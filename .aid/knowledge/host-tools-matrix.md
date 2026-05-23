# Host-Tools Matrix

> **Source:** aid-discover (orchestrator — KB extension, outside the standard 16)
> **Status:** Populated (initial pass, 2026-05-21)
> **Companions:** `integration-map.md` (per-tool integration depth), `tech-debt.md` H1/H3 (triplication drift), `coding-standards.md` §1–§4 (per-tool frontmatter contracts), `external-sources.md` (vendor docs + per-vendor local cross-reference).

## Purpose

AID is a multi-tool methodology. This matrix is the single page that answers:

1. *Which AI coding tools does AID ship support for today, and which are aspirational?*
2. *For each shipped tool — what's in the install payload, in which native format, and where does it land in the user's project?*
3. *Which AID features (skills + agents + the optional HTML viewer) are at parity across tools, and where does each tool diverge from the canonical Claude Code experience?*
4. *Which known divergences are bugs vs. by-design tool-specific adaptations?*

If you need depth on any one tool, follow the cross-references at the top.

## 1. Tool Support Status

| Tool | Status | Install payload in repo | User-side install root | Vendor docs (`external-sources.md`) |
|------|--------|-------------------------|------------------------|-------------------------------------|
| **Anthropic Claude Code** | ✅ Live | `profiles/claude-code/.claude/` (22 agents, 10 skills, templates) + `profiles/claude-code/CLAUDE.md` | `<project>/.claude/` + `<project>/CLAUDE.md` | Row 1 — https://docs.claude.com/en/docs/claude-code/overview |
| **Anthropic Claude Agent SDK** | ➖ Reference-only | None (no install payload — listed for completeness) | n/a (programmatic SDK) | Row 2 — https://docs.claude.com/en/api/agent-sdk/overview |
| **OpenAI Codex CLI** | ✅ Live | `profiles/codex/.codex/agents/` (22 TOMLs) + `profiles/codex/.agents/{skills,templates}/` + `profiles/codex/AGENTS.md` | `<project>/.codex/` + `<project>/.agents/` + `<project>/AGENTS.md` | Rows 3–4 — https://github.com/openai/codex, https://developers.openai.com/codex/ |
| **Cursor** | ✅ Live | `profiles/cursor/.cursor/{agents,rules,skills,templates}/` (22 agents, 10 skills, 2 rules) + `profiles/cursor/AGENTS.md` | `<project>/.cursor/` + `<project>/AGENTS.md` | Rows 5–6 — https://docs.cursor.com/context/rules-for-ai, https://docs.cursor.com/context/model-context-protocol |
| **GitHub Copilot CLI** | 🔮 Future | None — referenced in `README.md:267`, `CONTRIBUTING.md:58`, `docs/faq.md:28` as a future target | n/a | Row 7 — https://docs.github.com/en/copilot |
| **Google Antigravity** | 🔮 Future (URL unconfirmed) | None | n/a | Row 8 — https://antigravity.google/docs (flagged "to confirm via search") |

> Legend: ✅ Live = install payload ships in this repo and is exercised by `setup.{sh,ps1}`. ➖ Reference-only = listed in external sources but no payload. 🔮 Future = aspirational; no payload yet.

## 2. AID Capability × Host Tool Parity

Every cell answers: *does this capability ship for this tool, and how?*

| AID capability | Claude Code | Codex CLI | Cursor | Copilot (future) | Antigravity (future) |
|----------------|-------------|-----------|--------|------------------|----------------------|
| `aid-init` skill | ✅ `profiles/claude-code/.claude/skills/aid-init/SKILL.md` | ✅ `profiles/codex/.agents/skills/aid-init/SKILL.md` | ✅ `profiles/cursor/.cursor/skills/aid-init/SKILL.md` | ❌ | ❌ |
| `aid-discover` skill | ✅ 453 lines, `references/` + `scripts/` split | ✅ 1,078 lines (inlined) | ✅ 1,090 lines (inlined) | ❌ | ❌ |
| `aid-interview` skill | ✅ 477 lines | ✅ 694 lines | ✅ 698 lines | ❌ | ❌ |
| `aid-specify` skill | ✅ 413 lines | ✅ 485 lines | ✅ 488 lines | ❌ | ❌ |
| `aid-plan` skill | ✅ 336 lines | ✅ 332 lines (small drift, 4 lines) | ✅ matches Claude Code | ❌ | ❌ |
| `aid-detail` skill | ✅ | ✅ (5-line drift vs Claude Code) | ✅ (byte-identical to Claude Code) | ❌ | ❌ |
| `aid-execute` skill | ✅ 386 lines | ✅ 558 lines | ✅ 562 lines | ❌ | ❌ |
| `aid-deploy` skill | ✅ | ✅ (identical to Claude Code) | ✅ (identical) | ❌ | ❌ |
| `aid-monitor` skill | ✅ | ✅ (identical) | ✅ (identical) | ❌ | ❌ |
| `aid-summarize` skill | ✅ 430 lines | ✅ 436 lines | ✅ 436 lines | ❌ | ❌ |
| 22 named agents | ✅ markdown + YAML frontmatter | ✅ TOML with `developer_instructions` | ✅ markdown + YAML (uses `Terminal` tool name vs `Bash`) | ❌ | ❌ |
| Knowledge-summary HTML viewer assets | ✅ `profiles/claude-code/.claude/templates/knowledge-summary/` (~25 files) | ✅ `profiles/codex/.agents/templates/knowledge-summary/` (~25 files) | ✅ `profiles/cursor/.cursor/templates/knowledge-summary/` (~25 files) | ❌ | ❌ |
| `setup.sh` installer | ✅ copies `profiles/claude-code/.claude/` + `CLAUDE.md` | ❌ **CONFIRMED BUG (Q70)** — copies `profiles/codex/.codex/` + `AGENTS.md` but omits `profiles/codex/.agents/` (skills + templates). Patch trivial; tracked as `tech-debt.md H6`. | ✅ copies `profiles/cursor/.cursor/` + `AGENTS.md` | ❌ | ❌ |
| `setup.ps1` installer | ✅ | ❌ **CONFIRMED same Q70 omission** as `setup.sh` (lines 137-141). | ✅ | ❌ | ❌ |
| MCP integration | ⚪ Documented as supported by tool, AID ships nothing | ⚪ Unknown — needs vendor-doc fetch | ⚪ Documented as supported, AID ships nothing | n/a | n/a |
| Hooks ecosystem | ⚪ Documented, AID ships nothing | ⚪ Unknown | ⚪ Documented, AID ships nothing | n/a | n/a |
| `Project-context` file convention | `CLAUDE.md` | `AGENTS.md` | `AGENTS.md` (+ `.cursor/rules/*.mdc` always-on) | n/a | n/a |
| Cross-tool skill loading | n/a | n/a | ⭐ Reads `.claude/skills/` AND `.codex/skills/` per `profiles/cursor/README.md:142` | n/a | n/a |

> Legend: ✅ Ships and at parity. ⚠️ Ships but with a known divergence or bug. ⭐ Tool-specific superset. ⚪ Possible but unused by AID today. ❌ Not implemented. ➖ Reference-only.

## 3. Per-Tool Native Format Summary

| Aspect | Claude Code | Codex CLI | Cursor |
|--------|-------------|-----------|--------|
| Agent file format | Markdown + YAML frontmatter | TOML | Markdown + YAML frontmatter |
| Agent frontmatter required fields | `name`, `description`, `tools`, `model` | `name`, `description`, `model`, `model_reasoning_effort`, `developer_instructions` (multi-line) | `name`, `description`, `tools`, `model` |
| Agent shell-tool name | `Bash` | (Bash invoked via `developer_instructions` prose) | `Terminal` (Cursor canonical name) — but `profiles/cursor/.cursor/agents/` is **internally inconsistent** (some agents use `Bash`, e.g., `discovery-reviewer.md`). Per DISCOVERY-STATE Q52: audit + unify on `Terminal`. Tracked as `tech-debt.md M6`. |
| Skill file format | `SKILL.md` (YAML frontmatter + markdown body) | `SKILL.md` (same frontmatter) | `SKILL.md` (same frontmatter) |
| Skill optional fields | `context: fork`, `agent: <name>` (Claude-specific harness hints) | Omits `context:` / `agent:` (Codex CLI has no equivalent — Q51) | Same as Claude Code |
| Skill decomposition | Externalize content into `references/*.md` + `scripts/*.sh` (canonical pattern) | Inline everything in the SKILL.md body (cause of 2.4× line-count vs Claude Code) | Inline everything (same as Codex) |
| Project-context file | `CLAUDE.md` (top-level) | `AGENTS.md` (top-level) | `AGENTS.md` (top-level) + `.cursor/rules/*.mdc` for always-on rules |
| Permission file | `.claude/settings.json` with `permissions.allow/deny` (Bash allow-list) | None shipped — Codex prompts inline per command | `.cursor/` directory holds rules; permission UI is Cursor-app-side |
| Always-on rules | n/a (use `CLAUDE.md` for project-wide direction) | n/a (use `AGENTS.md`) | `.cursor/rules/*.mdc` with `alwaysApply: true` |
| Hook events | Supported by tool, none shipped by AID | Unknown | Supported by tool, none shipped by AID |
| MCP server registration | Supported by tool, none shipped by AID | Unknown | Supported by tool, none shipped by AID |

## 4. Three-Tier Agent Model — Tier Mapping

All 22 agents are tier-consistent across all 3 install trees (verified by quality agent; the May 2026 tier-rename migration documented at `profiles/codex/README.md:35` was applied cleanly).

| Tier | Claude Code model | Codex model | Codex reasoning effort | Cursor model | Used for |
|------|-------------------|-------------|------------------------|--------------|----------|
| **Opus** | `claude-opus-4-7` (alias `opus`) | `gpt-5.5` | `high` | `claude-opus-4-7` (or equivalent the user has) | Judgment-heavy roles: **3 Core** (Architect, Reviewer, Interviewer) + **1 Specialist** (Security) + **all 6 Discovery sub-agents** (Scout, Analyst, Architect, Integrator, Quality, Reviewer) = 10 agents. |
| **Sonnet** | `claude-sonnet-4-6` (alias `sonnet`) | `gpt-5.4` | `medium` | `claude-sonnet-4-6` | Operational / orchestration roles: **4 Core** (Orchestrator, Researcher, Developer, Operator) + **5 Specialist** (Data Engineer, Performance, Tech Writer, UX Designer, DevOps) = 9 agents. |
| **Haiku** | `claude-haiku-4-5` (alias `haiku`) | `gpt-5.4-mini` | `low` | `claude-haiku-4-5` | Mechanical-work-only — never synthesis: **3 Utility** (Simple Extractor, Simple Formatter, Simple Glob). |

**Verified tier counts** (recounted from `profiles/claude-code/.claude/agents/*.md` `model:` frontmatter, 2026-05-21 post-cycle-3 review): **10 Opus + 9 Sonnet + 3 Haiku = 22 agents** per install tree. May 2026 migration (`profiles/codex/README.md:35`) confirmed consistent across all 3 trees per `tech-debt.md` L6.

## 5. Known Divergences and Bugs

> Each row links to the DISCOVERY-STATE Q&A item where it's tracked.

| # | Tool(s) | Issue | Severity | Status | Q&A |
|---|---------|-------|----------|--------|-----|
| 1 | Codex | ❌ `setup.sh` / `setup.ps1` Codex branches copy `profiles/codex/.codex/` + `AGENTS.md` but **omit** `profiles/codex/.agents/` — Codex users get agent TOMLs without skill bodies. CONFIRMED via reviewer static-analysis spot-check. | HIGH | **CONFIRMED — patch tracked in `tech-debt.md H6`** | **Q70** |
| 2 | Codex | `discovery-reviewer` writes to `DISCOVERY-GRADE.md` + `open-questions.md` while Claude Code / Cursor write to `DISCOVERY-STATE.md` + `additional-info.md` (semantic drift, not just project-context file name) | HIGH | Pending decision | **Q30** |
| 3 | All trees | Skill body line-count drift: `aid-discover/SKILL.md` 453 (Claude Code) vs 1,078 (Codex) vs 1,090 (Cursor) — also `aid-interview`, `aid-execute`, `aid-specify`. Cause = inlining vs `references/` split. No propagation tooling exists | HIGH | Pending decision (intentional or accidental?) | **Q3, Q73** |
| 4 | All trees | `CONTRIBUTING.md:21-26` documents triplication rule as "human README + Claude Code + Codex" — **omits Cursor entirely**. The discipline is actually quadruplicate | HIGH | Pending update | **Q72, Q34** |
| 5 | Cursor | Cursor agents are **internally inconsistent** on the shell-execution tool name: `architect.md` uses `Terminal` (canonical), `discovery-reviewer.md` uses `Bash`. Cursor canonical per `external-sources.md` rows 5-6 is `Terminal`. Audit + rename remaining `Bash` → `Terminal` across all 22 agents. | MEDIUM | **CONFIRMED internal inconsistency — patch tracked in `tech-debt.md M6`** | **Q52** |
| 6 | Codex | Cursor `AGENTS.md` (45 lines, has KB + Permissions + Skills sections) vs `profiles/codex/AGENTS.md` (28 lines, minimal) vs `profiles/claude-code/CLAUDE.md` (30 lines, minimal) — three-way template-shape asymmetry | LOW | Pending alignment | **Q82** |
| 7 | Codex | `profiles/codex/.codex/agents/developer.toml:11-12` hardcodes a Maven build command + `ProjectRoot/pom.xml` path — likely template-fragment leak | MEDIUM | Pending cleanup | (in `security-model.md` 1.3; not separately Q'd) |
| 8 | Codex | Split `.codex/` (agents) + `.agents/` (skills) layout — documented in `profiles/codex/README.md:12-15` but rationale not stated | MEDIUM | Pending documentation | **Q9** |
| 9 | All trees | The 7 Claude Code skills that declare `context: fork` and/or `agent: <name>` — these fields are absent on Codex equivalents | MEDIUM | Pending documentation | **Q51** |
| 10 | All trees | The matched-pair `<!-- AID-DISCOVER {id} -->` ... `<!-- /AID-DISCOVER -->` placeholder style in this repo's own `CLAUDE.md` vs the single-line `<!-- AID-DISCOVER — Replace with ... -->` placeholder style in the three install payloads | MEDIUM | Pending documentation (likely by-design — install payloads are pre-aid-discover) | **Q50, Q81** |

**Positive parity finding:** the May 2026 tier-rename migration (`profiles/codex/README.md:35`) successfully unified the Opus / Sonnet / Haiku ↔ `gpt-5.5` / `gpt-5.4` / `gpt-5.4-mini` mapping across all 22 agents in all 3 trees. No drift detected.

## 6. Cross-Tree Asset Inventory

The same templates and scripts are duplicated four ways (root `templates/` + 3 install trees). From `tech-debt.md` H4:

| Asset | Lines per copy | Copies | Total duplicated lines |
|-------|----------------|--------|------------------------|
| `build-project-index.sh` | 368 | 4 | 1,472 |
| `lightbox.js` (knowledge-summary viewer) | 359 | 4 | 1,436 |
| `validate-diagrams.mjs` | 294 | 4 | 1,176 |
| `component-css.css` (knowledge-summary) | 642 | 4 | 2,568 |
| `grade.sh` (knowledge-summary variant) | 194 | 4 | 776 |
| `prompt.md` (knowledge-summary) | 248 | 4 | 992 |
| `grading-rubric.md` (knowledge-summary) | 226 | 4 | 904 |
| `mermaid-examples.md` | 187 | 4 | 748 |
| `accessibility-checklist.md` | 125 | 4 | 500 |
| ...rest of scripts/assets | (see `tech-debt.md` H4 for full table) | 4 each | — |

**Total estimated 4-way duplicated content:** ~17,600 lines = ~36% of the 49,226-line repository total.

## 7. Future Tool Onboarding Checklist

To add a fifth tool (e.g., Copilot CLI or Antigravity), the contributor would need to:

1. Decide the install-tree layout under `<tool-slug>/...` mirroring the existing three.
2. Translate each of the 22 agent definitions into the tool's native format (markdown / TOML / `.mdc` / something new).
3. Translate or copy each of the 10 SKILL.md files (inlining or splitting per the tool's preference).
4. Copy the `templates/knowledge-summary/` asset bundle.
5. Author a `<tool-slug>/<context-file>` analogous to `CLAUDE.md` / `AGENTS.md`.
6. Update `setup.{sh,ps1}` to add a menu entry and copy rule.
7. Update `README.md`, `CONTRIBUTING.md` (triplication → 5-way), `docs/faq.md`, and this matrix.
8. Add the tool's vendor docs URL to `external-sources.md` and write a local cross-reference once a payload exists.

The largest cost is item 2 (22 agent translations) plus item 6 (installer logic + the still-unresolved cross-tree-sync question from **Q3 / Q72**).

## 8. Where to Read Next

- **Choosing a tool as an adopter** → `external-sources.md` (vendor docs + local payload paths) + Section 1 above.
- **Implementing a fix that must hit all 3 trees** → `coding-standards.md` §9 (the triplicate-updates rule, with Q34/Q72 corrections in mind).
- **Investigating a parity bug** → Section 5 above, then jump to the linked Q&A entry in `DISCOVERY-STATE.md`.
- **Adding a 5th tool** → Section 7 above + `CONTRIBUTING.md` (pending the Q34/Q72 update).
