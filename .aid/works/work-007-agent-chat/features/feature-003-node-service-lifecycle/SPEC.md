# Node Service Lifecycle

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md §5 FR-0.1, FR-0.3, FR-1, FR-7.2, FR-7.4, FR-7.5, §9 AC-7, §10 stage P1 | /aid-define |
| 2026-08-09 | Unsourced boot-survival claim removed; the CLI-versus-MCP criterion, unverifiable at P1, replaced with a single-core criterion | /aid-define (cross-reference) |
| 2026-08-09 | FR-7.6, FR-7.7 and AC-23 added to Source (separate distributable, Python prerequisite); FR-7.2 narrowed to the clauses this feature owns; AC-23 mapped to stage P1 in §10 | /aid-define (cross-reference) |
| 2026-08-09 | The deferred question of where deploy obtains the node carried into this SPEC's own Source and Description, so `/aid-specify` reads it here rather than only in REQUIREMENTS §8 | /aid-define (cross-reference Q20) |
| 2026-08-09 | FR-7.4 and FR-0.3 split by clause with `feature-006` — both were claimed whole by two features at two different stages, leaving the subscriber clause owned twice and verified nowhere | /aid-define (cross-reference) |
| 2026-08-09 | FR-7.2's carve-out extended to name the other-session-membership clause, now claimed by `feature-005` | /aid-define (cross-reference) |
| 2026-08-09 | Criteria added for FR-7.6 and FR-7.4's in-tool-skills clause — both were claimed here and verified by nothing, and FR-7.6 is the requirement protecting AID's zero-dependency decision | /aid-define (cross-reference) |
| 2026-08-09 | The FR-7.4 criterion restated as transport containment — its first wording tested an in-tool skill, and this work ships none, so it was unpassable as written | /aid-define (cross-reference) |
| 2026-08-09 | That restatement over-reached — "reachable only through the CLI" would be false at P2 once the MCP façade ships, and it claimed the transport clause `feature-006` owns. Retargeted onto the clause this feature does own: the node publishes no client library, so a later skill has nothing to reimplement against | /aid-define (cross-reference) |
| 2026-08-09 | Dropped the surviving exclusivity clause ("the CLI is the only integration point published"), which the MCP façade contradicts from P2 onward; the criterion now rests on the no-client-library test alone, which holds at every stage | /aid-define (cross-reference) |
| 2026-08-09 | Technical Specification added. Fixed the eight keystone decisions nine later features consume: the process model is the dashboard server's, reused verbatim (setsid / `Start-Process` detach, JSON pid record under `$HOME/.aid/.temp/`, TCP-probe readiness, group-kill + Windows `taskkill /F /T` + port reap); the store is **stdlib `sqlite3`** at `$HOME/.aid/chat/chat.db` in WAL with `synchronous=FULL` and a forward-only migration stamp; the one core is `aid_chat_node/core/api.py`'s closed **operation registry**, on the dashboard's own `OP_TABLE` precedent, with the message-plane subset being exactly what `feature-008` faces; the node lives at a new top-level `chat-node/` with its own `pyproject.toml` and is kept out of all five install manifests; `aid chat` is a thin argv translator over `python -m aid_chat_node`, so there is one implementation and free Bash/PowerShell parity. Exit codes reuse the CLI's existing scheme — **9 is the Python-prerequisite failure**, the same code `aid dashboard start python` already returns for the same condition. Deploy idempotence defined byte-level, and "ships no operator-facing command" made inspectable as "the distribution declares no `[project.scripts]`". **Four findings beyond the requirements:** `test.yml` has no pytest lane (Python tests reach CI only through a shell driver suite); `technology-stack.md` documents a `pytest` command for tests that are `unittest`; `aid dashboard`'s interpreter probe is `python3`-only, which is the wrong name on Windows; and the probe must be a single-line `-c` script or pyenv-win mangles it (`tech-debt.md` W4-3 class G). The deferred deploy-source question is laid out with four options and a recommendation, **awaiting the stakeholder** | /aid-specify |
| 2026-08-09 | Re-gate cycle 2 (D+) — eight findings fixed. **Five of them were introduced by the previous cycle's own fixes**, which is the finding behind the findings. (1) **The new exit code was wrong.** The SPEC claimed "10 is unused by `bin/aid`"; `aid dashboard start --remote` exits 10 today (`bin/aid`:1343, twin `bin/aid.ps1`:1372). The claim was checked against the *documented* scheme, and neither `docs/install.md` nor `coding-standards.md` reaches a code the shipped script uses — **a code is free only if the scripts do not use it.** Moved to **exit 5**, verified free by grep across both twins, `lib/`, and both installers. (2) The exit-code table had no row for 5 and still said "No new code is introduced". Both fixed, with the SHOULD-reuse rule addressed head-on. (3) The **WEDGED** observation the flow now names had no row in the State Machines table, which explicitly denied a degraded state — added, with `status` output, exit, and why it is an observation and not a lifecycle state; `responding:` added to the status shape and `CN-STATUS-WEDGED` to the oracles. (4) **S-1's allocation used SQLite `RETURNING`, which needs SQLite ≥ 3.35 — a floor `requires-python = ">=3.12"` does not entail**, and whose absence fails at *every send* while deploy and `/healthz` report healthy. Rewritten as read-then-update inside the `BEGIN IMMEDIATE` the insert already holds; a standing rule added that the node uses no post-baseline SQLite feature without a stated floor and a probe that enforces it. (5) The `member` re-key had not been carried to **`message.sender`** — untyped, unkeyed, and its representation unstated, while `feature-005` was about to be written against it. Now **S-5**: `sender` (member id) + `sender_label` (machine-qualified name at send time), with **no foreign key** and the reason stated — `CASCADE` would delete a reaped member's messages against S-3, `RESTRICT` would make any member who ever sent anything unreapable against `feature-011`. Also: the oracle count (four extras → six, sixteen rows), the "six-field pid record" claim (nine and eight), and D-7's summary, which still carried the whole-directory idempotence formulation the body had already repudiated | /aid-specify (review fix) |
| 2026-08-09 | Review gate (D+) — six findings fixed, one routed out. **The store had a real correctness bug:** S-1 declared a per-chat monotonic `seq` with no durable counter, so `MAX(seq)+1` was the only derivation the shape allowed — and it is not monotonic across the deletions S-3 authorises `feature-011` to make. A chat trimmed empty would restart at `seq` 1 against positions of 1000, and `inbox` would silently never return the new messages. `chat.next_seq` added, with allocation specified. **`member` re-keyed** to a surrogate id with `(machine, name)` unique: a bare `name` primary key could not hold `alice` on two machines, so `feature-009` would have had to rewrite the table and every foreign key into it — the one thing a keystone exists to prevent. FR-6.3's store-and-forward queue named as deliberately left open, with the reason. **`deploy` could return 8** on a live-but-unresponsive node, contradicting its own "never surfaces 8" and putting AC-7 at risk; step 5 now has three branches, a bounded readiness re-probe, and a new exit 10 for the wedged case. AC-7's byte-level oracle narrowed from the whole store directory to a named set — WAL sidecars are written by the running node, including by the `/healthz` probe deploy itself issues, so the old assertion could fail for doing its job. The version-default question un-settled in the flow (it is deferred), and a `taskkill` citation repointed from a comment block to the two real call sites | /aid-specify (review fix) |

## Source

- REQUIREMENTS.md §5 FR-0.1, FR-0.3 (administration and message-plane halves only — the subscriber half completes at stage P2 with `feature-006`), FR-1.1–1.3, FR-7.2 (deploy / start / stop / status / configuration clauses only — the chat-lifecycle and other-session-membership clauses belong to `feature-005`, the retention-policy clause to `feature-011`), FR-7.4 (the in-tool-skills-invoke-the-CLI clause only — the subscriber-is-a-CLI-invocation clause belongs to `feature-006`), FR-7.5, FR-7.6, FR-7.7, §7 Constraints, §8 Assumptions (the deferred question of where `aid chat deploy` obtains the node, including on an offline machine — carried here for `/aid-specify`), §9 AC-7, AC-23, §10 stage P1

## Description

The background service that holds the messages, and the commands that run it.

The node does **one job** — move messages between sessions. It ships no commands of its
own, no installer, and no operator screen. Everything a human does to it is an `aid`
subcommand: put it there, start it, ask how it is, stop it. Putting it there twice changes
nothing the second time.

Once running it is independent of every session. Sessions come and go; the node stays — it
outlives the window that started it. (Whether it also restarts itself after a machine
reboot is **not** specified: no requirement asks for it, and nothing here tests it.)

The node is a **separate package with its own dependencies**, so installing `aid` does not
drag two third-party libraries onto every user's machine. `aid` installs and runs it; `aid`
does not contain it. One consequence follows and is deliberate: **the node needs Python, and
only one of `aid`'s four install channels guarantees it.** So chat states Python as a
prerequisite and says so with a clear error rather than a crash. AID itself gains no Python
requirement — a user who never enables chat notices nothing.

**One question is deliberately left open for `/aid-specify`: where the deploy command gets the
node from.** Because `aid` does not carry it, deploy has to fetch it — from a package index,
from a bundle, or otherwise — and one of the four install channels serves **offline,
air-gapped machines** with no index to reach. Nothing in this feature's criteria depends on
the answer, which is why it is not guessed at here. It is recorded so that whoever writes the
technical specification knows it is theirs to settle rather than assumes it was decided.

Beneath the surface there is **one implementation**. The CLI is not a second version of the
node's logic, and the MCP façade added later is not a third — both are thin faces over the
same core. This matters more than it sounds: two implementations drift, and the drift shows
up as messages that behave differently depending on which door they came through.

## User Stories

- As the operator, I want one command to stand the node up on a clean machine, so that
  setting up a new machine is not a procedure.
- As the operator, I want to run that command again without fear, so that I never have to
  remember whether I already did.
- As the operator, I want to see whether the node is running and stop it, so that I am not
  guessing at a background process.
- As a session, I want the node to already be there, so that my ability to send a message
  does not depend on which window opened first.

## Priority

Must

## Acceptance Criteria

- [ ] Given a machine with no node, when the operator runs the deploy command, then the
      node is installed and running.
- [ ] Given a machine with `aid` installed through a non-PyPI channel and no Python present,
      when the operator deploys the node, then it fails with an explicit message naming
      Python as the prerequisite — not a stack trace — and every unrelated `aid` command
      still works.
- [ ] Given a node already running, when the deploy command runs again, then nothing
      changes and no error is raised.
- [ ] Given a running node, when the operator asks for status, then its state is reported.
- [ ] Given a running node, when the operator stops it, then it stops.
- [ ] Given a running node, when the session that started it exits, then the node keeps
      running.
- [ ] Given the node's own distribution, when it is inspected, then it ships no
      operator-facing command of its own.
- [ ] Given `aid`'s own package manifests, when their dependency lists are read after this
      work ships, then they are **still empty** — the node's third-party libraries live in the
      node's distribution, and a user who never enables chat installs none of them. This is
      what makes the node a separate distributable rather than a folder in the installer, and
      it is the whole reason FR-7.6 exists.
- [ ] Given the node's distribution, when it is inspected, then it offers **no client library
      or SDK** for a caller to bind to. So an in-tool skill written later has nothing to
      reimplement against and invokes the CLI by construction, which is what FR-7.4's first
      clause asks for. (The MCP façade is a *face over the same core*, added at stage P2 by
      `feature-008`, not a client library — and the separate question of the HTTP transport
      staying internal to the subscriber belongs to `feature-006`.)
- [ ] Given the node's implementation, when it is inspected, then message-plane logic lives
      in one core that the CLI calls rather than reimplements — so the MCP façade added at a
      later stage has a single core to face.

---

## Technical Specification

> Every repository path, line number, command and count below was read on disk in this
> worktree at `master`@`9260fc88`. Where disk disagreed with a document, the disagreement is
> stated rather than smoothed over — see
> [Findings beyond the requirements](#findings-beyond-the-requirements).

This is the keystone. Nine of the eleven sibling features build on what is fixed here, so the
spec is organised around **what is settled and who consumes it** rather than around the
feature's own boundary. Two properties govern every choice:

1. **Reuse before invention.** AID already runs exactly one long-lived local background
   service — the dashboard server — and has already paid for the cross-platform spawn, probe
   and reap on Windows, macOS and Linux, twice (Bash and PowerShell). The node's process model
   is that model, reused, not a second one. Every place this SPEC diverges from it says so and
   says why.
2. **Say what is left open.** A P1 skeleton that quietly decides P2's and P3's questions is
   worse than one that names them. [What this SPEC deliberately does not
   settle](#what-this-spec-deliberately-does-not-settle) is a closed list, and the deferred
   deploy-source question is presented as options and a recommendation
   [awaiting the stakeholder](#the-deferred-question-where-deploy-obtains-the-node), not as a
   decision.

**The single most consequential fact about stage P1: the node has no third-party dependency
at all.** `mcp`/FastMCP arrives with `feature-008` (P2) and `zeroconf` with `feature-009` (P3)
(REQUIREMENTS §8 Toolchain). Everything P1 needs — an HTTP server, a durable store, JSON, a
virtual environment — is in the Python standard library. So FR-7.6 is satisfied at P1 by
construction, and the dependency question the requirements anticipate becomes real one stage
later. That timing changes the answer to the deferred question, and is stated there.

### Scope Ledger — the decisions this SPEC fixes, and who consumes them

| # | Decision | Fixed as | Consumed by |
|---|---|---|---|
| D-1 | **Process model** | One detached Python process, loopback-bound, spawned by `aid`; `setsid` on POSIX, `Start-Process -WindowStyle Hidden` (no redirection) on Windows; JSON pid record; TCP+`/healthz` probe; group-kill / `taskkill /F /T` + port reap | `feature-006` (holds connections open against this process), `feature-007`, `feature-009` |
| D-2 | **Store** | Stdlib `sqlite3`, one file at `$HOME/.aid/chat/chat.db`, `journal_mode=WAL`, `synchronous=FULL`, forward-only numbered migrations stamped in `schema_meta` | `feature-004` (positions), `feature-005` (AC-9 durability, ordering, dedupe), `feature-009` (**machine-qualified member identity; and the store-and-forward queue FR-6.3 needs, which is left open below**), `feature-010`, `feature-011` (trim point), `feature-012` (audit read) |
| D-3 | **The one core (FR-0.1)** | `aid_chat_node/core/api.py` holds a **closed operation registry**; `transport/` and every face are generated from it; nothing under `core/` may import a transport or a face | `feature-008` (the MCP façade is the `plane == "message"` subset of the registry), `feature-005`, `feature-006` |
| D-4 | **Where the node lives** | New top-level `chat-node/` with its own `pyproject.toml`; absent from all five install manifests and from both `aid` package manifests | `feature-008` (ships inside this distributable), `feature-009` |
| D-5 | **CLI surface** | `aid chat <verb>`; process verbs handled in `bin/aid`(`.ps1`), every other verb translated to `python -m aid_chat_node <verb>`; exit codes reuse the CLI's existing scheme | every feature that extends this surface — with a verb (`feature-004`, `feature-005`, `feature-006`, `feature-009`, `feature-012`) or with flags and config keys on an existing one (`feature-010`, `feature-011`) |
| D-6 | **Python prerequisite (FR-7.7 / AC-23)** | Single-line version probe over an ordered candidate list, before any side effect; failure is **exit 9** with an actionable message; the probe exists only inside the `chat` dispatch arm | — (nothing consumes it; and `feature-002` is deliberately *not* coupled to it — the repository's declared floor never reaches the node) |
| D-7 | **Deploy idempotence (AC-7)** | Two short-circuits — version match skips install, live `/healthz` skips spawn — with "nothing changed" defined byte-level over a **named set** — the venv tree, `config.yml` and `chat.db` proper (**not** the `-wal`/`-shm` sidecars, which the running node writes on its own, including under the `/healthz` probe deploy itself issues) — plus no new pid | — (verified here) |
| D-8 | **Config** | `$HOME/.aid/chat/config.yml`, flat `key: value`, read through `read-setting.sh`'s conventions, written only by `aid chat config set` | `feature-004` (stale threshold), `feature-006` (long-poll timeout), `feature-011` (TTL, unread depth, overflow, reap threshold) |

---

### Layers & Components

Three artifacts change or appear. Nothing else does, and the "nothing else" is the load-bearing
half — it is what FR-7.6 asks for, stated as a list a reviewer can grep.

| Artifact | Status | Role |
|---|---|---|
| `chat-node/` | **new top-level directory** | The node's source: a self-contained Python distributable with its own `pyproject.toml`, its own `requires-python`, and (from P2) its own `dependencies` |
| `bin/aid` | edited | The Bash face: a `chat` dispatch arm, a `_cmd_chat_ctl` handler, and a `chat` block in `_aid_usage` |
| `bin/aid.ps1` | edited | The PowerShell twin of the same, per the standing rule that a language twin changes in the same commit (`coding-standards.md` § Conventions, "Touching a language twin") |

#### What is deliberately NOT touched — the concrete form of FR-7.6

The node is a separate distributable exactly to the extent that it is absent from the file
sets the `aid` CLI ships through. Those sets are enumerated on disk, so the requirement is
checkable rather than asserted:

| File set | Where declared | Node's presence |
|---|---|---|
| The dashboard server+reader unit (23 paths) | `dashboard/MANIFEST` | **absent** — the node is not a dashboard file |
| npm payload | `packages/npm/package.json` `files` (`bin/`, `lib/`, `dashboard/`, `scripts/postinstall.js`, `VERSION`, `README.md`, `LICENSE`) | **absent** |
| PyPI payload | `packages/pypi/pyproject.toml` `[tool.hatch.build.targets.*].artifacts` (`aid_installer/_vendor/**`) | **absent** |
| curl / irm bootstrap payload | `install.sh`:704-720 and `install.ps1`:703-715, both deriving their dashboard set from `dashboard/MANIFEST` (as do `packages/npm/scripts/vendor.js`:33-36 and `packages/pypi/scripts/vendor.py`:23) | **absent** |
| The CLI bundle `aid-cli-v<VERSION>.tar.gz` | `release.sh`:310-343 (`bin/aid`, `bin/aid.ps1`, `bin/aid.cmd`, `lib/aid-install-core.sh`, `lib/AidInstallCore.psm1`, `VERSION`, plus the `dashboard/MANIFEST`-derived set) | **absent** |
| `aid`'s declared runtime dependencies | `packages/npm/package.json` `"dependencies": {}`; `packages/pypi/pyproject.toml` `dependencies = []` | **unchanged — both stay empty** |

That last row is the AC. D10 ("Polyglot, dual-channel, zero-dependency distribution",
`decisions.md`:202-211) is preserved, not amended: the two empty dependency sets are its
stated evidence, and this feature adds nothing to either. A user who never runs
`aid chat deploy` installs **none of the node and none of its dependencies** — the only growth
on that user's disk is the few kilobytes the `chat` verb adds to `bin/aid` and its twin.

Also untouched: `canonical/` and therefore `profiles/`. The node is not AID toolkit content
rendered into five host dialects — it is a runtime component, like `dashboard/`. So
`canonical/EMISSION-MANIFEST.md` gains no row and `test.yml`'s `render-drift` job is not in
this feature's blast radius.

#### Why `chat-node/` at the repository root

`dashboard/` is the precedent and the shape matches exactly: a runtime component, written in
its own language, living at the root, vendored (or in this case *not* vendored) into the
channels by an explicit manifest rather than by being part of the CLI's source
(`project-structure.md` § Top-Level Directory Purposes).

**Rejected: `packages/chat-node/`.** `packages/` has a stated meaning — "Distribution wrappers
that vendor `bin/`, `lib/`, and `dashboard/` for npm and PyPI publication"
(`project-structure.md`). The node is not a wrapper around the `aid` payload; it is a
different program. Putting it there would make the directory mean two things.

**Rejected: `canonical/aid/…`.** That tree renders into five profiles and both dogfood
installs. The node is one machine-level service, not per-repo toolkit content, and rendering
it five times would be five copies of a program that must exist once per machine.

#### Inside `chat-node/`

```
chat-node/
├── pyproject.toml                  # requires-python = ">=3.12"; dependencies = [] at P1
├── README.md                       # states plainly: an implementation detail of `aid chat`
└── aid_chat_node/
    ├── __init__.py                 # __all__ = []  -- no public API is exported
    ├── __main__.py                 # `python -m aid_chat_node <verb>`; argparse; main() -> int
    ├── core/                       # THE ONE CORE. No transport, no face, no argparse.
    │   ├── api.py                  # the operation registry (D-3)
    │   ├── store.py                # sqlite3 open/migrate/transaction helpers (D-2)
    │   ├── config.py               # config.yml read/write (D-8)
    │   ├── errors.py               # the domain error-code enum
    │   └── migrations/001_p1.sql   # forward-only, numbered
    ├── transport/
    │   ├── server.py               # ThreadingHTTPServer; POST /op, GET /healthz
    │   └── client.py               # the in-distribution caller __main__ uses
    └── service.py                  # the long-lived process: open store, migrate, serve, log
```

**The seam, stated so `feature-008` can be written against it without redesign.**
`core/api.py` declares one table:

```python
# aid_chat_node/core/api.py
OPERATIONS: dict[str, Operation] = { ... }   # name -> Operation

@dataclass(frozen=True)
class Operation:
    name:    str                     # e.g. "chat.send"
    plane:   Literal["message", "admin"]
    params:  dict[str, ParamSpec]    # name -> (type, required, default)
    result:  dict[str, str]          # field -> type, for the success envelope
    handler: Callable[[Store, dict], dict]
```

Three properties follow, and each is one of the sibling features' problems solved in advance:

- **FR-0.1 (one core).** `transport/server.py` builds its dispatch table by iterating
  `OPERATIONS`. It contains no operation-specific branch. The CLI reaches operations only
  through that transport. So a second implementation cannot appear without deleting the
  registry, which a reviewer can see.
- **FR-0.2 / FR-7.3 (no administration over MCP).** `feature-008`'s façade registers
  `{op for op in OPERATIONS.values() if op.plane == "message"}` as MCP tools. The privilege
  boundary is therefore a **property of the table**, not a rule someone has to remember when
  adding an operation — a new admin operation is invisible to MCP by default, and making it
  visible requires deliberately typing `plane="message"`.
- **`feature-008`'s "the façade holds no state and no logic of its own".** It cannot: the
  handler is the registry's, and `core/` is import-forbidden from reaching a face.

This is not a new pattern in this repository. `dashboard/server/server.py` already dispatches
every mutation through a "closed `OP_TABLE`" whose stated purpose is that "the server never
interprets a client-supplied path or command" (`dashboard/server/server.py`:12, :27, :977-982).
The node's registry is the same device, extended to carry the plane tag.

**The layering rule is machine-checked**, not documented: no module under `aid_chat_node/core/`
may import `http`, `socket`, `argparse`, `aid_chat_node.transport` or `aid_chat_node.service`.
See [Verification](#verification), `CN-LAYER`.

---

### Data Model

#### The store

| Property | Value | Why |
|---|---|---|
| Technology | **`sqlite3` from the Python standard library** | It gives crash durability, atomic multi-row writes and cheap trimming at **zero dependency cost**. FR-7.6 permits the node dependencies; it does not make them free, and the fewer it carries the smaller the install it asks of a user. The two alternatives actually considered are rejected below, with reasons |
| Location | `$HOME/.aid/chat/chat.db` | Per-user, always writable. Follows the pid-file precedent exactly: `bin/aid`:1202-1205 pins the dashboard's runtime state to `${HOME}/.aid/.temp` with the comment *"always per-user `$HOME/.aid`, never `AID_STATE_HOME` on global installs"* — because `AID_STATE_HOME` resolves to `/var/lib/aid` on a global install (`bin/aid`:65-71) and an unprivileged `aid` cannot write there |
| Journal mode | `PRAGMA journal_mode=WAL` | Concurrent readers with one writer; needed from P2, when `feature-006` holds subscriber connections open while sends continue |
| Durability | `PRAGMA synchronous=FULL` | AC-9 requires unacknowledged messages and every member's position to survive a node restart. `NORMAL` survives a process kill but not a power loss; `FULL` costs one fsync per committed send, and §6 sets **no performance target for v1**, so correctness wins and the trade is recorded rather than discovered |
| Concurrency | One connection per request thread (`threading.local()`), `PRAGMA busy_timeout=5000`, writes under `BEGIN IMMEDIATE` | `sqlite3` connections are not shareable across threads; `ThreadingHTTPServer` gives one thread per request |
| Foreign keys | `PRAGMA foreign_keys=ON` per connection | Off by default in SQLite; deleting a chat must take its messages and memberships with it (`feature-005`'s delete criterion) |

**Rejected: an append-only JSONL log per chat plus sidecar position files.** It is closer to
this repository's existing habits (`.aid/` is plain files) and it was the first candidate. It
fails on three counts that all belong to sibling features: a send must append a message *and*
leave every member's position consistent in one atomic step (`feature-005`); trimming
(`feature-011`) means rewriting the whole file, so a crash mid-trim can lose delivered
messages; and dedupe on an idempotency key (FR-4.5) becomes a full scan. SQLite gives all
three in the standard library, which is why the plain-files habit does not extend here.

**Rejected: an in-memory store with periodic snapshots.** AC-9 is a restart-survival
criterion; a snapshot window is a loss window.

#### Schema ownership

This SPEC fixes the **store contract**. The columns are the message-plane features'.

Fixed here, and not changeable by a later feature without reopening this SPEC:

- **S-1.** One chat's messages carry a **per-chat monotonic integer `seq`**, allocated from a
  **durable per-chat counter (`chat.next_seq`)** and **never reused**. That is the FIFO
  guarantee of §6 Ordering ("every member sees that chat's messages in the same order; no
  ordering guarantee *across* chats") expressed as a primary key rather than as a convention.

  **The counter is durable precisely because S-3 deletes rows.** `MAX(seq) + 1` would be the
  obvious derivation and it is wrong: retention trims acknowledged messages, so a chat trimmed
  empty would restart at `seq` 1 while every `membership.position` still read, say, 1000 — and
  `inbox`, which returns messages *after* the caller's position (FR-4.3), would silently never
  return them again. Messages sent, never delivered, never reported: the exact failure §6's
  overflow policy exists to prevent, arriving through the store instead. Allocation reads the
  counter, uses that value, bumps it, and inserts — **all inside the one `BEGIN IMMEDIATE`
  transaction the insert already runs in** (D-2), so a crash between any two of them leaves
  none of them:

  ```sql
  BEGIN IMMEDIATE;                                              -- write lock taken here
  SELECT next_seq FROM chat WHERE name = :chat;                 -- this run's seq
  UPDATE chat SET next_seq = next_seq + 1 WHERE name = :chat;
  INSERT INTO message (chat_name, seq, ...) VALUES (:chat, :seq, ...);
  COMMIT;
  ```

  **This deliberately uses no `RETURNING` clause, and the reason is a portability trap worth
  naming.** The obvious one-statement form,
  `UPDATE chat SET next_seq = next_seq + 1 WHERE name = ? RETURNING next_seq - 1`, requires
  **SQLite ≥ 3.35.0**, and nothing in this project guarantees that. `requires-python = ">=3.12"`
  does not entail it: CPython's `sqlite3` builds against whatever `libsqlite3` the host
  provides, and its own documented floor for 3.12 is far below 3.35. On such a host the failure
  is maximally unhelpful — deploy exits 0, `/healthz` answers, and **every send fails**. The
  read-then-update form above is correct on every SQLite that supports transactions at all,
  needs no version floor, no probe extension, and no runtime feature detection. It is not a
  race: `BEGIN IMMEDIATE` takes the write lock before the `SELECT`, so two concurrent senders
  serialise (D-2 also sets `busy_timeout=5000`).

  **The rule this sets for every later feature:** the node uses no SQLite feature newer than
  what a plain transactional SQLite provides. `RETURNING`, `UPSERT ... RETURNING`, strict
  tables, `JSON` operators and window functions are all off the table unless a feature states a
  SQLite floor *and* extends D-6's probe to enforce it — which today reads `sys.version_info`
  only and would not catch a violation.
- **S-2.** A member's progress in a chat is **one row per (chat, member)** holding the last
  acknowledged `seq`. It is stored with the membership, not with the member, so it survives
  re-registration of the name (FR-2.2, `feature-004`) and so a session in several chats holds
  one position per chat (FR-4.2).
- **S-3.** The **trim point** of a chat is `MIN(position)` over its live (un-reaped) members.
  `feature-011` enforces retention against that expression; nothing else may delete a message
  row.
- **S-4.** Schema evolution is **forward-only numbered migrations**. `core/migrations/NNN_*.sql`
  applied in order inside one transaction at node start; `schema_meta.schema_version` is
  stamped after each. A store whose `schema_version` is **higher** than the running code knows
  makes the node **refuse to start** (exit non-zero, explicit message) rather than operate on a
  shape it does not understand — the same fail-safe D13 applies to a repo's `format_version`
  stamp (`decisions.md`:248-253; `bin/aid`:116 `AID_SUPPORTED_FORMAT`).
- **S-5. A message records who sent it in two columns, and carries no foreign key.**
  `message.sender` holds the sender's `member.id`; `message.sender_label` holds the
  machine-qualified name **as it read at send time** (`<machine>/<name>` — the same rendering
  FR-2.2 gives a full session id). `feature-005` writes both on every send; nothing rewrites
  either afterwards.

  **Why two columns and not one.** The id is the join key — it is what lets `feature-012`
  count per-session activity and what `feature-010`'s directed messages resolve against. The
  label is the *historical* fact, and it is needed because the id can outlive the row it points
  at: `feature-011` reaps dead members, and reaping deletes the `member` row (which is what
  cascades `membership` away and raises S-3's `MIN(position)`). Without the label, every
  message a reaped session ever sent would become unattributable.

  **Why no foreign key — this is a decision, not an omission.** Both available behaviours are
  wrong here. `ON DELETE CASCADE` would delete a reaped member's messages, which S-3 forbids
  outright ("nothing else may delete a message row") and which would silently destroy other
  members' unread history to tidy up one dead session. `ON DELETE RESTRICT` would make a member
  who has ever sent anything **unreapable**, breaking `feature-011`'s reap and, through it, the
  retention that S-3 depends on. The store therefore keeps `sender` as a plain integer and
  accepts that it may dangle after a reap; `sender_label` is what makes a dangling id harmless.
  **A reader that joins `sender` to `member` MUST tolerate no match and fall back to
  `sender_label`** — that is a contract on `feature-005`, `feature-010` and `feature-012`, not
  an implementation detail.

  **P1 degeneracy, same as `member.machine`.** At P1 there is one machine, so every
  `sender_label` begins with this node's own id and no P1 behaviour depends on the prefix.
  `feature-009` is where it starts carrying information.

The P1 migration (`001_p1.sql`) creates `schema_meta` and the four tables the message plane
needs, so that `feature-004` and `feature-005` extend a shape rather than inventing one:

```sql
CREATE TABLE schema_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
-- rows: schema_version, protocol_version, node_id, created_at

CREATE TABLE member (                       -- FR-2, owned by feature-004
  id            INTEGER PRIMARY KEY,        -- surrogate; see the note below
  machine       TEXT NOT NULL,              -- this node's id at P1; a peer's from feature-009
  name          TEXT NOT NULL,              -- unique *per machine* (FR-2.2)
  tool          TEXT NOT NULL,
  cwd           TEXT NOT NULL,
  capabilities  TEXT NOT NULL DEFAULT '[]', -- JSON array
  registered_at TEXT NOT NULL,              -- ISO-8601 UTC
  last_seen_at  TEXT NOT NULL,              -- drives stale (feature-004) and reap (feature-011)
  UNIQUE (machine, name));                  -- FR-2.2's full id, enforced by the store

CREATE TABLE chat (                         -- FR-3, owned by feature-005
  name       TEXT PRIMARY KEY,              -- local name; machine qualification is feature-009
  next_seq   INTEGER NOT NULL DEFAULT 1,    -- S-1: durable high-water, never rewound
  created_at TEXT NOT NULL);

CREATE TABLE membership (                   -- S-2
  chat_name   TEXT NOT NULL REFERENCES chat(name) ON DELETE CASCADE,
  member_id   INTEGER NOT NULL REFERENCES member(id) ON DELETE CASCADE,
  position    INTEGER NOT NULL DEFAULT 0,   -- last acked seq (FR-4.4)
  joined_at   TEXT NOT NULL,
  PRIMARY KEY (chat_name, member_id));

CREATE TABLE message (                      -- FR-4, owned by feature-005
  chat_name       TEXT NOT NULL REFERENCES chat(name) ON DELETE CASCADE,
  seq             INTEGER NOT NULL,         -- S-1
  sender          INTEGER NOT NULL,         -- S-5: member.id, deliberately NO foreign key
  sender_label    TEXT NOT NULL,            -- S-5: machine/name as it was at send time
  body            TEXT NOT NULL,            -- no size limit (§6 Max payload size: none)
  kind            TEXT,                     -- FR-4.6
  correlation_id  TEXT,                     -- FR-4.6
  reply_to        TEXT,                     -- FR-4.6
  idempotency_key TEXT,                     -- FR-4.5
  sent_at         TEXT NOT NULL,
  PRIMARY KEY (chat_name, seq));

CREATE UNIQUE INDEX message_idem ON message(chat_name, idempotency_key)
  WHERE idempotency_key IS NOT NULL;        -- FR-4.5 dedupe, enforced by the store
```

`feature-010`'s `mention` and `whisper_to` are **not** pre-declared here. They arrive in
`002_*.sql` when that feature ships; declaring unused columns now would be this SPEC guessing
at another feature's shape, which is the failure mode `feature-001` describes.

**Why `member` carries a surrogate key and a `machine` column at P1, when P1 has one machine.**
FR-2.2 makes a session's identity *machine address + name*, and names are unique **per
machine**, not globally. `feature-009` then puts remote members into a locally-hosted chat
(FR-3.3) and must tell `alice` on machine A from `alice` on machine B. A bare
`name TEXT PRIMARY KEY` cannot hold both rows, so federation would have had to rewrite this
table and every foreign key into it — the one thing this SPEC exists to prevent. The columns
are therefore present from the start and simply degenerate at P1, where `machine` is always
this node's own id: **no P1 behaviour depends on them**, and nothing federation-shaped is
built here. This is the same move already made for `chat.name` ("machine qualification is
`feature-009`"), applied to the other identity the store holds.

#### The pid record

`$HOME/.aid/.temp/chat-node.pid`, JSON, written by `aid` at start and removed at stop. Same
directory, same shape and the same reason as `dashboard.pid` (`bin/aid`:1314-1329;
`bin/aid.ps1`:1335-1352):

```json
{
  "schema": 1,
  "pid": 12345,
  "port": 8788,
  "bind": "127.0.0.1",
  "node_version": "2.3.0",
  "started_at": "2026-08-09T12:34:56Z",
  "store": "/home/u/.aid/chat/chat.db",
  "logfile": "/home/u/.aid/.temp/chat-node.log"
}
```

It is **cache, not truth.** A record whose pid is dead is reclaimed silently, exactly as
`_dc_start` does at `bin/aid`:1216-1220. The truth about "is it running" is a live `/healthz`
answer on the recorded port.

#### The config file

`$HOME/.aid/chat/config.yml` — flat `key: value`, one level, no nesting. It is written only by
`aid chat config set`. Flat because that is the shape `read-setting.sh` parses with `awk` and no
`yq` dependency (`coding-standards.md` § Shell (Bash) Conventions), and because every parameter
§6 defines is a scalar. P1 seeds exactly one key, `port: 8788`; every retention and timing
parameter is added by the feature that owns it (D-8).

**A change takes effect without restarting the node**, and that is a requirement rather than a
convenience: `feature-011`'s criterion is "*when it is changed through the CLI, then the new
value takes effect without a code change*", and a criterion that silently required a restart
would be a worse answer than no answer. So `config set` has two paths, and the running one is
the primary:

- **node running** → the CLI issues the `config.set` operation (`plane: "admin"`, so it is
  never reachable over MCP — FR-7.3); the handler writes `config.yml` *and* updates the
  in-process value in one step, so the file and the running node cannot disagree.
- **node not running** → the CLI writes `config.yml` directly; the node reads it at next start.

Two parameters are read once per process and cannot change live, and they are named rather
than left to be discovered: `port` (the socket is already bound) and any future setting the
owning feature declares start-only. `config set port` therefore prints that the new value
applies at the next `aid chat start`.

**Known trap for whoever implements `config`:** `read-setting.sh` has a live defect
(`tech-debt.md` W5-7) where a trailing inline comment on a bare `key:` line is returned *as the
value*. A flat scalar file with no bare list keys does not trigger it, which is a further
reason for the flat shape — but a `config.yml` written with comments on continuation keys
would.

---

### API Contracts

#### 1. The CLI surface — `aid chat`

The verbs this feature owns:

```
aid chat deploy [--from-bundle <path>] [--version <v>] [--port <n>] [--force] [--verbose]
aid chat start  [--port <n>] [--verbose]
aid chat stop   [--verbose]
aid chat status [--verbose]
aid chat config list | get <key> | set <key> <value>
aid chat -h | --help
```

| Verb | Behaviour |
|---|---|
| `deploy` | Probe Python; obtain and install the node into a dedicated venv; start it. **Idempotent** (AC-7) |
| `start` | Spawn the node detached. Refuses when already running |
| `stop` | Terminate it. **Idempotent** — absent or stale record is success |
| `status` | Report deployed/running state, port, versions and paths |
| `config` | Read and change the node's settings (FR-7.2's configuration clause). The *mechanism* is this feature's; every *parameter* belongs to the feature that defines it (D-8) |

Help text follows `_aid_usage dashboard` (`bin/aid`:188-201) line for line in shape: one usage
line per form, then indented flag descriptions, then the invariants a user must know.

**Exit codes.** Reused from the existing scheme, per the standing rule that "a new failure mode
SHOULD reuse an existing code with matching semantics rather than inventing a new one"
(`coding-standards.md` § Exit Codes). **One new code is introduced — `5` — and the rule is a
SHOULD, not a MUST, so introducing it carries the burden of showing no existing code has
matching semantics. That case is made at the foot of this table.** Every other code here is
reused.

| Code | Meaning here | Existing precedent |
|---|---|---|
| 0 | Success. "Already deployed", "already stopped" and "not running (nothing to stop)" are successes | `aid dashboard stop` (`bin/aid`:1383-1385) |
| 1 | Generic runtime failure: venv creation failed, store unwritable, **or the node process failed to start** | install-core scheme |
| 2 | Usage error: no verb, unknown verb, unknown flag, `--port` out of `1024..65535`, `--from-bundle` with `--version` | `bin/aid`:1066-1070, :1109-1116, :4093-4095 |
| 3 | Could not obtain the node: download or version resolution failed and no `--from-bundle` | install-core "network / fetch failure"; `docs/install.md` § Exit codes |
| 4 | Checksum mismatch on a fetched node artifact | install-core; `verify_bundle_checksum` in `lib/aid-install-core.sh`:345-348 |
| **5** | **The node is deployed and its pid is alive, but `/healthz` did not answer within the readiness window — wedged.** The one new code | none — see the case below. `5` is unused across `bin/aid`, `bin/aid.ps1`, `lib/`, `install.sh` and `install.ps1`, and is not assigned by the install-core scheme (which uses 0–4 and 6) |
| 7 | The node is not deployed on this machine | `aid status` exit 7 ("no AID install found"); `aid dashboard` exit 7 ("missing from the install tree", `bin/aid`:1248-1250) |
| 8 | `start` when the node is already running | `aid dashboard start` (`bin/aid`:1213-1215) |
| **9** | **A usable Python was not found — the FR-7.7 / AC-23 code** | `aid dashboard start python` returns 9 for `python3 not found on PATH` (`bin/aid`:1227-1229; `bin/aid.ps1`:1226-1228) |

Three of these deserve their reasoning written down, because a reader will otherwise read them
as inconsistent:

- **"The node failed to start" is 1 here and 3 in `aid dashboard`** (`bin/aid`:1286-1291). This
  is the one deliberate divergence from the dashboard's codes, and it is forced: `aid chat
  deploy` has a real fetch path, so 3 must keep its install-core meaning of "network / fetch
  failure" (`docs/install.md` § Exit codes). The dashboard has no fetch path and was therefore
  free to reuse 3 for a failed spawn; the node is not. One code cannot carry both meanings on
  one verb, and the fetch meaning is the older and more widely documented of the two.
- **`deploy` is idempotent and never surfaces 8; `start` is not idempotent and returns 8.** The
  requirement makes only deploy idempotent (FR-1.1), and `aid dashboard start` already returns
  8 for a second start. `deploy` avoids 8 **structurally**: it never enters the start flow while
  a live pid is recorded, so the already-running guard is unreachable from deploy (Feature Flow
  step 5, all three branches). The guard tests only the pid, never readiness — that is why
  deploy resolves the live-but-unresponsive case itself rather than falling through to it.
- **Exit 5 — deployed and running, but not answering.** A node whose pid is alive while
  `/healthz` stays silent past the readiness window is neither "already running" (8) nor
  "failed to start" (1): it is wedged, and the honest answer names it and tells the operator
  what to do. Reusing 8 here would make AC-7's "no error is raised" false on a path this flow
  enumerates; reusing 1 would tell the operator to retry a deploy that will hit the same state;
  reusing 3 would claim a fetch failed when none was attempted. No existing code has matching
  semantics, which is what the SHOULD in `coding-standards.md` requires before a new one is
  introduced.

  **Why `5` and not `10`.** An earlier draft of this SPEC chose `10` on the stated ground that
  it was unused. **That was false, and the way it was false is the point:** `aid dashboard
  start --remote` already exits `10` (`bin/aid`:1343, with the comment at :1340 — "All expose
  failures (10/11/12) map to user-facing exit 10" — and the twin at `bin/aid.ps1`:1372). The
  check that produced the false claim read the *documented* scheme (`docs/install.md`:735-744
  stops at 7; `coding-standards.md`:214-221 stops at 6), and neither document reaches a code
  the shipped script actually uses. **A code is free only if the scripts do not use it — the
  docs are not the authority here, and any later feature adding a code must grep both twins,
  not the tables.** `5` was verified that way: `grep -rnoE "exit 5\b" bin/ lib/ install.sh
  install.ps1` returns nothing, and `bin/aid` uses 0, 1, 2, 3, 6, 7, 8, 9, 10 while
  `bin/aid.ps1` uses 0, 2, 6, 10.
- **`status` exits 0 when the node is deployed but stopped**, with `running: no` on stdout.
  Encoding the answer in the exit status would need 7 or 8, and neither's existing semantics
  match "the question was answered and the answer is no". The stable machine contract is the
  `running:` line, not the exit code. Exit 7 is reserved for the genuinely different case:
  nothing is deployed, so there is nothing to report.

**Output shape.** stdout carries the result, stderr carries diagnostics
(`coding-standards.md` § Logging and Output). `--verbose` adds launcher detail on stderr,
matching `aid dashboard --verbose`.

```
$ aid chat status
deployed: yes
running: yes
responding: yes
url: http://127.0.0.1:8788
pid: 12345
node_version: 2.3.0
schema_version: 1
protocol_version: 1.0.0
started_at: 2026-08-09T12:34:56Z
store: /home/u/.aid/chat/chat.db
log: /home/u/.aid/.temp/chat-node.log

$ aid chat start
Chat node running at http://127.0.0.1:8788 -- stop with: aid chat stop

$ aid chat stop
aid: chat: node stopped.

$ aid chat stop            # again
aid: chat: not running (nothing to stop).
```

No `--json` flag at P1. Nothing consumes one, and machine-readable operator output is
`feature-012`'s subject.

**Reserved verb namespace.** Named here so that the five later features that add a verb extend
one surface rather than negotiating it, and so `aid chat <unknown>` can fail with a complete
expected-verb list. **This SPEC does not specify their arguments or semantics** — the owning
feature does. (`feature-010` and `feature-011` add no verb: they add flags to `send` and keys to
`config` respectively.)

| Verbs | Owner | Stage |
|---|---|---|
| `deploy`, `start`, `stop`, `status`, `config` | `feature-003` (this) | P1 |
| `register`, `sessions` | `feature-004` | P1 |
| `create`, `delete`, `join`, `leave`, `add-member`, `remove-member`, `chats`, `send`, `inbox`, `ack` | `feature-005` | P1 |
| `subscribe` | `feature-006` | P2 |
| `machines` | `feature-009` | P3 |
| `audit` | `feature-012` | P4 |

`config` is claimed here because FR-7.2's configuration clause is this feature's; the
*parameters* it sets belong to `feature-004`, `feature-006` and `feature-011` (D-8).

**How a verb reaches the core.** `aid chat` is a **thin argv translator**, not a client:

```
aid chat send --chat build --body "..."
  └─ bin/aid: _cmd_chat_ctl  ->  exec "<venv-python>" -m aid_chat_node send --chat build --body "..."
                                    └─ transport/client.py  ->  POST http://127.0.0.1:<port>/op
                                                                   └─ transport/server.py -> OPERATIONS["chat.send"].handler
```

The shell twins carry argument validation and process lifecycle and nothing else. Three reasons:

1. **One implementation (FR-0.1).** An HTTP+JSON client written twice in shell — once in Bash,
   once in PowerShell — is two implementations of the message plane by any honest reading, and
   they would drift. `coding-standards.md` already names hand-kept twins as a risk
   (§ Observed Inconsistencies, "Twin drift risk").
2. **No new dependency for `aid`.** The alternative is `curl` (or `Invoke-WebRequest`) plus
   JSON parsing in shell. `bin/aid` currently hand-parses JSON with `grep`/`sed`
   (`bin/aid`:1210-1212) — adequate for a flat pid record of a dozen-odd scalar fields
   (`dashboard.pid` has nine, `bin/aid`:1318-1328; this node's has eight), unusable for message bodies
   that §6 explicitly does not size-limit and that may contain newlines and quotes.
3. **It is already how the CLI treats a runtime component.** `aid dashboard start` resolves an
   interpreter and execs an entry point in the install tree (`bin/aid`:1225-1274); it does not
   reimplement the server.

`python -m aid_chat_node` is **not** an operator-facing command and **not** a client library —
see [Packaging & Distribution](#packaging--distribution) for the three inspectable properties
that make that true rather than merely claimed.

#### 2. The node's internal HTTP transport

**Not a public surface.** FR-5 (§5 preamble) states it: "HTTP is the node's internal transport
between them, not a third public surface". It is documented here because two sibling features
extend it, not because anything outside the product may call it.

| Property | Value |
|---|---|
| Server | `http.server.ThreadingHTTPServer` (stdlib). Threading is not optional: `feature-006` holds connections open while other requests proceed. `feature-001` made the same call for the spike stub, for the same reason |
| Bind | **literal `127.0.0.1`**, never read from request, config or environment |
| Port | From the pid record / `--port`; default **8788** — adjacent to the dashboard's `8787` (`bin/aid`:1075) and deliberately distinct from it, since both services can run at once |
| Protocol | HTTP/1.1, `application/json; charset=utf-8`, UTF-8 bodies |
| Endpoints | `POST /op`, `GET /healthz`. Any other path → 404. Wrong method on a known path → 405 |

```
POST /op
  {"op": "<registry name>", "params": { ... }}

200  {"ok": true,  "result": { ... }}
200  {"ok": false, "error": {"code": "<enum>", "message": "<actionable text>"}}
400  malformed JSON, missing "op", or an op not in the registry
404  unknown path
405  non-POST on /op, non-GET on /healthz
500  unhandled exception (logged with traceback; the response carries no traceback)
```

**Transport failures are HTTP status; domain failures are `ok: false` with a stable `code`.**
The split matters because the CLI maps `code` onto its exit status deterministically, and a
domain error such as "chat not found" is not a transport problem. P1 defines the codes the
node itself needs; each later feature adds its own to `core/errors.py`:

| `code` | Meaning | Added by |
|---|---|---|
| `bad_request` | A parameter failed the registry's `ParamSpec` | this feature |
| `not_found` | The named entity does not exist on this machine | this feature (semantics extended by FR-3.2 at P3) |
| `conflict` | The operation would violate a store invariant | this feature |
| `internal` | Unexpected; the log holds the traceback | this feature |

```
GET /healthz
200 {"ok": true, "node_version": "2.3.0", "schema_version": 1,
     "protocol_version": "1.0.0", "pid": 12345, "started_at": "..."}
```

`/healthz` is separate from `/op` deliberately: `aid chat status` must be able to answer without
knowing the operation vocabulary, and the readiness probe at start must not need a valid op.

**Reserved and not built here.** `GET /subscribe` is reserved for `feature-006` — a long-lived
response does not fit the single-JSON `/op` envelope, so the transport is deliberately
extensible with a second endpoint *kind*, not with a second dispatch table.
`protocol_version` is reserved for `feature-009`'s semantic-version handshake (FR-6.4); it is
emitted from P1 so that a P3 node meeting a P1 node has something to compare.

#### 3. What is not in this feature's contract

No authentication, anywhere — no token, no key, no login, on the CLI or the transport (§4:
"There is no key, password, or login anywhere in this product"). Nothing below invents one.

---

### Feature Flow

#### `aid chat deploy`

```
aid chat deploy [--from-bundle <path>] [--version <v>] [--port <n>] [--force]
 │
 ├─ 1. parse args ................. unknown flag / bad --port / bundle+version -> stderr, exit 2
 │
 ├─ 2. PYTHON PROBE (FR-7.7, AC-23) ........ before ANY side effect
 │      candidates, in order:  $AID_CHAT_PYTHON | python3 | python | (Windows) py -3
 │      for each: <cand> -c "import sys;print('%d.%d'%sys.version_info[:2])"     <- ONE LINE
 │      accept the first whose version >= the node's declared floor (3.12)
 │      none found          -> the "no Python" message,       exit 9
 │      found but too old   -> the "Python too old" message,  exit 9
 │
 ├─ 3. resolve the target version V  (--version, else the default-version rule --
 │      AWAITING THE STAKEHOLDER, see Packaging & Distribution sub-question 1;
 │      the flow is identical either way, only the default differs)
 │
 ├─ 4. INSTALL SHORT-CIRCUIT (AC-7)
 │      venv exists  AND  <venv-python> -m aid_chat_node --print-version == V  AND  not --force
 │        -> skip: no download, no pip, no file written under $HOME/.aid/chat/
 │      else
 │        -> create/refresh $HOME/.aid/chat/venv   (<probed-python> -m venv, stdlib)
 │             venv unavailable -> the venv-unavailable message, exit 1
 │                                 (names `python3-venv` on Debian/Ubuntu, where the
 │                                  distribution splits `ensurepip` out of the interpreter)
 │           obtain + install the node   (see Packaging & Distribution)
 │             fetch failed    -> exit 3
 │             checksum failed -> exit 4
 │
 ├─ 5. RUN SHORT-CIRCUIT (AC-7) -- three states, not two
 │      a) pid record present AND pid alive AND GET /healthz answers
 │           -> skip: no process spawned, pid unchanged; exit 0
 │      b) pid record present AND pid alive AND /healthz silent
 │           -> re-probe every 250 ms up to 5 s (a node that is still starting
 │              answers inside that window; the store opens before the listener)
 │              answers  -> as (a)
 │              still silent -> exit 5, "node is running (pid N) but not answering
 │                              on <url>; run `aid chat stop` then deploy again"
 │           -> deploy NEVER reaches the start flow in this state, so it never
 │              surfaces 8, and it never spawns a second node beside a wedged one
 │      c) no pid record, or pid dead (stale record reclaimed)
 │           -> the `start` flow below   (child exits early -> exit 1)
 │
 └─ 6. print what it did; exit 0
```

The second run of `deploy` therefore takes step 4's and step 5's short-circuits and prints:

```
aid: chat: node already deployed (v2.3.0) and running at http://127.0.0.1:8788
```

**"Nothing changes" is defined byte-level over a named set**, so AC-7 is testable rather than
judged. After the second `deploy`: the **venv tree** and **`config.yml`** have unchanged
mtimes, **`chat.db` itself** has an unchanged mtime, the pid in the record is the same integer,
and `started_at` is unchanged.

The set is named rather than written as "everything under `$HOME/.aid/chat/`" because that
directory is **not deploy's alone**. The store runs in WAL mode, so `chat.db-wal` and
`chat.db-shm` sit beside it and are touched by the *running node* on ordinary traffic — and by
read transactions, which includes the `/healthz` probe deploy itself issues in step 5. A
directory-wide mtime assertion would therefore report a change deploy did not cause, on a path
deploy is required to take: an oracle that fails for doing its job is worse than no oracle.
That is the shape in [Verification](#verification) (`CN-DEPLOY-2`).

**The venv exists from P1 even though P1 has no dependency**, and that is deliberate rather
than premature. At P2 `mcp` arrives and at P3 `zeroconf`; if deploy learned about isolation
then, deploy would change shape mid-work and `feature-008` would inherit a migration nobody
scoped. An isolated interpreter also means the node's future dependencies can never collide
with whatever the user's system Python already carries — which is the whole point of the node
being a separate distributable.

#### `aid chat start`

Structurally `_dc_start` (`bin/aid`:1185-1375) with the dashboard-specific steps removed. The
divergences are listed rather than left to be spotted:

| Step | Dashboard | Node | Why it differs |
|---|---|---|---|
| Runtime choice | positional `node`\|`python` | none | The node is Python only. FR-7.7 rejects a second implementation, with the dashboard's own twin cost as the evidence (~8,255 lines of Node against ~10,098 of Python — `server.mjs` 2,729 + `reader.mjs` 5,526; `server.py` 3,011 + `dashboard/reader/*.py` 7,087) |
| Interpreter | `command -v python3` only | the ordered probe of step 2 above | `python3` alone is wrong on Windows, where the launcher is `py` and the executable is often `python` |
| Entry point | `$AID_CODE_HOME/dashboard/server/server.{py,mjs}` | `$HOME/.aid/chat/venv/{bin,Scripts}/python -m aid_chat_node serve` | The node is not in the CLI's install tree — that is FR-7.6 |
| Readiness | TCP connect, 50 x 0.1s | TCP connect **then** `GET /healthz`, same budget | A bound socket is not a migrated store; `/healthz` answers only after `001_p1.sql` has been applied |
| Log capture | launcher redirects (POSIX only) | **the node opens its own log** | Closes a gap the dashboard documents at `bin/aid.ps1`:1265-1274 — `Start-Process` *with* redirection hangs a capturing caller, so Windows gets no log at all. Passing `--log <path>` and letting the child open it works identically on all three platforms |
| `--remote` | present (tailscale) | **absent** | Out of scope. §4 puts NAT traversal and any relay tier out of scope for v1; cross-machine reach is `feature-009` over mDNS on a trusted LAN, not a tunnel |

Everything else is carried over unchanged and on purpose: the already-running guard returning
8, the stale-record reclaim, the bounded readiness wait, and the JSON record written last.

**Detachment — the part that makes the node outlive the session that started it.**

| Platform | Mechanism | Source |
|---|---|---|
| Linux / macOS | `setsid "$py" -m aid_chat_node serve --log "$log" … >/dev/null 2>&1 &` — the child is a new session leader, so it survives the parent shell and can later be reaped as a process group | `bin/aid`:1274 |
| Windows | `Start-Process -PassThru -WindowStyle Hidden` **without** `-RedirectStandard*` — ShellExecute does not inherit the caller's handles, which both fully detaches the child and avoids hanging a caller that captures output | `bin/aid.ps1`:1263-1284 |

The POSIX redirect goes to `/dev/null`, **not** to the log file, and that is the one byte of
difference from `bin/aid`:1274: the node opens its own log from `--log`, so a second writer on
the same path would interleave. Everything else about the row is the dashboard's.

The Windows row is the single most valuable thing reused here. It is a trap this repository
already fell into and documented in place, and re-deriving it would have cost the same CI hang.

**Machine-restart survival is not specified, not built and not tested.** No requirement asks
for it and this feature's Description says so explicitly. Concretely: no `systemd` unit, no
`launchd` plist, no Windows Task Scheduler registration, no login item. A later feature that
wants it is adding scope, not filling a gap.

#### `aid chat stop`

`_dc_stop` (`bin/aid`:1377-1456) with the `--remote` teardown removed:

```
read $HOME/.aid/.temp/chat-node.pid
 ├─ absent            -> "not running (nothing to stop)."      exit 0
 ├─ pid dead          -> reap by port (Windows), drop record,  exit 0
 └─ pid alive
      POSIX:   kill -TERM -<pid>  ; wait <= 5s ; kill -KILL -<pid>
      Windows: taskkill /F /T /PID <pid>
      then:    reap anything still LISTENING on 127.0.0.1:<recorded port>   (Windows only)
      remove record + log ; "aid: chat: node stopped."          exit 0
```

The Windows port reap is not defensive padding. `bin/aid`:1136-1148 records what happens
without it: the recorded pid is the `cmd`/`.bat` **wrapper**, not the native interpreter, an
MSYS process-group kill cannot reach the real child, and the leaked server keeps serving stale
in-memory code. For the dashboard the symptom was "pipelines appear empty". For the node it
would be worse — a stale process holding the SQLite file open and answering `/healthz` while
`aid chat status` reports the node stopped.

**The clean-shutdown handler is a POSIX nicety, and correctness must not depend on it running.**
On POSIX the node handles `SIGTERM` by stopping accepting, finishing in-flight requests,
committing, closing the store and exiting 0; `SIGKILL` after 5 s is the backstop. **On Windows
there is no graceful step at all** — `taskkill /F /T` is a hard terminate, exactly as
`bin/aid`:1427 and `bin/aid.ps1`:1462 (stop) / :1175 (port reap) already do for the dashboard, and the node
never sees a signal. So the durability guarantee cannot come from the handler; it comes from
the store. This is the reason `synchronous=FULL` was chosen rather than `NORMAL`: a hard kill
at any instant leaves the last committed transaction on disk and the uncommitted one absent,
never a torn one. AC-9 holds on all three platforms because of the PRAGMA, not because of the
signal.

---

### State Machines

The node has one lifecycle, and `aid` observes it entirely through two things: the pid record
and a `/healthz` answer.

```
                        aid chat deploy (step 4)
    NOT DEPLOYED ───────────────────────────────► DEPLOYED (stopped)
         ▲                                            │        ▲
         │  operator deletes ~/.aid/chat              │        │  aid chat stop
         │                                            │        │
         │        aid chat start  /  deploy (step 5)  │        │
         │                                            ▼        │
         │                                        STARTING ────┤  readiness wait, <= 5 s
         │                                            │        │
         │                        /healthz answers    │        │  child exits early -> exit 1
         │                                            ▼        │
         └──────────────────────────────────────── RUNNING ────┘
                                                      │
                                                      │  process dies without `stop`
                                                      ▼
                                               STALE RECORD
                                          (record present, pid dead)
                                                      │
                    next start/stop/status reclaims it silently -> DEPLOYED (stopped)
```

| State | How `aid` recognises it | `status` output | `status` exit |
|---|---|---|---|
| NOT DEPLOYED | no `$HOME/.aid/chat/venv` | `deployed: no` | 7 |
| DEPLOYED (stopped) | venv present; no pid record, or record with a dead pid | `deployed: yes` / `running: no` | 0 |
| STARTING | internal to `start` only; never observed by another command | — | — |
| RUNNING | record present, pid alive, `/healthz` answers on the recorded port | `deployed: yes` / `running: yes` / `responding: yes` + detail | 0 |
| WEDGED | record present, pid alive, `/healthz` silent past the readiness window | `deployed: yes` / `running: yes` / `responding: no`, plus url, pid, `started_at`, store and log — **but not `node_version`, `schema_version` or `protocol_version`, which are only obtainable from `/healthz`** | 0 |
| STALE RECORD | record present, pid dead | reported as DEPLOYED (stopped) after reclaim | 0 |

**WEDGED is an observation, not a lifecycle state.** It has no transitions of its own and
nothing drives the node into it deliberately: it is the name for "the pid is alive and the
listener is not answering", which is a thing that can be *seen* at any moment while the node is
nominally RUNNING. It is in this table because `aid chat status` must have a defined answer for
every state a user can be in, and because the deploy flow now names this one (exit 5). The only
exit from it is `aid chat stop` followed by a fresh `start` or `deploy`.

**`status` exits 0 for WEDGED, and this is deliberate.** The rule stated with the exit codes
above holds: an exit code answers "could the question be answered", not "is the news good". The
question was answered — the machine-readable answer is `responding: no`. `deploy` exits 5
because deploy was asked to *make the node usable* and could not; `status` was asked only to
report, and it did.

**There is no PAUSED, DRAINING or DEGRADED state, and no reconnect state machine.** Adding one
would be inventing lifecycle nobody asked for. WEDGED is not a counter-example: it is a probe
result with no transitions, no timers and no recovery behaviour of its own — precisely the
things a DEGRADED *state* would have brought with it. The node is up or it is not; a subscriber
that loses its connection reconnects and reads from its position, which is `feature-006`'s
problem and is exactly why the durable log exists.

**The pid record is a cache and the process table is the truth.** Every transition above is
decided by probing the live process, never by trusting the file — the reclaim path exists
because a file that outlives its process is the normal case after a crash, not an error.

---

### External Integrations

AID "is a distributed toolkit, not a networked service" (`integration-map.md`), and this
feature does not change that. Its integration surface is four items:

| Integration | Direction | Criticality | Notes |
|---|---|---|---|
| A Python 3.12+ interpreter on the host | outbound (invokes) | **Critical** | The node's stated prerequisite (FR-7.7). Absent → exit 9, never a stack trace. `aid` itself gains no Python requirement |
| `venv` + `pip` (from that interpreter) | outbound (invokes) | High | Both stdlib-adjacent; `pip` reaches the venv through `ensurepip` |
| The source `deploy` obtains the node from | inbound (fetches) | High | **Deferred — see below.** Whatever it is, it is verified by SHA-256 before use, per the mandatory download-integrity rule (`coding-standards.md` § Security Conventions) |
| Loopback TCP on `127.0.0.1:<port>` | inbound (serves) | Low | The node's own transport. Second loopback service in the product, after the dashboard |

**Not integrations of this feature**, stated so their absence is deliberate: mDNS/`zeroconf`
and any node-to-node link (`feature-009`, P3); MCP and any host-tool configuration
(`feature-008`, P2 — and FR-0.4's standing rule that AID writes and manages no host tool's MCP
configuration binds this feature too: `aid chat deploy` touches no `.mcp.json`, no
`settings.json`, no host config file, ever); the hosting server, held in reserve and
deliberately unused in v1 (§1); any telemetry endpoint (there is none — see
[Telemetry](#telemetry)).

#### Security posture

There is **no `### Security Specs` section** in this SPEC, and its absence is a statement
rather than an omission: §4 removed all authentication from the product, so there is no
authentication, authorization, credential, session or token design to specify. Writing one
would describe a security model this product does not have. What *does* exist:

- **The listener is loopback-only at P1.** Literal `127.0.0.1`, never a wildcard, never read
  from request, config or environment — the same SEC-1 posture the dashboard server states in
  its own header (`dashboard/server/server.py`:4). Federation needs a LAN-reachable listener;
  **this SPEC does not authorise a wildcard bind**, and `feature-009` must specify that
  exposure with §8's "the network *is* the security boundary" trade stated in its own terms.
- **No secret is stored, read or logged.** The node has no credential, so
  `.aid/connectors/.secrets/` and the `secret_reference` machinery are not in its path at all.
- **This is a boundary, not a sandbox**, and FR-7.3's honesty rule extends here: loopback
  restricts *who on the network* can reach the node, and restricts nothing about what a local
  session may do, since any session with shell access can run `aid chat` directly. Said plainly
  so nobody reads loopback as containment.
- **A traceback never reaches the user's terminal.** It goes to the node's log; the user gets a
  coded, actionable message. AC-23 asks for that on one path; making it the general rule costs
  nothing and stops the next path from regressing.

---

### Packaging & Distribution

#### The node's own manifest

`chat-node/pyproject.toml`:

```toml
[project]
name            = "aid-chat-node"
requires-python = ">=3.12"      # the node's OWN floor -- independent of packages/pypi (FR-8 preamble)
dependencies    = []            # P1: stdlib only. feature-008 adds mcp; feature-009 adds zeroconf.
# No [project.scripts]. No [project.entry-points."console_scripts"]. Deliberate -- see below.
```

`requires-python = ">=3.12"` here and `>=3.8` (moving to `>=3.12`) in
`packages/pypi/pyproject.toml`:10 are **two unrelated declarations**. The node declares its own,
so `feature-002` gates nothing here and nothing here gates `feature-002` — which is what the
FR-8 preamble and §10's P0b note assert, now true by construction rather than by agreement.

#### Three inspectable properties, and the criteria they satisfy

| Property | The check | Criterion it makes passable |
|---|---|---|
| The distribution declares **no console-script entry point** | `chat-node/pyproject.toml` contains no `[project.scripts]` and no `console_scripts` group; installing it puts **nothing on PATH** | "ships no operator-facing command of its own" (FR-7.5) |
| The distribution exports **no public API** | `aid_chat_node/__init__.py` sets `__all__ = []`; no `py.typed` marker (a typed-library marker is an invitation to bind); `chat-node/README.md` states in its first paragraph that the package is an implementation detail of `aid chat` and is not supported as an import target | "offers no client library or SDK for a caller to bind to" — the FR-7.4 in-tool-skills clause |
| Every human-facing operation is an `aid` subcommand | The only documented invocation anywhere is `aid chat <verb>`; `python -m aid_chat_node` appears in no user-facing document | FR-7.5 |

`python -m aid_chat_node` is reachable, and that is unavoidable for any importable Python
package — the honest claim is not "nothing can invoke it" but "**nothing is published for
anything to invoke**": no PATH entry, no exported API, no documentation, no stability promise.
A skill written later has nothing to bind to and therefore invokes `aid chat`, which is exactly
what FR-7.4's first clause asks for.

#### Where it is installed on the user's machine

```
$HOME/.aid/chat/
├── venv/                 # created by `<probed-python> -m venv`; holds the node and (from P2) its deps
│   └── bin/python3       #   ...or venv/Scripts/python.exe on Windows -- the launcher resolves both
├── chat.db               # the store (D-2)
└── config.yml            # the config (D-8)
$HOME/.aid/.temp/
├── chat-node.pid         # the pid record
└── chat-node.log         # the node's own log
```

**Uninstall / rollback** needs no new machinery and is worth stating because a failed deploy
must be recoverable: `aid chat stop` then delete `$HOME/.aid/chat/`. The `aid` CLI is
untouched by either — removing chat cannot break `aid`, because `aid` never depended on it.
`aid chat deploy --force` re-creates the venv from scratch, which is the recovery for a
half-installed one.

#### The deferred question: where `deploy` obtains the node

> **AWAITING THE STAKEHOLDER. This is not settled, and nothing below should be read as
> settled.** REQUIREMENTS §8 records it as a deliberate deferral to this phase, and this
> feature's own Source and Description carry it here. No criterion in this feature or in any
> sibling depends on the answer.

**Why it is a real question.** `aid` reaches users through four channels — `curl`/`irm`
bootstrap, **offline air-gapped bundle**, npm and PyPI (`technology-stack.md` § Package
Managers & Distribution; `docs/install.md`:854). `aid` does not carry the node (FR-7.6), so
deploy must obtain it, and the bundle channel serves machines with **no index to reach**
(`docs/install.md` § Offline / air-gapped install).

**The timing, which is the most useful thing to tell the stakeholder.** At P1 the node has
**zero dependencies**, so every option below is cheap and the offline case is one file. The
question only becomes expensive at **P2**, when `mcp` arrives: from that point an offline
bundle must carry third-party wheels, which are platform- and Python-version-specific once any
of them ships compiled code. **The decision is due before `feature-008` starts, not before this
feature ships.**

| Option | How deploy obtains it | For | Against |
|---|---|---|---|
| **A. Public index (PyPI)** | `<venv>/pip install aid-chat-node==<V>` | Smallest machinery; version pinning, upgrade and CVE response come free; `pip` handles TLS and index integrity; AID already publishes to PyPI through an OIDC Trusted Publisher (`release.yml`) | **Fails on the air-gapped channel outright.** Adds a fifth version carrier: the release gate `check-version-sync.sh` asserts every *present* carrier equals the expected version, so a new package either joins that check or silently stops being covered |
| **B. GitHub Release asset + `--from-bundle`** | `release.sh` publishes `aid-chat-node-v<V>.tar.gz` (node wheel + any dependency wheels) alongside the five profile tarballs and the CLI bundle; deploy downloads from the pinned tag, verifies against `SHA256SUMS`, then `pip install --no-index --find-links <extracted>` | Reuses AID's existing trust root verbatim — "the GitHub Release is the trust root" (`infrastructure.md` § Install Bootstrap), `verify_bundle_checksum` already exists, and `--from-bundle` already means exactly this to users. Air-gapped works by construction: the operator copies one file, as they already copy `aid-claude-code-v<V>.tar.gz`. No new registry, account or publisher | From P2 a dependency wheelhouse is platform- and interpreter-specific: either per-platform bundles, or a source build (needs a compiler), or a pure-Python-wheels-only constraint on what the node may depend on. Release artifact count and size grow |
| **C. Vendor into the `aid` payload** | Ship the node inside the CLI bundle | Offline works with no extra step | **Excluded by requirement.** FR-7.6: "`aid` installs and administers it; `aid` does not vendor it". It would also put the node's file set into all five install manifests, which is the exact thing the FR exists to prevent |
| **D. Single-file zipapp (`.pyz`)** | Build a `shiv`/`zipapp` with dependencies frozen in; deploy copies one file and runs it with any Python at or above the floor | No pip, no venv, no index at deploy time; the offline story is a file copy | Building needs a third-party builder in the **release** toolchain (not shipped, so D10 is untouched — but it is new maintainer machinery). A `zipapp` cannot load a C extension from inside the archive without extraction, so compiled dependencies re-introduce B's platform problem *and* hide the dependency set from `pip`, making a CVE response harder |

**Recommendation — A and B together, i.e. index by default and bundle by flag.** It is the
only option that serves all four install channels, and it is not a new mechanism: it is exactly
the two-mode shape `aid add` already has (`aid add <tool>` fetches; `aid add <tool>
--from-bundle <path>` does not, `docs/install.md`:386-396), reusing `SHA256SUMS`,
`verify_bundle_checksum`, and the `--from-bundle` flag users already know.

```
aid chat deploy                          -> pip install aid-chat-node==<V>            (default)
aid chat deploy --from-bundle <path>     -> pip install --no-index --find-links <path> aid-chat-node
```

**Two sub-questions the stakeholder must answer with it**, because leaving them implicit is how
this becomes three decisions instead of one:

1. **Does the node's version track `VERSION`?** Recommended **yes** — one release, one number,
   matching the four-carrier rule (`infrastructure.md` § Versioning). If yes,
   `canonical/aid/scripts/release/check-version-sync.sh` must gain the carrier, or the gate
   silently stops covering it.
2. **May the node depend on a package that ships compiled wheels?** A "pure-Python wheels only"
   rule keeps option B to a single platform-independent bundle forever. It is a real constraint
   on `feature-009`'s mDNS choice and should be decided with eyes open rather than discovered
   when the first wheelhouse turns out to be Linux-only.

---

### Telemetry

**Nothing leaves the machine. Ever.** No phone-home, no counters, no analytics, no crash
reporting. AID has no monitoring, APM or alerting of any kind (`infrastructure.md` § Hosting /
Containers / Data — None) and this feature adds none.

What exists is one local log, written by the node itself:

| Property | Value |
|---|---|
| Path | `$HOME/.aid/.temp/chat-node.log`, passed as `--log <path>` on the spawn argv |
| Writer | **the node process**, not the launcher — see the divergence table in [Feature Flow](#feature-flow); this is what gives Windows a log at all |
| Format | One line: `<ISO-8601 UTC> <LEVEL> <event> key=value ...`. Levels `INFO` / `WARN` / `ERROR`. No logging library — `coding-standards.md` § Logging and Output records that AID uses none |
| Rotation | Roll to `chat-node.log.1` at 8 MiB, keep exactly one. An unbounded log on a service with no restart policy is the failure mode; one rollover keeps the crash that produced it |
| P1 events | `start`, `ready` (after migration), `stop`, `signal`, `migration_applied`, one line per `/op` with op name, outcome and duration, and `ERROR` with a full traceback |
| **Never logged** | **Message bodies.** The log records op name, chat, sender and `seq` only. Bodies live in the store, which is where the audit log of FR-7.1 reads them (`feature-012`) — a debug artifact is the wrong place for a user's message content |

The **audit log is not this**. FR-7.1's "message audit log" is a read over the store, owned by
`feature-012` at P4. Conflating the two would put message content into a rotating debug file.

`aid chat status` reports the log path (see its output shape) so a user chasing a failure is
told where to look rather than having to know.

---

### Verification

New suites follow the repository's existing triple for a CLI surface — `test-aid-cli.sh` /
`test-aid-cli-ps1.sh` / `test-aid-cli-parity.sh` — and are discovered by
`tests/run-all.sh`'s glob (`tests/canonical/test-*.sh`), so nothing needs wiring. Each carries a
`# COVERS:` header (`tech-debt.md` W5-1) and emits one `PASS:`/`FAIL:` line per assertion, which
is what `tests/coverage-parity.sh` harvests.

| Suite | Covers |
|---|---|
| `tests/canonical/test-aid-chat-cli.sh` | The Bash CLI surface end to end: verbs, flags, exit codes, output shape, lifecycle |
| `tests/canonical/test-aid-chat-cli-ps1.sh` | The PowerShell twin of the same |
| `tests/canonical/test-aid-chat-parity.sh` | Bash/PowerShell equality of output and exit code for every verb and every failure path |
| `tests/canonical/test-chat-node-separation.sh` | FR-7.6, FR-7.5, FR-7.4 and FR-0.1 as static checks over the tree (below) |
| `tests/canonical/test-chat-node-core.sh` | Shell driver over the node's own Python tests |

**On the node's Python tests:** they use **stdlib `unittest`**, driven by a shell suite, not
`pytest`. This is not a preference — it is what reaches CI. `test-dashboard-reader.sh` drives
`dashboard/reader/tests/` (24 unittest modules, zero pytest imports) through `unittest`
discovery and emits per-test `PASS:`/`FAIL:` lines precisely because a suite that prints only a
verdict "contributed ZERO coverage-parity keys… a whole guard module could be DELETED and both
run-all.sh and the coverage oracle would stay green" (`test-dashboard-reader.sh`:1-23). The node's
driver copies that shape, including the two collection self-guards.

Suites that bind a port must take it from `find_free_port` (`tests/lib/net.sh`:24-34) rather
than hard-coding 8788, and must not run concurrently against a shared port. Note for whoever
runs them locally: `test-landscape.md` § Performance & Health and `tech-debt.md` W4-3 both
record that port-binding and pwsh suites are the ones that fail or hang on a Windows dev shell
for environmental reasons; `test-aid-dashboard-cli.sh` is the closest existing suite and is the
one to copy.

**Every acceptance criterion in this feature, mapped to an oracle.** All **ten** of this
feature's criteria appear below, each exactly once. **Six** further rows — `CN-PY-9b`,
`CN-DEPLOY-3`, `CN-STATUS-WEDGED`, `CN-STATUS-7`, `CN-CONFIG`, `CN-RESTART` — exceed them,
making **sixteen** rows in all. Four of the six are here because a sibling's criterion depends
on behaviour this feature owns and would otherwise reach P4 unverified; `CN-DEPLOY-3` and
`CN-STATUS-WEDGED` are here because the WEDGED observation (State Machines) is reachable and
must not be left to an implementer's judgement.

| # | Criterion (abridged) | Oracle |
|---|---|---|
| CN-DEPLOY-1 | Clean machine → deploy → installed and running | `deploy` into a sandboxed `$HOME`; assert `$HOME/.aid/chat/venv` exists, `/healthz` returns 200, exit 0 |
| CN-PY-9 | Non-PyPI channel, no Python → explicit prerequisite error, not a stack trace; unrelated `aid` commands still work | Run `deploy` with `PATH` scrubbed of every interpreter and `AID_CHAT_PYTHON` unset. Assert **exit 9**; stderr contains `Python`; stderr contains **no** `Traceback`; then `aid version` exits 0 and `aid status` exits its normal code in the same environment. **AC-23** |
| CN-PY-9b | Python present but below 3.12 | Same, with a 3.11 on PATH; assert exit 9 and that the message names the version found |
| CN-DEPLOY-2 | Second deploy → nothing changes, no error | Snapshot mtimes of **the venv tree, `config.yml` and `chat.db`** (not `chat.db-wal`/`-shm`, which the running node writes independently of deploy) plus the pid record; `deploy` again; assert exit 0, identical mtimes, identical pid and `started_at`. **AC-7** |
| CN-DEPLOY-3 | Deployed, pid alive, node wedged | Start the node, make `/healthz` unresponsive without killing the process, `deploy`; assert **exit 5** with the pid and URL in the message, that no second process was spawned, and that **8 is never returned** |
| CN-STATUS | Running node → state reported | `status` exits 0 and stdout carries `running: yes`, `responding: yes`, the url, the pid and both version fields |
| CN-STATUS-WEDGED | Wedged node → state reported, not misreported | Start the node, make `/healthz` unresponsive without killing the process, `status`; assert exit **0**, `running: yes` **and** `responding: no` on stdout, the pid and url present, and that `node_version` / `schema_version` / `protocol_version` are **absent** rather than stale or guessed |
| CN-STATUS-7 | Nothing deployed → exit 7, `deployed: no` | Fresh sandbox `$HOME` |
| CN-STOP | Running node → stops | `stop` exits 0; `/healthz` no longer answers; record removed. Second `stop` exits 0 with the not-running message |
| CN-ORPHAN | Session that started it exits → node keeps running | Start the node from a subshell (Bash) / child `Start-Process` (PowerShell); terminate the parent; assert `/healthz` still answers and the pid is unchanged |
| CN-SEP | `aid`'s manifests still empty | Assert `packages/npm/package.json` `dependencies` is `{}` and `packages/pypi/pyproject.toml` `dependencies` is `[]`; and that no `chat-node/` path appears in `dashboard/MANIFEST`, npm `files`, PyPI `artifacts`, or `release.sh`'s bundle copy list |
| CN-NOCMD | No operator-facing command of its own | Assert `chat-node/pyproject.toml` declares no `[project.scripts]` and no `console_scripts` group |
| CN-NOLIB | No client library or SDK | Assert `aid_chat_node/__init__.py` sets `__all__ = []`, no `py.typed` exists under `chat-node/`, and `chat-node/README.md` carries the implementation-detail statement |
| CN-LAYER | Message-plane logic lives in one core the CLI calls rather than reimplements | Static import scan: no module under `aid_chat_node/core/` imports `http`, `socket`, `argparse`, `aid_chat_node.transport` or `aid_chat_node.service`; and `transport/server.py` contains no operation name as a literal — its dispatch is built from `OPERATIONS` |
| CN-CONFIG | A setting changed through the CLI takes effect without a code change **and without a restart** | With the node running, `aid chat config set <live-key> <v>`; assert `config.yml` holds `<v>` **and** the running node reports `<v>` without being restarted. Serves `feature-011`'s configurability criterion from this feature's side |
| CN-RESTART | (Serves `feature-005`'s AC-9 from this feature's side) | Write rows, stop the node **by hard kill** (not a graceful stop — the Windows path has no graceful step), restart, assert the store opens, `schema_version` is unchanged, and the rows are present |

**One deliberate non-oracle.** Machine-restart survival has no test, because it has no
requirement. A suite that rebooted a machine would be verifying scope this feature does not
have.

---

### What this SPEC deliberately does not settle

A closed list, so an implementer knows where the edges are:

| Left open | Owner | Note |
|---|---|---|
| Where `deploy` obtains the node | **the stakeholder** | Options and a recommendation above; due before `feature-008`, not before this feature ships |
| Any non-loopback bind | `feature-009` (P3) | This SPEC authorises `127.0.0.1` only |
| The `GET /subscribe` endpoint's shape | `feature-006` (P2) | Reserved in the transport; not designed here |
| The MCP façade's tool names and registration snippets | `feature-008` (P2) | The seam is `OPERATIONS` filtered to `plane == "message"` |
| Every column beyond `001_p1.sql` | `feature-004`, `feature-005`, `feature-009`, `feature-010`, `feature-011` | Via a new numbered migration; invariants S-1..S-5 hold |
| **The store-and-forward queue (FR-6.3)** — a message whose destination chat's home machine is offline is held at the **sending** node and delivered when that machine returns (AC-4). Nothing in `001_p1.sql` holds it: `message` rows are keyed to a local `chat`, and an outbound item has no local chat. | `feature-009` | A new table in `002_*.sql`, not a column on `message`. Left open deliberately — its shape depends on the peer protocol and the retry policy, neither of which exists until P3. S-1..S-5 constrain the *chat log*; they say nothing about an outbound queue, so `feature-009` adds one without reopening this SPEC |
| Every retention and timing parameter (TTL, unread depth, overflow, reap, stale, long-poll) | `feature-011`, `feature-004`, `feature-006` | The config *mechanism* is fixed here; the keys are not |
| Reaping and trimming behaviour | `feature-011` (P4) | The node has no retention job at P1; `chat.db` grows |
| Machine-restart survival | **nobody** | Out of scope by the requirements and by this feature's Description |

---

### Sections excluded, and why

| Section | Why excluded |
|---|---|
| **UI Specs** | There is no UI. Every human-facing surface is a terminal command, specified under API Contracts. The dashboard is a separate component this feature does not touch |
| **Events & Messaging** | The product is messaging, but its event semantics — durable log, ordering, at-least-once, dedupe (`feature-005`) and push delivery (`feature-006`) — belong to those features. The only events this feature owns are process-lifecycle transitions, which are in State Machines |
| **Security Specs** | Stated as a positive rather than omitted: §4 removed all authentication from the product, so there is no authn/authz/credential/session design to specify. What exists is in [Security posture](#security-posture); a section header would imply a security model this product does not have |
| **BDD Scenarios** | The Acceptance Criteria above are already Given/When/Then. Restating them would duplicate; [Verification](#verification) maps each to an executable oracle instead, which is the part that was missing |
| **Migration Plan** | Nothing pre-exists to migrate: no store to upgrade, no CLI verb to rename, no user data to move, no behaviour to deprecate. The one forward-looking migration concern — the store's own schema evolution — is specified as S-4 under Data Model, where a reader looking for it will actually be |

---

### Findings beyond the requirements

Four things found on disk while writing this. None blocks the feature; each would have cost an
implementer time.

1. **`test.yml` has no `pytest` step, and no Python-test step at all beyond the generator
   self-tests.** Python tests reach CI only through a shell driver suite discovered by
   `tests/run-all.sh` — `test-dashboard-reader.sh` runs `dashboard/reader/tests/` via `unittest`
   discovery. An implementer who wrote the node's tests as pytest modules and added a
   `pytest chat-node/tests/` line to a document would have **zero CI coverage** and no signal
   that this was so. Handled above by specifying `unittest` + a driver suite.

2. **`technology-stack.md` § Test Commands lists `pytest dashboard/reader/tests/`, but those
   tests are `unittest`** — 24 modules import `unittest`, zero import `pytest`, and no workflow
   or runner invokes `pytest` anywhere in the repository. The command happens to work if pytest
   is installed (it collects `unittest.TestCase` classes), which is why it has survived; it is
   still not the shipped path. A one-line KB correction, outside this work's scope.

3. **`aid dashboard`'s interpreter probe is `python3` only** (`bin/aid`:1225-1229;
   `bin/aid.ps1`:1224-1228), which is the wrong name on Windows, where the launcher is `py` and
   the executable is commonly `python`. The node must not copy that; D-6's ordered candidate
   list is the divergence. Whether the dashboard has the same latent gap is a separate question
   this SPEC does not answer.

4. **The Python probe must use a single-line `-c` script.** `tech-debt.md` W4-3 class G records
   that pyenv-win's `python3` is a shell script routed through `cmd /C`, "which cannot carry an
   embedded newline, so any multi-line `python3 -c` script is mangled" — and names
   `find_free_port()` returning an empty string as the load-bearing instance, first failure in
   six suites. The probe specified in D-6 is one line for exactly this reason. Anyone extending
   it must keep it one line.

**Three touchpoints an implementer must not miss**, because each is an edit to a file this
feature does not otherwise change:

1. The `chat` block in `_aid_usage`'s **default** case (`bin/aid`:244-264) and its PowerShell
   twin — not only the per-command `chat` help.
2. The `# Usage:` **header comment block** at the top of `bin/aid`:10-24 and
   `bin/aid.ps1`:10-24. `coding-standards.md` § File Header Convention makes that header a
   rule, not decoration, and it is the one an editor forgets because it is not executed.
3. `docs/install.md` and `README.md` gain the Python prerequisite for chat — stated as what it
   is, a prerequisite of an **optional feature**, never of AID. Both documents also carry the
   channel table that FR-7.7's four-channel claim rests on, so the sentence belongs beside it.
