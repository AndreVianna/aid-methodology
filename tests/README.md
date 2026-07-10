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
| `test-read-setting.sh` | `canonical/aid/scripts/config/read-setting.sh` 3-tier resolution (per-skill override > global category default > hardcoded `--default`); `--path` mode for direct dotted lookups |
| `test-writeback-state.sh` | `canonical/aid/scripts/execute/writeback-state.sh` 4 arg modes + lock-contention safety under concurrent writers |
| `test-compute-block-radius.sh` | `canonical/aid/scripts/execute/compute-block-radius.sh` BFS transitive-descendant computation for failure-cascade in pool-dispatch (linear chains, diamonds, fan-outs) |
| `test-delivery-gate-aggregate.sh` | `canonical/aid/scripts/execute/aid-execute` delivery-gate aggregation: preserved deferred rows, empty-issues handling, SCORE computation, grade.sh determinism |
| `test-fetch-mermaid.sh` | `canonical/aid/scripts/summarize/fetch-mermaid.sh` pin + SHA verify: tampered-cache-hit rejection (Scenario A), post-download bad-blob rejection via curl stub (Scenario B), valid-cache fast path with no HTTP call (Scenario C), compute_sha256 unknown-fallback fails-closed when no sha256sum/shasum on PATH (Scenario D) |
| `test-grade.sh` | `canonical/aid/scripts/grade.sh` deterministic severity-tag → letter-grade scorer: per-band letter + count modifier, column-anchored counting (only a Severity-column `[TAG]` in a `Pending`/`Recurred` row counts; Description/Evidence/Summary text ignored — the cycle-7 false-positive guard), `--non-functional` forces F, deprecated `--from-prose` path |
| `test-visual-fidelity.sh` | `canonical/aid/scripts/summarize/validate-visuals.mjs` (Node + Playwright) §7 visual-fidelity gate: good-visual PASS (T3 non-trivial dimensions), collapsed element FAIL (T3), element overlap FAIL (T2), tiny text FAIL (T1); SKIP path when Playwright binary is absent (VF30–VF35). Replaces the retired `test-validate-diagrams.sh`. **Needs `node` + Playwright.** |
| `test-assemble-determinism.sh` | `canonical/aid/scripts/summarize/assemble.sh` determinism (Change 6 / FR-50): byte-identical output for identical inputs (`--manifest` required), different manifests produce different outputs, blank/comment lines ignored, missing section non-zero, NM guardrail — no Mermaid engine in assembled output. |
| `test-payload-size.sh` | Payload-size regression + no-Mermaid-engine assertions (Change 7 / FR-51): assembled `kb.html` < 1 MB ceiling (vs old ~3.4 MB Mermaid baseline); NM.1 no large inline bundle, NM.2 no `mermaid.initialize()`, NM.3 no CDN `<script src>`; S2 self-containment check passes. |
| `test-guardrails-d012.sh` | D-012 guardrail re-checks: C1 output path `.aid/dashboard/kb.html`, C2/C3 no CDN / split asset, NM no-Mermaid-engine assertion present, C5/C6 knowledge-summary status + completeness shapes, §5b/S5b section-5b properties. Asserts static source properties of canonical files — no runtime or Node needed. |
| `test-contrast-check.sh` | `canonical/aid/scripts/summarize/contrast-check.mjs` (Node) WCAG AA contrast: usage exit 2, missing-file non-zero, hex-6/hex-3/`rgb()` parse paths, low-contrast fail, unresolvable-vars skipped-not-failed, dark-theme override extraction, and an integration check that the shipped `knowledge-summary.html` passes. **Needs `node`.** |
| `test-install.sh` | `install.sh` usage / mode-detection surface: unknown flag → usage error exit 2 + prints usage; the retired legacy flags (`--tool`/`--update`/`--uninstall`/`--target`) now fall through to the same unknown-flag path and exit 2 (locks in the tech-debt-L3 excision of the flag-style direct-install mode); `--help`/`-h`; piped invocation (`AID_LIB_PATH` + stdin, `$0` unreadable) prints the usage stub, including for a piped bad flag. Functional install/uninstall/manifest/byte-fidelity/root-agent-merge coverage for the shared `lib/aid-install-core.sh` core now lives in `test-aid-cli.sh`, driven via the persistent CLI's `aid add`/`aid remove`/`aid update` subcommands instead of the retired direct-install flags. |
| `test-assemble-3part.sh` | `canonical/aid/scripts/summarize/assemble-3part.sh` byte-concat of PART1+MERMAID+PART2 → OUTPUT: arg/input validation (missing/empty input → exit 1), auto-created nested output dir, byte-exact concatenation + ordering. |
| `test-assemble-3part-ps1.sh` | `canonical/aid/scripts/summarize/assemble-3part.ps1` (PowerShell mirror) — same contract as the `.sh` oracle, run under `pwsh`. Cross-platform (explicit paths + byte I/O), so it runs fully on the Linux CI runner. **Needs `pwsh`.** |
| `test-install-ps1.sh` | `install.ps1` usage / mode-detection surface (PowerShell mirror): unknown parameter → usage error exit 2 + prints usage; the retired legacy parameters (`-Tool`/`-Update`/`-Uninstall`/`-TargetDirectory`) now fall through to the same path and exit 2 — `-Uninstall` is a declared-but-inert parameter specifically so PowerShell's prefix matching cannot silently alias it to `-UninstallCli`; `-Help`. Host-survival regression guard: install.ps1 invoked as a raw scriptblock (simulating `irm … \| iex`) must not kill the PowerShell host session on either the success (`-UninstallCli -Force`) or usage-error (bad flag) exit path. Functional install/uninstall/manifest/byte-fidelity coverage moved to `test-aid-cli-ps1.sh` (`aid add`/`aid remove`/`aid update`). Replaces the removed `test-setup-ps1.sh`. **Needs `pwsh`.** |

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

- The orchestration skills themselves (`/aid-discover`, `/aid-execute`, etc.) are prompt-driven and hard to test without an AI host; the `aid-reviewer` sub-agent (dispatched by `/aid-discover REVIEW`) provides the closest thing to integration verification by adversarially grading KB output each cycle.
- The renderer (`run_generator.py`) — its own deterministic verify check runs at end of every render and exits 1 on failure.
- Sub-agent definitions — see `canonical/agents/*/AGENT.md`.
- Cross-tool consistency (Cursor vs Claude Code vs Codex) — covered by the renderer's byte-identity assertion across the 3 profiles.
- End-to-end pipeline behavior (Discover → Interview → Specify → Plan → Detail → Execute → Deploy → Monitor) — exercised by dogfooding (this repo IS the test suite for the methodology) rather than scripted E2E tests.
