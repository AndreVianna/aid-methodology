> **SAMPLE OUTPUT** — This file illustrates what selected KB documents look like after
> running `/aid-discover` on the OrderFlow codebase. It is an excerpt, not a complete
> file. Actual AID output is tailored to each codebase and will differ in content and
> length. The structure and frontmatter conventions shown here are accurate to the
> current AID methodology.

---

# Sample KB Excerpt: domain-glossary.md (partial)

```markdown
---
kb-category: primary
source: aid-discover
intent: |
  Authoritative glossary of OrderFlow domain terms extracted from the codebase.
  Read before writing any code that touches order state, payment state, or
  inventory allocation. Order-state machine transitions are the most critical
  section — misunderstanding them is the primary source of historical bugs.
changelog:
  - 2026-06-03: Initial discovery (aid-discover work-003 cycle)
---

# Domain Glossary

## Order States

The order-state machine governs the lifecycle of every order. Transitions are
enforced in `orders/OrderService.js` (method `transitionTo`). Illegal transitions
throw `InvalidStateTransitionError`.

| State | Meaning | Legal next states |
|-------|---------|------------------|
| `DRAFT` | Order created, not yet submitted | `CONFIRMED`, `CANCELLED` |
| `CONFIRMED` | Payment captured, inventory allocated | `FULFILLED`, `CANCELLED` |
| `FULFILLED` | All items shipped | `CANCELLED` (within 24h window only) |
| `CANCELLED` | Order voided | (terminal) |

**Critical:** `CANCELLED` from `FULFILLED` is only legal within 24 hours of
fulfilment (`fulfilled_at` column). The time check is in `OrderService.canCancel()`.
Any refund feature must respect this boundary.

## Payment States

Distinct from order states. Managed in `payments/PaymentService.js`.

| State | Meaning |
|-------|---------|
| `AUTHORIZED` | Card authorized, not yet captured |
| `CAPTURED` | Payment captured (triggers CONFIRMED) |
| `FAILED` | Capture or authorization failed |
| `REFUNDED` | Full or partial refund processed (planned — not yet implemented) |

## Key Terms

**Idempotency Key** — A caller-supplied UUID stored on payment and refund records.
Re-submitting a request with the same key returns the original result without
re-processing. Pattern used in `PaymentService.createCharge()`. Must be adopted for
any new payment-related operations.

**Inventory Allocation** — Reserving stock at order confirmation. Managed by
`inventory/AllocationService.js`. Allocation is released on cancellation.

**Notification Fan-out** — When order state changes, `notifications/NotificationService.js`
fans out to registered webhooks. Retry logic: 3 attempts with exponential backoff.
Failure after 3 attempts writes to `notification_failures` table (dead-letter pattern).
```

---

# Sample KB Excerpt: tech-debt.md (partial)

```markdown
---
kb-category: primary
source: aid-discover
intent: |
  Known technical debt in OrderFlow discovered during the 2026-06-03 Discovery cycle.
  Read before planning any refactor work or estimating effort for new features —
  some items create hidden coupling that affects scope.
changelog:
  - 2026-06-03: Initial discovery (aid-discover work-003 cycle)
---

# Technical Debt

## TD-001 — Schema Drift: three columns present in DB but absent from Sequelize models

**Severity:** HIGH
**Evidence:** `orders` table has columns `promo_code`, `affiliate_id`, `risk_score`
present in PostgreSQL (verified via `\d orders` in `tests/fixtures/schema.sql`) but
absent from `models/Order.js`. These columns are populated by a legacy import script
(`scripts/legacy-import.js`) and read by the reports module via raw SQL. Any ORM-level
query that includes `SELECT *` will silently drop these columns.

**Impact:** Risk of data loss if ORM is used for update operations on orders with
promo or affiliate data. The refund feature must not use ORM-level `order.save()` on
existing orders without first resolving or working around this drift.

**Suggested resolution:** Add a Sequelize migration pass to declare these columns in
the model. Until resolved, use raw SQL for order updates in affected paths.

## TD-002 — Missing migration tooling

**Severity:** MEDIUM
**Evidence:** No migration runner (`sequelize-cli`, `knex`, `flyway`, or equivalent)
is present in `package.json`. Schema changes to date have been applied manually via
psql. There is a `scripts/migrate.sh` stub that is empty.

**Impact:** Any new feature that adds a table (e.g., Refund workflow) has no standard
path to deploy schema changes. The team must establish a migration runner before or
alongside the next schema-changing feature.

**Suggested resolution:** Add `sequelize-cli` and a `migrations/` directory convention.
Ship migration files alongside feature code. This is a prerequisite for the Refund
feature delivery-001.

## TD-003 — Deprecated Stripe SDK method in PaymentService

**Severity:** LOW
**Evidence:** `payments/PaymentService.js` line 87 calls `stripe.charges.create()`,
which Stripe deprecated in favor of `stripe.paymentIntents.create()` as of Stripe
API version 2019-02-11. The current Stripe API key in `.env.example` pins
`STRIPE_API_VERSION=2018-09-24` to avoid breaking changes.

**Impact:** Refunds initiated via `stripe.charges.create()` charges work but block
adoption of newer Stripe features (e.g., automatic payment methods). The refund
feature should be built on top of the current charge ID (compatible), but migrating
to PaymentIntents is a separate tech-debt work item.
```
