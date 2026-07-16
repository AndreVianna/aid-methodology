# AID — AI Integrated Development

![License](https://img.shields.io/github/license/AndreVianna/aid-methodology)
![Version](https://img.shields.io/github/v/release/AndreVianna/aid-methodology)
![Claude Code](https://img.shields.io/badge/Claude_Code-supported-8B5CF6)
![Codex CLI](https://img.shields.io/badge/Codex_CLI-supported-10B981)
![Cursor](https://img.shields.io/badge/Cursor-supported-3B82F6)
![Copilot CLI](https://img.shields.io/badge/Copilot_CLI-supported-F59E0B)
![Antigravity](https://img.shields.io/badge/Antigravity-supported-EF4444)

**A full-lifecycle methodology for building software with AI agents** — from understanding an existing codebase to monitoring it in production.

108 skills — 14 pipeline / on-demand / router skills + a 94-row shortcut catalog (64 verb-first shortcuts + 30 hand-authored repurpose skills) · 9 specialized agents · 5 AI tools · Knowledge Base that every phase reads and any phase can revise.

**Choosing your entry:** know your change → run the matching shortcut. Know it's big or new → `/aid-describe`. Not sure which? → `/aid-triage`. Just have a question? → `/aid-ask`.

```mermaid
flowchart TD
    subgraph Entry["Choose your entry"]
        SC["/aid-&lt;verb&gt;[-&lt;artifact&gt;]<br/>shortcut — I know my change"]
        TR["/aid-triage<br/>— not sure? (suggest-only)"]
        DS["/aid-describe<br/>— broad / new project"]
        ASK["/aid-ask<br/>— just asking a question"]
    end
    TR -. suggests .-> SC
    TR -. suggests .-> DS
    TR -. "question" .-> ASK

    CFG["/aid-config (bootstrap · once)"] --> DISC["/aid-discover (brownfield)"]
    DISC --> DS

    SC --> ENG["Shortcut engine<br/>INTAKE→CAPTURE→SPEC→PLAN→DETAIL→GATE→APPROVAL-HALT<br/>(Describe→Detail, collapsed &amp; autonomous)"]
    ENG --> HALT{{"Approval halt"}}

    DS --> DEF["/aid-define"] --> SPC["/aid-specify"] --> PLN["/aid-plan"] --> DTL["/aid-detail"]
    DTL --> HALT

    HALT --> EXE["/aid-execute (graded loop · 8 task types)"]
    EXE --> DEP["/aid-deploy (optional)"] --> MON["/aid-monitor (optional)"]
    MON -. "bug → /aid-fix" .-> SC
    MON -. "change request → /aid-triage" .-> TR
```

*108 skills · 3 entry points (shortcut, `/aid-triage`, `/aid-describe`) plus `/aid-ask` for a plain question. Full methodology: [docs/aid-methodology.md](docs/aid-methodology.md).*

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
# Resolve the latest release tag (or set VERSION manually from the Releases page above)
VERSION="$(curl -fsSL https://api.github.com/repos/AndreVianna/aid-methodology/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')"

# Download and verify (example: claude-code)
curl -LO "https://github.com/AndreVianna/aid-methodology/releases/download/v${VERSION}/aid-claude-code-v${VERSION}.tar.gz"
curl -LO "https://github.com/AndreVianna/aid-methodology/releases/download/v${VERSION}/SHA256SUMS"
sha256sum --check --ignore-missing SHA256SUMS     # Linux
shasum -a 256 -c SHA256SUMS                       # macOS

# Install from the local bundle (after bootstrapping the CLI)
aid add claude-code --from-bundle "aid-claude-code-v${VERSION}.tar.gz"
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

Re-running `aid add` is safe: identical files are skipped. Root agent files (`CLAUDE.md` / `AGENTS.md`) are updated in-place and losslessly: AID rewrites only the region between its own markers and leaves everything you authored outside those markers untouched.

[Full install guide — all channels, offline bundles, version pinning, protect-on-diff, reference →](docs/install.md)

---

## Quick Start

Open your AI coding tool in your project and run the skills as slash commands:

```
/aid-config           # once per project — scaffolds .aid/ and KB structure
/aid-discover         # brownfield only: analyze the codebase into the KB
/aid-triage           # not sure where to start? suggest-only router — points you to a shortcut, /aid-describe, or /aid-ask
/aid-<verb>[-<artifact>]  # shortcut — you know the change; e.g. /aid-fix, /aid-create-api, /aid-change-cli (64 shortcuts)
/aid-ask              # just have a question? free-form Q&A over the KB + codebase; friendly alias of /aid-query-kb
/aid-describe         # gather requirements for broad / new-project work (full path only); on approval, run /aid-define
/aid-define           # decompose approved requirements into features (full path only)
/aid-specify          # write the technical spec for each feature (full path only)
/aid-plan             # sequence features into shippable deliveries (full path only)
/aid-detail           # decompose deliveries into typed, PR-sized tasks (full path only)
/aid-execute          # implement each task with the built-in adversarial review loop
/aid-deploy           # optional — package and ship a delivery
/aid-monitor          # optional — classify production findings and route fixes back (bug → /aid-fix, change request → /aid-triage)
/aid-summarize        # optional — generate an offline HTML viewer of the KB
/aid-housekeep        # on-demand — keep the Knowledge Base current (off-pipeline)
/aid-query-kb         # on-demand — answer free-form questions from the KB + codebase; captures gaps
/aid-update-kb        # on-demand — apply a targeted delta to KB docs through the review gate
/aid-set-connector    # on-demand — create or update a connector descriptor for an external tool
/aid-unset-connector  # on-demand — remove a connector descriptor and purge its secret
```

**Brownfield** projects run `/aid-config` → `/aid-discover` → `/aid-describe` → `/aid-define`. **Greenfield** projects skip Discovery and start at `/aid-describe`. For a small, well-scoped change, skip straight to a shortcut instead — or run `/aid-triage` if you're not sure which one fits. Just have a question, not a change? Run `/aid-ask`. Every phase is gated — nothing advances without your approval.

[See it applied step by step →](examples/)

---

## What's New in v1.1.0

### AID dashboard

`aid dashboard start node` or `aid dashboard start python` opens a local, read-only web view of every project this install manages. Each project shows its current pipeline status, installed tools, and a 5-state Knowledge-Base freshness card (including "Outdated" detection). Click through to a task drill-down forensic panel. A 4-level breadcrumb keeps you oriented. The server binds to 127.0.0.1; pass `--remote` to expose the machine-level dashboard over your private tailnet.

### Self-cleaning install and update

Installing or updating AID now prunes stale AID files — files that were renamed, moved, or dropped between versions. Only AID-managed entries are pruned; your files are never touched. Combined with content isolation (see below), updates are clean by default: no orphaned files accumulate across upgrades.

### Content isolation

AID's own folders now install under an `aid/` subtree (`.claude/aid/{scripts,templates}`) and every AID file in tool-native folders (`agents/`, `skills/`, `rules/`) carries an `aid-` prefix. AID content and your content cannot collide, and `aid update` can prune AID's own stale files in place without any risk of touching yours.

Root-agent files (`CLAUDE.md` / `AGENTS.md`) are now updated in-place and losslessly: AID rewrites only the region between its own `<!-- AID:BEGIN -->` / `<!-- AID:END -->` markers; everything you wrote outside those markers is preserved exactly. The old `.aid-new` sidecar file is gone.

### `aid projects` and the project registry

`aid projects [list|add|remove|help]` manages the projects AID tracks. `list` shows each project's version, installed tools, tier, and a `*` marker for the current directory. The CLI keeps a lightweight registry (`$AID_STATE_HOME/registry.yml`) so the dashboard and `aid update self` always know which projects to display and migrate.

### Upgrade migration

`aid update self` walks every tracked project and offers to migrate it to the current layout — validating and repairing `.aid/settings.yml`, installing any missing files, and registering the project. Choose All / Yes / No / Cancel per project. Migration is idempotent and additive: it preserves your settings and comments. pip/pipx installs (no postinstall hook) are covered by lazy migration on the next `aid` command.

### Worktree-aware dashboard tracking

Work that lives only on a git worktree branch is surfaced under its project (labeled by branch) instead of being invisible. Same-work pipelines across branches are merged into a single view — the most-advanced state wins. The dashboard degrades gracefully to the main checkout when git is unavailable.

### `/aid-query-kb` and `/aid-update-kb`

`/aid-query-kb` is an on-demand skill that answers free-form questions about your project from the Knowledge Base, the codebase, and in-flight works, with source citations. When the context cannot answer, it captures the gap as a Query-Gap entry in the KB's Q&A backlog so it feeds the KB-improvement loop. Write scope is restricted to the gap-capture path — no KB doc or code file is ever written.

`/aid-update-kb` is an on-demand targeted KB update skill. Give it a free-form prompt describing what changed and it applies the delta to the affected KB docs through the same review/calibration gate as `/aid-discover`. Human-gated — it commits only after your explicit approval.

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

AID does not make you weigh the cost of the full pipeline against the size of a change yourself — that trade-off is automated. For a small, well-scoped change, skip the full pipeline entirely: name it with a verb-first shortcut (`/aid-fix`, `/aid-create-api`, `/aid-change-cli`, …) — one of 64 shortcuts spanning the shortcut families (create · change · fix · refactor · remove · deprecate · migrate · test · experiment · prototype · design · document · report · dashboard · review · research) — and the shared shortcut engine collapses Describe → Define → Specify → Plan → Detail into one fast, mostly-autonomous run, then halts for your approval. Each shortcut is bound to one specific change type, so the engine already knows the shape of the work and skips the generic elicitation a from-scratch interview would need — that's what makes it fast, not just short.

Not sure which shortcut fits, or is the change broad or multi-part? `/aid-triage` reads a free-form description and suggests either the matching shortcut or the full `/aid-describe` path. Just asking a question instead of proposing a change? `/aid-triage` points you to `/aid-ask` instead. Either way, nothing runs until you approve it.

This is not a shortcut that skips quality — it's proportionate rigour. The lite path still produces the full artifact set (`REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`, `BLUEPRINT.md`, `DETAIL.md`) and grades every document at GATE — an A+ floor by default — before the approval halt.

[The Lite path and the shortcut engine →](docs/aid-methodology.md#2-philosophy)

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
