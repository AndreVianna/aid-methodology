> **SAMPLE OUTPUT** — This file illustrates what a feature SPEC looks like after
> running `/aid-specify` on the Refund Workflow feature stub. It is a partial excerpt
> of `.aid/works/work-003/features/refund-workflow/SPEC.md`. Actual AID output is tailored
> to each codebase. The structure, frontmatter, and cross-references to KB documents
> shown here are accurate to the current AID methodology.

---

# Sample Feature SPEC Excerpt: Refund Workflow

````markdown
---
feature: refund-workflow
work: work-003
status: Specified
specified-by: aid-specify
kb-refs:
  - architecture.md
  - domain-glossary.md
  - module-map.md
  - schemas.md
  - pipeline-contracts.md
  - coding-standards.md
  - tech-debt.md
changelog:
  - 2026-06-03: Stub created by aid-describe
  - 2026-06-03: Technical spec added by aid-specify
---

# Feature SPEC: Refund Workflow

## Business Requirements (from REQUIREMENTS.md)

- BR-1: A refund can only be initiated from FULFILLED or CONFIRMED order state.
- BR-2: Partial refund amount must not exceed the original payment amount.
- BR-3: Refund processing must be idempotent (duplicate webhook delivery safe).
- BR-4: Webhook notification to storefront within 60 seconds of processor ACK.

## Technical Specification

### Data Model

New table: `refunds`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | `UUID` | PK, `DEFAULT gen_random_uuid()` | Matches existing UUID PK pattern (see `schemas.md` §2) |
| `order_id` | `UUID` | FK → `orders(id)`, NOT NULL | An order may have multiple refund records (partial refunds) |
| `idempotency_key` | `VARCHAR(255)` | UNIQUE, NOT NULL | Caller-supplied; see `domain-glossary.md` § "Idempotency Key" |
| `status` | `VARCHAR(32)` | NOT NULL, DEFAULT `'PENDING'` | Enum: `PENDING`, `PROCESSING`, `SUCCEEDED`, `FAILED` |
| `amount` | `INTEGER` | NOT NULL | Cents. Must satisfy: `SUM(refund.amount) ≤ order.total_amount` |
| `stripe_charge_id` | `VARCHAR(255)` | nullable | The Stripe charge ID being refunded (from `payments` table) |
| `created_at` | `TIMESTAMPTZ` | NOT NULL, DEFAULT `NOW()` | |
| `processed_at` | `TIMESTAMPTZ` | nullable | Set when status transitions to `SUCCEEDED` or `FAILED` |

**Migration note:** TD-002 (missing migration tooling) must be resolved in
delivery-001 before this table can be deployed. See `tech-debt.md` § TD-002.

### Refund State Machine

```
PENDING → PROCESSING → SUCCEEDED
                    ↘ FAILED
```

- `PENDING`: Refund record created, not yet submitted to Stripe.
- `PROCESSING`: Stripe API call in-flight. If the process dies here, a
  reconciliation pass (future work) can detect stuck records.
- `SUCCEEDED`: Stripe confirmed the refund; `processed_at` set.
- `FAILED`: Stripe rejected or a network error exceeded retry budget; `processed_at`
  set; error message stored in `failure_reason` (add column).

### API Endpoints

All three endpoints follow the existing error-first middleware pattern
(`coding-standards.md` §3 — `(err, req, res, next)` signature). Responses use the
existing `ApiResponse` envelope (`module-map.md` §shared).

**POST /orders/:id/refunds**
- Body: `{ idempotency_key: string, amount: integer, reason?: string }`
- Validates order state is FULFILLED or CONFIRMED (BR-1)
- Validates `amount ≤ order.total_amount − sum(existing refunds)` (BR-2)
- On duplicate `idempotency_key`: returns the existing refund record (BR-3)
- Response 201: refund object with status `PENDING`

**GET /orders/:id/refunds**
- Returns array of refund objects for the order
- Response 200

**GET /refunds/:id**
- Returns a single refund object
- Response 200 or 404

### Stripe Integration

Calls `stripe.refunds.create()` (not `stripe.charges.create()` — per TD-003,
new payment-related code should not extend the deprecated charge path). Parameters:

```javascript
await stripe.refunds.create({
  charge: refund.stripe_charge_id,
  amount: refund.amount,
  idempotency_key: `rfnd_${refund.idempotency_key}`,
});
```

Idempotency key is prefixed `rfnd_` to namespace from the original charge key.

### Webhook Emission

On `SUCCEEDED` or `FAILED` state transition, call `NotificationService.emit()` with
event type `refund.updated`. This follows the existing notification fan-out pattern
(`domain-glossary.md` § "Notification Fan-out"). Webhook must fire within 60 seconds
of Stripe ACK (BR-4) — use the existing retry logic (3 attempts, exponential backoff).

### Module Placement

| New file | Module | Why |
|----------|--------|-----|
| `payments/RefundService.js` | payments | Owns refund state machine + Stripe integration |
| `orders/refunds.controller.js` | orders | REST endpoints (refunds are order-scoped) |
| `models/Refund.js` | models | Sequelize model |
| `migrations/0001_create_refunds.sql` | migrations | Schema migration |

Naming follows the `*Service.js` / `*Controller.js` suffix pattern
(`coding-standards.md` §1).

## Acceptance Criteria (code level)

- [ ] `refunds` table created via migration; all columns present; FK constraint verified.
- [ ] `Refund` Sequelize model matches table schema; `belongsTo Order` association.
- [ ] `RefundService.create()` rejects invalid order states with `InvalidStateTransitionError`.
- [ ] `RefundService.create()` enforces amount cap across existing refunds.
- [ ] Duplicate `idempotency_key` returns existing record, does not create a new one.
- [ ] Stripe `refunds.create()` called with prefixed idempotency key.
- [ ] `NotificationService.emit('refund.updated', ...)` called on SUCCEEDED and FAILED transitions.
- [ ] All three REST endpoints return the correct HTTP status codes (201, 200, 404).
- [ ] Integration test: full lifecycle (create → PROCESSING → SUCCEEDED → webhook emitted).
- [ ] Integration test: idempotent create (second call returns first record unchanged).
- [ ] Integration test: invalid state (order DRAFT) returns 422.
````
