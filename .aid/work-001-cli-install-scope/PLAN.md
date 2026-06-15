# Plan — CLI install-scope, repo discovery, and migration model

> **Work:** work-001-cli-install-scope
> **Source of truth:** `REQUIREMENTS.md` (§10 priority) + the 5 feature SPECs under
> `features/feature-*/SPEC.md` (all graded A+) + `.aid/design/cli-install-scope-and-migration.md`.
> **Dogfood:** AID applied to its own repo.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-15 | Plan fixes: per-delivery test migration (green-per-delivery), staging-coordination note, prose; SPEC stale-ref cleanup | /aid-plan |

## Overview

Five A+ feature SPECs are sequenced into **three deliverables**, each a
standalone-functional MVP, foundation-first, with every dependency satisfied by a
prior delivery. The grouping is driven by one hard constraint (the migration-trigger
coupling, below) layered on top of the REQUIREMENTS §10 priority order.

### The migration-trigger coupling (001 ↔ 003) — how it is resolved

`feature-001` **removes** the legacy migration trigger (the
`_aid_check_migrate_sentinel` machine sentinel, the `$AID_HOME/.migrated` marker, and
the `$HOME`-walking `_aid_scan_for_repos`) and **stubs the `update self` post-step to a
no-op**. `feature-003` **adds the replacement trigger** — the per-repo `format_version`
stamp gate — and wires it into the **same call sites** (`bin/aid:1918`/`:1978`) that
001 vacated. feature-003's SPEC states this explicitly: *"The two features touch the
same call sites and must land together or sequence feature-001 first."*

If `feature-001` shipped **alone** as its own delivery, that delivery would have the
old trigger removed and **no replacement** — a coherent-but-incomplete migration story
(repos still operate read-only, but no migration is ever offered). To avoid any
delivery shipping that gap, **delivery-001 groups features 001 + 002 + 003 together**:
the home split (001), the global state provisioning that makes the global STATE home
actually writable (002), and the stamp gate that re-arms migration (003) all land in
one delivery. Within that delivery the execution graph sequences 001 → 003 so the
stamp gate replaces the sentinel at the moment it is removed, and the delivery's exit
state has a complete, coherent migration model: lazy per-repo stamp gate (no scan, no
machine marker). This is a deliberate, documented P1/P2 mix (003 is REQUIREMENTS §10
Priority 2) justified solely by the trigger coupling — it is the smallest grouping that
ships a non-broken migration story.

## Deliverables

### delivery-001: Root-cause fix — CODE/STATE split, global provisioning, and the stamp-gate migration trigger

- **What it delivers:** The end of the v1.0→v1.1 dogfood failure. An unprivileged
  `aid status` on a root-owned npm-global install operates with **no permission-denied
  error and no migration re-prompt loop** (AC1). Code and state homes resolve
  independently (`AID_CODE_HOME` read-only / `AID_STATE_HOME` mutable; `AID_HOME`
  redirects STATE only — AC4). A global install **provisions `/var/lib/aid`** at install
  time (root-owned, world-readable, seeded `registry.yml`), with a non-prompting runtime
  ensure-exists fallback (AC6). The legacy `.migrated` marker + `$HOME` scan are
  **removed** (AC7) and **replaced** by the per-repo `format_version` fail-safe stamp gate
  (AC3): newer-format repos are refused; older/absent stamps trigger a non-blocking
  migration offer. `.update-check` always resolves to `~/.aid` and never elevates (AC10).
- **Features:** feature-001 (runtime scope + CODE/STATE split; removes marker/scan/sentinel;
  stubs the update-self scan-caller to no-op; owns the
  `AID_STATE_HOME = ${AID_SHARED_STATE_HOME:-/var/lib/aid}` seam), feature-002
  (install-time `/var/lib/aid` provisioning + non-prompting runtime fallback),
  feature-003 (per-repo `format_version` stamp + fail-safe migration gate — the
  REPLACEMENT trigger).
- **Depends on:** PR #78 (prerequisite, merged to master first — see Prerequisites).
- **Priority:** Highest. REQUIREMENTS §10 Priority 1 (FR1/FR2/FR7/FR8/FR10; AC1/AC4/AC6/AC7/AC8/AC10)
  plus feature-003 (FR3/AC3, §10 Priority 2) pulled in **only** to satisfy the
  migration-trigger coupling so the delivery's migration story is coherent.
- **Standalone-functional:** Ships a complete, coherent install/state/migration model —
  the reported root-cause bug is fixed, the code/state homes are decoupled, global state
  is provisioned, and migration is re-armed via the lazy per-repo stamp gate (no scan, no
  machine marker) — usable on its own with no half-removed trigger.
- **Testing — suite stays green at this delivery boundary:** d001 carries the canonical
  test work for everything features 001/002/003 break, so `tests/run-all.sh` is green
  HOME-pinned at the d001 exit. Concretely: rework the AID_HOME-conflation fixture (the
  single conflated `new_aid_home`-style payload+state dir split into a CODE_HOME +
  STATE_HOME pair) in the suites that build it (`test-aid-dashboard-cli.sh`,
  `test-aid-remote.sh`, `test-aid-migrate.sh`); retire the removed `.migrated` / sentinel /
  `$HOME`-scan assertions and rewrite the `test-aid-migrate-trigger.sh` trigger model to
  the lazy-stamp model (absent stamp on encounter → stamp written + offer); add the
  `format_version` stamp + fail-safe gate assertions (constant parity in
  `test-aid-cli-parity.sh`, refuse-on-newer / offer-on-older / malformed in
  `test-aid-migrate.sh` + `test-aid-cli-ps1.sh`); and the `/var/lib/aid`
  install-provisioning assertions (`AID_SHARED_STATE_HOME` seam, non-prompting fallback).
  Every migration/encounter test keeps its `HOME`-pin + escape canary. This is the
  per-delivery slice of the suite migration; the v1.0/v1.1 bootstrap procedure and the
  final full-suite reconciliation sweep remain in d003.

### delivery-002: Coherent discovery — two-tier registry, cwd dispatch, and registry-driven `update self` migration

- **What it delivers:** The full discovery-and-dispatch model on top of the home split.
  A **two-tier registry** (user `~/.aid/registry.yml` + shared `$AID_STATE_HOME/registry.yml`)
  unioned at read time, collapsing to one file for per-user installs, with best-effort
  writes (skip+warn, never block) and quiet stale-pruning (AC2/AC6, FR4).
  **cwd-driven dispatch** implementing the A/B/C scenario matrix — self-commands
  machine-scoped; `aid add` per the B-table (errors on unwritable folder, asks
  shared-vs-user on global-outside-`~`); repo commands per the C-table; "always ask on a
  real decision" + no-hard-refuse (missing `.aid/` is an offer, git optional) (FR5).
  **`aid update self` migrates exactly the registered repos** (union of both tiers, no
  scan) with per-repo All/Yes/No/Cancel confirmation — replacing the no-op stub left by
  delivery-001 (AC5, FR6).
- **Features:** feature-004 (two-tier registry union + cwd dispatch A/B/C + registry-driven
  `update self` migration).
- **Depends on:** delivery-001 (feature-001 state-home/scope; feature-002 shared tier;
  feature-003 the per-repo stamp that registry migration writes and unregistered repos
  fall back to). PR #78 (the channel-aware `update self` mechanics that this delivery's registry migration step is layered on top of).
- **Priority:** High. REQUIREMENTS §10 Priority 2 (FR4/FR5/FR6; AC2/AC5/AC6).
- **Standalone-functional:** On top of delivery-001's working CLI, this adds the complete
  index/dispatch/batch-migration layer and replaces the update-self no-op with the real
  registry-driven migration — every command still operates without the registry (it is a
  rebuildable index), so the delivery is independently usable and degrades safely.
- **Testing — suite stays green at this delivery boundary:** d002 carries the canonical
  test changes for what feature-004 introduces/changes, so `tests/run-all.sh` stays green
  HOME-pinned at the d002 exit. Concretely: the two-tier registry union assertions
  (`test-registry.sh` — user-tier-only collapse for non-global, union read where a global
  install is simulated, best-effort skip+warn writes, stale-prune), the cwd-dispatch A/B/C
  matrix assertions, and the `update self` registry-driven migration replacing the
  delivery-001 no-op stub (per-repo All/Yes/No/Cancel, union-not-scan). HOME-pin + escape
  canary retained on every migration/encounter test.

### delivery-003: Rollout — v1.0/v1.1 bootstrap and final test-suite reconciliation

- **What it delivers:** Brings existing repos onto the new model and closes out the suite.
  **Bootstrap** (no scan): visiting or `aid update`-ing each known repo stamps
  `format_version: 1` and registers it in the appropriate tier — covering the maintainer's
  `~/projects/*` and `/srv/projects/*` dogfood repos and external upgraders (AC9, FR9).
  **Final test-suite reconciliation**: the per-delivery breaking-test migration was pulled
  forward into d001/d002 (each delivery migrated the suites it broke so the suite stayed
  green at every boundary). d003 adds the **bootstrap tests** (stamp+register on encounter,
  no scan; HOME-pin + escape canary) and runs the **final full-suite reconciliation green
  sweep** — a whole-of-`tests/run-all.sh` audit confirming the CODE/STATE split is
  consistently re-anchored across all suites and no stray `$AID_HOME/lib`,
  `$AID_HOME/VERSION`, or `.migrated` reference survives end-to-end (AC4/AC8; NFR
  test-suite compatibility).
- **Features:** feature-005 (bootstrap: stamp+register on visit, no scan; + the final
  canonical test-suite reconciliation sweep — its per-delivery breaking-test migration is
  distributed into d001/d002 per the Execution Graph).
- **Depends on:** delivery-001 (feature-001 home split tests assert against; feature-003
  the stamp written during bootstrap) and delivery-002 (feature-004 registration target —
  user vs shared tier). It is the integration/rollout step over all prior features.
- **Priority:** Medium. REQUIREMENTS §10 Priority 3 (FR9 + test-suite migration).
- **Standalone-functional:** Carries no new production code — it is a procedure (bootstrap)
  + a final test reconciliation that exercises behavior already shipped in deliveries
  001/002. It closes out the rollout: existing repos converge per-repo and the canonical
  suite is green against the new model, completing the dogfood resolution.
- **Testing — suite stays green at this delivery boundary:** the suite was already green at
  the d001 and d002 boundaries (breaking-test migration was carried per-delivery). d003 adds
  the bootstrap assertions and the final full-suite reconciliation green sweep
  (`tests/run-all.sh` HOME-pinned, escape canary intact), confirming nothing drifted across
  the three deliveries.

## Execution Graph

```
PR #78 (prerequisite — merged to master FIRST)
        |
        v
+--------------------------------------------------------------+
| delivery-001  (root-cause fix; standalone MVP)               |
|                                                              |
|   feature-001  (foundation: scope + CODE/STATE split;        |
|                 removes marker/scan/sentinel; stubs          |
|                 update-self scan-caller -> no-op; owns       |
|                 AID_SHARED_STATE_HOME seam)                  |
|       |                  \                                    |
|       |                   \                                   |
|       v                    v                                 |
|   feature-002          feature-003                           |
|   (provision           (stamp gate = the REPLACEMENT         |
|    /var/lib/aid;        trigger; wires into the SAME          |
|    runtime fallback)    call sites 001 vacated)              |
|                                                              |
|   Order:  001 first (foundation + removal).                  |
|           Then 002 and 003 in PARALLEL — disjoint regions:   |
|             - 002 touches lib/aid-install-core.sh +          |
|               installers + registry-write fallback.          |
|             - 003 touches the stamp helper + the gate        |
|               call sites (1918/1978) + settings template.    |
|           003 MUST land in this delivery (not later) so the  |
|           removed trigger has its replacement before exit.   |
|   Test:   d001 migrates the suites 001/002/003 break         |
|           (fixture split, retired marker/scan/sentinel,      |
|           stamp+gate + provisioning asserts) -> green here.  |
+--------------------------------------------------------------+
        |
        v
+--------------------------------------------------------------+
| delivery-002  (coherent discovery; standalone MVP)           |
|                                                              |
|   feature-004  (registry union + cwd A/B/C dispatch +        |
|                 update-self registry-migration; replaces     |
|                 the delivery-001 no-op stub)                 |
|       - depends on 001 (state-home/scope),                   |
|         002 (shared tier), 003 (stamp written by migration). |
|       - single feature -> no intra-delivery parallelism.     |
|   Test:   d002 migrates the registry/dispatch suites it      |
|           changes (test-registry.sh union, A/B/C matrix,     |
|           update-self registry migration) -> green here.     |
+--------------------------------------------------------------+
        |
        v
+--------------------------------------------------------------+
| delivery-003  (rollout; standalone MVP)                      |
|                                                              |
|   feature-005  (bootstrap stamp+register on visit, no scan;  |
|                 final test-suite reconciliation sweep)       |
|       - depends on 001 (home split), 003 (stamp),            |
|         004 (registration target).                           |
|       - two coupled work-streams that CAN run in parallel:   |
|           (i) bootstrap procedure + new bootstrap tests,     |
|           (ii) final full-suite reconciliation green sweep   |
|               (breaking-test migration already done in       |
|               d001/d002; bash+ps1 in lockstep).              |
+--------------------------------------------------------------+
```

**Inter-delivery order (strict):** delivery-001 → delivery-002 → delivery-003. No
inter-delivery parallelism — each delivery's standalone-functional guarantee depends on
the prior delivery's exit state (001 fixes the bug and re-arms migration; 002 adds the
registry the update-self migration and bootstrap registration target; 003 rolls out + the
test migration asserts against all three).

**Intra-delivery parallelism:**
- **delivery-001:** feature-001 first (foundation: the home split + the marker/scan
  removal). Then **feature-002 ∥ feature-003** in parallel — they touch disjoint surfaces
  (002 = installers + `lib/aid-install-core.sh` + the registry-write runtime fallback; 003 =
  the stamp helper + the format-gate call sites + the settings template). Both consume
  feature-001's `AID_STATE_HOME`/scope as a GIVEN.
  **Shared-file staging coordination (002 ∥ 003):** the two features author disjoint
  *regions* of the **same files** `bin/aid` + `bin/aid.ps1` (002 the `registry_register`/
  `registry_unregister` hunks ~`:1202-1273`; 003 the `AID_SUPPORTED_FORMAT` constant ~`:47`,
  the synthesizers `:1276-1670`, and the gate wiring `:1918`/`:1978`). Parallel authoring is
  safe, but git staging must be coordinated per the shared-checkout hazard: each feature
  stages **only its own hunks** (`git add -p`, never `git add <file>` wholesale) and pushes
  via an explicit `HEAD:branch` refspec so neither agent commits the other's in-flight edits.
- **Test migration is per-delivery:** d001 and d002 each migrate the canonical suites that
  their features break, so `tests/run-all.sh` stays green HOME-pinned at every delivery
  boundary; feature-005/d003 carries only the bootstrap tests + the final reconciliation
  sweep (see each delivery's "Testing — suite stays green" note).
- **delivery-002:** single feature (feature-004) — no intra-delivery parallelism; internally
  the union-read, write-tier selection, dispatch classifier, and update-self migration swap
  are sequential edits to `bin/aid`/`bin/aid.ps1`.
- **delivery-003:** single feature (feature-005) with two parallelizable work-streams —
  (i) the bootstrap procedure + new bootstrap assertions, (ii) the final full-suite
  reconciliation green sweep (the breaking-test migration of categories C1–C5 was pulled
  forward into d001/d002; d003 confirms whole-suite consistency, bash + ps1 in lockstep).

## Prerequisites

- **PR #78** (`_aid_priv_run` writability-probe / elevation helper + channel-aware
  `update self` / `remove self`, `--from-bundle`, `--dry-run`) — **HARD prerequisite for
  the whole work; gated to merge to master FIRST** (REQUIREMENTS §8, decided 2026-06-15).
  Every delivery treats `_aid_priv_run` (and the channel-aware self-commands) as a GIVEN:
  feature-001 reuses the writability probe for scope detection; feature-002 routes shared
  provisioning/writes through it; feature-004 adds the registry-migration step on top of the
  channel-aware `update self`. **PR #78 is not a deliverable** — it is the foundation this
  work builds on, and no delivery here re-specifies its self-update mechanics.
  Line cites in the SPECs anchored pre-#78 will shift after the merge (re-anchor by symbol
  name, not line — feature-001 SPEC dependency note).
