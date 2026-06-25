---
spine-dimension: C4
owner: aid-researcher-analyst
---
# Domain Glossary

## Token

A named design variable (color, spacing, typography) stored in `tokens/base.json`
and compiled to CSS custom properties. Tokens are the single source of truth for
visual constants in the system.

## Component

A reusable UI building block documented in the component inventory. Each component
has a Storybook story, a TypeScript props interface, and consumes tokens for styling.

## Variant

A named configuration of a component that changes its visual or behavioral state
(e.g. Button variant "primary" vs "secondary"). Variants are defined in the
component's props interface and Storybook stories.

## Scale

The ordinal step in a token series (e.g. 50, 100, 200...900 for colors; 1, 2, 4, 8
for spacing). Scale values follow the Tailwind convention.

## Invariants

- All terms refer to their definitions as realized in the codebase; generic design
  industry meanings may differ.
