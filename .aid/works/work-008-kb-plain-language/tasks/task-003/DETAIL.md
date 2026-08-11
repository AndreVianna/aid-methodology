# task-003: Cover the new lint with test-kb-language-lint.sh and its undefined/defined fixture pair

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

**Source:** work-008-kb-plain-language -> delivery-001

**Depends on:** task-002

**Scope:**
- Create `tests/canonical/test-kb-language-lint.sh`, discovered by the existing
  `tests/canonical/test-*.sh` glob so `tests/run-all.sh` needs no edit. Carry `# COVERS:` headers for
  `canonical/aid/scripts/kb/kb-language-lint.sh` and its fixture directory.
- Create the load-bearing fixture pair under `tests/canonical/fixtures/kb-language-lint/`:
  `undefined/` -- a minimal KB whose doc introduces a coined term with no `domain-glossary.md` entry
  and no dismissal row; and `defined/` -- byte-identical except that the term carries a `### `
  glossary entry. Add frontmatter fixtures in the same directory: an over-length `objective:`, a
  multi-sentence / over-length / multi-em-dash `summary:`, and their in-bounds twins.
- Assert the pair asymmetry explicitly: `undefined/` must exit 1 with a `[GLOSSARY-GAP]` line naming
  the term, `defined/` must exit 0. Both passing, or both failing, is itself a test failure (AC-7).
- Cover the dismissal route (a term listed in `.glossary-dismissed.txt` is silenced), the
  `--check frontmatter` bounds, the exit-code contract (0/1/2), and the ripgrep-free parity path
  (`AID_HARVEST_NO_RG=1` produces identical findings, AC-13).
- Follow the suite conventions `test-landscape.md` records: S1 (one subject invocation per distinct
  fixture, asserted many times), S2 (single-pass read into arrays, no per-assertion command
  substitution), S5 (mutate only a `mktemp -d` copy, never the source tree).
- Register the new suite's coverage rows in `tests/coverage-baseline.tsv` so
  `bash tests/coverage-parity.sh` stays green.
- Re-run the oracles the `closure-check.sh` change could disturb --
  `bash tests/canonical/test-closure-check.sh` and the essence/teachback suites -- and report the
  results as findings rather than adjusting them (AC-17).

**Acceptance Criteria:**
- [ ] `bash tests/run-all.sh` discovers `tests/canonical/test-kb-language-lint.sh` through the
      `tests/canonical/test-*.sh` glob and the suite passes (AC-16).
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --root
      tests/canonical/fixtures/kb-language-lint/undefined/` exits 1 and prints a `[GLOSSARY-GAP]`
      line naming the fixture's undefined term; the `.../defined/` sibling exits 0; the suite asserts
      both directions and fails if the two agree (AC-7).
- [ ] The frontmatter fixtures assert one `[LANG-FRONTMATTER]` finding per out-of-bounds case and
      none for the in-bounds twins (AC-4).
- [ ] The suite carries `# COVERS:` headers naming
      `canonical/aid/scripts/kb/kb-language-lint.sh` and
      `tests/canonical/fixtures/kb-language-lint/`, and `bash tests/coverage-parity.sh` exits 0 with
      the new rows present in `tests/coverage-baseline.tsv` (AC-16).
- [ ] `bash tests/canonical/test-closure-check.sh` and the essence/teachback suites pass unchanged --
      no assertion in them was edited to accommodate `--defined-extra` (AC-17).
- [ ] The suite asserts `AID_HARVEST_NO_RG=1` yields the same findings as the default run (AC-13).
- [ ] Two consecutive runs produce identical PASS/FAIL sets and counts; every temporary tree is
      created under `mktemp -d` and removed on exit including on failure; `git status --porcelain`
      after a run shows no fixture mutation (S5, determinism).
- [ ] `bash tests/canonical/test-ascii-only.sh` passes over the new suite and its fixtures.
- [ ] All section-6 quality gates pass.
