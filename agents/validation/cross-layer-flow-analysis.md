# Cross-Layer Flow Analysis

## 1) Player login

### Trace
1. Client calls `Game::loginWorld` and `ProtocolGame::login`.  
2. Server receives first packet in `ProtocolGame::onRecvFirstMessage`.  
3. Server authenticates via `IOLoginData::gameWorldAuthentication` and preloads player (`IOLoginDataLoad::preLoadPlayer`, `IOLoginData::loadPlayerById`).  
4. Server places creature (`Game::placeCreature`) and sets session active (`ProtocolGame::acceptPackets`).  
5. Server sends enter-world and initial map packets (`sendAddCreature`, map description sends).  
6. Client parses login/map packets in `ProtocolGame::parseMessage/parseEnterGame/parseMapDescription`; UI modules react via `g_game` signals.

### Files touched
- `otclient/src/client/game.cpp`
- `otclient/src/client/protocolgame.cpp`
- `otclient/src/client/protocolgameparse.cpp`
- `otclient/modules/client_entergame/*.lua`
- `otclient/modules/game_interface/*.lua`
- `crystalserver/src/server/network/protocol/protocolgame.cpp`
- `crystalserver/src/io/iologindata.cpp`
- `crystalserver/src/io/functions/iologindata_load_player.cpp`
- `crystalserver/src/game/game.cpp`
- `crystalserver/src/creatures/players/player.cpp`

### Agents triggered
- OTClient Engine Runtime
- OTClient UI Modules
- CrystalServer Network Session
- CrystalServer Persistence Scripting
- CrystalServer Gameplay Runtime

### Circular dependency check
- No compile-time cycle, but runtime handshake couples protocol layer with persistence and gameplay placement.

### Responsibility correctness
- Correct after redesign: session/auth at Network+Persistence; world placement at Gameplay.

---

## 2) Player death

### Trace
1. Combat reduces health (`Combat::*` to `Game::combatChangeHealth`).
2. `Creature::onDeath` executes death callbacks, corpse handling, and events.
3. `Monster::death/dropLoot` or player death path applies death effects.
4. `ProtocolGame::parsePacketDead` handles dead-screen interactions and respawn requests.
5. Client parses death (`ProtocolGame::parseDeath`) and updates UI.

### Files touched
- `crystalserver/src/creatures/combat/combat.cpp`
- `crystalserver/src/game/game.cpp`
- `crystalserver/src/creatures/creature.cpp`
- `crystalserver/src/creatures/monsters/monster.cpp`
- `crystalserver/src/server/network/protocol/protocolgame.cpp`
- `crystalserver/data*/scripts/**` (death event callbacks)
- `otclient/src/client/protocolgameparse.cpp`
- `otclient/src/client/game.cpp`
- `otclient/modules/game_interface/*.lua`

### Agents triggered
- CrystalServer Gameplay Runtime
- CrystalServer Network Session
- CrystalServer Data Gameplay
- OTClient Engine Runtime
- OTClient UI Modules

### Circular dependency check
- No hard cycle; callback-induced reentry risk exists through Lua events.

### Responsibility correctness
- Correct, with hotspot in Gameplay Runtime due mixed event + loot + notification concerns.

---

## 3) Combat damage application

### Trace
1. Action/spell enters combat in `Combat::doCombat`.
2. Block/armor/shield checks and damage calculation in `Combat`.
3. Health/mana mutation via `Game::combatChangeHealth/combatChangeMana`.
4. Effects/messages emitted via `Game` and `ProtocolGame::send*`.
5. Client parses updates (`parseCreatureHealth`, related opcodes) and refreshes modules.

### Files touched
- `crystalserver/src/creatures/combat/combat.cpp`
- `crystalserver/src/game/game.cpp`
- `crystalserver/src/server/network/protocol/protocolgame.cpp`
- `otclient/src/client/protocolgameparse.cpp`
- `otclient/src/client/creature.cpp`
- `otclient/modules/game_healthinfo/*.lua`

### Agents triggered
- CrystalServer Gameplay Runtime
- CrystalServer Network Session
- OTClient Engine Runtime
- OTClient UI Modules

### Circular dependency check
- No direct cycle; shared mutable creature state is a risk.

### Responsibility correctness
- Correct; explicit coupling to packet serialization is expected and bounded.

---

## 4) Item loot drop

### Trace
1. Death path calls `Monster::dropLoot` / corpse generation.
2. Loot interactions route through `Game::playerQuickLootCorpse`, `handleCorpseLoot`, reward chest methods.
3. Container/inventory updates emitted through protocol send methods.
4. Client parses container/tile updates and module UI refreshes.

### Files touched
- `crystalserver/src/creatures/monsters/monster.cpp`
- `crystalserver/src/creatures/creature.cpp`
- `crystalserver/src/game/game.cpp`
- `crystalserver/src/server/network/protocol/protocolgame.cpp`
- `crystalserver/data*/scripts/**` (loot/death script hooks)
- `otclient/src/client/protocolgameparse.cpp`
- `otclient/modules/game_containers/*.lua`
- `otclient/modules/game_inventory/*.lua`

### Agents triggered
- CrystalServer Gameplay Runtime
- CrystalServer Network Session
- CrystalServer Data Gameplay
- OTClient Engine Runtime
- OTClient UI Modules

### Circular dependency check
- No structural cycle; event callbacks can trigger additional loot logic recursively.

### Responsibility correctness
- Correct with known hotspot in monolithic `game.cpp`.

---

## 5) Protocol packet receive → action → response

### Trace
1. Server receives packet in `ProtocolGame::parsePacket`.
2. Dispatch branch in `parsePacketFromDispatcher` maps opcode → game action (`g_game().playerMove`, parse* helpers).
3. Game runtime mutates state.
4. Protocol serializes response via `send*` methods.
5. Client parses response in `ProtocolGame::parseMessage`.

### Files touched
- `crystalserver/src/server/network/protocol/protocolgame.cpp`
- `crystalserver/src/game/game.cpp`
- `crystalserver/src/creatures/**`
- `otclient/src/client/protocolgameparse.cpp`

### Agents triggered
- CrystalServer Network Session
- CrystalServer Gameplay Runtime
- OTClient Engine Runtime

### Circular dependency check
- No compile-time cycle; runtime command/result is acyclic.

### Responsibility correctness
- Correct after split, though session file still contains action routing.

---

## 6) Database save cycle

### Trace
1. Triggered via save scheduling (`SaveManager::scheduleAll/schedulePlayer`).
2. `SaveManager::doSavePlayer` acquires lock and calls `IOLoginData::savePlayer`.
3. `IOLoginDataSave::*` composes SQL writes for player data.
4. Database layer executes statements.

### Files touched
- `crystalserver/src/game/scheduling/save_manager.cpp`
- `crystalserver/src/io/iologindata.cpp`
- `crystalserver/src/io/functions/iologindata_save_player.cpp`
- `crystalserver/src/database/database.cpp`
- `crystalserver/schema.sql`
- `website/system/migrations/*.php` (schema compatibility path)

### Agents triggered
- CrystalServer Gameplay Runtime
- CrystalServer Persistence Scripting
- CrystalServer Platform Delivery
- Website Application Backoffice

### Circular dependency check
- No static cycle; runtime coupling exists between save model and schema owners.

### Responsibility correctness
- Correct and explicitly cross-agent; requires schema governance gate.

---

## 7) Client module loading

### Trace
1. Startup script discovers modules (`g_modules.discoverModules`).
2. Ordered loads (`autoLoadModules`, `ensureModuleLoaded`) in `init.lua`.
3. Modules register UI and game event hooks (`connect(g_game, ...)`, `g_ui.loadUI/displayUI`).

### Files touched
- `otclient/init.lua`
- `otclient/modules/**.otmod`
- `otclient/modules/**.lua`
- `otclient/modules/**.otui`
- `otclient/src/framework/luaengine/**`
- `otclient/src/client/game.cpp`

### Agents triggered
- OTClient UI Modules
- OTClient Engine Runtime
- OTClient Assets Distribution

### Circular dependency check
- Module dependency cycles possible if load order misdeclared; currently controlled by staged autoload buckets.

### Responsibility correctness
- Correct; modules remain distinct from C++ runtime ownership.

---

## 8) UI event → server request → persistence → UI refresh

### Trace (example: NPC trade / buy-sell)
1. UI action in module (`game_npctrade.lua`) calls `g_game.buyItem/sellItem`.
2. OTClient protocol sender emits packet (`protocolgamesend.cpp`).
3. Server `ProtocolGame::parsePlayerBuyOnShop` / related parser routes to gameplay.
4. Gameplay updates inventory/resources and may persist on save cycle.
5. Server sends inventory/container/resource updates.
6. Client parses updates and modules refresh visible state.

### Files touched
- `otclient/modules/game_npctrade/npctrade.lua`
- `otclient/src/client/game.cpp`
- `otclient/src/client/protocolgamesend.cpp`
- `otclient/src/client/protocolgameparse.cpp`
- `crystalserver/src/server/network/protocol/protocolgame.cpp`
- `crystalserver/src/game/game.cpp`
- `crystalserver/src/io/iologindata.cpp` (eventual persistence)

### Agents triggered
- OTClient UI Modules
- OTClient Engine Runtime
- CrystalServer Network Session
- CrystalServer Gameplay Runtime
- CrystalServer Persistence Scripting

### Circular dependency check
- Request-response pipeline is acyclic; persistence is eventual and asynchronous.

### Responsibility correctness
- Correct; cross-agent handoff points are explicit.
