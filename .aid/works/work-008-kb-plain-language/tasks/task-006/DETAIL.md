# task-006: Rewrite domain-glossary.md and land the settled term set

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

**Type:** REFACTOR

**Source:** work-008-kb-plain-language -> delivery-001

**Depends on:** task-001, task-004

**Scope:**
- Rewrite the prose and the `objective:`/`summary:` frontmatter of `.aid/knowledge/domain-glossary.md`
  (baseline 6741 words) in plain language, changing no fact, contract, enum, table row, path,
  command, or citation.
- Land the term set task-001 settled: add a `## Concept Spine` `### ` entry for every `define`
  disposition, an `**Aliases:**` value for every `alias` disposition, and apply the `replace` wording
  where this doc itself uses a term being retired.
- Create `.aid/knowledge/.glossary-dismissed.txt` -- one bare term per line, each preceded by a `#`
  comment line carrying its reason (the only form `closure-check.sh --dismissed` parses; an inline
  `#` is not stripped and would be read as part of the term), ASCII, LF, dot-prefixed so the KB
  scripts' `! -name '.*'` filter skips it as a doc. Add
  entries to `.aid/knowledge/.coined-term-denylist.local.txt` where task-001 identified an ordinary
  word the harvest keeps mis-ranking.
- **This task goes first among the corpus rewrites (FR-6):** the settled term set decides, for every
  other doc, whether a term is kept and defined or replaced. Tasks 007 through 013 depend on it.
- Verify per SPEC.md `#### Flow D` before handing off: capture the baseline with
  `git show <work-base-commit>:.aid/knowledge/domain-glossary.md`, assert set equality on fenced
  code-block bodies, inline-code spans, link targets, and `sources:` entries, assert table-cell and
  row-count survival, and attach the numbered claim ledger to the handoff note.
- Depends on task-004 so the rewrite is written against the tightened rule it will be graded by, and
  on task-001 for the dispositions.

**Acceptance Criteria:**
- [ ] The Flow D invariant diff against the base-commit version shows equal sorted sets for fenced
      code-block bodies, inline-code spans, link targets, and `sources:` entries; every table row's
      inline-code and enum cells survive with the same value; no table loses rows (AC-1).
- [ ] The handoff note carries the numbered claim ledger with every before-version claim marked
      `present`, and any `absent`/`scope-changed` entry justified as a pure wording change (AC-1).
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --root . --check frontmatter` emits no
      `[LANG-FRONTMATTER]` line for `domain-glossary.md`: `objective:` is one line of <= 25 words and
      `summary:` is <= 2 sentences of <= 30 words each with <= 1 em-dash (AC-4).
- [ ] `wc -w .aid/knowledge/domain-glossary.md` is at most 7752 words (115% of the 6741 baseline)
      (AC-6).
- [ ] Every `define` and `alias` disposition in `notes/term-inventory.md` is present in the rewritten
      glossary as a `### ` heading or an `**Aliases:**` value, and running
      `kb-language-lint.sh --root . --check glossary` no longer reports any of those terms (AC-2).
- [ ] Every shouted code appearing in this doc is expanded on first occurrence or resolves to a named
      legend or glossary entry (AC-3).
- [ ] `.aid/knowledge/.glossary-dismissed.txt` exists; every non-blank, non-comment line carries
      exactly one bare term immediately preceded by a `#` comment line stating its reason; no term
      listed there also carries a `domain-glossary.md` definition (AC-14).
- [ ] `bash canonical/aid/scripts/kb/lint-frontmatter.sh` and
      `bash canonical/aid/scripts/kb/kb-citation-lint.sh` over `.aid/knowledge/` both exit 0 with no
      `[FM-MISSING]`, `[FM-INVALID]`, or positional-citation finding (AC-10).
- [ ] `grep -rE 'work-[0-9]{3}' .aid/knowledge/domain-glossary.md
      .aid/knowledge/.glossary-dismissed.txt` returns no match (AC-11).
- [ ] All section-6 quality gates pass.
