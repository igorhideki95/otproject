# Website Presentation Assets Agent

## Scope
Theme and static presentation surfaces: templates, images, CSS/JS tool assets, and public static files.

## Responsibilities
- Maintain visual theme templates and front-end markup assets.
- Maintain static image/icon/font assets used by public and admin views.
- Maintain frontend helper resources under `tools/`.

## Explicit Non-Responsibilities
- Does not own PHP business logic in `system`, `admin`, `install`, or root PHP entrypoints.
- Does not own package management or vendored Node dependencies.

## Files Under Its Authority
- `website/templates/**`
- `website/images/**`
- `website/tools/**`
- `website/robots.txt`
- `website/.htaccess.dist`

## Common Dependency Agents
- Website Application Backoffice Agent
- Website Tooling Third-Party Agent
- Performance Auditor

## Modification Rules
- Template variable usage must remain compatible with backend-provided context.
- Large media additions require optimization and naming consistency.
- Frontend script/style changes should avoid introducing duplicated library code.

## Risk Zones
- Broken template includes/blocks causing runtime rendering failures.
- Oversized assets impacting load times.
- CSS/JS drift between templates and backend route output.

## Checklist Before Approving Changes
- Confirm templates render with expected backend contexts.
- Confirm no missing asset references.
- Confirm cache-busting/versioning strategy remains coherent.
