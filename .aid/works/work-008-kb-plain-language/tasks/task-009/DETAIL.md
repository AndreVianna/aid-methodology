# task-009: Rewrite the platform and standards docs -- technology-stack, infrastructure, coding-standards

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
- Rewrite the prose and the `objective:`/`summary:` frontmatter of three docs, in plain language,
  changing no fact, contract, enum, table row, path, command, or citation:
  `.aid/knowledge/technology-stack.md` (1652 words), `infrastructure.md` (2290),
  `coding-standards.md` (2252).
- **Grouping rationale:** these three describe the toolchain the project runs on and the rules code
  written against it must follow -- declared tools and commands, the environment they run in, and the
  conventions they are held to. They are the three smallest primary docs after `technology-stack.md`
  and are read together by anyone touching a script, so one batch keeps command names and tool names
  worded identically across all three. Total 6194 words, the smallest of the six rewrite batches; it
  is kept separate rather than merged so it can be reviewed in one sitting alongside the larger
  batches running in parallel.
- Apply the task-001 dispositions verbatim; resolve every shouted code appearing in these docs by
  expanding on first occurrence or pointing at a named legend or glossary entry.
- Treat every declared tool name, command line, version constraint, and exit code as an inline-code
  invariant -- `technology-stack.md`'s declared-tool list is what AC-13 is checked against, so a
  reworded tool name would break a different criterion.
- Verify per SPEC.md `#### Flow D` **per doc** before handing off, and attach one numbered claim ledger
  per doc to the handoff note.
- `INDEX.md` is not touched here -- task-014 regenerates it once, after every doc's frontmatter is
  final.

**Acceptance Criteria:**
- [ ] For each of the three docs, the Flow D invariant diff against the base-commit version shows equal
      sorted sets for fenced code-block bodies, inline-code spans, link targets, and `sources:`
      entries; every table row's inline-code and enum cells survive with the same value; no table
      loses rows (AC-1).
- [ ] The handoff note carries one numbered claim ledger per doc with every before-version claim marked
      `present`, and any `absent`/`scope-changed` entry justified as a pure wording change (AC-1).
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --root . --check frontmatter` emits no
      `[LANG-FRONTMATTER]` line for any of the three docs (AC-4).
- [ ] `wc -w` is at most: `technology-stack.md` 1900, `infrastructure.md` 2634,
      `coding-standards.md` 2590 -- 115% of each REQUIREMENTS.md §4 baseline (AC-6).
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --root . --check glossary` reports no
      `[GLOSSARY-GAP]` line naming any of these three docs (AC-2).
- [ ] `technology-stack.md`'s declared tool set is unchanged token for token, so the AC-13
      no-new-dependency check still reads against the same list (AC-1, AC-13).
- [ ] Every shouted code's first occurrence in each doc is expanded inline or resolves to a named
      legend or glossary entry (AC-3).
- [ ] `bash canonical/aid/scripts/kb/lint-frontmatter.sh` and
      `bash canonical/aid/scripts/kb/kb-citation-lint.sh` over `.aid/knowledge/` both exit 0 (AC-10).
- [ ] `grep -rE 'work-[0-9]{3}'` over the three docs returns no match (AC-11).
- [ ] All section-6 quality gates pass.
