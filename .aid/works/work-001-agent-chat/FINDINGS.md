# P0 Wake Feasibility Spike — Findings

Status: **in progress.** Test 1 complete. Tests 2, 3 and 4 outstanding.

Every number here comes from an NDJSON run log, cited by run id. Nothing is inferred from
recollection, and nothing measured on one host is asserted of the other.

---

## Apparatus

| | Machine A |
|---|---|
| Host name | `L-OTTAVIANNA` |
| OS | Windows 11, build 26200, x64 |
| Shell | PowerShell 7.6.5 |
| Python | 3.13.3, `sys.platform` = `win32` |
| Interpreter | `C:/Users/andre.vianna/.pyenv/pyenv-win/versions/3.13.3/python.exe` (pyenv-win) |
| Claude Code | 2.1.258 |
| Cursor | 3.18.9 (Electron 40.10.3, bundled Node 24.15.0) |
| Stub | `127.0.0.1:8811`, `max_wait` 86400 |
| Beat interval | 250 ms |

**Kill-instant resolution on this platform is ±0.25 s, not exact.** Windows delivers no signal a
terminated process can act on, so a killed hook cannot write its own terminal line and the last
`beat` bounds the kill. Any `KILLED(t)` below carries that resolution and `signal:
none observable (Windows)`.

---

## The four answers

| # | Question | Answer | Evidence |
|---|---|---|---|
| 1 | Does an idle Claude Code session wake? | **Yes** | `T1-000-a` |
| 2 | Does an idle Cursor session wake? | **Yes** | `T2-001-a` |
| 3 | How long may a Cursor `stop` hook block? | **Bounded by the hook's own `timeout` setting**, not by a host limit. Honoured iff `D` < `timeout`; on expiry the hook is abandoned, not killed. | `T2-001-a`, `T3-60-a`, `T3-120-a` |
| 4 | Does the wake cross two machines? | *not yet run* | — |

---

## Test 1 — Claude Code wakes

**Pass.** Run `T1-000-a`, Claude Code 2.1.258.

| Measurement | Value |
|---|---|
| Block requested | 30.0 s |
| Block achieved | **30.117 s**, returned under own power |
| Overshoot past deadline | +0.117 s |
| Wake payload emitted | 1 ms after the block ended |
| **Wake → act latency** | **7.581 s** |
| Clock drift over the block | 0.0003 s — no suspend |
| Beat gaps | none over 0.258 s — process scheduled throughout |

The hook asked the stub to wait 60 s while blocking for 30 s, so the stub could not have answered
first: the timeout is the hook's own and the return is under its own power, not a stub artifact.

Claude Code honoured the `decision: block` convention. It parsed the JSON and surfaced the
`reason` field — not the raw JSON — after which the agent ran the named command and the `act` line
was written. The wake works on this host.

**No probe coverage for this run.** Three probe attempts expired before the hook armed, at
20:33:17, 20:38:43 and 20:39:59, while the hook did not start until 20:40:50. The conclusion does
not depend on the probe: `end` proves the hook was not killed, because a killed process could not
have written it, and `act` proves a turn ran. The probe is nevertheless required for test 3, where
`KILLED` and `ABANDONED` are otherwise indistinguishable.

---

## Test 2 — Cursor wakes

**Pass.** Run `T2-001-a`, Cursor 3.18.9. Full probe coverage.

| Measurement | Value |
|---|---|
| Block requested | 30.0 s |
| Block achieved | **30.104 s**, returned under own power |
| Socket elapsed | 30.061 s, `kind=timeout` — 100.2% of the deadline |
| Probe | `alive=true` throughout; `alive=false` 0.235 s after `end` |
| Clock drift over block | 0.0004 s — no suspend |
| Wake → act latency | **voided — see below** |

Cursor honours the same `decision: block` convention as Claude Code, so no `exit2` retry was
needed. The probe's unbroken `alive=true` through the full 30 s, followed by death only *after*
`end` was written, establishes that Cursor did not kill the hook. **Test 3 therefore starts from a
measured floor: Cursor tolerates at least 30 s.**

### The latency from this run is void

The `act` line arrived 118.823 s after the wake — 1.177 s inside the 120 s `ABANDONED` threshold,
and 15.7 times Claude Code's 7.581 s. The operator confirms Cursor raised a command-approval prompt
and that nearly all of that interval was spent walking back to the window, reading it, and clicking
approve.

So the figure measures a human, not a host, and the runbook already voids a run on exactly this
condition. It is recorded here rather than deleted because the near-miss is the useful part: one
more distraction and this run would have been written up as `ABANDONED`, meaning "Cursor refused to
wake", which would have been false.

---

## Test 3 — the Cursor blocking limit (in progress)

`--wake-action text`, so no run's classification depends on a human approving a prompt.

| Run | `D` | Block achieved | `elapsed`/`D` | Probe | Wake → refire | Outcome |
|---|---|---|---|---|---|---|
| `T2-001-a` | 30 | 30.104 s | 1.002 | alive throughout | — | SURVIVED(30) |
| `T3-60-a` (pid 50100) | 60 | 60.072 s | 1.0007 | alive throughout | 3.264 s | **SURVIVED(60)** |
| `T3-60-a` (pid 51852) | 60 | 60.086 s | 1.0009 | alive throughout | 3.890 s | **SURVIVED(60)** |
| `T3-120-a` | 120 | 120.097 s | 1.0006 | alive throughout | **none** | **ABANDONED(120)** |

Two runs were executed at `D` = 60 under the **same run id**, distinguished here by pid. Both
survived, so 60 has two of the three consistent runs the confirmation phase requires.

The repetition cost the first run's raw log: the operator cleared `T3-60-a.*` before the second
attempt, which is what allowed the arming sentinel to be bypassed. The first run's figures above are
preserved from the extraction made when its log was produced, and are **not** re-derivable from
disk. Recorded as a limitation rather than presented as if the raw evidence were still in hand.

`T3-60-a` overshot its deadline by 0.072 s, drifted 0.0007 s between wall and monotonic clocks, and
died 0.099 s after writing its own `end`. Cursor did not interfere with it at any point.

`T3-120-a` blocked for the full 120 s and returned under its own power with the probe never seeing
it die — Cursor did not kill it. But no `refire` was written and no `ACK` appeared in the session.

The cause is not a host limit: the hook was registered with `"timeout": 90`, and `D` = 120 exceeded
it. See F7. **Bisection between 60 and 120 is therefore cancelled** — it would have spent runs
rediscovering a number already present in the configuration. The rungs at 300 and 600 are moot for
the same reason.

One incidental observation on `T3-120-a`: a single skipped beat at `t_mono` ≈ 61 s, 0.504 s against a
0.252 s cadence. Well inside the 2 s void threshold, so the run stands.

### Cursor's real wake latency is about 3.6 s

Runs `T3-60-a` pids 50100 and 51852, wake to `refire`: **3.264 s and 3.890 s**, mean 3.577 s,
spread 0.626 s over two samples. This is the figure the voided 118.823 s was hiding: with no
approval prompt in the path, Cursor turns a returned hook into a completed turn in under four
seconds, using about 3% of the 120 s window rather than 99%.

Two samples establish an order of magnitude, not a distribution. The spread between them is 19% of
the mean, so the third confirmation run at this rung should be treated as informative about
variance rather than as a formality.

**It is not comparable to Claude Code's 7.581 s.** That figure is wake-to-`act`, which includes
spawning a Python interpreter and completing an HTTP round trip; this one is wake-to-`refire` for a
one-word reply. Ranking the two hosts would need the same action measured on both, and no such pair
has been run. What this number does establish is that the wake mechanism is not slow, and that
`ABANDONED`'s 120 s threshold is generous by a factor of about 37 for an unblocked path.

---

## Findings that change the design

### F7 — Cursor's hook `timeout` abandons the hook; it does not kill it

The `stop` hook was registered with an explicit per-hook timeout:

```json
{ "version": 1,
  "hooks": { "stop": [ { "command": "... --deadline 120 --wake-action text", "timeout": 90 } ] } }
```

Every run is explained by one rule — **the wake is honoured if and only if `D` < `timeout`**:

| Run | `D` | vs `timeout` 90 | ACK | Outcome |
|---|---|---|---|---|
| `T2-001-a` | 30 | under | seen | SURVIVED |
| `T3-60-a` (pid 50100) | 60 | under | seen | SURVIVED |
| `T3-60-a` (pid 51852) | 60 | under | seen | SURVIVED |
| `T3-120-a` | 120 | **over** | none | ABANDONED |

No unexplained host policy is needed. `ABANDONED(120)` is `D` exceeding a configured value, not a
discovered limit.

**The behaviour at expiry is the finding, and the probe already caught it.** Cursor's timeout fired
around 90 s into `T3-120-a`, yet the probe recorded `alive: true` until 120.097 s, dying only 0.158 s
after the hook wrote its own `end`. The process outlived Cursor's abandonment by roughly 30 seconds.

So on timeout Cursor **discards the hook's output and stops waiting, but leaves the process
running**. It does not terminate it. Consequences for Feature 003:

- Every wake attempt that outlasts `timeout` leaves an orphaned process behind. Repeated on a poll
  cycle, that is a process leak, and nothing in the host reports it.
- The orphan still holds its long-poll socket open, so the node sees a waiter that no longer has a
  listener. A server counting connected waiters would over-count.
- The waker must therefore keep its own block strictly under the host's configured `timeout`, and
  cannot discover that value by observation alone — it is per-hook configuration, not a host
  constant.

**Correction to an earlier reading.** Before the configuration was known, this evidence was written
up as two independent limits — block-tolerance ≥ 120 s versus act-willingness somewhere in (60, 120].
The first half stands: Cursor genuinely does not kill a long hook. The second was an artefact of
reading a configured 90 s as a discovered boundary, and the bisection it implied would have spent
runs rediscovering a number already written in the config file.

**Still open:** whether `timeout` has a maximum Cursor will accept, and whether 90 is a default it
supplied or a value chosen when the hook was registered. The first bounds how long a waker may ever
block on this host; the second decides whether the product must assume 90 s in the field.

### F1 — The stop hook re-fires after the woken turn

Run `T1-000-a`. The woken turn's `act` landed at 20:41:28.493. **6.257 s later, at 20:41:34.750,
Claude Code fired the stop hook again**, and only the arming sentinel stopped it blocking a second
time — the log records `void: already armed for this run; not re-blocking`.

This is a loop. The wake ends a turn; ending a turn fires the stop hook; the stop hook wakes the
agent. Left alone it never terminates. Any real waker must therefore carry its own re-entry rule,
and "block on every stop event" is not implementable. The spike's sentinel is a throwaway stand-in
for a decision the design now has to make explicitly: what distinguishes a stop that should wait
from a stop that is merely the tail of a wake it already served.

This was not anticipated in the specification and is the most consequential result so far.
**It reproduces on Cursor**: run `T2-001-a`'s stop hook re-fired 6.626 s after its act, against
6.257 s on Claude Code. The loop is not host-specific.

The re-fire is also, usefully, a witness. A second stop event can only mean the host ran a further
turn, which is what "did it wake?" asks — and unlike a tool call it cannot be gated behind an
approval prompt. The apparatus now records it as `refire` rather than `void` for that reason.

### F6 — The stub's aborted response is evidence, and was being thrown away

Every wake run leaves a `WinError 10053` traceback in the stub's terminal, roughly 30 s after the
measurement ends. It is not a fault. The hook asks the stub for `after` = `D` + 30 and times out its
own read at `D`, so the waiter is always gone before the stub finishes sleeping and tries to write.
The traceback is therefore *caused by* the hook correctly returning under its own power, and cannot
occur on a run where the stub answered first — that case is the `VOID` one.

Two problems followed from letting it raise. A multi-line traceback appearing mid-run invites the
operator to assume the run is spoiled, and the only trace left in the log was the **absence** of a
`respond` line, which is weak evidence: indistinguishable from a line never written for some other
reason.

The stub now catches it and logs `client_gone` with the sequence number and how long it had been
asked to wait. That turns a discarded exception into independent corroboration, from the far end of
the socket, that the waiter left first — confirming `own_power` without relying on the hook's own
account of itself.

### F5 — The woken turn's tool call is gated behind human approval on Cursor

Run `T2-001-a`. The wake was delivered and the agent complied, but the shell command it was asked
to run raised an approval prompt and sat there until a human clicked it.

This is the finding that most constrains Feature 003. An autonomous channel between two agents
cannot depend on a woken turn performing a gated action, because the gate is a human. Either the
action must be pre-authorised on every participating host, or **the woken turn must do nothing that
requires authorisation** — the message is delivered as context and the agent simply continues.

It also invalidated the spike's own instrumentation for the timing ladder, since `ABANDONED` is
defined as "no `act` within 120 s" and an unapproved `act` never arrives. Test 3's up-to-25 runs
would each have been measuring operator attention. The apparatus now carries `--wake-action text`,
which asks the woken turn only for a word — no tool, no gate — and takes its witness from the
`refire` line instead. That is the mode the ladder uses.

### F2 — Claude Code runs hooks through bash on Windows

Run `T1-000-a`, and an earlier failed attempt whose error read
`/usr/bin/bash: line 1: PYEXE: command not found`.

The host does not invoke hooks in the platform's native shell. A waker cannot assume `cmd.exe` or
PowerShell quoting on Windows, and any path it emits must survive bash: unquoted backslashes are
consumed silently, collapsing `C:\Users\a\spike_hook.py` to `C:Usersaspike_hook.py`, which then
fails as a missing file rather than as a mangled path. Forward slashes are accepted by Windows and
untouched by bash, and are what the spike emits.

### F3 — The wake instruction reaches the model through the error channel

Run `T1-000-a`. Claude Code displayed the payload as `Stop hook error: A message arrived...`. The
mechanism worked and the agent complied, but the text a user sees is labelled an error. Cosmetic
for the spike; a product that wakes this way on this host will show its users an error string every
time it delivers a message, which is a user-visible consequence worth deciding about rather than
inheriting.

### F4 — An interpreter on `PATH` may be a shim

Machine A's `python` resolves through pyenv-win to `python.bat`. A hook registered against it would
have run the real interpreter as a grandchild of `cmd.exe`, making liveness unreadable for the
process that actually blocks. The waker must resolve the interpreter the way the spike does, from
the running process itself, never from `PATH`.

---

## Still to run

- **Test 2** — Cursor 3.18.9. Whether Cursor honours the same `decision: block` convention is
  unknown; if it does not, the run repeats under `--wake-schema exit2` before Fail is recorded.
- **Test 3** — the ladder, bisection and confirmation runs that give the Cursor blocking limit.
  Requires probe coverage on every run, and must use `--wake-action text` so that no run's
  classification depends on a human approving a prompt (F5). Starts from a measured floor of 30 s.
- **Test 4** — two machines. Needs a second machine for the Cursor side, since Cursor requires a
  desktop session.
