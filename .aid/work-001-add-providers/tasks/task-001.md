# task-001: Research latest GitHub Copilot CLI extension model

**Type:** RESEARCH

**Source:** feature-001-provider-research → delivery-001

**Depends on:** — (none)

**Scope:**
- Fetch the *current* GitHub Copilot CLI vendor docs (GitHub Docs "Copilot CLI" + "custom agents" + "MCP" pages, and `github/copilot-cli` repo README/docs) via Context7 / web fetch — not training data — and record the latest documented extension model. Treat the REQUIREMENTS §2 seed conventions as a prior to confirm, not ground truth.
- Produce raw findings (not the final mapping doc) covering, each with a doc URL + access date on every load-bearing claim:
  - **Agent file convention:** path(s) (repo `.github/agents/NAME.agent.md`; user `~/.copilot/agents/NAME.agent.md`), the exact `.agent.md` YAML frontmatter field shape (`name, description, target, tools, model, user-invocable, mcp-servers, metadata`), and invocation (`/agent`, `--agent`, inference).
  - **Skill/slash primitive existence:** confirm whether Copilot CLI has any user-defined skill/slash-command primitive (expected: none — agents + instructions only).
  - **Instructions/context file options:** `AGENTS.md` / `.github/copilot-instructions.md` / `.github/instructions/**/*.instructions.md` / `$HOME/.copilot/copilot-instructions.md`.
  - **MCP config:** location (`~/.copilot/mcp-config.json`, `COPILOT_HOME` override) and whether the tool reads repo-level vs user-home config.
  - **Install / CLI surface:** how a tree gets onto a user's machine and how Copilot CLI discovers it.
- Capture the data needed for downstream FR1 Q-E/Q-F/Q-G rulings (Copilot model strings per tier; any tool-name remaps Copilot uses; documented support for `hooks` / `skill_chaining` / `background_execution` / `stop_hook_autocontinue`), each sourced. For Q-E specifically, capture not just the model strings per tier alias but the **evidence of the model-tier form** — whether Copilot exposes only a plain `tier = "model-string"` (simple form) or also a reasoning-effort/detailed knob (`[model_tiers.<tier>]` with `model` + `reasoning_effort`) — so the synthesis (task-004) can state the simple-vs-detailed form per SPEC Q-E without inferring from incomplete evidence.
- Record the colleague's-fork status: per STATE.md Q1, the fork URL was **not provided** (the 2 public forks ubidev + shake-k are pre-`profiles/` and lack the work). State explicitly that research proceeds docs-only; do not block on it.
- Do NOT write `provider-mapping.md`, any profile TOML, renderer code, or disposition tags — this task only gathers and sources Copilot CLI facts for the synthesis tasks (task-003, task-004).

**Acceptance Criteria:**
- [ ] Latest Copilot CLI agent file convention recorded: path(s), full frontmatter field shape, and invocation method — each with a source reference (URL + access date).
- [ ] Skill/slash-primitive existence explicitly confirmed (present or absent), sourced.
- [ ] Instructions/context file options and MCP config location recorded, each sourced.
- [ ] Install / CLI discovery surface recorded, sourced.
- [ ] Raw inputs for Copilot Q-E (model strings per tier alias **and** the model-tier form evidence: whether a reasoning-effort/detailed-form knob exists vs simple `tier = "model-string"` only), Q-F (tool-name remaps), and Q-G (all 4 capability flags) captured with sources, sufficient for the synthesis (task-004) to state the simple-vs-detailed `[model_tiers]` form and rule each definitively.
- [ ] Colleague's-fork status recorded explicitly as "URL not provided — proceeded docs-only" per STATE.md Q1.
- [ ] At least 2 alternatives compared where applicable (e.g. agent-vs-instructions home for skills; repo-vs-user-home config locations), sources cited, with an actionable handoff for the synthesis task.
- [ ] All §6 quality gates pass (no invented/faked conventions; claims tied to current documented sources).
