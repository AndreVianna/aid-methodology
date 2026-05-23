# task-012-end-to-end-verification: End-to-end verification + dogfood smoke test

**Type:** TEST

**Source:** feature-001-you-are-here-heartbeat (AC1+AC2+AC3+AC4) + feature-002-state-file-consolidation (SKILL-body sweep) → delivery-001

**Depends on:** task-001, task-002, task-003, task-004, task-005, task-006, task-007a, task-007b, task-008, task-009, task-010

**Scope:**
- Run `python run_generator.py` clean against canonical/ → expect VERIFY-4a PASS, VERIFY-4b skipped=8 (vendor URLs pending fetch).
- Install trees regenerated; each SKILL body now carries heartbeat invocations.
- `setup.sh` smoke-installs the Claude Code profile into a fresh tmp directory (e.g., `/c/tmp/aid-test-delivery-001`) without prompts; install includes heartbeat-bearing SKILLs.
- **Spot-render heartbeat output** for 3 sample skills on toy scenarios:
  - **aid-discover** invoked on a tiny mock project (1–2 files) — observe state-entry, state-map, and AC4 sub-unit drill-down for the GENERATE state showing the 5–6 parallel discovery sub-agents.
  - **aid-execute** invoked on a 3-task synthetic delivery — observe state-entry, state-map, AC4 sub-unit drill-down for EXECUTE-WAVE with serial-task fallback (shows 1 task in flight at a time pre-feature-009).
  - **aid-summarize** invoked on the existing `.aid/knowledge/` — observe state-entry, state-map, bracket-pair around the long mermaid validation step.
- **Grep sweep across canonical/skills/** for orphan references to retired state names: `DISCOVERY-STATE.md`, `SUMMARY-STATE.md`, `INTERVIEW-STATE.md`, `task-NNN-STATE.md`, `DEPLOYMENT-STATE.md`, `feature-state.md`, `implementation-state.md`. Allowed locations: SKILL `## Change Log` sections (historical mention OK); SPEC bodies in `.aid/work-*/features/*/SPEC.md` (out of scope for this task; documented as residual historical references).
- Document any findings or known gaps in the work-003 STATE.md `## Lifecycle History` row for this task.

**Acceptance Criteria:**
- [ ] VERIFY-4a `overall_passed: true`.
- [ ] `setup.sh` installs Claude Code profile cleanly into a tmp directory (~114 files; matches earlier work-002 baseline).
- [ ] Spot-render verification confirmed for aid-discover (AC4 GENERATE drill-down visible), aid-execute (AC4 EXECUTE-WAVE serial fallback visible), aid-summarize (AC1+AC2+AC3 visible).
- [ ] Grep sweep finds zero orphan references to retired state names in `canonical/skills/` (Change Log mentions excluded).
- [ ] All §6 quality gates pass

---

## §6 Quality Gates (this task type)

Severities and grade calculation follow `canonical/templates/grading-rubric.md`. Tag findings with bracketed all-caps form so `grade.sh` counts them.

- [ ] **§6.1 — Generator clean.** `python run_generator.py` runs to completion; VERIFY-4a `overall_passed: true`; VERIFY-4b advisory skip-count = 8 (vendor URLs pending fetch — expected).
- [ ] **§6.2 — Installer smoke.** `setup.sh` installs the Claude Code profile into a fresh tmp directory without prompts; install includes the heartbeat-bearing SKILL bodies.
- [ ] **§6.3 — Heartbeat visibly renders *(manual verification — not automatable)*.** Three sample SKILLs invoked on toy scenarios per their per-task §6.4 specifications: aid-discover (AC4 GENERATE drill-down), aid-execute (AC4 EXECUTE-WAVE serial-fallback drill-down), aid-summarize (AC1+AC2+AC3 only). Each produces the expected state-entry line, state-map, and bracket-pair output.
- [ ] **§6.4 — No orphan refs across all canonical.** `git grep -nE "DISCOVERY-STATE\.md|SUMMARY-STATE\.md|INTERVIEW-STATE\.md|task-([A-Z]+|[0-9]+[a-z]*|\{[^}]+\})-STATE\.md|DEPLOYMENT-STATE\.md|feature-state\.md|implementation-state\.md" canonical/skills/` returns no matches (Change Log mentions in `## Change Log` sections allowed).
