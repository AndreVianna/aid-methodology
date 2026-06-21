# Plan -- Profile Generator Simplification

## Deliverables

### delivery-001: Format Decision + Symmetric Copy Generator
- **What it delivers:** The radically simpler copy-based generator (13→4 scripts, ~7,000→~900–1,300 LOC) on the symmetric per-tool layout, resting on the evidence-based FR4 format decision (uniform markdown, verify-first). The repo renders the new `profiles/*` trees + dogfood `.claude/`, drift-clean, with a new §7a byte-identity guard.
- **Features:** feature-001-behavioral-parity-format, feature-002-symmetric-copy-generator
- **Depends on:** --
- **Priority:** Must
- **Standalone:** Internally complete (working generator + drift-clean trees + guard). The AC4b gate (study produced before any branch deleted) is preserved as an intra-delivery task ordering. AC4a's 3-tool *behavioral* check is verified in **delivery-003's AC4** gate (it needs all trees + install). NOT released alone — see the Release-Safety Gate.

### delivery-002: Atomic aid update + Complete-Replacement Migration
- **What it delivers:** One `aid update` keeping all installed tools at one version (no per-tool selection); old-layout installs (`.agents/`, `.cursor/rules/`, `.agent/rules/`) migrate by complete replacement (marker-prune + retired-root sweep) with user content untouched; bash + PowerShell parity. This is the delivery that makes the new layout safe to ship.
- **Features:** feature-003-atomic-aid-update
- **Depends on:** delivery-001
- **Priority:** Must

### delivery-003: Lockstep Dependents + Final Acceptance Gate
- **What it delivers:** Every shipped artifact (`release.sh` codex roots, `docs/*` + synced `site/*`, KB incl. content-isolation R6 revision + capability-study promotion, profile READMEs) brought into lockstep with the new layout; the final AC3 all-green CI + AC4 multi-tool no-contamination acceptance; lands via PR to PR-protected master.
- **Features:** feature-004-lockstep-ci-closeout
- **Depends on:** delivery-001, delivery-002
- **Priority:** Must

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | **Release-safety window:** new-layout trees (delivery-001) without new-layout-aware install (delivery-002) = broken installs; `release.sh` codex roots not fixed until delivery-003 | H | **Release-Safety Gate** (below): features may land as separate PRs, but NO `aid-deploy`/release until all three deliveries have merged. |
| 2 | E-CODEX-1 may not resolve `high` during delivery-001 → Codex TOML branch ships dormant | M | Designed-for (verify-first): TOML branch kept dormant + tracked follow-up deletes it once E-CODEX-1 is `high`. Contingency, not a blocker — delivery-001 stays mergeable. |
| 3 | 002→003 manifest contract: if delivery-001's emitted bundle path-set leaks retired paths, delivery-002's prune targets the wrong set | M | The manifest is the seam; verify delivery-001's "new manifest omits retired paths" before delivery-002 builds its prune (`release.sh` "expected install root not found" guard self-checks once delivery-003 lands). |
| 4 | `docs.yml` Astro build + kb-hygiene INDEX-fresh are NOT PR gates (post-merge only) | L | delivery-003 gate (AC3) runs the docs build + INDEX-fresh checks locally before the PR. |

## Release-Safety Gate (binds the whole set)

> No `aid-deploy` / release (any channel) may run until **delivery-001, delivery-002, AND delivery-003 have all merged to master.** Individual deliveries may merge as separate PRs (**master-merge ≠ release** in this repo — the release is a separate, deliberate `aid-deploy` act). The new layout is release-safe only once the generator (001), the install/migration (002), and the `release.sh`/docs lockstep (003) are all in. This guards against shipping new-layout bundles to an old-layout install path — and npm/PyPI versions are irreversible.

## Execution Graphs

### delivery-001 execution graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-002 |
| task-004 | task-002 |
| task-005 | task-002, task-003, task-004 |
| task-006 | task-005 |
| task-007 | task-005, task-006 |
| task-008 | task-006, task-007 |

| Can Be Done In Parallel |
|------------------------|
| task-003, task-004 |

```wave-map
delivery: 001
wave 1: task-001
wave 2: task-002
wave 3: task-003, task-004
wave 4: task-005
wave 5: task-006
wave 6: task-007
wave 7: task-008
```

### delivery-002 execution graph

| Task | Depends On |
|------|-----------|
| task-009 | — (delivery-001) |
| task-010 | task-009 |
| task-011 | — (delivery-001 manifest seam) |
| task-012 | task-010, task-011 |
| task-013 | task-012 |

| Can Be Done In Parallel |
|------------------------|
| task-009, task-011 |

```wave-map
delivery: 002
wave 1: task-009, task-011
wave 2: task-010
wave 3: task-012
wave 4: task-013
```

### delivery-003 execution graph

| Task | Depends On |
|------|-----------|
| task-014 | — |
| task-015 | — |
| task-016 | — |
| task-017 | — |
| task-018 | task-016, task-017 |
| task-019 | task-016, task-017, task-018 |
| task-020 | task-014 |

| Can Be Done In Parallel |
|------------------------|
| task-014, task-015, task-016, task-017 |
| task-018, task-020 |

```wave-map
delivery: 003
wave 1: task-014, task-015, task-016, task-017
wave 2: task-018, task-020
wave 3: task-019
```
