# task-007: Collapse writeback-state.sh onto one YAML single-key write path

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-007/STATE.md` -- this task's mutable cells live
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

**Type:** REFACTOR

**Source:** work-009-refactor -> delivery-001

**Depends on:** task-004, task-006

**Scope:**
- `canonical/aid/scripts/execute/writeback-state.sh` -- three awk programs collapse onto one, and
  the CLI surface does not move:
  - `WB_SET_FRONTMATTER_AWK` (`:563-655`) becomes THE single write path: same algorithm with the
    `---` fence state machine removed (the whole file is the key space), the
    synthesize-a-block-when-absent branch (`:581-595`) collapsed into create-file-if-absent, and
    the existing `parent`/`child` dotted-key handling extended to the S3/S4/S5 targets a write can
    address (`tasks_lifecycle.task-NNN.<field>`, `delivery_lifecycle.updated`,
    `delivery_gate.issue_list`, `quick_check.*`) using the same create-parent-if-absent /
    insert-at-end-of-parent logic `parent_seen` already implements one level up.
  - `write_task_field_flat` (`:877-1022`) is **deleted** -- with it the `col_idx=3..7` map, the
    `new_row()` builder, `maybe_insert()`, `last_was_row`, the legacy-5-column tolerance and the
    `task-NNN` row-presence grep. A flattened per-task field write becomes the same single-key
    write against `tasks_lifecycle.task-NNN.<field>`.
  - Both section-replace awk programs (`:1056-1081` findings, `:1259-1284` delivery gate) are
    **deleted**; `quick_check` (mapping + sequence) and `delivery_gate.issue_list` (sequence)
    become structured writes.
- Preserved verbatim: the mode dispatch and every flag (`--pipeline --field`, `--task-id --field`,
  `--task-id --findings`, `--delivery-id --block`, `--lifecycle`, `--gate-field`,
  `--append-issue`); `AID_STATE_FILE` / `AID_WORK_DIR` / `AID_DELIVERY_DIR` /
  `AID_TASK_STATE_FILE` / `AID_DELIVERY_STATE_FILE` / `AID_ISSUES_DIR` / `AID_LOCK_TIMEOUT`; exit
  codes 0-6 (6's malformed-file check moves from "the `## Task State` heading exists" to "the file
  parses and is a mapping"); every closed-enum validation in `mode_field`, `mode_pipeline`,
  `mode_delivery_lifecycle`, `mode_gate_field`; the conditional-field clearing on a `Lifecycle`
  change (`:1491-1512`) including its chained-temp-file idiom; the sentinel lock
  (`:506-526`); write-to-temp + verify + atomic `mv`; `ENVIRON`-based raw-value passing (never awk
  `-v` -- the fix at `:542-548` and `:908-914` must not regress); the CRLF / trailing-newline
  guards (`has_crlf`, `had_trailing_nl`, `:707-737`); and the flat-layout auto-detection rule,
  retargeted by filename only.
- Deliberate deletions (FR-4b): the `|` guard (`:767-769`), the `mode_field` newline guard
  (`:772-774`) and `mode_pipeline`'s newline guard (`:1420-1422`) -- D-5 mode 3 expresses those
  values. `wb_frontmatter_verify` (`:746`) generalizes from `grep -q "^key:"` to "the written key
  resolves to the written value on re-read", closing the nested-key blind spot (today it greps
  `^  child:` for any parent).
- Emission per `SPEC.md § D-5`: bare iff the value matches `^[A-Za-z0-9_.+/-]+$` (`:568`) and is
  not on the implicit-type deny list; else single-quoted with `'` doubled; else double-quoted with
  the five-escape subset when the value carries a newline or control character.
- `dashboard/scripts/writeback-state.sh` -- the **deliberate fork** (C-2, FR-4d) -- is updated BY
  HAND with the same change and must keep accepting `Deploy` as a `Phase` value. It is never
  resynced from canonical; no test guards this, so the `Deploy` acceptance is the only available
  proof (asserted in task-017 as well).
- **Sequencing note (SP-18, C-6):** this task lands the writer only. Until task-010 converts the
  live work trees, the repo's own works are still markdown -- so the executor records this work's
  own state transitions in whichever format is live at that moment, and task-008/009/010 follow
  immediately so no step ends with a work whose tracking is unwritable.
- **The writer's own dashboard *callers* are NOT in this task** (`SPEC.md § L-11`, FR-4e). The six
  `AID_STATE_FILE` constructions in `dashboard/server/server.mjs` / `server.py` and the
  `dashboard/home.html` source labels are owned by **task-020**, which depends on this task. The
  split is deliberate: they are a different language, a different runtime pair and a different
  failure mode (an explicit env override winning over this writer's layout auto-detection), gated by
  a different criterion (SP-19b, not SP-4/5/6). What this task owes them is the *contract* they call
  against -- a writer that accepts a `STATE.yml` target through `AID_STATE_FILE` unchanged.
- OUT of this task: the templates (task-002), the readers (task-003/004), the shell readers
  including `delete-pipeline.sh` (task-006), the dashboard server call sites and `home.html`
  (task-020), the migration engine (task-008/009), converting live works (task-010), the writer's
  own suites (task-015), and the render fan-out (task-017 -- editing a render here is a defect,
  C-1).

**Acceptance Criteria:**
- [ ] Writing one key at any of the three levels reproduces every other line byte-for-byte --
      full-line comments, blank lines, key order, and the presence or absence of a trailing newline
      -- and `git diff` on the state file is exactly one line (SP-4, FR-4a).
- [ ] Every documented write mode keeps its CLI surface, its `AID_*_FILE` override envs and its
      exit-code contract 0/1/2/3/4/5/6; an out-of-enum value still fails with exit 4; a malformed
      file still exits 6 (SP-5).
- [ ] A value containing `|`, a newline, a colon, a `#` or a quote round-trips intact instead of
      being rejected, and the three deleted guards are gone from the file (SP-5, FR-4b).
- [ ] `write_task_field_flat` and both section-replace awk programs no longer exist; a flattened
      per-task field write goes through the single-key path against
      `tasks_lifecycle.task-NNN.<field>`; the net line count of the script decreases and the
      reduction is stated in the commit message (`task-type-rules.md § REFACTOR`).
- [ ] With N parallel writers on one file, each write is either fully applied or reports exit 2,
      the file parses at every observable moment, and no write is silently lost (SP-6).
- [ ] A write that fails verification leaves the original file byte-unchanged, and every `die` path
      still reports the file as preserved (SP-6).
- [ ] A CRLF source and a source with no trailing newline both round-trip unchanged on Windows and
      POSIX awk builds (SP-6, NFR-4).
- [ ] `wb_frontmatter_verify` confirms the written key resolves to the written value on re-read,
      including a nested `S3`/`S5` target (SP-4).
- [ ] Raw values still reach awk through `ENVIRON`, never `-v`; a value containing a backslash or
      `\n` literal is not re-processed (`:542-548`, `:908-914` behavior preserved).
- [ ] Layout auto-detection still applies the identical three-part rule, retargeted by filename
      only (SP-7).
- [ ] `dashboard/scripts/writeback-state.sh` carries the same change by hand AND still accepts
      `Deploy` as a `Phase` value; the diff shows it was hand-edited, not copied from canonical
      (SP-14, C-2).
- [ ] No file under `profiles/`, `.claude/` or `.cursor/` is edited by this task (C-1).
- [ ] All section-6 quality gates pass.
