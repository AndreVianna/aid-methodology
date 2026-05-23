# task-007b-update-aid-execute-skill-ac4-drilldown: Update aid-execute SKILL.md — AC4 sub-unit drill-down for EXECUTE-WAVE

**Type:** IMPLEMENT

**Critical path:** Yes — this task gates downstream nodes in `delivery-001`'s execution graph; delays here delay task-012 verification.

**Source:** feature-001-you-are-here-heartbeat (AC4 for EXECUTE-WAVE) → delivery-001

**Depends on:** task-007a

**Scope:**
- Build on task-007a's base implementation by adding **AC4 sub-unit drill-down for `EXECUTE-WAVE` state** per feature-001 SPEC `### Feature Flow → Flow D — sub-unit drill-down (AC4)` (qualifying-states table, snapshot format, coalescing rule, serial-fallback degradation).
- **Iteration source:** the work `STATE.md` `## Tasks Status` table — already in place per FR2 (work-002+CW3-CW6).
- **Display:** when in EXECUTE-WAVE state, render a sub-unit snapshot block immediately after the AC3 state-map showing each task in the current wave with status icon (✓ done / ● running / ✗ failed / (blank) queued), task name, and elapsed/expected time. Iteration header line: `Wave {M} of {N} · {K}/{T} done`.
- **Re-render trigger:** on every sub-unit transition (queued → running → done / failed). **1-second coalescing** — multiple transitions in the same second emit one snapshot.
- **Serial-task fallback** (until work-001/feature-009 parallel execution ships): shows 1 task in flight at a time as the wave runs serially. Documented degradation per SPEC Migration Plan §1 "AC4 phasing"; not a bug.
- **Render placement:** fresh block each tick (no in-place edit); reader sees most recent snapshot by scrolling to bottom.
- **Never blocks the pipeline:** snapshot render failure (malformed iteration source, etc.) is swallowed and never aborts execution.

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-execute/SKILL.md` implements AC4 sub-unit drill-down for EXECUTE-WAVE per Flow D.
- [ ] Snapshot re-renders on every sub-unit transition with 1-second coalescing.
- [ ] Serial-task fallback documented in the SKILL body (per-skill comment explaining the two-phase rollout with work-001/feature-009).
- [ ] Snapshot render failure is swallowed (try/except equivalent in the skill body's instruction language) and never aborts the skill.
- [ ] Sub-unit drill-down renders correctly on a toy 3-task wave (manual verification — observe queued → running → done transitions snapshotted).
- [ ] All §6 quality gates pass

---

## §6 Quality Gates (this task type)

Severities and grade calculation follow `canonical/templates/grading-rubric.md`. Tag findings with bracketed all-caps form ([MINOR], [LOW], [MEDIUM], [HIGH], [CRITICAL]) so `grade.sh` counts them.

- [ ] **§6.1 — Line endings preserved.** Edit uses binary-mode write; the edited file's pre-edit line-ending convention (LF or CRLF) is preserved post-edit.
- [ ] **§6.2 — No orphan refs.** `git grep -nE "DISCOVERY-STATE\.md|SUMMARY-STATE\.md|INTERVIEW-STATE\.md|task-([A-Z]+|[0-9]+[a-z]*|\{[^}]+\})-STATE\.md|DEPLOYMENT-STATE\.md|feature-state\.md|implementation-state\.md"` in the edited SKILL.md returns no matches (except historical references inside `## Change Log` if applicable). Pattern handles all placeholder conventions: `task-NNN-`, `task-001-`, `task-{id}-`.
- [ ] **§6.3 — Generator passes.** `python run_generator.py` runs to completion after the edit; VERIFY-4a `overall_passed: true`.
- [ ] **§6.4 — Heartbeat renders correctly *(manual verification — not automatable)*.** Invoke the edited SKILL in Claude Code (or equivalent host) on the following toy scenario: re-run the same 3-task synthetic delivery from task-007a; observe AC4 sub-unit drill-down rendering during EXECUTE-WAVE — serial-task fallback (1 task in flight at a time) shows queued → running → done transitions for each of the 3 tasks with 1-second coalescing. Observe in the chat output: a `[State: NAME] — {desc}` line at each state entry; an ASCII state-map block; a matching `▶ … starting (~…)` / `✓ … done in …` pair around the bracketed operation.
