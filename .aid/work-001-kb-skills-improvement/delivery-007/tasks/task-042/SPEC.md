# task-042: aid-update-kb thin-router SKILL.md skeleton + state-detection

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-007

**Depends on:** -- (none)

**Scope:**
- f008 Part 2 (FR-27, AC8) -- the **NEW** `canonical/skills/aid-update-kb/SKILL.md` thin-router
  shell only (C8: frontmatter + state-detection + Dispatch table; one step per turn). The
  per-state reference docs are task-043; this task builds the router that points at them.
- **Frontmatter:** `name: aid-update-kb`;
  `allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent` (same grant shape as
  `aid-housekeep` -- edits KB docs in APPLY, runs helpers + `grade.sh` in ANALYZE/REVIEW,
  dispatches the review panel); `argument-hint: "<what changed / what to update in the KB>"`.
- **Prompt pre-flight:** the argument is a free-form prompt (the scoping seed). If no prompt is
  supplied, print the usage line + example and exit (mirror `aid-ask`'s pre-flight):
  `Usage: /aid-update-kb "<what changed / what to update in the KB>"` /
  `Example: /aid-update-kb "work-003 added the content-isolation cornerstone (AID:BEGIN/END boundary)"`.
- **Off-pipeline + run-state:** document that `aid-update-kb` is an optional off-pipeline skill
  (like `aid-housekeep`/`aid-query-kb`) -- NOT in the numbered phase-to-skill pipeline, no phase
  gate references it. Its run-state lives in a transient project-level file under `.aid/.temp/`
  (`UPDATEKB_STATE_<ts>.md`, gitignored, removed at DONE -- the `aid-housekeep` precedent), NOT in
  any work `STATE.md`.
- **State-detection + Dispatch table** routing one `references/state-*.md` per state, matching the
  `aid-housekeep`/`aid-discover` shape exactly:
  `ANALYZE -> APPLY -> REVIEW -> APPROVAL -> DONE` with a FIX loop inside REVIEW. Table maps each
  state to `references/state-analyze.md` / `-apply.md` / `-review.md` / `-approval.md` /
  `-done.md`, its worker, and its advance verb (CHAIN / PAUSE-FOR-USER-ACTION / HALT) per the f008
  SPEC Part 2 state table.
- Reference the f010 boundary (prompt-driven-targeted vs `aid-housekeep` source-driven-global) but
  do NOT draw the contract here (FR-33/FR-34 boundary is delivery-008/f010).
- ASCII-only (C2; sibling consistency).

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-update-kb/SKILL.md` exists as a thin-router (frontmatter +
  state-detection + Dispatch table only -- no per-state behavior bodies; those are task-043).
- [ ] Frontmatter: `name: aid-update-kb`,
  `allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent`, the documented `argument-hint`.
- [ ] No-prompt invocation prints the usage line + example and exits (pre-flight).
- [ ] Run-state is documented as a transient `.aid/.temp/UPDATEKB_STATE_<ts>.md` (gitignored,
  removed at DONE); the skill writes NO work `STATE.md` for its own run-state.
- [ ] The Dispatch table lists exactly `ANALYZE -> APPLY -> REVIEW -> APPROVAL -> DONE` (FIX loop
  inside REVIEW), each row pointing at the correct `references/state-*.md`, worker, and advance
  verb per the f008 Part 2 table.
- [ ] The skill is marked optional / off-pipeline (no phase-gate reference).
- [ ] SKILL.md parses as a valid thin-router and is ASCII-only.
- [ ] All section-6 quality gates pass.
