# CrystalServer Engine Runtime Agent

## Scope
C++ runtime engine for CrystalServer: process bootstrap, networking server, game loop, entity systems, map IO, Lua bridge internals, and protocol/runtime primitives under `crystalserver/src`.

## Responsibilities
- Maintain server runtime lifecycle (`main`, bootstrap, signal handling).
- Maintain game execution loop, scheduling, movement, creatures, items, map, and IO services.
- Maintain database abstraction layer code in C++ and engine-side persistence adapters.
- Maintain C++/Lua binding internals and script execution environment implementation.
- Maintain security primitives in `src/security` and protocol/shared definitions in `src/protobuf`.

## Explicit Non-Responsibilities
- Does not own gameplay content scripts/XML in datapacks.
- Does not own deployment scripts, CI workflow files, or packaging files outside `src`.

## Files Under Its Authority
- `crystalserver/src/CMakeLists.txt`
- `crystalserver/src/main.cpp`
- `crystalserver/src/crystalserver.cpp`
- `crystalserver/src/server/**`
- `crystalserver/src/game/**`
- `crystalserver/src/creatures/**`
- `crystalserver/src/items/**`
- `crystalserver/src/map/**`
- `crystalserver/src/io/**`
- `crystalserver/src/database/**`
- `crystalserver/src/lua/**`
- `crystalserver/src/security/**`
- `crystalserver/src/account/**`
- `crystalserver/src/config/**`
- `crystalserver/src/kv/**`
- `crystalserver/src/utils/**`
- `crystalserver/src/lib/**`
- `crystalserver/src/enums/**`
- `crystalserver/src/protobuf/**`
- `crystalserver/src/*.hpp`
- `crystalserver/src/*.cpp`

## Common Dependency Agents
- CrystalServer Data Gameplay Agent
- CrystalServer Platform Delivery Agent
- OTClient Engine Runtime Agent (protocol compatibility)
- Security Auditor
- Performance Auditor

## Modification Rules
- Protocol or packet behavior changes require client compatibility note.
- C++ Lua API signature changes require datapack impact inventory.
- Database query/model changes require schema/migration alignment proof.

## Risk Zones
- Network packet parsing and message handling.
- Scheduler/dispatcher race and deadlock opportunities.
- Script environment lifetime and userdata safety.

## Checklist Before Approving Changes
- Confirm compile path for affected targets remains valid.
- Confirm no protocol desync with OTClient parser/sender paths.
- Confirm Lua bridge changes are backward compatible or version-gated.
