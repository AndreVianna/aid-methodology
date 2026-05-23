# UI Architecture

> **Source:** aid-discover (discovery-architect)
> **Status:** Populated (initial dogfood pass, 2026-05-21)
> **Companions:** `architecture.md` (overall AID architecture), `technology-stack.md` (HTML / CSS / JS file counts), `project-structure.md` (where these files live and their triplication).

There is **no traditional user-facing UI** in this repository. AID is a methodology + tooling repo — its primary user interface is the host AI tool's slash-command surface (`/aid-discover`, `/aid-init`, etc.) and the terminal output of `setup.sh` / `setup.ps1`. Those are not "UI architecture" in the conventional sense.

There **is** however one genuine HTML artifact emitted by AID: the **Knowledge Base Summary viewer** produced by the `aid-summarize` skill. This document covers that artifact in detail and notes the deliberate design constraints around it.

---

## 1. Location & Triplication

| Where | Files |
|---|---|
| Canonical source-of-truth assets | `templates/knowledge-summary/` (25 files per `project-structure.md:170-172`) |
| Claude Code install copy | `profiles/claude-code/.claude/templates/knowledge-summary/` |
| Codex install copy | `profiles/codex/.agents/templates/knowledge-summary/` |
| Cursor install copy | `profiles/cursor/.cursor/templates/knowledge-summary/` |

All four trees contain identical content. The `aid-summarize` skill reads from `.aid/templates/knowledge-summary/` (the path inside an installed project, which corresponds to one of the per-tool copies).

The skill that emits the HTML lives at `profiles/claude-code/.claude/skills/aid-summarize/SKILL.md` (430 lines) and equivalents under `profiles/codex/.agents/skills/aid-summarize/SKILL.md` (436 lines) and `profiles/cursor/.cursor/skills/aid-summarize/SKILL.md` (436 lines).

---

## 2. Component Architecture

### 2.1 The HTML skeleton

`templates/knowledge-summary/html-skeleton.html` (101 lines) defines the document shell with Mustache-style `{{PLACEHOLDER}}` substitution. Sections (in DOM order):

| Section | Lines in skeleton | Purpose |
|---|---|---|
| `<head>` | `:1-14` | Lang, charset, viewport, `color-scheme: light dark` meta, generator meta, robots: noindex, `<title>{{PROJECT_NAME}} — Knowledge Base Summary</title>`, inlined `{{INLINE_CSS}}` |
| `<a class="skip-link">` | `:17-18` | Skip-to-content for keyboard / screen-reader users |
| `<header role="banner">` (sticky top bar) | `:21-36` | Brand, breadcrumb (id `breadcrumb-current`), theme-toggle button (id `theme-toggle`) |
| `<main id="top">` with `{{BODY_CONTENT}}` | `:39-44` | Hero + TOC + section content (inserted by the generator from KB documents) |
| Lightbox dialog | `:47-60` | `role="dialog" aria-modal="true"` overlay with toolbar (zoom in/out/reset/close), stage, caption — toggled via `.open` class |
| `<footer>` | `:62-67` | Attribution + Mermaid version + "Re-run /aid-summarize when the KB changes" |
| `<noscript>` fallback | `:70-87` | Direct links to `.aid/knowledge/*.md` for JS-disabled users |
| Inlined Mermaid library | `:89-94` | Concatenated at generation time |
| Inlined `{{INLINE_LIGHTBOX_JS}}` | `:96-98` | The runtime JS |

### 2.2 Page-level content composition

The `{{BODY_CONTENT}}` placeholder is filled by `aid-summarize` GENERATE mode (`aid-summarize/SKILL.md:198-200`) using one of six **profile-specific section templates** under `templates/knowledge-summary/section-templates/`:

| Profile | Template | Lines |
|---|---|---|
| Auto-detect | `auto-detect.md` | 107 |
| Web app | `web-app.md` | 98 |
| Library | `library.md` | 70 |
| CLI | `cli.md` | 77 |
| Microservices | `microservices.md` | 87 |
| Data pipeline | `data-pipeline.md` | 104 |

Profile selection is done in `aid-summarize` PROFILE mode (`aid-summarize/SKILL.md:122-156`) by scoring signals across `ui-architecture.md`, `api-contracts.md`, `module-map.md`, `infrastructure.md`, `integration-map.md`. The auto-detect rules live in `auto-detect.md`. If confidence is "low" the skill prompts the user via `AskUserQuestion`.

### 2.3 Shared vs page-specific components

Everything in the generated HTML is **page-specific** — there is no shared component library or framework. The "components" are CSS class conventions like `.top-bar`, `.breadcrumb`, `.lightbox`, `.mermaid-box`, `.noscript-fallback`, `.skip-link`. There is **no JavaScript componentization** (no React, Vue, Svelte, web components, lit-html). The skeleton is a single HTML file; the JS in `lightbox.js` is a single IIFE.

---

## 3. State Management

There is no client-side state management framework (no Redux, no Zustand, no MobX, no Pinia, no XState).

**Persistent client state:**
- `localStorage.kb-theme` — the user's chosen theme (`light` or `dark`). Read on init in `lightbox.js:14-19`. Written by `setTheme(theme)` at `lightbox.js:98-101`. Falls back to `window.matchMedia('(prefers-color-scheme: dark)')`.

**Transient client state (in-memory, lives in closure variables):**
- The current theme (mirror of `localStorage.kb-theme`, stored on `document.documentElement[data-theme]`).
- Lightbox open/closed flag (`.lightbox.open` class) and currently zoomed-in element reference.
- Breadcrumb scrollspy: the section currently in view (text injected into `#breadcrumb-current`).

All state lives inside the single IIFE in `lightbox.js`. No global namespace pollution.

---

## 4. Design System

### 4.1 The token palette

`templates/knowledge-summary/design-tokens.md` (124 lines) is the **documentation** of the design token palette. It is **not consumed at runtime** — the actual tokens live in `component-css.css` as CSS custom properties (`component-css.css:6-63`).

**Token categories** (per `component-css.css:7-36` light theme, `:37-63` dark theme):

| Category | Token examples | Purpose |
|---|---|---|
| Backgrounds | `--bg`, `--bg-elev`, `--bg-sunken` | Three depth levels |
| Text | `--text`, `--text-muted`, `--text-dim` | Three emphasis levels |
| Borders | `--border`, `--border-strong` | Two strengths |
| Brand | `--primary`, `--primary-fg`, `--accent`, `--accent-fg` | Brand + interactive accents |
| Status | `--ok`, `--ok-bg`, `--warn`, `--warn-bg`, `--err`, `--err-bg`, `--info`, `--info-bg`, `--purple`, `--purple-bg` | Five status badge colors with light backgrounds |
| Shadows | `--shadow-sm`, `--shadow-md`, `--shadow-lg` | Three elevation levels |
| Radius | `--radius-sm`, `--radius`, `--radius-lg` | Three border-radius scales |

⚠️ **Design tension — Inferred from code, needs confirmation.** `design-tokens.md` and `component-css.css` are maintained in parallel with no propagation tooling. If a token changes in CSS, the doc must be updated manually (and vice versa). Recorded by scout as Q14 in `DISCOVERY-STATE.md`.

### 4.2 Light / Dark theming

Theming uses CSS variables scoped by `html[data-theme="light"]` and `html[data-theme="dark"]` (`component-css.css:6-63`). The toggle:

1. User clicks `#theme-toggle` button → `lightbox.js` `setTheme(theme)` (`lightbox.js:98-101`).
2. Function flips `document.documentElement.setAttribute('data-theme', theme)`, persists to `localStorage`, updates `#theme-icon` / `#theme-label` text, re-runs Mermaid with the new theme palette via `renderAllDiagrams()` and `initMermaid(theme)` (`lightbox.js:75-96`).
3. Mermaid theme variables for each mode are defined inline in `lightbox.js:31-60` (`mermaidThemeFor(theme)`).

Initial theme on first load:
1. Read `localStorage.kb-theme` (`lightbox.js:14-17`).
2. If missing, fall back to `window.matchMedia('(prefers-color-scheme: dark)').matches`.
3. Default to `light` if no prefers-color-scheme.

### 4.3 Reduced motion and forced colors

Two media queries handle accessibility automation:

- `@media (prefers-reduced-motion: reduce)` per `accessibility-checklist.md:57-62` — disables animations, transitions, smooth scroll, card hover transform.
- `@media (forced-colors: active)` per `accessibility-checklist.md:64-66` — preserves borders on cards, callouts, accordions; uses `forced-color-adjust: none` only where critical (status badges).

These are auto-verified by the validation pipeline (see §8 below).

---

## 5. Routing & Navigation

There is **no router** — the HTML output is a single page. Navigation is intra-page:

| Mechanism | Implementation |
|---|---|
| **Skip link** | `<a class="skip-link" href="#top">` → jumps to `<main id="top">` (focused-only via CSS). |
| **TOC links** | Generated in `{{BODY_CONTENT}}`; hash-anchors to per-section ids. CSS `html { scroll-behavior: smooth; scroll-padding-top: 80px; }` (`component-css.css:67`) accounts for the sticky top bar. |
| **Breadcrumb scrollspy** | `lightbox.js` updates `#breadcrumb-current` text to reflect the section currently in view as the user scrolls. Implementation lives inside the `lightbox.js` IIFE (see `aid-summarize/SKILL.md:7-8` skill description: "breadcrumb scrollspy"). |
| **Lightbox open/close** | URL is not modified. Lightbox state is purely DOM-class-based (`.lightbox.open`). |

No route guards, no auth — the document is static and unauthenticated.

---

## 6. Responsive & Adaptive

The generated HTML is **responsive via viewport meta + relative units**, not via a CSS framework or explicit breakpoints documented in `design-tokens.md`.

| Mechanism | Source |
|---|---|
| Viewport | `<meta name="viewport" content="width=device-width, initial-scale=1.0">` at `html-skeleton.html:5` |
| Text sizing | `accessibility-checklist.md:108`: *"All sizes use `rem` or relative units, not fixed `px` for text."* Confirmed in `component-css.css` font sizes: `h1 { font-size: 2.2rem }`, `h2 { 1.5rem }`, `h3 { 1.15rem }`, body line-height: 1.55. |
| Mermaid scaling | `mermaid-init.js:48-50`: `flowchart: { useMaxWidth: true }`, `er: { useMaxWidth: true }`, `sequence: { useMaxWidth: true }`. Diagrams shrink to fit their containers. |
| Sticky top bar | `position: sticky; top: 0; z-index: 100;` at `component-css.css:91-103`. Survives all viewport widths. |
| Code blocks / wide tables | `accessibility-checklist.md:105`: "Layout remains usable at 200% zoom (no horizontal scroll except in code blocks / wide tables)." Implies horizontal scroll is allowed for those two element types only. |

⚠️ **Inferred from code — needs confirmation.** No explicit breakpoint variables (`@media (max-width: 768px) { ... }`) appear in the head of `component-css.css:1-120`. Strategy is implicitly **mobile-first via fluid layout**, but a deeper read of the remaining CSS lines would be needed to confirm there are no hidden media queries lower down. The discovery brief targets a summary; deferring to a future read.

---

## 7. Accessibility

`templates/knowledge-summary/accessibility-checklist.md` (125 lines) is the authoritative checklist. Target: **WCAG 2.1 AA**.

### 7.1 What is verified automatically (`[auto]`)

Per `accessibility-checklist.md:7-9`, items marked `[auto]` are checked by `scripts/grade.sh`, `scripts/contrast-check.mjs`, `scripts/validate-html.sh`. Items marked `[manual]` are inspected by the agent during the VALIDATE mode of `aid-summarize`.

| Auto-checked area | Specifics |
|---|---|
| Document level | `<html lang="...">`, `<meta name="color-scheme" content="light dark">`, descriptive `<title>`, `<noscript>` block with KB links |
| Landmarks | `<header role="banner">`, `<main id="top">`, `<nav aria-label="...">`, `<footer>` |
| Skip link | First focusable element is `<a class="skip-link" href="#top">` |
| Focus visibility | `:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px }` in CSS |
| Lightbox dialog | `role="dialog" aria-modal="true"`, `aria-labelledby="lb-caption"`, `aria-hidden` toggled, all toolbar buttons have `aria-label` |
| Diagrams | Each `<div class="mermaid-box">` has `role="button"`, `tabindex="0"`, `aria-label` |
| Reduced motion | `@media (prefers-reduced-motion: reduce)` block in CSS |
| Forced colors | `@media (forced-colors: active)` block in CSS |
| Color contrast | All 11 token pairs at `accessibility-checklist.md:84-96` verified ≥ 4.5:1 (body text) or ≥ 3:1 (large text / UI components), per WCAG AA, in **both light and dark themes** |
| Live regions | `aria-live="polite"` for lightbox caption updates |

### 7.2 What is checked manually (`[manual]`)

- Tab order matches visual order.
- Focus moves into the lightbox dialog when opened (close button by default); cycles within (focus trap); returns to originator on close.
- 44 × 44 px minimum hit area for all interactive controls.
- Heading hierarchy correct (no skipped levels).

### 7.3 Explicit non-goals

`accessibility-checklist.md:121-125` declares the following as deliberately out of scope:

- Touch-zoom in the lightbox (browser-native pinch zoom is not overridden).
- Voice control (relies on the browser accessibility tree; landmarks suffice).
- RTL languages (out of scope for v1; doc flow assumes LTR).
- High-contrast theme variant (`forced-colors` mode handles this at the OS level).

---

## 8. Build & Bundle

### 8.1 No bundler

There is no Vite, Webpack, Rollup, esbuild, Turbopack, or Parcel anywhere in this repository. The generated `knowledge-summary.html` is **assembled by shell scripts at runtime on the user's machine**, not pre-built at repo time.

### 8.2 The generation pipeline

Per `aid-summarize/SKILL.md` GENERATE mode (`:159-200`) and the scripts in `templates/knowledge-summary/scripts/`:

```
                                ┌──────────────────────────────┐
                                │  templates/knowledge-summary/│
                                │   html-skeleton.html         │
                                │   component-css.css          │
                                │   lightbox.js                │
                                │   section-templates/*.md     │
                                │   accessibility-checklist.md │
                                └──────────────────────────────┘
                                              │
                                              ▼
   .aid/knowledge/*.md  ────►  aid-summarize GENERATE mode (skill body)
                                              │
                                              ▼
                              ┌──────────────────────────────────┐
                              │  fetch-mermaid.sh                │
                              │  (download latest if cache stale)│
                              └──────────────────────────────────┘
                                              │
                                              ▼
                              ┌──────────────────────────────────┐
                              │  concatenate.sh / concatenate.ps1│
                              │  (inline CSS + JS + Mermaid into │
                              │   the html-skeleton)             │
                              └──────────────────────────────────┘
                                              │
                                              ▼
                                 knowledge-summary.html
                                 (single self-contained file)
                                              │
                                              ▼
                              ┌──────────────────────────────────┐
                              │  VALIDATE mode:                  │
                              │  validate-html.sh                │
                              │  validate-links.sh               │
                              │  validate-diagrams.mjs (mmdc)    │
                              │  contrast-check.mjs              │
                              │  grade.sh (computes letter grade)│
                              └──────────────────────────────────┘
                                              │
                                              ▼
                                       APPROVAL → WRITEBACK → DONE
```

### 8.3 Code splitting / lazy loading

**None.** Everything is inlined. There is exactly one HTTP response (the HTML file). No deferred chunks, no dynamic imports, no service worker, no preload / prefetch hints.

### 8.4 Performance budget

No explicit budget declared. Practical implications of the inline-everything design:

- The HTML output carries the entire Mermaid library inline (~3 MB unminified, ~600 KB minified per typical Mermaid 11.x distribution).
- `--cdn-mermaid` flag (`aid-summarize/SKILL.md:51`) lets the user opt out: load Mermaid from `https://cdn.jsdelivr.net/npm/mermaid@{ver}/dist/mermaid.min.js` instead, which drops ~3 MB but loses offline support.

---

## 9. The deliberate "single offline HTML" constraint

The hardest design constraint on this UI is: **the output must be a single offline HTML file that works without any network at view time** (per `aid-summarize/SKILL.md:14-20`):

> Generates a single self-contained knowledge-summary.html... The output works fully offline, includes 8 Mermaid diagrams (or fewer for non-web-app profiles), supports light/dark themes, provides keyboard-accessible click-to-expand lightboxes for every diagram, and meets WCAG AA contrast in both themes.

### Architectural implications

| Constraint | Implication |
|---|---|
| **Single file** | No `<link rel="stylesheet">`, no `<script src="...">` to local files. Everything is inlined via `{{INLINE_CSS}}` / `{{INLINE_LIGHTBOX_JS}}` placeholders and the concatenation scripts. |
| **Offline at view time** | Mermaid library is inlined as text inside `<script>` blocks; no CDN URLs in production output (unless `--cdn-mermaid` flag is passed). Fonts use the system-font stack (`-apple-system, BlinkMacSystemFont, "Segoe UI", Inter, Roboto, "Helvetica Neue", Arial, sans-serif` at `component-css.css:70`). No `@font-face` imports. |
| **Mermaid offline** | `mermaid-init.js:46-50` sets `startOnLoad: false`, `securityLevel: 'loose'`; lightbox.js calls `mermaid.run()` manually after init, so diagrams render after the inlined library is parsed. |
| **No analytics, no telemetry** | The output cannot phone home — there is no network at view time. `<meta name="robots" content="noindex">` at `html-skeleton.html:9` deliberately keeps the page out of search indexes. |
| **Idempotent regeneration** | The skill compares KB mtime vs last summary mtime in STALE-CHECK mode (`aid-summarize/SKILL.md:99-119`). Re-running on an unchanged KB is a no-op. |

---

## 10. Mermaid Handling

| Aspect | Detail |
|---|---|
| Library version | Pinned per generation. Tracked at `.aid/knowledge/SUMMARY-STATE.md` as `**Mermaid Version:**`, `**Mermaid Fetched At:**`, `**Mermaid Cached:**` (per `aid-summarize/SKILL.md:178-186`). |
| Source | `https://cdn.jsdelivr.net/npm/mermaid@{ver}/dist/mermaid.min.js`, with version discovered from `https://registry.npmjs.org/mermaid/latest`. |
| Local cache | `.aid/knowledge/.cache/mermaid.min.js` + `.meta` (sha256 + timestamp). |
| Inline placement | At `html-skeleton.html:89-94`, BEFORE the lightbox.js IIFE so `window.mermaid` is defined when `initMermaid()` runs. |
| Init flags | `startOnLoad: false`, `securityLevel: 'loose'`, font from the system stack, `useMaxWidth: true` for flowchart / er / sequence (per `mermaid-init.js:44-50` and `lightbox.js:65-72`). |
| Re-render on theme toggle | `lightbox.js renderAllDiagrams()` — re-stashes the raw source via `data-source`, removes `data-processed`, calls `mermaid.run()` again. Uses `textContent`, never `innerHTML`, because `innerHTML` re-parses any `<token>` in diagram text as an HTML element and silently corrupts the source (see comment at `lightbox.js:85-90`). |
| Supported diagram types | Documented in `templates/knowledge-summary/mermaid-examples.md` (187 lines). |
| Quality gate | `validate-diagrams.mjs` (294 lines) attempts to render every Mermaid block via Mermaid CLI (`mmdc`); failure to parse or render blocks any grade higher than F per `templates/knowledge-summary/grading-rubric.md` (226 lines). |

---

## 11. The other "UI" surfaces (and why they don't count)

For completeness, the following surfaces exist but are **not UI architecture in any meaningful sense**:

| Surface | What it is | Why it's not UI architecture |
|---|---|---|
| `setup.sh` / `setup.ps1` interactive menu | A numbered terminal prompt (1=Claude Code, 2=Codex, 3=Cursor, 4=Install, 5=Quit) | Plain `echo` + `read` in Bash / `Read-Host` in PowerShell. No layout, no styling, no state machine. ~30 lines combined. |
| Slash-command output (per skill) | Markdown that the host AI tool renders in its chat panel | The host tool's chat UI does the rendering; AID supplies content, not presentation. |
| The `[State: GENERATE]` / `[State: REVIEW]` markers printed by skills | Plain stdout strings | Diagnostic markers for the user; not a UI element. |
| The knowledge-summary `<noscript>` block | Static HTML inside the generated page | Accessibility fallback only — not interactive. |

None of these have framework, component, state, routing, theming, or accessibility-architecture decisions to document.

---

## 12. Cross-references

- File counts for HTML / CSS / JS: `technology-stack.md` §4-6 and `project-index.md` Language Breakdown lines 21, 22, 25.
- Where the knowledge-summary assets live across the four trees (root + three install trees): `project-structure.md ## Templates` lines 170-172.
- Skill that drives the generation: `profiles/claude-code/.claude/skills/aid-summarize/SKILL.md` (430 lines).
- The `aid-summarize` 9-state state machine: `architecture.md` Pattern 1.
- Validation scripts (the runtime "tests" of the UI): `technology-stack.md` §2, §4.
- Design-tokens-vs-CSS drift open question: `DISCOVERY-STATE.md` Q14.
