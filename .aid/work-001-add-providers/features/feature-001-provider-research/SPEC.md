# Provider Deep-Research & Mapping

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-31 | Drafted from REQUIREMENTS during FEATURE-DECOMPOSITION | /aid-interview |
| 2026-05-31 | Technical Specification drafted | /aid-specify |
| 2026-05-31 | Specify review fixes (ledger spec-feature-001) | /aid-specify |
| 2026-05-31 | Specify review fix R2 (ledger #10) | /aid-specify |
| 2026-05-31 | Add Q-J context-file convention ruling; de-brittle cross-refs (post-specify review) | /aid-specify |

## Source

- REQUIREMENTS.md §4 (In Scope — Deep research), §5 FR1, §8 (Assumptions/Dependencies), §9 AC1, §10 priority 1

## Description

Before any profile is written, produce one findings document that pins down exactly how each
new host tool extends its behavior, and translate that into a concrete table mapping every AID
primitive (sub-agent, skill, script, template, recipe, context/instructions file, MCP) onto the
target tool's primitive. Covers: (a) the **latest** GitHub Copilot CLI extension model — custom
agents (`.github/agents/*.agent.md` frontmatter + invocation), instructions files, MCP config,
and the install/CLI surface; (b) a colleague's existing Copilot CLI fork used as a reference
implementation, incorporated once its URL is provided (proceed docs-first if it doesn't arrive);
and (c) confirmation of Google Antigravity's conventions (rules + slash-workflows) against current
docs, validating the "Antigravity ≈ Cursor" assumption. Where a tool lacks an AID primitive
(Copilot has no skill/slash primitive; Antigravity has no custom sub-agent file), the document
states the transformation or omission explicitly — never a faked primitive. **Top risk to
resolve:** whether Antigravity's `sub-agents → .agent/rules/` is a cross-kind mapping (it likely
is — cursor's rules come from a separate `canonical/rules/` source, not sub-agents), which decides
whether the Antigravity profile is pure-data or must reuse the Copilot feature's cross-kind engine
work. This is the first deliverable; the profile features consume its mapping.

## User Stories

- As an AID maintainer, I want a single findings doc with a verified AID-primitive→tool-primitive
  mapping for both new tools so I can implement the profiles without re-researching each tool's
  evolving conventions.
- As an AID maintainer, I want the colleague's Copilot CLI fork captured as a reference so I reuse
  proven layout decisions instead of guessing.
- As an AID adopter on Copilot CLI / Antigravity, I want the mapping to reflect each tool's
  *current* documented conventions so the install I eventually get actually works.

## Priority

Must

## Acceptance Criteria

- [ ] Given the current Copilot CLI docs, when research completes, then the findings doc records the
      latest agent file convention (path, frontmatter fields, invocation), instructions file
      options, MCP config location, and install/CLI surface, each with a source reference.
- [ ] Given the Antigravity docs, when research completes, then the doc confirms/corrects the rules
      + slash-workflows conventions and the "Antigravity ≈ Cursor" assumption, and explicitly rules
      whether `sub-agents → rules` (and `skills → workflows`) are cross-kind mappings.
- [ ] Given a provided fork URL, when the fork is reviewed, then the doc reflects relevant decisions
      from it (or records explicitly that the URL was not provided and proceeded docs-only).
- [ ] Given both tools, when the doc is complete, then it contains a concrete mapping table — AID
      primitive (sub-agent / skill / script / template / recipe / context / MCP) → tool primitive —
      for Copilot CLI and Antigravity, with each impedance point marked transform-or-omit, not faked.
- [ ] Given neither tool has a native home for AID's helper **scripts/templates**, when the mapping
      is produced, then it explicitly decides where scripts/templates land in each tool's tree (a
      referenced location) — so the profile features have no undefined gap.
- [ ] Given the downstream profiles defer profile-config values to FR1 via `[FR1-owned]` markers,
      when research completes, then the findings doc produces a definite value/ruling for the **full
      FR1 Deliverable Contract** — per-tool `[model_tiers]` strings, `[tool_names]` remaps,
      `[capabilities]` flags, Antigravity `project_context_file` (AGENTS.md vs GEMINI.md),
      Antigravity rule-file extension (`.mdc` vs `.md`), the new `agent.format` enum label + emitted
      frontmatter key set, the Copilot MCP emit/omit ruling, the scripts/templates home, the
      Antigravity cross-kind ruling, and the context-file production convention (`project_context_file`
      authored as profile-local data, not rendered) — with no marker left uncrossed. The **Technical-Spec FR1
      Deliverable Contract + "Acceptance / Done" block (below) is the authoritative, itemized
      checklist** for this criterion; this top-level list and that block MUST stay reconciled.

---

## Technical Specification

> This is a **RESEARCH** feature. Its deliverable is a findings document plus a verified
> AID-primitive→tool-primitive mapping — **not code**. The standard Data Model / Feature Flow /
> Layers sections are replaced by the research-adapted sections below. The whole point of this
> feature is that feature-002 (copilot-cli) and feature-003 (antigravity) can be implemented
> from the mapping table **without re-researching** either tool, and with a clear signal of
> which mapping cells are pure profile-data vs. which need new renderer (engine) code.

### Deliverable & Location

**Single findings document:**
`/home/andre.vianna/projects/AID/.aid/work-001-add-providers/research/provider-mapping.md`

Rationale for location: research output for this work belongs under the work folder, not under
`.aid/knowledge/` (that is the Discovery KB, regenerated by `/aid-discover`; a hand-authored
research note would be clobbered or flagged as drift). A new `research/` subdirectory under the
work root keeps the artifact alongside the REQUIREMENTS/STATE/features it serves, and lets
feature-002 / feature-003 link to it by a stable relative path. One file (not per-tool files) so
the cross-tool mapping table is read in one place.

**Required shape of `provider-mapping.md`:**

1. **Per-tool convention sections** — one per tool (Copilot CLI, Antigravity), each recording the
   tool's *current documented* extension model with a **source reference** (doc URL + access date,
   or fork path) on every load-bearing claim:
   - agent/custom-instruction file convention(s): path(s), frontmatter/field shape, invocation;
   - instructions/context file options;
   - MCP config location (if any);
   - workflow/slash primitive (if any);
   - install / CLI surface (how the tree gets onto a user's machine + how the tool discovers it).
2. **The mapping table** — the core deliverable. One table per tool (or one combined table with a
   column per tool), with **one row per AID primitive**, plus the **profile-config rows** that
   carry the `[FR1-owned]` values the downstream profiles defer to FR1 (see FR1 Deliverable
   Contract below). Every cell is a concrete value/path/ruling, never "TBD":

   | AID primitive / profile config | Copilot CLI target | Antigravity target | Disposition tag |
   |---|---|---|---|
   | sub-agent (`canonical/agents/*/AGENT.md`) | … | … | … |
   | skill (`canonical/skills/aid-*/` SKILL.md + references/) | … | … | … |
   | helper script (`canonical/scripts/**`) | … | … | … |
   | template (`canonical/templates/**`) | … | … | … |
   | recipe (`canonical/recipes/*.md`) | … | … | … |
   | context / instructions file (`{project_context_file}`) | … | …  (AGENTS.md vs GEMINI.md — Q-H) | … |
   | MCP config | … | … | … |
   | `[model_tiers]` strings (per tier alias) — Q-E | … | … | `[data]` (values FR1-owned) |
   | `[tool_names]` remaps (complete map) — Q-F | … | … | `[data]` (map FR1-owned) |
   | `[capabilities]` verified flags (all 4) — Q-G | … | … | `[data]` (flags FR1-owned) |
   | rule-file extension (`.mdc` vs `.md`) — Q-I | n/a | … | `[data]` (extension FR1-owned) |
   | `agent.format` enum label — Q-A | … (e.g. `copilot-agent`) | … | `[transform:engine]` (label FR1-owned) |

   Every cell carries one of three **disposition tags** (per AC4's "transform-or-omit, never
   faked" rule, extended with the engine-vs-data axis this spec requires):
   - **`[data]`** — expressible purely by a new `profiles/<tool>.toml` + existing renderer passes
     (layout dirs, `filename_map`, `[[extras.rules]]`, `tool_names`, `model_tiers`,
     `[capabilities]` flags, `[skill.frontmatter].claude_code_optional`). No Python change.
     **Note on agent frontmatter:** `[agent.frontmatter].required` / `.optional` are parsed by
     `aid_profile.py` (`FrontmatterConfig`, lines 109-114) but are **dead for emission** — no
     renderer consults them. `render_agents.py` `_render_agent_for_profile` (lines 282-297)
     hardcodes the emitted agent frontmatter key set (`name, description, tools, model`, plus
     `permissionMode` / `background` only when present in canonical). Therefore **any agent
     frontmatter shape beyond that hardcoded set is `[transform:engine]`, never `[data]`** —
     listing fields in `[agent.frontmatter]` does not make them emit. (Skills are different:
     `render_skills.py` *does* consult `[skill.frontmatter].claude_code_optional` to drop fields
     for non-Claude-Code profiles, so that one lever is genuine `[data]`.)
   - **`[transform:engine]`** — needs new renderer code (a new emitter, a new `agent.format`
     value, or cross-kind routing). The cell MUST name the specific renderer gap (see Renderer
     Validation below) so feature-002/003 scope the engine work precisely.
   - **`[omit]`** — the tool has no home for this primitive; the cell states what is dropped and
     why it is safe to drop (e.g. recipes are an `/aid-interview` lite-path input, not a runtime
     tool primitive). No faked target.

### Research Method

**Sources (in priority order):**

1. **Copilot CLI — current vendor docs (primary).** Fetch the *latest* GitHub Copilot CLI custom-
   agent / instructions / MCP docs (GitHub Docs "Copilot CLI" + "custom agents" + "MCP" pages,
   and the `github/copilot-cli` repo README/docs if applicable). Record the exact doc URL and
   access date per claim; the model is versioned/evolving (REQUIREMENTS §8) so undated claims are
   not acceptable. Use Context7 / web fetch for current pages rather than relying on training data.
   Seed conventions already captured in REQUIREMENTS §2 (treat as the prior to confirm, not as
   ground truth):
   - agents: `.github/agents/NAME.agent.md` (repo) / `~/.copilot/agents/NAME.agent.md` (user);
     frontmatter `name, description, target, tools, model, user-invocable, mcp-servers, metadata`;
     invoked via `/agent`, `--agent`, or inference;
   - instructions: `AGENTS.md` / `.github/copilot-instructions.md` /
     `.github/instructions/**/*.instructions.md` / `$HOME/.copilot/copilot-instructions.md`;
     MCP: `~/.copilot/mcp-config.json` (`COPILOT_HOME` override).
2. **Antigravity — current vendor docs (primary).** Confirm/correct the rules + slash-workflows
   conventions (`.agent/rules/*.md`, `.agent/workflows/*.md` slash-invoked; `AGENTS.md`/`GEMINI.md`
   context; `~/.gemini/…` global) and the **"Antigravity ≈ Cursor" assumption** (REQUIREMENTS §8).
3. **Colleague's Copilot CLI fork (reference, docs-first fallback per AC3 / STATE.md Q1).** The
   fork URL was **not provided** during the interview (the 2 public forks `ubidev` + `shake-k` are
   on a pre-`profiles/` layout and lack the work). Proceed **docs-first**: complete the mapping
   from vendor docs, and **explicitly record in the findings doc that the fork URL was not
   provided and the research proceeded docs-only**. If the URL arrives before/while feature-001
   executes, fold its layout decisions in and re-tag any affected cells. Do **not** block on it.

**Renderer validation (validate the mapping against the *current* renderer's real capabilities).**
Every `[data]` tag MUST be verified achievable by the existing renderer **as-is**; every
`[transform:engine]` tag MUST cite the specific constraint it violates. The renderer is fixed-pass
and closed-enum — concretely:

> **Renderer naming precision.** REQUIREMENTS and the banner above refer to `run_generator.py`
> (repo root) as the canonical→profiles driver. `run_generator.py` *orchestrates* a generation
> run; the per-kind **emitters** that actually transform canonical assets into a tool tree — and
> therefore the code every `[transform:engine]` cell must target — live at
> `.claude/skills/aid-generate/scripts/render_*.py`, each with its own `main()` entrypoint
> (`render_agents.py`, `render_skills.py`, `render_templates.py`, `render_canonical_scripts.py`,
> `render_recipes.py`) plus the shared `aid_profile.py` (profile schema + validator). When this
> spec says "the renderer," it means those per-kind `render_*.py main()` emitters, not the
> orchestrator.

- **Closed agent-format enum.** `aid_profile.py` `_KNOWN_AGENT_FORMATS = {"markdown", "toml"}`
  (line 334) and the validator rejects any other value (lines 394-398). Copilot's `.agent.md`
  is markdown-with-different-frontmatter, but **it is not reachable as data**: `render_agents.py`
  `_render_agent_for_profile` (lines 282-297) hardcodes the emitted frontmatter to
  `name, description, tools, model` (plus `permissionMode` / `background` when present in
  canonical), and `_build_frontmatter_md` (lines 104-125) just serializes whatever that function
  passes it. The `[agent.frontmatter].required` / `.optional` lists are **parsed but never
  consulted** for agent emission (verified: no renderer references them). Copilot's
  `target` / `user-invocable` / `mcp-servers` fields therefore have **no emission path today**.
  **Conclusion: Copilot `.agent.md` agent frontmatter is `[transform:engine]`** — it needs a new
  emission path (a new `agent.format` value and/or a frontmatter-driven emitter). It is not
  achievable by adding fields to `[agent.frontmatter]` in a profile alone.
- **Fixed asset-kind passes, by directory.** `render_agents.py` globs
  `canonical/agents/*/AGENT.md` (line 358); `render_skills.py` reads `canonical/skills/`. There is
  **no cross-kind routing** — a given canonical kind is rendered by exactly one renderer into one
  target subdir derived from `[layout].<kind>_dir`. Mapping AID **skills → Copilot agents**
  (Copilot has no skill primitive) means routing the `canonical/skills/` pass to produce
  `.agent.md` files — that is a renderer change, **`[transform:engine]`**, not data.
- **No MCP emitter exists.** No renderer writes `mcp-config.json`; the profile schema has no MCP
  table (`aid_profile.py` `Profile` dataclass, lines 168-192). Copilot MCP emission is therefore
  `[transform:engine]` (new emitter + new profile schema) **or** `[omit]` if the mapping decides
  AID ships no MCP servers — the doc must pick one and justify it.
- **What a profile.toml *can* express today (the `[data]` envelope):** `[layout]` roots + per-kind
  dirs + `project_context_file`; `[agent].format` ∈ {markdown, toml} (note `[agent.frontmatter]`
  `required`/`optional` are **parsed but dead for emission** — see the agent-frontmatter note
  above; only the format value routes); `[skill]` decomposition (`references` only —
  `_KNOWN_DECOMPOSITIONS`) + `[skill.frontmatter].claude_code_optional` (the one frontmatter lever
  the renderer *does* consult, in `render_skills.py`); `[model_tiers]` (simple or detailed);
  `[tool_names]` remap; `[filename_map]`
  (`project_context_file`, `reviewer_output_file`, `open_questions_file` required);
  `[[extras.rules]]` (Cursor-style `.mdc`/rule files with `filename`/`always_apply`/`globs`);
  `[capabilities]` flags. Anything outside this envelope is `[transform:engine]`.

### Key Questions the Mapping MUST Answer

These are explicit deliverable requirements — `provider-mapping.md` is not done until each is
answered (or, where docs are silent, marked **docs-only-noted** with the open gap stated):

- **Q-A — Copilot skill + sub-agent → `.agent.md`.** What is the exact `.agent.md` frontmatter
  shape AID must emit, and how is the resulting agent invoked? Resolve: (1) AID **sub-agents**
  (22 `canonical/agents/`) → `.agent.md` — direct kind match, but frontmatter differs from AID's
  `name/description/tools/model`; (2) AID **skills** (10 `canonical/skills/`) — Copilot has **no
  skill/slash primitive**, so state whether skills also become `.agent.md` agents (and how their
  Thin-Router + references/ bodies survive) or become instructions, and tag the disposition. Name
  which `.agent.md` fields are pass-through vs computed/renamed (per Fix #1, all such frontmatter
  is `[transform:engine]` because no current renderer emits beyond `name/description/tools/model`).
  **Deliverable — new `agent.format` enum label.** feature-002 will add a third `agent.format`
  value to `_KNOWN_AGENT_FORMATS` and route on it; its literal string label is `[FR1-owned]`
  (feature-002 §Profile Data → `[agent].format` proposes `"copilot-agent"`). Q-A MUST commit to the **exact enum label string**
  the Copilot profile will set (`copilot-agent`, or a justified alternative) and the exact emitted
  frontmatter key set/order for that format — not merely "a new format value" in the abstract — so
  feature-002 wires the validator and the new emitter to a fixed name.
- **Q-B — Copilot MCP-config emission.** Does AID ship any MCP servers? If yes, where does
  `~/.copilot/mcp-config.json` get written (user-home vs repo) and is it `[transform:engine]`
  (new emitter)? If no, mark MCP `[omit]` and justify. This question must end with a definite
  ruling, not "TBD".
- **Q-C — scripts/templates "no-native-home" placement (REQUIRED OUTPUT, AC5).** Neither tool has
  a native home for AID's helper **scripts** (`canonical/scripts/**`) or **templates**
  (`canonical/templates/**`). For **each** tool, the mapping MUST name a concrete referenced
  location (e.g. a `.github/aid/scripts/` + `.github/aid/templates/` home for Copilot; an
  `.agent/aid/...` home for Antigravity — these are illustrative, the research picks and justifies
  the real ones) so the profile's `[layout].scripts_dir` / `templates_dir` and the renderer's
  install-path rewrite (`rewrite_install_paths` keys body refs off `install_root`) resolve in an
  adopter project. No undefined gap left for feature-002/003. Confirm the chosen location is
  reachable via `[layout]` dirs alone (`[data]`) — it should be.
- **Q-D — Antigravity cross-kind ruling (the top risk; decides feature-003→feature-002
  dependency).** Is the Antigravity mapping **`sub-agents → .agent/rules/`** + **`skills →
  .agent/workflows/`** achievable as **pure data** (i.e. the existing per-kind passes can be
  pointed at renamed target dirs via `[layout]`, the way Cursor already maps cleanly), **or** does
  it require **cross-kind machinery** (routing the `canonical/agents/` pass into a rules dir and
  the `canonical/skills/` pass into a workflows dir with different output shapes)? Decision rule:
  if Antigravity rules/workflows are just markdown files in renamed dirs with the same body and a
  thin/absent frontmatter — `[data]`, and **feature-003 does NOT depend on feature-002's engine
  work**. If sub-agents must be *transformed* into a different artifact shape to live as rules
  (frontmatter dropped/renamed, body reshaped) — `[transform:engine]`, and **feature-003 reuses
  feature-002's cross-kind/new-emitter work, creating a dependency**. The findings doc MUST state
  the ruling and the resulting dependency edge explicitly, because the PLAN ordering hinges on it.
  (Note the existing Cursor profile does NOT derive its `.mdc` rules from `canonical/agents/`; they
  come from `[[extras.rules]]` + `canonical/rules/` — so "rules" in Cursor is not sub-agent-sourced,
  which is why Antigravity's sub-agents→rules is a genuinely new question, not a solved one.)
- **Q-E — model-tier strings (`[model_tiers]`) per tool.** Both downstream profiles defer their
  `[model_tiers]` values to FR1 (feature-002 §Profile Data → `[model_tiers]` — Copilot model strings;
  feature-003 §Profile Data → `[model_tiers]` — Antigravity / Gemini-lineage model strings, "confirm").
  The mapping MUST produce, **for each
  tool**, the concrete model-string value for **every tier alias the renderer resolves**
  (`_resolve_model` looks up `large` / `medium` / `small` — enumerate the actual tier keys the
  canonical agents reference) and state whether each tool uses the **simple** form
  (`tier = "model-string"`, like Claude Code / Cursor) or the **detailed** form
  (`[model_tiers.<tier>]` with `model` + `reasoning_effort`, like Codex). Each model string carries
  a source reference. This is `[data]` (a `[model_tiers]` table), but the *values themselves* are
  the FR1 deliverable — no profile can be written without them.
- **Q-F — tool-name remaps (`[tool_names]`) per tool.** Both profiles defer `[tool_names]` to FR1
  (feature-002 §Profile Data → `[tool_names]` — "any Copilot tool-name remaps"; feature-003 §Profile
  Data → `[tool_names]` — "cursor remaps Bash→Terminal; confirm" for Antigravity). The mapping MUST
  produce, **for each tool**, the explicit per-tool
  remap dict: for **each** AID tool name the canonical agents declare (`Read, Glob, Grep, Bash,
  Write, Edit, …`), either the tool's renamed equivalent or an explicit "no remap — passes
  through". `_remap_tools` substitutes only keys present in the dict and passes the rest through,
  so the deliverable is the **complete key→value list** (or an explicit empty-map ruling) for each
  tool, sourced. This is `[data]` (a `[tool_names]` table) but the map contents are FR1-owned.
- **Q-G — capability flags (`[capabilities]`) per tool.** Both profiles defer `[capabilities]`
  "verified flags" to FR1 (feature-002 §Profile Data → `[capabilities]`; feature-003 §Profile Data →
  `[capabilities]`). The mapping MUST produce, **for each
  tool**, the verified boolean for **each** flag in `CapabilitiesConfig` (`aid_profile.py`
  159-165): `hooks`, `skill_chaining`, `background_execution`, `stop_hook_autocontinue` — each set
  true/false against the tool's documented support, with a source reference. This is `[data]` (a
  `[capabilities]` table) but the verified flag values are FR1-owned.
- **Q-H — Antigravity context/instructions file: `AGENTS.md` vs `GEMINI.md` (binary ruling).**
  `project_context_file` for the Antigravity profile is `[FR1-owned]` (feature-003 §Profile Data →
  `project_context_file` "AGENTS.md vs GEMINI.md"; feature-004 §AGENTS.md Multi-Install Collision →
  context-file "or GEMINI.md — mirror feature-003"). Listing both as options in the
  convention section is **not sufficient** — the mapping MUST commit to a **single definite value**
  for `[layout].project_context_file`, with the doc evidence that the chosen file is the one
  Antigravity actually reads (and noting whether both are written, with one canonical). Downstream
  gets a decisive pick, not a menu. (`[data]` — a `[layout].project_context_file` value — but the
  pick itself is FR1-owned.)
- **Q-I — Antigravity rule-file extension: `.mdc` vs `.md` (binary ruling).** Whether Antigravity
  consumes Cursor-style `.mdc` rule files verbatim or requires a `.md` variant is `[FR1-owned]`
  (feature-003 §Profile Data → `[[extras.rules]].filename` "whether Antigravity wants .mdc verbatim
  or a .md variant"; `filename = "aid-methodology.mdc"  # confirm extension`). The mapping MUST rule on the **exact
  rule-file extension** Antigravity accepts and therefore the `[[extras.rules]]` `filename`
  extension the profile must use, sourced. This is distinct from Q-D (which rules data-vs-engine
  routing for sub-agents→rules); Q-I rules only the **file extension** of the rule artifacts.
  (`[data]` — `[[extras.rules]].filename` — but the extension ruling is FR1-owned.)
- **Q-J — context-file production convention (how `project_context_file` is produced).** How does
  each new provider's `project_context_file` (the context/instructions document) come to exist on
  disk? **Verified ground truth (state as fact in the ruling):** (i) `canonical/` has **no
  context/instructions source** — it carries only agents, recipes, rules, scripts, skills, and
  templates, so there is nothing to render a context document *from*. (ii) The existing 3 profiles'
  context files — `profiles/claude-code/CLAUDE.md`, `profiles/codex/AGENTS.md`,
  `profiles/cursor/AGENTS.md` — are **hand-authored, committed, and NOT rendered**: they appear in
  **no** `emission-manifest.jsonl`. They are near-identical (~27 lines), differing only in (a) the
  filename header, (b) the tool-specific embedded path (`.agents/` vs `.cursor/` vs `.claude/`), and
  (c) the KB-import idiom (`@.aid/knowledge.` vs the prose "Read `.aid/knowledge/INDEX.md`").
  (iii) `project_context_file` **is** a real profile knob and `{project_context_file}` is a real
  substitution token consumed in *other* files' bodies — but **nothing emits the context document
  itself**. **Ruling (default):** each new provider ships its `project_context_file` as a
  **profile-local, committed context file authored as profile-tree data** — written from the shared
  ~27-line template with that tool's path/idiom substituted — exactly as codex/cursor do today.
  It is **NOT rendered from canonical** and **NOT added to any `emission-manifest.jsonl`**.
  Rationale: matches how the existing 3 profiles work; respects REQUIREMENTS §4 Out of Scope (adds
  **no new canonical source** and changes **no existing-3 output**); and the byte-identical
  regression gate is unaffected because a re-render never touches an un-manifested file. **This
  ruling is ratifiable, not permanent:** if the project later wants a single canonical context
  source plus a context-file emitter, that is a **separate, larger change, OOS today**. **FR2's
  "context → AGENTS.md" / AC2 is therefore satisfied as profile-local data, NOT via a new emitter.**
  (`[data]` — a committed profile-tree file + the `[layout].project_context_file` value — authored,
  not rendered.)

### FR1 Deliverable Contract (cross-walk of every `[FR1-owned]` marker)

`provider-mapping.md` is the FR1 research deliverable that features 002/003/004 defer to via
`[FR1-owned]` markers. The doc is **not complete** until it produces a definite value or ruling for
**every** item below. Each row names the downstream marker(s), the value/ruling FR1 must produce,
where in this spec it is required, and the disposition the value lands in. (Disposition tags below
describe how the *resulting profile data/code* behaves; the **research itself is `[data]`-neutral**
— FR1 produces values and rulings, it does NOT build profiles or write renderer code.)

| FR1-owned value / ruling | Deferred by (downstream) | Produced by | Lands as |
|---|---|---|---|
| Copilot `.agent.md` agent frontmatter shape (fields + emission) | feature-002 §`.agent.md` emission | Q-A | `[transform:engine]` (new emitter; not `[agent.frontmatter]` data — Fix #1) |
| New `agent.format` enum label (e.g. `copilot-agent`) | feature-002 §Profile Data → `[agent].format` | Q-A | `[transform:engine]` (validator + router wiring) |
| Copilot `[model_tiers]` strings (per tier alias) | feature-002 §Profile Data → `[model_tiers]` | Q-E | `[data]` (`[model_tiers]`) — values FR1-owned |
| Antigravity `[model_tiers]` strings (Gemini-lineage) | feature-003 §Profile Data → `[model_tiers]` | Q-E | `[data]` (`[model_tiers]`) — values FR1-owned |
| Copilot `[tool_names]` remaps (complete map) | feature-002 §Profile Data → `[tool_names]` | Q-F | `[data]` (`[tool_names]`) — map FR1-owned |
| Antigravity `[tool_names]` remaps (confirm Bash→Terminal etc.) | feature-003 §Profile Data → `[tool_names]` | Q-F | `[data]` (`[tool_names]`) — map FR1-owned |
| Copilot `[capabilities]` verified flags (all 4) | feature-002 §Profile Data → `[capabilities]` | Q-G | `[data]` (`[capabilities]`) — flags FR1-owned |
| Antigravity `[capabilities]` verified flags (all 4) | feature-003 §Profile Data → `[capabilities]` | Q-G | `[data]` (`[capabilities]`) — flags FR1-owned |
| Antigravity `project_context_file`: AGENTS.md vs GEMINI.md | feature-003 §Profile Data → `project_context_file`; feature-004 §AGENTS.md Multi-Install Collision → context-file | Q-H | `[data]` (`[layout].project_context_file`) — pick FR1-owned |
| Antigravity rule-file extension: `.mdc` vs `.md` | feature-003 §Profile Data → `[[extras.rules]].filename` | Q-I | `[data]` (`[[extras.rules]].filename`) — extension FR1-owned |
| Copilot MCP-config emission ruling (emit/omit + location) | feature-002 §MCP decision | Q-B | `[transform:engine]` or `[omit]` — ruling FR1-owned |
| scripts/templates "no-native-home" placement (both tools) | feature-002 + feature-003 §Profile Data → `[layout]`; AC5 | Q-C | `[data]` (`[layout]` dirs) — locations FR1-owned |
| Antigravity sub-agents→rules / skills→workflows cross-kind ruling + dependency edge | feature-003 §dependency-on-feature-002 (iff engine) | Q-D | `[data]` or `[transform:engine]` — ruling FR1-owned |
| Context-file production convention (`project_context_file` authored as profile-local data, not rendered) | feature-002 + feature-003 §Profile Data → context-file; FR2 / AC2 | Q-J | `[data]` (committed profile-tree file + `[layout].project_context_file`) — convention FR1-owned |

A downstream implementer MUST be able to populate **every** `[FR1-owned]` cell in
`profiles/copilot-cli.toml` and `profiles/antigravity.toml` (and scope every named engine
extension) from this table alone, with no value left as "TBD" and no marker uncrossed.

### Outputs Consumed By

- **feature-002 (copilot-cli)** consumes the Copilot column of the mapping table + the Copilot
  per-tool convention section: it implements `profiles/copilot-cli.toml` and the narrow renderer
  extension(s) the `[transform:engine]` cells call for (`.agent.md` emission, MCP decision,
  scripts/templates home).
- **feature-003 (antigravity)** consumes the Antigravity column + Q-D's cross-kind ruling: it
  implements `profiles/antigravity.toml` and depends on feature-002's engine work **iff** Q-D
  ruled `[transform:engine]`.

The mapping must be **concrete enough to implement the two profiles from it without re-research**:
every target cell names a real path/field; every `[transform:engine]` cell names the renderer
gap; every `[data]` cell maps to a specific profile TOML key.

### Acceptance / Done

This feature is done when:

- [ ] `provider-mapping.md` exists at the path above with both per-tool convention sections, each
      load-bearing claim carrying a source reference (URL + access date, or fork path), and the
      cross-tool mapping table present (all 7 AID-primitive rows + the profile-config rows
      `[model_tiers]` / `[tool_names]` / `[capabilities]` / rule-extension / `agent.format` label,
      × both tools).
- [ ] **Every mapping cell is tagged** `[data]` | `[transform:engine]` | `[omit]`; no untagged
      cell; no faked primitive. Every `[transform:engine]` cell names the specific renderer
      constraint it violates (closed agent-format enum / fixed per-kind pass / no MCP emitter /
      profile-schema gap); every `[data]` cell names the profile TOML key that expresses it.
- [ ] The **key questions (Q-A…Q-J) are each answered** with a definite ruling, or explicitly
      marked **docs-only-noted** with the residual gap stated. Q-D's ruling explicitly states
      whether feature-003 depends on feature-002; Q-J's ruling states the context-file production
      convention (authored profile-local data, not rendered).
- [ ] **Every `[FR1-owned]` cell in the FR1 Deliverable Contract has a definite value/ruling**
      (no "TBD"), specifically:
  - [ ] **`[model_tiers]`** strings produced for **each** tier alias, **per tool** (Copilot + Antigravity),
        simple-vs-detailed form stated, each value sourced (Q-E).
  - [ ] **`[tool_names]`** remap produced **per tool** — a complete key→value map or an explicit
        empty-map ruling for each AID tool name (Q-F).
  - [ ] **`[capabilities]`** verified true/false produced **per tool** for all 4 flags
        (`hooks`, `skill_chaining`, `background_execution`, `stop_hook_autocontinue`), each sourced (Q-G).
  - [ ] **Antigravity `project_context_file`** ruled to a **single** value (AGENTS.md *or* GEMINI.md),
        with doc evidence (Q-H).
  - [ ] **Antigravity rule-file extension** ruled (`.mdc` *or* `.md`), with doc evidence (Q-I).
  - [ ] **New `agent.format` enum label** committed to an exact string (e.g. `copilot-agent`) plus the
        emitted frontmatter key set/order for that format (Q-A).
  - [ ] **Context-file production convention** ruled: each new provider's `project_context_file` is a
        committed profile-local file authored from the shared ~27-line template (NOT rendered from
        canonical, NOT in any `emission-manifest.jsonl`), satisfying FR2/AC2 as profile data; the
        verified ground truth (no canonical context source; existing-3 files hand-authored/un-rendered)
        and the OOS/byte-identical-gate rationale are recorded, with the ratifiable-emitter note (Q-J).
- [ ] The colleague's-fork status is recorded explicitly (proceeded docs-only, per STATE.md Q1).
- [ ] A downstream implementer can build `profiles/copilot-cli.toml` and `profiles/antigravity.toml`
      (plus any named engine extension) **from this doc alone**, without re-researching either
      tool's conventions.

### Out of Scope (this feature)

- Writing any `profiles/*.toml`, any renderer code, or any setup-script change — those are
  feature-002/003/004. This feature only **decides and documents**.
- Changing canonical source or the existing 3 profiles.
