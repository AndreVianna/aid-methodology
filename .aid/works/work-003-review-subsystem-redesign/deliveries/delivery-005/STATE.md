---
delivery_state: Done
gate_tier: Medium
gate_grade: "A+"
gate_timestamp: "2026-07-29T04:05:00Z"
ticket_ref: "--"
---

# Delivery State -- delivery-005

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

> **Delivery:** delivery-005
> **Work:** work-003-review-subsystem-redesign
> **Branch:** aid/work-003-delivery-005

---

## Delivery Lifecycle

<!-- AUTHORED -- single writer: this delivery's branch. The State scalar lives in the
     frontmatter above (delivery_state). -->

- **Updated:** 2026-07-28T17:26:52Z
- **Block Reason:** --
- **Block Artifact:** --

---

## Delivery Gate

<!-- AUTHORED -- single writer: the delivery-gate closing step of aid-execute on this
     delivery's branch. Reviewer Tier / Grade / Timestamp live in the frontmatter above. -->

- **Issue List:** 7 rows, `.aid/.temp/review-pending/delivery-005.md` — 6 `Fixed`, 1 `Accepted`,
  0 `Pending`. Severities as found: 1 `[CRITICAL]`, 2 `[HIGH]`, 2 `[MEDIUM]`, 2 `[LOW]`.
- **Result:** the ledger is 8 columns — `# | Severity | Status | Rule | Doc | Line | Description |
  Evidence` — migrated across 21 files, with `grade.sh` changed in **comments only**.

### The one that would have shipped

`profiles/<tool>/{CLAUDE.md,AGENTS.md}` are **hand-authored sources, not generator output.** The
installer copies their `AID:BEGIN`/`AID:END` body, in place, into a host project's own root file. The
first migration pass edited only *this repo's* root files, so all five profiles would have shipped the
old 7-column rule to **every adopter** while this repo told itself the migration was done.

Two full re-renders left those five files byte-identical, which is the proof they are sources rather
than emissions — and is exactly why "I re-rendered, so it propagated" was the wrong inference. The
tell was a region-level compare: render said 7-column, repo root said 8. `EC22` now asserts all five
carry the rule and `EC23` asserts it lands **inside** the managed region, since an edit outside those
markers would be writing in the adopter's own space.

### Migration is not one pass

Widening a header row is half a change. The first pass left **separator and data rows at 7 cells**
under 8-cell headers in all four `aid-discover` reviewer prompts — malformed markdown in shipped
product — and missed a backticked column list in `aid-review/SKILL.md:140` because the file's *prose*
mention had already been rewritten. Both were found by a written verifier, not by re-reading the diff.

The verifier itself then produced a **false positive**: it counted an escaped `\|` as a cell delimiter,
so a correctly-escaped row read as too wide. Worth recording because the same reasoning proves the
schema's escape rule is safe for grading — `grade.sh` reads `cols[3]`/`cols[4]`, which precede any
Description text, so escaped pipes later in the row cannot reach it. `EC14` pins that.

### Refusing to fabricate a rule ID

The four discover limbs had **no real rule IDs to cite.** The KB class routes to
`kb-authoring/review-rubric.md`, whose table is `Check | Definition | Evidence anchor | Severity` — it
defines no IDs at all, and `grep -oE '[A-Z]{2,12}-[0-9]{2}'` over it returns nothing. feature-002 §6
specifies `KB-20`..`KB-26`, but nothing on disk carries them yet.

Writing `KB-26` into an example would have produced a resolvable-*looking* citation that resolves to
nothing — the precise defect this work exists to remove, committed inside the feature that removes it.
The examples use `KB-NN`, which deliberately fails the ID regex `^[A-Z]{2,12}-[0-9]{2}$` so it cannot
be mistaken for real, with an inline note telling the author to substitute the true ID and never invent
one. **Recorded as a dependency (`Accepted`), not papered over.** `EC21` asserts every ID that *does*
look real exists in the catalog, and caught `ZZZ-99` under negative control.

Three example rows were also citing IDs that did not describe their own finding (`NAR-11`, the
prose-over-scripts rule, for a heading-level nit). Examples are what reviewers copy, so a mismatched ID
teaches the wrong mapping; corrected to the rules that actually govern.

### NFR-1 and NFR-5, proved by behaviour rather than by diff

`grade.sh` was edited at six comment lines. Both halves are asserted: every changed line begins with
`#`, and its non-comment content is byte-identical to the branch point (`EC15`). But the real promise
is behavioural, so the suite grades **the same findings in both shapes** and requires identical
grades — empty→`A+`, one `[HIGH]`→`D+`, and a mixed ledger where `Fixed`/`Accepted` rows are excluded
→`C`. `EC13` further proves the new column is inert to grading by parking a `[CRITICAL]` token in
`Rule` and requiring the grade not to move.

The two suites that exist to prove NFR-5 keep their 7-column fixtures, and `EC20` fails if either is
ever migrated — because migrating them would delete the only evidence that old ledgers still read.
`test-grade.sh` (19) and `test-delivery-gate-aggregate.sh` (21) both pass **unchanged**.

Live proof, not just fixtures: this delivery's own ledger is 8-column and grades `A+`, and
delivery-004's 7-column ledger still grades `A+` from the same binary.

### Suites

`test-ledger-eighth-column.sh` 23/23, with **6 of 6 negative controls CAUGHT** — schema header, the
MUST-carry statement, the named enforcer, `grade.sh`'s executable content, a reintroduced stale claim,
and a fabricated rule ID. `EC15` was confirmed to actually run rather than skip. Delivery-004's
`test-review-rubrics.sh` still 28/28.

### The dogfood hop, done properly this time

Delivery-003's standing note says the generator writes `profiles/*` only, so this repo's `.claude/` and
`.cursor/` installs need a manual last hop. The script written for delivery-004 synced only the
directories *that* delivery touched, which silently left everything else drifting — a whole-tree diff
found **11 additional stale files per install**. Replaced with a full-tree sync; both installs now
report 362/362 in sync. The three residual `.claude` entries are AID's own dev tooling
(`settings.json`, `skills/generate-profile`, `skills/release-aid`), which are correctly not shipped.

### Regions and scope

`git diff` on `aid-reviewer/AGENT.md` touches exactly the three regions this delivery declares: the
`description:` frontmatter, the `Columns:` list (which gains a `Rule` gloss), and the heredoc example.
Deterministic render gate PASS. Row kinds (`U-`/`G-` rows) remain delivery-006's scope — the column
exists here but nothing populates it yet, which is what "enabling, not standalone-functional" means.

---

## Cross-phase Q&A

<!-- AUTHORED -- single writer: this delivery's branch (via the delivery-gate step of
     aid-execute). Written here, NOT into the shared work-level STATE.md, to preserve the
     disjoint-write property. -->

_None yet._

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
