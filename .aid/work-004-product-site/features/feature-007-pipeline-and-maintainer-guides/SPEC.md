# Pipeline & Maintainer Guides

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | Feature identified from REQUIREMENTS.md §5 (FR6, FR7), §10 | /aid-interview |
| 2026-06-06 | Rescoped + renamed from feature-007-guides-and-releases: Releases (FR10) split out to feature-009-releases-and-banner. This feature is now pipeline + maintainer guides only (FR6, FR7). | /aid-interview (user request) |

## Source

- REQUIREMENTS.md §5 FR6, FR7 · §4 Scope · §3 Secondary audience

## Description

Task-oriented how-to guides for working AID and for maintaining it. The pipeline guide walks
the end-to-end flow — `aid-config` then the six numbered phases (Discover → Interview → Specify
→ Plan → Detail → Execute), with deploy/monitor as the optional **Deliver** skills (per
methodology v3.2) — so a competent user can drive the methodology with a goal in mind. The
maintainer guides cover "cut a release" (sourced from `docs/release.md`) and **regenerating the
host-tool trees/profiles** (the canonical render/generate workflow) for contributors to AID
itself. The Releases changelog page is not part of this feature — it is
owned by feature-009-releases-and-banner.

## User Stories

- As a new adopter, I want an end-to-end how-to for working the pipeline so that I can run a real piece of work from discovery through deploy.
- As a returning user, I want task-focused pipeline guides so that I can look up how to perform a specific phase.
- As a maintainer, I want a "cut a release" guide so that I can follow the release process reliably.
- As a maintainer, I want a guide for regenerating the host-tool trees/profiles (the canonical render/generate workflow) so that I can keep generated artifacts current.

## Priority

Could

## Acceptance Criteria

- [ ] Given the Guides section, when a visitor opens the pipeline guide, then it documents the end-to-end flow — `aid-config` + the six numbered phases (Discover → Execute) with deploy/monitor as optional Deliver skills (per methodology v3.2). (AC3 partial)
- [ ] Given the maintainer guides, when a maintainer opens "cut a release", then it reflects the content of `docs/release.md`.
- [ ] Given the maintainer guides, when a maintainer opens the trees/profiles regeneration guide, then the canonical render/generate workflow is documented.
- [ ] Given these guides, when migrated/derived content renders, then internal links resolve and any Mermaid diagrams render. (AC5 partial)

---

## Technical Specification

> Added by `/aid-specify`. Grounded in the real sources `docs/release.md` (369 lines), the
> canonical AID skills (`canonical/skills/aid-*`, methodology v3.2 phase set), and the
> maintainer-only generator (`.claude/skills/aid-generate/SKILL.md` + its renderers). Consumes
> the A+ provider contracts of feature-001 (site foundation / sidebar), feature-005 (sync-docs
> manifest), and feature-006 (Reference section); links to `concepts/methodology` (migrated by
> feature-005) for methodology depth.

### Overview & Approach

This feature ships **two hand-authored pages** under **Guides**, occupying the two explicit
sidebar slugs feature-001 reserved for feature-007 (`guides/pipeline`, `guides/maintainer`):

| Page file (`site/src/content/docs/`) | Slug | Sidebar label | Authored vs migrated |
|---|---|---|---|
| `guides/pipeline.mdx` | `guides/pipeline` | Working the pipeline | **Hand-authored** (.mdx) |
| `guides/maintainer.mdx` | `guides/maintainer` | Maintainer | **Hand-authored** (.mdx) — two H2 sections: "Cut a release" (*derived faithfully* from `docs/release.md`) + "Regenerate the host-tool trees/profiles" (D3) |

Both supersede feature-001's stub `.md` pages at the shared paths (feature-001 D8: Guides
uses explicit `slug:` items; the foundation ships stubs that real pages replace). Neither is added
to feature-005's `sync-docs.mjs` manifest — these are task-oriented guides with editorial IA and
cross-links, not faithful 1:1 transforms of a single source doc (D1, D2, justified below, exactly
mirroring feature-004's `guides/installation.mdx` precedent).

### Architectural Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | **`guides/pipeline` is HAND-AUTHORED `.mdx`, NOT added to feature-005's sync manifest.** Its prose draws on the real skill flow (`canonical/skills/`) and links to `concepts/methodology` for depth; there is no single `docs/` source doc to migrate. | The pipeline guide is *task-oriented* (drive a real piece of work, phase by phase), editorially distinct from the *explanation* in `concepts/methodology` (migrated by 005 from `docs/aid-methodology.md`). It needs Starlight MDX components (`<Steps>`, `<Tabs>`, `<Aside>`, `<CardGrid>`) and a Mermaid phase-flow diagram that the faithful `.md` transform (feature-005 D3) cannot produce. Auto-migration is impossible anyway — no source doc exists. This matches feature-004 D1 (own the guide as `.mdx`; `docs/` is *source* not *sync target*). |
| D2 | **"Cut a release" is HAND-AUTHORED into `guides/maintainer.mdx`, sourced *faithfully* from `docs/release.md`, NOT migrated via feature-005's manifest.** `docs/release.md` is the prose SOURCE that THIS feature consumes; per the reconciled contract, **feature-005 is amended to NOT include `docs/release.md` in its sync manifest** — it is a hand-authored source for feature-007, not a 005 migration target. The page reorganizes the source for the website IA and preserves every command, table, exit code, and recovery step (AC: "reflects the content of `docs/release.md`"). | This is the **install.md precedent applied to release.md**: feature-005 D1/D3 reserve the sync manifest for faithful single-page transforms whose body needs no Astro components and whose IA the consuming feature does not reshape; release.md fails both tests. It needs `<Steps>` for the numbered tag-push flow, `<Tabs syncKey="release-path">` to present the **CI path vs manual `release.sh` path** side-by-side (the source interleaves them), and `<Aside type="caution">` for the recovery/idempotency block. Migrating it 1:1 would lose that UX and force feature-005 to own maintainer IA. *Faithfulness* (the AC) is satisfied by content fidelity, not by the sync mechanism — same standard feature-004 meets for install.md. (Counter-considered: adding `docs/release.md` to 005's manifest as a plain `.md` page. Rejected — and feature-005 is being amended to exclude it: it would render as one flat wall mixing two release paths, with no tabbing, and would put a maintainer page under feature-005's ownership boundary — contradicting the FR7 scope that this feature owns the maintainer guides.) |
| D3 | **The maintainer area is ONE page** (`guides/maintainer.mdx`) with **two H2 sections**: "Cut a release" (from `docs/release.md`) and "Regenerate the host-tool trees/profiles" (from aid-generate). It occupies the single explicit `guides/maintainer` slug feature-001 reserved. | feature-001's Guides sidebar is an explicit `items:` slug array reserving exactly `guides/pipeline` + `guides/maintainer`; a third `guides/regenerate-trees` page would be orphaned (not in the array) without reopening feature-001's config. Rather than gate on that amendment, we adopt fallback (b): collapse the two maintainer runbooks into one page with two H2 sections. Both runbooks stay scannable via the on-this-page TOC and deep-linkable via H2 anchors; this honors the feature spec's "one page with sections or two pages" and AC3. No `sidebar.order`/`label` frontmatter beyond the reserved slug is needed (Guides is explicit, not autogenerate). |
| D4 | **Both pages are `.mdx`, not `.md`.** | Required to use Starlight components (`<Steps>`, `<Tabs>`, `<Aside>`, `<CardGrid>`/`<LinkCard>`) in body content (feature-005 D3 carves out exactly this: "pages that need MDX components … are authored separately as `.mdx`"). |
| D5 | **The pipeline guide names the REAL `/aid-*` skills per phase, read from `canonical/skills/`** (mapping table below), and presents them as the methodology v3.2 order: config → six numbered phases → optional Deliver skills. | AC3-partial + the feature description require the *actual* skill flow, not invented best practices. The phase→skill names are taken verbatim from the canonical `SKILL.md` frontmatter `name:` fields, so the guide cannot drift from the shipped commands. |
| D6 | **The regenerate-trees section is grounded 1:1 in `.claude/skills/aid-generate/SKILL.md` and its renderers**, documenting the LOAD → VALIDATE → RENDER → VERIFY → REPORT state machine, the `run_generator.py` entry point (which takes no argv), the **`/aid-generate` skill's `--tool` / `--dry-run` interface** (the skill, not the script, parses these), the five profiles, and the emission-manifest safety boundary. | AC: "the canonical render/generate workflow is documented." aid-generate is the maintainer-only skill that *is* this workflow; describing anything else would be inaccurate. The guide also states the render-drift CI convention (committed `profiles/` must match a fresh render) that ties this workflow to the release gate. |
| D7 | **Reference depth is LINKED, not duplicated** (feature-006 owns CLI / skills-agents-KB / settings / repo-structure / glossary). The pipeline guide links each phase to the **`/reference/skills` page root** (and `/reference/agents` root) — feature-006 ships `reference/skills` as a single table page with NO per-skill anchors, so links target the page, not per-entry fragments; the maintainer guide links to the CLI reference and repo-structure for command/flag depth. | Scope discipline + AC5 "internal links resolve." FR6/FR7 own the *how-to*; FR9/feature-006 owns the *reference*. Avoids two drifting copies of flag/exit-code tables (same boundary feature-004 D7 sets). |
| D8 | **Every cross-link targets a live Starlight route** (`/concepts/methodology`, `/reference/cli`, `/reference/skills`, `/reference/agents`, `/reference/repository-structure`, `/guides/installation`, `/releases/changelog`), never an anchor inside a `docs/` file or a non-migrated path. | AC5 "internal links resolve." `docs/release.md` is not a sync target (D2), so its in-doc `#anchors` are re-pointed at the new page's own H2 anchors or at Reference routes. |

### Phase → skill mapping (used by `guides/pipeline.mdx`, from `canonical/skills/`)

Methodology v3.2. Setup first, then the six numbered phases, then the optional **Deliver** skills:

| Order | Phase / step | Skill (command) | What the page tells the user to do |
|---|---|---|---|
| 0 | **Configure** | `/aid-config` | Scaffold/inspect `.aid/settings.yml`; set project name, review grade, etc. (run first). |
| 1 | **Discover** | `/aid-discover` | Brownfield only: analyze the repo to populate the Knowledge Base (GENERATE → REVIEW → … → DONE). Greenfield projects skip. |
| 2 | **Interview** | `/aid-interview` | Gather requirements conversationally → `REQUIREMENTS.md`, then decompose into feature files. |
| 3 | **Specify** | `/aid-specify` | Per-feature technical spec → `SPEC.md` (one feature at a time). |
| 4 | **Plan** | `/aid-plan` | Sequence feature SPECs into deliverables → `PLAN.md` (strategy). |
| 5 | **Detail** | `/aid-detail` | Break deliverables into typed tasks + execution graph → `task-NNN.md` (tactics). |
| 6 | **Execute** | `/aid-execute` | Execute one typed task with built-in review loop, on a per-delivery branch. |
| — | **Deliver (optional): deploy** | `/aid-deploy` | Package completed deliveries into a release. |
| — | **Deliver (optional): monitor** | `/aid-monitor` | Observe production, classify findings, route bugs/changes back to `/aid-interview`. |

(Adjacent skills `/aid-summarize` and `/aid-housekeep` exist in `canonical/skills/` but are
cross-cutting maintenance, not pipeline phases; the guide may mention them in passing under
"supporting skills" but does not number them. The guide links each phase to the `/reference/skills`
page root (and `/reference/agents` root) for depth — feature-006 has no per-entry anchors, D7.)

### Page structure — `guides/pipeline.mdx`

Frontmatter:

```yaml
---
title: Working the pipeline
description: An end-to-end, task-oriented walkthrough of running a real piece of work through AID — aid-config plus the six numbered phases (Discover → Execute) and the optional Deliver skills.
---
# Note: no `sidebar.order` — the Guides group uses feature-001's explicit `items:` array,
# which sets order (Installation → Working the pipeline → Maintainer); per-page sidebar.order
# would be inert here.
import { Steps, Tabs, TabItem, Aside, CardGrid, LinkCard } from '@astrojs/starlight/components';
```

Section outline (H2 unless noted):

1. **Before you start** — links to `/guides/installation` (install + add to project) and a one-line
   pointer to `/concepts/methodology` for the *why*. States this page is the *how*.
2. **The pipeline at a glance** — a `mermaid` flow diagram (```mermaid fence; rendered by feature-001's
   `astro-mermaid`) showing config → Discover → Interview → Specify → Plan → Detail → Execute →
   (Deliver: deploy → monitor → loop back to Interview). AC5 (Mermaid renders).
3. **Step 0 — Configure (`/aid-config`)** — scaffold settings; `<Steps>`.
4. **The six phases** — one H3 per phase (Discover … Execute) following the mapping table above; each
   H3 names the `/aid-*` command, the artifact it produces, and a `<LinkCard>` to the `/reference/skills`
   page root (feature-006 ships it as a single table page with no per-skill anchors; deep-link the page, not
   a fragment). Greenfield-vs-brownfield note (`<Aside>`) on whether to run Discover.
5. **Delivering: deploy & monitor (optional)** — the two Deliver skills and the feedback loop back to
   Interview.
6. **Lite vs full path** — short note + link to the Get-Started Lite-path quickstart (feature-003) and
   `/concepts/methodology` (lite vs full). No duplication (D7).
7. **Next steps** — `<CardGrid>` of `<LinkCard>`s to Reference and the Maintainer guide (`/guides/maintainer`).

### Page structure — `guides/maintainer.mdx` ("Cut a release" + "Regenerate trees", D2/D3/D6)

One page, two top-level H2 runbooks. No `sidebar.order`/`label` frontmatter — Guides is an explicit
`items:` sidebar in feature-001, so the reserved `guides/maintainer` slug is all that's needed.

Frontmatter:

```yaml
---
title: Maintainer
description: Runbooks for contributing to AID itself — cutting a release and regenerating the host-tool install trees.
---
import { Steps, Tabs, TabItem, Aside, CardGrid, LinkCard } from '@astrojs/starlight/components';
```

Section outline:

1. **Who this is for** — secondary audience (maintainers/contributors); `<CardGrid>` linking the two
   on-page runbooks (Cut a release → `#cut-a-release` H2; Regenerate trees → `#regenerate-the-host-tool-treesprofiles` H2).

**H2 — Cut a release** (D2; faithful to `docs/release.md`):

2. **How releases work** — faithful to `docs/release.md` "How releases work": one pushed `v*` tag →
   `release.yml` (gate → GitHub Release → npm → PyPI); all four channels from one run. Optional
   `mermaid` sequence of the workflow jobs (AC5).
3. **Prerequisites** — `VERSION` set + agreeing across `package.json`/`pyproject.toml` (FR10 version-sync
   gate), clean green CI on master, render-drift clean (links to the on-page "Regenerate trees" H2), no
   existing tag, `gh` authenticated.
4. **Primary path (tag-triggered CI)** — `<Steps>`: verify preconditions →
   optional dry run (`workflow_dispatch` `dry_run=true`) → push the `v$(cat VERSION)` tag → `gh run watch`.
   Commands reproduced verbatim from `docs/release.md` Steps 1–4.
5. **Manual path (`release.sh`)** — the fallback runbook: `--dry-run` / `--draft` /
   publish; inspect staged artifacts; create + publish a draft. Presented in a `<Tabs syncKey="release-path">`
   alongside the CI path where the source interleaves them.
6. **What a release produces** — the five per-profile tarballs, `aid-cli` bundle, two install-core lib
   files, `SHA256SUMS`; npm + PyPI packages. Faithful to the source's asset list (cross-checks feature-004's
   offline-bundle naming and feature-009's Releases-asset list — links, no duplication).
7. **Recovery & idempotency** — `<Aside type="caution">` reproducing the source's recovery steps
   (failed mid-publish, tag-exists-no-release, staging cleanup).
8. **Flag & exit-code reference (`release.sh`)** — the two tables verbatim from `docs/release.md`.

**H2 — Regenerate the host-tool trees/profiles** (D6; grounded in `.claude/skills/aid-generate/SKILL.md`):

9. **When to run** — any time a canonical skill/agent/template is edited, before committing install-tree
   changes; the render-drift CI convention (committed `profiles/` must match a fresh render — the same
   gate `release.yml` enforces; cross-references the "Cut a release" prerequisites above).
10. **What it does** — canonical (`canonical/`) + per-tool profiles (`profiles/*.toml`) → the five install
   trees (claude-code, codex, cursor, copilot-cli, antigravity). The emission-manifest safety boundary
   (only generator-emitted files are touched). Optional `mermaid` of LOAD → VALIDATE → RENDER → VERIFY → REPORT.
11. **Prerequisites** — Python 3.11+ (tomllib), a git working tree, at least one profile TOML.
12. **Regenerate all trees** — `<Steps>`: run the generator and assert no drift:
   `python .claude/skills/aid-generate/scripts/run_generator.py && git diff --exit-code -- profiles/`.
13. **Regenerate one tree / dry-run** — the **`/aid-generate` skill's `--tool <name>` and `--dry-run`
   interface** (render to scratch + diff). These flags are parsed by the skill, not by `run_generator.py`
   (which takes no argv).
14. **Verify & report** — the deterministic (hard-gate) and advisory verify steps and the REPORT summary;
   confirm `git diff --stat` shows only install-tree paths.
15. **See also** — `<LinkCard>` to `/reference/repository-structure`.

> Memory note: the guide instructs maintainers to run the **full** `run_generator.py`, not per-script
> renderers, so emission manifests don't go stale and render-drift CI passes (matches this repo's
> documented maintainer practice).

### Content provenance (authored vs migrated)

- **Authored (net-new, this feature):** both `.mdx` pages. The pipeline guide is original
  task-oriented prose grounded in `canonical/skills/`. The maintainer page's two H2 sections are
  **derived** (faithful reorganizations) — "Cut a release" from `docs/release.md`, "Regenerate trees" from
  `.claude/skills/aid-generate/SKILL.md`.
- **Migrated by feature-005 (NOT this feature):** `concepts/methodology`, `concepts/faq`,
  `reference/repository-structure`, `reference/glossary` — linked, never duplicated here.
- **Owned by other features (linked):** `/guides/installation` (004), all `/reference/*` depth (006),
  `/releases/changelog` (009).

### Acceptance-criteria mapping

- **AC3 (partial) — pages exist + navigable:** two `.mdx` pages at `guides/pipeline` and
  `guides/maintainer`, occupying feature-001's two reserved explicit Guides slugs (no extra slugs needed, D3).
- **"Pipeline documents the v3.2 flow":** the phase→skill mapping table + section 4 of the pipeline page.
- **"Cut a release reflects `docs/release.md`":** the maintainer page's "Cut a release" H2 (D2) — faithful
  derivation; every command/table/exit-code/recovery step reproduced.
- **"Trees/profiles regeneration documented":** the maintainer page's "Regenerate trees" H2 (D6) grounded in aid-generate.
- **AC5 (partial) — links resolve + Mermaid renders:** D8 link discipline (live routes only); Mermaid via
  ```mermaid fences rendered by feature-001's `astro-mermaid` (D6 of feature-001), on the pages/sections that use them.

### Assumptions to spot-check

- **A1 (RESOLVED — page count fixed):** feature-001's Guides sidebar is an explicit `items:` slug array
  reserving only `guides/pipeline` + `guides/maintainer`. We adopt D3 fallback (b): the maintainer area is
  a single `guides/maintainer.mdx` with two H2 sections. No `astro.config.mjs` amendment and no third slug
  are required, so this is no longer a gating spot-check.
- **A2:** the exact Starlight component import path/depth from `content/docs/guides/`
  (`@astrojs/starlight/components`) and that `<Tabs syncKey>` + `<Steps>` are available in the pinned
  Starlight version feature-001 ships.
- **A3:** Reference route slugs assumed for links — `/reference/cli`, `/reference/repository-structure`,
  `/reference/skills`, `/reference/agents`. feature-006 ships `reference/skills` as a single table page with
  NO per-skill anchors, so per-phase links target the page root, not a fragment (D7). Confirm against
  feature-006's final page slugs before wiring `<LinkCard>` hrefs (AC5).
- **A4:** `docs/release.md` remains accurate to the shipped `release.yml` / `release.sh` at build time
  (the guide is derived, not the source of truth for the scripts).
- **A5:** the generator entry point stays `.claude/skills/aid-generate/scripts/run_generator.py` (no argv;
  `--tool`/`--dry-run` are the `/aid-generate` skill interface, not script flags) and the five profiles
  remain claude-code/codex/cursor/copilot-cli/antigravity.
