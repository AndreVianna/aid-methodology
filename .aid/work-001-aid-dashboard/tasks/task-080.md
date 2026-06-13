# task-080: IMPLEMENT — version-sentinel lazy first-run + npm postinstall trigger (FF-4/DM-3/R16) in bin/aid + PS twin + package.json

**Type:** IMPLEMENT

**Source:** feature-011-upgrade-migration → delivery-011

**Depends on:** task-078, task-079

**Scope:**
- Add the **trigger machinery** (FF-4/DM-3, RC-1/RC-3, R16) that runs the FF-2 scan as part of the upgrade.
  Two surfaces feed the **same** task-078 scan: a version-sentinel lazy first-run in `bin/aid` (the
  universal cross-manager guarantee) and an npm `postinstall` (the eager path). In `bin/aid` + `bin/aid.ps1`
  twin (R17 lockstep, ASCII), **serialized** after task-078 and task-079 (same `bin/aid` file — the last of
  the Wave-3 serial chain task-078 → task-079 → task-080; the trigger invokes the task-078 scan). The
  `package.json` edit is a separate file (no `bin/aid` collision) but logically part of this trigger lane.
- **A) VERSION-SENTINEL LAZY FIRST-RUN** (universal: pypi, `--ignore-scripts`, curl). Insert near the
  existing throttled update-notice call site — `_aid_check_update` is defined at **`bin/aid:162`** and
  called at **`bin/aid:1202`** (landing block) and **`bin/aid:1260`** (status tail); the `.update-check`
  cache + `AID_NO_UPDATE_CHECK` opt-out precedent it mirrors is at **`bin/aid:159-160,174`** and the
  VERSION read + `tr -d '[:space:]'` trim idiom at **`bin/aid:168-170`**. Gate identically (TTY/opt-out).
  Logic: if `AID_NO_MIGRATE=1` → skip (mirrors `AID_NO_UPDATE_CHECK`, `bin/aid:164`);
  `installed = trim($AID_HOME/VERSION)`, `marker = trim($AID_HOME/.migrated if present else "")`; if
  `installed != "" AND installed != marker` (string inequality, DD-1) → **advanced**: interactive (TTY) →
  run the task-078 FF-2 scan once (which advances the DM-3 marker on completion); non-interactive →
  `AID_MIGRATE_YES=1` runs FF-2 (opt-in, advances marker) else **annotate**
  `AID hint: AID upgraded to <installed>; run 'aid update self' to migrate your repos.` and **DEFER** (do
  NOT advance the marker — next interactive run re-triggers). `installed == marker` → steady state, no
  trigger (SEC-6 no-loop).
- **DM-3 marker** `$AID_HOME/.migrated`: a single trimmed ASCII version line, resolved by the `$AID_HOME`
  rule (`bin/aid:40-47`). Provide the marker R/W helper (read in the sentinel here; the set-on-completion
  write is shared with task-078's `aid update self` completion). Crash-safe (temp-file + `mv -f`). Absent ≡
  "never migrated" ⇒ any installed version is treated as advanced (first upgrade after this ships triggers).
- **B) npm POSTINSTALL** (eager, on `npm i -g aid-installer`): add a `"postinstall"` script to
  **`packages/npm/package.json`** (`"scripts"` block at `:12`, currently only
  `"prepack": "node scripts/vendor.js"` at `:13`). It runs a node entry that spawns the vendored `bin/aid`
  with `update self` semantics in a **guaranteed non-interactive** context → hits the FF-4(A) no-TTY branch
  → **annotate + DEFER** unless `AID_MIGRATE_YES=1` (NFR12/SEC-1; never silently mutates). Resolve OQ-3
  toward a thin node postinstall entry (e.g. `scripts/postinstall.js`) that inherits `AID_MIGRATE_YES`; the
  invariant (annotate+defer unless opt-in) is fixed. **pypi has NO equivalent** (PEP 517 wheels, grounding
  §3e) → pypi relies entirely on the sentinel (A), the cross-manager guarantee (R16).
- **Cannot loop (SEC-6):** the marker is set to exactly the current `VERSION` once the scan completes
  (task-078); equality thereafter = no trigger. A deferral leaves the marker stale on purpose → one
  retrigger per upgrade until an interactive (or opt-in) scan completes. `AID_NO_MIGRATE=1` disables the
  trigger entirely. PS twin parity throughout (ASCII).

**Acceptance Criteria:**
- [ ] The sentinel is wired near the `_aid_check_update` call site (`bin/aid:1202`/`:1260`), gated by the
      same TTY/opt-out posture, honoring `AID_NO_MIGRATE=1` (skip) and `AID_MIGRATE_YES=1` (non-interactive
      opt-in); the compare is string inequality `installed != marker` (DD-1) reading `$AID_HOME/VERSION`
      vs `$AID_HOME/.migrated` (DM-3, trimmed per `bin/aid:170`).
- [ ] Interactive + advanced → runs the task-078 FF-2 scan once (marker advances on completion);
      non-interactive + advanced → annotates + defers (marker stays stale) unless `AID_MIGRATE_YES=1`;
      `installed == marker` → no trigger (SEC-6 no-loop); absent marker ⇒ treated as advanced.
- [ ] An npm `"postinstall"` is added to `packages/npm/package.json` that spawns vendored `bin/aid update
      self` non-interactively → FF-4(A) no-TTY branch → annotate + defer unless `AID_MIGRATE_YES=1` (OQ-3
      resolved); **no** pypi runtime hook is added (pypi = sentinel-only, R16).
- [ ] The marker write is crash-safe (temp-file + `mv -f`); the trigger cannot loop (SEC-6);
      `AID_NO_MIGRATE=1` disables it; PS twin parity (`test-aid-cli-parity.sh`), ASCII-only, not
      render-drift (C8).
