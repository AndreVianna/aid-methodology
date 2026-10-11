# Handoff — work-001 Shared Skills Folder (AID v4.0.0)

Updated 2026-10-11 by Codex. Resume branch: **`aid/work-001-shared-skills-folder-delivery-001`**.
Read `STATE.yml` for the complete append-only history. Specification GATE cleared A+/A+;
maintainer approved execution. Current phase `Execute`, lifecycle `Running`.

## Current execution checkpoint

Wave4 implementations committed/pushed: 007 67c3360d5 (packaging51 pass), 016 656a5806a (source-invariants23 pass). Both In Review for Sol. Full scanner suite S04 fails coined-term preservation despite new scanner controls passing; baseline/ownership not yet independently verified, do not claim task016 clear. Wave5 not started.

- Done (7/32): task-001, task-002, task-003, task-004, task-005, task-006, task-011.
- In Progress: none.
- In Review: task-007, task-016.
- Failed/Blocked: none.
- Pending: task-008, task-009, task-010, task-012, task-013, task-014, task-015, task-017, task-018, task-019, task-020, task-021, task-022, task-023, task-024, task-025, task-026, task-027, task-028, task-029, task-030, task-031, task-032.
- Current wave: 4 of 15. Derive authoritative waves from task dependency headers.
- Execution commits are on the delivery branch; `work-001` holds pre-execution planning.
- Wave ledgers: `review-ledgers/execute-wave-N.md`; each preserves unresolved/Accepted findings.
- Wave-1 Accepted item: Bash `_v3_quote` versus Python `json.dump` non-ASCII escaping; recheck at final review.
- Required PowerShell twins are implemented; their execution checks are deferred at maintainer request.
- Manual A-4/A-6 probes remain task-032; unknown is not pass.

## Resume and execution constraints

1. Preserve unrelated changes. Fetch and fast-forward the **delivery branch**, then read this
   handoff, STATE and the next task DETAIL. Do not restore old specification ledgers or redo GATE.
2. Sequential tasks, one writer at a time. In Codex use **gpt-6-luna** for task execution and
   **gpt-6.1-sol** for the quick check at each wave and final full review. Claude Code should use
   economical available equivalents; the prior IDE session used Haiku/Sonnet/Opus.
3. Orchestrator immediately writes In Progress before dispatch, In Review after the task commit,
   and Done/Failed after wave review. Use:
   `AID_STATE_FILE=.aid/works/work-001-shared-skills-folder/STATE.yml bash .claude/aid/scripts/execute/writeback-state.sh --task-id NNN --field state --value '<State>'`.
   After task-027 use `.aid/runtime/scripts/execute/writeback-state.sh` and reload `aid-execute`.
4. No long developer checks: coverage-parity, tests/run-all.sh, full regressions,
   render.py --self-test deferred to task-031. Focused task checks only. No chmod/mode changes.
   Host awk is mawk; distinguish the known DBI01 issue from real byte drift. Defer pwsh checks.
5. Wave quick check records an exact seven-column ledger. One Luna fix attempt, then one Sol
   fix attempt, then Failed/block dependents. Final full Sol review after all tasks, then pause/report.
6. Read only requirement slices and relevant KB/contracts. Commit exact task files and push
   checkpoints; preserve unrelated generated site changes, local config and node_modules artifacts.
   Keep usage small. Codex cannot read the user's 5-hour usage meter; stop and hand off when signaled.
7. Format-3 writers are `manifest_write_v3` / `_manifest_write_v3_python` /
   `_manifest_write_v3_bash` / `Write-AidManifestV3`; old format-2 writers remain until task-009.
   `copy_file_guarded <src> <dst> [sha] [root]`: pass root explicitly; `trash_file <root> <file> [stamp]`.
8. Every state/artifact outcome is tracked immediately; reviewer alone marks findings Fixed.
   KB content never names a work id/path. Resolve authoring criteria before writing.

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

## Key files

- `tasks/task-NNN/DETAIL.md`: scope and acceptance criteria.
- `REQUIREMENTS.md`: exact contract; use slice-requirements.sh plus precise additional sections.
- `STATE.yml`: pipeline and task state; lifecycle history and dispatch records.
- `PLAN.md`: execution graph/delivery gates.
- `review-ledgers/`: persistent wave and specification review snapshots.
- `probe-kits/`: manual host probe kits/evidence.
- `.claude/skills/aid-execute/SKILL.md`: execution workflow until task-027 resync.
