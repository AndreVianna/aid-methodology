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
  - 2026-05-30: H4, L3, L5 RESOLVED + removed. H4 (crud-outputs audit) — completed the systematic audit across all 10 user-facing skills, the 11 generator/builder scripts, and every `canonical/scripts/` helper (a 3-way file-write sweep): ZERO write-only outputs found — every persisted file is consumed by a downstream reader, is the phase's deliverable, or is self-consumed scratch (mktemp/lock); the cycle-1 `run_generator.py` verify-report fix confirmed still in place (pipeline passes `report_path=None`); `generated-files.txt` registry confirmed correct/complete. No code change needed — audit clean. L3 (broad Bash allowlist) — ACCEPTED: the unscoped `Bash(rm *)`/`Bash(python *)`/`Bash(chmod *)` in `.claude/settings.json` are appropriate for this maintainer-trusted dogfood (defense-in-depth via the per-agent `tools:` allowlist); scoping them would only add friction to the maintainer's own sessions. Revisit only if AID ships a shared/CI-managed instance. L5 (example divergence) — fixed `examples/brownfield-enterprise/README.md` doc names (data-model.md→schemas.md, api-contracts.md→pipeline-contracts.md, DISCOVERY-STATE.md→.aid/knowledge/STATE.md). Medium 1→0, Low 4→2; 3 open items remain (H5, L1, L4).
  - 2026-05-30: M4, M6, L2 RESOLVED + removed — the test-suite debt is closed. M4 (no aggregator): added `tests/run-all.sh`, the single glob-discovering entrypoint shared by CI + local dev. M6 (test refactor): extracted shared `tests/lib/assert.sh`, behavior-named the suites (`test-` prefix), standardized failure messages, and migrated every suite to the shared lib. L2 (coverage gaps): added Node suites for the `.mjs` validators (validate-diagrams, contrast-check), a `setup.sh` install-flow suite, bash + PowerShell suites for `assemble-3part`, and a pre-install suite for `setup.ps1`, all gated in CI (node pinned; pwsh asserted present). Shipped via PRs #26/#27. Medium 3→1, Low 5→4. (Descriptive test-suite metrics in this doc — suite count, LOC ratio, Open-PRs note — are stale and refresh on the next /aid-discover cycle.)
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

> This document is a diagnosis, not a sprint plan. Severity tags use the form `[CRITICAL]` / `[HIGH]` / `[MEDIUM]` / `[LOW]` so `build-metrics.sh` (see the "Severity tag convention" note in `canonical/templates/knowledge-base/tech-debt.md`) can tally them.

---

## Summary

**Overall debt level: Medium–High**. Rationale: the codebase itself is well-organized (Thin-Router skill convention, canonical/ as single source of truth, 13-suite canonical test suite) and now has **enforced pre-merge CI** (required status checks on `master`, 2026-05-29), but still carries a **structural gap** surfaced by cycle-1 discovery (methodology rigidity — H5 — pending). There are **zero open Critical** items. Resolved items are dropped from the inventory below; their closure record (what / when / why) lives in this doc's changelog frontmatter and in git history. As of this writing, C1, H1, H2, H3, H4, H6, M1, M2, M3, M4, M5, M6, M7, L2, L3, and L5 have been closed and removed from the list.

| Severity | Open | Open items |
|----------|------|------------|
| Critical | 0 | — |
| High | 1 | H5 |
| Medium | 0 | — |
| Low | 2 | L1, L4 |

> **Counting methodology:** this table counts unique **open** debt items (one row per entry, regardless of how many `[HIGH]`/`[MEDIUM]` tags appear in the fix recipe). Resolved items are removed from the inventory entirely; their closure record lives in the changelog frontmatter and git history. The generated `metrics.md` (built by `build-metrics.sh`) counts every body-tag occurrence including those inside fix-recipe sub-bullets, producing higher totals. Neither is wrong; they answer different questions. Canonical item count is this table.

---

## Debt Inventory

| ID | Type | Description | Location | Risk | Effort | Priority |
|----|------|-------------|----------|------|--------|----------|
| H5 | Methodology Flexibility | Methodology assumes rigid 16-doc KB set; meta-repos / docs-only / library-only projects need flexibility | methodology spec, aid-discover, canonical/templates/knowledge-base/ | High | L | P2 |
| L1 | Source Bloat | ~10 files >500 lines under canonical/methodology/tests (largest: `methodology/aid-methodology.md` ~1,070, `tests/canonical/test-parse-recipe.sh`, `canonical/skills/aid-execute/references/state-execute.md`, `canonical/scripts/execute/writeback-state.sh`) | various | Low | M | P3 |
| L4 | Versioning | AID has no version (no VERSION file, no semver); current position is "continuous master" | repo-wide; absence confirmed by project-index | Low | S | P3 |

---

## Detailed Debt Items

### [LOW] L1 — Roughly ten files exceed 500 lines (one exceeds 1,000)

**Type:** Source Size / Complexity
**Evidence (from `wc -l` over `canonical/`, `methodology/`, `tests/`; recover the current set with `find canonical methodology tests -type f \( -name '*.sh' -o -name '*.md' -o -name '*.py' -o -name '*.mjs' \) -exec wc -l {} + | awk '$1>500 && $2!="total"'`):**
- `methodology/aid-methodology.md` — the load-bearing spec, ~1,070 lines and the only file over 1,000; legitimately large.
- `tests/canonical/test-parse-recipe.sh` — the largest test suite; test-file size is justified.
- `canonical/skills/aid-execute/references/state-execute.md` — the largest reference doc.
- `canonical/scripts/execute/writeback-state.sh` — already tested by its dedicated suite.
- Several others now also cross the 500-line line (e.g. `canonical/scripts/summarize/validate-diagrams.mjs`, `canonical/scripts/interview/parse-recipe.sh`, `canonical/skills/aid-interview/references/state-condensed-intake.md`, `tests/canonical/test-delivery-gate-aggregate.sh`, `canonical/scripts/summarize/grade-summary.sh`, `canonical/skills/aid-interview/references/state-triage.md`); run the command above for the live list.
- Note: `canonical/scripts/kb/verify-claims.sh` (previously listed here) was deleted in cycle-1; its retirement is recorded in this doc's changelog.

**Impact:** None acute. The Thin-Router convention (`coding-standards.md §7b`) says SKILL.md should split past ~200 lines, but the `references/state-*.md` files do not have the same threshold. `state-execute.md` at 629 lines may justify further splitting if reviewers find it hard to navigate.

**Fix recipe (estimated M effort, opportunistic):**
- For `state-execute.md`: consider sub-splitting (e.g., `state-execute-pool.md`, `state-execute-review.md`) if specific sections grow further.
- For the shell scripts: extract self-contained functions into `lib/` files; verify behavior unchanged via the existing test suites.

**Owner suggestion:** address opportunistically during feature work in those files.

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

## Metrics

- **TODO/FIXME count:** 9 occurrences across 6 files (source: `rg "TODO|FIXME"` over `canonical/`). Specifically:
  - `canonical/agents/discovery-quality/AGENT.md` (2)
  - `canonical/agents/discovery-quality/README.md` (1)
  - `canonical/skills/aid-discover/references/state-generate.md` (1)
  - `canonical/skills/aid-discover/references/agent-prompts.md` (1)
  - `canonical/skills/aid-discover/README.md` (3)
  - `canonical/templates/knowledge-base/tech-debt.md` (1)
  - These are all *template-explanatory* mentions (e.g., "fill in TODO sections"), not unresolved code TODOs. Net **0 unresolved code TODOs**.
- **Files > 500 lines:** ~10 (representative cases listed in L1; `writeback-state.sh` is one)
- **Files > 1,000 lines:** 1 (`methodology/aid-methodology.md`)
- **Test-to-code ratio (helper-script subset):** ⚠️ **Inferred from file counts.** There are now **13** canonical suites under `tests/canonical/`, plus the shared `tests/lib/assert.sh` lib and the `tests/run-all.sh` glob-discovering aggregator. Lines-of-test across `tests/canonical/*.sh`, `tests/lib/*.sh`, and `tests/run-all.sh` sum to **4,162 lines** (`wc -l tests/canonical/*.sh tests/lib/*.sh tests/run-all.sh`). The suite count comfortably exceeds the helper-script count, so test coverage remains healthy for shell helpers (per-script LOC ratios drift with refactors and are not pinned here).
- **Open PRs:** 0 — the H6 durable-anchor / P1(a) count-purge / script-rename stack plus the M4/M6/L2 test-suite work (PRs #22 through #28, which also closed H6, M4, M6, and L2) merged to `master` on 2026-05-30.
