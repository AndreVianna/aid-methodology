# Home & Get Started

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | Feature identified from REQUIREMENTS.md §5 (FR3, FR4), §3, §10 | /aid-interview |
| 2026-06-06 | Revised: the home install one-liner consumes the build-time-injected current version (FR15, owned by feature-008-version-injection); version is no longer hard-coded. | /aid-interview (user request) |

## Source

- REQUIREMENTS.md §5 FR3, FR4 (consumes FR15) · §4 Scope · §3 Users

## Description

The site's front door. The Home / landing page communicates the AID value proposition,
renders the pipeline diagram, shows the primary install one-liner, and presents primary CTAs
(Get Started, GitHub). The Get Started section carries an evaluator from "what is AID" through
installation into running their first work: an overview / "What is AID", an Install AID entry
point, a new "Your first work" guided walkthrough, and a new "Lite path quickstart" for small
changes. The home install one-liner does not hard-code a version — it renders the latest
released version injected at build time (feature-008) so it never goes stale.

## User Stories

- As an evaluator, I want to grasp what AID is and why it exists within seconds of landing so that I can decide whether it is worth my time.
- As an evaluator, I want a single visible install one-liner and clear CTAs so that I can move from interest to action without hunting.
- As a new adopter, I want a guided "Your first work" walkthrough so that I can go from installed to running my first work with minimal friction.
- As a new adopter, I want a Lite path quickstart so that I can make a small change fast without learning the full pipeline.
- As a returning user, I want the home install one-liner to always reflect the current release so that copied commands are never stale.

## Priority

Must

## Acceptance Criteria

- [ ] Given the Home page, when a visitor loads it, then it shows the value proposition, the pipeline diagram, the install one-liner, and CTAs to Get Started and GitHub. (AC3 partial)
- [ ] Given the Get Started section, when a visitor navigates it, then Overview / "What is AID", Install AID, "Your first work" walkthrough, and "Lite path quickstart" all exist. (AC6 partial)
- [ ] Given the "Your first work" walkthrough and "Lite path quickstart", when a visitor reads them, then they are present as new content (not migrated). (AC6)
- [ ] Given a build, when the Home page renders, then its install one-liner shows the latest released version injected at build time, matching the `VERSION` file / latest GitHub Release. (AC13 partial)
- [ ] Given the pipeline diagram on Home, when the page is built, then the diagram renders correctly. (AC5)

---

## Technical Specification

### Overview & Approach

This feature delivers the site's **front door content**: the Home / landing page (FR3) and the
**Get Started** section (FR4). It is a pure **content + light-MDX** feature on top of the
`site/` Astro + Starlight project stood up by **feature-001** and the version-injection layer
provided by **feature-008**. It writes no new components, no theme tokens, no build/deploy
config, and no version logic — those are owned by siblings and **consumed** here.

Scope is exactly six pages under `site/src/content/docs/`:

| Page | File | Type | Net-new vs linked |
|------|------|------|-------------------|
| Home | `index.mdx` | splash + MDX | **Net-new content** (enriches feature-001's hero stub) |
| Get Started · Overview | `get-started/overview.md` | Markdown | **Net-new** thin page; links into Concepts |
| Get Started · Install | `get-started/install.md` | Markdown | **Net-new** thin chooser; links into `guides/installation` |
| Get Started · Your first work | `get-started/first-work.mdx` | MDX | **Net-new content** (AC6) |
| Get Started · Lite path quickstart | `get-started/lite-path.mdx` | MDX | **Net-new content** (AC6) |

`index.mdx` already exists as a feature-001 hero **stub**; this feature replaces its body.
The four `get-started/*` pages: `overview` exists as a feature-001 **placeholder** (replaced
here); the other three are created here. No content is migrated by this feature — the only
existing-doc dependency is **reuse of the methodology pipeline Mermaid diagram** on Home (see
*Home: pipeline diagram*), which is duplicated as a fence, not imported.

### Architectural Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | Home is `template: splash` with a `hero` frontmatter block; pipeline diagram + install one-liner + section cards live in the MDX **body below the hero** | feature-001 D-A3 reserved splash for Home; splash suppresses the sidebar/TOC for a landing feel; CTAs belong in `hero.actions`. |
| D2 | The home install one-liner is rendered by `<InstallCommand channel="curl" />` and the version pill by `<VersionBadge />` — **both imported from feature-008**, never hard-coded | FR15 / AC13: single source of truth for version; feature-008 is the sole owner (D77/D78 of that spec). |
| D3 | The pipeline diagram on Home is a hand-placed ` ```mermaid ` **fence** reusing the methodology flowchart, **not** an import of `concepts/methodology` | feature-001 D6 renders fences client-side via `astro-mermaid`; MDX cannot transclude another page's fenced block. Duplication is one diagram; Home links to the methodology page for the canonical copy. |
| D4 | Section cards use Starlight's `<CardGrid>` / `<LinkCard>` from `@astrojs/starlight/components` | Built-in, themed by casulo tokens, zero new components; gives Home its "section launcher" affordance (AC3 navigability). |
| D5 | `get-started/install.md` is a **chooser/stub that links into** feature-004's `guides/installation`, not a second install page | Avoids duplicating install content / drift (REQUIREMENTS §7 content-reuse); Get Started stays a learning path, Guides holds the reference how-to. |
| D6 | The Get Started group is `{ label: 'Get Started', autogenerate: { directory: 'get-started' } }` in feature-001's config; this feature adds pages purely by dropping them in `get-started/` with per-page `sidebar.order` (+ optional `sidebar.label`) — it does **not** edit feature-001's sidebar items array | feature-001 owns an `autogenerate` Get Started group; autogenerate is the single sidebar mechanism, so sibling features extend the section by adding files + ordering frontmatter, with zero cross-feature config edits. |
| D7 | All version-free pages stay `.md`; only pages that embed a component or a Mermaid fence are `.mdx` | Minimal-JS NFR / Lighthouse ≥ 90 (feature-001 D6): MDX/JS only where a component or diagram requires it. |

### Page Specs

#### Home — `site/src/content/docs/index.mdx`

**Frontmatter:**

```yaml
---
title: AID — Agentic Iterative Development
description: A methodology and toolchain that carries an idea from discovery to delivery with AI agents — grounded in real understanding, with the human in control at every gate.
template: splash
hero:
  tagline: From "never heard of it" to "installed and running your first work" — a disciplined, AI-agent pipeline with the human in control at every gate.
  image:
    file: ../../assets/aid-hero.svg   # optional; omit if feature-001 ships no hero asset (see A1)
  actions:
    - text: Get Started
      link: /get-started/overview/
      icon: right-arrow
      variant: primary
    - text: View on GitHub
      link: https://github.com/AndreVianna/aid-methodology
      icon: external
      variant: minimal
---
```

`title` doubles as the hero headline (Starlight uses `hero.title`, defaulting to `title`).
The CTA links honor AC3-Home: **Get Started → `/get-started/overview/`** and **GitHub → repo**.

**Body (below the hero), in order:**

1. **Value proposition** — 2–3 short paragraphs / a one-line "why AID" lede, grounded in
   REQUIREMENTS §1–§2 and `docs/aid-methodology.md` (understanding precedes specification;
   human-gated pipeline; lite path for small work). No version strings.
2. **Pipeline diagram** — a ` ```mermaid ` fence reusing the methodology flowchart
   (`docs/aid-methodology.md` §1, the `flowchart TB` with the five groups Prepare → Define →
   Map → Execute → Deliver). Honors **AC5**. A sentence below links to
   **`/concepts/methodology/`** as the canonical, fuller treatment (feature-005 target).
   (See *Home: pipeline diagram* for the duplication contract.)
3. **Primary install one-liner** — a short "Install in one line" heading, then:

   ```mdx
   import InstallCommand from '../../components/InstallCommand.astro';
   import VersionBadge from '../../components/VersionBadge.astro';

   <p>Current release: <VersionBadge href="/releases/changelog/" /></p>
   <InstallCommand channel="curl" />
   ```

   Honors **AC13-partial** (the badge + curl one-liner render the build-time version) and the
   FR3 "install one-liner" requirement. The badge links to the Releases page (feature-009's
   `releases/changelog` slug per feature-001 sidebar). A one-line "see all install channels"
   link points to **`/guides/installation/`** (feature-004).
4. **Section cards** — a `<CardGrid>` of `<LinkCard>`s, one per section, as a launcher:

   ```mdx
   import { CardGrid, LinkCard } from '@astrojs/starlight/components';

   <CardGrid>
     <LinkCard title="Get Started" href="/get-started/overview/" description="What AID is, install it, run your first work." />
     <LinkCard title="Guides" href="/guides/installation/" description="Installation across every channel and the full pipeline how-to." />
     <LinkCard title="Concepts" href="/concepts/methodology/" description="The methodology, phases, philosophy, and FAQ." />
     <LinkCard title="Reference" href="/reference/overview/" description="CLI, repository structure, settings, and glossary." />
     <LinkCard title="Releases" href="/releases/changelog/" description="Every release, with offline bundle assets." />
   </CardGrid>
   ```

   Card hrefs reuse feature-001's sidebar slugs so they resolve to real placeholder/real pages.

**Import paths:** `index.mdx` lives at `src/content/docs/index.mdx`; `src/components/` is two
levels up (`docs/` → `content/` → `src/`), so the path is `../../components/InstallCommand.astro`
(two `..`), as used in the sample above. Get-started pages at `src/content/docs/get-started/`
sit one level deeper and use `../../../components/…` (three `..`). (Spot-check A2 — relative
depth confirmed against the final tree at build.)

#### Get Started · Overview — `get-started/overview.md`

```yaml
---
title: What is AID?
description: A two-minute orientation to Agentic Iterative Development — what it is, who it's for, and how the pipeline works.
sidebar:
  label: Overview
  order: 1
---
```

Net-new thin orientation page (the evaluator's "what is AID" entry, REQUIREMENTS user story).
Summarizes the value prop and the six-phase pipeline in prose, then **links to
`/concepts/methodology/`** (feature-005) for depth and to **`/get-started/install/`** and
**`/get-started/first-work/`** as next steps. No diagram needed (Home carries it); `.md` (no
components, no version) keeps it JS-free.

#### Get Started · Install — `get-started/install.md`

```yaml
---
title: Install AID
description: Choose your install channel and follow the full instructions in the Installation guide.
sidebar:
  order: 2
---
```

A **channel chooser** (D5): one line of intro plus a short list/table of the four channels
(curl/irm, npm, PyPI, offline) each **linking into the corresponding section of
`/guides/installation/`** (feature-004 owns the commands + per-tool tabs). It contains **no
install commands itself** (no version, so `.md`) — it routes the learner from the Get Started
path into the Guides reference. Honors AC3-nav (Install AID present in Get Started).

#### Get Started · Your first work — `get-started/first-work.mdx` (NET-NEW, AC6)

```yaml
---
title: Your first work
description: A guided walkthrough from configuring AID to running your first full work through the pipeline.
sidebar:
  order: 3
---
```

New guided walkthrough (AC6). Structure: **(1) Configure** — run `aid-config` once to scaffold
`.aid/` (per `docs/aid-methodology.md` skill table); **(2) Start the work** — `aid-interview`
TRIAGE routes full vs lite; **(3) Walk the phases** — Specify → Plan → Detail → Execute, each
human-gated; **(4) What you get** at each gate. Uses an ordered step list (Starlight `<Steps>`
from `@astrojs/starlight/components`, hence `.mdx`). Cross-links: install step →
`/get-started/install/`; pipeline depth → `/concepts/methodology/` and `/guides/installation/`;
small-change alternative → `/get-started/lite-path/`. **No version strings, no hardcoded
commands beyond skill invocations** (which are version-independent).

#### Get Started · Lite path quickstart — `get-started/lite-path.mdx` (NET-NEW, AC6)

```yaml
---
title: Lite path quickstart
description: Make a small change fast — the lite path skips the full pipeline for low-risk work.
sidebar:
  order: 4
---
```

New quickstart (AC6) for small changes. Explains that `aid-interview`'s **TRIAGE** auto-routes
small/low-risk work to the lite path (grounded in `docs/aid-methodology.md` §"lite vs full"),
then gives the minimal flow as `<Steps>`. Contrasts with the full walkthrough and links back to
`/get-started/first-work/` for full-path work and `/concepts/methodology/` for the rationale.
`.mdx` for the `<Steps>` component; no version strings.

### Home: pipeline diagram (reuse contract)

The Home diagram is a **copy** of the `flowchart TB` block in `docs/aid-methodology.md` §1,
placed as a ` ```mermaid ` fence in `index.mdx`. Rationale (D3): MDX has no mechanism to
transclude another page's fenced code block, and feature-001's `astro-mermaid` renders fences
client-side per page. To bound drift: Home links to `/concepts/methodology/` as the canonical
source, and the fence is the **only** Mermaid duplication this feature introduces.

The reused fence renders via feature-001's `astro-mermaid` integration (D6 of feature-001), which
configures astro-mermaid with `theme: 'dark'` only. **A3 — resolved:** the Home copy **drops the
source diagram's hardcoded GitHub `classDef fill:` colors** (e.g. `#1E3A8A`) and instead inherits
astro-mermaid's themed palette, so the nodes are legible against the dark theme without authoring a
parallel color set. Light-mode Mermaid theming is a feature-001 concern (no light-mode Mermaid
palette exists to inherit today); if a light Mermaid theme is ever added, it belongs in
feature-001's astro-mermaid config, not in this fence.

### Navigation / Sidebar

feature-001's Get Started group is `{ label: 'Get Started', autogenerate: { directory: 'get-started' } }`
— **autogenerate is the single sidebar mechanism**. This feature populates the section purely by
adding pages under `get-started/`; each page declares its own `sidebar.order` so the group renders
in the intended sequence (1 overview → 2 install → 3 first-work → 4 lite-path), and the overview
page sets `sidebar.label: 'Overview'` so autogenerate shows "Overview". This feature does **not**
edit feature-001's `astro.config.mjs` — no sidebar items array exists to edit, and ordering/labels
are owned entirely by per-page frontmatter.

The Home splash is the `/` route (feature-001) and is not a sidebar item. Top-nav,
breadcrumbs, TOC, and search are all inherited from feature-001 (AC3) — unchanged here.

### Consumed Contracts (do not redefine)

| Contract | Owner | Used by this feature |
|----------|-------|----------------------|
| `<InstallCommand channel="curl" />` | feature-008 | Home install one-liner |
| `<VersionBadge href? prefix? />` | feature-008 | Home version pill (`href="/releases/changelog/"`) |
| `index.mdx` splash + `hero` frontmatter; `docs` collection + `docsSchema` | feature-001 | Home template + all page frontmatter |
| `astro-mermaid` fence rendering; casulo theme; `<CardGrid>`/`<LinkCard>`/`<Steps>` | feature-001 / Starlight | Home diagram, section cards, walkthrough steps |
| `concepts/methodology` slug | feature-005 | Home + overview + first-work + lite-path links |
| `guides/installation` slug | feature-004 | `get-started/install` chooser + Home "all channels" link |
| `releases/changelog` slug | feature-009 (feature-001 stub) | VersionBadge href + Releases card |
| `reference/overview` slug | feature-007 (feature-001 stub) | Reference card |

### File / Directory Tree (additions/edits under `site/`)

```
site/src/content/docs/
├── index.mdx                       # REPLACE feature-001 hero stub: hero + body (FR3)  [THIS FEATURE]
└── get-started/
    ├── overview.md                 # REPLACE feature-001 placeholder (FR4)             [THIS FEATURE]
    ├── install.md                  # NEW chooser → guides/installation                 [THIS FEATURE]
    ├── first-work.mdx              # NEW guided walkthrough (AC6)                        [THIS FEATURE]
    └── lite-path.mdx               # NEW lite quickstart (AC6)                          [THIS FEATURE]
```

No `site/astro.config.mjs` edit: feature-001's Get Started group is `autogenerate`, so these
files appear in the sidebar automatically, ordered/labelled by their own frontmatter.

### Acceptance Criteria Coverage

| AC | How this feature satisfies it |
|----|-------------------------------|
| AC3 (Home) | `index.mdx` splash: hero with value prop + Get Started/GitHub CTAs, pipeline Mermaid fence, `<InstallCommand channel="curl" />` one-liner, section `<CardGrid>`. |
| AC3 (nav) | Four Get Started pages exist with `sidebar.order` (overview also `sidebar.label: 'Overview'`); feature-001's `autogenerate` group renders them in order; Overview, Install AID, Your first work, Lite path quickstart all navigable. |
| AC5 | Home pipeline diagram is a ` ```mermaid ` fence rendered by feature-001's `astro-mermaid` (verified legible per A3). |
| AC6 | `get-started/first-work.mdx` and `get-started/lite-path.mdx` are net-new content (not migrated). |
| AC13 (partial) | Home install one-liner + version pill render via feature-008's `<InstallCommand>` / `<VersionBadge>` — build-time version, no hardcoding. |

### Assumptions & Open Questions

- **A1 (hero image):** the `hero.image` field is optional; include it only if feature-001
  ships a hero/splash asset (e.g. `site/src/assets/aid-hero.svg`). If none exists, omit
  `hero.image` — splash renders text-only cleanly. Spot-check feature-001's `public/`/`assets/`.
- **A2 (import depth):** component import paths depend on each page's directory depth
  (`index.mdx` → `../../components/…`; `get-started/*.mdx` → `../../../components/…`). Confirm
  against the built tree; an `astro:build` failure surfaces any mismatch immediately.
- **A3 (Mermaid theming) — resolved:** the Home copy drops the source diagram's hardcoded
  `classDef fill:` colors and inherits astro-mermaid's `theme: 'dark'` palette (legible on the
  dark theme, AC5). Light-mode Mermaid theming, if ever needed, is a feature-001 config concern.
- **A4 (sidebar) — resolved:** feature-001's Get Started group is `autogenerate`, so this feature
  adds pages with per-page `sidebar.order` (+ `sidebar.label`) and makes **no** edit to
  feature-001's `astro.config.mjs`. No cross-feature config coordination is required.
- **A5 (slug stability):** Home/overview links to `concepts/methodology` (feature-005),
  `guides/installation` (feature-004), `releases/changelog` + `reference/overview` (stubs).
  These slugs come from feature-001's sidebar skeleton; if a provider renames a slug, update
  the links here. CI internal-link checking (feature-001 NFR) will flag any breakage.
