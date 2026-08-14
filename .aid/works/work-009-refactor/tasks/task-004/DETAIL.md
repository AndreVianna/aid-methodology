# task-004: Port the Node reader twin onto the same structured state parse

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-004/STATE.md` -- this task's mutable cells live
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

**Depends on:** task-003

**Scope:**
- `dashboard/server/reader.mjs`, changed function-for-function against task-003 so parity is a
  port rather than a re-derivation (NFR-1, C-4): `parseFrontmatterScalars` (`:173`) becomes the
  single whole-document subset parser; `parseStateText` (`:2308`) loses its section state machine;
  `parseTasksLifecycleMd` (`:3833`), `_parseTaskStateMd` (`:3502`), `_parseDeliveryStateMd`
  (`:3589`), `parseQuickCheckFindings` (`:5038`), `parseDeliveryGate` (`:5121`) become structured
  reads; `_detectFlat` (`:3428`) changes filename only; `_stripScalarQuotes` (`:137`) and
  `stripYamlInlineComment` (`:565`) are wired into the state path.
- Two deletions with no Python counterpart: `hasTableSep` (`:1648`), whose only job is telling a
  markdown header row from a separator row, and `extractLatestHistoryDate` (`:1690`), which
  becomes `max(lifecycle_history[].date)`.
- The seven `join(workDir, "STATE.md")` / `join(..., "STATE.md")` state sites move to `STATE.yml`
  (`:3062`, `:3416`, `:3986`, `:4189`, `:4272`, `:4321`, `:4710`).
- The four state-path **label** strings retargeted with them (`:3063`, `:3982`, `:4184`, `:5439`) --
  the Node counterpart of the Python twin's `state_path_label` strings named in `SPEC.md § L-3`;
  omitting them leaves the Node dashboard displaying `STATE.md` paths for `STATE.yml` files
  (`SPEC.md § L-4`).
- **Two sites must NOT change**, both the out-of-scope discovery-area ledger:
  `join(kbDir, "STATE.md")` (`:879`) and `SKIP_NAMES` (`:1528`), which excludes `STATE.md` from
  the KB doc set. A blind find-and-replace hits both; editing either is a scope defect and is the
  single easiest mistake to make in this work.
- Legacy detection, graceful degradation, the one-read-per-work cost property and the
  `MAX_READ_BYTES` bounded read are ported with the same observable behavior as task-003.
- The lockstep comment pair (`state_schema.py:29-32` and its `reader.mjs` counterpart) is
  refreshed in this file too, and the implicit-typing divergence note is kept accurate.
- OUT of this task: the conformance corpus that PROVES the parity (task-005), the cross-format
  characterization suite (task-011), and updating the existing dashboard suites (task-016).

**Acceptance Criteria:**
- [ ] For every input the task-003 parser accepts, `reader.mjs` produces the same values; for
      every input it rejects, `reader.mjs` emits the same `parse_warning`, skips the same key and
      raises nothing (SP-1, NFR-1).
- [ ] `join(kbDir, "STATE.md")` (`:879`) and `SKIP_NAMES` (`:1528`) are byte-unchanged, and the
      diff is cited as evidence that the out-of-scope ledger was not touched.
- [ ] All seven work-tree state-path sites and their four labels resolve `STATE.yml`;
      `grep -n 'STATE\.md' reader.mjs` returns only the two out-of-scope ledger sites plus any
      explicitly labelled legacy-detection reference (SP-15).
- [ ] `hasTableSep` and `extractLatestHistoryDate` are deleted and `grep` shows no residual
      caller; the newest lifecycle-history date is derived as `max(lifecycle_history[].date)` and
      matches the pre-refactor value for the same work.
- [ ] `_detectFlat` still applies the identical three-part rule, retargeted only by filename
      (SP-7).
- [ ] An absent, empty, truncated, unknown-key-carrying or legacy-`STATE.md` file yields a
      best-effort payload with a `parse_warning` naming the file and no thrown error; the legacy
      warning names the migration command (SP-9).
- [ ] Exactly one file read per work; no added stat or glob; `MAX_READ_BYTES` applies to
      `STATE.yml` (SP-10).
- [ ] The repo-root `package.json` dependency block is unchanged and `reader.mjs` imports no YAML
      library (SP-17, C-3).
- [ ] Both twins' lockstep comments describe the new parse path and name each other (C-4).
- [ ] All section-6 quality gates pass.
