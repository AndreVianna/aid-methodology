# Design seed — aid-summarize domain-driven redesign (work-001 / feature-015)

> **Status:** scoping input (authoritative). Feeds feature-015/SPEC.md + delivery-011/012 + task breakdown.
> **Source:** 5-agent analysis of `/aid-summarize` (2026-06-25) + user design considerations.
> **Continuation of:** work-001-kb-skills-improvement (follows feature-014 domain-driven discovery).

## 1. Why this work exists

`/aid-discover` was generalized (feature-014) to produce a **domain-driven, flexible KB**:
a per-domain doc-set (variable docs), custom docs (`process-architecture`, `workflow-map`,
`authoring-conventions`, `artifact-schemas`, `quality-gates`, `capability-inventory`,
`decisions`), and a concept-explanatory authoring standard. `/aid-summarize` — which renders
the KB into `kb.html` — was **never updated** and is still bound to the OLD model (fixed 15-doc
software seed, project-type profiles, fixed ~8-Mermaid-diagram gallery). It produces a wrong,
stale, mis-graded summary of the new KB. This work realigns it.

## 2. Foundational reframing — TWO audiences (do not conflate)

| Artifact | Audience | Consequence |
|---|---|---|
| **KB docs** (`.aid/knowledge/*.md`) | Technical — humans **+ AI agents** (dual-audience) | The "no diagrams; tables/bullets" authoring rule lives HERE. |
| **`kb.html` summary** | **Non-technical human, little/no prior project knowledge** | Easy to read, **visually rich**. The no-diagram rule does NOT apply. More user-friendly concept infographics = better. |

**The summary is a different product from the KB.** aid-summarize must stop importing the KB's
authoring rules into the summary.

**Completeness standard (summary):** ALL project-relevant information must be represented — but
the **format of each piece is chosen to fit that piece** (diagram, infographic, table, card,
pill, or prose — whichever best communicates it to a newcomer). Completeness is about *coverage*,
not about a fixed section list or diagram count.

## 3. Diagnosis — three axes where the skill is bound to the old model (all 5 analysts converged)

1. **Input model is domain-blind.** Never reads `discovery.doc_set` or `## Discovery Domain`;
   selects a project-TYPE profile (web-app/cli/…) and renders hardcoded software-seed sections.
   → covers **0 of 7 custom docs**, cites a **phantom `repo-presentation.md`**, hardcodes a stale
   `noscript` doc list, "At a Glance" leads with software metrics.
2. **Content model "visualizes structure," not "explains concepts."** The Concept Spine
   (`domain-glossary.md`, 29 terms) and `decisions.md` (8 ADRs — the *why*) are **linked, never
   rendered**. No glossary/decision/capability components exist — only dashboard/metric cards.
3. **Form fights its own purpose / mis-grades.** 96% of the 3.4MB payload is the Mermaid *engine*
   for 5 static diagrams; the grade **caps at C+ unless N diagrams exist** (a quantity proxy for
   quality). Build is **prompt-driven (LLM hand-writes HTML), not data-driven** → not reproducible.

## 4. Keep verbatim (production-grade — do NOT rebuild)

Design-token system; light/dark theming (FOUC-free, shares `aid-dashboard-theme` with the
dashboard); the **lightbox** (focus-trap, zoom/pan, a11y); the a11y baseline (skip-link,
landmarks, `:focus-visible`, `prefers-reduced-motion`, `forced-colors`, `noscript`); responsive
layout; single-file self-containment. The redesign is **information architecture + content
components + generation**, NOT visual language.

## 5. Hard constraints (guardrails — must not break)

**5a. Dashboard self-containment contract** (analyst-verified; break any → dashboard breaks):
- **C1** Output path is exactly `<repo>/.aid/dashboard/kb.html`.
- **C2/C3** `kb.html` is a **single self-contained file** — all CSS/JS/visuals inlined. The server
  allowlists only `home.html`/`kb.html`, so any sibling sub-resource 404s. **No CDN, no split
  assets, no framework fetch.**
- **C5** Approval signal stays `## Knowledge Summary Status` → `**User Approved:** yes (YYYY-MM-DD)`
  in `.aid/knowledge/STATE.md` (the reader flips the KB card clickable on this literal).
- **C6** Keep `README.md ## Completeness` rows + `.aid/settings.yml kb_baseline:` shape (reader
  derives doc_count / outdated from them).

**5b. Page-shell consistency (user requirement).** The OUTER page structure — top bar, side
panel, search, nav chrome — was deliberately built to be **consistent with `home.html` and the
AID CLI `index.html`** for seamless dashboard navigation. **Keep/align the shell with them.** The
freedom is in the **inner content area** (illustrations, graphics, tables, pills, cards,
diagrams), defined by the content.

## 6. The change plan (revised for the two-audience model)

| # | Change | Layer | Delivery |
|---|--------|-------|----------|
| 1 | **Drive sections from `discovery.doc_set` + domain** — one section per doc/`kb-category`, derived from frontmatter; retire profile-as-project-type; fix the phantom-doc + stale `noscript`. | input | D-011 |
| 2 | **Concept-first content components** — glossary/definition, decision/ADR card, capability entry — render the Concept Spine + `decisions.md` as CONTENT, not links. | content | D-011 |
| 3 | **Replace the diagram-COUNT gate** with a **"best-format-per-fact + completeness"** standard. NOT a diagram floor and NOT a ceiling — grade rewards clarity, completeness, and visual communication for a newcomer. The no-diagrams KB rule does not apply to the summary. | grade | D-011 |
| 4 | **Tone = non-technical newcomer**, friendly + visual. Explain concepts (the *what* and *why*) accessibly. Drop the KB's dual-audience / agent-frontmatter framing from the summary. | content | D-011 |
| 5 | **Shell stays consistent with `home.html` + CLI `index.html`** (do NOT reinvent the chrome). Redesign the **inner content model + components** only. | UX | D-011 |
| 6 | **Data-driven, deterministic generation** from the resolved doc-set (not freehand-LLM HTML) — reproducible + auditable. | engineering | D-012 |
| 7 | **Pre-render visuals to inline SVG / HTML+CSS at build time; DROP the 3MB runtime Mermaid engine** → makes many rich infographics cheap (page 3.4MB → tens of KB) and removes Mermaid's silent-failure class. | engineering/perf | D-012 |

**Fast-follow (OUT of this work — logged separately):** server-side gzip/cache of the dashboard
leaf (`dashboard/server/server.mjs` + `server.py` byte-parity twins) — highest-ROI perf fix but
a different component (the server, not the skill).

## 7. NEW requirement — Visual-fidelity gate (the cost of dropping Mermaid)

Mermaid **automatically guarantees** a basic correct layout: readable text, minimal overlap,
sane spacing. Hand-authored SVG/HTML infographics LOSE that automatic safety net. Therefore the
redesigned VALIDATE state MUST include a **visual-fidelity gate** that holds every pre-rendered
visual to the same bar Mermaid gave for free:

- **Every pre-rendered visual is validated** by **Playwright render** (preferred, automatable) or
  explicit **visual inspection**.
- The gate asserts: **text is readable** (legible size, not clipped), **minimal/zero element
  overlap**, and a **correct basic layout** (non-trivial, not collapsed/empty).
- This **replaces** Mermaid's D2 render-correctness check (which is moot once the engine is gone)
  with a fidelity check appropriate to authored visuals.
- A visual that fails the gate is a generation defect, fixed before DONE — same rigor as the old
  D1/D2 "no broken diagram" guarantee.

## 8. Locked decisions

- **Decomposition:** feature-015, **two deliveries** — D-011 *correctness core* then
  D-012 *visual & engineering*. (Shippable midpoint: a correct, complete, shell-consistent
  summary of the new KB before the engine re-architecture.)
- **Scope IN:** SVG pre-render + drop Mermaid engine (D-012) + the §7 visual-fidelity gate.
- **Scope OUT (fast-follow):** server gzip/cache.
- **Grade gate:** **A+**, set via the `summary.minimum_grade` override in `.aid/settings.yml`
  (the global `review.minimum_grade` default stays **A**).
- **Audience:** kb.html = non-technical newcomer (§2). Guardrails §5 hold for both deliveries.

## 9. Delivery shape (high level — detail authored into delivery SPECs/tasks)

**D-011 — Correctness core** (the summary becomes RIGHT & complete for the new KB):
- doc-set/domain-driven section derivation (change 1); concept/decision/capability components
  (change 2); best-format-per-fact + completeness grading, removing the diagram-count cap
  (change 3); newcomer tone (change 4); shell-consistency with home/index, inner-content freedom
  (change 5). Templates/prompt/grading-rubric/state-profile→state-(doc-set) updated.

**D-012 — Visual & engineering** (rich + cheap + reproducible):
- data-driven deterministic generation (change 6); pre-render visuals to inline SVG, drop the 3MB
  Mermaid engine (change 7); the §7 visual-fidelity gate (Playwright/visual). validate-diagrams →
  validate-visuals; state-generate/state-validate reworked.

## 10. Analysis references (the 5 reports' load-bearing anchors)

- **Skill rigidity:** `state-profile.md` (seed-doc grep), `section-templates/*` (6 software
  profiles, 0 custom docs), `agentic-pipeline.md` cites phantom `repo-presentation.md`,
  `grading-rubric.md:108-111` diagram cap vs `authoring-conventions.md:90-91` no-diagrams.
- **Output/tone:** Concept Spine absent; 7 custom docs (esp. `decisions.md`) unrendered; `noscript`
  hardcodes old docs; "At a Glance" software-metric bias.
- **Dashboard:** contract = path + self-contained + approval-signal (`server.mjs:296/700`,
  `parsers.py:341-343`, `home.html:1605`).
- **Web-eng:** 3.31MB/3.43MB is Mermaid engine for 5 diagrams; server uncompressed; prompt-driven
  build; `grade-summary.sh:307` C+ cap.
- **UI/UX:** keep tokens/theming/lightbox/a11y; nav must scale + stay home.html-consistent; add
  concept components; promote tables; demote fixed diagram quota.
