---
kb-category: primary
source: hand-authored
objective: Severity-classified open technical and methodology debt in AID — dead code, lockstep-config hazards, blocked release channels, stale docs, large files, and security observations — each with location, risk, and resolution note.
summary: Read this before starting work in any area; declared debt items and the non-obvious gotchas (lockstep manifests, master-only gates, render-drift ordering, HOME-pinning) may change your approach or scope.
sources:
  - install.sh
  - lib/aid-install-core.sh
  - docs/repository-structure.md
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

| ID | Type | Description | Location | Risk | Effort | Priority |
|----|------|-------------|----------|------|--------|----------|
| **H1** | Architecture / lockstep | Five install manifests must stay byte-lockstep on the dashboard file set; a silent omission breaks provisioning on one channel | install.sh, install.ps1, vendor.js, vendor.py, release.sh | High | M | P1 |
| **M1** | Shipping gap | npm + PyPI publish channels are correct but BLOCKED on external account setup; effectively GitHub-only today | .github/workflows/release.yml | Medium | M (external) | P2 |
| **M2** | Test gap / process | Full canonical suite + Astro build run on master/tag only; feature branches skip them | .github/workflows/{test,docs}.yml | Medium | S | P2 |
| **M3** | Stale documentation | Contributor doc cites wrong skill/recipe counts + wrong path | docs/repository-structure.md | Medium | S | P2 |
| **L1** | Dead code | Unreachable `OVERALL_BLOCKED` / `exit 5` / `.aid-new` protect-on-diff branch | install.sh | Low | S | P3 |
| **L2** | Deferred feature | `release.sh --sign` exits non-zero (signing not implemented) | release.sh | Low | M | P3 |
| **L3** | Deprecation debt | Legacy flag-style install path "retained for one release" | install.sh | Low | S | P3 |
| **L4** | Test gap | No line-coverage metric or `%` enforcement anywhere | (whole pipeline) | Low | M | P3 |

**Risk definitions:** High = active risk to reliability/security/maintainability of core
flows; Medium = growing cost, becomes high if unaddressed in 1-2 cycles; Low = known, not
urgent.

---

## Detailed Debt Items

### [HIGH] H1 -- Five install manifests must stay lockstep on the dashboard file set

**Type:** Architecture / lockstep config

**Description:** The dashboard server+reader file set is vendored independently by five
install paths. There is no single shared list — each manifest hard-codes the files. Omitting
one file from one manifest silently breaks that channel (a real bug shipped this way: the
release CLI bundle once omitted `dashboard/home.html`, so the `curl|bash` + release-bundle
path provisioned no `home.html` while npm/PyPI were fine).

**Location:**
- `install.sh` — bootstrap fetch + provisioning
- `install.ps1` — PowerShell bootstrap
- `packages/npm/scripts/vendor.js` — npm prepack vendoring
- `packages/pypi/scripts/vendor.py` — hatchling build-hook vendoring
- `release.sh` — the `aid-cli-v*.tar.gz` CLI bundle (its `home.html` copy carries an explicit
  lockstep comment naming the other four)

**Risk if unaddressed:** A per-channel install regression that passes most tests (only the
affected channel breaks) and is easy to miss because the other four channels look healthy.

**Remediation:** Keep all five in lockstep on any dashboard file-set change; the
`test-npm-installer.sh` / `test-pypi-installer.sh` / `test-release-install-e2e.sh` suites plus
the Windows channel smokes are the guard. Consider extracting a single shared file-list.
Effort: M.

---

### [MEDIUM] M1 -- npm and PyPI channels blocked on external setup

**Type:** Shipping gap

**Description:** `release.yml` has fully-written `npm-publish` and `pypi-publish` jobs, but
both are gated `if: vars.NPM_ENABLED == 'true'` / `PYPI_ENABLED == 'true'` and require
external accounts that are not yet provisioned (the `@aid` npm scope; the CasuloAI Labs PyPI
org + reserved `aid-installer` name + a Trusted Publisher). Until those exist and the repo
variables are flipped, releases publish to the **GitHub Releases channel only**.

**Location:** `.github/workflows/release.yml` (header "External-setup blockers" + the two
publish jobs).

**Risk if unaddressed:** Users following npm/PyPI install instructions may hit a missing or
stale package; the documented "4 channels" is effectively fewer until enabled.

**Remediation:** Create the scope/org, store credentials/Trusted Publishers, flip
`NPM_ENABLED` / `PYPI_ENABLED`. External, not code. Effort: M (external).

---

### [MEDIUM] M2 -- Heavy correctness gates run on master/tag only

**Type:** Test gap / process

**Description:** The full canonical suite (`test.yml` `canonical-tests`) and the Astro site
build (`docs.yml`) trigger only on `master` (and the release tag via `release.yml gate`).
Feature branches run only `installer-tests.yml`. A change that breaks the canonical suite or
the site build can pass every feature-branch check and fail only after merge.

**Location:** `.github/workflows/test.yml` (`on: push/pull_request branches: [master]`),
`.github/workflows/docs.yml` (`on: push branches: [master]` + path filter).

**Risk if unaddressed:** A direct merge can red-master in ways the feature branch never saw
(this has happened — the master CI broke three ways from exactly this gap).

**Remediation:** Run `bash tests/run-all.sh` (HOME-pinned) and the `site` build locally
before merge. See [Gotchas](#gotchas). Effort: S (discipline).

---

### [MEDIUM] M3 -- Stale counts in docs/repository-structure.md

**Type:** Stale documentation (methodology debt)

**Description:** The contributor map says "12 skill definitions" and "51 lite-path recipes"
and references the path `canonical/recipes/`. Reality: `canonical/skills/` holds 13 skill
directories, recipes live at `canonical/aid/recipes/` (note the `aid/` segment) with 52
files. Adding/removing a canonical skill leaves "N user-facing skills" counts stale across
roughly ten KB/doc surfaces; CI does not catch this. Two related source-doc drifts share this
item: `docs/aid-methodology.md` ("## 7. Artifacts Reference") describes the flat task layout
`.aid/{work}/tasks/task-NNN.md` while the live skills + `work-state-template.md` + on-disk
state use the nested `delivery-NNN/tasks/task-NNN/` shape; and `canonical/EMISSION-MANIFEST.md`
enumerates only 3 profiles (claude-code/codex/cursor) while the generator emits 5
(+copilot-cli, +antigravity). All three are stale SOURCE docs; the KB documents the live reality.

**Location:** `docs/repository-structure.md` (skills/recipes counts + `canonical/recipes/`
path lines); `docs/aid-methodology.md` (flat task layout); `canonical/EMISSION-MANIFEST.md`
(3-profile enumeration).

**Risk if unaddressed:** A newcomer trusts the wrong path/count.

**Remediation:** Reconcile via `/aid-housekeep` (the established precedent for count drift),
not inline edits. Effort: S.

---

### [LOW] L1 -- Unreachable protect-on-diff branch in install.sh

**Type:** Dead code

**Description:** `install.sh` carries an `OVERALL_BLOCKED` / `exit 5` / `*.aid-new`
merge-warning branch that fires when `install_tool` returns `5` (a root-agent file was not
overwritten because it differed). That return value no longer occurs: `aid-install-core`
eliminated the `.aid-new` path and now updates root agent files in place via an
`AID:BEGIN/END` boundary, always setting `_CORE_ROOT_AGENT_STATUS="owned"` (CONFIRMED by the
comment in `lib/aid-install-core.sh` stating the `.aid-new` / pending-merge path was
removed). So the branch is unreachable.

**Location:** `install.sh` (`OVERALL_BLOCKED=0` … `exit 5` block); enabled-by-absence in
`lib/aid-install-core.sh`.

**Risk if unaddressed:** Misleading maintenance surface — a reader assumes a `.aid-new`
merge flow exists that does not. No runtime effect (never executes).

**Remediation:** Remove the dead branch. Effort: S. Low risk to fix (it never runs).

---

### [LOW] L2 -- release.sh --sign is deferred

**Type:** Deferred feature

**Description:** `release.sh --sign` (detached signature over `SHA256SUMS`) exits non-zero
with "not yet implemented (deferred to feature-005)". Releases are checksum-verified but not
cryptographically signed.

**Location:** `release.sh` (`--sign` guard) + Step 7 placeholder.

**Risk if unaddressed:** No signature-based provenance for the GitHub Release tarballs
(npm/PyPI do emit OIDC provenance/attestations — see Security Observations).

**Remediation:** Implement the signing approach, then drop the guard. Effort: M.

---

### [LOW] L3 -- Legacy flag-style install path retained

**Type:** Deprecation debt

**Description:** `install.sh` still carries the pre-CLI-evolution flag-style direct-install
path (`--tool`, `--update`, `--uninstall`), documented as "retained for one release".

**Location:** `install.sh` usage header ("Usage (legacy - back-compat, hidden ...)").

**Risk if unaddressed:** Two code paths to maintain; the legacy path widens the test surface.

**Remediation:** Remove after the deprecation window closes. Effort: S.

---

### [LOW] L4 -- No coverage measurement or enforcement

**Type:** Test gap

**Description:** No coverage tool (`nyc`, `coverage.py`, `--cov`) runs in any workflow, and
there is no `%` threshold. Coverage is assessed by suite-presence per subsystem (see
`test-landscape.md`).

**Location:** whole pipeline (absence in all four workflows).

**Risk if unaddressed:** A subsystem could lose effective coverage without a metric flagging
it. Acceptable for a shell/markdown toolkit, but undocumented as a deliberate choice until
now.

**Remediation:** Either adopt a lightweight coverage signal or formally record the
no-coverage decision. Effort: M.

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
| `install.sh` (~1380) | Bootstrap + legacy paths + provisioning | Carries L1/L3 debt |
| `.claude/skills/.../render.py` (~1019) | The profile renderer | Has self-tests |

---

## Missing Test Coverage

| Module / Function | Coverage | Type missing | Risk |
|------------------|----------|--------------|------|
| Prompt-driven skill state machines | none (by design) | integration | Accepted — needs AI host + human; covered by dogfooding + review |
| Astro site components | partial | unit | Build is the main gate; component logic lightly tested |
| Windows installer path | strong but Windows-CI-only | — | A green local `run-all.sh` does not exercise it (M2/gotcha) |

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
re-vendoring is the correct workflow.

---

## Dead Code

| Item | Location | Evidence of disuse | Safe to remove? |
|------|----------|--------------------|-----------------|
| `OVERALL_BLOCKED` / `exit 5` / `.aid-new` branch | `install.sh` | `install_tool` never returns 5 since `aid-install-core` removed the `.aid-new` path (`lib/aid-install-core.sh` comment) | Yes (verify install/update tests still pass) |

---

## Security Observations

Security findings are recorded here as debt items (there is no separate security doc).
Overall posture is solid for a CLI installer; the main inherent risk is the bootstrap trust
model.

| Observation | Severity | Detail |
|---|---|---|
| `curl\|bash` / `irm\|iex` bootstrap | Medium (inherent) | Users pipe a remote script to a shell. Mitigated: the bootstrap fetches the CLI bundle + libs from a **pinned release tag** and verifies them against `SHA256SUMS` before sourcing (CONFIRMED in `release.sh` Step 6 comment + `install.sh` lib-fetch). The trust root is the GitHub Release. |
| No release-asset signature | Low | `release.sh --sign` is deferred (L2); GitHub tarballs are checksum-verified but unsigned. |
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
- **Five install manifests in lockstep:** any change to the dashboard file set must touch
  `install.sh`, `install.ps1`, `vendor.js`, `vendor.py`, and `release.sh`'s CLI bundle
  together (H1) or one channel silently provisions the wrong files.
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
