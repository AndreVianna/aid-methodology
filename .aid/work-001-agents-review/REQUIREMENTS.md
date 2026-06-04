# Requirements

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-04 | Initial interview started | /aid-interview |
| 2026-06-04 | All 10 sections captured (full-path interview) | /aid-interview |
| 2026-06-04 | KB hydration assessed — no writes (brownfield; reqs are forward-looking, KB covered by FR8 post-build) | /aid-interview |
| 2026-06-04 | Interview complete — approved | /aid-interview |
| 2026-06-04 | Cross-reference: install trees 3→5; AC4 +templates/recipes; FR8/AC6 +module-map/README; FR7 +generator fix (Q1–Q3) | /aid-interview |
| 2026-06-04 | Added hard naming constraint: all roster agents carry `aid-` prefix (avoid overwriting user agents) — surfaced during /aid-execute | /aid-execute |

## 1. Objective

Conduct a complete, first-principles review of the AID agent set. Rather than incrementally
trimming the existing 22 agents in `canonical/agents/`, **derive the required agent roles
from the actual needs of the skills and the pipeline process**, then define the final agent
set from those needs. Apply agent-authoring best practices, remove duplication/redundancy,
consolidate overly-specific roles, and simplify wherever possible. The end goal is a leaner,
needs-justified agent roster that improves the AID methodology.

## 2. Problem Statement

The canonical agent roster has grown to 22 agents and is perceived as too large. Specific
concerns raised:
- **Duplication** — some agents overlap in responsibility.
- **Over-specificity** — some agents are too narrow to justify a standalone definition.
- **Redundancy** — some agents are no longer pulling their weight.

This bloat raises maintenance cost (each agent = AGENT.md + README.md, rendered into every
install tree) and makes the methodology harder to understand and to route work through.

The chosen remedy is a **ground-up re-derivation**: enumerate what every skill and every
pipeline phase genuinely requires from an agent, then design the minimal agent set that
covers those needs. The existing 22 agents are an input/reference for the analysis, not the
starting point to be edited in place.

## 3. Users & Stakeholders

- **AID maintainer(s)** (primary) — author and maintain the canonical agents/skills; bear the
  per-agent maintenance cost; the direct beneficiary of a simpler roster.
- **AID adopters / end users** — install AID into their host tool (Claude Code, Codex, Cursor)
  and run the pipeline; they experience agents indirectly via skill dispatch. They need the
  methodology to keep working unchanged in behavior.
- **The agents/skills themselves** — internal "consumers": skills dispatch agents, so the skill
  authors' need for a clear, predictable roster is a first-class concern.

## 4. Scope

### In Scope

- First-principles re-derivation of the required agent roles from the needs of every skill
  and every pipeline phase.
- Review of **how agents are generated and used** in the methodology (the definition format,
  the render/generate pipeline, and the dispatch/usage patterns), not just the roster — all
  open to change.
- Definition of the final agent roster, with each agent justified by a concrete need.
- Authoring the new `canonical/agents/<agent>/AGENT.md` + `README.md` definitions (applying
  agent-authoring best practices).
- A migration map (old 22 agents → new roster: kept / merged / renamed / dropped, with
  rationale).
- Rewiring every skill and reference doc that dispatches an agent by name to the new roster
  (e.g. `SKILL.md` dispatch tables, `references/*.md` agent assignments).
- Regenerating all five install trees (`claude-code`, `codex`, `cursor`, `copilot-cli`,
  `antigravity`) via `/aid-generate` so the repo is fully consistent and buildable.
- Updating any KB docs that describe the agent model (e.g. `architecture.md`).

### Out of Scope

- Changing the *behavior or purpose* of any skill beyond the agent it dispatches.
- Adding or removing pipeline phases or skills.
- Adding new host-tool render targets / install trees (the existing five stay as-is).
- A back-compat / deprecation shim for adopters — adopters re-install the regenerated trees;
  no migration tooling for external consumers is required.
- Functional changes to non-agent parts of the methodology (KB structure, recipes, templates)
  except where they directly reference agents.

## 5. Functional Requirements

- **FR1 — Needs inventory (demand side).** Catalogue every skill and pipeline phase and the
  kind of agent work each genuinely requires. Produce a needs→role matrix derived from the
  process, independent of today's agents.
- **FR2 — Current-state audit (supply side).** Map all 22 existing agents to where and how
  each is dispatched and used; flag duplication, overlap, over-specificity, and single-use
  agents.
- **FR3 — Target roster design.** Derive the minimal agent set from FR1, each role justified
  by single-responsibility + reuse. Includes deciding the agent definition format and the
  generation approach (both in scope per §7).
- **FR4 — Migration map.** Map old 22 → new roster, classified keep / merge / rename / drop,
  with a one-line rationale for each.
- **FR5 — Author new agent definitions.** Write the definitions for the final roster, applying
  agent-authoring best practices and reducing boilerplate.
- **FR6 — Rewire the methodology.** Update every `SKILL.md` dispatch table and reference doc
  that names an agent to the new roster.
- **FR7 — Regenerate install trees.** Run `/aid-generate`; ensure all five trees
  (`claude-code`, `codex`, `cursor`, `copilot-cli`, `antigravity`) are consistent and the repo
  builds/validates. Includes correcting the `aid-generate` skill's own stale references (its
  "three install trees" text and `--tool` enum) to match the five profiles, if not already
  derived from `profiles/`.
- **FR8 — Update KB & agent-count docs.** Reflect the new agent model in `architecture.md`,
  `module-map.md` (which hardcodes agent counts/tiers), the `README.md` agent counts, and any
  other agent-describing KB doc.
- **FR9 — Consistency check.** Verify no dangling references remain to any removed or renamed
  agent anywhere in the repo.

## 6. Non-Functional Requirements

### Design principles (ranked — these govern every keep/merge/drop decision)

1. **Clear single responsibility** *(highest priority)* — each agent does one well-defined
   thing; no two agents overlap in responsibility.
2. **Reuse across skills** — prefer agents invoked by multiple skills; an agent used by only
   one skill is a candidate for merging or inlining unless it has a strong distinct reason.
3. **Authoring simplicity** — agents should be easy to write and maintain; reduce duplicated
   boilerplate and definition complexity.

**"Fewer agents" is an expected outcome, not a primary goal.** The roster should shrink as a
*consequence* of applying single-responsibility + reuse, not because a target number was set.
There is no target count.

## 7. Constraints

**No hard invariants.** Everything about the agent system is open to redesign, including:
- the agent-tier model (Opus / Sonnet / Haiku assignment);
- the per-agent definition format (currently `AGENT.md` + `README.md` per agent);
- the generation / render / install pipeline that emits agents into the host trees;
- how agents are dispatched and used across skills and references.

The only implicit constraint is that the methodology must remain functional and the repo
buildable after the change (per Scope item: regenerate install trees).

**Hard naming constraint (added 2026-06-04):** every agent in the final roster MUST carry an
`aid-` prefix on its name (e.g. `reviewer` → `aid-reviewer`, `architect` → `aid-architect`,
`developer` → `aid-developer`), regardless of the roster's final shape. Rationale:
AID installs agents into the user's host tool (e.g. `.claude/agents/`); unprefixed generic
names (`reviewer`, `developer`, …) would collide with and overwrite the user's own agents.
The `aid-` namespace prevents this. Consequence: ALL surviving/renamed agents are renamed (no
pure "keep" retains its bare name), so the FR6 rewire rewrites every agent-name dispatch site,
and FR9's sweep must confirm no bare (unprefixed) old name survives.

## 8. Assumptions & Dependencies

- **Depends on** `/aid-generate` (and the canonical→render→install pipeline) functioning, so
  the install trees can be regenerated after the roster changes.
- **Depends on** the KB being current enough to serve as a reference for the needs inventory
  (FR1) and current-state audit (FR2).
- **Assumes** existing skills' behavior and contracts stay unchanged — only the agent each
  skill dispatches may change.
- **Assumes** the agent definition format itself may change (per §7), so FR5/FR7 may also
  touch the generator/renderer if a new format is chosen.

## 9. Acceptance Criteria

- **AC1** — A needs→role matrix exists covering every skill and pipeline phase (FR1).
- **AC2** — Every agent in the final roster maps to at least one documented need and has a
  single, non-overlapping responsibility (FR3 + principle 1).
- **AC3** — The migration map accounts for all 22 existing agents, each with a disposition
  (keep / merge / rename / drop) and rationale (FR4).
- **AC4** — No `SKILL.md`, reference doc, KB doc, template, recipe, or install-tree file
  references a non-existent agent; the consistency check passes clean (FR6 + FR9).
- **AC5** — `/aid-generate` runs without error and all five install trees validate; the repo
  builds/validates after the change (FR7).
- **AC6** — `architecture.md`, `module-map.md`, and the `README.md` agent counts (plus any
  other agent-describing KB doc) reflect the new agent model (FR8).
- **AC7** — Each new agent definition conforms to the chosen best-practice authoring format
  with reduced boilerplate (FR5 + principle 3).

## 10. Priority

Single cohesive work; all FRs are **Must-have** and sequenced FR1→FR9 (analysis → design →
authoring → rewire → regenerate → validate). FR7 (regenerate) and FR9 (consistency check) are
the gating validation steps — the work is not done until they pass clean. No FR is deferrable
without breaking the "repo stays buildable" constraint.
