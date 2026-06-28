# task-041: Anti-anchoring guard + read-back + verbatim-wording hardening (web-validation)

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-003 (post-gate hardening; added 2026-06-27 from the web best-practice validation)

**Depends on:** task-013, task-016 (the engine docs + spine are authored; this refines advisor-stance.md / calibration.md + adds a read-back)

**Scope:**
Harden the seasoned-analyst engine against the three gaps the web best-practice validation surfaced
(`features/feature-001-elicitation-research-spike/research/web-bestpractice-validation.md`). The
engine's NFR-7 "always propose a Suggested answer" is sound for AID's generative co-design context,
but it carries a residual ANCHORING risk on exactly the deferential/novice cohort AID gives MORE
straw-mans to. Add the validated mitigations (prose edits to the existing engine reference docs;
IMPLEMENT unit-test default OVERRIDDEN -- skills are prose-executed, exercised at task-042 verify):

- **G1 -- anti-anchoring guard (primary):** in `advisor-stance.md` + `calibration.md`:
  - A **calibration-sensitive open-first rule**: for genuinely-open / high-stakes / creative gaps,
    when calibration state is Novice (or the user is reading as deferential), the analyst ASKS
    OPEN-FIRST -- draw out the user's own answer BEFORE offering a straw-man (then the straw-man, if
    needed, confirms rather than leads). For Expert/Mixed users, or low-stakes/convergent gaps, the
    straw-man-first NFR-7 envelope stays as-is. Name "anchoring" explicitly as the failure mode being
    guarded (NN/g leading-questions; the validation report G1).
  - **Re-confirmable assumptions:** when the user accepts a suggested default (esp. without
    engagement), the analyst FLAGS it as an assumption to re-confirm, rather than treating silent
    acceptance as settled (guards the passive-accept trap the grill-me contrast warns about).
  - **Restate-not-replace distortion check:** when the analyst reflects/reformulates the user's
    answer, it must RESTATE (preserve the user's intent + terms), never silently REPLACE it with the
    analyst's framing -- echoing the 2026 RE finding that reformulation "risks distorting original
    intent." A quick self-check before recording.
- **G2 -- whole-picture read-back:** add a rule that BEFORE the approval gate the analyst reflects
  back the ASSEMBLED picture (the gathered intent as a whole) for the user to confirm/correct -- not
  just per-turn confirmations. Place it where it belongs in the engine flow (advisor-stance.md or
  elicitation-engine.md; if it more naturally lands in `state-completion.md`'s pre-approval step,
  put a one-line hook there pointing at the engine rule). Keep it lightweight.
- **G3 -- preserve verbatim wording:** add a rule that the analyst preserves the user's VERBATIM key
  terms (the ubiquitous-language keystone, D1) -- do not silently paraphrase the user's domain terms
  into the analyst's vocabulary; capture the user's word and only propose a rename explicitly (with
  rationale) if needed. Ties to term-capture (Move 2) + the D1 "I'll use your terms" promise.

Do NOT weaken NFR-7 (every question STILL carries a Suggested + Why) -- G1 changes the ORDER/framing
for the novice-open case (ask-then-suggest), not the invariant. Do NOT touch state-triage.md routing
tables, the lite path, or any brownfield mechanism. Edit CANONICAL only (this task is IMPLEMENT-only);
the FULL generator render to the 5 profiles + `.claude` mirror + the brownfield-intact verification
are done AFTER this task (orchestrator render + the delivery-003 re-gate). ASCII-only.

**Acceptance Criteria:**
- [ ] `advisor-stance.md` + `calibration.md` carry the calibration-sensitive **open-first** rule for novice/high-stakes/creative gaps, naming **anchoring** as the guarded failure mode; Expert/low-stakes path keeps straw-man-first. *(G1; validation report)*
- [ ] The **re-confirmable-assumption** flag (on accepted defaults) and the **restate-not-replace** distortion check are specified. *(G1)*
- [ ] A **whole-picture read-back** before the approval gate is specified (in the engine docs, with a `state-completion.md` hook if placed there). *(G2)*
- [ ] A **preserve-verbatim-wording** rule (D1 ubiquitous-language keystone) is specified, tied to term-capture. *(G3)*
- [ ] NFR-7 is NOT weakened (every question still carries Suggested + Why); the change is order/framing for the novice-open case only. *(no regression of AC-3)*
- [ ] No brownfield mechanism touched (routing tables, lite path, recipe tooling unchanged); ASCII-only. *(AC-10)*
- [ ] All REQUIREMENTS.md §6 quality gates pass (full render + DBI + brownfield suites confirmed at the verify task).
