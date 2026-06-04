# task-002: `release.sh` packaging test suite

**Type:** TEST

**Source:** feature-002-release-packaging-and-checksums → delivery-001

**Depends on:** task-001

**Scope:**
- Author `tests/canonical/test-release.sh` per feature-002 §S6: `#!/usr/bin/env bash`, fixed header, `set -u`, `source ../lib/assert.sh`, `mktemp -d` + `trap 'rm -rf' EXIT`, one assert per case; auto-discovered by `tests/run-all.sh`'s `tests/canonical/test-*.sh` glob.
- Drive `release.sh --dry-run` (hermetic: no network, no `gh`, no tag creation) and cover cases RL01–RL08 (naming, layout incl. no-`README.md`/no-`emission-manifest.jsonl`, flat root, `SHA256SUMS` format, checksum correctness, render-drift gate FAIL on dirtied `profiles/` via a temp copy, version-mismatch FAIL, help/exit).
- No PowerShell parity required (maintainer-only Bash helper; §S6).

**Acceptance Criteria:**
- [ ] `tests/canonical/test-release.sh` is auto-discovered by `tests/run-all.sh` and passes the full RL01–RL08 case set.
- [ ] The suite is hermetic (drives `--dry-run` only; no live `gh`/network/tag side effects) and leaves the real `profiles/` untouched (render-drift case operates on a temp clone).
- [ ] RL04/RL05 assert the `SHA256SUMS` format and checksum correctness against independently computed sha256s of the staged tarballs.
- [ ] All §6 quality gates pass.
