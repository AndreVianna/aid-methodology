# Diagram Content Reference

Where AID's diagrams live, where their facts come from, and what to update when those facts change. Diagram labels are easy to miss in a text search, so check this list when you change a phase, skill, agent or profile.

## Where diagrams live

| Place | How it is made | Edit at |
|-------|----------------|---------|
| Website pages | Plain lists and `Flow` components. `Flow` renders a real ordered list, so there is no image or Mermaid to go stale. | `site/src/components/` (components) and `site/src/content/docs/` (pages) |
| Website copies of `docs/*.md` | The site imports `docs/*.md` at build time. | `docs/` (never the site copy) |
| Website skill and agent pages | Generated from `canonical/` at build time. | `canonical/skills/`, `canonical/agents/` |
| `README.md` | A hand-written Mermaid diagram near the top that shows the entry points and the numbered path. | `README.md` |
| `docs/aid-methodology.md` | Mermaid blocks, shown as written on GitHub and imported into the site. | `docs/aid-methodology.md` |
| `kb.html` | Inline SVG diagrams built by the scripts in `canonical/aid/scripts/summarize/` when you run `/aid-summarize`. | The KB documents, then re-run `/aid-summarize` |

Do not hand-edit generated output. Run the generator or the build instead.

## Update triggers

Use this table to find what to check when a fact changes.

| If you change... | Check these places |
|------------------|--------------------|
| A phase name, order or count | `README.md` diagram; the methodology pipeline diagram; site pages that list the phases; the `kb.html` pipeline diagram |
| A skill (add, rename, remove) | The skill count wherever it is stated (derive it with `ls -d canonical/skills/*/ \| wc -l`); the `kb.html` module map; `docs/repository-structure.md` and `docs/install.md`; `README.md` only if the entry points change |
| The entry-point model (shortcut, `/aid-triage`, `/aid-describe`) or the shortcut engine's states | `README.md` diagram; the methodology "Three Doors In" section and its diagram; the site's how-it-works and choose-your-entry pages |
| The shortcut catalog (`shortcut-catalog.yml`) | The counts in `docs/aid-methodology.md`, `docs/install.md`, `docs/repository-structure.md` and the glossary; the `kb.html` module map |
| `/aid-monitor`'s loopback targets (bug to `/aid-fix`, change request to `/aid-triage`) | `README.md` diagram; the methodology feedback-loops and SDD-comparison diagrams (change both together) |
| An agent (add, rename, remove) or its tier | The agent count and tier text in `docs/aid-methodology.md`, `docs/install.md` and `docs/repository-structure.md`; the `kb.html` module map |
| A profile (a supported tool) | `docs/install.md`, `docs/repository-structure.md`, the FAQ and glossary tool tables; the `kb.html` render-and-distribute diagram |
| A publish channel (npm, PyPI, GitHub Releases) | The `kb.html` render-and-distribute diagram; `docs/install.md` |
| A top-level directory | `docs/repository-structure.md`; the `kb.html` architecture and module-map diagrams |

## Rules for any new diagram

1. Prefer a list or a `Flow` component over an image. A list is readable by screen readers and cannot drift out of sync with a picture.
2. Name every node in plain words. Do not carry meaning by color or position alone.
3. State the source of each fact in the page's text or in this file, so the next editor knows where to check it.
4. If you add, remove or relabel a diagram, update the table above in the same change.

## What is not covered

The `aid-interviewer` agent keeps its name, and `interview` is still the plain word for the conversation `/aid-describe` holds with you. Do not rename them as part of a diagram fix.
