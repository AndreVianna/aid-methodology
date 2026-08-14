# task-005: Shared cross-runtime YAML-subset conformance corpus

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-005/STATE.md` -- this task's mutable cells live
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

**Depends on:** task-003, task-004

**Scope:**
- The parity surface reduced to data (`SPEC.md § L-4`, enforcement leg 2): one committed corpus
  directory of small `.yml` inputs, each paired with its expected parse result, under
  `tests/canonical/fixtures/state-yaml-conformance/` (the repo's committed-fixture convention,
  alongside `tests/canonical/fixtures/migrate/`). A shared corpus must be ONE on-disk artifact
  both runtimes read -- building it inline twice would recreate exactly the divergence it exists to
  catch.
- Corpus coverage, one input per row: each permitted shape S1-S5; each of the three D-5 quoting
  modes including a value carrying `|`, a newline, a colon, a `#` and a quote; each
  implicit-typing deny-list literal (`y`/`Y`/`yes`/`Yes`/`YES`/`n`/`N`/`no`/`No`/`NO`/`true`/
  `True`/`TRUE`/`false`/`False`/`FALSE`/`on`/`On`/`ON`/`off`/`Off`/`OFF`/`null`/`Null`/`NULL`/`~`,
  the empty string, a number-looking value, an ISO date and an ISO date-time); each rejected
  construct from `SPEC.md § D-3` (tab indentation, a flow collection other than literal `[]`/`{}`,
  a block scalar with each chomping suffix, an anchor, an alias, a tag, a directive, a second
  document, odd indentation, over-deep nesting, a line with no `key:` separator, a duplicate key,
  a byte-order mark); an empty `[]` and `{}` versus an absent key.
- Two runners over the SAME corpus: `dashboard/reader/tests/test_state_yaml_conformance.py`
  (Python twin) and a Node-twin runner in the shape the existing cross-runtime suites already use
  -- `dashboard/reader/tests/test_flattened_layout_parity.py` invokes `reader.mjs` via
  `subprocess`; follow that precedent rather than inventing a harness.
- Each row asserts BOTH the parsed value set AND the emitted `parse_warning` set, so a divergence
  is a failing row rather than a silent field difference.
- OUT of this task: the payload-level cross-format comparison over a work-tree fixture (task-011),
  and edits to any existing suite (task-016).

**Acceptance Criteria:**
- [ ] The corpus exists at `tests/canonical/fixtures/state-yaml-conformance/` with one input file
      per shape, per quoting mode, per implicit-typing literal and per rejected construct
      enumerated in Scope, each paired with its expected values and expected warning set (SP-1).
- [ ] Both runners read the SAME corpus directory -- no second copy, no runtime-specific fixture --
      and each row's expectation file is the single source both compare against (SP-1, NFR-1).
- [ ] For every permitted-shape row both twins produce identical values and an empty warning set.
- [ ] For every rejected-construct row both twins produce the identical `parse_warning`, skip
      exactly that key, keep parsing the rest of the file, and raise no exception in either runtime
      (SP-1).
- [ ] For every implicit-typing row the parsed value is the string on disk in both runtimes -- the
      PyYAML-1.1 / js-yaml-1.2 `yes`/`no` divergence recorded at
      `dashboard/reader/state_schema.py:229-239` cannot reproduce (NFR-2).
- [ ] An absent key and an empty `[]`/`{}` collection are treated identically by both twins (D-3).
- [ ] Both runners are deterministic, need no network, clean up their temp state, and run under
      `python -m pytest dashboard/reader/tests dashboard/server/tests` with no third-party package
      installed (SP-17, `task-type-rules.md § TEST`).
- [ ] A first-run failure is reported as a finding, not hidden; if a row fails, the defect is fixed
      in task-003/task-004's files and the fix is named in this task's commit message.
- [ ] All section-6 quality gates pass.
