---
kb-category: primary
source: hand-authored
objective: CONTROL -- well-calibrated summary doc covering all salient terms; low overlap.
summary: Why the PaymentEngine decouples fee, reconciliation, and settlement concerns.
sources:
  - tests/canonical/fixtures/kb-essence/calibration/src/payment-engine.ts
tags: [test-fixture, cal-control]
---

# Payment Engine Design

The PaymentEngine exists to enforce a single, auditable path for every payment
transaction. Its design separates three concerns that must evolve independently:
fee policy (FeeSchedule), ledger accuracy (ReconciliationCycle), and clearing
atomicity (SettlementBatch). Coupling any two would make fee-rule changes risk
reconciliation correctness, or reconciliation failures risk partial settlement.

## Why three collaborators

The FeeSchedule isolates fee-tier logic from processing mechanics. When
regulatory requirements change a tier, only FeeSchedule changes -- the
PaymentEngine and SettlementBatch are unaffected. Similarly, ReconciliationCycle
owns the invariant that ledger entries match submitted amounts before any
SettlementBatch is accepted; a ReconciliationCycle failure is the controlled
circuit-breaker that prevents an out-of-balance batch from reaching the clearing
house.

## Lifecycle

A payment enters PaymentEngine.processPayment, is costed by FeeSchedule, the
net amount is registered in ReconciliationCycle, and then enqueued in
SettlementBatch. When a batch window closes, flushSettlementBatch submits
atomically. ReconciliationCycle.reset clears state after a confirmed flush so
the next cycle starts clean.

## The audit-record contract

Every payment that transits the PaymentEngine generates an audit-record contract:
an immutable entry that links the transaction identifier, the applied fee, and the
net amount submitted to the SettlementBatch. The audit-record contract is the
foundation of the auditability guarantee -- it is what allows reconciliation
failures to be traced to a specific payment without re-processing.

## What to look up in the source

Implementation details -- exact fee tiers, clearing-house API, ledger comparison
logic -- live in `src/payment-engine.ts`. This document explains the why and the
interaction model; the source is the authority for the how.
