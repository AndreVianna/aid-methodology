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
  - carrier equality: `AID_SUPPORTED_FORMAT` in `bin/aid`, `AidSupportedFormat` in `bin/aid.ps1`,
    `$script:_AidSupportedFormat` in `lib/AidInstallCore.psm1` and the `format_version` line of
    `canonical/aid/templates/settings.yml` all equal `5` (one above the pre-change `4`);
  - a fresh fixture with no manifest, recovery record or v3 legacy evidence (FR-11) and no settings
    successfully adds a tool, then a second `aid add` of another tool exits 0; a format-3 manifest with stamp 4 is refused
    unchanged;
  - a pending upgrade recovery record, with no manifest or with a format-3 manifest, makes
    `aid add` and `aid remove` exit 2, name `aid update`, and leave the fixture snapshot unchanged;
  - a manifest whose `format_version` is above 3 makes the CLI exit non-zero with
    `Run: aid update self` and write nothing (sha256 snapshot unchanged), for `aid add`,
    `aid update` and `aid status` (bash always; PowerShell when `pwsh` is present).

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-layout-format-guard.sh --verbose` exits `0` with `PASS:` lines for carrier equality, fresh missing-settings add, format-3/stamp-4 refusal, manifest-less legacy after projects-add migration, recovery add/remove gates, and future-format read-only refusal (including when a recovery record exists); every refusal preserves the fixture snapshot.
- [ ] Changing the value in one carrier, including the template line, to `6` in a scratch copy makes the carrier-equality assertion fail.
- [ ] All section-6 quality gates pass.
