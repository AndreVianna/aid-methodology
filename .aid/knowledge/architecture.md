---
kb-category: primary
source: hand-authored
intent: |
  Architectural map of the AID-methodology repository: the canonical→render→install pipeline
  that emits one canonical source into five byte-identical host-tool install trees (Claude Code,
  Codex, Cursor, GitHub Copilot CLI, Antigravity), the phase-to-skill mapping across 6 numbered pipeline phases (Discover→Execute) plus optional Deliver skills, the agent-tier model
  (Opus/Sonnet/Haiku), the Thin-Router SKILL.md pattern, the two-tier review + parallel
  pool dispatch execution model, and the declared-doc-set mechanism that makes the discovery
  KB doc-set project-configurable (varies by project; default seed as fallback). Read this
  to understand how the methodology pieces hang together; for raw file inventory see
  project-structure.md.
contracts:
  - "12 user-facing AID skills (7 core-pipeline: aid-config + 6 numbered phases; 5 optional: aid-summarize, aid-deploy, aid-monitor, aid-housekeep, aid-ask) listed in Dispatch table"
  - "9 specialist agents across 3 tiers (4 large / 4 medium / 1 small)"
  - "5 rendered install trees: claude-code, codex, cursor, copilot-cli, antigravity"
changelog:
  - 2026-06-09: aid-ask added (11->12 user-facing skills, 12->13 total, 4->5 optional) via /aid-housekeep KB-DELTA.
  - 2026-06-05: work-002-auto-installer — end-user installer rewritten: the former clone+`setup.sh`/`setup.ps1` menu installers were removed and replaced by a persistent global `aid` CLI (`bin/aid` + `bin/aid.ps1` + `bin/aid.cmd`, cores `lib/aid-install-core.sh` + `lib/AidInstallCore.psm1`, bootstrap `install.sh` / `install.ps1`) with four install channels (curl/irm bootstrap, npm, PyPI, offline `--from-bundle`). Module-boundaries End-user-installer row, install-time data-flow section, and Entry-Points install rows rewritten to the `aid add <tool>` flow (fetch+verify tarball → copy → FR11 protect-on-diff → `.aid/.aid-manifest.json`). Methodology-spec metrics de-cited (volatile line-count dropped per KB convention; `docs/aid-methodology.md` is the flagship after `methodology/` consolidated into `docs/`).
  - 2026-06-04: work-001-agents-review (task-013) — roster reduced 22→9 agents with aid-* prefix; §3 tier model updated to 4 large / 4 medium / 1 small; counts updated at lines 38, 64; agent canonical paths updated to aid-<name>/ dirs; boilerplate now shared-include via canonical/templates/agent-boilerplate.md.
  - 2026-06-03: methodology v3.2 — aid-deploy and aid-monitor reclassified from mandatory numbered phases (7/8) to OPTIONAL end-of-pipeline Deliver skills; numbered development phases 8→6 (Discover→Execute); skill taxonomy now 7 core-pipeline (aid-config + 6 phases) + 4 optional (aid-summarize, aid-deploy, aid-monitor, aid-housekeep) + maintainer-only generate-profile
  - 2026-06-03: post-merge update for work-001-aid-housekeep (PR #49) — added aid-housekeep (11th user-facing canonical skill, optional/on-demand, NOT in the mandatory pipeline flow); skill framing 10→11 user-facing / 11→12 total counting generate-profile; canonical SKILL.md body total 2,242→2,498 lines across 11 skills
  - 2026-06-01: post-merge update for work-001-add-providers (PRs #42/#43/#44) — 3→5 render profiles (added copilot-cli + antigravity), 2→4 agent formats (added copilot-agent + antigravity-rule), 10→12 generator Python files, setup menu now 5 tools + Done=6 with Option-A AGENTS.md collision handler
  - 2026-05-31: delivery-002 — added declared-doc-set mechanism: Step 0d propose→confirm, data-driven dispatch, de-hardcoded doc-set (varies by project)
  - 2026-05-27: Initial frontmatter added during cycle-1 FIX Phase B
---
# Architecture

> Architectural map of the AID-methodology repository — how the pieces fit together, what
> patterns govern them, and how data flows from the single canonical source out to five
> tool-specific install trees. For raw inventory see `project-structure.md`; this document
> describes the *shape*.

## Project Type

**Multi-tool methodology distribution + single-source code generator** — a single-package,
single-branch monorepo whose deliverable is **documentation rendered into five
host-tool install bundles**. There is no application runtime; the project ships:

1. The AID methodology specification (`docs/aid-methodology.md`).
2. Twelve user-facing skills + 9 agents + templates + recipes + helper scripts, authored
   once in `canonical/` and rendered into five byte-identical install trees
   (`profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/`). Of the twelve, seven
   form the core development pipeline — `aid-config` (one-time setup) plus the six numbered
   phases `aid-discover`…`aid-execute`; the other five (`aid-summarize`, `aid-deploy`,
   `aid-monitor`, `aid-housekeep`, `aid-ask`) are optional, on-demand skills not required to complete a
   cycle. `aid-deploy` and `aid-monitor` are optional end-of-pipeline Deliver skills;
   `aid-summarize`, `aid-housekeep`, and `aid-ask` run outside the linear flow.
3. An optional offline HTML Knowledge Base viewer (the UI surface — see
   `canonical/templates/knowledge-summary/` for the HTML/CSS/JS bundle).

Evidence:
- `project-structure.md` §Primary Purpose — "This repo has no application code — it ships
  skills, agents, templates, and recipes."
- `README.md` opening — "It ships as an install bundle for … AI coding tools" (Claude Code, Codex, Cursor, GitHub Copilot CLI, Antigravity). ⚠️ README count phrasing updated by orchestrator (it lists the tool set verbatim).
- `CONTRIBUTING.md` confirms repo-structure table.
- `canonical/skills/aid-housekeep/SKILL.md` frontmatter `name: aid-housekeep` +
  "Absent from the mandatory pipeline flow." — the 11th canonical (user-facing) skill,
  optional/on-demand.

## Folder Structure

```
aid-methodology/                    (repo root)
├── docs/                           ← the load-bearing spec (docs/aid-methodology.md, v3.2) + FAQ + glossary + install.md
├── canonical/                      ← SINGLE SOURCE OF TRUTH (renderer input)
│   ├── agents/                     ← 9 agent dirs (AGENT.md + README.md each)
│   ├── skills/                     ← 12 skill dirs (Thin-Router SKILL.md + references/);
│   │                                 7 core-pipeline (aid-config + 6 phases) + 5 optional (summarize, deploy, monitor, housekeep, ask)
│   ├── templates/                  ← 15 KB templates + knowledge-summary/ HTML bundle + …
│   ├── recipes/                    ← 51 lite-path recipes + README (add-X / change-X / fix-X family)
│   ├── scripts/                    ← helper scripts grouped by phase
│   │   ├── config/                 ← read-setting.sh
│   │   ├── execute/                ← writeback-state.sh, compute-block-radius.sh, …
│   │   ├── interview/              ← parse-recipe.sh
│   │   ├── kb/                     ← build-project-index.sh, build-kb-index.sh, discover-preflight.sh, …
│   │   ├── summarize/              ← assemble-3part.{sh,ps1}, validate-diagrams.mjs, …
│   │   └── grade.sh                ← deterministic severity→grade scorer (top-level)
│   ├── rules/                      ← Cursor-only .mdc rule sources
│   └── EMISSION-MANIFEST.md        ← deletion-safety spec
├── profiles/                       ← generator output + per-tool TOML config (5 profiles)
│   ├── claude-code.toml            ← profile 1 — single output_root layout
│   ├── claude-code/.claude/        ← rendered tree mirroring canonical/
│   ├── codex.toml                  ← profile 2 — split agents_root/assets_root
│   ├── codex/.codex/agents/        ← TOML agent files
│   ├── codex/.agents/              ← skills/, templates/, recipes/, scripts/
│   ├── cursor.toml                 ← profile 3 — single output_root + rules/ extras
│   ├── cursor/.cursor/             ← rendered tree
│   ├── copilot-cli.toml            ← profile 4 — output_root .github, format copilot-agent
│   ├── copilot-cli/.github/        ← rendered tree: agents/ skills/ scripts/ templates/ recipes/
│   ├── copilot-cli/AGENTS.md       ← root project-context file (Copilot CLI)
│   ├── antigravity.toml            ← profile 5 — output_root .agent, format antigravity-rule
│   ├── antigravity/.agent/         ← rendered tree: rules/ skills/ scripts/ templates/ recipes/
│   └── antigravity/AGENTS.md       ← root project-context file (Antigravity)
├── .claude/                        ← DOGFOOD install tree (AID applied to itself)
│   └── skills/generate-profile/        ← maintainer-only generator (NOT in canonical/)
│       └── scripts/                ← 12 Python files (render_lib.py, aid_profile.py, render_*.py, test_*_emitter.py, …)
├── tests/
│   ├── canonical/                  ← currently 35 helper-script + installer/CLI/release test suites (test-*.sh, bash)
│   ├── windows/                    ← native-Windows PowerShell installer test (Test-AidInstaller.ps1)
│   ├── lib/assert.sh               ← shared assertion helpers
│   ├── run-all.sh                  ← single aggregator entrypoint (globs test-*.sh)
│   └── README.md                   ← suite inventory + run instructions
├── examples/                       ← 3 case studies (brownfield-enterprise, data-pipeline, desktop-app)
├── bin/                            ← `aid` CLI dispatchers: aid (Bash) + aid.ps1 + aid.cmd (Windows)
├── lib/                            ← install cores: aid-install-core.sh (Bash) + AidInstallCore.psm1 (PowerShell)
├── packages/                       ← npm (`aid-installer`) + PyPI (`aid-installer`) thin-shim publish packages
├── .aid/                           ← runtime KB scaffold (committed in THIS repo — AID dogfoods itself)
│   ├── knowledge/                  ← KB output (this discovery's target)
│   ├── generated/project-index.md  ← built by build-project-index.sh
│   ├── settings.yml                ← AID runtime config
│   └── .heartbeat/                 ← ephemeral subagent heartbeat files (gitignored)
├── run_generator.py                ← live entrypoint
├── install.sh / install.ps1        ← `aid` CLI bootstrap (curl/irm-piped first install)
├── release.sh                      ← maintainer release packager (per-profile tarballs + SHA256SUMS)
├── VERSION                         ← single version source (FR10 version-sync; currently 1.1.0)
└── README.md / CLAUDE.md / CONTRIBUTING.md / LICENSE
```

Evidence: `project-structure.md` `## Top-Level Directory Tree (depth 3)`;
`canonical/EMISSION-MANIFEST.md` `## Asset Kinds` (asset-kind mapping);
`coding-standards.md §7a` (never-edit-profiles rule).

## Architectural Pattern

The project applies **four interlocking patterns**:

### 1. Single-source compilation with pure-mirror safety boundary

The dominant pattern. **`canonical/` is the only place a maintainer edits**; `run_generator.py`
calls per-asset renderers (`render_agents.py`, `render_skills.py`, `render_templates.py`,
`render_canonical_scripts.py`, `render_recipes.py`) to emit byte-identical output into each profile's
install tree. Output paths are recorded per profile in `{profile}/emission-manifest.jsonl`;
the deletion pass only removes files that **were** in the previous manifest but are no longer
in the current one. Files outside any manifest are never touched.

Evidence:
- `run_generator.py` `for profile_path in sorted(profiles_dir.glob('*.toml'))` — the live
  render loop (load profile → render → diff → delete → write manifest).
- `canonical/EMISSION-MANIFEST.md` `## Safety-Boundary Semantics` — the four-step
  load/diff/delete/write sequence.
- `.claude/skills/generate-profile/scripts/render_lib.py` `_MANIFEST_VERSION` +
  `_FILENAME_PLACEHOLDERS` — manifest sentinel + placeholder regex; the manifest is JSONL
  with a `{"_manifest_version": 1}` first line, sorted by `dst` for byte-stable diffs.
- `CONTRIBUTING.md` + `coding-standards.md §7a` — "Never edit `profiles/{claude-code,codex,
  cursor,copilot-cli,antigravity}/` directly — edit canonical/ and run `python .claude/skills/generate-profile/scripts/run_generator.py`."

### 2. Thin-Router state machine (per skill)

Every `aid-*` skill is a **state-machine orchestrator**. The top-level `SKILL.md` is a
≤~360-line *router* — Dispatch table + Pre-flight + State Detection only — that delegates
per-state logic to `references/state-{name}.md` files. Each `/aid-<skill>` invocation
detects which state to enter from disk, executes that one state, and exits. No
auto-advance; the human re-invokes the skill for the next state.

Evidence:
- `coding-standards.md §7b` — "When a SKILL.md grows past ~200 lines, extract per-state
  bodies into references/state-{name}.md; keep the router as Dispatch table + Pre-flight +
  State Detection only." Total canonical SKILL.md body lines: 2,685 (counted from disk:
  `find canonical/skills -name SKILL.md -exec cat {} + | wc -l`).
- `.claude/skills/aid-discover/SKILL.md` `State machine for this skill` — explicit
  `[GENERATE]→[REVIEW]→[Q-AND-A]→[FIX]→[APPROVAL]→[DONE]` machine.
- `.claude/skills/aid-summarize/SKILL.md` `## State Detection` — explicit `PREFLIGHT→
  STALE-CHECK→PROFILE→GENERATE→VALIDATE→MANUAL-CHECKLIST→FIX→APPROVAL→WRITEBACK→DONE` machine.
- `canonical/skills/aid-housekeep/SKILL.md` `State machine` blockquote — explicit
  `[ PREFLIGHT ] → [ KB-DELTA ] → [ SUMMARY-DELTA ] → [ CLEANUP ] → [ DONE ]` machine,
  with per-state bodies in `references/state-{preflight,kb-delta,summary-delta,cleanup,done}.md`.
- `profiles/claude-code.toml` `decomposition = "references"` enforces the
  state-file decomposition at render time.

Skill line counts (canonical): `.aid/generated/metrics.md` carries a per-skill breakdown
generated by `build-metrics.sh`, but ⚠️ it is currently stale — it lists 10 SKILL.md bodies
summing to 2,242 and predates `aid-housekeep`. The live on-disk total is **2,685 lines
across 12 canonical skills** (7 core-pipeline + 5 optional incl. `aid-housekeep` and `aid-ask`); re-run
`build-metrics.sh` to refresh `metrics.md`.

#### Skill inventory (canonical/skills/, 12 user-facing skills)

| Skill | Role | In mandatory pipeline? |
|-------|------|------------------------|
| `aid-config` | setup / scaffold | yes (Init, not numbered) |
| `aid-discover` | brownfield discovery → KB | yes (phase 1) |
| `aid-summarize` | optional KB HTML viewer | optional (Prepare group, not numbered) |
| `aid-interview` | requirements + SPEC stubs | yes (phase 2) |
| `aid-specify` | technical specification | yes (phase 3) |
| `aid-plan` | PLAN.md / deliveries | yes (phase 4) |
| `aid-detail` | typed PR-sized task files | yes (phase 5) |
| `aid-execute` | implement + review code | yes (phase 6) |
| `aid-deploy` | ship delivery + PR | optional (Deliver group, end-of-pipeline, not numbered) |
| `aid-monitor` | production findings → fixes | optional (Deliver group, end-of-pipeline, not numbered) |
| `aid-housekeep` | **optional / on-demand** KB + summary + cleanup maintenance | **no — not in the pipeline flow; no phase gate references it** |
| `aid-ask` | **optional / on-demand** read-only Q&A over KB + live codebase + in-flight works | **no — outside the numbered pipeline; single-shot, read-only** |

`generate-profile` is a **13th skill but maintainer-only**: it lives only at
`.claude/skills/generate-profile/`, is excluded from `canonical/`, and is not a user-facing
skill (see "Documentation vs. Implementation Discrepancies" below). Hence: **12 user-facing
skills + 1 maintainer-only = 13 total.**

### 3. Three-tier agent dispatch with reviewer-tier-≥-executor invariant

9 specialist agents split across three model tiers (Large / Medium / Small), mapped per
profile in `[model_tiers]`. Skills dispatch agents via the host tool's Agent capability;
the reviewer's tier is always ≥ the executor's so the writer never grades its own work.
The new roster is: Large (4) — aid-interviewer, aid-architect, aid-researcher, aid-reviewer;
Medium (4) — aid-developer, aid-operator, aid-orchestrator, aid-tech-writer;
Small (1) — aid-clerk.
Each agent file is `canonical/agents/aid-<name>/AGENT.md`; boilerplate sections
(`## Heartbeat protocol`, `## Self-review discipline`) are now factored into
`canonical/templates/agent-boilerplate.md` and injected at render time via
`{{include:agent-boilerplate}}` — not duplicated per-agent.

Evidence:
- `README.md` `## The Agent Model — three tiers` — three-tier diagram (4 Large, 4 Medium,
  1 Small).
- `profiles/claude-code.toml` `[model_tiers]` — `large=opus`, `medium=sonnet`, `small=haiku`.
- `profiles/codex.toml` `[model_tiers.large]` — split syntax with `reasoning_effort`
  (gpt-5.5 high / gpt-5.4 medium / gpt-5.4-mini low).
- `profiles/cursor.toml` `[model_tiers]` — same aliases as Claude Code.
- `profiles/copilot-cli.toml` `[model_tiers]` — simple-form scalar slugs (`large`/`medium`/`small`).
- `profiles/antigravity.toml` `[model_tiers.large]` — detailed split form (`model` + `reasoning_effort`, Gemini-3 lineage).
- `README.md` `### Skill → agent dispatch` — skill→agent dispatch diagram + the
  "Reviewer's tier ≥ Executor's" invariant.

### 4. Area-STATE consolidation (FR2)

Per the area-STATE consolidation rule, each runtime area uses **one** `STATE.md` as its
state hub (Discovery's hub is `.aid/knowledge/STATE.md`; per-work hub is
`.aid/{work}/STATE.md`). Legacy per-feature `STATE.md` and per-task `STATE.md` files are
retired.

Evidence:
- `coding-standards.md §7e` — "Each `.aid/{work}/STATE.md` is the per-area state hub;
  legacy per-feature `STATE.md` and per-task `STATE.md` files are retired."
- `profiles/claude-code.toml`, `profiles/codex.toml`, `profiles/cursor.toml`,
  `profiles/copilot-cli.toml`, `profiles/antigravity.toml` —
  `reviewer_output_file = "STATE.md"` (was `DISCOVERY-STATE.md` / `DISCOVERY-GRADE.md`
  pre-FR2).
- `profiles/cursor/.cursor/rules/aid-methodology.mdc` `## Workspace Structure (per FR2
  area-STATE rule)` — the always-on Cursor rule encoding the three-area rule.

## Module Boundaries

| Module | Path | Responsibility | Depends on |
|--------|------|----------------|------------|
| **Methodology spec** | `docs/aid-methodology.md` | Authoritative human-readable methodology document (`*Version 3.2*` header; line count is volatile and not pinned here) | — |
| **Canonical source** | `canonical/` | Single source of truth for everything that ships into install trees | (manually edited by maintainer) |
| **Generator harness** | `.claude/skills/generate-profile/scripts/render_lib.py` + `aid_profile.py` | Profile parsing, placeholder substitution, manifest read/write/diff, SHA-256 fingerprinting | Python stdlib only (`tomllib`, `hashlib`, `json`, `pathlib`) |
| **Asset renderers** | `render_agents.py`, `render_skills.py`, `render_templates.py`, `render_canonical_scripts.py`, `render_recipes.py` | One renderer per asset kind; each reads `canonical/<kind>/` and writes into the profile-specific install path. `render_agents.py` emits one of 4 agent formats per `[agent].format` (markdown / toml / copilot-agent / antigravity-rule); `render_skills.py` `_render_cursor_extras` handles per-rule `output_filename` + a gated trigger-frontmatter dialect | `render_lib`, `aid_profile` |
| **VERIFY (deterministic)** | `verify_deterministic.py` | Byte-identical re-render audit + file-presence audit + frontmatter parse | All renderers (re-runs them into a scratch dir) |
| **VERIFY (advisory)** | `verify_advisory.py` | Non-fatal advisory checks logged separately | `render_lib`, `aid_profile` |
| **Generator self-tests** | `test_manifest_safety.py`, `test_copilot_emitter.py`, `test_antigravity_emitter.py` | Manifest-deletion-boundary tests + per-format emitter unit tests for the copilot-agent and antigravity-rule frontmatter builders | `render_lib`, all renderers |
| **Entry point** | `run_generator.py` | 87-line glue: iterate `profiles/*.toml` (5 profiles), run renderers per profile, deletion pass, then VERIFY (deterministic) + VERIFY (advisory) | All of the above |
| **End-user installer (`aid` CLI)** | `bin/aid` (+ `bin/aid.ps1` / `bin/aid.cmd`) → cores `lib/aid-install-core.sh` / `lib/AidInstallCore.psm1`; bootstrap `install.sh` / `install.ps1` | Persistent global CLI: per-project `aid add/update/remove <tool>` fetches+verifies the matching release tarball (or `--from-bundle`), copies the profile subtree into the target, applies FR11 protect-on-diff to root agent files, and records `.aid/.aid-manifest.json` | curl/irm + tar + sha256sum/shasum (Bash) or PowerShell built-ins; no Python required (python3 used only as an optional manifest fast-path) |
| **Helper script library** | `canonical/scripts/{config,execute,interview,kb,summarize}/` + top-level `grade.sh` | Runtime helpers used by skill bodies (read-setting, parse-recipe, writeback-state, build-project-index, summarize pipeline, …) | bash 4+, occasionally Node 18+ for `.mjs` validators |
| **Per-tool profile config** | `profiles/{claude-code,codex,cursor,copilot-cli,antigravity}.toml` (5) | Per-host conventions: layout, agent frontmatter shape + format, model tier names, tool-name remapping, filename map, extras (incl. `rules_frontmatter` + per-rule `output_filename`) | Consumed by `aid_profile.py` |
| **HTML viewer asset bundle** | `canonical/templates/knowledge-summary/` | The optional offline KB viewer template + JS + CSS + Mermaid init + section profiles — see `canonical/templates/knowledge-summary/` for the bundle details | Inlined Mermaid (pinned v11.15.0, SHA-verified) at render time, fetched by `fetch-mermaid.sh` |

Dependency direction (no cycles):

```
docs/aid-methodology.md ──(read by humans)──> canonical/* (authored)
canonical/scripts/grade.sh ─(callable from)─> canonical/skills/*/SKILL.md
canonical/* ─→ aid_profile.py ─→ render_lib.py ─→ render_*.py ─→ profiles/{tool}/...   (tool ∈ {claude-code, codex, cursor, copilot-cli, antigravity})
                                              │
                                              └─→ emission-manifest.jsonl (sorted)
run_generator.py ─orchestrates→ renderers ─then→ verify_deterministic.py + verify_advisory.py
bin/aid ─sources→ lib/aid-install-core.sh ─fetches+verifies→ release tarball ─copies→ user project ─records→ .aid/.aid-manifest.json
```

## Data Flow

### Build-time data flow (maintainer running `python .claude/skills/generate-profile/scripts/run_generator.py`)

```
canonical/agents/aid-architect/AGENT.md
canonical/skills/aid-discover/SKILL.md + references/state-*.md
canonical/templates/...                                 ← read once per renderer
canonical/recipes/*.md
canonical/scripts/*/*.sh
            │
            ▼
aid_profile.load_profile(profiles/{tool}.toml)          ← parsed once per profile
            │
            ▼ (per asset kind)
render_{kind}(canonical_root, profile, manifest)        ← reads canonical bytes, applies
            │                                             {project_context_file} /
            │                                             {reviewer_output_file} /
            │                                             {open_questions_file} substitution
            │                                             via render_lib.substitute_filenames
            │                                             + rewrites canonical/scripts/…
            │                                             → <install_root>/scripts/…
            ▼
sha256_hex(rendered_bytes) ──→ manifest.add(profile, src, dst, sha256)
            │
            ▼
write to profiles/{tool}/<install_root>/{dst}
            │
            ▼
diff(prev_manifest, curr_manifest) ──→ delete removed_dst entries from disk
            │                          (only paths previously emitted are eligible —
            │                           hand-maintained files are never touched)
            ▼
write profiles/{tool}/emission-manifest.jsonl (sorted by dst, LF-only, binary mode)
            │
            ▼
verify_deterministic.run_verify(repo) ──→ re-render to scratch tmpdir,
                                          filecmp every file, parse every frontmatter
                                          (report_path=None — no file written)
            │
            ▼
verify_advisory.run_advisory(repo) ──→ non-fatal advisory checks
```

### Install-time data flow (end user running `aid add <tool>`)

The end-user install entrypoint is the **persistent global `aid` CLI**, bootstrapped once
per machine (curl/irm bootstrap, npm, or PyPI), then invoked per project as `aid add <tool>`
(tool auto-detected when omitted; `--target` overrides the working directory):

```
aid add <tool> [--version <v>] [--from-bundle <tar>] [--force]
            │
            ▼
resolve_version  (latest GitHub release tag, unless --version pins one)   ← bin/aid → lib/aid-install-core.sh `resolve_version`
            │
            ▼
fetch_tarball <tool> <ver>  →  aid-<tool>-v<ver>.tar.gz + SHA256SUMS       ← `fetch_tarball` (online)
            │   (--from-bundle path: verify_bundle_checksum against sibling SHA256SUMS)
            ▼
verify sha256 against SHA256SUMS  (exit 4 on mismatch)                     ← `_verify_checksum`
            │
            ▼
extract_tarball  (asserts flat-root, exit 1 on a wrapping dir)            ← `extract_tarball`
            │
            ▼
copy_dir staging → target  (copy_file: new=copy, identical=skip,
            │               different=skip-unless-`--force`)               ← `copy_file` / `copy_dir`
            ▼
FR11 protect-on-diff for the root agent file (CLAUDE.md / AGENTS.md):
   absent → copy; identical → up-to-date; AID-owned (manifest sha) → overwrite;
   someone-else's → write `<file>.aid-new` + WARN (exit 5) unless `--force`    ← `_copy_root_agent_file`
            │
            ▼
manifest_write  →  <target>/.aid/.aid-manifest.json  (+ .aid/.aid-version)     ← `manifest_write` / `write_version_marker`
```

The four AGENTS.md-writing tools (Codex, Cursor, Copilot CLI, Antigravity) now ship a
**byte-identical** root `AGENTS.md` (FR12 invariant), so a second AGENTS.md-writing
install is up-to-date rather than a collision; only a user-modified `AGENTS.md`/`CLAUDE.md`
triggers the protect-on-diff `*.aid-new` path. Claude Code uses `CLAUDE.md` and is exempt.

Evidence: `bin/aid` `_aid_usage` (subcommand surface) + `lib/aid-install-core.sh`
`install_tool` (the copy + manifest + protect-on-diff sequence); `README.md` `## Install`
(install instructions); `docs/install.md` `## Protect-on-diff for root agent files` (FR11);
`tests/canonical/test-agents-md-invariant.sh` (FR12 byte-identity guard).

### Run-time data flow (end user invoking `/aid-<skill>`)

Slash command → host tool reads the rendered `SKILL.md` from the installed tree
→ skill body (Thin-Router) reads `.aid/{knowledge,work-NNN}/STATE.md` to detect state
→ executes one state's reference body → optionally dispatches a subagent via the host's
Agent tool → writes state back to the appropriate `STATE.md` and exits.

`aid-housekeep` is the one exception to "lives only in the pipeline": it is invoked
on-demand (not as part of the linear phase flow) and drives its own
`PREFLIGHT → KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE` machine on a dedicated
`aid/housekeep-*` branch, one commit per stage, never pushing. Evidence:
`canonical/skills/aid-housekeep/SKILL.md` ("Absent from the mandatory pipeline flow." +
the `aid/housekeep-*` branch / one-commit-per-stage / never-push contract).

Evidence: `.claude/skills/aid-discover/SKILL.md` `State machine for this skill`;
`.claude/skills/aid-summarize/SKILL.md` `## State Detection`;
`canonical/templates/settings.yml` `execution.max_parallel_tasks`,
`traceability.heartbeat_interval` (runtime knobs).

### Discovery run-time flow detail (`/aid-discover` GENERATE state)

The discovery GENERATE state follows a richer sequence that includes a **declared-doc-set
resolve** and a **propose→confirm checkpoint** before dispatching sub-agents:

```
Step 0:  Resolve declared doc-set from .aid/settings.yml discovery.doc_set
         (if absent → synthesize default seed from canonical/templates/knowledge-base/ templates)
Step 0b: Read external-docs paths from STATE.md ## External Documentation
Step 0c: Build project index pre-pass (build-project-index.sh → .aid/generated/project-index.md)
Step 0d: Propose→confirm (PAUSE-FOR-USER-DECISION):
         – Infer proposed set as diff-against-default-seed from project-index.md file inventory
         – Present diff to user; await confirm or user-provided edits
         – On confirm: write confirmed set to .aid/settings.yml (no-op if equals default seed)
         – Chain → Step 1 with the confirmed set driving dispatch
Step 1:  aid-researcher (pre-scan, alone, sequential) → project-structure.md, external-sources.md
Steps 2-5: aid-researcher instances dispatched in parallel (data-driven from declared set):
         – Each agent's target list = owns-<agent> ∩ missing-on-disk
         – Empty target list → agent NOT dispatched (no-hang on omission)
         – Added custom doc → appended to owner's prompt (dispatch on addition)
Step 6:  Orchestrator generates README.md, INDEX.md, feature-inventory.md
Step 6b: Update STATE.md Q&A
Step 7:  Update project-context file ({project_context_file})
Step 8:  Wrap-up → chain → REVIEW
```

The doc-set size (N) is thus **variable per project** — it equals the declared set in
`.aid/settings.yml` (or the default seed if the section is absent). No literal count is
hardcoded in the dispatch logic.

Evidence:
- `canonical/skills/aid-discover/references/state-generate.md` `### Step 0d: Propose & Confirm Doc-Set`
- `canonical/skills/aid-discover/references/doc-set-resolve.md` `## resolve_doc_set` + `## synth_default_seed`
- `canonical/skills/aid-discover/references/state-generate.md` `### Steps 2-5: Dispatch 4 Subagents in Parallel (data-driven from declared set)`

## Dependency Injection

**No DI framework is used.** This is intentional and consistent with the project type:

- The Python generator is a script-style harness — `run_generator.py` does
  `sys.path.insert(0, '.claude/skills/generate-profile/scripts')` and imports the renderers
  by name. Renderers take their dependencies (`canonical_root: Path`, `profile: Profile`,
  `manifest: EmissionManifest`) as positional arguments.
- The `Profile` dataclass (`.claude/skills/generate-profile/scripts/aid_profile.py` `class Profile`)
  encapsulates per-tool configuration loaded from a `*.toml` file; that loaded object
  is passed explicitly to every renderer.
- Bash helper scripts pass dependencies via CLI arguments or environment variables.
  Example: `canonical/scripts/summarize/assemble-3part.sh` (`PART1="$1"` …) takes `PART1
  MERMAID PART2 OUTPUT` positional args; `canonical/scripts/config/read-setting.sh --path
  ... --default ...` reads from `.aid/settings.yml` keyed by a dotted path.

⚠️ Inferred from code — needs confirmation: the absence of any DI framework is by
design (Python script harness + bash CLI tools) — no plug-in or service-locator
mechanism was found in any source file.

## Entry Points

| Audience | Entry point | What it does |
|----------|-------------|--------------|
| **Maintainer build** | `python .claude/skills/generate-profile/scripts/run_generator.py` | Renders all 5 install trees from `canonical/`, runs VERIFY (deterministic, hard) + VERIFY (advisory). Evidence: `run_generator.py` (`"""Live generator run` module docstring). |
| **Maintainer one-tree render** | `python .claude/skills/generate-profile/scripts/render_skills.py --canonical-root . --profile profiles/claude-code.toml --output-root profiles/claude-code/.claude` | Renderers are each runnable standalone with `--canonical-root` / `--profile` / `--output-root`. Evidence: `.claude/skills/generate-profile/scripts/render_skills.py` (`# Usage:` header). |
| **Maintainer verify-only** | `python .claude/skills/generate-profile/scripts/verify_deterministic.py` | VERIFY (deterministic) hard gate. Re-renders to scratch tmpdir, byte-compares against committed install trees, parses every frontmatter. Exit code 0 on full pass; 1 on any sub-check failure. Evidence: `verify_deterministic.py` `def run_verify`. |
| **Maintainer release** | `bash release.sh` (or tag-push → `.github/workflows/release.yml`) | Packages the five per-profile tarballs + `SHA256SUMS` for a GitHub Release. Evidence: `release.sh`; `test-release.sh` header. |
| **End-user CLI bootstrap** | `curl -fsSL …/install.sh \| bash` / `irm …/install.ps1 \| iex` / `npm i -g aid-installer` / `pipx install aid-installer` | Installs the persistent global `aid` CLI once per machine (extracts `bin/` + `lib/` into `$AID_HOME`, wires PATH). Evidence: `install.sh` / `install.ps1`; `README.md` `## Install`. |
| **End-user install (per project)** | `aid add <tool>[,...] [--version <v>] [--from-bundle <tar>] [--force]` | Fetches+verifies the profile tarball and installs the AID tree into the current project (FR11 protect-on-diff + `.aid/.aid-manifest.json`). `aid status` / `aid update` / `aid remove` manage it thereafter. Evidence: `bin/aid` `_aid_usage`; `lib/aid-install-core.sh` `install_tool`. |
| **End-user runtime (pipeline skill)** | Slash command `/aid-config`, `/aid-discover`, `/aid-interview`, `/aid-specify`, `/aid-plan`, `/aid-detail`, `/aid-execute` (+ optional `/aid-summarize`, `/aid-deploy`, `/aid-monitor`) | Seven core-pipeline slash commands (setup + six numbered phases) plus three optional Deliver/Prepare skills. Each enters at the state detected from disk and exits after one state. |
| **End-user runtime (on-demand)** | Slash command `/aid-housekeep`, `/aid-ask` | Two off-pipeline user-facing skills — `aid-housekeep` is optional/on-demand KB + summary + cleanup maintenance; `aid-ask` is an optional, on-demand, read-only Q&A skill answering free-form project questions from the KB + live codebase + in-flight works with citations. Neither is part of the linear pipeline. Evidence: `canonical/skills/aid-housekeep/SKILL.md`; `canonical/skills/aid-ask/SKILL.md`. |
| **First-time AI agent context** | `CLAUDE.md` (Claude Code dogfood) / `AGENTS.md` (Codex, Cursor, Copilot CLI, Antigravity profiles) | Top-level project-context document — describes purpose, KB location, build/test commands, conventions. |
| **Methodology reader** | `docs/aid-methodology.md` | The authoritative specification (Version 3.2). Read by humans, not by skills directly. |

## Documentation vs. Implementation Discrepancies

The repository's documentation describes a "12 user-facing skills + 1 maintainer-only
(`generate-profile`) = 13 total" architecture; observed implementation matches with a few
caveats worth flagging:

1. **`generate-profile` is intentionally NOT in `canonical/`.** It lives only at
   `.claude/skills/generate-profile/` and is excluded from the render. `canonical/skills/`
   contains 12 directories (7 core-pipeline skills + 5 optional skills incl. `aid-housekeep` and `aid-ask`),
   not 13 — `generate-profile` is the 13th skill and is maintainer-only. Reason per
   `.claude/skills/generate-profile/SKILL.md` (`Maintainer-only skill` blockquote): "Edits to
   this skill are made directly to its files. Reason: it generates the install
   trees, so it cannot itself be generated from canonical without a chicken-and-egg
   deployment problem."

2. **`aid-housekeep` is optional / on-demand — NOT part of the mandatory pipeline.**
   It is the 11th user-facing canonical skill but is deliberately excluded from the
   phase→skill pipeline mapping; no phase gate references it. It runs three gated jobs in
   strict order on an `aid/housekeep-*` branch
   (`PREFLIGHT → KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE`), one commit per stage, and
   never pushes. Evidence: `canonical/skills/aid-housekeep/SKILL.md`
   ("Absent from the mandatory pipeline flow.") +
   `references/state-{preflight,kb-delta,summary-delta,cleanup,done}.md`.

3. **Skill total line drift + stale metrics.md.** The current canonical SKILL.md bodies
   sum to **2,685 lines across 12 skills** (counted from disk). ⚠️ `.aid/generated/metrics.md`
   is stale — it still reports 2,242 across 10 skills and predates `aid-housekeep`; re-run
   `build-metrics.sh` to refresh it. The rendered `.claude/skills/*/SKILL.md` set may also
   differ from canonical if `canonical/` was edited after the last
   `python .claude/skills/generate-profile/scripts/run_generator.py` run; run VERIFY (deterministic) to detect drift.

4. **`.aid/work-NNN/` directories referenced by older docs but absent from the project
   index.**
   - Q1 resolution (cycle-1): `.aid/work-001-aid-lite/test-reports/` was never a correct
     home for canonical test scripts; those runners have been removed from documentation.
   - Q2 resolution (cycle-1): `run_generator.py` no longer writes verify reports to
     `.aid/work-002-canonical-generator/`; `report_path=None` was passed to eliminate
     the stale write.

5. **Generator `run_generator.py` previously hardcoded paths to a work directory.**
   Fixed in cycle-1 (Q2 resolution): `run_generator.py` now passes `report_path=None`
   to `run_verify`/`run_advisory`, so no `.aid/work-002-canonical-generator/` directory
   is created or required.

6. **Two profiles remap the `Bash` tool name.** Cursor maps `Bash = "Terminal"`
   (`profiles/cursor.toml` `[tool_names]`) and Copilot CLI maps `Bash = "shell"`
   (`profiles/copilot-cli.toml` `[tool_names]`); Claude Code, Codex, and Antigravity use
   identity passthrough (Antigravity ships an empty `[tool_names]` map — `profiles/antigravity.toml`
   `Q-F: empty map`). The renderer applies the remap to every `allowed-tools:` frontmatter
   line via `render_agents.py` `_remap_tools_list` — see `coding-standards.md §2.3`.

## Access Limitations

None — all files referenced are readable from the working tree. The `run_generator.py`
work-directory write was eliminated in cycle-1 (Q2 resolution), so no directories are
created as side-effects of the build.
