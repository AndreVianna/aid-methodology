---
kb-category: primary
source: hand-authored
objective: Present commitment and future direction for AID — what it has decided to do next, why, and what it deliberately did not choose.
summary: Read this to know where the project is going and what the first committed slice is; specific defined-and-prioritized items live in backlog.md and shipped work in release-tracking.md.
sources: []
tags: [D, roadmap, commitment, direction, mvp]
see_also: [backlog.md, decisions.md, release-tracking.md]
owner: architect
audience: [architect, pm, developer]
---

# Roadmap

This document holds AID's committed direction: what the project has decided to build, why,
and what it has deliberately chosen not to build yet. It does not hold work items, task
lists, or execution detail — those live in the work state files and in `backlog.md`. Shipped
work is in `release-tracking.md`; the rationale behind significant decisions is in
`decisions.md`.

## Contents

- [MVP](#mvp)
- [Now](#now)
- [Next](#next)
- [Later](#later)

## MVP

- **What:** The nine planning skills plus the design-lifecycle machinery from the first
  delivery: `/aid-design-roadmap`, `/aid-create-roadmap`, `/aid-update-roadmap`,
  `/aid-design-mvp`, `/aid-create-mvp`, `/aid-update-mvp`, `/aid-design-backlog`,
  `/aid-create-backlog`, `/aid-update-backlog` — together with the shared `design →
  create → update` contract, the design-seed layer (`.aid/design/`), the KB doctrine
  amendment admitting `roadmap.md` and `backlog.md` as conditional doc-set members, and
  their conditional registrations in `.aid/settings.yml`.
- **Why:** This set is self-contained and immediately useful: it introduces the design-seed
  layer, settles the shared lifecycle contract, and gives adopters every skill they need to
  document their project's committed direction — without depending on the foundation/grid
  skills (delivery two) or the profile render (delivery three). Planning skills are the
  most universally applicable increment in the family; they also produce the two documents
  this repo itself needs to track its own direction.
- **Rejected:** Scoping the MVP to a single skill (no usable increment without the full
  design/create/update triad and the shared contract); including the knowledge relationship
  graph (independent effort, not a prerequisite for any planning skill); making the full
  36-skill catalog the MVP (conflates the minimum slice with the complete delivery).
- **Status:** In progress — `canonical/skills/aid-{design,create,update}-{roadmap,mvp,backlog}`
  and `canonical/aid/templates/design-lifecycle.md` and `canonical/aid/templates/design-seed.md`
  exist on the active branch; see `release-tracking.md` for the planned release items.

## Now

### Design-phase skill family

- **What:** Thirty-six new `design`/`create`/`update` skills covering nine artifact types —
  roadmap, mvp, backlog, architecture, technology stack, testing strategy, CI/CD, document,
  and brainstorm — plus the shared design-lifecycle contract and the `.aid/design/` seed
  layer that backs them. Three deliveries run in sequence: planning skills and lifecycle
  machinery first, foundation and grid skills next, then profile rendering and close-out
  including a description quality sweep across all 112 skill descriptions.
- **Why:** The `design` stage has never had a first-class entry point for planning or
  Knowledge Base artifacts. The shortcut path covers create and update but has no analogous
  design verb for artifacts that are most decision-sensitive. Without it, direction design
  is ad-hoc, untraced, and invisible to the pipeline.
- **Rejected:** Embedding direction-design into the existing bare `/aid-design` skill (too
  broad, no artifact-level structure); releasing skills incrementally without first settling
  the shared contract (the contract must be stable before any consuming skill ships); delivering
  the grid skills before the planning skills (the planning skills produce the documents this
  repo needs to record its own committed direction, so they go first).
- **Status:** In progress — `canonical/skills/aid-design-roadmap`, `aid-create-roadmap`,
  `aid-design-mvp`, `aid-create-mvp`, `aid-design-backlog`, `aid-create-backlog`,
  `aid-update-roadmap`, `aid-update-mvp`, `aid-update-backlog` exist on the active branch;
  deliveries two and three are planned and detailed, not yet executing.

### Knowledge relationship graph

- **What:** `/aid-graph` adds `relationships.md` (a machine-readable link table over the
  Knowledge Base) and `graph.html` (an interactive graph view with a table fallback), both
  produced on-demand via a new canonical script set and a set of graph templates. It is a
  sibling of `/aid-summarize` in the same post-KB slot: run once the KB is finished and
  approved, never triggered by discovery, idempotent and content-addressed.
- **Why:** RAG-by-convention gives the KB its navigability at read time; the graph adds an
  explicit relationship layer that convention alone cannot express — which documents depend
  on which, which share a domain concern, and which are entry points for a given audience.
  The gap is most acute for new contributors who do not yet know the KB's shape.
- **Rejected:** A live vector store (heavy operational cost for a per-project artifact that
  changes infrequently); embedding Mermaid diagrams in each doc (the KB forbids diagrams,
  and the graph view achieves the same goal without touching the sources).
- **Status:** In progress — `canonical/skills/aid-graph/SKILL.md` exists and the feature is
  executing on a dedicated branch; the Unreleased entry in `release-tracking.md` records
  the planned release items.

## Next

### v2.4.0 release

- **What:** After the two in-flight efforts merge to master, the next release packages them
  as a stable minor version. Both are self-contained: neither gates on a third in-flight
  effort, and either could ship first if the other is delayed, but they are expected to land
  close enough together that batching them is the lower-overhead path.
- **Why:** The release script and CI/CD pipeline are fully automated; there is no cost reason
  to hold the features once they land. A single minor release for both avoids a second
  update cycle for adopters.
- **Rejected:** A patch release carrying only one of the two (would still require a second
  release cycle); waiting for a third feature before cutting the release (no third feature is
  committed at this point, so waiting is speculative delay).
- **Status:** intent — no work has been opened for the release itself; it opens when the two
  in-flight efforts close.

### Agent chat channel

- **What:** A new skill that routes a free-form message to the correct agent directly from
  the pipeline, outside the structured skill sequence. It is the exploratory complement to
  the shortcut path: the shortcut path compresses well-defined tasks; the chat entry point
  is for open-ended interactions that do not yet have a clear pipeline entry point.
- **Why:** The current pipeline requires the user to know which skill to invoke. As the skill
  catalog grows, the cognitive load of routing increases; a conversational entry point lowers
  the barrier for users who are exploring rather than executing.
- **Rejected:** Building the chat channel before the design-phase skills (the formal pipeline
  has a gap first; the chat channel is the complement, not the fix); exposing raw agent
  access without a structured entry point (traceability and safety require a defined surface).
- **Status:** intent — the feature is specified and ready to plan; no delivery has been
  detailed or executed.

## Later

### Plain-language Knowledge Base rewrite

- **What:** A rewrite of Knowledge Base documents in plain language, making the KB accessible
  to a non-specialist audience — teams where not everyone reads dense technical prose, or
  onboarding contributors who need a gentler entry.
- **Why:** KB documents are currently written for architects and senior developers. A
  plain-language layer would support a broader adopter profile without replacing the
  technical content.
- **Rejected:** Auto-generating the plain-language layer from existing docs (output quality
  too low; the KB's technical density is structural, not incidental); adding a parallel
  plain-language doc family alongside the existing KB (doubles maintenance burden for every
  future update).
- **Status:** intent — detailed and paused; the direction is wanted but not yet irreversibly
  committed.

### Richer connector consumption

- **What:** Aid-managed consumption of connector APIs within skill runs — actually calling
  connector endpoints (issue trackers, CI systems, cloud providers) rather than only
  cataloguing them. The connector catalog and MCP-first protocol are already in place;
  richer consumption is the next layer on top.
- **Why:** Adopters increasingly want pipeline steps to interact directly with external tools
  without leaving the skill surface. The catalog-only model establishes the shape; richer
  consumption is the delivery of the value that shape anticipates.
- **Rejected:** Building richer consumption before the catalog has more usage data (the
  catalog needs real-world adoption to reveal which consumption patterns are actually needed);
  auto-generating connector-specific skills from schemas (premature; the consumption surface
  is not yet designed).
- **Status:** intent — anticipated by the architecture (see `decisions.md`), not yet
  committed to or worked.
