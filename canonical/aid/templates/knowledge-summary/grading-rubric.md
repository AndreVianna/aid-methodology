# Grading Rubric

The skill's `VALIDATE` state runs `grade-summary.sh` against the generated
`kb.html`. Each check is binary pass/fail (or partial for COV); the grade is the
weighted aggregate.

> **The KB no-diagrams rule does NOT apply here.** KB docs (`.aid/knowledge/*.md`)
> are authored without diagrams because they serve AI agents and technical readers.
> `kb.html` is a *different product* for a *different audience* -- a non-technical
> newcomer. Visuals (diagrams, infographics, cards, pill-grids) are encouraged
> wherever they help a newcomer understand the project. The grade rewards **quality
> and fit**, never a diagram count. There is **no diagram floor** (visuals are
> never required) and **no diagram ceiling** (more visuals are not penalised). If a
> visual is present, it is graded on newcomer clarity (V1 human gate); if absent,
> no points are lost.

## Two-Grade Model

Every run produces two independent grades:

| Grade | Checks | Max pts | How scored |
|-------|--------|---------|------------|
| **Machine Grade** | COV, L1, L2, H1, A1, A2, A3, A4, A5, C1, C2, D1, D2, S2 | 68 | `grade-summary.sh` runs automatically |
| **Human Grade** | K1, K2, **V1** | 30 | `manual-checklist.sh` run by a human reviewer |

**Overall Grade = min(Machine letter, Human letter).**

A+ requires both Machine >= 98% (67/68) and Human >= 98% (30/30). If
`manual-checklist.sh` has never run, the Human Grade is absent and Overall is
reported as **"Pending Human Review"** -- APPROVAL is blocked until the user
grade exists.

> **Pool total = 68 + 30 = 98.** `grade-summary.sh` sums the AUTO_POOL weights at
> runtime (it is not a hard-coded constant) -- if a check's weight changes, the
> total tracks it automatically. The 68 below is the current sum.

> **V1 is a MANDATORY GATE.** The human visual gate (5 pts) must be
> affirmatively passed. If V1 fails -- or the checklist has not been run --
> the Human Grade is forced to **F** regardless of K1/K2, so APPROVAL is
> blocked. Rationale: automated checks (C1/C2 contrast, structure) can ALL pass
> while a visual element is unreadable in one theme. Only a human looking at the
> rendered output in both themes catches that. V1 applies to any visual present
> (diagram, infographic, card grid); if no visuals are present, V1 is trivially
> passed (5/5) with a note.

## Check definitions

| ID | Check | Pass condition | Weight | Verifier |
|----|-------|----------------|--------|----------|
| **K1** | Resolved-doc-set coverage (human) | Every resolved doc from `discovery.doc_set` that exists on disk has its information represented in the summary (either a dedicated section or folded into a related section with attribution); the reviewer cross-checks the section manifest against the doc-set list | 10 | manual (`manual-checklist.sh`) |
| **K2** | KB facts grounded | All numeric/named facts in the HTML appear verbatim in source KB | 15 | manual (`manual-checklist.sh`) |
| **V1** | Human visual gate (mandatory) | The user opens `kb.html` in a browser and confirms ALL of: every visual element renders correctly (no error blocks, no collapsed/empty containers); any diagram or infographic text is legible in BOTH light AND dark themes; theme toggle works; lightbox opens / Esc closes / Tab cycles. If no visual elements are present, V1 is trivially passed (5/5) with a note. Pass=5, fail=0. **V1=0 forces Human Grade F.** | 5 | manual (`manual-checklist.sh`) |
| **COV** | Resolved-doc-set coverage (automated) | Every filename in `discovery.doc_set` (`.aid/settings.yml`) that exists on disk in `.aid/knowledge/` is referenced in the HTML (by section heading, anchor, or inline content mentioning the doc stem or its objective). Full (15 pts): coverage >= 95%. Partial (8 pts): coverage 80-94%. Minimal (3 pts): coverage 60-79%. None (0 pts): coverage < 60% -- also forces Machine Grade F. | 15 | `grade-summary.sh` (reads settings.yml + checks HTML) |
| **D1** | Mermaid parse (if present) | If `<pre class="mermaid">` blocks exist, `mermaid.parse()` succeeds for every block. If no Mermaid blocks are present, D1 is trivially passed (5/5) with a note. A parse failure on a present block reduces the score (0 pts) but does not force automatic F. | 5 | `validate-diagrams.mjs` |
| **D2** | Mermaid render (if present) | If `<pre class="mermaid">` blocks exist, each renders to non-trivial SVG (>500 bytes, contains `<g>` or `<path>`, no `mermaid-error` class). If no Mermaid blocks are present, D2 is trivially passed (5/5) with a note. | 5 | `validate-diagrams.mjs` (jsdom + Mermaid render) |
| **L1** | Anchor links | Every `href="#X"` resolves to in-page `id="X"` | 5 | `validate-html-output.sh` |
| **L2** | Relative md links | Every `./*.md` link points to an existing file in `.aid/knowledge/` | 5 | `validate-html-output.sh` |
| **H1** | HTML validity | If `tidy` or `html-validate` is available, zero errors reported; otherwise regex structural checks pass | 5 | `validate-html-output.sh` |
| **A1** | Semantic landmarks | `<header role="banner">`, `<main>`, `<nav>`, `<footer>` present | 5 | `validate-html-output.sh` |
| **A2** | ARIA on lightbox | Dialog has `role`, `aria-modal`, `aria-labelledby`, `aria-hidden` | 3 | `validate-html-output.sh` |
| **A3** | Focus trap | Inlined `lightbox.js` contains `trapFocusOnTab`, `lastFocused.focus()`, and `key === 'Escape'` | 5 | `validate-html-output.sh` (grep on inlined JS) |
| **A4** | Reduced motion | `prefers-reduced-motion` block present in CSS | 2 | `validate-html-output.sh` |
| **A5** | Visible focus | `:focus-visible` rule present in CSS | 3 | `validate-html-output.sh` |
| **C1** | Light theme contrast | All token pairs in checklist >= target ratios | 4 | `contrast-check.mjs` |
| **C2** | Dark theme contrast | Same | 4 | `contrast-check.mjs` |
| **S2** | Offline render | If Mermaid diagrams are present, the Mermaid library is inlined (or `--cdn-mermaid` chosen explicitly); if no Mermaid diagrams are present, trivially passed (2/2) | 2 | `validate-html-output.sh` |
| | **Machine total** | | **68** | |
| | **Human total** | | **30** | |

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

`grade-summary.sh` computes a **percentage** (`earned x 100 / pool_max`, integer
division) and maps it to a letter. The SAME percentage ladder applies to both
grades -- only the pool max differs (Machine 68, Human 30).

### Percentage ladder (authoritative -- matches `grade-summary.sh` `letter_grade()`)

| Letter | Min % | Machine (of 68) | Human (of 30) |
|--------|-------|-----------------|---------------|
| A+ | >= 98 | >= 67 | 30 |
| A  | >= 95 | >= 65 | >= 29 |
| A- | >= 90 | >= 62 | >= 27 |
| B+ | >= 85 | >= 58 | >= 26 |
| B  | >= 80 | >= 55 | >= 24 |
| B- | >= 75 | >= 51 | >= 23 |
| C+ | >= 70 | >= 48 | >= 21 |
| C  | >= 65 | >= 45 | >= 20 |
| C- | >= 60 | >= 41 | >= 18 |
| D  | >= 49 | >= 34 | >= 15 |
| F  | < 49 | < 34 | < 15 |

The Machine / Human columns are the absolute-point equivalents computed from
the percentage ladder at the current pool sizes -- shown for convenience; the
percentage is what `grade-summary.sh` actually evaluates. **COV coverage < 60%
forces Machine Grade = F regardless of score. V1 failure forces Human Grade = F
regardless of score.**

With the V1 gate passed (5), the reachable Human totals are K1+K2+5 where
K1 in {0,5,10} and K2 in {0,8,15} -- i.e. 5, 10, 13, 15, 18, 20, 23, 25, 30.
A+ requires the full 30 (K1 Full + K2 Full + V1 pass). If V1 fails (0),
Human Grade is F no matter what K1/K2 score.

### Overall Grade

`min(Machine_letter, Human_letter)`. Letter order for min():
A+ > A > A- > B+ > B > B- > C+ > C > C- > D+ > D > F.

If Human Grade is absent (manual-checklist.sh never ran): Overall = **"Pending Human Review"**.

## Hard rules (override the score)

1. **COV coverage < 60% = F.** If fewer than 60% of the resolved doc-set entries
   are represented in the HTML, the Machine Grade is forced to F regardless of
   other points. This is the completeness gate: a summary that omits most of the
   project's documented information is unacceptable.
2. **Missing skip-link OR missing focus-trap = automatic B ceiling** on Machine
   Grade.
3. **Human Grade unscored = APPROVAL blocked.** The two-grade model requires
   running `manual-checklist.sh` before APPROVAL. The script will refuse to
   write `Writeback Status: ok` if the Human Grade is missing from
   `.aid/knowledge/STATE.md` `## Knowledge Summary Status` (per FR2).
4. **V1 visual gate fail = Human Grade F = APPROVAL blocked.** V1 is mandatory.
   If the human visual gate is not affirmatively passed, Human Grade is forced
   to F (so Overall = F), regardless of K1/K2. The summary cannot be approved
   until the visual issue is fixed and V1 re-confirmed. Note: if no visuals are
   present, V1 is trivially passed (5/5) with a note.

> **Diagram-count hard rule: REMOVED.** There is no minimum or maximum diagram
> count. Neither adding nor omitting diagrams affects the Machine Grade ceiling.
> The old "C+ cap unless N diagrams" rule is gone. Visual elements are graded
> on quality and fit (V1 human gate and D1/D2 if Mermaid is used), never on
> count.

## Why the two-grade model

Prior versions auto-passed manual checks (K1 = 10 pts, K2 = 15 pts,
A3 = 5 pts = 30 pts the script could not verify). This created a structural
bias: the script-reported grade was inflated while simultaneously being capped
below A+ because A3 was never actually scored.

The two-grade split makes the trade-off explicit: machines do what machines
can do (now including A3, which is verified by grepping the inlined JS),
humans do what only humans can do (K1, K2, V1), and both grades must clear the
bar for APPROVAL.

**Why V1 (the human visual gate) is mandatory:** during dogfood use, a
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
must have its information represented in the HTML. Full coverage (10/10):
the reviewer confirms every resolved doc appears as a dedicated section or is
explicitly folded into a related section with attribution. Partial (5/10): most
docs (>=80%) are covered; a few are missing or only referenced without content.
None (0/10): major omissions. Reviewer cross-checks the section list against
the resolved doc-set during `manual-checklist.sh`.

**K2:** Every numeric/named fact in headers/cards/tables must be locatable in
a KB doc. Reviewer spot-checks 5-10 facts per run during `manual-checklist.sh`
(the `spot-check-facts.sh` report is a starting point, not a substitute for
human judgment).

**V1 (mandatory gate):** The reviewer opens `kb.html` in a real browser and
confirms ALL of: (a) every visual element renders correctly -- no error blocks,
no collapsed/empty containers; (b) any diagram or infographic text is legible in
BOTH light AND dark themes; (c) the light/dark theme toggle works; (d) the
lightbox opens on click, Esc closes it, Tab cycles focus inside. If no visual
elements are present in the summary, V1 is trivially passed (5/5 with a note
"no visuals to validate"). Pass (5 pts) requires all four points for any
visuals present. Any failure -> V1 = 0 -> Human Grade F -> APPROVAL blocked.

**COV (automated coverage):** `grade-summary.sh` reads `discovery.doc_set` from
`.aid/settings.yml`, intersects with files actually present in `.aid/knowledge/`
(the resolved doc-set), then checks the HTML for a reference to each resolved
doc (by section heading text, anchor `id`, or inline mention of the doc filename
stem). Scoring: coverage >= 95% = 15 pts (full); 80-94% = 8 pts (partial);
60-79% = 3 pts (minimal); < 60% = 0 pts AND forces Machine Grade F. If
`settings.yml` has no `doc_set` field, COV defaults to pass (15 pts) with a
note that coverage check was skipped (settings not yet doc-set-driven).

**D1 (if Mermaid diagrams present):** If the HTML contains `<pre class="mermaid">`
blocks, `mermaid.parse(text)` must not throw for any block. If no Mermaid blocks
exist, D1 is trivially passed (5/5) with a note. A parse failure on a present
block gives 0 pts (but does not force automatic F -- that role belongs to COV).

**D2 (if Mermaid diagrams present):** If the HTML contains `<pre class="mermaid">`
blocks, `validate-diagrams.mjs` calls `mermaid.render()` in jsdom. Each block's
SVG must be >500 bytes, contain `<g>` or `<path>`, and have no `mermaid-error`
class. If no Mermaid blocks exist, D2 is trivially passed (5/5) with a note.

**L1:** Every `href="#X"` must resolve to an element with `id="X"` in the page.

**L2:** Every `<a href="./X.md">` must point to an existing `.aid/knowledge/X.md`.

**H1 cascade:** `validate-html-output.sh` tries in order:
1. `tidy -e --quiet yes` -- fails on any error line.
2. `html-validate` -- fails on errors.
3. Regex fallback (unclosed tags, duplicate IDs, missing `<!DOCTYPE html>`).
The fallback path is noted in the grade output. Warnings allowed in all modes.

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

**S2:** If `<pre class="mermaid">` blocks exist, the Mermaid library must be
inlined (`__esbuild_esm_mermaid` marker), OR `--cdn-mermaid` recorded in
`.aid/knowledge/STATE.md` `## Knowledge Summary Status`. If no Mermaid blocks
are present, S2 is trivially passed (2/2) with a note.

## How a grading run reports

```
$ bash canonical/aid/scripts/summarize/grade-summary.sh .aid/dashboard/kb.html

Validating .aid/dashboard/kb.html ...
Resolved doc-set: 22 docs in discovery.doc_set, 22 present on disk.
Coverage check: 22/22 resolved docs referenced in HTML (100%)

  COV Resolved-doc-set coverage    [PASS] 22/22 (100%)  full      15/15
  D1  Mermaid parse                [PASS] 5/5 parse OK              5/5
  D2  Mermaid render               [PASS] 5/5 non-trivial SVG       5/5
  L1  Anchor links                 [PASS] 13/13 resolve             5/5
  L2  Relative md links            [PASS] 19/19 resolve             5/5
  H1  HTML validity                [PASS] tidy: 0 errors            5/5
  A1  Semantic landmarks           [PASS] header, main, nav, footer  5/5
  A2  ARIA on lightbox             [PASS] role+modal+hidden+labelledby  3/3
  A3  Focus trap                   [PASS] all 3 markers found       5/5
  A4  Reduced motion               [PASS] @media found              2/2
  A5  Visible focus                [PASS] :focus-visible            3/3
  C1  Light theme contrast         [PASS] 11/11 pairs >= target     4/4
  C2  Dark theme contrast          [PASS] 11/11 pairs >= target     4/4
  S2  Offline render               [PASS] Mermaid library inlined   2/2

Machine Score: 68 / 68  (100%)
Machine Grade: A+

  K1  Resolved-doc-set coverage (human)  [MANUAL] run manual-checklist.sh
  K2  KB facts grounded                  [MANUAL] run manual-checklist.sh
  V1  Human visual gate (mandatory)      [MANUAL] run manual-checklist.sh

Human Grade:   Pending Human Review
Overall Grade: Pending Human Review
```

## How failures surface

```
Coverage check: 10/22 resolved docs referenced in HTML (45%)

  COV Resolved-doc-set coverage    [FAIL] 10/22 (45%) < 60% gate    0/15

Machine Grade: F (COV coverage < 60% -- completeness gate failed)
Overall Grade: F
   Re-run /aid-summarize -> it will enter FIX state and add missing sections.
```

```
Coverage check: 18/22 resolved docs referenced in HTML (81%)

  COV Resolved-doc-set coverage    [PASS] 18/22 (81%)  partial      8/15
  ...all other auto checks pass...

Machine Score: 61 / 68  (89%)
Machine Grade: A-
```

```
  COV Resolved-doc-set coverage    [PASS] 22/22 (100%)  full       15/15
  D1  Mermaid parse                [PASS] no Mermaid blocks -- trivially passed  5/5
  D2  Mermaid render               [PASS] no Mermaid blocks -- trivially passed  5/5
  S2  Offline render               [PASS] no Mermaid blocks -- trivially passed  2/2
  ...
```
