# task-012: Reference-counted `aid remove` for shared entries

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-9, AC-12, AC-14

**Depends on:** task-010

**Scope:**
Bash and PowerShell twins together (`uninstall_tool` in `lib/aid-install-core.sh`,
`Uninstall-AidTool` in `lib/AidInstallCore.psm1`), per REQUIREMENTS.md § 11 Feature 001 ›
Feature Flow › 5.
- Dispatch on the manifest `format_version`: format 2 keeps the existing legacy path unchanged.
- Format 3: remove the tool's own `files` (a file whose sha256 differs from the recorded one is
  moved to the trash, not deleted); take the tool off every `users` list; a shared entry whose list
  becomes empty has its files removed under the same sha rule and its emptied directories pruned
  (never `<root>`); a mirror goes when no remaining user declares it; when `agents_md` loses its last
  user, delete `AGENTS.md` if it still has `file_sha256`, otherwise print
  `Left in place (modified or not AID-owned): AGENTS.md`; when `shared.claude_md` loses its last
  user, run `_remove_claude_md_region` / `Invoke-RemoveClaudeMdRegion` (task-005: trash first if
  the region drifted, remove the region, delete the file only when nothing but whitespace
  remains) and drop `shared.claude_md` from the manifest, leaving the `AGENTS.md` region in place
  for the remaining tools; rewrite `host.conf` (via
  `write_host_conf`) when the runtime remains; delete the manifest and `.aid/settings.yml` when no
  tools remain (existing behaviour).
- With the last tool, also remove the `.gitattributes` managed block: `remove_gitattributes_block` /
  `Remove-AidGitattributesBlock` (task-010 writes it) drops the block, marker lines included, keeps
  every other byte, and deletes the file only when whitespace alone remains; the `.gitignore` block stays.
- Non-`aid-*` entries in `.agents/skills/` or a mirror are never read or touched; user `.aid/`
  state (`knowledge/`, `works/`, `design/`, `connectors/`) is never touched.
- `aid remove --orphans` (new flag; `_remove_orphans` / `Invoke-RemoveOrphans`, wired into
  `bin/aid` and `bin/aid.ps1`; § 11 › Feature Flow › 10, *Recovery*): with no manifest, the layout
  counts as orphaned when `.agents/skills/aid-*`, a mirror's `aid-*`, `.aid/runtime/` or an AID
  marker region in `AGENTS.md` or `CLAUDE.md` is present. With no recorded sha256, every orphan is
  moved to `.aid/.trash/` (collision policy as usual), never deleted. FR-6 runtime-local paths and
  non-`aid-*` entries are untouched. Each root file with a region is trashed whole, its region is
  removed, and the file is deleted only when nothing else remains (FR-12). Emptied directories are
  pruned, never `<root>`. With a manifest present the flag exits 2 and names `aid remove <tool>`.
  `aid add` needs no change: with no manifest it adopts the orphans through `copy_file_guarded`.
- Fixture recipe as in task-008. Known red: the CLI suites listed in task-006.
- Deferred review note (definition-gate ledger row 32): A runtime-local `node_modules/` under `.aid/runtime/` must not make a fully uninstalled repo report "orphaned" forever: orphan detection ignores runtime-local paths (FR-6), and `--orphans` leaves them alone.
- Deferred review note (definition-gate ledger row 33): Without a manifest, `--orphans` cannot know a tool's mirror directories: derive them from the known profile mirror list compiled into the CLI (e.g. `.claude/skills/aid-*`), not from a manifest or staged `aid-tool.conf`.

**Acceptance Criteria:**
- [ ] In a fixture after `aid add claude-code,cursor,codex` (with pre-seeded `.agents/skills/my-skill/SKILL.md` and `.claude/skills/my-skill/SKILL.md`), `aid remove cursor` leaves the sha256 of every file under `.agents/skills/aid-*`, `.claude/skills/aid-*`, `.aid/runtime/` and of `AGENTS.md` unchanged, removes every `.cursor/agents/aid-*`, and no `users` list in the manifest names `cursor`.
- [ ] A following `aid remove codex` leaves `.agents/skills/aid-*`, `.claude/skills/aid-*`, `.aid/runtime/` and `AGENTS.md` present.
- [ ] A following `aid remove claude-code` leaves no `.agents/skills/aid-*`, no `.claude/skills/aid-*` and no `.aid/runtime/`; the manifest and `.aid/settings.yml` are gone; an unedited `AGENTS.md` is deleted, while an `AGENTS.md` edited outside the region is left in place with the exact `Left in place` line printed.
- [ ] Both `my-skill/SKILL.md` files, and pre-seeded `.aid/knowledge/x.md`, `.aid/works/w/STATE.yml` and `.aid/design/d.md`, keep their sha256 through the whole sequence.
- [ ] AC-14 (d): in a fixture with no prior `CLAUDE.md` and in one whose user `CLAUDE.md` had no markers, after `aid add claude-code,cursor` then `aid remove claude-code`, `CLAUDE.md` is absent in the first and equals its pre-add bytes in the second; in both, `AGENTS.md` has exactly one `<!-- AID:BEGIN -->` line, `shared.agents_md.users` is `["cursor"]`, and the manifest has no `shared.claude_md`.
- [ ] Removing `claude-code` while `cursor` stays installed rewrites `host.conf` to `worktree_root=.aid/.worktrees` and drops `.claude/skills` from `mirrors`.
- [ ] After `aid remove` of the last tool, the `.gitattributes` managed block is gone, a pre-existing user line in `.gitattributes` is byte-unchanged, and a `.gitattributes` the CLI created holding only the block is deleted; while another tool remains the block is still present.
- [ ] An agent file edited before its tool's removal ends up at `.aid/.trash/<its path>`, not deleted.
- [ ] In a fixture holding the shared layout with no manifest (as left by the frozen format-4 core removing the last tool), `aid remove --orphans` exits `0`, leaves no `aid-*` under `.agents/skills` or a mirror, no `.aid/runtime/` and no AID region in `AGENTS.md` or `CLAUDE.md`, and every removed byte exists under `.aid/.trash/` (each region-bearing root file whole at `.aid/.trash/<its name>`); `.agents/skills/my-skill/SKILL.md` and a fixture `.aid/runtime/scripts/summarize/node_modules/x.js` keep their sha256 (and the latter leaves no trash entry); a root file with user content outside the region keeps those bytes.
- [ ] `aid remove --orphans` in a fixture with a manifest exits `2`, names `aid remove <tool>`, and the fixture snapshot is unchanged; after the orphans are removed, `aid add cursor` into the same fixture succeeds.
- [ ] Each case gives the same tree, output lines and exit codes under `bin/aid.ps1` where `pwsh` exists; `bash tests/canonical/test-ps51-compat.sh` and `bash tests/canonical/test-ascii-only.sh` exit `0`.
- [ ] All section-6 quality gates pass.
