---
kb-category: primary
notes: "Retired as project-type profile selector (feature-015/Change 1). Content recast
        as rendering hints for CLI-domain KB docs, keyed by kb-category tier and doc
        identity — not by project-type. The section set is derived from the resolved
        doc-set + frontmatter, not from this template."
---

# Rendering Hints — CLI Domain Docs

> **Status:** Retired as a project-type profile selector (feature-015, Change 1).
> Profile-as-project-type auto-detection is replaced by the doc-set/domain-driven
> section derivation in `state-profile.md`. This file is now a **rendering hint
> reference** for GENERATE when the domain facets include `software-cli` or `cli-tool`
> and the resolved doc-set contains the listed docs.

---

## Original section structure (preserved as rendering reference)

The following layout was the CLI profile's fixed section order. It is **not selected as a
template**; it is kept as domain-specific rendering guidance for how to frame specific
KB docs when the domain is CLI-oriented. The resolved doc-set order (from `state-profile.md`
§4) is authoritative; these hints apply within each section once determined.

For command-line tools (e.g., `gh`, `terraform`, `aws-cli`-style). Subcommand
catalog replaces "API surface".

## Sections

| # | Title | Featured? | KB Sources |
|---|-------|-----------|------------|
| 1 | At a Glance | | STATE.md, project-structure.md, technology-stack.md |
| 2 | Architecture | ★ | architecture.md |
| 3 | Subcommand Catalog | ★ | pipeline-contracts.md |
| 4 | Internal Modules | | module-map.md |
| 5 | Data Schemas | | schemas.md |
| 6 | Inputs & Outputs | | integration-map.md |
| 7 | Configuration | | technology-stack.md, infrastructure.md |
| 8 | Test Landscape | | test-landscape.md |
| 9 | Tech Debt | | tech-debt.md |
| 10 | Build & Distribution | | infrastructure.md |
| 11 | Concept Spine | | domain-glossary.md |
| 12 | Knowledge Base Index | | INDEX.md |

## Diagrams

| Fig | Type | Subject |
|-----|------|---------|
| 1 | flowchart TB | Stack: terminal → CLI binary → core library → external services |
| 2 | graph TD | Subcommand tree (`tool` → `tool subcmd1` → `tool subcmd1 verb`) |
| 3 | flowchart LR | Command pipeline (parse args → load config → execute → format output) |
| 4 | flowchart LR | Inputs (stdin, files, env, args) and outputs (stdout, stderr, files, exit codes) |

## Section content guidance

### §3 Subcommand Catalog (FEATURED)
Hierarchical tree of all subcommands. Each row:
- Command path (e.g., `gh pr create`)
- Synopsis
- Key flags
- Status (stable / experimental / deprecated)

Use a nested accordion grouped by top-level command.

### §4 Internal Modules
Lighter than web-app — usually just a few core packages.

### §5 Data Model
Mostly config schemas, request/response shapes for any APIs the CLI calls,
and state files (e.g., `~/.config/...`).

### §6 Inputs & Outputs
Table:
| Channel | Type | Format | Notes |
|---|---|---|---|
| stdin | Input | JSON / YAML / text | If piped |
| flags | Input | KV | See subcommand catalog |
| env vars | Input | KV | List well-known env vars (e.g., `TOOL_TOKEN`) |
| stdout | Output | text / JSON | Mode-dependent |
| stderr | Output | text | Errors and progress |
| Exit codes | Output | int | 0 = success; non-zero = specific failure category |

### §7 Configuration
Where config lives (`~/.config/X`, project-local files), schema, precedence
rules.

### §10 Build & Distribution
Build commands + binary distribution (homebrew, scoop, github releases, npm,
direct download).

### §11 Concept Spine

The project's native vocabulary — domain-specific and coined terms you must know to use
and maintain the CLI. Drawn from `domain-glossary.md` (the C4 ubiquitous-language doc).

For a CLI, include: any coined subcommand names whose meaning is not obvious from the
verb alone, project-specific config key names, non-standard exit-code semantics, and
internal state-machine terms (e.g. "workspace", "context", "lock file"). Render as a
scannable definition list:

- **{term}** — {one-line definition in this project's context}

If `domain-glossary.md` is absent or empty, render a minimal placeholder; do not omit
the section. Wrap command-name terms in `<code>`.

## Skipped sections (vs web-app)

- ✗ API Surface (replaced by Subcommand Catalog)
- ✗ Frontend Architecture
- ✗ Integration Hub (CLIs typically don't have one — replaced by Inputs/Outputs)

## CLI-specific palette adjustments

Use a monospace look for command examples — wrap them in `<code>` or `<pre>`.
The `--accent` color works well for command names; `--text-muted` for prose.
