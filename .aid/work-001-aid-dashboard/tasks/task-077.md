# task-077: MIGRATE — _aid_migrate_repo core (FF-1) in bin/aid + bin/aid.ps1 twin (LC-MIG)

**Type:** MIGRATE

**Source:** feature-011-upgrade-migration → delivery-011

**Depends on:** task-074, task-076

**Scope:**
- Implement the shared per-repo migration function `_aid_migrate_repo <repo>` (FF-1, LC-MIG) — the single
  logical writer authored as a **Bash function in `bin/aid` plus its byte-behavior twin in `bin/aid.ps1`**
  (one logical writer per R17; the two files ship in lockstep, gated by `test-aid-cli-parity.sh`). `<repo>`
  is a CAN-1-canonical repo base folder (`cd "$repo" && pwd`, no `-P` — the same rule used at
  `bin/aid:1366` and feature-010's SEC-5). The four mutating steps each run **only when not already
  satisfied**, each **idempotent + WARN-not-fail** (a step's failure logs a WARN and the next step still
  runs; `return 0` on completion — SEC-4).
- **Step 0 — DETECT/QUALIFY (read-only, DD-6/SEC-1):** qualify iff `<repo>/.aid/` exists AND
  (`<repo>/.aid/settings.yml` exists [era-a] OR
  `<repo>/.aid/knowledge/{DISCOVERY_STATE.md|DISCOVERY-STATE.md|STATE.md}` exists [era-b, RC-4]). A bare
  `.aid/` with neither marker (e.g. only `.aid/.temp`) is **NOT a candidate** → return without mutation.
  Pure `test -f`/`test -d` reads — no write before this passes.
- **Step 1 — SETTINGS (DM-1, per the task-074 contract):** era-a → validate against the task-074 "valid"
  definition; if any REQUIRED key missing/malformed → **repair via targeted edit** (single-line-replace /
  append-block, temp-file + `mv -f`), **preserving `kb_baseline` + per-skill overrides byte-intact**
  (DD-3/R21). era-b → **synthesize** a fresh template-derived file (basename name, `brownfield` type,
  placeholder description, `tools.installed` from `.aid/.aid-manifest.json` via `manifest_list_tools`/
  `manifest_read_*` in `lib/aid-install-core.sh` (Bash) / `lib/AidInstallCore.psm1` (PS), defaults
  elsewhere), crash-safe (temp-file + `mv -f`). A valid era-a file → **no write**.
- **Step 2 — ADD home.html (additive, FR40/RC-2):** if NOT `-f <repo>/.aid/dashboard/home.html`:
  `mkdir -p <repo>/.aid/dashboard` then `cp "$AID_HOME/dashboard/home.html" <repo>/.aid/dashboard/home.html`
  (the single vendored source from task-076; `$AID_HOME` resolved per `bin/aid:40-47`). **Never overwrites**
  an existing `home.html` (the `-f` no-clobber guard). Resolves KI-010.
- **Step 3 — RELOCATE legacy summary (no-clobber, DM-4/FR31):** guard
  `[ -f <repo>/.aid/knowledge/knowledge-summary.html ] && [ ! -f <repo>/.aid/dashboard/kb.html ]` then
  `mkdir -p <repo>/.aid/dashboard && mv -n OLD NEW` — the exact FR31 idiom already at
  `canonical/scripts/summarize/summarize-preflight.sh:102-113`. **Never deletes** (a clobber is skipped,
  both files kept).
- **Step 4 — REGISTER (idempotent, DM-2/FR28):** `registry_register CAN-1(<repo>)` — reuse the existing
  writer at **`bin/aid:1094-1127`** verbatim (idempotent set-insert, atomic temp-file + `mv -f`,
  WARN-return-0 on failure); read existing registry via `_registry_read_repos` (**`bin/aid:1082-1088`**)
  where a caller needs to skip already-registered repos.
- **Ordering** is settings → home.html → relocate → register (SPEC FF-1 rationale). **No step removes user
  data** (SEC-3): step 2 copies-when-absent, step 3 `mv -n` under the `[ ! -f NEW ]` guard, step 1 is
  temp-file + `mv -f` (never truncating), step 4 is a set-insert.
- **PS twin parity (NFR5/R17):** the `bin/aid.ps1` `_aid_migrate_repo` twin uses the same `$AID_HOME`
  resolution, same era-a/era-b branch, same no-clobber/atomic semantics, same exit/return codes; manifest
  read via `lib/AidInstallCore.psm1`. **ASCII-only** prompt/WARN text. This task adds **no dispatch wiring**
  (the two reaches + trigger are tasks 078/079/080) and **no new verb** — it is the callable core only.
- Edits land in hand-maintained `bin/aid` + `bin/aid.ps1` (NOT `canonical/`; not render-drift, C8).

**Acceptance Criteria:**
- [ ] `_aid_migrate_repo <repo>` exists in **both** `bin/aid` and `bin/aid.ps1` as byte-behavior twins
      (same branches, semantics, return codes, ASCII text), runs DETECT→SETTINGS→ADD→RELOCATE→REGISTER in
      order, and `return 0` (WARN-not-fail per step — a single step failure logs a WARN, the next runs).
- [ ] DETECT qualifies only era-a (`settings.yml`) or era-b (`knowledge/{DISCOVERY_STATE.md|
      DISCOVERY-STATE.md|STATE.md}`); a bare `.aid/` is a non-candidate that mutates nothing (DD-6/SEC-1).
- [ ] SETTINGS implements the task-074 contract: era-a targeted repair preserving `kb_baseline`+overrides
      (DD-3/R21), era-b synthesis (basename / brownfield / placeholder / manifest `tools.installed` /
      defaults), both crash-safe (temp-file + `mv -f`); a valid era-a file is a no-write.
- [ ] ADD copies `$AID_HOME/dashboard/home.html` only when the repo copy is absent (never overwrites);
      RELOCATE moves the legacy summary under the `mv -n` + `[ ! -f NEW ]` no-clobber guard (never deletes);
      REGISTER calls the existing `registry_register` (`bin/aid:1094`) idempotently.
- [ ] No user data is removed in any step (SEC-3); no dispatch wiring or new verb is added here (callable
      core only); the edit is absent from `canonical/EMISSION-MANIFEST.md` (not render-drift, C8).
