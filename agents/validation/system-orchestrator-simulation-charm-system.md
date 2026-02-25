# System Orchestrator Simulation

## Request
Create Charm System

## Activated Agents
- **System Orchestrator** (coordination owner)
- CrystalServer Gameplay Runtime Agent
- CrystalServer Persistence Scripting Agent
- CrystalServer Data Gameplay Agent
- CrystalServer Network Session Agent
- OTClient Engine Runtime Agent
- OTClient UI Modules Agent
- CrystalServer Platform Delivery Agent
- Code Review Guardian
- Security Auditor
- Performance Auditor
- Project Architect (escalation)

## Impacted Layers
1. **Server Gameplay Runtime**: charm rules, trigger hooks, combat interactions, creature death/kill attribution.
2. **Persistence Layer**: player charm points/unlocks, migration-safe storage mapping, load/save symmetry.
3. **Datapack Content Layer**: charm definitions, tuning values, script events, balancing tables.
4. **Protocol Layer**: packets/opcodes for charm state sync, unlock actions, updates.
5. **Client Engine Runtime**: packet parse/send, feature flags, model updates.
6. **Client UI Modules**: charm window, unlock flow, feedback, localization hooks.
7. **Platform/Schema Layer**: schema updates, migration docs, release notes and compatibility guidance.

## Required Files (Path-Level Target Set)
### CrystalServer gameplay runtime
- `crystalserver/src/game/**`
- `crystalserver/src/creatures/**`

### CrystalServer persistence
- `crystalserver/src/io/**`
- `crystalserver/src/database/**`
- `crystalserver/src/lua/**` (bindings if needed)

### CrystalServer protocol/session
- `crystalserver/src/server/network/protocol/**`
- `crystalserver/src/protobuf/**` (if protocol schema path used)

### CrystalServer content + delivery
- `crystalserver/data/**`
- `crystalserver/data-global/**`
- `crystalserver/data-crystal/**`
- `crystalserver/schema.sql`
- `crystalserver/docs/**`

### OTClient engine + UI
- `otclient/src/client/protocolgame*.cpp`
- `otclient/src/client/game*.cpp`
- `otclient/modules/**` (new/updated charm module)
- `otclient/data/**` (styles/assets/locales if required)

## Governance Chain
1. Domain implementation owners execute scoped tasks.
2. Security + Performance specialists audit high-risk surfaces.
3. Code Review Guardian validates boundaries, tests, and evidence.
4. Project Architect resolves blockers and final cross-domain arbitration.

## Risk Classification
**High** (can elevate to Critical if protocol + schema migration + combat path all change in one PR)

### Risk drivers
- Combat hot path mutations (performance-sensitive).
- New player progression persistence fields (data integrity risk).
- Protocol synchronization and client/server compatibility risk.
- Potential exploit surface in unlock/action endpoints.

## Implementation Roadmap
### Phase 0 — Architecture split and contracts
- Define charm domain contracts (events, points, unlock semantics, sync model).
- Freeze interfaces between gameplay, persistence, and protocol.

### Phase 1 — Server model + persistence skeleton
- Add persistence model fields and migration path.
- Implement load/save behavior with backward compatibility defaults.

### Phase 2 — Gameplay runtime integration
- Implement charm effects entry points in combat/kill flows.
- Add bounded execution hooks to avoid per-hit heavy script overhead.

### Phase 3 — Datapack definitions and balance
- Add charm metadata/configuration and script-level behavior tables.
- Validate data references and fallback behavior for missing entries.

### Phase 4 — Protocol + client integration
- Add server send/client parse sync packets.
- Add client actions for unlock/config and error handling paths.

### Phase 5 — UI module delivery
- Implement charm UI, states, lock/unlock UX, and refresh triggers.
- Add localization and optional visual assets.

### Phase 6 — Hardening and release
- Security audit, performance sampling, migration rollback checks.
- Documentation updates and release compatibility notes.

## Cross-Layer Checklist
- [ ] Server gameplay applies charm effects deterministically.
- [ ] Persistence stores/reloads charm state losslessly.
- [ ] Protocol packets are version-compatible and feature-gated.
- [ ] Client parser tolerates unsupported/unknown charm payloads.
- [ ] UI handles offline/partial sync/error states.
- [ ] Datapack entries validated (no dangling IDs/references).
- [ ] Schema and migration order validated in clean + upgrade scenarios.

## Validation Steps
1. `python agents/tools/architecture_guard.py ownership --strict`
2. `python agents/tools/architecture_guard.py deps --strict`
3. `python agents/tools/architecture_guard.py impact --files <changed files...>`
4. `python agents/tools/architecture_guard.py drift --baseline agents/automation/baseline.json --strict`
5. `python agents/tools/architecture_guard.py report`
6. Domain test suites/build checks for CrystalServer + OTClient + website compatibility surface (if schema exposed).

## Required Approvals
- CrystalServer Gameplay Runtime owner
- CrystalServer Persistence Scripting owner
- CrystalServer Network Session owner
- OTClient Engine Runtime owner
- OTClient UI Modules owner
- CrystalServer Data Gameplay owner
- Code Review Guardian
- Security Auditor (mandatory)
- Performance Auditor (mandatory)
- Project Architect (mandatory if risk = Critical)

## Incomplete-Implementation Guards
Feature is **NOT complete** until all are true:
- Persistence migration + rollback verified.
- Client/server protocol sync verified on supported versions.
- Gameplay effect correctness validated under combat scenarios.
- Ownership/deps/drift/report checks green.
- Required approvals collected and recorded.
