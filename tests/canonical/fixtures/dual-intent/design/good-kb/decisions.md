---
spine-dimension: D
owner: aid-researcher-analyst
---
# Decisions

## Use Style Dictionary for token compilation

**Decision:** Design tokens in `tokens/base.json` are compiled by Style Dictionary.
**Rationale:** Style Dictionary is the industry standard for multi-platform token
compilation; it produces CSS custom properties, JS objects, and iOS/Android outputs
from one source. Single source of truth for all token values.
**Rejected alternative:** Hand-authoring CSS custom properties -- rejected because it
creates a maintenance burden when tokens change and allows the JS/iOS values to drift.

## Tokens-only styling (no raw values in components)

**Decision:** Components reference CSS custom properties (design tokens); no raw
hex/px values allowed in component stylesheets.
**Rationale:** Ensures that theme changes (e.g. dark mode) can be implemented by
swapping token values without touching component code.
**Rejected alternative:** Utility-class-only approach (Tailwind) -- not adopted because
it exposes raw values in markup and makes token auditing harder.
