# Domain-driven `kb.html` summary redesign (two-audience, visual-rich; Mermaid-free at the D-012 end-state)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-25 | Feature authored to realign `/aid-summarize` with the post-feature-014 domain-driven KB and to **reframe `kb.html` as a distinct product for a non-technical newcomer** (visually rich; the KB's no-diagrams rule does NOT apply to the summary). Closes the gap left when feature-014 generalized discovery but never updated the renderer (it still selects a software project-TYPE profile, covers 0 of 7 custom docs, cites a phantom `repo-presentation.md`, hardcodes a stale `noscript` doc list, and caps the grade at C+ unless N Mermaid diagrams exist). Seven changes across input/content/grade/UX/engineering, split into two deliveries: **D-011 correctness-core** then **D-012 visual & engineering** (SVG pre-render + drop the 3MB Mermaid engine + a NEW §7 visual-fidelity gate). Grounded in a 5-agent analysis (2026-06-25) + user design considerations. | user decision |

## Source

- REQUIREMENTS.md §5.K (FR-45–FR-51, NEW)
- REQUIREMENTS.md §5.J (FR-37–FR-44 — the domain-driven KB this renderer must now consume), §1.2 (KB value = the *delta* from what a generalist knows), §1.3 (the universal newcomer concerns — the spine the summary covers per doc)
- **Design seed (authoritative):** `.aid/design/aid-summarize-redesign.md` — the two-audience reframing, the 3-axis diagnosis, the keep-list, the §5 dashboard-self-containment + page-shell guardrails, the 7-change plan, the §7 visual-fidelity gate, and the locked decisions.
- **Extends / consumes:** feature-014 (`discovery.doc_set`, the generic-core spine + `kb-category` frontmatter, `decisions.md`, the seven custom docs) — the summary becomes a *reader* of f014's output. Reuses f003's doc model and the f001 `sources:`/`approved_at_commit:` freshness signals the dashboard already surfaces.
- **Evidence:** the 5 analyst reports' load-bearing anchors (seed §10) — `state-profile.md` seed-doc grep, the 7 software `section-templates/*` (0 custom docs), `agentic-pipeline.md` phantom `repo-presentation.md`, `grading-rubric.md` diagram-cap vs the KB no-diagrams rule, `grade-summary.sh` C+ cap, the 3.31MB Mermaid engine for 5 static diagrams, the dashboard self-containment contract (`server.mjs`/`server.py`/`parsers.py`/`home.html`).

## Description

`/aid-discover` was generalized by feature-014 into a **domain-driven** KB: the doc-set is
derived per domain (variable docs, not a fixed 15-doc software taxonomy), seven custom docs
were introduced (`process-architecture`, `workflow-map`, `authoring-conventions`,
`artifact-schemas`, `quality-gates`, `capability-inventory`, `decisions`), and an authoring
standard made each KB doc small, single-concern, dual-audience (humans + AI agents), and
**diagram-free**. `/aid-summarize` — the skill that renders the KB into `.aid/dashboard/kb.html`
— was **never updated**. It is still bound to the OLD model: it picks a software project-TYPE
profile (web-app / cli / library / microservices / data-pipeline / agentic-pipeline /
auto-detect), renders hardcoded software-seed sections, covers **zero** of the seven custom
docs, cites a **phantom `repo-presentation.md`**, hardcodes a **stale `noscript` doc list**,
and **caps the grade at C+** unless a fixed number of Mermaid diagrams are present. It produces
a wrong, stale, mis-graded summary of the new KB.

feature-015 realigns the renderer around a **foundational reframing: `kb.html` is a different
product from the KB.**

| Artifact | Audience | Consequence |
|---|---|---|
| **KB docs** (`.aid/knowledge/*.md`) | Technical — humans **+ AI agents** (dual-audience) | The "no diagrams; tables/bullets" authoring rule (FR-43) lives HERE. |
| **`kb.html` summary** | **Non-technical human, little/no prior project knowledge** | Easy to read, **visually rich**. The no-diagram rule does NOT apply; more newcomer-friendly concept infographics is better. |

The summary must stop importing the KB's authoring rules. Its **completeness standard** is that
ALL project-relevant information is represented, but the **format of each piece is chosen to fit
that piece** (diagram, infographic, table, card, pill, or prose — whichever best communicates it
to a newcomer). Completeness is about *coverage*, not a fixed section list or a diagram count.

The redesign is **information architecture + content components + generation** — it deliberately
**keeps** the production-grade visual language (design tokens, light/dark theming sharing
`aid-dashboard-theme`, the focus-trapped lightbox, the a11y baseline, responsive layout,
single-file self-containment) and the **outer page shell** (top bar, side panel, search, nav
chrome) that was built to stay **consistent with `home.html` and the CLI `index.html`** for
seamless dashboard navigation. The freedom is in the **inner content area**.

The work is split into two deliveries with a shippable midpoint:

- **D-011 — correctness core:** the summary becomes RIGHT and complete for the new KB —
  doc-set/domain-driven sections (one section per resolved doc / `kb-category`), concept-first
  content components (glossary, ADR/decision card, capability entry) that render the Concept
  Spine and `decisions.md` as CONTENT instead of links, a grade that rewards
  best-format-per-fact + completeness (the diagram-count cap removed), a non-technical newcomer
  tone, and shell-consistency with `home.html`/`index.html`.
- **D-012 — visual & engineering:** rich + cheap + reproducible — data-driven deterministic
  generation from the resolved doc-set (not freehand-LLM HTML), pre-render visuals to inline
  SVG / HTML+CSS at build time and **drop the ~3MB runtime Mermaid engine** (page 3.4MB → tens
  of KB), and a **NEW §7 visual-fidelity gate** that holds every authored visual to the
  readable-text / minimal-overlap / correct-basic-layout bar Mermaid used to guarantee for free.

Server-side gzip/cache of the dashboard leaf is the **highest-ROI perf fix but a different
component** (the server, not the skill) and is logged as an explicit **fast-follow, OUT of this
work.**

## User Stories

- As a **non-technical newcomer to a project** (e.g. a new teammate, a stakeholder, a manager),
  I want `kb.html` to explain — visually and in plain language — *what this project is, what it
  does, what it is made of, and the key decisions and vocabulary* so I can understand the
  project without reading code or technical KB docs.
- As a **newcomer**, I want the concepts and decisions that define the project (its glossary
  terms, its ADRs) shown as **rendered, friendly content** — cards, infographics, definitions —
  not as bare links to technical Markdown I would have to open and decode.
- As an **AID adopter on a non-software (or hybrid) project**, I want the summary to describe
  the documents *my* domain actually produced (driven by `discovery.doc_set`), not a software
  architecture gallery that omits my custom docs and cites a document that does not exist.
- As an **AID maintainer**, I want the summary **generated data-drivenly and deterministically**
  from the resolved doc-set — reproducible and auditable — rather than hand-written HTML, and I
  want every authored visual **automatically validated** for readable text, minimal overlap, and
  a correct basic layout so dropping Mermaid does not silently ship broken infographics.
- As an **AID maintainer**, I want the dashboard self-containment contract (single file at
  `.aid/dashboard/kb.html`, no CDN/split assets, the `## Knowledge Summary Status` approval
  signal, the `README.md ## Completeness` + `kb_baseline:` shapes) and the page-shell
  consistency with `home.html`/`index.html` **preserved**, so the redesign does not break the
  dashboard or its navigation.

## Priority

Must

## Acceptance Criteria

- [ ] **(Change 1 — doc-set/domain-driven input)** Given a KB produced by feature-014, when
  `/aid-summarize` runs, then it **reads the doc-set from `.aid/settings.yml → discovery.doc_set`
  and the domain from `.aid/knowledge/STATE.md → ## Discovery Domain`** and renders **one section
  per resolved doc / `kb-category`** (derived
  from each doc's frontmatter), retiring profile-as-project-type; the phantom
  `repo-presentation.md` reference is removed and the `noscript` doc list is **derived from the
  resolved doc-set**, not hardcoded. *(FR-45)*
- [ ] **(Change 2 — concept-first components)** Given a KB with a Concept Spine
  (`domain-glossary.md`) and `decisions.md`, when the summary is generated, then the glossary
  terms, the ADRs/decisions, and the capability inventory are rendered as **first-class content
  components** (glossary/definition, decision/ADR card, capability entry) — **rendered, not
  linked**. *(FR-46)*
- [ ] **(Change 3 — best-format-per-fact grading)** Given the redesigned rubric, when a summary
  is graded, then the grade rewards **clarity, completeness (coverage of all project-relevant
  information), and visual communication for a newcomer**, with **no diagram-count floor and no
  diagram-count ceiling**; the previous C+-unless-N-diagrams cap is removed and the KB
  no-diagrams rule is **not** applied to the summary. *(FR-47)*
- [ ] **(Change 4 — newcomer tone)** Given a generated summary, when its prose is read, then it
  targets a **non-technical newcomer** (friendly, accessible, explains the *what* and *why*) and
  **drops the KB's dual-audience / agent-frontmatter framing**; the "At a Glance" no longer
  leads with software metrics. *(FR-48)*
- [ ] **(Change 5 — shell consistency, inner-content freedom)** Given the redesigned summary,
  when its outer shell (top bar, side panel, search, nav chrome) is compared with `home.html`
  and the CLI `index.html`, then the shell is **kept consistent/aligned** with them; only the
  **inner content model + components** are redesigned (the chrome is not reinvented). *(FR-49)*
- [ ] **(Change 6 — data-driven deterministic generation)** Given the resolved doc-set, when the
  summary is built, then generation is **data-driven and deterministic** from that doc-set
  (reproducible + auditable), **not** freehand-LLM HTML. *(FR-50)*
- [ ] **(Change 7 — drop Mermaid, pre-render visuals)** Given the redesigned engine, when the
  page is built, then visuals are **pre-rendered to inline SVG / HTML+CSS at build time** and the
  **~3MB runtime Mermaid engine is removed**; the resulting `kb.html` is dramatically smaller
  (target: tens of KB rather than ~3.4MB) and contains no runtime diagram-rendering engine.
  *(FR-51)*
- [ ] **(§7 visual-fidelity gate — NEW)** Given the engine no longer relies on Mermaid's
  automatic layout guarantee, when the VALIDATE state runs, then **every pre-rendered visual is
  validated** by **Playwright render** (preferred) or explicit **visual inspection**, asserting
  **text is readable** (legible size, not clipped), **minimal/zero element overlap**, and a
  **correct basic layout** (non-trivial, not collapsed/empty); a visual that fails the gate is a
  generation defect fixed before DONE — the same rigor as the old "no broken diagram" guarantee.
  This **replaces** Mermaid's D2 render-correctness check (moot once the engine is gone). *(FR-51)*
- [ ] **(Guardrail C1)** The output path is exactly `<repo>/.aid/dashboard/kb.html`.
- [ ] **(Guardrails C2/C3)** `kb.html` remains a **single self-contained file** — all CSS/JS/
  visuals inlined; **no CDN, no split assets, no framework fetch** (the server allowlists only
  `home.html`/`kb.html`, so any sibling sub-resource would 404).
- [ ] **(Guardrail C5)** The approval signal remains `## Knowledge Summary Status` →
  `**User Approved:** yes (YYYY-MM-DD)` in `.aid/knowledge/STATE.md` (the reader flips the KB
  card clickable on this literal).
- [ ] **(Guardrail C6)** The `README.md ## Completeness` rows and the `.aid/settings.yml
  kb_baseline:` shape are preserved (the reader derives `doc_count` / outdated from them).
- [ ] **(Guardrail §5b — page-shell consistency)** The outer page shell stays consistent/aligned
  with `home.html` + CLI `index.html` for seamless dashboard navigation.
- [ ] **(Keep-list intact)** Design-token system, light/dark theming (FOUC-free, shared
  `aid-dashboard-theme`), the focus-trapped lightbox, the a11y baseline (skip-link, landmarks,
  `:focus-visible`, `prefers-reduced-motion`, `forced-colors`, `noscript`), responsive layout,
  and single-file self-containment are **kept** (not rebuilt).
- [ ] **All section-6 quality gates pass:** canonical→render parity (full `run_generator.py`),
  dogfood byte-identity (DBI), ASCII-only + WinPS-5.1 lint for any shipped script, and the
  affected canonical summarize suites re-run green.

---

## Technical Specification

> Design of record for feature-015. Realized across **two deliveries** — delivery-011
> (correctness core) and delivery-012 (visual & engineering), D-012 depending on D-011 — on
> branches `aid/work-001-delivery-011` / `-012`. The summary is a **reader** of feature-014's
> output; it does not re-spec discovery. Canonical edits require regen via the full
> `run_generator.py` + `.claude` dogfood sync + DBI, per the repo's standing build cornerstones.
> **This SPEC is scoping only** — it defines the HOW and the affected files; it does NOT modify
> the skill yet (the deliveries' tasks do).
>
> **Path anchor (DBI safety) — read this before editing any file below.** The affected-file
> lists in the per-change sections use **skill-relative shorthand**; the real, editable sources
> live under `canonical/` and are **rendered** into `.claude/` (which is generated — never edit it
> directly, or DBI breaks). Resolve every shorthand path to its canonical anchor:
> - `references/<x>.md` → `canonical/skills/aid-summarize/references/<x>.md`
> - `templates/knowledge-summary/<x>` → `canonical/aid/templates/knowledge-summary/<x>`
> - `scripts/summarize/<x>` → `canonical/aid/scripts/summarize/<x>`
> - `SKILL.md` → `canonical/skills/aid-summarize/SKILL.md`
>
> DETAIL/EXECUTE edit the `canonical/aid/...` (and `canonical/skills/aid-summarize/...`) source,
> then regen via the full `run_generator.py` — never the rendered `.claude/` copy.

### 0. The reframing that drives everything (the one rule)

`kb.html` and the KB are **two products for two audiences**. The KB's authoring rules
(single-concern, tables/bullets, **no diagrams**) are correct **for the KB** and must be
**stopped from leaking into the summary**. The summary's job is to make a **non-technical
newcomer** understand the project, using **whatever format best communicates each fact** —
diagrams included. Every change below is an application of this rule; the guardrails (§5)
constrain *how* it is realized so the dashboard keeps working.

### 1. Input model — doc-set + domain driven (Change 1, D-011) — FR-45

**Today (the defect):** `state-profile.md` greps the KB for a fixed software-seed doc list and
selects a project-TYPE profile (`section-templates/{web-app,cli,library,microservices,
data-pipeline,agentic-pipeline,auto-detect}.md`); the section set is hardcoded software; the
`noscript` fallback hardcodes the old doc list; `agentic-pipeline.md` cites a **phantom
`repo-presentation.md`**.

**Redesign:**
- **`references/state-profile.md` → doc-set-driven.** Replace project-TYPE selection with a
  read of the doc-set from `.aid/settings.yml → discovery.doc_set` and the domain from
  `.aid/knowledge/STATE.md → ## Discovery Domain` (both feature-014 outputs; note the **doc-set
  lives in `settings.yml` and the domain in `knowledge/STATE.md`** — distinct files). The
  resolved doc-set + each doc's frontmatter (`kb-category`,
  `objective`, `summary`, `audience`, `tags`) becomes the **section manifest**: one summary
  section per resolved doc / `kb-category`. Domain informs framing/labels, not a fixed gallery.
- **Section derivation is from frontmatter**, not from `section-templates/{type}.md`. The seven
  software `section-templates/*` are **retired as project-type profiles** and (where any are
  kept) recast as **rendering hints keyed by `kb-category`/spine-dimension**, not by
  project-type. The **phantom `repo-presentation.md`** reference is removed wherever it appears
  (the `agentic-pipeline.md` template + any prose).
- **`noscript` doc list is derived** from the resolved doc-set at generation time (no hardcoded
  doc list survives in the template/skeleton).
- **"At a Glance"** is rebuilt to lead with newcomer-relevant framing (what the project is / does)
  rather than software metrics (Change 4 below shares this).

**Affected files:** `references/state-profile.md` (→ doc-set/domain read),
`references/state-generate.md` (section manifest from frontmatter),
`templates/knowledge-summary/section-templates/*` (retire project-type profiles; remove phantom
doc; recast as category hints), `templates/knowledge-summary/html-skeleton.html` (derived
`noscript`), `SKILL.md` (state-flow prose).

### 2. Concept-first content components (Change 2, D-011) — FR-46

**Today (the defect):** the Concept Spine (`domain-glossary.md`, ~29 terms) and `decisions.md`
(the ADRs — the *why*) are **linked, never rendered**; only dashboard/metric cards exist.

**Redesign — three new content components**, rendering the Concept Spine and `decisions.md` as
CONTENT (a newcomer never has to open a `.md`):
- **Glossary / definition component** — renders `domain-glossary.md` terms as friendly
  definitions/pills/cards (the project's vocabulary, explained).
- **Decision / ADR card** — renders each `decisions.md` ADR (context → decision → rationale →
  consequence) as a newcomer-readable card (the *why* behind the project).
- **Capability entry** — renders `capability-inventory.md` (what the project can do, per
  capability).

These are **inner-content components** (per §5b the shell is untouched). They are added to the
component library (`templates/knowledge-summary/component-css.css` + the generation templates),
keyed by the source doc's `kb-category`. Where a resolved doc has no bespoke component, a
generic table/card/prose rendering covers it (completeness = coverage, §0).

**Affected files:** `templates/knowledge-summary/component-css.css` (new component styles),
`templates/knowledge-summary/section-templates/*` (category→component mapping),
`references/state-generate.md` (render glossary/decisions/capability as content),
`templates/knowledge-summary/prompt.md` (instruct concept-first rendering).

### 3. Grading — best-format-per-fact + completeness (Change 3, D-011) — FR-47

**Today (the defect):** `grading-rubric.md` rewards a fixed diagram count; `grade-summary.sh`
**caps at C+** unless N diagrams exist (a quantity proxy for quality) and conflicts with the KB
no-diagrams rule by importing it into the summary's grade.

**Redesign:**
- **Remove the diagram-count gate** entirely — **no floor and no ceiling** on diagrams.
- The rubric rewards **clarity, completeness (all project-relevant information represented), and
  visual communication for a newcomer**, with the **format chosen per fact** (the §0 standard).
  Completeness is measured against the **resolved doc-set coverage** (every resolved doc / spine
  dimension is represented in the summary), not a fixed section list.
- The **KB no-diagrams rule is explicitly NOT applied** to the summary grade.
- `grade-summary.sh` is reworked to compute the new rubric; the C+ cap line is deleted.

**Affected files:** `templates/knowledge-summary/grading-rubric.md` (rewrite dimensions; drop
diagram cap), `scripts/summarize/grade-summary.sh` (remove the C+/diagram-count gate; implement
coverage-based completeness scoring).

### 4. Tone — non-technical newcomer (Change 4, D-011) — FR-48

**Today (the defect):** prose imports the KB's dual-audience / agent-frontmatter framing and
"At a Glance" leads with software metrics.

**Redesign:** the generation prompt + section templates target a **non-technical newcomer** —
friendly, plain-language, explains the *what* and *why* accessibly; the KB's agent-oriented
framing (frontmatter talk, tier/audience machine-consumption language) is dropped from the
summary; "At a Glance" leads with newcomer framing. (Tone is a judgment surface; the rubric §3
anchors it with a clarity/accessibility dimension.)

**Affected files:** `templates/knowledge-summary/prompt.md`, the kept
`section-templates/*` (tone of headings/labels), `references/state-generate.md` (tone guidance).

### 5. Shell consistency, inner-content freedom (Change 5, D-011) — FR-49

**Guardrail §5b is the contract here.** The OUTER shell — top bar, side panel, search, nav
chrome — was deliberately built to be **consistent with `home.html` and the CLI `index.html`**
for seamless dashboard navigation. The redesign **keeps/aligns** the shell with them and
**redesigns only the inner content area** (illustrations, graphics, tables, pills, cards,
diagrams). `html-skeleton.html`'s shell structure is preserved/aligned; the content region is
where Changes 1–4 (and 6–7) act. No chrome is reinvented.

**Affected files:** `templates/knowledge-summary/html-skeleton.html` (shell kept/aligned; only
the content region changes), cross-checked against `home.html` + CLI `index.html`.

### 6. Data-driven deterministic generation (Change 6, D-012) — FR-50

**Today (the defect):** the build is **prompt-driven** (the LLM hand-writes the HTML) → not
reproducible/auditable; 96% of the payload is the Mermaid engine.

**Redesign:** generation becomes **data-driven and deterministic** — the resolved doc-set +
frontmatter + component library are assembled by a generator (extending/replacing the
`scripts/summarize/assemble*.sh` path) into the single-file output. The LLM's role narrows to
authoring the **content of each component from the KB doc** (still judgment), while **assembly,
section ordering, shell, and inlining are mechanical and reproducible**. Same input → same
structural output (auditable).

**Affected files:** `references/state-generate.md` (data-driven flow),
`scripts/summarize/assemble.sh` + `scripts/summarize/assemble-3part.sh` +
`scripts/summarize/assemble-3part.ps1` (the WinPS twin, mandatory `-Mermaid` param — the sh/ps1
parity cornerstone requires both twins move together) — deterministic assembly from the doc-set
manifest, `templates/knowledge-summary/prompt.md` (narrowed to per-component content authoring).

### 7. Pre-render visuals to inline SVG; drop the Mermaid engine (Change 7, D-012) — FR-51

**Today (the defect):** 3.31MB of a 3.43MB page is the **Mermaid engine** for **5 static
diagrams**; `mermaid-init.js` / `fetch-mermaid.sh` / `mermaid-examples.md` exist solely to feed
it; the engine fails silently on bad syntax.

**Redesign:**
- **Pre-render every visual to inline SVG / HTML+CSS at build time.** Static visuals do not need
  a runtime engine. This makes many rich infographics **cheap** (page 3.4MB → tens of KB) and
  removes Mermaid's silent-failure class.
- **DROP the ~3MB runtime Mermaid engine.** `fetch-mermaid.sh`, `mermaid-init.js`, and the
  Mermaid loading/embedding in `html-skeleton.html` are removed; `mermaid-examples.md` is
  retired or recast as an **authored-visual catalog** (SVG/HTML+CSS patterns).
- The page remains **single-file self-contained** (C2/C3): SVG is inlined, no CDN, no engine.

**Affected files:** `scripts/summarize/fetch-mermaid.sh` (remove),
`scripts/summarize/assemble-3part.ps1` (the WinPS twin embeds the Mermaid engine via its
mandatory `-Mermaid` param — drop the embed here too; sh/ps1 parity cornerstone requires both
twins move together),
`templates/knowledge-summary/mermaid-init.js` (remove),
`templates/knowledge-summary/mermaid-examples.md` (retire/recast),
`templates/knowledge-summary/html-skeleton.html` (remove Mermaid embed; inline SVG),
`references/state-generate.md` (pre-render visuals step).

### 8. The §7 visual-fidelity gate (D-012) — FR-51, the cost of dropping Mermaid

Mermaid **automatically guaranteed** a basic correct layout (readable text, minimal overlap,
sane spacing). Hand-authored SVG/HTML infographics **lose that automatic safety net**, so the
redesigned **VALIDATE** state MUST add a **visual-fidelity gate** holding every authored visual
to the same bar:

- **Every pre-rendered visual is validated** by **Playwright render** (preferred, automatable)
  or explicit **visual inspection**.
- The gate asserts, per visual: **text is readable** (legible size, not clipped), **minimal/zero
  element overlap**, and a **correct basic layout** (non-trivial — not collapsed/empty).
- This **replaces** Mermaid's D2 render-correctness check (moot once the engine is gone) with a
  fidelity check appropriate to authored visuals. A visual that fails the gate is a **generation
  defect, fixed before DONE** — same rigor as the old D1/D2 "no broken diagram" guarantee.
- Per the global project rule, **any review of rendered web output uses Playwright visual
  validation** — reading the HTML/CSS source is not sufficient.

**Affected files:** `scripts/summarize/validate-diagrams.mjs` **→ replaced by a new
`validate-visuals.mjs`**. Note this is **not a simple rename**: the current
`validate-diagrams.mjs` renders via **JSDOM** (a non-browser DOM), whereas the §7 gate requires a
**Playwright headless-browser render** of every authored visual — a **new browser-render
dependency** the DETAIL phase must provision and CI must support. The new validator asserts
readable-text / minimal-overlap / correct-basic-layout; the old Mermaid-D2 syntax check is
removed.
`references/state-validate.md` (the visual-fidelity gate replaces the diagram-render check),
`SKILL.md` (VALIDATE-state prose), `scripts/summarize/validate-html-output.sh` (keep
self-containment + a11y checks; add the no-Mermaid-engine assertion).

### 9. Hard constraints (guardrails — must not break) — §5/§5b

Stated explicitly so every task carries them:

- **C1** — output path is exactly `<repo>/.aid/dashboard/kb.html`.
- **C2/C3** — `kb.html` is a **single self-contained file**; all CSS/JS/visuals inlined; **no
  CDN, no split assets, no framework fetch** (the server allowlists only `home.html`/`kb.html`,
  so any sibling sub-resource 404s). Dropping Mermaid (§7) must not introduce any external fetch.
- **C5** — the approval signal stays `## Knowledge Summary Status` →
  `**User Approved:** yes (YYYY-MM-DD)` in `.aid/knowledge/STATE.md` (the reader flips the KB
  card clickable on this literal). `references/state-approval.md` + `writeback-state.sh` keep it.
- **C6** — keep the `README.md ## Completeness` rows + the `.aid/settings.yml kb_baseline:`
  shape (the reader derives `doc_count` / outdated from them). `stale-check.sh` /
  `state-stale-check.md` keep emitting them.
- **§5b page-shell consistency** — the outer shell stays consistent/aligned with `home.html` +
  CLI `index.html`; only the inner content area is redesigned.

These are **gate criteria in both deliveries** (D-011 and D-012). The keep-list (design tokens,
theming, lightbox, a11y baseline, responsive layout) is preserved — the redesign is information
architecture + content components + generation, NOT visual language.

### 10. Delivery boundary (what lands where)

- **D-011 (correctness core)** — Changes **1–5**: doc-set/domain-driven section derivation
  (Change 1, FR-45); concept/decision/capability content components (Change 2, FR-46);
  best-format-per-fact + completeness grading with the diagram-count cap removed (Change 3,
  FR-47); newcomer tone (Change 4, FR-48); shell-consistency with home/index + inner-content
  freedom (Change 5, FR-49). `state-profile.md`→doc-set-driven, `state-generate.md`, the
  templates, `grading-rubric.md`, `grade-summary.sh` updated. **Shippable midpoint:** a correct,
  complete, shell-consistent summary of the new KB — still Mermaid-backed for any diagrams.
- **D-012 (visual & engineering)** — Changes **6–7** + the **§7 gate**: data-driven
  deterministic generation (Change 6, FR-50); pre-render visuals to inline SVG, drop the 3MB
  Mermaid engine (Change 7, FR-51); the visual-fidelity gate. `validate-diagrams.mjs` →
  `validate-visuals.mjs`; `state-generate.md` / `state-validate.md` reworked; Mermaid assets
  removed. **Depends on D-011.**

### 11. Scope boundaries

**In scope (this feature):** Changes 1–7 + the §7 visual-fidelity gate, across D-011/D-012,
within the guardrails §5/§5b and on the keep-list §4.

**Out of scope (fast-follow, logged separately):** **server-side gzip/cache** of the dashboard
leaf (`dashboard/server/server.mjs` + `server.py` byte-parity twins) — the highest-ROI perf fix
but a **different component** (the server, not the skill).

**Won't (this work):** any change to feature-014's discovery/doc-set machinery (the summary is a
*reader* of it); any change to the dashboard server allowlist or the reader's approval/
completeness parsing (guardrails C2/C5/C6 keep those contracts intact).

### 12. Engineering constraints (reused)

- Any shipped script ASCII-only + WinPS-5.1-safe; deterministic where mechanical (assembly,
  inlining, validation harness) and judgment only where irreducible (per-component content
  authoring, tone, the visual-inspection fallback).
- Canonical edits → full `run_generator.py` regen → `.claude` dogfood sync → DBI green
  (per the standing build cornerstones).
- The §7 visual-fidelity gate prefers **Playwright** (automatable in CI) with explicit
  **visual inspection** as the documented fallback.
- **Grade gate:** **A+**, set via the `summary.minimum_grade` override in `.aid/settings.yml`
  (the global `review.minimum_grade` default stays **A**). Both deliveries gate at A+.
