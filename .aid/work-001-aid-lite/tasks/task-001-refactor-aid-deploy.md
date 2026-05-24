# task-001: Refactor aid-deploy to thin-router

**Type:** REFACTOR

**Source:** feature-002-skill-footprint-refactor → delivery-001

**Depends on:** —

**Scope:**
- `canonical/skills/aid-deploy/SKILL.md` uses **Step-keyed** as its per-state body convention.
- Extract each `## Step N: TITLE` body block into `references/step-{N}-{slug}.md` (or fold the linear steps into a single `references/procedure.md` if they don't gate on state).
- Reduce `canonical/skills/aid-deploy/SKILL.md` to: frontmatter + Title + opening paragraph + `## ⚠️ Pre-flight Checks` + `## State Detection` + `## Dispatch` table.
- Dispatch table columns: **State / Detail / Worker / Advance** (per feature-002 SPEC §Data Model — note the column is `Detail`, not `Reference`).
- Preserve every state's behavior verbatim — this is a packaging change, not a redesign.

**Acceptance Criteria:**
- [ ] SKILL.md is reduced to frontmatter + pre-flight + state detection + dispatch table (no inline state bodies).
- [ ] Per-state (or per-section / per-step) body extracted to `canonical/skills/aid-deploy/references/*.md` files loaded on demand per the convention above.
- [ ] Dispatch table has one row per state with **State / Detail / Worker / Advance** columns (State value in UPPERCASE-with-hyphens per CR6).
- [ ] On state entry, router prints `[State: NAME]` + state-entry heartbeat per FR1.
- [ ] When state completes, router prints `Next: [State: {NEXT}] — run /aid-aid-deploy again` and exits (no auto-advance).
- [ ] Worker column points at sub-agent name where state warrants offload, else `inline`.
- [ ] Behavioural parity: running `/aid-aid-deploy` before and after on the same workspace produces the same state transitions and outputs.
- [ ] work-002 generator re-renders this skill into all 3 install trees byte-identically.
- [ ] All tests pass before AND after (no behavior change).
- [ ] All §6 quality gates pass.
