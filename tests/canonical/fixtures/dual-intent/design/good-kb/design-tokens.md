---
spine-dimension: C5
owner: aid-researcher-analyst
---
# Design Tokens

## Contracts

Tokens are defined in `tokens/base.json` (JSON format) and compiled to CSS custom
properties via Style Dictionary.

### Color tokens

| Token | Value | Type | Usage |
|-------|-------|------|-------|
| color-primary-500 | #2563eb | color | Primary interactive elements |
| color-primary-700 | #1d4ed8 | color | Primary hover state |
| color-neutral-50 | #f8fafc | color | Page background |
| color-danger-500 | #dc2626 | color | Error states, destructive actions |

### Spacing tokens

| Token | Value | Type | Usage |
|-------|-------|------|-------|
| space-1 | 4px | spacing | Tight spacing between related elements |
| space-2 | 8px | spacing | Default padding within components |
| space-4 | 16px | spacing | Section padding, card inner margin |
| space-8 | 32px | spacing | Section separation |

### Typography tokens

| Token | Value | Type |
|-------|-------|------|
| font-size-sm | 14px | typography |
| font-size-md | 16px | typography |
| font-size-lg | 20px | typography |
| font-weight-regular | 400 | typography |
| font-weight-bold | 700 | typography |

## Conventions

To add a new token:
1. Add the token to `tokens/base.json` under the correct category key.
2. Token name must follow the pattern `<category>-<scale>` (e.g. `color-primary-600`).
3. Run `npm run build:tokens` to compile; committed output goes into `dist/tokens/`.
4. Document the new token in this file under the correct section.

## Invariants

- Token values must be raw values (hex, px, unitless number) -- no references to other tokens
  in `base.json` (they are resolved by Style Dictionary).
- Token names must be unique across all categories.
- Do not add tokens without a documented usage; unused tokens are pruned at each release.
