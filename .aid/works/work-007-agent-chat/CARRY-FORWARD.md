# Carry-Forward — Agent Chat Channel

> **What this is.** The handoff from this work to its successor, written because the decision
> was taken to re-baseline the pipeline rather than migrate this work's state. It exists to
> make the restart a **transfer of decisions**, not a re-derivation of them.
>
> **What this is not.** Not a Knowledge Base document (it names a work, which the KB may not),
> and not durable. It is transient handoff state and is pruned with this folder once the
> successor has absorbed it. Nothing permanent may cite it — anything that must outlive the
> handoff is listed under [Already durable](#already-durable) or is promoted by step 1 below.

---

## Why re-baseline at all

Three weeks, zero lines of product code, and two structural blockers that are not this work's
fault and not this work's to fix:

- **v3.0.0 retired the artifact set this work is built out of** — per-feature `SPEC.md` and
  per-delivery `BLUEPRINT.md` — with its own release note observing that "an in-flight work
  finds them gone". The features were folded into `REQUIREMENTS.md § 11` in response, and that
  half is done and verified.
- **`W7-3`** — the `STATE.md` → `STATE.yml` conversion drops every block the YAML key set does
  not name. Measured on this file on 2026-09-01: **113,584 bytes in, 65,608 out** — 47,976
  bytes, 42%, gone, and what goes includes the D1–D14 decision registry. Fixing it is a
  schema decision for the repository, not for a feature work, and this work should not
  wait on it.

A successor created by current tooling writes `STATE.yml` natively, so it never meets either
problem. **That is the entire case for restarting**, and it is worth stating its limits
plainly. It removes *existing* debt rather than protecting against future churn: if another
major release retires an artifact mid-flight, a fresh work is exactly as exposed. It also
does not escape `SY-6` — several skills' routing prose still names the retired `STATE.md`
and its markdown sections, `/aid-describe`'s included (see step 3).

**What is emphatically not the reason:** the requirements being wrong. They are the asset.
§1–§3 and §6 were never reopened by the runtime reset, and coverage across §5/§9/§11 was
re-verified mechanically on 2026-09-01 — 22 live criteria each owned by exactly one feature,
agreeing with §10 stage for stage, and all 40 §5 sub-requirements mapped.

---

## What moves

### 1. D1–D14 → `.aid/knowledge/decisions.md` (do this first, and separately)

Fourteen architectural decisions, each recorded with **the alternative it rejected and why**.
This is the single most valuable artifact the work produced and the one a new prompt is least
likely to reproduce: a prompt states conclusions, and what makes these useful is the rejected
branch attached to each.

Source: `STATE.md` § `Cross-phase Q&A` → `### Decisions carried from the originating interview`.

| # | Decision (abbreviated — carry the full row) |
|---|---|
| D1 | MCP cannot wake an idle session — it is pull-only, invoked *by* an agent *during* a turn |
| D2 | Local node per machine, deployed by the CLI — not a hosted broker |
| D3 | Wake = in-tool subscriber; the host's own background-completion machinery produces the turn |
| D4 | Pull floor retained — a session with no subscriber reads its inbox at its own turn boundaries |
| D5 | No spawning or resumption in the product |
| D6 | Address by stable name; session id internal |
| D7 | Async request/reply via `correlation_id`; no blocking API |
| D8 | Durable queue, at-least-once, per-subscriber cursor, explicit ack |
| D9 | Reject on overflow (the oversized-payload half was later overridden — no size limit) |
| D10 | All limits configurable via the CLI |
| D11 | CLI is the complete admin interface; the privilege boundary is absolute |
| D12 | One shared core, no second implementation (the MCP-façade half is withdrawn) |
| D13 | v1 = same machine + trusted LAN (the PSK and mDNS elements are both overridden) |
| D14 | Risk-first priority — the P0 spike before any build |

Three carry **override annotations that must travel with them** — D9, D12 and D13 each had an
element overturned by a later decision, and the row records both. Copying the conclusion without
the override would reinstate a rejected design.

**Why first, and why separate:** these are architectural decisions about the project, so
`decisions.md` is where they belong under the current model regardless of this restart — and
promoting them is what removes the largest part of `W7-3`'s subject. Do it through
`/aid-update-kb` (it gates on human confirmation) and **strip every work reference** on the way
in: the KB may contain no work id and no work-folder path.

### 2. `REQUIREMENTS.md` → the seed for the successor

The folded `REQUIREMENTS.md` in this folder (3,294 lines, §1–§11) is the best single statement of
everything decided. **Seed the successor from this file, not from memory.** A prompt written from
recall will silently drop decisions and re-litigate them later, which is the specific failure this
document exists to prevent.

Section-by-section disposition:

| Section | Carry | Note |
|---|---|---|
| §1 Objective | **Verbatim** | Never reopened. Already reflects the withdrawn MCP façade |
| §2 Problem Statement | **Verbatim** | The turn-boundary analysis and the three-recipient-state table hold on any runtime |
| §3 Users & Stakeholders | **Verbatim** | Five hosts with honest per-host confidence, including "Codex — not researched at all" |
| §4 Scope | **Re-derive from the current text** | Correct today, but its In/Out lists carry the scars of the reset; restate cleanly |
| §5 Functional Requirements | **Carry FR-0..FR-7; drop FR-8** | 40 sub-requirements, all mapped. FR-8 is withdrawn and must not be renumbered into existence |
| §6 Non-Functional | **Verbatim** | Survived the reset intact by being specified at the right altitude — properties, not mechanisms. See the limits table below |
| §7 Constraints | **Carry, minus the reset narrative** | The agent-surface bullet's *conclusion* is right; its long "here is what we reversed" passage is history |
| §8 Assumptions | **Carry the findings, drop the archaeology** | The host research and the store contract are the value; the "closed by deletion" notes are not |
| §9 Acceptance Criteria | **Carry all 22 live, renumber to AC-1..AC-22** | A fresh work has no citation history to protect, so the gaps left by AC-8/14/20/24/25 can close |
| §10 Priority | **Verbatim** | P0–P4, risk-first. Drop the struck P0b row |
| §11 Features | **Carry 001, 004, 005, 007, 008, 010, 011, 012; re-specify 003, 006, 009** | See below |

**§6 limits, carried as defaults rather than constants** (all configurable via the CLI, per D10):
message TTL **24 h** (eligibility, not hard expiry); max unread depth per member per chat
**1,000**; overflow **rejects the new send** with an explicit error; max payload size **none**;
stale-session threshold **30 min** (a display state, releases nothing); reap threshold **24 h**
(drops the member's claim on the trim point); long-poll timeout **30 s**.

### 3. The empirical findings — these are measurements, not prose

Re-deriving these costs hours of machine and human time; they are the cheapest thing to carry
and the most expensive to lose.

- **The `node:sqlite` store contract, verified by execution** on Node v24.19.0, v26.7.0 and
  v22.14.0: WAL engages and persists across reopen; `synchronous=FULL` sticks; a partial unique
  index rejects a duplicate idempotency key while permitting many NULLs; `ON DELETE CASCADE`
  fires; a reader held a transaction open 3 s while a writer committed 49 sends (slowest 3 ms);
  `SIGKILL` mid-transaction left the committed rows, discarded the uncommitted one, and passed
  `integrity_check`.
- **Two store findings that are inputs to Specify, not trivia:** the default `busy_timeout` is
  **0**, so a non-zero value is *required* rather than advisable; and there is **no
  `db.transaction()` helper**, so the wrapper is hand-written.
- **The effective Node floor is `22.13.0`, not `22`.** `node:sqlite` was added in v22.5.0 behind
  `--experimental-sqlite` and the flag requirement was removed in v22.13.0 (`nodejs.org/api/sqlite.html`,
  accessed 2026-09-01). The repository's adopter floor is `>=22`, which admits 22.0–22.4 where the
  module does not exist and 22.5–22.12 where it is flagged. It also emits an `ExperimentalWarning`
  on stderr on 22.x/23.x. **Carry this as an open question, not as a settled floor.**
- **Discovery cannot be fixed to one mechanism.** Of eleven comparable local-first tools surveyed,
  only two make mDNS primary and **all eleven** ship a manual backstop; WSL2 host-to-distro
  multicast is an open upstream defect, and AP client isolation, VLAN splits and macOS 15+ all
  defeat or gate broadcast. Hence FR-6.1 as an *outcome* with a guaranteed path plus best-effort
  zero-configuration above it.

### 4. `feature-001`'s spike protocol — carry it whole

Roughly 570 lines under `### Feature 001`, graded **A+** over five review cycles, and the only
feature specification in this work
that is both complete and unaffected by the runtime reset. It is an executable experiment design:
a single-endpoint throwaway stub, two host arrangements, a four-test measurement protocol
(ladder → bisection → 3-of-3 confirmation, with *killed* and *abandoned* defined separately and a
stated stopping rule), an NDJSON run-log schema, and the answer record's shape.

Two path fix-ups already applied and worth preserving: `throwaway/` and `FINDINGS.md` sit at the
**work root** (features have no folders now), and the promotion of the measured Cursor
`stop`-hook blocking limit into `.aid/knowledge/external-sources.md` when the spike completes
(stakeholder decision Q22) is stated with its no-work-id constraint.

### 5. Four unanswered questions

Carry these forward as open, not as decided:

| Was | Question | Status |
|---|---|---|
| Q23 | One-hop versus two-hop LAN coverage in the P0 spike — a third machine buys a symmetric result at real setup cost for a stage whose output is thrown away | Recommendation on file: accept one-hop |
| Q27 | Two premises the reset asserted as settled that the repository has not acted on — the PyPI channel is still live with `requires-python = ">=3.8"` on disk, and the dashboard's Node/Python twin still exists. **Neither changes a decision**; both were stated as fact and are not | Restate as premises |
| Q28 | What Node floor the node declares, and whether the `ExperimentalWarning` is acceptable on an operator-started service or must be suppressed | Evidence gathered (above); decision open |
| — | **`aid chat start` idempotence:** with `deploy` deleted, no verb holds the "safe to run twice" property. Either `start` absorbs it (already-running becomes success) or it keeps a distinct exit code | Named in FR-1.1; nothing else depends on it |

---

## What is dropped, deliberately

Each of these is a decision, not an omission — recorded so the successor does not go looking.

- **The process state.** 28 Q&A entries, 13 review-history rows, 9 lifecycle
  transitions, 14 cross-reference cycle records. Its *outputs* are carried above; the record of
  how they were reached is history, and git holds this file.
- **`feature-003`'s Technical Specification** (~1,100 lines, grade **D**, twelve findings open,
  two HIGH). It rests on four premises the runtime reset contradicts — stdlib `sqlite3`, a
  separate `chat-node/` distributable with its own `pyproject.toml`, a Python prerequisite, and
  `aid chat deploy` idempotence. **Two of its findings must be carried as constraints even though
  the document is not**, because they are defects a re-specification would otherwise reintroduce:
  exit code `5` is already taken by an existing command, and `id INTEGER PRIMARY KEY` **without**
  `AUTOINCREMENT` is a rowid alias, so SQLite reuses a reaped member's id and a later member
  silently inherits its predecessor's messages.
- **`feature-006` and `feature-009`'s descriptions as written.** 006 carries a stale FR-7.4
  carve-out. 009's Description and one scenario still describe discovery as zero-configuration
  announcement, which FR-6.1 and AC-3 no longer support — AC-3 says outright that it must be
  satisfiable by the guaranteed path alone.
- **The `##### BDD Scenarios` blocks**, as *criteria*. They were the retired per-feature
  acceptance-criteria lists and were preserved through the fold rather than deleted, because the
  cross-reference pass wrote many of them to cover an FR clause no §9 criterion reaches. In the
  successor they are **inputs to `/aid-specify`**, not a schema element to recreate.
- **All withdrawn scope**, and it must stay withdrawn: FR-8.1–8.7, AC-20/24/25, stage P0b,
  `feature-002` (repository Python floor), and the MCP façade with its `aid chat deploy` fetch
  path, `--from-bundle`, `--version` and exit codes 3/4/9.

---

## Already durable

Survives pruning with no action, and must not be re-derived:

- **`.aid/knowledge/external-sources.md`** — nine vendor sources on host harness behaviour
  (Cursor, Copilot CLI and Antigravity checked against published documentation; Claude Code
  explicitly marked first-hand-not-cited; Codex marked unresearched), plus the load-bearing
  conclusion that MCP is a **pull** surface on these hosts and cannot start a turn in an idle
  session. Preserved through the v3.0.0 merge.
- **`.aid/knowledge/tech-debt.md`** — `M5` (the untested PyPI Python floor, re-verified against
  the merged tree), `W7-1` (the `canonical-tests` CI lane with no `setup-python`), `W7-2`
  (closed), `W7-3` (open, P1).

---

## Order of operations

1. **Promote D1–D14 to `decisions.md`** via `/aid-update-kb`, stripping every work reference.
   Do this before anything else: it is the highest-value artifact, it belongs there under the
   current model regardless, and it removes the largest part of `W7-3`'s subject.
2. **Open `work-024-agent-chat`.** 024 is the lowest free number: 001, 003, 004, 005, 007–013,
   017 and 019–023 have all been used, counting the three that live only in `.gitignore`
   (004, 009, 023) and would otherwise look free. Current tooling writes `STATE.yml`
   natively, so there is nothing to migrate.
3. **Seed §1–§10 from this work's `REQUIREMENTS.md`** per the disposition table, then run
   `/aid-describe`. Its `CONTINUE` state works only sections marked `Pending` or `Partial`, so
   the questions it asks are the ones genuinely open (§4, §7, §8's floor, Q23/Q27/Q28 and the
   `start` idempotence sub-decision) — provided the seeded section states say so.

   > **Expect one snag here, and it is not a migration problem.** `aid-describe/SKILL.md`'s
   > detection logic still reads the retired shape — "Check for `STATE.md` … look for the
   > `## Interview State` section", and `**Status:** Pending` for the Q&A probe. Read
   > literally against a `STATE.yml` work it finds no `STATE.md` and routes to `FIRST-RUN`,
   > which would re-interview from zero. **The blast radius is small because the target state
   > disagrees with the router:** `references/state-first-run.md` opens by saying it "runs only
   > when STATE.yml (with its `interview` key) does not exist", so FIRST-RUN self-corrects into
   > an update rather than a rewrite. Still — check the routing decision before letting it
   > proceed. This is tech-debt `SY-6`, and it is the honest cost of restarting: a fresh work
   > escapes the *migration* debt but not the stale-prose debt.
4. **Renumber §9 to AC-1..AC-22.** A fresh work has no citation history to protect, so the gaps
   left by the deleted and withdrawn criteria should close rather than be preserved as struck rows.
5. **`/aid-define`** — expect the same eleven features. Carry 001's specification in whole;
   003, 006 and 009 start from their criteria.
6. **`/aid-specify` on 003 first.** It is the keystone, it owns the store schema, and
   `feature-005` cannot proceed until the `AUTOINCREMENT` defect above is closed in it.
7. **Cancel this work.** Set `lifecycle: Canceled` in its `STATE.md` with a one-line reason and
   a pointer to its successor, then prune the folder once the successor has absorbed this file.

**Do not re-run the fourteen cross-reference cycles as a target.** Their value was in the 93
defects they found, and the grade trajectory (D- → E+ → D → … → A+) is the honest record of how
much of that was self-inflicted — a fix applied to the line a finding named rather than the class
it belonged to, twice re-opening closed findings. Two structural changes ended it and are the
transferable lesson: **replace enumerated checks with property checks** (AC-20 went from a list of
six files to a meaning-based search of every tracked file, after being wrong six times), and
**make each reviewer re-verify its own prior evidence** instead of carrying it forward.
