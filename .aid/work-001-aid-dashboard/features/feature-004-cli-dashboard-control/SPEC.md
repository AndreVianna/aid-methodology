# CLI Dashboard Control (Start / Stop)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-10 | Feature identified from REQUIREMENTS.md §5 FR10; §8 OQ3 | /aid-interview |

## Source

- REQUIREMENTS.md §5 FR10 (CLI start/stop)
- REQUIREMENTS.md §8 OQ3 (CLI ownership — extend `aid` vs. separate CLI)

## Description

Provides the **CLI to start and stop the dashboard** for a repo, so the operator can run and test
it. Resolves **OQ3** — how the start/stop control is exposed.

**OQ3 — RESOLVED (user, 2026-06-10): a new subcommand on the existing `aid` CLI** (e.g.
`aid dashboard` / `aid serve`). Bare `aid` is **already a fully-implemented command** (`bin/aid`
`_cmd_dashboard()` prints version + project status + usage; `bin/aid` help documents
`aid → Show the dashboard` as a text status screen), so it must **not** be repurposed — doing so
would change existing observable CLI behavior (C4). The exact subcommand name is finalized in
/aid-specify. (A separate CLI was considered and not chosen.)

## User Stories

- As an **operator**, I want to start the dashboard with a single CLI command, so I can view my
  pipeline.
- As an **operator**, I want to stop it cleanly, so it isn't left running.

## Priority

Must (MVP).

## Acceptance Criteria

- [ ] Given a repo with AID installed, when I run the start command, then the dashboard is launched
      and served locally (handing off to feature-003).
- [ ] Given a running dashboard, when I run the stop command, then it is shut down cleanly.
- [ ] Given OQ3, when the SPEC is written, then the CLI ownership decision (repurpose bare `aid`
      vs. new subcommand vs. separate CLI) is made and justified **without changing existing
      `aid` behavior** (C4).

---

## Technical Specification

> Activated sections (per `canonical/templates/specs/spec-template.md`): **Data Model** (the run-state
> record the CLI manages — the `dashboard.pid` JSON file: what is stored, where, lifecycle, staleness),
> **Feature Flow** (`start`/`stop` algorithms incl. already-running, idempotent stop, `--remote`
> delegation, runtime-availability checks), **Layers & Components** (the `_cmd_dashboard_ctl` Bash
> handler + the PowerShell twin, dispatch integration that does not alter bare `aid`/`_cmd_dashboard`,
> the canonical-source/vendor-copy/ASCII-gate/parity-gate implications). Conditional: **CLI / Command
> spec** (REQUIRED — this feature *is* the command surface: grammar, flags, exit codes, help, errors),
> **Security Specs** (REQUIRED but thin — only the `127.0.0.1` bind delegation, `--remote` clear-fail,
> never-public invariant; deep exposure internals are feature-005). Skipped: **UI Specs** (the page is
> feature-003; this is a shell command with no rendered UI), **API Contracts → external** (the only
> surface is feature-003's localhost `/api/model`, consumed by the browser, not by this CLI),
> **Data/DB & Migration** (no schema, no DB — AID ships none, `schemas.md`), **State Machines** (FR16
> lifecycle is feature-002's; the start/stop transitions here are trivial enough to live in Feature
> Flow), **Telemetry** (none generated; NFR7).

OQ3 is **RESOLVED (REQUIREMENTS §8 OQ3; user, 2026-06-10)** and baked into this spec: the control
surface is a **new `dashboard` subcommand on the existing `aid` CLI** with `start`/`stop` verbs.
**Bare `aid` is NOT touched** — it remains `_cmd_dashboard()` (`bin/aid:533`, the text status
screen). The launcher is the existing **Bash `bin/aid` + PowerShell `bin/aid.ps1` twin**
(cross-platform per NFR5), spawning the runtime chosen on the command line (feature-003's dual-runtime
server) as a **tracked child process** recorded in a PID file. The CLI is **deterministic shell —
no agent/LLM** (NFR7); it is plain Bash/PowerShell exactly like the rest of `bin/aid`.

This feature owns **only** the start/stop control. It **invokes** feature-003 (the server it spawns)
and feature-005 (the `--remote` exposure layer) but specifies neither's internals; the integration
points are named contracts below (LC-1 server spawn contract, LC-2 exposure delegation contract).

---

### Data Model

There is no relational schema (AID ships no DB — `.aid/knowledge/schemas.md`). The only state this
feature manages is the **dashboard run-state record**: one transient file that tracks the spawned
server so `stop` can find and terminate it, and so a second `start` can detect "already running."

#### DM-1. The run-state file `.aid/.temp/dashboard.pid`

| Property | Value |
|----------|-------|
| **Path** | `<target>/.aid/.temp/dashboard.pid` — **per-repo, project-scoped** (one dashboard per repo, FR1/FR9), under the existing transient `.aid/.temp/` run-state convention (precedent: `aid-housekeep` `.aid/.temp/HOUSEKEEP_STATE_<ts>.md`, `pipeline-contracts.md`). |
| **Scope** | Per `<target>` repo (default cwd; honors the existing `--target`/`AID_TARGET` convention, `bin/aid:594`). Two different repos run independent dashboards with independent PID files. |
| **Lifecycle** | Created by `start` after the child is confirmed listening; read by `start` (already-running guard) and `stop`; deleted by `stop` after teardown. **Transient** — `.aid/.temp/` is git-ignored and not part of handoff (it is machine/run state, not pipeline state). |
| **Format** | A single-object JSON document (parseable by both runtimes feature-003 ships, and trivially by the launcher itself). ASCII-only content. |

Stored fields:

```jsonc
{
  "schema": 1,                 // int; record format version (bump on breaking change)
  "pid": 48213,                // int; OS pid of the spawned server child (process-group leader on POSIX)
  "runtime": "python",         // "python" | "node" — which server was launched (echoes the positional)
  "port": 8787,                // int; the 127.0.0.1 port the child bound (see DM-2)
  "bind": "127.0.0.1",         // literal; always loopback (C1/C2). Recorded for diagnostics, never 0.0.0.0
  "remote": false,             // bool; whether feature-005 exposure was requested AND succeeded
  "remote_handle": null,       // string|null; opaque teardown handle returned by feature-005 (LC-2), or null
  "started_at": "2026-06-10T14:30:00Z",  // ISO-8601 UTC; diagnostic only, NOT used for liveness
  "target": "/abs/path/to/repo",         // absolute repo root the server serves (resolved like bin/aid:710)
  "logfile": "/abs/path/to/repo/.aid/.temp/dashboard.log"  // where the child's stdout/stderr was redirected
}
```

- **Why a file, not env/memory:** `start` and `stop` are separate process invocations; the PID must
  survive between them. A file under `.aid/.temp/` is the established AID pattern and needs no daemon.
- **Liveness is verified, never trusted.** `started_at` is diagnostic only. Before acting on the
  record, both `start` (already-running guard) and `stop` **re-verify the PID is alive** (POSIX
  `kill -0 "$pid"`; Windows `Get-Process -Id`). A record whose PID is dead is a **stale record**
  (the server crashed or the machine rebooted without a clean `stop`) and is treated per DM-3.
- **`port` is recorded, not assumed.** Auto-pick-free-port is explicitly deferred (REQUIREMENTS §4
  Out of Scope), so the MVP uses a **fixed default port (`8787`)** overridable by `--port <n>`
  (see CLI-1). Whatever port the child actually bound is written to the record so `stop` and the
  printed URL agree with reality.

#### DM-2. Port selection (MVP, deferral-honest)

The "auto-pick a free port" nicety is deferred (§4 Out of Scope). MVP behavior:

- Default port **`8787`** (a fixed, documented constant). The user may override with `--port <n>`.
- If the chosen port is already in use, the server child fails to bind; `start` detects the child's
  early exit (Feature Flow step 8) and reports `ERROR: aid: dashboard: port <n> is already in use
  (try: aid dashboard start <runtime> --port <other>)` with **exit 3**. It does **not** silently
  retry on another port (that is the deferred nicety) and it never falls back to a public bind.

#### DM-3. Stale-record handling (no leaked "already running")

A `dashboard.pid` exists but its `pid` is **not alive**:

- On `start`: the stale record is **silently reclaimed** (logged at `--verbose`), `start` proceeds as
  if no dashboard were running, and overwrites the record. (A crashed previous server must not
  permanently block a restart.)
- On `stop`: a stale (or absent) record is treated as **already stopped** — `stop` removes any
  leftover record/logfile, prints `aid: dashboard: not running (nothing to stop)`, and exits **0**
  (idempotent stop, per the AC). It does **not** error on "nothing to stop."

---

### Feature Flow

Two deterministic shell flows. No agent/LLM anywhere (NFR7); every step is plain Bash/PowerShell.

#### `aid dashboard start <runtime> [--remote] [--port <n>] [--target <dir>]`

```
1.  Parse args:
      runtime  := positional #1, MUST be exactly "node" or "python"  (else exit 2, CLI-3)
      flags    := --remote (bool) | --port <n> | --target <dir> | --verbose | -h/--help
      Unknown flag or missing/invalid runtime -> usage error, exit 2.
2.  Resolve target repo root (same logic as bin/aid:705-710: --target | AID_TARGET | cwd; must be a dir).
3.  Resolve the AID install for <target>:
      no .aid/ (or no dashboard assets) at <target> -> ERROR, exit 7  (mirrors `aid status` exit 7).
4.  Already-running guard (DM-1/DM-3):
      read .aid/.temp/dashboard.pid; if present AND pid alive (kill -0 / Get-Process):
        print "aid: dashboard already running (runtime <r>, http://127.0.0.1:<port>); run 'aid dashboard stop' first."
        exit 8  (CLI-2 — "already running" is its own code, distinct from usage error).
      if present but pid dead -> reclaim stale record (DM-3), continue.
5.  Resolve runtime availability:
      runtime == python -> require python3 (>=3.11 per feature-003/technology-stack) on PATH;
      runtime == node   -> require node on PATH.
      Missing -> ERROR "aid: dashboard: <runtime> runtime not found on PATH (install it, or choose the
      other runtime: aid dashboard start <other>)", exit 9.
6.  Locate the feature-003 server entry point for <runtime> (LC-1 spawn contract):
      python: <assets>/server.py     node: <assets>/server.mjs   (entry-point paths + arg names are the
      LC-1 spawn contract this feature and feature-003 must AGREE ON -- feature-003's SPEC names neither
      a filename nor an arg grammar yet, so the names below are proposed here and to be confirmed against
      feature-003 at implementation; this CLI only resolves+invokes them, it does not own the server).
      Missing entry point -> ERROR, exit 7 (install incomplete).
7.  Spawn the server child, bound to 127.0.0.1:<port> (C1/C2):
      POSIX (bin/aid):   setsid <interp> <entry> --root <target> --host 127.0.0.1 --port <port> \
                           >"$logfile" 2>&1 &   ; pid=$!   (new session => clean process-group kill on stop)
      Windows (aid.ps1): Start-Process -FilePath <interp> -ArgumentList ... -RedirectStandardOutput/Error
                           -PassThru -WindowStyle Hidden ; pid=$proc.Id
      The bind host passed is the literal "127.0.0.1" — never read from config, never 0.0.0.0 (SEC-1).
8.  Confirm the child came up (bounded readiness wait, not a blind sleep):
      poll for up to ~5s: is pid still alive AND is 127.0.0.1:<port> accepting? (a single TCP connect,
      or one HTTP GET / via the runtime's own client — no third-party tool required).
      child exited early (e.g. port in use, import error) -> print last lines of <logfile>,
        do NOT write the record, exit 3.
      timeout but pid alive -> warn "started but not yet responding on :<port>; check <logfile>",
        still record (the child may be slow on a huge .aid/); exit 0 with the warning.
9.  Write .aid/.temp/dashboard.pid (DM-1) with pid/runtime/port/bind/target/logfile, remote=false.
10. If --remote (LC-2 exposure delegation, feature-005):
      invoke feature-005's expose(port=127.0.0.1:<port>, scope=host/user-ACL) -> returns a teardown handle.
      success -> set record.remote=true, record.remote_handle=<handle>, print the private remote URL.
      mechanism absent / not configured on this host -> print
        "ERROR: aid: dashboard: --remote requested but the secure remote-exposure mechanism is not
         available on this host; the dashboard is NOT exposed. The local server is still running at
         http://127.0.0.1:<port>." and exit 10.
      NOTE: the local server is ALREADY local-only-bound (step 7) BEFORE remote is attempted, so a
      --remote failure NEVER results in a public bind (C1) — at worst the operator gets a local-only
      dashboard plus a clear error. (The record stays remote=false in that case.)
11. Print the local URL ("Dashboard (<runtime>) running at http://127.0.0.1:<port> — stop with: aid
      dashboard stop") and, if remote succeeded, the private remote URL on its own line. exit 0.
```

#### `aid dashboard stop [--target <dir>]`

```
1.  Parse args: --target <dir> | --verbose | -h/--help. (No runtime positional — stop is runtime-agnostic;
      a stray positional is a usage error, exit 2.)
2.  Resolve target repo root (step 2 above).
3.  Read .aid/.temp/dashboard.pid.
      absent OR pid dead (DM-3) -> remove any leftover record/logfile, print
        "aid: dashboard: not running (nothing to stop).", exit 0  (idempotent).
4.  If record.remote == true: tear down feature-005 exposure FIRST (LC-2), using record.remote_handle.
      teardown failure -> WARN (do not abort the process kill); continue to step 5 (we must not leave
      the server running just because the tunnel teardown hiccuped). Note the partial in the final line.
5.  Terminate the server child cleanly:
      POSIX: kill the whole process group (kill -TERM -<pgid> where pgid==pid via setsid), wait up to
        ~5s for exit; escalate to kill -KILL on the group if still alive.
      Windows: Stop-Process -Id <pid> (graceful) then -Force if it survives the wait.
      pid already gone between step 3 and here -> treat as stopped (no error).
6.  Remove .aid/.temp/dashboard.pid (and the logfile). Print "aid: dashboard stopped." (or
      "stopped (remote teardown reported a warning — check above)" on a step-4 partial). exit 0.
```

- **Idempotent stop (AC):** a second `stop`, or a `stop` after a crash, exits 0 with "nothing to
  stop" — never an error.
- **No orphans:** spawning into a new session/process-group (POSIX `setsid`, Windows child process
  tracked by PID) lets `stop` kill the server **and** any children it forked, so nothing is left
  listening on the port.
- **`--remote` torn-down by `stop`:** because the exposure handle is persisted in the record, `stop`
  always tears the tunnel down before killing the server, satisfying "`stop` tears down the server
  child process AND any active remote exposure."

---

### Layers & Components

Per `coding-standards.md` (small, single-purpose, deterministic, documented exit codes, **ASCII-only
shipped scripts**) and `architecture.md` (the `aid` CLI dispatch pattern). This feature adds **one new
subcommand handler implemented twice** — once in `bin/aid` (Bash), once in `bin/aid.ps1` (PowerShell)
— held behavior-identical by the existing parity gate.

| Component | Side | Responsibility | MUST NOT |
|-----------|------|----------------|----------|
| **LC-CLI-B `_cmd_dashboard_ctl` (Bash)** | `bin/aid` | parse `dashboard start/stop`, manage `dashboard.pid`, spawn/kill the child bound to `127.0.0.1`, delegate `--remote` to feature-005 | repurpose bare `aid`/`_cmd_dashboard`; bind non-loopback; call any agent/LLM; embed feature-003 server logic or feature-005 exposure internals; emit non-ASCII bytes |
| **LC-CLI-P `Invoke-AidDashboardCtl` (PowerShell)** | `bin/aid.ps1` | byte-behavior twin of LC-CLI-B (same grammar, same exit codes, same messages, same record format) | diverge from the Bash side (parity gate); any of the above |
| **LC-1 feature-003 server** | spawned child | the dual-runtime server this CLI launches and tracks. **Spawn contract (proposed here; to be confirmed against feature-003, which names no entry-point/arg grammar yet):** entry points `server.py` (python) / `server.mjs` (node), invoked with `--root <target> --host 127.0.0.1 --port <n>`, exits non-zero on bind failure, prints nothing required on stdout (URL is printed by this CLI). | (server internals owned by feature-003; this CLI only spawns + tracks it) |
| **LC-2 feature-005 exposure** | invoked on `--remote` | host/user-ACL-scoped private exposure over the bound localhost port; returns/consumes an opaque teardown handle. **Contract proposed here; to be ratified against feature-005 (whose Technical Specification is still an unfilled placeholder as of 2026-06-10) — the `expose(port)->handle` / `teardown(handle)` shape does not yet exist and must be agreed during /aid-plan sequencing, same as LC-1.** | (owned by feature-005; this CLI only invokes expose/teardown) |

#### LC-3. Dispatch integration — coexist with bare `aid` (C4, hard)

- **Where it slots in `bin/aid`:** today `case "$1"` (`bin/aid:562`) handles `-h/--help`; then
  `SUBCMD="$1"; shift` (`bin/aid:569-570`); then `version`/`help`/`status`/`update`/`remove`, and the
  `add|remove|update` validation `case` at `bin/aid:653` whose `*)` arm rejects unknown commands with
  **exit 2** (`bin/aid:656-657`). A new branch **`if [[ "$SUBCMD" == "dashboard" ]]; then
  _cmd_dashboard_ctl "$@"; fi`** is added **before** that `add|remove|update` validation block (same
  placement style as the `version`/`status` early-return branches at `bin/aid:573,590`), so
  `dashboard` is recognized rather than falling into the unknown-command arm. The PowerShell twin adds
  the mirror branch before the `add/remove/update` validation at `bin/aid.ps1:572`.
- **Bare `aid` is untouched (C4):** the `$# -eq 0 -> _cmd_dashboard` path (`bin/aid:556-560`, mirror
  `bin/aid.ps1:385-406`) is not modified. `_cmd_dashboard()` and `_aid_usage` keep their exact current
  output; the new verb is reached **only** by the explicit token `aid dashboard …`. **Verified:**
  `aid dashboard` currently routes **nowhere good** — it hits the `add|remove|update` validation `*)`
  arm and exits 2 with "unknown command: dashboard". So introducing the handler **adds** behavior to a
  currently-erroring token and changes **no** existing success path. (The bare-`aid` status screen, and
  `aid version/status/add/remove/update`, are all byte-for-byte unchanged.)
- **Help surface:** `_aid_usage` (`bin/aid:100-115`) / `Show-AidUsage` (`bin/aid.ps1:133-149`) gain one
  line — `aid dashboard start <node|python> [--remote] | stop   Start/stop the local dashboard` — and a
  new `dashboard)` case arm with the per-command help (CLI-4). This **adds** a help line; the existing
  lines (incl. `aid   Show the dashboard`) are unchanged, so the "Show the dashboard" wording that
  documents bare `aid` is preserved (avoids the OQ3/C4 naming collision flagged in the source SPEC).

#### LC-4. Canonical source, vendored copies, and the CI gates (cross-platform mechanics)

- **`bin/aid` is hand-maintained canonical source, NOT a `canonical/`→5-tree render artifact.** Verified:
  `bin/aid`/`bin/aid.ps1`/`bin/aid.cmd` are **not** in `canonical/EMISSION-MANIFEST.md` and not under
  `canonical/`. So **the render-drift / `run_generator.py` pipeline does NOT touch them** — the
  "edit canonical, re-run the full generator" rule (memory: render-drift) does **not** apply here. The
  edit is made **directly** to `bin/aid` and `bin/aid.ps1` at the repo root.
- **Vendored copies are regenerated, not hand-edited.** `packages/npm/bin/aid` and
  `packages/pypi/aid_installer/_vendor/bin/aid` (+ `.ps1`/`.cmd`) are byte-identical copies produced by
  the `prepack` vendor step (`packages/npm/package.json` `"prepack": "node scripts/vendor.js"`;
  `packages/pypi/scripts/vendor.py`). **Do not edit the copies** — edit the root `bin/aid`/`bin/aid.ps1`
  and let vendoring propagate. (A task should run the vendor scripts, or rely on CI, to refresh them.)
- **ASCII-only gate (hard, `coding-standards.md` + memory).** `bin/aid`, `bin/aid.ps1`, `bin/aid.cmd`
  are all in `tests/canonical/test-ascii-only.sh`'s `SHIPPED_SCRIPTS`. The new handler MUST be
  **ASCII-only** — no Unicode glyphs, no smart quotes, no box-drawing in help/error text (use plain
  `->`, `|`, ASCII punctuation). This is enforced by CI.
- **Parity gate (hard).** `tests/canonical/test-aid-cli-parity.sh` asserts Bash and PowerShell produce
  identical `status` output and identical exit codes across subcommands. The dashboard handler MUST be
  added to **both** dispatchers with identical grammar, identical exit codes (CLI-2/CLI-3 table), and
  identical user-visible messages, and the parity suite extended to cover `dashboard start/stop`
  (a deliverable, not optional: see "Test scenarios").
- **`aid.cmd` is untouched.** It is the cmd.exe entry that forwards all args to `aid.ps1`
  (`bin/aid.cmd`), so `aid dashboard start …` already flows through it to the PowerShell twin; no edit
  to `aid.cmd` is needed. Likewise the npm `aid.js` / PyPI `__main__.py` shims forward argv verbatim
  (`pwsh`→`powershell` fallback on Windows, `bash` elsewhere), so the new subcommand works on all four
  install channels without shim changes.

---

### CLI / Command spec

This is the feature. ASCII-only (LC-4). Follows the existing `bin/aid` conventions: `_aid_die "<msg>"
<code>` style errors to stderr with the `ERROR: aid:` prefix (`bin/aid:122-125`), `-h/--help` per
subcommand, `--target`/`AID_TARGET` honored, `--verbose` honored.

#### CLI-1. Grammar

```
aid dashboard start <node|python> [--remote] [--port <n>] [--target <dir>] [--verbose]
aid dashboard stop                [--target <dir>] [--verbose]
aid dashboard (-h | --help)
aid dashboard start (-h | --help)
aid dashboard stop  (-h | --help)
```

- `<node|python>` — **required positional** for `start`; selects the feature-003 runtime. Exactly one
  of the two literals; anything else is a usage error.
- `--remote` — optional bool; additionally brings up feature-005's host/user-ACL-scoped exposure over
  the bound localhost port. Orthogonal to runtime (composes with either). Default off = local-only.
- `--port <n>` — optional int; overrides the default `8787` (DM-2). `1024..65535`; out-of-range or
  non-numeric -> usage error.
- `--target <dir>` / `--verbose` — same semantics as elsewhere in `bin/aid` (`bin/aid:594-597`).
- PowerShell twin accepts the same tokens **plus** the dash-style aliases the rest of `aid.ps1`
  accepts (`-Target`/`--target`, `-Verbose`/`--verbose`, `-h`/`--help`, `-Remote`/`--remote`,
  `-Port`/`--port`) — matching the dual-alias pattern at `bin/aid.ps1:447,452,606`.

#### CLI-2. Exit codes (documented + meaningful, `coding-standards.md` §3b)

Chosen to **not collide** with the meanings `bin/aid` already assigns (0 ok; 2 usage; 5 protect-on-diff
block; 6 no-manifest; 7 no-AID-install). New codes start at 8 to stay distinct and self-documenting.

| Code | Meaning |
|------|---------|
| `0` | Success (started / stopped / nothing-to-stop). |
| `2` | Usage error (bad/missing runtime, unknown flag, bad `--port`, stray positional on `stop`). |
| `3` | Server child failed to start (port in use, entry-point crash on boot — last log lines printed). (Within the dashboard path; `coding-standards.md` blesses `3` as a script-specific failure class. Existing uses of `3` are all on disjoint code paths — `bin/aid:256` `_cmd_update_self` (curl absent), `bin/aid.ps1:296` (update-self catch), and the PowerShell add/update version-resolution path — so there is no in-path conflict.) |
| `7` | No AID install / dashboard assets at `<target>` (mirrors `aid status` exit 7). |
| `8` | `start` while already running (a live `dashboard.pid` exists) — run `stop` first. |
| `9` | Selected runtime (`node`/`python3`) not found on PATH. |
| `10` | `--remote` requested but the secure exposure mechanism is unavailable; **local server still runs**, not exposed (C1 preserved). |

#### CLI-3. Error & status messages (exact, ASCII-only)

| Condition | Message (stderr unless noted) | Code |
|-----------|-------------------------------|------|
| missing runtime | `ERROR: aid: dashboard start requires a runtime: node or python (e.g. aid dashboard start python)` | 2 |
| bad runtime | `ERROR: aid: dashboard: unknown runtime '<x>' (expected: node or python)` | 2 |
| unknown flag | `ERROR: aid: dashboard: unknown flag: <x>` | 2 |
| bad `--port` | `ERROR: aid: dashboard: --port must be an integer in 1024..65535` | 2 |
| no AID install (no `.aid/`) | `ERROR: aid: dashboard: no AID install found at <target> (run 'aid add <tool>' first)` | 7 |
| install incomplete (no server entry-point) | `ERROR: aid: dashboard: AID install at <target> is missing the dashboard server (<runtime> entry-point not found); try 'aid update'` | 7 |
| already running | `aid: dashboard already running (runtime <r>, http://127.0.0.1:<port>); run 'aid dashboard stop' first.` (stdout) | 8 |
| runtime missing | `ERROR: aid: dashboard: <runtime> not found on PATH (install it, or try: aid dashboard start <other>)` | 9 |
| port in use | `ERROR: aid: dashboard: port <n> is already in use (try: aid dashboard start <runtime> --port <other>)` | 3 |
| child crash | `ERROR: aid: dashboard: server failed to start; last log lines:` + tail of `<logfile>` | 3 |
| `--remote` unavailable | `ERROR: aid: dashboard: --remote requested but the secure remote-exposure mechanism is not available on this host; the dashboard is NOT exposed. Local server still running at http://127.0.0.1:<port>.` | 10 |
| start success (local) | `Dashboard (<runtime>) running at http://127.0.0.1:<port> -- stop with: aid dashboard stop` (stdout) | 0 |
| start success (remote) | above + `Remote (private): <feature-005 URL>` (stdout) | 0 |
| stop success | `aid: dashboard stopped.` (stdout) | 0 |
| stop nothing | `aid: dashboard: not running (nothing to stop).` (stdout) | 0 |

#### CLI-4. Help text (the `dashboard)` arm of `_aid_usage` / `Show-AidUsage`)

```
aid dashboard start <node|python> [--remote] [--port <n>] [--target <dir>]
aid dashboard stop                [--target <dir>]
  Start or stop the local pipeline dashboard for the current project.
  <node|python>  select the server runtime to launch.
  --remote       also expose it to authorized users over a private channel (never public);
                 fails clearly if that mechanism is unavailable -- never binds publicly.
  --port <n>     listen port on 127.0.0.1 (default 8787).
  The dashboard binds to 127.0.0.1 only. 'stop' is idempotent and also tears down --remote.
```

The top-level usage block (`_aid_usage` default arm, `bin/aid:100-115`) gains one summary line:
`  aid dashboard start|stop ...      Start/stop the local dashboard`.

---

### Security Specs

Thin by design — deep exposure security is feature-005. This feature guarantees only the invariants
the *control surface* is responsible for (C1/C2/NFR1).

- **SEC-1. Loopback-only bind (C1/C2, hard).** `start` always passes the **literal `127.0.0.1`** as
  the server's `--host` (Feature Flow step 7). The bind address is **never** read from user input,
  config, or env — there is no flag to change it, no `--host`, no `0.0.0.0`. (Feature-003's server
  also hard-codes the loopback bind as its own invariant; this CLI never overrides it toward a wider
  bind.) A parity/self-check test asserts the launcher passes `127.0.0.1` and contains no
  `0.0.0.0`/wildcard token in the spawn path.
- **SEC-2. `--remote` never escalates to public (C1, hard).** The server is bound local-only **before**
  `--remote` is attempted (step 7 precedes step 10). If feature-005's mechanism is absent or fails,
  `start` reports exit 10 and the server **stays local-only** — there is **no fallback path that binds
  publicly or widens the bind**. Remote reachability is *exclusively* feature-005's ACL-scoped private
  channel layered over the loopback port; this CLI cannot make the dashboard public.
- **SEC-3. Clean teardown (NFR-hygiene).** `stop` tears down the feature-005 exposure (if any) and then
  the server process-group, so neither a listening socket nor an open private tunnel is left behind. A
  crashed server leaves only a stale `.aid/.temp/dashboard.pid` which the next `start`/`stop` reclaims
  (DM-3) — never a silently-still-exposed tunnel, because the tunnel handle lives in the record `stop`
  consumes.
- **Out of scope here (feature-005):** the ACL/grant model, the choice of mechanism (Tailscale w/
  host-user ACLs vs. evaluated alternatives, C3), and how authorization is enforced. This CLI treats
  feature-005 as an `expose(port) -> handle` / `teardown(handle)` contract (LC-2) — **proposed here,
  not yet ratified:** feature-005's Technical Specification is still a placeholder, so this exact
  shape must be agreed when feature-005 is specified / during /aid-plan sequencing (same status as
  the LC-1 seam).

---

### Test scenarios (deliverables, not polish)

| # | Scenario | Asserts |
|---|----------|---------|
| T-1 | `aid dashboard start python` in an AID repo (python present) | child spawned, bound `127.0.0.1:8787`, `dashboard.pid` written with correct fields, exit 0, URL printed |
| T-2 | `aid dashboard start node` (node present) | same, runtime=node |
| T-3 | second `start` while running | exit 8, "already running", no second child |
| T-4 | `aid dashboard stop` after a start | child gone (port free), record+logfile removed, exit 0 |
| T-5 | `aid dashboard stop` with no dashboard running | exit 0, "nothing to stop" (idempotent) |
| T-6 | `start` then crash the child, then `start` again | stale record reclaimed, fresh start, exit 0 |
| T-7 | `start foo` / `start` (no runtime) / unknown flag / bad `--port` | exit 2, correct message each |
| T-8 | `start python` with python3 absent (PATH stub) | exit 9, runtime-missing message, no record written |
| T-9 | `start python --port <busy>` | exit 3, port-in-use message |
| T-10 | bare `aid` and `aid version/status` regression | byte-identical output to pre-change (C4 guard) |
| T-11 | `--remote` on a host with no exposure mechanism (stub) | exit 10, server still local, record.remote=false |
| T-12 | Bash vs PowerShell parity for T-1/T-3/T-4/T-5/T-7 | identical exit codes + messages (extend `test-aid-cli-parity.sh`) |
| T-13 | ASCII-only guard | `bin/aid` + `bin/aid.ps1` still pass `test-ascii-only.sh` |

(`--remote` success path and the feature-005 mechanism itself are tested under feature-005; T-11 here
covers only the *clear-fail / never-public* contract this feature owns.)

---

### Known issues registered by this feature

This feature adds a new subcommand to `bin/aid`/`bin/aid.ps1` and a transient run-state file. It
introduces no schema/contract defect of its own: bind-loopback (SEC-1), never-public (SEC-2), idempotent
stop, and stale-record reclamation are all specified invariants verified by tests, not carried as debt;
the dual-dispatcher divergence risk is closed by the existing parity gate (T-12). The existing KIs
(KI-001..KI-004) are feature-001/002 concerns this feature does not touch. **No new `known-issues.md`
entry is warranted now.** (If, during implementation, the bounded readiness-wait or the cross-platform
process-group kill proves to need a runtime-specific workaround, that becomes a real KI at that time.)
