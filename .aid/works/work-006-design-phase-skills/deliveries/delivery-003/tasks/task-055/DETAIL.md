# task-055: Twelve collapse and kind-sibling descriptions, two of them suite-pinned

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-055/STATE.md.
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

**Depends on:** task-054

**Scope:**
- Source: REQUIREMENTS **AC-12** (cited, not restated), **FR-7** and FR-11 **CC-9** -- this slice
  holds three of the four confusable pairs feature-006 §8a verifies whole.
- **Slice 4 of 7.** The remaining twelve hand-authored (`repurpose: true`) rows: `aid-deploy`,
  `aid-monitor`, `aid-design`, `aid-prototype`, `aid-prototype-ui`, `aid-report`, `aid-research`,
  `aid-review`, `aid-test`, `aid-test-security`, `aid-test-performance`, `aid-test-data-quality`.
- **Two of the twelve have their state-machine line pinned by a live assertion, and the resolution
  is relocation.** `tests/canonical/test-deploy-monitor-repurpose.sh:138` asserts that
  `canonical/skills/aid-deploy/SKILL.md` contains a `State machine:` line naming the
  IDLE / SELECTING / VERIFYING / PACKAGING / DONE spine, and `:150` asserts that
  `canonical/skills/aid-monitor/SKILL.md` contains the OBSERVE / CLASSIFY / ROUTE / DONE spine --
  both via `assert_file_contains`, which matches the **whole file**. AC-12 check 2 bans the
  sequence from the description only, so each line **moves into the body** with its text preserved
  byte-for-byte. Deleting either fails its assertion; leaving it in the description fails AC-12;
  editing the suite is barred by feature-001 AC-3.
- **Take both literals out of the test file, never out of this DETAIL.** Their arrows are U+2192
  (`→`), not ASCII `->`, and the trailing full stop is inside each asserted string -- so a
  relocation that retyped the line from a paraphrase would move a byte and fail the assertion while
  looking correct to a reader. Copy the two expected strings from `:138` and `:150` and move those
  exact bytes.
- **`aid-deploy` is the second of the only two descriptions in the roster that already state a
  trigger.** AC-12's rationale records the figure. Its clause is preserved rather than rewritten.
- **Three of feature-006 §8a's pairs have a side in this slice**, and every one of them was authored
  by an earlier delivery under CC-9: `aid-research` <-> `aid-brainstorm` (FR-7),
  `aid-prototype-ui` <-> `aid-design-ui`, and bare `aid-design` <-> the artifact rows. delivery-002's
  task-049 closed on those sides existing and being mutual. A rewrite that drops a neighbour name, or
  drops the kept-versus-throwaway distinction `aid-prototype`/`aid-prototype-ui` and `aid-design`
  carry, reopens a criterion already closed.
- **The three `aid-test-*` kind-siblings share one shape**, delegating to `aid-test` with a kind
  hint, so their rewrite is one template instantiated three times.
- **Bare `aid-design` is the one description in this slice whose *content* is constrained by another
  feature's closed criterion.** feature-002 AC-9 and delivery-002's BLUEPRINT criterion 10 require it
  to read as a **catch-all** with the phrase `architecture sketch` absent
  (`grep -c 'architecture sketch'` -> `0`) and its dedicated `design` rows named as the route away
  from itself. Both properties must still hold after the rewrite.
- Out of scope: `SKILL.md` body size, `argument-hint` placement and self-containment (REQUIREMENTS
  §4's AC-12 bullet); the other six slices; and the whole-roster pair matrix (task-072).

**Acceptance Criteria:**
- [ ] **AC-12 checks 1, 2 and 4 over the twelve.** Each extracted `description:` block is
      **<= 1024** characters, contains no `Direct-entry Lite-path shortcut`, no `VERB=`, no
      `ARTIFACT=` and no arrow-separated state transition sequence, and names the user-facing outcome
      before any AID-internal vocabulary (a reviewer read, all twelve quoted in full)
- [ ] **Every one of the twelve states when to use the skill**, in AC-12's imperative form, recorded
      per skill with the clause quoted. `aid-deploy`'s pre-existing clause is present and unchanged
- [ ] **The two pinned state-machine literals survive, byte-for-byte, in the body.**
      `bash tests/canonical/test-deploy-monitor-repurpose.sh` reports the assertions at `:138` and
      `:150` as `PASS`; for each of the two files
      `grep -c 'State machine:' canonical/skills/<name>/SKILL.md` captured to a variable is `1` and
      that occurrence is **below** the frontmatter's closing `---`; and
      `git diff master -- tests/canonical/test-deploy-monitor-repurpose.sh` is **empty**, because no
      task has edited that file yet. task-062 later edits four *other* assertions in it, which is why
      task-062 carries a hunk-scoped form of this same guard rather than this whole-file one
- [ ] **Bare `/aid-design`'s two closed properties still hold.**
      `grep -c 'architecture sketch' canonical/skills/aid-design/SKILL.md` captured to a variable ->
      `0`, and its description still names the dedicated `design` rows as the route away from itself
      and still reads as a catch-all (a reviewer read, with the text quoted)
- [ ] **The kept-versus-throwaway distinction survives** in `aid-prototype`, `aid-prototype-ui` and
      `aid-design`: each description still states it (a reviewer read, quoted), which is the property
      FR-6 relies on to make `/aid-design-ui` versus `/aid-prototype-ui` not a collision
- [ ] **No negative route was lost.** For each of the twelve, the sorted set of `/aid-`-prefixed
      names in the description is compared with the same set from
      `git show HEAD:canonical/skills/<name>/SKILL.md`; every difference is an addition or a removal
      recorded with its reason. `HEAD`, not `master`: `aid-design`, `aid-research` and
      `aid-prototype-ui` were edited by delivery-002's task-028, so a `master` baseline would hide a
      regression of that edit
- [ ] **Only the twelve moved.** `git diff --name-only HEAD -- canonical/skills/` at the end of this
      task lists exactly the twelve `SKILL.md` files this slice owns
- [ ] **Frontmatter shape is intact on all twelve** -- block delimiters, all four keys, `name:`
      equal to the directory -- with `tests/canonical/test-frontmatter-lint.sh` and
      `tests/canonical/test-catalog-dirs-parity.sh` green and the latter unmodified
- [ ] Accuracy verified against the current codebase: every line number and assertion id in this
      task's record is re-resolved against the file as it stands
- [ ] Nothing outside the declared writes moves:
      `git diff --exit-code -- tests/ site/ canonical/aid/templates/ docs/ .aid/knowledge/` is
      clean, and `git status --porcelain profiles/ .claude/ .cursor/` is unchanged from its state at
      the start of this task
- [ ] All section-6 quality gates pass
