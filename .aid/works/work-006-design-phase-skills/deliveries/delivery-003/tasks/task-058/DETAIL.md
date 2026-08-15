# task-058: Fifteen `design` grid and `/aid-brainstorm` descriptions

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-058/STATE.md.
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

**Depends on:** task-057

**Scope:**
- Source: REQUIREMENTS **AC-12** (cited, not restated), **FR-5**, **FR-7**, and FR-11 **CC-8** --
  the rule that the fourteen grid rows are a **positive** selection and that no "unpaired artifact"
  exclusion may be asserted anywhere.
- **Slice 7 of 7, which closes the seventy-eight.** The fourteen `design` grid rows --
  `aid-design-api`, `-ui`, `-theme`, `-cli`, `-data-model`, `-data-pipeline`, `-messaging`,
  `-integration`, `-job`, `-config`, `-infra`, `-test`, `-document`, `-dashboard` -- plus
  `aid-brainstorm`.
- **The fourteen share one shape and one contract, so the rewrite is one template instantiated
  fourteen times.** Each is the `design` stage of an artifact whose `create` produces the **built
  artifact** through the shortcut engine rather than a Knowledge Base document (FR-5's two-class
  table). Each description therefore states: develop the design for this artifact, write it to
  `.aid/design/`, and hand it to the matching `/aid-create-<artifact>` -- which is FR-10's
  composition made visible.
- **`/aid-brainstorm` is authored individually and carries FR-7's pair.** It serves the case
  `/aid-research` cannot -- a problem not yet formed into a question -- and its description names
  `/aid-research` as the negative route. The reverse side lives in `aid-research`, rewritten in
  task-055. Both directions must survive; feature-006 §8a verifies the pair whole in task-072.
- **`aid-design-ui` and `aid-design-document` each carry a pair too.** `aid-design-ui` <->
  `aid-prototype-ui` is the kept-versus-throwaway distinction applied to `ui` (FR-6), and
  `aid-design-document` names **both** `aid-document` and `aid-create-document`. delivery-002's
  task-049 closed on those sides existing and being mutual; a rewrite that drops a name reopens it.
- **CC-8 constrains what may not be said.** No description may state or imply that an artifact is
  excluded because it lacks a `create`/`update` pair. The selection is stated positively wherever it
  is stated at all -- and `architecture` is the standing counter-example, since it **does** receive a
  `design` row as one of the seven design artifacts.
- **What a rewrite may not silently drop.** Every neighbour name carried as a negative route under
  FR-11 **CC-9**, plus each row's matching `/aid-create-<artifact>` hand-off. Compare against `HEAD`,
  not `master` -- these fifteen do not exist on `master`.
- Out of scope: `SKILL.md` body size, `argument-hint` placement and self-containment (REQUIREMENTS
  §4's AC-12 bullet); the generated doorways (task-051); and the whole-roster verification, which is
  task-072's and is where the pair matrix and the five AC-12 checks are reported over all 112.

**Acceptance Criteria:**
- [ ] **AC-12 checks 1, 2 and 4 over the fifteen.** Each extracted `description:` block is
      **<= 1024** characters, contains no `Direct-entry Lite-path shortcut`, no `VERB=`, no
      `ARTIFACT=` and no arrow-separated state transition sequence, and names the user-facing outcome
      before any AID-internal vocabulary (a reviewer read, all fifteen quoted in full)
- [ ] **Every one of the fifteen states when to use the skill**, in AC-12's imperative form, recorded
      per skill with the clause quoted. For the fourteen grid rows the trigger names the artifact,
      because that is the only thing distinguishing one row from the next
- [ ] **All fourteen still state the `.aid/design/`-only write and the hand-off.** For each,
      `grep -c '\.aid/design/'` over the extracted description block captured to a variable is
      `>= 1`, and the description names its matching `/aid-create-<artifact>` skill -- the visible
      half of FR-10's composition
- [ ] **FR-7's pair survives in both halves this delivery can see.**
      `grep -c '/aid-research' canonical/skills/aid-brainstorm/SKILL.md` over the extracted
      description block captured to a variable is `>= 1`, and `aid-brainstorm`'s description states
      the unformed-problem-versus-well-formed-question distinction (a reviewer read, quoted)
- [ ] **The two other pairs with a side here survive.**
      `grep -c '/aid-prototype-ui'` over `aid-design-ui`'s description block is `>= 1` and the
      kept-versus-throwaway distinction is stated; and `aid-design-document`'s description names
      **both** `/aid-document` and `/aid-create-document`
- [ ] **CC-8 is not contradicted.** `grep -rniE 'unpaired' canonical/skills/` returns **nothing**,
      and no description states or implies that an artifact is excluded for lacking a
      `create`/`update` pair (a reviewer read, recorded as a verdict)
- [ ] **No negative route was lost.** For each of the fifteen, the sorted set of `/aid-`-prefixed
      names in the description is compared with the same set from
      `git show HEAD:canonical/skills/<name>/SKILL.md`; every difference is an addition or a removal
      recorded with its reason
- [ ] **The seventy-eight are complete at this point, which is checked here rather than assumed.**
      Across all 112 `canonical/skills/*/SKILL.md` files, the count whose extracted description block
      still contains `Direct-entry Lite-path shortcut` captured to a variable -> `0`. Every one of
      the thirty-four generated descriptions was rewritten by task-051 and every one of the
      seventy-eight hand-authored by task-052 through this task, so a non-zero result names a skill
      no slice owned
- [ ] **Only the fifteen moved.** `git diff --name-only HEAD -- canonical/skills/` at the end of this
      task lists exactly the fifteen `SKILL.md` files this slice owns
- [ ] **Frontmatter shape is intact on all fifteen** -- block delimiters, all four keys, `name:`
      equal to the directory -- with `tests/canonical/test-frontmatter-lint.sh` and
      `tests/canonical/test-catalog-dirs-parity.sh` green and the latter unmodified
- [ ] Accuracy verified against the current codebase: every path cited in this task's record is
      re-resolved against the tree as it stands
- [ ] Nothing outside the declared writes moves:
      `git diff --exit-code -- tests/ site/ canonical/aid/templates/ docs/ .aid/knowledge/` is
      clean, and `git status --porcelain profiles/ .claude/ .cursor/` is unchanged from its state at
      the start of this task
- [ ] All section-6 quality gates pass
