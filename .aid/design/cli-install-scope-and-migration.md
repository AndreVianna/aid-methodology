# Design Note — AID CLI: install scope, repo discovery, and migration

**Status:** Settled (pre-implementation) — all §6 open items resolved 2026-06-15
(decisions A–F, §5.6–§5.11). Captures the model agreed in discussion; supersedes
the ad-hoc behavior shipped in v1.0.0 / v1.1.0.
**Date:** 2026-06-15.

---

## 1. Problem

AID is a CLI (`aid`) that manages per-project `.aid/` directories. The model has
to answer, coherently:

1. The CLI may be installed **globally** (machine-wide, e.g. root-owned npm
   global) **or per-user** (npm user prefix / pipx / curl `~/.aid`).
2. It is updated **through itself** (`aid update self`) **or via the installer**
   (`npm i -g …`, `pipx upgrade`, `curl|bash`).
3. An update **may require migrating repos** to the new format.
4. A **per-user** install limits the repo scope to the user's home (`~`).
5. A **global** install must be able to reach repos **anywhere on the machine**.
6. A repo's migration state is a **property of the repo** → it lives **with the
   repo**, not the CLI.
7. The **list** of AID repos may be kept with the CLI — design open (resolved below).

A real-machine dogfood (v1.0.0 npm-global → v1.1.0) exposed the core bug: the
migration wrote per-machine state (`.migrated`, `registry.yml`) into the
root-owned `$AID_HOME`, which an unprivileged `aid` invocation cannot write — and
running as root scanned the wrong `$HOME`. Six repos under `/srv/projects`
(group `developers`) were never seen because the scan only walked `$HOME`.

---

## 2. Prior art (how comparable tools solve each facet)

- **Git — migration state with the artifact, fail-safe.** Each repo stamps
  `core.repositoryformatversion` (+ `extensions.*`) *in the repo*; a git that
  doesn't understand the version **must not operate** ("risks losing data"); git
  bumps *per-data-file* versions to localize incompatibility.
  → validates **point 6**: per-repo stamp, fail-safe, migrate-on-touch.
  ([git repository-version](https://git-scm.com/docs/repository-version))
- **rustup / Homebrew — self-update follows the install method.** `rustup self
  update` for standalone installs; defers to the package manager when one owns
  it (`--no-self-update`). → **points 1–2**: channel-aware update; privilege by
  scope. ([rustup](https://rust-lang.github.io/rustup/installation/already-installed-rust.html))
- **mlocate / `updatedb` — machine index built by a privileged process, read by
  all.** A root `updatedb` walks the FS with a prune-list and writes
  `/var/lib/mlocate/mlocate.db`; unprivileged `locate` only *reads* it; system db
  + optional per-user dbs, merged. → **points 5 & 7**, and the rule we violated:
  *machine state is written by the privileged op, read by everyone.*
  ([mlocate](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/6.7_technical_notes/package-mlocate))

---

## 3. Core model

### 3.1 Invocation: cwd-driven, on-demand — no scan
`aid <cmd>` acts on the **current directory's** repo (like git / pre-commit /
terraform). There is **no machine-wide filesystem scan**, ever. Repos are learned
**incrementally, on encounter**. Only `update self` / `remove self` are
machine-scoped.

### 3.2 Install scope + the home split
- **Scope is derived at runtime, not recorded.** `aid` is **global** iff its
  payload root (where `bin/aid` resolves via `dirname(dirname(realpath))`) is
  **not writable by the current user**; otherwise **per-user**. This reuses the
  shipped writability-probe philosophy (`_aid_priv_run`, bin/aid:312) — no
  install-time scope marker to write or keep in sync, and it is self-correcting.
  `AID_INSTALL_CHANNEL` stays a **self-update routing** hint only (npm/pipx/curl);
  it is not the scope source of truth. (Decision A.)
- **Decouple CODE from STATE** into two internal resolutions (Decision B):
  - **`AID_CODE_HOME`** — self-located as today (`dirname(dirname(realpath(bin/aid)))`),
    **read-only**; locates `lib/aid-install-core.sh`, `dashboard/` source, `VERSION`.
    Lives wherever the channel vendored the payload (npm pkg / pipx venv / curl tree).
  - **`AID_STATE_HOME`** — `${AID_HOME:-<scope default>}`; holds **only mutable
    state**. Scope default: **non-global → `~/.aid`**; **global →
    `${AID_SHARED_STATE_HOME:-/var/lib/aid}`** (Decision D — FHS variable-state dir,
    the mlocate model; root-owned, world-readable, shared writes elevate per §3.3).
    The `AID_SHARED_STATE_HOME` env override is the **single source** of the shared
    path — honored identically by this runtime resolution, the install-time
    provisioning hooks, and the test sandbox seam — so a test pins it once and both
    the install and runtime paths redirect together (never touching real `/var/lib/aid`).
  - The env var **`AID_HOME` is retained as an explicit override of the STATE
    home** (not code) — this is exactly what the test suite already does when it
    pins `AID_HOME` to a throwaway dir. Code home is never relocated by env.
- **State split by nature** (Decision F-adjacent): the shared **registry** is the
  only privileged-written state; `.update-check` is advisory **per-user cache** →
  always `~/.aid/.update-check` regardless of scope (never needs elevation). The
  `.migrated` machine marker is **removed** entirely (§3.4, Decision F).

### 3.3 Registry — two-tier, incremental, best-effort (mlocate model)
- **User registry:** `~/.aid/registry.yml` (user-owned, always writable).
- **Shared registry:** `$AID_HOME/registry.yml` (global install only;
  **privileged-written**, world-readable). For a non-global install
  `$AID_HOME == ~/.aid`, so the two collapse to one file (no shared tier).
- The CLI **unions** both at read time. The registry is a rebuildable **index**
  for the dashboard's repo list — not required for any single-repo operation.
- **Writes are best-effort:** if registering needs elevation and the user
  declines / there's no TTY, **skip + warn, still operate** (decision #2). No
  read-only command force-prompts `sudo` merely to index.
- Stale entries (repo deleted/moved) are pruned quietly on read.

### 3.4 Migration state — per-repo stamp (git model)
- Each repo records a **`format_version: <int>`** key in **`.aid/settings.yml`**
  (Decision C). It is an integer **decoupled from CLI semver** — bumped *only* on
  a breaking `.aid/` layout change, not every release. An `extensions:` key is
  reserved (git forward-compat model) but unused for now.
- The CLI carries `AID_SUPPORTED_FORMAT`. **Fail-safe:** repo stamp **> supported**
  → refuse to operate (newer-format data, git's "must not operate" rule).
- Repo stamp **< supported, or absent** → **needs migration** → warn + offer
  `aid update` (current-repo). An absent stamp = legacy (pre-stamp) repo. This
  **replaces era-by-file-presence detection** (the old era-a/era-b branch) and is
  the lazy catch-all covering repos not in any registry.
- **This stamp is the only migration-done record.** There is no machine marker
  (§3.2); a repo's done-state lives in its own user-writable `.aid/settings.yml`,
  which is why the root-owned-marker re-prompt bug cannot recur.

### 3.5 Self-commands — channel-aware, elevate-when-needed
- `aid update self` / `remove self` detect the channel (`AID_INSTALL_CHANNEL`) and
  run the matching package manager (npm `install -g` / `uninstall -g`, pipx
  `upgrade` / `uninstall`, curl re-bootstrap / `rm` + unwire). (Implemented in
  PR #78.)
- **Auto-elevate only the privileged step** when the install location is not
  writable by the user (root-owned global); user-level prefix / pipx → no sudo.
  The migration scan always runs in the **user** context, never under that sudo.
- `update self` then **migrates the registered repos** (iterates the user +
  shared registries — *no scan*), each **with the per-repo confirmation**
  (All/Yes/No/Cancel). Unregistered repos are caught later by §3.4 (decision #1).

---

## 4. Dispatch rules (scenario matrix)

### A. Global commands — `update self` / `remove self` (cwd-independent)
| install | privileged step | migration |
|---|---|---|
| global | install/uninstall via channel, **auto-elevate** | `update self`: migrate registered repos (confirm each) |
| non-global | via channel, no sudo | same |

### B. `aid add [tool]` — installs AID into cwd (+ registers)
| install | cwd loc | folder write-access | "add as shared?" | result |
|---|---|---|---|---|
| any | inside `~` | (own) | — | install + register → **user** |
| non-global | outside `~` | full | — | install + register → **user** |
| non-global | outside `~` | **no** | — | **error + abort** |
| global | outside `~` | (folder writable) | **yes** | install + register → **shared** (auto-elevate the shared write) |
| global | outside `~` | full | **no** | install + register → **user** |
| global | outside `~` | **no** | **no** | **error** |

Note (decision #3): `aid add` never elevates the `.aid/` *creation* — if the
folder isn't writable, it errors rather than creating root-owned `.aid/`.

### C. Repo-commands — bare `aid`, `status`, `update`, dashboard
| install | cwd `.aid/`? | loc | registered? | stale? | result |
|---|---|---|---|---|---|
| any | yes | inside `~` | no | no | register → user (silent: no decision); operate |
| any | yes | inside `~` | no | yes | register → user; **warn + offer `aid update`**; operate |
| any | yes | any | yes | no | operate |
| any | yes | any | yes | yes | **warn + offer `aid update`**; operate |
| global | yes | outside `~` | no | either | **ask** → register shared (auto-elevate, best-effort) **or** user; [stale→offer update]; operate |
| non-global | yes | outside `~` | no | either | register → user; [stale→offer update]; operate |
| any | **no `.aid/`** | any | — | — | **not an error** — "no AID project here — set it up? (`aid add`)"; if not a git repo, note `.aid/` won't be version-controlled |

There is **no folder where `aid` hard-refuses** except genuine access failures
(B `no`-access rows). git presence is orthogonal — a non-git folder can use AID;
it simply can't persist `.aid/` to version control (a note, never a blocker).

---

## 5. Settled decisions
1. `update self` batch-migrates **registered** repos (no scan), **with per-repo
   confirmation**; unregistered repos migrate lazily on next visit.
2. Registration is **best-effort** — decline/no-TTY/elevation-unavailable →
   skip + warn, still operate. No read-only command force-prompts sudo to index.
3. `aid add` into an unwritable folder → **error** (never elevate `.aid/`
   creation into a root-owned dir).
4. **Always ask** when there's a real decision (shared-vs-user, elevation); the
   only silent path is the unambiguous in-`~` local registration.
5. **git is not required**; a non-git folder uses AID with a no-persistence note.
   Missing `.aid/` is an **offer** to set up (`aid add`), not a hard error.

_(Resolved 2026-06-15 — the former §6 open items:)_

6. **(A) Scope is derived at runtime** from payload-root writability; no
   install-time scope marker. Channel = self-update routing hint only.
7. **(B) CODE/STATE decoupled** into `AID_CODE_HOME` (self-located, read-only)
   and `AID_STATE_HOME` (`${AID_HOME:-<scope default>}`). `AID_HOME` env overrides
   STATE only. Global state default `/var/lib/aid`; non-global `~/.aid`.
8. **(C) Per-repo stamp** = `format_version: <int>` in `.aid/settings.yml`,
   decoupled from CLI semver; fail-safe vs `AID_SUPPORTED_FORMAT`.
9. **(D) Global shared state home = `/var/lib/aid`** (FHS, root-owned,
   world-readable; shared registry writes elevate, best-effort per #2).
10. **(E) v1.0→v1.1 bootstrap is manual, per-repo, no scan** — visiting/`aid
    update`-ing each repo stamps `format_version` + registers it.
11. **(F) The `$AID_HOME/.migrated` machine marker + `$HOME`-walking scan are
    removed.** Migration = lazy per-repo (via the stamp) + batch over *registered*
    repos in `update self`. `.update-check` becomes per-user cache (`~/.aid`).

---

## 6. Implementation notes (decisions in §5.6–§5.11)

**Touch points in the shipped code** (from a current-state audit):

- **Scope + home split** (`bin/aid`, `bin/aid.ps1`): replace the single
  `AID_HOME` resolution (bin/aid:40-47) with `AID_CODE_HOME` (the existing
  self-locate) + `AID_STATE_HOME` (`${AID_HOME:-<scope default>}`, scope derived
  from `AID_CODE_HOME` writability). Repoint every `$AID_HOME`-relative use:
  code-side (`lib/`, `dashboard/` source, `VERSION` — bin/aid:52,178,1113) →
  `AID_CODE_HOME`; state-side (`registry.yml`, `.update-check` — bin/aid:1325,184)
  → `AID_STATE_HOME` (and `.update-check` specifically → `~/.aid`).
- **Per-repo stamp** (`bin/aid`): add `format_version` read/write to the
  `.aid/settings.yml` template (bin/aid:1764-1787) and replace the era-by-presence
  branch (bin/aid:1417-1427) with stamp comparison vs a new `AID_SUPPORTED_FORMAT`
  constant. Migration *writes* the stamp on success.
- **Retire marker + scan** (`bin/aid`): delete `_aid_check_migrate_sentinel`
  (bin/aid:265-307), `_aid_write_migrated_marker` (bin/aid:1876-1890), and the
  `$HOME`-walking `_aid_scan_for_repos` (bin/aid:1802-1850). `update self`'s
  migration iterates the unioned registries (§3.3) instead of scanning; lazy
  per-repo stamp (§3.4) covers the rest.
- **Global state provisioning** (`lib/aid-install-core.sh` + installers): a
  global install creates `/var/lib/aid` (root-owned, world-readable) and writes
  shared `registry.yml` there; shared-registry writes go through `_aid_priv_run`
  (best-effort). Non-global collapses shared==user==`~/.aid`.
- **Bootstrap (this machine + upgraders)**: no scan — visiting/`aid update`-ing
  each known repo (`~/projects/*`, `/srv/projects/*`) stamps + registers it.

**Test-suite migration risk to watch:** many suites pin `AID_HOME` to a throwaway
expecting it to also relocate `lib/`/`VERSION`. After the split those expect
`AID_CODE_HOME`; audit `tests/canonical/*` for `$AID_HOME/lib`, `$AID_HOME/VERSION`,
`$AID_HOME/.migrated` references when implementing.

**Decision D addenda (resolved during /aid-specify, 2026-06-15):**
- **Windows shared-state home = `%ProgramData%\aid`** (`$env:ProgramData\aid`) —
  the Windows analogue of `/var/lib/aid`: machine-wide, app-managed,
  Administrator-written / all-users-readable; symmetric with the per-user
  fallback `$env:LOCALAPPDATA\aid` so the shared↔user collapse works identically
  to POSIX.
- **Provisioning is install-time primary, with a non-prompting runtime fallback
  (HYBRID).** *(Resolved 2026-06-15 after re-analysis; user-confirmed.)* A global
  install is already privileged (root runs `sudo npm i -g` / `sudo curl|bash`), so
  that is the correct, mlocate-faithful moment to create `/var/lib/aid` — and adding
  the install hooks is exactly what "provisioning by the installers" means (this is
  feature-002's job, not a deferral). Hooks: **npm** postinstall `getuid()===0`
  branch (inline `mkdir 0755` + no-clobber seed `schema: 1`/empty `repos:`); **curl**
  `install.sh` root-detected branch (guarded so test `AID_HOME` pins never touch real
  `/var/lib`); **pipx** never (per-user by construction). The **runtime** path in
  `registry_register` is a *best-effort, non-prompting ensure-exists fallback only*
  (never-elevate form; if the shared dir can't be created without elevation, degrade
  to `~/.aid` + warn, `return 0` — a routine `aid add` must NOT sudo-prompt). This
  satisfies AC1 literally ("/var/lib/aid exists when installation completes") whereas
  runtime/lazy-primary did not, and it preserves the best-effort contract (§3.3 #2).
  Old global installs predating the hooks converge on the next root re-install/upgrade;
  the runtime fallback only degrades, it does not self-heal via prompt.

**Still genuinely open (deferrable, not blocking):**
- Optional group-writable shared home (setgid) for non-sudo team registration —
  a future installer knob layered on the `/var/lib/aid` default (Decision D
  chose the FHS default; group sharing can come later).
- Whether `format_version` bumps warrant an `extensions:`-style partial-compat
  mechanism (reserved, unused until a real forward-compat case appears).

## 7. Non-goals
- No machine-wide filesystem scan; no `aid` daemon/service.
- No heavy multi-user concurrency control on the shared registry beyond atomic
  set-insert / prune.
