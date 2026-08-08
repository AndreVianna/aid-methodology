# Review Rubric — KB class

**Family:** Narrative — [`narrative.md`](narrative.md)'s rules apply in full and are not repeated here.
**Kind:** A (adversarial content grade)
**Universal tier:** [`INDEX.md`](INDEX.md)

Severity is looked up from
[`grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale).

---

## Why this file exists

Two reasons, both discovered rather than planned.

**The KB class had no rule IDs.** It routed to
[`kb-authoring/review-rubric.md`](../kb-authoring/review-rubric.md), whose table is
`Check | Definition | Evidence anchor | Severity` — a genuine rubric, but with nothing a ledger's `Rule`
column could cite. So a KB finding could not name the rule it violated, and the reviewer prompts had to
carry a `KB-NN` placeholder rather than fabricate an ID.

**The criteria were living in the caller.** `aid-discover`'s REVIEW state carried two tables of
severity-tagged authoring checks inside its *dispatch* prose. Those are rule rows: they say what a KB
document is graded for, they are stable across runs, and every reviewer of a KB document needs them.
Keeping them in one skill's state machine meant no other caller could apply them and no ledger row could
cite them.

`kb-authoring/review-rubric.md` stays where it is and remains the authority for the panel's
insufficiency taxonomy. This file assigns the IDs and carries the authoring-standard rows.

---

## Authoring-standard rules

Relocated from `aid-discover`'s REVIEW state. Apply to **hand-authored `primary` / `extension` KB
documents only** — `kb-category: meta` process and ledger docs (`STATE.md`, `README.md`) take a
spot-check, and generated docs (`INDEX.md`, `kb.html`) take build-verify.

| Rule | Check | Criterion | Modality | Mode | Evidence | Severity |
|---|---|---|---|---|---|---|
| `KB-01` | Frontmatter is the document's first block, before any content | `authoring-conventions.md § KB Document Layout` | MUST | mechanical | Read line 1; anything before `---` is the finding | `[HIGH]` |
| `KB-02` | A `## Contents` index is present near the top, for a document with more than three sections | `authoring-conventions.md § KB Document Layout` | MUST | mechanical | `grep -c '^## ' <doc>`; if > 3, require a Contents heading | `Step 2` — one doc without an index is confined → `[MEDIUM]`; widespread → escaped → `[HIGH]` |
| `KB-03` | `## Change Log` is the **last** section — no content follows it | `authoring-conventions.md § KB Document Layout` | MUST | mechanical | List the `^## ` headings with `grep -n` and confirm the change log is the final entry | `[HIGH]` |
| `KB-04` | The core frontmatter fields are present: `objective:`, `summary:`, `sources:` | `authoring-conventions.md § Frontmatter Rules` | MUST | mechanical | `bash .claude/aid/scripts/kb/lint-frontmatter.sh --root <dir>` | `[HIGH]` |
| `KB-05` | The classification fields are present: `audience:`, `owner:`, `tags:` | `authoring-conventions.md § Frontmatter Rules`; `kb-authoring/principles.md § P10. Dual-audience authoring standard` | SHOULD | mechanical | `bash .claude/aid/scripts/kb/lint-frontmatter.sh --root <dir>` — the same lint as `KB-04`; these are the dual-audience classification fields | `[LOW]; escaped (>1 doc) → [MEDIUM]` |
| `KB-06` | `tags:` carries a concern ID mapping the document to a spine dimension | `authoring-conventions.md § Concern Model (Doc-Set Derivation)` | SHOULD | mechanical | Check `tags:` for a concern token. Orientation docs (`external-sources`, `README`) are exempt — they own no concern | `[LOW]; escaped (>1 doc) → [MEDIUM]` |
| `KB-07` | The body carries no diagram blocks — no Mermaid, no ER diagram, no ASCII art | `authoring-conventions.md § Dual-Audience Standard`; `kb-authoring/principles.md § P10. Dual-audience authoring standard` | SHOULD | mechanical | `grep -c` the document for a fenced `mermaid` or `erDiagram` opener. Diagrams degrade in plain-text reading, which is half the audience | `[LOW]; escaped (>1 doc) → [MEDIUM]` |
| `KB-08` | Prose is plain and concrete enough for a junior professional to follow | `authoring-conventions.md § Dual-Audience Standard` | SHOULD | judgment | Name each jargon-dense paragraph that offers no plain-language alternative | `[LOW]; escaped (>1 doc) → [MEDIUM]` |
| `KB-09` | The document answers exactly **one** concern question, without material from an orthogonal concern | `authoring-conventions.md § Concern Model (Doc-Set Derivation)` | SHOULD | judgment | Name any section whose subject is another concern doc's declared question | `[LOW]; escaped (>1 doc) → [MEDIUM]` |

**`KB-03` is stricter than it looks.** A change log that is not last means content was appended after
it, which is how a change log stops describing the document it sits in.

---

## Insufficiency rules (the act-back taxonomy)

The panel's act-back limb asks a different question from the rest: *could an agent actually act on this
KB?* Its findings are about what the KB **failed to supply**, so the artifact may be internally perfect
and still fail these.

The authority remains [`kb-authoring/review-rubric.md`](../kb-authoring/review-rubric.md); this file
assigns the IDs and the severity anchors, re-derived against the canonical scale rather than the flat
`[HIGH]` the limb used to emit for every class.

| Rule | Check | Criterion | Modality | Mode | Evidence | Severity |
|---|---|---|---|---|---|---|
| `KB-20` | No two KB statements conflict, forcing the agent to choose | `kb-authoring/review-rubric.md` — the contradiction class | MUST | judgment | Quote both statements and name the choice the agent had to make | `Step 2` |
| `KB-21` | A correct plan is assemblable from the KB, and is right for this project | `kb-authoring/review-rubric.md` — the plan-correctness class | MUST | judgment | Name the step of the work-probe plan that has no KB anchor | `Step 2` |
| `KB-22` | Structural shape is stated, so the agent need not reach for the source | `kb-authoring/review-rubric.md` — the contract class | MUST | judgment | Name the contract the agent had to infer, and where it went to infer it | `[HIGH]` |
| `KB-23` | A rule that must hold is stated, rather than guessed | `kb-authoring/review-rubric.md` — the invariant class | MUST | judgment | Name the invariant the agent assumed | `[HIGH]` |
| `KB-24` | A non-obvious trap is warned about | `kb-authoring/review-rubric.md` — the gotcha class | MUST | judgment | Name the trap and what it would cost | `[HIGH]` |
| `KB-25` | The project's quality contract is conveyed | `kb-authoring/review-rubric.md` — the quality-bar class | MUST | judgment | Name the bar that was never stated. **If the bar WAS stated and the plan missed it, that is `KB-21`, not this** | `[HIGH]` |
| `KB-26` | A naming, path or style convention is stated, rather than assumed | `kb-authoring/review-rubric.md` — the convention class | **SHOULD** | judgment | Name the convention the agent had to invent | `[LOW]; escaped (>1 doc) → [MEDIUM]` |

**`KB-20` is the one that was missing.** Every other class describes *absence*, and absence at least
makes an agent guess while knowing it is guessing. A contradiction makes it choose **confidently** — and
different agents choose differently, so the failure is silent and non-reproducible.

**`KB-26` is the only genuine SHOULD here.** A project runs fine with inconsistent naming; it does not
run fine with unstated contracts. That single modality difference does most of the differentiating work,
which is why five of the seven still land at `[HIGH]`.

**Quality-bar is de-bundled.** It used to mean both *"the KB stated a bar and the plan missed it"* and
*"the KB never stated the bar"*. The first is a plan-correctness failure (`KB-21`); only the second is
`KB-25`.

---

## Ordering

Work the insufficiency rules in ID order and **stop at the first match** — the same first-match-wins
discipline as the universal taxonomy, so two reviewers classify the same gap identically and no
arbitration is needed.

## See also

- [`narrative.md`](narrative.md) — the family rules, which apply in full
- [`kb-authoring/review-rubric.md`](../kb-authoring/review-rubric.md) — the per-check authority
- [`INDEX.md`](INDEX.md) — routing and the universal tier

## Change Log

| Date | Change |
|---|---|
| 2026-07-29 | Created. Assigns the KB class its first rule IDs, relocates the authoring-standard checks out of `aid-discover`'s REVIEW state, and re-derives the act-back taxonomy against the canonical severity scale. |
