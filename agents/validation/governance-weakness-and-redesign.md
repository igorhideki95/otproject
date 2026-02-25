# Governance Weakness Detection and Redesign

## Weaknesses found in previous structure

1. **CrystalServer runtime agent was too broad**
   - Previously, protocol/session, gameplay simulation, and persistence/scripting all lived in one domain agent.
   - Consequence: symbol-level ownership was ambiguous for high-risk files (`protocolgame.cpp`, `game.cpp`, `player.cpp`, `iologindata.cpp`).

2. **Insufficient stress-test granularity for escalations**
   - A single runtime owner reduced meaningful multi-agent review in high-risk changes.

3. **Hidden coupling not reflected in ownership model**
   - File-level partition masked major trust-boundary and persistence-coupling seams.

## Redesign applied

### Domain split (CrystalServer runtime)
- Replaced `crystalserver-engine-runtime.md` with:
  - `crystalserver-network-session.md`
  - `crystalserver-gameplay-runtime.md`
  - `crystalserver-persistence-scripting.md`

### Why this resolves weakness
- Distinguishes trust boundary (network) from simulation authority (gameplay) and state durability (persistence).
- Forces cross-agent approvals on risky edits that previously self-approved under one domain.
- Makes audit triggers deterministic for security and performance specialists.

## Agent sizing assessment
- **Too few?** No after split; CrystalServer now has distinct runtime boundaries.
- **Too broad?** Improved; remaining broad files are tracked as refactor hotspots.
- **Too narrow?** No; each new CrystalServer runtime agent owns coherent, high-value boundaries.

## Governance hierarchy sufficiency
- Current hierarchy remains valid.
- Escalation now has higher signal due to increased domain specificity.

## Website isolation validation
- Website remains isolated to three domain agents (backoffice/presentation/tooling).
- No file ownership overlap with engine/runtime trees.
- Shared DB compatibility is represented as cross-agent dependency, not shared ownership.

## Additional hardening recommendations
- Add a mandatory “cross-agent impact” section to PR template when changes touch protocol, schema, or save/load fields.
- Add CI check that validates ownership-rule coverage and first-match uniqueness.
