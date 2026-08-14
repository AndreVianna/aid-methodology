# Pre-refactor test baseline and FR-13 change-set triage

Transient work-folder state. No permanent artifact (KB doc, test, script, template, product code)
may cite this document -- it is deleted with the work folder (`CLAUDE.md § Tracking discipline`,
"Work folders are transient"). It exists for exactly one consumer: **task-019 / SP-16**, which
compares the post-refactor run against it.

RESEARCH type-default **recorded as overridden**: the "compare at least 2 alternatives" default
does not apply. This is a measurement and inventory task -- there is no live alternative to compare
(`task-type-rules.md § RESEARCH`, restated in this task's `DETAIL.md § Scope`).

---

## 1. Capture provenance

| Fact | Value |
|---|---|
| Host / OS | Windows 11 Enterprise 10.0.26200, `win32`; bash lane via Git Bash (MSYS/cygwin-class) |
| Logical CPUs (`nproc`) | 22 |
| Repo root at capture | `C:\Projects\Personal\AID\.claude\worktrees\work-009-refactor` (git worktree, branch `work-009`) |
| Canonical entrypoint | `bash tests/run-all.sh` |
| Parallelism used for the baseline | `AID_TEST_JOBS=4` (equivalently `-P 4`) |
| Per-suite timeout | 300 s (a suite exceeding it is killed and reported `rc=124`) |
| Pytest entrypoint | `python -m pytest dashboard/reader/tests dashboard/server/tests` |
| Sandbox | `HOME` + `USERPROFILE` + `HOMEDRIVE` + `HOMEPATH` all pinned to a throwaway dir |
| Tree state at capture | clean except `.aid/works/work-009-refactor/**` (see § 1.3) |

### 1.1 Why `HOME` alone is insufficient on Windows

`SPEC.md § L-9` and `test-landscape.md § Test Commands` both give the command as
`HOME="$(mktemp -d)" bash tests/run-all.sh`. On this host that pin is **not sufficient**, and a
`HOME`-only sandbox is a privacy and correctness hazard rather than an isolation measure:

- Native `pwsh` does not read `HOME`. It derives `$HOME` from `USERPROFILE` (falling back to
  `HOMEDRIVE` + `HOMEPATH`). Any suite that shells out to `pwsh` -- the entire `*-ps1.sh` twin
  family, `test-aid-cli-ps1.sh`, `test-install-ps1.sh`, `test-connector-secret-ps1.sh`,
  `test-assemble-3part-ps1.sh`, `test-migrate-term-exclusions-ps1.sh` -- therefore resolves the
  **real** `~/.aid` under a `HOME`-only sandbox, reads the developer's real registry and settings,
  and can write to them.
- The baseline capture consequently pinned all four variables (`HOME`, `USERPROFILE`,
  `HOMEDRIVE`, `HOMEPATH`) to one throwaway directory. `tests/run-all.sh:58` additionally gives
  each suite its own private `HOME` for parallel-safe canary isolation; that mechanism does not
  cover `USERPROFILE`, so the outer pin is load-bearing.
- CONFIRMED consequence visible in this very baseline: five `dashboard/server/tests/test_server_py.py`
  failures are host-install contamination that survived even the four-way pin (§ 3), because the
  Python server resolves `AID_HOME` through its own precedence chain rather than through `$HOME`.

### 1.2 Why `-P 22` was rejected, and `-P 4` is the baseline

`tests/run-all.sh:122` sets `jobs="${AID_TEST_JOBS:-$(nproc 2>/dev/null || echo 4)}"`, and its own
comment at `:121` states the budget is "bounded by the runner (ubuntu-24.04 ~= 4 vCPU)". On this
22-core host the shipped default therefore dispatches **22** suites concurrently -- roughly 5.5x
the parallelism the default was calibrated for.

That run (retained as the superseded capture) reported, verbatim from its own summary line:

```
29 of 149 CANONICAL SUITES FAILED:
```

The `-P 4` capture reports **24** non-green suites. The difference is exactly five suites, all of
which pass standalone and pass at `-P 4`:

| Suite | `-P 22` | `-P 4` | Standalone |
|---|---|---|---|
| `test-writeback-state.sh` | FAILED | `rc=0`, `Tests passed: 360` / `Tests failed: 0` | `rc=0`, `Tests passed: 360` / `Tests failed: 0` |
| `test-closure-batching.sh` | FAILED | `rc=0`, `Tests passed: 7` / `Tests failed: 0` | -- |
| `test-dual-intent-self-eval.sh` | FAILED | `rc=0`, `Tests passed: 63` / `Tests failed: 0` | -- |
| `test-graph-relationship-validator.sh` | FAILED | `rc=0`, `Tests passed: 123` / `Tests failed: 0` | -- |
| `test-graph-runtime-gate.sh` | FAILED | `rc=0`, `Tests passed: 73` / `Tests failed: 0` | -- |

`29 - 5 = 24`, which reconciles exactly with the `-P 4` non-green count. The five are contention
artifacts, not failures. `test-writeback-state.sh` is the decisive case: it is *the writer's own
unit harness*, the single most important oracle in this work, and at the shipped default it is red
for a reason that has nothing to do with the writer.

**The `-P 4` capture is therefore the baseline.** The `-P 22` run is retained as evidence for
harness finding (a) in § 7 and for nothing else.

### 1.3 Baseline-before-edit (AC-3)

At capture time `git status --porcelain` listed exactly one modified path:

```
 M .aid/works/work-009-refactor/STATE.md
```

That is this work's own state file, written by the orchestrator's task-state transitions -- inside
`.aid/works/work-009-refactor/`. No file outside the work folder was modified before or during the
capture. CONFIRMED.

---

## 2. Per-suite results -- all 149 canonical suites

Counts are quoted from each suite's **own** `Tests passed:` / `Tests failed:` summary line, never
from a grep over stdout (`test-landscape.md § Test Commands`). Where a suite emits no such line the
cell says so explicitly and **no count is invented**; for a `rc=124` suite that is precisely because
the 300 s kill landed before the summary was printed, so the suite is *recorded as timed out rather
than counted* -- which is what AC-2 requires.

`rc` is the suite's process exit status: `0` green, `1` one or more assertion failures, `124`
killed at the timeout.

Buckets (§ 2.2 gives the per-suite deciding evidence):

- **green** -- `rc=0`.
- **timeout-local** -- `rc=124`. Not a failure. Fork cost on this host is ~1 s per spawn
  (cygwin/MSYS process creation), so a suite that spawns hundreds of subprocesses exhausts a 300 s
  budget here while finishing in a fraction of it on Linux.
- **environment-local** -- `rc=1` for a host reason: a missing tool, a Windows path or 8.3
  short-name mismatch, a `chmod`-based permission assertion, a port bind, a Windows ESM URL scheme,
  or contamination from the real local AID install.
- **genuine-red-pre-refactor** -- `rc=1` for a reason actually about the repo. **Zero suites are in
  this bucket** (§ 2.3).

### 2.1 The table

| Suite | rc | Own summary line | Bucket |
|---|---|---|---|
| `test-actback-fixtures.sh` | 0 | passed 20 / failed 0 | green |
| `test-actback-task.sh` | 0 | passed 42 / failed 0 | green |
| `test-agents-md-invariant.sh` | 0 | passed 25 / failed 0 | green |
| `test-aid-cli-parity.sh` | 124 | emits no summary line | timeout-local |
| `test-aid-cli-ps1.sh` | 124 | emits no summary line | timeout-local |
| `test-aid-cli.sh` | 124 | emits no summary line | timeout-local |
| `test-aid-dashboard-cli.sh` | 124 | emits no summary line | timeout-local |
| `test-aid-migrate-trigger.sh` | 0 | passed 60 / failed 0 | green |
| `test-aid-migrate.sh` | 124 | emits no summary line | timeout-local |
| `test-aid-provisioning.sh` | 1 | passed 37 / failed 5 | environment-local |
| `test-aid-remote.sh` | 1 | passed 18 / failed 31 | environment-local |
| `test-ascii-only.sh` | 0 | passed 29 / failed 0 | green |
| `test-assemble-3part-ps1.sh` | 0 | passed 10 / failed 0 | green |
| `test-assemble-3part.sh` | 0 | passed 15 / failed 0 | green |
| `test-assemble-determinism.sh` | 0 | passed 22 / failed 0 | green |
| `test-build-connectors-index.sh` | 0 | passed 42 / failed 0 | green |
| `test-build-kb-index.sh` | 0 | passed 40 / failed 0 | green |
| `test-calibration-fixtures.sh` | 0 | passed 6 / failed 0 | green |
| `test-catalog-dirs-parity.sh` | 0 | passed 341 / failed 0 | green |
| `test-change-refactor-family-scaffold.sh` | 0 | passed 142 / failed 0 | green |
| `test-closure-batching.sh` | 0 | passed 7 / failed 0 | green |
| `test-closure-check.sh` | 0 | passed 13 / failed 0 | green |
| `test-complexity-score.sh` | 0 | passed 13 / failed 0 | green |
| `test-compute-block-radius.sh` | 0 | passed 28 / failed 0 | green |
| `test-conformance-lane-semantics.sh` | 0 | passed 27 / failed 0 | green |
| `test-connector-consumption-linkage.sh` | 0 | passed 56 / failed 0 | green |
| `test-connector-registry.sh` | 0 | passed 14 / failed 0 | green |
| `test-connector-secret-ac3-leak-sweep.sh` | 0 | passed 11 / failed 0 | green |
| `test-connector-secret-ps1.sh` | 0 | passed 27 / failed 0 | green |
| `test-connector-secret.sh` | 0 | passed 29 / failed 0 | green |
| `test-connector-set-unset-lifecycle.sh` | 0 | passed 56 / failed 0 | green |
| `test-connector-skills-structural.sh` | 0 | passed 63 / failed 0 | green |
| `test-connector-twins-ps1-parity.sh` | 0 | passed 23 / failed 0 | green |
| `test-connectors-registry-integration.sh` | 0 | passed 20 / failed 0 | green |
| `test-contrast-check.sh` | 0 | passed 15 / failed 0 | green |
| `test-coverage-parity.sh` | 0 | passed 24 / failed 0 | green |
| `test-create-family-scaffold.sh` | 0 | passed 64 / failed 0 | green |
| `test-cutover-no-dangling.sh` | 0 | passed 31 / failed 0 | green |
| `test-dashboard-manifest.sh` | 0 | passed 10 / failed 0 | green |
| `test-dashboard-parity-h.sh` | 1 | passed 0 / failed 1 | environment-local |
| `test-dashboard-parity.sh` | 124 | emits no summary line | timeout-local |
| `test-dashboard-reader.sh` | 1 | passed 782 / failed 12 | environment-local |
| `test-delete-pipeline.sh` | 0 | passed 50 / failed 0 | green |
| `test-delivery-gate-aggregate.sh` | 0 | passed 21 / failed 0 | green |
| `test-deploy-monitor-repurpose.sh` | 0 | passed 58 / failed 0 | green |
| `test-describe-full-only.sh` | 0 | passed 54 / failed 0 | green |
| `test-diagram-content.sh` | 0 | passed 3 / failed 0 | green |
| `test-discover-preflight.sh` | 0 | passed 9 / failed 0 | green |
| `test-discovery-doc-ownership.sh` | 0 | passed 13 / failed 0 | green |
| `test-disjoint-merge.sh` | 0 | passed 23 / failed 0 | green |
| `test-doc-counts.sh` | 0 | passed 31 / failed 0 | green |
| `test-doc-set-mapping.sh` | 0 | passed 21 / failed 0 | green |
| `test-doc-set-propose-confirm.sh` | 0 | passed 12 / failed 0 | green |
| `test-doc-set-read.sh` | 0 | passed 48 / failed 0 | green |
| `test-document-family-scaffold.sh` | 0 | passed 119 / failed 0 | green |
| `test-dogfood-byte-identity.sh` | 0 | passed 1506 / failed 0 | green |
| `test-domain-doc-matrix.sh` | 0 | passed 37 / failed 0 | green |
| `test-downstream-worktree-entry.sh` | 0 | passed 60 / failed 0 | green |
| `test-dual-intent-self-eval.sh` | 0 | passed 63 / failed 0 | green |
| `test-essence-capture.sh` | 0 | passed 8 / failed 0 | green |
| `test-executor-graph-flat-plan.sh` | 0 | passed 13 / failed 0 | green |
| `test-expectations-single-source.sh` | 0 | passed 9 / failed 0 | green |
| `test-f010-governance-guards.sh` | 0 | passed 13 / failed 0 | green |
| `test-fix-family-scaffold.sh` | 0 | passed 57 / failed 0 | green |
| `test-frontmatter-lint.sh` | 0 | passed 57 / failed 0 | green |
| `test-grade-summary.sh` | 0 | passed 48 / failed 0 | green |
| `test-grade.sh` | 0 | passed 19 / failed 0 | green |
| `test-graph-canvas.sh` | 1 | passed 9 / failed 1 | environment-local |
| `test-graph-extraction.sh` | 124 | emits no summary line | timeout-local |
| `test-graph-gap-ledger.sh` | 0 | passed 305 / failed 0 | green |
| `test-graph-relationship-validator.sh` | 0 | passed 123 / failed 0 | green |
| `test-graph-runtime-digest.sh` | 0 | passed 45 / failed 0 | green |
| `test-graph-runtime-gate.sh` | 0 | passed 73 / failed 0 | green |
| `test-graph-runtime-grade.sh` | 0 | passed 30 / failed 0 | green |
| `test-graph-runtime.sh` | 0 | passed 227 / failed 0 | green |
| `test-graph-schema-loader.sh` | 0 | passed 249 / failed 0 | green |
| `test-graph-skill-registration.sh` | 0 | passed 207 / failed 0 | green |
| `test-graph-source-enumeration.sh` | 0 | passed 250 / failed 0 | green |
| `test-graph-table-view.sh` | 0 | passed 126 / failed 0 | green |
| `test-graph-view-shell.sh` | 0 | passed 175 / failed 0 | green |
| `test-guardrails-d012.sh` | 0 | passed 35 / failed 0 | green |
| `test-harvest-batching.sh` | 0 | passed 5 / failed 0 | green |
| `test-harvest-coined-terms.sh` | 0 | passed 18 / failed 0 | green |
| `test-housekeep-branch-commit.sh` | 0 | passed 36 / failed 0 | green |
| `test-housekeep-classify.sh` | 0 | passed 24 / failed 0 | green |
| `test-housekeep-deletion-split.sh` | 0 | passed 17 / failed 0 | green |
| `test-housekeep-state.sh` | 0 | passed 43 / failed 0 | green |
| `test-housekeep-workfolder-safety.sh` | 1 | passed 20 / failed 1 | environment-local |
| `test-install-parity.sh` | 0 | passed 3 / failed 0 | green |
| `test-install-provisioning.sh` | 0 | passed 44 / failed 0 | green |
| `test-install-ps1.sh` | 1 | passed 14 / failed 2 | environment-local |
| `test-install.sh` | 0 | passed 20 / failed 0 | green |
| `test-kb-citation-lint.sh` | 0 | passed 8 / failed 0 | green |
| `test-kb-export.sh` | 0 | passed 24 / failed 0 | green |
| `test-kb-forward-authored-marker.sh` | 0 | passed 35 / failed 0 | green |
| `test-kb-freshness-check.sh` | 0 | passed 37 / failed 0 | green |
| `test-kb-index-extract-list.sh` | 0 | passed 39 / failed 0 | green |
| `test-kb-review-surface.sh` | 0 | passed 7 / failed 0 | green |
| `test-kb-scanner-exclusions.sh` | 0 | passed 5 / failed 0 | green |
| `test-kb-scanner-scope.sh` | 0 | passed 5 / failed 0 | green |
| `test-kb-template-authoring-standard.sh` | 0 | passed 134 / failed 0 | green |
| `test-md-export-embed.sh` | 0 | passed 7 / failed 0 | green |
| `test-migrate-hierarchy.sh` | 0 | passed 122 / failed 0 | green |
| `test-migrate-kb-frontmatter.sh` | 0 | passed 60 / failed 0 | green |
| `test-migrate-term-exclusions-ps1.sh` | 0 | passed 15 / failed 0 | green |
| `test-migrate-term-exclusions.sh` | 0 | passed 26 / failed 0 | green |
| `test-multitool-isolation.sh` | 124 | emits no summary line | timeout-local |
| `test-npm-installer.sh` | 1 | passed 47 / failed 29 | environment-local |
| `test-output-root-isolation.sh` | 0 | passed 24 / failed 0 | green |
| `test-path-fixtures.sh` | 0 | passed 20 / failed 0 | green |
| `test-payload-size.sh` | 0 | passed 10 / failed 0 | green |
| `test-pipeline-status-walkthrough.sh` | 0 | passed 163 / failed 0 | green |
| `test-producer-completeness.sh` | 1 | emits no summary line | environment-local |
| `test-prototype-family-scaffold.sh` | 0 | passed 75 / failed 0 | green |
| `test-ps51-compat.sh` | 0 | passed 1 / failed 0 | green |
| `test-pypi-installer.sh` | 1 | passed 50 / failed 24 | environment-local |
| `test-read-setting.sh` | 0 | passed 29 / failed 0 | green |
| `test-recon-classify.sh` | 0 | passed 37 / failed 0 | green |
| `test-reconcile-scenarios.sh` | 0 | passed 49 / failed 0 | green |
| `test-registry.sh` | 124 | emits no summary line | timeout-local |
| `test-release-install-e2e.sh` | 1 | passed 48 / failed 73 | environment-local |
| `test-release-migrate-smoke.sh` | 1 | passed 4 / failed 2 | environment-local |
| `test-release.sh` | 1 | passed 39 / failed 31 | environment-local |
| `test-self-commands.sh` | 0 | passed 42 / failed 0 | green |
| `test-shortcut-builder-invariants.sh` | 0 | passed 43 / failed 0 | green |
| `test-shortcut-engine-contract.sh` | 0 | passed 24 / failed 0 | green |
| `test-skill-counts.sh` | 0 | passed 1 / failed 0 | green |
| `test-spine-depth-coverage.sh` | 0 | passed 159 / failed 0 | green |
| `test-summarize-preflight.sh` | 1 | passed 18 / failed 2 | environment-local |
| `test-task-state-transitions.sh` | 0 | passed 16 / failed 0 | green |
| `test-teachback-fixtures.sh` | 0 | passed 13 / failed 0 | green |
| `test-teachback-questions.sh` | 0 | passed 13 / failed 0 | green |
| `test-test-experiment-family-scaffold.sh` | 0 | passed 98 / failed 0 | green |
| `test-ticket-retirement-structural.sh` | 0 | passed 98 / failed 0 | green |
| `test-ticket-skills-structural.sh` | 0 | passed 88 / failed 0 | green |
| `test-triage-routing.sh` | 0 | passed 67 / failed 0 | green |
| `test-update-kb-scope-fidelity.sh` | 0 | passed 110 / failed 0 | green |
| `test-validator-profiles.sh` | 0 | passed 150 / failed 0 | green |
| `test-version-sync.sh` | 1 | passed 45 / failed 1 | environment-local |
| `test-visual-fidelity.sh` | 0 | passed 26 / failed 0 | green |
| `test-work-initiation-gate.sh` | 0 | passed 94 / failed 0 | green |
| `test-work-state-template.sh` | 0 | passed 58 / failed 0 | green |
| `test-worktree-lifecycle.sh` | 0 | passed 116 / failed 0 | green |
| `test-write-connector.sh` | 0 | passed 75 / failed 0 | green |
| `test-write-control-signal.sh` | 0 | passed 50 / failed 0 | green |
| `test-write-external-source.sh` | 0 | passed 55 / failed 0 | green |
| `test-write-requirement.sh` | 0 | passed 22 / failed 0 | green |
| `test-write-setting.sh` | 0 | passed 28 / failed 0 | green |
| `test-writeback-state.sh` | 0 | passed 360 / failed 0 | green |

**Tally: 149 suites = 125 green + 15 environment-local + 9 timeout-local + 0 genuine-red-pre-refactor.**

For every green suite the per-test pass/fail set is fully determined by its own summary line:
`Tests failed: 0` means every one of its `Tests passed: N` assertions passed. The per-test failure
set for the 15 non-green suites is enumerated in § 2.2. For the 9 `timeout-local` suites **no
per-test set exists at all** -- there is no partial credit recorded and none is inferred.

### 2.2 The 15 `environment-local` suites, with deciding evidence

| Suite | Failing units | Deciding evidence | Confidence |
|---|---|---|---|
| `test-aid-provisioning.sh` | `PRV-P05a`, `PRV-P05b`, `PRV-R02b`, `PRV-R02c`, `PRV-R04b` | P05a/b are the `chmod`-unwritable-parent pattern: "non-writable parent -> returns non-zero (error path) -- expected non-zero exit, got 0". `chmod`-based permission denial does not take effect on Windows, so the parent stayed writable and the error path never fired. R02b/c and R04b sit under the section header "PRV-R: runtime fallback to user tier **when shared is non-writable**" -- the same unmet premise, so the entry landed in the shared tier instead of the user tier | CONFIRMED |
| `test-aid-remote.sh` | 31 units, first `T-1: expose exit 0 with logged-in stub -- expected exit 0, got 11` | The `tailscale` stub is never reached; the log carries 8 occurrences of a Windows batch-shim signature (`|| goto :error`) from a `python3`/CLI shim on `PATH`. No `tailscale` on the host | CONFIRMED |
| `test-dashboard-parity-h.sh` | `[PT-1-H]` | "python server did not start within 12s on port" -- a port-bind/server-start test. Known-unrunnable locally (`reference_local-test-hangs`) | CONFIRMED |
| `test-dashboard-reader.sh` | 12 units, `DRPY1-*` | Identical set to the 12 reader-side pytest failures in § 3 (this suite is a shell wrapper around them): 8.3 short-path mismatch, `\`-vs-`/` separator, and Node `ERR_UNSUPPORTED_ESM_URL_SCHEME` | CONFIRMED |
| `test-graph-canvas.sh` | `GC00c` | 6 units (`GC09`, `GC10`, `GC13`, `GC17`, `GC19`, `GC21bounds`) SKIP with "jsdom is not resolvable here (it IS a devDependency of the repo-root package.json, but is not installed in this environment)". `GC00c` is a meta-assertion -- "only 6 outcome line(s), so most of the suite did not run" -- so the one failure is the *absence* of jsdom, reported once | CONFIRMED |
| `test-housekeep-workfolder-safety.sh` | `U10` (not the Unit 4 header the digest's first-line probe surfaced) | `U10: ancestry fallback used (gh absent) -> gate=offer -- expected 'offer' got 'explicit-confirm: ... (SHA not ancestor of origin/master); STATE: Deployed.'`. `gh` is absent AND this branch carries unpushed commits, so the ancestry probe falls through to explicit-confirm. **Unrelated to `STATE.md`** -- do not read this as a state-format failure | CONFIRMED |
| `test-install-ps1.sh` | `IN33c`, `IN33f` | "host-survival success: install LASTEXITCODE=0 visible to caller -- pattern not found: 'INSTALL-LASTEXITCODE=0'". A `pwsh` host-survival probe; the suite log retains no further diagnostic. Attributed to the native-`pwsh`-under-MSYS invocation path, not to repo logic | LIKELY |
| `test-npm-installer.sh` | 29 units, first `NM01-01 shim with stub -- exit 0 -- expected exit 0, got 64` | Exit 64 (`EX_USAGE`) with `NM01-02 argv file not written by stub`: the stub `bin/aid` is never executed, i.e. the failure is in the packaging shim's exec layer on Windows, not in argv handling. No `npm` on the host | LIKELY |
| `test-producer-completeness.sh` | `[positive-python]` (suite emits no summary line) | `python completeness gate FAILED on conforming fixture -- File "<string>", line 1 / \|\| goto :error / IndentationError: unexpected indent`. The host's `python3` is a Windows batch shim; its own `.cmd` body (`\|\| goto :error`) was fed to the interpreter. A pure shim artifact | CONFIRMED |
| `test-pypi-installer.sh` | 24 units, first `PW01-01 shim with stub -- exit 0 -- expected exit 0, got 64` | Same exit-64 shim-exec signature as `test-npm-installer.sh`, in the other packager. No `pip`-installed console-script layer on the host | LIKELY |
| `test-release-install-e2e.sh` | 73 units, first `E2E01 release.sh --dry-run exits 0 -- expected exit 0, got 1` | All 73 cascade from `E2E01`: with no staging dir, every later assertion fails as "file does not exist". `release.sh --dry-run`'s own stderr was not retained in the captured log, so the root cause is inferred from the sibling suite below | LIKELY |
| `test-release-migrate-smoke.sh` | `RMS-NPM-01`, `RMS-PYPI-01` | `npm global install failed` / `wheel build or pip install failed` -- no `npm`, no wheel toolchain | CONFIRMED |
| `test-release.sh` | 31 units, first `RL01 dry-run exits 0 (happy path) -- expected exit 0, got 1` | Downstream failures are `tar (child): ...aid-claude-code-v2.3.0.tar.gz: Cannot open: No such file or directory` (nothing was staged). The log also carries the `python3`-shim signature (`\|\| goto :error` / `IndentationError`) at its generator step and `tests/canonical/test-release.sh: line 396: .../profiles/claude-code/: Is a directory` | LIKELY |
| `test-summarize-preflight.sh` | `T1d` (x2) | "new path created despite unwritable knowledge dir" / "old path deleted despite migrate failure" -- the `chmod`-unwritable-directory pattern again | CONFIRMED |
| `test-version-sync.sh` | `WF01` | `WF01 release.yml is valid YAML -- expected exit 0, got 1`. Decisive detail: the **paired** assertion `WF01 yaml.safe_load returns without error` (which checks for `OK` in the captured output, `test-version-sync.sh:203`) **passed**. So `yaml.safe_load` succeeded and only the process exit code was wrong -- the host `python3` shim returns non-zero after a successful run. Guarded by `command -v python3 && python3 -c "import yaml"` at `:199`, so the skip branch was not taken | CONFIRMED |

### 2.3 No suite is `genuine-red-pre-refactor`

Every one of the 15 `rc=1` suites resolves to a host cause. **The baseline therefore contains zero
pre-existing repo failures**, and this is the point at which laundering is easiest and most
damaging: it would be convenient, and wrong, to bank 24 non-green suites as "pre-existing red" and
thereby give the post-refactor run 24 free failures.

Instead:

- **CI on Linux is the authoritative gate for every `timeout-local` and every `environment-local`
  suite.** None of them is evidence about the repo on this host, in either direction: a green local
  run of one would not clear it either.
- **task-019 must compare against these buckets, not against raw counts.** Concretely: compare
  green-suite-to-green-suite per test; treat each `timeout-local` suite as having **no** baseline
  (its post-refactor result is judged by CI alone); and for each `environment-local` suite compare
  only the *named failing unit set* in § 2.2 -- a new failing unit inside such a suite is a
  regression even though the suite was already `rc=1`.
- Four suites rest on LIKELY rather than CONFIRMED evidence (`test-install-ps1.sh`,
  `test-npm-installer.sh`, `test-pypi-installer.sh`, and the `test-release.sh` /
  `test-release-install-e2e.sh` pair). If CI on Linux shows any of them red at this same commit,
  that suite reclassifies to `genuine-red-pre-refactor` and this section must be corrected before
  task-019 uses it.

### 2.4 In-scope suites with no usable local baseline

Two suites that `SPEC.md § L-9` names as behavior-preservation oracles are `timeout-local` here and
therefore contribute **nothing** to the baseline:

- `test-aid-cli-parity.sh` (`rc=124`) -- the format-stamp twin.
- `test-aid-migrate.sh` (`rc=124`) -- the migration unit harness, and the heaviest oracle for FR-9.

task-019 cannot diff these against a local pre-refactor run. Their baseline must come from CI, or
from an individually-run capture with a raised timeout. Recording this now is the point: discovering
it during task-019 would look like a regression in the two suites that matter most to FR-9.

---

## 3. Pytest -- `dashboard/reader/tests` + `dashboard/server/tests`

Own summary line, verbatim:

```
17 failed, 2066 passed, 14 skipped, 246 subtests passed in 716.63s (0:11:56)
```

All 17 failures are `environment-local`; **zero** are `genuine-red-pre-refactor`.

| # | Failing test | Evidence | Bucket |
|---|---|---|---|
| 1 | `test_reader.py::TestLocator::test_paths_computed_correctly` | `WindowsPath('C:/Users/andre.vianna/...') != WindowsPath('C:/Users/ANDRE~1.VIA/...')` -- 8.3 short-path form of the same directory | environment-local |
| 2 | `test_task014_fixtures.py::TestMultiWorktreeRepo::test_parse_porcelain_single_worktree` | `'\repo\main' != '/repo/main'` -- Windows separator | environment-local |
| 3 | `test_task014_fixtures.py::TestMultiWorktreeRepo::test_parse_porcelain_two_worktrees` | `'/repo/main' not found in {'\repo\.claude\worktrees\feat', '\repo\main'}` -- same | environment-local |
| 4 | `test_task014_fixtures.py::TestGitDegradeScenario::test_enumerate_worktree_roots_degrades_to_main_on_none` | `WindowsPath('C:/Users/andre.vianna/.../.aid') != WindowsPath('C:/Users/ANDRE~1.VIA/.../.aid')` -- 8.3 | environment-local |
| 5 | `test_task044_freshness_parity.py::TestDocFreshnessParity::test_all_verdicts_node` | `RuntimeError: Node script failed (rc=1): Error [ERR_UNSUPPORTED_ESM_URL_SCHEME] ... On Windows, absolute paths must be valid file:// URLs. Received protocol 'c:'` | environment-local |
| 6 | ...`::test_doc_freshness_entry_order_identical` | same `ERR_UNSUPPORTED_ESM_URL_SCHEME` | environment-local |
| 7 | ...`::test_node_current_verdict` | same | environment-local |
| 8 | ...`::test_node_premigration_unknown` | same | environment-local |
| 9 | ...`::test_node_suspect_verdict_with_named_source` | same | environment-local |
| 10 | ...`::test_node_url_source_unknown` | same | environment-local |
| 11 | ...`::test_parity_byte_identical_doc_freshness` | same | environment-local |
| 12 | ...`::test_suspect_count_equals_one` | same | environment-local |
| 13 | `test_server_py.py::TestRouteTable::test_root_200_when_index_present` | Served the **real installed** dashboard page, not the fixture: `AssertionError: b'<html>' not found in b'<!DOCTYPE html>\n<html lang="en" data-theme="light">...'`. Host-install contamination reaching past the four-way home pin | environment-local |
| 14 | `test_server_py.py::TestRouteTable::test_root_503_when_index_absent` | `AssertionError: 200 != 503` -- a real installed `index.html` was present where the fixture expected none. Same cause as #13 | environment-local |
| 15 | `test_server_py.py::TestApiHomeDm2Shape::test_machine_aid_version_from_version_file` | `AssertionError: '2.3.0' != '1.0.0-test'` -- read the real installed `VERSION`, not the fixture's | environment-local |
| 16 | `test_server_py.py::TestApiHomeDm2Shape::test_machine_panel_has_aid_home` | `AssertionError: False is not true` -- same `AID_HOME`-resolution family as #13-#15 | environment-local |
| 17 | `test_server_py.py::TestAidHomeResolution::test_subprocess_boot_via_env` | `'C:\Users\ANDRE~1.VIA\...\aid_home' != 'C:\Users\andre.vianna\...\aid_home'` -- 8.3 | environment-local |

Notes for task-019:

- Failures #13-#16 mean the pytest server lane is **not** hermetic on this host even with `HOME`,
  `USERPROFILE`, `HOMEDRIVE` and `HOMEPATH` pinned, because the server resolves `AID_HOME` through
  its own precedence chain. Any post-refactor change in this group is uninterpretable locally.
- The 14 skips are not itemised here: pytest reports them only as a count on its summary line, and
  inventing an itemisation would violate the "quote the summary line" rule. If task-019 needs the
  skip identities it must re-run with `-rs`.
- `246 subtests passed` is a separate counter from `2066 passed`; do not add them.

---

## 4. FR-13 candidate triage -- IN-SCOPE-to-edit vs MUST-NOT-EDIT

### 4.1 What the inventory is, and what it misses

`REQUIREMENTS.md § FR-13` defines the candidate inventory as *files referencing `STATE.md`*:
**47 under `tests/`** and **37 under the `dashboard/**/tests/` trees**. Both figures reproduce
exactly (`grep -rl 'STATE\.md'`, `__pycache__` excluded from the dashboard count -- with `.pyc`
files included the raw grep returns 90 dashboard paths). The `51` figure elsewhere in that inventory
is the count across *all* of `dashboard/`, not its test trees; `47 + 37` is the correct pair.

That definition has a **gap**, and triaging only the 84 would understate the change-set. Seven files
`SPEC.md § L-9` names as in-scope contain **no** `STATE.md` string, so no grep for it can find them:

| File | Why the inventory misses it | Evidence |
|---|---|---|
| `tests/canonical/test-work-state-template.sh` | References the template filenames, not `STATE.md` | 50 hits for `state-template`, 0 for `STATE.md` |
| `tests/canonical/test-connector-consumption-linkage.sh` | same | 6 hits for `state-template` |
| `tests/canonical/test-ticket-retirement-structural.sh` | same | 6 hits for `state-template` |
| `tests/canonical/test-shortcut-engine-contract.sh` | Neither string appears | 0 hits for `STATE`, 0 for `state-template` |
| `tests/canonical/test-release-migrate-smoke.sh` | Neither string appears | 0 hits for `STATE`, 0 for `state-template` |
| `tests/canonical/test-aid-cli-parity.sh` | Its 50 `STATE` hits are all `AID_STATE_HOME` / "STATE home" -- unrelated to state files | 0 hits for `STATE.md` |
| `dashboard/server/tests/test_write_enabled_cross_runtime_parity.py` | Not in the 37 | 0 hits for `STATE.md` |

**Triaged universe = 47 + 37 + 7 = 91 files. Split: 73 IN-SCOPE-to-edit, 18 MUST-NOT-EDIT.**

### 4.2 MUST-NOT-EDIT (18) -- editing one is itself a scope defect

| File | One-line reason |
|---|---|
| `tests/canonical/test-discover-preflight.sh` | Discovery-area ledger only (`.aid/knowledge/STATE.md`), out of scope (`SPEC.md § L-9`) |
| `tests/canonical/test-summarize-preflight.sh` | Discovery-area ledger only, out of scope (`SPEC.md § L-9`) |
| `tests/canonical/test-kb-freshness-check.sh` | KB ledger only -- `FR20` asserts `STATE.md` is *excluded* by name from freshness output |
| `tests/canonical/test-grade-summary.sh` | Builds `.aid/knowledge/STATE.md` for Knowledge Summary Status; KB ledger only |
| `tests/canonical/test-kb-review-surface.sh` | `RS03` asserts KB meta ledgers (`STATE.md`, `README.md`) are review-excluded; KB ledger only |
| `tests/canonical/test-migrate-hierarchy.sh` | Triaged out by `SPEC.md § L-6` (89 references) -- it is the legacy hierarchy-migration oracle |
| `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/STATE.md` | The legacy-markdown **input** to the FR-9 migration oracle; converting it destroys the oracle |
| `.../work-999-migration-test/deliveries/delivery-001/STATE.md` | same |
| `.../work-999-migration-test/deliveries/delivery-001/BLUEPRINT.md` | Same fixture tree; its prose names the migrated-from `STATE.md` |
| `.../work-999-migration-test/deliveries/delivery-002/STATE.md` | same |
| `.../work-999-migration-test/deliveries/delivery-002/BLUEPRINT.md` | same |
| `tests/canonical/check-skill-counts.mjs` | Its two references are `.aid/knowledge/STATE.md` (`:149`, `:156`) -- KB ledger |
| `tests/canonical/test-graph-runtime.sh` | Writes `.aid/knowledge/STATE.md` only (`:349`, `:1000`) -- KB ledger |
| `tests/canonical/test-graph-runtime-digest.sh` | Writes `.aid/knowledge/STATE.md` only (`:227`) -- KB ledger |
| `tests/canonical/test-graph-runtime-gate.sh` | Writes `.aid/knowledge/STATE.md` only (`:251`) -- KB ledger |
| `tests/coverage-baseline.tsv` | 87 references, but **re-bootstrapped wholesale, never row-edited** (`SPEC.md § L-9`); a row edit here is the defect |
| `dashboard/reader/tests/test_task064_kb_status.py` | All 17 references resolve `kb / "STATE.md"` (`:201`, `:388`, `:403`, `:419`, `:437`, `:486`, `:526`, `:578`, `:596`, `:611`, `:634`, `:659`, `:678`) -- KB ledger |
| `dashboard/reader/tests/test_task066_kb_parity.py` | All 5 references resolve `kb / "STATE.md"` (`:280`, `:299`, `:339`, `:350`) -- KB ledger |

Note on the fixture tree: it carries **seven** `STATE.md` files (work root, `delivery-001`,
`delivery-002`, and the four per-task files under `delivery-001/tasks/task-001`, `task-002`,
`task-004`, `delivery-002/tasks/task-003`), but only **three** of them contain the literal string
`STATE.md` and so appear in the inventory. All seven are MUST-NOT-EDIT.

### 4.3 IN-SCOPE-to-edit (73)

`tests/` -- 31 files:

| File | One-line reason |
|---|---|
| `tests/canonical/test-writeback-state.sh` | The writer's own unit harness; 224 references, all three levels of work state (`SPEC.md § L-9`) |
| `tests/canonical/test-disjoint-merge.sh` | 73 references; the concurrency/disjoint-write oracle over the per-unit state hierarchy (NFR-3) |
| `tests/canonical/test-delivery-gate-aggregate.sh` | 27 references; `## Delivery Gate` written into the delivery state file (Test 7) |
| `tests/canonical/test-task-state-transitions.sh` | Asserts the `### Tasks lifecycle` table row after each `--field State` write |
| `tests/canonical/test-work-state-template.sh` | The template-shape suite; every subject resolves a `*-state-template.md` path FR-3 renames |
| `tests/canonical/test-pipeline-status-walkthrough.sh` | Drives the lifecycle state machine through the work state file (`:30`, `:53`) |
| `tests/canonical/test-delete-pipeline.sh` | Oracle for the `§L-10` `Running`-guard property (AC-13a); reads `lifecycle` from the state file |
| `tests/canonical/test-shortcut-engine-contract.sh` | Engine `INTAKE Step 4` copies the templates by name; **carries no state-file/template string today**, so its entry is additive |
| `tests/canonical/test-housekeep-workfolder-safety.sh` | 15 references; classifier signals read the work state file |
| `tests/canonical/test-aid-migrate.sh` | 27 references; the migration unit harness FR-9 extends |
| `tests/canonical/test-aid-migrate-trigger.sh` | Lazy-stamp encounter model; `:462` keys on the presence of `knowledge/STATE.md` |
| `tests/canonical/test-release-migrate-smoke.sh` | L2/L3 wiring smoke for install-time migration; **no state-file string today**, entry is additive |
| `tests/canonical/test-aid-cli-parity.sh` | Format-stamp twin (bash/ps1 parity of the migrate surface); **no `STATE.md` reference today**, entry is additive |
| `tests/canonical/test-connector-consumption-linkage.sh` | `CL08c-e` assert `ticket_ref` in all three `*-state-template.md` files (paths `:60-62`) |
| `tests/canonical/test-ticket-retirement-structural.sh` | `T087-T089` assert the same three template paths (`:93-95`) |
| `tests/canonical/test-cutover-no-dangling.sh` | `CND12a-b` resolve `work-state-template.md` and assert two `##` headings are absent (`:124-130`) |
| `tests/canonical/test-describe-full-only.sh` | `:233` onward builds a markdown work-state fixture carrying `## Pipeline State` / `## Interview State` |
| `tests/canonical/test-connector-secret-ac3-leak-sweep.sh` | `:131` runs a **live** `find "${REPO_ROOT}/.aid" -iname 'STATE.md'` sweep -- unretargeted it silently scans nothing |
| `tests/canonical/test-connector-set-unset-lifecycle.sh` | Writes work-folder sentinel state files (`:102`, `:104`) the connector writer must not touch |
| `tests/canonical/test-create-family-scaffold.sh` | Builds work state fixtures (`:443`, `:729`) and asserts bold-line fields (`CFS35`, `CFS45`, `CFS46`) |
| `tests/canonical/test-change-refactor-family-scaffold.sh` | Same shape (`:652`, `:991`; `CRF43`, `CRF55`, `CRF56`) |
| `tests/canonical/test-document-family-scaffold.sh` | Same shape (`:426`, `:679`; `DFS24`, `DFS34`, `DFS47`, `DFS48`) |
| `tests/canonical/test-fix-family-scaffold.sh` | Same shape (`:371`; `FFS36`, `FFS42`, `FFS45`, `FFS46`) and asserts on `${DEFECT_DIR}/STATE.md` (`:442`) |
| `tests/canonical/test-prototype-family-scaffold.sh` | Same shape (`:426`, `:700`; `PFS24`, `PFS35`, `PFS46`, `PFS47`) |
| `tests/canonical/test-test-experiment-family-scaffold.sh` | Same shape (`:405`, `:693`; `TEF43`, `TEF55`, `TEF56`) |
| `tests/canonical/test-deploy-monitor-repurpose.sh` | Builds a work state fixture (`:188`) and asserts a bold line `**Lifecycle:** Paused-Awaiting-Input` (`:257`) |
| `tests/canonical/test-downstream-worktree-entry.sh` | `G2` asserts skill text ordering around "`STATE.md` read" (`:174`, `:190`) -- skill text changes under FR-8 |
| `tests/canonical/test-housekeep-state.sh` | Builds work state fixtures; Unit 19 error path is "`STATE.md` file not found -> exit 1" |
| `tests/canonical/test-housekeep-classify.sh` | `:211` keys the classifier on the absence of a work state file |
| `tests/canonical/test-housekeep-deletion-split.sh` | `:274` seeds work state files with `Deployed`+SHA so the signals pass |
| `tests/canonical/test-worktree-lifecycle.sh` | `:253-254` creates an untracked work state file as the real-world convention |
| `tests/canonical/test-write-control-signal.sh` | `U26` asserts stop/resume leave the work state file **byte-unchanged** (`:266`) |
| `tests/canonical/test-work-initiation-gate.sh` | `:118`, `:134` build frontmatter state files as the routing inputs |
| `tests/canonical/test-triage-routing.sh` | `TR02b`/`TR02d` grep skill text for the literal `STATE.md` (`:85`, `:90`) |
| `tests/canonical/test-graph-source-enumeration.sh` | `R-EXCL-03` asserts the row `int:.aid/works/w1/STATE.md` is **absent** (`:338`, `:997`) |
| `tests/canonical/test-dashboard-parity-h.sh` | Fixture work state file carrying literal U+2028/U+2029 (`:14`, `:21`) |
| `tests/lib/pt1h_r7_check_state.py` | Reads the same U+2028/U+2029 fixture state file (`:8`, `:10`) |

(That table lists 37 rows because it also carries the six `tests/` files from § 4.1 that are not in
the 47; the `tests/`-inventory subset is 31 of the 47.)

`dashboard/**/tests/` -- 35 of the 37, plus `test_write_enabled_cross_runtime_parity.py`:

| File | One-line reason |
|---|---|
| `reader/tests/test_work003_state_schema.py` | The dual-format (frontmatter-first + legacy-prose-fallback) state read is this suite's whole subject; `§L-3` deletes the fallback |
| `reader/tests/test_work001_delivery_layouts.py` | Both layouts asserted through per-unit state files (`:10`) |
| `reader/tests/test_flattened_layout_parity.py` | Builds the flat fixture (work-root state file + `tasks/task-NNN/DETAIL.md`) and is the AC-2 fixture-builder home |
| `reader/tests/test_task014_fixtures.py` | 31 references; builds the hierarchical per-unit state fixture |
| `reader/tests/test_integration.py` | End-to-end: a state file written by `writeback-state.sh` read back by the reader (`:11`) |
| `reader/tests/test_reader.py` | Writes work state files through one helper (`:112`) feeding 117 test functions |
| `reader/tests/test_derivation.py` | Text fixtures for the no-`## Pipeline Status`-block fallback path (`:69`) |
| `reader/tests/test_fixtures.py` | Fixture #9 is "malformed/torn state file -> `parse_warning` + best-effort model" (AC-5) |
| `reader/tests/test_task011_reconcile.py` | `_state_md()` helper builds minimal state text (`:99`) |
| `reader/tests/test_task069_detail_parser.py` | Writes work state files (`:92`) |
| `reader/tests/test_task029_stop_requested.py` | Flat (`### Tasks lifecycle`) and hierarchical (per-task state file) derivation (`:12`) |
| `reader/tests/test_feature009.py` | State fixture with a real `delivery-NNN` wave column (`:241`) |
| `reader/tests/test_work016_container_discovery.py` | Writes `_STATE_MD` fixtures (`:118`) |
| `reader/tests/test_security_hardening.py` | Bounded-read DoS guard on a >5 MB state file (`:13`) |
| `reader/tests/test_task002_resolve_work_dir.py` | "a work directory with **no** state file still counts as a candidate" (`:15`) |
| `reader/tests/test_task008_display_rename.py` | `display_name` in per-task state frontmatter (`:13`) |
| `reader/tests/test_resolve_work_dir_cross_runtime_parity.py` | Writes a work state file for twin parity (`:118`) |
| `server/tests/test_server_node.mjs` | 25 references; writes work state files (`:126`) |
| `server/tests/test_reader_task069.mjs` | Constructs minimal state fixtures (`:63`) |
| `server/tests/test_task011_dispatch_round_trip.py` | Flat-layout work with a valid state file (`:102`) |
| `server/tests/test_task011_dispatch_round_trip.mjs` | Node twin of the same (`:129`) |
| `server/tests/test_task033_execution_control_round_trips.py` | Asserts on the state-file **BODY** text after the closing `---` fence (`:44`) -- a zone that ceases to exist |
| `server/tests/test_task008_display_rename.py` | `task.rename` against nested per-task frontmatter and flat rows (`:23`) |
| `server/tests/test_task010_task_notes.py` | Writes work state files (`:64`) |
| `server/tests/test_task010_task_notes_cross_runtime_parity.py` | Twin parity over the same write (`:118`) |
| `server/tests/test_task012_consuming_round_trips.py` | Asserts the raw state-file substring (`:27`) |
| `server/tests/test_task002_resolve_work_dir.mjs` | Never throws on a missing/malformed state file (`:19`) |
| `server/tests/test_index_html.py` | `:920` pins the `'.aid/' + workId + '/STATE.md'` fallback path a past fix changed; comment-level, no assertion inverts |
| `server/tests/test_task004_op_dispatch.py` | Writes work state files (`:96`) |
| `server/tests/test_task025_pipeline_delete_ops.py` | Seeds `.aid/works/<id>/STATE.md` so `resolve_work_dir` finds it (`:99`) |
| `server/tests/test_task025_pipeline_delete_ops.mjs` | Writes `---\nlifecycle: ${lifecycle}\n---\n` (`:148`) |
| `server/tests/test_task027_pipeline_delete_round_trips.py` | 409 guard on `lifecycle=Running` read from the state file (`:26`) |
| `server/tests/test_task029_task_stop_resume_ops.py` | Stop/resume must not touch the state file (`:34`) |
| `server/tests/test_task029_task_stop_resume_ops.mjs` | Node twin of the same (`:145`) |
| `server/tests/test_server_py.py` | Writes work state files (`:125`) |
| `server/tests/test_write_enabled_cross_runtime_parity.py` | Oracle for the `§L-11` write-path property (AC-13b); not in the inventory (§ 4.1) |

---

## 5. Change-set enumeration -- assertions expected to invert or change

This is what SP-16 compares against. An **understated** enumeration is itself a defect: an
assertion that regresses in an unlisted suite is indistinguishable from one intentionally updated.

Two kinds of entry, and the distinction matters:

- **path-level** -- the assertion's *subject* moves (`STATE.md` -> `STATE.yml`, or
  `*-state-template.md` -> `*.yml`). The assertion's substance survives. Every assertion in a suite
  whose fixture builder writes the state file is a path-level entry, so the count is the suite's own
  `Tests passed:` figure.
- **content-level / inverting** -- the assertion's *expectation* changes or flips. These are
  enumerated individually below.

### 5.1 `tests/canonical/test-writeback-state.sh` -- 360 assertions, Units 1-24

`SPEC.md § L-9` says "Units 1-21". **The file actually runs Units 1-24** (`:240`, `:270`, `:314`,
`:374`, `:402`, `:421`, `:447`, `:491`, `:541`, `:661`, `:737`, `:807`, `:857`, `:919`, `:947`,
`:965`, `:1115`, `:1209`, `:1262`, `:1337`, `:1570`, `:1675`, `:1931`, `:2042`); Unit 20 is the
flattened single-delivery layout, Unit 22 the frontmatter-writer path, Unit 23 the
`Name` -> `display_name` rename, Unit 24 the `AID_WORK_DIR`-only append-issue branch. Unit 20 is
absent from the header index (`:19-38`) though it runs. Enumerating only 21 units would leave
Units 22-24 -- including the body-invariance unit -- unaccounted for.

Path-level: **all 360**, via the three fixture builders `make_work_state` / `make_delivery_state` /
`make_task_state`.

Content-level / inverting:

| Unit | Assertion (label as emitted) | Change |
|---|---|---|
| 14 | `H2 pipe in --value -> exit 4` (`:923`) | **INVERTS** -- FR-4b deletes the `\|` guard (`writeback-state.sh:767-769`); expectation becomes exit 0 |
| 14 | `H2 pipe in --value: error message mentions "cannot contain '\|'"` (`:925`) | **INVERTS** -- the message ceases to exist |
| 14 | `H2 pipe rejection: task STATE.md not modified` (`:935`) | **INVERTS** -- the file is now written; also path-level |
| 14 | `H2b newline in --value -> exit 4` (`:944`) | **INVERTS** -- FR-4b also deletes the newline guard (`:772-774`) |
| 2 | every `--findings` assertion | `## Quick Check Findings` section-replace becomes a structured `quick_check` mapping + sequence (`§L-2`) |
| 3 | every `--block` assertion, incl. the emitted `## Delivery Gate block written for delivery-NNN` message | Section-replace becomes `delivery_gate.*` structured writes |
| 4 | every `--lifecycle` assertion | Delivery lifecycle write moves to `delivery_lifecycle.*` |
| 9 | "frontmatter creation + each base field" | Section/fence creation becomes whole-document key space; the frontmatter fence disappears |
| 12 | `12a`, `12b`, `12c`, `12d` ("work STATE.md unchanged after ...") | Path-level only; the byte-equality substance survives verbatim -- these are the isolation canaries and must **not** weaken |
| 13 | the exit-6 error path | Presence check changes from "the `## Task State` heading exists" to "the file parses and is a mapping" |
| 16 | `field=State` enum validation | Survives; row-arithmetic path deleted (`write_task_field_flat`), key path `tasks_lifecycle.task-NNN.state` |
| 18 | on-disk block determinism | The derived block is no longer a markdown block |
| 22 | body-invariance assertions | **Restated, not deleted**: FR-4a becomes "every pre-existing line other than the written key's line is byte-reproduced", with the create-parent-if-absent addition permitted |
| 8, 17 | concurrency assertions | Path-level only; the lock, temp-file + verify + atomic `mv` sequence must survive unchanged (NFR-3) |
| 21 | octal-footgun ids (`008`, `090`) | Path-level only; base-10 resolution must survive |

### 5.2 `tests/canonical/test-work-state-template.sh` -- 58 assertions, WS01-WS20 (16 live)

WS06 / WS11 / WS17 / WS18 were removed as comment-text assertions. Path-level: **all 58**, because
most subjects resolve through `WORK_STATE` / `DELIVERY_STATE` / `TASK_STATE` (`:55-57`), each pinned
to a `canonical/aid/templates/*-state-template.md` path FR-3 renames; the exceptions resolve
`DOGFOOD_WORK_STATE` (`:61`) or `FIRST_RUN` (`:62`), plus WS08 which resolves its subject inline via
`find "$REPO_ROOT/profiles"` (`:167`). `PROFILES_DIR` (`:63`) is dead and resolves nothing.

Content-level -- **eight**:

| Assertion | What breaks |
|---|---|
| WS01 (`:66-71`) | Asserts the `## Pipeline State` heading, which `§D-4` retires |
| WS02 (`:81-86`) | Four bold-line field checks (`**Phase:**`, `**Updated:**`, `**Block Reason:**`, `**Block Artifact:**`); its three frontmatter-key checks (`:88-93`) survive |
| WS05 (`:126-129`) | Asserts the whole `active_skill:` line with the `aid-{skill}` / `none` enum hint as the key's value; the hint moves into a full-line comment |
| WS08 | The same `## Pipeline State` heading in every rendered profile tree |
| WS12 | `## Cross-phase Q&A` heading in `delivery-state-template` |
| WS13 | `## Tasks State` heading |
| WS15 | `## Quick Check Findings` heading |
| WS16 | `## Dispatch Log` heading |

Surviving in substance, moving only in path: WS03, WS04, WS10, WS14 (enum members and mutable-cell
keys, preserved byte-for-byte by `§D-2`), WS05's first assertion (`:122-125`, the bare
`aid-{skill}` substring, which survives inside the new full-line comment), WS07 (`:61`, dogfood path
only), WS09's two negative `Status` greps (`:185-199`, which still pass against a heading-less
`.yml`; two of the five templates it iterates are never converted), WS19/WS20 (`aid-describe` seed
prose, changing only where it names the retired markdown fields).

### 5.3 The remaining in-scope bash suites

| Suite | Path-level count | Content-level / inverting entries, by unit/test id |
|---|---|---|
| `test-disjoint-merge.sh` | 23 | `DM01` ("Zero git merge conflicts on all STATE.md files", `:406`) -- subject set becomes the `.yml` files; `DM04` ("Work-level STATE.md not modified by delivery branches", `:469`) -- byte-equality substance survives, subject moves; `DM05` ("Cross-phase Q&A is per-delivery (SD-5 partition)", `:491`) -- **content**: the partition is no longer a `##` section but a `cross_phase_qa` sequence; `DM02`/`DM03` path-level; `DM06` (real-HOME leak canary) unaffected |
| `test-delivery-gate-aggregate.sh` | 21 | Fixture (`:47-67`) builds `## Tasks Status`, `## Delivery Gates`, `## Quick Check Findings`, `## Lifecycle History` -- **all four headings retired**, so Tests 1-8 all rebuild against keys; **Test 7** (`RECORD -- --delivery-id --block writes ## Delivery Gate into deliveries/delivery-NNN/STATE.md`) is the content-level entry: the written artifact becomes `delivery_gate.*`; Test 5 (loopback guard) and Test 6 (FR6 interlock, reads task `Failed`/`Blocked`) move to `tasks_lifecycle.task-NNN.state`; Tests 3/4 (SCORE, grade.sh) are path-level only -- `grade.sh` itself is unmodified (AC-7) |
| `test-task-state-transitions.sh` | 16 | The driver loop (`:261`) runs four transitions -- `Pending`, `In Progress`, `In Review`, `Done` -- each asserting four things. **Content-level: the four `writer: ### Tasks lifecycle row -> <value>` assertions** (`assert_transition`, `:212`), which assert `\| ${expected} \|` -- a markdown **table row** that becomes a `tasks_lifecycle.task-001.state` key. Path-level: the four `writeback-state.sh --field State --value "<v>"` exit-zero assertions (`:264`) and the eight reader-twin assertions (`python read_repo() surfaces -> <v>` `:231`, `node readRepo() surfaces -> <v>` `:245`) |
| `test-pipeline-status-walkthrough.sh` | 163 | Part A ("Lifecycle SM walk-through", `:84`) -- the helper at `:30` builds a state file with **no `## Pipeline Status` section** and `:53` pins `AID_STATE_FILE`/`AID_LOCK_DIR` to its directory: the "section absent -> created" premise becomes "key absent -> created", so every Part A assertion is content-level at the section/key boundary. Part B ("Wiring-level C4 static assertions", `:321`) is path-level: it greps skill/recipe text that FR-8 retargets |
| `test-delete-pipeline.sh` | 50 | **Unit 7** (`Running` guard: `lifecycle=Running` refuses deletion, exit 7, `:168`) is the AC-13a behavioral oracle -- it must stay green **through** the `_frontmatter_value` fence removal, so it is an entry only at the fixture-path level, and a *failure* here is the § L-10 safety defect, not a change-set item. **Units 14/15/16** (reconcile-winner on newest `updated`, `:326`/`:347`/`:368`) read the `updated` scalar -- path-level. **Unit 17** (non-git degrade, `:392`) and **Unit 11** (symlink containment, `:258`) build state files -- path-level. Units 1-6, 8-10, 12, 13, 18: path-level via the `:84` fixture helper |
| `test-housekeep-workfolder-safety.sh` | 20 pass / 1 fail | Units 1-12 all read the work state file. **Content-level: Unit 4** ("no `STATE.md` -> offered, gate=explicit-confirm") and **Unit 5** ("no PR/no SHA in `STATE.md`") -- the "absent state file" premise must be restated for the new filename, and a *stale legacy* `STATE.md` becomes a third, new case. **Unit 9** ("stale `## Housekeep Status` block in a work folder") is content-level: that block becomes a key. Unit 10 is the environment-local failure of § 2.2 and is **not** a change-set entry |
| `test-aid-migrate.sh` | no baseline (`rc=124`) | Gates 5a/5b are era-**b** `.aid/STATE.md` / `DISCOVERY_STATE.md` discovery-era artifacts, **not** work state, and are UNCERTAIN as entries -- see § 5.6 Q1. The definite entries are **additive**: a new gate for the FR-9 work-state conversion, plus Gate 6's idempotency ("second run byte-identical no-op") extended to it |
| `test-aid-migrate-trigger.sh` | 60 | `:462`'s TRG case keys on "a repo with `.aid/.aid-manifest.json` but NO `settings.yml` and NO `knowledge/STATE.md`" -- that path is the KB ledger, so **no entry**; the definite entry is additive: the lazy-stamp encounter must also fire for a legacy work-state tree |
| `test-release-migrate-smoke.sh` | 4 pass / 2 fail | **No state-file or template string today** (0 hits). Entries are additive only: `RMS-NPM-01` / `RMS-PYPI-01` extended to assert the work-state conversion ran as an install side effect. See § 5.6 Q2 |
| `test-aid-cli-parity.sh` | no baseline (`rc=124`) | **No `STATE.md` reference today**; its 50 `STATE` hits are `AID_STATE_HOME`. Entries are additive: bash/ps1 parity for whatever `aid migrate` surface FR-9 adds. See § 5.6 Q2 |
| `test-shortcut-engine-contract.sh` | 24 | **No `STATE`/template string today** (0 hits both). `SEC08a-c` assert verb-to-family binding, not state. Entry is additive at most. See § 5.6 Q2 |
| `test-connector-consumption-linkage.sh` | 56 | **Content-level: `CL08c`, `CL08d`, `CL08e`** -- assert `ticket_ref` in all three `*-state-template.md` files; the three path constants at `:60-62` are the mechanical part, the key's new position in a one-zone document the semantic part |
| `test-ticket-retirement-structural.sh` | 98 | **Content-level: `T087`, `T088`, `T089`** -- the same three template paths at `:93-95` |
| `test-cutover-no-dangling.sh` | 31 | **Content-level: `CND12a`, `CND12b`** (`:124-130`) -- resolve `work-state-template.md` and assert the **absence** of two `##` headings; with no headings at all in the `.yml`, both assertions become vacuous and must be restated as key-absence, not left to pass trivially |
| `test-describe-full-only.sh` | 54 | **Content-level: the `:233` fixture builder** and every assertion over it -- it hand-authors an "all sections Pending" markdown work state carrying `## Pipeline State` / `## Interview State`, exactly the shape FR-2b retires |
| `test-connector-secret-ac3-leak-sweep.sh` | 11 | **Content-level: `T1`, `T2`, `T3`'s `<label>: sentinel absent from every STATE.md under .aid/`** (`:132`), fed by the live glob `find "${REPO_ROOT}/.aid" -iname 'STATE.md' -type f` (`:131`). Retarget or the sweep matches zero files and the security assertion passes vacuously -- a silent loss of coverage, not a visible failure |
| `test-triage-routing.sh` | 67 | **Content-level: `TR02b`** (`:85-87`, directive-verb pairing with `.aid/work-*/` or `STATE.md`) and **`TR02d`** (`:90`, `assert_output_contains "$SKILL_TXT" "no \`STATE.md\`"`) -- both grep skill prose FR-8 rewrites |
| `test-graph-source-enumeration.sh` | 250 | **Content-level: `R-EXCL-03`** (`:997`, `assert_row_absent NA "int:.aid/works/w1/STATE.md"`), fed by the fixture at `:338`. Unretargeted the row id no longer exists and the exclusion assertion passes vacuously |
| `test-write-control-signal.sh` | 50 | **`U26`** (`:266`) -- "stop/resume never touch STATE.md (byte-unchanged)"; substance survives, subject moves. Byte-equality must **not** weaken to key-equality |
| `test-work-initiation-gate.sh` | 94 | Fixture builder `:118-134` writes frontmatter state files as routing inputs -- path-level for all 94; content-level only where the gate reads `phase`/`lifecycle` from a *fenced* block |
| `test-housekeep-state.sh` | 43 | Helper at `:50` creates a state fixture with **no `## Housekeep Status` section**; that section becomes a key, so the "section absent -> created" premise is content-level. **Unit 19** ("`STATE.md` file not found -> exit 1") restates for the new filename, and a legacy `STATE.md` present becomes a new case |
| `test-housekeep-classify.sh` | 24 | `:211` -- "this work folder has no `STATE.md` -> signal(i) fails -> not offered"; content-level for the same reason as Unit 19 above |
| `test-housekeep-deletion-split.sh` | 17 | `:274` seeds `Deployed`+SHA state files so signals pass -- path-level |
| `test-worktree-lifecycle.sh` | 116 | `:253-254` -- an **untracked** work state file; path-level, and the "never git add/commit" comment must survive |
| `test-connector-set-unset-lifecycle.sh` | 56 | `:104`'s `.aid/other-work/STATE.md` sentinel is a work-folder path -- path-level, retarget for fidelity; `:102`'s `.aid/knowledge/STATE.md` sentinel must **not** move |
| `test-deploy-monitor-repurpose.sh` | 58 | **Content-level: `DMR22`** and the `:257` assertion `assert_file_contains "${FIXTURE_DIR}/STATE.md" "**Lifecycle:** Paused-Awaiting-Input"` -- a bold-line field the conversion retires; fixture at `:188` |
| `test-downstream-worktree-entry.sh` | 60 | **Content-level: `G2`** (`:174`, "pointer precedes `## State Detection` (STATE.md read)") and the `:190` item-3 assertion ("Read work `STATE.md`") -- both grep skill prose FR-8 rewrites |
| `test-create-family-scaffold.sh` | 64 | **Content-level: `CFS35`** (Active Skill), **`CFS45`** (Delivery Lifecycle State is Specified), **`CFS46`** (Pipeline Lifecycle is Paused-Awaiting-Input) -- bold-line/section reads over the `:443`/`:729` fixtures |
| `test-change-refactor-family-scaffold.sh` | 142 | **`CRF43`**, **`CRF55`**, **`CRF56`** -- same three shapes; fixtures `:652`, `:991` |
| `test-document-family-scaffold.sh` | 119 | **`DFS24`**, **`DFS34`**, **`DFS47`**, **`DFS48`** -- same class; fixtures `:426`, `:679` |
| `test-fix-family-scaffold.sh` | 57 | **`FFS36`** (Active Skill), **`FFS42`** ("`tasks/<t>/` has no sibling `STATE.md`" -- a **negative** assertion that goes vacuous unless retargeted), **`FFS45`**, **`FFS46`**; plus `:442`'s `assert_file_contains "${DEFECT_DIR}/STATE.md" "**Active Skill:** aid-fix"` |
| `test-prototype-family-scaffold.sh` | 75 | **`PFS24`**, **`PFS35`**, **`PFS46`**, **`PFS47`** -- same class; fixtures `:426`, `:700` |
| `test-test-experiment-family-scaffold.sh` | 98 | **`TEF43`**, **`TEF55`**, **`TEF56`** -- same class; fixtures `:405`, `:693` |
| `test-dashboard-parity-h.sh` | 0 pass / 1 fail | The `/r/<id>/<workfolder>/STATE.md` route fixture (`:14`, `:21`) carrying literal U+2028/U+2029 -- path-level. `PT-1-H` is the environment-local failure of § 2.2, **not** a change-set entry |
| `tests/lib/pt1h_r7_check_state.py` | (library, no own summary) | Reads the same U+2028/U+2029 fixture (`:8`, `:10`) -- path-level |

### 5.4 The in-scope python / mjs suites

Path-level counts are test-function counts (`def test_`), not assertion counts.

| Suite | Tests | Content-level / inverting entries |
|---|---|---|
| `reader/tests/test_work003_state_schema.py` | 57 | **The heaviest content-level entry in the python lane.** `§L-3` deletes the markdown state parsers, so the classes whose whole subject is the dual/legacy format must be **deleted or rewritten, not retargeted**: `TestParseStateMdDualFormat` (`:341`), `TestParseTaskStateDualFormat` (`:524`), `TestParseDeliveryStateDualFormat` (`:569`), `TestParseHeaderBoldField` (`:199`, the `**Field:**` reader), `TestPhaseTask010Migration` (`:428`). `TestParseKbStateDualFormat` (`:445`) must **stay** -- the KB ledger is out of scope. `TestParseFrontmatterScalars` (`:72`) generalises from a fenced block to a whole document. `TestParseBoolYesno` (`:179`) must stay as-is (NFR-2 keeps the `yes/no/on/off` tolerance). `TestCrossTwinParity` (`:780`), `TestResolveKind` (`:218`), `TestWorkPathFromPipeline` (`:636`), `TestManifestRegistration` (`:1027`): path-level. **Deleted tests are "newly missing", which SP-16 must treat as enumerated changes, not as an oracle gap** |
| `reader/tests/test_derivation.py` | 69 | `TestFallbackHelpers` (`:723`) and `TestFallbackIntegration` (`:908`) exist for the "no `## Pipeline Status` block -- fallback only" text fixtures (`:69`); that fallback path is what `§L-3` removes, so these two classes are content-level. `TestDerivationSM2` (`:288`) and `TestRollupSM3` (`:599`): path-level |
| `reader/tests/test_work001_delivery_layouts.py` | 18 | `TestLiteFlatLayout` (`:306`), `TestFullNestedLayout` (`:408`), `TestBothLayoutsNodeParity` (`:486`) -- path-level via the fixture builders; content-level wherever a fixture writes a `### Tasks lifecycle` **table** rather than frontmatter |
| `reader/tests/test_task014_fixtures.py` | 77 | Path-level via the hierarchical fixture builder; three tests are already `environment-local` red (§ 3) and must not be read as regressions. It is also the "full layout" leg of AC-2 |
| `reader/tests/test_flattened_layout_parity.py` | 11 | Path-level; **additive**: this suite is the specified home for the AC-2 golden-master legs (a)/(b)/(c), reusing its fixture builder and `subprocess` Node invocation |
| `reader/tests/test_integration.py` | 15 | `TestProducerConsumerRoundTrip` (`:128`) -- the writer-to-reader round trip; path-level, but each round trip's *written artifact* changes shape with `§L-2`. `TestIntegrationModuleSelfCheck` (`:533`): path-level |
| `reader/tests/test_reader.py` | 117 | All 117 flow through the single fixture writer at `:112` -- one-line path change, 117 path-level assertions. `TestLocator::test_paths_computed_correctly` is already `environment-local` red (§ 3) |
| `reader/tests/test_fixtures.py` | -- | Fixture 9 ("malformed/torn state file -> `parse_warning`, never aborts") is content-level: the torn-document corpus must be re-authored as torn **YAML**; AC-5 requires the warning to name the file |
| `reader/tests/test_task011_reconcile.py` | -- | `_state_md()` (`:99`) becomes `_state_yml()`; content-level for any assertion over prose lines |
| `reader/tests/test_task069_detail_parser.py`, `test_task029_stop_requested.py`, `test_feature009.py`, `test_work016_container_discovery.py`, `test_security_hardening.py`, `test_task002_resolve_work_dir.py`, `test_task008_display_rename.py`, `test_resolve_work_dir_cross_runtime_parity.py` | -- | Path-level via their fixture writers (`:92`, `:12`, `:241`, `:118`, `:13`, `:15`, `:13`, `:118`). Two content-level exceptions: `test_task029_stop_requested.py`'s flat-layout leg reads the `### Tasks lifecycle` **table**, and `test_task002_resolve_work_dir.py`'s "no state file still counts as a candidate" (`:15`) must additionally cover a *legacy* `STATE.md` present |
| `server/tests/test_task033_execution_control_round_trips.py` | -- | **Inverting**: `:44` asserts over "the `STATE.md` **BODY** text -- everything after the closing `---` fence". A one-zone document has no body, so this assertion cannot be retargeted -- it must be restated (FR-4a's "every pre-existing line reproduced") or removed |
| `server/tests/test_task012_consuming_round_trips.py` | -- | `:27` asserts the **raw state-file substring**; content-level (the substring changes shape) |
| `server/tests/test_task025_pipeline_delete_ops.mjs`, `test_task029_task_stop_resume_ops.mjs` | -- | `:148` / `:145` write `---\nlifecycle: ${lifecycle}\n---\n` -- the fence goes away; content-level, small |
| `server/tests/test_task027_pipeline_delete_round_trips.py` | -- | `:26`'s 409 guard on `lifecycle=Running` -- the round-trip twin of `test-delete-pipeline.sh` Unit 7 and of AC-13a; path-level, must stay green |
| `server/tests/test_server_node.mjs`, `test_reader_task069.mjs`, `test_task011_dispatch_round_trip.{py,mjs}`, `test_task008_display_rename.py`, `test_task010_task_notes.py`, `test_task010_task_notes_cross_runtime_parity.py`, `test_task002_resolve_work_dir.mjs`, `test_task004_op_dispatch.py`, `test_task025_pipeline_delete_ops.py`, `test_task029_task_stop_resume_ops.py`, `test_server_py.py` | -- | Path-level via their fixture writers (`:126`, `:63`, `:102`/`:129`, `:23`, `:64`, `:118`, `:19`, `:96`, `:99`, `:34`, `:125`). `test_server_py.py` carries five `environment-local` failures (§ 3) |
| `server/tests/test_index_html.py` | -- | `:920`'s `'.aid/' + workId + '/STATE.md'` fallback is comment-level; **no assertion inverts** |
| `server/tests/test_write_enabled_cross_runtime_parity.py` | 2 | **Additive**: the `§L-11` write-path property (AC-13b) -- both runtimes must resolve the same writer source path |

### 5.5 Enumeration totals

- **44 in-scope suites/files carry change-set entries** (36 bash + `pt1h_r7_check_state.py` + 7
  python/mjs groups as tabled above; the 35 dashboard test files are enumerated individually or in
  named path-level groups).
- **Individually named assertions / unit ids: 120.** Counting the named ids above: Units 1-24 of
  `test-writeback-state.sh` (24, of which Unit 14's four assertions are named individually -> 27
  named items), WS01-WS20's 16 live ids, `DM01`-`DM06` (6), Tests 1-8 of
  `test-delivery-gate-aggregate.sh` (8), four transitions x `assert_transition` (4),
  `test-delete-pipeline.sh` Units 7/11/14/15/16/17 (6), `test-housekeep-workfolder-safety.sh`
  Units 4/5/9 (3), `CL08c-e` (3), `T087-T089` (3), `CND12a-b` (2), `TR02b`/`TR02d` (2), `T1`/`T2`/`T3`
  (3), `R-EXCL-03` (1), `U26` (1), Unit 19 of `test-housekeep-state.sh` (1), `G2` (1), `DMR22` (1),
  `CFS35/45/46` (3), `CRF43/55/56` (3), `DFS24/34/47/48` (4), `FFS36/42/45/46` (4), `PFS24/35/46/47`
  (4), `TEF43/55/56` (3), and 12 named python test classes.
- **Path-level totals, from the suites' own summary lines: 2,214 bash assertions** across the 30
  green in-scope bash suites, plus 24 for `test-housekeep-workfolder-safety.sh` and
  `test-release-migrate-smoke.sh`, plus **two in-scope suites with no baseline at all**
  (`test-aid-cli-parity.sh`, `test-aid-migrate.sh`).
- Python lane: 364 `def test_` functions across the eight suites SPEC names, plus the remaining 27
  in-scope dashboard test files.

### 5.6 Open questions this enumeration could not settle

Both are recorded here rather than guessed, because a guess would corrupt the oracle. Neither blocks
task-019; both are inputs to task-015.

- **Q1 -- `test-aid-migrate.sh` Gates 5a/5b.** Their `STATE.md` references are the era-**b**
  `.aid/STATE.md` and `DISCOVERY_STATE.md` discovery-era artifacts (`:20`, `:22`), not work state.
  `SPEC.md § L-9` lists the suite as in-scope, but whether *those two gates* change is UNCERTAIN. If
  they do not, the suite's only entries are additive.
- **Q2 -- three suites with no textual dependency at all.**
  `test-shortcut-engine-contract.sh`, `test-release-migrate-smoke.sh` and `test-aid-cli-parity.sh`
  contain zero references to any state filename, state shape or template name (§ 4.1). They are
  in-scope per `SPEC.md § L-9`, but their entries can only be **additive**, and it is UNCERTAIN
  whether they need editing at all. Listing them as "will change" without this caveat would let a
  genuine regression in one of them be waved through as an intended update -- the exact failure mode
  the enumeration exists to prevent.

### 5.7 task-015 addendum: an unlisted change, recorded per SP-16

Not a test-format retarget -- a production defect in the already-shipped writer, discovered while
building `test-writeback-state.sh`'s new oracle and confirmed against the real templates before any
test assertion was written to cover it (`known-issues.md` KI-010 carries the full root cause):
`canonical/aid/scripts/execute/writeback-state.sh`'s `WB_GET_KV_AWK` sanity-check read-back died at
exit 3 on every non-empty `quick_check.findings` / `delivery_gate.issue_list` write -- the ordinary
case in both shipped templates, not an edge case -- because a stale rule preempted the sequence's own
boundary detection. The write path itself was always correct; only the verify-and-die guard was wrong.
Left unfixed, this made Units 2/3/25 of `test-writeback-state.sh` and Test 7 of
`test-delivery-gate-aggregate.sh` unwritable as passing, real assertions -- weakening them to avoid
the bug would have been exactly the "half-retargeted guard is a silent no-op" failure mode `SPEC.md
§ L-10`/SP-19a warns against, just relocated to a different unit. Fixed with a single added condition
(`&& !collecting`); identical fix applied to the `dashboard/scripts/writeback-state.sh` fork (same
code, independently forked, no profile-render path covers it); the five profile renders regenerated
via the FULL `run_generator.py` and the `.claude/`/`.cursor/` dogfood trees resynced for this one file
only. No other canonical file was touched. Recorded here, not guessed past, per SP-16's own rule: an
unlisted change is indistinguishable from a regression unless it is named.

A second, unrelated addendum: `test-shortcut-engine-contract.sh` SEC01 asserted
`--default A+`; `canonical/aid/templates/shortcut-engine.md` reads `--default A` (commit
`d149ddc1`, an owner-approved pre-existing edit unrelated to task-010/task-015 -- "not
investigated further by request"). Not a state-format change, but SEC01 was red for this
reason alone and this suite is in this task's Scope, so the assertion is retargeted to
match the approved value (`A+` -> `A`) rather than left failing for an unrelated cause.

A third addendum, spanning four in-scope suites (`known-issues.md` KI-011 carries the full
root cause): `test-aid-migrate.sh`, `test-aid-migrate-trigger.sh`, `test-release-migrate-smoke.sh`
and `test-aid-cli-parity.sh` all carried assertions hardcoding the OLD `format_version: 3` stamp
value from before task-008 bumped `AID_SUPPORTED_FORMAT` to 4 (a prior, already-shipped change,
unrelated to task-015's own work). Two shapes: plain staleness (the migrated-stamp checks, which
simply expected a value the tool no longer writes) and, in `test-aid-cli-parity.sh` only, a
genuinely INVERTED oracle (PAR080-S03/S04's "format-current, no WARN" fixture and
PAR009-V02-V06/PAR029-W11-W15's "refuse-on-newer" fixtures both keyed off the number 4, which
meant opposite things before vs. after the bump). All four in-scope files are fixed here (each
retargeted value confirmed either by direct probe against `bin/aid __migrate-repo`, or by
re-reading `_aid_format_gate`'s 3-way classify logic line-by-line before editing the fixture).
`test-aid-cli-parity.sh` PAR077-C08 (a PS1-parity assertion that had never been implemented --
an unconditional `pass()` stub with a note explaining it was "OOS") is also promoted to a real
PWSH invocation, since `bin/aid.ps1` now ships its own conversion-engine twin. The SAME bug class
exists, unfixed, in four suites outside this task's enumerated Scope (`test-registry.sh`,
`test-install-provisioning.sh`, `Test-InstallProvisioning.ps1`, `Test-AidInstaller.ps1`) --
left untouched deliberately (editing an unlisted file is itself a scope defect) and flagged in
KI-011 as a follow-up.

A fourth addendum, in `test-disjoint-merge.sh` (retargeted to `.yml` per this task's normal
scope, so these two are content-level fixes within an already-in-scope edit, not new files):
(a) DM03e's expected `elapsed: 8m` never accounted for D-5/NFR-2's quoting rule (a value starting
with a digit is single-quoted even when not a pure number) -- corrected to `elapsed: '8m'`.
(b) DM06's real-HOME leak canary compares a `find`-under-`$HOME` snapshot before/after; on a host
where the OS temp dir lives under `$HOME` (this environment: Windows, `%TEMP%` under
`%USERPROFILE%\AppData\Local\Temp`), every throwaway `.aid/` this suite creates BY DESIGN inside
its own `$TMP` sandbox is *also* discovered by that same recursive find, indistinguishable from a
real leak -- a false positive present in the ORIGINAL (pre-task-015) canary too, just never
triggered in whatever environment last exercised it clean. Fixed by excluding paths under `$TMP`'s
own basename from the AFTER snapshot (a basename match, not a path-prefix match, because
MSYS/cygwin `mktemp` and `find` report the SAME physical directory via two different string forms
-- `/tmp/tmp.XXXXXX` vs. `/c/Users/<user>/AppData/Local/Temp/tmp.XXXXXX` -- on this platform).

---

## 6. Coverage re-bootstrap marker (for task-019)

`tests/coverage-baseline.tsv` is **re-bootstrapped wholesale, never row-edited**
(`SPEC.md § L-9`): this is a corpus-wide change, and its 87 `STATE.md` references are a symptom of
that, not a work item. The coverage-parity gate enforces as soon as its baseline file is present, so
the re-bootstrap is part of the change, not a follow-up.

Pre-refactor state, as of this capture:

| Marker | Value |
|---|---|
| `tests/coverage-baseline.tsv` line count | **8867** |
| `tests/coverage-baseline.meta` header | `# coverage-parity baseline provenance (auto-generated -- do not edit)` |
| `captured_utc` | `2026-08-07T17:46:27Z` |
| `commit_sha` | `5afdeaf604dd2ce6e34d91f720dacab1f4ab2b5a` |
| `runner_os` | `Linux 6.17.0-1020-azure x86_64 GNU/Linux` |
| `pwsh_version` | `7.6.3` |
| `node_version` | `v20.20.2` |
| `python3_version` | `Python 3.11.15` |

Note for task-019: the baseline was captured on **Linux** by CI, not on this host, and the gate
reports **count-deltas** -- so `added - reduced` is not the meaningful delta. Compare the two TSVs
directly (e.g. `comm`) rather than trusting the summary counts, and re-bootstrap rather than
accepting rows.

---

## 7. Harness findings -- recorded, NOT fixed

Both are out of scope for this work and belong in `.aid/knowledge/tech-debt.md`. This task does
**not** edit that file, `tests/run-all.sh`, or the suite named in (b).

### (a) `tests/run-all.sh` at its shipped default parallelism yields false failures on this host

`:122` defaults `AID_TEST_JOBS` to `$(nproc)`, while `:121`'s own comment states the budget is
"bounded by the runner (ubuntu-24.04 ~= 4 vCPU)". On a 22-core developer host the default is `-P 22`
and five suites fail spuriously -- including `test-writeback-state.sh`, the writer's own unit
harness, which passes standalone with `Tests passed: 360` / `Tests failed: 0`. Evidence: the `-P 22`
run's own summary line reports `29 of 149 CANONICAL SUITES FAILED`; `-P 4` reports 24 non-green; the
difference is exactly those five. Consequence: a developer running the documented command on a
many-core machine sees five red suites that are not red, and the one most likely to be
mis-attributed is the state writer's.

### (b) `test-pypi-installer.sh` writes a pip HTTP cache into the repo tree

The suite deposited a pip HTTP cache at `packages/pypi/pip/` -- inside the repository -- instead of a
temp dir. 604K of it was removed to restore a clean tree before this baseline was captured
(`packages/pypi/` now contains only `LICENSE`, `README.md`, `aid_installer`, `pyproject.toml`,
`scripts`). Consequence: a test run dirties the working tree, which can defeat a byte-identity or
render-drift gate and can be mistaken for a real diff.

Neither finding is a state-format issue and neither is repaired here.

---

## 8. Acceptance-criteria self-check

| AC | Status | Note |
|---|---|---|
| AC-1 baseline document with per-suite name, own summary counts, per-test pass/fail set | Satisfied, with one stated limit | § 2.1 (149 suites), § 2.2 (per-test failure sets), § 3 (pytest, all 17 named). Limit: the 9 `timeout-local` suites have **no** per-test set, and pytest's 14 skips are reported by pytest only as a count -- both stated rather than invented |
| AC-2 every count quoted from the suite's own summary line; timeouts recorded, not counted | Satisfied | Counts come from each suite's `Tests passed:` / `Tests failed:` lines; `rc=124` and the two `rc=1` suites that print no summary are recorded as "emits no summary line" |
| AC-3 capture before any edit | Satisfied | § 1.3: `git status --porcelain` showed only `.aid/works/work-009-refactor/STATE.md` |
| AC-4 every inventory file classified, with the named MUST-NOT-EDIT set honoured | Satisfied | § 4: 91 files, 73 IN-SCOPE / 18 MUST-NOT-EDIT; the five discovery-ledger suites, `test-migrate-hierarchy.sh` and the whole `work-999-migration-test` tree are MUST-NOT-EDIT |
| AC-5 change-set enumerates each assertion by suite + unit/test id, incl. Unit 14's inverting `\|` rejection | Satisfied | § 5; Unit 14's four assertions named individually in § 5.1. Two UNCERTAIN suites are flagged in § 5.6 rather than asserted |
| AC-6 coverage baseline row count + `.meta` recorded | Satisfied | § 6 |
| AC-7 no product code, test, template, script or doc modified | Satisfied | Only this file was written |
| AC-8 no permanent artifact cites the baseline | Satisfied | Stated at the head of this document; the only references to it are in this work folder's own definition documents |
| Section-6 quality gates | Not applicable as written | This task's `DETAIL.md` has no section 6 -- the file ends at `**Acceptance Criteria:**` (99 lines). Recorded rather than silently treated as passing |
