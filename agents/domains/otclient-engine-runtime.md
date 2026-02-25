# OTClient Engine Runtime Agent

## Scope
OTClient native engine and protocol runtime in C++ under `otclient/src`, including framework, rendering, networking protocol, and core client object model.

## Responsibilities
- Maintain C++ framework subsystems (graphics, net, core, platform abstractions).
- Maintain game protocol parsing/sending implementation in client runtime.
- Maintain thing/item/map runtime data structures and rendering integration.
- Maintain protobuf interfaces in OTClient source tree.

## Explicit Non-Responsibilities
- Does not own Lua module gameplay/UI logic under `otclient/modules`.
- Does not own data assets and package distribution files.

## Files Under Its Authority
- `otclient/src/**`

## Common Dependency Agents
- OTClient UI Modules Agent
- OTClient Assets Distribution Agent
- CrystalServer Engine Runtime Agent (protocol contracts)
- Performance Auditor

## Modification Rules
- Packet decode/encode behavior changes require explicit server-version compatibility notes.
- Rendering pipeline changes require measurable perf/regression checks.
- Public Lua bindings exposed from C++ require module impact review.

## Risk Zones
- Protocol parser bounds handling.
- GPU resource lifecycle and draw-loop churn.
- Threading/event dispatcher synchronization.

## Checklist Before Approving Changes
- Confirm client starts and connects with expected protocol version.
- Confirm no API break for Lua modules relying on bound symbols.
- Confirm build configurations (desktop/mobile/web) remain compile-valid.
