# State: VALIDATE

VALIDATE runs the machine-verifiable quality checks (coverage, diagrams, links, HTML, contrast) to compute the Machine Grade; it is selected after GENERATE completes and again after FIX.

▶ validation suite starting (~1.5 min total — 3 scripts × ~30 s each per `canonical/templates/rough-time-hints.md`)
Run `canonical/scripts/summarize/grade-summary.sh .aid/dashboard/kb.html`. It orchestrates the AUTO_POOL (machine-verifiable) checks only:

1. **`canonical/scripts/summarize/validate-diagrams.mjs`** — D1/D2: Mermaid-specific checks; **trivially passed when no Mermaid blocks are present in the generated HTML** (no penalty for zero Mermaid blocks — the diagram-count cap is removed). D1: parses each `<pre class="mermaid">` block; D2: renders each block via `jsdom` + Mermaid and asserts the SVG is non-trivial (>500 bytes, contains `<g>` or `<path>`, no `mermaid-error` marker). If `jsdom` is unavailable, D2 falls back to parse-only. Mermaid blocks are optional in D-011; the engine is retired in D-012.
2. **`canonical/scripts/summarize/validate-html-output.sh`** — single invocation that performs link-integrity AND HTML structural/a11y checks: L1/L2 (anchor and `./*.md` link integrity), H1 (tidy → html-validate → regex cascade — script picks the most rigorous tool available and prints which), A1/A2/A4/A5 (semantic landmarks, lightbox ARIA, reduced-motion, focus-visible), S2 (offline render — verifies the page is self-contained; trivially passed when no Mermaid blocks are present). **A3 (focus trap)** is auto-detected via `grep` of the inlined `lightbox.js` for the markers `trapFocusOnTab`, `lastFocused.focus()`, `key === 'Escape'`.
3. **`canonical/scripts/summarize/contrast-check.mjs`** — C1/C2: WCAG ratios for both themes.

✓ validation suite done (record actual time, per-script pass/fail summary) — or ✗ validation suite failed: {script, reason}

### Translate Script Output to Schema Rows

After each script exits, the orchestrator translates failed checks into schema rows in
`.aid/.temp/review-pending/summarize.md` (per `canonical/templates/reviewer-ledger-schema.md`):

| Script check | Severity mapping |
|---|---|
| COV (resolved-doc-set coverage < 60%) | `[CRITICAL]` — automatic F on Machine Grade; one row |
| D1 (diagram parse fail — only when Mermaid blocks present) | `[HIGH]` — one row per failing diagram |
| D2 (diagram renders trivially / as error SVG — only when Mermaid blocks present) | `[HIGH]` — one row per failing block |
| L1 (broken anchor links) | `[HIGH]` — one row per broken link |
| L2 (broken .md links) | `[HIGH]` — one row per broken path |
| H1 (HTML validity failure) | `[HIGH]` — one row per reported error |
| A1/A2/A4/A5 (missing ARIA / landmarks / reduced-motion / focus-visible) | `[MEDIUM]` — one row per check |
| A3 (focus trap missing) | `[MEDIUM]` — one row |
| S2 (offline render: page not self-contained — only when Mermaid blocks present) | `[HIGH]` — one row |
| C1/C2 (WCAG contrast fail) | `[MEDIUM]` — one row per failing color pair |

For each failed check, append a row:
- `#` = next sequential row number
- `Severity` = per mapping above (bracketed)
- `Status` = `Pending`
- `Doc` = `kb.html`
- `Line` = `—` (or nearest section if identifiable)
- `Description` = one sentence: "check X failed: {what was wrong}"
- `Evidence` = script output excerpt or exact error message

Passed checks are NOT added to the ledger (no row = no finding).

Persist Machine Grade + per-check table to `.aid/knowledge/STATE.md` `## Knowledge Summary Status` `### Findings (last validation — Machine)`. Grade is computed by running:

```bash
bash canonical/scripts/grade.sh --explain .aid/.temp/review-pending/summarize.md
```

If Machine Grade ≥ minimum → MANUAL-CHECKLIST. Otherwise → FIX.

Print: `[State: VALIDATE] complete.`

**Advance:** **CHAIN** → [State: MANUAL-CHECKLIST] if Machine Grade ≥ minimum; **CHAIN** → [State: FIX] otherwise. Both continue inline.
