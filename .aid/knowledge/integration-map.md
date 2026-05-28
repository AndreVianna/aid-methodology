---
kb-category: primary
source: hand-authored
intent: |
  Maps all external services and integrations the AID repo depends on. Because AID has no
  application runtime, integrations are minimal: the Mermaid library fetched from npm/jsdelivr
  CDN (consumed by aid-summarize), the gh GitHub CLI used in PR-creation workflows, and the
  multi-tool distribution model that renders canonical source into 3 host-tool install trees.
  Inter-skill choreography is implemented via filesystem state hand-offs (not a message broker).
contracts: []
changelog:
  - 2026-05-27: Initial frontmatter added during cycle-1 FIX Phase B
---
# Integration Map

> The AID repo has **no application runtime** — it ships a methodology distribution.
> External integrations are limited to: (1) the Mermaid library + npm registry + jsdelivr
> CDN consumed by the optional `aid-summarize` skill, (2) the `gh` GitHub CLI used in
> the PR-creation workflow, and (3) the **multi-tool distribution model** that emits the
> canonical source into 3 host-tool install trees.
>
> All claims cite `path:line` against the canonical source.

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
`canonical/skills/aid-execute/SKILL.md:110-121`,
`canonical/skills/aid-discover/SKILL.md:127-159`.

The state-machine + Q&A loopback pattern (§ Feedback Loops in
`methodology/aid-methodology.md:524-635`) is conceptually a single-producer / single-consumer
queue per loop, but materialized as Markdown-formatted entries appended to STATE files
rather than a runtime queue.

---

## Caches

### Mermaid Library Cache

- **System:** Plain filesystem (no Redis, no Memcached)
- **Location:** `.aid/knowledge/.cache/mermaid.min.js` + `mermaid.min.js.meta`
- **What is cached:** The minified Mermaid library bytes from jsdelivr CDN
- **Cache key:** npm-registry `latest` version string
- **Meta file format (KV):** `version=`, `sha256=`, `fetched_at=`, `url=`
- **Invalidation:** New invocation of `fetch-mermaid.sh` queries npm; cache hit only when
  cached `version` equals fetched `latest`; otherwise re-downloads and overwrites
- **TTL:** None (version-pinned, not time-pinned)
- **Atomicity:** `.tmp` file + `mv` to atomically swap
- **Source:** `canonical/scripts/summarize/fetch-mermaid.sh:9-74`

### Discovery `project-index.md` (functions as a cache)

- **Location:** `.aid/generated/project-index.md` (1,148 lines)
- **What is cached:** Full file inventory (path, size, language, mtime, notable annotation)
  for the entire repo — a deterministic pre-pass
- **Purpose:** All 5 discovery sub-agents read this **instead of** re-scanning the repo
  (`canonical/skills/aid-discover/SKILL.md:251-253` in §Process)
- **Invalidation:** Re-generated each discovery run by
  `canonical/scripts/kb/build-project-index.sh`
- **Source:** `canonical/scripts/kb/build-project-index.sh:1-50` (368 lines total per
  `.aid/knowledge/project-structure.md:153`)

### `.aid/knowledge/.cache/` (general scratch)

- **Location:** `.aid/knowledge/.cache/`
- **Gitignored:** Yes (`.gitignore:44` per
  `.aid/knowledge/project-structure.md:113`)
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
| **npm registry** (`registry.npmjs.org`) | Mermaid library version discovery | `curl -sSf --max-time 30` against `/mermaid/latest`, regex-extract `"version"` field | None (public read endpoint, no API key) | `canonical/scripts/summarize/fetch-mermaid.sh:16-18` |
| **jsdelivr CDN** (`cdn.jsdelivr.net`) | Fetch Mermaid library bytes | `curl -sSf --max-time 120` against `/npm/mermaid@<ver>/dist/mermaid.min.js` | None (public CDN, no API key) | `canonical/scripts/summarize/fetch-mermaid.sh:41-47` |
| **GitHub** (via `gh` CLI) | PR creation, issue mgmt, repo ops | Subprocess invocation of `gh` (assumed installed by adopter) | `gh auth login` — credential stored by `gh` (out-of-band), never embedded in repo. ⚠️ Maintainer note in user memory: `AndreVianna` account required for AID push access | `CLAUDE.md` PR/git workflow blocks |
| **Git server (any)** | VCS operations (branch, commit, push) | Inline `git` invocations by `aid-execute` / `aid-deploy` / dev workflow | OS git config / SSH key (out-of-band) | `canonical/skills/aid-execute/SKILL.md:53-71` (branch isolation block) |

⚠️ Credentials not visible in code — likely environment-injected (gh CLI auth context,
git config, OS keyring). No `.env`, no secrets manager, no token file inside the repo.

### External-service runtime requirements

| Requirement | Purpose | Source |
|-------------|---------|--------|
| `curl` | Mermaid fetch | `canonical/scripts/summarize/fetch-mermaid.sh:16, 43` |
| `sha256sum` OR `shasum -a 256` | Mermaid bytes integrity | `canonical/scripts/summarize/fetch-mermaid.sh:59-64` |
| `node` (Node 18+) | `validate-diagrams.mjs` | `README.md:326` (per `.aid/knowledge/project-structure.md:318`) |
| `python3` OR `python` | Recipe slot-fill JSON parse | `canonical/scripts/interview/parse-recipe.sh:38` |
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

| Capability | Claude Code | Codex | Cursor | Notes |
|------------|-------------|-------|--------|-------|
| `hooks` | `true` | `false` (⚠️ TODO) | (per cursor.toml) | Pre/post hooks |
| `skill_chaining` | `true` | `true` | (per cursor.toml) | Skills invoking skills |
| `background_execution` | `true` | `false` | (per cursor.toml) | `background: true` agents |
| `stop_hook_autocontinue` | `true` | `false` (⚠️ TODO) | (per cursor.toml) | Stop hook continues |

Source: `profiles/claude-code.toml:60-64`, `profiles/codex.toml:72-78`

### Per-Skill Grade Overrides (config, not feature flag)

`.aid/settings.yml` supports per-skill `minimum_grade` overrides
(`<skill>.minimum_grade`) that override the global `review.minimum_grade`. This is
config, not a feature flag — controls quality floor, not feature availability.

Source: `canonical/templates/settings.yml:52-81`,
`canonical/scripts/config/read-setting.sh:212-232`

### Graceful Degradation Switch (runtime capability probe, not a flag)

`aid-execute` probes whether the host supports `run_in_background: true` and falls back
to `MaxConcurrent=1` sequential execution if not. Surfaced as:

```
[degradation] MaxConcurrent={N} requested, host capability=sequential — running effective=1
```

Source: `canonical/skills/aid-execute/SKILL.md:198-211`

---

## Multi-Tool Distribution Integration

This is the integration story unique to the AID repo: **one canonical source emitted into
three host-tool install trees** plus a dogfood `.claude/` tree the repo uses on itself.

### Architecture

```
canonical/                          ← single source of truth (maintainer edits here)
  ├── agents/        (22 dirs)
  ├── skills/        (10 dirs + maintainer-only aid-generate)
  ├── templates/     (knowledge-base, knowledge-summary, kb-authoring, ...)
  ├── recipes/       (5 lite-path templates + README)
  ├── scripts/       (config/, execute/, interview/, kb/, summarize/, grade.sh)
  └── EMISSION-MANIFEST.md          ← safety-boundary spec

run_generator.py                    ← entrypoint (87 lines)
  └─ .claude/skills/aid-generate/scripts/  ← the actual renderer
       ├── harness.py               (756 lines — emission-manifest + pure-mirror deletion)
       ├── profile.py               (550 lines — parses profiles/*.toml)
       ├── render_agents.py         (522 lines)
       ├── render_skills.py         (469 lines)
       ├── render_recipes.py        (261 lines)
       ├── render_scripts.py        (224 lines)
       ├── render_templates.py      (252 lines)
       ├── verify_deterministic.py  (515 lines — VERIFY-4a byte-identity)
       ├── verify_advisory.py       (343 lines — VERIFY-4b advisory)
       └── test_manifest_safety.py  (254 lines — generator self-tests)
```

Source: `.aid/knowledge/project-structure.md:124-136`

### Output Trees (3 profile install bundles + 1 dogfood)

| Tree | Location | Purpose | Frontmatter format |
|------|----------|---------|-----|
| **canonical** | `canonical/` | Source of truth (humans edit here) | YAML (markdown) |
| **dogfood** | `.claude/` (top-level) | AID applied to AID itself | Same as Claude Code |
| **claude-code** | `profiles/claude-code/.claude/` + repo-root `CLAUDE.md` | Anthropic Claude Code install bundle | Markdown + YAML |
| **codex** | `profiles/codex/.codex/agents/*.toml` + `profiles/codex/.agents/{skills,scripts,recipes,templates}/*` | OpenAI Codex CLI bundle (split layout) | TOML (agents only) |
| **cursor** | `profiles/cursor/.cursor/*` + repo-root `AGENTS.md` | Cursor IDE bundle | Markdown + `.mdc` rules |

Source: `.aid/knowledge/project-structure.md:32-55`,
`canonical/EMISSION-MANIFEST.md:110-130`

### Codex split-layout exception

Codex is unique among the three tools — agent TOML files go under one root
(`profiles/codex/.codex/agents/`), everything else goes under a separate root
(`profiles/codex/.agents/{skills,scripts,recipes,templates}/`). A single
`profiles/codex/emission-manifest.jsonl` covers both roots; record paths in the
manifest are relative to the common parent (`codex/`) so the safety boundary covers
both roots from one manifest. (Resolves OQ2.)

Source: `canonical/EMISSION-MANIFEST.md:16-27`, `profiles/codex.toml:1-18`

### Byte-identity invariant (the integration contract)

The renderer guarantees that:
1. `canonical/skills/<skill>/SKILL.md` + `.claude/skills/<skill>/SKILL.md` (dogfood) +
   `profiles/{claude-code,codex,cursor}/.../<skill>/SKILL.md` are byte-identical in the
   body portion across all 4 trees (CLAUDE.md `## Architecture` bullet 1)
2. Re-running `python run_generator.py` on unchanged inputs produces a byte-identical
   install tree AND a byte-identical manifest (the AC2 determinism guarantee)
3. Only files in the previous manifest's `removed_dst` are deleted; files outside any
   manifest are NEVER touched (pure-mirror deletion safety)

Source: `canonical/EMISSION-MANIFEST.md:46-50, 70-83`

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

Source: `canonical/EMISSION-MANIFEST.md:70-83`

### Adopter installation flow

End users install AID into their own projects via:
- `./setup.sh <target-directory>` (Bash; macOS / Linux / Git Bash) — interactive menu
  for tool selection (Claude Code / Codex / Cursor), copies the relevant
  `profiles/<tool>/` tree into the target with diff-aware copy semantics
- `.\setup.ps1 <target-directory>` (PowerShell; Windows) — equivalent
- Source: `setup.sh:1-100`, `setup.ps1` (per `.aid/knowledge/project-structure.md:111`)

Setup.sh diff handling: `new = copy`, `identical = skip`, `different = ask`
(or overwrite with `--force`). Source: `setup.sh:86-100`.

---

## Inter-Skill Choreography (Pipeline Integration)

The 8 numbered phases + 2 non-phase Prepare skills + 1 maintainer skill compose a
pipeline. Skills hand work to each other via **filesystem state**, not direct calls.

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
aid-generate        ← maintainer-only (canonical → profile trees)
```

Source: `methodology/aid-methodology.md:528-556` (the 11 feedback loops Mermaid graph),
`docs/glossary.md:29-39` (phase table),
`canonical/templates/work-state-template.md:1-100`

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

Source: `methodology/aid-methodology.md:560-635`

### State-File Read/Write Contract Between Skills

Each skill detects state by reading specific sections of `STATE.md` files; never trusts
memory:

| Skill | Reads | Writes |
|-------|-------|--------|
| `aid-config` | `.aid/settings.yml` | `.aid/settings.yml`, `AGENTS.md`/`CLAUDE.md`, `.aid/knowledge/{STATE.md, INDEX.md, README.md}` + 16 KB doc scaffolds |
| `aid-discover` | `.aid/knowledge/STATE.md ## Q&A`, all 16 KB docs | All 16 KB docs + `STATE.md ## Review History` + `INDEX.md` |
| `aid-interview` | `.aid/{work}/STATE.md ## Triage, ## Interview Status, ## Cross-phase Q&A` | `STATE.md ## Triage, ## Interview Status, ## Features Status`; `REQUIREMENTS.md` OR work-root `SPEC.md` (lite); `tasks/task-NNN.md` (lite) |
| `aid-specify` | Feature `SPEC.md` (requirements side), KB | Feature `SPEC.md ## Technical Specification`; `STATE.md ## Features Status` |
| `aid-plan` | All feature SPECs marked `Ready`, KB | `PLAN.md`; `STATE.md ## Plan / Deliveries` |
| `aid-detail` | `PLAN.md`, feature SPECs | `tasks/task-NNN.md`; `PLAN.md` ## Execution Graph |
| `aid-execute` | `task-NNN.md`, `PLAN.md`, feature `SPEC.md`, `known-issues.md`, `INDEX.md`, `STATE.md ## Tasks Status` | `STATE.md ## Tasks Status` (via `writeback-task-status.sh`), `STATE.md ## Quick Check Findings`, `STATE.md ## Delivery Gates`, `IMPEDIMENT-task-NNN.md`, code |
| `aid-deploy` | `STATE.md ## Tasks Status` (all Done), `PLAN.md`, infrastructure config | `STATE.md ## Deploy Status`; `packages/package-NNN-{name}.md`; routes KB-affecting findings to `DISCOVERY-STATE.md` Q&A (never writes KB directly) |
| `aid-monitor` | Telemetry sources, `packages/`, `known-issues.md`, feature SPECs | `MONITOR-STATE.md`; new `tasks/task-NNN.md` (bug path); `DISCOVERY-STATE.md` Q&A (CR path) |
| `aid-summarize` | Approved `.aid/knowledge/` + `STATE.md ## Knowledge Summary Status` | `.aid/knowledge/knowledge-summary.html`; `STATE.md ## Knowledge Summary Status, ## Summarization History` |
| `aid-generate` (maintainer) | `canonical/`, `profiles/*.toml`, previous `emission-manifest.jsonl` per profile | `profiles/{claude-code,codex,cursor}/...`, new `emission-manifest.jsonl` per profile, repo-root `CLAUDE.md` / `AGENTS.md` |

Sources cited inline above per skill SKILL.md.

### Universal context-feeding protocol (KB INDEX)

Every task prompt receives `.aid/knowledge/INDEX.md` — a ~200–500 token map of all 16 KB
docs. The agent uses it as a navigation directory (Tier 1), then loads at most one
relevant KB doc on demand (Tier 2), and follows inline `path:line` citations to the
exact lines (Tier 3). This is RAG-by-convention, not vector embeddings.

Source: `methodology/aid-methodology.md:179-219`

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

Source: `canonical/templates/long-wait-protocol.md:1-60`,
`canonical/templates/subagent-heartbeat-protocol.md:1-176`,
`canonical/skills/aid-discover/SKILL.md:72-122`

---

## Discrepancies (doc vs code)

- **`infrastructure.md § Source Control` / `infrastructure.md § Deployment` / `infrastructure.md § Project Management`** — referenced as integration contract surfaces by multiple skills (`canonical/skills/aid-execute/SKILL.md:58, 258`, `canonical/skills/aid-deploy/SKILL.md` §PACKAGING, `canonical/skills/aid-monitor/SKILL.md`) but the AID repo itself does not publish a populated `infrastructure.md` for itself (the discovery cycle is filling this gap). ⚠️ Contract-by-convention until populated.
- **`profiles/codex.toml` `hooks` + `stop_hook_autocontinue` capabilities** — both `false` with `TODO: confirm` comments (`profiles/codex.toml:75, 78`); the documented integration is unverified against the vendor docs.
- **`.aid/work-001-aid-lite/` + `.aid/work-002-canonical-generator/`** — Per Q1 and Q2 resolutions (cycle-1): the e2e test runners were never correct canonical artifacts (wrong folder); `run_generator.py` no longer writes to `.aid/work-002-canonical-generator/` (report_path=None). Both directories are correctly absent.
