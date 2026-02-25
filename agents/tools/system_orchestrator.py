#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Set


@dataclass
class Classification:
    gameplay: bool
    persistence: bool
    protocol: bool
    ui: bool

    @property
    def feature_type(self) -> str:
        active = [self.gameplay, self.persistence, self.protocol, self.ui]
        if sum(active) > 1:
            return "Hybrid system"
        if self.gameplay:
            return "Gameplay system"
        if self.persistence:
            return "Persistence system"
        if self.protocol:
            return "Protocol extension"
        if self.ui:
            return "UI module"
        return "Gameplay system"


def classify_request(request: str) -> Classification:
    s = request.lower()
    gameplay_kw = r"charm|combat|monster|creature|spell|loot|death|bestiary|gameplay"
    persistence_kw = r"save|persist|database|schema|migration|storage|account|state"
    protocol_kw = r"packet|opcode|protocol|network|sync|message"
    ui_kw = r"ui|window|module|panel|otui|interface|client"

    gameplay = bool(re.search(gameplay_kw, s))
    persistence = bool(re.search(persistence_kw, s))
    protocol = bool(re.search(protocol_kw, s))
    ui = bool(re.search(ui_kw, s))

    # domain heuristic: systems like "charm" are usually hybrid unless constrained
    if "charm" in s and not any([persistence, protocol, ui]):
        persistence = protocol = ui = True

    return Classification(gameplay=gameplay or True, persistence=persistence, protocol=protocol, ui=ui)


def activated_agents(c: Classification) -> List[str]:
    agents: Set[str] = {
        "system-orchestrator",
        "code-review-guardian",
        "security-auditor",
        "performance-auditor",
        "project-architect",
    }
    if c.gameplay:
        agents.update(["crystalserver-gameplay-runtime", "crystalserver-data-gameplay"])
    if c.persistence:
        agents.update(["crystalserver-persistence-scripting", "crystalserver-platform-delivery"])
    if c.protocol:
        agents.update(["crystalserver-network-session", "otclient-engine-runtime"])
    if c.ui:
        agents.update(["otclient-ui-modules", "otclient-assets-distribution"])
    return sorted(agents)


def impacted_layers(c: Classification) -> List[str]:
    layers = ["Server Gameplay Runtime", "Datapack Content"]
    if c.persistence:
        layers.append("Persistence + Schema")
    if c.protocol:
        layers.append("Protocol + Transport")
    if c.ui:
        layers.append("OTClient UI + UX")
    return layers


def risk_score(c: Classification) -> Dict[str, object]:
    score = 30
    if c.gameplay:
        score += 20
    if c.persistence:
        score += 20
    if c.protocol:
        score += 20
    if c.ui:
        score += 10

    if score >= 80:
        level = "Critical"
    elif score >= 65:
        level = "High"
    elif score >= 45:
        level = "Medium"
    else:
        level = "Low"

    return {"score": score, "level": level}


def approvals(c: Classification, risk_level: str) -> List[str]:
    out = {"Code Review Guardian", "Security Auditor", "Performance Auditor"}
    if c.gameplay:
        out.update({"CrystalServer Gameplay Runtime", "CrystalServer Data Gameplay"})
    if c.persistence:
        out.update({"CrystalServer Persistence Scripting", "CrystalServer Platform Delivery"})
    if c.protocol:
        out.update({"CrystalServer Network Session", "OTClient Engine Runtime"})
    if c.ui:
        out.add("OTClient UI Modules")
    if risk_level == "Critical":
        out.add("Project Architect")
    return sorted(out)


def blueprint_set(c: Classification) -> List[str]:
    if sum([c.gameplay, c.persistence, c.protocol, c.ui]) > 1:
        return [
            "hybrid-feature-blueprint.md",
            "gameplay-system-blueprint.md",
            "persistent-system-blueprint.md",
            "protocol-extension-blueprint.md",
            "otclient-ui-module-blueprint.md",
        ]
    if c.gameplay:
        return ["gameplay-system-blueprint.md"]
    if c.persistence:
        return ["persistent-system-blueprint.md"]
    if c.protocol:
        return ["protocol-extension-blueprint.md"]
    return ["otclient-ui-module-blueprint.md"]


def generated_tree(feature: str) -> List[str]:
    f = feature.lower().replace(" ", "_")
    return [
        f"crystalserver/src/game/systems/{f}/{f}_system.hpp",
        f"crystalserver/src/game/systems/{f}/{f}_system.cpp",
        f"crystalserver/src/io/{f}/io_{f}.hpp",
        f"crystalserver/src/io/{f}/io_{f}.cpp",
        "crystalserver/src/server/network/protocol/protocolgame.cpp",
        "crystalserver/src/server/network/protocol/protocolgame.hpp",
        "crystalserver/schema.sql",
        f"crystalserver/data/scripts/{f}/init.lua",
        "otclient/src/client/protocolgameparse.cpp",
        "otclient/src/client/protocolgamesend.cpp",
        f"otclient/modules/game_{f}/{f}.lua",
        f"otclient/modules/game_{f}/{f}.otui",
        f"otclient/modules/game_{f}/game_{f}.otmod",
    ]


def skeleton_examples(feature: str) -> Dict[str, str]:
    cls = ''.join(x.capitalize() for x in feature.split())
    slug = feature.lower().replace(' ', '_')
    return {
        "server_class": f"""class {cls}System {{\npublic:\n  bool init();\n  void onKill(const std::shared_ptr<Player>& killer, const std::shared_ptr<Creature>& target);\n  void onLogin(const std::shared_ptr<Player>& player);\n}};""",
        "persistence": f"""class IO{cls} {{\npublic:\n  static bool load(const std::shared_ptr<Player>& player);\n  static bool save(const std::shared_ptr<Player>& player);\n}};""",
        "opcode": f"""constexpr uint8_t ClientOpcode{cls}Action = 0xE0;\nconstexpr uint8_t ServerOpcode{cls}State = 0xE1;""",
        "packet_handler": f"""void ProtocolGame::parse{cls}Action(NetworkMessage& msg);\nvoid ProtocolGame::send{cls}State(const std::shared_ptr<Player>& player);""",
        "sql": f"""CREATE TABLE IF NOT EXISTS player_{slug} (\n  player_id INT UNSIGNED NOT NULL,\n  charm_id SMALLINT UNSIGNED NOT NULL,\n  value BIGINT NOT NULL DEFAULT 0,\n  PRIMARY KEY (player_id, charm_id)\n);""",
        "storage": f"""Storage.{cls} = {{\n  Version = 93000,\n  Points = 93001,\n  UnlockBase = 93100\n}}""",
        "client_module": f"""function init()\n  connect(g_game, {{ onGameStart = refresh{cls}, onGameEnd = clear{cls} }})\nend""",
    }


def validation_checklist() -> List[str]:
    return [
        "ownership --strict",
        "deps --strict",
        "impact --files <changed files>",
        "drift --baseline agents/automation/baseline.json --strict",
        "report",
        "CrystalServer build/tests",
        "OTClient build/tests",
    ]


def orchestrate(request: str) -> Dict[str, object]:
    c = classify_request(request)
    r = risk_score(c)
    feature_name = request.replace("Create", "").strip()
    return {
        "request": request,
        "feature_type": c.feature_type,
        "activated_agents": activated_agents(c),
        "impacted_layers": impacted_layers(c),
        "risk": r,
        "required_approvals": approvals(c, r["level"]),
        "blueprints": blueprint_set(c),
        "generated_boilerplate_structure": generated_tree(feature_name),
        "generated_code_skeleton_examples": skeleton_examples(feature_name),
        "validation_checklist": validation_checklist(),
        "governance_chain": [
            "System Orchestrator",
            "Domain Owners",
            "Security/Performance Auditors",
            "Code Review Guardian",
            "Project Architect",
        ],
    }


def to_markdown(payload: Dict[str, object]) -> str:
    lines = [
        "# Intelligent Orchestration Simulation",
        "",
        f"## Request\n{payload['request']}",
        "",
        f"## Feature Type\n{payload['feature_type']}",
        "",
        "## Activated agents",
    ]
    lines += [f"- {a}" for a in payload["activated_agents"]]
    lines += ["", "## Layer impact"] + [f"- {l}" for l in payload["impacted_layers"]]
    risk = payload["risk"]
    lines += ["", "## Risk score", f"- Level: {risk['level']}", f"- Score: {risk['score']}"]
    lines += ["", "## Required approvals"] + [f"- {a}" for a in payload["required_approvals"]]
    lines += ["", "## Generated boilerplate structure"] + [f"- `{p}`" for p in payload["generated_boilerplate_structure"]]
    lines += ["", "## Generated file tree", "```text"]
    lines += [f"{p}" for p in payload["generated_boilerplate_structure"]]
    lines += ["```", "", "## Generated code skeleton examples"]
    for k, v in payload["generated_code_skeleton_examples"].items():
        lines += [f"### {k}", "```", v, "```"]
    lines += ["", "## Validation checklist"] + [f"- [ ] {v}" for v in payload["validation_checklist"]]
    lines += ["", "## Governance chain"] + [f"1. {x}" for x in payload["governance_chain"]]
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="System Orchestrator intelligent planner")
    parser.add_argument("--request", required=True, help="High-level feature request")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of markdown")
    parser.add_argument("--output", default=None, help="Optional output file")
    args = parser.parse_args()

    payload = orchestrate(args.request)
    content = json.dumps(payload, indent=2) if args.json else to_markdown(payload)

    if args.output:
        Path(args.output).write_text(content)
    else:
        print(content)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
