# task-020: Layout-format guard suite with a frozen format-4 install core

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

**Type:** TEST

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-12

**Depends on:** task-006, task-007

**Scope:**
- `tests/canonical/fixtures/format4-core/` (new): byte copies of the pre-change
  `lib/aid-install-core.sh` and `lib/AidInstallCore.psm1`, taken from the work's base commit with
  `git show <base>:lib/aid-install-core.sh` (the base is the merge-base of this branch with
  `master`), plus a short `README.md` stating what they are and that they must never be edited.
- `tests/canonical/test-layout-format-guard.sh` (new; S1 to S5, `HOME` pinned):
  - carrier equality: `AID_SUPPORTED_FORMAT` in `bin/aid`, `AidSupportedFormat` in `bin/aid.ps1`,
    `$script:_AidSupportedFormat` in `lib/AidInstallCore.psm1` and `PAYLOAD_LAYOUT_FORMAT` in
    `release.sh` all equal `5` (one above the pre-change `4`);
  - the new CLI's `aid add` into a format-4-layout fixture exits non-zero, names `aid update`, and
    the fixture's sha256 snapshot is unchanged;
  - FR-5 guarantee: the frozen format-4 core, given each new artifact from `tests/lib/bundle.sh`
    staging (`aid-<tool>-v<V>.tar.gz` and `aid-shared-v<V>.tar.gz`), exits non-zero (its
    `extract_tarball` wrapping-directory check) and the target tree's sha256 snapshot is unchanged;
    the same through the frozen `AidInstallCore.psm1` when `pwsh` is present.

**Acceptance Criteria:**
- [ ] `cmp tests/canonical/fixtures/format4-core/aid-install-core.sh <(git show "$(git merge-base HEAD master)":lib/aid-install-core.sh)` succeeds, and likewise for `AidInstallCore.psm1`.
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-layout-format-guard.sh --verbose` exits `0` with `PASS:` lines for carrier equality, the format-4 refusal (exit, message, unchanged snapshot) and the frozen-core refusal for every new artifact.
- [ ] Changing `PAYLOAD_LAYOUT_FORMAT` to `6` in a scratch copy of `release.sh` makes the carrier-equality assertion fail.
- [ ] All section-6 quality gates pass.
