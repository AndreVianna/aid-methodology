---
spine-dimension: C5
owner: aid-researcher-analyst
---
# Content Model

## Contracts

The CMS manages two primary content types: `Article` and `Tutorial`.

### Article schema

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| title | string | yes | max 200 chars; non-empty |
| slug | string | yes | pattern `^[a-z0-9]+(?:-[a-z0-9]+)*$`; unique across Articles |
| body | markdown | yes | max 50000 chars |
| publishedAt | ISO-8601 UTC | yes | must be present in published state |
| summary | string | no | max 300 chars |
| tags | string[] | no | max 10 tags; each tag max 50 chars |
| author | string | no | must match a known author slug |

### Tutorial schema

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| title | string | yes | max 200 chars; non-empty |
| slug | string | yes | pattern `^[a-z0-9]+(?:-[a-z0-9]+)*$`; unique across Tutorials |
| steps | object[] | yes | min 1 step; each step has `title` + `body` |
| difficulty | enum(easy, medium, hard) | yes | |
| prerequisites | string[] | no | slugs of prerequisite Tutorials |
| tags | string[] | no | max 10 tags |

## Conventions

To add a new content type:
1. Add the schema definition to `content-types.json` with `requiredFields`, `optionalFields`, and `slugPattern`.
2. Document the new type in this file with a field table and constraints.
3. Add a validation rule to `src/validators/<ContentType>.ts`.
4. Register the new type in `src/content-registry.ts`.

## Invariants

- Slugs are immutable after first publication.
- Publishing states are: draft, published, archived.
- Content type names are PascalCase; slug patterns are enforced at write time.
