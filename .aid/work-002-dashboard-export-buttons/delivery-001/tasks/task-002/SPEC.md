# task-002: Client-side export chrome (buttons + Blob download + print-CSS)

**Type:** IMPLEMENT

**Source:** work-002-dashboard-export-buttons → delivery-001

**Depends on:** task-001

**Scope:**
- Add two export buttons to the `kb.html` chrome near the theme toggle
  (`canonical/aid/templates/knowledge-summary/html-skeleton.html` `.controls` block),
  keyboard-accessible, theme-aware, and styled consistently with the existing chrome (WCAG AA).
- **Export Markdown:** JS that reads the hidden Markdown payload element defined by task-001 →
  builds a `Blob` → triggers a `.md` download.
- **Export PDF:** a `window.print()` handler plus print styling in
  `canonical/aid/templates/knowledge-summary/component-css.css`. An `@media print` block
  **already exists** there (~lines 577-583: hides `.top-bar`/`.controls`/`.lightbox`,
  `page-break-inside:avoid`, `body{background:white;color:black}`) — **extend/reconcile that block
  in place** (do NOT add a second one) so it also (a) forces light theme by overriding the
  `[data-theme="dark"]` CSS variables that still cascade to cards/callouts, and (b) inserts
  page-breaks BETWEEN top-level sections. Because CSS alone cannot reliably reveal closed
  `<details>`, the **print handler JS must set `open` on all `<details>` (incl. `details.accord`)
  before `window.print()`** (and may restore prior state afterward). No new dependency, no binary
  payload.
- Mirror the chrome/skeleton injection into the GENERATE scaffolding prose
  (`canonical/skills/aid-summarize/references/state-generate.md`) so canonical stays the durable
  source and a fresh `kb.html` ships both buttons by default.

**Acceptance Criteria:**
- [ ] Clicking **Export Markdown** in a generated `kb.html` downloads a `.md` file with the full payload content. (work SPEC AC1)
- [ ] The print handler opens all `<details>` (incl. `details.accord`) before calling `window.print()`. (work SPEC AC2)
- [ ] The reconciled `@media print` block (single block, extended in place) hides nav/toc/buttons, overrides the dark-theme CSS variables to force light rendering, and page-breaks between top-level sections. (work SPEC AC2)
- [ ] Both buttons are keyboard-focusable/operable and theme-aware (light/dark) at WCAG AA, consistent with the existing chrome. (work SPEC AC5)
- [ ] A fresh `kb.html` generated from the updated canonical templates ships both buttons by default and remains a single self-contained file. (work SPEC AC6, AC7)
- [ ] All applicable project quality gates pass (`tests/run-all.sh`, the `/aid-summarize` validators including the §7 visual-fidelity gate).
