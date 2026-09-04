# Pending — to be addressed in the correction and strengthening round

Everything deferred, accepted, or verified by a weaker means than the criterion deserves, gathered
in one place so the strengthening round has a worklist rather than a memory.

**Why this file exists:** each item below was recorded somewhere at the time — a task note, a gate
ledger, a tech-debt row, a manual procedure. Scattered across three deliveries, that is a set
nobody can act on. This is the flat list.

**Scope note:** this file is work-folder state and is pruned when the work ships. Anything here
that must outlive the work is ALSO filed in `.aid/knowledge/tech-debt.md`, and the row id is given.

Status values: `Open` (needs doing) · `Needs-hardware` (needs the operator's second machine or a
live host) · `Accepted` (a deliberate trade, listed so it is re-decided rather than forgotten).

---

## P1 — The PowerShell twins, which is the largest single gap

Four deliveries have shipped PowerShell code that **has never been executed**. No PowerShell
interpreter exists in this environment, so `tests/canonical/test-aid-cli-parity.sh` reports SKIP on
every run, and every twin was written by mirroring the verified Bash side. That is a code reading.

**It has already cost something.** The delivery-003 gate found `aid chat subscribe` present in
`bin/aid` and *entirely absent* from `bin/aid.ps1` — a whole verb, missed because nothing ran it.
The risk is not theoretical any more, and it compounds with every delivery.

| # | Item | Status |
|---|---|---|
| P1-1 | Run `tests/canonical/test-aid-cli-parity.sh` on a machine with PowerShell 7+ and fix whatever it reports | Needs-hardware |
| P1-2 | `MP-01` — the lifecycle and message-plane verbs under PowerShell | Needs-hardware |
| P1-3 | `MP-02` — a fresh install via `install.ps1` places `chat-node/` correctly | Needs-hardware |
| P1-4 | `MP-03` — `roster` and `connect` under PowerShell | Needs-hardware |
| P1-5 | **`subscribe`, `heartbeat`, `leave`, `list` and `reap` have no manual procedure at all** — five verbs whose PowerShell twin is neither executed nor recorded as needing execution. `subscribe` is the one that already produced a HIGH finding | Open |

`P1-5` is the actionable one and should be done in this work, not deferred to hardware: the fix is
to extend the manual procedures so the uncovered verbs are at least *enumerable*. A gap that is
recorded can be closed by whoever has a Windows machine; a gap nobody wrote down cannot.

---

## P2 — Criteria that need a live host or a second machine

These are not weaknesses in the implementation. They are criteria whose subject is a *host's own
behaviour* or a *real network*, and neither exists in this environment. A stub that never raises an
approval prompt proves nothing about a host that would.

| # | Item | Status |
|---|---|---|
| P2-1 | `MP-05` / `AC-1` — a Cursor session and a Claude Code session exchanging a message on one machine, recipient acting with no human action | Needs-hardware |
| P2-2 | `MP-06` / `AC-24` — no approval prompt raised, on a host that gates privileged actions by default | Needs-hardware |
| P2-3 | `MP-07` / `AC-23` — a wake does not loop, on a host whose stop hook actually re-fires | Needs-hardware |
| P2-4 | `MP-08` — the install document followed by somebody who did not write it, on a clean machine | Needs-hardware |
| P2-5 | delivery-004's two-machine criteria: `AC-2`, `AC-4`, and the inter-node link surviving an idle network. The plan itself says the honest validation of the last one is an overnight idle followed by a send, not a unit test | Needs-hardware |

The P0 spike already established `P2-1` through `P2-3` on two machines against its own apparatus.
What is owed is re-running them against the **shipped product**, which is a smaller job than the
spike was.

---

## P3 — Verified by a weaker means than the criterion deserves

| # | Item | Status | Durable row |
|---|---|---|---|
| P3-1 | ~~`FR-7.3`'s surface boundary checked against the CLI rather than the rendered skill.~~ **DONE** before delivery-005, deliberately: the check now reads all five rendered copies -- verb list, forbidden list, and body against the canonical source rather than against each other. Strengthened first so the last delivery's skill changes are held to it. `W1-20` closed | Done | — |
| P3-2 | `AC-25`'s abandoned-hook case is simulated by killing the adapter (`WK18b`) and by a silent server (`WK18d`). Neither is a host discarding output and walking away, though `WK18d` exercises the mechanism that bounds it | Accepted | — |
| P3-3 | `CO24` builds its state with foreign keys briefly off, because the interleaving it guards cannot occur with them on and a single-threaded core. Honest, and worth re-reading if the core ever becomes concurrent | Accepted | — |

`P3-1` is the one to act on: it was filed as needing hardware and it does not — the rendered skill
is on disk at `profiles/*/skills/aid-chat/SKILL.md`.

---

## P4 — Deliberate trades, listed so they are re-decided rather than forgotten

| # | Item | Status |
|---|---|---|
| P4-1 | The Cursor adapter declines re-entry at `loop_count >= 1` while the host's own cap is 5. Stricter on purpose; the cost is at most one deferred wake because the next stop reads the store first. Re-read if the host's follow-up semantics change | Accepted |
| P4-2 | Unknown, stale and already-in-a-channel collapse to one `target_unavailable` token, with the distinction in `detail`. The first rationale for this was wrong and is recorded as wrong in the code | Accepted |
| P4-3 | `test-kb-no-work-ids.sh` allows a work id inside a code span, on the argument that command syntax is not a citation. A real citation in backticks would pass | Accepted |
| P4-4 | The PowerShell subscriber's merged wake object copies a fixed field set, where the Bash twin merges every field the server sent. Cosmetic; a new server field would appear in one twin and not the other | Open |

`P4-4` is small and real, and belongs in the strengthening round.

---

## P4b — A test of my own that can flake under load

| # | Item | Status |
|---|---|---|
| P4b-1 | `WK18d` (the adapter's self-bounding guard, driven against a server that accepts and never answers) failed once during a heavily loaded sequential batch: event-loop starvation pushed the run past the harness bound. It passed three consecutive individual runs and passes under `run-all.sh`. The harness bound is now 90s so the failure mode is unambiguous -- a late guard fails the 25s assertion rather than being killed and reported as exit 124, which reads the same as "the guard never fired". The underlying question is whether an 18s guard is reliable on a starved event loop, and the honest answer is that it is not, which matters for a real adapter on a busy machine | Open |

`P4b-1` deserves a decision in the strengthening round rather than a looser threshold: if the guard
can be starved past the host's timeout, the abandoned-adapter case it prevents is reachable in
production, and the answer may be to bound it with something the event loop cannot delay.

## P5 — Tooling that slowed the work

| # | Item | Status | Durable row |
|---|---|---|---|
| P5-1 | `writeback-state.sh` corrupts a multi-line folded scalar by rewriting only its key line, leaving the file unparseable. Hit **three times** across this work | Open | `W1-18` |
| P5-2 | `test-aid-migrate-trigger.sh` ISOL-01 fails on any uncommitted edit under `packages/npm/` | Open | `W1-19` |
| P5-3 | 15 canonical suites fail and did so before this work began — confirmed by running them in a clean worktree at the pre-work commit. Out of scope for this work; listed so the number is not mistaken for a regression | Accepted | — |

---

## What the strengthening round should actually do

In order, because they are not equally valuable:

1. **`P1-5`** — write the missing manual procedures. Cheap, and it converts an invisible gap into a
   closeable one. The verb that already bit us is in this set.
2. ~~**`P3-1`**~~ — done ahead of delivery-005 rather than after it, so the last delivery's skill
   changes are checked by it instead of being checked afterwards.
3. **`P4-4`** — make the two subscriber twins agree on their output shape.
4. **`P5-1`** — either fix `writeback-state.sh` or stop using the affected path. Three hits is
   enough evidence.
5. Hand the operator a single consolidated list of what needs their hardware, rather than eight
   manual procedures spread through one file.
