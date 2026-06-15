# Requirements

- **Name:** CLI install-scope, repo discovery, and migration model
- **Description:** Rework how the `aid` CLI determines install scope, discovers AID repos, stores its state, and migrates repos on upgrade — fixing the root cause of the v1.0→v1.1 dogfood failure and replacing ad-hoc behavior with a coherent, prior-art-grounded model.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-15 | Initial requirements seeded from approved design note | /aid-interview |
| 2026-06-15 | Review fixes: added AC9/AC10 (FR9/FR10 coverage), pinned format_version=1, corrected PR #78 readiness wording + design-note §3.5 ref, added concurrency non-goal | /aid-interview review |
| 2026-06-15 | Interview complete — approved (A+); PR #78 gated-first decision recorded | /aid-interview |

## 1. Objective

Give the `aid` CLI a coherent, durable model for **install scope** (global vs per-user), **repo discovery** (cwd-driven, no machine scan), **state storage** (decoupled from the code payload), and **upgrade migration** (per-repo, fail-safe). The model must make `aid update self` / `aid remove self` and routine repo commands behave correctly under both root-owned global installs and unprivileged per-user installs, on every channel (npm / pypi / curl), without losing or corrupting repo data.

Source of truth: `.aid/design/cli-install-scope-and-migration.md` (settled 2026-06-15, decisions A–F).

## 2. Problem Statement

A real-machine dogfood (v1.0.0 npm-global → v1.1.0) exposed that the shipped CLI conflates the **code payload** and **mutable state** under a single self-located `$AID_HOME`. For a root-owned npm-global install that resolves to `/usr/lib/node_modules/aid-installer`:

- Migration tried to write per-machine state (`.migrated`, `registry.yml`) into that root-owned dir → **permission denied** for unprivileged `aid`.
- Running `sudo aid` scanned the wrong `$HOME` and still missed repos under `/srv/projects` (group `developers`) — the migration scan only walked `$HOME`.
- Because the `.migrated` marker could not persist, `aid` **re-prompts migration on every run**.

The behavior was never designed as a whole — scope, discovery, state location, and migration each made independent, conflicting assumptions.

## 3. Users & Stakeholders

- **End users running `aid`** — on per-user installs (pipx / npm user-prefix / curl `~/.aid`) and root-owned global installs (npm `-g`). Must not be forced into `sudo` for read-only commands.
- **Multi-developer machines** — e.g. shared repos under `/srv/projects` owned by group `developers`; need a shared repo index without per-command elevation friction.
- **AID maintainers** — must keep the canonical test suite green and the five install manifests (npm/pypi/curl + bash/ps1) lockstep.
- **Upgraders from v1.0/v1.1** — must migrate cleanly without a machine-wide scan.

## 4. Scope

### In Scope

- Runtime install-scope detection (global vs per-user).
- Decoupling CODE (`AID_CODE_HOME`) from STATE (`AID_STATE_HOME`) in `bin/aid` and `bin/aid.ps1`.
- Per-repo format stamp (`format_version` in `.aid/settings.yml`) with fail-safe comparison.
- Two-tier registry (user `~/.aid/registry.yml` + shared `$AID_STATE_HOME/registry.yml`), unioned, incremental, best-effort.
- cwd-driven dispatch rules (no machine scan) for self-commands, `aid add`, and repo commands (the A/B/C scenario matrix).
- Migration: lazy per-repo (stamp-driven) + batch over registered repos in `update self`.
- Global shared-state provisioning (`/var/lib/aid`) by the installers.
- Retirement of the `$AID_HOME/.migrated` machine marker and the `$HOME`-walking scan.
- Moving `.update-check` to a per-user cache (`~/.aid`).
- v1.0→v1.1 bootstrap (manual, per-repo, no scan) and migration of existing tests to the new home split.

### Out of Scope

- Machine-wide filesystem scan; any `aid` daemon/service.
- Heavy multi-user concurrency control on the shared registry beyond atomic set-insert / prune.
- Group-writable (setgid) shared-state home — deferred as a future installer knob; `/var/lib/aid` root-owned is the chosen default.
- `extensions:`-style partial-compat machinery for `format_version` (key reserved, unused).
- The channel-aware `update self` / `remove self` *self-update mechanics* themselves (design note §3.5) — implemented in PR #78 (**open, not yet merged to master**); this work **consumes** them (and depends on `_aid_priv_run` from that PR, see §8) and adds the registry-migration step on top.
- Concurrency control for racing privileged writers on the shared `/var/lib/aid/registry.yml` — a non-goal beyond atomic set-insert / prune; two simultaneous `aid add` calls are not coordinated.

## 5. Functional Requirements

- **FR1 — Runtime scope detection.** `aid` determines scope as **global iff its payload root (where `bin/aid` resolves) is not writable by the current user**, else **per-user**. No install-time scope marker is written. `AID_INSTALL_CHANNEL` remains a self-update routing hint only.
- **FR2 — CODE/STATE decoupling.** Resolve two homes: `AID_CODE_HOME` (self-located, read-only — locates `lib/`, `dashboard/` source, `VERSION`) and `AID_STATE_HOME` (mutable state only). `AID_STATE_HOME` defaults to `~/.aid` (per-user) or `/var/lib/aid` (global), and is overridable by the `AID_HOME` env var (which now overrides STATE only, never code). Repoint every state/code reference accordingly in both `bin/aid` and `bin/aid.ps1`.
- **FR3 — Per-repo format stamp.** Each repo records `format_version: <int>` in `.aid/settings.yml`, decoupled from CLI semver. The current `.aid/` layout is **`format_version: 1`**; the CLI ships `AID_SUPPORTED_FORMAT = 1`. A legacy/unstamped repo is treated as format `0` (needs migration to `1`). Fail-safe: repo stamp **>** supported → refuse to operate; repo stamp **<** supported or absent → needs migration (warn + offer `aid update`). This replaces era-by-file-presence detection.
- **FR4 — Two-tier registry.** A user registry (`~/.aid/registry.yml`, always writable) and, for global installs, a shared registry (`$AID_STATE_HOME/registry.yml`, privileged-written, world-readable). The CLI unions both at read time; for per-user installs the two collapse to one file. The registry is a rebuildable index for the dashboard — never required for a single-repo operation. Writes are best-effort (decline / no-TTY / no-elevation → skip + warn, still operate); stale entries pruned quietly on read.
- **FR5 — cwd-driven dispatch (no scan).** `aid <cmd>` acts on the current directory's repo; repos are learned incrementally on encounter. Only `update self` / `remove self` are machine-scoped. Implement the A/B/C dispatch matrix from the design note (self-commands; `aid add`; repo commands), including the "always ask on a real decision" rule and the no-hard-refuse rule (git not required; missing `.aid/` is an offer, not an error).
- **FR6 — Migration over the registry.** `aid update self` migrates the **registered** repos (union of user + shared registries — no scan), each with the per-repo confirmation (All / Yes / No / Cancel). Unregistered repos are caught lazily by FR3.
- **FR7 — Global state provisioning.** A global install creates `/var/lib/aid` (root-owned, world-readable) and writes the shared `registry.yml` there; shared writes go through the elevation helper (best-effort). Per-user installs collapse shared==user==`~/.aid`.
- **FR8 — Retire the machine marker + scan.** Remove `_aid_check_migrate_sentinel`, the `$AID_HOME/.migrated` marker, and the `$HOME`-walking `_aid_scan_for_repos`. Migration becomes lazy per-repo (FR3) plus batch-over-registry (FR6). A repo's migration-done state lives only in its own user-writable `.aid/settings.yml`.
- **FR9 — Bootstrap (v1.0/v1.1 → new model).** No scan. Visiting or `aid update`-ing each known repo stamps `format_version: 1` and registers it (in the user or shared registry per scope). The lazy per-repo stamp carries forward thereafter.
- **FR10 — Per-user update-check cache.** `.update-check` is advisory per-user cache → always `~/.aid/.update-check`, regardless of scope (never requires elevation).

## 6. Non-Functional Requirements

- **Parity:** `bin/aid` (bash) and `bin/aid.ps1` (PowerShell) must remain behaviorally equivalent (Windows has no `sudo`; scope detection still applies).
- **ASCII-only:** all shipped scripts (`bin/aid`, `bin/aid.ps1`, `install.*`, `packages/*`, `lib/*`) remain ASCII-only (CI-enforced).
- **No data loss:** fail-safe is mandatory — never operate on a newer-format repo; never silently corrupt `.aid/`.
- **Least privilege:** read-only commands never force a `sudo` prompt merely to index; elevation only for the genuinely privileged step.
- **Test-suite compatibility:** the canonical suite (`tests/run-all.sh`, HOME-pinned) must stay green; `AID_HOME`-pinning semantics (state redirection) preserved.
- **Backward compatibility:** an in-flight upgrade from v1.0/v1.1 must not strand a user (no hard failure on a missing stamp or missing shared home).

## 7. Constraints

- `master` is PR-protected; all changes land via PR reviewed/merged by the human maintainer (agent is the non-admin bot).
- Heavy CI gates (canonical suites, Astro docs build) run only on master — must validate locally (HOME-pinned `tests/run-all.sh`) before claiming green.
- Migration/scan-touching tests must pin `HOME` to a throwaway dir (real-repo safety).
- The five install manifests (npm/pypi/curl + bash/ps1) must stay lockstep on the file set.
- Dashboard must never be exposed publicly (tailnet-only).

## 8. Assumptions & Dependencies

- PR #78 (channel-aware `update self` / `remove self`, `--from-bundle`, `--dry-run`, `_aid_priv_run`) is the foundation this builds on; its `_aid_priv_run` writability-probe is reused for scope detection and shared-registry writes. **Decided 2026-06-15:** this work is gated on PR #78 merging to master first — decomposition treats `_aid_priv_run` and the channel-aware self-commands as a given (not in-scope deliverables).
- The design note `.aid/design/cli-install-scope-and-migration.md` is settled and is the authoritative source for the model.
- `/var/lib/aid` is creatable at global install time (installer runs privileged for a global install).
- Existing repos carry a recognizable legacy shape (era-a `settings.yml` / era-b `knowledge/*STATE.md`) for the one-time stamp-on-first-touch.

## 9. Acceptance Criteria

- **AC1.** On a root-owned npm-global install, an unprivileged `aid status` in a registered repo operates without any permission-denied error and without re-prompting migration on every run.
- **AC2.** `aid` never performs a machine-wide filesystem scan; repo discovery is cwd-driven and registry-driven only.
- **AC3.** A repo with `format_version` greater than `AID_SUPPORTED_FORMAT` causes `aid` to refuse operation with a clear message (fail-safe); a repo with an older/absent stamp triggers a migration offer, not a silent change.
- **AC4.** `AID_CODE_HOME` and `AID_STATE_HOME` resolve independently; setting `AID_HOME` redirects state only, and the canonical test suite passes HOME-pinned.
- **AC5.** `aid update self` migrates exactly the registered repos (union of both tiers) with per-repo confirmation, and performs no scan.
- **AC6.** Per-user and global installs both resolve the correct state home (`~/.aid` vs `/var/lib/aid`); shared-registry writes elevate only when needed and degrade to skip+warn when elevation is unavailable.
- **AC7.** The `.migrated` machine marker and `$HOME`-walking scan are removed from the codebase; no code path reintroduces a machine-level migration marker.
- **AC8.** `bin/aid` and `bin/aid.ps1` remain at parity and ASCII-only; CI (canonical suites) is green.
- **AC9.** Bootstrap (FR9): visiting or `aid update`-ing a v1.0/v1.1 repo that carries no `format_version` writes `format_version: 1` into its `.aid/settings.yml` and adds the repo to the appropriate registry (user or shared), with **no** machine-wide filesystem scan performed.
- **AC10.** Update-check cache (FR10): `.update-check` resolves to `~/.aid/.update-check` on **both** per-user and root-owned global installs, and refreshing it never triggers an elevation / `sudo` prompt.

## 10. Priority

1. **Highest (root-cause bug fix):** FR1, FR2, FR7, FR8, FR10 + AC1/AC4/AC7 — eliminate the permission-denied / re-prompt loop on global installs.
2. **High (the coherent model):** FR3, FR4, FR5, FR6 + AC2/AC3/AC5/AC6 — per-repo stamp, two-tier registry, cwd dispatch, registry migration.
3. **Medium (rollout):** FR9 bootstrap + test-suite migration.
