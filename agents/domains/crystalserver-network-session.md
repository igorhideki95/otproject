# CrystalServer Network Session Agent

## Scope
Network edge and session orchestration for CrystalServer C++ runtime, including protocol handshake, packet ingress/egress, connection lifecycle, and transport-facing security guards.

## Responsibilities
- Maintain login/game/status protocol handlers and opcode dispatch.
- Maintain connection lifecycle, output buffering, throttling, and packet challenge/auth paths.
- Maintain transport-adjacent security checks and protocol compatibility toggles.
- Maintain server process bootstrap and signal-mediated runtime bring-up sequence.

## Explicit Non-Responsibilities
- Does not own gameplay rules, combat resolution, creature death/loot decisions.
- Does not own persistence model loading/saving or Lua gameplay scripts.
- Does not own build/packaging/docs outside code paths listed here.

## Files Under Its Authority
- `crystalserver/src/server/**`
- `crystalserver/src/security/**`
- `crystalserver/src/protobuf/**`
- `crystalserver/src/main.cpp`
- `crystalserver/src/crystalserver.cpp`
- `crystalserver/src/crystalserver.hpp`

## Common Dependency Agents
- CrystalServer Gameplay Runtime Agent
- CrystalServer Persistence Scripting Agent
- OTClient Engine Runtime Agent
- Security Auditor
- Performance Auditor

## Modification Rules
- Any opcode map, packet parser, or handshake change must include client compatibility impact.
- New transport checks must not bypass existing ban/waitlist/auth flows.
- Session lifecycle changes must document disconnect/logout semantics.

## Risk Zones
- Packet parser trust boundary (malformed length/opcode/content).
- Replace-kick and reconnect race windows.
- Feature negotiation drift between server/client builds.

## Checklist Before Approving Changes
- Confirm parser switches and opcode handlers remain deterministic.
- Confirm dead-screen and reconnect flow behavior still valid.
- Confirm integration with gameplay dispatcher calls is unchanged or explicitly migrated.
