# task-002: Add tests/canonical/fetch-mermaid.sh covering both verify points + clean fast path

**Type:** TEST

**Source:** work-001-tech-debt-c1-mermaid-pin → delivery-001

**Depends on:** task-001

**Status:** In Review cycle 3 (commit 7ead158; live re-run shows Tests passed: 19, exit 0)

**Scope:**
- Add `tests/canonical/fetch-mermaid.sh` covering 3 scenarios:
  - **Scenario A** (cache-hit tampered): seed tampered cache; assert exit ≠ 0, both files deleted, generic error to stderr, no SHA leak (A5).
  - **Scenario B** (post-download tampered): curl PATH-shim writes bad blob; assert exit ≠ 0, downloaded file deleted, generic error (B4), no SHA leak (B5).
  - **Scenario C** (clean fast path): VALID cached file (matching SHA); assert exit 0, files preserved, no HTTP call (curl-not-invoked); CDN-download fallback if local seed missing.
  - **Scenario D** (compute_sha256 "unknown" fallback): PATH-shim with no sha256sum/shasum, only symlinks to needed bins; bad-blob curl stub; assert exit ≠ 0, no SHA leak, sha256sum not invoked (D4).
- Extract `EXPECTED_SHA256` from script at runtime; no hardcoded hex.
- Wire into `tests/README.md`.
- `pass()` function uses explicit `if/fi` form (not `&&` short-circuit) to avoid set-euo-pipefail abort.

**Cycle history:**
- Cycle 1 (d51389d): claimed 14/14 — actually never ran (pass() defect; reviewer-1 false-positive verification).
- Cycle 1 review: 4 findings (3 LOW + 1 MINOR) → grade B.
- Cycle 2 FIX (7a7838e): claimed 18/18; cycle-2 reviewer caught broken pass() (CRITICAL) + defeated PATH-shim (HIGH) → grade E+ regression.
- Cycle 3 FIX (7ead158): pass() rewritten with `if/fi`; PATH-shim uses shim-dir-only with symlinks for needed bins, NO /usr/bin. Live re-run: Tests passed: 19, exit 0.

**Acceptance Criteria:** (cycle 3 — pending review)
- [x] tests/canonical/fetch-mermaid.sh exists, executable, has `set -euo pipefail`
- [x] Scenarios A/B/C/D all exercise their intended code paths
- [x] EXPECTED_SHA256 extracted at runtime (no hex copy in test)
- [x] No stderr leak of EXPECTED_SHA256 (A5, B5, D2, D3)
- [x] `Tests passed: N` summary line emitted
- [x] tests/README.md lists the suite (consistent count)
- [x] Live re-run confirms 19/19 pass and exit 0 (verified by orchestrator after cycle 3)
- [x] PATH-shim hides sha256sum AND shasum (D4 asserts sha256sum not invoked)
- [x] All §6 quality gates pass
