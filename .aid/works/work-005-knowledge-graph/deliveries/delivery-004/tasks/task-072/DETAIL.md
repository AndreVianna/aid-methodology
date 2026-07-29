# task-072: Preset-lens parity and control-liveness assertions

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

**Source:** work-005-knowledge-graph -> delivery-004

**Depends on:** task-063, task-064

**Scope:**
- Author the AC-7 / AC-8 headless suite feature-007 § "Test hook for AC-7" describes, as
  `tests/canonical/test-graph-lens-parity.sh`. *(No SPEC names a suite file for this hook; the
  name follows the `tests/canonical/test-*.sh` discovery convention, and the suite is kept
  separate from `test-graph-view-shell.sh` so it does not contend with the GV-series serialisation
  of tasks 070 → 071.)*
- For each of the four presets: project it over a self-built fixture and assert the projection
  differs from the initial projection, and that the table rendering changes accordingly from that
  same `ViewModel`.
- Assert AC-8 control liveness: after arriving through each preset, grouping, density, filter and
  zoom writes still take effect through `setLens`.
- Assert the renderer-private carve-out: varying `zoom` or `sort` alone changes neither membership
  nor emphasis.
- **Scope limit, stated rather than assumed:** the graph rendering is feature-008 in delivery-005,
  so "each lens applies to **both** renderings" is asserted here through its mechanism -- one
  `ViewModel` instance delivered synchronously to every subscriber, with membership and emphasis
  decided only in `project()`. The canvas's own consumption of the same lenses is verified by
  task-087 in delivery-005.
- **Out of scope:** the GV series (tasks 070/071); WCAG verification (task-073); driving a real
  browser -- this suite is headless by design, which is what makes the parity assertion cheap
  enough to keep.

**Acceptance Criteria:**
- [ ] For each of `coverage`, `overview`, `impact` and `provenance`: the projection over the
      fixture differs from the `INITIAL_LENS` projection in at least one of `visibleNodes`,
      `visibleEdges`, `groups`, `nodeEmphasis` or `edgeEmphasis` -- the checkable form of "each
      visibly changes the view" (AC-7).
- [ ] For each preset, the table rendering's row set, order or badge state changes accordingly, and
      the suite asserts the table subscriber received the **identical `ViewModel` instance** the
      store notified -- the mechanism by which a second rendering cannot reinterpret the lens
      (NFR-3).
- [ ] AC-8: after applying each preset, a subsequent `setLens` write to `grouping`, `density`,
      each `filters` field and `zoom` takes effect, `revision` increments on each, and no control
      is left `disabled` -- a preset is an entry point, not a mode.
- [ ] Projecting the fixture with only `zoom` varied, and again with only `sort` varied, yields
      identical `visibleNodes`, `visibleEdges`, `nodeEmphasis` and `edgeEmphasis`.
- [ ] The initial state is asserted to match no preset patch, so "no privileged default layout"
      (FR-15) is checked rather than assumed.
- [ ] **Tests are deterministic** (TEST default): the suite is headless, uses no clock, no network
      and no randomness, and repeated runs give the same result.
- [ ] **Clean setup/teardown** (TEST default): the fixture `relationships.md` is built under
      `mktemp -d` and removed on exit; no dependence on any work folder (**A-6**);
      `tests/lib/assert.sh` sourced; `ID + description` labels used.
- [ ] The suite is discovered by `tests/run-all.sh`'s glob with no runner edit and
      `bash tests/canonical/test-graph-lens-parity.sh` exits 0.
- [ ] Source-feature coverage: AC-7 (both features' shared criterion, table side exercised
      directly and graph side bound by contract) and AC-8 are each covered by at least one labelled
      assertion; the graph-half exercise is named as task-087's.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
