# Section Template — `cli` Profile

For command-line tools (e.g., `gh`, `terraform`, `aws-cli`-style). Subcommand
catalog replaces "API surface".

## Sections

| # | Title | Featured? | KB Sources |
|---|-------|-----------|------------|
| 1 | At a Glance | | DISCOVERY-STATE.md, project-structure.md, technology-stack.md |
| 2 | Architecture | ★ | architecture.md |
| 3 | Subcommand Catalog | ★ | api-contracts.md |
| 4 | Internal Modules | | module-map.md |
| 5 | Data Model | | data-model.md |
| 6 | Inputs & Outputs | | integration-map.md |
| 7 | Configuration | | technology-stack.md, infrastructure.md |
| 8 | Test Landscape | | test-landscape.md |
| 9 | Tech Debt | | tech-debt.md |
| 10 | Build & Distribution | | infrastructure.md |
| 11 | Knowledge Base Index | | INDEX.md |

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

## Skipped sections (vs web-app)

- ✗ API Surface (replaced by Subcommand Catalog)
- ✗ Frontend Architecture
- ✗ Integration Hub (CLIs typically don't have one — replaced by Inputs/Outputs)

## CLI-specific palette adjustments

Use a monospace look for command examples — wrap them in `<code>` or `<pre>`.
The `--accent` color works well for command names; `--text-muted` for prose.
