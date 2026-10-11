# task-013: Drift report for shared files in `aid status`

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-10

**Depends on:** task-010, task-012

**Scope:**
Bash and PowerShell twins together, per REQUIREMENTS.md § 11 Feature 001 › Feature Flow › 8.
- `drift_report` (new; called by `aid_status` in `lib/aid-install-core.sh`) and
  `Get-AidDriftReport` (new; called by `Get-AidStatus` in `lib/AidInstallCore.psm1`).
- Checked: every file of `shared.skills`; each mirror against the `shared.skills` hashes (read
  relative to the mirror); `shared.runtime` (including `host.conf`); the `AGENTS.md` region against
  `shared.agents_md.region_sha256`; the `CLAUDE.md` import region against
  `shared.claude_md.region_sha256` when that entry exists (a `CLAUDE.md` that is absent or has lost
  its markers is reported `missing:`); each tool's `files`. An extra is an `aid-*` entry in `.agents/skills/` or a mirror
  that the manifest does not list, or an unrecorded file in `.aid/runtime/`.
- Output: after the existing header and tools block, a `Shared files` block listing each
  `modified:`, `missing:` or `extra:` path, then
  `Run: aid update (drifted files are moved to .aid/.trash/ first)`; or `Shared files: clean`.
- Runtime-local paths (FR-6: any `node_modules/` under `.aid/runtime/`) are never reported as
  `extra:` and never byte-compared; the `extra:` rule above applies outside them only.
- Hashing in one batch: a single python3 `hashlib` pass, or one `sha256sum`/`shasum` call over the
  file list; PowerShell uses `Get-FileHash` per file.
- Exit code stays `0` (drift is informational), or `7` with no manifest. For a format-2 manifest,
  print `Layout: format 4 (pre-shared). Run: aid update` and skip the drift check. The bare `aid`
  dashboard (`aid_status_body` / `Get-AidStatusBody`) does NOT run the drift check.
- Non-`aid-*` entries are never read. The repair side of FR-9 (rewrite after trashing) is
  `copy_file_guarded` on add (task-009) and update (task-014).
- Fixture recipe as in task-008. Known red: the CLI suites listed in task-006.

**Acceptance Criteria:**
- [ ] After `aid add claude-code`, appending one byte to `.claude/skills/aid-ask/SKILL.md`, deleting `.claude/skills/aid-fix/SKILL.md` and appending one byte to `.agents/skills/aid-plan/SKILL.md`, `aid status` exits `0` and its output names all three paths (as `modified:`, `missing:`, `modified:`) and contains `aid update`.
- [ ] Adding `.agents/skills/aid-zzz/SKILL.md` and `.aid/runtime/stray.txt` makes `aid status` list both as `extra:`; adding `.agents/skills/my-skill/SKILL.md` adds no line.
- [ ] Editing a line inside the `AGENTS.md` region is reported as `modified: AGENTS.md`, and editing inside the `CLAUDE.md` import region as `modified: CLAUDE.md`; editing outside either region is not reported.
- [ ] After `aid add claude-code`, deleting `CLAUDE.md` makes `aid status` print `missing: CLAUDE.md`, and so does a `CLAUDE.md` whose marker lines were removed; with `claude-code` not installed no `CLAUDE.md` line is printed.
- [ ] On a clean install `aid status` prints `Shared files: clean`; on a format-2 manifest fixture it prints `Layout: format 4 (pre-shared). Run: aid update` and exits `0`; with no manifest it exits `7`.
- [ ] A fixture file `.aid/runtime/scripts/summarize/node_modules/x.js` (modified after install) produces no `extra:` or `modified:` line.
- [ ] The bare `aid` dashboard output on the drifted fixture contains no `Shared files` line.
- [ ] `bin/aid.ps1 status` on the same fixtures prints the same lines and exit codes where `pwsh` exists; `bash tests/canonical/test-ps51-compat.sh` and `bash tests/canonical/test-ascii-only.sh` exit `0`.
- [ ] All section-6 quality gates pass.
