# Website Tooling Third-Party Agent

## Scope
Tooling manifests, formatter/linter config, CI workflow definitions, and vendored Node dependency tree.

## Responsibilities
- Maintain Node-based formatting/linting toolchain config.
- Maintain lockfile coherence with package manifest.
- Maintain workflow automation under website GitHub actions config.
- Track third-party dependency tree changes and vulnerability exposure.

## Explicit Non-Responsibilities
- Does not own PHP application logic.
- Does not own hand-authored presentation templates/assets.

## Files Under Its Authority
- `website/node_modules/**`
- `website/package.json`
- `website/package-lock.json`
- `website/.prettierignore`
- `website/.prettierrc`
- `website/.stylelintrc`
- `website/.github/**`

## Common Dependency Agents
- Website Application Backoffice Agent
- Website Presentation Assets Agent
- Security Auditor

## Modification Rules
- Dependency upgrades must update lockfile in same change.
- Lint/format config changes must be validated against repository conventions.
- Avoid manual edits in generated vendor files unless patching strategy is documented.

## Risk Zones
- Supply-chain risk from transitive dependencies.
- Massive lockfile churn obscuring intent.
- CI-tool mismatch with local formatter versions.

## Checklist Before Approving Changes
- Confirm dependency diff scope is intentional.
- Confirm lockfile integrity and reproducibility.
- Confirm workflows reference available scripts/tools.
