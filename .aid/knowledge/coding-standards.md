---
kb-category: primary
source: hand-authored
objective: AID repository coding conventions: SKILL.md/AGENT.md/KB-doc frontmatter shapes, Python and Bash style, Markdown conventions, and cross-cutting authoring rules.
summary: Documents the de-facto coding conventions used across the AID repo, covering skill/agent/KB authoring patterns, script style, and rules from CLAUDE.md and the kb-authoring templates.
sources:
  - canonical/skills/aid-config/SKILL.md
  - canonical/agents/aid-architect/AGENT.md
  - canonical/templates/kb-authoring/frontmatter-schema.md
  - canonical/templates/kb-authoring/principles.md
  - canonical/templates/kb-authoring/review-rubric.md
  - CLAUDE.md
approved_at_commit: ccb4e823
contracts:
  - "Every aid-* SKILL.md begins with a YAML frontmatter block containing name, description, allowed-tools (and optionally argument-hint)"
  - "Every canonical AGENT.md begins with a YAML frontmatter block containing at minimum name, description, tier, tools (per `canonical/agents/aid-architect/AGENT.md` frontmatter block)"
  - "Every KB doc begins with a YAML frontmatter block containing kb-category, source, intent (per `canonical/templates/kb-authoring/frontmatter-schema.md` `## Field reference`)"
  - "Every helper script declares set -euo pipefail (or set -uo pipefail with documented rationale)"
  - "Every helper script supports -h | --help that prints its own header comment via sed"
changelog:
  - 2026-06-23: Migrated by migrate-kb-frontmatter.sh: intent retired, objective/summary/sources added
  - 2026-06-09: aid-ask added (11->12 user-facing skills) via /aid-housekeep KB-DELTA.
  - 2026-06-04: work-001-agents-review (task-013) — §2a agent-dir naming updated to aid-* prefix; §8e agent-authoring updated to shared-include boilerplate (canonical/templates/agent-boilerplate.md via {{include:agent-boilerplate}}); §11c security model updated to new 9-agent roster; §10 convention table updated to 9 agents; old bare agent-name evidence cites replaced with aid-* paths.
  - 2026-06-21: work-005-profile-generator-simplify delivery-003 task-017 — §7a updated Codex split-layout line to unified .codex/; §8a removed render_agents.py reference; added §15 PowerShell gotchas (three work-005 delivery-002 Windows CI lessons: StrictMode absent-property, return-if parse trap, empty-array-sort).
  - 2026-06-01: work-001-add-providers (PRs #42/#43/#44) — render profiles grew 3→5; updated §7a multi-tree render set to include copilot-cli (.github) + antigravity (.agent), and §7d helper-script copy count (4→7 trees).
  - 2026-05-31: delivery-002 — added pipe-delimited-list-in-settings convention note to §6a (discovery.doc_set uses this pattern)
  - 2026-05-27: Initial generation (cycle-1)
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
| Python 3.11+ | `.claude/skills/generate-profile/scripts/*.py` + `run_generator.py` | PEP 8 + `from __future__ import annotations`, type hints, `@dataclass`, `Path` over `os.path`, stdlib-only |
| Bash | `canonical/scripts/**/*.sh` + `bin/aid` + `install.sh` + `lib/aid-install-core.sh` + `release.sh` + `tests/**/*.sh` | `#!/usr/bin/env bash` + `set -euo pipefail` (rare `set -uo pipefail` with rationale), POSIX-portable, 4-space indent inside `case`, sentinel-file locks for parallel-write safety. **Shipped CLI/installer scripts (`bin/aid`, `install.sh`, `lib/aid-install-core.sh`) are ASCII-only** — CI-guarded by `tests/canonical/test-ascii-only.sh` (a no-BOM UTF-8 script is mis-parsed under the Windows ANSI codepage; ASCII decodes identically everywhere) |
| JavaScript (ESM) | `canonical/scripts/summarize/{validate-diagrams,contrast-check}.mjs` + `canonical/templates/knowledge-summary/{lightbox,mermaid-init}.js` | `#!/usr/bin/env node` for CLI scripts, `import` syntax, top-level `await`, Node stdlib only |
| PowerShell | `bin/aid.ps1` + `install.ps1` + `lib/AidInstallCore.psm1` + `canonical/scripts/summarize/assemble-3part.ps1` | `aid` CLI dispatcher + installer core/bootstrap + concatenation helper; `#Requires -Version 5.1`, explicit `param()` blocks; **ASCII-only** shipped scripts (CI-guarded by `tests/canonical/test-ascii-only.sh`; the native-Windows path is asserted LF-only no-BOM by `tests/windows/Test-AidInstaller.ps1`) |
| Markdown | All skill bodies, agent bodies, templates, KB docs | YAML frontmatter delimited by `---`; GitHub-flavored tables; fenced code blocks with language identifiers |
| YAML | `canonical/templates/settings.yml` + `.aid/settings.yml` | YAML 1.2 (per `canonical/templates/settings.yml` `# Format: YAML 1.2.`); commented blocks above each section |
| TOML | `profiles/*.toml` + `profiles/codex/.codex/agents/*.toml` | TOML 1.0; sectioned with comments above each `[section]` |

---

## 2. Naming Conventions

### 2a. File + directory names

- **All `aid-*` skill directories are kebab-case** with the `aid-` prefix: `aid-config`, `aid-discover`, `aid-execute`, etc. (per `canonical/skills/`).
- **All agent directories carry the `aid-` prefix**, kebab-case: `aid-architect`, `aid-developer`, `aid-researcher`, `aid-clerk` (per `canonical/agents/` and REQUIREMENTS.md §7 collision-avoidance constraint).
- **Skill state files are `state-<state-name>.md`** — lowercase kebab-case state name, e.g., `state-generate.md`, `state-q-and-a.md`, `state-delivery-gate.md` (per `canonical/skills/aid-discover/references/`).
- **Helper scripts are kebab-case verb-noun** with `.sh` (or `.mjs` / `.ps1`) extension: `read-setting.sh`, `build-project-index.sh`, `compute-block-radius.sh`, `writeback-state.sh`, `validate-diagrams.mjs`, `contrast-check.mjs`.
- **Python files are snake_case** with `.py` extension: `render.py`, `render_lib.py`, `verify_deterministic.py`, `test_manifest_safety.py`, `run_generator.py`.
- **Templates are kebab-case** with `.md` extension: `task-template.md`, `discovery-state-template.md`, `recipe-template.md`, `subagent-heartbeat-protocol.md`.
- **Capitalized markdown filenames** are reserved for project-root files (`CLAUDE.md`, `README.md`, `CONTRIBUTING.md`, `LICENSE`) and for inside-work artifacts (`SPEC.md`, `PLAN.md`, `REQUIREMENTS.md`, `STATE.md`, `INDEX.md`, `AGENT.md`, `SKILL.md`, `IMPEDIMENT.md`, `EMISSION-MANIFEST.md`).
- **Generated files live under `.aid/generated/`** with kebab-case names: `project-index.md`, `metrics.md`, `INDEX.md` (note: `INDEX.md` keeps its capitalized form even when generated).

### 2b. Inside Python

- `snake_case` for functions, methods, module-level variables (per `.claude/skills/generate-profile/scripts/render_lib.py` `sha256_hex`, `substitute_filenames`).
- `PascalCase` for dataclasses (per `aid_profile.py` `LayoutConfig`, `FrontmatterConfig`).
- `_LEADING_UNDERSCORE` for module-private constants + helpers (per `render_lib.py` `_MANIFEST_VERSION`, `_PLACEHOLDER_RE`, `_CANONICAL_PATH_DIRS`).
- `SCREAMING_SNAKE` reserved for top-level constants when not module-private — none observed; the renderer uses `_LEADING_UNDERSCORE` exclusively.

### 2c. Inside Bash

- `UPPER_SNAKE_CASE` for environment-overridable config variables: `STATE_FILE`, `TASKS_DIR`, `DELIVERY_ISSUES_DIR`, `LOCK_DIR`, `LOCK_TIMEOUT` (per `canonical/scripts/execute/writeback-state.sh` `STATE_FILE="${AID_STATE_FILE`).
- `UPPER_SNAKE_CASE` for argument-bound locals: `KB_DIR`, `ROOT`, `FORMAT`, `SKIP_STATE`, `QUIET`; `SETTINGS_FILE`, `SKILL`, `KEY`, `DPATH`, `DEFAULT` (per `canonical/scripts/config/read-setting.sh` `SETTINGS_FILE=".aid/settings.yml"`).
- `lower_snake_case` for shell functions: `usage()`, `die()`, `warn()`, `build_prune_expr()`, `get_mtime()` (per `canonical/scripts/interview/parse-recipe.sh` `usage()`/`die()`/`warn()`, `kb/build-project-index.sh` `build_prune_expr()`/`get_mtime()`).
- Env-prefix convention `AID_*` for env-overridable defaults: `AID_STATE_FILE`, `AID_TASKS_DIR`, `AID_DELIVERY_ISSUES_DIR`, `AID_LOCK_DIR`, `AID_LOCK_TIMEOUT`, `AID_PARSE_RECIPE_LOCK_TIMEOUT` (per `writeback-state.sh` `STATE_FILE="${AID_STATE_FILE`, `parse-recipe.sh` `AID_PARSE_RECIPE_LOCK_TIMEOUT`).

### 2d. Inside Markdown (skill + agent + KB bodies)

- **Sections:** `## Title Case` for top-level inside a doc; `### Title Case` for sub-sections.
- **States in skill bodies:** UPPERCASE in narrative text (e.g., "State machine: GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE" per `canonical/skills/aid-discover/SKILL.md` `State-machine: GENERATE → REVIEW`), kebab-lowercase in filenames (`state-q-and-a.md`).
- **Task types:** UPPERCASE (RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, CONFIGURE per `canonical/skills/aid-execute/references/state-execute.md` `## Task Types`, `canonical/templates/delivery-plans/task-template.md` `**Type:**`).
- **Severity tags:** UPPERCASE bracketed: `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]`, `[MINOR]` (per `canonical/agents/aid-reviewer/AGENT.md` `## Severity Classification`, `canonical/scripts/grade.sh` `count_prose_tag CRITICAL`).
- **Source tags (for review findings):** UPPERCASE bracketed: `[CODE]`, `[TASK]`, `[SPEC]`, `[KB]`, `[ARCHITECTURE]` (per `canonical/agents/aid-reviewer/AGENT.md` `Tag every issue by source`).
- **Work + delivery IDs:** zero-padded 3-digit, kebab-prefixed: `work-001`, `work-002-canonical-generator`, `delivery-001`, `task-001`, `feature-005` (per `canonical/templates/work-state-template.md`).

---

## 3. File-Level Conventions

### 3a. Frontmatter (CONFIRMED for KB docs per `canonical/templates/kb-authoring/frontmatter-schema.md` `the entire frontmatter block is exempt from review`)

Every authored markdown artifact begins with a YAML frontmatter block delimited by `---` markers. There are three frontmatter shapes:

**KB doc frontmatter** (per `canonical/templates/kb-authoring/frontmatter-schema.md` `## Canonical schema`):
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

**Agent frontmatter** (per `canonical/agents/aid-architect/AGENT.md` frontmatter block):
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

**Skill frontmatter** (per `canonical/skills/aid-discover/SKILL.md` `name: aid-discover` frontmatter block):
```yaml
---
name: aid-<skill>
description: >
  Multi-line folded description.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[--flag] description of flag"
---
```

Per `frontmatter-schema.md` `the entire frontmatter block is exempt from review`, **the entire KB frontmatter block is exempt from
review** (per principle P6).

### 3b. Bash script header

Every helper script under `canonical/scripts/` follows a fixed header pattern (per `canonical/scripts/execute/writeback-state.sh` header comment, `canonical/scripts/config/read-setting.sh` header comment, `canonical/scripts/interview/parse-recipe.sh` header comment, `canonical/scripts/grade.sh` header comment):

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

**Variant:** `canonical/scripts/execute/writeback-state.sh` (`set -u` line) uses `set
-u` only (no `-e`, no `-o pipefail`) — because it does mode-dispatch and
returns specific exit codes per mode failure (codes 1-6 per its `# Exit codes:` header block).

### 3c. Bash script help mode

Every script supports `-h | --help` and renders its own header comment by
piping the file's top block through `sed` (per `canonical/scripts/execute/writeback-state.sh` `usage()`,
`canonical/scripts/grade.sh` `-h|--help`):

```bash
-h|--help)
  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
  ;;
```

The convention is to strip the leading `# ` prefix so the comment block reads as plain help text.

### 3d. Bash argument parsing

Every multi-arg script uses the same `while [[ $# -gt 0 ]] / case` pattern (per
`canonical/scripts/config/read-setting.sh` `while [[ $# -gt 0 ]]`,
`canonical/scripts/execute/writeback-state.sh` `while [[ $# -gt 0 ]]`,
`canonical/scripts/interview/parse-recipe.sh` `while [[ $# -gt 0 ]]`,
`canonical/scripts/kb/build-project-index.sh` `while [[ $# -gt 0 ]]`,
`canonical/scripts/grade.sh` `while [[ $# -gt 0 ]]`):

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

Every Python file starts with a shebang + module docstring-style comment + `from __future__ import annotations` (per `.claude/skills/generate-profile/scripts/render_lib.py` header comment, `aid_profile.py` header comment, `render.py` header comment):

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
`render_lib.py` `def sha256_hex` docstring).

---

## 4. Error Handling

### 4a. Bash

- **`die() / warn()` pattern** (per `canonical/scripts/interview/parse-recipe.sh` `die()`/`warn()`, `canonical/scripts/execute/writeback-state.sh` `die()`):
  ```bash
  die()  { echo "ERROR: <script>: $*" >&2; exit "${2:-1}"; }
  warn() { echo "WARN: <script>: $*" >&2; }
  ```
- **Exit codes are documented + meaningful per script** (per the headers cited in §3b). 0 = success; 1 = generic failure; 2 = usage error; 3+ = script-specific failure classes.
- **Errors go to stderr; results go to stdout** (CONFIRMED per `canonical/scripts/config/read-setting.sh` `# Output:` header block).
- **Trap cleanup** for temp files: `trap 'rm -f "$F1" "$F2"' EXIT` declared right before the first `mktemp`, with all slots pre-initialized to empty strings so the trap is safe to fire at any exit point (per `canonical/scripts/interview/parse-recipe.sh` `trap 'release_lock' EXIT` and `canonical/scripts/execute/writeback-state.sh`).

### 4b. Python

- **Renderer raises `ValueError`** for misconfigured profiles (per `.claude/skills/generate-profile/scripts/aid_profile.py` `raise ValueError`). The validator helper `validate(profile)` returns a list of errors instead of raising — the caller decides whether to abort (per `run_generator.py` `errors = validate(profile)`).
- **No bare `except:` clauses observed** — all caught exceptions are scoped (e.g., `except OSError:` per `run_generator.py` `except OSError:` for `parent.rmdir()` during tree pruning).
- **`sys.exit(1)` on render failure with stderr message** (per `run_generator.py` `errors = validate(profile)` and `VERIFY (deterministic) FAILED`). No traceback suppression.

### 4c. Markdown / KB docs

- **Findings are logged as rows in the 7-column reviewer ledger** (per `canonical/agents/aid-reviewer/AGENT.md` `## Output contract` and `canonical/templates/reviewer-ledger-schema.md`) — one markdown table, no narrative sections; out-of-scope findings are `Status: OOS` rows, not a separate section:
  ```
  | # | Severity | Status | Doc | Line | Description | Evidence |
  ```
- **Impediments are formal artifacts** at `.aid/{work}/task-NNN/IMPEDIMENT.md` (per `canonical/templates/feedback-artifacts/IMPEDIMENT.md` `# Impediment — task-NNN`). Four types: `wrong-assumption`, `missing-dependency`, `architecture-conflict`, `kb-gap` (per `IMPEDIMENT.md` `## Type`).

---

## 5. Logging + Progress

The AID repo has no application logging (no application code). Two related conventions exist for in-pipeline visibility:

### 5a. Subagent heartbeat (L3)

Every long-running subagent dispatch writes a single-line progress note to a per-dispatch file under `.aid/.heartbeat/<agent>-<unix-ts>.txt` (per `canonical/templates/subagent-heartbeat-protocol.md` `# Subagent Heartbeat Protocol`, injected into agents via `canonical/templates/agent-boilerplate.md`). The line format is:

```
[YYYY-MM-DDTHH:MM:SSZ] <STATE> | <progress> | <activity> (~<eta-remaining>)
```

Conventions (per `canonical/templates/agent-boilerplate.md` `## Heartbeat protocol`):
- Use `>` (overwrite), never `>>` (append).
- Activity must change between updates — repetition signals "stuck" to the orchestrator.
- Use `unknown` if eta-remaining cannot be predicted.
- Timestamp MUST come from a shell command (`$(date -u +%Y-%m-%dT%H:%M:%SZ)`), never typed in the agent's reply.

### 5b. Long-wait L2 timers (orchestrator-side)

Skills that dispatch subagents arm three L2 timers per dispatch as separate background Bash calls, each on its own `run_in_background: true` task — never chained with `&` inside a single wrapper (per `canonical/skills/aid-discover/SKILL.md` `Arm 3 L2 timers as SEPARATE background dispatches`). The three timers fire at `LOW/2`, `LOW`, and `1.5×LOW` of the rough-time estimate, allowing the user to see mid-wait progress instead of going silent for 10-25 minutes.

### 5c. Calibration log (always-on)

Every successful dispatch appends a row to `STATE.md ## Calibration Log` with format `| YYYY-MM-DD | <agent> | <task-id/cycle> | <ETA-band> | <actual> | <notes> |` (per `canonical/skills/aid-discover/SKILL.md` `STATE.md ## Calibration Log`). Unconditional per work-003 traceability.

---

## 6. Configuration

### 6a. Single source of truth: `.aid/settings.yml`

All AID runtime settings live in `.aid/settings.yml` (per `canonical/templates/settings.yml` `# Format: YAML 1.2.`). The file is YAML 1.2 with these sections:

- `project:` — `name`, `description`, `type` (brownfield/greenfield)
- `tools:` — `installed:` list (profile names: claude-code/codex/cursor/copilot-cli/antigravity)
- `review:` — `minimum_grade:` (global default)
- `execution:` — `max_parallel_tasks:` (parallel pool capacity)
- `traceability:` — `heartbeat_interval:` (minutes; 0 = disabled)
- Optional per-skill overrides: `discover:`, `summary:`, `interview:`, `specify:`, `plan:`, `detail:`, `execute:`, `deploy:`, `monitor:` — each may set `minimum_grade:`
- Optional `discovery:` — `doc_set:` block-list (see below)

**Pipe-delimited scalar lists in settings.yml:** When a settings section needs a list of
structured records (not just plain scalars), AID uses a **YAML block-list of pipe-delimited
strings** — each list item is a single YAML scalar with fields separated by `|`.
Example: `discovery.doc_set` — each item is `filename|owner|presence[:when]`.

Rules for this convention (per `canonical/skills/aid-discover/references/doc-set-resolve.md` `### Delimiter constraint`):
- Field values MUST NOT contain a comma — `read-setting.sh`'s `lookup_list` comma-joins all items into one string, then callers split on `,` to recover individual items; a comma inside a value shreds the record.
- The `|` field separator is safe because standard field values (filenames, agent names, `required`/`conditional`) never contain `|`.
- Free-text `when` suffix: list-like enumerations must use `;` or `/`, never `,` (e.g., `conditional:has CI; CD; or deploy config`).
- Inline `# comment` on an item line is stripped at read time; full-line comments between items TERMINATE list accumulation early — place them only after the last item.

### 6b. Settings resolution

Skills read settings via `bash canonical/scripts/config/read-setting.sh`, which implements per-skill override resolution: per-skill key (e.g., `discover.minimum_grade`) → global category default (`review.minimum_grade`) → hardcoded fallback supplied via `--default` (per `canonical/scripts/config/read-setting.sh` `Implements the canonical resolution order:`). Two invocation modes:

- `--skill <name> --key <key>` (override-aware) — for grade-style resolution.
- `--path <a.b.c>` (direct dotted-path) — for non-overridable keys like `execution.max_parallel_tasks`.

### 6c. Hard-coded defaults

When `.aid/settings.yml` is absent, callers fall back to `--default` values:
- `traceability.heartbeat_interval` → `1` (minute) per `canonical/templates/subagent-heartbeat-protocol.md` `Default value = **1 minute**`.
- `execution.max_parallel_tasks` → `5` per `canonical/skills/aid-execute/references/state-execute.md` `execution.max_parallel_tasks --default 5`.
- `review.minimum_grade` → `A` per `canonical/templates/settings.yml` `minimum_grade: A`.

### 6d. No secrets in repo

There are no `.env` files, no credential templates, no secrets handling (CONFIRMED — repo has no application code and no integration with external services). The only `JSON` configs are Claude-Code permission scopes (`.claude/settings.json`; `.claude/settings.local.json` (gitignored per `.gitignore` `.claude/settings.local.json`)).

---

## 7. File Organization

### 7a. Single-source canonical → multi-tree render

**Never edit `profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/` directly** (CONFIRMED per `canonical/EMISSION-MANIFEST.md` §Safety-Boundary Semantics). Edit `canonical/` and run `python .claude/skills/generate-profile/scripts/run_generator.py`. The render reads `canonical/` (the source) and emits byte-identical bodies into the **5 profile trees**:

- `profiles/claude-code/.claude/`
- `profiles/codex/.codex/` (unified layout — agents + skills + aid/ content)
- `profiles/cursor/.cursor/`
- `profiles/copilot-cli/.github/`
- `profiles/antigravity/.agent/`

The byte-identity invariant the generator enforces spans **6 trees** (`canonical/` source + the 5 profile trees). The repo-root `.claude/` (dogfood install) carries the same byte-identical bodies but is **hand-maintained — NOT written by `run_generator.py`** (per the dogfood-is-hand-editable policy); counting it gives **7 physical copies** on disk.

### 7b. Thin-router skill decomposition (CONFIRMED per `canonical/skills/*/SKILL.md` structure)

When a `SKILL.md` grows past ~200 lines, extract per-state bodies into `references/state-{name}.md`; keep the router as Dispatch table + Pre-flight + State Detection only. Skill-body line totals (and the pre-refactor reduction) are T3 metrics — see `.aid/generated/metrics.md` for current per-file counts.

### 7c. Co-location of state files

State references live alongside their skill: `canonical/skills/aid-discover/references/state-{approval,done,fix,generate,q-and-a,review}.md`. Naming pattern: `state-<lower-kebab-state-name>.md`.

### 7d. Per-script + per-test colocation

- Helper scripts live under `canonical/scripts/<category>/<script>.sh`. Each script has byte-identical copies in 7 physical locations (per §7a: the 6-tree render invariant — `canonical/` + 5 profile trees — plus the hand-maintained `.claude/` dogfood). Tests live at `tests/canonical/test-<script-name>.sh` and are run via `tests/run-all.sh` (shared helpers in `tests/lib/assert.sh`).
- The `tests/skills/` directory was deleted in cycle-1 (Q6 resolution). No skill-level e2e tests exist; the `tests/canonical/` suites are the complete test inventory (recount with `ls tests/canonical/test-*.sh | wc -l`; see `module-map.md §4`).

### 7e. Area-STATE consolidation (FR2, CONFIRMED per `canonical/templates/discovery-state-template.md`)

Each `.aid/{work}/STATE.md` is the per-area state hub; legacy per-feature `STATE.md` and per-task `STATE.md` files are retired. The discovery area has its own state at `.aid/knowledge/STATE.md` (per `canonical/templates/discovery-state-template.md` `# Discovery State`).

### 7f. Single-branch work (CONFIRMED — observed convention; see `tech-debt.md` H1 history)

Commit work-NNN to ONE persistent branch (off master); no per-task worktrees or branches. Worktree sprawl caused PR #12 to lose 63 commits; recovered via PR #13.

---

## 8. Code Style + Idioms

### 8a. Python

- **`pathlib.Path` over `os.path`** (per `.claude/skills/generate-profile/scripts/render_lib.py` `from pathlib import Path`, `aid_profile.py` `from pathlib import Path`, `render.py` `from pathlib import Path`).
- **`@dataclass` for value objects** (per `aid_profile.py` `class LayoutConfig`, `class FrontmatterConfig`, `class AgentConfig`).
- **`tomllib` stdlib for TOML parsing** (per `aid_profile.py` `import tomllib`) — no third-party `toml` package.
- **`hashlib.sha256` for content fingerprints** (per `render_lib.py` `def sha256_hex`) — used for `EmissionManifest` sha256 field.
- **Type hints throughout** (per `render_lib.py` `def sha256_hex(data: bytes) -> str`, `def substitute_filenames(body: str, filename_map: dict[str, str]) -> str`).
- **PEP 604 union syntax** (`X | None` not `Optional[X]`) per `aid_profile.py` `str | None`.
- **`TYPE_CHECKING` guard** for type-only imports (per `render_lib.py` `if TYPE_CHECKING:`).
- **Compiled regex constants at module scope** with leading-underscore name (per `render_lib.py` `_PLACEHOLDER_RE`, `_CANONICAL_PATH_RE`).

### 8b. Bash

- **POSIX-portable**: scripts must run on Linux, macOS (Big Sur+), and Windows Git Bash (per `canonical/scripts/interview/parse-recipe.sh` `# Portability: POSIX-portable`). Avoid GNU-only flags.
- **Platform-detection via `stat --version`** to pick between GNU coreutils and BSD stat (per `canonical/scripts/kb/build-project-index.sh` `if stat --version`).
- **Sentinel-file locking for parallel-write safety** (per `canonical/scripts/execute/writeback-state.sh` `acquire_lock()`, `canonical/scripts/interview/parse-recipe.sh` `acquire_lock()`). Uses `set -o noclobber + atomic create + sleep-poll retry` rather than `flock` (not portable to Windows Git Bash).
- **`mktemp` + EXIT trap** for temp files (per `canonical/scripts/interview/parse-recipe.sh` `trap 'release_lock' EXIT`).
- **AWK for line-level transforms** instead of `sed` when state is needed (per `canonical/scripts/grade.sh` `in_fence = !in_fence` — fence-detection awk).
- **No `realpath` or other GNU-only utilities** observed; portability is preserved.

### 8c. Markdown

- **GitHub-flavored tables** (`| col | col |` with `|---|---|` separator) — universally used for structured data (per any `.md` in the repo).
- **Fenced code blocks with language identifier** (e.g., ` ```bash`, ` ```yaml`, ` ```python`) per `canonical/templates/agent-boilerplate.md` `## Heartbeat protocol`.
- **One-sentence-per-line is NOT used** — prose flows naturally; bullets are used where a list is semantically correct.
- **Bold + arrow `→` for state transitions** (e.g., "GENERATE → REVIEW → FIX" per `canonical/skills/aid-discover/SKILL.md` `State-machine: GENERATE → REVIEW`).
- **Bullet style `-` (hyphen)** not `*` (asterisk). Consistent across all KB docs and skill bodies.

### 8d. State machine convention (CONFIRMED per `canonical/skills/aid-discover/SKILL.md` `**State machine for this skill:**`)

Each skill state machine is documented as a Dispatch table with these columns: `State | Detail | Worker | Advance` (per `canonical/skills/aid-discover/SKILL.md` `## Dispatch`). Advance follows one of three forms:

- **Unconditional** — always advance to the next state on exit.
- **Halt** — the state ends the run (terminal state).
- **Conditional** — advance based on a computed criterion (e.g., grade ≥ minimum → APPROVAL, else → FIX).

### 8e. Agent-authoring (CONFIRMED structure per all 9 `AGENT.md` files)

Every canonical agent body follows this section order:

1. YAML frontmatter (5-7 keys per §3a). Agent `name:` carries the `aid-` prefix (e.g. `aid-architect`).
2. One-paragraph identity ("You are the X — the Y specialist in the AID pipeline.").
3. `{{include:agent-boilerplate}}` — resolved at render time from `canonical/templates/agent-boilerplate.md`, which injects `## Heartbeat protocol` and `## Self-review discipline` into all 9 agents. The two protocol blocks are **NOT** duplicated per-agent; they live once in `canonical/templates/agent-boilerplate.md` and are included via this placeholder. `aid-clerk` (small-tier mechanical) may omit the placeholder per its narrow scope.
4. `## What You Do` (bullet list).
5. `## What You Don't Do` (bullet list).
6. `## Key Constraints` (bullet list).
7. `## Output Format` (per agent).
8. `## When to Escalate` (bullet list).

---

## 9. KB Authoring Principles (CONFIRMED per `canonical/templates/kb-authoring/principles.md`)

Seven principles govern all `.aid/knowledge/*.md` authoring:

- **P1.** No drift-prone information unless it carries semantic value. Three banned classes: (a) cosmetic counting, (b) dates without semantic anchor, (c) other low-value clutter.
- **P2.** Proper metric: when a numerical fact IS load-bearing, it must (a) serve a concrete purpose, (b) be measured before registering, (c) never be retroactively changed.
- **P3.** Plan first, change later. Review and fix are SEPARATE phases. Use the `.aid/.temp/review-pending/<skill>.md` ledger pattern.
- **P4.** Enforce via lint, not convention. `aid-reviewer` (dispatched from `/aid-discover REVIEW` state) validates KB citations, frontmatter compliance, and contract assertions (see `canonical/agents/aid-reviewer/AGENT.md`).
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
| Thin-Router SKILL.md ≤~360 lines | `coding-standards.md §7b`; `canonical/skills/*/SKILL.md` structure | YES — all 12 user-facing skills fit under the threshold; the largest is `aid-interview` (the newest, `aid-ask`, is well under the thin-router line limit as a single-shot read-only router). Per-file line counts live in `.aid/generated/metrics.md` / `project-index.md` | Confirmed |
| 9 agents, 3 tiers (4L/4M/1S) | `README.md` `## The Agent Model — three tiers` | YES — confirmed via 9 `AGENT.md` files under `canonical/agents/aid-*/` with `tier: large|medium|small` frontmatter | Confirmed |
| Active KB docs | `canonical/skills/aid-discover/references/doc-set-resolve.md` `## synth_default_seed` | YES — the default seed is now data-driven from `canonical/templates/knowledge-base/*.md` via `synth_default_seed`; count varies by project (delivery-002 resolved H5; hardcoded 14-doc list removed from SKILL.md) | Confirmed |
| 8-task-type catalog | `canonical/skills/aid-execute/references/state-execute.md` `## Task Types`; `canonical/templates/delivery-plans/task-template.md` `**Type:**` | YES — both lists match: RESEARCH/DESIGN/IMPLEMENT/TEST/DOCUMENT/MIGRATE/REFACTOR/CONFIGURE | Confirmed |
| 5 grade severity tags | `canonical/agents/aid-reviewer/AGENT.md` `## Severity Classification`; `canonical/scripts/grade.sh` `count_prose_tag CRITICAL` | YES — [CRITICAL]/[HIGH]/[MEDIUM]/[LOW]/[MINOR] match in both | Confirmed |
| 4 lite-path sub-paths | `canonical/templates/work-state-template.md` `**Sub-path:**`, `canonical/templates/recipe-template.md` ``Valid `applies-to` values`` | YES — sub-path enum present in both | Confirmed |
| Heartbeat interval = 1 minute default | `canonical/templates/settings.yml` `heartbeat_interval: 1`; `canonical/templates/subagent-heartbeat-protocol.md` `Default value = **1 minute**` | YES — both state default 1 minute | Confirmed |
| Max parallel tasks = 5 default | `canonical/templates/settings.yml` `max_parallel_tasks: 5`; `canonical/skills/aid-execute/references/state-execute.md` `execution.max_parallel_tasks --default 5` | YES — both state default 5 | Confirmed |
| Calibration Log unconditional | `canonical/skills/aid-discover/SKILL.md` `STATE.md ## Calibration Log` | Code requires it; always-on per work-003 traceability | Confirmed — matches user feedback "Traceability unconditional" |
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

The following paths MUST remain gitignored (per `.gitignore`):

- `.aid/.heartbeat/` — ephemeral per-subagent heartbeat files; accumulate and
  pollute history. Confirmed gitignored at `.gitignore` `.aid/.heartbeat/`;
  `git check-ignore -v .aid/.heartbeat/` resolves to that entry.
- `.aid/.temp/` — excluded by an explicit `.gitignore` directory entry `.aid/.temp/`
  (rename-resilient), in addition to the `*.temp` glob that also matches it.
- `.aid/knowledge/.cache/` — KB build cache; must not be tracked (per `.gitignore` `.aid/knowledge/.cache/`).
- IDE/editor files (`.idea/`, `.vscode/`, `*.iml`, etc.) — per `.gitignore` `.vscode/` / `.idea/`.
- `.claude/settings.local.json` — per-developer Claude Code overrides; excluded
  at `.gitignore` `.claude/settings.local.json`. Not a credentials file (the repo has no credentials) but
  excluded to prevent accidental personal-preference commits.

### 11b. Shell script safety discipline (CONFIRMED)

Every canonical helper script under `canonical/scripts/` declares
`set -euo pipefail` at the top (per `canonical/scripts/config/read-setting.sh` `set -euo pipefail`
as the exemplar). Exceptions are documented in §3b above:

- `set -uo pipefail` (no `-e`) when the script runs many checks and must
  continue past per-check failures (pattern: `canonical/scripts/kb/build-project-index.sh`).
- `set -u` only (no `-e`, no `-o pipefail`) when the script does explicit
  mode-dispatch with named exit codes (e.g., `writeback-state.sh` `set -u`).

The principle: **fail fast by default**; deviate only with a documented rationale
embedded in the script's header or inline comment.

### 11c. Agent permission model (security-by-design)

Each agent's tool access is declared in the `tools:` field of its YAML
frontmatter at `canonical/agents/aid-*/AGENT.md`. The host tool (Claude Code / Codex
/ Cursor) enforces the allowlist at dispatch time. Key patterns:

- **`aid-researcher`** (handles all KB discovery/analysis work previously spread
  across 5 discovery sub-agents) shares `Read, Glob, Grep, Bash, Write` but is
  constrained by prompt contract to write ONLY into `.aid/knowledge/`.
- **`aid-reviewer`** omits `Write` and `Edit` — read-only adversarial assessor.
- **`aid-interviewer`** is the strictest: `Read, Glob, Grep` only — conversation-
  only, no file writes and no shell execution.
- **`aid-tech-writer`** has `Write` and `Edit` but no `Bash` — docs-only, no shell.
- **`aid-clerk`** (small-tier mechanical) carries a narrower allowlist matching its
  single-operation scope.

⚠️ The write-scope restriction for `aid-researcher` is enforced by prompt, not
by path-scoped `Write` permission. A misbehaving agent COULD write outside
`.aid/knowledge/`. There is no path-scoping in the `tools:` schema.

See `canonical/agents/aid-*/AGENT.md` `tools:` frontmatter for the per-agent
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

---

## 15. PowerShell gotchas (Windows CI — delivery-002 lessons)

Three issues each cost a CI cycle during work-005 delivery-002 Windows debugging. Recorded
here so they do not recur when editing `bin/aid.ps1`, `install.ps1`, or `lib/AidInstallCore.psm1`.

### 15a. StrictMode + absent JSON property throws, not returns `$null`

Under `Set-StrictMode -Version Latest`, accessing a property that does not exist on a
PSCustomObject throws `PropertyNotFoundException` rather than returning `$null`. Reading
heterogeneous JSON (e.g., an old manifest format that lacks a key a new format added) silently
blows up inside a `try{}` if the guard is missing.

**Pattern to use** for optional JSON properties:

```powershell
# WRONG (throws under StrictMode if key absent):
$value = $obj.missingKey

# CORRECT:
$value = if ($obj.PSObject.Properties['missingKey']) { $obj.missingKey } else { $defaultValue }
```

Source: `lib/AidInstallCore.psm1` (guard pattern applied throughout); observed during
work-005 delivery-002 Windows manifest-parsing debugging.

### 15b. `return if (...)` is a CommandNotFoundException, not an early return

PowerShell parses `if` following `return` as a **command name**, not a control-flow keyword.
The result is a `CommandNotFoundException` that is silently swallowed inside a `try{}`, and
execution falls through to the wrong return value.

**Pattern to use:**

```powershell
# WRONG (silently falls through):
return if ($condition) { $valueA } else { $valueB }

# CORRECT:
$result = if ($condition) { $valueA } else { $valueB }
return $result
```

Source: `lib/AidInstallCore.psm1` / `bin/aid.ps1` (corrected during work-005 delivery-002
Windows debugging).

### 15c. Empty array piped through `ForEach-Object` yields `$null`, not an empty array

`@() | ForEach-Object { ... }` yields `$null` in PowerShell, not an empty collection.
Passing `$null` to `[System.Array]::Sort(...)` or any method expecting an array throws.

**Pattern to use:**

```powershell
# WRONG (throws if $arr is empty):
$arr | ForEach-Object { ... }
[System.Array]::Sort($arr, $comparer)

# CORRECT — guard before iterating or sorting:
if ($arr.Count -gt 0) {
    [System.Array]::Sort($arr, $comparer)
    foreach ($item in $arr) { ... }
}
```

Source: `lib/AidInstallCore.psm1` (guard applied during work-005 delivery-002 Windows
manifest-sort debugging).
