# Delivery BLUEPRINT -- delivery-028: Observation reports and the judgment boundary

> **Delivery:** delivery-028
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-08-11

---

## Objective

Put the boundary between mechanical checking and judgment where it belongs, and make it visible in the
scripts' own output. A script measures shape -- is a modality token present, does a citation resolve,
is a gap still open. Whether the thing it measured *matters* is a judgment, and this delivery stops the
scripts from being read as having made it. Carries group I (`FR-I1`--`FR-I6`).

## Scope

- Each mechanical check in the review path emits an **observation report**: no verdict vocabulary for
  anything a reviewer is meant to price, and an explicit statement of **what it did not examine**
  (`FR-I1`).
- The reports are produced **before** the reviewer is dispatched and passed to it as input, so one
  mechanical pass precedes one judgment pass (`FR-I2`).
- The reports stay **outside the ledger** (`FR-I3`). A ledger row is always something an agent decided
  to raise; a script observation the agent dismisses leaves no trace in the ledger.
- The reviewer is instructed that a report is **evidence, not truth**, and says so when it leans on a
  reported fact it cannot reproduce (`FR-I4`).
- Gate surface narrows to **one** mechanical blocker -- an open criteria gap -- plus citation
  *resolution*. Modality and citation *style* become advisory (`FR-I5`).

Carries `FR-I1`--`FR-I5`. Feature owner `feature-002`.

**Out of scope:** the renames in `FR-I6`. They are a `SHOULD` over shipped script names with live
callers, so they are a migration in their own right and must not ride on a behavioural change -- a
rename landing in the same commit as a semantic change makes both unbisectable.

**Also out of scope:** the modality check's *relocation* to `/aid-describe`. `FR-B5a` places it there;
this delivery only removes its power to block, which is the part group I owns.

## Gate Criteria

- [ ] Every mechanical check in the review path emits a report that states what it did **not** examine
- [ ] No report uses verdict vocabulary for a finding the reviewer is meant to price -- checked by
      reading the reports the checks actually emit, not by grepping the scripts for words
- [ ] The reviewer's brief carries the reports as input, and the dispatch happens **after** they exist
- [ ] No observation report contributes a ledger row on its own; every row in a graded ledger is
      traceable to a reviewing agent's decision
- [ ] Exactly two mechanical conditions can block a grade: an open criteria gap, and a citation that
      does not resolve. Demonstrated by a modality-failing artifact reaching a grade
- [ ] `grade.sh` computes the same letter it computes today for every existing ledger -- this delivery
      changes what reaches the ledger, not how a ledger is scored

## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. Written by `aid-detail`; empty until it runs._

| Task | Type | Wave | Title |
|------|------|------|-------|
| _none yet_ | | | |

## Dependencies

- **Depends on:** delivery-004
- **Blocks:** -- (none)

## Notes

**Why this exists as a delivery at all.** It is the boundary the rest of this work kept crossing by
accident. `FR-B5b` gave a lookup table authority over severity while nothing enforced it; the modality
check gated a grade on a shape whose stated purpose was feeding that lookup. Both are the same error
made twice -- a script measuring shape being handed authority over substance -- so the correction is
one delivery rather than two patches.

**Why it depends on delivery-004 and nothing else.** The catalog is where a rule row stops carrying a
severity anchor. Until that lands, "the reviewer assigns severity" and "the rule says the severity"
are both true on disk, and a report written against either reading is written against a moving target.
