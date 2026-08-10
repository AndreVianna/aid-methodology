# Delivery BLUEPRINT -- delivery-020: Ledger sighting log

> **Delivery:** delivery-020
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-08-09

---

## Objective

Make the ledger able to answer the question its own circuit breaker depends on: is this finding the
same defect returning, or a different defect in the same place? Scoped as a distinct unit because it
changes the durable row's shape, which is `feature-003`'s substrate and is read by `grade.sh`,
`writeback-ledger.sh` and every reconciliation site.

## Scope

- A durable ledger row keeps a short list of **one-line problem statements, one per sighting**,
  rather than only a status and a count. On a new sighting at an existing `(Doc, Rule)` key the
  incoming description is compared against the list already present.
- The `RECONCILE` join contract updated to record a sighting rather than overwrite nothing: today
  `Fixed` + present-in-scratch flips to `Recurred` while the row's `Description` -- which is
  authorial -- is never rewritten, so the row reports the FIRST sighting's text forever.
- `reviewer-ledger-schema.md`'s row definition and `writeback-ledger.sh`'s append/set-status paths.
- Whatever `§ DONE`'s deletion step must retain for the breaker to remain computable.

**Out of scope:** `grade.sh`'s scoring logic (NFR-1 forbids changing it, and this is grade-inert: `Pending` and
`Recurred` already score identically); the 7-column legacy shape, which stays readable per
*"the header decides"*.

## Gate Criteria

- [ ] A durable row that has been seen twice carries two distinct one-line statements, and a
      reader can tell from the row alone whether the second was the same defect or a new one
- [ ] The non-improvement breaker is computable **from the durable ledger alone** -- no scratch file
      is required to determine what a cycle opened versus closed
- [ ] `grade.sh` is unmodified and its output is unchanged for every existing ledger: `git diff`
      on `grade.sh` is empty, and a fixture ledger grades identically before and after
- [ ] A 7-column ledger written before this change still parses and still grades correctly
- [ ] `writeback-ledger.sh` rejects a malformed sighting list with a distinct exit code, and that
      code is documented in its header
- [ ] All section-6 quality gates pass

## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. Written by `aid-detail`; empty until it runs._

| Task | Type | Wave | Title |
|------|------|------|-------|
| _none yet_ | | | |

## Dependencies

- **Depends on:** delivery-009
- **Blocks:** delivery-022

## Notes

**Measured on this work's own `/aid-detail` review.** The derivation matters, because a naive row
count double-counts: the durable ledger **copies** the first sighting's description, so it overlaps
the scratch ledgers. The seven ledgers hold **22 rows** -- 12 durable plus 10 across
`cycle2..cycle7` -- of which **5 durable rows repeat a scratch row's description verbatim**, so the
honest total is **17 sightings** over **12 distinct `(Doc, Rule)` keys**. Comparing scratch against
scratch gives **0 identical descriptions**: 4 keys were seen more than once and every repeat was
textually different, the 5 extra sightings over those 4 keys being exactly what takes 12 keys to 17, and all 5 apparent repeats are the durable row's frozen copy of a scratch row.
**That double-count is the defect itself.** Reconstructing the true figures required reading the six
`*-cycleN.md` scratch files that `§ DONE` instructs the orchestrator to delete -- so the ledger that
survives is precisely the one that cannot answer the question.

**The alternative was considered and declined.** Folding a discriminator into the join key does not
preserve *what the earlier problems were*, which is the thing a human needs to judge whether a loop
is converging. Retaining scratch instead would silently convert "delete at DONE" into "retain at
DONE", making cleanup a requirement by the back door.

**Not a grading bug.** No grade computed in this work is wrong because of it.
