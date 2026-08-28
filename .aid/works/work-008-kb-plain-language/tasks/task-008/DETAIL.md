# task-008: Rewrite the contract and capability docs -- artifact-schemas, pipeline-contracts, capability-inventory

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
  `.aid/knowledge/artifact-schemas.md` (5081 words), `pipeline-contracts.md` (4309),
  `capability-inventory.md` (2803).
- **Grouping rationale:** these three are the contract layer -- the artifact schemas, the phase
  contracts between pipeline states, and the capability set those contracts expose. They are the
  densest carriers of enums, field names, and required-section lists in the whole KB, so they share
  the highest AC-1 risk and benefit from one reviewer holding the whole contract surface at once.
  Total 12193 words.
- Apply the task-001 dispositions verbatim; resolve every shouted code appearing in these docs
  (`CONFIRMED`, `S1-S5`, `T1-T6`, `C0`-`C9`, `APPROVAL-HALT` cluster heavily here) by expanding on
  first occurrence or pointing at a named legend or glossary entry.
- Treat every enum value, required-section name, and exit code as an inline-code invariant: reword the
  surrounding sentence, never the token.
- Verify per SPEC.md `#### Flow D` **per doc** before handing off, and attach one numbered claim
  ledger per doc to the handoff note.
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
- [ ] `wc -w` is at most: `artifact-schemas.md` 5843, `pipeline-contracts.md` 4955,
      `capability-inventory.md` 3223 -- 115% of each REQUIREMENTS.md §4 baseline (AC-6).
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --root . --check glossary` reports no
      `[GLOSSARY-GAP]` line naming any of these three docs (AC-2).
- [ ] Every shouted code's first occurrence in each doc is expanded inline or resolves to a named
      legend or glossary entry, and no enum token was silently renamed while doing so (AC-3).
- [ ] `bash canonical/aid/scripts/kb/lint-frontmatter.sh` and
      `bash canonical/aid/scripts/kb/kb-citation-lint.sh` over `.aid/knowledge/` both exit 0 (AC-10).
- [ ] `grep -rE 'work-[0-9]{3}'` over the three docs returns no match (AC-11).
- [ ] All section-6 quality gates pass.
