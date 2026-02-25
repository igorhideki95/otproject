# OTClient UI Modules Agent

## Scope
OTClient Lua-driven UX and gameplay-facing interface modules, startup scripts, and module metadata.

## Responsibilities
- Maintain module lifecycle, UI composition (`.otui`), and feature logic (`.lua`).
- Maintain startup orchestration from Lua entrypoints.
- Maintain gameplay feature modules (inventory, market, questlog, cyclopedia, shaders, store, etc.).

## Explicit Non-Responsibilities
- Does not own C++ runtime in `otclient/src`.
- Does not own binary/art assets in `otclient/data`.

## Files Under Its Authority
- `otclient/modules/**`
- `otclient/mods/**`
- `otclient/init.lua`
- `otclient/meta.lua`
- `otclient/otclientrc.lua`

## Common Dependency Agents
- OTClient Engine Runtime Agent
- OTClient Assets Distribution Agent
- CrystalServer Data Gameplay Agent

## Modification Rules
- New module must declare dependencies and load order explicitly.
- UI widget additions must keep style/theme compatibility with existing `client_styles`.
- Lua logic that depends on server opcodes/features must be feature-gated.

## Risk Zones
- Event callback leaks causing duplicate handlers on reload.
- Tight coupling between module state and protocol assumptions.
- Heavy UI update loops degrading frame rate.

## Checklist Before Approving Changes
- Confirm module enable/disable lifecycle is clean.
- Confirm no orphan keybinds/events remain after unload.
- Confirm localization/style references resolve correctly.
