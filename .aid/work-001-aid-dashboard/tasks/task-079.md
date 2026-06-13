# task-079: IMPLEMENT — aid update [<tool>] current-repo migration + self-update preamble (FF-3/CLI-2) in bin/aid + PS twin

**Type:** IMPLEMENT

**Source:** feature-011-upgrade-migration → delivery-011

**Depends on:** task-077, task-078

**Scope:**
- Add the **current-repo migration** to the `aid update [<tool>...]` reach (FF-3/CLI-2), in `bin/aid` + its
  `bin/aid.ps1` twin (R17 lockstep, ASCII). **Serialized** after task-078 (same `bin/aid` file; Wave-3
  serial chain — depends on task-078 to land its edits first, builds on the task-077 core). **No machine
  scan, no consent prompt** (the operator invoking `aid update` inside the repo *is* the consent).
- **Insertion seam (RE-PINNED against live `bin/aid`):** the `add|update` success tail is at
  **`bin/aid:1542`** (`add|update)` case) → `Done.` echo **`bin/aid:1563`** → existing
  `registry_register "$_AID_TARGET"` **`bin/aid:1565`** → `exit 0` **`bin/aid:1566`**. Insert
  `_aid_migrate_repo "$_AID_TARGET"` **after `bin/aid:1565` and before `bin/aid:1566`**, beside the
  existing register side-effect. `$_AID_TARGET` is the canonicalized cwd/`--target`
  (`_AID_TARGET="$(cd "$_AID_TARGET" && pwd)"` at **`bin/aid:1366`**) — FF-1 runs on exactly that one repo.
  Because `registry_register` already ran at `:1565`, FF-1 step 4 is an idempotent set-insert no-op; the
  other three steps run.
- Add the **self-update-if-needed preamble** to the `update` reach only (FF-3/CLI-2, OQ-6): FR38 mandates
  `aid update` ensure the CLI is current first; the live `add|update` engine does **not** self-update today
  (it re-installs tool trees from the bundle, no `_cmd_update_self` call). Wire the preamble to run on the
  `update` subcommand path **before** the tool loop. Resolve OQ-6 toward the simplest-correct: reuse
  `_cmd_update_self`'s channel logic (`bin/aid:247-268` — npm/pypi hint vs curl bootstrap) gated by a
  "skip if already current" version check (compare `$AID_HOME/VERSION`), so `aid add` is unaffected and a
  current CLI is a no-op. The invariant ("update implies current CLI before the per-repo migration") is
  fixed. Do **NOT** apply the preamble to the `add` reach.
- **Output (CLI-2):** print one concise line per action taken (e.g.
  `Migrated <repo>: synthesized settings.yml, added home.html.`); **silent** when the repo is already
  compliant (idempotent no-op). A step failure prints
  `WARN: aid: migration step '<step>' failed for <repo>: <reason>` and the command **still exits with its
  host-tool result** (NFR12 WARN-not-fail) — the migration never changes the `aid update` exit code.
- **Grammar UNCHANGED** (CLI-2): `aid update [<tool>...] [--target <dir>] [--version <v>] [--from-bundle <p>]`
  keeps its exact surface and exit codes. PS twin parity throughout (ASCII-only).

**Acceptance Criteria:**
- [ ] `_aid_migrate_repo "$_AID_TARGET"` is inserted at the `add|update` success tail (after the existing
      `registry_register "$_AID_TARGET"` at `bin/aid:1565`, before `exit 0` at `bin/aid:1566`), operating
      on the canonicalized `$_AID_TARGET` (`bin/aid:1366`) only — no scan, no prompt; the register inside
      FF-1 is an idempotent no-op beside the existing one.
- [ ] A self-update-if-needed preamble is wired on the `update` reach only (not `add`), ensuring the CLI is
      current before the per-repo migration (OQ-6 resolved simplest-correct, reusing `_cmd_update_self`
      channel logic + a skip-if-current check); a current CLI is a no-op.
- [ ] Output prints one concise line per action and is silent on an already-compliant repo; a step failure
      WARNs and the command still exits with its host-tool result (NFR12); the `update` grammar/exit codes
      are unchanged (CLI-2).
- [ ] The edit is the hand-maintained `bin/aid` + `bin/aid.ps1` twin (R17 lockstep, ASCII-only), serialized
      after task-078, not render-drift (C8).
