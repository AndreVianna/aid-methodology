# Mermaid library fetch — pin version + verify SHA — Refactor

- **Work:** work-001-tech-debt-c1-mermaid-pin
- **Created:** 2026-05-28
- **Source:** /aid-interview lite path — LITE-REFACTOR
- **Status:** In Execute (reconstructed 2026-05-29 after `.aid/` bulk-delete incident)

## Goal

Eliminate a supply-chain risk in `canonical/scripts/summarize/fetch-mermaid.sh`. Today the script downloads `mermaid@latest` from the npm registry on every invocation with no version pin and no expected-SHA verification before installing into the cache. After the refactor, the script downloads exactly one pinned version (v11.15.0, the version currently in cache), compares the downloaded sha256 to a pinned `EXPECTED_SHA256` constant, and refuses to use the cached file on mismatch — verifying on BOTH the cache-hit path AND the post-download path. Same purpose (provide an inlined Mermaid library to `/aid-summarize`), safer mechanism (reproducible + tamper-detectable).

## Context

**Scope:** `canonical/scripts/summarize/fetch-mermaid.sh` (single canonical script). Plus 1 new test under `tests/canonical/`. Propagation to 3 profile-tree copies via `python run_generator.py`. Dogfood `.claude/` refreshed by `setup.sh` after merge.

**Before:** `fetch-mermaid.sh` queries `https://registry.npmjs.org/mermaid/latest` on every invocation (lines 16–18), downloads `https://cdn.jsdelivr.net/npm/mermaid@${LATEST}/dist/mermaid.min.js` (line 41), then computes sha256 AFTER the download and stores it as cache metadata (lines 59–73). No version pin. No `EXPECTED_SHA256` constant compared at verification time. An npm-registry compromise or jsDelivr MITM silently ships compromised JS into the offline KB viewer that every adopter opens in their browser. Reproducibility is also broken — diagrams may render differently across runs.

**After:** Two pinned constants at the top of `fetch-mermaid.sh`: `PINNED_VERSION` (set to `v11.15.0`, the version currently in cache) and `EXPECTED_SHA256` (the known-good hash for that version's `mermaid.min.js`). The npm `/mermaid/latest` query is removed — `LATEST` is set from `PINNED_VERSION`. **SHA verification is the gate on EVERY use of the cached file, not just download — two distinct verify points:**

- **(a) Cache-hit path** (lines 33–38 of the original script): before returning the cached file as authoritative, compute its sha256 and compare to `EXPECTED_SHA256`. On mismatch, delete the tampered file + delete its `.meta` sibling + exit non-zero with a clear `SHA mismatch` error.
- **(b) Post-download path**: same compute-and-compare after the fresh download. On mismatch, delete the freshly-downloaded file + delete `.meta` + exit non-zero.

A comment block near the constants documents the manual bump procedure (where to look up the new SHA on npmjs.com, how to update the constants, how to test). Valid cache hits stay fast (one sha256sum call); invalid (tampered or wrong-version) cache files are rejected before use. The `.meta` file is treated as untrusted — version match is necessary but not sufficient; only the SHA comparison is the actual trust boundary.

**KB references:**
- `.aid/knowledge/tech-debt.md` — item **C1** (the canonical debt entry being closed by this work).
- `.aid/knowledge/STATE.md ## Knowledge Summary Status` — current `Mermaid Version: 11.15.0` and cache sha256 source.
- `.aid/knowledge/security-model.md` — supply-chain section (background on dependency-trust posture).

## Acceptance Criteria

- [x] `fetch-mermaid.sh` has explicit `PINNED_VERSION` + `EXPECTED_SHA256` constants near the top. *(closed by task-001, commit e912f81)*
- [x] **Cache-hit path** runs SHA verification before returning the cached file; on mismatch, deletes cached file + meta + exits non-zero. *(closed by task-001)*
- [x] **Post-download path** runs SHA verification after the fresh download; on mismatch, deletes downloaded file + meta + exits non-zero. *(closed by task-001)*
- [x] Running the script with a tampered cache file (regardless of whether the .meta version matches `PINNED_VERSION`) exits non-zero AND the tampered file is deleted. *(closed by task-001 AC6)*
- [x] Running the script with a clean, valid cache file leaves it in place and reports SHA match. *(closed by task-001 AC7)*
- [x] New test in `tests/canonical/` covers BOTH verify points (cache-hit verify on tampered file + post-download verify after a successful download) AND the clean-cache fast path. *(closed by task-002, commits d51389d → 7a7838e → 7ead158)*
- [x] `canonical/scripts/summarize/fetch-mermaid.sh` is the only canonical script modified for the fix itself; `python run_generator.py` propagates to the 3 profile trees. *(closed by task-001)*
- [x] After this lands, `.aid/knowledge/tech-debt.md` item C1 is marked **RESOLVED** with the commit reference. *(task-003)*
- [x] All existing tests pass; `/aid-summarize` VALIDATE state still reports Machine Grade ≥ A. *(verify at task-003; A+ confirmed)*
- [x] All §6 quality gates pass (baseline test/lint per REQUIREMENTS.md §6). *(verify at task-003)*

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Pin Mermaid version + SHA verify on BOTH cache-hit AND post-download paths |
| task-002 | TEST | Add tests/canonical/fetch-mermaid.sh covering both verify points + clean fast path |
| task-003 | DOCUMENT | Close tech-debt.md C1 + add bump-procedure comment in fetch-mermaid.sh |
| task-004 | DOCUMENT | KB markdown cascade-update for C1 closure |
| task-005 | DOCUMENT | HTML summary cascade-update for C1 closure (summary-src/sections + re-assemble) |

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | (none) |
| task-002 | task-001 |
| task-003 | task-001, task-002 |
| task-004 | task-001, task-003 |
| task-005 | task-001, task-002, task-003, task-004 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
| 2 | task-002 |
| 3 | task-003 |
| 4 | task-004 |
| 5 | task-005 |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-05-28 | Initial lite-path SPEC created | /aid-interview LITE-REFACTOR |
| 2026-05-28 | Tasks + Execution Graph filled (Option C, 3 tasks) | /aid-interview TASK-BREAKDOWN cycle 1 |
| 2026-05-28 | Context "After" + AC rewritten for cache-hit + post-download verify | /aid-interview L1 loopback |
| 2026-05-29 | Reconstructed after `.aid/work-*/` bulk-delete incident at 00:16:30 UTC-4 | manual recovery; content preserved in session transcript |
