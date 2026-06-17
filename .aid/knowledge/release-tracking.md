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
  - 2026-06-13: Added Unreleased items for the work-001 KB tier (5-state KB freshness card + outdated detection, kb.html relocation, aid-discover->aid-summarize auto-trigger + kb_baseline), delivery-009.
  - 2026-06-13: Added Unreleased items for the work-001 task drill-down view (Level-3 forensic panel: findings/ledger/raw-STATE/honest-logs over a lazy ?detail= poll) + the 4-level dashboard breadcrumb, delivery-010.
  - 2026-06-13: Added Unreleased items for the work-001 upgrade migration (aid update self/[<tool>] migrate pre-existing repos: settings repair/synthesize, install home.html, relocate summary, register; version-sentinel + npm postinstall trigger) + the now-vendored per-repo home.html, delivery-011 (resolves KI-010).
  - 2026-06-17: Added Unreleased entry for work-002 aid projects command (list/add/remove/help, deterministic tier, repos:→projects: key + terminology change), delivery-002.
---

# Release Tracking

> Cumulative log of all releases (newest first) and their items, tagged
> `[NEW]` / `[CHANGE]` / `[FIX]`. The top `Unreleased` section accumulates items for
> the next version; at tag time, rename it to the version + date and start a fresh
> `Unreleased` block. `[NEW]` items lead with a feature name; `[CHANGE]` / `[FIX]`
> are description-only. An optional trailing version on an Unreleased item is a
> planned target.

## Unreleased

- [NEW] aid projects command - `aid projects [list|add|remove|help]` manages the set of directories AID tracks (a *project* = any folder containing `.aid/`). `list` renders every registered project with its state (`vX.Y.Z` / `untracked` / `no-aid` / `missing`), tools, tier (user/shared), and a `*` marker for the current directory; `add [path]` registers a directory, `remove [path]` unregisters it (tracking-only — no tools are touched). Tier is resolved deterministically by location (under `$HOME` → user tier; outside on a global install → shared) with an explicit `--local`/`--shared` override; no interactive prompt. The registry key renames from `repos:` to `projects:` (lazy migration — readers are key-agnostic, so old files keep working and are silently re-keyed on the next write). All user-facing strings that referred to a tracked directory as "repo"/"repos" now say "project"/"projects" (literal `git repository` retained).
- [NEW] Upgrade migration - upgrading the AID CLI now brings your existing repos up to the current layout. `aid update self` updates the CLI then scans your machine for AID repos and offers to migrate each (All/Yes/No/Cancel); `aid update [<tool>]` migrates just the current repo. Migration is idempotent and additive — it validates/repairs (or, for very old repos, creates) `.aid/settings.yml` while preserving your settings and comments, installs the per-repo dashboard page (`.aid/dashboard/home.html`), relocates any legacy KB summary to `.aid/dashboard/kb.html`, and registers the repo with the CLI. A repo you decline stays unregistered until you run `aid update` inside it. (The migration also runs lazily on the next `aid` command after an upgrade, so pip/pipx installs — which have no postinstall hook — are covered too.)
- [CHANGE] The per-repo dashboard page `.aid/dashboard/home.html` is now a vendored, install-provisioned file (single source `dashboard/home.html`) — so a freshly-added or migrated repo's dashboard works out of the box (previously the per-repo page existed only in the AID repo itself). Resolves the gap where a fresh repo's dashboard card showed "dashboard not generated yet".
- [NEW] /aid-ask - optional read-only skill that answers free-form project questions from the Knowledge Base, the codebase, and in-flight works, with source citations.
- [NEW] Task drill-down view - clicking a task in the dashboard pipeline view opens a Level-3 forensic panel for that task: its quick-check findings (severity + location + disposition), the delivery grade + reviewer tier + deferred-[HIGH] issues, a read-only escaped view of the source `STATE.md`, and an honest logs panel (states plainly that AID captures no per-task logs, and what to run instead). Lazy-loaded over the existing dashboard poll (`?detail=` query) — no new endpoint, no schema change.
- [NEW] Dashboard breadcrumb - a clickable 4-level breadcrumb (Main > Project > Pipeline > Task) in the dashboard top bar lets you walk back up the tree without the browser Back button.
- [CHANGE] /aid-execute now leads with the work argument (/aid-execute work-001 task-001), consistent with the other skills; the single-work shorthand still works.
- [NEW] AID dashboard CLI home - `aid dashboard` now serves a machine-level home page at `/` that lists every repo this CLI install manages (read live from each repo's `.aid/settings.yml`), with a click-through into each repo's own live dashboard. One read-only server (127.0.0.1, Python or Node) serves all repos via `/r/<id>/...`.
- [NEW] Repo registry - the CLI tracks the repos it manages in `$AID_HOME/registry.yml`; `aid add` registers the current repo (first tool) and `aid remove` unregisters it when the last tool is removed. Paths-only, atomic writes, never blocks the install/uninstall.
- [CHANGE] The per-repo dashboard page moved from `dashboard/index.html` to `<repo>/.aid/dashboard/home.html` (co-located with the KB summary); the machine/CLI panel moved off the per-repo page onto the new CLI home. `aid dashboard --remote` now exposes the CLI home (all registered repos) over the private tailnet.
- [CHANGE] The dashboard server + reader are now vendored into the npm and PyPI packages and installed under `$AID_HOME/dashboard/`, so `aid dashboard` runs from the install tree (previously it only ran from a repo checkout).
- [NEW] Live KB freshness card - the per-repo dashboard now shows a 5-state Knowledge Base card (No KB / Building / Preparing / Ready / Outdated) derived live by the reader; "Outdated" is detected when the repo's default branch has advanced past the baseline the KB was generated against, and prompts `/aid-housekeep` to refresh.
- [CHANGE] The KB summary moved from `.aid/knowledge/knowledge-summary.html` to `<repo>/.aid/dashboard/kb.html` (served by the dashboard at `/r/<id>/kb.html`); the "Ready"/"Outdated" KB card opens it.
- [CHANGE] /aid-discover now auto-runs /aid-summarize at the end (after KB approval) to generate the KB summary, and records the KB git baseline; /aid-housekeep re-stamps that baseline when it refreshes the KB. Both existing approval gates (discovery KB approval + summary visual approval) are unchanged.
- [NEW] /aid-config `kb_baseline` setting - records the branch + commit date the KB reflects (producer-written; powers the Outdated detection above).

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
