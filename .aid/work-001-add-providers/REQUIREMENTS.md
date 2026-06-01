# Requirements

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-31 | Initial interview started | /aid-interview |
| 2026-05-31 | Captured objective + platform research (Copilot CLI + Antigravity conventions); Antigravity←cursor decision; deep-research set as 1st deliverable | /aid-interview |
| 2026-05-31 | Interview complete — approved | /aid-interview |
| 2026-05-31 | Decomposed into 4 features (trimmed from 5 via over-engineering review); cross-reference A+ (all codebase claims confirmed) | /aid-interview |
| 2026-05-31 | §2 corrected by FR1 research (delivery-001): Copilot CLI shipped native Agent Skills 2025-12-18; impedance mismatch narrowed (skills map natively, only sub-agents need transformation) | /aid-execute (FR1 loopback) |

## 1. Objective

Extend AID's multi-tool distribution to **two new host-tool providers** — **GitHub Copilot
CLI** and **Google Antigravity** — alongside the existing Claude Code / Codex / Cursor
profiles. Concretely: research each platform's extension/config conventions, add a **render
profile** for each (so `run_generator.py` emits a tool-specific install tree from the single
canonical source), and add **install options** for both in the setup scripts (`setup.sh` +
`setup.ps1`).

## 2. Problem Statement / Context

AID renders one canonical source (`canonical/`) into per-tool install trees via
`run_generator.py`, driven by a `profiles/<tool>.toml` config per provider (today:
`claude-code`, `codex`, `cursor`). Each profile maps AID's primitives — **sub-agents**
(`AGENT.md`), **skills** (slash-command workflows, `SKILL.md` + references), **scripts**,
**templates**, **recipes**, and a **context/instructions file** — into the tool's expected
layout (`.claude/`, `.codex/`+`.agents/`, `.cursor/`). The two requested providers have
**different, thinner extension models** (researched 2026-05-31):

- **GitHub Copilot CLI**
  - Custom agents: `.github/agents/NAME.agent.md` (repo) or `~/.copilot/agents/NAME.agent.md`
    (user) — Markdown + YAML frontmatter (`name, description, target, tools, model,
    user-invocable, mcp-servers, metadata`); invoked via `/agent`, `--agent`, or inference.
  - Instructions: `AGENTS.md` / `.github/copilot-instructions.md` /
    `.github/instructions/**/*.instructions.md` / `$HOME/.copilot/copilot-instructions.md`.
  - MCP: `~/.copilot/mcp-config.json` (`COPILOT_HOME` override).
  - **Native Agent Skills** — `SKILL.md` folders invoked via `/skills` / `/<skill-name>`, read
    from `.github/skills/`, **`.claude/skills/`**, `.agents/skills/` (and `~/.copilot/skills/`).
    **[Corrected by FR1 research 2026-05-31 — see `research/provider-mapping.md`.](#)** The original
    interview seed said Copilot had "no skills primitive"; GitHub shipped Agent Skills 2025-12-18.
- **Google Antigravity** (Windsurf lineage; VS Code-fork like Cursor)
  - Rules: `.agent/rules/*.md` (`trigger:`/`description`/`globs` frontmatter) + `AGENTS.md`
    (cross-tool canonical; `GEMINI.md` also read, override-only) (project); `~/.gemini/…` (global).
  - Workflows: `.agent/workflows/*.md` — **slash-invoked** (e.g. `/generate-unit-tests`); plus a
    native **skills** primitive (`.agent/skills/`).
  - Customization = rules + workflows + skills; no custom *sub-agent* file convention.

**Impedance mismatch** (the core design problem, **narrowed by FR1 research 2026-05-31**): the
mismatch is **smaller than the interview assumed** — both tools now have a native **skills**
primitive, so **AID skills map natively** (folder copy, `[data]`: Copilot `.github/skills/`,
Antigravity `.agent/skills/`), NOT via transformation. The residual mismatch is narrower:
**AID sub-agents** still need transformation (→ Copilot custom-agent `.agent.md` format; →
Antigravity `.agent/rules/` with a frontmatter reshape, since Antigravity has no sub-agent file),
and **scripts/templates** have no native home in either. So the profiles need **targeted
transformation for sub-agents only**, plus data-shaped mapping for skills/context — closer to the
existing 3 profiles than the interview feared. (Authoritative per-primitive dispositions:
`research/provider-mapping.md`.)

## 3. Users & Stakeholders

- **AID adopters on Copilot CLI / Antigravity** — gain a one-command install of the AID
  pipeline adapted to their tool.
- **AID maintainers** — gain two more profiles in the canonical→render pipeline (must stay
  render-drift-clean + tested like the existing 3).

## 4. Scope

### In Scope

- **Deep research (1st deliverable):** the latest GitHub Copilot CLI extension conventions
  (versioned — the model is evolving) and integration of a colleague's existing Copilot CLI
  fork as a reference implementation (fork URL pending from the user). Confirm/refine the
  Antigravity conventions against current docs.
- **Copilot CLI render profile** — `profiles/copilot-cli.toml` + emitted install tree, mapping
  AID's canonical onto Copilot primitives (skills + sub-agents → `.agent.md` agents;
  context → `AGENTS.md`; MCP → `mcp-config.json`; scripts → a chosen referenced home).
- **Antigravity render profile** — `profiles/antigravity.toml` + emitted tree, **modeled on the
  cursor profile** (`.agent/` rules + workflows; skills → workflows; sub-agents → rules/
  workflows; context → `AGENTS.md`/`GEMINI.md`).
- **Setup options** — add Copilot CLI + Antigravity as installable providers in `setup.sh` and
  `setup.ps1`.
- **Tests + render-drift** — extend the render-drift gate + canonical suites to cover the two
  new profiles.

### Out of Scope

- Changing the canonical source or the existing 3 profiles' output (backward compatible).
- Building anything for tool features that don't exist (no faked primitives) — where a tool
  lacks a primitive, the mapping transforms or omits, documented in the research.

## 5. Functional Requirements

- **FR1 — Deep research (RESEARCH).** Produce a findings doc on (a) the **latest** Copilot CLI
  extension model (agents, instructions, MCP, invocation, install/CLI), (b) the colleague's
  fork as a reference (once the URL is provided), and (c) confirmation of Antigravity's
  conventions vs current docs. Output: the concrete per-tool mapping (AID primitive → tool
  primitive) that the two profiles implement. *This is the first deliverable; the profile work
  depends on it.*
- **FR2 — Copilot CLI profile.** `profiles/copilot-cli.toml` + renderer support so
  `run_generator.py` emits a Copilot CLI install tree from canonical: AID sub-agents and skills
  → `.agent.md` agents (with correct frontmatter), context/instructions → `AGENTS.md` (+
  `.github/instructions/` as needed), MCP config, scripts in a referenced location.
- **FR3 — Antigravity profile.** `profiles/antigravity.toml` + renderer support, modeled on the
  cursor profile: skills → `.agent/workflows/*.md`, sub-agents → `.agent/rules/` (or workflows),
  context → `AGENTS.md`/`GEMINI.md`.
- **FR4 — Setup options.** `setup.sh` + `setup.ps1` offer Copilot CLI and Antigravity as
  selectable install targets (alongside the existing 3), installing the right tree to the right
  location.
- **FR5 — Non-regression + coverage.** Render-drift gate + canonical suites extended to the two
  new profiles; generator self-tests green; existing 3 profiles + their output unchanged.

## 6. Non-Functional Requirements

- **Dependency-free core** — no new pip/npm deps; renderer stays stdlib Python + bash.
- **Tool-idiomatic fidelity** — each profile matches the tool's *current* documented conventions
  (verified by FR1's research); no invented/faked primitives.
- **Backward compatible** — the existing 3 profiles render byte-identically as before.
- **Convention over infrastructure** — reuse the existing `profiles/<tool>.toml` + emission-
  manifest mechanism; add profiles as data + mappings, not a new render engine.

## 7. Constraints

- New profiles are auto-discovered/registered the same way the existing 3 are
  (`profiles/<tool>.toml` + emission manifest).
- Render-drift CI gate covers the new profiles; generator self-tests + canonical suites stay
  green; GitHub Actions stay SHA-pinned.
- Where a tool lacks a primitive (Copilot skills, Antigravity sub-agents), the transformation is
  documented, not hidden.

## 8. Assumptions & Dependencies

- **Antigravity ≈ Cursor** (Windsurf lineage) — its profile can be modeled closely on the
  existing cursor profile. To be confirmed by FR1.
- **A colleague's fork added Copilot CLI tooling** — intended as the reference implementation;
  **fork URL/owner pending** (the 2 public forks, `ubidev` + `shake-k`, are on an old pre-
  `profiles/` layout and do NOT contain it).
- Copilot CLI's extension model is **evolving/versioned** — FR1 must pin to the latest.
- The existing `profiles/<tool>.toml` + `run_generator.py` mechanism can express the two new
  mappings (verified at spec time).

## 9. Acceptance Criteria

1. **Research:** a findings doc pins the latest Copilot CLI conventions + the concrete AID→tool
   mapping for both providers (and reflects the colleague's fork if provided).
2. **Copilot CLI:** `run_generator.py` emits a Copilot CLI install tree from canonical that a
   Copilot CLI user can install and use (agents invocable; instructions + MCP in place).
3. **Antigravity:** likewise emits an Antigravity tree (rules + slash-workflows) modeled on the
   cursor profile.
4. **Setup:** `setup.sh` + `setup.ps1` let a user choose Copilot CLI and/or Antigravity and
   install the correct tree.
5. **Non-regression:** existing 3 profiles unchanged (byte-identical); render-drift clean across
   all 5 profiles; generator self-tests + canonical suites green.

## 10. Priority

1. **FR1 — deep research** (Copilot CLI latest + colleague's fork + Antigravity confirm) — the
   mapping everything else depends on.
2. **FR3 — Antigravity profile** (lower-risk; mirrors cursor) and **FR2 — Copilot CLI profile**
   (higher-risk; needs the transformation mapping).
3. **FR4 — setup options.**
4. **FR5 — tests + render-drift** (woven through, finalized last).

*(Detailed deliverable/task sequencing finalized in /aid-plan.)*
