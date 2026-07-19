# Delivery Issue Log -- delivery-003

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded -- grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-018 | [LOW] | Structural guard drift: `test-connector-skills-structural.sh` ST26 (a work-004 "no new scripts in connectors/" closed-set assertion) had to be updated to allowlist the new `write-connector.sh`. Legitimate + spec-authorized (this task adds exactly that script), but the gate should confirm the allowlist edit is minimal (only `write-connector.sh` added) and the closed-set intent is otherwise intact. | Deferred to gate (developer flagged; found via regression sweep, not called out by the task DETAIL). |
| task-018 | [MINOR] | `write-connector.sh` `set` runs the `mcp`/`auth_method: none` orphan-secret purge UNCONDITIONALLY (simpler than the skill's ADD-vs-UPDATE old-auth comparison). Developer confirms idempotent + confirmed to actually delete a pre-existing `.secrets/<stem>` (test U38). Gate: confirm this matches the DETAIL's explicit ask and can't purge a still-referenced secret. | Deferred to gate (developer-noted design choice, per DETAIL). |
| task-018 | [MINOR] | `connector-secret.sh`'s 2/3 exit-code normalization branch inside `purge_secret()` is defensively unreachable through the CLI surface (stems pre-validated). Developer states it is intentional defense-in-depth per DETAIL, not dead code. Gate: confirm it's not misleading cruft. | Deferred to gate (developer-noted). |
| task-018 | [INFO] | CI-deferred locally: `tests/run-all.sh` full suite and `test-dogfood-byte-identity.sh` (~700 sequential sha256sum forks -> impractically slow on this Git-Bash host). Developer verified the specific new-file risk surface via `diff -q` + manual `sha256sum` against `profiles/claude-code/`. Gate/CI must run the full byte-identity check. | Deferred to CI. |
