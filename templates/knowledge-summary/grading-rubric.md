# Grading Rubric

The skill's `VALIDATE` state runs `scripts/grade.sh` against the generated
`knowledge-summary.html`. Each check is binary pass/fail; the grade is the
weighted aggregate. **Any unparseable Mermaid diagram is an automatic F.**

## Check definitions

| ID | Check | Pass condition | Weight | Verifier |
|----|-------|----------------|--------|----------|
| **K1** | KB completeness | Every populated KB doc that maps to a section is read and reflected | 10 | manual |
| **K2** | KB facts grounded | All numeric/named facts in the HTML appear verbatim in source KB | 15 | manual |
| **D1** | Mermaid parse | `mermaid.parse()` succeeds for every block | 20 | `validate-diagrams.mjs` |
| **D2** | Mermaid render | Each block produces non-empty SVG when rendered | 10 | `validate-diagrams.mjs` |
| **L1** | Anchor links | Every `href="#X"` resolves to in-page `id="X"` | 5 | `validate-links.sh` |
| **L2** | Relative md links | Every `./*.md` link points to an existing file in `.aid/knowledge/` | 5 | `validate-links.sh` |
| **H1** | HTML validity | `tidy` (or `html-validate`) reports no errors (warnings allowed) | 5 | `validate-html.sh` |
| **A1** | Semantic landmarks | `<header role="banner">`, `<main>`, `<nav>`, `<footer>` present | 5 | `validate-html.sh` |
| **A2** | ARIA on lightbox | Dialog has `role`, `aria-modal`, `aria-labelledby`, `aria-hidden` | 3 | `validate-html.sh` |
| **A3** | Focus trap | Tab cycles within open lightbox; restored on close | 5 | manual / can't auto |
| **A4** | Reduced motion | `prefers-reduced-motion` block present in CSS | 2 | `validate-html.sh` |
| **A5** | Visible focus | `:focus-visible` rule present in CSS | 3 | `validate-html.sh` |
| **C1** | Light theme contrast | All token pairs in checklist ≥ target ratios | 4 | `contrast-check.mjs` |
| **C2** | Dark theme contrast | Same | 4 | `contrast-check.mjs` |
| **S2** | Offline render | Mermaid library is inlined (or `--cdn-mermaid` chosen explicitly) | 2 | `validate-html.sh` |
| | **Total** | | **98** | |

> File size is **not graded**. The output's actual size is recorded in
> `SUMMARY-STATE.md` for transparency, but no maximum is enforced.

## Grade boundaries (over a 98-point total)

| Grade | Score | Conditions |
|-------|-------|------------|
| A+ | ≥ 96 | Perfect or near-perfect |
| A | ≥ 93 | No D1/D2/A3 failures |
| A− | ≥ 88 | At most 1 minor failure |
| B+ | ≥ 83 | |
| B | ≥ 78 | |
| B− | ≥ 73 | |
| C+ | ≥ 68 | |
| C | ≥ 63 | |
| C− | ≥ 58 | |
| D+/D | ≥ 48 | Deliverable but flawed |
| F | < 48 OR any D1 failure | |

## Hard rules (override the score)

1. **D1 fail = F.** Even one diagram that fails to parse means the whole HTML
   is graded F. There is no partial credit. Fix the diagram before re-grading.
2. **Less than 6 diagrams = automatic C+ ceiling.** Diagrams are core to the
   value proposition. A summary with only 2 or 3 diagrams hasn't met the spec.
3. **Missing skip-link OR missing focus-trap = automatic B ceiling.**

## Per-check pass criteria details

### K1 — KB completeness

Every populated `.aid/knowledge/*.md` that the active profile expects must be
read and represented somewhere in the HTML. Empty docs (still `❌ Pending`) are
exempt.

**Pass:** for each expected doc, the HTML contains either:
- A section that links to it (caption or "Source:" reference), or
- Inline content extracted from it.

**Verification:** the agent reads the section list from the active profile
template, cross-checks against the HTML during VALIDATE.

### K2 — KB facts grounded

Numeric and named facts in the HTML (file counts, version pins, entity counts,
endpoint names) must appear in the source KB documents. Don't invent numbers.

**Pass:** for each numeric or named fact in headers/cards/tables, the agent
can locate it in a KB document.

**Verification:** spot-check 5–10 facts per run during VALIDATE.

### D1 — Mermaid parse (THE CRITICAL CHECK)

Every `<pre class="mermaid">` block must parse successfully via
`mermaid.parse(text)`. The validator extracts each block with regex and runs
parse in isolation.

**Pass:** all blocks return without throwing.

**Fail:** ANY block throws → automatic F. The error message and source block
location are written to SUMMARY-STATE.md so FIX state can repair them.

Common failure causes (see `mermaid-examples.md` for full list):
- HTML-tag-like tokens in labels (`<word>` — use `{word}` instead)
- Missing spaces around dotted-arrow text (`-.text.->` — use `-. text .->`)
- Continuation arrows with no source on a new line
- Unclosed quotes in node labels
- Reserved words used as type names in erDiagram

### D2 — Mermaid render

Each block must produce a non-empty SVG when rendered. Catches edge cases
where parse succeeds but layout fails (circular references, unrenderable
clusters).

**Pass:** all blocks produce SVG with `<svg>...</svg>` and at least one
`<rect>` or `<text>` element inside.

**Verification:** `validate-diagrams.mjs` renders each block via Mermaid's
`render()` API and checks output length and structure.

### L1 — Anchor links

For every `href="#X"` in the HTML, there must be a matching element with
`id="X"`.

**Pass:** all in-page anchors resolve.

### L2 — Relative md links

For every `<a href="./X.md">`, the file `.aid/knowledge/X.md` must exist.

**Pass:** all relative md links resolve.

### H1 — HTML validity

Run an HTML validator (`tidy` or `html-validate`). Warnings are OK, errors
are not.

**Pass:** zero errors.

### A1 — Semantic landmarks

The HTML must contain:
- `<header role="banner">` (the top bar)
- `<main>` (with `id="top"` for skip-link)
- At least one `<nav aria-label="...">`
- `<footer>`

**Pass:** all four landmarks present.

### A2 — ARIA on lightbox

The `#lightbox` element must have:
- `role="dialog"`
- `aria-modal="true"`
- `aria-hidden="true"` (default state)
- `aria-labelledby="..."` referencing an existing element

**Pass:** all four attributes present and correct.

### A3 — Focus trap

When lightbox opens, focus moves into it. Tab cycles within it. Esc closes
and returns focus to the originating element.

**Pass:** code has `getLightboxFocusables()`, `trapFocusOnTab()`, and
`lb.lastFocused` restoration logic.

### A4 — Reduced motion

CSS contains `@media (prefers-reduced-motion: reduce)` block that disables
animations and transitions.

**Pass:** the @media block is present and contains rules.

### A5 — Visible focus

CSS contains `:focus-visible` rule with visible outline.

**Pass:** rule present.

### C1 / C2 — Theme contrast

`contrast-check.mjs` computes WCAG AA ratios for the token pairs listed in
`accessibility-checklist.md`. Each pair must meet its target.

**Pass:** all pairs meet target in the named theme.

### S2 — Offline render

Either:
- The Mermaid library is inlined (look for a `<script>` tag containing
  `__esbuild_esm_mermaid` or similar marker), OR
- `--cdn-mermaid` was passed (recorded in SUMMARY-STATE.md).

**Pass:** offline-capable OR explicit CDN opt-in.

## How a grading run reports

```
$ scripts/grade.sh .aid/knowledge/knowledge-summary.html

Validating .aid/knowledge/knowledge-summary.html ...

  D1 Mermaid parse          [PASS]   8/8 diagrams parse cleanly
  D2 Mermaid render         [PASS]   8/8 produced non-empty SVG
  L1 Anchor links           [PASS]   13/13 resolve
  L2 Relative md links      [PASS]   19/19 resolve
  H1 HTML validity          [PASS]   tidy: 0 errors
  A1 Semantic landmarks     [PASS]   header, main, nav, footer
  A2 ARIA on lightbox       [PASS]   role + modal + hidden + labelledby
  A3 Focus trap             [PASS]   trapFocusOnTab present
  A4 Reduced motion         [PASS]   @media (prefers-reduced-motion) found
  A5 Visible focus          [PASS]   :focus-visible rule found
  C1 Light theme contrast   [PASS]   11/11 pairs ≥ target
  C2 Dark theme contrast    [PASS]   11/11 pairs ≥ target
  S2 Offline render         [PASS]   Mermaid library inlined (3.16 MB)
  K1 KB completeness        [MANUAL] (agent verifies during VALIDATE)
  K2 KB facts grounded      [MANUAL] (agent verifies during VALIDATE)

Score: 78 / 78 automated points.
With manual checks (assumed pass): 98 / 98.

Grade: A+
```

## How a failure surfaces

```
  D1 Mermaid parse          [FAIL]   1/8 diagrams failed
                                     Figure 3:
                                       Expecting 'NUM', 'NODE_STRING', got '<'
                                       Source: ... /mam.<plugin>/<Resource> ...

❌ Grade: F (D1 failure forces automatic F)
   Re-run /aid-summarize → it will enter FIX state and repair Figure 3.
```
