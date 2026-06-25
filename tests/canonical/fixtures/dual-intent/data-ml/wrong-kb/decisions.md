---
spine-dimension: D
owner: aid-researcher-analyst
---
# Decisions

## Use Pydantic for schema validation

**Decision:** All data schema validation uses Pydantic v2 models.
**Rationale:** Provides runtime type checking with Python type annotations; integrates
with FastAPI for any future API layer; generates JSON Schema for documentation.
**Rejected alternative:** Marshmallow -- considered but lacks native Python type annotation
integration and requires separate schema + model definitions.

## Additive-only schema changes

**Decision:** All schema changes are additive (new fields only); field removal requires
a deprecation period of at least one pipeline-run cycle.
**Rationale:** Downstream consumers (models, campaign-dispatch) are deployed independently;
a field removed without warning breaks them. The deprecation window allows safe rollover.
**Rejected alternative:** Allowing field removal with a single migration -- rejected because
it caused a production outage when campaign-dispatch was not updated in lockstep.
