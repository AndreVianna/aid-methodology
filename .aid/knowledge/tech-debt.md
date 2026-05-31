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
  - 2026-05-31: H5 RESOLVED + removed. H5 (methodology flexibility for KB doc-set) — implemented delivery-002 of work-001-adaptive-kb: added `discovery.doc_set` declared-doc-set in `.aid/settings.yml` (pipe-delimited YAML block-list, `filename|owner|presence[:when]`); redesigned `aid-discover` GENERATE state (Step 0d propose→confirm checkpoint + data-driven dispatch from declared set; no-hang on omission; dispatch on addition; default seed from `canonical/templates/knowledge-base/*.md` for backward-compat); added `doc-set-resolve.md` shared snippet with `resolve_doc_set`/`synth_default_seed` pure-bash+awk functions; de-hardcoded all doc-count/doc-list literals from GENERATE + REVIEW state; added 3 F4 canonical test suites covering read/mapping/propose-confirm; updated 3 install-tree profiles. The AID repo's cycle-1 15-doc carve-out is now modeled cleanly as a declared set. High 1→0 — zero open items remain.
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
> **Last Updated:** 2026-05-31

> This document is a diagnosis, not a sprint plan. Severity tags use the form `[CRITICAL]` / `[HIGH]` / `[MEDIUM]` / `[LOW]` so `build-metrics.sh` (see the "Severity tag convention" note in `canonical/templates/knowledge-base/tech-debt.md`) can tally them.

---

## Summary

**Overall debt level: Low**. Rationale: the codebase itself is well-organized (Thin-Router skill convention, canonical/ as single source of truth, 18-suite canonical test suite) and has **enforced pre-merge CI** (required status checks on `master`, 2026-05-29); the inventory holds **one Low item** (L6, an FR-P0-4 follow-up). There are **zero open Critical, High, or Medium** items. Resolved items are dropped from the inventory below; their closure record (what / when / why) lives in this doc's changelog frontmatter and in git history. As of this writing, C1, H1, H2, H3, H4, H5, H6, M1, M2, M3, M4, M5, M6, M7, L1, L2, L3, L4, and L5 have been closed and removed from the list.

| Severity | Open | Open items |
|----------|------|------------|
| Critical | 0 | — |
| High | 0 | — |
| Medium | 0 | — |
| Low | 1 | L6 |

> **Counting methodology:** this table counts unique **open** debt items (one row per entry, regardless of how many `[HIGH]`/`[MEDIUM]` tags appear in the fix recipe). Resolved items are removed from the inventory entirely; their closure record lives in the changelog frontmatter and git history. The generated `metrics.md` (built by `build-metrics.sh`) counts every body-tag occurrence including those inside fix-recipe sub-bullets, producing higher totals. Neither is wrong; they answer different questions. Canonical item count is this table.

---

## Debt Inventory

| ID | Severity | Title | Evidence | Effort | Priority |
|----|----------|-------|----------|--------|----------|
| L6 | LOW | FR-P0-4 residual fixed-doc-count literals outside the de-hardcode scope | `reviewer-prompt.md:64` ("16 primary documents"), `reviewer-brief.md:26` ("outside canonical 16"), discover `README.md:168` ("these 16 documents"), root `README.md:115` ("fixed shape — 14 standard documents") | S | P3 |

## Detailed Debt Items

### [LOW] L6 — FR-P0-4 residual fixed-doc-count literals

**Type:** Methodology / consistency
**Evidence:**
- `canonical/skills/aid-discover/references/reviewer-prompt.md:64` — "16 primary documents"
- `canonical/skills/aid-discover/references/reviewer-brief.md:26` — "outside canonical 16"
- `canonical/skills/aid-discover/README.md:168` — "subset of these 16 documents"
- root `README.md:115` — "fixed shape — 14 standard documents" (user-facing pitch)

**Impact:** work-001 delivery-002 removed the fixed doc-count assumption from the five
GENERATE/REVIEW de-hardcode targets enumerated in feature-004 SPEC §2.3, but a few reviewer/
README sites outside that scope still phrase the doc-set as a fixed "14"/"16" set. The shipped
behavior is correct (the doc-set is now declared/variable); these are stale *descriptions* that
contradict the new mechanism. Low impact (prose only, no behavior), but worth tidying so the
narrative is consistent with FR-P0-4's intent.

**Fix recipe (estimated S effort):**
1. Reword the three canonical reviewer/discover references to count-agnostic phrasing ("the
   declared doc-set" / "the default seed set").
2. Soften the root `README.md` pitch from "fixed shape — 14 standard documents" to describe the
   declared/derived doc-set (default seed for software-dev projects).
3. Re-render; confirm render-drift clean.

**Owner suggestion:** maintainer; a quick follow-up to work-001 (surfaced by its delivery-002 gate review).

---

## Metrics

- **TODO/FIXME count:** net **0 unresolved code TODOs** — all occurrences in `canonical/` are template-explanatory mentions ("fill in TODO sections"), not unresolved code TODOs.
- **Files > 500 lines:** ~9 (the methodology spec, several test suites + helper scripts, and detailed state-reference docs — all appropriately sized for their type)
- **Files > 1,000 lines:** 1 (`methodology/aid-methodology.md`)
- **Test-to-code ratio (helper-script subset):** ⚠️ **Inferred from file counts.** There are now **18** canonical suites under `tests/canonical/` (including the 3 F4 doc-set suites from delivery-002), plus the shared `tests/lib/assert.sh` lib and the `tests/run-all.sh` glob-discovering aggregator. The suite count comfortably exceeds the helper-script count, so test coverage remains healthy for shell helpers (per-script LOC ratios drift with refactors and are not pinned here; recount with `ls tests/canonical/test-*.sh | wc -l`).
- **Open PRs:** delivery-002 (H5 resolution + 3 doc-set suites + KB update) is implemented on branch `aid/work-001-adaptive-kb`; PR pending (not yet merged to master).
