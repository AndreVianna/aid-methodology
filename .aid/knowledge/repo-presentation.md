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
  - 2026-06-05: work-002-auto-installer — README was rewritten lean; reconciled the README section map to the current headings (Install / Quick Start / Why AID / How It Works / Documentation); replaced the `setup.sh`/`setup.ps1` install-script surface with the `aid` CLI + four install channels (curl/irm bootstrap, npm, PyPI, offline); documented the `methodology/` → `docs/` move + the expanded `docs/` taxonomy (aid-methodology.md, repository-structure.md, install.md, release.md, faq.md, glossary.md); methodology spec refreshed to v3.2; `2-comparison.png` removed (only `3-ironman.png` remains).
  - 2026-06-03: methodology v3.2 — README pipeline framing reconciled: numbered development phases 8 → 6; aid-deploy/aid-monitor recast from numbered phases 7/8 to optional end-of-pipeline Deliver skills; "10 skills" breakdown is now one setup + six numbered phases + three optional skills (summarize, deploy, monitor); Monitor feedback loops re-pointed to Interview (bugs + CRs).
---

# Repo Presentation

## Overview

The AID GitHub repository is itself a documentation product. It ships no application
code — it ships methodology, skills, agents, templates, and an installer. Every
file a user sees when they clone the repo is part of the methodology's user-facing
surface, and the quality of that surface determines whether a user understands what
AID is and how to adopt it.

The user-facing surface has five layers: the root `README.md` (the lean pitch and entry
point), the `docs/` folder (reference material for ongoing use — methodology, install,
release, FAQ, glossary, repo map), the `examples/` folder (proof-of-concept case studies),
the `docs/aid-methodology.md` specification (the load-bearing intellectual artifact), and
the install surface — the persistent global `aid` CLI delivered over four channels
(curl/irm bootstrap, npm, PyPI, offline) plus the five profile install trees. These layers
are designed to serve different readers at different stages: a skeptic scanning the README,
a practitioner using the glossary, a potential adopter reading a case study, a deep reader
working through the methodology, and a first-time installer running `curl … | bash` then `aid add`.

Nothing on this surface describes internal pipeline machinery (that is `architecture.md`)
or module structure (that is `module-map.md`). This document maps the surface as a
reader experiences it.

---

## README.md (root)

Source: `README.md` (the root pitch document)

The README was rewritten lean by work-002. It now leads with the install action, then
the value pitch, then how-it-works, then a documentation index that links into `docs/`.
Its major sections (`README.md` headings):

| Section | Anchor | Purpose |
|---------|--------|---------|
| **Install** | `README.md` `## Install` | The primary call-to-action, surfaced first. Four channels: curl/irm bootstrap (`### Bootstrap the `aid` CLI`), npm, PyPI, and offline/air-gapped bundle install; then `### Use it` (the `aid add`/`status`/`update`/`remove` subcommand cheat-sheet) + a protect-on-diff note. Links to `docs/install.md`. |
| **Quick Start** | `README.md` `## Quick Start` | Minimal end-to-end first run after install |
| **Why AID** | `README.md` `## Why AID` | The value pitch / failure modes AID removes |
| **How It Works** | `README.md` `## How It Works` | `### The Pipeline` (the skills + flow), `### The Lite Path`, `### The Knowledge Base`, `### The Agent Model` |
| **Documentation** | `README.md` `## Documentation` | An index table linking the `docs/` set (aid-methodology.md, install.md, repository-structure.md, release.md, faq.md, glossary.md) + `examples/` |
| **Contributing / License** | `README.md` `## Contributing` / `## License` | Links to CONTRIBUTING.md, MIT license; closing tagline with blog link |

The README deliberately does not reproduce the full methodology — it links to
`docs/aid-methodology.md` for depth. Its job is to get a first-time reader installed
quickly (`curl … | bash`, then `aid add claude-code`) and oriented in one sitting.

The footer (`README.md`, closing `*Full methodology:*` line) carries the external blog link:
`https://casuloailabs.com/blog/aid-methodology/`

### A note on skill counts (pipeline vs. total installed)

The README's `### The Pipeline` section (under `## How It Works`) frames the pipeline as
"**Six numbered development phases** … Deploy and Monitor are optional. `aid-housekeep`
runs off the pipeline on demand" (`README.md` `### The Pipeline`). The numbered
sequential path is therefore six phases (`aid-discover`…`aid-execute`); `aid-config` is the
once-per-project setup skill; `aid-summarize`, `aid-deploy`, and `aid-monitor` are optional.

The repository actually ships **11 user-facing skills**: `aid-config` + the six numbered
phases + the three optional skills (`aid-summarize`/`aid-deploy`/`aid-monitor`) + the
off-pipeline `aid-housekeep` (an optional, on-demand maintenance skill — see
`architecture.md` "Skill inventory" + `canonical/skills/aid-housekeep/SKILL.md`,
"Absent from the mandatory pipeline flow."). A 12th skill, `aid-generate`, is
maintainer-only and never installed for end users (it lives only in `.claude/skills/`,
not in `canonical/` — see `architecture.md`). So: **1 setup + 6 numbered + 3 optional + 1
off-pipeline (`aid-housekeep`) = 11 user-facing installed skills; +1 maintainer-only = 12 total.**

⚠️ The README frames the *pipeline* as six numbered phases, but the total count of
installed skills a user receives is 11. Keep these
two counts distinct when reconciling.

---

## docs/

Source: `docs/aid-methodology.md`, `docs/install.md`, `docs/repository-structure.md`, `docs/release.md`, `docs/faq.md`, `docs/glossary.md`

The `docs/` folder is the repo's reference library — six documents intended for ongoing
use rather than initial orientation. work-002 moved the methodology spec here from the
former `methodology/` directory (now `docs/aid-methodology.md`) and added the install,
repository-structure, and release docs:

| Document | Audience | Purpose |
|----------|----------|---------|
| `docs/aid-methodology.md` | Deep reader | The complete methodology spec — the load-bearing artifact (see its own section below) |
| `docs/install.md` | Adopter | Full install/update/remove guide: the four channels, offline bundles, version pinning, protect-on-diff, per-channel `aid update self`, the checksum trust model |
| `docs/repository-structure.md` | Contributor | Contributor-oriented map of the repo layout (`bin/`, `lib/`, `packages/`, `canonical/`, `profiles/`, …) |
| `docs/release.md` | Maintainer | Release runbook — tag-triggered CI (`release.yml`) primary path; manual `release.sh` fallback |
| `docs/faq.md` | Adopter | How-to questions (General / Adoption / Technical) |
| `docs/glossary.md` | All | Canonical term definitions |

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
`docs/aid-methodology.md#6-feedback-loops` (`docs/faq.md` `[methodology document]`)
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

## docs/aid-methodology.md

Source: `docs/aid-methodology.md` (moved here from `methodology/` by work-002)

The methodology specification is the load-bearing intellectual artifact of the repo.
Every skill, agent, and template is derived from it. It is the authoritative definition
of how AID works.

**Version:** 3.2 — June 2026 (`docs/aid-methodology.md` `*Version 3.2 — June 2026*`)

**Structure:** Ten sections (`docs/aid-methodology.md` `## Table of Contents`):

| # | Section | Scope |
|---|---------|-------|
| 1 | The Pipeline | The end-to-end pipeline, surfaced first — phases, gates, flow |
| 2 | Philosophy | Waterfall rehabilitation, Human-in-the-Middle, three core principles, failure modes, roles (Director/Orchestrator/Specialist) |
| 3 | The Knowledge Base | KB structure, completeness tracking, context feeding strategy (3-tier economy), INDEX.md mechanism |
| 4 | The Phases | The six numbered phases (plus the optional Deliver skills) defined with inputs, outputs, agent assignments |
| 5 | The Agent Model | The 9-agent three-tier model + reviewer >= executor invariant |
| 6 | Feedback Loops | 11 formal loops enumerated with trigger conditions and artifacts produced |
| 7 | Artifacts Reference | Every artifact defined: SPEC.md, STATE files, IMPEDIMENT.md, MONITOR-STATE.md, grading rubric |
| 8 | Case Studies | Summarized versions of the three examples/ case studies |
| 9 | Comparison with SDD | Detailed comparison table (expands on README's AID vs. SDD framing) |
| 10 | Adoption Guide | Incremental adoption, team use, common entry points |

The methodology document is flagged as a ~40-minute read in the README's Documentation
index (`README.md` `## Documentation`, the `docs/aid-methodology.md` row). One supporting
image lives alongside it in `docs/images/`: `3-ironman.png` (the Iron Man / Human-AI
collaboration model), referenced inline at `docs/aid-methodology.md`
`![…](images/3-ironman.png)`. (The former `2-comparison.png` was removed by work-002.)

The methodology document is not regenerated by the build system — it is hand-authored
and lives at a fixed path. It is the upstream source that informs all generated
artifacts but is not itself produced by any generator.

---

## External References

The README footer (`README.md`, closing `*Full methodology:*` line) links to a blog post:

> `https://casuloailabs.com/blog/aid-methodology/`

This is the only external (non-GitHub-registry) URL cited in the README prose. The blog is
hosted at `casuloailabs.com`, the author's lab/consulting domain. The post is titled
"AID — the complete picture" per the README link text.

The other external endpoints the README surfaces are the **install registries**: the
`raw.githubusercontent.com` bootstrap URLs (`install.sh` / `install.ps1`), the `npm` and
`pipx`/`pip` package commands (`aid-installer`), and the GitHub Releases download URLs in the
offline-install example. The FAQ and glossary otherwise contain only internal
cross-references (to `README.md` sections and `docs/aid-methodology.md`).

⚠️ The blog post content has not been verified against the current repo state (as of
this KB document authoring). The URL is confirmed from `README.md` (closing
`*Full methodology:*` line); content accuracy relative to the v3.2 methodology spec is not
verified here.

---

## Cross-Tool Installation Surface

Source: `README.md` `## Install`, `docs/install.md`, `bin/aid`,
`project-structure.md` `├── profiles/`

### The `aid` CLI + four install channels

Adopters no longer clone-and-run a script — work-002 replaced `setup.sh`/`setup.ps1` with a
persistent global `aid` CLI, installed once per machine then run per project with
`aid add <tool>`. The README leads with this (`README.md` `## Install`). All four channels
deliver the same CLI:

| Channel | First-install command (from `README.md` `## Install`) | Platform |
|---------|-------------------------------------------------------|----------|
| curl/irm bootstrap | `curl -fsSL …/install.sh \| bash` / `irm …/install.ps1 \| iex` | Linux/macOS / Windows |
| npm | `npm i -g aid-installer` (or `npx aid-installer add <tool>`) | any with Node >=18 |
| PyPI | `pipx install aid-installer` (or `pip install --user aid-installer`) | any with Python >=3.8 |
| Offline / air-gapped | download a release tarball, verify against `SHA256SUMS`, then `aid add <tool> --from-bundle <path>` | any |

After bootstrap, the per-project subcommands (`README.md` `### Use it`) are
`aid add <tool>[,...]`, `aid status`, `aid update [self]`, `aid remove [tool | self]`. Re-running
`aid add` is safe: identical files are skipped, and a user-authored root `CLAUDE.md`/`AGENTS.md`
is written as `*.aid-new` for review rather than overwritten (FR11 protect-on-diff, surfaced in
`README.md` after the `### Use it` block). The full channel comparison + offline + version-pinning
guide lives in `docs/install.md`.

### Profile Install Trees

Five tool-specific install bundles live in `profiles/` (`ls profiles/*.toml | wc -l` = 5):

| Profile | Install root | What users see |
|---------|-------------|----------------|
| **Claude Code** | `profiles/claude-code/` | `.claude/` directory containing `skills/`, `agents/`, `templates/`, `recipes/`, `scripts/`; plus `CLAUDE.md` at project root |
| **Codex CLI** | `profiles/codex/` | Split layout: `.codex/agents/` (TOML agent definitions) + `.agents/` (skills, scripts, recipes, templates); plus `AGENTS.md` at project root |
| **Cursor** | `profiles/cursor/` | `.cursor/` directory with `.mdc` rule files; plus `AGENTS.md` at project root |
| **GitHub Copilot CLI** | `profiles/copilot-cli/` | `.github/` directory (`output_root` `.github`) with `agents/*.agent.md` (copilot-agent format), `skills/`, `scripts/`, `recipes/`, `templates/`; plus `AGENTS.md` at project root |
| **Antigravity** | `profiles/antigravity/` | `.agent/` directory (`output_root` `.agent`) with sub-agents reshaped into `rules/*.md` (antigravity-rule format, `trigger:`-style frontmatter), plus `skills/`, `scripts/`, `recipes/`, `templates/`; plus `AGENTS.md` at project root |

(`project-structure.md` `├── profiles/`, `docs/install.md` `## What gets installed per tool`)

All five profiles contain byte-identical skill and agent bodies — only the wrapper
format differs per tool (markdown for Claude Code, TOML for Codex agents, `.mdc` for
Cursor rules, `.agent.md` copilot-agent frontmatter for Copilot CLI, and
`antigravity-rule` `trigger:`-style rule frontmatter for Antigravity; the four
agent-format values are listed in `aid_profile.py` `_KNOWN_AGENT_FORMATS`). The
generator (`run_generator.py`) enforces this byte-identity via VERIFY (deterministic)
at end of every render (see `architecture.md` `verify_deterministic.py` for the gate).

### What End Users See After Install

After `aid add <tool>`, the target project gains (`docs/install.md` `## What gets installed per tool`):

- The tool-appropriate hidden directory (`.claude/`, `.codex/`+`.agents/`, `.cursor/`,
  `.github/` for Copilot CLI, or `.agent/` for Antigravity)
  containing all 11 user-facing skills (the six numbered phases + `aid-config` + the three
  optional skills + the off-pipeline `aid-housekeep`), 9 agents, 51 recipes, templates, and
  helper scripts. (The maintainer-only `aid-generate` skill is never installed — it lives only
  in the source repo's `.claude/skills/`, not in `canonical/`; see `architecture.md`.)
- A `CLAUDE.md` or `AGENTS.md` at the project root with placeholders that
  `/aid-config` and `/aid-discover` populate. The root `AGENTS.md` is byte-identical across
  the four AGENTS.md-writing tools (FR12 invariant), so multi-tool installs no longer collide;
  a user-authored copy is preserved as `*.aid-new` (FR11 protect-on-diff). (`docs/install.md`
  `## What gets installed per tool`, `## Protect-on-diff for root agent files`)
- `.aid/` appended to the project's `.gitignore` — the Knowledge Base stays out of
  git by default; users remove the entry to commit it.
  (`docs/install.md` ``.aid/` is appended to your `.gitignore` by default`)

### Runtime Requirements

(`README.md` `## Install`, `docs/install.md` `## Install channels`)

- One or more host AI tools: Claude Code, OpenAI Codex CLI, Cursor, GitHub Copilot CLI, or Antigravity.
- The `aid` CLI runtime per channel: Bash (or git-bash on Windows) + curl for the curl bootstrap;
  PowerShell 5.1+ for the irm bootstrap on Windows; Node >=18 for the npm channel; Python >=3.8
  (pipx/pip) for the PyPI channel.
- Git.
- Node 18+ is optional — only `/aid-summarize` uses it for diagram validation.
  No `package.json` is present in the repo; users install Mermaid CLI ad-hoc
  when they use `aid-summarize`.
