# task-007: Rewrite the system-shape docs -- architecture, module-map, project-structure, integration-map

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
- Rewrite the prose and the `objective:`/`summary:` frontmatter of four docs, in plain language,
  changing no fact, contract, enum, table row, path, command, or citation:
  `.aid/knowledge/architecture.md` (4127 words), `module-map.md` (4193), `project-structure.md`
  (2505), `integration-map.md` (2720).
- **Grouping rationale:** these four are one concern cluster -- they describe the shape of the system
  (its layers, its modules, its directory layout, and its external seams) and cross-reference each
  other constantly, so the same term choices and the same level of abstraction must land in all four
  at once. Splitting them would let the same coined term be resolved two different ways in two
  neighbouring docs. Total 13545 words, the largest of the six rewrite batches, balanced against
  batches of 12193 (task-008) and 9674 (task-011).
- Apply the task-001 dispositions verbatim: retained terms use the wording task-006 defined, replaced
  terms use the proposed plain wording, and no term is resolved a second, different way here.
- Resolve the shouted bare codes appearing in these four docs -- expand on first occurrence in the
  doc or point at a named legend or glossary entry.
- Verify per SPEC.md `#### Flow D` **per doc** before handing off: baseline from
  `git show <work-base-commit>:.aid/knowledge/<doc>.md`, invariant set equality, table-cell and
  row-count survival, and a numbered claim ledger attached to the handoff note.
- `INDEX.md` is not touched here -- it is regenerated once, by task-014, after every doc's frontmatter
  is final.

**Acceptance Criteria:**
- [ ] For each of the four docs, the Flow D invariant diff against the base-commit version shows equal
      sorted sets for fenced code-block bodies, inline-code spans, link targets, and `sources:`
      entries; every table row's inline-code and enum cells survive with the same value; no table
      loses rows (AC-1).
- [ ] The handoff note carries one numbered claim ledger per doc with every before-version claim
      marked `present`, and any `absent`/`scope-changed` entry justified as a pure wording change
      (AC-1).
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --root . --check frontmatter` emits no
      `[LANG-FRONTMATTER]` line for any of the four docs -- specifically none for `architecture.md`'s
      `objective:`, which REQUIREMENTS.md §2 cites as the worst case (AC-4).
- [ ] `wc -w` is at most: `architecture.md` 4746, `module-map.md` 4822, `project-structure.md` 2881,
      `integration-map.md` 3128 -- 115% of each REQUIREMENTS.md §4 baseline (AC-6).
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --root . --check glossary` reports no
      `[GLOSSARY-GAP]` line naming any of these four docs (AC-2).
- [ ] Every shouted code's first occurrence in each of the four docs is expanded inline or resolves to
      a named legend or glossary entry (AC-3).
- [ ] `bash canonical/aid/scripts/kb/lint-frontmatter.sh` and
      `bash canonical/aid/scripts/kb/kb-citation-lint.sh` over `.aid/knowledge/` both exit 0 (AC-10).
- [ ] `grep -rE 'work-[0-9]{3}'` over the four docs returns no match (AC-11).
- [ ] All section-6 quality gates pass.
