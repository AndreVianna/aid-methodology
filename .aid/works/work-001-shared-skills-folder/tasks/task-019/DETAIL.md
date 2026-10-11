# task-019: Re-key the CLI suites to the shared layout and cover version skew and tool detection

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-11, AC-15

**Depends on:** task-012, task-013, task-014, task-015

**Scope:**
- `tests/canonical/test-aid-cli.sh` and `tests/canonical/test-aid-cli-ps1.sh`: build bundles with
  `tests/lib/bundle.sh` instead of tarring `profiles/<tool>/`; re-key every layout assertion
  (`<root>/aid/`, `<root>/skills/`, `CLAUDE.md`, manifest format 2, stamp 4) to the shared layout.
- AC-11 (extend the `FR11` cases): in a fixture at project version X, `aid add cursor --version Y`
  (Y != X) exits `2` and a sha256 snapshot of the whole fixture tree is unchanged; `aid add cursor`
  installs cursor at X; a manifest whose tools record differing versions makes `aid add` exit
  non-zero with `aid update` in the message; `aid update --from-bundle <staging>` leaves every tool
  `version` and every shared-entry `version` equal to `aid_version`; `aid add cursor --from-bundle
  <dir staged at a different version>` into a project at another version exits non-zero and the
  whole-tree sha256 snapshot is unchanged (the `_check_staged_version` / `Test-StagedVersion`
  check).
- AC-15: `detect_tool` on a fixture holding only `.agents/` exits `2` and prints no `codex`; on a
  fixture holding `.codex/` prints `codex`; the `Detect-Tool` twin in `test-aid-cli-ps1.sh` (guarded
  by `pwsh` presence as that suite already does).
- Bare-project regression: in a fixture, `aid projects add <dir>` then `aid add cursor --target <dir> --from-bundle <stage>` exits `0`; a v3-style bare fixture (hand-made format-2 manifest with no tools plus `.aid/settings.yml` holding `format_version: 4`) also accepts `aid add cursor`, after which the manifest records `format_version` 3 and `.aid/settings.yml` shows `format_version: 5`.
- Removed or renamed keys get rows in `tests/coverage-accepted-removals.tsv` or the re-home
  allowlist.

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-aid-cli.sh --verbose` exits `0`, with `PASS:` lines for each AC-11 clause and both AC-15 detect cases.
- [ ] The same `test-aid-cli.sh` run prints a `PASS:` line for the `--from-bundle` version-mismatch refusal (non-zero exit, unchanged snapshot, `aid update` in the message), and `test-aid-cli-ps1.sh` the same where `pwsh` exists.
- [ ] The `test-aid-cli.sh` run prints a `PASS:` line for the update-all regression: after the `_cmd_update_all` cache is built for a registered cursor project it holds `aid-cursor-v<V>.tar.gz`, `aid-shared-v<V>.tar.gz` and `SHA256SUMS`, and the child `update --from-bundle <cache>` exits `0`.
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-aid-cli-ps1.sh` exits `0` where `pwsh` exists, including the `Detect-Tool` cases.
- [ ] `grep -cE 'profiles/[a-z-]+/' tests/canonical/test-aid-cli.sh tests/canonical/test-aid-cli-ps1.sh` prints `0` for both.
- [ ] The coverage-parity gate (run where `pwsh`, `node` and `python3` are on PATH) reports no un-excused removal for these two suites.
- [ ] `test-aid-cli.sh` prints a `PASS:` line for the bare-project regression (`aid projects add <dir>` then `aid add cursor --target <dir> --from-bundle <stage>` exits `0`; the v3-style bare fixture with stamp-4 settings also exits `0` and ends with `format_version: 5`), and `test-aid-cli-ps1.sh` the same where `pwsh` exists.
- [ ] Existing format-3 manifest with settings stamp 4 refuses `aid add` unchanged; a manifest-less legacy tree continues refusing after projects-add/update-self settings migration; future formats remain read-only refused.
- [ ] All section-6 quality gates pass.
