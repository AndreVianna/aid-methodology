---
kb-category: primary
source: hand-authored
intent: |
  Inventory of test suites that protect the canonical bash helper scripts AID
  skills depend on. 7 unit/integration suites under tests/canonical/, all
  deterministic bash. NO methodology/orchestration/E2E tests — those don't
  exist and aren't needed (the methodology is exercised by dogfooding, the
  renderer has its own VERIFY-4a gate). Read this to understand what changes
  to canonical/scripts/ are guarded by tests vs require manual verification.
contracts:
  - "7 test suites under tests/canonical/, no skill-level tests"
  - "All suites are bash (POSIX); require Git Bash on Windows"
  - "No aggregator script (per Q6 cycle-1 decision); explicit per-suite invocation"
changelog:
  - 2026-05-29: Corrected count 5→7 suites / 235→273 assertions — added the fetch-mermaid.sh and grade.sh sections (both existed on disk but were missing from this inventory); fixed validate-diagrams.mjs line count 574→577
  - 2026-05-27: Initial generation by discovery-quality (cycle-1)
  - 2026-05-27: Full rewrite during cycle-2 FIX Phase B for accurate post-Q6-cleanup state (Q20)
---
# Test Landscape

## Scope

These tests cover **canonical bash helper scripts** only — the small, side-effect-free
utilities that AID skills invoke at runtime (writeback, BFS compute, recipe parsing, etc.).

What is NOT tested here:
- **Orchestration skills** (`/aid-discover`, `/aid-execute`, …) — prompt-driven; no
  scripted harness exists or is planned. The `discovery-reviewer` sub-agent acts as the
  closest adversarial integration check each cycle.
- **Renderer** (`run_generator.py`) — covered by its own VERIFY-4a determinism gate
  (`verify_deterministic.py`); see `architecture.md`.
- **Sub-agent definitions** — no test harness; verified by dogfooding.
- **Cross-tool consistency** (Cursor vs Claude Code vs Codex) — covered by the renderer's
  byte-identity assertion across the 3 install-tree profiles.
- **E2E pipeline** (Discover → … → Deploy) — exercised by dogfooding this repo, not
  scripted tests.

---

## Suites (7)

All suites live under `tests/canonical/` and target scripts under `canonical/scripts/`.

### read-setting.sh

**Target:** `canonical/scripts/config/read-setting.sh`

Covers the three-tier settings-resolution model:
- Per-skill override wins over global category default, which wins over hardcoded `--default`
- `--path` mode (direct dotted key lookup)
- Missing `settings.yml` with and without `--default`
- Comment stripping, quote stripping
- Error exits (bad `--path` format, unknown flag, missing paired args)

11 numbered scenarios; **18 assertions** (some scenarios contain multiple asserts).
File: `tests/canonical/test-read-setting.sh` (~360 lines)

### writeback-task-status.sh

**Target:** `canonical/scripts/execute/writeback-task-status.sh`

Covers all 4 argument modes plus safety:
- `--task-id --field --value` (single-field row update)
- `--task-id --findings` (Quick Check block write)
- `--delivery-id --block` (Delivery Gate block write)
- `--delivery-id --append-issue` (delivery-NNN-issues.md append)
- Idempotency (re-running each mode produces no additional change)
- Concurrent lock contention (5 parallel writers, different rows)
- Error paths (missing args, invalid task-id, lock timeout, missing lock dir)

7 numbered units; **69 assertions** (script prints "Tests passed: 69" then "All tests passed." in summary).
File: `tests/canonical/test-writeback-task-status.sh` (~535 lines)

### parse-recipe.sh

**Target:** `canonical/scripts/interview/parse-recipe.sh`

Covers all operating modes and error paths:
- `--list`, `--validate`, `--spec`, `--tasks`, `--render`
- Slot substitution, `{!{` escape rewrite, unmatched slot passthrough
- Multi-task recipe emits multiple task files
- Lock file lifecycle
- Name-vs-filename mismatch warning
- Error paths: missing file, malformed front-matter, missing blocks, bad args
- Units 15–19: validates each of the 5 seed recipes in `canonical/recipes/` (dogfood)

19 numbered units; **113 assertions** (script prints "Tests passed: 113" then "All tests passed." in summary). **Runtime note:** this suite takes ~150 s; do not impose timeouts under 180 s.
File: `tests/canonical/test-parse-recipe.sh` (~1,002 lines — the largest suite)

### compute-block-radius.sh

**Target:** `canonical/scripts/execute/compute-block-radius.sh`

Covers BFS transitive-descendant computation used by the pool-dispatch failure cascade:
- Linear chain, diamond, fan-out, unrelated chain, mid-chain failure
- No-dependents (leaf node) → empty block-radius
- Multi-root fan graphs
- End-to-end with `--plan-file` (PLAN.md parsing)
- Integration: 5-task delivery graph with seeded failure
- Error exits (missing required args, conflicting args, file-not-found)
- Whitespace normalization on `--failed-task`
- Stability check: `state-execute.md` degradation-notice format

17 numbered tests (T01–T17).
File: `tests/canonical/test-compute-block-radius.sh` (~345 lines)

### delivery-gate-aggregate.sh

**Target:** delivery-gate logic in `aid-execute` (uses `writeback-task-status.sh` +
`canonical/scripts/grade.sh` as collaborators)

Covers:
- AGGREGATE with existing `delivery-NNN-issues.md` (deferred rows preserved)
- AGGREGATE with no issues file (creates empty log correctly)
- SCORE computation for 3 sample deliveries of varying complexity
- Grade computation via `grade.sh` (deterministic output verification)
- Loopback guard (grade < min does NOT re-run quick-checks; only loops review)
- FR6 interlock (gate must not fire while any task has status Failed or Blocked)

6 numbered scenarios; **18 assertions**.
File: `tests/canonical/test-delivery-gate-aggregate.sh` (~535 lines)

### fetch-mermaid.sh

**Target:** `canonical/scripts/summarize/fetch-mermaid.sh`

Covers the C1 supply-chain pin + SHA-verification (added 2026-05-29):
- Tampered cache-hit rejection (Scenario A) — a corrupted cached blob fails the SHA check
- Post-download bad-blob rejection (Scenario B) — via a `curl` PATH-shim returning a tampered payload
- Valid-cache fast path (Scenario C) — no HTTP call is made when the cache is present and valid
- `compute_sha256` "unknown" fallback (Scenario D) — fails closed when neither `sha256sum` nor `shasum` is on PATH (sha256sum-spy via symlink)

4 scenarios; **19 assertions** (script prints "Tests passed: 19" then "All tests passed.").
File: `tests/canonical/test-fetch-mermaid.sh` (~494 lines)

### grade.sh

**Target:** `canonical/scripts/grade.sh`

Regression suite for the M7 column-anchored rewrite of the severity-tag → letter-grade scorer:
- Each severity band maps to the correct letter + count modifier
- Only Severity-column `[TAG]` values in `Pending`/`Recurred` rows are counted (tags in Description/Evidence cells and prose Summary lines are ignored — the cycle-7 false-positive guard)
- `--non-functional` forces F; empty / zero-finding ledger → A+
- Deprecated `--from-prose` path still parses (with fenced / inline-code stripping)

**19 assertions** (script prints "Tests passed: 19" then "All tests passed.").
File: `tests/canonical/test-grade.sh` (~353 lines)

---

## Total test count

| Suite | Assertions | Self-reported summary line |
|---|---|---|
| `read-setting.sh` | 18 | `Passed: 18 / Failed: 0` |
| `writeback-task-status.sh` | 69 | `Tests passed: 69 / All tests passed.` |
| `parse-recipe.sh` | 113 | `Tests passed: 113 / All tests passed.` |
| `compute-block-radius.sh` | 17 | `Results: 17 passed, 0 failed` |
| `delivery-gate-aggregate.sh` | 18 | `Results: 18 passed, 0 failed` |
| `fetch-mermaid.sh` | 19 | `Tests passed: 19 / All tests passed.` |
| `grade.sh` | 19 | `Tests passed: 19 / All tests passed.` |
| **Total** | **273** | (sum of self-reported summary lines) |

Count method: each suite's own self-reported summary line is authoritative. Verified end-to-end (cycle-5, 2026-05-27): run each suite with timeout ≥180s (parse-recipe takes ~150s), then read the script's own "Tests passed: N" / "Results: N passed" line. Do NOT count `PASS:` markers via grep — different suites use different formats and you may undercount if a suite hangs or is timed-out before completion. Recount after any test addition.

---

## Running

```bash
# Individual suites (from repo root — Git Bash on Windows)
bash tests/canonical/test-read-setting.sh
bash tests/canonical/test-writeback-task-status.sh
bash tests/canonical/test-parse-recipe.sh
bash tests/canonical/test-compute-block-radius.sh
bash tests/canonical/test-delivery-gate-aggregate.sh
bash tests/canonical/test-fetch-mermaid.sh
bash tests/canonical/test-grade.sh

# Verbose output
bash tests/canonical/test-read-setting.sh --verbose

# Run all 7 in sequence (no aggregator — per Q6 cycle-1 decision)
for f in tests/canonical/*.sh; do echo "=== $f ==="; bash "$f" || break; done
```

**Windows note:** all suites are POSIX bash. Run from Git Bash, not PowerShell or CMD.

Exit code: `0` = all passed, `1` = one or more failures. Each suite prints a
`PASS`/`FAIL` line per assertion and a summary at the end.

CI is enforced: `.github/workflows/test.yml` (added 2026-05-29) runs the suites on every PR/push and is a required status check on `master` — a PR cannot merge unless it is green.

---

## Coverage gaps and roadmap

- **CI enforced** — `.github/workflows/test.yml` runs the suites on PR/push and is a required status check on `master`.
- **No coverage measurement** — statement/branch coverage of the canonical helpers is
  unknown; test-line-to-source-line ratio is the only proxy.
- **No tests for PowerShell variants** — `canonical/scripts/summarize/concatenate.ps1`
  and mirror install-tree copies are untested.
- **No tests for `.mjs` validators** — `validate-diagrams.mjs` (577 lines) and
  `contrast-check.mjs` (151 lines) have no Node test harness.
- **No tests for `setup.sh` / `setup.ps1`** — the end-user install flow is untested.
- **bats migration** — the inline `PASS=0` / `FAIL=0` counter pattern works but
  produces no TAP output. Migration to `bats-core` would enable parallel runs and
  standard CI integration; deferred as low-priority.

---

## Adding a new suite

1. Create `tests/canonical/<helper-name>.sh` targeting `canonical/scripts/<path>/<helper>.sh`.
2. Use the same `PASS=0` / `FAIL=0` / `pass()` / `fail()` scaffold as existing suites.
3. Use `set -u` (not `set -e`) so all failures are reported in one run.
4. Use `mktemp -d` + `trap 'rm -rf ...' EXIT` for fixture cleanup.
5. Add the suite to the table in `tests/README.md` and update the count here.
