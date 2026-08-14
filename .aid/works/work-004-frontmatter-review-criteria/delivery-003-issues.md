# Delivery Issue Log -- delivery-003

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded -- grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-016 | [HIGH] | **AC-4 FAILS as measured.** 462 removed guard lines (379 checker + 83 wrapper) against 519 added mechanism lines on the strict count -- and AC-4 names 379 as the figure it is tested against, so it fails more clearly there. Two candidate reclassifications are reported, not applied; even granting both it is 458 vs 462, a 4-line margin. No script/check/validator was added (C-1 held), so the enforcement surface MOVED rather than shrank. Owner decision: accept the criterion as failed and record why, or revise NFR-2 to count mechanism as executable surface only. Not the executor's call. | Open |
