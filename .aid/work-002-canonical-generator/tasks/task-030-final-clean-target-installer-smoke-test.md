# task-030: Final clean-target installer smoke test — H6 retired end-to-end

**Type:** TEST

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** task-027

**Scope:**
- Independent of task-029 — this is the "H6 retired end-to-end" check that closes AC6.
- Create a fresh empty target directory (not the scratch from task-002 — a new one).
- Run `./setup.sh <new-target>` from the repo root and select **all three tools** (Claude Code + Codex + Cursor).
- Assert the target contains all expected artifacts for each tool:
  - **Claude Code:** `.claude/` (with `agents/`, `skills/`, `templates/`), `CLAUDE.md`.
  - **Codex:** `.codex/` (with `agents/`), **`.agents/` (with `skills/`, `templates/`)** ← the H6 fix; explicitly grep that `.agents/skills/aid-discover/SKILL.md` exists. `AGENTS.md` at the target root.
  - **Cursor:** `.cursor/` (with `agents/`, `skills/`, `templates/`, `rules/`), `AGENTS.md`.
- Repeat on PowerShell with `.\setup.ps1 <new-target> -Force` selecting all three (parity check between Bash and PowerShell installers).
- Confirm:
  - The Codex `.agents/skills/` directory contains all 10 SKILL.md files (one per skill: aid-init, aid-discover, aid-interview, aid-specify, aid-plan, aid-detail, aid-execute, aid-deploy, aid-monitor, aid-summarize). This is the load-bearing AC6 check — its absence was the H6 bug.
  - Slash commands would now resolve in a Codex environment because the SKILL.md bodies are present (this is the user-visible symptom-resolution that H6 closes; can't be tested end-to-end without an actual Codex CLI runtime, so this is a presence assertion only).
- Clean up the target directory after assertion.

**Acceptance Criteria:**
- [ ] `setup.sh` installs all three tools cleanly into a fresh target.
- [ ] `setup.ps1` does the same on PowerShell.
- [ ] All 10 Codex SKILL.md files are present under `<target>/.agents/skills/aid-*/SKILL.md` — AC6 live evidence.
- [ ] Claude Code and Cursor install artifacts are equally present (regression check — the H6 fix didn't break the other two tool branches).
- [ ] The PLAN.md Change Log entry documents AC6 verified live; tech-debt H6 status flipped from "open" to "retired" in `.aid/knowledge/tech-debt.md` (a small KB update).
