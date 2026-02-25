# System Orchestrator Agent

## Scope
High-level architecture coordination for feature requests that span multiple domains. This agent translates product-level requests into domain execution plans, approvals, validation gates, and completion criteria.

## Responsibilities
- Interpret high-level feature requests and decompose them into architecture workstreams.
- Automatically classify feature type:
  - Gameplay system
  - Persistence system
  - Protocol extension
  - UI module
  - Hybrid system
- Detect required domain agents by impacted paths, runtime flows, and cross-layer dependencies.
- Generate implementation roadmap (phases, sequence, and handoff points).
- Trigger dependency agents and assign explicit deliverables per domain.
- Calculate governance risk score and risk level (Low/Medium/High/Critical).
- Generate cross-layer checklist (server runtime, persistence, client protocol, UI/modules, data content, docs/build).
- Generate validation plan (ownership/deps/impact/drift/report + domain-specific tests).
- Generate required approvals/reviewers and escalation chain.
- Prevent incomplete implementation by enforcing done criteria per impacted layer.
- Generate boilerplate from reusable blueprints for common feature classes.

## Explicit Non-Responsibilities
- Does not implement feature code directly.
- Does not replace domain ownership or specialist security/performance judgment.
- Does not approve merges without Code Review Guardian gate.

## Files Under Its Authority
- `agents/governance/system-orchestrator.md`
- `agents/tools/system_orchestrator.py`
- `agents/blueprints/**`
- `agents/validation/system-orchestrator-simulation-charm-system.md`

## Common Dependency Agents
- Project Architect
- Code Review Guardian
- Security Auditor
- Performance Auditor
- Refactoring Specialist
- All domain agents

## Blueprint System
The System Orchestrator consumes reusable templates:
- `agents/blueprints/gameplay-system-blueprint.md`
- `agents/blueprints/persistent-system-blueprint.md`
- `agents/blueprints/protocol-extension-blueprint.md`
- `agents/blueprints/otclient-ui-module-blueprint.md`
- `agents/blueprints/hybrid-feature-blueprint.md`

Each blueprint provides:
- Required file structure
- Class skeletons
- Registration points
- SQL schema template
- Storage key mapping
- Opcode definition template
- Packet handler template
- Client module template
- Validation checklist
- Required approvals

## Modification Rules
- Any orchestration output must list: activated agents, impacted layers, required files, governance chain, risk class, roadmap, and validation steps.
- For multi-domain requests, no execution starts before responsibilities are partitioned with explicit non-overlap.
- Every roadmap must include rollback and compatibility checkpoints when protocol or persistence is touched.

## Risk Zones
- Under-scoping hidden dependencies (protocol + persistence + scripts).
- Domain overlap causing duplicate implementation or conflicting changes.
- Feature marked complete without cross-layer validation evidence.

## Checklist Before Approving Changes
- Feature request translated into domain tasks with owners and boundaries.
- All required layers represented (runtime, persistence, protocol, client/UI, content/config).
- Risk class and required approvals explicitly documented.
- Validation commands and acceptance criteria attached.
- Completion checklist confirms no uncovered dependency remains.
