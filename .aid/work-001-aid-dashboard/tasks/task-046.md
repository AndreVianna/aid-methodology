# task-046: R8 install-tree relocation — pin the `$AID_HOME/dashboard/` layout + vendor/install-core blast radius (escalate-or-proceed)

**Type:** RESEARCH

**Source:** feature-010-cli-home-and-registry → delivery-008

**Depends on:** —

**Scope:**
- Resolve **R8** (the headline d008 precondition; MEMORY "dashboard not install-wired") at detail: the multi-repo server must run from `$AID_HOME/dashboard/`, but today the `dashboard/` tree (server + reader) is vendored into **neither** the npm nor pypi package, and no install-core step places it under `$AID_HOME`. Confirmed at detail time: `packages/npm/scripts/vendor.js` + `packages/pypi/scripts/vendor.py` copy only `bin/`+`lib/`+`VERSION`; `find packages -path '*dashboard*'` is empty.
- **Pin the vendored unit** = `dashboard/server/{server.py,server.mjs}` **+** the feature-002 reader module(s) the server imports — Python `dashboard/reader/` package (`reader.py`, `models.py`, `parsers.py`, `derivation.py`, `locator.py`, `__init__.py`) and the Node `dashboard/server/reader.mjs` — laid out so the **existing relative imports resolve unchanged** from the new `$AID_HOME/dashboard/` location: Python `server.py:30-41` does a `sys.path` insert of the `dashboard/` parent then `from reader import read_repo`; Node `server.mjs:37` does `import { readRepo } from "./reader.mjs"` and `server.mjs:93` resolves `index.html` at `join(__dirname, "..", "index.html")`. Document the exact target layout so neither import path nor the `index.html` sibling-resolution breaks.
- **Enumerate the blast radius** across BOTH packaging surfaces (npm `vendor.js`/`package.json` `files`; pypi `vendor.py`/`MANIFEST`/`_vendor` tree) AND the install-core placement step that materializes the payload under `$AID_HOME` (the layer that today writes `bin/`,`lib/`,`VERSION` into the install tree). Identify every file/manifest/test that must change for `aid dashboard start <runtime>` to find `$AID_HOME/dashboard/server/server.{py,mjs}` + a working reader import at runtime on a clean install.
- **Decide and state explicitly (the R8 directive):** is co-vendoring the server+reader unit a **bounded task inside d008** (the PLAN's recommended path — task-047 does the wiring) **OR** does the blast radius exceed a co-vendor unit, requiring an **IMPEDIMENT escalation to a human decision before executing**? Record the verdict, the evidence, and (if "proceed") the precise file/manifest delta list task-047 will implement. Do NOT touch production code (research only).

**Acceptance Criteria:**
- [ ] A written layout decision pins the exact `$AID_HOME/dashboard/` tree (server entry + co-vendored reader package per runtime) such that the existing Python `sys.path`/`from reader import read_repo` and Node `./reader.mjs` + `../index.html` resolutions hold **without source edits to the import lines** (or, if a minimal import-shim is unavoidable, that shim is named and bounded).
- [ ] The full vendor/install blast radius is enumerated as a concrete file/manifest/test delta list across **both** npm and pypi vendoring **and** the install-core `$AID_HOME` placement step — sufficient for task-047 to execute without re-discovery.
- [ ] An explicit verdict is recorded: **proceed as a bounded co-vendor task (task-047)** with the delta list attached, **or** **IMPEDIMENT** raised to the work's `STATE.md ## Cross-phase Q&A` (and `.aid/knowledge/STATE.md` if KB-level) flagging the over-budget packaging effort for a human decision — per the PLAN R8 directive "do not balloon the spine."
- [ ] No production code is modified; this task emits a decision + delta list only (RESEARCH).
