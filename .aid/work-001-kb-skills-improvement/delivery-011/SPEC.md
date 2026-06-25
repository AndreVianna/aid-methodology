# Delivery SPEC -- delivery-011: Summary Correctness Core (`kb.html` domain-driven)

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-011/STATE.md.

> **Delivery:** delivery-011
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-25

---

## Objective

Realign `/aid-summarize` so `.aid/dashboard/kb.html` becomes **right and complete for the
post-feature-014 domain-driven KB**, and reframe the summary as a **distinct product for a
non-technical newcomer** — easy to read and visually rich, with the KB's no-diagrams authoring
rule explicitly NOT applied. This delivery realizes feature-015 **Changes 1-5** (FR-45–FR-49):
doc-set/domain-driven section derivation, concept-first content components (glossary / ADR /
capability rendered as content, not links), best-format-per-fact + completeness grading (the
diagram-count cap removed), non-technical newcomer tone, and page-shell consistency with
`home.html` + the CLI `index.html` (chrome kept; only the inner content redesigned). It is the
**shippable midpoint** — a correct, complete, shell-consistent summary of the new KB — before the
D-012 engine re-architecture.

## Scope

In scope (feature-015 Changes 1-5):

- **Doc-set/domain-driven input (Change 1, FR-45)** — `references/state-profile.md` reads the
  doc-set from `.aid/settings.yml → discovery.doc_set` and the domain from
  `.aid/knowledge/STATE.md → ## Discovery Domain`; renders **one section per
  resolved doc / `kb-category`** from frontmatter; retires the software project-TYPE profiles;
  removes the **phantom `repo-presentation.md`**; **derives the `noscript` doc list** from the
  resolved doc-set.
- **Concept-first content components (Change 2, FR-46)** — glossary/definition, decision/ADR
  card, capability entry components rendering `domain-glossary.md`, `decisions.md`, and
  `capability-inventory.md` as **content** (added to `component-css.css` + the generation
  templates, keyed by `kb-category`).
- **Best-format-per-fact + completeness grading (Change 3, FR-47)** — rewrite
  `grading-rubric.md` to reward clarity + completeness (coverage of the resolved doc-set) +
  newcomer visual communication; **remove the C+/diagram-count gate** from `grade-summary.sh`;
  no diagram floor/ceiling; the KB no-diagrams rule not applied to the summary.
- **Non-technical newcomer tone (Change 4, FR-48)** — `prompt.md` + section templates +
  `state-generate.md` target a non-technical newcomer; drop the KB's dual-audience/agent-
  frontmatter framing; "At a Glance" stops leading with software metrics.
- **Page-shell consistency (Change 5, FR-49)** — keep/align `html-skeleton.html`'s outer shell
  (top bar, side panel, search, nav chrome) with `home.html` + the CLI `index.html`; redesign
  **only the inner content area**.

**Out of scope:** data-driven deterministic generation (Change 6) and pre-render-SVG + drop the
Mermaid engine + the §7 visual-fidelity gate (Change 7) — those are **delivery-012**; any change
to feature-014's discovery/doc-set machinery (the summary is a *reader*); server-side gzip/cache
(fast-follow, OUT of this work).

## Gate Criteria

- [ ] `/aid-summarize` **reads `discovery.doc_set` + `## Discovery Domain`** and renders one
  section per resolved doc / `kb-category` from frontmatter; **profile-as-project-type is
  retired**; the phantom `repo-presentation.md` is gone; the `noscript` doc list is **derived**
  from the resolved doc-set (no hardcoded list survives). *(FR-45)*
- [ ] The Concept Spine (`domain-glossary.md`), `decisions.md` (ADRs), and the capability
  inventory are rendered as **first-class content components** (glossary/definition, decision/ADR
  card, capability entry) — **rendered, not linked**. *(FR-46)*
- [ ] The rubric rewards **clarity + completeness (resolved-doc-set coverage) + newcomer visual
  communication**, with **no diagram floor and no ceiling**; the C+-unless-N-diagrams gate is
  **removed** from `grade-summary.sh`; the KB no-diagrams rule is **not** applied to the summary.
  *(FR-47)*
- [ ] Summary prose targets a **non-technical newcomer**; the KB's dual-audience/agent-frontmatter
  framing is dropped; "At a Glance" does not lead with software metrics. *(FR-48)*
- [ ] The outer page shell stays **consistent/aligned with `home.html` + the CLI `index.html`**;
  only the inner content area is redesigned (the chrome is not reinvented). *(FR-49)*
- [ ] **Guardrails hold:** C1 (path `<repo>/.aid/dashboard/kb.html`), C2/C3 (single
  self-contained file, no CDN/split assets), C5 (`## Knowledge Summary Status` →
  `**User Approved:** yes (YYYY-MM-DD)`), C6 (`README.md ## Completeness` rows +
  `kb_baseline:` shape), and §5b page-shell consistency. The keep-list (design tokens, theming,
  lightbox, a11y baseline, responsive layout) is preserved.
- [ ] **Delivery grade gate = A+** (this work's quality bar, above the default A minimum).
- [ ] All section-6 quality gates pass: canonical→render parity (full `run_generator.py`),
  dogfood byte-identity (DBI), ASCII-only + WinPS-5.1 lint for any shipped script, and the
  affected canonical summarize suites re-run green.

## Tasks

> Authored by `/aid-detail`. Each task has a full SPEC + STATE at `tasks/task-NNN/`. The
> `Depends on` ordering and waves are in PLAN.md `### delivery-011 execution graph`.

| Task | Type | Title |
|------|------|-------|
| task-064 | DESIGN | Section/IA manifest contract — doc_set + domain + frontmatter kb-category |
| task-065 | IMPLEMENT | Rewire input model to doc-set/domain-driven sections (Change 1) |
| task-066 | IMPLEMENT | Concept-first content components — glossary / ADR / capability (Change 2) |
| task-067 | IMPLEMENT | Best-format-per-fact + completeness grading — remove the diagram-count cap (Change 3) |
| task-068 | IMPLEMENT | Newcomer tone + page-shell consistency with home.html / index.html (Changes 4 + 5) |
| task-069 | TEST | Adapt canonical summarize suites + guardrail checks (C1/C2/C3/C5/C6) |
| task-070 | DOCUMENT | Regen (full run_generator.py) + .claude DBI sync + SKILL/README docs |

## Dependencies

- **Depends on:** delivery-010 (consumes feature-014's `discovery.doc_set`, `## Discovery Domain`,
  the seven custom docs, the concept spine, and `decisions.md` — the domain-driven KB this
  summary must read)
- **Blocks:** delivery-012 (the visual & engineering re-architecture builds on this correctness
  core)

## Notes

- **Reader, not re-spec:** feature-015 makes `/aid-summarize` a reader of feature-014's output;
  it does not re-spec discovery or change `discovery.doc_set`.
- **Two-audience reframing is the spine:** `kb.html` is a different product from the KB — a
  non-technical-newcomer, visually-rich artifact; the KB no-diagrams rule does NOT apply.
  Completeness = ALL project-relevant information represented, format chosen per fact.
- **Shippable midpoint:** after D-011 the summary is correct, complete, and shell-consistent —
  still Mermaid-backed for any diagrams; the engine drop is D-012.
- **Design rationale** lives in
  `.aid/work-001-kb-skills-improvement/features/feature-015-summarize-domain-driven-redesign/SPEC.md`
  §Technical Specification and the design seed `.aid/design/aid-summarize-redesign.md`.
- Affected files: `references/state-profile.md`, `references/state-generate.md`,
  `templates/knowledge-summary/section-templates/*`, `templates/knowledge-summary/html-skeleton.html`,
  `templates/knowledge-summary/component-css.css`, `templates/knowledge-summary/prompt.md`,
  `templates/knowledge-summary/grading-rubric.md`, `scripts/summarize/grade-summary.sh`, `SKILL.md`.
