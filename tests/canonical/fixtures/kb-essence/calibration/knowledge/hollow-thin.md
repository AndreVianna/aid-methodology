---
kb-category: primary
source: hand-authored
objective: CAL-2 hollowness fixture -- dominated by see-src pointers, minimal synthesis.
summary: Payment engine overview. All detail deferred to source files.
sources: []
tags: [test-fixture, cal-hollow]
---

# Payment Engine Overview

For the core implementation, see `src/payment-engine.ts`.

For fee computation logic, see `src/payment-engine.ts` (FeeSchedule class).

For reconciliation logic, see `src/payment-engine.ts` (ReconciliationCycle class).

For settlement batching, see `src/payment-engine.ts` (SettlementBatch class).

For constructor parameters, see `src/payment-engine.ts` (PaymentEngine constructor).

For the processPayment method, see `src/payment-engine.ts`.

For the flushSettlementBatch method, see `src/payment-engine.ts`.

For exports, see `src/payment-engine.ts` (export statement).

For integration with clearing house, see `src/payment-engine.ts` (submit method).

For ledger reconciliation details, see `src/payment-engine.ts` (reconcile method).
