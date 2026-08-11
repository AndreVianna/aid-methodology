# task-013: Rewrite authoring-conventions.md and mirror the tightened rule into the KB

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

**Type:** DOCUMENT

**Source:** work-008-kb-plain-language -> delivery-001

**Depends on:** task-004, task-006

**Scope:**
- Rewrite the prose and the `objective:`/`summary:` frontmatter of
  `.aid/knowledge/authoring-conventions.md` (2386 words) in plain language, and mirror the tightened
  rule into it: § Dual-Audience Standard states the tightened plain-language and glossary-coverage
  rule, and § Enforcement gains rows for `kb-language-lint.sh` (Automatic: Yes) and for the two
  reviewer tags (Automatic: No), naming the same severities the canonical rubric assigns.
- **Why this doc is typed DOCUMENT rather than REFACTOR, and why it is its own task:** the mirrored
  rule is a deliberate new assertion in the KB, so this doc is the one in-scope doc whose knowledge
  intentionally changes. Batching it with a REFACTOR group would put a knowledge-adding edit inside a
  knowledge-preserving task and make the AC-1 check ambiguous for the whole batch.
- The rewrite half still preserves knowledge: apart from the mirrored rule, every fact, contract,
  table row, path, command, and citation survives unchanged.
- Apply the task-001 dispositions verbatim and resolve every shouted code appearing in the doc.
- Carry the pre-existing contradiction forward untouched: § KB Document Layout keeps requiring
  `## Change Log` as the last section even though `principles.md` P10 Layout says a KB doc has none.
  Resolving that belongs to a separate work (REQUIREMENTS.md §8).
- Depends on task-004 so the mirror names the same script, tags, and severities as the canonical rule,
  and on task-006 so it uses the settled term set.
- `INDEX.md` is not touched here -- task-014 regenerates it once, after every doc's frontmatter is
  final.

**Acceptance Criteria:**
- [ ] § Dual-Audience Standard states the tightened plain-language and glossary-coverage rule and names
      `kb-language-lint.sh` as its mechanism, matching `principles.md` P10 § Language with no
      contradiction (AC-8).
- [ ] § Enforcement lists `kb-language-lint.sh` with Automatic: Yes, and `[AUTHORING-CLARITY]` and
      `[AUTHORING-CODE]` with Automatic: No; all four tags (`[GLOSSARY-GAP]`, `[LANG-FRONTMATTER]`,
      `[AUTHORING-CLARITY]`, `[AUTHORING-CODE]`) carry the same severity here as in
      `canonical/aid/templates/kb-authoring/review-rubric.md` § Lint output -> severity mapping (AC-8).
- [ ] The Flow D invariant diff against the base-commit version shows equal sorted sets for fenced
      code-block bodies, inline-code spans, link targets, and `sources:` entries, and no table loses
      rows -- with the mirrored-rule additions as the only new assertions, each enumerated in the
      handoff note (AC-1).
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --root . --check frontmatter` emits no
      `[LANG-FRONTMATTER]` line for `authoring-conventions.md` (AC-4).
- [ ] `wc -w .aid/knowledge/authoring-conventions.md` is at most 2744 words (115% of the 2386
      baseline), the mirrored rule included (AC-6).
- [ ] `bash canonical/aid/scripts/kb/kb-language-lint.sh --root . --check glossary` reports no
      `[GLOSSARY-GAP]` line naming `authoring-conventions.md` (AC-2).
- [ ] Every shouted code's first occurrence in the doc is expanded inline or resolves to a named legend
      or glossary entry (AC-3).
- [ ] The `## Change Log` contradiction with `principles.md` P10 Layout is still present and is noted
      in the handoff as deliberately carried forward (AC-1).
- [ ] `bash canonical/aid/scripts/kb/lint-frontmatter.sh` and
      `bash canonical/aid/scripts/kb/kb-citation-lint.sh` over `.aid/knowledge/` both exit 0 (AC-10).
- [ ] `grep -rE 'work-[0-9]{3}' .aid/knowledge/authoring-conventions.md` returns no match (AC-11).
- [ ] All section-6 quality gates pass.
