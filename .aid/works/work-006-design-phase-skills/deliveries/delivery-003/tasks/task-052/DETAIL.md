# task-052: Nine curated pipeline and router descriptions given a trigger clause

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-052/STATE.md.
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

**Depends on:** task-051

**Scope:**
- Source: REQUIREMENTS **AC-12** -- its five checks are cited, not restated -- and its rationale
  paragraph, which is what makes this a reallocation of an existing budget rather than an expansion.
- **Slice 1 of 7 over the seventy-eight hand-authored descriptions.** The slices partition the
  hand-authored roster by the stratum each skill belongs to, which is a property re-derivable from
  disk (a directory under `canonical/skills/` with no catalog row is curated; a row with
  `repurpose: true` is hand-authored; every other row is generated and belongs to task-051). This
  slice is the **nine curated pipeline-and-router skills**: `aid-config`, `aid-discover`,
  `aid-describe`, `aid-define`, `aid-specify`, `aid-plan`, `aid-detail`, `aid-execute`,
  `aid-triage`.
- Rewrite each `description:` so it states what the skill does **and when to use it**, leading with
  the user-facing outcome, carrying no state-machine transition sequence and no `VERB=`/`ARTIFACT=`
  binding, within the 1024-character budget.
- **`aid-describe` carries the one hard interaction in this slice, and the resolution is relocation,
  not deletion.** `tests/canonical/test-describe-full-only.sh` takes the **first** `State machine:`
  line in the whole file (`:71`, `awk '/State machine:/{print; exit}'`) and then asserts `DFO01a`
  (the line exists), `DFO01b` (it carries no `TRIAGE`/`CONDENSED-INTAKE`/`LITE-` token) and `DFO01c`
  (it reads `FIRST-RUN -> Q-AND-A -> CONTINUE`). AC-12 check 2 bans that sequence from the
  **description** and says nothing about the body. So the line **moves into the `SKILL.md` body**
  and its text is preserved verbatim; the `awk` still finds it, and all three assertions stay green
  with the suite unedited. Deleting it would fail DFO01a; leaving it in the description would fail
  AC-12.
- **`aid-plan` is one of only two descriptions in the whole roster that already states a trigger.**
  AC-12's rationale records the figure. Its existing trigger clause is preserved, not rewritten for
  the sake of uniformity -- it is the shape the other 110 are being moved toward.
- **What a rewrite may not silently drop.** Any neighbour name a description carries as a negative
  route was written by the feature that owns that pair under FR-11 **CC-9**, and delivery-002's
  task-049 verified the sides it wrote. A rewrite that drops a neighbour name breaks a criterion
  already closed, so each description's set of `/aid-` names is compared before and after and any
  intended removal is stated with its reason.
- Out of scope: `SKILL.md` **body** size, moving `argument-hint` under `metadata:`, and skill
  self-containment -- all three named out of scope by REQUIREMENTS §4's AC-12 bullet. Also out of
  scope: the other six slices; the generated doorways (task-051); the count-bearing line inside
  `canonical/skills/aid-triage/references/state-classify.md` (`:85`), which is task-069's; and the
  whole-roster verification, which is task-072's.

**Acceptance Criteria:**
- [ ] **AC-12 checks 1, 2 and 4 over the nine.** For each of `aid-config`, `aid-discover`,
      `aid-describe`, `aid-define`, `aid-specify`, `aid-plan`, `aid-detail`, `aid-execute` and
      `aid-triage`: the extracted `description:` block is **<= 1024** characters, contains no
      `Direct-entry Lite-path shortcut`, no `VERB=`, no `ARTIFACT=` and no arrow-separated state
      transition sequence, and names the user-facing outcome before any AID-internal vocabulary (a
      reviewer read, recorded with all nine descriptions quoted in full)
- [ ] **Every one of the nine states when to use the skill**, in the imperative form AC-12 requires
      -- a trigger clause, recorded per skill with the clause quoted. `aid-plan`'s pre-existing
      clause is present and unchanged
- [ ] **`aid-describe`'s `State machine:` line was relocated, not removed.**
      `grep -c 'State machine:' canonical/skills/aid-describe/SKILL.md` captured to a variable is
      still `1`; that occurrence is **below** the closing `---` of the frontmatter block; and
      `bash tests/canonical/test-describe-full-only.sh` passes with `DFO01a`, `DFO01b` and `DFO01c`
      all `PASS` while `git diff master -- tests/canonical/test-describe-full-only.sh` is **empty**
- [ ] **No negative route was lost.** For each of the nine, the sorted set of `/aid-`-prefixed skill
      names appearing in the description is compared against the same set taken from
      `git show master:canonical/skills/<name>/SKILL.md`; every difference is an addition, or is a
      removal recorded with its reason
- [ ] **Only the nine moved.** `git diff --name-only master -- canonical/skills/` lists exactly the
      nine `SKILL.md` files this slice owns and nothing else
- [ ] **Frontmatter shape is intact on all nine**: the block still opens and closes with `---`,
      still declares `name`, `description`, `allowed-tools` and `argument-hint`, and `name:` still
      equals the directory. `tests/canonical/test-frontmatter-lint.sh` and
      `tests/canonical/test-graph-skill-registration.sh` are green -- the latter's `GR01.a3` asserts
      the `description` key's presence, which a malformed folded scalar would break
- [ ] Accuracy verified against the current codebase: every line and assertion id cited in this
      task's record is re-resolved against the file as it stands rather than carried from this DETAIL
- [ ] Nothing outside the declared writes moves:
      `git diff --exit-code -- tests/ site/ canonical/aid/templates/ docs/ .aid/knowledge/` is clean,
      and `git status --porcelain profiles/ .claude/ .cursor/` is unchanged from its state at the
      start of this task
- [ ] All section-6 quality gates pass
