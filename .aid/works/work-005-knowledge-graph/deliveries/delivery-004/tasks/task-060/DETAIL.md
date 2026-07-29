# task-060: `graph-model.js` `LensState`, `project()` and the four presets

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

**Source:** work-005-knowledge-graph -> delivery-004

**Depends on:** task-059

**Scope:**
- Extend `canonical/aid/templates/knowledge-graph/graph-model.js` with its **second slice**: the
  `LensState` record, the pure `project(graphModel, lensState)` function, and the frozen `PRESETS`
  and `INITIAL_LENS` constants. Task-059's parser, records and `RELATION_CATEGORY` are not
  disturbed.
- Implement `LensState` exactly as feature-007 § 2 tabulates it: `preset`, `grouping`, `density`,
  `filters.{nodeKinds, categories, provenance, text}`, `focus.{nodeId, depth}`, `emphasis`, plus
  the two renderer-private fields `zoom` (graph-only) and `sort` (table-only). Flat and
  JSON-serialisable -- no function, element handle or renderer object on any field.
- Implement `project()` producing every `ViewModel` field of feature-007 § 3: `visibleEdges`,
  `visibleNodes`, `groups`, `nodeEmphasis`, `edgeEmphasis`, `nodeLabels`, `coverageGaps`,
  `coverageOrigin`, `lensSummary`, `announcement`, `revision`, `counts`.
- Implement the four presets from feature-007's preset patch table (Coverage, Overview, Impact,
  Provenance) as frozen partial assignments, and `INITIAL_LENS` as the unfiltered whole table with
  no lens applied.
- **Out of scope:** `createStore`, the `kb_gaps` verification, the `R`/`G`/`T` sets and zero-row
  materialisation (task-061) -- `project()` consumes whatever `coverageGaps` inputs the store
  supplies; control wiring (task-062); table rendering (tasks 063/064); any `import` statement.

**Acceptance Criteria:**
- [ ] `project()` is pure: it touches no DOM, no `Date`, no `Math.random` and no layout
      measurement, and two calls with the same inputs return deep-equal output. A grep over the
      function body finds none of `document`, `window`, `Date`, `Math.random`.
- [ ] Every `ViewModel` field listed in feature-007 § 3 is present on the returned object, with the
      contracted types; `visibleEdges` is ordered by `edge.row` ascending.
- [ ] `density: 1` performs **no thinning at all** -- a node with `degree === 0` survives it --
      and levels `2`-`5` hide nodes with `degree < density`.
- [ ] `zoom` and `sort` are the only renderer-private fields, and neither affects membership or
      emphasis: projecting a fixture twice with only `zoom` varied, and again with only `sort`
      varied, yields identical `visibleNodes`, `visibleEdges`, `nodeEmphasis` and `edgeEmphasis`.
- [ ] `PRESETS` is frozen and contains exactly `coverage`, `overview`, `impact` and `provenance`,
      each patching precisely the fields feature-007's preset table lists and no others.
- [ ] `INITIAL_LENS` is frozen and is `preset: null`, `grouping: 'none'`, `density: 1`, all filters
      on, `emphasis: 'none'`, `focus.nodeId: null` -- so no one of the four purposes is the default
      layout (FR-15), checkable by comparing `INITIAL_LENS` against each `PRESETS` entry and
      finding no match.
- [ ] `emphasis` is the only field that drives dimming or highlighting, and `project()` returns
      emphasis **classes** (`normal`/`dimmed`/`kb-unbacked`/`int-undocumented`/`focus`;
      `normal`/`dimmed`/`chain` for edges) -- never a colour, so NFR-5 cannot be broken downstream
      by a renderer reading this field.
- [ ] `grouping: 'relation-category'` partitions by `RELATION_CATEGORY`, making relation category
      available as a grouping dimension (FR-6); `grouping: 'none'` yields a single `all` group.
- [ ] `nodeLabels` is produced for every node in `visibleNodes` and is the single accessible name
      both renderings use; `announcement` and `lensSummary` name the active lens and its control
      values in one sentence each.
- [ ] Task-059's parser, `Node`/`Edge` construction, `RELATION_CATEGORY` and `nameConflicts` are
      unchanged: the diff for this task adds the new declarations and edits none of the existing
      ones.
- [ ] The file still declares no top-level `import` (GV01).
- [ ] All existing canonical suites still pass, and no suite is modified by this task; the named
      suites are the lens-parity suite (task-072) and `tests/canonical/test-graph-view-shell.sh`
      (tasks 070/071). *(Stated override of the IMPLEMENT default "unit tests for all new public
      methods", per the vehicle note in task-059.)*
- [ ] Build passes: `python .claude/skills/generate-profile/scripts/run_generator.py` completes;
      the render-drift confirmation for this delivery is task-069.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
