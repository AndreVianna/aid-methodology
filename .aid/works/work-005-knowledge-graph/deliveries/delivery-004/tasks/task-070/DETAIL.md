# task-070: `test-graph-view-shell.sh` GV02-GV05 assertions

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

**Depends on:** task-054, task-069

**Scope:**
- Add `GV02`, `GV03`, `GV04` and `GV05` to the existing suite
  `tests/canonical/test-graph-view-shell.sh`, which task-054 (delivery-003) seeded with `GV01`.
- `GV02` -- the module's inlined region in a generated `graph.html` is byte-identical to the
  `coverage-predicate.mjs` **of the tree that generated it**.
- `GV03` -- a bare Node process imports the module and `detectKbGaps` returns the expected set over
  a fixture.
- `GV04` -- `COVERAGE_BEARING` equals feature-006's recorded `coverage_bearing` subset in the
  sibling file beside `canonical/aid/templates/graph/relation-vocabulary.yml` (task-045).
- `GV05` -- `COVERAGE_BEARING ⊆ keys(RELATION_CATEGORY)`.
- **Out of scope:** `GV01`, which task-054 owns and this task must not disturb; `GV06`-`GV08`
  (task-071, same file, immediately after this task); any change to product code -- a failing
  assertion here is a defect for the owning IMPLEMENT task, not a reason to weaken the assertion.

**Acceptance Criteria:**
- [ ] `GV02` diffs the inlined `<script type="module">` region out of a generated `graph.html`
      against the generating tree's own `<install-root>/aid/scripts/graph/coverage-predicate.mjs`,
      resolving the install root from the artifact under test; the assertion contains **no
      hard-coded `canonical/…` path** to the module, and it fails when a single byte of the inlined
      region differs.
- [ ] `GV03` runs `node --input-type=module` (or an equivalent bare import) with no DOM shim and no
      `package.json` in scope, and asserts `detectKbGaps` returns the expected sorted set over the
      fixture -- proving no browser dependency leaked into the module.
- [ ] `GV04` compares `COVERAGE_BEARING` to the recorded subset as **sets**, and fails on a member
      present in either one alone, in both directions.
- [ ] `GV05` asserts every member of `COVERAGE_BEARING` is a key of `RELATION_CATEGORY`, so a
      member that is not a real relation is a build failure rather than a member that never
      matches.
- [ ] `GV01` is untouched: the diff for this task adds assertions and edits none of task-054's
      lines, and the suite still reports `GV01` passing.
- [ ] **Tests are deterministic** (TEST default): repeated runs of
      `bash tests/canonical/test-graph-view-shell.sh` produce the same result, with no dependence
      on wall-clock time, network, or ordering.
- [ ] **Clean setup/teardown** (TEST default): every fixture is built under `mktemp -d` and removed
      on exit; the suite depends on no work folder's contents (**A-6**), sources
      `tests/lib/assert.sh`, and uses the `ID + description` assertion-label convention of
      `tests/canonical/test-guardrails-d012.sh`.
- [ ] The suite is discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob with no
      runner edit, and `bash tests/canonical/test-graph-view-shell.sh` exits 0.
- [ ] Source-feature coverage: `GV02`-`GV05` of feature-007 § Tests are each present and each maps
      to one labelled assertion; the delivery gate's GV01-GV08 requirement is completed by
      task-071.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
