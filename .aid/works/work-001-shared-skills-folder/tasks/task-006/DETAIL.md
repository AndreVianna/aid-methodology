# task-006: Bump the layout format to 5 and add the layout and version-skew gates

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-11, AC-12

**Depends on:** task-004

**Scope:**
Bash and PowerShell twins together (`bin/aid` + `lib/aid-install-core.sh` and `bin/aid.ps1` +
`lib/AidInstallCore.psm1`), per REQUIREMENTS.md § 11 Feature 001 › Data Model › Format stamp and
Feature Flow › 3 (steps 2 to 4).
- Format stamp 4 -> 5 in all three carriers in one commit: `readonly AID_SUPPORTED_FORMAT` in
  `bin/aid`, `AidSupportedFormat` in `bin/aid.ps1`, `$script:_AidSupportedFormat` in
  `lib/AidInstallCore.psm1`. The comment block above `readonly AID_SUPPORTED_FORMAT` gains the line
  `format 5 (was 4): shared skills under .agents/skills (+ CLI-owned mirrors), runtime under .aid/runtime/, one AGENTS.md pointer region for every tool, a CLAUDE.md @AGENTS.md import region while claude-code is installed; manifest format_version 3`.
- Stamp cap in `_aid_migrate_repo` and its PowerShell twin: write `format_version: 5` only when the
  manifest is absent or records `format_version` 3; otherwise write `4` (so `aid update self` and
  `aid projects add` never stamp a v3-layout repo as 5).
- `_aid_layout_gate` (new) and its twin, run by `aid add` after the writability pre-check: a
  manifest exists and records `format_version` < 3, or the settings stamp is < 5 -> exit 2, print
  `This project uses the v3 AID layout. Run: aid update (it upgrades every installed tool), then retry aid add.`,
  write nothing.
- Skew gate inside the `FR11: aid add version selection` block and its twin: a `tools.*.version` or
  `shared.*.version` differing from `aid_version` -> exit 2, message names `aid update`. The existing
  `--version <v>` != project version -> exit 2 rule is unchanged.
- Manifest `format_version` above 3 -> refuse with `Run: aid update self` (readers from task-004); no
  layout-format field is read or written. A `format_version` 2 manifest triggers the clean-slate
  upgrade in `aid update` and the refusal in `aid add`.
- The format gate's `repo > 5` refusal follows from the bump; `_aid_format_gate` logic is unchanged.
- Known red from here until their re-key tasks: suites asserting stamp `4` or exercising `aid add`
  on a format-2 manifest (`test-aid-cli.sh`/`test-aid-cli-ps1.sh` -> task-019, `test-aid-migrate.sh`
  -> task-021, `test-aid-cli-parity.sh` -> task-023, `test-registry.sh`/`test-self-commands.sh`/
  `test-release-migrate-smoke.sh` -> task-025).
- Known red from here until their re-key tasks: suites asserting stamp `4` or exercising `aid add`
  on a format-2 manifest (`test-aid-cli.sh`/`test-aid-cli-ps1.sh` -> task-019, `test-aid-migrate.sh`
  -> task-021, `test-aid-cli-parity.sh` -> task-023, `test-registry.sh`/`test-self-commands.sh`/
  `test-release-migrate-smoke.sh` -> task-025).
- Deferred review note (definition-gate ledger row 18): Literal fallbacks of the format number 4 also live in `lib/aid-install-core.sh` and twice in `bin/aid` (search `SUPPORTED_FORMAT:-`); bump them with the three carriers, or a library consumer seeds `format_version: 4` into a layout-5 project.

**Acceptance Criteria:**
- [ ] `grep -E 'readonly AID_SUPPORTED_FORMAT=' bin/aid`, the `AidSupportedFormat` assignment in `bin/aid.ps1` and the `$script:_AidSupportedFormat` assignment in `lib/AidInstallCore.psm1` all carry the value `5`, and the new comment line is present above the bash constant, containing both `one AGENTS.md pointer region for every tool` and `a CLAUDE.md @AGENTS.md import region while claude-code is installed`.
- [ ] In a fixture holding a format-2 manifest and `format_version: 4` settings, `aid add cursor` exits `2`, prints the layout-gate message (`This project uses the v3 AID layout. Run: aid update ...`), and a sha256 snapshot of the fixture tree (`find . -type f -exec sha256sum {} +`, sorted) is unchanged.
- [ ] In a fixture whose format-3 manifest records `tools.codex.version` different from `aid_version`, `aid add cursor` exits `2` and its output contains `aid update`; the fixture snapshot is unchanged.
- [ ] `_aid_migrate_repo` on a fixture with a format-2 manifest writes `format_version: 4`; on a fixture with no manifest, or a format-3 manifest, writes `format_version: 5`.
- [ ] In a fixture holding a format-3 manifest and a settings stamp of `4` (the state left by `aid update self`), `aid add cursor` exits `2`, prints the layout-gate message, and the fixture snapshot is unchanged.
- [ ] A manifest with `"format_version": 4` makes `aid status` refuse with a message containing `Run: aid update self`.
- [ ] Each case above gives the same exit code and output lines under `bin/aid.ps1` where `pwsh` exists.
- [ ] `bash tests/canonical/test-ps51-compat.sh` and `bash tests/canonical/test-ascii-only.sh` exit `0`.
- [ ] All section-6 quality gates pass.
