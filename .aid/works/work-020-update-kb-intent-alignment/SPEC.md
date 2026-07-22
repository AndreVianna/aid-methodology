# aid-update-kb Scope-Fidelity Redesign

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-21 | SPEC drafted (redesign analysis) | direct session |
| 2026-07-21 | Reshaped to feature-001 SPEC template; folded design into Technical Specification | direct session |
| 2026-07-22 | GATE Pass 1 FIX: scope-diff guard derives edited set from disk; added re-scope revert; AC-8 (HL-3); robust citations; corrected settings floor note; migration rename rows | GATE FIX |

## Source

- REQUIREMENTS.md §5 Functional Requirements (FR-1..FR-10)
- REQUIREMENTS.md §9 Acceptance Criteria (AC-1..AC-8)
- Owner-confirmed hard limits HL-1..HL-7 (§2 below)

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

### Feature Flow (state machine)

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

Two human gates by design (D1 resolved = two gates): **CONFIRM** guards
scope/understanding before work; **APPROVAL** guards the specific edits before commit.

#### Per-state behavior

- **ANALYZE** (`aid-researcher`, sonnet; read-only). Locate the docs the instruction *actually concerns* via `INDEX.md` — not every tag-overlap candidate (removes today's `state-analyze.md §1` candidate net — the "Every doc whose Objective or Tags overlaps the prompt's domain is a candidate" sentence; HL-5). Record current KB statement + relation + confidence per location. Freshness verdicts are advisory only: `suspect` inside scope is noted; `suspect` outside scope goes to Not-Changing. Ungroundable items become Contradiction/Open-question entries (HL-3/HL-4). CHAIN → SCOPE (or existing un-groundable PAUSE escalation).
- **SCOPE** (`aid-architect`, opus). Build the minimal Scope Plan; include an item only if it traces to an explicit instruction clause or a closure need; mark `closure`/`new-file` kinds; fill the Not-Changing list; draft confirmation questions. HL-2/HL-5/HL-6. CHAIN → CONFIRM (empty plan → existing "no update needed" HALT).
- **CONFIRM** (NEW; inline human gate). Present understanding + will-change + will-NOT-change + open questions. `[1] Confirm` → freeze `Confirmed Scope` + capture the pre-APPLY baseline (see Data Model), CHAIN → APPLY. `[2] Adjust: ___` → loop to SCOPE (or ANALYZE if understanding itself changes), PAUSE. `[3] Cancel` → HALT, clean. HL-1/HL-4. PAUSE-FOR-USER-ACTION.
- **APPLY** (inline `Edit`, or architect/researcher for deep docs). Apply only confirmed items; targeted in-place edits; the "not a rewrite" guard is repeated in the sub-agent dispatch prompt; cross-references only if they are confirmed items (removes the `state-apply.md §2b` open cascade — the "add cross-references as needed" clause). Retain calibration/altitude discipline, native-spine invariant, `approved_at_commit:` no-restamp rule. HL-2/HL-5. CHAIN → REVIEW.
- **REVIEW** (`aid-reviewer`, sonnet). **Scope-diff guard first (mechanical):** derive the *actually-edited* KB file set **from disk** — `git status --porcelain .aid/knowledge/` (or `git diff --name-only` against the pre-APPLY baseline recorded in run-state) — **never** from APPLY's self-reported `Edited Docs`; that disk-derived set MUST equal `Confirmed Scope`. A file changed on disk but absent from `Confirmed Scope` → **hard fail** (not gradable away); a `Confirmed Scope` doc not changed on disk → flag for reconciliation. **Traceability mandate:** each edit maps to a confirmed item. Then the unchanged f005 four-mandate panel via `aid-discover/state-review.md`. **FIX-loop constraint (HL-7):** fixes only within `Confirmed Scope`; an out-of-scope-only fix routes to a user escalation (back to CONFIRM) instead of expanding. CHAIN → APPROVAL when scope-diff PASS AND grade ≥ min AND teach/act-back PASS.
- **APPROVAL** (inline human gate). Summary shows the disk-derived scope-fidelity result + a real diff pointer. `[1] Approved` → DONE. `[2] Additional consideration` → re-scope back to CONFIRM/SCOPE (fixes today's `state-approval.md:96-98` gap where it looped blindly to APPLY); the re-scope revert below runs before APPLY re-runs. PAUSE-FOR-USER-ACTION.
- **DONE** (inline). Restamp `approved_at_commit:`, commit on `aid/update-kb-*`, clean run-state. **Change (HL-7):** a closure re-check shortfall that needs an out-of-scope addition **escalates to the user** rather than auto-pushing to APPLY. HALT.

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
| `SKILL.md` | 7-state diagram + banners + resume table + Dispatch table; updated `description:`; new Hard-Limits section (HL-1..HL-7); fix the pre-existing `five-mandate`→`four-mandate` frontmatter wording (aligns with `state-review.md`) |
| `references/state-analyze.md` | Rewrite: researcher Impact Map; remove tag-overlap net; freshness advisory only; contradiction/gap capture; no silent inference; **rename `Change Plan`→`Scope Plan`** in any residual reference |
| `references/state-scope.md` | **NEW**: architect minimal Scope Plan + Not-Changing + confirmation-question drafting |
| `references/state-confirm.md` | **NEW**: human gate `[1]/[2]/[3]`, freeze Confirmed Scope, capture Pre-APPLY baseline, PAUSE |
| `references/state-apply.md` | Bounded to confirmed plan; sub-agent inherits no-rewrite guard; remove open-ended cross-ref cascade |
| `references/state-review.md` | Add disk-derived scope-diff guard + traceability mandate; FIX-loop scope bound (HL-7); **rename the `Change Plan` fallback reference (`:30`)→`Scope Plan`** |
| `references/state-approval.md` | Show scope-fidelity; `[2]` re-scopes to CONFIRM/SCOPE with re-scope revert |
| `references/state-done.md` | Closure shortfall → user escalation, not auto-expand (HL-7); **rename the `Change Plan` commit-template reference (`:111`)→`Scope Plan`** |
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
