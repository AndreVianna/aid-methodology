# task-061: `graph-model.js` store, `kb_gaps` verification and zero-row materialisation

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

**Depends on:** task-045, task-060

**Scope:**
- Extend `canonical/aid/templates/knowledge-graph/graph-model.js` with its **third and final
  slice**: `createStore(graphModel, initialLens)` and the Feature Flow step 3b `kb_gaps`
  verification, including zero-row node materialisation and the loud-failure content. Tasks 059's
  and 060's contents are not disturbed.
- Implement the store surface feature-007 § API Contracts fixes: `getViewModel()`, `getLens()`
  (frozen copy), `setLens(patch)`, `applyPreset(name)`, `subscribe(listener)` returning an
  unsubscribe, with `listener(viewModel, lensState, changedKeys)`.
- Implement step 3b inside `createStore`, before any subscriber exists: recompute the
  `int-undocumented` set with the inlined `coverage-predicate.mjs` exports (`detectKbGaps`,
  `kbUnbacked`, `COVERAGE_BEARING` -- task-045's module, referenced from the shared module scope,
  never `import`ed), form `R`, `G` and `T`, derive `viewOnly`, `ledgerOnly` and `orphans`, store
  the outcome on `graphModel.integrity`, and set `coverageGaps.intUndocumented` to the sorted
  union and `coverageOrigin` per id.
- Materialise every `orphans` id as a **complete `Node` record** inserted into `GraphModel.nodes`,
  and append the `" -- no recorded relationships"` marker to that node's `nodeLabels` entry.
- Implement the three-channel loud failure: filling the existing `role="alert"` container one task
  after mount, the `console.error` line, and the `.callout.warn` degradation when `kb_gaps` is
  absent.
- **Out of scope:** creating the alert/warn markup (task-057, which authors them empty);
  authoring the predicate itself and its `COVERAGE_BEARING` membership (task-045, delivery-003);
  writing `kb_gaps` into `relationships.md` (task-046, delivery-003); the zero-row table region
  (task-064); inlining mechanics (task-065).

**Acceptance Criteria:**
- [ ] The verification runs **exactly once per load**, inside `createStore`, after `GraphModel` is
      built and before any subscriber exists, and does not re-run on any subsequent `setLens` or
      `applyPreset` -- asserted by counting predicate invocations across a fixture's lens changes.
- [ ] The three sets are computed as feature-007 defines them: `R` = the recomputed
      `int-undocumented` set, `G` = the id set of `recordedGaps`, `T` = the `int:` ids present in
      the table; and `viewOnly = R \ G`, `ledgerOnly = (G ∩ T) \ R`, `orphans = G \ T` are stored
      on `graphModel.integrity` as `{status, viewOnly, ledgerOnly, orphans}`.
- [ ] `coverageGaps.intUndocumented` is **always the sorted union `R ∪ G`**: over a fixture where
      `R` and `G` disagree in both directions, the resulting list contains every id from both sets,
      so a disagreement over-reports and can never hide a gap on either surface.
- [ ] `ledgerOnly` is intersected with `T` **in the set definition itself**, so the mismatch alarm
      is structurally unable to fire on a zero-row node: over a fixture whose only disagreement is
      a zero-row `kb_gaps` entry, `integrity.status` is clean, the `role="alert"` container stays
      empty, and no `console.error` is written. Changing that behaviour requires editing the set
      definition, not adding a guard clause -- there is no `orphan`/`degree === 0` test on the
      error path anywhere in the file.
- [ ] Each `orphans` id is materialised as a **complete `Node`** in `GraphModel.nodes`: `id` and
      `name` from the `kb_gaps` entry, `kind: 'int'` read from the id prefix by the same rule as
      every node, the `int` glyph by the same rule, `kbDoc: null`, and `degree`, `kbDegree`,
      `intDegree`, `extDegree` all `0`.
- [ ] The materialised record carries **no synthetic flag**: a grep over `graph-model.js` finds no
      `synthetic`, `isOrphan`, `zeroRow` or equivalent property on `Node`, and no `degree === 0`
      branch in the projection, the grouping partition, the focus handling or the emphasis
      assignment.
- [ ] A zero-row node behaves as feature-007's control table fixes: `grouping: 'node-kind'` puts it
      in the `int` group; `grouping: 'document'` in the ungrouped bucket; `grouping:
      'relation-category'` and `'provenance'` in a dedicated **`no relationships`** group listed
      last; `density: 1` shows it; `filters` admit and exclude it like any node; selecting it as
      `focus.nodeId` yields a neighbourhood of the node alone at every depth, with `lensSummary`
      and `announcement` saying "no recorded relationships".
- [ ] `nodeLabels` for a zero-row node is `"<name> — no recorded relationships"`, so the
      distinction reaches both renderings and the announced text through machinery they already
      implement.
- [ ] `coverageOrigin` reports `'verified'`, `'ledger-only'` or `'view-only'` for each
      `intUndocumented` id, and `'ledger-only'` for every zero-row node.
- [ ] On a genuine mismatch, all three channels fire and none blanks the page: the `.callout.err`
      `role="alert"` container is filled **one task after mount** with the plain-language text and
      the exact `viewOnly` / `ledgerOnly` id lists of feature-007 § "What the reader sees"; it is
      written at most once per load and is not dismissible; `console.error` is written with the
      stable prefix `graph.html: kb_gaps integrity check failed` followed by the two id lists; and
      **both renderings still mount**.
- [ ] When `recordedGaps === null` the page fills the `.callout.warn` instead, stating the ledger
      cross-check was unavailable and that the Coverage lens shows the view's own recomputation --
      no `role="alert"` write and no `console.error`.
- [ ] Store semantics: `setLens` shallow-merges the patch, re-projects, increments `revision`, and
      notifies **every** subscriber synchronously with the same `ViewModel` instance;
      `applyPreset(name)` is `setLens(PRESETS[name])` plus `preset: name`; `getLens()` returns a
      frozen copy whose mutation has no effect.
- [ ] Tasks 059's and 060's contents are unchanged: the diff adds `createStore` and the
      verification and edits neither the parser nor `project()`/`PRESETS`/`INITIAL_LENS`.
- [ ] The file still declares no top-level `import` and reaches the predicate's exports through the
      shared module scope (GV01).
- [ ] All existing canonical suites still pass, and no suite is modified by this task; the named
      suite is `tests/canonical/test-graph-view-shell.sh` (task-071 carries GV06 and the full GV07
      zero-row contract). *(Stated override of the IMPLEMENT default "unit tests for all new public
      methods", per the vehicle note in task-059.)*
- [ ] Build passes: `python .claude/skills/generate-profile/scripts/run_generator.py` completes;
      the render-drift confirmation for this delivery is task-069.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
