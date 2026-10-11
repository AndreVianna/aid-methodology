# task-005: One `AGENTS.md` root context source, root-file selection, and the `CLAUDE.md` import-region functions

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
Bash and PowerShell twins together (`lib/aid-install-core.sh`, `lib/AidInstallCore.psm1`), per
REQUIREMENTS.md § 5 FR-12, § 9 AC-14 and § 11 Feature 001 › Layers & Components › Root context
file.
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
- `CLAUDE.md` import region (FR-12; § 11 › Root context file): the *import region* is a fixed
  constant in both cores, never a payload file -- the three lines `<!-- AID:BEGIN -->`,
  `@AGENTS.md`, `<!-- AID:END -->`, each ending in LF.
  - `_ensure_claude_md_region` / `Invoke-EnsureClaudeMdRegion` (new): file missing -> create it
    holding only the import region; markers present -> branch B of `_copy_root_agent_file`: replace
    only the marked region, keep every byte outside the markers, and copy the whole file to the
    trash with `trash_file` first when its region differs from the import region and either has no
    recorded `region_sha256` or no longer matches it; no markers -> append the import region and
    change nothing else (one LF first when the file is non-empty and does not end in LF). Branches
    C1 and C2 never apply to `CLAUDE.md`. In migration mode, a file holding a heading that matches
    a C2 stem makes it print exactly
    `WARN: aid: CLAUDE.md has AID sections outside its managed region (<the C2 stems found>); remove them by hand -- AID instructions now live in AGENTS.md, which CLAUDE.md imports`.
    It yields the region sha256 recorded as `shared.claude_md.region_sha256`; a second run changes
    nothing.
  - `_remove_claude_md_region` / `Invoke-RemoveClaudeMdRegion` (new): when the region no longer
    matches `region_sha256`, copy the whole file to the trash first; remove the region, marker
    lines included, keeping every other byte; delete the file when the remainder is empty or
    whitespace-only; leave a file that has lost its markers byte-unchanged.
  - Neither function runs while no installed tool declares `context_import`; the wiring into add, update,
    remove and migration is tasks 009, 014, 012 and 015.
- Retire `tests/canonical/test-agents-md-invariant.sh` (its subject, the per-profile copies, is
  gone) with one `tests/coverage-accepted-removals.tsv` row per removed key; re-key the
  `profiles/claude-code/CLAUDE.md` / `profiles/codex/AGENTS.md` rows of
  `tests/canonical/test-connector-skills-structural.sh` to `canonical/AGENTS.md`.
- Known red from here until their re-key tasks: CLI-suite assertions that a `claude-code`
  install writes the full region into `CLAUDE.md` (`test-aid-cli.sh` and `test-aid-cli-ps1.sh` ->
  task-019, `test-multitool-isolation.sh` -> task-018, `test-aid-cli-parity.sh` -> task-023,
  `tests/windows/Test-AidInstaller.ps1` -> task-024).
- Function-level cases for both functions in both shells (PowerShell when `pwsh` exists), added to
  `tests/canonical/test-install-core-primitives.sh`.
- Deferred review note (definition-gate ledger row 36): C1's "root-file sha recorded in the manifest" must name its field: the format-3 manifest has no per-tool root record for the shared `AGENTS.md` write, so record the region/file sha under the shared root-file entry and read it from there.

**Acceptance Criteria:**
- [ ] `grep -c '^<!-- AID:BEGIN -->$' canonical/AGENTS.md` and `grep -c '^<!-- AID:END -->$' canonical/AGENTS.md` each print `1`; `grep -cE '\.(claude|codex|cursor|agent)/|\.github/aid/|canonical/|^@' canonical/AGENTS.md` prints `0`.
- [ ] `ls profiles/*/AGENTS.md profiles/claude-code/CLAUDE.md` reports every path as missing.
- [ ] With the core sourced, `_root_agent_file <tool>` prints `AGENTS.md` for each of the five tools; `Get-RootAgentFile` does the same where `pwsh` exists.
- [ ] For every `## ` heading inside the region of `canonical/AGENTS.md`, the C2 stem test of both shells returns true (a loop over the headings shows no miss).
- [ ] `_ensure_claude_md_region`: on an absent file, the result's bytes equal the import region exactly; on a no-marker file ending in LF, the pre-write bytes are a byte-exact prefix and the only bytes after them are the import region, and a second call leaves the sha256 unchanged; on a non-empty no-marker file NOT ending in LF, the result is the pre-write bytes, one LF, then the import region; on a file with user content above and below a full AID region and no recorded `region_sha256`, the result equals the pre-write content with the marked region (marker lines included) replaced by the import region, and the pre-write bytes exist at `.aid/.trash/CLAUDE.md`; on a no-marker file holding a C2-stem heading in migration mode, the exact WARN line is printed.
- [ ] `_remove_claude_md_region`: on the created-from-absent file the file is gone; on the appended-to-LF-terminated-user-file case the file equals its pre-add bytes; with a drifted region the whole file is first at `.aid/.trash/CLAUDE.md`; a file whose markers were deleted is byte-unchanged.
- [ ] The `Invoke-EnsureClaudeMdRegion` / `Invoke-RemoveClaudeMdRegion` twins give byte-identical results and output lines for every case above where `pwsh` exists.
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-install-core-primitives.sh` and `bash tests/canonical/test-connector-skills-structural.sh` exit `0`; `tests/canonical/test-agents-md-invariant.sh` no longer exists.
- [ ] `bash tests/canonical/test-ps51-compat.sh` and `bash tests/canonical/test-ascii-only.sh` exit `0`.
- [ ] All section-6 quality gates pass.
