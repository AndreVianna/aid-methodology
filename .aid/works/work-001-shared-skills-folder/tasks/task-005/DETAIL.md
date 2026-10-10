# task-005: One `AGENTS.md` root context source, root-file selection, and the `CLAUDE.md` migration function

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-14, AC-16

**Depends on:** task-004

**Scope:**
- `canonical/AGENTS.md` (new): the single root-context region source, replacing
  `profiles/{codex,cursor,copilot-cli,antigravity}/AGENTS.md` and `profiles/claude-code/CLAUDE.md`.
  It carries the `<!-- AID:BEGIN -->` / `<!-- AID:END -->` region taken from today's
  `profiles/*/AGENTS.md`, with runtime paths written as `.aid/runtime/templates/...` and "Read"
  lines (no `@` imports). It sits outside the review-criteria registry's corpus, like
  `canonical/EMISSION-MANIFEST.md`, so no registry row is owed.
- Delete the five profile root files listed above.
- `_root_agent_file` / `Get-RootAgentFile`: return `AGENTS.md` for every tool.
- The C2 heading-stem list in `_copy_root_agent_file` and `Test-AidHeadingStem` gains
  `Review criteria`, and any other `## ` heading of the region that the list lacks, so a C2
  migration never duplicates a section.
- `_migrate_claude_md` / `Invoke-MigrateClaudeMd` (new), per REQUIREMENTS.md § 11 Feature 001 ›
  Layers & Components › Root context file: (a) sha equals the format-2-recorded sha -> delete;
  (b) markers present and edited -> whole file to the trash via `trash_file` first, then the region
  is removed including the marker lines and every other byte is kept, and a whitespace-only
  remainder is deleted; (c) no markers and edited -> byte-unchanged, and print exactly
  `WARN: aid: CLAUDE.md kept as-is; remove its AID sections (<the C2 stems found>) by hand -- AID instructions now live in AGENTS.md`;
  a `CLAUDE.md` the format-2 manifest does not record and that has no markers is never touched.
  The function is called by the migration (task-015); nothing calls it yet.
- The `@AGENTS.md` fallback for a failed AC-20 A-3 check is NOT built (§ 11 Gap 1).
- Retire `tests/canonical/test-agents-md-invariant.sh` (its subject, the per-profile copies, is
  gone) with one `tests/coverage-accepted-removals.tsv` row per removed key; re-key the
  `profiles/claude-code/CLAUDE.md` / `profiles/codex/AGENTS.md` rows of
  `tests/canonical/test-connector-skills-structural.sh` to `canonical/AGENTS.md`.
- Known red from here until their re-key tasks: CLI-suite assertions that a `claude-code`
  install writes `CLAUDE.md` (`test-aid-cli.sh` and `test-aid-cli-ps1.sh` -> task-019,
  `test-multitool-isolation.sh` -> task-018, `test-aid-cli-parity.sh` -> task-023,
  `tests/windows/Test-AidInstaller.ps1` -> task-024).
- Function-level cases for `_migrate_claude_md` (cases a, b, b-with-empty-remainder, c, and the
  untouched unrecorded file) and, where `pwsh` exists, `Invoke-MigrateClaudeMd`, added to
  `tests/canonical/test-install-core-primitives.sh`.

**Acceptance Criteria:**
- [ ] `grep -c '^<!-- AID:BEGIN -->$' canonical/AGENTS.md` and `grep -c '^<!-- AID:END -->$' canonical/AGENTS.md` each print `1`; `grep -cE '\.(claude|codex|cursor|agent)/|\.github/aid/|canonical/|^@' canonical/AGENTS.md` prints `0`.
- [ ] `ls profiles/*/AGENTS.md profiles/claude-code/CLAUDE.md` reports every path as missing.
- [ ] With the core sourced, `_root_agent_file <tool>` prints `AGENTS.md` for each of the five tools; `Get-RootAgentFile` does the same where `pwsh` exists.
- [ ] For every `## ` heading inside the region of `canonical/AGENTS.md`, the C2 stem test of both shells returns true (a loop over the headings shows no miss).
- [ ] The `_migrate_claude_md` cases hold: (a) the file is gone; (b) the file equals, byte-for-byte, the pre-run content minus the marked region including its marker lines, and the pre-run bytes exist at `.aid/.trash/CLAUDE.md`; (b, empty remainder) the file is gone; (c) the file's sha256 is unchanged and the output contains the exact WARN line; (unrecorded, no markers) the file's sha256 is unchanged and nothing is printed.
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-install-core-primitives.sh` and `bash tests/canonical/test-connector-skills-structural.sh` exit `0`; `tests/canonical/test-agents-md-invariant.sh` no longer exists.
- [ ] `bash tests/canonical/test-ps51-compat.sh` and `bash tests/canonical/test-ascii-only.sh` exit `0`.
- [ ] All section-6 quality gates pass.
