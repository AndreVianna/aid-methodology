---
kb-category: primary
source: promoted from work-local research (work-005-profile-generator-simplify/research/capability-study.md)
intent: |
  Per-tool capability reference for every AID-supported host tool. Records how each
  tool discovers and executes AID agents/skills, how behaviorally-significant metadata
  is preserved, translated, or gapped under uniform markdown encoding, and the always-on
  context verdict. Used as the gating reference for format decisions (FR4), 6th-tool
  onboarding, and any future encoding change. Read this before authoring or deleting a
  format branch, adding a new host tool, or asserting behavioral parity across tools.
contracts:
  - "dispatchability is name-based and format-agnostic across all supported tools (Finding D1/D2)"
  - "uniform markdown is the default encoding; a native exception is kept only when (1) a behavioral axis is gap/un-translatable under markdown AND (2) AID relies on it AND (3) the finding is high-confidence"
  - "every (tool, axis) cell carries a Verification source and a Confidence level; no cell is undocumented"
  - "the Codex TOML branch is retained DORMANT (not deleted) until E-CODEX-1 reaches high confidence"
changelog:
  - 2026-06-21: Created — promoted from work-005-profile-generator-simplify delivery-003 task-018; content copied verbatim from the verified work-local study (capability-study.md, feature-001 task-001/task-002); Codex layout updated to unified .codex/ per delivery-001/002 (FR2).
---

# Host-Tool Capability Reference

> Reference document — read before any format-branch change, new-tool onboarding,
> or behavioral-parity assertion. Content was verified in the work-local capability
> study (feature-001-behavioral-parity-format, tasks task-001/task-002); this is the
> durable KB copy. Do not re-derive findings — update individual cells when a tool's
> behavior changes and record the verification source and date.

## Scope and Axis Set

This document covers the five AID-supported host tools:
**Claude Code · Cursor · Codex · GitHub Copilot CLI · Antigravity**.

The fixed, complete axis set (feature-001 Data Model, confirmed 2026-06-20):

- **discovery** — how the tool locates agent/skill files
- **execution-model** — how model tier / reasoning effort is conveyed
- **activation** — always-on vs. conditional loading
- **capability/permissions** — tool-restriction / permission-mode encoding
- **dispatchability** — how AID's generic Agent dispatch resolves to an agent definition

`token-cost` is a per-tool prose note, not a matrix axis.

## Verification Taxonomy

| Tag | Source | Confidence |
|-----|--------|------------|
| `empirical:codebase` | Directly verified in this repo via Grep/Glob/Read | **high** |
| `docs:all-tools-research-2026-06-20` | Transcribed from the all-tools rules/format research distilled in feature-001 Early Inputs + KB | **medium** (vendor-side; verify against live docs where load-bearing) |
| `empirical:E-CODEX-1` | The Codex markdown-agent discovery probe — NOT runnable at study time (codex CLI absent on host) | **medium** (docs-only; see E-CODEX-1 named residual) |

`high` is reserved for rows verified directly against the codebase on the study host. No vendor-side row is inflated to `high`.

## Cross-Cutting Findings (seed every dispatchability row)

**Finding D1 — AID dispatches agents by name through the host's generic Agent tool.**
Every dispatch site is the prose form `Agent(subagent_type: aid-<name>, …, run_in_background: true)` inside a byte-identical skill body. Verified: the canonical PD-2 dispatch block at `canonical/skills/aid-execute/references/state-execute.md` (lines 152–162), mirrored across `aid-specify`, `aid-detail`, `aid-plan`, `aid-interview`, `aid-execute`. Grep `subagent_type:` across `canonical/skills/` returns 9 prose matches in 7 files — zero native-named-dispatch keywords. A sequential graceful-degradation fallback exists for background dispatch. → `empirical:codebase`, **high**.

**Finding D2 — `dispatchability` reduces to "can the tool resolve `aid-<name>` to the agent definition?"**
TOML agents declare `name = "aid-<name>"`; markdown agents declare the same name in frontmatter. The dispatch contract is identical string-name resolution in either format. → `empirical:codebase`, **high**.

**Consequence:** `dispatchability` is `preserve` for all five tools regardless of format. The per-tool format decision reduces to "does any _non-dispatch_ axis present a `high`-confidence, AID-relied-upon, un-translatable gap?"

---

## Per-Tool Sections

### How to read a matrix

Each tool's matrix has five rows — one per axis. The columns are:

| Column | Meaning |
|--------|---------|
| **Axis** | One of the five fixed axes |
| **Native mechanism** | How the tool implements this axis natively |
| **Native format** | The file format used today |
| **Uniform-markdown encoding** | How the axis is expressed when the tool uses uniform markdown |
| **Preserve / Translate / Gap** | Encoding fidelity verdict |
| **Verification** | Source tag(s) |
| **Confidence** | `high` / `medium` per the taxonomy above |

### Adding a 6th (or later) tool

Add a new `### N. <Tool Name>` section following the pattern below:

1. Write a prose header block covering: tool version, asset kinds (agents/skills/rules), install root, format today, and always-on verdict.
2. Add a five-row matrix with exactly the columns listed above.
3. Write an "Alternatives compared" note with the uniform-markdown recommendation.
4. Write a "Token-cost note".
5. Update the Cross-Tool Summary table with a new row.
6. Record the addition in this document's `changelog` frontmatter.

No structural change to existing sections is needed when a new tool is added.

---

### 1. Claude Code

**Tool:** Claude Code (Anthropic). **Asset kinds:** agents (`.claude/agents/*.md`), skills (`.claude/skills/<slug>/SKILL.md`), rules folded into the root context file. **Format:** markdown + YAML frontmatter (default markdown branch). **Always-on verdict:** the root context file `CLAUDE.md` loads on every request (CONFIRMED on the study host — these instructions arrived as always-on context). No Cursor-style background caveat applies. AID ships no conditional rules folder for Claude; always-on guidance folds into `CLAUDE.md` uniformly. Source: `docs:all-tools-research-2026-06-20` + on-host observation.

| Axis | Native mechanism | Native format | Uniform-markdown encoding | Preserve/Translate/Gap | Verification | Confidence |
|------|------------------|---------------|---------------------------|------------------------|--------------|------------|
| discovery | Reads `.claude/agents/*.md` + `.claude/skills/<slug>/SKILL.md` by directory convention | markdown+yaml | native — this *is* uniform markdown | preserve | `both` (`empirical:codebase` `profiles/claude-code/.claude/agents/aid-architect.md`; `docs:all-tools-research-2026-06-20`) | high |
| execution-model | `model:` frontmatter (tier alias `opus`/`sonnet`/`haiku`) | markdown+yaml | `model:` frontmatter, verbatim | preserve | `empirical:codebase` (`model: opus` in rendered agent) | high |
| activation | Always-on via `CLAUDE.md` root file; agents activated on dispatch | markdown+yaml | root context file; no `alwaysApply` needed | preserve | `docs:all-tools-research-2026-06-20` + on-host | medium |
| capability/permissions | `tools:` frontmatter (`Bash`, `Read`, …) + `permissionMode` | markdown+yaml | `tools:` list verbatim (identity `[tool_names]`) | preserve | `empirical:codebase` (`tools: …, Bash`; `_remap_tools` identity) | high |
| dispatchability | Generic `Agent(subagent_type: aid-<name>)` resolves name → `.claude/agents/<name>.md` | markdown+yaml | name in frontmatter (`name: aid-<name>`) | preserve (D1/D2) | `empirical:codebase` (D1, D2) | high |

**Alternatives compared:** Claude Code reads uniform markdown natively — no axis where a native exception buys anything. **Recommendation:** uniform markdown; no exception.
**Token-cost note:** `CLAUDE.md` always-on cost is the standard root-context cost; AID adds no separate rules-folder cost.

---

### 2. Cursor

**Tool:** Cursor (Anysphere; VS Code fork). **Asset kinds:** agents (`.cursor/agents/*.md`), skills (`.cursor/skills/…`), `.mdc` rules (`.cursor/rules/*.mdc`, `alwaysApply: true`). **Format:** markdown + YAML frontmatter — same shape as Claude Code (`profiles/cursor.toml` line 15 "same format as Claude Code"; default markdown branch). **Always-on verdict:** the root context file (`AGENTS.md`) + `.mdc` rules with `alwaysApply: true` load as always-on context for the **interactive** agent. **Caveat (load-bearing):** the **Cursor background agent** has historically been less reliable about loading `AGENTS.md`/always-on rules than the interactive agent — the always-on _guarantee_ for background-agent runs is NOT asserted at `high`. AID uses two `alwaysApply: true` `.mdc` rules (`aid-methodology.mdc`, `aid-review.mdc` — `profiles/cursor.toml` `[[extras.rules]]`, verified), no glob-conditional rules. Source: `docs:all-tools-research-2026-06-20`. **Residual:** verify-against-live-docs that the Cursor background agent loads `AGENTS.md`/`alwaysApply` rules on every request.

| Axis | Native mechanism | Native format | Uniform-markdown encoding | Preserve/Translate/Gap | Verification | Confidence |
|------|------------------|---------------|---------------------------|------------------------|--------------|------------|
| discovery | Reads `.cursor/agents/*.md` + `.cursor/rules/*.mdc` by convention | markdown+yaml / rule-md | agents = native markdown; rules = `.mdc` (markdown dialect) | preserve | `both` (`empirical:codebase` `profiles/cursor/.cursor/agents/aid-architect.md`; `docs:all-tools-research-2026-06-20`) | high (agents) / medium (rules) |
| execution-model | `model:` frontmatter (tier alias) | markdown+yaml | `model:` frontmatter, verbatim | preserve | `empirical:codebase` (`model: opus`) | high |
| activation | `alwaysApply: true` (.mdc rules) / glob `globs:` / root `AGENTS.md` | rule-md / markdown+yaml | `alwaysApply:`/`globs:` in `.mdc`; root file for always-on | preserve | `both` (`empirical:codebase` `always_apply = true`; `docs:` for background caveat) | medium (background-agent caveat) |
| capability/permissions | `tools:` frontmatter; `Bash`→`Terminal` rename | markdown+yaml | `tools:` list, `Bash` translated to `Terminal` by generator | translate | `empirical:codebase` (`tools: …, Terminal`; `[tool_names] Bash="Terminal"`) | high |
| dispatchability | Generic Agent dispatch resolves name → `.cursor/agents/<name>.md` | markdown+yaml | name in frontmatter | preserve (D1/D2) | `empirical:codebase` (D1, D2) | high |

**Alternatives compared:** Cursor agents are already markdown; the only metadata needing translation is `Bash`→`Terminal`, which the generator does at render time (`translate`, not `gap`). No axis is un-translatable. **Recommendation:** uniform markdown; the `Bash`→`Terminal` capability rename is a generator translate-step, not a format exception. **Open caveat to carry forward:** background-agent always-on guarantee (`medium`).
**Token-cost note:** two `alwaysApply` `.mdc` rules + `AGENTS.md` are the always-on cost.

---

### 3. Codex

**Tool:** OpenAI Codex CLI. **Codex CLI was NOT installed on the study host** (`command -v codex` returned nothing — CONFIRMED), so all Codex-runtime rows are `docs`-only and the E-CODEX-1 probe was not run. **Asset kinds:** agents (`.codex/agents/*.toml` — TOML-native today), skills (`.codex/skills/…`), rules folded into `AGENTS.md`. **Install root:** `.codex/` (unified per work-005 FR2; the former `.agents/` split is retired — see `content-isolation.md` R6). **Format:** today TOML (`profiles/codex.toml` `[agent] format = "toml"`; agents carry `name`/`model`/`model_reasoning_effort`/`developer_instructions`). The FR4 question is whether agents must stay TOML or can become uniform markdown. **Always-on verdict:** Codex reads `AGENTS.md` as always-on context; AID ships no conditional rules folder for Codex. Source: `docs:all-tools-research-2026-06-20`.

> **The Codex resolution:** Dispatch is already format-agnostic — Finding D1 shows AID never uses Codex-native subagent auto-discovery; it injects `subagent_type: aid-<name>` in the byte-identical skill body. The open sub-question is **discovery, not dispatch**: does Codex _load/read_ a markdown agent file's instructions + `model_reasoning_effort` from frontmatter? → **E-CODEX-1** (not run; codex CLI absent on study host).

| Axis | Native mechanism | Native format | Uniform-markdown encoding | Preserve/Translate/Gap | Verification | Confidence |
|------|------------------|---------------|---------------------------|------------------------|--------------|------------|
| discovery (E-CODEX-1) | Codex discovers agents under `.codex/agents/`; native-subagent registration documented for TOML; markdown-agent *reading* unverified | toml (today) | proposed: markdown agent file under `.codex/agents/`, instructions in body | **gap-or-preserve — UNRESOLVED** (verify-first; TOML branch stays dormant until `high`) | `docs:all-tools-research-2026-06-20` + `empirical:E-CODEX-1` (NOT RUN — codex CLI absent on study host) | medium |
| execution-model | TOML `model` + `model_reasoning_effort` keys | toml | proposed: markdown frontmatter `model:` + `reasoning_effort:` | translate (verify Codex reads effort from markdown frontmatter) | `both` (`empirical:codebase` `model_reasoning_effort = "high"` in TOML; `docs:` for markdown-read) | medium |
| activation | `AGENTS.md` always-on root file; agents activated on dispatch | toml / markdown | root context file; no per-agent activation key | preserve | `docs:all-tools-research-2026-06-20` | medium |
| capability/permissions | Identity `[tool_names]` (`Bash` stays `Bash`) — no documented Codex rename | toml | `tools:`/prose; identity passthrough | preserve | `empirical:codebase` (`profiles/codex.toml` `[tool_names]` identity comment) | high |
| dispatchability | TOML `name = "aid-<name>"`; AID resolves via generic Agent dispatch by name string | toml | name in markdown frontmatter — same string-name resolution (D1/D2) | preserve (D1/D2) | `empirical:codebase` (D1, D2; TOML `name` field line 1) | high |

**E-CODEX-1 verdict:** NOT RUN on the study host (codex CLI absent). The Codex markdown-agent discovery row is `docs`-only at **`medium`**. **Named residual:** Codex markdown-agent discovery is unverified empirically; the TOML format branch stays **dormant** (verify-first) and is NOT deleted until E-CODEX-1 is run and reaches `high`. Follow-up: in a throwaway Codex project, install one AID agent as a markdown file under `.codex/agents/` + one skill that dispatches it by name, and confirm (a) the agent's instructions reach the model and (b) `model_reasoning_effort` is honored from markdown frontmatter; then delete the TOML branch once `high`.

**Alternatives compared:** Option A (keep TOML): justified only if E-CODEX-1 proves Codex cannot read a markdown agent's instructions/effort AND AID relies on it — currently unproven. Option B (uniform markdown, the expected outcome): dispatch is already format-agnostic (D1/D2, `high`); the only blocker is the discovery sub-question. **Recommendation:** commit to Option B (uniform markdown) verify-first, keeping the TOML branch dormant (not deleted) until E-CODEX-1 reaches `high`.
**Token-cost note:** `AGENTS.md` always-on cost only; no rules folder.

---

### 4. GitHub Copilot CLI

**Tool:** GitHub Copilot CLI. **Asset kinds:** agents (`.github/agents/*.agent.md`), skills (`.github/skills/<slug>/SKILL.md` — native primitive), rules folded into the root context file. **Format:** markdown + YAML frontmatter with the `.agent.md` suffix (`profiles/copilot-cli.toml` `format = "copilot-agent"` line 19; rendered agent `profiles/copilot-cli/.github/agents/aid-architect.agent.md` carries `name`/`description`/`tools` (YAML sequence)/`model`, verified). **Always-on verdict:** Copilot CLI reads its root context file as always-on context; AID ships no conditional rules folder for Copilot. No Cursor-style background caveat documented. Source: `docs:all-tools-research-2026-06-20`. **Parity note:** per AC4a, Copilot CLI behavioral parity is asserted via the Finding-D1 content-identity argument, not exercised (CI cannot run five live runtimes).

| Axis | Native mechanism | Native format | Uniform-markdown encoding | Preserve/Translate/Gap | Verification | Confidence |
|------|------------------|---------------|---------------------------|------------------------|--------------|------------|
| discovery | Reads `.github/agents/*.agent.md` + `.github/skills/<slug>/` by convention | `.agent.md` (markdown+yaml) | uniform markdown with `.agent.md` suffix (suffix is a format-branch property) | preserve (container = markdown; suffix is a path detail) | `both` (`empirical:codebase` rendered `.agent.md`; `docs:all-tools-research-2026-06-20`) | high (codebase shape) / medium (live read) |
| execution-model | `model:` frontmatter (`claude-opus-4.8` literal) | `.agent.md` | `model:` frontmatter, verbatim | preserve | `empirical:codebase` (`model: claude-opus-4.8`) | high |
| activation | Root context file always-on; agents activated on dispatch | `.agent.md` / markdown | root context file; no per-agent activation key | preserve | `docs:all-tools-research-2026-06-20` | medium |
| capability/permissions | `tools:` YAML sequence; `Bash`→`shell` rename | `.agent.md` | `tools:` list, `Bash` translated to `shell` by generator | translate | `empirical:codebase` (`- shell` in sequence; `[tool_names] Bash="shell"`) | high |
| dispatchability | Generic Agent dispatch resolves name → `.github/agents/<name>.agent.md` | `.agent.md` | name in frontmatter | preserve (D1/D2) | `empirical:codebase` (D1, D2) | high |

**Alternatives compared:** the `copilot-agent` branch differs from plain markdown only by (a) the `.agent.md` suffix and (b) `tools:` as a YAML sequence with `Bash`→`shell` — both are generator render-time concerns, not behavioral gaps. No axis is un-translatable. **Recommendation:** uniform markdown container; the `.agent.md` suffix + `shell` rename + sequence-form `tools:` are generator translate-steps, not a behavioral format exception.
**Token-cost note:** root context file always-on cost only.

---

### 5. Antigravity

**Tool:** Google Antigravity (Windsurf lineage; VS Code fork). **Version threshold:** v1.20.3+ is the relevant threshold for the always-on `trigger:` behavior. **Asset kinds:** agents reshaped into rules (`.agent/rules/*.md` with `trigger:`-style frontmatter), skills (`.agent/skills/<slug>/SKILL.md` — native primitive), methodology rules (`.agent/rules/*.md`). **Format:** `antigravity-rule` (`profiles/antigravity.toml` `format = "antigravity-rule"` line 19; rendered `profiles/antigravity/.agent/rules/aid-architect.md` carries `trigger: always_on` + `description` only — NOT `name`/`tools`/`model`, verified). **Always-on verdict:** AID's Antigravity agents/rules use `trigger: always_on`, which loads them on **v1.20.3+** (the `[extras] rules_frontmatter = "trigger"` knob maps `always_apply=true` → `trigger: always_on` — `profiles/antigravity.toml`, verified). **Residual:** verify-against-live-docs the v1.20.3+ `trigger: always_on` semantics. **Parity note:** per AC4a, Antigravity parity is asserted via Finding-D1, not exercised.

| Axis | Native mechanism | Native format | Uniform-markdown encoding | Preserve/Translate/Gap | Verification | Confidence |
|------|------------------|---------------|---------------------------|------------------------|--------------|------------|
| discovery | Reads `.agent/rules/*.md` + `.agent/skills/<slug>/` by convention | rule-md (markdown+`trigger:` frontmatter) | uniform markdown body; frontmatter reshaped to `trigger:`/`description`/`globs` | translate (frontmatter reshaped; body verbatim) | `both` (`empirical:codebase` rendered `.agent/rules/aid-architect.md`; `docs:` for v1.20.3+ read) | high (codebase shape) / medium (live read) |
| execution-model | Display-name model tiers ("Gemini 3 Pro (high)"); `reasoning_effort` in profile tiers | rule-md | model/effort NOT carried in agent frontmatter (reshaped rule drops `model:`) | **gap (per-agent model selection) — documented** | `empirical:codebase` (`gemini-3-pro`/`reasoning_effort` in `profiles/antigravity.toml` `[model_tiers]`, rendered rule has no `model:` key) + `docs:` | medium |
| activation | `trigger: always_on` / `trigger: glob` + `globs:` | rule-md | `trigger:` frontmatter (`always_apply=true`→`always_on`) | translate | `both` (`empirical:codebase` `trigger: always_on` rendered; `docs:` for v1.20.3+) | medium |
| capability/permissions | Empty `[tool_names]` (identity passthrough; no published Antigravity tool-token map); reshaped rule carries no `tools:` key | rule-md | tools NOT carried in reshaped rule frontmatter | **gap (per-agent tool restriction) — documented** | `empirical:codebase` (`profiles/antigravity.toml` `[tool_names]` empty; rendered rule has no `tools:`) | medium |
| dispatchability | Rule discoverable by stem; AID resolves via generic Agent dispatch by name string | rule-md | agent body present under its stem; name conveyed by filename/body | preserve (D1/D2 — name-based, format-agnostic) | `empirical:codebase` (D1, D2) | high |

**Alternatives compared:** the `antigravity-rule` branch reshapes the frontmatter (`name`/`tools`/`model` → `trigger`/`description`/`globs`). Two axes show documented gaps: per-agent **model** and per-agent **tools** are not carried in the reshaped rule frontmatter. These are **runtime gaps in the rule primitive** — the rule form has no slot for them, present regardless of container — not format-encoding choices AID can fix by switching container. AID does not exercise per-agent model selection or per-agent tool restriction on Antigravity (the rule primitive has no such slot and AID ships none). Condition (2) of the decision procedure fails → **uniform markdown body, with the `trigger:`-frontmatter reshape as a generator translate-step**. The per-agent model/tools gap is recorded as a runtime ceiling, not a reason to retain a separate format.
**Token-cost note:** `trigger: always_on` rules + `AGENTS.md` are the always-on cost.

---

## Cross-Tool Summary

| Tool | Install root | Always-on verdict | Format today | Open behavioral concern |
|------|-------------|-------------------|--------------|-------------------------|
| Claude Code | `.claude/` | `CLAUDE.md` always-on (on-host CONFIRMED) | markdown+yaml | none — pure uniform markdown |
| Cursor | `.cursor/` | `AGENTS.md` + `alwaysApply` rules always-on for interactive agent | markdown+yaml | **background-agent** always-on guarantee (`medium`, verify live) |
| Codex | `.codex/` | `AGENTS.md` always-on | toml (today) | **E-CODEX-1 markdown-agent discovery** unverified (probe not runnable — codex CLI absent on study host) |
| GitHub Copilot CLI | `.github/` | root context file always-on | `copilot-agent` (`.agent.md`) | none behavioral — `.agent.md` suffix + `shell` rename are translate-steps |
| Antigravity | `.agent/` | `trigger: always_on` rules on **v1.20.3+** | `antigravity-rule` (rule-md) | per-agent **model/tools** are documented runtime gaps in the rule primitive |

**Confidence distribution (25 axis rows = 5 tools x 5 axes):** pure-`high` = 13 (all five `dispatchability` rows via D1/D2 + Claude discovery/model/capability, Cursor model/capability, Codex capability, Copilot model/capability); split `high`/`medium` = 3 (Cursor discovery, Copilot discovery, Antigravity discovery); pure-`medium` = 9 (remaining vendor-side live-read rows, Cursor background-agent activation caveat, two Antigravity gap rows, Codex discovery/execution/activation including E-CODEX-1). No `low` rows.

**Residuals carried forward (verify-against-live-docs / verify-first):**
1. **E-CODEX-1** — Codex markdown-agent discovery + `model_reasoning_effort`-from-frontmatter: probe NOT runnable on study host (codex CLI absent); TOML branch stays dormant until `high`.
2. **Cursor background-agent** always-on guarantee — re-verify against live Cursor docs.
3. **Antigravity v1.20.3+** `trigger: always_on` semantics + model-tier tokenization — re-verify against live Antigravity docs.
4. The three vendor-side always-on rows (Claude/Codex/Copilot root-file always-on) are `medium` pending live re-verification, each corroborated by on-host or rendered-artifact evidence.

---

## FR4 Format Decision (the AC4b gate)

> Added 2026-06-20 (task-002/DESIGN). Records the FR4 verdict per (tool, asset-kind).
> Every verdict cites study rows above so "the FR4 decision follows from the study" (AC4b).

### Decision Procedure

A native format is kept as a documented native exception only when **ALL** of:

1. **(gap/un-translatable)** a behavioral axis is `gap` or un-`translate`-able under uniform markdown for that tool, and the generator cannot translate it at render time; **and**
2. **(AID relies on it)** AID actually exercises that behavior; **and**
3. **(`high` confidence)** the finding is `high` confidence.

Fail any of (1) / (2) / (3) → commit uniform markdown.

### Decision Table — Verdict per (tool, asset-kind)

| Tool | Asset-kind | Native format | Decision | Gating axis | Study citation |
|------|------------|---------------|----------|-------------|----------------|
| Claude Code | agents | markdown+yaml | **uniform-markdown** | none — native format *is* uniform markdown | §1 discovery/dispatchability rows (`preserve`, `high`); D1/D2 |
| Claude Code | skills | markdown (`SKILL.md`) | **uniform-markdown** | none — `.claude/skills/<slug>/SKILL.md` is native uniform markdown | §1 discovery row (`preserve`, `high`); D1 |
| Cursor | agents | markdown+yaml | **uniform-markdown** | capability/permissions (`Bash`→`Terminal`) — `translate`, not `gap` | §2 capability row (`translate`, `high`); D1/D2 |
| Cursor | skills | markdown (`SKILL.md`) | **uniform-markdown** | none — skill folder is native markdown | §2 discovery row (`preserve`/`high` agents); D1 |
| Codex | agents | toml (today) | **uniform-markdown (EXPECTED); TOML branch DORMANT (gated fallback)** | discovery (E-CODEX-1) — `gap-or-preserve` UNRESOLVED, `medium` (probe NOT RUN) | §3 discovery row E-CODEX-1 (`medium`, NOT RUN); D1/D2 (dispatch format-agnostic, `high`) |
| Codex | skills | markdown (`SKILL.md`) | **uniform-markdown** | none — skills are not the divergent surface | §3 dispatchability/capability rows (`preserve`, `high`); D1 |
| GitHub Copilot CLI | agents | `copilot-agent` (`.agent.md`) | **uniform-markdown** | capability (`Bash`→`shell`) + `.agent.md` suffix + sequence-form `tools:` — all `translate`/path-detail | §4 capability row (`translate`, `high`); discovery row (`preserve`); D1/D2 |
| GitHub Copilot CLI | skills | markdown (`SKILL.md`) | **uniform-markdown** | none — `.github/skills/<slug>/SKILL.md` is native uniform markdown | §4 discovery row (`preserve`); D1 |
| Antigravity | agents | `antigravity-rule` (rule-md) | **uniform-markdown** | execution-model + capability — documented runtime gaps in the rule primitive, not format-encoding choices | §5 execution-model + capability rows (`gap`, `medium`); D1/D2 |
| Antigravity | skills | markdown (`SKILL.md`) | **uniform-markdown** | none — `.agent/skills/<slug>/SKILL.md` is native uniform markdown | §5 discovery row (`preserve`); D1 |

**Summary: 10 of 10 (tool, asset-kind) verdicts = uniform markdown.** The only non-uniform-markdown candidate is Codex agents, where the TOML branch is retained DORMANT (not deleted) as the E-CODEX-1-gated fallback — the verdict is uniform-markdown-EXPECTED.

### AC4b Discharge

AC4b is discharged. The FR4a capability study exists and is documented (§§ 1–5 + Cross-Tool Summary above), and this FR4 decision section cites it — every (tool, asset-kind) verdict cites a specific study row + Finding D1/D2 + the E-CODEX-1 result. No branch is deleted in this document; it is the gate that authorizes feature-002/task-003+ to act on FR4.
