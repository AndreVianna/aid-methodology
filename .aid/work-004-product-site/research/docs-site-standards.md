# Research: Building a Product-Documentation Website for AID

Research feeding a requirements spec for a GitHub-Pages-hosted, low-maintenance docs site
that reuses existing repo Markdown and presents a Mintlify-style three-pane developer-docs UX,
served under `casuloailabs.com`.

---

## 1. The IA standard — Diátaxis (and corroborating authority)

**Diátaxis** (https://diataxis.fr, https://diataxis.fr/start-here/) is the dominant modern
framework for organizing technical documentation. It splits all docs into **four modes**, on two
axes (action vs. cognition; acquiring skill vs. applying skill):

| Mode | Orientation | User is… | Answers | AID examples |
|------|-------------|----------|---------|--------------|
| **Tutorials** | Learning-oriented (study + action) | a beginner being taught | "teach me by doing" | Getting-started walkthrough; "run the pipeline on a sample repo" |
| **How-to guides** | Task-oriented (work + action) | a competent user with a goal | "how do I X?" | Install via npm / PyPI / offline; add AID to a Cursor project; cut a release |
| **Reference** | Information-oriented (work + cognition) | working, needs facts | "what are the exact facts?" | CLI/subcommand reference; agent roster; KB document catalog; settings keys; glossary |
| **Explanation** | Understanding-oriented (study + cognition) | studying, wants context | "why / how does it work?" | The methodology (philosophy, pipeline, Iron-Man model); "how it works"; FAQ |

Key principle: **do not mix modes on one page.** A tutorial that drifts into reference, or a
how-to that explains theory, serves neither reader. Diátaxis is *iterative*: you place each page
in its quadrant and refine, rather than designing the whole tree up front.

Corroborating authorities:
- Tom Johnson, *I'd Rather Be Writing* — widely-read API-docs authority, treats Diátaxis as the
  reference model: https://idratherbewriting.com/blog/what-is-diataxis-documentation-framework
- BSSW (Better Scientific Software): https://bssw.io/items/diataxis-a-systematic-approach-to-technical-documentation-authoring
- Adopted by Gatsby, Cloudflare, Canonical/Ubuntu, Django, and others.

**Mapping note for AID:** AID's existing docs already cluster cleanly: `aid-methodology.md` =
Explanation; `install.md` + `release.md` = How-to; `glossary.md` + `repository-structure.md` =
Reference; `faq.md` = Explanation (with some how-to). The missing quadrant is **Tutorials**
(a guided getting-started), which the new site must add.

Sources: https://diataxis.fr · https://diataxis.fr/start-here/ ·
https://idratherbewriting.com/blog/what-is-diataxis-documentation-framework ·
https://bssw.io/items/diataxis-a-systematic-approach-to-technical-documentation-authoring

---

## 2. The layout pattern — three-pane developer docs

The "Mintlify / Claude-docs" look is a well-established **three-pane** (sometimes called
"holy grail" docs) layout. It is produced by essentially every modern docs theme out of the box
(Starlight, Docusaurus, MkDocs Material, VitePress, Mintlify, Nextra), so it is **not** a reason
to pick one tool over another — all of them give it for free.

Anatomy:
- **Top bar (global):** logo, **section tabs** (top-level nav buckets), **global search**
  (Cmd/Ctrl-K), version/theme switch, GitHub/social links, optional CTA.
- **Left pane:** grouped, collapsible **sidebar** scoped to the current section/tab. Multi-level,
  accordion expand/collapse, active-item highlighting, off-canvas/toggle on mobile.
- **Center pane:** **breadcrumbs**, page title, body. Modern themes add a "copy page / view as
  Markdown / open in LLM" affordance, **tabbed code blocks** (per-OS or per-language/environment),
  callout/admonition components, prev/next pager.
- **Right pane:** **"On this page" TOC** built from the page's headings, sticky, with
  scroll-spy active-state; collapses on narrow viewports.

(General layout pattern references: Vanilla Framework docs layout
https://vanillaframework.io/docs/layouts/documentation ; sticky-TOC scroll-spy technique
https://css-tricks.com/sticky-table-of-contents-with-scrolling-active-states/ .)

**Conventional top-level nav buckets** on leading developer-docs sites — the recurring vocabulary
is some subset of:

- **Get started / Overview** (intro + quickstart)
- **Guides** (how-to / tasks; sometimes "Develop", "Build")
- **Concepts / Learn** (explanation)
- **Reference / API** (facts, CLI, config)
- **Releases / Changelog**
- (often) **Resources / Community / Examples**

Anthropic/Claude docs (Mintlify) use tabs like *Guides / API reference / Resources / Release notes*.
Stripe, Vercel, Tailwind, and Astro all follow the same Get-started → Guides → Reference → Changelog
spine. This vocabulary maps almost 1:1 onto Diátaxis (Get-started=Tutorial, Guides=How-to,
Concepts=Explanation, Reference=Reference).

---

## 3. Tooling comparison (deploy to GitHub Pages, consume existing Markdown)

### Cross-cutting facts
- **GitHub Pages + Actions:** Every JS/Python generator here (Docusaurus, Starlight, MkDocs
  Material, VitePress) deploys to GH Pages **via a GitHub Actions workflow** (build → upload
  artifact → `actions/deploy-pages`). Only **Jekyll** can be built **natively** by GH Pages with
  no Actions (legacy "gem-based" build), though even Jekyll is commonly run through Actions now to
  use arbitrary plugins. Astro ships an official action (`withastro/action`); Astro/MkDocs/etc.
  set `site`/`base` for project-path vs custom-domain. Source:
  https://docs.astro.build/en/guides/deploy/github/ , Astro GH Pages action
  https://github.com/withastro/action .
- **"Reuse plain Markdown" caveat — the decisive axis:**
  - **MkDocs Material** consumes the **plainest** CommonMark/Python-Markdown with **no required
    frontmatter** — closest to "point it at `docs/*.md` and go." First `#` heading becomes the
    title. Lowest friction for AID's existing files.
  - **Starlight / Docusaurus / VitePress** are **MD/MDX** systems. Starlight/Docusaurus require
    (or strongly prefer) **YAML frontmatter with a `title`** on each page, and files must live in
    a content dir (`src/content/docs/` for Starlight, `docs/` for Docusaurus). Reusing repo docs
    means either moving/symlinking them in and adding frontmatter, or a small sync/transform step.
    Raw `.md` mostly works; the friction is frontmatter + file location, and any `{}`-looking text
    can trip MDX parsing in `.mdx`. Sources:
    https://starlight.astro.build/guides/authoring-content/ ,
    https://starlight.astro.build/reference/frontmatter/ .
- **Search options (no-SaaS vs SaaS):**
  - **Pagefind** = static, client-side, zero-backend full-text search; **built into Starlight**;
    addable to anything. Best "offline / no-SaaS" answer for JS generators.
  - **MkDocs Material** ships **built-in lunr.js** client-side search (no server, works offline,
    even has an `offline` plugin for file:// distribution). Source:
    https://squidfunk.github.io/mkdocs-material/setup/setting-up-site-search/ ,
    https://squidfunk.github.io/mkdocs-material/plugins/offline/ .
  - **Docusaurus** has **no good built-in** full-text search; the canonical path is **Algolia
    DocSearch** (SaaS, free for OSS but an external dependency + application/approval) or a
    community local-search plugin. VitePress ships a built-in local (minisearch) option and an
    optional Algolia integration.

### Per-tool table

| Tool | GH Pages | Native vs Actions | Reuse plain MD | Built-in search (no-SaaS) | Theming / branding | Custom domain | Build/maint. burden | Learning curve | License / cost |
|------|----------|-------------------|----------------|---------------------------|--------------------|---------------|---------------------|----------------|----------------|
| **MkDocs Material** | Yes | Actions (`mkdocs gh-deploy` or workflow) | **Best** — plain MD, no frontmatter needed | **Yes** — lunr, client-side, offline plugin | Strong, mature theme; CSS overrides, color/logo, "Insiders" extras paid | Yes (CNAME) | **Low** — single `mkdocs.yml`, Python | **Low** | OSS **MIT** (theme); Insiders sponsorware optional |
| **Astro Starlight** | Yes | Actions (`withastro/action`) | Good — needs frontmatter `title` + content dir | **Yes** — Pagefind built in | **Excellent** — Astro components, full CSS control, can match Mintlify look | Yes (CNAME in `public/`) | Low–Med — Node build, npm deps | Low–Med | OSS **MIT** |
| **VitePress** | Yes | Actions | Good — MD + frontmatter, Vue in prose | **Yes** — local minisearch built in | Good; Vue-centric customization | Yes | Low–Med | Med (Vue helps) | OSS **MIT** |
| **Docusaurus** | Yes | Actions | OK — MD/MDX, frontmatter, `docs/` dir | **Weak** — needs Algolia DocSearch (SaaS) or plugin | Excellent — React/MDX, huge plugin + versioning ecosystem | Yes | **Med-High** — heavier React build, more deps/JS | Med | OSS **MIT** |
| **Jekyll + Just-the-Docs** | Yes | **Native** (no Actions needed) | Good — MD + frontmatter | **Yes** — built-in lunr search | Modest; theme is functional, less "modern SaaS" polish | Yes | Low (native) but Ruby toolchain | Low–Med | OSS **MIT** |
| **Mintlify** | **No (effectively)** | N/A — see below | N/A (its own MDX dialect) | Yes (its own + AI) | **Reference look** (this is the target aesthetic) | Yes (on its hosting) | Low *content*, but you don't run it | Low | **SaaS**; Hobby free tier but **hosted by Mintlify**, Pro ~$250/mo, self-host = Enterprise only |
| **GitBook** | **No** | N/A — SaaS/hosted | Git-sync of MD possible | Yes (hosted) | Hosted look, limited | On its hosting | N/A (managed) | **SaaS**; free tier limited, paid plans |

### The Mintlify question (explicit)
- **Anthropic's docs (Claude API, Claude Code, MCP) are built on Mintlify** — confirmed by
  Mintlify's own customer page and the `*.mintlify.app` Anthropic preview hosts.
  Sources: https://www.mintlify.com/customers/anthropic ,
  https://anthropic.mintlify.app/en/api/models .
- **Mintlify is primarily a paid SaaS that hosts your docs.** Components/MDX engine and starter
  template are MIT-licensed (e.g. `@mintlify/mdx`, https://github.com/mintlify/mdx), but the
  full product (rendering, search, the three-pane app) runs on **Mintlify's platform**. The free
  **Hobby** tier still means *Mintlify hosts it* (with custom-domain support). **Self-hosting the
  Mintlify container is Enterprise-only.** Source: https://www.mintlify.com/pricing ,
  https://apidog.com/blog/mintlify-review-pricing-features-alternatives/ .
- **Therefore Mintlify CANNOT be self-hosted on GitHub Pages** in any practical free way. It does
  not produce a static bundle you deploy to GH Pages; you publish through Mintlify. This **fails
  the hard constraint** ("static, deployed via GH Actions from a single repo").
- If the *exact Mintlify aesthetic* is required without the SaaS, the open options are:
  (a) **Mintlify "custom frontend" / `mintlify-astro-starter`** (Astro, but still uses Mintlify's
  content engine — not free/standalone), or (b) **Unmint**, an MIT "Mintlify-style, self-hosted"
  clone (https://github.com/gregce/unmint) — niche/immature. Neither is recommended over a
  mainstream generator themed to look the part.

---

## 4. Custom-domain integration with `casuloailabs.com`

### How GitHub Pages custom domains work
- Setting a custom domain in repo **Settings → Pages** writes a **`CNAME` file** into the
  published output (for branch-based publishing; for Actions-based publishing, ship `CNAME` in the
  build output, e.g. Astro's `public/CNAME`). The file holds the single domain.
- **One custom domain per repository.** Move = remove from old repo first.
- **HTTPS:** GitHub auto-provisions a Let's Encrypt cert; enable **"Enforce HTTPS"** (can take up
  to ~24h after DNS resolves).
- **Add the domain in GitHub *before* creating the DNS records** to avoid takeover risk; avoid
  wildcard records.
- Source: https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site

### DNS records (exact values GitHub specifies)
- **Subdomain** (recommended — `aid.casuloailabs.com` or `docs.casuloailabs.com`):
  one **`CNAME`** record →  `<OWNER>.github.io` (the user/org, **not** the repo).
- **Apex** (`casuloailabs.com`) would need either four **A** records →
  `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153`
  (and/or AAAA `2606:50c0:8000::153 … :8003::153`), or an `ALIAS`/`ANAME` →
  `<OWNER>.github.io`. (Apex is **not** what we want here, since `casuloailabs.com` already
  serves the main site.)

### Subdomain vs sub-path — recommendation
| Approach | How | Pros | Cons |
|----------|-----|------|------|
| **Subdomain** `aid.casuloailabs.com` (or `docs.…`) | One CNAME → `OWNER.github.io`; set in repo Pages settings | **Trivial, native, free, auto-HTTPS**; clean separation; standard GH Pages flow | Separate origin from the apex (cookies/analytics counted separately); looks "alongside" not "inside" the path |
| **Sub-path** `casuloailabs.com/aid` (reverse proxy) | Reverse proxy / CDN rule on the apex host forwarding `/aid` to GH Pages | Reads as one unified site/domain | **Not a native GH Pages feature**; needs the apex host to run/maintain a proxy (Cloudflare Worker, Netlify/Nginx rule); base-path config, asset-URL pitfalls; more moving parts → higher maintenance |

**Recommendation:** **Use a subdomain — `aid.casuloailabs.com`** (or `docs.casuloailabs.com`).
It satisfies "low maintenance," is fully supported by GitHub Pages, needs only **one CNAME record**,
gets free auto-HTTPS, and keeps the docs repo self-contained. Reserve the reverse-proxy sub-path
only if branding strictly mandates a single apex domain. Add `aid.casuloailabs.com` in the repo's
Pages settings first, then create the CNAME at the DNS provider.

---

## 5. Recommended IA / sitemap for AID (Diátaxis-informed three-pane)

**Top-nav tabs (buckets):** `Get Started` · `Guides` · `Concepts` · `Reference` · `Releases`
(plus header links: GitHub, search). These map to Diátaxis Tutorial / How-to / Explanation /
Reference / (changelog).

```
Home  (landing / value-prop — not a nav tab; the "/" page)
  hero, what AID is, the pipeline diagram, install one-liner, CTAs to Get Started & Concepts

TAB: Get Started            (Tutorials — learning-oriented)
  - Overview / What is AID            ← intro of aid-methodology.md (Philosophy excerpt)
  - Install AID                       ← install.md (channel chooser; full how-to lives in Guides)
  - Your first run (walkthrough)      ← NEW guided tutorial: config → discover/interview → execute
  - The Lite path (quick start)       ← NEW: fast track for small changes/bug fixes

TAB: Guides                 (How-to — task-oriented)
  Installation
    - Install channels overview       ← install.md (curl/irm, npm, PyPI, offline)
    - curl / irm bootstrap            ← install.md  (per-OS TABS: Linux/macOS/Windows)
    - npm                             ← install.md
    - PyPI                            ← install.md
    - Offline / air-gapped tarball    ← install.md
    - Add AID to a project (per tool) ← install.md (Claude Code/Codex/Cursor/Copilot/Antigravity TABS)
    - Update / Remove                 ← install.md
  Working the pipeline
    - Discover a brownfield repo
    - Gather requirements (Interview)
    - Specify / Plan / Detail
    - Execute tasks
    - Deploy a release / Monitor      ← optional skills
  Maintainer
    - Cut a release                   ← release.md
    - Regenerate install trees        ← (aid-generate)

TAB: Concepts               (Explanation — understanding-oriented)
  - The methodology (full)            ← aid-methodology.md (the long read)
  - The pipeline & phases             ← aid-methodology.md §1, §4
  - Philosophy (Iron-Man model)       ← aid-methodology.md §2
  - The Knowledge Base                ← aid-methodology.md §3
  - The agent model / roster          ← aid-methodology.md §5
  - Feedback loops                    ← aid-methodology.md §6
  - Lite vs full path                 ← (explanation of when to use which)
  - Comparison with SDD               ← aid-methodology.md §9
  - FAQ                               ← faq.md

TAB: Reference              (Reference — information-oriented)
  - CLI & subcommands                 ← install.md "Reference" section
  - Skills reference (the 11 skills)  ← canonical/skills (one-line each + links)
  - Agents reference (the 9 agents)   ← agent roster
  - Knowledge Base documents (the 14) ← KB catalog
  - Settings (.aid/settings.yml keys) ← config keys
  - Artifacts reference               ← aid-methodology.md §7
  - Repository structure              ← repository-structure.md
  - Glossary                          ← glossary.md

TAB: Releases              (changelog — low-maintenance, automated)
  - Changelog / Release notes         ← auto-pulled from GitHub Releases or CHANGELOG.md
```

**Reuse map (existing file → destination):**
- `aid-methodology.md` → Concepts (split by H2 sections, or one long "The methodology" page).
- `install.md` → Get Started (chooser) + Guides/Installation (full how-to, per-OS & per-tool tabs)
  + Reference (CLI subcommands).
- `repository-structure.md` → Reference / Repository structure.
- `faq.md` → Concepts / FAQ.
- `glossary.md` → Reference / Glossary.
- `release.md` → Guides / Maintainer / Cut a release.
- **New content needed:** the *Tutorials* quadrant (first-run walkthrough, lite-path quickstart)
  and the Reference catalog pages (skills/agents/KB) that today live only in `canonical/`.

**Low-maintenance Releases automation:** prefer a build-time fetch of GitHub Releases (or render a
repo `CHANGELOG.md`). Two clean options: (a) a GitHub Action step that calls the Releases API and
writes a Markdown page before the docs build; or (b) point the page at GitHub Releases. With
MkDocs, the `mkdocs-rss-plugin` or a tiny pre-build script suffices; with Starlight/Docusaurus a
pre-build Node script. Triggering the docs deploy on `release: published` keeps it current with
zero manual edits.

---

## Recommendation (summary)

**Pick MkDocs Material.** It is the lowest-friction match for *every* hard constraint:
reuses the existing plain Markdown with **no frontmatter rework**, ships the **three-pane layout +
built-in offline client-side search** with **no SaaS** (no Algolia), deploys to GitHub Pages via a
small Actions workflow, supports the `aid.casuloailabs.com` CNAME, and has the **lowest ongoing
maintenance** (one `mkdocs.yml`, Python, MIT-licensed, no JS dependency churn). The theme already
delivers the Anthropic-style tabs/sidebar/TOC/admonitions/code-tabs aesthetic.

**Runner-up 1 — Astro Starlight:** best *visual* fidelity to the Mintlify/Claude look and full
component-level control, Pagefind search built in, MIT. Cost: needs frontmatter + a content dir,
so reusing the repo's `docs/*.md` requires a small sync/transform step, and it carries a Node
build. Choose this if matching the exact Anthropic aesthetic outranks reuse-simplicity.

**Runner-up 2 — Docusaurus:** most mature ecosystem (versioning, plugins, MDX/React). Cost:
heavier React build, **no good built-in search** (Algolia DocSearch SaaS or a community plugin),
higher maintenance. Choose only if you foresee heavy versioning/interactive needs.

**Rejected for the hard constraint:** **Mintlify** and **GitBook** — both are SaaS-hosted and
**cannot be self-hosted on GitHub Pages** for free (Mintlify self-host = Enterprise). Mintlify is
the aesthetic target, not a deployable-on-GH-Pages tool. Jekyll + Just-the-Docs is the only
*native* (Actions-free) option but its theme is less modern than the target look.

**Risks / caveats:**
- "Reuse existing Markdown" is the real differentiator — Starlight/Docusaurus/VitePress need
  frontmatter + relocation; only MkDocs Material is near-zero-touch. If docs stay in `docs/` and
  the site lives in the same repo, MkDocs can point straight at them.
- Internal relative links in the current `.md` files (e.g. `aid-methodology.md#9-…`) will need
  path/anchor adjustment once pages are re-grouped under the new IA — true for any generator.
- The Tutorials quadrant and the skills/agents/KB reference pages **do not exist yet** and must be
  authored — this is content work, not a tooling gap.
- Releases automation depends on a GitHub Action with a token to read the Releases API; trivial
  but a moving part to maintain.
- One custom domain per repo: keep the docs in their own repo (or a dedicated Pages config) so the
  CNAME doesn't collide with any other Pages site on the org.
- Mermaid diagrams in `aid-methodology.md` need a Mermaid plugin (MkDocs Material: pymdownx
  superfences + mermaid2; Starlight: rehype-mermaid / remark plugin) — supported in all, just
  configure it.
