# Blueprint: Gameplay System

## Feature Class
Gameplay system

## Required File Structure
- `crystalserver/src/game/systems/<feature>/<feature>_system.hpp`
- `crystalserver/src/game/systems/<feature>/<feature>_system.cpp`
- `crystalserver/src/creatures/<hooks as needed>`
- `crystalserver/data/scripts/<feature>/`
- `otclient/modules/game_<feature>/`

## Class Skeletons
```cpp
class <Feature>System {
public:
  bool init();
  void onCreatureKill(const std::shared_ptr<Player>& killer, const std::shared_ptr<Creature>& target);
  void onCombatResolved(const CombatContext& ctx);
};
```

## Registration Points
- `Game` startup init path
- combat/death hook path in `creatures/combat` or `creature.cpp`
- datapack script registration loader

## SQL Schema Template
```sql
ALTER TABLE players
  ADD COLUMN <feature>_version SMALLINT NOT NULL DEFAULT 1;
```

## Storage Key Mapping
```lua
Storage.<Feature> = {
  Version = 91000,
  Progress = 91001,
  Points = 91002
}
```

## Opcode Definition Template
```cpp
enum class GameServerOpcode : uint8_t {
  <Feature>State = 0xD0,
  <Feature>Update = 0xD1,
};
```

## Packet Handler Template
```cpp
void ProtocolGame::send<Feature>State(const std::shared_ptr<Player>& player);
void ProtocolGame::parse<Feature>Action(NetworkMessage& msg);
```

## Client Module Template
```lua
function init()
  connect(g_game, { onGameStart = refresh<Feature>, onGameEnd = clear<Feature> })
end
```

## Validation Checklist
- [ ] gameplay hooks deterministic and bounded
- [ ] datapack IDs and references valid
- [ ] server/client protocol sync validated
- [ ] migrations backward compatible

## Required Approvals
- CrystalServer Gameplay Runtime
- CrystalServer Data Gameplay
- OTClient UI Modules
- Code Review Guardian
