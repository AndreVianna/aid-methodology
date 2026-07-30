# State: VALIDATE

VALIDATE runs the machine-verifiable quality checks (coverage, visual fidelity, links, HTML, contrast) and records each failure as a ledger finding; it is selected after GENERATE completes and again after FIX.

**It does not compute a grade.** `grade.sh` does that, from the ledger, at the end of this state — the same way every other artifact in AID is graded.

▶ validation suite starting (~1.5 min total — 3 scripts × ~30 s each per `.cursor/aid/templates/rough-time-hints.md`)
Run `.cursor/aid/scripts/summarize/emit-summary-findings.sh .aid/knowledge/kb.html --ledger .aid/.temp/review-pending/summarize.md`. It orchestrates the machine-verifiable checks only.

> ⚠️ **It invokes items 2 and 3 below, not item 1.** `emit-summary-findings.sh` runs
> `validate-html-output.sh` and `contrast-check.mjs`; it also performs the doc-set coverage
> and retired-runtime checks inline. **It does not invoke `validate-visuals.mjs`** — and
> neither did the `grade-summary.sh` it replaced, so this is a long-standing wiring gap and
> not something the one-grading-backend change introduced. Verify before relying on it:
> `grep -c validate-visuals .cursor/aid/scripts/summarize/emit-summary-findings.sh`.
> Until it is wired, run item 1 by hand and treat the **mandatory** human visual check
> (`SUMMARY-06`, MANUAL-CHECKLIST) as the live safeguard — the same fallback already
> specified below for a host without Playwright.

1. **`.cursor/aid/scripts/summarize/validate-visuals.mjs`** — **S7 visual-fidelity gate (FR-51)** — *available, not currently invoked by the orchestrator; see the note above.* Playwright-renders `kb.html` in a headless Chromium browser (offline, `file://` URL, no network) and asserts, for every authored visual (inline `<svg>` / `.diagram-box` / infographic container):
   - **T1 — Readable text:** every visible text node inside the visual has a computed font-size >= 10 px and is NOT overflow-clipped to zero height.
   - **T2 — Minimal/zero overlap:** the bounding boxes of the visual's child elements do not materially overlap each other (tolerance: <= 20% of the smaller element's area).
   - **T3 — Correct basic layout:** the visual's own bounding rect has non-trivial dimensions (width > 0 AND height > 0) — the visual is rendered, not collapsed or empty.
   A visual that fails any of T1/T2/T3 is a **generation defect that blocks DONE** (same rigor as the old "no broken diagram" guarantee). Exit non-zero = defect; fix in GENERATE before continuing.
   **Visual-inspection fallback:** if Playwright is not installed, `validate-visuals.mjs` exits 0 with a SKIP message listing the visuals that require manual inspection. In this case, the **MANUAL-CHECKLIST V1 human visual gate is mandatory** — a reviewer must load `kb.html` in a browser and confirm that every visual is readable and correctly laid out. Reading or inspecting HTML/CSS source alone is NOT sufficient; it does not substitute for Playwright visual validation or a live browser inspection. Document any such skip in STATE.md before marking DONE.
   **Replaces:** the retired `validate-diagrams.mjs` (Mermaid D1/D2 JSDOM-based check — moot once the Mermaid engine is removed in D-012 Change 7 / FR-51).
2. **`.cursor/aid/scripts/summarize/validate-html-output.sh`** — single invocation that performs link-integrity AND HTML structural/a11y checks: L1/L2 (anchor and `./*.md` link integrity), H1 (tidy → html-validate → regex cascade — script picks the most rigorous tool available and prints which), A1/A2/A4/A5 (semantic landmarks, lightbox ARIA, reduced-motion, focus-visible), S2 (offline render — CDN-free assertion: no external CDN `<script src>` or `<link href>` in the output), NM (no-Mermaid-engine assertion: output contains no Mermaid runtime engine or init call). **A3 (focus trap)** is auto-detected via `grep` of the inlined `lightbox.js` for the markers `trapFocusOnTab`, `lastFocused.focus()`, `key === 'Escape'`.
3. **`.cursor/aid/scripts/summarize/contrast-check.mjs`** — C1/C2: WCAG ratios for both themes.
4. **`.cursor/aid/scripts/summarize/validate-diagram-content.mjs`** — **diagram-content gate (complement to S7):** where S7 checks a diagram *renders* well, this checks it *says the right thing*. If a content manifest exists at `.aid/.temp/summarize/summary-src/diagram-content-manifest.json`, it asserts every diagram contains its `requires` tokens and none of its `forbids`/stale tokens (phase names, skill/agent/profile counts). This catches label drift that text-grep and the rendering gate miss (e.g. a phase box still reading "Interview" after a skill rename). Run `node .cursor/aid/scripts/summarize/validate-diagram-content.mjs .aid/knowledge/kb.html .aid/.temp/summarize/summary-src/diagram-content-manifest.json`; exit non-zero = stale/missing label, fix in GENERATE. **No manifest present → skip (backward-compatible).** The manifest is the machine-readable companion to a human-readable diagram reference (e.g. `docs/diagram-content-reference.md`); keep both in lockstep with the diagrams.

✓ validation suite done (record actual time, per-script pass/fail summary) — or ✗ validation suite failed: {script, reason}

### Translate Script Output to Schema Rows

After each script exits, the orchestrator translates failed checks into schema rows in
`.aid/.temp/review-pending/summarize.md` (per `.cursor/aid/templates/reviewer-ledger-schema.md`):

Every row cites the rule it breaks, per the ledger schema's `Rule` column. The check-to-rule mapping
is the one recorded in `review-rubrics/summary.md § Where the retired per-check scores went`.

**Severity is looked up from the rule, never restated here.** The `Severity` column below is a
convenience copy of what `review-rubrics/summary.md` and `presentation.md` declare; where this table
and the catalog ever disagree, **the catalog wins** and this table is the defect. Restating a
severity is how a second source of truth starts, and one already did: this table used to give
`[HIGH]` for `L1`, `L2` and `H1` — the values the retired points model carried — while the catalog
re-derived them against the canonical scale as `[LOW]`, `[MEDIUM]` and `[MEDIUM]`. Those three are
corrected below, exactly the re-derivation feature-007 §1b called for.

| Script check | Rule | Severity (per the catalog) | Rows |
|---|---|---|---|
| COV (a resolved doc-set document is not referenced) | `SUMMARY-01` | `[MEDIUM]` | **One row per unreferenced document, naming it.** There is no 60% cliff and no automatic F: the grade follows from how many documents are missing |
| T1 (visual text not readable — font-size below threshold or zero-height-clipped) | `SUMMARY-06` | `[HIGH]` | one row per failing visual |
| T2 (visual child element overlap exceeds 20% tolerance) | `SUMMARY-06` | `[HIGH]` | one row per failing visual |
| T3 (visual collapsed or empty — non-trivial dimensions assertion failed) | `SUMMARY-06` | `[HIGH]` | one row per failing visual |
| L1 (broken anchor links) | `SUMMARY-08` | `[LOW]` | one row per broken link — a dead in-page jump is contained and fixed by regenerating |
| L2 (broken .md links) | `SUMMARY-09` | `[MEDIUM]` | one row per broken path — it sends the reader out of the summary to nothing |
| H1 (HTML validity failure) | `SUMMARY-02` | `[MEDIUM]` | one row per reported error |
| A1 (missing semantic landmarks) | `PRE-02` | `[MEDIUM]` | one row |
| A2 (missing ARIA on lightbox) | `PRE-04` | `[MEDIUM]` | one row |
| A3 (focus trap missing) | `PRE-04` | `[MEDIUM]` | one row |
| A4 (reduced-motion block missing) | `PRE-05` | `[MEDIUM]` | one row |
| A5 (visible focus missing) | `PRE-03` | `[MEDIUM]` | one row |
| S2 (CDN reference found — page not self-contained) | `SUMMARY-03` | `[HIGH]` | one row per CDN reference — an offline reader gets a broken page, so the radius has escaped |
| NM (Mermaid engine detected in output — should not be present in D-012) | `SUMMARY-07` | `[HIGH]` | one row |
| C1/C2 (WCAG contrast fail) | `PRE-11` | `[MEDIUM]` | one row per failing color pair — one rule, both themes |

For each failed check, append a row:
- `#` = next sequential row number
- `Severity` = per mapping above (bracketed)
- `Status` = `Pending`
- `Doc` = `kb.html`
- `Line` = `—` (or nearest section if identifiable)
- `Description` = one sentence: "check X failed: {what was wrong}"
- `Evidence` = script output excerpt or exact error message

Passed checks are NOT added to the ledger (no row = no finding).

Persist the findings and the per-check table to `.aid/knowledge/STATE.md` `## Knowledge Summary Status` `### Findings (last validation)`. The grade is then computed by the one grading backend:

```bash
bash .cursor/aid/scripts/review/check-gaps.sh --ledger .aid/.temp/review-pending/summarize.md   # exit 1 = an open criteria gap; do NOT grade
bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/summarize.md
```

If the grade >= minimum → MANUAL-CHECKLIST. Otherwise → FIX.

Print: `[State: VALIDATE] complete.`

**Advance:** **CHAIN** → [State: MANUAL-CHECKLIST] if the grade >= minimum; **CHAIN** → [State: FIX] otherwise. Both continue inline.
