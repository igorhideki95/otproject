# CrystalServer Gameplay Runtime Agent

## Scope
Authoritative in-memory gameplay engine for CrystalServer: creatures, combat, movement, world/map state transitions, item interactions, and game scheduler behavior.

## Responsibilities
- Maintain `Game` orchestration logic and runtime world state operations.
- Maintain creature/player/monster/NPC runtime behavior in C++.
- Maintain combat, death, loot, movement, map and tile logic.
- Maintain gameplay-facing scheduler/dispatcher/event timing behavior.

## Explicit Non-Responsibilities
- Does not own protocol packet parsing and connection layer.
- Does not own persistent storage serialization logic in IO/database modules.
- Does not own datapack Lua/XML content files.

## Files Under Its Authority
- `crystalserver/src/game/**`
- `crystalserver/src/creatures/**`
- `crystalserver/src/items/**`
- `crystalserver/src/map/**`
- `crystalserver/src/enums/**`
- `crystalserver/src/declarations.hpp`
- `crystalserver/src/core.hpp`

## Common Dependency Agents
- CrystalServer Network Session Agent
- CrystalServer Persistence Scripting Agent
- CrystalServer Data Gameplay Agent
- Performance Auditor

## Modification Rules
- Combat/death/loot changes require explicit side-effect review (events, rewards, persistence).
- Scheduler modifications require timing/regression assessment.
- New gameplay systems must define script/API boundary behavior.

## Risk Zones
- Shared mutable state in game loop and deferred tasks.
- Mixed responsibilities in very large files (`game.cpp`, `player.cpp`).
- Death/loot path with script callbacks and persistence side-effects.

## Checklist Before Approving Changes
- Confirm no gameplay regression in login, death, and loot pipelines.
- Confirm scheduler changes preserve deterministic ordering requirements.
- Confirm protocol notifications to clients remain coherent.
