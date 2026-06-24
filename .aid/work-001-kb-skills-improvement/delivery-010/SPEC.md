# Delivery SPEC -- delivery-010: Domain-Driven Discovery (+ dual-audience authoring)

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-010/STATE.md.

> **Delivery:** delivery-010
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-24

---

## Objective

Generalize `/aid-discover` from a fixed software-shaped Knowledge Base to a **domain-aware,
source-first** one that serves **any kind of digital work**, while making every KB document
serve **two audiences at once** (junior humans + AI agents). This delivery realizes
feature-014 (FR-37–FR-44): a domain-agnostic generic-core spine, source-driven domain
classification, a curated domain→doc-set matrix with a research fallback, the matrix
lifecycle (no automatic install→canonical feedback), self-bootstrap STATE, source-first
fill, and the dual-audience authoring standard enforced by the review panel.

## Scope

In scope (feature-014 §8 MVP):

- **Generic-core dimension spine** — generalize + standards-ground `concern-model.md`
  (domain-agnostic spine; C0–C9 = its software rendering; governance→pipeline note; the
  Decisions-concern decision). *(FR-37)*
- **`domain-doc-matrix.md`** — a new curated `canonical/aid/templates/kb-authoring/`
  artifact: `domain → [doc | spine-dimension | owner | presence]`, seeded with common
  domains; the **software row = today's 15-doc seed**. *(FR-39)*
- **Source-driven domain classifier** — a new GENERATE sub-step that classifies the domain
  from the project index/source; decisive → classify, uncertain → Q&A to the user; records a
  `## Discovery Domain` block in `STATE.md`. Includes the **Step 0f path-triage
  reconciliation** decision. *(FR-38)*
- **Matrix-or-research doc-set flow** — rewire the doc-set proposal to matrix-lookup →
  research-fallback → propose→confirm; anchored to the spine; composable for hybrids; retain
  `synth_default_seed` as the software-row generator; matrix lifecycle (local persistence +
  optional PR-candidate emit; no auto feedback). *(FR-39, FR-40)*
- **Self-bootstrap STATE** — `discover-preflight.sh` self-creates `STATE.md` from template;
  remove the init hard-stop. *(FR-41)*
- **Source-first fill** — reaffirm brownfield-first doc-fill, user-as-gap-filler. *(FR-42)*
- **Dual-audience authoring standard** — wire single-concern/small-docs, junior-clear
  language, tables/bullets-no-diagrams, machine-consumable classification, and the
  `frontmatter→index→content→changelog` layout into kb-authoring + doc templates + generation
  prompts, **enforced by the review panel's Anatomy mandate**. *(FR-43, FR-44)*

**Out of scope:** full downstream decoupling of `aid-summarize` section-templates + the
explicit `doc.md § Section` lookups from fixed KB filenames (a follow-on feature — only bites
once doc-sets routinely diverge from the software row); any telemetry / automatic
install→canonical feedback; greenfield forward-authoring (O7).

## Gate Criteria

- [ ] The generic-core dimension spine is defined, domain-agnostic, and **standards-grounded
  with citations** in `concern-model.md`; C0–C9 documented as its software rendering;
  governance→pipeline boundary stated. *(FR-37)*
- [ ] `domain-doc-matrix.md` exists with a documented schema and common-domain rows; the
  **software row reproduces today's 15-doc seed** (byte-stable `synth_default_seed`). *(FR-39)*
- [ ] Discovery **classifies the domain from source**, records it in `STATE.md`, and raises a
  Required Q&A when the source is insufficient/uncertain (measured-then-confirmed). *(FR-38)*
- [ ] The doc-set proposal resolves via **matrix hit OR research fallback**, anchored to the
  spine, composable, proposed→confirmed; the confirmed set **persists locally**; **no
  automatic install→canonical feedback** path exists. *(FR-39, FR-40)*
- [ ] `/aid-discover` **self-creates `STATE.md`** when absent and proceeds (no "run
  /aid-config first" hard-stop). *(FR-41)*
- [ ] The **dual-audience authoring standard** is written into kb-authoring + templates +
  generation prompts and **checked by the Anatomy mandate** (layout order, frontmatter
  fields, index present, changelog-last, diagram-absence mechanically; reading level +
  single-concern by judgment). *(FR-43, FR-44)*
- [ ] The **Step 0f path-triage reconciliation** is decided and recorded.
- [ ] All section-6 quality gates pass: canonical→render parity (full `run_generator.py`),
  dogfood byte-identity (DBI), ASCII-only + WinPS-5.1 lint for any shipped script, and the
  affected canonical suites (doc-set-read, actback, discovery-doc-ownership) re-run green.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-056 | DESIGN | Generic-core dimension spine + standards-grounded `concern-model.md` generalization |
| task-057 | DESIGN | `domain-doc-matrix.md` artifact (schema + common-domain rows; software row = seed) |
| task-058 | IMPLEMENT | Source-driven domain classifier in GENERATE (+ STATE record, Q&A-on-uncertainty, Step 0f reconciliation) |
| task-059 | IMPLEMENT | Matrix-or-research doc-set flow (rewire Step 0d) + matrix lifecycle (local persist, optional candidate emit) |
| task-060 | IMPLEMENT | Self-bootstrap STATE (`discover-preflight.sh` self-create; remove init hard-stop) |
| task-061 | IMPLEMENT | Dual-audience authoring standard → kb-authoring + templates + generation prompts + Anatomy mandate |
| task-062 | TEST | Tests for classifier / matrix resolution / self-bootstrap / authoring-standard checks + re-run affected suites |
| task-063 | DOCUMENT | Regen profiles + `.claude` dogfood sync (DBI) + KB/skill doc updates + record Step 0f outcome |

## Dependencies

- **Depends on:** delivery-001 (extends f003 doc model + f004 concept spine + f005 panel),
  delivery-004 (recon/paths — domain classifier is the source-driven sibling; Step 0f
  reconciliation), delivery-005 (act-back panel — the Anatomy mandate enforces the standard)
- **Blocks:** -- (none) — the deferred downstream-decoupling follow-on depends on this delivery

## Notes

- **Extend, don't re-spec:** f014 generalizes f004's concept model into the spine, rewires the
  front of GENERATE (domain-classify → matrix-or-research → propose→confirm) in place of the
  fixed-seed Step 0d, and extends f003's doc model with the authoring standard the f005 panel
  enforces. `synth_default_seed` is retained as the matrix's software-row generator.
- **Install-boundary correction:** the matrix ships in `canonical/` and is updated only by
  release/curation; a project's confirmed set persists locally; the only feedback channel is
  an optional, manual PR-candidate artifact. No telemetry.
- **Design rationale** (the standards/governance research) lives in feature-014/SPEC.md
  §Technical Specification.
