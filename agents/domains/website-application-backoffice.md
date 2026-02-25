# Website Application Backoffice Agent

## Scope
PHP application logic, admin panel, install/migration flows, plugin integrations, payment hooks, and root PHP entrypoints.

## Responsibilities
- Maintain account/auth/character/business logic in system/admin/install code.
- Maintain migration execution and database abstraction usage.
- Maintain plugin contracts and payment integration behavior.
- Maintain root PHP routing files and environment configuration semantics.

## Explicit Non-Responsibilities
- Does not own static presentation asset packs in `images/`, `templates/`, and `tools/`.
- Does not own third-party Node package contents.

## Files Under Its Authority
- `website/system/**`
- `website/admin/**`
- `website/install/**`
- `website/plugins/**`
- `website/payments/**`
- `website/account.php`
- `website/clientcreateaccount.php`
- `website/common.php`
- `website/config.php`
- `website/index.php`
- `website/login.php`
- `website/recaptcha_v2_content.php`
- `website/recaptcha_v3_content.php`
- `website/release.sh`
- `website/VERSION`
- `website/nginx-sample.conf`
- `website/README.md`
- `website/CHANGELOG.md`
- `website/CREDITS`
- `website/CONTRIBUTORS.txt`
- `website/LICENSE`
- `website/.editorconfig`
- `website/.gitattributes`
- `website/.gitignore`

## Common Dependency Agents
- Website Presentation Assets Agent
- Website Tooling Third-Party Agent
- CrystalServer Platform Delivery Agent (schema/config compatibility)
- Security Auditor

## Modification Rules
- Any DB-related change must align with migration ordering in `system/migrations`.
- Admin changes must include privilege/authorization review.
- Plugin contract changes require backward-compatible fallback or migration notes.

## Risk Zones
- SQL query safety and dynamic parameter handling.
- Session/login flows and password recovery endpoints.
- Installer defaults exposing insecure configurations.

## Checklist Before Approving Changes
- Confirm migration path from previous `database_version` is valid.
- Confirm admin routes enforce access restrictions.
- Confirm plugin/payment hooks fail safely.
