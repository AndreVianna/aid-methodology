# task-011: connector-secret twin behavior and AC-3 leak-proof sweep tests

**Type:** TEST

**Source:** work-002-external_sources -> delivery-001

**Depends on:** task-006

**Scope:**
- Deterministic shell/PowerShell tests for the task-006 twin: `write` stores exact bytes and records only the `file:` reference; no-echo (value never on stdout/console); path-confinement rejects separators / `..`; `purge` is idempotent; `write` fails-closed when the ignore precondition is unmet.
- AC-3 leak-proof sweep: after `write`, grep repo + `.aid/knowledge/` (KB) + every `STATE.md` + the session transcript for the registered value and assert nothing is found; the value exists only under `.aid/connectors/.secrets/<stem>`.

**Acceptance Criteria:**
- [ ] Tests are deterministic with clean setup/teardown (temp registry fixture; no reliance on developer state)
- [ ] AC-3 sweep proves the registered secret value appears nowhere in repo / KB / STATE / transcript — only in the local git-ignored store
- [ ] Covers the source-feature ACs: reference-not-value, no-echo / no-persist, path-confinement, idempotent purge, fail-closed
- [ ] Cross-platform intent honored — Bash + PowerShell paths exercised where the lane allows (AC-8)
- [ ] All §6 quality gates pass
