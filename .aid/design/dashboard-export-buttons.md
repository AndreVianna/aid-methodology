# Design seed — Export buttons (Markdown / PDF) for the KB summary

> **Status:** NOT STARTED — backlog item, captured 2026-06-26. Small, self-contained
> follow-up on top of the feature-015 `/aid-summarize` redesign. Off the work-001 critical
> path; can be its own small work (likely lite-path).

## Problem / intent

`kb.html` (the dashboard KB visual summary, produced by `/aid-summarize`) is currently a
read-only on-screen artifact. Users want to take it out of the browser:

- **Export to PDF** — a print-ready, shareable snapshot of the summary.
- **Export to Markdown** — a plain-text / re-editable form of the summary content.

Add two buttons to the `kb.html` chrome (near the theme toggle) that trigger these exports.

## Approach sketch (to be specified, not yet decided)

- **PDF** — cheapest path is `window.print()` driven by a dedicated `@media print`
  stylesheet (hide nav/toc/buttons, expand all `details`, force light theme, page-break
  between sections). No new dependency, fully offline, respects the single-self-contained-file
  guardrail. A heavier alternative (client-side lib like jsPDF/html2pdf) is likely overkill
  and would inflate the file — avoid unless print-CSS proves insufficient.
- **Markdown** — two candidate sources:
  1. **Reconstruct from the DOM** at click time (walk sections → headings/paragraphs/tables/
     lists → Markdown), download via a Blob. Keeps `kb.html` self-contained.
  2. **Embed the source Markdown** (the `.aid/knowledge/*.md` the summary was built from) as
     a hidden payload at GENERATE time, and just serve it. Simpler export, but bloats the file
     and duplicates KB content into the dashboard — likely violates self-containment intent.
  Lean option 1 (DOM→MD) to preserve self-containment.

## Guardrails to respect (from feature-015)

- `kb.html` stays a **single self-contained file** (dashboard self-containment allowlist) — no
  external fetches, no large embedded engines. The Mermaid 3 MB engine was just dropped; do not
  re-inflate.
- The **§7 visual-fidelity gate** (Playwright) and the existing visuals must still pass.
- Buttons must be keyboard-accessible + theme-aware, consistent with the existing chrome.

## Where it lands

- Generation: `canonical/aid/templates/knowledge-summary/` (skeleton + component-css +
  lightbox.js) and the `/aid-summarize` GENERATE path — so every generated `kb.html` ships the
  buttons. (Targeted-edit precedent exists via `summary-src/` + `assemble.sh`, but the durable
  home is the canonical templates so a fresh GENERATE includes them.)

## Open questions

- PDF: print-CSS only, or is a richer paginated layout wanted?
- Markdown: faithful section text only, or also a machine-readable export (front-matter/links)?
- Scope: `kb.html` only, or also the other dashboard surfaces (`home.html`/`index.html`)?
