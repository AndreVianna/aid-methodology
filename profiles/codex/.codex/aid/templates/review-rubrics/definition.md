# Review Rubric — Definition family

**Members:** `REQ`, `SPEC`, `PLAN`/`BLUEPRINT`, `TASK`
**Kind:** A (adversarial content grade)
**Universal tier:** [`INDEX.md`](INDEX.md) — the defect taxonomy, the two authority ladders,
severity derivation and evidence admissibility all apply and are not restated here.

Severity is looked up from
[`grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale).

---

## What this family is for

A definition artifact says **what must be true**, for someone else to build against. Its defects are
almost all of one shape: a statement that cannot be tested, cannot be traced, or contradicts the
thing it derives from.

**Portability note.** Each `Criterion` cites a KB spine document and a section by name. Those
document names are standard across AID installations, but a given adopter's KB may not carry the
cited *section*. When the declaring section is absent the rule **cannot fire**, and the concern is a
criteria gap rather than a finding — the `INDEX.md` graduated-fallback contract, applied to criteria
as well as to classes.

---

## Rules

| Rule | Check | Criterion | Modality | Mode | Evidence | Severity |
|---|---|---|---|---|---|---|
| `DEF-01` | Every requirement and **feature** acceptance criterion carries an explicit modality (`MUST` / `SHOULD` / `COULD`) — task `DETAIL.md` criteria are out of scope | `pipeline-contracts.md § The Grading Gate Contract`; `artifact-schemas.md § Task DETAIL.md` for the exclusion | MUST | mechanical | `bash .codex/aid/scripts/kb/lint-modality.sh --root .aid/works/{work}` — its discovery set is `REQUIREMENTS.md` and `SPEC.md`, which is the scope of this rule | `Step 2` |
| `DEF-02` | Every acceptance criterion is decidable — a reader can answer *pass* or *fail* without asking the author | `pipeline-contracts.md § Phase Input/Output Contracts` | MUST | judgment | Read each AC and name the observation that would settle it. An AC with no such observation fails | `Step 2` |
| `DEF-03` | Every requirement traces upstream to a stated need, and every downstream section traces to a requirement | `pipeline-contracts.md § Phase Input/Output Contracts` | MUST | judgment | For each requirement name its upstream source; for each spec section name the requirement it serves | `Step 2` |
| `DEF-04` | The artifact does not contradict the artifact it derives from, nor itself | `INDEX.md` universal taxonomy class 2 (Contradiction), and the intent ladder in `INDEX.md` | MUST | judgment | A load-bearing invariant stated in two places must agree. Quote both statements | `Step 2` |
| `DEF-05` | Every mandated section of the governing schema is present | `artifact-schemas.md § REQUIREMENTS.md`, `§ Feature SPEC.md`, `§ Delivery BLUEPRINT.md`, `§ Task DETAIL.md` — whichever governs this artifact | MUST | mechanical | `grep -c '^## ' <artifact>`, then `diff` that heading list against the mandated set in the governing schema section | `[HIGH]` |
| `DEF-06` | Every cited path, anchor and identifier resolves | `authoring-conventions.md § Citation Rule (Durable Anchors)` | MUST | mechanical | `bash .codex/aid/scripts/kb/kb-citation-lint.sh --root <artifact dir> --profile resolvable --depth 4` | `Step 2` — one bad cite is confined → `[MEDIUM]`; widespread → escaped → `[HIGH]` |
| `DEF-07` | The artifact carries no drift-prone content — no value that will silently go stale | `authoring-conventions.md § Drift-Prone Content is Banned` | MUST | judgment | Name each value that would become wrong without anyone editing this file. Each is a finding | `Step 2` |
| `DEF-08` | Every gate criterion of the governing `BLUEPRINT.md` is discharged by at least one task in that delivery | `INDEX.md` universal taxonomy class 3 (Unmet criterion), applied to the delivery's own gate criteria | MUST | judgment | List the BLUEPRINT's `## Gate Criteria` and its `## Scope` obligations, then name the task that carries each. A criterion no task carries is the finding; quote the criterion and state that no task's Scope or Acceptance Criteria reaches it | `Step 2` — one undischarged criterion is confined → `[MEDIUM]`; a delivery whose task set misses several → escaped → `[HIGH]` |
| `DEF-09` | Every factual claim the artifact makes about the repository holds on disk | `authoring-conventions.md § Citation Rule (Durable Anchors)` — the Definition-family analogue of `narrative.md`'s `NAR-01` | MUST | judgment | For each claim about what exists, what a site covers, or what a skill does, run the command that would falsify it and quote the output. A claim whose identifiers all resolve can still be false — resolution is `DEF-06`, truth is this rule | `Step 2` — one false claim is confined → `[MEDIUM]`; a task set reasoning from it → escaped → `[HIGH]` |

---

## Notes for reviewers of this family

**`DEF-01` is the rule every other severity depends on.** Step 1 of severity derivation reads the
violated rule's modality. An untagged requirement makes Step 1 impossible, so this is not a style
preference — it is what makes the rest of the artifact gradeable at all.

**`DEF-02` and `DEF-07` catch the most in practice.** An AC that cannot be decided, and a value that
will go stale unnoticed, are both statements dressed as criteria. Neither is caught by reading for
correctness; both are caught by asking *how would I check this, and when will it stop being true?*

**`DEF-06` is mechanical and cheap — run it first.** A citation sweep costs one command and
routinely finds more than a careful read does.

**Not in this rule set:** whether a stated count carries the command that produces it. That rule has
its own declaring criterion and is added separately; it is deliberately absent here rather than
forgotten.

---

## See also

- [`INDEX.md`](INDEX.md) — universal tier and routing
- [`grading-rubric.md#severity-scale`](../grading-rubric.md#severity-scale) — severity derivation

## Change Log

| Date | Change |
|---|---|
| 2026-07-28 | Created. Seven rules, every `Criterion` verified against a heading that exists in the KB spine. |
| 2026-08-08 | `DEF-01` scoped to requirements and **feature** criteria; task `DETAIL.md` acceptance criteria are explicitly out of it. Three declared sources had disagreed — `DEF-01`'s own Evidence read AC *tables*, `artifact-schemas.md § Task DETAIL.md` mandates plain checkboxes, and `lint-modality.sh --root` discovers only `REQUIREMENTS.md`/`SPEC.md` — so the rule could be neither applied nor dismissed against a task file. Human decision (criteria gap `def01/modality-scope-task-detail-acs`): task criteria stay plain checkboxes, because a task criterion inherits its weight from the requirement it serves and tagging it again is a second place for that value to drift. |
| 2026-08-08 | `DEF-08` added: a delivery's gate criteria must each be discharged by at least one task. The `/aid-detail` reviewer brief already demanded this check while no rule in this family could express it, so a criterion no task carried was unreportable — raised as criteria gap `definition/task-set-discharges-upstream-obligation` and resolved by human decision. Cites `INDEX.md` universal taxonomy class 3 (Unmet criterion), the same way `DEF-04` cites class 2, so no criterion is invented. |
| 2026-08-08 | `DEF-09` added: a work artifact's factual claims about the repository must hold on disk. Raised as criteria gap `definition/work-artifact-claim-contradicted-by-disk` and resolved by human decision. The hole was structural, not an oversight: `INDEX.md`'s per-class ladder gives `TASK` an intent authority of SPEC/BLUEPRINT and a manner authority of the KB, so **the repository is on neither** — a task asserting something false about the codebase was unreachable by `DEF-04` (which needs a higher-authority *artifact*), by `DEF-06` (which only asks whether identifiers resolve) and by `DEF-07` (whose declaring section is scoped to KB primary docs). The narrative family already carried this rule as `NAR-01`; Definition simply lacked its analogue, and cites the same section. |
