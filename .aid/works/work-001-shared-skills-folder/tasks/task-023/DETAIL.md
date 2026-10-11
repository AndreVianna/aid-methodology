# task-023: Bash/PowerShell parity suites for every shared-layout function

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-16

**Depends on:** task-012, task-013, task-015

**Scope:**
- `tests/canonical/test-aid-cli-parity.sh`: build bundles with `tests/lib/bundle.sh`; re-key the
  existing scenarios to the shared layout; add parity scenarios for Feature Flows 3 to 8 (add,
  update, remove, prune, dogfood-style `update --from-bundle --target`, status drift), each running
  `bin/aid` and `bin/aid.ps1` on twin fixtures and comparing exit codes, output lines, the resulting
  file tree, trash timestamps' format and manifest bytes (masked `installed_at`).
- A static check in the same suite: every twin pair in REQUIREMENTS.md § 11 Feature 001 › Layers &
  Components › Install core table (`read_kv_conf`/`Read-AidKvConf` through the staged-version check
  `_check_staged_version`/`Test-StagedVersion`, including `_is_aid_owned_path`/`Test-AidOwnedPath`,
  `retire_v3_layout`/`Invoke-RetireV3Layout`, the three upgrade-recovery record helper pairs,
  and `_repair_root_region`/`Repair-AidRootRegion`) is
  defined in its file, and the suite names each pair in at least one scenario. The
  pair list lives in the suite itself, not in a work folder.
- `tests/canonical/test-install-parity.sh` and `tests/canonical/test-ps51-compat.sh`: extend to
  the new functions (the PS 5.1 check covers every new PowerShell function: no `??`, no ternary, no
  `-AsHashtable`, ASCII-only).
- Recovery scenarios compare record bytes, validated target selection, retirement-phase retry,
  invalid-record refusal, add/remove gates and successful cleanup in both shells (task-015).
- PowerShell-dependent scenarios stay guarded by `pwsh` presence exactly as the suite guards them
  today. Removed or renamed keys get coverage rows.

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-aid-cli-parity.sh` exits `0` on a host with `pwsh`, with a `PASS:` line per Flow 3 to 8 scenario (identical exit codes, output lines and resulting tree under both shells), and one per twin pair of the static check.
- [ ] Deleting one PowerShell twin (e.g. `Get-AidDriftReport`) in a scratch copy makes the static check fail and name it.
- [ ] `bash tests/canonical/test-install-parity.sh` and `bash tests/canonical/test-ps51-compat.sh` exit `0`.
- [ ] The coverage-parity gate (run where `pwsh`, `node` and `python3` are on PATH) reports no un-excused removal for these suites.
- [ ] All section-6 quality gates pass.
