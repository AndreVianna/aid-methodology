# Site Foundation: Shell, Navigation, Search & Theming

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-06 | Feature identified from REQUIREMENTS.md §5 (FR1, FR2, FR13), §6, §7, §10 | /aid-interview |

## Source

- REQUIREMENTS.md §5 (FR1 Site shell & navigation, FR2 Search, FR13 Brand theming)
- REQUIREMENTS.md §6 (Non-Functional Requirements), §7 (Constraints), §10 (Priority — Must)

## Description

Stand up the Astro Starlight documentation project that every other feature builds on. It
provides the site's chrome and look-and-feel: the three-pane developer-docs layout (top nav
with the five section tabs — Get Started, Guides, Concepts, Reference, Releases; a grouped,
collapsible left sidebar; an on-this-page TOC; breadcrumbs), persistent header/footer links to
GitHub and casuloailabs.com, and site-wide client-side search (Pagefind, which ships with
Starlight — offline-capable, no external SaaS). The site is themed to the casuloailabs.com brand
so AID reads as product documentation within the Casulo AI Labs family: dark base `#0a0e1a`,
gold accent `#d4a853`, Inter typography, dark by default with a working light-mode toggle, both
modes WCAG-AA contrast-verified. The layout is optimized for desktop and landscape tablet and
remains usable (readable, navigable, with scrollable diagrams and code) on portrait tablet and
mobile. Mermaid diagram rendering is enabled here so content features can use it. This feature
delivers the shell with placeholder/empty section pages; real content arrives in later features.

## User Stories

- As an evaluator, I want a polished, branded, professionally laid-out site so that I get a
  credible first impression of AID's maturity within seconds.
- As an evaluator, I want a site-wide search box so that I can jump straight to what I need
  without reading linearly.
- As a returning user, I want consistent navigation (top tabs, left sidebar, TOC, breadcrumbs)
  so that I can reliably relocate reference material.
- As a returning user, I want a light-mode toggle so that I can read comfortably in any
  environment, with the casulo brand preserved in both modes.
- As a maintainer, I want a single CSS-variable theme mapped to the casulo tokens so that
  brand changes are made in one place without per-page overrides.

## Priority

Must

## Acceptance Criteria

- [ ] Given the project repo, when the site is built and served, then it renders the three-pane
  layout with top nav, grouped collapsible left sidebar, on-this-page TOC, and breadcrumbs (AC3).
- [ ] Given any page, when it is viewed, then the header/footer expose persistent links to
  GitHub and casuloailabs.com (AC3).
- [ ] Given the rendered site, when inspected against the brand reference, then it uses the
  casulo palette (dark `#0a0e1a`, gold `#d4a853`, Inter) and loads dark by default with a working
  light toggle, both modes themed (AC4).
- [ ] Given gold `#d4a853` and the theme tokens, when contrast is measured in both modes, then
  they meet WCAG 2.1 AA (AC4, AC10).
- [ ] Given a search query, when entered in the search box, then relevant client-side results
  are returned with no external SaaS request (AC8).
- [ ] Given a page containing a Mermaid code block, when the page is built and viewed, then the
  diagram renders correctly (AC5 enabler).
- [ ] Given a desktop or landscape-tablet viewport, when the site is viewed, then the full
  three-pane layout is shown; given a portrait-tablet or mobile viewport, then the site remains
  usable (text readable, sidebars collapse to a drawer, diagrams/code scroll) (AC10).

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
