# Release Notes

> Cumulative log of user-visible changes for the next release, grouped as **New**,
> **Improvements**, and **Fixes**. This file lives on `master` and accumulates items
> as they merge, surviving feature-branch deletion. At tag time, rename
> `[Unreleased]` to the new version + date, prune anything not actually shipping,
> and start a fresh `[Unreleased]` block. Items are compiled from changes merged
> since the last release (`v1.0.0`) and should be reviewed before the release is cut.

## [Unreleased]

### New

- **AID product website (`work-004`).** A full documentation + marketing site for
  AID (AI Integrated Development): home, install, and versions/releases pages;
  knowledge surfaces; pipeline and maintainer guides; a Contact Us section with
  dedicated report/contact pages; and on-site feedback/issue forms that prefill a
  GitHub issue (no backend). Includes Casulo AI Labs branding.
- **Automated installer (`work-002`).** An automated installer for setting up AID in
  a project, replacing the previous manual setup steps.
- **`/aid-ask` — ask the project anything (optional, read-only).** A new on-demand
  skill that answers free-form questions about the project by consulting the
  Knowledge Base, the live codebase, and in-flight AID works (`.aid/work-*/`),
  replying with source citations (KB doc names, file paths, or `work-NNN` STATE). It
  is single-shot (no state machine), never writes a file, and sits outside the
  numbered pipeline. It dispatches `aid-researcher` for deep investigation and
  answers trivial questions inline; when context is insufficient it states the gap
  instead of guessing. Available across all five install trees (Claude Code, Codex,
  Cursor, GitHub Copilot CLI, Antigravity).

### Improvements

- **`/aid-execute` now leads with the work argument** — `/aid-execute work-001 task-001`,
  consistent with every sibling skill (aid-detail, aid-plan, aid-specify,
  aid-interview). The single-work shorthand `/aid-execute task-001` still works.
- **Work-scoped delivery branches.** Delivery branches are now named
  `aid/{work}-delivery-NNN`, preventing cross-work branch collisions when multiple
  works share a delivery number.
- **Hardened release publishing.** npm publish now uses OIDC Trusted Publishing,
  dropping the long-lived `NPM_TOKEN` secret.
- **Hardened site dependencies.** Cleared all npm-audit vulnerabilities in the docs
  site dev dependencies; routine GitHub Actions dependency bumps (Dependabot).

### Fixes

- **Docs site content** — corrected the product name to "AID = AI Integrated
  Development" across the site, fixed the pipeline docs to show the lite path, and
  applied grounded-content audit corrections.
- **Docs site / Node 22** — the site now requires Node >= 22.12 (Astro 6); CI and
  docs build bumped accordingly.
- **Releases data** — `fetch-release-data` no longer breaks on Windows (main-module
  guard), and a local `npm run build` now shows releases via a data-file fallback.
- **Search modal** — fixed the clear button overlapping the input and overflowing.

### Known Issues

- The Knowledge Base's hand-written skill-count enumerations (e.g. "11 user-facing
  skills") are not yet updated for `aid-ask` (now 12). Reconcile via `/aid-housekeep`
  (KB-DELTA) before tagging — tracked as **Q30** in `.aid/knowledge/STATE.md`.
