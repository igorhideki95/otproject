# Blueprint: Persistent System

## Feature Class
Persistence system

## Required File Structure
- `crystalserver/src/io/<feature>/io_<feature>.hpp`
- `crystalserver/src/io/<feature>/io_<feature>.cpp`
- `crystalserver/src/database/migrations/<feature>_*.sql` (or project migration equivalent)
- `crystalserver/schema.sql`

## Class Skeletons
```cpp
class IO<Feature> {
public:
  static bool load(const std::shared_ptr<Player>& player);
  static bool save(const std::shared_ptr<Player>& player);
};
```

## Registration Points
- load path in `IOLoginData::loadPlayer`
- save path in `IOLoginData::savePlayer`

## SQL Schema Template
```sql
CREATE TABLE IF NOT EXISTS player_<feature> (
  player_id INT UNSIGNED NOT NULL,
  key_id INT UNSIGNED NOT NULL,
  value BIGINT NOT NULL DEFAULT 0,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (player_id, key_id)
);
```

## Storage Key Mapping
```cpp
namespace Storage<Feature> {
constexpr uint32_t Version = 92000;
constexpr uint32_t DataStart = 92010;
}
```

## Opcode Definition Template
```cpp
// N/A by default; add only if persistence must sync live
```

## Packet Handler Template
```cpp
// Optional: send snapshot after login
void ProtocolGame::send<Feature>Snapshot();
```

## Client Module Template
```lua
-- Optional if user-facing
```

## Validation Checklist
- [ ] schema migration up/down tested
- [ ] load/save symmetry validated
- [ ] null/default behavior for legacy players

## Required Approvals
- CrystalServer Persistence Scripting
- CrystalServer Platform Delivery
- Code Review Guardian
- Security Auditor
