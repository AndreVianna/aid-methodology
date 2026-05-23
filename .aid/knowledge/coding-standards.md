# Coding Standards

> **Source:** aid-discover (discovery-analyst)
> **Status:** Populated (initial dogfood pass)
> **Last Updated:** 2026-05-21

> ⚠️ **Important:** Because this repo has effectively **no source code** (no Java/Python/Go/TS service, no `package.json`, no compiled artifact), the "coding standards" mined here are the **authoring conventions for AID's own asset types** — SKILL.md, agent definitions, KB documents, templates, scripts. These are the conventions a contributor must follow to keep the three install trees consistent. Every claim cites a file path. Unless marked CONFIRMED, conventions are **inferred from a small sample** (typically 2–5 files of each kind); a wider sample may surface exceptions.

---

## 1. Skill File (SKILL.md) Conventions

### 1.1 Frontmatter — required fields

The `SKILL.md` frontmatter is YAML, delimited by `---` lines. Verified directly against `claude-code/.claude/skills/aid-discover/SKILL.md:1-10`, `claude-code/.claude/skills/aid-init/SKILL.md:1-10`, `codex/.agents/skills/aid-discover/SKILL.md:1-10`, and `cursor/.cursor/skills/aid-discover/SKILL.md:1-10`. All four use **the same shape**, regardless of host tool:

| Field | Required | Type | Example |
|-------|----------|------|---------|
| `name` | yes | string (kebab-case) | `name: aid-discover` |
| `description` | yes | YAML block scalar (`>` folded) | multi-line; first sentence is summary, second mentions state machine if applicable |
| `allowed-tools` | yes | comma-separated list (NOT YAML array) | `allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent` |
| `argument-hint` | optional | quoted string | `argument-hint: "[--grade A] minimum acceptable grade (default: A)  [--reset] clear KB and restart"` |

**Observation — identical frontmatter across trees.** `aid-discover/SKILL.md` lines 1–10 in **all three install trees** are byte-identical: same `name`, same `description` (folded block), same `allowed-tools` enumerated as `Read, Glob, Grep, Bash, Write, Edit, Agent`, same `argument-hint`. CONFIRMED from direct read of all three. The frontmatter does NOT vary by host tool — only the **body** varies (Claude Code factors out `references/`, Codex / Cursor inline).

⚠️ The Cursor and Codex SKILL.md frontmatter declares `Agent` in `allowed-tools` (Claude Code's tool name), but the underlying tools (Codex CLI / Cursor) may not expose a tool by that name. This is an unconfirmed cross-tool compatibility issue and is already flagged in `external-sources.md`.

### 1.2 Body structure

A canonical SKILL.md body follows this section order (verified against `claude-code/.claude/skills/aid-discover/SKILL.md`):

1. `# {Title}` — H1, sentence-case, descriptive (e.g., `# Brownfield Project Discovery`).
2. Opening paragraph — what the skill does, one paragraph, no lists.
3. `## ⚠️ Pre-flight Checks` — environment / state preconditions. Always present in skills that mutate state (`aid-discover` line 20, `aid-init` line 33).
4. `## Arguments` — a markdown table mapping `--flag` → effect. Present whenever `argument-hint` is set.
5. `## State Detection` and `## Mode: {NAME}` sections — state-machine skills (`aid-discover`, `aid-summarize`) decompose into one H2 per mode.
6. `## Quality Checklist` — bullet checklist of what "done" means.
7. `## Grading Criteria` and/or `## Document Expectations` — when the skill grades its own output.

Example: `aid-discover/SKILL.md` lines 20, 40, 82, 219, 254, 296, 352, 381, 415, 431 mark each of the section headers in order.

### 1.3 Decomposition idiom

**Claude Code:** when a skill body grows large, content is extracted into siblings:

- `references/*.md` — long-form prompts and explanations that the SKILL.md body refers to by filename.
- `scripts/*.sh` — runnable shell scripts invoked from the SKILL.md.

Example (`claude-code/.claude/skills/aid-discover/`): SKILL.md (453 lines) + `references/agent-prompts.md` (142) + `references/document-expectations.md` (121) + `references/reviewer-prompt.md` (75) + `scripts/check-preflight.sh` (45) + `scripts/verify-kb.sh` (60) = 6 files, 896 lines total. The SKILL.md body uses phrases like "Read `references/agent-prompts.md` section `## Scout`" (line 126).

**Codex / Cursor:** the same content is **inlined into a single, longer SKILL.md**. `codex/.agents/skills/aid-discover/SKILL.md` is 1,078 lines; `cursor/.cursor/skills/aid-discover/SKILL.md` is 1,090 lines. This is why the file is 2.4x larger in those trees. (One exception in both Codex and Cursor: `aid-interview/references/kb-hydration.md` 106 lines — a single `references/` survivor.)

### 1.4 State-machine notation

State-machine skills (`aid-discover`, `aid-summarize`, `aid-execute`, `aid-interview`) consistently use this notation in the description / body:

- States named in `SCREAMING_CASE` (`GENERATE`, `REVIEW`, `Q&A`, `FIX`, `APPROVAL`, `DONE` in `aid-discover/SKILL.md:7`; `PREFLIGHT`, `STALE-CHECK`, `PROFILE`, `GENERATE`, `VALIDATE`, `FIX`, `APPROVAL`, `WRITEBACK`, `DONE` in `project-structure.md:89`).
- Arrows are `->` (ASCII) or `→` (Unicode); both appear interchangeably across files.
- `[State: {NAME}]` is printed at runtime — e.g., `aid-discover/SKILL.md:78`.

### 1.5 Print-progress idiom

Skill bodies prescribe **literal `Print:` lines** for runtime status output, with bracketed step markers:

- `Print: \`[0c] Building project index...\`` (`aid-discover/SKILL.md:112`)
- `Print: \`[1/5] Pre-scan: mapping project structure...\`` (`aid-discover/SKILL.md:124`)
- `Print: \`Agent "[name]" completed. [N/4] done.\`` (`aid-discover/SKILL.md:154`)

Pattern: `[step/total]` for counted phases, `[State: NAME]` for state transitions, plain bracketed prefix `[Review 1/2]`, `[Q&A]`, `[Fix]` for mode-specific output.

---

## 2. Agent File Conventions

### 2.1 Claude Code agent format

**File path:** `claude-code/.claude/agents/{name}.md` (kebab-case slug = `name` frontmatter value).
**Frontmatter:** YAML between `---` lines. Required fields verified directly:

| Field | Required | Type | Source |
|-------|----------|------|--------|
| `name` | yes | string (kebab-case) | `claude-code/.claude/agents/architect.md:2` |
| `description` | yes | string OR YAML folded block | `architect.md:3` (single line), `discovery-reviewer.md:3-6` (folded block) |
| `tools` | yes | comma-separated list (NOT YAML array) | `architect.md:4` (`Read, Glob, Grep, Write, Edit, Bash`), `discovery-analyst.md:4` (`Read, Glob, Grep, Bash, Write`) |
| `model` | yes | one of `opus`/`sonnet`/`haiku` | `architect.md:5` (`opus`), `claude-code/.claude/agents/orchestrator.md` (Sonnet per project-structure.md) |
| `permissionMode` | optional | string, observed value `bypassPermissions` | `discovery-reviewer.md:9`, `discovery-analyst.md:6` |
| `background` | optional | boolean | `discovery-reviewer.md:10` (`true`), `discovery-analyst.md:7` (`true`) |

**Body structure** (verified against `architect.md`, `discovery-analyst.md`, `discovery-reviewer.md`):

1. `# {Title}` — H1, omitted in some smaller agents (e.g., `architect.md` opens with prose paragraph rather than H1).
2. Opening sentence: `You are a/an {Role} — {one-line mission}.` (`architect.md:8`, `discovery-analyst.md:10`, `discovery-reviewer.md:13`).
3. `## What You Do` — bullet list of responsibilities.
4. `## What You Don't Do` — bullet list of boundaries (each item identifies which agent owns that work instead).
5. `## Key Constraints` — bold-prefixed bullets (`**Grounded in KB.**`, `**Specs are hypotheses.**`).
6. `## Output Format` — list of artifacts produced with template path references.
7. `## When to Escalate` — bullet list mapping situation → escalation route (a Q&A entry in a STATE file, or IMPEDIMENT.md).

Larger / discovery-tier agents add:
- `## Your Mission`, `## ⚠️ {section}`, `## Document Expectations` (`discovery-reviewer.md`).
- `## ⚠️ File Writing` — warning footer about the Write-tool bug in background subagents, prescribing `cat > path << 'KBEOF' ... KBEOF` (`discovery-reviewer.md:372-381`, `discovery-analyst.md:96-105`). CONFIRMED present in all three discovery sub-agents read.

### 2.2 Codex agent format

**File path:** `codex/.codex/agents/{name}.toml`. TOML at the top, then the prose body lives inside a `developer_instructions = """..."""` multi-line string.

| Field | Required | Type | Source |
|-------|----------|------|--------|
| `name` | yes | string | `codex/.codex/agents/architect.toml:1` (`name = "architect"`) |
| `description` | yes | string (single line) | `architect.toml:2` |
| `model` | yes | string (Codex model name) | `architect.toml:3` (`model = "gpt-5.5"`) |
| `model_reasoning_effort` | yes | one of `low` / `medium` / `high` | `architect.toml:4` (`high`), `simple-extractor.toml:4` (`low`) |
| `developer_instructions` | yes | triple-quoted multi-line string | `architect.toml:5-39` |

**Tier mapping (model + reasoning_effort)** — partially verified directly:

| Tier | Model | Reasoning effort | Verified |
|------|-------|-------------------|----------|
| Opus | `gpt-5.5` | `high` | `architect.toml:3-4`, `discovery-reviewer.toml:3-4`, `discovery-analyst.toml`, `discovery-architect.toml`, `discovery-quality.toml`, `discovery-scout.toml`, `discovery-integrator.toml` |
| Sonnet | `gpt-5.4` | `medium` | ✅ VERIFIED post-Q36 via direct grep across all 9 Sonnet-tier `codex/.codex/agents/*.toml` files (orchestrator, developer, operator, researcher, devops, data-engineer, performance, tech-writer, ux-designer) — all match. |
| Haiku | `gpt-5.4-mini` | `low` | `simple-extractor.toml:3-4` |

✅ The Sonnet tier mapping is VERIFIED post-Q36 (cycle 1) by direct grep over all 9 Sonnet-tier Codex `*.toml` files. The May 2026 tier-rename migration documented in `codex/README.md:35` was confirmed clean across all 22 agents × 3 install trees per `tech-debt.md L6`.

**Body inside `developer_instructions`:** same H2 section order as Claude Code (`## What You Do`, `## What You Don't Do`, `## Key Constraints`, `## Output Format`, `## When to Escalate`), verified at `codex/.codex/agents/architect.toml:7-38`. **Note:** the Codex body uses **markdown headers inside a triple-quoted TOML string** — the markdown rendering depends on Codex CLI's interpretation, which is not directly verifiable from local files.

### 2.3 Cursor agent format

**File path:** `cursor/.cursor/agents/{name}.md`. Per `project-structure.md:66` and `project-index.md`, line counts are essentially identical to Claude Code (e.g., both `architect.md` files are 40 lines; both `discovery-reviewer.md` files are 381 lines). **Same YAML frontmatter shape as Claude Code, same body structure.**

✅ VERIFIED post-cycle-7: direct read of `cursor/.cursor/agents/architect.md:1-7` confirms YAML frontmatter with `name`, `description`, `tools`, `model` — same shape as Claude Code (with the documented `tools: ... Terminal` vs `Bash` divergence per Q52 / M6). Line-count parity per `project-index.md` also holds.

### 2.4 Drift between trees — same agent, different filename references

`discovery-reviewer` is one logical agent but its three instantiations have **real semantic drift**:

| Convention element | Claude Code | Codex | Cursor |
|-------------------|-------------|-------|--------|
| Project-context filename | `CLAUDE.md` (`claude-code/.claude/agents/discovery-reviewer.md:74`) | `AGENTS.md` (`codex/.codex/agents/discovery-reviewer.toml:37`) | `AGENTS.md` (verified: `cursor/AGENTS.md` exists at repo root, 45 lines) |
| Reviewer output filename | `DISCOVERY-STATE.md` (`discovery-reviewer.md:304`) | `DISCOVERY-GRADE.md` (`discovery-reviewer.toml:258`) | `DISCOVERY-STATE.md` (per parity with Claude Code) |
| Open-questions filename | `additional-info.md` (`discovery-reviewer.md:261`) | `open-questions.md` (`discovery-reviewer.toml:220`) | `additional-info.md` (per parity) |

**Convention implication:** When updating an agent body, the contributor must adapt these three filenames per tree. There is no abstraction layer or templating that handles this — it is a manual substitution discipline. ⚠️ Q30 below records the broader question of which set of filenames is canonical.

---

## 3. Cursor `.mdc` Rule Conventions

`.mdc` files live under `cursor/.cursor/rules/` and are project-rules that Cursor injects into the agent context per its precedence rules.

**Frontmatter** (YAML between `---` lines), verified from `cursor/.cursor/rules/aid-methodology.mdc:1-4` and `cursor/.cursor/rules/aid-review.mdc:1-5`:

| Field | Required | Type | Example |
|-------|----------|------|---------|
| `description` | yes | quoted string | `description: "AID methodology workflow and Knowledge Base integration"` |
| `alwaysApply` | yes | boolean | `alwaysApply: true` (`aid-methodology.mdc:3`) or `alwaysApply: false` (`aid-review.mdc:4`) |
| `globs` | optional | quoted glob expression — REQUIRED when `alwaysApply: false` | `globs: "**/*.{java,py,ts,js,cs,go,rs}"` (`aid-review.mdc:3`) |

**Two distinct rule classes observed:**

1. **Always-on rules** (`alwaysApply: true`, no `globs`) — `aid-methodology.mdc` (29 lines). Inject KB-first workflow on every request.
2. **Glob-scoped rules** (`alwaysApply: false`, with `globs`) — `aid-review.mdc` (11 lines). Inject review constraints only when editing source files matching the glob.

**Body convention:** plain markdown, no required H1 / H2 structure. The `aid-methodology.mdc` body uses `## Knowledge Base`, `## Workspace Structure`, `## Workflow` H2s; `aid-review.mdc` is a flat numbered list of 5 review checks.

---

## 4. KB Document Conventions

Every file under `.aid/knowledge/*.md` carries a **metadata header block** as its first content after the H1. Verified against the three KB documents already on disk (`.aid/knowledge/project-structure.md:1-7`, `.aid/knowledge/external-sources.md:1-7`, `.aid/knowledge/project-index.md:1-4`) and against the canonical templates (`templates/knowledge-base/module-map.md:1-7`, `templates/knowledge-base/data-model.md:1-7`, `templates/knowledge-base/coding-standards.md:1-9`).

### 4.1 Metadata header

```markdown
# {Title}

> **Source:** {producer skill or sub-agent}
> **Status:** {status enum}
> **Last Updated:** {date — `YYYY-MM-DD` ISO or `—`}
```

**Source vocabulary** observed:
- `aid-init` — for files created by init only.
- `aid-discover` — for KB docs produced by the broad discovery skill.
- `aid-discover (discovery-scout)` / `aid-discover (discovery-analyst)` / etc. — narrowed to the specific sub-agent (per `external-sources.md:3`, `project-structure.md:3`).
- `aid-init + aid-discover (discovery-scout) enrichment` — multi-producer file (`external-sources.md:3`).

**Status vocabulary** observed across the on-disk KB:
- `❌ Pending Discovery` — the templated placeholder, used by `aid-init`'s scaffolding (`.aid/knowledge/coding-standards.md:4` before this pass).
- `⚠️ Paths Registered / web fetch deferred` — partial status with caveat (`.aid/knowledge/external-sources.md:4`).
- `⚠️ URLs registered + local cross-reference — web fetch deferred` — variant (`external-sources.md:4`).
- `Populated (initial dogfood pass)` — fully populated with discovery output (`project-structure.md:4`).

⚠️ The status vocabulary is **not formally enumerated** anywhere — it has emerged organically. The reviewer's `templates/reports/discovery-state-template.md:14-31` uses a different status enum (`✅ Pass / ❌ Below minimum`) for the *grade-table*. There is no central list of valid status strings — a contributor inventing a new status would not violate any explicit rule. ⚠️ Q33 below.

### 4.2 Body structure

After the metadata block, KB documents follow per-document templates under `templates/knowledge-base/`. Each ends with a `## Revision History` table (verified from `templates/knowledge-base/module-map.md:86-91`, `templates/knowledge-base/data-model.md:104-109`, `templates/knowledge-base/coding-standards.md:114-119`):

```markdown
## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial discovery |
```

### 4.3 Inferred-content marking

Per `templates/knowledge-base/coding-standards.md:7` and `claude-code/.claude/agents/discovery-analyst.md:29` ("Mark inferred conventions with ⚠️ Inferred from code — needs confirmation"), facts inferred from code (rather than from documentation) carry a `⚠️` prefix. The `aid-discover/SKILL.md:420` Quality Checklist enforces this: "Inferred info marked with ⚠️".

### 4.4 File-path citation requirement

`claude-code/.claude/agents/discovery-analyst.md:27` ("Every claim must cite a file path. No unsourced assertions") and `aid-discover/SKILL.md:419` ("Claims grounded in code evidence (file paths, line numbers)") establish that every factual claim in a KB document must have an inline `path:line` citation. This convention is enforced post-hoc by `discovery-reviewer` (see `discovery-reviewer.md:84-94` "Accuracy Spot-Check (AGGRESSIVE)" — minimum 15 spot-checks, 5 of which must verify versions).

---

## 5. Template File Conventions

### 5.1 Placeholder syntax

Templates use **single curly braces** for placeholders: `{Project Name}`, `{date}`, `{grade}`. Verified across:
- `templates/knowledge-base/INDEX.md:1` (`# Knowledge Base Index — {Project Name}`)
- `templates/knowledge-base/module-map.md:15` (`| {module-name} | {what it does in one sentence} | ...`)
- `templates/knowledge-base/data-model.md:14` (`| **Type** | {PostgreSQL / MySQL / SQLite / SQL Server / MongoDB / DynamoDB / other} |`)
- `templates/reports/discovery-state-template.md:5` (`- **Minimum Grade:** {grade, default A}`)
- `templates/delivery-plans/task-template.md:1` (`# task-NNN: {Name}`)
- `claude-code/.claude/templates/discovery-state.md:5` (`**Minimum Grade:** {minimum}`)

**Convention:**
- Single braces for fillable values.
- Pipe-separated enumerations inside braces show the allowed set: `{✅ Complete | ⚠️ Partial | ❌ Missing}` (`templates/knowledge-base/module-map.md:5`).
- Slash-separated also seen, equivalent: `{PostgreSQL / MySQL / SQLite / ...}` (`templates/knowledge-base/data-model.md:14`). Both notations co-exist — no single convention.

**Other observed placeholder patterns:**
- `*(pending)*` — italic-parenthesized placeholder for not-yet-addressed sections (`templates/requirements/requirements-template.md:14`).
- `<!-- Comment -->` — HTML comment blocks for guidance the user should remove (`templates/feedback-artifacts/IMPEDIMENT.md:18`, `claude-code/.claude/templates/known-issues.md:6`).
- `_No issues yet._` / `_none yet_` — italicized empty-state strings (`templates/implementation-state.md:18`).

### 5.2 Templates-within-templates

Some templates document the **template-of-a-template**: `templates/requirements/requirements-template.md` is structured as `# Requirements Template` (lines 1–18 documentation) then a fenced code block (lines 22–80) containing the actual template to copy. The discovery state template at `templates/reports/discovery-state-template.md` does the same. **Convention:** the file-level H1 is the *meta* title (e.g., "REQUIREMENTS.md Template"), the fenced block inside is the *substantive* template starting with its own `# Requirements` H1.

### 5.3 Conditional sections

Templates use HTML comments to gate optional sections: `templates/specs/spec-template.md:54-75` lists 18 conditional sections (`### API Contracts`, `### UI Specs`, `### Events & Messaging`, `### DDD Analysis`, `### BDD Scenarios`, etc.) inside `<!-- ... -->` to be activated by `aid-specify` only when the feature warrants them.

---

## 6. Shell-Script Conventions

Verified from `templates/scripts/build-project-index.sh:1-40` and consistent with `project-structure.md:228-230`'s catalog of runtime scripts.

### 6.1 Shebang & strict mode

```bash
#!/usr/bin/env bash
# {script-name} — {one-line purpose}
# {longer description, blank-prefixed lines}
#
# Usage:
#   {script-name} [flags]
#
# Skips: {what gets pruned, if any}

set -euo pipefail
```

Verified at `templates/scripts/build-project-index.sh:1-20`. The opening comment block:
- Line 1: `#!/usr/bin/env bash` (NOT `#!/bin/bash` — portable shebang convention).
- Line 2: comment with script filename + em-dash + one-line purpose.
- Lines 3+: multi-line description, each line `#`-prefixed.
- A `Usage:` block listing flag invocations.
- `set -euo pipefail` immediately after the comment block — verified line 20 in `build-project-index.sh`.

### 6.2 Argument parsing

Long-flag `case` loop pattern (`build-project-index.sh:26-40`):

```bash
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)       OUTPUT="$2"; shift 2 ;;
    --root)         ROOT="$2"; shift 2 ;;
    --top-largest)  TOP_N="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "build-project-index.sh: unknown flag: $1" >&2
      exit 2
      ;;
  esac
done
```

Notable: `-h|--help` echoes the script's own comment block (lines 2–17, stripped of `# ` prefix) as the usage text. Avoids duplicating help.

### 6.3 Configurable skip-list

`build-project-index.sh:43-52` declares a bash array of paths to prune:

```bash
SKIP_DIRS=(
  .git .svn .hg
  node_modules vendor target build dist out
  .idea .vscode .vs
  __pycache__ .pytest_cache .tox
  .gradle .m2
  bin obj
  .next .nuxt
  .aid
)
```

⚠️ Note: `.aid` is in the skip list, which is correct — the index scans the project, not the discovery output that lives in `.aid/`.

### 6.4 Portable mtime detection

⚠️ Not directly inspected this pass; asserted from `project-structure.md` and `project-index.md`'s listing of `build-project-index.sh` as the largest shell file (368 lines), implying coverage of cross-platform `stat` invocation (GNU vs. BSD). Needs spot check.

---

## 7. Markdown Conventions

Inferred from a sample of ~20 files across this repo:

| Element | Convention | Source |
|---------|-----------|--------|
| Heading hierarchy | Single H1 per file, then H2 / H3. No H1 skipping. | `aid-methodology.md`, every SKILL.md, every template |
| Section dividers | `---` on its own line between H2 sections (state-machine skills especially) | `aid-discover/SKILL.md:38`, `80`, `217`, `252`, `294`, `350` |
| Tables | Pipe tables with header separator. Cells left-aligned unless numeric. | every template that uses tables |
| Code blocks | Triple-backtick fenced, language-tagged (`bash`, `markdown`, `csharp`, `typescript`, `mermaid`) | `aid-discover/SKILL.md:107` (`bash`), `templates/knowledge-base/data-model.md:51-58` (`mermaid`) |
| Inline code | Backticks for paths (`templates/scripts/build-project-index.sh`), filenames, flags (`--grade`), tool names (`Read`, `Glob`) | universal across SKILL.md and agent bodies |
| Emphasis | `**bold**` for required terms and key constraints; `_italic_` for empty-state placeholders (`_No issues yet._`) | `templates/implementation-state.md:18`, agent "Key Constraints" sections |
| Warning markers | `⚠️` emoji for inferred / uncertain claims. `✅` / `❌` for binary pass/fail. | `templates/knowledge-base/coding-standards.md:7`, `project-structure.md` (extensively) |
| Em-dash usage | Free use of `—` for parenthetical clauses ("Generated by — aid-discover (Phase 1)") | every KB doc header, every template |

---

## 8. Filename Conventions

| Class | Convention | Example | Source |
|-------|-----------|---------|--------|
| Skill slugs | `aid-{phase}` kebab-case | `aid-discover`, `aid-interview` | every `skills/aid-*/` |
| Agent slugs | kebab-case | `discovery-reviewer`, `simple-extractor` | `claude-code/.claude/agents/*.md` |
| KB documents | kebab-case `.md` | `module-map.md`, `coding-standards.md`, `data-model.md`, `tech-debt.md` | `templates/knowledge-base/*.md` |
| State files | `SCREAMING-KEBAB-CASE.md` | `DISCOVERY-STATE.md`, `INTERVIEW-STATE.md`, `MONITOR-STATE.md`, `FEATURE-STATE.md` | `claude-code/.claude/templates/interview-state.md:1` (`# INTERVIEW-STATE.md`), `aid-discover/SKILL.md` (extensively) |
| First-class methodology artifacts | UPPERCASE.md | `REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`, `CLAUDE.md`, `AGENTS.md`, `README.md`, `LICENSE`, `CONTRIBUTING.md` | `templates/requirements/requirements-template.md:16` ("File is uppercase (`REQUIREMENTS.md`) — it's a first-class artifact") |
| Feedback artifacts | UPPERCASE-prefix + numeric ID | `IMPEDIMENT-{id}.md`, `KI-{n}` (known issue) | `templates/feedback-artifacts/IMPEDIMENT.md:1` |
| Per-tool layout root | tool-name slug + dotted-hidden | `claude-code/.claude/`, `codex/.codex/`, `cursor/.cursor/` | `project-structure.md:64-66` |
| Codex split | `codex/.codex/agents/` (TOML) + `codex/.agents/{skills,templates}/` (markdown) | — | `external-sources.md:81` |
| Shell scripts | kebab-case `.sh` | `build-project-index.sh`, `grade.sh`, `check-preflight.sh`, `verify-kb.sh`, `validate-html.sh` | `project-index.md` |
| JavaScript modules | kebab-case `.js` or `.mjs` (mjs for ESM) | `lightbox.js`, `mermaid-init.js`, `validate-diagrams.mjs`, `contrast-check.mjs` | `project-index.md` |
| Cursor rules | kebab-case `.mdc` | `aid-methodology.mdc`, `aid-review.mdc` | `cursor/.cursor/rules/` |

**Anomaly:** `.claude/settings..json` (note the **double dot** in the filename) sits alongside `.claude/settings.json` at the repo root. Likely a typo. Flagged in `project-structure.md` as Anomaly 2.

---

## 9. The "Triplicate Updates" Rule

CONFIRMED — explicit in `CONTRIBUTING.md:21-26`:

```
Important: When updating a skill or agent, update ALL locations:
1. skills/aid-{phase}/README.md — human docs
2. claude-code/skills/aid-{phase}/SKILL.md — LLM version
3. codex/skills/aid-{phase}/SKILL.md — LLM version (shared body, Codex-specific frontmatter)

Same for agents: update the human README, Claude Code .md, and Codex .toml.
```

**Real path correction:** `CONTRIBUTING.md` shows the paths as `claude-code/skills/` and `codex/skills/` — but the actual on-disk paths are `claude-code/.claude/skills/` and `codex/.agents/skills/`. The CONTRIBUTING file is slightly stale in its path examples. ⚠️ Q34.

**Cursor is NOT listed** in CONTRIBUTING.md's triplicate rule (the doc enumerates only 3 locations), but Cursor support has since been added — Cursor is mentioned separately in `cursor/README.md`. So the discipline is actually **quadruplicate**: human README + Claude Code + Codex + Cursor. CONTRIBUTING.md needs updating.

---

## 10. Conventions NOT Enforced

This section is critical because it bounds what "convention" means in this repo. ALL of the following are observed gaps:

| Convention | Status |
|-----------|--------|
| Linter for SKILL.md frontmatter | **None.** No JSON Schema, no `yamllint`, no `frontmatter-validator`. A contributor could add an arbitrary frontmatter field and nothing would warn. |
| Linter for TOML agent files | **None.** Standard TOML syntax errors would fail at load time but field correctness is unchecked. |
| Triplication drift detection | **None.** No script compares `skills/aid-X/README.md` against `claude-code/.claude/skills/aid-X/SKILL.md` body, etc. The 244-vs-453-vs-1078-vs-1090 line divergence on `aid-discover` is visible only by manual `wc -l`. |
| Markdown linter | **None.** No `markdownlint` config, no `remark` setup, no `.markdownlintrc`. |
| Spell-check | **None.** |
| CI workflow | **None.** No `.github/workflows/`, no `.gitlab-ci.yml`, no Jenkinsfile (per `project-structure.md:225-226`). |
| Pre-commit hooks | **None.** No `.pre-commit-config.yaml`, no `husky` setup. |
| Test runner for shell scripts | **None.** `build-project-index.sh` (368 lines) and `grade.sh` (141 lines) ship with no tests. |
| Schema for KB document status strings | **None.** "Status" vocabulary is informal (see §4.1). |
| Versioning | **None.** No `VERSION` file, no semver tag at the repo level; "V3" is referenced in prose only. |
| Code-style guide for `lightbox.js` / `*.mjs` | **None.** No `eslint`, no `prettier`. |

**Implication for contributors:** Every convention documented above is **descriptive**, not prescriptive at the tooling level. A change that violates any of them will land cleanly. The only enforcement loop is human review at PR time.

---

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-05-21 | aid-discover (discovery-analyst) | Initial dogfood pass: 10 convention areas mined from SKILL.md, agent, .mdc, KB-document, template, and shell-script samples. "Conventions NOT enforced" section identifies tooling gaps. |
