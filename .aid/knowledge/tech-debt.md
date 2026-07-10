---
kb-category: primary
source: hand-authored
objective: Severity-classified open technical and methodology debt in AID — dead code, lockstep-config hazards, blocked release channels, stale docs, large files, and security observations — each with location, risk, and resolution note.
summary: Read this before starting work in any area; declared debt items and the non-obvious gotchas (lockstep manifests, master-only gates, render-drift ordering, HOME-pinning) may change your approach or scope.
sources:
  - install.sh
  - dashboard/MANIFEST
  - tests/canonical/test-dashboard-manifest.sh
  - lib/aid-install-core.sh
  - docs/repository-structure.md
  - canonical/EMISSION-MANIFEST.md
  - canonical/aid/scripts/execute/writeback-state.sh
  - .claude/skills/generate-profile/SKILL.md
  - .github/workflows/release.yml
  - release.sh
  - .github/workflows/test.yml
  - .aid/generated/project-index.md
tags: [C7, tech-debt, risk, security, gotchas, remediation]
see_also: [test-landscape.md, infrastructure.md, quality-gates.md, architecture.md]
owner: architect
audience: [developer, architect, pm]
intent: |
  Severity-tagged open technical and methodology debt with locations, risk, and
  remediation. Includes security observations (as debt items) and the non-obvious
  gotchas a change will trip. Diagnosis, not a sprint plan.
contracts: []
changelog:
  - 2026-06-25: Initial debt audit (aid-discover quality deep-dive)
---

# Tech Debt

This document is a diagnosis, not a sprint plan. It records what currently exists so agents
do not create more of it. **Only currently-open debt is listed**; resolved items are removed
entirely (git history is the audit trail).

A note on overall health: AID's source is unusually clean for its size. A scan for genuine
`TODO`/`FIXME`/`XXX`/`HACK` markers across `canonical/`, `lib/`, `bin/`, `dashboard/`,
`install.sh`, `install.ps1`, and `release.sh` returns **zero real markers** — the only hits
are `mktemp ... XXXXXX` templates (CONFIRMED via grep). The debt below is therefore
structural and methodological, not littered code.

## Contents

- [Debt Inventory](#debt-inventory)
- [Detailed Debt Items](#detailed-debt-items)
- [Complexity Hotspots](#complexity-hotspots)
- [Missing Test Coverage](#missing-test-coverage)
- [Outdated Dependencies](#outdated-dependencies)
- [Duplication](#duplication)
- [Dead Code](#dead-code)
- [Security Observations](#security-observations)
- [Gotchas](#gotchas)
- [Change Log](#change-log)

---

## Debt Inventory

_No open items — see [Change Log](#change-log) for the resolution history._

**Risk definitions:** High = active risk to reliability/security/maintainability of core
flows; Medium = growing cost, becomes high if unaddressed in 1-2 cycles; Low = known, not
urgent.

---

## Detailed Debt Items

_No open items._

---

## Complexity Hotspots

Large files concentrate complexity (line counts drift — measure on demand). CONFIRMED via
`.aid/generated/project-index.md` "Top 20 Largest Source Files".

| File | Why complex | Notes |
|------|-------------|-------|
| `dashboard/server/reader.mjs` (~4012) | Full KB/state parser re-implemented in Node | Triplicated (see Duplication) |
| `tests/canonical/test-aid-cli-parity.sh` (~3198) | Exhaustive bash↔PS behavior matrix | Large but flat assertions |
| `tests/windows/Test-AidInstaller.ps1` (~2406) | Whole installer surface in one PS script | Windows-CI only |
| `dashboard/reader/parsers.py` (~2232) | Python KB/state parser | Triplicated |
| `lib/aid-install-core.sh` (~2160) | The install/update/remove engine | Triplicated; most load-bearing shell file |
| `install.sh` (~1043) | Bootstrap + provisioning | Down from ~1380 after L3 (legacy flag-style install path removed) |
| `.claude/skills/.../render.py` (~1019) | The profile renderer | Has self-tests |

---

## Missing Test Coverage

| Module / Function | Coverage | Type missing | Risk |
|------------------|----------|--------------|------|
| Prompt-driven skill state machines | none (by design) | integration | Accepted — needs AI host + human; covered by dogfooding + review |
| Astro site components | partial | unit | Build is the main gate; component logic lightly tested |
| Windows installer path | strong but Windows-CI-only | — | A green local `run-all.sh` does not exercise it (see Gotchas: master-only heavy gates) |

---

## Outdated Dependencies

No CVE-flagged or end-of-life dependency was identified. AID's runtime payload is shell +
markdown with near-zero third-party runtime dependencies (the npm package advertises zero
runtime deps). Heavier dependency trees are confined to the **separate** `site/` Astro build
(`site/package-lock.json`) and the summarize Playwright tooling
(`.claude/aid/scripts/summarize/package.json`); `.github/dependabot.yml` is configured to
track updates. No action item beyond letting Dependabot run. CONFIRMED via project-index
(manifests list) + `dependabot.yml` presence.

---

## Duplication

> Intentional duplication — do not "deduplicate"; it is the source-of-truth + vendored-copy
> design. Listed so a change knows every copy to update.

| Area | Copies | Risk if not kept in sync |
|------|--------|--------------------------|
| `reader.mjs` | `dashboard/`, `packages/npm/dashboard/`, `packages/pypi/aid_installer/_vendor/dashboard/` | Dashboard behaves differently per install channel |
| `parsers.py` | same three locations | Same |
| `aid-install-core.sh` | `lib/`, `packages/npm/lib/`, `packages/pypi/aid_installer/_vendor/lib/` | Install logic diverges per channel |
| `canonical/` toolkit | rendered into 5 `profiles/` + `.claude/` | Caught by the render-drift gate (CI) |

The `canonical/ → profiles/` duplication is machine-guarded (render-drift). The
`dashboard`/`lib` vendored copies are guarded by the channel install suites; the vendoring is
done at build/pack time by `vendor.js` / `vendor.py`, so editing the source-of-truth copy and
re-vendoring is the correct workflow. The **dashboard file *set*** (which files make up the
server+reader unit) is no longer duplicated: all five install/vendor paths derive it from the
single-source `dashboard/MANIFEST`, guarded by `tests/canonical/test-dashboard-manifest.sh`
(H1, resolved 2026-07-10).

---

## Dead Code

No dead code is currently identified. A scan of the shipped scripts finds no unreachable
branches. (The previously-listed `OVERALL_BLOCKED` / `exit 5` / `.aid-new` protect-on-diff
branch was removed from `install.sh` + `install.ps1`; git history is the audit trail.)

---

## Security Observations

Security findings are recorded here as debt items (there is no separate security doc).
Overall posture is solid for a CLI installer; the main inherent risk is the bootstrap trust
model.

| Observation | Severity | Detail |
|---|---|---|
| `curl\|bash` / `irm\|iex` bootstrap | Medium (inherent) | Users pipe a remote script to a shell. Mitigated: the bootstrap fetches the CLI bundle + libs from a **pinned release tag** and verifies them against `SHA256SUMS` before sourcing (CONFIRMED in `release.sh` Step 6 comment + `install.sh` lib-fetch). The trust root is the GitHub Release. |
| No detached signature on GitHub tarballs | Low (accepted) | `release.sh --sign` is a stub (a deferred feature, not wired into `release.yml`). Accepted as not-needed: npm publishes with `--provenance` and PyPI with PEP 740 sigstore attestations (the channels most users install from), and GitHub tarballs are checksum-verified against `SHA256SUMS`. A detached GPG signature would add key-management burden for marginal gain; revisit only if the threat model changes. |
| Publish auth uses OIDC Trusted Publishing | Positive | npm publishes with `--provenance`; PyPI publishes with PEP 740 attestations via `pypa/gh-action-pypi-publish` — both token-less via OIDC. CONFIRMED in `release.yml`. |
| Least-privilege CI permissions | Positive | `test.yml` / `installer-tests.yml` use `permissions: contents: read`; `release.yml` grants only `contents: write` + `id-token: write`; `docs.yml` only `pages: write` + `id-token: write`. CONFIRMED. |
| Optional `NPM_TOKEN` classic automation token | Low | If OIDC is not used for npm, a classic `NPM_TOKEN` secret is the fallback (`release.yml` header). Prefer Trusted Publishing to avoid storing a long-lived token. |
| No secrets committed | Positive | No credentials in tracked files; auth is via CI secrets/OIDC only. |
| Dashboard binds localhost by default | Positive | The dashboard server binds `127.0.0.1`; `--remote` is a clear-fail stub (exit 10), so it cannot accidentally expose state on a network. CONFIRMED in `installer-tests.yml` dashboard smoke. |

---

## Gotchas

> Non-obvious traps a contributor cannot infer from the code alone. State the trap, then the
> safe way through it.

- **Master-only heavy gates:** the full canonical suite (`test.yml`) and Astro build
  (`docs.yml`) run on `master`/release-tag only; feature branches run only
  `installer-tests.yml`. A direct merge can red-master in ways the branch never saw. Run
  `bash tests/run-all.sh` (HOME-pinned) and the `site` build locally before merge.
- **HOME-pinning before any migration-scan test:** the migration scan defaults its root to
  `$HOME`; a test firing it must `export HOME=<throwaway>`, not just `AID_HOME`, or it
  migrates the developer's real repos. CI also checks the repo out (with its own `.aid/`)
  under `$HOME`, so isolation canaries must snapshot `REAL_HOME` before/after.
- **Render-drift needs the FULL generator:** after editing `canonical/`, run
  `python .claude/skills/generate-profile/scripts/run_generator.py` (the full generator), not
  a per-script renderer — otherwise the render-drift gate fails on stale `profiles/`
  emission manifests.
- **One dashboard manifest, five consumers:** the dashboard server+reader file set lives in
  `dashboard/MANIFEST` (one path per line). `install.sh`, `install.ps1`, `vendor.js`,
  `vendor.py`, and `release.sh`'s CLI bundle all DERIVE their file set from it — never re-list
  the files inline. Add/remove a dashboard source file by editing `dashboard/MANIFEST` only;
  `tests/canonical/test-dashboard-manifest.sh` fails CI if the manifest drifts from the curated
  `dashboard/` tree or if a consumer stops referencing it (H1 guard).
- **Four version carriers must agree:** `VERSION`, `packages/npm/package.json`,
  `packages/pypi/pyproject.toml`, and the git tag must all match, or
  `check-version-sync.sh` fails the release `gate`. Bump them together.
- **Edit `canonical/`, never `profiles/`:** `profiles/` is generated build output; hand-edits
  are wiped on the next render and fail render-drift.
- **ASCII-only shipped PowerShell:** Windows decodes no-BOM UTF-8 in the ANSI codepage and
  mis-parses non-ASCII; `test-ascii-only.sh` + `test-ps51-compat.sh` gate this. Keep shipped
  `.ps1`/`.psm1` ASCII and 5.1-compatible (no 3-arg `Join-Path`, no `-Encoding utf8NoBOM`,
  no `$IsWindows`, force TLS 1.2).
- **Web-output reviews require Playwright:** reviewing `kb.html` or the site by reading
  HTML/CSS is not a valid review — render and visually validate (the `visual-fidelity` gate).
- **`master` is branch-protected:** the bot identity cannot push to `master`; always open a
  PR (never direct-push/force-push master).

---

## Change Log

| Rev | Date | Source | Description |
|-----|------|--------|-------------|
| 1.0 | 2026-06-25 | aid-discover | Initial debt audit (quality deep-dive) |
| 1.1 | 2026-06-26 | wrap-up | L1 RESOLVED (dead `OVERALL_BLOCKED`/exit-5/`.aid-new` branch removed from install.sh + install.ps1). Triaged feature-015 follow-ups into debt: added M4 (single-viewport gate gap), L5 (cosmetic/hygiene), L6 (DBI node_modules orphan-scan). |
| 1.2 | 2026-06-26 | wrap-up | M2 RESOLVED — `docs.yml` Astro build now gates `pull_request` to master (test.yml canonical suite already did); `deploy` stays master-only. Marking the checks branch-protection-required is an owner action. |
| 1.3 | 2026-06-27 | feature-007/task-008 | M1 DEFERRED — workflow is OIDC-ready (`npm-publish` gated `if: vars.NPM_ENABLED == 'true'` L217; `pypi-publish` gated `if: vars.PYPI_ENABLED == 'true'` L284 in release.yml); closure is owner-gated/externally-blocked (npm @aid scope + PyPI org/Trusted-Publisher + variable flip); deferred to next public release cycle. |
| 1.4 | 2026-06-27 | work-001/task-009 | L7 RESOLVED -- aid-researcher granted WebSearch + WebFetch; RESEARCH tasks requiring a web survey can now use the type-appropriate executor instead of falling back to general-purpose agents. |
| 1.5 | 2026-06-28 | work-aid-interview-improvements | Corrected skill count from 13 to 14 in M3 inventory row and M3 detailed description (aid-interview split into aid-describe + aid-define). |
| 1.6 | 2026-07-08 | PR #132 (change-delivery) | Updated the M3 stale-doc description: live reality is now `deliveries/delivery-NNN/tasks/task-NNN/` (full path, nested under `deliveries/`) / `tasks/task-NNN/` (lite path, no `delivery-NNN/` folder), superseding the flat `delivery-NNN/tasks/task-NNN/` shape. |
| 1.7 | 2026-07-09 | work-001 lite-skills refresh | Deleted resolved-in-place items per the removal convention: M2 (heavy gates now gate PRs), L1 (dead install branch removed), L7 (aid-researcher web tools granted in work-001) — closure stays in this log + git. Rewrote M3 to the live remaining drift (EMISSION-MANIFEST 3-of-5 profiles + uncaught prose-count drift), dropping deleted-recipe references and the now-reconciled repository-structure.md / aid-methodology.md instances. Added L8 (writeback-state.sh octal-leading-zero id footgun) + L9 (generate-profile VALIDATE hard-codes a stale 14-skill list). Cleared the Dead Code table; dropped L1 from the install.sh complexity-hotspot note; fixed the dangling M2 reference in Missing Test Coverage. |
| 1.8 | 2026-07-09 | v2.1.0 skill-count sync | L9 updated to the current state: the v2.1.0 follow-on grew `canonical/skills/` from 82 to 92 (14 classic + `aid-triage` + `aid-ask` + 76 shortcuts), so VALIDATE's stale 14-skill list now leaves 78 (not 68) unlisted directories unvalidated. |
| 1.9 | 2026-07-10 | v2.1.0 debt re-validation | Validated every open item against disk/CI evidence and removed the stale-resolved ones per the removal convention: **M1** (npm+PyPI publish jobs SUCCEED on the v2.0.6 release run — channels are live, never "blocked/GitHub-only"), **M4** (the visual gate already asserts no-overflow at 732px + 390px — the proposed T4 remediation is implemented), **L6** (DBI orphan-scan now skips gitignored `node_modules/`/`.git/`), **L8** (all `printf '%03d'` sinks in `writeback-state.sh` are now `$((10#$id))`-normalized), **L9** (generate-profile VALIDATE now derives "92" from the catalog, not a hard-coded 14). Reframed **L2** as accepted/won't-do (npm/PyPI already emit sigstore/OIDC provenance; a detached tarball signature is not needed) and moved it to Security Observations. Narrowed **M3** to the remaining no-CI-guard-for-count-drift gap (the `EMISSION-MANIFEST.md` 3-of-5 profile enumeration was reconciled to 5). Updated **L3** remediation (deprecation window has closed; excise as its own installer-CI-gated change). Removed the now-obsolete zero-padded-id gotcha (closed with L8). **Remaining open: H1, M3, L3, L4.** |
| 2.0 | 2026-07-10 | tech-debt-followup | **H1 RESOLVED** — extracted the dashboard server+reader file set into a single source, `dashboard/MANIFEST`; `install.sh`, `install.ps1`, `packages/npm/scripts/vendor.js`, `packages/pypi/scripts/vendor.py`, and `release.sh` now all derive the set from it (the MANIFEST is bundled into the CLI tarball and both vendored payloads so bootstrap/sdist paths read it from a trusted, self-describing payload). New guard `tests/canonical/test-dashboard-manifest.sh` fails CI if the manifest drifts from the curated `dashboard/` tree or a consumer stops referencing it. This work uncovered and fixed a **live, unshipped correctness/security bug**: `dashboard/reader/io_bounds.py` (the v2.1.0 5 MB bounded-read DoS guard, added in `d2238d8a` and imported by `reader.py` at 9 sites) was **absent from all five manifests plus the two installer-test expected-file lists** — so a v2.1.0 cut would have vendored a `reader.py` that `ImportError`s on npm/PyPI/curl-bash. The manifest includes it; both vendored payloads now carry it (byte-verified). Updated `test-npm-installer.sh` (NM08) and `test-pypi-installer.sh` (PW05) to derive their expected sets from the manifest rather than a hand-maintained copy. **Remaining open: M3, L3, L4.** |
| 2.1 | 2026-07-10 | tech-debt-followup | **M3 RESOLVED** — added `tests/canonical/test-doc-counts.sh`, a CI guard (runs in `test.yml` on PR-to-master + the release gate via `run-all.sh`) that derives the canonical counts (skills/agents/profiles from the tree, catalog rows/canonical/alias/repurpose from `shortcut-catalog.yml`) and asserts every user-facing surface (README, `docs/*`, the five profile READMEs) states the CURRENT number. Needles are parameterized on the derived count, so they auto-update when the tree legitimately changes and never assert changelog/history lines (no false positives). Scope excludes the KB (`.aid/knowledge/`), which carries version-history sections and is reconciled by `/aid-housekeep`. Fixed the live drift the guard exposed: `docs/install.md` read "82 skills / 67 shortcuts" → corrected to 92 / 76. **Remaining open: L3, L4.** |
| 2.2 | 2026-07-10 | tech-debt-followup | **L4 RESOLVED** — recorded the deliberate no-line-coverage decision as ADR **D26** in `decisions.md` (suite-presence coverage is the right model for a shell/markdown toolkit: the product is ~1800 Markdown/prompt + ~327 shell files + a byte-identical render, so a coverage `%` would instrument only the small `dashboard`/`site` minority and mislead). Firmed up `test-landscape.md` §"Coverage Assessment" from "document the deliberate choice" (an open recommendation) to a ratified reference to D26. No coverage tooling adopted (validated premise: it would be security-theater metrics, not a real signal). **Remaining open: L3.** |
| 2.3 | 2026-07-10 | tech-debt-followup | **L3 RESOLVED** — excised the legacy flag-style direct-install path (`--tool`/`--update`/`--uninstall`/`--target`; PS `-Tool`/`-Update`/`-Uninstall`/`-TargetDirectory`) from `install.sh` + `install.ps1`. Mode-detection now routes an unrecognized flag or unknown first positional to a usage error (exit 2) instead of the retired LEGACY dispatch; `--from-bundle` stays a valid BOOTSTRAP/CONVENIENCE flag. `install.ps1` gained `[CmdletBinding(PositionalBinding=$false)]` (bare words land in `$RemainingArgs`, not `-Version`/`-FromBundle` positions) + a declared-but-inert `-Uninstall` switch so prefix-matching cannot alias a stray `-Uninstall` to `-UninstallCli`. Reworded the `detect_tool`/`Detect-Tool` shared-lib error strings that named the removed flag. Tests + docs updated in lockstep: `test-release-install-e2e.sh` and `tests/windows/Test-AidInstaller.ps1` cases that drove distinct install/update/uninstall mechanisms were **converted** to the new `install.sh add/update/remove <tool>` front door (not deleted); `test-install{,-ps1,-parity}.sh` were trimmed to the surviving usage-error/help/piped/static-parity surface (the tool-install mechanics they set up via `--tool` are still exercised through `aid add`/`aid remove` in `test-aid-cli{,-ps1}.sh`); the LEGACY routing cases (CLI027-Q, PS028-Q, PAR01-12, IN02-40) were removed. The one **security**-relevant guard that did not depend on the legacy path — lib-fetch tamper / PWNED-prevention (a tampered `aid-install-core.sh` must exit 4 and never be sourced) — was preserved by **re-adding it via the bootstrap path** as `test-release-install-e2e.sh` E2E09k-n. `bash install.sh --tool/--update/--uninstall/--target` → exit 2 verified locally; PS side + full install suites validated in CI. **All tech-debt items resolved — inventory is empty.** |
