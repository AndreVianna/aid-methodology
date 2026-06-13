# LC-1 Spawn Seam — Binding Contract

**Status:** RATIFIED (task-014, DESIGN, delivery-002)
**Owners of the two sides:** feature-004 (the `aid dashboard` CLI that spawns) ⇄ feature-003 (the dual-runtime server it spawns).
**Consumed verbatim by:** task-016 / task-017 (server impls), task-021 / task-022 (CLI handler Bash + PowerShell).
**Resolves:** PLAN risk R3 — both consuming features referenced this seam (feature-004 §Layers LC-1 "proposed here, to be confirmed against feature-003"; feature-003 §Feature Flow LAUNCH "out of scope here") but neither owned it. This doc is now the single source of truth; the implementers do not re-decide.

This is a contract, not a suggestion. Where it says MUST, the parity/self-check tests (feature-003 PT-1, feature-004 SEC-1, T-1/T-12) assert it.

---

## 1. Entry-point filenames and install-tree location

The two server entry points are **hand-maintained dashboard assets** — siblings of the existing `dashboard/reader/` package, NOT `canonical/`→5-tree render artifacts (verified: nothing under `dashboard/` is in `canonical/EMISSION-MANIFEST.md`, same posture feature-004 §LC-4 establishes for `bin/aid`). They live under a dedicated `dashboard/server/` directory:

| Runtime | Entry-point path (repo-relative) | Interpreter |
|---------|----------------------------------|-------------|
| Python  | `dashboard/server/server.py`     | `python3` (>=3.11, per `technology-stack.md` / feature-003) |
| Node    | `dashboard/server/server.mjs`    | `node` |

**Install-tree placement.** The `dashboard/` subtree (`dashboard/reader/`, `dashboard/server/`, the static front-end assets) ships into an AID install under the repo's AID asset area exactly as the reader does. The CLI resolves the entry point relative to the resolved AID install for `<target>` — i.e. the CLI's "locate the feature-003 server entry point" step (feature-004 Feature Flow step 6) maps to:

```
<assets>/server/server.py     # python
<assets>/server/server.mjs    # node
```

where `<assets>` is the installed `dashboard/` root for `<target>`. A missing entry point is an "install incomplete" error (feature-004 exit 7, CLI-3 row "install incomplete").

**Python import path.** `server.py` reaches the reader via `from reader import read_repo` (the package at `dashboard/reader/`, `__init__.py` exports `read_repo`). Because `server.py` and the `reader/` package are siblings under `dashboard/`, the server adds its own directory's parent (the `dashboard/` root) to `sys.path` — i.e. it imports the sibling package by relative location, not by an installed distribution name. The Node `server.mjs` imports its own runtime's reader sibling (`dashboard/server/` ↔ the Node reader the per-runtime contract in feature-003 §Layers requires); the Node reader is built alongside `server.mjs` and is NOT the Python package.

**Why a `server/` subdir (not flat `dashboard/server.py`).** See Alternatives A.

---

## 2. Invocation arg grammar (the literal usage line)

```
<interp> <entry> --root <target> --host 127.0.0.1 --port <n>
```

Concretely, as the CLI spawns it (feature-004 Feature Flow step 7):

```
python3 <assets>/server/server.py  --root <target> --host 127.0.0.1 --port <n>
node    <assets>/server/server.mjs --root <target> --host 127.0.0.1 --port <n>
```

| Flag | Value | Definition |
|------|-------|------------|
| `--root <target>` | absolute path to the **repo root** | The repository directory the dashboard serves — the same `<target>` the CLI resolved (feature-004 Feature Flow step 2: `--target` \| `AID_TARGET` \| cwd; the absolute repo root, the value written as `target` in `dashboard.pid` DM-1). It is the **repo root that contains `.aid/`**, NOT the `.aid/` dir itself. See §3 for the read_repo reconciliation. |
| `--host 127.0.0.1` | the **literal** `127.0.0.1` | The bind address. MUST be the literal loopback string; the server MUST NOT widen it. See §4. |
| `--port <n>` | integer 1024..65535 | The TCP port to bind on `127.0.0.1`. The CLI passes the resolved port (default `8787`, DM-2, or `--port` override). |

Rules the server MUST honor:

- All three flags are **required**; the server MUST NOT assume a default `--root` (it always receives one from the CLI). Missing/malformed args → exit non-zero (see §4) without binding.
- The server MUST NOT accept any flag that widens the bind (no `--host 0.0.0.0`, no `--bind`, no `--public`). `--host` exists only because the CLI passes the literal `127.0.0.1`; the server SHOULD reject any `--host` value other than a loopback address (`127.0.0.1` / `::1`) rather than honor a wider bind. (Remote reachability is feature-005's ACL layer over the loopback port; the server never goes public — feature-003 LC-S, feature-004 SEC-2.)
- Flag order is fixed as written (`--root`, then `--host`, then `--port`) for a stable, greppable spawn line (SEC-1's self-check greps the launcher for `127.0.0.1` and the absence of wildcards). Servers SHOULD still parse order-independently, but the CLI emits exactly this order.
- The server MUST NOT require anything on **stdin** and MUST NOT read config/env for the bind host or root.

---

## 3. read_repo reconciliation (confirmed against the real signature)

**Confirmed signature** (`dashboard/reader/reader.py:45`, `__init__.py:9`):

```python
def read_repo(aid_root: Union[str, Path]) -> RepoModel
```

The docstring + body (lines 56-71) state and implement that `aid_root` **accepts either the repo root (which contains `.aid/`) or the `.aid/` dir itself** — it normalizes internally:

```python
root = Path(aid_root).resolve()
if root.name == ".aid":
    root = root.parent          # so a passed ".aid" dir is folded to the repo root
```

**Decision:** `--root <target>` is the **repo root** and the server passes it **verbatim** to `read_repo(--root)`. The server MUST NOT compute `<target>/.aid` and pass that; it passes the repo root and lets the reader locate `.aid/` (the reader's `locate_aid_root(root)` does this). This is the form consistent with how feature-004 resolves `<target>` (the repo root, default cwd — feature-004 DM-1 `target` field, Feature Flow step 2) and with feature-003 §Feature Flow LAUNCH which already writes `read_repo(aid_root)`.

So, in the Python server:

```python
model = read_repo(args.root)     # args.root == <target> == repo root; reader normalizes
```

The Node `server.mjs` calls its own runtime's `read_repo(root)` equivalent with the identical contract (per-runtime reader, feature-003 §Layers). Both feed `--root` straight in.

**Robustness note (not a re-decision):** because the reader also accepts a `.aid/` path, an operator who manually points `--root` at a `.aid/` dir still works — but the CLI always passes the repo root, and the spec'd contract is repo-root. The "accepts either" behavior is a convenience safety net, not the contract.

---

## 4. Readiness and exit semantics

| Aspect | Contract |
|--------|----------|
| **stdout** | The server prints **nothing required** on stdout. The CLI owns the user-facing URL line (feature-004 CLI-3 "start success" → `Dashboard (<runtime>) running at http://127.0.0.1:<port> ...`). The server MAY write diagnostics to stderr (captured to the CLI's `<logfile>`, DM-1), but the CLI MUST NOT depend on parsing server stdout to learn the URL or readiness — it already knows host+port (it chose them). |
| **Readiness signal** | Readiness is **"the socket is accepting on 127.0.0.1:<port>"**, NOT a stdout token. The CLI confirms via a bounded TCP-connect / HTTP GET poll (feature-004 Feature Flow step 8). The server's only obligation is: once it returns from binding successfully, the listener is accepting. The server MUST bind **before** doing any slow startup work, so "process alive + port accepting" is a true readiness proxy. |
| **Bind failure** | If the bind fails (port in use, permission, bad host), the server MUST **exit non-zero** promptly and MUST NOT fall back to any other host or port. The CLI detects the early exit (feature-004 step 8) → exit 3 ("port in use" / "child crash", CLI-3). The specific non-zero code is the server's choice; the CLI keys off **non-zero exit + child no longer alive**, not a specific code. |
| **Bad args** | Missing/invalid `--root`/`--host`/`--port` → exit non-zero **without binding** (do not bind a partial/default). |
| **Bind host invariant** | The server binds the **literal `127.0.0.1`** and MUST NOT bind `0.0.0.0` / `::` / any wildcard or wider address — enforced by feature-003 LC-S self-check (server source contains no `0.0.0.0`/`INADDR_ANY`/wildcard token) and consistent with feature-004 SEC-1 (the launcher passes the literal `127.0.0.1` and contains no wildcard token). Even though `--host` is an arg, it is a **fixed** loopback value, never a widening control. |
| **Clean exit on signal** | The server MUST exit cleanly on `SIGTERM` (POSIX) / `Stop-Process` (Windows) so the CLI's `stop` process-group kill (feature-004 Feature Flow stop step 5) frees the port. No lingering listener after teardown. |

---

## 5. Alternatives considered

### A. Entry-point location: `dashboard/server/{server.py,server.mjs}`  (CHOSEN)  vs.  flat `dashboard/{server.py,server.mjs}`

- **A1 (chosen) — `dashboard/server/` subdir.** Mirrors the existing `dashboard/reader/` package boundary (one directory per concern). It gives the Node server a home for its sibling reader + any front-end-adjacent server helpers without cluttering the `dashboard/` root, and keeps the two runtimes' server files plus the static `index.html`/assets cleanly grouped. Source: feature-003 §Layers ("the two halves: the static front-end and the dual-runtime thin server"; "new modules consuming feature-002's `read_repo`") + the established `dashboard/reader/` layout.
- **A2 — flat `dashboard/server.py` + `dashboard/server.mjs`.** Fewer directories; the entry points sit directly beside `reader/`. Rejected: it mixes the two server runtimes' files (and their per-runtime reader, front-end assets) into the `dashboard/` root with no grouping, and the Python `sys.path` story is muddier (the server would have to add `.` rather than a clean parent). The subdir cost is negligible and the grouping pays off as feature-003 adds the static front-end and the Node reader.
- **Recommendation:** A1.

### B. Entry-point naming: `server.py` / `server.mjs`  (CHOSEN)  vs.  `dashboard-server.{py,mjs}`  vs.  `serve.{py,mjs}`

- **B1 (chosen) — `server.py` / `server.mjs`.** This is exactly the pair feature-004 §LC-1 / Feature Flow step 6 already proposed (`<assets>/server.py`, `<assets>/server.mjs`); ratifying the proposed names avoids churn in the CLI handler that already references them. The `.mjs` extension (not `.js`) is deliberate: it forces ESM and lets `server.mjs` use `import`/top-level structure cleanly under Node's built-in module resolution with zero config (feature-003: "Node's built-in `http`", zero third-party deps, no build step).
- **B2 — `dashboard-server.py` / `.mjs`.** More self-describing in a flat tree. Unnecessary once they live under `dashboard/server/` (A1) — the directory already names the concern; the `dashboard-` prefix would be redundant.
- **B3 — `serve.{py,mjs}`.** Shorter. Rejected: "serve" reads like a verb/CLI subcommand and collides conceptually with the `aid dashboard start` control surface; "server" names the artifact (the thing that is spawned), which is what this seam is about. Source: feature-004 §LC-1 names it "feature-003 server".
- **Recommendation:** B1.

### C. `--root` semantics: pass the **repo root**  (CHOSEN)  vs.  pass the `.aid/` dir

- **C1 (chosen) — `--root` is the repo root; server passes it straight to `read_repo`.** Matches the reader's primary documented contract (`aid_root` = "the repo root directory that contains the `.aid/` subdirectory", reader.py:57) and matches what the CLI already resolves and records (feature-004 DM-1 `target` = the repo root). One value flows end-to-end with no path arithmetic in the server. Source: reader.py:45-71, feature-004 Feature Flow step 2 / DM-1, feature-003 §Feature Flow LAUNCH (`read_repo(aid_root)`).
- **C2 — `--root` is the `.aid/` dir; server passes `<target>/.aid` or the CLI passes `.aid` directly.** The reader tolerates this (it folds a `.aid`-named path to its parent, reader.py:70-71), so it would work. Rejected: it forces the server (or CLI) to do path arithmetic and diverges from the value the CLI naturally has (the repo root it resolved for `--target`/`AID_TARGET`/cwd and writes to `dashboard.pid`). Two callers doing the join is two chances to disagree; passing the repo root keeps the reconciliation trivial and the wire value identical to the recorded `target`.
- **Recommendation:** C1. The reader's "accepts either" is a safety net, not the contract.

### D. Readiness signal: socket-accept poll  (CHOSEN)  vs.  a stdout "ready" token

- **D1 (chosen) — readiness == socket accepting; nothing on stdout.** The CLI already knows host+port (it chose them), so a TCP connect / HTTP GET is a sufficient, language-agnostic readiness probe and keeps the server's stdout free (feature-004 owns the URL line; feature-004 Feature Flow step 8 already specs the bounded poll). Source: feature-004 §LC-1 ("prints nothing required on stdout"), Feature Flow step 8; feature-003 §Feature Flow LAUNCH (bind then serve).
- **D2 — server prints a `READY http://127.0.0.1:<port>` line the CLI parses.** Rejected: it couples the CLI to server stdout formatting across two runtimes (a parity burden — the line would have to be byte-identical), duplicates information the CLI already has, and is brittle if the server logs anything else first. The socket probe is the more robust, runtime-neutral signal.
- **Recommendation:** D1.

---

## 6. Implementer checklist (what task-016/017 and task-021/022 build to)

- [ ] (016/017) Entry points at `dashboard/server/server.py` and `dashboard/server/server.mjs`; siblings of `dashboard/reader/`; hand-maintained (not `canonical/`).
- [ ] (016/017) Parse exactly `--root <target> --host 127.0.0.1 --port <n>`; bind the **literal** `127.0.0.1`; reject/ignore any wider `--host`.
- [ ] (016/017) Call `read_repo(args.root)` with `--root` passed verbatim (repo root); no `.aid` arithmetic. Python: `from reader import read_repo` via the sibling package on `sys.path`.
- [ ] (016/017) Bind before slow work; exit non-zero (no fallback host/port) on any bind/arg failure; print nothing required on stdout; exit cleanly on SIGTERM/Stop-Process.
- [ ] (021/022) CLI spawns exactly the line in §2 with the resolved `<target>` (repo root) and port; confirms readiness via the §4 socket poll; records `target`/`port`/`bind=127.0.0.1` in `dashboard.pid` (DM-1).
- [ ] (021/022) On child early-exit → exit 3; never widen the bind on any failure path (SEC-1/SEC-2).
