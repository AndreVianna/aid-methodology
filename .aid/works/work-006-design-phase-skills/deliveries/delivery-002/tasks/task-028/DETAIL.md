# task-028: Four shipped descriptions narrowed and cross-routed

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-028/STATE.md.
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

**Source:** work-006-design-phase-skills -> delivery-002

**Depends on:** task-027

**Scope:**
- Source spec: `features/feature-005-design-grid-and-brainstorm/SPEC.md` §7a (four of its five
  rows -- the fifth, `aid-create-document`, is task-027's), §7c's bare-verb row, and its AC-3,
  AC-4, AC-5, AC-8. BLUEPRINT criterion 10 rests on this task and on nothing else in the work.
- **Why it precedes every authoring task rather than following them.** All twenty-seven bodies
  bind feature-002 §3e's skill shape, which is *"modeled on `canonical/skills/aid-design/SKILL.md`"*
  -- so every later task in this delivery **reads** the file this task rewrites, and the
  narrowed text is the one the fourteen and the four route away from. Authoring first and
  narrowing afterwards would leave twenty-seven bodies written against an advertisement the
  work then withdraws.
- `canonical/skills/aid-design/SKILL.md` -- drop *"an architecture sketch"* from **both**
  frontmatter fields, and present the skill as the catch-all for subjects with no dedicated
  `design` row. `grep -c 'architecture sketch'` returns `2` today, at `:5` (inside the
  `description:` block) and `:14` (the `argument-hint`); a `description`-only edit leaves the
  second hit standing, which is exactly what feature-005 §7a says it must not do. The narrowed
  text names the **class** (*"use the dedicated `/aid-design-<artifact>` row when one exists"*),
  never an artifact list -- one side of this pair is twenty-two rows, which no `description` can
  enumerate (§7c).
- `canonical/skills/aid-research/SKILL.md` -- add the negative route to `/aid-brainstorm` inside
  its `description:` block (`:1-17` today, `description:` opening at `:3`). The pair is
  confusable by construction: `/aid-research` requires *"an open technical question"* and returns
  *"a curated, verified answer in one pass"* (`:4-6`), which a problem not yet formed into a
  question cannot fill.
- `canonical/skills/aid-prototype-ui/SKILL.md` -- state the kept-versus-throwaway route to
  `/aid-design-ui` in its `description:` block (`:1-11`). Its own text already says
  *"THROWAWAY"*, so the edit adds the counterpart, not the distinction.
- `canonical/skills/aid-document/SKILL.md` -- add the route to `/aid-design-document` in its
  `description:` block (`:1-13`), in substance matching the clause task-027 wrote into
  `canonical/skills/aid-create-document/SKILL.md` so the trio reads consistently.
- **Behavior is not touched in any of the four.** Every edit is confined to the YAML
  frontmatter block. For bare `/aid-design` this is a gate criterion rather than a preference:
  the four `DESIGN.md` sites at `:64`, `:75`, `:87` and `:106` are what feature-002 §5 keeps,
  and they are what a careless rewrite destroys.
- Out of scope: `canonical/skills/aid-create-document/SKILL.md` (task-027 owns both of its
  edits -- a second write here would be a defect, not a duplicate); the reverse routing
  direction on the fourteen generated `create` doorways, whose `description` is produced from
  the catalog row's `intent` (feature-005 §7b); and any body change in any of the four files.

**Acceptance Criteria:**
- [ ] feature-005 V5: `grep -c 'architecture sketch' canonical/skills/aid-design/SKILL.md`
      captured to a variable -> `0` (it is `2` today, at `:5` and `:14`), so **both** fields were
      edited
- [ ] **BLUEPRINT criterion 10 / feature-002 §7 G1 -- the scoped diff.**
      `git diff master -- canonical/skills/aid-design/SKILL.md` shows hunks confined to the YAML
      frontmatter block (delimited by the `---` at `:1` and the `---` at `:15`) **and nowhere
      else** -- in particular **no hunk touching the four `DESIGN.md` sites**, which
      `grep -n 'DESIGN.md' canonical/skills/aid-design/SKILL.md` locates (today `:64`, `:75`,
      `:87`, `:106`). A whole-file `--exit-code` diff is the wrong shape here and is
      unsatisfiable by construction, since this task edits the file
- [ ] The same frontmatter-confinement diff holds for the other three:
      `git diff master -- canonical/skills/aid-research/SKILL.md`,
      `... aid-prototype-ui/SKILL.md` and `... aid-document/SKILL.md` each show hunks only
      between that file's own opening and closing frontmatter `---`
- [ ] feature-005 V6, the greppable half: bare `/aid-design`'s `description:` names the
      dedicated rows as the route away from itself -- `aid-design-` appears inside the
      frontmatter block -- and the text names the **class**, not an artifact list. The
      class-versus-list reading is a judgement, so it is recorded as such and confirmed by the
      task reviewer rather than presented as a grep result
- [ ] feature-005 V7, this task's half: `grep -q 'aid-brainstorm' canonical/skills/aid-research/SKILL.md`
      succeeds **with the hit inside the `description:` block**. The `/aid-brainstorm` side of
      the pair is task-032's, and V7 is only satisfiable once both have landed
- [ ] feature-005 V8, this task's half: `canonical/skills/aid-prototype-ui/SKILL.md` names
      `/aid-design-ui` inside its `description:` block **and** states the kept-versus-throwaway
      distinction. A name grep does not establish the second half, so it is a reviewer reading
- [ ] feature-005 V9, this task's half: `canonical/skills/aid-document/SKILL.md` names
      `/aid-design-document` inside its `description:` block
- [ ] **No description names a neighbour feature-005 §7a and §7c do not assign it**, and no
      fifth shipped skill is edited: `git diff --name-only master -- canonical/skills/` at the
      end of this task lists exactly these four files plus the two task-027 already committed
- [ ] `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean and
      `git status --porcelain profiles/ .claude/ .cursor/` is clean
- [ ] Accuracy verified against the current codebase (DOCUMENT type default)
- [ ] All section-6 quality gates pass
