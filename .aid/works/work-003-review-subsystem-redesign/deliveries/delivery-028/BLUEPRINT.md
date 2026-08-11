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

- **The shipped reviewer agent's severity instruction.** `delivery-003` closed `Done`/`A+` having
  shipped the two-step lookup into `canonical/agents/aid-reviewer/AGENT.md`, which the Q32 decision
  retires. Four regions carry it: the `## Severity Classification` section's two numbered steps and its
  *"name the dependent"* line, the *"Look severity up... you do not assign it"* bullet, the *"Severity
  is looked up, not judged"* bullet with its two-reviewers-must-agree clause, and the
  cross-reference-reconciliation bullet's *"whose severity is looked up like any other"*. They are
  replaced by `FR-B5c`: the agent assigns severity, states one line of consequence, and judges the five
  dimensions. `delivery-003` is closed, so this is the delivery that carries it.
- **Eight copies, one source.** The agent body renders to five profile trees plus this repository's own
  `.claude/` and `.cursor/` installs. Only `canonical/` is edited; the rest are re-rendered, and the
  byte-identity gate is the oracle.

Carries `FR-I1`--`FR-I5`, `FR-I7`, and the `FR-B5c` correction to the shipped agent body. Feature owner
`feature-002`; the agent-body regions are `feature-001`'s by the ownership rule, so that inventory must
list them.

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
- [ ] **No copy of the reviewer agent instructs a severity lookup.** A sweep of `canonical/` and all
      seven rendered trees for *"look severity up"*, *"looked up"*, *"two steps"* and *"blast radius"*
      in the agent body returns nothing, and each copy instead carries the one-line-consequence duty
- [ ] A new-cycle reviewer cannot reach a prior cycle's ledger. Demonstrated by **giving one a scratch
      path and checking it cannot produce the previous cycle's findings** -- not by reading the
      instruction that says it must not, which is what failed on 2026-08-11 (`STATE.md` Q34)

## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. Written by `aid-detail`; empty until it runs._

| Task | Type | Wave | Title |
|------|------|------|-------|
| _none yet_ | | | |

## Dependencies

- **Depends on:** delivery-004
- **Blocks:** -- (none)

## The shipped surface, measured rather than estimated

Found on 2026-08-11 while amending features 001 and 002. **The retired lookup is not only in this
work's planning documents — it is on disk in `canonical/`, shipped, and rendered into seven trees.**
Counts are `grep -c` over `looked up | look severity up | blast radius | Step 2 | rule anchors | step 1
of the severity` and are given so this delivery can be sized; re-measure before starting rather than
trusting them, since they are a snapshot:

| File | Hits | What it carries |
|---|---|---|
| `skills/aid-discover/references/state-review.md` | 9 | the largest single site — grade-coupling prose keyed to what a rule anchors |
| `agents/aid-reviewer/AGENT.md` | 6 | `## Severity Classification`'s two numbered steps, plus three bullets |
| `skills/aid-discover/references/reviewer-prompt-anatomy.md` | 6 | per-check severity anchors declared on the file's own authority |
| `aid/templates/grading-rubric.md` | 4 | the scale itself — the one definition site, so this is the payload |
| `agents/aid-reviewer/README.md` | 3 | the human-facing restatement of the agent body |
| `aid/templates/kb-authoring/review-rubric.md` | 3 | the per-check anchors `feature-001` § 3e deliberately left alone |
| `skills/aid-summarize/references/state-validate.md` | 2 | a `Severity` column calling itself a copy of what the catalog declares |
| `skills/aid-discover/references/reviewer-prompt-correctness.md` | 2 | same shape as anatomy's |
| `aid/scripts/kb/lint-modality.sh` | 2 | its **failure message** teaches the retired rationale to whoever trips it |
| `aid/templates/reviewer-ledger-schema.md` | 1 | one pointer |

Plus **48 `Step 2` cells across the ten `review-rubrics/` files** — the `Severity` column `FR-B4`
removes. Those are deletions, not rewrites, and they are the bulk of the row count.

**And two shipped test suites now guard the retired rule**, found 2026-08-11:

| Suite | What it asserts |
|---|---|
| `tests/canonical/test-one-grading-backend.sh` | `SEV05` — *"every catalog row's Severity must sit in the band its own Modality selects"*, which is Step 1 by name. It is one of 24 `SEV*` assertions in that file |
| `tests/canonical/test-review-rubrics.sh` | the rule-row shape including its `Severity` cell |

This is the sharpest case in the inventory, and it is the reason this delivery cannot be deferred
quietly. `SEV05` was **added during `delivery-015`'s cycle-10 FIX and mutation-tested** — it is a
working, load-bearing guard. It will now **fail** as the catalog's `Severity` column is removed, and a
green suite is what tells anyone the change landed correctly. So the suite change is not cleanup after
the fact: it is part of the same commit as the catalog change, or the build goes red for the right
reason at the wrong time.

**Why `lint-modality.sh` is on this list even though `FR-B5a` keeps the check.** Its failure text reads
*"This is what step 1 of the severity scale reads. Without it, a finding against the criterion cannot be
graded — and once a reviewer meets it, the missing modality becomes a criteria gap that blocks the
grade."* Every clause of that is now false, and it is the one place a user meets this explanation at the
moment they are deciding what to do. A wrong error message is worse than no error message.

**This is out of scope for the two SPEC amendments that found it** — those are planning artifacts, this
is product code — and it is deliberately recorded here rather than fixed in passing. It changes eight
rendered copies and needs the byte-identity gate.

## Notes

**Why this exists as a delivery at all.** It is the boundary the rest of this work kept crossing by
accident. `FR-B5b` gave a lookup table authority over severity while nothing enforced it; the modality
check gated a grade on a shape whose stated purpose was feeding that lookup. Both are the same error
made twice -- a script measuring shape being handed authority over substance -- so the correction is
one delivery rather than two patches.

**Why it depends on delivery-004 and nothing else.** The catalog is where a rule row stops carrying a
severity anchor. Until that lands, "the reviewer assigns severity" and "the rule says the severity"
are both true on disk, and a report written against either reading is written against a moving target.
