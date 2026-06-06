# Requirements

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | Initial interview started | /aid-interview |
| 2026-06-06 | §1 Objective, §2 Problem Statement captured | /aid-interview |
| 2026-06-06 | §7/§8: tooling=Astro Starlight, host=GitHub Pages+Actions, domain=aid.casuloailabs.com (GoDaddy CNAME), brand=casulo dark+gold+Inter (structure may differ) | /aid-interview + research |
| 2026-06-06 | §3 Users, §4 Scope, §5 FRs (sitemap-driven), §6 NFRs (desktop+landscape-tablet first; dark default + light toggle; no analytics), §9 ACs, §10 Priority captured | /aid-interview |
| 2026-06-06 | Interview complete — approved | /aid-interview |
| 2026-06-06 | Scope addition (during decomposition): live-project bindings — FR14 feedback→prefilled GitHub issue + per-page "Report an issue", FR15 always-current version/install, FR16 release announcement banner, FR10 bound to `release: published` event; "Edit this page" links explicitly out; serverless feedback + RSS feed deferred. Repo slug corrected to AndreVianna/aid-methodology. | /aid-interview (user request) |

## 1. Objective

Build and publish a public **product website for the AID methodology** via GitHub Pages,
served from this repository. The site is AID's "front door": it explains what AID is and
why it exists, and carries a prospective user from "never heard of it" to "installed and
running their first work" with minimal friction. It is a polished, multi-page site covering
the value proposition, how AID works, installation across every channel, a getting-started
walkthrough, a releases/changelog section, and reference documentation — with content reused
from the repo's existing `docs/` where possible, deployed through a GitHub Actions workflow.
Where useful, the site is **bound to the live AID project** so it stays current hands-free
(releases, version numbers) and offers a low-friction feedback path.

## 2. Problem Statement

AID reached **v1.0.0** with a real installer across four channels (curl/irm, npm, PyPI,
offline tarball), but its public presence is still **repo-centric** — a GitHub README plus
loose `docs/` Markdown. That format reads as a README/blog, not a product: it **undersells
a sophisticated, finished methodology** and makes AID look less mature than it is. An
evaluator skimming to decide whether AID is worth adopting gets no professional first
impression; a new adopter must hunt through repo files instead of following a guided,
navigable path.

What's missing is a **professional product-documentation website** that meets the standard
of modern developer documentation (e.g. the three-pane docs layout used by Anthropic's
Claude docs: top section nav + global search, grouped left sidebar, center content with
per-environment tabs, on-this-page TOC). It must communicate the value quickly, give a
clean per-environment install + getting-started flow, and present releases and reference
docs in a structured, searchable form — and, ideally, be presented **as product
documentation within the casuloailabs.com product family** rather than as a standalone repo
page, so AID inherits the credibility and branding of an established site.

## 3. Users & Stakeholders

**Primary audiences (priority order):**

1. **Evaluators** — developers / teams assessing whether to adopt AID. Need to grasp the
   value quickly and get a credible, professional first impression.
2. **New adopters** — installing AID and running their first work. Need a guided
   per-environment install and getting-started path.
3. **Returning users** — looking up reference material, release notes, and troubleshooting.

**Secondary audience:**

- **Maintainers / contributors** to AID itself — the release process, repository structure,
  and regeneration workflows.

**Stakeholders:**

- **Owner / decision-maker:** Andre Vianna (Casulo AI Labs). The site represents the
  **Casulo AI Labs** brand and sits within the casuloailabs.com product family.

## 4. Scope

### In Scope

- A static **Astro Starlight** documentation site implementing the confirmed site map:
  **Home, Get Started, Guides, Concepts, Reference, Releases.**
- **Theming** to the casuloailabs.com brand (dark `#0a0e1a`, gold `#d4a853`, Inter), using
  Starlight's native three-pane docs structure.
- **Migration/reuse** of existing `docs/*.md` (methodology, install, repository-structure,
  faq, glossary) into Starlight content.
- **New content:** "Your first work" walkthrough, "Lite path quickstart", and a generated
  **Skills / Agents / KB reference** (from `canonical/`).
- **Global search** (Pagefind), **per-environment tabbed** install instructions, and
  **Mermaid** diagram rendering.
- **CI/CD:** a GitHub Actions workflow that builds and deploys to **GitHub Pages** at the
  custom domain **`aid.casuloailabs.com`** (HTTPS).
- **Releases** section auto-populated from GitHub Releases / `CHANGELOG.md`, including
  per-release **offline-tarball download links**, **rebuilt automatically on the
  `release: published` event** so it stays current hands-free.
- **Feedback path:** a feedback page and a per-page **"Report an issue"** link that open a
  **prefilled GitHub issue** (backed by a GitHub issue-form template) — no backend.
- **Always-current version & install:** the latest released version is injected at build
  time into the version badge and all install commands so they never go stale.
- **Release announcement banner:** a dismissible banner surfacing the latest release.
- **Cross-linking** to `casuloailabs.com` from the docs (nav/footer).

### Out of Scope

- Any **backend/server**, user accounts, or authentication — **including** a serverless
  function to auto-create issues from an on-page form. The feedback path uses **prefilled
  GitHub issues** instead; a "fully automatic" serverless feedback Worker is **deferred**
  (designed so it can be added later without reworking the form).
- **"Edit this page" links** — deliberately omitted: pages are migrated/generated from
  `docs/` and `canonical/`, so edit links would target copies and invite drift; feedback is
  funnelled through "Report an issue" instead.
- An **RSS/Atom releases feed** — deferred (may be added later).
- **Heavy analytics** (basic privacy-friendly page views optional, not required).
- Rewriting or restructuring the **casuloailabs.com marketing site** (only an outbound link
  from the parent site to AID docs may be added later — tracked separately as it lives in
  that repo).
- An **AI "assistant" panel** like the one in Claude's docs (future enhancement).
- **Internationalization** / multiple languages (English only initially).
- **Versioned docs** (single "current" version initially).
- A **blog** (already hosted on casuloailabs.com).

## 5. Functional Requirements

- **FR1 — Site shell & navigation.** Top nav with the five section tabs (Get Started,
  Guides, Concepts, Reference, Releases), a grouped collapsible left sidebar, an
  on-this-page TOC, breadcrumbs, and persistent links to GitHub and casuloailabs.com.
  Responsive across desktop/tablet/mobile.
- **FR2 — Search.** Site-wide client-side search (Pagefind), offline-capable, no external
  SaaS.
- **FR3 — Home / landing.** Value proposition, the pipeline diagram, the install one-liner,
  and primary CTAs (Get Started, GitHub).
- **FR4 — Get Started.** Overview / "What is AID"; **Install AID**; **"Your first work"**
  walkthrough (new); **Lite path quickstart** (new).
- **FR5 — Guides / Installation.** Channels overview + curl/irm + npm + PyPI + offline
  tarball; **per-tool "add to project"** instructions in tabbed blocks
  (Claude/Codex/Cursor/Copilot/…); update / remove. Sourced from `docs/install.md`.
- **FR6 — Guides / Pipeline.** End-to-end how-to for working the pipeline
  (discover → interview → specify → plan → detail → execute → deploy/monitor).
- **FR7 — Guides / Maintainer.** "Cut a release" (from `docs/release.md`) and
  "regenerate trees/profiles".
- **FR8 — Concepts.** The methodology, pipeline & phases, philosophy, Knowledge Base, agent
  model, feedback loops, lite vs full, AID vs spec-driven-dev (from
  `docs/aid-methodology.md`); FAQ (from `docs/faq.md`).
- **FR9 — Reference.** CLI & subcommands (from `docs/install.md`); a generated
  **Skills / Agents / KB** reference (from `canonical/`); settings keys; artifacts;
  repository structure (from `docs/repository-structure.md`); glossary (from
  `docs/glossary.md`).
- **FR10 — Releases (auto-bound).** A changelog auto-pulled from GitHub Releases /
  `CHANGELOG.md` at build time, with per-release offline-tarball download links. The docs
  deploy workflow **rebuilds on the `release: published` event** (no change to `release.yml`
  — decoupled binding), so the Releases page stays current hands-free.
- **FR11 — Content reuse.** Existing `docs/*.md` are migrated into Starlight content
  (frontmatter added) and kept as the single source where feasible; Mermaid diagrams render
  correctly.
- **FR12 — Build & deploy.** A GitHub Actions workflow builds the Starlight site and
  deploys it to GitHub Pages; custom domain `aid.casuloailabs.com` with enforced HTTPS and a
  `CNAME` in the build output.
- **FR13 — Brand theming.** The site visually inherits the casuloailabs.com palette and
  Inter typography (dark-first), per `research/casulo-brand.md`.
- **FR14 — Feedback & "Report an issue".** A dedicated feedback page and a per-page
  **"Report an issue"** link, each opening a **prefilled GitHub issue** (title, body,
  labels, and the originating page URL prefilled) backed by a GitHub issue-form template
  under `.github/ISSUE_TEMPLATE/`. No backend, no secrets; the visitor reviews and submits
  on GitHub. The form is structured so a serverless auto-create path could replace the
  prefilled link later without changing the UI.
- **FR15 — Always-current version & install.** At build time the latest released version
  is injected into the version badge and **all install one-liners** (curl/irm, npm, PyPI,
  offline) so the documented commands and version never go stale.
- **FR16 — Release announcement banner.** A dismissible site banner surfacing the latest
  release (e.g. "AID vX.Y.Z is out"), driven from the latest GitHub Release at build time,
  linking to the Releases page.

## 6. Non-Functional Requirements

- **Responsive:** **desktop + landscape-tablet first** (the layout is optimized for these,
  given the volume of content, wide Mermaid diagrams, images, and code snippets). Portrait
  tablet and mobile must remain **usable** — readable text and working navigation (sidebars
  collapse to a drawer), with **diagrams and code blocks horizontally scrollable** rather
  than forced to reflow. Full small-screen visual parity is explicitly not a goal.
- **Browsers:** modern evergreen browsers (Chrome, Edge, Firefox, Safari — last 2 major
  versions).
- **Theme:** **dark default** using the casulo palette, with a **light-mode toggle**; both
  modes themed with casulo colors/typography.
- **Accessibility:** target **WCAG 2.1 AA** — semantic heading structure, full keyboard
  navigation, and verified color contrast (confirm gold `#d4a853` and the theme tokens meet
  AA in both modes).
- **Performance:** statically prerendered; fast first load; minimal JavaScript; target
  **Lighthouse ≥ 90** for Performance / Accessibility / Best-Practices / SEO.
- **SEO:** per-page title + meta description, Open Graph / social cards, a generated
  `sitemap.xml`, and `robots.txt`.
- **Search:** client-side (Pagefind), instant, no external SaaS.
- **Analytics:** **none** in v1 (may be added later).
- **Maintainability:** content authored in Markdown/MDX; reuse a single source from `docs/`
  where feasible; pinned build dependencies for reproducible builds; CI should flag broken
  internal links where practical. Live-project bindings (releases, version, banner) must be
  **decoupled** from `release.yml` (event-driven), so the release process needs no changes.

## 7. Constraints

- **Hosting:** static site on **GitHub Pages**, built and deployed via a **GitHub Actions**
  workflow from the AID repository (`AndreVianna/aid-methodology`).
- **Generator:** **Astro Starlight** (Node/Astro toolchain). Chosen for closest fit to the
  modern three-pane developer-docs look, CSS-variable theming, and built-in offline search.
- **Custom domain:** **`aid.casuloailabs.com`** — a subdomain, via a `CNAME` DNS record at
  **GoDaddy** pointing at `AndreVianna.github.io`, plus the repo's Pages custom-domain
  setting and a `CNAME` file in the build output; **Enforce HTTPS**. The apex
  `casuloailabs.com` is already used by the separate site repo, so AID uses a subdomain
  (one custom domain per repo → AID docs stay in their own repo).
- **Visual identity:** inherit the **casuloailabs.com color theme** — dark base
  (`#0a0e1a`), gold accent (`#d4a853`), **Inter** typography (see
  `research/casulo-brand.md`). The docs **page structure may differ** from the marketing
  site; use Starlight's native docs layout (top nav + grouped left sidebar + on-this-page
  TOC + tabbed code blocks).
- **Content reuse:** reuse existing repo Markdown (`docs/aid-methodology.md`,
  `docs/install.md`, `docs/repository-structure.md`, `docs/faq.md`, `docs/glossary.md`)
  as the content source where possible; minimize duplication and drift.
- **Live-project bindings:** release/version/banner data is read at **build time** and the
  docs workflow triggers on the **`release: published`** GitHub event — **decoupled** from
  `release.yml` (which is not modified). No runtime backend.
- **Feedback path is static:** the feedback page and "Report an issue" link use **prefilled
  GitHub issues only** (no token, no serverless function), preserving the no-backend
  constraint. A serverless auto-create path is deferred.
- **No "Edit this page" links** — omitted by decision (generated/migrated content; risk of
  pointing at copies / inviting drift).
- **Maintenance:** low ongoing burden; the releases/changelog section must update with
  minimal manual effort.
- The repo's **ASCII-only rule does not apply** to site content (that guard is for shipped
  installer/CLI scripts, not docs); however, **Mermaid diagrams** require a Starlight/Astro
  plugin to render.

## 8. Assumptions & Dependencies

- The docs site is built and deployed from the **AID repo**
  (`AndreVianna/aid-methodology`), a separate repository from `casuloailabs.com`.
- The owner controls `casuloailabs.com` **DNS at GoDaddy** and can add the `aid` CNAME
  record and configure the repo's GitHub Pages custom domain.
- **Build dependencies:** Node.js + Astro + Starlight; **Pagefind** (bundled with Starlight)
  for client-side search; a **Mermaid** integration for the pipeline/feedback diagrams.
- **Content dependencies:** the existing `docs/*.md` files and `canonical/` (for a
  skills/agents/KB reference). **New content is required** for the Get-Started/tutorial
  walkthrough and the skills/agents/KB reference pages — these do not exist yet.
- **Releases / version / banner automation** depends on the **GitHub Releases API** (and/or
  `CHANGELOG.md` and the `VERSION` file); a build-step Action reads it using the workflow's
  `GITHUB_TOKEN`, and the workflow listens for the `release: published` event.
- **Feedback** depends on a **GitHub issue-form template** (`.github/ISSUE_TEMPLATE/`) and
  the GitHub `issues/new` prefill query parameters; submitters need a GitHub account.
- GitHub Pages must be enabled for the repo with **source = GitHub Actions**.
- Starlight content uses MD/MDX with **YAML frontmatter**; existing `docs/*.md` will need
  frontmatter added and to be placed in Starlight's content directory (a one-time,
  scriptable migration).

## 9. Acceptance Criteria

- **AC1 — Builds & deploys.** The Starlight site builds with no errors and a GitHub Actions
  workflow deploys it to GitHub Pages automatically on push to the default branch.
- **AC2 — Live on custom domain.** The site is reachable at **`https://aid.casuloailabs.com`**
  over HTTPS, with the `CNAME` and Pages custom-domain configured.
- **AC3 — Navigation complete.** All six areas (Home, Get Started, Guides, Concepts,
  Reference, Releases) exist and are navigable per the confirmed site map, with top nav,
  grouped left sidebar, on-this-page TOC, breadcrumbs, and GitHub + casuloailabs.com links.
- **AC4 — On brand.** The site matches the casulo palette (dark `#0a0e1a`, gold `#d4a853`,
  Inter), **dark by default with a working light toggle**.
- **AC5 — Content migrated faithfully.** Existing `docs/*.md` (methodology, install,
  repository-structure, faq, glossary) appears with no content loss; **Mermaid diagrams
  render**; internal links resolve.
- **AC6 — New content present.** "Your first work" walkthrough, "Lite path quickstart", and
  a Skills / Agents / KB reference exist.
- **AC7 — Install instructions.** All four channels (curl/irm, npm, PyPI, offline tarball)
  are documented with per-tool **tabbed** blocks and copyable commands.
- **AC8 — Search works.** Client-side search returns relevant results with no external SaaS.
- **AC9 — Releases current.** The Releases section reflects GitHub Releases / `CHANGELOG.md`
  with per-release offline-tarball download links.
- **AC10 — Quality bars.** Layout optimized for desktop + landscape tablet, and **usable**
  (readable, navigable; diagrams/code scroll) on portrait tablet and mobile; **Lighthouse
  ≥ 90** across Performance / Accessibility / Best-Practices / SEO; **WCAG 2.1 AA** contrast
  verified.
- **AC11 — Human visual gate.** The rendered site passes a human visual review/approval
  (look-and-feel is a primary goal of this work).
- **AC12 — Feedback → prefilled issue.** The feedback page and every per-page "Report an
  issue" link open a **prefilled GitHub issue** (correct issue-form template; title, body,
  labels, and originating page URL prefilled) with **no backend call**.
- **AC13 — Version/install never stale.** The version badge and every install one-liner
  (curl/irm, npm, PyPI, offline) render the **latest released version** at build time,
  matching the `VERSION` file / latest GitHub Release.
- **AC14 — Announcement banner.** A dismissible banner shows the latest release and links to
  the Releases page; dismissal persists for the visitor.
- **AC15 — Release-event rebind.** Publishing a GitHub Release triggers a docs rebuild that
  updates the Releases page, version badge/install commands, and banner — with **no manual
  steps and no change to `release.yml`**.

## 10. Priority

**Overall priority: High** — this is the flagship adoption asset following the v1.0.0
release.

Suggested delivery shape (MoSCoW), to guide `/aid-specify` and `/aid-plan`:

- **Must (first deploy / MVP):** FR1 shell & nav · FR13 theming · FR2 search · FR3 home ·
  FR4 Get Started (install + first-work) · FR5 installation guide · FR11 reuse of core docs ·
  FR12 build + deploy + custom domain · **FR15 always-current version & install** (prevents
  the most damaging docs-rot, core to credibility).
- **Should:** FR8 Concepts (full methodology) · FR9 Reference (CLI, repository structure,
  glossary) · FR10 Releases (auto-bound) · **FR14 feedback + "Report an issue"**.
- **Could:** FR6 pipeline guide depth · FR7 maintainer guides · generated Skills/Agents/KB
  reference (may start as stubs and deepen later) · **FR16 release announcement banner**.
- **Won't (this round):** serverless auto-create feedback Worker · "Edit this page" links ·
  RSS/Atom releases feed · AI assistant panel · internationalization · versioned docs ·
  analytics.
