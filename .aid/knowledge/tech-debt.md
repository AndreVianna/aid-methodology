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
  - 2026-05-27: Added 7 new entries from cycle-1 Q-AND-A; marked M2 (acronym) resolved
  - 2026-05-27: Initial frontmatter added during cycle-1 FIX Phase B
---

# Tech Debt

> **Source:** `discovery-quality` (Phase 1), cycle-1
> **Status:** Complete
> **Last Updated:** 2026-05-27

> This document is a diagnosis, not a sprint plan. Severity tags use the form `[CRITICAL]` / `[HIGH]` / `[MEDIUM]` / `[LOW]` so `build-metrics.sh` (see `canonical/templates/knowledge-base/tech-debt.md:17`) can tally them.

---

## Summary

**Overall debt level: Medium–High**. Rationale: the codebase itself is well-organized (Thin-Router skill convention, canonical/ as single source of truth, 5-suite canonical test suite post-cycle-1 cleanup) but operates with **zero pre-merge automation** and several **structural gaps** surfaced by cycle-1 discovery (methodology rigidity, verify-claims.sh transition incomplete, crud outputs audit pending). There is **one Critical** item: the supply-chain risk in `fetch-mermaid.sh` materially affects end users. M2 (acronym drift) was resolved in cycle-1 Phase A.

| Severity | Count | Items |
|----------|-------|-------|
| Critical | 1 | C1 |
| High | 6 | H1, H2, H3, H4, H5, H6 |
| Medium | 6 | M1, M2 (resolved), M3, M4, M5, M6 |
| Low | 5 | L1, L2, L3, L4, L5 |

---

## Debt Inventory

| ID | Type | Description | Location | Risk | Effort | Priority |
|----|------|-------------|----------|------|--------|----------|
| C1 | Supply Chain | `fetch-mermaid.sh` fetches `mermaid@latest` from npm registry with no version pin and no SHA verification | `canonical/scripts/summarize/fetch-mermaid.sh:16-18, 41, 59-73` | Critical | S | P1 |
| H1 | Doc Drift / Untestable Claim | Older docs cited two e2e test runners in `.aid/work-001-aid-lite/test-reports/` that do not exist on disk; per Q1 resolution (cycle-1) those runners were never correct canonical artifacts and have been removed from documentation | `tests/README.md` (the current contract); disk: `.aid/work-001-aid-lite/` correctly absent | High | S | P1 |
| H2 | No CI | Zero pre-merge automation; every test/verify pass is manual | repo-wide | High | M | P2 |
| H3 | Supply Chain (sibling of C1) | No language lock files exist (`package-lock.json`, `requirements.txt`, etc.) — vulnerability scanning is impossible | repo-wide; absence confirmed in `project-structure.md:96` | High | M | P2 |
| H4 | Crud Outputs (partially resolved) | Skills/scripts audit needed: unnecessary write-only outputs (reports/logs/intermediate files) not consumed by any downstream step — known instance fixed in cycle-1 (Q2: report_path=None); broader audit remains | scope: 10 user-facing skills + 11 generators/builders | Medium | M | P3 |
| H5 | Methodology Flexibility | Methodology assumes rigid 16-doc KB set; meta-repos / docs-only / library-only projects need flexibility | methodology spec, aid-discover, verify-claims, canonical/templates/knowledge-base/ | High | L | P2 |
| H6 | verify-claims.sh deletion follow-up | verify-claims.sh deleted; discovery-reviewer now owns FM+contract verification semantically — reviewer prompt coverage must be confirmed explicitly | cycle-1 inline refactor; canonical/agents/discovery-reviewer/AGENT.md | High | S | P2 |
| M1 | Doc Drift | `run_generator.py` writes VERIFY-4a/4b reports to `.aid/work-002-canonical-generator/` which does not exist; the script either crashes on first invocation or silently creates the dir without recording its purpose | `run_generator.py:76, 83`; disk: `.aid/work-002-canonical-generator/` missing | Medium | S | P2 |
| M2 | Doc Drift (RESOLVED) | Project name expansion drift — all four variants now canonicalized to "AI Integrated Development" | resolved 2026-05-27 commit 82a5bd5 | Medium | XS | — |
| M3 | Gitignore Fragility | `.aid/.temp/` is excluded only by the `*.temp` glob at `.gitignore:21`, not an explicit dir entry — a rename to e.g. `.aid/scratch/` would silently start tracking it | `.gitignore:18-21` | Medium | XS | P3 |
| M4 | Test Discoverability | No aggregator script: each of the 5 remaining test suites must be invoked manually with the right path; no way to run "all tests" with one command | `tests/README.md` (lists each separately); no `Makefile`/`task`/`npm test` | Medium | S | P3 |
| M5 | Q&A Schema | Two Q&A entry schemas coexist; canonical decided = Style A but work-state-template.md + methodology spec + aid-interview not yet migrated | `canonical/templates/work-state-template.md`, `methodology/aid-methodology.md`, aid-interview skill | Medium | S | P3 |
| M6 | Test Refactor | 5 remaining canonical/ test suites need: behavior-named files, shared test-utility extraction, consistent failure messages, optional aggregator | `tests/canonical/*.sh` (5 suites) | Medium | M | P3 |
| L1 | Source Bloat | 5 files >500 lines under canonical/methodology (largest: `methodology/aid-methodology.md` 1,071, `tests/canonical/parse-recipe.sh` 1,002, `canonical/scripts/execute/writeback-task-status.sh` 627, `canonical/skills/aid-execute/references/state-execute.md` 629) | various | Low | M | P3 |
| L2 | Test Coverage Gap | Zero tests for PowerShell paths (`setup.ps1`, `concatenate.ps1`), `.mjs` validators, and the `setup.sh` install flow | `test-landscape.md` Gaps section | Low | L | P3 |
| L3 | Allowlist Breadth | `.claude/settings.json` Bash allowlist includes broad `Bash(rm *)` and `Bash(python *)` without path scoping | `.claude/settings.json:5-14` | Low | XS | P3 |
| L4 | Versioning | AID has no version (no VERSION file, no semver); current position is "continuous master" | repo-wide; absence confirmed by project-index | Low | S | P3 |
| L5 | Examples Staleness | examples/ case studies (brownfield-enterprise, data-pipeline, desktop-app) are 3+ months stale (last touched March 2026) | `examples/` directory | Low | M | P3 |

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

### [HIGH] H1 — E2E test runners cited in older docs did not exist on disk (partially resolved)

**Type:** Documentation Drift / Untestable Claim
**Evidence:**
- Older documentation cited `.aid/work-001-aid-lite/test-reports/e2e-two-tier-runner.sh` (35 tests) and `e2e-lite-path-runner.sh` (38 tests) as part of the canonical test suite.
- Per Q1 resolution (cycle-1): "No canonical file should be in the work-* folder." Those runners were never correctly placed there; they were removed from documentation.
- Current test contract: 5 canonical suites in `tests/canonical/` (see `tests/README.md`); `.aid/work-001-aid-lite/` is correctly absent.

**Impact (historical):** Inflated "297 expected" total by 73 phantom tests. Confusingly misleading to new contributors.

**Remaining action:** If E2E test coverage is wanted in the project, relocate scripts to `tests/canonical/` or `tests/e2e/`. See H2 (no CI) — adding E2E coverage is most impactful once H2 is addressed.

**Owner suggestion:** maintainer.

---

### [HIGH] H2 — No CI

**Type:** Process / Automation
**Evidence:**
- No `.github/`, no `.gitlab-ci.yml`, no `Jenkinsfile`, no `azure-pipelines.yml`, no `.circleci/`, no `.travis.yml`, no `bitbucket-pipelines.yml` anywhere in the repo (confirmed by file-system search at scout time).

**Impact:** Every quality gate (canonical helper tests, render-determinism, KB claim verification) is human-discretionary. PR reviewers cannot rely on green-build signal. A regression in `parse-recipe.sh` or `writeback-task-status.sh` only surfaces if the maintainer remembers to run the suite locally before merging.

**Fix recipe (estimated M effort):**
1. Add `.github/workflows/test.yml` that on PR runs (in order): the 5 `tests/canonical/*.sh` suites, `python .claude/skills/aid-generate/scripts/verify_deterministic.py`, and the discovery-reviewer semantic check (see H6).
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

### [MEDIUM] M1 — `run_generator.py` wrote to `.aid/work-002-canonical-generator/` — RESOLVED

**Type:** Documentation / Path Drift
**Status:** Resolved in cycle-1 (Q2 resolution): `run_generator.py` now passes `report_path=None` to `run_verify()` / `run_advisory()`. No file writes occur; the directory is not created.
**Evidence (historical):**
- `run_generator.py:76` and `:83` previously passed `.aid/work-002-canonical-generator/verify-{4a,4b}-report.json` as report paths. Those JSON files were write-only — no downstream step read them.
- Surfaced user principle: skills and scripts should not emit files nobody reads (see feedback memory `no-crud-outputs`).

**Impact (historical):** On fresh clone, first build would have silently created the directory or failed.

**Owner suggestion:** n/a — resolved.

---

### [MEDIUM] M2 — Project name expansion drift between CLAUDE.md and settings.yml — RESOLVED

**Type:** Documentation Drift
**Status:** Resolved 2026-05-27 (cycle-1 Phase A commit 82a5bd5: acronym canonicalized to "AI Integrated Development" across CLAUDE.md, README, methodology spec, docs/, KB docs)
**Evidence (historical):**
- Older CLAUDE.md text said *"AID (Agentic Implementation Discipline)"*.
- `.aid/settings.yml:16` said `description: AI Integrated Development`.
- Per user memory (cross-conversation), the canonical expansion is "AI Integrated Development" — the CLAUDE.md text was stale. A four-way conflict also existed with domain-glossary.md ("AI-Integrated Development", hyphenated) and user memory (formerly "Agent Integrated Development"). See Q11 in STATE.md for full context.

**Impact (historical):** Low practical impact (no code reads either string) but undermined the canonical-source-of-truth convention. Surfaced by cycle-1 REVIEW as CC3.

**Resolution:** Updated CLAUDE.md, domain-glossary.md, methodology spec, README, and all KB docs to use "AI Integrated Development" (no hyphen). Grepped entire repo for all four variants; all replaced consistently in Phase A commit 82a5bd5.

**Owner suggestion:** n/a — resolved.

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
- `tests/README.md` lists the 5 bash test commands the maintainer runs individually. After Q6-cleanup (cycle-1: 3 test files deleted, 5 remaining), there is still no `make test`, no `npm test`, no `pytest`, no `task test` (no `Makefile` / `package.json` / `pyproject.toml` / `Taskfile.yml` in the repo).
- A new contributor must read `tests/README.md` to enumerate the suites; missing one means partial coverage.

**Impact:** Friction; partial test runs; correlates with H2.

**Fix recipe (estimated S effort):**
1. Add a `Makefile` (or `tests/run-all.sh` aggregator) that invokes every suite in sequence, aggregates PASS/FAIL counts, and exits non-zero on any failure.
2. Wire the same target into the CI workflow from H2.

**Owner suggestion:** maintainer.

---

### [LOW] L1 — Five files exceed 500 lines (one exceeds 1,000)

**Type:** Source Size / Complexity
**Evidence (from `wc -l` over `canonical/`, `methodology/`, `tests/`):**
- `methodology/aid-methodology.md` — 1,071 lines (the load-bearing spec; legitimately large)
- `tests/canonical/parse-recipe.sh` — 1,002 lines (113 tests; test-file size is justified)
- `canonical/scripts/execute/writeback-task-status.sh` — 627 lines (already tested by 69-test suite)
- `canonical/skills/aid-execute/references/state-execute.md` — 629 lines
- Note: `canonical/scripts/kb/verify-claims.sh` (695 lines, previously listed here) was deleted in cycle-1; its deletion is tracked in H6.

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
- `canonical/scripts/kb/verify-claims.sh` (deleted in cycle-1, see H6) hard-coded an expected-doc list.
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

### [HIGH] H6 — verify-claims.sh deletion follow-up

**Type:** Process / Quality
**Evidence:**
- `canonical/scripts/kb/verify-claims.sh` was deleted during cycle-1 inline refactor (commit c8ef59e). The discovery-reviewer agent now owns frontmatter + contract verification semantically.
- No explicit follow-up has confirmed that the reviewer's prompt covers all the checks the script performed: FM presence, FM field validity, contract claims, AUTO-GENERATED header presence for generated docs.
- The KB body still described verify-claims.sh as live in 18+ places across 6 docs (CC2 cascade); fixed in cycle-2 FIX Phase A.

**Impact:** If the reviewer prompt gaps any check the script used to do, that class of defect will silently go undetected going forward. The transition from script-based to semantic-agent-based verification is incomplete until the coverage is explicitly confirmed.

**Fix recipe (estimated S effort):**
1. Read `canonical/agents/discovery-reviewer/AGENT.md` and compare its checklist against the former script's check list (FM presence, FM field validity, contract claims, AUTO-GENERATED header).
2. For any gap: add an explicit check clause to the reviewer prompt.
3. KB body references updated in cycle-2 FIX Phase A sweep.
4. Add a note to `generated-files.txt` registry that the script no longer exists.

**Owner suggestion:** maintainer; priority P2 — cycle-2 FIX Phase A addressed the KB body cascade.

---

### [MEDIUM] M5 — Q&A schema canonicalization

**Type:** Documentation / Standards Drift
**Evidence:**
- Style A: `### Q{N}` header + sub-bullets for Category / Impact / Status / Context / Suggested / Answer. Used in `.aid/knowledge/STATE.md` (this repo's cycle) and in aid-discover output.
- Style B: `### IQ{N}: [Category: Impact]` inline header followed by Question / Context / Source / Suggested / Status. Used in `methodology/aid-methodology.md` Q&A spec and `canonical/templates/work-state-template.md`.
- Q15 answer: canonical decided = Style A. Phase B Q15 agent handles part of this migration.

**Impact:** Skills that emit Q&A entries or parse existing ones must handle both schemas, increasing fragility. New contributors will not know which is authoritative. Search/grep tooling that relies on the `### Q{N}` or `### IQ{N}:` pattern will produce inconsistent results.

**Fix recipe (estimated S effort):**
1. Update `canonical/templates/work-state-template.md` `## Cross-phase Q&A` section to use Style A.
2. Update `methodology/aid-methodology.md` Q&A spec to use Style A.
3. Update `aid-interview` skill body + references to emit Style A on Q&A injection from downstream phases.
4. Document Style A in `coding-standards.md` as the canonical Q&A schema (with an example block).
5. Confirm any unfinished migration work from Phase B (Q15 agent) and capture remainder here.

**Owner suggestion:** tech-writer + maintainer; pick up via `/aid-interview` when prioritized.

---

### [MEDIUM] M6 — Test refactor toward clean-code patterns

**Type:** Test Quality / Developer Experience
**Evidence:**
- Phase A (cycle-1) deleted 3 stale test files (`tests/skills/lite-subpaths.sh`, `tests/skills/lite-to-full-escalation.sh`, `tests/canonical/pool-dispatch.sh`) per Q6 answer.
- 5 remaining canonical/ suites are functionally sound but do not follow consistent conventions: file names describe the script under test, not the behavior being asserted; no shared test-utility module; assertion patterns vary across suites; failure messages are inconsistent.
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

### [LOW] L5 — examples/ staleness

**Type:** Documentation Drift
**Evidence:**
- `examples/brownfield-enterprise/`, `examples/data-pipeline/`, `examples/desktop-app/` — all last touched March 2026 (3+ months stale as of 2026-05-27).
- File sizes are small (~50-110 lines per case study).
- Q8 answer: user confirmed accept-stale for now; no refresh blocking this cycle.

**Impact:** Case studies that diverge from current methodology conventions mislead adopters. Risk is proportional to how much the methodology has changed since March 2026; currently moderate (Thin-Router skill convention, Q3's KB-doc renaming, acronym canonicalization are all post-March changes).

**Fix recipe (estimated M effort, deferred):**
1. After Q3 KB-doc renaming (api-contracts → pipeline-contracts, data-model → schemas, etc.) lands, update any example references to those doc names.
2. After acronym canonicalization (Q11) propagates, grep examples/ for old variants.
3. Full refresh: re-run each case study scenario against current methodology spec; update narration.
4. Add a `<!-- last-validated: YYYY-MM-DD -->` comment to each case study so staleness is visible.

**Owner suggestion:** tech-writer; refresh when the methodology-flexibility refactor (H5) and KB-doc renaming (Q3) are both stable.

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
- **Files > 1,000 lines:** 2 (`methodology/aid-methodology.md`, `tests/canonical/parse-recipe.sh`)
- **Test-to-code ratio (helper-script subset):** ⚠️ **Inferred from file counts.** After cycle-1 Q6 cleanup (pool-dispatch.sh deleted), 5 canonical helper suites remain. Lines-of-test for the 5 remaining suites (parse-recipe, writeback-task-status, delivery-gate-aggregate, compute-block-radius, read-setting) sum to approximately **2,777 lines** of test code against ~2,150 lines of canonical helper code — ratio **≈ 1.29×**. Healthy for shell helpers.
- **Open PRs:** 0 (the previously-cited PR #16 "aid-config simplification" merged 2026-05-27 per `git log --oneline -20`). Note: the dispatcher's note referenced PR #16 as "yet to merge" — this is stale relative to the current commit history.
- **Branches behind master:** current branch is `kb-overhaul`; recent merges suggest active KB work.
