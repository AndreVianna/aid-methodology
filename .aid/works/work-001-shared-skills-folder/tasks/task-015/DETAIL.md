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
  new layout first with `copy_file_guarded` (2.1 `.aid/runtime/` + `host.conf` first, so no
  interruption leaves a skill without its runtime, 2.2 `.agents/skills/aid-*`, 2.3 mirrors, 2.4
  every tool's agents (rewritten in place), 2.5 the `AGENTS.md` region (marker-less rule of
  task-005), 2.6 when `claude-code` is installed, `_ensure_claude_md_region` in migration mode -- the full AID region
  becomes the import region whether or not the file was user-edited, the pre-update file is
  trashed first because a format-2 manifest records no region hash, an unedited file is NOT
  deleted, a no-marker file gets the region appended plus the WARN line when it holds a C2-stem
  heading, and a missing file is created holding only the region); (3) write the format-3 manifest
  (including `shared.claude_md`) with the top-level key `"migration": "pending"`, placed after
  `layout_format`; (4) retire the old layout per tool to `.aid/.trash/<original-path>` under the
  path-based ownership rule of FR-11 (the new helper `_is_aid_owned_path` /
  `Test-AidOwnedPath`, not `_is_aid_owned_file`): a file is AID-owned when it lies under
  `<root>/skills/aid-*/` at any depth (every `references/*.md` counts), or under `<root>/aid/`, or
  its basename starts with `aid-`; never touching an unmarked file and never the `.github` root
  (G-12); (5) clear the marker by rewriting the manifest without `migration`, then
  `prune_shared`, `update_gitignore`, `_aid_migrate_repo` (stamps 5 only once the marker is clear,
  so the stamp stays 4 until step 4 has completed). Print
  `N retired AID file(s) moved to .aid/.trash/ (safe to delete once you have checked them)`.
- Resume: `aid update` on a `format_version` 3 manifest with `"migration": "pending"` resumes at
  step 4, skips steps 2 and 3, and finishes as steps 4 and 5; steps 4 and 5 are idempotent whatever
  interrupted them. The pending manifest is the branch task-014's dispatch point receives
  alongside a format-2 manifest.
- Creation journal (`_journal_created_path` / `_read_created_journal`, PowerShell
  `Add-MigrationCreatedPath` / `Read-MigrationCreatedJournal`): before step 2 writes, each path
  that does not yet exist is appended to `.aid/.trash/migration-created.list`; a path that exists
  is never listed (so a legacy `.agents/skills/aid-*` file is never listed). Steps 1 and 3 write
  nothing in place and step 4 only moves files to the trash.
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
  section stating the Migration Plan › Rollback procedure (before step 3: restore every
  in-place-modified path from `.aid/.trash/<original-path>` -- the `.claude/skills` copies, every
  tool's agents, the legacy `.agents/skills/aid-*` files, `CLAUDE.md` and `AGENTS.md`; a path whose
  bytes were identical needs no restore -- then delete exactly the paths in
  `.aid/.trash/migration-created.list`; after step 3 or after completion: `aid update` finishes a
  pending migration, or to abandon it restore the tool roots, `CLAUDE.md`, `AGENTS.md`, the
  manifest and settings from version control, delete the journal's paths, then recover uncommitted
  edits from `.aid/.trash/`).
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
- [ ] A run killed after the manifest write (step 3) leaves a format-3 manifest holding `"migration": "pending"` (key placed after `layout_format`) and `.aid/settings.yml` stamp `4`; `aid add cursor` then exits `2` with the layout-gate message; the next `aid update --from-bundle "$S"` leaves no `aid-*` entry under the old roots, no `migration` key in the manifest, stamp `5`, and does not re-run steps 2 and 3 (the sha256 of the new-layout files is unchanged).
- [ ] After a completed step 2, `.aid/.trash/migration-created.list` names every newly created path (e.g. `.aid/runtime/host.conf`, `.agents/skills/aid-*` files that did not exist) and names no path that existed beforehand (a pre-seeded legacy `.agents/skills/aid-plan/SKILL.md` is absent from it); following the runbook's before-step-3 procedure on such a fixture restores each in-place-modified file's pre-update bytes and deletes only the listed paths, after which the format-2 manifest and old layout are as before.
- [ ] Path-based ownership: in a format-4 fixture, `.codex/skills/aid-plan/references/x.md` (basename without `aid-`) is moved to `.aid/.trash/.codex/skills/aid-plan/references/x.md`, while `.codex/skills/my-skill/SKILL.md` and a non-`aid-` file directly under `.codex/` keep their sha256; `Test-AidOwnedPath` gives the same verdicts where `pwsh` exists.
- [ ] With the core sourced, `detect_tool` on a fixture holding only `.agents/` exits `2` and prints no `codex`; on a fixture holding `.codex/` it prints `codex`; `Detect-Tool` matches where `pwsh` exists.
- [ ] Every case gives the same tree and output lines under `bin/aid.ps1` where `pwsh` exists; `bash tests/canonical/test-ps51-compat.sh` and `bash tests/canonical/test-ascii-only.sh` exit `0`.
- [ ] All section-6 quality gates pass.
