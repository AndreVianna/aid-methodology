---
kb-category: primary
source: hand-authored
objective: Act-back representative-task fixture domain glossary.
summary: Vocabulary for the EventPipeline project. Carries Invariants section
  (expected owner per owning-table).
sources: []
tags: [test-fixture]
---

# Domain Glossary

## Concept Spine

### EventPipeline

**Definition-as-used-here:** The central sequential processing chain that transforms
raw inbound events into validated, enriched output. Each stage receives the event and
context from the previous stage and returns a result; the pipeline halts on the first
stage error.

### PipelineStage

**Definition-as-used-here:** A discrete, independently-testable processing unit
within the EventPipeline. Stages are composable and ordered; the registry determines
execution order.

### Event

**Definition-as-used-here:** The unit of work flowing through the pipeline. Every
Event has an id, type, payload, and timestamp; the schemas.md Contracts section
governs the full structural invariant.

## Invariants

- The EventPipeline is the ONLY entry point for processing inbound events; no stage
  is invoked directly from outside the pipeline.
- Stage order is determined solely by the registry; never hardcoded in stage logic.
- Every Event id must be globally unique; duplicate ids are rejected at the entry stage.
