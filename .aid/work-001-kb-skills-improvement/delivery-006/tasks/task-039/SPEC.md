# task-039: act-back fixture + test-actback-fixtures.sh (the V-E family)

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-006

**Depends on:** task-027 (delivery-005), task-029 (delivery-005)

**Scope:**
- Author the hand-built, ASCII, checked-in **act-back fixture** that joins f012's `kb-essence/` corpus
  under `tests/canonical/fixtures/kb-essence/actback/`, per the f013 act-back fixture *shape*
  ([SPIKE-A5]). Three parts:
  - A **representative-task spec fixture** -- a small fixed project shape (a confirmed
    `discovery.doc_set` -- filenames + `present|absent` -- plus the operational sections present in
    its docs) over which delivery-005's `kb-actback-task.sh` (task-027) emits a stable, well-formed
    representative task. The fixture records the asserted task spec in `expected/` so the suite can
    diff against a byte-reproducible golden.
  - **`actback-pass-kb/`** -- a KB whose relevant docs carry the **first-class operational sections**
    (`## Conventions` / `## Invariants` / `## Gotchas` / `## Contracts`, per delivery-005/task-028's
    `concern-model.md` owning-table) the representative task needs; the presence check reports them
    **present**; the clean-context agent can plan with no insufficiency flag (the PASS shape).
  - **`actback-fail-kb/`** -- the same KB with that operational guidance **buried in prose or omitted**
    (the named sections absent); the presence check reports the expected classes **absent**; the
    clean-context M6 agent must guess / reach-for-source -> at least one `[ACTBACK]` FAIL item (the
    FAIL shape).
- Author `tests/canonical/test-actback-fixtures.sh` -- the **V-E** regression family alongside f012's
  V-A..V-D, auto-discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob (NO edit to
  run-all.sh). Follow the `test-doc-set-mapping.sh` pattern (`set -u`, `source ../lib/assert.sh`,
  numbered `T..`/`V-E..` assertions, `mktemp -d` scratch, `trap ... EXIT` cleanup, `test_summary` +
  `exit $?`). It runs delivery-005's SHIPPED `kb-actback-task.sh` (task-027) over a `mktemp -d` copy of
  the fixture and asserts the **MECHANICAL half**:
  - **V-E1** -- representative-task selection is deterministic + byte-reproducible: `kb-actback-task.sh`
    over the representative-task spec fixture emits the recorded `expected/` task spec; re-run is
    byte-identical (`diff` clean).
  - **V-E2** -- presence check over `actback-pass-kb` reports the operational sections the task needs
    as **present** (scoped to the classes each doc is expected to own).
  - **V-E3** -- presence check over `actback-fail-kb` reports the same expected classes as **absent**
    (the buried/omitted shape) -- the structural cause of an act-back sufficiency FAIL.
- **Judgment half -- RUNTIME-ANCHORED, NOT a mechanical CI assertion (mirrors V-C's engine-narration
  limb).** *Does the clean-context M6 (task-029) plan succeed over `actback-pass-kb`*, and *are its
  insufficiency flags over `actback-fail-kb` well-founded* -- these are **irreducibly LLM judgment**
  (the operational analog of teach-back's engine-narration limb). The suite does NOT score the plan;
  it asserts only the substrate the judgment is anchored to (V-E1 task well-formedness + V-E2/V-E3
  present/absent). Add the judgment half as a **new AC16 row to f012's Judgment-Boundary table** (the
  M6 act-back reviewer attempts the representative task over each KB at runtime; CI does not score it).

**Isolation discipline (load-bearing):** HOME-pinned to a throwaway dir (`export
HOME="${TMP}/fakehome"`) before any script run; carry the `_CANARY_BEFORE`/`_CANARY_AFTER` real-HOME
`.aid` snapshot (snapshot BEFORE; the real `$HOME` may already hold a `.aid` under CI, per
[[ci-runs-as-root-repo-under-home]]); always pass explicit fixture paths at the `mktemp` fixture copy;
`mktemp -d` scratch + `trap ... EXIT` cleanup; never mutate the committed fixture.

**Boundary:** f012 EXERCISES delivery-005's act-back gate -- this task does NOT author/edit
`kb-actback-task.sh` (task-027/d005), the M6 panel wiring or `reviewer-prompt-actback.md` (task-029/d005),
the `[ACTBACK]` rubric tag, or the doc-model owning-table (task-028/d005). It runs the SHIPPED helper
over the fixture and asserts the mechanical present/absent + byte-reproducibility substrate. The M6
clean-context plan-success / flag-well-foundedness self-score is the **judgment half**, runtime-anchored
in f012's Judgment Boundary, NOT a CI assertion. The fixture is the single source -- delivery-005's
in-suite unit fixture (`test-actback-task.sh`, task-030/d005) points at this corpus; the two do not
duplicate/diverge ([SPIKE-A5]).

**Acceptance Criteria:**
- [ ] `tests/canonical/fixtures/kb-essence/actback/` exists with the representative-task spec fixture
  (+ `expected/` golden task spec), `actback-pass-kb/`, and `actback-fail-kb/`; all files ASCII and
  checked into git (no generation step); the committed trees are static read-only inputs (the suite
  runs over a `mktemp -d` copy).
- [ ] `tests/canonical/test-actback-fixtures.sh` exists, is auto-discovered by `tests/run-all.sh` (no
  edit to run-all.sh), and follows the `test-doc-set-mapping.sh` pattern.
- [ ] V-E1: `kb-actback-task.sh` over the representative-task spec fixture emits the recorded
  `expected/` task spec; re-run over the same fixture copy is byte-identical (`diff` clean).
- [ ] V-E2: the presence check over `actback-pass-kb` reports the task-needed operational sections
  **present** (scoped to expected classes). V-E3: over `actback-fail-kb` reports the same expected
  classes **absent**.
- [ ] Judgment half: the suite does NOT mechanically assert M6 plan success or flag well-foundedness
  (irreducible LLM judgment, the operational analog of V-C's engine-narration limb); the mechanical
  substrate asserted is V-E1/V-E2/V-E3; the M6 plan-success/flag verdict is runtime-anchored and added
  as a new AC16 row to f012's Judgment-Boundary table, NOT a CI assertion.
- [ ] Isolation: HOME pinned to a throwaway dir; real-HOME `.aid` canary snapshots before/after and
  asserts no `.aid` appeared; explicit fixture paths at the `mktemp` copy; committed fixture never
  mutated; repo root never used.
- [ ] The act-back corpus is the single source delivery-005's `test-actback-task.sh` (task-030/d005)
  points at -- no duplicate/divergent fixture ([SPIKE-A5]).
- [ ] Tests are deterministic with clean setup/teardown; all AC16 act-back-fixture acceptance criteria
  from feature-013 (the V-E mechanical half) are covered; all section-6 quality gates pass.
