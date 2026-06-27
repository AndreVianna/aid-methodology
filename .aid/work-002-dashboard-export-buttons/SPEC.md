# KB Summary Export (Markdown / PDF)

- **Name:** KB Summary Export (Markdown / PDF)
- **Description:** Add downloadable Markdown and PDF exports of the kb.html KB summary, with optimized Markdown pre-generated at build time and PDF produced on demand via print-CSS
- **Work:** work-002-dashboard-export-buttons
- **Created:** 2026-06-26
- **Source:** /aid-interview lite path — LITE-FEATURE
- **Status:** Ready

## Goal

Add the capacity to export the full content of the `kb.html` KB summary as downloadable
files in the user's choice of **Markdown** or **PDF** format. The summary is currently a
read-only on-screen artifact; this feature lets users take it out of the browser — a
re-editable Markdown form and a print-ready PDF snapshot — generated from the kb.html page
and downloaded on demand.

## Context

**Scope (approach [A] — split by format, chosen during intake):**

- Two export buttons added to the `kb.html` chrome (near the theme toggle), keyboard-accessible
  and theme-aware, styled consistently with the existing chrome.
- **Markdown — pre-generated & embedded.** At `/aid-summarize` GENERATE time, optimized
  Markdown is built directly from the source `.aid/knowledge/*.md` documents (not scraped from
  the DOM) and embedded in `kb.html` as a hidden text payload. The **Export Markdown** button
  downloads that payload via a Blob. Images are embedded inline as `data:` URIs (inline SVGs
  converted to data URIs) so the export is a single portable `.md` file — no separate image
  files, no zip.
- **PDF — on-the-fly via print-CSS.** The **Export PDF** button's handler opens all `<details>`
  (setting `open` in JS, since CSS alone cannot reveal closed `<details>`) and then calls
  `window.print()`, which is driven by an `@media print` stylesheet that hides nav/toc/buttons,
  forces light theme, and inserts page-breaks between sections. No new runtime dependency, no
  binary payload.
- **Where it lands.** Durable home is `canonical/aid/templates/knowledge-summary/` (skeleton +
  component-css + lightbox.js) and the `/aid-summarize` GENERATE path, so every generated
  `kb.html` ships both buttons and the embedded Markdown payload by default. (See KB
  `module-map.md` and `capability-inventory.md` for the dashboard/summary generation pipeline.)

**Guardrails carried from feature-015 (the `/aid-summarize` redesign):**

- `kb.html` stays a **single self-contained file** (dashboard self-containment allowlist) — no
  external fetches, no large embedded engines (the Mermaid 3 MB engine was just dropped; do not
  re-inflate). Embedded Markdown text is acceptable; a binary PDF/zip payload is not — hence the
  format split above.
- The **§7 Playwright visual-fidelity gate** and the existing visuals must still pass.

**Seed:** `.aid/design/dashboard-export-buttons.md`.

## Acceptance Criteria

- [ ] Given a generated `kb.html` open in a browser, when the user clicks **Export Markdown**, then a `.md` file containing the full, optimized KB-summary content is downloaded to their machine.
- [ ] Given a generated `kb.html`, when the user clicks **Export PDF**, then the handler opens all `<details>` and the browser print dialog opens with a print stylesheet that hides nav/toc/buttons, forces light theme, and page-breaks between sections.
- [ ] Given the exported Markdown, when it is opened, then its content faithfully reflects the KB summary (headings, paragraphs, tables, lists) and is generated from the `.aid/knowledge/*.md` source, not scraped from the DOM.
- [ ] Given the KB summary contains images, when the Markdown is exported, then each image is embedded inline as a `data:` URI (inline SVGs converted to data URIs) so the result is a single portable `.md` file — no separate image files and no zip; viewers without data-URI support degrade gracefully to alt text.
- [ ] Given the two new buttons, when navigating by keyboard or toggling light/dark theme, then they are focusable, operable, and styled consistently with the existing chrome (theme-aware, WCAG AA).
- [ ] Given the generated `kb.html`, when it is inspected, then it remains a single self-contained file (no external fetches, no large embedded engine) and the §7 Playwright visual-fidelity gate still passes.
- [ ] Given the canonical templates and `/aid-summarize` GENERATE path, when a fresh `kb.html` is generated, then it ships both buttons and the embedded Markdown payload by default.
- [ ] All applicable project quality gates pass: the canonical test suite `tests/run-all.sh` and the `/aid-summarize` validators (including the §7 Playwright visual-fidelity gate and the `validate-html-output.sh` self-containment check).

## Tasks

> Tasks live under `delivery-001/tasks/task-NNN/SPEC.md`; each task folder also contains
> `STATE.md` for mutable task state. The table below is the navigational index.

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Generation-time Markdown export payload |
| task-002 | IMPLEMENT | Client-side export chrome (buttons + Blob download + print-CSS) |
| task-003 | TEST | Export behaviors + §7 Playwright visual gate + a11y/theme |

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | task-001 |
| task-003 | task-001, task-002 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
| 2 | task-002 |
| 3 | task-003 |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-06-26 | Initial lite-path SPEC created | /aid-interview LITE-FEATURE |
