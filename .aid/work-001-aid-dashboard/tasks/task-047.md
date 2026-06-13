# task-047: Co-vendor the dashboard server + reader into the install tree; place under `$AID_HOME/dashboard/`; relocate the spawn seam

**Type:** CONFIGURE

> **Type rationale (gate finding #4):** CONFIGURE is correct — this is the **mechanical install-wiring unit** PLAN R8 prescribes as a single co-vendor task (vendor copy-list + install-core placement + a fixed entry-point/arg re-point), **not** a design decision. The spawn-seam edit is a **mechanical substitution** of two already-decided values: the spawn target path (`$AID_HOME/dashboard/server/server.{py,mjs}`, pinned by task-046's layout) and the passed root (`$AID_HOME`, fixed by task-048's contract). No grammar/help/exit-code/behavior is *designed* here; the one open design call adjacent to this seam — the `aid dashboard --target` residual meaning — is **owned by task-052 (DESIGN)** and explicitly out of scope below. If task-046's RESEARCH surfaces a behavior choice (not a fixed substitution), it escalates per task-046's IMPEDIMENT path rather than absorbing a design decision into this CONFIGURE unit.

**Source:** feature-010-cli-home-and-registry → delivery-008

**Depends on:** task-046

**Scope:**
- Implement the R8 wiring per task-046's pinned layout + delta list (residual item #1). Vendor the **server+reader unit** into both packages and materialize it under `$AID_HOME/dashboard/` at install time, so `aid dashboard start <runtime>` runs a machine server from the install tree (not a repo checkout).
- **npm:** extend `packages/npm/scripts/vendor.js` copy list + `package.json` `files` to ship `dashboard/server/{server.py,server.mjs}` + the Node reader (`dashboard/server/reader.mjs`) + the Python reader package (`dashboard/reader/*.py`), preserving the relative layout task-046 pinned. **pypi:** mirror in `packages/pypi/scripts/vendor.py` (+ `_vendor` tree / `MANIFEST`).
- **install-core placement:** extend the step that materializes `bin/`,`lib/`,`VERSION` into `$AID_HOME` to also place `dashboard/` (server + reader) at the pinned path, so a clean install has `$AID_HOME/dashboard/server/server.{py,mjs}` + an importable reader.
- **Spawn-seam relocation (CLI-2) — mechanical re-point, no design:** in the HAND-MAINTAINED root `bin/aid` (Bash) + `bin/aid.ps1` (PowerShell twin), substitute two **already-decided** values in the existing `aid dashboard start` spawn (`bin/aid:890`): (1) the spawn target path → the task-046-pinned `$AID_HOME/dashboard/server/server.{py,mjs}` (was the repo-checkout server), and (2) the passed root argument → the resolved **`$AID_HOME`** (the task-048 contract value, so the server finds `registry.yml` + the CLI-home `index.html`) in place of the single repo `--root`. This is a value substitution at a fixed seam — **no new behavior, flag, or control flow is designed here.** Grammar/help/exit-codes byte-UNCHANGED (CLI-2); the `127.0.0.1`-only bind is untouched. The `aid dashboard --target` residual *meaning* (auto-register / deep-link / no-op) is a **design decision owned by task-052**, NOT decided here.
- Reader stays read-only / no-LLM (NFR2/NFR7); the relocation moves bytes + the spawn target only — no reader/server behavior change in THIS task (the LC-MS contract rewrite is task-050/051). `bin/aid`/`bin/aid.ps1` edits pass **ASCII-only** + **Bash↔PowerShell parity** + **vendored-copy refresh** (NOT render-drift — `bin/aid` is hand-maintained, C7 governs canonical producers only).

**Acceptance Criteria:**
- [ ] After a clean install, `$AID_HOME/dashboard/server/server.{py,mjs}` exists and its reader import resolves at runtime (Python `from reader import read_repo`; Node `./reader.mjs`) — proven by a smoke check that the relocated server boots from `$AID_HOME` and the `index.html` sibling resolves.
- [ ] `vendor.js` + `vendor.py` (+ `package.json files` / pypi manifest) ship the server+reader unit at the pinned relative layout; the vendored-copy refresh gate passes; the install-core placement step lands `dashboard/` under `$AID_HOME`.
- [ ] `aid dashboard start <runtime>` spawns `$AID_HOME/dashboard/server/server.{py,mjs}` with the resolved `$AID_HOME` (not a single repo `--root`); bare `aid` + the `aid dashboard` grammar/help/exit-codes are byte-unchanged (CLI-2); the `127.0.0.1`-only bind path is preserved (no `0.0.0.0` token introduced).
- [ ] `bin/aid` + `bin/aid.ps1` pass `test-ascii-only.sh` + `test-aid-cli-parity.sh`; vendored copies refreshed; no `run_generator.py` / render-drift path touched.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline); existing CLI/server tests stay green.
