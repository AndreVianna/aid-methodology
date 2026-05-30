---
kb-category: primary
source: hand-authored
intent: |
  Known technical debt items in the AID methodology repo: items that work but
  carry future-cost or fragility risk. Each entry has severity (CRITICAL / HIGH /
  MEDIUM / LOW), evidence (file:line), impact, and a resolution roadmap.
  Read when planning the next refactor cycle or scoping a new work-NNN.
contracts: []
changelog:
  - 2026-05-30: H6 RESOLVED + removed — an adversarial audit confirmed the discovery-reviewer prompt already covers verify-claims.sh's former semantic duties (FM presence/validity, contract claims, AUTO-GENERATED header, and intra-file contradiction). The one real gap it surfaced was that volatile `file:LINE` citations were being stored + verified instead of durable grep-recoverable anchors. Fixed by adding P1(d) Positional-citations + P8 Rigor-follows-value to kb-authoring principles, aligning the discovery-* prompts + review rubric, and (P1(a) follow-up) purging volatile inline counts from the KB doc templates. Shipped via PRs #22/#23/#24. High 2→1.
  - 2026-05-29: H3 RESOLVED + removed as Not Applicable — a 4-facet dependency-surface audit confirmed the repo is dependency-free by design: ZERO third-party Python deps (stdlib-only), ZERO npm deps (no package.json; the sole external library, Mermaid v11.15.0, is a SHA-256-pinned standalone download — stronger than `npm audit`). Language lock files would lock empty trees (security theater) and `pip-audit`/`npm audit` would find nothing to scan, so H3's "vuln-scanning impossible" premise is moot. High 3→2. The one genuinely-real residual the audit surfaced — 3 first-party GitHub Actions pinned by mutable tag, no dependabot — is Low (first-party `actions/*` + least-privilege `contents: read`) and is an optional hardening, not tracked debt.
  - 2026-05-29: Removed resolved items (C1, M1, M2, M5, M7) from the inventory + detail per the "resolved → drop from the list" policy; closure record retained here in the changelog. Summary table reverted to open-only counts.
  - 2026-05-29: Closed + removed H1 — the phantom-test doc drift is fully resolved; the optional "add e2e coverage" remainder is a future enhancement gated on H2 (CI), not active debt.
  - 2026-05-29: H2 RESOLVED + removed — CI is now enforced (branch protection on `master` requires all 4 checks; verified via `gh api`). Flipped the "advisory / branch-protection-pending" wording to "enforced" across infrastructure, project-structure, technology-stack, test-landscape, and the HTML summary. High 4→3.
  - 2026-05-29: Added CI (`.github/workflows/test.yml` + `.gitattributes`) and an explicit `.aid/.temp/` gitignore entry — the latter resolves M3 (removed from the list). Rewrote H2's fix recipe to the studied design (render-drift keystone gate; dropped the headless-impossible discovery-reviewer step). H2 stays open pending CI activation + branch protection.
  - 2026-05-29: KB-honesty pass — closed M5 + M7 (verified resolved on disk); completed M2 (normalized the 2 remaining hyphenated .mdc rule files); corrected test-suite count 5→7 and assertion total 235→273 across all current-state docs; corrected L5 staleness (examples are not 3+ months stale); fixed H3 wrong evidence cite; corrected L1 file count 5→4; rebuilt Summary table (added M7, open-only counts)
  - 2026-05-29: Marked C1 resolved (work-001 task-003); decremented Critical count to 0; added bump-procedure comment ref
  - 2026-05-27: Added 7 new entries from cycle-1 Q-AND-A; marked M2 (acronym) resolved
  - 2026-05-27: Initial frontmatter added during cycle-1 FIX Phase B
---

# Tech Debt

> **Source:** `discovery-quality` (Phase 1), cycle-1
> **Status:** Complete
> **Last Updated:** 2026-05-29

> This document is a diagnosis, not a sprint plan. Severity tags use the form `[CRITICAL]` / `[HIGH]` / `[MEDIUM]` / `[LOW]` so `build-metrics.sh` (see `canonical/templates/knowledge-base/tech-debt.md:17`) can tally them.

---

## Summary

**Overall debt level: Medium–High**. Rationale: the codebase itself is well-organized (Thin-Router skill convention, canonical/ as single source of truth, 7-suite canonical test suite) and now has **enforced pre-merge CI** (required status checks on `master`, 2026-05-29), but still carries several **structural gaps** surfaced by cycle-1 discovery (methodology rigidity and crud-outputs audit pending). There are **zero open Critical** items. Resolved items are dropped from the inventory below; their closure record (what / when / why) lives in this doc's changelog frontmatter and in git history. As of this writing, C1, H1, H2, H3, H6, M1, M2, M3, M5, and M7 have been closed and removed from the list.

| Severity | Open | Open items |
|----------|------|------------|
| Critical | 0 | — |
| High | 1 | H5 |
| Medium | 3 | H4, M4, M6 |
| Low | 5 | L1, L2, L3, L4, L5 |

> **Counting methodology:** this table counts unique **open** debt items (one row per entry, regardless of how many `[HIGH]`/`[MEDIUM]` tags appear in the fix recipe). Resolved items are removed from the inventory entirely; their closure record lives in the changelog frontmatter and git history. The generated `metrics.md` (built by `build-metrics.sh`) counts every body-tag occurrence including those inside fix-recipe sub-bullets, producing higher totals. Neither is wrong; they answer different questions. Canonical item count is this table.

---

## Debt Inventory

| ID | Type | Description | Location | Risk | Effort | Priority |
|----|------|-------------|----------|------|--------|----------|
| H4 | Crud Outputs (partially resolved) | Skills/scripts audit needed: unnecessary write-only outputs (reports/logs/intermediate files) not consumed by any downstream step — known instance fixed in cycle-1 (Q2: report_path=None); broader audit remains | scope: 10 user-facing skills + 11 generators/builders | Medium | M | P3 |
| H5 | Methodology Flexibility | Methodology assumes rigid 16-doc KB set; meta-repos / docs-only / library-only projects need flexibility | methodology spec, aid-discover, verify-claims, canonical/templates/knowledge-base/ | High | L | P2 |
| M4 | Test Discoverability | No aggregator script: each of the 7 test suites must be invoked manually with the right path; no way to run "all tests" with one command | `tests/README.md` (lists each separately); no `Makefile`/`task`/`npm test` | Medium | S | P3 |
| M6 | Test Refactor | 7 canonical/ test suites need: behavior-named files, shared test-utility extraction, consistent failure messages, optional aggregator | `tests/canonical/*.sh` (7 suites) | Medium | M | P3 |
| L1 | Source Bloat | 4 files >500 lines under canonical/methodology (largest: `methodology/aid-methodology.md` 1,070, `tests/canonical/test-parse-recipe.sh` 1,002, `canonical/scripts/execute/writeback-task-status.sh` 627, `canonical/skills/aid-execute/references/state-execute.md` 629) | various | Low | M | P3 |
| L2 | Test Coverage Gap | Zero tests for PowerShell paths (`setup.ps1`, `concatenate.ps1`), `.mjs` validators, and the `setup.sh` install flow | `test-landscape.md` Gaps section | Low | L | P3 |
| L3 | Allowlist Breadth | `.claude/settings.json` Bash allowlist includes broad `Bash(rm *)` and `Bash(python *)` without path scoping | `.claude/settings.json:5-14` | Low | XS | P3 |
| L4 | Versioning | AID has no version (no VERSION file, no semver); current position is "continuous master" | repo-wide; absence confirmed by project-index | Low | S | P3 |
| L5 | Example Divergence | `examples/brownfield-enterprise/README.md` uses old KB doc names (`data-model.md`→`schemas.md`, `api-contracts.md`→`pipeline-contracts.md`) and `DISCOVERY-STATE.md`→`.aid/knowledge/STATE.md` — an adopter would look for files the tool no longer produces. data-pipeline + desktop-app verified clean | `examples/brownfield-enterprise/README.md:31,32,35,59` | Low | S | P3 |

---

## Detailed Debt Items

### [MEDIUM] M4 — No aggregator script for test suites

**Type:** Developer Experience / Test Discoverability
**Evidence:**
- `tests/README.md` lists the 7 bash test commands the maintainer runs individually. After the cycle-1 Q6-cleanup (3 test files deleted, 5 remaining), the suite later grew to 7 (`fetch-mermaid.sh` + `grade.sh` added); there is still no `make test`, no `npm test`, no `pytest`, no `task test` (no `Makefile` / `package.json` / `pyproject.toml` / `Taskfile.yml` in the repo).
- A new contributor must read `tests/README.md` to enumerate the suites; missing one means partial coverage.

**Impact:** Friction; partial test runs. The CI workflow now runs all 7 suites, but there is still no single local `make test` entrypoint a contributor can run before pushing.

**Fix recipe (estimated S effort):**
1. Add a `Makefile` (or `tests/run-all.sh` aggregator) that invokes every suite in sequence, aggregates PASS/FAIL counts, and exits non-zero on any failure.
2. Wire the same target into the CI workflow (`.github/workflows/test.yml`).

**Owner suggestion:** maintainer.

---

### [LOW] L1 — Four files exceed 500 lines (one exceeds 1,000)

**Type:** Source Size / Complexity
**Evidence (from `wc -l` over `canonical/`, `methodology/`, `tests/`):**
- `methodology/aid-methodology.md` — 1,070 lines (the load-bearing spec; legitimately large)
- `tests/canonical/test-parse-recipe.sh` — 1,002 lines (113 tests; test-file size is justified)
- `canonical/scripts/execute/writeback-task-status.sh` — 627 lines (already tested by 69-test suite)
- `canonical/skills/aid-execute/references/state-execute.md` — 629 lines
- Note: `canonical/scripts/kb/verify-claims.sh` (695 lines, previously listed here) was deleted in cycle-1; its retirement is recorded in this doc's changelog.

**Impact:** None acute. The Thin-Router convention (`coding-standards.md §7b`) says SKILL.md should split past ~200 lines, but the `references/state-*.md` files do not have the same threshold. `state-execute.md` at 629 lines may justify further splitting if reviewers find it hard to navigate.

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

### [MEDIUM] H4 — Skills/scripts crud audit (write-only outputs, partially resolved)

**Type:** Process / Hygiene
**Status:** Known instance fixed in cycle-1 (Q2 resolution); broader audit remains.
**Evidence:**
- `run_generator.py:76,83` (pre-cycle-1): passed `.aid/work-002-canonical-generator/verify-{4a,4b}-report.json` as report paths to `run_verify()` / `run_advisory()`. These JSON files were write-only — no downstream step read them; the script itself uses return values, not the file. Fixed in cycle-1 by passing `report_path=None`.
- Surfaced user principle: skills and scripts should not emit files nobody reads (see feedback memory `no-crud-outputs`).
- The known instance has been fixed; a systematic audit has not been done.

**Impact:** Write-only outputs create maintenance confusion (which files are authoritative?), bloat the `.aid/` tree, and can silently break when parent directories are missing. Any skill that writes to `.aid/.temp/` or `.aid/generated/` without a downstream reader is waste.

**Fix recipe (estimated M effort):**
1. Enumerate all file-write calls across 10 user-facing skills + 11 generator/builder scripts.
2. For each output file: confirm at least one downstream consumer (another script, an agent read call, a committed artifact). If none, remove the write.
3. Document confirmed output files in `canonical/templates/generated-files.txt` registry.

**Owner suggestion:** maintainer; pick up via `/aid-interview` when prioritized.

---

### [HIGH] H5 — Methodology flexibility for KB doc-set

**Type:** Methodology / Architecture
**Evidence:**
- `methodology/aid-methodology.md` defines a rigid 16-doc KB set.
- `canonical/scripts/kb/verify-claims.sh` (deleted in cycle-1) hard-coded an expected-doc list.
- `canonical/templates/knowledge-base/` treats the 16 templates as mandatory.
- Discovery cycle-1 required a 15-doc carve-out (Q3: 2 renamed, 1 deleted, 1 replaced) for the AID meta-repo itself — the methodology had no facility for this, making the deviation an undocumented one-time exception.
- Q16 answer: user confirmed this should be a methodology-level change; the canonical 16-doc list should become a configurable default.

**Impact:** Every project type that doesn't match the standard 16-doc profile (meta-repos, docs-only repos, library-only repos, microservices) must fork methodology behavior or carry phantom placeholder docs. Blocks adoption in non-application contexts.

**Fix recipe (estimated L effort):**
1. Add `discovery.kb_docs:` list to `.aid/settings.yml` schema (default = the canonical 16-doc names).
2. Redesign `aid-discover` state-detection + auto-doc-set verification to read the declared list.
3. Update `canonical/templates/knowledge-base/` from "mandatory templates" to "default templates + `custom/` sub-folder for project-specific additions".
4. Update methodology spec to describe the 16-doc set as "standard default, overridable per project".
5. Validate the AID repo's cycle-1 15-doc carve-out as the first real-world test of the flexibility mechanism.

**Owner suggestion:** maintainer; pick up via `/aid-interview` when prioritized (do NOT assign a work-NNN number here — Discovery defers that).

---

### [MEDIUM] M6 — Test refactor toward clean-code patterns

**Type:** Test Quality / Developer Experience
**Evidence:**
- Phase A (cycle-1) deleted 3 stale test files (`tests/skills/lite-subpaths.sh`, `tests/skills/lite-to-full-escalation.sh`, `tests/canonical/pool-dispatch.sh`) per Q6 answer.
- 7 canonical/ suites are functionally sound but do not follow consistent conventions: file names describe the script under test, not the behavior being asserted; no shared test-utility module; assertion patterns vary across suites; failure messages are inconsistent.
- Q17 answer: user confirmed refactor should be a separate work-NNN, not inline to cycle-1 FIX.

**Impact:** Higher friction for contributors adding new test cases; harder to diagnose failures (inconsistent output format); test names that describe scripts-under-test rather than behaviors go stale when the script is renamed.

**Fix recipe (estimated M effort):**
1. Rename convention: adopt `<behavior-under-test>_test.sh` (e.g., `recipe-slot-extraction_test.sh`) or migrate to Bash Automated Testing System (bats).
2. Extract shared test utilities into `tests/lib/assert.sh` (pass/fail counters, assertion helpers, setup/teardown).
3. Standardize failure messages: every failing assertion should emit `FAIL: <test-name> — expected X got Y`.
4. Optionally add an aggregator `tests/run-all.sh` once all suites share the same output format.

**Owner suggestion:** maintainer; pick up via `/aid-interview` when prioritized (do NOT assign a work-NNN here — Discovery defers that).

---

### [LOW] L4 — Versioning scheme

**Type:** Distribution / Packaging
**Evidence:**
- No `VERSION` file, no `__version__` in Python, no `version =` in any TOML, no git-tag-based semver/calver.
- Q5 answer: user confirmed "continuous master" is the intentional current position. AID is methodology-in-development; explicit non-versioning is the honest position.
- End users install by re-running `setup.sh` against current master; there is no upgrade notification mechanism.

**Impact:** Low now (methodology-in-development). Will become high once AID stabilizes and external adopters want reproducible pinned installs or changelogs.

**Fix recipe (estimated S effort, deferred):**
1. Add `VERSION` file at repo root with a placeholder semver (e.g., `0.1.0-dev`).
2. Add a "Versioning" subsection to `README.md` explaining the continuous-master model and when a formal version will be introduced.
3. Wire `setup.sh` to print the installed version on completion.
4. Revisit when the methodology-flexibility refactor (H5) lands — that is the natural semver-bump point.

**Owner suggestion:** maintainer; revisit after H5 is resolved.

---

### [LOW] L5 — examples/ diverge from current methodology conventions

**Type:** Documentation Drift / Example Divergence
**Evidence (verified 2026-05-29 by content scan, not timestamps):**
- `examples/brownfield-enterprise/README.md` lists KB documents using **old names**: `data-model.md` (`:31`) and `api-contracts.md` (`:32`). The shipped standard template set (`canonical/templates/knowledge-base/`) uses `schemas.md` and `pipeline-contracts.md`, so an adopter running `aid-discover` today gets the new names and won't find the ones the example shows.
- The same file uses `DISCOVERY-STATE.md` (`:35`, `:59`); the current convention is the per-area `.aid/knowledge/STATE.md` (the canonical `discovery-state-template.md` states it "absorbs what used to be `DISCOVERY-STATE.md`").
- `examples/data-pipeline/` and `examples/desktop-app/` were scanned for the same signatures (old doc names, acronym variants, deleted artifacts, stale state vocabulary) and are **clean**.
- The earlier "3+ months stale" framing was wrong (brownfield was refreshed 2026-05-22) — the issue is content divergence, not age.

**Impact:** A new adopter following `brownfield-enterprise` looks for `data-model.md` / `api-contracts.md` / `DISCOVERY-STATE.md` — files the current tool no longer produces — undermining the example's value as an onboarding reference.

**Fix recipe (estimated S effort):**
1. In `examples/brownfield-enterprise/README.md`, rename the 4 references: `data-model.md`→`schemas.md`, `api-contracts.md`→`pipeline-contracts.md`, and `DISCOVERY-STATE.md`→`.aid/knowledge/STATE.md`.
2. Re-scan all three examples after any future KB-doc-set change.
3. Optionally add a `<!-- last-validated: YYYY-MM-DD -->` marker per case study.

**Note:** A separate, larger drift exists — the methodology spec (`methodology/aid-methodology.md`) still uses `DISCOVERY-STATE.md` in ~10 places, lagging its own canonical skill/template. Out of L5's scope (examples-only); flagged for a future item.

**Owner suggestion:** tech-writer; the brownfield rename is a quick win, independent of H5.

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
- **Files > 500 lines:** 4 (listed in L1; verify-claims.sh removed from list post-deletion)
- **Files > 1,000 lines:** 2 (`methodology/aid-methodology.md`, `tests/canonical/test-parse-recipe.sh`)
- **Test-to-code ratio (helper-script subset):** ⚠️ **Inferred from file counts.** There are now 7 canonical helper suites (the original 5 plus `fetch-mermaid.sh` and `grade.sh`). Lines-of-test for all 7 suites sum to **3,625 lines** (`wc -l tests/canonical/*.sh`) against ~2,500 lines of canonical helper code — ratio **≈ 1.45×**. Healthy for shell helpers.
- **Open PRs:** 0 — the H6 durable-anchor / P1(a) count-purge / script-rename stack (PRs #22, #23, #24) merged to `master` on 2026-05-30.
