# Handoff — work-001 Shared Skills Folder (AID v4.0.0)

Updated 2026-10-11 by Claude Code (after execution wave 1). Originally written 2026-10-10 by Codex.
This is the current handoff; `STATE.yml` contains the append-only session history.
**Latest result (2026-10-11, Claude Code): EXECUTION IN PROGRESS — wave 1 of 15 Done; paused by
the maintainer after wave 1.** The GATE was cleared (definition A+, tasks A+) and the maintainer
approved execution. Sections 5–6 below describe the pre-execution state; `STATE.yml`
`lifecycle_history` carries the full record.

### Execution status (read this first)

- **Delivery branch:** `aid/work-001-shared-skills-folder-delivery-001` (pushed). All execution
  commits live there, not on `work-001`.
- **State file:** `STATE.yml` → `phase: Execute`, `active_skill: aid-execute`; per-task states in
  `tasks_lifecycle`.
- **Done (wave 1):** task-001 (canonical skills neutralized), task-002 (canonical/aid sources point
  at `.aid/runtime` paths), task-004 (install-core primitives: descriptor reader, trash move,
  guarded copy, format-3 manifest writers/readers).
- **Next (wave 2):** task-005, task-006, task-011 (all their dependencies are Done). Re-run
  `bash .claude/aid/scripts/execute/derive-waves.sh --from-tasks .aid/works/work-001-shared-skills-folder`
  for the authoritative graph.
- **Wave-1 review ledger:** `review-ledgers/execute-wave-1.md` (3 rows: 2 Fixed, 1 Accepted —
  bash `_v3_quote` vs python `json.dump` escaping of non-ASCII; re-check in the final review).
- **Spec deviation recorded:** the format-3 manifest writers are `manifest_write_v3` /
  `_manifest_write_v3_python` / `_manifest_write_v3_bash` / `Write-AidManifestV3`; the format-2
  `manifest_write` / `Write-AidManifest` stay until the install path switches (task-009).
  REQUIREMENTS.md § 11 reuse table and the task-004 / task-009 DETAILs were updated to match.
- **Notes for later tasks:** task-009 must pass the root explicitly to `copy_file_guarded <src>
  <dst> [sha] [root]` (the `$PWD` default is a fallback). `trash_file <root> <file> [utc-stamp]`.
  In this source repo `cleanup-classify.sh` finds no registry under `.aid/runtime/` until the
  dogfood resync (task-027) — expected.
- **PowerShell twins are unverified** (no `pwsh` in the cloud container). Run the PS criteria on
  Windows before release.

**How execution runs (maintainer's rules):**
1. One task at a time, Haiku `aid-developer` per task, sequential (never two agents on the same
   files).
2. Orchestrator writes the task state: `In Progress` before dispatch, `In Review` after the
   developer's commit, `Done`/`Failed` after the wave check. Command:
   `AID_STATE_FILE=.aid/works/work-001-shared-skills-folder/STATE.yml bash .claude/aid/scripts/execute/writeback-state.sh --task-id NNN --field state --value "<State>"`
   (after task-027's resync use `.aid/runtime/scripts/execute/writeback-state.sh`).
3. Developers: NO long checks (coverage-parity, `tests/run-all.sh`, full regressions,
   `render.py --self-test`) — those criteria are DEFERRED to the final verification (task-031).
   `pwsh` criteria are NOT-RUNNABLE here. Host awk is mawk (DBI01 in
   `test-dogfood-byte-identity.sh` fails for that reason only). No chmod / mode changes.
4. End of each wave: Sonnet `aid-reviewer` quick check → ledger
   `.aid/.temp/review-pending/work-001-wave-N.md`, copied to `review-ledgers/execute-wave-N.md`.
   Failure policy: 1 Haiku fix → 1 Sonnet fix → mark `Failed`, block dependents.
5. After the last wave: Opus full review, then PAUSE and report to the maintainer.
6. Manual probes A-4 (Cursor alias list) and A-6 (pointer probe) are owned by task-032.

---

## 1. Quick start (Claude Code)

1. Open the existing `work-001` checkout/worktree (switch to that branch first if using another
   checkout). Preserve unrelated local changes. Fetch and fast-forward:
   ```bash
   git fetch origin work-001
   git merge --ff-only FETCH_HEAD
   ```
   `origin/work-001` is the resume branch. The historical
   `claude/youthful-curie-aqfdvp` branch was not updated by Codex.
2. Restore exactly the two current GATE ledgers from their tracked snapshots:
   ```bash
   mkdir -p .aid/.temp/review-pending
   cp .aid/works/work-001-shared-skills-folder/review-ledgers/shortcut-work-001-shared-skills-folder-defn.md .aid/.temp/review-pending/
   cp .aid/works/work-001-shared-skills-folder/review-ledgers/shortcut-work-001-shared-skills-folder-tasks.md .aid/.temp/review-pending/
   ```
3. Read this handoff, the two Pending rows, and `STATE.yml` › `lifecycle_history`. Read the
   relevant `REQUIREMENTS.md` sections and task details before editing; avoid another broad
   reread just to resume. Continue at **§6 Next steps**.

The pipeline is `.claude/skills/aid-update/SKILL.md` and
`.claude/aid/templates/shortcut-engine.md` › GATE. Execution later is
`.claude/skills/aid-execute/SKILL.md`; it is not approved yet. Run scripts from the repository root.

---

## 2. What this work does

**Goal:** every installed AID skill is byte-identical across host tools, so one repo can be driven
from several IDEs at once. Ships as **AID v4.0.0** (breaking).

**Target layout in an adopter repo:**

| What | Where |
|---|---|
| Skills (all tools) | `.agents/skills/aid-*/` |
| Claude Code mirror (byte-identical, CLI-owned, sha-checked, no symlinks) | `.claude/skills/aid-*/` — only while Claude Code is installed |
| Shared runtime (scripts, templates, rules) | `.aid/runtime/` (`rules.md` holds the AID rules) |
| Agents | per tool, as today (`.claude/agents`, `.codex/agents` TOML, …) |
| Root file | `AGENTS.md` with a 5-line pointer region; `CLAUDE.md` gets a 1-line `@AGENTS.md` region while Claude Code is installed |

The pointer region (exact text, decided):
```
<!-- AID:BEGIN -->
<!-- Managed by the AID CLI. Do not edit between the AID markers. -->
@.aid/runtime/rules.md
Before acting, read and follow `.aid/runtime/rules.md` (AID rules).
<!-- AID:END -->
```

**Repo side:** only canonical sources live in the repo (`canonical/skills`, `canonical/aid` incl. the
new `canonical/aid/rules.md`, `canonical/agents`). The generator wipes and regenerates each
`profiles/<tool>/` (agents + `aid-tool.conf` only). The release ships one shared payload plus
per-tool agent artifacts; the **CLI** decides placement at install time.

---

## 3. Decisions log (all made by the maintainer — do not reopen)

| # | Decision |
|---|---|
| D1 | Single source of truth = canonical skills; placement decided by the CLI at install |
| D2 | `.agents/skills/` for every tool + CLI-owned byte-identical `.claude/skills/` copy for Claude Code; no symlinks (Windows) |
| D3 | Shared runtime in `.aid/runtime/` (tool-neutral, fixed path; skills run from project root) |
| D4 | Multiple tools per repo; shared files ref-counted in the install manifest; one AID version per repo (refuse skew; only `aid update` upgrades all) |
| D5 | `allowed-tools` space-separated, shell listed as aliases `Bash Shell Terminal` |
| D6 | `AGENTS.md` is the one root file; when Claude Code is installed the CLI **always** ensures `CLAUDE.md` has an `@AGENTS.md` import region (create the file if missing) |
| D7 | AID rules move to `.aid/runtime/rules.md`; the root-file region is the 5-line pointer above; the CLI repairs a damaged region by **content** (its lines are known) |
| D8 | Release is **AID v4.0.0**: profiles wiped and regenerated (no emission manifests); **no** protection/recovery for v3 CLIs; **clean-slate upgrade** (`retire_v3_layout`: move old AID-owned paths to `.aid/.trash/`, then fresh install) replaces the migration plan |
| D9 | Out of scope (future works): agents stay per tool; model-tier settings map with per-tier fallback lists (Option B, discussed); hooks |
| D10 | Copilot CLI skill execution accepted as working like the other `.agents/skills` hosts (account 403 blocked the probe) |

---

## 4. Evidence gathered (manual probes on Windows, 2026-10-10)

| Tool | Reads `.agents/skills` | Same-named skill in both folders | `.aid/runtime/` path | Notes |
|---|---|---|---|---|
| Claude Code | ❌ (needs `.claude/skills`) | n/a | ✅ | `allowed-tools: Bash` pre-approved; unknown `Shell` → prompt, skill still runs |
| Cursor | ✅ | listed once; **showed `.agents` description but ran `.claude` body** → copies must be identical | ✅ | permission test inconclusive (prior grants) |
| Antigravity v2.22.0 | ✅ (its default) | listed once, `.agents` copy | ✅ | ignores `allowed-tools` (prompts for both) |
| Codex | ✅ | same as Cursor/Antigravity | ✅ | |
| Copilot CLI | ✅ (discovery) | menu showed `.agents` copy | — | execution blocked by account 403 (accepted, D10) |

Docs facts used: Claude Code has **no** setting to add a skills folder (only `.claude/skills`,
`--add-dir`, plugins); Claude Code reads `AGENTS.md` (v2.1.277+) with the user-level "Project
instructions" setting (`claude-md-or-agents-md` default) that a project cannot set — hence D6.
Raw probe results: `probe-kits/ide-probe-RESULTS.md`. Kits: `probe-kits/*.zip`.

---

## 5. Where the work stands

- Branch: `work-001`; work folder: `.aid/works/work-001-shared-skills-folder/`.
- Pipeline: `/aid-update`, flattened Lite, `phase: Detail`, `delivery_state: Specified`,
  `lifecycle: Paused-Awaiting-Input`, `user_approved: 'no'`.
- Pause reason: `Full review below floor A; awaiting maintainer decision before fixes`.
- All 32 implementation tasks remain Pending. The dependency graph resolves to 15 waves;
  derive it with `derive-waves.sh --from-tasks .aid/works/work-001-shared-skills-folder`.
- Current grades: **definition C+, tasks C+; minimum A**. Earlier A+ entries are historical,
  preceding the latest full review, and must not be treated as current clearance.

### Completed in the Codex session

1. Confirmed the complete v4 intent in §2–§3. Settled the root-source decision:
   `canonical/aid/rules.md` replaces the old canonical root-context source; the release ships
   no root-context file; install cores own the constant pointer/import regions.
2. Aligned AC-14(c) and tasks 015/021: clean-slate upgrade removes the old region, preserves
   outside bytes/order, appends the new region at the end, adds one separating LF only when
   required, and backs up the whole original.
3. Independently verified definition rows 38–40 and task rows 1–14 as Fixed. Subsequent fixes
   resolved definition 41–42 and task 15: no profile README preservation exception; task-005
   extracts canonical rules before task-003 wipes profiles; interrupted upgrades retain the
   exact tool set and retirement-complete flag in `.aid/.temp/v3-upgrade-tools.json`.
   See REQUIREMENTS › Upgrade from v3 › Recovery record for the bounded atomic protocol.
4. A full review found definition 43–47 and tasks 16–18. The maintainer approved a bounded
   fix cycle: `gpt-6-luna` fixes, `gpt-6.1-sol` verification (Terra was unavailable), Codex
   orchestration/final integrated review. Fixed fresh-install/legacy stamp gates, preservation
   of pre-existing AGENTS content on final uninstall, collision-free trash suffixes,
   CRLF-aware region recognition and canonical-LF region hashes, A-6 probe ownership/fallback,
   documentation scope and valid generic work-path examples.
5. Used one targeted correction round for definition 48 and tasks 19–21: qualified the fresh
   stamp fixture; removed premature full-command gates; clarified that removing a region from
   an originally non-LF-terminated user file retains the inserted separator LF; separated
   scripted path greps from semantic reviewer checks. Removed a duplicated task-021 checkbox.
   Sol verified all these findings Fixed; both ledgers graded A+ at that point.
6. The maintainer requested another **fresh full review**. A new Sol reviewer read the entire
   definition and all 32 task bodies, rechecked every Fixed claim, and checked cross-task
   consistency/dependency order. It found the two issues below, with no Fixed regressions.
   **These two issues have not been fixed.**

Useful commits: `936f9e2fe` (Luna draft), `4ce9d5a89` (corrections), `26ed49f51` (prior A+
review close), `9027b77f5` (latest full definition review), `b966346df` (latest full task
review/pause). All work changes are pushed to `work-001`; git and STATE history carry the detail.
Only work artifacts were edited for these fixes. Unrelated generated site changes, local npm
configuration and node_modules artifacts in the Codex workspace were not included in these commits.

### Current ledger status — source of truth for remaining fixes

| Ledger | Fixed | Accepted | OOS | Pending | Recurred |
|---|---|---|---|---|---|
| `shortcut-work-001-shared-skills-folder-defn.md` | 28 | 19 | 1 | 1 (#49) | 0 |
| `shortcut-work-001-shared-skills-folder-tasks.md` | 21 | 0 | 0 | 1 (#22) | 0 |

Preserve the maintainer's Accepted decisions; do not reopen or duplicate them. The extra
`review-ledgers/adhoc-work-001-final.md` is an empty historical orchestrator-review snapshot
from the preceding cycle, not the current GATE ledger.

**Definition #49 — Medium, REQUIREMENTS §9 AC-13 / §5 FR-11.** The fixture seeds a non-AID
user file in each old directory and promises preservation at its original path. But every file
under an old `<root>/aid/` subtree is AID-owned by the authorized path predicate and must move
to trash. For example, `.cursor/aid/user-notes.txt` cannot remain at its old path while that
subtree is retired. Recommended fix: retain path-based ownership; put non-AID preservation
fixtures outside AID-owned subtrees, and separately assert byte-identical trash backups for
all files under old `aid/`. Align AC-13 and tasks 015/021 plus direct references/test plan.

**Task #22 — Medium, task-014 / FR-5.** `bin/aid::_cmd_update_all` and
`bin/aid.ps1::Invoke-AidUpdateAll` cache only per-tool tarballs and SHA256SUMS, then run child
`update --from-bundle <cache>`. New staging requires one `aid-shared-v*.tar.gz`, so that child
fails with the incomplete cache. No task currently owns the producer change. Recommended fix:
assign both cache producers a shared-payload fetch at the selected version, reuse the staging
helpers, and add an update-all cache/child regression criterion in the relevant CLI/parity
suite tasks. Keep staging validation and one-version-per-project behavior.

### Remaining manual validation

A-4 alias and A-6 pointer probes are still unverified, with kits in `probe-kits/`.
Task-032 now owns both for the required hosts, records pass/fail/unknown, and applies the
existing fallback plus affected checks/final regression on confirmed failure. Unknown is not
success. The evidence in §4 remains the original Windows probe evidence, not a new Codex run.

---

## 6. Next steps (exact order)

1. Show the maintainer the two Pending findings/current C+ grades and agree the next bounded
   fix cycle when asked to resume. This handoff request authorized saving/pushing, not fixing
   these newly discovered issues or starting implementation.
2. Fix definition #49 and task #22 with the smallest aligned changes. Read the ledger rows and
   affected contracts, preserve Accepted decisions, and do not mark rows Fixed yourself.
3. Independent verification: recheck Pending/Fixed evidence and hunt changes plus direct
   references. Reviewer alone marks resolved rows Fixed or real regressions Recurred; exact
   7-column schema in `.claude/aid/templates/reviewer-ledger-schema.md`, no narrative in ledgers.
4. Grade both with `bash .claude/aid/scripts/grade.sh --explain <ledger>`. Floor is A.
   **Pause and show results before another fix loop.** Commit/push artifacts, STATE and tracked
   ledger snapshots. Respect remaining usage: one fixer, one verifier, targeted correction;
   avoid repeated broad scans. A scoped check is not a new full review: follow the final-full-
   pass requirement before approval (`reviewer-ledger-schema.md` › Two sets from cycle 2).
5. Once both full passes clear, append separate GATE Pass 1/2 cleared entries, remove active
   ledgers, retain tracked snapshots for handoff, and enter APPROVAL-HALT. Explicit maintainer
   approval is required before `/aid-execute`; do not infer it from approved specification fixes.
6. During later execution, write task state changes immediately. Legacy suites may be red only
   where a task explicitly documents its re-key owner; task-031 must finish fully green.
   PowerShell parity requires pwsh/Windows support. Task-032 owns the manual host probes.

---

## 7. Working conventions for this work (maintainer preferences)

- **Be careful with usage.** One agent at a time on the same file; one pass, no self-review
  loops; agents read only the passages they change; pause and report after every review.
- The last authorized Codex cycle used Luna fixes and Sol verification; in Claude Code use
  available economical models appropriate to the maintainer's next instruction. Do not claim
  unavailable model names were used. Minimize duplicated context and keep one writer per file.
- Every state change goes to `STATE.yml` immediately (project `CLAUDE.md` § Tracking discipline).
  **Gotcha:** `writeback-state.sh` defaults to a wrong path — always call it as
  `AID_STATE_FILE=.aid/works/work-001-shared-skills-folder/STATE.yml bash .claude/aid/scripts/execute/writeback-state.sh --pipeline --field <Field> --value <value>`.
- Commit and push after each step. Commits end with the session attribution lines the host adds.
- Never name a work id/folder inside `.aid/knowledge/**` (project rule; task-029 enforces it).
- Before writing any file, resolve its review criteria (`.aid/knowledge/authoring-conventions.md`).

---

## 8. Key files

| File | Why |
|---|---|
| `REQUIREMENTS.md` | the spec (§9 ACs, §11 design, twin table, test plan, "Upgrade from v3 (clean slate)") |
| `STATE.yml` | pipeline state + full `lifecycle_history` of this work |
| `tasks/task-NNN/DETAIL.md` | the 32 tasks |
| `review-ledgers/` | copies of the two GATE ledgers (restore to `.aid/.temp/review-pending/`) |
| `probe-kits/` | the IDE probe and pointer probe kits + recorded results |
| `.claude/aid/templates/shortcut-engine.md` | the pipeline being followed (GATE, APPROVAL-HALT) |
| `lib/aid-install-core.sh`, `lib/AidInstallCore.psm1`, `bin/aid`, `bin/aid.ps1` | the CLI being changed |
| `.claude/skills/generate-profile/scripts/render.py` | the generator being changed |
