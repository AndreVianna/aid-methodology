# task-012: Calibration reference doc (read+ask, depth-shaping)

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-003

**Depends on:** -- (none)

**Scope:**
- Author the new single-concern reference doc `canonical/skills/aid-interview/references/calibration.md`
  (additive). It encodes the AC-4 calibration design that the engine driver (task-013) consults in
  selection Step 4 and gap-selection rank 2.
- **The AC-4 vs D1 reconciliation:** the opener is NEVER the calibration question -- turn 1 is always
  the D1 what+why example-anchored question; calibration is a DISTINCT early behavior, not turn 1.
- **(a) READ -- continuous, from turn 1 onward:** infer expertise/role from HOW the user answers
  (jargon fluency, precision, decisiveness, self-classification -> Expert; hedging, "I don't know",
  asking what a term means, requesting recommendations -> Novice/unsure). Calibration state is one of
  `Unknown | Expert | Mixed | Novice`, re-read EVERY turn (continuous, not a one-time gate).
- **(b) ASK -- an explicit early follow-up, NOT turn 1:** when state is still `Unknown` after >= 1
  substantive answer (gap-selection rank 2), the engine MAY emit an explicit knowledge-level/type
  question (domain familiarity, software/requirements practice, AID familiarity). This question ITSELF
  carries an NFR-7 `Suggested:`+`Why:` envelope (a straw-man inferred from the opener); it confirms the
  read, never replaces it, and is never asked cold on turn 1.
- **Depth-shaping table** (the AC-4 "demonstrably adapts" bar): Expert -> Lighter (fewer why-steps,
  confirm-and-move, skip teaching scaffolds); Mixed -> Targeted (confirm where fluent, draw out where
  hedging); Novice/unsure -> Heavier (more drawing-out, teaching scaffolds, more example-probes and
  why-steps, proactive recommendations). Note calibration is shared substrate that feature-004
  inherits (an unsure user needs more drawing-out to route correctly).
- Single-concern per file; cross-references `elicitation-engine.md` and `advisor-stance.md` by real
  path. ASCII-only.
- **Out of scope:** the selector loop (task-013); the move playbook (task-011); the envelope template
  (task-010); generator render (task-017).

**Acceptance Criteria:**
- [ ] `references/calibration.md` exists and documents BOTH the continuous READ (from turn 1) and the explicit ASK (an early follow-up gated on `Unknown` after >= 1 substantive answer, never turn 1), with the ASK itself carrying an NFR-7 `Suggested:`+`Why:` envelope. *(AC-4, gate criterion 2)*
- [ ] The `Unknown | Expert | Mixed | Novice` state and the per-state depth-shaping behaviors are specified concretely enough that an Expert run and a Novice run diverge demonstrably in depth. *(AC-4 "adapts" bar)*
- [ ] The doc states explicitly that the opener is NEVER the calibration question (D1 preserved). *(AC-4 vs D1 reconciliation, gate criterion 2)*
- [ ] Doc is single-concern, cross-references the engine + advisor docs by real path, and is ASCII-only.
- [ ] Skill is prose-executed: no unit test is added (per feature-002 DoD; IMPLEMENT unit-test default overridden). Existing canonical tests untouched (verified at task-018); render deferred to task-017.
- [ ] All REQUIREMENTS.md §6 quality gates pass.
