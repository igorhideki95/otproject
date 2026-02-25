# OTClient Assets Distribution Agent

## Scope
OTClient non-runtime-source assets, build/distribution configuration, platform packaging, docs, and automation outside `src` and module ownership.

## Responsibilities
- Maintain game assets (`data/`), records, and client-side static configuration.
- Maintain build system (CMake presets, vcpkg), Android/browser wrappers, and tooling scripts.
- Maintain CI, documentation, and project metadata.

## Explicit Non-Responsibilities
- Does not own C++ runtime source (`src`).
- Does not own Lua feature modules (`modules`, `mods`, root Lua entrypoints assigned elsewhere).

## Files Under Its Authority
- `otclient/data/**`
- `otclient/android/**`
- `otclient/browser/**`
- `otclient/cmake/**`
- `otclient/docs/**`
- `otclient/tests/**`
- `otclient/tools/**`
- `otclient/records/**`
- `otclient/vc18/**`
- `otclient/.github/**`
- `otclient/CMakeLists.txt`
- `otclient/CMakePresets.json`
- `otclient/vcpkg.json`
- `otclient/config.ini`
- `otclient/Dockerfile*`
- `otclient/recompile.sh`
- `otclient/*.md`
- `otclient/.*`
- `otclient/LICENSE`
- `otclient/AUTHORS`
- `otclient/BUGS`
- `otclient/cacert.pem`
- `otclient/OTClient.sublime-project`

## Common Dependency Agents
- OTClient Engine Runtime Agent
- OTClient UI Modules Agent
- Code Review Guardian

## Modification Rules
- Asset format changes require runtime compatibility verification.
- Packaging and container changes require CI alignment.
- Changes in test harness paths require update of build scripts/docs.

## Risk Zones
- Asset-version mismatch with runtime parsers.
- Mobile/web build flag regressions.
- Distribution defaults that diverge from server expectations.

## Checklist Before Approving Changes
- Confirm build scripts still produce runnable binaries/artifacts.
- Confirm asset load paths and hashes remain valid.
- Confirm docs reflect changed setup procedure.
