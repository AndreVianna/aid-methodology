# Upgrade Migration (Per-Repo Compliance + Machine Scan)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-13 | Feature created from REQUIREMENTS.md §5 FR37–FR40, §6 NFR12, §7 C8 (upgrade migration) — resolves KI-010 (`home.html` provisioning) | /aid-interview |
| 2026-06-13 | Technical Specification authored: DM-1..4, FF-1..4, LC-MIG/LC-VND/LC-HSRC, CLI-1/CLI-2, SEC-1..6, §6 gates, DD-1..6, RC-1..4 | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR37 (per-repo upgrade migration — detect/qualify → settings validate/repair|synthesize → add `home.html` → relocate legacy summary → register; idempotent, in-order, skip-already-satisfied)
- REQUIREMENTS.md §5 FR38 (migration command model — `aid update self` = machine scan with All/Yes/No/Cancel; `aid update [<tool>]` = current repo only; shared FR37 logic, different reach)
- REQUIREMENTS.md §5 FR39 (migration is part of the upgrade — trigger via version sentinel + npm postinstall; non-interactive defers, NFR12)
- REQUIREMENTS.md §5 FR40 (`home.html` single vendored source — `dashboard/home.html`, both vendor manifests, copied into each repo's `.aid/dashboard/home.html`; no second committed source)
- REQUIREMENTS.md §6 NFR12 (migration safety — idempotent, additive, no-clobber, no-delete, crash-safe, WARN-not-fail, read-only detection, consent-gated mutation)
- REQUIREMENTS.md §7 C8 (lands in hand-maintained `bin/aid` + `bin/aid.ps1` twin + install/package layer; ASCII-only + Bash↔PowerShell parity + vendored-copy refresh gates, NOT render-drift; never destroys user data; annotate+offer posture)
- REQUIREMENTS.md §5 FR28/FR29 (the `$AID_HOME/registry.yml` registry + the `registry_register` idempotent writer the migration reuses — owned by feature-010)
- REQUIREMENTS.md §5 FR31 (the legacy KB-summary relocation idiom `mkdir -p .aid/dashboard && mv -n` the migration reuses)
- KI-010 (`.aid/work-001-aid-dashboard/known-issues.md` — the `home.html`-not-provisioned gap this feature closes)
- Grounding brief `.aid/work-001-aid-dashboard/design/feature-011-grounding.md` (the factual substrate: settings.yml schema §1, DISCOVERY_STATE/STATE.md era-b map §2, install/upgrade/postinstall reality §3, registry §4, FR31 relocation §5, KI-010 §6, numbering §7/§9)

## Description

The two-level re-architecture (feature-010) changed the per-repo on-disk shape: a repo's live page is
now `<repo>/.aid/dashboard/home.html`, the KB summary moved to `<repo>/.aid/dashboard/kb.html`, and a
repo must be registered in `$AID_HOME/registry.yml` to appear on the CLI home. **Repos created by older
AID versions do not comply** — they have no `home.html` (KI-010: it is neither vendored, generated, nor
scaffolded), may hold a legacy `.aid/knowledge/knowledge-summary.html`, may have a
missing/invalid/incomplete `.aid/settings.yml`, and are not in the registry — so their per-repo
dashboard cannot be served.

This feature adds an **idempotent, read-mostly per-repo upgrade migration** that brings an existing AID
repo into the current layout, plus the trigger machinery to run it as part of the CLI upgrade. It does
exactly four mutating things, each only when not already satisfied: **validate/repair or synthesize
`settings.yml`**, **add `home.html`**, **relocate the legacy KB summary**, and **register the repo**. A
fresh `aid add` already lays down most of a compliant repo once `home.html` is vendored (FR40); the
migration is for the repos that predate the new layout. It is reached two ways through the **existing
`aid update`** command (no new verb): `aid update self` updates the CLI then **scans the machine** and
migrates each discovered repo with an **All/Yes/No/Cancel** consent prompt; `aid update [<tool>]` updates
the CLI if stale then migrates **only the current repo** (no scan). The trigger is a **version-sentinel
lazy first-run** check in `bin/aid` (the universal cross-manager guarantee, since pypi wheels have no
install-time hook) plus an **npm `postinstall`** eager path.

It lands in the **hand-maintained** `bin/aid` (+ `bin/aid.ps1` twin) and the package/vendor layer — NOT
in `canonical/`→render artifacts (C8) — so its gates are **ASCII-only + Bash↔PowerShell parity +
vendor-refresh**, never render-drift. It honors the project's annotate+offer / never-destroy-user-data
posture (NFR12, MEMORY "ask-user-over-auto-proof"): detection is read-only, mutation happens only after
consent, never silently in a non-interactive context, and the only writes are additive
(`home.html` copy), no-clobber (`mv -n` of the legacy summary), and value-preserving
(`settings.yml` repair/synthesize). It resolves **KI-010**.

## User Stories

- As an **operator** who installed AID a while ago and just upgraded the CLI, I want my existing repos
  to be brought up to the new dashboard layout automatically (with my consent per repo), so the CLI home
  lists them and each one's per-repo dashboard actually loads.
- As an **operator** running a machine scan, I want a clear **All / Yes / No / Cancel** choice per repo,
  so I can migrate everything at once, pick individual repos, skip ones I don't want touched, or abort —
  and a repo I skip is left exactly as it was, with a one-liner telling me how to migrate it later.
- As an **operator** on a pre-0.7 repo with no `settings.yml`, I want the migration to synthesize a valid
  one from what's on disk (folder name + installed-tools manifest), so the dashboard's readers parse it
  cleanly without me hand-writing YAML.
- As an **operator** in CI / a no-TTY context, I want the upgrade to **never silently mutate** my repos —
  it should annotate what it found and defer, unless I explicitly opt in.
- As an **operator** who already migrated, I want re-running the migration to be a **no-op** that touches
  nothing and never deletes or overwrites my data.

## Priority

**Must** (FR37–FR40 are the closure of the two-level re-architecture for existing repos — without it,
KI-010 stands and the per-repo dashboard is unserveable for any repo not hand-committed like the dogfood
repo). It is **not a release blocker** (user decision 2026-06-13: current adoption is negligible) but
this version carries the migration.

## Owned Requirements

- **FR37** (per-repo upgrade migration — detect/qualify, settings validate/repair|synthesize, add
  `home.html`, relocate legacy summary, register; idempotent, in-order, skip-satisfied).
- **FR38** (command model — `aid update self` machine-scan with All/Yes/No/Cancel; `aid update [<tool>]`
  current-repo-only; shared logic).
- **FR39** (trigger — version sentinel + npm postinstall; non-interactive defers).
- **FR40** (`home.html` single vendored source `dashboard/home.html`; both manifests; per-repo copy).
- **NFR12** (migration safety — idempotent/additive/no-clobber/no-delete/crash-safe/WARN-not-fail/
  read-only detection/consent-gated).
- **C8** (lands in hand-maintained `bin/aid`+PS twin + package layer; ASCII + parity + vendor-refresh
  gates, NOT render-drift; never destroys user data; annotate+offer posture; single `home.html` source).
- Reuses (does not own / re-specify): **FR28/FR29** registry + `registry_register` (feature-010),
  **FR31** legacy-summary relocation idiom (feature-007/summarize), the `lib/aid-install-core.sh` manifest
  readers (the installer engine), and feature-010's CLI-home `index.html` / multi-repo server contract.
- **Resolves KI-010** (`home.html` provisioning gap).

## Acceptance Criteria

- [ ] Given an **era-a** repo (`.aid/settings.yml` present) with a **valid** settings file, a
      `home.html` already present, no legacy summary, and already registered, when the per-repo migration
      runs, then it is a **no-op** — no file is written, moved, created, or deleted, and the registry is
      unchanged (FR37 skip-already-satisfied; NFR12 idempotent).
- [ ] Given an **era-a** repo whose `.aid/settings.yml` is **malformed/incomplete** (e.g. missing a
      `project:` block or a required scalar section), when migration runs, then `settings.yml` is
      **repaired** to a shape all current readers (`read-setting.sh`, the dashboard server `_read_settings`,
      the reader `parse_project_name`) parse without falling back, **any present `kb_baseline` and
      per-skill overrides are preserved**, and the write is crash-safe (temp-file + `mv -f`)
      (FR37 validate/repair; NFR12 additive/value-preserving).
- [ ] Given a **pre-0.7 (era-b)** repo (`.aid/knowledge/{DISCOVERY_STATE.md|DISCOVERY-STATE.md|STATE.md}`
      present, **no** `settings.yml`), when migration runs, then a valid `.aid/settings.yml` is
      **synthesized** from template defaults with `project.name` = repo folder basename, `project.type` =
      `brownfield`, `project.description` = placeholder, and `tools.installed` derived from
      `.aid/.aid-manifest.json`; the file parses cleanly for all current readers (FR37 synthesize; RC-4).
- [ ] Given any qualifying repo with **no** `.aid/dashboard/home.html`, when migration runs, then the
      current vendored `home.html` (`$AID_HOME/dashboard/home.html`, the single source per FR40) is
      **copied** into `<repo>/.aid/dashboard/home.html` (additive, never overwriting an existing one); a
      repo that already has `home.html` is left untouched (FR37 add `home.html`; FR40; NFR12; resolves KI-010).
- [ ] Given a qualifying repo with a legacy `.aid/knowledge/knowledge-summary.html` and **no**
      `.aid/dashboard/kb.html`, when migration runs, then the legacy summary is moved to
      `.aid/dashboard/kb.html` via the **no-clobber** `mkdir -p .aid/dashboard && mv -n` idiom guarded by
      `[ -f OLD ] && [ ! -f NEW ]`; a repo that already has `kb.html` keeps both files untouched and never
      loses the legacy one (FR37 relocate; FR31 reuse; NFR12 no-clobber/no-delete).
- [ ] Given a qualifying repo not yet in `$AID_HOME/registry.yml`, when migration runs, then the repo's
      CAN-1-canonical base folder is **registered** via the existing idempotent atomic `registry_register`;
      a repo already registered is a registry no-op (FR37 register; FR28/FR29 reuse; NFR12 idempotent).
- [ ] Given a folder that is a **bare `.aid/`** with neither `settings.yml` nor a
      `knowledge/{DISCOVERY_STATE.md|DISCOVERY-STATE.md|STATE.md}` marker (e.g. a stray `.aid/.temp`),
      when the scan evaluates it, then it is **not a migration candidate** — read-only detection skips it
      and never mutates it (FR37 detect/qualify; NFR12 read-only detection; C8 annotate+offer).
- [ ] Given `aid update self` on a machine with several AID repos, when the scan presents each candidate,
      then the operator gets an **All / Yes / No / Cancel** prompt where **All** applies to this and all
      remaining repos without re-asking, **Yes** migrates only this repo, **No** skips it (and the repo is
      **not registered** and the CLI advises running `aid update` inside that folder later), and **Cancel**
      aborts the whole scan; a single repo's migration failure **WARNs and continues** (FR38; NFR12 WARN-not-fail).
- [ ] Given `aid update [<tool>]` (or bare `aid update`) run inside a repo, when it completes, then the CLI
      self-updates if a newer version exists (an additive preamble — the live `add|update` engine does not
      self-update today), then runs the **per-repo** FR37 migration on the resolved cwd/`--target` **only**
      (no machine scan), attached to the existing `add|update` success tail beside the current
      `registry_register` side-effect (FR38).
- [ ] Given an upgraded CLI whose installed `$AID_HOME/VERSION` has advanced past the persisted
      last-migrated marker, when `aid` is next invoked **interactively**, then the machine scan
      (FR38 `aid update self` behavior) runs **once** and the marker is updated to the installed version, so
      the upgrade is "complete" only after the affected repos are migrated; subsequent invocations at the
      same version do **not** re-trigger (FR39 version sentinel; cross-manager guarantee covering pypi,
      `--ignore-scripts`, curl).
- [ ] Given a **non-interactive** context (no TTY / CI / npm postinstall) where the sentinel or postinstall
      fires, when the scan would run, then it **does not silently mutate** any repo — it annotates the
      candidate list and **defers** (leaving the DM-3 marker stale so the next interactive run re-triggers),
      unless the explicit opt-in `AID_MIGRATE_YES=1` (or `aid update self --yes`) is set, in which case it
      migrates and advances the marker (FR39; NFR12 consent-gated; C8 annotate+offer).
- [ ] Given the `home.html` source, when the package is built/vendored, then `dashboard/home.html` is the
      **single committed source**, present in **both** vendor manifests (`packages/npm/scripts/vendor.js`,
      `packages/pypi/scripts/vendor.py`) and installed to `$AID_HOME/dashboard/home.html`; the AID repo's
      own `.aid/dashboard/home.html` is a **derived copy** with **no second source of truth**; a CI
      equality gate detects any divergence between the copy and the source (FR40; C8 single source; RC-2; DD-5).
- [ ] Given every edit lands in hand-maintained `bin/aid` / `bin/aid.ps1` + the package layer, when the
      gates run, then **ASCII-only** (`tests/canonical/test-ascii-only.sh`), **Bash↔PowerShell parity**
      (`tests/canonical/test-aid-cli-parity.sh`), and **vendor-refresh** (`vendor.js`/`vendor.py`) all pass,
      and the change is **not** subject to render-drift / `run_generator.py` (C8).
- [ ] Given a freshly-migrated repo served through the multi-repo server, when the reviewer renders that
      repo's `home.html` in **Playwright**, then the provisioned SPA shell loads, polls `/r/<id>/api/model`,
      and renders without a 404 or a blank page (resolves KI-010; R5 hard gate).

## Decomposition Rationale (one feature, not N)

> _Recorded for /aid-plan. Reviewed for over/under-splitting._

The migration logic (FR37), the two command reaches (FR38), the trigger (FR39), and the `home.html`
vendoring (FR40) were considered as separate features. They are kept as **one** because they form a
single indivisible capability with no useful standalone sub-deliverable: the per-repo migration (FR37) is
inert without a way to reach it (FR38) and a reason to run (FR39); the trigger (FR39) and both reaches
(FR38) are meaningless without the logic they invoke (FR37); and the "add `home.html`" step (FR37) cannot
function without a vendored source (FR40) — `home.html` vendoring exists **only** to feed the migration's
add-step (and the symmetric fresh-`aid add` lay-down). Splitting them would manufacture cross-feature
dependencies on a tiny surface (one new migration function set, two dispatch hook points, one sentinel
marker, two vendor-manifest entries) and several coordination seams where one suffices. They all land in
the **same domain boundary** — the hand-maintained `bin/aid`/`bin/aid.ps1` + the package/vendor layer
(C8) — distinct from feature-010's machine-tier server/registry/page (`canonical/`-rendered producers are
not touched). This keeps every FR37–FR40 requirement owned exactly once with no homeless cross-cutting
piece.

---

## Technical Specification

> Added by `/aid-specify`. Determined from REQUIREMENTS.md, the grounding brief, and the live `bin/aid`.
> **Line anchors re-pinned against the live `bin/aid` (63 KB) at spec time** (grounding §3b flagged
> drift; the brief's anchors match the live file: `_cmd_update_self`:247, update-self dispatch
> 1265–1281, `add|update` success tail 1563–1566, `remove` unregister 1587–1591, `--target` canonicalize
> 1366, manifest path 1414, `$AID_HOME` resolve 40–47, `registry_register` 1094–1127,
> `_registry_read_repos` 1082–1088, `.update-check` sentinel-pattern precedent 159/174). **/aid-detail
> MUST re-pin again at detail time** (the file is edited under it).

> Activated sections (per `canonical/templates/specs/spec-template.md`): **Data Model** (the
> `.aid/settings.yml` validate/repair-to+synthesize-target schema = DM-1; the `$AID_HOME/registry.yml`
> format reused = DM-2; the version-sentinel marker format/location = DM-3; the legacy summary OLD→NEW
> relocation map = DM-4), **Feature Flow** (the four runtime cycles: per-repo migration = FF-1; the
> `aid update self` machine-scan + All/Yes/No/Cancel state machine = FF-2; `aid update [<tool>]`
> current-repo = FF-3; the sentinel/postinstall trigger = FF-4), **Layers & Components** (the migration
> function set in `bin/aid`/PS twin = LC-MIG; the vendor/package layer = LC-VND; the `home.html` source
> move = LC-HSRC), **CLI / Command spec** (REQUIRED — the `aid update self` + `aid update [<tool>]`
> behavior, the All/Yes/No/Cancel contract + declined-repo advisory, exit codes, the opt-in flag = CLI-1/
> CLI-2), **Migration Plan** (this whole feature IS a migration; the per-repo migration ordering + era
> handling is the Migration Plan, expressed in FF-1/DM-1), **Security Specs** (REQUIRED — read-only-until-
> consent, bounded scan scope, no traversal, additive/no-clobber/crash-safe mutation, sentinel can't loop
> = SEC-1..6). **Skipped:** **State Machines** (the only state machine — the per-repo All/Yes/No/Cancel
> consent walk — lives in FF-2 where it is most legible; the per-repo migration has no persistent
> lifecycle beyond the sentinel marker which DM-3 fully describes), **API Contracts** (the migration is a
> CLI/filesystem capability with no HTTP surface — the only routes touched are feature-010's, which this
> feature does not change), **UI Specs** (the migration provisions feature-006's `home.html`; it specifies
> **no** new UI — the R5 gate validates the *provisioned* page renders, but the page is owned by
> feature-006), **Telemetry** (no telemetry generated; NFR7-class deterministic CLI code; the only
> persistent artifact is the DM-3 marker, a sentinel not a metric), **BDD Scenarios** (the acceptance
> criteria + FF-1..4 walkthroughs + the §6 fixture-repo tests already express the behavioral contract
> concretely), **Recovery Management** (no transactional/rollback surface — every write is failure-atomic
> by construction: temp-file+`mv -f` for `settings.yml` and the marker, `mv -n` no-clobber for the
> summary, `registry_register`'s own atomic write; a failed step WARNs and the next run resumes
> idempotently, NFR12), **Events & Messaging / CQRS / DDD / Cache / Batch / Mobile / Search / AI / Cloud /
> Hardware** (not applicable to a filesystem migration in a shell launcher).

The migration is **deterministic shell code with no agent/LLM** (consistent with the dashboard's NFR7
runtime posture) living entirely in the hand-maintained `bin/aid` + `bin/aid.ps1` twin and the package/
vendor layer. It **writes to a repo only after consent** (FF-2) and only in **additive/no-clobber/value-
preserving** ways (NFR12). Four resolved design decisions are recorded as **RC-1..RC-4** (settled with
the user); supporting mechanics as **DD-1..DD-6**.

---

### Data Model

No relational schema (AID ships no database). This feature defines/consumes **four** on-disk shapes:
the `settings.yml` validate/repair/synthesize target (DM-1, owned by `/aid-config`, this feature is a
**writer**), the `$AID_HOME/registry.yml` registry (DM-2, **reused** verbatim from feature-010), the
version-sentinel marker (DM-3, **new**, owned here), and the legacy-summary relocation map (DM-4).

#### DM-1. `.aid/settings.yml` — the validate/repair / synthesize target (FR37)

The migration's `settings.yml` step makes the file a shape **all current readers parse without falling
back**. The schema is **owned by `/aid-config`** (the sole creator/editor; grounding §1); this feature
only **validates/repairs** (era-a) or **synthesizes** (era-b) to it — it introduces **no** new key.

Canonical template source: `canonical/templates/settings.yml` (96 lines). Key inventory (grounding §1b):

| Dotted key | Type | Template default | Required for "valid"? | Migration handling |
|---|---|---|---|---|
| `project.name` | string (single-line, non-empty) | `<project-name>` | **REQUIRED** | era-a: keep if present & non-empty, else fill basename; era-b: repo folder basename |
| `project.description` | string (single-line, NO newlines) | `<project-description>` | REQUIRED key present (value may be placeholder) | era-a: keep; era-b: placeholder/empty |
| `project.type` | enum `brownfield`\|`greenfield` | `brownfield` | REQUIRED | era-a: keep if valid enum, else `brownfield`; era-b: `brownfield` |
| `tools.installed` | list<string> | `[claude-code]` | REQUIRED (≥0 entries; the block must exist) | era-a: keep; era-b: derive from `.aid/.aid-manifest.json` `tools` keys |
| `review.minimum_grade` | grade `^[A-F][+-]?$` | `A` | REQUIRED | era-a: keep if valid, else `A`; era-b: `A` |
| `execution.max_parallel_tasks` | positive int | `5` | REQUIRED | era-a: keep if int>0, else `5`; era-b: `5` |
| `traceability.heartbeat_interval` | int ≥0 (`0` disables) | `1` | REQUIRED | era-a: keep if int≥0, else `1`; era-b: `1` |
| `kb_baseline.{branch,tip_date}` | string / ISO-8601 | absent (commented example) | OPTIONAL (absent ≡ no baseline) | **PRESERVE** verbatim if present; never synthesize |
| `<skill>.minimum_grade` | grade `^[A-F][+-]?$` | absent (commented) | OPTIONAL | **PRESERVE** verbatim if present; never add |

- **"Valid" definition (the validate/repair-to contract; grounding §1).** A settings.yml is valid iff
  the readers below parse it **without falling back**: a top-level `project:` block carrying `name:` and
  `description:`, plus the four scalar sections `tools:`/`review:`/`execution:`/`traceability:` with the
  required keys above present and well-typed. **Repair** = ensure those exist with the right shape, filling
  template defaults for any missing/malformed required key, while **preserving** every present
  `kb_baseline` and per-skill override (DD-3).
- **Readers the repaired/synthesized file MUST keep parseable (grounding §1):**
  `canonical/scripts/config/read-setting.sh` (awk flat-section + list lookup, tolerant of a missing file
  via `--default`); the dashboard server `_read_settings` (`dashboard/server/server.py:189-214` line-scan
  `project:`→`name:`/`description:`, returns `(None,None)` on failure; Node twin parses the same); the
  dashboard reader `parse_project_name` (`parsers.py:155-199`) + `parse_kb_baseline` (`parsers.py:231-279`)
  + `_strip_yaml_inline_comment` (`parsers.py:202-228`). The migration MUST NOT emit a shape these
  fall-back on.
- **Era-a vs era-b (RC-4).** Era-a = `.aid/settings.yml` exists → **validate/repair**. Era-b = no
  `settings.yml` but a pre-0.7 KB marker exists → **synthesize** from template defaults + basename +
  manifest-derived `tools.installed` (STATE.md/DISCOVERY_STATE.md carry **no** name/description — grounding
  §2b — so they are NOT a config source; they only prove the repo IS an AID project).
- **Crash-safe write (NFR12, grounding §1).** Both repair (in-place edits / append-block) and synthesize
  (write a fresh template-derived file) use the existing temp-file + `mv -f` idiom
  (`aid-config/SKILL.md:124` single-line replace, `:126-132` append-block). Never an in-place truncating
  rewrite.

#### DM-2. `$AID_HOME/registry.yml` — reused verbatim (FR28/FR29; feature-010 DM-1)

The migration's **register** step reuses feature-010's registry **unchanged** — it does not redefine the
format. Recap (grounding §4a; live `bin/aid:1094-1127`):

```yaml
# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).
# Holds ONLY the base folders of repos this CLI install manages. Per-repo name/
# description/version are read from each repo's own .aid/settings.yml at render time.
schema: 1
repos:
  - /abs/path/to/repoA
  - /abs/path/to/repoB
```

- `repos` = **absolute, CAN-1-canonical** repo base-folder paths (the dir containing `.aid/`, not `.aid/`
  itself), where CAN-1 = `cd "$path" && pwd` (no `-P`) per feature-010 DM-1.
- The migration writes via `registry_register <canon-path>` (`bin/aid:1094`) — idempotent set-insert,
  atomic temp-file + `mv -f`, WARN-and-return-0 on failure (never blocks). It reads the existing registry
  via `_registry_read_repos` (`bin/aid:1082`) when the scan needs to skip already-registered repos. **No
  schema change.**

#### DM-3. The version-sentinel marker — `$AID_HOME/.migrated` (FR39; RC-1)

A persisted "last-migrated CLI version" marker the trigger compares against `$AID_HOME/VERSION`.

| Property | Value |
|----------|-------|
| **Path** | **`$AID_HOME/.migrated`** — a dotfile in the installed CLI tree, alongside the existing lazily-created `$AID_HOME/.update-check` cache (`bin/aid:159,174`) which it deliberately mirrors (a per-install runtime cache, not a guaranteed fresh-install member, not a per-repo artifact). Resolved by the same `$AID_HOME` rule (`bin/aid:40-47`). |
| **Scope** | Machine-level, one per CLI install. Removed wholesale by `aid remove self` (`rm -rf $AID_HOME`) — acceptable, the next upgrade re-triggers a scan. |
| **Format** | A single ASCII line: the CLI version string the machine scan **last completed** for (e.g. `1.3.0`), trimmed of whitespace exactly as `VERSION` is read (`tr -d '[:space:]'`, `bin/aid:170`). Absent ≡ "never migrated" ⇒ the sentinel treats any installed version as advanced (first upgrade after this feature ships triggers a scan). |
| **Lifecycle** | Written **only** after the machine scan completes (interactive, or non-interactive with the opt-in), set to the current `$AID_HOME/VERSION`. Written crash-safe (temp-file + `mv -f`). A non-interactive deferral does **NOT** advance the marker (so the next interactive run still triggers) — see FF-4. |
| **Writers** | Only the trigger path (FF-4) and `aid update self` on completion (FF-2). Never the per-repo migration (FF-1), never the server/page. |

- **Sentinel compare (DD-1).** "Advanced" = `VERSION` (trimmed) **!=** `.migrated` (trimmed), evaluated as
  a **string inequality**, not a semver `>`: any change to the installed version after a recorded marker
  is treated as "needs a scan." This is deliberately the cheapest, monotonic-enough test (the installer
  only ever moves the version forward; an equal string is the steady state and the **only** no-trigger
  case). It cannot loop: the marker is set to exactly the current `VERSION` once the scan completes, so a
  second invocation at the same version finds equality and does nothing (SEC-6).
- **Opt-out / opt-in env vars.** `AID_NO_MIGRATE=1` disables the sentinel trigger entirely (mirrors
  `AID_NO_UPDATE_CHECK`, `bin/aid:164`); `AID_MIGRATE_YES=1` is the **explicit non-interactive opt-in**
  (RC-3) that allows a no-TTY/CI/postinstall scan to actually migrate (default = annotate+defer).

#### DM-4. Legacy KB-summary relocation map (FR37 relocate; FR31 reuse; grounding §5)

| | Value |
|---|---|
| **OLD** | `<repo>/.aid/knowledge/knowledge-summary.html` (the only historical summary path — grounding §5) |
| **NEW** | `<repo>/.aid/dashboard/kb.html` |
| **Move** | `mkdir -p .aid/dashboard` then `mv -n` (no-clobber), guarded by `[ -f "$OLD" ] && [ ! -f "$NEW" ]` — the exact FR31 idiom already implemented at `canonical/scripts/summarize/summarize-preflight.sh:102-113` and `aid-housekeep/references/state-summary-delta.md:85-89`. Best-effort, idempotent (the `[ ! -f NEW ]` guard makes a re-run a no-op), **never deletes** (a clobber is skipped, leaving both files; NFR12). |

---

### Feature Flow

Four runtime cycles. FF-1 is the shared per-repo logic; FF-2/FF-3 are the two reaches (FR38); FF-4 is the
trigger (FR39). The **only** writes to a repo happen in FF-1, and only after the consent in FF-2/FF-3.

#### FF-1. Per-repo migration (FR37, the shared logic) — `_aid_migrate_repo <repo>`

Operates on a single CAN-1-canonical repo base folder. Each step is **idempotent + WARN-not-fail** (a
step's failure logs a WARN and the next step still runs; the repo is left in a valid-or-better state).

```
_aid_migrate_repo(<repo>):    # <repo> = CAN-1(base folder), pre-qualified by the caller (DETECT below)
  0. DETECT / QUALIFY (read-only; the caller already ran this for scan, re-checked here for the direct reach):
       qualifies iff  <repo>/.aid/ exists AND (
            <repo>/.aid/settings.yml exists                                  # era-a
         OR <repo>/.aid/knowledge/{DISCOVERY_STATE.md|DISCOVERY-STATE.md|STATE.md} exists )  # era-b (RC-4)
       a bare .aid/ with neither marker (e.g. only .aid/.temp) -> NOT a candidate -> return (no mutation)
  1. SETTINGS (validate/repair | synthesize -> DM-1):
       if .aid/settings.yml exists (era-a):
            validate against DM-1; if any required key missing/malformed -> REPAIR in place
            (temp-file + mv -f), PRESERVING kb_baseline + per-skill overrides (DD-3)
       else (era-b):  SYNTHESIZE from template defaults:
            project.name = basename(<repo>);  project.type = brownfield;  project.description = placeholder
            tools.installed = keys of <repo>/.aid/.aid-manifest.json "tools" (via manifest readers, LC-MIG)
            review/execution/traceability = template defaults (A / 5 / 1)
            write crash-safe (temp-file + mv -f)
       # idempotent: a valid era-a file -> no write
  2. ADD home.html (additive; RC-2 / FR40):
       if NOT -f <repo>/.aid/dashboard/home.html:
            mkdir -p <repo>/.aid/dashboard
            cp "$AID_HOME/dashboard/home.html"  <repo>/.aid/dashboard/home.html    # the single vendored source
       # idempotent: present -> no copy; NEVER overwrites an existing home.html (no-clobber by the -f guard)
  3. RELOCATE legacy summary (no-clobber; DM-4 / FR31):
       if [ -f <repo>/.aid/knowledge/knowledge-summary.html ] && [ ! -f <repo>/.aid/dashboard/kb.html ]:
            mkdir -p <repo>/.aid/dashboard && mv -n OLD NEW
       # idempotent + never deletes (the guard skips when NEW exists, leaving both)
  4. REGISTER (idempotent; DM-2 / FR28):
       registry_register CAN-1(<repo>)        # set-insert no-op if already present (bin/aid:1094)
  return 0   # WARN-not-fail: any single step's failure is logged, the repo ends valid-or-better
```

- **Ordering rationale.** Settings first (the readers + later steps assume a parseable config), then
  `home.html` (the served shell), then the summary relocation (so a present `kb.html` is co-located before
  registration makes the repo visible), then register (the repo is now fully compliant when it appears on
  the CLI home). Each step independently idempotent so a partial prior run resumes cleanly.
- **No-delete invariant (NFR12).** Step 2 only copies when absent; step 3 only moves under the `[ ! -f
  NEW ]` no-clobber guard; step 1 repairs/creates but never truncates (temp-file + `mv -f`); step 4 is a
  set-insert. **No step ever removes user data.**

#### FF-2. `aid update self` machine scan + All/Yes/No/Cancel (FR38)

Attaches **after** `_cmd_update_self` returns, before `exit` (the update-self dispatch block,
`bin/aid:1277-1278`). On npm/pypi channels `_cmd_update_self` returns early (the real upgrade happens via
the package manager), so the scan still runs against the now-current install.

```
aid update self [--yes]:
  _cmd_update_self            # existing CLI self-update (bin/aid:247); returns early on npm/pypi channel
  # ---- NEW post-update machine scan ----
  if NOT interactive (no TTY) AND NOT (--yes OR AID_MIGRATE_YES=1):
      annotate the discovered candidate list to stdout (read-only) and DEFER (do not mutate, do not
      advance the DM-3 marker) -> see FF-4 non-interactive rule
      exit 0
  candidates = SCAN_FOR_AID_REPOS()       # SEC-2 bounded, read-only (below)
  apply_all = (--yes OR AID_MIGRATE_YES=1)   # "All" preset by the opt-in
  for repo in candidates (deterministic order):
      if repo already fully compliant (FF-1 detect + all 4 steps satisfied):  continue   # silent no-op
      if NOT apply_all:
          prompt:  "Migrate <repo>? [A]ll / [Y]es / [N]o / [C]ancel"
          A -> apply_all = true; migrate this repo
          Y -> migrate this repo only
          N -> SKIP: do NOT migrate, do NOT register; advise:
                 "Skipped <repo>. Run 'aid update' inside that folder to migrate it later."
               continue
          C -> cancelled = true; break   # abort the scan; do NOT advance the marker (re-trigger next run)
      if apply_all OR (answer in {A,Y}):
          _aid_migrate_repo(repo)  || WARN "migration of <repo> failed: <reason>; continuing"   # NFR12 WARN-not-fail
  if NOT cancelled:
      set DM-3 marker = trimmed $AID_HOME/VERSION   # crash-safe; the upgrade is "complete" (FR39)
  # cancelled -> marker stays stale -> the sentinel (FF-4) re-fires on the next interactive aid run
  exit 0
```

- **All/Yes/No/Cancel contract.** **All** sets the `apply_all` "don't ask again" flag and migrates the
  current + every remaining repo without re-prompting. **Yes** migrates only the current repo, then
  re-prompts for the next. **No** skips (no migrate, **no register**) and prints the FR18 advisory.
  **Cancel** aborts the entire scan immediately (no further repos touched; already-migrated repos stay
  migrated) **and does NOT advance the DM-3 marker**, so the sentinel (FF-4) re-fires the scan on the
  next interactive `aid` run (the upgrade is not yet "complete" — FR39). The default `aid update self`
  is interactive; `--yes`/`AID_MIGRATE_YES=1` presets All.
- **WARN-not-fail (NFR12, mirrors registry NFR10).** A single repo's `_aid_migrate_repo` failure logs a
  `WARN` and the scan continues to the next repo; it never aborts the scan or fails the CLI op. **Cancel**
  is the only thing that stops the scan, and it's user-initiated.
- **Marker advance is the completion signal (FR39).** The DM-3 marker is set to the current `VERSION`
  **only** when the scan runs to completion under consent (interactive all-repos-visited, or opt-in
  non-interactive) — **never** on **Cancel** and **never** on a deferred non-interactive run. Both of
  those leave the marker stale so the next interactive `aid` re-triggers the scan (FF-4). "Completion"
  means every candidate was offered (migrated, skipped, or declined) without a Cancel.

#### FF-3. `aid update [<tool>...]` current-repo migration (FR38)

Attaches at the **`add|update` success tail** (`bin/aid:1563-1566`), right beside the existing
`registry_register "$_AID_TARGET"` side-effect (`:1565`). **No machine scan.**

```
aid update [<tool>...] [--target <dir>]:    # shares the add|update engine; bare 'aid update' resolves all manifest tools
  ... NEW self-update-if-needed: ensure the CLI is current (FR38). NOTE: the live add|update engine
      does NOT self-update today (it re-installs tool trees from the bundle, no _cmd_update_self call);
      FR38 ADDS a "self-update if a newer version exists" preamble to the 'update' reach. On npm/pypi
      channels this is the package-manager hint (like _cmd_update_self, bin/aid:250-259); on curl it is
      the bootstrap. This is an additive preamble, NOT existing behavior -- /aid-detail wires it. ...
  ... existing add|update tool loop (install_tool, UNCHANGED) ...
  AFTER the loop succeeds (bin/aid:1563, the exit-0 tail):
      registry_register "$_AID_TARGET"          # EXISTING side-effect (feature-010), UNCHANGED
      _aid_migrate_repo "$_AID_TARGET"          # NEW: per-repo FR37 migration on cwd/--target ONLY
      # _AID_TARGET is already CAN-1-canonical (cd && pwd at bin/aid:1366); register is idempotent so the
      # explicit register inside _aid_migrate_repo step 4 is a no-op here (the line above already ran)
  exit 0
```

- **Scope = the resolved target only.** `$_AID_TARGET` is the canonicalized cwd/`--target`
  (`bin/aid:1366`). FF-3 runs FF-1 on exactly that one repo — no enumeration, no consent prompt (the
  operator already invoked `aid update` inside the repo, which is the consent). This is the reach a
  declined-`No` repo from FF-2 is told to use.
- **The self-update preamble is a new addition (FR38), not existing behavior.** The live `add|update`
  engine re-installs tool trees from the bundle and does **not** call `_cmd_update_self`; FR38's "ensures
  the CLI is current (self-update if a newer version exists)" is an **additive preamble** on the `update`
  reach only (not `add`). Its exact wiring (reuse `_cmd_update_self`'s channel logic vs a lighter version
  check) is a /aid-detail mechanic (Residual OQ-6); the invariant is "update implies current CLI before
  the per-repo migration."
- **Idempotent beside the existing register.** Because `registry_register` already ran at `:1565`, FF-1's
  step 4 is a set-insert no-op; the other three steps run as FF-1 specifies. A fully-compliant repo => the
  whole call is a no-op.

#### FF-4. The sentinel / postinstall trigger (FR39, RC-1, RC-3)

Two trigger surfaces feed the **same** FF-2 scan. The sentinel is the universal cross-manager guarantee;
the npm postinstall is the eager path.

```
A) VERSION-SENTINEL LAZY FIRST-RUN (universal: pypi, --ignore-scripts, curl) -- in bin/aid early dispatch:
     # runs near the existing _aid_check_update call site, gated identically
     if AID_NO_MIGRATE=1:  skip
     installed = trim($AID_HOME/VERSION);  marker = trim($AID_HOME/.migrated  if present else "")
     if installed != "" AND installed != marker:        # "advanced" (DM-3 / DD-1) -- string inequality
         if interactive (TTY):
             run FF-2 scan once (this marks the DM-3 marker = installed on completion)
         else (no TTY / CI):
             if AID_MIGRATE_YES=1:  run FF-2 (opt-in) -> marks marker
             else:                  annotate "AID upgraded to <installed>; run 'aid update self' to migrate
                                     your repos." ; DEFER (do NOT mark the marker) -> next interactive run retriggers
     # else installed == marker -> steady state -> no trigger (SEC-6 no-loop)

B) npm POSTINSTALL (eager, on `npm i -g aid-installer`) -- NEW "postinstall" in packages/npm/package.json:
     runs a node entry that spawns the vendored bin/aid with `update self` semantics in a non-interactive
     context -> hits the FF-4(A) no-TTY branch -> annotate + DEFER unless AID_MIGRATE_YES=1 (NFR12; SEC-1)
     # pypi has NO equivalent (PEP 517 wheels, grounding §3e) -> pypi relies entirely on the sentinel (A)
```

- **RC-1: why both.** pypi wheels have **no** install-time hook (grounding §3e), so the **sentinel (A) is
  the primary, universal guarantee** — it covers pypi, `npm --ignore-scripts`, and the curl bootstrap. The
  **npm postinstall (B)** is an *eager* convenience that fires sooner on `npm i -g`, but because npm
  postinstall runs **non-interactively** it (like any non-interactive trigger) **annotates + defers** by
  default (NFR12) — it does not silently mutate. The eager-vs-lazy distinction is *when the user is
  reminded*, not *whether repos are mutated without consent*.
- **Sentinel cannot loop (SEC-6).** The marker is set to the current `VERSION` exactly once per upgrade,
  on scan completion; equality thereafter = no trigger. A deferral leaves the marker stale on purpose, so
  the next *interactive* run picks it up — that is one retrigger per upgrade until an interactive scan
  completes, never an unbounded loop within a single version.

---

### Layers & Components

All edits land in the **hand-maintained** `bin/aid` + `bin/aid.ps1` twin and the package/vendor layer —
**NOT** `canonical/`→render artifacts (C8). Per `coding-standards.md` (small, deterministic, no hidden
I/O) and the existing installer-engine conventions.

| Component | Where | Responsibility | MUST NOT |
|-----------|-------|----------------|----------|
| **LC-MIG Migration function set (×2: Bash in `bin/aid` + PowerShell twin in `bin/aid.ps1`)** | `bin/aid` / `bin/aid.ps1` | `_aid_migrate_repo <repo>` (FF-1: detect/qualify, settings validate/repair\|synthesize, add `home.html`, relocate summary, register); the scan enumerator `SCAN_FOR_AID_REPOS` (SEC-2 bounded, read-only); the All/Yes/No/Cancel consent loop (FF-2); the sentinel check + marker R/W (FF-4/DM-3). Reuses `registry_register`/`_registry_read_repos` (`bin/aid:1082,1094`), the FR31 `mv -n` idiom (DM-4), and the `lib/aid-install-core.sh` manifest readers (`manifest_list_tools`/`manifest_read_*`) for era-b `tools.installed` detection | be authored in `canonical/`/be subject to render-drift (C8); delete or overwrite user data; mutate a repo before consent (FF-2) or in a non-interactive context without the opt-in (FF-4/SEC-1); follow `..`/symlink escape during the scan (SEC-2); write `settings.yml` non-atomically; diverge Bash↔PS (parity gate) |
| **LC-VND Vendor / package layer** | `packages/npm/scripts/vendor.js`, `packages/pypi/scripts/vendor.py`, `packages/npm/package.json` | add `dashboard/home.html` to **both** vendor manifests' copy lists (so it installs to `$AID_HOME/dashboard/home.html`, FR40); add the npm `"postinstall"` script (FF-4 B). | ship a second committed `home.html` source (C8/FR40); add a pypi runtime install hook (PEP 517 has none — grounding §3e); break the existing 17-file vendor set (additive only) |
| **LC-HSRC `home.html` source move** | `dashboard/home.html` (new committed source) ← from `.aid/dashboard/home.html` (the current d010 dogfood file) | `dashboard/home.html` becomes the **single source of truth** (alongside `dashboard/index.html`, the CLI-home page). The dogfood repo's own `.aid/dashboard/home.html` becomes a **copy** kept in sync by a vendor/sync step (DD-5). | leave two divergent committed sources (C8/FR40); change the page's behavior (it is a relocation, the SPA shell content is unchanged) |
| **LC-REG Registry I/O (feature-010)** | `bin/aid` | `registry_register`/`_registry_read_repos` — consumed **as-is** by LC-MIG | (owned by feature-010; not re-specified) |
| **LC-CORE Installer engine (existing)** | `lib/aid-install-core.sh` / `.psm1` | `manifest_list_tools`/`manifest_read_*` — consumed **as-is** by LC-MIG for era-b tool detection | (owned by the installer; not re-specified) |

- **The two `bin/aid` dispatch hook points (re-pinned against the live file; /aid-detail re-pins).**
  (1) **`aid update self` scan** — inserted in the update-self dispatch block **between
  `_cmd_update_self` (`bin/aid:1277`) and `exit $?` (`:1278`)**, so the scan runs after the CLI is current
  (FF-2). (2) **`aid update [<tool>]` current-repo migration** — inserted at the **`add|update` success
  tail (`bin/aid:1563-1566`)**, immediately after the existing `registry_register "$_AID_TARGET"`
  (`:1565`) and before `exit 0` (`:1566`) (FF-3). The **sentinel check** (FF-4 A) is inserted near the
  existing `_aid_check_update` call site (the throttled early-dispatch update-notice block, `bin/aid:152-`)
  and gated by the same TTY/opt-out posture.
- **`home.html` is repo-agnostic, so a single vendored copy suffices (RC-2/FR40).** It is a static SPA
  shell that fetches `/r/<id>/api/model` at runtime; nothing in it is repo-specific. Therefore: ONE source
  (`dashboard/home.html`) → vendored to `$AID_HOME/dashboard/home.html` → copied per repo. **No server
  install-tree fallback** — each repo physically holds its own `home.html` (NFR11, self-contained); the
  multi-repo server (feature-010) keeps serving the **per-repo** file at `/r/<id>/home.html` exactly as it
  does today (a `has_home=false` repo still renders a "dashboard not generated yet" card until migrated —
  the migration is what flips it to served).
- **PowerShell twin parity (NFR5, grounding §3f).** Every LC-MIG function has a `bin/aid.ps1` twin —
  same `$AID_HOME` resolution, same era-a/era-b branch, same first-class no-clobber/atomic semantics, same
  All/Yes/No/Cancel wording, same exit codes. Gated by `test-aid-cli-parity.sh`.
- **Cross-manager mechanics.** On npm/pypi channels `_cmd_update_self` returns early (the package manager
  did the upgrade); the FF-2 scan still runs against the now-current install. The **pypi** path has no
  postinstall (grounding §3e) and is covered **solely** by the FF-4(A) sentinel.

---

### CLI / Command spec

Two existing commands gain new tail behavior. **No new verb, no grammar change** (FR38).

#### CLI-1. `aid update self` — machine scan (FR38)

- **Grammar.** `aid update self [--force|-y]` (existing, `bin/aid:1271-1276`) gains an **opt-in alias**
  `--yes` (the non-interactive "apply All" opt-in, RC-3; equivalent to `AID_MIGRATE_YES=1`). `--force`/`-y`
  remain no-ops for the self-update itself.
- **New behavior (post-update tail).** After `_cmd_update_self` returns, runs the FF-2 machine scan +
  per-repo All/Yes/No/Cancel.
- **Prompt wording (exact contract; ASCII-only per C8).**
  `Migrate <repo>? [A]ll / [Y]es / [N]o / [C]ancel:` — `A` = apply to this and all remaining repos
  without re-asking; `Y` = this repo only; `N` = skip (do not migrate, **do not register**); `C` = abort
  the whole scan.
- **Declined-repo advisory (FR18/FR38).** On `N`:
  `Skipped <repo>. Run 'aid update' inside that folder to migrate it later.`
- **Non-interactive (no TTY / CI / postinstall).** Without `--yes`/`AID_MIGRATE_YES=1`: annotate the
  candidate list + defer (no mutation, marker not advanced). With the opt-in: migrate all candidates,
  advance the marker.
- **Exit codes.** `0` on a completed scan (including all-skipped or all-no-op). The scan **never** changes
  the self-update's exit code on the failure path — a per-repo migration failure is a `WARN`, the scan
  continues, and the command still exits `0` (NFR12). **Cancel** also exits `0` (a user-chosen stop is not
  an error).

#### CLI-2. `aid update [<tool>...]` — current-repo migration (FR38)

- **Grammar: UNCHANGED.** `aid update [<tool>...] [--target <dir>] [--version <v>] [--from-bundle <p>]`
  keeps its exact surface (`bin/aid` add|update help) and exit codes.
- **New semantics (two additions to the `update` reach).** (1) A **self-update-if-needed preamble** —
  FR38 mandates `aid update` ensure the CLI is current first; the live engine does **not** do this today
  (it re-installs tool trees, no `_cmd_update_self` call), so this is an additive preamble on the `update`
  reach only, wired at detail (Residual OQ-6). (2) After the `add|update` loop succeeds and the existing
  `registry_register "$_AID_TARGET"` runs (`bin/aid:1565`), run `_aid_migrate_repo "$_AID_TARGET"` (FF-3)
  on the resolved cwd/`--target` **only** — no scan, no prompt.
- **Output.** The migration prints one concise line per action taken (e.g.
  `Migrated <repo>: synthesized settings.yml, added home.html.`) and is **silent** when the repo is
  already compliant (idempotent no-op). A step failure prints
  `WARN: aid: migration step '<step>' failed for <repo>: <reason>` and the command **still exits with its
  host-tool result** (NFR12).
- **Cross-platform parity (NFR5/C8).** A **direct edit** to hand-maintained `bin/aid` (Bash) +
  `bin/aid.ps1` (PowerShell twin) — byte-behavior twins. Gates: **ASCII-only**
  (`tests/canonical/test-ascii-only.sh`), **Bash↔PowerShell parity** (`tests/canonical/test-aid-cli-parity.sh`
  — identical exit codes + messages), **vendored-copy refresh** (`packages/npm/scripts/vendor.js` +
  `packages/pypi/scripts/vendor.py`). **NOT** render-drift / `run_generator.py` (C8 — these files are not
  `canonical/`-rendered).

---

### Security Specs

The migration's whole risk surface is "scanning the machine and mutating repos." NFR12 + C8 pin it to:
read-only-until-consent, bounded scope, no traversal, additive/no-clobber/crash-safe mutation, and a
non-looping sentinel.

- **SEC-1. Read-only until consent (NFR12, C8 annotate+offer).** `_aid_migrate_repo`'s DETECT step and the
  scan's enumeration are **pure reads** (`test -f`/`test -d`, manifest reads, registry read). **No write
  to any repo** happens before the operator answers `A`/`Y` (FF-2), invokes `aid update` in the repo
  (FF-3), or sets the explicit opt-in (FF-4). A non-interactive context **never** mutates without
  `AID_MIGRATE_YES=1`/`--yes`. This is the project's "annotate what we cannot prove and let the user
  confirm" posture (MEMORY "ask-user-over-auto-proof").
- **SEC-2. Bounded scan scope, no traversal (NFR12, C8).** `SCAN_FOR_AID_REPOS` enumerates candidate
  `.aid/` folders under a **bounded** root set with a **bounded depth**, and **skips** `node_modules/`,
  `.git/`, and other heavy/irrelevant trees. It detects a candidate by the **presence test** of
  `.aid/settings.yml` OR `.aid/knowledge/{DISCOVERY_STATE.md|DISCOVERY-STATE.md|STATE.md}` — it never
  follows a path supplied by an untrusted source, never resolves `..` to climb out of the scan root, and
  treats symlinked directories as non-candidates rather than following them out of scope. The exact scan
  root(s) + depth cap + the symlink-handling policy are a **/aid-detail mechanic** (Residual OQ-1) — the
  invariant fixed here is **bounded + no escape + read-only**.
- **SEC-3. Mutations are additive / no-clobber / crash-safe (NFR12, C8 never-destroys).** `home.html` is
  only **copied when absent** (no overwrite); the legacy summary is moved with **`mv -n`** under a
  `[ ! -f NEW ]` guard (a clobber is skipped, both files kept); `settings.yml` is written via **temp-file
  + `mv -f`** (never an in-place truncating rewrite) and **preserves** `kb_baseline` + per-skill overrides;
  the registry write is `registry_register`'s own atomic temp-file + `mv -f`. **No step deletes user
  data.** A crash mid-step leaves either the old or the new complete file (atomic rename), and the next run
  resumes idempotently.
- **SEC-4. WARN-not-fail isolation (NFR12).** A single repo's migration failure is contained to a `WARN`;
  it never aborts the machine scan (FF-2), never fails the `aid update`/`aid add` host-tool op (FF-3), and
  never corrupts a sibling repo (each `_aid_migrate_repo` operates only within its own `<repo>/.aid/`).
- **SEC-5. No path injection into the registry or per-repo paths.** The repo path registered and the per-
  repo target are **CAN-1-canonical** (`cd "$repo" && pwd`, no `-P`) — the same rule feature-010 uses — so
  the migration cannot register a non-canonical or traversal-laden path, and the id↔path resolution stays
  consistent with feature-010's server.
- **SEC-6. The sentinel cannot loop (FR39/DM-3).** The DM-3 marker is set to exactly the current
  `$AID_HOME/VERSION` once the scan completes; a subsequent invocation at the same version finds string
  equality and does **not** re-trigger. The only retrigger is a *deferred* non-interactive run (which
  deliberately leaves the marker stale so the next interactive run picks it up) — bounded to one retrigger
  per upgrade until an interactive (or opt-in) scan completes. `AID_NO_MIGRATE=1` disables the trigger
  entirely.

---

### §6 Quality Gates

The applicable gates (C8: **ASCII + parity + vendor-refresh, NOT render-drift**) plus the
migration-specific functional gates.

1. **ASCII-only source (C8).** `tests/canonical/test-ascii-only.sh` passes for the edited `bin/aid` +
   `bin/aid.ps1` (MEMORY "ASCII-only PowerShell scripts"; Windows ANSI-codepage hazard). All prompt
   wording / advisories are ASCII.
2. **Bash↔PowerShell parity (C8/NFR5).** `tests/canonical/test-aid-cli-parity.sh` passes — `bin/aid` and
   `bin/aid.ps1` produce identical exit codes + messages for the new migration commands (era-a/era-b
   branches, All/Yes/No/Cancel wording, declined advisory, WARN lines).
3. **Vendored-copy refresh (C8/FR40).** Running `node packages/npm/scripts/vendor.js` +
   `python3 packages/pypi/scripts/vendor.py` re-vendors the edited `bin/aid`/`bin/aid.ps1` **and** the new
   `dashboard/home.html`; a test asserts `dashboard/home.html` is present in **both** manifests' copy lists
   and lands at the vendored `$AID_HOME/dashboard/home.html` path. **NOT** render-drift / `run_generator.py`
   (C8 — these are hand-maintained files; verifying they are absent from `canonical/EMISSION-MANIFEST.md`).
4. **Migration unit tests — era-a (TEST).** Fixture repos: (a) **valid** `settings.yml` + `home.html` +
   registered ⇒ the migration is a **no-op** (no fs change, no registry change); (b) **malformed/incomplete**
   `settings.yml` (missing a required section, plus a present `kb_baseline` + a per-skill override) ⇒
   repaired to DM-1 validity, **`kb_baseline` + override preserved**, parseable by `read-setting.sh` and the
   server/reader.
5. **Migration unit tests — era-b (TEST).** Fixture repo: **no** `settings.yml`, a
   `.aid/knowledge/STATE.md` (and a variant with `DISCOVERY_STATE.md`) + a `.aid/.aid-manifest.json` ⇒
   `settings.yml` synthesized with `project.name=basename`, `project.type=brownfield`,
   `tools.installed`=manifest keys, defaults elsewhere; parseable by all readers.
6. **Idempotency (TEST).** Running `_aid_migrate_repo` **twice** on each fixture = the second run is a
   **no-op** (no fs change, no registry change) — assert byte-identical tree + registry after run 2.
7. **No-delete (TEST).** A fixture with both a legacy `knowledge-summary.html` **and** an existing
   `kb.html` ⇒ migration keeps **both** (no-clobber); a fixture with an existing `home.html` ⇒ it is
   **never overwritten**. Assert no user file is removed in any fixture.
8. **Bare-`.aid/` non-candidate (TEST).** A folder with only `.aid/.temp/` (no `settings.yml`, no KB
   marker) ⇒ the scan does **not** treat it as a candidate and mutates nothing.
9. **Cross-manager trigger (TEST).** With `$AID_HOME/VERSION` advanced past `$AID_HOME/.migrated`: an
   interactive sentinel run triggers the scan once + advances the marker; a second run at the same version
   does **not** retrigger (SEC-6); a non-interactive run without the opt-in **defers** (annotates, marker
   unchanged); with `AID_MIGRATE_YES=1` it migrates + advances. Exercises the pypi-no-postinstall path
   (sentinel-only) and the npm-postinstall path.
10. **R5 Playwright on a freshly-migrated repo (hard gate, TEST/DESIGN).** Run the migration on an era-b
    fixture repo, register it, start the multi-repo server, and **render that repo's `home.html` in
    Playwright** — assert the provisioned SPA shell loads, polls `/r/<id>/api/model`, and renders (no 404,
    no blank page). Per the global CLAUDE.md web-review gate, source-only inspection is an automatic FAIL.
    This is the concrete proof KI-010 is resolved.

---

### Design Decisions

| ID | Decision | Rationale / alternatives rejected |
|----|----------|-----------------------------------|
| **DD-1** | **Sentinel compare = string inequality `VERSION != .migrated`, not a semver `>`.** | The installer only ever moves the version forward, and the steady state is exact equality. A string inequality is the cheapest test, needs no semver parser in shell/PS, and is monotonic-enough (any change after a recorded marker means "scan"). It cannot loop because the marker is set to exactly the current `VERSION` on completion (SEC-6). A semver `>` was rejected as over-engineered (a downgrade would then *not* migrate, but a downgrade is not a supported upgrade path and the inequality's "scan on any change" is the safer default). |
| **DD-2** | **Manifest is the era-b `tools.installed` source, not STATE.md.** | `.aid/knowledge/{DISCOVERY_STATE.md,STATE.md}` carries **no** name/description/tools (grounding §2b); `.aid/.aid-manifest.json` is the authoritative installed-tools record the installer maintains. Reusing the existing `manifest_list_tools`/`manifest_read_*` readers (`lib/aid-install-core.sh`) avoids inventing a parser and matches what `aid add`/`aid remove` already key off (feature-010 DD-4). STATE.md is used **only** to qualify the repo as era-b, never as a config source. |
| **DD-3** | **`settings.yml` repair PRESERVES `kb_baseline` + per-skill overrides via targeted edits, never a wholesale template overwrite.** | `kb_baseline` is producer-written (`aid-discover`/`aid-housekeep`, FR35) and per-skill overrides are user-authored; a template-overwrite repair would destroy them (an NFR12 no-delete violation). Repair therefore ensures only the *missing/malformed required* keys, leaving every present optional block byte-intact — reusing the `/aid-config` single-line-replace (`SKILL.md:124`) + append-block (`:126-132`) crash-safe idioms. Synthesize (era-b) writes a fresh template-derived file because there is nothing to preserve. |
| **DD-4** | **The two reaches share ONE `_aid_migrate_repo`; only the enumeration + consent differ.** | FR38 mandates shared logic, different reach. Factoring all four steps into one function means the machine scan (FF-2) and the current-repo path (FF-3) cannot drift; the scan adds enumeration + All/Yes/No/Cancel on top, the current-repo path adds nothing (the `aid update` invocation is itself the consent). This keeps the per-repo behavior provably identical across both reaches and makes FF-3 a one-line tail beside the existing `registry_register`. |
| **DD-5** | **`home.html` single SOURCE OF TRUTH = `dashboard/home.html`; the dogfood repo's `.aid/dashboard/home.html` is a DERIVED copy whose equality is CI-enforced (RC-2).** | KI-010 + FR40 + C8 require exactly one *source of truth* so the shipped/served shell is unambiguous. The current d010 content **moves** to `dashboard/home.html` (alongside the CLI-home `dashboard/index.html`), gets vendored to `$AID_HOME/dashboard/home.html`, and the migration/`aid add` copy it per repo. The AID repo's own `.aid/dashboard/home.html` is then a **derived copy**. Because it is also committed (the dogfood dashboard must be servable from a checkout), the two files *can* diverge between edits; a **CI equality gate** (`dashboard/home.html` == `.aid/dashboard/home.html`) **detects** any divergence and fails the build — it catches drift rather than making it structurally impossible. (A stronger alternative — gitignore the dogfood copy and generate it from the source — is left as an /aid-detail option, OQ-5.) A server install-tree fallback was **rejected** (RC-2): repos must be self-contained (NFR11) — each holds its own copy, the server keeps serving the per-repo file. |
| **DD-6** | **Detection is a presence-test of two markers, not a heuristic "looks like AID".** | C8 forbids auto-mutating a repo a heuristic merely *guesses* is AID. A bare `.aid/` (e.g. only `.aid/.temp`) is **not** a candidate; only `.aid/settings.yml` (era-a) or a `.aid/knowledge/` discovery/state marker (era-b) qualifies — both are facts the AID pipeline itself writes, so the test is provable, not guessed (matches FR37's qualify rule + the project's annotate+offer posture). |

---

### Reconciliations (resolved design decisions)

> _Settled with the user; recorded as reconciliations with rationale._

| ID | Reconciliation | Rationale |
|----|----------------|-----------|
| **RC-1** | **Trigger = a version-sentinel lazy first-run in `bin/aid` (primary, universal) + an npm `postinstall` (eager).** Sentinel marker = **`$AID_HOME/.migrated`** (a single trimmed version line, DM-3); opt-out env var **`AID_NO_MIGRATE=1`**; non-interactive opt-in **`AID_MIGRATE_YES=1`** (and the `--yes` alias on `aid update self`). | pypi wheels have **no** install-time hook (PEP 517, grounding §3e), so an npm-only postinstall cannot guarantee the upgrade completes for pypi/`--ignore-scripts`/curl installs. The sentinel — comparing installed `$AID_HOME/VERSION` against the persisted `.migrated` marker on `aid` invocation — is the **universal cross-manager guarantee** and honors FR39's "upgrade not complete until migration" by gating the marker advance on scan completion. The npm postinstall is kept as the *eager* reminder path. Marker path mirrors the existing `$AID_HOME/.update-check` precedent (`bin/aid:159,174`); opt-out var mirrors `AID_NO_UPDATE_CHECK`. |
| **RC-2** | **`home.html` single source = `dashboard/home.html`**, vendored into **both** manifests → `$AID_HOME/dashboard/home.html`; migration + `aid add` copy it into each repo's `.aid/dashboard/home.html`. The current d010 `.aid/dashboard/home.html` content **moves** to `dashboard/home.html`; the dogfood copy is a derived copy whose equality with the source is CI-enforced (DD-5). **No server install-tree fallback** — repos hold their own copy (NFR11). | KI-010 + FR40 + C8 demand exactly one source of truth (drift caught by a CI equality gate) and self-contained repos (NFR11). A single static, repo-agnostic SPA shell satisfies both: one source, vendored, copied per repo. The server keeps serving the **per-repo** file at `/r/<id>/home.html` (feature-010, unchanged) — a fallback would break the self-contained invariant and complicate the server, so it is rejected. |
| **RC-3** | **Non-interactive safety: the scan annotates + defers in no-TTY/CI/postinstall contexts; it mutates only with the explicit opt-in `AID_MIGRATE_YES=1` / `--yes`.** | NFR12 + C8 forbid silent machine-wide mutation. In CI/postinstall there is no operator to answer All/Yes/No/Cancel, so the safe default is "annotate the candidate list and defer to the next interactive `aid update self`," with an explicit opt-in for users who *want* unattended migration (e.g. an automated provisioning script). This is the project's annotate+offer posture (MEMORY). The deferral deliberately leaves the DM-3 marker stale so the next interactive run still triggers. |
| **RC-4** | **Era-b synthesis = template defaults + `project.name`=repo folder basename + `tools.installed` from `.aid/.aid-manifest.json`; `project.description`=placeholder; `project.type`=`brownfield`. Pre-0.7 detection accepts `.aid/knowledge/{DISCOVERY_STATE.md, DISCOVERY-STATE.md, STATE.md}`.** | STATE.md/DISCOVERY_STATE.md carry **no** name/description (grounding §2b), so synthesis cannot lift config from them — basename (the dashboard's own fallback, `models.py:166`) + manifest-derived tools + template defaults is the only grounded source. Accepting all three KB-marker filenames covers the rename history (DISCOVERY-STATE → STATE, grounding §2a) and the UNCERTAIN pre-0.7 exact filename without risking a missed era-b repo. |

---

### Known issues addressed / registered by this feature

- **Resolves KI-010** (`home.html`-not-provisioned). FR40 vendors `dashboard/home.html` to
  `$AID_HOME/dashboard/home.html` and the migration (FF-1 step 2) + a fresh `aid add` copy it into each
  repo's `.aid/dashboard/home.html`. The §6 R5 Playwright gate is the concrete proof a freshly-migrated
  repo's `home.html` renders. KI-010 should be marked **RESOLVED (feature-011)** at delivery.
- **No new known defect introduced at spec time.** The mutation surface is bounded by SEC-1..6 and the §6
  no-delete/idempotency/parity tests. If, during implementation, the scan root/depth policy (Residual OQ-1)
  or the era-b filename set proves to need an edge handled beyond DD-6/RC-4, that becomes a real KI then —
  it is not a defect now.

---

### Residual open questions (for /aid-plan and /aid-detail)

Detail-phase mechanics, not design gaps — the design is decided; these are "exact wiring" items:

1. **Scan root(s) + depth cap + symlink policy (SEC-2).** The bounded scan scope is fixed in principle
   (bounded, no escape, skip `node_modules`/`.git`); the exact default root set (e.g. `$HOME` subtree vs a
   configured list), the depth limit, and whether to follow non-escaping symlinks are a detail-phase pick.
   Recommendation: a conservative bounded set with a shallow depth + a `--root <dir>` override on
   `aid update self`, never following symlinks out of scope.
2. **`bin/aid` line anchors.** Re-pinned at spec time against the live file (header note), but the file is
   edited under /aid-detail — **re-pin all `bin/aid:NNN` seams at detail** (grounding §3b).
3. **npm postinstall entry shape (FF-4 B).** Whether the postinstall spawns `bin/aid` with `update self`
   in a guaranteed non-interactive context (and how it inherits `AID_MIGRATE_YES`) vs a dedicated thin
   node entry — pick at detail; the invariant (annotate+defer unless opt-in) is fixed (RC-3).
4. **`settings.yml` repair granularity (DD-3).** Whether era-a repair edits only the missing keys in place
   or rewrites the whole file from the template while splicing back preserved blocks — pick the
   simplest-correct at detail; the invariant (preserve `kb_baseline`+overrides, crash-safe) is fixed.
5. **Vendor/sync check for the dogfood `home.html` copy (DD-5/RC-2).** The exact sync step (a make/CI
   check that `.aid/dashboard/home.html` == `dashboard/home.html`) — wire at detail.
6. **`aid update` self-update-preamble wiring (CLI-2/FF-3).** The live `add|update` engine does not
   self-update; FR38 requires it. Whether the preamble reuses `_cmd_update_self`'s channel logic
   (npm/pypi hint vs curl bootstrap, `bin/aid:247-268`) or a lighter "skip if already current" version
   check — pick the simplest-correct at detail; the invariant ("update implies current CLI before the
   per-repo migration") is fixed.
