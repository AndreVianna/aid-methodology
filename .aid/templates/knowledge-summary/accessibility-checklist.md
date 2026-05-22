# Accessibility Checklist (WCAG AA)

Every `/aid-summarize` output must meet these criteria. The grading script
(`scripts/grade.sh`) automates verification of items marked **[auto]**;
items marked **[manual]** are inspected by the agent during VALIDATE.

## Document level

- **[auto]** `<html lang="...">` — set to project's primary language (default `en`).
- **[auto]** `<meta name="color-scheme" content="light dark">` — informs native
  UI elements (scrollbars, form controls).
- **[auto]** `<title>` is descriptive: `{Project} — Knowledge Base Summary`.
- **[auto]** `<noscript>` block present with link to `.aid/knowledge/INDEX.md`.

## Landmarks (semantic HTML)

- **[auto]** `<header role="banner">` for the top bar.
- **[auto]** `<main id="top">` for the primary content (skip-link target).
- **[auto]** `<nav aria-label="...">` for navigation regions.
- **[auto]** `<footer>` for the page footer.
- **[manual]** No more than one `<main>` per page.
- **[manual]** All form controls have associated labels.

## Skip link

- **[auto]** First focusable element in the DOM is `<a class="skip-link" href="#top">Skip to content</a>`.
- **[manual]** It becomes visible on focus (CSS handles).

## Keyboard reach

- **[manual]** All interactive elements (theme toggle, TOC links, accordion
  summaries, mermaid boxes) are reachable via Tab.
- **[manual]** Tab order matches visual order.
- **[auto]** `:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px }`
  is present in the inlined CSS.
- **[manual]** No focus traps outside the lightbox.

## Lightbox dialog

- **[auto]** `role="dialog" aria-modal="true"` on the lightbox container.
- **[auto]** `aria-labelledby="lb-caption"` (or equivalent).
- **[auto]** `aria-hidden="true"` when closed; `false` when open.
- **[manual]** Focus moves into the dialog when opened (close button by default).
- **[manual]** Tab cycles within the dialog (focus trap).
- **[manual]** Focus returns to the originating element on close.
- **[auto]** All toolbar buttons have `aria-label`.
- **[manual]** `Escape` closes; tested by clicking-then-Esc.

## Diagrams

- **[auto]** Each diagram-bearing `<div class="mermaid-box">` has `role="button"`,
  `tabindex="0"`, and `aria-label` summarizing the diagram.
- **[manual]** Each cloned SVG in the lightbox has `role="img"` and
  `aria-label` matching its caption.

## Reduced motion

- **[auto]** `@media (prefers-reduced-motion: reduce)` block present in CSS that:
  - Sets `animation-duration: 0.01ms !important`
  - Sets `transition-duration: 0.01ms !important`
  - Disables `scroll-behavior: smooth`
  - Disables card hover transform

## Forced colors (Windows High Contrast)

- **[auto]** `@media (forced-colors: active)` block preserves borders on cards,
  callouts, accordions; uses `forced-color-adjust: none` only where critical
  (status badges).

## Color contrast (WCAG AA)

Verified by `scripts/contrast-check.mjs`. Targets:

- **[auto]** Body text vs background ≥ **4.5:1** (normal text).
- **[auto]** Large text (≥ 18.66 px bold or ≥ 24 px) ≥ **3:1**.
- **[auto]** Interactive components (buttons, focus rings) ≥ **3:1** vs adjacent
  background.
- **[auto]** Non-text UI: link/icon ≥ **3:1**.

Both light and dark themes must pass independently.

### Specific token pairs to verify

| Pair | Min ratio |
|---|---|
| `--text` on `--bg` | 4.5:1 |
| `--text-muted` on `--bg` | 4.5:1 |
| `--text-dim` on `--bg-elev` | 4.5:1 |
| `--accent` on `--bg-elev` (link color) | 4.5:1 |
| `--primary-fg` on `--primary` | 4.5:1 |
| `--accent-fg` on `--accent` | 4.5:1 |
| `--ok` on `--ok-bg` (badge text) | 4.5:1 |
| `--warn` on `--warn-bg` | 4.5:1 |
| `--err` on `--err-bg` | 4.5:1 |
| `--info` on `--info-bg` | 4.5:1 |
| `--purple` on `--purple-bg` | 4.5:1 |

## Touch targets

- **[manual]** Minimum 44 × 44 px hit area for interactive controls (buttons,
  TOC links, theme toggle).

## Text resizing

- **[manual]** Layout remains usable at 200% zoom (no horizontal scroll except
  in code blocks / wide tables).
- **[auto]** All sizes use `rem` or relative units, not fixed `px` for text.

## Screen reader announcement

- **[auto]** `<span aria-live="polite">` or `aria-live` region for dynamic
  content (lightbox caption updates).
- **[manual]** Heading hierarchy is correct (no skipped levels: h1 → h2 → h3).

## Forms (if present)

- **[manual]** Every input has a `<label for="..."`> or `aria-label`.
- **[manual]** Error messages are associated via `aria-describedby`.

## What this skill does NOT need to handle

- **Touch-zoom in lightbox** — pinch zoom is browser-native; we don't override.
- **Voice control** — relies on browser accessibility tree; landmarks suffice.
- **RTL languages** — out of scope for v1; doc flow assumes LTR.
- **High-contrast theme variant** — `forced-colors` mode handles this at OS level.
