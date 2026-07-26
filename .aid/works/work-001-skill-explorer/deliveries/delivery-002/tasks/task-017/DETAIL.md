# task-017: `gen-skills.test.mjs` -- the AC-1 / AC-2 / AC-6 suite

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-017. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-017/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Source:** work-001-skill-explorer -> delivery-002 (feature-001-skill-detail-pages)

**Depends on:** task-015

**Scope:**
- Author `site/scripts/__tests__/gen-skills.test.mjs`, organised like its neighbour `gen-reference.test.mjs` and run by the site's existing `npm test` -> `vitest run`. Because `gen-skills.mjs`'s modules are importable (the `import.meta.url` guard, not `gen-reference.mjs`'s module-scope `main()`), most of this is real unit testing rather than output grepping.
- Cover feature-001's nine test-layer groups: **Parser -- fixtures** (every row of the parser table as a small inline fixture string: block sequence, flow sequence, `|` literal, `>-`/`|+` chomping, blank line inside a folded block, CRLF fence, dotted and digit keys, empty value, quoted-escape forms); **Parser -- guards**; **Value rendering**; **Corpus coverage (AC-1)**; **Header completeness (AC-2)**; **Drift guard (AC-1)**; **Idempotence (AC-6)**; **Marker + manifest**; **Isolation**.
- This suite stays **separate** from `gen-reference.test.mjs` -- the two files each own one generator, and this suite's Isolation group is what asserts the two do not interfere.

**Acceptance Criteria:**
- [ ] **No assertion compares against a numeric literal**; every corpus expectation derives from the live `canonical/skills/` directory listing.
- [ ] AC-2 is tested at **fixture granularity** against the list-valued and folded-scalar cases the existing parser mishandles, driven off the parser -- not by grepping the rendered corpus -- so it stays true as the corpus changes.
- [ ] Every row of feature-001's parser table has at least one inline fixture, and every parser guard (duplicate key, unclassifiable line, missing fence, `name` mismatch) is asserted to throw with the file and line in its message.
- [ ] Value rendering is asserted in both directions: `<` and `&` escaped outside code spans, `<` inside an authored code span passing through unescaped, using a fixture drawn from `aid-read-ticket`'s real description.
- [ ] AC-1 is tested in **both directions**: one page exists for every directory, and no page exists without one. With a synthetic orphan page present, the generator throws and names it.
- [ ] AC-6 is a **byte comparison of run 1 against run 2 with no `git` dependency** -- the property AC-6 actually states, and one that survives this worktree's unresolvable `.git` pointer.
- [ ] The manifest is asserted to carry `generator`, one `entries` row per generated page, and **no `generatedAt`**.
- [ ] Isolation: the four `site/src/content/docs/reference/*.md` pages and `site/scripts/.reference-manifest.json` are byte-unchanged after `gen:skills` runs.
- [ ] Tests are deterministic, use clean setup/teardown, build their own fixtures inside the test file, and read nothing under `.aid/works/`.
- [ ] Every acceptance criterion of feature-001 in delivery-002's scope (AC-1, AC-2, AC-6) is covered by at least one assertion.
- [ ] All section-6 quality gates pass
