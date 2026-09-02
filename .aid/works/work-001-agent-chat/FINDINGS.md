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
| 2 | Does an idle Cursor session wake? | *not yet run* | — |
| 3 | How long may a Cursor `stop` hook block? | *not yet run* | — |
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

## Findings that change the design

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
  Requires probe coverage on every run.
- **Test 4** — two machines. Needs a second machine for the Cursor side, since Cursor requires a
  desktop session.
