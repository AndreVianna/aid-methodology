# Roster Design

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-04 | Feature identified from REQUIREMENTS.md §5 (FR1–FR4), §6, §9 | /aid-interview |
| 2026-06-04 | Technical specification authored (FR1–FR4 method, artifact formats, AC mapping) | /aid-specify |
| 2026-06-04 | Spec fixes from review (AC1 verification consistency + phase-coverage check; removed pre-deciding language; resolved A3; citation fixes) | /aid-specify |
| 2026-06-04 | Applied REQUIREMENTS §7 hard naming constraint: all proposed roster names carry the `aid-` prefix (collision-avoidance); decision artifacts updated (target-roster/migration-map/roster-decision) | /aid-execute |

## Source

- REQUIREMENTS.md §5 (FR1 needs inventory, FR2 current-state audit, FR3 target roster design, FR4 migration map)
- REQUIREMENTS.md §6 (ranked design principles), §4 (scope), §9 (AC1–AC3), §10 (priority)

## Description

Decide what the AID agent set *should be*. Starting from the actual needs of every skill and
pipeline phase (the demand side) and an audit of the existing 22 agents and where they are
dispatched (the supply side), derive the final, minimal agent roster — each role justified by
single-responsibility and reuse — and choose the agent definition format and generation
approach. Capture the result as one reviewable decision artifact, including an old→new
migration map (keep / merge / rename / drop, with rationale per agent).

This feature produces a *decision*, not code changes. Nothing in the repo's agents, skills, or
install trees is modified here — that is `feature-002-roster-rollout`. The single human
approval gate of the whole work sits at the end of this feature: the roster is frozen before
anything is touched.

## User Stories

- As an **AID maintainer**, I want a needs-justified target roster and a clear old→new
  migration map so that I can approve the redesign before any files change.
- As a **skill author**, I want each proposed agent to have one clear responsibility and a
  documented reuse story so that I know which agent to dispatch and why.

## Priority

Must

## Acceptance Criteria

- [ ] **AC1** — A needs→role matrix exists covering every skill and pipeline phase (FR1).
- [ ] **AC2** — Every agent in the proposed roster maps to at least one documented need and
      has a single, non-overlapping responsibility (FR3 + design principle 1).
- [ ] **AC3** — The migration map accounts for all 22 existing agents, each with a disposition
      (keep / merge / rename / drop) and a one-line rationale (FR4).
- [ ] The chosen agent definition format and generation approach are stated and justified
      against the ranked design principles (FR3 + principle 3).

---

## Technical Specification

> Authored by `/aid-specify`. This feature is a **methodology/tooling** work item, not an
> app feature — there is no DB or UI. The standard SPEC sections are mapped to their
> methodology analogs: "Deliverable Artifacts & Formats" plays the role of the data model,
> "Process Flow" the role of the feature flow, and "Components & Inputs" the role of layers.

### Overview & Approach

Re-derive the AID agent roster from first principles: build the **demand** side by cataloguing
every skill and pipeline phase and the agent work each genuinely requires (FR1), build the
**supply** side by auditing all 22 existing agents under `canonical/agents/` and where each is
dispatched (FR2), then derive the minimal target roster by applying the three ranked design
principles from REQUIREMENTS.md §6 (1 single-responsibility, 2 reuse, 3 authoring-simplicity),
including the chosen agent-definition format and generation approach (FR3), and finally produce a
complete old→new migration map (FR4). "Fewer agents" is an *outcome* of applying the principles,
not a target — there is no agent-count goal (REQUIREMENTS.md §6).

**Scope boundary — DECIDE, do not EXECUTE.** This feature produces a *reviewable decision
artifact set* only. It performs the analysis and records the proposed roster/migration, which a
human approves at the single approval gate at the end of this feature (SPEC Description). It does
**not** rename, merge, delete, or author any agent, skill, profile, KB doc, or install-tree file —
all file mutation belongs to `feature-002-roster-rollout` (REQUIREMENTS.md §4 In/Out of Scope;
FR5–FR9). This Technical Specification therefore defines the **method**, the **artifact
schemas**, the **process flow**, the **inputs read**, and **how each acceptance criterion is
verified** — i.e. the shape of the deliverable and the procedure, not the final roster itself.

> **Note on the artifact medium.** The four artifacts below are specified as Markdown tables
> living under `.aid/work-001-agents-review/design/` (proposed path). This keeps the decision
> artifact human-reviewable in a normal diff/PR and consistent with how AID already stores
> decision/state docs as Markdown under `.aid/` (e.g. `STATE.md`, `REQUIREMENTS.md`). No new
> tooling or schema format is introduced for the artifacts themselves.

### Deliverable Artifacts & Formats

Four artifacts are produced. Proposed home: `.aid/work-001-agents-review/design/`. Each is a
Markdown document with the table schema below (column = field). A single combined
`roster-decision.md` MAY embed all four as `##` sections; this spec treats them as four logical
artifacts regardless of physical file split.

**(a) Needs→Role Matrix — `design/needs-matrix.md` [FR1, satisfies AC1].**
The demand side: one row per (skill phase × distinct agent-work need). Derived from the *process*,
independent of today's agents.

| Field | Definition |
|-------|------------|
| `consumer` | The skill or pipeline phase that has the need — one of the 11 user-facing skills (`aid-config`, `aid-discover`, `aid-interview`, `aid-specify`, `aid-plan`, `aid-detail`, `aid-execute`, `aid-summarize`, `aid-deploy`, `aid-monitor`, `aid-housekeep`) or the maintainer-only `aid-generate` (per `architecture.md` skill inventory). |
| `phase / state` | The skill state or pipeline phase where the need arises (e.g. `aid-discover GENERATE`, `aid-execute REVIEW`). |
| `need` | The kind of agent work required, stated as a capability (e.g. "design a spec from requirements", "review code against a rubric", "extract a list of files by glob"). |
| `tier-pressure` | The model-tier the work plausibly demands (large/medium/small) per the existing tier model in `architecture.md` → `## Architectural Pattern` → `### 3. Three-tier agent dispatch...`; advisory input to roster derivation, not a binding decision. |
| `reuse-count` | How many distinct consumers share this need (drives principle 2). |
| `source-evidence` | File:section citation proving the need exists (e.g. a `SKILL.md` dispatch line or `references/state-*.md` step). |

**(b) Current-State Audit Table — `design/current-audit.md` [FR2].**
The supply side: exactly one row per existing agent — all 22 (`architect`, `data-engineer`,
`developer`, `devops`, `discovery-analyst`, `discovery-architect`, `discovery-integrator`,
`discovery-quality`, `discovery-reviewer`, `discovery-scout`, `interviewer`, `operator`,
`orchestrator`, `performance`, `researcher`, `reviewer`, `security`, `simple-extractor`,
`simple-formatter`, `simple-glob`, `tech-writer`, `ux-designer`).

| Field | Definition |
|-------|------------|
| `agent` | Canonical dir name under `canonical/agents/`. |
| `tier` | `tier:` frontmatter value (large/medium/small). |
| `agent_md_lines` | Body size of `AGENT.md` (size signal for boilerplate burden). |
| `dispatched_by` | Skills/references that name this agent (the reuse measurement). |
| `dispatch_breadth` | Count of distinct skills that dispatch it (single-use ⇒ merge candidate per principle 2). |
| `responsibility` | One-line statement of what the agent does today (from its `## What You Do`). |
| `overlap_flags` | Overlap / duplication / over-specificity / redundancy flags vs other agents (principle 1). |
| `boilerplate_burden` | Whether the agent carries the duplicated `## Heartbeat protocol` + `## Self-review discipline` blocks (principle 3 evidence). |
| `evidence` | File:section citations for the dispatch and overlap claims. |

**(c) Target Roster Spec — `design/target-roster.md` [FR3, satisfies AC2; format/generation sub-section satisfies the format AC].**
The derived minimal roster. One row per *proposed* agent, plus a dedicated sub-section for the
format/generation decision. Every `proposed_agent` name carries the `aid-` prefix per
REQUIREMENTS.md §7 (collision-avoidance — installing AID must not overwrite a user's own
`.claude/agents/<name>.md`); the prefix is a naming constraint on the roster, not a change to its
derived composition.

| Field | Definition |
|-------|------------|
| `proposed_agent` | Proposed agent name (new or kept). |
| `single_responsibility` | The one well-defined responsibility (must be non-overlapping with every other row — principle 1). |
| `covers_needs` | The needs-matrix rows (artifact a) this agent satisfies — must be ≥1 (this is the AC2 mapping). |
| `consumers` | Which skills will dispatch it (reuse story — principle 2). |
| `proposed_tier` | large/medium/small assignment with rationale. |
| `derivation_rationale` | Why this agent exists, justified against principles 1–3. |

Plus required sub-sections in `target-roster.md`:
- **Format decision** — the chosen agent-definition format (see *Format & generation decision criteria*) with justification against principle 3.
- **Generation decision** — the chosen generation approach (how definitions are emitted into the 5 install trees), referencing the existing `render_agents.py` per-format-branch mechanism.

**(d) Migration Map — `design/migration-map.md` [FR4, satisfies AC3].**
Exactly 22 rows (one per existing agent — the same 22 enumerated in artifact b), each with a
disposition.

| Field | Definition |
|-------|------------|
| `old_agent` | One of the 22 existing agents. |
| `disposition` | Enum: `keep` / `merge` / `rename` / `drop`. |
| `new_agent` | Target agent in the proposed roster (the merge/rename destination; empty for `drop`). |
| `rationale` | One-line justification tied to a principle (e.g. "single-use, merged into X per principle 2"). |
| `dispatch_rewrite_hint` | For feature-002 consumption: which dispatch sites (file:line classes) will need rewiring if this disposition is executed. |

### Process Flow

Ordered analysis steps. Each step's output is an artifact section; nothing here writes to
`canonical/agents/`, `canonical/skills/`, `profiles/`, or KB docs.

1. **Demand inventory (FR1).**
   *Input:* the 11 (+1) skills' `SKILL.md` + `references/state-*.md` under `canonical/skills/`
   (dogfood mirror at `.claude/skills/`), `architecture.md` skill inventory + phase mapping.
   *Output:* artifact (a) `needs-matrix.md`. Every consumer must appear at least once (AC1 coverage).
2. **Supply audit (FR2).**
   *Input:* all 22 `canonical/agents/<a>/AGENT.md` + `README.md`; a name-grep of dispatch sites
   across `canonical/skills/` + `.claude/skills/` (and references). The cross-reference pass has
   already measured dispatch breadth (e.g. `reviewer` ~392 refs across 74 files, `architect` ~136,
   `orchestrator` ~62, down to a tail: `simple-formatter` and `simple-glob` ~4 refs each, `operator`
   in 2 files) — record these per row.
   *Output:* artifact (b) `current-audit.md`.
3. **Derive roster (FR3) under the ranked principles.**
   *Input:* (a) ∩ (b) — match each need to the supply, applying the keep/merge/drop rules below.
   *Output:* artifact (c) roster rows. Every roster row must map to ≥1 need (AC2) and have a
   non-overlapping responsibility (principle 1).
4. **Decide format & generation (FR3).**
   *Input:* `coding-standards.md §8e` (canonical AGENT.md structure), the duplicated boilerplate
   blocks, `render_agents.py` format branches, `profiles/*.toml [agent]` blocks.
   *Output:* the Format decision + Generation decision sub-sections of artifact (c).
5. **Produce migration map (FR4).**
   *Input:* (b) old agents × (c) proposed roster.
   *Output:* artifact (d) `migration-map.md` — 22 rows, every disposition assigned.
6. **Self-consistency check (pre-approval).** Verify AC1–AC3 + the format AC hold across the four
   artifacts (see *Acceptance Criteria mapping*), then present the artifact set at the human
   approval gate. No file mutation; approval freezes the roster for feature-002.

### Components & Inputs

**Read (inputs to the analysis):**
- `canonical/agents/*/AGENT.md` + `canonical/agents/*/README.md` — the 22 agents under audit.
- `canonical/skills/*/SKILL.md` + `canonical/skills/*/references/*.md` — dispatch surface (demand + reuse). Dogfood mirror `.claude/skills/` confirms but canonical is authoritative.
- `.claude/skills/aid-generate/` — the generator; note FR7's stale "three install trees" text and `--tool claude-code|codex|cursor` enum in `SKILL.md` (lines 4, 8, 15, 61) that lag the five profiles — relevant context for the generation decision, but the *fix* is feature-002.
- `.claude/skills/aid-generate/scripts/render_agents.py` — the 4 per-format branches (`markdown`, `toml`, `copilot-agent`, `antigravity-rule`) for the generation decision.
- `profiles/{claude-code,codex,cursor,copilot-cli,antigravity}.toml` — `[agent].format` + `[agent.frontmatter]` per host (e.g. `codex.toml` uses `format = "toml"`).
- `canonical/templates/subagent-heartbeat-protocol.md`, `canonical/templates/self-review-protocol.md` — the source of the duplicated boilerplate blocks (principle 3 evidence).
- KB: `architecture.md` (agent-tier model, canonical→render→install pipeline, skill inventory), `module-map.md §2a–2c` (hardcoded "22 agents (10 large / 9 medium / 3 small)"), `coding-standards.md §8e` (CONFIRMED AGENT.md structure).

**NOT touched (write boundary):** no writes to `canonical/agents/`, `canonical/skills/`,
`canonical/templates/`, `profiles/`, install trees, or KB docs. The only files this feature writes
are the four decision artifacts under `.aid/work-001-agents-review/design/` (and this SPEC).
Rewiring (FR6), authoring (FR5), regeneration (FR7), KB updates (FR8), and the consistency check
(FR9) are all feature-002.

### Roster-derivation criteria

Operationalizing the three ranked principles into testable keep/merge/drop rules. Rules are
applied in principle order; ties broken by the higher-ranked principle.

- **R1 (single-responsibility, principle 1 — highest).** Two agents whose `responsibility` /
  `covers_needs` substantially overlap are **merge** candidates; the merged agent must state one
  non-overlapping responsibility. No proposed roster row may share a responsibility with another
  (this is the AC2 test). Over-specific agents (a responsibility that is a strict subset of another
  agent's) are **merge/drop** candidates.
- **R2 (reuse, principle 2).** An agent dispatched by **exactly one** skill (`dispatch_breadth == 1`)
  is a **merge** candidate **unless** it has a strong distinct reason — a distinct responsibility
  that cannot be folded without violating R1, or a distinct tier/tool requirement. `dispatch_breadth`
  is computed for every agent from the cross-reference measurements (e.g. `operator` 2 files,
  `simple-formatter` / `simple-glob` ~4 refs each at the low-breadth end; `reviewer`, `architect`,
  `orchestrator` at the high-breadth end). High-breadth and single-use agents are *inputs* to the
  keep/merge rules — no agent is pre-classified to a disposition here; the rule fires per row at
  derivation time.
- **R3 (authoring-simplicity, principle 3).** Where two roles differ only by boilerplate or
  near-identical bodies, prefer one agent + parameterization over two. Agents whose definitional
  weight is dominated by the duplicated `## Heartbeat protocol` + `## Self-review discipline` blocks
  are flagged so the format decision (below) can reduce that burden.
- **R4 (need-coverage, AC2 guard).** Every proposed roster agent MUST cite ≥1 needs-matrix row in
  `covers_needs`. A roster agent with zero needs is invalid and must be dropped.
- **R5 (count-neutrality).** No rule targets a specific final count; shrinkage is an emergent
  result of R1–R4 (REQUIREMENTS.md §6).

Each keep/merge/rename/drop decision records which rule fired, giving the migration-map rationale.

### Format & generation decision criteria

The agent-definition format and generation approach are **in scope to change** (REQUIREMENTS.md §7;
no hard invariants). Options to weigh, judged primarily against principle 3 (authoring-simplicity)
and the constraint "repo stays buildable / 5 trees still render":

1. **Status quo** — keep per-agent `canonical/agents/<a>/AGENT.md` + `README.md`, boilerplate
   macro-copied verbatim into each `AGENT.md` (today's pattern per `coding-standards.md §8e`:
   frontmatter → role line → `## Heartbeat protocol` → `## Self-review discipline` → role sections).
   *Con:* the Heartbeat block is byte-identical across all 22 agents and Self-review across 19 —
   pure duplication that raises maintenance cost (FR2 concern, principle 3).
2. **Shared-include for boilerplate** — keep per-agent files but factor the two duplicated blocks
   into the existing `canonical/templates/{subagent-heartbeat-protocol,self-review-protocol}.md`
   and inject them at render time, so authors no longer copy them. This leverages the existing
   renderer substitution machinery (`substitute_filenames`, defined in `render_lib.py` and imported
   into `render_agents.py`).
3. **Single-file-per-agent** — collapse `AGENT.md` + `README.md` into one file per agent (the
   README is human-facing only; evaluate whether it earns a separate file).
4. **Consolidated manifest** — one source listing all agents with shared sections defined once
   (most aggressive; weigh against host-tool render needs — Codex emits one `.toml` per agent via
   `render_agents.py` `_render_codex_toml`, so per-agent identity must survive whatever format wins).

**Decision criteria:** (i) minimizes duplicated boilerplate (principle 3); (ii) keeps each agent's
identity renderable into all 4 existing formats (`markdown`/`toml`/`copilot-agent`/`antigravity-rule`)
without new per-tool special-casing; (iii) keeps authoring a new agent a one-file, low-ceremony act;
(iv) does not require redesigning the canonical→render→install pipeline (constraint: buildable).
The chosen option is recorded with this justification in `target-roster.md` → *Format decision* /
*Generation decision*. The decision must also note (as input to feature-002) the `aid-generate`
stale "three install trees" / `--tool` enum that any generation change should correct under FR7.

### Migration Plan considerations

The migration map (artifact d) is the hand-off contract to `feature-002-roster-rollout`. To be
deterministically consumable it must:
- Enumerate **all 22** existing agents exactly once (AC3) with a disposition from the closed enum
  `keep | merge | rename | drop` — no agent left unclassified.
- For every `merge`/`rename`, name the exact `new_agent` destination so feature-002 can mechanically
  rewire dispatch sites; for `drop`, leave `new_agent` empty and ensure no proposed roster agent
  depends on it.
- Carry `dispatch_rewrite_hint` per row: the *class* of dispatch sites to update (e.g.
  "all `SKILL.md` dispatch-table rows naming `<old>`", "`references/state-*.md` agent assignments"),
  so feature-002's FR6 rewire and FR9 consistency check have a checklist. Note that the cross-ref
  pass already located these sites (e.g. `reviewer` across 74 files) — the hint references that breadth.
- Be internally closed: the set of `new_agent` values (minus blanks) must equal the proposed roster
  in artifact (c); every roster agent must be reachable from at least one old agent or marked as a
  net-new addition with rationale.

### Acceptance Criteria mapping

| AC (this SPEC) | How satisfied / verified |
|----------------|---------------------------|
| **AC1** — needs→role matrix covers every skill and pipeline phase (FR1) | Artifact (a) `needs-matrix.md` exists. The canonical consumer set is the **12** = the 11 dirs under `canonical/skills/` PLUS `aid-generate` (maintainer-only, living at `.claude/skills/aid-generate/`, deliberately absent from `canonical/skills/`). **Consumer check (two-way set equality):** every consumer in {11 `canonical/skills/` dirs ∪ `aid-generate`} appears in the matrix `consumer` column, AND every distinct matrix `consumer` value is a member of that 12-element set — i.e. `set(matrix.consumer) == set(ls canonical/skills/) ∪ {aid-generate}`, both directions empty-diff (not a one-sided diff against `ls canonical/skills/`, which would always show `{aid-generate}` and never pass). **Phase/state check:** the source-of-truth for each consumer's phases/states is its `SKILL.md` State Detection / Dispatch table plus its `references/state-*.md` files. Verification = `set(matrix.(consumer, phase/state) pairs) == set((skill, state) pairs enumerated across all skills' SKILL.md dispatch tables / the `references/state-*.md` file stems)` — a concrete two-way diff a reviewer runs, empty in both directions. |
| **AC2** — every proposed agent maps to ≥1 documented need and has a single, non-overlapping responsibility (FR3 + principle 1) | Artifact (c) `target-roster.md`: every row's `covers_needs` is non-empty (R4) and references valid `needs-matrix` rows; pairwise `single_responsibility` check finds no overlap (R1). |
| **AC3** — migration map accounts for all 22 agents, each with a disposition + one-line rationale (FR4) | Artifact (d) `migration-map.md` has exactly 22 rows whose `old_agent` set equals the 22 dirs under `canonical/agents/`; each row has a disposition from the enum and a non-empty `rationale`. Verification = row-count == 22 and old_agent set-equality. |
| **Format/generation AC** — chosen format + generation approach stated and justified against the ranked principles (FR3 + principle 3) | `target-roster.md` → *Format decision* + *Generation decision* sub-sections name the chosen option from the four weighed above and justify it against principle 3 + the buildable/4-format constraint. |

(SPEC-level AC4–AC7 — consistency check, `/aid-generate` clean run, KB/count updates, conforming
new definitions — are **feature-002** acceptance criteria; this feature only *specifies* the
format and the rewrite hints that make them achievable.)

### Out of Scope / Assumptions

**Out of scope (decide-vs-execute boundary, restated):** no renaming, merging, dropping, or
authoring of any agent; no edits to `SKILL.md`/reference dispatch tables; no `profiles/` or
install-tree changes; no `/aid-generate` run; no KB/`module-map.md`/`README.md` count updates;
no fix of the `aid-generate` stale-trees text. All of these are `feature-002-roster-rollout`
(FR5–FR9). This feature ends at human approval of the four artifacts.

**Assumptions / decisions for reviewer or human to confirm:**
- **A1 — Artifact home.** The four artifacts live under `.aid/work-001-agents-review/design/`
  (proposed). If the work prefers a single combined `roster-decision.md`, the four schemas embed
  as `##` sections unchanged.
- **A2 — Markdown-table medium.** Artifacts are Markdown (not JSON/CSV), consistent with AID's
  existing decision-doc convention. No new validator tooling is introduced for them in this feature;
  AC checks are manual/grep-level set comparisons.
- **A3 — Consumer set (decided).** `aid-generate` IS in scope as the 12th consumer: the needs
  matrix covers the 11 user-facing skills + the maintainer-only `aid-generate` (per
  `architecture.md`). This is a stated decision, not an open question — the matrix schema and AC1's
  two-way set-equality check both commit `aid-generate` as a consumer (it lives at
  `.claude/skills/aid-generate/`, maintainer-only, deliberately not in `canonical/skills/`).
- **A4 — Format/generation is decided here, not pre-decided.** This spec *enumerates and weighs*
  format/generation options and the decision criteria; the actual choice is made during execution
  and recorded in artifact (c). No option is pre-selected.
- **A5 — Boilerplate counts (measured on disk, June 2026).** `## Heartbeat protocol` present in
  **all 22** `AGENT.md` (byte-identical block); `## Self-review discipline` present in **19**,
  absent only in `discovery-reviewer`, `orchestrator`, and `reviewer`. NOTE: this contradicts
  `module-map.md` line 146 (which claims the blocks are "absent on simple-* utilities and
  `interviewer`") and `coding-standards.md §8e` item 3 (claims Heartbeat "absent on simple-*
  utilities and `interviewer`") — both KB statements are stale; the audit (artifact b) uses the
  disk-measured truth. These are inputs to the audit, not yet decisions.
- **A6 — Cross-reference dispatch numbers** (e.g. `reviewer` ~392 refs / 74 files) are advisory
  measurements to seed the audit; the executing analysis re-confirms them at audit time.
