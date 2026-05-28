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
(`setup.sh` / `setup.ps1`) plus the three profile install trees. These layers are
designed to serve different readers at different stages: a skeptic scanning the README,
a practitioner using the glossary, a potential adopter reading a case study, a deep
reader working through the methodology, and a first-time installer running the script.

Nothing on this surface describes internal pipeline machinery (that is `architecture.md`)
or module structure (that is `module-map.md`). This document maps the surface as a
reader experiences it.

---

## README.md (root)

Source: `README.md:1-374` (374 lines)

The README is the primary pitch document. It is structured as a progressive disclosure:
hook first, proof second, how-to last. Its table of contents (`README.md:9-19`) lists
eight sections:

| Section | Location | Purpose |
|---------|----------|---------|
| **What is AID?** | `README.md:23-38` | Core philosophy in three convictions; Iron Man collaboration image |
| **Why AID? — the failure modes it removes** | `README.md:41-54` | Six-row table mapping failure modes to structural fixes (hallucination, drift, overengineering, etc.) |
| **The Pipeline** | `README.md:59-108` | Mermaid flowchart + table of all 10 skills, groups, and outputs |
| **The Knowledge Base** | `README.md:112-171` | KB structure, 14-document fixed shape, 3-tier context economy diagram |
| **The Agent Model** | `README.md:175-237` | Three-tier agent diagram (Large/Medium/Small), provider-agnostic tier table, skill→agent dispatch |
| **Feedback Loops** | `README.md:241-253` | 11 formal loops described; key loops called out (Any phase → Discovery, Execute → IMPEDIMENT, Monitor → Execute, Monitor → Discover) |
| **AID vs. SDD** | `README.md:256-271` | Eight-row comparison table; framing quote |
| **Using AID in your own project** | `README.md:275-336` | Install instructions (git clone + setup.sh/setup.ps1), slash command list, what gets installed, runtime requirements, incremental adoption |
| **Repository structure** | `README.md:340-370` | Directory tree + navigation table (where to go to read methodology, skills, agents, examples) |
| **Contributing / License** | `README.md:362-374` | Links to CONTRIBUTING.md, MIT license; closing tagline with blog link |

The README deliberately does not reproduce the full methodology — it links to
`methodology/aid-methodology.md` for depth. Its job is to orient a first-time reader
in under 20 minutes and give them one clear action: install and run `/aid-config`.

The footer (`README.md:374`) carries the external blog link:
`https://casuloailabs.com/blog/aid-methodology/`

---

## docs/

Source: `docs/faq.md` (61 lines), `docs/glossary.md` (76 lines)

The `docs/` folder contains two reference documents intended for ongoing use, not
initial orientation. Readers who have already installed AID and are working with
it are the primary audience.

### docs/faq.md

`docs/faq.md:1-61` — 61 lines, three sections (General, Adoption, Technical):

- **General** (`faq.md:3-21`): What AID stands for, how it differs from SDD, whether
  all 8 phases are required, and how to start a new project.
- **Adoption** (`faq.md:25-39`): Compatible AI tools (Claude Code, Codex CLI, Cursor,
  Copilot, Windsurf, Aider, custom agents), how to load skills as system context, team
  use, and adoption timeline.
- **Technical** (`faq.md:41-61`): What the Knowledge Base is, what feedback loops are,
  what the Grade A gate means (including a note that the "five checks" are specific to
  the data-pipeline case study, not universal), and how to handle the "spec was wrong"
  problem via IMPEDIMENT.md.

The FAQ references `README.md#aid-vs-sdd` and `methodology/aid-methodology.md#4-feedback-loops`
for deeper reading (`faq.md:9`, `faq.md:47`).

### docs/glossary.md

`docs/glossary.md:1-77` — 76 lines, four sections (Core Concepts, Setup, Phases,
Artifacts, Groups, Related Terms):

- **Core Concepts** (`glossary.md:7-18`): AID, Knowledge Base, Feedback Loop, Phase Gate,
  Iron Man Model.
- **Setup** (`glossary.md:20-23`): `aid-config` bootstrapping step.
- **Phases** (`glossary.md:25-37`): All 8 phases in a table with group membership and
  primary output artifact.
- **Artifacts** (`glossary.md:41-52`): SPEC.md, Q&A entry, IMPEDIMENT.md,
  MONITOR-STATE.md, Grading (A+ to F).
- **Groups** (`glossary.md:54-65`): All 5 groups with phases and focus.
- **Related Terms** (`glossary.md:67-77`): SDD, Brownfield, Greenfield, Determinism Test.

The glossary is the canonical term-definition authority for the repo. When a term is
used in the methodology or skills, its definition lives here.

---

## examples/

Source: `examples/README.md:1-28`, plus per-case-study READMEs.

The `examples/` directory contains three anonymized real-world case studies. The
index (`examples/README.md`) introduces all three with a one-paragraph summary and
key takeaway per case. Detailed files live within each case study subdirectory.

### examples/brownfield-enterprise/

`examples/brownfield-enterprise/README.md:1-61`

- **Scenario:** A 21GB Java/OSGi enterprise monorepo with ~200 OSGi plugin bundles,
  Eclipse Tycho/Maven build, Hibernate + Elasticsearch, React (Aura) frontend, no
  documentation, no architect available. (`brownfield-enterprise/README.md:5-13`)
- **Goal:** Understand the system well enough to review PRs and implement features
  within days, not weeks.
- **Phases applied:** Discovery (4-hour AI session vs. estimated 2-3 weeks manual),
  Interview (gap-filling via targeted questions), Execute + Review (14 PR issues
  across 18 files, fixed in one session). (`brownfield-enterprise/README.md:17-49`)
- **KB documents produced:** 9 documents, ranging from Complete to Partial.
  (`brownfield-enterprise/README.md:26-35`)
- **Supporting files:** `discovery-report.md` (architecture analysis) and
  `knowledge-base/architecture.md` (sample KB document).
- **Key takeaway:** Discovery pays for itself immediately; partial KB documents
  are acceptable when gaps are marked.

### examples/data-pipeline/

`examples/data-pipeline/README.md:1-79`

- **Scenario:** Multi-brand e-commerce analytics pipeline — 3 brands, 5 data sources
  (Shopify, Meta Ads, Google Ads, Klaviyo, GA4), 12 specialist AI agents,
  automated weekly reports delivered as HTML email.
  (`data-pipeline/README.md:5-12`)
- **Goal:** Automated weekly performance reports validated against source data at 1%
  tolerance.
- **Phases applied:** Full lifecycle including Monitor→Execute bug-fix path.
  A 6-phase pipeline (Pull → Validate → Preprocess → Charts → Agents → Orchestrate)
  with a Grade A quality gate per report.
- **Bug-fix in action:** Timezone mismatch (UTC vs. Australia/Sydney) + wrong Klaviyo
  metric + stale cache — three root-cause issues identified and fixed via
  Track→Triage→Implement. (`data-pipeline/README.md:54-67`)
- **Supporting files:** `pipeline-architecture.md` (detailed pipeline flow).
- **Key takeaway:** Grade A validation catches LLM hallucination in numeric outputs;
  formal triage identifies multiple concurrent root causes instead of treating them
  as one vague bug.

  ⚠️ The FAQ (`faq.md:52`) notes that the "five checks" (SOURCE_MATCH, TRACEABILITY,
  CONSISTENCY, COMPLETENESS, NO_ZEROS) are specific to this case study and are not
  universal AID quality gates. The methodology's Grade A gate is defined per project
  in SPEC.md.

### examples/desktop-app/

`examples/desktop-app/README.md:1-57`

- **Scenario:** Windows desktop transcription app using .NET 10/C#/Avalonia UI/MVVM,
  Whisper (local speech-to-text), Phi-3 (AI correction), sherpa-onnx (diarization),
  SQLite. (`desktop-app/README.md:5-12`)
- **Goal:** Ship incremental deliveries, each self-contained and fully tested.
- **Phases applied:** Plan→Detail→Implement→Review→Test→Deploy cycle repeated across
  5 deliveries (2a–2e), growing from 0 to 1,184 tests.
  (`desktop-app/README.md:22-27`)
- **Three-tier E2E testing:** Mock (CI-safe, ~80 tests), Integration (real data
  services, ~67 tests), Full (requires hardware). (`desktop-app/README.md:43-46`)
- **Supporting files:** `delivery-plan.md` (Delivery 2d example),
  `task-spec.md` (File Import feature task spec).
- **Key takeaway:** Task specs are the real unit of work; three-tier testing catches
  integration bugs that mock tests miss (SQLite `OrderBy(TimeSpan)` incompatibility).

  ⚠️ The delivery numbers start at "2a" in the example, suggesting Delivery 1 existed
  but is not included in the example artifacts. Inferred from the README context.

---

## methodology/aid-methodology.md

Source: `methodology/aid-methodology.md:1-200` (first 200 lines read; full document
is 1,071 lines per `project-structure.md:57`)

The methodology specification is the load-bearing intellectual artifact of the repo.
Every skill, agent, and template is derived from it. It is the authoritative definition
of how AID works.

**Version:** 3.1 — May 2026 (`methodology/aid-methodology.md:4`)

**Structure:** Nine sections (`methodology/aid-methodology.md:36-46`):

| # | Section | Scope |
|---|---------|-------|
| 1 | Philosophy | Waterfall rehabilitation, Human-in-the-Middle, three core principles, failure modes table, roles (Director/Orchestrator/Specialist) |
| 2 | The Knowledge Base | KB structure (14 standard + 3 meta + 1 generated), completeness tracking, context feeding strategy (3-tier economy), INDEX.md mechanism |
| 3 | The Phases | All 8 phases defined in detail with inputs, outputs, agent assignments |
| 4 | Feedback Loops | 11 formal loops enumerated with trigger conditions and artifacts produced |
| 5 | Artifacts Reference | Every artifact defined: SPEC.md, STATE files, IMPEDIMENT.md, MONITOR-STATE.md, grading rubric |
| 6 | The Pipeline | End-to-end pipeline with state machine per skill |
| 7 | Case Studies | Summarized versions of the three examples/ case studies |
| 8 | Comparison with SDD | Detailed comparison table (expands on README's AID vs. SDD table) |
| 9 | Adoption Guide | Incremental adoption, team use, common entry points |

The methodology document is explicitly flagged as a ~40-minute read in the README's
repository structure section (`README.md:344`). Two supporting images live alongside
it in `methodology/images/`: `2-comparison.png` (SDD vs. AID comparison diagram) and
`3-ironman.png` (Human-AI collaboration model, referenced inline at `README.md:35`).

The methodology document is not regenerated by the build system — it is hand-authored
and lives at a fixed path. It is the upstream source that informs all generated
artifacts but is not itself produced by any generator.

---

## External References

The README footer (`README.md:374`) links to a blog post:

> `https://casuloailabs.com/blog/aid-methodology/`

This is the only external URL cited in the README. The blog is hosted at
`casuloailabs.com`, which is the author's lab/consulting domain. The post is titled
"AID — the complete picture" per the README link text.

No other external links are cited in the README. The FAQ and glossary contain only
internal cross-references (to `README.md` sections and `methodology/aid-methodology.md`).

⚠️ The blog post content has not been verified against the current repo state (as of
this KB document authoring). The URL is confirmed from `README.md:374`; content
accuracy relative to the v3.1 methodology spec is not verified here.

---

## Cross-Tool Installation Surface

Source: `README.md:279-336`, `setup.sh:1-60`, `project-structure.md:49-56`

### Install Scripts

Users install AID into their own projects via two cross-platform scripts at the repo root:

| Script | Platform | Lines | Behavior |
|--------|----------|-------|----------|
| `setup.sh` | Bash (Linux/macOS/git-bash) | 162 | Interactive menu: select Claude Code, Codex, Cursor; installs selected profiles into target directory |
| `setup.ps1` | PowerShell 5.1+ (Windows) | 157 | Same menu and behavior in PowerShell |

Both scripts accept `<target-directory>` as a positional argument and an optional
`--force` flag to overwrite without prompts (`README.md:290-293`). Re-running is safe:
identical files are skipped; changed files prompt before overwriting.

Manual installation is also documented: copy the relevant profile directory directly
into the project root (`README.md:294-296`).

### Profile Install Trees

Three tool-specific install bundles live in `profiles/`:

| Profile | Install root | What users see |
|---------|-------------|----------------|
| **Claude Code** | `profiles/claude-code/` | `.claude/` directory containing `skills/`, `agents/`, `templates/`, `recipes/`, `scripts/`; plus `CLAUDE.md` at project root |
| **Codex CLI** | `profiles/codex/` | Split layout: `.codex/agents/` (TOML agent definitions) + `.agents/` (skills, scripts, recipes, templates); plus `AGENTS.md` at project root |
| **Cursor** | `profiles/cursor/` | `.cursor/` directory with `.mdc` rule files; plus `AGENTS.md` at project root |

(`project-structure.md:49-56`, `README.md:318-320`)

All three profiles contain byte-identical skill and agent bodies — only the wrapper
format differs per tool (TOML for Codex agents, `.mdc` for Cursor rules, markdown for
Claude Code). The generator (`run_generator.py`) enforces this byte-identity
via VERIFY-4a at end of every render (see `architecture.md` byte-identity section).

### What End Users See After Install

After running `setup.sh` or `setup.ps1`, the target project gains:

- The tool-appropriate hidden directory (`.claude/`, `.codex/`+`.agents/`, or `.cursor/`)
  containing all 10 skills, 22 agents, 5 recipes, templates, and helper scripts.
- A `CLAUDE.md` or `AGENTS.md` at the project root with placeholders that
  `/aid-config` and `/aid-discover` populate. (`README.md:318-320`)
- `.aid/` appended to the project's `.gitignore` — the Knowledge Base stays out of
  git by default; users remove the entry to commit it. (`README.md:321`)

### Runtime Requirements

(`README.md:322-326`)

- One or more host AI tools: Claude Code, OpenAI Codex CLI, or Cursor.
- Bash (or git-bash on Windows) for scripts; PowerShell 5.1+ for `setup.ps1`.
- Git.
- Node 18+ is optional — only `/aid-summarize` uses it for diagram validation.
  No `package.json` is present in the repo; users install Mermaid CLI ad-hoc
  when they use `aid-summarize`.
