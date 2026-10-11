# task-010: Prune, `host.conf`, `.gitignore` worktree entries and the runtime settings seed

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-7, AC-8

**Depends on:** task-006, task-009

**Scope:**
Bash and PowerShell twins together, per REQUIREMENTS.md § 11 Feature 001 › Data Model (The
`host.conf` value; `.gitignore` managed block) and Feature Flow › 3 (step 6, sub-steps 3, 8, 9)
and › 6.
- `write_host_conf` / `Write-AidHostConf` (new): `.aid/runtime/host.conf` holds
  `worktree_root=<the worktree_root of the first installed tool, in AID_TOOLS order, that declares one; otherwise .aid/.worktrees>`,
  where each installed tool's value is read from its manifest entry (`tools.<t>.worktree_root`,
  task-004) and each newly added tool's from its `aid-tool.conf` (add stages only the new tools);
  written on every add after the runtime copy, recorded in `shared.runtime.files` with its sha256 and
  in the manifest `host` key. (Rewriting it on remove is task-012.)
- `prune_shared` / `Invoke-PruneShared` (replace `_prune_tool_dirs` / `Invoke-PruneToolDirs`), run
  after every add commit (task-014 adds the update call): candidates are `aid-*` children of
  `.agents/skills/` and of each mirror not in `shared.skills`, files under `.aid/runtime/` not in
  `shared.runtime` and not under an FR-6 runtime-local path, and `aid-*` children of each tool's
  `<root>/agents/` not in that tool's `files`. Runtime-local paths (any `node_modules/` directory
  under `.aid/runtime/`) are user-provisioned: never candidates, so never pruned, never trashed.
  A candidate whose bytes match a sha256 in the previous manifest is deleted; every other candidate
  is moved to the trash with `trash_file`. Emptied directories are removed, never `<root>` itself.
- `_aid_gitignore_block` / `Get-AidGitignoreBlock`: add `.aid/.worktrees/`; when
  `host.worktree_root` is not under `.aid/`, also list that root (e.g. `.claude/worktrees/`). The
  block stays a pure function of the manifest and idempotent. The block also lists each FR-6
  runtime-local path (`.aid/runtime/**/node_modules/`). `.aid/runtime/` itself is NOT added.
- `.gitattributes` managed block (§ 11 › Data Model, *`.gitattributes` managed block*; FR-6):
  `_aid_gitattributes_block` / `Get-AidGitattributesBlock` (constant: the `.gitignore` marker lines
  around `.agents/skills/aid-*/** text eol=lf`, `.claude/skills/aid-*/** text eol=lf`,
  `.aid/runtime/** text eol=lf`) and `update_gitattributes` / `Update-AidGitattributes` (create
  when missing, replace only the block, keep every byte outside it, idempotent), run right after
  `update_gitignore`.
- `seed_settings_yml` / `Initialize-AidSettingsFile`: read the template from
  `.aid/runtime/templates/settings.yml`. `update_gitignore` and `_migrate_term_exclusions` run after,
  as today.
- Fixture recipe as in task-008. Known red: the CLI suites listed in task-006.

**Acceptance Criteria:**
- [ ] After `aid add cursor`, `.aid/runtime/host.conf` is exactly `worktree_root=.aid/.worktrees`; after `aid add claude-code` in a fresh fixture it is `worktree_root=.claude/worktrees`; after `aid add cursor` then `aid add claude-code` it is `worktree_root=.claude/worktrees`. In each case the manifest `host.worktree_root` matches and `shared.runtime.files` lists `host.conf` with its current sha256.
- [ ] In a fixture installed with `claude-code` then `aid add cursor` (only `cursor` staged), `host.conf` stays `worktree_root=.claude/worktrees`, computed from the manifest's recorded `tools.claude-code.worktree_root`.
- [ ] The `.gitignore` AID block contains `.aid/.worktrees/` in every fixture, contains `.claude/worktrees/` only when `claude-code` is installed, contains `.aid/runtime/**/node_modules/`, and never contains a line equal to `.aid/runtime/`.
- [ ] After `aid add cursor` in a fixture with a pre-existing `.gitattributes` user line, `.gitattributes` contains the managed block with the three `text eol=lf` lines and the user line is unchanged; with no prior `.gitattributes` the file is created holding only the block; a second `aid add`/`aid update` leaves its sha256 unchanged.
- [ ] A fixture file `.aid/runtime/scripts/summarize/node_modules/x.js` survives the next `aid add <another tool>` with unchanged sha256, and nothing from it lands in `.aid/.trash/`.
- [ ] A stray `.aid/runtime/stray.txt` and a stray `.agents/skills/aid-zzz/SKILL.md` placed before the next `aid add <another tool>` are gone from their places afterwards and present byte-for-byte at `.aid/.trash/.aid/runtime/stray.txt` and `.aid/.trash/.agents/skills/aid-zzz/SKILL.md`; `.agents/skills/my-skill/SKILL.md` keeps its sha256.
- [ ] `.aid/settings.yml` exists after a first add, and `grep -rn 'aid/templates/settings.yml' lib/ bin/` shows only the `.aid/runtime/templates/settings.yml` form.
- [ ] `grep -rn '_prune_tool_dirs\|Invoke-PruneToolDirs' lib/ bin/` prints nothing.
- [ ] Each case gives the same tree and manifest bytes (masked `installed_at`) under `bin/aid.ps1` where `pwsh` exists; `bash tests/canonical/test-ps51-compat.sh` and `bash tests/canonical/test-ascii-only.sh` exit `0`.
- [ ] All section-6 quality gates pass.
