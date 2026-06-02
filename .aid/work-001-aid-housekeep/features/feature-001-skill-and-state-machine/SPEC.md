# Skill Scaffold & State Machine

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-02 | Feature identified from REQUIREMENTS.md §5 (FR5–FR7), §7 (C1, C3) | /aid-interview |
| 2026-06-02 | Technical Specification authored (state machine, run-state contract, resume detection, VC boundary, distribution, tests) | /aid-specify |
| 2026-06-02 | Added incremental-delivery stub-no-op contract (skeleton stages whose feature isn't yet built record `skipped` + CHAIN to DONE) — enables standalone incremental deliveries per /aid-plan | /aid-plan (review) |
| 2026-06-02 | Simplification: dropped the dedicated `parse-args.sh` script + its `test-housekeep-parse-args.sh` suite (over-engineering — no AID skill ships a CLI arg-parser). Arguments are now handled in `SKILL.md` `## Arguments` + State Detection prose (no dedicated arg-parse script), consistent with the other five skills. The `--grade` / `--cleanup-only` / no-args grammar moves into the SKILL.md router. | /aid-plan (restructure) |

## Source

- REQUIREMENTS.md §5 FR5 (strict sequencing, hard gates, halt-and-resume), FR6 (optional
  on-demand skill), FR7 (invocation modes)
- REQUIREMENTS.md §7 C1 (ordering mandatory), C3 (auto-commit on branch; never push)
- REQUIREMENTS.md §6 NFR4 (pipeline consistency)
- REQUIREMENTS.md §9 AC9 (halt & resume), AC10 (`--cleanup-only`), AC11 (distribution)

## Description

The skeleton of the `/aid-housekeep` skill that every other feature hangs on: a thin-router
`SKILL.md` driving a re-entrant state machine over the three gated jobs
(`KB-DELTA → SUMMARY-DELTA → CLEANUP`), consistent with the other `/aid-*` skills. It owns
the strict ordering and hard gates (a stage may not start until the previous stage reached
its passing/approved state), the halt-and-resume behavior (a stalled gate halts cleanly with
a "resume here" message; re-running picks up at the stalled stage using the filesystem as
the source of truth), argument routing (default = full gated sequence; `--cleanup-only` jumps
straight to cleanup), and the version-control policy: work happens on an `aid/housekeep-*`
branch (created if needed, never operating on `master` directly) with one commit per stage,
and the skill never pushes. Because it is authored in `canonical/`, it renders into all
install profiles like the other skills; it is absent from the mandatory pipeline flow.

## User Stories

- As an AID maintainer, I want a single optional command that runs the three housekeeping
  jobs in a safe, fixed order so that I can reconcile drift without remembering the steps.
- As an AID maintainer, I want a stalled run to resume where it left off so that I don't
  redo completed stages after fixing a gate.
- As an AID maintainer, I want `--cleanup-only` so that I can sweep cruft quickly when the
  KB is already current.

## Priority

Must

## Acceptance Criteria

- [ ] **AC9** — Given a stalled gate (declined KB approval, or summary gate below minimum),
  when the stage cannot pass, then the skill halts with a resume message and a re-run
  resumes at the stalled stage (not job 1).
- [ ] **AC10** — Given `--cleanup-only`, when the skill runs, then it jumps straight to the
  cleanup stage, skipping KB and summary.
- [ ] **AC11** — Given the skill is authored in `canonical/`, when the renderer runs, then
  `/aid-housekeep` appears in all install profiles and is absent from the mandatory flow.
- [ ] **C1/C3** — Given a run, when any stage produces changes, then they are committed on an
  `aid/housekeep-*` branch (one commit per stage) and the skill never pushes nor commits to
  `master`.
- [ ] **NFR4** — Given the skill runs, then `SKILL.md` is a thin-router with state-entry
  banners + "you are here" map consistent with the other `/aid-*` skills, and the new
  `tests/canonical/` suites for housekeep's deterministic logic are wired into `run-all.sh`.
  (The suites themselves are authored with the features that own the logic — feature-002
  detection + path→doc map, feature-004 cleanup classification — per NFR5.)

---

## Technical Specification

> Scope note: this feature delivers the **skeleton** — the `/aid-housekeep` thin-router
> `SKILL.md`, its state-machine wiring, the run-state contract, the gate/commit/resume
> machinery, argument routing, and distribution. The **stage LOGIC** (KB delta detection +
> path→doc mapping, summary reconciliation, cleanup classification) is owned by
> features 002 / 003 / 004, which plug into the contracts defined here. Where a state's
> body is owned by another feature, this spec defines the *interface* (what the state must
> read/write, when it passes its gate, what it commits) and marks the body
> "owned by feature-00X".

This skill mirrors the established thin-router + state-machine pattern of
`canonical/skills/aid-discover/SKILL.md` and `canonical/skills/aid-summarize/SKILL.md`:
a `SKILL.md` with `## State Detection`, a `## Dispatch` table, per-state `references/state-*.md`
bodies, state-entry banners with a "you are here" map, and advance routing per
`canonical/templates/state-machine-chaining.md`.

### Data Model

**N/A as a relational schema** — AID ships no database (`.aid/knowledge/schemas.md` §
"There is NO relational database in AID"). The real "data model" here is the **run-state**
that makes halt-and-resume possible. It is defined in *Data/State Contracts* below.

### Data/State Contracts (the real "data model")

This feature introduces persistent housekeep run-state and a branch-naming contract. All
of it lives on the **filesystem**, which is the sole source of truth for resume detection
(mirroring the `⚠️ FILESYSTEM IS THE ONLY SOURCE OF TRUTH` rule in
`canonical/skills/aid-discover/SKILL.md § State Detection` and
`canonical/skills/aid-summarize/SKILL.md § State Detection`).

#### C-1. Where run-state lives — decision

**Decision:** persist housekeep run-state in a new `## Housekeep Status` **section of the
work-area `STATE.md`** (`.aid/work-NNN-*/STATE.md`), authored as a key-value block in the
exact `**Field:** value` shape used by `## Knowledge Summary Status` in
`.aid/knowledge/STATE.md` (one `**Field:**` per line, grep-recoverable).

**Rationale / alternatives considered:**
- *Chosen:* reuse the existing work-area `STATE.md` (`canonical/templates/work-state-template.md`).
  It is already the per-work process-state hub ("the single state file for this work")
  and already carries sibling status sections; adding one more section is consistent and
  needs no new file conventions, no new gitignore rules, and is naturally swept by the
  cleanup stage only when the whole merged work folder goes.
- *Rejected:* a free-standing `.aid/.housekeep-state` file — it would itself become exactly
  the kind of stray artifact FR4 hunts (REQUIREMENTS.md D2), and would need its own
  lifecycle rules.
- *Rejected:* storing run-state in `.aid/knowledge/STATE.md` — that file is the Discovery
  area's hub; housekeep is a *run* over the repo, not a KB doc, so its transient
  run-state does not belong there. (Housekeep still *reads* `.aid/knowledge/STATE.md` for
  the KB approval anchor and *writes* the approval-baseline field there — see C-3.)

> **Open assumption for the reviewer:** the work-area `STATE.md` template
> (`canonical/templates/work-state-template.md`) does not yet contain a `## Housekeep Status`
> section. Adding the section (template + this skill's writer) is in scope for this feature.
> If the reviewer prefers the run-state to live in a dedicated file, that is the one
> structural decision worth re-litigating; everything else hangs off "wherever the
> `## Housekeep Status` block is".

#### C-2. `## Housekeep Status` fields

| Field | Values | Set by | Read by |
|-------|--------|--------|---------|
| `**State:**` | `KB-DELTA` \| `SUMMARY-DELTA` \| `CLEANUP` \| `DONE` | each stage on entry | State Detection (resume target) |
| `**Stage Status:**` | `running` \| `stalled` \| `passed` \| `skipped` | each stage on exit | State Detection (gate check) |
| `**Branch:**` | `aid/housekeep-<slug>` | KB-DELTA entry (branch create) | all stages (commit target) |
| `**Mode:**` | `full` \| `cleanup-only` | entry router | State Detection |
| `**Stall Reason:**` | free text (e.g. `KB approval declined`, `summary grade B < A`) | the stalling stage | resume banner |
| `**Last Run:**` | `YYYY-MM-DDTHH:MM:SSZ` | each stage | transparency |
| `**KB Stage:**` | `passed` \| `skipped` \| `stalled` \| `—` | feature-002 | gate before SUMMARY-DELTA |
| `**Summary Stage:**` | `passed` \| `skipped` \| `stalled` \| `—` | feature-003 | gate before CLEANUP |
| `**Cleanup Stage:**` | `passed` \| `—` | feature-004 | DONE |

The three `**X Stage:**` rows are the **hard-gate ledger** (C1): a downstream stage may
only start when the upstream stage's row reads `passed` or `skipped`. They are written by
the stage-owning features (002/003/004); this feature defines the field names and the
gate-check semantics that read them.

#### C-3. KB approval baseline (cross-feature dependency — NOT this feature's writer)

feature-002 introduces `**Approved-At-Commit:**` in `.aid/knowledge/STATE.md` (REQUIREMENTS.md
FR1 / D1) — the `master` SHA recorded at KB approval, used to compute the delta. **This
feature does not read or write it.** It is named here only so 002 has a defined home: the
existing `**User Approved:**` / `**Last KB Review:**` lines at the top of
`.aid/knowledge/STATE.md` (see `### Discovery State` header block) are the sibling fields it
joins. The skeleton's KB-DELTA state simply dispatches into feature-002's body and reads back
its `**KB Stage:**` result.

#### C-4. Branch-naming contract

`aid/housekeep-<slug>` where `<slug>` is a short kebab token (e.g. `aid/housekeep-2026-06-02`
or `aid/housekeep-postmerge`). Created off the current `master` HEAD if the working branch is
`master`; if already on a non-`master` branch whose name starts with `aid/housekeep-`, reuse
it (resume case). This matches the observed convention in the repo (e.g.
`.aid/knowledge/STATE.md` records work done on `aid/kb-refresh-work-001`) and the project rule
"never commit to `master` directly — branch + PR always" (REQUIREMENTS.md C3).

### Feature Flow (the state machine)

Three gated states, plus terminal `DONE`, consistent with the sibling skills:

```
                 (default: full)
PREFLIGHT ─► KB-DELTA ──gate──► SUMMARY-DELTA ──gate──► CLEANUP ─► DONE
    │            ▲ feat-002        ▲ feat-003            ▲ feat-004
    │  (--cleanup-only)                                  │
    └────────────────────────────────────────────────► CLEANUP
```

- **PREFLIGHT** (this feature): synchronous gate. Verifies (1) `.aid/` exists and a
  work-area or repo root is present; (2) not in Plan Mode (stages write); (3) git repo is
  present and clean enough to branch. On failure, exit non-zero with an actionable message
  and **create no state** — mirrors `canonical/skills/aid-summarize/references/state-preflight.md`.
- **KB-DELTA** (interface here; body = feature-002): detect delta since last KB approval,
  scope/confirm, dispatch targeted re-discovery via `/aid-discover`, route through its
  REVIEW→APPROVAL gate. On approval → write `**KB Stage:** passed`, commit, CHAIN to
  SUMMARY-DELTA. On no-delta → `**KB Stage:** skipped`, CHAIN. On declined approval or
  offline-permission-denied → `**Stage Status:** stalled` + `**KB Stage:** stalled`, HALT
  with resume banner (PAUSE-FOR-USER-ACTION).
- **SUMMARY-DELTA** (interface here; body = feature-003): delegate to `/aid-summarize`'s
  STALE-CHECK. Regenerate iff stale; pass its two-grade gate; write `**Summary Stage:**
  passed`/`skipped`, commit if regenerated, CHAIN to CLEANUP. Below-minimum grade →
  `stalled`, HALT.
- **CLEANUP** (interface here; body = feature-004): build the tiered checklist, confirm
  per-item, delete (`git rm` for tracked, `rm` for untracked), commit. Write `**Cleanup
  Stage:** passed`, CHAIN to DONE.
- **DONE** (this feature): print closing summary (branch name, per-stage commits, "user
  pushes / opens PR" reminder per C3). HALT.

**Advance types** (per `canonical/templates/state-machine-chaining.md`): inter-stage
transitions on success are **CHAIN** (the gate is a programmatic check on the
`**X Stage:**` field, not a user re-type — same reasoning the doc gives for `/aid-summarize`
chaining PREFLIGHT→…→DONE). A **stalled gate** is **PAUSE-FOR-USER-ACTION** (the user must do
work outside the chat: approve the KB, fix the summary, or grant offline permission), so the
skill prints the resume command and exits. DONE and PREFLIGHT-fail are **HALT**.

#### Incremental-delivery stub no-op (skeleton contract; enables standalone deliveries)

The skeleton ships the **full** PREFLIGHT→KB-DELTA→SUMMARY-DELTA→CLEANUP→DONE machine, but a
stage whose owning feature (003/004) is **not yet implemented in the current delivery** ships
as an **inert no-op stub**: its default `references/state-<stage>.md` body writes
`**<X> Stage:** skipped` + `**Stage Status:** skipped` to `## Housekeep Status` and **CHAINs
straight onward** (to the next stage, ultimately DONE) without doing any work or pausing. A
later delivery replaces the stub body with the feature's real logic. This is what makes an
**incremental delivery standalone-functional**: e.g., when only KB-DELTA is implemented
(delivery-001), KB-DELTA runs for real, then the SUMMARY-DELTA and CLEANUP stubs each record
`skipped` and CHAIN through to DONE, so the run terminates cleanly as a complete KB-refresh
tool. The stub no-op is a skeleton responsibility (this feature), distinct from a *runtime*
`skipped` (e.g. summary already current) which a fully-implemented stage decides for itself.
`--cleanup-only` is only offered once the CLEANUP body is real (its delivery); until then the
flag is absent from the arg grammar.

> Reference patterns to mirror verbatim in tone: the `## Dispatch` advance-routing block and
> the chaining citation line in both `canonical/skills/aid-discover/SKILL.md § Dispatch` and
> `canonical/skills/aid-summarize/SKILL.md § Dispatch`.

### Sequencing & Gates / Halt-Resume (C1, AC9)

**Gate definition.** Between stage N and N+1 the gate is satisfied iff the upstream
`**X Stage:**` field reads `passed` or `skipped`. No stage may begin otherwise (C1). The
gate is a pure read of `## Housekeep Status` — deterministic, scriptable, testable.

**"Passing/approved state" per stage:**
- KB-DELTA passes when feature-002 reaches a fresh `**User Approved:** yes` in
  `.aid/knowledge/STATE.md` (the same APPROVAL marker `/aid-discover` writes), or when no
  delta exists (skipped).
- SUMMARY-DELTA passes when `/aid-summarize` reaches Overall Grade ≥ minimum
  (`bash canonical/scripts/config/read-setting.sh --skill summary --key minimum_grade --default A`),
  or when STALE-CHECK reports `CURRENT_APPROVED` (skipped).
- CLEANUP passes when the user has resolved every checklist item (feature-004).

**Stalled-gate semantics (AC9).** When a stage cannot pass, it writes
`**Stage Status:** stalled`, `**<that>-Stage:** stalled`, and `**Stall Reason:** <why>`,
then the orchestrator prints a **resume banner** and exits (PAUSE-FOR-USER-ACTION):

```
⏸  /aid-housekeep paused at KB-DELTA — KB re-approval declined.
   Fix: re-run /aid-discover to approve, or adjust the refresh scope.
   Resume: re-run /aid-housekeep — it will pick up at KB-DELTA (not job 1).
```

**Resume detection (the re-entry table).** A re-run reads `## Housekeep Status` and resumes
at the first non-`passed`/non-`skipped` stage. This mirrors the disk-driven state tables in
`canonical/skills/aid-discover/SKILL.md § State Detection` (States 1–6) and
`canonical/skills/aid-summarize/SKILL.md § State Detection` (steps 1–8):

| # | Disk condition (read `## Housekeep Status`) | Resume mode |
|---|---------------------------------------------|-------------|
| 1 | No `## Housekeep Status` section (fresh run), no `--cleanup-only` | PREFLIGHT → KB-DELTA |
| 2 | No section, `--cleanup-only` flag | PREFLIGHT → CLEANUP (Mode=cleanup-only) |
| 3 | `**KB Stage:**` is `stalled`/`running`/`—` | resume at **KB-DELTA** |
| 4 | `**KB Stage:**` passed/skipped AND `**Summary Stage:**` stalled/running/`—` | resume at **SUMMARY-DELTA** |
| 5 | KB + Summary passed/skipped AND `**Cleanup Stage:**` not passed | resume at **CLEANUP** |
| 6 | All three passed/skipped AND `**State:** DONE` | report "nothing to resume" (NFR2 idempotent no-op) |

`--cleanup-only` (AC10) sets `**Mode:** cleanup-only` and jumps to CLEANUP, leaving KB/Summary
stage rows `—` (a deliberate cleanup-only run does not violate C1 — REQUIREMENTS.md FR7).

### Layers & Components

AID has no application layers; "components" here are the skill's files
(`.aid/knowledge/module-map.md` describes the skill + canonical-scripts layout this follows).

**Owned by THIS feature:**

- `canonical/skills/aid-housekeep/SKILL.md` — thin-router. Frontmatter shape per
  `canonical/skills/aid-summarize/SKILL.md` lines 1–14 (`name`, folded `description` naming
  the state machine, `allowed-tools`, `argument-hint`). `allowed-tools` must include
  `Agent` (the KB stage dispatches sub-agents via feature-002 → `/aid-discover`), so the set
  matches `canonical/skills/aid-discover/SKILL.md` (`Read, Glob, Grep, Bash, Write, Edit, Agent`).
  Sections: `## Arguments`, `## Dispatch Protocol (L1+L2+L3)`, `## State Detection`
  (the re-entry table above + state-entry banners), `## Dispatch` (table below), and a
  state-machine-chaining citation line. **Argument handling lives in the `## Arguments` table +
  State Detection prose (no dedicated arg-parse script)**, consistent with the other five skills
  — see Invocation / CLI.
- `canonical/skills/aid-housekeep/references/state-preflight.md` — PREFLIGHT body (this feature).
- `canonical/skills/aid-housekeep/references/state-done.md` — DONE body (this feature).
- `canonical/skills/aid-housekeep/references/state-kb-delta.md` — KB-DELTA **router stub +
  interface contract**; the substantive body is authored by feature-002.
- `canonical/skills/aid-housekeep/references/state-summary-delta.md` — SUMMARY-DELTA stub +
  interface; body by feature-003.
- `canonical/skills/aid-housekeep/references/state-cleanup.md` — CLEANUP stub + interface;
  body by feature-004.
- `canonical/scripts/housekeep/housekeep-state.sh` — read/write the `## Housekeep Status`
  block and resolve the resume target (the deterministic State-Detection logic, scriptable
  for testing). Mirrors the role of `canonical/scripts/summarize/stale-check.sh` as a
  state-resolving helper the SKILL.md calls.
- `canonical/scripts/housekeep/branch-commit.sh` — branch-ensure (create `aid/housekeep-*`
  off `master` if needed; never operate on `master`) and per-stage commit helper
  (one commit per stage, never push). Uses `git rev-parse --abbrev-ref HEAD`,
  `git switch -c`, `git add`/`git commit`. **Never** runs `git push`.

> `## Dispatch` table for `SKILL.md` (shape per the sibling skills' Dispatch tables):
>
> | State | Detail | Worker | Advance |
> |-------|--------|--------|---------|
> | PREFLIGHT | `references/state-preflight.md` | inline | CHAIN → KB-DELTA (or CLEANUP if Mode=cleanup-only) |
> | KB-DELTA | `references/state-kb-delta.md` | `architect` (feat-002 dispatches sub-agents) | CHAIN → SUMMARY-DELTA / PAUSE if stalled |
> | SUMMARY-DELTA | `references/state-summary-delta.md` | inline (delegates to `/aid-summarize`) | CHAIN → CLEANUP / PAUSE if stalled |
> | CLEANUP | `references/state-cleanup.md` | inline | CHAIN → DONE |
> | DONE | `references/state-done.md` | inline | HALT |

**NOT owned by this feature (plug-in points):** the bodies of state-kb-delta.md (002),
state-summary-delta.md (003), state-cleanup.md (004), and the deterministic test suites for
their logic (per NFR5; see Testing).

### Invocation / CLI

Arg grammar handled in `SKILL.md`'s `## Arguments` table + State Detection prose (no dedicated
arg-parse script — consistent with the other five skills, which all route args via the prose
`## Arguments` table + State Detection rather than a CLI parser), in the `## Arguments` table
style of the sibling skills:

| Argument | Effect |
|----------|--------|
| *(none)* | Full gated sequence: `KB-DELTA → SUMMARY-DELTA → CLEANUP` (FR7 default). |
| `--cleanup-only` | Jump straight to CLEANUP, skipping KB and summary (AC10). Sets `**Mode:** cleanup-only`. |
| `--grade X` | Pass-through to the SUMMARY-DELTA delegation to `/aid-summarize` (`[A-F][-+]?`), resolved otherwise via `read-setting.sh --skill summary --key minimum_grade --default A`. |

**`--fetch` / offline:** the online-first / permissioned-offline gate (REQUIREMENTS.md C2,
AC3) is **feature-002's** (it owns the delta computation that needs the network). The
skeleton does not parse a `--fetch` flag; it simply routes into KB-DELTA, whose body
(feature-002) performs `git fetch origin` and the offline-permission prompt. Noted here only
to delineate the boundary.

### Git / Version-Control Boundary (Security-equivalent)

There is no auth/secrets surface; the security-equivalent concern is the **VC boundary**
(`.aid/knowledge/infrastructure.md` § Source Control; project rule in `CLAUDE.md`
"never commit to `master` directly — branch + PR always"; REQUIREMENTS.md C3, NFR1).

- **Never operate on `master`.** `branch-commit.sh` checks the current branch; if it is
  `master`, it creates/switches to `aid/housekeep-<slug>` before any mutation. If already on
  an `aid/housekeep-*` branch, reuse it (resume).
- **One commit per stage.** KB refresh, summary regen, and cleanup each produce exactly one
  commit with a descriptive message (e.g. `chore(housekeep): KB delta refresh [feature-002]`).
- **Deletion mechanism (CLEANUP, feature-004, referenced here for the commit contract):**
  tracked items via `git rm` (staged, recoverable from history); untracked cruft via plain
  `rm`. Both land in the single per-stage commit.
- **Never push.** The skill stops at the commit; the user pushes and opens the PR
  (REQUIREMENTS.md C3, Out-of-Scope). `branch-commit.sh` contains no `git push`.

### Traceability (NFR4)

KB-DELTA dispatches sub-agents (feature-002 → `/aid-discover`'s targeted re-discovery path),
so the `SKILL.md` MUST carry the same `## Dispatch Protocol (L1+L2+L3 subagent visibility)`
block as `canonical/skills/aid-discover/SKILL.md` (heartbeat pre-create via
`read-setting.sh --path traceability.heartbeat_interval --default 1`, three armed L2 timers
as separate background dispatches, Calibration-Log writeback). This is a **requirement on the
scaffold** so feature-002 inherits it; the per-dispatch mechanics live in feature-002's body.
References: `canonical/templates/long-wait-protocol.md`,
`canonical/templates/subagent-heartbeat-protocol.md`,
`canonical/templates/rough-time-hints.md`.

### Distribution (AC11)

- **Authored in `canonical/`** under `canonical/skills/aid-housekeep/`.
- **Auto-rendered to all 5 profiles** with **no renderer edit**:
  `.claude/skills/aid-generate/scripts/render_skills.py` discovers skills by
  `skill_dirs = sorted(d for d in skills_base.iterdir() if d.is_dir())` (`render_skills` fn)
  and emits `SKILL.md` + `references/*.md` + `scripts/*.sh` for every folder it finds. Adding
  `canonical/skills/aid-housekeep/` is therefore sufficient for it to ship to claude-code,
  codex, cursor, copilot-cli, and antigravity (the 5 profiles under `profiles/*.toml`). The
  determinism self-test (`render_skills.py --self-test`) will exercise the new folder
  automatically.
- **Absent from the mandatory pipeline flow.** Like `/aid-summarize`, `/aid-housekeep` is an
  optional / on-demand skill (REQUIREMENTS.md FR6) — it is NOT inserted into the
  phase-to-skill pipeline mapping in `.aid/knowledge/architecture.md`. No phase-gate
  references it; it is invoked by the user on demand.

### Testing (NFR4 / NFR5)

A canonical suite under `tests/canonical/`, auto-discovered by the
`tests/canonical/test-*.sh` glob in `tests/run-all.sh` (no edit to `run-all.sh` — it
discovers suites by glob, sources `tests/lib/assert.sh`, runs each under `timeout 300`).
This feature owns the deterministic-logic suites for the **skeleton**:

- `tests/canonical/test-housekeep-state.sh` — `housekeep-state.sh` round-trip: write a
  `## Housekeep Status` block, read it back, and assert the resume target for each of the 6
  re-entry rows (the resume-detection contract is the highest-value thing to test for AC9).
- `tests/canonical/test-housekeep-branch-commit.sh` — `branch-commit.sh` against a throwaway
  git repo: refuses to mutate `master` (creates `aid/housekeep-*` first), reuses an existing
  `aid/housekeep-*` branch, makes exactly one commit, and never calls `git push` (assert no
  remote interaction).

The **stage-logic** suites (delta detection + path→doc mapping = feature-002; cleanup
classification + work-folder safety = feature-004) are authored with those features per NFR5,
not here.

### Sections marked N/A (this domain)

- **API Contracts** — N/A: AID ships no HTTP/RPC services (`.aid/knowledge/pipeline-contracts.md`
  § "AID ships no HTTP services or RPC endpoints"). The skill's "contract" is its slash-command
  signature + state-machine, captured under Invocation/CLI and Feature Flow.
- **UI Specs / Mobile Specs** — N/A: no UI and no mobile surface; interaction is the CLI/chat
  state machine.
- **Events & Messaging** — N/A: inter-skill choreography is filesystem state hand-offs, not a
  broker (`.aid/knowledge/integration-map.md`).
- **Migration Plan / Cache Strategy / Search/Indexing / Telemetry / Cloud / Hardware** — N/A:
  no runtime infrastructure (`.aid/knowledge/infrastructure.md` § "no conventional runtime
  infrastructure").

### Cross-feature contracts (what 002 / 003 / 004 plug into)

- **feature-002 (KB delta)** authors the body of `references/state-kb-delta.md`; on exit it
  MUST write `**KB Stage:** passed|skipped|stalled` in `## Housekeep Status`, reach a fresh
  `**User Approved:** yes` for the `passed` case, write `**Approved-At-Commit:**` to
  `.aid/knowledge/STATE.md`, and own the C2 offline-permission gate. It inherits the
  scaffold's `## Dispatch Protocol (L1+L2+L3)` for its sub-agent dispatch.
- **feature-003 (summary delta)** authors `references/state-summary-delta.md`; writes
  `**Summary Stage:** passed|skipped|stalled`; delegates to `/aid-summarize` STALE-CHECK + gate.
- **feature-004 (cleanup)** authors `references/state-cleanup.md`; writes `**Cleanup Stage:**
  passed`; uses the `branch-commit.sh` per-stage commit + `git rm`/`rm` deletion mechanism
  defined here.
- All three commit through `canonical/scripts/housekeep/branch-commit.sh` (one commit per
  stage, never push) and read their gate predecessor via
  `canonical/scripts/housekeep/housekeep-state.sh`.
