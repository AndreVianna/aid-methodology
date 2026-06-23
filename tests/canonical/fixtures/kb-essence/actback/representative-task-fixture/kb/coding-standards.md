---
kb-category: primary
source: hand-authored
objective: Act-back representative-task fixture coding standards doc.
summary: Coding standards for the EventPipeline project. Carries Conventions
  section (expected owner per owning-table).
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
