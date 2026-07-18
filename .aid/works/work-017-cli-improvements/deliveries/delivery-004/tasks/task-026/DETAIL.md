# task-026: Danger-zone Delete UI + type-to-confirm modal

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.md.
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

**Source:** feature-009-pipeline-delete -> delivery-004

**Depends on:** task-025

**Scope:**
- **Objective:** Add the human gate for the delete op -- a Danger-zone control and a type-to-confirm modal on the pipeline detail view -- gated by `write_enabled`, worktree-agnostic, and wired to POST `pipeline.delete` then re-fetch. (feature-009 SPEC §UI Specs, §Feature Flow.)
- **Placement** (`dashboard/home.html`, pipeline detail route `#/work/<work_id>` only -- `index.html` is NOT touched): append a **"Danger zone"** block to the work-overview body (`work-overview-body`, home.html line 831/859), rendered by `renderWorkHeader` (line 1901) at the end of its build, visually set apart as an `--err`-bordered section (matching the existing `border-err` Blocked-work treatment). It contains a single `btn-danger` **"Delete pipeline"** button. It is NOT nested in the whole-card link on the main grid (`_renderWorkCard` line 1476) -- the destructive control lives only on the per-pipeline page (correct intentionality bar).
- **Write gate:** the ENTIRE Danger zone is rendered ONLY when `model.write_enabled === true` (feature-001's signal). Under `--remote` without `--allow-writes` no delete affordance exists at all (defense-in-depth with the server-side 403).
- **Type-to-confirm modal** (a native `<dialog>` element or a `role="dialog"` overlay -- vanilla JS, no library, consistent with the current home.html):
  - **Worktree-agnostic copy keyed ONLY on `work_id`** -- the DM-1 JSON envelope carries no `branch_label` (non-enumerable on the Node twin, omitted from `_ser_work` on the Python twin), so the modal cannot and does not read it, and does NOT hardcode any `.claude/worktrees/<work_id>` path (persistent worktrees live at arbitrary user-registered paths). The copy states outcomes CONDITIONALLY, verbatim: "This removes the work folder `.aid/works/<work_id>`. If this pipeline has its own worktree, that worktree is removed too; a worktree shared with other pipelines is kept. The git branch is not deleted."
  - **Irreversibility warning** (strong terms), verbatim: "This permanently deletes the pipeline. Any work not pushed to git will be lost and cannot be recovered."
  - **Type-to-confirm:** a text input; the destructive Confirm button stays `disabled` until the typed value === `work_id` (the GitHub "type the name to confirm" pattern). Cancel button, `Esc`, and backdrop click all dismiss with NO side effect.
  - **Accessibility:** focus moves into the modal on open and is trapped; the dialog has an `aria-label` / labelled heading; the Confirm button carries an explicit destructive label ("Delete work-NNN-..."); focus returns to the Delete button on cancel.
- **Action + re-render** (§Feature Flow): Confirm issues `fetch('/r/<id>/api/op', {method:'POST', body:{op:"pipeline.delete", target:{work_id}}})`. On **200**: close the modal, set `location.hash = ""` (main route), and call `doFetch()` (home.html line 1033) for an immediate truthful re-fetch -- the deleted pipeline is gone from the grid (AC2). On **4xx/5xx**: keep the modal open and show the server `error`/`detail` inline (e.g. 409 -> "This pipeline is Running -- Finish it before deleting."; 404 -> "Pipeline not found -- it may already be gone.").
- **Race-safety** relied on (no new code): if the poll re-renders the stale `#/work/<deleted>` route before the hash change lands, `render` (home.html line 1217) already routes an unknown `work_id` to `renderStaleWorkNotice` (called at line 1251) -- graceful degrade, not an error.

**Acceptance Criteria:**
- [ ] The pipeline detail view (`#/work/<work_id>`) shows an `--err`-bordered "Danger zone" block appended to `work-overview-body` (via `renderWorkHeader`) containing a `btn-danger` "Delete pipeline" button; `index.html` is unchanged. (AC7, UI Specs)
- [ ] The Danger zone renders ONLY when `model.write_enabled === true`; under a read-only model it is absent entirely. (AC8)
- [ ] Clicking Delete opens a type-to-confirm modal (native `<dialog>` / `role="dialog"`, vanilla JS) whose Confirm button stays `disabled` until the typed input === `work_id`. (AC7 strong gate)
- [ ] The modal copy is worktree-agnostic (keyed only on `work_id`, no hardcoded worktree path, no `branch_label` read) and states -- verbatim -- folder removal, conditional worktree removal, shared-worktree kept, branch retained, plus the irreversibility warning. (UI Specs)
- [ ] Cancel, `Esc`, and backdrop click dismiss the modal with no side effect and return focus to the Delete button; focus is trapped while open; the dialog is labelled. (Accessibility)
- [ ] Confirm POSTs `/r/<id>/api/op` with `{op:"pipeline.delete", target:{work_id}}`. (API)
- [ ] On 200 the modal closes, `location.hash` is set to `""`, and `doFetch()` re-fetches so the deleted pipeline no longer appears. (AC2)
- [ ] On 4xx/5xx the modal stays open and shows the server `error`/`detail` inline (409 Running message; 404 not-found message). (Feature Flow)
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
