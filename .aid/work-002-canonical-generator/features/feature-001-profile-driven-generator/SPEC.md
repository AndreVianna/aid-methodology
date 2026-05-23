# Profile-Driven Install-Tree Generator

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-22 | Feature identified from REQUIREMENTS.md §5 (FR5) (originally REQUIREMENTS.md §5 FR5 of work-001-aid-lite) | /aid-interview |
| 2026-05-22 | Technical Specification — Data Model section written (canonical/ source + profiles/ TOML descriptors) | /aid-specify |
| 2026-05-22 | Technical Specification — Feature Flow section written (5-step pipeline; two-layer VERIFY: deterministic hard gate + advisory conformance review; pure-mirror RENDER) | /aid-specify |
| 2026-05-22 | Technical Specification — Layers & Components section written (4 layers; Python render scripts; end-user-needs-no-Python hard boundary per NFR5) | /aid-specify |
| 2026-05-22 | Technical Specification — Migration Plan section written (7-step cutover; canonical/ bootstrapped from the Claude Code tree; H6 installer fix folded in) | /aid-specify |
| 2026-05-22 | Amended (decision F) — all three profiles use `references` decomposition; the inline-for-Codex/Cursor framing removed (2026-05-22 research: on-demand reference loading is universal) | /aid-specify |

## Source

- REQUIREMENTS.md §1–§7 (work-002-canonical-generator)
- Originally REQUIREMENTS.md §5 FR5, §8, §9, §10 of work-001-aid-lite (pre-reshape)

## Description

Today the same skills, agents, and templates are hand-maintained in four parallel
locations — the human-canonical sources plus three per-tool install trees — and
they drift apart over time. This feature replaces that hand-maintained duplication
with a single tool-agnostic canonical source plus a declarative profile per host
tool. A profile describes one tool's conventions — directory layout, frontmatter
schema, file extensions, inline vs. `references/` decomposition, agent format,
model-tier mapping — and a set of capability flags (hook support, skill-chaining
support, background execution) that doubles as the per-tool capability registry the
rest of AID consults. Generating an install tree becomes nothing more than running
a profile, and onboarding a future host tool becomes authoring one new profile with
zero changes to canonical content or existing trees. This locks in the footprint
refactor so drift cannot re-accumulate, and makes announced future targets cheap to
add.

## User Stories

- As an AID methodology maintainer, I want to edit skills, agents, and templates in
  one canonical place so that I no longer have to apply every change four times by
  hand and risk the trees drifting apart.
- As an AID methodology maintainer, I want to onboard a new host tool by writing a
  single declarative profile so that supporting GitHub Copilot CLI or Google
  Antigravity does not require duplicating the whole methodology again.
- As an AID end user, I want the install tree for my host tool to behave the same as
  every other tool's tree so that the methodology works consistently regardless of
  which tool I run it through.

## Priority

Must

## Acceptance Criteria

- [ ] Given a canonical source and a set of per-tool profiles, when the generator is
  run, then every install tree is produced from that one canonical source by running
  the corresponding profile.
- [ ] Given the generator has already produced the install trees, when the generator
  is re-run, then every tree is reproduced with zero drift.
- [ ] Given a new host tool needs to be supported, when a maintainer adds a new
  profile for it, then a complete install tree is generated with no change to
  canonical content or to any existing tree.
- [ ] Given a profile declares a host tool's capability flags (hook support,
  skill-chaining support, background execution), when other AID features need to
  know a tool's capabilities, then the profile serves as the authoritative
  per-tool capability registry.

---

## Technical Specification

> The generator (originally FR5 of work-001-aid-lite) is a **maintainer-facing skill** that runs inside the agentic
> platform (it maintains the AID repo itself; it is not part of the user-facing
> pipeline). Rendering is **deterministic** — deterministic helper scripts perform
> the mechanical transformation, so re-runs are byte-identical.

### Data Model

The generator works over two structures: the **canonical source** and the
**per-tool profiles**.

#### Canonical source — `canonical/`

One tool-agnostic copy of every skill, agent, and template, at the repo root:

```
canonical/
  skills/aid-{name}/
    SKILL.md               # thin router: frontmatter + pre-flight + state-detection + dispatch table
    references/state-*.md  # per-state detail
    scripts/*.sh           # helper scripts
  agents/{name}.md         # one agent definition: abstract frontmatter + body
  templates/...            # format-agnostic templates
```

The canonical skill is stored in the **FR3 thin-router structure** (states
externalized to `references/state-*.md`). All three host tools support on-demand `references/` loading
(confirmed by 2026-05-22 capability research), so every profile renders skills in
the externalized thin-router form — the structure is carried through to every
install tree. FR5's canonical
format and FR3's refactor target are therefore the *same structure* — the reason
work-001-aid-lite's §10 sequences this work first, before FR3 (FR5 defines the
shape; FR3 fills it).

The `canonical/` tree is **extensible**: skills, agents, and templates are the
initial asset kinds, but other features may add new kinds under `canonical/` —
future integrations may extend the canonical layout with hooks, scripts, or other
asset kinds, from which the generator would render each profile's per-tool
configuration as a normal RENDER output. `canonical/` is extensible by design.

#### Profiles — `profiles/`

One declarative file per host tool, grouped at the repo root:

```
profiles/
  claude-code.toml
  codex.toml
  cursor.toml
```

Format: **TOML** — consistent with AID's existing Codex agent definitions, supports
comments, and maps cleanly to the structured fields below. Each profile declares:

| Field | Purpose |
|-------|---------|
| `layout` | Output root + per-kind directories (agents / skills / templates / rules) + project-config filename (`CLAUDE.md` vs `AGENTS.md`) |
| `agent.format` | `markdown` (Claude Code, Cursor) or `toml` (Codex) |
| `agent.frontmatter` | The frontmatter field schema for that tool's agent files |
| `skill.decomposition` | `references` for all three current tools — every host tool supports on-demand `references/` loading; the field stays per-tool for future tools |
| `skill.frontmatter` | The SKILL.md frontmatter schema for that tool — `name`, `description`, `allowed-tools`, `argument-hint`, plus optional fields such as Claude Code's `context:` / `agent:` |
| `model_tiers` | Small / Medium / Large → the tool's model names (+ Codex `model_reasoning_effort`) |
| `tool_names` | Abstract → tool-specific tool-name map (e.g. `Bash` → `Terminal` for Cursor) |
| `extras` | Tool-specific additions (e.g. Cursor `.mdc` rules) |
| `capabilities` | `hooks`, `skill_chaining`, `background_execution`, `stop_hook_autocontinue` — the per-tool capability registry consulted by downstream features that need to know a host tool's capabilities (`stop_hook_autocontinue` is retained as a forward-looking registry entry; no surviving consumer in the current work scope) |

#### Outputs

The generator produces the **three install trees** (`claude-code/`, `codex/`,
`cursor/`) from `canonical/` + the profiles. There is no "human-readable" profile —
the human-readable `skills/` / `agents/` READMEs at the repo root are out of scope
for the generator and remain separate.

`canonical/` + `profiles/` replace the hand-maintained triplication of skill /
agent / template *content* across the three install trees. Migration from the
current state is specified in the Migration Plan section below.

### Feature Flow

The generator skill, invoked by the maintainer inside the agentic platform on the
AID repo, runs this pipeline. (This describes steady-state operation — it assumes
the one-time migration to `canonical/` + `profiles/` is complete; see the Migration
Plan section.)

1. **LOAD** — read `canonical/` (source) and `profiles/*.toml` (descriptors).
2. **VALIDATE** — each profile is well-formed; `canonical/` is complete (every skill,
   agent, and template present).
3. **RENDER** — for each profile (`claude-code`, `codex`, `cursor`), run the
   deterministic render scripts:
   - **agents** — `canonical/agents/{name}.md` → the tool's format (markdown or
     TOML), applying the profile's frontmatter schema, model-tier map, tool-name map.
   - **skills** — `canonical/skills/aid-{name}/` → `SKILL.md` with its `references/`
     kept externalized (`skill.decomposition = references` — all three current
     profiles; on-demand reference loading is universal).
   - **templates** — `canonical/templates/` → placed per the profile's `layout`.
   - **extras** — e.g. Cursor `.mdc` rules.

   The install tree is a **pure mirror** of `canonical/ + profile`: RENDER also
   deletes any install-tree file **under a generator-owned path** whose canonical
   source no longer exists, so a stale file cannot silently survive; paths outside
   the generator's output set are never touched.

   **Generator-owned paths are defined by the emission manifest.** During RENDER,
   each renderer records every output path it emits into an **emission manifest**
   (one manifest per profile per run; the union across renderers is the profile's
   complete owned-path set for this run). Deletion is restricted to paths that
   appear in the *previous* run's manifest but not in the current run's — i.e. only
   paths the generator itself previously emitted are candidates for deletion. Any
   install-tree file that has never appeared in a manifest (e.g. user-added content,
   out-of-band files) is, by construction, outside the generator's output set and
   never touched. The previous-run manifest is committed alongside the generated
   trees so the safety boundary is reproducible across machines and re-runs.

   RENDER is **pure** — output is a function only of
   `(canonical source, profile)`, with no timestamps or ordering nondeterminism —
   which is what makes re-runs byte-identical.
4. **VERIFY** — two layers:
   - **4a — deterministic (hard gate).** Re-render is byte-identical; every expected
     file present; all frontmatter parses. Run by scripts. A failure here blocks.
   - **4b — conformance (advisory).** An agent review reads each host tool's official
     documentation (the vendor-doc URLs in `external-sources.md`) and compares the
     generated files against what those docs currently recommend — frontmatter
     fields, file structure, naming, deprecations. Discrepancies are reported as
     warnings: they indicate the **profile** has drifted from the tool's actual
     recommendations and should be reviewed by the maintainer. This is the mechanism
     by which work-001-aid-lite §8's "provider capability tracking" is satisfied.
     VERIFY-4b is non-deterministic and sits *outside* the pure render, so it does
     not affect the byte-identical guarantee. **Graceful degradation:** when a
     vendor doc is unreachable or still marked `⚠️ Pending fetch` in
     `external-sources.md` (all 8 URLs are pending at time of writing), the
     conformance check for that doc is **skipped with a warning** in the REPORT
     output rather than failing the run — VERIFY-4b is an advisory layer, never a
     blocking gate.
5. **REPORT** — which trees were regenerated, file counts, the `git diff` of the
   install-tree paths (the concrete zero-drift evidence — empty when `canonical/`
   and the profiles were unchanged), and the VERIFY-4b advisory findings.

**Scope:** "generate all three" by default; "generate `{tool}`" regenerates a single
tree.

**Determinism boundary:** steps 3 (RENDER) and 4a are deterministic and
reproducible; step 4b is an advisory AI review layered on top. The
byte-identical-re-run acceptance criterion (work-002 §6 AC2) is satisfied by steps
3 + 4a alone.

**Installer seam.** The generator produces install-tree *content*; the installer
(`setup.sh` / `setup.ps1`) that copies a tree into a user project — and the fix to
tech-debt H6 (the Codex installer omitting `codex/.agents/`, mandated by work-002 §3 / work-001-aid-lite §8) — is
addressed in the Migration Plan section.

### Layers & Components

The generator is a maintainer-facing skill plus deterministic helper scripts, in
four layers:

| Layer | Component | Role |
|-------|-----------|------|
| Orchestration | the generator `SKILL.md` | The maintainer-facing skill the agent executes — LOAD → VALIDATE → RENDER (per profile) → VERIFY → REPORT. A meta-skill that maintains the AID repo itself. |
| Render | render `scripts/` — agent renderer, skill renderer, template renderer, profile parser | The pure deterministic engine; one renderer per asset kind, each driven by the profile. |
| Verify | verify `scripts/` (4a — separate files from the render scripts) + a dispatched conformance agent (4b) | 4a: deterministic checks (byte-compare, frontmatter parse, file presence). 4b: advisory conformance review against vendor docs. |
| Data | `canonical/` + `profiles/` | The source content and per-tool descriptors (see Data Model). |

*LOAD, VALIDATE, and REPORT are orchestration logic within the generator `SKILL.md`
— not separate components.*

**Placement.** The generator skill and its render scripts are **maintainer tooling**
— they maintain the AID repo itself. They live in the AID repo's own tooling
location (e.g. `.claude/skills/` — the exact host-tool placement is an
implementation detail), NOT in `canonical/` and NOT in any install tree.
Users never receive or invoke the generator.

**Render-script implementation: Python.** The render scripts perform structured
transformation — parse TOML, transform frontmatter, convert markdown↔TOML agent
format, inline or externalize skill `references/`. Bash (AID's existing
helper-script language) is poorly suited to that class of work. The render scripts
are therefore written in **Python** — native TOML parsing (`tomllib`, 3.11+), clean
structured-text handling, readable and testable renderers.

**End users require no Python — a hard boundary (NFR5).**

- The generator runs **only on the AID maintainer's machine**, at build time, when
  the maintainer regenerates the install trees.
- The **generated install trees are committed to the AID repo.**
- An end user installs AID by running `setup.sh` / `setup.ps1`, which **copies a
  pre-generated, committed tree** into their project — exactly as today. The user
  never invokes the generator and never needs Python.
- Python is therefore a **maintainer-only, build-time dependency** — precisely what
  NFR5 permits ("the FR5 generator is a maintainer-side build tool; build-time
  dependencies acceptable; the end-user install stays close to today's `git clone`
  + minimal deps").

**Dependencies.** Minimal — the skill hands each render script the profile path,
the canonical root, and the output root; the script is otherwise self-contained. No
service container, no DI framework.

### Migration Plan

feature-001 is a brownfield change: today the same skill / agent / template
content is hand-maintained in **four parallel locations** — the human-readable
`skills/` and `agents/` READMEs at the repo root plus the three per-tool install
trees (`claude-code/`, `codex/`, `cursor/`) — and `CONTRIBUTING.md` instructs
contributors to update all of them by hand. The one-time cutover:

1. **Bootstrap `canonical/`.** Extract the tool-agnostic content from the **Claude
   Code tree** — the richest, as it already carries the `references/` decomposition
   that is the canonical structure. Where the Codex and Cursor trees differ (the
   documented body drift — e.g. `aid-discover/SKILL.md` is 453 / 1,078 / 1,090 lines
   across the trees), the maintainer resolves to the correct content during
   bootstrap. The generator is **structure-agnostic**: a skill not yet refactored to
   thin-router form is carried as a monolithic `SKILL.md` and rendered monolithic to
   every tree; once FR3 refactors the canonical content to thin-router form, a
   re-render produces the thin-router form (references kept) across every tree.
   (This is the FR5 → FR3
   interlock: FR5 ships first with `canonical/` bootstrapped as-is; FR3 then
   refactors the canonical content.)
2. **Author the three profiles** — `claude-code.toml`, `codex.toml`, `cursor.toml` —
   encoding each tool's conventions, extracted from the current trees and
   `coding-standards.md`.
3. **Bootstrap verification.** Run the generator. The generated trees should equal
   the current committed trees *except* where the current trees carried drift — that
   diff is the drift being eliminated. The maintainer reviews it to confirm it only
   removes drift and loses nothing.
4. **Cut over.** The three install trees become generated artifacts (still committed
   to the repo). `CONTRIBUTING.md`'s manual cross-tree update rule
   (`CONTRIBUTING.md:21-26` — itself incomplete: it enumerates only three locations
   and omits Cursor, tech-debt H5) is replaced with "edit `canonical/`, run the
   generator" — which also retires H5.
5. **Installer / tech-debt H6 fix (work-001-aid-lite §8 / work-002 §3 mandate).** `setup.sh` / `setup.ps1` continue
   to *copy* the (now generated, complete) trees. The H6 bug — the Codex branch of
   `setup.sh` / `setup.ps1` never copying `codex/.agents/` — is fixed as part of this
   cutover: the installer must copy the **full** Codex tree (`.codex/` **and**
   `.agents/`).
6. **Backward compatibility (NFR2).** Existing user installs are untouched.
   Re-running `setup.sh` on an existing project surfaces the drift-corrected trees
   through its existing "skip identical / prompt on different" behavior — no silent
   breakage.
7. **Out of scope.** The human-readable `skills/` / `agents/` READMEs remain
   hand-maintained (there is no human-readable profile — a Data Model decision). A
   deliberate, accepted residue of manual upkeep.
