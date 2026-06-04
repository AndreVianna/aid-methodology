# AID — AI Integrated Development

![License](https://img.shields.io/github/license/AndreVianna/aid-methodology)
![Version](https://img.shields.io/badge/version-0.1.0--dev-blue)
![Claude Code](https://img.shields.io/badge/Claude_Code-supported-8B5CF6)
![Codex CLI](https://img.shields.io/badge/Codex_CLI-supported-10B981)
![Cursor](https://img.shields.io/badge/Cursor-supported-3B82F6)
![Copilot CLI](https://img.shields.io/badge/Copilot_CLI-supported-F59E0B)
![Antigravity](https://img.shields.io/badge/Antigravity-supported-EF4444)

**A full-lifecycle methodology for building software with AI agents** — from understanding an existing codebase to monitoring it in production.

11-skill pipeline · 22 specialized agents · 5 AI tools · Knowledge Base that every phase reads and any phase can revise.

```mermaid
flowchart TB
    classDef prep    fill:#1E3A8A,stroke:#1E3A8A,color:#ffffff
    classDef def     fill:#6D28D9,stroke:#6D28D9,color:#ffffff
    classDef map     fill:#0F766E,stroke:#0F766E,color:#ffffff
    classDef exe     fill:#166534,stroke:#166534,color:#ffffff
    classDef delopt  fill:#C2410C,stroke:#C2410C,color:#ffffff,stroke-dasharray:5 4
    classDef aux     fill:#E5E7EB,stroke:#9CA3AF,color:#1F2937,stroke-dasharray:4 3
    classDef offpipe fill:#374151,stroke:#374151,color:#ffffff,stroke-dasharray:6 4

    subgraph G1[" 1 · Prepare "]
        Init["aid-config<br/>setup · once"]:::aux
        Disc["1 · aid-discover<br/>brownfield"]:::prep
        Sum["aid-summarize<br/>optional"]:::aux
    end
    subgraph G2[" 2 · Define "]
        Intv["2 · aid-interview<br/>TRIAGE → full or lite"]:::def
        Spec["3 · aid-specify<br/>full path only"]:::def
    end
    subgraph G3[" 3 · Map "]
        Plan["4 · aid-plan<br/>full path only"]:::map
        Det["5 · aid-detail<br/>full path only"]:::map
    end
    subgraph G4[" 4 · Execute "]
        Exe["6 · aid-execute<br/>8 task types · graded loop"]:::exe
    end
    subgraph G5[" 5 · Deliver (optional) "]
        Dep["aid-deploy"]:::delopt
        Mon["aid-monitor"]:::delopt
    end

    HK["aid-housekeep<br/>on-demand · off-pipeline<br/>KB-DELTA · SUMMARY-DELTA · CLEANUP"]:::offpipe

    Init --> Disc --> Intv --> Spec --> Plan --> Det --> Exe
    Exe -. "on demand" .-> Dep
    Exe -. "on demand" .-> Mon
    HK  -. "targeted KB refresh" .-> Disc
```

*11 skills · 5 groups · 2 paths (TRIAGE-routed). Full methodology: [methodology/aid-methodology.md](methodology/aid-methodology.md).*

> [!TIP]
> New to AID? Install takes 2 minutes. Run slash commands directly in your AI coding tool — no plugins required. Jump to [Install](#install) to get started.

---

## Install

AID is distributed by `git clone`. The setup script copies skills, agents, and templates into your target project in each tool's native format.

```bash
git clone https://github.com/AndreVianna/aid-methodology.git
cd aid-methodology

# Linux / macOS / git-bash
./setup.sh /path/to/your/project

# Windows (PowerShell 5.1+)
.\setup.ps1 C:\path\to\your\project
```

The script shows a numbered menu — select the tools you use, then select Done:

```
1. Claude Code
2. OpenAI Codex CLI
3. Cursor
4. GitHub Copilot CLI
5. Antigravity
[6] Done
```

Re-running is safe: identical files are skipped, changed files prompt before overwriting. Pass `--force` to overwrite without prompts.

> [!NOTE]
> Prefer to install by hand? Copy the profile directory for each tool you use directly into your project root:
> - Claude Code: `profiles/claude-code/.claude/`
> - Codex CLI: `profiles/codex/.codex/` + `profiles/codex/.agents/`
> - Cursor: `profiles/cursor/.cursor/`
> - GitHub Copilot CLI: `profiles/copilot-cli/.github/`
> - Antigravity: `profiles/antigravity/.agent/`

**Runtime requirements:** one or more of the five supported AI tools · Bash or PowerShell 5.1+ · Git · Node 18+ (optional, only for `/aid-summarize` diagram validation).

---

## Quick Start

Open your AI coding tool in your project and run the skills as slash commands:

```
/aid-config           # once per project — scaffolds .aid/ and KB structure
/aid-discover         # brownfield only: analyze the codebase into the KB
/aid-interview        # gather requirements; TRIAGE auto-routes full or lite path
/aid-specify          # write the technical spec for each feature (full path only)
/aid-plan             # sequence features into shippable deliveries (full path only)
/aid-detail           # decompose deliveries into typed, PR-sized tasks (full path only)
/aid-execute          # implement each task with the built-in adversarial review loop
/aid-deploy           # optional — package and ship a delivery
/aid-monitor          # optional — classify production findings and route fixes back
/aid-summarize        # optional — generate an offline HTML viewer of the KB
/aid-housekeep        # on-demand — keep the Knowledge Base current (off-pipeline)
```

**Brownfield** projects run `/aid-config` → `/aid-discover` → `/aid-interview`. **Greenfield** projects skip Discovery and start at `/aid-interview`. Every phase is gated — nothing advances without your approval. See [examples/](examples/README.md) for step-by-step walkthroughs.

---

## Why AID? — The Failure Modes It Removes

Hand a capable coding agent a vague task and a large repository and you get predictable failure modes. AID removes each one structurally — not with prompt-tuning, but with process.

| **Failure mode** | What it looks like | How AID removes it |
|---|---|---|
| **Knowledge gaps** | The agent invents how the existing system works. | Discovery builds the Knowledge Base first — a fixed-shape, evidence-backed picture of the codebase before any spec is written. |
| **Hallucination** | The agent states things about the code that aren't true. | Every KB claim carries a `path:line` citation. Agents navigate to exact lines instead of guessing. |
| **Drift** | Implementation quietly diverges from intent; the spec rots. | Spec-as-hypothesis + 11 formal feedback loops. When reality contradicts an artifact the agent files a Q&A entry or IMPEDIMENT and the upstream artifact is revised — traceably. |
| **Overengineering** | The agent adds scope nobody asked for. | Typed, PR-sized tasks with explicit acceptance criteria. The Reviewer grades against the spec, not vibes. |
| **Oversights** | Bugs and untested paths slip through review. | Separate adversarial review: the agent that writes never grades its own work — a higher-tier Reviewer with clean context loops until grade ≥ minimum. |
| **Context exhaustion** | Loading the whole repo — slow, expensive, lossy. | A 3-tier context economy: always-loaded index → one KB doc on demand → exact `path:line`. The agent pays only for what the task needs. |

[Full philosophy and design rationale →](methodology/aid-methodology.md)

---

## The Pipeline

The six numbered development phases form the mandatory sequential path. Deploy and Monitor are optional Deliver skills. `aid-housekeep` runs off the pipeline on demand.

| **Group** | **Phase** | **Skill** | **What it produces** |
|---|---|---|---|
| **1 · Prepare** | — Init | `/aid-config` | `.aid/` scaffold · KB placeholders (14 templates + meta) · `CLAUDE.md` / `AGENTS.md` |
| | 1 · Discover | `/aid-discover` | the 14-standard-document Knowledge Base |
| | — Summarize | `/aid-summarize` | optional offline HTML viewer of the KB |
| **2 · Define** | 2 · Interview | `/aid-interview` | `REQUIREMENTS.md` + per-feature `SPEC.md` stubs (full path) OR work-root `SPEC.md` + `tasks/` (lite path) |
| | 3 · Specify | `/aid-specify` | technical specification for each feature (full path only) |
| **3 · Map** | 4 · Plan | `/aid-plan` | `PLAN.md` — features sequenced into shippable deliveries (full path only) |
| | 5 · Detail | `/aid-detail` | typed, PR-sized task files with acceptance criteria (full path only) |
| **4 · Execute** | 6 · Execute | `/aid-execute` | implemented + reviewed code, looped to grade |
| **5 · Deliver** | — Deploy | `/aid-deploy` | *(optional)* shipped delivery + pull request |
| | — Monitor | `/aid-monitor` | *(optional)* production findings classified and routed to fixes |
| **off-pipeline** | — | `/aid-housekeep` | KB-DELTA refresh · SUMMARY-DELTA · workspace CLEANUP |

[Per-phase deep-dive →](methodology/aid-methodology.md)

---

## The Lite Path

For small, well-scoped work, `/aid-interview` begins with a TRIAGE that routes automatically — no manual cost-benefit decision required.

```mermaid
flowchart LR
    classDef def   fill:#6D28D9,stroke:#6D28D9,color:#ffffff
    classDef exe   fill:#166534,stroke:#166534,color:#ffffff
    classDef lite  fill:#92400E,stroke:#92400E,color:#ffffff

    Triage["aid-interview · TRIAGE<br/>T1 breadth · T2 task-count · T3 type"]:::def

    subgraph FullPath[" Full path "]
        direction LR
        F1["Interview<br/>REQUIREMENTS + feature SPEC stubs"]:::def
        F2["aid-specify"]:::def
        F3["aid-plan"]:::def
        F4["aid-detail"]:::def
    end
    subgraph LitePath[" Lite path "]
        direction LR
        L1["CONDENSED-INTAKE"]:::lite
        L2["TASK-BREAKDOWN"]:::lite
        L3["LITE-REVIEW"]:::lite
    end
    Exec["aid-execute"]:::exe

    Triage -- "ANY large signal:<br/>T1 = multiple · T2 = many (6+)<br/>· T3 = new feature/system" --> F1
    F1 --> F2 --> F3 --> F4 --> Exec
    Triage -- "ALL small:<br/>T1 none/one-small · T2 a few (≤5)<br/>· T3 bug-fix / refactor / doc" --> L1
    L1 --> L2 --> L3 --> Exec
    L3 -. "escalate if scope grows" .-> F1
```

**Lite path output:** work-root `SPEC.md` + `tasks/` directory — no `features/` folder, no `REQUIREMENTS.md`, no `PLAN.md`. Straight to `/aid-execute`.

| **workType** | **Sub-path** | **Typical output** |
|---|---|---|
| `bug-fix` | LITE-BUG-FIX | 1 IMPLEMENT task (fix + regression test) |
| `small-refactor` | LITE-REFACTOR | 1–3 REFACTOR + TEST tasks |
| `single-doc` | LITE-DOC | 1 DOCUMENT task |
| `small-new-feature` | LITE-FEATURE | 1–5 IMPLEMENT + TEST + DOCUMENT tasks |

**Recipes** speed up recurring patterns further. Five pre-filled templates live at `canonical/recipes/` — YAML frontmatter + `## spec` + `## tasks` blocks with `{{slot}}` placeholders that `parse-recipe.sh` substitutes, eliminating redundant interview for known work shapes. A lite work can also escalate to full mid-flight if scope grows.

---

## The Knowledge Base

The KB is the central artifact: the accumulated, living understanding of the project. Every phase reads it; every phase may revise it. Its doc-set is declared per project — a standard 14-document default, adjustable via `discovery.doc_set` in `.aid/settings.yml`.

**Standard KB doc-set (14 documents):** `architecture` · `coding-standards` · `domain-glossary` · `external-sources` · `feature-inventory` · `infrastructure` · `integration-map` · `module-map` · `pipeline-contracts` · `project-structure` · `schemas` · `tech-debt` · `technology-stack` · `test-landscape`

Because the set is declared, an agent looking for data schemas always reads `schemas.md`; looking for debt, always `tech-debt.md` — navigation by convention, not search. Retrieval happens in three tiers, cheapest first:

- **Tier 1 — `INDEX.md`, always loaded.** A 2-3 line summary of every KB doc (~200-500 tokens). The agent knows what exists and where, at negligible cost.
- **Tier 2 — one KB document, on demand.** From the INDEX entry the agent reads only the single document a task needs.
- **Tier 3 — exact `path:line` citation.** Every factual claim in a KB doc carries an inline citation. The agent jumps straight to the precise file and line — never bulk-loading unrelated source.

Net effect: retrieval-augmented behavior with no vector database, no embeddings, no chunking.

[Knowledge Base in depth →](methodology/aid-methodology.md)

---

## The Agent Model

Skills are state-machine orchestrators; agents are the workers. AID defines 22 agents across three tiers.

```mermaid
flowchart TB
    classDef large fill:#1E3A8A,stroke:#1E3A8A,color:#ffffff
    classDef med   fill:#0F766E,stroke:#0F766E,color:#ffffff
    classDef small fill:#E5E7EB,stroke:#9CA3AF,color:#1F2937

    subgraph L["Large tier — 10 · highest-stakes (Opus / GPT-5.5 / Gemini-3 Pro hi)"]
        direction LR
        LA["architect"]:::large
        LR2["reviewer"]:::large
        LI["interviewer"]:::large
        LS["security"]:::large
        LD["6 × discovery-*"]:::large
    end
    subgraph M["Medium tier — 9 · production workhorses (Sonnet / GPT-5.4 / Gemini-3 Pro lo)"]
        direction LR
        MO["orchestrator"]:::med
        MR["researcher"]:::med
        MD["developer"]:::med
        MOps["operator"]:::med
        MDE["5 × data-engineer · performance<br/>devops · tech-writer · ux-designer"]:::med
    end
    subgraph S["Small tier — 3 · mechanical (Haiku / GPT-5.4-mini / Gemini-3 Flash)"]
        direction LR
        SE["simple-extractor"]:::small
        SF["simple-formatter"]:::small
        SG["simple-glob"]:::small
    end
    L -. "reviewer tier ≥ executor tier" .-> M -.-> S
```

The tiers are provider-agnostic — each host tool maps them to a concrete model:

| **Tier** | **Claude Code** | **Codex CLI** | **Cursor** | **Copilot CLI** | **Antigravity** |
|---|---|---|---|---|---|
| **Large** | Claude Opus | GPT-5.5 (high reasoning) | Claude Opus | claude-opus-4.8 | gemini-3-pro |
| **Medium** | Claude Sonnet | GPT-5.4 (medium reasoning) | Claude Sonnet | claude-sonnet-4.6 | gemini-3-pro |
| **Small** | Claude Haiku | GPT-5.4-mini (low reasoning) | Claude Haiku | claude-haiku-4.5 | gemini-3-flash |

The invariant enforced everywhere: **the Reviewer's tier is always ≥ the Executor's tier.** The agent that writes never grades its own work.

[Full agent roster and dispatch rules →](methodology/aid-methodology.md)

---

## Feedback Loops

The development pipeline is sequential by default. AID defines 11 formal feedback loops so any phase can revise an upstream artifact when reality contradicts an assumption — eight within development, two from production back to development, and one cross-cutting re-entry available from any phase.

Key loops:

- **Any phase → Discovery** — the KB is wrong or incomplete; targeted re-discovery fills the specific gap.
- **Execute → IMPEDIMENT** — the agent hits an assumption that doesn't hold and escalates explicitly instead of working around it silently.
- **Monitor → Interview** — a production bug takes the short path through Interview's lite bug-fix TRIAGE into Execute.
- **Monitor → Interview** — a change request re-enters as new requirements and runs the pipeline from Interview.

Every loop produces a formal record (Q&A entry in a STATE file, an IMPEDIMENT file, or a Monitor finding) with a revision trail. The spec evolves — but traceably.

[All 11 loops described →](methodology/aid-methodology.md)

---

## AID vs. SDD

Spec-Driven Development is a good idea. AID contains it and goes further.

| **Dimension** | **SDD** | **AID** |
|---|---|---|
| **Starting point** | You have a spec | You have a problem |
| **Brownfield support** | Not addressed | First-class Discovery phase + 14-document KB |
| **Spec philosophy** | Spec is the source of truth | Spec is a hypothesis — revised by formal protocol |
| **Requirements** | Assumed to exist | Adaptive interview, one question at a time |
| **Path routing** | One fixed path | TRIAGE routes full or lite automatically |
| **Planning depth** | A single spec | Two levels: Plan (strategy) → Detail (tactics) |
| **Quality** | Review the output | Separate adversarial reviewer + deterministic grading loop |
| **Feedback loops** | Linear: spec → code → done | 11 formal loops (8 development + 2 post-production + 1 cross-cutting) |
| **Post-delivery** | Not addressed | Monitor classifies findings and routes them back |

> SDD says: *the spec drives development.*
> AID says: *understanding drives the spec, the spec drives development, and production drives the next understanding.*

---

## What Gets Installed

<details>
<summary>Expand file listings by tool</summary>

**Claude Code** — installed into `.claude/`:
- `.claude/skills/` — 11 skill markdown files
- `.claude/agents/` — 22 agent markdown files
- `CLAUDE.md` — project-context file at your project root

**Codex CLI** — installed into `.codex/` + `.agents/`:
- `.codex/agents/` — agent TOML files
- `.agents/` — agent TOML files
- `AGENTS.md` — project-context file at your project root

**Cursor** — installed into `.cursor/`:
- `.cursor/rules/` — skill and agent `.mdc` rule files
- `AGENTS.md` — project-context file at your project root

**GitHub Copilot CLI** — installed into `.github/`:
- `.github/copilot-agents/` — agent `.agent.md` files
- `AGENTS.md` — project-context file at your project root

**Antigravity** — installed into `.agent/`:
- `.agent/` — skill and agent files with `trigger:` frontmatter
- `AGENTS.md` — project-context file at your project root

All five profiles contain byte-identical skill/agent bodies — only the wrapper format differs per tool. `.aid/` is appended to your `.gitignore` by default (the Knowledge Base stays out of git; remove the entry if you want to commit it).

</details>

All five profiles are generated from the same canonical source at `canonical/` — byte-identity is verified by `verify_deterministic.py` after every render. Never edit `profiles/` directly; edit `canonical/` and re-run `python run_generator.py`.

---

## Versioning

AID is at **`0.1.0-dev`** (see [`VERSION`](VERSION)) — a pre-release marker, not a stable release. The canonical position is **"continuous master"**: there is no formal semver release cadence yet.

- Install via `setup.sh` (or `setup.ps1`) to get current `master`; re-run to pick up updates.
- A formal version bump will be introduced when the methodology stabilizes.

---

## Repository Structure

<details>
<summary>Expand full repository layout</summary>

```
aid-methodology/
├── canonical/                      ← single source of truth (never edit profiles/ directly)
│   ├── skills/                     ← 11 user-facing skill definitions
│   ├── agents/                     ← 22 agent definitions
│   ├── templates/                  ← KB templates and document templates
│   ├── recipes/                    ← 5 lite-path seed recipes
│   └── scripts/                    ← helper scripts by phase
├── profiles/                       ← rendered install trees (generated — do not edit)
│   ├── claude-code/
│   ├── codex/
│   ├── cursor/
│   ├── copilot-cli/
│   └── antigravity/
├── methodology/aid-methodology.md  ← the complete methodology (~40 min read)
├── docs/                           ← glossary and FAQ
├── examples/                       ← step-by-step worked tutorial examples
├── setup.sh  ·  setup.ps1         ← cross-platform installers
└── CONTRIBUTING.md  ·  LICENSE
```

</details>

| **Want to…** | **Go to** |
|---|---|
| Read the complete methodology | [`methodology/aid-methodology.md`](methodology/aid-methodology.md) |
| Look up a term | [`docs/glossary.md`](docs/glossary.md) |
| Answer a how-to question | [`docs/faq.md`](docs/faq.md) |
| See AID applied step by step | [`examples/`](examples/README.md) — greenfield, brownfield full-path, brownfield lite-path |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to contribute skills, templates, examples, or methodology improvements.

## License

MIT — see [LICENSE](LICENSE).

---

*Full methodology: [methodology/aid-methodology.md](methodology/aid-methodology.md) · Blog: [AID — the complete picture](https://casuloailabs.com/blog/aid-methodology/)*
