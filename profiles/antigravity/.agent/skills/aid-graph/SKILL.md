---
name: aid-graph
description: >
  Build .aid/knowledge/relationships.md and .aid/knowledge/graph.html from an approved
  Knowledge Base and the project source. On demand, never fired by discovery, and a
  sibling of aid-summarize rather than a phase of it. Reads widely and writes narrowly:
  the Knowledge Base is read-only for the whole run, and that guarantee is a fence
  raised before the first write and verified before the run ends. Idempotent and
  content-addressed: a re-run on an unchanged project is a true no-op, and when it does
  regenerate it names which input changed. Two-grade quality gate (Machine + Human) over
  THIS SKILL'S OWN artifacts only -- never over the Knowledge Base's completeness.
  Knowledge Base gaps are REPORTED and routed onward, never gated on and never fixed
  here. State machine: PREFLIGHT -> ENUMERATE -> STALE-CHECK -> EXTRACT -> EMIT ->
  GAP-REPORT -> RENDER -> VALIDATE -> VISUAL-GATE -> FIX -> DONE.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[--reset] force regeneration  [--grade X] override the minimum for this run only"
---

# Knowledge Graph

Builds two artifacts from a populated and approved `.aid/knowledge/` Knowledge Base plus
the project's own source: `relationships.md`, the machine-readable relationship table,
and `graph.html`, the interactive view over it.

**On demand.** This skill occupies the same post-Knowledge-Base slot as `/aid-summarize`
and is a **sibling** of it — never a phase of it, and never fired by discovery. A graph
built from a half-written Knowledge Base would report gaps that are simply work in
progress, so pre-flight refuses unless the Knowledge Base is finished and approved, and
says what to do instead.

**Read widely, write narrowly.** The run reads the Knowledge Base, the project source,
the external-sources registry, its own settings and its own installed files. It writes
two artifacts, two reviewer ledgers and its own scratch, and nothing else. That one-way
relationship is the whole basis of its trustworthiness as an observer: it cannot alter
the thing it reports on. The guarantee is not a promise made once per state — it is a
fence raised before the first write and verified before the run ends, over the
complement of a declared allowlist, so a write nobody intended is caught rather than
assumed away.

**Idempotent.** Running it twice on an unchanged project does nothing the second time,
and when it does regenerate it names the input that changed.

**It grades its own output and only its own output.** It never scores the Knowledge
Base's completeness: that would fail the skill for reasons outside its control and would
reward under-reporting, which is the one thing a gap signal cannot afford. Knowledge Base
gaps are reported in a separate ledger that no grading state can reach, and routed
onward to the skills that own Knowledge Base repair.

---

## ⚠️ Pre-flight Checks

Run `.agent/aid/scripts/graph/graph-preflight.sh` before any state. It verifies
seven prerequisites — P1 through P7 — and its `--help` lists each with the action that
clears it. See `references/state-preflight.md`.

If it exits non-zero, do NOT proceed and do NOT create any file: the script writes
nothing whatever the answer, and neither should the run.

## Arguments

| Argument | Effect |
|----------|--------|
| *(none)* | A full run. A no-op when nothing changed. |
| `--reset` | Forces regeneration by **discarding the digest comparison** and nothing else: no artifact is deleted, and **no ledger is preserved**. Passed straight through to `.agent/aid/scripts/graph/graph-stale-check.sh --reset`. |
| `--grade X` | Overrides the minimum acceptable grade **for this run only**. Format: `^[A-F][+-]?$`. Passed to `.agent/aid/scripts/graph/grade-graph.sh --grade X`. **Nothing is persisted** — `.aid/settings.yml` is itself one of this run's staleness inputs, so writing a grade floor into it would force an unrelated regeneration on the next run. A durable floor is set through `/aid-config`, which owns that file. |

Without `--grade`, the floor is resolved by the project's single resolver, which
`grade-graph.sh` invokes itself. No state parses `.aid/settings.yml`.

There is no `--table-only`: whether the view is in scope is already decided by a fact on
disk, so a flag would be a second, divergent way to say the same thing.

---

## State Detection

⚠️ **Filesystem is the only source of truth.** Always read actual files on disk.

```
1. PREFLIGHT (synchronous gate). Aborts on failure -- no further state runs, nothing written.

2. Raise the write fence, before the first write of the run.

3. ENUMERATE, then STALE-CHECK -- in that order, and the order is a requirement, not a
   preference: one digest component is defined over the enumerated node set, and a newly
   added artifact is invisible to any stored path list, so enumeration must precede the
   decision. What a CURRENT verdict saves is the expensive half -- the two-pass
   extraction with its bounded agent step, and the render.

4. Route on graph-stale-check.sh's verdict token, which is its LAST stdout line:
     - FIRST_RUN or STALE -> mode = REGENERATE. Continue to EXTRACT.
     - CURRENT            -> mode = IDEMPOTENT. Lower the fence, then DONE's idempotent variant.

5. REGENERATE: EXTRACT -> EMIT -> GAP-REPORT -> RENDER -> VALIDATE -> VISUAL-GATE -> DONE,
   with RENDER and VISUAL-GATE present only where the view is in scope, and FIX entered
   from VALIDATE or VISUAL-GATE.

6. Lower the fence on EVERY exit path -- the idempotent one and the failing ones included.
```

**`view_expected` — one decidable fact, three consumers.** The view is in scope for a run
**iff `.agent/aid/templates/knowledge-graph/graph-skeleton.html` is installed.** That
one fact drives RENDER's and VISUAL-GATE's presence, the `V-*` rubric rows, and the
expected-artifact set — so the three cannot drift, and no flag is needed. `graph-stale-check.sh`
and `grade-graph.sh` each read it for their own half; a state never decides it by judgment.

Print the state-entry line and the "you are here" map on entry to each state:

```
[State: NAME] — {one line: what this state is doing}
aid-graph  ▸ you are here
  [● PREFLIGHT ] → [ ENUMERATE ] → [ STALE-CHECK ] → [ EXTRACT ] → [ EMIT ] → [ GAP-REPORT ] → [ RENDER ] → [ VALIDATE ] → [ VISUAL-GATE ] → [ DONE ]
```

Mark the state being entered `●`, every completed state `✓`, and a state this run skips
`—` (RENDER and VISUAL-GATE where the view is not in scope). FIX is off the spine and is
not a map node; on entry it prints its re-entry target instead.

---

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| PREFLIGHT | `references/state-preflight.md` | inline | → ENUMERATE (exit `0`) / abort the run, naming the failing check (exit `1`) |
| ENUMERATE | `references/state-enumerate.md` | inline | → STALE-CHECK |
| STALE-CHECK | `references/state-stale-check.md` | inline | → EXTRACT (`STALE` / `FIRST_RUN`) / → DONE, idempotent variant (`CURRENT`) |
| EXTRACT | `references/state-extract.md` | inline + `Agent` dispatches per `references/agent-pass.md` | → EMIT |
| EMIT | `references/state-emit.md` | inline | → GAP-REPORT |
| GAP-REPORT | `references/state-gap-report.md` | inline | → RENDER |
| RENDER | `references/state-render.md` | inline | → VALIDATE. **Skipped when `view_expected` is false** |
| VALIDATE | `references/state-validate.md` | inline | → VISUAL-GATE (Machine Grade ≥ the resolved floor) / → FIX (below it) / → DONE (Machine Grade ≥ the floor and `view_expected` is false, VISUAL-GATE being N/A) |
| VISUAL-GATE | `references/state-visual-gate.md` | inline | → DONE (Overall Grade ≥ the floor) / → FIX (below it). **N/A when `view_expected` is false** |
| FIX | `references/state-fix.md` | inline | → RENDER / → EXTRACT / → VALIDATE, by where the repaired input lives |
| DONE | `references/state-done.md` | inline | → halt, in one of two variants |

On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.
When a state completes, route by its `**Advance:**` type (per [`state-machine-chaining.md`](../../aid/templates/state-machine-chaining.md)):
- **CHAIN** → begin the next state's reference doc within the same invocation; no exit.
- **HALT** → print the closing summary and exit.

**Every transition here is CHAIN or HALT; none is a pause.** VISUAL-GATE asks its one
question with `AskUserQuestion` and surfaces the artifact to be opened, rather than
stopping the run — the same treatment `/aid-summarize`'s own browser-requiring check
gets. A pause is only legitimate when the user has to do work outside the chat that the
orchestrator cannot trigger.

> **Note on the two DONE variants:** `references/state-done.md` carries both a normal
> completion (after VISUAL-GATE) and an idempotent completion (after a `CURRENT`
> STALE-CHECK). State Detection step 4 selects which variant runs. The asymmetry is the
> same one `/aid-summarize`'s composite DONE has, and for the same reason.

---

## Quality Gate

VALIDATE runs `.agent/aid/scripts/graph/grade-graph.sh`, which invokes the reused leaf
validators, translates each failure into a row of `.aid/.temp/review-pending/graph.md` at
the severity the rubric assigns, and prints the check inventory and then the Machine,
Human and Overall grades. The rubric — every row, its severity and the reason for it — is
in that script's `--help`, authored once there rather than restated per state.

Three properties are worth naming here because they are what the gate is *for*:

- **The gate's subject is this skill's own artifacts.** No check's subject is the
  Knowledge Base's completeness. The gap rows live in a different ledger whose path is
  passed to no grading call, and `grade-graph.sh` refuses that path outright — so the gap
  rows are unreachable by the gate rather than merely unread.
- **"No row = no finding" is only safe if every check ran**, so the gate reports its own
  coverage: `run` / `skip` / `fail` for **every** rubric row, before the grades and again
  in the closing summary. An absent row therefore means a passed check and never an unrun
  one, and a check that could not run — no browser, an uninstalled validator — is a
  recorded skip that emits no row and is never a silent pass.
- **One mandatory human check, `G1`**, asking whether the live graph is legible. That is
  not machine-decidable, and reviewing rendered web output by reading its source is not a
  valid review of it. Where the view is not in scope the human pool is **N/A** and the
  Overall Grade is the Machine Grade.

---

## Failure modes and recovery

| Symptom | Cause | Recovery |
|---|---|---|
| Pre-flight refuses: the Knowledge Base is not approved | `/aid-discover` has not reached APPROVAL | Run `/aid-discover` through to APPROVAL and approve the Knowledge Base, then re-run. |
| Pre-flight refuses: not inside a git working tree | The enumeration's exclusion classes need `git check-ignore` and `git check-attr` | Run from a git checkout. A non-git tree cannot produce a reproducible node set. |
| Pre-flight refuses: the installed graph area is incomplete | A partial or stale install | Reinstall or upgrade AID, then re-run. |
| A notice says `external-sources.md` is absent, and the run continues | No external-sources registry in this project | Nothing to fix. A missing registry is zero nodes of the affected kinds, not an error; the coverage notes report the absence. |
| STALE-CHECK prints `CURRENT` but you expected a rebuild | Every staleness input is unchanged | `/aid-graph --reset`. If you expected a change to be seen, compare the per-component values the verdict printed against the previous run's. |
| STALE-CHECK exits `1` naming a missing stream | ENUMERATE did not run, or wrote elsewhere | Re-run `/aid-graph` from the top; ENUMERATE must precede STALE-CHECK. |
| The fence exits `1` naming a path | Something wrote inside `.aid/knowledge/` outside the allowlist | Do **not** trust this run's artifacts. Restore the named paths and re-run. If the write was an index regeneration, that write belongs to the skill that owns the index, not here. |
| The fence exits `2`: no snapshot | The run reached the fence check without raising the fence | Re-run from the top. `--verify` fails closed by design: a run that never snapshotted cannot pass verification. |
| VALIDATE reports `V-T skip` | Playwright is unavailable | Expected degradation. The human `G1` check then carries the whole visual review, and it requires a real browser. |
| VALIDATE reports a rubric row `skip -- could not be invoked (exit 2)` | A reused validator's invocation contract changed under this orchestrator | Report it against the validator; the gate records a skip rather than a pass, so nothing is silently green. |
| The gap ledger is gone after the run | Every reviewer ledger is deleted at skill DONE | Expected. The durable carrier is `kb_gaps` in `relationships.md`'s frontmatter; GAP-REPORT prints the command that regenerates the ledger. |
