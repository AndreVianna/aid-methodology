# task-005: Refactor aid-interview to thin-router

**Type:** REFACTOR

**Source:** feature-002-skill-footprint-refactor → delivery-001

**Depends on:** —

**Scope:**
- Extract each `## Mode: NAME` H2 block in `canonical/skills/aid-interview/SKILL.md` into a separate `references/state-{name}.md` file (lowercase, hyphenated).
- Reduce `canonical/skills/aid-interview/SKILL.md` to: frontmatter + Title + opening paragraph + `## ⚠️ Pre-flight Checks` + `## State Detection` + `## Dispatch` table.
- Dispatch table: one row per state with columns State / Reference / Worker / Advance.
- Preserve every state's behavior verbatim — this is a packaging change, not a redesign.
- Note: leaves a clear insertion point for delivery-002's State TRIAGE between State 1 and State 2.

**Acceptance Criteria:**
- [ ] SKILL.md is reduced to frontmatter + pre-flight + state detection + dispatch table (no inline state bodies).
- [ ] Each prior `## Mode: NAME` H2 block extracted to `canonical/skills/aid-{skill}/references/state-{name}.md`.
- [ ] Dispatch table has one row per state with State (UPPERCASE-with-hyphens per CR6) / Reference / Worker / Advance columns.
- [ ] On state entry, router prints `[State: NAME]` + state-entry heartbeat per FR1.
- [ ] When state completes, router prints `Next: [State: {NEXT}] — run /aid-{skill} again` and exits (no auto-advance).
- [ ] Worker column points at sub-agent name where state warrants offload, else `inline`.
- [ ] Behavioural parity: running `/aid-{skill}` before and after on the same workspace produces the same state transitions and outputs.
- [ ] work-002 generator re-renders this skill into all 3 install trees byte-identically.
- [ ] All §6 quality gates pass.
