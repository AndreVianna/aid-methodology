# task-002: Smoke-test the H6 installer fix end-to-end

**Type:** TEST

**Source:** work-002-canonical-generator → delivery-001

**Depends on:** task-001

**Scope:**
- Create an empty scratch target directory.
- Run `./setup.sh <scratch-dir> --force` from the repo root and select **only the Codex tool** (option 2). On Windows, run the equivalent `.\setup.ps1 <scratch-dir> -Force` invocation.
- After the run, assert the scratch directory contains all three Codex install artifacts:
  - `<scratch-dir>/.codex/` (existed before the fix; must still land).
  - `<scratch-dir>/.agents/` (the H6 fix — must now exist and contain `skills/aid-{init,discover,interview,specify,plan,detail,execute,deploy,monitor,summarize}/SKILL.md`).
  - `<scratch-dir>/AGENTS.md` (existed before the fix; must still land).
- Specifically grep that the `.agents/skills/aid-discover/SKILL.md` file exists and is non-empty (this is the file whose absence is the load-bearing H6 symptom — slash commands appear inert without it).
- Repeat with `setup.ps1` on PowerShell at minimum once (Windows-side parity check).
- Clean up the scratch directory after assertion.
- This smoke test becomes a permanent regression — keep the script (or document the manual steps) in the work item history so the H6 retirement is replayable on demand.

**Acceptance Criteria:**
- [ ] Bash run: `setup.sh` against an empty target with Codex selected produces all three artifacts (`.codex/`, `.agents/`, `AGENTS.md`); `.agents/skills/aid-discover/SKILL.md` is present and non-empty.
- [ ] PowerShell run: `setup.ps1` produces the same three artifacts on Windows.
- [ ] The smoke check returns non-zero exit if any of the three artifacts is missing (so it is wiring-ready for the eventual CI proposed in H2).
- [ ] The script / steps are reproducible — a second run against a fresh empty target yields the same pass.
