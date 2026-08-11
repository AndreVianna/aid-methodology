# task-015: Run the delivery-wide verification sweep and clear the grade gate

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

**Depends on:** task-003, task-014

**Scope:**
- Run the whole delivery's verification set over the finished tree, once, and report the results as
  findings rather than fixing them in place:
  - `bash canonical/aid/scripts/kb/kb-language-lint.sh --root .` (both checks, whole KB).
  - `bash canonical/aid/scripts/kb/lint-frontmatter.sh` and
    `bash canonical/aid/scripts/kb/kb-citation-lint.sh` over `.aid/knowledge/`.
  - `grep -rE 'work-[0-9]{3}' .aid/knowledge/`.
  - `wc -w` on all 17 docs against their REQUIREMENTS.md §4 baselines (115% cap).
  - `bash tests/run-all.sh` and `bash tests/coverage-parity.sh`.
  - `AID_HARVEST_NO_RG=1 bash canonical/aid/scripts/kb/kb-language-lint.sh --root .` compared against
    the default run.
  - A read of `.aid/knowledge/.glossary-dismissed.txt` cross-checked against `domain-glossary.md`.
- Dispatch `aid-reviewer` over the rewritten KB against the tightened rubric, and run
  `bash .claude/aid/scripts/grade.sh` over the resulting 7-column ledger at
  `.aid/.temp/review-pending/<scope>.md`.
- This is the delivery's single whole-tree gate run. Per-doc and per-script verification already
  happened inside tasks 002-014; this task proves the composition holds and that nothing regressed
  when the batches merged.
- Any failure is written up as a finding naming the owning task; this task does not silently repair
  another task's work.

**Acceptance Criteria:**
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --root .` exits 0 with zero `[GLOSSARY-GAP]`
      and zero `[LANG-FRONTMATTER]` lines over the whole KB (AC-2, AC-4).
- [ ] Every term REQUIREMENTS.md §2 names either resolves to a `domain-glossary.md` definition or no
      longer appears in `.aid/knowledge/*.md`, checked by case-insensitive grep per term (AC-2).
- [ ] `lint-frontmatter.sh` and `kb-citation-lint.sh` over `.aid/knowledge/` both exit 0 with no
      `[FM-MISSING]`, `[FM-INVALID]`, or positional-citation finding (AC-10).
- [ ] `grep -rE 'work-[0-9]{3}' .aid/knowledge/` returns no match (exit 1) (AC-11).
- [ ] `wc -w` on each of the 17 docs is at most 115% of its REQUIREMENTS.md §4 baseline, reported as a
      per-doc table (AC-6).
- [ ] `bash tests/run-all.sh` passes, including `test-kb-language-lint.sh`,
      `test-closure-check.sh`, the essence/teachback suites, and
      `test-dogfood-byte-identity.sh`; `bash tests/coverage-parity.sh` exits 0 (AC-16, AC-17).
- [ ] `AID_HARVEST_NO_RG=1` produces findings identical to the default lint run (AC-13).
- [ ] Every non-blank, non-comment line of `.aid/knowledge/.glossary-dismissed.txt` carries exactly
      one bare term immediately preceded by a `#` comment line stating its reason, and no term there
      also carries a `domain-glossary.md` definition (AC-14).
- [ ] The `aid-reviewer` ledger carries no `[GLOSSARY-GAP]`, `[LANG-FRONTMATTER]`,
      `[AUTHORING-CLARITY]`, or `[AUTHORING-CODE]` row above MINOR, and `grade.sh` over that ledger
      returns at least `A`, the resolved `minimum_grade` (AC-12, AC-3).
- [ ] The run is reported in full -- every command, its exit code, and its findings -- with each
      failure attributed to the owning task rather than repaired here.
- [ ] All section-6 quality gates pass.
