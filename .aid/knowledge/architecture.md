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
  - "11 user-facing AID skills (7 core-pipeline: aid-config + 6 numbered phases; 4 optional: aid-summarize, aid-deploy, aid-monitor, aid-housekeep) listed in Dispatch table"
  - "9 specialist agents across 3 tiers (4 large / 4 medium / 1 small)"
  - "5 rendered install trees: claude-code, codex, cursor, copilot-cli, antigravity"
changelog:
  - 2026-06-04: work-001-agents-review (task-013) — roster reduced 22→9 agents with aid-* prefix; §3 tier model updated to 4 large / 4 medium / 1 small; counts updated at lines 38, 64; agent canonical paths updated to aid-<name>/ dirs; boilerplate now shared-include via canonical/templates/agent-boilerplate.md.
  - 2026-06-03: methodology v3.2 — aid-deploy and aid-monitor reclassified from mandatory numbered phases (7/8) to OPTIONAL end-of-pipeline Deliver skills; numbered development phases 8→6 (Discover→Execute); skill taxonomy now 7 core-pipeline (aid-config + 6 phases) + 4 optional (aid-summarize, aid-deploy, aid-monitor, aid-housekeep) + maintainer-only aid-generate
  - 2026-06-03: post-merge update for work-001-aid-housekeep (PR #49) — added aid-housekeep (11th user-facing canonical skill, optional/on-demand, NOT in the mandatory pipeline flow); skill framing 10→11 user-facing / 11→12 total counting aid-generate; canonical SKILL.md body total 2,242→2,498 lines across 11 skills
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

1. The AID methodology specification (`methodology/aid-methodology.md`, 1,070 lines).
2. Eleven user-facing skills + 9 agents + templates + recipes + helper scripts, authored
   once in `canonical/` and rendered into five byte-identical install trees
   (`profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/`). Of the eleven, seven
   form the core development pipeline — `aid-config` (one-time setup) plus the six numbered
   phases `aid-discover`…`aid-execute`; the other four (`aid-summarize`, `aid-deploy`,
   `aid-monitor`, `aid-housekeep`) are optional, on-demand skills not required to complete a
   cycle. `aid-deploy` and `aid-monitor` are optional end-of-pipeline Deliver skills;
   `aid-summarize` and `aid-housekeep` run outside the linear flow.
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
├── methodology/                    ← the load-bearing spec (1 .md, 1,070 lines) + images/
├── canonical/                      ← SINGLE SOURCE OF TRUTH (renderer input)
│   ├── agents/                     ← 9 agent dirs (AGENT.md + README.md each)
│   ├── skills/                     ← 11 skill dirs (Thin-Router SKILL.md + references/);
│   │                                 7 core-pipeline (aid-config + 6 phases) + 4 optional (summarize, deploy, monitor, housekeep)
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
│   └── skills/aid-generate/        ← maintainer-only generator (NOT in canonical/)
│       └── scripts/                ← 12 Python files (render_lib.py, aid_profile.py, render_*.py, test_*_emitter.py, …)
├── tests/
│   ├── canonical/                  ← currently 24 helper-script test suites (test-*.sh, bash)
│   ├── lib/assert.sh               ← shared assertion helpers
│   ├── run-all.sh                  ← single aggregator entrypoint (globs test-*.sh)
│   └── README.md                   ← suite inventory + run instructions
├── examples/                       ← 3 case studies (brownfield-enterprise, data-pipeline, desktop-app)
├── docs/                           ← FAQ (61) + glossary (76)
├── .aid/                           ← runtime KB scaffold (committed in THIS repo — AID dogfoods itself)
│   ├── knowledge/                  ← KB output (this discovery's target)
│   ├── generated/project-index.md  ← built by build-project-index.sh
│   ├── settings.yml                ← AID runtime config
│   └── .heartbeat/                 ← ephemeral subagent heartbeat files (gitignored)
├── run_generator.py                ← live entrypoint
├── setup.sh / setup.ps1            ← end-user installers
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
- `.claude/skills/aid-generate/scripts/render_lib.py` `_MANIFEST_VERSION` +
  `_FILENAME_PLACEHOLDERS` — manifest sentinel + placeholder regex; the manifest is JSONL
  with a `{"_manifest_version": 1}` first line, sorted by `dst` for byte-stable diffs.
- `CONTRIBUTING.md` + `coding-standards.md §7a` — "Never edit `profiles/{claude-code,codex,
  cursor,copilot-cli,antigravity}/` directly — edit canonical/ and run `python .claude/skills/aid-generate/scripts/run_generator.py`."

### 2. Thin-Router state machine (per skill)

Every `aid-*` skill is a **state-machine orchestrator**. The top-level `SKILL.md` is a
≤~360-line *router* — Dispatch table + Pre-flight + State Detection only — that delegates
per-state logic to `references/state-{name}.md` files. Each `/aid-<skill>` invocation
detects which state to enter from disk, executes that one state, and exits. No
auto-advance; the human re-invokes the skill for the next state.

Evidence:
- `coding-standards.md §7b` — "When a SKILL.md grows past ~200 lines, extract per-state
  bodies into references/state-{name}.md; keep the router as Dispatch table + Pre-flight +
  State Detection only." Total canonical SKILL.md body lines: 2,498 (counted from disk:
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
summing to 2,242 and predates `aid-housekeep`. The live on-disk total is **2,498 lines
across 11 canonical skills** (7 core-pipeline + 4 optional incl. `aid-housekeep`); re-run
`build-metrics.sh` to refresh `metrics.md`.

#### Skill inventory (canonical/skills/, 11 user-facing skills)

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

`aid-generate` is a **12th skill but maintainer-only**: it lives only at
`.claude/skills/aid-generate/`, is excluded from `canonical/`, and is not a user-facing
skill (see "Documentation vs. Implementation Discrepancies" below). Hence: **11 user-facing
skills + 1 maintainer-only = 12 total.**

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
| **Methodology spec** | `methodology/aid-methodology.md` | Authoritative human-readable methodology document (1,070 lines, version 3.1) | — |
| **Canonical source** | `canonical/` | Single source of truth for everything that ships into install trees | (manually edited by maintainer) |
| **Generator harness** | `.claude/skills/aid-generate/scripts/render_lib.py` + `aid_profile.py` | Profile parsing, placeholder substitution, manifest read/write/diff, SHA-256 fingerprinting | Python stdlib only (`tomllib`, `hashlib`, `json`, `pathlib`) |
| **Asset renderers** | `render_agents.py`, `render_skills.py`, `render_templates.py`, `render_canonical_scripts.py`, `render_recipes.py` | One renderer per asset kind; each reads `canonical/<kind>/` and writes into the profile-specific install path. `render_agents.py` emits one of 4 agent formats per `[agent].format` (markdown / toml / copilot-agent / antigravity-rule); `render_skills.py` `_render_cursor_extras` handles per-rule `output_filename` + a gated trigger-frontmatter dialect | `render_lib`, `aid_profile` |
| **VERIFY (deterministic)** | `verify_deterministic.py` | Byte-identical re-render audit + file-presence audit + frontmatter parse | All renderers (re-runs them into a scratch dir) |
| **VERIFY (advisory)** | `verify_advisory.py` | Non-fatal advisory checks logged separately | `render_lib`, `aid_profile` |
| **Generator self-tests** | `test_manifest_safety.py`, `test_copilot_emitter.py`, `test_antigravity_emitter.py` | Manifest-deletion-boundary tests + per-format emitter unit tests for the copilot-agent and antigravity-rule frontmatter builders | `render_lib`, all renderers |
| **Entry point** | `run_generator.py` | 87-line glue: iterate `profiles/*.toml` (5 profiles), run renderers per profile, deletion pass, then VERIFY (deterministic) + VERIFY (advisory) | All of the above |
| **End-user installer** | `setup.sh`, `setup.ps1` | Interactive tool-selection menu; copies the selected `profiles/<tool>/` subtree into a target project | None (pure shell / PowerShell, no Python) |
| **Helper script library** | `canonical/scripts/{config,execute,interview,kb,summarize}/` + top-level `grade.sh` | Runtime helpers used by skill bodies (read-setting, parse-recipe, writeback-state, build-project-index, summarize pipeline, …) | bash 4+, occasionally Node 18+ for `.mjs` validators |
| **Per-tool profile config** | `profiles/{claude-code,codex,cursor,copilot-cli,antigravity}.toml` (5) | Per-host conventions: layout, agent frontmatter shape + format, model tier names, tool-name remapping, filename map, extras (incl. `rules_frontmatter` + per-rule `output_filename`) | Consumed by `aid_profile.py` |
| **HTML viewer asset bundle** | `canonical/templates/knowledge-summary/` | The optional offline KB viewer template + JS + CSS + Mermaid init + section profiles — see `canonical/templates/knowledge-summary/` for the bundle details | Inlined Mermaid (pinned v11.15.0, SHA-verified) at render time, fetched by `fetch-mermaid.sh` |

Dependency direction (no cycles):

```
methodology/ ──(read by humans)──> canonical/* (authored)
canonical/scripts/grade.sh ─(callable from)─> canonical/skills/*/SKILL.md
canonical/* ─→ aid_profile.py ─→ render_lib.py ─→ render_*.py ─→ profiles/{tool}/...   (tool ∈ {claude-code, codex, cursor, copilot-cli, antigravity})
                                              │
                                              └─→ emission-manifest.jsonl (sorted)
run_generator.py ─orchestrates→ renderers ─then→ verify_deterministic.py + verify_advisory.py
setup.{sh,ps1} ─reads→ profiles/{tool}/ ─copies→ user project
```

## Data Flow

### Build-time data flow (maintainer running `python .claude/skills/aid-generate/scripts/run_generator.py`)

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

### Install-time data flow (end user running `./setup.sh /target/project`)

`setup.sh` shows a menu of `[1] Claude Code [2] Codex [3] Cursor [4] GitHub Copilot CLI
[5] Antigravity [6] Done`, then copies each chosen `profiles/<tool>/` subtree into the
user's project root (`.claude/`; `.codex/` + `.agents/`; `.cursor/`; `.github/`; or
`.agent/`). Codex (2), Cursor (3), Copilot CLI (4) and Antigravity (5) all write a root
`AGENTS.md`; when ≥2 are selected, the Option-A collision handler warns once and the
highest-numbered selected writer's `AGENTS.md` wins (last-write-wins by fixed per-tool
install order — others are not preserved). Existing identical files are skipped; differing
files prompt unless `--force` is passed.

Evidence: `setup.sh` `print_menu` (menu loop), `README.md` `### 1. Install` (install
instructions).

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
  `sys.path.insert(0, '.claude/skills/aid-generate/scripts')` and imports the renderers
  by name. Renderers take their dependencies (`canonical_root: Path`, `profile: Profile`,
  `manifest: EmissionManifest`) as positional arguments.
- The `Profile` dataclass (`.claude/skills/aid-generate/scripts/aid_profile.py` `class Profile`)
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
| **Maintainer build** | `python .claude/skills/aid-generate/scripts/run_generator.py` | Renders all 5 install trees from `canonical/`, runs VERIFY (deterministic, hard) + VERIFY (advisory). Evidence: `run_generator.py` (`"""Live generator run` module docstring). |
| **Maintainer one-tree render** | `python .claude/skills/aid-generate/scripts/render_skills.py --canonical-root . --profile profiles/claude-code.toml --output-root profiles/claude-code/.claude` | Renderers are each runnable standalone with `--canonical-root` / `--profile` / `--output-root`. Evidence: `.claude/skills/aid-generate/scripts/render_skills.py` (`# Usage:` header). |
| **Maintainer verify-only** | `python .claude/skills/aid-generate/scripts/verify_deterministic.py` | VERIFY (deterministic) hard gate. Re-renders to scratch tmpdir, byte-compares against committed install trees, parses every frontmatter. Exit code 0 on full pass; 1 on any sub-check failure. Evidence: `verify_deterministic.py` `def run_verify`. |
| **End-user install (Unix)** | `./setup.sh /path/to/your/project [--force]` | Menu-driven copy of selected profiles into a target project. Evidence: `setup.sh` `print_menu`. |
| **End-user install (Windows)** | `.\setup.ps1 C:\path\to\your\project` | PowerShell 5.1+ equivalent of `setup.sh`. |
| **End-user runtime (pipeline skill)** | Slash command `/aid-config`, `/aid-discover`, `/aid-interview`, `/aid-specify`, `/aid-plan`, `/aid-detail`, `/aid-execute` (+ optional `/aid-summarize`, `/aid-deploy`, `/aid-monitor`) | Seven core-pipeline slash commands (setup + six numbered phases) plus three optional skills. Each enters at the state detected from disk and exits after one state. |
| **End-user runtime (on-demand)** | Slash command `/aid-housekeep` | The 11th user-facing skill — optional/on-demand KB + summary + cleanup maintenance, NOT part of the linear pipeline. Evidence: `canonical/skills/aid-housekeep/SKILL.md`. |
| **First-time AI agent context** | `CLAUDE.md` (Claude Code dogfood) / `AGENTS.md` (Codex, Cursor, Copilot CLI, Antigravity profiles) | Top-level project-context document — describes purpose, KB location, build/test commands, conventions. |
| **Methodology reader** | `methodology/aid-methodology.md` | The 1,070-line authoritative specification. Read by humans, not by skills directly. |

## Documentation vs. Implementation Discrepancies

The repository's documentation describes an "11 user-facing skills + 1 maintainer-only
(`aid-generate`) = 12 total" architecture; observed implementation matches with a few
caveats worth flagging:

1. **`aid-generate` is intentionally NOT in `canonical/`.** It lives only at
   `.claude/skills/aid-generate/` and is excluded from the render. `canonical/skills/`
   contains 11 directories (7 core-pipeline skills + 4 optional skills incl. `aid-housekeep`),
   not 12 — `aid-generate` is the 12th skill and is maintainer-only. Reason per
   `.claude/skills/aid-generate/SKILL.md` (`Maintainer-only skill` blockquote): "Edits to
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
   sum to **2,498 lines across 11 skills** (counted from disk). ⚠️ `.aid/generated/metrics.md`
   is stale — it still reports 2,242 across 10 skills and predates `aid-housekeep`; re-run
   `build-metrics.sh` to refresh it. The rendered `.claude/skills/*/SKILL.md` set may also
   differ from canonical if `canonical/` was edited after the last
   `python .claude/skills/aid-generate/scripts/run_generator.py` run; run VERIFY (deterministic) to detect drift.

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
