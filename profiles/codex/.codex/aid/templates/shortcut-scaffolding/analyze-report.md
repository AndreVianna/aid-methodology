# Shortcut Scaffolding: analyze / report

Per-family scaffolding reference for the **`report`** verb (bare `aid-report` only),
the **`review`** verb (bare `aid-review` only), and the **`research`** verb (bare
`aid-research` only; a v2.1.0 coverage-gap follow-on to work-001-lite-aid-skills).
Consulted by the shared engine
(`.codex/aid/templates/shortcut-engine.md § Family Scaffolding Consult`) at
CAPTURE, SPEC, and DETAIL for every `{verb, artifact}` whose `verb` field resolves to
`report`, `review`, or `research`. None of these rows carry an artifact suffix or
alias rows. Free-form prose, like any other `state-*.md` reference doc -- the
dispatched `aid-architect` reads this for judgment; it is not machine-parsed.

Grounded in exploratory data analysis / product-metrics analysis (`aid-report`).
The engine infers the data-access/BI stack from the KB, so those are never capture
slots.

## `aid-report` -- CAPTURE

Bare verb, no artifact parameter:

| Slot | Notes |
|---|---|
| Question / hypothesis | the specific question the analysis answers |
| Data source | where the data comes from |
| Metric(s) | the metric(s) under analysis |
| Audience | who the finding is for |
| Decision it informs | the decision the insight feeds |

**Escalation.** Same rule as the generic engine: escalate to the one combined
CAPTURE question only when the question/hypothesis or the metric(s) cannot be made
concrete and testable from `{description}` + KB context.

## `aid-report` -- SPEC

Base sections only -- the mandatory three (`### Data Model`, `### Feature Flow`,
`### Layers & Components`) apply with no conditional section; `### Data Model` reads
"no schema changes" (the report reads existing data, it does not model new
persistence).

## `aid-report` -- DETAIL

`task-type-rules.md ## RESEARCH` ("compare >= 2 alternatives ... end with a
recommendation") maps directly onto EDA's requirement for multiple interpretations of
the same finding:

| Task | Type | Notes |
|---|---|---|
| `task-001` | RESEARCH | EDA + metrics; at least 2 interpretations of the finding; ends with a recommendation |
| `task-002` (optional) | DOCUMENT | write up the finding for `{audience}`; depends on `task-001` |

## `aid-review` -- CAPTURE

Bare verb, no artifact parameter (v2.1.0 coverage-gap follow-on):

| Slot | Notes |
|---|---|
| Target | the artifact under review -- code, a change/diff, or a design |
| Review criteria / rubric | what "good" looks like for this review -- coding standards, a SPEC's acceptance criteria, a security checklist, an architectural principle, etc. |
| Depth | how thorough -- a quick pass vs a line-by-line/exhaustive audit |

**Escalation.** Same rule as the generic engine: escalate to the one combined
CAPTURE question only when the target or the review criteria/rubric cannot be made
concrete and testable from `{description}` + KB context.

## `aid-review` -- SPEC

Base sections only -- the mandatory three (`### Data Model`, `### Feature Flow`,
`### Layers & Components`) apply with no conditional section; `### Data Model` reads
"no schema changes" (a review reads and assesses an existing artifact, it does not
model new persistence).

## `aid-review` -- DETAIL

Same `task-type-rules.md ## RESEARCH` mapping as `aid-report`:

| Task | Type | Notes |
|---|---|---|
| `task-001` | RESEARCH | assess `{target}` against the captured criteria/rubric; at least 2 considerations (e.g. strengths vs. risks, or 2 competing readings of an ambiguous criterion); ends with findings + a recommendation. Emits the reviewer-ledger per the global review-output schema (`.codex/aid/templates/reviewer-ledger-schema.md` -- CLAUDE.md § Review output format), NOT prose findings, so the task's own output is directly consumable by any downstream FIX loop. |
| `task-002` (optional) | DOCUMENT | write up the findings for a stakeholder audience; depends on `task-001` |

## `aid-research` -- CAPTURE

Bare verb, no artifact parameter (v2.1.0 coverage-gap follow-on):

| Slot | Notes |
|---|---|
| Question / decision | the open technical question or decision this research resolves |
| Options under consideration | the alternatives already known or worth surfacing (may be empty -- the task itself may need to enumerate them) |
| Decision criteria | what makes one option win -- cost, risk, performance, maintainability, time-to-ship, etc. |

**Escalation.** Same rule: escalate only when the question/decision or the decision
criteria cannot be made concrete and testable from `{description}` + KB context.

## `aid-research` -- SPEC

Base sections only -- the mandatory three (`### Data Model`, `### Feature Flow`,
`### Layers & Components`) apply with no conditional section; `### Data Model` reads
"no schema changes" (research investigates a question, it does not model new
persistence).

## `aid-research` -- DETAIL

| Task | Type | Notes |
|---|---|---|
| `task-001` | RESEARCH | compare >= 2 alternatives against `{decision criteria}` (feasibility spike or options analysis, per `task-type-rules.md ## RESEARCH`); ends with a recommendation |
| `task-002` (optional) | DOCUMENT | write up the recommendation (e.g. an ADR via `aid-document-decision`-shaped content); depends on `task-001` |

## Ownership boundary

**Report/dashboard belong wholly to G11**, distinguished from neighbors by intent:
`aid-report` = **derive insight** from data (RESEARCH); `aid-document` = **communicate
already-known** information (a status/progress report is G8's bare `aid-document`;
an analytical report is here). Building the **data pipeline** that feeds a
report/dashboard is `aid-create-data-pipeline` (G4); adding **data-quality checks**
on the source is `aid-test-data-quality` (G7); a controlled **experiment/A-B test**
(design + run) is `aid-experiment` (G7) -- `aid-report` analyzes results, it does not
design the trial.

**`aid-review`/`aid-research` also belong wholly to G11** (v2.1.0 coverage-gap
follow-on), distinguished from their own neighbors: `aid-review` = **assess an
existing artifact** against criteria (RESEARCH, ends in findings + a
recommendation); `aid-research` = **investigate an open question** before a
decision is made (RESEARCH, ends in a recommendation). **Correcting a defect**
found during a review is `aid-fix` (G6), not `aid-review` -- a review's own task
only produces findings + a recommendation, it never fixes the target in place.
**Removing, deprecating, or migrating** an artifact once a review/research
recommends it is `aid-remove`/`aid-deprecate`/`aid-migrate` (G5,
`shortcut-scaffolding/change-refactor.md`), a separate follow-on shortcut, not a
continuation of the same `aid-review`/`aid-research` work. Full-path, open-ended
project discovery (G1, out of scope for shortcuts entirely) stays with
`aid-discover`/`aid-describe`/`aid-define`/`aid-specify` -- `aid-research` is a
single, already-scoped question a shortcut can answer in one flattened Lite work,
not a project-wide discovery pass.

## See also

- `.codex/aid/templates/shortcut-engine.md § Family Scaffolding Consult` -- how
  this file is looked up and what happens when it is absent
- `.codex/aid/templates/shortcut-scaffolding/document.md § Ownership boundary` --
  where a status/progress report routes instead
- `.codex/aid/templates/shortcut-scaffolding/test-experiment.md § aid-experiment`
  -- where a controlled experiment/A-B test design routes instead
- `.codex/aid/templates/shortcut-scaffolding/change-refactor.md § aid-remove /
  § aid-deprecate / § aid-migrate` -- where acting on a review/research
  recommendation routes instead
- `.codex/aid/templates/reviewer-ledger-schema.md` -- the ledger schema
  `aid-review`'s `task-001` emits
- `features/feature-011-analyze-and-report-family/SPEC.md`
  (work-001-lite-aid-skills) -- the settled design this reference implements
- `.codex/skills/aid-execute/references/task-type-rules.md ## RESEARCH /
  ## IMPLEMENT` -- the per-type execution rules this breakdown maps onto
- `.aid/knowledge/artifact-schemas.md § Task DETAIL.md` -- the one-type-per-task
  contract
