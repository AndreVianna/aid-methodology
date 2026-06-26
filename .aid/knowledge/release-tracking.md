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

- [CHANGE] Codex profile now installs exclusively under `.codex/` — the former `.agents/` split root is retired; all Codex agents, skills, and AID-own files live under the unified `.codex/{agents,skills,aid}` tree (work-005 FR2).
- [CHANGE] All five host tools now use a uniform `{agents,skills,aid}` layout under their own root (`.claude/`, `.cursor/`, `.codex/`, `.github/`, `.agent/`) — agent format branches collapsed to uniform markdown; Codex TOML branch retained dormant pending E-CODEX-1 verification (work-005 FR1/FR4).
- [CHANGE] Profile generator simplified from 13 Python files to 7 — tool-specific emitter scripts replaced by a single copy-based generator that renders profiles via file-level copy + minimal path substitution, with no per-tool branching logic outside the profiles themselves (work-005 FR1/FR5/FR6).
- [CHANGE] `aid update` now replaces a profile's managed files atomically in a single pass and removes stale files left by previous versions — ensures a clean, complete layout after every update with no orphaned tool files from older generator shapes (work-005 FR7).

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
