> **SAMPLE OUTPUT** — This file illustrates what a delivery plan looks like after
> running `/aid-plan` for the Refund Workflow work item. It is an excerpt of
> `.aid/work-003/PLAN.md`. Actual AID output is tailored to each project's features
> and dependencies. The structure and conventions shown here are accurate to the
> current AID methodology.

---

# Sample Delivery Plan Excerpt: PLAN.md (work-003)

````markdown
---
work: work-003
title: Refund Workflow
status: Planned
planned-by: aid-plan
features:
  - refund-workflow
changelog:
  - 2026-06-03: Initial plan produced by aid-plan
---

# Plan: work-003 — Refund Workflow

## Summary

One feature (refund-workflow) split into two deliveries. Delivery-001 is a
prerequisite for delivery-002: the Sequelize model and migration must be merged
before the service layer and REST layer can be implemented and tested end-to-end.

## Deliveries

### delivery-001 — Schema + Model Foundation

**Goal:** Merge a standalone PR that adds the `refunds` table migration, the
Sequelize `Refund` model, and model-level unit tests. No business logic.
No Stripe calls. Independently reviewable and mergeable.

**Prerequisite:** TD-002 (missing migration tooling) must be resolved before this
delivery can be deployed. Recommended: add `sequelize-cli` as a dev dependency and
establish the `migrations/` directory convention as the first commit in this
delivery's branch.

**Tasks:**

| Task | Type | Description | Depends on |
|------|------|-------------|-----------|
| task-001 | MIGRATE | Create `refunds` table migration (`migrations/0001_create_refunds.sql`); configure `sequelize-cli` | — |
| task-002 | IMPLEMENT | Add `models/Refund.js`: Sequelize model, `RefundStatus` enum, `belongsTo Order` association | task-001 |
| task-003 | TEST | Unit tests for `Refund` model: associations, validations, enum values | task-002 |

**Done when:** All three tasks pass reviewer grade ≥ A. PR is green on CI.

---

### delivery-002 — State Machine, Stripe Integration, and REST Layer

**Goal:** Implement the complete Refund workflow: state machine, Stripe integration,
webhook emission, REST controllers, and full integration test coverage.

**Depends on:** delivery-001 merged.

**Tasks:**

| Task | Type | Description | Depends on |
|------|------|-------------|-----------|
| task-004 | IMPLEMENT | `payments/RefundService.js`: create refund, validate order state, idempotency check, state machine transitions | delivery-001 done |
| task-005 | IMPLEMENT | Stripe integration in `RefundService.js`: call `stripe.refunds.create()`, handle errors, update status | task-004 |
| task-006 | IMPLEMENT | Webhook emission: call `NotificationService.emit('refund.updated', ...)` on SUCCEEDED/FAILED | task-005 |
| task-007 | IMPLEMENT | REST controllers: `POST /orders/:id/refunds`, `GET /orders/:id/refunds`, `GET /refunds/:id` | task-004 |
| task-008 | TEST | Integration tests: full refund lifecycle, idempotency, invalid-state rejection | task-006, task-007 |
| task-009 | TEST | Webhook delivery tests: mock Stripe, verify `NotificationService.emit` called with correct payload | task-006 |
| task-010 | DOCUMENT | Update API reference: document three new endpoints with request/response shapes | task-007 |

**Done when:** All seven tasks pass reviewer grade ≥ A. PR is green on CI.
Integration tests cover the acceptance criteria from `SPEC.md`.

---

## Execution Graph (visual)

```
delivery-001:
  task-001 → task-002 → task-003

delivery-002 (after delivery-001 merged):
  task-004 ─┬─ task-005 → task-006 ─┐
             │                       ├─ task-008
             └─ task-007 ────────────┘
                              task-009 (parallel with task-008)
             task-010 (after task-007)
```

## Risk Notes

- **TD-002 is a blocker for delivery-001.** If adding `sequelize-cli` is
  contentious, create a separate preparatory PR (pre-001) to resolve it first.
- **Stripe test mode:** task-005 and task-009 must use the Stripe test API key.
  Verify `STRIPE_API_KEY` in the CI environment before delivery-002 starts.
- **Amount cap across refunds:** `RefundService.create()` must query existing
  refund totals atomically to prevent race conditions on concurrent refund
  requests for the same order. Use a DB-level check constraint as the safety net.
````
