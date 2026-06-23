# Delivery SPEC -- delivery-009: Lifecycle Governance

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md. It is the IMMUTABLE DEFINITION for this delivery.
Written by aid-plan; not a state file. State lives in delivery-009/STATE.md.

> **Delivery:** delivery-009
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-23

---

## Objective

Draw the clean, non-overlapping boundary between AID's two KB-mutating skills, and make
concept-closure a standing invariant. Define `aid-housekeep` (KB-DELTA) as **source-driven and
global** -- a whole-KB reconcile against current source state (merge-to-master / major change /
periodic), prioritized by delivery-007's per-doc staleness (FR-5) as the shared scoping signal while
retaining the whole-KB content re-review so the "subtly-wrong-all-along" guarantee is preserved.
Define `aid-update-kb` as **prompt-driven and targeted** -- a prompt specifies what to update and the
skill folds it into the KB via the review/calibration gate. The two MUST NOT overlap; per-doc
staleness is the shared signal that distinguishes them. Finally, promote concept-closure from a
discovery-only check to a maintained invariant: both `aid-update-kb` and `aid-housekeep` re-verify
closure after they change the KB, so the KB cannot drift into an undefined project-specific term
after a targeted edit or a reconcile sweep.

## Scope

In scope:

- **feature-010 -- housekeep <-> update-kb boundary & standing closure.** Rewrite
  `aid-housekeep`'s KB-DELTA stage to prioritize its whole-KB sweep via f007's
  `kb-freshness-check.sh` per-doc suspect verdicts (replacing the git-date hint as the drift signal,
  adding a fast no-drift exit) while retaining the whole-KB content re-review of all docs; add a
  closure re-verify step (consuming f004's `closure-check.sh`) to **both** `aid-housekeep` (before it
  commits a KB refresh) and `aid-update-kb` (before it commits a targeted edit); document the
  non-overlap contract (housekeep = global source-driven; update-kb = targeted prompt-driven).

**Out of scope:** the per-doc staleness check itself (delivery-007, f007 -- consumed as the shared
signal); the `closure-check.sh` oracle itself (delivery-001, f004 -- consumed as the invariant
re-verified); the `aid-update-kb` skill definition + `aid-query-kb` rename (delivery-008, f008 --
this delivery draws the boundary around the already-shipped skill, it does not author it).

## Gate Criteria

- [ ] `aid-housekeep` performs a whole-KB source-driven reconcile and `aid-update-kb` performs a
  prompt-driven targeted update, with no overlap and per-doc staleness (f007/FR-5) as the shared
  signal scoping the housekeep sweep. *(f010, AC10)*
- [ ] Given a KB change by `aid-update-kb` or `aid-housekeep`, on completion it re-verifies
  concept-closure (closure is a standing invariant, not discovery-only) via f004's `closure-check.sh`.
  *(f010, AC3 support)*
- [ ] The housekeep sweep retains the whole-KB content re-review (the "subtly-wrong-all-along"
  guarantee) while gaining a fast no-drift exit driven by f007's verdicts. *(f010)*
- [ ] All section-6 quality gates pass

## Tasks

| Task | Type | Title |
|------|------|-------|
| _none yet_ | | |

## Dependencies

- **Depends on:** delivery-001, delivery-007, delivery-008
- **Blocks:** -- (none)

## Notes

Consumes delivery-007's f007 per-doc staleness (the shared scoping signal that distinguishes
housekeep from update-kb), delivery-001's f004 `closure-check.sh` (the closure invariant re-verified
here), and delivery-008's f008 `aid-update-kb` skill (the skill whose boundary vs `aid-housekeep` this
delivery draws). This is the last Should-priority delivery; it closes the lifecycle-governance loop
so closure stays an invariant across every KB-mutating path, not just discovery.
