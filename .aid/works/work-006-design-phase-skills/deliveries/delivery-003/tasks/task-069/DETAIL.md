# task-069: Every count-bearing surface states its true value, under the surviving guard and G-01

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-069/STATE.md.
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

**Depends on:** task-068

**Scope:**
- **This task was re-scoped by owner decision (2026-08-14).** Its original subject -- extend
  `CLAIMS` to cover modes M2/M3/M4, raise `MARKER_CAP` and `CLAIM_FLOOR`, and drive the stage-2
  replay to zero -- targeted constructs inside `tests/canonical/check-skill-counts.mjs`, which
  was **deleted upstream** (work-004, merged to `master`). No constant survives to raise and no
  replay survives to run. The authoritative record of the re-scope, including how every stale
  citation in this delivery resolves, is
  `.aid/works/work-006-design-phase-skills/deliveries/delivery-003/RESCOPE-COUNT-GUARD.md`;
  read it before starting. Q1 in `deliveries/delivery-003/STATE.md` carries the decision.
- Source: `features/feature-006-integration-and-close-out/SPEC.md` §3's
  **surfaces-state-their-own-value** half, which survives. §3's constants (a), (b) and (c) and
  its §10 rows about guarded-versus-unguarded phrasings are **superseded** -- they describe the
  retired guard. It closes BLUEPRINT criterion **4** as re-scoped, whose per-file work
  task-051, task-059 and task-065 through task-068 did.
- **It still runs last of the count work**, for an unchanged reason: the derived figures are not
  final until every document and the catalog are, and this task is the one that asserts them
  repo-wide.
- **The obligation, in one sentence: make every count-bearing surface state the true number.**
  The surviving guard, `tests/canonical/test-doc-counts.sh`, **derives** each count from the
  canonical tree and asserts that each public-facing surface states the current derived value.
  Its own header states the consequence -- *"you regenerate the docs, not this test"* -- so
  there is no claim set to widen and no ratchet to raise. Drive it to exit **0**.
- **The guarded half is a fixed, enumerated work list.** On this branch the guard reports 14
  `DC02` count-drift failures over exactly 10 files, and `RESCOPE-COUNT-GUARD.md` tabulates
  every one. The derived figures are **112** skills and **94** catalog rows *because this
  work's 36 skills and 36 rows have landed*; they are not hard-coded and move with the tree, so
  re-derive rather than trusting these numbers.
- **The five `profiles/*/README.md` are renders.** Fix the `canonical/` source and re-render;
  never edit a render in place (`G-06` excludes a render from content review for that reason).
  The render itself is task-050's single committed run, not this task's.
- **The unguarded half is a reviewer criterion, not a build.** Count-bearing prose inside
  `canonical/` and `.aid/knowledge/` is governed by **`G-01`** in `authoring-conventions.md` --
  *"No cosmetic count unless it is load-bearing and measured from disk at authoring time"* --
  at severity `MINOR`. For each such surface this task either removes the cosmetic count or
  re-measures it at authoring time, and records the verdict. That this half is reviewer-governed
  rather than guarded is the accepted trade of the owner's decision, and is recorded as such
  rather than presented as equivalent to a guard.
- **The three surfaces that belong to no other task are still named here so they are not
  orphaned.** `canonical/skills/aid-triage/references/state-classify.md` (its count line) and
  `.claude/skills/release-aid/SKILL.md` are both `G-01` surfaces now. `README.md` has moved into
  the **guarded** half -- it is an asserted surface in `test-doc-counts.sh`, so the guard's own
  output is its oracle. Editing `release-aid` cannot break the byte-identity gate: that suite
  puts `skills/release-aid/*` in its documented allowlist and the skill has no `canonical/`
  source, so it needs no re-render.
- **`kb.html` is still task-071's, by regeneration.** The old reason was that `EXT` admitted no
  `.html`; the new reason is that `test-doc-counts.sh` does not scan it and `G-01` reaches only
  markdown. Either way the remedy is regeneration, and this task must not attempt to reach it.
- **feature-001 AC-3 is not violated**, and now trivially so: this task authors and edits **no**
  file under `tests/canonical/` or `site/scripts/__tests__/` at all, because the artifact it used
  to edit no longer exists.
- Out of scope: re-creating a repo-wide count guard (that reverses the upstream owner decision);
  `tests/canonical/test-doc-counts.sh` itself, which is derived-by-construction and needs no edit
  for a legitimate tree change; `tests/coverage-baseline.{tsv,meta}` (task-063); `INDEX.md`
  (task-070) and `kb.html` (task-071).

**Acceptance Criteria:**
- [ ] **BLUEPRINT criterion 4, oracle 1 (re-scoped) -- the surviving guard is green.**
      `bash tests/canonical/test-doc-counts.sh` exits **0**, with its `Tests passed` / `Tests
      failed` summary recorded from the run output rather than from this DETAIL. A run that still
      reports any `DC02` failure fails this criterion
- [ ] **Every surface in `RESCOPE-COUNT-GUARD.md`'s work list is resolved**, each recorded with
      the file and the value it now states. The list is re-derived at execution time -- a surface
      that entered or left it since this DETAIL was re-scoped is recorded as such, because the
      guard's figures track the tree
- [ ] **The derived figures are read from the guard, not asserted from memory.** The recorded
      `SKILLS` / `ROWS` / `SHORTCUTS` values are the ones `test-doc-counts.sh` derives on the run
      that passes, and the record states them
- [ ] **`DC01` internal consistency holds**: the guard's own catalog check (canonical rows +
      alias rows == total rows) passes, recorded from the run
- [ ] **The five profile READMEs were fixed at their `canonical/` source, not in place.**
      `git diff --name-only` for this task lists no `profiles/*/README.md` as a hand edit; their
      correction arrives through the render. If the render has not yet run, this criterion is
      recorded as deferred to task-050 with the source edit named
- [ ] **The unguarded (`G-01`) half is discharged per surface and recorded as a verdict.** For
      each count-bearing line in `canonical/` or `.aid/knowledge/` this task touches, the record
      states whether the count was **removed** as cosmetic or **re-measured** at authoring time,
      with the command used for a re-measure. A surface reported only as "checked" fails
- [ ] **The three named surfaces are each resolved and recorded.**
      `canonical/skills/aid-triage/references/state-classify.md` and
      `.claude/skills/release-aid/SKILL.md` are recorded as `G-01` verdicts; `README.md` is
      recorded from the guard's own output. After any edit to `release-aid`,
      `bash tests/canonical/test-dogfood-byte-identity.sh` is still green with both key sets
      reported -- the allowlist makes that edit safe, and this is where it is demonstrated
      rather than assumed
- [ ] **The `34 emitting shortcuts` negative half still holds, with its three witnesses named.**
      `test-doc-counts.sh` derives `SHORTCUTS` as **34** and asserts it in the public docs;
      `tests/coverage-baseline.tsv` (task-063) is cited as the second witness; the regenerated
      `kb.html` (task-071) is named as the third and **not** claimed here
- [ ] **No count guard is re-created and none is edited.** `git diff --name-only HEAD --
      tests/canonical/ site/scripts/__tests__/` is **empty** for this task, and the record states
      that `check-skill-counts.mjs` is retired upstream rather than pending
- [ ] **The re-scope itself is traceable.** The record cites `RESCOPE-COUNT-GUARD.md` and
      delivery-003 STATE.md Q1, and states which of this task's original obligations were
      **dropped** (the `CLAIMS` extension, `SUPERSEDED`, `MARKER_CAP`, `CLAIM_FLOOR`, the stage-2
      replay) versus **carried** (every surface stating its true value)
- [ ] All existing tests still pass, and `git diff --name-only HEAD` lists only the count-line
      fixes this task made -- each enumerated in the record with its document. A changed file in
      neither list is the finding
- [ ] All section-6 quality gates pass
