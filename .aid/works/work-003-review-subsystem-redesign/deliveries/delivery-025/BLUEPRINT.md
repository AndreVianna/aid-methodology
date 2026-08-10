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
- The sweep output recorded where the gate can read it, so an unswept fix is visible rather than
  assumed.
- A fixture that fails without the sweep and passes with it (`AC-17`).
- The five-profile render of the changed reference file.

Carries `FR-E2` and `AC-17`. Feature owner `feature-009`.

**Out of scope:** automating the *repair* of the siblings the sweep finds. The obligation is to make them
visible; fixing them is the fixer's existing job. Also out: any new rule set -- this is `F1` given an
oracle, not a new criterion.

## Gate Criteria

- [ ] `state-fix.md` states the sweep as a step with an output, not as advice, and names where that
      output is recorded -- the fixer's report to the orchestrator, which the orchestrator carries into
      the reconciled row's `Evidence`. The fixer cannot write the ledger itself: it has a single writer,
      and `writeback-ledger.sh` gains the `Evidence`-append mode this delivery ships
      (`features/feature-009-review-effectiveness/SPEC.md § 5`)
- [ ] **The fixture fails without the sweep.** A corrected claim restated in **two other files** --
      `AC-17`'s own wording, not a weaker "sites" -- must leave the fix rejected until the sweep output
      naming both files is on the record. Verified in both directions: a run with the sweep passes, a run
      without it fails
- [ ] The sweep's phrase is derived from the ledger row being discharged, not chosen freely, so two
      fixers sweeping the same finding sweep the same thing
- [ ] Five-profile parity re-run and clean; dogfood byte-identity passes
- [ ] All section-6 quality gates pass

## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. Written by `aid-detail`; empty until it runs._

| Task | Type | Wave | Title |
|------|------|------|-------|
| _none yet_ | | | |

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
