# Delivery Issue Log -- delivery-004

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded -- grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-024 | [LOW] | Current-worktree guard SCOPE: dev implemented it as unconditional for ANY non-main winner (a superset), matching the AC's literal wording + Security Specs framing, rather than the narrower Algorithm-prose reading ("only if about to be worktree-removed"). Safer superset. Gate: confirm the broader reading is intended (it refuses deleting a work whose winner copy lives in the current worktree even for a folder-only delete). | Deferred to gate (dev-flagged interpretation). |
| task-024 | [LOW] | `dotglob` deviation: the dedicated-vs-shared classification counts `.aid/works/*` with `dotglob` ON (so a dot-prefixed work folder can't under-count → misclassify shared as dedicated → over-delete), a deliberate divergence from `enumerate-works.sh`'s own non-dotglob listing loop (that loop only displays; this one feeds a destructive decision). Gate: confirm the safety reasoning. | Deferred to gate (dev-flagged deliberate deviation). |
| task-024 | [INFO] | Containment check (exit 3) real-world bite is Windows-environment-dependent (NTFS junction vs POSIX symlink semantics); `rm -rf`'s own reparse-point-safe behavior still prevented data loss in the tested case. The symlink unit self-skips (clear note) if the host can't produce a resolvable symlink. Forced-removal-failure (exit 3) proven via `git worktree lock` (git-native), not exotic fault injection. Full fault-injection (disk-full, POSIX perm-denied) deferred to CI/Linux. | Deferred to gate/CI (platform nuance, not a gap). |
| task-024 | [INFO] | Dev CAUGHT + FIXED a real bug in self-review: the sentinel lock was released unconditionally on EXIT, so on contention (exit 2) the trap deleted the OTHER process's lock — defeating the sentinel. Fixed with a `LOCK_ACQUIRED` guard (mirrors writeback-state.sh). Good catch; gate: confirm the fix. | Fixed in task-024. |
| task-024 | [INFO] | `test-writeback-state.sh` hangs locally past its concurrency unit (pre-existing local-env issue; that file untouched by task-024). Deferred to CI. delete-pipeline.sh is co-vendor-only (no render; confirmed). | Pre-existing / CI-deferred. |
