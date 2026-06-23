# task-012: kb-teachback-questions.sh + canonical test

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-001

**Depends on:** task-006

**Scope:**
- Author `canonical/aid/scripts/kb/kb-teachback-questions.sh`: the deterministic (no LLM) teach-back
  question-set generator. From `.aid/generated/candidate-concepts.md`, emit "what is X?" for every
  EMITTED `Term` row where `spread >= 2` OR `Source == synthesis` (the explicit two-clause selection
  rule -- the `OR Source == synthesis` clause is load-bearing because f004 emits synthesis rows with
  an empty/`-` `Spread`, so a bare `spread >= 2` filter would drop exactly the tokenless concepts the
  non-lexical limb quizzes), PLUS the one fixed engine question
  "Explain how this system works, in its own language." Bounded by f004's emitted table (never
  invents un-emitted terms). ASCII bash; coreutils only (`grep`/`awk`/`sort`/`tr`).
- Add `kb-teachback-questions.sh` to the `test-ascii-only.sh` allow-list.
- Author `tests/canonical/test-teachback-questions.sh`: assert the generator extracts cross-source
  terms (incl. `synthesis` concepts) + the engine question deterministically and byte-reproducibly;
  auto-discovered by `tests/run-all.sh`.
- Test-split convention (deliberate sizing choice): a canonical test is BUNDLED into its IMPLEMENT
  task when SMALL (single-script + a few assertions -- e.g. this teach-back set, and task-003's
  frontmatter lint), and SPLIT into its own TEST task when SUBSTANTIAL (large fixture suites --
  harvest T01-T10 + fixture trees -> task-007; closure C01-C08 + 3-output fixtures -> task-009).
- Edit canonical only; re-run `run_generator.py`; commit regenerated `profiles/`.

**Acceptance Criteria:**
- [ ] `kb-teachback-questions.sh` is deterministic ASCII bash (coreutils only; no LLM) emitting the
  fixed question set per the `spread >= 2 OR Source == synthesis` rule + the one fixed engine question.
- [ ] Every `synthesis`-tagged concept is included regardless of its empty/`-` `Spread` (the OR clause
  is verified to not drop synthesis rows).
- [ ] The set is bounded by `candidate-concepts.md`'s emitted rows -- no un-emitted term is invented.
- [ ] A re-run is byte-identical (determinism).
- [ ] `kb-teachback-questions.sh` is on the `test-ascii-only.sh` allow-list and passes the ASCII guard.
- [ ] `tests/canonical/test-teachback-questions.sh` asserts cross-source + synthesis extraction + the
  engine question + byte-reproducibility; it is deterministic with clean setup/teardown and
  auto-discovered by `tests/run-all.sh`.
- [ ] `run_generator.py` re-run; regenerated `profiles/` committed (render-drift green).
- [ ] All section-6 quality gates pass.
