# task-038: test-teachback-fixtures.sh (AC1, TEST-C)

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-006

**Depends on:** task-037, task-012 (delivery-001)

**Scope:**
- Author `tests/canonical/test-teachback-fixtures.sh` -- the AC1 teach-back regression suite (f012
  SPEC TEST-C), auto-discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob (line 33; NO
  edit to run-all.sh). Follow the `test-doc-set-mapping.sh` pattern: `set -u`,
  `source ../lib/assert.sh`, numbered `T01..` assertions, `mktemp -d` scratch, `trap ... EXIT`
  cleanup, `test_summary` + `exit $?`.
- The suite runs f005's SHIPPED `kb-teachback-questions.sh` (delivery-001 task-012) + f004's SHIPPED
  `closure-check.sh` (delivery-001) over the task-037 `teachback/` fixtures (a `mktemp -d` copy of
  `pass-kb/` / `fail-kb/`) and asserts V-C1..V-C4 (f012 SPEC TEST-C):
  - V-C1 -- question-set generation is deterministic + correct: `kb-teachback-questions.sh` over
    `pass-kb/generated/candidate-concepts.md` emits a "what is X?" for every emitted Spread `>= 2`
    `Term` plus the one fixed engine-narration question; re-run is byte-identical.
  - V-C2 -- teach-back PASS substrate: `closure-check.sh` over `pass-kb` reports ZERO ungrounded
    (every concept the question set asks about is defined in the spine -- the KB can answer every
    question; the PASS shape).
  - V-C3 -- teach-back FAIL substrate: `closure-check.sh` over `fail-kb` reports the one undefined
    core concept (the KB cannot answer that "what is X?"; the FAIL shape). The suite asserts a FAIL
    verdict over `fail-kb`.
  - V-C4 -- the fail-KB's missing concept is a question-set member: the V-C3 ungrounded term appears
    in the V-C1 question set (the FAIL is on a *required* teach-back question, not a noise term).
- **Engine-narration limb -- RUNTIME JUDGMENT, NOT a mechanical CI assertion (load-bearing
  correction).** The fixed engine-narration question -- "can the KB support a coherent end-to-end
  account of the engine?" -- is **irreducibly LLM judgment** (f005 SPEC L434-435: "there is no
  mechanical check"; no shipped script returns this verdict; `kb-teachback-questions.sh` only EMITS
  the engine question as a fixed string, it does not score it, and `closure-check.sh` is purely
  lexical term-grounding). The suite therefore **does NOT mechanically assert an engine-narration
  FAIL**. The MECHANICAL substrate this suite asserts is: V-C1 (the engine question is a MEMBER of
  the generated question SET) + the LEXICAL PASS/FAIL (V-C2 term-defined PASS / V-C3 term-undefined
  FAIL). The engine-narration PASS/FAIL is exercised + ANCHORED at runtime (the clean-context M4
  reviewer attempts the narration over the planted fail-KB) and lives in f012's documented Judgment
  Boundary, not in this suite's assertion set.

**Isolation discipline (load-bearing acceptance criteria):** HOME-pinned to a throwaway dir
(`export HOME="${TMP}/fakehome"`) before any script run; carry the `_CANARY_BEFORE`/`_CANARY_AFTER`
real-HOME `.aid` snapshot from `test-aid-migrate.sh` (snapshot BEFORE -- the real `$HOME` may already
hold a `.aid` under CI, per [[ci-runs-as-root-repo-under-home]]); always pass explicit fixture paths
at the `mktemp` fixture copy (never a cwd/`$HOME` default, never the repo root); `mktemp -d` scratch +
`trap ... EXIT` cleanup; never mutate the committed fixture.

**Boundary:** f012 EXERCISES f005's teach-back gate -- this task does NOT author/edit
`kb-teachback-questions.sh`, the teach-back exit gate, the engine-narration question, or
`closure-check.sh` (f005/f004, delivery-001). It runs them over the task-037 fixtures and asserts the
PASS/FAIL substrate. The reviewer's clean-context teach-back narration self-score (f005 M4 -- the LLM
binary verdict) is the judgment half, NOT a CI assertion. The **engine-narration limb is wholly in
that judgment half** (no shipped script returns its verdict); this suite asserts only the MECHANICAL
LEXICAL substrate that makes a term-defined teach-back PASS reachable and a term-undefined FAIL
detectable, plus that the fixed engine question is a member of the generated question set. The
engine-narration PASS/FAIL is runtime-anchored, not mechanically asserted.

**Acceptance Criteria:**
- [ ] `tests/canonical/test-teachback-fixtures.sh` exists, is auto-discovered by `tests/run-all.sh` (no edit to run-all.sh), and follows the `test-doc-set-mapping.sh` pattern (`set -u`, `source ../lib/assert.sh`, numbered Ts, `mktemp -d`, `trap EXIT`, `test_summary`/`exit $?`).
- [ ] V-C1: `kb-teachback-questions.sh` over `pass-kb/generated/candidate-concepts.md` emits a "what is X?" for every emitted Spread `>= 2` `Term` AND the fixed engine-narration question is present; re-run over the same fixture copy is byte-identical (`diff` clean).
- [ ] V-C2: `closure-check.sh` over `pass-kb` asserts an empty ungrounded set (PASS substrate). V-C3: `closure-check.sh` over `fail-kb` asserts the one undefined core concept is in the ungrounded set, and the suite records a FAIL verdict over `fail-kb`.
- [ ] V-C4: the V-C3 ungrounded term is a member of the V-C1 question set (the FAIL is on a required teach-back question, not a noise term).
- [ ] Engine-narration limb: the suite does NOT mechanically assert an engine-narration FAIL (it is irreducible LLM judgment -- no shipped script returns the verdict; f005 SPEC L434-435). The mechanical engine-substrate asserted is V-C1's "the fixed engine question is a member of the generated question SET". The engine-narration PASS/FAIL is exercised + anchored at runtime (M4 reviewer over the planted fail-KB) per f012's documented Judgment Boundary, NOT a CI assertion.
- [ ] Isolation: HOME is pinned to a throwaway dir; the real-HOME `.aid` canary snapshots before/after and asserts no `.aid` appeared; every script invocation passes explicit fixture paths at the `mktemp` fixture copy; the committed fixture is never mutated; the repo root is never used.
- [ ] Tests are deterministic with clean setup/teardown; all AC1 (TEST-C) acceptance criteria from feature-012 are covered; all section-6 quality gates pass.
