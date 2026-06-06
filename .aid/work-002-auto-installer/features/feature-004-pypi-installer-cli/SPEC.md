# PyPI Installer CLI (M3b)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-04 | Feature identified from REQUIREMENTS.md §5 (FR7, FR9), §7, §8 | /aid-interview |

## Source

- REQUIREMENTS.md §5 (FR7, FR9 consumer), §7 (PyPI org), §8

## Description

The Python-audience install channel: a published PyPI package runnable via `pipx run aid …`,
published under a **CasuloAI Labs** PyPI org. Like the npm CLI, it is a **thin wrapper** over the
shared release tarball (feature-002) and the shared install core (feature-001) — no duplicated
logic. It carries `pyproject.toml` as a version-sync participant (feature-005). This feature owns
a hard external prerequisite: **the CasuloAI Labs PyPI org is not yet registered** — registration
and package-name reservation must happen before publishing.

## User Stories

- As a Python / data / AI developer, I want to run `pipx run aid-installer --tool claude-code` so that I can install AID with my existing toolchain and registry-integrity guarantees.

## Priority

Must (P1 — required install experience; built after the foundation. Carries an external registration blocker.)

## Acceptance Criteria

- [ ] Given a developer with Python/pipx, when they run `pipx run aid-installer` (or `pipx run --spec aid-installer aid`) with auto-detect or `--tool`, then AID is installed/updated from the shared release tarball with the same result as the other channels.
- [ ] The CLI delegates to the shared install core (no duplicated install logic).
- [ ] The CasuloAI Labs PyPI org is registered and the package name reserved before publishing.
- [ ] The package participates in version sync (`pyproject.toml` reconciled by feature-005).

## Dependencies

- **feature-001**, **feature-002**. Parallelizable with feature-003. **External blocker:** PyPI CasuloAI Labs org registration (not yet done). PyPI Trusted-Publishing attestation lands in feature-005.

---

## Technical Specification

> **Authored by:** /aid-specify (Architect). Grounded against feature-001's authoritative
> contract (CLI surface, canonical tool ids, exit codes, manifest schema, **shared-core
> delegation contract**) and feature-002's artifact contract. **Symmetric with feature-003**
> (npm CLI): identical vendor-and-shell-out strategy, identical arg mapping, identical
> exit-code propagation — the two CLIs are the same wrapper in two package ecosystems, differing
> only in packaging (`pyproject.toml`/`subprocess`/`argparse` here vs `package.json`/`child_process`
> there). Any behavioral divergence from feature-003 is a bug. Live-repo grounding (2026-06-04):
> `technology-stack.md` confirms Python 3.11+ is a **build-time** dep (renderer/`tomllib`) and that
> AID ships **stdlib-only** Python with **no `pyproject.toml` anywhere** — this feature introduces
> the first `pyproject.toml` and the first end-user Python install surface.

### S0. Scope of this feature (the PyPI/pipx channel, M3b)

This feature owns the **Python-audience install channel**: a PyPI-published wrapper, runnable via
`pipx run`, that **delegates 1:1 to feature-001's bootstrap** (`install.sh` / `install.ps1`). It is a
**thin wrapper** (FR7, FR9): it does **not** reimplement any install logic (no extract, no copy, no
protect-on-diff, no manifest, no host detection — all of that lives in feature-001's shared core).

What this feature owns:

1. The `pyproject.toml` (package identity, build backend, console entry, `requires-python`) — S1.
2. The **vendor-and-shell-out** wrapper module + console script — S2/S3.
3. The arg-mapping + exit-code-propagation contract from the Python CLI to the bootstrap — S4.
4. Cross-platform shell resolution (bash vs pwsh) — S5.
5. The pipx/pip UX surface + offline caveats — S6.

What it explicitly does NOT own (referenced, not redefined): install/extract/copy/manifest/uninstall
logic (**feature-001**); the release tarball + `SHA256SUMS` (**feature-002**); FR10 version
reconciliation across `VERSION`/`package.json`/`pyproject.toml` and the tag-triggered publish +
Trusted-Publishing attestation (**feature-005**); the npm sibling channel (**feature-003**).

### S1. Package identity and `pyproject.toml`

#### S1.1 Package name and the `pipx run` invocation (SETTLED, with a naming nuance)

The settled primary UX is **`pipx run aid-installer`** (with `pipx run --spec aid-installer aid` as
the exact alt). pipx's `run` resolves its first positional as **both the PyPI package to fetch and the
console-script (app) name** to execute, unless `--spec` overrides the package. Two ways the short
`pipx run aid` form could have been honored:

- **(A) PyPI package named `aid`** + a console script also named `aid` → `pipx run aid` would work bare.
  Risk: the bare name `aid` is a generic, high-contention PyPI name and is **almost certainly
  unavailable / squatted** on the public index. Not relied upon. (Bare `pipx run aid` does **not**
  resolve under the settled package name `aid-installer`.)
- **(B) PyPI package named `aid-installer`** (symmetric with npm's `aid-installer` per REQUIREMENTS §7)
  + a console script named `aid`. Bare `pipx run aid` would then try to fetch a *package* named `aid`
  (wrong); the correct invocation is **`pipx run --spec aid-installer aid`**. To still offer the
  short form, **also declare a second console script `aid-installer`** so `pipx run aid-installer`
  works with no `--spec` (package name == app name, pipx's happy path).

**Decision: (B), package `aid-installer`.** Rationale: (1) symmetry with the npm package name
`aid-installer` (REQUIREMENTS §7 / feature-003) — one memorable name across both ecosystems;
(2) the bare `aid` PyPI name is unreservable in practice; (3) reserving `aid-installer` under the
CasuloAI Labs org is feasible. The **console entry point is `aid`** (so the *binary* a user types is
`aid`, matching the npm bin and the `pipx run --spec aid-installer aid` form), with `aid-installer`
as a second entry alias so `pipx run aid-installer` also works. Documentation leads with
**`pipx run --spec aid-installer aid --tool …`** (exact, copy-pasteable) and notes
`pipx run aid-installer --tool …` as the shorter no-`--spec` form. *(Q&A candidate: if the owner
can reserve the bare `aid` PyPI name under CasuloAI Labs, switch to option (A) and the docs collapse
to `pipx run aid`. Flagged below.)*

#### S1.2 `pyproject.toml` shape (SETTLED)

A single `pyproject.toml` at **repo root** (first one in the repo; `technology-stack.md` Package
Manager confirms none exists today). PEP 621 metadata + a PEP 517 build backend.

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "aid-installer"
version = "0.7.0"                       # == VERSION file; reconciled by feature-005 (FR10)
description = "One-command installer for the AID methodology (PyPI/pipx channel)."
readme = "README.md"
requires-python = ">=3.8"               # wrapper is pure stdlib; see S1.3
license = { text = "MIT" }              # match repo LICENSE; confirm in feature-005
authors = [{ name = "CasuloAI Labs" }]
keywords = ["aid", "installer", "ai-agents", "methodology"]
dependencies = []                       # NO third-party runtime deps (stdlib only) — S2

[project.scripts]
aid = "aid_installer.__main__:main"           # primary binary: `aid`
aid-installer = "aid_installer.__main__:main" # alias so `pipx run aid-installer` needs no --spec

[project.urls]
Homepage = "https://github.com/AndreVianna/aid-methodology"
Repository = "https://github.com/AndreVianna/aid-methodology"
Issues = "https://github.com/AndreVianna/aid-methodology/issues"

[tool.hatch.build.targets.wheel]
packages = ["aid_installer"]
# Vendored bootstrap shipped as package data — S2.
artifacts = ["aid_installer/_vendor/**"]
```

- **`version`** is the bare `VERSION` content (`0.7.0`), matching the tag `v<VERSION>` (feature-002 S4)
  and the npm `package.json` version (feature-003). **feature-005 owns reconciliation** (FR10) — this
  spec only states the equality; it does not implement the sync (referenced, not redefined).
- **Build backend `hatchling`** is a *build-time* dependency only (in `[build-system].requires`,
  resolved in the build venv by `python -m build`); it is **not** an adopter runtime dep. (Alternative
  `setuptools` is equally acceptable and changes nothing observable; `hatchling` chosen for simpler
  package-data/artifacts handling. Settle finally in feature-005's publish job.)
- **`dependencies = []`** is load-bearing: the wrapper is **pure stdlib** (`argparse`, `subprocess`,
  `sys`, `os`, `shutil`, `pathlib`, `platform`), consistent with AID's stdlib-only Python stance
  (`technology-stack.md` Frameworks & Libraries) and symmetric with feature-003 (Node built-ins only).

#### S1.3 `requires-python`

`>=3.8`. The wrapper uses only long-stable stdlib (`argparse`, `subprocess.run`, `shutil.which`),
so it does **not** need the 3.11+ floor the *generator* needs (`tomllib`, per `technology-stack.md`).
A low floor maximizes the pipx-able audience: this channel only *shells out* to the bootstrap; it does
not run the renderer. (The 3.11+ generator requirement is a maintainer/build concern, not an
adopter-install concern — confirmed by the research M3b note that Python-for-install is **not** required
today and this channel is what changes that for Python users.) *(Q&A candidate: confirm `>=3.8`
vs a higher floor; lower is friendlier and carries no cost here.)*

### S2. Vendor-and-shell-out design (SYMMETRIC WITH feature-003)

Per feature-001's **Shared-core delegation contract**: "003/004 do **not** call individual core
functions across the language boundary … They call the **bootstrap CLI**." This feature implements
exactly that — the Python package **vendors** the bootstrap scripts as package data and **spawns** the
right one per platform via `subprocess`, passing the normalized flags through 1:1.

#### S2.1 Package layout

```
pyproject.toml                       # repo root (S1.2)
aid_installer/
  __init__.py                        # version string mirror (optional)
  __main__.py                        # console-script entry: main()  (S3)
  _vendor/                           # vendored bootstrap = feature-001 payload (S2.2)
    install.sh
    install.ps1
    lib/aid-install-core.sh
    lib/AidInstallCore.psm1
```

`aid_installer/_vendor/` holds a **verbatim copy** of feature-001's `install.sh`, `install.ps1`, and
the `lib/` core (`aid-install-core.sh`, `AidInstallCore.psm1`). These are **bundled as package data**
(`[tool.hatch.build.targets.wheel].artifacts`) so the installed wheel contains runnable scripts.
**Symmetry with feature-003:** feature-003 vendors the same four files into its npm tarball; both
channels carry the identical bootstrap and both **shell out** to it. The vendored copy is **stamped
at build/release time** from the repo-root `install.*`/`lib/*` — feature-005's release job is the
authoritative stamper so npm and PyPI ship byte-identical bootstraps at the same version. *(Risk R2:
vendored-copy drift — mitigated by build-time stamping; see Risks.)*

#### S2.2 Why vendor-and-shell-out (not a Python reimplementation) — FR9, SETTLED

- **FR9 mandates single canonical install logic.** Reimplementing extract/copy/protect-on-diff/manifest
  in Python would create a **third** parallel implementation (alongside the Bash and PowerShell cores),
  violating FR9 ("no 4× duplication") and guaranteeing behavioral drift on the exact files FR11 guards.
  Rejected.
- **Delegation keeps one source of truth.** The wrapper's *only* responsibility is: parse a Python-side
  CLI, locate the vendored bootstrap, pick the platform script, exec it with the same flags, propagate
  its exit code. All install semantics (host detection, `--from-bundle`, protect-on-diff, manifest,
  exit codes 0–6) come from feature-001 unchanged.
- **Identical to the npm wrapper.** This is deliberately the same shape as feature-003 so the two
  channels cannot diverge in behavior.

### S3. Console-script entry (`aid_installer/__main__:main`)

A pure-stdlib `main()` that mirrors feature-003's wrapper behavior:

1. **Parse args with `argparse`** in **pass-through** style. The wrapper does **not** re-validate the
   install semantics — it accepts feature-001's flags and forwards them. Use a permissive parser
   (`parse_known_args`, or a flat definition of every flag in S4) so unknown/future bootstrap flags
   pass through rather than erroring at the Python layer. `-h/--help` prints a short wrapper banner
   **and** then forwards `--help` to the bootstrap so the authoritative usage (feature-001's header
   block) is what the user sees.
2. **Resolve the vendored bootstrap dir** via `importlib.resources` (or `Path(__file__).parent /
   "_vendor"`), so it works from an installed wheel and a `pipx run` ephemeral venv.
3. **Select the platform script** (S5): Unix → `bash <vendor>/install.sh`; Windows → the canonical
   `pwsh -NoProfile -ExecutionPolicy Bypass -File <vendor>/install.ps1` (fallback `powershell` with
   the identical flags/order) — the single Windows spawn argv shared byte-for-byte with feature-003.
4. **Build argv** (Unix: `[bash, install.sh, *forwarded_flags]`; Windows: `[<pwsh|powershell>,
   -NoProfile, -ExecutionPolicy, Bypass, -File, install.ps1, *forwarded_flags]`, per S5) and run via
   `subprocess.run(argv, check=False)`. Stdout/stderr are **inherited** (not captured) so the
   bootstrap's `Copied:` / `Up to date:` / protect-on-diff warnings reach the user verbatim.
5. **Propagate the exit code:** `sys.exit(completed.returncode)` (S4.2). No remapping.

The module follows `coding-standards.md §3e` Python conventions (shebang-style header comment,
`from __future__ import annotations`, type hints, `pathlib.Path`, stdlib-only).

### S4. Arg mapping + exit-code propagation (IDENTICAL to feature-003)

#### S4.1 Flag mapping — 1:1, Unix spelling forwarded verbatim

The Python CLI accepts feature-001's **Bash** flag spellings (the canonical contract) and forwards
them **unchanged** to whichever script it spawns. On Windows, the wrapper translates the Unix flag
names to the PowerShell parameter spellings feature-001 defines, because `install.ps1` uses
PowerShell `-Param` names:

| User passes (Python CLI) | Forwarded to `bash install.sh` | Forwarded to `pwsh -NoProfile -ExecutionPolicy Bypass -File install.ps1` |
|---|---|---|
| `--tool <name[,name…]>` | `--tool <v>` | `-Tool <v>` |
| `--version <v>` | `--version <v>` | `-Version <v>` |
| `--from-bundle <path>` | `--from-bundle <path>` | `-FromBundle <path>` |
| `--force` | `--force` | `-Force` |
| `--update` | `--update` | `-Update` |
| `--uninstall` | `--uninstall` | `-Uninstall` |
| `--target <dir>` (or trailing positional) | `--target <dir>` / positional | `-TargetDirectory <dir>` |
| `-h` / `--help` | `--help` | `-Help` |

- **Canonical tool ids** accepted unchanged: `claude-code`, `codex`, `cursor`, `copilot-cli`,
  `antigravity` (and comma-lists), normalized by feature-001 — the wrapper does **not** validate them
  (it forwards; the bootstrap is the single validator). This keeps the wrapper from drifting out of
  sync with feature-001's tool vocabulary.
- The Unix→PowerShell flag translation is a **fixed table** identical to feature-003's, ensuring the
  two wrappers map flags the same way. (Same approach as feature-003: forward Unix spellings on Unix,
  translate to `-Param` on Windows.)

#### S4.2 Exit-code propagation — verbatim, no remap

`main()` returns the bootstrap's exit code unchanged so feature-001's contract surfaces through PyPI:

| Code | Meaning (from feature-001) |
|------|----------------------------|
| 0 | Success (install/update/uninstall; "nothing to do" is success). |
| 1 | Generic runtime failure. |
| 2 | Usage error (unknown flag, missing value, ambiguous/undetectable tool, bad `--target`, mutually-exclusive flags). |
| 3 | Network/fetch failure (download or `/latest` resolution failed, no `--from-bundle`). |
| 4 | Checksum verification failed. |
| 5 | Protect-on-diff blocked a root agent file without `--force`. |
| 6 | Uninstall found no manifest. |

The exit codes the wrapper itself originates (before/instead of spawning) are: **exit 1** if no
platform shell is found (S5) — a missing interpreter is a runtime/environment error, matching
feature-001's convention (2 = usage, 1 = generic runtime) and **feature-003's npm wrapper, which
returns exit 1 for the same missing-shell condition**; and **exit 2** for a wrapper-level usage error
(unknown flag / missing value the wrapper itself rejects pre-spawn). Everything the bootstrap can
decide is left to the bootstrap. (Symmetric with feature-003, which likewise originates only the
no-shell (exit 1) / usage (exit 2) error and otherwise propagates.)

### S5. Cross-platform shell resolution

`main()` picks the interpreter by `platform.system()` (or `os.name`) and verifies presence with
`shutil.which`:

- **Unix/macOS/Linux** (`os.name == "posix"`): require `bash` (matches feature-001's Bash 4+ floor).
  `shutil.which("bash")` → spawn `bash <vendor>/install.sh …`. If absent → **exit 1** (missing
  interpreter = runtime/environment error, matching feature-003 and feature-001's 1 = generic runtime
  convention) with `aid-installer: 'bash' not found on PATH; the AID installer requires bash` (stderr).
- **Windows** (`os.name == "nt"`): prefer `pwsh` (PowerShell 7+, cross-platform), fall back to
  `powershell` (Windows PowerShell 5.1+, matching feature-001's floor). `shutil.which("pwsh") or
  shutil.which("powershell")` selects the interpreter, then spawn the **single canonical Windows
  spawn argv shared with feature-003**:

  ```
  pwsh -NoProfile -ExecutionPolicy Bypass -File <vendor>/install.ps1 <args…>
  ```

  with `powershell` substituted for `pwsh` (same flags, same order) when `pwsh` is absent. The flag
  order — `-NoProfile -ExecutionPolicy Bypass -File` — is **byte-identical to feature-003's**
  PowerShell spawn argv; this is the one canonical form both channels emit, so the wrapper runs the
  vendored script without a per-machine policy prompt or profile interference. Any deviation in this
  argv (flags, order, or interpreter selection) from feature-003 is a bug. If neither interpreter is
  present → **exit 1** (missing interpreter = runtime/environment error, matching feature-003 and
  feature-001's 1 = generic runtime convention) with a clear `PowerShell (pwsh/powershell) not found`
  message.
- A user may run the Python CLI under `pwsh` on Linux (CI parity, per feature-001's no-WSL design), but
  the **default** Unix path is `bash install.sh`. (Symmetric with feature-003.)

The vendored `.ps1`/`.sh` are read-only package data; the wrapper never edits them, only spawns them.

### S6. pipx / pip UX and offline behavior

#### S6.1 Primary UX — `pipx run` (ephemeral)

```bash
# exact (no --spec needed because app==package for this alias):
pipx run aid-installer --tool claude-code
# explicit-spec form (binary is `aid`):
pipx run --spec aid-installer aid --tool claude-code
```

`pipx run` creates a throwaway isolated venv, installs `aid-installer` from PyPI, runs the `aid`/
`aid-installer` console script, then discards the venv — the cleanest "try without installing" UX and
the one REQUIREMENTS §3 maps to the Python audience.

#### S6.2 Secondary UX — persistent install

```bash
pipx install aid-installer      # persistent isolated app; `aid --tool …` thereafter
pip install --user aid-installer
```

Both are noted as supported; `pipx install` gives a clean isolated uninstall (`pipx uninstall
aid-installer`). These remove the *wrapper*, not an AID install in a target repo — AID itself is
uninstalled via the wrapper's `--uninstall` (which forwards to the bootstrap's manifest-driven
uninstall, feature-001).

#### S6.3 Offline / air-gapped caveat (FLAG — "verify" item)

- **`pipx run` is NOT offline-capable by default**: it must fetch `aid-installer` from PyPI on first
  use unless the wheel is already in pipx's/pip's cache or a local index is configured. This is a real
  limitation of the channel and is called out per the task's "verify offline behavior" item.
- **The install itself can still be offline** via the **bootstrap's** `--from-bundle <tarball|dir>`
  (feature-001 / feature-002) — but obtaining the *wrapper package* offline (pre-cached wheel, vendored
  wheel, or local PyPI mirror) is the adopter's responsibility. For a fully air-gapped install, the
  recommended path remains **M2's `--from-bundle`** directly (REQUIREMENTS §3, "offline tar is the
  recommended path for security review"), not the pipx channel.
- Summary: `--from-bundle` works through the wrapper (the flag forwards to the bootstrap), but the
  **wrapper acquisition** still needs PyPI/cache. Documented as a known constraint, not a defect.

### S7. Version sync (FR10 — feature-005-owned; referenced)

`pyproject.toml`'s `version` MUST equal the `VERSION` file (`0.7.0`), the git tag `v<VERSION>`
(feature-002 S4), and the npm `package.json` version (feature-003). **feature-005 owns FR10
reconciliation** — the tag-triggered workflow stamps/asserts all four in lockstep and fails CI on a
mismatch. This feature only **declares** the equality and the field location; it does not implement the
sync or the CI gate. (Referenced, not redefined.)

### S8. Publishing (feature-005-owned; referenced + BLOCKER called out)

- **Build:** `python -m build` (PEP 517) produces the sdist + wheel; the wheel includes
  `aid_installer/_vendor/` package data (S2.2). The vendored bootstrap is stamped from the repo-root
  `install.*`/`lib/*` at release time (feature-005).
- **Publish:** to PyPI under the **CasuloAI Labs** org via **Trusted Publishing (OIDC, sigstore
  attestations)** — REQUIREMENTS §6/§8, the same posture as npm `--provenance`. **The Trusted-Publishing
  configuration and the publish job are owned by feature-005** (tag-triggered, one tag → all channels);
  this feature does not author CI.
- **HARD PREREQUISITE / BLOCKER (REQUIREMENTS §7, §8; this feature's AC):** the **CasuloAI Labs PyPI
  org is NOT yet registered**, and the package name `aid-installer` is **not yet reserved**. Both must
  be done before any publish:
  1. Register the CasuloAI Labs organization/account on PyPI (`pypi.org`).
  2. Reserve the `aid-installer` project name under that org.
  3. Configure Trusted Publishing (the GitHub repo + workflow as a trusted publisher) — coordinated
     with feature-005.
  Until (1)+(2) are done, **feature-004 cannot ship** even though the wrapper code is complete and
  testable locally. This is the channel's external blocker (mirrors npm's `@aid`/`aid-installer`
  scope-acquisition prerequisite in feature-003 — but here the org itself does not exist yet, a
  strictly larger gap).

### S9. Testing approach

Follows `tests/canonical/test-*.sh` conventions where shelling out, and stdlib-only Python tests for
the wrapper logic. The wrapper is hermetic-testable **without** PyPI or network by exercising the
vendored bootstrap against temp targets — and **without** even the real bootstrap by stubbing it.

- **TW01 — flag forwarding (Unix):** stub `bash` (or a fake `install.sh`) that echoes its argv; assert
  the Python CLI forwards `--tool`, `--version`, `--from-bundle`, `--force`, `--update`, `--uninstall`,
  `--target` verbatim, including comma-lists and trailing-positional target.
- **TW02 — flag translation (Windows path):** with `os.name`/`platform.system` monkeypatched to
  Windows and a stub `pwsh`, assert Unix flags are translated to `-Tool/-Version/-FromBundle/-Force/
  -Update/-Uninstall/-TargetDirectory` per S4.1 — proving symmetry with feature-003's table.
- **TW03 — exit-code propagation:** stub bootstrap returns each of 0–6; assert the Python CLI's exit
  code equals it unchanged (S4.2).
- **TW04 — shell resolution errors:** with `shutil.which` returning `None`, assert exit 1 (missing
  interpreter = runtime error, matching feature-003) + the expected stderr message (Unix: no `bash`;
  Windows: no `pwsh`/`powershell`).
- **TW05 — vendored-payload presence:** assert the built wheel (or `aid_installer/_vendor/`) contains
  `install.sh`, `install.ps1`, `lib/aid-install-core.sh`, `lib/AidInstallCore.psm1`, and that they are
  **byte-identical** to the repo-root sources at build time (parity gate against drift — R2).
- **TW06 — end-to-end through the real vendored bootstrap (Unix):** run the Python CLI with
  `--from-bundle <fixture-tarball> --tool codex --target <tmp>` against feature-002's fixture tarball
  (no network), and assert the same install result as feature-001's own `test-install.sh` (delegation
  is real, not mocked). Network `/latest` paths stay stubbed/skipped (rate-limit flakiness, per
  feature-001 Risks).
- **TW07 — help passthrough:** `aid --help` prints the bootstrap's authoritative usage (forwarded),
  exit 0.
- **PowerShell parity** is exercised via the same skip-if-no-`pwsh` pattern feature-001 uses; on CI
  where `pwsh` is asserted present, TW02's Windows-path translation runs against a real `pwsh -File`.

These mirror feature-003's wrapper tests one-for-one (same cases, Python idiom), so the two channels'
test suites assert the same forwarding/propagation contract.

### S10. Risks / open questions

1. **R1 — CasuloAI Labs PyPI org not registered (BLOCKER, EXTERNAL).** The channel cannot publish until
   the org is registered and `aid-installer` reserved (S8). Code is complete/testable without it, but
   **delivery of M3b is gated** on this human/admin step. *(Hard prerequisite; surfaced to the owner.)*
2. **R2 — vendored-bootstrap drift.** The PyPI package and the npm package each vendor their own copy
   of `install.*`/`lib/*`; a stale copy ships an old installer. Mitigation: feature-005's release job is
   the single stamper (copies repo-root sources into both packages at release time), and **TW05**
   asserts byte-identity at build. Without that gate, the vendored copy could silently lag feature-001.
3. **R3 — pipx is a two-step prerequisite (UX, research-flagged).** `pipx` is **not** installed with
   Python by default (`pip install --user pipx` or `brew install pipx` first), per the research M3b note.
   This makes the Python channel a heavier on-ramp than the curl/M2 path. Mitigation: docs state the
   prerequisite; `pipx install`/`pip install --user` are offered as alternatives; M2 remains the
   zero-prereq default.
4. **R4 — `pipx run` not offline by default (S6.3).** Wrapper acquisition needs PyPI/cache even though
   the *install* can use `--from-bundle`. Documented as a known constraint; air-gapped users are pointed
   at M2 `--from-bundle` directly. **Verify** the exact pipx cache behavior before publishing the docs.
5. **R5 — bare `aid` name unavailable (S1.1).** `pipx run aid` requires either the (squatted) bare
   `aid` PyPI name or `--spec aid-installer`. Resolved by shipping an `aid-installer` console-script
   alias (so `pipx run aid-installer` needs no `--spec`) and leading docs with the explicit form.
   *(Q&A: if the owner secures the bare `aid` PyPI name under CasuloAI Labs, switch and simplify docs.)*
6. **R6 — `requires-python` floor (S1.3).** Proposed `>=3.8`; lower is friendlier and costless for a
   pure-stdlib `subprocess` wrapper. *(Q&A: confirm floor; not a blocker.)*
7. **R7 — license field.** `pyproject.toml` `license` must match the repo `LICENSE`; confirmed/reconciled
   by feature-005's publish job. *(Low; confirm before first publish.)*
