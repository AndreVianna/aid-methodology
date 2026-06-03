---
kb-category: primary
source: hand-authored
intent: |
  Maps all external services and integrations the AID repo depends on. Because AID has no
  application runtime, integrations are minimal: the Mermaid library fetched from npm/jsdelivr
  CDN (consumed by aid-summarize), the gh GitHub CLI used in PR-creation workflows, and the
  multi-tool distribution model that renders canonical source into 5 host-tool install trees.
  Inter-skill choreography is implemented via filesystem state hand-offs (not a message broker).
contracts: []
changelog:
  - 2026-06-03: housekeep run-state relocation (PR #51) — corrected the aid-housekeep State-File R/W row: run-state moved from the work-area STATE.md to the project-level `.aid/.temp/HOUSEKEEP_STATE_<ts>.md`; CLEANUP offers every work folder + stale artifact for user-confirmed deletion.
  - 2026-06-03: aid-housekeep merge (PR #49) — skill enumeration 10→11 user-facing (added optional off-pipeline aid-housekeep) + maintainer-only aid-generate; documented aid-housekeep as a filesystem-state choreography participant (STATE.md Q&A handshake with /aid-discover, work-area ## Housekeep Status run-state block, /aid-summarize delegation)
  - 2026-06-01: work-001-add-providers merge (PRs #42/#43/#44) — distribution now 5 profile trees (added copilot-cli → `.github/`, antigravity → `.agent/`); documented Copilot native Agent Skills + Antigravity rules mapping + Option-A AGENTS.md collision handler
  - 2026-05-27: Initial frontmatter added during cycle-1 FIX Phase B
---
# Integration Map

> The AID repo has **no application runtime** — it ships a methodology distribution.
> External integrations are limited to: (1) the Mermaid library + npm registry + jsdelivr
> CDN consumed by the optional `aid-summarize` skill, (2) the `gh` GitHub CLI used in
> the PR-creation workflow, and (3) the **multi-tool distribution model** that emits the
> canonical source into 5 host-tool install trees.
>
> All claims cite `` `file` `anchor` `` (grep-recoverable symbol/heading) against the canonical source.

---

## Message Queues / Event Buses

**None.** No Kafka, RabbitMQ, NATS, SQS, Pub/Sub, EventBridge, or similar broker is
present. The repo has no networked event surface.

The closest equivalent — **inter-skill choreography** — is implemented via filesystem
state hand-offs:
- One skill writes `.aid/{work}/STATE.md` section + an artifact (e.g., PLAN.md, SPEC.md,
  task-NNN.md)
- The next skill reads the FILESYSTEM (not memory) to detect state and resume
- No daemon, no listener — each skill exits after one state and re-enters on the next
  slash-command invocation

Source: every aid-* SKILL.md `## State Detection` block, e.g.
`canonical/skills/aid-execute/SKILL.md` `## State Detection`,
`canonical/skills/aid-discover/SKILL.md` `## State Detection`.

The state-machine + Q&A loopback pattern (§ Feedback Loops in
`methodology/aid-methodology.md` `## 4. Feedback Loops`) is conceptually a single-producer / single-consumer
queue per loop, but materialized as Markdown-formatted entries appended to STATE files
rather than a runtime queue.

---

## Caches

### Mermaid Library Cache

- **System:** Plain filesystem (no Redis, no Memcached)
- **Location:** `.aid/knowledge/.cache/mermaid.min.js` + `mermaid.min.js.meta`
- **What is cached:** The minified Mermaid library bytes from jsdelivr CDN (pinned to v11.15.0)
- **Cache key:** `PINNED_VERSION` constant (`v11.15.0`); derived via `${PINNED_VERSION#v}` — no npm registry query
- **Meta file format (KV):** `version=`, `sha256=`, `fetched_at=`, `url=`
- **Meta trust:** `.meta` is treated as untrusted — version match is necessary but not sufficient; SHA comparison is the actual trust boundary
- **Invalidation / verify gate:** On cache-hit, `compute_sha256()` is called and compared to `EXPECTED_SHA256`; mismatch deletes cached file + meta + exits non-zero. On post-download, same SHA comparison is applied before accepting the downloaded file.
- **TTL:** None (version-pinned, not time-pinned)
- **Atomicity:** `.tmp` file + `mv` to atomically swap
- **Source:** `canonical/scripts/summarize/fetch-mermaid.sh` (`PINNED_VERSION` / `EXPECTED_SHA256` constants, `compute_sha256()`, the cache-hit SHA-verify branch)

### Discovery `project-index.md` (functions as a cache)

- **Location:** `.aid/generated/project-index.md` (1,148 lines)
- **What is cached:** Full file inventory (path, size, language, mtime, notable annotation)
  for the entire repo — a deterministic pre-pass
- **Purpose:** All 5 discovery sub-agents read this **instead of** re-scanning the repo
  (`canonical/skills/aid-discover/references/state-generate.md` `### Step 0c: Build Project Index (Pre-pass)`)
- **Invalidation:** Re-generated each discovery run by
  `canonical/scripts/kb/build-project-index.sh`
- **Source:** `canonical/scripts/kb/build-project-index.sh` (368 lines total per
  `.aid/knowledge/project-structure.md` `## Key Files and Their Purpose`)

### `.aid/knowledge/.cache/` (general scratch)

- **Location:** `.aid/knowledge/.cache/`
- **Gitignored:** Yes (`.gitignore` entry `.aid/knowledge/.cache/` per
  `.aid/knowledge/project-structure.md` `## Key Files and Their Purpose`)
- **Purpose:** Working-set cache for `aid-summarize` (Mermaid above) + future caches

No application-tier cache (no Redis, Memcached, etcd, etc.) exists or is invoked.

---

## Webhooks

**None — incoming or outgoing.** The repo exposes no HTTP server, has no webhook
endpoints, no Stripe-style signed-payload verification, no Slack/Discord adapters.

The `gh` CLI (see Third-Party Services below) interacts with GitHub via the user's
personal credentials and does not register webhooks.

---

## Third-Party Services

| Service | Purpose | Integration method | Auth / credentials | Source |
|---------|---------|--------------------|--------------------|--------|
| **jsdelivr CDN** (`cdn.jsdelivr.net`) | Fetch pinned Mermaid library bytes (mermaid@v11.15.0) | `curl -sSf --max-time 120` against `/npm/mermaid@11.15.0/dist/mermaid.min.js`; download SHA-verified against `EXPECTED_SHA256` constant before accepting | None (public CDN, no API key) | `canonical/scripts/summarize/fetch-mermaid.sh` (`curl -sSf --max-time 120` download + `# Post-download path: verify SHA` block) |
| **GitHub** (via `gh` CLI) | PR creation, issue mgmt, repo ops | Subprocess invocation of `gh` (assumed installed by adopter) | `gh auth login` — credential stored by `gh` (out-of-band), never embedded in repo. ⚠️ Maintainer note in user memory: `AndreVianna` account required for AID push access | `CLAUDE.md` PR/git workflow blocks |
| **Git server (any)** | VCS operations (branch, commit, push) | Inline `git` invocations by `aid-execute` / `aid-deploy` / `aid-housekeep` / dev workflow | OS git config / SSH key (out-of-band) | `canonical/skills/aid-execute/SKILL.md` `### Check 5: Branch Isolation`, `canonical/scripts/housekeep/branch-commit.sh` (`git switch -c`/`git commit`; never `git push`) |

⚠️ Credentials not visible in code — likely environment-injected (gh CLI auth context,
git config, OS keyring). No `.env`, no secrets manager, no token file inside the repo.

### External-service runtime requirements

| Requirement | Purpose | Source |
|-------------|---------|--------|
| `curl` | Mermaid fetch (pinned jsdelivr only) | `canonical/scripts/summarize/fetch-mermaid.sh` (`curl -sSf --max-time 120` download) |
| `sha256sum` OR `shasum -a 256` | Mermaid bytes integrity (cache-hit + post-download verify) | `canonical/scripts/summarize/fetch-mermaid.sh` `compute_sha256()` |
| `node` (Node 18+) | `validate-diagrams.mjs` | `README.md` `### Runtime requirements` |
| `python3` OR `python` | Recipe slot-fill JSON parse | `canonical/scripts/interview/parse-recipe.sh` `python_bin()` |
| `awk`, `sed`, `grep`, `wc`, `find` | Universal helper-script dependencies | every `canonical/scripts/**/*.sh` |
| `gh` CLI | PR creation workflow (dev only) | `CLAUDE.md` |

---

## Feature Flags

**None.** No LaunchDarkly, no internal flag table, no environment-variable gating that
toggles user-facing features.

Two adjacent mechanisms exist but are NOT runtime feature flags:

### Profile Capabilities (build-time, not feature flags)

Each profile TOML declares its host tool's supported capabilities. These are
**informational** for the renderer / skill author — they do NOT toggle features at
runtime; the renderer always emits the same canonical content regardless.

| Capability | Claude Code | Codex | Cursor | Copilot CLI | Antigravity | Notes |
|------------|-------------|-------|--------|-------------|-------------|-------|
| `hooks` | `true` | `false` (⚠️ TODO) | (per cursor.toml) | `true` | `true` | Pre/post hooks |
| `skill_chaining` | `true` | `true` | (per cursor.toml) | `true` | `true` | Skills invoking skills |
| `background_execution` | `true` | `false` | (per cursor.toml) | `true` | `true` | `background: true` agents |
| `stop_hook_autocontinue` | `true` | `false` (⚠️ TODO) | (per cursor.toml) | `true` | `false` | Stop hook continues |

Source: `profiles/claude-code.toml` `[capabilities]`, `profiles/codex.toml` `[capabilities]`,
`profiles/copilot-cli.toml` `[capabilities]`, `profiles/antigravity.toml` `[capabilities]`

### Per-Skill Grade Overrides (config, not feature flag)

`.aid/settings.yml` supports per-skill `minimum_grade` overrides
(`<skill>.minimum_grade`) that override the global `review.minimum_grade`. This is
config, not a feature flag — controls quality floor, not feature availability.

Source: `canonical/templates/settings.yml` (`Optional per-skill overrides` block),
`canonical/scripts/config/read-setting.sh` (`Skill mode:` per-skill override lookup)

### Graceful Degradation Switch (runtime capability probe, not a flag)

`aid-execute` probes whether the host supports `run_in_background: true` and falls back
to `MaxConcurrent=1` sequential execution if not. Surfaced as:

```
[degradation] MaxConcurrent={N} requested, host capability=sequential — running effective=1
```

Source: `canonical/skills/aid-execute/SKILL.md` `## Delivery Lifecycle` (`**Graceful degradation:**` block)

---

## Multi-Tool Distribution Integration

This is the integration story unique to the AID repo: **one canonical source emitted into
five host-tool install trees** plus a dogfood `.claude/` tree the repo uses on itself.

### Architecture

```
canonical/                          ← single source of truth (maintainer edits here)
  ├── agents/        (22 dirs)
  ├── skills/        (11 user-facing dirs + maintainer-only aid-generate)
  ├── templates/     (knowledge-base, knowledge-summary, kb-authoring, ...)
  ├── recipes/       (5 lite-path templates + README)
  ├── scripts/       (config/, execute/, housekeep/, interview/, kb/, summarize/, grade.sh)
  └── EMISSION-MANIFEST.md          ← safety-boundary spec

run_generator.py                    ← entrypoint (87 lines)
  └─ .claude/skills/aid-generate/scripts/  ← the actual renderer
       ├── render_lib.py              (756 lines — emission-manifest + pure-mirror deletion)
       ├── aid_profile.py             (550 lines — parses profiles/*.toml)
       ├── render_agents.py           (522 lines)
       ├── render_skills.py           (469 lines)
       ├── render_recipes.py          (261 lines)
       ├── render_canonical_scripts.py (224 lines)
       ├── render_templates.py        (252 lines)
       ├── verify_deterministic.py    (VERIFY (deterministic) byte-identity)
       ├── verify_advisory.py         (VERIFY (advisory) advisory)
       ├── test_manifest_safety.py    (generator self-test)
       ├── test_copilot_emitter.py    (Copilot-CLI emitter self-test — CI-wired)
       └── test_antigravity_emitter.py (Antigravity emitter self-test — CI-wired)
```

(12 Python files under `scripts/` + `run_generator.py` = 13 renderer files total;
 `test_copilot_emitter.py` + `test_antigravity_emitter.py` run as generator self-tests in
 `.github/workflows/test.yml` `test_copilot_emitter.py --self-test` /
 `test_antigravity_emitter.py --self-test`.)

Source: `.aid/knowledge/project-structure.md` heading `### Generator (maintainer-only, ...)`

> **Skill enumeration (post PR #49):** `canonical/skills/` holds **11 user-facing skills**
> (`aid-config`, `aid-discover`, `aid-interview`, `aid-specify`, `aid-plan`, `aid-detail`,
> `aid-execute`, `aid-deploy`, `aid-monitor`, `aid-summarize`, plus the **optional
> off-pipeline** `aid-housekeep`) **+ maintainer-only `aid-generate`**. `aid-housekeep` is
> NOT in the mandatory phase→skill mapping and no phase gate references it — it is invoked
> on-demand. Source: `find canonical/skills -maxdepth 1 -type d`,
> `canonical/skills/aid-housekeep/SKILL.md` (`**Absent from the mandatory pipeline flow.**`).

### Output Trees (5 profile install bundles + 1 dogfood)

| Tree | Location | Purpose | Frontmatter format |
|------|----------|---------|-----|
| **canonical** | `canonical/` | Source of truth (humans edit here) | YAML (markdown) |
| **dogfood** | `.claude/` (top-level) | AID applied to AID itself | Same as Claude Code |
| **claude-code** | `profiles/claude-code/.claude/` + repo-root `CLAUDE.md` | Anthropic Claude Code install bundle | Markdown + YAML |
| **codex** | `profiles/codex/.codex/agents/*.toml` + `profiles/codex/.agents/{skills,scripts,recipes,templates}/*` | OpenAI Codex CLI bundle (split layout) | TOML (agents only) |
| **cursor** | `profiles/cursor/.cursor/*` + repo-root `AGENTS.md` | Cursor IDE bundle | Markdown + `.mdc` rules |
| **copilot-cli** | `profiles/copilot-cli/.github/*` (`agents/*.agent.md`, native `skills/<slug>/`, `templates/`, `scripts/`, `recipes/`) + `profiles/copilot-cli/AGENTS.md` | GitHub Copilot CLI bundle | `copilot-agent` (agents); native Agent Skills folders; MCP omitted |
| **antigravity** | `profiles/antigravity/.agent/*` (`rules/*.md` for sub-agents + methodology, native `skills/<slug>/`, `templates/`, `scripts/`, `recipes/`) + `profiles/antigravity/AGENTS.md` | Google Antigravity bundle | `antigravity-rule` (sub-agents → `trigger:` rules); native Skills folders |

Source: `.aid/knowledge/project-structure.md` `## Top-Level Directory Tree (depth 3)`,
`canonical/EMISSION-MANIFEST.md` `## Asset Kinds`, `profiles/copilot-cli.toml` `[layout]`,
`profiles/antigravity.toml` `[layout]`

### Copilot CLI mapping (host-tool conventions)

- **Sub-agents** → `.github/agents/*.agent.md` (`[agent].format = "copilot-agent"`;
  frontmatter `name/description/tools/model`; `Bash`→`shell` via `[tool_names]`).
- **Skills** → **native Copilot Agent Skills** `.github/skills/<slug>/SKILL.md` (folder copy
  by the existing `render_skills` pass; no `emit_as` knob).
- **MCP** → **omitted** — no `[mcp]` table; the repo ships zero MCP servers, so no
  `mcp-config.json` is emitted.
- **Context** → profile-local **committed** `AGENTS.md` (filename-map token only; NOT emitted
  by the renderer).
- Source: `profiles/copilot-cli.toml` (`[layout]`, `[agent]`, `[skill]`, `[tool_names]`, the
  "No [mcp] table" comment), `profiles/copilot-cli/.github/agents/architect.agent.md`.

### Antigravity mapping (host-tool conventions)

- **Skills** → native `.agent/skills/<slug>/SKILL.md` folders ([data]).
- **Sub-agents** → `.agent/rules/*.md` (`[agent].format = "antigravity-rule"`; reshaped to
  `trigger: always_on` frontmatter).
- **Methodology rules** → `.agent/rules/*.md` via `RuleEntry.output_filename` (`.md`, NOT
  `.mdc`) under a gated `[extras] rules_frontmatter = "trigger"` dialect that strips the
  source `.mdc` frontmatter and regenerates `trigger:/description/globs`
  (`always_apply=true`→`trigger: always_on`; `false`→`trigger: glob` + globs). DECOUPLED from
  `[agent].format`. Sub-agent rules and methodology rules share `.agent/rules/` (disjoint
  stems: persona names vs `aid-` prefix).
- **Context** → profile-local committed `AGENTS.md`.
- Source: `profiles/antigravity.toml` (`[layout]`, `[agent]`, `[extras]`, `[[extras.rules]]`),
  `profiles/antigravity/.agent/rules/reviewer.md`, `profiles/antigravity/.agent/rules/aid-methodology.md`.

### Codex split-layout exception

Codex is unique among the three tools — agent TOML files go under one root
(`profiles/codex/.codex/agents/`), everything else goes under a separate root
(`profiles/codex/.agents/{skills,scripts,recipes,templates}/`). A single
`profiles/codex/emission-manifest.jsonl` covers both roots; record paths in the
manifest are relative to the common parent (`codex/`) so the safety boundary covers
both roots from one manifest. (Resolves OQ2.)

Source: `canonical/EMISSION-MANIFEST.md` `## Filename and Location`, `profiles/codex.toml` `[layout]`

### Byte-identity invariant (the integration contract)

The renderer guarantees that:
1. `canonical/skills/<skill>/SKILL.md` + `.claude/skills/<skill>/SKILL.md` (dogfood) +
   `profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/.../<skill>/SKILL.md` are
   byte-identical in the body portion across all trees (CLAUDE.md `## Architecture` bullet 1)
2. Re-running `python run_generator.py` on unchanged inputs produces a byte-identical
   install tree AND a byte-identical manifest (the AC2 determinism guarantee)
3. Only files in the previous manifest's `removed_dst` are deleted; files outside any
   manifest are NEVER touched (pure-mirror deletion safety)

Source: `canonical/EMISSION-MANIFEST.md` `## Ordering`, `## Safety-Boundary Semantics`

### Manifest as the safety boundary

The `emission-manifest.jsonl` is the **authoritative input** to deletion logic. The
generator:
1. Loads the previous run's committed manifest
2. Runs all renderers — each emitted file goes into the current run's in-memory manifest
3. Computes `diff(prev, curr)` — `added_dst`, `removed_dst`, `changed_dst`
4. Deletes ONLY files in `removed_dst`; overwrites `changed_dst`; lets the renderer
   create `added_dst`
5. Writes the new manifest

Files the user creates manually (outside any manifest) are NEVER touched.

Source: `canonical/EMISSION-MANIFEST.md` `## Safety-Boundary Semantics`

### Adopter installation flow

End users install AID into their own projects via:
- `./setup.sh <target-directory>` (Bash; macOS / Linux / Git Bash) — interactive menu
  with 5 tool options (`[1]` Claude Code, `[2]` Codex, `[3]` Cursor, `[4]` GitHub Copilot CLI,
  `[5]` Antigravity) + `[6]` Done; copies the selected `profiles/<tool>/` tree(s) into the
  target with diff-aware copy semantics
- `.\setup.ps1 <target-directory>` (PowerShell; Windows) — equivalent
- Source: `setup.sh` (the menu `echo` block + `[6] Done`), `setup.ps1`
  (per `.aid/knowledge/project-structure.md` `## Key Files and Their Purpose`)

### Option-A AGENTS.md multi-install collision handler

Codex (2), Cursor (3), Copilot CLI (4), and Antigravity (5) all write a root `AGENTS.md`.
When ≥2 of these are selected, `setup.sh` sets `AGENTS_COLLISION=1`, prints a one-time
non-interactive warning, and applies **last-installed-wins**: the survivor is the
highest-numbered selected AGENTS.md-writing tool (fixed per-tool install order, NOT the
toggle order). On copy, the survivor's `AGENTS.md` overwrites without prompting
(`copy_file` AGENTS.md branch: "AGENTS.md last-writer-wins — collision resolved
non-interactively"). Claude Code (1) uses `CLAUDE.md` only and is exempt.
- Source: `setup.sh` (the "AGENTS.md collision pre-copy block (Option A)" comment, the
  `AGENTS_COLLISION` survivor-selection block, and the `copy_file` AGENTS.md branch).

Setup.sh diff handling: `new = copy`, `identical = skip`, `different = ask`
(or overwrite with `--force`). Source: `setup.sh` `copy_file()`.

---

## Inter-Skill Choreography (Pipeline Integration)

The 8 numbered phases + 2 non-phase Prepare skills + 1 optional off-pipeline skill
(`aid-housekeep`) + 1 maintainer skill compose the skill set. Skills hand work to each
other via **filesystem state**, not direct calls.

### Phase Sequence (linear with feedback loops)

```
aid-config          ← non-phase Setup (run once)
   ↓
aid-discover        ← Phase 1: Prepare
   ↓
aid-interview       ← Phase 2: Define (lite path may collapse 2-5 into one)
   ↓
aid-specify         ← Phase 3: Define
   ↓
aid-plan            ← Phase 4: Map
   ↓
aid-detail          ← Phase 5: Map
   ↓
aid-execute         ← Phase 6: Execute
   ↓
aid-deploy          ← Phase 7: Deliver
   ↓
aid-monitor         ← Phase 8: Deliver

aid-summarize       ← non-phase, optional, runs against approved KB
aid-housekeep       ← optional, OFF the mandatory pipeline (no phase gate references it);
                       invoked on-demand. Delegates to /aid-discover (KB-DELTA) and
                       /aid-summarize (SUMMARY-DELTA); never auto-runs.
aid-generate        ← maintainer-only (canonical → profile trees)
```

Source: `methodology/aid-methodology.md` `## 4. Feedback Loops` (the 11 feedback loops Mermaid graph),
`docs/glossary.md` `## Phases` (phase table),
`canonical/templates/work-state-template.md` `# Work State`,
`canonical/skills/aid-housekeep/SKILL.md` (`**Absent from the mandatory pipeline flow.**`)

### Eleven Feedback Loops (the integration backbone)

| Loop | From → To | Trigger | Carrier artifact |
|------|-----------|---------|-------------------|
| L1 | Interview → Discovery | KB wrong/incomplete during interview | `DISCOVERY-STATE.md` Q&A |
| L2 | Specify → Discovery | Writing spec exposes KB gap | `DISCOVERY-STATE.md` Q&A |
| L3 | Plan → Discovery | Planning reveals KB miss | `DISCOVERY-STATE.md` Q&A |
| L4 | Plan → Specify | SPEC ambiguous/contradictory | Feature `STATE.md` Q&A |
| L5 | Detail → Plan | PLAN too vague to decompose | Plan revision |
| L6 | Execute → Discovery / Specify / Detail | Assumption broke at impl time | `IMPEDIMENT-task-NNN.md` (typed) |
| L7 | Execute Review → upstream | Reviewer finds TASK/SPEC/KB issues | Tagged issues in STATE.md |
| L8 | Deploy → Execute | Deploy verification failed | Re-route to `/aid-execute` |
| L9 | Monitor → Execute | BUG classification | New `task-NNN.md` |
| L10 | Monitor → Discover | Change Request classification | `DISCOVERY-STATE.md` Q&A |
| L11 | Any phase → Discovery | Targeted re-discovery | `DISCOVERY-STATE.md` Q&A |

Source: `methodology/aid-methodology.md` `### The Eleven Loops`

> **`aid-housekeep` reuses Loop 11 (targeted re-discovery) mechanically, off-pipeline.**
> Its KB-DELTA stage synthesizes a `**Impact:** Required` Q&A entry into
> `.aid/knowledge/STATE.md ## Q&A (Pending)` (the same `DISCOVERY-STATE.md` Q&A carrier as
> L11), then invokes `/aid-discover` to run only the affected sub-agents. `aid-housekeep`
> is not itself one of the 11 named loops — it is an on-demand driver that triggers L11.
> Source: `canonical/skills/aid-housekeep/references/state-kb-delta.md`
> (`### Step 4 — Synthesize an Impact: Required Q&A entry + invoke /aid-discover`).

### State-File Read/Write Contract Between Skills

Each skill detects state by reading specific sections of `STATE.md` files; never trusts
memory:

| Skill | Reads | Writes |
|-------|-------|--------|
| `aid-config` | `.aid/settings.yml` | `.aid/settings.yml`, `AGENTS.md`/`CLAUDE.md`, `.aid/knowledge/{STATE.md, INDEX.md, README.md}` + 15 KB doc scaffolds |
| `aid-discover` | `.aid/knowledge/STATE.md ## Q&A`, all 15 KB docs | All 15 KB docs + `STATE.md ## Review History` + `INDEX.md` |
| `aid-interview` | `.aid/{work}/STATE.md ## Triage, ## Interview Status, ## Cross-phase Q&A` | `STATE.md ## Triage, ## Interview Status, ## Features Status`; `REQUIREMENTS.md` OR work-root `SPEC.md` (lite); `tasks/task-NNN.md` (lite) |
| `aid-specify` | Feature `SPEC.md` (requirements side), KB | Feature `SPEC.md ## Technical Specification`; `STATE.md ## Features Status` |
| `aid-plan` | All feature SPECs marked `Ready`, KB | `PLAN.md`; `STATE.md ## Plan / Deliveries` |
| `aid-detail` | `PLAN.md`, feature SPECs | `tasks/task-NNN.md`; `PLAN.md` ## Execution Graph |
| `aid-execute` | `task-NNN.md`, `PLAN.md`, feature `SPEC.md`, `known-issues.md`, `INDEX.md`, `STATE.md ## Tasks Status` | `STATE.md ## Tasks Status` (via `writeback-state.sh`), `STATE.md ## Quick Check Findings`, `STATE.md ## Delivery Gates`, `IMPEDIMENT-task-NNN.md`, code |
| `aid-deploy` | `STATE.md ## Tasks Status` (all Done), `PLAN.md`, infrastructure config | `STATE.md ## Deploy Status`; `packages/package-NNN-{name}.md`; routes KB-affecting findings to `DISCOVERY-STATE.md` Q&A (never writes KB directly) |
| `aid-monitor` | Telemetry sources, `packages/`, `known-issues.md`, feature SPECs | `MONITOR-STATE.md`; new `tasks/task-NNN.md` (bug path); `DISCOVERY-STATE.md` Q&A (CR path) |
| `aid-summarize` | Approved `.aid/knowledge/` + `STATE.md ## Knowledge Summary Status` | `.aid/knowledge/knowledge-summary.html`; `STATE.md ## Knowledge Summary Status, ## Summarization History` |
| `aid-housekeep` (optional, off-pipeline) | project-level run-state file `.aid/.temp/HOUSEKEEP_STATE_<ts>.md` (resume state, via `housekeep-state.sh`); `.aid/knowledge/STATE.md` (`**Last KB Review:**`, `**User Approved:**`, `## Summarization History`); `git` log/diff (hint only) | project-level run-state file `.aid/.temp/HOUSEKEEP_STATE_<ts>.md` (run-state fields, via `housekeep-state.sh`; gitignored, removed at DONE); `.aid/knowledge/STATE.md ## Q&A (Pending)` (synthesizes an `**Impact:** Required` entry to drive `/aid-discover`); one commit per stage on an `aid/housekeep-*` branch (via `branch-commit.sh`, never pushes). Delegates KB-DELTA → `/aid-discover`, SUMMARY-DELTA → `/aid-summarize`; CLEANUP offers every stale `.aid/` artifact + work folder for user-confirmed deletion via `cleanup-classify.sh` + `git rm`/`rm` |
| `aid-generate` (maintainer) | `canonical/`, `profiles/*.toml` (5 profiles), previous `emission-manifest.jsonl` per profile | `profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/...`, new `emission-manifest.jsonl` per profile, repo-root `CLAUDE.md` / `AGENTS.md` |

Sources cited inline above per skill SKILL.md (`aid-housekeep` row:
`canonical/skills/aid-housekeep/SKILL.md`, `references/state-kb-delta.md`,
`references/state-summary-delta.md`, `references/state-cleanup.md`,
`canonical/scripts/housekeep/{housekeep-state,branch-commit,cleanup-classify}.sh`).

### Universal context-feeding protocol (KB INDEX)

Every task prompt receives `.aid/knowledge/INDEX.md` — a ~200–500 token map of all 15 KB
docs. The agent uses it as a navigation directory (Tier 1), then loads at most one
relevant KB doc on demand (Tier 2), and follows inline `path:line` citations to the
exact lines (Tier 3). This is RAG-by-convention, not vector embeddings.

Source: `methodology/aid-methodology.md` `### Context Feeding Strategy`

---

## Cross-Cutting: Subagent Visibility (work-003 traceability — always-on)

Every long-running subagent dispatch surfaces L1 + L2 + L3 traceability:

- **L1** — Honest ETA bracket pair `▶ <agent> starting (~LOW-HIGH)` / `✓ <agent> done in <actual>`. ETAs sourced from `canonical/templates/rough-time-hints.md`.
- **L2** — Three backgrounded `run_in_background: true` Bash timers at `LOW/2`, `LOW`, `1.5×LOW` minutes; each fires an echo even if the subagent completes earlier.
- **L3** — Pre-created heartbeat file at `.aid/.heartbeat/<agent>-<unix-ts>.txt`; subagent overwrites it every N minutes with `[ISO-8601] STATE | progress | activity (~eta)`.

Always-on per `coding-standards.md §5c` and user-memory rule
(`feedback_traceability-unconditional.md`): "work-003 traceability is always-on; remove
ETA/threshold gates; not subject to my judgment."

Calibration row appended to work `STATE.md ## Calibration Log` AND `## Dispatches`
sub-column on every dispatch (unconditional).

`aid-housekeep` inherits this same L1+L2+L3 protocol for its KB-DELTA sub-agent dispatches
(via `/aid-discover`). Source: `canonical/skills/aid-housekeep/SKILL.md`
`## Dispatch Protocol (L1+L2+L3 subagent visibility, subagent-visibility-patch)`.

Source: `canonical/templates/long-wait-protocol.md` `# Long-Wait Protocol`,
`canonical/templates/subagent-heartbeat-protocol.md` `# Subagent Heartbeat Protocol`,
`canonical/skills/aid-discover/SKILL.md` `## Dispatch Protocol (L1+L2+L3 subagent visibility, subagent-visibility-patch)`

---

## Discrepancies (doc vs code)

- **`infrastructure.md § Source Control` / `infrastructure.md § Deployment` / `infrastructure.md § Project Management`** — referenced as integration contract surfaces by multiple skills (`canonical/skills/aid-execute/SKILL.md` `### Check 5: Branch Isolation` + `## Project Management Sync (conditional)`, `canonical/skills/aid-deploy/SKILL.md` §PACKAGING, `canonical/skills/aid-monitor/SKILL.md`) but the AID repo itself does not publish a populated `infrastructure.md` for itself (the discovery cycle is filling this gap). ⚠️ Contract-by-convention until populated.
- **`profiles/codex.toml` `hooks` + `stop_hook_autocontinue` capabilities** — both `false` with `TODO: confirm` comments (`profiles/codex.toml` `[capabilities]`, `hooks` + `stop_hook_autocontinue` keys); the documented integration is unverified against the vendor docs.
- **`.aid/work-001-aid-lite/` + `.aid/work-002-canonical-generator/`** — Per Q1 and Q2 resolutions (cycle-1): the e2e test runners were never correct canonical artifacts (wrong folder); `run_generator.py` no longer writes to `.aid/work-002-canonical-generator/` (report_path=None). Both directories are correctly absent.
