# Blueprint: Hybrid Feature

## Feature Class
Hybrid system (Gameplay + Persistence + Protocol + UI)

## Required File Structure
- `crystalserver/src/game/systems/<feature>/`
- `crystalserver/src/io/<feature>/`
- `crystalserver/src/server/network/protocol/` (feature packet handlers)
- `crystalserver/data/scripts/<feature>/`
- `otclient/src/client/protocolgame*.cpp`
- `otclient/modules/game_<feature>/`
- `crystalserver/schema.sql` and migration files

## Class Skeletons
```cpp
class <Feature>System { /* gameplay orchestration */ };
class IO<Feature> { /* persistence load/save */ };
```

## Registration Points
- server startup + gameplay hooks
- player load/save cycle
- protocol parse/send switch points
- client module startup/load order

## SQL Schema Template
```sql
CREATE TABLE IF NOT EXISTS player_<feature> (...);
ALTER TABLE players ADD COLUMN <feature>_version SMALLINT NOT NULL DEFAULT 1;
```

## Storage Key Mapping
```cpp
namespace Storage<Feature> { constexpr uint32_t Version = 93000; }
```

## Opcode Definition Template
```cpp
constexpr uint8_t ClientOpcode<Feature>Action = 0xE0;
constexpr uint8_t ServerOpcode<Feature>State = 0xE1;
```

## Packet Handler Template
```cpp
void ProtocolGame::parse<Feature>Action(NetworkMessage& msg);
void ProtocolGame::send<Feature>State(const std::shared_ptr<Player>& player);
```

## Client Module Template
```lua
function request<Feature>Action(...)
  g_game.send<Feature>Action(...)
end
```

## Validation Checklist
- [ ] ownership/deps/impact/drift/report checks green
- [ ] server/client protocol compatibility verified
- [ ] persistence migration + rollback verified
- [ ] combat/performance sampling for hot paths
- [ ] security review for parser and action authorization

## Required Approvals
- CrystalServer Gameplay Runtime
- CrystalServer Persistence Scripting
- CrystalServer Network Session
- CrystalServer Data Gameplay
- OTClient Engine Runtime
- OTClient UI Modules
- Code Review Guardian
- Security Auditor
- Performance Auditor
