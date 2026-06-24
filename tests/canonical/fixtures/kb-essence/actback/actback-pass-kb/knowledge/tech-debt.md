---
kb-category: primary
source: hand-authored
objective: Act-back PASS fixture tech-debt doc -- Gotchas section present.
summary: Known risks and gotchas for the EventPipeline project. The Gotchas
  section is a named, greppable first-class section so the M4 reviewer can
  anticipate non-obvious traps when planning a contract-field addition.
sources: []
tags: [test-fixture]
---

# Tech Debt and Known Risks

This document captures non-obvious traps and known technical debt.

## Gotchas

- Adding a new required field to the Event schema ALSO requires updating the
  entry-stage validator in `src/pipeline/stages/validate-payload.ts`; failing
  to do so silently accepts invalid events at runtime.
- The registry file (`src/pipeline/registry.ts`) must be updated in the SAME
  commit as the new stage implementation; a stage that is implemented but not
  registered is silently skipped with no error.
- TypeScript `unknown` payload fields require explicit type guards before
  access; omitting a type guard causes a runtime error only at the affected
  payload shape, not at compile time.
- Schema version bumps must be reflected in the OpenAPI spec file
  (`docs/api/openapi.yaml`) or the CI contract-drift check will fail.
