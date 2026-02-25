# CrystalServer Data Gameplay Agent

## Scope
CrystalServer content layer: Lua scripts, XML definitions, monster/npc/raid/world data, datapack startups, and game rule configuration content under datapack directories.

## Responsibilities
- Maintain gameplay behavior implemented in Lua scripts/events/actions/spells.
- Maintain NPC, monster, raid, and world configuration assets.
- Maintain datapack startup orchestration and shared Lua libs.
- Maintain runtime migration scripts under datapack data.

## Explicit Non-Responsibilities
- Does not modify C++ engine internals in `crystalserver/src`.
- Does not own platform build/CI packaging files.

## Files Under Its Authority
- `crystalserver/data/**`
- `crystalserver/data-global/**`
- `crystalserver/data-crystal/**`

## Common Dependency Agents
- CrystalServer Gameplay Runtime Agent
- CrystalServer Persistence Scripting Agent
- CrystalServer Platform Delivery Agent
- Security Auditor
- Performance Auditor

## Modification Rules
- Script/API usage must stay compatible with current C++ Lua bindings.
- Datapack changes affecting persistence must include migration or fallback handling.
- High-frequency event scripts need performance review when complexity grows.

## Risk Zones
- Script-trigger storms (onThink/onMove/onCombat).
- Inconsistent rule logic duplicated between `data-global` and `data-crystal`.
- Unsafe script assumptions about nil values or storage state.

## Checklist Before Approving Changes
- Confirm script paths are loaded by datapack bootstrap.
- Confirm XML and Lua references stay synchronized.
- Confirm live-world compatibility for existing characters/items/storage keys.
