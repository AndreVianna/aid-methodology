# task-020: Layout-format guard suite for the v3 layout and newer manifests

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

**Depends on:** task-006, task-007, task-012, task-013, task-015

**Scope:**
- `tests/canonical/test-layout-format-guard.sh` (new; S1 to S5, `HOME` pinned; fixtures built per
  run, no frozen v3 core and no guard artifact -- v4 requires CLI v4, so v3 CLI behaviour is not
  tested):
  - carrier equality: `AID_SUPPORTED_FORMAT` in `bin/aid`, `AidSupportedFormat` in `bin/aid.ps1` and
    `$script:_AidSupportedFormat` in `lib/AidInstallCore.psm1` all equal `5` (one above the
    pre-change `4`);
  - the new CLI's `aid add` into a v3-layout fixture (a format-2 manifest) exits `2`, writes
    nothing, names `aid update`, and the fixture's sha256 snapshot is unchanged;
  - a pending upgrade recovery record, with no manifest or with a format-3 manifest, makes
    `aid add` and `aid remove` exit 2, name `aid update`, and leave the fixture snapshot unchanged;
  - a manifest whose `format_version` is above 3 makes the CLI exit non-zero with
    `Run: aid update self` and write nothing (sha256 snapshot unchanged), for `aid add`,
    `aid update` and `aid status` (bash always; PowerShell when `pwsh` is present).

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-layout-format-guard.sh --verbose` exits `0` with `PASS:` lines for carrier equality (three values), the v3-layout `aid add` refusal (exit `2`, message naming `aid update`, unchanged snapshot) the recovery-record add/remove gates (exit 2, `aid update`, unchanged snapshot), and the `format_version` above 3 refusal (exit, `Run: aid update self`, unchanged snapshot), including when a recovery record also exists.
- [ ] Changing the value in one carrier to `6` in a scratch copy makes the carrier-equality assertion fail.
- [ ] All section-6 quality gates pass.
