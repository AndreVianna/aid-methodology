# delivery-003 — deferred [HIGH] log

> Per-task quick-checks defer [HIGH] findings here; the delivery gate aggregates them.
> [CRITICAL] findings are fixed on-spot. Schema: schemas.md §12.

| # | Task | Severity | Description | Source (file:line) | Status |
|---|------|----------|-------------|--------------------|--------|
| 1 | 024 | HIGH | Never-funnel guard was comment-aware (2 comments held the literal "funnel" token, so a bare `grep funnel` returned non-zero) — fragile for a structural C1 invariant. No funnel invocation existed. | bin/aid:530,572 | Fixed-on-spot (comments rephrased; ZERO funnel tokens; bare grep proves never-public) |
