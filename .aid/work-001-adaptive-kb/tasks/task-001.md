# task-001: Reconcile discovery-scout / discovery-quality doc ownership

**Type:** IMPLEMENT

**Source:** feature-001-scout-ownership-reconcile → delivery-001

**Depends on:** — (none)

**Scope:**
- Edit `canonical/` only, then re-render with `python run_generator.py`.
- `canonical/agents/discovery-scout/AGENT.md`: frontmatter `description` (~L3); `## What You Do` Produce line + surrounding bullets (~L65–68); add an infrastructure disclaimer to `## What You Don't Do` (~L70–75); replace the embedded `### infrastructure.md` template in `## Output Documents` (~L85–138) with an `external-sources.md` shape and keep `project-structure.md`; retarget `## When to Escalate` + ~L143/L149–151 off infrastructure. Net: scout owns `project-structure.md` + `external-sources.md`, never `infrastructure.md`.
- `canonical/agents/discovery-scout/README.md`: ~L25 infrastructure → external-sources; re-point "What It Does" item 2; promote `external-sources.md` to a first-class produced doc.
- `canonical/agents/discovery-quality/AGENT.md`: add `infrastructure.md` to the `## What You Do` Produce line (~L68); retarget the `## What You Don't Do` line (~L75) off infrastructure (to project-structure/open-questions) so quality no longer hands infra to scout.
- Do NOT touch `state-generate.md` / `SKILL.md` / `agent-prompts.md` (already-correct source of truth). Do NOT touch any "14"/"16" count literal (that is task-008 / FR-P0-4).
- Log whether the dogfood `.claude/` refresh rides along or is deferred (REQUIREMENTS §4 marks dogfood refresh OOS).

**Acceptance Criteria:**
- [ ] Scout's description, What-You-Do, What-You-Don't-Do, Output-Documents, and Escalate sections show structure + external-sources and never list `infrastructure.md` as a scout output; scout disclaims infra.
- [ ] Quality's `## What You Do` Produce line includes `infrastructure.md`; its `## What You Don't Do` no longer disclaims infra. The two agent defs are reciprocal.
- [ ] `state-generate.md` dispatch table, `agent-prompts.md`, and the SKILL.md Targeted-Discovery map are unchanged; no "14"/"16" literal touched.
- [ ] Rendered `profiles/*/.../agents/discovery-scout.*` and `discovery-quality.*` reflect the edits (read the rendered text).
- [ ] All §6 quality gates pass: generator self-tests green, render-drift clean across the 3 profiles, existing 13 canonical suites green.
