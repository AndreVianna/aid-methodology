# task-013: aid-fix catalog row + fix.md scaffolding reference

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-007, task-008, task-009

**Scope:**
- Add the `aid-fix` row to `canonical/aid/templates/shortcut-catalog.yml` (`verb=fix`, `artifact=""`, `alias_of=null`, `default_type=IMPLEMENT`, `group=G6`). aid-fix stays bare (no artifact suffixes, no aliases).
- Create `canonical/aid/templates/shortcut-scaffolding/fix.md` -- the fix scaffolding reference. CAPTURE slots: symptom/title, reproduction steps, expected vs actual, `fix-kind` (`defect | regression | incident | vulnerability`), affected area. Default breakdown: `task-001` IMPLEMENT (reproduce + root-cause + patch) + `task-002` TEST (regression test that fails on pre-fix code and passes on post-fix), depends task-001. fix-kind adaptations: defect (base); regression (repro pinned to the regressing change); vulnerability (`### Security Specs` activated, TEST proves the exploit path closed, deep SAST/DAST -> route `aid-test-security`); incident (mitigation here, postmortem/runbook -> `aid-document-runbook`).
- Generate `canonical/skills/aid-fix/SKILL.md` by running `build-shortcut-skills.py` (not hand-written).

**Acceptance Criteria:**
- [ ] `aid-fix` row present (bare, IMPLEMENT, G6); `canonical/skills/aid-fix/SKILL.md` generated (name == dir, `aid-` prefix, delegates to the engine) (AC-1 G6 subset).
- [ ] `fix.md` defines the fix-kind slot, the IMPLEMENT -> TEST breakdown, the four fix-kind adaptations, and the routing boundaries.
- [ ] `aid-fix` stays bare with no artifact-suffixed variants (AC-4 fix-bare).
- [ ] Renders to all 5 profiles; `render-drift` green; dogfood byte-identical; existing tests pass.
- [ ] All §6 quality gates pass.
