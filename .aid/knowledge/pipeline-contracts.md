---
kb-category: primary
source: hand-authored
intent: |
  Defines the interfaces between AID pipeline components. Because AID ships no HTTP services
  or RPC endpoints, "contracts" here means: skill slash-command signatures and state-machine
  contracts, script CLI signatures + exit codes, file-format contracts (settings.yml,
  emission-manifest.jsonl, heartbeat files, STATE.md sections), subagent dispatch conventions,
  and the canonical→5-profile renderer contract. Read this to understand what each pipeline
  boundary expects and emits.
contracts:
  - "11 user-facing skill slash-command contracts documented (aid-config through aid-monitor, aid-summarize, plus optional off-pipeline aid-housekeep) + maintainer-only aid-generate"
  - "discovery.doc_set in settings.yml: declared-set → dispatch mapping honors the set (no-hang on omission; dispatch on addition)"
changelog:
  - 2026-06-03: aid-housekeep merge (PR #49) — added /aid-housekeep as an optional off-pipeline skill with its consume/produce contracts (the STATE.md Impact:Required Q&A handshake with /aid-discover, the work-area ## Housekeep Status run-state block, the /aid-summarize delegation, the housekeep-state.sh / branch-commit.sh / cleanup-classify.sh CLI contracts); slash-command count 10→11 user-facing
  - 2026-06-01: work-001-add-providers merge (PRs #42/#43/#44) — renderer contract now spans 5 profiles (added copilot-cli + antigravity) and 4 agent formats (markdown/toml/copilot-agent/antigravity-rule); emission-manifest profile enum + manifest-locations updated
  - 2026-05-31: delivery-002 — added discovery.doc_set to settings read contract; added declared-set → dispatch contract section
  - 2026-05-27: Initial frontmatter added during cycle-1 FIX Phase B
---
# Pipeline Contracts

> AID ships **no HTTP services, no RPC endpoints, no SDK clients** — it is a methodology
> distribution. "API contracts" here means the **interfaces between pipeline components**:
> skill ↔ subagent dispatch contracts, script CLI signatures + exit codes, file-format
> contracts (settings.yml, emission-manifest.jsonl, heartbeat files, STATE.md sections),
> and the canonical → 5-profile renderer contract.
>
> All claims below cite `` `path` `` + a grep-recoverable anchor (symbol, heading, or
> unique string) against the canonical source — never a bare line number.

---

## Exposed APIs — End-User Slash Commands

These are the only "endpoints" the user invokes. Each is an AID skill installed at
`.claude/skills/<skill>/SKILL.md` (Claude Code), `.codex/agents/*` + `.agents/skills/<skill>/`
(Codex split layout), `.cursor/skills/<skill>/` (Cursor), `.github/skills/<slug>/SKILL.md`
(Copilot CLI native Agent Skills), or `.agent/skills/<slug>/SKILL.md` (Antigravity).

There are **11 user-facing skills** (`aid-config` … `aid-monitor`, `aid-summarize`, and the
optional off-pipeline `aid-housekeep`) plus maintainer-only `aid-generate`. Of these,
`aid-summarize` and `aid-housekeep` are **non-phase / optional** and `aid-housekeep` is
additionally **off the mandatory pipeline** (no phase gate references it; invoked on-demand).
Source: `find canonical/skills -maxdepth 1 -type d`,
`canonical/skills/aid-housekeep/SKILL.md` (`**Absent from the mandatory pipeline flow.**`).

### `/aid-config`

- **Type:** Setup / configuration skill
- **Auth:** None (local filesystem only)
- **Request:** `(none)` for view-all mode, or `<dotted.key>` (e.g., `project.name`,
  `review.minimum_grade`, `discover.minimum_grade`) for view/update mode
- **Response:** Table of settings to stdout, or interactive update prompt
- **Side effects:** Creates `.aid/settings.yml` from template on first run; updates the
  named key in place on Mode 2
- **Source:** `canonical/skills/aid-config/SKILL.md` (`## Mode 1 — Show all settings` +
  `## Mode 2 — View/update one key`)
- **Allowed-tools:** `Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion`
  (`canonical/skills/aid-config/SKILL.md` frontmatter `allowed-tools:`)

### `/aid-discover [--grade A] [--reset]`

- **Type:** State-machine skill; one state per invocation
- **States:** `GENERATE → REVIEW → Q-AND-A → FIX → APPROVAL → DONE`
  (`canonical/skills/aid-discover/SKILL.md` frontmatter `State-machine: GENERATE → REVIEW`,
  `## State Detection`)
- **Request:** Optional `--grade [A-F][-+]?` overrides minimum grade; `--reset` clears
  `.aid/knowledge/` and restarts (`canonical/skills/aid-discover/SKILL.md` `## Arguments`)
- **Response:** Console output of state-entry line, "you are here" map, and per-state
  artifacts
- **Side effects:** Writes 15 KB docs + `STATE.md` + `INDEX.md` to `.aid/knowledge/`
- **Source:** `canonical/skills/aid-discover/SKILL.md`

### `/aid-interview [work-NNN] [--reset work-NNN] [--features work-NNN]`

- **Type:** Multi-agent state-machine skill (10+ states across full + lite paths)
- **States:** `FIRST-RUN → Q-AND-A → TRIAGE → {full: CONTINUE → COMPLETION → FEATURE-DECOMPOSITION → CROSS-REFERENCE → DONE | lite: CONDENSED-INTAKE → TASK-BREAKDOWN → LITE-REVIEW → LITE-DONE | escalated: any lite → CONTINUE → ...}` (`canonical/skills/aid-interview/SKILL.md` frontmatter `State machine: FIRST-RUN → Q-AND-A → TRIAGE`)
- **Agents dispatched:** `interviewer` (States 1–4, TRIAGE, L1), `architect` (State 5, L2),
  `reviewer` (State 6, L3), inline (L4, State 7) (`canonical/skills/aid-interview/SKILL.md` `## Agents Involved`)
- **Source:** `canonical/skills/aid-interview/SKILL.md`

### `/aid-specify <work-NNN/feature-NNN> [--reset]`

- **Type:** Per-feature conversational refinement state machine
- **States:** `INITIALIZE → CONTINUE → REVIEW → DONE` (loopback: SPIKE / BLOCKED)
  (`canonical/skills/aid-specify/SKILL.md` frontmatter `State machine: INITIALIZE → CONTINUE → REVIEW → DONE`)
- **Source:** `canonical/skills/aid-specify/SKILL.md`

### `/aid-plan [work-NNN] [--reset]`

- **States:** `FIRST-RUN → REVIEW → DONE` (`canonical/skills/aid-plan/SKILL.md` frontmatter `State machine: FIRST-RUN → REVIEW → DONE`)
- **Source:** `canonical/skills/aid-plan/SKILL.md`

### `/aid-detail [work-NNN] [--reset]`

- **States:** `FIRST-RUN → REVIEW → DONE` (`canonical/skills/aid-detail/SKILL.md` frontmatter `State machine: FIRST-RUN → REVIEW → DONE`)
- **Source:** `canonical/skills/aid-detail/SKILL.md`

### `/aid-execute <task-NNN> [work-NNN]`

- **States:** `EXECUTE → REVIEW → FIX → REVIEW → DONE` (`canonical/skills/aid-execute/SKILL.md` frontmatter `State machine: EXECUTE → REVIEW → FIX`)
- **Branch contract:** One branch per delivery (`aid/delivery-NNN`); RESEARCH/DOCUMENT
  tasks that produce only `.aid/` artifacts may skip branching
  (`canonical/skills/aid-execute/SKILL.md` `### Check 5: Branch Isolation`)
- **Source:** `canonical/skills/aid-execute/SKILL.md`

### `/aid-deploy [work-NNN]`

- **States:** `IDLE → SELECTING → VERIFYING → PACKAGING → DONE`
  (`canonical/skills/aid-deploy/SKILL.md` frontmatter `State machine: IDLE → SELECTING → VERIFYING → PACKAGING → DONE`)
- **Source:** `canonical/skills/aid-deploy/SKILL.md`

### `/aid-monitor <work-NNN> [--since YYYY-MM-DD] [--package package-NNN]`

- **States:** `OBSERVE → CLASSIFY → ROUTE → DONE` (`canonical/skills/aid-monitor/SKILL.md` frontmatter `State machine: OBSERVE → CLASSIFY → ROUTE → DONE`)
- **Source:** `canonical/skills/aid-monitor/SKILL.md`

### `/aid-summarize [--grade X] [--profile auto|web-app|library|cli|microservices|data-pipeline] [--theme palette=X] [--cdn-mermaid] [--reset]`

- **States:** `PREFLIGHT → STALE-CHECK → PROFILE → GENERATE → VALIDATE → MANUAL-CHECKLIST → FIX → APPROVAL → WRITEBACK → DONE` (`canonical/skills/aid-summarize/SKILL.md` frontmatter `State-machine: PREFLIGHT →`)
- **Two-grade gate:** APPROVAL requires BOTH `Machine Grade ≥ minimum` AND
  `Human Grade ≥ minimum` (`canonical/skills/aid-summarize/SKILL.md` frontmatter `APPROVAL requires BOTH grades >= minimum`)
- **Source:** `canonical/skills/aid-summarize/SKILL.md`

### `/aid-housekeep [--cleanup-only] [--grade X]` (optional — OFF the mandatory pipeline)

- **Type:** Optional, on-demand housekeeping state-machine skill; **not** part of the
  phase→skill mapping and no phase gate references it (REQUIREMENTS.md FR6). Runs three
  gated jobs in strict order on a dedicated `aid/housekeep-*` branch; **never pushes**.
- **States:** `PREFLIGHT → KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE`
  (`canonical/skills/aid-housekeep/SKILL.md` frontmatter
  `State-machine: PREFLIGHT → KB-DELTA → SUMMARY-DELTA →` + the "you are here" map
  `[ PREFLIGHT ] → [ KB-DELTA ] → [ SUMMARY-DELTA ] → [ CLEANUP ] → [ DONE ]`)
- **Request:** `--cleanup-only` jumps straight to CLEANUP (sets `**Mode:** cleanup-only`,
  bypasses KB+summary); `--grade X` (`[A-F][-+]?`) passes through to the SUMMARY-DELTA
  delegation to `/aid-summarize` (ignored under `--cleanup-only`). Any other flag → exit
  non-zero. (`canonical/skills/aid-housekeep/SKILL.md` `## Arguments`,
  `## State Detection` "Argument pre-check")
- **Gate ordering (C1):** strict order — SUMMARY-DELTA refuses unless `**KB Stage:**` is
  `passed`/`skipped`; one commit per stage (C3). Re-entrant: a stalled run resumes at the
  stalled stage via the six-row resume table (`canonical/skills/aid-housekeep/SKILL.md`
  `## State Detection`, `references/state-summary-delta.md` `## Step 0 — C1 guard`).
- **Consumes:**
  - work-area `STATE.md ## Housekeep Status` run-state block (resume detection), read via
    `housekeep-state.sh --resume`
  - `.aid/knowledge/STATE.md` — `**Last KB Review:**` (hint), `**User Approved:**` +
    `## Summarization History` (read-back)
  - `git fetch/log/diff` (hint only — no hard offline gate, C2)
- **Produces:**
  - work-area `STATE.md ## Housekeep Status` run-state fields (via `housekeep-state.sh --write`)
  - `.aid/knowledge/STATE.md ## Q&A (Pending)` — synthesizes an `**Impact:** Required`
    Style-A Q&A entry (`### Q{N}`) that drives `/aid-discover`'s Targeted Discovery
    re-entry (the handshake; never resolves owners itself)
    (`references/state-kb-delta.md` `## Step 4 — Synthesize an Impact: Required Q&A entry`)
  - one commit per stage on an `aid/housekeep-*` branch (via `branch-commit.sh`); CLEANUP
    deletes only user-confirmed stale `.aid/` artifacts (`git rm`/`rm`)
- **Delegations:** KB-DELTA → `/aid-discover` (targeted re-entry → REVIEW → Q-AND-A → FIX →
  APPROVAL); SUMMARY-DELTA → `/aid-summarize` (with optional `--grade X`, no other flags);
  both run unmodified. (`references/state-kb-delta.md` `## Step 4`,
  `references/state-summary-delta.md` `## Step 2 — Delegate to /aid-summarize`)
- **Source:** `canonical/skills/aid-housekeep/SKILL.md`,
  `canonical/skills/aid-housekeep/references/{state-preflight,state-kb-delta,state-summary-delta,state-cleanup,state-done}.md`

---

## Internal API — Skill → Subagent Dispatch Contract

### Universal Subagent-Dispatch Brief (the "Reviewer-Dispatch Protocol")

Every skill that dispatches a reviewer subagent MUST pass a brief with EXACTLY 6 sections
in this order:

1. `ARTIFACTS UNDER REVIEW:` — explicit file list (no wildcards beyond the artifact set)
2. `CONTEXT:` — descriptive-only background (CONTEXT discipline rule)
3. `RUBRIC: <named rubric>` — which rubric applies
4. `OUT OF SCOPE (do not grade against):` — explicit exclusions
5. `OUT-OF-SCOPE FINDINGS POLICY:` — log to ledger; excluded from severity counts
6. `DELIVERABLES:` — findings format, severity scale, grade computation
- **Source:** `canonical/templates/reviewer-dispatch.md` `## The brief structure`

### Heartbeat / Long-Wait Protocol (L1+L2+L3 traceability)

Every long-running subagent dispatch MUST:

1. **L1** — Look up ETA in `canonical/templates/rough-time-hints.md`; emit
   `▶ <agent> starting (~<LOW>-<HIGH>)` bracket on dispatch
   (`canonical/templates/long-wait-protocol.md` `### Step 1 — Look up ETA`)
2. **L2** — Arm THREE separate `run_in_background: true` bash timers at
   `<LOW/2>`, `<LOW>`, `<1.5×LOW>` minutes — each emits a check-in echo
   (`canonical/templates/long-wait-protocol.md` `### Step 2 — Emit opening bracket + arm 3 timers`,
   `canonical/skills/aid-discover/SKILL.md` `## Dispatch Protocol`)
3. **L3** — Pre-create heartbeat file at `.aid/.heartbeat/<agent>-<unix-ts>.txt`,
   pass `HEARTBEAT_FILE=<path>` + `HEARTBEAT_INTERVAL=Nm` in dispatch prompt
   (`canonical/templates/subagent-heartbeat-protocol.md` `## Orchestrator-side responsibilities (dispatcher)`)
4. **Subagent contract:** every N minutes, write a single-line status via shell echo
   using `>` (overwrite), pipe-delimited fields
   (`canonical/templates/subagent-heartbeat-protocol.md` `## Subagent-side responsibilities (the dispatched agent)`)
5. **On completion:** emit `✓ <agent> done in <actual>`, append a row to the work
   `STATE.md ## Calibration Log`, update `## Dispatches` sub-column, delete heartbeat file
   (`canonical/skills/aid-discover/SKILL.md` `## Dispatch Protocol`)

`aid-housekeep` carries the same L1+L2+L3 contract for its KB-DELTA sub-agent dispatches
(`canonical/skills/aid-housekeep/SKILL.md`
`## Dispatch Protocol (L1+L2+L3 subagent visibility, subagent-visibility-patch)`).

**Configuration knob:** `traceability.heartbeat_interval` (integer minutes; default `1`;
`0` disables) in `.aid/settings.yml`, resolved by
`bash canonical/scripts/config/read-setting.sh --path traceability.heartbeat_interval --default 1`
(`canonical/templates/subagent-heartbeat-protocol.md` `## Configuration`).

### Subagent-Side Heartbeat Block (boilerplate in every AGENT.md)

Every `canonical/agents/<agent>/AGENT.md` contains a `## Heartbeat protocol` section that
specifies the contract: read `HEARTBEAT_FILE` + `HEARTBEAT_INTERVAL` from prompt, write
shell-generated timestamp via `echo > "$HEARTBEAT_FILE"`, use `|` delimiters, change
`<activity>` between updates. Example: `canonical/agents/reviewer/AGENT.md` `## Heartbeat protocol`,
`canonical/agents/architect/AGENT.md` `## Heartbeat protocol`, `canonical/agents/simple-extractor/AGENT.md` `## Heartbeat protocol`.

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

**Source:** `canonical/skills/aid-discover/references/agent-prompts.md` (`## Scout` through `## Quality`)

### Reviewer Output Contract — Structured Issue List

The Reviewer agent produces a structured issue list with two-tag classification per issue:

- **Source tag:** `[CODE]`, `[TASK]`, `[SPEC]`, `[KB]`, `[ARCHITECTURE]`
- **Severity tag:** `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]`, `[MINOR]`
- **Evidence required:** file path, line number, criterion violated
- **Reviewer does NOT:** fix issues, compute the grade, or open files outside ARTIFACTS
  UNDER REVIEW (except citation resolution)
- **Source:** `canonical/agents/reviewer/AGENT.md` `## Output contract`, `## What You Don't Do`

---

## Internal API — Script CLIs

### `bash canonical/scripts/config/read-setting.sh`

- **Purpose:** Single point of read access for `.aid/settings.yml`
- **Two modes:**
  - **Skill mode:** `--skill <name> --key <key> [--default V]` — applies override
    resolution: per-skill key → `review.<key>` → `--default` → exit 1
    (`canonical/scripts/config/read-setting.sh` comment `# Skill mode: try per-skill override; fall back to review.<key>`)
  - **Path mode:** `--path <dotted.path> [--default V]` — direct lookup, no override
    resolution; supports scalar + list-valued keys
    (`canonical/scripts/config/read-setting.sh` comment `# Path mode: direct dotted-path lookup`)
- **Output:** Stdout = resolved value (single line; list values comma-joined).
  Stderr = errors (always include absolute file path for debuggability)
  (`canonical/scripts/config/read-setting.sh` header comment `# Exit codes:`)
- **Exit codes:** `0` value found / default used; `1` value missing AND no default;
  `2` arg error / settings.yml unreadable (`canonical/scripts/config/read-setting.sh` header comment `# Exit codes:`)
- **Caller invariants:** ALL grade lookups in every aid-* skill MUST resolve through
  this script — never read settings.yml directly. Example callers:
  `canonical/skills/aid-execute/SKILL.md` `### Check 3: Read Minimum Grade` (`--skill execute --key minimum_grade --default A`),
  `canonical/skills/aid-discover/SKILL.md` `## Dispatch Protocol` (`--path traceability.heartbeat_interval`),
  `canonical/skills/aid-summarize/SKILL.md` `## Arguments` (`--skill summary --key minimum_grade`),
  `canonical/skills/aid-housekeep/SKILL.md` `## Arguments` (`--skill summary --key minimum_grade --default A` for the SUMMARY-DELTA grade resolution).

### `bash canonical/scripts/grade.sh`

- **Purpose:** Universal AID-rubric grade computation (severity tags → letter grade)
- **Input:** Markdown text on stdin OR a file path argument containing `[CRITICAL] [HIGH]
  [MEDIUM] [LOW] [MINOR]` tags
- **Output:** Single line: one of `A+ A A- B+ B B- C+ C C- D+ D D- E+ E E- F`
- **Rubric (deterministic):** Worst severity present dominates the letter; count within
  that tier sets the modifier (1 = `+`, 2–5 = nothing, 6+ = `-`). `--non-functional`
  flag forces `F`. (`canonical/scripts/grade.sh` `modifier_for_count()`)
- **Filters:** Strips fenced code blocks AND inline backticks before counting,
  to suppress false positives from prose-quoted tags
  (`canonical/scripts/grade.sh` comments `# Strip fenced code blocks before counting.` +
  `# Strip inline backtick content.`)
- **Source:** `canonical/scripts/grade.sh`

### `bash canonical/scripts/execute/writeback-state.sh`

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
  STATE.md (`canonical/scripts/execute/writeback-state.sh` header comment `# Exit codes:`)
- **Test suite:** 69 tests at `tests/canonical/test-writeback-state.sh`
- **Source:** `canonical/scripts/execute/writeback-state.sh`

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
- **Test suite:** 17 tests at `tests/canonical/test-compute-block-radius.sh`
- **Source:** `canonical/scripts/execute/compute-block-radius.sh`

### `bash canonical/scripts/execute/complexity-score.sh`

- **Purpose:** Compute delivery-complexity score (Small / Medium / Large) for DELIVERY-GATE
  reviewer tier selection
- **Input:** `--plan-file PATH --delivery-id NNN` OR `--graph-file PATH`, both with
  optional `--tasks-dir`, `--quick-check-state`, `--consults N`
- **Output:** Stdout — `tasks=N`, `depth=N`, `risk=N`, `consults=N`, `score=N`,
  `tier=Small|Medium|Large` (one per line)
- **Thresholds:** Low=6, High=14 by default; reads `.aid/knowledge/STATE.md` overrides
  via `$AID_KB_STATE`
- **Source:** `canonical/scripts/execute/complexity-score.sh`

### `bash canonical/scripts/housekeep/housekeep-state.sh` (optional — /aid-housekeep)

- **Purpose:** Deterministic read/write of the nine `**Field:** value` lines inside the
  work-area `STATE.md ## Housekeep Status` block, and resolution of the `/aid-housekeep`
  resume target (the six-row re-entry table). No yq/python dependency (bash + grep/sed/awk).
- **3 modes:**
  - `--state FILE --write --field FIELD --value VALUE` — write/replace a `**FIELD:**` line
    (creates `## Housekeep Status` if absent; idempotent)
  - `--state FILE --read --field FIELD` — print the current value (empty line if absent;
    exit 0 even when section/field absent)
  - `--state FILE --resume [--cleanup-only]` — print one of
    `PREFLIGHT | KB-DELTA | SUMMARY-DELTA | CLEANUP | DONE` per the six-row resume table
    (`--cleanup-only` consulted only when no section exists)
- **Valid fields:** `State`, `Stage Status`, `Branch`, `Mode`, `Stall Reason`, `Last Run`,
  `KB Stage`, `Summary Stage`, `Cleanup Stage` (`VALID_FIELDS` array)
- **Exit codes:** `0` success; `1` STATE.md not found/unreadable; `2` argument error
  (unknown flag, missing value, incompatible flags); `3` write verification failed
  (`canonical/scripts/housekeep/housekeep-state.sh` header comment `# Exit codes:`)
- **Source:** `canonical/scripts/housekeep/housekeep-state.sh`

### `bash canonical/scripts/housekeep/branch-commit.sh` (optional — /aid-housekeep)

- **Purpose:** Two operations for `/aid-housekeep`: (1) ensure the `aid/housekeep-<slug>`
  branch (creates off `master` via `git switch -c`, or reuses an existing
  `aid/housekeep-*` branch on resume; refuses to operate directly on `master`); (2) make
  exactly ONE commit with the supplied message and `--add` paths. **Never runs `git push`**
  (enforced by a self-check that exits 4 if the script ever contains a `git push` call).
- **Modes:**
  - `--ensure-branch --slug <slug>` — ensure/switch to `aid/housekeep-<slug>`
  - `--commit --message <msg> [--add <path> ...]` — stage listed paths (or `--add-all`)
    and make one commit
  - combined `--ensure-branch ... --commit ...`
- **Exit codes:** `0` success; `1` git error; `2` argument error; `3` refused (current
  branch is master and `--ensure-branch` not requested); `4` refused (script contains
  `git push` — safety self-check) (`canonical/scripts/housekeep/branch-commit.sh` header
  comment `# Exit codes:`)
- **Source:** `canonical/scripts/housekeep/branch-commit.sh`

### `bash canonical/scripts/housekeep/cleanup-classify.sh` (optional — /aid-housekeep)

- **Purpose:** Deterministic, **read-only** scan+classify phase of the CLEANUP stage —
  inspects fixed conservative roots S1–S6 under `.aid/` and emits one candidate record per
  artifact. Performs **no deletion, no commit, no push, no UI** (enforced by a safety
  self-check that exits 1 if the script ever contains `rm`/`git rm`/`git commit`/`git push`).
- **Args:** `--root REPO_ROOT [--active-work WORK_FOLDER_NAME ...]` (active-work folders are
  excluded from S6 results; may be supplied multiple times)
- **Output (one line per candidate, stdout):**
  `PATH|TIER|TRACKED|DEFAULT_CHECKED|REASON[|GATE]` where `TIER`∈{0,1,2}, `TRACKED`∈
  {tracked,untracked}, `DEFAULT_CHECKED`∈{true,false}, `GATE` (Tier-1 only) ∈
  {offer, explicit-confirm:<reason>}
- **Exit codes:** `0` success (list may be empty); `1` REPO_ROOT not found or `.aid/`
  absent; `2` argument error (`canonical/scripts/housekeep/cleanup-classify.sh` header
  comment `# Exit codes:`)
- **Source:** `canonical/scripts/housekeep/cleanup-classify.sh`

### KB Citation Validation (`/aid-discover REVIEW`)

- **Purpose:** Validate KB citations against disk (the "anti-drift" pass)
- **Mechanism:** The `discovery-reviewer` sub-agent (dispatched in `/aid-discover REVIEW`
  state) performs frontmatter compliance checks, cited `file:line` existence verification,
  KB-file presence, and generated-files freshness. This semantic validation replaced
  the former `verify-claims.sh` script (deleted in cycle-1; closure recorded in `tech-debt.md` changelog).
- **Agent:** `canonical/agents/discovery-reviewer/AGENT.md`
- **Output:** ledger at `.aid/.temp/review-pending/discovery.md` with per-finding severity
  tags; grade computed by `canonical/scripts/grade.sh`

### `bash canonical/scripts/kb/build-project-index.sh`

- **Purpose:** Build `.aid/generated/project-index.md` — pre-built file inventory used by
  discovery sub-agents as a shared input (replaces re-scanning the repo)
- **Flags:** `--root .`, `--output .aid/knowledge/project-index.md`
- **Source:** `canonical/scripts/kb/build-project-index.sh` (368 lines per the
  `build-project-index.sh` row in `.aid/knowledge/project-structure.md`)

### `bash canonical/scripts/summarize/grade-summary.sh <html-file> [--fast]`

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
  (`canonical/scripts/summarize/grade-summary.sh` header comment `# Exit codes:`)
- **Source:** `canonical/scripts/summarize/grade-summary.sh`

### `bash canonical/scripts/summarize/fetch-mermaid.sh`

- **Purpose:** Fetches the pinned Mermaid library (v11.15.0) from jsdelivr CDN; caches to
  `.aid/knowledge/.cache/mermaid.min.js`. SHA-verified on both cache-hit and post-download paths.
- **Output (stdout last line):** `VERSION=x.y.z PATH=.aid/knowledge/.cache/mermaid.min.js SHA256=...`
- **Cache hit:** Re-uses cache when version matches `PINNED_VERSION` AND SHA matches `EXPECTED_SHA256`
- **External dependencies:** `curl`, `sha256sum` or `shasum -a 256`
- **Source:** `canonical/scripts/summarize/fetch-mermaid.sh` (`PINNED_VERSION` + `EXPECTED_SHA256` constants)

### `bash canonical/scripts/kb/discover-preflight.sh <knowledge-dir>`

- **Purpose:** Discovery pre-flight gate — verifies (1) `STATE.md` exists (init has run),
  (2) not in Plan Mode
- **Source:** `canonical/scripts/kb/discover-preflight.sh` (header comment `# Checks:`)

### `node canonical/scripts/summarize/validate-diagrams.mjs <html-file> [--fast]`

- **Purpose:** Extracts `<pre class="mermaid">` blocks; runs D1 parse-check (regex + jsdom
  `mermaid.parse()`) and D2 render-check (jsdom `mermaid.render()` → assert SVG > 500
  bytes, contains `<g>`/`<path>`, no error markers)
- **Exit codes:** `0` all pass; `1` one or more failed; `2` invocation error
- **Fallback:** Falls back to regex-only if `jsdom` not installed
- **Source:** `canonical/scripts/summarize/validate-diagrams.mjs` (header comment `// Validation strategy:`)

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
| `discovery.doc_set` | YAML block-list of pipe-delimited strings | absent (→ default seed) | Declared KB doc-set for this project; each item `filename\|owner\|presence[:when]` | `aid-discover` GENERATE + REVIEW states |

> `aid-housekeep` reads `summary.minimum_grade` / `review.minimum_grade` (skill-mode
> `--skill summary`) for SUMMARY-DELTA and `traceability.heartbeat_interval` (path-mode) for
> its KB-DELTA dispatches — no new settings keys are introduced.
> (`canonical/skills/aid-housekeep/SKILL.md` `## Arguments`, `## Dispatch Protocol`)

**Resolution order** (skill mode): per-skill override → `review.<key>` → script `--default`
→ exit 1. (`canonical/scripts/config/read-setting.sh` comment `# Skill mode: try per-skill override; fall back to review.<key>`)
**Source of truth:** `canonical/templates/settings.yml`

### Declared-Set → Dispatch Contract (`discovery.doc_set` → sub-agent dispatch)

**Source:** `canonical/skills/aid-discover/references/state-generate.md` `### Steps 2-5: Dispatch 4 Subagents in Parallel (data-driven from declared set)` + `canonical/skills/aid-discover/references/doc-set-resolve.md`.

The discover orchestrator resolves the active doc-set at GENERATE Step 0 and uses it
data-driven for every dispatch decision in Steps 2–5:

| Rule | Behavior |
|------|----------|
| **Mapping honors the set** | Each agent's target list = filenames where `owner = <agent>` in the declared set, intersected with missing-on-disk |
| **No-hang on omission** | If a doc is absent from the declared set, the owning agent's target list may be empty → that agent is NOT dispatched (no hang, no error) |
| **Dispatch on addition** | A custom doc added to the declared set with an owner → included in that agent's target list → agent dispatched for it |
| **Unknown owner fallback** | Unknown owner value → routed to `discovery-architect` with a non-fatal warning (FR-P1-5) |
| **Default seed (backward compat)** | If `discovery.doc_set` is absent/empty in settings.yml, `synth_default_seed` synthesizes the set from `canonical/templates/knowledge-base/*.md` using the §2.2 ownership map — no change to prior behavior |
| **Verify** | After dispatch, cross-check `count == size(list-filenames)` against the accessor, not a literal integer |

**Accessor functions** (pure bash+awk, inlined from `doc-set-resolve.md`):

| Accessor | Returns |
|----------|---------|
| `resolve_doc_set "$raw" \| cut -f1` | All filenames in the declared set (list-filenames) |
| `resolve_doc_set "$raw" \| awk -F'\t' -v f="$fn" '$1==f{print $2}'` | Owner of a specific filename |
| `resolve_doc_set "$raw" \| awk -F'\t' -v a="$agent" '$2==a{print $1}'` | All filenames assigned to a given agent |

---

## File-Format Contracts

### Emission Manifest (`{profile}/emission-manifest.jsonl`)

The authoritative safety boundary for the generator's pure-mirror deletion logic.

- **Format:** JSON Lines (`.jsonl`); LF line endings; trailing `\n` on every record
- **First line (sentinel):** `{"_manifest_version": 1}` — reserved object
- **Record schema (exactly 4 keys):**
  - `profile` (string) — `"claude-code" | "codex" | "cursor" | "copilot-cli" | "antigravity"`
  - `src` (string) — repo-relative path inside `canonical/`
  - `dst` (string) — install-tree path relative to manifest's directory
  - `sha256` (string) — lowercase hex SHA-256 of rendered bytes
- **Ordering:** Lexicographic by `dst` (byte-stable across re-runs — preserves AC2)
- **Locations:**
  - `profiles/claude-code/emission-manifest.jsonl` (Claude Code)
  - `profiles/codex/emission-manifest.jsonl` (Codex — covers both `.codex/` and `.agents/` roots)
  - `profiles/cursor/emission-manifest.jsonl` (Cursor)
  - `profiles/copilot-cli/emission-manifest.jsonl` (Copilot CLI — covers the `.github/` root)
  - `profiles/antigravity/emission-manifest.jsonl` (Antigravity — covers the `.agent/` root)
- **Safety semantics:** Files outside any manifest are NEVER touched; `removed_dst` from
  manifest diff is the ONLY set of paths the generator may delete
- **Source:** `canonical/EMISSION-MANIFEST.md` (`## Record Schema`, `## Safety-Boundary Semantics`)

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
- **Source:** `canonical/templates/subagent-heartbeat-protocol.md` (`## Example heartbeat file`, `## File lifecycle`)

### Work `STATE.md` — Per-Area State Hub (FR2 consolidation)

A single STATE file per `.aid/work-NNN-{name}/` directory absorbs what used to be
`INTERVIEW-STATE.md` + per-feature `STATE.md` × N + per-task `task-NNN-STATE.md` × N +
(future) `DEPLOYMENT-STATE.md`. (`canonical/templates/work-state-template.md` `# Work State — work-NNN-{name}`)

**Required sections (consumed by various skills):**

| Section | Producer | Consumer | Source |
|---------|----------|----------|--------|
| `## Triage` | `aid-interview` TRIAGE | `aid-interview` lite/full router | `canonical/templates/work-state-template.md` `## Triage` |
| `## Escalation Carry` | lite→full escalation | CONTINUE state | `canonical/templates/work-state-template.md` `## Escalation Carry` |
| `## Interview Status` | `aid-interview` States 1–4 | `aid-interview` CONTINUE / COMPLETION | `canonical/templates/work-state-template.md` `## Interview Status` |
| `## Features Status` | `aid-specify` | `aid-plan`, `aid-detail` | `canonical/templates/work-state-template.md` `## Features Status` |
| `## Plan / Deliveries` | `aid-plan` | `aid-detail`, `aid-execute` | `canonical/templates/work-state-template.md` `## Plan / Deliveries` |
| `## Tasks Status` | `aid-execute` (via writeback-state.sh) | All execute states + delivery gate | `canonical/templates/work-state-template.md` `## Tasks Status` |
| `## Quick Check Findings` | reviewer (per-task) | Delivery gate aggregator | `canonical/scripts/execute/writeback-state.sh` comment `# Write/replace the ### task-NNN block under ## Quick Check Findings` |
| `## Delivery Gates` | reviewer (per-delivery) | `aid-deploy` | `canonical/scripts/execute/writeback-state.sh` comment `# Write/replace the ### delivery-NNN block under ## Delivery Gates` |
| `## Deploy Status` | `aid-deploy` | `aid-monitor` | `canonical/templates/work-state-template.md` `## Deploy Status` |
| `## Cross-phase Q&A (Pending)` | All phases (loopback writers) | Owning phase's Q&A state | `canonical/templates/work-state-template.md` `## Cross-phase Q&A (Pending)` |
| `## Housekeep Status` | `aid-housekeep` (via `housekeep-state.sh`) | `aid-housekeep` resume detection (`housekeep-state.sh --resume`) | `canonical/templates/work-state-template.md` `## Housekeep Status`, `canonical/scripts/housekeep/housekeep-state.sh` |
| `## Calibration Log` | Every dispatcher (always-on, work-003) | Operator review | `canonical/skills/aid-discover/SKILL.md` `## Dispatch Protocol` |

#### `## Housekeep Status` Run-State Block (key-value contract)

- **Shape:** key-value, one `**Field:** value` line per field (NOT a table — the
  `**Field:** value` shape is grep-recoverable). Read/written ONLY by `housekeep-state.sh`
  (skill bodies never hand-edit it).
- **Nine fields:** `**State:**`, `**Stage Status:**`, `**Branch:**`, `**Mode:**`,
  `**Stall Reason:**`, `**Last Run:**`, `**KB Stage:**`, `**Summary Stage:**`,
  `**Cleanup Stage:**`
- **Stage-gate values:** each of `KB Stage`/`Summary Stage`/`Cleanup Stage` ∈
  `passed | skipped | stalled | running | —`; resume routes to the first incomplete stage
  (six-row resume table). `**Mode:**` ∈ `full | cleanup-only`.
- **Source:** `canonical/templates/work-state-template.md` `## Housekeep Status`
  (the `> Format: key-value` note + the nine `**Field:** —` template lines),
  `canonical/scripts/housekeep/housekeep-state.sh` (`VALID_FIELDS`, `mode_resume()`)

### Knowledge-Base `STATE.md` (`.aid/knowledge/STATE.md`)

Equivalent area-STATE for the Discovery area:
- `## Q&A (Pending)` — questions raised by downstream phases targeting the KB (also the
  carrier `aid-housekeep` KB-DELTA writes its synthesized `**Impact:** Required` entry into)
- `## Review History` — discover-cycle grades with timestamps
- `## Knowledge Summary Status` (FR2 home for `aid-summarize` profile + last-run state)
- `**User Approved:** yes | no` — the discovery approval gate (read back by
  `aid-housekeep` KB-DELTA Step 5 and required by `aid-summarize` preflight)
- **Source:** `canonical/skills/aid-discover/SKILL.md` `## State Detection`,
  `canonical/scripts/summarize/grade-summary.sh` (`## Knowledge Summary Status` profile resolution),
  `canonical/skills/aid-housekeep/references/state-kb-delta.md` `## Step 4` / `## Step 5`

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
- **Source:** `canonical/recipes/README.md` `### YAML Front-Matter`

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

- **Source:** `canonical/templates/feedback-artifacts/IMPEDIMENT.md` `## Type`,
  `canonical/skills/aid-execute/SKILL.md` `## Impediments`,
  `methodology/aid-methodology.md` `#### Loop 6: Execute → Discovery / Specify / Detail`

### Q&A Entry Contract (universal loopback artifact)

Every design-phase loop records the gap as a Q&A entry appended to the relevant phase's
STATE file. Required schema (Style A per `coding-standards.md §12`):

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

The next run of the owning phase detects the pending entry and resolves it in Q&A mode.
`aid-housekeep` KB-DELTA writes exactly such an entry with `**Impact:** Required` (and
`**Category:** Housekeep / KB Delta Refresh`) into `.aid/knowledge/STATE.md ## Q&A
(Pending)` to force `/aid-discover` into targeted re-entry regardless of current grade.
- **Source:** `coding-standards.md §12`; `methodology/aid-methodology.md` `### Feedback Loop Artifacts`;
  `canonical/skills/aid-housekeep/references/state-kb-delta.md` `## Step 4 — Synthesize an Impact: Required Q&A entry + invoke /aid-discover`

---

## Renderer Contract — Canonical → 5 Profile Trees

The generator (`run_generator.py` → `.claude/skills/aid-generate/scripts/*.py`) implements
a **pure-mirror** contract across **5 profiles** (claude-code, codex, cursor, copilot-cli,
antigravity) and **4 agent formats** (`markdown | toml | copilot-agent | antigravity-rule`;
`.claude/skills/aid-generate/scripts/aid_profile.py` `_KNOWN_AGENT_FORMATS`):

| Canonical source | Renderer | Claude Code | Codex | Cursor | Copilot CLI | Antigravity |
|------------------|----------|-------------|-------|--------|-------------|-------------|
| `canonical/agents/` | `render_agents.py` | `.claude/agents/` (Markdown) | `.codex/agents/` (TOML) | `.cursor/agents/` (Markdown) | `.github/agents/*.agent.md` (`copilot-agent`) | `.agent/rules/*.md` (`antigravity-rule`) |
| `canonical/skills/` | `render_skills.py` | `.claude/skills/` | `.agents/skills/` | `.cursor/skills/` | `.github/skills/<slug>/SKILL.md` (native Agent Skills) | `.agent/skills/<slug>/SKILL.md` (native Skills) |
| `canonical/templates/` | `render_templates.py` | `.claude/templates/` | `.agents/templates/` | `.cursor/templates/` | `.github/templates/` | `.agent/templates/` |
| `canonical/recipes/` | `render_recipes.py` | `.claude/recipes/` | `.agents/recipes/` | `.cursor/recipes/` | `.github/recipes/` | `.agent/recipes/` |
| `canonical/scripts/` | `render_canonical_scripts.py` | `.claude/scripts/` | `.agents/scripts/` | `.cursor/scripts/` | `.github/scripts/` | `.agent/scripts/` |

**Source:** `canonical/EMISSION-MANIFEST.md` `## Asset Kinds`, `profiles/copilot-cli.toml`
`[layout]`, `profiles/antigravity.toml` `[layout]`

> **Copilot CLI host-tool mapping** (`profiles/copilot-cli.toml`): AID sub-agents →
> `.github/agents/*.agent.md` (`[agent].format = "copilot-agent"`, frontmatter
> `name/description/tools/model`, `Bash`→`shell` rename via `[tool_names]`); AID skills →
> **native Copilot Agent Skills** at `.github/skills/<slug>/SKILL.md` (folder copy via the
> existing `render_skills` pass — no `emit_as` knob); MCP → **omitted** (no `[mcp]` table;
> repo ships zero MCP servers); methodology rules → `.github/recipes/`/`templates/` as
> verbatim `[data]`; context file → profile-local committed `AGENTS.md` (token only, NOT
> emitted by the renderer). ⚠️ Model slug spelling (`claude-opus-4.8` etc.) docs-only-noted
> as GitHub's lowercase-dotted model-id convention (`profiles/copilot-cli.toml` `[model_tiers]`).
>
> **Antigravity host-tool mapping** (`profiles/antigravity.toml`): AID sub-agents →
> `.agent/rules/*.md` (`[agent].format = "antigravity-rule"`; reshaped to `trigger:`-style
> frontmatter — `always_on` for personas); AID skills → **native** `.agent/skills/<slug>/SKILL.md`
> folders ([data]); methodology rules → `.agent/rules/*.md` via `RuleEntry.output_filename`
> (`.md` output, NOT `.mdc`) driven by a gated `[extras] rules_frontmatter = "trigger"` dialect
> that strips the source `.mdc` frontmatter and regenerates `trigger:/description/globs`
> (`always_apply=true`→`trigger: always_on`; `false`→`trigger: glob` + globs); context file →
> profile-local committed `AGENTS.md`. The extras-rules path is DECOUPLED from `[agent].format`.
> ⚠️ Gemini model-id/effort tokenization docs-only-noted (`profiles/antigravity.toml`
> `[model_tiers.large]`); `[tool_names]` empty → identity passthrough.

**Invariants:**
1. **AC2 byte-identity** — re-running the generator on unchanged inputs produces a
   byte-identical install tree AND a byte-identical manifest
   (`canonical/EMISSION-MANIFEST.md` `## Ordering`)
2. **Skill bodies byte-identical across all trees** — `canonical/skills/<skill>/SKILL.md`
   + `.claude/skills/<skill>/SKILL.md` (dogfood) + 5 profile trees are bit-for-bit
   identical for the body portion (CLAUDE.md `## Architecture` bullet 1)
3. **Pure-mirror deletion** — only files in the previous manifest's `removed_dst` are
   deleted; files outside any manifest are NEVER touched
   (`canonical/EMISSION-MANIFEST.md` `## Safety-Boundary Semantics`)

**Profile front-matter required fields:**

| Field | Claude Code | Codex | Cursor | Copilot CLI | Antigravity |
|-------|-------------|-------|--------|-------------|-------------|
| Agent file format | Markdown + YAML (`markdown`) | TOML (`toml`) | Markdown + YAML (`markdown`) | `.agent.md` (`copilot-agent`) | `.agent/rules/*.md` (`antigravity-rule`) |
| Required agent fields | `name, description, tools, model` | `name, description, model, model_reasoning_effort, developer_instructions` | (per `profiles/cursor.toml`) | `name, description, tools, model` | `trigger, description` (+ optional `globs`; lists parsed-but-dead — reshape is in the format branch) |
| Required skill fields | `name, description, allowed-tools` | `name, description, allowed-tools` | (per `profiles/cursor.toml`) | `name, description, allowed-tools` | `name, description` (lists dead-for-emission — skills preserve canonical frontmatter verbatim) |
| Source | `profiles/claude-code.toml` `[agent.frontmatter]` | `profiles/codex.toml` `[agent.frontmatter]` | `profiles/cursor.toml` | `profiles/copilot-cli.toml` `[agent.frontmatter]` | `profiles/antigravity.toml` `[agent.frontmatter]` |

**Filename-map contract** (substitution in canonical templates):

| Placeholder | claude-code | codex | cursor | copilot-cli | antigravity |
|-------------|-------------|-------|--------|-------------|-------------|
| `project_context_file` | `CLAUDE.md` | `AGENTS.md` | (per cursor.toml) | `AGENTS.md` | `AGENTS.md` |
| `reviewer_output_file` | `STATE.md` | `STATE.md` | `STATE.md` | `STATE.md` | `STATE.md` |
| `open_questions_file` | `additional-info.md` | `additional-info.md` | `additional-info.md` | `additional-info.md` | `additional-info.md` |

Source: `profiles/claude-code.toml` `[filename_map]`, `profiles/codex.toml` `[filename_map]`,
`profiles/copilot-cli.toml` `[filename_map]`, `profiles/antigravity.toml` `[filename_map]`

**Model-tier mapping:**

| Tier | Claude Code | Codex | Cursor | Copilot CLI | Antigravity |
|------|-------------|-------|--------|-------------|-------------|
| `large` | `opus` | `gpt-5.5` (reasoning_effort=high) | (per cursor.toml) | `claude-opus-4.8` | `gemini-3-pro` (reasoning_effort=high) |
| `medium` | `sonnet` | `gpt-5.4` (medium) | (per cursor.toml) | `claude-sonnet-4.6` | `gemini-3-pro` (low) |
| `small` | `haiku` | `gpt-5.4-mini` (low) | (per cursor.toml) | `claude-haiku-4.5` | `gemini-3-flash` (low) |

Source: `profiles/claude-code.toml` `[model_tiers]`, `profiles/codex.toml` `[model_tiers]`,
`profiles/copilot-cli.toml` `[model_tiers]`, `profiles/antigravity.toml` `[model_tiers.large]`

---

## Consumed APIs — External Services

(See `.aid/knowledge/integration-map.md ## Third-Party Services` for the integration-side
view. Listed here for the contract-side completeness.)

| External service | Purpose | Client | Source |
|------------------|---------|--------|--------|
| `https://cdn.jsdelivr.net/npm/mermaid@11.15.0/dist/mermaid.min.js` | Mermaid library bytes (pinned version, SHA-verified) | `curl -sSf --max-time 120` | `canonical/scripts/summarize/fetch-mermaid.sh` (`curl -sSf --max-time 120` download) |
| `gh` CLI (GitHub API) | PR creation, issue mgmt | Subprocess (per `CLAUDE.md` PR convention) | `CLAUDE.md` git/PR sections |

No SDKs, no HTTP clients in code beyond `curl` calls in 2 helper scripts. No persistent
connections, no auth tokens stored anywhere in the repo.

---

## Discrepancies (doc vs code)

- **e2e test runners** — Per Q1 resolution (cycle-1): `.aid/work-001-aid-lite/test-reports/`
  was never a correct home for canonical test scripts; those runners have been removed from
  documentation. The canonical test suites in `tests/canonical/` (run via
  `tests/run-all.sh`) are the complete test contract; recount with `ls tests/canonical/test-*.sh | wc -l` (see `tests/README.md`).
- **`run_generator.py` verify-report sink** — Per Q2 resolution (cycle-1): `run_generator.py`
  now passes `report_path=None` and no longer writes to `.aid/work-002-canonical-generator/`.
  The directory is not required.
- **`profiles/codex.toml` `hooks`, `stop_hook_autocontinue` capabilities** — both marked
  `TODO: confirm` (`profiles/codex.toml` `[capabilities]` — `hooks` + `stop_hook_autocontinue`
  keys); contract values present but unverified against the vendor docs.
