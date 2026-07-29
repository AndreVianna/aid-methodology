# task-038: `test-relationships-reproducible.sh` byte-identity suite

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

**Source:** work-005-knowledge-graph -> delivery-002

**Depends on:** task-023, task-024

**Scope:**

- Create `tests/canonical/test-relationships-reproducible.sh` -- the suite that makes FR-32 and
  AC-5 real rather than asserted. Feature-005's Layers table fixes its two halves: "two
  consecutive runs on an unchanged fixture tree yield a byte-identical class-0 block; then a
  class-1 row is added, removed, and reworded and the class-0 block is asserted unchanged".
  Because the staleness check of task-041 is only meaningful if this property holds, these
  assertions must be **exact byte comparisons, never approximations** -- no row-count check, no
  sorted-set comparison, no normalisation before diffing.
- **Half 1 -- two runs, byte-identical class 0.** Build a fixture KB plus source tree under
  `mktemp -d`, `git init` it, run `build-relationships.sh` twice with no change between runs, and
  assert:
  - The extracted **class-0 block** -- the contiguous prefix of rows whose `Provenance` is
    `declared` or `derived` -- is **byte-identical** between run 1 and run 2 (`cmp`, not a
    field-wise comparison).
  - The extraction uses the D7 predicate (`Provenance ∈ {declared, derived}`) and **no in-file
    boundary marker**, since the class boundary is a predicate the ordering guarantees is
    contiguous and §5.2's one-table rule forbids a marker.
  - The class-0 block is a **contiguous prefix**: no `inferred` row appears before any class-0
    row.
- **Half 2 -- class-1 churn leaves class 0 unchanged.** With the same fixture and the same
  class-0 input, perform three separate mutations of the class-1 set and assert after **each**
  that the class-0 block is byte-identical to the Half 1 baseline:
  1. a class-1 row **added**;
  2. a class-1 row **removed**;
  3. a class-1 row **reworded** (its `observation` free text changed).
  Assert that in none of the three does a class-0 row move, split, or reflow -- which is the
  property class-major ordering exists to provide.
- **The seven mechanisms of feature-005's "What guarantees FR-32 / AC-5", each with an
  assertion:**
  1. **Contiguity** -- as above.
  2. **Enforced one-way merge** -- a class-1 row whose `rel_row_key` collides with a class-0 key
     is rejected, and a class-1 row not stamped `inferred` is rejected; pass 2 has **no write
     path into class 0**.
  3. **Stable ordering** -- every sort is `LC_ALL=C`. Assert the class-0 block is byte-identical
     when the suite re-runs the generator under a deliberately non-C locale
     (e.g. `LANG`/`LC_ALL` set to a UTF-8 locale for the caller), proving the pinned sorts hold.
  4. **Stable ids and names** -- no cell contains `$PWD`, an absolute path, a drive letter, or a
     repo-root prefix. Assert by grep over the emitted table.
  5. **No time and no position inside the boundary** -- no timestamp in the table, in any row, or
     in the `AUTO-GENERATED` marker; no `changelog:`; no mtime, file size, or line number; every
     class-0 `observation` is a grep-recoverable literal. Assert that
     `graph_inputs_digest` and `graph_generated_at` sit **outside** the boundary: changing them
     alone leaves the class-0 block byte-identical.
  6. **Total tie-breaks** -- assert the step-7 de-duplication rule is a total order by feeding
     the same duplicate key in two different input orders and asserting the same survivor:
     stronger provenance wins (`declared` over `derived`), and on a tie the lexicographically
     smaller `observation` wins.
  7. **LF-only output** -- the emitted file contains no CR byte, verified even though the
     repository is authored on Windows.
- **The AC-5 mechanical check shape.** Assert the check the SPEC specifies is the one the suite
  performs: regenerate, extract the class-0 prefix, and byte-compare it against the class-0
  prefix of the previously committed artifact obtained with
  `git show HEAD:.aid/knowledge/relationships.md`. Exercise this git-native form against the
  suite's own `mktemp -d` fixture repository -- committing the first run there and comparing the
  second against `HEAD` -- so no side-channel file and no stored hash is needed and the assertion
  never reads this repository's own `.aid/knowledge/` or any work folder (A-6).
- Fixtures include a fixture vocabulary and a fixture edge-relation map, never feature-001's real
  file, so the suite runs while feature-001 is still open (D-1). Class-1 rows are supplied by a
  **stubbed** pass-2 input file rather than a live agent dispatch, so the suite is deterministic;
  assert the stub path explicitly rather than leaving it implicit.
- Out of scope: the pass-2 bound rejections themselves (**task-039**); the declared and derived
  harvest suites (**tasks 036, 037**); the staleness digest suite (**task-041**), which depends on
  this property but tests a different script; and `build-relationships.sh` itself (tasks 023,
  024).
- Discovered by the `tests/canonical/test-*.sh` glob with **no edit to `tests/run-all.sh`**;
  sources `tests/lib/assert.sh`; uses the `ID + description` label convention of
  `tests/canonical/test-guardrails-d012.sh`.

**Acceptance Criteria:**

- [ ] `tests/canonical/test-relationships-reproducible.sh` exists, sources `tests/lib/assert.sh`,
      uses the `ID + description` label convention, and is discovered by the glob with no edit to
      `tests/run-all.sh`.
- [ ] Two consecutive runs over an unchanged fixture tree are asserted to yield a
      **byte-identical** class-0 block, compared with `cmp` (or `diff` on raw bytes) rather than
      by row count, field-wise comparison, or a re-sorted set.
- [ ] The class-0 block is extracted by the `Provenance ∈ {declared, derived}` predicate with no
      in-file boundary marker, and is asserted to be a contiguous prefix.
- [ ] Three separate class-1 mutations -- add, remove, reword -- are each asserted to leave the
      class-0 block byte-identical to the two-run baseline.
- [ ] A class-1 row colliding with a class-0 `rel_row_key` is asserted rejected, and a class-1
      row not stamped `inferred` is asserted rejected.
- [ ] The class-0 block is asserted byte-identical when the generator is invoked under a
      non-C caller locale.
- [ ] A grep over the emitted table is asserted to find no `$PWD`, absolute path, drive letter,
      or repo-root prefix.
- [ ] No timestamp is asserted present in the table, in any row, or in the `AUTO-GENERATED`
      marker, and no `changelog:` field is emitted.
- [ ] Changing `graph_inputs_digest` and `graph_generated_at` alone is asserted to leave the
      class-0 block byte-identical.
- [ ] The step-7 de-duplication tie-break is asserted total: the same survivor results from two
      different input orders, with `declared` beating `derived` and the lexicographically
      smaller `observation` breaking a tie.
- [ ] The emitted file is asserted to contain no CR byte.
- [ ] The AC-5 git-native check (`git show HEAD:...` on the fixture repository, then a byte
      compare of the class-0 prefix) is exercised, and it reads neither this repository's
      `.aid/knowledge/relationships.md` nor any path under `.aid/works/` (A-6).
- [ ] Class-1 rows come from a stubbed pass-2 input, not a live agent dispatch, and the stub is
      named explicitly in the suite.
- [ ] The suite uses a fixture vocabulary and a fixture edge-relation map, never feature-001's
      real `relation-vocabulary.yml`.
- [ ] **Tests are deterministic** -- no wall-clock dependence, no network, no agent invocation,
      no ordering dependence; repeated runs of the suite agree byte for byte.
- [ ] **Clean setup/teardown** -- every fixture is created under `mktemp -d` and removed on exit
      including on failure (`trap`); `git status --porcelain` is clean afterwards.
- [ ] **Every acceptance criterion from feature-005 that this suite carries is covered**:
      **AC-5** in both halves, and FR-32's "deterministic majority" boundary as feature-003 D7
      draws it.
- [ ] The suite passes under `HOME="$(mktemp -d)" bash tests/run-all.sh`, and no existing suite
      regresses.
