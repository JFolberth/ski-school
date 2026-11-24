---
name: azure-architecture-diagrams
description: Update and validate this repository's TerraVision Azure architecture diagrams. Use when changing diagram resources, boundaries, flows, icons, layouts, tooltips, interactions, or generated previews.
---

# Azure architecture diagrams

1. Read `docs/diagrams/README.md` and the relevant graph, annotation and
   renderer files before editing. The guide maps each diagram to its Terraform
   and application sources and documents the current regeneration commands.
2. Verify changed relationships against the relevant checked-in configuration
   and code. These are manually mapped logical views, not Terraform plans or
   live Azure discovery. Do not imply successful deployment, telemetry
   ingestion, regional support or failover without evidence. Distinguish
   runtime, image-pull and deployment identities, as well as resource-group
   ownership from separate state and logical containers.
3. Edit the appropriate `docs/diagrams/*.tvg.json` graph and
   `*.annotations.json` labels and details. Use `render.py` for shared rendering,
   routing or interaction changes rather than editing generated HTML or SVG.
   Keep the overview environment-neutral: do not add specific region names or
   environment labels unless requested. Keep authentication and regional
   availability details accurate and appropriately qualified.
4. Preserve the overview's green request, purple telemetry and orange image-pull
   flows, numbered request steps, group boundaries, nested Foundry hierarchy,
   and interactive hover/focus and legend behavior unless asked to change them.
   Maintain keyboard accessibility and reduced-motion behavior. Source icons
   from appropriate official resources and retain third-party license notices.
5. Regenerate affected HTML and SVG outputs with the documented commands.
   Refresh `docs/diagrams/architecture.png` when the overview's visible SVG
   changes. A tooltip-only change needs the HTML refreshed, not the static
   preview. Regenerate all affected views when shared renderer logic changes.
6. Inspect the rendered result for legibility, containment, arrow direction and
   crossings. For interaction changes, verify hover and keyboard focus for
   groups and steps, flow highlighting, and existing node interactions in the
   local browser when available. Run `git diff --check`; report any validation
   that could not be performed.

Do not include credentials, state, tenant or subscription IDs, private endpoints,
or telemetry endpoint URLs in diagram artifacts. Do not initialize Terraform,
access state, deploy resources, or invoke external annotation services to render
these diagrams. Make product documentation changes only when requested.
