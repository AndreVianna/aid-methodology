# task-084: Blind Work-Simulation limb (generalize reviewer-prompt-actback.md)

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-084/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-015

**Depends on:** task-083

**Scope:**
- Realize feature-016 §3.1 / §4.1 — the **Blind Work-Simulation** limb (Intent 1, the assertiveness
  gate, FR-54), generalizing the M4 act-back mandate. Edit **canonical** sources only; the full
  `run_generator.py` regen + `.claude` sync is the regen step.
- **Generalize `canonical/skills/aid-discover/references/reviewer-prompt-actback.md`** from a single
  representative software task to a **derived work-probe set** (from task-083's helper): a
  clean-context, **KB-only (no source access)** agent plans each work probe step-by-step **in the
  project's own conventions**, tagging each step **STATED** (KB gave the contract/convention) /
  **ASSUMED** (had to guess) / **REACH** (would have to read source).
- **Scoring + the quality dimension:** any **load-bearing ASSUMED/REACH** = `[HIGH] [ACTBACK]`
  insufficiency (FAIL -> FIX target). Add the **quality check (not just functional):** a plan that
  would "work" but violates the project's conventions (C3), invariants/gotchas, or quality bars (C6)
  is a **quality FAIL** — the KB failed to convey the quality contract. PASS = a complete, correct,
  convention-honoring plan with **zero** load-bearing insufficiencies.
- Emits into the dual-intent ledger with the `[ACTBACK]` tag (the ledger + gate wiring is task-086;
  this task authors the limb body + its emission contract). Reuses the existing `aid-reviewer`
  parallel-panel + the 7-column ledger schema — **no** new agent enum, **no** new grading infra.
- Run the full `run_generator.py` regen -> `.claude` sync; never edit the rendered `.claude/` copy.

**Acceptance Criteria:**
- [ ] `reviewer-prompt-actback.md` is generalized to the **Blind Work-Simulation** limb: KB-only
  (no source) step-by-step planning of the **derived work-probe set** in the project's own
  conventions, with per-step **STATED / ASSUMED / REACH** tagging. *(FR-54, §3.1)*
- [ ] Any **load-bearing ASSUMED/REACH** is a `[HIGH] [ACTBACK]` insufficiency (FAIL -> FIX). *(FR-54)*
- [ ] The **quality check** is present: a plan violating C3 conventions / invariants / C6 quality
  bars is a **quality FAIL**; PASS = complete, correct, convention-honoring, **zero** load-bearing
  insufficiencies. *(FR-54)*
- [ ] The limb reuses the existing parallel-panel + 7-column ledger and emits the `[ACTBACK]` tag;
  **no** new agent enum / verdict sentinel / grading infra. *(scope discipline)*
- [ ] Edits are `canonical/...` only; the full `run_generator.py` regen + `.claude` sync run.
- [ ] All section-6 quality gates pass.
