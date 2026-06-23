---
kb-category: primary
source: hand-authored
objective: CAL-3 coverage-gap fixture -- salient term from sources is absent from body.
summary: Payment engine architecture overview. One load-bearing term from the source is absent.
sources:
  - tests/canonical/fixtures/kb-essence/calibration/src/payment-engine.ts
tags: [test-fixture, cal-coverage]
---

# Payment Engine Architecture

The PaymentEngine is the central coordinator for all payment processing in this
project. It applies a FeeSchedule to each incoming transaction to compute the net
amount, then submits the net amount in a SettlementBatch to the clearing house.

## PaymentEngine

The PaymentEngine holds references to a FeeSchedule and a SettlementBatch.
Each call to processPayment computes the fee via FeeSchedule, derives the net
amount, and enqueues it into the pending SettlementBatch. When a batch window
closes, flushSettlementBatch submits the batch atomically to the clearing house.

## FeeSchedule

The FeeSchedule encodes tiered fee rules. For large transactions (over 10000)
the rate is 1 percent. For mid-range transactions (over 1000) the rate is 1.5
percent. For standard transactions the rate is 2 percent. The PaymentEngine
queries FeeSchedule.compute once per transaction.

## SettlementBatch

The SettlementBatch accumulates net payment amounts and submits them as a single
atomic unit to the clearing house. Batching reduces per-transaction overhead and
ensures atomicity at the clearing house boundary.

## Design Rationale

The PaymentEngine decouples fee logic (FeeSchedule) from clearing logic
(SettlementBatch). Each concern is independently testable and the PaymentEngine
coordinates them without either knowing about the other.
