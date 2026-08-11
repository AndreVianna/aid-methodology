---
pipeline:
  path: full
  initiator: aid-describe
started: "2026-07-27"
minimum_grade: "A"
user_approved: yes
lifecycle: Running
phase: Specify
active_skill: aid-specify
updated: '2026-08-10T14:56:42Z'
pause_reason: --
block_reason: --
block_artifact: --
ticket_ref: "--"
---

# Work State -- work-003-review-subsystem-redesign

Redesign of AID's review subsystem: extract review into chainable light/deep
review skills, formalize artifact-typed review criteria over a single severity
source of truth, and close the accumulated review-path defects.

> **State:** Running -- delivery-015 gate, FIX cycle 12 complete and awaiting a fresh reviewer
> **Phase:** Execute. Deliveries 001-012 gated `A+` with records; **013 and 014 were marked `Gated`
> with no gate ever run** (Q22) and their late gates are open with 24 findings between them;
> delivery-015's six tasks are all `Done` and its gate is at cycle 12. 016-018 are `Pending-Spec`.
> **Next:** `/aid-execute work-003` from worktree `.claude/worktrees/work-003` (branch
> `aid/work-003-delivery-015`) -- work the delivery-013 and delivery-014 ledgers, then re-gate all
> three deliveries.

---

## Pipeline State

<!-- AUTHORED -- values live in the YAML frontmatter block at the top of this file,
     written ONLY by `writeback-state.sh --pipeline ...` at every transition. -->
>
> Lifecycle enum:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
> Phase enum:        Describe | Define | Specify | Plan | Detail | Execute
> Active Skill enum: aid-{skill} | none

---

## Interview State

<!-- AUTHORED -- updated by `aid-describe` as each section is completed. -->

**Interview State:** Approved  **State:** Approved  **Grade:** Not graded (see note)

| # | Section | State | Last Updated |
|---|---------|-------|--------------|
| 1 | Objective | Complete | 2026-07-27 |
| 2 | Problem Statement | Complete | 2026-07-27 |
| 3 | Users & Stakeholders | Complete | 2026-07-27 |
| 4 | Scope | Complete | 2026-07-27 |
| 5 | Functional Requirements | Complete | 2026-07-27 |
| 6 | Non-Functional Requirements | Complete | 2026-07-27 |
| 7 | Constraints | Complete | 2026-07-27 |
| 8 | Assumptions & Dependencies | Complete | 2026-07-27 |
| 9 | Acceptance Criteria | Complete | 2026-07-27 |
| 10 | Priority | Complete | 2026-07-27 |

### Review History

| # | Date | Grade | Stage | Notes |
|---|------|-------|-------|-------|
| 1 | 2026-07-27 | -- | Feature Decomposition | 6 features created (pass 2; pass 1's 9-feature proposal rejected as over-decomposed) |

> All three blocking decisions landed 2026-07-27: two review skills (Q1),
> gap-sequencing in place of call-and-return (Q5a), and the criteria-vs-evidence
> boundary for greenfield (Q5d). Section 5 carries **37** FRs across 5 groups
> (A:8, B:8, C:11, D:9, E:1) -- an earlier "33" in this file was a miscount,
> corrected 2026-07-27 during FEATURE-DECOMPOSITION.
> Remaining Q1 items are design details for Define/Specify, not requirement blockers.

---

## Lifecycle History

<!-- AUTHORED -- append-only audit trail. Newest entry last. -->

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-27 | Work created | -- | Worktree `work-003` allocated via work-initiation-gate; NEW branch (work-001, work-002 unrelated) |
| 2026-07-27 | Describe started | -- | Pre-work reviewer analysis captured as Q1/Q2/Q3 below; requirements elicitation in progress |
| 2026-07-27 | REQUIREMENTS.md authored | -- | Consolidated Q1-Q6 into 10 sections; 30 FRs across 5 groups, 6 NFRs, 12 ACs; section 5 open pending Q1/Q5a/Q5d |
| 2026-07-27 | Describe complete (all 10 sections) | -- | Three blockers resolved: two review skills, gap-sequencing replaces call-and-return, criteria-vs-evidence greenfield boundary. 33 FRs. Ready for Define. |
| 2026-07-27 | REQUIREMENTS approved (human gate) | Not graded | User approved directly. **No reviewer was dispatched and no grade computed** -- the aid-describe REVIEW/grade step was not run. Recorded for honesty: this work's own requirements did not pass the review rigor the work exists to build. |
| 2026-07-27 | Define started | -- | Entered /aid-define work-003; State 5 FEATURE-DECOMPOSITION (no features/ yet) |
| 2026-07-27 | Decomposition proposed (9 features) | -- | aid-architect proposed 9 features covering all 37 FRs; corrected the FR count (was recorded as 33); 13 concerns raised, 4 blocking -- see Q7. Not approved -- challenged as over-decomposed. |
| 2026-07-27 | Decomposition rejected; requirements revised | -- | 3 FRs straddled feature boundaries (B5, C9, A8), 2 features held a single FR, and FR-C9 was scheduled to be built twice. Agent split decided (Q1), Q7#2 closed, FR-B5 split into B5a/B5b, FR-A9/A10/B9 added. REQUIREMENTS.md now carries 41 FRs. Re-decomposing at a merged count. |
| 2026-07-27 | Feature decomposition approved (6 features) | -- | All 41 FRs placed exactly once; no feature under 3 FRs; no straddling; no planned rework; FR-A10 solely owned by feature-006. 4 new concerns recorded (N1-N4). SPEC stubs written for all 6. |
| 2026-07-27 | KB meta-document update deliberately skipped | -- | Decomposition Step 5 asks to update `.aid/knowledge/INDEX.md` and `README.md`. Both are `source: generated`; INDEX carries an explicit DO-NOT-EDIT marker and a contract of one entry per KB document (a work reference would violate it). README's Revision History records *KB content changes*, and this work has changed no KB document yet. The README entry is owed when work-003's KB revisions (roster 9->10, architecture, decisions, agent-dispatch-tiering) actually land -- at ship, not at Define. |
| 2026-07-27 | CROSS-REFERENCE deferred; moved to Specify | -- | The CROSS-REFERENCE entry-point question was asked and not taken up -- the user invoked `/aid-specify` instead. aid-define's State 6 is therefore **not complete**; re-running `/aid-define work-003` returns to CROSS-REFERENCE. Proceeding to Specify is legitimate (the entry point permits declining), but the KB/codebase cross-validation of REQUIREMENTS.md and the six feature boundaries has not been run. 15 concerns already stand by hand in Q7 and Q8. |
| 2026-07-27 | Artifact inventory; feature-007 added | -- | Swept every artifact AID produces (persistent, generated, transient). Found AID already implements **five distinct review kinds** (A adversarial / B build-verify / C spot-check / D mechanical / E machine+human) never named as a set -- now FR-B11. Found 5 coverage gaps -> group F / feature-007. Work now has **7 features, 47 FRs**. |
| 2026-08-08 | `/aid-detail` REVIEW, deliveries 016-018 (cycle 7) | **A+** | **Zero findings, zero gaps, all nine `Examined`.** Gate clean, `grade.sh` computes `A+` over a durable ledger of 12 rows all `Fixed`. Bar is `B-`; **the review is DONE at cycle 7.** Grade path `C-` → `C` → `C` → `C+` → `C` → `C+` → `A+`. **What broke the oscillation was building the oracle instead of iterating the fix.** Cycles 3-6 each closed nearly every finding and opened ~1 new one that the fix itself created, so the loop sat between `C` and `C+`: a process injecting ~1 defect per pass cannot reach a bar requiring 0. Before this cycle a transient validator (scratchpad, not the repo) was written for the four shapes my own fixes had injected — re-run every embedded command and diff against the stated result; resolve every `§` anchor; resolve every cited path; find every deictic reference. **It found nothing in the artifacts and three defects in itself**, each caught only because it was tested rather than trusted: `resolve()` returned the first glob hit, so citations resolved into `profiles/` and `node_modules/` twins instead of `canonical/`; the exclude list was matched against absolute paths, and since the repo root itself contains `worktrees` and `.claude` it excluded the entire repository (25 spurious `PATH NOT FOUND`); and the owner-scoping loop took the first skill name in the window rather than the nearest, mis-resolving three correct citations. **A fifth check was written for the authority axis — the exact shape of cycle 6's defect — and mutation-proved VACUOUS**: replayed against the pre-fix text at `61f164f2^` it fired zero times, because Scope's "not" attached to a different object than AC-4's "wrong" and proximity cannot tell which. It was demoted from gate to reporter rather than tuned into a plausible-looking guess; the reviewer then checked that axis by reading, and found the repair correct. The reviewer independently confirmed only one file had changed since cycle 6 (`art=173715caa0f7`, the other eight byte-identical) and declined to register a candidate gap that `DEF-08`'s own Evidence cell already settles. **Two non-blocking criteria gaps remain `Pending`** and are unaffected by this grade: `definition/task-scope-already-discharged-on-disk`, `def09/whitespace-normalisation-in-quoted-strings`. **Deliberate deviation from § DONE:** the durable ledger and the cycle 2-7 scratch files are **retained, not deleted** — deleting them is precisely the defect `Q23` raises, and `Q23` is an open decision. |
| 2026-08-08 | `/aid-detail` REVIEW, deliveries 016-018 (cycle 6) | **C+** | **1** finding, down from 3, and the reviewer traced it to cycle 5's own fix: `2bc934f1` rewrote `016/task-001`'s Scope tail to check the regenerated paragraph against `.aid/settings.yml` and left AC-4 — which names `settings.yml` as the **wrong** authority for a `SUMMARY`-class object — untouched. That is the **fourth** self-inflicted defect in eight findings, and it confirms the diagnosis rather than refuting it: the artifact set is no longer the dominant defect source; edits to it are. **The pre-dispatch sweep did what it was added for, and its gap is now known.** Every repo claim in the two dense files was falsification-tested first — `017/task-002` returned **zero** findings for the first time since cycle 1, including the AC-3 grep (8 reference files + shortcut engine, exact), the residual set's five anchors, `feature-006 § 12`'s Tier-3 deferral and `feature-008 § 4`. It also caught a `DEF-06` **I introduced 60 seconds earlier**: a citation to `feature-006 SPEC § Tier 3`, an anchor that does not exist (the line is a bullet under `### 12. Out of scope`), corrected before dispatch. But the sweep checked *deixis* ("the criterion below") and *disk claims*, and not **authority agreement** — which is exactly the axis this finding sits on, and why it survived. Fixed by naming the authority AC-4 names; `F1` swept all nine files for the class (`017/task-003`'s two mentions carry no conflict, so the class is confined). **Disclosure: I corrupted the durable ledger mid-reconcile** — splitting the row on `\|` puts `Status` at index 3 and I wrote index 4, overwriting the `Rule` column on four rows. The file is untracked, so git could not restore it; repaired from the rule mapping extracted at session start and verified every row again reads `DEF-NN`. `Status` was never touched, so no grade depended on it. **Q23 opened**: the `(Doc, Rule)` join cannot distinguish a returned defect from a new one at the same key, and § DONE deletes the scratch files that are the only evidence its own non-improvement breaker needs. Grade path `C-` → `C` → `C` → `C+` → `C` → `C+`. |
| 2026-08-08 | `/aid-detail` REVIEW, deliveries 016-018 (cycle 5) | **C** | 3 findings, and **two of the three were defects the orchestrator introduced while fixing**: cycle 4's "the residual set is derived by running the command in the AC below" contradicted itself (that command derives the COVERED set), and cycle 3's "the KB it is generated from is already right" was false. Row 9's three-cycle recurrence finally closed. Two honest corrections to my own process this cycle. **(a) A bug in the reconciliation script**: it never applied `Fixed` → `Recurred`, so two findings landing on already-`Fixed` keys were not counted and the grade computed as `C+`; the true grade is `C`. Fixed and re-run. **(b) Overreach, reverted**: finding 1 exposed that `quality-gates.md` names this repo's key as `review.minimum_grade` where `.aid/settings.yml` carries a flat `minimum_grade` and no `review:` section. I corrected that one sentence — correct and in scope — but also edited the resolution-order tier and the `contracts:` block, then found `review.minimum_grade` is the established logical name in **20 sites including `read-setting.sh`'s own header**. Changing 1 of 20 is the inconsistency this work exists to prevent, and KB accuracy is explicitly out of this review's scope. Both edits reverted; the 20-site key-naming question is recorded here, not fixed. Grade path `C-` → `C` → `C` → `C+` → `C`: not converging, and the dominant source of new findings is now the fixes themselves. |
| 2026-08-08 | `/aid-detail` REVIEW, deliveries 016-018 (cycle 4) | **C+** | Loop inverted before dispatch, on owner instruction to fix the root cause rather than the instance: every repo-asserting sentence in all 9 files was enumerated and verified against disk FIRST (16 claims), so the reviewer would confirm rather than discover. That sweep found the class already closed and, applying F3, declined to "fix" two claims that turned out TRUE (the Lite path does complete the BLUEPRINT `## Tasks` table; `INDEX.md` class 6 does carry the cell form task-004 cites). Cycle 4 returned **1** finding, down from 3: delivery-012 scoped `aid-review` **in** as the ninth of nine caller migrations and closed `A+` with it undelivered — the task had it backwards as a deliberate exclusion. **The root cause was then addressed, not just the sentence.** Row 9's key `(017/task-002, DEF-09)` had recurred in cycles 2, 3 AND 4, a different false premise each time, all inside one 319-word Scope bullet — 5-13× every sibling — that litigated delivery-012's scope, feature-006's amendments and which SPEC said what. None of it was the task's work, and every sentence was `DEF-09`-falsifiable. Reduced to the operative boundary, 319 → 131 words, with the history left to `feature-008 § 4` which now states it correctly; all identifiers and § anchors re-verified. One new **non-blocking** gap: `def09/whitespace-normalisation-in-quoted-strings` — and notably that is delivery-017's own subject matter, so the decision belongs with its execution. Grade path `C-` → `C` → `C` → `C+`. |
| 2026-08-08 | `/aid-detail` REVIEW, deliveries 016-018 (cycle 3) | **C** | Cycle 2's rows 7 and 8 closed. 3 new findings, **all `DEF-09`** -- the rule added in cycle 2, on its first full pass, which is where a new rule is expected to earn out. One of the three was **introduced by the orchestrator**: correcting feature-008's SPEC mid-flight (to stop a truthful task grading as a `DEF-04` contradiction against a false upstream) invalidated the sentence the fixer had written *referencing* that SPEC's claim -- the F6 case, caught by the next cycle rather than by me. The other two are inherited premises that delivery-012's rewrite falsified: "the four reviews" (two of the four already name the BLUEPRINT) and "corrects the generator source" (no generator source carries the sentence; only the render does). All 3 fixed and oracle-verified. One **non-blocking** gap left open by design: `definition/task-scope-already-discharged-on-disk` -- awaiting a human decision, does not hold the grade. Grade path `C-` → `C` → `C`: **first non-improving cycle**; the breaker needs three consecutive before it trips. Rows stay `Pending` until cycle 4 reconciles. |
| 2026-08-08 | `/aid-detail` REVIEW, deliveries 016-018 (cycle 2) | **C** | Fresh reviewer, clean context, fresh scratch. **None of cycle 1's six recurred** — all nine units `Examined`, so reconciliation closed them `Fixed`. 2 new findings + 1 blocking criteria gap, answered: **`DEF-09` added** — a work artifact's factual claims about the repository must hold on disk. The hole was structural, not an oversight: `INDEX.md`'s ladder gives `TASK` an intent authority of SPEC/BLUEPRINT and a manner authority of the KB, so **the repository is on neither**, and a task asserting something false about the codebase was unreachable by `DEF-04`, `DEF-06` and `DEF-07` alike. Cites the same section `narrative.md`'s `NAR-01` does — Definition simply lacked the analogue. Its live instance became row 9, so the ledger closed at 3 open `[MEDIUM]` = `C`. All 3 fixed. The fixer corrected the orchestrator's own evidence in both directions: `aid-describe` **is** covered (transitively, via `aid-discover`'s panel — a `grep -rc` on its directory returns 0 and still misses it), and the uncovered set is larger than the finding named. Grade path `C-` → `C`: improving, so the non-improvement breaker has not tripped. Rows stay `Pending` until cycle 3 reconciles. **Cycle 3 not yet run.** |
| 2026-08-08 | `/aid-detail` REVIEW, deliveries 016-018 (cycle 1) | **C-** | 9 task `DETAIL.md` files re-reviewed against the current PLAN, SPECs and rubrics -- they were authored 2026-07-28 and never revised, while 34 commits landed on `canonical/` beneath them. Bar `B-`; 4 findings + 2 blocking criteria gaps, both answered by the human and registered. Gaps resolved: `DEF-01` scoped OUT of task criteria (checkboxes stay plain), and **`DEF-08` added** -- a delivery's gate criteria must each be discharged by at least one task, which the reviewer brief demanded while the catalog could not express it. `DEF-08`'s two live instances then became findings 5-6, so the ledger closed at 6 `[MEDIUM]` = `C-`. All 6 addressed by `aid-architect`; rows stay `Pending` until the cycle-2 reviewer reconciles them. **Cycle 2 not yet run.** |
| 2026-08-07 | delivery-015 gate cycle 12 FIX (part 2) | -- | Part 1 (`d4af0528`) built the derived-value guard but closed only a subset of the class, and the guard was blind to every instance that survived. Both guards extended and mutation-proved (`DV12`-`DV14`, `SC02`-`SC05`); 7 stale sites fixed; `KB-02`/`NAR-08`/`EXE-09` moved `SHOULD` -> `MUST` with their severity anchors, which re-sequenced row 4 behind row 7 and invalidated a third ledger-schema example the reviewer had cleared. 9 of 9 cycle-12 rows `Fixed`; `kb.html` extent handed to delivery-016 (generated artifact, its declared scope); 11 pre-existing exit-code-header violations recorded as tech-debt `W3-1`. Ungraded until a fresh reviewer runs. |
| 2026-07-27 | feature-001 spec **Ready** | **A+** | Authored 9 adapted sections, then 4 review cycles: **C+** (2 findings) -> **D+** (fix introduced a false positive in the AC-1 oracle) -> **B+** (fix left `quality-gates.md` uncovered, since its definition is prose not a heading) -> **A+** (0 findings). Every finding across all four cycles landed in §8's verification oracles -- the prose sections were clean from cycle 1. Ledger `specify-feature-001.md` deleted per schema at DONE; this row is the audit record. |

---

## Deploy State

<!-- AUTHORED -- written ONLY by `aid-deploy`. -->

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|-----|-------|
| _none yet_ | | | | | |

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     Assembled at READ TIME from per-delivery and per-task STATE.md files.
     NEVER written directly.
     ============================================================ -->

## Features State

<!-- DERIVED -- assembled from features/{feature}/SPEC.md progress.
     NOTE (defect, 2026-07-27): the work-state template marks this section DERIVED and
     "never written here", but `aid-specify/references/state-initialize.md § Step 3`
     instructs the skill to write Feature State rows into it, and aid-specify's State
     Detection reads them from here. Same defect class as the `## Tasks Status` write
     target found in the reviewer agent. Written here per the operative skill
     instruction; logged for the Q3 defect backlog. -->

| # | Feature | Spec State | Spec Grade | Sections | Started | Notes |
|---|---------|------------|------------|----------|---------|-------|
| 1 | feature-001-severity-single-source | **Ready** | **A+** | 9 | 2026-07-27 | 5 FRs (B7 cut); AC-1, AC-2. Spec authored + reviewed to A+ in 4 cycles (C+ -> D+ -> B+ -> A+). Recommends splitting into 2 deliveries at Plan. |
| 2 | feature-002-review-rubric-catalog | **Ready** | **A+** | 14 | 2026-07-27 | 5 FRs (B4, B5b, B9, B10, B11); AC-3. A+ in 3 cycles (D+ -> C+ -> A+). Recommends 3 deliveries at Plan. |
| 3 | feature-003-ledger-substrate | **Ready** | **A+** | 10 | 2026-07-27 | 3 FRs (D1-D3); AC-9. A+ in 3 cycles (D -> D+ -> A+). Took the AC-3 enforcement duty and the mixed-shape rule; declined the FR-D5 actor rewrite to feature-005. Recommends 2 deliveries. |
| 4 | feature-004-criteria-gap-interrupt | **Ready** | **A+** | 12 | 2026-07-27 | 12 FRs; AC-4, AC-5, AC-10. A+ in 3 cycles (C+ -> B -> A+). Owns FR-D9 (promoted to MUST). 37 files, 2 new scripts, 18-site gate. Recommends 3 deliveries. |
| 5 | feature-005-review-resume | **Ready** | **A+** | 13 | 2026-07-27 | 4 FRs (D4-D7); AC-6, AC-7, AC-8. A+ in 2 cycles (C+ -> A+). Discharged feature-003's lifecycle-rewrite debt as an AC. Amended feature-003's `U-` row Evidence contract (art=/rs= digests). Recommends 4 deliveries. |
| 6 | feature-006-review-skills | **Ready** | **A+** | 12 | 2026-07-27 | 11 FRs (**FR-A7 cut**) + FR-C9 + FR-E1; AC-11, AC-12. A+ in 3 cycles (B -> B+ -> A+). Proved the boilerplate split is **byte-identical** -- N1's blast radius collapses to a zero-diff assertion. Recommends 5 deliveries. |
| 8 | feature-008-citation-accuracy | **Ready** | **A+** | 8 | 2026-07-28 | 5 FRs (group G); AC-14. **Added post-Specify** -- see Q14. Extends `kb-citation-lint.sh` to work artifacts. A+ in **9 cycles**, the most of any feature, and 18 findings of which **one was itself wrong**. Collides with nothing; **D1 depends on nothing and gates nothing**, so it could ship first. |
| 9 | feature-009-review-effectiveness | **In Discussion** | Pending | 8 | 2026-08-10 | **Added post-Plan 2026-08-10** -- see Q28/Q29. Owns group H (FR-H1-H3, recall measurement) and FR-E2 (the class sweep). `SPEC.md` authored 2026-08-10 following the `feature-008` precedent (Q14): requirements half plus `## Technical Specification` in 8 sections, on the Q31 two-lane decision. Awaiting REVIEW. Discharges the review-path slice of tech-debt `L4`; `L4` itself stays open. Deliveries 024, 025 and 027 cannot be detailed until this reaches `Ready`. |
| 7 | feature-007-review-coverage-gaps | **Ready** | **A+** | 12 | 2026-07-27 | 6 FRs (group F incl. FR-F6). A+ in **6 cycles** (C+ -> C+ -> B+ -> B+ -> B+ -> A+) -- the longest of the work, every finding a citation or count defect. Applied 5 amendments to features 002 and 006. Recommends 5 deliveries. |

## Plan / Deliveries

<!-- DERIVED -- assembled from delivery-NNN/STATE.md lifecycle fields. -->

| Delivery | State | Tasks | Notes |
|----------|-------|-------|-------|
| _none yet_ | | | |

## Tasks State

<!-- DERIVED -- assembled from per-task STATE.md files.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Delivery Gates

<!-- DERIVED -- union of each delivery-NNN/STATE.md ## Delivery Gate section. -->

_None yet._

## Deferred Findings — [LOW] / [MINOR], swept at end of work

<!-- WORK-OWNER-AUTHORED. Created 2026-07-30 when the gate bar moved to B-.

     These rows are DEFERRED, NOT WAIVED. `.aid/.temp/review-pending/` is transient and is
     deleted at DONE, so a deferred row that lives only in a ledger is a lost row. Every
     [LOW]/[MINOR] a delivery gate leaves open gets copied here, verbatim in its ledger
     columns plus the delivery it came from, and is discharged in one sweep before the work
     ships. The work is NOT shippable while any row here is Pending. -->

**Bar: `B-` (set 2026-07-30, `.aid/settings.yml`).** Measured on `86eb7584`: `grade.sh` is
worst-severity-dominated with a 3-band count modifier, so one `[MEDIUM]` caps a ledger at `C+`
however few there are (8 `[LOW]` + 1 `[MEDIUM]` = `C+`), while a `[LOW]`-only ledger bottoms
out at `B-` however many (`[LOW]` ×1 → `B+`, ×2–5 → `B`, ×6+ → `B-`). `B-` is therefore the
lowest bar whose entire band excludes `[MEDIUM]`, and the bar and the intent — "no `[MEDIUM]`
or worse; `[LOW]`/`[MINOR]` at the end" — are the same statement.

| # | Severity | Rule | Doc | Line | Description | From | Status |
|---|---|---|---|---|---|---|---|
| 1 | [LOW] | EXE-08 | canonical/aid/scripts/summarize/emit-summary-findings.sh | 122 | Twelve globals are lowercase where `coding-standards.md § Naming Conventions` reserves lowercase for locals (`missing_docs`, `stem`, `doc`, `d`, `vrc`, `crc`, `unresolved`, `claimed`, `k`, `fail_line`, `pair`, `theme`/`detail`) -- and `missing_docs` is **dead**: `grep -n missing_docs` returns two lines, both writes (`:122` initialises, `:150` appends), so the accumulator is built and never consumed. Confined to one file, so the `>1 file` escape does not apply: `manual-checklist.sh`'s globals are all UPPER_SNAKE. | delivery-015 gate cycle 11, row 13 | Pending |

## Criteria Gaps

<!-- AUTHORED by gap-register.sh, never by hand. Section created by hand on 2026-07-30 because
     this work predates the template that introduced it, and the writer does not create it --
     see Q18. Cell contracts: work-state-template.md ## Criteria Gaps.

     A criteria gap is "there is no rule to judge this by" -- a missing PRECONDITION of the
     review, not a defect in the artifact.

     Status: Pending | Answered | Declined | Superseded   (Declined is a recorded "no")
     Kind:   criteria | evidence                          (only `criteria` gates a grade) -->

| Gap Key | Kind | Status | Depth | Recurrences | Scope | Criterion | Resolution |
|---|---|---|---|---|---|---|---|
| scripts/temp-file-lifecycle-and-destructive-paths | criteria | Answered | 0 | 0 | delivery-015 gate cycle 10, row 7 (`EXE-04`) -- `canonical/aid/scripts/summarize/emit-summary-findings.sh` validator-timeout branch | No KB document declares a rule for **trap-scoped temp-file cleanup** or for **guarding a destructive path against a device node**. `coding-standards.md § Security Conventions` covers download integrity, manifest-driven removal and secret handling; `§ Error Handling` covers exit codes, message content and `\|\| true`. Neither reaches the defect found: the branch rebound `HTML_LOG=/dev/null` after a single-quoted `trap 'rm -f "$HTML_LOG"' EXIT` was installed, so the trap ran `rm -f /dev/null` and the real `mktemp` file leaked (measured under `bash -x`). | 2026-08-09, human decision: ADD THE RULE. Resource cleanup is the same category as EXE-05 (exit codes) and EXE-07 (error handling) -- script correctness -- and without a rule a reviewer who finds the bug cannot write it down, because the No-Criterion-no-row contract forbids a finding with no rule ID. Premise verified as still holding: no KB section and no rubric rule covers trap-scoped temp-file cleanup or guarding a destructive path; EXE-12, EXE-13 and authoring-conventions.md sec Generated and Temporary Files are all manifest-driven deletion of DIRECTORIES, not a script's own mktemp file. TWO STEPS REQUIRED, unlike DEF-08/DEF-09 which cited sections that already existed: (1) author the convention in coding-standards.md sec Shell (Bash) Conventions via aid-update-kb -- it currently carries six bullets, none about temp files or traps; (2) add EXE-14 to review-rubrics/executable.md citing it. Live exposure, measured 2026-07-30: of 21 scripts calling mktemp, 18 installed an EXIT trap and 3 did not (execute/write-control-signal.sh, housekeep/housekeep-state.sh, migrate/migrate-work-hierarchy.sh), each rm -f-ing only on the happy path. Re-measured 2026-08-10 after the master merge: 27 call mktemp and 24 install a trap -- the exposed set is still exactly those same 3 files, which is the figure the decision rests on. delivery-019 states its criterion as the invariant rather than a count for this reason. Original instance (emit-summary-findings.sh single-quoted trap expanding a rebound value to rm -f /dev/null while the real temp file leaked) is fixed and never shipped. NOT YET IMPLEMENTED -- needs a delivery to carry it. // 2026-07-30: the **instance** is fixed (the rebind is gone; it was dead anyway, since the branch that runs on rc=124 never reads the log). The **criterion** is still missing, so a reviewer meeting the next instance has no rule to cite -- cycle 10 filed the finding under `EXE-04` (the branch is untested, with the bug as its Evidence) rather than invent a rule for the bug itself. Pending, not Declined: unlike the essence-coverage gap this has had no human decision. Registered BY HAND, not by `gap-register.sh`, because that writer still finds its section by substring (Q18) and would append into prose. |
| kb-anatomy/intent-edge-case-term-coverage | criteria | Answered | 0 | 0 | delivery-015 gate cycle 12, row 4 (`NAR-05`) -- `canonical/skills/aid-discover/references/reviewer-prompt-anatomy.md` § Anatomy / Coverage checklist, items 1, 4 and 6 | No rule in any `review-rubrics/*.md` declares a criterion for **coverage against a document's declared `intent:`**, for a **missing edge case / failure mode**, or for an **undefined project-specific term** within a document's own scope. Each of the three checklist items states its own `[MEDIUM]`, and the file's "Severity anchors" block claimed every value in it was the anchor of a cited rule -- false for exactly these, because they cite none. | 2026-08-09, human decision: ALL THREE BECOME RULES -- add the two that already have criteria, AND author a criterion for the third rather than leaving it open. Rationale: the No-Criterion-no-row contract makes all three unwritable as findings today, so a KB reviewer performing a check it was told to perform can only re-register the same gap cycle after cycle; that is the condition delivery-015 was chartered to remove. (1) CONTENT-VS-DECLARED-PURPOSE -- criterion already exists at kb-authoring/review-rubric.md sec Rubric: Full Primary item 2, a source review-rubrics/kb.md already cites 11 times. SUB-DECISION INCLUDED: the criterion is keyed to intent:, a SUPERSEDED frontmatter field absent from 8 of 21 KB docs when measured 2026-08-09 (9 of 22 on 2026-08-10, after the master merge added a doc; 13 carry it, which is the figure delivery-019's gate criterion states) and unchecked by lint-frontmatter.sh, so the rule is pointed at objective:/summary: and item 2 is updated to match -- writing a rule against a retiring field would be dead on 8 docs, and leaving the criterion saying intent: while the rule says objective: would invent a criterion by the back door. (2) UNDEFINED PROJECT-SPECIFIC TERM -- criterion already exists at authoring-conventions.md sec Dual-Audience Standard, the same section KB-08 cites. Expect modality SHOULD -> [LOW] escaped (>1 doc) -> [MEDIUM], matching its peer bullets KB-05..KB-08, which LOWERS it from the [MEDIUM] the checklist self-declares; also reconcile the predicate mismatch (KB says define in domain-glossary.md, the checklist flags a term undefined within the doc's own scope). (3) MISSING EDGE CASE / FAILURE MODE -- no criterion exists, so one is AUTHORED as a new item 11 in kb-authoring/review-rubric.md sec Rubric: Full Primary, the same section item 1's criterion comes from and already an admissible source; the rule then cites it. NOT reframed onto KB-24, which would raise severity [MEDIUM] -> [HIGH] and is act-back-scoped (state-review.md counts AB- rows matching ^KB-2[0-6]$). Free IDs: KB-10..KB-19, KB-27+. Residual to clear when implemented: reviewer-prompt-anatomy.md lines 60-62, 71-72, 77-81 still declare [MEDIUM] on the reviewer's own authority. NOT YET IMPLEMENTED -- needs a delivery to carry it. |
| kb-essence/load-bearing-fact-coverage | criteria | Declined | 0 | 0 | aid-discover essence gate, condition 2 (Omission) -- canonical/skills/aid-discover/references/state-review.md § 2c | No KB document declares that the Knowledge Base must carry the project's load-bearing source facts. The Divergence half of the gate maps onto NAR-05; the Omission half has no declaring criterion, so review-rubrics/INDEX.md's No-Criterion-no-row contract forbids authoring a rule row for it. | 2026-07-30, human decision: leave the Omission condition keyed on the [ESSENCE-GAP] Description marker and record the gap rather than invent a rule ID or pause delivery-015 for a KB edit. Declined, not Pending -- the decision is made, so this must not be re-asked and must not gate a grade. Reopening it means adding the standard to the KB authoring conventions via /aid-update-kb, then re-pointing condition 2 at the new rule; task-004's second acceptance criterion is therefore closed for the act-back gate and the Divergence half, and open for this half. |
| def01/modality-scope-task-detail-acs | criteria | Answered | 0 | 0 | aid-detail REVIEW, delivery-016/017/018 task DETAIL.md files (detail-016-018 cycle 1, G-002) | Three declared sources disagree on whether a task DETAIL acceptance criterion carries a Modality: DEF-01's Check says 'every requirement and acceptance criterion' while its Evidence reads AC tables; artifact-schemas.md Task DETAIL.md mandates plain testable checkboxes; lint-modality.sh --root discovers only REQUIREMENTS.md and SPEC.md; and task-detail-template.md gained no Modality table when feature.md and requirements.md did on 2026-08-08. If DEF-01 reaches task files, all 9 artifacts violate it. | 2026-08-08, human decision: task acceptance criteria stay PLAIN CHECKBOXES. DEF-01 is scoped to requirements and feature criteria, with the exclusion stated in the rule and cited to artifact-schemas.md. Rationale: a task criterion inherits its weight from the requirement it serves, so tagging it again is a second place for that value to drift. No back-fill of the ~70 existing task files; task-detail-template.md and the linter's discovery set are unchanged and now agree with the rule. |
| definition/task-set-discharges-upstream-obligation | criteria | Answered | 0 | 0 | aid-detail REVIEW, delivery-016/017/018 task DETAIL.md files (detail-016-018 cycle 1, G-001) | review-rubrics/definition.md declared no rule for universal taxonomy class 3 (Unmet criterion) applied to a delivery's own gate criteria, so an obligation that NO task in the delivery discharges could not be written as a finding. The /aid-detail reviewer brief demanded exactly that check ('Every delivery gate criterion is discharged by at least one task') while the catalog could not express it. Two live instances: delivery-016 BLUEPRINT's Inherited defect (kb.html:3408) carried by neither task, and delivery-017 BLUEPRINT's 'AC-14 holds on fixtures failing in both directions' carried by none of its four. | 2026-08-08, human decision: add the missing rule. DEF-08 added to review-rubrics/definition.md, citing INDEX.md universal taxonomy class 3 (Unmet criterion) exactly as DEF-04 cites class 2, so no criterion is invented. MUST / judgment / Step 2, banded one-confined -> [MEDIUM], several -> escaped -> [HIGH]. Verified by SEV05 (85 catalog rows, all in band -- the same figure `Q2`'s Answer gives for the catalog, `INDEX.md` plus nine class files). The two live instances now grade as ordinary DEF-08 findings. |
| definition/work-artifact-claim-contradicted-by-disk | criteria | Answered | 0 | 0 | aid-detail REVIEW cycle 2, delivery-016/017/018 task DETAIL.md files (G-001) | Nothing in the Definition family lets a reviewer report that a task DETAIL's Scope prose states a repository fact that disk contradicts, when every identifier in it resolves. INDEX.md's per-class ladder gives TASK an intent authority of SPEC/BLUEPRINT and a manner authority of the KB, so the repository is on neither: DEF-04 needs a higher-authority artifact, DEF-06 only asks whether identifiers resolve, and DEF-07's declaring section is scoped to KB primary docs. Live instance: delivery-017 task-002's Scope claims one aid-deep-review RESOLVE site covers 'every definition skill plus aid-review plus the shortcut engine', while grep -c aid-deep-review over aid-review/SKILL.md and aid-describe/ both return 0. | 2026-08-08, human decision: add the rule. DEF-09 added to review-rubrics/definition.md -- every factual claim a work artifact makes about the repository holds on disk. MUST / judgment / Step 2. Cites authoring-conventions.md § Citation Rule (Durable Anchors), the same section narrative.md's NAR-01 cites: the narrative family already carried this rule and Definition simply lacked its analogue, so no criterion is invented. Resolution is DEF-06; truth is DEF-09. |
| definition/task-scope-already-discharged-on-disk | criteria | Declined | 0 | 0 | aid-detail REVIEW cycle 3, delivery-016/017/018 (G-001, NON-BLOCKING) | review-rubrics/definition.md has no rule saying a task's Scope item and its acceptance criterion must name work not ALREADY discharged on disk. DEF-08 is the inverse case (a criterion no task carries) and DEF-09 needs a falsifiable claim, which a bare Scope noun phrase does not make. Live instance: delivery-016 task-001 Scope bullet 3 and AC-3 ('The registry states both kinds for this class') were already satisfied when the task was written -- review-rubrics/INDEX.md:179 reads '\| `SUMMARY` \| **A + E** \|', introduced by commit 0dc1fa56 closing delivery-004. | 2026-08-09, human decision: DECLINED. No rule is added for a task whose Scope and acceptance criteria were already satisfied on disk when written. The delivery gate still checks the criterion, so a pre-satisfied task costs wasted motion rather than a defect, and a new judgment rule is added surface for a review loop that took seven cycles to stabilise. The live instance (delivery-016 task-001 Scope bullet 3 and AC-3, satisfied by review-rubrics/INDEX.md:179 via commit 0dc1fa56) stands as written. Must NOT be re-raised by a reviewer. // SUPERSEDED by the decision above; retained as the record of what was open -- Raised 2026-08-08 as [GAP:CRITERIA:NB] -- deliberately non-blocking, so it does not hold the grade. Two options the reviewer put: (a) add a Definition-family rule 'a task's Scope and acceptance criteria name work not already discharged on disk', MUST/judgment/Step 2, declared against pipeline-contracts.md § Phase Input/Output Contracts (the criterion DEF-02 already cites); or (b) Decline, on the grounds that a criterion satisfied early is harmless because the delivery gate still checks it. Awaiting a human decision; must NOT be re-asked by a reviewer in the meantime. |
| def09/whitespace-normalisation-in-quoted-strings | criteria | Answered | 0 | 0 | aid-detail REVIEW cycle 4, delivery-018/task-002 (G-001, NON-BLOCKING) | No declared rule says whether a quoted string reproduced in a work artifact must match its source byte-for-byte in WHITESPACE. delivery-018/task-002 quotes 'artifacts: PLAN.md and every delivery BLUEPRINT.md' with one space where both aid-plan files carry five, so a literal grep -c returns 0/0 while the label-free fragment returns 1/1. AC-14 and delivery-017/task-001 mandate EMPHASIS normalisation and are silent on whitespace, so DEF-09 can be neither applied nor dismissed. | 2026-08-09, human decision: FORMAT DOES NOT MATTER, MEANING DOES. Whitespace does not matter; neither does exact wording, emphasis, or any other formatting or irrelevant detail. The criterion for an attributed quote is SEMANTIC FIDELITY -- the quoted content must mean exactly what the source intends. A reworded quote that preserves the source's meaning is correct; a byte-perfect quote that misrepresents intent is the defect. This answers the whitespace question by dissolving it: normalisation rules (whitespace, emphasis) are the wrong axis entirely. The delivery-018 task-002 instance ('artifacts: PLAN.md and every delivery BLUEPRINT.md', one space vs five) is therefore NOT a defect -- the meaning is identical. CONSEQUENCE, exposed not decided: feature-008's FR-G3 is a literal substring check with emphasis/whitespace normalisation, which cannot express semantic fidelity; the same disposition FR-G4 already took (SPEC section 3, 'a review rule, not a lint check') is now an open question for FR-G3. Raised as Q25. |
| def06/code-span-wrapped-mid-token | criteria | Declined | 0 | 0 | plan-019-023 | Whether a markdown code span may wrap across a line boundary inside a path, and if not, which document declares it so DEF-06 can cite it. | Declined as a rule 2026-08-10: the single instance (delivery-021 Scope, a path split across lines inside backticks) was reflowed, and a second span wrapping at a space inside a section name was reflowed with it. Not worth a new authoring convention on one occurrence -- a wrap at a space renders identically, and only a wrap mid-token corrupts the citation. Re-open if a second mid-token instance appears. |
| definition/scope-item-untested-by-gate-criteria | criteria | Declined | 0 | 0 | plan-019-023 | Whether a delivery BLUEPRINT Scope bullet that no gate criterion tests is a reportable finding. DEF-08 is the inverse (a criterion no task discharges) and is scoped to tasks, not to a delivery's own Scope-to-criteria correspondence, so the Definition family declares no rule for this direction. | Declined 2026-08-10 as an ORCHESTRATOR disposition during the work-003 plan review, NOT a human ruling -- recorded here because it was being cited to reviewers as settled while no register row existed, which is precisely the drift the register prevents. Grounds: a delivery gate is a judgment gate, not a checklist join, so a Scope bullet without a matching criterion is a completeness question for the gate reviewer rather than a rule violation; and the inverse direction (a criterion no Scope bullet covers) is already reportable as DEF-04. Reopen for a human decision if a delivery ships scope that its gate demonstrably never examined. |
| routing/work-state-authored-sections-rule-set | criteria | Declined | 0 | 0 | plan-019-023 | review-rubrics/INDEX.md routes any STATE.md to class STATE, kind C (spot-check, no rule rows), and the Definition family's members are REQ / SPEC / PLAN-BLUEPRINT / TASK. So when a review is scoped to a work STATE.md's AUTHORED sections -- a Q&A answer, the Criteria Gaps register -- no rule set carrying rule IDs formally governs them, and a real defect there is unwritable as a graded finding. Related: definition.md declares a rule for universal taxonomy classes 2 (DEF-04), 3 (DEF-08), 4 (DEF-05) and 5 (DEF-06) but none for class 1 (Contract violation). | Declined 2026-08-10 as an ORCHESTRATOR disposition, NOT a human ruling. Working rule: where a phase review is explicitly scoped to named AUTHORED regions of a work STATE.md, those regions are graded under the phase's own rule set (here definition.md), because DEF-04 and DEF-09 cite artifact-class-agnostic criteria -- a contradiction between two live statements and a repository claim disk contradicts are defects wherever they are written. Kind C continues to govern an UNSCOPED STATE.md, which is what it was written for: a spot-check of a file nobody asked to be graded. The class-1 hole in definition.md is real and left open; it did not bind here because both findings were expressible under DEF-04. Reopen for a human decision if a defect appears in a work STATE.md that neither DEF-04 nor DEF-09 can express. |
| definition/unmet-criterion-outside-blueprint-gate | criteria | Pending | 1 | 0 | specify-feature-009 | No definition-family rule instantiates taxonomy class 3 (Unmet criterion) for a requirement or convention declared in REQUIREMENTS -- DEF-08 reaches only a delivery BLUEPRINT's gate criteria. So FR-H3's unspecified mechanism and faithful (non-contradicting) violations of the Restatement convention are both unreportable. DEF-07, the nearest fit, cites authoring-conventions.md whose own scope is KB primary docs. | -- |
| definition/spec-region-ownership-for-shared-file | criteria | Pending | 1 | 0 | specify-feature-009 | No rule declares whether a feature SPEC must state region ownership for a canonical file several features change. feature-009 § 4 changes review-rubrics/INDEX.md (also claimed by features 002 and 007) and state-fix.md (also claimed by 005 and 008), and is the only one of nine feature SPECs with no affected-artifact-inventory section. | -- |
## Cross-phase Q&A

<!-- DERIVED -- union of per-delivery Q&A plus WORK-OWNER-AUTHORED entries below
     (work owner is the single writer for those). -->

### Q32 -- severity is computed from two proxies that both degenerate outside code (2026-08-11)

- **Category:** Design-Decision / the work's own subject
- **Impact:** High -- it is why nine cycles of real fixes never moved the grade out of the `D` band
- **Status:** **Pending**
- **Surfaced by:** the owner asking whether the findings were real issues or minutia, after
  `/aid-specify` cycle 9

**CORRECTED 2026-08-11, before any decision was taken.** This entry first claimed that *"fifteen
cosmetic findings were graded `[HIGH]`"* and that severity had mis-ranked a typo above a broken
criterion. **Both claims were false.** They came from a keyword script that sorted findings by the words
in their Description, and it dumped material findings into the cosmetic bucket whenever they did not
happen to use its keywords. The owner's question -- *why was the count problem set to high?* -- exposed
it. The count problem was **never** `[HIGH]`: `~144 suites` versus the 162 on disk scored `[MEDIUM]` in
all three cycles it appeared. What follows is the hand-checked record.

**What was measured, by hand.** Nine cycles, 89 findings, **20 of them `[HIGH]`**. Every one of the 20
was read and judged against one question -- *would this cause the wrong thing to be built, or block
building at all?*

| | Count | Verdict |
|---|---|---|
| `[HIGH]` findings | 20 | **All 20 material.** Absent mandated sections; a coverage domain specified three incompatible ways; a report missing a term `FR-H2` requires; `AC-17` undecidable; a criterion unsatisfiable for four rule sets; an owner decision silently reversed; a renumbering that left a gate criterion pointing at a section that no longer existed; a tally file with no invoker; a mechanism both unowned and inert |
| `[MEDIUM]` findings | 54 | **Mixed** -- material-but-confined defects sitting beside pure cosmetic ones, indistinguishable |
| `[MINOR]` | 7 | Cosmetic, correctly placed |

**So the severity scale did not mis-rank anything, and the grade was never wrong.**
`grade.sh` picks the letter from the **worst severity present**: any `[HIGH]` yields `D`, and the
`[MEDIUM]` count only sets the modifier when there is no `[HIGH]`. There was a `[HIGH]` in all nine
cycles, so the letter was decided entirely by findings that were all material. The grade was correctly
reporting *"at least one material defect is present"* every single time.

**The real reason the grade never improved** is therefore the one already recorded, not a scale defect:
**every cycle contained at least one material defect, and in most cycles it was one the previous fix had
just introduced** -- the tally with no invoker (cycle 6) came from cycle 5's repair, the inert series
(cycle 8) from cycle 7's, the dropped `AC-17` clauses (cycle 9) from cycle 8's.

**What IS still wrong, narrowed to what the evidence supports.** Not the ranking -- the **floor**.

`DEF-09` -- *"every factual claim the artifact makes about the repository holds on disk"* -- carries
modality **MUST**, and after Step 2 the lowest severity a MUST can reach is `[MEDIUM]`. So a true-but-
inconsequential claim, like a suite count no consumer reads, **cannot** be scored below `[MEDIUM]`.
There is no reachable band for *"real defect, no consequence"*. That is why 54 findings share one band
regardless of whether they change anything.

**The cost is real even though the grade was not affected.** Roughly two thirds of the 89 findings were
cosmetic. They never moved a letter -- the `[HIGH]`s decided every grade -- so the whole of that effort
bought nothing. Reviewer attention and fix cycles were spent on findings that **could not** affect the
outcome, and worse, the material `[HIGH]` sat in a list beside them rather than at the top.

**The owner's framing still holds, and is the part worth acting on.** Blast radius and reversibility are
proxies for consequence **in code**. On a document nothing has consumed, reversibility is always local
and radius is only *"is this mentioned elsewhere"*. That does not corrupt the letter, because modality
and the worst-severity rule carry it -- but it does mean **the MEDIUM band cannot separate a confined
material defect from a cosmetic one**, and the reviewer reviews code, data, text, tests and
specifications alike.

**Suggested reading of the evidence (NOT a decision).** Insert a **Step 2a** ahead of the existing
matrix:**Suggested reading of the evidence (NOT a decision).** Insert a **Step 2a** ahead of the existing
matrix:

> **Step 2a -- consequence.** Name the consumer decision this defect changes. If no decision can be
> named, the defect is **cosmetic**: `[MINOR]`, or `[LOW]` where it is widespread. Only a load-bearing
> defect continues to the blast-radius x reversibility matrix.

**And make it per-kind by extending a table that already exists.** `review-rubrics/INDEX.md` already
carries a per-class ladder with `Kind`, `Intent authority` and `Manner authority`. One more column
gives every artifact class its own meaning of *"the decision at stake"* -- no new taxonomy, no new
mechanism:

| Class | Consumer | A defect is load-bearing when it changes... |
|---|---|---|
| `KB` | an agent routing on it | which document it reads, or which convention it applies |
| `REQ` | Specify and Plan | what is in scope, or what modality binds |
| `SPEC` | Detail, then whoever builds | what gets built |
| `PLAN` | Execute | delivery order, a dependency edge, or a delivery's contents |
| `TASK` | the developer | the change made to the tree |
| `CODE` | the runtime, or a caller | control flow, a value, or a resource |
| `TEST` | the suite's verdict | whether it fails when the subject is broken |
| `DATA` | a query, or a consuming system | an answer returned |
| `AID` | the render, or an adopter's install | what ships to a profile |
| `SUMMARY` | a human reader | the belief they form about the KB |

**What it would have done to this work's own review record**, which is the only honest test available
-- and it is a smaller claim than this entry first made. **The nine letter grades would not change at
all**, because every one was set by a material `[HIGH]`. What changes is the working list: the cosmetic
share of the 54 `[MEDIUM]`s drops to `[MINOR]`, so each cycle's ledger would have shown a handful of
consequential findings instead of five to ten equals, and the material defect would have been visible
without reading every row. The gain is **attention and cycle cost, not accuracy of the grade.** That is
a weaker case for the change, and it is the true one.

**Cost, stated plainly.** This amends the canonical severity scale, which is `feature-001`'s territory
(`FR-B1`: one canonical scale), and the per-class ladder, which is `feature-002`'s. It is a **third
axis on the scale this work exists to make authoritative**, so it is not a small amendment, and it
touches two features already graded `A+`. It also re-opens one settled decision -- not `FR-B7`'s cut,
but the premise that two axes suffice.

---

### Q31 -- a CI runner cannot measure whether a reviewer AGENT finds a seeded defect (2026-08-10)

- **Category:** Design-Decision / feature-009
- **Impact:** High -- it decides what `FR-H2`'s number means and whether `FR-H3` has an automatic trigger
- **Status:** **Answered** 2026-08-10 -- owner chose the hybrid split
- **Surfaced by:** `/aid-specify` INITIALIZE for `feature-009`, Step 1 (loading `test-landscape.md`
  and the existing fixture families)

**The constraint.** `FR-H2` requires measuring the fraction of seeded defects a review pass finds. For a
rule enforced by a **script**, that is a shell assertion. For a rule enforced by **reviewer judgment**,
it needs a live model call, which a CI runner cannot make. Wiring one in would also make a deterministic
gate depend on a non-deterministic agent, which is not how any other gate in this project works.

**Answer (2026-08-10, owner decision): hybrid -- scripts in CI, agents on demand.**

| Lane | Subject | Where it runs | Shape |
|---|---|---|---|
| A | rules a named script decides | CI, every run | **pass/fail assertion**, not a percentage -- expected recall for a script rule is exactly 1.0, so a miss is a bug in the lint |
| B | rules reviewer judgment decides | on demand, deliberately | a reported fraction per rule set, plus a recorded baseline |

**Why the shapes differ, and why that is load-bearing.** Lane A being an assertion rather than an average
is what keeps `FR-F6` (one grading backend) intact: no percentage, no second arithmetic, no override
channel. Had both lanes been averaged into one figure, this feature would have introduced exactly the
second grading model `FR-F6` retires.

**The cost the owner accepted:** the agent half is not automatic, so a recall regression in a
judgment-enforced rule is only caught when someone runs Lane B. The mitigation is a named trigger rather
than an intention -- `PLAN.md § Cross-Cutting Risks` row 6 -- so a series exists before the number
matters.

**Correction 2026-08-10, made while specifying `feature-009`.** This entry originally named that trigger
as *"a Lane B run at every delivery close from `delivery-024` onward"*. **That trigger cannot fire as
written:** the Lane B figure is computed by `recall-measure.sh`, which ships with `delivery-027`, so
there is nothing to run at the closes of 024, 025 and 026. The **decision** above is unaffected and
stands; what replaces the wording serves the same purpose, because the series guarding against an
unattributable first figure is **Lane A breaking the build from `delivery-024`'s close onward** -- a
script rule that stops catching its seeded defect fails CI at that close. So the guard does start at
024, as intended, without any per-close bookkeeping duty. Recorded here rather than quietly contradicted downstream -- see
`features/feature-009-review-effectiveness/SPEC.md § 7`.

**Rejected, with reasons:** *on-demand only* -- simplest to build, but nothing automatic, which is the
same weakness that let eighteen polished passes go by; *everything in CI including the agent* -- strongest
signal, but needs credentials in CI, costs money per run, and makes a deterministic gate depend on a
non-deterministic agent.

**Applied 2026-08-10** to `features/feature-009-review-effectiveness/SPEC.md`
`## Technical Specification` -- the lane split is § 3, the `enforcement` column that routes a catalogue
row to a lane is § 2, and the wiring and cost of each lane is § 7.

---

### Q27 -- a review's coverage is recorded per FILE, and RECONCILE trusts it to clear findings (2026-08-10)

- **Category:** Design-Decision / the work's own subject
- **Impact:** High — this is the mechanism by which a shallow pass marks a live defect `Fixed`
- **Status:** **Answered** 2026-08-10 — owner accepted the suggestion; coverage becomes per-claim
- **Answer (2026-08-10, owner decision).** **The coverage unit changes from FILE to CLAIM, and the
  auto-close transition depends on it.** Three parts, accepted as put: (1) the reviewer brief carries
  an **enumerated worklist** for the scope, rather than a mandate to be thorough; (2) a `U-` row
  **cites the worklist item it discharges**, so `Examined` records *what was checked* instead of that
  a file was opened; (3) RECONCILE's `Pending → Fixed` transition fires only when **every worklist
  item covering that `Doc` was checked**, which makes the inference falsifiable. Rationale accepted
  as put: the schema already guards *"absence proves nothing"* for an unexamined unit and then trusts
  silence completely once a self-reported, file-granular box is ticked — which is how `PLAN.md` was
  marked `Examined` 21 times while holding 13 findings.
  **Accepted cost:** the widest blast radius of the four — the `U-` grammar and the RECONCILE join in
  `reviewer-ledger-schema.md`, the brief in `reviewer-brief-template.md`, and `feature-005`'s
  requirement family, which today states no coverage granularity at all.
  **Interaction with `Q28`:** the recall oracle is the instrument that measures whether this change
  works, so `Q28`'s corpus should be able to report recall per-claim as well as per-review.
  **Not yet applied.**

**What was measured.** Over the 18-cycle `/aid-plan` review of deliveries 019-023, `PLAN.md` was
marked `Examined` **21 times** in coverage rows, and **13 findings were later reported in it**.
Across 14 defects that were on disk before the fix cycles began, the mean number of reviews that
missed each one was **6.6**; the worst (`delivery-022`'s *"sequenced last"* contradiction) was missed
by **17** consecutive reviews before cycle 19 caught it.

**Why the coverage row cannot carry the weight put on it.** A `U-` row asserts one thing about one
unit — and the unit is a **file**. `reviewer-ledger-schema.md § Attempts and reconciliation`
then acts on it:

| Durable row | Key in scratch? | Result |
|---|---|---|
| `Pending` | no, **and** the unit covering `Doc` is `Examined` | → `Fixed` |
| `Pending` | no, and the unit is **not** `Examined` | stays `Pending` — *"absence proves nothing"* |

The guard on the second row shows the schema already knows absence is weak evidence. The first row
then licenses exactly that inference on the strength of a **self-reported, file-granular** claim. So
a sampling pass does not merely fail to find a defect — it **clears** it.

**The counter-evidence that a different granularity works.** Twice during this review the reviewer
was given an **enumerated worklist** instead of a mandate to be thorough:

| Pass | Method | Findings in ONE pass |
|---|---|---|
| Claims sweep | a script listed all **133** quantified claims; the agent checked every one | **15** |
| Q&A sweep | all **26** `Q` entries, no sampling | **17** |
| Any single review cycle | the reviewer chose where to look | **1-4** |

Same artifacts, same rule set, same reviewer model. Enumeration was the only variable.

**Suggested reading of the evidence (NOT a decision).** `Examined` should record **what was
checked**, not that a file was opened, and the unit should be the **claim** rather than the file.
Minimum viable shape: the brief carries an enumerated worklist for the scope, and a `U-` row cites
the worklist item it discharges. RECONCILE's `Pending → Fixed` transition then rests on "every
worklist item covering this `Doc` was checked", which is falsifiable.

**Amendments this would force.** `feature-005` (review resume) owns coverage rows;
`reviewer-ledger-schema.md` owns the `U-` grammar and the RECONCILE join;
`reviewer-brief-template.md` would gain the worklist. `FR-D*` (feature-005) is the requirement
family; no existing `FR` states coverage granularity at all.

**APPLIED 2026-08-10.** `FR-D10` (MUST) and `AC-15` in `REQUIREMENTS.md`; carried by
**delivery-026** (Per-claim coverage), which depends on delivery-009 so the RECONCILE join is not
written twice.

---

### Q28 -- nothing in this work measures whether a review finds what is there (2026-08-10)

- **Category:** Scope gap / the work's own subject
- **Impact:** High — without a denominator, "clean" is unfalsifiable, and every grade in this work
  measures reviewer attention rather than artifact quality
- **Status:** **Answered** 2026-08-10 — owner accepted the suggestion; this becomes new scope
- **Answer (2026-08-10, owner decision).** **Bring the recall oracle into this work.** The
  subsystem gets a fixture corpus with **seeded, catalogued defects** and a measured fraction the
  review finds, giving the grade a denominator and turning "the review is thorough" from a mandate
  into a measurement. Rationale accepted as put: this work's stated purpose is fixing review and it
  currently cannot tell whether review works, and parking the measurement outside the work is what
  allowed 18 polished-looking passes to go by. Supersedes the disposition that left this as
  tech-debt `L4` (*test-effectiveness programme, not started*) — the review-path slice of `L4` is
  now carried here. **Corrected 2026-08-10, after the SPEC was authored:** `L4`'s subject is
  whether the canonical **test suites** bite -- `tech-debt.md` owns that corpus size and it drifts with
  every added suite, so it is not restated here -- while group H's subject is whether a **review**
  finds what is there. Same technique, different subject, so group H discharges a slice of `L4`
  rather than replacing it, and `L4` stays open for the rest. The decision recorded above is
  unaffected — only the scope of what it closes.
  **Accepted cost:** new scope, the largest of the four, shifting the work from making the review
  subsystem tidy to making it measurable, and adding at least one delivery.
  **Not yet applied** — needs a requirement in `REQUIREMENTS.md`, a feature owner, and a delivery.

**What was measured.** `grep -in "exhaustiv\|recall\|seeded\|false negative\|missed" REQUIREMENTS.md`
returns **no hit on the concept** (the two matches are `FR-A1` and `FR-A9`, on other words). Across
**10 features** and ~60 requirements, the work never asks whether a review found what was actually
present. `grade.sh` counts findings **found**; there is no term for findings **missed**.

**Why that is the load-bearing gap.** Every feature in this work improves the handling of findings
that were already found — one severity source (`feature-001`), a rule ID on every row
(`feature-002`), durable surgical writes (`feature-003`), no finding without a rule
(`feature-004`), none lost to interruption (`feature-005`), resolvable evidence (`feature-008`).
That is a **precision** programme end to end. Nothing in it raises or measures **recall**. Two of
those features plausibly *lower* recall, because the No-Criterion-no-row contract and
severity-by-lookup both raise the cost of writing a finding.

**The consequence, observed.** This review produced immaculate bookkeeping — a rule ID on every row,
resolvable citations, 11 criteria gaps registered, zero open keys, exact dependency reciprocity —
while missing each defect 6.6 times on average. A rigorous-looking clean pass is **more** misleading
than a scruffy one, because it invites belief.

**Suggested reading of the evidence (NOT a decision).** The subsystem needs a **recall oracle**: a
fixture corpus with **seeded, catalogued defects**, and a measured fraction the review finds. It
gives the grade a denominator and turns "the review is thorough" from a mandate into a measurement.
This is already carried as tech-debt `L4` (*test-effectiveness programme, not started*); the finding
here is that it belongs **inside** this work, because this work is the one claiming to fix review.

**Cost, stated plainly.** This is **new scope** and the largest of the four. It arguably changes what
the work is *for* — from making the review subsystem tidy to making it measurable.

**APPLIED 2026-08-10.** New **group H** in `REQUIREMENTS.md` (`FR-H1`–`FR-H3`) plus `AC-16`,
priority order 5, and the scope-honesty note. Carried by **delivery-024** (the corpus — a free track
that depends on nothing, so the baseline is not taken after the change) and **delivery-027** (the
measurement, after delivery-022 so the figure describes the shape that ships). Owner `feature-009`,
whose SPEC was authored on 2026-08-10 and is `In Discussion`. Tech-debt `L4` is partly
discharged, not superseded (see the correction in the Answer above).

---

### Q29 -- `FIX` has no mechanical obligation to sweep a finding's class (2026-08-10)

- **Category:** Process defect
- **Impact:** Medium — measured at roughly 7 of 69 findings in the plan review
- **Status:** **Answered** 2026-08-10 — owner accepted the suggestion
- **Answer (2026-08-10, owner decision).** **A fix is not done until its class has been swept and
  every site listed.** Before marking a fix complete the fixer greps the distinguishing phrase of
  the corrected claim across the work and reports every occurrence, so a missed sibling is visible
  immediately rather than found a cycle later. This is `F1` given an **oracle** instead of an
  instruction — no new rule set, no ledger change, and the phrase to grep comes free from the row
  the fixer is already discharging. Rationale accepted as put: the rule already existed in prose and
  was still broken roughly once every two cycles.
  **Lands in:** `aid-execute/references/state-fix.md`, which already states `F1`.
  **Interaction with `Q27`:** the swept site list is claim-shaped, so it is a natural input to the
  enumerated worklist `Q27` introduces — a class sweep produces exactly the kind of item a coverage
  row would then cite.
  **Not yet applied.**

**What was measured.** `aid-execute/references/state-fix.md` states `F1` — *a finding is a CLASS;
Evidence specifies the EXTENT* — as prose. Nothing checks it. In the 18-cycle plan review, the same
claim-family was swept and missed repeatedly: `PLAN.md` alone took **10** `DEF-04` findings, each a
different site of a claim already corrected elsewhere. Concrete instances: the "delivery-022 is
last" claim was fixed in the BLUEPRINT at cycle 10 and found again in `PLAN.md` at cycle 19; the
carrier-delivery correction was applied to `Q5`, `Q8` and `Q26` and missed in `Q13`; the
`git ls-tree` wording was fixed in `PLAN.md` and `REQUIREMENTS.md` and missed twice in `STATE.md`.

**Suggested reading of the evidence (NOT a decision).** Before a fix is marked complete, the fixer
runs a **class sweep**: grep the distinguishing phrase of the corrected claim across the work and
report every site, so a missed sibling is visible rather than discovered a cycle later. Cheap,
mechanical, and it needs no new rule set — it is `F1` given an oracle instead of an instruction.

**Where it lands.** `state-fix.md` owns `F1`. `feature-003`'s ledger substrate already gives the
fixer the row it is discharging, which is where the phrase would come from.

**APPLIED 2026-08-10.** `FR-E2` (MUST) and `AC-17` in `REQUIREMENTS.md`; carried by
**delivery-025** (Class sweep in FIX), a free track that depends on nothing. It earned its keep
immediately: sweeping the delivery-022 trim found a third site -- `PLAN.md`'s *"It blocks only
delivery-023"* -- that the two blueprint edits alone would have left contradicting the graph.

---

### Q30 -- the same fact is restated across 3-4 artifacts, and that is what set the defect floor (2026-08-10)

- **Category:** Design-Decision / artifact structure
- **Impact:** Medium — it is the reason the grade could not reach `A` by editing
- **Status:** **Answered** 2026-08-10 — owner accepted **both** parts
- **Answer (2026-08-10, owner decision).** **Both moves, accepted as put.**
  **(a) Cite, do not restate.** A derived fact is stated **once**, in the artifact that owns it, and
  cited from everywhere else. Convention for the work as a whole. The trade-off was stated when this
  was put and is accepted: a cited fact reads less well than a restated one, and someone reading
  `delivery-022` alone must follow a pointer to learn why it is sequenced where it is. That cost buys
  the removal of the sweep-on-every-correction burden that produced **65 of 69** findings under the
  two consistency rules.
  **(b) Task-level detail leaves the delivery `BLUEPRINT`.** `artifact-schemas.md` scopes `## Scope`
  to *"bounded in-scope deliverables"*; `delivery-022`'s Scope had accumulated a per-line forensic
  account of seven read sites in `tests/canonical/test-review-extraction.sh`, which is task
  `DETAIL.md` content and which produced the findings in cycles 16-19. Applied **now**, because it is
  what `IMPEDIMENT-plan-review.md` blocks the plan on.
  **Interaction with `Q27`/`Q29`:** both reduce restatement, so all three pull the same direction —
  `Q29`'s class sweep finds the restatements, `Q30(a)` stops them being created, and `Q27`'s worklist
  is what a reviewer checks them against.
  **APPLIED 2026-08-10, both parts.** (a) is the **Restatement convention** in
  `REQUIREMENTS.md`'s conventions preamble, beside the modality convention it parallels, and it is already dogfooded:
  `PLAN.md`'s free/spine figure is now stated once in `§ Dependency graph` and cited from
  `§ Sequencing decisions` and `§ Cross-Cutting Risks` instead of restated in each. (The convention
  itself lives in `REQUIREMENTS.md`'s conventions preamble, beside the modality convention -- not in
  `§ 5`, as this entry first said.) (b) trimmed
  `delivery-022`'s Scope -- the per-site forensics left for `/aid-detail`, the obligation kept as
  two gate criteria, `BLUEPRINT.md` down from 172 to 155 lines. The blueprint template's own
  closing line agrees: *"detailed design belongs in task DETAIL.md files."*

**What was measured.** Duplication of single facts across the work's artifacts:

| Fact | Restated in |
|---|---|
| The entry-path count | 4 files |
| The `git ls-tree` "76 names" result | 4 files |
| The 17-sightings arithmetic | 3 files |
| Which delivery carries which `Q26` item | 3 files |

Every correction therefore had to be swept across 3-4 files. Miss one and it is a `DEF-04`
contradiction; re-word one imprecisely and it is a `DEF-09` false claim. Those two rules are **65 of
the work's 69 plan-review findings**. Roughly **1 in 3** findings was introduced by a previous fix,
which is what held the grade at `C` for fourteen consecutive cycles: the bar is zero findings, and
each repair reopened the class one level deeper.

**Suggested reading of the evidence (NOT a decision).** Two moves, independent of each other:
(a) state a derived fact **once**, in the artifact that owns it, and cite it from the others rather
than restating it; (b) keep task-level detail out of a delivery `BLUEPRINT` — `artifact-schemas.md`
scopes `## Scope` to *"bounded in-scope deliverables"*, and `delivery-022`'s Scope had accumulated a
per-line forensic account of seven read sites in a bash suite, which is task `DETAIL.md` content and
which produced the findings in cycles 16-19.

**Relationship to the impediment.** `IMPEDIMENT-plan-review.md` already recommends (b) for
`delivery-022` specifically. This entry asks whether (a) becomes a convention for the work as a
whole.

---

### Q26 -- four decisions read as settled in prose and are not settled on disk (2026-08-09)

- **Category:** Process defect — same class as `Q22`, found the same way
- **Impact:** High — and the four fail in three different ways. **Two** (items 2 and 3) sit inside a delivery that closed `Done` over work it did not deliver, which is the process defect proper. **One** (item 1, `reviewer-guide.md`) was never scheduled into any delivery, so no gate ever had the chance. **One** (item 4, `Q5` decision 7) is **benign**: the work shipped and the decision was consciously reversed, so nothing is undelivered and only this file's own text is stale
- **Status:** **Answered** 2026-08-09 — items 1-2 re-scheduled into new deliveries; item 3
  superseded by `Q1(a)`; item 4 and the `Q8` N3 correction are text fixes to this file.
  **Carriers corrected 2026-08-10** — this read *"into the merge delivery"*, written before that
  delivery was split in two. On disk: **item 1 is carried by `delivery-022`** (the merge),
  and **items 2 and 4 and the `Q8` N3 correction by `delivery-021`** (record corrections and
  the greenfield edit). Each delivery's Scope names its own share.
- **Answer (2026-08-09, human decision).** **Items 1 and 2 are re-scheduled into new deliveries
  rather than reopened. Closed deliveries stay closed.** (As put on 2026-08-09 this said *"the delivery
  that carries the `/aid-review` merge"*, when one delivery was expected to carry everything;
  the split into `delivery-021` and `delivery-022` came later the same day.) Reopening delivery-007 or any
  other `Done` delivery would corrupt the record of what those gates actually certified — the gate
  *did* run, and rewriting its outcome retrospectively destroys the evidence of the real defect, which
  is that a delivery's recorded scope outran what was performed. A new delivery carrying the shortfall
  keeps the history honest and places the work where it will be re-reviewed anyway. Item 1 is close to
  free: retiring `reviewer-guide.md` is a deletion plus one hand-edit, and it **also closes
  `Q3(b)` and `Q3(c)`**, which have been open only because the deletion never happened. **Referrer
  count corrected 2026-08-10** — this read *"updating two referrers"*. There are none under
  `canonical/` (`grep -rln 'reviewer.guide' canonical/` exits 1). Repo-wide, excluding transient
  `.aid/.temp/` files **and this work's own records under `.aid/works/`** (16 files match in total;
  9 of them are work-003 records, which `delivery-022` deliberately leaves unswept), there are
  **seven** that a deletion would actually have to touch: five `profiles/*/emission-manifest.jsonl`, plus
  `.aid/.aid-manifest.json` -- all six regenerated, not edited -- and one hand-maintained suite,
  `tests/canonical/test-review-extraction.sh`. So the only manual referrer edit is the test.
  Item 3 needs no ruling — superseded, see above. Item 4 (`Q5` decision 7's reversed text) and the
  `Q8` N3 carrier-claim correction are edits to this file's own entries and ride `delivery-021`
  alongside item 2, not the merge delivery.

**How it surfaced.** Eight `Cross-phase Q&A` entries still read `Pending` although all were raised
2026-07-27 and fifteen deliveries have shipped since. Triaging them against disk (rather than against
what the entries claim) settled most of them — and turned up four decisions that the record treats as
done while disk disagrees. **The `Status` field being stale was the trivial finding; this is the real
one.**

**1. `aid-execute/references/reviewer-guide.md` was to be retired** (`Q13` / feature-006 #5). It is
still present at 77 lines and still carries the `CODE / TASK / SPEC / KB` source table that
`reviewer-ledger-schema.md:165-167` and `aid-reviewer/AGENT.md:20` both declare **retired**. It was
never scheduled into any delivery: at the time of this triage `grep -rln reviewer-guide deliveries/`
over the then-18 delivery folders returned only `delivery-001/BASELINE-ac11.md`, which merely
measures the file for the `AC-11` baseline, and `delivery-004/BLUEPRINT.md`, whose **Out of scope**
line already calls it *"the retired `reviewer-guide.md`"* while scoping the deletion to nobody.
(`delivery-021` and `delivery-022`, created the same day to carry this finding, now match the same
grep -- so re-run it against the pre-2026-08-09 folders to reproduce the figure above.) **Consequence:** `Q3(b)` and
`Q3(c)` were to be resolved *by this deletion*, so they remain open by default rather than by decision.

**2. The greenfield criteria-vs-evidence split was to edit `document-expectations.md` 50-52**
(`Q13` / feature-004 #9; `Q5(d)`). `features/feature-004-criteria-gap-interrupt/SPEC.md:435` claims regions 13-19 and 36-54. Work-003
never touched that file — its newest commit is `b7490a40`, from **work-023**. `grep -i resolvable`
returns nothing and lines 50-52 still carry the pre-decision C3 text. **Delivery-007 closed `Done`.**

**3. "Light-review findings land in the canonical ledger as `Pending`"** (`Q13` / feature-006 #4;
`Q5` decision 3). Contradicted by the skill's own text: `aid-light-review/SKILL.md:21` forbids it
writing a ledger — *"a cheap pass must never contribute to a grade"* — and its REPORT state writes
nothing at all. So light review records **neither findings nor gaps**, and the corollary "the calling
skill writes them" never landed either. The `U-` half of the decision did ship.
**SUPERSEDED 2026-08-09 by the `Q1(a)` revision — this item needs no separate ruling.** With
`aid-light-review` merging into `/aid-review` as the **screening entry path**, the question is no
longer "why did the skill not do what was decided" but "what does the screening path write" — and
that must be settled *as part of the merge*, against `FR-A2` (screening computes no grade) and
`FR-A4` (a clean screening pass may only add findings, never pre-clear the gate). **Folded into the
merge delivery**, not carried as a defect against a delivery that has closed.

**4. `Q5` decision 7, "restart, not resume", is superseded — and is the one benign case.**
`criteria-gap-protocol.md:75` ships *"coverage rows **resume** rather than restart"*, deliberately and
traceably, by `Q6` proposal 3. Here the entry's **text** needs correcting, not just its `Status`;
writing it as answered-as-recorded would preserve a decision that was consciously reversed.

**A fifth, of the same shape, in `Q8` N3.** The entry asserts *"Each feature SPEC now carries this
note"* about the AC-12 parity gate. `grep -c AC-12` across the eight feature SPECs returns
`1,1,0,0,0,7,0,0` — **three of eight**, not eight. The per-delivery gate is likewise partial: 11 of 18
BLUEPRINTs carry a parity criterion. The *decision* (per-delivery regression gate, delivery-012 owns
the criterion of record) is sound and provable; only the **carrier claim** is false.

**Why this matters beyond the four.** `Q22` recorded deliveries marked `Gated` with no gate ever run.
This is the same failure from the other end: a gate that **did** run, over a delivery whose recorded
scope included work nobody performed. In both cases the tracking said the work was complete and no
artifact of it exists. The `/aid-detail` review that just closed `A+` cannot have caught these — its
scope was nine task files, not the delivery record.

**Not fixed here, deliberately.** Items 1-3 each need a delivery to carry them, and three of the
affected deliveries are already `Done`; whether to reopen, re-schedule into a new delivery, or accept
and record is a decision per item. Item 4 and the `Q8` N3 correction are text fixes to this file's own
entries and are the cheapest of the five.

### Q25 -- `FR-G3` checks bytes, but the criterion is now meaning (2026-08-09)

- **Category:** Requirement/implementation mismatch, created by a decision
- **Impact:** Medium — it changes what feature-008 delivers, and delivery-017 executes it
- **Status:** **Answered** 2026-08-09 — the lint becomes a cheap pre-filter; judgment decides on a miss

**What was found.** Answering gap `def09/whitespace-normalisation-in-quoted-strings` established that
an attributed quote is judged on **semantic fidelity**: the content must mean exactly what the source
intends, and formatting — whitespace, emphasis, exact wording — is irrelevant.

`FR-G3` as specified cannot express that. Its check is literal: *"for each `*"…"*` span, if a
backticked file citation precedes it on the same line, the quoted text **must** appear in that file"*,
with both sides stripped of emphasis and whitespace-collapsed first. That is a substring test. A
faithful paraphrase fails it; a byte-perfect quote that inverts the source's meaning passes it. **Both
error directions are wrong under the new criterion.**

**The precedent is already in the same SPEC.** § 3 dispositions `FR-G4` as *"a review rule, not a lint
check"* because counting occurrences was not mechanically reachable. Semantic fidelity is less
mechanically reachable than counting, not more.

**What is at stake beyond the rule.** § 4 carries a design note — *"a quote that must survive FR-G3
should be a short fragment from a single source line"* — and `delivery-017/task-003` carries that
guidance as scope. That guidance exists **only because** the check is literal. If `FR-G3` becomes a
judgment rule, the guidance is solving a problem that no longer exists.

**Answer (2026-08-09, human decision).** **`FR-G3` becomes a cheap pre-filter, not a gate.** A
substring hit proves fidelity and exits early — cheap, mechanical, and sound in that direction. A
**miss escalates to reviewer judgment rather than failing**, because a miss means only "not byte-
identical", which under the meaning criterion proves nothing. The lint keeps the part that is
genuinely mechanical; meaning goes where only judgment reaches it.

**Consequences that follow, to be carried by delivery-017.**
- `FR-G3`'s exit contract changes: a miss is no longer a failure. `[UNATTRIBUTED-QUOTE]` is already
  advisory; the missed-quote case joins it rather than setting a non-zero exit.
- **The short-fragment guidance survives, with its rationale rewritten.** It is no longer a rule for
  passing a gate — it is advice for making the *cheap path* succeed, so fewer quotes escalate.
  `delivery-017/task-003` keeps it in scope; only the reason it gives changes.
- Emphasis/whitespace normalisation stays, but demoted: it widens the pre-filter's hit rate. It is no
  longer load-bearing, because a normalisation miss no longer decides anything.
- A judgment rule is needed for the escalated case. `FR-G4`'s disposition (§ 3) is the precedent for
  how to declare one without inventing a criterion.
- **`AC-14` and `FR-G3` must be amended, and delivery-017 carries that.** Added 2026-08-09 after a
  plan review found this consequence list had no entry for it: the re-disposition had been applied
  to delivery-017's BLUEPRINT alone, leaving `REQUIREMENTS.md`'s `AC-14` (a **MUST**), feature-008's
  `FR-G3`, and **one** task `DETAIL.md` (`task-001`) still asserting the byte criterion. A decision
  recorded in one artifact and contradicted in three is the defect this work exists to remove.
  **Count corrected 2026-08-10** — this read *"both task `DETAIL.md` files"* and *"contradicted in
  four"*. At `7127acd4`, `grep -c "appear in that file"` over this delivery's four task files
  returned `1,0,0,0`: only `task-001` ever carried the wording. `task-003` carries the short-fragment
  *guidance* that presupposed the byte criterion, which is what the original count was reaching for,
  but guidance whose rationale changed is not an artifact asserting the retired criterion —
  `delivery-017`'s Scope makes exactly that distinction and says *"the one task `DETAIL.md`"*.

Options declined: re-dispositioning `FR-G3` as a *pure* review rule (throws away a sound, cheap check
and the guidance with it), and keeping it literal (enforces a criterion the owner rejected).

### Q24 -- this work states a bar of `A` that no gate enforces (2026-08-08)

- **Category:** Stated-but-unenforced value — the class this work exists to fix
- **Impact:** Low here, higher as precedent — no grade in this work turned on it
- **Status:** **Answered** 2026-08-09, then **OVERTAKEN BY DISK 2026-08-10.** The answer below described a `B-`
  floor. There is no `B-` floor any more: `.aid/settings.yml:6` reads `minimum_grade: A`, `read-setting.sh`
  returns `A` for all five reviewing callers, and that file's own floor history records `B- → A` on
  **2026-08-04** (work-004's closing pass, commit `2216ddc6`), which reached this branch in the 2026-08-09
  master merge. The `A` gate was therefore already reinstated before this entry was answered, and for
  reasons unrelated to the restore condition below. **The stated-but-unenforced defect this entry records
  is real and its diagnosis stands; only its reading of the current bar is stale.**

**What was found.** This file's frontmatter carries `minimum_grade: "A"` (line 6). Every review gate
resolves its bar through `read-setting.sh`, whose header states it reads `.aid/settings.yml` and
which returns **`B-`** for every reviewing caller:

```
aid-detail B-   aid-plan B-   aid-specify B-   aid-execute B-   aid-define B-
```

`.aid/settings.yml` carried a flat `minimum_grade: B-` **when this was written**; it reads `A` since
2026-08-04. Nothing resolves the work-level key:
`read-setting.sh` reads only the settings file, and `canonical/aid/scripts/execute/writeback-state.sh:1437` maps
`Minimum Grade → minimum_grade` for **writing** the field, not for consuming it as a bar.

**So a reader of this file sees a bar of `A` while every gate in the work enforces `B-`.** That is
the same shape as `quality-gates.md` claiming a CI lint ran when no workflow invoked it — the defect
delivery-002 was pulled forward to correct.

**It changed nothing here.** The `/aid-detail` review closed at `A+`, which clears both bars, and
delivery gates 013-015 are ungraded pending re-gate. No decision in this work rests on the difference.

**Answer (2026-08-09, human decision).** **Neither value is stale, and the premise that one of them
is drift was wrong.** `A` is this work's real bar. `.aid/settings.yml`'s `B-` is a **deliberate
temporary floor**, lowered because reaching `A` was costing too many review cycles and tokens; the
proper `A` gate is to be reinstated once the missing deliveries are defined. So the fix is not to
delete either value — it is to record *why* they differ, which is the one thing disk did not say.
The three options put (wire an override to `A`, delete the frontmatter key as stale, mark it
non-enforcing) were all predicated on that wrong premise and are declined.

**What was genuinely missing, and is now here:** nothing on disk stated that `B-` is temporary or
what restores `A`. A reader could only see two bars disagreeing. That is the residual defect, and
this entry is its fix.

**Restore condition — MET, and overtaken 2026-08-10.** As written this read *"not yet met"* on three
grounds, and disk now falsifies all three. `PLAN.md` ends at **`delivery-023`**, not 018, and 23 delivery
folders exist (019-023 are at `Pending-Spec` with no task `DETAIL.md` yet, which is correct for their
state). `Q23`'s added `feature-003` requirement **is** carried — `delivery-020`'s first Scope bullet is
that requirement. And the `A` gate did not wait for any of this: it went back on **2026-08-04**, by an
owner decision recorded in `.aid/settings.yml`'s floor history. The cost concern was real when the floor
was lowered and is not what resolved it.

### Q23 -- the ledger cannot support its own circuit-breaker condition (2026-08-08)

- **Category:** Product defect in feature-003's substrate
- **Impact:** Medium — it does not move any grade, it makes the loop undiagnosable
- **Status:** **Answered** 2026-08-09 — becomes a `feature-003` requirement

**What was found.** `aid-deep-review` § RECONCILE joins scratch onto durable on `(Doc, Rule)`, and
`Fixed` + present-in-scratch → `Recurred`. But the durable row's `Description` is authorial and is
never rewritten, so a *new* defect at an already-visited `(Doc, Rule)` key is recorded as `Recurred`
carrying the **first** sighting's description. The ledger therefore cannot distinguish *"the fix did
not work"* from *"a different defect now sits at the same key"* — and those have opposite remedies.

**Measured on this review** (**figures corrected 2026-08-10**; this read *"16 sightings"*, which did not
reproduce). Over the seven ledgers — the durable one plus `cycle2..cycle7` — **17 sightings** across
**12 distinct `(Doc, Rule)` keys**, of which **4 keys were seen more than once**, and **0 of the 4 were
the same defect twice**. The arithmetic closes: 12 keys plus 5 extra sightings over those 4 keys is 17.
No row in any of the seven ledgers ever carried the literal status `Recurred` — the recurrence is visible
only by joining on the key, which is the defect this entry describes. **Five rows over four keys, matching the figures above** (**row added 2026-08-10** — the table enumerated three keys and four events while the prose said four and five). Three of the five are traceably introduced by the preceding cycle's own fix. The `Cycles` column is **as recorded at reconcile time and is not re-derivable**: the durable ledger stamps no cycle on its rows, which is a second face of the same defect this entry describes.

| Key | Cycles | What actually recurred |
|---|---|---|
| `017/task-002` · `DEF-09` | 2 → 3 | c2's fix edited feature-008 SPEC § 4; task-002 still described the old § 4 |
| `017/task-002` · `DEF-09` | 3 → 4 | a different sentence in the same Scope bullet (pre-existing) |
| `016/task-001` · `DEF-09` | 3 → 5 | the sentence written in c3, invalidated by the c4 KB edit |
| `017/task-002` · `DEF-04` | 1 → 5 | self-contradiction created when the 319-word bullet was cut in c4 |
| `016/task-001` · `DEF-04` | 2 → 6 | a *different* self-contradiction at the same key four cycles later — c2 found `AC-4` naming the wrong winning authority, c6 found Scope and `AC-4` disagreeing over which artifact settles the *Minimum Grade Thresholds* paragraph |

**Why it matters, and it is not cosmetic.** The FIX circuit breaker is declared as *non-improvement*
— "each cycle closing more than it opens". Computing that requires knowing whether a `Recurred` row
is a *reopen* or a *new open*, and the durable ledger holds neither the per-cycle description nor an
open/close event. Answering it here required reading the six `*-cycleN.md` scratch files — which
§ DONE instructs the orchestrator to **delete** at merge. Following the skill as written destroys
the only evidence its own breaker needs.

**Not a grading bug.** `grade.sh` treats `Pending` and `Recurred` identically (both grade-bearing,
`features/feature-003-ledger-substrate/SPEC.md:168`), so no grade computed on this work is wrong because of this.

**Answer (2026-08-09, human decision).** `feature-003` gains the requirement, in the form the owner
specified: **the row keeps a short list of one-line problem statements, one per sighting, instead of
only a status and a count.** A count cannot be compared; a one-liner can. On a new sighting at an
existing `(Doc, Rule)` key, the incoming description is compared against the list already there, so
the ledger distinguishes *the same problem recurring* from *a new set of problems in the same place*
— which is the distinction the non-improvement breaker needs and the only reason four scratch files
had to be read to answer it.

Two options put and **not** taken: a discriminator folded into the join key (does not preserve what
the earlier problems *were*), and declining to tech-debt on the grounds that retained scratch files
suffice (which silently converts "delete at DONE" into "retain at DONE", making cleanup a
requirement by the back door).

Not folded into an in-flight delivery: `feature-003`'s SPEC is `Ready` at `A+`, so this lands as an
amendment to an already-graded SPEC and needs a delivery to carry it.

### Q22 -- deliveries 013 and 014 were marked Gated with no gate ever run (2026-07-30)

- **Category:** Process defect
- **Impact:** High
- **Status:** **Being closed now** — both gates dispatched 2026-07-31.

**What was found.** Both deliveries read `delivery_state: Gated`, but their whole gate record is
empty: `gate_grade: "Pending"`, `gate_timestamp: "--"`, `Issue List: --`. Only `gate_tier: Medium`
was set, which is the value the *scoring* step writes before a reviewer is dispatched. Their tasks
are all `Done` and the work shipped 48 and 58 files respectively. So the lifecycle was advanced to
`Gated` without a gate: the state says a quality gate happened and no artifact of one exists.

This is precisely the failure the tracking rule in `CLAUDE.md` exists to prevent, in its less obvious
direction — not a task sitting at `Pending` while it runs, but a delivery *claiming* a terminal
review state it never reached. Twelve of the fifteen executed deliveries carry `A+` with a record;
these two carried a state with nothing behind it, and it survived because nothing cross-checks
`delivery_state: Gated` against the presence of a grade.

**What is being done.** Both gates are now running against **today's HEAD**, not the commit they
shipped at (`9601190d` for 013, `7a9df485` for 014). Reviewing them late is not a workaround, it is
strictly stronger: 140-odd commits and a master merge have landed on top, so a criterion that held
then and has since been broken is a finding the original gate could not have produced. Delivery-014's
subject matter in particular has moved underneath it — it owns `lint-settings.sh`, and
`.aid/settings.yml` has since changed `minimum_grade` twice and had a per-skill override rejected by
that very linter (§ Q19).

**The gap that let it happen, which outlives these two deliveries.** Nothing asserts the invariant
*`delivery_state: Gated` implies a non-empty `gate_grade`*. That is a one-line mechanical check over
every `deliveries/*/STATE.md`, and its absence is why a missing gate looked identical to a passed one
for three days. Recorded here rather than fixed inline — it belongs with the state-schema work, not
in a gate FIX cycle.

### Q21 -- merging master: the circuit breaker collided with work-001's chart engine (2026-07-30)

- **Category:** Integration
- **Impact:** High
- **Status:** **Decided and applied** (human decision: update master's engine + tests).

Master advanced 132 commits, merging work-001's Skill Explorer. Ten files conflicted textually; the
substantive collision was none of them.

**The collision.** Our delivery-012 extracted review into `/aid-light-review` + `/aid-deep-review`,
moving the GATE fix loop and circuit breaker OUT of `shortcut-engine.md` — that file's GATE section
now reads "`/aid-deep-review` runs the loop" and names it owner of "the gap gate, the grade, the fix
loop and the circuit breaker". Work-001, meanwhile, built a flow-chart engine whose **B1** rule looks
for a bolded `**Circuit breaker.**` arm under GATE *in that exact file*, plus 44 assertions asserting
the resulting nine-node graph with a GATE self-edge. Both changes are right on their own; they cannot
both be true of one file. Master alone: 2772/2772 green. After the merge: 104 failing.

**Decision (human): update master's engine and tests**, because the chart should describe the file as
it is. Applied: the shortcut-engine chart is now 8 nodes with no self-edge and two exits, and every
assertion that named the breaker asserts instead the **positive fact that replaced it** — that the
GATE section delegates the loop and breaker, and that `/aid-deep-review` still carries the breaker.
Trading a real assertion for "expect nothing" is the vacuous-guard failure this work has spent four
cycles removing; the same standard applies to another work's tests. B1 stays keyed on GATE rather
than deleted: it is generic, so a breaker returning to the file charts again with no code change.

**Not all 104 were that.** The other causes, each fixed:
- **56 were line endings.** My working tree carried CRLF in 77 files where the index and
  `.gitattributes` both say LF, so `gen-skills.mjs` aborted on a provenance check. CI (fresh clone)
  would have passed while my local run could not — the inverse of the usual local-only failure.
- **Three separate rosters** each needed the two new review skills: `curated-roster.mjs`,
  `skills/groups.mjs` — omitting it *throws* `unassignable skill`, which killed the generator
  outright — and the deliberately-independent list in `gen-reference.test.mjs`. Verified the roster
  entry is load-bearing by deleting it and watching the generator exit non-zero.
- **42 stale skill counts across 22 files**, flagged by master's new repo-wide count guard because
  work-003 takes the corpus 111 → 113 (19 curated, not 17). Driven from the guard's own file:line
  output rather than a blanket replace; three spanned line breaks and needed hand-fixing.

**Two independent branches, one decision.** Master lowered `minimum_grade` `A+` → `B-` the same day
for the same reason (a gate loop that was not terminating). Same value, complementary rationale —
kept both halves in `settings.yml`. And `maintainer.mdx` showed each branch fixing *one half* of the
same stale claim: ours said 92 skills/10 agents, master's 111 skills/9 agents; disk says 113/10.

**Left alone, deliberately:** `aid-deep-review`'s own page charts as a generic `residual` shape
(STEP-1…6) because master's extractor never classified it. That is pre-existing — master has no such
skill — not a merge regression, and teaching the extractor its state machine is a feature, not a
merge fix.

### Q20 -- four things cycle 10 turned up and did NOT fix, with the evidence (2026-07-30)

- **Category:** Defect / observation
- **Impact:** Medium (1), Low (2-4)
- **Status:** Open -- recorded so none has to be rediscovered. Each names why it is out of
  delivery-015's scope (the grading backend).

**1. `aid-discover`'s per-document grade ladder has 9 letters; `grade.sh` has 16.**
`canonical/skills/aid-discover/SKILL.md § Grading Criteria` defines meanings for `A+ A B+ B B- C+ C
D F` only. A reviewer told to use that table cannot express `A-`, `C-`, `D+`, `D-`, `E+`, `E`, `E-` --
7 of the 16 letters `grade.sh` produces. Cycle 10 removed the **second grade producer** in that
section (the "Overall grade = weighted average where architecture, module-map and coding-standards
count double" rule, which averaged where `grade.sh` is worst-dominated and whose weights nothing
computed). The remaining letter-vocabulary mismatch is a prose gap, not a second producer, and
extending the table to 16 rows is an `aid-discover` change.

**2. `test-actback-fixtures.sh`'s isolation canary fails under any concurrent test run.**
`ISO-CANARY-01` scans the whole of `$HOME` for new `.aid` directories, so it reports temp dirs
created by *other* suites running at the same time. MEASURED: run in parallel with four other
suites it failed, naming `/c/Users/andre.vianna/AppData/Local/Temp/tmp.*/.aid`; run alone
immediately after, 20/20 passed. The canary is right to exist -- it caught a real HOME-escape once
(KI/work-018) -- but it needs to be scoped to paths the suite itself could have created, or CI will
flake as soon as suites run concurrently.

**3. `\|` inside an awk regex is undefined behaviour, and the repo uses it ~67 times.**
gawk 5.4 (local) and mawk (ubuntu-24.04, CI) both treat `/\|/` as a literal pipe, so nothing is
broken today. But an awk that reads it as the alternation operator sees `/|/` -- empty-or-empty,
which matches at every position -- and any count built on it becomes garbage that is still a number.
MEASURED extent: 17 occurrences of `/\|` and 50 of `\|/` across 24 files under
`canonical/aid/scripts/` + `tests/canonical/`. Cycle 10 hardened only the one assertion it authored
whose arithmetic depended on it (`CK06`, now `[|]`). Converting the rest is a repo-wide sweep with
no defect behind it.

**4. `## Knowledge Summary Status` carries 17 body lines the template declares none of.**
Cycle 10 fixed the two fields this delivery introduced (`Grade`, `Checklist` -- declared as table
rows while `state-generate.md` writes them as body lines) and declared `Grade Source` alongside
them. The other 14 remain undeclared, two of them (`Theme`, `Output`) declared as table rows *and*
written as body lines, and two more restating frontmatter scalars under different names
(`Last Reviewed KB Date` vs `last_kb_review`, `Last Summary Date` vs `last_summary`). The real list
is recorded in `discovery-state-template.md`'s section comment so the next change starts from it.

### Q19 -- the per-skill settings override cannot be written into a file that passes its own lint (2026-07-30)

- **Category:** Defect
- **Impact:** Medium
- **Status:** Open -- **NOT fixed here.** Out of delivery-015's scope (`lint-settings.sh` and
  `templates/settings.yml` are delivery-014's artifacts; this delivery's Scope names the grading
  backend). Recorded with the reproduction.

Found by trying to use it: the gate bar moved to `B-` for `/aid-execute` only, which is a per-skill
override, and it would not lint.

**What happened.** `read-setting.sh` documents its resolution order at `:5-10` as *"1. Per-skill
override key (e.g., `discover.minimum_grade`) → use if present"*, and implements it at `:306`
by looking up section `$SKILL`, key `$KEY`. Writing exactly that:

```yaml
execute:
  minimum_grade: B-
```

resolves correctly — `read-setting.sh --skill execute --key minimum_grade` returned `B-` (2 bytes,
no quotes) while every other skill still returned the global. Then
`lint-settings.sh --file .aid/settings.yml` exited `1`:

```
[FAIL] S8 unknown top-level key(s), not in the template: execute
```

**Why.** S8 (`lint-settings.sh:243-256`) builds its known-key set from the top-level keys of
`canonical/aid/templates/settings.yml`, which are exactly seven — `name`, `description`, `type`,
`source_control`, `minimum_grade`, `heartbeat_interval`, `knowledge` — plus `format_version`. The
template seeds **no** skill sections, so **every** per-skill override the resolution order's step 1
supports is an S8 violation. Step 1 is unreachable in any project whose settings file is linted.

**Confirmed it is S8 and not the value:** with the same `B-` written to the global
`minimum_grade` instead, the linter passes (`bar = B-`) and
`tests/canonical/test-settings-frontmatter-gates.sh` returns 35/35. With the `execute:` section
present, `SG05` (*the live `.aid/settings.yml` passes*) and `SG07` both failed — so the suite does
catch it; nothing here is invisible, it is simply contradictory.

**Fix, when someone owns it:** seed the skill sections in the template (commented is enough — S8
reads the key names, and `S9` would then require each new key be validated), or teach S8 that a
top-level key matching a known skill name is a legal section. Do not relax S8 generally: its stated
purpose is catching a typo'd key that would otherwise silently fall through to `--default`.

**Consequence, accepted while the `B-` floor stood (2026-07-30 to 2026-08-04):** that bar was set **globally**, so `/aid-discover`,
`/aid-summarize`, `/aid-specify` and the rest also stop at `B-` rather than `A+`. Recorded here
because that is wider than the decision that was made, and it reverts by restoring one line.

### Q18 -- `gap-register.sh` finds its section by substring, and wrote a row into this file's prose (2026-07-30)

- **Category:** Defect
- **Impact:** High
- **Status:** Open -- **NOT fixed here.** Out of delivery-015's scope (`gap-register.sh` is
  feature-004's artifact and this delivery's Scope names only the grading backend). Recorded with a
  reproduction so whoever owns it does not have to rediscover it.

Found by using the script for real, registering delivery-015's essence-gate criteria gap.

**What happened.** `gap-register.sh --promote` reported
`OK: ... registered gap 'kb-essence/load-bearing-fact-coverage' (criteria, Declined, depth 0)`
and exited `0`. The row was written **into the middle of `## Cross-phase Q&A`**, immediately before
`## Calibration Log` -- with no `## Criteria Gaps` heading and no table header above it. A bare
markdown row loose in prose. Nothing complained.

**Why.** The section is located with `index($0, "## Criteria Gaps")` (lines 183, 249, 285, 318,
346) -- a **substring test on the whole line, not an anchored heading match**. This file's Q13
contains the sentence:

> 8. **A dedicated `` ## Criteria Gaps `` table** in the work and discovery state templates, ...

That line *contains* the string, so the writer treated a backticked mention inside a prose bullet as
the section itself and appended at the next `^## ` heading it met.

**Two distinct defects, and the first is the sharper one:**

1. **Substring matching where an anchored match is required.** `^## Criteria Gaps[[:space:]]*$`
   would not have matched the prose. This is *the same defect class delivery-015 exists to remove*
   -- the essence and act-back gates were counting `[FIDELITY]`/`[ACTBACK]` as substrings of free
   text, and task-004 just re-pointed them at the closed `Rule` enum for exactly this reason. The
   register writer has the same bug, one directory away, and it is worse there: a gate that
   miscounts produces a wrong grade, but a *writer* that mislocates its section corrupts the file
   it was asked to protect.
2. **No section-absent handling.** This work's `STATE.md` predates the template that introduced
   `## Criteria Gaps`, so the section genuinely did not exist. The sibling writer
   `writeback-state.sh` documents the opposite behaviour for exactly this case -- its
   `wb_set_frontmatter` "creates the frontmatter block from scratch ... so a not-yet-migrated
   STATE.md degrades gracefully instead of failing". `gap-register.sh` should create its section
   the same way. Instead, with no anchor and no creation path, its `END { if (inreg && !done) ... }`
   guard cannot fire either, so a file without the section and without an accidental prose match
   would have silently registered **nothing at all** while still exiting `0`.

**Reproduce:**
```bash
printf '# S\n\n## Notes\n\nSee the `## Criteria Gaps` table.\n\n## After\n' > /tmp/s.md
bash .claude/aid/scripts/review/gap-register.sh --state /tmp/s.md --promote \
    --gap-key a/b --kind criteria --scope s --criterion c    # exits 0
cat /tmp/s.md            # row lands under ## Notes; no ## Criteria Gaps heading exists
```

**What was done here.** The section was created by hand in template order (between
`## Delivery Gates` and this one), the misplaced row moved into it under a proper header, and every
read API re-verified against the repaired file: `--resolved-keys` returns the key, `--open-keys` is
empty (it is `Declined`), `--depth-of` returns `0`, and a repeat `--promote` adds no second row.
The idempotence probe incremented `Recurrences` to 1 as designed for a re-promoted `Declined` key;
since no gap actually recurred, it was reset to 0 by hand rather than left asserting a loop that
never happened.

**A third defect, found 2026-08-10 in the plan review — and it is the destructive one.**
`--set-status` writes its `--resolution` into **the middle of the `Criterion` cell**, at the first
**escaped** pipe (`\|`) it meets, instead of at the cell boundary. Two of the rows in this
file's register were corrupted by it:

- `scripts/temp-file-lifecycle-and-destructive-paths` — the resolution landed inside the code span
  `` `\|\| true` ``, splitting it, and the row went to **9 cells against an 8-column header**.
- `definition/task-scope-already-discharged-on-disk` — same splice, and here it **destroyed
  content**: the quoted fragment of `review-rubrics/INDEX.md:179` lost `` `SUMMARY` `` entirely,
  restorable only from the cited source.

**Why it is worse than defect 1.** GFM silently ignores cells beyond the header count, so **the
`Resolution` column of both rows never rendered at all** — what displayed there was a fragment of
the `Criterion`. The register's whole job is to be the durable record of a settled decision, and for
those two keys the settled decision was invisible to any reader of the rendered file while the
script reported success. A mislocated row (defect 1) is visible; an unrendered cell is not.

**The fix is the same shape as defect 1's:** locate the target cell by counting **unescaped** pipes
from the start of the row, not by searching for a pipe character. `\|` inside a cell is content.

**Both rows were rebuilt by hand on 2026-08-10** to 8 cells, with the destroyed `` `SUMMARY` ``
restored from `review-rubrics/INDEX.md:179` and both resolutions moved into the `Resolution` column,
the newer decision first. The script itself is **still unfixed** — this remains `Open`.

### Q15 -- Three defects found while executing delivery-013 (2026-07-29)

- **Category:** Defect / process
- **Impact:** Medium
- **Status:** Resolved

Delivery-013 itself was small (a modality lint, four template/skill edits, a back-fill), but running the
full suite around it surfaced three separate problems. Recorded because two of them will recur.

**1. The test suite is not hermetic with respect to `AID_WORK_DIR`. [HIGH]**
`writeback-state.sh` resolves the work folder from `AID_WORK_DIR`. That variable was exported into the
shell used to update this delivery's own task states; `tests/run-all.sh` inherited it, and every
`writeback-state` test then wrote into **this work's real delivery folders** instead of its temp
fixtures. It flipped `delivery-001/task-001` from `Done` back to `In Progress` and deleted its Quick
Check Findings block, and it set `delivery-009/task-006` notes to the test's own literal
`auto-resolved`. 47 of 143 suites failed as a result; the corrupted files were restored from git.

The immediate cause was mine, but the underlying defect is the product's: **a test suite that mutates
real project state when an ambient environment variable happens to be set is a hazard**, and the damage
here was silent — it looked like unrelated test failures, not data loss. The tests should neutralise
`AID_WORK_DIR` (and any sibling resolver input) rather than inherit it. **Not fixed here** — it belongs
to whoever owns the test harness, and the fix is a one-line `unset` per suite plus a guard asserting the
resolved path is under a temp root.

**2. `test-shortcut-engine-contract.sh` was left red by delivery-012. [MEDIUM] -- fixed**
Delivery-012 moved the REVIEW -> GRADE -> FIX loop and its 3-cycle circuit breaker out of
`shortcut-engine.md` and into `/aid-deep-review`. The contract test still asserted the old literals in
the engine, so it had been failing since that migration — five assertions, on a delivery graded A+.
Fixed the same way delivery-008 handled the gap gate: the contract is now satisfied **transitively**,
asserting that the engine delegates and that the delegate carries the loop. Demanding the literals stay
in the engine would require it to keep a copy of exactly what the extraction removed.

**3. The dogfood `.claude/` tree is a THIRD destination, and re-rendering does not update it. [HIGH] -- fixed**
AID installs itself: `.claude/` at the repo root is an installed copy of `profiles/claude-code/.claude/`,
held byte-identical by `test-dogfood-byte-identity.sh`. Editing `canonical/` and running the profile
generator updates two of the three trees and silently leaves the dogfood copy stale — here it broke
exactly the five files this delivery touched (748 other assertions still passed, which is what made the
attribution unambiguous). Synced, and the suite returned to 753 pass / 0 fail.

This is the mirror image of delivery-004's failure, where the repo root was edited and the canonical
source was not. **Any delivery that edits `canonical/` must update all three trees**, and no current
gate says so — worth a checklist line wherever the render step is documented.

### Q16 -- delivery-014 findings: a gate that can never pass, and one that runs for three minutes (2026-07-29)

- **Category:** Defect / design
- **Impact:** Medium
- **Status:** Resolved, except where noted

**1. `--fail-on-skip` was unusable as first written. [HIGH] -- fixed**
The flag's purpose is to stop `lint-frontmatter.sh` reporting `PASS` on a KB where every doc was
soft-skipped as pre-migration — a passing record for work never inspected. The first version failed on
*any* skip, which conflated two unrelated things: docs skipped **permanently by design**
(`kb-category: meta`, `source: generated`) and docs skipped as **pre-migration**. This KB has five of
the former, so the flag could never pass, and **a gate that can never pass gets switched off** — which
would have left the wiring worse than useless. Skips are now counted separately and only pre-migration
ones fail. Both directions are tested: a pre-migration doc fails the flag, a meta doc does not.

**2. `lint-settings.sh` silently dropped a corrupted `doc_set` row. [MEDIUM] -- fixed**
A row that lost its leading `- ` stops being a YAML list item, so the row extractor skipped it and the
document simply vanished from the doc set with nothing complaining. That is quieter and worse than a
malformed row. The lint now reports any non-list line inside the block. Found by a negative control that
was itself written wrong first — the fixture produced this case by accident.

**3. The frontmatter lint takes ~190s on a 21-doc KB, and it is now a runtime gate. [MEDIUM] -- NOT fixed**
Step 5a2 of `aid-discover` GENERATE now invokes it, so that cost is paid on every discovery run. It is
roughly 9 seconds per document for a presence-and-shape check, caused by per-field subprocess spawns
rather than by the work itself. **Left as-is deliberately**: fixing it means rewriting the linter's
parser, which is not delivery-014's scope, and correctness-before-speed is the right order. Worth a
follow-up — the same bulk-pass fix used for the rule catalog (222s to 7.2s) and for this delivery's own
`doc_set` validation applies directly.

**4. Per-file process spawns are the recurring Windows trap.** A dogfood sync that ran `cmp` once per
file across 375 files blocked for over an hour; the identical check by file hash in PowerShell took nine
seconds. This is now the third time in this work that per-item spawning has been the bottleneck
(rule-catalog integrity, this delivery's `doc_set` loop, this sync). **On this platform, per-item
process spawning should be treated as the default suspect** whenever something is unexpectedly slow.

### Q17 -- Session handoff at delivery-015 task-003 (2026-07-30)

- **Category:** Process / resume
- **Impact:** Low
- **Status:** Open

**Where:** worktree `.claude/worktrees/work-003`, branch `aid/work-003-delivery-015`.

**Done (committed):** delivery-015 task-001 (SUMMARY rule rows), task-002 (`emit-summary-findings.sh`; `grade-summary.sh` deleted).

**In progress (uncommitted):** task-003 de-score — `manual-checklist.sh` is a recorder; `aid-summarize` surfaces migrated; `knowledge-summary/grading-rubric.md` COV bands removed; `tests/canonical/test-one-grading-backend.sh` added and **23/23 pass**. Staged: `grade-summary.sh` deletion (from task-002, still staged).

**Next steps (in order):**
1. Commit task-003 changes (+ test file).
2. Dispatch review; mark task-003 `Done` at A+.
3. task-004: retire binary verdicts in `emit-summary-findings.sh` / `grade.sh` callers.
4. task-005: remove two-grade model from remaining surfaces.
5. task-006: finalize NFR-7 test suite (mostly written).
6. Delivery-015 gate (A+), then delivery-016.

**Shell:** use Git Bash on Windows (`C:\Program Files\Git\bin\bash.exe`), not WSL. Unset `AID_WORK_DIR` before running `tests/run-all.sh` (see Q15).

### Q1 -- Review extraction: two skills, or one skill with a depth mode?

- **Category:** Design-Decision / scope-shaping
- **Impact:** High
- **Status:** **Answered** 2026-08-09 — **(a) REVISED: ONE skill, not two**; (b)-(d) ratified from
  disk; (f) decided; **(e) answered 2026-08-09 — a live chaining confirmation on codex, copilot-cli
  and antigravity is scheduled before ship; full reasoning at `Q7 #4`**
- **(a) REVISED (2026-08-09, human decision) — supersedes the 2026-07-27 two-skill answer.**
  **There is exactly one review skill: `/aid-review`.** `aid-deep-review` and `aid-light-review` both
  merge into it, and `/aid-audit` is eliminated. Neither of the two new skills has ever shipped
  (`git ls-tree --name-only origin/master:canonical/skills/` returns **76 names, among them `aid-review` and neither merged skill**), so this is prevention,
  not migration — no adopter ever sees `aid-deep-review` or `aid-light-review`.
  **The cheap screening pass survives; only the second *skill* goes.** It becomes an **explicit named
  entry path** of `/aid-review`, not a `depth` flag. The 2026-07-27 rationale for two skills — *"a
  single skill with a `depth` flag would put both behaviours behind one entry point, and the failure
  mode is silent"* — is honoured rather than overturned: the objection was to **silence**, and named
  entry paths are not silent. A `depth` flag remains rejected.
  **Three entry paths must be explicit, because there are now three callers, not two:** (1) a human
  invoking `/aid-review` ad-hoc on an arbitrary artifact, with **no manifest**; (2) a pipeline skill
  chain-calling the graded gate **with a full manifest**, where a missing field is *"a caller error,
  not something to infer"*; (3) the **screening** pass — `FR-C9`'s up-front precondition scan that
  batches gaps before the graded pass. Inferring which is intended would reproduce exactly the failure
  this answer preserves.
  **What this deliberately does NOT cut.** `aid-screener` stays (10-agent roster stands; it is cited in
  9 files including `architecture.md` and `decisions.md`, and **delivery-010 already shipped `Done`**
  splitting the agent boilerplate precisely so the screener would not inherit the exhaustiveness
  mandate — cutting it would make that delivery work done for nothing). `FR-C9`'s primary path stands,
  so gap resolution does **not** revert to mid-review interruption. `AC-13`/`NFR-3`'s cost claim keeps
  its subject: light + deep still costs less than deep alone, now measured across the **screening**
  and **gate** entry paths of one skill rather than two skills. Those are two of the three paths
  named above; the **ad-hoc** path carries no cost claim, so "two" here counts the paths the
  comparison spans, not the paths the skill has.
  **Amendments this forces — ALL APPLIED as of 2026-08-09; this read *"not yet applied"*:** `FR-A1` states the split as *"two skills"* and must be
  amended to one skill with named entry paths; `FR-A2`, `FR-A4`, `FR-A5` and `FR-C9` survive intact but
  their `aid-light-review` references must be re-pointed at the screening entry path.
- **(f) Answer (2026-08-09, human decision).** **`/aid-deep-review` merges INTO `/aid-review`** — that
  direction, not the reverse — and **`/aid-audit` is eliminated**. **Superseded within the hour by the
  `(a)` revision above:** `aid-light-review` merges in as well, so the end state is **one** review
  skill, `/aid-review`, with named entry paths — leaving `/aid-triage` nothing to route *between*, and
  reducing its obligation to naming the single skill. The reasoning below stands unchanged; only the
  count does.
  **Why this direction is cheaper than the reverse, which was the option originally put.**
  `git ls-tree --name-only origin/master:canonical/skills/` returns **76 names**, and of the four review-ish skills only `aid-review` is among them — `aid-audit`,
  `aid-deep-review` and `aid-light-review` are all absent upstream. So (i) eliminating `/aid-audit` is
  **catching up with master**, which already retired it with the alias model, not a breaking change;
  and (ii) `aid-deep-review` **has never shipped** — renaming before merge means the name never
  reaches an adopter, with no rename churn and no deprecation cycle. Naming also improves: review is
  deep by default and `light` marks the exception, so the qualifier leaves the common case.
  **Cost 1 — blast radius:** 12 `canonical/` files, 4 `tests/` files, 13 work-003 artifacts. Notably
  `delivery-017/task-002/DETAIL.md`, which passed `A+` at cycle 7 and whose whole Scope is the gate in
  `aid-deep-review` **RESOLVE**, including `AC-3`'s command `grep -rl "/aid-deep-review"`. It has not
  executed (delivery-017 is `Pending-Spec`), so this is pre-execution revision rather than rework — but
  it is the single highest-defect file in this work and needs a re-review after the change.
  **Cost 2 — a design question the merge opens, to be settled by whoever carries it.** `/aid-review` is
  human-invoked on an arbitrary artifact; `aid-deep-review` is a callable engine whose RESOLVE states
  *"Every field except `gap_depth` is required; a missing one is a caller error, not something to
  infer."* The merged skill must serve **both** a human with no manifest and a pipeline skill with a
  full one, via **two explicit entry paths** — **count superseded by `(a)`: three, not two.** `(a)` adds the **screening** path to this human/pipeline pair, and the note above limits this block's supersession to the *skill* count only, which left this sentence standing when it should not have. The live figure is three, everywhere. Collapsing them into one implicit path would reproduce
  exactly the failure `(a)` rejected: two behaviours behind one entry point, failing silently.
  **Not yet implemented — needs a delivery to carry it.**
- **Triage 2026-08-09.** **(a) Two skills, not a depth flag** — both `aid-deep-review/` and
  `aid-light-review/` ship, and the deep skill states the reason: a `depth` flag *"would put both
  behaviours behind one entry point, and the failure mode is silent."* **(b) Two agents** — a new
  `aid-screener` (small tier, `Read, Glob, Grep`, no `Bash`) plus the retained `aid-reviewer`; roster
  9 → 10 and the KB records it. **(c) An invocation manifest** in `reviewer-brief-template.md` — the
  shared skill renders the brief from the manifest plus exactly two caller sections; the six per-skill
  briefs shrank 68-101 → 31-33 lines. **(d) `/aid-deep-review` owns the REVIEW→FIX loop** and the
  non-improvement breaker; the caller keeps only its two sections, its executor agent, its minimum
  grade and its own state machine. **(e) Half-settled** — the design no longer forks on
  `skill_chaining` (*"One fallback design, not five"*) and five-profile render parity is tested
  statically (RX13-RX16), but the empirical claim is unverified: the `skill_chaining = true` lines for
  codex/copilot-cli/antigravity were authored **before** work-003, so they are the same declaration
  this question called unverified, not a verification of it. **(f) OPEN — untouched.**
  `/aid-review`, `/aid-light-review` and `/aid-deep-review` all ship and nothing
  disambiguates them (**corrected 2026-08-10**: this also listed `/aid-audit`, which had already been deleted by `6cb4aa1c` in work-004. It reached this branch at the **2026-08-09** master merge `f0eaf415` — *not* the 2026-07-30 one: `git merge-base --is-ancestor 6cb4aa1c 7ba8e16c` exits 1, and `7ba8e16c` still carries `aid-audit`. So the skill was absent from this branch on the triage day itself, though only just. `(f)`'s own Answer says master *"already retired it"*): `/aid-triage` has no routing row for the two new ones, neither new skill's
  See-also mentions the old ones, and `/aid-review` still dispatches `aid-reviewer` directly instead of
  calling `/aid-deep-review` — the ninth of nine caller migrations that delivery-012 scoped **in** and
  closed `A+` without delivering.
- **Context:** The soft/hard review split already exists three times over
  (`aid-execute` Step 1.5 quick-check vs DELIVERY-GATE; `aid-discover`
  `panel: full` vs `panel: collapsed`; `aid-review` simple vs standard/complex),
  but each is embedded in its host skill rather than shared. Proposal under
  discussion: extract `aid-light-review` + `aid-deep-review` as chainable
  skills so calling skills shrink and review becomes reusable. Open
  sub-questions: (a) two skills vs one skill with a depth parameter;
  (b) whether each gets its own agent or both reuse `aid-reviewer`;
  (c) how the 5-section brief is passed through a skill invocation
  (skills take one free-form argument); (d) who owns the REVIEW->FIX loop
  and the executor dispatch inside it; (e) `skill_chaining` capability is
  confirmed for cursor + claude-code but not yet verified for codex,
  copilot-cli, antigravity; (f) naming collision with the existing
  on-demand `/aid-review` + `/aid-audit`. (`/aid-audit` no longer exists — work-004's `6cb4aa1c` deleted it, which reached this branch at the 2026-08-09 master merge `f0eaf415`. The question is recorded as asked; `(f)`'s answer eliminates the collision by eliminating the skill.)
- **Suggested:** Resolve during Describe/Define; the answer shapes the
  feature decomposition.
- **DECIDED (2026-07-27): two skills** -- `aid-light-review` and `aid-deep-review`,
  chain-called by the pipeline skills.
- **DECIDED (2026-07-27): two agents.** `aid-screener` (new; small tier; read-only
  `Read, Glob, Grep`, no `Bash`) + `aid-reviewer` (retained as the deep reviewer, so all
  six existing dispatch sites keep working). Roster grows 9 -> 10; the nine-agent count
  is a KB-recorded fact this meta-work revises, not a constraint.
  - **Deciding reason:** `aid-reviewer`'s body mandates exhaustiveness ("find nothing
    more to find", "enumerate the class, not the instance"). A cheap bounded pass cannot
    be obtained from that prompt -- the exhaustive instruction wins. A screener needs a
    *different* instruction set, not a subset. Supporting: different tool grants
    (read-only), per-agent tier defaults that actually stick, different output contracts,
    and the tier-invariant carve-out becomes self-evident for an agent that structurally
    cannot grade.
  - **Naming:** `aid-screener`, not `aid-triager` -- `aid-triage` is an existing skill and
    "triage" is used throughout the codebase. "Screening" is also the more accurate word
    (a cheap uniform first pass, where a negative result explicitly is not an all-clear --
    which encodes FR-A4 in the name). Skill stays `aid-light-review`, since "screen"
    already means a UI view in this codebase.
- ~~Still open: naming against the existing on-demand `/aid-review` + `/aid-audit`; how the 5-section brief is passed through a skill invocation; who owns the FIX loop.~~ **All three CLOSED 2026-08-09 by `Q1(a)`/`(f)`, struck rather than deleted so the record shows what was open.** Naming: one skill, `/aid-review`, with three named entry paths; `/aid-audit` is not a competing name because it does not exist. Brief passing: the invocation manifest, shipped by `delivery-012`. FIX loop: the caller's own executor agent, named per-invocation in the manifest.

### Q2 -- Severity model: collapse to one source of truth, keep artifact flavors

- **Category:** Design-Decision / correctness
- **Impact:** High
- **Status:** **Answered** 2026-08-09 — ratified from disk, not re-decided; see **Answer** below
- **Answer:** **Collapsed to one source, and it shipped.** `grading-rubric.md § Severity Scale`
  (marker-delimited `AID:SEVERITY-SCALE:BEGIN/END`) is the sole definition; the six former rivals now
  cite it rather than define it — `reviewer-ledger-schema.md`, `kb-authoring/review-rubric.md`,
  `aid-reviewer/AGENT.md`, its `README.md`, `quality-gates.md`, `aid-execute/references/reviewer-guide.md`.
  The specific contradiction is gone (`grep -rn "incorrect behavior\|incomplete but not wrong"` over
  those files returns nothing). The per-artifact **flavours became the catalog**: `review-rubrics/` =
  `INDEX.md` plus nine class files carrying 85 rule rows, with a universal tier holding the defect
  taxonomy, the two authority ladders, severity derivation and evidence admissibility. Severity is
  **looked up** from the matched rule, never assigned (`AGENT.md`: *"You do not assign it"*); modality
  `MUST/SHOULD/COULD` sets the band and blast radius × reversibility selects within it; FR-B7's damage
  axes were cut as double-counting; confidence never modifies severity; there is no third source.
  **Residual, tracked separately:** `reviewer-guide.md` still carries the retired `CODE/TASK/SPEC/KB`
  source table — fallout from the un-executed file retirement, recorded as `Q26` item 1, not a
  surviving severity definition.
- **Context:** Severity is defined in seven places with four distinct meanings
  (`grading-rubric.md` + `reviewer-guide.md` + `quality-gates.md`;
  `agents/aid-reviewer/AGENT.md` + its `README.md`;
  `reviewer-ledger-schema.md`; `kb-authoring/review-rubric.md`). Two directly
  contradict on the most-used band: one defines MEDIUM as "incorrect behavior
  (non-critical)", the other as "incomplete but not wrong". Because `grade.sh`
  derives the grade deterministically from (severity, count) over rows with
  Status in {Pending, Recurred}, severity misclassification propagates straight
  into the gate decision -- the determinism guarantee is only as strong as the
  severity assignment feeding it. Agreed direction: collapse to a single
  artifact-neutral source of truth; the per-artifact "flavors" become a
  formalized rubric-catalog layer over it rather than competing definitions.
- **Suggested:** Formalize as: one canonical severity scale + per-artifact-class
  rubric rows that map defect-class -> severity, so severity is looked up, not judged.
- **Agreed so far (2026-07-27 discussion):**
  - Grading is a *distance from ideal* metric -- readable by both a human and a
    script. Reducing severity subjectivity is what makes that distance meaningful.
  - **Criteria come only from the two sources of truth:** the KB (guidelines,
    standards, models, structures, decisions) and the work's own spec documents
    (REQUIREMENTS / SPEC / BLUEPRINT / DETAIL -- their FRs and ACs). No third
    source. "Established best practice" is not a criterion.
  - Requirement **modality** (must / should / could / suggestion) should be stated
    explicitly in FRs and ACs and is a primary severity input.
  - **Damage** (reach / reversibility / silence) is an agreed severity axis.
  - Reviewer confidence must NOT modify severity. Uncertainty escalates to the
    user instead (see Q4).

### Q3 -- Review-path defects (deferred until the target process is settled)

- **Category:** Defect-Backlog
- **Impact:** Medium
- **Status:** Deferred
- **Context:** Found during the pre-work analysis; user decision is to fold the
  fixes into this work once the target review process (agents + skills +
  possibly hooks) is established, rather than patching now.
  (a) `aid-execute/references/state-review.md` contradicts itself -- opening
  line says a full reviewer "produces the full grade", closing contract note
  says no grade is computed at task level; references `Step 2` twice (**corrected 2026-08-10 twice over**: the count read *"four"* — `grep -c "Step 2"` on that file returns 2 — and the word *"removed"* was wrong, as `(b)` below records: `Step 2 (REVIEW)` is **live** at `state-delivery-gate.md:145`. What survives as a defect is narrower and still open: that file has no `Step 1` or `Step 2` heading of its own, so its two forward references point into a **different** state machine than the one it serves)
  (b) ~~`aid-execute/references/reviewer-guide.md` header points at the same removed "Step 2".~~ **Premise corrected 2026-08-10: `Step 2` is not removed.** `state-delivery-gate.md:145` carries a live `## Step 2: REVIEW` heading, which `delivery-022`'s Scope states outright. The header is stale for a different reason — it points at a step in a *different* state machine than the one the file serves — and the case for retiring the file is its retired source table plus zero referrers.
  (c) ~~The `references/reviewer-guide.md` pointer in the execute brief is not rewritten by the profile renderer, unlike every sibling path in the block.~~ **MOOT 2026-08-10: the pointer does not exist.** `grep -rln 'reviewer.guide' canonical/` exits 1 — the file has no referrers under `canonical/` at all, so there is nothing for the renderer to rewrite. Retiring the file closes this by removing the subject rather than fixing it.
  (d) ~~`agents/aid-reviewer/README.md` claims Large tier against canonical `tier: medium`~~ — **CLOSED 2026-08-10, by the `aid-reviewer` rewrite.** The README's `## Tier` section now states the opposite and agrees with the frontmatter: *"**Medium by default, escalated to Large per dispatch.** The canonical frontmatter is `tier: medium`"*, and it explicitly rejects a Large default as contradicting *"the frontmatter that actually configures the model"*. The second half stands: six skills hardcode Large via the reviewer >= executor invariant, so the medium default is nearly never used.
  (e) `worktree-lifecycle.sh` run under WSL writes a `/mnt/c/...` gitdir
  pointer that Windows-native git cannot resolve, producing an unusable
  worktree (hit while allocating this very work; repaired manually).
- **Suggested:** Fold into this work's delivery plan after the target design
  is agreed.

### Q4 -- Uncertainty escalation and source-of-truth self-healing

- **Category:** Design-Decision
- **Impact:** High
- **Status:** **Answered** 2026-08-09 — ratified from disk, not re-decided; see **Answer** below
- **Answer:** **Both halves shipped as decided.** *(a) Escalation.* The trigger set is a **closed
  three-token enum** on the gap row's `Description`, not agent discretion: `[GAP:CRITERIA]` (no rule in
  either ladder speaks to the concern) **blocks the grade**; `[GAP:CRITERIA:NB]` and `[GAP:EVIDENCE]`
  do not. The block is enforced mechanically — `check-gaps.sh --ledger <path>` precedes every grade
  site and `grade.sh` is *"only reachable on exit 0"*. A source **conflict** is handled separately and
  is never the reviewer's to resolve: *"Two sources at equal rank — surface both, pick neither."* The
  calling skill asks **once for the whole batch**, because a dispatched sub-agent cannot hold a
  dialogue. So: batched-and-blocking for criteria, queued for evidence.
  *(b) Self-healing is user-gated.* Ten-step lifecycle in `criteria-gap-protocol.md`: the reviewer
  **proposes in its return message** (*"Proposals never enter the ledger"*) and **writes nothing** to
  any source of truth; the calling skill asks the user, promotes the answer to a **git-tracked**
  register, then halts and routes to the skill that owns the document (KB → `/aid-update-kb`,
  REQUIREMENTS → `/aid-define`, SPEC → `/aid-specify`, PLAN/BLUEPRINT → `/aid-plan`, DETAIL →
  `/aid-detail`). Every answer is scoped *canon or one-time*. The *"established best practice"*
  fallback has been removed from the agent body — the hole that made self-healing necessary is closed.
- **Context:** Two related user decisions from the 2026-07-27 discussion.
  (a) **Uncertainty escalates, never guesses.** When the reviewer cannot ground a
  finding in the KB or the spec documents, it must ask the user rather than fall
  back on opinion. Open sub-question: uncertainty is itself subjective, so this
  needs defined *triggers* (source silent / sources conflict / no evidence
  obtainable / severity is gate-determining and the rule does not clearly apply)
  rather than agent discretion -- and a decision on whether escalation BLOCKS the
  pipeline or queues into the existing batched Q&A backlog.
  (b) **Self-healing is user-gated.** Recurring findings are evidence that a source
  of truth (KB doc or spec document) is wrong or incomplete. The agent may detect
  and propose, but the decision to amend an established source of truth is
  delegated to the user -- matching the existing capture-and-flag / never-auto-apply
  rule and the `## Q&A (Pending)` backlog mechanism.
- **Suggested:** Define the trigger set + the block-vs-queue rule during Describe;
  reuse the existing Q&A backlog rather than inventing a new channel.
- **DECIDED (2026-07-27):** The golden rule is **ask the user**. The
  "established best practice" fallback in `agents/aid-reviewer/AGENT.md` and the
  undefined quality terms in `aid-execute/references/reviewer-guide.md` were added
  to cover greenfield projects and brownfield projects missing definitions. That is
  now considered a mistake and is to be removed. When a criterion is missing, the
  reviewer identifies the gap in the source of truth and asks the user to define the
  guideline (offering suggestions) -- it never substitutes common best practice.

### Q5 -- Criteria-gap interrupt: halt, resolve the source of truth, resume

- **Category:** Functional-Requirement / new capability
- **Impact:** High
- **Status:** **Answered (text correction outstanding)** — triaged 2026-08-09; **decision 3
  half-shipped, decision 7 reversed. No decision is open**: decision 3 is superseded by the `Q1(a)`
  one-skill revision and decision 7's text correction is scheduled at `Q26` item 4, carried by
  **`delivery-021`** — carrier corrected 2026-08-10; this read *"riding the merge delivery"*, which is
  `delivery-022` and does not scope it. This entry is not awaiting a human.
- **Triage 2026-08-09.** **Decisions 1, 2, 4, 5, 6, 8 shipped as decided** — resolve-before-grading is
  enforced by `check-gaps.sh` ahead of every grade site; the improvement-opportunity routing table and
  git-tracked register exist; a *"no"* gets its two follow-ups (what instead, canon or one-time); the
  reviewer never writes and triggers the owning skill; the recursion cost is accepted and stated
  (*"Each level costs a full human-gated skill run"*); answer size stayed unbounded.
  **Sub-questions (a), (b), (c), (e), (f) all shipped** — the halt is `PAUSE-FOR-USER-ACTION`, not a
  new mechanism; recursion terminates at **depth 2 by demoting rather than discarding**
  (`[GAP:CRITERIA]` → `[GAP:CRITERIA:NB]`, register keeps `Depth: 2`); "skip resolved" vs clean context
  is resolved **structurally** — the reviewer is given only its scratch path and is never told the
  canonical one; the conversation lives with the calling skill, batched and asked once; a waiver is
  durable and *"a recurrence never resets the answer."*
  **Decision 3 — "gap detection lives in both passes" — CONTRADICTED on the light half.**
  `aid-light-review/SKILL.md:21-23` lists writing `G-` rows under what it deliberately does **not** do,
  and its REPORT state writes nothing. The deep half shipped; the light half did not. See `Q26` item 3.
  **Decision 7 — "restart, not resume" — REVERSED, deliberately.** `criteria-gap-protocol.md:75` ships
  *"coverage rows **resume** rather than restart"*, superseded by `Q6` proposal 3. **This entry's text
  needs correcting, not just its Status** — see `Q26` item 4.
  **(d) greenfield criteria-vs-evidence — half-shipped.** The universal rule landed (`[GAP:CRITERIA]`
  blocks everywhere, no greenfield exception in the reviewer body); the named edit to
  `document-expectations.md` 50-52 never happened — see `Q26` item 2.
- **Context:** Follows from Q4's decision. Some issues are not findings *about the
  artifact* -- they are gaps in the review's own preconditions, and they cannot be
  graded because no yardstick exists. Example: reviewing Java code when no Java
  coding standard is defined. Required behavior: **stop the review, ask the user,
  update the KB or the spec documents accordingly, then resume.** No mechanism for
  this exists today -- the ledger can only express findings about the artifact, and
  the existing paths (IMPEDIMENT, Q&A backlog) either block terminally or defer
  without resuming.
- **DECIDED (2026-07-27):**
  1. **Type 2 must be resolved before grading.** No grade is computed while any
     precondition gap is open.
  2. **Gaps are an improvement opportunity, not an obstacle.** Greenfield projects,
     and brownfield projects with documentation gaps, use the review process itself
     to improve the KB and the work documentation.
  3. **Gap detection lives in both passes.** A light review / triage pass detects
     gaps early, but the deep review must be able to find them too -- the
     precondition scan is not a one-time gate that exempts the deep pass.
  4. **A "no" answer is followed up twice:** (i) "what to do instead?", and
     (ii) "is this one-time, or canon for the project?"
  5. **Reviewer still never writes.** The reviewer detects the gap, proposes a
     solution, discusses with the user, and -- once well defined -- triggers the
     proper skill with a proper prompt: `/aid-update-kb` for KB gaps, or
     `/aid-define` / `/aid-specify` / `/aid-plan` / `/aid-detail` for work-document
     gaps depending on which document changes. Another agent performs the update.
  6. **Recursive review cost is accepted.** Those skills run their own review
     cycles; that recursion is a cost the design pays deliberately.
  7. **Restart, not resume** -- but previously resolved issues may be skipped.
  8. **Answer size is unbounded.** The user decides how big the definition is.
- **Open sub-questions (revised):**
  (a) **Call-and-return -- RESOLVED (2026-07-27) by sequencing, not by mechanism.**
  Primary path: `aid-light-review` batches all gaps -> HALT with resolution commands ->
  user resolves -> `aid-deep-review` grades. Forward chaining and halts only; the
  coverage manifest survives the halt so re-invoking resumes. Exception path (deep
  review finds a gap anyway): halt and re-invoke, the existing house idiom.
  **Scope correction:** the four-advance-type contract governs *state transitions
  within a skill*, not skill-to-skill invocation -- the earlier blanket "no
  call-and-return" reading was too broad. Invoke-and-use-result does have precedent
  (`aid-query-kb` -> `/aid-read-ticket`, `aid-review` -> `/aid-update-ticket`), but only
  for short read-only non-interactive delegations. Delegating to a long human-gated
  skill like `/aid-update-kb` has no precedent and would nest two approval gates,
  which is the real reason for halt-and-route. Rejected alternatives: dispatching the
  update *agent* directly (bypasses the update skill's own review cycle and approval
  gate, contradicting decisions 5 and 6) and adding a fifth advance type (needs a
  return-stack, touches every skill; kept in reserve).
  (b) **Recursion termination.** A gap-resolution review can itself raise a Type 2
  gap -- including a gap in the very standard being authored. Needs a depth limit or
  a restricted mode for gap-resolution reviews.
  (c) **"Skip resolved" conflicts with clean-context rules.** `aid-discover`'s
  contamination-prevention rule forbids telling a reviewer what was fixed or what the
  previous grade was. Skipping by *finding* would violate it; skipping by *scope*
  (do not re-review untouched artifacts) preserves it.
  (d) **Conflict with existing greenfield policy -- DECIDED (2026-07-27):**
  `aid-discover` halts and asks like everything else; no relax-and-continue exception.
  **Refinement raised for confirmation:** the existing greenfield mode conflates two
  different gaps. Missing **criteria** (no rule exists to measure against) is a Type 2
  gap and halts -- this is what the decision covers, and it should apply universally
  including discover. Missing **evidence** (greenfield has no code yet to verify a
  claim against) is a different axis; halting there would demand the code be written
  before the design can be reviewed. Recommendation: halt-and-ask for missing
  criteria everywhere; retain evidence-substitution for greenfield.
  (e) **Where the conversation lives.** A dispatched sub-agent cannot hold a
  multi-turn user conversation; the calling skill must own the discussion and the
  downstream trigger. Reinforces the Q1 skill-extraction design.
  (f) **Waiver durability.** A "no" answer plus its what-instead / one-time-vs-canon
  follow-ups must be recorded so the same gap is never re-asked.

### Q6 -- Resume mechanism: coverage manifest + two review modes

- **Category:** Design-Proposal
- **Impact:** High
- **Status:** **Answered** 2026-08-09 — ratified from disk; every proposed item shipped
- **Answer:** **All five proposal items accepted and shipped, plus both `DECIDED` items and all four
  consequences.** The coverage manifest lives **in the ledger** as `U-NNN` rows — a third row kind
  alongside findings and gaps — with the vocabulary renamed to `Unexamined | In Progress | Examined |
  Skipped`. Mode selection is **one `test -f`** on the scratch path: present → resume, absent →
  new-cycle. Reconciliation **moved off the reviewer to the orchestrator** (FR-D5), on the stated
  principle *"Independence protects judgment, not bookkeeping"*. Invalidation on resume is by `art=` /
  `rs=` digest at (artifact × rule set) granularity, via `plan-resume.sh`, which invalidates a unit on
  `In Progress`, a changed artifact digest, or a changed rule-set digest — **never by finding**. All
  three interruption types are in scope, with `In Progress` units treated as unexamined. Loop
  detection rides the git-tracked gap register's `Depth` and `Recurrences` columns. `grade.sh` needed
  **no change**, exactly as the proposal's verification predicted, because `U-`/`G-` rows are
  grade-inert. Consequences: the schema dropped "one row = one finding"; `G-` rows are promoted to the
  register **before** anything is deleted; the surgical helper `writeback-ledger.sh` is mandatory and
  the old `cat >` heredoc instruction is superseded; parallel panel merges keep `U-`/`G-` rows
  per-mandate with namespaced IDs.
- **Context:** User asked whether resuming a review can rely on the ledger, and drew
  a distinction: **resuming** an interrupted review keeps context of what was done;
  a **new review in a grading cycle** is a fresh clean-context pass.
- **Finding:** the ledger is necessary but not sufficient. It records *findings*, not
  *coverage* -- it cannot distinguish "examined and clean" from "never reached".
  Resume needs progress state in addition to the ledger.
- **Proposal:**
  1. **Coverage manifest.** Before reviewing, enumerate the scope into atomic units
     (artifact, or artifact x rule-set). Each unit carries
     Pending / In Progress / Done / Skipped(reason). The reviewer marks a unit Done
     as it completes it -- this is the "safe checkpoint" the existing subagent
     stop-poll contract already promises. Ledger = what is wrong; manifest = what was
     looked at.
  2. **Two modes.** RESUME (same review, interrupted) may see its own prior progress
     and findings -- it is continuing, not re-judging. NEW CYCLE (after FIX) is a
     fresh clean-context reviewer with no prior findings; the **orchestrator**
     reconciles new findings against the old ledger and updates Status.
     Principle: *independence protects judgment, not bookkeeping.*
  3. **Invalidation on resume.** Artifact changed -> re-review that unit. Criteria
     changed (KB/spec updated, e.g. after a Q5 gap resolution) -> re-review every
     unit the changed criterion applies to. This makes decision 7
     ("restart, skip resolved") precise.
  4. **Interruption types.** (i) halt to ask the user; (ii) user actively stopped;
     (iii) involuntary (crash / timeout / context exhaustion) -- added by proposal,
     needs user confirmation that it is in scope.
  5. **Loop detection.** Record resume count and gap-resolution depth; the same gap
     ID raised twice auto-halts with a possible-loop flag rather than relying on the
     user to notice.
- **Resolves an existing contradiction:** `reviewer-ledger-schema.md` (cycle N>=2
  reviewer reads the prior ledger and updates Status) and `aid-execute`'s delivery
  gate (same) directly contradict `aid-discover`'s contamination-prevention rule
  ("Do NOT include previous review results in any mandate prompt"). Discover already
  resolves it the right way -- mandate reviewers write scratch ledgers and the
  orchestrator merges/reconciles in its aggregate step. Adopt that model globally.
- **Existing machinery to reuse:** the subagent heartbeat protocol (liveness +
  coarse progress, e.g. `REVIEW | 4/21 docs | ...`), the `STOP_FILE` cooperative
  stop-poll written only by `write-control-signal.sh`, and the "halt at the next safe
  checkpoint -- finish your current atomic unit" contract already in the agent body.
- **DECIDED (2026-07-27):**
  1. All three interruption types are in scope: (i) halt to ask the user,
     (ii) user actively stopped, (iii) involuntary (crash / timeout / context
     exhaustion).
  2. **The manifest lives IN the ledger file**, and serves both resume and loop
     detection.
- **Verified safe (`canonical/aid/scripts/grade.sh`):** the grader counts a row only
  when `cols[3]` is *exactly* one of `[CRITICAL] [HIGH] [MEDIUM] [LOW] [MINOR]` AND
  `cols[4]` is exactly `Pending` or `Recurred`. A coverage or gap row carrying `--`
  in the Severity column is therefore never counted, whatever its Status. Putting
  the manifest in the ledger needs **no change to grade.sh**.
- **Proposed row scheme (one 7-column table, three row kinds by `#` prefix --
  precedent: `aid-discover` already uses `M1-NNN` / `M2-NNN` / `TB-NNN` / `AB-NNN`):**
  - `1, 2, 3...` -- findings. Bracketed severity. Grade-bearing.
  - `U-NNN` -- coverage units. Severity `--`. Status
    `Unexamined | In Progress | Examined | Skipped`. `Doc` = artifact,
    `Description` = rule-set, `Evidence` = checkpoint stamp.
  - `G-NNN` -- gap / interrupt events. Severity `--`. Status `Open | Resolved`.
    Records the triggered skill and the resume count; a repeated `G-NNN` is the
    loop signal.
- **Consequences to resolve:**
  (a) `reviewer-ledger-schema.md` must drop "every row is one finding" and
  "exactly one markdown table ... no sections" -- a spec change, not a parser change.
  Keep the table shape valid so the grader's legacy prose-counting fallback is never
  reached.
  (b) **Durability.** The ledger is deleted at skill DONE and `.aid/.temp/` is
  gitignored, so `G-NNN` history dies with it. Loop detection works within one
  invocation; cross-invocation detection needs the gap rows promoted to `STATE.md`
  on DONE.
  (c) **Write cost -- RESOLVED (2026-07-27): checkpoint after every unit.** This
  makes a surgical row-update helper **mandatory**, not optional (per-unit full-file
  `cat >` rewrites are untenable). Required helper behavior: update one row in place
  by ID; append a new row; never renumber; preserve the 7-column table shape so the
  grader's table path (not its legacy prose fallback) is used. Single-writer per
  ledger file holds even under parallel mandate dispatch, since each mandate writes
  its own scratch ledger -- no locking needed. Consequence: the `## File Writing`
  section of `agents/aid-reviewer/AGENT.md` (the `cat >` heredoc instruction and its
  truncation warning) is superseded and must be rewritten.
  (d) **Parallel merge.** Under `aid-discover`'s parallel mandate dispatch each
  reviewer writes its own scratch ledger; coverage rows must be partitioned per
  mandate so the orchestrator's merge does not collide.

### Q10 -- feature-001 specification decisions (2026-07-27)

- **Category:** Design-Decision
- **Impact:** High
- **Status:** Resolved
- **Decisions taken at feature-001 INITIALIZE, in response to the architect's proposal:**
  1. **A `SUGGESTION`-modality rule is never grade-bearing** -- "for now, no".
  2. **`SUGGESTION` is removed entirely.** Modality becomes `MUST / SHOULD / COULD`.
     Consequence: this collapses onto the same three values feature-level `## Priority`
     already uses, so the vocabulary collision resolves itself -- one vocabulary, not two.
     Three existing usages were text-only (no FR was tagged `SUGGESTION`), so the removal
     is clean.
  3. **`AGENT.md` line 36 / `README.md` line 66 ("Severity is your judgment") is fixed
     now**, by feature-001, rather than left contradicting the canonical scale for four
     features. feature-001's claimed regions in `aid-reviewer/AGENT.md` therefore become
     lines **31, 36, and 59-67** (was 31 and 59-67). Recorded as a deliberate
     encroachment on ground nominally belonging to FR-B5b/FR-A10 -- the other features'
     edit inventories must be updated to match.
  4. **`lint-modality.sh` applies retroactively**, not forward-only. Existing documents
     must be back-filled -- including this work's own REQUIREMENTS.md (its 12 ACs in §9
     carry no modality) and all six feature SPECs. Self-referential work, and immediate.
  5. **`task-type-rules.md` stays out of AC-2's scope**, with an important boundary
     clarification: *executor-only* patterns (how to write the code) are not review
     criteria, but *architecture-level mandates* -- clean architecture, hexagonal, DDD,
     BDD, TDD-required -- **are** reviewable **when the KB declares them**. The reviewer
     identifies their absence; the architect or executor applies them. Where the KB
     declares nothing, their absence is a **criteria gap (Type 2)**, not an invented
     finding. This sharpens FR-B2 and should be written into the two-sources rule.
- **Also decided:** **FR-B7 is CUT** (see REQUIREMENTS.md §5.B). Reach and reversibility
  are already axes inside the canonical scale, so B7 would count the same fact twice;
  *silence* survives as a feature-002 rule-authoring input to FR-B4.

### Q14 -- feature-008 added post-Specify, and the four defects in its own motivation (2026-07-27)

- **Category:** Design-Decision
- **Impact:** Required
- **Status:** Resolved -- feature-008 created; REQUIREMENTS.md group G, AC-13 and AC-14 added.

**Origin.** After the Specify phase closed at A+ on all seven features, the user asked whether the
feature set still represented the intent of the work. Reviewing the work's own review record
surfaced two gaps, and the user approved both.

**Gap 1 -- the work never measured the thing it was started for.** The user's opening motivation was
that a light/deep split would *"save time and tokens."* That became NFR-3 and NFR-4, and neither
tests it:

- **NFR-3 (MUST)** compares light *to deep* -- trivially true, and not the question.
- **NFR-4 (SHOULD)** covers only *small* artifacts and is satisfied by a threshold, i.e. by
  avoidance rather than measurement.

Worse, feature-006 §2 made light review deliberately **non-reducing** on the deep pass (it writes
no `U-NNN` coverage rows, so deep re-examines everything). That was correct for FR-A4, but it means
the only route to a saving is **fewer FIX cycles**, and nothing counted FIX cycles. **NFR-3 was a
MUST with no acceptance criterion**, and AC-1..12 covered severity, rules, gaps, resume, the ledger,
extraction and parity -- none covered cost.

**Resolution:** **AC-13** added, built on the always-on `## Dispatch Log` / `## Calibration Log`
telemetry (one row per dispatch, with agent and cycle), baseline captured in feature-006's D0
beside AC-11's. NFR-3 and NFR-4 annotated rather than rewritten.

**Gap 2 -- the dominant defect class was unaddressed.** All 17 findings-bearing review cycles
produced only wrong line numbers, unverified counts, and paraphrases presented as quotes.
`kb-citation-lint.sh` already enforces the durable-anchor standard **and is scoped to
`.aid/knowledge`** -- work artifacts, where the citations actually are, are unchecked.

**Resolution:** **feature-008** created; FR-G1..G5 and AC-14 added.

**The four defects in feature-008's own first draft.** Recorded rather than quietly fixed, because
a motivation document for a citation-accuracy lint that cannot survive its own lint is not evidence
of anything. All four were found by the architect on dispatch:

| # | Claim as first written | Disk truth |
|---|---|---|
| 1 | *"Nineteen review cycles"* | **24** total (`4+3+3+3+2+3+6`), of which **17** carried findings. The 19 was never computed -- and I had already reported it to the user twice |
| 2 | 82 bare citations across the seven specs; 53 in feature-007 | **85** and **54** |
| 3 | A correlation between bare-citation count and review cost | Has **two counterexamples in a sample of seven**: feature-001 carried 0 citations and needed 4 cycles; feature-005 carried 13 and needed 2. The mechanism (semantic, not syntactic mis-citation) predicts no correlation |
| 4 | *"see STATE.md Q14"*, cited in the SPEC and in REQUIREMENTS.md | **Q14 did not exist.** This section is it |

**The finding that most changes the feature's shape.** A range-and-resolution lint would have
recovered **0 of the 17** findings-bearing cycles. The defects were line numbers that *resolved* and
were *in range* but pointed at the wrong content -- the `[AUTHORING-FM]` case cited three different
ranges, all inside a 130-line file, so all three pass a range check. The case for feature-008 is
therefore **not** retro-justification; it rests on 22 live findings, a latent tokenizer bug, a false
CI claim in the KB, and forward cost only.

**What specifying feature-008 then demonstrated, at its own expense.** It took **9 cycles** and 18
findings — more than any other feature — and the findings are the strongest evidence the work has
produced:

- **Three long quotations in that one spec had drifted from their sources**, each caught only by a
  reviewer opening the file. Two were dropped parentheticals; one changed double quotes to single.
  **Three separate fixes to the same paragraph each introduced a new defect in that paragraph.**
  The eventual fix was structural: quote a **short fragment from a single source line**, and
  paraphrase anything longer openly.
- **Four findings were sibling-spec `§`-numbers that were wrong while the quoted string was right.**
  A section number is a second claim that drifts independently of the thing it locates. Resolution:
  **cross-feature references name the feature and the quoted string, not the section** — the
  quotation is self-locating by `grep`. Region-ownership inventories keep their section numbers,
  because there the section is part of the claim.
- **Three findings were stale duplicate figures** left behind when a number was replaced by its
  command in one place and not the other. Sweep for other occurrences when replacing a figure.
- **One finding was itself wrong.** A review claimed `grading-rubric.md` is 62 and 266 lines; disk
  says **83 and 330**, matching the spec. That is the **fifth** wrong count a review has produced
  in this work. Combined with the three author-side miscounts, the conclusion is not "authors
  miscount" but **"whoever states a bare count gets it wrong at a similar rate"** — which is
  precisely why FR-G4 becomes a convention binding both sides (state the command) rather than a
  lint aimed at authors.

**Three real defects found while specifying it:**
1. **`kb-citation-lint.sh`'s linespec class uses an ASCII hyphen.** All **25** range citations in
   the seven specs use an en-dash (U+2013), so every one is silently truncated to its first number.
   Harmless for a ban; fatal for a range check.
2. **`quality-gates.md` lines 353-354 claim the citation lint runs in CI and is "blocking for
   merges to master."** `grep -rn 'kb-citation-lint' .github/workflows/` returns nothing -- neither
   it nor `closure-check.sh` has ever run in CI. The same false-wiring class feature-007's FR-F3
   found for the frontmatter lint, in the same document, two rows away, unclaimed by feature-007.
3. **FR-G4 is not mechanically reachable, for a sharper reason than assumed.** For the `aid-plan`
   BLUEPRINT count, `grep -rho` gives 12, `grep -rn` gives 11, case-insensitive gives 14 and 12 --
   **11 and 12 are both correct.** Neither reviewer was wrong; the *question* was never written
   down. The defect is an unstated question, and no lint supplies a missing question. FR-G4 becomes
   a **review rule** in feature-002's Definition-family file, not a lint check.

### Q13 -- `[DECIDED AUTONOMOUSLY]` overnight-run decisions (2026-07-27)

- **Category:** Design-Decision
- **Impact:** Medium
- **Status:** **Answered** 2026-08-09 — **all 31 settled: 27 RATIFIED as ratified-by-execution, 4
  exceptions individually ruled on.** Original note retained for the record: *all items here were
  decided without asking, under the user's overnight authorization. Scan and overturn as needed.*
- **Ratification (2026-08-09, human decision).** The 27 sub-items verified as shipped are **ratified
  as a block, none overturned.** Each was checked against disk individually rather than accepted from
  the entry's own claim, and each has been load-bearing across fifteen deliveries — so overturning one
  now would be a change to working behaviour, not the correction of an unreviewed decision. Raising a
  specific concern later remains cheaper than re-opening all 27, and this ratification does not
  foreclose that. The four exceptions are ruled on individually at `Q26`.
- **Triage 2026-08-09.** Each of the 31 numbered sub-items was checked against disk individually.
  **27 shipped as decided** and can be ratified as a block: feature-003 all 6 (sentinel lock,
  `--verify-grade` default-on, screener cannot write rows, coverage/gap rows out of the panel merge,
  `--list-units`/`--get-status`, `PROJECT-INDEX` kind B); feature-004 9 of 10; feature-006 6 of 8 plus
  the discipline-block and tiering items; feature-007 6 of 7.
  **The four exceptions, each inside a delivery that closed `Done` or `Gated`:**
  **(i) feature-004 #9** — the greenfield edit to `document-expectations.md` 50-52 was never made;
  delivery-007 closed `Done`. **(ii) feature-006 #5** — `reviewer-guide.md` was to be retired and is
  still present at 77 lines, never scheduled into any delivery; `Q3(b)`/`Q3(c)` remain open only
  because this deletion never happened. **(iii) feature-006 #4** — shipped in a form that contradicts
  half its own text: the `U-` half landed, the "light findings land in the canonical ledger as
  `Pending`" half is forbidden by the skill itself. **(iv) feature-007 #5** — `aid-detail` writing the
  BLUEPRINT Tasks table is decided and **scheduled into delivery-018, which is `Pending-Spec`** — not
  a defect, just unexecuted.
  All four are consolidated in **`Q26`**. Stale residue also noted: this work's `.aid/works/work-003-review-subsystem-redesign/REQUIREMENTS.md:293` still reads
  *"FR-A7 (still open)"* although `:111` records it **CUT 2026-07-27**.
  **Both halves are now discharged (2026-08-09):** the 27 are ratified (see Status above), and
  (i)-(iii) are ruled on at `Q26` — item 1 re-scheduled into `delivery-022` (the `/aid-review` merge) and item 2 into `delivery-021` (**carrier corrected 2026-08-10**; this read *"items 1-2 ... into the `/aid-review` merge delivery"*, written before the carrier split in two), with
  closed deliveries left closed, item 3 superseded by the `Q1(a)` one-skill revision. **(iv) needs no
  ruling**: `aid-detail` writing the BLUEPRINT Tasks table is correctly scheduled into delivery-018,
  which is `Pending-Spec` — unexecuted, not undelivered.

**feature-003 (all six were the architect's own recommendations, accepted):**
1. **Sentinel lock inherited** from `writeback-state.sh` (~20 lines, already tested). Unnecessary
   today under the single-writer invariant, but FR-D5 makes the orchestrator a second writer two
   features out. Exit 2 documented as a bug signal, not a normal path.
2. **`--verify-grade` default-on** for `U`/`G` appends. Converts AC-9 from a fixture claim into a
   runtime invariant; one extra awk pass over a 3-10 KB file. `--no-verify-grade` escape hatch.
3. **`aid-screener` cannot write ledger rows** -- it holds `Read, Glob, Grep` and no `Bash`,
   and the helper is a shell script. It returns rows in its message; the **calling skill** writes
   them. Consistent with FR-A2 and "the reviewer never writes". **A constraint on feature-006.**
4. **Coverage and gap rows are excluded from `aid-discover`'s panel merge** -- they stay in the
   writer's own scratch ledger, so mandate resume works with no cross-mandate ID reconciliation
   and the merged canonical ledger stays purely findings, leaving the essence and act-back
   verdict derivations untouched.
5. **`--list-units` and any resume-planning read API defer to feature-005**, which has an actual
   caller. `--get-status` ships in 003 because it makes the helper self-testable.
6. **feature-002's rule-ID regex cannot express its own `PROJECT-INDEX` class** (the class token
   contains a hyphen; the regex allows one). Mitigated in practice -- `PROJECT-INDEX` is kind B
   and kind B needs no rule rows -- so logged as a **non-blocking note to feature-002's
   implementation** rather than reopening its A+ spec.

**feature-004 (all ten were the architect's own recommendations, accepted):**
1. **FR-C9 stays out of `## Source`** -- the 12-FR count of record holds (C1-C8, C10, C11, D8,
   D9). Its substance ships as the up-front batched scan inside the existing REVIEW states;
   feature-006 relocates it into `aid-light-review`.
2. **FR-D9 promoted SHOULD -> MUST and reassigned to feature-004.** Three of its acceptance
   criteria rest on the promotion, so leaving it a SHOULD would close the feature with
   unsatisfied MUSTs -- the exact defect Q7 #7 recorded. **REQUIREMENTS.md edited.**
3. **`/aid-update-kb` branches off `master`, not the caller's HEAD** -- accepted for now: the gap
   brief and depth ride in its free-text argument (the only one of the five routing targets that
   takes free text), the halt prints an explicit merge line, and the
   no-increment-while-Pending rule stops the first re-invocation looking like a loop. **The
   branch base itself is logged to Q3** -- a KB change made to unblock a work's review arguably
   belongs on the work's branch.
4. **`AGENT.md` line 17 added to feature-002's inventory** (it mandates the retired
   `[ARCHITECTURE]` tag and was missing while its README counterparts were claimed).
   **feature-002's A+ spec edited** rather than annexed by feature-004.
5. **Two scripts, not one** -- `check-gaps.sh` (linter exit codes: 0/1/2) and `gap-register.sh`
   (`writeback-state.sh` codes). `coding-standards.md` 226-229 forbids inventing a third scheme,
   and a gate and a STATE writer cannot share one. The possible-loop signal rides **stdout**.
6. **Depth limit = 2**, and the cap **demotes rather than discards** (`[GAP:CRITERIA]` becomes
   `[GAP:CRITERIA:NB]`, the register keeps `Depth: 2` `Pending`).
7. **Gate wired at all 18 grade sites**, including the two machine-validator ledgers -- a total
   oracle beats a maintained exclusion list.
8. **A dedicated `## Criteria Gaps` table** in the work and discovery state templates, not the
   existing `## Cross-phase Q&A` -- that section legitimately holds long-lived Pending entries,
   and a grade-gating gap cannot live among them. KB scope additionally writes the companion
   `Impact: Required` Q&A entry, so the existing Q-AND-A state needs **zero** change.
9. **Only one behavioural change to greenfield mode:** `document-expectations.md` 50-52. A
   declaration naming a **resolvable** standard (URL, doc, or a linter config in the repo) is a
   criterion and the missing code example is an evidence gap; a declaration naming nothing
   resolvable is "established best practice" with a wrapper and becomes a halting gap.
   Everything else in Greenfield Mode is evidence-shaped and retained.
10. **The inline-check-enumeration licence is deleted** from `reviewer-dispatch.md` (133-134,
    209-214, 247-254). An inline-enumerated check is neither a KB rule nor a spec rule, so FR-B2
    forbids it; after feature-002's catalog, no rubric means family fallback or a criteria gap.

**feature-006 (all eight were the architect's own recommendations, accepted):**
1. **FR-A7 CUT** -- an aspiration with no test. **REQUIREMENTS.md edited.**
2. **The six `reviewer-brief.md` files survive, shrunken in place** to their two genuinely
   per-skill sections. Deleting them would make feature-005's oracle (b) pass **vacuously on an
   empty glob** and destroy feature-002's `RUBRIC:` re-point target.
3. **FR-A8 ships as a new *use* of CHAIN, not a fifth advance type** -- a "terminal hand-off"
   line under CHAIN's `Use for:` list. `state-machine-chaining.md:96` stays untouched.
   **One fallback design, not five:** `skill_chaining = true` on all five profiles and the
   renderer does not branch on capabilities at all, so a per-profile branch would *create* the
   AC-12 divergence it was meant to prevent. The hand-off line doubles as a
   PAUSE-FOR-USER-ACTION resume command, so the degradation is "the user types the printed
   command". **The chaining spike becomes a confirmation task, not a design fork.**
4. **Light-review findings land in the canonical ledger as `Pending`; light writes NO `U-NNN`
   coverage rows.** This is what makes FR-A4 structural: with no coverage artifact, a deep resume
   cannot mistake a light pass for clearance. Had light written `U-` rows into the same scope, a
   deep resume could silently skip a unit -- the exact hazard FR-A4 exists to prevent.
5. **`aid-execute/references/reviewer-guide.md` is retired**, its per-Type checklists absorbed
   into feature-002's catalog. Resolves Q3(b) and Q3(c) by deletion. Costs feature-001's edits at
   6-14 and 35; carried as a hand-off AC.
6. **`aid-describe`'s missing seventh brief is dropped from the list**, not authored -- as a
   manifest caller it needs no brief file, so the six-vs-seven defect closes without new content.
7. **FR-A9 ships as its own delivery** -- the only delivery whose success criterion is an *empty
   diff*, which makes it uniquely cheap to verify and uniquely dangerous to bundle.
8. **`reviewer-dispatch.md` claim narrowed to 174-208 + 215-246** to avoid feature-004's 209-214.
- **Discipline block: nine of ten agents** (all but `aid-screener`). `self-review-protocol.md:7-10`
  exempts `aid-reviewer` and `aid-orchestrator` yet the block ships to all nine -- FR-A9's
  "deep-review agents only" read literally would invert the protocol. Took the byte-neutral
  reading; **logged the protocol/boilerplate exemption mismatch as a NEW Q3 item.**
- **STATE.md Q7 #3 (reviewer >= executor vs a cheap light pass) is RESOLVED, not carved out:**
  the invariant binds *the agent that produces the graded ledger*, and `aid-screener`
  structurally is not that agent -- no `Bash`, so it cannot run `grade.sh`; no write path, so it
  cannot produce a ledger.

**feature-006's three findings, worth keeping:**
- **The boilerplate split is byte-identical**, proven by round-tripping the renderer's own
  concatenation. STATE.md N1's "full-roster regression" collapses to a zero-diff assertion.
- **The "stray The" is not in the committed base** -- it exists only in an accidental
  markdown-formatter run sitting uncommitted in the main tree. Reconciliation is
  `git checkout --`, not an edit. My earlier report of it as a shipped defect was based on the
  dirty working tree.
- **The real full-roster blast radius is `tests/canonical/test-doc-counts.sh`** -- a live CI gate
  whose 10 AGENTS and 11 SKILLS assertions (21 of 29) break the moment the roster grows. Good
  news: the regression is already mechanically caught, so no new oracle is needed.
- **`reviewer-dispatch.md` does not reference `agent-boilerplate.md`** -- N1's stated cause was
  wrong, though its blast radius was real.

**Corrections to my own earlier framing, for the record:**
- The gap halt is **`PAUSE-FOR-USER-ACTION`**, already sanctioned at
  `state-machine-chaining.md` line 47 for *"Run another `/aid-<other-skill>` first (cross-skill
  loopback)"*. So my "no call-and-return" framing was overstated **twice** -- first corrected to
  "narrower than it looks", now to "already an existing advance type". And
  `aid-housekeep`'s KB-DELTA already ships register-write-then-route.

**feature-007 (all seven were the architect's own recommendations, accepted):**
1. **`grade-summary.sh` renamed `emit-summary-findings.sh`.** A script named for a grade it no
   longer computes is exactly the drift FR-F6 exists to remove -- and a misnamed script is how the
   second backend grew. Costs a `sed` over 47 coverage-baseline keys and 13 doc surfaces that
   FR-F6 is editing anyway.
2. **`lint-frontmatter.sh` gains `--fail-on-skip`**, additive and default-off. Without it M2 keeps
   a narrowed check-8 residue for the "no structured frontmatter at all" case the script's
   day-one soft-skip deliberately passes. Safe because **no doc in this repo triggers the skip**
   (measured: 16 checked, 5 skipped, all category/source skips, zero pre-migration skips).
3. **COV's tightening ships un-softened.** One unreferenced doc goes from **A+ to C+**. Any
   threshold that softens it is a curve, and the binary bar is already decided. Noted in the
   changelog; the fix for a newly-failing summary is FIX adding the missing section.
4. **FR-F1's fourth AC re-read** as *"the resolved bar is printed at every gate site"*. It cannot
   mean diffing against a prior value because nothing records one, and a settings-history file is
   new durable state for a SHOULD-shaped concern.
5. **`aid-detail` writing the BLUEPRINT Tasks table is IN scope for FR-F4.** Without it, adding
   the BLUEPRINT to `aid-detail`'s artifact set lands a **guaranteed-failing gate** -- the table
   stays `_none yet_` forever on the Full path. A parity fix, not new design:
   `shortcut-engine.md:634` already does it on the Lite path.
6. **`--non-functional` is reserved for "nothing usable" only.** An illegible visual is a `[HIGH]`
   row -> `D+` -> fails any configured minimum anyway, so the flag buys nothing and costs the
   distinction between "one defect" and "the artifact does not work".
7. **`format_version` is validated if present, not required.** Requiring it would fail every
   existing adopter install on the day the gate ships.

**feature-007's findings, worth keeping:**
- **`SUMMARY` is Presentation family, not NARRATIVE.** My own AC said NARRATIVE; feature-002 §4
  assigns it to Presentation and its AC requires exactly one rule set per artifact. The
  content-truth criteria live in the `SUMMARY` **class** file. **Both specs amended.**
- **`state-continue.md` cannot take feature-006's terminal CHAIN.** Step 4 sits inside a
  per-section loop and both review skills HALT at DONE, so a terminal hand-off would end the skill
  after the first section. **feature-006 amended** to exclude it; it gets FR-F5's mechanics inline.
- **`AGENT.md` line 18** still says *"Tag every issue by severity"* -- reviewer-**assigned**
  severity, contradicting feature-001's line-36 replacement and feature-002's severity-as-lookup.
  Nobody had claimed it. **Handed back to feature-006's FR-A10, not annexed.**
- **Ten of `grade-summary.sh`'s 68 points are dead** -- D1 and D2 are set `pass`
  unconditionally at lines 248-249 since the Mermaid engine was retired, inflating every Machine
  Grade. Pure deletion.
- **COV and K1 were one criterion wearing two hats**, worth 25 of 98 points between them.
- **Four checks that "block DONE" carried zero grade weight.** Under rule rows they carry
  `[HIGH]` -- so the new rule set is *smaller than the points table and strictly stronger*.
- **The essence/act-back "third backend" was overstated.** Both gates' condition 1 is already
  derived from ledger rows; only their **ratio** conditions (>= 90% coverage) were a separate
  arithmetic, and those rest on an agent's unfalsifiable denominator. Retired in favour of the
  conservative rule already written beside them.
- **Unanswered != failed.** `grade-summary.sh` (**retired** by `delivery-015` task-003, commit `3d200962`, "de-score the manual checklist"; the surviving script is `emit-summary-findings.sh`) set `HUMAN_GRADE="F"` for an unanswered
  checklist, contradicting its own rubric which says Overall should read *"Pending Human Review"*.
  Now no grade at all -- a `PAUSE-FOR-USER-ACTION`.

**Process lesson from the overnight run:** **24 review cycles across 7 features (`4+3+3+3+2+3+6`, re-derived from `## Features State`; **corrected 2026-08-10** — this read *"19"*, the uncomputed figure `Q14` row 1 retires), and every single
finding was a citation or count precision defect.** Not one structural, design, or completeness
finding was raised. Three times two successive reviewers gave *different wrong answers* for the
same count (`test-grade.sh` cases: 14, then 15, actually 16; the M2 anchor range: 189-194, then
148-149, actually 149-150; the `aid-plan` BLUEPRINT total: 4, then 11, then 12). **The durable fix
adopted mid-run: do not quote a count or range in a spec -- state the command that produces it.**
Specs written that way converged in 2-3 cycles; feature-007, written before the lesson fully
landed, took 6.

**New defect found at the Detail gate (2026-07-28), routed to the Q3 backlog:**
- **The closed task-type enum has two disagreeing authorities.** Both
  `canonical/aid/templates/task-detail-template.md` and
  `canonical/aid/templates/delivery-plans/task-template.md` declare eight values --
  `RESEARCH | DESIGN | IMPLEMENT | TEST | DOCUMENT | MIGRATE | REFACTOR | CONFIGURE` -- and
  **omit `FIX`**. But `canonical/agents/aid-developer/AGENT.md` advertises handling *"all
  implementation task types (IMPLEMENT, TEST, REFACTOR, CONFIGURE, MIGRATE, **FIX**)"*. A task
  authored with `Type: FIX` conforms to the agent and violates the template. Three tasks in this
  work were authored that way and were retyped (`CONFIGURE`, `MIGRATE`, `DOCUMENT`) because the
  template governs the artifact. **Same defect class as the review-path contradictions this work
  exists to fix** -- two documents, one enum, no single source -- so it is a candidate for
  feature-001's treatment rather than a one-line edit.

**New defects found and routed to the Q3 backlog:**
- ~~**All five rendered emission manifests carry a `src` path that does not exist**~~ --
  **RETRACTED at execution, 2026-07-28. This was not a defect.** `render.py` deliberately
  normalizes `canonical/aid/<sub>/` to `canonical/<sub>/` in the manifest `src` field, with the
  stated reason *"for manifest src stability (downstream traceability paths unchanged)"*. The field
  is a **stable logical identifier, not a filesystem path**, and is correct as generated. I reported
  this as a defect overnight and it propagated into four SPECs, one BLUEPRINT and one task; all have
  been corrected. The **"verify emission by rendering"** criteria are retained, because a directory
  that has never been emitted has never exercised the mapping -- but that is the reason, not
  staleness. **Lesson: I read a normalization as a bug because the two paths differed, without
  reading the code that produced them** -- the same claim-without-checking-the-source failure the
  citation-accuracy feature exists to catch.
- `test-grade.sh` has **16** numbered cases. Two successive reviewers reported 14 and 15; both
  were wrong. Count claims in specs should carry the counting command, not just the number.

### Q12 -- Artifact inventory and review-kind taxonomy (2026-07-27)

- **Category:** Research / Design-Input
- **Impact:** High
- **Status:** Resolved -- both user decisions taken 2026-07-27; gaps 1-5 became group F / feature-007
- **DECIDED:** `.aid/settings.yml` gets a kind-D gate **in this work**, and `kb.html` gains a
  kind-A adversarial content pass **in addition to** its existing machine + human gates.
  Together with the unwired frontmatter lint, the ungraded BLUEPRINT, and the
  ledger-less per-section specify review, these became **REQUIREMENTS.md §5 group F**
  (FR-F1..F5) and **feature-007**, sequenced last so its gates are built on feature-006's
  shared capability rather than added and then migrated.
  The review-kind taxonomy itself became **FR-B11**, owned by feature-002.
  `kb.html` will be the only artifact carrying **two** review kinds (A + E) -- deliberate,
  and to be stated explicitly in the class registry.
- **DECIDED (2026-07-27): one grading backend.** The inventory found **three** -- the
  universal ledger (`grade.sh` + `grading-rubric.md`), the KB panel's binary verdict gates
  layered on top of it, and `grade-summary.sh`'s **weighted-points** model for `kb.html`
  (68 machine + 30 human -> percentage -> letter). Now **FR-F6** and **NFR-7**:
  `grade.sh` is the only producer of a letter grade.
  - **The argument:** weighted points were a *proxy for per-check severity anchoring*. A
    score of "60% of the accessibility points" only exists because no rule declared what an
    accessibility violation is worth. Once each rule carries an anchor, the weights are not
    just redundant -- they are a second arithmetic that can disagree with the first.
  - **What is lost:** partial credit. Consistent with the binary-bar decision already
    taken (*do not grade on a curve*), and the severity anchors carry the weight the points
    used to.
  - **The three binary verdict gates are re-expressed, not deleted.** The essence gate
    (PASS iff zero open `[FIDELITY]`) and act-back gate (PASS iff zero open `[ACTBACK]`) are
    already *derivable* from the ledger -- "zero findings of this rule class" needs no
    separate mechanism. Summarize's **V1** is the one true hard stop and maps onto the
    existing `grade.sh --non-functional` flag.
  - **NFR-1 holds:** `grade.sh`'s counting logic does not change; only its set of callers does.
  - **Ownership split:** feature-002 authors the rule sets (turning summarize's points into
    anchored rule rows); feature-007 retires the old backend and rewires the callers.
- **Method:** three parallel exploratory sweeps of the worktree -- persistent artifact templates
  (`canonical/aid/templates/**`, `artifact-schemas.md`, `pipeline-contracts.md`,
  `generated-files.txt`), transient artifacts (`.aid/.temp/`, `.aid/generated/`, script
  write targets), and existing review coverage (every `aid-reviewer` dispatch, every
  machine validator, every rubric, every stated exemption).

**AID already implements five distinct KINDS of review. They have never been named as a
set, which is why the catalog design kept trying to force one shape onto all of them.**

| Kind | What it does | Existing examples |
|---|---|---|
| **A. Adversarial content grade** | Agent grades content against criteria; severity-tagged findings; `grade.sh` computes the letter | SPEC, PLAN, DETAIL, CODE, KB primary docs, lite deliverables |
| **B. Build-verify only** | Re-run the generator and diff; the script is the authority; content grading skipped | `INDEX.md`, `metrics.md`, `project-index.md` |
| **C. Spot-check snapshot** | Only current-value fields checked; history/ledger rows explicitly not graded | `.aid/knowledge/STATE.md`, `README.md` |
| **D. Mechanical gate** | A script passes/fails; no agent involved; blocks the phase | `kb-citation-lint.sh`, `closure-check.sh` (a), `check-version-sync.sh`, the summarize validators |
| **E. Machine + human checklist** | Weighted machine score plus a mandatory human gate | `kb.html` via `grade-summary.sh` + `manual-checklist.json` (V1 visual gate) |
| **(exempt)** | Declared out of scope, with a stated reason | `.aid/.temp/**`, unregistered `.aid/generated/*`, frontmatter optional fields, `/aid-triage` |

**Three grading backends exist** (a fragmentation worth noting): the universal ledger
(`grade.sh` + `grading-rubric.md`), the KB panel (`kb-authoring/review-rubric.md`), and
summarize scoring (`grade-summary.sh` + human JSON).

**Coverage gaps found (candidates for the Q3 backlog / feature scope):**
1. **`.aid/settings.yml` is never reviewed** -- and it carries `minimum_grade`,
   `discovery.doc_set`, and `term_exclusions`. A wrong value silently loosens every gate
   in the project. Highest-leverage unreviewed artifact in the system.
2. **`lint-frontmatter.sh` is built, documented as the mechanical gate, and wired to
   nothing** -- no skill state invokes it; only tests and the dashboard. Frontmatter is
   agent-checked in M2 instead.
3. **`aid-specify` per-section review (S1) has no ledger path and no `grade.sh` call**,
   unlike its own final REVIEW state. Inconsistent discipline inside one skill.
4. **`kb.html` never sees `aid-reviewer`** -- it is the only major deliverable with no
   adversarial pass, machine + human only.
5. **`BLUEPRINT.md` is never independently graded** -- read for gate criteria at
   DELIVERY-GATE, but no review of its own.
6. **`REQUIREMENTS.md` grading is asymmetric** -- full path gets a COMPLETION checklist
   and is graded later at `aid-define` CROSS-REFERENCE; the Lite path grades it at GATE.
7. **Connector descriptors and `connectors/INDEX.md` have no review gate** (P7 exemption,
   but never stated as a review exemption).
8. **`known-issues.md`, `delivery-NNN-issues.md`, `IMPEDIMENT*.md` feed reviews but are
   never reviewed.** Probably correct -- but exemption should be *declared*, not merely absent.
9. **`.aid/.temp/summarize/summary-src/**` has no DONE cleanup**, unlike review ledgers;
   it lingers until housekeep S1.
10. **`DEPLOYMENT-STATE.md` is referenced in `pipeline-contracts.md` but has no template,
    producer, or consumer** -- stale documentation, not a real artifact type.

### Q11 -- feature-002 specification decisions (2026-07-27)

- **Category:** Design-Decision
- **Impact:** High
- **Status:** Partially resolved (4 of 5)
- **Accepted, as recommended:**
  1. **Claim `aid-reviewer/AGENT.md` lines 3, 75, 96-99 for feature-002** (frontmatter
     description, the literal Columns list, and the heredoc example's header + data rows).
     Same precedent as feature-001 taking line 36: leaving them would ship an agent
     asserting seven columns and a retired tag set for a whole feature.
     **feature-003's and feature-006's edit inventories must drop those lines.**
  2. **Defer the `DOC` and `REL` artifact classes.** Neither has a KB document declaring
     its criteria, so shipping them would mean authoring standards inside this feature.
     A documentation review hitting a Type 2 gap once feature-004 lands is the correct
     outcome, not a defect.
  3. **Unmatched artifact class before feature-004 exists** -> the reviewer records one
     `Status: OOS` row naming the class, with `--` in Rule. Grade-neutral by existing
     contract, existing machinery, one line of interim contract. Feature-004 replaces it
     with a `G-NNN` gap row. A `GEN` catch-all rule set was rejected: it regrows exactly
     the invention loophole FR-B3 closes.
  4. **`kb-authoring/review-rubric.md` stays where it is**, referenced from the new
     catalog INDEX rather than moved. Roughly eight inbound pointers and membership of the
     `aid-discover` bundle outweigh catalog uniformity. Its per-check anchors are
     re-derived in place.
- **#5 RESOLVED (2026-07-27) -- force floors are removed entirely.** `[TEACHBACK]` (and
  `[ACTBACK]`, which carries the identical floor) are anchored **`[HIGH]`** as ordinary
  rules. The D-range outcome then follows from the normal grade arithmetic, with no
  override mechanism, no orchestrator obligation, and no new lint.
  - **This is not an assignment, it is what the canonical scale already yields.** A
    TEACHBACK violation breaks a MUST-modality rule (the KB must support defining its own
    concepts); its blast radius is **escaped** (every downstream agent reading the KB
    depends on it); correction is **local** (fix the doc). Escaped + local = `[HIGH]` by
    feature-001 Step 2. It also agrees with the silence guideline -- a KB that cannot
    teach a concept fails silently, so the radius is escaped by default.
  - **Exact behavioural match, with one immaterial difference.** The old floor demanded
    `grade <= D`. Anchoring HIGH gives D+ for a single occurrence, D for 2-5, D- for 6+.
    Only the single-occurrence case differs, and it differs by one modifier in the lenient
    direction. At any minimum grade of C- or better -- which covers the hardcoded default
    `A` and this repo's `A+` -- D+ and D both fail, so no pass/fail outcome changes.
  - **Consequence for the schema:** the `· floor:<GRADE>` annotation is dropped. A
    severity anchor now has exactly two forms, **Fixed** or **`Step 2`**. The catalog no
    longer contains any feature that looks mechanical but is not -- which was the whole
    objection to keeping force floors.
  - Supersedes the three options put to the user (document as an orchestrator obligation /
    build the FR-B8 lint / drop force-floor support). This is a fourth and strictly better
    answer: it keeps the behaviour, removes the mechanism, and makes enforcement real.
  - **FR-B8 is no longer entangled with this question** and can be decided on its own
    merits when feature-003 is specified.
  - **Supporting evidence found while answering "what is ACTBACK?" (2026-07-27):**
    `[ACTBACK]` is live -- emitted by the M4 Assertiveness Gate and by
    `kb-actback-task.sh` / `kb-dual-intent-probes.sh`. **`[TEACHBACK]` appears dead**:
    only three references exist tree-wide (its definition in the rubric tag table;
    `aid-update-kb/references/state-review.md:186` counting it; and
    `aid-discover/references/state-review.md:367` stating M3 tags findings `[FIDELITY]`
    / `[ESSENCE-GAP]` -- *"NOT `[TEACHBACK]`"*). No file emits it. It is defined and
    counted but never produced -- **add to the Q3 defect backlog.**
    This reinforces the decision: M3's live successors already use plain severities
    (`[FIDELITY]` HIGH, `[ESSENCE-GAP]` MEDIUM) with **no force floor**, so the essence
    gate abandoned that mechanism already. Anchoring at HIGH aligns the rest of the tree
    with current M3 behaviour rather than inventing anything.
- **Corrections the architect made to the dispatching brief (worth keeping):**
  - The "7-column" migration set was wrong in both directions. The six per-skill reviewer
    briefs carry **no** 7-column assertion; they carry divergent *source-tag* lines.
    Eleven unnamed files **do** assert it -- `aid-discover`'s `state-review.md` and five
    `reviewer-prompt*.md`, three SKILL.md files, and two KB docs (in frontmatter
    *contracts*).
  - `grade.sh` is the **only** positional ledger parser in the tree; every other
    `cols[...]` site parses STATE tables, task graphs, or its own output.
  - Five of the six briefs point `RUBRIC:` at `grading-rubric.md` -- the severity->grade
    arithmetic, not a rule set. Only `aid-discover` routes to a real catalog.
- **New defects found (add to the Q3 backlog):** `reviewer-dispatch.md` says "Six
  per-skill briefs are shipped" then lists seven, and `aid-describe`'s brief does not
  exist on disk; the `R6` label in the content-isolation block resolves to nothing
  anywhere in the repo; the phantom `content-isolation.md` is also cited in
  `lib/aid-install-core.sh` and `lib/AidInstallCore.psm1`.
- **New cross-feature dependency:** AC-3's runtime half ("every finding cites a rule")
  cannot be proven by any static check. Its only mechanical enforcer is **feature-003's
  surgical write helper**, the single writer of ledger rows. Feature-003's spec must pick
  up "reject a finding row with `--` in Rule" as a helper requirement.

### Q9 -- Specification sequencing (2026-07-27)

- **Category:** Process-Decision
- **Impact:** Medium
- **Status:** Resolved
- **Context:** Asked whether the six features could be specified in parallel. Derived the
  **spec-level** dependency graph, which differs from the implementation graph: a SPEC
  needs upstream *decisions*, not upstream *code*.
  - 2 depends on 1 (rule-row severity anchors must reference the canonical scale).
  - 3's core (D1-D3) depends on nothing -- it touches the severity *tokens*, which do not
    change, not the severity *semantics*. Only **FR-B8** ties 3 to 2, because the
    conformance lint validates against the catalog's rule->severity bindings.
  - 4 depends on 2 and 3; 5 depends on 3 and 4; 6 depends on all.
  - Therefore **FR-B8 is the switch**: keep it and the chain is fully serial; cut it and
    features 1 and 3 form the single available parallel pair (5 waves instead of 6).
    No other pairing is possible -- after wave 1 every remaining feature has an
    unsatisfied predecessor.
- **DECIDED:** proceed **serially**, no parallelism. Order: 1 -> 2 -> 3 -> 4 -> 5 -> 6.
- **Still open, but no longer sequencing-critical:** FR-B8's fate (affects feature-003's
  content only, and 003 is third in the order, so there is time). **FR-B7 is decision-now**
  -- it sits in feature-001, which starts immediately. FR-A7 affects feature-006 only.
- **Note:** had the pair been taken, features 1 and 3 both modify
  `reviewer-ledger-schema.md` in different sections -- no edit collision, but their specs
  would have needed an agreed target shape for that file up front.

### Q8 -- Second-pass decomposition concerns (2026-07-27)

- **Category:** Design-Risk
- **Impact:** High (N1, N2) / Medium (N3, N4)
- **Status:** **Answered (text correction outstanding)** — triaged 2026-08-09; **N1/N2/N4 settled;
  N3's decision is sound but its carrier claim is false. No decision is open**: the correction is
  scheduled at `Q26`, carried by **`delivery-021`** — carrier corrected 2026-08-10; this read
  *"riding the merge delivery"*, which is `delivery-022` and does not scope it. This entry is not
  awaiting a human.
- **Triage 2026-08-09.** **N1 — adopted.** FR-A9 ships as its own delivery: delivery-010, Kind
  `enabling`, success criterion an **empty rendered diff**, with a risk row stating it is *"never
  bundled"*. `Done`. **N2 — accepted deliberately, not worked around.** The four-features-one-file
  serialization became a **named invariant**, the AGENT.md spine `003 → 004 → 005 → 006 → 007 → 009 →
  011`, enforced by a per-delivery `git diff` assertion and quoted-string region inventories; parallel
  delivery is confined to four free tracks. **N4 — re-triaged out.** The WSL gitdir bug leaves this
  work per its own recommendation, retired from FR-E1 and recorded in the PLAN's Deferred table; the
  bug is still live, only its ownership moved. **N3 — decision sound, carrier claim FALSE.** The
  decision (re-run parity at every delivery close; delivery-012 owns the criterion of record) is
  provable in `PLAN.md` and `delivery-012/BLUEPRINT.md:39`. But this entry asserts *"Each feature SPEC
  now carries this note"* — `grep -c AC-12` across the eight returns `1,1,0,0,0,7,0,0`, **three of
  eight**. The per-delivery gate is likewise partial: **11 of 18** BLUEPRINTs carry a parity criterion.
  **This entry's own text must be corrected, not preserved** — see `Q26`.
  **Boundary-honesty note on FR-B5a — vindicated.** Placement held and the reach was real, but
  under-sized exactly as the note warned: delivery-013 sits `Gated` with an open ledger recording that
  `spec-template.md`, `task-detail-template.md` and `delivery-blueprint-template.md` still return
  `grep -ci modality` = 0, and that `aid-plan`/`aid-detail` carry no lint invocation.
- **N1 -- The boilerplate split is the highest-blast-radius item in the work.** All nine
  agent bodies carry `{{include:agent-boilerplate}}`, and `reviewer-dispatch.md`
  references it. FR-A9's split therefore re-renders every agent across all five
  profiles -- a full-roster regression sitting inside feature-006, whose other work is
  review-specific. Feature-006's Specify should decide whether FR-A9 ships as its own
  delivery with its own render check.
- **N2 -- Four of six features edit `aid-reviewer/AGENT.md`.** The edit inventory proves
  no region is touched twice, so this is not rework -- but features 1, 2, 3, 5 and 6
  cannot be reordered or run in parallel without colliding in one file. Accept
  deliberately, or revisit if parallel delivery is wanted.
- **N3 -- AC-12 (five-profile parity) is assigned to feature-006, but every feature from
  1 onward changes rendered content.** Checking parity only at the end lets render drift
  accumulate across five features and land as one undiagnosable failure. Recommend
  re-running it as a regression gate at every feature close, with feature-006 owning it
  as the criterion of record. Each feature SPEC now carries this note.
- **N4 -- Q3 item (e), the WSL `worktree-lifecycle.sh` gitdir bug, is not review-path.**
  Folding FR-E1 into feature-006 drags an unrelated worktree-allocation fix into the
  review-extraction feature. Re-triage it out of this work entirely.
- **Boundary honesty note:** FR-B5a gives feature-001 reach outside the review subsystem,
  since explicit modality must be enforced in the requirements and spec templates and in
  the skills that author them. Feature-001 is therefore not purely the bounded,
  grep-verifiable editorial job it is otherwise described as. Placement is still correct;
  size it with that reach in mind.

### Q7 -- Decomposition concerns raised by aid-architect (2026-07-27)

- **Category:** Requirement-Defect / Design-Decision
- **Impact:** High (4 blocking) / Medium (rest)
- **Status:** **Answered** 2026-08-09 — all eleven sub-items settled; #4 schedules a live chaining
  confirmation before ship, #11 holds the `Q3` re-triage until 016-018 execute
- **Triage 2026-08-09.** **#1 eighth `Rule` column** and **#2 ten agents** were already CLOSED and both
  verify on disk. **#3 NFR-3 vs reviewer-tier ≥ executor-tier — resolved structurally, no carve-out
  needed.** The invariant binds *the agent that produces the graded ledger*, and `aid-screener`
  structurally is not that agent: no `Bash`, so it cannot run `grade.sh`; no write path, so it cannot
  produce a ledger. Pinned `small`/`low` with escalation *"never"*. **#5 FR-B5 vs §4's out-of-scope
  line — half done.** The scope call was made and executed (delivery-013 changed
  `templates/requirements.md` and `feature.md`), but the requested REQUIREMENTS.md fix was never made:
  `grep -rn "form, not content"` returns exactly one hit — this concern itself. §4 still reads *"Any
  change to what the phases themselves produce"*, byte-identical to its first commit, sitting beside
  FR-B5a's retroactive mandate. **#6 FR-B8 vs NFR-1 — resolved by deletion, not relocation.** FR-B8 is
  **CUT**; it could only check `Fixed`-form severity anchors, the low-probability case, while the real
  risk sits on `Step 2` anchors where a lint cannot help. **#7 FR-C7 depth vs FR-C3 halt** — the first
  option was taken: FR-D9 promoted SHOULD → MUST and moved to feature-004, so the depth counter lives
  in the git-tracked register that outlives the deleted ledger. **#8 missing FR for the lifecycle
  rewrite** — resolved by delivery, not requirement: feature-005 owns it via delivery-009's scope line,
  and the rewrite is on disk. **#9 AC-11's "measurably shorter"** — `BASELINE-ac11.md` defines both
  metrics and a three-part threshold including an anti-gaming clause, with the grep pattern written
  into the SPEC *"so it cannot be tuned after the fact"*. **#10 in-flight old-schema ledgers** —
  *"the header decides"*: 7-column ledgers stay readable and are never rewritten, and grade correctly
  because `Severity`/`Status` sit at the same positions in both shapes.
  **#4 ANSWERED 2026-08-09 (human decision): schedule a live chaining confirmation** on codex,
  copilot-cli and antigravity **before this work ships**. Static render parity (`RX13`-`RX16`) is not
  sufficient evidence: it proves the artifacts *reach* all five profiles, not that a chain *executes*
  on three of them. The `skill_chaining = true` declarations for those hosts were authored by commits
  **predating work-003**, so they restate the assumption rather than verify it. The design carries
  *"one fallback design, not five"*, so an unconfirmed capability leaves the fallback unexercised as
  well — a single failure would surface as an adopter finding that a pipeline skill cannot reach its
  reviewer. The item's original sequencing premise ("before feature-007 is specified") has expired;
  the new gate is **before ship**, not before a feature. **Not yet implemented — needs a delivery to
  carry it**, and it is a host-runtime check, so it cannot be discharged by a canonical test.
  Also closes `Q1(e)`. **#11 ANSWERED 2026-08-09 (human decision): HOLD until 016-018 execute, then
  re-triage.** The original reason to wait still holds — several `Q3` items target files those
  deliveries rewrite, so triaging now would sort against a tree about to change and the work would be
  done twice. The cost of waiting is that `Q3` keeps accumulating, which is untidy but not lossy:
  nothing is lost by deferring, only deferred. `FR-E1` stays `SHOULD` and `Q3` stays `Deferred` until
  then. **This is now a scheduled obligation, not an open question** — re-triage is a required step
  after 016-018 execute, and must not be skipped because the entry reads `Deferred`.
  ~~**#11 OPEN** — the FR-E1~~ *(superseded by the answer above; original text retained:)* the FR-E1
  re-triage cannot have run: deliveries 016-018 are `Pending-Spec`, while `Q3` has **grown** (the FIX
  task-type enum, the `/aid-update-kb` branch base, feature-006's exemption mismatch, and three items
  feature-007 surfaced and left unfixed).
- **Blocking -- must resolve before the named feature is specified:**
  1. ~~**AC-3 has nowhere to store a rule reference.**~~ **CLOSED (2026-07-27) --
     add an 8th column.** The ledger gains a **`Rule`** column, and §4's freeze on the
     column set is lifted.
     - **Position is constrained, not free.** `grade.sh` parses by column *position*:
       `cols[3]` must be Severity and `cols[4]` must be Status (verified at
       `canonical/aid/scripts/grade.sh` lines 195-198). Inserting anywhere at or before
       position 3 would break the grader and violate NFR-1. Inserting **after Status** is
       safe, because the grader reads nothing beyond `cols[4]`.
     - **Chosen shape** -- `# | Severity | Status | Rule | Doc | Line | Description | Evidence`.
       This groups the table into three readable bands: *classification* (`#`, Severity,
       Status, Rule), *location* (Doc, Line), *content* (Description, Evidence). It also
       satisfies "not necessarily at the end" while staying grader-safe.
     - **The `Rule` column subsumes the source tag.** The reviewer currently mandates
       `[CODE]` / `[TASK]` / `[SPEC]` / `[KB]` / `[ARCHITECTURE]` tags with nowhere to put
       them. Namespacing rule IDs by artifact class (`CODE-12`, `KB-07`, `SPEC-03`) makes
       the source derivable from the rule and makes it impossible for the two to
       contradict. Final ID format is feature-002's to fix.
     - **Ownership: feature-002, not feature-003.** feature-002 is the first consumer and
       comes first in the order; feature-003 then extends the already-8-column table with
       its row kinds.
     - **Knock-on scope:** every "7-column" assertion must move to eight -- the ledger
       schema, the reviewer agent body and README, the six per-skill reviewer briefs, the
       `reviewer-dispatch.md` protocol, and the AID-managed regions of the root `CLAUDE.md`
       / `AGENTS.md` context files. `grade.sh`'s line-172 comment naming `cols[5..8]` also
       becomes stale; correcting a comment is not a logic change and does not breach NFR-1.
  2. ~~**FR-A1's "each has an agent" collides with the nine-agent KB invariant**~~ --
     **CLOSED (2026-07-27).** The invariant was a misread: this is a meta-work on AID,
     so the roster is in scope. Decided: 10 agents (`aid-screener` added, `aid-reviewer`
     retained). The KB revisions are deliverables, not costs. See Q1.
  3. **NFR-3 collides with the unconditional reviewer-tier >= executor-tier rule.**
     Light review cannot be genuinely cheaper while that rule is unconditional -- it
     would be forced to Large. §7 flags a possible carve-out; it must become a decision.
  4. **Skill chaining is unverified on codex, copilot-cli, antigravity** -- three of the
     five profiles NFR-2/AC-12 require parity across. Warrants a spike before
     feature-007 is specified, not a discovery during execution.
- **Non-blocking but should be fixed in REQUIREMENTS.md:**
  5. FR-B5's modality clause contradicts §4's out-of-scope line (it changes what
     `aid-describe`/`aid-specify` produce). Needs a "form, not content" carve-out.
  6. FR-B8 vs NFR-1: B8 adds a validation pass to `grade.sh` while NFR-1 forbids
     changing it. Cleaner as a separate lint than inside `grade.sh`.
  7. FR-C7's recursion depth limit cannot survive the FR-C3 halt, because the ledger
     holding depth state is deleted at DONE. Makes a MUST depend on FR-D9, a SHOULD.
     Either promote D9 to MUST or give C7 its own durable counter.
  8. **Missing FR:** nothing states "rewrite `reviewer-ledger-schema.md`'s lifecycle
     section", yet FR-D5 contradicts it. Feature-003 or -006 must own it.
  9. AC-11's "measurably shorter" has no metric and no captured baseline.
  10. No rule for in-flight ledgers written under the old schema (NFR-5 gap).
  11. FR-E1 is a container delegating to Q3; re-triage Q3 after features 7-8, since
      several items target files those features will rewrite.
- **Suggested:** resolve 1-4 during Specify (or now, if cheap); fold 5-11 into a
  REQUIREMENTS.md revision before Define closes.

## Calibration Log

<!-- DERIVED -- union of per-task ## Dispatch Log entries. -->

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Dispatches

<!-- DERIVED -- union of per-task dispatch logs. -->

_None yet._
