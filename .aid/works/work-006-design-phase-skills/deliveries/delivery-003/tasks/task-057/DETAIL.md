# task-057: Twelve foundation-artifact descriptions -- architecture, stack, testing strategy, ci/cd

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-057/STATE.md.
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

**Type:** DOCUMENT

**Source:** work-006-design-phase-skills -> delivery-003

**Depends on:** task-056

**Scope:**
- Source: REQUIREMENTS **AC-12** (cited, not restated), **FR-2**, and FR-11 **CC-6** -- the rule that
  a foundation destination resolves by **concern**, not by filename, which is what these twelve
  descriptions must not contradict.
- **Slice 6 of 7.** The twelve foundation-artifact skills delivery-002 authored:
  `aid-design-architecture`, `aid-create-architecture`, `aid-update-architecture`,
  `aid-design-stack`, `aid-create-stack`, `aid-update-stack`, `aid-design-testing-strategy`,
  `aid-create-testing-strategy`, `aid-update-testing-strategy`, `aid-design-cicd`,
  `aid-create-cicd`, `aid-update-cicd`.
- **CC-6 constrains the wording, and it is the one place a well-meant rewrite does real damage.** A
  description that names a concrete destination filename would be correct in a minority of domains --
  `test-landscape.md` appears in only two of the eight domain sections. So the trigger states the
  **concern** the skill settles (the architecture, the technology stack, the testing standard, the
  CI/CD pipeline) and, where a destination is mentioned at all, says it is resolved from the
  project's own document set. Hardcoding a filename into a description would put a false statement
  in the single place an agent reads to decide whether the skill loads.
- **`/aid-design-stack`, `/aid-design-testing-strategy` and `/aid-design-cicd` are three of the
  counterpart names feature-005 needed from feature-004**, and bare `/aid-design`'s narrowing (edited
  by delivery-002's task-028, and re-asserted in task-055 of this delivery) names them as the routes
  away from itself. The reverse direction lives in these descriptions. Dropping a name here breaks a
  pair delivery-002's task-049 already closed as mutual.
- **The four `create` descriptions carry the brownfield contract, and it is not cosmetic.**
  REQUIREMENTS FR-1's region rule and AC-6b make a populated destination the **normal** case: these
  four must not read as though they refuse when their destination already carries content. They
  refuse only when their **own owned region** does, and route to the matching `update` skill by
  name.
- **The four `update` descriptions carry CC-3**: they consume a `.aid/design/` seed when one is
  present and never require one.
- **What a rewrite may not silently drop.** Every neighbour name carried as a negative route under
  FR-11 **CC-9**, plus the `update`-skill routes the `create` descriptions name. Compare against
  `HEAD`, not `master` -- these twelve do not exist on `master`.
- Out of scope: `SKILL.md` body size, `argument-hint` placement and self-containment (REQUIREMENTS
  §4's AC-12 bullet); the other six slices; and the whole-roster verification (task-072).

**Acceptance Criteria:**
- [ ] **AC-12 checks 1, 2 and 4 over the twelve.** Each extracted `description:` block is
      **<= 1024** characters, contains no `Direct-entry Lite-path shortcut`, no `VERB=`, no
      `ARTIFACT=` and no arrow-separated state transition sequence, and names the user-facing outcome
      before any AID-internal vocabulary (a reviewer read, all twelve quoted in full)
- [ ] **Every one of the twelve states when to use the skill**, in AC-12's imperative form, and the
      trigger distinguishes its stage from the other two verbs on the same artifact. Recorded per
      skill with the clause quoted
- [ ] **CC-6 is not contradicted: no description hardcodes a destination filename.** For each of the
      twelve, the extracted description block contains none of `architecture.md`,
      `technology-stack.md`, `test-landscape.md`, `quality-gates.md` or `infrastructure.md` -- and
      where a destination is referred to at all, it is referred to as one resolved from the project's
      own document set. A reviewer read, recorded as a verdict alongside the grep
- [ ] **The three counterpart names bare `/aid-design` routes to still name it back.** For each of
      `aid-design-stack`, `aid-design-testing-strategy` and `aid-design-cicd`,
      `grep -c '/aid-design\b'` over the extracted description block captured to a variable is
      `>= 1`, anchored so `/aid-design-stack` does not satisfy its own assertion
- [ ] **The brownfield reading survives on all four `create` descriptions.** None of
      `aid-create-architecture`, `aid-create-stack`, `aid-create-testing-strategy` or
      `aid-create-cicd` reads as refusing on a populated destination document, and each names its
      matching `/aid-update-*` skill as the route when its own owned region already carries committed
      content. A reviewer read, quoted per skill -- this is REQUIREMENTS AC-6b's premise, and the
      description is where a reader forms it
- [ ] **CC-3 survives on all four `update` descriptions**: each still states that it consumes a
      `.aid/design/` seed when one is present and never requires one. A reviewer read, quoted per
      skill
- [ ] **No negative route was lost.** For each of the twelve, the sorted set of `/aid-`-prefixed
      names in the description is compared with the same set from
      `git show HEAD:canonical/skills/<name>/SKILL.md`; every difference is an addition or a removal
      recorded with its reason
- [ ] **Only the twelve moved.** `git diff --name-only HEAD -- canonical/skills/` at the end of this
      task lists exactly the twelve `SKILL.md` files this slice owns
- [ ] **Frontmatter shape is intact on all twelve** -- block delimiters, all four keys, `name:` equal
      to the directory -- with `tests/canonical/test-frontmatter-lint.sh` and
      `tests/canonical/test-catalog-dirs-parity.sh` green and the latter unmodified
- [ ] Accuracy verified against the current codebase: every path cited in this task's record is
      re-resolved against the tree as it stands
- [ ] Nothing outside the declared writes moves:
      `git diff --exit-code -- tests/ site/ canonical/aid/templates/ docs/ .aid/knowledge/` is
      clean, and `git status --porcelain profiles/ .claude/ .cursor/` is unchanged from its state at
      the start of this task
- [ ] All section-6 quality gates pass
