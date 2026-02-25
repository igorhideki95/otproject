# Blueprint: OTClient UI Module

## Feature Class
UI module

## Required File Structure
- `otclient/modules/game_<feature>/<feature>.lua`
- `otclient/modules/game_<feature>/<feature>.otui`
- `otclient/modules/game_<feature>/game_<feature>.otmod`
- `otclient/data/styles/<feature>.otui` (optional)

## Class Skeletons
```lua
local <feature>Window

function init()
  connect(g_game, { onGameStart = online, onGameEnd = offline })
end

function terminate()
  disconnect(g_game, { onGameStart = online, onGameEnd = offline })
end
```

## Registration Points
- module autoload in startup flow (`otclient/init.lua` or `.otmod` dependencies)

## SQL Schema Template
```sql
-- N/A unless UI needs persisted web/server state
```

## Storage Key Mapping
```lua
-- N/A by default
```

## Opcode Definition Template
```cpp
// Optional, if module triggers custom protocol actions
```

## Packet Handler Template
```lua
-- connect to g_game callbacks fed by protocol parser
```

## Client Module Template
```otui
<Feature>Window < MainWindow
  id: <feature>Window
```

## Validation Checklist
- [ ] init/terminate idempotent
- [ ] no leaked event bindings
- [ ] UI state sync with server updates

## Required Approvals
- OTClient UI Modules
- OTClient Engine Runtime (if protocol-coupled)
- Code Review Guardian
