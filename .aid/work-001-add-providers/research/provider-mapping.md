# Provider Mapping — AID Primitives → Copilot CLI / Antigravity

> **Deliverable of feature-001-provider-research (FR1), work-001-add-providers.**
> Authored by task-003 (convention sections + dispositioned mapping table) and task-004
> (Q-A..Q-J rulings + 14-row FR1 Deliverable Contract crosswalk) as **one** file.
>
> **Purpose:** a downstream implementer can populate `profiles/copilot-cli.toml` and
> `profiles/antigravity.toml` (and scope every named engine extension) from this doc **alone**,
> without re-researching either tool.
>
> **Inputs:** `research/copilot-cli-findings.md` (task-001), `research/antigravity-findings.md`
> (task-002), plus independent live re-verification of the high-impact Copilot Agent-Skills finding
> and the AID repo itself.
>
> **Access date for all live re-verifications in this doc: 2026-05-31.**
> **Disposition legend:** `[data]` = expressible by a new `profiles/<tool>.toml` + the existing
> renderer passes (names the profile TOML key); `[transform:engine]` = needs new renderer code
> (names the specific renderer gap); `[omit]` = no home (states what is dropped + why safe).
> **Agent-frontmatter rule (SPEC):** any `.agent.md` field beyond the hardcoded
> `name/description/tools/model` (+`permissionMode`/`background`) emission set is
> `[transform:engine]`, never `[data]` — `[agent.frontmatter]` lists are parsed but dead for
> emission.

---

## 0. HEADLINE — verified high-impact change + the divergences it forces

**GitHub Copilot CLI shipped a native Agent Skills primitive (`SKILL.md` folders, `/skills`,
`/<skill-name>`) on 2025-12-18, AFTER the requirements interview.** This obsoletes the
feature-002 / REQUIREMENTS §2 premise that "Copilot has no skill/slash primitive → AID skills must
be transformed into agents (the E2 cross-kind route)."

**Live re-verification result: CONFIRMED (not docs-only).** I independently re-fetched the two
load-bearing sources on 2026-05-31:

- **Agent Skills exist + SKILL.md convention + project dirs** —
  `https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills`
  (accessed 2026-05-31). Confirmed verbatim: *"For **project skills**, specific to a single
  repository, create a `.github/skills`, `.claude/skills`, or `.agents/skills` directory in your
  repository."* The surprising **`.claude/skills/`** claim is **CONFIRMED**. Personal dirs:
  `~/.copilot/skills`, `~/.agents/skills`. Slash surface confirmed: `/skills list|info|add|reload|remove`
  and toggle `/skills`, plus explicit invocation `/<skill-name>` in a prompt (page example
  `/frontend-design`). `SKILL.md` is the required file (YAML frontmatter `name`, `description`,
  optional `license`/`allowed-tools` + Markdown body).
- **Cross-tool pickup** — GitHub Changelog 2025-12-18
  `https://github.blog/changelog/2025-12-18-github-copilot-now-supports-agent-skills/`
  (accessed 2026-05-31). Confirmed Agent Skills work across *"Copilot coding agent, Copilot CLI,
  and agent mode in Visual Studio Code"*, and verbatim: *"If you've already set up skills for
  Claude Code in the `.claude/skills` directory in your repository, Copilot will pick them up
  automatically."* This independently corroborates the `.claude/skills/` directory and the
  data-shaped (folder-copy) nature of the mapping.

**Model strings re-verification (Copilot):** the agent-frontmatter reference
`https://docs.github.com/en/copilot/reference/custom-agents-configuration` and supported-models
`https://docs.github.com/en/copilot/reference/ai-models/supported-models` (both accessed
2026-05-31) confirm **Claude Opus 4.8 / Sonnet 4.6 / Haiku 4.5** are all GA for Copilot (Opus 4.8
GA confirmed by changelog 2026-05-28). **One residual:** those two reference pages rendered the
**display names** ("Claude Opus 4.8"), not the lowercase-dotted **slug** form
(`claude-opus-4.8`) the findings claimed for the `model:` field. The slug form is GitHub's
documented model-id convention, but I could not pin the exact `model:`-field tokenization on a live
page render this session → I mark the **exact slug spelling `docs-only-noted`** (residual gap: confirm
`model: claude-opus-4.8` spelling vs a display-name form against the live model-id reference before
pinning the emitted literal). The *identity* of the three models is confirmed.

### Divergences from current SPEC / REQUIREMENTS (flagged, NOT silently rewritten)

> **DIVERGENCE 1 — feature-002's E2 cross-kind route is very likely UNNECESSARY for skills.**
> REQUIREMENTS §2 ("No user-defined slash-command / 'skills' primitive — only agents +
> instructions"), the §2 Impedance-mismatch paragraph ("Copilot CLI has agents but **no
> skill/slash primitive**"), feature-002 SPEC §Description / §Renderer-Extension **E2**, and AC3
> ("skill→agent cross-kind transformation") all rest on the obsolete premise. With native Agent
> Skills, **AID skills map to Copilot Agent Skills as a folder copy (`[data]`)** — the same
> `SKILL.md` + `references/` shape `render_skills` already emits. **Downstream impact:**
> feature-002's **E2 engine work (the skills→`.agent.md` cross-kind route, `[skill].emit_as`
> knob, the collapse/inline-or-co-locate references decision) is likely NOT needed**;
> feature-002 SPEC §E2 + AC3 and REQUIREMENTS §2/§4 (FR2 "skills → `.agent.md` agents") need
> revision before delivery-002. See Q-A for the disposition.

> **DIVERGENCE 2 — Copilot now has a skill-folder home; `[layout].skills_dir` becomes real for
> Copilot.** feature-002 SPEC's emitted-tree shows only `agents/` (no `skills_dir`), because it
> assumed skills collapse into agents. With native skills, the Copilot profile should carry a
> `skills_dir = "skills"` (→ `.github/skills/`) and route the *existing* `render_skills` folder
> pass there — pure data. feature-002 SPEC §Profile Data / §Emitted Tree need updating.

> **DIVERGENCE 3 (minor) — REQUIREMENTS §2 Copilot instructions list is incomplete, not wrong.**
> The four seed instruction files are all confirmed; current docs additionally honor
> `CLAUDE.md`/`GEMINI.md` at the repo root, `~/.copilot/instructions/*.instructions.md`, and the
> `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` env var. No ruling depends on this; flagged for completeness.

> **DIVERGENCE 4 (minor) — Antigravity directory + extension corrections vs REQUIREMENTS §2.**
> §2 listed Antigravity rules as "`.agent/rules/*.md` + `AGENTS.md`/`GEMINI.md`". Confirmed correct
> on `.agent/rules/` and `.md`, but §2 conflates the **context/instructions** layer
> (`AGENTS.md`/`GEMINI.md`) with the **rule-file** layer (`.agent/rules/*.md`) — they are distinct
> (see §B.3). Also: the Antigravity rule-file extension is **`.md`, not `.mdc`** (Q-I), so the
> Antigravity profile **cannot reuse cursor's `.mdc` filenames verbatim**. feature-003 must use
> `.md` + the `trigger:` frontmatter key, not `.mdc` + `alwaysApply:`.

**Colleague's-fork status (recorded per STATE.md Q1 / AC3):** the colleague's Copilot CLI fork
**URL was NOT provided**. The two known public forks (`ubidev`, `shake-k`) are on a pre-`profiles/`
layout and do not contain the Copilot work. Research **proceeded docs-only**, building toward an
**original implementation (no fork reference, no fork)** per the user's decision. No fork layout
decisions were folded in. If a URL arrives later it can be folded in and affected cells re-tagged;
do not block on it.

---

## A. Convention section — GitHub Copilot CLI

All claims below carry a source URL + access date (2026-05-31 for all). `[LIVE]` = re-fetched this
session; `[task-001]` = sourced in `copilot-cli-findings.md` (vendor docs fetched 2026-05-31).

### A.1 Custom agents (`.agent.md`)

- **Paths:** repo `.github/agents/NAME.agent.md` (team-shared on push); user
  `~/.copilot/agents/NAME.agent.md` (honors `COPILOT_HOME`). Extension `.agent.md`; filename charset
  `. - _ a-z A-Z 0-9`; body ≤ 30,000 chars Markdown. `[task-001 §1]` — sources:
  `docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-custom-agents-for-cli`,
  `docs.github.com/en/copilot/reference/custom-agents-configuration`.
- **Frontmatter field set `[LIVE re-confirmed 2026-05-31]`** against
  `docs.github.com/en/copilot/reference/custom-agents-configuration`. Exactly nine fields;
  **only `description` is required**, all others optional:

  | Field | Required | Type |
  |---|---|---|
  | `name` | optional | string (defaults to filename minus `.agent.md`) |
  | `description` | **required** | string (drives inference) |
  | `target` | optional | string (`vscode` \| `github-copilot`; unset = both) |
  | `tools` | optional | list of strings **or** comma-string (`["*"]` / `[]` allowed) |
  | `model` | optional | string (model id; inherits default if unset) |
  | `disable-model-invocation` | optional | boolean (default false) |
  | `user-invocable` | optional | boolean (default true) |
  | `mcp-servers` | optional | object/map (inline per-agent MCP) |
  | `metadata` | optional | object/map (string→string) |

  `handoffs` and `argument-hint` are **explicitly not supported** for the GitHub side `[LIVE]`
  ("the `argument-hint` and `handoffs` properties ... are currently not supported for Copilot cloud
  agent on GitHub.com").
- **Invocation `[task-001 §1]`:** `/agent` (interactive picker); explicit in-prompt; automatic
  inference on `description` (gated by `disable-model-invocation`); `--agent NAME --prompt "..."`.

### A.2 Agent Skills (`SKILL.md`) — PRESENT (seed correction; see §0)

- **Skill = a folder containing `SKILL.md`** (+ optional bundled scripts/resources; Copilot
  auto-discovers all files in the dir). `[LIVE]`
- **Project-skill dirs:** `.github/skills/`, `.claude/skills/`, `.agents/skills/`. **Personal:**
  `~/.copilot/skills/`, `~/.agents/skills/`. `[LIVE]`
- **`SKILL.md` frontmatter:** `name` (required, lowercase-hyphen id), `description` (required);
  optional `license`, `allowed-tools`. Body = Markdown instructions. `[LIVE]`
- **Invocation:** automatic (by `description` relevance) or explicit `/<skill-name>`; managed via
  `/skills list|info|add|reload|remove`. `[LIVE]`
- Source: `docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills`;
  changelog `github.blog/changelog/2025-12-18-github-copilot-now-supports-agent-skills/`
  (both accessed 2026-05-31).

### A.3 Instructions / context files

- **`AGENTS.md`** (repo root / cwd / `COPILOT_CUSTOM_INSTRUCTIONS_DIRS`) — **primary**; nearest in
  the tree wins. `.github/copilot-instructions.md` (repo-wide always-on; used *with* `AGENTS.md` if
  both exist). `.github/instructions/**/*.instructions.md` (path-scoped via `applyTo`).
  `CLAUDE.md`/`GEMINI.md` at repo root also honored. `$HOME/.copilot/copilot-instructions.md` and
  `~/.copilot/instructions/*.instructions.md` (user/global). Conflict resolution is
  model-nondeterministic (documented). `[task-001 §3]` — sources:
  `.../copilot-cli/customize-copilot/add-custom-instructions`, CLI config-dir reference.
- **AID context-file home:** repo-root **`AGENTS.md`** (primary, team-shared, parallels existing
  codex/cursor profiles). User-home `copilot-instructions.md` is machine-global → wrong home for a
  per-project install.

### A.4 MCP config

- **User-level default:** `~/.copilot/mcp-config.json`; root key is **`mcpServers`** (not
  `servers`); `COPILOT_HOME` relocates the whole `~/.copilot` dir. Repo-level
  `.copilot/mcp-config.json` + `--additional-mcp-config` merge is the team-sharing path. Add via
  `/mcp add`. `[task-001 §4]` — sources: CLI config-dir reference,
  `.../copilot-cli/customize-copilot/add-mcp-servers`. (Repo-root `.copilot/mcp-config.json`
  spelling is how-to-summary + community confidence, not a fresh live fetch — noted; does not affect
  the Q-B ruling, which is `[omit]`.)

### A.5 Install / discovery surface

- Install: `npm install -g @github/copilot` (Node 22+); also WinGet / Homebrew
  (`brew install copilot-cli`) / install script. Binary `copilot`; auth via `/login`. `[task-001 §5]`
- Discovery is **convention-based path scanning, no registry**: repo `.github/` tree
  (`agents/*.agent.md`, `skills/`, `AGENTS.md`, `copilot-instructions.md`, `instructions/**`,
  `.github/hooks/*.json`) + `.claude/skills/`/`.agents/skills/`, and the user `~/.copilot/` tree.
  **Implication:** an AID install is a pure file-drop into the repo `.github/` (+ `.claude/skills/`)
  tree — no plugin-registration step (matches AID's existing model). `[task-001 §5]`

---

## B. Convention section — Google Antigravity

`[LIVE-2nd]` = corroborated by ≥2 current sources in `antigravity-findings.md`; `[GAP]` = vendor
page not retrievable, fallback stated. All accessed 2026-05-31. Primary corroboration: official docs
mirror via Context7 (`/alphaperseii3000/google-antigravity-docs`, `/llmstxt/.../google_antigravity`),
Atamel dev post (2025-11-25), dev.to malloc72p, agentpedia.codes guides, gemini-cli issue #16058.

### B.1 Rules — `.agent/rules/*.md`

- Project rules: **`.agent/rules/`** (singular `.agent`) at workspace/repo root; files are **`.md`**
  (plain Markdown + YAML frontmatter). Global rules: a single **`~/.gemini/GEMINI.md`** file.
  `[LIVE-2nd, antigravity §1]`
- Rule **frontmatter:** `trigger:` (enum `always_on` / `model_decision` / `glob` / `manual`) +
  `description:` (for `model_decision`) + `globs:` (for `glob`). Activation modes map 1:1: Always On
  / Model Decision / Glob / Manual. `[LIVE-2nd, §1]`
- Distinct from Cursor: `.md` (not `.mdc`); `trigger: always_on` (not `alwaysApply: true`).

### B.2 Slash-workflows — `.agent/workflows/*.md`

- Project workflows: **`.agent/workflows/`**; global `~/.gemini/antigravity/global_workflows/`.
  Saved Markdown files registering a slash command, invoked **`/workflow-name`** (confirms the
  REQUIREMENTS §2 `/generate-unit-tests` example). **Workflows can call other workflows**
  (composition). Frontmatter is thin: **`description:` only**. `// turbo` marks auto-exec steps.
  `[LIVE-2nd, §2]`

### B.3 Context/instructions — `AGENTS.md` vs `GEMINI.md`

- Antigravity **reads BOTH** `AGENTS.md` and `GEMINI.md` (project root + global `~/.gemini/`) and
  **merges** them. Precedence on conflict: **System Rules → GEMINI.md → AGENTS.md → `.agent/rules/`**
  (GEMINI.md outranks AGENTS.md). Recommended split: `AGENTS.md` = cross-tool foundation (the open
  standard shared with Cursor/Claude Code/Codex); `GEMINI.md` = Antigravity-specific overrides.
  Nested `AGENTS.md` recognized. `[LIVE-2nd, §3]`
- `~/.gemini/GEMINI.md` collision with Gemini CLI corroborated by gemini-cli issue #16058.

### B.4 Native Skills — `.agent/skills/<folder>/SKILL.md`

- Antigravity **also has a native first-class Skills primitive**: `.agent/skills/<folder>/SKILL.md`
  with frontmatter `name` + `description` + Markdown body — **the same shape AID skills already
  have**. `[LIVE-2nd, §7]`

### B.5 Sub-agent file convention — ABSENT

- **No user-authored custom sub-agent file** (nothing like Claude Code's `.claude/agents/<name>.md`
  or Cursor's `.cursor/agents/<name>.md`). Customization surface = Rules + Workflows + Skills. The
  built-in *browser subagent* and runtime-spawned background subagents are **not** author files.
  `[LIVE-2nd, §6]` ⇒ AID's 22 sub-agents have **no native 1:1 home** in Antigravity (the substance
  of Q-D).

### B.6 "Antigravity ≈ Cursor" assumption (REQUIREMENTS §8) — VALID with two corrections

Valid: both VS Code forks, always-on/glob/model-decided rule files w/ YAML frontmatter, slash-saved
prompts, both read `AGENTS.md`. **Corrections:** (1) dir root is `.agent/` not `.cursor/`; (2) rule
extension `.md` + `trigger:` key, not `.mdc` + `alwaysApply:`; (3) Antigravity additionally has
native `.agent/skills/` and **no** sub-agent file. So model the Antigravity profile on cursor as the
*starting point*, but it is a **rename-dir + change-extension + change-frontmatter-key** adaptation,
not a byte-clone. `[LIVE-2nd, §5]`

### B.7 Install / model surface

- VS Code-fork IDE + an Antigravity CLI / Agent Manager. Hooks defined as JSON; async background
  subagents. Multi-model via Vertex Model Garden; user picks model in a dropdown (sticky per turn).
  `[LIVE-2nd, §8/§10]`
- **Naming caveat `[GAP-flagged]`:** one Google codelab uses **`.agents/`** (plural) +
  `agents.md` + `.agents/skills/`. The official mirror + Atamel + dev.to all use **`.agent/`**
  (singular), taken as canonical; the plural is treated as a tutorial-author variation. feature-003
  should be aware; canonical pick = `.agent/`.

---

## C. Mapping table (7 AID-primitive rows + 5 profile-config rows × both tools)

Every cell is concrete and carries exactly one disposition tag. Cells are self-consistent with the
Q-A..Q-J rulings (§D) and the FR1 crosswalk (§E).

| AID primitive / profile config | Copilot CLI target | Antigravity target | Disposition |
|---|---|---|---|
| **sub-agent** (`canonical/agents/*/AGENT.md`) | `.github/agents/<name>.agent.md` (Markdown + Copilot YAML frontmatter; invoked `/agent`/`--agent`/inference) | `.agent/rules/<name>.md` (AGENT frontmatter reshaped → `trigger:`-style rule frontmatter; body carries over) | **`[transform:engine]`** — *Copilot:* closed `_KNOWN_AGENT_FORMATS={markdown,toml}` (`aid_profile.py:334`) + fixed `_build_frontmatter_md` key set `name/description/tools/model` (`render_agents.py:282-296`) cannot emit `.agent.md` suffix or the Copilot key order/list-valued `tools`; needs E1 new `copilot-agent` format. *Antigravity:* `render_agents` globs only `canonical/agents/*/AGENT.md` and emits the hardcoded key set; emitting `trigger:`/`description`/`globs` rule frontmatter from the agents pass is a frontmatter reshape no current pass performs (Q-D). |
| **skill** (`canonical/skills/aid-*/` SKILL.md + references/) | `.github/skills/<slug>/SKILL.md` (+ `references/`) — **native Agent Skill, folder copy** | `.agent/skills/<slug>/SKILL.md` (+ `references/`) — **native Skills primitive, folder copy** | **`[data]`** — `[layout].skills_dir = "skills"`; the **existing** `render_skills.py` folder pass (decomposition `references`) emits `<root>/<skills_dir>/<slug>/SKILL.md` + `references/*.md` unchanged. SKILL.md `name`/`description` already match both tools' required pair. *(Copilot `.claude/skills/` pickup means even the dir is reusable — see §0.)* Reverses feature-002 E2. |
| **helper script** (`canonical/scripts/**`) | `.github/scripts/` (bare `scripts_dir = "scripts"`) | `.agent/scripts/` (bare `scripts_dir = "scripts"`) | **`[data]`** — `[layout].scripts_dir = "scripts"`; existing `render_canonical_scripts` emits to `<output_root>/<scripts_dir>/`; `rewrite_install_paths` rewrites body refs to `<install_root>/scripts/`. Bare `scripts` keeps emitted-location == rewritten-link (Q-C); a deeper home would dangle links (feature-002 SPEC §Profile Data caveat). No native script primitive in either tool, but a referenced dir under the install root is reachable by `[layout]` alone. |
| **template** (`canonical/templates/**`) | `.github/templates/` (bare `templates_dir = "templates"`) | `.agent/templates/` (bare `templates_dir = "templates"`) | **`[data]`** — `[layout].templates_dir = "templates"`; existing `render_templates` pass; same bare-name rewrite-agreement rule as scripts (Q-C). |
| **recipe** (`canonical/recipes/*.md`) | `.github/recipes/` (`recipes_dir` default `"recipes"`) | `.agent/recipes/` (`recipes_dir` default `"recipes"`) | **`[data]`** — the existing `render_recipes` pass runs **unconditionally** for every profile (`run_generator.py:45`; `recipes_dir` defaults to `"recipes"`, `aid_profile.py:40`), emitting `<output_root>/recipes/` exactly as the 3 existing profiles do today (`profiles/{cursor,codex,claude-code}/*/recipes`). There is **no per-profile pass-selection mechanism**, so recipes cannot be omitted as data — they emit as referenced files via the existing pass, no engine change. **(Correction:** the earlier "leave `render_recipes` unselected / no `recipes_dir` emitted ⇒ `[omit]`" hint was wrong — `render_recipes` is unconditional per `run_generator.py:45`; recipes are `[data]`, not `[omit]`.) |
| **context / instructions file** (`{project_context_file}`) | repo-root **`AGENTS.md`** (profile-local committed file, authored not emitted) | repo-root **`AGENTS.md`** (profile-local committed file, authored not emitted; GEMINI.md also read but AGENTS.md is the canonical pick — Q-H) | **`[data]`** — `[layout].project_context_file = "AGENTS.md"` + `[filename_map].project_context_file = "AGENTS.md"`; the document itself is a committed profile-tree file authored from the shared ~27-line template, **not rendered, not in any `emission-manifest.jsonl`** (Q-J), exactly as codex/cursor do today. |
| **MCP config** | **`[omit]`** — AID ships **no** MCP servers (repo evidence, Q-B); no `mcp-config.json` emitted | **`[omit]`** — same; no MCP artifact emitted | **`[omit]`** — verified: `grep -ri mcp canonical/ profiles/*.toml` returns **zero** matches; no canonical artifact defines an MCP server and the `Profile` dataclass has no MCP table. Dropping is safe (nothing to emit); avoids building the E3 emitter + MCP schema. Justification in Q-B. |
| **`[model_tiers]`** (per tier alias) — Q-E | **simple form:** `large="claude-opus-4.8"`, `medium="claude-sonnet-4.6"`, `small="claude-haiku-4.5"` | **detailed form:** `[model_tiers.large]{model="gemini-3-pro",reasoning_effort="high"}`, `medium{model="gemini-3-pro",reasoning_effort="low"}`, `small{model="gemini-3-flash"}` | **`[data]`** — `[model_tiers]` table. Copilot = simple (`tier="string"`, like Claude Code/Cursor); Antigravity = detailed (`model`+`reasoning_effort`, like Codex). Tier keys `large/medium/small` confirmed against canonical (`grep '^tier:' canonical/agents/*/AGENT.md` → 10 large / 9 medium / 3 small; `_resolve_model` resolves exactly these). Values FR1-owned (Q-E). |
| **`[tool_names]`** (complete map) — Q-F | `Bash = "shell"` only; `Read/Glob/Grep/Write/Edit` pass through (no documented renamed equivalent — `write` is a permission *category*, not a per-tool rename) | **empty map** (identity passthrough) — no published tool-token rename | **`[data]`** — `[tool_names]` table. Canonical tool tokens confirmed: `Read, Glob, Grep, Bash, Write, Edit` (`grep '^tools:' canonical/agents`). `_remap_tools` substitutes only present keys, passes the rest through (Q-F). |
| **`[capabilities]`** (all 4 flags) — Q-G | `hooks=true`, `skill_chaining=true`, `background_execution=true`, `stop_hook_autocontinue=true` | `hooks=true`, `skill_chaining=true`, `background_execution=true`, `stop_hook_autocontinue=false` | **`[data]`** — `[capabilities]` table; per-flag evidence in Q-G. |
| **rule-file extension** (`.mdc` vs `.md`) — Q-I | **n/a** (Copilot has no Cursor-style `[[extras.rules]]` rule-file artifact; instructions are `AGENTS.md`/`.instructions.md`, not emitted as rule files) | **`.md`** → `[[extras.rules]].filename = "aid-methodology.md"` etc. (NOT `.mdc`), with `trigger:`-style frontmatter | **`[data]`** — `[[extras.rules]].filename` extension; ruling in Q-I. |
| **`agent.format` enum label** — Q-A | **`"copilot-agent"`** (new value added to `_KNOWN_AGENT_FORMATS`; emits `.agent.md` + Copilot key order) | n/a for sub-agents-as-agents (Antigravity has no agent-file kind; sub-agents → rules, handled by the Q-D engine route) | **`[transform:engine]`** — Copilot label requires widening the closed enum (`aid_profile.py:334`) + a new E1 emitter branch + validator/router wiring; not reachable as `[agent.frontmatter]` data (the lists are parsed but dead for emission). |

---

## D. Key-Question rulings (Q-A … Q-J)

### Q-A — Copilot `.agent.md` frontmatter + skills disposition + `agent.format` label

**Sub-agents → `.agent.md`:** AID's 22 sub-agents map to Copilot custom agents at
`.github/agents/<name>.agent.md`. This **still needs the E1 emitter** (`[transform:engine]`): the
current renderer cannot emit the `.agent.md` suffix, the Copilot frontmatter key order, or a
list-valued `tools:` (its `else` branch emits a Python `repr`, invalid YAML — feature-002 SPEC §E1).

- **Exact emitted frontmatter key set/order** for the `copilot-agent` format (only `description`
  required; `[LIVE]` reference confirms the field universe and that all others are optional):
  **`name`, `description`, `tools`, `model`** — the four AID already has data for. `name`←canonical
  `name`; `description`←canonical `description`; `tools`←canonical `tools:` remapped via
  `[tool_names]` (`Bash→shell`), emitted as a **YAML sequence**; `model`←`_resolve_model(tier)` →
  the `[model_tiers]` string. The optional Copilot fields **`target`, `user-invocable`,
  `disable-model-invocation`, `mcp-servers`, `metadata`** are **omitted** (no canonical source; AID
  has no per-agent value for them; the agent's default behavior is correct). If feature-002 later
  wants any of them as a constant, that is a profile literal handled inside the E1 branch — still
  `[transform:engine]` (the SPEC agent-frontmatter rule: anything beyond `name/description/tools/model`
  is engine, not data). **Pass-through vs computed:** `name`/`description` pass through;
  `tools` is **computed** (remap + sequence serialization); `model` is **computed** (tier resolve).
  No field is renamed.
- **Exact `agent.format` enum label: `"copilot-agent"`** (matches feature-002 SPEC §E1 proposal).
  feature-002 adds this to `_KNOWN_AGENT_FORMATS`, wires the validator + the E1 emitter branch
  (which also binds the `.agent.md` suffix to the format, per SPEC — not a separate `agent_suffix`
  key).

**Skills disposition — RULED: AID skills → Copilot native Agent Skills (`.github/skills/<slug>/`),
NOT `.agent.md` agents. Disposition `[data]`.** (See §0 verification.) Two alternatives compared:

- **(A) skills → `SKILL.md` native Agent Skill (CHOSEN).** Copilot now has a native skill kind whose
  `SKILL.md` required pair (`name`,`description`) matches AID's `SKILL.md`; `references/` bodies
  survive as bundled folder files (Copilot auto-discovers them). The **existing** `render_skills`
  folder pass emits exactly this when pointed at `skills_dir = "skills"` → `.github/skills/<slug>/`.
  **No engine work** — reverses feature-002 E2. `.claude/skills/` being an accepted Copilot dir means
  the shape is doubly validated as data.
- **(B) skills → `.agent.md` agents (the obsolete seed route, REJECTED).** Was forced only because
  "no skill primitive existed." Now the worse fit: collapses the skill idiom into the agent idiom,
  forces the E2 cross-kind route + the 0–20 references inline/co-locate problem, and is strictly
  more engine work for a worse semantic match.

**Recommendation:** route AID skills through the existing folder pass to `.github/skills/`; drop
feature-002's E2. **Residual:** confirm the exact `model:` slug spelling (see §0) before pinning the
`[model_tiers]` literals; the skill mapping itself has no residual.

> **DIVERGENCE (restated):** feature-002 SPEC §Description / §E2 / AC3 and REQUIREMENTS §2 ("no
> skill/slash primitive") / FR2 ("skills → `.agent.md` agents") are obsolete for skills. Revise
> before delivery-002: E2 + `[skill].emit_as` are unnecessary; add `skills_dir` to the Copilot
> profile.

### Q-B — Copilot MCP emit/omit

**RULED: `[omit]`.** AID ships **no MCP servers.** Repo evidence:
`grep -ri 'mcp' canonical/ profiles/*.toml` returns **zero** matches (run 2026-05-31); no canonical
artifact defines an MCP server, and the `Profile` dataclass (`aid_profile.py:168-192`) has no MCP
table. **Alternatives compared:** *emit* would require building the E3 `render_mcp.py` emitter + an
MCP profile schema + wiring it into both the live-emit and `verify_deterministic._render_all`
pass-lists (feature-002 SPEC §E3) — pure cost with **nothing to emit**. *Omit* drops nothing real
and is the cheapest, safe path. **Ruling:** no `mcp-config.json` emitted; document the omission in
the profile comments; **E3 is not built**. If AID ever ships MCP servers, revisit — the location
would then be repo-root `.copilot/mcp-config.json` (inside the audited `output_root`).

> **DIVERGENCE:** feature-002 SPEC §E3 / FR2 ("MCP → `mcp-config.json`") / REQUIREMENTS §4 (FR2
> "MCP config") assume a possible MCP emitter; Q-B rules it OMIT, so E3 is dropped. Update
> feature-002 to mark MCP `[omit]` (the SPEC already allows this branch as the "cheapest path").

### Q-C — scripts/templates home per tool (reachable via `[layout]` alone)

**RULED `[data]` for both tools, bare names under the install root:**

- **Copilot:** `scripts_dir = "scripts"` → `.github/scripts/`; `templates_dir = "templates"` →
  `.github/templates/`.
- **Antigravity:** `scripts_dir = "scripts"` → `.agent/scripts/`; `templates_dir = "templates"` →
  `.agent/templates/`.

Reachable via `[layout]` dirs alone: `render_canonical_scripts`/`render_templates` emit to
`<output_root>/<dir>/`, and `rewrite_install_paths` rewrites body refs to `<install_root>/scripts/`
using the **literal canonical dir name**, not the profile key (`render_lib.py`, feature-002 SPEC
§Profile Data). **Bare `scripts`/`templates` keeps emitted-location == rewritten-link**; a deeper
home (e.g. `aid/scripts`) would dangle the links and force a 4th engine change to
`rewrite_install_paths` — **avoided.** Alternatives compared: bare-name-under-install-root (chosen,
`[data]`) vs deeper `aid/`-prefixed home (rejected: needs engine change, leaves dangling links).

### Q-D — Antigravity sub-agents→rules / skills→workflows: `[data]` vs `[transform:engine]` + dependency edge

**Skills → native `.agent/skills/` (NOT workflows). `[data]`.** Antigravity has a native
`.agent/skills/<slug>/SKILL.md` primitive with the **same shape AID skills already have**. The
existing `render_skills` folder pass pointed at `skills_dir = "skills"` emits `.agent/skills/<slug>/`
unchanged — pure data. (Alternative: skills→`.agent/workflows/` gains slash-invocation but loses the
SKILL.md packaging and would need a body reshape; rejected — `.agent/skills/` is the lower-impedance,
same-frontmatter match.)

**Sub-agents → `.agent/rules/`. `[transform:engine]`.** AID sub-agents have **no native Antigravity
sub-agent home** (§B.5). To live as rules, the AGENT frontmatter (`name/description/tools/model`)
must be **dropped/replaced** by rule frontmatter (`trigger:`/`description`/`globs`) — a frontmatter
**reshape**. The Markdown body carries over (data-shaped), but **the body alone is not the
artifact** — the rule needs the `trigger:` key, and the current `render_agents` pass emits only the
hardcoded `name/description/tools/model` set and globs only `canonical/agents/*/AGENT.md` into one
target subdir. Emitting `trigger:`-style frontmatter from the agents pass is a route that **does not
exist today** (closed agent-format enum + fixed per-kind pass; no precedent — Cursor's `.mdc` rules
come from `[[extras.rules]]`+`canonical/rules/`, not from sub-agents). **Ruling: sub-agents→rules is
`[transform:engine]`** (a new agent-format/emitter that produces rule-shaped frontmatter, analogous
to but distinct from Copilot's E1).

- Alternatives compared: sub-agents→`.agent/rules/` (chosen) vs sub-agents→`.agent/workflows/`
  (frontmatter collapses to `description` only — also a reshape, also engine; rules are the better
  always-available context match for AID's always-loaded sub-agent personas).

**DEPENDENCY EDGE (explicit, the reason PLAN ordering hinges on this):**
**feature-003 (antigravity) DEPENDS ON feature-002 (copilot-cli)'s engine work** — specifically the
new-agent-format emitter machinery (E1-style: a per-format frontmatter emitter + widened
`_KNOWN_AGENT_FORMATS` + format-driven routing). feature-003 adds an Antigravity agent-format
(e.g. `"antigravity-rule"`) that reuses that machinery to emit `.agent/rules/*.md` with `trigger:`
frontmatter from the `canonical/agents/` pass. The **skills→`.agent/skills/`** half is independent
`[data]`, but the **sub-agents→rules** half makes feature-003 reuse feature-002's emitter
extension ⇒ **feature-002 must land before feature-003.** (Note: feature-002's E2 *skills* engine
work is dropped per Q-A, but its E1 *new-agent-format* machinery is what feature-003 reuses — so the
edge survives even after E2 is removed.)

### Q-E — `[model_tiers]` per tier alias per tool (simple-vs-detailed FORM)

Tier keys `_resolve_model` resolves are `large`/`medium`/`small` (confirmed: canonical agents
declare `tier: large|medium|small`, 10/9/3 of 22 — `grep '^tier:' canonical/agents/*/AGENT.md`).

**Copilot — SIMPLE form** (`tier = "model-string"`, like Claude Code/Cursor). Evidence: the CLI's
model selection is a plain string (`/model <name>`, `--model`, scalar `model:` frontmatter);
reasoning effort is a model-internal default, not a user-set per-tier knob (`[task-001 §6]`:
changelogs 2025-10-03 + 2026-04-17, DeepWiki model-selection page). Values (`[LIVE]` model identity
confirmed; slug spelling `docs-only-noted` per §0):
```toml
[model_tiers]
large  = "claude-opus-4.8"
medium = "claude-sonnet-4.6"
small  = "claude-haiku-4.5"
```
Source: `docs.github.com/en/copilot/reference/ai-models/supported-models` (accessed 2026-05-31) —
documented tiers most-capable=Opus 4.8, balanced=Sonnet 4.6, fast=Haiku 4.5; Opus 4.8 GA per
changelog 2026-05-28. All-Anthropic mapping chosen for consistency with claude-code/cursor profiles.

**Antigravity — DETAILED form** (`[model_tiers.<tier>]` with `model` + `reasoning_effort`, like
Codex). Evidence: Gemini 3 Pro is exposed in **(high)/(low)** reasoning variants alongside Gemini 3
Flash → a reasoning-effort knob exists, not a plain opaque string (`[antigravity §8]`). Recommended:
```toml
[model_tiers.large]
model            = "gemini-3-pro"
reasoning_effort = "high"
[model_tiers.medium]
model            = "gemini-3-pro"
reasoning_effort = "low"
[model_tiers.small]
model            = "gemini-3-flash"
```
**Residual `docs-only-noted` (Q-E Antigravity):** the docs label variants as **display names**
("Gemini 3 Pro (high)"), not as `model-id` + `reasoning_effort` token pairs. The detailed-form
*shape* is confirmed supported; the exact tokenization (`gemini-3-pro` + `reasoning_effort="high"`
vs a single `gemini-3-pro-high` id) is **not enumerated in the retrieved docs** — confirm against a
vendor Vertex/Gemini model-id reference before pinning the literal. Tier→variant assignment is an AID
choice, not vendor-fixed. Alternatives: detailed form (chosen, matches the high/low evidence) vs
simple form (rejected: would discard the documented reasoning-effort distinction).

### Q-F — `[tool_names]` per tool

Canonical tool tokens (confirmed `grep '^tools:' canonical/agents/*/AGENT.md`):
`Read, Glob, Grep, Bash, Write, Edit`.

**Copilot:** `[tool_names]` = **`Bash = "shell"`** only; `Read/Glob/Grep/Write/Edit` **pass through**
(no remap). Evidence (`[task-001 §7]`, configure-CLI + about-CLI pages): Copilot's controllable tool
vocabulary is **categories** — `shell` (all shell exec; the single home for AID's `Bash`), `write`
(file-modifying; covers `Write`/`Edit`), and `MCP_SERVER(tool)`. There is **no documented distinct
named tool for `Read`/`Glob`/`Grep`** (file read/search are built-in capability, not separately
remappable). `write` is a *permission category*, not a 1:1 tool rename, so `Write`/`Edit` are left as
identity passthrough rather than forced to `write`.
```toml
[tool_names]
Bash = "shell"
```
**Antigravity:** **empty map** (identity passthrough). `[GAP]` — vendor docs describe the IDE
"Terminal" surface and auto-execution policies but **do not publish an agent tool-call token map**
(no `Bash→Terminal` token confirmation, unlike Cursor's internally-confirmed remap). AID tool tokens
are Markdown instructions Antigravity reads as-is; no evidence it rejects "Bash". Alternatives:
empty-map/passthrough (chosen, safest given no published evidence) vs mirror Cursor's `Bash→Terminal`
(rejected — inference only, not documented). **Mark Q-F Antigravity `docs-only-noted`:** empty-map
recommended unless a vendor tool-token reference surfaces.
```toml
[tool_names]
# empty — identity passthrough (no published Antigravity tool-token map; docs-only-noted)
```

### Q-G — `[capabilities]` (all 4 flags) per tool

**Copilot CLI** (`[task-001 §8]`, all accessed 2026-05-31):

| Flag | Value | Evidence |
|---|---|---|
| `hooks` | **true** | First-class hooks (`.github/hooks/*.json`, `~/.copilot/hooks/`); full event list incl. `preToolUse`/`postToolUse`/`sessionStart`. Sources: use-hooks how-to + hooks-configuration reference. |
| `skill_chaining` | **true** | Skills exist (§A.2); agents orchestrate skills; multiple skills composable in a session. (Literal term "skill chaining" not doc-named → inferred-from-capability, lean true. community discussion #183962.) |
| `background_execution` | **true** | `/delegate` (async → branch+PR), `/tasks`, detached shells, `ctrl+x→b`, `/resume`. DeepWiki async-task-delegation + changelog 2025-10-28. |
| `stop_hook_autocontinue` | **true** | The `agentStop`/`Stop` (+`subagentStop`) hook can `"block"` and force continuation via its decision field — the documented Copilot equivalent of stop-hook auto-continue. Hooks-configuration reference. |

**Antigravity** (`[antigravity §10]`):

| Flag | Value | Evidence |
|---|---|---|
| `hooks` | **true** | Hooks defined as JSON; intercept before-tool-call / after-file-edit / on-session-start. `[LIVE-2nd]` |
| `skill_chaining` | **true** | Workflows can call other workflows (doc-confirmed composition); Skills invocable by the agent. `[LIVE-2nd]` for workflow chaining (`[GAP]` for strict SKILL.md→SKILL.md). |
| `background_execution` | **true** | CLI / Agent Manager dispatch async background subagents. `[LIVE-2nd]` |
| `stop_hook_autocontinue` | **false** | No documented stop-hook auto-continue loop. `[GAP]` → lean false (matches cursor's pinned value). |

### Q-H — Antigravity `project_context_file`: AGENTS.md vs GEMINI.md

**RULED: `AGENTS.md`** (single definite pick). Both are read+merged at session start; GEMINI.md
outranks AGENTS.md on conflict, **but AGENTS.md is the cross-tool canonical** AID should pick:
it is the open standard AID already emits for codex + cursor (`profiles/{codex,cursor}/AGENTS.md`),
keeping the Antigravity profile maximally consistent (REQUIREMENTS §8 "model on cursor"), and it is
a file Antigravity actually reads at the project root. `[LIVE-2nd, §B.3]`
```toml
[layout]
project_context_file = "AGENTS.md"
```
Alternatives compared: **AGENTS.md** (chosen — cross-tool canonical, matches existing profiles;
con: GEMINI.md outranks it, but AID needs no Antigravity-specific override) vs **GEMINI.md**
(rejected — Gemini-CLI global-path collision #16058, diverges from the cursor model, not the
cross-tool file). Note: GEMINI.md is *also* read but is reserved for tool-specific overrides AID does
not author.

### Q-I — Antigravity rule-file extension: `.mdc` vs `.md`

**RULED: `.md`** (plain Markdown + YAML frontmatter). Every current source shows
`.agent/rules/<name>.md`; **no** source shows Antigravity consuming `.mdc`. `[LIVE-2nd, §B.1/§4]`
Therefore `[[extras.rules]].filename` must use **`.md`** (e.g. `aid-methodology.md`), and the
frontmatter key must be **`trigger: always_on`** (Antigravity), **not** Cursor's `alwaysApply: true`.
The Antigravity profile **cannot reuse cursor's `.mdc` filenames verbatim** — extension AND
always-on frontmatter key both change. Alternatives: `.md` (chosen, evidence-backed) vs `.mdc`
(rejected — no source shows it).
```toml
[[extras.rules]]
filename = "aid-methodology.md"   # .md, NOT .mdc
# frontmatter uses trigger: always_on (not alwaysApply: true)
```

### Q-J — context-file production convention

**RULED (ground truth restated as fact):** each new provider's `project_context_file` is a
**committed, profile-local file authored from the shared ~27-line template** with that tool's
path/idiom substituted — **NOT rendered from canonical, NOT in any `emission-manifest.jsonl`** —
exactly as `profiles/{claude-code,codex,cursor}/` do today.

Verified ground truth:
- `canonical/` has **no context/instructions source** (it carries only `agents`, `recipes`, `rules`,
  `scripts`, `skills`, `templates` — confirmed `ls canonical/`), so there is **nothing to render a
  context document from**.
- The existing 3 profiles' context files (`profiles/claude-code/CLAUDE.md`,
  `profiles/codex/AGENTS.md`, `profiles/cursor/AGENTS.md`) are **hand-authored, git-committed, and
  appear in no `emission-manifest.jsonl`** (feature-002 SPEC §Grounding confirms commit `bf4e814`,
  un-rendered). They are near-identical (~27 lines), differing only in (a) filename header, (b) the
  tool-specific embedded path, (c) the KB-import idiom (`@.aid/knowledge.` vs prose).
- `project_context_file` is a real profile knob and `{project_context_file}` is a real substitution
  token consumed in *other* files' bodies (`substitute_filenames`, `render_lib.py`) — but **nothing
  emits the context document itself**.

**OOS / byte-identical-gate rationale:** shipping the context file as profile-local data adds **no
new canonical source** and changes **no existing-3 output** (REQUIREMENTS §4 Out of Scope), and the
byte-identical determinism gate is unaffected because a re-render **never touches an un-manifested
file** and the presence audit never expects it. **FR2's "context → AGENTS.md" / AC2 is therefore
satisfied as profile-local data, NOT via a new emitter.** **Ratifiable-emitter note:** this ruling
is ratifiable, not permanent — if the project later wants a single canonical context source + a
context-file emitter, that is a separate, larger change, **OOS today**. Both Copilot
(`profiles/copilot-cli/AGENTS.md`) and Antigravity (`profiles/antigravity/AGENTS.md`) ship their
`AGENTS.md` this way.

---

## E. FR1 Deliverable Contract — 14-row crosswalk

A definite value/ruling per row; a downstream implementer populates both profile TOMLs from this
table alone. No "TBD", no marker uncrossed.

| # | FR1-owned value / ruling | Ruling / value | Lands as | From |
|---|---|---|---|---|
| 1 | Copilot `.agent.md` frontmatter shape (fields + emission) | Emit `name, description, tools, model` (order); `tools` as YAML sequence (remapped); `model` via tier resolve; optional Copilot fields omitted | `[transform:engine]` — new E1 emitter (closed enum + fixed key set) | Q-A |
| 2 | New `agent.format` enum label | **`"copilot-agent"`** | `[transform:engine]` — add to `_KNOWN_AGENT_FORMATS`, wire validator + E1 branch + `.agent.md` suffix | Q-A |
| 3 | Copilot `[model_tiers]` strings | **simple:** `large="claude-opus-4.8"`, `medium="claude-sonnet-4.6"`, `small="claude-haiku-4.5"` (slug spelling `docs-only-noted`) | `[data]` `[model_tiers]` | Q-E |
| 4 | Antigravity `[model_tiers]` strings | **detailed:** `large`={gemini-3-pro, high}, `medium`={gemini-3-pro, low}, `small`={gemini-3-flash} (exact id/effort tokenization `docs-only-noted`) | `[data]` `[model_tiers]` | Q-E |
| 5 | Copilot `[tool_names]` map | `Bash = "shell"`; rest passthrough | `[data]` `[tool_names]` | Q-F |
| 6 | Antigravity `[tool_names]` map | **empty map** (identity passthrough; `docs-only-noted`) | `[data]` `[tool_names]` | Q-F |
| 7 | Copilot `[capabilities]` (4 flags) | `hooks=true, skill_chaining=true, background_execution=true, stop_hook_autocontinue=true` | `[data]` `[capabilities]` | Q-G |
| 8 | Antigravity `[capabilities]` (4 flags) | `hooks=true, skill_chaining=true, background_execution=true, stop_hook_autocontinue=false` | `[data]` `[capabilities]` | Q-G |
| 9 | Antigravity `project_context_file` | **`AGENTS.md`** | `[data]` `[layout].project_context_file` | Q-H |
| 10 | Antigravity rule-file extension | **`.md`** (`[[extras.rules]].filename = "*.md"`; `trigger:` frontmatter, not `alwaysApply:`) | `[data]` `[[extras.rules]].filename` | Q-I |
| 11 | Copilot MCP emit/omit | **`[omit]`** — AID ships no MCP servers (zero `mcp` matches in canonical/ + profiles); E3 not built | `[omit]` | Q-B |
| 12 | scripts/templates home (both tools) | Copilot `.github/scripts/` + `.github/templates/`; Antigravity `.agent/scripts/` + `.agent/templates/`; bare `scripts_dir="scripts"`/`templates_dir="templates"` (rewrite-agreement) | `[data]` `[layout]` dirs | Q-C |
| 13 | Antigravity cross-kind ruling + dependency edge | skills→`.agent/skills/` = `[data]`; **sub-agents→`.agent/rules/` = `[transform:engine]`** ⇒ **feature-003 DEPENDS ON feature-002's new-agent-format emitter machinery** (feature-002 before feature-003) | mixed; ruling FR1-owned | Q-D |
| 14 | Context-file production convention | Profile-local **committed** `AGENTS.md` authored from the shared ~27-line template; **not rendered**, **not in any emission-manifest**; satisfies FR2/AC2 as data; ratifiable-emitter note recorded | `[data]` committed profile-tree file + `[layout].project_context_file` | Q-J |

**Self-check vs SPEC §"Acceptance / Done":** both convention sections present + sourced ✔; mapping
table all 7 primitive rows + 5 profile-config rows × both tools ✔; every cell tagged, every
`[transform:engine]` names the renderer gap, every `[data]` names the TOML key ✔; Q-A..Q-J each
ruled (Q-E Antigravity tokenization, Q-F Antigravity, and the Copilot model-slug spelling are the
only `docs-only-noted` items, each with the residual gap stated) ✔; all 14 FR1 rows have a definite
value ✔; Q-D states the feature-003→feature-002 dependency edge ✔; Q-J states the production
convention + ground truth + OOS/byte-identical rationale + ratifiable note ✔; fork status recorded ✔.

---

## F. Confidence ledger (honest)

| Claim | Confidence |
|---|---|
| Copilot Agent Skills exist + `SKILL.md` + dirs (`.github/skills`, `.claude/skills`, `.agents/skills`) + `/skills`/`/<skill>` | **LIVE re-confirmed 2026-05-31** (add-skills page + 2025-12-18 changelog, both fetched) |
| Copilot agent frontmatter 9-field set; only `description` required; `handoffs`/`argument-hint` absent | **LIVE re-confirmed 2026-05-31** (custom-agents-configuration) |
| Copilot model identities (Opus 4.8 / Sonnet 4.6 / Haiku 4.5 GA) | **LIVE re-confirmed 2026-05-31** (supported-models + changelog 2026-05-28) |
| Copilot exact `model:` **slug** spelling (`claude-opus-4.8`) | **docs-only-noted** — reference pages rendered display names; confirm slug tokenization before pinning literal |
| Copilot model selection = plain string ⇒ simple `[model_tiers]` form | **LIVE/DeepWiki (task-001 §6)** — 3 sources |
| Copilot `[tool_names]` = `Bash→shell` only; Read/Glob/Grep no named tool | LIVE permission categories; "no named Read/Glob/Grep" is an **absence** finding (task-001 §7) |
| Copilot capabilities (4) | hooks/background/stop-continue LIVE; skill_chaining inferred-from-capability (literal term not doc-named) |
| Copilot MCP `[omit]` | **repo-verified** — zero `mcp` matches in `canonical/` + `profiles/*.toml` (2026-05-31) |
| Antigravity `.agent/rules/.md`, `.agent/workflows/.md`, `/workflow-name`, `~/.gemini/GEMINI.md`, native `.agent/skills/SKILL.md` | **LIVE-2nd** (mirror + 3 dev sources, task-002) |
| Antigravity `AGENTS.md` pick (Q-H) / `.md` extension (Q-I) | **LIVE-2nd** |
| Antigravity detailed `[model_tiers]` form (high/low knob) | **LIVE-2nd**; exact id/effort tokenization **docs-only-noted** |
| Antigravity `[tool_names]` empty-map | **docs-only-noted** — no published tool-token map |
| Antigravity capabilities (4) | hooks/background/skill_chaining LIVE-2nd; stop_hook_autocontinue **false (lean, GAP)** |
| Antigravity `.agent/` (singular) vs codelab `.agents/` (plural) | canonical `.agent/`; plural flagged for feature-003 awareness |
| Q-D sub-agents→rules = `[transform:engine]`; dependency edge | ruled against renderer constraints (closed enum, fixed per-kind pass, no sub-agent→rule precedent) |
| Context-file convention (Q-J), scripts/templates home (Q-C), MCP omit (Q-B), recipes [data] (unconditional render_recipes) | repo-verified + SPEC-grounded |
| Colleague's fork | **not provided** — proceeded docs-only, original no-fork implementation |

No invented/faked primitives. Every load-bearing claim is tied to a fetched source or repo
evidence; no claim rests on training data alone; no URLs fabricated. OOS boundary held — this doc
authors only `provider-mapping.md` (no `profiles/*.toml`, renderer, or setup-script change; no edits
to feature SPECs or REQUIREMENTS — divergences are flagged here only).

---

## Sources (all accessed 2026-05-31)

**Live re-verified this session:**
- Add agent skills (CLI): https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills
- Agent Skills launch changelog (2025-12-18): https://github.blog/changelog/2025-12-18-github-copilot-now-supports-agent-skills/
- Custom agents configuration (frontmatter reference): https://docs.github.com/en/copilot/reference/custom-agents-configuration
- Supported AI models: https://docs.github.com/en/copilot/reference/ai-models/supported-models
- Claude Opus 4.8 GA changelog (2026-05-28): https://github.blog/changelog/2026-05-28-claude-opus-4-8-is-generally-available-for-github-copilot/

**Carried from task-001 (copilot-cli-findings.md, vendor docs fetched 2026-05-31):** create-custom-agents-for-cli, add-custom-instructions, add-mcp-servers, cli-config-dir-reference, configure-copilot-cli, about-copilot-cli, use-hooks, hooks-configuration, cli-getting-started; changelogs 2025-10-28 / 2026-04-17 / 2025-10-03; npm `@github/copilot`; DeepWiki model-selection + async-task-delegation; community discussion #183962.

**Carried from task-002 (antigravity-findings.md, accessed 2026-05-31):** Context7 docs mirror (`/alphaperseii3000/google-antigravity-docs`, `/llmstxt/.../google_antigravity`); Atamel (2025-11-25); dev.to malloc72p; agentpedia.codes rule/AGENTS.md/CLI guides; Google Codelabs autonomous-pipelines; gemini-cli issue #16058.

**Repo evidence (this session):** `grep -ri 'mcp' canonical/ profiles/*.toml` → 0 matches;
`grep '^tier:' canonical/agents/*/AGENT.md` → large=10/medium=9/small=3; `grep '^tools:'` →
`Read,Glob,Grep,Bash,Write,Edit`; `ls canonical/` → no context source; `profiles/{cursor,codex}.toml`.
