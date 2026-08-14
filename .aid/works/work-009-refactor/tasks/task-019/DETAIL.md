# task-019: Post-refactor behavior-preservation verification and coverage re-bootstrap

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-019/STATE.md` -- this task's mutable cells live
only in the work-root state file's `### Tasks lifecycle` table.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Type:** TEST

**Source:** work-009-refactor -> delivery-001

**Depends on:** task-005, task-010, task-011, task-013, task-015, task-016, task-018

**Scope:**
- The AC-1 / SP-16 oracle's second half: re-run the same suites task-001 baselined, on the
  post-refactor tree, and diff the per-test pass/fail sets --
  `HOME="$(mktemp -d)" bash tests/run-all.sh` and
  `python -m pytest dashboard/reader/tests dashboard/server/tests`, reading each suite's OWN summary
  line (never a grep over stdout, which undercounts on a hang or timeout).
- Adjudicate the diff against the task-001 change-set: the permitted difference is exactly the
  enumerated format-asserting updates. Any other newly-failing test, **and any newly-passing test
  not on that list**, is a regression to be fixed in the owning task's files before this task
  closes.
- Re-bootstrap `tests/coverage-baseline.tsv` (with `tests/coverage-baseline.meta`) rather than
  row-editing it, because the change is corpus-wide; compare the two TSVs with `comm` rather than
  reading the gate's count-deltas, and do not add accept-list rows for a corpus-wide change.
- Dependency-floor check (SP-17): run both reader twins in a clean environment with no third-party
  packages installed and confirm `packages/pypi/pyproject.toml` (`dependencies = []`) and the
  repo-root `package.json` dependency block are unchanged.
- Residual documentation *and consumer* sweep (SP-15), now that the renders exist: search every KB
  doc, skill, template, agent-context file, profile render and dogfood tree **and every operational
  consumer under `dashboard/`** -- `dashboard/scripts/` (the `delete-pipeline.sh` guard and the
  `writeback-state.sh` fork), `dashboard/server/` (`server.mjs`, `server.py`, `reader.mjs`) and
  `dashboard/home.html` -- for `STATE.md` and for the retired markdown section headings, and confirm
  every surviving hit is either the out-of-scope discovery-area ledger (`join(kbDir, ...)`,
  `SKIP_NAMES`) or an explicitly labelled legacy/migration reference, and that none *resolves a path
  to* an in-scope work-tree state file. The `dashboard/` half is searched explicitly because a
  docs-and-renders-only sweep is exactly what let `SPEC.md § L-10` and `§ L-11` go unnoticed in the
  first draft -- none of those files is a doc, a skill, a template or a render.
- Grading half of SP-13: confirm on a real completed review cycle from this delivery that no ledger
  row cites a state file as its `Doc`, and that `canonical/aid/scripts/grade.sh` is byte-unchanged
  against its pre-refactor content.
- No new suite is authored here -- this task runs, compares and adjudicates. Fixes land in the task
  that owns the file.
- NFR-10 (performance budget) stays out: no measured baseline for reader parse time exists and none
  is invented (`SPEC.md § L-12`). Only the structural cost property is checked, and it is checked in
  task-003/task-004.

**Acceptance Criteria:**
- [ ] The post-refactor per-test pass/fail set is recorded from each suite's own summary line and
      diffed against `.aid/works/work-009-refactor/test-baseline-pre-refactor.md` (SP-16).
- [ ] The only differences are entries on the task-001 change-set; every difference is matched to its
      entry, and any unmatched difference -- newly failing OR newly passing -- is fixed in the owning
      task's files and re-verified before this task closes (SP-16).
- [ ] `tests/coverage-baseline.tsv` is re-bootstrapped (not row-edited), the old and new TSVs are
      compared with `comm`, and no accept-list row was added for this corpus-wide change (SP-16).
- [ ] Both reader twins parse state files successfully in a clean environment with no third-party
      package installed; `packages/pypi/pyproject.toml` and the root `package.json` dependency block
      show no diff (SP-17).
- [ ] The residual sweep for `STATE.md` and the retired headings across `.aid/knowledge/`,
      `canonical/`, `profiles/`, `.claude/`, `.cursor/`, `CLAUDE.md`, `AGENTS.md`,
      `dashboard/scripts/`, `dashboard/server/` and `dashboard/home.html` yields only
      out-of-scope-ledger or explicitly-labelled legacy references, each enumerated with its reason,
      and no surviving reference *resolves a path to* an in-scope work-tree state file (SP-15).
- [ ] The two SP-19 consumer-layer properties are confirmed green in this adjudication, not inferred
      from a text search: `tests/canonical/test-delete-pipeline.sh` proves the `Running` guard still
      exits 7 against a converted work (SP-19a), and
      `dashboard/server/tests/test_write_enabled_cross_runtime_parity.py` proves all three
      write-enabled edit surfaces succeed identically in both runtimes (SP-19b). A failure here is
      fixed in the owning task (task-006 / task-020) and re-verified before this task closes.
- [ ] No ledger row from any review cycle in this delivery cites a state file as its `Doc`, and
      `canonical/aid/scripts/grade.sh` is byte-unchanged (SP-13, FR-10d).
- [ ] Every live work under every worktree root still renders in both twins with no `parse_warning`
      after all landings, and this work's own state file is readable and writable (SP-12, SP-18).
- [ ] Any suite that timed out or hung is reported as such, not counted as passing, and re-run with
      an adequate timeout before adjudication (`test-landscape.md`).
- [ ] Findings are reported, not hidden: a residual regression that cannot be fixed inside this
      delivery is escalated as a Q&A entry in the work's `STATE` Cross-phase Q&A rather than
      silently accepted.
- [ ] All section-6 quality gates pass.
