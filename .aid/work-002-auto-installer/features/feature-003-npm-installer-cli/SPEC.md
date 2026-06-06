# npm Installer CLI (M3a)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-04 | Feature identified from REQUIREMENTS.md §5 (FR6, FR9), §7, §8 | /aid-interview |

## Source

- REQUIREMENTS.md §5 (FR6, FR9 consumer), §7 (`@aid/installer`), §8

## Description

The Node-audience install channel: a published npm package **`@aid/installer`** runnable via
`npx @aid/installer …`. It is a **thin wrapper** that resolves and downloads the shared release
tarball (feature-002) and delegates to the shared install core (feature-001) — it does **not**
reimplement install logic. It carries `package.json` as a participant in version synchronization
(feature-005) and owns acquisition/verification of the `@aid` npm scope.

## User Stories

- As a Node developer, I want to run `npx @aid/installer --tool claude-code` so that I can install AID with the tooling I already have and a registry-integrity guarantee.

## Priority

Must (P1 — required install experience; built after the foundation)

## Acceptance Criteria

- [ ] Given a developer with Node, when they run `npx @aid/installer` (auto-detect or `--tool`), then AID is installed/updated from the shared release tarball with the same result as the other channels.
- [ ] The CLI delegates to the shared install core (no duplicated install logic).
- [ ] The package is published under the `@aid` scope and participates in version sync (`package.json` reconciled by feature-005).

## Dependencies

- **feature-001** (shared core to delegate to), **feature-002** (tarball to fetch). Parallelizable with feature-004. npm provenance publishing lands in feature-005.

---

## Technical Specification

> **Authored by:** /aid-specify (Architect), 2026-06-04. Grounded against the live repo state
> (`VERSION`=`0.7.0`; five `profiles/<tool>/` trees; no `package.json` anywhere — confirmed by
> `technology-stack.md` Package Manager) and the **authoritative** contracts in
> feature-001's Technical Specification (CLI surface, canonical tool ids, exit codes, manifest
> schema, **shared-core delegation contract**) and feature-002's artifact contract (tarball
> naming, asset URLs, `SHA256SUMS`). **This feature does NOT redefine any of those — it mirrors
> them.** Where a flag, exit code, or tool id appears below, it is quoted verbatim from
> feature-001 and any drift is a feature-001 decision, not a 003 decision.

### S0. Scope of this feature (what 003 owns vs. what it consumes)

This feature is the **npm/npx install channel (M3a)**: a published npm scoped package
`@aid/installer`, runnable as `npx @aid/installer …`. Per FR9 and feature-001's
**shared-core delegation contract**, it is a **thin wrapper** — it parses its own CLI, then
**shells out to the bootstrap CLI** (`bash install.sh …` on Unix /
`pwsh -NoProfile -ExecutionPolicy Bypass -File install.ps1 …` on Windows) with the normalized
flags. It contains **zero install logic**: no copy, no
protect-on-diff, no manifest read/write, no host-tool detection, no tarball fetch/extract — all
of that lives in feature-001's `install.sh`/`install.ps1` + `lib/*` and runs inside the spawned
process. The Node layer is a **platform-shell selector + arg passthrough + exit-code relay**.

| Concern | Owner | This feature does |
|---------|-------|-------------------|
| Install/update/uninstall logic, host-tool detection, copy semantics, protect-on-diff (FR11), manifest, exit-code definitions | **feature-001** | **Delegates** to `install.sh`/`install.ps1`; never reimplements. |
| Tarball naming (`aid-<tool>-v<VERSION>.tar.gz`), asset URLs, `SHA256SUMS`, the fetch contract | **feature-002** | Not touched directly by the Node layer — the **spawned bootstrap** performs the fetch. 003 only needs to ship the bootstrap so it can fetch. |
| FR10 version reconciliation (git tag ⇆ `VERSION` ⇆ `package.json` ⇆ `pyproject.toml`) | **feature-005** | **Declares** `package.json` `version` MUST equal `VERSION`; feature-005 reconciles + fails CI on drift. Not redefined here. |
| npm publish automation, `--provenance`, OIDC Trusted Publishing | **feature-005** | **References** the manual `npm publish --access public` path + the §8 scope/token prereqs; the automated/provenance publish is feature-005. |
| PyPI channel (M3b, `aid-installer` via pipx) | **feature-004** | Parallel sibling; same delegation contract. Out of scope here. |

### S1. Package identity & `package.json` shape (003 OWNS)

A single npm **scoped** package. Name and bin per REQUIREMENTS §7 (`@aid/installer`) and the
delegation contract.

- **Name:** `@aid/installer` (scoped under the `@aid` org — §8 prerequisite, see S8).
- **`bin`:** one executable named **`aid-installer`** mapped to `./bin/aid-installer.js`. Running
  `npx @aid/installer` resolves the package's single bin and runs it; running
  `npx @aid/installer@0.7.0` pins a version. (Single-bin packages let `npx <pkg>` work without
  naming the bin.)
- **`version`:** equals the AID `VERSION` file content (currently `0.7.0`) — see S6 (FR10).
- **`engines.node`:** `>=18` — see S5 for the rationale (matches `technology-stack.md` Node 18+
  baseline; nothing here needs newer).
- **`type`:** `commonjs` (explicit). The bin uses only Node built-ins (`child_process`, `os`,
  `path`, `fs`, `process`) — no ESM-only need, no third-party deps (preserves AID's
  zero-npm-dependency posture for the *code*; the package itself is the first published
  `package.json`, which `technology-stack.md` notes as "no `package.json` at any level" — this
  feature introduces exactly one, for this package only).

```json
{
  "name": "@aid/installer",
  "version": "0.7.0",
  "description": "Install AID (Agentic Iterative Development) into a repo. Thin npm wrapper over the cross-platform install bootstrap.",
  "bin": { "aid-installer": "bin/aid-installer.js" },
  "type": "commonjs",
  "engines": { "node": ">=18" },
  "files": [
    "bin/",
    "install.sh",
    "install.ps1",
    "lib/",
    "VERSION",
    "README.md",
    "LICENSE"
  ],
  "repository": { "type": "git", "url": "git+https://github.com/AndreVianna/aid-methodology.git" },
  "homepage": "https://github.com/AndreVianna/aid-methodology#readme",
  "bugs": { "url": "https://github.com/AndreVianna/aid-methodology/issues" },
  "license": "<repo LICENSE id — read from repo root LICENSE at packaging time>",
  "keywords": ["aid", "agentic", "installer", "claude-code", "codex", "cursor", "copilot-cli", "antigravity"],
  "dependencies": {}
}
```

Notes:
- **`dependencies` is empty** by design. The bin is pure Node built-ins. This keeps the package
  install-time-dependency-free (nothing to audit, no supply-chain surface beyond AID's own files)
  and aligns with the no-third-party-runtime-deps posture (`technology-stack.md`).
- **`files`** is an allowlist: it ships **`bin/`** (the Node wrapper) plus the **vendored**
  `install.sh`, `install.ps1`, `lib/`, and the `VERSION` marker (see S2). It deliberately does
  **not** ship `node_modules`, tests, or `.aid/`.
- The package root for npm is **a subdirectory of the AID repo** (proposed: `packages/npm/` — the
  build copies/symlinks the repo-root `install.sh`, `install.ps1`, `lib/`, `VERSION` into the
  package payload at pack time; exact staging mechanics are a feature-005 packaging concern, but
  the **payload contract** — that these files are present in the tarball — is owned here). The
  canonical sources of the vendored files remain the repo-root copies feature-001 authors.

### S2. Vendoring vs. fetching — DECISION: vendor the bootstrap, spawn it per-platform

**Decision: the published npm tarball VENDORS feature-001's `install.sh`, `install.ps1`, and
`lib/` (the core libs `aid-install-core.sh` + `AidInstallCore.psm1`), and the Node `bin` SPAWNS
the right script for the host platform.** The Node layer never reimplements install behavior and
never reaches across the language boundary into core functions — it execs the **bootstrap CLI**,
exactly as feature-001's delegation contract mandates ("003/004 do **not** call individual core
functions across the language boundary … They call the **bootstrap CLI**").

**Why vendor (chosen):**
1. **Self-contained, versioned, offline-from-cache.** The published `@aid/installer@0.7.0`
   tarball carries the exact bootstrap+core bytes for that version. Once npm has cached the
   package, `npx @aid/installer` runs the install logic without re-downloading the *scripts*
   (the bootstrap still fetches the **profile tarball** from the GitHub Release at run time for
   the online path — that network step is feature-001/002's, unchanged; see S3/S8 risk on `npx`
   first-fetch). The version of the bootstrap is pinned to the package version — no skew between
   "the wrapper" and "the logic it runs."
2. **Single canonical logic (FR9) preserved.** The vendored files are the **same** `install.sh`/
   `install.ps1`/`lib/*` feature-001 authors (copied verbatim at pack time, not forked). There is
   one source of truth; the npm tarball is a transport, not a second implementation.
3. **No cross-language FFI.** Node→`bash`/`pwsh` is a process boundary with a stable CLI, exactly
   the "stable contract surface" feature-001 enumerates (flag names, tool ids, exit codes,
   manifest path/schema, `--from-bundle` semantics).

**Why NOT the alternatives:**
- **Fetch-the-tarball-and-reimplement-copy-in-JS (REJECTED):** would duplicate copy semantics,
  protect-on-diff (FR11), manifest, and detection in JavaScript — a third canonical
  implementation alongside Bash and PowerShell. **Directly violates FR9** ("single canonical
  install logic reused by all surfaces; no duplicated install logic") and the AC "The CLI
  delegates to the shared install core (no duplicated install logic)." Rejected.
- **Fetch the bootstrap scripts at run time from the GitHub Release instead of vendoring
  (REJECTED):** adds a network dependency just to obtain the scripts, breaks the
  pinned-version guarantee, and offers no benefit over vendoring (the bootstrap *itself* already
  fetches the profile tarball online or reads `--from-bundle` offline). Vendoring is strictly
  better for reproducibility and cache-offline behavior.

**Payload layout inside the published package:**
```
@aid/installer/
  package.json
  bin/aid-installer.js     # the Node wrapper (003 owns)
  install.sh               # vendored verbatim from repo root (feature-001 owns source)
  install.ps1              # vendored verbatim from repo root (feature-001 owns source)
  lib/aid-install-core.sh  # vendored verbatim (feature-001 owns source)
  lib/AidInstallCore.psm1  # vendored verbatim (feature-001 owns source)
  VERSION                  # vendored verbatim; bin reads it for --version reporting / sanity
  README.md  LICENSE
```
The bin resolves these via `path.join(__dirname, '..')` (package root), so they are found
relative to the installed package regardless of the adopter's CWD.

### S3. Arg mapping — `npx @aid/installer …` → bootstrap invocation (003 OWNS the mapping)

The Node bin accepts the **same flag vocabulary** feature-001 defines (it does not invent flags)
and passes them through **1:1** to the spawned bootstrap. Because the flags are already
identical to feature-001's Bash spelling, the Unix path is a near-verbatim passthrough; the
Windows path translates the same flags to `install.ps1`'s PowerShell parameter spelling.

**Accepted flags (mirrors feature-001's authoritative CLI table verbatim):**
`--tool <name>[,<name>...]`, `--version <v>`, `--from-bundle <path>`, `--force`, `--update`,
`--uninstall`, `--target <dir>` (and trailing positional `<target-dir>`), `-h`/`--help`.
**Canonical tool ids** accepted unchanged: `claude-code`, `codex`, `cursor`, `copilot-cli`,
`antigravity`.

**The Node bin does NOT parse flag semantics** beyond two jobs: (a) it must spot `-h`/`--help`
to optionally print a short wrapper banner *and then still forward `--help` so the bootstrap
prints its authoritative usage*, and (b) it forwards everything else **opaquely** as an argv
array. It deliberately does **not** validate `--tool` values, mutual-exclusion
(`--from-bundle` + `--version`), or target existence — **the bootstrap is the single validator**
so the wrapper can never drift from feature-001's rules. (Doing otherwise would re-encode
feature-001 logic in JS and risk divergence.)

**Unix invocation (Linux/macOS/git-bash):**
```
bash <pkgroot>/install.sh <forwarded argv…>
```
e.g. `npx @aid/installer --tool codex --version 0.7.0` →
`bash <pkgroot>/install.sh --tool codex --version 0.7.0`.

**Windows invocation (canonical argv — IDENTICAL to feature-004):**
```
pwsh -NoProfile -ExecutionPolicy Bypass -File <pkgroot>/install.ps1 <translated argv…>
```
e.g. `npx @aid/installer --tool codex --version 0.7.0` →
`pwsh -NoProfile -ExecutionPolicy Bypass -File <pkgroot>\install.ps1 -Tool codex -Version 0.7.0`.
`-ExecutionPolicy Bypass` is required so the vendored `.ps1`, run via `-File`, is not blocked by
the machine's execution policy. When `pwsh` is absent, fall back to `powershell` with the **same**
flags: `powershell -NoProfile -ExecutionPolicy Bypass -File <pkgroot>\install.ps1 …`.

**Flag translation table (Unix passthrough ↔ Windows `install.ps1` params, both from
feature-001's CLI table):**

| `npx @aid/installer` (== `install.sh`) | Windows → `install.ps1` |
|----------------------------------------|--------------------------|
| `--tool <name[,name]>` | `-Tool <name[,name]>` |
| `--version <v>` | `-Version <v>` |
| `--from-bundle <path>` | `-FromBundle <path>` |
| `--force` | `-Force` |
| `--update` | `-Update` |
| `--uninstall` | `-Uninstall` |
| `--target <dir>` / trailing `<dir>` | `-TargetDirectory <dir>` |
| `-h` / `--help` | `-Help` |

`--from-bundle`, `--update`, `--uninstall` are **pure passthrough** — the wrapper has no special
handling; it forwards them and the bootstrap does the work (offline extract / manifest-driven
update / manifest-driven removal). The trailing positional target is forwarded as-is on Unix; on
Windows it is forwarded as `-TargetDirectory <dir>`.

**Argument safety:** the bin spawns with **`spawnSync(cmd, argvArray, {stdio:'inherit'})`** —
argv is passed as an **array, never a concatenated shell string**, so paths/values with spaces
or shell metacharacters are not re-interpreted by a shell (no `shell:true`). stdin/stdout/stderr
are inherited so the bootstrap's `Copied:` / `Up to date:` / `Updated:` / warning lines and any
prompts reach the user unchanged.

### S4. Cross-platform shell resolution (003 OWNS)

The bin selects which interpreter to spawn from `process.platform`:

1. **`process.platform === 'win32'`** → use PowerShell. Resolve in order: `pwsh` (PowerShell 7+,
   preferred), then `powershell` (Windows PowerShell 5.1, the `technology-stack.md` floor). Probe
   with a cheap `spawnSync('<exe>', ['-NoProfile','-Command','$PSVersionTable.PSVersion.Major'])`
   (or `where pwsh`). If neither resolves → **exit 1 (generic runtime failure)** with:
   `aid-installer: PowerShell not found. Install PowerShell 5.1+ (https://aka.ms/powershell) and re-run.`
2. **Otherwise (linux/darwin, and git-bash/MSYS where `process.platform` is still reported per
   the Node build)** → use **`bash`**. Resolve `bash` on `PATH` (`spawnSync('bash',['-c','exit 0'])`
   or check via `which`). If absent → **exit 1 (generic runtime failure)** with:
   `aid-installer: bash not found. Install Bash 4+ (or git-bash on Windows) and re-run.`
3. The chosen interpreter is invoked as in S3. The script path is the **vendored** copy under the
   package root, resolved via `__dirname`.

Rationale grounded in feature-001's delegation contract, which states the wrapper "detects the
platform and calls `pwsh -File install.ps1 …` (or `powershell -File`); on Unix it calls `bash
install.sh …`." This section implements exactly that detection, adding the explicit
shell-missing error path. A missing interpreter is a runtime/environment condition, so it maps
to **exit 1 (generic runtime failure)** per feature-001's exit-code table — not exit 2, which
feature-001 reserves for usage errors.

**No WSL requirement** (consistent with feature-001): on Windows the native PowerShell path runs
`install.ps1`; bash is *not* required on Windows.

### S5. Minimum Node version — DECISION: `node >=18`

`engines.node: ">=18"`. Justification:
- `technology-stack.md` already lists **Node 18+** as the AID baseline ("Node.js 18+ (optional —
  only `/aid-summarize` uses it)"). Reusing that floor avoids introducing a *new* version axis;
  this feature simply makes Node a prerequisite **for this channel only** (the curl/tar channels
  remain Node-free).
- The bin uses only long-stable built-ins (`child_process.spawnSync`, `os.platform`, `path`,
  `fs.existsSync`, `process.platform/argv/exit`) — all available far below 18; 18 is chosen for
  alignment, not because a newer API is needed.
- 18 is an active/maintained LTS line as of authoring; pinning the floor to the documented AID
  baseline keeps the prerequisite predictable. (If feature-005 later wants a higher floor for
  provenance tooling, that is a feature-005 reconciliation, not a 003 redefinition.)

`engines` is advisory by default (npm warns, does not hard-fail, unless the adopter sets
`engine-strict`); no defensive runtime version check is added in the bin (the built-ins are
universally present), so no extra gate is needed.

### S6. Version sync participation (FR10 — owned by feature-005)

`package.json` `version` **MUST equal** the AID `VERSION` file (currently `0.7.0`) at publish
time, so `npx @aid/installer` and `npx @aid/installer@<VERSION>` resolve the bootstrap of the
matching release. **feature-005 owns FR10**: it reconciles `git tag ⇆ VERSION ⇆ package.json ⇆
pyproject.toml` and **fails CI on drift**. This feature only **declares the constraint** and
ships the vendored `VERSION` marker in the payload (S2) so the bin can sanity-report/assert the
vendored bootstrap matches the package version if desired. It does **not** redefine the FR10
reconciliation algorithm. (feature-002 independently guarantees `VERSION` ⇆ tag ⇆ tarball names;
this feature adds the `package.json` ⇆ `VERSION` edge for feature-005 to enforce.)

### S7. Publishing (manual path; automation referenced, not redefined)

**Manual first-release path (until feature-005's CI lands):**
```
npm publish --access public
```
run from the staged package root, after `npm pack` produces the expected tarball (smoke-check the
`files` allowlist contains `install.sh`, `install.ps1`, `lib/*`, `VERSION`, `bin/aid-installer.js`
and **excludes** tests/`.aid/`). `--access public` is required for a **scoped** package's first
publish (scoped packages default to restricted).

**Prerequisites (REQUIREMENTS §8 — referenced, not owned here):**
- The **`@aid` npm scope/org must exist and be owned** by the maintainer (§8 "Verify
  availability/ownership"). This is a precondition flagged as an **open question** (S9).
- **Publish credentials:** an npm token, or — **preferred** — **OIDC Trusted Publishing** from
  GitHub Actions to avoid long-lived secrets (§8). The token/OIDC wiring and the **`--provenance`**
  flag belong to **feature-005**'s CI release automation (FR8). This feature does **not** add
  `--provenance` to the manual path or define the OIDC flow; it only notes the manual
  `npm publish --access public` works once the scope + a token exist, and that feature-005
  upgrades this to a provenance-attested, OIDC-authenticated publish.

### S8. Testing (per repo conventions; wrapper-focused)

The bin shells out, so tests exercise **arg mapping, exit-code propagation, and platform-shell
selection** with the **bootstrap stubbed** — they do not re-test feature-001's install behavior
(that has its own `tests/canonical/test-install.sh`).

Following `tests/canonical/test-*.sh` conventions (auto-discovered by `tests/run-all.sh`,
`source ../lib/assert.sh`, `mktemp -d` workdirs, exit 0/1) and the **skip-if-tool-absent**
pattern used by `test-setup-ps1.sh`, add **`tests/canonical/test-npm-installer.sh`**, which
**SKIPs (exit 0) when `node` is absent** so the suite stays green on hosts without Node (mirrors
the `pwsh`-skip pattern; the CI `canonical-tests` job, which asserts the toolchain is present,
catches real failures):

- **AM01 arg passthrough (Unix):** stub `install.sh` on `PATH`/package root with a script that
  echoes its argv to a file; run `node bin/aid-installer.js --tool codex --version 0.7.0`; assert
  the recorded argv is exactly `--tool codex --version 0.7.0` (1:1, order preserved, no extra/
  dropped flags).
- **AM02 spaces/metachars:** `--target "/tmp/has space/dir"` → the stub records a single argv
  element `/tmp/has space/dir` (proves array-spawn, no shell re-split).
- **AM03 passthrough of each mode:** `--update`, `--uninstall`, `--from-bundle <p>`, `--force`,
  comma-list `--tool codex,cursor` each reach the stub unchanged.
- **AM04 exit-code relay:** stub exits with each of `0,1,2,3,4,5,6` (feature-001's codes); assert
  the Node bin exits with the **same** code each time (the relay returns the child's exit status;
  on signal-termination, exit `1`).
- **AM05 help:** `--help` reaches the stub (so the bootstrap's authoritative usage prints); the
  bin exits 0.
- **AM06 platform selection (mockable):** with `AID_INSTALLER_PLATFORM=win32` (a test-only
  override of the `process.platform` branch), assert the bin selects the PowerShell path and
  translates `--tool→-Tool`, `--version→-Version`, etc., per S3's table; default (no override)
  selects `bash`. (The override exists solely for testability of the Windows branch on Linux CI,
  mirroring how `test-install-ps1.sh` exercises platform-independent paths on Linux.)
- **AM07 missing-shell error:** point the shell-resolver at a non-existent interpreter (test
  override of the probe) → bin exits **1** (generic runtime failure) with the documented message.
- **AM08 packaging smoke:** `npm pack --dry-run` (or parse `package.json` `files`) asserts the
  published set includes `install.sh`, `install.ps1`, `lib/aid-install-core.sh`,
  `lib/AidInstallCore.psm1`, `VERSION`, `bin/aid-installer.js` and excludes `tests/`, `.aid/`.
- **AM09 version sync:** assert `package.json` `version` == repo-root `VERSION` content (a cheap
  local guard; feature-005 owns the authoritative CI gate).

Because the bin is pure Node built-ins, the test harness is a thin Bash driver invoking `node`
with stub scripts — no test framework or npm devDependency is added (preserves the
zero-dependency posture). An **end-to-end** test (real `install.sh`, real fixture tarball via
`--from-bundle`) is **optional/redundant** here since feature-001's suite already covers install
behavior; one happy-path E2E (`node bin/aid-installer.js --tool codex --from-bundle <fixture>`
against a temp target, asserting the tool tree + manifest land) is recommended as a single
integration smoke to prove the wrapper actually reaches a real bootstrap.

### S9. Risks / open questions (flag for /aid-specify Q&A where noted)

1. **`npx` offline / first-run network behavior (VERIFY — research-flagged UNCERTAIN).** `npx
   @aid/installer` must **download the package from the npm registry on first use** unless it is
   already in the npm cache (`npx --prefer-offline` needs a prior cache hit; `npx --offline`
   fails without one). So the "offline" story has two layers: (a) obtaining the *package* (needs
   npm registry or a pre-seeded cache — not air-gap-friendly on first run), and (b) obtaining the
   *profile tarball* (the bootstrap's `--from-bundle` handles this with no network). True air-gap
   installs should prefer the curl/tar channel (M1/M2) or `npm i -g @aid/installer` from a
   pre-fetched tarball, then run the bootstrap with `--from-bundle`. **Verify the exact `npx
   --offline`/`--prefer-offline` semantics against current npm docs before build** and document
   the recommended air-gap path. *(Research said "verify against npm docs"; carry it forward.)*
2. **Windows `pwsh` vs `powershell` availability.** Windows 10/11 ship Windows PowerShell 5.1
   (`powershell`) but **not** PowerShell 7 (`pwsh`) by default. The resolver (S4) tries `pwsh`
   then falls back to `powershell`, so the default-shipped 5.1 works — matching feature-001's
   5.1+ floor. Confirm `install.ps1` runs correctly under 5.1 (feature-001 asserts it does);
   no action for 003 beyond the fallback ordering. *(Low risk; covered by S4.)*
3. **`@aid` scope ownership (BLOCKER for publish — §8 open).** Publishing `@aid/installer`
   requires the `@aid` npm org/scope to exist and be maintainer-owned. REQUIREMENTS §8 flags this
   "Verify availability/ownership." If `@aid` is unavailable, a fallback name (e.g.
   `aid-installer` unscoped, or `@<owner>/aid-installer`) must be chosen — which would change the
   `npx` command string in docs. **Decision needed before publish.** *(Q&A candidate → routed to
   feature-005 / owner, since 005 owns the publish step; 003's design is name-agnostic except for
   the literal `@aid/installer` in `package.json`.)*
4. **Whether to also support `npm i -g @aid/installer` (global install).** The single-bin package
   works fine globally (`aid-installer --tool …` on `PATH` after a global install) at no extra
   cost — the same `bin` entry serves both `npx` and `-g`. **Recommendation: support both
   implicitly** (no extra code; document `npx` as primary, `-g` as the "I run this often / want
   it cached/offline-ish" path). Flagged so docs name both. *(Low risk; recommend yes.)*
5. **`package.json` is the repo's FIRST `package.json` (KB contract drift).**
   `technology-stack.md` asserts the contract "No npm `package.json` at any level." Adding one
   under `packages/npm/` for this published package **breaks that stated contract**. This is an
   intended, scoped change (one package manifest, no `node_modules`, empty `dependencies`), but
   the KB doc's `contracts:` entry and the project-structure attestation must be refreshed by the
   KB-housekeep cycle post-merge. **Not hand-edited in this delivery** (KB carve-out, mirroring
   feature-001's handling of `setup.sh` reference updates), but **flagged** so the housekeep cycle
   reconciles it. *(KB Q&A → `.aid/knowledge/STATE.md` candidate.)*
6. **Provenance on the manual path (DEFERRED to feature-005).** The manual `npm publish
   --access public` (S7) does **not** carry `--provenance` (which needs an OIDC-authenticated CI
   context). REQUIREMENTS §6/§8 require the *published* package to carry provenance — satisfied by
   feature-005's automated publish, **not** the manual bootstrap path. The manual path is the
   pre-005 stopgap (parity with feature-002's manual `gh release create`). Confirm the first
   public release waits for feature-005's provenance publish, or accepts a provenance-less manual
   first publish. *(Q&A candidate for the owner.)*
