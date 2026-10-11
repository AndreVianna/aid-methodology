# task-015: Clean-slate upgrade from the v3 layout to the shared layout on `aid update`

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
Bash and PowerShell twins together, per REQUIREMENTS.md § 5 FR-11 and § 11 Feature 001 › Upgrade
from v3 (clean slate) (Trigger, Steps, Interruption and recovery).
- `retire_v3_layout` / `Invoke-RetireV3Layout` (new), wired into task-014's v3-layout dispatch
  point (a format-2 manifest, or the old `<root>/aid/` and `<root>/skills/aid-*` paths). Steps in
  order: (1) stage and validate everything (flow 2), so a failure here means no write at all;
  (2) `retire_v3_layout` moves every old AID-owned path into `.aid/.trash/<original-path>`
  (collision policy as usual), under the path-based ownership rule of FR-11 (the new helper
  `_is_aid_owned_path` / `Test-AidOwnedPath`, not `_is_aid_owned_file`): a file is AID-owned when
  it lies under `<root>/skills/aid-*/` at any depth (every `references/*.md` counts), or under
  `<root>/aid/`, or its basename starts with `aid-`; never touching a user file and never the
  `.github` root (G-12). For `AGENTS.md` and `CLAUDE.md` it copies the whole file to the trash and
  removes the old AID region, marker lines included; a file left empty or whitespace-only is
  deleted, and a file with no well-formed region stays unchanged. Emptied directories are removed,
  never `<root>`; (3) a normal fresh v4 install of the same tools (the manifest's tools, or the
  tools whose old roots held AID-owned paths): the flow 3 commit steps, the flow 6 prune, then
  `_aid_migrate_repo`, which stamps 5. Print
  `N old AID file(s) moved to .aid/.trash/ (safe to delete once you have checked them)`.
- No resume key, no journal and no step ordering: an interrupted run is fixed by re-running
  `aid update` (step 2 only moves files, so a re-run finds fewer old paths; step 3 is the idempotent
  fresh install). The manifest carries no `migration` key and no layout-format key.
- Old paths: `<root>/skills/aid-*` and `<root>/aid/**` for `.claude`, `.codex`, `.cursor`,
  `.github` and `.agent`, and the legacy `.agents/aid/**`, all -> trash; `.cursor/rules/aid-*` and
  `.agent/rules/` keep their existing sweep. Paths a format-2 manifest records that the list does
  not name (e.g. a retired `<root>/recipes/`) keep the treatment `_migrate_retired_layout` gives
  them today.
- `_migrate_retired_layout` / `Invoke-MigrateRetiredLayout`: it no longer sweeps `.agents/`, and
  nothing sweeps or rejects `.agents/skills/`; the legacy `.agents/aid/` is retired by
  `retire_v3_layout`.
- `detect_tool` / `Detect-Tool`: `.agents/` is no longer a Codex marker.
- `aid add` never upgrades (task-006's layout gate refuses).
- Recovery note: a comment block in `bin/aid` beside the existing `RUNBOOK -- ROLLBACK` section
  stating that an interrupted upgrade is fixed by re-running `aid update`, that a rollback is a
  restore from `.aid/.trash/<original-path>` (the newest copy sits at the original path, older
  copies carry a timestamp suffix) or from version control, and that a v3 CLI cannot drive a v4
  layout (`v4 requires CLI v4`).
- Fixture recipe as in task-008; v3 fixtures (a format-2 manifest plus the old paths) are built by
  hand. Known red: the CLI suites listed in task-006.

**Acceptance Criteria:**
- [ ] For each of the five tools (plus a Codex fixture holding a legacy `.agents/aid/`), a v3 fixture with one user-modified AID file in the old `skills/aid-*`, one in the old `aid/` subtree, and one non-AID user file in each old directory, after `aid update --from-bundle "$S"`: every `canonical/skills/<rel>` equals `.agents/skills/<rel>` (and `.claude/skills/<rel>` for claude-code); `diff -r -x node_modules -x '.*' canonical/aid/scripts .aid/runtime/scripts` and the same for `templates` print nothing and `cmp canonical/aid/rules.md .aid/runtime/rules.md` succeeds; no `aid-*` entry remains under `.codex/skills`, `.cursor/skills`, `.github/skills` or `.agent/skills`; no `<root>/aid/` remains.
- [ ] Every old AID-owned file, modified or not, exists byte-for-byte at `.aid/.trash/<original-path>`; each non-AID file keeps its sha256; `.aid/settings.yml` has `format_version: 5`; the manifest has `"format_version": 3` and `grep -c '"migration"' .aid/.aid-manifest.json` prints `0`.
- [ ] A second `aid update --from-bundle "$S"` prints `up to date` for `shared` and every tool and leaves the sha256 snapshot of `.aid/.trash/` unchanged.
- [ ] An `aid update` killed after the trash step and before the manifest write (simulated by failing the run at the start of step 3), then re-run, ends in the state of the first criterion (the AC-3 and AC-7 checks pass) and loses no non-AID file.
- [ ] AC-14 (c), v3 claude-code fixtures: a user-edited `CLAUDE.md` with user content above and below the full old AID region ends with every pre-update line outside the old region present unchanged and in its original order, none of the old region's body lines left, and exactly one import region (one `@AGENTS.md` line); the pre-update file exists byte-for-byte at `.aid/.trash/CLAUDE.md`. A v3 `CLAUDE.md` with no markers keeps its pre-update bytes as a byte-exact prefix followed only by the import region. A v3 `AGENTS.md` holding the full old region ends holding the pointer region the same way, with its pre-update file at `.aid/.trash/AGENTS.md`; `AGENTS.md` has exactly one `<!-- AID:BEGIN -->` line.
- [ ] Path-based ownership: in a v3 fixture, `.codex/skills/aid-plan/references/x.md` (basename without `aid-`) is moved to `.aid/.trash/.codex/skills/aid-plan/references/x.md`, while `.codex/skills/my-skill/SKILL.md` and a non-`aid-` file directly under `.codex/` keep their sha256; `Test-AidOwnedPath` gives the same verdicts where `pwsh` exists.
- [ ] With the core sourced, `detect_tool` on a fixture holding only `.agents/` exits `2` and prints no `codex`; on a fixture holding `.codex/` it prints `codex`; `Detect-Tool` matches where `pwsh` exists.
- [ ] Every case gives the same tree and output lines under `bin/aid.ps1` where `pwsh` exists; `bash tests/canonical/test-ps51-compat.sh` and `bash tests/canonical/test-ascii-only.sh` exit `0`.
- [ ] All section-6 quality gates pass.
