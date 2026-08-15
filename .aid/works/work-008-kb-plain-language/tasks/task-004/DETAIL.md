# task-004: Tighten the canonical KB-authoring rule set and the reviewer rubric

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

**Depends on:** task-002

**Scope:**
- `canonical/aid/templates/kb-authoring/principles.md`: rewrite P10 § Language so the plain-language
  and define-on-first-use expectations read as stated, checked conditions naming
  `kb-language-lint.sh` and the two reviewer tags; add to P4 ("enforce via review, not by mechanical
  lint") the narrow carve-out this work creates, so P4 and the new script do not contradict.
- `canonical/aid/templates/kb-authoring/review-rubric.md`: add two checks to § Rubric: Full Primary
  -- reading level (`[AUTHORING-CLARITY]`, MEDIUM) and shouted-code resolvability
  (`[AUTHORING-CODE]`, MEDIUM); add four rows to § Lint output -> severity mapping --
  `[GLOSSARY-GAP]` HIGH, `[LANG-FRONTMATTER]` HIGH, `[AUTHORING-CLARITY]` MEDIUM,
  `[AUTHORING-CODE]` MEDIUM. The two MEDIUM rows carry an explicit severity prefix, per that table's
  own standing rule that a non-HIGH lint tag never ships bare.
- `canonical/aid/templates/kb-authoring/frontmatter-schema.md`: record the readability bounds for
  `objective:` and `summary:` next to the existing shape rules. **No new field** -- the bounds
  constrain the content of the existing scalars, not the schema's shape.
- `canonical/skills/aid-discover/references/reviewer-prompt-anatomy.md`: point the Authoring Standard
  checklist's item 15 at the rubric as the source of truth, add the shouted-code check, and add both
  tags to the severity-anchor list.
- `canonical/skills/aid-discover/references/document-expectations.md`: state the plain-language and
  glossary-coverage expectation where the per-doc expectations live.
- Depends on task-002 so the prose names the script, flags, tags, and exit codes as actually shipped
  rather than as planned.
- Explicitly **not** in scope here: `state-review.md`'s oracle list and the `kb-hygiene` CI step
  (task-005 owns both), `.aid/knowledge/authoring-conventions.md` (task-013 owns the KB mirror), the
  `profiles/` render (task-014 owns it), and any style sweep of the surrounding
  `canonical/skills/**` prose (out of scope per REQUIREMENTS.md §4).

**Acceptance Criteria:**
- [ ] `principles.md` P10 § Language states the plain-language and define-on-first-use rule as a
      checked condition and names `kb-language-lint.sh`, `[GLOSSARY-GAP]`, `[LANG-FRONTMATTER]`,
      `[AUTHORING-CLARITY]`, and `[AUTHORING-CODE]`; P4 carries a carve-out that names this lint as
      the exception, so a side-by-side read of P4 and P10 shows no contradiction (AC-8).
- [ ] `review-rubric.md` § Rubric: Full Primary contains a reading-level check and a shouted-code
      resolvability check, each naming its tag and severity (AC-3).
- [ ] `review-rubric.md` § Lint output -> severity mapping contains exactly the four new rows with
      the severities `[GLOSSARY-GAP]` HIGH, `[LANG-FRONTMATTER]` HIGH, `[AUTHORING-CLARITY]` MEDIUM,
      `[AUTHORING-CODE]` MEDIUM, and each MEDIUM row carries its explicit severity prefix.
- [ ] `frontmatter-schema.md` records the bounds -- `objective:` one line of <= 25 words; `summary:`
      <= 2 sentences of <= 30 words each with <= 1 em-dash -- and `git diff` shows no field added to
      the schema's required or optional field lists.
- [ ] `reviewer-prompt-anatomy.md` item 15 defers to the rubric, a shouted-code check is present, and
      both new tags appear in the severity-anchor list.
- [ ] `document-expectations.md` states the plain-language and glossary-coverage expectation for the
      primary and extension doc sets.
- [ ] Every flag, tag, and exit code named in the edited prose matches the shipped
      `kb-language-lint.sh` (grep each named token against the script; no drift).
- [ ] `git status --porcelain -- profiles/` prints nothing: no hand edit reached the render (AC-9's
      precondition; task-014 runs the generator).
- [ ] `bash tests/canonical/test-ascii-only.sh` passes over the edited canonical files.
- [ ] All section-6 quality gates pass.
