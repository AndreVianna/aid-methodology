# Handoff — work-001 Shared Skills Folder (AID v4.0.0)

Updated 2026-10-12 by Claude Code. Resume branch: **`aid/work-001-shared-skills-folder-delivery-001`**.
Read `STATE.yml` for the complete append-only history. Phase `Execute`. **Paused after the final
Opus full review, awaiting the maintainer** (decision on the review findings + task-032 probe results).

## Current execution checkpoint

- **Done (31/32):** task-001 … task-031. Waves 1–14 closed; wave ledgers in `review-ledgers/execute-wave-*.md`.
- **In Progress:** task-032 — the maintainer's manual A-4 / A-6 probes. Kit:
  `probe-kits/aid-v4-probe.zip` (real `aid add` of all five tools from `release.sh --stage-only`,
  token `TEAL-PANGOLIN-77` in `.aid/runtime/rules.md`, `PROMPTS.md` P1–P3 + S1 `/aid-config`,
  `RESULTS.md`). Rebuild: `bash release.sh --stage-only --out <stage>`, then
  `bin/aid add claude-code,codex,cursor,copilot-cli,antigravity --from-bundle <stage> --target <dir>`,
  then append the probe section (token + `probe:` rule) to `<dir>/.aid/runtime/rules.md`.
  Record results as ONE `lifecycle_history` entry (pass/fail/unknown per host; unknown ≠ pass), then
  apply task-032's fallbacks if anything fails (rules_inline for an A-6 failure, alias Q&A for A-4).
- **Final Opus review:** `review-ledgers/execute-final-review.md` — verdict **YES-WITH-GAPS**, grade
  **D**, 13 rows Pending (4 HIGH, 4 MEDIUM, 3 LOW, 2 MINOR). Release call: not ready for 4.0.0 until:
  1. HIGH 1 — `aid update` on a v4 (format-3) repo flips into the v3 upgrade when a legacy path
     appears (e.g. `.cursor/aid/` restored by a branch switch, a user `.codex/skills/aid-*`), and then
     drops installed tools / trashes the mirror (`bin/aid:6458`, both shells).
  2. HIGH 2 — bash now hard-requires python3 (manifest readers) with no up-front check; without it
     `aid add` writes files then dies before the manifest. Docs say curl/bundle channels need only Bash.
  3. HIGH 3 — PowerShell re-reads `CLAUDE.md` / `AGENTS.md` as UTF-8 and corrupts non-UTF-8 bytes
     with no trash copy (PS 5.1 writes cp1252/UTF-16 by default).
  4. HIGH 4 — `release-tracking.md` has `## v4.0.0 - unreleased` while `backlog.md` § Next Release is
     empty; move the entry to backlog § Next Release (release-aid writes the dated section at tag time).
  MEDIUM: bare `sha256sum` (no `shasum` fallback) in region hashing; `aid remove` of a non-last tool
  rewrites the AGENTS.md region without a trash copy; `.gitattributes` block omits `<root>/agents/aid-*`
  (spec gap; Windows autocrlf); PowerShell `rules_inline` repair not in parity (untested).
  LOW/MINOR: dry-run trash list, upgrade docs (update CLI first; pre-v3 → v3 first), rules.md wording,
  two stale comments. Plus: green CI on master for AC-21 and the Windows lane (AC-16).
- **Verification state (this container):** `tests/run-all.sh` 161/170 in 344 s; coverage-parity gate
  clean except 29 keys; the 9 failing suites and all 29 keys fail/miss identically on the pre-change
  commit here (root user, no en_US.UTF-8, no pypi `build`, no `rg`, browser/timing) → host-environment.
  CI must confirm.
- **Execution-time changes beyond task scopes (all pushed):** ~20 PowerShell runtime fixes found
  once pwsh was installed (incl. a parse error that broke every PS command); v3-upgrade fixes
  (`.cursor/rules` / `.agent/rules` ownership, format-less manifests); performance pass (bash add
  7.1→2.0 s, no-op update 12.8→1.8 s; PS 5.7→4.4 s; migrate suite 540→144 s, parity 500→224 s;
  coverage collect now parallel); maintainer decision **v4 upgrades only from v3.x** (spec updated;
  pre-v3 migration gates removed from the suites); dead format-2 install code deleted (~980 lines).
- **Next (when the maintainer decides):** fix HIGH 1–4 (and the MEDIUMs worth it) as a bounded fix
  cycle → focused suites + parity → re-review → record task-032 → task-032 Done → close Execute.

## Resume and execution constraints

1. Preserve unrelated changes. Fetch and fast-forward the **delivery branch**, then read this
   handoff, STATE and the next task DETAIL. Do not restore old specification ledgers or redo GATE.
2. Sequential tasks, one writer at a time. In Codex use **gpt-6-luna** for task execution and
   **gpt-6.1-sol** for the quick check at each wave and final full review. Claude Code should use
   economical available equivalents; the prior IDE session used Haiku/Sonnet/Opus.
3. Orchestrator immediately writes In Progress before dispatch, In Review after the task commit,
   and Done/Failed after wave review. Use:
   `AID_STATE_FILE=.aid/works/work-001-shared-skills-folder/STATE.yml bash .claude/aid/scripts/execute/writeback-state.sh --task-id NNN --field state --value '<State>'`.
   Since task-027 the writer is `.aid/runtime/scripts/execute/writeback-state.sh` (same arguments).
4. Long checks (run-all, coverage-parity gate) are now fast: run-all ~6 min, coverage collect ~6 min
   (parallel). Needs pwsh, node, python3 and GNU awk on PATH. In a fresh cloud container install
   them first (`apt-get install -y gawk`; pwsh tarball from the PowerShell GitHub releases). No
   chmod/mode changes (all tests/canonical/*.sh are tracked executable).
5. Wave quick check records an exact seven-column ledger. One Luna fix attempt, then one Sol
   fix attempt, then Failed/block dependents. Final full Sol review after all tasks, then pause/report.
6. Read only requirement slices and relevant KB/contracts. Commit exact task files and push
   checkpoints; preserve unrelated generated site changes, local config and node_modules artifacts.
   Keep usage small. Codex cannot read the user's 5-hour usage meter; stop and hand off when signaled.
7. Manifest writers are `manifest_write_v3` / `Write-AidManifestV3` (format-2 writers deleted).
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
