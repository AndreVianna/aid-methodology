# task-002-update-aid-discover-skill: Update aid-discover SKILL.md

**Type:** IMPLEMENT

**Source:** feature-001-you-are-here-heartbeat (AC1+AC2+AC3+AC4 for GENERATE) + feature-002-state-file-consolidation (SKILL-body state-ref updates) → delivery-001

**Depends on:** task-011

**Scope:**
- Edit `canonical/skills/aid-discover/SKILL.md` to add heartbeat invocations per feature-001 SPEC:
  - **AC1 state-entry print:** at the top of every state in the skill's body, print `[State: NAME] — {one-line description}`. Description sourced from the opening sentence of `references/state-{name}.md` once feature-002-in-work-001 (thin-router) ships; until then, the body author provides the description inline.
  - **AC2 bracket-pair floor:** around every long operation (sub-agent dispatch, validation script, long tool call), print `▶ {op} starting (~{time band})` before and `✓ {op} done in {actual}` after (or `✗ failed: {reason}` on error). Time bands sourced from task-011's rough-time-hints table.
  - **AC3 ASCII state-map render:** immediately after each state-entry print, render an ASCII state-map showing the skill's ordered state sequence with the current state marked.

**SPEC section references** (read these before editing):
  - **AC1** — see feature-001 SPEC `### Feature Flow → Flow A — state-entry print` for the format and render trigger.
  - **AC2** — see feature-001 SPEC `### Feature Flow → Flow C — bracket-pair floor around long operations` for the format, the rough-time-hints contract, and the never-blocks-pipeline invariant.
  - **AC3** — see feature-001 SPEC `### Feature Flow → Flow B — "you are here" state-map render` for the per-skill projection rule, branch-collapse semantics, and degradation behavior.
  - **AC4** — see feature-001 SPEC `### Feature Flow → Flow D — sub-unit drill-down (AC4)` for the qualifying-states table, snapshot format, coalescing rule, and serial-fallback degradation.
- **AC4 sub-unit drill-down for `GENERATE` state** per feature-001 SPEC Flow D. Iteration source: see SPEC's qualifying-states table. 1-second coalescing on re-renders.
- **State-ref updates** (per FR2 area-STATE rule): Update all `DISCOVERY-STATE.md` references in the SKILL body to `.aid/knowledge/STATE.md`. Section pointers: `## KB Documents Status`, `## Review History`, `## Q&A (Pending)`, `## Verification Spot-Checks`, `## Issues`. References inside `references/agent-prompts.md`, `references/document-expectations.md`, `references/reviewer-prompt.md` also need updating (in scope for this task).
- Heartbeat invocations are **additive content** that survives the work-001/feature-002 (thin-router) refactor. Insertion points should be chosen to nest cleanly into per-state `references/state-*.md` files when that refactor lands.
- Per NFR5: no scripts, no helpers, no hooks — pure skill-body text additions only.

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-discover/SKILL.md` contains state-entry prints for every state (AC1).
- [ ] `canonical/skills/aid-discover/SKILL.md` brackets every long operation with `▶/✓` lines (AC2), citing rough-time-hints table from task-011.
- [ ] `canonical/skills/aid-discover/SKILL.md` renders an ASCII state-map on each state transition (AC3).
- [ ] `canonical/skills/aid-discover/SKILL.md` implements AC4 sub-unit drill-down for `GENERATE` per Flow D.
- [ ] All legacy state-file references in this SKILL body are updated to area-STATE per FR2.
- [ ] All §6 quality gates pass

---

## §6 Quality Gates (this task type)

Severities and grade calculation follow `canonical/templates/grading-rubric.md`. Tag findings with bracketed all-caps form ([MINOR], [LOW], [MEDIUM], [HIGH], [CRITICAL]) so `grade.sh` counts them.

- [ ] **§6.1 — Line endings preserved.** Edit uses binary-mode write; the edited file's pre-edit line-ending convention (LF or CRLF) is preserved post-edit.
- [ ] **§6.2 — No orphan refs.** `git grep -nE "DISCOVERY-STATE\.md|SUMMARY-STATE\.md|INTERVIEW-STATE\.md|task-([A-Z]+|[0-9]+[a-z]*|\{[^}]+\})-STATE\.md|DEPLOYMENT-STATE\.md|feature-state\.md|implementation-state\.md"` in the edited SKILL.md returns no matches (except historical references inside `## Change Log` if applicable). Pattern handles all placeholder conventions: `task-NNN-`, `task-001-`, `task-{id}-`.
- [ ] **§6.3 — Generator passes.** `python run_generator.py` runs to completion after the edit; VERIFY-4a `overall_passed: true`.
- [ ] **§6.4 — Heartbeat renders correctly *(manual verification — not automatable)*.** Invoke the edited SKILL in Claude Code (or equivalent host) on the following toy scenario: run aid-discover on a synthetic 5-file project (`/tmp/aid-test-discover-001` containing 1 `.py`, 1 `.md`, 1 `package.json`, 1 `README.md`, 1 `.gitignore`); observe state-entry prints, state-map, and AC4 sub-unit drill-down rendering for the GENERATE state (5-6 parallel discovery sub-agents iterated). Observe in the chat output: a `[State: NAME] — {desc}` line at each state entry; an ASCII state-map block; a matching `▶ … starting (~…)` / `✓ … done in …` pair around the bracketed operation.
