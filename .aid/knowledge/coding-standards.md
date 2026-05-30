---
kb-category: primary
source: hand-authored
intent: |
  Mines the de-facto coding conventions used across the AID repo by reading
  the actual code: SKILL.md frontmatter shape, AGENT.md authoring pattern,
  Python style in the renderer, Bash style in the helper scripts, Markdown
  conventions inside skill/agent bodies, and the cross-cutting rules from
  CLAUDE.md + canonical/templates/kb-authoring/principles.md. Read this when
  you are authoring a NEW skill, agent, script, template, recipe, or KB doc
  and need the existing-style fingerprint. NOT a tech-stack overview (see
  architecture.md) and NOT a per-doc review rubric (see
  canonical/templates/kb-authoring/review-rubric.md).
contracts:
  - "Every aid-* SKILL.md begins with a YAML frontmatter block containing name, description, allowed-tools (and optionally argument-hint)"
  - "Every canonical AGENT.md begins with a YAML frontmatter block containing at minimum name, description, tier, tools (per canonical/agents/architect/AGENT.md:1-6)"
  - "Every KB doc begins with a YAML frontmatter block containing kb-category, source, intent (per canonical/templates/kb-authoring/frontmatter-schema.md:46-89)"
  - "Every helper script declares set -euo pipefail (or set -uo pipefail with documented rationale)"
  - "Every helper script supports -h | --help that prints its own header comment via sed"
changelog:
  - 2026-05-27: Initial generation by discovery-analyst (cycle-1)
---

# Coding Standards

> All conventions below are inferred from current code unless they cite a
> document that explicitly normatively asserts them (frontmatter-schema.md,
> principles.md, CLAUDE.md). Confirmed assertions are tagged **CONFIRMED**;
> inferred ones are not tagged.

---

## 1. Languages + Where They Live

| Language | Where | Style fingerprint |
|----------|-------|-------------------|
| Python 3.11+ | `.claude/skills/aid-generate/scripts/*.py` + `run_generator.py` | PEP 8 + `from __future__ import annotations`, type hints, `@dataclass`, `Path` over `os.path`, stdlib-only |
| Bash | `canonical/scripts/**/*.sh` + `setup.sh` + `tests/**/*.sh` | `#!/usr/bin/env bash` + `set -euo pipefail` (rare `set -uo pipefail` with rationale), POSIX-portable, 4-space indent inside `case`, sentinel-file locks for parallel-write safety |
| JavaScript (ESM) | `canonical/scripts/summarize/{validate-diagrams,contrast-check}.mjs` + `canonical/templates/knowledge-summary/{lightbox,mermaid-init}.js` | `#!/usr/bin/env node` for CLI scripts, `import` syntax, top-level `await`, Node stdlib only |
| PowerShell | `setup.ps1` + `canonical/scripts/summarize/concatenate.ps1` | Windows-host installer + concatenation helper; explicit `param()` blocks |
| Markdown | All skill bodies, agent bodies, templates, KB docs | YAML frontmatter delimited by `---`; GitHub-flavored tables; fenced code blocks with language identifiers |
| YAML | `canonical/templates/settings.yml` + `.aid/settings.yml` | YAML 1.2 (per `canonical/templates/settings.yml:8`); commented blocks above each section |
| TOML | `profiles/*.toml` + `profiles/codex/.codex/agents/*.toml` | TOML 1.0; sectioned with comments above each `[section]` |

---

## 2. Naming Conventions

### 2a. File + directory names

- **All `aid-*` skill directories are kebab-case** with the `aid-` prefix: `aid-config`, `aid-discover`, `aid-execute`, etc. (per `canonical/skills/`).
- **All agent directories are kebab-case**, single-word or compound: `architect`, `developer`, `discovery-analyst`, `simple-extractor` (per `canonical/agents/`).
- **Skill state files are `state-<state-name>.md`** — lowercase kebab-case state name, e.g., `state-generate.md`, `state-q-and-a.md`, `state-delivery-gate.md` (per `canonical/skills/aid-discover/references/`).
- **Helper scripts are kebab-case verb-noun** with `.sh` (or `.mjs` / `.ps1`) extension: `read-setting.sh`, `build-project-index.sh`, `compute-block-radius.sh`, `writeback-task-status.sh`, `validate-diagrams.mjs`, `contrast-check.mjs`.
- **Python files are snake_case** with `.py` extension: `render_agents.py`, `verify_deterministic.py`, `test_manifest_safety.py`, `run_generator.py`.
- **Templates are kebab-case** with `.md` extension: `task-template.md`, `discovery-state-template.md`, `recipe-template.md`, `subagent-heartbeat-protocol.md`.
- **Capitalized markdown filenames** are reserved for project-root files (`CLAUDE.md`, `README.md`, `CONTRIBUTING.md`, `LICENSE`) and for inside-work artifacts (`SPEC.md`, `PLAN.md`, `REQUIREMENTS.md`, `STATE.md`, `INDEX.md`, `AGENT.md`, `SKILL.md`, `IMPEDIMENT.md`, `EMISSION-MANIFEST.md`).
- **Generated files live under `.aid/generated/`** with kebab-case names: `project-index.md`, `metrics.md`, `INDEX.md` (note: `INDEX.md` keeps its capitalized form even when generated).

### 2b. Inside Python

- `snake_case` for functions, methods, module-level variables (per `.claude/skills/aid-generate/scripts/harness.py:67` `sha256_hex`, `:88` `substitute_filenames`).
- `PascalCase` for dataclasses (per `profile.py:28-29` `LayoutConfig`, `:108-109` `FrontmatterConfig`).
- `_LEADING_UNDERSCORE` for module-private constants + helpers (per `harness.py:36` `_MANIFEST_VERSION`, `:48` `_PLACEHOLDER_RE`, `:57` `_CANONICAL_PATH_DIRS`).
- `SCREAMING_SNAKE` reserved for top-level constants when not module-private — none observed; the renderer uses `_LEADING_UNDERSCORE` exclusively.

### 2c. Inside Bash

- `UPPER_SNAKE_CASE` for environment-overridable config variables: `STATE_FILE`, `TASKS_DIR`, `DELIVERY_ISSUES_DIR`, `LOCK_DIR`, `LOCK_TIMEOUT` (per `canonical/scripts/execute/writeback-task-status.sh:46-50`).
- `UPPER_SNAKE_CASE` for argument-bound locals: `KB_DIR`, `ROOT`, `FORMAT`, `SKIP_STATE`, `QUIET`; `SETTINGS_FILE`, `SKILL`, `KEY`, `DPATH`, `DEFAULT` (per `canonical/scripts/config/read-setting.sh:46-51`).
- `lower_snake_case` for shell functions: `usage()`, `die()`, `warn()`, `build_prune_expr()`, `get_mtime()` (per `canonical/scripts/interview/parse-recipe.sh:68-73`, `kb/build-project-index.sh:55,73,75`).
- Env-prefix convention `AID_*` for env-overridable defaults: `AID_STATE_FILE`, `AID_TASKS_DIR`, `AID_DELIVERY_ISSUES_DIR`, `AID_LOCK_DIR`, `AID_LOCK_TIMEOUT`, `AID_PARSE_RECIPE_LOCK_TIMEOUT` (per `writeback-task-status.sh:46-50`, `parse-recipe.sh:65`).

### 2d. Inside Markdown (skill + agent + KB bodies)

- **Sections:** `## Title Case` for top-level inside a doc; `### Title Case` for sub-sections.
- **States in skill bodies:** UPPERCASE in narrative text (e.g., "State machine: GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE" per `canonical/skills/aid-discover/SKILL.md:7`), kebab-lowercase in filenames (`state-q-and-a.md`).
- **Task types:** UPPERCASE (RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, CONFIGURE per `canonical/skills/aid-execute/references/state-execute.md:6-16`, `canonical/templates/delivery-plans/task-template.md:3`).
- **Severity tags:** UPPERCASE bracketed: `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]`, `[MINOR]` (per `canonical/agents/reviewer/AGENT.md:54-62`, `canonical/scripts/grade.sh:5-7`).
- **Source tags (for review findings):** UPPERCASE bracketed: `[CODE]`, `[TASK]`, `[SPEC]`, `[KB]`, `[ARCHITECTURE]` (per `canonical/agents/reviewer/AGENT.md:37`).
- **Work + delivery IDs:** zero-padded 3-digit, kebab-prefixed: `work-001`, `work-002-canonical-generator`, `delivery-001`, `task-001`, `feature-005` (per `canonical/templates/work-state-template.md`).

---

## 3. File-Level Conventions

### 3a. Frontmatter (CONFIRMED for KB docs per `canonical/templates/kb-authoring/frontmatter-schema.md:6-7`)

Every authored markdown artifact begins with a YAML frontmatter block delimited by `---` markers. There are three frontmatter shapes:

**KB doc frontmatter** (per `canonical/templates/kb-authoring/frontmatter-schema.md:14-26`):
```yaml
---
kb-category: primary | meta | extension
source: hand-authored | generated
generator: <script-name>          # required iff source: generated
intent: |
  One paragraph (1-4 sentences) describing what this doc is FOR.
contracts:
  - "Structural cardinality claim 1"
changelog:
  - YYYY-MM-DD: change description
---
```

**Agent frontmatter** (per `canonical/agents/architect/AGENT.md:1-6`):
```yaml
---
name: <agent-name>
description: <one-paragraph description>
tier: large | medium | small
tools: Read, Glob, Grep, Bash, Write, Edit
permissionMode: bypassPermissions    # optional — set on discovery-* sub-agents
background: true                     # optional — set on discovery-* sub-agents
---
```

**Skill frontmatter** (per `canonical/skills/aid-discover/SKILL.md:1-10`):
```yaml
---
name: aid-<skill>
description: >
  Multi-line folded description.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[--flag] description of flag"
---
```

Per `frontmatter-schema.md:7`, **the entire KB frontmatter block is exempt from
review** (per principle P6).

### 3b. Bash script header

Every helper script under `canonical/scripts/` follows a fixed header pattern (per `canonical/scripts/execute/writeback-task-status.sh:1-50`, `canonical/scripts/config/read-setting.sh:1-43`, `canonical/scripts/interview/parse-recipe.sh:1-60`, `canonical/scripts/grade.sh:1-23`):

```bash
#!/usr/bin/env bash
# <script-name> — one-line tagline.
#
# Purpose:
#   <one-paragraph what this script does and why>.
#
# Usage:
#   <script-name> --flag1 VALUE [--flag2]
#       <description of mode 1>
#
#   <script-name> --flag3
#       <description of mode 2>
#
# Exit codes:
#   0  success
#   1  <named failure 1>
#   2  <named failure 2>
#
# Output:
#   stdout: <what stdout carries on success>
#   stderr: <what stderr carries on failure>

set -euo pipefail
```

**Variant:** scripts that intentionally tolerate command failures use
`set -uo pipefail` (no `-e`) — this pattern applies when a script runs many
checks and must continue past per-check failures; rationale should be documented
in the script's header comment.

**Variant:** `canonical/scripts/execute/writeback-task-status.sh:41` uses `set
-u` only (no `-e`, no `-o pipefail`) — because it does mode-dispatch and
returns specific exit codes per mode failure (codes 1-6 per lines 32-40).

### 3c. Bash script help mode

Every script supports `-h | --help` and renders its own header comment by
piping the file's top block through `sed` (per `canonical/scripts/execute/writeback-task-status.sh:53-55`,
`canonical/scripts/grade.sh:36-39`):

```bash
-h|--help)
  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
  ;;
```

The convention is to strip the leading `# ` prefix so the comment block reads as plain help text.

### 3d. Bash argument parsing

Every multi-arg script uses the same `while [[ $# -gt 0 ]] / case` pattern (per
`canonical/scripts/config/read-setting.sh:53-79`,
`canonical/scripts/execute/writeback-task-status.sh:71-108`,
`canonical/scripts/interview/parse-recipe.sh:83-100`,
`canonical/scripts/kb/build-project-index.sh:26-40`,
`canonical/scripts/grade.sh:26-49`):

```bash
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)        usage; exit 0 ;;
        --flag1)          FLAG1="$2"; shift 2 ;;
        --bool-flag)      BOOL_FLAG=1; shift ;;
        *)                die "unknown flag: $1" 5 ;;
    esac
done
```

`shift 2` consumes a flag + its value; `shift` consumes a bare boolean flag.

### 3e. Python script header

Every Python file starts with a shebang + module docstring-style comment + `from __future__ import annotations` (per `.claude/skills/aid-generate/scripts/harness.py:1-16`, `profile.py:1-13`, `render_agents.py:1-14`, `render_skills.py:1-14`):

```python
#!/usr/bin/env python3
# <module>.py — one-line tagline.
#
# Purpose:
#   <multi-line purpose>.
#
# Usage:
#   python <module>.py --flag VALUE
#
# Requirements: Python 3.11+ (tomllib is stdlib; no third-party deps)
from __future__ import annotations
```

Note: comment block instead of triple-quoted docstring for the file header.
Triple-quoted docstrings are reserved for function + class signatures (per
`harness.py:67-81` `sha256_hex` docstring).

---

## 4. Error Handling

### 4a. Bash

- **`die() / warn()` pattern** (per `canonical/scripts/interview/parse-recipe.sh:72-73`, `canonical/scripts/execute/writeback-task-status.sh:57`):
  ```bash
  die()  { echo "ERROR: <script>: $*" >&2; exit "${2:-1}"; }
  warn() { echo "WARN: <script>: $*" >&2; }
  ```
- **Exit codes are documented + meaningful per script** (per the headers cited in §3b). 0 = success; 1 = generic failure; 2 = usage error; 3+ = script-specific failure classes.
- **Errors go to stderr; results go to stdout** (CONFIRMED per `canonical/scripts/config/read-setting.sh:33-36`).
- **Trap cleanup** for temp files: `trap 'rm -f "$F1" "$F2"' EXIT` declared right before the first `mktemp`, with all slots pre-initialized to empty strings so the trap is safe to fire at any exit point (per `canonical/scripts/interview/parse-recipe.sh:64-66` and `canonical/scripts/execute/writeback-task-status.sh`).

### 4b. Python

- **Renderer raises `ValueError`** for misconfigured profiles (per `.claude/skills/aid-generate/scripts/profile.py:72-74`, `:101-104`). The validator helper `validate(profile)` returns a list of errors instead of raising — the caller decides whether to abort (per `run_generator.py:26-29`).
- **No bare `except:` clauses observed** — all caught exceptions are scoped (e.g., `except OSError:` per `run_generator.py:63` for `parent.rmdir()` during tree pruning).
- **`sys.exit(1)` on render failure with stderr message** (per `run_generator.py:28-29`, `:78-79`). No traceback suppression.

### 4c. Markdown / KB docs

- **Findings carry severity + source tags** (per `canonical/agents/reviewer/AGENT.md:64-69`):
  ```
  [SEVERITY] [SOURCE] Description | File:Line | Criterion violated
  ```
- **Impediments are formal artifacts** at `.aid/{work}/task-NNN/IMPEDIMENT.md` (per `canonical/templates/feedback-artifacts/IMPEDIMENT.md:1-9`). Four types: `wrong-assumption`, `missing-dependency`, `architecture-conflict`, `kb-gap` (per `IMPEDIMENT.md:20-23`).

---

## 5. Logging + Progress

The AID repo has no application logging (no application code). Two related conventions exist for in-pipeline visibility:

### 5a. Subagent heartbeat (L3)

Every long-running subagent dispatch writes a single-line progress note to a per-dispatch file under `.aid/.heartbeat/<agent>-<unix-ts>.txt` (per `canonical/templates/subagent-heartbeat-protocol.md:1-12`, `canonical/agents/discovery-analyst/AGENT.md:11-34`). The line format is:

```
[YYYY-MM-DDTHH:MM:SSZ] <STATE> | <progress> | <activity> (~<eta-remaining>)
```

Conventions (per `canonical/agents/architect/AGENT.md:17-30`):
- Use `>` (overwrite), never `>>` (append).
- Activity must change between updates — repetition signals "stuck" to the orchestrator.
- Use `unknown` if eta-remaining cannot be predicted.
- Timestamp MUST come from a shell command (`$(date -u +%Y-%m-%dT%H:%M:%SZ)`), never typed in the agent's reply.

### 5b. Long-wait L2 timers (orchestrator-side)

Skills that dispatch subagents arm three L2 timers per dispatch as separate background Bash calls, each on its own `run_in_background: true` task — never chained with `&` inside a single wrapper (per `canonical/skills/aid-discover/SKILL.md:89-93`). The three timers fire at `LOW/2`, `LOW`, and `1.5×LOW` of the rough-time estimate, allowing the user to see mid-wait progress instead of going silent for 10-25 minutes.

### 5c. Calibration log (always-on)

Every successful dispatch appends a row to `STATE.md ## Calibration Log` with format `| YYYY-MM-DD | <agent> | <task-id/cycle> | <ETA-band> | <actual> | <notes> |` (per `canonical/skills/aid-discover/SKILL.md:103-108`). Unconditional per work-003 traceability.

---

## 6. Configuration

### 6a. Single source of truth: `.aid/settings.yml`

All AID runtime settings live in `.aid/settings.yml` (per `canonical/templates/settings.yml:1-9`). The file is YAML 1.2 with these sections:

- `project:` — `name`, `description`, `type` (brownfield/greenfield)
- `tools:` — `installed:` list (claude-code/codex/cursor)
- `review:` — `minimum_grade:` (global default)
- `execution:` — `max_parallel_tasks:` (parallel pool capacity)
- `traceability:` — `heartbeat_interval:` (minutes; 0 = disabled)
- Optional per-skill overrides: `discover:`, `summary:`, `interview:`, `specify:`, `plan:`, `detail:`, `execute:`, `deploy:`, `monitor:` — each may set `minimum_grade:`

### 6b. Settings resolution

Skills read settings via `bash canonical/scripts/config/read-setting.sh`, which implements per-skill override resolution: per-skill key (e.g., `discover.minimum_grade`) → global category default (`review.minimum_grade`) → hardcoded fallback supplied via `--default` (per `canonical/scripts/config/read-setting.sh:4-17`). Two invocation modes:

- `--skill <name> --key <key>` (override-aware) — for grade-style resolution.
- `--path <a.b.c>` (direct dotted-path) — for non-overridable keys like `execution.max_parallel_tasks`.

### 6c. Hard-coded defaults

When `.aid/settings.yml` is absent, callers fall back to `--default` values:
- `traceability.heartbeat_interval` → `1` (minute) per `canonical/templates/subagent-heartbeat-protocol.md:21`.
- `execution.max_parallel_tasks` → `5` per `canonical/skills/aid-execute/references/state-execute.md:49`.
- `review.minimum_grade` → `A` per `canonical/templates/settings.yml:38`.

### 6d. No secrets in repo

There are no `.env` files, no credential templates, no secrets handling (CONFIRMED — repo has no application code and no integration with external services). The only `JSON` configs are Claude-Code permission scopes (`.claude/settings.json`; `.claude/settings.local.json` (gitignored per `.gitignore:44`)).

---

## 7. File Organization

### 7a. Single-source canonical → multi-tree render

**Never edit `profiles/{claude-code,codex,cursor}/` directly** (CONFIRMED per `canonical/EMISSION-MANIFEST.md` §Safety-Boundary Semantics). Edit `canonical/` and run `python run_generator.py`. The render emits byte-identical bodies across:

- `canonical/` (source)
- `.claude/` (dogfood install)
- `profiles/claude-code/.claude/`
- `profiles/codex/.codex/` + `profiles/codex/.agents/` (split layout)
- `profiles/cursor/.cursor/`

### 7b. Thin-router skill decomposition (CONFIRMED per `canonical/skills/*/SKILL.md` structure)

When a `SKILL.md` grows past ~200 lines, extract per-state bodies into `references/state-{name}.md`; keep the router as Dispatch table + Pre-flight + State Detection only. Total skill body lines: 2,242 across 10 skills (was 4,467 pre-refactor — 53% reduction) per `metrics.md`.

### 7c. Co-location of state files

State references live alongside their skill: `canonical/skills/aid-discover/references/state-{approval,done,fix,generate,q-and-a,review}.md`. Naming pattern: `state-<lower-kebab-state-name>.md`.

### 7d. Per-script + per-test colocation

- Helper scripts live under `canonical/scripts/<category>/<script>.sh`. Each script has byte-identical copies in 4 trees (per §7a). Tests live at `tests/canonical/<script-name>.sh`.
- The `tests/skills/` directory was deleted in cycle-1 (Q6 resolution). No skill-level e2e tests exist; the 7 canonical/ suites are the complete test inventory.

### 7e. Area-STATE consolidation (FR2, CONFIRMED per `canonical/templates/discovery-state-template.md`)

Each `.aid/{work}/STATE.md` is the per-area state hub; legacy per-feature `STATE.md` and per-task `STATE.md` files are retired. The discovery area has its own state at `.aid/knowledge/STATE.md` (per `canonical/templates/discovery-state-template.md:1-10`).

### 7f. Single-branch work (CONFIRMED — observed convention; see `tech-debt.md` H1 history)

Commit work-NNN to ONE persistent branch (off master); no per-task worktrees or branches. Worktree sprawl caused PR #12 to lose 63 commits; recovered via PR #13.

---

## 8. Code Style + Idioms

### 8a. Python

- **`pathlib.Path` over `os.path`** (per `.claude/skills/aid-generate/scripts/harness.py:24`, `profile.py:20`, `render_agents.py:20`).
- **`@dataclass` for value objects** (per `profile.py:28,108,118` `LayoutConfig`, `FrontmatterConfig`, `AgentConfig`).
- **`tomllib` stdlib for TOML parsing** (per `profile.py:18`) — no third-party `toml` package.
- **`hashlib.sha256` for content fingerprints** (per `harness.py:67-81`) — used for `EmissionManifest` sha256 field.
- **Type hints throughout** (per `harness.py:67` `def sha256_hex(data: bytes) -> str`, `:88` `def substitute_filenames(body: str, filename_map: dict[str, str]) -> str`).
- **PEP 604 union syntax** (`X | None` not `Optional[X]`) per `profile.py:30-32,46`.
- **`TYPE_CHECKING` guard** for type-only imports (per `harness.py:25-28`).
- **Compiled regex constants at module scope** with leading-underscore name (per `harness.py:48-50` `_PLACEHOLDER_RE`, `:58-60` `_CANONICAL_PATH_RE`).

### 8b. Bash

- **POSIX-portable**: scripts must run on Linux, macOS (Big Sur+), and Windows Git Bash (per `canonical/scripts/interview/parse-recipe.sh:3-7`). Avoid GNU-only flags.
- **Platform-detection via `stat --version`** to pick between GNU coreutils and BSD stat (per `canonical/scripts/kb/build-project-index.sh:73-80`).
- **Sentinel-file locking for parallel-write safety** (per `canonical/scripts/execute/writeback-task-status.sh:8-9`, `canonical/scripts/interview/parse-recipe.sh:34-35`). Uses `set -o noclobber + atomic create + sleep-poll retry` rather than `flock` (not portable to Windows Git Bash).
- **`mktemp` + EXIT trap** for temp files (per `canonical/scripts/interview/parse-recipe.sh:64-66`).
- **AWK for line-level transforms** instead of `sed` when state is needed (per `canonical/scripts/grade.sh:73-76` — fence-detection awk).
- **No `realpath` or other GNU-only utilities** observed; portability is preserved.

### 8c. Markdown

- **GitHub-flavored tables** (`| col | col |` with `|---|---|` separator) — universally used for structured data (per any `.md` in the repo).
- **Fenced code blocks with language identifier** (e.g., ` ```bash`, ` ```yaml`, ` ```python`) per `canonical/agents/architect/AGENT.md:17-25`.
- **One-sentence-per-line is NOT used** — prose flows naturally; bullets are used where a list is semantically correct.
- **Bold + arrow `→` for state transitions** (e.g., "GENERATE → REVIEW → FIX" per `canonical/skills/aid-discover/SKILL.md:7`).
- **Bullet style `-` (hyphen)** not `*` (asterisk). Consistent across all KB docs and skill bodies.

### 8d. State machine convention (CONFIRMED per `canonical/skills/aid-discover/SKILL.md:54-59`)

Each skill state machine is documented as a Dispatch table with these columns: `State | Detail | Worker | Advance` (per `canonical/skills/aid-discover/SKILL.md:213-219`). Advance follows one of three forms:

- **Unconditional** — always advance to the next state on exit.
- **Halt** — the state ends the run (terminal state).
- **Conditional** — advance based on a computed criterion (e.g., grade ≥ minimum → APPROVAL, else → FIX).

### 8e. Agent-authoring (CONFIRMED structure per all 22 `AGENT.md` files)

Every canonical agent body follows this section order:

1. YAML frontmatter (5-7 keys per §3a).
2. One-paragraph identity ("You are the X — the Y specialist in the AID pipeline.").
3. `## Heartbeat protocol` (byte-identical block; absent on simple-* utilities and `interviewer`).
4. `## Self-review discipline` (byte-identical block; absent on `simple-*` utilities, `interviewer`, `orchestrator`, `reviewer`, `security`, `ux-designer`, `performance`, `devops`, `data-engineer`, `tech-writer`, `researcher` — present on `architect`, `developer`, `discovery-*`, `operator`).
5. `## What You Do` (bullet list).
6. `## What You Don't Do` (bullet list).
7. `## Key Constraints` (bullet list).
8. `## Output Format` (per agent).
9. `## When to Escalate` (bullet list).

---

## 9. KB Authoring Principles (CONFIRMED per `canonical/templates/kb-authoring/principles.md`)

Seven principles govern all `.aid/knowledge/*.md` authoring:

- **P1.** No drift-prone information unless it carries semantic value. Three banned classes: (a) cosmetic counting, (b) dates without semantic anchor, (c) other low-value clutter.
- **P2.** Proper metric: when a numerical fact IS load-bearing, it must (a) serve a concrete purpose, (b) be measured before registering, (c) never be retroactively changed.
- **P3.** Plan first, change later. Review and fix are SEPARATE phases. Use the `.aid/.temp/review-pending/<skill>.md` ledger pattern.
- **P4.** Enforce via lint, not convention. The `discovery-reviewer` sub-agent in `/aid-discover REVIEW` state validates KB citations, frontmatter compliance, and contract assertions (see `canonical/agents/discovery-reviewer/AGENT.md`).
- **P5.** Mark auto-generated / temporary files clearly. Generated files carry HTML comment + `source: generated` frontmatter; temporary files live under `.aid/.temp/` and are never reviewed.
- **P6.** Per-doc review metadata via frontmatter. The whole frontmatter block is exempt from review.
- **P7.** Review is read-only on the repo. `/aid-discover` and discovery skills WRITE only to `.aid/knowledge/`, `.aid/generated/`, `.aid/.temp/`.

### 9a. Fact stability tiers (T1-T4, CONFIRMED per `canonical/templates/kb-authoring/tier-model.md`)

Every claim in a KB doc belongs to one tier:

| Tier | What | Inline allowed? | Where it lives |
|------|------|-----------------|----------------|
| **T1 Concept** | Patterns, definitions, architectural laws | YES — this IS the knowledge | Inline in primary docs |
| **T2 Structure** | Cardinality contracts, schemas, named-list assertions | YES — when load-bearing | Inline + declared in `contracts:` frontmatter; lint enforces |
| **T3 Metric** | Line counts, byte counts, function counts | **NO** — banned from primary docs | `.aid/generated/metrics.md` only, regenerated by `build-metrics.sh` |
| **T4 Temporal** | Dates, cycle tags, "as of X" | **NO** — banned from primary docs | Frontmatter `changelog:` + `STATE.md` history sections |

---

## 10. Convention vs. Docs — Where They Match (or Drift)

Docs that describe a convention vs. what code actually does:

| Convention | Documented at | Code confirms? | Notes |
|------------|---------------|----------------|-------|
| Thin-Router SKILL.md ≤~360 lines | `coding-standards.md §7b`; `canonical/skills/*/SKILL.md` structure | YES — all 10 user-facing skills fit under the threshold; the largest is `aid-interview`. Per-file line counts live in `.aid/generated/metrics.md` / `project-index.md` | Confirmed |
| 22 agents, 3 tiers | `README.md:178-198` | YES — confirmed via 22 `AGENT.md` files with `tier: large|medium|small` frontmatter | Confirmed |
| 15 active KB docs (was 16) | `canonical/skills/aid-discover/SKILL.md:145-149` | YES — list updated in Q3 FIX: 14 retained from standard 16 (removed: security-model, ui-architecture; renamed: data-model → schemas, api-contracts → pipeline-contracts) + 1 new custom (repo-presentation, replaces ui-architecture) = 15 | Confirmed |
| 8-task-type catalog | `canonical/skills/aid-execute/references/state-execute.md:6-16`; `canonical/templates/delivery-plans/task-template.md:3` | YES — both lists match: RESEARCH/DESIGN/IMPLEMENT/TEST/DOCUMENT/MIGRATE/REFACTOR/CONFIGURE | Confirmed |
| 5 grade severity tags | `canonical/agents/reviewer/AGENT.md:54-62`; `canonical/scripts/grade.sh:5-7` | YES — [CRITICAL]/[HIGH]/[MEDIUM]/[LOW]/[MINOR] match in both | Confirmed |
| 4 lite-path sub-paths | `canonical/templates/work-state-template.md:19`, `canonical/templates/recipe-template.md:90-93` | YES — sub-path enum present in both | Confirmed |
| Heartbeat interval = 1 minute default | `canonical/templates/settings.yml:50`; `canonical/templates/subagent-heartbeat-protocol.md:21` | YES — both state default 1 minute | Confirmed |
| Max parallel tasks = 5 default | `canonical/templates/settings.yml:44`; `canonical/skills/aid-execute/references/state-execute.md:49` | YES — both state default 5 | Confirmed |
| Calibration Log unconditional | `canonical/skills/aid-discover/SKILL.md:103-108` | Code requires it; always-on per work-003 traceability | Confirmed — matches user feedback "Traceability unconditional" |
| Single-branch work | User memory `feedback_single-branch-work.md`; `tech-debt.md` H1 history | (No code enforcement — observed convention only) | Inferred from convention doc; lint does not check |

⚠️ Inferred from code — needs confirmation: no static lint rule enforces the
single-branch work convention or the Thin-Router line ceiling. Both are
convention + reviewer judgment, not mechanically verified.

---

## 11. Security-By-Design Conventions

This section consolidates security-relevant authoring conventions applicable to
this repo. AID has no application runtime, so the surface reduces to: what gets
committed, how shell scripts handle input, and what tools each agent may invoke.

### 11a. `.gitignore` exclusion policy (CONFIRMED)

The following paths MUST remain gitignored (per `.gitignore:18-47`):

- `.aid/.heartbeat/` — ephemeral per-subagent heartbeat files; accumulate and
  pollute history. Confirmed gitignored at `.gitignore:46-47`; `git check-ignore
  -v .aid/.heartbeat/` returns line 47.
- `.aid/.temp/` — excluded by an explicit `.gitignore` directory entry
  (rename-resilient), in addition to the `*.temp` glob that also matches it.
- `.aid/knowledge/.cache/` — KB build cache; must not be tracked.
- IDE/editor files (`.idea/`, `.vscode/`, `*.iml`, etc.) — per `.gitignore:18-30`.
- `.claude/settings.local.json` — per-developer Claude Code overrides; excluded
  at `.gitignore:44`. Not a credentials file (the repo has no credentials) but
  excluded to prevent accidental personal-preference commits.

### 11b. Shell script safety discipline (CONFIRMED)

Every canonical helper script under `canonical/scripts/` declares
`set -euo pipefail` at the top (per `canonical/scripts/config/read-setting.sh:44`
as the exemplar). Exceptions are documented in §3b above:

- `set -uo pipefail` (no `-e`) when the script runs many checks and must
  continue past per-check failures (pattern: `canonical/scripts/kb/build-project-index.sh`).
- `set -u` only (no `-e`, no `-o pipefail`) when the script does explicit
  mode-dispatch with named exit codes (e.g., `writeback-task-status.sh:41`).

The principle: **fail fast by default**; deviate only with a documented rationale
embedded in the script's header or inline comment.

### 11c. Agent permission model (security-by-design)

Each agent's tool access is declared in the `tools:` field of its YAML
frontmatter at `canonical/agents/*/AGENT.md`. The host tool (Claude Code / Codex
/ Cursor) enforces the allowlist at dispatch time. Key patterns:

- **Discovery sub-agents** (`discovery-scout`, `discovery-analyst`,
  `discovery-architect`, `discovery-integrator`, `discovery-quality`) share a
  uniform `Read, Glob, Grep, Bash, Write` allowlist but are constrained by
  prompt contract to write ONLY into `.aid/knowledge/`.
- **Audit/review agents** (`security`, `reviewer`, `performance`) omit `Write`
  and `Edit` — they are read-only assessors.
- **`interviewer`** is the strictest: `Read, Glob, Grep` only — conversation-
  only, no file writes and no shell execution.
- **`tech-writer`** has `Write` and `Edit` but no `Bash` — docs-only, no shell.

⚠️ The write-scope restriction for discovery agents is enforced by prompt, not
by path-scoped `Write` permission. A misbehaving agent COULD write outside
`.aid/knowledge/`. There is no path-scoping in the `tools:` schema.

See `canonical/agents/*/AGENT.md` `tools:` frontmatter for the per-agent
allowlist. The full per-agent table is not reproduced here to avoid drift.

---

## 12. Q&A Schema (Cross-phase + Discovery)

All Q&A entries (in `.aid/knowledge/STATE.md ## Q&A` and any work's `STATE.md
## Cross-phase Q&A`) follow this schema:

```markdown
### Q{N}
- **Category:** {category}
- **Impact:** {High|Medium|Low|Required}
- **Status:** Pending | Answered | Skipped
- **Context:** {why this question matters}
- **Suggested:** {best-guess answer if inferrable, or "—"}
```

After user response, append:
```markdown
- **Answer:** {actual answer text or decision}
- **Applied to:** {file path or task-id where the answer was incorporated}
```

This is the **only canonical schema**. The older Style B (`### IQ{N}: [Category: Impact]`)
was deprecated in cycle-1 (see tech-debt.md Q15 follow-up).

---

## 13. KB cites to CLAUDE.md / AGENTS.md (banned)

**Knowledge Base documents MUST NOT cite `CLAUDE.md` or `AGENTS.md` by line number or section name.**

These files are agent-context pointers (auto-loaded into every agent task
context by the host tool). They are NOT a source-of-truth — their content is
intentionally minimal and may be rewritten without notice. KB cites *to* them
become stale immediately.

**Allowed direction:** CLAUDE.md / AGENTS.md → KB ("see .aid/knowledge/INDEX.md
for a map of the Knowledge Base"). **Never** KB → CLAUDE.md / AGENTS.md.

If a fact appears to have CLAUDE.md as its canonical home, the fact belongs in
a KB doc. Move it there + cite the KB doc.

This rule was added 2026-05-27 (cycle-2 Q18) after CLAUDE.md was collapsed from
~118 lines to 25 lines, leaving ~40 KB cites pointing past EOF. The rule
prevents the recurrence — see also `tech-debt.md` changelog.

## 14. Machine-parsed values must be text, glyphs are display-only

**Wherever a script, agent, or downstream tool parses a value from a markdown table or doc, the source-of-truth value MUST be plain text.** Glyphs (`✅` `⚠️` `❌` `✓` `🚧`) may decorate human-facing displays — legend rows, derived HTML views, README completeness tables read by humans — but the canonical machine-readable column is always plain text.

**Why:** Two bug classes are eliminated:

1. **Codepoint mismatch** — `✓` (U+2713 text checkmark) and `✅` (U+2705 emoji checkmark) look identical to humans, are different bytes to machines. `feature-inventory.md` used `✓` (cycle-1) → `build-metrics.sh` greped `✅` → `Shipped=0`. Q21 fix changed to `✅` → still buggy because:
2. **Loose regex matching** — `grep ✅` matched the symbol *everywhere*, including the legend row that DEFINES `✅`. Cycle-7 found `Shipped=12` (vs body=11) from the legend row being counted as a feature.

**The fix is both:** (a) use text values in the data column, and (b) constrain table-parsing regexes to data rows (e.g., `^\|[^|]*\|[^|]*\| Shipped \|`).

**How to apply:**

- **Inventory / tracking / status columns:** values are text (`Shipped`, `Partial`, `Pending`, `In Progress`, `Deprecated`, `Complete`, `Missing`, `Reviewed`, etc.). Examples: `feature-inventory.md` Status column, `tech-debt.md` Status column, work `STATE.md` per-task Status.
- **Glyphs are allowed in:** (a) legend / explanation paragraphs (humans only); (b) rendered HTML output of `aid-summarize` knowledge-summary.html; (c) test runner stdout (`[PASS]` / `[FAIL]`); (d) `## Knowledge Summary Status` table in STATE.md (purely human-read).
- **For scripts that parse markdown tables:** prefer text patterns AND constrain to data rows via regex like `^\|[^|]*\|.*\| <text-value> \|` which requires the line to start with `|`, have at least one column before the target, and have the target value enclosed in pipe-delimiters with surrounding spaces. This excludes legend rows, header rows, separator rows, and body prose.
- **When auditing:** ask "is this column parsed by any script, agent, or downstream tool?" If yes → text. If no → glyph is fine.
- **For new docs:** default to text. Only add glyph variants in derived/rendered views where no script reads them.

**Examples of past violations:**
- `feature-inventory.md` `✓` (cycle-1 GENERATE) → glyph mismatch, fixed cycle-2 Q21
- `feature-inventory.md` `✅` (cycle-2 fix) → legend over-counted, fixed cycle-7 / this convention
- The pattern keeps recurring with glyphs; the text-for-machine principle eliminates the class.

This rule was added 2026-05-28 (cycle-7 closeout glyph analysis). Memory: `feedback_text-for-machine-glyphs-for-display`. Both build-metrics.sh and feature-inventory.md were migrated to text in commit `bf4e814+` (the schema rollout + this convention).
