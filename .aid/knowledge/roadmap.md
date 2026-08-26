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
- **Status:** Delivered — `canonical/skills/aid-{design,create,update}-{roadmap,mvp,backlog}`,
  `canonical/aid/templates/design-lifecycle.md` and `canonical/aid/templates/design-seed.md`
  are on master, awaiting the next tag; see `backlog.md` § `Next Release`.

## Now

### Design-phase skill family

- **What:** Thirty-six new `design`/`create`/`update` skills covering nine artifact types —
  roadmap, mvp, backlog, architecture, technology stack, testing strategy, CI/CD, document,
  and brainstorm — plus the shared design-lifecycle contract and the `.aid/design/` seed
  layer that backs them. Three deliveries run in sequence: planning skills and lifecycle
  machinery first, foundation and grid skills next, then profile rendering and close-out
  including a description quality sweep across all 111 skill descriptions.
- **Why:** The `design` stage has never had a first-class entry point for planning or
  Knowledge Base artifacts. The shortcut path covers create and update but has no analogous
  design verb for artifacts that are most decision-sensitive. Without it, direction design
  is ad-hoc, untraced, and invisible to the pipeline.
- **Rejected:** Embedding direction-design into the existing bare `/aid-design` skill (too
  broad, no artifact-level structure); releasing skills incrementally without first settling
  the shared contract (the contract must be stable before any consuming skill ships); delivering
  the grid skills before the planning skills (the planning skills produce the documents this
  repo needs to record its own committed direction, so they go first).
- **Status:** Delivered — all three deliveries are complete and on master, awaiting the next
  tag. All 36 skills exist under `canonical/skills/` and are rendered to the five profiles;
  the shortcut catalog is back to 94 rows and the corpus to 111 skill directories.

## Next

### v3.0.0 release

- **What:** The next release packages everything sitting on master since v2.3.0 as a stable
  **major** version. Its committed slice is `backlog.md` § `Next Release`.
- **Why:** It is a major and not a minor because two of the shipped changes break adopters:
  36 skill names are retired with the alias model, so an invocation that worked before now
  resolves to nothing; and the Node floor rises to `>=22`, so an adopter on Node 20 cannot
  install. A minor version would promise compatibility the release does not keep.
- **Rejected:** Cutting it as `v2.4.0` (the version this section previously named — decided
  before the alias retirement and the Node floor raise landed, and no longer honest);
  splitting the breaking changes across two majors (they landed together and share one
  upgrade note, so two migrations where one will do); holding the release for the agent chat
  channel below (not committed, so waiting is speculative delay).
- **Status:** ready to cut — the committed slice is drained into `release-tracking.md` by
  `/release-aid major`, which bumps the carriers, tags, and publishes.

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
- **Status:** intent — the connector catalog and MCP-first protocol are already in place and
  aid-managed consumption is deferred by design; richer consumption is not yet committed to or
  worked.
