---
kb-category: primary
source: hand-authored
intent: |
  How the AID methodology is presented to users in this GitHub repository: the
  README's structure and key sections, the docs/ folder taxonomy, the examples/
  case studies, the methodology specification document, and external blog/marketing
  references. Read this to understand the user-facing surface of the repo (NOT
  the internal architecture — see architecture.md for that). Replaces the former
  ui-architecture.md (which was scoped wrong — described the KB-viewer UI rather
  than the repo's documentation surface).
contracts: []
changelog:
  - 2026-05-27: Initial authoring during cycle-1 FIX Phase B (replaces deleted ui-architecture.md per Q3)
  - 2026-06-01: Post-merge update for work-001-add-providers (PRs #42/#43/#44) — install surface 3 profiles → 5 (added GitHub Copilot CLI + Antigravity); Option-A AGENTS.md collision handler documented; setup.sh/ps1 line counts refreshed (210/199).
  - 2026-06-03: Post-merge update for work-001-aid-housekeep (PR #49) — total installed skills 10 → 11 (added optional/on-demand aid-housekeep); clarified that README's "## The Pipeline" table still lists 10 pipeline skills only (aid-housekeep is intentionally absent from that table).
  - 2026-06-03: methodology v3.2 — README pipeline framing reconciled: numbered development phases 8 → 6; aid-deploy/aid-monitor recast from numbered phases 7/8 to optional end-of-pipeline Deliver skills; "10 skills" breakdown is now one setup + six numbered phases + three optional skills (summarize, deploy, monitor); Monitor feedback loops re-pointed to Interview (bugs + CRs).
---

# Repo Presentation

## Overview

The AID GitHub repository is itself a documentation product. It ships no application
code — it ships methodology, skills, agents, templates, and install scripts. Every
file a user sees when they clone the repo is part of the methodology's user-facing
surface, and the quality of that surface determines whether a user understands what
AID is and how to adopt it.

The user-facing surface has five layers: the root `README.md` (the pitch and entry
point), the `docs/` folder (reference material for ongoing use), the `examples/`
folder (proof-of-concept case studies), the `methodology/aid-methodology.md`
specification (the load-bearing intellectual artifact), and the install scripts
(`setup.sh` / `setup.ps1`) plus the five profile install trees. These layers are
designed to serve different readers at different stages: a skeptic scanning the README,
a practitioner using the glossary, a potential adopter reading a case study, a deep
reader working through the methodology, and a first-time installer running the script.

Nothing on this surface describes internal pipeline machinery (that is `architecture.md`)
or module structure (that is `module-map.md`). This document maps the surface as a
reader experiences it.

---

## README.md (root)

Source: `README.md` (the root pitch document)

The README is the primary pitch document. It is structured as a progressive disclosure:
hook first, proof second, how-to last. Its table of contents (`README.md` `## Contents`) lists
the major sections:

| Section | Anchor | Purpose |
|---------|--------|---------|
| **What is AID?** | `README.md` `## What is AID?` | Core philosophy in three convictions; Iron Man collaboration image |
| **Why AID? — the failure modes it removes** | `README.md` `## Why AID? — the failure modes it removes` | Failure-mode table mapping failure modes to structural fixes (knowledge gaps, hallucination, drift, overengineering, etc.) |
| **The Pipeline** | `README.md` `## The Pipeline` | Mermaid flowchart + table of the 10 pipeline skills (one setup skill, six numbered phases, three optional skills — `aid-summarize` plus the two end-of-pipeline Deliver skills `aid-deploy`/`aid-monitor`), their groups, and outputs. ⚠️ This table covers the *pipeline* skills only — `aid-housekeep` (the 11th installed skill, optional/on-demand) is intentionally NOT in this table because it is not part of the linear pipeline flow. |
| **The Knowledge Base** | `README.md` `## The Knowledge Base — the gravitational center` | KB structure, 14-standard-document fixed shape, 3-tier context economy diagram |
| **The Agent Model** | `README.md` `## The Agent Model — three tiers` | Three-tier agent diagram (Large/Medium/Small), provider-agnostic tier table, skill→agent dispatch |
| **Feedback Loops** | `README.md` `## Feedback Loops` | 11 formal loops described; key loops called out (Any phase → Discovery, Execute → IMPEDIMENT, Monitor → Interview for both bugs and change requests) |
| **AID vs. SDD** | `README.md` `## AID vs. SDD` | Comparison table; framing quote |
| **Using AID in your own project** | `README.md` `## Using AID in your own project` | Install instructions (git clone + setup.sh/setup.ps1), slash command list, what gets installed, runtime requirements, incremental adoption |
| **Repository structure** | `README.md` `## Repository structure` | Directory tree + navigation table (where to go to read methodology, skills, agents, examples) |
| **Contributing / License** | `README.md` `## Contributing` / `## License` | Links to CONTRIBUTING.md, MIT license; closing tagline with blog link |

The README deliberately does not reproduce the full methodology — it links to
`methodology/aid-methodology.md` for depth. Its job is to orient a first-time reader
in under 20 minutes and give them one clear action: install and run `/aid-config`.

The footer (`README.md`, closing `*Read the full methodology:*` line) carries the external blog link:
`https://casuloailabs.com/blog/aid-methodology/`

### A note on skill counts (pipeline vs. total installed)

The README's `## The Pipeline` section frames AID as "**10 skills** — one setup skill,
six numbered development phases, three optional skills" (`README.md` `## The Pipeline`).
That "10 skills" count refers to the **pipeline-table skills** — the ones in
the Pipeline table and Mermaid flowchart (`aid-config`, the six numbered phases
`aid-discover`…`aid-execute`, plus the optional `aid-summarize`, `aid-deploy`, and
`aid-monitor`). `aid-deploy` and `aid-monitor` are optional, on-demand Deliver skills
positioned at the end of the pipeline — not required, numbered phases.

The repository actually ships **11 user-facing skills**: those 10 pipeline skills **plus**
`aid-housekeep` — an optional, on-demand maintenance skill that is deliberately absent from
the README Pipeline table because it is not part of the linear pipeline flow (see
`architecture.md` "Skill inventory" + `canonical/skills/aid-housekeep/SKILL.md`,
"Absent from the mandatory pipeline flow."). A 12th skill, `aid-generate`, is
maintainer-only and never installed for end users (it lives only in `.claude/skills/`,
not in `canonical/` — see `architecture.md`). So: **10 pipeline + 1 optional on-demand
(`aid-housekeep`) = 11 user-facing installed skills; +1 maintainer-only = 12 total.**

⚠️ The README's "10 skills" phrasing is therefore correct *as a description of the
pipeline*, but the total count of installed skills a user receives is 11. Keep these
two counts distinct when reconciling.

---

## docs/

Source: `docs/faq.md`, `docs/glossary.md`

The `docs/` folder contains two reference documents intended for ongoing use, not
initial orientation. Readers who have already installed AID and are working with
it are the primary audience.

### docs/faq.md

`docs/faq.md` — three sections (General, Adoption, Technical):

- **General** (`docs/faq.md` `## General`): What AID stands for, how it differs from SDD, whether
  all six numbered phases are required, and how to start a new project.
- **Adoption** (`docs/faq.md` `## Adoption`): Compatible AI tools (Claude Code, Codex CLI, Cursor,
  Copilot, Windsurf, Aider, custom agents), how to load skills as system context, team
  use, and adoption timeline.
- **Technical** (`docs/faq.md` `## Technical`): What the Knowledge Base is, what feedback loops are,
  what the Grade A gate means (including a note that the "five checks" are specific to
  the data-pipeline case study, not universal), and how to handle the "spec was wrong"
  problem via IMPEDIMENT.md.

The FAQ references `README.md#aid-vs-sdd` (`docs/faq.md` `[comparison table]`) and
`methodology/aid-methodology.md#4-feedback-loops` (`docs/faq.md` `[methodology document]`)
for deeper reading.

### docs/glossary.md

`docs/glossary.md` — six sections (Core Concepts, Setup, Phases,
Artifacts, Groups, Related Terms):

- **Core Concepts** (`docs/glossary.md` `## Core Concepts`): AID, Knowledge Base, Feedback Loop, Phase Gate,
  Iron Man Model.
- **Setup** (`docs/glossary.md` `## Setup`): `aid-config` bootstrapping step.
- **Phases** (`docs/glossary.md` `## Phases`): The six numbered phases plus the two optional
  Deliver skills (Deploy, Monitor) in a table with group membership and primary output artifact.
- **Artifacts** (`docs/glossary.md` `## Artifacts`): SPEC.md, Q&A entry, IMPEDIMENT.md,
  MONITOR-STATE.md, Grading (A+ to F).
- **Groups** (`docs/glossary.md` `## Groups`): All 5 groups with phases and focus.
- **Related Terms** (`docs/glossary.md` `## Related Terms`): SDD, Brownfield, Greenfield, Determinism Test.

The glossary is the canonical term-definition authority for the repo. When a term is
used in the methodology or skills, its definition lives here.

---

## examples/

Source: `examples/README.md`, plus per-case-study READMEs.

The `examples/` directory contains three anonymized real-world case studies. The
index (`examples/README.md`) introduces all three with a one-paragraph summary and
key takeaway per case. Detailed files live within each case study subdirectory.

### examples/brownfield-enterprise/

`examples/brownfield-enterprise/README.md`

- **Scenario:** A 21GB Java/OSGi enterprise monorepo with ~200 OSGi plugin bundles,
  Eclipse Tycho/Maven build, Hibernate + Elasticsearch, React (Aura) frontend, no
  documentation, no architect available. (`examples/brownfield-enterprise/README.md` `## Context`)
- **Goal:** Understand the system well enough to review PRs and implement features
  within days, not weeks.
- **Phases applied:** Discovery (4-hour AI session vs. estimated 2-3 weeks manual),
  Interview (gap-filling via targeted questions), Execute + Review (14 PR issues
  across 18 files, fixed in one session). (`examples/brownfield-enterprise/README.md` `## AID Phases Applied`)
- **KB documents produced:** 9 documents, ranging from Complete to Partial.
  (`examples/brownfield-enterprise/README.md` `**KB Documents Produced:**`)
- **Supporting files:** `discovery-report.md` (architecture analysis) and
  `knowledge-base/architecture.md` (sample KB document).
- **Key takeaway:** Discovery pays for itself immediately; partial KB documents
  are acceptable when gaps are marked.

### examples/data-pipeline/

`examples/data-pipeline/README.md`

- **Scenario:** Multi-brand e-commerce analytics pipeline — 3 brands, 5 data sources
  (Shopify, Meta Ads, Google Ads, Klaviyo, GA4), 12 specialist AI agents,
  automated weekly reports delivered as HTML email.
  (`examples/data-pipeline/README.md` `## Context`)
- **Goal:** Automated weekly performance reports validated against source data at 1%
  tolerance.
- **Phases applied:** Full lifecycle including the Monitor→Interview bug-fix path.
  A 6-phase pipeline (Pull → Validate → Preprocess → Charts → Agents → Orchestrate)
  with a Grade A quality gate per report.
- **Bug-fix in action:** Timezone mismatch (UTC vs. Australia/Sydney) + wrong Klaviyo
  metric + stale cache — three root-cause issues identified and fixed via
  Track→Triage→Implement. (`examples/data-pipeline/README.md` `### Track→Triage→Implement in Action`)
- **Supporting files:** `pipeline-architecture.md` (detailed pipeline flow).
- **Key takeaway:** Grade A validation catches LLM hallucination in numeric outputs;
  formal triage identifies multiple concurrent root causes instead of treating them
  as one vague bug.

  ⚠️ The FAQ (`docs/faq.md` `### What's the Grade A gate?`) notes that the "five checks"
  (SOURCE_MATCH, TRACEABILITY, CONSISTENCY, COMPLETENESS, NO_ZEROS) are specific to this
  case study and are not universal AID quality gates. The methodology's Grade A gate is
  defined per project in SPEC.md.

### examples/desktop-app/

`examples/desktop-app/README.md`

- **Scenario:** Windows desktop transcription app using .NET 10/C#/Avalonia UI/MVVM,
  Whisper (local speech-to-text), Phi-3 (AI correction), sherpa-onnx (diarization),
  SQLite. (`examples/desktop-app/README.md` `## Context`)
- **Goal:** Ship incremental deliveries, each self-contained and fully tested.
- **Phases applied:** Plan→Detail→Implement→Review→Test→Deploy cycle repeated across
  5 deliveries (2a–2e), growing from 0 to 1,184 tests.
  (`examples/desktop-app/README.md` `### Delivery Structure`)
- **Three-tier E2E testing:** Mock (CI-safe, ~80 tests), Integration (real data
  services, ~67 tests), Full (requires hardware). (`examples/desktop-app/README.md` `### Quality Gates`)
- **Supporting files:** `delivery-plan.md` (Delivery 2d example),
  `task-spec.md` (File Import feature task spec).
- **Key takeaway:** Task specs are the real unit of work; three-tier testing catches
  integration bugs that mock tests miss (SQLite `OrderBy(TimeSpan)` incompatibility).

  ⚠️ The delivery numbers start at "2a" in the example, suggesting Delivery 1 existed
  but is not included in the example artifacts. Inferred from the README context.

---

## methodology/aid-methodology.md

Source: `methodology/aid-methodology.md` (full document is 1,070 lines per
`project-structure.md` `| `methodology/aid-methodology.md` |`)

The methodology specification is the load-bearing intellectual artifact of the repo.
Every skill, agent, and template is derived from it. It is the authoritative definition
of how AID works.

**Version:** 3.1 — May 2026 (`methodology/aid-methodology.md` `*Version 3.1 — May 2026*`)

**Structure:** Nine sections (`methodology/aid-methodology.md` `## Table of Contents`):

| # | Section | Scope |
|---|---------|-------|
| 1 | Philosophy | Waterfall rehabilitation, Human-in-the-Middle, three core principles, failure modes table, roles (Director/Orchestrator/Specialist) |
| 2 | The Knowledge Base | KB structure (14 standard + 3 meta + 1 generated), completeness tracking, context feeding strategy (3-tier economy), INDEX.md mechanism |
| 3 | The Phases | The six numbered phases (plus the two optional Deliver skills) defined in detail with inputs, outputs, agent assignments |
| 4 | Feedback Loops | 11 formal loops enumerated with trigger conditions and artifacts produced |
| 5 | Artifacts Reference | Every artifact defined: SPEC.md, STATE files, IMPEDIMENT.md, MONITOR-STATE.md, grading rubric |
| 6 | The Pipeline | End-to-end pipeline with state machine per skill |
| 7 | Case Studies | Summarized versions of the three examples/ case studies |
| 8 | Comparison with SDD | Detailed comparison table (expands on README's AID vs. SDD table) |
| 9 | Adoption Guide | Incremental adoption, team use, common entry points |

The methodology document is explicitly flagged as a ~40-minute read in the README's
repository structure section (`README.md` `## Repository structure`). Two supporting images live alongside
it in `methodology/images/`: `2-comparison.png` (SDD vs. AID comparison diagram) and
`3-ironman.png` (Human-AI collaboration model, referenced inline at
`README.md` `![Human-AI collaboration model](methodology/images/3-ironman.png)`).

The methodology document is not regenerated by the build system — it is hand-authored
and lives at a fixed path. It is the upstream source that informs all generated
artifacts but is not itself produced by any generator.

---

## External References

The README footer (`README.md`, closing `*Read the full methodology:*` line) links to a blog post:

> `https://casuloailabs.com/blog/aid-methodology/`

This is the only external URL cited in the README. The blog is hosted at
`casuloailabs.com`, which is the author's lab/consulting domain. The post is titled
"AID — the complete picture" per the README link text.

No other external links are cited in the README. The FAQ and glossary contain only
internal cross-references (to `README.md` sections and `methodology/aid-methodology.md`).

⚠️ The blog post content has not been verified against the current repo state (as of
this KB document authoring). The URL is confirmed from `README.md` (closing
`*Read the full methodology:*` line); content
accuracy relative to the v3.1 methodology spec is not verified here.

---

## Cross-Tool Installation Surface

Source: `README.md` `## Using AID in your own project`, `setup.sh`,
`project-structure.md` `├── profiles/`

### Install Scripts

Users install AID into their own projects via two cross-platform scripts at the repo root:

| Script | Platform | Lines | Behavior |
|--------|----------|-------|----------|
| `setup.sh` | Bash (Linux/macOS/git-bash) | 210 | Interactive menu: select Claude Code (1), Codex (2), Cursor (3), GitHub Copilot CLI (4), Antigravity (5), Done (6); installs selected profiles into target directory (`setup.sh` `tool_name()`, `print_menu()`) |
| `setup.ps1` | PowerShell 5.1+ (Windows) | 199 | Same 5-tool menu and behavior in PowerShell |

Both scripts accept `<target-directory>` as a positional argument and an optional
`--force` flag to overwrite without prompts (`README.md` `**Re-running is safe:**`).
Re-running is safe: identical files are skipped; changed files prompt before overwriting.

Manual installation is also documented: copy the relevant profile directory directly
into the project root (`README.md` `Prefer to install by hand?`).

### Profile Install Trees

Five tool-specific install bundles live in `profiles/` (`ls profiles/*.toml | wc -l` = 5):

| Profile | Install root | What users see |
|---------|-------------|----------------|
| **Claude Code** | `profiles/claude-code/` | `.claude/` directory containing `skills/`, `agents/`, `templates/`, `recipes/`, `scripts/`; plus `CLAUDE.md` at project root |
| **Codex CLI** | `profiles/codex/` | Split layout: `.codex/agents/` (TOML agent definitions) + `.agents/` (skills, scripts, recipes, templates); plus `AGENTS.md` at project root |
| **Cursor** | `profiles/cursor/` | `.cursor/` directory with `.mdc` rule files; plus `AGENTS.md` at project root |
| **GitHub Copilot CLI** | `profiles/copilot-cli/` | `.github/` directory (`output_root` `.github`) with `agents/*.agent.md` (copilot-agent format), `skills/`, `scripts/`, `recipes/`, `templates/`; plus `AGENTS.md` at project root |
| **Antigravity** | `profiles/antigravity/` | `.agent/` directory (`output_root` `.agent`) with sub-agents reshaped into `rules/*.md` (antigravity-rule format, `trigger:`-style frontmatter), plus `skills/`, `scripts/`, `recipes/`, `templates/`; plus `AGENTS.md` at project root |

(`project-structure.md` `├── profiles/`, `README.md` `### 3. What gets installed`)

All five profiles contain byte-identical skill and agent bodies — only the wrapper
format differs per tool (markdown for Claude Code, TOML for Codex agents, `.mdc` for
Cursor rules, `.agent.md` copilot-agent frontmatter for Copilot CLI, and
`antigravity-rule` `trigger:`-style rule frontmatter for Antigravity; the four
agent-format values are listed in `aid_profile.py` `_KNOWN_AGENT_FORMATS`). The
generator (`run_generator.py`) enforces this byte-identity via VERIFY (deterministic)
at end of every render (see `architecture.md` `verify_deterministic.py` for the gate).

### What End Users See After Install

After running `setup.sh` or `setup.ps1`, the target project gains:

- The tool-appropriate hidden directory (`.claude/`, `.codex/`+`.agents/`, `.cursor/`,
  `.github/` for Copilot CLI, or `.agent/` for Antigravity)
  containing all 11 user-facing skills (the 10 pipeline-table skills + the optional
  on-demand `aid-housekeep`), 22 agents, 5 recipes, templates, and helper scripts.
  (The maintainer-only `aid-generate` skill is never installed — it lives only in the
  source repo's `.claude/skills/`, not in `canonical/`; see `architecture.md`.)
- ⚠️ **AGENTS.md collision (Option A):** Codex, Cursor, Copilot CLI, and Antigravity all
  write a root `AGENTS.md`. When ≥2 of these are selected, `setup.sh`/`setup.ps1` warn
  once and the highest-numbered selected writer wins — no interactive prompt
  (`setup.sh` `AGENTS.md collision pre-copy block (Option A)`).
- A `CLAUDE.md` or `AGENTS.md` at the project root with placeholders that
  `/aid-config` and `/aid-discover` populate. (`README.md` `### 3. What gets installed`)
- `.aid/` appended to the project's `.gitignore` — the Knowledge Base stays out of
  git by default; users remove the entry to commit it.
  (`README.md` ``.aid/` appended to your project's `.gitignore``)

### Runtime Requirements

(`README.md` `### Runtime requirements`)

- One or more host AI tools: Claude Code, OpenAI Codex CLI, Cursor, GitHub Copilot CLI, or Antigravity.
- Bash (or git-bash on Windows) for scripts; PowerShell 5.1+ for `setup.ps1`.
- Git.
- Node 18+ is optional — only `/aid-summarize` uses it for diagram validation.
  No `package.json` is present in the repo; users install Mermaid CLI ad-hoc
  when they use `aid-summarize`.
