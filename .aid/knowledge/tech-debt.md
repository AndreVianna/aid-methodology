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
  - 2026-05-30: L1, L4 RESOLVED + removed. L1 (source bloat) — split the one file with a clean, value-adding seam: `state-execute.md` (629→485 lines) had its self-contained snapshot-rendering spec extracted to a new `state-execute-drilldown.md` (the SKILL.md already referenced the two sections separately; the SKILL.md + domain-glossary cross-refs were updated and the 3 profiles re-rendered). Audited the remaining >500-line files and confirmed they are appropriately sized for their type — the methodology spec (~1,070, a deliberate single spec), the test suites, the well-tested helper scripts, and the detailed `state-*.md` references each have legitimate reasons, and the Thin-Router convention is enforced on the SKILL.md routers; per the item's "opportunistic" guidance no further standalone splitting is warranted. L4 (versioning) — added a `VERSION` file (`0.1.0-dev` pre-release marker), refreshed the README "Versioning" section, and wired `setup.sh`/`setup.ps1` to print the installed version on completion; honors the Q5 "continuous master" position while giving adopters a concrete version string (the formal semver bump remains the natural post-H5 milestone). Low 2→0 — only H5 remains open.
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

**Overall debt level: Low–Medium**. Rationale: the codebase itself is well-organized (Thin-Router skill convention, canonical/ as single source of truth, 13-suite canonical test suite) and has **enforced pre-merge CI** (required status checks on `master`, 2026-05-29); the inventory is now down to a **single open item** — H5 (methodology rigidity), a High-severity design change that is not urgent. There are **zero open Critical** items. Resolved items are dropped from the inventory below; their closure record (what / when / why) lives in this doc's changelog frontmatter and in git history. As of this writing, C1, H1, H2, H3, H4, H6, M1, M2, M3, M4, M5, M6, M7, L1, L2, L3, L4, and L5 have been closed and removed from the list.

| Severity | Open | Open items |
|----------|------|------------|
| Critical | 0 | — |
| High | 1 | H5 |
| Medium | 0 | — |
| Low | 0 | — |

> **Counting methodology:** this table counts unique **open** debt items (one row per entry, regardless of how many `[HIGH]`/`[MEDIUM]` tags appear in the fix recipe). Resolved items are removed from the inventory entirely; their closure record lives in the changelog frontmatter and git history. The generated `metrics.md` (built by `build-metrics.sh`) counts every body-tag occurrence including those inside fix-recipe sub-bullets, producing higher totals. Neither is wrong; they answer different questions. Canonical item count is this table.

---

## Debt Inventory

| ID | Type | Description | Location | Risk | Effort | Priority |
|----|------|-------------|----------|------|--------|----------|
| H5 | Methodology Flexibility | Methodology assumes rigid 16-doc KB set; meta-repos / docs-only / library-only projects need flexibility | methodology spec, aid-discover, canonical/templates/knowledge-base/ | High | L | P2 |

---

## Detailed Debt Items

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

## Metrics

- **TODO/FIXME count:** 9 occurrences across 6 files (source: `rg "TODO|FIXME"` over `canonical/`). Specifically:
  - `canonical/agents/discovery-quality/AGENT.md` (2)
  - `canonical/agents/discovery-quality/README.md` (1)
  - `canonical/skills/aid-discover/references/state-generate.md` (1)
  - `canonical/skills/aid-discover/references/agent-prompts.md` (1)
  - `canonical/skills/aid-discover/README.md` (3)
  - `canonical/templates/knowledge-base/tech-debt.md` (1)
  - These are all *template-explanatory* mentions (e.g., "fill in TODO sections"), not unresolved code TODOs. Net **0 unresolved code TODOs**.
- **Files > 500 lines:** ~9 (the methodology spec, several test suites + helper scripts, and detailed state-reference docs — all appropriately sized for their type)
- **Files > 1,000 lines:** 1 (`methodology/aid-methodology.md`)
- **Test-to-code ratio (helper-script subset):** ⚠️ **Inferred from file counts.** There are now **13** canonical suites under `tests/canonical/`, plus the shared `tests/lib/assert.sh` lib and the `tests/run-all.sh` glob-discovering aggregator. Lines-of-test across `tests/canonical/*.sh`, `tests/lib/*.sh`, and `tests/run-all.sh` sum to **4,162 lines** (`wc -l tests/canonical/*.sh tests/lib/*.sh tests/run-all.sh`). The suite count comfortably exceeds the helper-script count, so test coverage remains healthy for shell helpers (per-script LOC ratios drift with refactors and are not pinned here).
- **Open PRs:** 0 — the H6 durable-anchor / P1(a) count-purge / script-rename stack plus the M4/M6/L2 test-suite work (PRs #22 through #28, which also closed H6, M4, M6, and L2) merged to `master` on 2026-05-30.
