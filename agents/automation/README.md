# Architecture Enforcement Automation

This folder contains executable governance enforcement tooling.

## Main tool
- `agents/tools/architecture_guard.py`

## Commands

```bash
# Phase 1: Ownership enforcement
python agents/tools/architecture_guard.py ownership --strict

# Include movement detection against a target branch/ref
python agents/tools/architecture_guard.py ownership --base-ref origin/main --strict

# Phase 2: Cross-agent dependency monitor
python agents/tools/architecture_guard.py deps --strict

# Phase 3: Change impact engine (auto diff)
python agents/tools/architecture_guard.py impact --base-ref origin/main

# Or explicit changed files
python agents/tools/architecture_guard.py impact --files crystalserver/src/game/game.cpp otclient/modules/game_interface/gameinterface.lua

# Phase 4: Architecture drift detector
python agents/tools/architecture_guard.py drift --baseline agents/automation/baseline.json --strict

# Write/refresh baseline
python agents/tools/architecture_guard.py drift --write-baseline --baseline agents/automation/baseline.json

# Phase 5: Continuous validation report
python agents/tools/architecture_guard.py report
```

# Intelligent orchestration (feature planning + boilerplate)
python agents/tools/system_orchestrator.py --request "Create Charm System"
python agents/tools/system_orchestrator.py --request "Create Charm System" --json
python agents/tools/system_orchestrator.py --request "Create Charm System" --output agents/validation/system-orchestrator-simulation-charm-system.md

## CI-friendly output
All commands emit JSON to stdout. Strict mode exits with non-zero status when violations are detected.

## Config
- `agents/automation/ownership_rules.json` contains:
  - ordered ownership rules
  - forbidden cross-domain includes
  - forbidden symbol calls
  - risk patterns
  - reviewer mapping and escalation chain
