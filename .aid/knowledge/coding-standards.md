# Coding Standards

> **Source:** aid-discover (discovery-analyst)
> **Status:** Populated (cycle-11 FIX — post work-002 canonical-generator + work-003 FR2)
> **Last Updated:** 2026-05-23

> ⚠️ **Important:** Because this repo has effectively **no source code** (no Java/Python/Go/TS service, no `package.json`, no compiled artifact), the "coding standards" mined here are the **authoring conventions for AID's own asset types** — SKILL.md, agent definitions, KB documents, templates, scripts. These are the conventions a contributor must follow when editing `canonical/` (the source of truth) before re-running `run_generator.py`. Every claim cites a file path. Unless marked CONFIRMED, conventions are **inferred from a small sample** (typically 2–5 files of each kind); a wider sample may surface exceptions.

---

## 1. Skill File (SKILL.md) Conventions

### 1.1 Frontmatter — required fields

The `SKILL.md` frontmatter is YAML, delimited by `---` lines. Verified directly against `canonical/skills/aid-discover/SKILL.md:1-10`, `canonical/skills/aid-init/SKILL.md:1-10`, and the propagated copies in `profiles/claude-code/.claude/skills/aid-discover/SKILL.md:1-10`, `profiles/codex/.agents/skills/aid-discover/SKILL.md:1-10`, `profiles/cursor/.cursor/skills/aid-discover/SKILL.md:1-10`. All four locations use **the same shape** (the canonical-generator emits identical bodies; only profile-specific tool-name substitutions like `Bash` → `Terminal` for Cursor differ):

| Field | Required | Type | Example |
|-------|----------|------|---------|
| `name` | yes | string (kebab-case) | `name: aid-discover` |
| `description` | yes | YAML block scalar (`>` folded) | multi-line; first sentence is summary, second mentions state machine if applicable |
| `allowed-tools` | yes | comma-separated list (NOT YAML array) | `allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent` |
| `argument-hint` | optional | quoted string | `argument-hint: "[--grade A] minimum acceptable grade (default: A)  [--reset] clear KB and restart"` |

**Observation — identical frontmatter + body across trees post-canonical-generator.** `aid-discover/SKILL.md` is 596 lines in all 4 locations (canonical + 3 profiles), verified 2026-05-23. The pre-work-002 narrative ("Claude Code 453 / Codex 1,078 / Cursor 1,090 — divergent") is RETIRED. The frontmatter and body are emitted from a single canonical source by `render_skills.py` (450 lines in `.claude/skills/aid-generate/scripts/`).

⚠️ The Cursor and Codex SKILL.md frontmatter inherits the canonical `allowed-tools` shape; profile-specific tool-name remapping (e.g., Claude Code `Bash` → Cursor `Terminal`, per Q52) is performed by `render_skills.py` at emission time, so what lands in each profile already matches the host tool's tool vocabulary.

### 1.2 Body structure

A canonical SKILL.md body follows this section order (verified against `canonical/skills/aid-discover/SKILL.md`):

1. `# {Title}` — H1, sentence-case, descriptive (e.g., `# Brownfield Project Discovery`).
2. Opening paragraph — what the skill does, one paragraph, no lists.
3. `## ⚠️ Pre-flight Checks` — environment / state preconditions. Always present in skills that mutate state.
4. `## Arguments` — a markdown table mapping `--flag` → effect. Present whenever `argument-hint` is set.
5. `## State Detection` and `## Mode: {NAME}` sections — state-machine skills (`aid-discover`, `aid-summarize`) decompose into one H2 per mode.
6. `## Quality Checklist` — bullet checklist of what "done" means.
7. `## Grading Criteria` and/or `## Document Expectations` — when the skill grades its own output.

### 1.3 Decomposition idiom (post-canonical-generator)

When a skill body grows large, content is extracted into siblings under the canonical source:

- `references/*.md` — long-form prompts and explanations that the SKILL.md body refers to by filename.
- `scripts/*.sh` — runnable shell scripts invoked from the SKILL.md.

Example (`canonical/skills/aid-discover/`): SKILL.md (596 lines) + `references/agent-prompts.md` (142) + `references/document-expectations.md` (121) + `references/reviewer-prompt.md` (75) + `scripts/check-preflight.sh` (45) + `scripts/verify-kb.sh` (60) = 6 files, 1,039 lines total. The SKILL.md body uses phrases like "Read `references/agent-prompts.md` section `## Scout`".

**Post-work-002 propagation:** `run_generator.py` (top-level, 83 lines) reads each canonical skill folder and emits the full decomposition (SKILL.md + references/ + scripts/) verbatim into all 3 profile trees plus the dogfood `.claude/skills/`. The pre-work-002 narrative — "Claude Code factors out references/ while Codex / Cursor inline" — is RETIRED. Verified 2026-05-23: `wc -l` on `aid-discover/SKILL.md` returns 596 across canonical + all 3 profiles. The same `references/*.md` siblings are present in every profile tree. Contributors edit `canonical/` only; the generator handles the propagation.

⚠️ One historical exception remains visible in the file tree: `aid-interview/references/kb-hydration.md` (106 lines) — present in canonical and all 3 profiles. This is now the propagated norm, not an exception.

### 1.4 State-machine notation

State-machine skills (`aid-discover`, `aid-summarize`, `aid-execute`, `aid-interview`) consistently use this notation in the description / body:

- States named in `SCREAMING_CASE` (`GENERATE`, `REVIEW`, `Q&A`, `FIX`, `APPROVAL`, `DONE` in `aid-discover/SKILL.md:7`; `PREFLIGHT`, `STALE-CHECK`, `PROFILE`, `GENERATE`, `VALIDATE`, `FIX`, `APPROVAL`, `WRITEBACK`, `DONE` per `project-structure.md`).
- Arrows are `->` (ASCII) or `→` (Unicode); both appear interchangeably across files.
- `[State: {NAME}]` is printed at runtime (FR1 heartbeat — every canonical SKILL.md emits `[State:` markers; verified ≥3 per skill via `grep -c "\[State:"`).

### 1.5 Print-progress idiom

Skill bodies prescribe **literal `Print:` lines** for runtime status output, with bracketed step markers:

- `Print: \`[0c] Building project index...\``
- `Print: \`[1/5] Pre-scan: mapping project structure...\``
- `Print: \`Agent "[name]" completed. [N/4] done.\``

Pattern: `[step/total]` for counted phases, `[State: NAME]` for state transitions, plain bracketed prefix `[Review 1/2]`, `[Q&A]`, `[Fix]` for mode-specific output.

---

## 2. Agent File Conventions

### 2.1 Claude Code agent format

**File path (profile tree):** `profiles/claude-code/.claude/agents/{name}.md` — emitted from `canonical/agents/{name}/AGENT.md` by `render_agents.py` (503 lines).
**Frontmatter:** YAML between `---` lines. Required fields verified directly:

| Field | Required | Type | Source |
|-------|----------|------|--------|
| `name` | yes | string (kebab-case) | `profiles/claude-code/.claude/agents/architect.md:2` |
| `description` | yes | string OR YAML folded block | `architect.md:3` (single line), `discovery-reviewer.md:3-6` (folded block) |
| `tools` | yes | comma-separated list (NOT YAML array) | `architect.md:4` (`Read, Glob, Grep, Write, Edit, Bash`), `discovery-analyst.md:4` (`Read, Glob, Grep, Bash, Write`) |
| `model` | yes | one of `opus`/`sonnet`/`haiku` | `architect.md:5` (`opus`) |
| `permissionMode` | optional | string, observed value `bypassPermissions` | `discovery-reviewer.md:9`, `discovery-analyst.md:6` |
| `background` | optional | boolean | `discovery-reviewer.md:10` (`true`), `discovery-analyst.md:7` (`true`) |

**Body structure** (verified against `canonical/agents/architect/AGENT.md`, `discovery-analyst/AGENT.md`, `discovery-reviewer/AGENT.md`):

1. `# {Title}` — H1, omitted in some smaller agents (e.g., `architect/AGENT.md` opens with prose paragraph rather than H1).
2. Opening sentence: `You are a/an {Role} — {one-line mission}.`
3. `## What You Do` — bullet list of responsibilities.
4. `## What You Don't Do` — bullet list of boundaries (each item identifies which agent owns that work instead).
5. `## Key Constraints` — bold-prefixed bullets (`**Grounded in KB.**`, `**Specs are hypotheses.**`).
6. `## Output Format` — list of artifacts produced with template path references.
7. `## When to Escalate` — bullet list mapping situation → escalation route (a Q&A entry in a STATE file, or IMPEDIMENT.md).

Larger / discovery-tier agents add:
- `## Your Mission`, `## ⚠️ {section}`, `## Document Expectations` (`discovery-reviewer/AGENT.md`).
- `## ⚠️ File Writing` — warning footer about the Write-tool bug in background subagents, prescribing `cat > path << 'KBEOF' ... KBEOF`. CONFIRMED present in all three discovery sub-agents read.

### 2.2 Codex agent format

**File path (profile tree):** `profiles/codex/.codex/agents/{name}.toml` — emitted from `canonical/agents/{name}/AGENT.md` by `render_agents.py` with tier mapping applied. TOML at the top, then the prose body lives inside a `developer_instructions = """..."""` multi-line string.

| Field | Required | Type | Source |
|-------|----------|------|--------|
| `name` | yes | string | `profiles/codex/.codex/agents/architect.toml:1` (`name = "architect"`) |
| `description` | yes | string (single line) | `architect.toml:2` |
| `model` | yes | string (Codex model name) | `architect.toml:3` (`model = "gpt-5.5"`) |
| `model_reasoning_effort` | yes | one of `low` / `medium` / `high` | `architect.toml:4` (`high`), `simple-extractor.toml:4` (`low`) |
| `developer_instructions` | yes | triple-quoted multi-line string | `architect.toml:5-39` |

**Tier mapping (model + reasoning_effort)** — generator-enforced via `profiles/codex.toml`:

| Tier | Model | Reasoning effort | Verified |
|------|-------|-------------------|----------|
| Opus | `gpt-5.5` | `high` | `architect.toml:3-4`, `discovery-reviewer.toml`, all 6 discovery sub-agents |
| Sonnet | `gpt-5.4` | `medium` | ✅ VERIFIED across all 9 Sonnet-tier `profiles/codex/.codex/agents/*.toml` files (orchestrator, developer, operator, researcher, devops, data-engineer, performance, tech-writer, ux-designer) |
| Haiku | `gpt-5.4-mini` | `low` | `simple-extractor.toml:3-4` |

✅ The Sonnet tier mapping is VERIFIED. The May 2026 tier-rename migration documented in `profiles/codex/README.md:35` was confirmed clean across all 22 agents × 3 install trees post-generator.

**Body inside `developer_instructions`:** same H2 section order as Claude Code (`## What You Do`, `## What You Don't Do`, `## Key Constraints`, `## Output Format`, `## When to Escalate`). **Note:** the Codex body uses **markdown headers inside a triple-quoted TOML string** — the markdown rendering depends on Codex CLI's interpretation.

### 2.3 Cursor agent format

**File path (profile tree):** `profiles/cursor/.cursor/agents/{name}.md` — emitted from `canonical/agents/{name}/AGENT.md` by `render_agents.py`. Per `project-index.md`, line counts are essentially identical to Claude Code (e.g., both `architect.md` files are 39 lines; both `discovery-reviewer.md` files are 378 lines). **Same YAML frontmatter shape as Claude Code, same body structure.**

✅ VERIFIED: line-count parity per `project-index.md` (regenerated 2026-05-23) holds across all 22 agents.

### 2.4 Cross-tree filename substitution (handled by the generator)

`discovery-reviewer` historically had real semantic drift between trees (Claude Code → `CLAUDE.md` for project context, Codex → `AGENTS.md`; Claude Code → `additional-info.md` for open questions, Codex → `open-questions.md`). Post-canonical-generator, these substitutions are centralized in `harness.substitute_filenames` and applied during emission. Contributors edit `canonical/agents/{name}/AGENT.md` with **canonical placeholders**; the generator substitutes per-profile.

**Post-FR2 update:** Both `DISCOVERY-STATE.md` and `DISCOVERY-GRADE.md` are RETIRED — `discovery-reviewer` now writes to `.aid/knowledge/STATE.md` (Discovery area) regardless of profile. Same shape, single name across all 3 trees.

---

## 3. Cursor `.mdc` Rule Conventions

`.mdc` files live under `canonical/rules/` (source of truth) and are propagated to `profiles/cursor/.cursor/rules/` by the generator. Cursor injects them into the agent context per its precedence rules.

**Frontmatter** (YAML between `---` lines), verified from `canonical/rules/aid-methodology.mdc:1-4` and `canonical/rules/aid-review.mdc:1-5`:

| Field | Required | Type | Example |
|-------|----------|------|---------|
| `description` | yes | quoted string | `description: "AID methodology workflow and Knowledge Base integration"` |
| `alwaysApply` | yes | boolean | `alwaysApply: true` or `alwaysApply: false` |
| `globs` | optional | quoted glob expression — REQUIRED when `alwaysApply: false` | `globs: "**/*.{java,py,ts,js,cs,go,rs}"` |

**Two distinct rule classes observed:**

1. **Always-on rules** (`alwaysApply: true`, no `globs`) — `aid-methodology.mdc` (40 lines per `project-index.md:238`). Inject KB-first workflow on every request.
2. **Glob-scoped rules** (`alwaysApply: false`, with `globs`) — `aid-review.mdc` (11 lines). Inject review constraints only when editing source files matching the glob.

**Body convention:** plain markdown, no required H1 / H2 structure. The `aid-methodology.mdc` body uses `## Knowledge Base`, `## Workspace Structure`, `## Workflow` H2s; `aid-review.mdc` is a flat numbered list of 5 review checks.

---

## 4. KB Document Conventions

Every file under `.aid/knowledge/*.md` carries a **metadata header block** as its first content after the H1. Verified against the canonical templates (`canonical/templates/knowledge-base/module-map.md:1-7`, `canonical/templates/knowledge-base/data-model.md:1-7`, `canonical/templates/knowledge-base/coding-standards.md:1-9`) and against actual KB instances on disk.

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
- `aid-discover (discovery-scout)` / `aid-discover (discovery-analyst)` / etc. — narrowed to the specific sub-agent.
- `aid-init + aid-discover (discovery-scout) enrichment` — multi-producer file.

**Status vocabulary** observed across the on-disk KB:
- `❌ Pending Discovery` — the templated placeholder, used by `aid-init`'s scaffolding.
- `⚠️ Paths Registered / web fetch deferred` — partial status with caveat.
- `⚠️ URLs registered + local cross-reference — web fetch deferred` — variant.
- `Populated (initial dogfood pass)` — fully populated with discovery output.
- `Populated (cycle-NN FIX — ...)` — after a FIX cycle (this document, cycle-11 FIX).

⚠️ The status vocabulary is **not formally enumerated** anywhere — it has emerged organically. There is no central list of valid status strings — a contributor inventing a new status would not violate any explicit rule. ⚠️ Q33 below.

### 4.2 Body structure

After the metadata block, KB documents follow per-document templates under `canonical/templates/knowledge-base/`. Each ends with a `## Revision History` table:

```markdown
## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | {date} | aid-discover | Initial discovery |
```

### 4.3 Inferred-content marking

Per `canonical/templates/knowledge-base/coding-standards.md` and `canonical/agents/discovery-analyst/AGENT.md` ("Mark inferred conventions with ⚠️ Inferred from code — needs confirmation"), facts inferred from code (rather than from documentation) carry a `⚠️` prefix. The `aid-discover/SKILL.md` Quality Checklist enforces this: "Inferred info marked with ⚠️".

### 4.4 File-path citation requirement

`canonical/agents/discovery-analyst/AGENT.md` ("Every claim must cite a file path. No unsourced assertions") and `aid-discover/SKILL.md` ("Claims grounded in code evidence (file paths, line numbers)") establish that every factual claim in a KB document must have an inline `path:line` citation. This convention is enforced post-hoc by `discovery-reviewer` (minimum 15 spot-checks, 5 of which must verify versions/counts) and by `canonical/templates/scripts/verify-kb-claims.sh` (356 lines) which does grep-based fact-checking against on-disk reality.

---

## 5. Template File Conventions

### 5.1 Placeholder syntax

Templates use **single curly braces** for placeholders: `{Project Name}`, `{date}`, `{grade}`. Verified across:
- `canonical/templates/knowledge-base/INDEX.md:1` (`# Knowledge Base Index — {Project Name}`)
- `canonical/templates/knowledge-base/module-map.md` (`| {module-name} | {what it does in one sentence} | ...`)
- `canonical/templates/knowledge-base/data-model.md` (`| **Type** | {PostgreSQL / MySQL / SQLite / SQL Server / MongoDB / DynamoDB / other} |`)
- `canonical/templates/discovery-state-template.md:5` (`- **Minimum Grade:** {grade}`)
- `canonical/templates/work-state-template.md:5` (`> **Minimum Grade:** {from .aid/knowledge/STATE.md}`)
- `canonical/templates/delivery-plans/task-template.md:1` (`# task-NNN: {Name}`)

**Convention:**
- Single braces for fillable values.
- Pipe-separated enumerations inside braces show the allowed set: `{✅ Complete | ⚠️ Partial | ❌ Missing}`.
- Slash-separated also seen, equivalent: `{PostgreSQL / MySQL / SQLite / ...}`. Both notations co-exist — no single convention.

**Other observed placeholder patterns:**
- `*(pending)*` — italic-parenthesized placeholder for not-yet-addressed sections (`canonical/templates/requirements/requirements-template.md:14`).
- `<!-- Comment -->` — HTML comment blocks for guidance the user should remove (`canonical/templates/feedback-artifacts/IMPEDIMENT.md:18`, `canonical/templates/known-issues.md:6`).
- `_No issues yet._` / `_none yet_` — italicized empty-state strings (`canonical/templates/work-state-template.md:36`).

### 5.2 Templates-within-templates

Some templates document the **template-of-a-template**: `canonical/templates/requirements/requirements-template.md` is structured as `# Requirements Template` (lines 1–18 documentation) then a fenced code block (lines 22–80) containing the actual template to copy. **Convention:** the file-level H1 is the *meta* title (e.g., "REQUIREMENTS.md Template"), the fenced block inside is the *substantive* template starting with its own `# Requirements` H1.

### 5.3 Conditional sections

Templates use HTML comments to gate optional sections: `canonical/templates/specs/spec-template.md:54-75` lists 18 conditional sections (`### API Contracts`, `### UI Specs`, `### Events & Messaging`, `### DDD Analysis`, `### BDD Scenarios`, etc.) inside `<!-- ... -->` to be activated by `aid-specify` only when the feature warrants them.

---

## 6. Shell-Script Conventions

Verified from `canonical/templates/scripts/build-project-index.sh:1-40` and consistent with `project-structure.md`'s catalog of runtime scripts.

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

Verified at `canonical/templates/scripts/build-project-index.sh:1-20`. The opening comment block:
- Line 1: `#!/usr/bin/env bash` (NOT `#!/bin/bash` — portable shebang convention).
- Line 2: comment with script filename + em-dash + one-line purpose.
- Lines 3+: multi-line description, each line `#`-prefixed.
- A `Usage:` block listing flag invocations.
- `set -euo pipefail` immediately after the comment block.

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

⚠️ Not all scripts follow this convention rigorously — `canonical/templates/knowledge-summary/scripts/writeback-state.sh` (173 lines) lacks `-h|--help` handling and lacks GRADE format validation (Q191, pending fix).

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

⚠️ Not directly inspected this pass; asserted from `project-structure.md` and `project-index.md`'s listing of `build-project-index.sh` as 368 lines, implying coverage of cross-platform `stat` invocation (GNU vs. BSD). Needs spot check.

---

## 7. Markdown Conventions

Inferred from a sample of ~20 files across this repo:

| Element | Convention | Source |
|---------|-----------|--------|
| Heading hierarchy | Single H1 per file, then H2 / H3. No H1 skipping. | `aid-methodology.md`, every SKILL.md, every template |
| Section dividers | `---` on its own line between H2 sections (state-machine skills especially) | `canonical/skills/aid-discover/SKILL.md` |
| Tables | Pipe tables with header separator. Cells left-aligned unless numeric. | every template that uses tables |
| Code blocks | Triple-backtick fenced, language-tagged (`bash`, `markdown`, `csharp`, `typescript`, `mermaid`) | `aid-discover/SKILL.md`, `canonical/templates/knowledge-base/data-model.md` |
| Inline code | Backticks for paths (`canonical/templates/scripts/build-project-index.sh`), filenames, flags (`--grade`), tool names (`Read`, `Glob`) | universal across SKILL.md and agent bodies |
| Emphasis | `**bold**` for required terms and key constraints; `_italic_` for empty-state placeholders (`_None yet._`) | `canonical/templates/work-state-template.md:36`, agent "Key Constraints" sections |
| Warning markers | `⚠️` emoji for inferred / uncertain claims. `✅` / `❌` for binary pass/fail. | `canonical/templates/knowledge-base/coding-standards.md:7`, `project-structure.md` (extensively) |
| Em-dash usage | Free use of `—` for parenthetical clauses ("Generated by — aid-discover (Phase 1)") | every KB doc header, every template |

---

## 8. Filename Conventions

| Class | Convention | Example | Source |
|-------|-----------|---------|--------|
| Skill slugs | `aid-{phase}` kebab-case | `aid-discover`, `aid-interview` | every `canonical/skills/aid-*/` |
| Agent slugs | kebab-case | `discovery-reviewer`, `simple-extractor` | `canonical/agents/*/` |
| KB documents | kebab-case `.md` | `module-map.md`, `coding-standards.md`, `data-model.md`, `tech-debt.md` | `canonical/templates/knowledge-base/*.md` |
| State files | See §8.5 below (FR2 area-STATE rule) | `STATE.md` (areas), `MONITOR-STATE.md` (deferred) | `canonical/templates/{discovery,work}-state-template.md` |
| First-class methodology artifacts | UPPERCASE.md | `REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`, `CLAUDE.md`, `AGENTS.md`, `README.md`, `LICENSE`, `CONTRIBUTING.md` | `canonical/templates/requirements/requirements-template.md:16` |
| Feedback artifacts | UPPERCASE-prefix + numeric ID | `IMPEDIMENT-{id}.md`, `KI-{n}` (known issue) | `canonical/templates/feedback-artifacts/IMPEDIMENT.md:1` |
| Per-tool layout root | tool-name slug + dotted-hidden | `profiles/claude-code/.claude/`, `profiles/codex/.codex/`, `profiles/cursor/.cursor/` | `project-structure.md` |
| Codex split | `profiles/codex/.codex/agents/` (TOML) + `profiles/codex/.agents/{skills,templates}/` (markdown) | — | `external-sources.md` |
| Shell scripts | kebab-case `.sh` | `build-project-index.sh`, `grade.sh`, `check-preflight.sh`, `verify-kb.sh`, `validate-html.sh`, `writeback-state.sh` | `project-index.md` |
| JavaScript modules | kebab-case `.js` or `.mjs` (mjs for ESM) | `lightbox.js`, `mermaid-init.js`, `validate-diagrams.mjs`, `contrast-check.mjs` | `project-index.md` |
| Cursor rules | kebab-case `.mdc` | `aid-methodology.mdc`, `aid-review.mdc` | `canonical/rules/` |

**Anomaly:** `.claude/settings.local.json` sits alongside `.claude/settings.json` at the repo root — this is intentional (`local` is for per-developer overrides). Confirmed normal.

---

### 8.5 State file naming (FR2 area-STATE rule)

State files use **area-based consolidation** (per `work-003-traceability/REQUIREMENTS.md` FR2).

| Area | File path | What it tracks |
|---|---|---|
| Discovery | `.aid/knowledge/STATE.md` | KB documents status, knowledge summary status, Q&A, review history, summarization history |
| Work | `.aid/work-NNN-{name}/STATE.md` | Interview status, features status, plan/deliveries, tasks status, deploy status, cross-phase Q&A, lifecycle history |
| Monitor *(deferred)* | `.aid/work-NNN-{name}/MONITOR-STATE.md` | Observations, classifications, action routing — area not mature; follows the same area-STATE pattern when authored. The standalone naming reflects that Monitor is itself the state (no separate artifact to suffix against). |

**Naming rule:** the state file is named `STATE.md` (plain) when it tracks a directory of multiple artifacts (Discovery, Work). It is named `{AREA}-STATE.md` (SCREAMING-KEBAB) when the state is itself the artifact (Monitor).

**Retired patterns** (one-time consolidation completed in `work-003-traceability/feature-002`):
- Per-skill SCREAMING-KEBAB: `INTERVIEW-STATE.md`, `SUMMARY-STATE.md`, `DEPLOYMENT-STATE.md` — absorbed into area STATE files.
- Plain `STATE.md` per feature: `features/<name>/STATE.md` — absorbed.
- Artifact-named: `task-NNN-STATE.md` — absorbed.

**Artifact files keep their inline `## Change Log` sections** — that is content history, distinct from process state. Artifact files (REQUIREMENTS.md, SPEC.md, PLAN.md, task-NNN.md, KB docs) are unchanged by FR2.

**Canonical templates** for area STATE files: `canonical/templates/{discovery,work}-state-template.md` (83 + 82 lines respectively).

## 9. The Canonical-Generator Authoring Rule (replaces the old "Triplicate Updates" rule)

**Post-work-002 discipline (CONFIRMED, generator-enforced):**

```
When updating a skill, agent, template, or rule:
1. Edit canonical/ ONLY — never edit profile trees directly.
   - canonical/skills/aid-{phase}/{SKILL.md, README.md, references/*.md, scripts/*.sh}
   - canonical/agents/{name}/{AGENT.md, README.md}
   - canonical/templates/...
   - canonical/rules/*.mdc (Cursor-specific extras)
2. Run: python run_generator.py
3. Verify VERIFY-4a passes (byte-deterministic emission).
4. Commit canonical/ changes + the regenerated profiles/{claude-code,codex,cursor}/ + .claude/ together.
```

**Why this replaces the old rule:** Before work-002, the same logical asset existed in 4 parallel locations (`skills/`, `profiles/claude-code/.claude/skills/`, `profiles/codex/.agents/skills/`, `profiles/cursor/.cursor/skills/`) and contributors had to manually keep them in sync per `CONTRIBUTING.md:21-26`. That discipline produced documented drift (line counts diverging 244 / 453 / 1078 / 1090 for `aid-discover`). Post-work-002:
- `canonical/` is the single source of truth (`canonical/skills/`, `canonical/agents/`, `canonical/templates/`, `canonical/rules/`).
- `run_generator.py` (top-level, 83 lines) reads `canonical/` + profile manifests (`profiles/{tool}.toml`) and re-emits all 3 profile trees plus the dogfood `.claude/` tree.
- Generator scripts (`.claude/skills/aid-generate/scripts/{render_agents.py 503, render_skills.py 450, render_templates.py 245}`) handle profile-specific substitutions (e.g., tool-name remapping `Bash` → `Terminal` for Cursor, Codex tier mapping `opus` → `gpt-5.5`).
- `verify_deterministic.py` (513 lines) confirms byte-equality across emission targets.
- Emission manifests at `profiles/{tool}/emission-manifest.jsonl` track every file emitted.

**Pre-work-002 narrative RETIRED:** The "manual triplicate/quadruplicate update" rule and the `CONTRIBUTING.md:21-26` reference to it are obsolete. `CONTRIBUTING.md` itself was updated as part of the cleanup; see also the deletion of the pre-work-002 top-level `skills/` and `agents/` directories.

**Residual contributor discipline:**
- Edit `canonical/` only; do not edit `profiles/{tool}/` or `.claude/` directly (such edits are wiped on the next generator run).
- After `canonical/` edits, run `python run_generator.py` and commit the regenerated files alongside.
- Profile-specific filename substitutions (e.g., `CLAUDE.md` vs `AGENTS.md` for project-context) are handled by `harness.substitute_filenames` — extend that table when adding new substitution patterns, not the canonical body.
- ⚠️ Orphan detection in `run_generator.py` is still being hardened (Q190 follow-up): new files appearing in `profiles/{tool}/...` but absent from `canonical/` are caught by `verify_advisory.py` but not blocked.

---

## 10. Conventions NOT Enforced

This section is critical because it bounds what "convention" means in this repo. ALL of the following are observed gaps:

| Convention | Status |
|-----------|--------|
| Linter for SKILL.md frontmatter | **None.** No JSON Schema, no `yamllint`, no `frontmatter-validator`. A contributor could add an arbitrary frontmatter field to a canonical SKILL.md and nothing would warn; the generator would propagate the typo. |
| Linter for TOML agent files | **None.** Standard TOML syntax errors would fail at load time (and `profile.py:516` validates *profile* TOML) but field correctness on emitted agent TOML is unchecked. |
| Canonical-vs-profile drift detection | **Generator-enforced for the canonical→profile direction** (via `verify_deterministic.py`). Profile-side manual edits are caught by the next `run_generator.py` run (they get overwritten). New files appearing in profiles but not canonical → flagged by `verify_advisory.py` but not blocked. |
| Markdown linter | **None.** No `markdownlint` config, no `remark` setup, no `.markdownlintrc`. |
| Spell-check | **None.** |
| CI workflow | **None.** No `.github/workflows/`, no `.gitlab-ci.yml`, no Jenkinsfile. |
| Pre-commit hooks | **None.** No `.pre-commit-config.yaml`, no `husky` setup. |
| Test runner for shell scripts | **Partial.** No bats/shellcheck integration. The Python generator has `test_manifest_safety.py` (254 lines) — sole automated test in the repo. |
| Schema for KB document status strings | **None.** "Status" vocabulary is informal (see §4.1). |
| Versioning | **None.** No `VERSION` file, no semver tag at the repo level; "V3" is referenced in prose only. |
| Code-style guide for `lightbox.js` / `*.mjs` | **None.** No `eslint`, no `prettier`. |

**Implication for contributors:** Every convention documented above is **descriptive**, not prescriptive at the tooling level (with the partial exception of canonical→profile byte-equality, which `run_generator.py` enforces). A change to `canonical/` that violates any of these conventions will land cleanly and propagate. The only enforcement loop is human review at PR time, plus `verify-kb-claims.sh` for KB-fact integrity.

---

## Revision History

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-05-21 | aid-discover (discovery-analyst) | Initial dogfood pass: 10 convention areas mined from SKILL.md, agent, .mdc, KB-document, template, and shell-script samples. "Conventions NOT enforced" section identifies tooling gaps. |
| 1.1 | 2026-05-23 | aid-discover cycle-11 FIX (KB-FIX work) | §1.1, §1.3 rewritten to describe canonical-generator pattern (work-002): canonical is source of truth, `run_generator.py` propagates byte-identically to 3 profile trees + dogfood. Retired the "Claude Code 453 / Codex 1,078 / Cursor 1,090 divergence" narrative — all four locations now 548 lines for `aid-discover/SKILL.md`. §2.1-§2.3, §3, §5.1, §5.2, §5.3 path citations updated from `profiles/...` to `canonical/...` (the source of truth). §2.4 rewrote cross-tree filename drift section to note generator-centralized substitution + FR2 STATE.md unification. §6.2 added Q191 note. §8 row for "State files" reduced to a pointer at §8.5 (which is already correct from CW7). §9 fully rewritten as "Canonical-Generator Authoring Rule" — the old "Triplicate Updates Rule" referencing `CONTRIBUTING.md:21-26` is RETIRED. §10 row on "Triplication drift detection" updated to "Canonical-vs-profile drift detection (generator-enforced)". §8.5 (FR2 area-STATE rule) preserved unchanged from CW7. Resolves cycle-11 HIGH findings on coding-standards.md §1.3 + §9. |
