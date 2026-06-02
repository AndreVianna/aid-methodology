# Summary Delta Refresh

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-02 | Feature identified from REQUIREMENTS.md §5 (FR3) | /aid-interview |
| 2026-06-02 | Technical Specification authored (pure delegation to /aid-summarize; result→Summary Stage mapping; V1 human-gate handling; C1 gate guard; no new scripts/tests — justified) | /aid-specify |
| 2026-06-02 | Review A; applied 2 MINOR polishes (grade-summary cite 26; CURRENT_UNAPPROVED→approve-only sub-path noted in passed row) | /aid-specify (review) |

## Source

- REQUIREMENTS.md §5 FR3 (summary refresh, coarse staleness, delegated)
- REQUIREMENTS.md §9 AC6
- REQUIREMENTS.md §6 NFR2 (idempotency)
- REQUIREMENTS.md §7 C1 (ordering — runs only after KB is current & approved)

## Description

The summary stage of `/aid-housekeep`, run only after the KB stage has produced a current,
approved Knowledge Base (per the C1 ordering gate). It reconciles
`knowledge-summary.html` by **delegating to `/aid-summarize`** and honoring its existing
**STALE-CHECK** (date-based: any KB approval newer than the last summary → regenerate). This
is *coarse by design* — there is no effect-aware KB-doc→section mapping; regeneration runs
through `/aid-summarize`'s two-grade quality gate, so "regenerate whenever the KB moved" is
always safe, and the cost is just a rebuild. When the summary is already current, the stage
is a no-op.

## User Stories

- As an AID maintainer, I want the summary refreshed automatically after a KB update so that
  the published HTML never lags the Knowledge Base.
- As an AID maintainer, I want the stage to do nothing when the summary is already current so
  that re-runs are cheap and noise-free.

## Priority

Must

## Acceptance Criteria

- [ ] **AC6** — Given the KB is current & approved, when the summary stage runs, then
  `knowledge-summary.html` is regenerated iff `/aid-summarize`'s STALE-CHECK reports the KB is
  newer than the last summary, passing the two-grade gate before advancing; otherwise it is a
  no-op.
- [ ] **NFR2** — Given an unchanged state, when the stage runs, then it performs no
  regeneration.

---

## Technical Specification

> Scope note: this is the **thinnest** feature in the work. It authors the **body** of
> the SUMMARY-DELTA state that feature-001's skeleton routes into
> (`canonical/skills/aid-housekeep/references/state-summary-delta.md`, a stub per
> feature-001 SPEC § Layers & Components). The substantive work — deciding whether the
> summary is stale, regenerating it, and grading it — is **owned entirely by the existing
> `/aid-summarize` skill**. This feature adds **no new staleness logic, no new grading
> logic, and (decision below) no new scripts of its own.** It is pure delegation plus a
> result→gate translation. Per FR3 the staleness is **coarse/date-based by design** — there
> is no effect-aware KB-doc→summary-section mapping. **Contracts honored** (see § Cross-feature
> contracts honored): on exit this body writes `**Summary Stage:** passed|skipped|stalled`
> in `## Housekeep Status` via feature-001's `housekeep-state.sh`, commits a regenerated
> HTML via feature-001's `branch-commit.sh`, and runs only after feature-001's hard gate
> confirms `**KB Stage:**` is `passed`/`skipped` (C1).

### The delegation decision (FR3, AC6)

**Decision — invoke `/aid-summarize` with no staleness args and honor its STALE-CHECK +
two-grade gate verbatim.** The SUMMARY-DELTA body does **not** decide staleness itself; it
runs `/aid-summarize`, whose own `## State Detection` (`canonical/skills/aid-summarize/SKILL.md:58-99`)
runs **STALE-CHECK first, always** (step 3) and chooses GENERATE vs DONE-IDEMPOTENT vs
APPROVAL. Housekeep then translates `/aid-summarize`'s outcome into the `**Summary Stage:**`
gate value. This is the FR3 mandate ("reconcile … by delegating to `/aid-summarize`. Use its
existing STALE-CHECK") taken literally.

*Why no args (not `--reset`, not `--grade`):* feature-002 just bumped the KB approval, so
`/aid-summarize`'s date-based STALE-CHECK will already see the KB newer than the last summary
and choose GENERATE on its own — `--reset` would be redundant and would also force a needless
rebuild in the KB-skipped/summary-already-current case, breaking NFR2 idempotency. The
minimum-grade comes from `/aid-summarize`'s own resolver
(`bash canonical/scripts/config/read-setting.sh --skill summary --key minimum_grade --default A`,
`canonical/skills/aid-summarize/SKILL.md:50`); the only override housekeep forwards is the
optional `--grade X` the user passed to `/aid-housekeep` (feature-001 § Invocation/CLI maps
`--grade X` as "pass-through to the SUMMARY-DELTA delegation"). Default invocation passes no
flags at all.

**STALE-CHECK reliance (AC6).** The script that decides is
`canonical/scripts/summarize/stale-check.sh`, which compares the latest `## Review History`
date against the latest `## Summarization History` date (or the `**Last Run**` field of
`## Knowledge Summary Status`) in `.aid/knowledge/STATE.md` and prints one of four tokens —
`STALE` / `CURRENT_APPROVED` / `CURRENT_UNAPPROVED` / `FIRST_RUN`
(`stale-check.sh:5-9,23-107`; note the doc `state-stale-check.md` lists only the first three,
but the script also emits `FIRST_RUN` → treated as GENERATE per
`canonical/skills/aid-summarize/SKILL.md:75`). Because feature-002's KB stage, when it
`passed`, wrote a fresh `**User Approved:** yes` / `**Last KB Review:**` (a new
`## Review History` entry newer than the last summary), STALE-CHECK will return `STALE` →
`/aid-summarize` regenerates. When the KB stage was a no-op (`**KB Stage:** skipped`, no new
review entry) and the summary is already current+approved, STALE-CHECK returns
`CURRENT_APPROVED` → `/aid-summarize` exits via DONE-IDEMPOTENT and housekeep records the
stage as `skipped`. This is the entire AC6 / NFR2 behavior — inherited, not reimplemented.

### Result → `**Summary Stage:**` mapping (the only logic this feature owns)

The SUMMARY-DELTA body invokes `/aid-summarize`, observes how its state machine terminated
(by re-reading the filesystem — `.aid/knowledge/knowledge-summary.html`,
`## Knowledge Summary Status`, `## Summarization History` in `.aid/knowledge/STATE.md`; the
same `⚠️ Filesystem is the only source of truth` rule both skills enforce,
`canonical/skills/aid-summarize/SKILL.md:60`), and writes the gate field via
`housekeep-state.sh`:

| `/aid-summarize` outcome | How housekeep detects it | `**Summary Stage:**` | Advance (feature-001) |
|---|---|---|---|
| **Regenerated & approved** — STALE → GENERATE → VALIDATE → MANUAL-CHECKLIST → APPROVAL → WRITEBACK → DONE; Overall Grade ≥ minimum and user approved | new `## Summarization History` entry dated this run; `## Knowledge Summary Status` `**User Approved:** yes` | `passed` | **commit** the regenerated HTML via `branch-commit.sh`; **CHAIN → CLEANUP** |
| **Already current** — CURRENT_APPROVED → DONE-IDEMPOTENT (`state-done.md:28-40`, no file modified) | no new Summarization-History entry; STATE.md unchanged | `skipped` | **no commit**; **CHAIN → CLEANUP** (NFR2) |
| **Below-minimum grade / V1 fail / diagram parse fail** — `/aid-summarize` cannot reach APPROVAL (Overall Grade `min(Machine,Human) < minimum`; e.g. D1 diagram-parse → auto-F per `SKILL.md:192`, or V1 human-visual fail → Human Grade forced F per `state-manual-checklist.md:17,34`), or the user answered "no" at APPROVAL | no fresh `**User Approved:** yes` after `/aid-summarize` returns; HTML may exist but is ungraded/unapproved | `stalled` | also set `**Stage Status:** stalled` + `**Stall Reason:**`; **PAUSE-FOR-USER-ACTION** (feature-001 resume banner; re-run resumes at SUMMARY-DELTA, State-Detection row 4) |

This three-way branch is the **sole deterministic decision this feature makes**, and it is a
read of `/aid-summarize`'s own outputs — not a recomputation of staleness or grade.

### The V1 human gate — honest handling (AC6, AC9)

`/aid-summarize`'s quality gate is **two grades, `Overall = min(Machine_letter, Human_letter)`**
(`SKILL.md:101`), and the Human Grade's **V1 is a mandatory human visual gate** that no script
can auto-pass: the agent must elicit it via `AskUserQuestion` after the user has actually
opened the HTML in a real browser, and a V1 fail **forces Human Grade = F** and blocks APPROVAL
(`canonical/skills/aid-summarize/references/state-manual-checklist.md:13,17,34`;
`grade-summary.sh:26` "V1 (human visual gate) is MANDATORY"). **Housekeep cannot and does not
bypass this.** When the summary is regenerated, `/aid-summarize` itself reaches MANUAL-CHECKLIST
and pauses to ask the user the K1/K2/V1 questions — that human interaction happens **inside the
delegated `/aid-summarize` invocation**, exactly as it would on a direct `/aid-summarize` run.
The housekeep body's responsibility is only to (a) let that interaction occur, and (b) read the
terminal state afterward. Two honest consequences:

- A **regenerate** path is **not silent** — the user will be prompted by `/aid-summarize` to
  visually confirm V1 before the stage can record `passed`. The SUMMARY-DELTA state-entry
  banner says so up front (it warns the user a regeneration will require them to open and
  visually check the HTML), consistent with NFR3 transparency.
- If the user **cannot pass V1** (a real visual defect, an un-renderable diagram, or they
  decline), `/aid-summarize` ends below minimum without a fresh approval → housekeep records
  `**Summary Stage:** stalled` and PAUSES with a resume banner (feature-001 AC9). The fix
  (correct the diagram / re-run `/aid-summarize`) is user work outside the chat, which is
  precisely the PAUSE-FOR-USER-ACTION semantics feature-001 defines.

The **DONE-IDEMPOTENT** path does **not** trigger V1 — STALE-CHECK short-circuits before
GENERATE/MANUAL-CHECKLIST, so an already-current summary skips the human gate entirely
(`SKILL.md:69-79`). This is why the no-op case is cheap and noise-free (NFR2).

### Ordering precondition (C1)

SUMMARY-DELTA MUST NOT run unless the upstream gate is open. On entry the body reads
`## Housekeep Status` via feature-001's `housekeep-state.sh` and **asserts `**KB Stage:**` is
`passed` or `skipped`** (feature-001 SPEC § Sequencing & Gates: "a downstream stage may only
start when the upstream stage's row reads `passed` or `skipped`"; resume row 4). If it reads
`stalled`/`running`/`—`, the stage refuses to run — but in practice feature-001's State
Detection never routes here in that case (it resumes at KB-DELTA, row 3). The assertion is a
defensive guard restating the C1 invariant, not new gate machinery (the gate read itself is
feature-001's). The body also relies on `/aid-summarize`'s **own** preflight
(`canonical/scripts/summarize/summarize-preflight.sh:33-42` requires
`**User Approved:** yes`) as a second, independent confirmation that the KB is approved before
any HTML is generated — so even the delegated skill will refuse to run against an unapproved KB.

### Feature Flow (the SUMMARY-DELTA state body)

`references/state-summary-delta.md` is short, step-numbered prose in the style of
`canonical/skills/aid-summarize/references/state-*.md`:

```
SUMMARY-DELTA entry
  Step 0  guard: read **KB Stage:** via housekeep-state.sh; if not passed|skipped → refuse (C1)
  Step 1  state-entry banner ("you are here" map; warn: a regenerate will ask you to
              visually confirm the HTML — V1 human gate)
  Step 2  invoke /aid-summarize  (no staleness flags; forward only the user's --grade if given)
              └─ /aid-summarize runs its own PREFLIGHT → STALE-CHECK → … → DONE / pauses for V1
  Step 3  read back the filesystem and classify the outcome (mapping table above):
              ├─ regenerated & approved ─► **Summary Stage:** passed; branch-commit.sh; CHAIN → CLEANUP
              ├─ DONE-IDEMPOTENT        ─► **Summary Stage:** skipped; no commit;       CHAIN → CLEANUP
              └─ below-min / V1 fail / declined ─► **Summary Stage:** stalled +
                                                   **Stall Reason:**; PAUSE-FOR-USER-ACTION
```

### Gate Output (feature-001 contract)

On exit the body writes `**Summary Stage:**` **only** through feature-001's
`canonical/scripts/housekeep/housekeep-state.sh` (the sole writer of the `## Housekeep Status`
block per feature-001 SPEC § C-2 / § Cross-feature contracts; this body never hand-edits the
block):

- `passed` — `/aid-summarize` regenerated the HTML and reached a fresh approval (Overall Grade
  ≥ minimum). `passed` also covers the `CURRENT_UNAPPROVED → APPROVAL` sub-path (STALE-CHECK
  finds the HTML current but not yet signed off, so `/aid-summarize` skips GENERATE and goes
  straight to APPROVAL): if the user approves, only the `STATE.md` approval edit is committed
  (no HTML change) — still `passed`. (The already-current **and** already-approved case is
  reported as `skipped` (next row), not `passed`.)
- `skipped` — STALE-CHECK said `CURRENT_APPROVED` → DONE-IDEMPOTENT; nothing regenerated,
  nothing committed (NFR2).
- `stalled` — the two-grade gate came back below minimum (diagram parse F, V1 human-visual
  fail, or user declined approval); also writes `**Stage Status:** stalled` +
  `**Stall Reason:**` (e.g. `summary V1 visual gate failed` / `summary grade B < A`) and
  PAUSES; feature-001's scaffold prints the resume banner and a re-run resumes at SUMMARY-DELTA
  (State Detection row 4).

### Commit boundary (C3)

A regenerated `knowledge-summary.html` is committed via feature-001's
`canonical/scripts/housekeep/branch-commit.sh` (one commit per stage, on the
`aid/housekeep-*` branch, **never push** — feature-001 SPEC § Git/VC Boundary), with a message
like `chore(housekeep): summary delta refresh [feature-003]`. The `skipped` (DONE-IDEMPOTENT)
path makes **no** commit. This feature introduces **no** new commit mechanism; it calls the
shared helper.

> **Note — who commits the summary?** `/aid-summarize`'s own WRITEBACK
> (`canonical/skills/aid-summarize/references/state-writeback.md`) edits `STATE.md` history
> but does **not** itself git-commit (it has no VC boundary). So the housekeep body owns the
> single per-stage commit of both the regenerated HTML and the `STATE.md` history edit
> `/aid-summarize` made — captured in one `branch-commit.sh` call after `/aid-summarize`
> returns `passed`. This keeps "one commit per stage" (C3) intact.

### Components / Scripts

**Owned by THIS feature:**

- `canonical/skills/aid-housekeep/references/state-summary-delta.md` — the SUMMARY-DELTA body
  (fills the feature-001 stub). Short step-numbered prose; the only artifact this feature
  authors.

**Consumed (not owned):**

- `/aid-summarize` (the entire skill: `canonical/skills/aid-summarize/SKILL.md` + its
  `references/state-*.md` + `canonical/scripts/summarize/*.sh`) — invoked as-is; its
  STALE-CHECK, GENERATE, two-grade VALIDATE+MANUAL-CHECKLIST gate, V1 human gate, and
  WRITEBACK are reused verbatim.
- feature-001's `canonical/scripts/housekeep/housekeep-state.sh` (writes `**Summary Stage:**`,
  reads the `**KB Stage:**` gate) and `canonical/scripts/housekeep/branch-commit.sh`
  (per-stage commit, never push).

**No new scripts (decision + justification).** Unlike feature-002 (which owns
`detect-delta.sh` / `scope-delta.sh` because its git-delta and path→doc logic is genuinely
new) and feature-004 (cleanup classification), feature-003 has **no new deterministic
algorithm**: staleness is `stale-check.sh`, grading is `grade-summary.sh` + `manual-checklist.sh`,
gate-writing is feature-001's `housekeep-state.sh`, committing is feature-001's
`branch-commit.sh`. The only logic added is the three-way result classification, which is a
handful of filesystem reads in the prose body, not a reusable script. Adding a wrapper script
would duplicate `stale-check.sh`'s decision (the exact FR3 anti-goal). **So this feature ships
zero new `canonical/scripts/`.**

### Testing (NFR5)

**Decision — no dedicated canonical test suite for this feature; coverage rides on
`/aid-summarize`'s existing suites — justified.** NFR5 scopes the canonical-suite requirement
to *"the new deterministic logic — delta detection, path→KB-doc mapping, cleanup
classification, and work-folder safety rules"* (REQUIREMENTS.md NFR5; feature-001 SPEC §
Testing lists the owning features as 002 and 004 — feature-003 is **not** named). This feature
adds **none** of those: the deterministic staleness decision is already covered by
`/aid-summarize`'s own test suite for `stale-check.sh`, and the two-grade gate by its
`grade-summary.sh`/`manual-checklist.sh` suites (the existing `tests/canonical/test-*.sh`
glob in `tests/run-all.sh`). The remaining behavior — the result→`**Summary Stage:**` mapping
— is agent-orchestration prose (invoke a skill, read three filesystem signals, write one
field via `housekeep-state.sh`), and `housekeep-state.sh`'s round-trip is already exercised by
feature-001's `tests/canonical/test-housekeep-state.sh` (feature-001 SPEC § Testing, which
asserts every `## Housekeep Status` field write incl. `**Summary Stage:**` and the resume
target). A new bash suite here would have no new deterministic unit to drive — it would either
re-test `stale-check.sh` (owned by `/aid-summarize`) or re-test `housekeep-state.sh` (owned by
feature-001). A dedicated suite is therefore **N/A** for this feature; the behavior is verified
by (a) `/aid-summarize`'s suites for the staleness/grade decisions and (b) feature-001's
`test-housekeep-state.sh` for the gate-field write/resume.

### Sections marked N/A (this domain)

- **Data Model / Schema** — N/A: AID ships no database (`.aid/knowledge/schemas.md`
  § "There is NO relational database in AID"). The only persistent state this feature writes is
  one key-value field, `**Summary Stage:**`, in the work-area `## Housekeep Status` block —
  defined by feature-001 § C-2, written through `housekeep-state.sh`. The summary's own state
  (`## Knowledge Summary Status`, `## Summarization History`) is owned by `/aid-summarize`.
- **API Contracts** — N/A: AID ships no HTTP/RPC services
  (`.aid/knowledge/pipeline-contracts.md` § "AID ships no HTTP services or RPC endpoints").
  The "contract" is the delegation to `/aid-summarize`'s slash-command + the result→gate
  mapping table above.
- **UI Specs / Mobile Specs** — N/A: no UI/mobile surface. (The one human-interaction surface,
  the V1 visual check, is `/aid-summarize`'s `AskUserQuestion` flow, not housekeep's.)
- **Events & Messaging** — N/A: the only inter-skill handoff is filesystem state
  (the regenerated HTML + `STATE.md` history + the `**Summary Stage:**` gate field), not a
  broker (`.aid/knowledge/integration-map.md`).
- **Migration Plan / Cache Strategy / Search-Indexing / Telemetry / Cloud / Hardware** — N/A:
  no runtime infrastructure (`.aid/knowledge/infrastructure.md` § "no conventional runtime
  infrastructure").
- **New scripts / dedicated test suite** — N/A by design (see Components and Testing above).

### Cross-feature contracts honored

- **feature-001 § C-2 / Cross-feature contracts** — sole writer of
  `**Summary Stage:** passed|skipped|stalled` via `housekeep-state.sh`; never hand-edits
  `## Housekeep Status`.
- **feature-001 § Sequencing & Gates (C1)** — runs only when `**KB Stage:**` reads
  `passed`/`skipped` (Step 0 guard); `passed`/`skipped` opens the gate before CLEANUP;
  `stalled` triggers the scaffold's PAUSE-FOR-USER-ACTION resume banner (re-run resumes at
  SUMMARY-DELTA, State Detection row 4).
- **feature-001 § Git/VC Boundary (C3)** — a regenerated HTML is committed through
  `branch-commit.sh` (one commit per stage, never push); the DONE-IDEMPOTENT path makes no
  commit.
- **feature-002** — relies on its `**KB Stage:** passed` having written a fresh KB
  approval/review entry, which is exactly what makes `/aid-summarize`'s STALE-CHECK return
  `STALE` → regenerate (AC6); a `**KB Stage:** skipped` with an already-current summary yields
  DONE-IDEMPOTENT → `skipped` (NFR2).
- **`/aid-summarize`** — invoked unmodified; its STALE-CHECK, two-grade gate, mandatory V1
  human gate, and WRITEBACK are reused verbatim. This feature edits nothing in
  `canonical/skills/aid-summarize/`.
