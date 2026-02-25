# Intelligent Orchestration Simulation

## Request
Create Daily Task System with progressive rank UI and creature render with frag counter

## Feature Type
Hybrid system

## Activated agents
- code-review-guardian
- crystalserver-data-gameplay
- crystalserver-gameplay-runtime
- otclient-assets-distribution
- otclient-ui-modules
- performance-auditor
- project-architect
- security-auditor
- system-orchestrator

## Layer impact
- Server Gameplay Runtime
- Datapack Content
- OTClient UI + UX

## Risk score
- Level: Medium
- Score: 60

## Required approvals
- Code Review Guardian
- CrystalServer Data Gameplay
- CrystalServer Gameplay Runtime
- OTClient UI Modules
- Performance Auditor
- Security Auditor

## Generated boilerplate structure
- `crystalserver/src/game/systems/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter_system.hpp`
- `crystalserver/src/game/systems/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter_system.cpp`
- `crystalserver/src/io/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter/io_daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter.hpp`
- `crystalserver/src/io/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter/io_daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter.cpp`
- `crystalserver/src/server/network/protocol/protocolgame.cpp`
- `crystalserver/src/server/network/protocol/protocolgame.hpp`
- `crystalserver/schema.sql`
- `crystalserver/data/scripts/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter/init.lua`
- `otclient/src/client/protocolgameparse.cpp`
- `otclient/src/client/protocolgamesend.cpp`
- `otclient/modules/game_daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter.lua`
- `otclient/modules/game_daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter.otui`
- `otclient/modules/game_daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter/game_daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter.otmod`

## Generated file tree
```text
crystalserver/src/game/systems/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter_system.hpp
crystalserver/src/game/systems/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter_system.cpp
crystalserver/src/io/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter/io_daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter.hpp
crystalserver/src/io/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter/io_daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter.cpp
crystalserver/src/server/network/protocol/protocolgame.cpp
crystalserver/src/server/network/protocol/protocolgame.hpp
crystalserver/schema.sql
crystalserver/data/scripts/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter/init.lua
otclient/src/client/protocolgameparse.cpp
otclient/src/client/protocolgamesend.cpp
otclient/modules/game_daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter.lua
otclient/modules/game_daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter/daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter.otui
otclient/modules/game_daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter/game_daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter.otmod
```

## Generated code skeleton examples
### server_class
```
class DailyTaskSystemWithProgressiveRankUiAndCreatureRenderWithFragCounterSystem {
public:
  bool init();
  void onKill(const std::shared_ptr<Player>& killer, const std::shared_ptr<Creature>& target);
  void onLogin(const std::shared_ptr<Player>& player);
};
```
### persistence
```
class IODailyTaskSystemWithProgressiveRankUiAndCreatureRenderWithFragCounter {
public:
  static bool load(const std::shared_ptr<Player>& player);
  static bool save(const std::shared_ptr<Player>& player);
};
```
### opcode
```
constexpr uint8_t ClientOpcodeDailyTaskSystemWithProgressiveRankUiAndCreatureRenderWithFragCounterAction = 0xE0;
constexpr uint8_t ServerOpcodeDailyTaskSystemWithProgressiveRankUiAndCreatureRenderWithFragCounterState = 0xE1;
```
### packet_handler
```
void ProtocolGame::parseDailyTaskSystemWithProgressiveRankUiAndCreatureRenderWithFragCounterAction(NetworkMessage& msg);
void ProtocolGame::sendDailyTaskSystemWithProgressiveRankUiAndCreatureRenderWithFragCounterState(const std::shared_ptr<Player>& player);
```
### sql
```
CREATE TABLE IF NOT EXISTS player_daily_task_system_with_progressive_rank_ui_and_creature_render_with_frag_counter (
  player_id INT UNSIGNED NOT NULL,
  charm_id SMALLINT UNSIGNED NOT NULL,
  value BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY (player_id, charm_id)
);
```
### storage
```
Storage.DailyTaskSystemWithProgressiveRankUiAndCreatureRenderWithFragCounter = {
  Version = 93000,
  Points = 93001,
  UnlockBase = 93100
}
```
### client_module
```
function init()
  connect(g_game, { onGameStart = refreshDailyTaskSystemWithProgressiveRankUiAndCreatureRenderWithFragCounter, onGameEnd = clearDailyTaskSystemWithProgressiveRankUiAndCreatureRenderWithFragCounter })
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
