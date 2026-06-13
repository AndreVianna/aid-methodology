---
kb-category: meta
source: hand-authored
intent: |
  Cumulative release-tracking ledger for the AID repo — every release newest-first
  with its items tagged [NEW] / [CHANGE] / [FIX], plus an Unreleased section that
  accumulates items for the next (unnumbered) version. Read or update this to know
  what shipped in which version and what is pending release. Maintained by hand;
  at release time the Unreleased section is renamed to the new version + date.
contracts: []
changelog:
  - 2026-06-09: Created — Unreleased (aid-ask, product site, aid-execute work-first arg order) + v1.0.0 back-filled from the GitHub release.
  - 2026-06-09: Moved the AID product website from Unreleased to v1.0.0 (it shipped with v1.0.0; absent from the GitHub release page because that covers only the CLI package).
  - 2026-06-12: Added Unreleased items for the work-001 two-level dashboard (CLI home + repo registry + per-repo home.html relocation + install-wiring), delivery-008.
---

# Release Tracking

> Cumulative log of all releases (newest first) and their items, tagged
> `[NEW]` / `[CHANGE]` / `[FIX]`. The top `Unreleased` section accumulates items for
> the next version; at tag time, rename it to the version + date and start a fresh
> `Unreleased` block. `[NEW]` items lead with a feature name; `[CHANGE]` / `[FIX]`
> are description-only. An optional trailing version on an Unreleased item is a
> planned target.

## Unreleased

- [NEW] /aid-ask - optional read-only skill that answers free-form project questions from the Knowledge Base, the codebase, and in-flight works, with source citations.
- [CHANGE] /aid-execute now leads with the work argument (/aid-execute work-001 task-001), consistent with the other skills; the single-work shorthand still works.
- [NEW] AID dashboard CLI home - `aid dashboard` now serves a machine-level home page at `/` that lists every repo this CLI install manages (read live from each repo's `.aid/settings.yml`), with a click-through into each repo's own live dashboard. One read-only server (127.0.0.1, Python or Node) serves all repos via `/r/<id>/...`.
- [NEW] Repo registry - the CLI tracks the repos it manages in `$AID_HOME/registry.yml`; `aid add` registers the current repo (first tool) and `aid remove` unregisters it when the last tool is removed. Paths-only, atomic writes, never blocks the install/uninstall.
- [CHANGE] The per-repo dashboard page moved from `dashboard/index.html` to `<repo>/.aid/dashboard/home.html` (co-located with the KB summary); the machine/CLI panel moved off the per-repo page onto the new CLI home. `aid dashboard --remote` now exposes the CLI home (all registered repos) over the private tailnet.
- [CHANGE] The dashboard server + reader are now vendored into the npm and PyPI packages and installed under `$AID_HOME/dashboard/`, so `aid dashboard` runs from the install tree (previously it only ran from a repo checkout).

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
