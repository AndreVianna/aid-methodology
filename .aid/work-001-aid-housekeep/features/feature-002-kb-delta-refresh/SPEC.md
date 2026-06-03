# KB Delta Refresh

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-02 | Feature identified from REQUIREMENTS.md §5 (FR1, FR2), §7 (C2), §8 (D1) | /aid-interview |
| 2026-06-02 | Q1 resolved: delegation via synthesized Q&A/IMPEDIMENT entry (existing re-entry, not a new entrypoint); naming disambiguated (path→doc scoping map) | /aid-interview (cross-reference) |
| 2026-06-02 | Technical Specification authored (detect-delta.sh CLI/exit contract, path→doc scoping map, synthesized Q&A delegation, Approved-At-Commit baseline + D1 edit, gate output, offline/bootstrap, tests) | /aid-specify |
| 2026-06-02 | FIX (review C+→re-gate): no-resolvable-owner branch in scope-delta (MEDIUM); baseline-ref reconciliation origin/master vs HEAD (LOW); Q&A cite 541-546 (LOW); build-project-index path cite (MINOR) | /aid-specify (review) |
| 2026-06-02 | **Design pivot — agent-driven KB reconciliation.** Technical Specification rewritten: KB detection/scoping is now agent analysis (prose), not deterministic scripts. REMOVED `detect-delta.sh`, `scope-delta.sh`, the path→doc scoping map, the `Approved-At-Commit:` baseline field, and the D1 edit to `/aid-discover`. Git history is an optional hint (C2), not a boundary; no hard offline gate. The synthesized `Impact: Required` Q&A delegation to `/aid-discover`'s targeted re-entry STAYS (gate reuse). Rule: scripts only for deterministic / eliminate-subjectivity work; analysis→agent prose. | /aid-execute (loopback) |

## Source

- REQUIREMENTS.md §5 FR1 (agent-driven KB reconciliation; git history is an optional hint,
  not a boundary), FR2 (scoped refresh + delegated, gated re-approval)
- REQUIREMENTS.md §7 C2 (git is a hint, handled conversationally; no hard offline gate)
- REQUIREMENTS.md §9 AC1–AC5
- REQUIREMENTS.md §6 NFR3 (transparency), NFR5 (tested)

## Description

The KB stage of `/aid-housekeep` — the core new logic the skill owns. It is an **agent-driven**,
drift-focused re-discovery: the agent autonomously inspects the actual repository content
(code, data, docs) against what the Knowledge Base claims, finds the discrepancies, and
refreshes only the affected KB documents. Detecting and scoping the drift is **analysis the
agent performs** — there is no SHA-anchored detection script, no `Approved-At-Commit:` field,
and no path→doc scoping map. Git history is an **optional hint**: the agent may `git fetch` and
read `git log/diff` since the recorded `Last KB Review` date to focus attention on
recently-changed areas first, but it is **not bounded by the git delta** (it also catches KB
claims that were subtly wrong all along — AC1). Offline is handled conversationally (C2): with
no network the agent says so and proceeds from local state / broader content inspection — there
is no hard offline gate. Having planned the corrections, the agent **shows the proposed refresh
scope for confirm-and-adjust**, then **delegates** the actual update to `/aid-discover`'s
targeted re-discovery + REVIEW→APPROVAL gate — reusing the approval machinery rather than
duplicating it — ending in a fresh `User Approved: yes`.

**Delegation mechanism (resolved — Q1, 2026-06-02):** housekeep drives `/aid-discover`'s
**existing** targeted re-entry by **synthesizing a Q&A entry** in `knowledge/STATE.md`
(`**Impact:** Required`) that names the affected docs from the user-confirmed scope.
`/aid-discover`'s dispatch path is **not** modified, and (after the pivot) neither is its
approval writeback — no skill outside this feature is edited. This keeps the integration surface
minimal and reuses the proven re-entry rather than adding a new scoped-dispatch entrypoint.

## User Stories

- As an AID maintainer, I want the skill to find exactly what changed on `master` since the
  KB was approved so that I refresh only the affected docs, not everything.
- As an AID maintainer, I want to see and adjust the proposed refresh scope before anything
  runs so that I stay in control of what gets re-discovered.
- As an AID maintainer, I want detection anchored on a commit (not a fuzzy date) so that no
  change is missed or double-counted.

## Priority

Must

## Acceptance Criteria

- [ ] **AC1** — Given a KB approved at commit `X` with merges to `origin/master` since, when
  the skill runs, then it fetches and reports the changed paths from `X..origin/master`.
- [ ] **AC2** — Given no `Approved-At-Commit:` recorded, when the skill runs, then it falls
  back to the approval date and records a SHA at the next approval.
- [ ] **AC3** — Given the fetch fails, when the skill runs, then it halts and requests
  explicit permission before diffing local `master`; without permission it does not proceed.
- [ ] **AC4** — Given a delta, when the skill scopes it, then it auto-maps changed paths to
  owning docs/sub-agents, shows the scope for confirm/adjust, dispatches only those
  sub-agents through `/aid-discover` REVIEW→APPROVAL, ending in `User Approved: yes`.
- [ ] **AC5** — Given no delta, when the KB stage runs, then it reports "current," dispatches
  no sub-agents, and advances.
- [ ] **D1** — Given a KB approval (via `/aid-discover` or housekeep), when the writeback
  runs, then `Approved-At-Commit:` is set to the current `master` SHA in `knowledge/STATE.md`.

---

## Technical Specification

> Scope note: this feature authors the **body** of the KB-DELTA state that
> feature-001's skeleton routes into. feature-001 owns the thin-router, the
> `## Housekeep Status` run-state, `housekeep-state.sh`, `branch-commit.sh`, the
> `## Dispatch Protocol (L1+L2+L3)` block on `SKILL.md`, and the CHAIN/PAUSE/HALT
> advance machinery. This feature fills `references/state-kb-delta.md` (a stub
> per feature-001 SPEC § Layers & Components) **as agent-driven prose**.
> **Contracts honored** (see § Cross-feature contracts honored): on exit this
> body writes `**KB Stage:** passed|skipped|stalled` in `## Housekeep Status`,
> reaches a fresh `**User Approved:** yes` in `.aid/knowledge/STATE.md` for the
> `passed` case, commits via `branch-commit.sh`, and inherits the L1/L2/L3
> dispatch protocol for its sub-agent run.

> **Design model (the governing rule).** Scripts are reserved for **deterministic
> work or for eliminating the subjectivity of an analysis** — the branch/commit
> safety guard and run-state I/O (feature-001), the cleanup safety classification
> (feature-004). **Anything needing analysis, understanding, or planning is the
> agent's job (prose).** KB reconciliation — *what has drifted, which docs are
> affected, what the correction is* — is analysis. Therefore this feature ships
> **no new scripts**: it is a prose body in `references/state-kb-delta.md` plus
> the reuse of feature-001's helpers and `/aid-discover`'s gate. There is **no
> `detect-delta.sh`, no `scope-delta.sh`, no path→doc scoping map, no
> `Approved-At-Commit:` field, and no edit to `/aid-discover`** (all removed in
> the 2026-06-02 pivot).

### Data Model

**N/A as a relational schema** — AID ships no database
(`.aid/knowledge/schemas.md` § "There is NO relational database in AID"). The
persistent state this feature touches is the `**KB Stage:**` field in the
work-area `## Housekeep Status` block (defined in *Data/State Contracts* below)
and a synthesized `### Q{N}` entry it appends to `.aid/knowledge/STATE.md`
`## Q&A (Pending)`. The reconciliation's intermediate data (the drift analysis,
the affected-doc set) is the agent's working reasoning, ephemeral per run — not
serialized to a schema.

### Data/State Contracts

#### S-1. `**KB Stage:**` in `## Housekeep Status` (feature-001 contract)

This body is the sole writer of `**KB Stage:**` (`passed` | `skipped` |
`stalled`) in the work-area `## Housekeep Status` block (feature-001 SPEC § C-2
field table). It writes through feature-001's
`canonical/scripts/housekeep/housekeep-state.sh` writer (the same helper that
owns every `**Field:**` in that block) — this body does NOT hand-edit the block.
The gate before SUMMARY-DELTA reads this field.

#### S-2. Synthesized `### Q{N}` entry (the delegation handle)

To drive `/aid-discover`'s targeted re-entry, the body appends one Q&A entry to
`.aid/knowledge/STATE.md` `## Q&A (Pending)` in the canonical Style A schema
(`### Q{N}` + sub-bullets — `coding-standards.md §12`; `{N}` = next integer after
the highest existing `### Q[0-9]+`). Its `**Impact:** Required` is what forces
`/aid-discover` into its Q-AND-A → targeted re-entry regardless of grade
(`aid-discover/SKILL.md § State Detection` State 3; `references/state-q-and-a.md`).
The body **reads `Last KB Review`** (`> **Last KB Review:**` blockquote line,
`.aid/knowledge/STATE.md`) as the optional git hint and **reads `User Approved`**
(`> **User Approved:**`) on read-back to confirm a fresh approval — both are
existing fields; this feature adds **no new field** to `knowledge/STATE.md`.

### Feature Flow (the KB-DELTA state body)

`references/state-kb-delta.md` runs as a linear sequence inside one KB-DELTA
entry, mirroring the step-numbered body style of `/aid-summarize`'s state docs
(e.g. `canonical/skills/aid-summarize/references/state-stale-check.md`). On its
first entry it runs Steps 1–4 (hint → content inspection → scope/confirm →
delegate). Subsequent re-entries (resume after the user acts on the synthesized
Q&A) run Steps 5–6 (read-back + gate). Resume is disk-driven: the body checks
`.aid/knowledge/STATE.md` for the synthesized entry's `**Status:**` and for a
fresh `**User Approved:**` to know which half to run (mirroring the
`⚠️ FILESYSTEM IS THE ONLY SOURCE OF TRUTH` rule both sibling skills enforce).

```
KB-DELTA entry
  Step 1  read Last KB Review; optionally git fetch + log/diff (HINT only)
              offline ─► say so, proceed from local/content (no hard gate)  (C2/AC5)
  Step 2  inspect repo content vs KB claims → find drift                    (AC1)
              no drift ─► **KB Stage:** skipped, CHAIN                       (AC4)
  Step 3  propose affected docs + corrections; confirm-and-adjust           (AC2)
              cancel ─► **KB Stage:** stalled, PAUSE
  Step 4  synthesize **Impact:** Required Q&A in knowledge/STATE.md
              + invoke /aid-discover targeted re-entry (REVIEW→Q&A→FIX→APPROVAL)  (AC3)
  ── (re-entry) ──
  Step 5  read back: fresh **User Approved:** yes ? ── no ─► **KB Stage:** stalled, PAUSE
  Step 6  **KB Stage:** passed; commit via branch-commit.sh; CHAIN          (AC3)
```

### KB Reconciliation (agent analysis — FR1, C2, AC1)

This is the heart of the feature and it is **agent prose, not a script**. The
agent:

1. **Reads the hint.** Reads `**Last KB Review:**` from
   `.aid/knowledge/STATE.md`. Optionally runs `git fetch origin master 2>/dev/null`
   and, on success, `git log --oneline <Last-KB-Review-date>..origin/master` +
   `git diff --name-only` over that range to see what changed *recently*. This is
   a **focus hint** — where to look first.
   - **Offline (C2/AC5):** if the fetch fails, the agent says so plainly and
     proceeds from local state and broader content inspection. There is **no hard
     offline gate** and **no offline-permission prompt** — the reconciliation is
     not bounded by git, so a missing network only removes a convenience hint.
     (Down-graded from the former SHA-anchored online-first/permissioned-offline
     rule in the 2026-06-02 pivot.)
2. **Inspects content vs claims (AC1).** The agent autonomously reads the actual
   repo content (code, data, docs) and reconciles it against each KB document's
   claims, prioritizing the git-hinted areas first, then widening — because a
   purely git-scoped pass would miss drift that was subtly wrong all along (KB
   claims that never matched reality). It identifies which KB docs/areas have
   drifted and **what** in each needs correcting. This judgment is **not encoded
   as a path→doc map**; it is the agent's analysis.

No SHA-anchored range, no `Approved-At-Commit:` baseline, no exit-code contract —
those were removed with the detection script.

### Scope Proposal + Confirm (FR2, AC2, NFR3)

Step 3 of the body. The agent presents the affected docs and the corrections it
found, and pauses for confirm-and-adjust before any KB change (NFR3 transparency
— no silent KB edits), mirroring `/aid-discover`'s propose→confirm pattern:

```
KB drift detected (hint: git delta since <Last-KB-Review>, plus content review).
Proposed KB refresh scope:
  architecture.md   — <one-line: what drifted / correction>
  module-map.md     — <one-line>
  test-landscape.md — <one-line>
[1] Confirm — refresh this scope
[2] Adjust  — add/remove docs: ___
[3] Cancel  — stall this stage
```

`[2]` lets the user add or drop docs; the confirmed doc list carries to Step 4.
`[3]` writes `**KB Stage:** stalled` + `**Stall Reason:** KB refresh scope
cancelled` and PAUSES (feature-001 halt/resume).

### /aid-discover Delegation (Q1 resolved — mechanism (a))

**Decision — synthesize a Q&A entry; reuse the existing Targeted Discovery
re-entry; do NOT modify `/aid-discover` at all.** `/aid-discover` already has a
re-entry that runs *only* the affected sub-agents when a Pending Q&A entry in
`.aid/knowledge/STATE.md` names what is missing —
`canonical/skills/aid-discover/SKILL.md § Targeted Discovery (Re-entry)` (Steps
1–7: read the Q&A entry, resolve owner via `owns-<agent>`, dispatch only that
agent, regenerate INDEX/README, reset `**Grade:** Pending`, report). That
re-entry is invoked from the Q-AND-A state, which State Detection enters when any
Pending Q&A has `**Impact:** Required` (`aid-discover/SKILL.md § State Detection`
State 3; `references/state-q-and-a.md`). Housekeep drives this by **writing
exactly such an entry**, then invoking `/aid-discover`.

**Step 4 — what gets written.** Append one Q&A entry to
`.aid/knowledge/STATE.md` `## Q&A (Pending)` in canonical Style A
(`coding-standards.md §12`; `### Q{N}` + sub-bullets — the only canonical
schema):

```markdown
### Q{N}
- **Category:** Housekeep / KB Delta Refresh
- **Impact:** Required
- **Status:** Pending
- **Context:** /aid-housekeep reconciled the repo against the KB and found drift in:
  <architecture.md, module-map.md, …>. Corrections: <one line per doc>. These docs
  need targeted re-discovery.
- **Suggested:** Re-run the sub-agents that own these docs (targeted re-discovery),
  then REVIEW → APPROVAL.
```

`**Impact:** Required` is what forces `/aid-discover` into Q-AND-A → targeted
re-entry regardless of grade (State 3). `{N}` is the next integer after the
highest existing `### Q{N}` (grep `### Q[0-9]\+`). The affected-doc list comes
from the **user-confirmed scope** (Step 3), so the entry carries exactly what the
user approved. **Owner resolution is `/aid-discover`'s job** — its re-entry maps
each named doc to its owning sub-agent via its own `owns-<agent>` accessor; this
body does not resolve owners itself (no scoping map).

**Invocation + L1/L2/L3.** The body invokes `/aid-discover` to drive its state
machine (targeted re-entry → REVIEW → Q-AND-A → FIX → APPROVAL). Because
sub-agents run, this body operates **under feature-001's `## Dispatch Protocol
(L1+L2+L3)`** already present on `canonical/skills/aid-housekeep/SKILL.md`
(feature-001 SPEC § Traceability): heartbeat pre-create via
`read-setting.sh --path traceability.heartbeat_interval --default 1`, three armed
L2 timers as separate background dispatches, Calibration-Log writeback. This body
does not re-implement the protocol; it inherits it. ETA band from
`canonical/templates/rough-time-hints.md` for the discovery-subagent class.

**Read-back + routing to approval (Steps 5–6).** After `/aid-discover`'s machine
settles, the body re-reads `.aid/knowledge/STATE.md` (filesystem = source of
truth):
- The synthesized entry's `**Status:**` flips to `Answered` and `**Grade:**` is
  reset to `Pending` by the re-entry (Step 6 of Targeted Discovery), so a fresh
  REVIEW runs.
- When `/aid-discover` reaches APPROVAL and the user approves, `**User
  Approved:** yes` is set with a fresh date (`aid-discover/references/state-approval.md`).
  The body checks the approval date is newer than this run's start.
- **Fresh approval present** → Step 6: write `**KB Stage:** passed`, commit via
  `branch-commit.sh`, CHAIN to SUMMARY-DELTA.
- **Approval declined / still below grade with no resolution** → `**KB Stage:**
  stalled` + `**Stall Reason:** KB re-approval declined`, PAUSE-FOR-USER-ACTION
  (feature-001 resume banner; re-run resumes at KB-DELTA, State Detection row 3).

### Gate Output (feature-001 contract)

On exit the body writes `**KB Stage:**` via `housekeep-state.sh`:
- `passed` — fresh `**User Approved:** yes` reached (AC3).
- `skipped` — no drift found (KB already matches the repo) (AC4).
- `stalled` — scope cancelled (Step 3 `[3]`) or re-approval declined (Step 5);
  also sets `**Stage Status:** stalled` + `**Stall Reason:**` and PAUSES per
  feature-001's halt/resume (the scaffold prints the resume banner; re-run
  resumes at KB-DELTA via feature-001 State Detection row 3).

### No-Drift No-Op (AC4)

Step 2 finds the KB already matches the repo (or every change the agent saw was a
KB self-edit, not a source delta) → the body prints `✓ KB current — no drift
between the repo and the Knowledge Base; skipping refresh.`, writes `**KB
Stage:** skipped`, dispatches **no** sub-agents, makes **no** commit, and CHAINs
to SUMMARY-DELTA. Satisfies NFR2 idempotency.

### Offline Behavior (C2, AC5)

Git is a **hint, handled conversationally**. If `git fetch` fails, the agent says
so and proceeds from local state / broader content inspection — there is **no
offline-permission prompt and no hard gate**. The reconciliation is not bounded
by git, so the absence of a network only removes a convenience hint, never blocks
the stage. (This replaces the former SHA-anchored online-first / permissioned-
offline behavior, dropped 2026-06-02.)

### Components / Scripts

**Owned by THIS feature:**

- `canonical/skills/aid-housekeep/references/state-kb-delta.md` — the KB-DELTA
  body (fills the feature-001 stub) as **agent-driven, step-numbered prose** in
  the style of `canonical/skills/aid-summarize/references/state-*.md`. This is the
  feature's **only** deliverable artifact; it ships **no `canonical/scripts/`**.

**No scripts and no skill edits** are owned by this feature (the 2026-06-02
pivot removed `detect-delta.sh`, `scope-delta.sh`, the path→doc scoping map, the
`Approved-At-Commit:` field, and the `/aid-discover` `state-approval.md` D1 edit).

**Consumed (not owned):** feature-001's `housekeep-state.sh` (writes `**KB
Stage:**`), `branch-commit.sh` (one commit per stage, never push), the `SKILL.md`
Dispatch Protocol block. `/aid-discover`'s `SKILL.md § Targeted Discovery
(Re-entry)` and its `owns-<agent>` accessor in `references/doc-set-resolve.md`
(read-only reuse — the re-entry resolves owners; this body does not). `git`
(`fetch`/`log`/`diff` as an optional hint). `read-setting.sh` (settings, e.g. the
heartbeat interval).

### Testing (NFR5)

The KB reconciliation is **agent analysis/judgment** — it has **no unit suite**
(there is nothing deterministic to assert; per the governing rule, analysis is
not scripted). NFR5 is satisfied indirectly:

- **Integration test (task-005 / `test-housekeep-flow.sh`)** asserts the
  **deterministic state-machine transitions** this body wires through
  `housekeep-state.sh`: no-drift → `**KB Stage:** skipped` → CHAIN; a `stalled`
  KB-DELTA halts and a re-run resumes at KB-DELTA (re-entry row 3); the hard-gate
  ledger (SUMMARY-DELTA does not advance until `**KB Stage:**` reads
  `passed`/`skipped`). It drives the housekeep scripts and the gate-field ledger,
  **not** the LLM prose body.
- **Render / self-test gate** (`render_skills.py --self-test`) verifies the prose
  body renders byte-identically into all 5 install profiles.

This is consistent with the no-E2E-tier policy (`test-landscape.md`): the
LLM-authored prose body has no runtime behavioral test; only the deterministic
transitions it wires and its distribution are tested.

### Cross-feature contracts honored

- **feature-001 § C-2** — sole writer of `**KB Stage:** passed|skipped|stalled`
  via `housekeep-state.sh`; never hand-edits `## Housekeep Status`.
- **feature-001 § Sequencing & Gates** — `passed`/`skipped` satisfies the gate
  before SUMMARY-DELTA; `stalled` triggers the scaffold's PAUSE-FOR-USER-ACTION
  resume banner (re-run resumes at KB-DELTA, State Detection row 3).
- **feature-001 § Git/VC Boundary** — every commit goes through
  `branch-commit.sh` (one commit per stage, never push); this body runs on the
  `aid/housekeep-*` branch.
- **feature-001 § Traceability** — sub-agent dispatch inherits the `SKILL.md`
  L1/L2/L3 Dispatch Protocol; no re-implementation here.
- **`/aid-discover` § Targeted Discovery (Re-entry)** — driven via a synthesized
  `**Impact:** Required` Q&A entry; its dispatch path and its approval writeback
  are **both unchanged** (no edit to any `/aid-discover` file).

### Sections marked N/A (this domain)

- **API Contracts** — N/A: AID ships no HTTP/RPC services
  (`.aid/knowledge/pipeline-contracts.md` § "AID ships no HTTP services or RPC
  endpoints"). The only "contract" here is the synthesized Q&A entry shape (S-2)
  and the `**KB Stage:**` gate field (S-1).
- **UI Specs / Mobile Specs** — N/A: no UI/mobile surface; interaction is the
  CLI/chat confirm-and-adjust flow.
- **Events & Messaging** — N/A: inter-skill handoff is filesystem state (the
  synthesized Q&A entry + `## Housekeep Status`), not a broker
  (`.aid/knowledge/integration-map.md`).
- **Migration Plan / Cache Strategy / Search/Indexing / Telemetry / Cloud /
  Hardware** — N/A: no runtime infrastructure (`.aid/knowledge/infrastructure.md`
  § "no conventional runtime infrastructure").
