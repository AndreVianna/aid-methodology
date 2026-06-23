---
kb-category: primary
source: hand-authored
objective: Act-back FAIL fixture domain glossary -- Invariants section ABSENT (buried).
summary: Vocabulary for the EventPipeline project. The invariants governing the pipeline
  and event uniqueness are mentioned in prose rather than a named Invariants section,
  so the presence check reports Invariants absent and the M6 reviewer must infer or guess.
sources: []
tags: [test-fixture]
---

# Domain Glossary

<!-- NOTE: The ## Invariants section is INTENTIONALLY ABSENT from this doc.
     This is the act-back FAIL fixture: kb-actback-task.sh reports domain-glossary.md
     Invariants as absent, since the invariants are buried in prose definitions.
     The M6 reviewer cannot grep for invariants; it must infer them from narrative. -->

## Concept Spine

### EventPipeline

**Definition-as-used-here:** The central sequential processing chain that transforms
raw inbound events into validated, enriched output. It is important that all events
enter only through this pipeline and that stage ordering not be hardcoded. Each Event
id should be unique; duplicate ids are handled at entry. More constraints on these
behaviors can be inferred from reading the source code.

### PipelineStage

**Definition-as-used-here:** A discrete, independently-testable processing unit
within the EventPipeline. Stages are composable and ordered by the registry.

### Event

**Definition-as-used-here:** The unit of work flowing through the pipeline. Every
Event has an id, type, payload, and timestamp. See schemas.md for more details.
