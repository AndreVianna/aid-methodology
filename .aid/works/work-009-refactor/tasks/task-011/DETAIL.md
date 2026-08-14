# task-011: Cross-format, cross-runtime characterization suite

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-011/STATE.md` -- this task's mutable cells live
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

**Depends on:** task-008

**Scope:**
- The AC-2 oracle in its **golden-master** form (`SPEC.md § SP-8`, `§ L-9`) -- *not* a live
  four-way comparison. A live "legacy read vs converted read" equality is unsatisfiable by
  construction: task-003/task-004 delete the markdown state parsers, so a post-refactor read of a
  legacy `STATE.md` returns the minimal model plus a `parse_warning` (it is diagnosed, not parsed)
  and can never be field-equal to a converted read. Three legs, and which BUILD reads which tree
  is part of the specification:
  - **(a) Record the baseline against the PRE-refactor readers.** Build the legacy-markdown
    fixture work tree, read it with the pre-refactor `dashboard/reader` (Python) and
    `dashboard/server/reader.mjs` (Node), assert the two payloads are equal on every rendered
    field with no `parse_warning`, and commit that payload as the golden baseline fixture.
    Because this task runs after task-003/task-004, the pre-refactor parser code is obtained by
    materializing the pre-refactor revision in a scratch checkout (`git worktree add` /
    `git show` into a temp dir) as a **one-time authoring step of this task**. The committed suite
    must never resolve repo git history at run time -- CI clones shallowly, and a history-reading
    test fails there.
  - **(b) Compare the conversion against the POST-refactor readers.** Run the task-008 converter
    over the same fixture tree, read the result with both post-refactor twins, and assert each
    payload equals the committed golden baseline on every field enumerated below, with no
    `parse_warning` from either.
  - **(c) Assert the legacy read degrades identically.** Read the *unconverted* legacy tree with
    both post-refactor twins and assert the minimal-model degradation plus the same
    `parse_warning` naming the file and the migration command in both runtimes. This is the
    required behavior (SP-9, AC-5), asserted explicitly -- not a shortfall of (b).
- Home: the existing cross-runtime parity suite family, whose
  `dashboard/reader/tests/test_flattened_layout_parity.py` already builds a flat-layout fixture and
  asserts `reader.py` and `reader.mjs` "read the SAME fixture identically". Extend that shape;
  reuse its self-contained fixture-builder and `subprocess` Node invocation rather than a new
  harness.
- Both layouts covered: flat via the `test_flattened_layout_parity.py` fixture shape, full via the
  hierarchical fixture shape of `dashboard/reader/tests/test_task014_fixtures.py`.
- Compared fields, at minimum: lifecycle, phase, active skill, updated, delivery state, gate
  tier/grade/timestamp, per-task state/review/elapsed/notes/display-name, lifecycle-history rows,
  Q&A entries, and the derived counts and percentages.
- Fixtures and the golden baseline are self-contained test assets -- no work folder's contents are
  an input (a work folder is transient, `C-6`), and no live work tree is read.
- OUT of this task: the subset/reject-list corpus (task-005); edits to existing suites (task-016);
  `test-migrate-hierarchy.sh` and `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/`
  (both triaged OUT and left untouched).

**Acceptance Criteria:**
- [ ] The golden baseline exists as a committed fixture payload, produced by the **pre-refactor**
      Python and Node readers over the legacy-markdown fixture tree, with those two payloads
      recorded as equal on every field enumerated in Scope and neither raising a `parse_warning`
      (SP-8 leg a).
- [ ] For the flat fixture, both **post-refactor** twins' reads of the converted tree equal the
      committed golden baseline on every field enumerated in Scope, with no `parse_warning` from
      either (SP-8 leg b).
- [ ] For the full-layout fixture, the same baseline equality holds, including the per-delivery and
      per-task file levels (SP-8 leg b).
- [ ] Reading the **unconverted** legacy tree with both post-refactor twins returns the
      minimal-model degradation and the same `parse_warning` naming the file and the migration
      command in both runtimes -- asserted as the required outcome, not tolerated as a shortfall
      (SP-8 leg c, SP-9, AC-5).
- [ ] The committed suite resolves no repo git history at run time; the pre-refactor capture is a
      recorded one-time authoring step of this task (CI clones shallowly).
- [ ] Derived counts and percentages in both post-refactor converted-tree payloads match the
      golden baseline's, proving no rollup was persisted by the conversion (SP-3, C-8).
- [ ] The suite builds its own fixtures, reads no live work tree, is deterministic, needs no
      network, and cleans up its temp state (`task-type-rules.md § TEST`).
- [ ] The suite runs under `python -m pytest dashboard/reader/tests dashboard/server/tests` with no
      third-party package installed (SP-17).
- [ ] Each assertion names the acceptance criterion it traces to (SP-8, and REQUIREMENTS AC-2) in
      the test docstring, matching the naming convention the existing parity suites use.
- [ ] A first-run failure is reported as a finding, not hidden; any defect it exposes is fixed in
      the owning task's files and named in this task's commit message.
- [ ] All section-6 quality gates pass.
