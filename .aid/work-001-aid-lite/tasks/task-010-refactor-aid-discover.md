# task-010: Refactor aid-discover to thin-router

**Type:** REFACTOR

**Source:** feature-002-skill-footprint-refactor → delivery-001

**Depends on:** —

**Scope:**
- `canonical/skills/aid-discover/SKILL.md` uses **Mode-keyed (with `## Step:` substructure inside each Mode)** as its per-state body convention.
- Mode is the primary key. Extract each `## Mode: NAME` body into `references/state-{name-lower}.md`. Step substructure within each Mode stays inside that Mode's reference file. Sub-agent dispatch pattern in Steps 2-5 of GENERATE mode preserved as-is in the dispatch table (Worker column points at the 4 discovery agents).
- Reduce `canonical/skills/aid-discover/SKILL.md` to: frontmatter + Title + opening paragraph + `## ⚠️ Pre-flight Checks` + `## State Detection` + `## Dispatch` table.
- Dispatch table columns: **State / Detail / Worker / Advance** (per feature-002 SPEC §Data Model — note the column is `Detail`, not `Reference`).
- Preserve every state's behavior verbatim — this is a packaging change, not a redesign.

**Acceptance Criteria:**
- [ ] SKILL.md is reduced to frontmatter + pre-flight + state detection + dispatch table (no inline state bodies).
- [ ] Per-state (or per-section / per-step) body extracted to `canonical/skills/aid-discover/references/*.md` files loaded on demand per the convention above.
- [ ] Dispatch table has one row per state with **State / Detail / Worker / Advance** columns (State value in UPPERCASE-with-hyphens per CR6).
- [ ] On state entry, router prints `[State: NAME]` + state-entry heartbeat per FR1.
- [ ] When state completes, router prints `Next: [State: {NEXT}] — run /aid-aid-discover again` and exits (no auto-advance).
- [ ] Worker column points at sub-agent name where state warrants offload, else `inline`.
- [ ] Behavioural parity: running `/aid-aid-discover` before and after on the same workspace produces the same state transitions and outputs.
- [ ] work-002 generator re-renders this skill into all 3 install trees byte-identically.
- [ ] All tests pass before AND after (no behavior change).
- [ ] All §6 quality gates pass.
