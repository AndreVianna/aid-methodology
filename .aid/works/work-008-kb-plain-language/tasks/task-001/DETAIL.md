# task-001: Enumerate the coined-term and shouted-code universe and decide a disposition for every term

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

**Type:** RESEARCH

**Source:** work-008-kb-plain-language -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Compute the coined-term candidate universe over the KB as it stands today, using only the shipped
  scripts and exactly the two-harvest recipe SPEC.md `#### Flow A` step 3 fixes:
  `bash canonical/aid/scripts/kb/harvest-coined-terms.sh --root .` and a second run with
  `--root .aid/knowledge`, both with a `--top` value large enough that neither `## Ranked Candidates`
  table truncates. Merge the two tables and deduplicate by term.
- Resolve each candidate against `.aid/knowledge/domain-glossary.md`'s defined set with
  `bash canonical/aid/scripts/kb/closure-check.sh --concepts <merged> --spine
  .aid/knowledge/domain-glossary.md --kb-dir .aid/knowledge`. Because the additive
  `--defined-extra` flag (task-002) may not exist yet, triage by hand any candidate that is already
  defined in a `## Lexicon -- *`, `## Abbreviations & Acronyms`, or
  `## Terms with Specific Domain Meanings` table, and record it as already-defined rather than as a
  gap.
- Enumerate the shouted bare-code class REQUIREMENTS.md §5 FR-4 names (`CONFIRMED`, `SYNTHESIS`,
  `ELICIT E1/E2`, `S1-S5`, `T1-T6`, `P1`/`P9`/`P10`, `C0`-`C9`, `APPROVAL-HALT`, and any further
  member of the class the sweep finds) across all 17 in-scope docs, recording for each its
  first-occurrence doc and whether a legend resolving it exists in that doc today.
- Decide and record exactly one disposition per term -- `define` (a new `## Concept Spine` `### `
  entry), `alias` (an `**Aliases:**` value on an existing spine concept), `replace` (plain words,
  with the proposed replacement wording), or `dismiss` (not a concept at all, with the reason text
  that task-006 will write into `.aid/knowledge/.glossary-dismissed.txt`).
- Write the findings to `.aid/works/work-008-kb-plain-language/notes/term-inventory.md`. This is the
  input every rewrite task (task-006 through task-013) works from, so it must be complete rather
  than illustrative -- REQUIREMENTS.md §8 states the §2 list is a sample, not the class.
- **Changes no production file.** RESEARCH produces documents only: no KB doc, no `canonical/` file,
  no script, no test fixture is touched here.

**Acceptance Criteria:**
- [ ] `.aid/works/work-008-kb-plain-language/notes/term-inventory.md` exists and carries one row per
      candidate term with the columns: term | harvest channel(s) | docs where used | glossary status
      today | disposition | reason or proposed replacement wording.
- [ ] The note records the exact harvest and closure-check commands run, including the `--top`
      values, and re-running them reproduces the same candidate set (the inventory is reproducible,
      not recalled).
- [ ] Every term REQUIREMENTS.md §2 names -- "load-bearing", "Concept Spine", "dogfood",
      "kind-sibling", "thin doorway", "fat pipeline", "hand-authored collapse", "lockstep",
      "render-drift", "HOME-pinning" -- appears with a disposition and an explicit
      define-versus-replace trade-off (AC-2).
- [ ] Every shouted-code class in FR-4 is listed with its first-occurrence doc and the chosen
      resolution route -- inline expansion, a named legend, or a glossary entry (AC-3).
- [ ] Every `dismiss` row carries the verbatim reason text destined for
      `.aid/knowledge/.glossary-dismissed.txt`, and no term carries both a `dismiss` disposition and
      a `define`/`alias` disposition (AC-14).
- [ ] The note names, for each `define` row, whether the term goes to the Concept Spine or to a
      Lexicon table, so task-006 does not have to re-decide the glossary's structure.
- [ ] `git status --porcelain -- .aid/knowledge canonical tests` prints nothing: the task changed no
      production file.
- [ ] All section-6 quality gates pass.
