# task-081: TEST — migration unit/safety (era-a/era-b, idempotency, no-delete, bare-.aid non-candidate) §6 gates 4-8

**Type:** TEST

**Source:** feature-011-upgrade-migration → delivery-011

**Depends on:** task-077

**Scope:**
- Author migration **unit + safety** tests over `_aid_migrate_repo` (FF-1, task-077), covering §6 gates
  4-8. Fixture repos are read-only-built tmp trees (NFR2 — never mutate the dogfood `.aid/`); assert the
  on-disk tree + registry before/after. Exercise both the Bash core and (where the harness supports it) the
  PS twin via `test-aid-cli-parity.sh`'s seam — though the deep era-a/era-b assertions are the parity
  partner of task-082's parity lane.
- **§6 gate 4 — era-a (no-op + repair):** (a) fixture with a **valid** `settings.yml` + `home.html` +
  registered ⇒ migration is a **no-op** (no fs write/move/create/delete, registry unchanged). (b) fixture
  with a **malformed/incomplete** `settings.yml` (missing a required section, e.g. no `project:` block or a
  missing scalar section) **AND** a populated `kb_baseline` block **AND** a per-skill `<skill>.minimum_grade`
  override ⇒ repaired to DM-1 validity, the **`kb_baseline` + override survive byte-for-byte** (R21 — the
  highest-consequence hazard), and the result parses via `read-setting.sh` + the server/reader without
  falling back. This is the explicit R21 / §6-gate-4 preserve assertion.
- **§6 gate 5 — era-b (synthesize):** fixture with **no** `settings.yml`, a `.aid/knowledge/STATE.md` (plus
  a variant with `DISCOVERY_STATE.md` to cover RC-4 filename set) + a `.aid/.aid-manifest.json` ⇒
  `settings.yml` synthesized with `project.name`=basename, `project.type`=`brownfield`,
  `tools.installed`=manifest `tools` keys, defaults elsewhere; parses cleanly for all readers (DD-2/RC-4).
- **§6 gate 6 — idempotency:** run `_aid_migrate_repo` **twice** on each fixture ⇒ the second run is a
  **byte-identical no-op** (tree + registry unchanged after run 2).
- **§6 gate 7 — no-delete:** (a) fixture with a legacy `knowledge-summary.html` **and** an existing
  `kb.html` ⇒ migration keeps **both** (no-clobber, `mv -n` guard). (b) fixture with an existing `home.html`
  ⇒ it is **never overwritten**. Assert no user file is removed in any fixture (SEC-3/NFR12).
- **§6 gate 8 — bare-`.aid/` non-candidate:** a folder with only `.aid/.temp/` (no `settings.yml`, no KB
  marker) ⇒ the scan/detect does **NOT** treat it as a candidate and mutates nothing (DD-6/SEC-1).
- No production file is modified by this task; tests are read-only-on-`.aid/`; any server they spin stays
  bound to `127.0.0.1`.

**Acceptance Criteria:**
- [ ] §6 gate 4: era-a valid ⇒ no-op (tree+registry unchanged); era-a malformed **with a populated
      `kb_baseline` + a per-skill override** ⇒ repaired to DM-1 validity with `kb_baseline`+override
      **preserved byte-for-byte** (R21) and parseable by `read-setting.sh` + server/reader without fallback.
- [ ] §6 gate 5: era-b (STATE.md + a DISCOVERY_STATE.md variant) + manifest ⇒ synthesized settings
      (basename / brownfield / manifest `tools.installed` / defaults) parseable by all readers (RC-4/DD-2).
- [ ] §6 gate 6: a second `_aid_migrate_repo` run on each fixture is a byte-identical no-op (tree +
      registry).
- [ ] §6 gate 7: existing `kb.html` + legacy summary ⇒ both kept (no-clobber); existing `home.html` ⇒ never
      overwritten; no user file removed in any fixture (SEC-3).
- [ ] §6 gate 8: a bare `.aid/.temp/`-only folder is a non-candidate that mutates nothing (DD-6);
      no production file changed; read-only on `.aid/`; any server bound to `127.0.0.1`.
