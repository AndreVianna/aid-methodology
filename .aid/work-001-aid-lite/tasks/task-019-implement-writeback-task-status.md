# task-019: Implement `writeback-task-status.sh` helper + smoke-test harness

**Type:** IMPLEMENT

**Source:** feature-004-two-tier-review → delivery-003

**Depends on:** —

**Scope:**
- Create `canonical/templates/scripts/writeback-task-status.sh` — placed under the existing general-helper scripts directory (alongside `build-project-index.sh`, `grade.sh`, `verify-kb-claims.sh`). Note: work-003's `writeback-state.sh` precedent lives one level deeper at `canonical/templates/knowledge-summary/scripts/` because it is knowledge-summary-specific; the new helper is general-purpose (consumed by aid-execute), so the top-level scripts directory is the right level.
- Lock mechanism: sentinel-file lock (`set -o noclobber` atomic-create + sleep-poll retry on contention), mirroring work-003's `writeback-state.sh` pattern.
- Args: `--task-id NNN --field <field> --value <value>` for `## Tasks Status` row updates.
- Args: `--delivery-id NNN --block <markdown-block>` for `## Delivery Gates` section block writes.
- Cross-platform via plain Bash semantics (no `flock`/`LockFileEx` dependency).
- Write a 5-row concurrent-write smoke-test harness under `canonical/templates/scripts/test-writeback-task-status.sh`.

**Acceptance Criteria:**
- [ ] Helper updates the named field in the named task's row without disturbing other rows.
- [ ] Helper writes a multi-line block into `## Delivery Gates` keyed by delivery-NNN.
- [ ] Smoke-test passes: 5 concurrent processes each writing to a different row produce a final file with all 5 rows correctly updated (no lost writes, no duplicate writes, no corruption).
- [ ] Helper is idempotent: re-running the same update produces no change in file size.
- [ ] Helper releases the sentinel file on success and on error (trap EXIT).
- [ ] Helper exits non-zero on failure with a clear message.
- [ ] Unit tests for the field-extraction + replacement logic.
- [ ] All §6 quality gates pass.
