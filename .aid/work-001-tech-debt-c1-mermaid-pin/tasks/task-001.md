# task-001: Pin Mermaid version + SHA verify on BOTH cache-hit AND post-download paths

**Type:** REFACTOR

**Source:** work-001-tech-debt-c1-mermaid-pin → delivery-001

**Depends on:** — (none)

**Status:** Done (commit e912f81, reviewer cycle 1 grade A+, all 10 ACs verified on disk + 6 adversarial checks passed)

**Scope:**
- Modify ONLY `canonical/scripts/summarize/fetch-mermaid.sh` (single-file scope). `python run_generator.py` propagates to the 3 profile-tree copies.
- Add two top-of-file constants: `PINNED_VERSION="v11.15.0"` and `EXPECTED_SHA256="70137e77bb273bb2ef972b86e8b0400cca8be53cb25bfc45911a186dc98665de"`.
- Remove the npm `/mermaid/latest` HTTP query. Derive `LATEST` from `PINNED_VERSION`.
- Install sha256 compare-and-reject gate at TWO distinct verify points (cache-hit + post-download).
- Generic error message (no `EXPECTED_SHA256` echoed to stderr).
- `.meta` file is treated as untrusted at runtime.

**Acceptance Criteria:** (all closed per reviewer cycle 1)
- [x] AC1: PINNED_VERSION + EXPECTED_SHA256 constants present
- [x] AC2: Cache-hit verify deletes both files + exits non-zero on mismatch
- [x] AC3: Post-download verify deletes both files + exits non-zero on mismatch
- [x] AC4: Generic error message; no EXPECTED_SHA256 leak
- [x] AC5: npm /mermaid/latest query removed; LATEST from PINNED_VERSION
- [x] AC6: Tampered .js with correct .meta version=11.15.0 still fails
- [x] AC7: Clean cache hit: one sha256sum call, no HTTP, exit 0
- [x] AC8: Only fetch-mermaid.sh modified
- [x] AC9: All 3 profile-tree copies byte-identical (sha256 4614253808bbe9afe569ef05729ce6497d2ecff048b0f22359a18294a766c945)
- [x] AC10: §6 quality gates pass
