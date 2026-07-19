# Delivery Issue Log -- delivery-005

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded -- grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-028 | [INFO] | GOOD CATCH: the `.gitignore` "AID managed" block is GENERATOR-produced (`lib/aid-install-core.sh` `_aid_gitignore_block` + `lib/AidInstallCore.psm1` `Get-AidGitignoreBlock`, both "rewritten on every add/update"), so a static `.gitignore` edit alone would be silently reverted by the next `aid update`. Dev fixed BOTH generators too (added `.aid/.control/` alongside `.aid/.heartbeat/`). install-provisioning tests 44/44 + 33/33 pass; no test hardcodes a line-count. Gate: confirm the twin generators (bash + ps1) stay in sync. | Deferred to gate (dev-flagged, verified). |
| task-028 | [INFO] | RENDER handled correctly: `write-control-signal.sh` authored in `canonical/aid/scripts/execute/`, `run_generator.py` rendered to all 5 profiles + dogfood `.claude/` resynced + co-vendored to `dashboard/scripts/` + MANIFEST; byte-identity confirmed across canonical↔5 profiles↔.claude↔dashboard via `diff -q`; render diff scope is ONLY the new file × 5 + 5 emission-manifest lines (no drift). 50/50 writer tests. `test-writeback-state.sh` local-hang (untouched, CI-deferred); full byte-identity → CI. | Clean. |
| task-028 | [LOW] | KB-delta follow-up (out of task-028's IMPLEMENT scope, dev-flagged): `.aid/knowledge/module-map.md` line ~157 lists the `execute/` script set and doesn't yet mention `write-control-signal.sh`. Housekeeping, not blocking. | Deferred (KB-delta follow-up). |
