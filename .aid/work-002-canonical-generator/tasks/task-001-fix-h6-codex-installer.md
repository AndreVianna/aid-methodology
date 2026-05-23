# task-001: Fix H6 — Codex installer omits `.agents/` copy

**Type:** MIGRATE

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** — (none)

**Scope:**
- Modify `setup.sh` Codex branch (currently lines 142–146) to additionally copy `codex/.agents/` to `$TARGET/.agents/` using the existing `copy_dir` helper. Insert the new line between the current `copy_dir "$SCRIPT_DIR/codex/.codex" "$TARGET/.codex"` and `copy_file "$SCRIPT_DIR/codex/AGENTS.md" "$TARGET/AGENTS.md"` lines.
- Modify `setup.ps1` Codex branch (currently lines 136–141) to additionally copy `codex\.agents` to `$Target\.agents` using the existing `Copy-Dir-Safe` helper. Insert the new line between the existing `.codex` copy and the `AGENTS.md` copy.
- No other installer logic changes. Do NOT alter the Claude Code or Cursor branches. Do NOT touch the menu, the copy helpers, or the final "Next steps" banner.
- Both branches must remain idempotent under the existing "skip identical / prompt on different / `--force` overwrite" semantics — those are provided by the helpers already; the new `copy_dir` / `Copy-Dir-Safe` call inherits them.
- This task is independent of the generator and ships first. The KB items it retires are tech-debt **H6** (`tech-debt.md` lines 116–124) and DISCOVERY-STATE Q70.

**Acceptance Criteria:**
- [ ] `setup.sh` Codex branch contains exactly three operations in order: `copy_dir codex/.codex → .codex`, `copy_dir codex/.agents → .agents`, `copy_file codex/AGENTS.md → AGENTS.md`.
- [ ] `setup.ps1` Codex branch contains the equivalent three operations using `Copy-Dir-Safe` and `Copy-Item-Safe`.
- [ ] Static check: `grep -n "codex/.agents" setup.sh` returns at least one match inside the Codex `if` block; `grep -n "codex\\\\.agents" setup.ps1` (or PowerShell equivalent) returns at least one match inside the Codex `if` block.
- [ ] No other lines in either installer are modified (verified via `git diff` review — diff is confined to the two Codex branches).
- [ ] Both scripts remain syntactically valid (`bash -n setup.sh` succeeds; `pwsh -NoProfile -Command "{ . ./setup.ps1 -TargetDirectory 'x' -WhatIf }"` does not parse-fail — or equivalent dry parse check).
