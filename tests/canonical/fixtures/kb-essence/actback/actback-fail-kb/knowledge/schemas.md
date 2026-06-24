---
kb-category: primary
source: hand-authored
objective: Act-back FAIL fixture schemas doc -- Contracts section ABSENT (buried).
summary: Data contracts for the EventPipeline project. The contract details are
  described in narrative paragraphs rather than a named Contracts section, so the
  presence check reports schemas.md Contracts as absent and the M4 reviewer must
  guess or reach for source for the exact contract shape.
sources: []
tags: [test-fixture]
---

# Schemas

<!-- NOTE: The ## Contracts section is INTENTIONALLY ABSENT from this doc.
     This is the act-back FAIL fixture: kb-actback-task.sh reports schemas.md
     Contracts as absent. The contract information is buried in prose so the
     M4 reviewer cannot locate the exact contract shape for planning a field
     addition without guessing or reaching for source.
     schemas.md is an expected Contracts owner per the owning-table (C5). -->

This document describes data formats used in the EventPipeline project.

Events flowing through the pipeline have a standard shape that includes an id
(a UUID), a type string, a payload of unknown structure, and a numeric timestamp.
When adding fields, a required field addition normally requires a version bump and
a migration guide, while optional fields can be added more freely. Stages emit
results indicating success or failure with optional data. For the precise interface
definitions see the TypeScript source files in `src/`.
