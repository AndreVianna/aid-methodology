# Delivery Issue Log -- delivery-002

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded -- grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-016 | [HIGH] | Pre-existing test failure: test_s9_brand_contains_aid_this_machine expects 'AID' in brand div; brand HTML contains only '<strong>Home</strong>', not '<strong>AID ... this machine</strong>'; blocks build gate | Resolved (NOT a work-017 regression — validated: fails at the work-017 base; brand was "Home" pre-work-017; work-017 touched neither the brand nor test_s9). Per user decision to keep the "Home" brand, the stale test was updated (test_s9_brand_present, asserts "Home") — suite green (174/174 in test_cli_home_html.py). |

## Post-gate dogfood UI findings (live browser dogfooding of index.html after the A+ re-gate)

> Per the gate discipline established after delivery-001 (which shipped 4 broken edit surfaces past an A+ static gate), delivery-002's interactive controls were dogfooded in a real browser via Playwright against an isolated `--allow-writes` server (HOME/USERPROFILE/AID_HOME pinned to a scratch registry listing only this repo) on 2026-07-18.

**VERIFIED WORKING (all delivery-002 controls, index.html all-projects home):**
| Control | Result |
|---------|--------|
| Add project | Button renders + enabled; click opens the inline form (path textbox + "Must already be an AID project…" helper + Register/Cancel); Cancel closes it. NOT a no-op (the delivery-001 regression class is absent). |
| Remove (per card) | Renders + enabled; click opens the inline two-step confirm ("Untracks this project… No files are removed" + Confirm untrack/Cancel); "Confirm untrack" dispatches the REAL `aid projects remove` via `bash bin/aid` and surfaces the CLI stderr inline (AC1: real op, never a phantom success). |
| Update Tools (per card) | Renders + enabled (not clicked — would run a real `aid update`). |
| Update CLI (global) | Renders + enabled (not clicked — would run a real `aid update self`). |
| write_enabled gate (AC8) | `/api/home` `machine.write_enabled: true` under `--allow-writes`; all four buttons `disabled:false`. |

**FINDINGS:**
| # | Severity | Description | Status |
|---|----------|-------------|--------|
| D-1 | [MEDIUM] | Windows-only: a project registered via the dashboard "Add project" (which spawns `bash bin/aid projects add`, storing the MSYS `/c/…` path form) renders WITHOUT metadata (`name/description/aid_version = None`) because the native-Windows Python/Node reader resolves `C:\…` but not `/c/…`. The Add OP persists correctly (AC1); only the rendered card is degraded, and only on Windows. Pre-existing (base reader + CLI path-form; predates work-017 — the read-only dashboard had the same limitation for CLI-added projects); feature-003 makes it one-click reachable. Invisible to the Linux-CI test suite. | **Resolved** (user chose fix-now). Added `_native_fs_path`/`nativeFsPath` MSYS→native normalizer to both reader twins at the filesystem boundary only (id/display/write-ops stay verbatim; CAN-1/DD-5 preserved; syntactic, no realpath). Windows branch made CI-exercisable via an injectable platform seam; guarded by `TestNativeFsPathUnit` + byte-identical `TestNativeFsPathParity`. Re-dogfooded on both twins: the `/c/…` card now resolves name/version. See **KI-008** (Resolved). |
| D-2 | [MINOR] | Cosmetic: the footer reads "· read-only ·" even under `--allow-writes` with write controls active/enabled — the string is generic copy not wired to `write_enabled`. Non-blocking; pre-existing footer copy, not a delivery-002 control. | Open (non-blocking; noted). |
