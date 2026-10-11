# Handoff — work-001 Shared Skills Folder (AID v4.0.0)

Written 2026-10-11 by the Claude Code session that ran this work up to here, for the maintainer
to continue in **Codex**. Read this file top to bottom once; it is self-contained.

---

## 1. Quick start (Codex)

1. Check out the branch: `git fetch origin work-001 && git checkout work-001`
   (the same commits are also on `claude/youthful-curie-aqfdvp`).
2. Restore the two review ledgers (they live in a git-ignored folder, so they were copied here):
   ```bash
   mkdir -p .aid/.temp/review-pending
   cp .aid/works/work-001-shared-skills-folder/review-ledgers/*.md .aid/.temp/review-pending/
   ```
3. Read, in this order: this file → `REQUIREMENTS.md` (§1–§11) → `STATE.yml` (`lifecycle_history`
   at the bottom) → the two ledgers.
4. Continue at **§6 Next steps**.

**AID skills in Codex:** this repo has no `.codex/` or `.agents/` install, so Codex does not
auto-discover AID skills. Open the skill file and follow it by hand:
- shortcut engine (this work's pipeline): `.claude/aid/templates/shortcut-engine.md`
  (entered from `.claude/skills/aid-update/SKILL.md`);
- later, execution: `.claude/skills/aid-execute/SKILL.md`.
Their scripts run fine from bash at `.claude/aid/scripts/...` (project root as working directory).

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

- Worktree/branch: `work-001` (created by AID's `worktree-lifecycle.sh`), work folder
  `.aid/works/work-001-shared-skills-folder/`.
- Pipeline: `/aid-update` shortcut engine, flattened Lite work, `phase: Detail`,
  `delivery_state: Specified`, `lifecycle: Paused-Awaiting-Input`.
- `REQUIREMENTS.md`: 17 FR, 21 AC (AC-1..AC-21), assumptions A-1..A-6, §11 Feature 001 spec.
  **Just revised for the v4.0.0 scope — not yet re-reviewed.**
- Tasks: 32 (`tasks/task-001..032/DETAIL.md`), all `Pending`, 14 waves
  (`bash .claude/aid/scripts/execute/derive-waves.sh --from-tasks .aid/works/work-001-shared-skills-folder`).
  **Just aligned to the v4.0.0 revision — not yet re-reviewed.**
- GATE history (grades in `STATE.yml` `lifecycle_history`): Pass 1 (definition) went D+ → C+ →
  A+; then D8 changed the requirements, so they need a scoped re-check. Pass 2 (tasks) cycle 1
  graded D+; its findings were addressed but not re-verified.
- Minimum grade for this work: `A` (`read-setting.sh --skill aid-update --key minimum_grade` → A).

### Ledger status

`shortcut-work-001-shared-skills-folder-defn.md` (definition):
- Rows 1–37: Fixed or Accepted (18 MINOR rows parked by the maintainer as Accepted; 6 LOW rows
  accepted and carried into tasks as "Deferred review note" bullets).
- Rows **38, 39, 40: Pending** — believed resolved by the v4.0.0 revision (fresh install writes
  `.gitattributes`; `--orphans` gone and last-tool remove clears the block; content-based region
  repair). Need verification.

`shortcut-work-001-shared-skills-folder-tasks.md` (task set, cycle 1):
- Rows **1–14: Pending** — all addressed (rows 1, 2, 4–13 by the alignment pass; rows 3 and 14 by
  making task-013 depend on task-012 and task-014 on task-013). Need verification.

### Open items that need the maintainer

1. **Pointer probe** (A-6): run `probe-kits/aid-pointer-probe.zip` in each tool (P1/P2/P3 in its
   `PROMPTS.md`). A tool passes if P1 or P2 shows the rules. A failing tool gets `rules_inline` in
   its profile (the fallback already specified in REQUIREMENTS.md).
2. **Alias list check** (A-4, AC-20): in Cursor with fresh permissions, a skill with
   `allowed-tools: Read Shell Bash Terminal` runs `git init x` without a permission prompt.
   (Claude Code already verified: `Bash` pre-approves.)
3. **Confirm:** `canonical/AGENTS.md` is replaced by `canonical/aid/rules.md`; the release no
   longer ships an `AGENTS.md`; both root regions are constants in the install cores.
4. **Wording conflict to settle:** the clean-slate upgrade writes the fresh import region at the
   end of `CLAUDE.md`, while AC-14(c) says the old region is replaced in place. Tasks 015/021 use
   "lines outside the old region unchanged and in order, one import region, pre-update copy in
   `.aid/.trash/`". Pick one and align AC-14(c) or the tasks.

---

## 6. Next steps (exact order)

1. **Scoped re-review** (strong model, one pass, read-only except ledgers). Brief:
   - Definition ledger: re-verify rows 38–40; look for regressions ONLY in
     `git diff c6f61084 acaf9b9b -- .aid/works/work-001-shared-skills-folder/REQUIREMENTS.md`;
     append new rows (Status Pending). Do not touch Accepted rows.
   - Task ledger: re-verify rows 1–14; look for regressions ONLY in
     `git diff 4a8d3e36 HEAD -- .aid/works/work-001-shared-skills-folder/tasks/`; append new rows.
   - Ledger schema: `.claude/aid/templates/reviewer-ledger-schema.md` (7 columns, no narrative).
   - Do not compute grades.
2. **Grade** each ledger: `bash .claude/aid/scripts/grade.sh --explain <ledger>`. Both must reach
   `A` or better. **Pause and show the maintainer the result before fixing.**
3. **Fix loop** (if needed): smallest edits; mechanical fixes with a small model and exact
   find/replace text; design fixes with a mid model; then a narrow strong-model re-check of the
   changed text only. Circuit breaker: stop after 3 cycles without improvement
   (`shortcut-engine.md § Step 4`).
4. When both passes clear: append the two "GATE Pass N cleared" entries to `lifecycle_history`,
   delete the ledgers (`rm -f .aid/.temp/review-pending/shortcut-work-001-*`; the copies in
   `review-ledgers/` can be deleted too), then **APPROVAL-HALT** (`shortcut-engine.md § State:
   APPROVAL-HALT`) — the maintainer approves before anything is built.
5. Execution later: `.claude/skills/aid-execute/SKILL.md` on this work. Notes for that phase:
   - Each task's `State` must be written the moment it changes (`In Progress` → `In Review` →
     `Done`/`Failed`) — project `CLAUDE.md` § Tracking discipline.
   - Some legacy CLI test suites are **expected red** mid-delivery; each task lists them and the
     task that re-keys them. task-031 must end fully green.
   - PowerShell twin criteria need `pwsh` (Windows or a CI runner with it).
   - task-032 / AC-20 are manual maintainer probes.

---

## 7. Working conventions for this work (maintainer preferences)

- **Be careful with usage.** One agent at a time on the same file; one pass, no self-review
  loops; agents read only the passages they change; pause and report after every review.
- Model tiers (Codex mapping from `profiles/codex.toml`): small `gpt-5.4-mini` for exact
  find/replace edits, medium `gpt-5.4` for design edits, large `gpt-5.5` for reviews.
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
