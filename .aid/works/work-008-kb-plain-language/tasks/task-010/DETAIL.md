# task-010: Rewrite the verification docs -- test-landscape, quality-gates

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
- Rewrite the prose and the `objective:`/`summary:` frontmatter of two docs, in plain language,
  changing no fact, contract, enum, table row, path, command, or citation:
  `.aid/knowledge/test-landscape.md` (5125 words) and `quality-gates.md` (3052, extension).
- **Grouping rationale:** these two are the verification concern -- what the project tests and how,
  and which gates a change must clear. `quality-gates.md` names gates that `test-landscape.md`
  describes the suites for, so the two must use one vocabulary for suite names, gate names, and the
  S-convention codes. Total 8177 words. `test-landscape.md` also carries the single worst frontmatter
  defect REQUIREMENTS.md §2 cites (a ~90-word `summary:` with six em-dash asides), which makes this
  batch the AC-4 showcase.
- Apply the task-001 dispositions verbatim; resolve the S1-S5 and T1-T6 code families that cluster
  here by expanding each on first occurrence or pointing at a named legend, and keep the code tokens
  themselves intact so other docs' references still resolve.
- Verify per SPEC.md `#### Flow D` **per doc** before handing off, and attach one numbered claim ledger
  per doc to the handoff note.
- `INDEX.md` is not touched here -- task-014 regenerates it once, after every doc's frontmatter is
  final.

**Acceptance Criteria:**
- [ ] For both docs, the Flow D invariant diff against the base-commit version shows equal sorted sets
      for fenced code-block bodies, inline-code spans, link targets, and `sources:` entries; every
      table row's inline-code and enum cells survive with the same value; no table loses rows (AC-1).
- [ ] The handoff note carries one numbered claim ledger per doc with every before-version claim marked
      `present`, and any `absent`/`scope-changed` entry justified as a pure wording change (AC-1).
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --root . --check frontmatter` emits no
      `[LANG-FRONTMATTER]` line for either doc -- specifically none for `test-landscape.md`'s
      `summary:`, which must now be <= 2 sentences of <= 30 words each with <= 1 em-dash (AC-4).
- [ ] `wc -w` is at most: `test-landscape.md` 5894, `quality-gates.md` 3510 -- 115% of each
      REQUIREMENTS.md §4 baseline (AC-6).
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --root . --check glossary` reports no
      `[GLOSSARY-GAP]` line naming either doc (AC-2).
- [ ] Every `S1`-`S5` and `T1`-`T6` code, and every other shouted code in these two docs, is expanded
      on its first occurrence in the doc or resolves to a named legend, with the code token itself
      unchanged (AC-3, AC-1).
- [ ] `bash canonical/aid/scripts/kb/lint-frontmatter.sh` and
      `bash canonical/aid/scripts/kb/kb-citation-lint.sh` over `.aid/knowledge/` both exit 0 (AC-10).
- [ ] `grep -rE 'work-[0-9]{3}'` over both docs returns no match (AC-11).
- [ ] All section-6 quality gates pass.
