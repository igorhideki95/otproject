# CrystalServer Persistence Scripting Agent

## Scope
Persistence, storage mapping, script runtime integration, and account/model loading for CrystalServer C++ runtime.

## Responsibilities
- Maintain DB abstraction and query execution layers.
- Maintain IO loaders/savers for players, guild/account, and related persistence workflows.
- Maintain Lua environment/bindings/module registries used by runtime.
- Maintain key-value persistence and runtime config access wiring.

## Explicit Non-Responsibilities
- Does not own protocol parser and session transport logic.
- Does not own gameplay rule execution internals except through persistence/script interfaces.
- Does not own datapack script/content files outside `crystalserver/src`.

## Files Under Its Authority
- `crystalserver/src/database/**`
- `crystalserver/src/io/**`
- `crystalserver/src/lua/**`
- `crystalserver/src/account/**`
- `crystalserver/src/kv/**`
- `crystalserver/src/config/**`
- `crystalserver/src/lib/**`
- `crystalserver/src/utils/**`
- `crystalserver/src/pch.cpp`
- `crystalserver/src/pch.hpp`

## Common Dependency Agents
- CrystalServer Gameplay Runtime Agent
- CrystalServer Network Session Agent
- CrystalServer Platform Delivery Agent
- Website Application Backoffice Agent
- Security Auditor

## Modification Rules
- Schema-facing changes require migration and backward-read validation.
- Lua binding changes require datapack compatibility inventory.
- Save/load path updates must include failure and partial-write handling notes.

## Risk Zones
- SQL correctness and transaction consistency on player save.
- Script-runtime ownership/lifetime of userdata.
- Async save scheduling race with logout/shutdown.

## Checklist Before Approving Changes
- Confirm load/save symmetry for modified player/account fields.
- Confirm migration alignment with `schema.sql` and website queries.
- Confirm script callbacks still receive expected argument contracts.
