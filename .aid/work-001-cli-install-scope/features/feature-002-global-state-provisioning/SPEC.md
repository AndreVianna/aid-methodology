# Global Shared-State Provisioning (/var/lib/aid)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-15 | Feature identified from REQUIREMENTS.md §5 (FR7), §4, §9 (AC6), §10 (Priority 1) | /aid-interview |
| 2026-06-15 | Technical Specification authored | /aid-specify |
| 2026-06-15 | Spec fixes (review cycle 1): _aid_priv_run convention, real provisioning hook, removed fabricated verb | /aid-specify |

## Source

- REQUIREMENTS.md §5 (FR7 Global state provisioning)
- REQUIREMENTS.md §4 Scope (in-scope: global shared-state provisioning `/var/lib/aid` by the installers)
- REQUIREMENTS.md §9 (AC6)
- REQUIREMENTS.md §10 Priority 1 (root-cause bug fix)
- Design note §3.2 (global state default `/var/lib/aid`), §3.3 (shared registry tier), §6 (global state provisioning touch points)

## Description

A global (machine-wide, root-owned) install needs a writable, machine-shared
place to keep its state that is not the read-only code payload. This feature has
the installers provision that location: at global install time they create
`/var/lib/aid` (root-owned, world-readable, following the FHS variable-state
convention and the mlocate "privileged process writes, everyone reads" model) and
seed the shared `registry.yml` there. Shared-state writes go through the elevation
helper on a best-effort basis. For a per-user install there is no separate shared
tier — the shared home collapses to the user home `~/.aid`. This work lives in the
installer/core layer (`lib/aid-install-core.sh` and the npm/pypi/curl installers)
and must keep the five install manifests lockstep.

## User Stories

- As a **multi-developer machine administrator**, I want a global install to
  create a root-owned, world-readable `/var/lib/aid`, so the machine has a shared
  repo index that all users can read without per-command elevation.
- As an **end user on a global install**, I want shared-state writes to elevate
  only when genuinely needed and to degrade gracefully (skip + warn) when
  elevation is unavailable, so indexing never blocks my command.
- As an **end user on a per-user install**, I want the shared and user homes to
  collapse to one `~/.aid`, so there is no spurious privileged path.

## Priority

Must (Priority 1 — root-cause bug fix)

## Acceptance Criteria

- [ ] Given a global install runs (privileged), when installation completes, then
  `/var/lib/aid` exists, is root-owned and world-readable, and contains the seeded
  shared `registry.yml` (FR7).
- [ ] Given a per-user install, when installation completes, then no separate
  shared tier is provisioned — shared, user, and `AID_STATE_HOME` all resolve to
  `~/.aid` (FR7, AC6 partial).
- [ ] Given a global install, when a shared-registry write is needed, then it goes
  through the elevation helper and elevates only when the location is not writable;
  if elevation is unavailable it degrades to skip + warn while still operating (AC6).
- [ ] Given per-user and global installs, when the CLI resolves the state home,
  then it correctly resolves `~/.aid` vs `/var/lib/aid` respectively (AC6).
- [ ] Given all five install manifests (npm/pypi/curl + bash/ps1), when the
  provisioning changes land, then they remain lockstep on the provisioning
  behavior and the file set, and shipped scripts remain ASCII-only (AC8; constraints §7).

> **Cross-cutting NFRs (apply to all ACs):** bash/ps1 parity (Windows path/
> elevation differs — no `sudo`; scope detection still applies), ASCII-only
> shipped scripts (CI-enforced), least-privilege (best-effort elevation only for
> the genuinely privileged write), no data loss.
>
> **Dependencies:** the state-home resolution from feature-001 (`AID_STATE_HOME`
> defaulting to `/var/lib/aid` for global scope); the `_aid_priv_run` elevation
> helper from PR #78 (gated to master first). Out of scope: setgid/group-writable
> shared home (deferred future installer knob).

---

## Technical Specification

### Scope of this feature

This feature is the **runtime shared-state provisioning slice** of the global
state home. It does **not** re-specify scope detection or the `AID_CODE_HOME` /
`AID_STATE_HOME` resolution — those are feature-001 and are treated as GIVEN
here, as is the `_aid_priv_run` elevation helper (PR #78, gated to master first).
This feature owns three concrete behaviors:

1. **Lazy creation** of `/var/lib/aid` (root-owned, world-readable) on the
   **first shared-state write** of a global install — seeding an empty shared
   `registry.yml` there — because there is no reachable install-time hook today
   (see Approach › "Why provisioning is RUNTIME"). Install-time seeding is
   deferred to feature-003 (installer-scope rework).
2. The runtime **shared-registry write path** that elevates only when the target
   is not user-writable, degrading to skip+warn (best-effort) per AC6.
3. The **per-user collapse** so a non-global install never produces a `/var/lib/aid`
   path: shared == user == `AID_STATE_HOME` == `~/.aid`.

> **Dependency naming convention used below.** `AID_STATE_HOME` is the
> feature-001 state-home resolution (`${AID_HOME:-<scope-default>}`, where the
> scope default is `~/.aid` per-user and `/var/lib/aid` global).
>
> `_aid_priv_run <writability-probe-dir> <cmd...>` is the PR #78 best-effort
> elevation helper (`bin/aid:312-340` on branch `aid/self-contained-update-remove`).
> **Its first argument is a probe directory, not the command.** Exact contract,
> read from the helper body:
>
> 1. It elevates iff the probe dir is non-empty **and** exists **and** is **not
>    writable** by the current user **and** the current uid is not 0
>    (`[[ -n "$probe" && -e "$probe" && ! -w "$probe" && "$(id -u)" -ne 0 ]]`).
> 2. When elevation is needed and `sudo` is on `PATH`, it prints
>    `aid: <probe> is not writable -- elevating this step via sudo...` and runs
>    `sudo "$@"`, returning sudo's exit code. **`sudo` DOES prompt interactively
>    for a password** — there is **no TTY guard** and no "never prompts" behavior.
> 3. When elevation is needed but `sudo` is **absent**, it prints an
>    `ERROR: ... not writable and sudo is unavailable` line and returns **13**.
> 4. Otherwise (probe writable, empty `""`, missing, or uid 0) it runs `"$@"`
>    directly with no elevation. Passing an **empty probe (`""`) forces the
>    direct, never-elevate path** — this is how the feature suppresses elevation
>    when it must not prompt.
> 5. Honors `_SELF_DRYRUN=1` (prints the resolved command, prefixed `sudo` when
>    it would elevate, and does nothing).
>
> This feature consumes both `AID_STATE_HOME` and `_aid_priv_run` verbatim and
> defines no new resolution or elevation logic.

### Approach

#### Why provisioning is RUNTIME (lazy), not install-time

The earlier draft anchored provisioning on `_install_global_cli` and an
install.sh `/var/lib` branch. A current-state audit shows **neither is a
reachable hook**:

- `_install_global_cli` (`bin/aid:539-561`) is **defined but never called**
  anywhere in the repo (`grep -rn _install_global_cli bin/ install.sh lib/
  packages/` finds only the definition + one test-allowlist string). It also
  installs to `aid_home="${AID_HOME:-${HOME}/.aid}"` — **never** `/var/lib` — so
  even if it fired it could not provision the shared tier.
- `install.sh` always installs to `$HOME/.aid` (the three `AID_HOME="${AID_HOME:-${HOME}/.aid}"`
  sites at `install.sh:577,669,936`) and contains **no root/uid detection and no
  `/var/lib` branch** (`grep -n 'id -u\|EUID\|/var/' install.sh` is empty). A
  root `curl|bash` lands in `/root/.aid`, whose payload root *is* root-writable,
  so feature-001 derives **per-user** scope and a "global path" install hook
  would never fire.
- `packages/npm/scripts/postinstall.js` has **no `getuid`/root branch** today; it
  only prints a notice or spawns `aid update self`. `pypi` has no JS postinstall
  at all.

So there is **no existing, reachable install-time site that runs `/var/lib`-eligible
and root** across the npm/pypi/curl channels. Rather than fabricate one in three
manifests, this feature provisions **lazily at runtime, on the first shared-state
write** — which is a real, single code site (the registry writers) that
feature-001 already touches, and which is the exact moment the privileged
location is genuinely needed (the mlocate "privileged process writes" model,
design §3.3). This also matches feature-001's runtime-derived-scope model
(scope = payload-root writability, decided per invocation, never recorded).

**Recommendation (and the one genuine design choice — see Open decision below):
runtime/lazy provisioning is the primary mechanism.** Install-time seeding is
deferred to feature-003 (the installer-scope rework) where a real root-detecting
install path is built; it is **not** specified here against dead code.

#### The provisioning helper

A new helper `_provision_shared_state_home <shared-home>` is added to
`lib/aid-install-core.sh` (the file the curl bootstrap dot-sources at
`install.sh:526` and copies to `${AID_HOME}/lib/aid-install-core.sh` at
`install.sh:779`; the npm/pypi payloads vendor the same file, so the helper is
available to `bin/aid` at runtime via the existing lib-sourcing path). Because
provisioning is runtime-driven, **`bin/aid` calls this helper from the registry
write path** (below), not from any installer.

The helper, given the resolved shared home `SH` (`/var/lib/aid` on a global
install):

1. If `"$SH"` does not exist, create it via the elevation helper, **probing the
   parent**: `_aid_priv_run "$(dirname "$SH")" mkdir -p "$SH"` then
   `_aid_priv_run "$SH" chmod 0755 "$SH"`. Probing `dirname "$SH"` (`/var/lib`)
   is correct: if `/var/lib` is not user-writable the helper elevates the
   `mkdir`; if `$SH` itself does not yet exist it cannot be the probe. Result is
   root-owned (created under sudo), world-readable + world-traversable,
   owner-writable only — the mlocate model (design §2/§3.2).
2. If `"$SH/registry.yml"` does **not** already exist, seed an **empty** registry
   using the exact current schema (`bin/aid:1216-1223`): the three comment lines,
   `schema: 1`, and `repos:` with **no items**. Write to a temp file, then
   `_aid_priv_run "$SH" mv -f "$tmp" "$SH/registry.yml"` (elevates iff `$SH` is
   not user-writable), then `_aid_priv_run "$SH" chmod 0644 "$SH/registry.yml"`.
   Never clobber an existing `registry.yml` (idempotent / upgrade safe).
3. Best-effort throughout: if any `_aid_priv_run` step declines (returns 13 / no
   sudo) or fails (read-only `/var`, container), the helper returns non-zero; the
   caller degrades to the **user** tier `~/.aid` + one `WARN:` line and **never
   hard-fails** the user's command (see Edge cases, AC6).

**Per-user install: no `/var/lib/aid`.** When feature-001 resolves per-user
scope, `AID_STATE_HOME == ~/.aid`, so the registry write path targets a
user-writable home and **never calls `_provision_shared_state_home`** — there is
nothing to provision. The existing `registry_register` `mkdir -p "$AID_STATE_HOME"`
(`bin/aid:1204`, the `mkdir -p "$AID_HOME"` line after the feature-001 rename)
creates `~/.aid` lazily on first write. Shared, user, and `AID_STATE_HOME` are
the same directory; there is no second tier and no privileged path.

### On-disk layout

| Scope | `AID_STATE_HOME` | Shared registry | User registry | Owner / perms (shared) |
|---|---|---|---|---|
| global | `/var/lib/aid` | `/var/lib/aid/registry.yml` | `~/.aid/registry.yml` | root:root, dir `0755`, file `0644` |
| per-user | `~/.aid` | (collapses → user) | `~/.aid/registry.yml` | user-owned, default umask |

Both tiers use the **identical** `registry.yml` schema (`schema: 1`, `repos:`
list of canonical paths). Seeded shared file at provision time:

```
# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).
# Holds ONLY the base folders of repos this CLI install manages. Per-repo name/
# description/version are read from each repo's own .aid/settings.yml at render time.
schema: 1
repos:
```

State-home → registry-path mapping is a pure function of scope, owned by
feature-001's resolution: `<AID_STATE_HOME>/registry.yml` for the shared/sole
registry, and `~/.aid/registry.yml` for the always-user registry. The CLI unions
the two at read time (design §3.3); for per-user they are one file, so the union
is a no-op.

### Affected components

| Component | Channel | Change |
|---|---|---|
| `lib/aid-install-core.sh` | all (vendored) | **New** `_provision_shared_state_home <shared-home>`: create dir + `chmod 0755` and seed empty `registry.yml` (`0644`, atomic, no-clobber), each filesystem mutation routed through `_aid_priv_run`. Best-effort; returns non-zero (does not abort the caller) when elevation declines. |
| `bin/aid` `registry_register` (`bin/aid:1202-1235` after the feature-001 `AID_STATE_HOME` rename) | runtime, all | **Primary hook.** Before writing, if `$reg` lives under a **non-user-writable** shared home and the shared dir is missing, call `_provision_shared_state_home "$AID_STATE_HOME"` (lazy, first-shared-write). Then commit via `_aid_priv_run "$AID_STATE_HOME" mv -f "$tmp" "$reg"` (probes the registry's own dir; elevates iff that dir is not user-writable). Best-effort: provisioning or elevation declines → degrade to `~/.aid` + existing `WARN:` and `return 0`. |
| `bin/aid` `registry_unregister` (`bin/aid:1241-1273` after the rename) | runtime, all | Same atomic-commit change: `_aid_priv_run "$AID_STATE_HOME" mv -f "$tmp" "$reg"`. (No provisioning here — unregister only runs when a registry already exists; `[[ -f "$reg" ]] || return 0` guards it.) |
| `packages/npm/scripts/postinstall.js` | npm | **No change required for provisioning.** Provisioning is runtime/lazy; the postinstall path (notice / `aid update self`) is unchanged. Documented here only to record that the previously-proposed `process.getuid?.()===0` provisioning spawn and the `aid --provision-shared-state` verb are **dropped** (no such verb exists; `grep -rn provision-shared-state` is empty). |
| pypi packaging | pypi | **No change required for provisioning** (same rationale; pypi has no JS postinstall and provisioning rides the runtime registry-write path in the vendored `bin/aid` + `lib/`). |

> **Feature-001 prerequisite (call-out, not owned here).** The registry writers
> today hardcode `reg="${AID_HOME}/registry.yml"` (`bin/aid:1203,1242`) and `bin/aid`
> has zero `AID_STATE_HOME` references (`grep -c AID_STATE_HOME bin/aid` = 0). The
> `AID_HOME → AID_STATE_HOME` repoint and scope-derivation are a **feature-001
> GIVEN** that must land **before** this feature's runtime hook is correct —
> otherwise the wrapper would key off the wrong variable and the shared tier
> would never be selected. This feature does not perform that rename; it consumes
> the resolved `AID_STATE_HOME`.

The privileged-write path for the shared registry is
**`_aid_priv_run "$AID_STATE_HOME" mv -f "$tmp" "$reg"`** — the **first argument
is the writability-probe dir** (the registry's own directory `$AID_STATE_HOME`),
**not** the command. `_aid_priv_run` already encodes the
writable-probe-then-elevate-else-decline contract, so the registry writers gain
shared-tier support without duplicating that logic. Provisioning's dir/file
mutations use the same form: `_aid_priv_run "$(dirname "$SH")" mkdir -p "$SH"`,
`_aid_priv_run "$SH" chmod ...`, `_aid_priv_run "$SH" mv -f ...`.

### Behavior / Flow

**Global first-shared-write provisioning sequence** (runtime, on a global
install; e.g. `aid add` / dashboard auto-register, repo outside `~`):
1. feature-001 resolves scope = global and `AID_STATE_HOME = /var/lib/aid`;
   `reg="$AID_STATE_HOME/registry.yml"`.
2. Idempotent check: `$repo` already present → no-op (`bin/aid:1207`).
3. If the shared dir `$AID_STATE_HOME` does not exist, call
   `_provision_shared_state_home "$AID_STATE_HOME"`:
   `_aid_priv_run "$(dirname "$AID_STATE_HOME")" mkdir -p "$AID_STATE_HOME"`
   (elevates iff `/var/lib` is not user-writable — it normally is not, so this
   runs `sudo mkdir` and **prompts for a password**), then `chmod 0755`, then
   seed empty `registry.yml` `0644` if absent. Idempotent on every later write.
4. `mktemp` next to `reg`; write the merged, deduped, sorted list (unchanged
   logic, `bin/aid:1216-1223`).
5. Commit: `_aid_priv_run "$AID_STATE_HOME" mv -f "$tmp" "$reg"` — first arg is
   the **probe dir** (the registry's directory). If that dir is user-writable
   (e.g. already running as root, or a group-writable future knob) the helper
   runs `mv` directly; otherwise it prints `aid: <dir> is not writable --
   elevating this step via sudo...` and runs `sudo mv` (which **prompts**).
6. **Degrade:** if `_aid_priv_run` returns non-zero — `sudo` absent (return 13),
   the user fails/cancels the sudo prompt, or provisioning could not create the
   dir — `rm -f "$tmp"`, fall back to the user registry `~/.aid/registry.yml`
   (re-run the write there), and print the existing `WARN: aid: could not update
   the machine repo registry (...)` line. The command the user actually ran
   (status, dashboard, add) **still completes** — the registry is a rebuildable
   index, never required for a single-repo op (design §3.3). `return 0`.

> **Note on prompting (corrected from the prior draft).** `_aid_priv_run` has
> **no TTY guard** and does **not** silently decline: when the probe dir is not
> writable and `sudo` exists, it runs `sudo "$@"`, which prompts interactively.
> The only non-prompting decline is when `sudo` is absent (return 13). This is
> acceptable here because the shared write is an explicit `aid add` / register
> action, not a read-only command; design §3.3 #2 ("no read-only command
> force-prompts sudo merely to index") is honored by **not routing read-only
> commands through this path at all**, not by an internal TTY check.

**Per-user runtime write:** feature-001 resolves `AID_STATE_HOME = ~/.aid`,
`reg="$HOME/.aid/registry.yml"`, always user-writable; `_provision_shared_state_home`
is never called and `_aid_priv_run "$AID_STATE_HOME" mv -f ...` runs `mv` directly
with no elevation, identical to today.

### Edge cases & fail-safes

- **`/var/lib/aid` not present at runtime** (older global install predating this
  feature, or a global `curl|bash` that ran without root and never provisioned):
  the runtime write path finds no shared dir. `mkdir -p` of `/var/lib/aid` via
  `_aid_priv_run` is attempted **once** on the write; if that too declines/fails,
  degrade to the **user** registry (`~/.aid/registry.yml`) + one `WARN:` line.
  Never hard-fail. (AC6: "degrade to skip+warn while still operating.")
- **Elevation declines on the shared write** (`sudo` absent → `_aid_priv_run`
  returns 13, or the user cancels the sudo prompt → non-zero): the writer falls
  back to the user registry, prints `WARN:`, and `return 0`. This path is only
  ever entered from an explicit write action (`aid add` / register), never from a
  read-only command — read-only commands are **not** routed through the
  privileged-write path at all (design §3.3 decision #2; NFR least-privilege),
  which is how "no read-only command force-prompts sudo to index" is satisfied
  (the helper itself has no TTY guard, so the guarantee lives at the call site).
- **Re-install / upgrade over an existing `/var/lib/aid`:** the seed step is
  no-clobber (`[[ -e "$reg" ]] && skip`), so registered repos survive a reinstall.
- **Concurrent privileged writers** (two `aid add` racing on the shared registry):
  out of scope beyond the atomic `mv -f` set-insert (REQUIREMENTS §4 non-goal);
  last writer wins, no corruption (atomic rename).
- **FHS correctness:** `/var/lib/aid` is variable state owned by a package,
  persisting across reboots — the FHS `/var/lib/<pkg>` slot. Not `/var/cache`
  (the registry is authoritative, not regenerable from elsewhere), not `/etc`
  (machine-generated, not admin-edited; the header says do-not-hand-edit).
- **Read-only `/var` / container with no writable `/var/lib`:** the first
  shared-write provisioning attempt fails (even under sudo); the runtime write
  falls back to the user tier `~/.aid/registry.yml` + one `WARN:`. The user's
  command still completes; the global install itself was never blocked because
  provisioning is lazy, not an install step.

### bash ↔ ps1 parity

Windows has no `/var/lib` and no `sudo`. The bash file (`bin/aid`,
`lib/aid-install-core.sh`, `install.sh`) and the PowerShell twin (`bin/aid.ps1`,
`lib/AidInstallCore.psm1`, `install.ps1`) must stay behaviorally equivalent on
the *contract* (two-tier registry, best-effort degrade), differing only on the
concrete shared-state path and elevation mechanism.

**Recommended Windows shared-state home: `%ProgramData%\aid`**
(`$env:ProgramData\aid`, typically `C:\ProgramData\aid`). Rationale: it is the
Windows analogue of `/var/lib` — machine-wide, persistent, application-managed
data writable by Administrators and readable by all users, mirroring the
root-writes / everyone-reads model. The per-user home already resolves to
`$env:LOCALAPPDATA\aid` (`bin/aid.ps1:66`), so the shared/user split is symmetric
with POSIX. Elevation for the shared write uses the PR #78 PowerShell elevation
path (UAC `Start-Process -Verb RunAs`, or no-elevation when the location is
user-writable); when elevation is unavailable, the same skip+warn degrade
applies. A global Windows install (machine-wide MSI/Admin install) provisions
`%ProgramData%\aid`; a per-user install collapses shared==user==`%LOCALAPPDATA%\aid`,
exactly as POSIX collapses to `~/.aid`.

All shipped scripts touched here remain **ASCII-only** (CI-enforced; NFR §6).

### Testing

Canonical assertions (HOME- and AID_HOME-pinned to a throwaway dir; mirror the
existing pinning so no real repo or real `/var/lib` is touched — tests target a
sandbox `SHARED=<tmp>/shared` passed as the shared-home argument, **never** the
literal `/var/lib/aid`):

1. **Provision helper creates the dir + empty registry.** With `_aid_priv_run`
   stubbed to run commands directly (writable sandbox), invoke
   `_provision_shared_state_home "$SHARED"`; assert `$SHARED` exists, is mode
   `0755`, and `$SHARED/registry.yml` exists with mode `0644`, `schema: 1`, and a
   `repos:` line with **zero** items.
2. **Seed is no-clobber.** Pre-create `$SHARED/registry.yml` with one repo;
   re-run the helper; assert the repo entry survives (idempotent re-write).
3. **Per-user collapse.** With per-user scope (payload root writable, so
   `AID_STATE_HOME == ~/.aid`), run a `registry_register`; assert it never calls
   `_provision_shared_state_home` (stub records calls), creates no
   `/var/lib/aid`-equivalent path, and writes to `~/.aid/registry.yml`.
4. **Shared write elevates only when needed.** With `$SHARED` user-writable, a
   `registry_register` writes directly (stub `_aid_priv_run` asserts it ran the
   command without an elevation branch). With `$SHARED` made non-writable (e.g.
   `chmod 0555`), assert the writer routed through `_aid_priv_run`.
5. **Best-effort degrade when elevation declines.** Stub `_aid_priv_run` to
   return non-zero (simulating `sudo` absent → 13, or a cancelled prompt); assert
   `registry_register` falls back to `~/.aid/registry.yml`, prints the `WARN:`
   line, returns 0, the surrounding command still completes, and no
   `*.aid-tmp.*` temp file is left.
6. **Missing shared dir at runtime degrades to user tier.** Point
   `AID_STATE_HOME` at a non-existent, non-creatable shared path with
   `_aid_priv_run` stubbed to decline; assert the entry lands in
   `~/.aid/registry.yml` and one WARN is printed, no hard failure.
7. **ASCII-only guard** over the changed scripts (reuse the existing CI check).

These extend the existing registry suites in `tests/canonical/`; reuse the
`mktemp`/`mv -f` assertions already covering `registry_register`.

### Backward compatibility

Existing **global** installs (v1.0/v1.1) wrote `registry.yml` into the root-owned
payload dir under the single self-located `$AID_HOME` (e.g.
`/usr/lib/node_modules/aid-installer/registry.yml`) — the root-cause bug
(REQUIREMENTS §2): an unprivileged `aid` could not write it, and the file was in
the read-only code payload. Transition:

- After this feature lands (with feature-001's split), the shared registry
  resolves to `/var/lib/aid/registry.yml`, **not** the payload dir. Any stale
  registry inside the old payload dir is simply **ignored** — `AID_STATE_HOME`
  no longer points there, so it is never read.
- No migration of the old file's contents is attempted (the registry is a
  rebuildable index; repos re-register lazily on next visit per design §3.4/§3.5
  and feature-001's bootstrap). This is intentional and matches the "registry is
  an index, not authoritative state" model — avoids reading from a root-owned
  location the new code deliberately abandons.
- On a global install, the **first shared-state write** after this feature lands
  provisions `/var/lib/aid` if absent (lazy, idempotent seed), so upgraders
  converge to the correct home with no manual step and no install-time root hook.
  Until that first write, or if provisioning's elevation declines, the write
  degrades to the user tier + warn (Edge cases), never stranding the user
  (NFR backward-compat).
- Per-user installs are unaffected: `~/.aid/registry.yml` was always writable and
  remains the sole registry.
