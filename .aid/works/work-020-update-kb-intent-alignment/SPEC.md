# aid-update-kb Scope-Fidelity Redesign

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-21 | SPEC drafted (redesign analysis) | direct session |
| 2026-07-21 | Reshaped to feature-001 SPEC template; folded design into Technical Specification | direct session |
| 2026-07-22 | GATE Pass 1 FIX: scope-diff guard derives edited set from disk; added re-scope revert; AC-8 (HL-3); robust citations; corrected settings floor note; migration rename rows | GATE FIX |
| 2026-07-22 | Cycle-4: reinforce start-of-run worktree isolation (mirror /aid-fix); add HL-8 (conversation not a source) + AC-9/AC-10; clarify hunk-level traceability. `approved_at_commit:` left unchanged per owner | owner directive |
| 2026-07-22 | delivery-gate FIX (7 findings): REVIEW's FIX loop is now self-contained (no longer delegates to aid-discover's unparameterized state-fix.md); APPLY's re-scope revert is disk-derived (strips stray never-self-reported out-of-scope edits, not just prior Edited Docs); REVIEW 4(b) "accept" routes through SCOPE (via CONFIRM's own [2] Adjust) instead of a bare CONFIRM re-freeze; Pre-flight Rung A now prompt-matches (STOP on mismatch) like Rung B; APPLY Step 2 is check-before-write (idempotent on re-entry) and gains the new-file (`Kind: new-file`) creation branch (Write + f001 schema); SKILL.md/SPEC.md corrected so CONFIRM/APPROVAL CHAIN inline on `[1]` and only pause/halt on `[2]`/`[3]` | delivery-gate FIX |

## Source

- REQUIREMENTS.md §5 Functional Requirements (FR-1..FR-11)
- REQUIREMENTS.md §9 Acceptance Criteria (AC-1..AC-10)
- Owner-confirmed hard limits HL-1..HL-8 (§ Governing hard limits below)

## Description

Redesign the `aid-update-kb` skill so the change applied to the Knowledge Base is
strictly bounded to the scope of the user's instruction. The skill first analyzes
how and where the instruction lands in the KB (surfacing contradictions,
mismatches, and gaps), confirms that understanding and scope with the user, and
only then applies edits limited to what was confirmed.

## User Stories

- As an AID adopter, I want the skill to tell me exactly which KB docs it will change (and which it won't) and let me confirm before it writes anything, so I never get more change than I asked for.
- As a KB owner, I want the skill to flag any contradiction between my instruction and the current KB and ask me, rather than silently "correcting" either side.
- As a maintainer, I want scope-fidelity enforced by the review gate, so an edit outside the confirmed scope fails rather than shipping.

## Priority

Must.

## Acceptance Criteria

- [ ] AC-1 No KB file is edited before `Confirmed: yes` exists in run-state (HL-1).
- [ ] AC-2 A pinpoint instruction yields a Scope Plan touching only instruction-traceable docs (+ confirmed closure); a domain-overlapping but uninstructed doc appears under Not-Changing (HL-2/HL-5).
- [ ] AC-3 An instruction contradicting the KB produces a CONFIRM question, not a silent edit (HL-4).
- [ ] AC-4 REVIEW hard-fails when the disk-derived edited-doc set ≠ Confirmed Scope (scope-diff guard).
- [ ] AC-5 The FIX loop and DONE closure check never edit a doc outside Confirmed Scope; a post-APPLY re-scope that shrinks Confirmed Scope reverts the now-out-of-scope edits (HL-7).
- [ ] AC-6 A new file is created only after appearing as `new-file` kind at CONFIRM (HL-6).
- [ ] AC-7 f005 quality gate, human-commit invariant, and FR-33/34 boundary intact; generated copies byte/path-parity clean.
- [ ] AC-8 An item ANALYZE cannot ground as CONFIRMED-from-instruction (a LIKELY/UNCERTAIN inference) is surfaced as a CONFIRM question, never applied silently (HL-3).
- [ ] AC-9 Content present in the session conversation but absent from the instruction and unsupported by KB/code evidence has no valid `Traces-to` and never enters the Scope Plan; the scope-deciding agents run in clean contexts that never receive the session transcript (HL-8).
- [ ] AC-10 The skill creates and enters its own worktree based on `master` before any analysis or edit; all run-state, edits, branch, and commits live in that worktree, isolated from the caller's working tree/branch.

---

## Technical Specification

### Governing hard limits (owner-confirmed)

Every state below cites the limits it enforces.

- **HL-1 No apply without confirmation.** No KB edit before the user confirms scope + understanding at CONFIRM.
- **HL-2 Limit to the scope of the instruction.** Scope Plan ⊆ what the instruction explicitly requests + *necessary closure* (e.g. a coined term's glossary entry) — and closure is **surfaced at CONFIRM, never silent**.
- **HL-3 No assumptions — surface, don't act.** The analyst may form hypotheses (LIKELY/UNCERTAIN) but anything not CONFIRMED-from-instruction is routed to CONFIRM as a question; never applied silently.
- **HL-4 Flag, don't resolve, contradictions.** Instruction-vs-KB conflicts are raised to the user; the skill never silently "corrects" either side.
- **HL-5 No opportunistic edits.** Docs that merely share a domain/tag, or are `suspect` per freshness but unnamed by the instruction, are out of scope (→ `aid-housekeep`).
- **HL-6 New files require explicit confirmation.** Allowed, never a silent side effect.
- **HL-7 Grade-chasing may not expand scope.** The REVIEW FIX loop and DONE closure re-check may only edit within confirmed scope; out-of-scope needs escalate to the user.
- **HL-8 The instruction is the only scope seed; the conversation is not a source.** Scope and content are grounded solely in the verbatim `/aid-update-kb` instruction plus KB/codebase evidence. Anything discussed earlier in the session is never a source of scope or content. Enforced by: (a) the skill runs in its own isolated worktree (Pre-flight) and ANALYZE/SCOPE run in **clean-context** sub-agents that never receive the session transcript; (b) the orchestrator passes the instruction **verbatim** and must not enrich it with session-derived context; (c) every Scope Plan item's `Traces-to` cites the instruction text or a KB/code location — never "the session" or prior discussion.

### Feature Flow (state machine)

**Pre-flight (before any state) — ISOLATE.** After confirming the prompt, the skill creates
and enters **its own worktree on an `aid/update-kb-<ts>` branch based on `master`** — plain git
worktree mechanics (`git worktree add <path> -b aid/update-kb-<ts> master`), entered via the
host-native switch (claude-code: the `EnterWorktree` tool; other profiles: operate with the
resolved path as cwd and surface it), reusing only the **generic enter contract** of
`.claude/aid/templates/worktree-lifecycle.md § Step 2`. It does **not** use
`worktree-lifecycle.sh`'s `create` path or `work-initiation-gate.md` — those are keyed on a
`work-NNN` id (hard-validated `^work-[0-9]+$`), which this off-pipeline maintenance skill does
not allocate: its run-state stays the timestamp-keyed `.aid/.temp/UPDATEKB_STATE_<ts>.md`
(FR-9), and its branch follows the existing `aid/update-kb-*` convention. This mirrors the
*isolation* `/aid-fix` gets at INTAKE, adapted to a non-work-NNN maintenance skill (the
`aid/housekeep-*` branch-per-run precedent, taken one step further to a full worktree). The
entire state machine, run-state, edits, the `aid/update-kb-<ts>` branch, and all commits then
live **inside that worktree**, isolated from whatever pipeline the caller was in. HL-8 covers
the companion context plane.

```
ANALYZE ──▶ SCOPE ──▶ CONFIRM ──▶ APPLY ──▶ REVIEW ──▶ APPROVAL ──▶ DONE
(research)  (plan)   (HUMAN GATE   (bounded) (quality +  (HUMAN GATE   (commit)
 aid-        aid-     -- pre-apply) edits)    scope-      -- pre-commit)
 researcher  architect                        fidelity)
                          ▲                       │
                          └──── adjust ───────────┘  (APPROVAL [2] re-scopes → CONFIRM/SCOPE)
                                                      (REVIEW FIX loop: within confirmed scope only)
```

Per-invocation pausing (natural pause points per `state-machine-chaining.md`):

| Invocation | Runs | Ends at |
|---|---|---|
| 1st | ANALYZE → SCOPE → CONFIRM | PAUSE (human confirms scope) |
| 2nd | APPLY → REVIEW → APPROVAL | PAUSE (human approves edits) |
| 3rd | DONE | HALT (commit + clean) |

This table shows the invocation boundary a `[2]`/`[3]` answer forces (a
genuine re-plan or cancel). A `[1]` answered inline does **not** force a new
invocation: CONFIRM/APPROVAL are inline human-decision points that CHAIN
straight through on `[1]` (per `state-machine-chaining.md` — a pause is
only for out-of-chat work, and answering a question inline is not that), so
a fully-happy-path run can drive ANALYZE all the way to DONE in a single
invocation with two inline Q&A breaks, not three separate invocations.

Two human gates by design (D1 resolved = two gates): **CONFIRM** guards
scope/understanding before work; **APPROVAL** guards the specific edits before commit.

#### Per-state behavior

- **Pre-flight / ISOLATE** (inline). Confirm the prompt, then create + enter the skill's own worktree on an `aid/update-kb-<ts>` branch off `master` — plain `git worktree add -b`, entered per `worktree-lifecycle.md § Step 2` (NOT the work-NNN-keyed `worktree-lifecycle.sh`; see Feature Flow note). Fail-closed: if the worktree can't be created, STOP — never fall back to the caller's tree. All subsequent states, run-state, and the `aid/update-kb-<ts>` branch live inside the worktree. CHAIN → ANALYZE.
- **ANALYZE** (`aid-researcher`, sonnet; read-only; **clean-context dispatch** — the agent receives only the verbatim instruction + KB/code, never the session transcript, HL-8). Locate the docs the instruction *actually concerns* via `INDEX.md` — not every tag-overlap candidate (removes today's `state-analyze.md §1` candidate net — the "Every doc whose Objective or Tags overlaps the prompt's domain is a candidate" sentence; HL-5). Record current KB statement + relation + confidence per location. Freshness verdicts are advisory only: `suspect` inside scope is noted; `suspect` outside scope goes to Not-Changing. Ungroundable items become Contradiction/Open-question entries (HL-3/HL-4). CHAIN → SCOPE (or existing un-groundable PAUSE escalation).
- **SCOPE** (`aid-architect`, opus; **clean-context dispatch**, HL-8). Build the minimal Scope Plan; include an item only if it traces to an explicit instruction clause or a closure need; mark `closure`/`new-file` kinds; fill the Not-Changing list; draft confirmation questions. HL-2/HL-5/HL-6/HL-8. CHAIN → CONFIRM (empty plan → existing "no update needed" HALT).
- **CONFIRM** (NEW; inline human gate — decision answered in-chat, not an out-of-chat pause per se). Present understanding + will-change + will-NOT-change + open questions. `[1] Confirm` → freeze `Confirmed Scope` + capture the pre-APPLY baseline (see Data Model), CHAIN → APPLY (inline, same invocation). `[2] Adjust: ___` → loop to SCOPE (or ANALYZE if understanding itself changes), PAUSE-FOR-USER-ACTION (a genuine re-plan needs a fresh clean-context SCOPE dispatch). `[3] Cancel` → HALT, clean. HL-1/HL-4.
- **APPLY** (inline `Edit`, or architect/researcher for deep docs). Apply only confirmed items; targeted in-place edits; the "not a rewrite" guard is repeated in the sub-agent dispatch prompt; cross-references only if they are confirmed items (removes the `state-apply.md §2b` open cascade — the "add cross-references as needed" clause). Retain calibration/altitude discipline, native-spine invariant, `approved_at_commit:` no-restamp rule. HL-2/HL-5. CHAIN → REVIEW.
- **REVIEW** (`aid-reviewer`, sonnet). **Scope-diff guard first (mechanical):** derive the *actually-edited* KB file set **from disk** — `git status --porcelain .aid/knowledge/` (or `git diff --name-only` against the pre-APPLY baseline recorded in run-state) — **never** from APPLY's self-reported `Edited Docs`; that disk-derived set MUST equal `Confirmed Scope`. A file changed on disk but absent from `Confirmed Scope` → **hard fail** (not gradable away); a `Confirmed Scope` doc not changed on disk → flag for reconciliation. **Traceability mandate (per edit / hunk-level):** each individual edit — down to the hunk — maps to a confirmed Scope Plan item; this catches over-editing *within* an in-scope doc that the file-level scope-diff guard cannot see (e.g. a whole new section added to a doc that legitimately received one small in-scope edit). Then the unchanged f005 four-mandate panel via `aid-discover/state-review.md`. **FIX-loop constraint (HL-7):** fixes only within `Confirmed Scope`; an out-of-scope-only fix routes to a user escalation (back to CONFIRM) instead of expanding. CHAIN → APPROVAL when scope-diff PASS AND grade ≥ min AND teach/act-back PASS.
- **APPROVAL** (inline human gate — decision answered in-chat, not an out-of-chat pause per se). Summary shows the disk-derived scope-fidelity result + a real diff pointer. `[1] Approved` → CHAIN → DONE (inline, same invocation). `[2] Additional consideration` → re-scope back to CONFIRM/SCOPE (fixes today's `state-approval.md:96-98` gap where it looped blindly to APPLY); PAUSE-FOR-USER-ACTION (same re-plan reasoning as CONFIRM `[2]`); the re-scope revert below runs before APPLY re-runs.
- **DONE** (inline). Restamp `approved_at_commit:`, commit on the **Pre-flight worktree's `aid/update-kb-<ts>` branch** (already created at Pre-flight — DONE creates **no** new branch, and **never pushes `master`**; the human merges after CI is green), clean run-state. **Change (HL-7):** a closure re-check shortfall that needs an out-of-scope addition **escalates to the user** rather than auto-pushing to APPLY. HALT.

**Re-scope revert (post-APPLY, HL-7 / AC-5).** When APPROVAL `[2]` or a REVIEW HL-7
escalation loops back to CONFIRM/SCOPE *after* APPLY has already written edits, any
working-tree edit to a doc dropped from the revised `Confirmed Scope` is reverted
(`git restore -- <doc>` against the pre-APPLY baseline) before APPLY re-runs — so the
working tree never carries edits broader than the current confirmed scope (the exact
failure mode this work closes).

### Data Model (run-state + artifacts)

Run-state file `.aid/.temp/UPDATEKB_STATE_<ts>.md` gains three artifact blocks plus a
baseline marker.

**Impact Map** (ANALYZE / aid-researcher):
```
**Understanding:** <plain restatement of what the instruction asks — the "correct understanding" to be confirmed>
**Impact Findings:**
| # | KB location (doc §, file:line) | Current KB statement | Relation | Confidence |
Relation enum: MATCHES | CONTRADICTS | MISMATCH | GAP | ABSENT
Confidence enum: CONFIRMED | LIKELY | UNCERTAIN
**Contradictions & open questions:** (HL-3/HL-4 — must be asked, not assumed)
- Q1: ...
```

**Scope Plan** (SCOPE / aid-architect; replaces today's `Change Plan`):
```
**Scope Plan:**
| # | Doc | Change-type | Description | Traces-to | Kind |
Kind enum: in-scope | closure | new-file
**Not-Changing:** (docs considered but excluded — HL-5)
- <doc> — <reason>
```
Change-type taxonomy retained (`New summary+pointer entry` / `Corrected fact` /
`New sources: entry` / `New concept on the spine` / `No change needed`); every entry MUST carry a `Traces-to`.

**Confirmation record + baseline** (CONFIRM):
```
**Confirmed:** yes
**Confirmed At:** <ISO-8601>
**Confirmed Scope:** <frozen doc set — the scope contract for APPLY/REVIEW>
**Pre-APPLY baseline:** <git rev of HEAD (or `clean` marker) captured at Confirm, before APPLY's first edit — REVIEW's scope-diff guard derives the edited-file set from disk relative to this, and the re-scope revert restores against it>
**Adjustments:** <free-text, or -->
```

Resume table gains `SCOPE` and `CONFIRM` rows; banners/diagram in
`SKILL.md § State Detection` updated to the 7-state machine.

### Layers & Components (agents + files)

Agents (pinned models, never inherit session): `aid-researcher` (sonnet) =
analyst/impact-map; `aid-architect` (opus) = minimal scope plan; `aid-reviewer`
(sonnet) = quality + scope-fidelity.

Verification controls:

| Control | Where | Type | Guards |
|---|---|---|---|
| Worktree isolation | Pre-flight (before any state) | mechanical | own worktree off master; no caller working-tree/branch bleed (AC-10) |
| Clean-context dispatch | ANALYZE + SCOPE | mechanical | scope-deciding agents never see the session transcript (HL-8/AC-9) |
| CONFIRM gate | before APPLY | human | HL-1 (root fix) |
| Scope-diff guard (disk-derived) | REVIEW (first) | mechanical | `git status`-derived edited-set == Confirmed Scope |
| Traceability mandate | REVIEW | reviewer | every edit → confirmed item |
| f005 four-mandate panel | REVIEW | reviewer | quality (unchanged) |
| FIX-loop scope bound | REVIEW | rule | HL-7 |
| Re-scope revert | CONFIRM/SCOPE re-entry | mechanical | tree never broader than Confirmed Scope (HL-7/AC-5) |
| APPROVAL gate | before commit | human | edit-level sign-off |
| Closure escalation | DONE | rule | HL-7 |

### State Machines

The 7-state machine above is the authoritative flow. Each `/aid-update-kb`
invocation drives it to the next natural pause (`state-machine-chaining.md`):
mechanical states CHAIN; only CONFIRM and APPROVAL PAUSE, and DONE HALTs.

### Migration Plan (edit target + propagation)

All edits under `canonical/skills/aid-update-kb/`, then re-emitted (generator →
`profiles/*` → setup.sh → dogfood `.claude/`); generated copies differ only by
the profile path-prefix rewrite.

| File | Change |
|---|---|
| `SKILL.md` | New **Pre-flight ISOLATE** step: create + enter own worktree on an `aid/update-kb-<ts>` branch off `master` via plain `git worktree add -b` + the generic enter step (`worktree-lifecycle.md § Step 2`) — **NOT** the work-NNN-keyed `worktree-lifecycle.sh`/`work-initiation-gate.md` — fail-closed, before any state; 7-state diagram + banners + resume table + Dispatch table; updated `description:`; new Hard-Limits section (HL-1..HL-8); update the "DONE (commit convention)" note to reflect the Pre-flight worktree branch (no separate branch at DONE; never push `master`); fix **all** `five-mandate`→`four-mandate` occurrences (frontmatter `:8` + REVIEW banner body + the "REVIEW reuse (f005)" blockquote), aligning with `state-review.md` |
| `references/state-analyze.md` | Rewrite: researcher Impact Map; remove tag-overlap net; freshness advisory only; contradiction/gap capture; no silent inference; **rename `Change Plan`→`Scope Plan`** in any residual reference |
| `references/state-scope.md` | **NEW**: architect minimal Scope Plan + Not-Changing + confirmation-question drafting |
| `references/state-confirm.md` | **NEW**: human gate `[1]/[2]/[3]`, freeze Confirmed Scope, capture Pre-APPLY baseline, PAUSE |
| `references/state-apply.md` | Bounded to confirmed plan; sub-agent inherits no-rewrite guard; remove open-ended cross-ref cascade; **rename the `Change Plan` read in APPLY Step 1 (`:30-33`)→`Scope Plan`** |
| `references/state-review.md` | Add disk-derived scope-diff guard + traceability mandate; FIX-loop scope bound (HL-7); **rename the `Change Plan` fallback reference (`:30`)→`Scope Plan`** |
| `references/state-approval.md` | Show scope-fidelity; `[2]` re-scopes to CONFIRM/SCOPE with re-scope revert |
| `references/state-done.md` | **Remove the existing Step 2 "Ensure branch" (`git checkout -b aid/update-kb-<date>`)** — the branch is the Pre-flight worktree's `aid/update-kb-<ts>` branch; DONE only commits on it (no new branch), commits/pushes are transparent, and it **never pushes `master`** (the human merges after CI is green). Closure shortfall → user escalation, not auto-expand (HL-7); **rename the `Change Plan` commit-template reference (`:111`)→`Scope Plan`**. (`approved_at_commit:` behavior unchanged.) |
| generated copies | Re-emit via generator → `profiles/*`; resync dogfood `.claude/` |

Post-change sweep (task-004): sweep **all source docs** (not only tests/fixtures) for
residual `Change Plan` references — specifically the `state-review.md` fallback and the
`state-done.md` commit template — and confirm none remain. Verify `.aid/settings.yml`:
`aid-update-kb` has no per-skill `update-kb` override, so its floor resolves to the
project's global `minimum_grade` (currently `A+`); the skill's hardcoded fallback is
`A`. This work does not change the floor; task-004 owns the verification.

### Design decisions (resolved)

- **D1 — one gate or two? RESOLVED = two** (CONFIRM for scope, APPROVAL for edits). Lighter alternative retained for the owner: auto-pass APPROVAL when scope-diff PASS + grade ≥ min. Trade-off: fewer pauses vs losing the final edit-level look.
- **D2 — ANALYZE + SCOPE two states vs one? RESOLVED = two** (researcher fact-find vs architect decision; auto-chain, so one user pause).
