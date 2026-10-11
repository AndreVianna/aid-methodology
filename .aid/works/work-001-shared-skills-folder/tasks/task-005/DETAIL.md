# task-005: One `rules.md` source, the `AGENTS.md` pointer region, and content-based root-region repair with the `CLAUDE.md` import-region functions

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
REQUIREMENTS.md § 5 FR-12, § 8 A-6, § 9 AC-14 and § 11 Feature 001 › Layers & Components › Root
context file.
- `canonical/aid/rules.md` (new): the single source of the AID rules, replacing the region text of
  `profiles/{codex,cursor,copilot-cli,antigravity}/AGENTS.md` and `profiles/claude-code/CLAUDE.md`.
  It carries the rules text taken from today's `profiles/*/AGENTS.md` region (the text between the
  markers, without the marker lines), with runtime paths written as `.aid/runtime/templates/...`
  and "Read" lines (no `@` imports). It is part of `canonical/aid/`, so it installs verbatim at
  `.aid/runtime/rules.md`; it lies outside the review-criteria registry's corpus
  (`canonical/aid/templates/` only), so no registry row is owed.
- Commit `canonical/aid/rules.md` before deleting the old profile root files. Task-003 depends
  on this task and performs the subsequent full profile wipe; no generator run may destroy the
  extraction source first. Delete the five old root context files listed above after extraction.
- `_root_agent_file` / `Get-RootAgentFile`: return `AGENTS.md` for every tool.
- Region constants, fixed in both cores (never payload files; every line ends in LF). The
  `AGENTS.md` pointer region is exactly these five lines:
  ```
  <!-- AID:BEGIN -->
  <!-- Managed by the AID CLI. Do not edit between the AID markers. -->
  @.aid/runtime/rules.md
  Before acting, read and follow `.aid/runtime/rules.md` (AID rules).
  <!-- AID:END -->
  ```
  The `CLAUDE.md` import region is the three lines `<!-- AID:BEGIN -->`, `@AGENTS.md`,
  `<!-- AID:END -->`. Skills never write inside either region.
- `_repair_root_region <file> <region>` / `Repair-AidRootRegion` (new; one function for both
  files; § 11 › Root context file). It repairs by content, not by marker shape:
  - file missing -> create it holding only the region;
  - file holds exactly the well-formed region (each region line once, in order, adjacent) -> change
    nothing;
  - file holds no AID region line -> append the region at its end, preceded by one LF when the file
    is non-empty and does not end in LF; every pre-existing byte is kept and no trash copy is made;
  - anything else (an orphan or duplicated marker, a partial or repeated region) -> copy the whole
    file to `.aid/.trash/<file>` (collision policy, via `trash_file`), remove every line that
    exactly equals a region line of that file's region wherever it sits, and write one well-formed
    region at the position of the first removed line; every other byte is kept. A second call
    changes nothing and adds no trash entry.
- `_copy_root_agent_file` / `Copy-RootAgentFile`: writes `AGENTS.md` by calling
  `_repair_root_region` with the pointer region, and records `shared.agents_md.region_sha256` and
  `file_sha256`. Fallback (A-6): when any installed or newly added tool's `aid-tool.conf` carries
  `rules_inline=true`, the region written is the BEGIN line, the managed-by comment line, the full
  bytes of `.aid/runtime/rules.md` and the END line instead of the two pointer lines; repair then
  replaces only the span between the BEGIN and END lines and removes no other line.
- `_ensure_claude_md_region` / `Invoke-EnsureClaudeMdRegion` (new): runs whenever an installed tool
  declares `context_import`, and calls `_repair_root_region` with the import region; it yields the
  region sha256 recorded as `shared.claude_md.region_sha256`. A second run changes nothing.
- `_remove_claude_md_region` / `Invoke-RemoveClaudeMdRegion` (new): when the region no longer
  matches `region_sha256`, copy the whole file to the trash first; remove the region, marker
  lines included, keeping every other byte; delete the file when the remainder is empty or
  whitespace-only; leave a file that has lost its markers byte-unchanged.
- Neither CLAUDE.md function runs while no installed tool declares `context_import`; the wiring
  into add, update, remove and the clean-slate upgrade is tasks 009, 014, 012 and 015.
- Retire `tests/canonical/test-agents-md-invariant.sh` (its subject, the per-profile copies, is
  gone) with one `tests/coverage-accepted-removals.tsv` row per removed key; re-key the
  `profiles/claude-code/CLAUDE.md` / `profiles/codex/AGENTS.md` rows of
  `tests/canonical/test-connector-skills-structural.sh` to `canonical/aid/rules.md`.
- Known red from here until their re-key tasks: CLI-suite assertions that a `claude-code`
  install writes the full region into `CLAUDE.md` (`test-aid-cli.sh` and `test-aid-cli-ps1.sh` ->
  task-019, `test-multitool-isolation.sh` -> task-018, `test-aid-cli-parity.sh` -> task-023,
  `tests/windows/Test-AidInstaller.ps1` -> task-024).
- Function-level cases for the functions above in both shells (PowerShell when `pwsh` exists),
  added to `tests/canonical/test-install-core-primitives.sh`.

**Acceptance Criteria:**
- [ ] `canonical/aid/rules.md` exists, `grep -cE '\.(claude|codex|cursor|agent)/|\.github/aid/|canonical/|^@|AID:(BEGIN|END)' canonical/aid/rules.md` prints `0`, and `grep -c 'aid/runtime/templates/' canonical/aid/rules.md` prints at least `1`.
- [ ] `ls profiles/*/AGENTS.md profiles/claude-code/CLAUDE.md` reports every path as missing.
- [ ] With the core sourced, `_root_agent_file <tool>` prints `AGENTS.md` for each of the five tools; `Get-RootAgentFile` does the same where `pwsh` exists.
- [ ] `_repair_root_region`: a missing file ends with bytes equal to the region; a file holding exactly the well-formed region plus user text before and after is byte-unchanged (sha256) with no trash entry; a LF-terminated no-region file keeps its pre-write bytes as a byte-exact prefix followed only by the region, a non-LF-terminated one gets one LF first, and neither writes a trash entry.
- [ ] `_repair_root_region` on three malformed fixtures -- an `AGENTS.md` or `CLAUDE.md` holding `<!-- AID:BEGIN -->` with no `<!-- AID:END -->` followed by user text; an `AGENTS.md` holding two copies of the pointer region around user text; a `CLAUDE.md` holding a lone `@AGENTS.md` line -- leaves exactly one well-formed region, every other line present unchanged and in its original order, a full copy of the pre-write file at `.aid/.trash/<file>`, and a second call leaves the sha256 unchanged and adds no trash entry.
- [ ] `_copy_root_agent_file` on an absent `AGENTS.md` produces exactly the five pointer-region lines and records `agents_md.region_sha256` and `file_sha256`; with a staged `aid-tool.conf` carrying `rules_inline=true`, the file holds the BEGIN line, the comment line, the bytes of `canonical/aid/rules.md` and the END line, and after one in-span byte is edited a repair restores that span while a user line outside the markers is untouched.
- [ ] `_ensure_claude_md_region`: on an absent file the result's bytes equal the import region exactly; on a no-region file ending in LF the pre-write bytes are a byte-exact prefix and the only bytes after them are the import region, and a second call leaves the sha256 unchanged; on a non-empty file NOT ending in LF the result is the pre-write bytes, one LF, then the import region.
- [ ] `_remove_claude_md_region`: on the created-from-absent file the file is gone; on the appended-to-LF-terminated-user-file case the file equals its pre-add bytes; with a drifted region the whole file is first at `.aid/.trash/CLAUDE.md`; a file whose markers were deleted is byte-unchanged.
- [ ] The `Repair-AidRootRegion`, `Copy-RootAgentFile`, `Invoke-EnsureClaudeMdRegion` and `Invoke-RemoveClaudeMdRegion` twins give byte-identical results and output lines for every case above where `pwsh` exists.
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-install-core-primitives.sh` and `bash tests/canonical/test-connector-skills-structural.sh` exit `0`; `tests/canonical/test-agents-md-invariant.sh` no longer exists.
- [ ] `bash tests/canonical/test-ps51-compat.sh` and `bash tests/canonical/test-ascii-only.sh` exit `0`.
- [ ] All section-6 quality gates pass.
