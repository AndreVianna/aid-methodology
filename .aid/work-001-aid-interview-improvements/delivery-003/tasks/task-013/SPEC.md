# task-013: Elicitation-engine driver reference doc (opener + 5-step selector)

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-003

**Depends on:** task-010, task-011, task-012

**Scope:**
- Author the new reference doc `canonical/skills/aid-interview/references/elicitation-engine.md`
  (additive) -- the engine DRIVER that integrates the three component docs authored in task-010
  (advisor-stance / NFR-7 envelope), task-011 (move-playbook), and task-012 (calibration). This is the
  load-bearing "engine = one fixed opener + adaptive loop (D1 + D2), NOT a question list" doc.
- **The D1 fixed opener (the ONLY fixed turn):** the single fixed what+why example-anchored question,
  NFR-7-compliant by construction (the baked-in concrete example IS the `Suggested:`; the cue "describe
  the pieces the way you'd naturally name them -- I'll work from your words" IS the `Why:`). On READ it
  captures the first vocabulary (term-capture) + seeds the calibration signal.
- **The deterministic five-step next-move selector** (every subsequent turn, D2), inputs = D2's four
  drivers (seed-gap, move playbook, calibration state, NFR-7 invariant):
  1. STOP CHECK (precedes gap selection; NFR-4 / RQ-A5) -- halt at minimal-but-sufficient for the host
     purpose, NOT the end of a list (the discipline grill-me lacks);
  2. GAP SELECTION via the precedence ranking (rank 1 open coherence conflict; rank 2 calibration
     unknown only after >= 1 substantive answer, never turn 1; rank 3 keystone seed/critical
     REQUIREMENTS gap; rank 4 lighter element; rank 5 under-pinned existing answer);
  3. MOVE SELECTION -- delegate to `move-playbook.md`'s gap-type -> move firing table;
  4. CALIBRATION SHAPING -- delegate to `calibration.md`'s depth-shaping;
  5. ENVELOPE + EMIT -- wrap via `advisor-stance.md`'s NFR-7 envelope + run the pre-emit self-check;
     then READ -> record (REQUIREMENTS / seed doc + STATE) -> re-read calibration -> back to Step 1.
- **The consumer-parameterization hooks (consumption contract, D3):** the three parameters a consumer
  supplies -- gap inventory, stop predicate, record sink -- and the statement that feature-003 (seed
  authoring) and feature-004 (guided triage) CONSUME the engine (do not re-implement it), with the
  engine returning control to the host state when its stop check fires. Include the loop diagram
  showing EMIT D1 OPENER -> READ -> ADAPTIVE LOOP -> EXIT to the host state's advance.
- ASCII-only; cross-references the three component docs by real path.
- **Out of scope:** editing the existing spine files (task-014); the triage gap inventory / routing
  (feature-004 / task-015); the seed content model (feature-003); generator render (task-017).

**Acceptance Criteria:**
- [ ] `references/elicitation-engine.md` exists and specifies the D1 fixed opener as the ONE fixed turn, NFR-7-compliant by construction (example = `Suggested:`, cue = `Why:`). *(D1, AC-3, gate criterion 1)*
- [ ] The five-step selector (STOP CHECK -> GAP SELECTION -> MOVE SELECTION -> CALIBRATION SHAPING -> ENVELOPE+EMIT) is documented as a deterministic loop that delegates Step 3 to move-playbook.md, Step 4 to calibration.md, Step 5 to advisor-stance.md; the gap-precedence ranking (ranks 1-5) is reproduced. *(D2)*
- [ ] The STOP CHECK halts at minimal-but-sufficient (consumer-parameterized), not at the end of a list; the doc shows the loop is selector-driven, not a fixed questionnaire (no hidden question list). *(D1/D2/NFR-4, gate criterion 3)*
- [ ] The three-parameter consumption contract (gap inventory / stop predicate / record sink) and the consume-not-reimplement statement for features 003 and 004 are present. *(D3, gate criterion 4 enabling)*
- [ ] Doc cross-references the three component docs by real path and is ASCII-only; one-question-per-turn and update-after-answer invariants are preserved.
- [ ] Skill is prose-executed: no unit test is added (per feature-002 DoD; IMPLEMENT unit-test default overridden by the in-doc selector logic + the envelope self-check). Existing canonical tests untouched (verified at task-018); render deferred to task-017.
- [ ] All REQUIREMENTS.md §6 quality gates pass.
