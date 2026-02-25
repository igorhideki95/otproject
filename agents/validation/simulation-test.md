# Simulation Test (Governance Under Change Pressure)

## Scenario A — Modify `Player.cpp`

### Target file
- `crystalserver/src/creatures/players/player.cpp`

### Triggered agents
- CrystalServer Gameplay Runtime (owner)
- CrystalServer Network Session (if send wrapper/packet behavior touched)
- CrystalServer Persistence Scripting (if saved fields/state semantics touched)
- Security Auditor (if permissions/trade/economy abuse surface touched)
- Performance Auditor (if per-tick or combat-path logic touched)

### Required approvals
- Owner approval: Gameplay Runtime
- Mandatory secondary: Network Session and/or Persistence Scripting depending on changed symbols
- Governance gate: Code Review Guardian

### Risk categories
- Global state mutation
- Gameplay regression
- Protocol side-effect drift
- Save/load divergence

### Escalation chain validation
Gameplay Runtime → (Security/Performance blockers) → Code Review Guardian → Project Architect.

---

## Scenario B — Modify `ProtocolGame.cpp`

### Target file
- `crystalserver/src/server/network/protocol/protocolgame.cpp`

### Triggered agents
- CrystalServer Network Session (owner)
- CrystalServer Gameplay Runtime (opcode action side effects)
- CrystalServer Persistence Scripting (login/auth/load interactions)
- OTClient Engine Runtime (protocol compatibility consumer)
- Security Auditor (trust boundary parser)
- Performance Auditor (hot packet path)

### Required approvals
- Owner approval: Network Session
- Mandatory secondary: Gameplay Runtime + Persistence Scripting
- Compatibility check: OTClient Engine Runtime
- Governance gate: Code Review Guardian

### Risk categories
- Parser security
- Session hijack/DoS behavior
- Action-routing regressions
- Client/server desync

### Escalation chain validation
Network Session owner cannot self-close security parser findings; mandatory escalation remains intact.

---

## Scenario C — Modify `IOLoginData.cpp`

### Target file
- `crystalserver/src/io/iologindata.cpp`

### Triggered agents
- CrystalServer Persistence Scripting (owner)
- CrystalServer Gameplay Runtime (player field model contract)
- CrystalServer Platform Delivery (schema alignment)
- Website Application Backoffice (shared DB model assumptions)
- Security Auditor (auth and account security)

### Required approvals
- Owner approval: Persistence Scripting
- Mandatory secondary: Gameplay Runtime + Platform Delivery
- Compatibility advisory: Website Backoffice
- Governance gate: Code Review Guardian

### Risk categories
- Authentication correctness
- SQL/query integrity
- Migration/schema drift
- Data corruption on save/load mismatch

### Escalation chain validation
Any schema or auth blocker escalates to Security Auditor and can block merge until guardian decision.

---

## Scenario D — Modify `game.cpp`

### Target file
- `crystalserver/src/game/game.cpp`

### Triggered agents
- CrystalServer Gameplay Runtime (owner)
- CrystalServer Network Session (if packet signaling semantics changed)
- CrystalServer Persistence Scripting (save scheduling/state durability)
- CrystalServer Data Gameplay (script callback behavior impact)
- Performance Auditor (main-loop and combat hot path)

### Required approvals
- Owner approval: Gameplay Runtime
- Mandatory secondary: Network Session/Persistence/Data Gameplay by touched region
- Governance gate: Code Review Guardian

### Risk categories
- Main-loop performance regression
- Hidden shared-state race
- Script callback behavior breakage
- Loot/death/login flow regressions

### Escalation chain validation
Performance blocker cannot be waived by owner; requires guardian and potentially architect override.

---

## Scenario E — Modify `modules/game_interface/`

### Target files
- `otclient/modules/game_interface/**`

### Triggered agents
- OTClient UI Modules (owner)
- OTClient Engine Runtime (if event/protocol assumptions changed)
- CrystalServer Network Session (if extended opcode/protocol expectations change)
- Performance Auditor (UI update cost)

### Required approvals
- Owner approval: OTClient UI Modules
- Mandatory secondary: OTClient Engine Runtime
- Compatibility advisory: CrystalServer Network Session (when protocol-expectation changes)
- Governance gate: Code Review Guardian

### Risk categories
- UI event leaks / double binding
- Client/server feature flag mismatch
- UX regressions under reconnect/login cycle

### Escalation chain validation
UI-only changes stay local; protocol-coupled changes escalate cross-repo by rule.

---

## Result
- After redesign, all five simulations trigger meaningful, non-overlapping ownership paths.
- Escalation is enforceable and no single runtime agent can unilaterally approve cross-boundary high-risk changes.
