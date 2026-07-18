# task-024: delete-pipeline.sh guarded destructive writer

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

**Depends on:** -- (none)

**Scope:**
- **Objective:** Build the sole component that performs a pipeline delete -- a new, co-vendored, guarded destructive bash writer `delete-pipeline.sh` that removes a work's on-disk artifacts worktree-aware, refuses unsafe deletes, and retains the git branch. (feature-009 SPEC §Layers component 2, §API Contracts `delete-pipeline.sh` contract, §Security Specs.)
- **New file** `dashboard/` co-vendored writer (path added to `dashboard/MANIFEST` -- see plumbing bullet), self-located from `$AID_CODE_HOME` (same discipline as feature-001's `write-setting.sh` / `write-requirement.sh`). `set -euo pipefail` (the dominant coding-standards strict mode -- exactly what `.claude/aid/scripts/works/enumerate-works.sh` uses -- NOT a weakened mode for an irreversible op); fixed-argv git only (`git -C <repo> ...`), no shell string, no `eval`; expected-nonzero git calls guarded / degrade in-subshell rather than relaxing the whole script.
- **CLI:** `delete-pipeline.sh --work-id <work_id>` with env `AID_REPO_ROOT=<abs main repo root>`. `work_id` is the full folder name (e.g. `work-017-cli-improvements`), validated `^work-[0-9]+(-[a-z0-9][a-z0-9-]*)?$`.
- **Worktree-aware enumeration** (Algorithm steps 2-3): `REPO="${AID_REPO_ROOT:-$PWD}"`; enumerate roots via `git -C "$REPO" worktree list --porcelain` -- the bash mirror of the reader's `enumerate_worktree_roots` (`dashboard/reader/locator.py` line 126) -- yielding the same `(branch_label, aid_dir)` pairs feature-001's resolver consumes (`aid_dir.parent` = worktree root; main root always first and always included; degrade to main-only on any git failure).
- **Reconcile-winner select** (steps 4-5): `FOUND` = every root `R` where `-d "$R/.aid/works/<work_id>"`; empty `FOUND` -> **exit 1** (404). Select the SINGLE reconciled winner `$W` by the same rule as `_reconcile_same_work` step 2 (`dashboard/reader/reader.py` line 131): newest STATE.md frontmatter `updated`; tie -> `branch_label` lexical with `main` first. `$W` must therefore be exactly the copy the reader rendered and `resolve_work_dir` returned. ONLY `$W` is removed -- a `work_id` shadowed in another worktree is NOT bulk-deleted (WT-1 symmetry). `$W`'s worktree root is its `aid_dir.parent`.
- **Guards before ANY removal** (step 6), evaluated on `$W`: **Running guard** -- read `$W/.aid/works/<work_id>/STATE.md` frontmatter `lifecycle` scalar (same leading-`---` block scan `enumerate-works.sh` uses); `== Running` -> **exit 7**. **Current-worktree guard** -- `CUR = git -C "$PWD" rev-parse --show-toplevel`; if `$W` is a non-main worktree slated for `worktree remove` and its realpath equals `CUR` -> **exit 7** (cannot remove the worktree you run from; the main worktree is never a removal target).
- **Folder-only vs folder+worktree classification BY CONTENT** (step 7), never by a `.claude/worktrees/`+basename path match (persistent worktrees are user-registered at arbitrary paths per `aid-execute/SKILL.md`): `$W` is **main** -> `rm -rf -- "$W/.aid/works/<work_id>"` (the main worktree is never removed, only the folder within it); `$W` is a **dedicated** non-main worktree (its `.aid/works/` contains ONLY `<work_id>`) -> `git -C "$REPO" worktree remove --force -- "$W"` (removes folder + worktree together; git auto-cleans the `.git/worktrees/<name>` admin dir); `$W` is a **shared** non-main worktree (its `.aid/works/` hosts other works too) -> `rm -rf -- "$W/.aid/works/<work_id>"` only.
- **realpath containment** (step 7): realpath of `$W/.aid/works/<work_id>` MUST be a child of realpath `$W/.aid/works/`; else **exit 3** (defeats symlink/`..` traversal).
- **Lock + verify:** best-effort `writeback-state.sh`-style sentinel lock on the work folder before removal (contention -> **exit 2**); after removal, the removed folder MUST no longer exist -- residue -> **exit 3**.
- **Branch retained** (step 9): the git branch is never touched (OQ-PL3 -- the branch is the sole recovery anchor; worktree removal stays reversible via `git worktree add <path> <branch>`).
- **Exit-code alphabet** (feeds feature-001's exit->HTTP map + the exit-7 row added by task-025): `0` ok; `1` not-found; `2` lock contention/busy; `3` removal failed / residue / containment failure; `4` invalid `work_id` (regex backstop); `5` missing `--work-id` (backstop -- the server always supplies it); `7` guard tripped (Running or current-worktree). On `0`, print `OK: deleted <work_id> (folder[, worktree <path>])` to stdout.
- **Co-vendor plumbing:** append the writer's one path to `dashboard/MANIFEST` (single source from which `vendor.js`, `vendor.py`, `install.sh`, `install.ps1`, and `release.sh`'s CLI bundle derive their file set); `tests/canonical/test-dashboard-manifest.sh` fails CI if the manifest drifts. No op-schema flag, no envelope/`schema_version` change (owned by task-025 on the server side; this writer adds none).

**Acceptance Criteria:**
- [ ] `delete-pipeline.sh` exists, is listed in `dashboard/MANIFEST`, self-locates from `$AID_CODE_HOME`, opens with `set -euo pipefail`, and uses only fixed-argv git (no `eval`, no `shell`-string, no body-supplied path). (AC7 destructive-primitive containment)
- [ ] Given a valid `--work-id` and `AID_REPO_ROOT`, the writer enumerates worktree roots via `git worktree list --porcelain` and selects the single reconciled winner by newest STATE.md `updated` (tie -> `branch_label` lexical, `main` first) -- identical to `resolve_work_dir` / `_reconcile_same_work`. (WT-1)
- [ ] A `work_id` present in no enumerated worktree root exits 1; a `work_id` shadowed across multiple worktrees removes ONLY the reconciled winner and leaves the other copy intact. (WT-1 / AC2 edge case)
- [ ] The Running guard exits 7 with NO removal when the winner's STATE.md frontmatter `lifecycle == Running`. (Guards)
- [ ] The current-worktree guard exits 7 with NO removal when the non-main winner's realpath equals `git -C "$PWD" rev-parse --show-toplevel`; the main worktree is never a removal target. (Guards)
- [ ] Folder-only vs folder+worktree is decided by `.aid/works/` content, not path name: a **main** winner -> `rm -rf` of the folder only; a **dedicated** non-main worktree -> `git worktree remove --force`; a **shared** non-main worktree -> `rm -rf` of the folder only (sibling works untouched). (AC-PD1, AC7)
- [ ] realpath containment: a removal target that is not a realpath child of `$W/.aid/works/` (symlink / `..` escape) exits 3 with NO removal. (Security)
- [ ] Lock contention on the work folder exits 2; a failed `git worktree remove` or post-removal residue exits 3. (exit-code alphabet)
- [ ] After a successful (exit 0) delete the git branch still exists (never deleted). (OQ-PL3)
- [ ] On exit 0 the writer prints `OK: deleted <work_id> ...`; exit codes 0/1/2/3/4/5/7 match the feature-009 failure table (feeds task-025's exit->HTTP map). (API contract)
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
