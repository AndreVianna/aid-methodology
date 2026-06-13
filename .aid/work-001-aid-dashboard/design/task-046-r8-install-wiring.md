# task-046 — R8 install-wiring research: pin the `$AID_HOME/dashboard/` layout + vendor/install blast radius

**Type:** RESEARCH (read-only analysis; no production code modified)
**Resolves:** R8 (PLAN.md:352) — feature-010/delivery-008 precondition.
**Verdict:** **PROCEED** as a bounded co-vendor task (task-047). Delta list attached below.

---

## 1. Confirmed baseline (the gap is real)

| Claim | Status | Evidence |
|---|---|---|
| `dashboard/` vendored into npm | NO | `packages/npm/scripts/vendor.js:27-34` copies exactly 6 files (bin/aid{,.ps1,.cmd}, lib/{aid-install-core.sh,AidInstallCore.psm1}, VERSION). `package.json:16-22` `files` = `bin/ lib/ VERSION README.md LICENSE` only. |
| `dashboard/` vendored into pypi | NO | `packages/pypi/scripts/vendor.py:36-43` — same 6 files into `aid_installer/_vendor/{bin,lib}`. |
| `find packages -path '*dashboard*'` empty | CONFIRMED | Ran it; no output. |
| install-core places `dashboard/` under `$AID_HOME` | NO | `install.sh:715-748` stages+copies only `bin/aid{,.ps1,.cmd}`, `lib/aid-install-core.sh`, `VERSION` into `$AID_HOME`. install.ps1 mirrors (`install.ps1:156` LibDir, AidHome bin/lib). No `dashboard/` ever written. |
| release CLI bundle carries `dashboard/` | NO | `release.sh:300-322` — bundle is the same 6 files, flat root. |
| Today's `aid dashboard start` runs from the **served repo**, not `$AID_HOME` | CONFIRMED | `bin/aid:872-879`: `assets_dir="${target}/dashboard"`, `entry_point="${assets_dir}/server/server.{py,mjs}"` where `target` is the project being served (`--target`/cwd). This is exactly MEMORY "dashboard not install-wired": it works only from a repo checkout. |

So the feature-010 requirement (a machine-wide server in `$AID_HOME/dashboard/` serving *all* registered repos via `--root`) has **zero** existing wiring. Co-vendoring is non-optional (PLAN R8).

---

## 2. The runtime import constraints (what the vendored unit must satisfy)

**Python** (`dashboard/server/server.py:33-41`):
```
_SERVER_DIR   = .../dashboard/server/        # Path(__file__).resolve().parent
_DASHBOARD_DIR= .../dashboard/               # _SERVER_DIR.parent
_ASSETS_DIR   = _DASHBOARD_DIR               # index.html lives here
_INDEX_HTML   = _DASHBOARD_DIR/"index.html"
sys.path.insert(0, str(_DASHBOARD_DIR))      # add dashboard/ to path
from reader import read_repo                 # resolves dashboard/reader/ PACKAGE
```
- `from reader import read_repo` resolves the **package** `dashboard/reader/` via `reader/__init__.py` (`reader/__init__.py:9` `from .reader import read_repo`).
- `reader/` uses **relative intra-package imports**: `reader.py:27-38` (`from .locator`, `from .models`, `from .parsers`), `parsers.py:21-33` (`from .models`, `from .derivation`), `derivation.py:58` (`from .models`). → the **entire `dashboard/reader/` directory** must be co-located as a package; you cannot vendor a single `reader.py` file.
- All reader Python imports are **stdlib-only** (`json, re, pathlib, typing, dataclasses, enum, datetime`) — no third-party deps to package.

**Node** (`dashboard/server/server.mjs:37,87-93`):
```
import { readRepo } from "./reader.mjs";              // SIBLING of server.mjs
const __dirname = dirname(fileURLToPath(import.meta.url));  // dashboard/server/
const INDEX_HTML_PATH = join(__dirname, "..", "index.html"); // dashboard/index.html
```
- `reader.mjs` must sit **inside `server/`** (sibling of `server.mjs`). The repo already has it at `dashboard/server/reader.mjs`.
- `reader.mjs` imports only `fs`/`path` (`reader.mjs:15-16`) — stdlib-only, no `node_modules`, no `package.json` needed.
- `index.html` resolved at `dashboard/index.html` (one level up from `server/`).

**Conclusion:** if the vendored tree preserves the exact shape `dashboard/{index.html, reader/<py package>, server/{server.py,server.mjs,reader.mjs}}`, then **every relative import + the `index.html` sibling-resolution holds with ZERO source edits to the import lines.** No import-shim is required.

> Stale-test note: `test-aid-dashboard-cli.sh:49,98` still references a flat `dashboard/reader.py` + `dashboard/__init__.py` that do not exist (the package is `dashboard/reader/`); those symlink lines are dead no-ops guarded by `[[ -f ]]`. Tracked as delta D12.

---

## 3. The pinned `$AID_HOME/dashboard/` target layout

The Python package `reader/` is a **sibling of `server/`** (because `server.py` puts `dashboard/` on `sys.path` then does `import reader`). The Node reader `reader.mjs` is **inside `server/`** (because `server.mjs` does `./reader.mjs`).

```
$AID_HOME/
├── bin/                            (existing — aid, aid.ps1, aid.cmd)
├── lib/                            (existing — aid-install-core.sh, AidInstallCore.psm1)
├── VERSION                         (existing)
└── dashboard/                      ← NEW co-vendored unit
    ├── index.html                  ← GET / (Python: dashboard/index.html; Node: ../index.html)
    ├── reader/                     ← Python package (sys.path=dashboard/ → `import reader`)
    │   ├── __init__.py
    │   ├── reader.py
    │   ├── models.py
    │   ├── parsers.py
    │   ├── derivation.py
    │   └── locator.py
    └── server/
        ├── server.py               ← python entry: `import reader` (sibling reader/ via sys.path)
        ├── server.mjs              ← node entry: `./reader.mjs` + `../index.html`
        ├── reader.mjs              ← Node reader (sibling of server.mjs)
        └── __init__.py             ← present in repo; harmless, keep for package-shape parity
```

**Why every import resolves unchanged:**
- Python: `server.py` inserts `…/dashboard` on `sys.path`, then `import reader` finds `…/dashboard/reader/__init__.py`. ✔
- Python intra-package: relative `from .models` etc. resolve within `reader/`. ✔
- Python index: `_DASHBOARD_DIR/"index.html"` = `…/dashboard/index.html`. ✔
- Node: `./reader.mjs` = `…/dashboard/server/reader.mjs`. ✔
- Node index: `join(__dirname,"..","index.html")` = `…/dashboard/index.html`. ✔

**Explicitly EXCLUDE** from the vendored payload (cleanliness; these exist in the repo tree): `__pycache__/`, `.pytest_cache/`, `*.pyc`, `reader/tests/`, `server/tests/` (incl. `tests/fixtures/`), `dashboard/README.md` (optional). The vendor step must copy a **curated file list**, not `cp -r dashboard/` (which would ship test fixtures + caches into every install — same posture as vendor.js/vendor.py's explicit COPIES list).

**Vendored file manifest (the curated unit — 11 files):**
```
dashboard/index.html
dashboard/reader/__init__.py
dashboard/reader/reader.py
dashboard/reader/models.py
dashboard/reader/parsers.py
dashboard/reader/derivation.py
dashboard/reader/locator.py
dashboard/server/server.py
dashboard/server/server.mjs
dashboard/server/reader.mjs
dashboard/server/__init__.py
```

---

## 4. Blast-radius delta list (concrete; task-047 executes without re-discovery)

Two packaging surfaces (npm, pypi) + the from-source install path (install.sh / install.ps1 / release.sh) + the spawn seam + tests. **14 deltas, 11 vendored files.**

### Packaging surface — npm
- **D1.** `packages/npm/scripts/vendor.js:27-34` — copy the 11 dashboard files into `packages/npm/dashboard/…` (add a curated dashboard list; preserve subtree shape). Update the clean-slate block (`vendor.js:36-42`) to also `rmSync` `packages/npm/dashboard`. Update the "6 files vendored" log line (`vendor.js:70`).
- **D2.** `packages/npm/package.json:16-22` — add `"dashboard/"` to the `files` array so npm packs it.

### Packaging surface — pypi
- **D3.** `packages/pypi/scripts/vendor.py:36-43` — copy the 11 files into `aid_installer/_vendor/dashboard/…`. Update clean-slate (`vendor.py:50`), the build-hook `sources_present`/`missing` checks (`vendor.py:89,95`) to include the dashboard sources, and the "6 files" log (`vendor.py:66`).
- **D4.** pypi packaging config — ensure the wheel/sdist ships `_vendor/dashboard/`. Verify `packages/pypi/pyproject.toml` (hatch `force-include`/`artifacts`/inclusion glob for `aid_installer/_vendor`) and `MANIFEST.in` if present; add `aid_installer/_vendor/dashboard` to whatever inclusion mechanism currently ships `_vendor/`. (vendor.py is a build hook, but the inclusion glob must cover the new subtree.)

### From-source install path (curl|bash, irm|iex, local repo install)
- **D5.** `release.sh:285-322` — the `aid-cli-v<VERSION>.tar.gz` bundle (extraction root == `$AID_HOME` layout) must add the 11 dashboard files under `dashboard/…` to `CLI_BUNDLE_STAGE` and to the explicit `--no-recursion` tar file-list (`release.sh:315-321`). Without this, piped-bootstrap installs get no dashboard.
- **D6.** `install.sh:711-748` — the bootstrap staging+atomic-move step must stage `dashboard/` (from `${SCRIPT_DIR}/dashboard` or the extracted CLI bundle `${_AID_CLI_BUNDLE_EXTRACT_DIR}/dashboard`) and copy it into `${AID_HOME}/dashboard`. Add to the clean-replace block (`install.sh:737-739`) so upgrades replace it cleanly (`rm -rf "${AID_HOME}/dashboard"` before copy).
- **D7.** `install.ps1` — mirror D6 in PowerShell (the bootstrap staging block around the bin/lib/VERSION placement; Resolve-AidHome + copy section ~572-660). ASCII-only (CI-guarded per MEMORY). PS source-of-truth `dashboard/` copy + clean-replace.

### Spawn seam (bin/aid — task-047's behavioral change; this research bounds it)
- **D8.** `bin/aid:871-879` (`_dc_start`) — change `assets_dir="${target}/dashboard"` to resolve the entry-point from **`$AID_HOME/dashboard`** (`assets_dir="${AID_HOME}/dashboard"`), and keep passing `--root "$target"` (already passed at `bin/aid:890`) so the install-tree server serves the requested repo. This is the seam relocation feature-010 needs; the `--root` plumbing already exists. Update the missing-entry error message (`bin/aid:881`) to point at `aid update`/reinstall.
- **D9.** `bin/aid.ps1` — mirror D8 (PLAN R10: bin/aid.ps1 carries the same spawn change). ASCII-only.

### Tests
- **D10.** `tests/canonical/test-npm-installer.sh:238-243` (NM08 "npm pack --dry-run lists the 6 vendored files") — extend the expected-file list to include the 11 `dashboard/…` files; assert the dashboard server entry-points are present in the pack.
- **D11.** `tests/canonical/test-pypi-installer.sh:209-230` (PW05 "_vendor byte-identical to the 6 repo sources") — extend the `pairs` list to assert the 11 dashboard files are vendored byte-identical (drift gate).
- **D12.** `tests/canonical/test-aid-dashboard-cli.sh:48-99` — fixture builder must be updated for the new layout: today it symlinks `${target}/dashboard/server/{server.py,server.mjs}` + a non-existent flat `dashboard/reader.py`. For D8's `$AID_HOME`-relative resolution, place the full curated `dashboard/` tree under **AID_HOME** (not the served repo), staging the real `reader/` package + `reader.mjs`. Replace the dead `DASHBOARD_READER_PY`/`DASHBOARD_INIT_PY` symlink lines (`:49,98`) with a real package copy.
- **D13.** `tests/canonical/test-aid-cli-parity.sh` — per PLAN R10, extend to cover the spawn-seam change (entry-point now `$AID_HOME/dashboard`, not repo) for both bin/aid and bin/aid.ps1.
- **D14.** `tests/canonical/test-dashboard-parity.sh` (PT-1 cross-runtime byte-parity) — confirm it invokes the servers from the new vendored location, or is layout-agnostic. Likely invokes entry-points by explicit path; verify the path source after D8. Low-risk; may need no change.

**Optional/verify-only (not counted):** `test-release-install-e2e.sh`, `test-install.sh`, `test-install-parity.sh` — these assert tool-bundle (`.claude` etc.) installs, not the CLI bundle's `$AID_HOME` payload; verify they don't hard-assert the absence of `dashboard/`.

---

## 5. VERDICT — **PROCEED** (bounded co-vendor task)

**One-paragraph rationale.** Every import constraint resolves with **zero source edits** once the curated 11-file `dashboard/` unit is laid out in its existing repo shape under `$AID_HOME` — the Python `sys.path`-insert + `import reader` package, the Node `./reader.mjs` sibling, and the `../index.html` resolution all hold unchanged because both readers are **stdlib-only** (no `node_modules`, no PyPI deps to package) and the directory shape is already correct in the repo. The blast radius is a **bounded, mechanical co-vendor**: it extends the same explicit-COPIES pattern that vendor.js (`:27-34`) and vendor.py (`:36-43`) already use, adds one `files`/inclusion-glob entry per packaging surface, threads the unit through the three install paths (release bundle + install.sh + install.ps1) that already stage bin/lib/VERSION the same way, and flips one `assets_dir` line in bin/aid + bin/aid.ps1 (the spawn seam, with `--root` already plumbed). No new packaging *capability* is invented — no new build system, no dependency resolution, no manifest-schema change, no native module, no third-party-tree distribution. Total: **14 deltas (11 vendored files)**, all following established patterns, all CI-coverable by extending existing parity/installer suites. This is squarely inside the PLAN R8 "co-vendor unit" budget and does **not** balloon the spine. Strongest single piece of evidence that it's bounded: the entire payload is **stdlib-only on both runtimes** (`reader.mjs:15-16` imports only `fs`/`path`; the Python reader imports only stdlib), so co-vendoring is a file-copy + path-resolution problem, not a dependency-distribution problem.

**Honest caveat (does not change the verdict):** D8/D9 (spawn-seam relocation from served-repo to `$AID_HOME`) is a genuine *behavioral* change, not pure packaging — but the PLAN already scopes it to task-047 (R10) and the `--root` argument is already passed, so it is one-line-per-shell plus its parity test, correctly inside d008. If during task-047 the pypi inclusion mechanism (D4) turns out to require a build-backend change rather than an additive glob (verify `pyproject.toml` first), re-evaluate — that is a within-task contingency, not a reason to escalate now.

---

## 6. Hand-off to task-047 (CONFIGURE)

Execute D1–D14 above. Curated 11-file unit + pinned layout in §3. Exclude `__pycache__/.pytest_cache/tests/*.pyc`. Re-run after edits: full installer/parity CI (`test-npm-installer.sh`, `test-pypi-installer.sh`, `test-aid-dashboard-cli.sh`, `test-aid-cli-parity.sh`, `test-dashboard-parity.sh`) — push and rely on remote CI (MEMORY: installer tests need a Windows runner). ASCII-only for bin/aid.ps1 + install.ps1 edits.
