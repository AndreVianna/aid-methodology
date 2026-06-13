# task-078: IMPLEMENT — aid update self machine scan + All/Yes/No/Cancel consent (FF-2/CLI-1) in bin/aid + PS twin

**Type:** IMPLEMENT

**Source:** feature-011-upgrade-migration → delivery-011

**Depends on:** task-077

**Scope:**
- Add the **machine-scan + consent** behavior to `aid update self` (FF-2/CLI-1), in `bin/aid` + its
  `bin/aid.ps1` twin (R17 lockstep, ASCII-only). **Serialized** against task-077 (same `bin/aid` file) and
  against tasks 079/080 (the other two `bin/aid` writer concerns — Wave-3 serial chain).
- **Insertion seam (RE-PINNED against live `bin/aid`, 1593 lines):** the update-self dispatch branch is
  `bin/aid:1267-1278` — `_cmd_update_self` is called at **`bin/aid:1277`** and `exit $?` follows at
  **`bin/aid:1278`**. Attach the scan **between line 1277 and line 1278** (after the CLI is current, before
  exit). On npm/pypi channels `_cmd_update_self` returns early (`bin/aid:250-259`, the package manager did
  the upgrade) — the scan still runs against the now-current install.
- Add the **`--yes` opt-in alias** to the update-self flag loop (`bin/aid:1270-1276`, where `--force|-y`
  are no-ops at `:1272`): `--yes` presets "apply All" (equivalent to `AID_MIGRATE_YES=1`, RC-3); `--force`/
  `-y` remain self-update no-ops.
- Implement `SCAN_FOR_AID_REPOS` (SEC-2, R19): bounded root set + shallow depth cap, **skips**
  `node_modules/`/`.git/`, **read-only** presence-test detection (`.aid/settings.yml` OR
  `.aid/knowledge/{DISCOVERY_STATE.md|DISCOVERY-STATE.md|STATE.md}` — DD-6), **never** follows `..` or
  symlinks out of scope, emits CAN-1-canonical paths only (SEC-5). Provide a `--root <dir>` override
  (residual OQ-1; the invariant bounded+no-escape+read-only is fixed). Reuse `_registry_read_repos`
  (`bin/aid:1082`) to skip already-fully-compliant repos silently.
- Implement the **All/Yes/No/Cancel** consent walk (FF-2 state machine; CLI-1 exact wording, ASCII):
  prompt `Migrate <repo>? [A]ll / [Y]es / [N]o / [C]ancel:` — **A** sets the `apply_all` flag (migrate
  this + every remaining repo without re-asking); **Y** migrates this repo only then re-prompts; **N**
  SKIPs (do **NOT** migrate, do **NOT** register) and prints
  `Skipped <repo>. Run 'aid update' inside that folder to migrate it later.`; **C** aborts the whole scan
  (`break`) and does **NOT** advance the DM-3 marker. For each consented repo call `_aid_migrate_repo`
  (task-077); a single repo's failure logs `WARN ... continuing` and the scan continues (SEC-4, NFR12
  WARN-not-fail) — never aborts the scan or changes the exit code.
- **Non-interactive guard (RC-3/SEC-1):** before the loop, if NOT a TTY AND NOT (`--yes` OR
  `AID_MIGRATE_YES=1`): annotate the candidate list to stdout (read-only) and **DEFER** — do not mutate,
  do not advance the marker — then `exit 0`. With the opt-in, preset `apply_all=true`.
- **Marker advance (DM-3, FF-2 completion):** on a **completed** scan (every candidate offered:
  migrated/skipped/declined, no Cancel), write the DM-3 marker `$AID_HOME/.migrated` = trimmed
  `$AID_HOME/VERSION` (crash-safe temp-file + `mv -f`; trim exactly as `bin/aid:170` does). On **Cancel**
  or a non-interactive defer, leave the marker **stale** so the FF-4 sentinel (task-080) re-fires next
  interactive run. The marker R/W helper is shared with task-080's trigger (one writer, but the
  set-on-completion call lives here for the `aid update self` reach).
- **Exit code 0** on a completed scan including all-skipped/all-no-op/Cancel (a user-chosen stop is not an
  error); a per-repo migration failure never changes the exit code (NFR12). PS twin parity throughout.

**Acceptance Criteria:**
- [ ] The scan attaches between `_cmd_update_self` (`bin/aid:1277`) and `exit $?` (`bin/aid:1278`) and runs
      after the CLI is current (incl. the npm/pypi early-return channel); `--yes` is added as the opt-in
      alias in the update-self flag loop; PS twin parity (`test-aid-cli-parity.sh`).
- [ ] `SCAN_FOR_AID_REPOS` is bounded + read-only + no-traversal (SEC-2/R19), skips `node_modules`/`.git`,
      detects only via the DD-6 presence-test, never follows `..`/symlinks out of scope, emits CAN-1 paths
      (SEC-5), and offers a `--root` override.
- [ ] The All/Yes/No/Cancel walk matches the CLI-1 wording exactly (ASCII): A=apply-all, Y=this-repo-only,
      N=skip+do-not-register+advisory, C=abort+no-marker-advance; each consented repo runs
      `_aid_migrate_repo`; a single repo failure WARNs and continues (SEC-4).
- [ ] A non-interactive context without `--yes`/`AID_MIGRATE_YES=1` annotates + defers + does NOT advance
      the marker (RC-3/SEC-1); with the opt-in it migrates and advances; the marker advances to trimmed
      `$AID_HOME/VERSION` only on a completed scan, never on Cancel/defer (DM-3).
- [ ] Exit code is 0 on completed/skipped/no-op/Cancel; a per-repo failure never changes it (NFR12); the
      edit is hand-maintained `bin/aid`/`bin/aid.ps1`, ASCII-only, not render-drift (C8).
