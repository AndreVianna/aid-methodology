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
| 3 | How long may a Cursor `stop` hook block? | **As long as the hook's own `timeout` allows — there is no separate host limit.** The wake fires iff `D` < `timeout`, verified across five configurations. Platform default is under 60 s; an explicit 3600 was accepted. On expiry the hook is abandoned, not killed. | `T2-001-a`, `T3-60-a` ×2, `T3-120-a` ×2 |
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

A wake occurred: the instruction reached the model and the agent complied. **How** it reached the
model is not established by this run — see F8. The spike sent Claude Code's `decision: block` shape,
which is not in Cursor's documented schema, so the earlier claim that Cursor honours the same
convention is withdrawn. The probe's unbroken `alive=true` through the full 30 s, followed by death
only *after* `end` was written, does establish that Cursor did not kill the hook. **Test 3 therefore starts from a
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
| `T3-120-a` (`timeout` 90) | 120 | 120.097 s | 1.0006 | alive throughout | **none** | **ABANDONED(120)** |
| `T3-120-a` (`timeout` 3600) | 120 | 120.083 s | 1.0004 | alive throughout | 3.368 s | **SURVIVED(120)** |

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

The cause was not a host limit: the hook carried `"timeout": 90`, and `D` = 120 exceeded it. Raising
`timeout` to 3600 and rerunning the same `D` = 120 produced a clean SURVIVED with an ACK and a
3.368 s refire. See F7.

**Test 3 is answered.** Five configurations, one rule, no exceptions:

| `timeout` | `D` | Predicted | Observed |
|---|---|---|---|
| *absent* | 60 | no wake (default < 60) | no wake |
| 90 | 30 | wake | wake |
| 90 | 60 | wake | wake |
| 90 | 120 | no wake | no wake |
| 3600 | 120 | wake | wake |

There is no host-imposed blocking limit distinct from the configured `timeout`, and Cursor accepted
3600 without clamping it below 120. The bisection, and the rungs at 300 and 600, are all moot: they
were searching for a boundary that turned out to be a number the operator writes.

One incidental observation on `T3-120-a`: a single skipped beat at `t_mono` ≈ 61 s, 0.504 s against a
0.252 s cadence. Well inside the 2 s void threshold, so the run stands.

### Cursor's real wake latency is about 3.5 s

Wake to `refire` across three runs — `T3-60-a` pids 50100 and 51852, and `T3-120-a` under
`timeout` 3600: **3.264 s, 3.890 s, 3.368 s**. Mean 3.507 s, spread 0.626 s. The 3.368 s sample came
from a 120 s block, so latency does not appear to scale with block duration. This is the figure the voided 118.823 s was hiding: with no
approval prompt in the path, Cursor turns a returned hook into a completed turn in under four
seconds, using about 3% of the 120 s window rather than 99%.

Three samples establish an order of magnitude, not a distribution. The spread is 18% of the mean,
which is wide enough that any design budgeting on this number should use the observed maximum rather
than the mean.

**It is not comparable to Claude Code's 7.581 s.** That figure is wake-to-`act`, which includes
spawning a Python interpreter and completing an HTTP round trip; this one is wake-to-`refire` for a
one-word reply. Ranking the two hosts would need the same action measured on both, and no such pair
has been run. What this number does establish is that the wake mechanism is not slow, and that
`ABANDONED`'s 120 s threshold is generous by a factor of about 37 for an unblocked path.

---

## Findings that change the design

### F8 — The spike used the wrong wake mechanism on Cursor, and the right one solves F1

Cursor's documented `stop` hook contract, from `cursor.com/docs/hooks`:

```
// Input   { "status": "completed" | "aborted" | "error", "loop_count": 0 }
// Output  { "followup_message": "<message text>" }
```

`followup_message`, when non-empty, is submitted as the next user message. **`decision: block` is
Claude Code's convention and does not appear in Cursor's schema at all.** The spike sent the Claude
shape to both hosts.

**`decision: block` nevertheless wakes Cursor**, in four runs out of four where `D` < `timeout`
(30, 60, 60, 120). So the Claude shape works on this host, undocumented, and it is the shape every
run so far has used — the `start` lines show `schema=claude`. What is *not* established is the
mechanism: something carries the text to the model, plausibly the same path Claude Code uses where
unrecognised hook output surfaces as an error string the model then reads, but that is inference.

Two consequences. Test 2's claim that "Cursor honours the same convention as Claude Code" is
narrowed rather than withdrawn: the observable holds, the explanation does not. And building on it
would mean depending on behaviour outside the vendor's schema, which can change without notice —
`followup_message` is still the shape to ship, and **it remains untested.**

**The input side matters more.** `loop_count` tells the hook how many automatic follow-ups this
conversation has already triggered, and `loop_limit` caps them — **default 5 for Cursor hooks,
`null` (uncapped) for Claude Code hooks**.

That is F1's re-entry rule, already built and already documented. Feature 003 does not need to
invent one for Cursor: it reads `loop_count` and stops when it judges enough. The throwaway
sentinel was solving a problem the host had already solved.

It also sharpens F1 rather than retiring it. On Cursor the wake loop is bounded at 5 by default. On
**Claude Code the documented default is `null`, meaning uncapped** — so the loop F1 observed there
has no host-side backstop, and the re-entry rule is not optional on that host.

The apparatus now carries `--wake-schema cursor` emitting `followup_message`, and logs `status`,
`loop_count` and the set of keys the host actually sent, so a run records what it was given rather
than what it assumed.

### F9 — `beforeShellExecution` can close F5's approval gate

`beforeShellExecution` is documented to return `{"permission": "allow" | "deny" | "ask", ...}`. A
hook that returns `allow` for the specific command the woken turn runs would remove the human click
that voided `T2-001-a`'s latency.

This does not retract F5: the gate is real, and a product cannot assume users have installed such a
hook. It does mean the constraint is closable by configuration rather than being a hard limit —
which is the difference between "the woken turn may not use tools" and "the woken turn may use tools
the operator has pre-authorised". Feature 003 should decide which of those it requires, because they
imply different install instructions.

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

**On the default — measured.** Cursor's documentation gives `timeout` as "platform default" and
**states no number**, at either place the option table appears. So it was measured: with the
`timeout` line removed entirely, a run at `D` = 60 produced **no ACK**.

| Configuration | `D` | ACK | Implies |
|---|---|---|---|
| `timeout: 90` | 30 | yes | `D` < `timeout` |
| `timeout: 90` | 60 | yes | `D` < `timeout` |
| `timeout: 90` | 120 | no | `D` > `timeout` |
| *no `timeout` line* | 60 | **no** | **platform default < 60 s** |

The platform default is therefore **under 60 seconds**. That makes the third-party 30 s figure
consistent with measurement, though it does not confirm it as the exact value — narrowing further
needs runs with the line absent at smaller `D`.

**This collides with `§6`'s own default.** The product's long-poll default is 30 s, and the wake is
honoured only while `D` < `timeout`. If Cursor's platform default is 30 s, a 30 s long-poll running
under it sits exactly at the boundary and would not be honoured — the node would hold the message,
the hook would return, and nothing would happen.

So the waker **cannot rely on Cursor's default hook timeout**. It must write an explicit `timeout`
comfortably above its own long-poll, and that instruction belongs in whatever the product tells users
to install. This is not a tuning preference; at the default it does not work.

Also documented and relevant: hook failures including timeout are **fail-open** by default, so a
timed-out waker does not block the user's session. `failClosed: true` would invert that, and a waker
must never set it — a hung long-poll would then freeze the agent.

**Still open:** whether Cursor enforces a maximum acceptable `timeout`. That would bound how long
any waker may block on this host, independent of what the product prefers.

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
