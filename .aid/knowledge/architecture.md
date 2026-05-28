# Architecture

> Architectural map of the AID-methodology repository — how the pieces fit together, what
> patterns govern them, and how data flows from the single canonical source out to three
> tool-specific install trees. For raw inventory see `project-structure.md`; this document
> describes the *shape*.

## Project Type

**Multi-tool methodology distribution + single-source code generator** — a single-package,
single-branch monorepo whose deliverable is **documentation rendered into three
host-tool install bundles**. There is no application runtime; the project ships:

1. The AID methodology specification (`methodology/aid-methodology.md`, 1,071 lines).
2. Ten skills + 22 agents + templates + recipes + helper scripts, authored once in
   `canonical/` and rendered into three byte-identical install trees
   (`profiles/{claude-code,codex,cursor}/`).
3. An optional offline HTML Knowledge Base viewer (the UI surface — see
   `canonical/templates/knowledge-summary/` for the HTML/CSS/JS bundle).

Evidence:
- `CLAUDE.md:23-25` — "This repo has no application code — it ships skills, agents,
  templates, and recipes."
- `README.md:5-7` — "It ships as an install bundle for three AI coding tools …".
- `CONTRIBUTING.md` confirms repo-structure table.

## Folder Structure

```
aid-methodology/                    (repo root — branch: kb-overhaul)
├── methodology/                    ← the load-bearing spec (1 .md, 1,071 lines) + images/
├── canonical/                      ← SINGLE SOURCE OF TRUTH (renderer input)
│   ├── agents/                     ← 22 agent dirs (AGENT.md + README.md each)
│   ├── skills/                     ← 10 skill dirs (Thin-Router SKILL.md + references/)
│   ├── templates/                  ← 17 KB templates + knowledge-summary/ HTML bundle + …
│   ├── recipes/                    ← 5 lite-path recipes + README (478 lines)
│   ├── scripts/                    ← helper scripts grouped by phase
│   │   ├── config/                 ← read-setting.sh
│   │   ├── execute/                ← writeback-task-status.sh, compute-block-radius.sh, …
│   │   ├── interview/              ← parse-recipe.sh
│   │   ├── kb/                     ← verify-claims.sh, build-project-index.sh, build-index.sh, …
│   │   ├── summarize/              ← concatenate.{sh,ps1}, validate-diagrams.mjs, …
│   │   └── grade.sh                ← deterministic severity→grade scorer (top-level)
│   ├── rules/                      ← Cursor-only .mdc rule sources
│   └── EMISSION-MANIFEST.md        ← deletion-safety spec (152 lines)
├── profiles/                       ← generator output + per-tool TOML config
│   ├── claude-code.toml            ← profile 1 — single output_root layout
│   ├── claude-code/.claude/        ← rendered tree mirroring canonical/
│   ├── codex.toml                  ← profile 2 — split agents_root/assets_root
│   ├── codex/.codex/agents/        ← TOML agent files
│   ├── codex/.agents/              ← skills/, templates/, recipes/, scripts/
│   ├── cursor.toml                 ← profile 3 — single output_root + rules/ extras
│   └── cursor/.cursor/             ← rendered tree
├── .claude/                        ← DOGFOOD install tree (AID applied to itself)
│   └── skills/aid-generate/        ← maintainer-only generator (NOT in canonical/)
│       └── scripts/                ← 10 Python files (harness.py, profile.py, render_*.py, …)
├── tests/
│   ├── canonical/                  ← 6 helper-script test suites (pure bash, 297 tests expected)
│   └── skills/                     ← skill-level e2e suites
├── examples/                       ← 3 case studies (brownfield-enterprise, data-pipeline, desktop-app)
├── docs/                           ← FAQ (61) + glossary (76)
├── .aid/                           ← runtime KB scaffold (mostly gitignored)
│   ├── knowledge/                  ← KB output (this discovery's target)
│   ├── generated/project-index.md  ← built by build-project-index.sh
│   ├── settings.yml                ← AID runtime config
│   └── .heartbeat/                 ← ephemeral subagent heartbeat files (gitignored)
├── run_generator.py                ← live entrypoint (86 lines)
├── setup.sh / setup.ps1            ← end-user installers (162 / 157 lines)
└── README.md / CLAUDE.md / CONTRIBUTING.md / LICENSE
```

Evidence: `project-structure.md:23-71`; `canonical/EMISSION-MANIFEST.md:108-115` (asset-kind
mapping); `CLAUDE.md:48-55`.

## Architectural Pattern

The project applies **four interlocking patterns**:

### 1. Single-source compilation with pure-mirror safety boundary

The dominant pattern. **`canonical/` is the only place a maintainer edits**; `run_generator.py`
calls per-asset renderers (`render_agents.py`, `render_skills.py`, `render_templates.py`,
`render_scripts.py`, `render_recipes.py`) to emit byte-identical output into each profile's
install tree. Output paths are recorded per profile in `{profile}/emission-manifest.jsonl`;
the deletion pass only removes files that **were** in the previous manifest but are no longer
in the current one. Files outside any manifest are never touched.

Evidence:
- `run_generator.py:24-72` — the live render loop (load profile → render → diff → delete →
  write manifest).
- `canonical/EMISSION-MANIFEST.md:69-83` — "Safety-Boundary Semantics" — the four-step
  load/diff/delete/write sequence.
- `.claude/skills/aid-generate/scripts/harness.py:36-46` — manifest sentinel +
  placeholder regex; the manifest is JSONL with a `{"_manifest_version": 1}` first line,
  sorted by `dst` for byte-stable diffs.
- `CONTRIBUTING.md` (per `CLAUDE.md:104-106`) — "Never edit `profiles/{claude-code,codex,
  cursor}/` directly — edit canonical/ and run `python run_generator.py`."

### 2. Thin-Router state machine (per skill)

Every `aid-*` skill is a **state-machine orchestrator**. The top-level `SKILL.md` is a
≤~360-line *router* — Dispatch table + Pre-flight + State Detection only — that delegates
per-state logic to `references/state-{name}.md` files. Each `/aid-<skill>` invocation
detects which state to enter from disk, executes that one state, and exits. No
auto-advance; the human re-invokes the skill for the next state.

Evidence:
- `CLAUDE.md:52-55` — "every `aid-*` SKILL.md is a state router (≤~360 lines) … total skill
  body lines: 2,108 across 10 skills (was 4,467 pre-refactor — 53% reduction)."
- `.claude/skills/aid-discover/SKILL.md:54-58` — explicit `[GENERATE]→[REVIEW]→[Q-AND-A]
  →[FIX]→[APPROVAL]→[DONE]` machine.
- `.claude/skills/aid-summarize/SKILL.md:60-99` — explicit `PREFLIGHT→STALE-CHECK→PROFILE
  →GENERATE→VALIDATE→MANUAL-CHECKLIST→FIX→APPROVAL→WRITEBACK→DONE` machine.
- `profiles/claude-code.toml:26-28` — `decomposition = "references"` enforces the
  state-file decomposition at render time.

Skill line counts (canonical, current snapshot from `wc -l`):
`aid-config 190 · aid-deploy 147 · aid-detail 77 · aid-discover 308 · aid-execute 279 ·
aid-interview 357 · aid-monitor 224 · aid-plan 208 · aid-specify 207 · aid-summarize 233`
(sum = 2,230).

⚠️ Inferred from code — needs confirmation: the `CLAUDE.md:55` claim of "2,108 lines total"
matches the rendered `.claude/skills/*/SKILL.md` set (sum after the most recent render
pass), not the current canonical sources. The most recent canonical edits to
`aid-config/SKILL.md` (190 vs rendered 176) have not been re-rendered into the install
trees.

### 3. Three-tier agent dispatch with reviewer-tier-≥-executor invariant

22 specialist agents split across three model tiers (Large / Medium / Small), mapped per
profile in `[model_tiers]`. Skills dispatch agents via the host tool's Agent capability;
the reviewer's tier is always ≥ the executor's so the writer never grades its own work.

Evidence:
- `README.md:185-198` — three-tier diagram (10 Large, 9 Medium, 3 Small).
- `profiles/claude-code.toml:38-41` — `large=opus`, `medium=sonnet`, `small=haiku`.
- `profiles/codex.toml:43-55` — split syntax with `model_reasoning_effort`
  (gpt-5.5 high / gpt-5.4 medium / gpt-5.4-mini low).
- `profiles/cursor.toml:36-40` — same aliases as Claude Code.
- `README.md:215-237` — skill→agent dispatch diagram + the "Reviewer's tier ≥
  Executor's" invariant.

### 4. Area-STATE consolidation (FR2)

Per the area-STATE consolidation rule, each runtime area uses **one** `STATE.md` as its
state hub (Discovery's hub is `.aid/knowledge/STATE.md`; per-work hub is
`.aid/{work}/STATE.md`). Legacy per-feature `STATE.md` and per-task `STATE.md` files are
retired.

Evidence:
- `CLAUDE.md:108-110` — "Area-STATE consolidation (FR2) … each `.aid/{work}/STATE.md` is
  the per-area state hub; legacy per-feature `STATE.md` and per-task `STATE.md` files
  are RETIRED."
- `profiles/claude-code.toml:52`, `profiles/codex.toml:65`, `profiles/cursor.toml:51` —
  `reviewer_output_file = "STATE.md"` (was `DISCOVERY-STATE.md` / `DISCOVERY-GRADE.md`
  pre-FR2).
- `profiles/cursor/.cursor/rules/aid-methodology.mdc:13-20` — the always-on Cursor rule
  encoding the three-area rule.

## Module Boundaries

| Module | Path | Responsibility | Depends on |
|--------|------|----------------|------------|
| **Methodology spec** | `methodology/aid-methodology.md` | Authoritative human-readable methodology document (1,071 lines, version 3.1) | — |
| **Canonical source** | `canonical/` | Single source of truth for everything that ships into install trees | (manually edited by maintainer) |
| **Generator harness** | `.claude/skills/aid-generate/scripts/harness.py` + `profile.py` | Profile parsing, placeholder substitution, manifest read/write/diff, SHA-256 fingerprinting | Python stdlib only (`tomllib`, `hashlib`, `json`, `pathlib`) |
| **Asset renderers** | `render_agents.py`, `render_skills.py`, `render_templates.py`, `render_scripts.py`, `render_recipes.py` | One renderer per asset kind; each reads `canonical/<kind>/` and writes into the profile-specific install path | `harness`, `profile` |
| **VERIFY-4a (strict)** | `verify_deterministic.py` | Byte-identical re-render audit + file-presence audit + frontmatter parse | All renderers (re-runs them into a scratch dir) |
| **VERIFY-4b (advisory)** | `verify_advisory.py` | Non-fatal advisory checks logged separately | `harness`, `profile` |
| **Manifest safety tests** | `test_manifest_safety.py` | Generator self-tests for the deletion boundary | `harness`, all renderers |
| **Entry point** | `run_generator.py` | 86-line glue: iterate `profiles/*.toml`, run renderers per profile, deletion pass, then VERIFY-4a + VERIFY-4b | All of the above |
| **End-user installer** | `setup.sh` (162 lines), `setup.ps1` (157 lines) | Interactive tool-selection menu; copies the selected `profiles/<tool>/` subtree into a target project | None (pure shell / PowerShell, no Python) |
| **Helper script library** | `canonical/scripts/{config,execute,interview,kb,summarize}/` + top-level `grade.sh` | Runtime helpers used by skill bodies (read-setting, parse-recipe, writeback-task-status, verify-claims, build-project-index, summarize pipeline, …) | bash 4+, occasionally Node 18+ for `.mjs` validators |
| **Per-tool profile config** | `profiles/{claude-code,codex,cursor}.toml` | Per-host conventions: layout, agent frontmatter shape, model tier names, tool-name remapping, filename map, extras | Consumed by `profile.py` |
| **HTML viewer asset bundle** | `canonical/templates/knowledge-summary/` | The optional offline KB viewer template + JS + CSS + Mermaid init + section profiles — see `canonical/templates/knowledge-summary/` for the bundle details | Inlined Mermaid at render time (fetched by `fetch-mermaid.sh`) |

Dependency direction (no cycles):

```
methodology/ ──(read by humans)──> canonical/* (authored)
canonical/scripts/grade.sh ─(callable from)─> canonical/skills/*/SKILL.md
canonical/* ─→ profile.py ─→ harness.py ─→ render_*.py ─→ profiles/{tool}/...
                                              │
                                              └─→ emission-manifest.jsonl (sorted)
run_generator.py ─orchestrates→ renderers ─then→ verify_deterministic.py + verify_advisory.py
setup.{sh,ps1} ─reads→ profiles/{tool}/ ─copies→ user project
```

## Data Flow

### Build-time data flow (maintainer running `python run_generator.py`)

```
canonical/agents/architect/AGENT.md
canonical/skills/aid-discover/SKILL.md + references/state-*.md
canonical/templates/...                                 ← read once per renderer
canonical/recipes/*.md
canonical/scripts/*/*.sh
            │
            ▼
profile.load_profile(profiles/{tool}.toml)              ← parsed once per profile
            │
            ▼ (per asset kind)
render_{kind}(canonical_root, profile, manifest)        ← reads canonical bytes, applies
            │                                             {project_context_file} /
            │                                             {reviewer_output_file} /
            │                                             {open_questions_file} substitution
            │                                             via harness.substitute_filenames
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
                                          (writes report to .aid/work-002-canonical-generator/)
            │
            ▼
verify_advisory.run_advisory(repo) ──→ non-fatal advisory checks
```

### Install-time data flow (end user running `./setup.sh /target/project`)

`setup.sh` shows a menu of `[1] Claude Code [2] Codex [3] Cursor`, then copies the chosen
`profiles/<tool>/` subtree into the user's project root (`.claude/`, `.codex/` + `.agents/`,
or `.cursor/`). Existing identical files are skipped; differing files prompt unless
`--force` is passed.

Evidence: `setup.sh:1-60` (menu loop), `README.md:282-293` (install instructions).

### Run-time data flow (end user invoking `/aid-<skill>`)

Slash command → host tool reads the rendered `SKILL.md` from the installed tree
→ skill body (Thin-Router) reads `.aid/{knowledge,work-NNN}/STATE.md` to detect state
→ executes one state's reference body → optionally dispatches a subagent via the host's
Agent tool → writes state back to the appropriate `STATE.md` and exits.

Evidence: `.claude/skills/aid-discover/SKILL.md:54-58`; `.claude/skills/aid-summarize/SKILL.md:60-99`;
`canonical/templates/settings.yml:43-50` (`execution.max_parallel_tasks`,
`traceability.heartbeat_interval` runtime knobs).

## Dependency Injection

**No DI framework is used.** This is intentional and consistent with the project type:

- The Python generator is a script-style harness — `run_generator.py:7-15` does
  `sys.path.insert(0, '.claude/skills/aid-generate/scripts')` and imports the renderers
  by name. Renderers take their dependencies (`canonical_root: Path`, `profile: Profile`,
  `manifest: EmissionManifest`) as positional arguments.
- The `Profile` dataclass (`.claude/skills/aid-generate/scripts/profile.py:28-46`)
  encapsulates per-tool configuration loaded from a `*.toml` file; that loaded object
  is passed explicitly to every renderer.
- Bash helper scripts pass dependencies via CLI arguments or environment variables.
  Example: `canonical/scripts/summarize/concatenate.sh:5-9` takes `PART1 MERMAID PART2
  OUTPUT` positional args; `canonical/scripts/config/read-setting.sh --path ... --default
  ...` reads from `.aid/settings.yml` keyed by a dotted path.

⚠️ Inferred from code — needs confirmation: the absence of any DI framework is by
design (Python script harness + bash CLI tools) — no plug-in or service-locator
mechanism was found in any source file.

## Entry Points

| Audience | Entry point | What it does |
|----------|-------------|--------------|
| **Maintainer build** | `python run_generator.py` | Renders all 3 install trees from `canonical/`, runs VERIFY-4a (hard) + VERIFY-4b (advisory). Evidence: `run_generator.py:1-86`. |
| **Maintainer one-tree render** | `python .claude/skills/aid-generate/scripts/render_skills.py --canonical-root . --profile profiles/claude-code.toml --output-root profiles/claude-code/.claude` | Renderers are each runnable standalone with `--canonical-root` / `--profile` / `--output-root`. Evidence: `.claude/skills/aid-generate/scripts/render_skills.py:9-12`. |
| **Maintainer verify-only** | `python .claude/skills/aid-generate/scripts/verify_deterministic.py` | VERIFY-4a hard gate. Re-renders to scratch tmpdir, byte-compares against committed install trees, parses every frontmatter. Exit code 0 on full pass; 1 on any sub-check failure. Evidence: `verify_deterministic.py:1-15`. |
| **End-user install (Unix)** | `./setup.sh /path/to/your/project [--force]` | Menu-driven copy of selected profiles into a target project. Evidence: `setup.sh:1-60`. |
| **End-user install (Windows)** | `.\setup.ps1 C:\path\to\your\project` | PowerShell 5.1+ equivalent of `setup.sh`. |
| **End-user runtime (per skill)** | Slash command `/aid-config`, `/aid-discover`, `/aid-interview`, …, `/aid-summarize` | One per skill (10 slash commands). Each enters at the state detected from disk and exits after one state. |
| **First-time AI agent context** | `CLAUDE.md` (Claude Code dogfood) / `AGENTS.md` (Codex, Cursor profiles) | Top-level project-context document — describes purpose, KB location, build/test commands, conventions. |
| **Methodology reader** | `methodology/aid-methodology.md` | The 1,071-line authoritative specification. Read by humans, not by skills directly. |

## Documentation vs. Implementation Discrepancies

The repository's documentation describes a "10 skills + 11 (counting `aid-generate`)"
architecture; observed implementation matches with a few caveats worth flagging:

1. **`aid-generate` is intentionally NOT in `canonical/`.** It lives only at
   `.claude/skills/aid-generate/` and is excluded from the render. `canonical/skills/`
   contains 10 directories (not 11). Reason per `.claude/skills/aid-generate/SKILL.md:13`:
   "Edits to this skill are made directly to its files. Reason: it generates the install
   trees, so it cannot itself be generated from canonical without a chicken-and-egg
   deployment problem."

2. **Skill total line drift.** `CLAUDE.md:55` claims 2,108 total skill-body lines; the
   current canonical sources (per `wc -l` on this snapshot) sum to 2,230 lines. The
   delta (~122 lines) is concentrated in `aid-config/SKILL.md` (190 canonical vs 176
   rendered/.claude/) and reflects edits made after the last render pass.

3. **Two `.aid/work-NNN/` directories referenced by docs but absent from the project
   index.**
   - `CLAUDE.md:35-36` references `.aid/work-001-aid-lite/test-reports/e2e-{two-tier,
     lite-path}-runner.sh` — not on disk in the project index (per
     `project-structure.md:178`, `308`).
   - `run_generator.py:76,83` writes verify reports to
     `.aid/work-002-canonical-generator/verify-{4a,4b}-report.json` — that directory is
     also absent from the project index. The script will create it on first run.

4. **Generator `run_generator.py` hardcodes paths to a work directory that may not
   exist** (`run_generator.py:76,83`). This is functional (parent dirs are auto-created
   by `Path.open`) but ties a maintainer's clean-clone first build to that path.

5. **Cursor profile uses `Terminal` instead of `Bash`.** The only non-identity tool-name
   remap across all three profiles (`profiles/cursor.toml:42-45`). The renderer applies
   this remap to every `allowed-tools:` frontmatter line — see `coding-standards.md
   §2.3` (per the comment in `profiles/cursor.toml:44`).

## Access Limitations

None — all files referenced are readable from the working tree. Two work-directory
references in source files (`run_generator.py:76,83`; `CLAUDE.md:35-36`) are forward
references to dirs the build step creates, and are documented in the discrepancy
section above.
