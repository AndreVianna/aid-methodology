# GitHub Copilot CLI Support (Profile + Renderer Extension)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-31 | Drafted from REQUIREMENTS during FEATURE-DECOMPOSITION (merged renderer-extension + profile per decomposition review) | /aid-interview |
| 2026-05-31 | Technical Specification drafted | /aid-specify |
| 2026-05-31 | Specify review fixes (ledger spec-feature-002) | /aid-specify |
| 2026-05-31 | Context-file → profile-local convention; altitude trim + de-brittle (post-specify review) | /aid-specify |
| 2026-05-31 | FR1 loopback: drop E2 (skills now native) + E3 (MCP omit); keep E1; skills→native Agent Skills [data] | /aid-execute |
| 2026-05-31 | Fix: recipes [omit]→[data] (render_recipes is unconditional; emit like existing profiles); keeps E1-only | /aid-execute |

## Source

- REQUIREMENTS.md §2 (impedance mismatch), §4 (Copilot CLI render profile), §5 FR2, §6 (NFR: dependency-free, convention over infrastructure), §7, §9 AC2, §10 priority 2 (higher-risk)

## Description

Add full GitHub Copilot CLI support to the canonical→profiles pipeline: `profiles/copilot-cli.toml`
**plus the narrow renderer extension it requires**, so `run_generator.py` emits a complete Copilot
CLI install tree from the single canonical source. (Per the decomposition review, the engine work
and its sole consumer ship together — the engine change is a task inside this feature, not a
separate feature.)

**The FR1 research (`provider-mapping.md`, delivery-001) overturned the premise this SPEC was first
built on.** GitHub Copilot CLI shipped a **native Agent Skills primitive** (`SKILL.md` folders;
reads `.github/skills/`, `.claude/skills/`, `.agents/skills/`) on 2025-12-18, after the requirements
interview. The mismatch this feature must bridge therefore **narrowed sharply** and the scope
**shrank** (see Backward-Compat / Risk):

Using the feature-001 mapping (Copilot column):

- **Sub-agents → Copilot custom agents.** AID's 22 sub-agents have **no native-skill home**; they
  map to Copilot custom agents at `.github/agents/<name>.agent.md` (Markdown + Copilot YAML
  frontmatter; invocable via `/agent`, `--agent`, or inference). This is the **one renderer code
  addition** (E1) — see Renderer Extension.
- **Skills → Copilot native Agent Skills, as `[data]`** (FR1 Q-A). AID skills map to Copilot Agent
  Skills via a **folder copy** — the existing `render_skills.py` folder pass pointed at the Copilot
  skills home, **exactly like the cursor profile emits skills as folders today**
  (`skills_dir = "skills"` → `render_skills` writes `<root>/<skills_dir>/<slug>/SKILL.md` +
  `references/`). The SKILL.md required pair (`name`, `description`) already matches Copilot's. **No
  cross-kind engine, no `[skill].emit_as` knob** — this reverses the original SPEC's E2.
- **Context/instructions → profile-local committed `AGENTS.md`** (the codex/cursor convention,
  feature-001 Q-J — authored, not emitted).
- **MCP → `[omit]`** (FR1 Q-B). The repo ships **no** MCP servers, so **no `mcp-config.json` is
  emitted** — this drops the original SPEC's E3.
- **Helper scripts / templates → `[data]`** via bare `scripts_dir`/`templates_dir` under the install
  root (FR1 Q-C).
- **Recipes → `[data]`** — the existing `render_recipes` pass runs **unconditionally** for every
  profile (`run_generator.py:45`; `recipes_dir` defaults to `"recipes"`, `aid_profile.py:40`), so
  copilot-cli emits `recipes/` under the install root (`.github/recipes/`) exactly like the 3 existing
  profiles do today (cursor → `.cursor/recipes/`, codex → `.agents/recipes/`, claude-code →
  `.claude/recipes/`). No engine change and no pass-selection mechanism is involved — recipes are
  referenced files carried as data.

**The renderer extension is now exactly E1** (the NFR demands "add profiles as data + mappings, not
a new render engine"): a single new `.agent.md` agent-format emitter for sub-agents, plus the schema
widening to register the new `agent.format` value. **E2 and E3 are NOT built** (FR1 Q-A rules skills
are native; Q-B rules MCP `[omit]`) — see Renderer Extension. Everything else (skills, context,
scripts/templates home) is **`[data]`** expressed in `profiles/copilot-cli.toml` + the profile-local
committed `AGENTS.md`. Today the engine still can't express the sub-agent emission (`.agent.md`
suffix + Copilot frontmatter; `_KNOWN_AGENT_FORMATS = {markdown, toml}`), so the tightly-scoped E1
addition is required and justified; the rest is reachable as data.

This is the higher-risk profile. It must be render-drift-clean, and the existing 3 profiles must
stay **byte-identical from this feature onward** (continuous gate, not a final check).

## User Stories

- As an AID adopter on GitHub Copilot CLI, I want a one-command-installable AID tree where the
  sub-agents are invocable as custom agents, the skills are picked up as native Agent Skills, and
  the instructions are in place so I can run the AID pipeline in my tool.
- As an AID maintainer, I want Copilot CLI to be a `profiles/<tool>.toml` consuming canonical (with
  a narrow, justified engine addition) so I maintain it like the existing three profiles — not a
  forked render engine.

## Priority

Must

## Acceptance Criteria

- [ ] Given canonical + `profiles/copilot-cli.toml`, when `python run_generator.py` runs, then it
      emits a Copilot CLI tree with AID sub-agents as `.agent.md` agent files carrying valid Copilot
      frontmatter at `.github/agents/`, and AID skills as `SKILL.md` folders under the Copilot skills
      home (folder copy, the same shape `render_skills` emits for cursor today).
- [ ] Given the emitted tree plus the profile-local committed `AGENTS.md`, when a Copilot CLI user
      installs it, then sub-agents are invocable as custom agents, skills are discovered as native
      Agent Skills, and the instructions (`AGENTS.md`) are in place. **No `mcp-config.json` is
      emitted** (FR1 Q-B: AID ships no MCP servers → `[omit]`).
- [ ] Given Copilot's native Agent Skills primitive (FR1 Q-A), when skills are rendered, then they
      emit as `SKILL.md` folders via the **existing** `render_skills` folder pass (`[data]`) — no
      cross-kind skill→agent transformation is built, and the original SPEC's E2 is dropped.
- [ ] Given the NFR, when the renderer is extended, then the change is a **narrow** addition (one
      `.agent.md` sub-agent emitter + the `agent.format` schema widening) using only Python stdlib +
      bash — not a generic transform framework, and covered by a generator self-test. **E2 (cross-kind
      route) and E3 (MCP emitter) are not built.**
- [ ] Given the existing 3 profiles, when `run_generator.py` runs after this feature, then their
      emitted trees + manifests are **byte-identical** to before (VERIFY deterministic passes); the
      new Copilot profile is render-drift clean.

---

## Technical Specification

> This is a tooling/render-pipeline feature in the AID methodology repo. There is no DB / HTTP API
> / UI. The standard Data Model / Feature Flow / Layers sections are replaced by the
> renderer-adapted sections below: a **Renderer Extension** design (the narrow engine additions),
> a **Profile Data** design (`profiles/copilot-cli.toml`), the **Emitted Tree**, the explicit
> **Data-vs-Engine split**, the **Test Plan**, and **Backward-Compat / Risk**.
>
> **FR1 is DONE — this is a loopback re-spec.** This feature consumes the Copilot column of the
> mapping table produced by feature-001
> (`/home/andre.vianna/projects/AID/.aid/work-001-add-providers/research/provider-mapping.md`,
> delivery-001). The research **overturned the premise** the first draft rested on (Copilot "has no
> skill/slash primitive"): Copilot now ships native Agent Skills, so skills are `[data]` (FR1 Q-A)
> and MCP is `[omit]` (FR1 Q-B). The concrete values below (frontmatter field mapping, scripts/
> templates home, model-tier strings, tool-name remaps, capabilities) are **no longer deferred** —
> they are sourced to `provider-mapping.md` and cited inline. The **one residual** the mapping marks
> `docs-only-noted` is the exact Copilot model-slug spelling (`model: claude-opus-4.8` vs a
> display-name form — provider-mapping.md §0 / Q-E); the model *identities* (Opus 4.8 / Sonnet 4.6 /
> Haiku 4.5) are LIVE-confirmed. The engine *mechanism* (E1) is fixed by the renderer's real shape
> (read at spec time + re-confirmed for this loopback 2026-05-31).

### Grounding (renderer as-is, read 2026-05-31)

The render pipeline is `run_generator.py` → for each `profiles/*.toml`: `load_profile` +
`validate` (`aid_profile.py`), then the fixed live-emit passes in `run_generator.py`
(`render_agents`, `render_skills`, `render_templates`, `render_canonical_scripts`,
`render_recipes`), then `verify_deterministic` + `verify_advisory`. This feature touches **only**
`render_agents` (E1) and the `aid_profile` schema/validator — it adds **no new pass**, so the
multi-pass-list wiring concerns that scoped the original E3 no longer apply (E3 is dropped, FR1
Q-B). The constraints this feature must work within:

- `aid_profile.py` `_KNOWN_AGENT_FORMATS = {"markdown", "toml"}` (line 334); `validate` rejects any
  other `[agent].format` value (lines 394-398). **E1 widens this enum** (adds `"copilot-agent"`).
- `render_agents.py` `_build_frontmatter_md` (lines 104-125) has only `bool` and `str` branches;
  the per-agent field dict is built in `_render_agent_for_profile` with the fixed key order
  `name, description, tools, model` (lines 282-287), then `permissionMode` / `background` only when
  present in canonical (lines 289-295). Crucially, `tools` is set from `_remap_tools(...)`
  (line 279), which returns a **comma-separated string** (`", ".join(...)`, `render_agents.py:173`),
  so `_build_frontmatter_md` serializes it through the `str` branch (line 114) — a scalar, not a
  YAML sequence. The terminal `else` branch (line 122-123) emits a Python `repr` for any list value,
  which is invalid YAML. **Consequence for E1:** to emit Copilot's documented list-valued `tools:`
  as a YAML sequence, the Copilot branch must build a *list* value and add a **YAML-list serializer**
  (`_build_frontmatter_md` as-is cannot produce a valid sequence).
- `render_agents.render_agents` globs exactly `canonical/agents/*/AGENT.md`;
  `render_skills.render_skills` reads exactly `canonical/skills/*/` and emits **folders**
  (`SKILL.md` + `references/*.md` [+ `scripts/*` when present]) under `<root>/<skills_dir>/<slug>/`
  (`render_skills.py:300-359`, output path via `_skill_output_root`, lines 126-137). **This
  folders-emission is exactly what the Copilot skills mapping reuses, unchanged:** the cursor profile
  already drives it with `skills_dir = "skills"` (`profiles/cursor.toml:8`) to emit `SKILL.md`
  folders. Copilot's profile points `skills_dir` at Copilot's skills home; skills are therefore
  `[data]` (FR1 Q-A) and **no cross-kind route is needed** — the original SPEC's E2 is dropped.
- **No pass emits `project_context_file` to the adopter repo root, and none is needed (verified
  2026-05-31).** `project_context_file` is used by exactly one mechanism: `substitute_filenames`
  (`render_lib.py`) replaces the `{project_context_file}` token inside bodies with the profile's
  filename (e.g. `AGENTS.md`). It is **not** the source of a written context document. Grepping all
  five render passes for `project_context_file` finds zero writers, and `canonical/` carries no
  context/instructions source to render one from. The `profiles/claude-code/CLAUDE.md`,
  `profiles/cursor/AGENTS.md`, `profiles/codex/AGENTS.md` files that exist on disk are
  **hand-authored and git-committed** (commit `bf4e814`), are **absent from every
  `emission-manifest.jsonl`**, and are produced by no pass. FR2's "context → `AGENTS.md`"
  deliverable is therefore satisfied the same way: as a **profile-local committed `AGENTS.md`**
  authored as profile-tree data, not via any emitter — see Emitted Tree.
- The `[data]` envelope a profile.toml can already express: `[layout]` roots + per-kind dirs +
  `project_context_file`; `[agent].format` ∈ {markdown, toml} + `[agent.frontmatter]`
  required/optional (+ `claude_code_optional`, a real `FrontmatterConfig` key —
  `aid_profile.py:114` — that lists Claude-Code-only optional frontmatter fields; irrelevant to
  Copilot but part of the schema, named here so the inventory is complete); `[skill].decomposition
  = "references"` + frontmatter; `[model_tiers]`; `[tool_names]`; `[filename_map]` (3 required
  keys); `[[extras.rules]]`; `[capabilities]`. Anything outside this envelope needs engine code.
- Determinism contract every emitting path obeys: write `bytes` in binary mode (LF-only); apply
  `substitute_filenames` THEN `rewrite_install_paths(install_root)` to every text body AND to any
  re-emitted frontmatter field that can carry `canonical/<dir>/` references; record each file in
  the `EmissionManifest` with repo-relative `src` and `common_parent`-relative `dst`.

### Renderer Extension (narrow — E1 only, plus the schema widening it requires)

The NFR ("add profiles as data + mappings, not a new render engine") bounds this. After the FR1
loopback the extension is **exactly one scoped addition — E1** — plus the schema/validator widening
it requires. The original draft scoped three additions (E1 + E2 cross-kind route + E3 MCP emitter);
the FR1 rulings **drop two of them**:

- **E2 (skills → `.agent.md` cross-kind route) is NOT built.** FR1 Q-A rules AID skills map to
  Copilot's **native Agent Skills** as a folder copy (`[data]`), using the existing `render_skills`
  folder pass pointed at the Copilot skills home — exactly as cursor emits skills today
  (`profiles/cursor.toml:8`). There is no `[skill].emit_as` knob, no cross-kind branch, no
  references inline/co-locate decision, no skill→agent collision guard. (The premise that forced
  E2 — "Copilot has no skill/slash primitive" — was overturned: provider-mapping.md §0 / Q-A.)
- **E3 (MCP-config emitter) is NOT built.** FR1 Q-B rules MCP `[omit]`: `grep -ri mcp canonical/
  profiles/*.toml` returns **zero** matches (provider-mapping.md Q-B), so there is nothing to emit.
  No `render_mcp.py`, no `[mcp]` profile table, no MCP schema, and no two-pass-list wiring (which
  only mattered for adding a new emitting pass — moot now that no pass is added).

This leaves **E1 as the only renderer code addition.**

**E1 — Copilot `.agent.md` frontmatter emitter for AID sub-agents** (`render_agents.py`).
AID's 22 sub-agents map to Copilot custom agents (FR1 Q-A); they have no native-skill home, so this
is the one route that needs engine code. Today `[agent].format` ∈ {markdown, toml}, and markdown
frontmatter is the fixed `name/description/tools/model[/permissionMode/background]` set built in
`_render_agent_for_profile` (`render_agents.py:282-296`). Copilot's `.agent.md` is markdown but
needs the `.agent.md` suffix and a YAML-**sequence** `tools:` field, neither of which the current
markdown branch produces. Add a third **agent-format** value `"copilot-agent"` (label fixed by FR1
Q-A) handled by a new branch alongside the existing `toml`/`markdown` split. Required behavior of
the branch:
- **Emitted frontmatter field set: `name, description, tools, model`** (in that order) — the four
  fields AID already has data for, per FR1 Q-A. `name`←canonical `name` (pass-through);
  `description`←canonical `description` (pass-through); `tools`←canonical `tools:` remapped via
  `[tool_names]` (`Bash→shell`) and emitted as a **YAML sequence** (computed); `model`←
  `_resolve_model(tier)` → the `[model_tiers]` string (computed). The optional Copilot fields
  (`target`, `user-invocable`, `disable-model-invocation`, `mcp-servers`, `metadata`) are
  **omitted** — AID has no per-agent source for them and the agent's defaults are correct (FR1 Q-A).
  If a constant is wanted later, that is an `[agent.frontmatter]` profile literal still inside E1's
  branch (the SPEC agent-frontmatter rule: anything beyond `name/description/tools/model` is engine,
  not data).
- reuses the existing canonical parse (`_parse_frontmatter`), tier→model resolution
  (`_resolve_model`), tool remap (`_remap_tools`), and the **same** `substitute_filenames` +
  `rewrite_install_paths` body/description treatment — no new transform machinery;
- **A YAML-list serializer is a REQUIRED part of E1.** Reason (verified 2026-05-31): `_remap_tools`
  (`render_agents.py:157-173`) returns a **comma-separated string**, which the markdown branch feeds
  into `_build_frontmatter_md` (`render_agents.py:104-125`) through the `str` branch (line 114) — a
  scalar like `tools: Read, Glob, ...`, NOT a YAML sequence. The function's only other branches are
  `bool` (line 112) and a terminal `else` (line 122) that emits a Python `repr` for a list (e.g.
  `tools: ['Read', 'shell']`) — invalid YAML. Copilot's `tools:` is a documented YAML list
  (provider-mapping.md §A.1; REQUIREMENTS §2), so the Copilot branch must build a **list** value and
  serialize list-valued fields as a proper YAML block sequence (flow form acceptable only if it
  parses back identically), with an empty list emitted as `[]` rather than a dangling key.
  (Serialization specifics are task-level.)
- **Scalar quoting must be confirmed Copilot-YAML-safe.** The reused str branch
  (`render_agents.py:116`) quotes values containing YAML-special characters by double-quoting with
  escaping; this is correct for Claude-Code/Cursor frontmatter but is **asserted, not verified**,
  against Copilot's YAML parser (especially a `description` containing `:`). E1's self-test
  (Test Plan #2) MUST assert every emitted frontmatter block round-trips through a real YAML load
  and that a `:`-bearing description parses back unchanged.
- writes to `<output_root>/<agents_dir>/<name>.agent.md` (the `.agent.md` suffix is new — today
  markdown agents are `<name>.md`); the suffix is a property of the `copilot-agent` format branch,
  NOT a separate data-driven `agent_suffix` key (see Schema/validator widening), and `agents_dir`
  comes from the profile (see Profile Data).

**Schema/validator widening (`aid_profile.py`) required by E1:**
- add `"copilot-agent"` to `_KNOWN_AGENT_FORMATS` (`aid_profile.py:334`, currently
  `{"markdown", "toml"}`); `validate` (lines 394-398) then accepts the new format. **The output
  suffix (`.agent.md` vs `.md`) is bound to the format value, NOT a separate data-driven
  `agent_suffix` key.** There is no `agent_suffix` profile key; the E1 branch selected by
  `format == "copilot-agent"` writes `.agent.md`, the markdown branch writes `.md`, the toml branch
  writes `.toml` — suffix is a property of the format branch (no speculative per-profile suffix
  engine).
- **No `[skill].emit_as` knob is added** (E2 dropped) and **no MCP table is added** (E3 dropped).
This is a single additive, default-preserving edit — existing profiles parse and validate exactly as
before (none set `format = "copilot-agent"`; defaults reproduce current behavior).

### Profile Data — `profiles/copilot-cli.toml`

Single-root layout (like Claude Code / Cursor — Copilot output is repo-relative under `.github/`).
Modeled on `cursor.toml` structure (skills emit as folders; markdown agents). The values below are
**sourced to `provider-mapping.md`** (FR1 is done) and cited to their ruling; the **one residual** is
the exact Copilot model-slug spelling, which the mapping marks `docs-only-noted` (§0 / Q-E — model
identities confirmed, slug tokenization to confirm before pinning the emitted literal).

```toml
# Profile: GitHub Copilot CLI
# Encodes the Copilot CLI host tool's install conventions (REQUIREMENTS §2; FR1 mapping
# provider-mapping.md — Copilot column).

[layout]
output_root          = "profiles/copilot-cli/.github"   # install_root() basename = ".github"
agents_dir           = "agents"                          # → .github/agents/*.agent.md (sub-agents, E1)
skills_dir           = "skills"                          # → .github/skills/<slug>/SKILL.md (native Agent Skills; Q-A/Q-C) — drives existing render_skills folder pass
templates_dir        = "templates"                       # bare name → .github/templates/ (matches rewrite-link; Q-C)
scripts_dir          = "scripts"                          # bare name → .github/scripts/ (matches rewrite-link; Q-C)
# recipes_dir intentionally unset → defaults to "recipes" (aid_profile.py:40), so recipes emit at
#   .github/recipes/ as [data] (Q-C/mapping row). render_recipes runs UNCONDITIONALLY for every
#   profile (run_generator.py:45) — there is no per-profile pass-selection mechanism — so recipes
#   emit exactly like the 3 existing profiles (cursor/.cursor/recipes, etc.), no engine change.
project_context_file = "AGENTS.md"                       # token value; the AGENTS.md doc itself is profile-local committed data (Q-J), not emitted

[agent]
format = "copilot-agent"                                 # E1: new agent-format value (Q-A); binds .agent.md suffix + Copilot frontmatter

[agent.frontmatter]
# Copilot emits exactly name/description/tools/model (Q-A). Optional Copilot fields
# (target/user-invocable/disable-model-invocation/mcp-servers/metadata) are omitted — AID has no
# per-agent source for them; agent defaults are correct.
required = ["name", "description", "tools", "model"]
optional = []

[skill]
decomposition = "references"
# No emit_as knob — skills are native Agent Skills, emitted as folders by the existing pass (Q-A).

[skill.frontmatter]
required = ["name", "description", "allowed-tools"]
optional = ["argument-hint"]

[model_tiers]                                            # simple form (Q-E); slug spelling docs-only-noted (§0)
large  = "claude-opus-4.8"
medium = "claude-sonnet-4.6"
small  = "claude-haiku-4.5"

[tool_names]                                             # Q-F: Bash→shell only; Read/Glob/Grep/Write/Edit pass through
Bash = "shell"

[filename_map]                                           # 3 keys required by validator
project_context_file = "AGENTS.md"
reviewer_output_file = "STATE.md"
open_questions_file  = "additional-info.md"

# No [mcp] table — MCP is [omit] (Q-B): repo ships no MCP servers (zero `mcp` matches in
# canonical/ + profiles/*.toml). No mcp-config.json is emitted.

[capabilities]                                           # Q-G
hooks                  = true
skill_chaining         = true
background_execution   = true
stop_hook_autocontinue = true
```

`install_root()` returns `.github` (basename of `output_root`, `aid_profile.py:47-75`), so
`rewrite_install_paths` rewrites `canonical/scripts/...` → `.github/scripts/...` (`render_lib.py`
rewrites to `<install_root>/<canonical-dir-name>/`, using the **literal canonical dir name** —
`scripts`, `templates` — captured by `_CANONICAL_PATH_RE`, NOT the profile's
`scripts_dir`/`templates_dir`).

**Demonstrated match/mismatch (verified 2026-05-31 by reading both code paths):**
- The EMITTED location of scripts is `_scripts_output_root` (`render_canonical_scripts.py:53-62`) =
  `output_base / output_root / scripts_dir` → `.github/<scripts_dir>/`. So
  `render_canonical_scripts` **does honor `scripts_dir`** for where files land.
- The body-rewrite link target is `<install_root>/scripts/` = `.github/scripts/` — fixed to the
  canonical name `scripts`, **ignoring `scripts_dir`**.
- Therefore the two AGREE **iff `scripts_dir == "scripts"`** (and `templates_dir == "templates"`).
  With `scripts_dir = "scripts"`: files emit at `.github/scripts/` and body links rewrite to
  `.github/scripts/` — demonstrated match. With `scripts_dir = "aid/scripts"`: files emit at
  `.github/aid/scripts/` but body links still rewrite to `.github/scripts/` — demonstrated
  mismatch (links would dangle in an adopter project).
- **Caveat for the verify gate:** `render_canonical_scripts` is a pre-existing live-emit pass that
  `verify_deterministic._render_all` does **not** re-render (it runs `render_agents`/`render_skills`/
  `render_templates`/`render_recipes` only — confirmed: no `render_canonical_scripts` call in
  `verify_deterministic.py`), so this match is NOT exercised by the determinism/presence checks today —
  the scripts subtree is emitted live but unverified. This feature does not fix that omission
  (out of scope) but the implementer MUST treat the match as code-verified, not gate-verified, and
  is encouraged to add scripts to `_render_all` if doing so does not perturb the existing 3
  profiles' byte-identical output (it would only ADD coverage, not change emitted bytes).
- **Recommendation (unchanged, now grounded):** keep `scripts_dir = "scripts"` and
  `templates_dir = "templates"` as bare names under `.github/` to stay inside the `[data]` envelope,
  keep emitted location and rewritten link in agreement, and avoid a 4th engine change to
  `rewrite_install_paths`. A deeper home requires touching `rewrite_install_paths` — out of the
  narrow scope and discouraged. This is flagged as a decision in the closing section.

### Emitted Tree — `profiles/copilot-cli/...`

```
profiles/copilot-cli/
├── emission-manifest.jsonl            # common_parent() = profiles/copilot-cli
├── AGENTS.md                          # profile-local committed context file (authored, NOT emitted, NOT in manifest)
└── .github/                           # install_root = .github
    ├── agents/
    │   ├── architect.agent.md         # 22 AID sub-agents → Copilot custom agents (E1)
    │   ├── developer.agent.md
    │   └── … (20 more)
    ├── skills/                         # 10 AID skills → Copilot native Agent Skills (folder copy, [data], Q-A)
    │   ├── aid-specify/
    │   │   ├── SKILL.md
    │   │   └── references/*.md         # carried as bundled folder files (Copilot auto-discovers)
    │   ├── aid-config/                 # zero-reference skill: SKILL.md only, no references/ (matches render_skills today)
    │   │   └── SKILL.md
    │   └── … (8 more)
    ├── scripts/                        # canonical/scripts/** (referenced home; see scripts caveat)
    ├── templates/                      # canonical/templates/** (referenced home)
    └── recipes/                        # canonical/recipes/** ([data]) — render_recipes runs unconditionally (run_generator.py:45), same as the 3 existing profiles
    # NO mcp-config.json — MCP is [omit] (Q-B)
```

Skills emit via the **existing** `render_skills` folder pass (`render_skills.py:300-359`),
unchanged from how cursor emits its `skills/` tree today — `skills_dir = "skills"` →
`<output_root>/skills/<slug>/SKILL.md` + `references/`. The zero-reference skill `aid-config` emits
`SKILL.md` only (the `references/` glob simply finds nothing, `render_skills.py:335-342`); no special
case is needed. This is pure `[data]`; no engine code touches skills.

**AGENTS.md — profile-local committed data, not an emission.** FR2's "context → `AGENTS.md`"
deliverable is satisfied exactly as the existing 3 profiles satisfy it: Copilot's instructions file
is a **profile-local, git-committed `profiles/copilot-cli/AGENTS.md`**, authored from the shared
~27-line context template with Copilot-specific paths and KB-import idiom substituted — the same
convention codex and cursor follow today. The authority for this convention is **feature-001 Q-J**.
Consequences this feature relies on as fact:
- `canonical/` has **no context/instructions source** to render from, and **no pass emits**
  `project_context_file` (verified — see Grounding). The `project_context_file` value is used ONLY
  for `{project_context_file}` token substitution in other files' bodies; it is never the source of
  a written document.
- `AGENTS.md` is therefore **authored, not rendered**, and is **absent from `emission-manifest.jsonl`**
  (like `profiles/{claude-code,codex,cursor}/`'s committed context files). The byte-identical
  determinism gate is unaffected because a re-render never touches an un-manifested file, and the
  presence audit never expects it.
- This adds **no new canonical source** and changes **none of the existing 3 profiles' output**,
  respecting REQUIREMENTS §4 Out of Scope. The exact context-document *content* (which paths/idiom
  Copilot needs) is profile-tree authoring, informed by the FR1 mapping but not an engine concern.

Final file count: 22 sub-agent `.agent.md` (E1) + 10 skill folders (`SKILL.md` + their references,
`[data]`) + canonical scripts/templates/recipes (`[data]`) + the committed `AGENTS.md` (authored).
**No** `mcp-config.json` (Q-B `[omit]`). Recipes **are** emitted under `.github/recipes/` as `[data]`
via the unconditional `render_recipes` pass (`run_generator.py:45`), exactly like the 3 existing
profiles.

### Data-vs-Engine split (explicit)

**Pure profile.toml data (`[data]` — no Python change):**
- All `[layout]` roots and per-kind dirs (incl. `skills_dir = "skills"` driving the existing
  `render_skills` folder pass); the `project_context_file` *filename* = `AGENTS.md` (used
  by `{project_context_file}` token substitution). **NOTE:** the `AGENTS.md` document itself is a
  **profile-local committed file authored as profile-tree data** (feature-001 Q-J) — not rendered by
  any pass and not in the manifest — so both the token value and the document are data, with no
  engine involvement (see Emitted Tree).
- **Skills → native Agent Skills (folder copy)** — pure data via `skills_dir` + the unchanged
  `render_skills` pass, exactly as cursor emits skills today. No engine code (Q-A).
- **Recipes → `.github/recipes/`** — pure data via the unchanged `render_recipes` pass, which runs
  **unconditionally** for every profile (`run_generator.py:45`; `recipes_dir` default `"recipes"`,
  `aid_profile.py:40`), exactly as the 3 existing profiles emit recipes today. No engine code, and no
  per-profile pass-selection mechanism exists (Q-C).
- `[filename_map]`, `[model_tiers]`, `[tool_names]`, `[capabilities]`.
- The *set* of frontmatter fields in `[agent.frontmatter].required` (which fields exist).
- Any Copilot frontmatter field whose value is a **constant** across all agents (a profile literal).

**Engine addition (`[transform:engine]` — the ONE from feature-001's Copilot column):**
- **E1** new `.agent.md` emitter / `"copilot-agent"` format + Copilot YAML-sequence `tools:` +
  `.agent.md` suffix — violates "closed agent-format enum" (`_KNOWN_AGENT_FORMATS`) + the
  scalar-only `_build_frontmatter_md` (no YAML-list serializer). Plus the schema/validator widening
  (`_KNOWN_AGENT_FORMATS += "copilot-agent"`) to make E1 selectable as data.

**NOT built (considered, then ruled out by FR1):**
- **E2** (skills → `.agent.md` cross-kind route + `[skill].emit_as`) — **dropped (Q-A):** Copilot has
  a native Agent Skills primitive, so skills are `[data]` (folder copy), not a cross-kind transform.
- **E3** (MCP-config emitter + `[mcp]` schema) — **dropped (Q-B):** the repo ships no MCP servers, so
  MCP is `[omit]` (nothing to emit).

Everything outside E1 + its schema widening is data. No generic transform framework is added: the
one engine piece is a single named branch guarded so the 3 existing profiles are untouched.

### Test Plan

1. **`aid_profile` validator self-test** — extend the existing validator coverage: a profile with
   `[agent].format = "copilot-agent"` validates clean; an unknown `[agent].format` value is rejected
   with a clear message. The 3 existing profiles (claude-code, codex, cursor) still validate clean
   (defaults unchanged); after this feature there are 4 profiles total (3 existing + copilot-cli).
2. **`render_agents` self-test (E1)** — `python render_agents.py --self-test` must stay green and
   now exercise `copilot-cli`: two renders byte-identical; output files end in `.agent.md`;
   frontmatter contains the Copilot key order (`name, description, tools, model`); **each emitted
   frontmatter block round-trips through a YAML parse and the `tools` field is emitted as a valid
   YAML sequence, not a comma-string and not a Python repr**; **a description containing a `:` is
   emitted as a quoted scalar that parses back unchanged**; `tools` reflects the `Bash→shell` remap.
   The 3 existing profiles' (claude-code, codex, cursor) agent output is byte-identical across the
   run.
3. **`render_skills` self-test (skills as `[data]` folders)** — `python render_skills.py --self-test`
   green for all 4 profiles (3 existing + copilot-cli). For `copilot-cli`: the 10 skills emit as **10
   `SKILL.md` folders** under `skills/` (the same folder shape cursor emits), not as agents.
   Assertions: (a) a multi-reference skill emits `SKILL.md` + its `references/*.md` under
   `skills/<slug>/`; (b) **the zero-reference skill `aid-config` emits `SKILL.md` only, with no
   `references/` directory** (the existing glob simply matches nothing — no special case);
   (c) for the 3 existing profiles, skill output is **byte-identical** to before (the folder pass is
   unchanged — copilot-cli takes the same code path, only `skills_dir`/`tool_names` differ as data).
4. **No MCP emitter** — assert no `mcp-config.json` is emitted for `copilot-cli` (Q-B `[omit]`); no
   `render_mcp` pass exists. (E3 is not built.)
5. **Render-drift clean for the new profile** — `python run_generator.py` emits `copilot-cli`
   with no errors; `verify_deterministic` PASS (byte-identical re-render + manifest presence audit
   has no missing/extra files for `copilot-cli`).
6. **Continuous byte-identical gate for the existing 3 profiles** — a check that
   `profiles/{claude-code,codex,cursor}/` trees + their `emission-manifest.jsonl` are
   byte-identical before vs after this feature (git diff shows zero changes under those three
   subtrees). This runs as a gate from this feature onward, not only at the end.
7. **Canonical suites green** — the existing generator self-tests (`render_lib --self-test`,
   `render_templates`, `render_canonical_scripts`, `render_recipes` self-tests) and
   `verify_advisory` continue to pass unchanged. **No new emitting pass is added** (E3 dropped), so
   the live-emit list (`run_generator.py`) and `verify_deterministic._render_all` are untouched and
   the two-pass-list wiring concern no longer applies. (The pre-existing `render_canonical_scripts`
   omission from `_render_all` is unrelated and remains out of scope.)

### Backward-Compat / Risk

- **Scope SHRANK after the FR1 loopback → lower risk.** The original draft carried three engine
  additions (E1 + E2 cross-kind route + E3 MCP emitter); FR1 dropped E2 (skills are native, `[data]`)
  and E3 (MCP `[omit]`), leaving **only E1**. The two highest-risk pieces (the cross-kind skill fold
  and a brand-new emitting pass + its two-pass-list wiring) are gone. Invariants are unchanged.
- **Existing 3 profiles unchanged.** The one engine addition is default-guarded: the new
  `[agent].format = "copilot-agent"` is set only by `copilot-cli`; `claude-code`/`codex`/`cursor`
  keep `markdown`/`toml`, so their code paths and output are byte-identical (gate test #6). The
  schema edit is additive (one widened enum). This is the NFR's "byte-identical from this feature
  onward."
- **Main residual risk: E1's YAML-sequence `tools:` serialization + scalar quoting.** The current
  `_build_frontmatter_md` cannot emit a YAML list and its scalar quoting is unverified against
  Copilot's parser. Mitigation: the E1 self-test (test #2) round-trips every frontmatter block
  through a real YAML load, asserting the `tools` sequence and a `:`-bearing description parse back
  unchanged. Blast radius is zero on other profiles (new branch, selected only by the new format).
- **Skills carry no shape risk** — they reuse the existing, already-tested `render_skills` folder
  pass verbatim (only `skills_dir`/`tool_names` differ as data), exactly as cursor does.
- **FR1 dependency — now SATISFIED.** `provider-mapping.md` (delivery-001) has answered Q-A (skills
  native `[data]`; `.agent.md` frontmatter = `name/description/tools/model`; format label
  `copilot-agent`), Q-B (MCP `[omit]`), Q-C (bare `scripts`/`templates` home), Q-E (`[model_tiers]`
  simple form), Q-F (`Bash→shell`), Q-G (`[capabilities]`). The **one residual** is the exact Copilot
  model-slug spelling, marked `docs-only-noted` by the mapping (§0 / Q-E) — confirm
  `model: claude-opus-4.8` vs a display-name form before pinning the emitted literal; model
  identities are LIVE-confirmed.
- **`rewrite_install_paths` dir-name caveat** (see Profile Data) — keeping `scripts_dir`/
  `templates_dir` as bare `scripts`/`templates` keeps the feature inside the `[data]` envelope and
  avoids touching `rewrite_install_paths` (FR1 Q-C). Deviating is out of the narrow scope and
  discouraged.
- **No new dependencies** — E1 uses only Python stdlib + the existing renderer helpers; no pip/npm.
  Satisfies the dependency-free NFR.
