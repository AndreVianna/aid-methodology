# task-060: Self-bootstrap STATE (discover-preflight self-create; remove init hard-stop)

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-060/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-010

**Depends on:** -- (none)

**Scope:**
- Change `canonical/aid/scripts/kb/discover-preflight.sh` so a **missing
  `.aid/knowledge/STATE.md` is self-created** from `discovery-state-template.md` instead of
  exiting non-zero with "run /aid-config first". Preserve the not-Plan-Mode check.
- Update `canonical/skills/aid-discover/SKILL.md` Pre-flight Checks prose to reflect
  self-bootstrap (no init precondition for STATE).
- Ensure the State Detection legacy "no STATE.md" path remains coherent (now STATE is
  self-seeded on first run).

**Acceptance Criteria:**
- [ ] `discover-preflight.sh` no longer exits non-zero on a missing `STATE.md`; it **creates
  STATE.md from the template** and passes. *(FR-41)*
- [ ] `SKILL.md` pre-flight text updated (no "run /aid-config first" hard-stop for STATE). *(FR-41)*
- [ ] Script is **ASCII-only**; preflight test updated/added to cover self-bootstrap.
- [ ] All section-6 quality gates pass.
