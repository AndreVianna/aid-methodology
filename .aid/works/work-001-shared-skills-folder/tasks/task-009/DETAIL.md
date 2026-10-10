# task-009: Commit the shared placement on `aid add` (skills, mirrors, runtime, agents, `AGENTS.md` region)

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-3, AC-7, AC-9, AC-14

**Depends on:** task-005, task-008

**Scope:**
Bash and PowerShell twins together, per REQUIREMENTS.md § 11 Feature 001 › Feature Flow › 3
(step 6, sub-steps 1 to 7) and Data Model › Install manifest.
- `install_shared` / `Install-AidShared` (new): `.agents/skills/aid-*` via `copy_file_guarded`;
  every mirror declared by any installed or newly added tool's `aid-tool.conf` written the same way
  (a newly added `claude-code` creates `.claude/skills/aid-*`); the staged runtime to
  `.aid/runtime/`; the `AGENTS.md` region through `_copy_root_agent_file` branches A, B and C2, with
  the whole file copied to the trash first when its region differs from what is being written and
  either has no recorded `region_sha256` or no longer matches it; then, when any user's
  `aid-tool.conf` declares `context_import` (Claude Code: `CLAUDE.md`), the `CLAUDE.md` import
  region through `_ensure_claude_md_region` / `Invoke-EnsureClaudeMdRegion` (task-005), recorded
  as the `shared.claude_md` entry (`path`, `version`, `users` = the declaring tools,
  `region_sha256`).
- `install_tool` / `Install-AidTool` rewritten: places only the tool's `<root>/agents/` files.
- `aid add` commit order exactly as Flow 3 step 6: shared skills, mirrors, runtime, each new tool's
  agents, the `AGENTS.md` region (then the `CLAUDE.md` import region when `claude-code` is
  installed); any copy failure aborts before the manifest write; then the format-3 manifest is
  written atomically (each new tool joins every shared `users` list it uses; every file recorded
  with the sha256 of its staged bytes; `region_sha256` and `file_sha256` for `agents_md`;
  `region_sha256` for `claude_md`; an entry whose user list would be empty is absent). The CLI
  never writes the full AID region into `CLAUDE.md`, and never reads or writes `CLAUDE.md` while no
  installed tool declares `context_import`.
- Never read, write or prune a non-`aid-*` entry in `.agents/skills/` or in a mirror.
- Output: one summary block for `shared` and one per tool, in the existing counter format; a block
  with nothing to change prints `up to date (N files)`.
- Remove the `_prune_tool_dirs` / `Invoke-PruneToolDirs` call from the add path; task-010 adds
  `prune_shared`, `host.conf`, the gitignore entries and the settings-seed path.
- Fixture recipe as in task-008. Known red: the CLI suites listed in task-006.

**Acceptance Criteria:**
- [ ] For each of the five tools, in a fresh fixture, `aid add <tool> --from-bundle "$S"` exits `0`; for every file `canonical/skills/<rel>`, `cmp canonical/skills/<rel> "$F/.agents/skills/<rel>"` succeeds, and `find "$F/.agents/skills" -path '*/aid-*' -type f | wc -l` equals `find canonical/skills -type f | wc -l`.
- [ ] For `claude-code` only, every `canonical/skills/<rel>` also equals `"$F/.claude/skills/<rel>"` byte-for-byte; no other tool creates a `<root>/skills/` directory.
- [ ] `diff -r canonical/aid/scripts "$F/.aid/runtime/scripts"` and `diff -r canonical/aid/templates "$F/.aid/runtime/templates"` print nothing; no `aid/` directory exists under `.claude`, `.codex`, `.cursor`, `.github` or `.agent`.
- [ ] `grep -c '^<!-- AID:BEGIN -->$' "$F/AGENTS.md"` prints `1` for every tool. After `aid add claude-code` into a fixture with no `CLAUDE.md`, `CLAUDE.md`'s bytes equal the import region (`<!-- AID:BEGIN -->`, `@AGENTS.md`, `<!-- AID:END -->`, each LF-terminated); after `aid add cursor` into a fixture with no `CLAUDE.md`, none exists.
- [ ] After `aid add claude-code` into a fixture whose user `CLAUDE.md` has no markers and ends in LF, the pre-add bytes are a byte-exact prefix of `CLAUDE.md` and the only bytes after them are the import region; the manifest's `shared.claude_md` has users `["claude-code"]` and a `region_sha256` equal to the sha256 of the import region.
- [ ] `.aid/.aid-manifest.json` has `"format_version": 3`, the key order of the Data Model example, `users` equal to the installed tool for `shared.skills`, `shared.runtime` and `shared.agents_md`, and a `sha256` per file that equals `sha256sum` of the installed file.
- [ ] `aid add cursor` followed by `aid add claude-code` leaves `users` as `["claude-code", "cursor"]` (`AID_TOOLS` order) on the three shared entries and `mirrors` holding `.claude/skills` with users `["claude-code"]`.
- [ ] Pre-seeded `.agents/skills/my-skill/SKILL.md` and `.claude/skills/my-skill/SKILL.md` keep their sha256 through both adds.
- [ ] After appending one byte to `.agents/skills/aid-plan/SKILL.md`, `aid add codex` restores canonical bytes there and the modified bytes exist at `.aid/.trash/.agents/skills/aid-plan/SKILL.md`.
- [ ] The same fixtures built with `bin/aid.ps1` (where `pwsh` exists) give an identical file tree and identical manifest bytes after masking `installed_at`; `bash tests/canonical/test-ps51-compat.sh` and `bash tests/canonical/test-ascii-only.sh` exit `0`.
- [ ] All section-6 quality gates pass.
