---
kb-category: primary
notes: "Retired as project-type profile selector (feature-015/Change 1). Content recast
        as rendering hints for the agentic-pipeline domain's KB docs, keyed by kb-category
        tier and doc identity — not by project-type. Use these hints during GENERATE when
        the resolved doc-set contains the listed docs and the domain facets include
        'agentic-pipeline' or 'methodology'."
---

# Rendering Hints — Agentic-Pipeline Domain Docs

> **Status:** Retired as a project-type profile selector (feature-015, Change 1).
> Profile-as-project-type auto-detection is replaced by the doc-set/domain-driven
> section derivation in `state-profile.md`. This file is now a **rendering hint
> reference** for GENERATE when the domain facets include `agentic-pipeline` or
> `methodology` and the resolved doc-set contains these specific docs.

---

## Per-doc rendering hints (keyed by doc identity + `kb-category`)

### `architecture.md` (tier: `primary`)

The defining diagram for an agentic pipeline: a top-to-bottom or left-to-right pipeline
of named phases with explicit phase gates (where the user approves transitions) and
feedback loops (where downstream phases can revise upstream artifacts). Cite the
methodology spec line range for each phase if available. Explain *why* the pipeline is
sequential by default, and *which* feedback loops exist as escape hatches.

Infographic candidate: a pipeline-phase flowchart (phases → gates → feedback loops).

### `feature-inventory.md` (tier: `primary`)

For an agentic pipeline, "features" are "skills" or "phases". For each skill/phase,
render a card with: skill name (slash command if applicable), one-sentence purpose,
state-machine shape (e.g., `GENERATE → REVIEW → FIX → DONE`), dispatched sub-agents,
key inputs / outputs.

### `module-map.md` (tier: `primary`)

For an agentic pipeline, "modules" split into two distinct concerns: **Skills** (the
slash-command units that do work) and **Agents** (the AI entities dispatched by skills).
Render each concern separately. For agents, include the tier hierarchy (e.g., Large /
Medium / Small) and which skills dispatch which agents.

Infographic candidate: an agent-dispatch model diagram (skill → tier → agents).

### `pipeline-contracts.md` (tier: `primary`)

The interfaces that hold the pipeline together: skill ↔ sub-agent dispatch contracts
(what prompt fields are mandatory), script CLI signatures + exit codes, file-format
contracts (settings.yml, STATE.md sections, manifest / heartbeat schemas), and the
canonical → render → install contract (if multi-tool). One subsection per contract;
cite source for each.

For an agentic pipeline, note that "Endpoints" map to "Slash commands" (the skill
invocations, not HTTP endpoints).

### `schemas.md` / `artifact-schemas.md` (tier: `primary`)

Render an entity/schema diagram of the KB documents: which docs are primary vs
meta vs generated, which depend on others, per-doc role. Reference the schema doc
that defines the contracts. If the project has a flexible doc-set, explain the
standard default + how to extend.

### `coding-standards.md` (tier: `primary`)

For an agentic pipeline, highlight the review-grade-fix discipline: reviewer dispatch
contract, grading rubric, severity scale, the ledger format (if a structured findings
ledger is used), and the rule about reviewer ≠ executor. Explain the *philosophy* —
the reviewer is the safety net, the orchestrator owns catching all errors before review.

### `infrastructure.md` (tier: `primary`)

How the project ships to adopters: install script (per-tool, or auto-detect), supported
tool hosts, what gets copied where, runtime requirements. If multi-tool, include the
canonical → profile distribution model. For an agentic pipeline, "Services" map to
"Agents"; "CLI binary" maps to "slash command invocation".

### `test-landscape.md` (tier: `primary`)

Test coverage for an agentic pipeline: unit tests, integration tests, canonical suites,
DBI / byte-identity checks, and any CI gate that guards quality. Render as a table or
cards per concern.

### `tech-debt.md` (tier: `primary`)

Render as severity cards (critical / high / medium / low). Focus on the *actionability*
for a newcomer: what debt exists and what it means for contributing or adopting the
project.

### `authoring-conventions.md` (tier: `primary`)

For an agentic pipeline, this covers the authoring discipline that governs KB docs,
skills, and generated assets. Render as prose + key rules table. A newcomer needs to
understand the conventions before contributing.

### `domain-glossary.md` (tier: `primary` — bespoke component)

Render as the **Glossary / definition component** (see `state-generate.md` §3).
For an agentic pipeline, include: the skill/agent/phase terminology, any coined names
for pipeline states or contracts, and project-specific abbreviations.

### `capability-inventory.md` (tier: `primary` — bespoke component)

Render as the **Capability entry component** (see `state-generate.md` §3).
For an agentic pipeline, capabilities map to slash commands / skills — what each does,
when to use it, how to invoke it.

### `decisions.md` (tier: `extension` — bespoke component)

Render as the **Decision / ADR card component** (see `state-generate.md` §3).
Focus on the architectural decisions that shaped the pipeline: why phases are sequential,
why a given agent tier model was chosen, why the canonical → render → install split exists.

### `quality-gates.md` (tier: `extension`)

Supporting section. Render as a table of gates (which state/phase, what checks, what
the pass/fail criteria are). Secondary prominence — a newcomer reads this after the core
pipeline docs.

### `external-sources.md` (tier: `meta`)

Compact reference list. Orientation: the external references, blog posts, papers, or
upstream projects that informed the design. Render briefly; fold into the KB Index or
render as a compact reference block.

### `README.md` (tier: `meta`)

Compact reference. The project's entry-point for first-time visitors. May be omitted
from the main content area and surfaced only via the KB Index row.

---

## Vocabulary adjustments for agentic-pipeline domain

When the domain facets include `agentic-pipeline` or `methodology`, adjust these labels
in section headings and "At a Glance" framing:

| Default label | Agentic-pipeline label |
|---|---|
| "Features" | "Skills" or "Phases" |
| "Endpoints" | "Slash commands" |
| "Services" | "Agents" |
| "Modules" | "Skills" + "Agents" |
| "Data Model" | "Knowledge Base Shape" |
| "API Surface" | "Pipeline Contracts" |

These are label adjustments, not structural changes. The section set is still the
resolved doc-set; these hints adjust phrasing for domain clarity.
