# Google Antigravity — Raw Research Findings (task-002)

> **Task:** task-002 (RESEARCH) of work-001-add-providers. Confirm/correct the CURRENT Google
> Antigravity conventions vs the REQUIREMENTS §2/§8 seed, sourced. **This is raw findings only** —
> NOT `provider-mapping.md`, profile TOML, renderer code, or disposition tags (those are
> task-003/task-004). Downstream consumers: SPEC Key Questions Q-D / Q-E / Q-F / Q-G / Q-H / Q-I.
>
> **Access date for ALL live retrievals below: 2026-05-31.**
> **Confidence legend:** `[LIVE]` = retrieved from a current doc/source this session; `[LIVE-2nd]` =
> corroborated by ≥2 independent current sources; `[GAP]` = could not retrieve a canonical vendor
> page (states fallback); `[MODEL]` = model knowledge (Jan 2026 cutoff), flagged for live confirm.

---

## 0. Headline answers (TL;DR for synthesis)

| Question | Ruling | Confidence |
|---|---|---|
| Rules dir | `.agent/rules/*.md` (singular `.agent`) — project; `~/.gemini/GEMINI.md` — global | `[LIVE-2nd]` |
| Workflows dir | `.agent/workflows/*.md`, slash-invoked `/workflow-name` (e.g. `/generate-unit-tests`) | `[LIVE-2nd]` |
| Rule/workflow file extension (Q-I) | **`.md`** (plain Markdown + YAML frontmatter). **NOT `.mdc`.** | `[LIVE-2nd]` |
| Rule frontmatter | YAML: `trigger:` (enum `always_on` / `model_decision` / `glob` / `manual`) + `description:` + `globs:` (for glob trigger) | `[LIVE-2nd]` |
| Workflow frontmatter | YAML: `description:` only (thin) | `[LIVE-2nd]` |
| Context file (Q-H) | Both `AGENTS.md` AND `GEMINI.md` read; **GEMINI.md wins on conflict**, but **AGENTS.md is the cross-tool canonical** AID should pick | `[LIVE-2nd]` |
| Custom sub-agent FILE convention | **ABSENT.** No user-authored sub-agent file. Customization = rules + workflows + skills. (Browser subagent is built-in; CLI background subagents are runtime-spawned.) | `[LIVE-2nd]` |
| Antigravity ≈ Cursor (§8) | **Mostly valid** (VS Code-fork, `.mdc`-style rules with trigger/glob/always-on, slash-workflows). **Two corrections:** dir is `.agent/` not `.cursor/`; extension is `.md` not `.mdc`. | `[LIVE-2nd]` |
| Cross-kind lean (Q-D) | Rules & workflows are **plain Markdown in renamed dirs, thin/absent frontmatter** → leans `[data]`. BUT Antigravity ALSO has a native `.agent/skills/` (SKILL.md) primitive — see §7 nuance. | `[LIVE-2nd]` |
| Q-E model form | **Detailed form** signal present: Gemini 3 Pro exposes **(high)/(low)** reasoning variants alongside Gemini 3 Flash → reasoning-effort knob exists, not plain-string-only | `[LIVE-2nd]` |
| Q-F tool names | Docs do NOT enumerate an agent shell-tool token; IDE surface is "Terminal". Bash→Terminal remap is **plausible but UNCONFIRMED** at the tool-token level | `[GAP]` |
| Q-G capabilities | `hooks` = **true**; `background_execution` = **true**; `skill_chaining` = **true** (workflows call workflows); `stop_hook_autocontinue` = **no direct evidence** (lean false) | `[LIVE-2nd]` / `[GAP]` |

---

## 1. Rules — `.agent/rules/*.md`

**Confirmed `[LIVE-2nd]`:**
- Workspace/project rules live in **`.agent/rules/`** (singular `.agent`) at the workspace / Git-repo
  root. Files are **Markdown (`.md`)**.
- Global rules live in **`~/.gemini/GEMINI.md`** (a single file, not a dir of rule files).
- Rule **activation modes** (the doc-canonical enum): **Manual** (`@`-mention), **Always On**
  (every conversation), **Model Decision** (applied based on a natural-language `description`), and
  **Glob** (applied to files matching a pattern, e.g. `*.js`, `src/**/*.ts`).
- Rule-file **YAML frontmatter** observed in current third-party guides:
  ```yaml
  ---
  trigger: always_on
  ---
  ```
  ```yaml
  ---
  trigger: model_decision
  description: Backend rules for Server Actions, Prisma, Auth, etc.
  ---
  ```
  So the frontmatter key is **`trigger`** (enum `always_on` / `model_decision` / `glob` / `manual`),
  plus **`description`** (used by `model_decision`) and **`globs`** (for the `glob` trigger).
  Vendor-doc prose maps 1:1 to this: Always On / Model Decision / Glob / Manual.

**Correction vs REQUIREMENTS §2 seed:** the seed said "`.agent/rules/*.md` + `AGENTS.md`/`GEMINI.md`
(project); `~/.gemini/…` (global)". The **path and extension are confirmed correct** (`.agent/rules/`,
`.md`). The global file is specifically **`~/.gemini/GEMINI.md`** (the seed's "`~/.gemini/…`" is
correct but underspecified). The seed listing `AGENTS.md`/`GEMINI.md` as "rules" conflates the
**context/instructions files** (§3, Q-H) with the **`.agent/rules/` rule files** — they are distinct
layers (see §3).

**Note vs Cursor frontmatter:** Cursor `.mdc` uses `description` + `alwaysApply` + `globs`.
Antigravity `.md` uses `trigger` (enum) + `description` + `globs`. The semantics overlap (always-on,
glob-scoped, model-decided) but the **key names differ** (`trigger: always_on` vs `alwaysApply: true`)
and the **extension differs** (`.md` vs `.mdc`). This is the load-bearing Q-I / §5 correction.

---

## 2. Slash-workflows — `.agent/workflows/*.md`

**Confirmed `[LIVE-2nd]`:**
- Workspace workflows live in **`.agent/workflows/`**; global workflows at
  `~/.gemini/antigravity/global_workflows/`.
- Workflows are **saved Markdown files** that register a slash command in the Agent chat. Invoked as
  **`/workflow-name`** (the doc's own example pattern; the live tutorial shows typing `/generate`
  auto-completing to `generate-unit-tests`). This **confirms the REQUIREMENTS §2 `/generate-unit-tests`
  example verbatim**.
- Workflows **can call other workflows** (composition) — load-bearing for Q-G `skill_chaining`.
- Workflow **frontmatter** is thin — only a `description`:
  ```yaml
  ---
  description: Start the Autonomous AI Developer Pipeline sequence with a new idea
  ---
  ```
- `// turbo` inline comments inside a workflow mark steps for automatic (no-confirm) execution.
- Doc framing: **Rules = persistent prompt-level context; Workflows = trajectory-level step
  sequences triggered on demand.**

---

## 3. Context/instructions file — `AGENTS.md` vs `GEMINI.md` (Q-H input)

This is the most nuanced area; multiple independent current sources agree on the **layering**:

**Confirmed `[LIVE-2nd]`:**
- Antigravity **reads BOTH** `AGENTS.md` and `GEMINI.md` at session start (project root + global
  `~/.gemini/`), **merging** them.
- **Precedence on conflict: System Rules → GEMINI.md → AGENTS.md → `.agent/rules/*.md`.**
  i.e. **GEMINI.md takes precedence** over AGENTS.md for conflicting directives, and `.agent/rules/`
  are "applied last / good for organizing rules by concern."
- **Roles (the recommended split):** `AGENTS.md` = **cross-tool foundation** (the open
  `AGENTS.md` standard shared with Cursor / Claude Code / Codex); `GEMINI.md` =
  **Antigravity-specific overrides**.
- Nested/sub-directory `AGENTS.md` files (e.g. `src/components/AGENTS.md`) are also recognized.
- Known conflict (corroborating that GEMINI.md is the Gemini-lineage global): Antigravity global
  rules and Gemini CLI global context **both write `~/.gemini/GEMINI.md`** (filed as gemini-cli
  issue #16058) — confirms `~/.gemini/GEMINI.md` is the real global path and that GEMINI.md is the
  Gemini-native file.

**Alternatives compared (the AC requires ≥2):**
- **`AGENTS.md`** — PRO: it is the **cross-tool open standard AID already emits for codex + cursor**
  (`profiles/codex/AGENTS.md`, `profiles/cursor/AGENTS.md` are both `AGENTS.md`); reusing it keeps the
  Antigravity profile maximally consistent with the existing cursor model (REQUIREMENTS §8). CON:
  GEMINI.md outranks it on conflict, so any Antigravity-specific override would need GEMINI.md.
- **`GEMINI.md`** — PRO: Antigravity-canonical, highest user priority. CON: Gemini-CLI global-path
  collision (#16058); not the cross-tool file AID's other profiles use; would diverge from the
  "model on cursor" directive.

**Actionable handoff to task-004 (Q-H):** the evidence supports a **single definite pick of
`AGENTS.md`** for `[layout].project_context_file` — it is the file Antigravity *does* read at the
project root, it is the cross-tool canonical, and it matches the codex/cursor profiles AID already
ships (Q-J says context files are authored profile-local data, identical idiom). GEMINI.md is read
too but is reserved for tool-specific overrides AID does not need. This is enough for task-004 to
commit to one value; record that both are read with AGENTS.md as the AID canonical.

---

## 4. Rule-file extension — `.mdc` vs `.md` (Q-I input)

**Confirmed `[LIVE-2nd]`: Antigravity rule files are `.md` (plain Markdown + YAML frontmatter),
NOT Cursor's `.mdc`.** Every current source — the official docs mirror, the Atamel dev post, the
agentpedia rule guide, and the dev.to walkthrough — shows `.agent/rules/<name>.md` and YAML-frontmatter
Markdown. No source shows Antigravity consuming a `.mdc` file. The skills use `SKILL.md`; workflows
use `<name>.md`; rules use `<name>.md`.

**Binary ruling evidence for task-004 (Q-I): `.md`.** AID's cursor profile emits `.mdc`
(`[[extras.rules]].filename = "aid-methodology.mdc"`). For Antigravity the extension must be **`.md`**,
and the frontmatter key must be **`trigger: always_on`** (Antigravity) rather than Cursor's
`alwaysApply: true`. So the Antigravity profile cannot reuse cursor's `.mdc` filenames verbatim —
the **extension and the always-on frontmatter key both change**.

---

## 5. "Antigravity ≈ Cursor" assumption (REQUIREMENTS §8) — validate/correct

**Verdict: substantially VALID with two concrete corrections.** `[LIVE-2nd]`

Valid (Windsurf-lineage / VS Code-fork similarities):
- Both are agent-first VS Code forks with an editor-embedded chat.
- Both have **always-on / glob-scoped / model-decided rule files** with YAML frontmatter +
  Markdown body (Cursor `.mdc`; Antigravity `.md`).
- Both have **slash-invoked saved prompts** (Cursor: skills/commands; Antigravity: `.agent/workflows/`).
- Both read **`AGENTS.md`** at the project root.

Corrections (do NOT copy cursor verbatim):
1. **Directory root differs:** Cursor uses `.cursor/` (`rules/`, `agents/`, etc.); Antigravity uses
   **`.agent/`** (`rules/`, `workflows/`, `skills/`). Global config differs too (`~/.gemini/`).
2. **Rule extension + frontmatter key differ:** Cursor `.mdc` + `alwaysApply`/`globs`/`description`;
   Antigravity **`.md` + `trigger`(enum)/`globs`/`description`**.
3. **Antigravity additionally has a native first-class Skills primitive** (`.agent/skills/<folder>/SKILL.md`)
   that Cursor's profile does not model — relevant to Q-D (see §7). And Antigravity has **no
   `.cursor/agents/`-style sub-agent file** (Cursor profile ships `.cursor/agents/*.md`; Antigravity
   has no equivalent author convention — §6).

So "model the Antigravity profile on the cursor profile" is the right *starting point*, but it is a
**rename-dir + change-extension + change-frontmatter-key** adaptation, plus a decision about whether
to use the native Skills primitive (§7), not a byte-clone.

---

## 6. Custom sub-agent FILE convention — present or absent?

**Confirmed ABSENT `[LIVE-2nd]`.** Antigravity has **no user-authored custom sub-agent file**
convention (nothing analogous to Claude Code's `.claude/agents/<name>.md` or Cursor's
`.cursor/agents/<name>.md`). The customization surface is **Rules + Workflows + Skills**.

Two things that are NOT a user-authored sub-agent file (to avoid confusion downstream):
- **Browser subagent** — a **built-in** specialized agent (driven by "Gemini 2.5 Pro UI Checkpoint")
  for browser actuation. Not user-defined; not a file you author.
- **CLI/Agent-Manager background subagents** — the main agent can **spawn focused subagents at
  runtime** for parallel/async work. These are runtime-orchestrated, **not declared in author files**.

**Handoff:** matches the REQUIREMENTS §2 expectation ("no custom *sub-agent* file convention").
AID's 22 `canonical/agents/` sub-agents therefore have **no native 1:1 home** in Antigravity — they
must be transformed into rules or workflows (or skills). This is the substance of Q-D (§7).

---

## 7. Cross-kind evidence (Q-D input) — `[data]` vs `[transform:engine]`

**The decision rule (from SPEC Q-D):** if Antigravity rules/workflows are just Markdown files in
renamed dirs with the **same body** and **thin/absent frontmatter**, the mapping leans `[data]`
(feature-003 does NOT depend on feature-002's engine). If sub-agents must be **transformed** into a
different artifact shape (frontmatter dropped/renamed, body reshaped) to live as rules, it leans
`[transform:engine]` (feature-003 reuses feature-002 engine work). **task-004 makes the binding
ruling against the actual renderer; this section provides the convention-shape evidence.**

**Evidence gathered (`[LIVE-2nd]`):**
- **Rules** = plain Markdown body + thin YAML frontmatter (`trigger` + optional `description`/`globs`).
- **Workflows** = plain Markdown body + thinnest frontmatter (`description` only).
- **Skills** = plain Markdown `SKILL.md` (frontmatter `name` + `description`) + a body — **the same
  shape AID skills already have** (`canonical/skills/aid-*/SKILL.md`).

**What this means for the two candidate mappings (≥2 alternatives, per AC):**

- **skills → `.agent/workflows/`** vs **skills → `.agent/skills/`.** Antigravity has BOTH a workflows
  primitive AND a native Skills primitive whose `SKILL.md(name, description)` shape is **near-identical
  to AID's own skills**. Mapping AID skills to **`.agent/skills/`** is the lower-impedance option (same
  `SKILL.md` + `references/` decomposition AID already produces); mapping them to `.agent/workflows/`
  gains slash-invocation but loses the SKILL.md packaging. **Convention-shape lean: AID skills → either
  is plain-Markdown-in-renamed-dir → supports `[data]`** (the body survives unchanged; only the target
  dir and possibly frontmatter trimming differ). task-004 picks which dir; both are data-shaped.

- **sub-agents → `.agent/rules/`** vs **sub-agents → `.agent/workflows/`.** AID sub-agents
  (`canonical/agents/*/AGENT.md`, frontmatter `name/description/tools/model` + Markdown body) have **no
  native Antigravity sub-agent home (§6)**. To live as **rules**, the AGENT frontmatter
  (`name/description/tools/model`) must be **dropped/replaced** with the rule frontmatter
  (`trigger`/`description`/`globs`) — a frontmatter **reshape**, even though the Markdown body can carry
  over. To live as **workflows**, frontmatter collapses to `description` only — also a reshape. **So
  sub-agents→rules/workflows is NOT a same-body-same-frontmatter rename** the way Cursor's clean
  per-kind dir mapping is.

**Lean for task-004:** The *body* is plain Markdown in renamed dirs (data-shaped); the **frontmatter
must be reshaped** for sub-agents→rules/workflows (AGENT keys → rule/workflow keys). Whether that
reshape is reachable by existing profile data or needs new emitter code is the **renderer-validation
call task-004 must make against `render_agents.py` / `aid_profile.py`** (SPEC notes the current
`render_agents.py` hardcodes the emitted frontmatter to `name/description/tools/model` and the
agent-format enum is closed `{markdown, toml}` — so emitting `trigger:`-style rule frontmatter from the
agents pass is very likely **`[transform:engine]`**). **This findings doc does NOT assign the tag**
(out of scope per task contract) — it supplies the shape evidence: *bodies are data-shaped; sub-agent
frontmatter is reshaped, which is the cross-kind risk the Q-D ruling turns on.*

> **Genuinely-new-question note (from SPEC):** the existing Cursor profile does NOT derive `.mdc`
> rules from `canonical/agents/` — Cursor rules come from `[[extras.rules]]` + a separate rule source,
> not sub-agents. So "Antigravity sub-agents → rules" has no solved precedent in the codebase; it is a
> new routing question, which is exactly why Q-D is the top risk.

---

## 8. Q-E inputs — model strings per tier + model-tier FORM

**Reasoning models offered for the core agent (`[LIVE-2nd]`, official docs mirror):**
- **Gemini 3 Pro (high)**
- **Gemini 3 Pro (low)**
- **Gemini 3 Flash**
- Claude Sonnet 4.5 / Claude Sonnet 4.5 (thinking) / Claude Opus 4.5 (thinking) / GPT-OSS
  (Antigravity is multi-model via the Vertex Model Garden; user selects in a dropdown, sticky per turn.)

**Non-customizable internal models (not tier-eligible, FYI only):** Nano Banana Pro (image),
Gemini 2.5 Pro UI Checkpoint (browser subagent), Gemini 2.5 Flash (checkpointing/summarization),
Gemini 2.5 Flash Lite (semantic search).

**Model-tier FORM evidence (the load-bearing Q-E signal):** Gemini 3 Pro is exposed in **two
reasoning variants — `(high)` and `(low)`** — alongside a separate **Gemini 3 Flash**. This is a
**reasoning-effort distinction baked into the model selection**, i.e. the Gemini-3 lineage exposes a
**reasoning-effort knob**, not a plain opaque model string only. This is the **same shape as Codex's
detailed form** (`[model_tiers.<tier>]` with `model` + `reasoning_effort`) rather than Claude
Code/Cursor's simple `tier = "model-string"`. **Handoff to task-004:** the Antigravity/Gemini-lineage
model-tier form can be expressed in the **detailed form** (e.g. `large = Gemini 3 Pro / high`,
`medium = Gemini 3 Pro / low` or `Gemini 3 Flash`, `small = Gemini 3 Flash`), and the docs support a
reasoning-effort knob existing. **Caveat `[GAP]`:** the docs label variants as display names
("Gemini 3 Pro (high)") not as API model-id + reasoning_effort token pairs; the exact API string
form (`gemini-3-pro` + `reasoning_effort = "high"` vs a single `gemini-3-pro-high` id) is **not
enumerated in the retrieved docs** — task-004 should state the detailed-form *shape* is supported and
flag the exact id/effort tokenization as needing a vendor model-id reference if a precise string is
required. Tier→model assignment (which Gemini variant is large/medium/small) is an AID mapping choice,
not a vendor-fixed mapping.

---

## 9. Q-F inputs — tool-name remaps (confirm Bash→Terminal etc.)

**Status: `[GAP]` — could NOT confirm an agent tool-call token rename.** The retrieved docs:
- Describe the IDE **"Terminal"** surface (toggle `Cmd/Ctrl + J`) and **"terminal command
  auto-execution policies"** (Request Review / Always Proceed allowlist/denylist).
- Do **NOT** enumerate the agent's internal tool-call vocabulary (no published list of tool tokens
  like `Read`/`Glob`/`Grep`/`Bash`/`Write`/`Edit`). No source names whether the shell tool token is
  `Terminal`, `run_command`, `Bash`, or other.

**Handoff to task-004 (Q-F):** unlike Cursor (where AID confirmed `Bash → Terminal` via internal
tech-debt notes), Antigravity's docs do **not** publish a tool-token map. Two defensible options for
task-004, both must be marked:
- **(a) Empty remap (identity passthrough)** — safest given no published evidence of token renames;
  `_remap_tools` passes everything through. **Lean: this**, since AID's tool tokens are instructions
  to the model in Markdown bodies, and Antigravity reads Markdown instructions as-is; there is no
  evidence it rejects the token "Bash".
- **(b) Mirror Cursor's `Bash → Terminal`** — by §5 lineage analogy and the IDE's "Terminal" framing,
  but this is **inference, not documented**, and must be tagged unconfirmed.
- Mark Q-F **docs-only-noted**: vendor docs do not publish a tool-name map; recommend empty-map unless
  a vendor tool reference surfaces.

---

## 10. Q-G inputs — capability flags

Per `CapabilitiesConfig` (`hooks`, `skill_chaining`, `background_execution`, `stop_hook_autocontinue`):

| Flag | Value | Evidence | Confidence |
|---|---|---|---|
| `hooks` | **true** | Antigravity 2.0 / CLI support **Hooks** "defined as JSON," intercepting lifecycle moments — **before a tool call, after a file edit, on session start**. | `[LIVE-2nd]` |
| `background_execution` | **true** | Antigravity CLI / Agent Manager dispatch **asynchronous background subagents**; main agent spawns focused subagents for parallel work while you keep prompting. | `[LIVE-2nd]` |
| `skill_chaining` | **true** | **Workflows can call other workflows** (doc-confirmed composition); Skills framework is invocable by the agent. Workflow→workflow chaining is the direct analog of skill-chaining. | `[LIVE-2nd]` (workflow chaining); `[GAP]` if "skill" means strictly the SKILL.md primitive chaining |
| `stop_hook_autocontinue` | **false (lean)** | **No direct evidence** of a stop-hook auto-continue mechanism in retrieved docs. Hooks exist (incl. session lifecycle) but no documented "stop hook → auto-continue" loop like Claude Code's. Cursor profile also sets this `false`. | `[GAP]` → lean **false** |

**Handoff:** `hooks` / `background_execution` / `skill_chaining` are **live-confirmed true**;
`stop_hook_autocontinue` is **unconfirmed — recommend false** (matches cursor's pinned value and the
absence of documented evidence). task-004 sets the four flags from this row.

---

## 11. Colleague's fork status

N/A to Antigravity (the fork concerns Copilot CLI, not this task). Recorded for completeness: the
Copilot fork URL was not provided per STATE.md Q1; that is the Copilot task's concern.

---

## Sources

All accessed **2026-05-31**.

1. Official docs mirror via Context7 — `/alphaperseii3000/google-antigravity-docs` (Source Reputation:
   Medium) and `/llmstxt/.../google_antigravity/llms-full_txt` (High). Confirmed: `.agent/rules/`,
   `~/.gemini/GEMINI.md`, rule activation modes (Manual/Always On/Model Decision/Glob), `/workflow-name`
   invocation + workflow-calls-workflow, `.agent/skills/<folder>/SKILL.md` (name+description),
   reasoning models (Gemini 3 Pro high/low, Gemini 3 Flash, Claude Sonnet/Opus 4.5, GPT-OSS),
   non-customizable internal models, MCP support, browser subagent (built-in), terminal
   auto-execution policies.
2. Official docs page (attempted): `https://antigravity.google/docs/rules-workflows` and
   `https://antigravity.google/docs/home` — **`[GAP]`: WebFetch returned only the page title (JS-rendered
   SPA), no body**. Conventions confirmed instead via the Context7 mirror (#1) + dev sources (#3-#7).
3. Mete Atamel, "Customize Google Antigravity with rules and workflows" (2025-11-25),
   `https://atamel.dev/posts/2025/11-25_customize_antigravity_rules_workflows/` — confirmed `.agent/rules/`
   + `.agent/workflows/` (singular), `.md`, `/generate-unit-tests` slash example, `~/.gemini/GEMINI.md`
   global, `~/.gemini/antigravity/global_workflows/`.
4. dev.to (malloc72p), "AntiGravity: Getting the Most Out of Agentic Coding with Rules, Skills, and
   Workflows" — confirmed rule frontmatter `trigger: always_on` / `trigger: model_decision` +
   `description`; workflow frontmatter `description`; `// turbo` auto-exec; `.agent/rules` + `.agent/workflows`.
5. agentpedia.codes, "Antigravity Rules: Guide with AGENTS.md & Examples (2026)"
   (`/blog/user-rules`) and "AGENTS.md Guide: Cross-Tool Rules for Antigravity (2026)"
   (`/blog/antigravity-agents-md-guide`) — confirmed precedence **System Rules → GEMINI.md → AGENTS.md
   → .agent/rules/**, both files read+merged at session start, AGENTS.md as cross-tool foundation,
   nested `AGENTS.md`, `.md` extension.
6. agentpedia.codes, "Antigravity CLI Deep Dive: Google's Go-Based Terminal Agent (May 2026)"
   (`/blog/antigravity-cli-deep-dive`) — Hooks (JSON; before-tool-call / after-file-edit / on-session-start),
   async background subagents, Skills/Hooks/Subagents/MCP/Plugins extensibility; **no user-authored
   sub-agent file convention documented; no agent tool-token map; no skill-chaining specifics**.
7. Google Codelabs, "Build Autonomous Developer Pipelines using agents.md and skills.md in Antigravity"
   (`codelabs.developers.google.com/autonomous-ai-developer-pipelines-antigravity`) — **divergent
   naming: this codelab uses `.agents/` (plural) + `agents.md` + `.agents/skills/*.md`.** Treated as a
   tutorial-author variation / possible older convention; the **official mirror (#1) + Atamel (#3) +
   dev.to (#4) all use `.agent/` (singular)**, which is taken as canonical. Flagged as a naming
   discrepancy task-004 should be aware of.
8. github.com/google-gemini/gemini-cli issue #16058 — corroborates `~/.gemini/GEMINI.md` as the real
   Gemini-lineage global path (Antigravity + Gemini CLI both write it).

---

## Retrieval gaps / confidence ledger

| Claim | Status |
|---|---|
| `.agent/rules/` + `.agent/workflows/` (singular), `.md` extension | `[LIVE-2nd]` (mirror + 3 dev sources) |
| Rule frontmatter `trigger` enum (always_on/model_decision/glob/manual) + `description`/`globs` | `[LIVE-2nd]` (mirror prose + dev.to frontmatter examples) |
| Workflow `/workflow-name` slash + workflow-calls-workflow | `[LIVE-2nd]` |
| `~/.gemini/GEMINI.md` global; `~/.gemini/antigravity/global_workflows/` | `[LIVE-2nd]` |
| Both AGENTS.md + GEMINI.md read; GEMINI.md > AGENTS.md on conflict; AGENTS.md = cross-tool canonical | `[LIVE-2nd]` |
| `.mdc` NOT used; rules are `.md` | `[LIVE-2nd]` (no source shows `.mdc`; all show `.md`) |
| No user-authored custom sub-agent file (browser subagent built-in; CLI subagents runtime) | `[LIVE-2nd]` |
| Native `.agent/skills/<folder>/SKILL.md` (name+description) primitive exists | `[LIVE-2nd]` |
| Reasoning models: Gemini 3 Pro (high/low), Gemini 3 Flash, Claude 4.5, GPT-OSS | `[LIVE-2nd]` |
| Reasoning-effort knob exists (detailed-form supported) | `[LIVE-2nd]` (high/low variants) |
| Exact API model-id + reasoning_effort tokenization (`gemini-3-pro`+`high` vs `gemini-3-pro-high`) | `[GAP]` — display names only; needs a vendor model-id reference for a precise string |
| `hooks` = true (JSON lifecycle hooks) | `[LIVE-2nd]` |
| `background_execution` = true (async subagents) | `[LIVE-2nd]` |
| `skill_chaining` = true (workflows call workflows) | `[LIVE-2nd]` for workflow chaining; `[GAP]` for strict SKILL.md-to-SKILL.md chaining |
| `stop_hook_autocontinue` | `[GAP]` — no evidence; lean **false** (matches cursor) |
| Agent shell tool-call token / `Bash → Terminal` remap | `[GAP]` — no published tool-token map; recommend empty-map (passthrough), Cursor-analogy is inference only |
| Official `antigravity.google/docs/*` page bodies | `[GAP]` — JS SPA returned title-only via WebFetch; relied on Context7 mirror + dev sources instead |
| `.agents/` (plural) vs `.agent/` (singular) | One Google codelab (#7) uses plural `.agents/`; canonical taken as **`.agent/`** (singular) per mirror + Atamel + dev.to. Flagged for task-004 awareness. |
