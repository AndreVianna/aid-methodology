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
| `test-compute-block-radius.sh` | `canonical/scripts/execute/compute-block-radius.sh` BFS transitive-descendant computation for failure-cascade in pool-dispatch (linear chains, diamonds, fan-outs) |
| `test-delivery-gate-aggregate.sh` | `canonical/scripts/execute/aid-execute` delivery-gate aggregation: preserved deferred rows, empty-issues handling, SCORE computation, grade.sh determinism |
| `test-fetch-mermaid.sh` | `canonical/scripts/summarize/fetch-mermaid.sh` pin + SHA verify: tampered-cache-hit rejection (Scenario A), post-download bad-blob rejection via curl stub (Scenario B), valid-cache fast path with no HTTP call (Scenario C), compute_sha256 unknown-fallback fails-closed when no sha256sum/shasum on PATH (Scenario D) |
| `test-grade.sh` | `canonical/scripts/grade.sh` deterministic severity-tag → letter-grade scorer: per-band letter + count modifier, column-anchored counting (only a Severity-column `[TAG]` in a `Pending`/`Recurred` row counts; Description/Evidence/Summary text ignored — the cycle-7 false-positive guard), `--non-functional` forces F, deprecated `--from-prose` path |
| `test-visual-fidelity.sh` | `canonical/scripts/summarize/validate-visuals.mjs` (Node + Playwright) §7 visual-fidelity gate: good-visual PASS (T3 non-trivial dimensions), collapsed element FAIL (T3), element overlap FAIL (T2), tiny text FAIL (T1); SKIP path when Playwright binary is absent (VF30–VF35). Replaces the retired `test-validate-diagrams.sh`. **Needs `node` + Playwright.** |
| `test-assemble-determinism.sh` | `canonical/scripts/summarize/assemble.sh` determinism (Change 6 / FR-50): byte-identical output for identical inputs (`--manifest` required), different manifests produce different outputs, blank/comment lines ignored, missing section non-zero, NM guardrail — no Mermaid engine in assembled output. |
| `test-payload-size.sh` | Payload-size regression + no-Mermaid-engine assertions (Change 7 / FR-51): assembled `kb.html` < 1 MB ceiling (vs old ~3.4 MB Mermaid baseline); NM.1 no large inline bundle, NM.2 no `mermaid.initialize()`, NM.3 no CDN `<script src>`; S2 self-containment check passes. |
| `test-guardrails-d012.sh` | D-012 guardrail re-checks: C1 output path `.aid/dashboard/kb.html`, C2/C3 no CDN / split asset, NM no-Mermaid-engine assertion present, C5/C6 knowledge-summary status + completeness shapes, §5b/S5b section-5b properties. Asserts static source properties of canonical files — no runtime or Node needed. |
| `test-contrast-check.sh` | `canonical/scripts/summarize/contrast-check.mjs` (Node) WCAG AA contrast: usage exit 2, missing-file non-zero, hex-6/hex-3/`rgb()` parse paths, low-contrast fail, unresolvable-vars skipped-not-failed, dark-theme override extraction, and an integration check that the shipped `knowledge-summary.html` passes. **Needs `node`.** |
| `test-install.sh` | `install.sh` + `lib/aid-install-core.sh` installer: usage/error exits (unknown flag → 2, mutually-exclusive flags → 2, missing target → 2); fresh install per tool (claude-code/.claude+CLAUDE.md, codex/.codex+.agents+AGENTS.md, cursor/.cursor+AGENTS.md, copilot-cli/.github+AGENTS.md, antigravity/.agent+AGENTS.md); byte-fidelity of installed files vs `profiles/<tool>/` sources; idempotent re-install (“Up to date”); `--force` overwrites a locally-edited file; manifest correctness (paths + version + root_agent sha256 + status); uninstall exactness (removes manifested paths, manifest + .aid/ pruned on last tool); in-place root-agent update (pre-placed user AGENTS.md → AID region written between `AID:BEGIN/END`, user content preserved, no `.aid-new` sidecar, exit 0); uninstall safety (modified AID-owned AGENTS.md left in place); comma-list `--tool codex,cursor` (both tools update their region in the shared AGENTS.md in place); auto-detect (single marker→used, two→exit 2, none→exit 2); `--update` mode; `--help`/`-h`; `--from-bundle` with directory; multi-tool install without AGENTS.md collision; partial uninstall (one tool preserved); manifest contains only relative POSIX paths. All paths driven via `--from-bundle` with locally-built fixture tarballs — no network. |
| `test-assemble-3part.sh` | `canonical/scripts/summarize/assemble-3part.sh` byte-concat of PART1+MERMAID+PART2 → OUTPUT: arg/input validation (missing/empty input → exit 1), auto-created nested output dir, byte-exact concatenation + ordering. |
| `test-assemble-3part-ps1.sh` | `canonical/scripts/summarize/assemble-3part.ps1` (PowerShell mirror) — same contract as the `.sh` oracle, run under `pwsh`. Cross-platform (explicit paths + byte I/O), so it runs fully on the Linux CI runner. **Needs `pwsh`.** |
| `test-install-ps1.sh` | `install.ps1` + `lib/AidInstallCore.psm1` (PowerShell installer mirror) — FR9 parity suite asserting the same message strings and exit codes as `test-install.sh` for all platform-independent paths: arg/precondition errors (mutually-exclusive flags → 2, missing target → 2, unknown parameter → 1), fresh install per tool (all 5; .claude/.codex/.agents/.cursor/.github/.agent + root agent file), byte-fidelity vs `profiles/<tool>/` sources, idempotent re-install (`Up to date:`), `-Force` overwrite, manifest correctness (paths + aid_version + sha256 + status), uninstall exactness (`Removed:` / `Uninstall complete.`), in-place root-agent update (pre-placed file → AID region written between `AID:BEGIN/END`, user content preserved, no `.aid-new` sidecar, exit 0), uninstall safety (modified AID-owned file `Left in place`), auto-detect (single marker→used, two→exit 2, none→exit 2), `-Update` mode, `-Help`, `-FromBundle` with directory. Multi-tool comma-list cases excluded (PS1 strict-mode manifest property-lookup divergence). All driven via `-FromBundle` with locally-built fixture tarballs — no network. Replaces the removed `test-setup-ps1.sh`. **Needs `pwsh`.** |

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
