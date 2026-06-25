# Delivery SPEC -- delivery-012: Summary Visual & Engineering (SVG pre-render + drop Mermaid + fidelity gate)

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-012/STATE.md.

> **Delivery:** delivery-012
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-25

---

## Objective

Make the redesigned `kb.html` summary **rich, cheap, and reproducible** by re-architecting its
generation engine. This delivery realizes feature-015 **Changes 6-7 + the §7 visual-fidelity
gate** (FR-50–FR-51): data-driven deterministic generation from the resolved doc-set (replacing
freehand-LLM HTML), pre-rendering visuals to inline SVG / HTML+CSS at build time while **dropping
the ~3MB runtime Mermaid engine** (page 3.4MB → tens of KB, removing the silent-failure class),
and a **NEW visual-fidelity gate** that holds every authored visual to the readable-text /
minimal-overlap / correct-basic-layout bar Mermaid used to guarantee for free. It builds on the
delivery-011 correctness core.

## Scope

In scope (feature-015 Changes 6-7 + §7 gate):

- **Data-driven deterministic generation (Change 6, FR-50)** — assemble the single-file output
  from the resolved doc-set + frontmatter + component library deterministically (extend/replace
  `scripts/summarize/assemble.sh` + `assemble-3part.sh` **and its WinPS twin
  `assemble-3part.ps1`** — the sh/ps1 parity cornerstone requires both move together); narrow the
  LLM to per-component content
  authoring; same input → same structural output (reproducible + auditable). `state-generate.md`
  reworked.
- **Pre-render visuals; drop the Mermaid engine (Change 7, FR-51)** — pre-render every visual to
  **inline SVG / HTML+CSS at build time**; **remove the ~3MB runtime Mermaid engine**
  (`fetch-mermaid.sh` removed, `mermaid-init.js` removed, the Mermaid embed dropped from
  `html-skeleton.html` **and from the WinPS twin `assemble-3part.ps1`'s `-Mermaid` path**,
  `mermaid-examples.md` retired/recast as an authored-visual catalog); the
  page stays **single-file self-contained** (C2/C3 — no CDN/engine).
- **§7 visual-fidelity gate (FR-51)** — replace `validate-diagrams.mjs` (today **JSDOM**-based)
  with a new **`validate-visuals.mjs`** that **Playwright-renders** every authored visual — a
  **new headless-browser-render dependency** (to provision in DETAIL + support in CI), not a
  simple rename — or explicit visual inspection,
  asserting **readable text** (legible, not clipped), **minimal/zero element overlap**, and a
  **correct basic layout** (non-trivial, not collapsed/empty); a failing visual is a generation
  defect fixed before DONE. This **replaces** Mermaid's D2 render-correctness check.
  `state-validate.md` reworked; `validate-html-output.sh` gains a no-Mermaid-engine assertion.

**Out of scope:** Changes 1-5 (delivery-011 — the correctness core this delivery depends on); any
change to feature-014's discovery/doc-set machinery; **server-side gzip/cache** of the dashboard
leaf (`dashboard/server/server.mjs` + `server.py`) — the highest-ROI perf fix but a different
component (the server, not the skill), logged as a fast-follow OUT of this work.

## Gate Criteria

- [ ] Summary generation is **data-driven and deterministic** from the resolved doc-set
  (reproducible + auditable); the LLM's role is narrowed to per-component content authoring;
  assembly / ordering / shell / inlining are mechanical. *(FR-50)*
- [ ] Visuals are **pre-rendered to inline SVG / HTML+CSS at build time**; the **~3MB runtime
  Mermaid engine is removed** (`fetch-mermaid.sh` / `mermaid-init.js` gone; `html-skeleton.html`
  carries no Mermaid embed; `mermaid-examples.md` retired/recast); the resulting `kb.html` is
  dramatically smaller (target: tens of KB rather than ~3.4MB) and contains no runtime diagram
  engine. *(FR-51)*
- [ ] The **visual-fidelity gate** runs in the VALIDATE state: **every** pre-rendered visual is
  validated by **Playwright render** (preferred) or explicit visual inspection, asserting
  **readable text + minimal/zero overlap + correct basic layout**; a failing visual blocks DONE.
  The gate **replaces** Mermaid's render-correctness check; the JSDOM-based
  `validate-diagrams.mjs` is replaced by a new Playwright-based `validate-visuals.mjs` (a new
  browser-render dependency, not a rename). *(FR-51, §7)*
- [ ] **Guardrails hold:** C1 (path `<repo>/.aid/dashboard/kb.html`), C2/C3 (single
  self-contained file, no CDN/split assets — dropping Mermaid introduces **no** external fetch),
  C5 (`## Knowledge Summary Status` → `**User Approved:** yes (YYYY-MM-DD)`), C6 (`README.md
  ## Completeness` rows + `kb_baseline:` shape), and §5b page-shell consistency with `home.html`
  + the CLI `index.html`. The keep-list (design tokens, theming, lightbox, a11y baseline,
  responsive layout) is preserved.
- [ ] **Delivery grade gate = A+** (this work's quality bar, above the default A minimum).
- [ ] All section-6 quality gates pass: canonical→render parity (full `run_generator.py`),
  dogfood byte-identity (DBI), ASCII-only + WinPS-5.1 lint for any shipped script, and the
  affected canonical summarize suites re-run green.

## Tasks

> Authored by `/aid-detail`. Each task has a full SPEC + STATE at `tasks/task-NNN/`. The
> `Depends on` ordering and waves are in PLAN.md `### delivery-012 execution graph`.

| Task | Type | Title |
|------|------|-------|
| task-071 | IMPLEMENT | Data-driven deterministic assembly (assemble.sh / assemble-3part.sh + WinPS twin) (Change 6) |
| task-072 | IMPLEMENT | Pre-render visuals to inline SVG; drop the ~3MB Mermaid engine (Change 7) |
| task-073 | CONFIGURE | Provision the Playwright browser-render dependency (+ CI support) for the visual-fidelity gate |
| task-074 | IMPLEMENT | §7 visual-fidelity gate — validate-visuals.mjs (Playwright) + state-validate rework + no-engine assertion |
| task-075 | TEST | Visual-fidelity fixtures + payload-size regression + guardrail re-checks |
| task-076 | DOCUMENT | Regen + .claude DBI sync + SKILL/README docs + log the server-gzip fast-follow |

## Dependencies

- **Depends on:** delivery-011 (the summary correctness core — the engine re-architecture and the
  visual-fidelity gate build on a correct, complete, shell-consistent summary)
- **Blocks:** -- (none)

## Notes

- **The cost of dropping Mermaid:** Mermaid automatically guaranteed a basic correct layout
  (readable text, minimal overlap, sane spacing). Hand-authored SVG/HTML infographics lose that
  safety net, so the §7 visual-fidelity gate is **load-bearing** — it is the authored-visual
  replacement for Mermaid's free guarantee, with the same rigor as the old "no broken diagram"
  bar. Per the global project rule, any review of rendered web output uses **Playwright visual
  validation** — reading HTML/CSS source is not sufficient.
- **Self-containment is non-negotiable:** the server allowlists only `home.html`/`kb.html`, so
  inlined SVG with no CDN/engine is mandatory (C2/C3); the Mermaid drop must not add any external
  fetch.
- **Fast-follow (OUT):** server-side gzip/cache of the dashboard leaf is the highest-ROI perf fix
  but a different component (the server) — logged separately, not in this delivery.
- **Design rationale** lives in
  `.aid/work-001-kb-skills-improvement/features/feature-015-summarize-domain-driven-redesign/SPEC.md`
  §Technical Specification (§6, §7, §8) and the design seed `.aid/design/aid-summarize-redesign.md`
  (§7).
- Affected files: `scripts/summarize/assemble.sh`, `scripts/summarize/assemble-3part.sh`,
  `scripts/summarize/assemble-3part.ps1` (WinPS twin, mandatory `-Mermaid` param — sh/ps1 parity),
  `scripts/summarize/fetch-mermaid.sh` (remove), `scripts/summarize/validate-diagrams.mjs` →
  `validate-visuals.mjs`, `scripts/summarize/validate-html-output.sh`,
  `templates/knowledge-summary/mermaid-init.js` (remove),
  `templates/knowledge-summary/mermaid-examples.md` (retire/recast),
  `templates/knowledge-summary/html-skeleton.html`, `references/state-generate.md`,
  `references/state-validate.md`, `SKILL.md`.
