# Delivery Issue Log -- delivery-002

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded -- grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-029,030,031 | [HIGH] | 14 grid design rows sit after delivery-001's planning rows (roadmap/mvp/backlog) rather than immediately after the aid-design row (SPEC feature-005 3b literal); adjudicated presentational -- task-029 DETAIL line 73 states row order has no oracle and requires only that the 14 stay contiguous ahead of task-033's foundation rows (both satisfied), the checkable AC (A less-than row less-than G8) is satisfied, and groups.mjs family order is fixed by the aid-design row (all are verb design) so it is unaffected; reordering would displace feature-003's committed rows. Gate to confirm. | Deferred |
| (environment) | [MEDIUM] | tests/canonical/test-domain-doc-matrix.sh (MT01/MT02) and test-doc-set-mapping.sh (T15) fail in THIS VM because it ships mawk 1.3.4 not gawk; the test awk program errors with 'syntax error at or near ,'. Verified pre-existing: identical failure set on committed HEAD before task-034. task-034's rows are conditional and MT01/MT02 compare only required rows, so content is unaffected. Not a delivery-002 defect -- an env portability gap in the test harness. | Deferred |
| (environment) | [MEDIUM] | Third suite hit by the same gawk gap: tests/canonical/test-dogfood-byte-identity.sh DBI01 reports 'manifest contains no .claude/ entries' because its awk manifest loader errors under mawk; the manifest genuinely holds 373 .claude/ entries. Verified pre-existing: identical failure at pre-merge commit 3ff30c3b in a clean worktree. Root cause is the VM shipping mawk 1.3.4 instead of gawk -- not a content defect and not caused by the master merge. | Deferred |
