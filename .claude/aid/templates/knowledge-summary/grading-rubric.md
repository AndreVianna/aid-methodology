# Summary Check Definitions

> **This document no longer defines a grade.** It defines the **checks** run against a generated
> `kb.html` and what each one means. The letter grade comes from `grade.sh`, derived from the findings
> in the ledger, exactly as it is for every other artifact in AID.
>
> The skill's `VALIDATE` state runs `emit-summary-findings.sh`, which runs these checks and writes a
> **ledger row per failure** citing the rule it breaks. It computes no grade of its own.

The checks below are the criterion source cited by the `SUMMARY-*` rules in
[`review-rubrics/summary.md`](../review-rubrics/summary.md) — that file maps every check here to the
rule that now carries it.

> **`discovery.doc_set` and `knowledge.doc_set` are the same list at two layers**, and both appear
> below without contradiction. `discovery.doc_set` is the *accessor path* every skill and template
> uses; `read-setting.sh` resolves it to the `knowledge:` block where the rows physically live. Use
> the accessor path when describing the doc-set as a concept, and the physical key only when
> describing what a script parses out of `.aid/settings.yml`.

> **The KB no-diagrams rule does NOT apply here.** KB docs (`.aid/knowledge/*.md`)
> are authored without diagrams because they serve AI agents and technical readers.
> `kb.html` is a *different product* for a *different audience* -- a non-technical
> newcomer. Visuals (diagrams, infographics, cards, pill-grids) are encouraged
> wherever they help a newcomer understand the project. What is judged is **quality
> and fit**, never a diagram count. There is **no diagram floor** (visuals are
> never required) and **no diagram ceiling** (more visuals are not penalised). A
> visual that is present is judged on newcomer clarity through the human visual
> check (`SUMMARY-06`); a summary with no visuals produces no finding either way.

## How this artifact is graded now

One backend, the same as everywhere else:

1. `emit-summary-findings.sh` runs the machine checks and writes a ledger row per failure, citing the
   rule from [`review-rubrics/summary.md`](../review-rubrics/summary.md).
2. A reviewer adds the rows that no machine can produce — whether a claim is *true* (`SUMMARY-04`,
   `SUMMARY-05`) and whether the visuals actually render (`SUMMARY-06`).
3. `grade.sh` reads the ledger and derives the letter from the worst severity and the count.

**The human visual check is still mandatory, and it is still not something an agent may answer.** No
agent sees a rendered page: every automated check can pass while a visual is unreadable in one theme.
What changed is the consequence of *not having run it*. It used to force a grade of `F`. It now produces
**no grade at all** — the gate pauses for the human.

That distinction is the point: **unanswered is not the same as failed.** Reporting `F` for a check
nobody has performed states a result that was never observed, and it lets a real failure hide behind an
identical-looking score.

The weights, the percentage ladder and the two-grade minimum are gone. See
[`review-rubrics/summary.md § Where the retired per-check scores went`](../review-rubrics/summary.md)
for where each check landed.

## Check definitions

| ID | Check | Pass condition | Now expressed as | Verifier |
|----|-------|----------------|------------------|----------|
| **K1** | Resolved-doc-set coverage (human) | Every resolved doc from `discovery.doc_set` that exists on disk has its information represented in the summary (either a dedicated section or folded into a related section with attribution); the reviewer cross-checks the section manifest against the doc-set list | `SUMMARY-01` | manual (`manual-checklist.sh`) |
| **K2** | KB facts grounded | All numeric/named facts in the HTML appear verbatim in source KB | `SUMMARY-05` | manual (`manual-checklist.sh`) |
| **V1** | Human visual gate (mandatory) | The user opens `kb.html` in a browser and confirms ALL of: every visual element renders correctly (no error blocks, no collapsed/empty containers); any diagram or infographic text is legible in BOTH light AND dark themes; theme toggle works; lightbox opens / Esc closes / Tab cycles. If no visual elements are present, V1 is trivially passed with a note. | `SUMMARY-06` | manual (`manual-checklist.sh`) |
| **COV** | Resolved-doc-set coverage (automated) | Every filename in `knowledge.doc_set` (`.aid/settings.yml`) that exists on disk in `.aid/knowledge/` is referenced in the HTML (by section heading, anchor, or inline content mentioning the doc stem or its objective). **Each unreferenced document is one finding, naming that document** -- there are no coverage bands and no threshold. If `settings.yml` declares no `doc_set`, the check reports itself as not evaluated rather than passing. | `SUMMARY-01` | `emit-summary-findings.sh` (reads settings.yml + checks HTML) |
| **T1** | Visual text readable (§7 gate) | Every visible text node inside each authored visual (inline `<svg>`, `.diagram-box`, infographic container) has a computed font-size >= 10 px and is NOT overflow-clipped to zero height. If Playwright is unavailable, T1 skips and V1 carries the visual-review obligation. A failure is a `SUMMARY-06` finding and blocks approval — but only if the validator is actually run. | `SUMMARY-06` | `validate-visuals.mjs` (Playwright) — **not invoked by any orchestrator; run by hand, see below** |
| **T2** | Visual element overlap minimal (§7 gate) | The bounding boxes of sibling elements inside each authored visual do not materially overlap (tolerance: <= 20% of the smaller element's area). If Playwright is unavailable, T2 skips and V1 carries the visual-review obligation. A failure is a `SUMMARY-06` finding and blocks approval — but only if the validator is actually run. | `SUMMARY-06` | `validate-visuals.mjs` (Playwright) — **not invoked by any orchestrator; run by hand, see below** |
| **T3** | Visual layout non-trivial (§7 gate) | Each authored visual's bounding rect has non-trivial dimensions (width > 0 AND height > 0) — the visual is rendered, not collapsed or empty. If Playwright is unavailable, T3 skips and V1 carries the visual-review obligation. A failure is a `SUMMARY-06` finding and blocks approval — but only if the validator is actually run. | `SUMMARY-06` | `validate-visuals.mjs` (Playwright) — **not invoked by any orchestrator; run by hand, see below** |
| **NM** | No Mermaid runtime engine | The assembled `kb.html` contains no Mermaid runtime engine or init call (`mermaid.init`, `mermaid.js`, `cdn.jsdelivr.net/npm/mermaid`). D-012 guardrail: visuals are inline SVG / HTML+CSS only. A failure is a `SUMMARY-07` finding at `[HIGH]`, and this check **is** wired — `validate-html-output.sh` runs on every VALIDATE. | `SUMMARY-07` | `validate-html-output.sh` |
| **L1** | Anchor links | Every `href="#X"` resolves to in-page `id="X"` | `SUMMARY-08` | `validate-html-output.sh` |
| **L2** | Relative md links | Every `./*.md` link points to an existing file in `.aid/knowledge/` | `SUMMARY-09` | `validate-html-output.sh` |
| **H1** | HTML validity | If `tidy` or `html-validate` is available, zero errors reported; otherwise regex structural checks pass | `SUMMARY-02` | `validate-html-output.sh` |
| **A1** | Semantic landmarks | `<header role="banner">`, `<main>`, `<nav>`, `<footer>` present | `PRE-02` | `validate-html-output.sh` |
| **A2** | ARIA on lightbox | Dialog has `role`, `aria-modal`, `aria-labelledby`, `aria-hidden` | `PRE-04` | `validate-html-output.sh` |
| **A3** | Focus trap | Inlined `lightbox.js` contains `trapFocusOnTab`, `lastFocused.focus()`, and `key === 'Escape'` | `PRE-04` | `validate-html-output.sh` (grep on inlined JS) |
| **A4** | Reduced motion | `prefers-reduced-motion` block present in CSS | `PRE-05` | `validate-html-output.sh` |
| **A5** | Visible focus | `:focus-visible` rule present in CSS | `PRE-03` | `validate-html-output.sh` |
| **C1** | Light theme contrast | All token pairs in checklist >= target ratios | `PRE-11` | `contrast-check.mjs` |
| **C2** | Dark theme contrast | Same | `PRE-11` | `contrast-check.mjs` |
| **S2** | Offline render | The page is single-file self-contained with no external engine or CDN fetch. Passes trivially today — the Mermaid engine was removed in D-012 and inline SVG needs no runtime engine — but it is still evaluated, because a CDN reference reintroduced by mistake is exactly what it exists to catch. | `SUMMARY-03` | `validate-html-output.sh` |

There is no totals row. `Machine total 68` and `Human total 30` were the two pools of the retired
grading model; a table of check *definitions* has no total, because the checks are not summed.

> File size is **not graded**. The output's actual size is recorded in
> `.aid/knowledge/STATE.md` `## Knowledge Summary Status` for transparency,
> but no maximum is enforced.

> **Format-per-fact freedom.** The summary chooses the best format for each
> piece of information -- diagram, infographic, table, card, pill-grid, or
> prose -- whichever best communicates that fact to a non-technical newcomer.
> There is no required format for any given section. The COV check cares only
> that the resolved-doc-set's information is *represented*, not *how* it is
> represented.

## Grade boundaries

There is no ladder here any more. The letter comes from
[`grading-rubric.md`](../grading-rubric.md) — AID's single grading rubric — applied by `grade.sh` to the
findings in the ledger.

**Why the percentage ladder was retired.** It was a second grading model, and it disagreed with the
first by construction:

- **It knew a different alphabet.** Eleven letters (`A+ A A- B+ B B- C+ C C- D F`) against `grade.sh`'s
  sixteen. `D+`, `D-`, `E+`, `E` and `E-` were unreachable, so the two backends could not return the
  same grade for the same artifact even in principle.
- **It let good checks pay for bad ones.** A percentage averages. `grade.sh` is dominated by the worst
  issue on purpose: five clean sections do not offset one critical defect.
- **It gave away ten points.** `D1` and `D2` were hardcoded `pass` once the Mermaid engine was retired —
  10 of 68 points that could never be lost.
- **Its partial credit hid real gaps.** 95% coverage scored full marks, so a summary missing one
  document in twenty was graded complete.

## Hard rules

Two of the old hard rules survive, restated as what they always were — **preconditions**, not score
overrides. The rest were artefacts of the ladder.

1. **The human checklist must have been completed before approval.** Not because it contributes points,
   but because `SUMMARY-06` cannot be answered by any agent. If it has not been run, the outcome is
   **a pause, not a grade** — see *How this artifact is graded now*, above.
2. **A visual that fails the human check blocks approval.** It produces a `SUMMARY-06` finding, and the
   grade follows from that finding like any other.

**Coverage no longer has a 60% cliff.** It was the ladder's way of forcing a floor. Under `SUMMARY-01`
each unreferenced document is its own `[MEDIUM]` finding, so coverage degrades the grade smoothly and
names what is missing instead of announcing a percentage.

> **Diagram-count hard rule: REMOVED**, and it stays removed. There is no minimum or maximum diagram
> count, and neither adding nor omitting diagrams affects the grade. Visuals are judged on quality and
> fit through the human check, never on count.

## Why there were two grades, and why there are no longer

The split solved a real problem. Earlier versions **auto-passed** the checks a script cannot verify
(`K1`, `K2`, `A3` — 30 points awarded without evidence), which inflated the reported grade while capping
it below `A+` because `A3` was never truly scored. Separating machine-verifiable from human-verifiable
made that dishonesty visible, and that was the right diagnosis.

The wrong part was the **remedy**: a whole second grading model — its own pools, its own percentage
ladder, its own alphabet, its own minimum-of-two rule — to express one idea, that some checks need a
human.

That idea needs no second model. It is a property of the *rules*: `SUMMARY-06` is marked human-evidence-
only, so an agent's "no violations" cannot satisfy it. The distinction is preserved exactly, in the one
place review criteria belong, and the ledger stays the only input to the one grader.

**What was actually lost by having two.** Two grading models drift. This pair already had: eleven
letters against sixteen, an average against a worst-dominates rule, ten unloseable points, and partial
credit that scored a summary missing a document as complete. Every one of those made the summary's grade
mean something different from the same letter on any other artifact.

**Why the human visual check is mandatory** — the original rationale, which still holds: during dogfood
use, a
generated summary passed every automated check -- D1/D2 (diagrams parse and
render), C1/C2 (theme contrast), all of A1-A5 -- while its Mermaid node labels
were genuinely unreadable in dark mode (silver text on teal, ~1.2:1). The
automated contrast checks (C1/C2) only measure the page's CSS theme tokens;
they do not and cannot measure the colors inside a rendered SVG.
No automated check covers "does the rendered visual actually look right." V1
closes that hole: the user must open the file and look, in both themes, before
the summary can be approved. V1 applies to any visual present (diagram,
infographic, SVG, card grid with color); if none are present, it is trivially
passed.

*Identified during dogfood discovery of AID against itself, 2026-05-21;
tracked as `tech-debt.md H8`.*

## Per-check pass criteria details

**K1:** Every resolved doc from `discovery.doc_set` (those that exist on disk)
must have its information represented in the HTML. The reviewer cross-checks the
section list against the resolved doc-set during `manual-checklist.sh` and
answers `y` / `p` / `n`:

- `y` — every resolved doc appears as a dedicated section, or is explicitly
  folded into a related section with attribution. No finding.
- `p` or `n` — **name the documents whose information is absent.** Each named
  document is one `SUMMARY-01` finding, exactly as the automated `COV` check
  emits them. There is no partial credit and no `>=80%` band; the answer is a
  prompt to enumerate, not a score.

**K2:** Every numeric/named fact in headers/cards/tables must be locatable in
a KB doc. Reviewer spot-checks 5-10 facts per run during `manual-checklist.sh`
(the `spot-check-facts.sh` report is a starting point, not a substitute for
human judgment).

**V1 (mandatory gate):** The reviewer opens `kb.html` in a real browser and
confirms ALL of: (a) every visual element renders correctly -- no error blocks,
no collapsed/empty containers; (b) any diagram or infographic text is legible in
BOTH light AND dark themes; (c) the light/dark theme toggle works; (d) the
lightbox opens on click, Esc closes it, Tab cycles focus inside. If no visual
elements are present in the summary, it is trivially passed with a note
("no visuals to validate"). All four points are required for any visuals
present; any failure is a `SUMMARY-06` finding and blocks approval.

**If the checklist has not been run at all, there is no grade** — the gate pauses for the human. It no
longer reports `F`. Reporting a failing grade for a check nobody performed states a result that was
never observed, and it makes a genuine failure indistinguishable from an absent answer.

**COV (automated coverage):** `emit-summary-findings.sh` reads `knowledge.doc_set` from
`.aid/settings.yml`, intersects with files actually present in `.aid/knowledge/`
(the resolved doc-set), then checks the HTML for a reference to each resolved
doc (by section heading text, anchor `id`, or inline mention of the doc filename
stem). **Each unreferenced document is one `SUMMARY-01` finding, naming that document.** There are no
bands and no cliff: the grade follows from how many documents are missing, and the report says which.
If `settings.yml` has no `doc_set` field, the check is not evaluated and says so — it is not silently
recorded as a pass.

**T1/T2/T3 (§7 visual-fidelity gate) — read this before relying on them.**
**No orchestrator invokes `validate-visuals.mjs` today.** `emit-summary-findings.sh` runs
`validate-html-output.sh` and `contrast-check.mjs` and nothing else; the retired
`grade-summary.sh` invoked the same two, so this is a long-standing gap rather than
something the one-grading-backend change caused. Until it is wired, T1/T2/T3 are
**available but not automatic**: run
`node .claude/aid/scripts/summarize/validate-visuals.mjs .aid/knowledge/kb.html`
by hand, and treat the mandatory human visual check (`V1` → `SUMMARY-06`) as the
live safeguard — which is exactly the fallback already specified for a host without
Playwright. Recorded rather than quietly wired, because wiring a gate is a behaviour
change and this delivery's scope is the grading backend.

What the validator does when it is run: `validate-visuals.mjs` launches a
headless Chromium browser (offline, `file://` URL) and for every authored visual
(inline `<svg>`, `.diagram-box`, infographic container) asserts: T1 — every
visible text node has computed font-size >= 10 px and is not overflow-clipped;
T2 — sibling element bounding boxes do not materially overlap (tolerance <= 20%
of the smaller element's area); T3 — the visual's own bounding rect has non-trivial
dimensions (width > 0 AND height > 0). A failing T1/T2/T3 is a generation defect
that blocks DONE. If Playwright is unavailable, all three checks skip with a SKIP
message and the V1 human visual gate is mandatory (browser-rendered inspection
required; HTML/CSS source inspection is not sufficient).

**NM (no-Mermaid-engine assertion):** `validate-html-output.sh` greps the
assembled `kb.html` for known Mermaid runtime engine markers (`mermaid.init`,
`mermaid.js`, `cdn.jsdelivr.net/npm/mermaid`). Any match is a D-012 guardrail
violation — it means the CDN-fetched engine was reintroduced and the page is no
longer self-contained. NM failure blocks DONE.

**D1 and D2 are deleted, not retired-but-still-listed.** They were the Mermaid parse and render
checks, hardcoded `pass` once the Mermaid engine was removed (D-012, Change 7 / FR-51) — 10 of the
old 68 points that could never be lost. A check that cannot fail is not coverage, so they have no
rule and no pass criteria. `SUMMARY-07` asserts the engine stays gone; the visual-fidelity checks
below cover authored inline SVG.

**L1:** Every `href="#X"` must resolve to an element with `id="X"` in the page.

**L2:** Every `<a href="./X.md">` must point to an existing `.aid/knowledge/X.md`.

**H1 cascade:** `validate-html-output.sh` tries in order:
1. `tidy -e --quiet yes` -- fails on any error line.
2. `html-validate` -- fails on errors.
3. Regex fallback (unclosed tags, duplicate IDs, missing `<!DOCTYPE html>`).
Warnings are allowed in all modes. **Which of the three paths ran is visible only in
`validate-html-output.sh`'s own output** — it prints e.g. `✅ H1. HTML validity (regex fallback — less
rigorous; install tidy for strict check)`. The emitter does not surface it (there is no grade output for
it to appear in, and the emitter discards the validator log once it has extracted the failures), so if
you need to know whether the strict checker or the regex fallback graded the markup, run the validator
directly.

**A1:** `<header role="banner">`, `<main id="top">`, `<nav aria-label="...">`,
`<footer>` all present.

**A2:** `#lightbox` has `role="dialog"`, `aria-modal="true"`,
`aria-hidden="true"`, and `aria-labelledby` referencing an existing element.

**A3:** `validate-html-output.sh` greps inlined `lightbox.js` for all three markers:
`trapFocusOnTab`, `lastFocused.focus()`, `key === 'Escape'`.

**A4:** CSS has `@media (prefers-reduced-motion: reduce)` with at least one rule.

**A5:** CSS has `:focus-visible` rule with visible outline.

**C1/C2:** `contrast-check.mjs` checks WCAG AA ratios for all token pairs in
`accessibility-checklist.md`; every pair must meet its target ratio.

**S2:** The page must be single-file self-contained (all CSS and JS inlined; inline
SVG visuals need no runtime engine). `validate-html-output.sh` confirms there is no
`<script src="https://...">` and no `<link href="https://...">`. It passes on
current output — there is no Mermaid engine and no external fetch — but it is a
live check, not a free pass: a CDN reference reintroduced by mistake is the whole
reason it exists, and that is why it kept a rule (`SUMMARY-03`) where `D1`/`D2`
did not.

## How a check run reports

A clean run emits nothing to the ledger and reports no grade:

```
$ bash .claude/aid/scripts/summarize/emit-summary-findings.sh .aid/knowledge/kb.html \
      --ledger .aid/.temp/review-pending/summary.md

=== emit-summary-findings.sh: .aid/knowledge/kb.html ===

OK: emit-summary-findings.sh: no findings.
NOTE: this script does not grade. Run grade.sh over the ledger for the letter.
```

## How failures surface

Each failure is a ledger row naming the rule it breaks and the thing that broke it. Note that the
missing documents are **named** — the retired check reported only a percentage:

**In `--ledger` mode the rows go to the ledger, not to the terminal** — the writer's output is
discarded, so a run that finds problems prints only the count. Use `--dry-run` to see the rows; that
mode writes nothing and prints them pipe-separated, exactly as below (this is real output, not an
illustration):

```
$ bash .claude/aid/scripts/summarize/emit-summary-findings.sh .aid/knowledge/kb.html --dry-run

=== emit-summary-findings.sh: .aid/knowledge/kb.html ===
[MEDIUM] | SUMMARY-01 | tech-debt.md | Declared knowledge-base document is not represented in the generated summary | settings.yml knowledge.doc_set lists tech-debt.md and .aid/knowledge/tech-debt.md exists, but no reference to "tech-debt" appears in kb.html
[MEDIUM] | SUMMARY-01 | test-landscape.md | Declared knowledge-base document is not represented in the generated summary | settings.yml knowledge.doc_set lists test-landscape.md and .aid/knowledge/test-landscape.md exists, but no reference to "test-landscape" appears in kb.html

emit-summary-findings.sh: emitted 2 finding(s).
NOTE: no grade is computed here. Run grade.sh over the ledger for the letter.
```

The grade then comes from the one grader, over those rows — again, real output:

```
$ bash .claude/aid/scripts/grade.sh --explain .aid/.temp/review-pending/summary.md

C
Issue counts (schema-table mode):
  CRITICAL: 0
  HIGH:     0
  MEDIUM:   2
  LOW:      0
  MINOR:    0
  TOTAL:    2
Grade: C
```

The letter goes to stdout on its own first line, so a caller can capture it with `$(...)`; the
breakdown is what `--explain` adds.

Re-run `/aid-summarize` to enter FIX and add the missing sections. Because each absent document is its
own finding rather than a band, fixing one improves the grade — under the retired ladder, going from 18
to 21 of 22 documents changed nothing until a threshold was crossed.
