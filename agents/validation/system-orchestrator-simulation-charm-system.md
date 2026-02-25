# Intelligent Orchestration Simulation

## Request
Create Charm System

## Feature Type
Hybrid system

## Activated agents
- code-review-guardian
- crystalserver-data-gameplay
- crystalserver-gameplay-runtime
- crystalserver-network-session
- crystalserver-persistence-scripting
- crystalserver-platform-delivery
- otclient-assets-distribution
- otclient-engine-runtime
- otclient-ui-modules
- performance-auditor
- project-architect
- security-auditor
- system-orchestrator

## Layer impact
- Server Gameplay Runtime
- Datapack Content
- Persistence + Schema
- Protocol + Transport
- OTClient UI + UX

## Risk score
- Level: Critical
- Score: 100

## Required approvals
- Code Review Guardian
- CrystalServer Data Gameplay
- CrystalServer Gameplay Runtime
- CrystalServer Network Session
- CrystalServer Persistence Scripting
- CrystalServer Platform Delivery
- OTClient Engine Runtime
- OTClient UI Modules
- Performance Auditor
- Project Architect
- Security Auditor

## Generated boilerplate structure
- `crystalserver/src/game/systems/charm_system/charm_system_system.hpp`
- `crystalserver/src/game/systems/charm_system/charm_system_system.cpp`
- `crystalserver/src/io/charm_system/io_charm_system.hpp`
- `crystalserver/src/io/charm_system/io_charm_system.cpp`
- `crystalserver/src/server/network/protocol/protocolgame.cpp`
- `crystalserver/src/server/network/protocol/protocolgame.hpp`
- `crystalserver/schema.sql`
- `crystalserver/data/scripts/charm_system/init.lua`
- `otclient/src/client/protocolgameparse.cpp`
- `otclient/src/client/protocolgamesend.cpp`
- `otclient/modules/game_charm_system/charm_system.lua`
- `otclient/modules/game_charm_system/charm_system.otui`
- `otclient/modules/game_charm_system/game_charm_system.otmod`

## Generated file tree
```text
crystalserver/src/game/systems/charm_system/charm_system_system.hpp
crystalserver/src/game/systems/charm_system/charm_system_system.cpp
crystalserver/src/io/charm_system/io_charm_system.hpp
crystalserver/src/io/charm_system/io_charm_system.cpp
crystalserver/src/server/network/protocol/protocolgame.cpp
crystalserver/src/server/network/protocol/protocolgame.hpp
crystalserver/schema.sql
crystalserver/data/scripts/charm_system/init.lua
otclient/src/client/protocolgameparse.cpp
otclient/src/client/protocolgamesend.cpp
otclient/modules/game_charm_system/charm_system.lua
otclient/modules/game_charm_system/charm_system.otui
otclient/modules/game_charm_system/game_charm_system.otmod
```

## Generated code skeleton examples
### server_class
```
class CharmSystemSystem {
public:
  bool init();
  void onKill(const std::shared_ptr<Player>& killer, const std::shared_ptr<Creature>& target);
  void onLogin(const std::shared_ptr<Player>& player);
};
```
### persistence
```
class IOCharmSystem {
public:
  static bool load(const std::shared_ptr<Player>& player);
  static bool save(const std::shared_ptr<Player>& player);
};
```
### opcode
```
constexpr uint8_t ClientOpcodeCharmSystemAction = 0xE0;
constexpr uint8_t ServerOpcodeCharmSystemState = 0xE1;
```
### packet_handler
```
void ProtocolGame::parseCharmSystemAction(NetworkMessage& msg);
void ProtocolGame::sendCharmSystemState(const std::shared_ptr<Player>& player);
```
### sql
```
CREATE TABLE IF NOT EXISTS player_charm_system (
  player_id INT UNSIGNED NOT NULL,
  charm_id SMALLINT UNSIGNED NOT NULL,
  value BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY (player_id, charm_id)
);
```
### storage
```
Storage.CharmSystem = {
  Version = 93000,
  Points = 93001,
  UnlockBase = 93100
}
```
### client_module
```
function init()
  connect(g_game, { onGameStart = refreshCharmSystem, onGameEnd = clearCharmSystem })
end
```

## Validation checklist
- [ ] ownership --strict
- [ ] deps --strict
- [ ] impact --files <changed files>
- [ ] drift --baseline agents/automation/baseline.json --strict
- [ ] report
- [ ] CrystalServer build/tests
- [ ] OTClient build/tests

## Governance chain
1. System Orchestrator
1. Domain Owners
1. Security/Performance Auditors
1. Code Review Guardian
1. Project Architect
