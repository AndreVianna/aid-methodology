---
kb-category: meta
notes: "Retired as project-type profile selector. Kept as a kb-category rendering-hint
        reference for GENERATE. Profile-as-project-type (web-app/cli/library/microservices/
        data-pipeline/agentic-pipeline auto-detection) is retired by feature-015/Change 1.
        The section set is now derived from the resolved doc-set + frontmatter, not from a
        project-type profile."
---

# `kb-category` Rendering Hints

> **Status:** Project-type profile auto-detection is **retired** (feature-015, Change 1).
> This file previously held scoring rules for detecting `web-app`, `cli`, `library`,
> `microservices`, `data-pipeline`, and `agentic-pipeline` project types. Those rules
> are replaced by the doc-set/domain-driven section derivation in `state-profile.md`.
>
> What remains is **`kb-category`-keyed rendering guidance** for the GENERATE step —
> how to format each section by its tier, not by project type.

---

## Tier-keyed rendering guidance

`kb-category` ∈ `{primary, extension, meta}` is a **prominence/tier** classifier,
not a content-shape ("glossary" vs "ADR" vs "table"). The content-component decision
uses two signals:

1. **Tier (`kb-category`)** → ordering, featured-ness, and the generic fallback shape.
2. **Well-known doc identity (filename)** → three bespoke components override the
   generic fallback for those specific docs.

### Tier `primary`

Full-prominence section. Featured (accent treatment) for domain-salient core docs.
Format per fact: tables for catalogs, cards for grids, prose for narrative, infographic
for structure. A primary section MAY carry a data-driven infographic if the content
warrants it.

Well-known docs at this tier:
- `domain-glossary.md` → **Glossary / definition component** (not a generic section).
- `capability-inventory.md` → **Capability entry component** (not a generic section).

All other primary docs → generic table / card / prose / infographic, best-format-per-fact.

### Tier `extension`

Supporting / lower-prominence section. Same per-fact format selection as `primary` but
rendered as a secondary section (visually subordinate). Extensions are supporting
documentation, not core newcomer concerns.

Well-known docs at this tier:
- `decisions.md` → **Decision / ADR card component** (not a generic section).

All other extension docs → generic table / card / prose, rendered as supporting section.

### Tier `meta`

Compact prose / reference list. Orientation content, not a primary newcomer concern.
`external-sources.md` and `README.md` sort last and may be folded into the KB Index.
Render briefly; the newcomer is not expected to engage with meta docs as primary content.

---

## Concept Spine (all resolved doc-sets)

`domain-glossary.md`, when present in the resolved doc-set, is always rendered as the
**Glossary / definition component** immediately after "At a Glance" (the concept-first
trio position). This applies regardless of the domain or any other signal — the Glossary
is always the first substantial section for a newcomer who needs vocabulary first.

---

## Section-templates/* as rendering hints

The remaining files in this directory (`web-app.md`, `cli.md`, `library.md`,
`microservices.md`, `data-pipeline.md`, `agentic-pipeline.md`) are **retired as project-type
profile selectors** — they are never selected as a project-type template. Where they contain
rendering guidance that maps to `kb-category` tiers (e.g. per-section content hints), that
guidance is used as a **secondary reference** during GENERATE for its applicable KB docs, but
the section set itself is always derived from the resolved doc-set, not from these templates.
