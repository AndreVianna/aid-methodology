---
kb-category: primary
source: hand-authored
objective: Known AID methodology repository technical debt: severity, evidence, impact, and resolution roadmap per item.
summary: Documents known technical debt items in the AID methodology repo with severity, evidence, impact assessment, and resolution roadmap for each open item.
tags: [tech-debt, gotchas, severity-tags, render-pipeline-traps, installer-hygiene, ci-pitfalls]
audience: [maintainer, developer, architect]
see_also: [test-landscape.md, infrastructure.md, module-map.md]
sources: []
approved_at_commit: ccb4e823
contracts: []
changelog:
  - 2026-06-23: Migrated by migrate-kb-frontmatter.sh: intent retired, objective/summary/sources added
  - 2026-06-06: work-004-product-site (dogfooding) — added `[LOW] Release/installer hygiene` item (maintainer-only `check-version-sync.sh` is emitted into all profiles though only CI uses the canonical copy; `.aid/` manifest/version persistence undefined; `docs/install.md:445` claims an auto-`.gitignore` the installer doesn't do; root `.claude/` was missing the release script — restored). Corrected the Summary table + Debt Inventory intro (dropped the already-resolved ps1 item per the 2026-06-05 entry; open count stays 4).
  - 2026-06-05: work-002-auto-installer — RESOLVED + removed the `[LOW] ps1 setup parity (SPS05-08) pwsh-skips in CI` item (per P9: closed items leave the body, git history is the audit trail). It is moot: `setup.sh`/`setup.ps1` (and their `test-setup*.sh` suites) were deleted and replaced by the `aid` CLI; the PowerShell installer path is now covered by the native-Windows `tests/windows/Test-AidInstaller.ps1` on the dedicated `.github/workflows/installer-tests.yml` `windows-latest` runner, so PowerShell coverage no longer depends on a `pwsh` being present on a Linux host. Also refreshed the Metrics test-count to 35.
  - 2026-06-03: cycle-10 /aid-housekeep refresh — corrected stale "18 canonical suites" → 24 (5 test-housekeep-* added by PR #49) and de-pinned the count per §9a; refreshed Last Updated.
  - 2026-06-01: post-merge work-001-add-providers (PRs #42/#43/#44) — recorded 4 open LOW residuals introduced by the 5-profile expansion (Copilot model-slug not live-tool-verified; Antigravity model-id tokenization inferred from display names; empty Antigravity [tool_names] identity-passthrough; ps1 setup parity pwsh-skips in CI). Per STATE.md Q23-Q25 these are Answered docs-only-noted residuals — appropriate to record as OPEN debt.
  - 2026-05-31: Inventory current — 0 open items. Per the documentation rule (kb-authoring P9), resolved tech-debt records are removed from this doc entirely once closed; git history is the audit trail.
---

# Tech Debt

> **Source:** `aid-researcher` (quality doc-set) (Phase 1), cycle-1
> **Status:** Complete
> **Last Updated:** 2026-06-06

> This document is a diagnosis, not a sprint plan. Severity tags use the form `[CRITICAL]` / `[HIGH]` / `[MEDIUM]` / `[LOW]` so `build-metrics.sh` (see the "Severity tag convention" note in `canonical/templates/knowledge-base/tech-debt.md`) can tally them.

---

## Summary

**Overall debt level: Low**. Rationale: the codebase itself is well-organized (Thin-Router skill convention, canonical/ as single source of truth, a comprehensive canonical test suite) and has **enforced pre-merge CI** (required status checks on `master`, 2026-05-29). The only open items are **4 LOW** non-blocking residuals — three docs-only-noted provider-mapping inferences from the work-001 5-profile expansion (PRs #42/#43/#44), plus one **release/installer-hygiene** cluster surfaced during work-004. Resolved items are removed from this doc entirely once closed — git history is the only retained record.

| Severity | Open | Open items |
|----------|------|------------|
| Critical | 0 | — |
| High | 0 | — |
| Medium | 0 | — |
| Low | 4 | Copilot model-slug not live-tool-verified; Antigravity model-id tokenization inferred; empty Antigravity `[tool_names]` passthrough; release/installer hygiene (version-sync script ships to adopters + `.aid/` metadata persistence undefined + stale install doc) |

> **Counting methodology:** this table counts unique **open** debt items (one row per entry, regardless of how many `[HIGH]`/`[MEDIUM]` tags appear in the fix recipe). Resolved items are removed from this doc entirely once closed; git history is the only retained record. The generated `metrics.md` (built by `build-metrics.sh`) counts every body-tag occurrence including those inside fix-recipe sub-bullets, producing higher totals. Neither is wrong; they answer different questions. Canonical item count is this table.

---

## Debt Inventory

> The **first three** items below were introduced by the work-001-add-providers merge (PRs #42/#43/#44) and recorded as **docs-only-noted** residuals at merge time (per `STATE.md` Q23-Q25, now Answered). They are LOW because each ships a defensible, working default; the cost is future-confirmation, not current breakage. The **fourth** (release/installer hygiene) was surfaced during work-004-product-site and is LOW because nothing is broken today (CI uses the canonical copy; the pipeline never calls the script).

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

### [LOW] Release/installer hygiene: maintainer-only version-sync script ships to adopters; `.aid/` metadata persistence undefined; stale install doc

> Surfaced 2026-06-06 during work-004-product-site (dogfooding — user ran `aid add` on the repo). A cluster of related, non-blocking hygiene gaps around the installer + release tooling. Earmarked for a dedicated "release/installer hygiene" lite work.

- **Evidence:**
  - **(a) Stale install doc.** `docs/install.md:445` states "`.aid/` is appended to your `.gitignore` by default," but **no shipped installer code writes to `.gitignore`** (`grep -rn gitignore install.sh bin/aid lib/aid-install-core.sh lib/AidInstallCore.psm1` → none). Doc/code mismatch.
  - **(b) No `.aid/` VCS-persistence policy.** `aid add` writes `.aid/.aid-manifest.json` + `.aid/.aid-version` — the install receipt/lockfile that `aid update`/`aid uninstall` require (they exit `6` "no manifest" without it) — but they land **untracked** and the installer defines no commit/ignore policy. A teammate who clones a repo with a committed `.claude/` but no manifest cannot `aid update`/`uninstall`, and there is no VCS record of the installed version.
  - **(c) Maintainer-only script shipped to adopters.** `canonical/scripts/release/check-version-sync.sh` is referenced **only** by `.github/workflows/release.yml:114` (which calls the *canonical* copy) and `tests/canonical/test-version-sync.sh` — **no `SKILL.md` references it** — yet the generator emits it into all five profiles (`profiles/*/emission-manifest.jsonl`) and hence into every adopter install, where nothing uses it (dead weight).
  - **(d) Root tree drift (symptom of (c)).** The repo's own root `.claude/` committed tree had drifted — it was missing `scripts/release/check-version-sync.sh` (present in canonical + all profiles). Restored 2026-06-06 by committing the file on the work-004 branch so root matches the claude-code profile.
- **Impact:** No current breakage — CI uses the canonical copy and the adopter pipeline never calls the script. Costs: adopters carry an unused maintainer script in every install; the install doc misleads about `.gitignore` behavior; and AID's own version-control state (manifest/version) is not persisted by default, so update/uninstall and version-drift detection do not survive a clone.
- **Resolution roadmap (dedicated lite work):**
  1. Relocate `check-version-sync.sh` to a maintainer-only, **non-emitted** path that CI calls; remove it from `canonical/scripts/release/` so it stops shipping to profiles. Re-run the FULL generator; update emission manifests + the root `.claude/` mirror.
  2. Define + implement a `.aid/` VCS-persistence policy: write a scoped `.aid/.gitignore` (ignore `.temp/`, `.heartbeat/`, `knowledge/.cache/`; pick a KB/works default) while **keeping** `.aid/.aid-manifest.json` + `.aid/.aid-version` tracked.
  3. Fix `docs/install.md:445` to match actual behavior.
- **Effort:** ~half a day (generator change + emission manifests + docs + a test).

---

## Gotchas

> The non-obvious traps a newcomer to the AID repo cannot infer from the code -- a config
> that must change in lockstep, a build step that must run first, a "looks safe but isn't"
> edit. State the trap, then the safe way through it. One gotcha per bullet, grep-findable.

- **Edit `canonical/`, never a rendered tree:** changing a file under
  `profiles/{...}/` or the dogfood `.claude/` is overwritten on the next render and fails
  `verify_deterministic.py`. The safe way: edit `canonical/`, then run
  `python .claude/skills/generate-profile/scripts/run_generator.py` (the FULL generator,
  not a per-script renderer) -- a partial render leaves stale emission manifests and CI
  render-drift fails.
- **A new/removed skill drifts ~10 KB docs:** the "N user-facing skills" counts are
  scattered across the KB and CI does not catch the drift. Reconcile via `/aid-housekeep`,
  never inline.
- **Tests that fire the migration scan MUST pin `HOME`:** the scan defaults its root to
  `$HOME`; a test that does not `export HOME=<throwaway>` migrates the developer's real
  repos. Pin both `HOME` and `AID_HOME`, with an escape canary.
- **Shipped CLI/installer scripts must be ASCII-only and Windows-PowerShell-5.1-compatible:**
  a no-BOM UTF-8 script is mis-parsed under the Windows ANSI codepage; PS must avoid
  TLS-1.2-absent, 3-arg `Join-Path`, and `utf8NoBOM`. CI-guarded -- but the Windows-only
  installer test runs ONLY on the windows runner, not in `run-all.sh`, so a green local run
  can still fail Windows CI.
- **`INDEX.md` regen uses the canonical script:** regenerate via
  `canonical/aid/scripts/kb/build-kb-index.sh`, not the `.claude/` copy, or the KB-hygiene
  CI check fails on the embedded script path.
- **npm/PyPI versions are irreversible:** a published version number can never be reused.
  Verify every channel (GitHub/npm/PyPI, bash/PS) before publishing; a green first-run is a
  starting suspicion, not a verdict.

---

## Metrics

- **TODO/FIXME count:** net **0 unresolved code TODOs** — all occurrences in `canonical/` are template-explanatory mentions ("fill in TODO sections"), not unresolved code TODOs.
- **Large files:** the largest is the methodology spec (`docs/aid-methodology.md`); a handful of test suites, helper scripts, and detailed state-reference docs exceed 500 lines — all appropriately sized for their type. Exact file-size counts (T3) are not pinned here; see `.aid/generated/project-index.md` (`## Largest Files`).
- **Test-to-code ratio (helper-script subset):** ⚠️ **Inferred from file counts.** There are now **35** canonical suites under `tests/canonical/` (work-002 added the `aid` CLI installer/release suites — `test-install*.sh`, `test-aid-cli*.sh`, `test-release*.sh`, `test-version-sync.sh`, `test-ascii-only.sh`, `test-agents-md-invariant.sh`, `test-npm-installer.sh`, `test-pypi-installer.sh`), plus the native-Windows `tests/windows/Test-AidInstaller.ps1`, the shared `tests/lib/assert.sh` lib, and the `tests/run-all.sh` glob-discovering aggregator. The suite count comfortably exceeds the helper-script count, so test coverage remains healthy for shell helpers (per-script LOC ratios drift with refactors and are not pinned here; recount with `ls tests/canonical/test-*.sh | wc -l`).
- **Open PRs:** none representing tracked debt.
