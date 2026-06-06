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
  - 2026-06-05: work-002-auto-installer — RESOLVED + removed the `[LOW] ps1 setup parity (SPS05-08) pwsh-skips in CI` item (per P9: closed items leave the body, git history is the audit trail). It is moot: `setup.sh`/`setup.ps1` (and their `test-setup*.sh` suites) were deleted and replaced by the `aid` CLI; the PowerShell installer path is now covered by the native-Windows `tests/windows/Test-AidInstaller.ps1` on the dedicated `.github/workflows/installer-tests.yml` `windows-latest` runner, so PowerShell coverage no longer depends on a `pwsh` being present on a Linux host. Also refreshed the Metrics test-count to 35.
  - 2026-06-03: cycle-10 /aid-housekeep refresh — corrected stale "18 canonical suites" → 24 (5 test-housekeep-* added by PR #49) and de-pinned the count per §9a; refreshed Last Updated.
  - 2026-06-01: post-merge work-001-add-providers (PRs #42/#43/#44) — recorded 4 open LOW residuals introduced by the 5-profile expansion (Copilot model-slug not live-tool-verified; Antigravity model-id tokenization inferred from display names; empty Antigravity [tool_names] identity-passthrough; ps1 setup parity pwsh-skips in CI). Per STATE.md Q23-Q25 these are Answered docs-only-noted residuals — appropriate to record as OPEN debt.
  - 2026-05-31: Inventory current — 0 open items. Per the documentation rule (kb-authoring P9), resolved tech-debt records are removed from this doc entirely once closed; git history is the audit trail.
---

# Tech Debt

> **Source:** `aid-researcher` (quality doc-set) (Phase 1), cycle-1
> **Status:** Complete
> **Last Updated:** 2026-06-03

> This document is a diagnosis, not a sprint plan. Severity tags use the form `[CRITICAL]` / `[HIGH]` / `[MEDIUM]` / `[LOW]` so `build-metrics.sh` (see the "Severity tag convention" note in `canonical/templates/knowledge-base/tech-debt.md`) can tally them.

---

## Summary

**Overall debt level: Low**. Rationale: the codebase itself is well-organized (Thin-Router skill convention, canonical/ as single source of truth, a comprehensive canonical test suite) and has **enforced pre-merge CI** (required status checks on `master`, 2026-05-29). The only open items are **4 LOW docs-only-noted residuals** from the work-001 5-profile expansion (PRs #42/#43/#44) — provider-mapping inferences and one CI-skip parity gap, none blocking. Resolved items are removed from this doc entirely once closed — git history is the only retained record.

| Severity | Open | Open items |
|----------|------|------------|
| Critical | 0 | — |
| High | 0 | — |
| Medium | 0 | — |
| Low | 4 | Copilot model-slug not live-tool-verified; Antigravity model-id tokenization inferred; empty Antigravity `[tool_names]` passthrough; ps1 setup parity pwsh-skips in CI |

> **Counting methodology:** this table counts unique **open** debt items (one row per entry, regardless of how many `[HIGH]`/`[MEDIUM]` tags appear in the fix recipe). Resolved items are removed from this doc entirely once closed; git history is the only retained record. The generated `metrics.md` (built by `build-metrics.sh`) counts every body-tag occurrence including those inside fix-recipe sub-bullets, producing higher totals. Neither is wrong; they answer different questions. Canonical item count is this table.

---

## Debt Inventory

> All four items below were introduced by the work-001-add-providers merge (PRs #42/#43/#44) and recorded as **docs-only-noted** residuals at merge time (per `STATE.md` Q23-Q25, now Answered). They are LOW because each ships a defensible, working default; the cost is future-confirmation, not current breakage.

### [LOW] Copilot `model:` slug spelling not live-tool-verified

- **Evidence:** `profiles/copilot-cli.toml` `[model_tiers]` block (the `large = "claude-opus-4.8"` / `medium = "claude-sonnet-4.6"` / `small = "claude-haiku-4.5"` lines + the preceding `# Slug spelling is docs-only-noted` comment). ⚠️ Inferred from GitHub's documented model-id convention — needs confirmation against the live Copilot CLI.
- **Impact:** The model *identities* (Opus 4.8 / Sonnet 4.6 / Haiku 4.5) are live-confirmed, but the exact `model:` field tokenization (lowercase-dotted slug) is asserted from GitHub's published convention, not exercised against the running tool. If Copilot expects a different slug form, the emitted Copilot agent frontmatter would name a model the tool does not resolve.
- **Effort:** ~15 min — run one Copilot CLI agent invocation and compare the accepted `model:` slug to the emitted values.

### [LOW] Antigravity model-id tokenization inferred from display names

- **Evidence:** `profiles/antigravity.toml` `[model_tiers.large]` / `[model_tiers.medium]` / `[model_tiers.small]` (`model = "gemini-3-pro"` + `reasoning_effort = "high"/"low"`, `model = "gemini-3-flash"`) + the `# Exact id/effort tokenization is docs-only-noted` and `# gemini-3-flash has no documented effort variant` comments. ⚠️ Inferred from vendor display names ("Gemini 3 Pro (high)") — needs confirmation.
- **Impact:** Antigravity docs expose display names rather than model-id token pairs, so the split into `model` + `reasoning_effort` (and the `gemini-3-flash` "low" placeholder) is a best-guess mapping. A mismatch with Antigravity's actual id/effort tokenization would emit rule frontmatter naming an unresolvable model.
- **Effort:** ~15 min — confirm the id/effort token form against Antigravity once a model-id convention is published or observable.

### [LOW] Empty Antigravity `[tool_names]` identity-passthrough

- **Evidence:** `profiles/antigravity.toml` `[tool_names]` block (empty map + the `# Q-F: empty map — identity passthrough (no published Antigravity tool-token map; docs-only-noted)` comment).
- **Impact:** With no published Antigravity tool-token map, canonical tool names pass through unchanged. If Antigravity later publishes a tool-token convention (renames like Copilot's `Bash → shell`), the emitted rules would use canonical names the tool does not recognize. Benign today (identity is a safe default); revisit if/when a vendor convention appears.
- **Effort:** ~10 min to populate the map once a vendor tool-token convention is published.

---

## Metrics

- **TODO/FIXME count:** net **0 unresolved code TODOs** — all occurrences in `canonical/` are template-explanatory mentions ("fill in TODO sections"), not unresolved code TODOs.
- **Large files:** the largest is the methodology spec (`docs/aid-methodology.md`); a handful of test suites, helper scripts, and detailed state-reference docs exceed 500 lines — all appropriately sized for their type. Exact file-size counts (T3) are not pinned here; see `.aid/generated/project-index.md` (`## Largest Files`).
- **Test-to-code ratio (helper-script subset):** ⚠️ **Inferred from file counts.** There are now **35** canonical suites under `tests/canonical/` (work-002 added the `aid` CLI installer/release suites — `test-install*.sh`, `test-aid-cli*.sh`, `test-release*.sh`, `test-version-sync.sh`, `test-ascii-only.sh`, `test-agents-md-invariant.sh`, `test-npm-installer.sh`, `test-pypi-installer.sh`), plus the native-Windows `tests/windows/Test-AidInstaller.ps1`, the shared `tests/lib/assert.sh` lib, and the `tests/run-all.sh` glob-discovering aggregator. The suite count comfortably exceeds the helper-script count, so test coverage remains healthy for shell helpers (per-script LOC ratios drift with refactors and are not pinned here; recount with `ls tests/canonical/test-*.sh | wc -l`).
- **Open PRs:** none representing tracked debt.
