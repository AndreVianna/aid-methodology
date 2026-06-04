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
| `test-validate-diagrams.sh` | `canonical/scripts/summarize/validate-diagrams.mjs` (Node) D1 regex sanity + invocation paths via `--fast`: no-args/`--help`/missing-file → exit 2, zero-diagram warn-pass, valid `<pre>`/`<div>` diagrams, and D1 failures (directive-only, unrecognized type, empty block, mixed). D2 render is not hermetic (needs jsdom/mermaid-cli) and is out of scope. **Needs `node`.** |
| `test-contrast-check.sh` | `canonical/scripts/summarize/contrast-check.mjs` (Node) WCAG AA contrast: usage exit 2, missing-file non-zero, hex-6/hex-3/`rgb()` parse paths, low-contrast fail, unresolvable-vars skipped-not-failed, dark-theme override extraction, and an integration check that the shipped `knowledge-summary.html` passes. **Needs `node`.** |
| `test-install.sh` | `install.sh` + `lib/aid-install-core.sh` installer: usage/error exits (unknown flag → 2, mutually-exclusive flags → 2, missing target → 2); fresh install per tool (claude-code/.claude+CLAUDE.md, codex/.codex+.agents+AGENTS.md, cursor/.cursor+AGENTS.md, copilot-cli/.github+AGENTS.md, antigravity/.agent+AGENTS.md); byte-fidelity of installed files vs `profiles/<tool>/` sources; idempotent re-install (“Up to date”); `--force` overwrites a locally-edited file; manifest correctness (paths + version + root_agent sha256 + status); uninstall exactness (removes manifested paths, manifest + .aid/ pruned on last tool); protect-on-diff FR11 (pre-placed user AGENTS.md → not overwritten, `*.aid-new` written, exit 5; `--force` overwrites); uninstall safety (modified AID-owned AGENTS.md left in place); comma-list `--tool codex,cursor` (second AGENTS.md triggers protect-on-diff); auto-detect (single marker→used, two→exit 2, none→exit 2); `--update` mode; `--help`/`-h`; `--from-bundle` with directory; multi-tool install without AGENTS.md collision; partial uninstall (one tool preserved); manifest contains only relative POSIX paths. All paths driven via `--from-bundle` with locally-built fixture tarballs — no network. |
| `test-assemble-3part.sh` | `canonical/scripts/summarize/assemble-3part.sh` byte-concat of PART1+MERMAID+PART2 → OUTPUT: arg/input validation (missing/empty input → exit 1), auto-created nested output dir, byte-exact concatenation + ordering. |
| `test-assemble-3part-ps1.sh` | `canonical/scripts/summarize/assemble-3part.ps1` (PowerShell mirror) — same contract as the `.sh` oracle, run under `pwsh`. Cross-platform (explicit paths + byte I/O), so it runs fully on the Linux CI runner. **Needs `pwsh`.** |
| `test-install-ps1.sh` | `install.ps1` + `lib/AidInstallCore.psm1` (PowerShell installer mirror) — FR9 parity suite asserting the same message strings and exit codes as `test-install.sh` for all platform-independent paths: arg/precondition errors (mutually-exclusive flags → 2, missing target → 2, unknown parameter → 1), fresh install per tool (all 5; .claude/.codex/.agents/.cursor/.github/.agent + root agent file), byte-fidelity vs `profiles/<tool>/` sources, idempotent re-install (`Up to date:`), `-Force` overwrite, manifest correctness (paths + aid_version + sha256 + status), uninstall exactness (`Removed:` / `Uninstall complete.`), protect-on-diff FR11 (pre-placed file → not overwritten, `.aid-new` written, exit 5; `-Force` overwrites), uninstall safety (modified AID-owned file `Left in place`), auto-detect (single marker→used, two→exit 2, none→exit 2), `-Update` mode, `-Help`, `-FromBundle` with directory. Multi-tool comma-list cases excluded (PS1 strict-mode manifest property-lookup divergence). All driven via `-FromBundle` with locally-built fixture tarballs — no network. Replaces the removed `test-setup-ps1.sh`. **Needs `pwsh`.** |

## Running

```bash
# Run every suite (aggregates PASS/FAIL, exits non-zero on any failure)
bash tests/run-all.sh
bash tests/run-all.sh -v          # verbose — pass through to each suite

# Run one suite
bash tests/canonical/test-read-setting.sh
bash tests/canonical/test-read-setting.sh --verbose
```

On Windows, run from Git Bash (these are POSIX bash scripts). Some suites shell
out to other runtimes — the two `.mjs` validator suites need `node`, and the two
`*-ps1.sh` suites need `pwsh` — and each skips (exit 0 with a `SKIP:` notice) if
its runtime is absent, so a host missing one still runs the rest. CI provides both.

## What's NOT tested

- The orchestration skills themselves (`/aid-discover`, `/aid-execute`, etc.) are prompt-driven and hard to test without an AI host; the `discovery-reviewer` sub-agent provides the closest thing to integration verification by adversarially grading KB output each cycle.
- The renderer (`run_generator.py`) — its own deterministic verify check runs at end of every render and exits 1 on failure.
- Sub-agent definitions — see `canonical/agents/*/AGENT.md`.
- Cross-tool consistency (Cursor vs Claude Code vs Codex) — covered by the renderer's byte-identity assertion across the 3 profiles.
- End-to-end pipeline behavior (Discover → Interview → Specify → Plan → Detail → Execute → Deploy → Monitor) — exercised by dogfooding (this repo IS the test suite for the methodology) rather than scripted E2E tests.
