# P0 Spike Runbook — Windows (PowerShell)

**One action per step.** Do them in order.

**Shell:** Windows PowerShell or PowerShell 7. **Not `cmd.exe`** — several steps rely on `~`
expansion and PowerShell cmdlets that `cmd` does not have.

**What you are producing:** four answers, one of them a number. Nothing else.

**Authority:** `REQUIREMENTS.md § 11 / Feature 001` is the protocol. This file only sequences the
actions. If the two disagree, the specification wins.

If machine A turns out to be a Linux VM, see **Appendix — Linux machine A** at the end.

Transient. Delete this file with the spike.

---

## Read this before Part 0 — two things Windows changes

**Windows change A — your test 3 number will have ±0.25 s resolution, not exact.** On POSIX the hook catches
SIGTERM and writes the kill instant from inside itself. Windows has no deliverable signal for a
terminated process, so the hook gets no chance to write. The kill is bounded instead by the last
`beat` line, which lands every 250 ms. **The record must say `resolution: ±0.25 s` and
`signal: none observable (Windows)`.** This is expected and the specification already provides
for it — it is not a defect in the run.

**Windows change B — `taskkill`, `Stop-Process` and Ctrl-C are not the same thing.** When you need to end a
process by hand, use Ctrl-C in its own terminal. Do not use `Stop-Process -Force` on the hook
during a measurement run — you would be the thing that killed it, and the log would read as
though Cursor did.

---

## Part 0 — Setup (once)

**1.** Open PowerShell.

**2.** Create a scratch folder outside this repository: `mkdir ~\spike`

**3.** Change into it: `cd ~\spike`

**4.** On your laptop, pull this branch: `git fetch origin work-001; git checkout work-001`

**5.** Copy the three scripts into the scratch folder:

```powershell
Copy-Item C:\path\to\repo\.aid\works\work-001-agent-chat\throwaway\spike_*.py ~\spike\
```

> The three `spike_*.py` files are force-added to this branch **only** so you can fetch them.
> `throwaway/` is otherwise gitignored, and step 162 removes them from version control at
> close-out — `AC-20` requires that none of this code is carried forward.

**6.** Run `py -3 --version`.

**7.** If that failed, run `python --version`.

**8.** If that also failed, run `python3 --version`.

**9.** Write down whichever of those three commands worked. Call it `PY`.

> Windows does not reliably provide `python3`. `py -3` is the launcher that ships with
> python.org installs; `python` is what the Microsoft Store install exposes. Every step below
> writes `PY` — substitute whichever worked.

**10.** Confirm the version it printed is 3.9 or newer.

**11.** Write down the Python version.

**12.** Run `PY -c "import sys; print(sys.executable)"`.

**13.** Write down that absolute path. Call it `PYEXE`.

> Ask the interpreter where it lives; do not ask `PATH`. `Get-Command python` returns the first
> match on `PATH`, which on Windows is frequently a Scoop shim, a `WindowsApps` alias stub, or a
> profile alias — and a shim re-launches the real interpreter as a **child**. The host would then
> be measuring the shim, the shim would exit immediately, and "still alive" would be unreadable
> for the process that matters. `sys.executable` is the interpreter's own answer and cannot be a
> shim.
>
> Sanity-check it before going on: the path should end in `python.exe`, and
> `& "PYEXE" --version` should print the same version you wrote down at step 11. If it ends in
> `py.exe`, or the version differs, you have the wrong path.

**14.** Run `Resolve-Path ~\spike\spike_hook.py`.

**15.** Write down that absolute path. Call it `HOOK`.

> `PYEXE` and `HOOK` must both be absolute, and you must never wrap them in a `.bat`, `.cmd` or
> `.ps1` script. The process the host spawns has to be the process being measured. A wrapper
> leaves the interpreter as an orphaned grandchild and makes "still alive" unreadable.

**16.** Open Cursor.

**17.** Write down the Cursor version.

**18.** Run `claude --version`.

**19.** Write down the Claude Code version.

**20.** Run `[System.Environment]::OSVersion.VersionString`.

**21.** Write down the Windows version.

**22.** Open Windows Settings and set the screen to never turn off.

**23.** In the same place, set sleep to never.

---

## Part 1 — Test 1: does an idle Claude Code session wake?

**24.** Open a PowerShell window. Call it **terminal 1**.

**25.** In terminal 1, run `PY ~\spike\spike_stub_node.py --port 8811`.

**26.** Confirm it printed a line saying it is listening.

**27.** Leave terminal 1 alone for the rest of this part.

**28.** Open a second PowerShell window. Call it **terminal 2**.

**29.** In terminal 2, run `PY ~\spike\spike_probe.py --run T1-000-a`.

**30.** Confirm it printed that it is waiting for the hook's start line.

**31.** Leave terminal 2 alone for the rest of this part.

**32.** Open a new empty folder as a project in Claude Code.

> It must not be this repository. `FR-0.4` says the product writes no host tool's configuration,
> and this repo's `.claude/settings.json` is tracked — a hook there lands in every contributor's
> checkout.

**33.** Register this as that project's stop hook, substituting your `PYEXE` and `HOOK`:

```
PYEXE HOOK --host claude --run T1-000-a --deadline 30
```

**34.** Pre-approve that command in Claude Code's permission settings.

**35.** Confirm no other hook is registered in that project.

**36.** Write down the current time as the no-touch start.

**37.** Let the Claude Code session go idle.

**38.** Do not touch the machine for 60 seconds.

**39.** Write down the current time as the no-touch end.

**40.** Run `Get-Content ~\spike\logs\T1-000-a.ndjson`.

**41.** Search the output for a line containing `"event": "act"`.

**42.** If that line is present, record test 1 as **Pass**.

**43.** If that line is absent, record test 1 as **Fail**.

**44.** Copy the log into your notes now.

> Not later. A run reconstructed from memory is not evidence.

**45.** Check whether any of the five void conditions happened (box below).

**46.** If none happened, go to Part 2.

**47.** If one happened, write down which one.

**48.** Run `Remove-Item ~\spike\logs\T1-000-a.ndjson`.

**49.** Run `Remove-Item ~\spike\logs\T1-000-a.armed`.

**50.** Repeat this part from step 25, using run id `T1-000-b`.

> **The five void conditions.** A run is void if: you interacted with the session; the host
> raised a permission prompt; the machine slept; the stub restarted or returned early; or the
> hook log has a gap over 2 s between `beat` lines with no matching `probe` line.

---

## Part 2 — Test 2: does an idle Cursor session wake?

**51.** In terminal 1, press Ctrl-C to stop the stub.

**52.** In terminal 1, run `PY ~\spike\spike_stub_node.py --port 8811`.

> The stub is restarted before every run. That is what makes `seq` reliable for ordering.

**53.** In terminal 2, run `PY ~\spike\spike_probe.py --run T2-000-a`.

**54.** Open a new empty folder as a project in Cursor.

**55.** Register this as that project's `stop` hook:

```
PYEXE HOOK --host cursor --run T2-000-a --deadline 30
```

**56.** Pre-approve that command in Cursor's settings.

**57.** Write down the current time as the no-touch start.

**58.** Let the Cursor session go idle.

**59.** Do not touch the machine for 60 seconds.

**60.** Write down the current time as the no-touch end.

**61.** Run `Get-Content ~\spike\logs\T2-000-a.ndjson`.

**62.** Search for a line containing `"event": "act"`.

**63.** If present, record test 2 as **Pass**.

**64.** If absent, record test 2 as **Fail**.

**65.** Copy the log into your notes now.

**66.** Check the five void conditions again.

**67.** If one happened, repeat this part with run id `T2-000-b`.

---

## Part 3 — Test 3: the number

### The prior

**68.** Open `https://cursor.com/docs/hooks`.

**69.** Find any statement about a hook timeout.

**70.** Write down what it says. If it says nothing, write down "none stated".

**71.** Write down the Cursor version next to it.

> A documented number is not a measured one. You measure regardless. If the two disagree, that
> disagreement is a finding and is recorded both ways.

### One run — the recipe

Every run in this part uses these nine steps. `D` is the duration being tried. `L` is the repeat
letter (`a`, `b`, `c`).

**R1.** In terminal 1, press Ctrl-C to stop the stub.

**R2.** In terminal 1, run `PY ~\spike\spike_stub_node.py --port 8811`.

**R3.** In terminal 2, run `PY ~\spike\spike_probe.py --run T3-<D>-<L>`.

**R4.** Register the Cursor stop hook: `PYEXE HOOK --host cursor --run T3-<D>-<L> --deadline <D>`

**R5.** Write down the current time as the no-touch start.

**R6.** Let the Cursor session go idle.

**R7.** Wait until either terminal 2's probe exits, or `D` + 120 seconds have passed.

**R8.** Run `Get-Content ~\spike\logs\T3-<D>-<L>.ndjson`.

**R9.** Write down the outcome, using exactly one label from the table below, plus the log excerpt.

| Label | What the log shows |
|---|---|
| **SURVIVED(D)** | An `"event": "end"` line whose note says *returned under own power*, **and** an `act` line after it |
| **KILLED(t)** | The `beat` lines stop at `t` < `D`, **and** a `probe` line shows `"alive": false`. On Windows there will be **no** `killed` line and no `signal` — the last `beat` bounds `t` to ±0.25 s |
| **ABANDONED(D)** | `probe` lines show alive all the way through `D`, the hook returned, but **no** `act` line within 120 s |

### Phase 1 — the ladder

**72.** Run the recipe with `D` = 5, `L` = `a`.

**73.** If the outcome was SURVIVED, run the recipe with `D` = 15, `L` = `a`.

**74.** If that SURVIVED, run the recipe with `D` = 30.

**75.** If that SURVIVED, run the recipe with `D` = 60.

**76.** If that SURVIVED, run the recipe with `D` = 120.

**77.** If that SURVIVED, run the recipe with `D` = 300.

**78.** If that SURVIVED, run the recipe with `D` = 600.

**79.** Write down `S` — the largest `D` that SURVIVED.

**80.** Write down `F` — the smallest `D` that did not.

**81.** If `D` = 600 SURVIVED, write down the answer as "≥ 600 s, no limit observed".

**82.** If `D` = 600 SURVIVED, write down that 600 s was the ceiling probed.

**83.** If `D` = 600 SURVIVED, skip to step 94.

> Chasing an upper bound past 600 s spends hours to change no decision: `§6`'s long-poll default
> is 30 s. Recording the ceiling stops "≥ 600 s" being misread as "unbounded".

**84.** If `D` = 5 did **not** SURVIVE, run the recipe with `D` = 2.

**85.** If `D` = 2 did not SURVIVE, run the recipe with `D` = 1.

**86.** If `D` = 1 did not SURVIVE, write down the answer as "the `stop` hook may not block at all".

**87.** If `D` = 1 did not SURVIVE, write down the terminal mode and the observed `t`.

**88.** If `D` = 1 did not SURVIVE, skip to step 98.

> That outcome is not a failure of the spike — it is the answer this stage exists to find. Cursor
> would have no viable waker adapter and would degrade to the pull floor, which `FR-5.2` already
> allows for.

### Phase 2 — bisection

**89.** Calculate `max(5, 0.10 × F)`. Call it `T`.

**90.** If `F − S` is less than or equal to `T`, go to step 94.

**91.** Calculate `D = round((S + F) / 2)`.

**92.** Run the recipe at that `D`, `L` = `a`.

**93.** If it SURVIVED, replace `S` with that `D`; otherwise replace `F` with that `D`. Then go
back to step 90.

### Phase 3 — confirmation

**94.** Run the recipe at `D` = `S`, `L` = `a`.

**95.** Run the recipe at `D` = `S`, `L` = `b`.

**96.** Run the recipe at `D` = `S`, `L` = `c`.

**97.** If there is an `F`, run the recipe at `D` = `F` with `L` = `a`, then `b`, then `c` — three
separate runs.

> Where the ladder reached the 600 s ceiling there is no `F`, and the three ceiling runs are the
> whole of phase 3.

**98.** Count how many of the three `S` runs SURVIVED.

**99.** Count how many of the three `F` runs failed.

**100.** If `S` is 3 of 3 and `F` is 3 of 3, write down the result as confirmed.

**101.** If either end is mixed, write down "the limit is not deterministic".

**102.** If either end is mixed, write down the bracket and the per-endpoint counts.

> Do not average a mixed result into one number. The design would then trust it.

### Stop

**103.** Count the total runs performed in Part 3.

**104.** If you reached 25 runs without confirming, stop.

**105.** If 4 hours of wall clock have passed without confirming, stop.

**106.** If you stopped on either budget, write down the bracket you reached.

**107.** If you stopped on either budget, write down every run performed.

**108.** If you stopped on either budget, write down why you stopped.

> That is a valid answer. `AC-20` accepts "could not determine" in exactly this form.

**109.** Count how many runs in Part 3 were void.

**110.** Write down that count.

**111.** Write down the reason for each void run.

> A test that only completes four times in ten attempts is itself a finding.

**112.** Write down `resolution: ±0.25 s` and `signal: none observable (Windows)`.

---

## Part 4 — Test 4: two machines

Machine **A** hosts the stub and Claude Code. Machine **B** hosts Cursor. Your Windows laptop
should be **B**, because Cursor needs a desktop session. A VM is fine for **A**.

If A is Linux, use the Appendix's command forms on that side.

**113.** On machine A, find its LAN address:

```powershell
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch 'Loopback' } | Select-Object IPAddress, InterfaceAlias
```

**114.** Write down machine A's LAN address. Call it `A_ADDR`.

**115.** On machine B, run `ping A_ADDR`.

**116.** Confirm the ping replies.

**117.** Copy the three scripts to machine A.

**118.** On machine A, check Python is 3.9 or newer.

**119.** Write down machine A's Python version.

**120.** Write down machine A's OS name and version.

**121.** Turn off sleep on machine A.

**122.** On machine A, allow inbound TCP on port 8811 through the firewall.

> Windows blocks it by default and the failure looks like a network problem. On Windows machine A:
> `New-NetFirewallRule -DisplayName "spike 8811" -Direction Inbound -LocalPort 8811 -Protocol TCP -Action Allow`
> Remove the rule when the spike closes.

**123.** On machine A, set the machine label: `$env:SPIKE_MACHINE = 'A'`

**124.** On machine A, run `PY ~\spike\spike_stub_node.py --bind 0.0.0.0 --port 8811`.

> PowerShell has no inline `VAR=value command` syntax. Setting `$env:` first, as its own step, is
> why steps 123 and 124 are separate.

**125.** On machine B, run `curl.exe "http://A_ADDR:8811/wait?after=0&run=T4-PING&text=ping"`.

> Use `curl.exe`, not `curl`. In Windows PowerShell 5.1 `curl` is an **alias for
> `Invoke-WebRequest`**, which takes different arguments and returns a different object.

**126.** Confirm it returned JSON.

**127.** If it did not, fix the network or the firewall before going further.

**128.** On machine A, open a second terminal.

**129.** In it, set the label: `$env:SPIKE_MACHINE = 'A'`

**130.** Run `PY ~\spike\spike_probe.py --run T4-000-a`.

**131.** On machine B, open a terminal.

**132.** In it, set the label: `$env:SPIKE_MACHINE = 'B'`

**133.** Run `PY ~\spike\spike_probe.py --run T4-000-a`.

**134.** On machine A, register the Claude Code stop hook:
`PYEXE HOOK --host claude --run T4-000-a --deadline 60`

**135.** On machine B, register the Cursor stop hook:
`PYEXE HOOK --host cursor --run T4-000-a --deadline 60 --url http://A_ADDR:8811/wait`

> The hooks inherit `SPIKE_MACHINE` from the host process, not from your terminal. If the
> `machine` field comes out wrong in the logs, set the variable at user scope instead:
> `[Environment]::SetEnvironmentVariable('SPIKE_MACHINE','B','User')`, then restart Cursor.

**136.** Let the machine A session go idle.

**137.** Let the machine B session go idle.

**138.** Confirm both hooks have written a `start` line before the arrival.

**139.** Do not touch either machine.

**140.** On machine A, run `Get-Content ~\spike\logs\stub-8811.ndjson`.

**141.** Confirm the log contains two `request` lines — one per waiter.

**142.** Confirm it contains the single arrival.

**143.** Confirm it contains two `act` lines.

**144.** Confirm one `act` line's `note` field shows `client=` with machine B's address.

**145.** Record test 4 as **Pass** if steps 141 to 144 all held.

**146.** Record test 4 as **Fail** if any did not.

> One log on one machine, so the ordering is unambiguous and no clock synchronisation between the
> machines is needed.

**147.** Run the recipe once more at `D` = `S` over the LAN, run id `T4-CONF-a`, with machine B's
`--url`.

**148.** If that run did not SURVIVE, write down both figures: test 3's loopback number, and this
smaller LAN number.

---

## Part 5 — Hand back

**149.** Collect every file in `~\spike\logs\` on machine A.

**150.** Collect every file in `~\spike\logs\` on machine B.

**151.** Collect your Part 0 notes: versions and OS for both machines.

**152.** Collect your no-touch windows.

**153.** Collect your void counts and reasons.

**154.** Collect the four recorded outcomes.

**155.** Give me all of it.

I will classify each run, work the ladder and bisection, and write `FINDINGS.md` in the shape the
specification requires — the apparatus block per host, the four answers one row each, and a
mandatory "what was tried" paragraph for anything Inconclusive.

**156.** Wait until `FINDINGS.md` is written and reviewed.

**157.** Run `Remove-Item -Recurse -Force ~\spike`.

**158.** On machine A, remove the firewall rule:
`Remove-NetFirewallRule -DisplayName "spike 8811"`

**159.** Remove the force-added scripts from version control:
`git rm --cached .aid/works/work-001-agent-chat/throwaway/spike_*.py`

**160.** Delete `throwaway/` from the work folder.

**161.** Delete the `.aid/works/work-001-agent-chat/throwaway/` line from `.gitignore`.

**162.** Confirm `git ls-files | Select-String spike_` returns nothing.

> `AC-20` requires that no code from this feature is carried forward. Every filename starts with
> `spike_` so that check is a search rather than a judgement.

---

## Appendix — Linux machine A

If machine A is a Linux VM, the scripts are identical; only the shell forms differ.

| Windows (PowerShell) | Linux |
|---|---|
| `PY script.py` | `python3 script.py` |
| `$env:SPIKE_MACHINE = 'A'` then the command | `SPIKE_MACHINE=A python3 script.py` (one line) |
| `Get-Content file` | `cat file` |
| `Copy-Item a b` | `cp a b` |
| `Get-NetIPAddress ...` | `hostname -I` |
| `curl.exe "URL"` | `curl "URL"` |
| `Remove-Item -Recurse -Force dir` | `rm -rf dir` |
| `New-NetFirewallRule ...` | usually nothing; if `ufw` is active: `sudo ufw allow 8811/tcp` |
| `~\spike\` | `~/spike/` |

**On Linux, test 3's resolution is exact rather than ±0.25 s**, because the hook can catch
SIGTERM and record the kill instant itself. That only matters if the Cursor session is the Linux
one — and it will not be, since Cursor needs the desktop. So expect ±0.25 s regardless, and
record it.
