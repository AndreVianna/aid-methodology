# task-007: Refactor aid-plan to thin-router

**Type:** REFACTOR

**Source:** feature-002-skill-footprint-refactor → delivery-001

**Depends on:** —

**Scope:**
- `canonical/skills/aid-plan/SKILL.md` uses **Section-keyed (no per-state blocks)** as its per-state body convention.
- Body is procedural narrative without per-state H2 blocks. Refactor splits the body *thematically* into `references/{theme}.md` files (e.g., dependency-mapping, parallel-grouping, conditional-skip-logic). Dispatch table rows become section anchors rather than state names.
- Reduce `canonical/skills/aid-plan/SKILL.md` to: frontmatter + Title + opening paragraph + `## ⚠️ Pre-flight Checks` + `## State Detection` + `## Dispatch` table.
- Dispatch table columns: **State / Detail / Worker / Advance** (per feature-002 SPEC §Data Model — note the column is `Detail`, not `Reference`).
- Preserve every state's behavior verbatim — this is a packaging change, not a redesign.
- After the refactor edits land in `canonical/`, **re-run work-002's generator** to render all 3 install trees + commit the regenerated `EMISSION-MANIFEST.md` (per the manifest's safety-boundary semantics).

**Acceptance Criteria:**
- [ ] SKILL.md is reduced to frontmatter + pre-flight + state detection + dispatch table (no inline state bodies).
- [ ] Per-state (or per-section / per-step) body extracted to `canonical/skills/aid-plan/references/*.md` files loaded on demand per the convention above.
- [ ] Dispatch table has one row per state with **State / Detail / Worker / Advance** columns (State value in UPPERCASE-with-hyphens per CR6).
- [ ] On state entry, router prints `[State: NAME]` + state-entry heartbeat per FR1.
- [ ] When state completes, router prints `Next: [State: {NEXT}] — run /aid-plan again` and exits (no auto-advance).
- [ ] Worker column points at sub-agent name where state warrants offload, else `inline`.
- [ ] Behavioural parity: running `/aid-plan` before and after on the same workspace produces the same state transitions and outputs.
- [ ] work-002 generator re-renders this skill into all 3 install trees byte-identically.
- [ ] Behavior-equivalence verified per the per-skill state-extraction recipe (feature-002 SPEC's Migration Plan): every state's body before-and-after diff shows ONLY the move from inline H2/section to `references/*.md` — no content edits, no logic changes. (No traditional unit-test suite exists per `.aid/knowledge/test-landscape.md`; equivalence is verified by inspection + the post-refactor pipeline parity test in task-012.)
- [ ] All §6 quality gates pass.
