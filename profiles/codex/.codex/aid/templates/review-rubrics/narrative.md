# Review Rubric — Narrative family

**Members:** `KB`, `DOCUMENTATION`, `REPORT`, `RESEARCH`, `ADR`
**Kind:** A (adversarial content grade)
**Universal tier:** [`INDEX.md`](INDEX.md) — the defect taxonomy, the two authority ladders,
severity derivation and evidence admissibility all apply and are not restated here.

Severity is looked up from
[`grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale).

> **The `KB` class has its own rule set**, kept where it already lives:
> [`kb-authoring/review-rubric.md`](../kb-authoring/review-rubric.md). It is referenced rather than
> moved — it has many inbound pointers and belongs to the `aid-discover` bundle. Use it for
> `.aid/knowledge/*.md`; use this file for the family's other members.

---

## What this family is for

A narrative artifact makes **claims**. Its defects are therefore mostly about the relationship
between a claim and its evidence: a claim with no support, support that no longer resolves, or a
claim that contradicts a higher authority.

**Portability note.** Each `Criterion` cites a KB spine document and a section by name. Document
names are standard across AID installations; a given adopter's KB may not carry the cited *section*.
When the declaring section is absent the rule **cannot fire**, and the concern is a criteria gap
rather than a finding.

---

## Rules

| Rule | Check | Criterion | Modality | Mode | Evidence | Severity |
|---|---|---|---|---|---|---|
| `NAR-01` | Every load-bearing claim is grounded — the reader can reach what makes it true | `authoring-conventions.md § Citation Rule (Durable Anchors)` | MUST | judgment | For each load-bearing claim, name its support. An ungrounded load-bearing claim is the finding | `Step 2` |
| `NAR-02` | Every citation uses a durable anchor, not a bare line number | `authoring-conventions.md § Citation Rule (Durable Anchors)` | MUST | mechanical | `bash .codex/aid/scripts/kb/kb-citation-lint.sh --root <dir>` | `Step 2` — one volatile cite is confined → `[MEDIUM]`; widespread → escaped → `[HIGH]` |
| `NAR-03` | Every cited path and anchor resolves | `authoring-conventions.md § Citation Rule (Durable Anchors)` | MUST | mechanical | `bash .codex/aid/scripts/kb/kb-citation-lint.sh --root <dir> --profile resolvable --depth 4` | `Step 2` — one dead cite is confined → `[MEDIUM]`; widespread → escaped → `[HIGH]` |
| `NAR-04` | The document carries no drift-prone content — no value that will silently go stale | `authoring-conventions.md § Drift-Prone Content is Banned` | MUST | judgment | Name each value that would become wrong without anyone editing this file | `Step 2` |
| `NAR-05` | The document does not contradict a higher-authority source, nor itself | `INDEX.md` universal taxonomy class 2 (Contradiction), and the manner ladder in `INDEX.md` | MUST | judgment | Quote both statements. Artifact versus KB, the KB wins; equal rank, surface both and pick neither | `Step 2` |
| `NAR-06` | The document serves both its audiences — a human reader and an agent consumer | `authoring-conventions.md § Dual-Audience Standard` | MUST | judgment | Name what an agent would need to act on this document and check it is present, not implied | `Step 2` |
| `NAR-07` | The document holds one concern; content belonging to another document is not duplicated here | `authoring-conventions.md § Concern Model (Doc-Set Derivation)` | SHOULD | judgment | Name any section whose subject is another document's declared concern | `[LOW]; escaped (>1 doc) → [MEDIUM]` |
| `NAR-08` | Layout follows the declared document structure | `authoring-conventions.md § KB Document Layout` | SHOULD | mechanical | Compare the heading sequence against the declared layout | `[LOW]; escaped (>1 doc) → [MEDIUM]` |
| `NAR-09` | Frontmatter is complete and valid | `authoring-conventions.md § Frontmatter Rules` | MUST | mechanical | `bash .codex/aid/scripts/kb/lint-frontmatter.sh --root <dir>` | `[HIGH]` |
| `NAR-10` | Resolved items leave no trace — no stale "pending" or "TBD" for something already settled | `authoring-conventions.md § Resolved Items Leave No Trace` | SHOULD | mechanical | `grep` for pending/TBD markers and check each against current state | `[LOW]; escaped (>1 doc) → [MEDIUM]` |
| `NAR-11` | Prose is preferred where prose suffices — no script standing in for an explanation | `authoring-conventions.md § Prose Over Scripts` | COULD | judgment | Name any code block that would read more clearly as a sentence | `[MINOR]` |

---

## Notes for reviewers of this family

**`NAR-02` and `NAR-03` are two different rules and both matter.** `NAR-02` asks whether the citation
*form* is durable; `NAR-03` asks whether it currently *resolves*. A durable anchor can still be dead,
and a bare line number can still be live. Run both commands.

**`NAR-01` is the family's core, and it is the one that resists mechanisation.** "Load-bearing" means
a reader would act differently if the claim were false. Grounding is not the same as citing — a
citation to a document that does not actually support the claim is a `NAR-01` finding even though
`NAR-03` passes.

**`NAR-04` catches the class of defect that ages worst.** A count, a version, a file total, a
"currently N of M" — each is correct on the day it is written and wrong later, with nothing to flag
it. Where the value is genuinely needed, it belongs beside the command that reproduces it.

---

## See also

- [`INDEX.md`](INDEX.md) — universal tier and routing
- [`kb-authoring/review-rubric.md`](../kb-authoring/review-rubric.md) — the `KB` class rule set
- [`grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale) — severity derivation

## Change Log

| Date | Change |
|---|---|
| 2026-07-28 | Created. Eleven rules, every `Criterion` verified against a heading that exists in the KB spine. |
