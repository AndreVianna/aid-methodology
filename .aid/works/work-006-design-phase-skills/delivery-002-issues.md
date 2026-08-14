# Delivery Issue Log -- delivery-002

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded -- grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-029,030,031 | [HIGH] | 14 grid design rows sit after delivery-001's planning rows (roadmap/mvp/backlog) rather than immediately after the aid-design row (SPEC feature-005 3b literal); adjudicated presentational -- task-029 DETAIL line 73 states row order has no oracle and requires only that the 14 stay contiguous ahead of task-033's foundation rows (both satisfied), the checkable AC (A less-than row less-than G8) is satisfied, and groups.mjs family order is fixed by the aid-design row (all are verb design) so it is unaffected; reordering would displace feature-003's committed rows. Gate to confirm. | Deferred |
