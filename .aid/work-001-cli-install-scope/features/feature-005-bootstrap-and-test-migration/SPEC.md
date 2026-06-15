# v1.0/v1.1 Bootstrap and Canonical Test-Suite Migration

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-15 | Feature identified from REQUIREMENTS.md §5 (FR9), §4, §9 (AC9), §10 (Priority 3) | /aid-interview |
| 2026-06-15 | Technical Specification authored | /aid-specify |
| 2026-06-15 | Spec fixes (review cycle 1): corrected test-file citations (ASCII vs byte-parity, template site, line refs) | /aid-specify |

## Source

- REQUIREMENTS.md §5 (FR9 Bootstrap — v1.0/v1.1 → new model)
- REQUIREMENTS.md §4 Scope (in-scope: v1.0→v1.1 bootstrap, manual/per-repo/no-scan, and migration of existing tests to the new home split)
- REQUIREMENTS.md §9 (AC9), §6 (Test-suite compatibility NFR)
- REQUIREMENTS.md §10 Priority 3 (rollout)
- Design note §5 decision (E) (manual, per-repo, no-scan bootstrap), §6 (bootstrap + test-suite migration risk notes)

## Description

This is the rollout layer that brings existing repos and the test suite onto the
new model. **Bootstrap** is the migration path for repos created under v1.0/v1.1
(which carry no `format_version`): with no machine-wide scan, visiting or
`aid update`-ing each known repo stamps `format_version: 1` into its
`.aid/settings.yml` and registers it in the appropriate registry (user or shared
per scope); the lazy per-repo stamp carries forward thereafter. This covers both
the maintainer's own dogfood machine (the `~/projects/*` and `/srv/projects/*`
repos that originally exposed the bug) and external upgraders, without ever
walking the filesystem.

**Test-suite migration** updates the canonical suite (`tests/canonical/*`,
`tests/run-all.sh`) to the new CODE/STATE home split. Many suites pin `AID_HOME`
to a throwaway directory expecting it to also relocate `lib/`/`VERSION`; after the
split those references must point at `AID_CODE_HOME`, and any `$AID_HOME/.migrated`
references (now removed) must be retired. HOME-pinning semantics (state
redirection) are preserved, and migration/scan-touching tests must pin `HOME` to a
throwaway dir for real-repo safety.

## User Stories

- As an **upgrader from v1.0/v1.1**, I want visiting or `aid update`-ing a repo to
  stamp it `format_version: 1` and register it (no machine-wide scan), so my
  existing repos move onto the new model cleanly.
- As the **AID maintainer dogfooding this machine**, I want to bootstrap the
  `~/projects/*` and `/srv/projects/*` repos per-repo without a scan, so the
  original dogfood failure is resolved on the real machine.
- As an **AID maintainer**, I want the canonical test suite updated for the
  CODE/STATE home split (and the removed marker) so CI stays green and HOME-pinning
  semantics are preserved.

## Priority

Should (Priority 3 — rollout)

## Acceptance Criteria

- [ ] Given a v1.0/v1.1 repo with no `format_version`, when it is visited or
  `aid update`-ed, then `format_version: 1` is written into its `.aid/settings.yml`
  and the repo is added to the appropriate registry (user or shared per scope),
  with no machine-wide filesystem scan performed (AC9).
- [ ] Given the bootstrap path, when applied to known repos (`~/projects/*`,
  `/srv/projects/*`), then each is stamped and registered per-repo and the lazy
  per-repo stamp carries forward on subsequent visits (FR9).
- [ ] Given the canonical test suite, when run HOME-pinned via `tests/run-all.sh`,
  then it passes against the new CODE/STATE home split; `AID_HOME` redirects state
  only and `lib/`/`VERSION` references resolve via `AID_CODE_HOME` (AC4, AC8;
  NFR test-suite compatibility).
- [ ] Given `tests/canonical/*`, when audited, then `$AID_HOME/lib`,
  `$AID_HOME/VERSION`, and `$AID_HOME/.migrated` references are migrated to the
  new model (or removed for the retired marker) (FR9; design note §6).
- [ ] Given any migration/scan-touching test, when it runs, then it pins `HOME` to
  a throwaway directory so it cannot touch the developer's real repos (constraints §7).

> **Cross-cutting NFRs (apply to all ACs):** bash/ps1 parity (bootstrap behaves
> equivalently on Windows), ASCII-only shipped scripts (CI-enforced), no data loss
> (no scan, fail-safe stamping), backward compatibility (an in-flight upgrade must
> not strand a user).
>
> **Dependencies (lands last):** feature-001 (home split — tests assert against
> it), feature-003 (the stamp written during bootstrap), feature-004 (registration
> target — user vs shared registry). Bootstrap is the integration/rollout step
> over all prior features.

---

## Technical Specification

This feature has **two coupled deliverables**: (1) the **bootstrap** procedure that
moves v1.0/v1.1 repos onto the new model with no machine scan, and (2) the
**canonical test-suite migration** that re-aligns `tests/canonical/*` and
`tests/run-all.sh` with the feature-001 CODE/STATE home split and the removed
marker/scan. It carries **no new production code of its own** — bootstrap is a
*procedure* composed from feature-003 (stamp) and feature-004 (register); the
production behavior it exercises ships in features 001/003/004. This spec defines
the bootstrap recipe, the test audit/migration plan, the new fixtures, and the
acceptance bar.

### Approach — Bootstrap (manual, per-repo, no scan)

Per design note §3.1, §3.4, §5.10 (Decision E) and §6, there is **no machine-wide
filesystem scan, ever**. A v1.0/v1.1 repo has no `format_version` in its
`.aid/settings.yml`; under feature-003's stamp comparison an absent stamp =
legacy (`< AID_SUPPORTED_FORMAT`) → "needs migration". Bootstrap is simply the
act of **encountering each known repo once**:

1. **On encounter** (`cd <repo>` + any repo-command — bare `aid`, `aid status`,
   `aid update`), feature-003's stamp comparison fires: an absent/old stamp →
   warn + offer `aid update` (design note §3.4; dispatch matrix §4.C rows 1-2,4).
2. **`aid update`** (the current-repo migration, `__migrate-repo`) runs, and on
   success **feature-003 writes `format_version: <AID_SUPPORTED_FORMAT>`** into
   that repo's `.aid/settings.yml` (the only migration-done record — design note
   §3.4; the stamp is emitted by feature-003 at the settings.yml template sites:
   the era-b synthesizer `_aid_migrate_synthesize_settings_era_b`
   (bin/aid:1629-1670) and the era-a repair `_aid_migrate_repair_settings_era_a`
   (called at bin/aid:1318)).
3. **In the same encounter, feature-004 registers the repo** in the appropriate
   tier: user registry `~/.aid/registry.yml` always; shared
   `$AID_STATE_HOME/registry.yml` only for a global install when the user opts
   shared (design note §3.3, §4.C row 5). Registration is best-effort (skip+warn
   if elevation declined/no-TTY — decision #2).
4. **Carry-forward:** subsequent visits read the stamp, find it current, and do
   nothing (no re-prompt). The root-owned-marker re-prompt loop cannot recur
   because there is no machine marker (design note §3.4).

**Concrete dogfood-machine recipe (the original-bug machine):** the maintainer
visits each known repo **one by one** — `~/projects/*` and the
`group developers` repos under `/srv/projects/*` that the old `$HOME`-only scan
never saw (design note §1, §6). For each:

```
cd <repo> && aid update      # stamp(003) + register(004); confirm if prompted
```

No globbing into a scan loop is mandated or implied; the maintainer chooses the
order. `update self` additionally batch-migrates **already-registered** repos
with per-repo confirmation (design note §3.5, §5.1) — but the first-pass
bootstrap is the manual per-repo visit above. External upgraders follow the
identical procedure on their own repos.

### Approach — Canonical test-suite migration

**Root cause of the breakage.** Today `bin/aid:44` resolves
`AID_HOME="${AID_HOME:-$(dirname dirname realpath)}"` — the **env var wins over
self-locate**, so a test that points `AID_HOME` at a throwaway dir containing
`bin/aid` + `lib/aid-install-core.sh` + `VERSION` relocates **both code and
state** at once. The `new_aid_home()` fixture in
`tests/canonical/test-aid-migrate.sh:56-67` builds exactly such a conflated dir.
After feature-001, **`AID_HOME` overrides STATE only**; code resolves via the
self-located `AID_CODE_HOME` and is **never** relocated by env. Any test that
relied on `$AID_HOME/lib`, `$AID_HOME/VERSION`, or the conflated fixture must be
updated, and every reference to the removed `.migrated` marker / scan / sentinel
must be retired.

**Audit categories** (each `tests/canonical/*` reference is classified into one):

| # | Category | Pattern to find | Migration action |
|---|----------|-----------------|------------------|
| C1 | **Code-home conflation** | `$AID_HOME/lib/...`, `$AID_HOME/VERSION`, `AID_LIB_PATH="${...}/lib/..."`, the `new_aid_home()`-style "one dir holds bin+lib+VERSION+state" fixture | Split the fixture into a **CODE_HOME** (bin/aid + lib + VERSION, the dir `bin/aid` self-locates from) and a **STATE_HOME** (`AID_HOME=` throwaway, holds only registry/state). Code refs resolve via self-locate / `AID_CODE_HOME`, never via `AID_HOME`. `AID_LIB_PATH` stays an explicit lib override but must point at CODE_HOME's lib. |
| C2 | **Removed marker** | `.migrated` file existence/content (`$AID_HOME/.migrated`, marker == VERSION) | Delete the assertion. The migration-done record is now the per-repo `format_version` stamp in `.aid/settings.yml`; replace marker assertions with stamp assertions where the test's intent was "migration happened". |
| C3 | **Removed scan/sentinel** | `_aid_scan_for_repos`, `_aid_check_migrate_sentinel`, `_aid_write_migrated_marker`, "VERSION advanced → scan fires", SEC-6 no-loop | Delete or rewrite. The sentinel/scan trigger model is gone (FR8); migration is lazy per-repo (stamp) + batch over registered repos in `update self`. Replace "scan fires + marker written" assertions with "stamp written + repo registered on encounter". |
| C4 | **Registry tier paths** | `$AID_HOME/registry.yml` | Re-anchor on `AID_STATE_HOME`. `AID_STATE_HOME = ${AID_HOME:-<scope default>}`, so when a test pins `AID_HOME` to a throwaway dir, `AID_STATE_HOME` is that throwaway (the scope-default `~/.aid` only applies when `AID_HOME` is unset). For a **non-global** install the design-§3.3 collapse is `$AID_HOME == ~/.aid` (shared==user, one file), so under an explicit `AID_HOME` pin `$AID_HOME/registry.yml` remains the correct single-tier target — confirm the test's install is non-global (the default for a user-writable throwaway). Add a shared-tier case only where a global install is simulated. |
| C5 | **HOME-pinning canary** | `export HOME=<throwaway>`, escape canary | **Keep and strengthen.** Migration/scan-touching tests already pin `HOME` (test-aid-migrate-trigger.sh:113, test-aid-cli-parity.sh:83, test-release-migrate-smoke.sh:43); the canary that asserts the real `REPO_ROOT/.aid/registry.yml` was untouched (test-aid-migrate-trigger.sh:224-228) is retained as the real-repo-safety guard. |

**New / changed fixtures:**

- **`new_code_home()`** (replacing the conflated `new_aid_home()` in
  test-aid-migrate.sh:56): builds the **read-only payload** — `bin/aid`, `lib/`,
  `VERSION`, stub `dashboard/home.html` — the dir `bin/aid` self-locates as
  `AID_CODE_HOME`. **Not** pointed at by `AID_HOME`.
- **`new_state_home()`**: a separate throwaway dir for mutable state, exported as
  `AID_HOME=` (→ `AID_STATE_HOME`). Holds `registry.yml` / `.update-check`. For
  non-global tests this is also the (collapsed) registry home.
- **Throwaway `HOME`** (existing pattern, extended to every migration/encounter
  test): `export HOME="${TMP}/fakehome"` so any home-relative resolution
  (`~/.aid` user registry, `~/.aid/.update-check`) lands in the sandbox, plus the
  **escape canary** asserting no real repo under the developer's true `$HOME` was
  touched.

### Affected components

| File | Audit cat. | Why it changes |
|------|-----------|----------------|
| `tests/canonical/test-aid-migrate.sh` | C1, C2, C4 | `new_aid_home()` (l.56-67) conflates bin+lib+VERSION+state under one `AID_HOME`; `run_migrate()` (l.72-79) passes `AID_HOME=` for both code and state; Gate 9e (l.866-875) asserts `$AID_HOME/registry.yml`; G8 (l.760-768) asserts on `$AID_HOME/registry.yml`. Split fixture into CODE_HOME + STATE_HOME; re-anchor registry on STATE_HOME (collapsed == AID_HOME for non-global). |
| `tests/canonical/test-aid-migrate-trigger.sh` | C2, C3, C5 | Entire suite is the **sentinel/scan trigger** model being removed (TRG-A..F; `.migrated` marker l.186,199,255,284; `_aid_scan_for_repos` l.38). Rewrite to the lazy-stamp model: "on encounter, absent stamp → stamp written + registered"; **retain** the HOME pin (l.113) + canary (l.224-228). Likely the largest single rewrite. |
| `tests/canonical/test-aid-cli.sh` | C1 | Pervasive `AID_HOME="$h" AID_LIB_PATH="$h/lib/..."` invocation pattern (l.96,210,235,250,256,651,781,929,952,957,967,972,983,1105) treats one dir as code+state. Split so `AID_LIB_PATH`/code → CODE_HOME, `AID_HOME` → STATE_HOME. Status "ref == AID_HOME/VERSION" comment (l.636) re-anchors on CODE_HOME/VERSION. |
| `tests/canonical/test-aid-cli-parity.sh` | C1, C2, C3, C4, C5 | Conflated invocation (l.178,185,1129,1147); `.migrated` marker + scan/sentinel refs (l.1858,1869,1889,1902,2000,2021-2025,2054-2185; scan-root comment at l.63); registry-tier asserts (l.968-1096). Both bash and ps1 sides must be migrated **in lockstep** (parity). Retain HOME pin (l.83). |
| `tests/canonical/test-aid-cli-ps1.sh` | C1 | PS1 mirror of the conflated code-home pattern; migrate in lockstep with the bash suite. |
| `tests/canonical/test-registry.sh` | C4 | `$AID_HOME/registry.yml` and `AID_LIB_PATH` (l.87, l.167, l.186-412). Confirm non-global collapse (STATE_HOME==AID_HOME==~/.aid); split code lib ref to CODE_HOME. Registry semantics (DM-1 header, schema:1, two-space indent) unchanged. |
| `tests/canonical/test-release-migrate-smoke.sh` | C3, C5 | "first `aid` run fires the version sentinel (lazy)" (l.9-10) describes the removed trigger; rewrite the per-channel smoke to "first encounter stamps + registers". Retain HOME pin (l.43). |
| `tests/canonical/test-npm-installer.sh` | C1 | `$AID_HOME/lib`, `$AID_HOME/VERSION` refs — these are **fixture setup** (`mkdir`/`cp` building the payload dir, l.350-354), not assertions. After the split this payload dir is the **installed payload root** (= CODE_HOME for that channel), which for an npm install is the package dir, not a state dir; re-anchor the fixture/refs on the code-home payload, add a `~/.aid` (or `/var/lib/aid`) state-home check if the test exercises state. (Genuine post-install `assert_file_exists` on lib/VERSION live in test-release-install-e2e.sh:484-486.) |
| `tests/canonical/test-pypi-installer.sh` | C1 | Same as npm: `$AID_HOME/lib`/`VERSION` are fixture setup (`mkdir`/`cp`, l.295-299) building the payload-root code dir, not assertions — re-anchor on the code-home payload vs state home. |
| `tests/canonical/test-release-install-e2e.sh` | C1 | `$AID_HOME/lib`, `$AID_HOME/VERSION` end-to-end install asserts (`assert_file_exists`, l.484-486) → re-anchor on the code-home payload; add state-home check if exercised. |
| `tests/run-all.sh` | — (harness) | No structural change, but **must stay green HOME-pinned**: it already runs each suite in an isolated bash process (l.46-52). The acceptance gate is that the full sweep passes after the migrations above. The repo-access/real-machine-safety memory (HOME-pin) is enforced per-suite, not here. |

New helper fixtures (`new_code_home()`, `new_state_home()`) live in the suites
that need them (or a shared `tests/canonical/lib/` helper if one exists at
implementation time — Glob to confirm before introducing).

### Behavior / Flow

**Bootstrap sequence on an upgraded machine:**

1. Maintainer upgrades the CLI (`aid update self` / installer) — features 001/003/004 now in effect; `AID_CODE_HOME` self-locates the new payload, `AID_STATE_HOME=${AID_HOME:-~/.aid}`.
2. `update self` batch-migrates **already-registered** repos with per-repo confirm (design note §3.5). On a fresh-upgrade machine the registry may be empty → nothing batch-migrates yet.
3. Maintainer visits each known repo manually: `cd <repo> && aid update`.
   - **First touch:** stamp absent → feature-003 warns + (`aid update`) stamps `format_version:1`; feature-004 registers (user tier always; shared if global+opt-in).
   - **Subsequent touch:** stamp current → silent no-op (carry-forward).
4. The union of user + shared registries (design note §3.3) now lists the bootstrapped repos for the dashboard.

**First-touch stamping (single repo):** `cd repo` → repo-command → feature-003 reads `.aid/settings.yml`, finds no `format_version` → "needs migration" warn+offer → `aid update` → `__migrate-repo` runs, writes `format_version:1` → feature-004 registers. AC9 satisfied (stamp + register, **no scan**).

### Edge cases & fail-safes

- **Repo visited before its dependencies migrated:** N/A at runtime — features 001/003/004 land *before* this rollout feature (stated dependency: "lands last"). The bootstrap procedure assumes the new CLI is already installed; if not, the old CLI simply does nothing new (no marker re-prompt to break).
- **Repo with no git:** AID operates anyway (design note §3.1, §4.C last row, decision #5); stamping `.aid/settings.yml` succeeds; a note that `.aid/` won't be version-controlled. Not a bootstrap blocker.
- **Repo with no `.aid/`:** not an error — offer `aid add` (design note §4.C last row). Bootstrap touches only existing AID repos.
- **Mid-bootstrap interruption:** some repos stamped, some not. Each repo's done-state is its own `format_version` stamp; an un-stamped repo is simply caught on its next encounter (lazy catch-all, design note §3.4). No global state to corrupt.
- **Elevation declined during shared register (global):** skip + warn, still operate; stamp still written (best-effort registration, decision #2).
- **HOME-pinning canary (tests):** every migration/encounter test sets `export HOME=<throwaway>` and asserts a canary planted at a real path outside the throwaway is untouched (test-aid-migrate-trigger.sh:224-228 pattern). This is the hard guard that the (now-removed but historically dangerous) scan path, and any home-relative `~/.aid` write, never touches the developer's real repos. **Mandatory** per the repo-safety constraint (REQUIREMENTS §7).

### bash ↔ ps1 parity

- Bootstrap behavior (stamp + register on encounter, no scan) must be **equivalent on Windows**: `bin/aid.ps1` performs the same stamp/register; the parity suites (`test-aid-cli-parity.sh`, `test-aid-cli-ps1.sh`) must migrate the bash and PS1 fixtures **in lockstep** so the CODE/STATE split is asserted identically on both.
- **Installer parity needs a Windows runner:** `test-npm-installer.sh` / `test-pypi-installer.sh` / `test-install-ps1.sh` cover the payload-root (code-home) install on each OS; the PS1 install path is only fully validated on a Windows CI runner, not Linux (per the testing-cadence constraint). The Linux sweep validates the bash side + the OS-agnostic stamp/register logic.
- **ASCII-only:** any new/edited shipped script content stays ASCII-only — enforced by the dedicated guard `test-ascii-only.sh` (CI-guarded, `grep -P '[^\x00-\x7F]'`). Test fixtures that scaffold `registry.yml` keep their existing ASCII assertions (test-registry.sh:255-258, l.408-412). The parity suite (`test-aid-cli-parity.sh`) enforces **byte-parity** (bash↔PS1 byte-identical scaffolding/no-op output, e.g. l.269,930,1485,1707,1773) — a distinct check from ASCII-only enforcement, not an ASCII assertion; both must continue to pass after the migration.

### Testing

This feature **is** substantially a test deliverable. Acceptance:

- **Full sweep green, HOME-pinned:** `bash tests/run-all.sh` passes end-to-end after migration, with every migration/encounter suite pinning a throwaway `HOME` (and the escape canary intact). This is the top-line gate (AC: NFR test-suite compatibility).
- **No conflation remains:** a final audit grep over `tests/canonical/*` finds **zero** `$AID_HOME/lib`, `$AID_HOME/VERSION` references that assume code relocation by `AID_HOME`, and **zero** live `.migrated` / `_aid_scan_for_repos` / `_aid_check_migrate_sentinel` / `_aid_write_migrated_marker` references (categories C1-C3 fully discharged) (AC: design note §6).
- **New bootstrap assertions:** add tests proving — on first encounter of a stamp-less repo, (a) `format_version:1` is written into `.aid/settings.yml`, (b) the repo is registered in the (user-tier, collapsed) `registry.yml`, (c) **no filesystem scan** occurs (canary outside the throwaway HOME untouched). Directly verifies AC9 / FR9.
- **Carry-forward assertion:** a second encounter of an already-stamped repo neither re-prompts nor re-writes the stamp.
- **Tier coverage:** non-global collapse (user==shared==~/.aid) asserted by default; at least one simulated global install asserts the shared `/var/lib/aid` registry tier (or documents it as deferred to the global-provisioning slice if `/var/lib/aid` can't be created in CI without root).

### Backward compatibility

- **In-flight upgrade is safe:** with some repos stamped and some not, the CLI operates on every repo regardless — a stamp-less repo is migrated lazily on its next encounter; there is no global gate that a partial bootstrap leaves half-set. No user is stranded mid-rollout.
- **No data loss:** no scan, fail-safe stamping (stamp written only on successful migration), best-effort registration. A repo whose stamp is *newer* than `AID_SUPPORTED_FORMAT` is refused (git "must not operate" rule, design note §3.4) — not silently downgraded.
- **Removed marker is non-breaking:** old `$AID_HOME/.migrated` files left on disk are simply ignored (the code path that read them is deleted, FR8); they cause no error and need no cleanup.

### Open decision (recommendation)

- **Global shared-tier (`/var/lib/aid`) CI coverage.** The shared-registry tier (design note §3.3, §5.9) needs a root-owned `/var/lib/aid`, which a non-root CI job can't provision. **Recommendation:** in this feature, assert the **non-global collapse** path (the dogfood default and the common case) as the green gate, and cover the shared tier with either (a) a `AID_STATE_HOME`-overridden throwaway "pretend-global" dir (asserting the *two-tier union read* logic without real `/var/lib/aid`), or (b) defer the true root-provisioned `/var/lib/aid` assertion to the global-provisioning slice noted in design §6. Option (a) is preferred — it exercises the union/tier logic in-suite without root, keeping `run-all.sh` runnable by any contributor.
