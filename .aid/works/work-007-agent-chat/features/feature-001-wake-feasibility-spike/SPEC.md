# Wake Feasibility Spike

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md §10 (stage P0), §8 (host research), §9 AC-21 | /aid-define |
| 2026-08-09 | "Proven for Claude Code" retracted — the mechanism is first-hand and undemonstrated, which is why it is test 1 rather than an assumption the spike can skip | /aid-define (cross-reference) |
| 2026-08-09 | Technical Specification written — the stub's single endpoint, the two host arrangements, the four-test measurement protocol (ladder → bisection → 3-of-3 confirmation, with killed/abandoned defined separately and a stated stopping rule), the throwaway location and its three disposability mechanisms, the run-log schema, and the answer record. One item flagged for a human: where the measured number lives after the work folder is pruned | /aid-specify |
| 2026-08-09 | Review gate (C+) — four findings fixed. The stub's default port moved to **8811**: the claim that AID has no fixed port to collide with was false (`8787` is the dashboard default in both CLI entry points), and the port originally chosen, `8799`, is the one the maintainer's own documented local dashboard command uses on the very machine the spike runs on. The stub now fails loudly on a bound port rather than falling back. `seq` defined where it is emitted; the act request corrected to carry the mandatory `run` parameter; FR-0.4 restated with its **MCP** qualifier — it governs MCP configuration, so the spike's hook placement follows its reasoning by choice rather than by rule. The two deferrals raised as Q22 and Q23 | /aid-specify (review fix) |
| 2026-08-09 | **Q22 answered — the results are promoted to the Knowledge Base.** The measured Cursor blocking limit and the two wake results go into `external-sources.md` when the spike completes, as first-hand measurements carrying method, bound and date; the full run record stays in `FINDINGS.md` and is pruned with the folder. The KB entry names no work and no work-folder path — the folder it came from will not exist, so a citation to it would be a dangling pointer by design | /aid-specify (stakeholder Q22) |
| 2026-08-09 | Re-gate cycle 4 (B+) — one finding, and it was introduced by cycle 3's own fix. Giving `spike_probe.py` a `--log` **default** ("the same run log the hook writes") named a value nothing in the document could compute: no passage fixed a filename or directory for the per-run NDJSON log, and the stub's and hook's `--log` flags had no stated default either. The convention is now stated **once**, in § Telemetry — `throwaway/logs/<run>.ndjson` per run, `throwaway/logs/stub-<port>.ndjson` per stub process — and all three flag descriptions point at it, so the hook and probe meet in one file without the operator passing matching paths. Both `throwaway/`-scoped guarantees still cover it: the `.gitignore` line and the end-of-spike deletion are directory-wide | /aid-specify (review fix) |
| 2026-08-09 | Review gate cycle 3 (B+) — one finding fixed. `spike_probe.py` was the only one of the three artifacts with no flags column, so an implementer would have had to invent its interface to run test 3 — the test that produces the spike's one measured number. Its row now names `--run`, `--log` and `--interval-ms`, and states that the pid comes from the hook's `start` line, matching what the § Telemetry schema already said | /aid-specify (review fix) |
| 2026-08-10 | **Runtime reset sweep — three edits, and one of them retracts a change made earlier the same day.** (1) **The spike stays Python, decisively.** An earlier edit had turned this into an "open question, recommendation Node" note, on the ground that the two anchors the `3.9+` floor deferred to (the repository floor, the node's 3.12) had both disappeared. **That note was itself the defect** — it left a spec graded *Ready / A+ / DONE* asserting the language was undecided one paragraph above committing every file to a `python3` shebang, `argparse` and `.py` filenames. The `3.9+` never derived from either anchor; it is this spike's own floor. Python is kept because what the spike measures is a runtime-independent *host* property, Python-stdlib is the weaker assumption on a second machine, and the code is deleted when the spike closes — so a three-file rewrite would risk a defect in the one stage whose output is a measurement. (2) Two mDNS references restated: FR-6.1 is an outcome, not a mechanism, so the hand-passed peer address stands in for no particular one. (3) **The FR-0.4 reasoning corrected, and its conclusion reversed:** this section argued a hook is not MCP configuration, so FR-0.4 did not govern the spike, which followed its spirit by choice. FR-0.4 is now broader — *no host tool's configuration* — so it **does** govern the hook. The practice already complied; what changed is that compliance is now required rather than voluntary | /aid-specify (runtime reset) |

## Source

- REQUIREMENTS.md §10 stage P0 (scope, expectations, rationale), §8 Assumptions (host research and the unvalidated assumption), §9 AC-21

## Description

Answer the one question that can invalidate the whole design, before anything is built on
top of it: **can a message arriving from outside turn an idle AI session into a live turn,
with no human touching anything?**

**Neither host has actually been proven.** For Claude Code the mechanism is understood
first-hand — a long-lived monitor streams events into a session, and events arrive even while
the session sits waiting — but that is a runtime capability description, not a published
document and not a demonstration, so it is untested like everything else here. That is
precisely why it is **test 1**: if the one host rated most likely to work does not, FR-5 has
no demonstrated instance at all. Cursor is weaker still. Cursor's
documentation states plainly that no background process can start a turn; the only way in
is its `stop` hook, which fires when a turn ends and can submit the next message. So the
route exists, and everything depends on a number nobody has measured: **how long Cursor
lets that hook block before killing it.** Block long enough and Cursor behaves like Claude
Code. Die after a second and Cursor falls back to reading its own mail.

The work is a throwaway stub — one endpoint that waits, then answers — driven against two
real tools on two real machines. **Every line is discarded.** The deliverable is four
recorded answers, one of them a measured number, and nothing else.

## User Stories

- As the operator, I want to know whether an idle Cursor session can be woken at all, so
  that I find out before P1 is built rather than after P3.
- As the operator, I want the Cursor hook's blocking limit as a number, so that the
  subscriber's timeout is chosen from evidence rather than guessed.
- As a developer, I want a recorded "we could not determine it, and here is what we tried",
  so that an unanswered question is visibly unanswered instead of silently assumed.

## Priority

Must

## Acceptance Criteria

- [ ] Given an idle Claude Code session with the stub armed, when a message is sent, then
      the session acts on it with no human action — recorded as pass or fail.
- [ ] Given an idle Cursor session with a blocking `stop` hook, when a message is sent,
      then the session acts on it with no human action — recorded as pass or fail.
- [ ] Given a Cursor `stop` hook that blocks indefinitely, when the host terminates it,
      then **the elapsed time is recorded as a number**.
- [ ] Given the two sessions on different machines on the same network, when a message is
      sent, then the exchange is recorded as pass or fail.
- [ ] Given any test that could not be completed, when the spike closes, then the record
      states what was attempted and why it was inconclusive — silence is not an outcome.
- [ ] Given the spike is complete, when P1 begins, then **no code from this feature has
      been carried forward**.

---

## Technical Specification

This specifies an **experiment, not a component**. What follows is an apparatus, a procedure,
and a record format. It deliberately designs no part of the node — the node's shape is
`feature-003`'s subject, and anything decided here would be decided before the evidence
exists, which is the whole reason this stage runs first.

Two properties govern every choice below:

1. **Nothing is proven yet.** Both wake mechanisms are hypotheses. Claude Code's is
   understood first-hand and is not a citable document (REQUIREMENTS §8, and
   `.aid/knowledge/external-sources.md` § Host agent-tool documentation: "Treat any Claude
   Code harness claim as unsourced until a published reference exists"). Cursor's route is
   documented but its one load-bearing number is unmeasured. The apparatus therefore treats
   both hosts identically and lets neither pass on reputation.
2. **Every artifact is thrown away** (AC-21, §10 "P0 expectations"). The location, the
   naming, and the file count below are chosen so that promotion into P1 requires a
   deliberate act that a reviewer can see, rather than an omission nobody notices.

### Data Model

**Deliberately excluded — no schema exists to specify.** The spike persists nothing that
outlives a run: no chat, no message log, no member position. It writes exactly two on-disk
shapes, both of them evidence rather than state — an append-only run log (§ Telemetry &
Tracking) and the answer record (§ Recording the Answers). Both are specified where they are
used. Introducing a durable store here would be the first step toward the node, which this
stage exists to *not* build.

### Feature Flow

#### The stub node — one endpoint, and only one

| Property | Value |
|---|---|
| Method and path | `GET /wait` |
| Query parameters | `after` (integer seconds, default `0`), `text` (string, default `""`), `run` (opaque run id, echoed back) |
| Behaviour | Sleep `after` seconds on the request's own thread, then respond |
| Success response | `200 application/json` — `{"run": "<run>", "text": "<text>", "sent_at": <epoch_ms>, "seq": <n>}`. **`seq`** is a per-process counter incremented once per request served, starting at `1`, reset when the stub restarts. It exists so two responses within the same millisecond are still orderable in the log, and so a restarted stub is visible as a counter that went backwards rather than as a silent gap |
| Errors | `404` unknown path; `400` non-integer, negative, or above `--max-wait` (default `86400`) `after` |
| Concurrency | `http.server.ThreadingHTTPServer` — a single-threaded server would serialise the two waiters and fail test 4 for a reason that has nothing to do with the wake |
| Every request | Logged before the sleep begins and again after the response is written (§ Telemetry & Tracking) |

**`after` is the send.** The stub has no `send` operation and gains none: the arrival time is
chosen by the caller when it arms the wait, and the timer expiring *is* the message being
sent. A real send path is `feature-005`, and building one here would produce exactly the
artifact most likely to be promoted. `after=0` therefore does double duty — it is how a woken
session reports that it woke (the request itself is the machine-readable witness), at the cost
of nothing, because an immediate return is the same code path.

#### What the words mean, operationally

These three definitions are load-bearing; without them test 1 can pass while proving nothing.

- **Idle** — *no model tokens are being consumed and no turn is in progress.* This is FR-5.5's
  bar ("an adapter blocks in a process outside the model"), not "the window is unfocused". A
  session holding a foreground shell call open is **busy**, not idle, and a run arranged that
  way is invalid. The evidence that a run was idle is that the block lived entirely inside a
  hook process (the hook log spans the interval) while the session transcript shows no
  assistant activity across it.
- **No human action** — between arming and the arrival, the operator issues no input, clicks
  nothing, and answers no prompt. A host permission prompt for the woken turn's command counts
  as human action and invalidates the run for the pass criterion (see § Test Method, "What
  invalidates a run").
- **Acts on it** — the woken turn performs one externally observable act: it runs
  `<python> <spike-dir>/spike_hook.py --act <run> --url <stub-url>`, which issues
  `GET /wait?after=0&text=ACT-<run>&run=<run>`. **`run` is mandatory on every request**, here
  as everywhere — it has no default (see the endpoint contract above), and every log line from
  every process carries it, which is what makes a run's lines separable from a neighbour's.
  The stub's request log records it with a timestamp, so "it acted" is a line in a file rather
  than an impression of a transcript. The transcript is kept as corroboration, not as the
  primary witness.

#### Arrangement CC — Claude Code

1. The operator registers a `Stop` hook whose command is an absolute interpreter path plus an
   absolute path to `spike_hook.py --host claude` (host configuration, never the repository's
   — see § Layers & Components).
2. The operator gives the session one trivial prompt and stops touching the machine. The turn
   ends; `Stop` fires; the hook process starts and the session is idle by the definition above.
3. The hook checks the `stop_hook_active` guard the host provides and exits `0` immediately,
   without blocking, when it is set — omitting this guard loops the session forever
   (REQUIREMENTS §2, prior art 2). **How that flag is carried to the hook is read from the
   host's own hook contract at execution time and copied into the record's apparatus block**,
   for the same reason Cursor's payload schema is (below): the Knowledge Base holds no citable
   Claude Code harness document, so a transport asserted here would be a guess. The hook also
   exits immediately when this run's `<run>.armed` sentinel is already consumed, so a run arms
   exactly once and a repeat cannot pollute the next measurement.
4. The hook issues `GET /wait?after=<N>&run=<run>` against the stub and blocks.
5. At `t0+N` the stub responds. The hook emits the continuation payload that makes the session
   take a further turn, carrying the instruction to perform the act.
6. The act reaches the stub. Test 1's answer is the presence or absence of that line, plus the
   idle and no-human-action evidence.

**Arrangement CC is the constructible one, not the one §8 describes.** §8's Claude Code row
rests on a long-lived monitor streaming events into the session; the spike has no such server,
and a stub that grew one would stop being a stub. The blocking `Stop` hook is the route this
work has already written down (§2, prior art 2) and is what CC tests. If it fails, the second
attempt is §8's streamed-event path, and if that proves unconstructible against a stub, *that
is the recorded answer* — AC-21 admits "could not determine" precisely here, provided the
record says what was tried. Which arrangement produced the answer is a required field of the
record.

#### Arrangement CU — Cursor

Identical in shape, with three differences that come from the host:

1. The hook is Cursor's **`stop`** hook, which fires when the agent loop ends and can submit
   the next user message (`https://cursor.com/docs/hooks`, catalogued in
   `.aid/knowledge/external-sources.md`).
2. The continuation payload is Cursor's, not Claude Code's. **The exact field names are read
   from that vendor page at execution time and copied verbatim into the record's apparatus
   block.** They are not stated here: the Knowledge Base registry records the hook's semantics
   and not its payload schema, and a schema guessed in a specification is a defect that
   surfaces as a mysterious test failure.
3. Cursor is the host under measurement in test 3, so the same hook binary carries the
   block-limit instrumentation.

### Layers & Components

There are **three files**, and the count is itself a design decision — a spike with a module
layout is a spike someone will promote.

| Artifact | Role |
|---|---|
| `spike_stub_node.py` | The one endpoint above. `--port` (default `8811` — see § External Integrations for why not 8787 or 8799), `--bind` (default `127.0.0.1`), `--max-wait`, `--log` (default `throwaway/logs/stub-<port>.ndjson`; § Telemetry) |
| `spike_hook.py` | Both hooks and the act. `--host claude` or `--host cursor`, `--url`, `--after`, `--deadline`, `--run`, `--log` (default `throwaway/logs/<run>.ndjson`; § Telemetry); `--act <run>` performs the woken turn's single request. Arms once per run via a `<run>.armed` sentinel beside it |
| `spike_probe.py` | External observer. `--run` (required — which run to watch), `--log` (default `throwaway/logs/<run>.ndjson` — the same file the hook resolves for that run; see § Telemetry), `--interval-ms` (default `250`). Reads the run log until it sees that run's `proc: hook` / `event: start` line, takes the `pid` from it (the schema in § Telemetry names that line as where the probe learns it), then samples that pid's liveness every `--interval-ms` and appends `probe` events to the same log. Exits when the pid dies or the run ends. It exists only to tell *killed* from *abandoned* (§ Test Method) |

#### Where they live, and why that location is the disposability mechanism

All three live in **`.aid/works/work-007-agent-chat/features/feature-001-wake-feasibility-spike/throwaway/`** — a new directory,
created by this feature and deleted by it.

Three independent things make promotion hard, which is what "disposable by construction" has
to mean if it is to mean anything:

- **The repository rule.** `CLAUDE.md` states that work folders are transient and that **no
  permanent artifact may depend on the contents of a specific work folder.** A P1 task that
  imported from this path would break a standing rule, visibly, in review — not merely be in
  poor taste.
- **The disk.** The work folder is pruned when the work ships, so the code stops existing
  without anyone deciding to delete it.
- **Git.** `.aid/works/work-007-agent-chat/` is **untracked today** (verified:
  `git check-ignore` does not match it and `git status --porcelain` reports it as `??`), and
  REQUIREMENTS AC-20 already relies on that fact when it excludes "untracked working state"
  from the floor sweep. Untracked-by-accident is not a guarantee, so this feature adds **one
  line** to `.gitignore` for the `throwaway/` directory, in the existing
  "Transient pipeline work folders -- kept LOCAL only, never committed" block that already
  carries `.aid/works/work-023-ticket-integration/` and
  `.aid/works/work-004-optimize-skill-library/`. That line is removed when the work ships. It
  is a rule *about* a work folder rather than a dependency *on* one, which is why it does not
  offend the transience rule — and the precedent for it is already in the file.

The `spike_` prefix on every filename is chosen so the no-carry-forward check is a search
rather than a judgement (§ Recording the Answers).

#### Where they must not live, and the concrete mechanism each would trip

| Location | What would happen |
|---|---|
| `tests/canonical/` | `tests/run-all.sh` discovers suites by the glob `tests/canonical/test-*.sh` and runs each under `timeout 300` (`tests/run-all.sh`:8,:93). A spike script there is auto-enrolled into CI merely by existing, and the block-limit run needs longer than 300 s — it would red master while measuring nothing |
| `canonical/` | Rendered into `profiles/` by `run_generator.py` and guarded by the render-drift gate; the spike would ship to every adopter |
| `dashboard/` | The file set is derived from `dashboard/MANIFEST` by five consumers and gated by `tests/canonical/test-dashboard-manifest.sh` |
| `packages/npm/`, `packages/pypi/` | Both declare empty dependency sets on purpose (decision D10, FR-7.6); anything here is distribution |

#### Language, runtime, and conformance

**Python, standard library only, `3.9+`**, and the actual interpreter version on each machine is
recorded. Stdlib-only
means nothing to install on the second machine. Not shell, because both hooks must run unchanged
on Windows and on the LAN peer, and because the measurement needs a monotonic clock and — on
POSIX, where one can be installed — a signal handler inside the process being timed.

> **The spike stays Python, and stays deliberately unaligned with the product's runtime.**
> This paragraph originally stated `3.9+` while taking **no** position on either the repository
> floor or the node's 3.12 — a spike that pinned either would be a spike with an opinion about
> P1. On 2026-08-10 both anchors disappeared: the repository-floor feature was withdrawn and the
> node moved to Node (REQUIREMENTS §8 Toolchain). **The `3.9+` here is unaffected, because it
> never derived from either.** It is a floor this spike sets for itself.
>
> **Why not follow the product to Node.** What the spike measures is a *host* property — whether
> a tool can hold a token-free wait and turn an arriving message into a turn, and how long a
> blocking hook survives before the host kills it. That is runtime-independent: no finding of
> this feature changes with the language. What the choice does affect is the assumption imposed
> on the two machines the spike runs across, and there Python is the **weaker** assumption, being
> present by default on more Linux and macOS installations than Node is — which is precisely why
> stdlib-only was chosen in the first place. Add that the code is deleted when the spike closes,
> and alignment with P1 buys nothing while a rewrite of three files risks a defect in the one
> stage whose output is a measurement.
>
> **This is recorded rather than left implicit** because a reader arriving after the runtime
> reset would otherwise reasonably expect Node here, and reasonably suspect the Python below of
> being an oversight. It is a decision.

The three files follow `.aid/knowledge/coding-standards.md` § Python Conventions —
`#!/usr/bin/env python3`, a header block stating Purpose / Usage / Exit codes (§ File Header
Convention), `from __future__ import annotations`, type hints, `argparse` inside
`main() -> int` with `sys.exit(main())`, results on stdout and diagnostics on stderr. Exit
codes reuse the documented scheme (§ Exit Codes): `0` success, `1` runtime failure, `2` usage
or argument error, `3` for a bind or connection failure, whose semantics match the existing
network/fetch code. Each header additionally opens with the line
`THROWAWAY - work-007 stage P0. Deleted when the spike closes. Do not import, copy, or
promote.`

#### Host configuration is the operator's, and never this repository's

Each host session for the spike runs in **a scratch project directory outside the AID
repository**, and its hook is registered in that scratch project's own host configuration or in
the operator's user-scope configuration. The repository's `.claude/settings.json` is **tracked**
(verified with `git ls-files`) and the repository's `.claude/` tree is written only by the
install path — a spike that edited it would both pollute the dogfood tree and put a hook into
every AID contributor's checkout. If a project-scope file is used at all it is the git-ignored
`.claude/settings.local.json` (`.gitignore`:55). This is **required by FR-0.4, not merely aligned with it** — and that changed on
2026-08-10. FR-0.4 previously said AID writes and manages no host tool's **MCP**
configuration, and this paragraph reasoned from that narrow wording: a hook is not MCP
configuration, so the requirement did not govern the spike, which then followed its spirit *by
choice*. **The restated FR-0.4 is broader** — "the product writes no host tool's configuration",
with MCP named only as one instance — so it now governs the spike's hook directly. **The
practice below is unchanged and already complies**; what changes is that compliance is no longer
optional, and a future spike edit that reached into a tracked host-config file would be a
requirement violation rather than a lapse of taste.

### Test Method / Measurement Protocol

#### Common apparatus and run discipline

- **A run is identified** by `<test>-<parameter>-<repeat>`, e.g. `T3-060-b`, and that id
  appears on every log line the run produces, in both processes and on both machines.
- **Clocks.** Elapsed times come from `time.monotonic()`; wall-clock ISO-8601 UTC is logged
  alongside it only for correlating the two machines and the host's own logs. No elapsed figure
  is ever computed from wall clock.
- **Before each run:** the stub is restarted, machine sleep and display-sleep are disabled, no
  other hook is registered, and the woken turn's command is pre-approved in the host's
  permission settings.
- **During each run:** the operator does not touch either machine. The no-touch window is
  recorded with its start and end.
- **After each run:** the operator records the outcome and the log excerpt immediately. A run
  reconstructed from memory later is not evidence.

#### What invalidates a run

Any of the following voids the run, which is re-executed rather than interpreted: the operator
interacted with the session; the host raised a permission prompt; the machine slept; the stub
restarted or returned early; the hook's own log shows a gap larger than 2 s between heartbeats
without a matching probe observation. Void runs are logged with their reason — the count of
void runs and why is part of the record, because a test that can only be run four times in ten
attempts is itself a finding.

#### Test 1 — an idle Claude Code session (AC-21 question 1)

Arrangement CC with `--after 60`. **Pass** when all four hold: the act appears in the stub's
request log; it appears after the arrival; the transcript shows no assistant activity between
arming and arrival; and the no-touch window covers the whole interval. **Fail** when the
arrival is served and no act follows within 120 s. Three runs; the answer is the majority with
all three outcomes recorded, and a 2–1 split is reported as intermittent rather than smoothed
into a pass.

#### Test 2 — an idle Cursor session (AC-21 question 2)

Arrangement CU, `--after 60`, otherwise identical to test 1. Test 2 is only meaningful for a
block that Cursor tolerates, so it runs at `after=60` first and, if the hook is killed before
the arrival, is re-run at a duration test 3 has shown to survive. Ordering note: test 3 may
therefore have to run before test 2 completes, and the record states the order actually used.

#### Test 3 — the number (AC-21 question 3)

This is the deliverable that is a measurement, so its procedure is stated to the point of
tedium.

**What is being measured.** Not "how long the process lives" but **how long a `stop` hook may
block and still have its continuation honoured** — the usable blocking budget. A hook that
survives 300 s and whose submitted message Cursor then ignores is worth exactly as much as one
that was killed at 5 s, and a protocol that only watched the pid would score the first as a
success.

**Apparatus.** The hook blocks on a real socket read, not on `sleep`: it issues
`GET /wait?after=<D+30>&run=<run>` against the stub on **loopback** and applies its own client deadline
of `D`. So the stub can never return first, the block is a genuine network wait (some hosts
time out on silence rather than on runtime, and `sleep` would not exercise that), and a hook
that is left alone returns under its own power at exactly `D`. Loopback is deliberate: test 3
measures the host, not the network. The hook is invoked as an absolute interpreter path plus an
absolute script path, with **no shell wrapper**, so the process the host spawns is the process
being measured — a wrapper would leave the interpreter as an orphaned grandchild and make
"still alive" unreadable.

**Instrumentation.** The hook writes `start` (with its pid and `D`), then a `beat` every
250 ms, then one terminal line. On POSIX it installs handlers for SIGTERM, SIGINT and SIGHUP
that write `killed` with the elapsed time and the signal number, giving the kill instant
exactly. **On Windows there is no such signal** — a terminated process gets no chance to
write — so the last `beat` bounds the kill to within 250 ms, and the reported number carries
that resolution explicitly. `spike_probe.py` samples the pid on the same 250 ms cadence from
outside, which is what distinguishes a dead process from a live but ignored one. Each log line
is flushed to the OS on write; `fsync` is not used, because a process kill does not lose data
already handed to the kernel and 2,400 syncs would perturb the thing being timed.

**The three outcomes, defined before any data is collected.**

- **SURVIVED(D)** — the hook returned on its own at `D`, *and* the act reached the stub. Both
  halves are required.
- **KILLED(t)** — the heartbeat stopped at `t < D` and the probe confirms the pid gone. `t` is
  exact on POSIX and `±0.25 s` on Windows.
- **ABANDONED(D)** — the probe shows the process alive through `D` and the hook returned, but no
  act follows within 120 s: Cursor stopped waiting and moved on without honouring the
  continuation.

The usable budget is bounded by whichever of KILLED and ABANDONED appears first, and the record
names which mode was observed. Treating them as one number would hide the more interesting
failure.

**Phase 0 — the prior.** Re-read `https://cursor.com/docs/hooks` and record whatever timeout it
states, including "none stated", together with the Cursor version. A documented number is not a
measured one; the measurement is performed regardless, and a disagreement between the two is a
finding recorded in both directions.

**Phase 1 — ladder.** One run each at `D` = 5, 15, 30, 60, 120, 300, 600 s, ascending. Stop at
the first non-SURVIVED outcome. This yields `S` (largest survived) and `F` (smallest failed).
If 600 s survives, stop the ladder and go straight to phase 3, confirming at the 600 s ceiling,
for the answer **"≥ 600 s, no limit observed"** — that is a complete answer for the design's
purposes, since §6's long-poll default
is 30 s, and chasing an upper bound past 600 s spends hours to change no decision. Record the
ceiling that was probed, so "≥ 600 s" is never mistaken for "unbounded".

**The degenerate case has to be handled, because it is the one that changes the architecture.**
If the lowest rung fails, there is no `S` to bisect from, so the ladder continues *downward* at
2 s and 1 s. If 1 s also fails, the recorded answer is **"the `stop` hook may not block at
all"** — with the terminal mode and the observed `t` — and the consequence is stated rather than
softened: Cursor has no viable waker adapter and degrades to the FR-5.3 pull floor, which is
FR-5.2's stated fallback and is exactly the outcome §10's rationale says this stage exists to
discover before P1.

**Phase 2 — bisection.** Probe `D = round((S+F)/2)`, one run, and replace `S` or `F` by the
outcome. Repeat until `F - S ≤ max(5 s, 0.10 × F)`. From a `[300, 600]` bracket this is three
to four runs.

**Phase 3 — confirmation.** Three runs at `S` and three at `F`. (Where phase 1 reached the
ceiling, `S` is 600 s and there is no `F`; the three ceiling runs are the whole of phase 3.)
The result is accepted only
when `S` survives 3 of 3 and `F` fails 3 of 3. Any mixed endpoint means the limit is **not
deterministic**, which is reported as such — the bracket, plus the per-endpoint outcome counts
— rather than averaged into a number the design would then trust. Three repetitions and not
thirty because the number feeds a timeout choice with a safety margin, not a statistical claim:
what the design needs is a conservative floor and an order of magnitude.

**Stopping rule.** The measurement ends at the first of: phase 3 confirms — at a bisected `S`,
at the 600 s ceiling, or at the "may not block at all" floor; or the budget of **25 runs or
4 hours of wall clock** is exhausted. In the last case
the record states the bracket reached, every run performed, and why it stopped — which is
exactly the shape AC-21 requires of a "could not determine".

**Reported form.** Largest duration surviving 3 of 3; smallest failing 3 of 3; the bracket;
terminal mode (killed, abandoned, or both); signal or "none observable (Windows)"; resolution;
run count including void runs; Cursor version; OS and version; network (loopback).

**What the number is for, stated but not acted on here.** §6 defaults the long-poll timeout to
30 s. If `S` lands near or below 60 s, that default is challenged, and if it lands in the
hundreds of seconds it is comfortably safe. Recording the implication is in scope; changing the
requirement is not — that belongs to `feature-006` and `feature-007`, which is why the STATE
row for `feature-007` already says it is shaped by this number.

#### Test 4 — two machines on the LAN (AC-21 question 4)

Machine **A** runs the stub bound to `0.0.0.0` — so the local waiter reaches it on loopback and
machine B reaches it on the LAN address, from one process — and hosts the **Claude Code**
session. Machine **B** hosts the **Cursor** session, whose hook holds its block across
the network. This is the shape of the target case in REQUIREMENTS §3 — Cursor on one machine,
Claude Code on another — and it puts the LAN hop under the host with the weaker route, where a
router, NIC or OS idle-connection timeout would bite first.

Procedure: arm both sessions; each calls `GET /wait?after=<N>&run=<run>` with an `N` chosen so
both are armed before the arrival; at `t0+N` both are released by the same stub. Each woken turn
performs its act, and machine B's act crosses the LAN back to the stub.

**Pass** when the stub's request log holds, in order, both waits, the single arrival, and both
acts, with machine B's act arriving from B's address. The log is one file on one machine, so the
ordering is unambiguous and no clock synchronisation between the machines is required — the
reason the stub, and not the sessions, holds the authoritative log.

Test 4 also carries **one confirmation run at `S`** over the LAN. If the block that survived on
loopback does not survive across the network, the usable budget over LAN is smaller than the
number test 3 produced, and both figures are recorded.

**What test 4 does not prove, stated plainly.** It proves that a message crossing the LAN wakes
a session on the far machine and that the woken turn can reach the other machine's service. It
does **not** prove node-to-node federation, peer discovery, or store-and-forward — those are
FR-6 and `feature-009` at stage P3, and no line of this spike touches them.

### External Integrations

The only integration is the LAN hop in test 4, and it is deliberately as thin as it can be.

| Concern | Decision |
|---|---|
| Transport | Plain HTTP/1.1 over TCP. No TLS: REQUIREMENTS §4 has no authentication anywhere in the product and §8 makes the network the security boundary; adding TLS here would test a property the product does not have |
| Bind | `127.0.0.1` by default; `0.0.0.0` **only** for test 4, and only for as long as that test runs |
| Port | `--port`, **default `8811`**, recorded in the apparatus. **AID does have a fixed port to avoid: `8787`**, the dashboard default in `bin/aid` and `bin/aid.ps1`. `8799` is also excluded — `.aid/knowledge/infrastructure.md` documents the maintainer's own local command as `aid dashboard start node --port 8799`, on the very machine this spike runs on, and it is used by the UI test harness besides; a stub that silently squats it would surface as a mysterious dashboard outage rather than as a spike error. `8811` collides with neither, nor with any other port this repository names. The stub **fails loudly on a bound port** — **exit `3`**, the documented code for a bind or connection failure (§ Exit Codes), with the port in the message — rather than falling back to another, so a collision is a stopped run, not a run measured against somebody else's server. The operator confirms the port is free on both machines and records it |
| Firewall | An inbound rule on machine A for that port, added for the test and removed after. Whether one was required is recorded — on Windows it usually is, and a reader repeating this will otherwise lose an hour to a silent block |
| Discovery | None. Machine A's address is passed to machine B on the command line. Discovery is FR-6.1 and stage P3 — and FR-6.1 is stated as an **outcome**, not as mDNS, since 2026-08-10; the spike's hand-passed address is therefore not a stand-in for any particular mechanism |
| Precedent guarded | The shipped dashboard server binds `127.0.0.1` and its `--remote` flag is a clear-fail stub (`.aid/knowledge/tech-debt.md` § Security Observations). The stub's non-loopback bind sets **no** precedent for the node: `feature-003` decides the node's bind policy on its own evidence |

### Telemetry & Tracking

The measurement is only as good as its log, so the log has a schema.

**One append-only NDJSON file per run**, written by both `spike_hook.py` and `spike_probe.py`,
plus one per stub process. One JSON object per line, flushed on write.

**Where it lives, and what it is called.** All three scripts resolve `--log` the same way, and
the convention is stated here once because three flags defaulting to "the same file" is
meaningless unless something computes it:

```
throwaway/logs/<run>.ndjson       # per-run log: spike_hook.py and spike_probe.py
throwaway/logs/stub-<port>.ndjson # per-stub-process log: spike_stub_node.py
```

relative to the `throwaway/` directory named under § Layers & Components, with `logs/` created
on first write. `<run>` is the run id already carried on every line. So `--log` on
`spike_hook.py` and `spike_probe.py` defaults to `throwaway/logs/<run>.ndjson` for the `--run`
they were given — which is what makes the probe and the hook meet in the same file without the
operator having to pass matching paths to both. `--log` remains available on all three to
override it; nothing in the protocol depends on the override.

| Field | Meaning |
|---|---|
| `ts_wall` | ISO-8601 UTC, for cross-machine and cross-tool correlation only |
| `t_mono` | Seconds since that process's start, from `time.monotonic()` — the only field elapsed figures are computed from |
| `run` | The run id, on every line from every process |
| `proc` | `stub`, `hook`, or `probe` |
| `machine` | `A` or `B` |
| `pid` | The writing process's pid; the hook's `start` line is where the probe learns it |
| `event` | `start`, `beat`, `request`, `respond`, `act`, `end`, `killed`, `abandoned`, `probe`, `void`, `error` |
| `d` | The run's target block duration, on hook lines |
| `seq` | The stub's per-process request counter, on `request` and `respond` lines only. It is what makes two events inside the same millisecond orderable, and what makes a restarted stub visible — the counter goes backwards instead of the log showing a silent gap |
| `alive` | Boolean, on `probe` lines only |
| `signal` | Signal number, on `killed` lines from POSIX only |
| `note` | Free text; carries the void reason on `void` lines |

**Nothing else is instrumented.** No metrics endpoint, no aggregation, no summary file — the
answer record is written by hand from these logs, and a tool that summarised them would be a
tool worth keeping, which is the failure mode this stage is guarding against.

### Recording the Answers

**The record is the deliverable** (§10: "Its only deliverable is the answers"). It is written
to
**`.aid/works/work-007-agent-chat/features/feature-001-wake-feasibility-spike/FINDINGS.md`** —
beside this SPEC, outside `throwaway/`, so that deleting the code does not delete the result.

Its shape:

1. **Apparatus block** — for each host: tool and version, OS and version, machine role, Python
   version, the hook configuration file actually used, the continuation payload schema copied
   verbatim from the vendor page, the stub's port and bind, and whether a firewall rule was
   needed. This block is why a later reader can tell whether the answer still applies after a
   host update.
2. **The four answers, one row each:** question, verdict (`Pass`, `Fail`, or `Inconclusive`),
   the answer itself, runs performed (including void runs), the log excerpt that evidences it,
   and the date. Question 3's answer is the reported form specified in test 3 — a number with a
   bracket, a terminal mode, and a resolution, never a bare figure.
3. **A "what was tried" paragraph, mandatory for every `Inconclusive` row** — the arrangements
   attempted, the outcome of each, and why the question could not be closed. AC-21 admits
   "we could not determine it" **only** in this form, so a row is not complete without it. An
   empty paragraph is a failed criterion, not a formatting lapse.
4. **Order of execution**, since test 2 may depend on test 3's result (see test 2).
5. **The implication for the design**, recorded and not acted upon: what the measured budget
   means for the §6 long-poll default, addressed to `feature-006` and `feature-007`.

#### Disposal and the no-carry-forward check

When the four answers are transcribed and the record is complete, `throwaway/` is deleted and
the `.gitignore` line goes with it. The feature's last acceptance criterion — no code carried
forward — is then checked three ways, because the obvious check is vacuous:

- **`git ls-files` proves nothing here** and must not be cited as if it did: the work folder is
  untracked, so a path-based search over tracked files returns empty whether or not the spike
  ever existed. Stating this is part of the check.
- **The directory is absent from disk** at the moment P1's first task starts.
- **The names are absent from the repository.** A search of tracked files for `spike_stub_node`,
  `spike_hook`, and `spike_probe` returns nothing. This one is not vacuous — it is what catches
  a file copy-pasted into `canonical/`, `dashboard/` or `tests/`, which is the realistic way P0
  code survives.
- **No P1 task cites the path.** No task DETAIL under this work references
  `feature-001-wake-feasibility-spike/throwaway/`. This catches promotion by reference, which
  the name search would miss.

#### Promotion to the Knowledge Base (stakeholder decision Q22)

AC-21 requires the answers to be written down and does not say where they live **after** this
work ships. `FINDINGS.md` satisfies the criterion and serves every consumer inside this work,
but the work folder is prunable by rule — and the measured Cursor number is a durable fact
about a third-party harness, not pipeline state. `feature-007`'s adapter design turns on it,
and re-measuring costs hours.

**Decided: the results are promoted to `.aid/knowledge/external-sources.md` when the spike
completes.** That document already draws the first-hand-versus-cited distinction for these
exact hosts, so the entries land beside the claims they settle:

| Promoted | Recorded as |
|---|---|
| The Cursor `stop`-hook blocking limit | First-hand measurement: the number, its confidence bound, the method in one sentence, the host version, the OS, and the date |
| Whether an idle Claude Code session acts with no human action | First-hand result. That document has **no Claude Code row** — deliberately: its § Host agent-tool documentation preamble explains that Claude Code's harness is exposed at runtime rather than published, and instructs the reader to "treat any Claude Code harness claim as unsourced until a published reference exists". The spike produces the project's first **measured** claim about it, so the promotion amends that preamble rather than filling a table row, and the distinction it draws — first-hand versus citable — is preserved, not erased |
| Whether the exchange held across the LAN | One line, with the arrangement tested |

The **full run record stays in `FINDINGS.md`** and is pruned with the folder. What is promoted
is the conclusion and enough method to trust or re-derive it — not the raw ladder.

**One hard constraint on the KB entry.** It states the measurement and its method **only**:
no work id, no work-folder path, no "measured by work-007" — in prose, table or frontmatter.
The project's context file forbids naming a work in the Knowledge Base, for the exact reason
that applies here: the folder this measurement came from will not exist, so a citation to it
is a dangling pointer by design. Cite the host, the version and the date instead.

The promotion happens at execute time, when the numbers exist. This specification records the
obligation; it does not pre-write the entry.
