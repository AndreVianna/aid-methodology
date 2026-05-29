# Tests

Unit/integration tests for the canonical helper scripts that AID skills depend on.
Each suite is a self-contained bash script with its own assertions; run them
individually as needed. There is intentionally **no aggregator runner** — the
suite count is small (6), all tests are deterministic, and explicit per-suite
invocation matches the methodology's preference for explicit over magical.

## Test suites

All under `tests/canonical/` (run from repo root):

| Suite | Tests script asserts |
|---|---|
| `read-setting.sh` | `canonical/scripts/config/read-setting.sh` 3-tier resolution (per-skill override > global category default > hardcoded `--default`); `--path` mode for direct dotted lookups |
| `writeback-task-status.sh` | `canonical/scripts/execute/writeback-task-status.sh` 4 arg modes + lock-contention safety under concurrent writers |
| `parse-recipe.sh` | `canonical/scripts/interview/parse-recipe.sh` operating modes (`--list`, `--validate`, `--spec`, `--tasks`, `--render`) + error paths (missing file, malformed front-matter, missing blocks, bad args) |
| `compute-block-radius.sh` | `canonical/scripts/execute/compute-block-radius.sh` BFS transitive-descendant computation for failure-cascade in pool-dispatch (linear chains, diamonds, fan-outs) |
| `delivery-gate-aggregate.sh` | `canonical/scripts/execute/aid-execute` delivery-gate aggregation: preserved deferred rows, empty-issues handling, SCORE computation, grade.sh determinism |
| `fetch-mermaid.sh` | `canonical/scripts/summarize/fetch-mermaid.sh` pin + SHA verify: tampered-cache-hit rejection (Scenario A), post-download bad-blob rejection via curl stub (Scenario B), valid-cache fast path with no HTTP call (Scenario C) |

## Running

```bash
# Run one suite
bash tests/canonical/read-setting.sh

# Verbose
bash tests/canonical/read-setting.sh --verbose

# Run all 5 (no aggregator; just chain them)
for f in tests/canonical/*.sh; do echo "=== $f ==="; bash "$f" || break; done
```

On Windows, run from Git Bash (these are POSIX bash scripts).

## What's NOT tested

- The orchestration skills themselves (`/aid-discover`, `/aid-execute`, etc.) are prompt-driven and hard to test without an AI host; the `discovery-reviewer` sub-agent provides the closest thing to integration verification by adversarially grading KB output each cycle.
- The renderer (`run_generator.py`) — its own VERIFY-4a check runs at end of every render and exits 1 on failure.
- Sub-agent definitions — see `canonical/agents/*/AGENT.md`.
- Cross-tool consistency (Cursor vs Claude Code vs Codex) — covered by the renderer's byte-identity assertion across the 3 profiles.
- End-to-end pipeline behavior (Discover → Interview → Specify → Plan → Detail → Execute → Deploy → Monitor) — exercised by dogfooding (this repo IS the test suite for the methodology) rather than scripted E2E tests.
