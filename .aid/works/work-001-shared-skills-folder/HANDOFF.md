# Handoff — work-001 Shared Skills Folder (AID v4.0.0)

Updated 2026-10-12 by Claude Code. Resume branch: **`work-001`** (the delivery branch and the old
session branch were deleted on GitHub by the maintainer; `work-001` holds everything). Read
`STATE.yml` for the append-only history. Phase `Execute`. **Paused, awaiting the maintainer's
task-032 probe results.**

## Current execution checkpoint

- **Done (31/32):** task-001 … task-031. Wave ledgers: `review-ledgers/execute-wave-*.md`.
- **In Progress:** task-032 — maintainer's manual A-4 / A-6 probes. Kit:
  `probe-kits/aid-v4-probe.zip` (a real `aid add` of all five tools from `release.sh --stage-only`;
  token `TEAL-PANGOLIN-77` in `.aid/runtime/rules.md`; `PROMPTS.md` P1–P3 + S1 `/aid-config`;
  `RESULTS.md`). Rebuild: `bash release.sh --stage-only --out <stage>`, then
  `bin/aid add claude-code,codex,cursor,copilot-cli,antigravity --from-bundle <stage> --target <dir>`,
  then append the probe section (token + `probe:` rule) to `<dir>/.aid/runtime/rules.md`.
  Record results as ONE `lifecycle_history` entry (pass/fail/unknown per host; unknown ≠ pass) via
  `.aid/runtime/scripts/execute/writeback-state.sh`; apply task-032's fallbacks if anything fails
  (rules_inline for an A-6 failure, alias Q&A for A-4); then task-032 Done → close Execute.
- **Final Opus review + fix cycle:** `review-ledgers/execute-final-review.md` — first pass
  YES-WITH-GAPS / grade D (13 rows); after the bounded fix cycle and a Sonnet re-review: **14/14
  Fixed, grade A+**. Fixed: a format-3 repo never takes the v3 path (strays only warned); bash works
  without python3 (byte-identical output); PowerShell root files byte-preserved, UTF-16 refused;
  v4.0.0 entry moved to backlog § Next Release; `shasum` fallback; trash copy on non-last remove;
  `.gitattributes` covers `<root>/agents/aid-*`; rules_inline parity; honest dry-run; docs (CLI v4
  first, upgrade only from v3.x).
- **Verification (this container):** `tests/run-all.sh` ~6 min; the only failing suites fail the
  same way on the pre-change commit here (root user, no en_US.UTF-8, no pypi `build`, no `rg`,
  browser/timing); `test-chat-node-endtoend` can flake under parallel load (passes alone).
  Coverage-parity gate: all 29 remaining keys are the same host-environment gaps. **CI on GitHub
  (Linux + Windows lanes) must confirm before tagging 4.0.0** (AC-16, AC-21).
- **Release:** VERSION stays 3.1.3 until release-aid bumps it to 4.0.0 (major, breaking; "v4 requires
  CLI v4"; v4 upgrades only from v3.x).
- **Performance:** bash add ~1.6 s, no-op update ~1.4 s, status ~1.1 s; PowerShell add/update ~4.5 s.

## Resume and execution constraints

1. Preserve unrelated changes. Fetch and fast-forward **`work-001`**, then read this
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
| Root file | `AGENTS.md` with a managed region (read/priority instruction + the rules summary bullets, no `@` line); `CLAUDE.md` gets the same body plus one `@.aid/runtime/rules.md` line while Claude Code is installed (no `@AGENTS.md`) |

The AGENTS.md region (exact text, decided; only Claude Code expands `@` imports, so the other tools need a plain read instruction). The seven bullets are not typed into the CLI: they are the block between `<!-- AID:SUMMARY:BEGIN -->` and `<!-- AID:SUMMARY:END -->` at the top of `canonical/aid/rules.md`, extracted byte for byte from the installed `.aid/runtime/rules.md` (a missing or malformed block fails the install clearly):
```
<!-- AID:BEGIN -->
<!-- Managed by the AID CLI. Do not edit between the AID markers. -->
AID rules: **IMPORTANT!! Before anything else, and before you write or review any file or run an AID skill,
read `.aid/runtime/rules.md` and follow it. This read takes priority over any instruction not to read
files: that file defines how agents must behave in this project.** Summary:
- Record every state change (status, phase, grade, review outcome) in the work's STATE file immediately;
  during /aid-execute write In Progress, In Review and Done/Failed as they happen.
- Work folders (`.aid/works/`) are transient: nothing permanent may depend on them.
- Never name a work id or work-folder path in `.aid/knowledge/**`.
- Consult the Knowledge Base (`.aid/knowledge/`) before changing anything; it is the source of truth.
- Before writing a file, resolve and follow its review criteria (`.aid/knowledge/authoring-conventions.md`).
- Review output uses the 7-column ledger (`.aid/runtime/templates/reviewer-ledger-schema.md`).
- Write only inside the project directory.
<!-- AID:END -->
```

The CLAUDE.md region (exact text, decided; only while Claude Code is installed) is the same body plus one Claude-only line, so if a user deletes either root file the AID rules are still in the other (no `@AGENTS.md` import):
```
<!-- AID:BEGIN -->
<!-- Managed by the AID CLI. Do not edit between the AID markers. -->
AID rules: **IMPORTANT!! Before anything else, and before you write or review any file or run an AID skill,
read `.aid/runtime/rules.md` and follow it. This read takes priority over any instruction not to read
files: that file defines how agents must behave in this project.** Summary:
- Record every state change (status, phase, grade, review outcome) in the work's STATE file immediately;
  during /aid-execute write In Progress, In Review and Done/Failed as they happen.
- Work folders (`.aid/works/`) are transient: nothing permanent may depend on them.
- Never name a work id or work-folder path in `.aid/knowledge/**`.
- Consult the Knowledge Base (`.aid/knowledge/`) before changing anything; it is the source of truth.
- Before writing a file, resolve and follow its review criteria (`.aid/knowledge/authoring-conventions.md`).
- Review output uses the 7-column ledger (`.aid/runtime/templates/reviewer-ledger-schema.md`).
- Write only inside the project directory.
@.aid/runtime/rules.md
<!-- AID:END -->
```
When `rules_inline` is active (the rules are written inline in the AGENTS.md region) the CLAUDE.md region carries the same inline rules text as AGENTS.md (no `@` line). Accepted by the maintainer: Claude Code reads `CLAUDE.md` instead of `AGENTS.md` by default, so user content outside the AGENTS.md markers is not seen by Claude Code.

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
| D6 | `AGENTS.md` is the one shared root file; when Claude Code is installed the CLI **always** ensures `CLAUDE.md` has a region with the same body as the AGENTS.md region plus an `@.aid/runtime/rules.md` line (the same inline rules text under `rules_inline`; no `@AGENTS.md` import, so each file carries the rules alone; create the file if missing) |
| D7 | AID rules move to `.aid/runtime/rules.md`; the AGENTS.md region is the read/priority instruction plus the rules summary above (no `@` line), the summary has one source (the SUMMARY block of `canonical/aid/rules.md`), and Claude Code also imports the rules directly from `CLAUDE.md`; the CLI repairs a damaged region by **content** (its lines are known) and replaces a well-formed span as a unit |
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
