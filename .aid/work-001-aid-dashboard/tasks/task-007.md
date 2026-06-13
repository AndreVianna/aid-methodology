# task-007: M4 — wire phase skills to emit `--pipeline` at existing transitions

**Type:** IMPLEMENT

**Source:** feature-001-pipeline-state-architecture → delivery-001

**Depends on:** task-005

**Scope:**
- Wire each phase skill to call `writeback-state.sh --pipeline` at its EXISTING transitions (feature-001 §4 M4): `aid-specify`, `aid-plan`, `aid-detail`, `aid-execute`, `aid-deploy` — emit `Lifecycle` / `Phase` / `Active Skill` / `Updated` at the points where they already transition.
- Edit each skill's `references/state-*.md` only at the transition points the skill already performs — add a single locked helper call; introduce no new prompt, gate, or output.
- Re-run the FULL `run_generator.py`; manually confirm no new prompts/gates appear (C4 observable-behavior preservation).

**Acceptance Criteria:**
- [ ] Each of `aid-specify`, `aid-plan`, `aid-detail`, `aid-execute`, `aid-deploy` emits a `--pipeline` write at its existing phase/state transitions, setting the correct `Phase` + `Active Skill` + `Lifecycle: Running` (or terminal) + `Updated`.
- [ ] No new prompt, gate, decision, or user-facing output is introduced at any wired transition (C4); the emitted `--pipeline` call is the only added action.
- [ ] The `## Pipeline Status` block now tracks the live phase deterministically across a full-path run (feature-001 AC: a single reliable source for "what skill/task is running").
- [ ] FULL generator re-run; no render-drift; `verify_deterministic.py` exits 0.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Unit/integration tests for the new emit points added where applicable; existing `tests/run-all.sh` + Windows installer suite pass; FULL generator build passes (behavior-preservation walk-through is task-009).
