---
kb-category: primary
source: hand-authored
objective: Act-back PASS fixture coding standards -- Conventions section present.
summary: Coding standards for the EventPipeline project. The Conventions section
  is a named, greppable first-class section so the M4 act-back reviewer can plan
  a contract change using the project's own naming and registration rules.
sources: []
tags: [test-fixture]
---

# Coding Standards

This document states the project's conventions for implementing changes.

## Conventions

- New pipeline stages are named in lowercase-hyphen format (e.g. `validate-payload`).
- Every stage must be registered in `src/pipeline/registry.ts` after implementation.
- Handler functions use the signature `(event: Event, ctx: Context) => Promise<Result>`.
- Error handling: always wrap stage logic in try/catch; re-throw as `PipelineError`.
- New fields added to contracts must follow the `camelCase` naming convention.
- Optional fields use the `?` suffix in TypeScript interface declarations.
