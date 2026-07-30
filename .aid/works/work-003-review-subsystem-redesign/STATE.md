---
pipeline:
  path: full
  initiator: aid-describe
started: "2026-07-27"
minimum_grade: "A"
user_approved: yes
lifecycle: Running
phase: Execute
active_skill: aid-execute
updated: '2026-07-30T03:45:29Z'
pause_reason: --
block_reason: --
block_artifact: --
ticket_ref: "--"
---

# Work State -- work-003-review-subsystem-redesign

Redesign of AID's review subsystem: extract review into chainable light/deep
review skills, formalize artifact-typed review criteria over a single severity
source of truth, and close the accumulated review-path defects.

> **State:** Paused -- session handoff
> **Phase:** Execute (deliveries 001-014 gated A+; delivery-015 in progress)
> **Next:** `/aid-execute work-003` from worktree `.claude/worktrees/work-003` (branch `aid/work-003-delivery-015`) -- finish task-003, then tasks 004-006

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
| kb-essence/load-bearing-fact-coverage | criteria | Declined | 0 | 0 | aid-discover essence gate, condition 2 (Omission) -- canonical/skills/aid-discover/references/state-review.md § 2c | No KB document declares that the Knowledge Base must carry the project's load-bearing source facts. The Divergence half of the gate maps onto NAR-05; the Omission half has no declaring criterion, so review-rubrics/INDEX.md's No-Criterion-no-row contract forbids authoring a rule row for it. | 2026-07-30, human decision: leave the Omission condition keyed on the [ESSENCE-GAP] Description marker and record the gap rather than invent a rule ID or pause delivery-015 for a KB edit. Declined, not Pending -- the decision is made, so this must not be re-asked and must not gate a grade. Reopening it means adding the standard to the KB authoring conventions via /aid-update-kb, then re-pointing condition 2 at the new rule; task-004's second acceptance criterion is therefore closed for the act-back gate and the Divergence half, and open for this half. |

## Cross-phase Q&A

<!-- DERIVED -- union of per-delivery Q&A plus WORK-OWNER-AUTHORED entries below
     (work owner is the single writer for those). -->

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
- **Status:** Pending
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
  on-demand `/aid-review` + `/aid-audit`.
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
- Still open: naming against the existing on-demand `/aid-review` + `/aid-audit`; how the
  5-section brief is passed through a skill invocation; who owns the FIX loop.

### Q2 -- Severity model: collapse to one source of truth, keep artifact flavors

- **Category:** Design-Decision / correctness
- **Impact:** High
- **Status:** Pending
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
  says no grade is computed at task level; references a removed "Step 2" four
  times; has no Step 1 or Step 2 headings.
  (b) `aid-execute/references/reviewer-guide.md` header points at the same
  removed "Step 2".
  (c) The `references/reviewer-guide.md` pointer in the execute brief is not
  rewritten by the profile renderer, unlike every sibling path in the block.
  (d) `agents/aid-reviewer/README.md` claims Large tier against canonical
  `tier: medium`; six skills hardcode Large via the reviewer >= executor
  invariant, so the medium default is nearly never used.
  (e) `worktree-lifecycle.sh` run under WSL writes a `/mnt/c/...` gitdir
  pointer that Windows-native git cannot resolve, producing an unusable
  worktree (hit while allocating this very work; repaired manually).
- **Suggested:** Fold into this work's delivery plan after the target design
  is agreed.

### Q4 -- Uncertainty escalation and source-of-truth self-healing

- **Category:** Design-Decision
- **Impact:** High
- **Status:** Pending
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
- **Status:** Pending
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
- **Status:** Pending (proposed 2026-07-27, awaiting user decision)
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
- **Status:** Pending user review -- **all items here were decided without asking, under the
  user's overnight authorization. Scan and overturn as needed.**

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
   `shortcut-engine.md:636` already does it on the Lite path.
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
- **Unanswered != failed.** `grade-summary.sh:465-467` sets `HUMAN_GRADE="F"` for an unanswered
  checklist, contradicting its own rubric which says Overall should read *"Pending Human Review"*.
  Now no grade at all -- a `PAUSE-FOR-USER-ACTION`.

**Process lesson from the overnight run:** **19 review cycles across 7 features, and every single
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
- **Status:** Pending
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
- **Status:** Pending
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
