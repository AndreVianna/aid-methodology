---
spine-dimension: C3
owner: aid-researcher-analyst
---
# Design Principles

## Conventions

- All new components must have a Storybook story covering all variants.
- Component TypeScript props interface is the canonical contract; no untyped props.
- Variant naming: lowercase, hyphen-separated (e.g. `primary-large`).
- New components are registered in `src/components/index.ts` with a named export.
- Token usage: components must reference tokens (CSS custom properties) -- no raw
  hex/px values in component stylesheets.
- Accessibility: all interactive components must have ARIA roles and keyboard support.
