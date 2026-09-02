# P0 Spike Runbook

**One action per step.** Do them in order.

**What you are producing:** four answers, one of them a number. Nothing else.

**Authority:** `REQUIREMENTS.md § 11 / Feature 001` is the protocol. This file only sequences the
actions. If the two disagree, the specification wins.

Transient. Delete this file with the spike.

---

## Part 0 — Setup (once)

**1.** Create a scratch folder outside this repository: `mkdir ~/spike`

**2.** Change into it: `cd ~/spike`

**3.** Copy the three scripts into it:
`cp /path/to/repo/.aid/works/work-001-agent-chat/throwaway/spike_*.py ~/spike/`

**4.** Run `python3 --version`.

**5.** Confirm it is 3.9 or newer.

**6.** Write down the Python version.

**7.** Open Cursor.

**8.** Write down the Cursor version.

**9.** Run `claude --version`.

**10.** Write down the Claude Code version.

**11.** Write down your OS name and version.

**12.** Turn off machine sleep.

**13.** Turn off display sleep.

**14.** Run `which python3`.

**15.** Write down that absolute path. Call it `PY`.

**16.** Run `realpath ~/spike/spike_hook.py`.

**17.** Write down that absolute path. Call it `HOOK`.

> `PY` and `HOOK` must both be absolute, and you must never wrap them in a shell script. The
> process the host spawns has to be the process being measured. A wrapper leaves the interpreter
> as an orphaned grandchild and makes "still alive" unreadable.

---

## Part 1 — Test 1: does an idle Claude Code session wake?

**18.** Open a terminal. Call it **terminal 1**.

**19.** In terminal 1, run `python3 ~/spike/spike_stub_node.py --port 8811`.

**20.** Confirm it printed a line saying it is listening.

**21.** Leave terminal 1 alone for the rest of this part.

**22.** Open a second terminal. Call it **terminal 2**.

**23.** In terminal 2, run `python3 ~/spike/spike_probe.py --run T1-000-a`.

**24.** Confirm it printed that it is waiting for the hook's start line.

**25.** Leave terminal 2 alone for the rest of this part.

**26.** Open a new empty folder as a project in Claude Code.

> It must not be this repository. `FR-0.4` says the product writes no host tool's configuration,
> and this repo's `.claude/settings.json` is tracked — a hook there lands in every contributor's
> checkout.

**27.** Register this as that project's stop hook: `PY HOOK --host claude --run T1-000-a --deadline 30`

**28.** Pre-approve that command in Claude Code's permission settings.

**29.** Confirm no other hook is registered in that project.

**30.** Write down the current time as the no-touch start.

**31.** Let the Claude Code session go idle.

**32.** Do not touch either machine for 60 seconds.

**33.** Write down the current time as the no-touch end.

**34.** Run `cat ~/spike/logs/T1-000-a.ndjson`.

**35.** Search the output for a line containing `"event": "act"`.

**36.** If that line is present, record test 1 as **Pass**.

**37.** If that line is absent, record test 1 as **Fail**.

**38.** Copy the log into your notes now.

> Not later. A run reconstructed from memory is not evidence.

**39.** Check whether any of the five void conditions happened (see the box below).

**40.** If none happened, go to Part 2.

**41.** If one happened, write down which one.

**42.** Delete `~/spike/logs/T1-000-a.ndjson`.

**43.** Delete `~/spike/logs/T1-000-a.armed`.

**44.** Repeat this part from step 19, using run id `T1-000-b`.

> **The five void conditions.** A run is void if: you interacted with the session; the host
> raised a permission prompt; the machine slept; the stub restarted or returned early; or the
> hook log has a gap over 2 s between `beat` lines with no matching `probe` line.

---

## Part 2 — Test 2: does an idle Cursor session wake?

**45.** In terminal 1, press Ctrl-C to stop the stub.

**46.** In terminal 1, run `python3 ~/spike/spike_stub_node.py --port 8811`.

> The stub is restarted before every run. That is what makes `seq` reliable for ordering.

**47.** In terminal 2, run `python3 ~/spike/spike_probe.py --run T2-000-a`.

**48.** Open a new empty folder as a project in Cursor.

**49.** Register this as that project's `stop` hook: `PY HOOK --host cursor --run T2-000-a --deadline 30`

**50.** Pre-approve that command in Cursor's settings.

**51.** Write down the current time as the no-touch start.

**52.** Let the Cursor session go idle.

**53.** Do not touch either machine for 60 seconds.

**54.** Write down the current time as the no-touch end.

**55.** Run `cat ~/spike/logs/T2-000-a.ndjson`.

**56.** Search for a line containing `"event": "act"`.

**57.** If present, record test 2 as **Pass**.

**58.** If absent, record test 2 as **Fail**.

**59.** Copy the log into your notes now.

**60.** Check the five void conditions again.

**61.** If one happened, repeat this part with run id `T2-000-b`.

---

## Part 3 — Test 3: the number

### The prior

**62.** Open `https://cursor.com/docs/hooks`.

**63.** Find any statement about a hook timeout.

**64.** Write down what it says. If it says nothing, write down "none stated".

**65.** Write down the Cursor version next to it.

> A documented number is not a measured one. You measure regardless. If the two disagree, that
> disagreement is a finding and is recorded both ways.

### One run — the recipe

Every run in this part uses these nine steps. `D` is the duration being tried. `L` is the repeat
letter (`a`, `b`, `c`).

**R1.** In terminal 1, press Ctrl-C to stop the stub.

**R2.** In terminal 1, run `python3 ~/spike/spike_stub_node.py --port 8811`.

**R3.** In terminal 2, run `python3 ~/spike/spike_probe.py --run T3-<D>-<L>`.

**R4.** Register the Cursor stop hook: `PY HOOK --host cursor --run T3-<D>-<L> --deadline <D>`

**R5.** Write down the current time as the no-touch start.

**R6.** Let the Cursor session go idle.

**R7.** Wait until either terminal 2's probe exits, or `D` + 120 seconds have passed.

**R8.** Read `~/spike/logs/T3-<D>-<L>.ndjson`.

**R9.** Write down the outcome, using exactly one of the three labels in the table below, plus
the log excerpt.

| Label | What the log shows |
|---|---|
| **SURVIVED(D)** | An `"event": "end"` line whose note says *returned under own power*, **and** an `act` line after it |
| **KILLED(t)** | A `"event": "killed"` line at `t` < `D`, **and** a `probe` line with `"alive": false`. `t` is exact on POSIX, ±0.25 s on Windows |
| **ABANDONED(D)** | `probe` lines show alive all the way through `D`, the hook returned, but **no** `act` line within 120 s |

### Phase 1 — the ladder

**66.** Run the recipe with `D` = 5, `L` = `a`.

**67.** If the outcome was SURVIVED, run the recipe with `D` = 15, `L` = `a`.

**68.** If that SURVIVED, run the recipe with `D` = 30.

**69.** If that SURVIVED, run the recipe with `D` = 60.

**70.** If that SURVIVED, run the recipe with `D` = 120.

**71.** If that SURVIVED, run the recipe with `D` = 300.

**72.** If that SURVIVED, run the recipe with `D` = 600.

**73.** Write down `S` — the largest `D` that SURVIVED.

**74.** Write down `F` — the smallest `D` that did not.

**75.** If `D` = 600 SURVIVED, write down the answer as "≥ 600 s, no limit observed".

**76.** If `D` = 600 SURVIVED, write down that 600 s was the ceiling probed.

**77.** If `D` = 600 SURVIVED, skip to step 88.

> Chasing an upper bound past 600 s spends hours to change no decision: `§6`'s long-poll default
> is 30 s. Recording the ceiling stops "≥ 600 s" being misread as "unbounded".

**78.** If `D` = 5 did **not** SURVIVE, run the recipe with `D` = 2.

**79.** If `D` = 2 did not SURVIVE, run the recipe with `D` = 1.

**80.** If `D` = 1 did not SURVIVE, write down the answer as "the `stop` hook may not block at all".

**81.** If `D` = 1 did not SURVIVE, write down the terminal mode and the observed `t`.

**82.** If `D` = 1 did not SURVIVE, skip to step 92.

> That outcome is not a failure of the spike — it is the answer this stage exists to find. Cursor
> would have no viable waker adapter and would degrade to the pull floor, which `FR-5.2` already
> allows for.

### Phase 2 — bisection

**83.** Calculate `max(5, 0.10 × F)`. Call it `T`.

**84.** If `F − S` is less than or equal to `T`, go to step 88.

**85.** Calculate `D = round((S + F) / 2)`.

**86.** Run the recipe at that `D`, `L` = `a`.

**87.** If it SURVIVED, replace `S` with that `D`. Otherwise replace `F` with that `D`. Then go
back to step 84.

### Phase 3 — confirmation

**88.** Run the recipe at `D` = `S`, `L` = `a`.

**89.** Run the recipe at `D` = `S`, `L` = `b`.

**90.** Run the recipe at `D` = `S`, `L` = `c`.

**91.** If there is an `F`, run the recipe at `D` = `F` with `L` = `a`, then `b`, then `c` —
three separate runs.

> Where the ladder reached the 600 s ceiling there is no `F`, and the three ceiling runs are the
> whole of phase 3.

**92.** Count how many of the three `S` runs SURVIVED.

**93.** Count how many of the three `F` runs failed.

**94.** If `S` is 3 of 3 and `F` is 3 of 3, write down the result as confirmed.

**95.** If either end is mixed, write down "the limit is not deterministic".

**96.** If either end is mixed, write down the bracket and the per-endpoint counts.

> Do not average a mixed result into one number. The design would then trust it.

### Stop

**97.** Count the total runs performed in Part 3.

**98.** If you reached 25 runs without confirming, stop.

**99.** If 4 hours of wall clock have passed without confirming, stop.

**100.** If you stopped on either budget, write down the bracket you reached.

**101.** If you stopped on either budget, write down every run performed.

**102.** If you stopped on either budget, write down why you stopped.

> That is a valid answer. `AC-20` accepts "could not determine" in exactly this form.

**103.** Count how many runs in Part 3 were void.

**104.** Write down that count.

**105.** Write down the reason for each void run.

> A test that only completes four times in ten attempts is itself a finding.

---

## Part 4 — Test 4: two machines

Machine **A** hosts Claude Code and the stub. Machine **B** hosts Cursor. A VM is fine for either.

**106.** On machine A, run `hostname -I`.

**107.** Write down machine A's LAN address. Call it `A_ADDR`.

**108.** On machine B, run `ping A_ADDR`.

**109.** Confirm the ping replies.

**110.** Copy the three scripts to machine B.

**111.** On machine B, run `python3 --version`.

**112.** Confirm it is 3.9 or newer.

**113.** Write down machine B's Python version.

**114.** Write down machine B's OS name and version.

**115.** Turn off machine sleep on machine B.

**116.** Turn off display sleep on machine B.

**117.** On machine A, stop the stub with Ctrl-C.

**118.** On machine A, run
`SPIKE_MACHINE=A python3 ~/spike/spike_stub_node.py --bind 0.0.0.0 --port 8811`.

**119.** On machine B, run `curl "http://A_ADDR:8811/wait?after=0&run=T4-PING&text=ping"`.

**120.** Confirm it returned JSON.

**121.** If it did not, fix the network before going further.

**122.** On machine A, run `SPIKE_MACHINE=A python3 ~/spike/spike_probe.py --run T4-000-a`.

**123.** On machine B, run `SPIKE_MACHINE=B python3 ~/spike/spike_probe.py --run T4-000-a`.

**124.** On machine A, register the Claude Code stop hook:
`SPIKE_MACHINE=A PY HOOK --host claude --run T4-000-a --deadline 60`

**125.** On machine B, register the Cursor stop hook:
`SPIKE_MACHINE=B PY HOOK --host cursor --run T4-000-a --deadline 60 --url http://A_ADDR:8811/wait`

**126.** Let the machine A session go idle.

**127.** Let the machine B session go idle.

**128.** Confirm both hooks have written a `start` line before the arrival.

**129.** Do not touch either machine.

**130.** On machine A, run `cat ~/spike/logs/stub-8811.ndjson`.

**131.** Confirm the log contains two `request` lines — one per waiter.

**132.** Confirm it contains the single arrival.

**133.** Confirm it contains two `act` lines.

**134.** Confirm one `act` line's `note` field shows `client=` with machine B's address.

**135.** Record test 4 as **Pass** if steps 131 to 134 all held.

**136.** Record test 4 as **Fail** if any did not.

> One log on one machine, so the ordering is unambiguous and no clock synchronisation between the
> machines is needed.

**137.** Run the recipe once more at `D` = `S` over the LAN, using run id `T4-CONF-a` and machine
B's `--url`.

**138.** If that run did not SURVIVE, write down both figures: test 3's loopback number, and this
smaller LAN number.

---

## Part 5 — Hand back

**139.** Collect every file in `~/spike/logs/` on machine A.

**140.** Collect every file in `~/spike/logs/` on machine B.

**141.** Collect your Part 0 notes: the versions and OS for both machines.

**142.** Collect your no-touch windows.

**143.** Collect your void counts and reasons.

**144.** Collect the four recorded outcomes.

**145.** Give me all of it.

I will classify each run, work the ladder and bisection, and write `FINDINGS.md` in the shape the
specification requires — the apparatus block per host, the four answers one row each, and a
mandatory "what was tried" paragraph for anything Inconclusive.

**146.** Wait until `FINDINGS.md` is written and reviewed.

**147.** Delete `~/spike/`.

**148.** Delete `throwaway/` from the work folder.

**149.** Delete the `.aid/works/work-001-agent-chat/throwaway/` line from `.gitignore`.

> `AC-20` requires that no code from this feature is carried forward. Every filename starts with
> `spike_` so that check is a search rather than a judgement.
