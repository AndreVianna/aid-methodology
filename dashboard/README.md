# dashboard/

This directory is the home for the AID dashboard component, which provides
a live monitoring view of AID pipeline runs across repos.

## Structure

```
dashboard/
  reader/          Python reference implementation of the state reader
  README.md        (this file)
```

## Reader

`dashboard/reader/` is the **Python 3.11+ reference implementation** of the
`read_repo(aid_root) -> RepoModel` entry point (feature-002). It is hand-maintained
shipped code (analogous to `bin/aid`) -- it is NOT a canonical->render artifact and
does NOT live under `canonical/`. Do NOT run the generator for it.

### Runtime decision (seam 1)

The reader is implemented in Python 3.11+ stdlib only (zero third-party deps: `pathlib`,
`json`, `re`, `datetime`, `dataclasses`, `typing`, `unittest`). This is the
always-present reference implementation. A Node built-ins-only port (for the dashboard
server feature-003 option C hybrid runtime) is task-017 in delivery-002 -- out of scope
here. The byte-parity test between the two ports is task-018.

### Home decision (seam 2)

The reader lives at `dashboard/reader/` -- the natural home for the new dashboard
component that `aid dashboard` (feature-004) will serve. The Node server (feature-003),
static front-end (task-019), and the asset-tree shipping mechanisms are formalized in
delivery-002 (task-014/017).

### ASCII gate

The ASCII-only gate (`tests/canonical/test-ascii-only.sh`) is scoped to `bin/aid` and
installer scripts. Python source may use UTF-8 normally and is not under that gate.
This reader is ASCII-only by choice (preferred for simple parse rules), but that is
not a CI-enforced requirement for Python source.

### Delivery scope

- delivery-001: `dashboard/reader/` Python reference impl + unit tests (task-010/012).
- delivery-002: Node port + server wiring + byte-parity test (task-014..018).
- delivery-003: Secure remote exposure (task-024..026).

## home.html — SPA shell (source of truth)

`dashboard/home.html` is the **single committed source of truth** for the SPA shell
(LC-HSRC, DD-5, FR40).  It is vendored into the installed CLI at `$AID_HOME/dashboard/home.html`
and served directly from there (the multi-repo server serves it at `/r/<id>/home.html`); it is
**not** copied into each repo. There is no per-repo `.aid/dashboard/home.html`, and the vendored
copy must remain byte-identical to this source.

Sync direction (one-way, authoritative):
```
dashboard/home.html  (edit here)
       |
       v  CI equality gate enforces byte-identity (tests/canonical/test-home-html-source-sync.sh)
       v  task-076 vendor step copies to $AID_HOME/dashboard/home.html
$AID_HOME/dashboard/home.html  (vendored copy — served directly by the CLI; do NOT edit directly)
```

**Never edit `$AID_HOME/dashboard/home.html` directly.**  Always edit `dashboard/home.html` and
then re-vendor.  The CI gate (`tests/canonical/test-home-html-source-sync.sh`) will fail
the build on any divergence between the two files (R20).
