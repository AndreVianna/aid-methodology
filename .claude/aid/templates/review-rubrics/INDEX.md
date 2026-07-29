# Review Rubric Catalog — INDEX

**This is the routing table and the universal tier of AID's review criteria.** A reviewer starts
here, resolves the artifact to exactly one rule set, and applies that rule set plus everything
declared on this page.

Severity is never defined here. It is defined once, at
[`.claude/aid/templates/grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale).

---

## Three tiers

| Tier | Declared in | Contains |
|---|---|---|
| **Universal** | this file | the defect taxonomy, the two authority ladders, severity derivation, evidence admissibility |
| **Family** | `review-rubrics/<family>.md` | criteria shared by every class in the family |
| **Class** | `review-rubrics/<class>.md` | criteria a class has that its family does not cover |

A class file exists **only** where the class has criteria its family does not already cover. Absence
of a class file is normal, not a gap.

---

## The rule row — seven cells

```
| Rule | Check | Criterion | Modality | Mode | Evidence | Severity |
```

| Cell | Contract |
|---|---|
| **Rule** | The rule ID. This value goes in the ledger's `Rule` column. Format below |
| **Check** | One sentence, stated **positively** — the assertion that must hold. A finding is always "this Check is false here" |
| **Criterion** | A durable citation to the KB doc or spec doc that *declares* the rule. **No Criterion, no row** — this is what stops the catalog becoming a third source of truth |
| **Modality** | `MUST` / `SHOULD` / `COULD`, copied from the criterion, **never invented** |
| **Mode** | `mechanical` or `judgment`. Mechanical rows carry a runnable command in Evidence; judgment rows name the surface read and what is read off it |
| **Evidence** | Per Mode |
| **Severity** | One of exactly two forms — never prose. Below |

### The severity anchor has exactly two legal forms

Modality is knowable when a rule is authored. Blast radius and reversibility are **instance** facts.
So a rule cannot always pin one token, and pretending otherwise would contradict the canonical scale
on the first row.

- **Fixed** — a single bracketed token, when the violation always has the same radius/reversibility
  shape. May carry a stated escape threshold. The only legal escape form puts the bracketed token
  first: `[LOW]; escaped (>1 doc) → [MEDIUM]`. Never a modality prefix.
- **`Step 2`** — modality is MUST; the two axes are read off the instance per the canonical scale.

`Step 2` is **not** a judgment escape hatch. Both axes are evidence-bearing — *name the dependent,
or the radius is confined* — so the reviewer evaluates two checkable predicates.

### A rule row's cells must contain no pipe — not even an escaped one

The ledger escapes a literal `|` as `\|`, and that is safe there because `grade.sh` reads `cols[3]` and
`cols[4]`, which precede any free text. **A rule row is different: `Severity` is the LAST cell**, so a
pipe anywhere earlier shifts it, and escaping does not help a *positional* parse.

So an `Evidence` command containing a pipe must be **described rather than pasted** — *"list the
headings with `grep -n` and confirm the change log is last"* rather than a piped one-liner. Found by the
catalog's own integrity suite, on rows added after the schema was written.

**There is no force-floor form.** A catalog feature that looks mechanical but is honoured only by
convention is exactly what this catalog exists to remove.

**Density is not a separate mechanism.** "MINOR per occurrence, MEDIUM if widespread" dissolves under
the canonical scale: such checks are SHOULD-modality, so Step 1 already gives `[LOW]` escaping to
`[MEDIUM]`. Where a concrete count is needed it becomes an escape threshold inside the Severity cell,
in scale vocabulary.

---

## Rule ID format

**`<CLASS>-<NN>`** — an uppercase class token, a hyphen, a two-digit sequence unique within the
class. Never reused after retirement.

```
^[A-Z]{2,12}-[0-9]{2}$
```

Single hyphen, no spaces, no pipes — greppable, sortable, and safe inside a markdown cell. Two digits
cap a class at 99 rules; needing more is a signal to split the class.

**The class prefix *is* the source tag.** `CODE-*`, `TASK-*`, `SPEC-*`, `KB-*`. The tag stops being a
second thing the reviewer asserts, so it can no longer contradict the rule.

`[ARCHITECTURE]` **is retired.** It was never an artifact class — it was a *criterion source* wearing
an artifact-tag costume. An architecture finding is always a finding about code or a spec whose
criterion happens to be an architecture mandate, and the `Criterion` cell now records that.

Two further contracts:

- **Non-finding rows carry `--`** in the ledger's `Rule` column. Coverage rows have no rule.
- **One rule per row.** A defect violating two rules produces two rows. No comma-separated lists —
  the cell stays single-valued, greppable, and countable.

---

## The universal defect taxonomy

Inherited by every kind-A rule set. **Ordered by severity, first match wins**, so two reviewers
classify the same defect identically and no arbitration is needed.

| # | Class | The artifact… | Modality | Anchor |
|---|---|---|---|---|
| 1 | **Contract violation** | breaks a declared interface, signature, schema, or closed enum | MUST | `Step 2` |
| 2 | **Contradiction** | conflicts with a higher-authority source, or with itself | MUST | `Step 2` |
| 3 | **Unmet criterion** | fails a requirement or AC it is bound by | *inherits the criterion's* | MUST → `Step 2`; SHOULD → `[LOW]`; COULD → `[MINOR]` |
| 4 | **Missing content** | omits a mandated section, field, or element | MUST | `[HIGH]` |
| 5 | **Stale reference** | cites a path, anchor, or identifier that no longer resolves | MUST | `Step 2` — one bad cite is confined → `[MEDIUM]`; widespread → escaped → `[HIGH]` |
| 6 | **Convention deviation** | differs from a declared naming, structure, or format convention | SHOULD | `[LOW]; escaped (>1 artifact) → [MEDIUM]` |

**Unmet criterion** borrows the modality of whatever it violated — tag the ACs and this class grades
itself. **Stale reference** needs no density rule: one dead link affects only a reader of that
artifact (confined); dead links throughout mean consumers rely on them (escaped).

### Two outcomes that are not findings

- **Cannot measure** — a claim no available evidence can confirm or deny → **ask the user**. Never
  record a softened finding.
- **No criterion** — nothing in either ladder speaks to the concern → **criteria gap**.

**Executor guidance is inexpressible here, by construction.** "Write clean code", "YAGNI" and the
like have no KB criterion declaring them review rules, so the admission rule — no `Criterion`, no
row — keeps them out. Architecture-level mandates (clean architecture, hexagonal, DDD, BDD,
TDD-required) become ordinary rows whose `Criterion` cites the KB document declaring them. Where the
KB is silent, no row exists, so the concern is a gap rather than a finding.

---

## The five review kinds

**AID already implements five kinds of review.** Every class declares which it takes. **Only kind A
needs rule rows.**

| Kind | What it does |
|---|---|
| **A** | Adversarial content grade — an agent grades content, findings carry severities, `grade.sh` computes the letter |
| **B** | Build-verify only — re-run the generator and diff; content grading skipped, the script is the authority |
| **C** | Spot-check snapshot — current-value fields only; history and ledger rows explicitly not graded |
| **D** | Mechanical gate — a script passes or fails; no agent, no rule rows |
| **E** | Machine score plus a mandatory human checklist |

---

## The two authority ladders

The sources of truth shift by phase, so every class declares both.

- **Intent** — *what must this artifact achieve?* Accumulates as the pipeline advances:
  user → REQUIREMENTS → SPEC → BLUEPRINT → DETAIL.
- **Manner** — *how must it be built?* The Knowledge Base. Constant, **except during Discover**,
  where the KB is the artifact being produced and therefore cannot judge itself.

**Conflict rules.** Manner outranks intent on *how*; intent outranks manner on *what*. A conflict
*between* ladders is never the reviewer's to resolve — surface both and escalate. Within a ladder the
higher rung wins: **artifact versus KB, the KB wins.** Two sources at equal rank (SPEC versus PLAN) —
surface both, pick neither.

### Per-class declarations

| Class | Kind | Intent authority | Manner authority |
|---|---|---|---|
| `KB` | A | User's confirmed statements, then external documents | AID's KB-authoring rubric |
| `REQ` | A | User's confirmed statements | KB |
| `SPEC` | A | REQUIREMENTS | KB |
| `PLAN` | A | SPEC, then REQUIREMENTS | KB |
| `TASK` | A | SPEC / BLUEPRINT | KB |
| `CODE` | A | Task DETAIL's ACs, then SPEC | KB |
| `TEST` | A | The ACs under test, then SPEC | KB (`test-landscape.md`) |
<!-- The DATA row cites `artifact-schemas.md`. feature-002's SPEC wrote `schemas.md`, which does
     not exist in the KB spine -- corrected at delivery-004 rather than propagated. -->

| `DATA` | A | Declared schema | KB (`artifact-schemas.md`) |
| `AID` | A | AID's own requirements | `authoring-conventions.md`, `EMISSION-MANIFEST.md` |
| `SUMMARY` | **A + E** | The KB it summarises | `knowledge-summary/grading-rubric.md`, re-derived as rules |
| `SETTINGS` | D | The user's stated configuration | The settings schema |
| `INDEX`, `METRICS`, `PROJECT-INDEX` | B | — | The generating script |
| `STATE` (all levels) | C | — | The state template's enums |

`SUMMARY` is the only class carrying **two** kinds. That is deliberate, and stated here so it does
not read as an error: its machine and human gates remain (kind E), and an adversarial content pass is
added (kind A). Both use the same rule set.

---

## Artifact families

The artifact set is **not exhaustive and is not meant to be.** An artifact matching no class is a
**criteria gap**, not a defect — so the catalog need not be complete to be correct, only honest about
its edges. Families are what let it grow without duplication.

| Family | Members | Shared criteria |
|---|---|---|
| **Definition** | REQ, SPEC, PLAN/BLUEPRINT, TASK | Traceability upstream, testable criteria, modality tagged, no implementation prose |
| **Executable** | CODE, TEST, CONFIG, INFRA, JOB, PIPELINE, MIGRATION | Build/lint/test green, convention compliance, contract conformance |
| **Interface** | API, CLI, MESSAGING, DATA MODEL, SCHEMA | Declared contract honoured, versioning, backward compatibility |
| **Presentation** | UI, THEME, DASHBOARD, DIAGRAM, SUMMARY | Design tokens, accessibility, responsive behaviour, state coverage |
| **Narrative** | KB, DOCUMENTATION, REPORT, RESEARCH, ADR | Claim-evidence discipline, durable citations, audience fit, single concern |
| **Process** | TICKET, RELEASE, SPIKE, PROTOTYPE | Scope stated, exit criteria defined, disposability declared |

### Graduated fallback

An artifact whose **family** is clear but whose **class** is unregistered is reviewed against the
**family's** declared rules, and the missing class rule set is recorded as a **non-blocking** gap.
Only when no family fits does it become a full criteria gap.

No invention occurs either way — family rules are declared rules, merely less specific.

**There is no catch-all rule set.** A `GEN` family-of-last-resort was considered and rejected: it
becomes the place reviewers reach when nothing fits, and invented criteria grow back inside it.

---

## Routing table

**Key: artifact selector × producing skill**, following the KB rubric's `kb-category × source`
precedent.

### How to resolve an artifact to a rule set

Work these three steps in order and **stop at the first that answers**. Every artifact resolves to
**exactly one** rule set — the table below does not list every class, and it is not meant to.

1. **Exact route.** Match the artifact against the routing table. A match gives the rule set
   directly. If the matched row declares a kind other than A, there are no rule rows to apply — the
   named script or checklist *is* the review.
2. **Family fallback.** No routing row? Find the artifact's class in the **Artifact families** table
   above and apply that **family's** rule set. Record the missing class rule set as a
   **non-blocking** gap. This is the ordinary path for a class the catalog has not yet specialised
   (`RESEARCH`, `ADR`, `API`, `CLI`, `TICKET`, `CONFIG` and the rest) — those are routed, not
   unrouted.
3. **Criteria gap.** No family fits either? **Stop and raise a criteria gap.** Do not reach for the
   nearest-looking rule set, and do not invent criteria.

A class appearing in both a routing row and a family is **not** ambiguous: step 1 wins, and the
family's rules still apply beneath the class file, per the three-tier model.

| Artifact selector | Producing skill | Class | Rule set |
|---|---|---|---|
| `.aid/knowledge/*.md` | `aid-discover`, `aid-update-kb` | `KB` | [`kb.md`](kb.md) — which assigns the IDs and cites `kb-authoring/review-rubric.md` as the per-check authority |
| `.aid/works/*/REQUIREMENTS.md` | `aid-describe`, `aid-define` | `REQ` | `definition.md` |
| `.aid/works/*/features/*/SPEC.md` | `aid-specify` | `SPEC` | `definition.md` |
| `.aid/works/*/PLAN.md`, `**/BLUEPRINT.md` | `aid-plan` | `PLAN` | `definition.md` |
| `**/tasks/*/DETAIL.md` | `aid-detail` | `TASK` | `definition.md` |
| product source files | `aid-execute` | `CODE` | `executable.md` |
| test files | `aid-execute`, `aid-test` | `TEST` | `executable.md` |
| `.aid/knowledge/kb.html` | `aid-summarize` | `SUMMARY` | `summary.md` |
| `canonical/**`, `profiles/**` | AID's own pipeline | `AID` | `aid.md` — reachable only where `canonical/EMISSION-MANIFEST.md` exists at repo root |
| `.aid/settings.yml` | `aid-config` | `SETTINGS` | kind D — mechanical gate, no rule rows |
| `.aid/knowledge/INDEX.md`, metrics, project index | generator scripts | `INDEX`/`METRICS`/`PROJECT-INDEX` | kind B — build-verify, no rule rows |
| any `STATE.md` | every skill | `STATE` | kind C — spot-check, no rule rows |

**The `AID` class is guarded by the presence of `canonical/EMISSION-MANIFEST.md` at repo root**,
which exists only in AID's own repository. The rules ship to every adopter but are **unreachable**
there.

**Shipped now:** the six families, plus class rule sets only where a declaring document already
exists. Everything else inherits its family and accumulates class rules as the project declares
them — the same improvement loop, applied to the catalog itself.

---

## See also

- [`.claude/aid/templates/grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale) —
  the single severity definition
- [`.claude/aid/templates/reviewer-ledger-schema.md`](../reviewer-ledger-schema.md) — the ledger
  the `Rule` column lives in
- [`.claude/aid/templates/kb-authoring/review-rubric.md`](../kb-authoring/review-rubric.md) — the
  `KB` class rule set, referenced in place

## Change Log

| Date | Change |
|---|---|
| 2026-07-28 | Created. Universal tier, rule-row schema, ID format, five review kinds, two authority ladders, six families, routing table. |
