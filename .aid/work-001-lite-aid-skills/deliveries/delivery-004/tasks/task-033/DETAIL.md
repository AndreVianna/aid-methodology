# task-033: aid-monitor routing re-point (Must)

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-004

**Depends on:** task-027, task-029, task-013

**Scope:**
- Re-point `aid-monitor`'s finding routing (targets only; the classification vocabulary BUG/CHANGE REQUEST/INFRASTRUCTURE/NO ACTION is unchanged): BUG -> `/aid-fix`, Change Request -> `/aid-triage`. Edit `canonical/skills/aid-monitor/SKILL.md` (`description` + `## Agents Involved` Routing targets), `canonical/skills/aid-monitor/references/state-route.md` (Step 4 proposal lines + Step 5 Act blocks), `canonical/skills/aid-monitor/README.md` (classification->route table + the Act bullet; drop the "lite bug-fix triage" prose).
- KB lockstep: update `.aid/knowledge/pipeline-contracts.md` Feedback Loop Contracts rows L9 (`Monitor -> Fix (bug)`) and L10 (`Monitor -> Triage (CR)`) so the KB and the skill agree.
- No surviving reference to `aid-describe`-lite / "lite bug-fix triage" / `LITE-BUG-FIX` in any aid-monitor file.

**Acceptance Criteria:**
- [ ] aid-monitor routes BUG -> `/aid-fix` and Change Request -> `/aid-triage` across SKILL.md + state-route.md + README.md; classification vocabulary unchanged (A-9/AC-9).
- [ ] `pipeline-contracts.md` L9/L10 targets updated in lockstep.
- [ ] No surviving `aid-describe`-lite / "lite bug-fix triage" / `LITE-BUG-FIX` reference (grep) in any aid-monitor file.
- [ ] Renders to all 5 profiles; `render-drift` green; dogfood byte-identical.
- [ ] All existing tests still pass (`tests/run-all.sh` green).
- [ ] All §6 quality gates pass.
