---
spine-dimension: C2
owner: aid-researcher-integrator
---
# Data Pipeline

## Conventions

Stages are connected via the registry. A new stage must:
1. Implement the `PipelineStage` interface (`src/pipeline/base.py`).
2. Be registered in `src/pipeline/registry.py` with a unique key.
3. Declare its input schema(s) and output schema(s) in this doc.

## Contracts

Stage I/O contracts:

| Stage | Input | Output |
|-------|-------|--------|
| ingest | raw S3 events (JSON, newline-delimited) | events table rows |
| feature-engineering | events rows | feature_vectors table rows |
| model-inference | feature_vectors rows | predictions table rows |
| campaign-dispatch | predictions rows | campaign_queue messages |

## Invariants

- Stages must be idempotent: running a stage twice on the same input must produce
  the same output without side effects.
- Stage order is fixed: ingest -> feature-engineering -> model-inference -> campaign-dispatch.
