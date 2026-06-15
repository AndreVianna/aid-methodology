# Global Shared-State Provisioning (/var/lib/aid)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-15 | Feature identified from REQUIREMENTS.md §5 (FR7), §4, §9 (AC6), §10 (Priority 1) | /aid-interview |
| 2026-06-15 | Technical Specification authored | /aid-specify |
| 2026-06-15 | Spec fixes (review cycle 1): _aid_priv_run convention, real provisioning hook, removed fabricated verb | /aid-specify |
| 2026-06-15 | Re-spec (cycle 2): install-time provisioning primary + non-prompting runtime fallback (was runtime/lazy) | /aid-specify |
| 2026-06-15 | Spec fixes (cycle 3): working curl install guard (env-preset capture), AID_SHARED_STATE_HOME test seam, line cite | /aid-specify |
| 2026-06-15 | Seam consistency: global AID_STATE_HOME honors AID_SHARED_STATE_HOME (runtime+install unified) | /aid-specify |

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

This feature is the **global shared-state provisioning slice** of the global
state home, using a **HYBRID** model: install-time provisioning is the PRIMARY
mechanism, and a non-prompting best-effort runtime ensure-exists is a FALLBACK
only. It does **not** re-specify scope detection or the `AID_CODE_HOME` /
`AID_STATE_HOME` resolution — those are feature-001 and are treated as GIVEN
here, as is the `_aid_priv_run` elevation helper (PR #78, gated to master first).
This feature owns four concrete behaviors:

1. **Install-time creation (PRIMARY)** of `/var/lib/aid` (root-owned,
   world-readable) and seeding of an empty shared `registry.yml` there, performed
   by the installers themselves (npm postinstall + curl `install.sh`) **only when
   the install runs as root**. Adding these install-time hooks IS this feature's
   job (REQUIREMENTS §4 "global shared-state provisioning `/var/lib/aid` by the
   installers"; the feature title) — it is **not** deferred to any other feature.
   The earlier premise "no reachable install-time hook today" is true-but-irrelevant:
   the hook does not exist *yet* because building it is the work here.
2. **Runtime ensure-exists (FALLBACK, non-prompting)** on a shared-state write of
   a global install whose `/var/lib/aid` is absent — e.g. an older global install
   predating this feature, or a non-root convenience install that could not
   provision at install time. This path attempts create/seed via the
   never-elevate route and, if the shared dir is missing and cannot be created
   without elevation, DEGRADES to the user tier `~/.aid` + one WARN and `return 0`.
   A routine `aid add` MUST NOT fire an interactive sudo password prompt.
3. The **shared-registry write path** itself, which is best-effort: the write into
   an already-root-owned `/var/lib/aid` inherently needs elevation, so per design
   §3.3 #2 that shared registration is a best-effort skip+warn (it does **not**
   prompt — it degrades to the user tier).
4. The **per-user collapse** so a non-global install never produces a `/var/lib/aid`
   path: shared == user == `AID_STATE_HOME` == `~/.aid`.

> **Dependency naming convention used below.** `AID_STATE_HOME` is the
> feature-001 state-home resolution (`${AID_HOME:-<scope-default>}`, where the
> scope default is `~/.aid` per-user and `${AID_SHARED_STATE_HOME:-/var/lib/aid}`
> global). Because feature-001 resolves the global default through the same
> `AID_SHARED_STATE_HOME` seam this feature uses, the runtime ensure-exists path
> (which writes to `AID_STATE_HOME`) honors the identical override as the
> install-time hooks below — pinning the seam once reaches both.
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
>
> **Shared-state root override (the one new knob this feature adds).**
> `AID_SHARED_STATE_HOME` is a single documented environment override for the
> machine-wide shared-state root, **defaulting to `/var/lib/aid`**. It is the
> only parameterization introduced here, and it is honored consistently by
> **every** site that names the shared root:
>
> - npm postinstall: `process.env.AID_SHARED_STATE_HOME || '/var/lib/aid'`.
> - curl `install.sh` hook + `_provision_shared_state_home` arg:
>   `"${AID_SHARED_STATE_HOME:-/var/lib/aid}"`.
> - runtime ensure-exists (the global-scope shared home that feature-001's
>   `AID_STATE_HOME` resolves to): same `"${AID_SHARED_STATE_HOME:-/var/lib/aid}"`
>   default.
>
> Production default is unchanged (`/var/lib/aid`); the override exists so
> canonical tests get a real, writable sandbox seam (set it to `<tmp>/shared`)
> instead of touching the live machine path. No broader configuration surface is
> introduced — this single env var is the whole seam.

### Approach

#### Why provisioning is INSTALL-TIME (primary), with a non-prompting runtime fallback

A current-state audit shows the npm/pypi/curl installers do **not** yet provision
a shared `/var/lib/aid`:

- `install.sh` always installs to `$HOME/.aid` (the three
  `AID_HOME="${AID_HOME:-${HOME}/.aid}"` sites at `install.sh:577,669,936`) and
  contains **no root/uid detection and no `/var/lib` branch** today
  (`grep -n 'id -u\|EUID\|/var' install.sh` is empty).
- `packages/npm/scripts/postinstall.js` has **no `getuid`/root branch** today; it
  only prints a notice or spawns `aid update self`. `pypi` has no JS postinstall
  at all (per-user by construction via pipx — see Affected components).

The earlier draft read this absence as "no reachable install-time hook today" and
made runtime/lazy the primary mechanism. **That premise is true-but-irrelevant:
adding these hooks IS this feature's job** (REQUIREMENTS §4 "global shared-state
provisioning `/var/lib/aid` by the installers"; the feature title). The hooks are
small, reachable insertions in install paths that already run during a global
install, and they create `/var/lib/aid` at the exact moment the installer holds
root — so the literal contract "when installation completes, `/var/lib/aid`
exists" (AC1) is satisfiable as written. We therefore **build them here**, not
defer to another feature.

**Install-time is PRIMARY** because:

- It is the only point where the process legitimately holds root for a global
  install (npm `-g` postinstall under sudo; root `curl|bash`), so the
  root-owned/world-readable mlocate layout (design §2/§3.2) is created **without
  a later interactive sudo prompt** during normal CLI use.
- It makes AC1 literally true: provisioning is a deterministic install step, not
  a probabilistic "first write someday" event.
- Non-root installs (user-prefix npm global, non-root `curl|bash`, pipx) correctly
  **skip** the install-time hook (uid≠0) — they are per-user scope anyway and
  collapse to `~/.aid` (behavior 4).

**Runtime ensure-exists is the FALLBACK** (non-prompting, best-effort) for global
installs whose `/var/lib/aid` is absent at write time — old installs predating
this feature, or a global tree provisioned without root. It re-converges by
attempting a never-elevate create/seed and, when that is not possible without
elevation, degrading to `~/.aid` + WARN. It **never** force-prompts sudo: a
routine `aid add` must not block on a password.

**Recommendation: install-time provisioning is the primary mechanism; runtime is
a non-prompting best-effort ensure-exists fallback only.** The
`_provision_shared_state_home` helper body is correct and reusable either way;
this re-spec moves its **call site** from the runtime registry-write path to the
installers, and re-scopes the residual runtime path to never-elevate.

#### The provisioning helper

A new helper `_provision_shared_state_home <shared-home>` is added to
`lib/aid-install-core.sh` (the file the curl bootstrap dot-sources at
`install.sh:526` and copies to `${AID_HOME}/lib/aid-install-core.sh` at
`install.sh:779`; the npm/pypi payloads vendor the same file, so the helper is
available both to the installers and to `bin/aid` at runtime via the existing
lib-sourcing path). **The installers call this helper at install time when running
as root** (primary path — see Affected components); the runtime registry-write
path only invokes the never-elevate ensure-exists portion as a fallback.

The helper, given the resolved shared home `SH` (`/var/lib/aid` on a global
install):

1. If `"$SH"` does not exist, create it, **probing the parent**:
   `_aid_priv_run "$(dirname "$SH")" mkdir -p "$SH"` then
   `_aid_priv_run "$SH" chmod 0755 "$SH"`. At the **install-time** call site the
   process already holds root, so the probe of `/var/lib` is writable
   (uid 0 ⇒ `need_root=0`, `bin/aid:322`) and the `mkdir` runs directly — no
   prompt. Result is root-owned, world-readable + world-traversable,
   owner-writable only — the mlocate model (design §2/§3.2).
2. If `"$SH/registry.yml"` does **not** already exist, seed an **empty** registry
   using the exact current schema (`bin/aid:1216-1223`): the three comment lines,
   `schema: 1`, and `repos:` with **no items**. Write to a temp file, then
   `_aid_priv_run "$SH" mv -f "$tmp" "$SH/registry.yml"` (elevates iff `$SH` is
   not user-writable), then `_aid_priv_run "$SH" chmod 0644 "$SH/registry.yml"`.
   Never clobber an existing `registry.yml` (idempotent / upgrade safe).
3. Best-effort throughout: if any `_aid_priv_run` step fails (read-only `/var`,
   container), the helper returns non-zero and **never hard-fails** its caller.
   At the **install-time** caller (npm postinstall / curl `install.sh`) a non-zero
   return is simply swallowed (caught try/catch for npm; the install still
   succeeds) — the install is not blocked and no per-user degrade happens there.

> **Two distinct call modes (the load-bearing distinction of this re-spec).**
> (a) **Install-time PRIMARY** invokes the full `_provision_shared_state_home`
> helper while holding root, so its probes are writable and it runs directly.
> (b) **Runtime FALLBACK** does **not** call the full helper with non-empty
> probes (that could elevate/prompt); the registry writers instead perform their
> own **never-elevate** ensure-exists via `_aid_priv_run ""` (empty probe ⇒
> forced direct, `bin/aid:322,337`) and, on failure, degrade to the user tier
> `~/.aid` + one `WARN:` + `return 0` (see Affected components, Behavior B,
> Edge cases, AC6). No routine command prompts for sudo.

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
| `lib/aid-install-core.sh` | all (vendored) | **New** `_provision_shared_state_home <shared-home>`: create dir + `chmod 0755` and seed empty `registry.yml` (`0644`, atomic, no-clobber), each filesystem mutation routed through `_aid_priv_run`. Best-effort; returns non-zero (does not abort the caller) when elevation declines. **Body unchanged from cycle 1 — only the call site moves to install-time.** When the installer already holds root (uid 0), every `_aid_priv_run` probe finds the target writable and runs directly, so install-time provisioning never re-prompts. |
| `packages/npm/scripts/postinstall.js` | npm | **Install-time PRIMARY hook (npm).** Resolve the shared-state root once via the seam — `var sharedHome = process.env.AID_SHARED_STATE_HOME || '/var/lib/aid';` — then add a branch guarded by `process.getuid && process.getuid() === 0` **and** not-already-provisioned (`!existsSync(path.join(sharedHome, 'registry.yml'))`): `mkdirSync(sharedHome, {mode: 0o755})` then seed an empty `registry.yml` under `sharedHome` (write `0644`, **no-clobber**) using the exact schema (`schema: 1` + empty `repos:`) — the same seed text the CLI uses (`bin/aid:1216-1223`, self-contained branch `bin/aid:1338-1342`). Wrap in the **existing** `try/catch` (the `try` opens at `postinstall.js:31`, `catch` at `:61-67`) so any failure stays non-fatal (`npm i -g` never breaks; NFR12/RC-3). A user-prefix global install runs as **non-root** ⇒ `getuid()!==0` ⇒ the branch is **skipped** correctly (that scope is per-user → `~/.aid`). The `AID_SHARED_STATE_HOME` env override (default `/var/lib/aid`) is the canonical-test sandbox seam — a test sets it to a writable tmp dir so the npm hook never writes the real `/var/lib`. This UN-DROPS the previously-dropped `getuid()===0` idea as an **inline** `mkdirSync`/seed — **not** the fabricated `aid --provision-shared-state` verb (no such verb; `grep -rn provision-shared-state` is empty). |
| `install.sh` (top-of-file env capture) | curl | **New early capture line.** As one of the first executable lines, immediately after `set -uo pipefail` (`install.sh:66`) and **before** the first `AID_HOME="${AID_HOME:-${HOME}/.aid}"` default (`install.sh:577`), add: `_AID_HOME_PRESET="${AID_HOME:-}"`. This snapshots whether `AID_HOME` was preset **in the environment** before `install.sh` unconditionally defaults it — the signal both hooks guard on. A real root `sudo curl\|bash` has no `AID_HOME` in its env (`_AID_HOME_PRESET` empty ⇒ provision); a canonical test that pins `AID_HOME=<throwaway>` in the env (`_AID_HOME_PRESET` non-empty ⇒ skip, protecting the real `/var/lib`). This intentionally does **not** key off the post-default `AID_HOME` (which is the always-set install dir, not feature-001's STATE-override and never empty at either hook site). |
| `install.sh` (curl bootstrap + convenience) | curl | **Install-time PRIMARY hook (curl).** After install success in BOOTSTRAP mode (after the `aid CLI ... installed` echo, `install.sh:820`) AND in the shared CONVENIENCE block (after install success / before the `exec` at `install.sh:1065`; block body `install.sh:941-1062`), add: `if [[ "$(id -u)" -eq 0 && -z "$_AID_HOME_PRESET" ]]; then _provision_shared_state_home "${AID_SHARED_STATE_HOME:-/var/lib/aid}"; fi`. The `-z "$_AID_HOME_PRESET"` guard tests the **environment-preset** snapshot taken at `install.sh:66` (above), not the post-default `AID_HOME` — so it is true on a real root `curl\|bash` (env had no `AID_HOME`) and false under a test that env-pins `AID_HOME` (keeping the suite from ever touching the real `/var/lib`). `install.sh` currently installs to `$HOME/.aid` at `:577/:669/:936`; this is the first `/var/lib` / `id -u` site it gains. Best-effort: the helper returns non-zero on failure but the install does not abort. |
| pipx packaging | pypi/pipx | **No change.** pipx is per-user by construction (installs into a per-user venv, runs as the invoking non-root user); there is no global root install path to hook. Shared==user==`~/.aid` collapse applies; provisioning rides the runtime fallback only if a `/var/lib/aid` ever exists for it to converge to. |
| `bin/aid` `registry_register` (`bin/aid:1202-1235` after the feature-001 `AID_STATE_HOME` rename) | runtime, all | **Non-prompting FALLBACK hook.** If `$reg` lives under a shared home whose dir is missing, attempt a **never-elevate** ensure-exists: `_aid_priv_run "" mkdir -p "$AID_STATE_HOME"` (empty probe ⇒ forced direct, `bin/aid:322` makes `need_root=0`; `bin/aid:337` runs `"$@"` with no sudo) plus the seed via the same never-elevate path. If the shared dir is missing and cannot be created without elevation, **DEGRADE** to `~/.aid` (user tier) + one `WARN:` + `return 0`. The shared-tier commit `mv -f "$tmp" "$reg"` is likewise best-effort: a write into an already-root-owned `/var/lib/aid` is **skipped+warned (degrades to `~/.aid`), not sudo-prompted** (design §3.3 #2). A routine `aid add` therefore **never** fires an interactive sudo prompt. |
| `bin/aid` `registry_unregister` (`bin/aid:1241-1273` after the rename) | runtime, all | Atomic-commit via the same never-elevate path; degrade to user tier on failure. (No provisioning here — unregister only runs when a registry already exists; `[[ -f "$reg" ]] || return 0` guards it.) |

> **Feature-001 prerequisite (call-out, not owned here).** The registry writers
> today hardcode `reg="${AID_HOME}/registry.yml"` (`bin/aid:1203,1242`) and `bin/aid`
> has zero `AID_STATE_HOME` references (`grep -c AID_STATE_HOME bin/aid` = 0). The
> `AID_HOME → AID_STATE_HOME` repoint and scope-derivation are a **feature-001
> GIVEN** that must land **before** this feature's runtime hook is correct —
> otherwise the wrapper would key off the wrong variable and the shared tier
> would never be selected. This feature does not perform that rename; it consumes
> the resolved `AID_STATE_HOME`. **The `AID_SHARED_STATE_HOME` seam reaches
> runtime via feature-001:** feature-001 resolves the global `AID_STATE_HOME`
> default as `${AID_SHARED_STATE_HOME:-/var/lib/aid}`, so the runtime
> ensure-exists path (which writes to `AID_STATE_HOME`) honors the same seam as
> the install hooks. There is no separate seam for runtime — pinning
> `AID_SHARED_STATE_HOME` once redirects both the install-time provisioning and
> the runtime write to the sandbox, so a canonical test exercises the runtime
> fallback against `<tmp>/shared`, never the real `/var/lib`.

**Two distinct call modes of `_aid_priv_run` are used, and the distinction is
load-bearing:**

- **Install-time provisioning (PRIMARY, may elevate-by-being-root):** the
  installer runs `_provision_shared_state_home "${AID_SHARED_STATE_HOME:-/var/lib/aid}"` while holding root,
  so the helper's dir/file mutations
  (`_aid_priv_run "$(dirname "$SH")" mkdir -p "$SH"`,
  `_aid_priv_run "$SH" chmod ...`, `_aid_priv_run "$SH" mv -f ...`) all find the
  probe writable (uid 0 ⇒ `need_root=0`, `bin/aid:322`) and run directly — no
  sudo, no prompt. This is the only place the root-owned layout is created.
- **Runtime fallback (NEVER-ELEVATE):** the registry writers use the **empty
  probe** form `_aid_priv_run "" mkdir -p "$AID_STATE_HOME"` / `_aid_priv_run ""
  mv -f "$tmp" "$reg"`. The empty first argument forces the direct,
  never-elevate path (`bin/aid:322` requires `-n "$probe"`, so `need_root`
  stays 0 and `bin/aid:337` runs `"$@"` with no sudo). When the direct write
  fails because the target is root-owned, the writer **degrades to `~/.aid` +
  WARN**, it does **not** route through a non-empty probe (which would prompt).
  A routine `aid add` therefore never triggers an interactive sudo prompt.

### Behavior / Flow

**A. Install-time provisioning sequence (PRIMARY — root global install):**
1. **npm `-g` (root):** `postinstall.js` runs with `process.getuid() === 0`. The
   new branch, inside the existing `try/catch` (`postinstall.js:61-67`),
   `mkdirSync('/var/lib/aid', {mode: 0o755})` (no-op if present) and, if
   `/var/lib/aid/registry.yml` is absent, writes the empty seed (`schema: 1` +
   empty `repos:`, mode `0644`). Failure is non-fatal (caught → soft WARN →
   `exit 0`).
2. **curl `install.sh` (root, no env-preset `AID_HOME`):** `install.sh` first
   snapshots `_AID_HOME_PRESET="${AID_HOME:-}"` at the top of the file
   (`install.sh:66`, before the first default at `:577`), so on a real root
   `curl|bash` the snapshot is empty. After the install-success echo in BOOTSTRAP
   (`install.sh:820`) and again at the end of the CONVENIENCE install block
   (before the `exec`, `install.sh:1065`), the guard
   `[[ "$(id -u)" -eq 0 && -z "$_AID_HOME_PRESET" ]]` runs
   `_provision_shared_state_home "${AID_SHARED_STATE_HOME:-/var/lib/aid}"`.
   Holding root, every internal `_aid_priv_run` probe is writable ⇒ direct
   `mkdir -p /var/lib/aid`, `chmod 0755`, atomic-seed `registry.yml` `0644`
   (no-clobber). No prompt.
3. **Non-root / user-prefix / pipx:** the guard fails (`getuid()!==0` /
   `id -u != 0`) and nothing is provisioned — that install is per-user scope and
   collapses to `~/.aid` (behavior 4). A test that env-presets `AID_HOME`
   likewise short-circuits (`_AID_HOME_PRESET` non-empty), protecting the real
   `/var/lib`.
4. Result on a root global install: when installation completes, `/var/lib/aid`
   exists, root-owned, `0755`, with a seeded `0644` `registry.yml` — **AC1
   literally satisfied**.

**B. Runtime ensure-exists FALLBACK (non-prompting)** — only when a global
install's `/var/lib/aid` is absent at write time (old install, or a global tree
never provisioned at install):
1. feature-001 resolves scope = global and `AID_STATE_HOME = /var/lib/aid`;
   `reg="$AID_STATE_HOME/registry.yml"`.
2. Idempotent check: `$repo` already present → no-op (`bin/aid:1207`).
3. If the shared dir is missing, attempt a **never-elevate** ensure-exists:
   `_aid_priv_run "" mkdir -p "$AID_STATE_HOME"` (empty probe ⇒ `need_root=0`,
   `bin/aid:322`; direct run at `bin/aid:337`) + never-elevate seed. **No sudo,
   no prompt.** If the parent is not user-writable so the direct `mkdir` fails,
   go to step 6 (degrade).
4. `mktemp` next to `reg`; write the merged, deduped, sorted list (unchanged
   logic, `bin/aid:1216-1223`).
5. Commit: `_aid_priv_run "" mv -f "$tmp" "$reg"` (empty probe ⇒ direct). If
   `/var/lib/aid` is already root-owned (the normal post-install case but the
   user is unprivileged), the direct `mv` fails — go to step 6.
6. **Degrade (best-effort, never prompts):** `rm -f "$tmp"`, fall back to the
   user registry `~/.aid/registry.yml` (re-run the write there), print the
   existing `WARN: aid: could not update the machine repo registry (...)` line,
   and `return 0`. The command the user actually ran (status, dashboard, add)
   **still completes** — the registry is a rebuildable index, never required for
   a single-repo op (design §3.3).

> **Note on prompting (re-spec cycle 2).** The runtime path uses the **empty-probe
> never-elevate form** of `_aid_priv_run` (`_aid_priv_run "" ...`), which the
> helper body forces down the direct, no-sudo branch (`bin/aid:322,337`). The
> shared WRITE into an already-root-owned `/var/lib/aid` inherently needs
> elevation, but per design §3.3 #2 that registration is **best-effort skip+warn**:
> `aid add`'s shared registration does **NOT** prompt — it degrades to `~/.aid`.
> A routine `aid add` therefore never fires an interactive sudo password prompt.
> (Elevation that genuinely needs root happens only at install time, in A, where
> the process already holds it.)

**Per-user runtime write:** feature-001 resolves `AID_STATE_HOME = ~/.aid`,
`reg="$HOME/.aid/registry.yml"`, always user-writable; `_provision_shared_state_home`
is never called and `_aid_priv_run "" mv -f ...` runs `mv` directly with no
elevation, identical to today.

### Edge cases & fail-safes

- **`/var/lib/aid` not present at runtime** (older global install predating this
  feature, or a global install whose install-time hook was skipped — e.g. it was
  not run as root): the runtime FALLBACK finds no shared dir. A **never-elevate**
  `mkdir -p` (`_aid_priv_run "" ...`) is attempted **once**; if that fails because
  the parent is not user-writable, degrade to the **user** registry
  (`~/.aid/registry.yml`) + one `WARN:` line, no prompt. Never hard-fail.
  (AC6: "degrade to skip+warn while still operating.")
- **Shared write into a root-owned `/var/lib/aid` by an unprivileged user:** the
  never-elevate direct `mv` fails; the writer falls back to the user registry,
  prints `WARN:`, and `return 0`. **It does NOT prompt for sudo** — the shared
  registration is best-effort (design §3.3 #2; NFR least-privilege). The
  guarantee lives at the call site (the empty-probe form), not in a TTY check.
  Read-only commands are additionally **not** routed through this write path at
  all.
- **Re-install / upgrade over an existing `/var/lib/aid`:** both the install-time
  seed (npm/curl) and the runtime seed are no-clobber (`[[ -e "$reg" ]] && skip`),
  so registered repos survive a reinstall.
- **Non-root global install (user-prefix npm, non-root `curl|bash`):** the
  install-time hook is **skipped** (uid≠0 / `id -u != 0`); that install is
  per-user scope and collapses to `~/.aid`, so no `/var/lib/aid` is expected or
  created. Correct by design, not a degradation.
- **Concurrent privileged writers** (two `aid add` racing on the shared registry):
  out of scope beyond the atomic `mv -f` set-insert (REQUIREMENTS §4 non-goal);
  last writer wins, no corruption (atomic rename).
- **FHS correctness:** `/var/lib/aid` is variable state owned by a package,
  persisting across reboots — the FHS `/var/lib/<pkg>` slot. Not `/var/cache`
  (the registry is authoritative, not regenerable from elsewhere), not `/etc`
  (machine-generated, not admin-edited; the header says do-not-hand-edit).
- **Read-only `/var` / container with no writable `/var/lib`:** the install-time
  provisioning attempt fails (caught, non-fatal, install still succeeds); a later
  runtime write falls back to the user tier `~/.aid/registry.yml` + one `WARN:`,
  no prompt. The user's command still completes.

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
with POSIX. The **primary** provisioning point mirrors POSIX: a machine-wide
(Administrator) install creates `%ProgramData%\aid` at **install time** while
holding elevation; the runtime path is the same non-prompting best-effort
ensure-exists fallback (no UAC re-prompt during a routine `aid add` — degrade to
`%LOCALAPPDATA%\aid` + WARN instead). A per-user install collapses
shared==user==`%LOCALAPPDATA%\aid`, exactly as POSIX collapses to `~/.aid`.

All shipped scripts touched here remain **ASCII-only** (CI-enforced; NFR §6).

### Testing

Canonical assertions (HOME- and AID_HOME-pinned to a throwaway dir; mirror the
existing pinning so no real repo or real `/var/lib` is touched). The
shared-state root is redirected to a sandbox via the **`AID_SHARED_STATE_HOME`
seam** (default `/var/lib/aid`): tests `export AID_SHARED_STATE_HOME=<tmp>/shared`
(also passed/observed as the `_provision_shared_state_home` argument), so every
provisioning site — the npm postinstall, the curl `install.sh` hook, the helper,
and the runtime ensure-exists — writes under the sandbox and **never** touches
the literal `/var/lib/aid`. Where a test invokes the helper directly it passes
`SHARED=<tmp>/shared` as the explicit argument:

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
4. **Install-time hook provisions when root, skips otherwise (npm).** Run
   `postinstall.js` with `getuid` stubbed to return 0 and
   `AID_SHARED_STATE_HOME=<tmp>/shared` (the seam redirects `mkdirSync`/seed off
   `/var/lib/aid` to the sandbox); assert the sandbox dir + empty `0644` seed are
   created. Re-run with `getuid` returning a non-zero uid; assert **nothing** is
   provisioned. Re-run with the seed pre-existing; assert no-clobber.
5. **Install-time hook guard (curl).** With `AID_SHARED_STATE_HOME=$SHARED`
   (the sandbox seam, default `/var/lib/aid`) and `id -u`→0 and `AID_HOME` unset
   in the env, run the `install.sh` provisioning guard; assert
   `_AID_HOME_PRESET` is captured empty, the guard passes, and `$SHARED` is
   provisioned (the real `/var/lib` is never touched because the helper is
   pointed at `$SHARED` via the seam). Then env-pin `AID_HOME=<throwaway>` and
   re-run; assert `_AID_HOME_PRESET` is non-empty so the guard's
   `-z "$_AID_HOME_PRESET"` short-circuit skips provisioning entirely.
6. **Runtime fallback never prompts.** With global scope resolved so feature-001
   sets `AID_STATE_HOME=${AID_SHARED_STATE_HOME:-/var/lib/aid}=$SHARED` (the seam
   reaches the runtime write through feature-001's resolution — the same override
   the install hooks use), `$SHARED` made non-writable (e.g. `chmod 0555`), and
   `sudo` present on PATH, run `registry_register` and assert the empty-probe
   `_aid_priv_run ""` path was used (no `sudo` invocation, confirmable via a
   `sudo` stub that fails the test if called), it degraded to `~/.aid/registry.yml`,
   and printed one `WARN:`.
7. **Best-effort degrade, no temp leak.** Make the shared write fail (non-writable
   `$SHARED`); assert `registry_register` falls back to `~/.aid/registry.yml`,
   prints the `WARN:` line, returns 0, the surrounding command still completes,
   and no `*.aid-tmp.*` temp file is left.
8. **Missing shared dir at runtime degrades to user tier.** Point
   `AID_STATE_HOME` at a non-existent, non-creatable shared path (read-only
   parent); assert the never-elevate `mkdir` fails, the entry lands in
   `~/.aid/registry.yml`, one WARN is printed, no hard failure, no prompt.
9. **ASCII-only guard** over the changed scripts (`install.sh`,
   `lib/aid-install-core.sh`; `postinstall.js` is not ASCII-CI-gated but stays
   ASCII for parity) — reuse the existing CI check.

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
- A **re-install / upgrade** of a global install after this feature lands runs the
  install-time hook (npm postinstall / curl `install.sh`) as root and provisions
  `/var/lib/aid` if absent (idempotent, no-clobber seed) — so upgraders converge
  to the correct home with **no manual step** as part of the normal upgrade.
- Old global installs that have not yet been re-installed (no install-time hook
  ran) converge via the **runtime fallback**: the first shared-state write
  attempts a never-elevate ensure-exists, and if the shared dir is absent/not
  creatable without elevation, degrades to the user tier + warn (Edge cases) —
  never prompting, never stranding the user (NFR backward-compat).
- Per-user installs are unaffected: `~/.aid/registry.yml` was always writable and
  remains the sole registry.
