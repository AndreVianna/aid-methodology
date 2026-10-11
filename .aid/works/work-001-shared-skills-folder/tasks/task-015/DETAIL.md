# task-015: Migrate format-4 installs to the shared layout on `aid update`

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

**Type:** MIGRATE

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-13, AC-14, AC-15

**Depends on:** task-005, task-014

**Scope:**
Bash and PowerShell twins together, per REQUIREMENTS.md § 11 Feature 001 › Migration Plan (From ->
To, Trigger, Forward steps, the old-path treatment table, Interruption and idempotency, Rollback).
- `migrate_layout_v2` / `Invoke-MigrateLayoutV2` (new), wired into task-014's format-2 dispatch
  point. Forward steps in order, each idempotent: (1) stage and validate everything; (2) write the
  new layout first with `copy_file_guarded` (2.1 `.agents/skills/aid-*`, 2.2 mirrors, 2.3
  `.aid/runtime/` + `host.conf`, 2.4 every tool's agents, 2.5 the `AGENTS.md` region, 2.6 when
  `claude-code` is installed, `_ensure_claude_md_region` in migration mode -- the full AID region
  becomes the import region whether or not the file was user-edited, the pre-update file is
  trashed first because a format-2 manifest records no region hash, an unedited file is NOT
  deleted, a no-marker file gets the region appended plus the WARN line when it holds a C2-stem
  heading, and a missing file is created holding only the region); (3) write the format-3 manifest
  (including `shared.claude_md`); (4) retire the old layout per tool to
  `.aid/.trash/<original-path>` under the existing ownership markers (`aid-` prefix, or inside an
  `aid/` subtree), never touching an unmarked file and never the `.github` root (G-12); (5)
  `prune_shared`, `update_gitignore`, `_aid_migrate_repo` (stamps 5). Print
  `N retired AID file(s) moved to .aid/.trash/ (safe to delete once you have checked them)`.
- Old paths per the table: `<root>/skills/aid-*` and `<root>/aid/**` for `.codex`, `.cursor`,
  `.github`, `.agent` -> trash; `.claude/skills/aid-*` becomes the mirror (rewritten in place,
  trashed first if different); `.claude/aid/**` -> trash; legacy `.agents/aid/**` -> trash; legacy
  `.agents/skills/aid-*` overwritten in place (trashed first if different); `.cursor/rules/aid-*`
  and `.agent/rules/` keep their existing sweep. Emptied `<root>/skills/` and `<root>/aid/`
  directories are removed; `<root>` never. Paths a format-2 manifest records that the table does not
  name (e.g. a retired `<root>/recipes/`) keep the treatment `_migrate_retired_layout` gives them
  today.
- `_migrate_retired_layout` / `Invoke-MigrateRetiredLayout`: the Codex sweep is narrowed to
  `.agents/aid/`; nothing sweeps or rejects `.agents/skills/`.
- `detect_tool` / `Detect-Tool`: `.agents/` is no longer a Codex marker.
- `aid add` never migrates (task-006's layout gate refuses).
- Rollback runbook: a comment block in `bin/aid` beside the existing `RUNBOOK -- ROLLBACK`
  section stating the Migration Plan › Rollback procedure (before step 3: delete
  `.agents/skills/aid-*`, new mirror files and `.aid/runtime/`; after completion: restore the tool
  roots, `CLAUDE.md`, `AGENTS.md`, the manifest and settings from version control, then recover
  uncommitted edits from `.aid/.trash/`).
- Fixture recipe as in task-008; format-4 fixtures are built with the frozen format-4 core
  (`git show <base-commit>:lib/aid-install-core.sh`) or by hand. Known red: the CLI suites listed in
  task-006.
- Deferred review note (definition-gate ledger row 34): Rollback after step 3 must not depend on files only in the gitignored, "safe to delete" `.aid/.trash/`, and step 3 must trash a copy of the format-2 manifest before overwriting it ("Steps 1 and 3 write nothing in place" must hold).
- Deferred review note (definition-gate ledger row 35): While `migration: pending`, the settings stamp stays 4, which lets an old format-4 CLI into a half-migrated repo: make the old-CLI path refuse or be harmless in that state (e.g. write the stamp to a value the format-4 gate refuses, or document the bounded risk in the rollback runbook).

**Acceptance Criteria:**
- [ ] For each of the five tools (plus a Codex fixture holding a legacy `.agents/aid/`), a format-4 fixture with one user-modified AID file in the old `skills/aid-*`, one in the old `aid/` subtree, and one non-AID user file in each old directory, after `aid update --from-bundle "$S"`: every `canonical/skills/<rel>` equals `.agents/skills/<rel>` (and `.claude/skills/<rel>` for claude-code); `.aid/runtime/{scripts,templates}` equals `canonical/aid/{scripts,templates}`; no `aid-*` entry remains under `.codex/skills`, `.cursor/skills`, `.github/skills` or `.agent/skills`; no `<root>/aid/` remains.
- [ ] Each modified file exists byte-for-byte at `.aid/.trash/<original-path>`; each non-AID file keeps its sha256; `.aid/settings.yml` has `format_version: 5`; the manifest has `"format_version": 3`.
- [ ] A second `aid update --from-bundle "$S"` prints `up to date` for `shared` and every tool and leaves the sha256 snapshot of `.aid/.trash/` unchanged.
- [ ] AC-14 (c), three claude-code fixtures: a user-edited `CLAUDE.md` with user content above and below the full AID region ends equal, byte-for-byte, to its pre-update content with the marked region (marker lines included) replaced by the import region, and the pre-update file exists byte-for-byte at `.aid/.trash/CLAUDE.md`; an unedited `CLAUDE.md` (sha equal to the format-2-recorded sha) gets the same replacement and still exists; a no-marker `CLAUDE.md` holding AID sections keeps its pre-update bytes as a byte-exact prefix followed only by the import region, and the run prints exactly `WARN: aid: CLAUDE.md has AID sections outside its managed region (<the C2 stems found>); remove them by hand -- AID instructions now live in AGENTS.md, which CLAUDE.md imports`. In all three, `CLAUDE.md` has exactly one `@AGENTS.md` line and `AGENTS.md` exactly one `<!-- AID:BEGIN -->` line.
- [ ] An interrupted run (simulated by failing a copy after step 2 starts) leaves the old layout intact and a format-2 manifest, and a re-run completes the migration.
- [ ] With the core sourced, `detect_tool` on a fixture holding only `.agents/` exits `2` and prints no `codex`; on a fixture holding `.codex/` it prints `codex`; `Detect-Tool` matches where `pwsh` exists.
- [ ] Every case gives the same tree and output lines under `bin/aid.ps1` where `pwsh` exists; `bash tests/canonical/test-ps51-compat.sh` and `bash tests/canonical/test-ascii-only.sh` exit `0`.
- [ ] All section-6 quality gates pass.
