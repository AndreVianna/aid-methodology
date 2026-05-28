# API Contracts

> AID ships **no HTTP services, no RPC endpoints, no SDK clients** — it is a methodology
> distribution. "API contracts" here means the **interfaces between pipeline components**:
> skill ↔ subagent dispatch contracts, script CLI signatures + exit codes, file-format
> contracts (settings.yml, emission-manifest.jsonl, heartbeat files, STATE.md sections),
> and the canonical → 3-profile renderer contract.
>
> All claims below cite `path:line` against the canonical source.

---

## Exposed APIs — End-User Slash Commands

These are the only "endpoints" the user invokes. Each is an AID skill installed at
`.claude/skills/<skill>/SKILL.md` (Claude Code), `.codex/agents/*` + `.agents/skills/<skill>/`
(Codex split layout), or `.cursor/skills/<skill>/` (Cursor).

### `/aid-config`

- **Type:** Setup / configuration skill
- **Auth:** None (local filesystem only)
- **Request:** `(none)` for view-all mode, or `<dotted.key>` (e.g., `project.name`,
  `review.minimum_grade`, `discover.minimum_grade`) for view/update mode
- **Response:** Table of settings to stdout, or interactive update prompt
- **Side effects:** Creates `.aid/settings.yml` from template on first run; updates the
  named key in place on Mode 2
- **Source:** `canonical/skills/aid-config/SKILL.md:1-80` (frontmatter + Mode 1/Mode 2 table)
- **Allowed-tools:** `Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion`
  (`canonical/skills/aid-config/SKILL.md:8`)

### `/aid-discover [--grade A] [--reset]`

- **Type:** State-machine skill; one state per invocation
- **States:** `GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE`
  (`canonical/skills/aid-discover/SKILL.md:7`, `:54-59`)
- **Request:** Optional `--grade [A-F][-+]?` overrides minimum grade; `--reset` clears
  `.aid/knowledge/` and restarts (`canonical/skills/aid-discover/SKILL.md:62-68`)
- **Response:** Console output of state-entry line, "you are here" map, and per-state
  artifacts
- **Side effects:** Writes 16 KB docs + `STATE.md` + `INDEX.md` to `.aid/knowledge/`
- **Source:** `canonical/skills/aid-discover/SKILL.md:1-200`

### `/aid-interview [work-NNN] [--reset work-NNN] [--features work-NNN]`

- **Type:** Multi-agent state-machine skill (10+ states across full + lite paths)
- **States:** `FIRST-RUN → Q-AND-A → TRIAGE → {full: CONTINUE → COMPLETION → FEATURE-DECOMPOSITION → CROSS-REFERENCE → DONE | lite: CONDENSED-INTAKE → TASK-BREAKDOWN → LITE-REVIEW → LITE-DONE | escalated: any lite → CONTINUE → ...}` (`canonical/skills/aid-interview/SKILL.md:8`)
- **Agents dispatched:** `interviewer` (States 1–4, TRIAGE, L1), `architect` (State 5, L2),
  `reviewer` (State 6, L3), inline (L4, State 7) (`canonical/skills/aid-interview/SKILL.md:18-30`)
- **Source:** `canonical/skills/aid-interview/SKILL.md:1-200`

### `/aid-specify <work-NNN/feature-NNN> [--reset]`

- **Type:** Per-feature conversational refinement state machine
- **States:** `INITIALIZE → CONTINUE → REVIEW → DONE` (loopback: SPIKE / BLOCKED)
  (`canonical/skills/aid-specify/SKILL.md:8`)
- **Source:** `canonical/skills/aid-specify/SKILL.md:1-60`

### `/aid-plan [work-NNN] [--reset]`

- **States:** `FIRST-RUN → REVIEW → DONE` (`canonical/skills/aid-plan/SKILL.md:7`)
- **Source:** `canonical/skills/aid-plan/SKILL.md:1-60`

### `/aid-detail [work-NNN] [--reset]`

- **States:** `FIRST-RUN → REVIEW → DONE` (`canonical/skills/aid-detail/SKILL.md:8`)
- **Source:** `canonical/skills/aid-detail/SKILL.md:1-60`

### `/aid-execute <task-NNN> [work-NNN]`

- **States:** `EXECUTE → REVIEW → FIX → REVIEW → DONE` (`canonical/skills/aid-execute/SKILL.md:6`)
- **Branch contract:** One branch per delivery (`aid/delivery-NNN`); RESEARCH/DOCUMENT
  tasks that produce only `.aid/` artifacts may skip branching
  (`canonical/skills/aid-execute/SKILL.md:53-71`)
- **Source:** `canonical/skills/aid-execute/SKILL.md:1-280`

### `/aid-deploy [work-NNN]`

- **States:** `IDLE → SELECTING → VERIFYING → PACKAGING → DONE`
  (`canonical/skills/aid-deploy/SKILL.md:8`)
- **Source:** `canonical/skills/aid-deploy/SKILL.md:1-100`

### `/aid-monitor <work-NNN> [--since YYYY-MM-DD] [--package package-NNN]`

- **States:** `OBSERVE → CLASSIFY → ROUTE → DONE` (`canonical/skills/aid-monitor/SKILL.md:8`)
- **Source:** `canonical/skills/aid-monitor/SKILL.md:1-80`

### `/aid-summarize [--grade X] [--profile auto|web-app|library|cli|microservices|data-pipeline] [--theme palette=X] [--cdn-mermaid] [--reset]`

- **States:** `PREFLIGHT → STALE-CHECK → PROFILE → GENERATE → VALIDATE → MANUAL-CHECKLIST → FIX → APPROVAL → WRITEBACK → DONE` (`canonical/skills/aid-summarize/SKILL.md:10-11`)
- **Two-grade gate:** APPROVAL requires BOTH `Machine Grade ≥ minimum` AND
  `Human Grade ≥ minimum` (`canonical/skills/aid-summarize/SKILL.md:7-8`)
- **Source:** `canonical/skills/aid-summarize/SKILL.md:1-80`

---

## Internal API — Skill → Subagent Dispatch Contract

### Universal Subagent-Dispatch Brief (the "Reviewer-Dispatch Protocol")

Every skill that dispatches a reviewer subagent MUST pass a brief with EXACTLY 5 sections
in this order:

1. `ARTIFACTS UNDER REVIEW:` — explicit file list (no wildcards beyond the artifact set)
2. `CONTEXT:` — descriptive-only background (CONTEXT discipline rule)
3. `RUBRIC: <named rubric>` — which rubric applies
4. `OUT OF SCOPE (do not grade against):` — explicit exclusions
5. `OUT-OF-SCOPE FINDINGS POLICY:` — log to ledger; excluded from severity counts
6. `DELIVERABLES:` — findings format, severity scale, grade computation
- **Source:** `canonical/templates/reviewer-dispatch.md:1-80`

### Heartbeat / Long-Wait Protocol (L1+L2+L3 traceability)

Every long-running subagent dispatch MUST:

1. **L1** — Look up ETA in `canonical/templates/rough-time-hints.md`; emit
   `▶ <agent> starting (~<LOW>-<HIGH>)` bracket on dispatch
   (`canonical/templates/long-wait-protocol.md:38-49`)
2. **L2** — Arm THREE separate `run_in_background: true` bash timers at
   `<LOW/2>`, `<LOW>`, `<1.5×LOW>` minutes — each emits a check-in echo
   (`canonical/templates/long-wait-protocol.md:43-49`,
   `canonical/skills/aid-discover/SKILL.md:89-95`)
3. **L3** — Pre-create heartbeat file at `.aid/.heartbeat/<agent>-<unix-ts>.txt`,
   pass `HEARTBEAT_FILE=<path>` + `HEARTBEAT_INTERVAL=Nm` in dispatch prompt
   (`canonical/templates/subagent-heartbeat-protocol.md:39-72`)
4. **Subagent contract:** every N minutes, write a single-line status via shell echo
   using `>` (overwrite), pipe-delimited fields
   (`canonical/templates/subagent-heartbeat-protocol.md:74-115`)
5. **On completion:** emit `✓ <agent> done in <actual>`, append a row to the work
   `STATE.md ## Calibration Log`, update `## Dispatches` sub-column, delete heartbeat file
   (`canonical/skills/aid-discover/SKILL.md:104-111`)

**Configuration knob:** `traceability.heartbeat_interval` (integer minutes; default `1`;
`0` disables) in `.aid/settings.yml`, resolved by
`bash canonical/scripts/config/read-setting.sh --path traceability.heartbeat_interval --default 1`
(`canonical/templates/subagent-heartbeat-protocol.md:20-37`).

### Subagent-Side Heartbeat Block (boilerplate in every AGENT.md)

Every `canonical/agents/<agent>/AGENT.md` contains a `## Heartbeat protocol` section that
specifies the contract: read `HEARTBEAT_FILE` + `HEARTBEAT_INTERVAL` from prompt, write
shell-generated timestamp via `echo > "$HEARTBEAT_FILE"`, use `|` delimiters, change
`<activity>` between updates. Example: `canonical/agents/reviewer/AGENT.md:11-32`,
`canonical/agents/architect/AGENT.md:11-32`, `canonical/agents/simple-extractor/AGENT.md:11`.

### Discovery Sub-Agent Prompt Contract (`agent-prompts.md`)

The discover orchestrator passes 5 prose prompts — one per sub-agent — that each declare:
1. The KB files the sub-agent owns and must write (`.aid/knowledge/<file>.md`)
2. Required reference documents to read FIRST (`project-index.md`,
   `project-structure.md`, `external-sources.md`)
3. The contract phrase "Write only to the .aid/knowledge/ directory."

**Sub-agents:**
- **Scout** — writes `project-structure.md`, `external-sources.md` + temp `.scout-questions.tmp`
- **Architect** — writes `architecture.md`, `technology-stack.md`
- **Analyst** — writes `module-map.md`, `coding-standards.md`, `schemas.md`
- **Integrator** — writes `pipeline-contracts.md`, `integration-map.md`, `domain-glossary.md`
- **Quality** — writes `test-landscape.md`, `tech-debt.md`, `infrastructure.md`

**Source:** `canonical/skills/aid-discover/references/agent-prompts.md:1-143`

### Reviewer Output Contract — Structured Issue List

The Reviewer agent produces a structured issue list with two-tag classification per issue:

- **Source tag:** `[CODE]`, `[TASK]`, `[SPEC]`, `[KB]`, `[ARCHITECTURE]`
- **Severity tag:** `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]`, `[MINOR]`
- **Evidence required:** file path, line number, criterion violated
- **Reviewer does NOT:** fix issues, compute the grade, or open files outside ARTIFACTS
  UNDER REVIEW (except citation resolution)
- **Source:** `canonical/agents/reviewer/AGENT.md:34-60`

---

## Internal API — Script CLIs

### `bash canonical/scripts/config/read-setting.sh`

- **Purpose:** Single point of read access for `.aid/settings.yml`
- **Two modes:**
  - **Skill mode:** `--skill <name> --key <key> [--default V]` — applies override
    resolution: per-skill key → `review.<key>` → `--default` → exit 1
    (`canonical/scripts/config/read-setting.sh:212-232`)
  - **Path mode:** `--path <dotted.path> [--default V]` — direct lookup, no override
    resolution; supports scalar + list-valued keys
    (`canonical/scripts/config/read-setting.sh:234-263`)
- **Output:** Stdout = resolved value (single line; list values comma-joined).
  Stderr = errors (always include absolute file path for debuggability)
  (`canonical/scripts/config/read-setting.sh:32-37`)
- **Exit codes:** `0` value found / default used; `1` value missing AND no default;
  `2` arg error / settings.yml unreadable (`canonical/scripts/config/read-setting.sh:27-31`)
- **Caller invariants:** ALL grade lookups in every aid-* skill MUST resolve through
  this script — never read settings.yml directly. Example callers:
  `canonical/skills/aid-execute/SKILL.md:44` (`--skill execute --key minimum_grade --default A`),
  `canonical/skills/aid-discover/SKILL.md:84` (`--path traceability.heartbeat_interval`),
  `canonical/skills/aid-summarize/SKILL.md:50` (`--skill summary --key minimum_grade`).

### `bash canonical/scripts/grade.sh`

- **Purpose:** Universal AID-rubric grade computation (severity tags → letter grade)
- **Input:** Markdown text on stdin OR a file path argument containing `[CRITICAL] [HIGH]
  [MEDIUM] [LOW] [MINOR]` tags
- **Output:** Single line: one of `A+ A A- B+ B B- C+ C C- D+ D D- E+ E E- F`
- **Rubric (deterministic):** Worst severity present dominates the letter; count within
  that tier sets the modifier (1 = `+`, 2–5 = nothing, 6+ = `-`). `--non-functional`
  flag forces `F`. (`canonical/scripts/grade.sh:100-126`)
- **Filters:** Strips fenced code blocks AND inline backticks before counting,
  to suppress false positives from prose-quoted tags
  (`canonical/scripts/grade.sh:68-82`)
- **Source:** `canonical/scripts/grade.sh:1-141`

### `bash canonical/scripts/execute/writeback-task-status.sh`

- **Purpose:** Race-safe writes to work `STATE.md ## Tasks Status` from parallel pool
- **4 modes:**
  - `--task-id NNN --field FIELD --value VALUE` — update single field
    (Fields: `Status | Review | Elapsed | Notes | Wave | Type`)
  - `--task-id NNN --findings BLOCK` — write/replace `### task-NNN` block under
    `## Quick Check Findings`
  - `--delivery-id NNN --block MARKDOWN_BLOCK` — write `### delivery-NNN` block under
    `## Delivery Gates`
  - `--delivery-id NNN --append-issue ROW` — append issue row to
    `delivery-NNN-issues.md`
- **Locking:** Sentinel-file lock (`set -o noclobber` + atomic create + sleep-poll
  retry) prevents races when parallel tasks dispatch reviewers concurrently
- **Exit codes:** `0` success; `1` STATE missing; `2` lock contention timeout;
  `3` empty/unverifiable; `4` invalid arg; `5` missing required arg; `6` malformed
  STATE.md (`canonical/scripts/execute/writeback-task-status.sh:32-39`)
- **Test suite:** 69 tests at `tests/canonical/writeback-task-status.sh`
- **Source:** `canonical/scripts/execute/writeback-task-status.sh:1-100`

### `bash canonical/scripts/execute/compute-block-radius.sh`

- **Purpose:** BFS over execution graph; given a failed task, returns all tasks that
  transitively depend on it (the "block-radius")
- **Input modes:** `--failed-task NNN --plan-file PATH` (parses Execution Graph from
  PLAN.md/SPEC.md) OR `--failed-task NNN --graph-file PATH` (pre-computed TSV
  reverse-graph snapshot)
- **Output:** One `task-NNN` per line, sorted ascending. Empty if failed task has no
  dependents. Failed task itself is NOT in output.
- **Exit codes:** `0` success; `1` arg missing / file not found; `2` failed task not in
  graph (warn, succeed with empty); `4` invalid arg value; `5` missing required arg
- **Algorithm:** BFS with visited-set; AND-only dependency edges (no alternative paths)
- **Test suite:** 17 tests at `tests/canonical/compute-block-radius.sh`
- **Source:** `canonical/scripts/execute/compute-block-radius.sh:1-80`

### `bash canonical/scripts/execute/complexity-score.sh`

- **Purpose:** Compute delivery-complexity score (Small / Medium / Large) for DELIVERY-GATE
  reviewer tier selection
- **Input:** `--plan-file PATH --delivery-id NNN` OR `--graph-file PATH`, both with
  optional `--tasks-dir`, `--quick-check-state`, `--consults N`
- **Output:** Stdout — `tasks=N`, `depth=N`, `risk=N`, `consults=N`, `score=N`,
  `tier=Small|Medium|Large` (one per line)
- **Thresholds:** Low=6, High=14 by default; reads `.aid/knowledge/STATE.md` overrides
  via `$AID_KB_STATE`
- **Source:** `canonical/scripts/execute/complexity-score.sh:1-80`

### `bash canonical/scripts/interview/parse-recipe.sh`

- **Purpose:** Recipe parser for FR8 lite-path slot-fill
- **5 modes:**
  - `--list RECIPE_FILE` — emit unique slot names (one per line, order of first appearance)
  - `--validate RECIPE_FILE` — compare front-matter `slot-count`/`task-count` against
    actual body counts; warns (exit 0) on mismatch
  - `--render --recipe RECIPE_FILE --slots-json SLOTS_JSON_FILE --work-dir WORK_DIR` —
    substitute `{{slot-name}}` tokens, apply `{!{ → {{` escape, emit `SPEC.md` +
    `tasks/task-NNN.md` files (sentinel lock to coordinate concurrent writes)
  - `--spec RECIPE_FILE` — emit raw `## spec` block content
  - `--tasks RECIPE_FILE` — emit raw `## tasks` block content
- **Exit codes:** `0` success; `1` file missing; `2` malformed front-matter; `3` missing
  required body block; `4` invalid arg; `5` missing required arg; `6` work dir creation
  failed; `7` render write error; `8` lock contention timeout
- **Slot lexical rule:** `[a-z][a-z0-9-]*` (no underscores, uppercase, dots, spaces)
- **JSON parser dep:** `python3` or `python` (no jq required)
- **Test suite:** 113 tests at `tests/canonical/parse-recipe.sh`
- **Source:** `canonical/scripts/interview/parse-recipe.sh:1-100`

### `bash canonical/scripts/kb/verify-claims.sh`

- **Purpose:** Validate KB citations against disk (the "anti-drift" pass)
- **Flags:** `--kb PATH` (default `.aid/knowledge`), `--root PATH` (default `.`),
  `--format human|tsv`, `--include-state` (also verify citations in `STATE.md`),
  `--quiet`
- **Exit codes:** `0` all passed; `1` at least one broken citation or count drift;
  `2` usage error / KB dir missing (`canonical/scripts/kb/verify-claims.sh:28-32`)
- **Adopter-aware:** discovers script's own install-tree root so prefix resolution
  works in `canonical/`, `.claude/scripts/kb/`, `.agents/scripts/kb/`,
  `.cursor/scripts/kb/` contexts (`canonical/scripts/kb/verify-claims.sh:35-43`)
- **Source:** `canonical/scripts/kb/verify-claims.sh:1-60`

### `bash canonical/scripts/kb/build-project-index.sh`

- **Purpose:** Build `.aid/generated/project-index.md` — pre-built file inventory used by
  discovery sub-agents as a shared input (replaces re-scanning the repo)
- **Flags:** `--root .`, `--output .aid/knowledge/project-index.md`
- **Source:** `canonical/scripts/kb/build-project-index.sh` (368 lines per
  `.aid/knowledge/project-structure.md:153`)

### `bash canonical/scripts/summarize/run-validators.sh <html-file> [--fast]`

- **Purpose:** VALIDATE-state orchestrator for `/aid-summarize` — runs all automated
  checks; emits the two-grade report
- **Two-grade model:**
  - **Machine Grade** — automated checks only (`AUTO_POOL = D1 D2 L1 L2 H1 A1 A2 A3 A4 A5 C1 C2 S2`; 73 pts max)
  - **Human Grade** — manual checklist only (`MANUAL_POOL = K1 K2 V1`; 30 pts max)
  - **Overall Grade** — the lower of the two letter grades
  - V1 (visual gate) is **mandatory**: V1=0 forces Human Grade = F
- **A+ requires:** Machine ≥ 98% × 73 AND Human ≥ 98% × 30
- **Diagram-count hard rule:** Reads active profile from `STATE.md ## Knowledge Summary
  Status`; reads `target_diagrams` from `templates/knowledge-summary/section-templates/
  {profile}.md` front-matter (fallback 6); actual < target → grade capped at C+
- **Exit codes:** `0` Machine Grade ≥ A-; `1` Machine Grade < A-; `2` invocation error
- **Source:** `canonical/scripts/summarize/run-validators.sh:1-80`

### `bash canonical/scripts/summarize/fetch-mermaid.sh`

- **Purpose:** Fetches latest Mermaid library from npm + jsdelivr CDN; caches to
  `.aid/knowledge/.cache/mermaid.min.js`
- **Output (stdout last line):** `VERSION=x.y.z PATH=.aid/knowledge/.cache/mermaid.min.js SHA256=...`
- **Cache hit:** Re-uses cache when version unchanged (no download)
- **External dependencies:** `curl`, `sha256sum` or `shasum -a 256`
- **Source:** `canonical/scripts/summarize/fetch-mermaid.sh:1-78`

### `bash canonical/scripts/kb/preflight.sh <knowledge-dir>`

- **Purpose:** Discovery pre-flight gate — verifies (1) `STATE.md` exists (init has run),
  (2) not in Plan Mode
- **Source:** `canonical/scripts/kb/preflight.sh:1-46`

### `node canonical/scripts/summarize/validate-diagrams.mjs <html-file> [--fast]`

- **Purpose:** Extracts `<pre class="mermaid">` blocks; runs D1 parse-check (regex + jsdom
  `mermaid.parse()`) and D2 render-check (jsdom `mermaid.render()` → assert SVG > 500
  bytes, contains `<g>`/`<path>`, no error markers)
- **Exit codes:** `0` all pass; `1` one or more failed; `2` invocation error
- **Fallback:** Falls back to regex-only if `jsdom` not installed
- **Source:** `canonical/scripts/summarize/validate-diagrams.mjs:1-80`

---

## Internal API — Skill ↔ Settings Contract

### `.aid/settings.yml` Read Contract

| Key (dotted path) | Type | Default | Purpose | Consumer skills |
|-------------------|------|---------|---------|-----------------|
| `project.name` | string | `<project-name>` placeholder | Identity | All skills, AGENTS.md/CLAUDE.md |
| `project.description` | string | `<project-description>` placeholder | Sole source of truth (not duplicated) | All skills |
| `project.type` | enum | `brownfield` | `brownfield` or `greenfield` | `aid-discover` (skipped on greenfield) |
| `tools.installed` | list | `[claude-code]` | Which install trees exist | Renderer + `aid-summarize` |
| `review.minimum_grade` | grade | `A` | Global REVIEW exit criterion | All skills with REVIEW state |
| `execution.max_parallel_tasks` | integer | `5` | Parallel pool capacity | `aid-execute` PD-0..PD-6 |
| `traceability.heartbeat_interval` | integer min | `1` (0 disables) | L3 heartbeat cadence | Every dispatcher (always) |
| `<skill>.minimum_grade` | grade | inherits `review.minimum_grade` | Per-skill override | The named skill |

**Resolution order** (skill mode): per-skill override → `review.<key>` → script `--default`
→ exit 1. (`canonical/scripts/config/read-setting.sh:212-232`)
**Source of truth:** `canonical/templates/settings.yml:1-82`

---

## File-Format Contracts

### Emission Manifest (`{profile}/emission-manifest.jsonl`)

The authoritative safety boundary for the generator's pure-mirror deletion logic.

- **Format:** JSON Lines (`.jsonl`); LF line endings; trailing `\n` on every record
- **First line (sentinel):** `{"_manifest_version": 1}` — reserved object
- **Record schema (exactly 4 keys):**
  - `profile` (string) — `"claude-code" | "codex" | "cursor"`
  - `src` (string) — repo-relative path inside `canonical/`
  - `dst` (string) — install-tree path relative to manifest's directory
  - `sha256` (string) — lowercase hex SHA-256 of rendered bytes
- **Ordering:** Lexicographic by `dst` (byte-stable across re-runs — preserves AC2)
- **Locations:**
  - `profiles/claude-code/emission-manifest.jsonl` (Claude Code)
  - `profiles/codex/emission-manifest.jsonl` (Codex — covers both `.codex/` and `.agents/` roots)
  - `profiles/cursor/emission-manifest.jsonl` (Cursor)
- **Safety semantics:** Files outside any manifest are NEVER touched; `removed_dst` from
  manifest diff is the ONLY set of paths the generator may delete
- **Source:** `canonical/EMISSION-MANIFEST.md:1-152`

### Heartbeat File (`.aid/.heartbeat/<agent>-<unix-ts>.txt`)

- **Format:** Single line, pipe-delimited
- **Schema:** `[<ISO-8601-UTC>] <STATE> | <progress> | <activity> (~<eta-remaining>)`
- **Example:** `[2026-05-23T20:35:05Z] REVIEW | 4/21 docs | Checking line-count drift (~12m remaining)`
- **Write rule:** `>` (overwrite) NEVER `>>` (append); timestamp MUST be shell-generated
  via `$(date -u +%Y-%m-%dT%H:%M:%SZ)`
- **Parser-friendly:** `head -1` + `awk -F'|'`
- **Lifecycle:** Created by dispatcher; updated by subagent every N minutes; deleted by
  dispatcher on completion
- **Gitignore requirement:** `.aid/.heartbeat/` MUST be in `.gitignore`
- **Source:** `canonical/templates/subagent-heartbeat-protocol.md:74-176`

### Work `STATE.md` — Per-Area State Hub (FR2 consolidation)

A single STATE file per `.aid/work-NNN-{name}/` directory absorbs what used to be
`INTERVIEW-STATE.md` + per-feature `STATE.md` × N + per-task `task-NNN-STATE.md` × N +
(future) `DEPLOYMENT-STATE.md`. (`canonical/templates/work-state-template.md:9`)

**Required sections (consumed by various skills):**

| Section | Producer | Consumer | Source |
|---------|----------|----------|--------|
| `## Triage` | `aid-interview` TRIAGE | `aid-interview` lite/full router | `canonical/templates/work-state-template.md:13-24` |
| `## Escalation Carry` | lite→full escalation | CONTINUE state | `canonical/templates/work-state-template.md:26-43` |
| `## Interview Status` | `aid-interview` States 1–4 | `aid-interview` CONTINUE / COMPLETION | `canonical/templates/work-state-template.md:46-62` |
| `## Features Status` | `aid-specify` | `aid-plan`, `aid-detail` | `canonical/templates/work-state-template.md:63-69` |
| `## Plan / Deliveries` | `aid-plan` | `aid-detail`, `aid-execute` | `canonical/templates/work-state-template.md:71-77` |
| `## Tasks Status` | `aid-execute` (via writeback-task-status.sh) | All execute states + delivery gate | `canonical/templates/work-state-template.md:79-85` |
| `## Quick Check Findings` | reviewer (per-task) | Delivery gate aggregator | `canonical/scripts/execute/writeback-task-status.sh:17-18` |
| `## Delivery Gates` | reviewer (per-delivery) | `aid-deploy` | `canonical/scripts/execute/writeback-task-status.sh:20-23` |
| `## Deploy Status` | `aid-deploy` | `aid-monitor` | `canonical/templates/work-state-template.md:87-93` |
| `## Cross-phase Q&A (Pending)` | All phases (loopback writers) | Owning phase's Q&A state | `canonical/templates/work-state-template.md:95-100` |
| `## Calibration Log` | Every dispatcher (always-on, work-003) | Operator review | `canonical/skills/aid-discover/SKILL.md:104-107` |

### Knowledge-Base `STATE.md` (`.aid/knowledge/STATE.md`)

Equivalent area-STATE for the Discovery area:
- `## Q&A (Pending)` — questions raised by downstream phases targeting the KB
- `## Review History` — discover-cycle grades with timestamps
- `## Knowledge Summary Status` (FR2 home for `aid-summarize` profile + last-run state)
- `**User Approved:** yes | no` — the discovery approval gate
- **Source:** `canonical/skills/aid-discover/SKILL.md:152-159`,
  `canonical/scripts/summarize/run-validators.sh:74-80`

### Recipe File Front-matter Contract

```
---
name: bug-fix          # kebab; must match basename
applies-to: bug-fix    # bug-fix | small-refactor | single-doc | small-new-feature | *
slot-count: 4          # integer; must equal unique {{slot}} count in body
task-count: 1          # integer; must equal ### task-NNN heading count
---
```

All 4 fields required. Body must contain `## spec` and `## tasks` blocks. Slot lexical
rule: `[a-z][a-z0-9-]*`. Escape `{!{` → `{{` at render time.
- **Source:** `canonical/recipes/README.md:43-100`

### IMPEDIMENT-task-NNN.md Contract

When `aid-execute` discovers an assumption that doesn't hold, it writes
`.aid/{work}/IMPEDIMENT-task-NNN.md` rather than silently working around the problem.

Required sections: Summary, **Type** (one of `wrong-assumption | missing-dependency |
architecture-conflict | kb-gap`), Source, What Was Found, KB Impact, Options,
Recommendation. The type determines the resolution loop:
- `kb-gap` → targeted `/aid-discover` (Loop 6 / Loop 11)
- `architecture-conflict` → `/aid-specify`
- `missing-dependency` → `/aid-detail`
- `wrong-assumption` → update task or SPEC

- **Source:** `canonical/templates/feedback-artifacts/IMPEDIMENT.md:1-60`,
  `canonical/skills/aid-execute/SKILL.md:225-247`,
  `methodology/aid-methodology.md:596-606`

### Q&A Entry Contract (universal loopback artifact)

Every design-phase loop records the gap as a Q&A entry appended to the relevant phase's
STATE file. Required schema:

```
### IQ{N}: [{Category}: {Impact}]
**Question:** {what needs to be resolved}
**Context:** {why — what the calling phase found}
**Source:** {calling phase, e.g. /aid-plan work-001}
**Suggested:** {answer if inferrable, or —}
**Status:** Pending
```

The next run of the owning phase detects the pending entry and resolves it in Q&A mode.
- **Source:** `methodology/aid-methodology.md:652-661`

---

## Renderer Contract — Canonical → 3 Profile Trees

The generator (`run_generator.py` → `.claude/skills/aid-generate/scripts/*.py`) implements
a **pure-mirror** contract:

| Canonical source | Renderer | Claude Code output | Codex output | Cursor output |
|------------------|----------|--------------------|--------------|---------------|
| `canonical/agents/` | `render_agents.py` | `.claude/agents/` (Markdown) | `.codex/agents/` (TOML) | `.cursor/agents/` (Markdown) |
| `canonical/skills/` | `render_skills.py` | `.claude/skills/` | `.agents/skills/` | `.cursor/skills/` |
| `canonical/templates/` | `render_templates.py` | `.claude/templates/` | `.agents/templates/` | `.cursor/templates/` |
| `canonical/recipes/` | `render_recipes.py` | `.claude/recipes/` | `.agents/recipes/` | `.cursor/recipes/` |
| `canonical/scripts/` | `render_scripts.py` | `.claude/scripts/` | `.agents/scripts/` | `.cursor/scripts/` |

**Source:** `canonical/EMISSION-MANIFEST.md:110-130`

**Invariants:**
1. **AC2 byte-identity** — re-running the generator on unchanged inputs produces a
   byte-identical install tree AND a byte-identical manifest
   (`canonical/EMISSION-MANIFEST.md:46-50`)
2. **Skill bodies byte-identical across 4 trees** — `canonical/skills/<skill>/SKILL.md`
   + `.claude/skills/<skill>/SKILL.md` (dogfood) + 3 profile trees are bit-for-bit
   identical for the body portion (CLAUDE.md `## Architecture` bullet 1)
3. **Pure-mirror deletion** — only files in the previous manifest's `removed_dst` are
   deleted; files outside any manifest are NEVER touched
   (`canonical/EMISSION-MANIFEST.md:70-83`)

**Profile front-matter required fields:**

| Field | Claude Code | Codex | Cursor |
|-------|-------------|-------|--------|
| Agent file format | Markdown + YAML | TOML | Markdown + YAML |
| Required agent fields | `name, description, tools, model` | `name, description, model, model_reasoning_effort, developer_instructions` | (per `profiles/cursor.toml`) |
| Required skill fields | `name, description, allowed-tools` | `name, description, allowed-tools` | (per `profiles/cursor.toml`) |
| Source | `profiles/claude-code.toml:18-19` | `profiles/codex.toml:25-26` | `profiles/cursor.toml` |

**Filename-map contract** (substitution in canonical templates):

| Placeholder | claude-code | codex | cursor |
|-------------|-------------|-------|--------|
| `project_context_file` | `CLAUDE.md` | `AGENTS.md` | (per cursor.toml) |
| `reviewer_output_file` | `STATE.md` | `STATE.md` | `STATE.md` |
| `open_questions_file` | `additional-info.md` | `additional-info.md` | `additional-info.md` |

Source: `profiles/claude-code.toml:48-53`, `profiles/codex.toml:61-66`

**Model-tier mapping:**

| Tier | Claude Code | Codex | Cursor |
|------|-------------|-------|--------|
| `large` | `opus` | `gpt-5.5` (reasoning_effort=high) | (per cursor.toml) |
| `medium` | `sonnet` | `gpt-5.4` (medium) | (per cursor.toml) |
| `small` | `haiku` | `gpt-5.4-mini` (low) | (per cursor.toml) |

Source: `profiles/claude-code.toml:38-41`, `profiles/codex.toml:43-55`

---

## Consumed APIs — External Services

(See `.aid/knowledge/integration-map.md ## Third-Party Services` for the integration-side
view. Listed here for the contract-side completeness.)

| External service | Purpose | Client | Source |
|------------------|---------|--------|--------|
| `https://registry.npmjs.org/mermaid/latest` | Latest Mermaid version metadata | `curl -sSf --max-time 30` | `canonical/scripts/summarize/fetch-mermaid.sh:16-18` |
| `https://cdn.jsdelivr.net/npm/mermaid@<ver>/dist/mermaid.min.js` | Mermaid library bytes | `curl -sSf --max-time 120` | `canonical/scripts/summarize/fetch-mermaid.sh:41-47` |
| `gh` CLI (GitHub API) | PR creation, issue mgmt | Subprocess (per `CLAUDE.md` PR convention) | `CLAUDE.md` git/PR sections |

No SDKs, no HTTP clients in code beyond `curl` calls in 2 helper scripts. No persistent
connections, no auth tokens stored anywhere in the repo.

---

## Discrepancies (doc vs code)

- **`.aid/work-001-aid-lite/test-reports/e2e-*.sh` test runners** — `CLAUDE.md:35-36`
  references two test runners (35 + 38 tests) that are NOT present in the project
  index. `.aid/knowledge/project-structure.md:177-178` notes the work-001 directory was
  apparently retired or never committed to the `kb-overhaul` branch. ⚠️ Contract
  documented but no script present.
- **`run_generator.py` references `.aid/work-002-canonical-generator/`** as a verify-report
  sink (`.aid/knowledge/project-structure.md:312`) — also absent from the project index.
- **`profiles/codex.toml` `hooks`, `stop_hook_autocontinue` capabilities** — both marked
  `TODO: confirm` (`profiles/codex.toml:75, 78`); contract values present but unverified
  against the vendor docs.
