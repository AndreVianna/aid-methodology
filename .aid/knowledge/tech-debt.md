---
kb-category: primary
source: hand-authored
objective: Severity-classified open technical and methodology debt in AID — dead code, lockstep-config hazards, blocked release channels, stale docs, large files, and security observations — each with location, risk, and resolution note.
summary: Read this before starting work in any area; declared debt items and the non-obvious gotchas (lockstep manifests, master-only gates, render-drift ordering, HOME-pinning) may change your approach or scope.
sources:
  - install.sh
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

| ID | Type | Description | Location | Risk | Effort | Priority |
|----|------|-------------|----------|------|--------|----------|
| **H1** | Architecture / lockstep | Five install manifests must stay byte-lockstep on the dashboard file set; a silent omission breaks provisioning on one channel | install.sh, install.ps1, vendor.js, vendor.py, release.sh | High | M | P1 |
| **M1** | Shipping gap | ~~npm + PyPI publish channels BLOCKED on external account setup; effectively GitHub-only~~ DEFERRED — workflow is OIDC-ready; npm-publish gated vars.NPM_ENABLED (release.yml L217), pypi-publish gated vars.PYPI_ENABLED (L284); closure requires owner to create npm @aid scope + PyPI org/Trusted-Publisher and flip repo variables | .github/workflows/release.yml | Medium | M (external) | P2 |
| **M3** | Stale documentation | `canonical/EMISSION-MANIFEST.md` enumerates only 3 profiles (claude-code/codex/cursor) while the generator emits 5 (+copilot-cli, +antigravity); more broadly, hand-written skill/count figures drift across ~10 doc surfaces and no CI check catches it | canonical/EMISSION-MANIFEST.md; (general: docs/*, KB count surfaces) | Medium | S | P2 |
| **M4** | Test gap / gate coverage | Visual-fidelity gate validates one wide viewport only; a visual can pass yet clip at the narrower dashboard column | canonical/aid/scripts/summarize/validate-visuals.mjs | Medium | S | P2 |
| **L2** | Deferred feature | `release.sh --sign` exits non-zero (signing not implemented) | release.sh | Low | M | P3 |
| **L3** | Deprecation debt | Legacy flag-style install path "retained for one release" | install.sh | Low | S | P3 |
| **L4** | Test gap | No line-coverage metric or `%` enforcement anywhere | (whole pipeline) | Low | M | P3 |
| **L5** | Cosmetic / hygiene | feature-015 residues: web-app §1 retired metric-grid text; non-ASCII em-dash in a summarize script comment | canonical/aid/templates/knowledge-summary/section-templates/web-app.md, canonical/aid/scripts/summarize/writeback-state.sh | Low | S | P3 |
| **L6** | Tooling inconsistency | DBI orphan-scan flags gitignored `node_modules/` that `render.py` already excludes from emission | tests/canonical/test-dogfood-byte-identity.sh | Low | S | P3 |
| **L8** | Correctness footgun | `writeback-state.sh` validates `--task-id`/`--delivery-id` as zero-paddable but feeds the raw value to `printf '%03d'` without base-10 normalization, so a leading-zero id (`08`, `09`, `010`) is misparsed as octal — hard error or silent wrong-file resolution | canonical/aid/scripts/execute/writeback-state.sh | Low | S | P3 |
| **L9** | Stale gate guidance | The `generate-profile` maintainer skill's VALIDATE state hard-codes "The 14 expected skills" (a literal enumeration) + a "14 skills" completeness assertion, stale since the skill count grew to 82 | .claude/skills/generate-profile/SKILL.md | Low | S | P3 |

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

**Status: DEFERRED (2026-06-27)** — The workflow is already OIDC-ready; no code change is
needed. The `npm-publish` job is gated `if: vars.NPM_ENABLED == 'true'` (release.yml L217) and
`pypi-publish` is gated `if: vars.PYPI_ENABLED == 'true'` (release.yml L284). Closure requires
external account setup that only the owner can perform; an agent cannot create npm scopes, PyPI
orgs, or Trusted Publishers. Deferred to the next public release cycle when the owner is ready
to provision those accounts and flip the repo variables. Per AC-9, this explicit
deferral-with-rationale satisfies the criterion.

**Owner steps to close:**
1. **npm:** Create and own the `@aid` npm scope (or confirm OIDC Trusted Publishing for
   `aid-installer`); set repo variable `NPM_ENABLED=true`.
2. **PyPI:** Create the CasuloAI Labs PyPI org, reserve the `aid-installer` name, and configure
   a Trusted Publisher pointing at this repo + `release.yml` workflow; set `PYPI_ENABLED=true`.
   No `PYPI_TOKEN` secret is needed -- auth is via OIDC id-token.
3. Verify by cutting a release tag and confirming both `npm-publish` and `pypi-publish` jobs run
   (not skipped by the `vars.*` gate) and succeed; then confirm via
   `npm view aid-installer@<v> version` and `pip index versions aid-installer`.

---

### [MEDIUM] M3 -- Stale profile enumeration + uncaught prose-count drift

**Type:** Stale documentation (methodology debt)

**Description:** `canonical/EMISSION-MANIFEST.md § "One manifest per profile"` enumerates only
3 profiles (`claude-code`, `codex`, `cursor`) while the generator emits **5** — also
`copilot-cli` and `antigravity`, both present under `profiles/`. More broadly, hand-written
skill/agent/profile **counts** drift across roughly ten doc surfaces whenever the canonical
inventory changes (work-001 alone grew skills from 14 to 82), and no CI check asserts prose
counts against the canonical tree, so drift is caught only by manual review or `/aid-housekeep`.
The earlier `docs/repository-structure.md` (skill/recipe counts + path) and
`docs/aid-methodology.md` (flat task layout) instances of this drift were reconciled in the
work-001 documentation refresh; recipes themselves were deleted, so no recipe count remains to
track.

**Location:** `canonical/EMISSION-MANIFEST.md` (3-profile enumeration table); general risk
across `docs/*` and KB count surfaces.

**Risk if unaddressed:** A newcomer trusts a stale count or an incomplete profile list.

**Remediation:** Update the EMISSION-MANIFEST profile table to the 5 emitted profiles;
reconcile prose counts via `/aid-housekeep` (the established precedent for count drift), not
inline edits. Effort: S.

---

### [MEDIUM] M4 -- Visual-fidelity gate validates a single wide viewport

**Type:** Test gap / gate coverage

**Description:** `validate-visuals.mjs` (the §7 visual-fidelity gate) renders each authored
visual at a single ~1152px-wide viewport. A visual can pass there yet clip at the dashboard's
narrower ~732px column (found in feature-015 Phase-3: a lifecycle-timeline pill was cut by
~24px at 732px and had to be hand-corrected). The gate does not check narrower representative
widths.

**Location:** `canonical/aid/scripts/summarize/validate-visuals.mjs`;
`tests/canonical/test-visual-fidelity.sh`.

**Risk if unaddressed:** A generated `kb.html` can ship a horizontally-clipped visual that the
gate passes, surfacing only in the narrower dashboard / mobile layouts.

**Remediation:** Add a "no horizontal overflow-clip at target widths" check (proposed T4) that
validates each visual at representative widths (e.g. the dashboard column ~720-760px and a
mobile ~390px), not just one wide viewport. Effort: S-M.

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

### [LOW] L5 -- feature-015 cosmetic / hygiene follow-ups

**Type:** Cosmetic / hygiene

**Description:** Two non-blocking residues from the feature-015 build: (a)
`section-templates/web-app.md` §1 retains the old metric-grid body text as a "kept rendering
reference" (the header flags it retired and the authoritative generation path enforces the
newcomer lead); (b) a non-ASCII em-dash in the `writeback-state.sh` line-2 comment. The
operative `test-ascii-only.sh` excludes agent-side summarize scripts (CI green), but
shipped-script ASCII hygiene is the standing rule.

**Location:** `canonical/aid/templates/knowledge-summary/section-templates/web-app.md` §1;
`canonical/aid/scripts/summarize/writeback-state.sh` (header comment block).

**Risk if unaddressed:** None functional -- cosmetic doc-consistency + an ASCII-hygiene exception.

**Remediation:** Trim the retired web-app §1 text; replace the em-dash with ASCII `--` (then
re-render profiles). Effort: S.

---

### [LOW] L6 -- DBI orphan-scan flags gitignored node_modules

**Type:** Tooling inconsistency

**Description:** `test-dogfood-byte-identity.sh`'s orphan-scan flags any on-disk `node_modules/`
under `.claude/`/`profiles/` as a DBI-ORPHAN, even though `render.py` correctly EXCLUDES
`node_modules` from emission (D-012). The two disagree. The visual-fidelity gate's on-demand
`npm ci` (in `canonical/aid/scripts/summarize`) creates such a directory; in a shared checkout
this can trip the scan. CI is unaffected -- the gate and the DBI suite run in separate job
checkouts. Build workaround: `rm -rf` the node_modules before DBI.

**Location:** `tests/canonical/test-dogfood-byte-identity.sh` (orphan-scan); `render.py`
(exclusion).

**Risk if unaddressed:** Spurious DBI failures during local builds that interleave the visual gate.

**Remediation:** Make the DBI orphan-scan skip gitignored paths (`node_modules/`, `.git/`),
matching `render.py`'s exclusion. Effort: S.

---

### [LOW] L8 -- writeback-state.sh octal-leading-zero task/delivery id footgun

**Type:** Correctness footgun

**Description:** `writeback-state.sh` accepts `--task-id`/`--delivery-id` values matching
`^[0-9]+$` and its own validation comment says it allows the zero-padded form ("allow
zero-padded like 019"). But the value is passed **directly** to `printf '%03d'` in
`resolve_task_state_file` / `resolve_delivery_state_file` with no base-10 normalization. Bash
`printf` treats a leading-zero integer as octal, so `--task-id 08`/`09` errors ("invalid
number") and `--task-id 010` silently resolves to `task-008`. The delivery resolver that
parses a task `DETAIL.md` `Source` line DOES normalize (`DELIVERY_ID_RESOLVED=$(( 10#$raw_num ))`),
showing the octal trap was handled in one path but not the CLI-arg path. The on-disk
directories are named `task-NNN`/`delivery-NNN` (zero-padded), so the padded form is the
natural value a caller substitutes for the documented `--task-id NNN` placeholder — which is
exactly what triggers the bug.

**Location:** `canonical/aid/scripts/execute/writeback-state.sh` (`resolve_task_state_file` /
`resolve_delivery_state_file` `printf '%03d'` sinks; the CLI-arg parse path, which lacks the
`10#` normalization the `Source`-line resolver has).

**Risk if unaddressed:** A caller passing a zero-padded id either hard-fails or, worse,
silently writes state to the wrong task's `STATE.md`. Latent today (pipeline callers derive
the id and the delivery `Source`-line path self-normalizes), hence Low — re-rate up if any
caller begins passing padded ids.

**Remediation:** Normalize both CLI args with `$(( 10#$id ))` before `printf '%03d'`, matching
the `Source`-line resolver. Effort: S.

---

### [LOW] L9 -- generate-profile VALIDATE hard-codes a stale 14-skill list

**Type:** Stale gate guidance (methodology debt)

**Description:** `.claude/skills/generate-profile/SKILL.md § Mode: VALIDATE` step 1 hard-codes
"The 14 expected skills are:" followed by a literal list of the 14 classic skills, and the
success-criteria checklist asserts "`canonical/` completeness verified: 14 skills, 9 agents".
Work-001 grew `canonical/skills/` from 14 to 82 (14 classic + `aid-triage` + 67 shortcuts); the
v2.1.0 skill-count follow-on grew it further to the current **92** (14 classic + `aid-triage` +
`aid-ask` + 76 shortcuts), so both the enumeration and the "14 skills" figure are stale. Because
VALIDATE only checks that each of the listed 14 exists (all still do, as a subset), the generator
still renders correctly — the check does not hard-fail — but its "completeness" claim is
misleading and it does not validate the 78 newer skill directories. The `9 agents` figure is
still correct.

**Location:** `.claude/skills/generate-profile/SKILL.md` (`Mode: VALIDATE` step 1 enumeration;
success-criteria "14 skills" line). This maintainer skill lives only under `.claude/skills/`
(it is not rendered from `canonical/`).

**Risk if unaddressed:** A maintainer following VALIDATE literally may treat the 78 unlisted
skills as unexpected, or trust a false "completeness" signal.

**Remediation:** Replace the hard-coded enumeration with a count/inventory derived from
`canonical/skills/` (or from `shortcut-catalog.yml` + the classic list) so it self-updates.
Effort: S.

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
| `install.sh` (~1380) | Bootstrap + legacy paths + provisioning | Carries L3 debt (legacy flag path) |
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
re-vendoring is the correct workflow.

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
- **Zero-padded ids to `writeback-state.sh`:** pass `--task-id`/`--delivery-id` as a plain
  integer (`8`, not `08`); a leading-zero value is misparsed as octal by `printf '%03d'`
  (L8) — `08`/`09` error and `010` silently resolves to `008`.
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
