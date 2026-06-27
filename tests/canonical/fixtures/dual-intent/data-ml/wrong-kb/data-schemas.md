---
spine-dimension: C5
owner: aid-researcher-analyst
---
# Data Schemas

## Contracts

The pipeline uses two primary datasets: `events` and `user_profiles`.

### events schema

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| event_id | UUID | yes | globally unique, immutable |
| user_id | UUID | yes | foreign key to user_profiles |
| event_type | enum(click, view, purchase, impression) | yes | must be in allowlist |
| timestamp | ISO-8601 UTC | yes | monotonically increasing per user |
| payload | JSON object | no | max 4KB; schema validated |

### user_profiles schema

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| user_id | UUID | yes | primary key |
| segment | enum(free, pro, enterprise) | yes | determines feature gates |
| created_at | ISO-8601 UTC | yes | immutable after write |

## Conventions

To add a new field to an existing schema:
1. Add the field definition to this doc under the relevant schema table.
2. Add a migration in `migrations/` using the naming pattern `YYYYMMDD_add_<field>.sql`.
3. Update the Pydantic model in `src/models/<schema_name>.py`.
4. Re-run `make validate-schemas` to confirm all downstream consumers pass.

## Invariants

- `event_id` and `user_id` fields are write-once and must never be mutated after creation.
- Enum fields must have their allowlist updated before a new value is used in production.
- Schema changes are additive-only (no field removal without a deprecation period).
