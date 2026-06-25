# task-065: Rewire input model to doc-set/domain-driven sections (Change 1)

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-065/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-011

**Depends on:** task-064

**Scope:**
- Implement feature-015 **Change 1 (FR-45)** against the task-064 manifest contract, editing the
  **canonical** sources only (`canonical/skills/aid-summarize/...` and
  `canonical/aid/templates/knowledge-summary/...`) — never the rendered `.claude/` copy (regen is
  task-070).
- **`references/state-profile.md` -> doc-set-driven.** Replace project-TYPE profile selection with
  a read of the doc-set from `.aid/settings.yml -> discovery.doc_set` and the domain from
  `.aid/knowledge/STATE.md -> ## Discovery Domain`; resolve the section manifest from the doc-set +
  each doc's frontmatter (one section per resolved doc / `kb-category`).
- **`references/state-generate.md`** — derive the section manifest from frontmatter (not from
  `section-templates/{type}.md`); wire the derived `noscript` doc list and the newcomer-framed
  "At a Glance" inputs per the manifest. (Concept-component content rendering is task-066; tone
  polish is task-068 — this task wires the data flow + section set.)
- **`templates/knowledge-summary/section-templates/*`** — **retire the seven software project-TYPE
  profiles** as project-type selectors; where any survive, recast them as **rendering hints keyed
  by `kb-category`/spine-dimension**, not project-type. **Remove the phantom `repo-presentation.md`
  reference** in `agentic-pipeline.md` and any prose that cites it.
- **`templates/knowledge-summary/html-skeleton.html`** — replace the hardcoded `noscript` doc list
  with the derived-at-generation list (no hardcoded doc list survives in the skeleton). Touch the
  `noscript` content region only; the outer shell is task-068's concern (no chrome change here).
- **`SKILL.md`** — update the state-flow prose to describe the doc-set/domain read (retire the
  profile-selection wording).
- Trivial state/arg derivation stays in **prose** (state-*.md), not a new script (per the
  prose-over-scripts lesson).

**Acceptance Criteria:**
- [ ] Given a KB produced by feature-014, `/aid-summarize` reads `discovery.doc_set` from
  `.aid/settings.yml` and the domain from `.aid/knowledge/STATE.md -> ## Discovery Domain`, and
  renders **one section per resolved doc / `kb-category`** derived from frontmatter. *(FR-45)*
- [ ] **Profile-as-project-type is retired** — no `section-templates/{type}.md` is selected as a
  project-type profile; any surviving template is keyed by `kb-category`/spine-dimension as a
  rendering hint. *(FR-45)*
- [ ] The **phantom `repo-presentation.md`** reference is removed everywhere it appears
  (`agentic-pipeline.md` + any prose); a repo-wide grep for `repo-presentation` in
  `canonical/skills/aid-summarize` + `canonical/aid/templates/knowledge-summary` returns no live
  reference. *(FR-45)*
- [ ] The `noscript` doc list is **derived from the resolved doc-set** at generation time; no
  hardcoded doc list survives in `html-skeleton.html` or the templates. *(FR-45)*
- [ ] All edits are in `canonical/...` sources (not `.claude/`); the change set matches the
  task-064 retirement enumeration. Guardrails C1/C2/C3/C5/C6 + §5b are not regressed (path,
  self-containment, approval/completeness signals, shell unchanged by this task).
- [ ] All section-6 quality gates pass.
