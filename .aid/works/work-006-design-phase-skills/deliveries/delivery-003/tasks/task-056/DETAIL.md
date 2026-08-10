# task-056: Nine planning-artifact descriptions -- roadmap, backlog, mvp

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-056/STATE.md.
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

**Depends on:** task-055

**Scope:**
- Source: REQUIREMENTS **AC-12** (cited, not restated), **FR-1**'s three-verb table, and FR-11
  **CC-5** -- the region-owning rule that `/aid-*-mvp` must keep visible in its own description.
- **Slice 5 of 7.** The nine planning-artifact skills delivery-001 authored:
  `aid-design-roadmap`, `aid-create-roadmap`, `aid-update-roadmap`, `aid-design-backlog`,
  `aid-create-backlog`, `aid-update-backlog`, `aid-design-mvp`, `aid-create-mvp`,
  `aid-update-mvp`.
- **These nine are the reason AC-12 is in this work rather than deferred.** They were authored in
  delivery-001 against FR-1 and CC-5, before AC-12 existed, so they carry the same
  internals-first shape as the rest of the roster. REQUIREMENTS §4's AC-12 bullet states the
  consequence of deferring: they would ship carrying the defect and need retrofitting.
- **The rewrite is a template instantiated three times per artifact, not nine authoring decisions.**
  All three verbs share one contract, so each description states the stage's outcome, the
  destination, and the trigger. What differs per verb is exactly what FR-1's table differs on: the
  `design` stage writes only within `.aid/design/`, `create` is the realization event that consumes
  the seed and writes the Knowledge Base document, `update` maintains what exists and consumes a
  seed when one is present (CC-3).
- **`/aid-create-mvp` and `/aid-update-mvp` carry a routing clause CC-5 makes load-bearing**, not
  decorative: `/aid-*-mvp` owns the `## MVP` section of `roadmap.md` and never creates the document,
  so `/aid-create-mvp` against an absent `roadmap.md` routes to `/aid-create-roadmap` **by name**.
  That name is the observable half of CC-5 and delivery-001 closed on it. It must survive the
  rewrite.
- **What a rewrite may not silently drop.** Every neighbour name carried as a negative route under
  FR-11 **CC-9**, plus the `/aid-create-roadmap` route above. Compare each description's set of
  `/aid-` names before and after against `HEAD`, not `master` -- these nine do not exist on `master`
  at all, so a `master` baseline has nothing to compare and would report every name as an addition.
- **Do not restate a cross-feature contract inside a description.** FR-11's governing rule is
  *refer, never restate*, and a description is exactly where a restated rule would drift invisibly.
  Name the neighbour and the destination; do not reproduce the region-ownership rule's text.
- Out of scope: `SKILL.md` body size, `argument-hint` placement and self-containment (REQUIREMENTS
  §4's AC-12 bullet); the other six slices; the twelve foundation descriptions, which are task-057's;
  and the whole-roster verification (task-072).

**Acceptance Criteria:**
- [ ] **AC-12 checks 1, 2 and 4 over the nine.** Each extracted `description:` block is
      **<= 1024** characters, contains no `Direct-entry Lite-path shortcut`, no `VERB=`, no
      `ARTIFACT=` and no arrow-separated state transition sequence, and names the user-facing outcome
      before any AID-internal vocabulary (a reviewer read, all nine quoted in full)
- [ ] **Every one of the nine states when to use the skill**, in AC-12's imperative form, and the
      trigger distinguishes its **stage** from the other two verbs on the same artifact -- which is
      the whole reason three skills exist per artifact rather than one. Recorded per skill with the
      clause quoted
- [ ] **The three `design` descriptions still state that they write only within `.aid/design/`** and
      never touch the Knowledge Base (FR-1's `design` row); the three `create` descriptions still
      state that they consume the seed and write the Knowledge Base document; the three `update`
      descriptions still state that they consume a seed when one is present and never require one
      (CC-3). A reviewer read, quoted per skill
- [ ] **CC-5's route survives by name.**
      `grep -c '/aid-create-roadmap' canonical/skills/aid-create-mvp/SKILL.md` over the extracted
      description block captured to a variable is `>= 1`, and the description still says the skill
      writes only the `## MVP` section rather than the document
- [ ] **No negative route was lost.** For each of the nine, the sorted set of `/aid-`-prefixed names
      in the description is compared with the same set from
      `git show HEAD:canonical/skills/<name>/SKILL.md`; every difference is an addition or a removal
      recorded with its reason
- [ ] **No cross-feature contract is restated.** No description reproduces the text of an FR-11
      contract -- a reviewer read against FR-11's *refer, never restate* rule, recorded as a verdict
      rather than as a grep
- [ ] **Only the nine moved.** `git diff --name-only HEAD -- canonical/skills/` at the end of this
      task lists exactly the nine `SKILL.md` files this slice owns
- [ ] **Frontmatter shape is intact on all nine** -- block delimiters, all four keys, `name:` equal
      to the directory -- with `tests/canonical/test-frontmatter-lint.sh` and
      `tests/canonical/test-catalog-dirs-parity.sh` green and the latter unmodified
- [ ] Accuracy verified against the current codebase: every path cited in this task's record is
      re-resolved against the tree as it stands
- [ ] Nothing outside the declared writes moves:
      `git diff --exit-code -- tests/ site/ canonical/aid/templates/ docs/ .aid/knowledge/` is
      clean, and `git status --porcelain profiles/ .claude/ .cursor/` is unchanged from its state at
      the start of this task
- [ ] All section-6 quality gates pass
