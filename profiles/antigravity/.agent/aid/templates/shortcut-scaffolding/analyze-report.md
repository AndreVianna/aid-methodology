# Shortcut Scaffolding: analyze / report

Per-family scaffolding reference for the **`report`** verb (bare `aid-report` only)
and the **`show-dashboard`** verb (bare `aid-show-dashboard` only -- the whole name is
the verb; no artifact suffix; feature-011, work-001-lite-aid-skills). Consulted by
the shared engine
(`.agent/aid/templates/shortcut-engine.md § Family Scaffolding Consult`) at
CAPTURE, SPEC, and DETAIL for every `{verb, artifact}` whose `verb` field resolves to
`report` or `show-dashboard`. Neither row carries an alias (feature-011 SPEC "Catalog
rows owned" -- 2 canonical, no aliases). Free-form prose, like any other `state-*.md`
reference doc -- the dispatched `aid-architect` reads this for judgment; it is not
machine-parsed.

Grounded in exploratory data analysis / product-metrics analysis (`aid-report`) and
building a durable BI view (`aid-show-dashboard`). The engine infers the
data-access/BI stack from the KB, so those are never capture slots.

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

## `aid-show-dashboard` -- CAPTURE

Bare verb (the whole name `show-dashboard` is the verb; no artifact suffix):

| Slot | Notes |
|---|---|
| Data source | where the dashboard's data comes from |
| Metrics/dimensions | what the dashboard shows |
| Visualization type | chart/table/view shape |
| Refresh cadence | how often the view refreshes |
| Publish target | where/how the dashboard is published |

**Escalation.** Same rule: escalate only when the data source or the
metrics/dimensions cannot be made concrete from `{description}` + KB context.

## `aid-show-dashboard` -- SPEC

Activates `### Telemetry & Tracking` + `### UI Specs` on top of the mandatory three
-- the dashboard's data/metric wiring is `### Telemetry & Tracking`; its
visualization/layout is `### UI Specs`. `### Data Model` reads "no schema changes"
(a dashboard reads and visualizes existing data; it does not model new schema).

## `aid-show-dashboard` -- DETAIL

| Task | Type | Notes |
|---|---|---|
| `task-001` | IMPLEMENT | build the view: source -> viz -> publish/refresh |
| `task-002` (optional) | TEST | validate data accuracy + refresh; depends on `task-001` |

## Ownership boundary

**Report/dashboard belong wholly to G11**, distinguished from neighbors by intent:
`aid-report` = **derive insight** from data (RESEARCH); `aid-document` = **communicate
already-known** information (a status/progress report is G8's bare `aid-document`;
an analytical report is here). Building the **data pipeline** that feeds a
report/dashboard is `aid-create-data-pipeline` (G4); adding **data-quality checks**
on the source is `aid-test-data-quality` (G7); a controlled **experiment/A-B test**
(design + run) is `aid-experiment` (G7) -- `aid-report` analyzes results, it does not
design the trial.

## See also

- `.agent/aid/templates/shortcut-engine.md § Family Scaffolding Consult` -- how
  this file is looked up and what happens when it is absent
- `.agent/aid/templates/shortcut-scaffolding/document.md § Ownership boundary` --
  where a status/progress report routes instead
- `.agent/aid/templates/shortcut-scaffolding/test-experiment.md § aid-experiment`
  -- where a controlled experiment/A-B test design routes instead
- `features/feature-011-analyze-and-report-family/SPEC.md`
  (work-001-lite-aid-skills) -- the settled design this reference implements
- `.agent/skills/aid-execute/references/task-type-rules.md ## RESEARCH /
  ## IMPLEMENT` -- the per-type execution rules this breakdown maps onto
- `.aid/knowledge/artifact-schemas.md § Task SPEC.md` -- the one-type-per-task
  contract
