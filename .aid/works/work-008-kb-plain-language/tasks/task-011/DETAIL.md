# task-011: Rewrite tech-debt.md

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

**Depends on:** task-006

**Scope:**
- Rewrite the prose and the `objective:`/`summary:` frontmatter of `.aid/knowledge/tech-debt.md`
  (9674 words) in plain language, changing no fact, contract, enum, table row, path, command, or
  citation.
- **Grouping rationale:** this doc gets a task of its own on size alone. At 9674 words it is 43%
  larger than the next-largest doc and larger than an entire rewrite batch (task-009 is 6194 words);
  pairing it with anything would produce a batch no reviewer could hold in one pass. It is also the
  densest carrier of per-item debt rows, each of which is an independent factual claim, so its AC-1
  claim ledger is the longest in the work.
- Apply the task-001 dispositions verbatim; resolve every shouted code appearing in the doc by
  expanding on first occurrence or pointing at a named legend or glossary entry.
- Carry pre-existing factual defects forward untouched (REQUIREMENTS.md §8): a debt item that is stale
  or wrong stays stale or wrong. Correcting a fact during a wording refactor would itself break AC-1.
- Verify per SPEC.md `#### Flow D` before handing off: baseline from
  `git show <work-base-commit>:.aid/knowledge/tech-debt.md`, invariant set equality, table-cell and
  row-count survival, and the numbered claim ledger attached to the handoff note.
- `INDEX.md` is not touched here -- task-014 regenerates it once, after every doc's frontmatter is
  final.

**Acceptance Criteria:**
- [ ] The Flow D invariant diff against the base-commit version shows equal sorted sets for fenced
      code-block bodies, inline-code spans, link targets, and `sources:` entries; every table row's
      inline-code and enum cells survive with the same value; no table loses rows -- in particular the
      debt-item table's row count is identical (AC-1).
- [ ] The handoff note carries the numbered claim ledger with every before-version claim marked
      `present`, and any `absent`/`scope-changed` entry justified as a pure wording change (AC-1).
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --root . --check frontmatter` emits no
      `[LANG-FRONTMATTER]` line for `tech-debt.md` (AC-4).
- [ ] `wc -w .aid/knowledge/tech-debt.md` is at most 11125 words (115% of the 9674 baseline) (AC-6).
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --root . --check glossary` reports no
      `[GLOSSARY-GAP]` line naming `tech-debt.md` (AC-2).
- [ ] Every shouted code's first occurrence in the doc is expanded inline or resolves to a named legend
      or glossary entry (AC-3).
- [ ] No debt item is added, removed, re-scoped, or corrected: the handoff note states explicitly that
      every pre-existing factual defect was carried forward (AC-1, REQUIREMENTS.md §8).
- [ ] `bash canonical/aid/scripts/kb/lint-frontmatter.sh` and
      `bash canonical/aid/scripts/kb/kb-citation-lint.sh` over `.aid/knowledge/` both exit 0 (AC-10).
- [ ] `grep -rE 'work-[0-9]{3}' .aid/knowledge/tech-debt.md` returns no match -- this doc is the most
      likely to have cited a work folder (AC-11).
- [ ] All section-6 quality gates pass.
