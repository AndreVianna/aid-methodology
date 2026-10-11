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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-9, AC-14

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
  user, compare the whole-file `file_sha256`: if different, leave it in place and print
  `Left in place (modified or not AID-owned): AGENTS.md`; if equal, remove only the unchanged
  managed region, preserve outside bytes, and delete only when the remainder is empty/whitespace; when `shared.claude_md` loses its last
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
- Fixture recipe as in task-008. Known red: the CLI suites listed in task-006.

**Acceptance Criteria:**
- [ ] In a fixture after `aid add claude-code,cursor,codex` (with pre-seeded `.agents/skills/my-skill/SKILL.md` and `.claude/skills/my-skill/SKILL.md`), `aid remove cursor` leaves the sha256 of every file under `.agents/skills/aid-*`, `.claude/skills/aid-*`, `.aid/runtime/` and of `AGENTS.md` unchanged, removes every `.cursor/agents/aid-*`, and no `users` list in the manifest names `cursor`.
- [ ] A following `aid remove codex` leaves `.agents/skills/aid-*`, `.claude/skills/aid-*`, `.aid/runtime/` and `AGENTS.md` present.
- [ ] Last-user removal fixtures cover pre-existing markerless user content, an AID-created region-only file, and edits after install: preserve outside bytes when whole hash matches, delete only the region-only file, and leave the file in place with the exact `Left in place` line when edited.
- [ ] Both `my-skill/SKILL.md` files, and pre-seeded `.aid/knowledge/x.md`, `.aid/works/w/STATE.yml` and `.aid/design/d.md`, keep their sha256 through the whole sequence.
- [ ] AC-14 (d): in a fixture with no prior `CLAUDE.md` and in one whose user `CLAUDE.md` had no markers, after `aid add claude-code,cursor` then `aid remove claude-code`, `CLAUDE.md` is absent in the first and equals its pre-add bytes in the second; in both, `AGENTS.md` has exactly one `<!-- AID:BEGIN -->` line, `shared.agents_md.users` is `["cursor"]`, and the manifest has no `shared.claude_md`.
- [ ] Removing `claude-code` while `cursor` stays installed rewrites `host.conf` to `worktree_root=.aid/.worktrees` and drops `.claude/skills` from `mirrors`.
- [ ] After `aid remove` of the last tool, the `.gitattributes` managed block is gone, a pre-existing user line in `.gitattributes` is byte-unchanged, and a `.gitattributes` the CLI created holding only the block is deleted; while another tool remains the block is still present.
- [ ] An agent file edited before its tool's removal ends up at `.aid/.trash/<its path>`, not deleted.
- [ ] Each case gives the same tree, output lines and exit codes under `bin/aid.ps1` where `pwsh` exists; `bash tests/canonical/test-ps51-compat.sh` and `bash tests/canonical/test-ascii-only.sh` exit `0`.
- [ ] All section-6 quality gates pass.
