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
    crystalserver-engine-runtime.md
    crystalserver-data-gameplay.md
    crystalserver-platform-delivery.md
    otclient-engine-runtime.md
    otclient-ui-modules.md
    otclient-assets-distribution.md
    website-application-backoffice.md
    website-presentation-assets.md
    website-tooling-thirdparty.md
```

## Single-Owner Partition Rules

Every repository file is assigned to exactly one **domain** agent by top-level prefix and sub-prefix rules:

1. `crystalserver/src/**` → `domains/crystalserver-engine-runtime.md`
2. `crystalserver/data/**`, `crystalserver/data-crystal/**`, `crystalserver/data-global/**` → `domains/crystalserver-data-gameplay.md`
3. All remaining `crystalserver/**` paths (root config, docs, build, ci, docker, tests, metrics, vcproj, cmake) → `domains/crystalserver-platform-delivery.md`
4. `otclient/src/**` → `domains/otclient-engine-runtime.md`
5. `otclient/modules/**`, `otclient/mods/**`, `otclient/init.lua`, `otclient/meta.lua`, `otclient/otclientrc.lua` → `domains/otclient-ui-modules.md`
6. All remaining `otclient/**` paths (`data`, android, browser, docs, tests, cmake, vc18, tools, records, root config/build files) → `domains/otclient-assets-distribution.md`
7. `website/system/**`, `website/admin/**`, `website/install/**`, `website/plugins/**`, `website/payments/**`, all root `website/*.php` entrypoints/config files → `domains/website-application-backoffice.md`
8. `website/templates/**`, `website/images/**`, `website/tools/**`, `website/robots.txt`, `website/.htaccess.dist` → `domains/website-presentation-assets.md`
9. `website/node_modules/**`, `website/package.json`, `website/package-lock.json`, `website/.prettier*`, `website/.stylelintrc`, `website/.github/**` → `domains/website-tooling-thirdparty.md`
10. `agents/**` governance and domain definitions → `governance/project-architect.md`

Governance agents do not own product-code paths; they own policy and escalation decisions only.

## Escalation Hierarchy

1. Project Architect (supreme coordinator)
2. Code Review Guardian (gatekeeper)
3. Security Auditor / Performance Auditor (parallel specialist blockers)
4. Refactoring Specialist (structure and debt execution)
5. Domain Agents (path owners)

Any blocked security/performance finding escalates upward to the Code Review Guardian and then to Project Architect for final approval.
