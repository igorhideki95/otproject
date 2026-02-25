# Agent Governance Map

## Folder Tree

```text
agents/
  README.md
  governance/
    project-architect.md
    code-review-guardian.md
    refactoring-specialist.md
    security-auditor.md
    performance-auditor.md
  domains/
    crystalserver-network-session.md
    crystalserver-gameplay-runtime.md
    crystalserver-persistence-scripting.md
    crystalserver-data-gameplay.md
    crystalserver-platform-delivery.md
    otclient-engine-runtime.md
    otclient-ui-modules.md
    otclient-assets-distribution.md
    website-application-backoffice.md
    website-presentation-assets.md
    website-tooling-thirdparty.md
  validation/
    symbol-level-ownership-validation.md
    cross-layer-flow-analysis.md
    coupling-risk-map.md
    governance-weakness-and-redesign.md
    simulation-test.md
  automation/
    ownership_rules.json
    baseline.json
    README.md
  tools/
    architecture_guard.py
  ci/
    github-actions-architecture-validation.yml
```

## Single-Owner Partition Rules

Every repository file is assigned to exactly one **domain** agent by ordered first-match rules:

1. `crystalserver/src/server/**`, `crystalserver/src/security/**`, `crystalserver/src/protobuf/**`, `crystalserver/src/main.cpp`, `crystalserver/src/crystalserver.cpp`, `crystalserver/src/crystalserver.hpp` → `domains/crystalserver-network-session.md`
2. `crystalserver/src/game/**`, `crystalserver/src/creatures/**`, `crystalserver/src/items/**`, `crystalserver/src/map/**`, `crystalserver/src/enums/**`, `crystalserver/src/declarations.hpp`, `crystalserver/src/core.hpp` → `domains/crystalserver-gameplay-runtime.md`
3. `crystalserver/src/database/**`, `crystalserver/src/io/**`, `crystalserver/src/lua/**`, `crystalserver/src/account/**`, `crystalserver/src/kv/**`, `crystalserver/src/config/**`, `crystalserver/src/lib/**`, `crystalserver/src/utils/**`, `crystalserver/src/pch.cpp`, `crystalserver/src/pch.hpp` → `domains/crystalserver-persistence-scripting.md`
4. `crystalserver/data/**`, `crystalserver/data-crystal/**`, `crystalserver/data-global/**` → `domains/crystalserver-data-gameplay.md`
5. All remaining `crystalserver/**` paths (build, ci, docs, docker, metrics, tests, schema/config root files) → `domains/crystalserver-platform-delivery.md`
6. `otclient/src/**` → `domains/otclient-engine-runtime.md`
7. `otclient/modules/**`, `otclient/mods/**`, `otclient/init.lua`, `otclient/meta.lua`, `otclient/otclientrc.lua` → `domains/otclient-ui-modules.md`
8. All remaining `otclient/**` paths (`data`, android, browser, docs, tests, cmake, vc18, tools, records, root config/build files) → `domains/otclient-assets-distribution.md`
9. `website/system/**`, `website/admin/**`, `website/install/**`, `website/plugins/**`, `website/payments/**`, root `website/*.php` entrypoints/config files and website operational metadata (`VERSION`, `release.sh`, `nginx-sample.conf`, docs/license metadata) → `domains/website-application-backoffice.md`
10. `website/templates/**`, `website/images/**`, `website/tools/**`, `website/robots.txt`, `website/.htaccess.dist` → `domains/website-presentation-assets.md`
11. `website/node_modules/**`, `website/package.json`, `website/package-lock.json`, `website/.prettier*`, `website/.stylelintrc`, `website/.github/**` → `domains/website-tooling-thirdparty.md`
12. `agents/**` governance and validation definitions → `governance/project-architect.md`

Governance agents do not own product-code paths; they own policy and escalation decisions only.

## Escalation Hierarchy

1. Project Architect (supreme coordinator)
2. Code Review Guardian (quality gate)
3. Security Auditor / Performance Auditor (parallel specialist blockers)
4. Refactoring Specialist (boundary and debt execution)
5. Domain Agents (path owners)

Any unresolved security/performance blocker escalates to Code Review Guardian, then Project Architect for final disposition.
