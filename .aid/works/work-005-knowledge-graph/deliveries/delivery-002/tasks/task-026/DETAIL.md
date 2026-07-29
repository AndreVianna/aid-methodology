# task-026: `graph-preflight.sh` checks P1-P6

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** task-007

**Scope:**

- Create `canonical/aid/scripts/graph/graph-preflight.sh`, the script the PREFLIGHT state runs
  before any other state. It follows `canonical/aid/scripts/summarize/summarize-preflight.sh`'s
  shape: an `err()` helper printing a cause line plus an actionable `->` line, then a non-zero
  exit.
- Implement all six checks of feature-010's PREFLIGHT table, each with the failure message that
  table names:
  - **P1** -- `.aid/knowledge/STATE.md` exists; message directs the user to run `/aid-config`
    then `/aid-discover`.
  - **P2** -- the KB is approved (FR-8). **Read the frontmatter scalar `kb_status` from the
    leading YAML block first**; `Approved` passes. Only when that key is absent, fall back to
    the blockquoted metadata line `> **User Approved:** yes` **scoped to the region above the
    first `##` heading**. Message: run `/aid-discover` to APPROVAL and approve the KB.
  - **P3** -- at least one populated KB document exists: a `.aid/knowledge/*.md` other than
    `STATE.md` / `README.md` / `INDEX.md`, with more than 30 non-blank lines and no
    `^❌ Pending` marker. Message: run `/aid-discover` to populate the KB.
  - **P4** -- not in Plan Mode (`CLAUDE_PLAN_MODE` is not `1`), because the run writes files.
    Message: exit Plan Mode and re-run.
  - **P5** -- Node.js **>= 20** (C-5). Message: install or upgrade Node.js and re-run.
  - **P6** -- `.aid/knowledge/external-sources.md` exists, as a declared FR-11 staleness input
    and an AC-1 resolution target. Message: run `/aid-discover` (its ELICIT state authors it).
- The P2 scoping is a deliberate correctness fix over `summarize-preflight.sh`, which greps the
  whole file and therefore passes when this repository's `.aid/knowledge/STATE.md` carries the
  literal `**User Approved:** yes` a second time inside `## Knowledge Summary Status` (the
  *summary's* approval). Implement the scalar-first, scoped-fallback read so that case is
  refused. **Do not "fix" `summarize-preflight.sh`** -- feature-010 records that defect as
  reported upstream and explicitly out of this work's scope.
- P5's floor of 20 is the floor its sibling already enforces after the on-branch fix
  (`summarize-preflight.sh` Check 5 guards `-lt 20`); this task adopts it, it does not raise it.
- Exit codes: `0` pass, `1` a prerequisite failed, `2` usage -- the contract feature-010's script
  table fixes.
- Standard script conventions from `.aid/knowledge/coding-standards.md`:
  `#!/usr/bin/env bash`, `set -euo pipefail`, a Purpose / Usage / Exit-codes header block with
  `-h|--help` re-printing a slice of it, and the
  `while [[ $# -gt 0 ]]; do case "$1" in … esac done` argument loop with unknown flag -> stderr +
  exit 2.
- Out of scope: the KB write fence (task-028), the staleness digest (task-027), the rubric
  orchestrator (task-029), `references/state-preflight.md`'s body (task-030), the `SKILL.md`
  Pre-flight section (task-007), and the refusal suite (task-040).
- Authored in `canonical/` only; no rendered copy is hand-written (C-2).

**Acceptance Criteria:**

- [ ] `canonical/aid/scripts/graph/graph-preflight.sh` exists, is executable-shaped
      (`#!/usr/bin/env bash`, `set -euo pipefail`), and carries the Purpose / Usage / Exit-codes
      header with a working `-h|--help`.
- [ ] All six checks P1-P6 are implemented and each failure prints a cause line plus an
      actionable `->` line naming the remediation feature-010's PREFLIGHT table specifies.
- [ ] P2 reads the frontmatter scalar `kb_status` from the leading YAML block first and only
      falls back to `> **User Approved:** yes` when that key is absent; the fallback match is
      scoped to the region above the first `##` heading, so a `## Knowledge Summary Status`
      approval cannot satisfy it.
- [ ] P3's populated-document predicate is exactly: a depth-1 `.aid/knowledge/*.md` other than
      `STATE.md` / `README.md` / `INDEX.md`, with more than 30 non-blank lines and no
      `^❌ Pending` marker.
- [ ] P5 fails on a reported Node major version below 20 and passes at 20 or above.
- [ ] Exit code is `0` when every check passes, `1` when any prerequisite fails, `2` on a usage
      error (unknown flag).
- [ ] `canonical/aid/scripts/summarize/summarize-preflight.sh` is not modified by this task.
- [ ] Settings, if read at all, are read only through `read-setting.sh` -- never a hand-parse of
      `settings.yml` (`module-map.md` Invariants).
- [ ] No rendered copy is hand-authored under `profiles/`, `.claude/`, `.cursor/`, `.codex/`,
      `.agent/` or `.github/aid/`.
- [ ] All existing canonical suites still pass: `HOME="$(mktemp -d)" bash tests/run-all.sh`.
- [ ] **IMPLEMENT's "unit tests for all new public methods" is overridden**: the one-type-per-task
      rule puts the suite in its own task. The named suite is **task-040**
      (`tests/canonical/test-graph-preflight.sh`).
- [ ] Build passes: the FULL `run_generator.py` render for this delivery is **task-044**.
- [ ] Code baseline per `.aid/knowledge/coding-standards.md`; the delivery gate reaches this
      repository's resolved `minimum_grade` of **A+** (`review.minimum_grade` in
      `.aid/settings.yml`), i.e. zero ledger rows with Status `Pending` or `Recurred`.
      REQUIREMENTS.md section 6 holds only the six accessibility NFRs and is not a code baseline.
