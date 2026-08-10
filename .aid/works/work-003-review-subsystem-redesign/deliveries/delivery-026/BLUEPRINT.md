# Delivery BLUEPRINT -- delivery-026: Per-claim coverage

> **Delivery:** delivery-026
> **Work:** work-003-review-subsystem-redesign
> **Created:** 2026-08-10

---

## Objective

Stop a sampling pass from **clearing** a defect it never looked at. Today a coverage
row asserts that a **file** was examined, and RECONCILE promotes a `Pending` finding to `Fixed` on
the strength of that self-report. The unit becomes the **claim**, and the promotion rests on a
falsifiable statement instead.

## Scope

- The brief carries an **enumerated worklist** for its scope
  (`reviewer-brief-template.md`).
- A `U-` row cites the worklist item it discharges; the `U-` grammar in
  `reviewer-ledger-schema.md` gains the field.
- RECONCILE's `Pending` -> `Fixed` transition rests on every worklist item covering that `Doc` being
  examined, replacing the file-granular `Examined` test (`FR-D10`).
- The fixture proving the new join blocks what the old one cleared (`AC-15`).
- The five-profile render of both changed templates.

Carries `FR-D10` and `AC-15`. Feature owner `feature-005` (coverage rows).

**Out of scope:** how a worklist is *produced* for an arbitrary scope. This delivery specifies that the brief
carries one and what a `U-` row must cite; generating one automatically for every artifact class is
not required by `FR-D10` and is not attempted here. Also out: changing what `grade.sh` counts --
`NFR-1` is unaffected, since coverage rows carry `--` in Severity and the grader ignores them.

## Gate Criteria

- [ ] Every `U-` row in a scope with a worklist cites a worklist item; a row citing none
      is a schema violation `lint`-visible before review
- [ ] **The fixture blocks what the old join cleared.** A partial pass that leaves one worklist item
      unexamined must leave the finding under it `Pending` -- where a file-granular `Examined` would
      have marked it `Fixed`. Run both ways on the same ledger
- [ ] The `"absence proves nothing"` guard is preserved, not duplicated: the two RECONCILE rows are
      restated as one test over worklist items rather than two tests over files
- [ ] `AC-9` still holds -- adding or re-shaping coverage rows changes no grade `grade.sh` computes
      for the same findings
- [ ] Five-profile parity re-run and clean; dogfood byte-identity passes
- [ ] All section-6 quality gates pass

## Tasks

_Derived from `tasks/task-NNN/DETAIL.md`. Written by `aid-detail`; empty until it runs._

| Task | Type | Wave | Title |
|------|------|------|-------|
| _none yet_ | | | |

## Dependencies

- **Depends on:** delivery-009
- **Blocks:** delivery-027

## Notes

**Why it must follow delivery-009.** That delivery writes the ledger lifecycle and moves
status reconciliation to the orchestrator (`FR-D5`). This one changes the join that migration
installs, so running it first would mean writing the join twice.

**Measured origin.** `STATE.md` Q27 records the measurement: how often a file this work marked
`Examined` still held findings, how many reviews missed each pre-existing defect, and the single
variable with counter-evidence -- an enumerated worklist returning far more findings in one pass
than any self-directed pass did, on the same artifacts under the same rules. Cited rather than
restated, per the restatement convention in `REQUIREMENTS.md § 5`.
