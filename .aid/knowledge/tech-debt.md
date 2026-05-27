# Tech Debt

> **Source:** `discovery-quality` (Phase 1), cycle-1
> **Status:** Complete
> **Last Updated:** 2026-05-27

> This document is a diagnosis, not a sprint plan. Severity tags use the form `[CRITICAL]` / `[HIGH]` / `[MEDIUM]` / `[LOW]` so `build-metrics.sh` (see `canonical/templates/knowledge-base/tech-debt.md:19-23`) can tally them.

---

## Summary

**Overall debt level: Medium**, leaning High in a single direction (no automation gate). Rationale: the codebase itself is well-organized (Thin-Router skill convention, canonical/ as single source of truth, 297-test canonical suite) but operates with **zero pre-merge automation** and several **stale references in load-bearing docs** (CLAUDE.md, run_generator.py) that point at directories that don't exist on the current branch. There is **one Critical** item: the supply-chain risk in `fetch-mermaid.sh` materially affects end users.

| Severity | Count | Items |
|----------|-------|-------|
| Critical | 1 | C1 |
| High | 3 | H1, H2, H3 |
| Medium | 4 | M1, M2, M3, M4 |
| Low | 3 | L1, L2, L3 |

---

## Debt Inventory

| ID | Type | Description | Location | Risk | Effort | Priority |
|----|------|-------------|----------|------|--------|----------|
| C1 | Supply Chain | `fetch-mermaid.sh` fetches `mermaid@latest` from npm registry with no version pin and no SHA verification | `canonical/scripts/summarize/fetch-mermaid.sh:16-18, 41, 59-73` | Critical | S | P1 |
| H1 | Doc Drift / Untestable Claim | CLAUDE.md cites two e2e test runners in `.aid/work-001-aid-lite/test-reports/` that do not exist on disk on `kb-overhaul` branch; their 35+38 = 73 tests inflate the "297 expected" total | `CLAUDE.md:48-49`; disk: `.aid/work-001-aid-lite/` missing | High | S | P1 |
| H2 | No CI | Zero pre-merge automation; every test/verify pass is manual | repo-wide; documented at `CLAUDE.md:52` | High | M | P2 |
| H3 | Supply Chain (sibling of C1) | No language lock files exist (`package-lock.json`, `requirements.txt`, etc.) — vulnerability scanning is impossible | repo-wide; absence confirmed in `project-structure.md:96` | High | M | P2 |
| M1 | Doc Drift | `run_generator.py` writes VERIFY-4a/4b reports to `.aid/work-002-canonical-generator/` which does not exist; the script either crashes on first invocation or silently creates the dir without recording its purpose | `run_generator.py:76, 83`; disk: `.aid/work-002-canonical-generator/` missing | Medium | S | P2 |
| M2 | Doc Drift | Project name expansion drift — `CLAUDE.md:5` says "Agentic Implementation Discipline" but `.aid/settings.yml:16` says "AI Integrated Development"; per user memory the canonical answer is the latter | `CLAUDE.md:5` vs `.aid/settings.yml:16` | Medium | XS | P2 |
| M3 | Gitignore Fragility | `.aid/.temp/` is excluded only by the `*.temp` glob at `.gitignore:21`, not an explicit dir entry — a rename to e.g. `.aid/scratch/` would silently start tracking it | `.gitignore:18-21` | Medium | XS | P3 |
| M4 | Test Discoverability | No aggregator script: each of the 8 test suites must be invoked manually with the right path; no way to run "all tests" with one command | `CLAUDE.md:42-49` (lists each separately); no `Makefile`/`task`/`npm test` | Medium | S | P3 |
| L1 | Source Bloat | 5 files >500 lines under canonical/methodology (largest: `methodology/aid-methodology.md` 1,071, `tests/canonical/parse-recipe.sh` 1,002, `canonical/scripts/kb/verify-claims.sh` 695, `canonical/scripts/execute/writeback-task-status.sh` 627, `canonical/skills/aid-execute/references/state-execute.md` 629) | various | Low | M | P3 |
| L2 | Test Coverage Gap | Zero tests for PowerShell paths (`setup.ps1`, `concatenate.ps1`), `.mjs` validators, and the `setup.sh` install flow | `test-landscape.md` Gaps section | Low | L | P3 |
| L3 | Allowlist Breadth | `.claude/settings.json` Bash allowlist includes broad `Bash(rm *)` and `Bash(python *)` without path scoping | `.claude/settings.json:5-14` | Low | XS | P3 |

---

## Detailed Debt Items

### [CRITICAL] C1 — Mermaid CDN fetch not version-pinned or SHA-verified

**Type:** Security / Supply Chain
**Evidence:**
- `canonical/scripts/summarize/fetch-mermaid.sh:16-18` queries `https://registry.npmjs.org/mermaid/latest` on every invocation, extracting whatever version is current.
- `canonical/scripts/summarize/fetch-mermaid.sh:41` downloads `https://cdn.jsdelivr.net/npm/mermaid@${LATEST}/dist/mermaid.min.js` — no pin.
- `canonical/scripts/summarize/fetch-mermaid.sh:59-73` computes sha256 AFTER download and stores it as cache metadata; there is no `EXPECTED_SHA256` constant compared at verification time.

**Impact:** Every end user who runs `/aid-summarize` receives whatever JS the npm registry serves at fetch time. An npm-registry compromise or jsDelivr MITM silently ships compromised JS into the offline KB viewer that the end user opens in their browser. Reproducibility is also broken — diagrams may render differently across runs.

**Fix recipe (estimated S effort):**
1. Add a constant near the top of the script: `PINNED_VERSION="<chosen-version>"` and `EXPECTED_SHA256="<sha-from-npmjs>"`.
2. Replace the `curl ... /mermaid/latest | sed ...` block with `LATEST="$PINNED_VERSION"`.
3. After the download (`mv "$CACHE_FILE.tmp" "$CACHE_FILE"`), compute the SHA, then `[ "$SHA" = "$EXPECTED_SHA256" ] || { echo "SHA mismatch"; rm -f "$CACHE_FILE"; exit 1; }`.
4. Add a `# Renovate / Dependabot equivalent` comment block describing the manual bump procedure.
5. Update `tests/canonical/` (or add a new suite) to cover the pin-mismatch path.

**Owner suggestion:** maintainer (single-file change in canonical/, then `python run_generator.py` to propagate to 4 install-tree copies).

---

### [HIGH] H1 — CLAUDE.md cites e2e test runners that do not exist on disk

**Type:** Documentation Drift / Untestable Claim
**Evidence:**
- `CLAUDE.md:48-49` instructs maintainers to run:
  ```
  bash .aid/work-001-aid-lite/test-reports/e2e-two-tier-runner.sh   # 35 tests
  bash .aid/work-001-aid-lite/test-reports/e2e-lite-path-runner.sh  # 38 tests
  ```
- `ls .aid/work-001-aid-lite/` returns `No such file or directory`.
- `CLAUDE.md:42` claims "297/297 expected" but the 73 tests from these two runners are included in that total. Net: even a fully-passing local run would report at most 224/297 with no explanation for the missing 73.
- Likely root cause: PR #17 "remove work" (merged 2026-05-27 per git log) cleaned out the `.aid/work-001-aid-lite/` directory but `CLAUDE.md` was not updated.

**Impact:** Confuses new maintainers; makes the test-count claim falsifiable in a misleading way; reduces trust in CLAUDE.md as a source of truth.

**Fix recipe (estimated S effort):**
1. Either restore the two runner scripts (preferred if they encode E2E logic worth keeping) OR delete `CLAUDE.md:48-49` and update the count on `CLAUDE.md:42` to `224/224 expected`.
2. If the runners are restored, ensure their test counts are re-validated (the 35/38 numbers may be stale).
3. Run `bash canonical/scripts/kb/verify-claims.sh` after the edit to catch any other broken citations.

**Owner suggestion:** the maintainer who ran PR #17; the choice between restore-vs-delete is editorial.

---

### [HIGH] H2 — No CI

**Type:** Process / Automation
**Evidence:**
- No `.github/`, no `.gitlab-ci.yml`, no `Jenkinsfile`, no `azure-pipelines.yml`, no `.circleci/`, no `.travis.yml`, no `bitbucket-pipelines.yml` anywhere in the repo (confirmed by file-system search at scout time).
- `CLAUDE.md:52` explicitly acknowledges: *"There is no CI — see `tech-debt.md` H2."* (this is the canonical H2 reference.)

**Impact:** Every quality gate (canonical helper tests, render-determinism, KB claim verification) is human-discretionary. PR reviewers cannot rely on green-build signal. A regression in `parse-recipe.sh` or `writeback-task-status.sh` only surfaces if the maintainer remembers to run the suite locally before merging.

**Fix recipe (estimated M effort):**
1. Add `.github/workflows/test.yml` that on PR runs (in order): the 6 `tests/canonical/*.sh` suites, the 2 `tests/skills/*.sh` suites, `python .claude/skills/aid-generate/scripts/verify_deterministic.py`, and `bash canonical/scripts/kb/verify-claims.sh`.
2. Add a `Makefile` target `make test` that invokes the same list, so local + CI use the same entrypoint (also addresses M4).
3. Pin GitHub-hosted runner OS (`ubuntu-24.04` not `ubuntu-latest`) for reproducibility.
4. Cache the `mermaid.min.js` between runs once C1 is fixed (so the registry lookup is bypassed).
5. Require status check in branch protection on `master`.

**Owner suggestion:** maintainer + devops agent.

---

### [HIGH] H3 — No language lock files; supply-chain vulnerability scan impossible

**Type:** Security / Supply Chain
**Evidence:**
- No `package.json` / `package-lock.json` despite Node 18+ being required for `aid-summarize` validators (`project-structure.md:96`).
- No `requirements.txt`, `pyproject.toml`, `Pipfile`, `Pipfile.lock` despite Python 3.11+ being required for the generator (`.claude/skills/aid-generate/scripts/harness.py:15`).
- No `Cargo.toml`, `go.mod`, `Gemfile.lock`.

**Impact:** Cannot run `npm audit` / `pip-audit` / `dependabot` / `renovate` against this repo. Vulnerability advisories in any transitive dependency (Mermaid included) are invisible. Compounds C1.

**Fix recipe (estimated M effort):**
1. Add a minimal `package.json` declaring the Mermaid CLI + any dev tooling used by the `.mjs` validators; commit `package-lock.json`.
2. Add a `requirements.txt` (or `pyproject.toml`) listing Python's `tomllib` is stdlib — but if any future dep is added, capture it here.
3. Once present, the CI from H2 can wire in `npm audit --audit-level=high` and `pip-audit` automatically.

**Owner suggestion:** maintainer + security agent.

---

### [MEDIUM] M1 — `run_generator.py` writes to `.aid/work-002-canonical-generator/` which does not exist

**Type:** Documentation / Path Drift
**Evidence:**
- `run_generator.py:76` and `:83` pass `.aid/work-002-canonical-generator/verify-{4a,4b}-report.json` as the report path to `run_verify()` / `run_advisory()`.
- `ls .aid/work-002-canonical-generator/` returns `No such file or directory`.
- The underlying `verify_deterministic.py` / `verify_advisory.py` may auto-create the parent or may fail — not verified in this pass without running the generator.

**Impact:** On a fresh clone the first `python run_generator.py` invocation may either crash on missing parent dir, or silently create a stale-named directory the project no longer documents anywhere else. Either way the path string is a debt artifact from a removed work directory.

**Fix recipe (estimated S effort):**
1. Decide canonical report location: `.aid/generated/verify-reports/` is consistent with the existing `.aid/generated/project-index.md` pattern.
2. Update `run_generator.py:76, 83` to the new path.
3. Add the parent dir to `.gitignore` if reports shouldn't be committed (probably).
4. Run `python run_generator.py` once to confirm clean execution.

**Owner suggestion:** maintainer.

---

### [MEDIUM] M2 — Project name expansion drift between CLAUDE.md and settings.yml

**Type:** Documentation Drift
**Evidence:**
- `CLAUDE.md:5` says *"AID (Agentic Implementation Discipline)"*.
- `.aid/settings.yml:16` says `description: AI Integrated Development`.
- Per user memory (cross-conversation), the canonical expansion is "AI Integrated Development" — the CLAUDE.md text is stale.

**Impact:** Low practical impact (no code reads either string) but undermines the canonical-source-of-truth convention. New contributors will not know which is authoritative.

**Fix recipe (estimated XS effort):** Update `CLAUDE.md:5` to "AID (AI Integrated Development)"; grep for other occurrences with `grep -rn "Agentic Implementation Discipline" .` and update consistently.

**Owner suggestion:** maintainer or any docs contributor.

---

### [MEDIUM] M3 — `.aid/.temp/` gitignore is glob-fragile

**Type:** Configuration / Hygiene
**Evidence:**
- `.gitignore:18-21` excludes `*.temp` as a global glob; `.aid/.temp/` matches by virtue of the suffix.
- `.gitignore:46-47` explicitly excludes `.aid/.heartbeat/`. The asymmetry is suspicious — heartbeat is treated as a first-class dir but temp is not.

**Impact:** If the `.aid/.temp/` directory is ever renamed (e.g., to `.aid/scratch/`, `.aid/workdir/`), files inside will silently begin being tracked by git. A noisy commit will eventually catch it but only after damage.

**Fix recipe (estimated XS effort):** Add an explicit line `.aid/.temp/` to `.gitignore` (modeled on line 47). Optionally remove the `*.temp` glob if no other use exists.

**Owner suggestion:** any contributor; one-line edit.

---

### [MEDIUM] M4 — No aggregator script for test suites

**Type:** Developer Experience / Test Discoverability
**Evidence:**
- `CLAUDE.md:42-49` lists 5+ bash test commands the maintainer is expected to run individually. There is no `make test`, no `npm test`, no `pytest`, no `task test` (no `Makefile` / `package.json` / `pyproject.toml` / `Taskfile.yml` in the repo).
- A new contributor must read CLAUDE.md to enumerate the suites; missing one means partial coverage.

**Impact:** Friction; partial test runs; correlates with H2.

**Fix recipe (estimated S effort):**
1. Add a `Makefile` (or `tests/run-all.sh` aggregator) that invokes every suite in sequence, aggregates PASS/FAIL counts, and exits non-zero on any failure.
2. Update `CLAUDE.md:42-49` to read `make test` (with the long form as fallback).
3. Wire the same target into the CI workflow from H2.

**Owner suggestion:** maintainer.

---

### [LOW] L1 — Five files exceed 500 lines (one exceeds 1,000)

**Type:** Source Size / Complexity
**Evidence (from `wc -l` over `canonical/`, `methodology/`, `tests/`):**
- `methodology/aid-methodology.md` — 1,071 lines (the load-bearing spec; legitimately large)
- `tests/canonical/parse-recipe.sh` — 1,002 lines (113 tests; test-file size is justified)
- `canonical/scripts/kb/verify-claims.sh` — 695 lines
- `canonical/scripts/execute/writeback-task-status.sh` — 627 lines (already tested by 69-test suite)
- `canonical/skills/aid-execute/references/state-execute.md` — 629 lines

**Impact:** None acute. The Thin-Router convention (`CLAUDE.md:111-113`) says SKILL.md should split past ~200 lines, but the `references/state-*.md` files do not have the same threshold. `state-execute.md` at 629 lines may justify further splitting if reviewers find it hard to navigate.

**Fix recipe (estimated M effort, opportunistic):**
- For `state-execute.md`: consider sub-splitting (e.g., `state-execute-pool.md`, `state-execute-review.md`) if specific sections grow further.
- For the shell scripts: extract self-contained functions into `lib/` files; verify behavior unchanged via the existing test suites.

**Owner suggestion:** address opportunistically during feature work in those files.

---

### [LOW] L2 — Test-coverage gaps for PowerShell, `.mjs`, and install flow

**Type:** Test Coverage
**Evidence:** see `test-landscape.md` Gaps section.

**Fix recipe (estimated L effort):** Add `tests/pwsh/` for PowerShell scripts (use Pester or a parallel `pass`/`fail` counter pattern), a `tests/mjs/` directory using `node --test`, and a smoke test for `setup.sh` install into a tmpdir.

**Owner suggestion:** maintainer or devops agent.

---

### [LOW] L3 — `.claude/settings.json` Bash allowlist is broad

**Type:** Configuration / Hardening
**Evidence:** `.claude/settings.json:5-14` permits `Bash(rm *)`, `Bash(python *)`, `Bash(chmod *)` without path scoping.

**Impact:** Acceptable for a maintainer-trusted dogfood environment; would not be acceptable in a multi-tenant setting. Low priority because every Bash invocation by an agent goes through the per-agent `tools:` allowlist first.

**Fix recipe (estimated XS effort, optional):** narrow `Bash(rm *)` to `Bash(rm -rf .aid/.temp/*)` and similar; or accept and document the rationale ("maintainer-trusted scope").

**Owner suggestion:** maintainer; address if the project ever ships a shared/CI-runner-managed instance.

---

## Metrics

- **TODO/FIXME count:** 9 occurrences across 6 files (source: `rg "TODO|FIXME"` over `canonical/`). Specifically:
  - `canonical/agents/discovery-quality/AGENT.md` (2)
  - `canonical/agents/discovery-quality/README.md` (1)
  - `canonical/skills/aid-discover/references/state-generate.md` (1)
  - `canonical/skills/aid-discover/references/agent-prompts.md` (1)
  - `canonical/skills/aid-discover/README.md` (3)
  - `canonical/templates/knowledge-base/tech-debt.md` (1)
  - These are all *template-explanatory* mentions (e.g., "fill in TODO sections"), not unresolved code TODOs. Net **0 unresolved code TODOs**.
- **Files > 500 lines:** 5 (listed in L1)
- **Files > 1,000 lines:** 2 (`methodology/aid-methodology.md`, `tests/canonical/parse-recipe.sh`)
- **Test-to-code ratio (helper-script subset):** ⚠️ **Inferred from file counts.** Lines-of-test for the 6 helpers with dedicated suites (parse-recipe, writeback-task-status, delivery-gate-aggregate, compute-block-radius, pool-dispatch, read-setting) sum to **2,930 lines** of test code against ~2,150 lines of canonical helper code (the same six scripts) — ratio **≈ 1.36×**. Healthy for shell helpers.
- **Open PRs:** 0 (the previously-cited PR #16 "aid-config simplification" merged 2026-05-27 per `git log --oneline -20`). Note: the dispatcher's note referenced PR #16 as "yet to merge" — this is stale relative to the current commit history.
- **Branches behind master:** current branch is `kb-overhaul`; recent merges suggest active KB work.
