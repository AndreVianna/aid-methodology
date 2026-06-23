---
kb-category: primary
source: hand-authored
objective: Act-back PASS fixture schemas doc -- Contracts section present.
summary: Data contracts for the EventPipeline project. The Contracts section is
  a named, greppable first-class section so the M6 reviewer can plan a field
  addition against a stated contract rather than guessing the schema.
sources: []
tags: [test-fixture]
---

# Schemas

This document states the data contracts for the EventPipeline project.

## Contracts

- All pipeline events must conform to the `Event` interface:
  `{ id: string; type: string; payload: unknown; timestamp: number }`.
- The `id` field must be a non-empty UUID string.
- Adding a new required field to `Event` requires a migration guide and a
  major schema version bump (e.g. `1.x.x` -> `2.0.0`).
- New optional fields may be added in a minor version bump (e.g. `1.2.x` ->
  `1.3.0`) with no migration required.
- Stage result contracts: every stage emits
  `{ ok: boolean; data?: unknown; error?: string }`.
- Contract changes must be reflected in the entry-stage validator within the
  same PR as the schema change.
