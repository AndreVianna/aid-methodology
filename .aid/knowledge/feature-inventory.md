---
kb-category: primary
source: hand-authored
intent: |
  Canonical feature list with status (Shipped / Partial / Pending / In Progress / Deprecated), source, and traceability to work items. Read this to understand WHAT the project does at a feature level.
contracts: []
changelog:
  - 2026-05-26: KB Authoring v2 template seed
  - 2026-05-27: Populated with 10 user-facing skills + 1 maintainer-only skill
  - 2026-06-03: Added /aid-housekeep (11th user-facing skill) via /aid-housekeep KB-delta refresh
  - 2026-06-05: work-002-auto-installer — added the installer/CLI capability (the persistent global `aid` CLI + its four install channels) as an engineering feature; corrected the `/aid-generate` row (it is no longer shipped via `setup.sh` — that installer was replaced by the `aid` CLI).
  - 2026-06-03: methodology v3.2 — marked /aid-deploy and /aid-monitor as optional, on-demand end-of-pipeline Deliver skills (not numbered phases); independent of each other.
  - 2026-06-07: v1.0.0 first stable release — corrected stale VERSION note (0.7.5 → 1.0.0); added Agent model (9 agents), Knowledge Base doc-set (14), feedback loops (11), and host-tool profiles (5) as tracked feature areas.
---

# Feature Inventory

> The user-facing features of the AID methodology repository — i.e., the slash
> commands an adopter can invoke once they have AID installed in their project.

**Status values (text-only — machine-parsed):** `Shipped` · `Partial` · `Pending` · `In Progress` · `Deprecated`
(Decorative glyphs are NOT used here — see `coding-standards.md §14` for the text-for-machine rule.)

## User-facing skills (11)

| # | Skill | Status | Description | Source |
|---|-------|--------|-------------|--------|
| 1 | `/aid-config` | Shipped | View or update AID pipeline settings. Bare invocation shows all values in a table; first run auto-creates `.aid/settings.yml` from the template. Pass a dotted key to view and update one setting interactively. | `canonical/skills/aid-config/SKILL.md` |
| 2 | `/aid-discover` | Shipped | Brownfield project discovery with built-in quality gate. Analyzes all repository content (code, configuration, and documentation) to populate KB documents, then reviews, collects user input, fixes issues, and gets user approval — one step per run. | `canonical/skills/aid-discover/SKILL.md` |
| 3 | `/aid-interview` | Shipped | Adaptive requirements gathering through conversational interview. Builds REQUIREMENTS.md incrementally, then cross-references against the KB and decomposes functional requirements into discrete feature files; supports a lite path for small work. | `canonical/skills/aid-interview/SKILL.md` |
| 4 | `/aid-specify` | Shipped | Technical specification through conversational refinement, one feature at a time. Acts as a tech lead — reads KB, Requirements, and codebase, proposes technical solutions, and builds the spec collaboratively with the developer. | `canonical/skills/aid-specify/SKILL.md` |
| 5 | `/aid-plan` | Shipped | Sequences feature SPECs into deliverables, each one a functional MVP that builds on the previous. Answers one question: in what order do we deliver, and does each delivery stand on its own? | `canonical/skills/aid-plan/SKILL.md` |
| 6 | `/aid-detail` | Shipped | Breaks deliverables into small, dependency-driven, typed tasks — each one a reviewable unit. Detects task types from SPEC signals and builds an execution graph per delivery with explicit dependencies and parallelism. | `canonical/skills/aid-detail/SKILL.md` |
| 7 | `/aid-execute` | Shipped | Executes a task based on its type (RESEARCH, DESIGN, IMPLEMENT, TEST, DOCUMENT, MIGRATE, REFACTOR, or CONFIGURE) with a built-in review-fix loop per type. Runs until the grade meets the configured minimum. | `canonical/skills/aid-execute/SKILL.md` |
| 8 | `/aid-deploy` | Shipped | Optional, on-demand end-of-pipeline Deliver skill (not a numbered phase). Packages completed deliveries into a release. Selects eligible deliveries, verifies the combined build, packages according to project infrastructure, generates release notes, and updates artifact statuses. | `canonical/skills/aid-deploy/SKILL.md` |
| 9 | `/aid-monitor` | Shipped | Optional, on-demand end-of-pipeline Deliver skill (not a numbered phase; independent of `aid-deploy`). Observes production, classifies findings, and routes actions. Combines telemetry interpretation with triage — detects anomalies, performs root cause analysis, and routes findings to `aid-interview` (bugs via its LITE-BUG-FIX triage; change requests as new/changed requirements). | `canonical/skills/aid-monitor/SKILL.md` |
| 10 | `/aid-summarize` | Shipped | Generates a single self-contained `knowledge-summary.html` from `.aid/knowledge/`. Inlines Mermaid diagrams for offline use, supports light/dark themes, and enforces a two-grade quality gate (Machine + Human) before writing the final output. | `canonical/skills/aid-summarize/SKILL.md` |
| 11 | `/aid-housekeep` | Shipped | Optional on-demand housekeeping. Runs three gated jobs in strict order — KB-DELTA (re-discover KB docs that drifted since the last approval) → SUMMARY-DELTA (regenerate the visual summary if the KB changed) → CLEANUP (sweep stale `.aid/` work-area artifacts). Each stage commits on an `aid/housekeep-*` branch; never pushes. Re-entrant: a stalled run resumes at the stalled stage. Not part of the mandatory pipeline. | `canonical/skills/aid-housekeep/SKILL.md` |

## Maintainer-only skills (1)

| # | Skill | Status | Description | Source |
|---|-------|--------|-------------|--------|
| - | `/aid-generate` | Shipped | Regenerates the five install trees (claude-code, codex, cursor, copilot-cli, antigravity) from `canonical/` and `profiles/`. Not part of the end-user `aid` CLI; lives only at `.claude/skills/aid-generate/` to avoid a chicken-and-egg deployment problem. | `.claude/skills/aid-generate/SKILL.md` |

## Agent model (9 agents)

The skills above dispatch a fixed roster of specialized agents across three model tiers.
The reviewer's tier is always ≥ the executor's, and the agent that writes code never grades
its own work.

| Tier | Agents | Source |
|------|--------|--------|
| Large | `aid-architect`, `aid-interviewer`, `aid-researcher`, `aid-reviewer` | `canonical/agents/*/AGENT.md` |
| Medium | `aid-developer`, `aid-operator`, `aid-orchestrator`, `aid-tech-writer` | `canonical/agents/*/AGENT.md` |
| Small | `aid-clerk` | `canonical/agents/aid-clerk/AGENT.md` |

## Knowledge Base doc-set (14 standard docs)

`aid-discover` populates a configurable set of standard Knowledge Base documents (default
seed: **14**) under `.aid/knowledge/`, plus three meta-documents (`INDEX.md`, `README.md`,
`STATE.md`). Navigated by convention (RAG-by-convention). Configurable per project via
`discovery.doc_set` in `.aid/settings.yml`. Templates: `canonical/templates/knowledge-base/*.md`.

## Feedback loops (11)

Eleven formal pathways let a downstream phase revise an upstream artifact, each producing a
tracked record: Q&A entries (appended to a STATE file), `IMPEDIMENT.md` (implementation
contradicts the spec), and MONITOR-STATE findings (production → fix / change-request).
Source: `docs/aid-methodology.md` §6 Feedback Loops.

## Host-tool profiles (5)

`aid add <tool>` installs AID into a project for any of five host tools, with byte-identical
skill/agent bodies (only the wrapper format differs). Source of truth is `canonical/`,
rendered into `profiles/` by the generator (`run_generator.py`).

| Profile | Install dir | Context file |
|---------|-------------|--------------|
| Claude Code | `.claude/` | `CLAUDE.md` |
| Codex CLI | `.codex/agents/` + `.agents/` | `AGENTS.md` |
| Cursor | `.cursor/` | `AGENTS.md` |
| GitHub Copilot CLI | `.github/` | `AGENTS.md` |
| Antigravity | `.agent/` | `AGENTS.md` |

## Engineering features (referenced for historical context)

The 11 user-facing skills above are the result of the following engineering work items:

- **Thin-Router Skills** (work-001 feature-002) — every `aid-*` SKILL.md is a state router (≤~360 lines) that delegates per-state logic to `references/state-*.md` files.
- **Two-tier review** (work-001 feature-004) — per-task quick-check (Small-tier reviewer, no grade loop) + per-delivery quality gate (full review/fix/review loop with `grade.sh` determinism).
- **Lite path with description-first TRIAGE** (work-001 feature-005; restructured by work-001-lite-path-recipes) — `aid-interview` TRIAGE infers the work-type + best-matching recipe from a free-form work description and routes small work to LITE-BUG-FIX / LITE-REFACTOR / LITE-FEATURE sub-paths (the `single-doc`/LITE-DOC sub-path was eliminated — documentation/report work folds into LITE-FEATURE/LITE-REFACTOR).
- **Pool dispatch** (work-001 feature-009) — `aid-execute` runs a PD-0..PD-6 pool model with `MaxConcurrent` capacity, wait-for-any-completion, failure-block-radius, and graceful degradation.
- **Recipes catalog** (work-001 feature-011; expanded by work-001-lite-path-recipes) — `canonical/recipes/` ships **51** pre-filled lite-path templates, named `add-X`/`change-X`/`fix-X` across 11 target-kind families + refactor-only verbs + 1 cross-type (`add-test-coverage`), with YAML front-matter (incl. a `summary:` field TRIAGE matches against) and `{{slot}}` placeholders.
- **Always-on traceability** (work-003) — every long-running subagent dispatch surfaces L1 state markers, L2 ETA bracket pairs, and L3 heartbeat files.
- **Optional housekeeping skill** (work-001-aid-housekeep) — `/aid-housekeep` reconciles drift in three strictly-ordered gated jobs (KB-DELTA → SUMMARY-DELTA → CLEANUP) on an `aid/housekeep-*` branch, backed by deterministic helpers in `canonical/scripts/housekeep/` (run-state I/O + resume rule, branch/commit safety guard, stale-artifact classification).

## Delivery surface (the installer)

How adopters get AID onto their machine and into a project — not a slash command, but the
capability that delivers all of the above. Shipped by **work-002-auto-installer**.

| Capability | Status | Description | Source |
|------------|--------|-------------|--------|
| Persistent global `aid` CLI | Shipped | Bootstrapped once per machine into `$AID_HOME`, then run per project. Subcommands: bare `aid` (dashboard), `aid status`, `aid add <tool>[,...]`, `aid update [<tool>... \| self]`, `aid remove [<tool>... \| self]`, `aid version`; flags `--from-bundle`/`--version`/`--force`/`--target`/`--verbose`. Cross-platform: `bin/aid` (Bash), `bin/aid.ps1` + `bin/aid.cmd` (PowerShell), shared engines `lib/aid-install-core.sh` + `lib/AidInstallCore.psm1`. | `bin/aid`, `lib/aid-install-core.sh` |
| Four install channels | Shipped | (1) curl/irm bootstrap (`install.sh` / `install.ps1`), (2) npm `aid-installer` (`packages/npm/`), (3) PyPI `aid-installer` (`packages/pypi/`), (4) offline `aid add <tool> --from-bundle <path>`. All deliver the same CLI; npm/PyPI are thin shims that vendor the payload and spawn `bin/aid`. | `install.sh`, `packages/npm/package.json`, `packages/pypi/pyproject.toml` |
| FR11 protect-on-diff | Shipped | A user-authored root `CLAUDE.md`/`AGENTS.md` is written as `*.aid-new` for review rather than overwritten on `aid add`/`aid update`. | `lib/aid-install-core.sh`, `docs/install.md` |
| FR12 invariant root `AGENTS.md` | Shipped | The four AGENTS.md-writing tools ship a byte-identical root `AGENTS.md`; CI-guarded. | `tests/canonical/test-agents-md-invariant.sh` |
| Tag-triggered release pipeline | Shipped | `release.sh` builds the profile tarballs + CLI bundle + `SHA256SUMS` + `gh release create`; `.github/workflows/release.yml` gates then publishes GitHub Release + npm/PyPI via OIDC on a `v*` tag. **v1.0.0** is the first stable release (v0.7.0–v0.7.5 were pre-releases); `VERSION` = 1.0.0. | `release.sh`, `.github/workflows/release.yml` |
