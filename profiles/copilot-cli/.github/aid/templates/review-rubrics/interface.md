# Review Rubric — Interface family

**Members:** `API`, `CLI`, `MESSAGING`, `DATA MODEL`, `SCHEMA`
**Kind:** A (adversarial content grade)
**Universal tier:** [`INDEX.md`](INDEX.md) — the defect taxonomy, the two authority ladders,
severity derivation and evidence admissibility all apply and are not restated here.

Severity is looked up from
[`grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale).

---

## What this family is for

An interface artifact is a **promise to someone you cannot see**. Its defining property is that
breaking it breaks consumers you did not review — which is why blast radius in this family is
usually *escaped* by default, and why `Step 2` anchors here often resolve to `[HIGH]` or
`[CRITICAL]` rather than `[MEDIUM]`.

**Portability note.** Each `Criterion` cites a document and section by name. When the declaring
section is absent from a given installation the rule **cannot fire**, and the concern is a criteria
gap rather than a finding.

---

## Rules

| Rule | Check | Criterion | Modality | Mode | Evidence | Severity |
|---|---|---|---|---|---|---|
| `INT-01` | The declared contract is honoured — signature, shape and enum values match what is published | `pipeline-contracts.md § Typed Artifact Contracts`, or the project's own contract document | MUST | judgment | Name each element of the declared contract and the implementation's counterpart. A mismatch in name, shape, or enum value is the finding | `Step 2` — a published contract has consumers, so the radius is normally escaped |
| `INT-02` | A change to an existing contract is backward compatible, or the break is declared | `integration-map.md § Contracts` | MUST | judgment | Name every existing consumer of the changed element. If a consumer would break and no migration is declared, that is the finding | `Step 2` |
| `INT-03` | A closed enum is not extended or narrowed without updating every reader of it | `INDEX.md` universal taxonomy class 1 (Contract violation) | MUST | mechanical | `grep` for each reader of the enum and check it handles the new set | `Step 2` |
| `INT-04` | Integration conventions are followed | `integration-map.md § Conventions` | SHOULD | judgment | Compare the integration's shape against the declared convention for its kind | `[LOW]; escaped (>1 integration) → [MEDIUM]` |
| `INT-05` | The artifact's own schema is satisfied where one is declared | `artifact-schemas.md` — the section governing this artifact type | MUST | mechanical | Validate against the declared schema | `[HIGH]` |

---

## What this family does not yet cover

Versioning policy, deprecation windows and compatibility guarantees are **not** rules here, because
this installation's KB does not declare them. That is deliberate: under `INDEX.md`'s admission rule,
a concern with no declaring criterion is a **criteria gap**, not a finding at a softened severity.

When a project declares its versioning policy, those rules belong here and their `Criterion` cites
that declaration. Until then, a reviewer who believes a versioning concern matters should **raise the
gap**, not invent the rule.

---

## See also

- [`INDEX.md`](INDEX.md) — universal tier and routing
- [`grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale) — severity derivation

## Change Log

| Date | Change |
|---|---|
| 2026-07-28 | Created. Five grounded rules; versioning and deprecation explicitly left as criteria gaps rather than invented. |
