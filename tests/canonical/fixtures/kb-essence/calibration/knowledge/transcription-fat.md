---
kb-category: primary
source: hand-authored
objective: CAL-1 transcription fixture -- near-verbatim restatement of payment-engine.ts.
summary: Payment engine module documentation. High lexical overlap with source; no synthesis.
sources:
  - tests/canonical/fixtures/kb-essence/calibration/src/payment-engine.ts
tags: [test-fixture, cal-transcription]
---

# Payment Engine Module

The payment-engine.ts file contains the core payment processing implementation.
The PaymentEngine class orchestrates all payment lifecycle transitions in this
project. PaymentEngine coordinates FeeSchedule application, ReconciliationCycle
execution, and SettlementBatch dispatch for every transaction processed.

## PaymentEngine

The PaymentEngine class is the central coordinator for payment processing.
It applies the FeeSchedule to each transaction, runs the ReconciliationCycle
to reconcile ledger entries, and submits a SettlementBatch to the clearing house.
Every payment MUST transit through the PaymentEngine to ensure auditability.

Constructor parameters:
- feeSchedule: FeeSchedule
- reconciliationCycle: ReconciliationCycle
- settlementBatch: SettlementBatch

The processPayment method processes a payment through the PaymentEngine.
It applies FeeSchedule, runs ReconciliationCycle, then queues a SettlementBatch
entry. The flushSettlementBatch method flushes the current SettlementBatch to
the clearing house.

## FeeSchedule

The FeeSchedule class holds the tiered fee rules applied by the PaymentEngine.
Each tier specifies a percentage applied to the transaction amount.
The PaymentEngine queries the FeeSchedule once per transaction.

The compute method returns the fee amount for the given transaction and amount.
If amount is greater than 10000, the fee is amount multiplied by 0.01.
If amount is greater than 1000, the fee is amount multiplied by 0.015.
Otherwise the fee is amount multiplied by 0.02.

## ReconciliationCycle

The ReconciliationCycle class accumulates ledger entries from the PaymentEngine
and reconciles them against the authoritative ledger at the end of each cycle.
A ReconciliationCycle failure blocks the next SettlementBatch submission.

The record method accumulates an entry for reconciliation.
The reconcile method validates all accumulated entries against the ledger.
It returns true if all entries reconcile and false on mismatch.
The reset method clears the ReconciliationCycle state after a successful
SettlementBatch.

## SettlementBatch

The SettlementBatch class collects net payment amounts from the PaymentEngine
and submits them as a single atomic batch to the clearing house.
Batching reduces per-transaction overhead and enables atomic clearing.

The enqueue method adds a net payment to the pending SettlementBatch.
The submit method sends the current SettlementBatch to the clearing house
atomically. If the items list is empty, submit returns immediately.
In production this calls the clearing house API.

## Exports

The module exports: PaymentEngine, FeeSchedule, ReconciliationCycle, SettlementBatch.
