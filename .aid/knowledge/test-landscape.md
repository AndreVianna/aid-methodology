---
kb-category: primary
source: hand-authored
objective: AID test suite landscape: 56 canonical suites plus native-Windows suite, aggregated by run-all.sh, covering canonical scripts and the aid CLI installer/release surface.
summary: Inventory of all test suites that protect the canonical helper scripts and aid CLI installer/release surface, covering the 56 suites under tests/canonical/ plus the native-Windows Test-AidInstaller.ps1 and explaining what is guarded vs requires manual verification.
tags: [test-suites, run-all, canonical-tests, windows-installer-tests, ci-gates, assert-lib]
audience: [developer, maintainer, reviewer]
see_also: [infrastructure.md, tech-debt.md, coding-standards.md]
sources:
  - tests/canonical/
  - tests/run-all.sh
  - tests/lib/assert.sh
  - tests/windows/Test-AidInstaller.ps1
  - .github/workflows/test.yml
  - .github/workflows/installer-tests.yml
  - canonical/aid/scripts/
approved_at_commit: ccb4e823
contracts:
  - "currently 56 test suites under tests/canonical/ (glob-discovered; recount with ls tests/canonical/test-*.sh | wc -l) + tests/windows/Test-AidInstaller.ps1 (native Windows, now run under both pwsh 7 and Windows PowerShell 5.1 on installer-tests.yml), no skill-level tests"
  - "tests/run-all.sh is the single aggregator (glob-discovers tests/canonical/test-*.sh)"
  - "All suites source tests/lib/assert.sh (shared counters + asserts + test_summary)"
  - "Most suites are pure bash (POSIX, Git Bash on Windows); 2 need node, several need pwsh (the *-ps1.sh mirrors + the install.ps1 / aid.ps1 CLI suites) — each skips if absent; CI installer-tests.yml runs the native-Windows path"
changelog:
  - 2026-06-23: Migrated by migrate-kb-frontmatter.sh: intent retired, objective/summary/sources added
  - 2026-06-22: housekeep KB-DELTA (Q30) — suite count 49->56 (verified `ls tests/canonical/test-*.sh | wc -l` = 56 on disk). Documented test-multitool-isolation.sh (structural multi-tool isolation acceptance, feature-004 AC4) and test-ps51-compat.sh (AST-based WinPS 5.1 compatibility lint). Added the new real Windows PowerShell 5.1 CI lane in installer-tests.yml (re-runs Test-AidInstaller.ps1 under `shell: powershell`, complementing the ps51-compat static lint). Refreshed the generator self-test references for work-005-profile-generator-simplify: the per-format emitter self-tests test_copilot_emitter.py / test_antigravity_emitter.py were DELETED with the per-type renderers; coverage is now render.py --self-test (8 copy-core tests) + test_manifest_safety.py. Kept qualitative — no per-suite assertion counts (§9a).
  - 2026-06-14: housekeep KB-DELTA — VERSION 1.0.0—1.1.0 era; suite count 35→49 (verified `ls tests/canonical/test-*.sh | wc -l` = 49 on disk). Documented the 14 suites that landed across delivery-007/008/010/011 but were missing from this inventory: the dashboard surface (`test-dashboard-parity.sh`, `test-dashboard-parity-h.sh`, `test-dashboard-reader.sh`, `test-aid-dashboard-cli.sh`, `test-aid-remote.sh`, `test-producer-completeness.sh`, `test-pipeline-status-walkthrough.sh`, `test-work-state-template.sh`, `test-summarize-preflight.sh`, `test-registry.sh`, `test-home-html-source-sync.sh`), and the 1.0.0→1.1.0 migration surface (`test-aid-migrate.sh`, `test-aid-migrate-trigger.sh`, `test-release-migrate-smoke.sh`). Kept qualitative — no per-suite assertion counts (§9a).
  - 2026-06-05: work-002-auto-installer — the former `setup.sh`/`setup.ps1` installers were removed and replaced by the persistent `aid` CLI; deleted the `test-setup.sh` / `test-setup-ps1.sh` suite docs and added the real installer/CLI/release suites: `test-install.sh`, `test-install-ps1.sh`, `test-install-parity.sh`, `test-aid-cli.sh`, `test-aid-cli-ps1.sh`, `test-aid-cli-parity.sh`, `test-release.sh`, `test-release-install-e2e.sh`, `test-version-sync.sh`, `test-ascii-only.sh`, `test-agents-md-invariant.sh`, `test-npm-installer.sh`, `test-pypi-installer.sh`, plus the native-Windows `tests/windows/Test-AidInstaller.ps1`. Suite count 24→35 (verified `ls tests/canonical/test-*.sh | wc -l` = 35 on disk). Added the new `.github/workflows/installer-tests.yml` cross-platform runner to the CI notes; documented that the installer/CLI/release suites run on `installer-tests.yml` (cross-platform) in addition to the `test.yml` `canonical-tests` aggregator.
  - 2026-06-03: housekeep KB-delta (Q29) — work-001 (PR #56) expanded the recipe catalog 5→51 and migrated/renamed the old seed recipes; updated the test-parse-recipe.sh description so the dogfood note reflects the migrated catalog (validates the migrated seed basenames fix-application/add-docs/change-member/add-api-endpoint/add-test-coverage as representatives, per the suite's Units 15–19) rather than implying the old 5-recipe seed set. Kept qualitative — no per-suite assertion count added (§9a).
  - 2026-06-03: housekeep run-state relocation (PR #51) — updated the test-housekeep-state.sh + test-housekeep-workfolder-safety.sh descriptions: run-state now in `.aid/.temp/HOUSEKEEP_STATE_<ts>.md` (absent-file tolerance covered); the work-folder matrix is now informational (every folder offered, user-confirmed; only the current-branch folder hard-skipped — old signals (a)/(c) removed).
  - 2026-06-03: post-merge work-001-aid-housekeep (PR #49) + work-002 canonical bug-fix suites — suite count 18→24 (verified `ls tests/canonical/test-*.sh | wc -l` = 24 on disk). Documented the 5 new housekeep suites (test-housekeep-state.sh, test-housekeep-branch-commit.sh, test-housekeep-classify.sh, test-housekeep-workfolder-safety.sh, test-housekeep-deletion-split.sh) added by the /aid-housekeep skill, which guard the canonical/scripts/housekeep/ helpers (housekeep-state.sh, branch-commit.sh, cleanup-classify.sh). Also documented test-complexity-score.sh (work-002 task-001 four-fix regression suite for canonical/scripts/execute/complexity-score.sh) which was on disk but missing from this inventory. Done via /aid-housekeep targeted re-discovery.
  - 2026-06-01: post-merge work-001-add-providers (PRs #42/#43/#44) — byte-identity assertion 3→5 install-tree profiles (added GitHub Copilot CLI + Antigravity); documented new setup cases (test-setup.sh SU12-17/SU16b; test-setup-ps1.sh SPS05-08, which SKIPs without pwsh per established contract); documented the 2 new generator self-tests (test_copilot_emitter.py, test_antigravity_emitter.py) wired into the CI generator-selftests step. Canonical suite count unchanged at 18 (verified `ls tests/canonical/test-*.sh | wc -l` = 18 on disk — the new setup cases are SU/SPS additions inside the existing test-setup.sh / test-setup-ps1.sh suites, not new suite files).
  - 2026-05-31: delivery-002 — added 3 F4 doc-set suites (test-doc-set-read.sh, test-doc-set-mapping.sh, test-doc-set-propose-confirm.sh); updated suite count 15→18
  - 2026-05-31: delivery-001 — added test-discovery-doc-ownership.sh and test-expectations-single-source.sh; updated suite count 13→15 (stated as "currently N", not a hardcoded invariant); updated Suites section header accordingly.
  - 2026-05-30: Substantive refresh to current truth — 7→13 suites; documented the tests/run-all.sh aggregator (replaces the old "no aggregator, per-suite loop" claim) and tests/lib/assert.sh shared library; inverted the gaps section (the .mjs validators, PowerShell mirrors, and setup install flow are now COVERED, not gaps); recorded the node/pwsh-skip model; applied script renames (writeback-task-status→writeback-state, concatenate→assemble-3part, build-index→build-kb-index, harness.py→render_lib.py, VERIFY-4a/4b→VERIFY (deterministic)/(advisory)); converted bare line-number citations to durable anchors. Dropped invented per-suite assertion numbers in favor of qualitative coverage (suites now share one summary format and the README does not commit to counts).
  - 2026-05-29: Corrected count 5→7 suites / 235→273 assertions — added the fetch-mermaid.sh and grade.sh sections (both existed on disk but were missing from this inventory); fixed validate-diagrams.mjs line count 574→577
  - 2026-05-27: Initial generation by aid-researcher (quality doc-set) (cycle-1)
  - 2026-05-27: Full rewrite during cycle-2 FIX Phase B for accurate post-Q6-cleanup state (Q20)
---
# Test Landscape

## Scope

These tests cover the **canonical helper scripts** only — the small utilities that
AID skills invoke at runtime (writeback, BFS compute, recipe parsing, severity
grading, diagram/contrast validation, 3-part assembly, the `aid` CLI installer +
release tooling, the /aid-housekeep helpers, etc.).
Most are pure bash; a few shell out to `node` or `pwsh` to exercise the `.mjs`
validators and the PowerShell side of the installer (`install.ps1` / `bin/aid.ps1` /
the `*-ps1.sh` mirrors). The native-Windows path is exercised by
`tests/windows/Test-AidInstaller.ps1` on the `installer-tests.yml` Windows runner.

What is NOT tested here:
- **Orchestration skills** (`/aid-discover`, `/aid-execute`, …) — prompt-driven; no
  scripted harness exists or is planned. `aid-reviewer` dispatched from `/aid-discover`
  acts as the closest adversarial integration check each cycle.
- **Generator** (`run_generator.py`) — covered by its own VERIFY (deterministic)
  determinism gate (`verify_deterministic.py`); see `architecture.md`. The generator also
  has **self-tests** (Python, NOT under `tests/canonical/`) wired into the CI
  `generator-selftests` job (`.github/workflows/test.yml`, the `--self-test` invocations):
  `render.py --self-test` (8 in-process copy-core tests — verbatim byte-identity, two-run
  determinism per translate mode, tool_names remap) and `test_manifest_safety.py`
  (pure-mirror deletion safety). Both under `.claude/skills/generate-profile/scripts/`.
  (The former per-format emitter self-tests `test_copilot_emitter.py` /
  `test_antigravity_emitter.py` were deleted with the per-type renderers in
  work-005-profile-generator-simplify — see `module-map.md §3`.)
- **Sub-agent definitions** — no test harness; verified by dogfooding. See
  `canonical/agents/*/AGENT.md`.
- **Cross-tool consistency** (Claude Code vs Codex vs Cursor vs Copilot CLI vs Antigravity) —
  covered by the renderer's byte-identity assertion across the 5 install-tree profiles.
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

### Runtime skips (node / python3 / pwsh)

Most suites are pure bash, but a substantial minority shell out to an **external
runtime** and carry a runtime-presence guard so a host missing that runtime SKIPs
(exit 0 with a `SKIP:` notice — whole-suite or per-block) rather than failing, and
still runs the rest.

**Counting rule:** a suite "depends on runtime R" here if its source contains an
explicit `command -v R` presence guard (the gate that drives the SKIP). Reproduce
the per-runtime counts with:

```bash
for rt in pwsh python3 node; do
  printf '%s: ' "$rt"; grep -lE "command -v $rt" tests/canonical/test-*.sh | wc -l
done
```

As of the 1.0.0—1.1.0 era this yields **7 `pwsh`, 12 `python3`, 6 `node`** (20 distinct
suites carry at least one such guard — `grep -lE "command -v (pwsh|python3|node)"
tests/canonical/test-*.sh | wc -l`; five of them guard two runtimes). The runtime
footprint grew sharply with the dashboard (deliveries 007/008) and migration
(deliveries 010/011) surfaces, which lean on `python3`/`node` server twins and the
per-channel installer toolchains. By category:

- **`node`** (6) — the two `.mjs` validators (`test-validate-diagrams.sh`,
  `test-contrast-check.sh`) plus the dashboard/Node-server twins and channel shims
  (`test-dashboard-parity.sh`, `test-dashboard-parity-h.sh`, `test-producer-completeness.sh`,
  `test-npm-installer.sh`).
- **`python3`** (12) — the dashboard Python reader/server twins
  (`test-dashboard-reader.sh`, `test-dashboard-parity.sh`, `test-dashboard-parity-h.sh`,
  `test-producer-completeness.sh`, `test-aid-dashboard-cli.sh`), the installer/release
  surface that uses python for render-drift / checksum / JSON paths (`test-install.sh`,
  `test-install-ps1.sh`, `test-release.sh`, `test-release-install-e2e.sh`,
  `test-version-sync.sh`, `test-pypi-installer.sh`), and the migration smoke
  (`test-release-migrate-smoke.sh`, which skips its PyPI leg without python).
- **`pwsh`** (7) — `test-assemble-3part-ps1.sh` (the assemble mirror), the installer/CLI
  PowerShell mirrors (`test-install-ps1.sh`, `test-aid-cli-ps1.sh`), the cross-platform
  parity suites that need BOTH bash and pwsh (`test-install-parity.sh`,
  `test-aid-cli-parity.sh`), the remote-exposure parity half (`test-aid-remote.sh`), and
  the release→install E2E (`test-release-install-e2e.sh`, whose `pwsh` legs skip when
  absent).

Two further nuances the `command -v` rule deliberately excludes: a few suites
*hard-invoke* a runtime with no skip guard (e.g. `test-aid-migrate-trigger.sh` runs
`node`/`python3` for its vendor-refresh and postinstall gates, and `test-aid-cli*.sh`
use `python3` heredocs to parse manifests) — these would FAIL, not skip, if the
runtime were missing; and one suite uses an *optional* `gh` guard
(`test-housekeep-workfolder-safety.sh` SKIPs the gh-PR-merge path when `gh` is absent
and otherwise exercises the offline `git merge-base --is-ancestor` ancestry fallback).

CI does **not** tolerate a silent skip: the `canonical-tests` job pins `node` (v20)
and asserts both `node` and `pwsh` are present before running, and the runner ships
`python3`, so the node/python/PowerShell coverage can never be silently bypassed.

---

## Suites (currently 56)

All suites live under `tests/canonical/` and target scripts under `canonical/scripts/`
(or the `aid` CLI installer/release surface — `bin/aid`, `lib/aid-install-core.sh`,
`lib/AidInstallCore.psm1`, `install.sh`/`install.ps1`, `release.sh` — or the canonical
agent/skill source files). The native-Windows installer test lives separately at
`tests/windows/Test-AidInstaller.ps1` (run by `installer-tests.yml`, not by `run-all.sh`).
Coverage is described qualitatively — suites share one `test_summary` format and the
suite inventory in `tests/README.md` does not commit to per-suite assertion counts.

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
paths (missing file, malformed front-matter, missing blocks, bad args). Also dogfoods
the shipped recipe catalog in `canonical/recipes/` — after **work-001 (PR #56)**
grew the catalog from 5 to ~51 recipes and migrated/renamed the old seed set, the
suite `--validate`s representative migrated recipes (`fix-application`, `add-docs`,
`change-member`, `add-api-endpoint`, `add-test-coverage` — the Units 15–19 fixtures)
and asserts each passes all checks. **Runtime note:** this is
the largest/slowest suite (~150 s); `run-all.sh`'s `timeout 300` covers it — do not
impose timeouts under 180 s when running it standalone.

### test-complexity-score.sh

**Target:** `canonical/scripts/execute/complexity-score.sh`

Regression suite added by **work-002 task-001** for the four correctness fixes in the
delivery-complexity scorer (find each via the `# A1`/`# A2`/`# A3`/`# A4` headers in
the suite):
- **A1 — Type matching:** both `**Type:**` (bold task-template form) and `- Type:`
  (flat recipe form) score risk.
- **A2 — portable awk:** extraction works under `mawk` (no gawk 3-arg `match`);
  leading-zero delivery-id matching is numeric (`003` == `3`).
- **A3 — lite/recipe specs:** a top-level `## Execution Graph` (no delivery wrapper)
  parses with `--delivery-id` not required and the `## Tasks` table not swallowed;
  a multi-delivery PLAN still scopes per delivery and requires `--delivery-id`.
- **A4 — cycle guard:** a cyclic / self-looping `Depends On` table terminates with
  exit 0; `— (none)` / `(none)` are treated as no-deps (lite-spec template form).

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

### test-install.sh

**Target:** `install.sh` + `lib/aid-install-core.sh` (the Bash installer core)

Drives `install.sh` against temp target directories using **locally-built fixture
tarballs** (`--from-bundle`), so no network calls run in CI. Covers per-tool install of
each of the 5 profiles (`.claude/` / `.codex/`+`.agents/` / `.cursor/` / `.github/` /
`.agent/`), tool auto-detection vs `--tool`, idempotent re-install ("up to date"),
`--force` overwrite, `--verbose` per-file lines (`Copied:` / `Updated:` / `Removed:`),
manifest write (`.aid/.aid-manifest.json`) + `.aid-version` marker, the flat-root tarball
contract assertion, checksum verification against `SHA256SUMS` (exit 4 on mismatch), and
the `lib` integrity-verify opt-out (`AID_INSECURE_SKIP_LIB_VERIFY`). Pure bash on the
Linux runner.

### test-install-ps1.sh

**Target:** `install.ps1` + `lib/AidInstallCore.psm1` (the PowerShell installer core).
**Needs `pwsh`.**

The PowerShell mirror of `test-install.sh`: same `--from-bundle` install/idempotency/
`--force`/manifest/checksum contract, driven through `install.ps1` under `pwsh`. **SKIPs
(exit 0 with a `SKIP:` notice) when `pwsh` is absent**; CI's installer matrix asserts
`pwsh` is present so the skip cannot silently fire there.

### test-install-parity.sh

**Target:** cross-platform parity between `install.sh` and `install.ps1`. **Needs `pwsh`.**

Installs the SAME fixture tarball through BOTH the bash and PowerShell installers into
separate temp targets and asserts the installed trees are **byte-identical** (`diff -r`)
and the two `.aid/.aid-manifest.json` files are identical modulo the `installed_at`
timestamps (same `manifest_version`, `aid_version`, tools, `paths`, `sha256`, `status`,
and key order). SKIPs without `pwsh`.

### test-aid-cli.sh

**Target:** the persistent Bash `aid` CLI — `bin/aid` dispatcher + `install.sh`
BOOTSTRAP/CONVENIENCE paths

Integration tests for the per-machine CLI: bootstrap + PATH wiring (all temp state under
`mktemp`, `AID_HOME` never touches the real `$HOME`), every subcommand
(`aid` bare dashboard / `status` / `add` / `update` / `remove` / `version`), CONVENIENCE
mode, LEGACY back-compat, and `remove self`. Profile files are temp; `AID_LIB_PATH` is
always set so no network calls occur.

### test-aid-cli-ps1.sh

**Target:** the PowerShell `aid` CLI — `bin/aid.ps1`. **Needs `pwsh`.**

PowerShell mirror of `test-aid-cli.sh` for the `bin/aid.ps1` dispatcher (subcommand
surface + bootstrap/PATH parity). SKIPs without `pwsh`.

### test-aid-cli-parity.sh

**Target:** cross-platform parity for the `aid` CLI (`bin/aid` vs `bin/aid.ps1`).
**Needs `pwsh`.**

Runs the same `add` / `remove` / `update` / `uninstall` subcommand sequence on both
dispatchers and asserts an identical project tree, manifest equivalence (same tool list,
paths, sha256/status) and identical `status` output + exit codes. SKIPs without `pwsh`.

### test-release.sh

**Target:** `release.sh` (the maintainer release packager)

Drives `release.sh --dry-run` hermetically (no network, no `gh`, no tag creation; uses a
local git clone per group so the real `profiles/` is untouched and the clean-worktree
precondition holds). Cases (find via the `RL01`..`RL07` headers): tarball naming, install
layout, flat-root tarball contract, `SHA256SUMS` format + checksum correctness, a
render-drift FAIL path, and a version-mismatch path.

### test-release-install-e2e.sh

**Target:** the full release→install loop (`release.sh` → tarballs+`SHA256SUMS` →
`install.sh`/`install.ps1` → `update` → `uninstall`). **Uses `pwsh` when available.**

End-to-end (delivery-001): packages the staged artifacts with `release.sh --dry-run`, then
installs them via `install.sh` (and `install.ps1` when `pwsh` is present), then exercises
`update` and `uninstall` — all against the staged artifacts with no pre-built fixtures and
no network.

### test-version-sync.sh

**Target:** the FR10 version-sync invariant — `VERSION` == `packages/npm/package.json`
== `packages/pypi/pyproject.toml` (== release tag)

Asserts the four version carriers agree (cases `VS02`/`VS03`/`VS06`): a `package.json`,
`pyproject.toml`, or `VERSION`-vs-`--expect` divergence fails (exit 1, naming the drifting
carrier). This is the same check the `release.yml` `gate` job runs on the tagged commit.

### test-ascii-only.sh

**Target:** the shipped CLI/installer scripts — `lib/aid-install-core.sh`,
`lib/AidInstallCore.psm1`, `bin/aid`, `bin/aid.ps1`, `bin/aid.cmd`, `install.sh`,
`install.ps1`, `packages/npm/bin/aid.js` (the `SHIPPED_SCRIPTS` array)

Guards the **ASCII-only shipped-script** standard: each listed script must contain only
ASCII bytes. Rationale (per the suite header) — Windows decodes a no-BOM UTF-8 script in
the ANSI codepage and mis-parses non-ASCII characters, whereas ASCII bytes decode
identically in every single-byte codepage. CI-guarded.

### test-agents-md-invariant.sh

**Target:** the four profile root `AGENTS.md` files (FR12 invariant)

Asserts the root `AGENTS.md` shipped by the four AGENTS.md-writing profiles (Codex,
Cursor, Copilot CLI, Antigravity) is **byte-identical** across all four — the guard that
lets the installer treat a second AGENTS.md-writing install as up-to-date rather than a
collision (replacing the former Option-A last-installed-wins handler).

### test-npm-installer.sh

**Target:** the npm channel — `packages/npm/bin/aid.js` (the `aid-installer` shim)

Tests the npm thin-shim: argv passthrough, exit-code relay, platform selection
(`bin/aid` on Unix / `bin/aid.ps1` on Windows), missing-runtime handling,
`AID_INSTALL_CHANNEL=npm` injection (so `aid update self` prints the npm-correct upgrade
hint), a pack/install smoke, and version parity with `VERSION`.

### test-pypi-installer.sh

**Target:** the PyPI channel — `packages/pypi/aid_installer/__main__.py` (the
`aid-installer` shim)

Tests the PyPI thin-shim: argv passthrough, exit-code relay, platform selection,
missing-runtime handling, `AID_INSTALL_CHANNEL=pypi` injection (pipx upgrade hint), a
pip/pipx smoke, and version parity with `VERSION`.

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

### tests/windows/Test-AidInstaller.ps1 (native Windows — NOT under tests/canonical/)

**Target:** `install.ps1` + `bin/aid.ps1` + `lib/AidInstallCore.psm1` on a **real Windows
host**. Run by `installer-tests.yml` (the `windows-latest` / `native-ps1` leg), NOT by
`run-all.sh`.

Self-contained PowerShell integration test (no Pester; its own `Assert` / `Assert-Match` /
`Assert-FileLF` helpers; runs under `pwsh` or Windows PowerShell 5.1). Covers the path the
Linux bash harness cannot reach (find via the `T01`..`T07`+ headers): per-project install
via `install.ps1 -Tool -FromBundle -TargetDirectory`; install tree + `manifest`/`version`
files present; the manifest and `.aid-version` are **LF-only with no UTF-8 BOM**
(byte-level assertion — the Windows-encoding hazard the ASCII-only guard also protects);
manifest JSON parses and contains the tool with `"status":"owned"`; idempotent re-install;
and `aid status` via the installed `bin/aid.ps1`. The Windows leg of `installer-tests.yml`
additionally smokes the npm + PyPI Windows channels (pack/build → global install →
`aid status`/`aid add`).

### test-housekeep-state.sh

**Target:** `canonical/scripts/housekeep/housekeep-state.sh`

Added by the **/aid-housekeep** skill. Covers the run-state I/O round-trip and the
`--resume` decision rule against the `## Housekeep Status` section of a run-state
fixture (the project-level `.aid/.temp/HOUSEKEEP_STATE_<ts>.md` file; find the scenarios
via the `Unit 1:`–`Unit 20:` header block in the suite) — including absent-file
tolerance (read→empty/exit 0; write creates the file):
`--read` on a file with no section → empty/exit 0; `--write` creates the section + field
line and is idempotent (replace, no duplicate); independent fields co-exist; all nine
C-2 fields round-trip write→read; the six `--resume` rows (PREFLIGHT → CLEANUP →
KB-DELTA → SUMMARY-DELTA → CLEANUP → DONE) keyed on the KB/Summary/Cleanup stage
markers (stalled/running/`—`/passed/skipped); and error paths (missing `--state` →
exit 2, missing `--field` with `--read` → exit 2, missing `--value` with `--write` →
exit 2, STATE.md not found → exit 1).

### test-housekeep-branch-commit.sh

**Target:** `canonical/scripts/housekeep/branch-commit.sh`

Added by the **/aid-housekeep** skill. Exercises the branch-ensure + per-stage commit
helper against a throwaway git-repo fixture (`mktemp`, cleaned on exit), asserting the
**git safety guard** (find the scenarios via the `Unit 1:`–`Unit 9:` header block):
`--ensure-branch` on `master` creates an `aid/housekeep-<slug>` branch; re-running on an
existing `aid/housekeep-*` branch reuses it (resume); a non-master / non-housekeep
branch is **refused (exit 3)**; `--commit` on an `aid/housekeep-*` branch produces
exactly one commit; `--commit` on `master` without ensure-branch is **refused (exit 3)**;
the source file contains **no `git push`** (static assertion) and **no remote
interaction** occurs in any operation; combined `--ensure-branch` + `--commit` in one
invocation; and argument-validation errors (missing slug / message / etc.).

### test-housekeep-classify.sh

**Target:** `canonical/scripts/housekeep/cleanup-classify.sh`

Added by the **/aid-housekeep** skill. Verifies the scan + classify phase assigns
**cleanup tiers** correctly against a fixture `.aid/` tree (find the scenarios via the
`Unit 1:`–`Unit 13:` header block): S1 `.aid/.temp/**`, S2 `.aid/.heartbeat/**`,
S3 `.aid/knowledge/.cache/**` + `.manual-checklist.json` + `.spot-check-facts.txt`,
S4 stray `verify-deterministic-report.json` / `verify-advisory-report.json`, and S5
unregistered `.aid/generated/` output → **Tier-0 checked**; a registered `.aid/generated/`
output → **not emitted**; a loose hand-authored `.aid/` file → **Tier-2 unchecked**;
and protected/live files (`.aid/settings.yml`, `.aid/knowledge/*.md`) → **never emitted**;
empty `.aid/` → zero output lines.

### test-housekeep-workfolder-safety.sh

**Target:** `canonical/scripts/housekeep/cleanup-classify.sh` (work-folder safety rules)

Added by the **/aid-housekeep** skill. Tests the (i)/(ii) **work-folder safety decision
matrix** using throwaway git repos with a fake `origin/master` and `.aid/work-*/`
fixtures (find the scenarios via the `Unit 1:`–`Unit 10:` header block). Signal (i)
(merged-to-master) is exercised via the offline `git merge-base --is-ancestor` ancestry
fallback so the suite runs without network or `gh`; the gh-PR path is guarded by
`command -v gh` and SKIPs if absent. The (i)/(ii) signals are now **informational
context only** — they no longer gate whether a folder is offered. **Every** work folder
is offered (the user has the last word): (i)✓(ii)✓ → main checklist (gate=offer, default
unchecked); otherwise → gate=explicit-confirm (merged-but-not-concluded, or merge
unverified — unmerged SHA / no STATE.md / no PR-or-SHA). The single hard skip is the
work folder of the currently checked-out `aid/work-NNN-*` branch (signal (b)); the
`--active-work` caller exclusion is still honored. (Former exclusions (a) "carries
`## Housekeep Status`" and (c) "non-Deployed status" were removed.)

### test-housekeep-deletion-split.sh

**Target:** `canonical/scripts/housekeep/cleanup-classify.sh` (tracked/untracked split)

Added by the **/aid-housekeep** skill. Verifies the classify helper discriminates
**tracked vs untracked** paths via `git ls-files` / `git check-ignore` and re-asserts
the deletion-safety static guards (find the scenarios via the `Unit 1:`–`Unit 10:`
header block): a git-tracked path → `tracked`; a gitignored or uncommitted-and-not-ignored
path → `untracked`; a tracked-but-`.aid/.temp/` file → Tier-0 untracked (gitignore
precedence); the candidate `tracked` field matches the actual `git ls-files` result; a
`.aid/work-*/` directory is tracked when committed and untracked when not; and the script
source contains **no executable `rm`, `git rm`, `git commit`, or `git push`** calls
(deletion is the skill's job, not the classifier's).

### test-discovery-doc-ownership.sh

**Target:** `canonical/agents/aid-researcher/AGENT.md`,
`canonical/skills/aid-discover/references/state-generate.md`.

Regression guard for discovery doc-ownership consistency. Verifies that `aid-researcher`
(the consolidated researcher agent replacing the former 5 discovery-* sub-agents) covers
all standard KB docs, and that the dispatch table in `state-generate.md` routes every doc
to `aid-researcher`. 14 checks (T01–T14). (NOTE: these checks target the new roster — the
former per-agent ownership invariants for the pre-work-001 agents are
superseded by the roster consolidation in work-001-agents-review.)

### test-expectations-single-source.sh

**Target:** `canonical/skills/aid-discover/references/document-expectations.md`,
`canonical/agents/aid-reviewer/AGENT.md`, `canonical/skills/aid-discover/references/reviewer-prompt.md`,
`canonical/skills/aid-discover/references/state-review.md`, `canonical/skills/aid-discover/references/state-fix.md`.

Guards the single-source invariant for per-doc expectations: `document-expectations.md`
is the sole file with per-doc `### *.md` blocks; `aid-reviewer/AGENT.md` has zero
such blocks. Also guards reviewer-has-access invariant: the `{{DOCUMENT_EXPECTATIONS}}`
placeholder is present in `reviewer-prompt.md`, and `document-expectations.md` is named
in both `state-review.md` and `state-fix.md`. Verifies merge completeness (the file is
a superset containing `{reviewer_output_file}`, `project-structure.md`, and
`external-sources.md` blocks). 9 checks (T01–T09).

### test-doc-set-read.sh

**Target:** `canonical/skills/aid-discover/references/doc-set-resolve.md` (the
`resolve_doc_set` / `synth_default_seed` functions + all 4 accessors)

Covers the core doc-set resolve/accessor logic: unset `discovery.doc_set` → default seed
synthesized from templates; declared set → exact filename/owner/presence rows; all 4
accessors (`list-filenames`, `owner-of`, `owns-<agent>`, full TSV); inline `#` comment
stripping; comma-in-`when` shred behavior (fragment 1 survives as valid record; fragments
2+ with no pipe are warned and skipped); unknown owner → routes to `aid-researcher`
with a non-fatal warning; no `category` or `expectations` fields in any output; and the
dependency-free constraint (only bash+awk). 15 checks (T01–T15).

### test-doc-set-mapping.sh

**Target:** `canonical/skills/aid-discover/references/doc-set-resolve.md` + dispatch
mapping logic in `canonical/skills/aid-discover/references/state-generate.md`

Mechanical set-difference checks for the mapping-honors-declared-set invariant.
Covers: no-hang-on-omission (omitted doc excluded from owning agent's target list; declared
count lowers by 1); dispatch-on-addition (added doc in declared set → appears in owning
agent's list; count rises); carve-out-as-config (§1.4 fixture contains the renamed docs
`pipeline-contracts.md`, `schemas.md`, `repo-presentation.md` and excludes the old names
`api-contracts.md`, `data-model.md`, `ui-architecture.md`, `security-model.md`); and
non-software fixture (omission + custom addition vs default seed; user edits honored
verbatim). 15 checks (T01–T15).

### test-doc-set-propose-confirm.sh

**Target:** `canonical/skills/aid-discover/references/doc-set-resolve.md` +
`canonical/skills/aid-discover/references/state-generate.md` `### Step 0d`

Covers the propose→confirm flow behaviors per SPEC feature-004 §3.1 and §4:
default path (unset `discovery.doc_set` → resolved set equals default seed; accepting
default is a no-op — settings file remains without a `discovery.doc_set` section after
confirm); user-edit path (fixture with omission + addition → resolved set honors both
verbatim; count matches fixture entry count; omitted doc absent; added doc present).
Does not duplicate carve-out or non-software set-difference tests (those live in
`test-doc-set-mapping.sh`). 9 checks (T01–T09).

### test-dashboard-reader.sh

**Target:** the Python state reader under `dashboard/server/` (feature-002), run via
`python3 -m unittest`. **Needs `python3`.**

Wraps the reader's Python unittest module and maps its result into the canonical
pass/fail summary format. SKIPs (reports a single failure / non-run) when `python3`
is absent. Validates that the reader correctly parses a project's `.aid/` state into the
dashboard model.

### test-dashboard-parity.sh

**Target:** cross-runtime byte-parity of the Python (`dashboard/server/server.py`) and
Node (`dashboard/server/server.mjs`) dashboard servers (feature-003). **Uses `python3`
and `node`.**

Asserts both servers emit byte-identical `/r/<id>/api/model` responses for the same
`.aid/` snapshot (after stripping `generated_by` and normalizing `read.read_at`), using
checked-in fixtures (full Running/Paused/Blocked/Completed/Fallback state, and a no-`.aid/`
case). Includes the R7 invariant: a manifest carrying U+2028/U+2029 must be canonically
escaped by both servers. Each runtime half skips if absent; the parity check runs only
when both are present.

### test-dashboard-parity-h.sh

**Target:** the multi-repo server shape introduced by delivery-008 — `AID_HOME` +
`registry.yml`, `/api/home`, and `/r/<id>/{home.html,kb.html,api/model}` routes
(feature-010, PT-1-H). **Uses `python3` and `node`.**

Extends `test-dashboard-parity.sh`: asserts `GET /api/home` and `GET /r/<id>/api/model`
are byte-identical across both runtimes (including U+2028/U+2029 escaping and identical
`<id>` derivation), plus the SEC-2 traversal-refusal set (`../`, `%2e%2e`, absolute path,
escaping out of a repo root, unregistered/malformed `<id>` → identical 404 from both),
SEC-1 (no wildcard/`0.0.0.0` bind), SEC-3 (no filesystem-write/delete calls), and SEC-4
(no agent/LLM import) in either server source.

### test-aid-dashboard-cli.sh

**Target:** the `aid dashboard` start/stop handlers in `bin/aid` (Bash) (feature-004).

Integration tests for the dashboard launcher: `start` spawns a child and writes
`dashboard.pid` + prints the URL (python and node runtimes); double-start → exit 8
("already running"); `stop` reaps the child and removes the record/logfile (idempotent);
stale-PID reclaim on restart; usage errors → exit 2; runtime-absent → exit 9; busy port →
exit 3; bare `aid`/`version`/`status` regression guard; `--remote` with no mechanism →
exit 10 (stays local); and the `--remote` SUCCESS integration (record `remote=true` +
teardown-on-stop) when tailscale is available.

### test-aid-remote.sh

**Target:** the `_aid_remote_expose` / `_aid_remote_teardown` helpers in `bin/aid` and
their `bin/aid.ps1` twins — feature-005 secure remote exposure. **Uses `pwsh` for the
parity half.**

Drives the helpers with a PATH-shim `tailscale` STUB (no live tailnet) that fails the
suite if ever called with the public `funnel` verb. Covers: expose → `serve --bg <port>`
+ handle/HTTPS URL on stdout + FR18 ACL guidance; scoped teardown (`--https=443 off`, not a
blind reset); the NEVER-FUNNEL guard (SEC-1, static + runtime); idempotent/ malformed
teardown; non-loopback target refusal (exit 11); serve-failure revert (exit 12, never
public); not-logged-in / no-tailscale → exit 10; and Bash↔PowerShell parity (PS half skips
if `pwsh` absent).

### test-registry.sh

**Target:** the DR-1 multi-repo registry side-effect in `bin/aid` (`registry_register` /
`registry_unregister` / `_registry_read_repos`) — task-049.

Unit + CLI tests for the `~/.aid-dash/registry.yml` book-keeping: first-tool `add`
registers the repo, a second `add` is a no-op, removing the last tool unregisters, removing
one-of-several leaves the registry intact; register/unregister idempotency; atomic
temp-file write (`*.aid-tmp.*`, cleaned up); warn-and-continue on write failure (host-tool
op never aborts); and the DM-1 `schema: 1` + `repos:` file format (ASCII-only scaffolding).

### test-producer-completeness.sh

**Target:** the PF-9 producer-completeness gate (delivery-007) — the reader invoked
directly via `python3` / `node` (no HTTP server). **Uses `python3` / `node`.**

Asserts the PT-1 conforming fixture produces a model with no degraded sentinels (null
title/description/delivery/lane/short_name) for works carrying `REQUIREMENTS.md` or
`SPEC.md`, plus a negative assertion that a deliberately-degraded fixture copy fails the
same check (proving the gate bites on regressions). Skips when the runtime is absent.

### test-pipeline-status-walkthrough.sh

**Target:** the M4+M5 pipeline-status lifecycle (feature-001) — `writeback-state.sh
--pipeline` plus static wiring assertions against the canonical skill files.

Two angles: Part A walks the lifecycle state machine by simulating transitions through
`writeback-state.sh --pipeline` (against a throwaway `STATE.md`); Part B is C4 wiring-level
static `grep` assertions that the canonical skills write the `## Pipeline Status` block as
specified. Behavior-preservation guard for the pipeline-status feature.

### test-work-state-template.sh

**Target:** the `## Pipeline Status` block of `work-state-template.md` (canonical +
rendered copies) — feature-001 M1.

Shape assertions that the canonical template (and its rendered dogfood + per-profile
copies) carry the exact `## Pipeline Status` header, all seven fields, and the three closed
enum declarations (Lifecycle / Phase / Active Skill) that are the single source of truth
for feature-002; plus the "written ONLY by … / Never hand-edited" note, and that
`aid-interview` first-run seeds `Lifecycle: Running` / `Phase: Interview` / `Active Skill:
aid-interview` without adding new user-facing output.

### test-summarize-preflight.sh

**Target:** the FR31 legacy-summary migration block (step 6) inside
`canonical/scripts/summarize/summarize-preflight.sh`, plus a stale-check integration.

Covers the legacy `knowledge-summary.html` → new `kb.html` migration: old-present/new-absent
→ migrated; both-present → no clobber; neither → no-op; unwritable `.aid/dashboard` →
best-effort exit 0; idempotency; and a stale-check integration (a migrated summary makes
`stale-check.sh` return `CURRENT_APPROVED`). Uses stub fixtures to satisfy the earlier
preflight checks (which need a real approved KB + network).

### test-home-html-source-sync.sh

**Target:** the home.html source-sync CI equality gate — `dashboard/home.html` (committed
source of truth) vs `.aid/dashboard/home.html` (derived dogfood copy) (R20 / DD-5 / LC-HSRC).

Asserts the two files are byte-identical via `cmp -s`, catching the case where a developer
edited the dogfood copy instead of the source (or failed to sync the source back).
home.html itself is exempt from the ASCII-only gate (served static asset with Unicode
glyphs); this suite enforces equality only, not charset.

### test-aid-migrate.sh

**Target:** the `_aid_migrate_repo` migration logic in `bin/aid` (reachable via
`aid __migrate-repo <path>`) — task-081 / feature-011 §6 gates 4-8.

Unit/safety tests for the 1.0.0→1.1.0 settings migration: era-a valid settings → byte-identical
no-op; era-a malformed/bare settings → repaired to DM-1 validity with `kb_baseline` +
skill overrides preserved; era-b `STATE.md` + `.aid-manifest.json` (and `DISCOVERY_STATE.md`
variant / no-manifest) → synthesized settings; idempotency (second run byte-identical);
no-clobber of existing `kb.html` / legacy summary / `home.html`; and a bare `.aid/.temp/`
(no marker) → non-candidate with zero writes. Every case runs in a throwaway `$AID_HOME` +
fixture repo under `mktemp` and NEVER scans the real `$HOME` or this repo's `.aid/`.

### test-aid-migrate-trigger.sh

**Target:** the cross-manager migration trigger (R16, Gate 9) plus the delivery-011 gate
1/2/3 wrappers — task-082 / feature-011 §6. **Uses `node` / `python3` for vendor-refresh
gates.**

Covers the version-sentinel/opt-in trigger surface: an advanced `VERSION` with
`AID_MIGRATE_YES=1` fires the scan inside a throwaway `HOME` (one fixture repo migrated;
an escape CANARY asserts nothing outside the throwaway HOME is touched); steady-state /
`AID_NO_MIGRATE=1` / no-TTY-no-opt-in → no trigger (SEC-6 no-loop, non-interactive defer);
and npm-postinstall default/opt-in/error paths (always exit 0, NFR12). Gate 1 delegates to
`test-ascii-only.sh`, Gate 2 to `test-aid-cli-parity.sh`, and Gate 3 (vendor-refresh)
asserts `dashboard/home.html` is vendored into the npm/pypi manifests, absent from the
emission manifest (C8), byte-identical to `.aid/dashboard/home.html` (R20), and that the
npm/pypi `vendor` scripts land it.

### test-release-migrate-smoke.sh

**Target:** the L2/L3 install→migrate wiring across all three channels (npm / curl / pypi)
— integration smoke for feature-011. **SKIPs per channel when its toolchain is absent.**

Asserts a REAL channel install/upgrade migrates a pre-existing AID repo as a side effect
(the gap unit tests cannot see): npm postinstall eagerly runs `aid update self --yes` →
scan+migrate; curl `install.sh` then first `aid` run fires the lazy version sentinel; pip
entry point likewise on first run. One seeded "old" repo + one assertion per channel.
`HOME` is pinned to a throwaway for the whole process (the scan defaults to `$HOME`), with
an escape canary asserting the real repo is untouched. Catches packaging/wiring regressions
(e.g. a missing `home.html` source on the bundle path).

### test-multitool-isolation.sh

**Target:** multi-tool install isolation (AC4 of feature-004-lockstep-ci-closeout).
**Needs the install bundle.**

Structural acceptance suite: installs claude-code + cursor + codex into one throwaway repo
(`aid add --from-bundle`) and asserts three invariants — (T01-T12) each tool's tree exists
with the uniform `{agents,skills,aid}` shape under its own root (`.claude/`, `.cursor/`,
`.codex/`); (T13-T20) representative canonical files carrying no per-tool substitution are
byte-identical across the three installed trees; (T21-T26) no operational script in any
tree's `aid/scripts/` subtree references a foreign root basename (tool isolation). Qualitative
coverage — see the suite header for the unit ranges.

### test-ps51-compat.sh

**Target:** all shipped PowerShell stays Windows PowerShell 5.1 compatible (the repo
advertises "PowerShell 5.1+" and the PS files declare `#Requires -Version 5.1`).
**Needs `pwsh`** (runs an AST lint).

Runs an AST-based lint (`ps51-compat-check.ps1`) that fails on any PowerShell 6/7-only
construct — 3-arg `Join-Path`, `utf8NoBOM` encoding, `$IsWindows`, 3-arg `String.Replace`,
web calls without TLS 1.2, etc. Written because PSScriptAnalyzer's `PSUseCompatible*` rules
silently miss several of these (verified), giving false confidence. This is a STATIC lint;
the actual runtime-5.1 behavior is covered by the WinPS 5.1 CI lane in
`.github/workflows/installer-tests.yml` (see ## Running).

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

A second workflow, `.github/workflows/installer-tests.yml` (`Installer CI
(cross-platform)`), runs a two-leg matrix dedicated to the installer surface: the
`ubuntu-latest` / `bash-harness` leg drives the bash installer/CLI/release suites, and the
`windows-latest` / `native-ps1` leg runs `tests/windows/Test-AidInstaller.ps1` (under pwsh 7)
plus the npm + PyPI Windows channel smokes. A dedicated **Windows PowerShell 5.1 lane**
re-runs `Test-AidInstaller.ps1` under the built-in `powershell.exe` (5.1, the version a fresh
Windows box ships) via `shell: powershell`, catching runtime 5.1 breaks (BOM divergence, TLS
handshake, FileSystem-provider semantics) that static analysis cannot. It complements the
static `test-ps51-compat.sh` AST lint (runs in the bash harness). Both legs assert `pwsh` is
present, so the real-Windows path the Linux bash harness cannot reach is always exercised.

---

## Coverage gaps and roadmap

The PowerShell mirrors, the `.mjs` validators, and the **`aid` CLI installer/release
flow** are all covered (closed under L2): `test-validate-diagrams.sh`,
`test-contrast-check.sh`, `test-assemble-3part.sh`, `test-assemble-3part-ps1.sh`, and the
installer/CLI/release suites `test-install*.sh`, `test-aid-cli*.sh`, `test-release*.sh`,
`test-version-sync.sh`, `test-ascii-only.sh`, `test-agents-md-invariant.sh`, plus the
native-Windows `tests/windows/Test-AidInstaller.ps1` on `installer-tests.yml`. (The former
`test-setup.sh` / `test-setup-ps1.sh` suites were removed with the `setup.sh`/`setup.ps1`
installers they targeted.) The `/aid-housekeep` helpers (`canonical/scripts/housekeep/`)
are likewise covered by the five `test-housekeep-*.sh` suites.

The **dashboard surface** (deliveries 007/008) is now covered too: the Python state
reader (`test-dashboard-reader.sh`), the Python↔Node server twins' byte-parity for both
the single-repo and multi-repo (`AID_HOME` + `registry.yml`, `/api/home`,
`/r/<id>/{home.html,kb.html,api/model}`) shapes plus their traversal-refusal / no-public-bind
security invariants (`test-dashboard-parity.sh`, `test-dashboard-parity-h.sh`), the
producer-completeness gate (`test-producer-completeness.sh`), the `aid dashboard`
start/stop launcher and the multi-repo registry book-keeping
(`test-aid-dashboard-cli.sh`, `test-registry.sh`), the secure remote-exposure helpers
(`test-aid-remote.sh`), the home.html source↔dogfood sync gate
(`test-home-html-source-sync.sh`), the legacy-summary → `kb.html` migration inside
summarize-preflight (`test-summarize-preflight.sh`), and the pipeline-status lifecycle +
work-state template shape (`test-pipeline-status-walkthrough.sh`, `test-work-state-template.sh`).

The **1.0.0→1.1.0 migration surface** (deliveries 010/011) is likewise guarded: the
settings repair/synthesize + home.html/kb.html no-clobber provisioning logic
(`test-aid-migrate.sh`), the cross-manager version-sentinel/opt-in trigger and the
vendor-refresh gates (`test-aid-migrate-trigger.sh`), and the per-channel
install→migrate wiring smoke across npm/curl/pypi (`test-release-migrate-smoke.sh`).

The genuinely untested surface is the prompt-driven / orchestration layer:

- **Orchestration skills** (`/aid-discover`, `/aid-execute`, …) — prompt-driven and hard
  to test without an AI host. `aid-reviewer` dispatched from `/aid-discover` is the
  closest thing to integration verification, adversarially grading KB output each cycle.
- **The generator** (`run_generator.py`) — its own VERIFY (deterministic) check runs at
  the end of every render and exits 1 on failure; not part of `tests/canonical/`. The
  copy core carries its own self-tests run by the CI `generator-selftests` job:
  `render.py --self-test` (8 copy-core tests) and `test_manifest_safety.py`
  (both under `.claude/skills/generate-profile/scripts/`, invoked with `--self-test`).
- **Sub-agent definitions** — see `canonical/agents/*/AGENT.md`; verified by dogfooding.
- **Cross-tool consistency** (Claude Code vs Codex vs Cursor vs Copilot CLI vs Antigravity) —
  covered by the renderer's byte-identity assertion across the 5 profiles, not by a suite here.
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
