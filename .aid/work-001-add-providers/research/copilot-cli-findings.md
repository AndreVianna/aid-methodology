# GitHub Copilot CLI — Extension-Model Raw Findings (task-001 / FR1)

> **Scope:** Raw, sourced findings on the *current* GitHub Copilot CLI extension model, to
> feed synthesis tasks task-003 / task-004 (provider-mapping.md). This is **not** the mapping
> doc; no profile TOML, renderer code, or disposition tags here.
> **Access date for all live claims:** 2026-05-31.
> **Method:** WebSearch + WebFetch against live GitHub Docs (`docs.github.com/en/copilot/...`),
> the `github/copilot-cli` repo / DeepWiki mirror, and the GitHub changelog. Context7 was not
> required — the primary vendor docs resolved directly and are the authoritative source.
> **Seed treatment:** REQUIREMENTS §2 conventions treated as a prior to CONFIRM, not trust. One
> seed assumption was found **outdated** (see the headline below and §2).

## HEADLINE — what changed vs. the REQUIREMENTS §2 seed

**The §2 seed claim "No user-defined slash-command / 'skills' primitive — only agents +
instructions" is NO LONGER TRUE.** GitHub shipped **Agent Skills** (a `SKILL.md` folder
primitive, explicitly invocable via `/<skill-name>`) to Copilot — including the **CLI** —
announced **2025-12-18**, after the §2 seed was captured. Copilot CLI now has **three**
user-extension primitives: **custom agents** (`.agent.md`), **agent skills** (`SKILL.md`), and
**custom instructions** (`AGENTS.md` etc.). This materially affects Q-A (skills no longer have
to be forced into `.agent.md` — there is now a native skill home) and the skill-primitive AC.
See §2 for the sourced detail and the actionable handoff.

---

## 1. Agent file convention (`.agent.md`)

**Paths (LIVE-CONFIRMED).**
- Repo-level: `.github/agents/NAME.agent.md` (version-controlled; shared with the team on push).
- User-level: `~/.copilot/agents/NAME.agent.md` (available across all sessions; under the config
  dir, so honors `COPILOT_HOME`).
- Extension: `.agent.md`. Filename charset restricted to `. - _ a-z A-Z 0-9`.
- Body limit: max 30,000 characters of Markdown instructions below the frontmatter.
- Source: GitHub Docs "Creating and using custom agents for GitHub Copilot CLI"
  https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-custom-agents-for-cli
  (accessed 2026-05-31); paths echoed by "Custom agents configuration"
  https://docs.github.com/en/copilot/reference/custom-agents-configuration (accessed 2026-05-31).

**Frontmatter field set (LIVE-CONFIRMED against the reference page).** From
https://docs.github.com/en/copilot/reference/custom-agents-configuration (accessed 2026-05-31):

| Field | Type | Required? | Allowed values / notes |
|---|---|---|---|
| `name` | string scalar | Optional | Display name; defaults to filename (minus `.agent.md`) if omitted. |
| `description` | string scalar | **Required** | Purpose/when-to-use; drives inference. |
| `target` | string scalar | Optional | `vscode` \| `github-copilot`; unset = both. |
| `tools` | list/array **or** comma-sep string | Optional | Tool names, `["*"]`, or `[]`. Default = all tools. |
| `model` | string scalar | Optional | Model identifier (see §6); inherits default if unset. |
| `user-invocable` | boolean | Optional | Default `true`. Controls whether `/agent` exposes it. |
| `disable-model-invocation` | boolean | Optional | Default `false`. Suppresses automatic inference selection. |
| `mcp-servers` | object/map | Optional | Inline MCP server config scoped to the agent. |
| `metadata` | object/map | Optional | String→string name/value pairs. |

- **Seed reconciliation:** seed listed `name, description, target, tools, model, user-invocable,
  mcp-servers, metadata` — **all eight CONFIRMED to exist.** Two refinements: (a) `description`
  is **required**, the rest optional; (b) the seed did **not** list `disable-model-invocation`
  (exists) and the VS-Code-only `infer` (now retired) / `handoffs` (NOT supported on the GitHub
  side) — see note below.
- **`handoffs` / `argument-hint` do NOT exist here** (LIVE-CONFIRMED): the reference states these
  VS Code properties "are currently not supported for Copilot cloud agent on GitHub.com." Treat
  `handoffs` as absent for the CLI mapping.
- **Confidence note:** the per-field type/required table above comes from the WebFetch summary of
  the reference page; the field *names* are corroborated across three independent pages (the CLI
  how-to, the reference, and a `github/copilot-cli-for-beginners` README). The exact required/
  optional split for the rarer fields (`target`, `metadata`) is reference-summary-level confidence
  — high, but task-004 should glance at the live reference table before pinning emitted key order.

**Invocation (LIVE-CONFIRMED).** Four ways (CLI how-to page, accessed 2026-05-31):
1. Interactive slash: `/agent` then pick from the list.
2. Explicit in-prompt: name the agent in the prompt.
3. Automatic inference: Copilot matches the prompt to an agent `description` (gated by
   `disable-model-invocation`).
4. Programmatic flag: `--agent NAME --prompt "..."` (NAME = filename without `.agent.md`).

---

## 2. Skill / slash primitive — **PRESENT** (seed correction)

**Copilot CLI HAS a user-defined skill primitive: Agent Skills (`SKILL.md`).** This is the most
important deviation from the seed.

- **Announced:** "GitHub Copilot now supports Agent Skills" — GitHub Changelog, **2025-12-18**
  https://github.blog/changelog/2025-12-18-github-copilot-now-supports-agent-skills/
  (accessed 2026-05-31).
- **CLI how-to (authoritative):** "Adding agent skills for GitHub Copilot CLI"
  https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills
  (accessed 2026-05-31). Confirms skills work **in the CLI** and adds CLI commands:
  `/skills list`, `/skills info`, `/skills reload`, `/skills remove`, `/skills add`.
- **Concept page:** "About agent skills"
  https://docs.github.com/en/copilot/concepts/agents/about-agent-skills (accessed 2026-05-31):
  "Agent skills work with Copilot cloud agent, the GitHub Copilot CLI, and agent mode in VS Code."

**Convention (LIVE-CONFIRMED):**
- A skill is a **folder** containing `SKILL.md` (Markdown + YAML frontmatter) plus optional
  bundled scripts/resources. "Copilot automatically discovers all of the files in the skill's
  directory and makes them available alongside the skill's instructions."
- **Project-skill directories:** `.github/skills/`, **`.claude/skills/`**, `.agents/skills/`.
- **Personal-skill directories:** `~/.copilot/skills/`, `~/.agents/skills/`.
- **`SKILL.md` frontmatter:** `name` (required; lowercase-hyphen id, usually = dir name),
  `description` (required; what it does + when to use it); optional `license`, `allowed-tools`
  (pre-approves tools, e.g. `shell`, without a confirmation prompt). Body = Markdown instructions.
- **Invocation:** automatic (Copilot picks by relevance to the `description`) **or** explicit via
  `/<skill-name>` in the prompt — i.e. there **is** a user-facing slash mechanism for skills.
- **Distribution:** `gh skill` (GitHub CLI) discovers/installs/updates/publishes skills from repos.

**Handoff to synthesis (alternatives compared — agent-home vs skill-home for AID skills):**
AID's 10 `canonical/skills/` now have **two** plausible Copilot targets, not one:
- **(A) skills → `SKILL.md`** (native kind match). Notably, `.claude/skills/` is an
  **accepted Copilot project-skill dir** — so AID's existing Claude-Code skill tree shape is
  directly reusable. AID's `SKILL.md` already carries `name`/`description`, matching Copilot's
  required pair; the references/ bodies survive as bundled folder files (Copilot auto-discovers
  them). This is the closer idiomatic fit and likely **less** renderer work than forcing skills
  into agents.
- **(B) skills → `.agent.md` agents** (the seed-era assumption, when no skill primitive existed).
  Still possible but now the *worse* fit: it collapses the skill's slash-invocation idiom into the
  agent idiom and needs the new agent-frontmatter emission path.
- **Recommendation for task-003/004:** re-evaluate Q-A. The "skills have no native home, so make
  them agents" premise is **obsolete**. Pre-empt: only AID **sub-agents** strictly need the
  `.agent.md` path; AID **skills** can map to `SKILL.md`. task-004 must still RULE which, but it
  should rule with the skill primitive now on the table.

---

## 3. Instructions / context files

**Files read by Copilot CLI (LIVE-CONFIRMED).** From "Adding custom instructions for GitHub
Copilot CLI" https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions
(accessed 2026-05-31) and the config-dir reference (accessed 2026-05-31):

- **`AGENTS.md`** (repo root, cwd, or any dir in `COPILOT_CUSTOM_INSTRUCTIONS_DIRS`) — **primary**
  instructions. Nearest `AGENTS.md` in the directory tree takes precedence.
- **`.github/copilot-instructions.md`** (repo) — repo-wide always-on instructions. If both this
  and root `AGENTS.md` exist, **both are used**.
- **`.github/instructions/**/*.instructions.md`** (repo) — path-scoped via `applyTo` frontmatter.
- **`CLAUDE.md` / `GEMINI.md`** (repo root) — also recognized as agent instructions (noted on the
  CLI instructions page; corroborates that `AGENTS.md` is the canonical one but model-named files
  are honored).
- **`$HOME/.copilot/copilot-instructions.md`** (user/global) — "personal custom instructions that
  apply to all your sessions, regardless of project." Honors `COPILOT_HOME`.
- **`~/.copilot/instructions/*.instructions.md`** (user/global) — additional personal instruction
  files loaded alongside the primary one (config-dir reference).

**Precedence (LIVE-CONFIRMED, with one soft spot).** Documented order:
primary (`AGENTS.md` / `.github/copilot-instructions.md`) → path-specific
(`.github/instructions/**`) → additional `AGENTS.md` from `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` →
local `$HOME/.copilot/copilot-instructions.md`. The docs explicitly say conflicting instructions
are resolved **non-deterministically** by the model, and that "instructions in both files are
used" when several apply — so this is a *merge with priority weighting*, not a hard override
chain. **Confidence:** order is doc-stated; the precise tie-break is doc-stated-as-nondeterministic
(not a gap — that IS the documented behavior).

**Seed reconciliation:** all four seed files CONFIRMED (`AGENTS.md`,
`.github/copilot-instructions.md`, `.github/instructions/**/*.instructions.md`,
`$HOME/.copilot/copilot-instructions.md`). Additions found: `CLAUDE.md`/`GEMINI.md`,
`~/.copilot/instructions/`, and the `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` env var.

**Handoff (alternatives — repo `AGENTS.md` vs user-home for AID context file):** for an AID
install, the project context file maps to repo-root **`AGENTS.md`** (the primary, team-shared,
nearest-wins file) — directly parallel to how the existing codex/cursor profiles already author
`AGENTS.md`. The user-home `$HOME/.copilot/copilot-instructions.md` is the alternative but is
machine-global, not project-scoped, so it is the wrong home for a per-project AID install. Pick:
repo-root `AGENTS.md`.

---

## 4. MCP config

**Location (LIVE-CONFIRMED).** From "GitHub Copilot CLI configuration directory" reference
https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference and
"Adding MCP servers for GitHub Copilot CLI"
https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers
(both accessed 2026-05-31):

- **User-level (default):** `~/.copilot/mcp-config.json` — servers available in all sessions.
- **`COPILOT_HOME` override:** replaces the *entire* `~/.copilot` path; mcp-config.json then lives
  under the overridden dir.
- **Schema:** root object is **`mcpServers`** (NOT `servers`). Each entry configures one server
  (local command / stdio etc.). Add interactively via `/mcp add` (writes to `~/.copilot` by
  default), or edit the file directly.
- **Repo-level vs user-home (alternatives, LIVE-CONFIRMED):** the canonical store is **user-home**
  `~/.copilot/mcp-config.json`. A repo can also ship `.copilot/mcp-config.json` at the project root
  for team standardization, and additional configs can be merged at runtime with
  **`--additional-mcp-config`** (merges project files into the global config). So: user-home is
  authoritative/default; repo-level + the merge flag is the team-sharing path.
- **Confidence:** user-home path + `mcpServers` key + `COPILOT_HOME` are reference-page LIVE. The
  repo-level `.copilot/mcp-config.json` + `--additional-mcp-config` merge detail comes from the
  how-to page summary plus a corroborating community article — **high** but task-004 should confirm
  the repo-root path spelling on the live how-to page before relying on it for an emitted location.

**Handoff:** if AID ships MCP servers, the natural emit target is repo-root
`.copilot/mcp-config.json` (team-shared, per-project) rather than the user-home global. If AID
ships **no** MCP servers, this is an omit. (task-004 makes the emit/omit call — Q-B.)

---

## 5. Install / CLI surface & discovery

**Install (LIVE-CONFIRMED).** From "Installing/Getting started with GitHub Copilot CLI"
https://docs.github.com/en/copilot/how-tos/copilot-cli/cli-getting-started and the npm package
https://www.npmjs.com/package/@github/copilot (accessed 2026-05-31):
- Primary: **`npm install -g @github/copilot`** (Node.js **22+** prerequisite).
- Also: WinGet (Windows), Homebrew (`brew install copilot-cli`, macOS/Linux), and an install
  script (macOS/Linux). Binary/command name: **`copilot`**.
- Auth: run `copilot`, then `/login`.

**Discovery (LIVE-CONFIRMED, synthesized from §§1–4).** Copilot CLI discovers extensions by
**convention-based path scanning**, not a registry:
- **Repo (cwd / git root):** `.github/agents/*.agent.md`, `.github/skills/` (+ `.claude/skills/`,
  `.agents/skills/`), `AGENTS.md`, `.github/copilot-instructions.md`,
  `.github/instructions/**/*.instructions.md`, repo `.copilot/mcp-config.json`, `.github/hooks/*.json`.
- **User-home config dir (`~/.copilot`, overridable by `COPILOT_HOME`):** `agents/`, `skills/`,
  `instructions/`, `copilot-instructions.md`, `mcp-config.json`, `settings.json`, `hooks/`,
  `config.json` (internal state — do not hand-edit).
- **Implication for AID's "get a tree onto a machine":** an AID install can be **purely
  file-drop** into the repo's `.github/` (+ `.claude/skills/`) tree and/or the user `~/.copilot/`
  tree — no plugin registration step. This matches AID's existing install model.

**Handoff (alternatives — repo vs user-home install root):** repo `.github/`-rooted install =
team-shared, version-controlled, project-scoped (parallels claude-code/codex/cursor repo trees).
User `~/.copilot/` install = machine-global. AID's per-project install model favors the
**repo `.github/` root**; `~/.copilot/` is the alternative for a global install option.

---

## 6. Q-E inputs — model strings per tier + model-tier FORM

**Model strings (LIVE-CONFIRMED).** From "Supported AI models in GitHub Copilot"
https://docs.github.com/en/copilot/reference/ai-models/supported-models (accessed 2026-05-31).
Exact slugs currently listed:
- Anthropic: `claude-haiku-4.5`, `claude-opus-4.5`, `claude-opus-4.6`, `claude-opus-4.6-fast`
  (preview), `claude-opus-4.7`, `claude-opus-4.8`, `claude-sonnet-4.5`, `claude-sonnet-4.6`.
- OpenAI: `gpt-4.1` (closing 2026-06-01), `gpt-5-mini`, `gpt-5.2` + `gpt-5.2-codex` (both closing
  2026-06-01), `gpt-5.3-codex`, `gpt-5.4`, `gpt-5.4-mini`, `gpt-5.4-nano`, `gpt-5.5`.
- Google: `gemini-2.5-pro`, `gemini-3-flash` (preview), `gemini-3.1-pro` (preview),
  `gemini-3.5-flash`.
- Other: `raptor-mini` (preview).
- **Documented capability tiers:** most-capable = **Claude Opus 4.8 / GPT-5.5**; balanced =
  **Claude Sonnet 4.6 / GPT-5.4**; fast = **Claude Haiku 4.5 / GPT-5 mini**.

**Tier-alias suggestion for AID's `large/medium/small` (handoff, NOT a final pick — task-004
rules):** a defensible all-Anthropic mapping consistent with AID's other profiles —
`large = claude-opus-4.8`, `medium = claude-sonnet-4.6`, `small = claude-haiku-4.5`. (task-004
should confirm which tier keys AID's canonical agents actually reference via `_resolve_model`.)

**Model-tier FORM (the load-bearing Q-E evidence).**
- The **CLI's own selection surface is a PLAIN model string**: `/model` opens a picker / `/model
  <model_name>` switches; the agent frontmatter `model:` field is a single scalar string; the
  `--model` flag takes one string. No reasoning-effort argument is part of CLI model *selection*.
  Sources: changelog "Enhanced model selection"
  https://github.blog/changelog/2025-10-03-github-copilot-cli-enhanced-model-selection-image-support-and-streamlined-ui/
  and "Auto model selection"
  https://github.blog/changelog/2026-04-17-github-copilot-cli-now-supports-copilot-auto-model-selection/
  (accessed 2026-05-31); DeepWiki `github/copilot-cli` "Model Selection & Usage"
  https://deepwiki.com/github/copilot-cli/3.4-model-selection-and-usage (accessed 2026-05-31).
- **Reasoning effort is a model-internal default, NOT a user-exposed per-tier knob in the CLI
  config.** DeepWiki states e.g. "Claude Opus 4.6 uses medium reasoning effort by default" and that
  "Auto mode" handles models that don't support a configured effort — i.e. effort is implicit per
  model, not a `model + reasoning_effort` pair the user sets per tier (unlike Codex's detailed
  form). **Confidence:** the plain-string selection is LIVE across 3 sources; the "no user-set
  per-tier effort knob" is DeepWiki-summary-level — strong, and consistent with the absence of any
  effort field in the live agent-frontmatter reference (§1, which has only scalar `model`).
- **Q-E FORM RULING EVIDENCE → SIMPLE.** Copilot CLI exposes only a plain `model = "model-string"`.
  The evidence supports the **simple `[model_tiers]` form** (`tier = "model-string"`, like
  Claude Code / Cursor) — **not** the Codex-style detailed
  `[model_tiers.<tier>] { model, reasoning_effort }`. task-004 can state simple form with this
  evidence; no inference from incomplete data required.

---

## 7. Q-F inputs — tool-name remaps

**Copilot does NOT use the AID tool vocabulary, but it is NOT a 1:1 rename map either
(LIVE-CONFIRMED).** From the configure-CLI page
https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/configure-copilot-cli
and the about-CLI concept page
https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli (accessed 2026-05-31):

- Copilot's tool/permission vocabulary is **category + permission-spec**, not a per-verb tool list:
  - **`shell`** — all shell command execution (parameterized: `shell(git)`, `shell(git push)`,
    `shell(rm)`). This is the single home for what AID splits as `Bash`.
  - **`write`** — file-modifying tools (covers AID's `Write`/`Edit`).
  - **`MCP_SERVER_NAME(tool_name)`** — MCP-provided tools.
  - Permission flags operate on these: `--allow-tool`, `--deny-tool`, `--allow-all-tools`,
    `--available-tools`, plus path/URL gates (`--allow-all-paths`, `--allow-url`, etc.).
- There is **no documented distinct named tool for `Read` / `Glob` / `Grep`** — file reading and
  searching are part of the agent's built-in capability surface, not separately named tools a user
  remaps. The agent `tools:` frontmatter restricts *access* (and accepts `["*"]` / `[]`), but the
  documented controllable categories are `shell`, `write`, and MCP tools.

**Q-F handoff (the actionable shape for `[tool_names]`):** Copilot CLI does **not** offer a
`Read→X`, `Glob→X`, `Grep→X`, `Edit→X` style 1:1 rename table the way Cursor remaps `Bash→Terminal`.
The only meaningful, sourced correspondence is **`Bash → shell`** (and AID's `Write`/`Edit` fall
under `write`). task-004 should treat `[tool_names]` for Copilot as **near-empty**: the only
defensible remap is `Bash = "shell"`; `Read/Glob/Grep/Write/Edit` have **no documented renamed
equivalent** and pass through (or, for `tools:` restriction purposes, are subsumed by the
`shell`/`write` categories). **Confidence:** LIVE on the permission categories; the "no named
Read/Glob/Grep tool" is an *absence* finding from the configure + concept pages (documented what
exists; these names do not appear) — flag as "absence, not contradicted, but a negative claim."

---

## 8. Q-G inputs — capability flags (all 4)

For `CapabilitiesConfig` = { `hooks`, `skill_chaining`, `background_execution`,
`stop_hook_autocontinue` }:

| Flag | Value | Evidence (LIVE unless noted) |
|---|---|---|
| `hooks` | **true** | Hooks are a first-class CLI feature. "Using hooks with GitHub Copilot CLI" + "GitHub Copilot hooks reference" (https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-hooks ; https://docs.github.com/en/copilot/reference/hooks-configuration , accessed 2026-05-31). `hooks.json` in `.github/hooks/*.json` (repo) / `~/.copilot/hooks/` (user) / inline in settings. Events: `sessionStart`, `sessionEnd`, `userPromptSubmitted`, `preToolUse`, `postToolUse`, `postToolUseFailure`, `agentStop`/`Stop`, `subagentStart`, `subagentStop`, `errorOccurred`, `preCompact`, `notification`. |
| `stop_hook_autocontinue` | **true** | The `agentStop`/`Stop` hook (and `subagentStop`) "can block and force continuation" via a decision field (`"block"` \| `"allow"`) — i.e. a stop hook can prevent the agent from stopping and force it to continue. Same hooks-reference source (accessed 2026-05-31). This is the documented Copilot equivalent of stop-hook auto-continue. |
| `background_execution` | **true** | `/delegate` (async delegate to coding agent → branch+PR in background), `/tasks` (manage background work), detached shell processes, `ctrl+x → b` to background a running task, `/resume <task-id>`. Sources: DeepWiki `github/copilot-cli` "Async Task Delegation" https://deepwiki.com/github/copilot-cli/3.8-async-task-delegation and changelog 2025-10-28 https://github.blog/changelog/2025-10-28-github-copilot-cli-use-custom-agents-and-delegate-to-copilot-coding-agent/ (accessed 2026-05-31). **Confidence:** LIVE feature existence; whether it matches AID's *exact* `background_execution` semantics is a task-004 judgment. |
| `skill_chaining` | **true (skills exist + are composable); LITERAL "chaining" = docs-only-noted** | Skills exist in the CLI (§2) and an agent "orchestrates skills"; skills are invoked automatically/explicitly and can be combined within a session. However, the docs do **not** use the exact term "skill chaining" or document a formal skill→skill chaining contract. So: the underlying capability (multiple skills usable/composed in a session, agents orchestrating skills) is **present**, but a literal `skill_chaining` guarantee is **not named in docs**. task-004 should set this with that nuance (lean true given skills + agent-orchestration, but record it as inferred-from-capability, not a doc-named flag). Sources: §2 skill sources + community discussion #183962 ("custom agents orchestrate skills") https://github.com/orgs/community/discussions/183962 (accessed 2026-05-31). |

---

## 9. Colleague's-fork status (STATE.md Q1)

**Fork URL was NOT provided.** Per STATE.md Q1 / REQUIREMENTS §8, the two public forks (`ubidev`,
`shake-k`) are on a pre-`profiles/` layout and do **not** contain the Copilot CLI work. Research
proceeded **docs-only**, building toward an **original implementation (no fork reference, no
fork)** per the user's decision. No fork layout decisions were folded in. If a URL arrives later,
task-003/004 can fold it in and re-tag affected cells; do not block on it.

---

## Sources (all accessed 2026-05-31)

**GitHub Docs — Copilot CLI (authoritative, primary):**
- Create custom agents (CLI): https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-custom-agents-for-cli
- Custom agents configuration (reference): https://docs.github.com/en/copilot/reference/custom-agents-configuration
- Add custom instructions (CLI): https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions
- Add agent skills (CLI): https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills
- About agent skills (concept): https://docs.github.com/en/copilot/concepts/agents/about-agent-skills
- Add MCP servers (CLI): https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers
- CLI config directory reference: https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference
- Configure Copilot CLI (tool permissions): https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/configure-copilot-cli
- About Copilot CLI (concept): https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli
- Use hooks (CLI): https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-hooks
- Hooks configuration reference: https://docs.github.com/en/copilot/reference/hooks-configuration
- Getting started / install: https://docs.github.com/en/copilot/how-tos/copilot-cli/cli-getting-started
- Supported AI models: https://docs.github.com/en/copilot/reference/ai-models/supported-models

**GitHub changelog / blog:**
- Agent Skills launch (2025-12-18): https://github.blog/changelog/2025-12-18-github-copilot-now-supports-agent-skills/
- Custom agents + delegate (2025-10-28): https://github.blog/changelog/2025-10-28-github-copilot-cli-use-custom-agents-and-delegate-to-copilot-coding-agent/
- Auto model selection (2026-04-17): https://github.blog/changelog/2026-04-17-github-copilot-cli-now-supports-copilot-auto-model-selection/
- Enhanced model selection (2025-10-03): https://github.blog/changelog/2025-10-03-github-copilot-cli-enhanced-model-selection-image-support-and-streamlined-ui/

**Repo / mirror (secondary, corroborating):**
- npm `@github/copilot`: https://www.npmjs.com/package/@github/copilot
- DeepWiki `github/copilot-cli` — Model Selection: https://deepwiki.com/github/copilot-cli/3.4-model-selection-and-usage
- DeepWiki `github/copilot-cli` — Async Task Delegation: https://deepwiki.com/github/copilot-cli/3.8-async-task-delegation
- Community discussion #183962 (agents vs skills vs instructions): https://github.com/orgs/community/discussions/183962

---

## Retrieval gaps / confidence ledger

**LIVE-CONFIRMED (vendor docs fetched directly, 2026-05-31):**
- Agent paths (`.github/agents/`, `~/.copilot/agents/`), `.agent.md` extension, invocation
  (`/agent`, `--agent`, in-prompt, inference). [§1]
- Full agent frontmatter field *names* (`name, description, target, tools, model, user-invocable,
  disable-model-invocation, mcp-servers, metadata`) and `handoffs` absence. [§1]
- **Skill primitive EXISTS** (`SKILL.md`, dirs, `/skills` commands, `/<skill>` invocation). [§2]
- Instructions files + documented precedence (incl. nondeterministic tie-break). [§3]
- MCP `~/.copilot/mcp-config.json`, `mcpServers` root key, `COPILOT_HOME`. [§4]
- Install (`npm i -g @github/copilot`, Node 22+, `copilot` binary, `/login`). [§5]
- Model slug list + capability tiers; CLI model selection is a plain string. [§6]
- Tool permission categories `shell` / `write` / `MCP_SERVER(tool)` + permission flags. [§7]
- Hooks feature + full event list + stop-hook block/continue; background `/delegate`+`/tasks`. [§8]

**REFERENCE/DEEPWIKI-SUMMARY confidence (high, but secondary or summary-level — verify before
pinning emitted values):**
- Exact required-vs-optional split for rarer agent fields (`target`, `metadata`) — §1. task-004
  should glance at the live reference table before fixing emitted key order.
- Repo-root `.copilot/mcp-config.json` + `--additional-mcp-config` merge — §4 (how-to summary +
  community article).
- "No user-set per-tier reasoning-effort knob in the CLI" — §6 (DeepWiki + absence in frontmatter
  reference). Strong, but a negative/absence claim.
- `skill_chaining` literal flag — §8: capability present, exact term not doc-named (lean true,
  recorded as inferred).
- Q-F: "no named Read/Glob/Grep tool" — §7 absence finding (documented what exists; these names do
  not appear).

**NOT model-knowledge-only:** every load-bearing claim above is tied to a fetched current source;
no claim rests solely on training data. No URLs were fabricated.

**Could-not-retrieve:** `https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-commands-reference`
returned HTTP 404 (likely renamed/moved); its content (model strings, tool names, flags) was
recovered from the supported-models reference, the configure-CLI page, and DeepWiki instead — so
no AC was left unmet by this 404.

**ACs not fully satisfiable here (by design — deferred to task-003/004):** this is the raw-findings
file; it does NOT emit profile TOML, the mapping table, or disposition tags (`[data]` /
`[transform:engine]` / `[omit]`) — those are task-003/004 per the task contract. All cover items
1–8 + fork status are captured and sourced.
