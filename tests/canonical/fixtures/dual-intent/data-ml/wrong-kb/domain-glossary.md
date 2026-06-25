---
spine-dimension: C4
owner: aid-researcher-analyst
---
# Domain Glossary

## Event

A user action captured by the tracking system. Each event has a type, a user, and
a timestamp. Events are immutable after write.

## Feature Vector

A fixed-length numeric array derived from raw events for use as model input.
Computed by the feature-engineering pipeline stage.

## Segment

A classification of a user_profile that determines which features and pricing tier
they access. Valid values: free, pro, enterprise.

## Pipeline Run

A scheduled or triggered execution of the full ETL pipeline from raw events to
model predictions. Each run produces a versioned artifact set.

## Model Card

A structured document describing a trained model's purpose, training data,
evaluation results, and known limitations.

## Invariants

- All terms in this glossary correspond to concepts used in the codebase and schemas.
- No abbreviations are used as primary term entries; the full form is the canonical name.
