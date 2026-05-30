---
kb-category: primary
source: hand-authored
intent: |
  Inventory of test suites that protect the canonical helper scripts AID skills
  depend on. 13 unit/integration suites under tests/canonical/, discovered by
  glob and run by the tests/run-all.sh aggregator. Most are pure bash (POSIX);
  two shell out to node (.mjs validators) and two to pwsh (PowerShell mirrors),
  each skipping if its runtime is absent. All suites source the shared
  tests/lib/assert.sh assertion library. NO methodology/orchestration/E2E tests —
  those don't exist and aren't needed (the methodology is exercised by
  dogfooding, the renderer has its own VERIFY (deterministic) gate). Read this to
  understand what changes to canonical/scripts/ are guarded by tests vs require
  manual verification.
contracts:
  - "13 test suites under tests/canonical/, no skill-level tests"
  - "tests/run-all.sh is the single aggregator (glob-discovers tests/canonical/test-*.sh)"
  - "All suites source tests/lib/assert.sh (shared counters + asserts + test_summary)"
  - "Most suites are pure bash (POSIX, Git Bash on Windows); 2 need node, 2 need pwsh — each skips if absent"
changelog:
  - 2026-05-30: Substantive refresh to current truth — 7→13 suites; documented the tests/run-all.sh aggregator (replaces the old "no aggregator, per-suite loop" claim) and tests/lib/assert.sh shared library; inverted the gaps section (the .mjs validators, PowerShell mirrors, and setup install flow are now COVERED, not gaps); recorded the node/pwsh-skip model; applied script renames (writeback-task-status→writeback-state, concatenate→assemble-3part, build-index→build-kb-index, harness.py→render_lib.py, VERIFY-4a/4b→VERIFY (deterministic)/(advisory)); converted bare line-number citations to durable anchors. Dropped invented per-suite assertion numbers in favor of qualitative coverage (suites now share one summary format and the README does not commit to counts).
  - 2026-05-29: Corrected count 5→7 suites / 235→273 assertions — added the fetch-mermaid.sh and grade.sh sections (both existed on disk but were missing from this inventory); fixed validate-diagrams.mjs line count 574→577
  - 2026-05-27: Initial generation by discovery-quality (cycle-1)
  - 2026-05-27: Full rewrite during cycle-2 FIX Phase B for accurate post-Q6-cleanup state (Q20)
---
# Test Landscape

## Scope

These tests cover the **canonical helper scripts** only — the small utilities that
AID skills invoke at runtime (writeback, BFS compute, recipe parsing, severity
grading, diagram/contrast validation, 3-part assembly, the end-user installer, etc.).
Most are pure bash; a few shell out to `node` or `pwsh` to exercise the `.mjs`
validators and the PowerShell mirror scripts.

What is NOT tested here:
- **Orchestration skills** (`/aid-discover`, `/aid-execute`, …) — prompt-driven; no
  scripted harness exists or is planned. The `discovery-reviewer` sub-agent acts as the
  closest adversarial integration check each cycle.
- **Renderer** (`run_generator.py`) — covered by its own VERIFY (deterministic)
  determinism gate (`verify_deterministic.py`); see `architecture.md`.
- **Sub-agent definitions** — no test harness; verified by dogfooding. See
  `canonical/agents/*/AGENT.md`.
- **Cross-tool consistency** (Cursor vs Claude Code vs Codex) — covered by the renderer's
  byte-identity assertion across the 3 install-tree profiles.
- **E2E pipeline** (Discover → … → Deploy → Monitor) — exercised by dogfooding this repo,
  not scripted tests.

---

## How the suites run

### Aggregator — `tests/run-all.sh`

`tests/run-all.sh` is **the** single "run all tests" entrypoint, shared by CI
(`.github/workflows/test.yml`, the `canonical-tests` job) and local development —
a contributor runs the exact same gate locally before pushing. It:

- **Glob-discovers** suites: `tests/canonical/test-*.sh`. Adding a suite needs no
  edit to the runner (find the glob at the `shopt -s nullglob` line in `run-all.sh`).
- Runs each suite **under `timeout 300`** in its own isolated `bash` process.
- `chmod +x`'s the helper + test scripts first (the repo is authored on Windows,
  committed `100644`; several suites invoke their SUT directly and need the exec bit
  on Linux). Idempotent.
- Aggregates results and **exits non-zero if any suite fails** (or if no suites are
  found). Under GitHub Actions it emits `::group::` folding and `::error::`
  annotations (gated on `GITHUB_ACTIONS`).

```bash
bash tests/run-all.sh        # run every suite, aggregate PASS/FAIL
bash tests/run-all.sh -v     # verbose — passes --verbose through to each suite
```

> **Historical note:** earlier cycles had *no* aggregator (a Q6 cycle-1 decision),
> and this doc previously told you to loop `for f in tests/canonical/*.sh; do …; done`
> by hand. That is obsolete — `run-all.sh` is the aggregator now (closed under M4).

### Shared assertion library — `tests/lib/assert.sh`

Every suite **sources** `tests/lib/assert.sh` (find each at its
`source ".../lib/assert.sh"` line). The library provides:

- **Shared counters:** `PASS`, `FAIL`, `ERRORS[]` (initialized in the lib).
- **Logging / outcomes:** `log` (VERBOSE-only), `pass "<name>"` (counts; printed only
  when `VERBOSE=1`), `fail "<name> — why"` (counts; **always** printed; recorded in
  `ERRORS`).
- **Assertion helpers:** `assert_eq`, `assert_output_contains`,
  `assert_output_not_contains`, `assert_file_contains`, `assert_file_not_contains`,
  `assert_file_exists`, `assert_dir_exists`, `assert_exit_zero`, `assert_exit_nonzero`,
  `assert_exit_eq`, `assert_line_exact`, `assert_line_count`.
- **`test_summary`** — prints `Tests passed: N` / `Tests failed: M`, lists failures,
  and returns `1` if any assertion failed. Every suite ends by calling it, so all
  suites share one uniform summary format (closed under M6 — before it, each suite
  carried its own `PASS=0`/`FAIL=0` scaffold and printed in its own format).

### Runtime skips (node / pwsh)

Most suites are pure bash. Four shell out to another runtime via a thin bash wrapper
that **skips (exit 0 with a `SKIP:` notice) if its runtime is absent**, so a host
missing one still runs the rest:

- **`node`** — `test-validate-diagrams.sh`, `test-contrast-check.sh` (the two `.mjs`
  validators).
- **`pwsh`** — `test-assemble-3part-ps1.sh`, `test-setup-ps1.sh` (the PowerShell
  mirrors).

CI does **not** tolerate a silent skip: the `canonical-tests` job pins `node` (v20)
and asserts both `node` and `pwsh` are present before running, failing loudly if
either is missing so the node/PowerShell coverage can never be silently bypassed.

---

## Suites (13)

All suites live under `tests/canonical/` and target scripts under `canonical/scripts/`
(or the top-level `setup.*` installers). Coverage is described qualitatively — suites
share one `test_summary` format and the suite inventory in `tests/README.md` does not
commit to per-suite assertion counts.

### test-read-setting.sh

**Target:** `canonical/scripts/config/read-setting.sh`

Covers the three-tier settings-resolution model: per-skill override > global category
default > hardcoded `--default`; `--path` mode for direct dotted-key lookups; missing
`settings.yml` with and without `--default`; comment/quote stripping; and error exits
(bad `--path` format, unknown flag, missing paired args).

### test-writeback-state.sh

**Target:** `canonical/scripts/execute/writeback-state.sh`
(renamed from the former `writeback-task-status.sh`)

Covers all 4 argument modes plus lock-contention safety under concurrent writers:
`--task-id --field --value` (single-field row update), `--task-id --findings` (Quick
Check block write), `--delivery-id --block` (Delivery Gate block write), and
`--delivery-id --append-issue` (`delivery-NNN-issues.md` append); idempotency of each
mode; concurrent lock contention (parallel writers on different rows); and error paths
(missing args, invalid task-id, lock timeout, missing lock dir).

### test-parse-recipe.sh

**Target:** `canonical/scripts/interview/parse-recipe.sh`

Covers all operating modes (`--list`, `--validate`, `--spec`, `--tasks`, `--render`)
plus slot substitution, `{!{` escape rewrite, unmatched-slot passthrough, multi-task
recipe emission, lock-file lifecycle, name-vs-filename mismatch warning, and error
paths (missing file, malformed front-matter, missing blocks, bad args). Also validates
each of the seed recipes in `canonical/recipes/` (dogfood). **Runtime note:** this is
the largest/slowest suite (~150 s); `run-all.sh`'s `timeout 300` covers it — do not
impose timeouts under 180 s when running it standalone.

### test-compute-block-radius.sh

**Target:** `canonical/scripts/execute/compute-block-radius.sh`

Covers the BFS transitive-descendant computation used by the pool-dispatch failure
cascade: linear chains, diamonds, fan-outs, unrelated chains, mid-chain failure,
leaf-node (empty block-radius), multi-root fan graphs, end-to-end `--plan-file`
(PLAN.md parsing), a seeded-failure delivery-graph integration, error exits
(missing/conflicting args, file-not-found), whitespace normalization on
`--failed-task`, and the `state-execute.md` degradation-notice format.

### test-delivery-gate-aggregate.sh

**Target:** the delivery-gate logic in `canonical/scripts/execute/aid-execute`
(uses `writeback-state.sh` and `canonical/scripts/grade.sh` as collaborators)

Covers: AGGREGATE with an existing `delivery-NNN-issues.md` (deferred rows preserved);
AGGREGATE with no issues file (creates the empty log correctly); SCORE computation for
sample deliveries of varying complexity; grade computation via `grade.sh`
(deterministic output verification); the loopback guard (grade < min does not re-run
quick-checks; only loops review); and the FR6 interlock (the gate must not fire while
any task has status Failed or Blocked).

### test-fetch-mermaid.sh

**Target:** `canonical/scripts/summarize/fetch-mermaid.sh`

Covers the supply-chain pin + SHA-verification:
- **Scenario A** — tampered cache-hit rejection (a corrupted cached blob fails the SHA check).
- **Scenario B** — post-download bad-blob rejection via a `curl` PATH-shim returning a tampered payload.
- **Scenario C** — valid-cache fast path: no HTTP call is made when the cache is present and valid.
- **Scenario D** — `compute_sha256` unknown-fallback fails closed when neither `sha256sum` nor `shasum` is on PATH.

### test-grade.sh

**Target:** `canonical/scripts/grade.sh` (the top-level scorer — **unchanged** name)

Regression suite for the column-anchored severity-tag → letter-grade scorer: each
severity band maps to the correct letter + count modifier; only a Severity-column
`[TAG]` in a `Pending`/`Recurred` row counts (tags in Description/Evidence cells and
prose Summary lines are ignored — the cycle-7 false-positive guard); `--non-functional`
forces F; empty / zero-finding ledger → A+; and the deprecated `--from-prose` path still
parses (with fenced / inline-code stripping).

### test-validate-diagrams.sh

**Target:** `canonical/scripts/summarize/validate-diagrams.mjs` (Node). **Needs `node`.**

Covers the D1 regex sanity + invocation paths via `--fast`: no-args / `--help` /
missing-file → exit 2, zero-diagram warn-pass, valid `<pre>`/`<div>` diagrams, and D1
failures (directive-only, unrecognized type, empty block, mixed). D2 render is not
hermetic (needs jsdom/mermaid-cli) and is out of scope.

### test-contrast-check.sh

**Target:** `canonical/scripts/summarize/contrast-check.mjs` (Node). **Needs `node`.**

Covers WCAG AA contrast: usage exit 2, missing-file non-zero, hex-6 / hex-3 / `rgb()`
parse paths, low-contrast fail, unresolvable-vars skipped-not-failed, dark-theme
override extraction, and an integration check that the shipped `knowledge-summary.html`
passes.

### test-setup.sh

**Target:** `setup.sh` (the end-user installer)

Covers the installer's arg/precondition errors, interactive menu logic (Done / toggle /
invalid), per-tool installs (Claude Code / Codex / Cursor), multi-tool install,
idempotent re-install ("Up to date"), and `--force` overwrite. The menu is driven via
piped stdin; only the fresh / identical / `--force` paths are exercised (never the
`/dev/tty` prompt).

### test-assemble-3part.sh

**Target:** `canonical/scripts/summarize/assemble-3part.sh`
(renamed from the former `concatenate.sh`)

Covers byte-concat of PART1 + MERMAID + PART2 → OUTPUT: arg/input validation
(missing/empty input → exit 1), auto-created nested output dir, and byte-exact
concatenation + ordering.

### test-assemble-3part-ps1.sh

**Target:** `canonical/scripts/summarize/assemble-3part.ps1` (PowerShell mirror).
**Needs `pwsh`.**

Same contract as the `.sh` oracle, run under `pwsh`. Cross-platform (explicit paths +
byte I/O), so it runs fully on the Linux CI runner once `pwsh` is present.

### test-setup-ps1.sh

**Target:** `setup.ps1` (the Windows-host installer). **Needs `pwsh`.**

Only its platform-independent pre-install logic is exercised under `pwsh` on Linux:
target validation + the selection-menu loop. The backslash-path file copy is
Windows-only; the actual install coverage lives in `test-setup.sh`.

---

## Running

```bash
# Run every suite via the aggregator (from repo root; Git Bash on Windows)
bash tests/run-all.sh
bash tests/run-all.sh -v          # verbose — passes --verbose through to each suite

# Run one suite directly
bash tests/canonical/test-read-setting.sh
bash tests/canonical/test-read-setting.sh --verbose
```

**Windows note:** all suites are POSIX bash — run them from Git Bash, not PowerShell or
CMD. (The `*-ps1.sh` suites are themselves bash wrappers that *invoke* `pwsh`; they are
not run by PowerShell directly.)

Exit code: `0` = every suite passed, `1` = one or more failures (or no suites found).
Each suite prints a `FAIL:` line per failed assertion and the shared `test_summary`
(`Tests passed: N` / `Tests failed: M`) at the end.

CI is enforced: `.github/workflows/test.yml`'s `canonical-tests` job runs
`bash tests/run-all.sh` on every PR/push to `master` and is a required status check —
a PR cannot merge unless it is green. The same job pins `node` v20, pre-seeds the
SHA-verified Mermaid pin via `fetch-mermaid.sh`, and asserts both `node` and `pwsh`
are present so the node/PowerShell suites cannot silently skip.

---

## Coverage gaps and roadmap

The earlier inversion in this doc — which listed the PowerShell mirrors, the `.mjs`
validators, and the `setup.*` install flow as *untested* — is **wrong and now fixed**.
Those are all covered (closed under L2): `test-setup.sh`, `test-setup-ps1.sh`,
`test-validate-diagrams.sh`, `test-contrast-check.sh`, `test-assemble-3part.sh`,
`test-assemble-3part-ps1.sh`. The genuinely untested surface is the prompt-driven /
orchestration layer:

- **Orchestration skills** (`/aid-discover`, `/aid-execute`, …) — prompt-driven and hard
  to test without an AI host. The `discovery-reviewer` sub-agent is the closest thing to
  integration verification, adversarially grading KB output each cycle.
- **The renderer** (`run_generator.py`) — its own VERIFY (deterministic) check runs at
  the end of every render and exits 1 on failure; not part of `tests/canonical/`.
- **Sub-agent definitions** — see `canonical/agents/*/AGENT.md`; verified by dogfooding.
- **Cross-tool consistency** (Cursor vs Claude Code vs Codex) — covered by the renderer's
  byte-identity assertion across the 3 profiles, not by a suite here.
- **End-to-end pipeline behavior** (Discover → Interview → Specify → Plan → Detail →
  Execute → Deploy → Monitor) — exercised by dogfooding (this repo IS the test suite for
  the methodology) rather than scripted E2E tests.
- **No coverage measurement** — statement/branch coverage of the canonical helpers is
  unknown.
- **bats migration** — the suites use the shared `assert.sh` counter pattern (not TAP).
  Migration to `bats-core` would enable parallel runs and standard TAP integration;
  deferred as low-priority.

---

## Adding a new suite

1. Create `tests/canonical/test-<helper-name>.sh` targeting `canonical/scripts/<path>/<helper>`.
   The `test-` prefix matters — `run-all.sh` discovers suites by the `tests/canonical/test-*.sh`
   glob, so a correctly-named suite is picked up with **no runner edit**.
2. `source` `tests/lib/assert.sh` (set `VERBOSE` first) and use its `pass`/`fail`/`assert_*`
   helpers; end with `test_summary` so the suite returns the right exit code.
3. Use `set -uo pipefail` (not `set -e`) so all failures are reported in one run.
4. Use `mktemp -d` + `trap 'rm -rf …' EXIT` for fixture cleanup.
5. If the suite shells out to `node` or `pwsh`, skip (exit 0 with a `SKIP:` notice) when
   the runtime is absent, mirroring the existing `.mjs` / `*-ps1.sh` suites.
6. Add the suite to the table in `tests/README.md`.
