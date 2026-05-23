# API Contracts

> **Source:** aid-discover (Phase 1) + aid-interview (Phase 2)
> **Status:** {✅ Complete | ⚠️ Partial | ❌ Missing}
> **Last Updated:** {date}

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

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial API surface mapping |
