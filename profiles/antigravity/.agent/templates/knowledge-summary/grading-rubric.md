# Grading Rubric

The skill's `VALIDATE` state runs `.agent/scripts/grade.sh` against the generated
`knowledge-summary.html`. Each check is binary pass/fail; the grade is the
weighted aggregate. **Any unparseable Mermaid diagram is an automatic F.**

## Two-Grade Model

Every run produces two independent grades:

| Grade | Checks | Max pts | How scored |
|-------|--------|---------|------------|
| **Machine Grade** | D1, D2, L1, L2, H1, A1, A2, A3, A4, A5, C1, C2, S2 | 73 | `grade.sh` runs automatically |
| **Human Grade** | K1, K2, **V1** | 30 | `manual-checklist.sh` run by a human reviewer |

**Overall Grade = min(Machine letter, Human letter).**

A+ requires both Machine ≥ 98% (72/73) and Human ≥ 98% (30/30). If
`manual-checklist.sh` has never run, the Human Grade is absent and Overall is
reported as **"Pending Human Review"** — APPROVAL is blocked until the user
grade exists.

> **Pool total = 73 + 30 = 103.** `grade.sh` sums the AUTO_POOL weights at
> runtime (it is not a hard-coded constant) — if a check's weight changes, the
> total tracks it automatically. The 73 below is the current sum.

> **V1 is a MANDATORY GATE.** The human visual gate (5 pts) must be
> affirmatively passed. If V1 fails — or the checklist has not been run —
> the Human Grade is forced to **F** regardless of K1/K2, so APPROVAL is
> blocked. Rationale: this whole check exists because automated checks
> (C1/C2 contrast, D1/D2 diagrams) can ALL pass while a diagram is visually
> unreadable — e.g. Mermaid node-label colors are not covered by C1/C2.
> Only the user looking at the rendered output catches that.

## Check definitions

| ID | Check | Pass condition | Weight | Verifier |
|----|-------|----------------|--------|----------|
| **K1** | KB completeness | Every populated KB doc that maps to a section is read and reflected | 10 | manual (`manual-checklist.sh`) |
| **K2** | KB facts grounded | All numeric/named facts in the HTML appear verbatim in source KB | 15 | manual (`manual-checklist.sh`) |
| **V1** | Human visual gate (mandatory) | The user opens the HTML in a browser and confirms ALL of: every diagram renders (no error blocks); diagram + node text is legible in BOTH light AND dark themes; theme toggle works; lightbox opens / Esc closes / Tab cycles. Pass=5, fail=0. **V1=0 forces Human Grade F.** | 5 | manual (`manual-checklist.sh`) |
| **D1** | Mermaid parse | `mermaid.parse()` succeeds for every block | 20 | `validate-diagrams.mjs` |
| **D2** | Mermaid render | Each block renders to non-trivial SVG (>500 bytes, contains `<g>` or `<path>`, no `mermaid-error` class) | 10 | `validate-diagrams.mjs` (jsdom + Mermaid render) |
| **L1** | Anchor links | Every `href="#X"` resolves to in-page `id="X"` | 5 | `validate-html-output.sh` |
| **L2** | Relative md links | Every `./*.md` link points to an existing file in `.aid/knowledge/` | 5 | `validate-html-output.sh` |
| **H1** | HTML validity | If `tidy` or `html-validate` is available, zero errors reported; otherwise regex structural checks pass | 5 | `validate-html-output.sh` |
| **A1** | Semantic landmarks | `<header role="banner">`, `<main>`, `<nav>`, `<footer>` present | 5 | `validate-html-output.sh` |
| **A2** | ARIA on lightbox | Dialog has `role`, `aria-modal`, `aria-labelledby`, `aria-hidden` | 3 | `validate-html-output.sh` |
| **A3** | Focus trap | Inlined `lightbox.js` contains `trapFocusOnTab`, `lastFocused.focus()`, and `key === 'Escape'` | 5 | `validate-html-output.sh` (grep on inlined JS) |
| **A4** | Reduced motion | `prefers-reduced-motion` block present in CSS | 2 | `validate-html-output.sh` |
| **A5** | Visible focus | `:focus-visible` rule present in CSS | 3 | `validate-html-output.sh` |
| **C1** | Light theme contrast | All token pairs in checklist ≥ target ratios | 4 | `contrast-check.mjs` |
| **C2** | Dark theme contrast | Same | 4 | `contrast-check.mjs` |
| **S2** | Offline render | Mermaid library is inlined (or `--cdn-mermaid` chosen explicitly) | 2 | `validate-html-output.sh` |
| | **Machine total** | | **73** | |
| | **Human total** | | **30** | |

> File size is **not graded**. The output's actual size is recorded in
> `.aid/knowledge/STATE.md` `## Knowledge Summary Status` for transparency
> (per FR2; pre-FR2 this lived in `SUMMARY-STATE.md`), but no maximum is enforced.

## Grade boundaries

`grade.sh` computes a **percentage** (`earned × 100 / pool_max`, integer
division) and maps it to a letter. The SAME percentage ladder applies to both
grades — only the pool max differs (Machine 73, Human 30).

### Percentage ladder (authoritative — matches `grade.sh` `letter_grade()`)

| Letter | Min % | Machine (of 73) | Human (of 30) |
|--------|-------|-----------------|---------------|
| A+ | ≥ 98 | ≥ 72 | 30 |
| A  | ≥ 95 | ≥ 70 | ≥ 29 |
| A− | ≥ 90 | ≥ 66 | ≥ 27 |
| B+ | ≥ 85 | ≥ 63 | ≥ 26 |
| B  | ≥ 80 | ≥ 59 | ≥ 24 |
| B− | ≥ 75 | ≥ 55 | ≥ 23 |
| C+ | ≥ 70 | ≥ 52 | ≥ 21 |
| C  | ≥ 65 | ≥ 48 | ≥ 20 |
| C− | ≥ 60 | ≥ 44 | ≥ 18 |
| D  | ≥ 49 | ≥ 36 | ≥ 15 |
| F  | < 49 | < 36 | < 15 |

The Machine / Human columns are the absolute-point equivalents computed from
the percentage ladder at the current pool sizes — shown for convenience; the
percentage is what `grade.sh` actually evaluates. **D1 failure forces Machine
Grade = F regardless of score; V1 failure forces Human Grade = F regardless
of score.**

With the V1 gate passed (5), the reachable Human totals are K1+K2+5 where
K1 ∈ {0,5,10} and K2 ∈ {0,8,15} — i.e. 5, 10, 13, 15, 18, 20, 23, 25, 30.
A+ requires the full 30 (K1 Full + K2 Full + V1 pass). If V1 fails (0),
Human Grade is F no matter what K1/K2 score.

### Overall Grade

`min(Machine_letter, Human_letter)`. Letter order for min():
A+ > A > A− > B+ > B > B− > C+ > C > C− > D+ > D > F.

If Human Grade is absent (manual-checklist.sh never ran): Overall = **"Pending Human Review"**.

## Hard rules (override the score)

1. **D1 fail = F.** Even one diagram that fails to parse means the whole HTML
   is graded F. There is no partial credit. Fix the diagram before re-grading.
2. **Fewer diagrams than the active profile's `target_diagrams` = automatic C+
   ceiling.** Profile templates declare `target_diagrams: N` in frontmatter;
   `grade.sh` reads `.aid/knowledge/STATE.md` `## Knowledge Summary Status` to find the active profile, then reads
   the profile template to find N. If the HTML has fewer than N
   `<pre class="mermaid">` blocks, the Machine Grade is capped at C+ regardless
   of other points.
3. **Missing skip-link OR missing focus-trap = automatic B ceiling** on Machine
   Grade.
4. **Human Grade unscored = APPROVAL blocked.** The two-grade model requires
   running `manual-checklist.sh` before APPROVAL. The script will refuse to
   write `Writeback Status: ok` if the Human Grade is missing from
   `.aid/knowledge/STATE.md` `## Knowledge Summary Status` (per FR2).
5. **V1 visual gate fail = Human Grade F = APPROVAL blocked.** V1 is mandatory.
   If the human visual gate is not affirmatively passed, Human Grade is forced
   to F (so Overall = F), regardless of K1/K2. The summary cannot be approved
   until the visual defect is fixed and V1 re-confirmed.

## Why the two-grade model

Prior versions auto-passed manual checks (K1 = 10 pts, K2 = 15 pts,
A3 = 5 pts = 30 pts the script couldn't verify). This created a structural
bias: the script-reported grade was inflated while simultaneously being capped
below A+ because A3 was never actually scored.

The two-grade split makes the trade-off explicit: machines do what machines
can do (now including A3, which is verified by grepping the inlined JS),
humans do what only humans can do (K1, K2, V1), and both grades must clear the
bar for APPROVAL.

**Why V1 (the human visual gate) is mandatory:** during dogfood use, a
generated summary passed *every* automated check — D1/D2 (diagrams parse and
render), C1/C2 (theme contrast), all of A1–A5 — while its Mermaid node labels
were genuinely unreadable in dark mode (silver text on teal, ~1.2:1). The
automated contrast checks (C1/C2) only measure the page's CSS theme tokens;
they do not and cannot measure the colors *inside* a Mermaid-rendered SVG.
No automated check covers "does the rendered diagram actually look right." V1
closes that hole: the user must open the file and look, in both themes, before
the summary can be approved.

*Identified during dogfood discovery of AID against itself, 2026-05-21;
tracked as `tech-debt.md H8`.*

## Per-check pass criteria details

**K1:** Every populated KB doc the active profile expects must appear in the
HTML (section link or inline content). Empty `❌ Pending` docs exempt.
Reviewer cross-checks profile section list during `manual-checklist.sh`.

**K2:** Every numeric/named fact in headers/cards/tables must be locatable in
a KB doc. Reviewer spot-checks 5–10 facts per run during `manual-checklist.sh`
(the `spot-check-facts.sh` report is a starting point, not a substitute for
human judgment).

**V1 (mandatory gate):** The reviewer opens `knowledge-summary.html` in a real
browser and confirms ALL of: (a) every Mermaid diagram renders — no red error
blocks; (b) diagram + node-label text is legible in BOTH light AND dark themes
— pay specific attention to text inside colored Mermaid nodes, which no
automated check covers; (c) the light/dark theme toggle works; (d) the lightbox
opens on click, Esc closes it, Tab cycles focus inside. Pass (5 pts) requires
all four. Any failure → V1 = 0 → Human Grade F → APPROVAL blocked. Also verify
the EXPANDED (lightbox) view, not only the inline diagrams — they can differ.

**D1 (critical):** `mermaid.parse(text)` must not throw for any block. ANY
failure → automatic F; error + source location written to
`.aid/knowledge/STATE.md` `## Knowledge Summary Status` `### Findings (last validation)` (per FR2).
Common causes: `<word>` labels (use `{word}`), missing spaces in dotted arrows,
unclosed quotes, reserved words in erDiagram. See `mermaid-examples.md`.

**D2:** `validate-diagrams.mjs` calls `mermaid.render()` in jsdom. SVG must be
>500 bytes, contain `<g>` or `<path>`, and have no `mermaid-error` class.

**L1:** Every `href="#X"` must resolve to an element with `id="X"` in the page.

**L2:** Every `<a href="./X.md">` must point to an existing `.aid/knowledge/X.md`.

**H1 cascade:** `validate-html-output.sh` tries in order:
1. `tidy -e --quiet yes` — fails on any error line.
2. `html-validate` — fails on errors.
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

**S2:** Mermaid library inlined (`__esbuild_esm_mermaid` marker), OR
`--cdn-mermaid` recorded in `.aid/knowledge/STATE.md` `## Knowledge Summary Status` (per FR2).

## How a grading run reports

```
$ bash .agent/scripts/grade.sh .aid/knowledge/knowledge-summary.html

Validating .aid/knowledge/knowledge-summary.html ...
Active profile: web-app  (target_diagrams: 8)
Diagram count:  8 <pre class="mermaid"> blocks found.

  D1 Mermaid parse          [PASS]   8/8 diagrams parse cleanly
  D2 Mermaid render         [PASS]   8/8 produced non-trivial SVG (jsdom)
  L1 Anchor links           [PASS]   13/13 resolve
  L2 Relative md links      [PASS]   19/19 resolve
  H1 HTML validity          [PASS]   tidy: 0 errors
  A1 Semantic landmarks     [PASS]   header, main, nav, footer
  A2 ARIA on lightbox       [PASS]   role + modal + hidden + labelledby
  A3 Focus trap             [PASS]   trapFocusOnTab + lastFocused.focus() + key==='Escape' found
  A4 Reduced motion         [PASS]   @media (prefers-reduced-motion) found
  A5 Visible focus          [PASS]   :focus-visible rule found
  C1 Light theme contrast   [PASS]   11/11 pairs ≥ target
  C2 Dark theme contrast    [PASS]   11/11 pairs ≥ target
  S2 Offline render         [PASS]   Mermaid library inlined (3.16 MB)
  K1 KB completeness        [MANUAL] run manual-checklist.sh
  K2 KB facts grounded      [MANUAL] run manual-checklist.sh
  V1 Human visual gate      [MANUAL] run manual-checklist.sh (mandatory)

Machine Score: 73 / 73  (100%)
Machine Grade: A+

Human Grade:   Pending Human Review
Overall Grade: Pending Human Review
```

## How a failure surfaces

```
  D1 Mermaid parse          [FAIL]   1/8 diagrams failed
                                     Figure 3:
                                       Expecting 'NUM', 'NODE_STRING', got '<'
                                       Source: ... /mam.<plugin>/<Resource> ...

Machine Grade: F (D1 failure forces automatic F)
Overall Grade: F
   Re-run /aid-summarize → it will enter FIX state and repair Figure 3.
```

```
Active profile: cli  (target_diagrams: 4)
Diagram count:  2 <pre class="mermaid"> blocks found.

  ...all 13 auto checks pass...

Machine Score: 73 / 73 (100%, before cap)
Hard rule: fewer diagrams than target_diagrams (2 < 4) → Machine Grade capped at C+
Machine Grade: C+
```
