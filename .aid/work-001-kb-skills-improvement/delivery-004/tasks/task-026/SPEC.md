# task-026: Panel-scaling amendment to state-review.md (branch on review.panel; collapsed = sequential mandate passes)

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-004

**Depends on:** task-014 (delivery-001), task-025

**Scope:**
- Amend `canonical/skills/aid-discover/references/state-review.md` Step 1 to **branch on the
  `review.panel` parameter** (the seam f005 left explicitly deferred -- the per-mandate dispatch
  list is the unit f006 scales). `review.panel` is supplied as a runtime parameter from
  `path-config.md` (per task-025), passed by the orchestrator to REVIEW -- NOT a persisted settings
  key (it is per-run, per-path, re-derived each run, like the closure cap).
  - **`panel: full` (brownfield-large):** the UNCHANGED f005 default -- 5 parallel `aid-reviewer`
    dispatches, one per mandate {Correctness, Anatomy/Coverage, Concept-closure, Teach-back,
    Calibration}, merged to `discovery.md`. No collapse.
  - **`panel: collapsed` (brownfield-small + greenfield):** the panel collapses to **2 dispatches**:
    1. **ONE `aid-reviewer`** that runs the four content mandates (M1 Correctness / M2 Anatomy /
       M3 Concept-closure / M5 Calibration) as **SEPARATE SEQUENTIAL PASSES** within the single
       agent -- driven through each mandate's existing FOCUS body
       (`reviewer-prompt-{correctness,anatomy,concept-closure,calibration}.md`, the f005 split) ONE
       AT A TIME, IN ORDER, writing that mandate's findings to the scratch ledger before the next
       pass, the per-mandate results then concatenated into the one ledger the merge step (f005
       Step 2) consumes. This is the **anti-P2 no-blending property preserved at lower
       parallelism** -- each mandate is still adjudicated on its own; only the four passes'
       parallelism collapses (4 parallel agents -> 4 sequential passes in 1 agent), NOT the
       no-blending rule. **[SPIKE-T3 -- RESOLVED]**.
    2. **ONE clean-context teach-back reviewer (M4)** -- teach-back stays its own clean-context
       dispatch on EVERY path (it cannot share a context that has seen the source), preserving the
       teach-back keystone exit (FR-18).
  - **All five mandates still run on every path** (FR-17: mandates + the no-blending rule are
    invariant; only the size/parallelism scales).
  - **Greenfield deferral note:** this task builds the `review.panel` BRANCH LOGIC (the `full` vs
    `collapsed` dispatch-count seam) only. Greenfield's `collapsed` panel value takes effect when
    delivery-009 delivers the greenfield GENERATE/REVIEW path; D4 does NOT build greenfield behavior
    (consistent with task-023/task-025, where the greenfield classifier row + route-note are D4 but
    the greenfield path behavior is delivery-009).
  - **Do NOT touch** the f005 mandate bodies, the merge/grade (Step 2), or the teach-back hard gate
    -- this task edits only the dispatch-count branch f005 left as a seam.
- Re-run `python .claude/skills/generate-profile/scripts/run_generator.py`; commit regenerated
  `profiles/` so the `state-review.md` edit renders to all 5 trees + `.claude/` (render-drift stays
  green; **[SPIKE-T4]**).

**Acceptance Criteria:**
- [ ] `state-review.md` Step 1 branches on `review.panel`: `full` => 5 parallel mandate dispatches
  (f005 default, unchanged); `collapsed` => 2 dispatches.
- [ ] For `collapsed`, dispatch 1 is ONE reviewer running M1/M2/M3/M5 as separate sequential passes
  (driven through the four existing FOCUS bodies one at a time, in order, each written to the
  ledger before the next), explicitly NOT one blended judgment.
- [ ] For `collapsed`, dispatch 2 is ONE clean-context teach-back (M4) reviewer on every collapsed
  path (brownfield-small + greenfield).
- [ ] All five mandates run on every path; the no-blending (anti-P2) property is preserved at lower
  parallelism.
- [ ] The mandate bodies, the merge/grade (Step 2), and the teach-back hard gate are unchanged
  (this task touches only the dispatch-count branch).
- [ ] `review.panel` is consumed as a runtime parameter (from path-config.md / the orchestrator),
  not introduced as a persisted settings key.
- [ ] `run_generator.py` re-run; the edit renders to all 5 trees + `.claude/`; render-drift stays
  green.
- [ ] All section-6 quality gates pass.
