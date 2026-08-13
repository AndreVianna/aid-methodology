# task-008: Delete-prep and remove the 20 internal READMEs

> **Execution protocol:** whoever executes this task writes its `State` at every
> transition (`In Progress` at start, `In Review` before the reviewer, terminal
> `Done`/`Failed` at end) in this task's `STATE.md`. Binds the main agent executing
> directly, not only a dispatched sub-agent.

**Type:** IMPLEMENT

**Source:** work-004-frontmatter-review-criteria -> delivery-002

**Depends on:** -- (none within delivery-002; delivery-001 must be complete)

**Scope:**
- **Prep before deletion:**
  - Relocate the `aid-clerk` caller contract from `canonical/agents/aid-clerk/README.md` into
    `canonical/agents/aid-clerk/AGENT.md` (which ships); fix the pointer at
    `canonical/skills/aid-execute/references/state-execute.md` line 166 to reference `AGENT.md`.
  - Remove **all three** `MONITOR_README` assertions in `tests/canonical/test-deploy-monitor-repurpose.sh`
    (`DMR00c`, `DMR03c`, `DMR03d`); first confirm the `BUG`→`/aid-fix` / `Change Request`→`/aid-triage`
    routing the two `DMR03*` check is stated in a shipping file (`aid-monitor/SKILL.md`).
- **Delete** the 20 internal READMEs: `canonical/skills/*/README.md` (11) + `canonical/agents/*/README.md`
  (9), including the two prepped ones.
- Delete **before** any per-file declaration is authored (task-009/010).

**Acceptance Criteria:**
- [ ] The `aid-clerk` caller contract lives in `AGENT.md`; the `state-execute.md` pointer resolves to a
      shipping path; no dangling reference to a deleted README remains in any shipping file.
- [ ] All 3 `MONITOR_README` assertions are removed and the monitor routing survives in `SKILL.md`.
- [ ] All 20 internal READMEs are gone (`find canonical/skills canonical/agents -name README.md` = 0).
- [ ] The `aid-execute.flow.json` sidecar is left for delivery-003's render (not hand-edited).
- [ ] All §6 quality gates pass.
