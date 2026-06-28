---
kb-category: primary
source: hand-authored
objective: Public API surfaces, schemas, request/response shapes, and protocol contracts for {project}.
summary: Read this when implementing or modifying any externally-visible interface or pipeline boundary.
sources:
  - src/                        # API and contract implementation code
  - {path/to/api/specs}         # e.g., openapi.yaml, proto files, schema definitions
tags: [C2, api, contracts, schemas, protocols]
see_also: [architecture.md, integration-map.md, schemas.md]
owner: architect
audience: [developer, architect]
intent: |
  Public API surfaces, frontmatter schemas, request/response shapes, and protocol contracts. Read this when implementing or modifying any externally-visible interface.
contracts: []
changelog:
  - 2026-06-23: Added f001 frontmatter fields (objective/summary/sources/tags/see_also/owner/audience)
  - 2026-05-26: KB Authoring v2 template seed
---

# API Contracts

> **Source:** aid-discover (Phase 1) + aid-describe (Phase 2)
> **Status:** {✅ Complete | ⚠️ Partial | ❌ Missing}
> **Last Updated:** {date}

## Contents

- [APIs Exposed (This System)](#apis-exposed-this-system)
- [APIs Consumed (External Dependencies)](#apis-consumed-external-dependencies)
- [Internal APIs (Service-to-Service)](#internal-apis-service-to-service)
- [API Versioning Strategy](#api-versioning-strategy)
- [Known Issues](#known-issues)
- [Conventions](#conventions)
- [Contracts](#contracts)
- [Change Log](#change-log)

---

## APIs Exposed (This System)

> APIs this system provides to consumers.

### {API Name}

| Property | Value |
|----------|-------|
| **Type** | {REST / GraphQL / gRPC / WebSocket / SOAP} |
| **Base URL** | {production base URL or pattern} |
| **Authentication** | {Bearer JWT / API Key / OAuth2 / Basic / none} |
| **Versioning** | {URL path (/v1/) / Header / Query param / none} |
| **Documentation** | {Swagger UI path / link to docs / none} |

**Key Endpoints:**

| Method | Path | Purpose | Auth Required |
|--------|------|---------|---------------|
| `GET` | `/api/v1/{resource}` | {description} | {Yes / No} |
| `POST` | `/api/v1/{resource}` | {description} | {Yes / No} |
| `PUT` | `/api/v1/{resource}/{id}` | {description} | {Yes / No} |
| `DELETE` | `/api/v1/{resource}/{id}` | {description} | {Yes / No} |

**Request/Response example:**
```json
// POST /api/v1/{resource}
// Request:
{
  "{field}": "{type/example}"
}

// Response 200:
{
  "id": "{uuid}",
  "{field}": "{value}"
}

// Error Response 400:
{
  "type": "https://tools.ietf.org/html/rfc7807",
  "title": "Bad Request",
  "errors": { "{field}": ["{message}"] }
}
```

---

## APIs Consumed (External Dependencies)

> External APIs this system calls. Critical for understanding failure modes.

| API | Provider | Purpose | Auth | Rate Limit | Notes |
|-----|----------|---------|------|-----------|-------|
| {API name} | {Provider} | {what we use it for} | {API key / OAuth} | {requests/min} | {any gotchas} |

### {External API Name} — Details

| Property | Value |
|----------|-------|
| **Base URL** | {URL} |
| **SDK / Client** | {package name and version, or "raw HTTP"} |
| **Auth location** | {env var name or config key} |
| **Timeout** | {configured timeout} |
| **Retry policy** | {retries on 429/5xx? exponential backoff?} |
| **Failure behavior** | {throws / returns null / circuit breaker} |

**Endpoints used:**
| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `{path}` | {what we do with it} |

---

## Internal APIs (Service-to-Service)

> For microservice architectures — HTTP or gRPC calls between internal services.

| Caller | Callee | Method | Endpoint | Purpose |
|--------|--------|--------|----------|---------|
| {ServiceA} | {ServiceB} | `GET` | `{path}` | {purpose} |

---

## API Versioning Strategy

{Describe how API versions are managed — breaking changes, deprecation timeline, backward compatibility policy}

---

## Known Issues

- {e.g., "External payment API rate limit is 100 req/min. Current traffic peaks at 80 req/min — limited headroom."}
- {e.g., "OpenAPI spec is manually maintained and often lags the actual implementation."}
- {e.g., "/api/v2 was started but never completed — endpoints are mixed between v1 and v2."}

---

## Conventions

> The project's **own way** of adding/versioning an API or pipeline boundary -- routing,
> naming, versioning, error-shape. Without this an agent invents an endpoint convention
> wrong for this project. State the rule, then point at the canonical example endpoint.

- **How a new endpoint is added:** {e.g. "controllers under `Api/Controllers/`, one per
  aggregate; route `/api/v{n}/{resource}`"}.
- **Versioning rule:** {e.g. "breaking changes go to a new `/vN` prefix; never break an
  existing version in place"}.
- **Error shape:** {e.g. "all 4xx/5xx responses return RFC 7807 ProblemDetails"}.

---

## Contracts

> The structural shape a change MUST satisfy at a pipeline/API boundary -- the
> request/response schema, the interface, the protocol contract. Without this an agent's
> change breaks integration. State the contract precisely (fields, types, required-ness) and
> name every downstream consumer the contract binds.

- **{Contract name / boundary}:** {the exact shape -- fields, types, which are required, what
  validation applies; and the consumers bound to it (who breaks if it changes)}.
- **Compatibility rule:** {e.g. "additive-only within a version: new fields optional;
  removing or retyping a field is a breaking change requiring a new version"}.

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial API surface mapping |
