---
kb-category: extension
source: hand-authored
objective: Cumulative release ledger for the AID repo — every release newest-first with its items tagged [NEW] / [CHANGE] / [FIX], plus an Unreleased section that accumulates items for the next version.
summary: Read or update this to know what shipped in which version and what is pending release. Hand-maintained; at tag time the Unreleased section is renamed to the version + date and a fresh Unreleased block starts. Referenced by infrastructure.md as the home of release history (the root RELEASE_NOTES.md is retired).
sources:
  - release.sh
  - .github/workflows/release.yml
tags: [C8, release, versioning, changelog, tracking]
see_also: [infrastructure.md, technology-stack.md]
owner: skill-self
audience: [developer, devops, product]
---

# Release Tracking

> Cumulative log of all releases (newest first) and their items, tagged
> `[NEW]` / `[CHANGE]` / `[FIX]`. The top `Unreleased` section accumulates items for
> the next version; at tag time, rename it to the version + date and start a fresh
> `Unreleased` block. `[NEW]` items lead with a feature name; `[CHANGE]` / `[FIX]`
> are description-only. An optional trailing version on an Unreleased item is a
> planned target.

## Unreleased

_Nothing yet._

## v2.0.0 - 2026-06-28

> **Major release.** Breaking changes to the skill commands and the install layout (see [Migration to v2.0.0](#migration-to-v200)). The `.aid/` project-state format is unchanged — there is **no data migration**.

- [NEW] **`aid-describe` + `aid-define`** — **Breaking:** `aid-interview` is split into two Phase 2 skills: `aid-describe` (Phase 2a — conversational requirements gathering driven by the seasoned-analyst engine, the lite path, and the greenfield DESCRIBE-SEED state) and `aid-define` (Phase 2b — feature decomposition + KB cross-reference from approved requirements); skill count rises from 13 to 14; the `aid-interviewer` agent is unchanged.
- [NEW] **Seasoned-analyst elicitation engine** — `aid-describe` generates a suggested answer with rationale for each interview question before asking it (NFR-7), enabling guided triage over open-ended elicitation; anti-anchoring guards (calibration-gated open-first, whole-picture read-back, verbatim wording) prevent premature convergence.
- [NEW] **Greenfield seed authoring** — `aid-describe` (its DESCRIBE-SEED state) forward-authors KB docs (frontmatter `source: forward-authored`) as the design contract for greenfield projects; these docs are authoritative and code conforms to them, not the reverse.
- [NEW] **Build conformance check** — `aid-housekeep` gains a Conformance Lane in KB-DELTA: a code→design shadow extraction that flags design↔as-built divergence for human reconciliation (flag-not-overwrite; design authoritative; never auto-applies as-built). Backed by three new canonical suites: `test-output-root-isolation.sh`, `test-conformance-lane-semantics.sh`, `test-kb-forward-authored-marker.sh`.
- [NEW] **`aid-update-kb`** — new on-demand, off-pipeline skill that applies a described, targeted KB delta through the same review/approval gate as `aid-discover`; human-gated (no auto-apply), transient run-state in `.aid/.temp/`.
- [NEW] **Domain-driven Knowledge Base** — KB docs now carry structured frontmatter (`kb-category`, `objective`, `summary`, `sources`, `tags`, `audience`, `owner`) across the standard doc types; `lint-frontmatter.sh` validates conformance and the non-destructive `migrate-kb-frontmatter.sh` (propose/apply, degrade-safe) migrates existing KBs.
- [NEW] **KB INDEX routing table** — `INDEX.md` emits a routing table (doc → category → concern → audience → confidence → summary) instead of a flat list; doc names link to their in-page `kb.html` sections.
- [NEW] **`aid-discover` completeness gates** — two pre-GENERATE checks: term-closure (every coined term is closed against the KB or a user-confirmed exclusion; discovery never finishes with an open Q&A) and operational act-back (the reviewer verifies the KB actually guides a representative task).
- [NEW] **`aid-discover` dual-intent self-evaluation** — before the GENERATE gate, two blind self-evals run: Intent-1 (blind work-simulation from the KB alone) and Intent-2 (blind glossary reconstruction + source confrontation); both must pass.
- [NEW] **Per-document dashboard freshness** — the dashboard KB card shows a per-document suspect marker for each stale KB file, replacing the single overall "Outdated" flag.
- [NEW] **Redesigned `kb.html`** — the KB visual summary is rebuilt as a newcomer-facing product: diagrams pre-rendered as inline SVG at generation time (the Mermaid runtime engine is removed — faster load, no external dependency), light/dark themes at WCAG-AA contrast, click-to-expand lightbox, concept-spine narrative, and a visual-fidelity gate.
- [NEW] **Export buttons on `kb.html`** — "Export as Markdown" (a self-contained file from a generation-time base64 payload; works offline) and "Export as PDF" (print-optimized CSS; dark theme preserved).
- [NEW] **Diagram-content gate** — a manifest + `validate-diagram-content.mjs` assert each `kb.html` diagram contains its required labels and no stale tokens (phase names, skill/agent/profile counts); wired into `aid-summarize` VALIDATE and a canonical suite, with `docs/diagram-content-reference.md` as the human content contract.
- [CHANGE] **Breaking:** Codex installs exclusively under `.codex/` — the former `.agents/` split root is retired; all Codex agents, skills, and AID-owned files live under the unified `.codex/{agents,skills,aid}` tree.
- [CHANGE] **Breaking:** all five host tools use a uniform `{agents,skills,aid}` layout under their own root (`.claude/`, `.cursor/`, `.codex/`, `.github/`, `.agent/`); `aid update` migrates an upgraded project to the new structure and prunes old files.
- [CHANGE] **Breaking:** `aid-ask` renamed to `aid-query-kb` — behavior preserved; unanswerable queries now also log a Query-Gap to the relevant work `STATE.md` so knowledge gaps feed back into the KB loop.
- [CHANGE] Profile generator simplified from 13 Python files to 7 — a single copy-based generator replaces the per-tool emitter scripts (no per-tool branching outside the profiles).
- [CHANGE] `aid update` replaces a profile's managed files atomically in a single pass and removes stale files left by previous versions; `--dry-run` previews the planned deletions.
- [CHANGE] Phase 2 is labeled **"Describe → Define"** across the methodology, KB, site, and the `kb.html` pipeline diagram (resolving the prior `2·Interview` / `2·Define` inconsistency).
- [CHANGE] `aid-discover` defers all ambiguities to the user — any unclear term, discrepancy, classification, or exclusion generates a Q&A entry and waits for explicit resolution; nothing is resolved silently.
- [CHANGE] `aid-reviewer` gains source-authority + cross-reference reconciliation checks (e.g. flags an instruction file treated as an authoritative spec); enforced at the `aid-discover` REVIEW gate.
- [CHANGE] `aid-summarize` generates a doc-set-driven KB summary — sections derive from the resolved doc-set and concern model; concept-spine narrative; newcomer tone.
- [FIX] KB pipeline phase model corrected everywhere — a from-zero `aid-discover` run had grounded on a stale instruction file and propagated a bogus "12-phase pipeline"; the authoritative model (six numbered phases Discover → Execute; `aid-config` bootstrap; Deploy/Monitor optional Deliver) is now enforced across the KB, diagrams, and `kb.html`.
- [FIX] Multi-tool distribution diagram corrected — all three channels (curl/irm, npm, PyPI) are shown as equivalent paths to the same content, not per-profile.
- [FIX] `kb.html` dark-mode contrast fixed for the Architecture and Module-Map diagrams (WCAG AA in both themes).
- [FIX] `kb.html` Markdown-export payload now survives the canonical assemble pipeline (it was dropped on regeneration through `assemble.sh`).
- [FIX] Windows PowerShell 5.1 compatibility restored in all shipped scripts (TLS 1.2 enforcement, `-Encoding utf8NoBOM`, three-arg `Join-Path`); guarded by an AST lint and a 5.1 CI lane.
- [FIX] `aid-config` rejects `kb_baseline` as an unknown key — it is producer-written (by `aid-discover` / `aid-housekeep`), not user-editable.
- [FIX] Release version-sync gate fixed — `check-version-sync.sh` resolved the repo root at a fixed depth that broke when the scripts moved under `canonical/aid/scripts/` (it landed on `canonical/` and could not find `VERSION`); it now walks up to the `VERSION` file (location-independent), with a regression test exercising the bare CI invocation.

### Migration to v2.0.0

`aid update` **is** the migration — idempotent and self-cleaning; no manual file steps and no data migration.

- **Skill renames** (`/aid-interview` → `/aid-describe` + `/aid-define`; `/aid-ask` → `/aid-query-kb`): `aid update` prunes the old skill directories (aid-prefixed, absent from the new manifest) and installs the new ones; the `CLAUDE.md` / `AGENTS.md` AID-managed region is rewritten in place.
- **Install layout** (`.agents/` → `.codex/`, uniform `{agents,skills,aid}`): handled by `aid update` (atomic replace + prune) and `aid update self` for all registered projects; also runs lazily on the next `aid` command after a pip/pipx upgrade.
- **In-flight Phase-2 work resumes** under the new skills — a mid-interview work continues with `/aid-describe`; an approved work hands off to `/aid-define`. The `.aid/` format is unchanged (the STATE.md `Phase` enum stays compatible), so existing works and KB are untouched.
- **Existing KBs (optional, non-destructive):** to adopt the new domain-driven frontmatter (lighting up the doc-set-driven summary, INDEX routing, and per-doc freshness), run `migrate-kb-frontmatter.sh` (or `/aid-housekeep`), then `/aid-summarize` to refresh `kb.html`. Old KBs keep working without this (graceful fallback). **Never reset/rebuild the KB.**

## v1.1.1 - 2026-06-19

- [FIX] A project set up with `aid add <tool>` alone (a manifest but no `settings.yml`) no longer warns `this project uses an older format` on **every** `aid update`. The first `aid update` now synthesizes a stamped `settings.yml` for it, so the warning clears and stays cleared. (Repos created through the full `/aid-config` pipeline were unaffected.) Supersedes v1.1.0.

## v1.1.0 - 2026-06-17

- [NEW] **`aid projects` command** — `aid projects [list|add|remove|help]` manages the projects AID tracks; `list` shows each project's state (`vX.Y.Z` / `untracked` / `no-aid` / `missing`), tools, tier, and a `*` current-directory marker; `add`/`remove` manage tracking only (no tools are touched). Tier is resolved deterministically by location (under `$HOME` → user; outside on a global install → shared) with `--local`/`--shared` overrides; no interactive prompt.
- [NEW] **Project registry** — the CLI tracks the projects it manages in `$AID_STATE_HOME/registry.yml`: a per-user tier plus, on a global install, a privileged-written machine-shared tier, unioned at read. `aid add` / `aid remove` register/unregister; paths-only, atomic writes, degrades gracefully, never blocks install/uninstall.
- [NEW] **Upgrade migration** — `aid update self` brings your existing projects up to the current layout (per project: All/Yes/No/Cancel); `aid update` inside a project migrates just that one. Idempotent and additive — validates/repairs (or, for very old repos, creates) `.aid/settings.yml` preserving your settings and comments, and registers the project. Also runs lazily on the next `aid` command after an upgrade, so pip/pipx installs (no postinstall hook) are covered.
- [NEW] **AID dashboard** — a local, read-only dashboard for your AID projects: a per-project live view (pipeline status, installed tools, a 5-state Knowledge-Base freshness card including "Outdated" detection), a machine-level home (`aid dashboard`) listing every project this install manages with click-through, a task drill-down forensic panel, and a 4-level breadcrumb. Served by a vendored local server (Python or Node, 127.0.0.1); `aid dashboard --remote` exposes the home over your private tailnet.
- [NEW] **/aid-ask** — optional, read-only, on-demand skill that answers free-form project questions from the Knowledge Base, the codebase, and in-flight works, with source citations. Never writes.
- [NEW] **Self-cleaning install/update** — installing or updating a tool now prunes stale AID files (renamed, moved, or dropped between versions) instead of leaving them behind forever; only AID-managed entries are pruned and your own files are never touched.
- [CHANGE] `/aid-execute` now leads with the work argument (`/aid-execute work-001 task-001`), consistent with the other skills; the single-work shorthand still works.
- [CHANGE] `/aid-discover` now auto-runs `/aid-summarize` at the end (after KB approval) to generate the KB summary; both existing approval gates are unchanged.
- [CHANGE] The release source is mirror-overridable — `AID_API_BASE` and `AID_DOWNLOAD_BASE` override the release endpoints, for air-gapped installs or enterprise mirrors.
- [CHANGE] Root-agent files (`CLAUDE.md`/`AGENTS.md`) now carry an imperative tracking-discipline rule: every agent — whether invoked by a skill or a direct prompt, on the full or lite path — must immediately record any project/task/deliverable state change in the work's `STATE.md` (created from the work-state template if absent), so every pipeline stays visible and trackable in the dashboard and to `/aid-execute`.
- [CHANGE] AID-delivered content is now isolated from your files: AID's own folders install under an `aid/` subtree (e.g. `.claude/aid/{scripts,templates,recipes}`) and AID files in tool-native folders (`agents/`, `skills/`, `rules/`) all carry an `aid-` prefix — so AID content can be updated and pruned in place without ever colliding with yours.
- [CHANGE] `CLAUDE.md` / `AGENTS.md` updates are now in-place and lossless: AID rewrites only the region between `<!-- AID:BEGIN -->` / `<!-- AID:END -->` markers and preserves everything you authored outside it; the old `.aid-new` sidecar file is gone, and existing marker-less files migrate cleanly on the next update.
- [CHANGE] The dashboard now discovers in-flight work in git worktrees: work that lives only on a worktree branch is surfaced under its project (labeled by branch) instead of being invisible, with same-work pipelines across branches merged into one view (most-advanced state wins, no branch is the loser). Degrades to the main checkout when git is unavailable.
- [FIX] `aid` commands no longer fail with permission-denied on a root-owned global install; mutable state (registry, update-check cache) is written to `~/.aid` (or the shared state home), never into the install directory.
- [FIX] Parallel delivery branches no longer collide on a shared work-state file — each unit's state is written by exactly one branch and merges back without conflict, so simultaneous deliveries on separate branches stay trackable.
- [NOTE] User-facing "repo"/"repos" wording is now "project"/"projects"; the registry's on-disk key is `projects:`, and any existing `repos:`-keyed file is read transparently.

## v1.0.0 - 2026-06-07

- Pipeline & skills - six numbered phase commands (Discover -> Execute), /aid-config, and optional Deliver skills (/aid-deploy, /aid-monitor, /aid-summarize, /aid-housekeep); 11 user-facing skills.
- Knowledge Base - 14 standard KB document types with RAG-by-convention navigation, a per-project configurable doc-set, and a self-contained offline KB summary.
- Agent model - 9 specialized agents across three tiers, with structural separation of duties (reviewer tier always >= executor).
- Lite path & recipes - description-first TRIAGE auto-routes small work to a lite path; 51 recipes with {{slot}} substitution; mid-flight escalation to the full path.
- Quality & review - two-tier review (per-task quick-check + per-delivery graded fix loop, A+ to F), a configurable minimum grade, and 11 formal feedback loops.
- Execution engine - 8 task types, parallel pool dispatch, branch-per-delivery isolation (aid/{work}-delivery-NNN), and always-on traceability.
- Installation & host-tool support - persistent global `aid` CLI (add/status/update/remove/version), four install channels (curl/irm, npm, PyPI, offline bundle), and five host tools with byte-identical bodies.
- Documentation & examples - methodology guide, FAQ, glossary, repository map, and worked greenfield / brownfield (full + lite) examples.
- Product website - documentation + marketing site (home, install, releases, knowledge surfaces, pipeline & maintainer guides, Contact Us, and on-site feedback forms that prefill a GitHub issue). Not in the GitHub release page, which covers only the CLI package.

## Change Log

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-06-25 | Restored into the domain-driven KB as a first-class `extension` doc (frontmatter conformed to the authoring standard: objective/summary/sources/tags/see_also/owner/audience). Release-ledger content preserved verbatim from the prior hand-authored KB; resolves the dangling `infrastructure.md` reference. Prior per-edit history is in git. |
| 1.1 | 2026-06-28 | Added 4 Unreleased entries for work-aid-interview-improvements: aid-describe/aid-define split (13->14 skills), seasoned-analyst elicitation engine, greenfield seed authoring, and the aid-housekeep Conformance Lane. |
