# Coupling & Risk Map

## Cyclic dependency findings

### Runtime-level (logical) cycles
- **Cycle pattern**: Protocol handler → Game action → immediate protocol send.
- **Location**: `crystalserver/src/server/network/protocol/protocolgame.cpp` + `crystalserver/src/game/game.cpp`.
- **Risk**: hard-to-isolate regressions in action handlers that implicitly rely on send ordering.
- **Mitigation**: isolate command handling from packet serialization via response DTO/event queue.

### Module/event cycles
- **Cycle pattern**: OTClient module callback mutates state, emits further callbacks.
- **Location**: `otclient/modules/**` hooked to `g_game` and `LocalPlayer` events.
- **Risk**: duplicate handler registration after reload.
- **Mitigation**: enforce strict `init()/terminate()` idempotency and event unbind checks.

## Hidden shared state risks
- Global singletons (`g_game`, `g_dispatcher`, config manager) are shared mutation points across subsystems.
- `Player` and `Game` act as high-fan-in mutable aggregates.
- Save scheduler (`SaveManager`) reads mutable player state while runtime continues progressing.

## Tight-coupling hotspots across agents
1. **Network Session ↔ Gameplay Runtime**
   - Direct `g_game().player*` invocations inside opcode switch.
2. **Gameplay Runtime ↔ Persistence Scripting**
   - `IOLoginData::savePlayer/loadPlayer` depends on broad `Player` internals.
3. **Gameplay Runtime ↔ Data Gameplay**
   - Death/combat/action paths execute Lua callbacks with side effects.
4. **OTClient Engine Runtime ↔ UI Modules**
   - Modules rely on feature flags and protocol state details without strict typed contracts.

## Single-responsibility violations
- `crystalserver/src/game/game.cpp` and `crystalserver/src/creatures/players/player.cpp` are oversized mixed-responsibility files.
- `crystalserver/src/server/network/protocol/protocolgame.cpp` combines trust-boundary parsing, policy checks, and serialization.
- `otclient/src/client/protocolgameparse.cpp` is a giant protocol switchboard with heterogeneous domains.

## Performance bottlenecks crossing agents
- High-frequency packet handling in protocol switch plus immediate world mutations.
- Combat + script callback chains in AoE scenarios.
- UI module event storms when multiple modules subscribe to overlapping `g_game` notifications.
- Save bursts (`saveAll`) traversing all online players and guilds in one cycle.

## Security-sensitive cross-agent paths
- Login/auth path crosses Network Session + Persistence Scripting (`ProtocolGame::onRecvFirstMessage` + `IOLoginData::gameWorldAuthentication`).
- Extended opcode handling crosses protocol trust boundary into module/script surfaces.
- Website migration + shared schema compatibility with server DB models.

## Risk grading
- **Critical**: protocol parser trust boundary and auth/session flow.
- **High**: `Player`/`Game` monolith coupling, async save race windows.
- **Medium**: module callback storms and implicit feature coupling.
- **Medium**: schema drift between Website migrations and server persistence logic.
