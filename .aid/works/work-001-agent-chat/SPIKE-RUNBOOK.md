# P0 Spike Runbook — operator steps

> **What this is.** The steps a human must perform to run Feature 001's spike, because they
> need two live host sessions and a cloud agent cannot be one. The apparatus is built and
> smoke-tested; everything below is yours.
>
> **What this is not.** Not a substitute for Feature 001's specification in
> `REQUIREMENTS.md § 11`. That is the authority on the protocol — the ladder, the bisection,
> the three outcome definitions, what voids a run, and the shape of the answer record. This
> file only sequences the operator actions and records what was already verified for you.
>
> Transient, like everything in this folder. Delete it with the spike.

---

## What is already done

The three artefacts exist in `throwaway/` and are **git-ignored** (`.gitignore`:68), so they
cannot be committed by accident:

| File | Verified |
|---|---|
| `spike_stub_node.py` | `GET /wait` returns `{run, text, sent_at, seq}`; `seq` increments per request and resets on restart; 404 on an unknown path; 400 on a non-integer, negative, or over-`--max-wait` `after`; refuses to start on a bound port rather than silently moving |
| `spike_hook.py` | Blocks on a real socket read (never `sleep`); beats every 250 ms while blocked; returns under its own power at `--deadline`; writes `killed` with the signal number on SIGTERM; arms once per run via a `<run>.armed` sentinel; flags a run VOID if the stub answers first |
| `spike_probe.py` | Learns the hook's pid from the run log's `proc: hook` / `event: start` line; samples liveness every 250 ms; distinguishes *pid gone* from *hook ended while pid alive* — which is the KILLED/ABANDONED distinction |

**End-to-end runs performed here:** a SURVIVED(3 s) run with 13 beats, the probe observing
the pid throughout and then gone, and the act reaching the stub; a KILLED run where SIGTERM
at ~1.5 s of a 30 s block produced `killed` with `signal: 15` and the probe confirmed the pid
gone 0.5 s later. Log paths resolve from the scripts' own location, so they work whatever
working directory a host spawns a hook in — verified by running from `/tmp`.

**What was NOT verified, and cannot be from here:** anything a host does. No Cursor, no
Claude Code, one machine. Tests 1–4 are entirely unrun.

---

## What you need

- **Your laptop** with Cursor (desktop — the `stop` hook needs a real session, not headless
  print mode) and Claude Code.
- **A second machine for test 4.** A VM is fine. The spike hand-passes the peer address and
  tests no discovery, so hypervisor NAT eating multicast does not matter here. Machine B
  needs to be able to open a TCP connection to machine A's stub port.
- **Python 3.9+** on both. Standard library only — nothing to install.

## Before anything: the hook goes in a scratch project, never in this repository

`FR-0.4` — *the product writes no host tool's configuration* — governs this, and the
specification is explicit: each host session runs in **a scratch project directory outside
the AID repository**, with its hook registered in that scratch project's own config or in
your user-scope config. The repository's `.claude/settings.json` is tracked; a hook written
there would land in every contributor's checkout. If you use a project-scope file at all,
use the git-ignored `.claude/settings.local.json`.

Copy the three scripts wherever you like. They need no repository context.

---

## Run discipline (from the specification — these void a run if broken)

- **Run id** is `<test>-<parameter>-<repeat>`, e.g. `T3-060-b`. Every log line carries it.
- **Before each run:** restart the stub, disable machine and display sleep, register no other
  hook, and pre-approve the woken turn's command in the host's permission settings.
- **During each run:** do not touch either machine. Record the no-touch window.
- **After each run:** record the outcome and the log excerpt *immediately*. A run
  reconstructed from memory is not evidence.
- **A run is void** if you interacted with the session, the host raised a permission prompt,
  the machine slept, the stub restarted or returned early, or the hook's log shows a
  heartbeat gap over 2 s with no matching probe observation. Void runs are logged with their
  reason — *how many runs voided and why is itself part of the record.*

---

## Test 1 — an idle Claude Code session

1. Start the stub: `python3 spike_stub_node.py --port 8811`
2. In a scratch project, register `spike_hook.py --host claude --run T1-000-a --deadline 30`
   as the hook, using an **absolute interpreter path and absolute script path, no shell
   wrapper** — the process the host spawns must be the process being measured.
3. Start the probe in its own terminal: `python3 spike_probe.py --run T1-000-a`
4. Let the session go idle. Do not touch it.
5. **Pass** when the session acts on the message with no human action — evidenced by an
   `act` line in the run log, with the session transcript showing no assistant activity
   across the block.

## Test 2 — an idle Cursor session

Same shape, `--host cursor`, run id `T2-000-a`. The route is Cursor's `stop` hook, which
fires when the agent loop ends and can submit the next message.

## Test 3 — the number

**This is the deliverable that is a measurement.** Follow the specification's phases exactly;
they are stated there to the point of tedium and I will not paraphrase them into ambiguity.
In outline: **Phase 0** record what Cursor's docs claim (including "none stated") plus the
Cursor version; **Phase 1** ladder at D = 5, 15, 30, 60, 120, 300, 600 s ascending, stopping
at the first non-SURVIVED, and *descending* to 2 s and 1 s if the lowest rung fails;
**Phase 2** bisect until `F - S ≤ max(5 s, 0.10 × F)`; **Phase 3** three runs at `S` and three
at `F`, accepted only on 3-of-3 at each end.

Command per run: `python3 spike_hook.py --host cursor --run T3-<D>-<rep> --deadline <D>`,
with the probe on the same run id. Loopback deliberately — test 3 measures the host, not the
network.

**Stopping rule:** the first of phase 3 confirming, or 25 runs, or 4 hours of wall clock. If
the budget is exhausted, record the bracket reached, every run performed, and why it stopped
— that is exactly the shape `AC-20` requires of a "could not determine".

## Test 4 — two machines

Machine **A** binds `0.0.0.0` and hosts **Claude Code**; machine **B** hosts **Cursor**,
whose hook holds its block across the network:

```
# machine A
SPIKE_MACHINE=A python3 spike_stub_node.py --bind 0.0.0.0 --port 8811
SPIKE_MACHINE=A python3 spike_hook.py --host claude --run T4-000-a --deadline 60

# machine B  (A_ADDR is machine A's LAN address)
SPIKE_MACHINE=B python3 spike_hook.py --host cursor --run T4-000-a --deadline 60 \
    --url http://A_ADDR:8811/wait
```

Choose the arrival so both sessions are armed before it. **Pass** when machine A's stub log
holds, in order, both waits, the single arrival, and both acts — with machine B's act arriving
from B's address. One log on one machine, so no clock synchronisation is needed.

Also carry **one confirmation run at `S`** over the LAN: if a block that survived on loopback
does not survive across the network, the usable LAN budget is smaller than test 3's number,
and **both figures are recorded**.

`SPIKE_MACHINE` is read by all three scripts and written to the `machine` field, so set it on
each side.

---

## When you are done

Hand me `throwaway/logs/*.ndjson` from both machines. I will do the analysis — classifying each
run SURVIVED / KILLED / ABANDONED from the hook and probe lines together, working the ladder and
bisection, and writing `FINDINGS.md` at the work root in the shape the specification requires:
the apparatus block per host, the four answers one row each, and a mandatory "what was tried"
paragraph for any `Inconclusive`.

Two things then follow, and neither is automatic:

1. **The measured Cursor number and the two wake results are promoted to
   `.aid/knowledge/external-sources.md`** as first-hand measurements carrying method, bound and
   date. They are durable facts about a third-party harness, and re-measuring costs hours. The
   entry names **no work id and no work-folder path** — this folder is pruned when the work
   ships, so a citation to it would be a dangling pointer by design.
2. **Feature 003 unblocks**, and `§6`'s 30 s long-poll default gets re-examined: if the number
   lands near or below 60 s that default is challenged, and if it lands in the hundreds of
   seconds it is comfortably safe. Recording the implication is the spike's job; changing the
   requirement is Feature 003's.

Then delete `throwaway/` and its `.gitignore` line. `AC-20` requires that no code from this
feature is carried forward, and the `spike_` prefix on every filename is there so the check is
a search rather than a judgement.
