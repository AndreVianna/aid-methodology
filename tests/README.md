# Tests

Unit/integration tests for the canonical helper scripts that AID skills depend on.
Each suite is a self-contained bash script with its own assertions. Run the whole
set with the aggregator — `bash tests/run-all.sh` — the single entrypoint shared by
CI and local development; or run any suite individually. Adding a suite needs no
runner edit: `run-all.sh` discovers `tests/canonical/test-*.sh` by glob.

## Test suites

All under `tests/canonical/` (run from repo root):

| Suite | Tests script asserts |
|---|---|
| `test-read-setting.sh` | `canonical/scripts/config/read-setting.sh` 3-tier resolution (per-skill override > global category default > hardcoded `--default`); `--path` mode for direct dotted lookups |
| `test-writeback-state.sh` | `canonical/scripts/execute/writeback-state.sh` 4 arg modes + lock-contention safety under concurrent writers |
| `test-parse-recipe.sh` | `canonical/scripts/interview/parse-recipe.sh` operating modes (`--list`, `--validate`, `--spec`, `--tasks`, `--render`) + error paths (missing file, malformed front-matter, missing blocks, bad args) |
| `test-compute-block-radius.sh` | `canonical/scripts/execute/compute-block-radius.sh` BFS transitive-descendant computation for failure-cascade in pool-dispatch (linear chains, diamonds, fan-outs) |
| `test-delivery-gate-aggregate.sh` | `canonical/scripts/execute/aid-execute` delivery-gate aggregation: preserved deferred rows, empty-issues handling, SCORE computation, grade.sh determinism |
| `test-fetch-mermaid.sh` | `canonical/scripts/summarize/fetch-mermaid.sh` pin + SHA verify: tampered-cache-hit rejection (Scenario A), post-download bad-blob rejection via curl stub (Scenario B), valid-cache fast path with no HTTP call (Scenario C), compute_sha256 unknown-fallback fails-closed when no sha256sum/shasum on PATH (Scenario D) |
| `test-grade.sh` | `canonical/scripts/grade.sh` deterministic severity-tag → letter-grade scorer: per-band letter + count modifier, column-anchored counting (only a Severity-column `[TAG]` in a `Pending`/`Recurred` row counts; Description/Evidence/Summary text ignored — the cycle-7 false-positive guard), `--non-functional` forces F, deprecated `--from-prose` path |

## Running

```bash
# Run every suite (aggregates PASS/FAIL, exits non-zero on any failure)
bash tests/run-all.sh
bash tests/run-all.sh -v          # verbose — pass through to each suite

# Run one suite
bash tests/canonical/test-read-setting.sh
bash tests/canonical/test-read-setting.sh --verbose
```

On Windows, run from Git Bash (these are POSIX bash scripts).

## What's NOT tested

- The orchestration skills themselves (`/aid-discover`, `/aid-execute`, etc.) are prompt-driven and hard to test without an AI host; the `discovery-reviewer` sub-agent provides the closest thing to integration verification by adversarially grading KB output each cycle.
- The renderer (`run_generator.py`) — its own deterministic verify check runs at end of every render and exits 1 on failure.
- Sub-agent definitions — see `canonical/agents/*/AGENT.md`.
- Cross-tool consistency (Cursor vs Claude Code vs Codex) — covered by the renderer's byte-identity assertion across the 3 profiles.
- End-to-end pipeline behavior (Discover → Interview → Specify → Plan → Detail → Execute → Deploy → Monitor) — exercised by dogfooding (this repo IS the test suite for the methodology) rather than scripted E2E tests.
