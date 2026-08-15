# Scoped Review Cycles

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-15 | Feature identified from REQUIREMENTS.md §5 FR-1–FR-7 and FR-14, §9 AC-2–AC-4, AC-9, AC-10, AC-12 | /aid-define |
| 2026-08-15 | FR-14 folded in here rather than made a fourth feature — it edits the same sites; NFR-5 close-out folded in likewise (C-7) | /aid-define |
| 2026-08-15 | **AC-13 adopted** (for FR-5, the once-per-phase contradiction pass), promoted to a numbered criterion in REQUIREMENTS.md §9 after cross-reference cycle 1 found FR-5 demanded by nothing. `## Source` updated to list it — cycle 2 found it present in the criteria list but absent from Source | /aid-define |

## Source

- REQUIREMENTS.md §5 FR-1 to FR-7 (the scoped cycle and its three guards)
- REQUIREMENTS.md §5 FR-14 (the requirements slice for the per-feature specify gate)
- REQUIREMENTS.md §6 NFR-4 (no guarantee traded for cost), NFR-5 (the single render)
- REQUIREMENTS.md §7 C-3 (7 columns and `grade.sh` untouched), C-4 (resolution stays scope-free)
- REQUIREMENTS.md §9 AC-2, AC-3, AC-4, AC-9, AC-10, AC-12, AC-13

## Description

A review re-reads the whole artifact on every cycle. The cause is one sentence at the end
of the cycle-2-and-later workflow in `reviewer-ledger-schema.md`: *"Append new rows as
`Pending` for newly-found issues."* Everything before it is already targeted and cheap —
verify each `Pending` row on disk, promote to `Fixed`, demote a regressed `Fixed` to
`Recurred`. That last clause is what forces the full re-read, because finding NEW issues
means re-scanning everything.

This feature splits that clause in two. **Ledger verification stays full; new-finding
discovery becomes scoped.** Cycle 1 still reads everything. Cycles 2 and later hunt for new
findings only in what the previous FIX changed.

The scoping is only safe because of three guards, and all three land with it rather than
after it:

1. **A fix in one section breaks another.** The scoped surface includes the sections that
   *reference* the changed ones, found by mechanical cross-reference lookup — not by asking
   the model to judge what might be affected.
2. **Cross-document contradictions.** That pass is kept, but runs once per PHASE instead of
   once per cycle per feature. It was never a per-cycle check.
3. **Something is missed anyway.** `Recurred` already exists for exactly this, and a final
   full pass runs before approval as the backstop. A scoped cycle never approves.

Feature-002 is what makes this sound rather than merely cheaper. A scoped cycle only works
for criteria that can be *evaluated* against a subset, and evaluation scope varies per
criterion — `G-01` fires on a local occurrence, `KB-02` needs the whole file, `G-07` needs
the whole corpus. A criterion with an oracle is re-run at any scope for negligible cost, so
its evaluation scope stops mattering. That is why feature-002 comes first.

**Folded in here, per C-7 rather than made into more features:** FR-14, the requirements
slice, because it edits the same files; and the NFR-5 close-out, because a render is the
last act of the last delivery, not a feature of its own.

## User Stories

- As the repo owner, I want a review cycle to cost what the change costs rather than what
  the document costs, so that a small fix does not pay for a full re-read.
- As a reviewer, I want the surface I must hunt to be stated and bounded, so that my
  coverage is provable rather than asserted.
- As a reviewer on a per-feature specify gate, I want the slice of requirements the feature
  traces to rather than the whole document, so that I am not re-reading 88 KB to check one
  feature.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-2** Given a defect seeded in a section that REFERENCES a changed section, when a
      scoped cycle runs, then the defect is found. FR-4's guard is tested, not trusted.
- [ ] **AC-3** Given a defect seeded OUTSIDE the scoped surface and consequently missed by
      a scoped cycle, when the final full pass runs, then the defect is caught. The
      backstop is demonstrated end to end.
- [ ] **AC-4** Given a `Fixed` row that regresses in a section outside the scoped surface,
      when the next cycle runs, then it is still demoted to `Recurred` — ledger
      verification is provably unscoped.
- [ ] **AC-9** Given a per-feature specify gate, when it is dispatched, then it carries only
      the requirements slice the feature traces to, and the saving is stated as a measured
      byte reduction on a real feature.
- [ ] **AC-10** Given the work at close, when the ledger and the grader are inspected, then
      the ledger is still 7 columns and `canonical/aid/scripts/grade.sh` is byte-identical
      to its state at the start of the work (C-3).
- [ ] **AC-12** Given the work at close, when CI runs, then the render-drift gate and the
      dogfood byte-identity gate are both green (NFR-5).
- [ ] **AC-13** Given a phase whose gate runs 2 or more cycles over more than one feature,
      when the cross-document contradiction pass is counted, then it executed exactly once
      for the phase — and a contradiction spanning two features is still caught by it. Both
      halves are required: a pass that runs once but stops catching what it exists for is a
      regression, not a saving.
- [ ] Given cycle 1 of any review, when it runs, then it reads the whole artifact —
      unchanged behaviour (FR-1).
- [ ] Given a scoped cycle, when it completes, then it has not approved the artifact; only
      a full pass can (FR-6).

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
