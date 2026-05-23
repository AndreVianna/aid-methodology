# task-009-update-aid-monitor-skill: Update aid-monitor SKILL.md

**Type:** IMPLEMENT

**Source:** feature-001-you-are-here-heartbeat (AC1+AC2+AC3) + feature-002-state-file-consolidation (SKILL-body state-ref updates) → delivery-001

**Depends on:** task-011

**Scope:**
- Edit `canonical/skills/aid-monitor/SKILL.md` to add heartbeat invocations per feature-001 SPEC:
  - **AC1 state-entry print:** at the top of every state in the skill's body, print `[State: NAME] — {one-line description}`. Description sourced from the opening sentence of `references/state-{name}.md` once feature-002-in-work-001 (thin-router) ships; until then, the body author provides the description inline.
  - **AC2 bracket-pair floor:** around every long operation (sub-agent dispatch, validation script, long tool call), print `▶ {op} starting (~{time band})` before and `✓ {op} done in {actual}` after (or `✗ failed: {reason}` on error). Time bands sourced from task-011's rough-time-hints table.
  - **AC3 ASCII state-map render:** immediately after each state-entry print, render an ASCII state-map showing the skill's ordered state sequence with the current state marked.

**SPEC section references** (read these before editing):
  - **AC1** — see feature-001 SPEC `### Feature Flow → Flow A — state-entry print` for the format and render trigger.
  - **AC2** — see feature-001 SPEC `### Feature Flow → Flow C — bracket-pair floor around long operations` for the format, the rough-time-hints contract, and the never-blocks-pipeline invariant.
  - **AC3** — see feature-001 SPEC `### Feature Flow → Flow B — "you are here" state-map render` for the per-skill projection rule, branch-collapse semantics, and degradation behavior.
- **State-ref updates** (per FR2 area-STATE rule): Monitor area STATE is deferred per FR2 OQ-3 resolution (wait until Monitor matures). Do NOT introduce actual `.aid/work-NNN/MONITOR-STATE.md` references in the SKILL body; instead, **immediately after the `## Pre-flight Checks` section** (or before `## Step 1` / `## State Detection`, whichever comes first in the body), add this comment block: `<!-- NOTE (FR2 area-STATE rule, work-003-traceability/feature-002 OQ-3 resolution): The Monitor area STATE is deferred until the area matures. When authored, MONITOR-STATE.md follows the area-STATE pattern documented at canonical/templates/work-state-template.md (per-work) and .aid/knowledge/data-model.md §1A. -->`. No new STATE.md writes in this task.
- Heartbeat invocations are **additive content** that survives the work-001/feature-002 (thin-router) refactor. Insertion points should be chosen to nest cleanly into per-state `references/state-*.md` files when that refactor lands.
- Per NFR5: no scripts, no helpers, no hooks — pure skill-body text additions only.

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-monitor/SKILL.md` contains state-entry prints for every state (AC1).
- [ ] `canonical/skills/aid-monitor/SKILL.md` brackets every long operation with `▶/✓` lines (AC2), citing rough-time-hints table from task-011.
- [ ] `canonical/skills/aid-monitor/SKILL.md` renders an ASCII state-map on each state transition (AC3).
- [ ] All legacy state-file references in this SKILL body are updated to area-STATE per FR2.
- [ ] All §6 quality gates pass

---

## §6 Quality Gates (this task type)

Severities and grade calculation follow `canonical/templates/grading-rubric.md`. Tag findings with bracketed all-caps form ([MINOR], [LOW], [MEDIUM], [HIGH], [CRITICAL]) so `grade.sh` counts them.

- [ ] **§6.1 — Line endings preserved.** Edit uses binary-mode write; the edited file's pre-edit line-ending convention (LF or CRLF) is preserved post-edit.
- [ ] **§6.2 — No orphan refs.** `git grep -nE "DISCOVERY-STATE\.md|SUMMARY-STATE\.md|INTERVIEW-STATE\.md|task-([A-Z]+|[0-9]+[a-z]*|\{[^}]+\})-STATE\.md|DEPLOYMENT-STATE\.md|feature-state\.md|implementation-state\.md"` in the edited SKILL.md returns no matches (except historical references inside `## Change Log` if applicable). Pattern handles all placeholder conventions: `task-NNN-`, `task-001-`, `task-{id}-`.
- [ ] **§6.3 — Generator passes.** `python run_generator.py` runs to completion after the edit; VERIFY-4a `overall_passed: true`.
- [ ] **§6.4 — Heartbeat renders correctly *(manual verification — not automatable)*.** Invoke the edited SKILL in Claude Code (or equivalent host) on the following toy scenario: (no end-to-end scenario — Monitor area is deferred per FR2 OQ-3 resolution); minimal verification: invoking aid-monitor produces state-entry prints + state-map for whatever pre-flight states the SKILL defines, without writing to a MONITOR-STATE.md file. Observe in the chat output: a `[State: NAME] — {desc}` line at each state entry; an ASCII state-map block; a matching `▶ … starting (~…)` / `✓ … done in …` pair around the bracketed operation.
