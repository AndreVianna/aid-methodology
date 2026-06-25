# task-064: Section/IA manifest contract — doc_set + domain + frontmatter kb-category

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-064/STATE.md.

**Type:** DESIGN

**Source:** work-001-kb-skills-improvement -> delivery-011

**Depends on:** delivery-010 (feature-014 `discovery.doc_set`, `## Discovery Domain`, `kb-category`
frontmatter, the seven custom docs, the concept spine, and `decisions.md`)

**Scope:**
- Define the **section/IA manifest contract** that drives the redesigned summary: the precise,
  data-driven mapping from feature-014's outputs to the summary's section set, BEFORE any skill
  file is rewired (task-065 implements against this contract).
- Specify the **two distinct input sources** (do not conflate — they live in different files):
  the doc-set from `.aid/settings.yml -> discovery.doc_set`, and the domain from
  `.aid/knowledge/STATE.md -> ## Discovery Domain`. State which field each section attribute is
  derived from.
- Define **one section per resolved doc / `kb-category`**, with each section's attributes derived
  from the doc's frontmatter (`kb-category`, `objective`, `summary`, `audience`, `tags`). Specify
  the section ordering rule and how `domain` informs framing/labels (not a fixed gallery).
- Specify the **category -> component mapping** the manifest hands to task-066 (which `kb-category`
  renders as glossary/definition, which as decision/ADR card, which as capability entry, and the
  **generic table/card/prose fallback** for any resolved doc with no bespoke component — so
  completeness = coverage, never a dropped doc).
- Specify the **derived `noscript` doc list** rule (enumerated from the resolved doc-set at
  generation time) and the **"At a Glance"** newcomer-framing inputs (what the project is / does),
  retiring the software-metric lead.
- Enumerate **what is retired**: profile-as-project-type selection, the phantom
  `repo-presentation.md` reference, and the hardcoded `noscript`/seed-doc lists — and where each
  lives today (`state-profile.md` seed grep, `section-templates/agentic-pipeline.md` phantom doc,
  `html-skeleton.html` hardcoded list).
- Output is a written manifest/contract document at a fixed, discoverable path —
  `.aid/work-001-kb-skills-improvement/features/feature-015-summarize-domain-driven-redesign/section-manifest.md`
  (tasks 065/066/067 consume it from there); it is **DESIGN only** — no canonical skill file is
  edited in this task.

**Acceptance Criteria:**
- [ ] The manifest names the **exact source field** for each derived attribute: doc-set from
  `.aid/settings.yml -> discovery.doc_set`, domain from `.aid/knowledge/STATE.md ->
  ## Discovery Domain`, and per-section attributes from doc frontmatter
  (`kb-category`/`objective`/`summary`/`audience`/`tags`). *(FR-45)*
- [ ] The manifest specifies **one section per resolved doc / `kb-category`**, a deterministic
  section-ordering rule, and how `domain` informs framing/labels (not a fixed software gallery).
  *(FR-45)*
- [ ] The manifest specifies the **`kb-category` -> content-component map** (glossary/definition,
  decision/ADR card, capability entry) **and the generic table/card/prose fallback** for any
  resolved doc lacking a bespoke component (completeness = coverage). *(FR-45, FR-46)*
- [ ] The manifest specifies the **derived `noscript` doc list** (enumerated from the resolved
  doc-set at generation time) and the **newcomer-framed "At a Glance"** inputs (no software-metric
  lead). *(FR-45, FR-48)*
- [ ] The manifest **enumerates the retirements** (profile-as-project-type, phantom
  `repo-presentation.md`, hardcoded `noscript`/seed-doc lists) with the file/anchor each lives in
  today, so task-065 has an exhaustive change list. *(FR-45)*
- [ ] The contract honours guardrails C1/C2/C3/C5/C6 + §5b (the manifest does not require any new
  output path, split asset, CDN, or shell change) and is consistent with the §0 two-audience
  reframing.
- [ ] All section-6 quality gates pass.
