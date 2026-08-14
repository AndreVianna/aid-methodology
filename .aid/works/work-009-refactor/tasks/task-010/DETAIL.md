# task-010: Convert every live work tree in this repository to STATE.yml

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-010/STATE.md` -- this task's mutable cells live
only in the work-root state file's `### Tasks lifecycle` table.
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

**Type:** MIGRATE

**Source:** work-009-refactor -> delivery-001

**Depends on:** task-009, task-017, task-020

**Scope:**
- The self-hosting cutover (`SPEC.md § L-6 Live works during the conversion`, C-6, SP-18): run the
  task-008 conversion step over every live work tree in this repository, as ONE step that leaves no
  work in the old format. Readers (task-003/004), shell readers (task-006), the writer (task-007),
  the dashboard server write path (task-020), the dogfood render of the writer (task-017) and the
  CLI format gate (task-008/009) all already accept `STATE.yml` before this task starts -- that
  ordering is the requirement, not a preference, and it is why this task depends on task-017 and
  task-020 as well as task-009.
- **FIRST STEP, before any conversion: enumerate the live works from disk.** Run
  `.claude/aid/scripts/works/enumerate-works.sh` from each worktree root -- or the equivalent
  cross-worktree sweep, `git worktree list` followed by `ls <root>/.aid/works/` per root -- and
  record the resulting root/work set as the authority for this run. **No list in any document is
  that authority, including the one below.** The set moves: two additional worktrees appeared
  between this task being written and its definition passing GATE, and a work omitted from a
  hardcoded roster is a work left in markdown after the cutover, which SP-18 and
  `BLUEPRINT.md § Notes` ("No two-format end state") forbid.
- Illustrative snapshot only, **not** the enumeration (accurate on 2026-08-12, guaranteed stale
  afterwards): eight roots -- the master checkout plus the `work-003`, `work-004`, `work-006`,
  `work-007`, `work-008`, `work-009` (this work) and `work-010` worktrees -- carrying live works
  `work-003`, `work-004`, `work-005`, `work-006`, `work-007`, `work-008`, `work-009` and
  `work-010`. Use it to sanity-check the enumeration's order of magnitude, never as its source.
- `work-005-knowledge-graph` is **tracked on master**, so it materializes under EVERY root:
  converting it once produces a change every other root inherits, and the converter must be a
  no-op against roots that already see the converted form. The remaining works are untracked
  per-worktree state and are converted per root.
- Both layouts occur live: `work-005-knowledge-graph` carries
  `deliveries/delivery-001/tasks/task-NNN/STATE.md`, and this work carries the flattened work-root
  file only.
- **This work's own tracker is one of the files being converted.** The tracking-discipline mandate
  keeps binding throughout: state writes before the conversion go to the markdown file, writes
  after it go to `STATE.yml`, and this task is not `Done` until this work's own tracking has been
  proven readable and writable in the new format.
- Rollback (`task-type-rules.md § MIGRATE`): tracked works revert with a VCS restore; untracked
  per-worktree works revert from the per-file fail-safe (task-008 deletes the `.md` only after the
  `.yml` verifies) or are re-created by their own pipeline. Record which roots were converted, in
  order, so a partial run is resumable -- and re-running the step is safe because it is idempotent.
- OUT of this task: any change to the converter or the stamp (task-008, task-009); test fixtures,
  which build their own inputs and are never a live tree (`tests/canonical/fixtures/migrate/...`
  stays untouched).

**Acceptance Criteria:**
- [ ] The root/work set was enumerated from disk as this task's first step -- via
      `.claude/aid/scripts/works/enumerate-works.sh` per root, or the equivalent
      `git worktree list` + `ls <root>/.aid/works/` sweep -- and that enumeration is recorded in
      the commit message as the authority for the run; no roster from a definition document was
      used as the source (SP-12, SP-18).
- [ ] Every live work tree under every **enumerated** worktree root holds a `STATE.yml` and no
      `.aid/works/*/STATE.md`, `deliveries/*/STATE.md` or `deliveries/*/tasks/*/STATE.md` -- proven
      by a find across all roots from that same enumeration, re-run after the conversion so a root
      that appeared mid-run is caught rather than missed (SP-12, SP-18).
- [ ] No root ends this task with works in two formats; the conversion is one step and the
      two-format window closes inside it (SP-18).
- [ ] The expected `phase`/`lifecycle` per work is recorded BEFORE any conversion by reading each
      work's markdown frontmatter directly, and after the conversion
      `bash canonical/aid/scripts/works/enumerate-works.sh` from each root reports exactly that
      recorded set, with no `--` sentinel for a converted work. A pre-conversion RUN of the script
      is not the baseline and must not be used as one: task-006 has already retargeted it to
      `STATE.yml`, so before the conversion it returns `--` for every work (SP-11, SP-12).
- [ ] Both reader twins render every work from every root with no `parse_warning`, and the
      dashboard payloads for each work match the pre-conversion payloads field-for-field (SP-8,
      SP-12).
- [ ] Re-running the conversion changes nothing anywhere -- including under the roots that inherit
      the tracked `work-005-knowledge-graph` conversion (SP-12 idempotence).
- [ ] This work's own `STATE.yml` is readable by both twins and writable by
      `writeback-state.sh --pipeline`/`--task-id` immediately after the conversion, demonstrated by
      a real state write recorded in this task's own lifecycle (SP-18, C-6).
- [ ] Every scalar, former-table row and Q&A entry survives per work: counts compared
      pre/post per file, with any DERIVED-row hard error resolved by running the hierarchy
      migration first rather than by editing data (SP-3, SP-12).
- [ ] The per-root conversion order is recorded in the commit message so a partial run is
      resumable.
- [ ] No file under `tests/` is modified by this task.
- [ ] All section-6 quality gates pass.
