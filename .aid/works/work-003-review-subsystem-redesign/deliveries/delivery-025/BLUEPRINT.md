# Delivery BLUEPRINT -- delivery-025: Class sweep in FIX

> **Delivery:** delivery-025
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-08-10

---

## Objective

Give `F1` an oracle instead of an instruction. `state-fix.md` already says a finding
is a **class** and that Evidence specifies the extent; nothing checks it, so a corrected claim keeps
its siblings. Scoped as a distinct unit because it needs no new rule set and nothing upstream.

## Scope

- The class-sweep obligation written into `aid-execute/references/state-fix.md`: before a
  fix is marked complete, the fixer greps the distinguishing phrase of the corrected claim across the
  work and reports every site (`FR-E2`).
- The sweep output recorded in the task `STATE.md` `notes` field, so an unswept fix is visible to the
  gate rather than assumed. That field already exists and `writeback-state.sh` already writes it, so
  `AC-17` costs no new artifact -- which `STATE.md` Q29 requires.
- A fixture that fails without the sweep and passes with it (`AC-17`).
- The five-profile render of the changed reference file.

Carries `FR-E2` and `AC-17`. Feature owner `feature-009`.

**Out of scope:** automating the *repair* of the siblings the sweep finds. The obligation is to make them
visible; fixing them is the fixer's existing job. Also out: any new rule set -- this is `F1` given an
oracle, not a new criterion.

## Gate Criteria

- [ ] `state-fix.md` states the sweep as a step with an output, not as advice: the fixer runs
      `class-sweep.sh` and **records its output in the task `STATE.md` `notes` field**, and a fix is not
      complete until it has. **No ledger write is involved** -- an earlier draft routed the output into
      the reconciled row's `Evidence`, needing a new `writeback-ledger.sh` mode, a schema extension and a
      `RECONCILE` step; all three were deleted as unnecessary
      (`features/feature-009-review-effectiveness/SPEC.md § 5`)
- [ ] **The fixture fails without the sweep.** A corrected claim restated in **two other files** --
      `AC-17`'s own wording, not a weaker "sites" -- must leave the fix rejected until the sweep output
      naming both files is on the record. Verified in both directions: a run with the sweep passes, a run
      without it fails
- [ ] The sweep's phrase is a **substring of the text the fix changed**, which is what makes the
      obligation falsifiable: a sweep whose phrase does not appear in the correction has not swept the
      corrected claim. Deliberately **not** derived from the ledger row -- an `Evidence` cell commonly
      quotes several strings, so "the string the row quotes" names nothing
      (`features/feature-009-review-effectiveness/SPEC.md § 5`)
- [ ] Five-profile parity re-run and clean; dogfood byte-identity passes
- [ ] All section-6 quality gates pass

## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. `Wave` is computed from `Depends on`, never authored -- one relation, one source._

| Task | Type | Wave | Title |
|------|------|------|-------|
| task-001 | IMPLEMENT | 1 | class-sweep.sh |
| task-002 | IMPLEMENT | 2 | The sweep obligation in state-fix.md |
| task-003 | TEST | 3 | AC-17 asserted in both directions |
| task-004 | CONFIGURE | 3 | Render the changed reference to five profiles |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

**Measured origin.** The share of this work's own Plan-review findings that were siblings of an
already-corrected claim, and the worst case of a sibling surviving many cycles after its twin was
fixed, are recorded in `STATE.md` Q29. Cited rather than restated, per the restatement convention in
`REQUIREMENTS.md`'s conventions preamble — which is the same discipline this delivery mechanises.

**Why it is independent of delivery-024 despite sharing a feature.** That delivery measures how
*finding* works; this one changes how *fixing* works. Neither reads the other's output.
