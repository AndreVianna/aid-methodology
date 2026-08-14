# task-020: Retarget the dashboard server write path and raw-state labels to STATE.yml

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-020/STATE.md` -- this task's mutable cells live
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

**Depends on:** task-007

**Scope:**
- The dashboard server layer (`SPEC.md § L-11`, FR-4e) -- the write-path **caller** of the
  task-007 writer, in two runtimes. This task retargets the caller only; no write semantics, no
  route, no payload and no auth behavior changes.
- `dashboard/server/server.mjs` -- the three `const env = { AID_STATE_FILE: join(workDir,
  "STATE.md"), AID_WORK_DIR: workDir }` constructions at `:1242`, `:1280` and `:1555` (task
  set-notes, pipeline `Lifecycle=Completed`, task rename) become `join(workDir, "STATE.yml")`.
  The narrative comment at `:1539` that names the env pair is checked with them.
- `dashboard/server/server.py` -- the same three, `{"AID_STATE_FILE": str(work_dir / "STATE.md"),
  ...}` at `:1503`, `:1540` and `:1803`, become `str(work_dir / "STATE.yml")`. The comment at
  `:1786` is checked with them. **All six sites land in this one task, in the same change** --
  `server.mjs` and `server.py` are a lockstep twin pair under C-4 and may never be split across
  tasks or across commits; a one-runtime edit is a parity defect even while both runtimes are
  individually consistent.
- `dashboard/home.html` -- `:5816`, the raw-state viewer's **fallback** source label
  `('.aid/works/' + workId + '/STATE.md')`, used when the reader supplied no `rawState.path`; plus
  its ten sibling `STATE.md` UI strings and comments at `:3229`, `:4970`, `:5574`, `:5791`, `:5800`,
  `:5808`, `:5828`, `:5860`, `:5865` and `:5957`, so the UI never labels a `STATE.yml` as
  `STATE.md`. `:5957`'s forensics blurb also names two retired markdown sections (`Quick Check
  Findings`, `Delivery Gates / Delivery Gate`) -- it is retargeted to the key names task-002
  declares, not left describing headings that no longer exist.
- **Why this is behavioral and not cosmetic.** `AID_STATE_FILE` is an *explicit override*, so it
  wins over the writer's own layout auto-detection: an unretargeted site points at a path that no
  longer exists and the writer dies `"$STATE_FILE does not exist"` with exit 1
  (`writeback-state.sh:1414`, plus the parallel existence checks at `:805`, `:894`, `:1039`,
  `:1133`, `:1206`, `:1240`). Every write-enabled dashboard edit surface breaks at once, in both
  runtimes, with **no reader-side symptom** to hint at the cause -- which is why the gate is
  SP-19b, asserted behaviorally, and not a text search.
- Reads are NOT in scope: `dashboard/server/reader.mjs` is task-004's, and the `join(kbDir,
  "STATE.md")` / `SKIP_NAMES` references to the out-of-scope `.aid/knowledge/STATE.md` discovery
  ledger must keep saying `STATE.md`. A blind find-and-replace across `dashboard/server/` hits them;
  each surviving hit is enumerated in the commit message with its reason.
- No `canonical/` source and no `profiles/` render exists for any of these three files, so they are
  edited in place. Editing them here is NOT a C-1 violation, and task-017's render fan-out does not
  cover them.
- OUT of this task: the writer itself and the `dashboard/scripts/writeback-state.sh` fork
  (task-007); the shell readers including `dashboard/scripts/delete-pipeline.sh` (task-006); the
  reader twins (task-003/004); the oracle suite
  `dashboard/server/tests/test_write_enabled_cross_runtime_parity.py` (task-016).

**Acceptance Criteria:**
- [ ] Against a converted work, each of the three write-enabled dashboard edit surfaces (task
      set-notes, pipeline `Lifecycle=Completed`, task rename) writes successfully to `STATE.yml`,
      in **both** server runtimes, with identical results (SP-19b, FR-4e, C-4).
- [ ] The raw-state viewer resolves the same source path in both runtimes, and its label names
      `STATE.yml` on both the reader-supplied and the `:5816` fallback path (SP-19b).
- [ ] All six `AID_STATE_FILE` constructions name `STATE.yml`:
      `grep -n 'AID_STATE_FILE' dashboard/server/server.mjs dashboard/server/server.py` shows nine
      lines -- the six env constructions (`server.mjs` `:1242`, `:1280`, `:1555`; `server.py`
      `:1503`, `:1540`, `:1803`) plus the three narrative comments (`server.mjs` `:967`, `:1539`;
      `server.py` `:1786`) -- and no `STATE.md` among them.
- [ ] The two runtimes are in lockstep: the `server.mjs` and `server.py` edits are in the same
      commit, and a per-site comparison shows the same three surfaces changed the same way in both
      (C-4, SP-14).
- [ ] No `STATE.md` string survives in `dashboard/home.html`, and no UI string, comment or blurb
      describes a work-tree state file as markdown or names a retired markdown section (SP-15).
- [ ] `grep -rn 'STATE\.md' dashboard/server/ dashboard/home.html` returns only the out-of-scope
      `.aid/knowledge/STATE.md` discovery-ledger references (`join(kbDir, ...)`, `SKIP_NAMES`) and
      explicitly labelled legacy/migration references; every remaining hit is enumerated in the
      commit message with its reason (SP-15).
- [ ] The discovery-ledger guards are untouched -- the `kbDir` / `SKIP_NAMES` sites still say
      `STATE.md` and the diff shows they were not retargeted (scope-defect guard).
- [ ] Behavior is otherwise preserved: no route, request payload, response shape, spawn argument
      list, auth check or write-enablement condition changes, and the net change is the path
      constant plus labels (`task-type-rules.md § REFACTOR`).
- [ ] No file under `canonical/`, `profiles/`, `.claude/` or `.cursor/` is edited by this task
      (C-1) -- the three files in Scope are single-copy, unrendered sources.
- [ ] All section-6 quality gates pass.
