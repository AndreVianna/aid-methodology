# task-061: Dual-audience authoring standard (kb-authoring + templates + prompts + Anatomy mandate)

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-061/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-010

**Depends on:** task-056

**Scope:**
- Write the **dual-audience authoring standard** into kb-authoring:
  `principles.md` (granularity = one concern per doc, minimal overlap, small-focused default,
  split oversized; language = simple/clear/junior-professional; format = tables + bullets,
  **avoid diagrams** in KB `.md` docs), `frontmatter-schema.md` (machine-consumable
  classification: concern/dimension, tier, audience, owner, tags), `tier-model.md` (cross-ref),
  and the **doc layout convention**: `frontmatter -> index -> content -> change log (last)`.
- Bake compliance into the **knowledge-base doc templates**
  (`canonical/aid/templates/knowledge-base/*.md`: frontmatter fields + an index placeholder +
  change-log-at-end) and the **generation prompts**
  (`canonical/skills/aid-discover/references/agent-prompts.md`: instruct small single-concern,
  junior-clear, tables/bullets-no-diagrams, classified, correct layout).
- Wire the **review panel's Anatomy mandate**
  (`canonical/skills/aid-discover/references/state-review.md` + any kb helper script) to
  **check** the standard: layout order, frontmatter fields present, index present,
  change-log-last, **diagram-absence** (mechanical); reading level + single-concern coherence
  (judgment).

**Acceptance Criteria:**
- [ ] kb-authoring docs state the standard (granularity, junior-clarity, tables/bullets-no-
  diagrams, dual-audience classification, layout order). *(FR-43, FR-44)*
- [ ] Doc templates + generation prompts comply with / instruct the standard (frontmatter +
  index + changelog-last). *(FR-43, FR-44)*
- [ ] The **Anatomy mandate checks** the standard — mechanical checks named (layout/
  frontmatter/index/changelog/diagram-absence), judgment checks prompted (reading level,
  single-concern). *(FR-44)*
- [ ] The `kb.html` visual summary is explicitly **out of scope** for the no-diagram rule.
- [ ] Any shipped script ASCII-only. All section-6 quality gates pass.
