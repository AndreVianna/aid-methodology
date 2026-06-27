---
spine-dimension: C2
owner: aid-researcher-analyst
---
# Component Inventory

## Conventions

To add a new component:
1. Create `src/components/<ComponentName>/<ComponentName>.tsx`.
2. Define the props interface in `<ComponentName>.types.ts`.
3. Add a Storybook story at `src/components/<ComponentName>/<ComponentName>.stories.tsx`.
4. Export from `src/components/index.ts`.

## Contracts

| Component | Props interface | Token dependencies |
|-----------|----------------|-------------------|
| Button | ButtonProps | color-primary-500, color-danger-500, space-2 |
| InputField | InputFieldProps | color-neutral-50, color-danger-500, font-size-md |
| Card | CardProps | space-4, color-neutral-50 |

## Invariants

- Each component file exports exactly one named component.
- Component names are PascalCase; file names match the component name.
