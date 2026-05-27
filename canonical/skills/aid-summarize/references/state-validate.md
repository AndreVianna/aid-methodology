# State: VALIDATE

VALIDATE runs the machine-verifiable quality checks (diagrams, links, HTML, contrast) to compute the Machine Grade; it is selected after GENERATE completes and again after FIX.

▶ validation suite starting (~1.5 min total — 3 scripts × ~30 s each per `canonical/templates/rough-time-hints.md`)
Run `canonical/scripts/summarize/run-validators.sh .aid/knowledge/knowledge-summary.html`. It orchestrates the AUTO_POOL (machine-verifiable) checks only:

1. **`canonical/scripts/summarize/validate-diagrams.mjs`** — D1: extracts every `<pre class="mermaid">` block, parses each via `mermaid.parse()`. **Any failure = automatic F.** D2: renders each block via `jsdom` + Mermaid and asserts the SVG is non-trivial (>500 bytes, contains `<g>` or `<path>`, no `mermaid-error` marker). If `jsdom` is unavailable, D2 falls back to parse-only and the output flags `D2: jsdom-fallback`.
2. **`canonical/scripts/summarize/validate-html-output.sh`** — single invocation that performs link-integrity AND HTML structural/a11y checks: L1/L2 (anchor and `./*.md` link integrity), H1 (tidy → html-validate → regex cascade — script picks the most rigorous tool available and prints which), A1/A2/A4/A5 (semantic landmarks, lightbox ARIA, reduced-motion, focus-visible), S2 (Mermaid library inlined). **A3 (focus trap)** is auto-detected via `grep` of the inlined `lightbox.js` for the markers `trapFocusOnTab`, `lastFocused.focus()`, `key === 'Escape'`.
3. **`canonical/scripts/summarize/contrast-check.mjs`** — C1/C2: WCAG ratios for both themes.
4. Computes the Machine Grade from the AUTO_POOL tally + per-profile diagram-count enforcement (reads `target_diagrams: N` from the active profile template; caps at C+ if `actual < target`). **Does NOT compute a final Overall Grade** — that requires Human Grade too.

✓ validation suite done (record actual time, per-script pass/fail summary) — or ✗ validation suite failed: {script, reason}

Persist Machine Grade + per-check table to `.aid/knowledge/STATE.md` `## Knowledge Summary Status` `### Findings (last validation — Machine)`.

If Machine Grade ≥ minimum → MANUAL-CHECKLIST. Otherwise → FIX.

Print: `[State: VALIDATE] complete.`

**Advance:** Next: [State: MANUAL-CHECKLIST] — run /aid-summarize again
