---
kb-category: primary
source: hand-authored
objective: Component map of the AID repository -- every major module, its purpose, dependencies, test coverage, and the wiring sequence for adding a new one.
summary: Read this to navigate AID's parts (installer, CLI, canonical toolkit, profile renderer, packages, dashboard, site, tests) and learn how they depend on each other before any module-touching change. Also carries the four skill *structural* shapes (fat pipeline / hand-authored collapse / generated doorway / kind-sibling) and how they differ from the ownership taxonomy -- read before writing tooling that parses skill bodies.
sources:
  - bin/
  - lib/
  - install.sh
  - install.ps1
  - canonical/
  - .claude/skills/generate-profile/scripts/
  - profiles/
  - packages/
  - dashboard/
  - site/
  - tests/
  - canonical/EMISSION-MANIFEST.md
tags: [C2, modules, dependencies, components, wiring, test-coverage]
see_also: [project-structure.md, architecture.md, artifact-schemas.md, integration-map.md]
owner: architect
audience: [developer, architect]
review-criteria:
  - id: F-01
    kind: validate
    criterion: "canonical/ is named as the single source of truth, with profiles/ and the vendored package copies identified as rendered output"
    severity: HIGH
    why: "An agent that reads this doc and edits a render loses the edit at the next generator run -- the most common defect this map exists to prevent"
  - id: F-02
    kind: validate
    criterion: "The skill, agent and profile counts stated here are measured from canonical/skills/, canonical/agents/ and profiles/"
    severity: MEDIUM
    why: "These three counts are load-bearing: the generator, the catalog parity suites and the site build all derive from the same directories, so a stale count here contradicts a test"
  - id: F-03
    kind: validate
    criterion: "site/ is described as deriving its skill content from canonical/ at build time, with the generators failing on corpus drift"
    severity: MEDIUM
    why: "It is why a canonical change can break the site build, which is otherwise a surprising failure"
---

# Module Map

This document maps the parts of the AID repository and how they depend on each
other. AID is not one application -- it is a **toolkit factory** plus the toolkit
it produces. The modules fall into four planes:

1. **Distribution plane** -- how the toolkit reaches a user's machine (installers,
   CLI, install-core, packages, release tooling).
2. **Toolkit plane** -- the AID content itself, authored once in `canonical/`
   (skills, agents, scripts, templates).
3. **Render plane** -- the profile renderer that mirrors `canonical/` into five
   per-tool `profiles/` trees under an emission-manifest safety boundary.
4. **Observation plane** -- read-only consumers of pipeline state (the dashboard)
   and the standalone marketing/docs website (`site/`).

## Contents

- [Module Inventory](#module-inventory)
- [Dependency Graph](#dependency-graph)
- [Script Modules by Area](#script-modules-by-area)
- [Notable Skill Reference Modules](#notable-skill-reference-modules)
- [Skill Structural Shapes](#skill-structural-shapes)
- [Entry Points](#entry-points)
- [High-Churn Modules](#high-churn-modules)
- [Oversized Modules](#oversized-modules)
- [Conventions](#conventions)
- [Invariants](#invariants)
- [Contracts](#contracts)
- [Gotchas](#gotchas)

---

## Module Inventory

> Size is qualitative (small/medium/large). Precise line/file counts drift -- run
> `find`/`wc -l` for live numbers (per kb-authoring P1). Test coverage is a health
> assessment, not a percentage.

| Module | Plane | Purpose | Depends on | Size | Test coverage | Notes |
|--------|-------|---------|-----------|------|---------------|-------|
| `install.sh` / `install.ps1` | Distribution | Bootstrap installer; downloads + verifies a release tarball, stages it, installs the CLI to the state-home. | install-core libs | large (`install.sh`) | tested (`tests/canonical/test-aid-cli-parity.sh`, `tests/windows/Test-AidInstaller.ps1`) | Two language twins that must stay behavior-equal. |
| `lib/aid-install-core.sh` | Distribution | Sourceable Bash library of pure install/update/remove functions (copy, manifest, root-agent region update). | none (pure functions) | large | tested (parity + migrate suites) | Largest shell file; no side effects on source. See header `Provides:` block. |
| `lib/AidInstallCore.psm1` | Distribution | PowerShell twin of the install-core library (`#Requires -Version 5.1`). | none | large | tested (`Test-AidInstaller.ps1`, `ps51-compat-check.ps1`) | Must stay WinPS-5.1 compatible (see coding-standards.md). |
| `bin/aid`, `bin/aid.ps1`, `bin/aid.cmd` | Distribution | Persistent `aid` CLI dispatcher: parses subcommands (`update`, `remove`, `dashboard`, ...) and calls install-core. | install-core libs | medium | tested (cli-parity, registry) | `aid.cmd` is a thin cmd.exe shim over `aid.ps1`. |
| `release.sh` | Distribution | Maintainer runbook: packages the five per-profile tarballs + checksums and cuts a GitHub Release. | `canonical/`, `profiles/`, `check-version-sync.sh` | medium | indirectly (release.yml CI) | Maintainer-only; rebuild bundle from clean HEAD. |
| `canonical/skills/*` (76) | Toolkit | Slash-command definitions (`SKILL.md` + `references/*.md`) that drive the pipeline state machines. | `canonical/aid/scripts/*`, `templates/*` | large (collectively) | not machine-tested (by design) | The user-facing surface; one dir per skill (76 total: 18 curated pipeline / on-demand / router skills + the 58-row shortcut catalog's skills: 34 verb-first direct-entry shortcut doorways + 24 hand-authored `repurpose` skills). Phase 2 (Describe → Define) is two skills: `aid-describe` (2a) + `aid-define` (2b). Several `references/` clusters are tracked as modules -- see [Notable Skill Reference Modules](#notable-skill-reference-modules). Skill state machines are validated by dogfooding + AI/human review, NOT an automated harness (see test-landscape.md); only the helper scripts they call have suites. |
| `canonical/agents/*` (9) | Toolkit | Sub-agent role definitions (one `AGENT.md` each); dispatched by skills. | `templates/agent-boilerplate.md` (include) | medium | n/a (prose) | Roles: architect, clerk, developer, interviewer, operator, orchestrator, researcher, reviewer, tech-writer. The `interviewer` agent is dispatched by `aid-describe`. |
| `canonical/aid/scripts/*` | Toolkit | Helper scripts grouped by phase area (config, connectors, execute, graph, housekeep, kb, migrate, release, summarize) + top-level `grade.sh`. | `config/read-setting.sh`, `grade.sh` | large | partial (per-area suites + fixtures) | See [Script Modules by Area](#script-modules-by-area). |
| `canonical/aid/templates/*` | Toolkit | KB doc seeds, state-file templates, schemas, kb-authoring rules, the shortcut catalog + engine + scaffolding. | none (consumed by skills) | large | n/a (data) | The artifact-schema source of truth (see artifact-schemas.md). |
| `generate-profile` renderer | Render | Python renderer that mirrors `canonical/` into each `profiles/<tool>/` tree under an emission manifest. | `canonical/`, `profiles/*.toml` | large | tested (`test_manifest_safety.py`, `verify_deterministic.py`, `verify_advisory.py`) | Lives at `.claude/skills/generate-profile/scripts/`. Also carries `build-shortcut-skills.py`, the maintainer helper that emits the shortcut doorways from `shortcut-catalog.yml`. |
| `profiles/<tool>/` (5) | Render | Rendered, per-tool copies of the toolkit (claude-code, codex, cursor, copilot-cli, antigravity) + `<tool>.toml` config. | output of the renderer | large | render-drift CI | Build output -- never hand-edit; regenerate. |
| `packages/npm` | Distribution | npm `aid-installer` wrapper; vendors `bin/`, `lib/`, `dashboard/`. | `bin/`, `lib/`, `dashboard/` | medium | release smoke | Vendored copies regenerate; edit the wrapper, not the vendor. |
| `packages/pypi` | Distribution | PyPI `aid-installer` wrapper (`aid_installer/` + `_vendor/`). | `bin/`, `lib/`, `dashboard/` | medium | release smoke | `__main__.py` puts `aid` on PATH. |
| `dashboard/reader/*` (Python) | Observation | Parses `.aid/` state (STATE.md hierarchy, settings, KB) into typed models. | `.aid/` artifact schemas | large | tested (`dashboard/reader/tests/`) | `parsers.py` + `derivation.py` + `models.py` + `locator.py` + `reader.py`. |
| `dashboard/server/*` | Observation | Serves the dashboard: a Node `reader.mjs`/`server.mjs` twin of the Python reader, plus `server.py`, index/home HTML. | `dashboard/reader` semantics | large | tested (`dashboard/server/tests/`) | `reader.mjs` is the Node twin of the **whole** `dashboard/reader/` Python reader (its own header: "port of dashboard/reader/"), not just `parsers.py` -- a change to ANY reader `.py` (`parsers`/`derivation`/`models`/`locator`/`reader`) must be mirrored in `reader.mjs`; behavior-equal, no import. |
| `site/` | Observation | Astro marketing + docs website. **Derives its skill content from `canonical/` at build time** (see the Skill Explorer rows below). | own `package.json`; `canonical/skills/`, `canonical/agents/`, `canonical/aid/templates/` | large | tested (`site/**/__tests__`, ~2765 vitest) | Independent of the **CLI** (`bin/`, `lib/`), NOT of the toolkit. Separate `node_modules`/`dist`. |
| `site/scripts/gen-skills.mjs` + `site/scripts/skills/*` (12) | Observation | **Skill Explorer generator**. Emits the `/skills/` section — one index page plus a detail page per skill directory — from `canonical/skills/` and the shortcut catalog. Modules: discovery, frontmatter parse, grouping (four groups; Definition subdivided by verb family), card/summary/value rendering, index + page render, path resolution, catalog read, and the shared curated roster. | `canonical/skills/`, `shortcut-catalog.yml` | large | tested (`skills-*.test.mjs`, `gen-skills*.test.mjs`) | **Throws** on corpus drift: an on-disk skill that is neither a catalog row nor a curated-roster member fails the build BY NAME. |
| `site/scripts/lib/flow-graph/*` (14) | Observation | **Flow extractor**. Reads a skill's own instructions and derives its control flow — ordered states, loops, decision branches, exit points — then renders Mermaid. Extractors are per body shape (dispatch table, inline `## State:` sections, engine doorway, sibling, residual), over a shared compose/advance/validate core. | `canonical/skills/*/SKILL.md` + `references/*.md` | large | tested (`flow-*.test.mjs`, the largest suite group) | The four skill *structural shapes* in § Skill Structural Shapes are what these extractors dispatch on. |
| `site/scripts/gen-reference.mjs` | Observation | Generates the four reference pages (`skills`, `agents`, `kb`, `settings`) from `canonical/` + `.aid/settings.yml`. Since delivery-006 its skills page carries only the **shortcut-engine narrative** — the roster moved to `/skills/`. | `canonical/`, `.aid/settings.yml` | medium | tested (`gen-reference.test.mjs`) | Not frozen. |
| `site/scripts/skills/skill-counts.mjs` | Observation | **The** derivation of the skill-count triple (`directories`, `curatedOnly`, `shortcuts`, `catalogRows`, …). The public-facing docs are checked against it; counts elsewhere are a declared review criterion rather than a guarded assertion. | `canonical/skills/`, `shortcut-catalog.yml` | small | tested (`skill-counts.test.mjs`) + `tests/canonical/test-doc-counts.sh` | Pure, no import-time side effect — deliberately does not import `gen-reference.mjs`, which runs `main()` at module scope. |
| `site/public/skill-node-panel.mjs` (runtime) + `site/src/lib/skill-node-panel.ts` (build-time projection, ~149) | Observation | **Interactive node panel**. Decorates each rendered flow-chart node with `role=button` / `tabindex` / ARIA and reveals a panel carrying that node's verbatim prompt fragment and a source deep link. | the generated per-page projection island | medium | tested (jsdom suites + manual browser gate) | Reads the JSON projection, never feature-005's DOM. Survives mermaid's theme re-render. |
| `tests/canonical/*` | Cross-cutting | Cross-platform shell test suites + `fixtures/`, run via `tests/run-all.sh`. | the modules under test | large | self | Heavy gates run on master CI only. |
| `tests/windows/*` | Cross-cutting | Windows-only PowerShell installer tests (`Test-AidInstaller.ps1`). | installers + install-core | large | windows CI lane | NOT in `run-all.sh`; needs a Windows runner. |

---

## Dependency Graph

> Arrows point from importer/consumer to its dependency (`A -> B` = A depends on B).
> Diagrams are avoided per kb-authoring P10; this is the plain-text form.

```
# Distribution plane
install.sh            -> lib/aid-install-core.sh
install.ps1           -> lib/AidInstallCore.psm1
bin/aid               -> lib/aid-install-core.sh
bin/aid.ps1           -> lib/AidInstallCore.psm1
bin/aid.cmd           -> bin/aid.ps1
release.sh            -> canonical/ , profiles/ , canonical/aid/scripts/release/check-version-sync.sh
packages/npm          -> bin/ , lib/ , dashboard/          (vendored)
packages/pypi         -> bin/ , lib/ , dashboard/          (vendored under _vendor/)

# Render plane (source-of-truth -> rendered copies)
generate-profile      -> canonical/ , profiles/<tool>.toml
profiles/<tool>/      -> generate-profile                  (emitted by)
profiles/<tool>/emission-manifest.jsonl -> generate-profile (safety boundary)

# Toolkit plane (internal wiring)
canonical/skills/*    -> canonical/aid/scripts/* , canonical/aid/templates/*
canonical/agents/*    -> canonical/aid/templates/agent-boilerplate.md   (include directive)
canonical/aid/scripts/* (most) -> canonical/aid/scripts/config/read-setting.sh
*/state-review.md (skills) -> canonical/aid/scripts/grade.sh
canonical/skills/aid-<verb>[-<artifact>]* -> canonical/aid/templates/shortcut-engine.md , shortcut-scaffolding/<family>.md   (thin shortcut doorways delegate to the shared engine)
.claude/skills/generate-profile/scripts/build-shortcut-skills.py -> canonical/aid/templates/shortcut-catalog.yml   (emits/refreshes the shortcut doorways)
canonical/skills/aid-describe -> canonical/skills/aid-define   (REQUIREMENTS.md handoff: Phase 2a -> 2b)
canonical/skills/aid-housekeep -> canonical/skills/aid-discover/references/agent-prompts.md  (shadow-extract via output_root; Conformance Lane)
canonical/skills/aid-discover/references/state-elicit.md -> .aid/knowledge/external-sources.md , .aid/connectors/   (ELICIT E1/E2 write targets; reconciled via canonical/aid/scripts/connectors/*)

# Observation plane
dashboard/server/server.mjs -> dashboard/server/reader.mjs
dashboard/server/server.py  -> dashboard/reader/reader.py
dashboard/reader/reader.py  -> parsers.py , derivation.py , models.py , locator.py
dashboard/reader/*          -> .aid/ artifact schemas (STATE.md, settings.yml, KB)
dashboard/server/reader.mjs <parity> dashboard/reader/*.py   (whole-reader twin -- no import; behavior-equal)
site/                       -> canonical/skills/, canonical/agents/,
                               canonical/aid/templates/{shortcut-catalog.yml,knowledge-base/}
                               (generators read the toolkit at build time)
site/                       -> (independent of the CLI: bin/, lib/, install.sh)
```

**`site/` DOES consume `canonical/` — this was a non-dependency and is no longer.**

```
site/  ->  canonical/       (hard build-time dependency, and enforced)
```

The website derives its content from the toolkit rather than restating
it. **Two** generators — `gen-reference.mjs` and `gen-skills.mjs` — read `canonical/`
on every `prebuild`, and the coupling is *enforced*, not incidental. (The third generator,
`sync-docs.mjs`, reads `docs/` only and is NOT part of this coupling — it is named here
because an earlier revision of this row wrongly counted it, and overstating a dependency to
justify reversing a non-dependency is the same defect as understating it.)

- `gen-skills.mjs` and `gen-reference.mjs` **throw** when the on-disk skill set diverges from
  the catalog plus curated roster, so a canonical change that the site cannot account for
  fails the build rather than silently emitting a stale page.
- `.github/workflows/docs.yml` lists `canonical/**` on both path filters — a canonical-only
  commit must still rebuild the site.
- `tests/canonical/test-doc-counts.sh` compares the counts stated in the public-facing docs
  (root `README.md`, `docs/`, the profile READMEs) against a derivation rooted in `canonical/`.
  Counts stated elsewhere are governed by criterion `G-01` instead of by a guard.

**Consequence for any change:** a `canonical/skills/` addition or removal is now a `site/`
change too. Adding a skill directory without a catalog row or curated-roster entry turns the
site build red by design.

---

## Script Modules by Area

The `canonical/aid/scripts/` tree is grouped by the pipeline phase that consumes
each area. Two scripts are cross-cutting and live where every skill can reach them:
`config/read-setting.sh` (settings resolver) and the top-level `grade.sh` (ledger
grader).

| Area | Scripts | Consumed by | Purpose |
|------|---------|-------------|---------|
| (root) | `grade.sh` | every skill REVIEW state | Reads the reviewer ledger, counts findings by severity, emits a grade. |
| `config/` | `read-setting.sh` | every skill | Resolves a setting from `.aid/settings.yml` (skill-override -> category -> default). |
| `connectors/` | `connector-registry.sh`/`.ps1`, `build-connectors-index.sh`/`.ps1`, `connector-secret.sh`/`.ps1` | `aid-discover` ELICIT (Step E2 author) + reconcile (Steps R0-R5) | Frontmatter accessor (list/read) for `.aid/connectors/*.md` descriptors, the deterministic `INDEX.md` builder, and the no-echo/path-confined secret write/purge handler for the git-ignored `.secrets/` store. Bash+PowerShell twins throughout. Test coverage: `tests/canonical/test-connector-registry.sh`, `test-connector-secret.sh`, `test-connector-secret-ps1.sh`, `test-connector-secret-ac3-leak-sweep.sh`, `test-connector-twins-ps1-parity.sh`, `test-connectors-registry-integration.sh`, `test-build-connectors-index.sh`, `test-reconcile-scenarios.sh`. |
| `execute/` | `complexity-score.sh`, `compute-block-radius.sh`, `writeback-state.sh` | `aid-execute` | Delivery-complexity scoring, failure block-radius (tasks transitively depending on a failed task), and locked per-unit STATE.md writeback. |
| `graph/` | `graph-preflight.sh`, `kb-write-fence.sh`, `graph-stale-check.sh`, `harvest-declared.sh`, `scan-source.sh`, `significance-rules.sh`, `derive-edges.sh`, `relationship-schema.sh`, `build-relationships.sh`, `validate-relationships.sh`, `report-endpoint-satisfiability.sh`, `assemble-coverage-notes.sh`, `grade-graph.sh`, `coverage-predicate.mjs`, `detect-kb-gaps.mjs` | `aid-graph` | The knowledge-relationship graph pipeline: pre-flight prerequisite gate; the write fence that keeps the Knowledge Base read-only for the whole run; content-addressed staleness check; declared-relationship harvest from KB frontmatter plus a source scan, filtered by the significance rules; edge derivation and the `relationships.md` build/validate pair against `templates/graph/relationship-schema.yml` + `relation-vocabulary.yml`; endpoint-satisfiability and coverage reporting; KB gap detection (reported onward, never gated on); and the graph's own two-grade gate. |
| `housekeep/` | `branch-commit.sh`, `cleanup-classify.sh`, `housekeep-state.sh` | `aid-housekeep` | Branch/commit helpers, orphan/cleanup classification, housekeep run-state. |
| `kb/` | `build-project-index.sh`, `build-metrics.sh`, `build-kb-index.sh`, `harvest-coined-terms.sh`, `closure-check.sh`, `discover-preflight.sh`, `kb-actback-task.sh`, `kb-citation-lint.sh`, `kb-dual-intent-probes.sh`, `kb-freshness-check.sh`, `kb-teachback-questions.sh`, `lint-frontmatter.sh`, `recon-classify.sh` | `aid-discover` (most), `aid-update-kb` (`kb-freshness-check.sh`) | The discovery/KB engine: index + metric generation, concept harvest, closure loop, frontmatter + citation lint, path classification, dual-intent self-eval. |
| `migrate/` | `migrate-kb-frontmatter.sh`, `migrate-work-hierarchy.sh`, `migrate-work-hierarchy.ps1` | `aid` CLI update path | One-time migrations (KB frontmatter v2; work-hierarchy restructure). Shell + PowerShell twin. |
| `release/` | `check-version-sync.sh` | `release.sh`, CI | Verifies the version string is in lockstep across all manifests. |
| `summarize/` | `assemble.sh`, `assemble-3part.sh`/`.ps1`, `build-md-export.sh`, `grade-summary.sh`, `manual-checklist.sh`, `spot-check-facts.sh`, `stale-check.sh`, `summarize-preflight.sh`, `validate-html-output.sh`, `validate-diagram-content.mjs`, `validate-visuals.mjs`, `contrast-check.mjs`, `writeback-state.sh` | `aid-summarize` | Builds + validates the `kb.html` visual summary (assembly, markdown export, fact/stale checks, HTML + diagram-content + visual + contrast validation via Playwright/Node). |

> The installed copies under each profile (and the dogfood `.claude/aid/scripts/` and
> `.cursor/aid/scripts/`) are rendered from these canonical sources. Edit `canonical/`,
> never the rendered copy.

---

## Notable Skill Reference Modules

Most skills carry their state-machine prose in `references/*.md`. Three reference
clusters — those of `aid-describe` and `aid-define`, the two halves of the
interview split — are substantial enough to track as modules in their own right.

| Module | Owning skill | Purpose | Key files (durable anchors) |
|--------|--------------|---------|-----------------------------|
| aid-describe elicitation engine | `aid-describe` | The seasoned-analyst interview driver: a fixed D1 opener plus a deterministic five-step next-move selector, ten elicitation moves with a gap-type firing table, expertise calibration, the NFR-7 advisory envelope, and a final coherence check. | `canonical/skills/aid-describe/references/`: `elicitation-engine.md` ("D1 Fixed Opener", "Engine Overview"), `move-playbook.md` ("Gap-Type to Move Firing Table"), `calibration.md`, `advisor-stance.md` ("NFR-7 Question-Envelope Contract"), `coherence-check.md`. |
| Greenfield KB-seed authoring | `aid-describe` | Forward-authors a five-element KB seed (concept-spine + architecture + conventions + tech-stack + decisions) from intent, stamped `source: forward-authored` -- the docs-are-truth, code-conforms inversion. | `canonical/skills/aid-describe/references/state-describe-seed.md`; the `forward-authored` marker is defined in `canonical/aid/templates/kb-authoring/frontmatter-schema.md` (the `forward-authored` source row). |
| aid-housekeep Conformance Lane | `aid-housekeep` | Sub-module of the KB-DELTA state: checks as-built code against `source: forward-authored` design docs in the code -> design direction and flags divergence for human reconciliation; never auto-overwrites the design (NFR-5 carve). Runs a shadow extraction via aid-discover's `output_root` parameter. | `canonical/skills/aid-housekeep/references/state-kb-delta.md` ("Conformance Lane -- forward-authored docs"); the shadow-extract parameter lives in `canonical/skills/aid-discover/references/agent-prompts.md` ("Dispatch Parameter: output_root"). |

---

## Skill Structural Shapes

The 76 skill directories share one **ownership** taxonomy (18 curated + 34 generated doorways
+ 24 hand-authored `repurpose`, per the contracts above) but four distinct **structural**
shapes. The two taxonomies do not line up, and tooling that reads skill bodies must key off
the shape, not the ownership flag.

| Shape | Body structure | Typical size | Exemplars |
|-------|----------------|--------------|-----------|
| Fat pipeline skill | `## Dispatch` table mapping states to `references/state-*.md` workers + `Advance` targets; no inline `## State:` sections | the largest of the skills | `aid-describe` |
| Hand-authored collapse skill | Six inline `## State:` sections in `SKILL.md` itself; self-contained, no delegation | low hundreds of lines -- run `wc -l` on the members rather than trusting a range here | Eight skills: `aid-review`, `aid-research`, `aid-test`, `aid-prototype`, `aid-design`, `aid-update-document`, `aid-create-document`, `aid-report` |
| Generated shortcut doorway | Binds `{verb, artifact}` and delegates to `canonical/aid/templates/shortcut-engine.md` | ~18 lines | `aid-create-api`, `aid-fix` |
| Kind-sibling doorway | Delegates to a **sibling skill**, not to the engine | ~24 lines | `aid-test-security` -> `aid-test`; the `test-*` and `create-diagram`/`create-document` clusters |

- **`repurpose: true` is a generator-ownership flag, not a structural signal.** It marks rows
  whose directories `build-shortcut-skills.py` must never generate or overwrite. `aid-review`
  (fat, 221 lines) and `aid-test-security` (thin, 24 lines) both carry it. Classify by
  inspecting the body.
- **The two doorway shapes carry no control flow of their own.** Their real flow is the shared
  engine's `INTAKE -> CAPTURE -> SPEC -> PLAN -> DETAIL -> GATE -> APPROVAL-HALT`, so any
  per-skill flow extraction must resolve the delegation before it has anything to show.
  **The delegating majority** is the engine doorways plus the kind-siblings. Derive both from
  disk rather than from a figure here -- the doorway population is the non-`repurpose` rows of
  `shortcut-catalog.yml`, and the kind-siblings are the skills whose body delegates to a sibling
  skill instead of to the engine. A stated total for this split has drifted twice: it read 64
  doorways before the alias removal, and a later recount left a skill total here that disagreed
  with this document's own module inventory.
- **There is no single reliable parse marker for a skill's state machine.** Skills variously use
  frontmatter `State machine:`, `## Dispatch` tables, inline `## State:` sections, a literal
  `## State Machine` heading, or ASCII state maps. Branch conditions are prose in parentheses
  inside `Advance` cells, so edge labels are a best-effort extraction rather than a parse.
- **`aid-triage` is a Dispatch-shape skill.** It carries a `## State Machine` heading (line 58)
  *and* a `## Dispatch` table with `State`/`Advance` columns (line 73), plus two inline
  `## State:` sections. An earlier revision of this section cited it as the marker-less
  exception; that was wrong. The genuinely residual skills are curated on-demand ones --
  `aid-config`, the three ticket skills, and the two connector skills (membership varies with
  the classifier's discriminators).

CONFIRMED: the inline-`## State:` counts and the delegation shapes are measured directly
against `canonical/skills/*/SKILL.md`, and delegation is confirmed by `shortcut-engine`
references in the body. **Line counts are deliberately not asserted here** -- every one that was
had drifted by the next reading, which is what `G-01` exists to prevent; measure them when you
need them. Ownership counts follow this document's own criteria and `project-structure.md`.

---

## Entry Points

| Entry point | Module | Type | What it starts |
|-------------|--------|------|----------------|
| `install.sh` / `install.ps1` | Distribution | bootstrap | Downloads + installs the `aid` CLI (curl\|bash / irm\|iex). |
| `bin/aid` (+ `.ps1`/`.cmd`) | Distribution | CLI | Dispatches `aid <subcommand>` on PATH. |
| `packages/pypi/aid_installer/__main__.py` | Distribution | CLI | `aid` on PATH after `pipx install`. |
| `/aid-<skill>` slash commands | Toolkit | agent skill | Resolve to `canonical/skills/<name>/SKILL.md` (installed copy). |
| `.claude/skills/generate-profile/scripts/run_generator.py` | Render | build | Full profile render of `canonical/` -> `profiles/`. |
| `dashboard/server/server.mjs` / `server.py` | Observation | HTTP server | Serves the local read-only dashboard. |
| `site/` (Astro) | Observation | static build | Builds the marketing/docs website. |
| `tests/run-all.sh` | Cross-cutting | test runner | Aggregates the canonical shell suites. |

---

## High-Churn Modules

> Name + reason; the live churn number is point-in-time (run `git log`).

| Module | Why it churns | Risk |
|--------|---------------|------|
| `canonical/skills/aid-discover/` | The actively-developed discovery engine -- large reference set, frequent feature additions. | High |
| `canonical/aid/scripts/kb/` | Backs aid-discover; new linters/checks land here often. | High |
| `lib/aid-install-core.sh` + PS twin | Install/migration semantics evolve with each release; twin must stay in sync. | High |
| `dashboard/reader` + `dashboard/server` | Reader/parser changes follow every STATE.md schema change; two twins to keep in parity. | Medium |

---

## Oversized Modules

**Modules to watch:**

- `dashboard/server/reader.mjs` and `dashboard/reader/parsers.py` -- the two
  largest source files; each is a full state-parsing engine. Large enough to hide
  complexity. `reader.mjs` is the Node **twin of the whole** `dashboard/reader/`
  Python reader (not only `parsers.py`): a change to any reader `.py` must be
  mirrored in `reader.mjs`, doubling the risk.
- `lib/aid-install-core.sh` (and `AidInstallCore.psm1`) -- the largest shell file;
  install/update/remove/manifest logic concentrated in one library.
- `canonical/skills/aid-discover/references/state-generate.md` and
  `state-review.md` -- very large single reference files driving the discovery
  state machine.

---

## Conventions

> The project's own way of adding/wiring a part. State the rule, then the example.

- **Where a new skill goes:** create `canonical/skills/aid-<name>/SKILL.md` (+ a
  `references/` subdir for state files). Name it `aid-<verb>` (see
  `canonical/skills/aid-discover/`). The `SKILL.md` carries YAML frontmatter with
  `name:`, `description:`, `allowed-tools:`, `argument-hint:` (see
  `aid-config/SKILL.md`). This is for hand-authored pipeline / on-demand skills; the
  34 verb-first shortcut doorways are **generated**, not hand-authored -- see "How a
  new shortcut goes" below.
- **Where a new agent goes:** create `canonical/agents/aid-<role>/AGENT.md` -- and only
  that; the directory holds no README. The `AGENT.md` frontmatter carries `name:`, `description:`,
  `tier:` (large/medium/small), `tools:`. Include shared boilerplate with
  `{{include:agent-boilerplate}}` (see `canonical/agents/aid-architect/AGENT.md`).
- **Where a new helper script goes:** place it under the phase area it serves
  (`canonical/aid/scripts/<area>/`). Cross-cutting helpers go at the script root
  (`grade.sh`) or in `config/`. Read settings via `read-setting.sh`; do not parse
  `settings.yml` directly.
- **How a new generated file is registered:** add a `<output-path>|<build-command>`
  line to `canonical/aid/templates/generated-files.txt` (dependencies first); the
  renderer rewrites the `canonical/` path to each profile's install root.
- **How a new shortcut goes:** add a row to
  `canonical/aid/templates/shortcut-catalog.yml`
  (`{name, verb, artifact, alias_of, default_type, group}`), then run the maintainer
  helper `.claude/skills/generate-profile/scripts/build-shortcut-skills.py` to
  emit/refresh the thin `canonical/skills/aid-<name>/SKILL.md` doorway (one per
  non-`repurpose` row), then run the FULL `run_generator.py`. Every shortcut doorway
  delegates to `canonical/aid/templates/shortcut-engine.md`; the family-specific
  SPEC/PLAN/DETAIL scaffolding it consults lives in
  `canonical/aid/templates/shortcut-scaffolding/<family>.md`.
- **Never edit a rendered copy.** Edit `canonical/` and regenerate; `profiles/*`,
  `packages/*/_vendor/`, and the dogfood `.claude/` + `.cursor/` are build output.

---

## Invariants

> Hard MUST/MUST-NOT rules the module graph enforces silently.

- **Single source of truth:** every shipped file originates in `canonical/`.
  `profiles/`, `packages/*/_vendor/`, and the dogfood `.claude/` + `.cursor/` MUST be
  regenerated, never hand-edited. Hand-editing a rendered copy is lost on the next render.
- **Render is a pure mirror bounded by the emission manifest:** the renderer may
  only delete install-tree paths present in the previous run's
  `emission-manifest.jsonl` (`removed_dst`). Files outside any manifest are never
  touched. (See `canonical/EMISSION-MANIFEST.md`.)
- **Language twins stay behavior-equal:** `aid-install-core.sh` <-> `AidInstallCore.psm1`,
  `bin/aid` <-> `bin/aid.ps1`, `dashboard/reader/*.py` <-> `dashboard/server/reader.mjs`
  (the whole Python reader, not only `parsers.py`), and the migrate `.sh`/`.ps1` twins MUST
  change in lockstep. A change to one
  without the other is a defect.
- **Install manifests stay in lockstep:** the dashboard file set vendored into the
  five install manifests (npm, pypi, the three release paths) MUST match; a missing
  file in one channel is a ship bug (precedent: home.html omission).
- **Settings are read through `read-setting.sh`:** scripts MUST NOT hand-parse
  `.aid/settings.yml`; the resolver owns the override -> category -> default chain.
- **Forward-authored docs flow design -> code, never code -> design:** a
  `source: forward-authored` KB doc is the design contract; `aid-housekeep`'s
  Conformance Lane may only FLAG code divergence for human reconciliation and MUST
  NOT overwrite the design with as-built reality (NFR-5 carve; see
  `state-kb-delta.md` "Conformance Lane").
- **Derived STATE views are never written:** the work/delivery `## Tasks State`,
  `## Delivery Gates`, etc. are read-time unions over per-unit STATE.md files; only
  the per-unit files are write targets (see artifact-schemas.md).

---

## Contracts

> Structural shape a new part or connection MUST satisfy.

- **Skill contract:** `canonical/skills/aid-<name>/SKILL.md` MUST carry valid
  frontmatter (`name`, `description`, `allowed-tools`, `argument-hint`) and resolve
  its config via `read-setting.sh`; any REVIEW state MUST emit a reviewer ledger
  and grade it via `grade.sh`.
- **Agent contract:** `canonical/agents/aid-<role>/AGENT.md` MUST carry `name`,
  `description`, `tier`, `tools` frontmatter and define What You Do / Don't Do /
  Key Constraints / When to Escalate sections (see any `AGENT.md`).
- **Emission-manifest record contract:** every rendered file is recorded as a JSONL
  object with exactly `{profile, src, dst, sha256}`, sorted by `dst`, LF-only, with
  a `{"_manifest_version": 1}` sentinel first line (see `canonical/EMISSION-MANIFEST.md`).
- **Generated-file registry contract:** each line is `<output-path>|<build-command>`,
  `canonical/`-rooted, ordered dependencies-first (see `generated-files.txt`).
- **Reader-parity contract:** the Node reader and the Python reader MUST produce the
  same model from the same `.aid/` state (the dashboard parity test suites enforce this).

---

## Gotchas

- **Heavy file duplication is intentional.** `reader.mjs`/`parsers.py` and the whole
  toolkit appear many times (dashboard + npm + pypi `_vendor` + five profiles + the two
  dogfood trees `.claude/` and `.cursor/`). Do NOT "deduplicate" -- they are
  rendered/vendored copies of `canonical/`.
- **Shortcut doorways are generated, not hand-authored.** The 34 `aid-<verb>[-<artifact>]`
  skill directories under `canonical/skills/` are emitted by
  `.claude/skills/generate-profile/scripts/build-shortcut-skills.py` from
  `shortcut-catalog.yml`. Edit the catalog + re-run the helper (then the FULL
  `run_generator.py`); do not hand-edit a generated doorway's `SKILL.md`.
- **Master-only CI gates.** `tests/run-all.sh` (canonical suites) and the Astro
  `site` build run only on push/PR to master; a green feature branch can still break
  master. Run them locally (HOME-pinned) before claiming green.
- **Windows installer tests are not in `run-all.sh`.** `tests/windows/Test-AidInstaller.ps1`
  runs only on the Windows CI lane; a CLI behavior change must update it too.
- **Scan tests must pin `$HOME`.** The migration scan defaults its root to `$HOME`;
  a test firing it without `export HOME=<throwaway>` will migrate the developer's
  real repos.
