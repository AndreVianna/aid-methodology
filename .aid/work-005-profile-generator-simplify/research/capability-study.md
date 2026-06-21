# Per-Tool Capability Study (FR4a)

> **Work:** work-005-profile-generator-simplify · **Feature:** feature-001-behavioral-parity-format · **Task:** task-001 (RESEARCH)
> **Status:** Study + matrix (task-001) **plus** the FR4 Format Decision section appended by task-002/DESIGN (see `## FR4 Format Decision` below — the AC4b gate). Modifies no generator / profile / KB file.

## Purpose & Method

This study records, for each of the five supported host tools (Claude Code, Cursor, Codex,
GitHub Copilot CLI, Antigravity), how the tool discovers and executes AID agents/skills/rules
and how each piece of **behaviorally-significant metadata** (the `Format ⊥ behavior` axis set —
`.aid/knowledge/domain-glossary.md` "Format ⊥ behavior (behavioral metadata)") is **preserved /
translated / gapped** when content is re-encoded into uniform markdown. It is the gating
input the FR4 format decision (task-002) cites before any format branch is deleted (AC4b).

**Axis set (fixed, complete — feature-001 Data Model "Confirmed 2026-06-20"):**
`discovery` · `execution-model` · `activation` · `capability/permissions` · `dispatchability`.
`token-cost` is a per-tool prose note, not an axis.

**Verification taxonomy:**

- `empirical:codebase` — directly verified in this repo with Grep/Glob/Read (this host). Marked **`high`**.
- `docs:all-tools-research-2026-06-20` — transcribed from the already-web-verified all-tools
  rules/format research distilled in feature-001's "Early inputs" + the KB. These vendor-side
  rows are **NOT freshly re-verified live here** (this researcher has no web tool), so they are
  marked **`medium`** and carry an explicit "verify-against-live-docs" residual where load-bearing.
- `empirical:E-CODEX-1` — the Codex markdown-agent discovery probe. **NOT runnable on this host**
  (codex CLI is not installed — `command -v codex` returns nothing). Recorded `docs`-only at
  `medium` with a named residual (see the Codex section).

**Confidence honesty:** No vendor-side row is inflated to `high`. `high` is reserved for rows
this researcher confirmed against the codebase on this host. This is the spec's verify-first
posture (feature-001 "Confirmed 2026-06-20": uniform-markdown-for-Codex is expected, the TOML
branch stays gated until E-CODEX-1 reaches `high`).

---

## Findings D1 & D2 (codebase-established, seed every `dispatchability` row)

**Finding D1 — AID dispatches agents by name through the host's generic Agent tool, NOT via any
tool's native named-dispatch primitive.** Every dispatch site is the prose form
`Agent(subagent_type: aid-<name>, …, run_in_background: true)` inside a byte-identical skill body.
Verified on this host: the canonical PD-2 dispatch block at
`canonical/skills/aid-execute/references/state-execute.md` (lines 152–162, with the
`subagent_type: <type-specific executor>` parameter at line 156), mirrored at every
persona-override `subagent_type: aid-<name>` site across `aid-specify`
(`references/state-continue.md`), `aid-detail` (`references/first-run.md`), `aid-plan`
(`references/first-run-loop.md`), `aid-interview` (`references/state-cross-reference.md`,
`references/state-feature-decomposition.md`), and `aid-execute` (`references/state-review.md` +
`state-execute.md`). Grep `subagent_type:` across `canonical/skills/` returns 9 prose matches in 7
files (the dispatch key is always the agent-name string `aid-<name>`; e.g. `aid-clerk`,
`aid-reviewer`, `aid-architect`), and **zero** native-named-dispatch keywords. The host also
probes for generic `run_in_background` (PD-0) with an explicit **sequential graceful-degradation**
fallback (state-execute.md line 164 "Sequential fallback") — so even background dispatch is
optional, never load-bearing.
→ `empirical:codebase`, `high`.

**Finding D2 — `dispatchability` reduces to "can the tool resolve `aid-<name>` to the agent
definition?"** Only requires the name to be present and discoverable, in any format. Codex TOML
agents declare `name = "aid-<name>"` (`profiles/codex/.codex/agents/aid-architect.toml` line 1,
verified); markdown agents declare the same name in frontmatter
(`profiles/claude-code/.claude/agents/aid-architect.md` `name: aid-architect`, verified). The
dispatch contract is identical string-name resolution either way.
→ `empirical:codebase`, `high`.

**Generator translation reality (seeds `capability/permissions` rows):** `_remap_tools_list` /
`_remap_tools` in `.claude/skills/generate-profile/scripts/render_agents.py` already rewrite
`allowed-tools` per tool — `Bash`→`Terminal` for Cursor (`profiles/cursor.toml` `[tool_names]`
line 45), `Bash`→`shell` for Copilot (`profiles/copilot-cli.toml` `[tool_names]` line 48),
identity for Claude/Codex/Antigravity. This proves the `translate` verdict is mechanically
achievable today, not hypothetical. The four agent-format branches live in `render_agents.py`
(`toml` line 532, `copilot-agent` line 546, `antigravity-rule` line 578, and the default
`markdown` (Claude Code / Cursor) `else:` branch at line 619) — verified.

---

## 1. Claude Code

**Tool & version:** Claude Code (Anthropic). Version not pinned in-repo; the host this study ran
on is Claude Code (Opus 4.8). **Asset kinds:** agents (`.claude/agents/*.md`), skills
(`.claude/skills/<slug>/SKILL.md`), rules folded into the root context file. **Format:**
markdown + YAML frontmatter (`profiles/claude-code.toml` — default markdown branch).
**Always-on verdict:** the root context file `CLAUDE.md` loads on every request (CONFIRMED for
this host — these very instructions arrived as always-on context); no Cursor-style background
caveat applies. AID ships no conditional rules folder for Claude, so always-on guidance folds
into `CLAUDE.md` uniformly. Source: `docs:all-tools-research-2026-06-20` + on-host observation.

| Axis | Native mechanism | Native format | Uniform-markdown encoding | Preserve/Translate/Gap | Verification | Confidence |
|------|------------------|---------------|---------------------------|------------------------|--------------|------------|
| discovery | Reads `.claude/agents/*.md` + `.claude/skills/<slug>/SKILL.md` by directory convention | markdown+yaml | native — this *is* uniform markdown | preserve | `both` (`empirical:codebase` `profiles/claude-code/.claude/agents/aid-architect.md`; `docs:all-tools-research-2026-06-20`) | high |
| execution-model | `model:` frontmatter (tier alias `opus`/`sonnet`/`haiku`) | markdown+yaml | `model:` frontmatter, verbatim | preserve | `empirical:codebase` (`model: opus` in rendered agent) | high |
| activation | Always-on via `CLAUDE.md` root file; agents activated on dispatch | markdown+yaml | root context file; no `alwaysApply` needed | preserve | `docs:all-tools-research-2026-06-20` + on-host | medium |
| capability/permissions | `tools:` frontmatter (`Bash`,`Read`,…) + `permissionMode` | markdown+yaml | `tools:` list verbatim (identity `[tool_names]`) | preserve | `empirical:codebase` (`tools: …, Bash`; `_remap_tools` identity) | high |
| dispatchability | Generic `Agent(subagent_type: aid-<name>)` resolves name → `.claude/agents/<name>.md` | markdown+yaml | name in frontmatter (`name: aid-<name>`) | preserve (D1/D2) | `empirical:codebase` (D1, D2) | high |

**Alternatives compared (per the open question):** uniform markdown vs a native exception —
Claude Code reads uniform markdown natively, so there is **no axis where a native exception buys
anything**. **Recommendation:** uniform markdown; no exception.
**Token-cost note:** `CLAUDE.md` always-on cost is the standard root-context cost; AID adds no
separate rules-folder cost.

---

## 2. Cursor

**Tool & version:** Cursor (Anysphere; VS Code fork). Version not pinned in-repo. **Asset kinds:**
agents (`.cursor/agents/*.md`), skills (`.cursor/skills/…`), `.mdc` rules
(`.cursor/rules/*.mdc`, `alwaysApply: true`). **Format:** markdown + YAML frontmatter — same shape
as Claude Code (`profiles/cursor.toml` line 15 "same format as Claude Code"; renders via the
default markdown branch). **Always-on verdict:** the root context file (`AGENTS.md`) + `.mdc`
rules with `alwaysApply: true` load as always-on context for the **interactive** agent. **Caveat
(load-bearing):** the **Cursor background agent** has historically been less reliable about
loading `AGENTS.md`/always-on rules than the interactive agent — so the always-on *guarantee* for
background-agent runs is **NOT** asserted at `high`. AID uses two `alwaysApply: true` `.mdc` rules
(`aid-methodology.mdc`, `aid-review.mdc` — `profiles/cursor.toml` `[[extras.rules]]`, verified),
no glob-conditional rules. Source: `docs:all-tools-research-2026-06-20`. **Residual:
verify-against-live-docs** that the Cursor background agent loads `AGENTS.md`/`alwaysApply` rules
on every request.

| Axis | Native mechanism | Native format | Uniform-markdown encoding | Preserve/Translate/Gap | Verification | Confidence |
|------|------------------|---------------|---------------------------|------------------------|--------------|------------|
| discovery | Reads `.cursor/agents/*.md` + `.cursor/rules/*.mdc` by convention | markdown+yaml / rule-md | agents = native markdown; rules = `.mdc` (markdown dialect) | preserve | `both` (`empirical:codebase` `profiles/cursor/.cursor/agents/aid-architect.md`; `docs:all-tools-research-2026-06-20`) | high (agents) / medium (rules) |
| execution-model | `model:` frontmatter (tier alias) | markdown+yaml | `model:` frontmatter, verbatim | preserve | `empirical:codebase` (`model: opus`) | high |
| activation | `alwaysApply: true` (.mdc rules) / glob `globs:` / root `AGENTS.md` | rule-md / markdown+yaml | `alwaysApply:`/`globs:` in `.mdc`; root file for always-on | preserve | `both` (`empirical:codebase` `always_apply = true`; `docs:` for background caveat) | medium (background-agent caveat) |
| capability/permissions | `tools:` frontmatter; `Bash`→`Terminal` rename | markdown+yaml | `tools:` list, `Bash` translated to `Terminal` by generator | translate | `empirical:codebase` (`tools: …, Terminal`; `[tool_names] Bash="Terminal"`) | high |
| dispatchability | Generic Agent dispatch resolves name → `.cursor/agents/<name>.md` | markdown+yaml | name in frontmatter | preserve (D1/D2) | `empirical:codebase` (D1, D2) | high |

**Alternatives compared:** uniform markdown vs native exception — Cursor agents are already
markdown; the only metadata needing translation is `Bash`→`Terminal`, which the generator does at
render time (`translate`, not `gap`). No axis is un-translatable. **Recommendation:** uniform
markdown; the `Bash`→`Terminal` capability rename is a generator translate-step, not a format
exception. **Open caveat to carry forward:** background-agent always-on guarantee (`medium`).
**Token-cost note:** two `alwaysApply` `.mdc` rules + `AGENTS.md` are the always-on cost.

---

## 3. Codex

**Tool & version:** OpenAI Codex CLI. Version not pinned in-repo. **Codex CLI is NOT installed on
this host** (`command -v codex` returns nothing — CONFIRMED), so all Codex-runtime rows are
`docs`-only and the E-CODEX-1 probe is **not runnable here**. **Asset kinds:** agents
(`.codex/agents/*.toml` today — TOML-native), skills (`.codex/skills/…`), rules folded into
`AGENTS.md`. **Format:** today TOML (`profiles/codex.toml` `[agent] format = "toml"`; the TOML
agents carry `name`/`model`/`model_reasoning_effort`/`developer_instructions` —
`profiles/codex/.codex/agents/aid-architect.toml`, verified). The open FR4 question is whether
this must stay TOML or can become uniform markdown. **Always-on verdict:** Codex reads `AGENTS.md`
as always-on context; AID ships no conditional rules folder for Codex, so always-on guidance
folds into `AGENTS.md` uniformly. Source: `docs:all-tools-research-2026-06-20`.

> **The Codex resolution (per feature-001):** *Dispatch* is already format-agnostic — Finding D1
> shows AID never uses Codex-native subagent auto-discovery; it injects `subagent_type: aid-<name>`
> in the byte-identical skill body the orchestrator reads, and the agent's behavioral metadata
> travels in the agent file either way. codex issue #15250 ("markdown agents are not discovered as
> *native* Codex subagents") is therefore **not load-bearing for AID's dispatch**. The one genuinely
> open sub-question is **discovery, not dispatch**: does Codex *load/read* a markdown agent file's
> instructions + `model_reasoning_effort` from frontmatter at all? → **E-CODEX-1**.

| Axis | Native mechanism | Native format | Uniform-markdown encoding | Preserve/Translate/Gap | Verification | Confidence |
|------|------------------|---------------|---------------------------|------------------------|--------------|------------|
| discovery (E-CODEX-1) | Codex discovers agents under `.codex/agents/`; native-subagent registration documented for TOML; markdown-agent *reading* unverified | toml (today) | proposed: markdown agent file under the agent path, instructions in body | **gap-or-preserve — UNRESOLVED** (verify-first; TOML branch stays dormant until `high`) | `docs:all-tools-research-2026-06-20` + `empirical:E-CODEX-1` (**NOT RUN — codex CLI absent on host**) | medium |
| execution-model | TOML `model` + `model_reasoning_effort` keys | toml | proposed: markdown frontmatter `model:` + `reasoning_effort:` (generator places where Codex reads) | translate (verify Codex reads effort from markdown frontmatter) | `both` (`empirical:codebase` `model_reasoning_effort = "high"` in TOML; `docs:` for markdown-read) | medium |
| activation | `AGENTS.md` always-on root file; agents activated on dispatch | toml / markdown | root context file; no per-agent activation key | preserve | `docs:all-tools-research-2026-06-20` | medium |
| capability/permissions | Identity `[tool_names]` (`Bash` stays `Bash`) — no documented Codex rename | toml | `tools:`/prose; identity passthrough | preserve | `empirical:codebase` (`profiles/codex.toml` `[tool_names]` identity comment) | high |
| dispatchability | TOML `name = "aid-<name>"`; AID resolves via generic Agent dispatch by name string | toml | name in markdown frontmatter — same string-name resolution (D1/D2) | preserve (D1/D2) | `empirical:codebase` (D1, D2; TOML `name` field line 1) | high |

**E-CODEX-1 verdict (explicit):** **NOT RUN on this host** — the codex CLI is not installed
(CONFIRMED). The Codex markdown-agent **discovery** row is recorded `docs`-only at **`medium`**.
**Named residual:** *Codex markdown-agent discovery is unverified empirically; the TOML format
branch stays **dormant** (verify-first) and is NOT deleted until E-CODEX-1 is run and reaches
`high`. Follow-up: in a throwaway Codex project install one AID agent as a markdown file under
`.codex/agents/` + one skill that dispatches it by name, and confirm (a) the agent's instructions
reach the model and (b) `model_reasoning_effort` is honored from markdown frontmatter; then delete
the TOML branch once `high`.* This is a valid feature-001 DONE state (feature-001 "Confirmed
2026-06-20": E-CODEX-1 may stay `docs`-only/`medium`; feature-002 inherits the open row).

**Alternatives compared (the one open format question):**
- **Option A — keep TOML as the documented FR4 exception.** Justified only if E-CODEX-1 proves
  Codex *cannot* read a markdown agent's instructions/effort (discovery `gap`) AND AID relies on
  that (it does — agent instructions must reach the model). Currently **unproven** (probe not run),
  so this exception is **not** yet "provably required" per the decision procedure's condition 3
  (`high` confidence required).
- **Option B — uniform markdown for Codex agents (the expected outcome).** Dispatch is already
  format-agnostic (D1/D2, `high`); the only blocker is the discovery sub-question. If E-CODEX-1
  confirms Codex reads markdown-agent instructions + effort, Option B holds.
- **Recommendation:** **commit to Option B (uniform markdown) verify-first, keeping the TOML branch
  dormant (not deleted) until E-CODEX-1 reaches `high`.** This matches the spec's expected outcome
  and the decision procedure (no `high`-confidence gap proven → uniform-markdown default).
**Token-cost note:** `AGENTS.md` always-on cost only; no rules folder.

---

## 4. GitHub Copilot CLI

**Tool & version:** GitHub Copilot CLI. Version not pinned in-repo. **Asset kinds:** agents
(`.github/agents/*.agent.md`), skills (`.github/skills/<slug>/SKILL.md` — native primitive),
rules folded into the root context file. **Format:** markdown + YAML frontmatter with the
`.agent.md` suffix (`profiles/copilot-cli.toml` `format = "copilot-agent"` line 19; rendered
agent `profiles/copilot-cli/.github/agents/aid-architect.agent.md` carries
`name`/`description`/`tools` (YAML sequence)/`model`, verified). **Always-on verdict:** Copilot CLI
reads its root context file as always-on context; AID ships no conditional rules folder for
Copilot, so always-on guidance folds into the root file uniformly. No Cursor-style background
caveat documented. Source: `docs:all-tools-research-2026-06-20`. **Parity note:** per AC4a,
Copilot CLI behavioral parity is **asserted via the Finding-D1 content-identity argument, not
exercised** (CI cannot run 5 live runtimes).

| Axis | Native mechanism | Native format | Uniform-markdown encoding | Preserve/Translate/Gap | Verification | Confidence |
|------|------------------|---------------|---------------------------|------------------------|--------------|------------|
| discovery | Reads `.github/agents/*.agent.md` + `.github/skills/<slug>/` by convention | `.agent.md` (markdown+yaml) | uniform markdown with `.agent.md` suffix (suffix is a format-branch property) | preserve (container = markdown; suffix is a path detail) | `both` (`empirical:codebase` rendered `.agent.md`; `docs:all-tools-research-2026-06-20`) | high (codebase shape) / medium (live read) |
| execution-model | `model:` frontmatter (`claude-opus-4.8` literal) | `.agent.md` | `model:` frontmatter, verbatim | preserve | `empirical:codebase` (`model: claude-opus-4.8`) | high |
| activation | Root context file always-on; agents activated on dispatch | `.agent.md` / markdown | root context file; no per-agent activation key | preserve | `docs:all-tools-research-2026-06-20` | medium |
| capability/permissions | `tools:` YAML sequence; `Bash`→`shell` rename | `.agent.md` | `tools:` list, `Bash` translated to `shell` by generator | translate | `empirical:codebase` (`- shell` in sequence; `[tool_names] Bash="shell"`) | high |
| dispatchability | Generic Agent dispatch resolves name → `.github/agents/<name>.agent.md` | `.agent.md` | name in frontmatter | preserve (D1/D2) | `empirical:codebase` (D1, D2) | high |

**Alternatives compared:** uniform markdown vs native exception — the `copilot-agent` branch only
differs from plain markdown by (a) the `.agent.md` suffix and (b) `tools:` emitted as a YAML
sequence + `Bash`→`shell`. Both are generator render-time concerns, not behavioral gaps
(`translate`/path-detail). No axis is un-translatable. **Recommendation:** uniform markdown
container; the `.agent.md` suffix + `shell` rename + sequence-form `tools:` are generator
translate-steps, not a behavioral format exception.
**Token-cost note:** root context file always-on cost only.

---

## 5. Antigravity

**Tool & version:** Google Antigravity (Windsurf lineage; VS Code fork). **Version pinned:
v1.20.3+** is the relevant threshold for the always-on `trigger:` behavior (per feature-001
"Early inputs"). **Asset kinds:** agents reshaped into rules (`.agent/rules/*.md` with
`trigger:`-style frontmatter), skills (`.agent/skills/<slug>/SKILL.md` — native primitive),
methodology rules (`.agent/rules/*.md`). NB: `.agent/` (singular) is the current folder; the
legacy `.agent/` Antigravity folder is the older layout. **Format:** `antigravity-rule`
(`profiles/antigravity.toml` `format = "antigravity-rule"` line 19; rendered
`profiles/antigravity/.agent/rules/aid-architect.md` carries **`trigger: always_on` +
`description` only — NOT `name`/`tools`/`model`**, verified). **Always-on verdict:** AID's
Antigravity agents/rules use `trigger: always_on`, which loads them as always-on context on
**v1.20.3+** (the `[extras] rules_frontmatter = "trigger"` knob maps `always_apply=true` →
`trigger: always_on` — `profiles/antigravity.toml`, verified). Source:
`docs:all-tools-research-2026-06-20`. **Residual: verify-against-live-docs** the v1.20.3+
`trigger: always_on` semantics. **Parity note:** per AC4a, Antigravity parity is **asserted via
Finding-D1 content-identity, not exercised**.

| Axis | Native mechanism | Native format | Uniform-markdown encoding | Preserve/Translate/Gap | Verification | Confidence |
|------|------------------|---------------|---------------------------|------------------------|--------------|------------|
| discovery | Reads `.agent/rules/*.md` + `.agent/skills/<slug>/` by convention | rule-md (markdown+`trigger:` frontmatter) | uniform markdown body; frontmatter reshaped to `trigger:/description/globs` | translate (frontmatter reshaped; body verbatim) | `both` (`empirical:codebase` rendered `.agent/rules/aid-architect.md`; `docs:` for v1.20.3+ read) | high (codebase shape) / medium (live read) |
| execution-model | Display-name model tiers ("Gemini 3 Pro (high)"); `reasoning_effort` in profile tiers | rule-md | model/effort NOT carried in agent frontmatter (reshaped rule drops `model:`) | **gap (per-agent model selection) — documented** | `empirical:codebase` (`gemini-3-pro`/`reasoning_effort` in `profiles/antigravity.toml` `[model_tiers]`, but rendered rule has no `model:` key) + `docs:` (tokenization noted unconfirmed) | medium |
| activation | `trigger: always_on` / `trigger: glob` + `globs:` | rule-md | `trigger:` frontmatter (`always_apply=true`→`always_on`) | translate | `both` (`empirical:codebase` `trigger: always_on` rendered; `docs:` for v1.20.3+) | medium |
| capability/permissions | Empty `[tool_names]` (identity passthrough; no published Antigravity tool-token map); reshaped rule carries no `tools:` key | rule-md | tools NOT carried in reshaped rule frontmatter | **gap (per-agent tool restriction) — documented** | `empirical:codebase` (`profiles/antigravity.toml` `[tool_names]` empty; rendered rule has no `tools:`) | medium |
| dispatchability | Rule discoverable by stem; AID resolves via generic Agent dispatch by name string | rule-md | agent body present under its stem; name conveyed by filename/body | preserve (D1/D2 — name-based, format-agnostic) | `empirical:codebase` (D1, D2) | high |

**Alternatives compared:** uniform markdown vs native exception — Antigravity already uses a
markdown body; the `antigravity-rule` branch *reshapes the frontmatter* (`name`/`tools`/`model` →
`trigger`/`description`/`globs`). Two axes show a **documented `gap`** (per-agent `model` and
per-agent `tools` are not carried in the reshaped rule frontmatter — the rule form has no slot for
them). These are **runtime gaps in the rule primitive, not format-encoding choices** AID can fix by
switching container — so they are documented gaps, never silently dropped (NFR3), regardless of
which container is chosen. **Recommendation:** uniform markdown body with the `trigger:`-frontmatter
reshape as a generator translate-step; record the per-agent model/tools `gap` as a runtime ceiling
(Antigravity rules carry no per-agent model/tool selection), not as a reason to keep a separate
format. **Note:** whether AID *relies* on per-agent model/tools for Antigravity (decision-procedure
condition 2) is a task-002 question; this study only records the `gap`.
**Token-cost note:** `trigger: always_on` rules + `AGENTS.md` are the always-on cost.

---

## Cross-Tool Summary

| Tool | Always-on verdict | Format today | Open behavioral concern |
|------|-------------------|--------------|-------------------------|
| Claude Code | `CLAUDE.md` always-on (on-host CONFIRMED) | markdown+yaml | none — pure uniform markdown |
| Cursor | `AGENTS.md` + `alwaysApply` rules always-on for interactive agent | markdown+yaml | **background-agent** always-on guarantee (`medium`, verify live) |
| Codex | `AGENTS.md` always-on | toml (today) | **E-CODEX-1 markdown-agent discovery** unverified (probe not runnable — codex CLI absent) |
| Copilot CLI | root context file always-on | `copilot-agent` (`.agent.md`) | none behavioral — `.agent.md` suffix + `shell` rename are translate-steps |
| Antigravity | `trigger: always_on` rules on **v1.20.3+** | `antigravity-rule` (rule-md) | per-agent **model/tools** are documented runtime `gap`s in the rule primitive |

**Confidence distribution (25 axis rows = 5 tools × 5 axes):** pure-`high` = **13** (all five
`dispatchability` rows via D1/D2 + Claude discovery/model/capability, Cursor model/capability, Codex
capability, Copilot model/capability); **split** `high` (codebase shape) / `medium` (live read) = **3**
(Cursor discovery, Copilot discovery, Antigravity discovery); pure-`medium` = **9** (the remaining
vendor-side live-read rows, the Cursor background-agent activation caveat, the two Antigravity `gap`
rows, and the Codex discovery/execution/activation rows incl. E-CODEX-1). **No `low` rows.** No row is
left as an unverified draft — every `(tool, axis)` cell carries a Verification + Confidence value.

**Residuals carried forward (verify-against-live-docs / verify-first):**
1. **E-CODEX-1** — Codex markdown-agent discovery + `model_reasoning_effort`-from-frontmatter:
   probe NOT runnable on this host (codex CLI absent); TOML branch stays **dormant** until `high`.
2. **Cursor background-agent** always-on guarantee — re-verify against live Cursor docs.
3. **Antigravity v1.20.3+** `trigger: always_on` semantics + model-tier tokenization — re-verify
   against live Antigravity docs.
4. The three vendor-side always-on rows (Claude/Codex/Copilot root-file always-on) are `medium`
   pending live re-verification, but each is corroborated by on-host or rendered-artifact evidence.

**Scope boundary honored (through §Cross-Tool Summary):** the per-tool study/matrix above (§1–§5
+ this summary) is the task-001/RESEARCH output and modifies **no** generator / `profiles/*` /
`.aid/knowledge/` file — those were read-only as study evidence. The **FR4 decision section that
follows** is the task-002/DESIGN deliverable (added 2026-06-20); it adds the verdict + cite-join
but likewise touches **no** generator / `profiles/*` / `.aid/knowledge/` file and authorizes **no**
branch deletion — it is the **AC4b gate** that later tasks (feature-002 / task-003+) depend on.

---

## FR4 Format Decision (task-002 / DESIGN — the AC4b gate)

> **Work:** work-005-profile-generator-simplify · **Feature:** feature-001-behavioral-parity-format
> · **Task:** task-002 (DESIGN). **Added 2026-06-20.** This section is folded **into** this one
> study doc (the separate `format-decision.md` was dropped per the intent-review correction —
> feature-001 Data Model "The decision section"). It records the FR4 verdict per `(tool, asset-kind)`
> and **cites the study rows above** so that "the FR4 decision follows from the study" (AC4b).

### Decision procedure (recap — feature-001 Feature Flow S2)

A native format is kept as a **documented native exception** only when **ALL** of:

1. **(gap/un-translatable)** a behavioral axis is `gap` or un-`translate`-able under uniform
   markdown for that tool, **and** the generator cannot translate it into the tool's idiom at
   render time; **and**
2. **(AID relies on it)** AID actually exercises that behavior; **and**
3. **(`high` confidence)** the finding is `high` confidence (`docs` *and*, where feasible,
   `empirical`).

Fail **any** of (1) / (2) / (3) → **commit uniform markdown** (the FR4 default, verify-first).
"Provably required" = (1) ∧ (2) ∧ (3), each citing a study row. For every uniform-markdown
verdict below, the section states which condition failed; for the one retained (dormant) candidate,
it states which condition is not-yet-met. **Every verdict cites a specific study row above + Finding
D1 (lines 39–63) + the E-CODEX-1 result (§3, lines 159 + 165–173).**

> **Why D1 + E-CODEX-1 gate every verdict.** Finding **D1/D2** (`empirical:codebase`, `high`)
> establishes that `dispatchability` is name-based and **format-agnostic for all five tools** — so
> the per-tool decision reduces to "does any *non-dispatch* axis (discovery / execution-model /
> activation / capability) present a `high`-confidence, AID-relied-upon, un-translatable gap?"
> **E-CODEX-1** is the one open probe that could surface such a gap (Codex markdown-agent
> *discovery*); it is **NOT RUN on this host** (codex CLI absent — §3 line 165), recorded
> `docs`-only at `medium`. So no `high`-confidence gap is proven anywhere → uniform markdown
> everywhere, with **Codex agents' TOML branch retained DORMANT** (not deleted) as the gated
> fallback until E-CODEX-1 reaches `high`.

### Decision table — verdict per `(tool, asset-kind)` (the AC4b cite-join)

| tool | asset-kind | native-format | decision | gating-axis (the axis that could force an exception) | study-citation |
|------|------------|---------------|----------|------------------------------------------------------|----------------|
| Claude Code | agents | markdown+yaml | **uniform-markdown** | none — native format *is* uniform markdown | §1 discovery/dispatchability rows (`preserve`, `high`); D1/D2 |
| Claude Code | skills | markdown (`SKILL.md`) | **uniform-markdown** | none — `.claude/skills/<slug>/SKILL.md` is native uniform markdown | §1 discovery row (`preserve`, `high`); D1 (skill body byte-identical) |
| Cursor | agents | markdown+yaml | **uniform-markdown** | capability/permissions (`Bash`→`Terminal`) — `translate`, not `gap` | §2 capability row (`translate`, `high`); dispatchability (`preserve`, D1/D2) |
| Cursor | skills | markdown (`SKILL.md`) | **uniform-markdown** | none — skill folder is native markdown; `.mdc` rules dropped per FR3 | §2 discovery row (`preserve`/`high` agents); D1 |
| Codex | agents | toml (today) | **uniform-markdown (EXPECTED); TOML branch DORMANT (gated fallback)** | discovery (E-CODEX-1) — `gap-or-preserve` **UNRESOLVED**, `medium` (probe NOT RUN) | §3 discovery row E-CODEX-1 (`medium`, NOT RUN, lines 159/165); D1/D2 (dispatch format-agnostic, `high`) |
| Codex | skills | markdown (`SKILL.md`) | **uniform-markdown** | none — skills are not the divergent surface; only Codex *agents* were ever TOML | §3 dispatchability/capability rows (`preserve`, `high`); D1 |
| GitHub Copilot CLI | agents | `copilot-agent` (`.agent.md`) | **uniform-markdown** | capability (`Bash`→`shell`) + `.agent.md` suffix + sequence-form `tools:` — all `translate`/path-detail | §4 capability row (`translate`, `high`); discovery row (`preserve`); D1/D2 |
| GitHub Copilot CLI | skills | markdown (`SKILL.md`) | **uniform-markdown** | none — `.github/skills/<slug>/SKILL.md` is native uniform markdown | §4 discovery row (`preserve`); D1 |
| Antigravity | agents | `antigravity-rule` (rule-md) | **uniform-markdown** | execution-model + capability — documented runtime `gap`s in the rule primitive, **not** format-encoding choices | §5 execution-model + capability rows (`gap`, `medium`); dispatchability (`preserve`, D1/D2) |
| Antigravity | skills | markdown (`SKILL.md`) | **uniform-markdown** | none — `.agent/skills/<slug>/SKILL.md` is native uniform markdown | §5 discovery row (`preserve`); D1 |

**Summary: 10 of 10 `(tool, asset-kind)` verdicts = uniform markdown. The only non-uniform-markdown
candidate is Codex *agents*, where the TOML branch is retained DORMANT (not deleted) as the
E-CODEX-1-gated fallback — the verdict is still uniform-markdown-EXPECTED.**

### Per-verdict justification (3-part procedure applied)

#### Claude Code — agents → uniform markdown · skills → uniform markdown

**Condition (1) FAILS (no gap at all).** Claude Code's native format **is** markdown+YAML for both
agents (`.claude/agents/*.md`) and skills (`.claude/skills/<slug>/SKILL.md`) — uniform markdown is
the native format, so no axis has a `gap` and nothing needs translating (§1 discovery/execution/
activation/capability rows all `preserve`, mostly `high`). Dispatchability is `preserve` via **D1/D2**
(name resolves to `.claude/agents/<name>.md`). With (1) failed, the exception test stops → **uniform
markdown, no exception.** **E-CODEX-1:** not implicated (Codex-specific); cited as the cross-tool gate
that confirms no other tool surfaces a gap either.

#### Cursor — agents → uniform markdown · skills → uniform markdown

**Condition (1) FAILS (translatable, not gap).** Cursor agents are already markdown+YAML (same shape
as Claude — §2 discovery row, `high` for agents). The only metadata needing change is the
capability axis `Bash`→`Terminal`, which the generator performs at render time via
`_remap_tools_list` / `[tool_names] Bash="Terminal"` (§2 capability row = **`translate`, `high`**) —
so it is translatable, not a `gap`. Dispatchability `preserve` via **D1/D2**. The `.mdc` always-on
rules are dropped under FR3 (always-on folds into `AGENTS.md`), not a per-agent format concern.
(1) failed → **uniform markdown; the `Bash`→`Terminal` rename is a generator translate-step, not a
format exception.** **Open caveat carried forward (does not change the verdict):** the Cursor
**background-agent** always-on guarantee is `medium` (§2 activation row) — a verify-against-live-docs
residual on activation, not an un-translatable per-agent-format gap. **E-CODEX-1:** not implicated;
cited as the cross-tool gate.

#### Codex — agents → uniform markdown (EXPECTED), TOML branch DORMANT · skills → uniform markdown

This is the **one open question** (feature-001 "The Codex Resolution"). The candidate exception is
**keep Codex-agent TOML**. Apply the procedure to that candidate:

- **Condition (2) HOLDS (AID relies on it).** AID relies on the agent's instructions +
  `model_reasoning_effort` (execution axis) reaching the model — so the *discovery* sub-question is a
  behavior AID exercises. (Dispatch itself does **not** need TOML — **D1/D2** show dispatch is
  name-based and format-agnostic, `high`; codex #15250 "markdown agents not discovered as *native*
  subagents" is therefore **not load-bearing for AID's dispatch** — §3 lines 149–155.)
- **Condition (1) is UNRESOLVED.** Whether Codex *reads* a markdown agent's instructions + effort
  from frontmatter (discovery `gap` vs `preserve`) is the **E-CODEX-1** probe, recorded
  `gap-or-preserve — UNRESOLVED` (§3 discovery row, line 159). Not proven to be a gap.
- **Condition (3) FAILS (`high` not met).** **E-CODEX-1 was NOT RUN on this host** — the codex CLI is
  not installed (`command -v codex` returns nothing, CONFIRMED — §3 line 165). The Codex
  markdown-agent discovery row is `docs`-only at **`medium`** (§3 lines 159, 166–173). Condition (3)
  requires `high` confidence.

**Verdict.** Condition (3) fails (and (1) is unresolved) → the TOML exception is **not yet "provably
required"** → the **FR4 default holds: uniform markdown for Codex agents — the EXPECTED outcome**
(feature-001 "Confirmed 2026-06-20": uniform-markdown-for-Codex is expected; Option B). **But
verify-first means the TOML branch is NOT deleted:** it is retained **DORMANT** as the gated fallback
until E-CODEX-1 is run and reaches `high`. The dormant-TOML state is an explicit, valid feature-001
DONE state (§3 E-CODEX-1 verdict + named residual, lines 165–173) — feature-002 inherits the open row
and only deletes the TOML branch (`render_agents.py` line 532) once E-CODEX-1 is `high`. **Codex
*skills*** were never the divergent surface (only Codex *agents* were TOML); skills are
`.codex/skills/<slug>/SKILL.md` markdown — condition (1) fails outright → **uniform markdown.**

#### GitHub Copilot CLI — agents → uniform markdown · skills → uniform markdown

**Condition (1) FAILS (translatable / path-detail, not gap).** The `copilot-agent` branch differs
from plain markdown only by (a) the `.agent.md` filename suffix (a path detail) and (b) `tools:`
emitted as a YAML sequence with `Bash`→`shell` — a generator translate-step (§4 capability row =
**`translate`, `high`**; `[tool_names] Bash="shell"`). The markdown container itself is preserved
(§4 discovery row, `preserve`). Dispatchability `preserve` via **D1/D2**. No axis is un-translatable
→ **uniform markdown; the `.agent.md` suffix + `shell` rename + sequence-form `tools:` are generator
translate-steps, not a behavioral format exception.** Skills are `.github/skills/<slug>/SKILL.md`
native markdown → (1) fails outright → **uniform markdown.** (Per AC4a, Copilot parity is asserted
via the **Finding-D1** content-identity argument, not exercised — §4 parity note.) **E-CODEX-1:**
not implicated; cited as the cross-tool gate.

#### Antigravity — agents → uniform markdown · skills → uniform markdown

The subtle case: two axes carry a **documented `gap`** (§5). Apply the procedure to the candidate
"keep `antigravity-rule` as an exception":

- **Condition (1) — partially: there ARE documented gaps, but they are runtime ceilings, not
  format-encoding choices AID can fix by container.** The `antigravity-rule` form reshapes the
  frontmatter (`name`/`tools`/`model` → `trigger`/`description`/`globs`); per-agent **model**
  (execution-model row) and per-agent **tools** (capability row) are **not carried** in the reshaped
  rule frontmatter — both recorded **`gap`** at `medium` (§5 execution-model + capability rows). But
  these are **gaps in the Antigravity *rule primitive's runtime* (the rule form has no slot for
  per-agent model/tools), present regardless of which container AID emits** — *not* something a
  different source format would preserve. Switching to (or away from) a "native" format buys nothing
  here, so condition (1) "un-translatable *under uniform markdown*" is **not the binding axis**: the
  ceiling is the tool runtime, not the encoding.
- **Condition (2) — AID does NOT rely on per-agent model/tools for Antigravity.** AID's Antigravity
  agents render as `trigger: always_on` rules carrying `description` only — AID does not exercise
  per-agent model selection or per-agent tool restriction on Antigravity (the rule primitive has no
  such slot, and AID ships none). The behavior AID relies on — the agent body reaching the model —
  is `preserve`d (markdown body verbatim, §5 discovery row); dispatchability is `preserve` via
  **D1/D2** (name-based, format-agnostic).
- **Condition (3)** is moot once (2) fails.

**Verdict.** Condition (2) fails (AID does not rely on the gapped per-agent model/tools behavior) →
the `antigravity-rule` form is **not "provably required"** → **uniform markdown body, with the
`trigger:`-frontmatter reshape as a generator translate-step (§5 activation row, `translate`).** The
per-agent model/tools `gap` is recorded as a **runtime ceiling** of the Antigravity rule primitive
(documented, never silently dropped — NFR3), **not** as a reason to retain a separate format. Skills
are `.agent/skills/<slug>/SKILL.md` native markdown → (1) fails outright → **uniform markdown.** (Per
AC4a, Antigravity parity is asserted via **Finding-D1**, not exercised — §5 parity note.)
**E-CODEX-1:** not implicated; cited as the cross-tool gate.

### AC4b discharge + scope

- **AC4b is DISCHARGED.** The FR4a capability study **exists and is documented** (§1–§5 + Cross-Tool
  Summary), and **this FR4 decision section cites it** — every `(tool, asset-kind)` verdict cites a
  specific study row + **Finding D1/D2** + the **E-CODEX-1 result**. This section is produced
  **before any format branch is deleted**: it is the **gate** that authorizes feature-002 /
  task-003+ to act on FR4. No branch is deleted here.
- **The 3-part "provably required" procedure is recorded per verdict** (above): every
  uniform-markdown verdict names the failing condition — (1) for Claude/Cursor/Copilot agents +
  Codex/Cursor/Copilot/Antigravity skills (no gap / translatable / native markdown), (2) for
  Antigravity agents (AID does not rely on the gapped behavior); the Codex-agents candidate names
  (3) failing (`high` not met, E-CODEX-1 NOT RUN) with (1) unresolved → dormant-TOML fallback.
- **The Codex verdict reflects the actual E-CODEX-1 outcome** (`docs`-only / `medium`, NOT RUN):
  **markdown-EXPECTED, TOML-branch-DORMANT** (gated, not deleted) until E-CODEX-1 reaches `high`.
- **DESIGN defaults (feature-001 §UI Specs N/A):** design tokens = the fixed Capability-Matrix /
  verdict-table **schema** reused here (`tool | asset-kind | native-format | decision | gating-axis
  | study-citation`), **not** a UI token set — this is a research/decision feature with **no rendered
  UI**. Responsive behavior: **N/A** (no rendered UI), recorded with rationale.
- **Scope:** this section adds the decision only. It modifies **no** matrix row task-001 wrote, **no**
  generator / `profiles/*` / `.aid/knowledge/` file, and begins **no** branch deletion (feature-002 /
  later tasks). It is the GATE that authorizes them.

---

## Scope boundary (whole document)

This document is the per-tool study/matrix (§1–§5, Cross-Tool Summary — task-001/RESEARCH) **plus**
the FR4 Format Decision section (task-002/DESIGN). It modifies **no** generator / `profiles/*` /
`.aid/knowledge/` file — those were read-only as study evidence — and authorizes (but does not
perform) any branch deletion.
