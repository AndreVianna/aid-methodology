# Integration Map

> **Source:** aid-discover (Phase 1) + aid-interview (Phase 2)
> **Status:** {✅ Complete | ⚠️ Partial | ❌ Missing}
> **Last Updated:** {date}

---

## Overview

> Summarize all external systems this application integrates with. This is the blast radius map — everything here is a failure domain.

| Integration | Type | Direction | Criticality | Notes |
|-------------|------|-----------|-------------|-------|
| {name} | {message queue / cache / external API / email / SMS / storage / other} | {inbound / outbound / both} | {Critical / High / Medium / Low} | |

---

## Message Queues & Event Buses

### {Queue / Topic Name}

| Property | Value |
|----------|-------|
| **Technology** | {RabbitMQ / Kafka / SQS / Azure Service Bus / Redis Streams / other} |
| **Type** | {Queue (point-to-point) / Topic (pub-sub) / Exchange} |
| **Producer(s)** | {which services/modules publish to this} |
| **Consumer(s)** | {which services/modules consume from this} |
| **Message format** | {JSON / Avro / Protobuf — schema location if documented} |
| **Dead letter queue** | {Yes: {dlq-name} / No} |
| **Retry policy** | {n retries, backoff} |
| **Connection config** | {env var or config key} |

**Message schema:**
```json
{
  "eventType": "{event-name}",
  "payload": {
    "{field}": "{type/description}"
  }
}
```

---

## Caches

### {Cache Name}

| Property | Value |
|----------|-------|
| **Technology** | {Redis / Memcached / in-memory / distributed / other} |
| **Purpose** | {what is cached and why} |
| **Eviction policy** | {TTL, LRU, explicit invalidation} |
| **TTL** | {default TTL for main cached items} |
| **Connection config** | {env var or config key} |
| **Cache key pattern** | {e.g., `{prefix}:{entity}:{id}`} |

---

## File / Object Storage

### {Storage Name}

| Property | Value |
|----------|-------|
| **Technology** | {S3 / Azure Blob / GCS / local filesystem / NFS / other} |
| **Purpose** | {what is stored} |
| **Access pattern** | {read-heavy / write-heavy / archival} |
| **Bucket / Container** | {name or naming convention} |
| **Auth** | {IAM role / access key / service principal / other} |
| **Config location** | {env var or config key} |

---

## Email & Notifications

| Property | Value |
|----------|-------|
| **Provider** | {SendGrid / Mailgun / SES / SMTP / other} |
| **Used for** | {transactional / marketing / system alerts / all} |
| **Trigger events** | {list what sends email} |
| **Template management** | {code / provider dashboard / none} |
| **Config location** | {env var name} |

---

## Third-Party Services

> Everything else — payments, analytics, monitoring, auth providers, etc.

| Service | Provider | Purpose | SDK/Client | Config |
|---------|----------|---------|------------|--------|
| {Payments} | {Stripe / PayPal / other} | {process charges} | {package version} | {env var} |
| {Auth} | {Auth0 / Cognito / Okta / other} | {user authentication} | {package version} | {env var} |
| {Monitoring} | {Datadog / New Relic / other} | {APM, error tracking} | {package version} | {env var} |
| {Analytics} | {Segment / Mixpanel / other} | {user behavior} | {package version} | {env var} |

---

## Integration Health Risks

> Which integrations are most likely to cause production incidents?

| Integration | Risk | Mitigation |
|-------------|------|-----------|
| {name} | {e.g., No circuit breaker — single API timeout cascades} | {recommendation} |
| {name} | {e.g., Hard dependency on startup — if unavailable, service won't start} | {recommendation} |
| {name} | {e.g., API key stored in code, not env var} | {Move to secrets management} |

---

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial integration surface mapping |
