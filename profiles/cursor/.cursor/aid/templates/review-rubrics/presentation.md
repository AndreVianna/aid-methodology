# Review Rubric — Presentation family

**Members:** `UI`, `THEME`, `DASHBOARD`, `DIAGRAM`, `SUMMARY`
**Kind:** A (adversarial content grade). `SUMMARY` additionally takes kind E — see
[`summary.md`](summary.md).
**Universal tier:** [`INDEX.md`](INDEX.md) — the defect taxonomy, the two authority ladders,
severity derivation and evidence admissibility all apply and are not restated here.

Severity is looked up from
[`grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale).

---

## What this family is for

A presentation artifact is **read by a person**, which makes two things true that hold nowhere else
in the catalog. Accessibility is a correctness property rather than a nicety, and some defects are
only visible to a human eye — no agent can confirm that a rendered page is legible.

That second point is why this family's classes may carry a **mandatory human checklist** alongside the
agent pass. An agent finding of "no accessibility violations" is not a statement that the artifact
looks right.

**Portability note.** Each `Criterion` cites a document and section by name. When the declaring
section is absent the rule **cannot fire**, and the concern is a criteria gap rather than a finding.

---

## Rules

| Rule | Check | Criterion | Modality | Mode | Evidence | Severity |
|---|---|---|---|---|---|---|
| `PRE-01` | Document-level accessibility requirements are met | `knowledge-summary/accessibility-checklist.md § Document level` | MUST | mechanical | Run the declared validator; each unmet item is a finding | `[MEDIUM]` — confined to readers of this artifact, and a local edit corrects it |
| `PRE-02` | Semantic landmarks are present and correctly nested | `knowledge-summary/accessibility-checklist.md § Landmarks (semantic HTML)` | MUST | mechanical | Validate the landmark structure | `[MEDIUM]` |
| `PRE-03` | Every interactive element is keyboard reachable | `knowledge-summary/accessibility-checklist.md § Keyboard reach` | MUST | judgment | Name each interactive element and its tab path. An unreachable element is the finding | `[MEDIUM]` |
| `PRE-04` | A modal or dialog traps and restores focus correctly | `knowledge-summary/accessibility-checklist.md § Lightbox dialog` | MUST | judgment | Name where focus goes on open, on close, and on escape | `[MEDIUM]` |
| `PRE-05` | Motion respects the reduced-motion preference | `knowledge-summary/accessibility-checklist.md § Reduced motion` | MUST | mechanical | Check each animation for a reduced-motion guard | `[MEDIUM]` |
| `PRE-06` | Diagrams carry text alternatives | `knowledge-summary/accessibility-checklist.md § Diagrams` | MUST | mechanical | Check each diagram for its declared alternative | `[MEDIUM]` |
| `PRE-07` | Colours come from the declared palette, not ad-hoc values | `knowledge-summary/design-tokens.md § Color palette` | MUST | mechanical | `grep` for colour literals outside the token set | `[MEDIUM]` |
| `PRE-08` | Type follows the declared typography scale | `knowledge-summary/design-tokens.md § Typography` | SHOULD | mechanical | `grep` for font sizes outside the scale | `[LOW]; escaped (>1 component) → [MEDIUM]` |
| `PRE-09` | Spacing follows the declared scale | `knowledge-summary/design-tokens.md § Spacing & sizing` | SHOULD | mechanical | `grep` for spacing values outside the scale | `[LOW]; escaped (>1 component) → [MEDIUM]` |
| `PRE-10` | A project theming override uses the declared override mechanism | `knowledge-summary/design-tokens.md § Theming overrides per project` | SHOULD | judgment | Name each override and the mechanism it uses | `[LOW]; escaped (>1 override) → [MEDIUM]` |
| `PRE-11` | Every declared token pair meets WCAG AA contrast, in every theme the artifact ships | `knowledge-summary/accessibility-checklist.md § Color contrast (WCAG AA)` | MUST | mechanical | Run the contrast checker over the token pairs, once per theme. One row per failing pair, naming the theme and the measured ratio | `[MEDIUM]` |

---

## Why these anchor `[MEDIUM]` rather than `Step 2`

An accessibility or token violation in a rendered artifact affects **readers of that artifact**, and
regenerating or editing the artifact corrects it. That is *confined* plus *local*, which the canonical
scale puts at `[MEDIUM]`. These are therefore Fixed anchors rather than `Step 2` — the
radius/reversibility shape does not vary between instances.

The exception is an artifact that other artifacts are **built from** (a shared theme, a token file). A
violation there has escaped, and the reviewer should treat the anchor as `Step 2` and name the
dependent.

---

## What this family does not yet cover

Responsive behaviour and state coverage are named as family concerns in `INDEX.md` but have **no
declaring document** in this installation, so they carry no rules. A reviewer who believes a
responsive defect matters should **raise the criteria gap**, not invent the rule.

---

## See also

- [`INDEX.md`](INDEX.md) — universal tier and routing
- [`summary.md`](summary.md) — the `SUMMARY` class, which adds content-truth rules and a human gate
- [`grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale) — severity derivation

## Change Log

| Date | Change |
|---|---|
| 2026-07-28 | Created. Ten grounded rules; responsive behaviour and state coverage left as criteria gaps rather than invented. |
| 2026-07-29 | Added `PRE-11` (WCAG AA contrast, per theme). The retiring summary grader scored contrast as `C1`/`C2` while no family rule covered it, so retiring that grader would have dropped the check entirely. One rule spans all themes: the criterion is identical and only the palette changes. |
