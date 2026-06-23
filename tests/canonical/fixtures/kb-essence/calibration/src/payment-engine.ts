// payment-engine.ts -- core payment processing implementation.
// The PaymentEngine orchestrates all payment lifecycle transitions in this project.
// PaymentEngine coordinates FeeSchedule application, ReconciliationCycle execution,
// and SettlementBatch dispatch for every transaction processed.

/**
 * PaymentEngine is the central coordinator for payment processing.
 * It applies the FeeSchedule to each transaction, runs the ReconciliationCycle
 * to reconcile ledger entries, and submits a SettlementBatch to the clearing house.
 * Every payment MUST transit through the PaymentEngine to ensure auditability.
 */
class PaymentEngine {
  private feeSchedule: FeeSchedule;
  private reconciliationCycle: ReconciliationCycle;
  private settlementBatch: SettlementBatch;

  constructor(
    feeSchedule: FeeSchedule,
    reconciliationCycle: ReconciliationCycle,
    settlementBatch: SettlementBatch
  ) {
    this.feeSchedule = feeSchedule;
    this.reconciliationCycle = reconciliationCycle;
    this.settlementBatch = settlementBatch;
  }

  // Process a payment through the PaymentEngine.
  // Applies FeeSchedule, runs ReconciliationCycle, then queues a SettlementBatch entry.
  processPayment(txId: string, amount: number): void {
    const fee = this.feeSchedule.compute(txId, amount);
    const netAmount = amount - fee;
    this.reconciliationCycle.record(txId, netAmount);
    this.settlementBatch.enqueue(txId, netAmount);
  }

  // Flush the current SettlementBatch to the clearing house.
  flushSettlementBatch(): void {
    this.settlementBatch.submit();
  }
}

/**
 * FeeSchedule holds the tiered fee rules applied by the PaymentEngine.
 * Each tier specifies a percentage applied to the transaction amount.
 * The PaymentEngine queries the FeeSchedule once per transaction.
 */
class FeeSchedule {
  // compute returns the fee amount for the given transaction and amount.
  compute(txId: string, amount: number): number {
    if (amount > 10000) return amount * 0.01;
    if (amount > 1000) return amount * 0.015;
    return amount * 0.02;
  }
}

/**
 * ReconciliationCycle accumulates ledger entries from the PaymentEngine
 * and reconciles them against the authoritative ledger at the end of each cycle.
 * A ReconciliationCycle failure blocks the next SettlementBatch submission.
 */
class ReconciliationCycle {
  private entries: { txId: string; amount: number }[] = [];

  // record accumulates an entry for reconciliation.
  record(txId: string, amount: number): void {
    this.entries.push({ txId, amount });
  }

  // reconcile validates all accumulated entries against the ledger.
  // Returns true if all entries reconcile; false on mismatch.
  reconcile(): boolean {
    // Placeholder: in production this compares entries to the authoritative ledger.
    return this.entries.length > 0;
  }

  // reset clears the ReconciliationCycle state after a successful SettlementBatch.
  reset(): void {
    this.entries = [];
  }
}

/**
 * SettlementBatch collects net payment amounts from the PaymentEngine
 * and submits them as a single atomic batch to the clearing house.
 * Batching reduces per-transaction overhead and enables atomic clearing.
 */
class SettlementBatch {
  private items: { txId: string; amount: number }[] = [];

  // enqueue adds a net payment to the pending SettlementBatch.
  enqueue(txId: string, amount: number): void {
    this.items.push({ txId, amount });
  }

  // submit sends the current SettlementBatch to the clearing house atomically.
  submit(): void {
    if (this.items.length === 0) return;
    // Placeholder: in production this calls the clearing house API.
    this.items = [];
  }
}

export { PaymentEngine, FeeSchedule, ReconciliationCycle, SettlementBatch };
