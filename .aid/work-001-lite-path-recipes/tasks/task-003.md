# task-003: Rewrite TRIAGE to description-first classification

**Type:** REFACTOR

**Source:** feature-002-description-first-triage → delivery-001

**Depends on:** task-001

**Scope:**
- Wholesale rewrite of `canonical/skills/aid-interview/references/state-triage.md` from the T1/T2/T3-sizing + deterministic-rule model to a **description-first** model that infers work-type + best recipe from a free-form work description (via the recipe `summary:` field) and asks the user to confirm in one turn:
  - Delete the T1/T2/T3 sizing questions and the deterministic sizing rule.
  - Author new **Steps 1–4** for the description-first flow (capture free-form description → infer type + match recipe by `summary:` → present single-recipe confidence decision → confirm/escalate).
  - Keep sub-steps **5a-1**, **5a-3**, and **5a-4 verbatim** (unchanged routing/handoff prose).
  - Drop the `single-doc` and `LITE-DOC` rows from the routing/decision tables.
  - Re-key any unit/reference tables whose numbering shifts because of the rewrite so cross-references stay valid.
- This task does NOT remove the LITE-DOC sub-path body or its KB/template references — those are task-004.

**Acceptance Criteria:**
- [ ] `state-triage.md` contains no T1/T2/T3 sizing question and no deterministic sizing rule; the flow is description-first with Steps 1–4.
- [ ] Sub-steps 5a-1, 5a-3, and 5a-4 are byte-identical to their pre-rewrite text.
- [ ] No `single-doc` or `LITE-DOC` row remains in any decision/routing table in `state-triage.md`.
- [ ] All re-keyed unit/reference tables are internally consistent (no dangling cross-reference).
- [ ] All §6 quality gates pass.
