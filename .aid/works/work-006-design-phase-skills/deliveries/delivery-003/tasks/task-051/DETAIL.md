# task-051: The generated doorway's description template -- one f-string, thirty-four doorways

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-051/STATE.md.
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

**Type:** IMPLEMENT

**Source:** work-006-design-phase-skills -> delivery-003

**Depends on:** task-050

**Scope:**
- Source: REQUIREMENTS **AC-12**, checks **3**, **2**, **1** and **4**. AC-12 names the write target
  itself -- the `frontmatter = (` assignment in
  `.claude/skills/generate-profile/scripts/build-shortcut-skills.py`, *"one edit covers all 34, and
  hand-editing generated output instead would be overwritten on the next render"*. AC-12's five
  checks are **cited, not restated**; read them there.
- **This is the generated half of the one description sweep this delivery runs.** AC-12 and
  feature-006 §8a are a single pass over a single file set, not two passes over it: this task and
  task-052 through task-058 author, and task-072 verifies routing and triggering together. The
  generated half is cut first so the seventy-eight hand-authored slices that follow can be written
  in the same voice.
- Edit the `frontmatter = (` assignment (`build-shortcut-skills.py:253-266`) so the emitted
  `description:` **leads with the row's `intent`**, states when to use the skill, and carries none
  of the three forms AC-12 check 2 bans. The only per-skill variables in scope are `{intent}`,
  `{verb}` and `{artifact}` (`:246-251`) -- which is exactly why one edit covers all thirty-four and
  why no per-skill wording is possible or wanted here.
- **The body must keep what the description gives up, or three assertions per doorway go red.**
  `tests/canonical/test-catalog-dirs-parity.sh:149` reads the **whole file**
  (`body=$(cat "$skill_md")`) and then asserts `CDP{i}e` (``VERB=`<verb>` ``, `:151-156`), `CDP{i}f`
  (``ARTIFACT=`<artifact>` `` or `ARTIFACT="" (bare verb)`, `:158-167`) and `CDP{i}g` (the literal
  `canonical/aid/templates/shortcut-engine.md`, `:169-173`). All three strings appear today in
  **both** the description (`:258`, `:261`) and the body (`:276-282`). Removing them from the
  description is required; removing them from the body is forbidden. The `_GENERATED_MARKER` in the
  body (`:272`) must survive too -- `find_orphans` (`:294-323`) and `CDP-ORPHAN` (`:185-193`) both
  key on it, and an orphan sweep that stopped recognising a directory it generated would delete it.
- **Regenerate, then prove the regeneration is total.** Run
  `python .claude/skills/generate-profile/scripts/build-shortcut-skills.py`, then the same script
  with `--check`, which must print `OK:` -- the helper's own byte-level drift detector.
  `canonical/skills/` is declared as this task's write because the helper writes
  `SKILLS_ROOT / <name> / "SKILL.md"` (`:363-377`) and **walks the whole tree** looking for orphans
  (`:310`), which is also why this task cannot run beside any other writer under it.
- **This task is the single writer of `build-shortcut-skills.py` in this delivery, so it carries
  that file's one stale count comment.** `:12` reads *"`repurpose: true` rows (24 total after
  work-004) are SKIPPED"* -- a count-bearing line inside the count guard's own scanned trees, listed
  by feature-006 §3 under mode M3. It is corrected here from a figure re-derived with
  `grep -c '^    repurpose: true$' canonical/aid/templates/shortcut-catalog.yml`, rather than in
  task-069, so that one file has one writer.
- Out of scope: the seventy-eight hand-authored descriptions (task-052 through task-058); the
  `SKILL.md` **body** size guidance, moving `argument-hint` under `metadata:`, and skill
  self-containment -- all three placed out of scope by REQUIREMENTS §4's AC-12 bullet; the render to
  the five profiles (task-060); and every catalog comment, which is task-059's.

**Acceptance Criteria:**
- [ ] **AC-12 check 3 -- the template leads with the intent.** The `frontmatter = (` assignment and
      the `:12` comment are the only edited regions:
      `git diff master -- .claude/skills/generate-profile/scripts/build-shortcut-skills.py` shows
      hunks confined to those two, and each emitted `description:` opens with its row's `intent`
      text rather than carrying it in parentheses
- [ ] **AC-12 check 2 -- none of the three banned forms survives in any of the thirty-four
      descriptions.** For each generated `SKILL.md`, the text between `description:` and the next
      top-level frontmatter key contains no `Direct-entry Lite-path shortcut`, no `VERB=`, no
      `ARTIFACT=` and no `INTAKE -> CAPTURE` transition sequence. Asserted over the **extracted
      description block**, never over the whole file -- the body legitimately keeps all four
- [ ] **AC-12 checks 1 and 4 -- budget and ordering.** Each of the thirty-four descriptions is
      **<= 1024** characters, and each names the user-facing outcome before any AID-internal
      vocabulary (a reviewer judgement, recorded with the longest and the shortest of the thirty-four
      quoted in full)
- [ ] **The body-side assertions survive, which is the failure this task is most likely to cause.**
      `bash tests/canonical/test-catalog-dirs-parity.sh` passes with every `CDP{i}e`, `CDP{i}f` and
      `CDP{i}g` reported `PASS`, and
      `git diff master -- tests/canonical/test-catalog-dirs-parity.sh` is empty. A description-only
      edit that also stripped the body bindings would pass a frontmatter grep and fail here
- [ ] **The regeneration is total and byte-current.**
      `python .claude/skills/generate-profile/scripts/build-shortcut-skills.py --check` exits 0 and
      prints a line beginning `OK:`, and a second run without `--check` reports `0` written
- [ ] **Only the thirty-four moved.** `git diff --name-only master -- canonical/skills/` lists
      exactly the thirty-four generated doorways' `SKILL.md` files and nothing else -- no
      hand-authored body, and no directory added or removed
- [ ] **The generated marker still marks all thirty-four**, so the orphan sweep still recognises
      what it generated: a `grep -l` for the marker string across `canonical/skills/*/SKILL.md`
      captured to a variable -> `34`, with the marker read out of `build-shortcut-skills.py` rather
      than retyped
- [ ] **The `:12` count comment is corrected from a re-derived figure**, and the derivation is
      recorded beside it: `grep -c '^    repurpose: true$' canonical/aid/templates/shortcut-catalog.yml`
      captured to a variable -> `60`
- [ ] Unit-level coverage for this change is the existing parity suite plus the helper's own
      `--check` mode; no new test file is authored, and `git diff --exit-code -- tests/
      site/scripts/__tests__/` is clean -- authoring a suite under either tree is barred by
      feature-001 AC-3
- [ ] All existing tests still pass and nothing outside the declared writes moves:
      `git diff --exit-code -- canonical/aid/templates/ docs/ .aid/knowledge/ site/` is clean, and
      `git status --porcelain profiles/ .claude/ .cursor/` is unchanged from its state at the start
      of this task
- [ ] All section-6 quality gates pass
