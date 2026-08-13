# Delivery Issue Log -- delivery-001

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded -- grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-002 | [HIGH] | review-rubric.md section Temp ledger format shows a stale ledger shape (# Severity Doc Line Tier Status Claim, lowercase status values) that contradicts the canonical 7-column shape and defeats grade.sh positional parse -- cols[4] lands on Doc so every row is skipped and the grade reads A+ | Resolved |
| task-007 | [HIGH] | The same review-rubric.md stale-ledger defect logged by task-002, re-found independently and rated [CRITICAL] by a real review: a ledger written to that shape puts Doc and Line at cols[3]/cols[4], so grade.sh finds no bracketed severity and returns A+ for every such ledger. Gate to decide severity. | Resolved |
| task-007 | [MEDIUM] | Hand-off to delivery-002: the carry-as-data key rename is NOT mechanical. reviewer-ledger-schema.md's frontmatter holds 6 bare-string entries; renaming the key alone leaves 6 idless entries under a field whose schema requires objects, and an idless criterion cannot be cited. The data pass must convert shape too. | Resolved |
| task-007 | [HIGH] | Pre-existing, out of delivery-001 scope: reviewer-ledger-schema.md contradicts itself three ways on whether an Accepted/Invalid rationale belongs in Description, Evidence, or both; and its Workflow section gives the reviewer no path to mark a prior finding Invalid though the Status table grants it. | Accepted -- still present on disk (reviewer-ledger-schema.md lines 124, 133, 225 confirm all three passages survive). Genuinely outside delivery-001's scope: no task's Scope covers the Accepted/Invalid status lifecycle, and no gate cycle raised it. Accepted at A+ rather than silently marked resolved. Hands off to a follow-on. |
