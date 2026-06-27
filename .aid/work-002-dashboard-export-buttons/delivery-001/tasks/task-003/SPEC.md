# task-003: Export behaviors + §7 Playwright visual gate + a11y/theme

**Type:** TEST

**Source:** work-002-dashboard-export-buttons → delivery-001

**Depends on:** task-001, task-002

**Scope:**
- Generate a fresh `kb.html` from the updated canonical templates + GENERATE path and verify it
  via the §7 Playwright visual-fidelity gate
  (`canonical/aid/scripts/summarize/validate-visuals.mjs` and the companion
  validate/contrast checks). Visual validation is mandatory: Playwright must render + screenshot
  the page — source inspection alone is an automatic fail.
- Verify: (a) **Export Markdown** downloads a `.md` whose content faithfully reflects the summary
  with inline `data:` URI images; (b) **Export PDF** — since `window.print()` opens a native
  dialog Playwright cannot assert against, verify the print *stylesheet* via
  `page.emulateMedia({ media: 'print' })` + screenshot (nav/toc/buttons hidden, `<details>`
  opened by the print handler, light rendering even when the page was in dark theme, section
  page-breaks); (c) both buttons are keyboard-operable and theme-aware at WCAG AA in light and
  dark; (d) `kb.html` remains a single self-contained file (self-containment allowlist, no
  external fetch) and the existing visuals / §7 gate still pass.

**Acceptance Criteria:**
- [ ] Playwright renders the generated `kb.html`, exercises both export buttons, and screenshots confirm behavior in light and dark themes. (work SPEC AC1, AC2, AC5)
- [ ] Exported Markdown content matches the summary (headings, paragraphs, tables, lists) with inline data-URI images, and every embedded image carries `alt` text so a data-URI-blind viewer degrades gracefully. (work SPEC AC3, AC4)
- [ ] The print stylesheet behavior is verified under `emulateMedia({ media: 'print' })` + screenshot: nav/toc/buttons hidden, `<details>` opened, forced-light rendering from a dark starting theme, and section page-breaks. (work SPEC AC2)
- [ ] The self-containment allowlist holds (no external fetch), the refined NM.1 anti-Mermaid check passes on the >100 KB Markdown payload, and the pre-existing §7 visuals still pass. (work SPEC AC6)
- [ ] All applicable project quality gates pass — `tests/run-all.sh` and the `/aid-summarize` validators including the §7 visual-fidelity gate. (work SPEC AC8)
