# task-021: Restore the coarse-updated fallback on the Python twin and close the KI-004 divergence

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Added POST-GATE, after task-004 surfaced KI-004; it is therefore not present in the gated
`PLAN.md § Execution Graph`, and that omission is deliberate rather than drift -- re-gating four
definition documents to add one task would cost more than it informs. Its dependency edge
(`task-003`, `task-004`) and its wave placement are recorded in the work-root state file's
`## Lifecycle History`. This is a flattened Lite work, so there is NO sibling `task-021/STATE.md`
-- this task's mutable cells live only in the work-root state file's `### Tasks lifecycle` table.
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

**Depends on:** task-003, task-004

**Scope:**
- The defect, recorded as `known-issues.md § KI-004` and measured rather than inferred:
  `dashboard/reader/derivation.py`'s `_extract_latest_history_date` (`:905`) scans raw text for a
  markdown `## Lifecycle History` **table**. After task-002 that table does not exist --
  `lifecycle_history` is a YAML sequence -- so the scan is dead against every `STATE.yml`. Measured:
  it returns `None` for a `STATE.yml` document where the markdown form returned `'2026-08-12'`. It is
  still called at five sites: `:722`, `:735`, `:753`, `:771`, `:783`.
- Two consequences, and this task closes both:
  1. **A behavior regression on the Python side.** Pre-refactor, a work lacking an authoritative
     `updated` still derived a coarse date from its history. It no longer does. A `restructure`
     forbids that, and `derivation.py` was out of edit scope for BOTH task-003 and task-004, so no
     existing task owns the fix -- which is precisely why this task exists.
  2. **The delivery's first genuine twin divergence.** task-004 had no equivalent module boundary and
     replaced the dead scan with `computeLatestHistoryDate()` = `max(lifecycle_history[].date)` over
     the already-parsed array. Node derives a date where Python derives `None`.
- The change, mirroring the Node twin function-for-function (NFR-1, C-4 -- the same porting
  discipline task-004 followed against task-003):
  - Compute the newest history date from the **already-parsed** `lifecycle_history` sequence, as
    `max` over its entries' `date` values, skipping non-string and null-sentinel (`--`) values. No
    second file read, no re-scan of raw text -- the array is already in hand at the call site
    (SP-10's one-read property must not regress).
  - Thread that value into `derive_lifecycle` the way `reader.mjs` threads `latestHistoryDate`, so
    all five call sites receive it identically instead of each re-deriving it.
  - `_extract_latest_history_date` is **deleted**, with its `_RE_HISTORY_SECTION` helper if that
    regex has no other consumer -- check before deleting, and name any surviving consumer in the
    commit message.
- **Behavior for a file that HAS `lifecycle` or `updated` must not change at all.** The fallback is
  consulted only when there is no authoritative value; every other input must produce the identical
  model it produces today. This is a regression fix, not an opportunity to improve derivation.
- OUT of this task: `models.py` and `io_bounds.py` (untouched); `parsers.py` beyond the minimum
  needed to hand the parsed sequence to the call site; the Node twin (already correct -- do NOT
  change `reader.mjs` to match Python's broken behavior, the direction of the fix is Python toward
  Node); the conformance corpus (task-005) and the cross-runtime characterization suite (task-011),
  which consume this fix rather than contain it; every existing suite (task-016).

**Acceptance Criteria:**
- [ ] For a `STATE.yml` with **no `lifecycle` key, no `updated` key, and a populated
      `lifecycle_history`**, the Python twin derives the same coarse date as the Node twin -- the
      exact three-condition case KI-004 identifies. Asserted by running BOTH runtimes over one
      fixture and comparing, because this is the case two independent parity harnesses already
      missed.
- [ ] `_extract_latest_history_date` is deleted and `grep` over `dashboard/` shows no residual
      caller; `_RE_HISTORY_SECTION` is deleted too or its surviving consumer is named in the commit
      message.
- [ ] The derived value equals `max(lifecycle_history[].date)` for an **out-of-order** date list, and
      null-sentinel (`--`) and non-string entries are skipped rather than winning the comparison.
- [ ] Every input carrying an authoritative `lifecycle` or `updated` produces a byte-identical model
      to the pre-task-021 reader -- verified by diffing `read_repo` output over a multi-work fixture
      before and after, not by inspection.
- [ ] No second file read and no added stat or glob: the parsed sequence already in hand is used
      (SP-10).
- [ ] `models.py` and `io_bounds.py` are byte-unchanged; `reader.mjs` is byte-unchanged; no module
      under `dashboard/reader/` imports a YAML library and `packages/pypi/pyproject.toml` still
      declares `dependencies = []` (C-3, SP-17).
- [ ] `known-issues.md § KI-004` is updated to record the resolution and which of its three options
      was taken.
- [ ] All section-6 quality gates pass.
