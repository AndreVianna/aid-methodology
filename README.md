# AID — AI Integrated Development

![License](https://img.shields.io/github/license/AndreVianna/aid-methodology)
![Version](https://img.shields.io/badge/version-0.7.5-blue)
![Claude Code](https://img.shields.io/badge/Claude_Code-supported-8B5CF6)
![Codex CLI](https://img.shields.io/badge/Codex_CLI-supported-10B981)
![Cursor](https://img.shields.io/badge/Cursor-supported-3B82F6)
![Copilot CLI](https://img.shields.io/badge/Copilot_CLI-supported-F59E0B)
![Antigravity](https://img.shields.io/badge/Antigravity-supported-EF4444)

**A full-lifecycle methodology for building software with AI agents** — from understanding an existing codebase to monitoring it in production.

11-skill pipeline · 9 specialized agents · 5 AI tools · Knowledge Base that every phase reads and any phase can revise.

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
    Exe -. "when finished" .-> HK
    HK  -. "targeted KB refresh" .-> Disc
```

*11 skills · 5 groups · 2 paths (TRIAGE-routed). Full methodology: [docs/aid-methodology.md](docs/aid-methodology.md).*

> [!TIP]
> New to AID? Install takes 2 minutes. Run slash commands directly in your AI coding tool — no plugins required. Jump to [Install](#install) to get started.

---

## Install

AID uses a persistent global `aid` CLI installed once per machine. After bootstrap, use `aid add <tool>` inside any repo to install the AID profile for that tool.

### Bootstrap the `aid` CLI (once per machine)

**Linux / macOS:**

```bash
curl -fsSL https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.sh | bash
```

Installs to `~/.aid/` and adds `~/.aid/bin` to your PATH. Open a new shell after.

**Windows (PowerShell 5.1+):**

```powershell
irm https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/install.ps1 | iex
```

Installs to `%LOCALAPPDATA%\aid\` and adds it to your User PATH. Open a new shell after.

**npm (Node >=18):**

```bash
npm i -g aid-installer
# one-off without a global install:
npx aid-installer add claude-code
```

**PyPI (Python >=3.8):**

```bash
pipx install aid-installer        # recommended — isolated environment
# or:
pip install --user aid-installer
```

**Offline / air-gapped:**

Download a profile tarball from the [GitHub Releases page](https://github.com/AndreVianna/aid-methodology/releases), verify it, then install without network access:

```bash
# Download and verify (example: claude-code at v0.7.5)
curl -LO https://github.com/AndreVianna/aid-methodology/releases/download/v0.7.5/aid-claude-code-v0.7.5.tar.gz
curl -LO https://github.com/AndreVianna/aid-methodology/releases/download/v0.7.5/SHA256SUMS
sha256sum --check --ignore-missing SHA256SUMS     # Linux
shasum -a 256 -c SHA256SUMS                       # macOS

# Install from the local bundle (after bootstrapping the CLI)
aid add claude-code --from-bundle aid-claude-code-v0.7.5.tar.gz
```

All four channels deliver the same `aid` CLI. See [Full install guide →](docs/install.md) for the channel comparison and `aid update self` behavior per channel.

### Use it

```bash
aid add claude-code        # install AID into the current project (also: codex cursor copilot-cli antigravity)
aid add codex,cursor       # multiple tools at once
aid status                 # show what is installed
aid update                 # update all installed tools
aid update self            # update the aid CLI itself
aid remove codex           # remove one tool
aid remove self            # remove the aid CLI itself (asks to confirm)
```

Re-running `aid add` is safe: identical files are skipped. Root agent files (`CLAUDE.md` / `AGENTS.md`) that you wrote yourself are protected — AID writes the incoming version as `*.aid-new` for you to review rather than overwriting silently.

[Full install guide — all channels, offline bundles, version pinning, protect-on-diff, reference →](docs/install.md)

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

**Brownfield** projects run `/aid-config` → `/aid-discover` → `/aid-interview`. **Greenfield** projects skip Discovery and start at `/aid-interview`. Every phase is gated — nothing advances without your approval.

[See it applied step by step →](examples/)

---

## Why AID

Hand a capable coding agent a vague task and a large repository and you get predictable failure modes. AID removes each one structurally — not with prompt-tuning, but with process.

| **Failure mode** | What it looks like | How AID removes it |
|---|---|---|
| **Knowledge gaps** | The agent invents how the existing system works. | Discovery builds the Knowledge Base first — a fixed-shape, evidence-backed picture of the codebase before any spec is written. |
| **Hallucination** | The agent states things about the code that aren't true. | Every KB claim carries a `path:line` citation. Agents navigate to exact lines instead of guessing. |
| **Drift** | Implementation quietly diverges from intent; the spec rots. | Spec-as-hypothesis + 11 formal feedback loops. When reality contradicts an artifact the agent files a Q&A entry or IMPEDIMENT and the upstream artifact is revised — traceably. |
| **Overengineering** | The agent adds scope nobody asked for. | Typed, PR-sized tasks with explicit acceptance criteria. The Reviewer grades against the spec, not vibes. |
| **Oversights** | Bugs and untested paths slip through review. | Separate adversarial review: the agent that writes never grades its own work — a higher-tier Reviewer with clean context loops until grade >= minimum. |
| **Context exhaustion** | Loading the whole repo — slow, expensive, lossy. | A 3-tier context economy: always-loaded index -> one KB doc on demand -> exact `path:line`. The agent pays only for what the task needs. |

[Full philosophy and design rationale →](docs/aid-methodology.md)

---

## How It Works

### The Pipeline

Six numbered development phases form the mandatory sequential path. Deploy and Monitor are optional. `aid-housekeep` runs off the pipeline on demand.

AID's phases are gated: you approve every transition. Nothing auto-advances. [Full pipeline deep-dive →](docs/aid-methodology.md#1-the-pipeline)

### The Lite Path

For small, well-scoped work, `/aid-interview` opens with a TRIAGE: you describe the work in your own words and the agent infers the work-type and the best-matching recipe. A confident, single-target match skips the full pipeline and routes straight to `/aid-execute`.

[Lite path and recipes →](docs/aid-methodology.md#2-philosophy)

### The Knowledge Base

The KB is the central artifact: a living 14-document picture of the project. Every phase reads it; any phase can revise it. A 3-tier retrieval model (INDEX → one doc on demand → exact `path:line`) gives agents precise context at minimal cost — no vectors, no embeddings, no chunking.

[Knowledge Base in depth →](docs/aid-methodology.md#3-the-knowledge-base)

### The Agent Model

AID defines 9 agents across three tiers (Large / Medium / Small), mapped per tool to concrete models. The invariant enforced everywhere: the Reviewer's tier is always >= the Executor's. The agent that writes never grades its own work.

[Full agent roster and dispatch rules →](docs/aid-methodology.md#5-the-agent-model)

**Feedback Loops** — 11 formal pathways so any phase can revise an upstream artifact when reality contradicts an assumption. [All 11 loops →](docs/aid-methodology.md#6-feedback-loops)

**AID vs. SDD** — SDD says the spec drives development. AID says understanding drives the spec, the spec drives development, and production drives the next understanding. [Comparison →](docs/aid-methodology.md#9-comparison-with-sdd)

---

## Documentation

| Document | Contents |
|---|---|
| [docs/aid-methodology.md](docs/aid-methodology.md) | Complete methodology (~40 min read) |
| [docs/install.md](docs/install.md) | Full install guide — all channels, offline, update, remove |
| [docs/repository-structure.md](docs/repository-structure.md) | Repo layout and contributor orientation |
| [docs/release.md](docs/release.md) | Maintainer release runbook |
| [docs/faq.md](docs/faq.md) | How-to questions |
| [docs/glossary.md](docs/glossary.md) | Term definitions |
| [examples/](examples/README.md) | Step-by-step walkthroughs — greenfield, brownfield full-path, brownfield lite-path |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to contribute skills, templates, examples, or methodology improvements.

## License

MIT — see [LICENSE](LICENSE).

---

*Full methodology: [docs/aid-methodology.md](docs/aid-methodology.md) · Blog: [AID — the complete picture](https://casuloailabs.com/blog/aid-methodology/)*
