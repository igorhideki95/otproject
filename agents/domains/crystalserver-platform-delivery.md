# CrystalServer Platform Delivery Agent

## Scope
CrystalServer build, packaging, configuration, schema, tests, metrics, documentation, and automation outside runtime/content trees.

## Responsibilities
- Maintain build system (CMake, vcpkg manifests, vcproj).
- Maintain deployment/bootstrap scripts and docker definitions.
- Maintain repository docs, CI workflows, and coding policies.
- Maintain SQL schema and global server config defaults.
- Maintain test harness and metrics integration files.

## Explicit Non-Responsibilities
- Does not own C++ runtime sources in `src`.
- Does not own datapack gameplay content in `data*` folders.

## Files Under Its Authority
- `crystalserver/CMakeLists.txt`
- `crystalserver/CMakePresets.json`
- `crystalserver/vcpkg.json`
- `crystalserver/schema.sql`
- `crystalserver/config.lua.dist`
- `crystalserver/linux_installer.sh`
- `crystalserver/crystal_windows_installer.ps1`
- `crystalserver/start.sh`
- `crystalserver/start_gdb.sh`
- `crystalserver/recompile.sh`
- `crystalserver/package.json`
- `crystalserver/Jenkinsfile`
- `crystalserver/GitVersion.yml`
- `crystalserver/.github/**`
- `crystalserver/cmake/**`
- `crystalserver/docker/**`
- `crystalserver/tests/**`
- `crystalserver/docs/**`
- `crystalserver/metrics/**`
- `crystalserver/vcproj/**`
- `crystalserver/*.md`
- `crystalserver/.*`
- `crystalserver/*.pem`
- `crystalserver/*.rc`
- `crystalserver/gdb_debug`

## Common Dependency Agents
- CrystalServer Network Session Agent
- CrystalServer Gameplay Runtime Agent
- CrystalServer Persistence Scripting Agent
- CrystalServer Data Gameplay Agent
- Website Application Backoffice Agent (DB compatibility)
- Code Review Guardian

## Modification Rules
- Schema changes require migration coordination with website/account flows.
- Config default changes require release-note impact statement.
- Build toolchain updates require CI workflow alignment.

## Risk Zones
- Schema drift between server and website queries.
- Packaging script assumptions across OS distributions.
- Secrets and certificates committed in repository root.

## Checklist Before Approving Changes
- Confirm build/test matrix still representative.
- Confirm schema and migration order is deterministic.
- Confirm deployment docs match actual scripts.
