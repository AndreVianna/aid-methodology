---
kb-category: primary
source: hand-authored
objective: Act-back representative-task fixture schemas doc.
summary: Data contracts for the EventPipeline project. Carries Contracts section
  (expected owner per owning-table).
sources: []
tags: [test-fixture]
---

# Schemas

This document states the data contracts for the EventPipeline project.

## Contracts

- All pipeline events must conform to the `Event` interface: `{ id: string; type: string; payload: unknown; timestamp: number }`.
- The `id` field must be a non-empty UUID string.
- Adding a new required field to `Event` requires a migration guide and a major schema version bump.
- New optional fields may be added in a minor version bump with no migration required.
- Stage result contracts: every stage emits `{ ok: boolean; data?: unknown; error?: string }`.
