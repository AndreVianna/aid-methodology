# Google Antigravity Render Profile

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-31 | Drafted from REQUIREMENTS during FEATURE-DECOMPOSITION | /aid-interview |
| 2026-05-31 | Technical Specification drafted | /aid-specify |
| 2026-05-31 | Specify review fixes (ledger spec-feature-003) | /aid-specify |
| 2026-05-31 | Specify review fix R2 (ledger #7) | /aid-specify |
| 2026-05-31 | Context-file → profile-local convention; de-brittle cross-refs (post-specify review) | /aid-specify |
| 2026-05-31 | FR1 loopback: skills→.agent/skills/ [data] (native); sub-agents→.agent/rules/ reshape reuses E1 format-branch mechanism; AGENTS.md/.md per Q-H/Q-I | /aid-execute |
| 2026-05-31 | Fix: extras.rules literals match disk (aid-review = glob trigger, not always-on); frontmatter-list consistency | /aid-execute |

## Source

- REQUIREMENTS.md §4 (Antigravity render profile), §5 FR3, §8 (Antigravity ≈ Cursor assumption), §9 AC3, §10 priority 2 (lower-risk)

## Description

Add `profiles/antigravity.toml` and the canonical→Antigravity emission so `run_generator.py`
produces a Google Antigravity install tree from canonical, **modeled on the existing cursor
profile** (Antigravity shares the Windsurf / VS-Code-fork lineage). Per the feature-001 mapping
(`provider-mapping.md`, delivery-001 — Antigravity column + Q-A..Q-J):

- **Skills → `.agent/skills/<slug>/SKILL.md` as `[data]`** (FR1 Q-D / §B.4). Antigravity has a
  **native first-class Skills primitive** whose `SKILL.md` (`name`+`description`) is the same shape
  AID skills already have. AID skills map via a **folder copy** — the existing `render_skills.py`
  folder pass pointed at `skills_dir = "skills"` (→ `.agent/skills/<slug>/SKILL.md` + `references/`),
  exactly as cursor/copilot emit skills. **This reverses the original SPEC's skills→`.agent/workflows/`
  cross-kind route** (which had reused feature-002's now-deleted E2). No cross-kind engine, no
  `[skill].emit_as` knob — skills are plain `[data]`.
- **Sub-agents → `.agent/rules/<name>.md` as `[transform:engine]`** (FR1 Q-D). AID's 22 sub-agents
  have **no native Antigravity sub-agent home** (§B.5), so they live as **rules**: a frontmatter
  **reshape** dropping/replacing the AGENT `name/description/tools/model` set with rule frontmatter
  (`trigger:` / `description` / `globs`) into `.md` rule files; the Markdown body carries over. This
  is the **one** engine increment for this feature — a new `agent.format` value for Antigravity rules
  (distinct from Copilot's `copilot-agent`), reusing the **new-agent-format-branch mechanism
  feature-002's E1 introduces** in `_render_agent_for_profile`.
- **Context/instructions → profile-local committed `AGENTS.md`** (FR1 Q-H / Q-J — authored, not
  emitted). `GEMINI.md` is also read by Antigravity but is reserved for tool-specific overrides AID
  does not author; `AGENTS.md` is the cross-tool canonical pick.

**Context-file convention (ground truth).** `canonical/` has **no** context source: the existing
three profiles' `AGENTS.md`/`CLAUDE.md` are **hand-authored committed files**, NOT rendered, and
absent from every `emission-manifest.jsonl` (REQUIREMENTS §4 OOS forbids adding a new canonical
source or changing the existing 3). Antigravity follows the same convention (FR1 Q-J is the
convention authority): its context file is **`AGENTS.md`** (FR1 Q-H, single definite pick — the
open cross-tool standard AID already emits for codex/cursor), a **profile-local committed file**
living in `profiles/antigravity/` as profile-tree data (exactly like the codex/cursor profiles'
committed context files), **NOT rendered by `run_generator.py` and NOT recorded in the manifest**.
Therefore the byte-identical render-drift gate is unaffected, and AC3's "context as `AGENTS.md`" is
satisfied by committing that profile-local data — there is no emission path for it.

**Dependency (precise, from FR1 Q-D).** "Modeled on cursor" is not a clean copy: in the cursor
renderer, rules come from a *separate* `canonical/rules/` source (`extras.rules`), **not** from
canonical sub-agents — so `sub-agents → .agent/rules/` is a frontmatter-reshape route the engine
does not do today. **feature-003 DEPENDS ON feature-002** for exactly one reason: the sub-agents→rules
reshape **reuses the new-agent-format-branch mechanism feature-002's E1 introduces** in
`_render_agent_for_profile` (a per-format frontmatter emitter + a widened `_KNOWN_AGENT_FORMATS` +
format-driven routing). feature-003 adds **another** `agent.format` value (e.g. `"antigravity-rule"`)
on top of that mechanism — it does **NOT** reuse E1's Copilot `.agent.md` *output*, and it does
**NOT** reuse feature-002's deleted E2 (the old skills route). The **skills→`.agent/skills/`** half
is independent `[data]`; it is only the **sub-agents→rules** half that creates the
feature-003→feature-002 edge ⇒ **feature-002 must land before feature-003.** The transformation is
documented, not faked. Must be render-drift-clean with the existing profiles (incl. copilot-cli)
byte-identical.

## User Stories

- As an AID adopter on Google Antigravity, I want a one-command-installable AID tree of native
  `.agent/skills/` + `.agent/rules/` so I can run the AID pipeline in my tool.
- As an AID maintainer, I want the Antigravity profile modeled on the cursor profile so it reuses
  proven cursor-shaped renderer paths and is cheap to maintain.

## Priority

Must

## Acceptance Criteria

- [ ] Given canonical + `profiles/antigravity.toml`, when `python run_generator.py` runs, then it
      emits an Antigravity tree with AID skills as `.agent/skills/<slug>/SKILL.md` folders (folder
      copy via the existing `render_skills` pass, `[data]`) and sub-agents as `.agent/rules/<name>.md`
      rule files (frontmatter reshaped to `trigger:`/`description`/`globs`); the context document is
      delivered as a profile-local committed `AGENTS.md` (NOT rendered, NOT in the manifest — see
      Context-file convention).
- [ ] Given the emitted tree plus the committed profile-local `AGENTS.md`, when an Antigravity user
      installs it, then the skills are discovered as native `.agent/skills/`, the rules (both the
      reshaped sub-agents and the methodology `[[extras.rules]]` `.md` files) are in `.agent/rules/`,
      and the context document is in place.
- [ ] Given Antigravity has no custom sub-agent file (FR1 Q-D / §B.5), when sub-agents are rendered,
      then they are reshaped into `.agent/rules/*.md` with `trigger:`-style frontmatter via a new
      `agent.format` value that **reuses the new-agent-format-branch mechanism feature-002's E1
      introduces** (NOT E1's Copilot output, NOT the deleted E2); the transformation is documented,
      not faked.
- [ ] Given skills map to Antigravity's native `.agent/skills/` primitive (FR1 Q-D), when skills are
      rendered, then they emit as `SKILL.md` folders via the **existing** `render_skills` folder pass
      (`[data]`) — no cross-kind transformation is built for skills.
- [ ] Given the new profile, when the render-drift gate runs, then the Antigravity profile is
      render-drift clean and the existing profiles (claude-code, codex, cursor, and copilot-cli once
      feature-002 merges) remain byte-identical.

---

## Technical Specification

> This is a tooling/render-pipeline feature in the AID methodology repo (canonical→profiles render
> pipeline). There is no DB / HTTP API / UI. The standard Data Model / Feature Flow / Layers
> sections are replaced by render-adapted sections: a **Mapping** (modeled on cursor), the
> **Profile Data** design (`profiles/antigravity.toml`), the **Emitted Tree**, the explicit
> **Dependency** edge for /aid-plan, the **Test Plan**, and **Backward-Compat / Risk**.
>
> **FR1 is DONE — this is a loopback re-spec.** This feature consumes the Antigravity column of the
> mapping table + the Q-A..Q-J rulings produced by feature-001
> (`/home/andre.vianna/projects/AID/.aid/work-001-add-providers/research/provider-mapping.md`,
> delivery-001). The research **resolved every value this spec previously deferred**: skills are
> native `[data]` to `.agent/skills/` (Q-D — reversing the old skills→workflows route);
> sub-agents→`.agent/rules/` is the one `[transform:engine]` reshape (Q-D); context is `AGENTS.md`
> (Q-H); the rule extension is `.md` with `trigger:` frontmatter (Q-I); model tiers are the detailed
> Gemini-3 form (Q-E); `[tool_names]` is an empty map (Q-F); `[capabilities]` per Q-G
> (`stop_hook_autocontinue = false`); the dir root is `.agent/` (§B.7 ruling, plural `.agents/`
> flagged as a tutorial variation). The concrete values below are **sourced to `provider-mapping.md`
> and cited inline**, no longer marked `[FR1-owned]`. The two items the mapping leaves
> `docs-only-noted` are: (a) the exact Antigravity model id/effort tokenization (Q-E —
> `gemini-3-pro` + `reasoning_effort="high"` vs a single `gemini-3-pro-high` id), and (b) the
> `[tool_names]` empty-map (Q-F — no published tool-token map); model *identities* and the
> detailed-form *shape* are confirmed. The engine *mechanism* (a new agent-format branch reusing
> feature-002's E1 machinery) is fixed by the renderer's real shape (read for this loopback
> 2026-05-31).

### Grounding (renderer as-is, read 2026-05-31)

The pipeline is `run_generator.py` → auto-discovers every `profiles/*.toml`
(`profiles_dir.glob('*.toml')`, line 24 — so a new `profiles/antigravity.toml` is registered with
no code change), then per profile: `load_profile` + `validate` (`aid_profile.py`), five fixed passes
(`render_agents`, `render_skills`, `render_templates`, `render_canonical_scripts`, `render_recipes`),
then `verify_deterministic` + `verify_advisory`. The constraints relevant to Antigravity:

- **Skills emit as folders — pure `[data]`, reused verbatim.** `render_skills.render_skills`
  (lines 300-359) reads `canonical/skills/*/` and emits **folders** (`SKILL.md` + `references/*.md`
  [+ `scripts/*` when present]) under `_skill_output_root` = `<output_root>/<skills_dir>/<slug>/`
  (lines 126-137). Antigravity's native `.agent/skills/<slug>/SKILL.md` primitive (Q-D / §B.4) is
  the same shape, so `skills_dir = "skills"` → `.agent/skills/` drives this **unchanged** pass —
  exactly as cursor (`profiles/cursor.toml:8`) emits its `skills/` tree today. **No engine code
  touches skills** (this reverses the old skills→workflows route).
- **Cursor's `.cursor/rules/` do NOT come from sub-agents.** `render_skills._render_cursor_extras`
  (lines 261-293) reads a **separate `canonical/rules/` source** (`aid-methodology.mdc`,
  `aid-review.mdc` — verified present) listed under `[[extras.rules]]`, and copies them **verbatim**
  (`out_path = rules_out_dir / rule.filename`, line 288 — **source filename == output filename**)
  into `<output_root>/<rules_dir>/`. AID sub-agents (`canonical/agents/*/AGENT.md`) are rendered by
  `render_agents` into `<output_root>/<agents_dir>/` as `<name>.md`. **These are two distinct
  sources into two distinct dirs.** So the Antigravity mapping "AID sub-agents → `.agent/rules/`"
  is a **frontmatter reshape** the renderer does **not** do today — FR1 Q-D rules it
  `[transform:engine]` (the one engine increment, below).
- **Fixed per-kind passes; closed enums.** `render_agents` globs `canonical/agents/*/AGENT.md`
  (line 358) and emits markdown `<name>.md` into `<output_root>/<agents_dir>/` (lines 300-302) with
  the fixed frontmatter set `name, description, tools, model[, permissionMode, background]`
  (`_build_frontmatter_md` lines 104-125, dict built in `_render_agent_for_profile` lines 282-296)
  — there is no `trigger:`/`globs` emission path and no agents→rules route. `aid_profile.py`
  `_KNOWN_AGENT_FORMATS = {"markdown", "toml"}` (line 334) and `validate` rejects any other
  `[agent].format` (lines 394-398); `_KNOWN_DECOMPOSITIONS = {"references"}` (line 336). Emitting
  rule-shaped frontmatter from the agents pass therefore needs a **new `agent.format` value** — the
  same kind of widening feature-002's E1 makes for `copilot-agent` (see Renderer Increment).
- **`RuleEntry` has no `output_filename` and no `trigger` key.** `RuleEntry` (`aid_profile.py:144-150`)
  carries only `filename, always_apply, description, globs`; `_render_cursor_extras` writes the source
  file under its **own filename** (line 288). For Antigravity the methodology rules must be `.md`
  (Q-I), and the canonical source files are `aid-methodology.mdc` / `aid-review.mdc` (`.mdc`) — so a
  `.md` output name differs from the `.mdc` source name, which the verbatim-copy code **cannot
  express today**. This needs a small `RuleEntry.output_filename` addition (extension/rename support)
  — see Renderer Increment + Risk.
- **The `[data]` envelope a profile.toml can express today:** `[layout]` `output_root` + per-kind
  dirs (`agents_dir`, `skills_dir`, `templates_dir`, `recipes_dir`, `scripts_dir`, `rules_dir`) +
  `project_context_file`; `[agent].format` ∈ {markdown, toml} + `[agent.frontmatter]`; `[skill]`
  decomposition (`references` only) + frontmatter; `[model_tiers]` (simple OR detailed —
  `_parse_model_tiers` accepts both, `aid_profile.py:237-255`); `[tool_names]`; `[filename_map]`
  (3 required keys: `project_context_file`, `reviewer_output_file`, `open_questions_file`);
  `[[extras.rules]]` (filename / always_apply / globs, sourced from `canonical/rules/`);
  `[capabilities]`. Anything outside this is `[transform:engine]`.
- **Determinism contract every emitting path obeys:** write `bytes` (LF-only); apply
  `substitute_filenames` THEN `rewrite_install_paths(install_root)` to every text body (and any
  re-emitted frontmatter that can carry `canonical/<dir>/` refs); record each file in the
  `EmissionManifest` with repo-relative `src` and `common_parent`-relative `dst`. `rewrite_install_paths`
  rewrites `canonical/{scripts,templates,skills,agents,rules,recipes}/…` to `<install_root>/<dir>/…`
  using the **canonical** dir name (not the profile's `*_dir` value); `install_root()` =
  basename of `output_root` (here `.agent`).

### Mapping (modeled on cursor)

Per the feature-001 mapping (`provider-mapping.md` Antigravity column + Q-D) and REQUIREMENTS
§2/§5 FR3, the Antigravity targets are:

| AID primitive | Antigravity target | Cursor analogue | Disposition |
|---|---|---|---|
| skill (`canonical/skills/aid-*/`) | `.agent/skills/<slug>/SKILL.md` + `references/` (native Skills primitive, folder copy) | `.cursor/skills/<slug>/` folders | **`[data]`** — `skills_dir = "skills"` drives the existing `render_skills` folder pass unchanged (Q-D / §B.4) |
| sub-agent (`canonical/agents/*/AGENT.md`) | `.agent/rules/<name>.md` (AGENT frontmatter reshaped → `trigger:`/`description`/`globs`; body carries over) | NOT cursor's rules (those come from `canonical/rules/`) | **`[transform:engine]`** — frontmatter reshape; a new `agent.format` value reusing feature-002's E1 mechanism (Q-D) |
| context / instructions | profile-local committed `AGENTS.md` | existing profiles' hand-authored committed `AGENTS.md`/`CLAUDE.md` (not rendered) | **`[data]`** — profile-local committed file, NOT rendered, NOT in manifest (Q-H / Q-J) |
| AID's `canonical/rules/` (`.mdc` methodology rules) | `.agent/rules/*.md` (`.md`, NOT `.mdc`; `trigger:` frontmatter) | `.cursor/rules/*.mdc` via `[[extras.rules]]` | **`[data]`** (existing `_render_cursor_extras` path) **+ a small `RuleEntry.output_filename` touch** for the `.mdc`→`.md` rename (Q-I) |
| helper script / template / recipe | referenced home under `.agent/` (bare `scripts`/`templates`/`recipes`) | `.cursor/{scripts,templates,recipes}/` | **`[data]`** — bare-name dirs (Q-C; recipes always emitted, see note) |

**Skills are now plain `[data]`.** Antigravity has a native `.agent/skills/<slug>/SKILL.md`
primitive (Q-D / §B.4) with the same `name`+`description` frontmatter and `references/` packaging AID
skills already have, so the existing `render_skills` folder pass — pointed at `skills_dir = "skills"`
→ `.agent/skills/` — emits them unchanged, exactly as cursor/copilot do. (This **reverses** the
original SPEC's skills→`.agent/workflows/` cross-kind route, which had reused feature-002's E2;
feature-002's E2 is now deleted and Antigravity skills need no engine work at all.)

**Sub-agents → `.agent/rules/` is the one engine increment (Q-D).** In cursor, `.cursor/rules/` are
NOT sub-agents — `_render_cursor_extras` reads `canonical/rules/`, a separate source. AID sub-agents
have no native Antigravity sub-agent home (§B.5), so they must live as **rules**: the AGENT
frontmatter (`name/description/tools/model`) is dropped/replaced by rule frontmatter (`trigger:` /
`description` / `globs`) into `.md` files, body carried over. The current `render_agents` pass emits
only the hardcoded `name/description/tools/model` set and has no `trigger:`/`globs` route — so this is
`[transform:engine]`. See **Renderer Increment** for how it reuses feature-002's E1 machinery.

### Renderer Increment (one engine addition — reuses feature-002's E1 mechanism)

feature-002's **E1** introduces the **new-agent-format-branch mechanism** in
`_render_agent_for_profile`: a per-format frontmatter emitter selected by `[agent].format`, a widened
`_KNOWN_AGENT_FORMATS` (it adds `"copilot-agent"`), and format-driven routing/suffix selection.
feature-003 adds **another** `agent.format` value on top of that same mechanism — call it
**`"antigravity-rule"`** — which:

- is selected by `[agent].format = "antigravity-rule"` in `profiles/antigravity.toml`;
- emits, from the `canonical/agents/*/AGENT.md` pass, a **rule** file: a `.md` file under
  `<output_root>/<agents_dir>/` (= `.agent/rules/`) whose frontmatter is **`trigger:`** (+
  `description`, and `globs` for the glob trigger) — a **reshape** that drops the AGENT
  `name/description/tools/model` set (Antigravity rules have no `tools`/`model` frontmatter; §B.1).
  AID's always-loaded sub-agent personas map to `trigger: always_on`;
- reuses the existing canonical parse (`_parse_frontmatter`), the body treatment
  (`substitute_filenames` THEN `rewrite_install_paths`), and the manifest/determinism helpers — no
  new transform machinery beyond the format branch + a `trigger:`-frontmatter serializer;
- requires the schema/validator widening to add `"antigravity-rule"` to `_KNOWN_AGENT_FORMATS`
  (`aid_profile.py:334`) so `validate` (lines 394-398) accepts it.

**This is NOT a reuse of E1's Copilot *output*** (`.agent.md` + Copilot YAML-sequence `tools:`) — it
is a reuse of the *branch-dispatch mechanism* E1 builds, producing a **different** (rule-shaped)
frontmatter. **And it is NOT the deleted E2** (the old skills route) — skills are now `[data]`. The
dependency edge therefore survives the E2 deletion: feature-002 must land first because feature-003's
sub-agents→rules reshape rides on E1's format-branch machinery.

**Plus the small `[[extras.rules]]` extension touch** (Q-I): `_render_cursor_extras` copies rules
verbatim (source name == output name, `render_skills.py:288`), but Antigravity wants `.md` while the
canonical source is `.mdc`. A `RuleEntry.output_filename` field (`aid_profile.py` `RuleEntry` +
`_parse_extras`, plus the `out_path` change in `render_skills.py:288`) lets the `.mdc` source emit as
`aid-methodology.md`. This is a tiny, default-preserving addition (cursor leaves `output_filename`
unset → source name preserved, so cursor stays byte-identical).

> **/aid-plan signal:** Always order feature-003 after feature-001 (mapping) and **after feature-002**
> — feature-003's sub-agents→rules reshape reuses the new-agent-format-branch mechanism feature-002's
> E1 introduces. The skills→`.agent/skills/` half is independent `[data]` and creates no edge; it is
> only the sub-agents→rules half that makes the feature-002 edge. feature-002's E2 (the old skills
> cross-kind route) is **deleted** and is **not** the basis of this edge.

### Profile Data — `profiles/antigravity.toml` (modeled on cursor.toml)

Single-root layout like cursor. `output_root = "profiles/antigravity/.agent"` →
`install_root()` basename `.agent`. The **keys** are fixed by the existing schema; the concrete
literals are **sourced to `provider-mapping.md`** (FR1 is done) and cited to their ruling. The two
items the mapping leaves `docs-only-noted` (the model id/effort tokenization and the empty
`[tool_names]`) are flagged inline.

```toml
# Profile: Google Antigravity (Windsurf lineage; VS Code-fork like Cursor)
# Encodes the Antigravity host tool's install conventions (REQUIREMENTS §2; FR1 mapping
# provider-mapping.md — Antigravity column). Modeled on profiles/cursor.toml.

[layout]
output_root          = "profiles/antigravity/.agent"   # install_root() basename = ".agent" (§B.7: .agent singular; plural .agents/ is a tutorial variation)
agents_dir           = "rules"                          # sub-agents reshaped → .agent/rules/*.md (Q-D; engine increment). Shares rules_dir — disjoint stems, see collision note.
skills_dir           = "skills"                          # skills → .agent/skills/<slug>/ folders (native Skills primitive, Q-D/§B.4; existing render_skills pass, [data])
templates_dir        = "templates"                       # bare name → .agent/templates/ (Q-C; matches rewrite_install_paths)
# scripts_dir intentionally unset → schema default "scripts" → .agent/scripts/ (bare name keeps body-link rewrite in agreement; Q-C)
recipes_dir          = "recipes"                          # bare name → .agent/recipes/ (always emitted; see recipes note below)
rules_dir            = "rules"                            # .agent/rules/ — target of [[extras.rules]] methodology .md rules
project_context_file = "AGENTS.md"                       # AGENTS.md (Q-H, single pick). NB: a filename-substitution token only (for refs inside OTHER rendered bodies); the AGENTS.md doc itself is a profile-local committed file, NOT emitted — see Context-file convention.

[agent]
# Antigravity sub-agents reshape into .agent/rules/*.md with trigger:-style frontmatter (Q-D).
# New agent-format value reusing feature-002's E1 new-agent-format-branch mechanism (NOT E1's
# copilot-agent output, NOT the deleted E2). Requires _KNOWN_AGENT_FORMATS widening.
format = "antigravity-rule"

[agent.frontmatter]
# Antigravity rule frontmatter is trigger:/description/globs (§B.1) — NOT name/description/tools/model.
# The reshape is performed by the antigravity-rule format branch (engine); these lists are
# parsed-but-dead-for-emission (provider-mapping.md §"[agent.frontmatter] lists are parsed but dead
# for emission") and do NOT drive the reshape. Values kept structurally valid + documentary only.
required = ["trigger", "description"]
optional = ["globs"]

[skill]
decomposition = "references"
# No emit_as knob — skills are native .agent/skills/ folders via the existing pass (Q-D). [data].

[skill.frontmatter]
# Antigravity/AID-native SKILL.md required pair is name+description (Q-D/§B.4); license/allowed-tools
# are optional. These lists are dead-for-emission for skills — render_skills preserves the canonical
# frontmatter verbatim — but kept consistent with the stated native shape.
required = ["name", "description"]
optional = ["allowed-tools", "argument-hint"]

[model_tiers.large]                                      # detailed form (Q-E); Gemini-3 lineage. id/effort tokenization docs-only-noted (Q-E).
model            = "gemini-3-pro"
reasoning_effort = "high"
[model_tiers.medium]
model            = "gemini-3-pro"
reasoning_effort = "low"
[model_tiers.small]
model            = "gemini-3-flash"
reasoning_effort = "low"                                 # small tier has no documented effort variant; placeholder effort so ModelTierDetailed.reasoning_effort is non-empty (validator requires it) — confirm with Q-E tokenization

[tool_names]                                             # Q-F: empty map — identity passthrough (no published Antigravity tool-token map; docs-only-noted)

[filename_map]                                           # 3 keys required by validator
project_context_file = "AGENTS.md"                       # Q-H
reviewer_output_file = "STATE.md"
open_questions_file  = "additional-info.md"

# [[extras.rules]] — reuse the cursor _render_cursor_extras path to place AID's methodology rules
# into .agent/rules/. Q-I: Antigravity rules are .md (NOT .mdc) with trigger: frontmatter (NOT
# alwaysApply:). Because the canonical sources are .mdc, the OUTPUT name must differ from the source
# name — needs RuleEntry.output_filename (small renderer touch, see Renderer Increment).
# NB: the always_apply/globs VALUES below mirror each canonical .mdc's actual frontmatter (disk truth):
#   aid-methodology.mdc → alwaysApply: true,  no globs        → trigger: always_on
#   aid-review.mdc      → alwaysApply: false, globs: "**/*.{java,py,ts,js,cs,go,rs}" → trigger: glob (globs preserved)
# These per-rule literals are ILLUSTRATIVE of the source-to-trigger mapping; the exact trigger-shape
# injection (translating alwaysApply:/globs: in the .mdc bodies into Antigravity trigger: frontmatter)
# is deferred to /aid-plan (task). Values here MUST match disk truth even as illustration.
[[extras.rules]]
filename        = "aid-methodology.mdc"                  # canonical source (in canonical/rules/)
output_filename = "aid-methodology.md"                   # Q-I: .md output (NEW RuleEntry field; cursor omits it → source name preserved)
description     = "AID methodology workflow and Knowledge Base integration"
always_apply    = true                                  # disk: alwaysApply: true → emitted as trigger: always_on by the .md rule serializer (Q-I)
globs           = []                                     # disk: aid-methodology.mdc carries no globs

[[extras.rules]]
filename        = "aid-review.mdc"
output_filename = "aid-review.md"                        # Q-I
description     = "Code review standards for AID methodology"
always_apply    = false                                 # disk: alwaysApply: false → NOT always_on; emitted as trigger: glob (Q-I)
globs           = ["**/*.{java,py,ts,js,cs,go,rs}"]      # disk: aid-review.mdc globs: "**/*.{java,py,ts,js,cs,go,rs}" — preserved, drives the glob trigger

[capabilities]                                           # Q-G
hooks                  = true
skill_chaining         = true
background_execution   = true
stop_hook_autocontinue = false                           # Q-G: no documented stop-hook auto-continue loop (matches cursor's pinned value)
```

> **Validator note (model_tiers detailed form).** `_parse_model_tiers` (`aid_profile.py:237-255`)
> maps a `[model_tiers.<tier>]` sub-table to `ModelTierDetailed(model, reasoning_effort)`, and
> `validate` (lines 426-434) requires **both** `model` and `reasoning_effort` non-empty for a
> detailed tier. The mapping's Q-E small tier (`gemini-3-flash`) lists no reasoning_effort; a
> non-empty placeholder is therefore required to pass `validate()`, and the exact id/effort
> tokenization is the `docs-only-noted` residual (Q-E) to confirm before the literals are pinned.

**`rewrite_install_paths` dir-name caveat (same as feature-002).** The rewriter keys off the
*canonical* dir name, not the profile's `*_dir`. So `canonical/scripts/…` always rewrites to
`.agent/scripts/…`. The TOML above intentionally **omits** `scripts_dir`, so it takes the schema
default `"scripts"` (`aid_profile.py:41`) — bare `scripts` under `.agent/`, which keeps body
references resolving; `templates_dir` is likewise the bare `templates` (Q-C). A deeper home (e.g.
`.agent/aid/scripts/`) would require touching `rewrite_install_paths` — out of scope, discouraged.

**`[[extras.rules]]` extension touch (Q-I) — REQUIRED for Antigravity.** Unlike cursor (which keeps
`.mdc` verbatim, source name == output name), Antigravity needs `.md` rules (Q-I), so the OUTPUT
filename must differ from the canonical `.mdc` source name. The verbatim-copy code today
(`out_path = rules_out_dir / rule.filename`, `render_skills.py:288`) cannot do this. This feature adds
an optional `RuleEntry.output_filename` (`aid_profile.py` `RuleEntry` + `_parse_extras`), used by
`_render_cursor_extras` when set; cursor leaves it unset → byte-identical. The frontmatter inside the
rule (cursor's `alwaysApply:`/`globs:` vs Antigravity's `trigger:`, per-rule: aid-methodology →
`trigger: always_on`, aid-review → `trigger: glob` with its glob) is a property of the
methodology rule files themselves; if the canonical `.mdc` sources carry cursor's `alwaysApply:` form,
a `.md` Antigravity variant of the rule bodies is also profile-local data (the source files differ),
NOT a verbatim copy — flag for /aid-plan whether a separate Antigravity rule source is needed or the
`trigger:` shape is injected by the touch.

**Same-dir co-location — `agents_dir = "rules"` and `rules_dir = "rules"` (resolved, not a risk).**
Both the reshaped sub-agents and the `[[extras.rules]]` methodology files land in the **same**
`.agent/rules/` dir — which FR1 Q-D explicitly intends (sub-agents live as rules). `render_agents`
writes each sub-agent as `<name>.md` (`render_agents.py:300-302`) and `_render_cursor_extras` writes
each methodology rule as its `output_filename` (`render_skills.py:288`). There is **no collision
guard** in the renderer (last-writer-wins by path), but the names are disjoint: sub-agents are
`architect.md`, `developer.md`, … (persona stems) while the methodology rules are `aid-methodology.md`
/ `aid-review.md` (`aid-` prefixed). Q-D confirms the shared dir; the disjoint-stem invariant should
be asserted by the render_agents/render_skills self-tests (no `<name>.md` equals a methodology rule
output name).

**Recipes are always emitted (no opt-out today).** `render_recipes` runs unconditionally for every
profile and only no-ops when `canonical/recipes/` is absent — it is present and non-empty, and
`recipes_dir` is only a destination-name knob (`aid_profile.py` `LayoutConfig.recipes_dir`), not a
suppression switch. `render_recipes` copies **every non-hidden file** under `canonical/recipes/`
(currently 6 `.md` files — 5 recipes + `README.md`; the hidden `.gitkeep` is skipped). There is
**no `[omit]` mechanism** in the schema. So `profiles/antigravity/` **will** contain `.agent/recipes/`
with every file under `canonical/recipes/`. (The mapping rules recipes `[omit]` semantically — they
are an `/aid-interview` input artifact, not a host-tool primitive — but the renderer has no
suppression knob, so they are emitted as harmless data; adding suppression would be a separate engine
knob, out of scope.)

### Emitted Tree — `profiles/antigravity/...`

```
profiles/antigravity/
├── emission-manifest.jsonl            # common_parent() = profiles/antigravity
├── AGENTS.md                          # profile-local COMMITTED context file — NOT rendered, NOT in emission-manifest.jsonl (Q-H/Q-J, like the existing profiles' context files)
└── .agent/                            # install_root = .agent
    ├── rules/                          # agents_dir == rules_dir == "rules" (Q-D: sub-agents live as rules)
    │   ├── aid-methodology.md          # methodology rule (canonical/rules/aid-methodology.mdc → .md via output_filename + [[extras.rules]]; Q-I)
    │   ├── aid-review.md               # methodology rule (.md, Q-I)
    │   ├── architect.md                # 22 AID sub-agents reshaped → rules (trigger:/description/globs frontmatter; engine increment)
    │   ├── developer.md
    │   └── … (20 more sub-agent rule files)
    ├── skills/                         # 10 AID skills → native .agent/skills/ folders (folder copy, [data], Q-D/§B.4)
    │   ├── aid-specify/
    │   │   ├── SKILL.md
    │   │   └── references/*.md
    │   ├── aid-config/                 # zero-reference skill: SKILL.md only (matches render_skills today)
    │   │   └── SKILL.md
    │   └── … (8 more)
    ├── scripts/                        # canonical/scripts/** (bare-name home; rewrite-compatible)
    ├── templates/                      # canonical/templates/**
    └── recipes/                        # canonical/recipes/** (every file: 5 recipes + README.md; always emitted — no omit knob)
```

Only the `.agent/` subtree above is emitted/manifested by `run_generator.py`. The profile-local
`AGENTS.md` is a committed file alongside the profile (Q-H/Q-J), not a render output. The 22 reshaped
sub-agent rules and the 2 methodology rules co-locate in `.agent/rules/` with disjoint stems (the
`aid-` prefix on methodology rules vs persona stems on sub-agents), per the co-location note above.

### Dependency (explicit, for /aid-plan)

- **Depends on feature-001 (mapping) — ALWAYS, and SATISFIED.** `provider-mapping.md` (delivery-001)
  has answered the Antigravity column + Q-D (skills `[data]` to `.agent/skills/`; sub-agents→rules
  `[transform:engine]`), Q-H (`AGENTS.md`), Q-I (`.md` rules + `trigger:`), Q-E (detailed model
  tiers), Q-F (empty `[tool_names]`), Q-G (capabilities), §B.7 (`.agent/` dir).
- **Depends on feature-002 (E1 new-agent-format-branch mechanism) — for the sub-agents→`.agent/rules/`
  reshape.** feature-003's `"antigravity-rule"` agent-format **reuses the per-format frontmatter
  emitter + the widened `_KNOWN_AGENT_FORMATS` + the format-driven routing that feature-002's E1
  introduces** in `_render_agent_for_profile`. feature-003 does **NOT** reuse E1's Copilot
  `.agent.md` *output*, and does **NOT** reuse feature-002's now-deleted E2 (the old skills
  cross-kind route). Because the reshape rides on E1's machinery, **feature-002 must land before
  feature-003.**
- **The skills→`.agent/skills/` half is independent `[data]`** (Q-D) — it creates no feature-002
  edge. The feature-003→feature-002 edge exists **solely** because of the sub-agents→rules reshape.
- **Small `RuleEntry.output_filename` touch (Q-I)** is feature-003-owned engine work (a tiny,
  default-preserving schema+renderer addition), not attributed to feature-002.

### Test Plan

1. **`aid_profile` validator** — `profiles/antigravity.toml` loads + `validate()` returns no errors:
   3 `filename_map` keys present; `[agent].format = "antigravity-rule"` is accepted by the widened
   `_KNOWN_AGENT_FORMATS`; an unknown `[agent].format` value is rejected; `[skill].decomposition =
   "references"` valid; the **detailed** `[model_tiers.<tier>]` sub-tables each validate (both
   `model` and `reasoning_effort` non-empty — `aid_profile.py:426-434`). The exact Gemini id/effort
   tokenization is the Q-E `docs-only-noted` residual: the profile validates *structurally* as
   written; confirm the literal before functional correctness. The 3 existing profiles (claude-code,
   codex, cursor) still validate clean (defaults unchanged).
2. **`render_agents` self-test (the sub-agents→rules reshape)** — `python render_agents.py
   --self-test` green for all profiles incl. `antigravity` (auto-discovered): two renders
   byte-identical; for `antigravity` the 22 sub-agents emit as `<name>.md` rule files under
   `.agent/rules/` whose frontmatter is `trigger:`/`description`(/`globs`) — NOT
   `name/description/tools/model`; each emitted frontmatter block round-trips through a YAML parse.
   The 3 existing profiles' agent output (+copilot-cli once feature-002 merges) is **byte-identical**
   across the run (the `antigravity-rule` branch is selected only by `antigravity`).
3. **`render_skills` self-test (skills as `[data]` folders + the `output_filename` rule touch)** —
   `python render_skills.py --self-test` green for all profiles incl. `antigravity`: the 10 skills
   emit as **10 `SKILL.md` folders** under `.agent/skills/` (the same folder shape cursor emits), not
   as workflows; a multi-reference skill emits `SKILL.md` + `references/*.md`; the zero-reference skill
   emits `SKILL.md` only. The `[[extras.rules]]` methodology rules land under `.agent/rules/` as
   `aid-methodology.md` / `aid-review.md` (`.md`, via `output_filename`). The pre-existing profiles'
   skill output (cursor's `.mdc` rules included — `output_filename` unset → source name preserved) is
   **byte-identical** to before.
4. **Disjoint-stem assertion** — no reshaped sub-agent rule output name (`<name>.md`) equals a
   methodology rule output name (`aid-methodology.md`/`aid-review.md`) in the shared `.agent/rules/`
   dir (the renderer has no collision guard; the test asserts the invariant Q-D relies on).
5. **Render-drift clean for the new profile** — `python run_generator.py` emits `antigravity` with
   no errors; `verify_deterministic` PASS (byte-identical re-render + manifest presence audit: no
   missing/extra files for `antigravity`).
6. **Existing profiles byte-identical** — `profiles/{claude-code,codex,cursor}/` trees + their
   `emission-manifest.jsonl` are byte-identical before vs after this feature (git diff shows zero
   changes under those subtrees). If feature-002 has merged, `profiles/copilot-cli/` is likewise
   byte-identical. This is a gate, not a final-only check.
7. **Canonical suites green** — existing generator self-tests (`render_lib`, `render_templates`,
   `render_canonical_scripts`, `render_recipes`) and `verify_advisory` continue to pass unchanged.

### Backward-Compat / Risk

- **Scope is one engine increment + one small touch.** The `"antigravity-rule"` agent-format (the
  sub-agents→rules reshape, reusing E1's mechanism) + the `_KNOWN_AGENT_FORMATS` widening + the
  `RuleEntry.output_filename` touch. Skills, context, scripts/templates/recipes are all `[data]`.
  The old two-branch (pure-data vs cross-kind) framing and the skills→flat-workflows route are gone
  (skills are native `[data]`).
- **Existing profiles unchanged.** Every addition is default-guarded: `[agent].format =
  "antigravity-rule"` is set only by `antigravity` (claude-code/cursor stay `markdown`, codex stays
  `toml`); `RuleEntry.output_filename` is unset for cursor (→ source name preserved, byte-identical);
  the `_KNOWN_AGENT_FORMATS` edit is additive. Only `antigravity` opts in → other profiles
  byte-identical (gate #6).
- **"≈cursor" assumption (REQUIREMENTS §8) — confirmed-with-corrections by FR1 (§B.6).** Antigravity
  is a VS-Code fork with always-on/glob/model-decision rule files; the corrections are
  `.agent/` (not `.cursor/`), `.md` + `trigger:` (not `.mdc` + `alwaysApply:`), native
  `.agent/skills/`, and no sub-agent file. The profile is cursor-modeled but is a
  rename-dir + change-extension + change-frontmatter-key + reshape-sub-agents adaptation, not a
  byte-clone — all of which this spec accounts for.
- **Methodology-rule frontmatter shape (open).** Q-I says Antigravity rules use `trigger:` (per-rule:
  `always_on` for aid-methodology, `glob` for aid-review), not cursor's `alwaysApply:`/`globs:`. If the
  canonical `canonical/rules/*.mdc` bodies embed cursor's
  `alwaysApply:` frontmatter, an Antigravity `.md` variant of those rule bodies is also profile-local
  data (different source), not a pure `output_filename` rename. /aid-plan should size whether the
  touch injects the `trigger:` shape or a separate Antigravity rule source is committed. (The
  sub-agents→rules reshape itself already emits `trigger:` frontmatter via the engine branch.)
- **`docs-only-noted` residuals (Q-E, Q-F).** The exact Gemini model id/effort tokenization
  (`gemini-3-pro` + `reasoning_effort` vs a fused `gemini-3-pro-high` id) and the empty
  `[tool_names]` (no published Antigravity tool-token map) are the two items the mapping leaves to
  confirm against a vendor reference before pinning the literals; the detailed-form *shape* and the
  passthrough *behavior* are correct.
- **No new runtime dependencies.** The `antigravity-rule` branch + the `output_filename` touch use
  only Python stdlib + the existing renderer helpers; no pip/npm. New profile is auto-discovered
  (`run_generator.py` globs `profiles/*.toml`).
