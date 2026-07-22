# Delivery Issue Log -- delivery-001

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded -- grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-001 | [HIGH] | Pre-flight ISOLATE Rung-B cross-session resume attaches to any live aid/update-kb-* worktree by branch pattern, not by matching stored Prompt vs the current instruction; a new invocation while an older run is paused elsewhere silently re-enters the stale run and discards the new instruction (no dedupe/first-match guard; CONFIRM shows only the stale Understanding). Fix: match stored Prompt to current instruction (else start fresh / ask), add first-match guard, surface current prompt at CONFIRM. | Open |
