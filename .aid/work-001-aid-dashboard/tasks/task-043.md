# task-043: Dogfood render — FULL run_generator.py emits the canonical producer edits into .claude/skills + 5 install trees

**Type:** CONFIGURE

**Source:** feature-009-producer-state-emission → delivery-006

**Depends on:** task-038, task-039

**Scope:**
- Run the **FULL** `python3 .claude/skills/aid-generate/scripts/run_generator.py` (NOT a per-script renderer) so the canonical/skills edits from task-038 (`aid-interview` PF-1 scaffold + COMPLETION compose + REQUIREMENTS template) and task-039 (`aid-detail` PF-3 short-name rule + PF-5a `wave-map` emission) re-emit into **this repo's dogfood** `.claude/skills/**` and the **five install trees** (FR24/C5).
- Verify the post-render gates are green: **render-drift** (all five install trees byte-identical to canonical emission), **deterministic-emission / emission-manifest** (manifests current — `verify_deterministic`), and the **ASCII-only** gate for any shipped script/text touched. Do not hand-edit `.claude/skills/**`; they must be pure render output of the FULL generator (any drift = the generator must be re-run, not patched).

**Acceptance Criteria:**
- [ ] The FULL `run_generator.py` was run (not a per-script renderer); `.claude/skills/aid-interview/**` and `.claude/skills/aid-detail/**` reflect the task-038/task-039 canonical edits (PF-1 scaffold/COMPLETION, PF-3 rule, PF-5a wave-map emission) and so do the five install trees.
- [ ] The **render-drift** gate is green: all five install trees are byte-identical to canonical emission; no manual `.claude/skills/**` edit exists (pure render output).
- [ ] The **deterministic-emission / emission-manifest** gate is green (manifests current after the render).
- [ ] The **ASCII-only** gate is green for any shipped script/text touched by the render.
- [ ] All §6 quality gates pass; the dogfood-rendered producers are available for the work-001 migration (task-044) and end-to-end re-view (task-045).
