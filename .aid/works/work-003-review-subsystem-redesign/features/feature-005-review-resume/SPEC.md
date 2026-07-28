# Review Resume

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-27 | Feature identified from REQUIREMENTS.md §5.D (FR-D4..D7), §9 (AC-6, AC-7, AC-8) | /aid-define |

## Source

- REQUIREMENTS.md §5 group D — FR-D4, FR-D5, FR-D6, FR-D7
- REQUIREMENTS.md §9 — AC-6, AC-7, AC-8
- REQUIREMENTS.md §2 — problem 4 (a review cannot be resumed)

## Description

Feature 3 gave the ledger somewhere to record coverage. This feature decides what that
record means when a review picks up again.

The central distinction is between two things that look similar and are not. **Resuming** an
interrupted review is continuing the same pass — it may see its own progress and its own
earlier findings, because it is not re-judging anything. Starting a **new cycle** after a fix
is re-judging, so it must run clean, with no knowledge of what was found before or what was
repaired.

That distinction resolves a contradiction sitting in the codebase today. The ledger schema
tells a second-cycle reviewer to read the prior ledger and update statuses. `aid-discover`
forbids exactly that — no prior results, no mention of what was fixed, never say "re-review".
The rule that reconciles them: independence protects judgment, not bookkeeping. So status
reconciliation moves to the orchestrator, and the new-cycle reviewer stays clean.
`aid-discover` already works this way, with mandate reviewers writing scratch ledgers that the
orchestrator merges.

Resuming also has to know what is still valid. Two things invalidate examined work: the
artifact changed, or the criteria changed. The second matters most here — if a review halted
because a standard was missing and the user then wrote that standard, the yardstick moved, and
units measured against the old one are no longer trustworthy.

Three kinds of interruption are handled: halting to ask, the user stopping the run, and
involuntary death from a crash, timeout, or exhausted context. The last is why checkpointing
happens after every unit, and why a unit left `In Progress` is treated as unexamined.

## User Stories

- As an **adopter project**, I want an interrupted review to pick up where it stopped rather than starting over.
- As an **AID maintainer**, I want a new review cycle to run clean so that its judgment is genuinely independent of the previous one.
- As an **AID maintainer**, I want status bookkeeping owned by the orchestrator so that reviewer independence and ledger continuity stop being in conflict.
- As an **adopter project**, I want a review that crashed to resume correctly, re-checking only the unit it died inside.
- As an **adopter project**, I want a review to re-check what a changed standard affects — and only that.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-6** — Given an interrupted review, when it resumes, then it re-examines no `Examined` unit and skips no `Unexamined` one.
- [ ] **AC-7** — Given a review killed mid-unit, when it resumes, then it re-examines only the interrupted unit.
- [ ] **AC-8** — Given a criterion change, when the review resumes, then exactly the affected units are invalidated and re-reviewed — verifiable on a fixture.
- [ ] Given a resumed review, when it runs, then it may see its own prior progress and findings.
- [ ] Given a new cycle after a fix, when the reviewer is dispatched, then it receives no prior findings, no prior grade, and no account of what was fixed.
- [ ] Given a completed review cycle, when statuses are reconciled against the existing ledger, then the orchestrator performs it, not the reviewer.
- [ ] Given a changed artifact, when the review resumes, then that artifact's unit is invalidated.
- [ ] Given a unit left `In Progress` by an involuntary interruption, when the review resumes, then it is treated as unexamined.
- [ ] Given a user-initiated stop, when the reviewer reaches its next safe checkpoint, then it finishes the current unit and ends without starting further work.

## Notes for Specify

- **This feature edits `canonical/agents/aid-reviewer/AGENT.md`** — it removes reviewer-side Status reconciliation ("you may update an existing row's Status", FR-D5).
- **It also resolves the schema contradiction.** `reviewer-ledger-schema.md`'s cycle-N≥2 workflow and `aid-execute`'s delivery gate both instruct the reviewer to update prior statuses; `aid-discover`'s contamination-prevention rule forbids it. STATE.md Q7 #8 notes no FR explicitly owns rewriting that lifecycle section — this feature or feature 3 must claim it, and this is the more natural home since FR-D5 is the requirement that contradicts it.
- **Requires features 3 and 4.** The manifest and checkpoint helper come from 3. Criteria-change invalidation only has an event to react to once gap resolution exists in 4.
- Reuse the existing subagent heartbeat protocol (liveness plus coarse progress) and the `STOP_FILE` cooperative stop-poll rather than inventing new signals. The agent contract already promises to "halt at the next safe checkpoint — finish your current atomic unit of work", which is precisely the resume boundary; it simply is not recorded anywhere today.
- Verify five-profile render parity at feature close (STATE.md concern N3).

---

## Technical Specification

> Authored by `/aid-specify` on 2026-07-27. Unlike features 001–004, this spec keeps three of
> the standard conditional sections — `State Machines`, `Recovery Management` and
> `Migration Plan` — because this feature genuinely is a state machine and a recovery story.
> The remaining conditional sections are dropped: no store, no request flow, no network or UI
> surface. The template's conditional count is whatever this returns, so it is not quoted here:
> `awk '/conditional sections below/,0' canonical/aid/templates/specs/spec-template.md | grep -c '^#\{2,3\} '`

### 1. The contradiction, and the resolving principle

Three sites, quoted:

- `canonical/aid/templates/reviewer-ledger-schema.md:101` — *"**REVIEW (cycle N≥2):** read
  existing file. For each existing `Pending` row: verify on disk → if resolved, change Status to
  `Fixed`; if still wrong, leave as `Pending`. For each existing `Fixed` row: verify still
  resolved → if regressed, change Status to `Recurred`. Append new rows as `Pending` for
  newly-found issues."*
- `canonical/skills/aid-execute/references/state-delivery-gate.md:170–173` — *"**Ledger
  lifecycle:** \"Read the existing `.aid/.temp/review-pending/execute-delivery-NNN.md` if it
  exists. For each existing row: verify on disk, update Status if needed…\""* — twenty-two lines
  after line 148 tells the same dispatch *"Clean context — reviewer must NOT inherit any
  executor working notes."*
- `canonical/skills/aid-discover/references/state-review.md:355–357` — *"- Do NOT include
  previous review results in any mandate prompt / - Do NOT tell reviewers what was fixed or the
  previous grade / - Do NOT say \"re-review\" — each mandate reviewer must approach fresh"*.

**The resolving principle: independence protects judgment, not bookkeeping.** Clean context
exists so cycle N's severity is not anchored by cycle N−1's. Deciding that row 4 is now `Fixed`
is not a judgment about the artifact — it is a set difference between two finding lists. Nothing
is protected by making the judge do that arithmetic, and a great deal is lost: the judge must be
shown the prior verdict to do it.

**The current model is worse than contradictory — it cannot run.** Verified in the one skill
that already uses scratch ledgers:

- `state-review.md:497–528` (step 2e) deletes every scratch **unconditionally** after each merge.
- `state-fix.md:7` shows FIX reads only the canonical `discovery.md`; nothing re-creates a scratch.
- Yet each mandate prompt tells a cycle-2 reviewer to read a file 2e already deleted —
  `reviewer-prompt-correctness.md:127`, `-anatomy.md:223`, `-teachback.md:191`,
  `-actback.md:183`, all of the form *"If re-reviewing: read existing `{{SCOPE}}-<mandate>.md`,
  update Status for your prior rows"*.
- And `state-review.md:404–411` builds on that — *"the mandate reviewers have updated their own
  rows' Status in their scratch ledgers. Merge rule: 1. For rows in the existing `{{SCOPE}}.md`
  that correspond to a mandate's scratch ledger, replace the row with the scratch ledger's
  version"*. A key **is** named, at lines 405–406: *"Each mandate reviewer's rows are identified
  by their `#` ID prefix (M1-NNN, M2-NNN, TB-NNN, AB-NNN)"*. But that key is the **row ID**, and a
  row ID is only stable across cycles if the scratch that minted it still exists — which step 2e
  has already deleted. So the key is defined and unusable, which is a different defect from an
  undefined one and a worse one: it looks workable on the page.

So reconciliation in `aid-discover` has an input deleted before it is read and a join key that
cannot survive that deletion. **FR-D5 is not a preference; it is the repair** — and keying on
`(Doc, Rule)` instead of the row ID (§3) is what makes the join independent of scratch lifetime.

### 2. The attempt model — two modes, two files

**The mechanism is a file, not a flag.** Every reviewer dispatch writes to a **per-attempt
scratch ledger**; the durable `<scope>.md` is the **canonical** ledger and only the orchestrator
writes it. This generalises `aid-discover`, the only skill that already works this way
(`state-review.md:247` — *"Each mandate reviewer writes ONLY to its own scratch ledger … the
canonical `{{SCOPE}}.md` ledger … is untouched until Step 2"*).

| | Scratch path | Given to the reviewer | May see |
|---|---|---|---|
| **New cycle** (after FIX) | `<scope>-cycle<N+1>.md`, **absent** at dispatch | the scratch path only | nothing prior — it is never told the canonical path, so contamination is **structural, not instructional** |
| **Resume** (same attempt) | `<scope>-cycle<N>.md`, **present** at dispatch | the same scratch it was writing | its own coverage rows and its own partial findings — the same review, continuing |

**Selection is one `test -f`.** The dispatcher computes N from the cycle counter it already
keeps: scratch exists → resume; absent → new cycle. The brief still declares it
(`{{RESUME_MODE}}` ∈ `new-cycle | resume`) so the agent knows its contract, but correctness does
not rest on the declaration. `{{MODE}}` and `{{SCOPE}}` are already taken on other axes
(`aid-execute`'s brief line 25 uses `{{MODE}}` for `per-task | per-delivery`; `aid-plan` and
`aid-detail` use `{{SCOPE}}`), hence the third name.

**The rule that falls out:**

> **Findings merge into the canonical ledger; coverage and gap rows live and die with the
> attempt's scratch.** Resume re-enters an attempt, so coverage is intact. A new cycle starts a
> fresh attempt, so coverage is empty — which is correct, because a fresh pass re-examines
> everything.

That is feature-003 §7 promoted from a parallel-mandate special case to the universal model, and
it needs no change to it: when a run is interrupted, step 2e never runs, so the scratch is
exactly where the resumed reviewer left it.

### 3. Reconciliation — the orchestrator's algorithm (FR-D5)

```
dispatch:   orchestrator picks the scratch path (§2). Reviewer writes ONLY there.
return:     reviewer's message carries narrative; the scratch carries rows.
reconcile:  orchestrator joins scratch -> canonical on (Doc, Rule).
grade:      check-gaps.sh (feature-004) then grade.sh, on the CANONICAL ledger.
merge-out:  findings merged; the scratch's U-/G- rows stay behind and are dropped
            with the scratch (G- keys promoted to the register first, FR-D9).
```

**The join key is `(Doc, Rule)`.** Feature-002 makes `Rule` mandatory on every finding row and
single-valued (*"One rule per row … No comma-separated lists"*), which is what makes a key
possible at all — it did not exist before FR-B10. `Line` is deliberately excluded: it drifts on
every edit, so keying on it would report every fixed-then-shifted finding as new. Where one
`(Doc, Rule)` pair legitimately appears twice, `Line` is the tiebreaker.

**The transition table — the orchestrator's whole job:**

| Canonical row | Key in scratch? | Result |
|---|---|---|
| `Pending` | yes | stays `Pending`. Severity and Description are authorial and never rewritten |
| `Pending` | no, **and** the unit covering `Doc` is `Examined` in the scratch | → `Fixed` |
| `Pending` | no, and the unit is **not** `Examined` | stays `Pending` — absence proves nothing |
| `Fixed` | yes | → `Recurred` |
| `Fixed` | no | stays `Fixed` |
| `Accepted` / `OOS` / `Invalid` | either | **never auto-changed.** Schema line 94 makes `Accepted` an authorization state; a re-find is reported in the orchestrator's narration, not written |
| — | key absent from canonical | append via `writeback-ledger.sh --append-finding`, next free `#` |

**The coverage guard on row 3 is why this feature and feature-003 are one story.** Today a
cycle-N reviewer marks a row `Fixed` on absence with no evidence that it looked; the `U-NNN`
manifest is the first thing that makes *"I examined this and did not find it"* distinguishable
from *"I never got there"*. Without the guard, an interrupted cycle silently clears every finding
it did not reach.

**Reconciliation runs on every reviewer return, not only on new cycles.** A resumed attempt that
re-examines an invalidated unit will re-emit findings the canonical ledger already holds; the
same join dedupes them. One code path, and the duplicate-row hazard disappears without a second
mechanism.

### 4. Coverage validity on resume (FR-D6)

**Granularity: rule-set × artifact, with a fingerprint per axis recorded by the helper.**

A `U-NNN` row already carries both coordinates — `Doc` is the artifact, `Description` is
`rule-set: <name>`. Feature-003's `U-` row `Evidence` contract was **amended at this feature's
request** to carry two more helper-generated tokens:

```
| U-001 | -- | Examined | -- | foo.md | -- | rule-set: KB | 2026-07-27T10:00:04Z; art=3f2a…; rs=KB@a1b2c3d4 |
```

`plan-resume.sh` recomputes both on re-entry and emits a verdict per unit:

> A unit is **invalidated** — Status forced to `Unexamined` — if its Status is `In Progress`,
> **or** its `art=` digest no longer matches its artifact, **or** its `rs=` digest no longer
> matches its rule set. Otherwise it is **kept**.

`art=` is `sha256sum` of the artifact, truncated. `rs=` is `sha256sum` over the rule-set catalog
file **plus every distinct path appearing in that rule set's `Criterion` cells** — parseable by
construction, because feature-002's oracle (c) already requires every Criterion to resolve to an
existing file and a greppable anchor. Both use the idiom already in the tree at
`canonical/aid/scripts/kb/kb-dual-intent-probes.sh` (`… | sha256sum | cut -c1-16`) with the
`sha256sum`/`shasum -a 256` fallback from `lib/aid-install-core.sh`. Helper-generated, never
model-generated — the same discipline `subagent-heartbeat-protocol.md` imposes on timestamps.

**Why not per-rule.** Per-rule invalidation needs each `U-` row to record which of its rule
set's N rules were actually evaluated. That is a runtime claim by the reviewer that no static
check can verify; it inverts feature-002's discipline (a rule that fires no finding leaves no
trace, so *"I applied it"* is unfalsifiable); and it turns a one-token cell into an N-token list
immediately after feature-002 closed the door on multi-valued cells. The precision gained is
real but small, and it is bought with an unverifiable assertion.

**The cost, stated honestly.** Rule-set granularity **over-invalidates within a rule set**:
change one KB rule and every unit measured against the KB rule set is re-examined. A third
option — invalidating only units named in the resolved gap's `Scope` cell — would be tighter
still but covers only gap-driven changes and misses a plain KB edit between runs. The trade:
**over-invalidation is bounded and cheap; under-invalidation is a correctness bug.** AC-8's
"exactly the affected units" is therefore read at the declared granularity — *affected* means
*measured against a rule set whose criteria moved* — and §12's fixture pins it in both directions.

### 5. The three interruptions (FR-D7)

Four observable signals at re-entry: an `Open` `[GAP:CRITERIA]` row plus the register; the
pipeline `Lifecycle` field; the `STOP_FILE`; and the coverage manifest itself.

| Type | Positive signature | Recovery |
|---|---|---|
| **Halt-to-ask** | an `Open` `[GAP:CRITERIA]` row **and** `Lifecycle = Paused-Awaiting-Input` with a `Pause Reason` | subtract resolved gap keys (feature-004 step 4); re-open units left `Skipped … blocked by G-NNN` whose gap is now `Resolved`; apply §4's fingerprint check — the resolution almost always moved `rs=`, which is precisely the case this feature exists for |
| **User stop** | `STOP_FILE` present, **or** `Lifecycle ≠ Running`, and **no** open criteria gap | resume at the first remaining unit. The agent contract already guarantees the boundary — *"finish the atomic unit of work you are currently mid-way through"* — so nothing is left `In Progress` |
| **Involuntary** | the residual class: **no** open gap, **no** `STOP_FILE`, `Lifecycle == Running` — **and** a unit left `In Progress`, or a heartbeat whose last stamp is older than 3 × `HEARTBEAT_INTERVAL` with no completion record | the `In Progress` unit is forced `Unexamined` and re-examined; every `Examined` unit passing §4 is kept. **This is AC-7** |

Two things make this work rather than merely sound plausible.

**The `In Progress` marker must be written *before* the unit's work, not after.** Per-unit
checkpointing is a *pair* of `--set-status` calls — `In Progress` on entry, `Examined` on exit.
Feature-003 ships both calls; the discipline is stated here. Without the leading write, an
involuntary death is indistinguishable from "never reached" and AC-7 has no signature at all.
This is also why nothing-announced makes involuntary death the *residual* class: both announced
types leave a positive artifact, so their absence plus a positive `In Progress` marker is a
complete partition.

**The user-stop channel does not reach most reviews, and this spec does not pretend otherwise.**
`write-control-signal.sh` is task-scoped: `--task-id` validated against `^[0-9]{1,3}$`, signal at
`${WORK_DIR}/../../.control/${WORK_ID}/task-<NNN>.stop`, with a dashboard reader and UI keyed to
`task-<NNN>.stop`. A review dispatched by `aid-discover`, `aid-specify`, `aid-plan`,
`aid-detail`, or by `aid-execute`'s own **delivery gate** has no task id and therefore no stop
path. **Resolved: generalise it** — `write-control-signal.sh` gains
`--scope review --slug <ledger-scope>`, writing `.aid/.control/<work_id>/review-<slug>.stop`,
sized as its own delivery. FR-D7 says "all three" unqualified; declaring user-stop out of scope
for non-task reviews would close the feature with a partial MUST, which is the STATE.md Q7 #7
defect again.

### 6. Unit and attempt lifecycles

**The unit machine** (states from feature-003 §1):

```
Unexamined ──(reviewer enters unit)──> In Progress ──(unit complete)──> Examined
     ▲                                      │                              │
     │                                      └──(involuntary death)─────────┤
     │                                                                     │
     └──(plan-resume: art= or rs= digest moved, or Status was In Progress)──┘

Unexamined ──(blocked by an Open G-NNN)──> Skipped ──(that gap Resolved)──> Unexamined
```

**The attempt machine:**

```
                  ┌────────────── FIX ──────────────┐
                  ▼                                 │
new-cycle ──> attempt N (scratch present) ──> reconcile ──> grade ──> route
                  │                                                    │
                  └──(interrupted; scratch survives)──> resume ────────>┘
```

An attempt ends when its scratch is deleted. Resume re-enters attempt N; a new cycle opens
attempt N+1. There is no state in which two attempts are live for one scope.

### 7. The resume read API

Feature-003 §10 deferred `--list-units` *"to feature-005, which has an actual caller"*. There are
three, so it ships.

**Read side — a fifth mode on feature-003's helper**, beside its `--get-status`:

```bash
writeback-ledger.sh --ledger PATH --list-units [--status S] [--remaining] [--namespace NS]
# TSV to stdout: row-id <tab> status <tab> doc <tab> rule-set <tab> stamp <tab> art <tab> rs
```

`--remaining` is sugar for `Unexamined ∪ In Progress` — FR-D7's "treated as unexamined" made
mechanical in the read API rather than restated in prose at every caller. Exit codes reuse
feature-003's alphabet unchanged.

**Planning side — a new read-only `canonical/aid/scripts/review/plan-resume.sh`**, in the
`review/` directory feature-003 creates:

```bash
plan-resume.sh --ledger PATH [--rubric-root canonical/aid/templates/review-rubrics]
# TSV: row-id <tab> keep|invalidate <tab> reason   (reason ∈ ok|in-progress|artifact-changed|criteria-changed)
# exit 0 = nothing stale, 1 = stale units present, 2 = usage
```

Split for the reason feature-004 established and `.aid/knowledge/coding-standards.md` lines
226–229 require: *"Linters use `0` clean, `1` violations, `2` usage … A new failure mode SHOULD
reuse an existing code with matching semantics rather than inventing a new one."* A planner that
reports staleness follows the linter alphabet; a writer follows `writeback-state.sh`'s, where `1`
is unreadable and `2` is lock contention. One script cannot honour both.

**The planner never writes.** The orchestrator applies the plan with
`writeback-ledger.sh --set-status`, preserving feature-003's single-writer invariant and using
the sentinel lock STATE.md Q13 item 1 provisioned for exactly this feature.

### 8. The ledger-schema lifecycle rewrite — the inherited debt

Feature-003 §6 declined the *actor* half and handed it here in writing: *"feature-005 must
rewrite `reviewer-ledger-schema.md` lines 101, 149–157, 185 and 192–194, and must carry that as
an explicit acceptance criterion."* STATE.md Q7 #8 exists because this rewrite was orphaned once.
It is carried as an AC, verified by content anchors in §12 rather than line numbers — because
features 001–004 all edit this file first and every number would have drifted.

### 9. Affected-artifact inventory and region ownership

Line numbers from the work-003 worktree, before 001–004 land.

**`canonical/agents/aid-reviewer/AGENT.md`.** The union of 001–004 is
`3, 17, 21, 31, 36, 39–57, 59–67, 69–74, 75, 76–79, 81–95, 96–99, 100–103, 106–107` plus an
insertion after 79. FR-D5's target is the **second sentence of line 79** — *"On subsequent
cycles, you may update an existing row's Status (Pending→Fixed, Fixed→Recurred), but never its
Severity or Description."* Line 79 sits inside feature-003's `76–79`.

Feature-003 §6 splits this file's lifecycle **by clause, not by line** — it takes shape and
mechanism and explicitly *"declines the clause about **who** updates Status"*. So:

| Region | Change |
|---|---|
| **the Status-reconciliation clause of line 79**, as feature-003 leaves it | Deleted. A clause-level claim inside a line feature-003 owns, declared here rather than discovered as a collision, and carried as an AC in §12 |
| **insertion after feature-004's `## Finding Types` section** | A new `## Cycles and Resume` section: the two modes, what each may see, the paired `In Progress`/`Examined` checkpoint, and "you never reconcile Status — the orchestrator does". Anchored to a section, not a line, because 003 and 004 both mutate that seam |

**`canonical/agents/aid-reviewer/README.md`** — **insertion after 64**, in `## Key Behaviors`.
63/66 are feature-001's, 11/13/31/33 feature-002's, 80–81 and "after 34" feature-004's, 52 is
Q3(d).

**`canonical/aid/templates/reviewer-ledger-schema.md`** — the four inherited regions plus siblings:

| Region | Change | Status |
|---|---|---|
| **101** | Workflow step 2 → the orchestrator's reconciliation, with the coverage guard | **inherited** |
| **102** | Step 3: *"that's the next reviewer's job"* → the orchestrator's job | free (003 claims 100 only) |
| **103** | Step 4: the orchestrator's duties gain reconciliation | free |
| **138** | `First REVIEW`: *"Reviewer reads existing ledger"* → writes to a fresh scratch. 003's claim here is an insertion after 139; 004's is 141–142 | free |
| **146** | FIX block: *"that's the next reviewer's job"* | free |
| **149–157** | The whole `Subsequent REVIEW (cycle N)` block → new-cycle + resume | **inherited** |
| **185** | Fixer rule: *"that's the next reviewer's job. The fixer addresses; the reviewer confirms."* | **inherited** |
| **192–194** | Orchestrator `**Always:**` bullets. 004 deliberately inserted after 191 to leave these free | **inherited** |
| **207–208, 210** | Ad-hoc flow: the scratch path, and *"Pending → Fixed flow"* at 210 | free |
| **209** | *"After sub-agent return: runs `grade.sh`"* — see the finding below | free |
| **insertion after 104** | Scratch lifecycle at DONE | claims no existing line |

> **A cross-feature finding, verified.** Feature-004's grade-gate oracle is scoped to
> `grep -rn 'bash canonical/aid/scripts/grade\.sh' canonical/` — 18 files, 19 lines, reproduced
> exactly. **This file is not among them**, yet it invokes the grader in prose at 141, 157, 192
> and 209. 141 is feature-004's; 157 and 192 come here by hand-off; **209 is orphaned by both.**
> Claiming 209 closes the hole, and feature-004's implementation should know its totality oracle
> does not see prose grade calls.

**The FR-D5 migration set** — derived, not asserted:

```bash
grep -rnE '(Pending|Fixed) *(→|->) *(Fixed|Recurred)|update Status|next reviewer.s job|Status updated' \
     canonical .aid/knowledge CLAUDE.md AGENTS.md
```

Measured today: **13 files, 28 lines** — non-trivially false, and 0 after implementation. A manual
read adds one file the pattern cannot reach, so the authoritative set is **14**:

| File | Claimed | Note |
|---|---|---|
| `canonical/aid/templates/reviewer-dispatch.md` | **49** | The DELIVERABLES bullet *"For existing rows from prior cycles: update Status only"* — the highest-leverage site; every brief inherits it. 170 is 001's; 122–123 002's; 43–44/196/269 declined by 003; 133–134/209–214/247–254 are 004's |
| `canonical/aid/templates/shortcut-engine.md` | **770–775** | The Lite path's cycle-N≥2 reconciliation. 778 is feature-004's grade site. **The one file the sweep misses** |
| `canonical/skills/aid-execute/references/state-delivery-gate.md` | **170–173**, **326–327** | The ledger-lifecycle prompt block, and *"Status updates happen in the next REVIEW cycle when the reviewer re-verifies."* 196 is 001's |
| `canonical/skills/aid-specify/references/state-review.md` | **38–39** | |
| `canonical/skills/aid-plan/references/review-deliverables.md` | **42–43** | |
| `canonical/skills/aid-detail/references/review.md` | **45–46** | |
| `aid-discover/references/reviewer-prompt-correctness.md` | **127–128** | |
| `aid-discover/references/reviewer-prompt-anatomy.md` | **223–224** | |
| `aid-discover/references/reviewer-prompt-teachback.md` | **191–192** | |
| `aid-discover/references/reviewer-prompt-actback.md` | **183–184** | |
| `aid-discover/references/state-review.md` | **355**, **insertion after 357**, **404–411** | Sharpen *"previous review results"* to *previous **cycle's***, so resume is not forbidden by the contamination rule; add the resume carve-out; rewrite the cycle-N≥2 premise and merge rule 1. 7–11/575–576 and "after 427" are 004's; "after 424" is 003's — rules 2–4 at 412–424 unchanged |
| `.aid/knowledge/quality-gates.md` | **128**, **133–137**, **189** | Line 133 states the invariant FR-D5 inverts: *"the **reviewer** sets/updates Status"*. 98–100 is 001's, 107 002's, "after 122" 003's. Carries a Change Log row and a `README.md` revision-history entry |
| `canonical/agents/aid-reviewer/AGENT.md` | the line-79 clause | above |
| `canonical/aid/templates/reviewer-ledger-schema.md` | above | |

**New files, and two upstream amendments:**

| File | Content |
|---|---|
| `canonical/aid/scripts/review/plan-resume.sh` | §7. Lands in the `review/` directory feature-003 creates, inheriting its verified emission caveat |
| `tests/canonical/test-review-resume.sh` | §12. `run-all.sh` globs; `coverage-parity.sh` fails only on reduced assertions |
| `writeback-ledger.sh` | `--list-units` mode added (feature-003's helper) |
| `write-control-signal.sh` | `--scope review --slug <ledger-scope>` added (§5), its own delivery |
| **feature-003 §1** | The `U-` row `Evidence` contract — **already amended** to carry `art=` and `rs=`, per the Q13 amend-upstream precedent |

**Deliberately untouched.** `grade.sh` — no change of any kind, so NFR-1 holds trivially; §4's
digests are grade-inert because they ride in `Evidence`, past `cols[4]`. The six
`reviewer-brief.md` templates need no *lifecycle* edit — verified: none carries a
status-reconciliation instruction, they inherit it from `reviewer-dispatch.md:49`. They each gain
the `{{RESUME_MODE}}` slot (§12 oracle b).

### 10. Migration and compatibility

**In-flight ledgers.** A review interrupted before this feature lands has no scratch and no
coverage rows, so on first re-entry `plan-resume.sh` reports every unit `invalidate` with reason
`in-progress` — there are none to keep. That is the correct degradation: a pre-feature review
resumes as a fresh pass. No migration script.

**NFR-5.** Existing 7-column ledgers stay readable. Reconciliation requires the 8-column shape
because the join key needs `Rule` — and that is safe to require, because feature-003 §6's
shape-follows-the-header rule plus deletion at DONE means no long-lived 7-column ledger exists.
Defining a fallback key would be dead code from day one.

**NFR-6.** Resume never moves a grade — §12's differential oracle proves it, and §4's digests are
structurally grade-inert.

### 11. Render and profile impact

Per STATE.md concern N3, verified **at this feature's close**: `/generate-profile`, then
`verify_deterministic.py`, then assert `plan-resume.sh` is emitted and executable under each of
the five tool roots plus this repo's own `.claude/` and `.cursor/` installs, and that every
rendered brief carries the `{{RESUME_MODE}}` slot. Emission of `review/` must be confirmed by
rendering, per feature-003's emission caveat (a never-emitted subdirectory has never exercised the
mapping; the earlier "manifest staleness" justification was retracted).

### 12. Verification strategy

Ships as `tests/canonical/test-review-resume.sh`. Every baseline below was produced by running
the command.

```bash
grep -rnE '(Pending|Fixed) *(→|->) *(Fixed|Recurred)|update Status|next reviewer.s job|Status updated' \
     canonical .aid/knowledge CLAUDE.md AGENTS.md | wc -l   # measured: 28  (13 files)
grep -rn 'RESUME_MODE'     canonical | wc -l                # measured: 0
grep -rn 'plan-resume\.sh' canonical | wc -l                # measured: 0
grep -rn 'list-units'      canonical | wc -l                # measured: 0
grep -rn 'In Progress' canonical/aid/templates/reviewer-ledger-schema.md canonical/agents/aid-reviewer/ | wc -l   # measured: 0
```

**(b) Mode totality over a glob-derived surface** — no exclusion list, so a brief added later
fails automatically:

```bash
for f in $(ls canonical/skills/*/references/reviewer-brief.md \
              canonical/skills/aid-discover/references/reviewer-prompt*.md \
              canonical/aid/templates/reviewer-dispatch.md); do
  grep -q 'RESUME_MODE' "$f" || fail "$f: no review-mode declaration"
done
```
Measured surface today: **12 files** by that exact glob (6 briefs + 5 `reviewer-prompt*.md` + the
protocol).

**AC-6 — resumes without re-examining Examined units and without skipping Unexamined ones.** The
strong form is a **partition** assertion, which fails in both directions at once; a one-sided
check would pass trivially on "re-examine everything".

```bash
plan-resume.sh --ledger fx-mixed.md > plan.tsv        # 6 units: 3 Examined, 2 Unexamined, 1 Skipped
KEEP=$(awk -F'\t' '$2=="keep"{print $1}'       plan.tsv | sort)
INV=$( awk -F'\t' '$2=="invalidate"{print $1}' plan.tsv | sort)
ALL=$( writeback-ledger.sh --ledger fx-mixed.md --list-units | cut -f1 | sort)
[ -z "$(comm -12 <(echo "$KEEP") <(echo "$INV"))" ]                    # disjoint
[ "$(cat <(echo "$KEEP") <(echo "$INV") | sort)" = "$ALL" ]            # total
[ "$KEEP" = "$(printf 'U-001\nU-003\nU-005\n')" ]                      # the exact expected set
```

**AC-7 — killed mid-unit, re-examines only the interrupted unit.**

```bash
# fx-crash.md: U-002 In Progress, U-001/U-003 Examined, digests all current
[ "$(writeback-ledger.sh --ledger fx-crash.md --list-units --remaining | cut -f1)" = 'U-002' ]
# NEGATIVE CONTROL -- the assertion that stops "invalidate everything" passing:
[ "$(awk -F'\t' '$2=="invalidate"' <(plan-resume.sh --ledger fx-crash.md) | wc -l)" -eq 1 ]
```

**AC-8 — a criterion change invalidates exactly the affected units.** Two rule sets, two
mutations, one control:

```bash
# fx-criteria.md: U-001 foo.md rule-set KB (Examined), U-002 bar.sh rule-set CODE (Examined)
touch-and-edit  rubrics/kb.md                  # a KB rule-set criterion moves
plan-resume.sh --ledger fx-criteria.md > p.tsv ; [ $? -eq 1 ]
[ "$(awk -F'\t' '$2=="invalidate"{print $1"/"$3}' p.tsv)" = 'U-001/criteria-changed' ]
[ "$(awk -F'\t' '$1=="U-002"{print $2}'          p.tsv)" = 'keep' ]

# NEGATIVE CONTROL -- a file neither rule set cites moves; nothing invalidates.
git checkout rubrics/kb.md ; touch-and-edit unrelated.md
plan-resume.sh --ledger fx-criteria.md ; [ $? -eq 0 ]
```

The negative control is the one a weaker suite omits, and without it AC-8 passes on a planner
that invalidates on any filesystem change at all.

**NFR-6 / NFR-1 control — resume never moves the grade.**

```bash
grade.sh --explain fx-mixed.md 2>before.err >/dev/null
apply-plan fx-mixed.md            # every --set-status the plan calls for
grade.sh --explain fx-mixed.md 2>after.err  >/dev/null
diff -q before.err after.err      # byte-identical five-way breakdown, not just the letter
```

This holds by construction: resume writes only `U-` row Status and `Evidence`, and `grade.sh`
reaches Status at line 215 only after `cols[3]` matches one of the five bracketed literals at
lines 207–212 — a `--` fails the chain.

**The inherited debt, as an acceptance criterion** (per feature-003 §6's hand-off), verified by
content anchors rather than line numbers because 001–004 all edit this file first:

```bash
for r in 'REVIEW (cycle N≥2)' 'Subsequent REVIEW (cycle N)' \
         "that's the next reviewer's job" \
         'advance state to REVIEW (which re-verifies and updates Statuses)'; do
  grep -qF "$r" canonical/aid/templates/reviewer-ledger-schema.md && fail "orphan survives: $r"
done
grep -q 'orchestrator reconciles' canonical/aid/templates/reviewer-ledger-schema.md || fail 'no replacement'
```

**What no script can prove, stated plainly.** *"The resumed reviewer actually skips the units the
plan told it to skip"* is a runtime property of an agent. These oracles prove the plan is correct,
that the manifest can express the distinction, that the mode is declared at every dispatch site,
and that resume cannot move a grade. Whether a reviewer honours the plan is enforced by the agent
body and observable afterwards in the `U-` rows.

### 13. Out of scope

- The severity scale, the rubric catalog, the `Rule` column, the row kinds, the write helper, and
  the gap model — **features 001–004**. This feature consumes all of them.
- `aid-light-review`, `aid-screener`, the boilerplate split, and the caller migration —
  **feature-006**.
- The settings gate, the frontmatter-lint wiring, the BLUEPRINT review, the per-section specify
  ledger, and the single-grading-backend consolidation — **feature-007**.
- Two pre-existing defects found and **logged to Q3, not claimed here**:
  `reviewer-dispatch.md` says *"EXACTLY these 5 sections"* (line 20, repeated at 179 and 213) and
  ships **six** — verified twice, in the fenced block at 23–55 and by
  `awk 'NR>=60 && NR<=175 && /^### /'`, which returns 6. This is distinct from feature-002's
  "six briefs listed as seven" finding, and it matters because both feature-004 (`GAP POLICY`)
  and this feature want to add content there — which is exactly why the mode declaration goes
  inside `DELIVERABLES` rather than as a seventh section. Second: `shortcut-engine.md:765–766`
  enumerates the "5-section brief" and lists only five, omitting `DELIVERABLES`.

### Delivery recommendation

Four deliveries. **D1** — `plan-resume.sh`, `--list-units`, and the suite; independently
verifiable and ships the whole planning capability. **D2** — the schema lifecycle rewrite plus
the `AGENT.md` and `README.md` edits, discharging the inherited debt. **D3** — the 14-file FR-D5
migration and the `{{RESUME_MODE}}` slot across the 12-file brief surface; largest file count,
smallest per-file change. **D4** — the `write-control-signal.sh` generalisation for non-task
reviews, separable because it closes FR-D7's third type independently of the rest.
