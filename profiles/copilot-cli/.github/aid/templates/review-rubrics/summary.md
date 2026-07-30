# Review Rubric — SUMMARY class

**Family:** Presentation — [`presentation.md`](presentation.md)'s rules apply in full and are not
repeated here.
**Kind:** **A + E** — the only class in the catalog carrying two review kinds.
**Universal tier:** [`INDEX.md`](INDEX.md).

Severity is looked up from
[`grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale).

---

## Why this class exists separately from its family

A generated knowledge summary is a Presentation artifact — so accessibility, tokens and layout are
governed by `presentation.md`. But it is also a set of **claims about the Knowledge Base**, and the
Presentation family has no vocabulary for "what it says is wrong".

Its **intent authority is the KB it summarises** (`INDEX.md`, per-class table). So the class-specific
rules below are content-truth rules, borrowed in substance from the Narrative family's
claim–evidence discipline but declared here — because an artifact resolves to exactly one rule set,
and this one's family is Presentation.

**Two kinds, and both are required.**

- **Kind A** — an agent reads the whole document against the rules below and produces findings.
- **Kind E** — a machine score plus a **mandatory human checklist**, because no agent sees a rendered
  page. An agent's "no violations" is not a statement that the summary is legible or that its visuals
  render.

Neither substitutes for the other. A clean agent pass with no human checklist is an **incomplete
review**, not a pass.

---

## Content-truth rules

| Rule | Check | Criterion | Modality | Mode | Evidence | Severity |
|---|---|---|---|---|---|---|
| `SUMMARY-01` | Every resolved doc-set document is represented in the summary | `settings.yml`'s `knowledge.doc_set`, as the declared set the summary covers | MUST | mechanical | Compare the doc set against the documents the summary references. **One row per unreferenced document** | `[MEDIUM]` — confined to readers of the summary, and regenerating corrects it |
| `SUMMARY-02` | The summary's markup is valid | `knowledge-summary/grading-rubric.md` — the HTML-validity check | MUST | mechanical | Run the declared validator | `[MEDIUM]` |
| `SUMMARY-03` | The summary is self-contained — it renders with no external fetch | `knowledge-summary/grading-rubric.md` — the self-contained check | MUST | mechanical | Load with the network disabled; any external request is the finding | `[HIGH]` — an offline reader gets a broken page, so the radius has escaped the artifact |
| `SUMMARY-04` | No claim in the summary contradicts the KB it summarises | `INDEX.md` universal taxonomy class 2 (Contradiction); intent authority is the KB | MUST | judgment | For each load-bearing claim, quote the summary's statement and the KB's. **The KB wins** | `Step 2` |
| `SUMMARY-05` | Every load-bearing claim is grounded in a KB document, not inferred | `authoring-conventions.md § Citation Rule (Durable Anchors)` | MUST | judgment | Name the KB document supporting each load-bearing claim. An ungrounded claim is the finding | `Step 2` |
| `SUMMARY-06` | Every visual renders and is legible | `knowledge-summary/grading-rubric.md` — the visual-fidelity checks | MUST | judgment | **Human evidence only** — an agent cannot satisfy this rule. One row per failing visual | `[HIGH]` |
| `SUMMARY-07` | The summary carries no diagram runtime that was retired | `knowledge-summary/grading-rubric.md` — the no-runtime check | MUST | mechanical | `grep` for the retired runtime | `[HIGH]` |
| `SUMMARY-08` | Every in-page anchor resolves to an element in the document | `knowledge-summary/grading-rubric.md § Check definitions` — the `L1` definition | MUST | mechanical | Resolve each `href="#X"` against the document's IDs. One row per unresolved anchor | `[LOW]` — a dead in-page jump is contained, visible, and fixed by regenerating |
| `SUMMARY-09` | Every relative document link points at a file that exists | `knowledge-summary/grading-rubric.md § Check definitions` — the `L2` definition | MUST | mechanical | Resolve each `./*.md` link against the tree. One row per broken link | `[MEDIUM]` — it sends the reader out of the summary to nothing, so the radius leaves the artifact |

---

## Where the retired per-check scores went

The generated summary used to be graded by a **second** grading model: a weighted-points ladder over
fourteen automated checks plus a thirty-point manual pool. That model is gone — `grade.sh` is now the
only producer of a letter grade. Every check it scored is accounted for here, so retiring the ladder
removes a *scoring mechanism*, not *coverage*.

| Retired check | Now expressed as | Note |
|---|---|---|
| `COV` resolved-doc-set coverage | `SUMMARY-01` | Was partial credit on a band; now one finding per unreferenced document |
| `D1` Mermaid parse | **deleted** | Hardcoded `pass` since the Mermaid engine was retired |
| `D2` Mermaid render | **deleted** | Same — together these were 10 of 68 points that could never be lost |
| `L1` anchor links | `SUMMARY-08` | |
| `L2` relative md links | `SUMMARY-09` | |
| `H1` HTML validity | `SUMMARY-02` | |
| `A1` semantic landmarks | `PRE-02` | Family rule — not repeated here |
| `A2` ARIA on lightbox | `PRE-04` | Family rule |
| `A3` focus trap | `PRE-04` | Family rule |
| `A4` reduced motion | `PRE-05` | Family rule |
| `A5` visible focus | `PRE-03` | Family rule — `:focus-visible` sits under *Keyboard reach* |
| `C1` light theme contrast | `PRE-11` | Family gap this delivery closed |
| `C2` dark theme contrast | `PRE-11` | One rule, both themes |
| `S2` offline render | `SUMMARY-03` | |
| `K1` doc-set coverage (human) | `SUMMARY-01` | Same claim as `COV`, asked of a human |
| `K2` KB facts grounded | `SUMMARY-05` | |
| `V1` human visual gate | `SUMMARY-06` | Including the `T1`/`T2` legibility and overlap sub-gates |

**Why the accessibility checks are not restated as `SUMMARY-*` rows.** This class declares that its
family's rules "apply in full and are not repeated here". Copying `A1`–`A5` into this file would create
a second statement of a family rule that could drift from the first — the same duplication this work
exists to remove. They are cited above so the mapping is auditable, not restated as rules.

---

## Notes for reviewers of this class

**`SUMMARY-01` fires once per unreferenced document, and that is deliberate.** The check it replaces
awarded partial credit on a percentage band, so a summary missing one document out of twenty scored
full marks. Under this rule one missing document is one `[MEDIUM]`, which lands the grade below a
passing bar. That is a real tightening: a KB document whose content is absent from the project summary
is a defect, and costing it nothing was the bug.

**`SUMMARY-04` and `SUMMARY-05` are the rules the machine suite cannot reach.** The validators prove
the HTML is well-formed and accessible. They cannot tell you a number is wrong. That gap is the whole
reason this class takes kind A in addition to kind E.

**`SUMMARY-06` is human-only, and must not be answered by an agent.** If the checklist has not been
completed, the correct outcome is **no grade at all** — a pause for the human — rather than a failing
grade. Unanswered is not the same as failed.

---

## See also

- [`presentation.md`](presentation.md) — the family rules, which apply in full
- [`INDEX.md`](INDEX.md) — universal tier and routing
- [`grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale) — severity derivation

## Change Log

| Date | Change |
|---|---|
| 2026-07-28 | Created. Seven content-truth rules, per the amendment requiring this class to carry them rather than inherit Narrative. |
