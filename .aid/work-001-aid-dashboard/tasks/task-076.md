# task-076: CONFIGURE — vendor dashboard/home.html into both manifests + CI source↔copy equality gate (LC-VND/FR40)

**Type:** CONFIGURE

**Source:** feature-011-upgrade-migration → delivery-011

**Depends on:** task-075

**Scope:**
- Add `dashboard/home.html` to **both** vendor manifests so it installs to `$AID_HOME/dashboard/home.html`
  (LC-VND, FR40 — the single vendored source the migration ADD step copies per repo):
  - `packages/npm/scripts/vendor.js` — add `['dashboard/home.html', 'dashboard/home.html']` to the `copies`
    array (currently 11 entries shown at `:48-58`; `dashboard/index.html` is at `:48`); also extend the
    header-comment manifest listing (`:19-29`) for parity with the existing documented set.
  - `packages/pypi/scripts/vendor.py` — add `("dashboard/home.html", "dashboard/home.html")` to the
    `COPIES` list (`:57-67`; `index.html` at `:57`); extend the header-comment listing (`:23-33`).
  - This is **additive** — do not disturb the existing 17-file vendor set; the new entry lands at the
    vendored path `$AID_HOME/dashboard/home.html` exactly like `dashboard/index.html` does today.
- Wire the **CI source↔copy equality gate** (R20/OQ-5, DD-5): a check that
  `dashboard/home.html` **byte-equals** `.aid/dashboard/home.html` and **fails the build** on any
  divergence (the dogfood copy drifting from the source). Implement as a small canonical test
  (e.g. `tests/canonical/test-home-html-equality.sh`, mirroring the existing `tests/canonical/` shell-test
  shape) so it runs in the same gate suite as `test-ascii-only.sh` / `test-aid-cli-parity.sh`. Resolve
  OQ-5 toward the **CI-equality-check** option (the stronger gitignore-and-generate alternative is not
  required); the invariant (single source of truth, copy equality enforced) is fixed.
- **No pypi runtime install hook** — PEP 517 wheels have none (grounding §3e); pypi relies on vendoring +
  the sentinel trigger (task-080). This task does **not** add the npm `postinstall` (that is task-080's
  trigger lane — `packages/npm/package.json` is its writer; keep the writers separate to avoid a same-file
  collision on `package.json`).
- The vendored files are hand-maintained — the new `home.html` entry is **not** render-drift /
  `run_generator.py` (C8); confirm `dashboard/home.html` is **absent** from `canonical/EMISSION-MANIFEST.md`.

**Acceptance Criteria:**
- [ ] `dashboard/home.html` is present in **both** vendor manifests' copy lists
      (`packages/npm/scripts/vendor.js` `copies`, `packages/pypi/scripts/vendor.py` `COPIES`) and, after a
      vendor run, lands at the vendored `$AID_HOME/dashboard/home.html` path (verified by task-082's
      vendor-refresh assertion); the existing 17-file set is undisturbed (additive only).
- [ ] A CI equality gate asserts `dashboard/home.html` byte-equals `.aid/dashboard/home.html` and **fails**
      on divergence (R20/OQ-5, DD-5), runnable in the canonical gate suite.
- [ ] No pypi runtime install hook is added (PEP 517, grounding §3e); the npm `postinstall` is **not**
      added here (owned by task-080 — `package.json` single writer).
- [ ] `dashboard/home.html` is confirmed **absent** from `canonical/EMISSION-MANIFEST.md` (not
      render-drift, C8).
