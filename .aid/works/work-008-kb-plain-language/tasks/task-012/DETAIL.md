# task-012: Rewrite the decision and release ledger docs -- decisions, release-tracking

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
- Rewrite the prose and the `objective:`/`summary:` frontmatter of two extension docs, in plain
  language, changing no fact, contract, enum, table row, path, command, or citation:
  `.aid/knowledge/decisions.md` (4856 words) and `release-tracking.md` (4942).
- **Grouping rationale:** both are append-structured ledgers -- one row or entry per recorded decision
  or release -- rather than expository docs, so they need the same rewriting technique: reword the
  rationale prose inside an entry while leaving every entry's identity, date, version, and outcome
  token untouched. Grouping them keeps that technique consistent and keeps the AC-1 row-count check
  identical for both. Total 9798 words, balanced against task-011's 9674.
- Apply the task-001 dispositions verbatim; resolve every shouted code appearing in these docs
  (`P1`/`P9`/`P10`, `C0`-`C9`, and the decision-status tokens cluster here) by expanding on first
  occurrence or pointing at a named legend or glossary entry, keeping the tokens themselves intact.
- Every version string, date, decision id, and status value is an invariant. A ledger entry may be
  reworded; it may never be merged, split, reordered, or re-dated.
- Verify per SPEC.md `#### Flow D` **per doc** before handing off, and attach one numbered claim ledger
  per doc to the handoff note.
- `INDEX.md` is not touched here -- task-014 regenerates it once, after every doc's frontmatter is
  final.

**Acceptance Criteria:**
- [ ] For both docs, the Flow D invariant diff against the base-commit version shows equal sorted sets
      for fenced code-block bodies, inline-code spans, link targets, and `sources:` entries; every
      table row's inline-code and enum cells survive with the same value; no table loses rows (AC-1).
- [ ] Entry counts are identical before and after in both docs, and every decision id, version string,
      date, and status token is byte-identical -- no entry merged, split, reordered, or re-dated
      (AC-1).
- [ ] The handoff note carries one numbered claim ledger per doc with every before-version claim marked
      `present`, and any `absent`/`scope-changed` entry justified as a pure wording change (AC-1).
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --root . --check frontmatter` emits no
      `[LANG-FRONTMATTER]` line for either doc (AC-4).
- [ ] `wc -w` is at most: `decisions.md` 5584, `release-tracking.md` 5683 -- 115% of each
      REQUIREMENTS.md §4 baseline (AC-6).
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --root . --check glossary` reports no
      `[GLOSSARY-GAP]` line naming either doc (AC-2).
- [ ] Every shouted code's first occurrence in each doc is expanded inline or resolves to a named legend
      or glossary entry (AC-3).
- [ ] `bash canonical/aid/scripts/kb/lint-frontmatter.sh` and
      `bash canonical/aid/scripts/kb/kb-citation-lint.sh` over `.aid/knowledge/` both exit 0 (AC-10).
- [ ] `grep -rE 'work-[0-9]{3}'` over both docs returns no match -- ledger docs are the likeliest place
      a work id was cited as provenance (AC-11).
- [ ] All section-6 quality gates pass.
