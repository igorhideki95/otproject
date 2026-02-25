# Blueprint: Protocol Extension

## Feature Class
Protocol extension

## Required File Structure
- `crystalserver/src/server/network/protocol/protocolgame.cpp`
- `crystalserver/src/server/network/protocol/protocolgame.hpp`
- `otclient/src/client/protocolgameparse.cpp`
- `otclient/src/client/protocolgamesend.cpp`
- `otclient/src/client/protocolcodes.*`

## Class Skeletons
```cpp
// server
void ProtocolGame::parse<Feature>Action(NetworkMessage& msg);
void ProtocolGame::send<Feature>State(const std::shared_ptr<Player>& player);

// client
void ProtocolGame::parse<Feature>State(const InputMessagePtr& msg);
void ProtocolGame::send<Feature>Action(...);
```

## Registration Points
- opcode switch in server parse dispatcher
- opcode switch in client parseMessage

## SQL Schema Template
```sql
-- Only if protocol payload requires persisted fields
```

## Storage Key Mapping
```cpp
// Optional storage ids when protocol mirrors persistent progress
```

## Opcode Definition Template
```cpp
constexpr uint8_t ClientOpcode<Feature>Action = 0xE0;
constexpr uint8_t ServerOpcode<Feature>State = 0xE1;
```

## Packet Handler Template
```cpp
case ClientOpcode<Feature>Action:
  parse<Feature>Action(msg);
  break;
```

## Client Module Template
```lua
connect(g_game, { on<Feature>State = on<Feature>State })
```

## Validation Checklist
- [ ] backward compatibility / feature gating
- [ ] parser bounds and malformed packet handling
- [ ] client/server version negotiation documented

## Required Approvals
- CrystalServer Network Session
- OTClient Engine Runtime
- Code Review Guardian
- Security Auditor
