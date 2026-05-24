# task-006: Refactor aid-specify to thin-router

**Type:** REFACTOR

**Source:** feature-002-skill-footprint-refactor → delivery-001

**Depends on:** —

**Scope:**
- `canonical/skills/aid-specify/SKILL.md` uses **State-keyed** as its per-state body convention.
- Extract each `## State N: NAME` body block into `references/state-{name-slug}.md`. aid-specify has 3 H2 state blocks on disk: State 1 INITIALIZE, State 2 CONTINUE, State 5 REVIEW. SPIKE / BLOCKED / DONE are sub-state labels in the State Detection table (not standalone H2 blocks); they remain part of the State Detection logic and the dispatch table, not separate reference files.
- Reduce `canonical/skills/aid-specify/SKILL.md` to: frontmatter + Title + opening paragraph + `## ⚠️ Pre-flight Checks` + `## State Detection` + `## Dispatch` table.
- Dispatch table columns: **State / Detail / Worker / Advance** (per feature-002 SPEC §Data Model — note the column is `Detail`, not `Reference`).
- Preserve every state's behavior verbatim — this is a packaging change, not a redesign.
- After the refactor edits land in `canonical/`, **re-run work-002's generator** to render all 3 install trees + commit the regenerated `EMISSION-MANIFEST.md` (per the manifest's safety-boundary semantics).

**Acceptance Criteria:**
- [ ] SKILL.md is reduced to frontmatter + pre-flight + state detection + dispatch table (no inline state bodies).
- [ ] Per-state (or per-section / per-step) body extracted to `canonical/skills/aid-specify/references/*.md` files loaded on demand per the convention above.
- [ ] Dispatch table has one row per state with **State / Detail / Worker / Advance** columns (State value in UPPERCASE-with-hyphens per CR6).
- [ ] On state entry, router prints `[State: NAME]` + state-entry heartbeat per FR1.
- [ ] When state completes, router prints `Next: [State: {NEXT}] — run /aid-specify again` and exits (no auto-advance).
- [ ] Worker column points at sub-agent name where state warrants offload, else `inline`.
- [ ] Behavioural parity: running `/aid-specify` before and after on the same workspace produces the same state transitions and outputs.
- [ ] work-002 generator re-renders this skill into all 3 install trees byte-identically.
- [ ] Behavior-equivalence verified per the per-skill state-extraction recipe (feature-002 SPEC's Migration Plan): every state's body before-and-after diff shows ONLY the move from inline H2/section to `references/*.md` — no content edits, no logic changes. (No traditional unit-test suite exists per `.aid/knowledge/test-landscape.md`; equivalence is verified by inspection + the post-refactor pipeline parity test in task-012.)
- [ ] All §6 quality gates pass.
