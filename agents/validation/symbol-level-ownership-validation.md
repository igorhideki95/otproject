# Symbol-Level Ownership Validation

## Method
- Cross-checked high-impact symbols in CrystalServer, OTClient, and Website against the file-partition rules in `agents/README.md`.
- Validated ownership by source path and reviewed coupling via direct includes/calls observed in key runtime files.

## Symbol Map

| Symbol / System | File | Owning Agent | Why ownership is correct | Cross-agent dependencies | Ambiguity | File-level partition hiding coupling? |
|---|---|---|---|---|---|---|
| `class Player` | `crystalserver/src/creatures/players/player.hpp` | CrystalServer Gameplay Runtime | Player state and gameplay behavior live in creature/game domain. | Network Session (`ProtocolGame` send paths), Persistence Scripting (`IOLoginData` save/load), Data Gameplay (Lua callbacks). | Medium | Yes: player includes networking-facing send helpers and persistence-impacting state transitions. |
| `class ProtocolGame` | `crystalserver/src/server/network/protocol/protocolgame.cpp` | CrystalServer Network Session | Network ingress/egress, opcode decode, session lifecycle. | Gameplay Runtime (`g_game().playerMove`, actions), Persistence Scripting (`IOLoginData`, auth/preload). | Medium | Yes: `login()` performs policy/auth checks and deep gameplay placement calls. |
| `IOLoginData::loadPlayer/savePlayer` | `crystalserver/src/io/iologindata.cpp` | CrystalServer Persistence Scripting | Data model hydration/dehydration and DB reads/writes. | Gameplay Runtime (`Player` fields), Platform Delivery (`schema.sql` compatibility), Website Backoffice (shared DB model). | Low | Yes: load/save sequences rely on gameplay object internals and invariants. |
| `Game::combatChangeHealth` family | `crystalserver/src/game/game.cpp`, `crystalserver/src/creatures/combat/combat.cpp` | CrystalServer Gameplay Runtime | Authoritative combat application and side effects are gameplay responsibilities. | Data Gameplay (script callbacks), Network Session (result packets), Persistence (save scheduling). | Medium | Yes: combat path triggers sound/effects/network and script hooks. |
| `Creature::onDeath`, `Monster::dropLoot` | `crystalserver/src/creatures/creature.cpp`, `crystalserver/src/creatures/monsters/monster.cpp` | CrystalServer Gameplay Runtime | Death and loot are core simulation decisions. | Data Gameplay (death events), Network Session (death notifications), Persistence (status/save). | Medium | Yes: script and persistence side-effects are embedded in runtime path. |
| Dispatcher/event loop | `crystalserver/src/game/scheduling/dispatcher.*` and `otclient/src/framework/core/eventdispatcher.*` | CrystalServer Gameplay Runtime / OTClient Engine Runtime | Scheduling and deferred execution are runtime execution controls. | All runtime agents call dispatcher. | High | Yes: global schedulers are hidden shared infrastructure across features. |
| Packet receive pipeline | `crystalserver/src/server/network/protocol/protocolgame.cpp::parsePacket*` | CrystalServer Network Session | It is the trust boundary for remote input. | Gameplay Runtime, Persistence Scripting, Security Auditor. | Low | Partially: opcode handlers directly call gameplay and DB-triggering operations. |
| OTClient `ProtocolGame::parseMessage` | `otclient/src/client/protocolgameparse.cpp` | OTClient Engine Runtime | Client-side packet decode and model update. | OTClient UI Modules (`g_game` events), CrystalServer Network Session (protocol compatibility). | Low | Yes: parser dispatch reaches Lua callbacks and UI-facing game state. |
| OTClient module bootstrap (`g_modules`) | `otclient/init.lua`, `otclient/modules/**` | OTClient UI Modules | Module discovery/load order and UI feature registration are Lua-module responsibilities. | OTClient Engine Runtime (`g_game`, protocol features), Assets Distribution (styles/resources). | Low | Moderate: modules rely on implicit runtime feature flags/opcodes. |
| Website migration runner | `website/system/migrate.php` | Website Application Backoffice | DB schema progression is backend app responsibility. | CrystalServer Platform Delivery (`schema.sql`), Tooling agent (release process). | Low | Low |

## Mixed-Responsibility Files and Refactor Segmentation

### 1) `crystalserver/src/server/network/protocol/protocolgame.cpp`
- **Issue**: Contains transport parsing, auth policy checks, waiting-list policy, gameplay invocation, and packet serialization in one compilation unit.
- **Refactor plan**:
  - `protocolgame_session.cpp` (handshake/login/logout/session state)
  - `protocolgame_parse.cpp` (opcode decode and routing only)
  - `protocolgame_actions.cpp` (delegation to gameplay commands)
  - `protocolgame_serialize.cpp` (all `send*` packet writers)

### 2) `crystalserver/src/creatures/players/player.cpp`
- **Issue**: Blends domain model, protocol send wrappers, market/shop flows, imbuements, party/social, and persistence-sensitive state.
- **Refactor plan**:
  - `player_state.cpp` (core state transitions)
  - `player_social.cpp` (guild/party/vip/chat)
  - `player_economy.cpp` (shop/trade/imbuement-related economics)
  - `player_protocol_bridge.cpp` (send wrappers to `ProtocolGame`)

### 3) `crystalserver/src/game/game.cpp`
- **Issue**: Central god-object with combat, map operations, looting, login checks, and utility subsystems.
- **Refactor plan**:
  - `game_session_flow.cpp` (login/logout/death-screen activity)
  - `game_combat_flow.cpp` (damage application and effects)
  - `game_loot_flow.cpp` (corpse/direct loot/reward chest)
  - `game_world_ops.cpp` (movement/map tile state)

### 4) `otclient/src/client/protocolgameparse.cpp`
- **Issue**: Large opcode switch with heterogeneous UI and model side-effects.
- **Refactor plan**:
  - Segment by protocol domains: map, containers, social, combat, store, meta/system.
  - Keep single registration table but split handlers into focused units.
