# task-016: Opener-seam de-dup in state-continue.md

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-003

**Depends on:** task-014, task-015

**Scope:**
- Resolve the 002/004 opener seam so the single D1 opener fires EXACTLY ONCE across TRIAGE -> CONTINUE.
  Edit ONLY `canonical/skills/aid-interview/references/state-continue.md`: make the D1 opener emission
  (the CONTENT landed by task-014) CONDITIONAL.
- **The conditional:** on entry CONTINUE already reads `STATE.md`; check for the `## Triage **Opener:**`
  field (written by task-015's Step 6). When PRESENT, the engine's turn 1 already fired in TRIAGE, so
  CONTINUE does NOT re-emit the D1 opener -- it seeds the adaptive loop with the opener answer as the
  first captured intent (vocabulary + calibration already read) and enters at the loop's
  STOP-CHECK / GAP-SELECTION step.
- **Defensive fallback:** when `**Opener:**` is ABSENT -- a legacy direct-CONTINUE entry, a pre-TRIAGE
  in-flight work, or a loopback with no triage record -- CONTINUE emits the D1 opener itself (this is
  the f002 replacement, now made conditional).
- **Compose with the existing `## Escalation Carry` path:** CONTINUE skips the opener when EITHER an
  Escalation Carry block OR an `## Triage **Opener:**` capture is present; the `Path: escalated`
  sentinel semantics and the Escalation Carry hand-off are otherwise unchanged.
- ASCII-only. Surgical single-file edit; no other spine behavior altered.
- **Out of scope:** the `**Opener:**` field producer in state-triage.md (task-015); the engine docs
  (tasks 010-013); generator render (task-017).

**Acceptance Criteria:**
- [ ] `state-continue.md`'s D1 opener emission is CONDITIONAL: skipped when `## Triage **Opener:**` is present (CONTINUE seeds the loop with the carried opener answer and enters at STOP-CHECK / GAP-SELECTION, no re-ask). *(AC-7 de-dup, gate criterion 4)*
- [ ] The defensive fallback emits the D1 opener when `**Opener:**` is absent (legacy direct-CONTINUE / pre-TRIAGE / loopback). *(feature-004 de-dup mechanics step 4)*
- [ ] The skip composes with `## Escalation Carry` (skip when EITHER signal is present); `Path: escalated` semantics and the Escalation Carry hand-off are byte-unchanged. *(AC-10 / NFR-2)*
- [ ] Only `state-continue.md` is edited (verify via diff); ASCII-only; skill is prose-executed (no unit test; IMPLEMENT default overridden). Brownfield full-path interview still completes (verified at task-018); render deferred to task-017.
- [ ] All REQUIREMENTS.md §6 quality gates pass.
