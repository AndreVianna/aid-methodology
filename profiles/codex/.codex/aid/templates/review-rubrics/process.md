# Review Rubric — Process family

**Members:** `TICKET`, `RELEASE`, `SPIKE`, `PROTOTYPE`
**Kind:** A (adversarial content grade)
**Universal tier:** [`INDEX.md`](INDEX.md) — the defect taxonomy, the two authority ladders,
severity derivation and evidence admissibility all apply and are not restated here.

Severity is looked up from
[`grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale).

---

## What this family is for

A process artifact is **about the work rather than the product**. Two of its members — `SPIKE` and
`PROTOTYPE` — are explicitly disposable, which changes what a defect even means: holding throwaway
code to production conventions is a category error, and *failing to declare* that it is throwaway is
the real defect.

So this family's rules are mostly about **stated boundaries**: what is in scope, when it is finished,
and whether it is meant to survive.

**Portability note.** Each `Criterion` cites a document and section by name. When the declaring
section is absent the rule **cannot fire**, and the concern is a criteria gap rather than a finding.

---

## Rules

| Rule | Check | Criterion | Modality | Mode | Evidence | Severity |
|---|---|---|---|---|---|---|
| `PRO-01` | Scope is stated — what is included, and what is deliberately excluded | `pipeline-contracts.md § Phase Input/Output Contracts` | MUST | judgment | Name the in-scope set and the out-of-scope set. An absent out-of-scope statement is the finding | `Step 2` |
| `PRO-02` | Exit criteria are stated and decidable — a reader can tell when this is finished | `pipeline-contracts.md § Phase Input/Output Contracts` | MUST | judgment | Name the observation that would settle "done". If none exists, that is the finding | `Step 2` |
| `PRO-03` | Disposability is declared — a spike or prototype says plainly that it is not production code | `pipeline-contracts.md § Typed Artifact Contracts` | MUST | mechanical | `grep` the artifact for its disposability statement | `[HIGH]` — an undeclared prototype gets consumed as if it were product, and by then the radius has escaped |
| `PRO-04` | A release artifact's version carriers agree | `release-tracking.md` — the section declaring the version carriers | MUST | mechanical | `bash .codex/aid/scripts/release/check-version-sync.sh --expect <version>` | `Step 2` |
| `PRO-05` | An external tracker reference resolves, where the artifact carries one | `integration-map.md § Connectors` | SHOULD | mechanical | Resolve each `ticket_ref` against its connector | `[LOW]; escaped (>1 artifact) → [MEDIUM]` |

---

## The rule this family exists for

**`PRO-03` is the one that earns the family its place in the catalog.** Every other rule here has a
close analogue in the Definition family. This one does not, and its absence is a real failure mode:
throwaway code that nobody labelled as throwaway gets read as an example, copied, and depended on.
By the time that is noticed the blast radius has escaped and the correction is non-local — which is
why the anchor is `[HIGH]` and not `[MEDIUM]`.

The inverse error is also worth naming: **applying `executable.md`'s convention rules to a declared
prototype is not a finding.** A prototype that says it is a prototype has satisfied its contract.

---

## What this family does not yet cover

Ticket-workflow conventions (state transitions, required fields, assignment rules) have no declaring
document in this installation. They belong here when a project declares them; until then they are
criteria gaps rather than findings.

---

## See also

- [`INDEX.md`](INDEX.md) — universal tier and routing
- [`grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale) — severity derivation

## Change Log

| Date | Change |
|---|---|
| 2026-07-28 | Created. Five grounded rules; ticket-workflow conventions left as criteria gaps rather than invented. |
