---
delivery_state: Gated
gate_tier: Large
gate_grade: D
gate_timestamp: '2026-07-30T11:48:09Z'
ticket_ref: "--"
---

# Delivery State -- delivery-015

<!-- ZONES
  FRONTMATTER (single writer = this delivery's branch): delivery_state, gate_tier,
      gate_grade, gate_timestamp, ticket_ref.
  AUTHORED (single writer = this delivery's branch): the narrative remainder of
      Delivery Lifecycle / Delivery Gate, and Cross-phase Q&A.
  DERIVED (read-only, assembled at read time): Tasks State.
  Identifiers (Delivery / Work / Branch) are INFERRED from the folder name and git
  worktree -- never authored in frontmatter.

  Lifecycle enum: Pending-Spec | Specified | Executing | Gated | Done | Blocked
  Authored independently across the pipeline, NOT derived from task rollup:
    aid-plan    creates this file at Pending-Spec
    aid-specify advances to Specified
    aid-execute advances Specified -> Executing -> Gated -> Done, or to Blocked
-->

> **Delivery:** delivery-015
> **Work:** work-003-review-subsystem-redesign
> **Branch:** aid/work-003-delivery-015

---

## Delivery Lifecycle

<!-- AUTHORED -- single writer: this delivery's branch. The State scalar lives in the
     frontmatter above (delivery_state). -->

- **Updated:** 2026-07-30T19:31:56Z
- **Block Reason:** --
- **Block Artifact:** --

---

## Delivery Gate

- **Complexity Score:** 18 (tasks=6, depth=3, risk=9, consults=0) -> Large tier
- **Cycles:** 9. Grades D- -> D -> D -> D -> D+ -> D -> D+ -> D -> D; findings 13 -> 15 -> 8 -> 11 -> 6 -> 7 -> 9 -> 8 -> 8. The recorded Grade is cycle 9's, the last one actually measured.
- **Issue List:** all 85 findings across the nine cycles are FIXED and self-verified. Cycle 9's 8 fixes have NOT been graded by a fresh reviewer, so the current tree is ungraded. **Gate NOT passed** against the A+ minimum. Reasons and options: § Cross-phase Q&A, 'Why six cycles did not reach A+' (written at cycle 6; the diagnosis it records held through cycle 9) and § 'Method change at cycle 9'.
---

## Cross-phase Q&A

<!-- AUTHORED -- single writer: this delivery's branch (via the delivery-gate step of
     aid-execute). Written here, NOT into the shared work-level STATE.md, to preserve the
     disjoint-write property. -->

### Why six cycles did not reach A+ (2026-07-30) — needs a human decision

- **Category:** Process
- **Impact:** High
- **Status:** Open — gate not passed; awaiting a decision on how to close it

Six Large-tier cycles. Grades `D- → D → D → D → D+ → D`. Findings `13 → 15 → 8 → 11 → 6 → 7`. All 60
are fixed; cycle 6's seven fixes are self-verified but ungraded.

**The substance is sound, and every cycle re-confirmed it independently.** Each reviewer built its own
fixtures and *ran* the emitter and the checklist script, re-derived the coverage-parity inventory,
mutation-tested the suites' gate-criterion assertions (7–8 mutations per cycle, all caught), and
re-verified NFR-1 (`grade.sh` byte-identical to `7a9df485`), NFR-2 (render parity across all 8 trees,
byte-identity 755/755), and NFR-7 (one grade producer, repo-wide). Gate criteria 1–4, 6 and 7 hold.

**What kept the grade down was documentation coherence — and, materially, me.** Three of the findings
in cycle N+1 were *caused by* a fix in cycle N:

| Cycle | Introduced by the previous cycle's fix |
|---|---|
| 4 | `AC3e-2`'s pattern carried a literal `0x08` where `\b` was meant → the only mechanical guard for gate criterion 5 passed unconditionally |
| 5 | `SEV01`'s row *feed* still required backticked rule IDs, so the widened extraction read 0 rows in four of eight files |
| 6 | wiring `PRE-01` landed a literal `\n` instead of a line continuation → the emitter **aborted** under `set -u` and reported exit 1, the code for a *complete* run |

All three are the same root cause: **an escape written through a layer that consumed it.** Two guards
now exist for it (`CB01` control bytes, `CB03` literal `\n`), both mutation-tested. But the rate matters
more than the instances: while fixing ~10 findings a cycle I was creating roughly one, so further cycles
carry real risk of net harm rather than convergence.

**The other driver is structural.** This delivery rewrote ~20 interlocking prose surfaces that all
describe one workflow (VALIDATE → MANUAL-CHECKLIST → APPROVAL/FIX, plus the two discover gates). An A+
floor requires *zero* open findings at `[MEDIUM]` or above, and `grade.sh` is worst-severity dominated —
so one restated severity or one stale sentence anywhere in those twenty files pins the whole delivery at
`D`. Cycle 6's seven findings were: one crash (mine), one unreconcilable rule (mine, cycle 5), two
missing runbook steps, and three stale sentences. That is the shape of the residue, and it is not
converging to zero by iteration.

**Three ways to close it, for the human to pick:**

1. **Accept at the current grade, with the residue documented.** The scripts, tests and gates are
   verified; the open class is prose coherence in files that no test can bind. Records the honest grade
   rather than an engineered one.
2. **Narrow the gate's scope to what it can actually judge** — scripts, tests, rendered parity — and
   move the prose-coherence sweep to its own delivery with a lint that can enforce it (a "no severity
   restated beside a rule ID" check already exists as `SEV01`; the missing one is "no stale claim about
   what a script does", which needs a different mechanism than review).
3. **Keep cycling.** Cheapest to say, and the trajectory argues against it: six cycles, one grade step,
   and a fix-induced-defect rate near one per cycle.

**Recommendation: option 2.** It is the only one that changes the mechanism rather than the effort, and
it matches what this work has already concluded twice — that a claim about a script's behaviour needs a
lint, not a reviewer (feature-008's FR-G4, and Q16's "a gate that can never pass gets switched off").

### Resumed 2026-07-30 — what the handoff's "implementation complete" actually was

The prior session recorded task-003 as complete with 23/23 tests passing. Both halves of that were
true and neither was sufficient: the uncommitted tree held **task-003's de-score plus an incomplete
start on task-005's surface sweep**, and the test suite passed over defects it was not written to
see. Carried here so nothing is lost and nothing is claimed twice.

**Fixed under task-003 (its own scope):**

| # | Where | Defect |
|---|---|---|
| 1 | `manual-checklist.sh:224` | Interactive banner still printed `Scores K1 (10) + K2 (15) + V1 visual gate (5) = 30 pts.` — the retired model, in user-visible output, from the very script being de-scored |
| 2 | `manual-checklist.sh:252` | Prompt still read `HUMAN VISUAL GATE (mandatory, 5 pts)` |
| 3 | `manual-checklist.sh:213` | Non-interactive mode announced `scoring supplied answers` |
| 4 | `manual-checklist.sh:24` | Header still said `V1=n (0 pts)` |
| 5 | `state-approval.md:3` | `the grade meet the minimum` — agreement error introduced by the rewrite |
| 6 | `state-approval.md:15-17` | The three new rows broke the value-column alignment the rest of the block keeps |

**Why the test suite did not catch 1-4.** `MC01` greps for `^\s*(K1|K2|V1)_score=` and the three
`score_*()` definitions. All of those were genuinely gone, so it passed — while four score strings
survived in the same file, two of them the only thing a human running the script would actually see.
The suite's own header warns that "it is easy to write a test that passes because it looks at
nothing"; this is that, in the suite that warns about it. **task-006 must assert over the script's
output strings, not only its identifiers.**

**Open, and owned by later tasks in this delivery** (not fixed under task-003 — each is in another
task's declared scope):

| # | Where | Defect | Owner |
|---|---|---|---|
| 7 | `knowledge-summary/grading-rubric.md:70-71` | The check table still carries `**Machine total** \| **68**` and `**Human total** \| **30**` — the two-grade model's totals, live on a canonical surface. `TG01` misses them because it greps `Machine Grade`/`Human Grade`, not `Machine total` | task-005 |
| 8 | same, `:296-302` | An orphaned code block with no heading or lead-in, displaying the retired scored output (`15/15`, `5/5`, `2/2`) — left behind when the percentage-ladder section was deleted | task-005 |
| 9 | same, `:161-166`, `:213-219`, `:247-251`, `:69` | Point values surviving in the pass-criteria prose: `Full coverage (10/10)`, `Partial (5/10)`, `trivially passed (5/5)`, `Trivially passed (2/2)` | task-005 |
| 10 | same, `:212-219` | `D1`/`D2` still have live pass-criteria sections while `review-rubrics/summary.md` records them as **deleted** | task-005 |
| 11 | same, `:51`, `:160` | `K1` cites `discovery.doc_set`; `COV` at `:54` and `summary.md` cite `knowledge.doc_set`. One of the two is wrong | task-005 |
| 12 | `state-summary-delta.md:319` | Reads `diagram parse failure → auto-F on the human visual check` — a careless substitution that now asserts something false (a diagram parse failure is not the human visual check), and the line still says "Machine or Human grade" | task-005 |
| 13 | `state-fix.md:14-15`, `:26` | Still carries `D1`/`D2` repair entries for deleted checks, and an example reading *"K1 scored partial"* | task-005 |
| 14 | `review-rubrics/summary.md` mapping table | Omits `T1`, `T2`, `T3` and `NM` while claiming "Every check it scored is accounted for here". `T1`/`T2` appear only inside the `V1` row's note; `T3` and `NM` appear nowhere. `MP02` asserts 17 checks, so it cannot see the gap | task-004 (it owns the visual-gate split) |
| 15 | `review-rubrics/summary.md` Change Log | Says "Seven content-truth rules"; the file defines **nine** (`SUMMARY-01`…`09`) | task-004 |

### Two pre-existing defects the sweep turned up — recorded, deliberately NOT fixed here

Both were found by task-005's derived sweep, both predate this delivery, and neither is in its scope
(`## Scope` names the grading backend). Recorded with the evidence and the fix so the decision to
defer is visible rather than silent.

**A. `validate-visuals.mjs` has never been invoked by anything. [HIGH]**

Six surfaces describe the §7 visual-fidelity gate (T1/T2/T3) as part of VALIDATE, and
`state-validate.md` listed it as check **1 of 3** that `emit-summary-findings.sh` "orchestrates".
Nothing invokes it:

```bash
grep -rn validate-visuals canonical/ --include=*.sh --include=*.mjs   # only its own file
```

`emit-summary-findings.sh` runs `validate-html-output.sh` and `contrast-check.mjs`, and does the
coverage and retired-runtime checks inline. **The retired `grade-summary.sh` invoked the same two**
(`git show 7a9df485:...grade-summary.sh | grep -E '\.mjs|bash '`), so this delivery neither caused it
nor reduced coverage — the delivery gate criterion *"reduces no assertion"* holds. It is the same
false-wiring class this work already found twice: feature-007's frontmatter lint, and feature-008's
`quality-gates.md` claim that the citation lint runs in CI.

It also falsifies feature-007 SPEC §1c, which says the retained script *"Keeps: ... the four
validator invocations"*. There were **two**.

*Done here:* every surface now says the validator is available but not invoked, points at the manual
invocation, and names the mandatory human visual check as the live safeguard — which is the fallback
already specified for a host without Playwright. *Not done here:* wiring it. That is a behaviour
change, needs Playwright plus a real `kb.html` to test, and belongs to whoever owns the visual gate.

**B. 11 canonical `SKILL.md` files carry a dead relative link, and it ships. [MEDIUM]**

```bash
grep -rlc '](\.\./\.\./templates/state-machine-chaining.md)' canonical/skills/   # 11 files
grep -rlc '](\.\./\.\./aid/templates/state-machine-chaining.md)' canonical/skills/ # 2 files, correct
```

From `canonical/skills/<skill>/SKILL.md`, `../../templates/` resolves to `canonical/templates/`,
which does not exist; the file is at `canonical/aid/templates/`. `aid-create-ticket` and `aid-define`
use the correct `../../aid/templates/` form. **The renderer does not rewrite it** — the dogfood
`.claude/skills/aid-summarize/SKILL.md` carries the identical broken path — so it is dead in all five
profiles and both dogfood trees, i.e. shipped to adopters.

The fix is mechanical (`../../templates/` → `../../aid/templates/` in 11 files) and the delivery
re-renders anyway. Deferred regardless: delivery-015's gate criteria are all about grading, and
touching 11 unrelated skills inside it would make the diff unreviewable against those criteria.
**Raised for a scope decision rather than assumed either way.**

### AC-2 is satisfied BY the historical rows, not despite them

`.aid/knowledge/STATE.md` still records `| Machine Grade | A+ (grade-summary AUTO_POOL 68/68) |`,
`| Human Grade | A+ ... |` and `**Overall Grade:** A+` from a past run. Those are **left exactly as
they are, on purpose** — task-005's second acceptance criterion says historical recorded values stay
as history, because re-deriving a letter for findings that were never itemised would be fabrication.
The template that governs *future* writes (`discovery-state-template.md`) now emits `Grade` +
`Checklist`. Flagged here so the delivery gate does not read a deliberately-preserved record as a
missed surface.

**NFR-2 (five profiles) is discharged once for the delivery, not per task.** Tasks 001-002 left the
render un-run: `emit-summary-findings.sh` exists only in `canonical/`, and `grade-summary.sh` is
still present in all five `profiles/` trees and both dogfood trees (`.claude/`, `.cursor/`).
Rendering per task would publish incoherent intermediate trees — task-005's surfaces currently
contradict task-003's script. The render + dogfood sync therefore runs once, after task-005, before
task-006 and the gate. Task-003's "All section-6 quality gates pass" is satisfied at that point;
recorded here rather than ticked early.

### Method change at cycle 9 (2026-07-30) — fix the class, not the instance

Cycles 1-8 fixed what the ledger named and handed the rest back to the next reviewer. The evidence
that this was the actual cause of non-convergence, not bad luck:

| Fixed at | Found again at | The class that was never swept |
|---|---|---|
| cycle 8 — severities in `kb-dual-intent-probes.sh` | cycle 9 | the identical claim in its sibling `kb-actback-task.sh`, never grepped |
| cycle 6 — "forces grade <= D" in 4 places | cycles 8 **and** 9 | 4 more instances of the same sentence |
| cycle 8 — 3 control chars in `escape_json` | cycle 9 | 29 of the 32 C0 chars were still broken |
| cycle 7 — added `MC09` to hold that class | cycle 9 | the guard could not fail: its fixture held only already-handled chars |

From cycle 9 the FIX step is three obligations, not one:

1. **Sweep the class.** A finding names a defect *kind*; its Evidence bounds the *extent*. Grep the
   whole tree for the kind before touching the named instance.
2. **Run it, then mutate it.** Exercise every exit path of what was changed, and for each new guard,
   break the thing it guards and confirm the guard fails. A guard that has never failed is unproven.
3. **Discharge the coherence obligations the fix creates.** A changed contract has readers — the
   state docs, the rubric rows, the golden fixtures, the sibling script. Enumerate and check them.

What this produced at cycle 9: 4 classes swept tree-wide, 22+ mechanical guards now holding the
classes prose review had been re-catching each cycle (`test-one-grading-backend.sh` 23 -> 58
assertions), every exit path of both scripts exercised, and the two golden fixtures the changes
touched updated and re-verified. Cost: this cycle's self-review was longer than the reviewer pass it
precedes. That is the intended trade — the reviewer is a safety net, not the mechanism.

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEW
     Assembled at READ TIME from tasks/task-NNN/STATE.md. Never written here.
     ============================================================ -->

## Tasks State

<!-- DERIVED -- read-only rollup from tasks/task-NNN/STATE.md.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |
