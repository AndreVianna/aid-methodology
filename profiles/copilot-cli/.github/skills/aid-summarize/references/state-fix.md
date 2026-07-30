# State: FIX

FIX repairs machine-detected findings autonomously and routes human-judgment findings through the expose-propose-ask loop; it is selected when VALIDATE or MANUAL-CHECKLIST determines the grade is below minimum.

FIX handles two fundamentally different kinds of finding. **Route each by kind** — do not treat them the same. The split is by *what evidence settles it*, not by which of two score pools it once belonged to; those pools are gone.

### Machine-detected findings — fix directly (objective; one correct fix)

Read `.aid/.temp/review-pending/summarize.md`. Filter rows where Status ∈ {`Pending`, `Recurred`} — these are the open findings to address. **Do NOT modify the ledger `Status` column during FIX** — that is reconciliation's job, and VALIDATE does it: it re-runs the checks into a per-cycle scratch ledger and reconciles scratch against this file on `(Doc, Rule)`, flipping to `Fixed` exactly the rows whose defect is gone (`references/state-validate.md`).

> This used to read *"VALIDATE will re-run the checks and create fresh rows in the next cycle"*, which was wrong in both halves and made the loop non-terminating: VALIDATE appended to this same file rather than creating anything fresh, so a fixed row stayed `Pending`, `grade.sh` kept counting it, and every pass duplicated the rows that were still failing.

For each Pending/Recurred row, apply the corresponding repair autonomously:

- **`SUMMARY-01` findings (resolved doc-set coverage)** — the summary is missing sections for resolved KB docs. Each finding **names the missing document**, so add a section for each one until `emit-summary-findings.sh` finds a reference to it in the HTML. Fix them all: **fixing some but not all may not move the grade at all.** `grade.sh` counts findings in three bands (`modifier_for_count`: 1 -> `+`, 2-5 -> none, 6+ -> `-`), so the measured curve for `[MEDIUM]` rows is **0 -> `A+`, 1 -> `C+`, 2-5 -> `C`, 6+ -> `C-`**. Going from five missing documents to two is three real fixes and zero grade steps. The retired ladder's
  60% cliff is gone, but banding is not the same as monotonicity, and an earlier version of this line
  claimed "there is no threshold to clear" -- the thresholds it denied (1 and 5) are the ones
  `grade.sh` actually has.
- **`SUMMARY-07` (a retired diagram runtime is present)** — a legacy `<pre class="mermaid">` block or a Mermaid engine reference was authored by mistake. Remove it and replace it with an inline SVG visual (see `.github/aid/templates/knowledge-summary/authored-visual-catalog.md`). This row replaces the old `D1`/`D2` entries, which are **deleted**: they were hardcoded to pass once the Mermaid engine was retired, so a repair instruction for them described a row that could not appear.
- **`SUMMARY-08` (L1 — anchor links)** — fix the `href` or add the missing `id`.
- **`SUMMARY-09` (L2 — relative md links)** — correct the relative path.
- **`SUMMARY-02` (H1 — HTML validity)** — fix the reported markup error (from tidy / html-validate / regex, whichever ran).
- **`PRE-02` / `PRE-04` / `PRE-05` / `PRE-03` (A1–A5 — accessibility)** — add the missing landmark / ARIA attribute / focus-trap marker / reduced-motion block / focus-visible rule.
- **`PRE-11` (C1 / C2 — contrast, one rule across both themes)** — adjust the offending color in the inlined CSS to meet the ratio. The row's `Line` names the theme and the token pair.
- **`SUMMARY-03` (S2 — page not self-contained)** — the assembled HTML carries an external reference. Remove the `<script src="https://…">` or `<link href="https://…">` and inline what it provided; the summary must render with the network disabled.
- **`PRE-01` (document-level accessibility)** — add the missing item the row's `Line` names: a `<noscript>` fallback listing the doc-set, or a `color-scheme: light dark` declaration. Both are MUST items in `knowledge-summary/accessibility-checklist.md § Document level`.

> **This list must name every rule the emitter can emit — all twelve.** It carried ten: `SUMMARY-03`
> and `PRE-01` were missing, so a row for either reached FIX with no repair instruction and could
> never reach `Fixed`, which stalls the VALIDATE → FIX → VALIDATE loop for it. Keep it in step with
> `emit-summary-findings.sh`'s `RULE_FOR` plus its two direct emitters (`SUMMARY-01`, `PRE-11`);
> `tests/canonical/test-one-grading-backend.sh` asserts the three surfaces agree.

Edit ONLY the failing parts; leave everything else untouched. After all mechanically-fixable findings are addressed, return to VALIDATE.

### Human-judgment / subjective findings — expose → propose → ask (NEVER fix silently)

When a human-judgment answer fell short (KB completeness, fact grounding) or the user left a free-text complaint in `## Manual Notes`, there is **no single objective fix** — the user flagged it because their judgment is the input. Do NOT guess-and-apply. Instead, for each such issue, run the **expose → propose → ask** loop:

1. **Expose** — restate the issue precisely. Quote the user's note or the failing checklist item. Name the specific HTML section(s) or claim(s) involved. Example: *"K1 was answered `partial` — your note says the Schemas section only lists artifact names without the per-artifact schemas that `schemas.md` actually contains."*
2. **Propose** — offer a concrete, specific fix. Example: *"Proposed: expand §5 Schemas to include the field-level schema table for each of the 15 artifacts, pulled from `schemas.md §2.1-§2.15`. Adds ~40 lines."*
3. **Ask** — use `AskUserQuestion` to ask the user to (a) approve the proposed fix, (b) provide their own fix / direction, or (c) mark the issue as won't-fix (accept the finding, and the grade that follows from it). Wait for the answer before editing.

Apply only what the user confirms. Capture the resolution in `.aid/knowledge/STATE.md` `## Knowledge Summary Status` `### Manual Notes`. After all human-judgment findings are resolved (or accepted as won't-fix), return to VALIDATE → MANUAL-CHECKLIST so the user can re-answer the checklist.

**Rationale:** machine-detected issues have one objective fix; human-detected / subjective issues do not — applying the agent's guess silently risks solving the wrong problem or overwriting the user's intent. The user is the judgment input; collaboration produces the right outcome.

Print: `[State: FIX] complete.`

**Advance:** **CHAIN** → [State: VALIDATE] (continue inline).
