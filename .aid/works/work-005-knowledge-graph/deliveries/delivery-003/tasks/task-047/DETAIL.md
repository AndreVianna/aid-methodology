# task-047: Gap-ledger Status transitions, routing block and exit contract

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

**Source:** work-005-knowledge-graph -> delivery-003

**Depends on:** task-046

**Scope:**
- Extend `canonical/aid/scripts/graph/detect-kb-gaps.mjs` with the three behaviours task-046
  deliberately left out. **No other file is touched by this task.**
- **Status transitions across runs (D5).** When `--previous` names an existing ledger, read it
  **first** (Feature Flow step 2), before anything is emitted, so existing row numbers, severities
  and descriptions are preserved and only `Status` moves. A node still uncovered stays `Pending`; a
  node now covered becomes `Fixed`; a node that was `Fixed` and is uncovered again becomes
  `Recurred`. Nothing is renumbered and no row is deleted -- the schema's append-only rule. An
  absent `--previous`, or a `--previous` path that does not exist, is cycle 1: every row starts
  `Pending`.
- `Accepted`, `OOS` and `Invalid` are **never** written by this script. The schema reserves them for
  the orchestrator acting with user authorization.
- **The routing block (FR-27)**, printed to stdout: the summary line
  (`KB gaps: N (a HIGH, b MEDIUM, c LOW)`, with the `— N with no relationships at all` clause
  **omitted entirely** rather than printed as `0` when that slice is empty); the ledger path marked
  retained, not graded, and the run successful; and the two routes, naming `/aid-update-kb` for the
  targeted case and `/aid-housekeep` for the broad sweep. The `[HIGH]` rows are listed first so the
  suggested `/aid-update-kb` instruction is drawn from the most consequential gap. The script
  invokes neither skill, opens no ticket, and writes nothing into `.aid/knowledge/STATE.md`.
- **The exit contract -- mechanism S2.** Exit `0` unconditionally, whether the run emits zero rows or
  five hundred, following the precedent of `canonical/aid/scripts/summarize/stale-check.sh`. Gap
  count is reported on stdout, never in the exit status. `2` is reserved for a usage/argument error
  only, per `.aid/knowledge/coding-standards.md` § Exit Codes. **No other exit code is defined**,
  because no other outcome exists -- that is what keeps the unconditional 0 honest.
- Out of scope: the ledger's column shape, the severity join and the `kb_gaps` write (task-046); the
  retention carve-out text for `reviewer-ledger-schema.md` -- task-049 drafts it and lands nothing;
  the state body's single unconditional Advance line, mechanism S3 (task-050); the `SKILL.md`
  dispatch row (task-051); the assertions `GL08`, `GL10` and `GL11` (task-053).

**Acceptance Criteria:**
- [ ] Re-running against a previous ledger moves a now-covered row to `Fixed` and a re-broken row to
      `Recurred`, renumbers nothing, and leaves every existing `#`, `Severity` and `Description` cell
      byte-unchanged. (`GL10`, asserted in task-053.)
- [ ] The previous ledger is read **before** any row is emitted, so a crash mid-write cannot lose the
      prior cycle's row numbering.
- [ ] An absent `--previous` flag and a `--previous` path that does not exist both yield cycle-1
      behaviour: every row `Pending`, and no error.
- [ ] A row's `Status` is only ever `Pending`, `Fixed` or `Recurred`; grep of the script finds no
      code path that writes `Accepted`, `OOS` or `Invalid`.
- [ ] `Status` values are written in the exact form `grade.sh` counts, so `grade.sh` over a ledger
      whose rows are all `Fixed` returns `A+`. (`GL11`, asserted in task-053.)
- [ ] The routing block names both `/aid-update-kb` and `/aid-housekeep`, prints the retained ledger
      path with its not-graded status, and lists `[HIGH]` rows first so the suggested
      `/aid-update-kb` instruction is drawn from the highest-severity gap.
- [ ] The "no relationships at all" count reports a **slice of rows already in the ledger** -- every
      one of those nodes has its own row, severity and evidence -- and the clause is omitted entirely
      when the slice is empty.
- [ ] The script invokes no repair skill, opens no ticket, and writes nothing into
      `.aid/knowledge/STATE.md`.
- [ ] Exit status is `0` for a zero-gap run and for a fixture with many gaps alike; `2` is reachable
      only from a usage/argument error; grep of the script finds no third `process.exit` value.
- [ ] `git diff` for this task touches only `canonical/aid/scripts/graph/detect-kb-gaps.mjs`.
- [ ] All existing canonical suites still pass -- `bash tests/run-all.sh` reports no newly red suite.
- [ ] **The named suites land in task-052** (`GL07` -- many gaps yield a non-empty ledger and exit 0)
      **and task-053** (`GL08`, `GL10`, `GL11`), both in
      `tests/canonical/test-graph-gap-ledger.sh`. *This replaces IMPLEMENT's "unit tests for all new
      public methods" default, which has no vehicle here for a Node script outside the
      `tests/canonical/test-*.sh` suites that the one-type-per-task rule forces into separate TEST
      tasks.*
- [ ] The build for this repository is the profile render, and it runs for this delivery in
      **task-055**; this task hand-edits no file under `profiles/`, `.claude/` or `.cursor/`.
- [ ] Quality gate: this task's reviewer ledger grades **A+** under `grade.sh` -- the resolved
      `review.minimum_grade` (`.aid/settings.yml`, and this work's `STATE.md` `minimum_grade: "A+"`)
      -- i.e. zero rows with Status `Pending` or `Recurred`. The code baseline is
      `.aid/knowledge/coding-standards.md` and the gate is `.aid/knowledge/quality-gates.md`;
      REQUIREMENTS.md §6 holds only the six accessibility NFRs and is **not** a code or lint baseline.
