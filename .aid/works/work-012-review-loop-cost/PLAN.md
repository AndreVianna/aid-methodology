# Plan -- Scoped Review Cycles and Criterion Oracles

## Deliverables

### delivery-001: The review loop, measured then scoped

- **What it delivers:** a review cycle that stops re-reading what it has already read, and
  a criterion that can be decided by running a check instead of re-judging it — with the
  saving measured on this work's own review cycles rather than asserted.
- **Features:** feature-001-cost-measurement, feature-002-criterion-oracles,
  feature-003-scoped-review-cycles
- **Depends on:** --
- **Priority:** Must

**Why one delivery and not two.** C-7 permits up to two. One is used because the owner asked
for one and nothing in the work requires a second — **not** because one is better for AC-1.

*An earlier draft of this section claimed one delivery gives AC-1 a larger "after" sample.
That claim was wrong and the plan gate caught it. It is recorded rather than deleted,
because the mistake is instructive: it inferred a measurement consequence from a packaging
decision that has none.* Under the natural two-delivery split — `{feature-001, feature-002}`
then `{feature-003}` — FR-3's task is still the **first task of feature-003**, because §10
fixes the feature order and a delivery boundary does not move a task within that order. The
"after" sample is therefore **identical** either way. If anything, two deliveries would have
added delivery-001's own gate cycles to the *before* side, which is the side already well
sampled.

So AC-1 is close to neutral on delivery count, and the honest reasons for one are:

- AC-1's subject (Q-03) is **per-task** review cycles, not gates, so the primary metric does
  not depend on a second delivery existing.
- Nothing in the work is independently shippable in a way that earns its own gate: the meter
  without the remedies measures nothing, and the remedies without the meter prove nothing.
- One less gate is one less gate, and this is a work about review cost.

**What one delivery gives up, stated rather than glossed:**

1. The secondary delivery-gate reading named in Q-03. AC-1's primary metric is unaffected;
   there is one fewer corroborating figure.
2. Partial shipping. With two, the meter and the oracles could ship even if the scoping work
   stalled. With one, a stall on FR-3 blocks everything. **This is the real cost of the
   choice** — and with the AC-1 argument withdrawn, it is the *only* material one.

### Internal sequence (the ordering that matters more than the delivery count)

With one delivery, correctness rests on task order rather than delivery boundaries. Three
constraints bind, all inherited rather than invented here:

| # | Constraint | Source |
|---|---|---|
| 1 | The meter and its baseline land **first**. Once a remedy is in the tree the "before" figure is unrecoverable. | §10 step 1; feature-001 AC |
| 2 | The oracle work (FR-8..FR-13) lands **before** the scoping work. Remedy 2 removes remedy 1's correctness objection rather than guarding around it. | §10 step 2; L5 |
| 3 | FR-3's task lands **as early as 1 and 2 allow**, and no later. Every task reviewed after it is an AC-1 "after" sample. | Q-03; AC-1 |

Everything else — the remaining guards, FR-14's slice, and the close-out — follows FR-3, and
that is a feature of the ordering rather than a leftover: those tasks *are* the "after"
sample.

`/aid-detail` owns the task breakdown. What it may not do is reorder around constraint 3:
moving FR-3's task later is not a scheduling preference, it is a reduction in the evidence
AC-1 rests on.

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | **The "after" sample is too small to show anything.** FR-3 cannot land first — it waits on the meter and the oracles — so only the tasks after it are measurable, and there may be few. | H | Constraint 3 above puts FR-3 at the earliest permitted point. If the sample is still thin at close, report it as a thin sample with its row count rather than as a result: feature-001's `report` prints the count behind every figure precisely so a weak sample cannot masquerade as a strong one. |
| 2 | **All-or-nothing shipping.** One delivery means a stall on the scoping work blocks the meter and the oracles too, though both are independently useful. | M | Accepted, as the stated cost of the one-delivery choice. If a stall does occur, the delivery can be split at that point — the feature boundaries are already drawn, so the split is cheap and C-7's cap leaves room for exactly one more. |
| 3 | **The `.aid/knowledge/` edits need owner authorization.** Two features depend on them. | L | Discharged before Plan: C-5 was authorized on 2026-08-15, enumerated to three specific edits. Anything beyond those still needs a fresh ask. |
| 4 | **The single render is easy to get wrong.** `canonical/` edits in features 002 and 003 must be rendered with the **full** generator; a per-script renderer leaves stale emission manifests and fails the render-drift gate. | M | feature-003's close-out step 1 names the full generator explicitly, and NFR-5 fixes the render at exactly one, at the end. |

## Deferred

*(None. All three features are in delivery-001.)*
