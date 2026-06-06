# Plan — AID Product Website (work-004-product-site)

> Strategy for delivering the AID methodology product website (Astro Starlight on GitHub
> Pages at `aid.casuloailabs.com`). Four standalone-functional deliveries, sequenced
> Must → Should → Could, with the live-on-domain milestone (AC1/AC2) and the first human
> visual gate (AC11) front-loaded into delivery-001.

## Dependency Graph (from feature SPECs)

`needs → enables`, distilled from each feature's *Technical Specification* and boundary tables:

| Feature | Needs (provider) | Enables (consumer) | Priority |
|---------|------------------|--------------------|----------|
| 001 site-foundation | — | everything (`site/`, theme, sidebar, content schema, component-override slots, astro-mermaid, Pagefind) | Must |
| 002 build-and-deploy | 001 (sets the `site`/`base` + sitemap TODO markers 001 left) | live deploy (AC1/AC2); `release-data.ts` accessor → 008, 009; `release:published` trigger | Must |
| 008 version-injection | 002 (`getAidVersion()` accessor) | 003, 004 (`<InstallCommand>` / `<VersionBadge>`) | Must |
| 003 home-and-get-started | 001, 008 | front-door content (FR3/FR4) | Must |
| 004 installation-guide | 001, 008 | install how-to (FR5) | Must |
| 005 content-migration | 001 | 006 (migrated concepts/reference pages) | Must |
| 006 concepts-and-reference | 001, 005 | concepts + reference sections (FR8/FR9) | Should |
| 009 releases-and-banner | 001, 002 (`getAllRelease`/`getLatestRelease` accessor + `release:published`) | Releases page + banner (FR10/FR16) | Should/Could |
| 010 feedback-and-issues | 001 (`reportIssue` schema field + `Footer` slot) | feedback path (FR14) | Should |
| 007 pipeline-and-maintainer-guides | 001 (006 referenced for cross-links only) | pipeline + maintainer guides (FR6/FR7) | Could |

## Deliverables

### delivery-001: Live, branded, deployable site shell on the custom domain

**What it delivers** — A polished, casulo-branded Starlight site that builds, deploys to
GitHub Pages, and is **reachable over HTTPS at `https://aid.casuloailabs.com`** (AC1, AC2).
Three-pane layout, top nav with all five sections, grouped sidebar, TOC, breadcrumbs,
GitHub + casuloailabs.com links, dark-default + working light toggle, Pagefind search, and
Mermaid rendering — all behind stub pages so every nav entry resolves with no broken links
(AC3, AC4, AC8). This is the milestone where the **first human visual gate (AC11)** is taken
on real chrome, and where the one-time DNS/Pages setup is performed. Standalone-functional:
a complete, navigable (if content-light) site is live.

**Features** — 001 (site-foundation), 002 (build-and-deploy)

**Depends on** — none (foundation)

**Priority** — Must

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 (CONFIGURE — scaffold) | — |
| task-002 (CONFIGURE — theme CSS) | task-001 |
| task-003 (CONFIGURE — astro.config) | task-002 |
| task-004 (IMPLEMENT — schema + stubs) | task-003 |
| task-005 (CONFIGURE — pages/SEO) | task-003 |
| task-006 (IMPLEMENT — fetch + accessor) | task-004 |
| task-007 (CONFIGURE — docs.yml workflow) | task-005, task-006 |
| task-008 (DOCUMENT — DNS/Pages runbook) | task-007 |
| task-009 (TEST — build/Lighthouse/a11y/mermaid) | task-007 |

| Can Be Done In Parallel |
|------------------------|
| task-004, task-005 |
| task-008, task-009 |

### delivery-002: Version-bound front door — home, get-started, and install

**What it delivers** — The adoption path an evaluator/new-adopter actually reads: the Home
landing (value prop, pipeline diagram, install one-liner, CTAs), the Get Started section
(Overview, Install chooser, "Your first work" walkthrough, "Lite path quickstart"), and the
full Installation guide (four channels with per-OS tabs, per-tool "add to project" tabs for
the five profiles, update/remove). Every version badge and install one-liner across the site
renders the **latest released version injected at build time** and never goes stale (AC13),
refreshing automatically on `release:published` (AC15 version/install portion). This
completes the **Must / first-deploy MVP** (FR3, FR4, FR5, FR15). Standalone-functional: the
site now carries a visitor from landing to a working install.

**Features** — 008 (version-injection), 003 (home-and-get-started), 004 (installation-guide)

**Depends on** — delivery-001 (008 needs 002's `getAidVersion()` accessor; 003/004 need the
foundation + 008's components)

**Priority** — Must

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-010 (IMPLEMENT — version.ts + components) | task-009 |
| task-011 (IMPLEMENT — home + get-started) | task-010 |
| task-012 (IMPLEMENT — installation.mdx) | task-010 |
| task-013 (TEST — version injection / AC13) | task-011, task-012 |

| Can Be Done In Parallel |
|------------------------|
| task-011, task-012 |

### delivery-003: Knowledge surfaces — migrated docs, concepts, reference, releases, feedback

**What it delivers** — The site's depth for returning users and evaluators: the existing
`docs/*.md` migrated faithfully into Starlight content with Mermaid intact and links
resolving (AC5, FR11); the **Concepts** section (full methodology, philosophy, KB, agent
model, lite vs full, FAQ) and the **Reference** section (CLI, settings keys, artifacts,
repository structure, glossary, plus the generated Skills/Agents/KB roster) (FR8, FR9, AC6);
the **Releases** page auto-populated from the GitHub Releases API with per-release offline
bundle asset links plus the dismissible **announcement banner** (FR10, FR16, AC9, AC14,
AC15 releases/banner portion); and the **feedback path** — per-page "Report an issue" +
dedicated feedback page opening prefilled GitHub issues with the issue-form template (FR14,
AC12). Standalone-functional: each surface stands alone, and all are independently testable
on the already-live site.

**Features** — 005 (content-migration), 006 (concepts-and-reference), 009 (releases-and-banner),
010 (feedback-and-issues)

**Depends on** — delivery-001 (foundation + deploy + release-data accessor for 009);
delivery-002 not required, but 006/009/010 add their keys to the same `components:` map and
share slugs that delivery-002 also links to (see Cross-Cutting Risk #1)

**Priority** — Mixed: **Must** for feature-005 (content-migration — pulled in here as the
prerequisite for feature-006's Concepts/Reference arrangement), **Should** for 006/009/010.
(All Must *deliverables* — 001, 002 — ship in deliveries 001-002; feature-005 is the one Must
*feature* sequenced here for its dependency, not a deferral of Must work.)

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-014 (IMPLEMENT — sync-docs.mjs) | task-009 |
| task-015 (TEST — migration / drift-check) | task-014 |
| task-016 (IMPLEMENT — gen-reference.mjs) | task-014 |
| task-017 (IMPLEMENT — concepts/reference IA + sidebar) | task-016 |
| task-018 (TEST — concepts/reference / drift-check) | task-017 |
| task-019 (IMPLEMENT — releases page + banner) | task-009 |
| task-020 (TEST — releases / banner dismissal) | task-019 |
| task-021 (CONFIGURE — issue template + labels) | task-009 |
| task-022 (IMPLEMENT — Footer override + feedback page) | task-021 |
| task-023 (TEST — feedback prefilled-issue) | task-022 |

> Note: task-014 → task-016 → task-017 → task-019 → task-022 each ADD a key to the single
> `astro.config.mjs` / shared maps (Cross-Cutting Risk #1) or share the committed-generated
> convention (Risk #3); execute the `astro.config.mjs`/`components:` edits in id order and verify
> all expected keys are present after the last edit.

| Can Be Done In Parallel |
|------------------------|
| task-019, task-021 (both depend only on task-009; disjoint from the 014→017 chain) |
| task-015, task-016 (both depend only on task-014; task-015's drift-check is scoped to sync-docs' four migrated pages + assets + sync manifest, disjoint from task-016's generated `reference/*` pages, so they share no file/state) |

### delivery-004: Task-oriented guides — pipeline & maintainer

**What it delivers** — The two hand-authored **Guides** pages that complete the site map's
Guides section: "Working the pipeline" (`aid-config` + the six numbered phases, deploy/monitor
as optional Deliver skills, per methodology v3.2) and "Maintainer" (cut a release from
`docs/release.md` + regenerate the host-tool trees/profiles) (FR6, FR7). This is the **Could**
band — depth that can start lean and deepen later. Standalone-functional: two self-contained
guides slotting into the Guides slugs the foundation already reserved.

**Features** — 007 (pipeline-and-maintainer-guides)

**Depends on** — delivery-001 (foundation/Guides slugs); cross-links to Concepts/Reference
(delivery-003) resolve once those ship — non-blocking, stub the anchors if 007 lands first

**Priority** — Could

#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-024 (IMPLEMENT — pipeline + maintainer guides) | task-009 |
| task-025 (TEST — links resolve / mermaid) | task-024 |

| Can Be Done In Parallel |
|------------------------|
| (none — sequential) |

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | **Single `components:` map in `site/astro.config.mjs`.** Features 008 (version-badge/`Hero` slot), 009 (`Banner`), and 010 (`Footer`) each register a Starlight component override by adding a key to the ONE `components:` map that feature-001 owns. Three features editing one config block (008 in delivery-002; 009 + 010 in delivery-003) risk merge collisions / clobbered keys. | Medium — a dropped key silently disables a banner/badge/Footer override without a build error. | feature-001 ships the map with all slots reserved + documented (per its boundary table); each consumer *adds* its key rather than rewriting the map; within a delivery, sequence the `astro.config.mjs` edits and verify all expected keys are present after the last edit. Detail (`/aid-detail`) assigns the map edits to distinct, ordered tasks. |
| 2 | **One-time DNS + Pages setup gates AC2 (live HTTPS domain).** The GoDaddy `aid` CNAME, the repo Pages custom-domain + `Source = GitHub Actions`, and Let's Encrypt HTTPS provisioning are manual, out-of-band, and can take ~24h — none automatable by the workflow. | High — delivery-001's AC2 (and the whole "live on domain" milestone) cannot be marked done until DNS/cert propagate. | feature-002 documents the exact one-time steps (add domain in GitHub *before* the DNS record; committed `public/CNAME` prevents wipe-on-deploy). Schedule the DNS change early in delivery-001 so propagation overlaps build work; treat AC1 (builds+deploys to Pages) as independently verifiable ahead of AC2 (custom domain) so the delivery is not fully blocked on cert timing. |
| 3 | **Two committed-generated + drift-checked generators.** feature-005 (`sync-docs.mjs`, docs/*.md → content) and feature-006 (`gen-reference.mjs`, canonical/ + settings.yml → reference) both commit generated output and add a `git diff --exit-code` CI drift check, mirroring the repo's canonical→profiles render-drift convention. | Medium — a stale commit or an un-run generator fails CI; the two generators must write to disjoint paths or they collide. | SPECs already define disjoint output paths and the shared sync+diff convention; both live in delivery-003, so sequence 005 before 006 (006 consumes 005's migrated pages) and run both generators + commit before pushing. `docs/install.md` is excluded from 005's manifest (owned hand-authored by 004/006) — confirmed, no slug collision. |

> No items deferred — all ten Ready features (001–010) are assigned to a delivery above.
