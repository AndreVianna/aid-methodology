---
kb-category: primary
source: hand-authored
intent: |
  Inventory of test suites that protect the canonical bash helper scripts AID
  skills depend on. 5 unit/integration suites under tests/canonical/, all
  deterministic bash. NO methodology/orchestration/E2E tests — those don't
  exist and aren't needed (the methodology is exercised by dogfooding, the
  renderer has its own VERIFY-4a gate). Read this to understand what changes
  to canonical/scripts/ are guarded by tests vs require manual verification.
contracts:
  - "5 test suites under tests/canonical/, no skill-level tests"
  - "All suites are bash (POSIX); require Git Bash on Windows"
  - "No aggregator script (per Q6 cycle-1 decision); explicit per-suite invocation"
changelog:
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

## Suites (5)

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
File: `tests/canonical/read-setting.sh` (~360 lines)

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

7 numbered units; **69 assertions** (most units exercise multiple assert helpers).
File: `tests/canonical/writeback-task-status.sh` (~535 lines)

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

19 numbered units; **113 assertions**.
File: `tests/canonical/parse-recipe.sh` (~1,002 lines — the largest suite)

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
File: `tests/canonical/compute-block-radius.sh` (~345 lines)

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
File: `tests/canonical/delivery-gate-aggregate.sh` (~535 lines)

---

## Total test count

| Suite | Assertions |
|---|---|
| `read-setting.sh` | 18 |
| `writeback-task-status.sh` | 69 |
| `parse-recipe.sh` | 113 |
| `compute-block-radius.sh` | 17 |
| `delivery-gate-aggregate.sh` | 18 |
| **Total** | **235** |

Count method: running each suite and summing PASS counts (cross-checked against
assertion call sites in source for suites with simple call patterns).

---

## Running

```bash
# Individual suites (from repo root — Git Bash on Windows)
bash tests/canonical/read-setting.sh
bash tests/canonical/writeback-task-status.sh
bash tests/canonical/parse-recipe.sh
bash tests/canonical/compute-block-radius.sh
bash tests/canonical/delivery-gate-aggregate.sh

# Verbose output
bash tests/canonical/read-setting.sh --verbose

# Run all 5 in sequence (no aggregator — per Q6 cycle-1 decision)
for f in tests/canonical/*.sh; do echo "=== $f ==="; bash "$f" || break; done
```

**Windows note:** all suites are POSIX bash. Run from Git Bash, not PowerShell or CMD.

Exit code: `0` = all passed, `1` = one or more failures. Each suite prints a
`PASS`/`FAIL` line per assertion and a summary at the end.

There is no CI. Maintainer runs suites manually before merging. See `tech-debt.md H2`
for the formal debt item.

---

## Coverage gaps and roadmap

- **No CI** — tests only run when someone runs them manually. See `tech-debt.md H2`.
- **No coverage measurement** — statement/branch coverage of the canonical helpers is
  unknown; test-line-to-source-line ratio is the only proxy.
- **No tests for PowerShell variants** — `canonical/scripts/summarize/concatenate.ps1`
  and mirror install-tree copies are untested.
- **No tests for `.mjs` validators** — `validate-diagrams.mjs` (574 lines) and
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
