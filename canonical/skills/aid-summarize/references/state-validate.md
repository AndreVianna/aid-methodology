# State: VALIDATE

VALIDATE runs the machine-verifiable quality checks (coverage, visual fidelity, links, HTML, contrast) to compute the Machine Grade; it is selected after GENERATE completes and again after FIX.

▶ validation suite starting (~1.5 min total — 3 scripts × ~30 s each per `canonical/aid/templates/rough-time-hints.md`)
Run `canonical/aid/scripts/summarize/grade-summary.sh .aid/knowledge/kb.html`. It orchestrates the AUTO_POOL (machine-verifiable) checks only:

1. **`canonical/aid/scripts/summarize/validate-visuals.mjs`** — **S7 visual-fidelity gate (FR-51):** Playwright-renders `kb.html` in a headless Chromium browser (offline, `file://` URL, no network) and asserts, for every authored visual (inline `<svg>` / `.diagram-box` / infographic container):
   - **T1 — Readable text:** every visible text node inside the visual has a computed font-size >= 10 px and is NOT overflow-clipped to zero height.
   - **T2 — Minimal/zero overlap:** the bounding boxes of the visual's child elements do not materially overlap each other (tolerance: <= 20% of the smaller element's area).
   - **T3 — Correct basic layout:** the visual's own bounding rect has non-trivial dimensions (width > 0 AND height > 0) — the visual is rendered, not collapsed or empty.
   A visual that fails any of T1/T2/T3 is a **generation defect that blocks DONE** (same rigor as the old "no broken diagram" guarantee). Exit non-zero = defect; fix in GENERATE before continuing.
   **Visual-inspection fallback:** if Playwright is not installed, `validate-visuals.mjs` exits 0 with a SKIP message listing the visuals that require manual inspection. In this case, the **MANUAL-CHECKLIST V1 human visual gate is mandatory** — a reviewer must load `kb.html` in a browser and confirm that every visual is readable and correctly laid out. Reading or inspecting HTML/CSS source alone is NOT sufficient; it does not substitute for Playwright visual validation or a live browser inspection. Document any such skip in STATE.md before marking DONE.
   **Replaces:** the retired `validate-diagrams.mjs` (Mermaid D1/D2 JSDOM-based check — moot once the Mermaid engine is removed in D-012 Change 7 / FR-51).
2. **`canonical/aid/scripts/summarize/validate-html-output.sh`** — single invocation that performs link-integrity AND HTML structural/a11y checks: L1/L2 (anchor and `./*.md` link integrity), H1 (tidy → html-validate → regex cascade — script picks the most rigorous tool available and prints which), A1/A2/A4/A5 (semantic landmarks, lightbox ARIA, reduced-motion, focus-visible), S2 (offline render — CDN-free assertion: no external CDN `<script src>` or `<link href>` in the output), NM (no-Mermaid-engine assertion: output contains no Mermaid runtime engine or init call). **A3 (focus trap)** is auto-detected via `grep` of the inlined `lightbox.js` for the markers `trapFocusOnTab`, `lastFocused.focus()`, `key === 'Escape'`.
3. **`canonical/aid/scripts/summarize/contrast-check.mjs`** — C1/C2: WCAG ratios for both themes.
4. **`canonical/aid/scripts/summarize/validate-diagram-content.mjs`** — **diagram-content gate (complement to S7):** where S7 checks a diagram *renders* well, this checks it *says the right thing*. If a content manifest exists at `.aid/.temp/summarize/summary-src/diagram-content-manifest.json`, it asserts every diagram contains its `requires` tokens and none of its `forbids`/stale tokens (phase names, skill/agent/profile counts). This catches label drift that text-grep and the rendering gate miss (e.g. a phase box still reading "Interview" after a skill rename). Run `node canonical/aid/scripts/summarize/validate-diagram-content.mjs .aid/knowledge/kb.html .aid/.temp/summarize/summary-src/diagram-content-manifest.json`; exit non-zero = stale/missing label, fix in GENERATE. **No manifest present → skip (backward-compatible).** The manifest is the machine-readable companion to a human-readable diagram reference (e.g. `docs/diagram-content-reference.md`); keep both in lockstep with the diagrams.

✓ validation suite done (record actual time, per-script pass/fail summary) — or ✗ validation suite failed: {script, reason}

### Translate Script Output to Schema Rows

After each script exits, the orchestrator translates failed checks into schema rows in
`.aid/.temp/review-pending/summarize.md` (per `canonical/aid/templates/reviewer-ledger-schema.md`):

| Script check | Severity mapping |
|---|---|
| COV (resolved-doc-set coverage < 60%) | `[CRITICAL]` — automatic F on Machine Grade; one row |
| T1 (visual text not readable — font-size below threshold or zero-height-clipped) | `[HIGH]` — one row per failing visual |
| T2 (visual child element overlap exceeds 20% tolerance) | `[HIGH]` — one row per failing visual |
| T3 (visual collapsed or empty — non-trivial dimensions assertion failed) | `[HIGH]` — one row per failing visual |
| L1 (broken anchor links) | `[HIGH]` — one row per broken link |
| L2 (broken .md links) | `[HIGH]` — one row per broken path |
| H1 (HTML validity failure) | `[HIGH]` — one row per reported error |
| A1/A2/A4/A5 (missing ARIA / landmarks / reduced-motion / focus-visible) | `[MEDIUM]` — one row per check |
| A3 (focus trap missing) | `[MEDIUM]` — one row |
| S2 (CDN reference found — page not self-contained) | `[HIGH]` — one row per CDN reference |
| NM (Mermaid engine detected in output — should not be present in D-012) | `[HIGH]` — one row |
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
bash canonical/aid/scripts/grade.sh --explain .aid/.temp/review-pending/summarize.md
```

If Machine Grade >= minimum → MANUAL-CHECKLIST. Otherwise → FIX.

Print: `[State: VALIDATE] complete.`

**Advance:** **CHAIN** → [State: MANUAL-CHECKLIST] if Machine Grade >= minimum; **CHAIN** → [State: FIX] otherwise. Both continue inline.
