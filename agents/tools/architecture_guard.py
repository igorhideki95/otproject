#!/usr/bin/env python3
from __future__ import annotations

import argparse
import fnmatch
import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Set, Tuple


@dataclass
class Rule:
    pattern: str
    agent: str


def load_config(path: Path) -> dict:
    return json.loads(path.read_text())


def list_repo_files(repo: Path) -> List[str]:
    out = []
    for root, dirs, files in os.walk(repo):
        rootp = Path(root)
        if ".git" in rootp.parts:
            dirs[:] = []
            continue
        for f in files:
            rel = str((rootp / f).relative_to(repo)).replace("\\", "/")
            out.append(rel)
    return sorted(out)


def match_all(path: str, rules: List[Rule]) -> List[str]:
    return [r.agent for r in rules if fnmatch.fnmatch(path, r.pattern)]


def match_first(path: str, rules: List[Rule]) -> Optional[str]:
    for r in rules:
        if fnmatch.fnmatch(path, r.pattern):
            return r.agent
    return None


def build_owner_map(files: Iterable[str], rules: List[Rule]) -> Tuple[Dict[str, str], List[str], Dict[str, List[str]]]:
    owners: Dict[str, str] = {}
    uncovered: List[str] = []
    overlaps: Dict[str, List[str]] = {}
    for f in files:
        all_matches = match_all(f, rules)
        if not all_matches:
            uncovered.append(f)
            continue
        uniq = sorted(set(all_matches))
        if len(uniq) > 1:
            overlaps[f] = uniq
        owners[f] = match_first(f, rules)  # first-match ownership
    return owners, uncovered, overlaps


def git_changed_files(repo: Path, base_ref: Optional[str]) -> List[str]:
    if not base_ref:
        cmd = ["git", "diff", "--name-only", "HEAD~1..HEAD"]
    else:
        cmd = ["git", "diff", "--name-only", f"{base_ref}...HEAD"]
    p = subprocess.run(cmd, cwd=repo, capture_output=True, text=True, check=False)
    if p.returncode != 0:
        return []
    return [x.strip() for x in p.stdout.splitlines() if x.strip()]


def git_renames(repo: Path, base_ref: Optional[str]) -> List[Tuple[str, str]]:
    if not base_ref:
        rng = "HEAD~1..HEAD"
    else:
        rng = f"{base_ref}...HEAD"
    cmd = ["git", "diff", "--name-status", "--find-renames", rng]
    p = subprocess.run(cmd, cwd=repo, capture_output=True, text=True, check=False)
    renames = []
    if p.returncode != 0:
        return renames
    for line in p.stdout.splitlines():
        parts = line.split("\t")
        if parts and parts[0].startswith("R") and len(parts) >= 3:
            renames.append((parts[1], parts[2]))
    return renames


def scan_dependency_edges(repo: Path, files: List[str], owners: Dict[str, str]) -> Tuple[List[Tuple[str, str, str, str]], List[dict], List[dict]]:
    """Returns include edges + unresolved includes + symbol leakage warnings."""
    include_re = re.compile(r'^\s*#\s*include\s*[<\"]([^>\"]+)[>\"]')
    php_re = re.compile(r"\b(?:require|include)(?:_once)?\s*\(?\s*['\"]([^'\"]+)['\"]")

    source_files = [f for f in files if f.endswith((".cpp", ".hpp", ".h", ".c", ".cc", ".php"))]
    path_index = defaultdict(list)
    for f in files:
        path_index[Path(f).name].append(f)

    edges = []
    unresolved = []
    symbol_leakage = []

    for sf in source_files:
        src_domain = owners.get(sf)
        if not src_domain:
            continue
        text = (repo / sf).read_text(errors="ignore")

        includes = include_re.findall(text)
        if sf.endswith(".php"):
            includes += php_re.findall(text)

        for inc in includes:
            target = None
            candidates = []
            norm_inc = inc.replace("\\", "/")
            # direct relative
            local = (Path(sf).parent / norm_inc).as_posix()
            if local in owners:
                target = local
            elif norm_inc in owners:
                target = norm_inc
            else:
                by_name = path_index.get(Path(norm_inc).name, [])
                if len(by_name) == 1:
                    target = by_name[0]
                else:
                    candidates = by_name[:5]

            if not target:
                unresolved.append({"source": sf, "include": inc, "candidates": candidates})
                continue

            dst_domain = owners.get(target)
            if not dst_domain:
                continue
            if src_domain != dst_domain:
                edges.append((src_domain, dst_domain, sf, target))
                if sf.endswith((".hpp", ".h")):
                    symbol_leakage.append({
                        "header": sf,
                        "to": target,
                        "from_domain": src_domain,
                        "to_domain": dst_domain,
                        "reason": "Public header includes cross-domain implementation type; prefer forward declarations where possible."
                    })

    return edges, unresolved, symbol_leakage


def strongly_connected_components(graph: Dict[str, Set[str]]) -> List[List[str]]:
    index = 0
    stack = []
    indices = {}
    lowlink = {}
    onstack = set()
    sccs = []

    def strongconnect(v: str):
        nonlocal index
        indices[v] = index
        lowlink[v] = index
        index += 1
        stack.append(v)
        onstack.add(v)

        for w in graph.get(v, set()):
            if w not in indices:
                strongconnect(w)
                lowlink[v] = min(lowlink[v], lowlink[w])
            elif w in onstack:
                lowlink[v] = min(lowlink[v], indices[w])

        if lowlink[v] == indices[v]:
            comp = []
            while True:
                w = stack.pop()
                onstack.remove(w)
                comp.append(w)
                if w == v:
                    break
            if len(comp) > 1:
                sccs.append(sorted(comp))

    for v in sorted(graph.keys()):
        if v not in indices:
            strongconnect(v)
    return sccs


def compute_risk(files: List[str], owners: Dict[str, str], cfg: dict) -> Tuple[str, int, dict]:
    score = 0
    impact = {
        "security_sensitive_files": [],
        "performance_hot_files": [],
        "cross_agent_count": 0
    }

    impacted_agents = sorted({owners.get(f) for f in files if owners.get(f)})
    impact["cross_agent_count"] = len(impacted_agents)
    score += max(0, len(impacted_agents) - 1) * 2

    for f in files:
        for pat in cfg.get("security_sensitive_patterns", []):
            if fnmatch.fnmatch(f, pat):
                impact["security_sensitive_files"].append(f)
                score += 3
                break
        for pat in cfg.get("performance_hot_patterns", []):
            if fnmatch.fnmatch(f, pat):
                impact["performance_hot_files"].append(f)
                score += 2
                break

    if score >= 12:
        level = "Critical"
    elif score >= 8:
        level = "High"
    elif score >= 4:
        level = "Medium"
    else:
        level = "Low"
    return level, score, impact


def command_ownership(args) -> int:
    repo = Path(args.repo).resolve()
    cfg = load_config(Path(args.config))
    rules = [Rule(**r) for r in cfg["rules"]]
    files = list_repo_files(repo)
    owners, uncovered, overlaps = build_owner_map(files, rules)

    duplicate_patterns = []
    seen = {}
    for r in rules:
        if r.pattern in seen and seen[r.pattern] != r.agent:
            duplicate_patterns.append((r.pattern, seen[r.pattern], r.agent))
        seen[r.pattern] = r.agent

    renames = git_renames(repo, args.base_ref)
    moved_domains = []
    for old, new in renames:
        old_owner = match_first(old, rules)
        new_owner = match_first(new, rules)
        if old_owner and new_owner and old_owner != new_owner:
            moved_domains.append({"from": old, "to": new, "old_agent": old_owner, "new_agent": new_owner})

    result = {
        "file_count": len(files),
        "covered_count": len(files) - len(uncovered),
        "coverage_pct": round((len(files) - len(uncovered)) * 100.0 / max(1, len(files)), 2),
        "uncovered": uncovered,
        "overlap_conflicts": overlaps,
        "rule_conflicts": duplicate_patterns,
        "domain_moves": moved_domains
    }
    print(json.dumps(result, indent=2))

    failed = bool(uncovered or duplicate_patterns)
    return 1 if failed and args.strict else 0


def command_deps(args) -> int:
    repo = Path(args.repo).resolve()
    cfg = load_config(Path(args.config))
    rules = [Rule(**r) for r in cfg["rules"]]
    files = list_repo_files(repo)
    owners, uncovered, _ = build_owner_map(files, rules)
    if uncovered:
        print(json.dumps({"error": "uncovered files exist", "count": len(uncovered)}, indent=2))
        return 1

    edges, unresolved, leakage = scan_dependency_edges(repo, files, owners)
    graph = defaultdict(set)
    edge_counter = Counter()
    for src, dst, _sf, _tf in edges:
        graph[src].add(dst)
        edge_counter[(src, dst)] += 1

    cycles = strongly_connected_components(graph)

    forbidden = []
    forbidden_rules = cfg.get("forbidden_domain_includes", [])
    for src, dst, sf, tf in edges:
        for fr in forbidden_rules:
            if src == fr["from"] and dst == fr["to"]:
                forbidden.append({"source": sf, "target": tf, "from": src, "to": dst, "reason": fr["reason"]})

    symbol_bypass = []
    for fs in files:
        dom = owners.get(fs)
        if not dom or not fs.endswith((".cpp", ".hpp", ".h", ".lua", ".php")):
            continue
        text = (repo / fs).read_text(errors="ignore")
        for rule in cfg.get("forbidden_symbol_calls", []):
            if rule["domain"] == dom and re.search(rule["pattern"], text):
                symbol_bypass.append({"file": fs, "domain": dom, "pattern": rule["pattern"], "reason": rule["reason"]})

    result = {
        "domain_edges": [
            {"from": s, "to": d, "count": c} for (s, d), c in sorted(edge_counter.items())
        ],
        "cycles": cycles,
        "forbidden_cross_domain_includes": forbidden,
        "direct_boundary_bypass": symbol_bypass,
        "symbol_leakage": leakage[:200],
        "unresolved_includes": unresolved[:200]
    }
    print(json.dumps(result, indent=2))

    failed = bool(cycles or forbidden or symbol_bypass)
    return 1 if failed and args.strict else 0


def command_impact(args) -> int:
    repo = Path(args.repo).resolve()
    cfg = load_config(Path(args.config))
    rules = [Rule(**r) for r in cfg["rules"]]
    files = list_repo_files(repo)
    owners, _, _ = build_owner_map(files, rules)

    changed = args.files or git_changed_files(repo, args.base_ref)
    changed = [f for f in changed if f in owners]
    impacted_agents = sorted({owners[f] for f in changed})

    risk_level, score, details = compute_risk(changed, owners, cfg)

    reviewers = set(["@code-review-guardian"])
    for a in impacted_agents:
        for r in cfg.get("agent_reviewers", {}).get(a, []):
            reviewers.add(r)

    if risk_level in {"High", "Critical"}:
        reviewers.add("@security-auditor")
        reviewers.add("@performance-auditor")
    if risk_level == "Critical":
        reviewers.add("@project-architect")

    result = {
        "changed_files": changed,
        "impacted_agents": impacted_agents,
        "risk": {"level": risk_level, "score": score, "details": details},
        "required_reviewers": sorted(reviewers),
        "escalation_chain": cfg.get("escalation_chain", [])
    }
    print(json.dumps(result, indent=2))
    return 0


def command_drift(args) -> int:
    repo = Path(args.repo).resolve()
    cfg = load_config(Path(args.config))
    rules = [Rule(**r) for r in cfg["rules"]]
    files = list_repo_files(repo)
    owners, uncovered, _ = build_owner_map(files, rules)
    edges, _, _ = scan_dependency_edges(repo, files, owners)

    per_agent_files = Counter(owners.values())
    per_agent_lines = Counter()
    for f, a in owners.items():
        try:
            per_agent_lines[a] += sum(1 for _ in (repo / f).open("r", errors="ignore"))
        except Exception:
            pass

    coupling = Counter((s, d) for s, d, _, _ in edges if s != d)
    security_growth = Counter()
    perf_growth = Counter()
    for f, a in owners.items():
        if any(fnmatch.fnmatch(f, p) for p in cfg.get("security_sensitive_patterns", [])):
            security_growth[a] += 1
        if any(fnmatch.fnmatch(f, p) for p in cfg.get("performance_hot_patterns", [])):
            perf_growth[a] += 1

    snapshot = {
        "uncovered": len(uncovered),
        "agent_file_count": per_agent_files,
        "agent_line_count": per_agent_lines,
        "cross_agent_coupling_edges": {f"{s}->{d}": c for (s, d), c in coupling.items()},
        "security_sensitive_file_count": security_growth,
        "performance_hot_file_count": perf_growth
    }

    baseline = None
    baseline_path = Path(args.baseline)
    if baseline_path.exists():
        baseline = json.loads(baseline_path.read_text())

    drift = {"responsibility_creep": [], "coupling_growth": [], "security_path_growth": [], "performance_path_growth": []}
    if baseline:
        for a, count in per_agent_files.items():
            old = baseline.get("agent_file_count", {}).get(a, 0)
            if old and count > old * 1.25:
                drift["responsibility_creep"].append({"agent": a, "old": old, "new": count})
        for k, count in snapshot["cross_agent_coupling_edges"].items():
            old = baseline.get("cross_agent_coupling_edges", {}).get(k, 0)
            if old and count > old * 1.3:
                drift["coupling_growth"].append({"edge": k, "old": old, "new": count})
        for a, count in security_growth.items():
            old = baseline.get("security_sensitive_file_count", {}).get(a, 0)
            if count > old:
                drift["security_path_growth"].append({"agent": a, "old": old, "new": count})
        for a, count in perf_growth.items():
            old = baseline.get("performance_hot_file_count", {}).get(a, 0)
            if count > old:
                drift["performance_path_growth"].append({"agent": a, "old": old, "new": count})

    if args.write_baseline:
        baseline_path.parent.mkdir(parents=True, exist_ok=True)
        baseline_path.write_text(json.dumps(snapshot, indent=2, default=lambda x: dict(x)))

    out = {
        "snapshot": json.loads(json.dumps(snapshot, default=lambda x: dict(x))),
        "drift": drift,
        "baseline_used": bool(baseline)
    }
    print(json.dumps(out, indent=2))
    failed = any(len(v) > 0 for v in drift.values())
    return 1 if failed and args.strict else 0


def command_report(args) -> int:
    repo = Path(args.repo).resolve()
    cfg = load_config(Path(args.config))
    rules = [Rule(**r) for r in cfg["rules"]]
    files = list_repo_files(repo)
    owners, uncovered, overlaps = build_owner_map(files, rules)
    edges, _, leakage = scan_dependency_edges(repo, files, owners)

    cross_edges = [(s, d) for s, d, _, _ in edges if s != d]
    coupling_score = len(cross_edges) / max(1, len(files))

    violations = {
        "uncovered": len(uncovered),
        "overlap_conflicts": len(overlaps),
        "symbol_leakage": len(leakage)
    }

    load = Counter(owners.values())
    heatmap = defaultdict(int)
    for f in files:
        a = owners.get(f)
        if not a:
            continue
        if any(fnmatch.fnmatch(f, p) for p in cfg.get("security_sensitive_patterns", [])):
            heatmap[a] += 3
        if any(fnmatch.fnmatch(f, p) for p in cfg.get("performance_hot_patterns", [])):
            heatmap[a] += 2

    bottlenecks = sorted(({"agent": a, "files": c, "risk_heat": heatmap[a]} for a, c in load.items()), key=lambda x: (x["risk_heat"], x["files"]), reverse=True)[:10]

    report = {
        "coverage_pct": round((len(files) - len(uncovered)) * 100.0 / max(1, len(files)), 2),
        "coupling_score": round(coupling_score, 4),
        "boundary_violations": violations,
        "risk_heatmap": dict(sorted(heatmap.items())),
        "agent_load_distribution": dict(sorted(load.items())),
        "governance_bottlenecks": bottlenecks
    }
    print(json.dumps(report, indent=2))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Architecture governance enforcement tool")
    parser.add_argument("--repo", default=".", help="Repository root")
    parser.add_argument("--config", default="agents/automation/ownership_rules.json", help="Rules config JSON")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p1 = sub.add_parser("ownership", help="Validate ownership mapping")
    p1.add_argument("--base-ref", default=None)
    p1.add_argument("--strict", action="store_true")
    p1.set_defaults(func=command_ownership)

    p2 = sub.add_parser("deps", help="Validate cross-agent dependencies")
    p2.add_argument("--strict", action="store_true")
    p2.set_defaults(func=command_deps)

    p3 = sub.add_parser("impact", help="Calculate change impact")
    p3.add_argument("--base-ref", default=None)
    p3.add_argument("--files", nargs="*", default=[])
    p3.set_defaults(func=command_impact)

    p4 = sub.add_parser("drift", help="Detect architecture drift")
    p4.add_argument("--baseline", default="agents/automation/baseline.json")
    p4.add_argument("--write-baseline", action="store_true")
    p4.add_argument("--strict", action="store_true")
    p4.set_defaults(func=command_drift)

    p5 = sub.add_parser("report", help="Generate continuous validation report")
    p5.set_defaults(func=command_report)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
