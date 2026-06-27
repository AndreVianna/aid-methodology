---
kb-category: primary
source: hand-authored
objective: Act-back representative-task fixture tech-debt doc.
summary: Known risks and gotchas for the EventPipeline project. Carries Gotchas
  section (expected owner per owning-table).
sources: []
tags: [test-fixture]
---

# Tech Debt and Known Risks

This document captures non-obvious traps and known technical debt.

## Gotchas

- Adding a new required field to the Event schema ALSO requires updating the
  entry-stage validator; failing to do so silently accepts invalid events.
- The registry file (`src/pipeline/registry.ts`) must be updated in the SAME
  commit as the new stage implementation; a stage that is implemented but not
  registered is silently skipped.
- TypeScript `unknown` payload fields require explicit type guards before access;
  omitting a type guard causes a runtime error only at the affected payload shape.
