# task-054: `test-graph-view-shell.sh` GV01 module boundary-rule assertions

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

**Source:** work-005-knowledge-graph -> delivery-003

**Depends on:** task-045

**Scope:**
- Create `tests/canonical/test-graph-view-shell.sh` -- feature-007's suite -- and seed it with
  **`GV01` only**.
- **Why it is seeded here, in delivery-003:** the module exists here but the view does not.
  `GV02`, `GV04` and `GV08` assert against a generated `graph.html` and the rendered `profiles/`
  copies, and `GV03`, `GV05`, `GV06` and `GV07` assert against `graph-model.js` and the view's
  runtime behaviour -- none of which exists until delivery-004. Those land in tasks 070 and 071.
  What delivery-003 can and must assert is `GV01`'s greppable boundary rules.
- `GV01`'s module half, over `canonical/aid/scripts/graph/coverage-predicate.mjs` -- feature-007's
  boundary **rules 1, 2, 3 and 5**: no `import` and no `require`; no `node:` specifier; no
  `document`, `window` or `globalThis`; no `canonical/` substring; none of the three filename
  placeholders (`{project_context_file}`, `{reviewer_output_file}`, `{open_questions_file}`) -- each
  checked in code **and** in comments, because `rewrite_install_paths`' comment-skip test
  (`line.lstrip().startswith("#")`) does not protect a JavaScript `//` or `/* */` comment; and only
  top-level `export function` / `export const` declarations, with no `export {}` list and no default
  export.
- `GV01`'s second half -- "the view's `.js` files contain no top-level `import`" -- has **no subject
  in delivery-003**: `graph-model.js`, `graph-controls.js`, `graph-table.js` and `graph-canvas.js`
  do not exist until delivery-004 and delivery-005. Write it to iterate whatever of the
  `canonical/aid/templates/knowledge-graph/` `.js` set is present, so the check is inert now and
  becomes live as those files land, rather than being written twice.
- The suite is discovered by the `tests/canonical/test-*.sh` glob with no edit to `tests/run-all.sh`.
  `tests/` sits outside `canonical/` and is never rendered, so the suite may name `canonical/...`
  paths freely -- rule 5 binds the module, not the test.
- Leave the file structured so tasks 070 and 071 append `GV02`-`GV08` without restructuring it, and
  so `GV01` does not need to move.
- Out of scope: `GV02`-`GV05` (task-070) and `GV06`-`GV08` (task-071), both in delivery-004 -- in
  particular `GV04`'s `COVERAGE_BEARING`-equals-the-recorded-subset check, which the delivery-003
  BLUEPRINT places in delivery-004 alongside `GV02` and `GV08`; `GL12`'s bare-Node import, which
  lives in the gap-ledger suite (task-052); the `test-graph-gap-ledger.sh` assertions generally
  (tasks 052 and 053).

**Acceptance Criteria:**
- [ ] `tests/canonical/test-graph-view-shell.sh` exists and is discovered by `bash tests/run-all.sh`
      with no edit to the runner.
- [ ] `GV01` asserts over `canonical/aid/scripts/graph/coverage-predicate.mjs`: no `import`, no
      `require`, no `node:` specifier, no `document`, no `window`, no `globalThis`, no `canonical/`
      substring, and none of the three filename placeholders.
- [ ] Each of those checks is applied to the whole file -- code **and** comments -- not only to
      non-comment lines.
- [ ] `GV01` asserts that every top-level declaration is `export function` or `export const`, and
      that no `export {}` list and no default export appears.
- [ ] Each of the four checked boundary rules (1, 2, 3, 5) is a **separately reported** assertion, so
      a failure names which rule broke rather than reporting one composite failure.
- [ ] A negative check proves the assertions bite rather than passing vacuously: a temporary copy of
      the module with a deliberately injected `import`, and a second with a `canonical/...` path
      injected **into a comment**, are each rejected.
- [ ] The view-`.js` half of `GV01` iterates whatever of the
      `canonical/aid/templates/knowledge-graph/` `.js` set exists and is inert while that set is
      empty, so it needs no rewrite when delivery-004 lands those files.
- [ ] A comment in the suite records that `GV02`-`GV08` land in delivery-004 tasks 070 and 071, and
      why they cannot run here -- the module exists in delivery-003 but the view does not.
- [ ] Tests are deterministic with clean setup and teardown, including on failure (TEST defaults);
      any temporary copy made for the negative check is removed.
- [ ] Source-feature coverage stated honestly (TEST default): this suite covers `GV01` only. AC-6,
      AC-7, AC-8, AC-10 and the view side of AC-15 -- the criteria feature-007 owns -- are **not**
      closed by this task, and the suite says so.
- [ ] Quality gate: this task's reviewer ledger grades **A+** under `grade.sh` -- the resolved
      `review.minimum_grade` (`.aid/settings.yml`, and this work's `STATE.md` `minimum_grade: "A+"`)
      -- i.e. zero rows with Status `Pending` or `Recurred`. The code baseline is
      `.aid/knowledge/coding-standards.md` and the gate is `.aid/knowledge/quality-gates.md`;
      REQUIREMENTS.md §6 holds only the six accessibility NFRs and is **not** a code or lint baseline.
