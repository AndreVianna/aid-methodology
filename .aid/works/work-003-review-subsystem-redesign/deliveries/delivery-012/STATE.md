---
delivery_state: Done
gate_tier: Medium
gate_grade: "A+"
gate_timestamp: "2026-07-29T19:05:00Z"
ticket_ref: "--"
---

# Delivery State -- delivery-012

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

> **Delivery:** delivery-012
> **Work:** work-003-review-subsystem-redesign
> **Branch:** aid/work-003-delivery-012

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

- **Issue List:** 5 findings, all `Fixed`, 0 `Pending`. Severities as found: 1 `[HIGH]`,
  2 `[MEDIUM]`, 2 `[LOW]`.
- **AC-11 passes all three clauses.** Aggregate C **271 → 154 (43%)**, every migrated caller strictly
  decreased, and clause (b) — the anti-gaming clause — at **719 against the pinned 876**.

### The two skills the work was proposed to build

`aid-light-review` dispatches `aid-screener` and stops. `aid-deep-review` resolves the rule set,
dispatches `aid-reviewer`, reconciles on `(Doc, Rule)`, gates on open criteria gaps, grades, and runs the
FIX loop with a three-cycle breaker.

**The light pass writes no `U-` coverage rows, and that is the sharp constraint.** A `U-` row means
*"examined against a rule set"*, so if a cheap screen wrote one, a later deep review would skip units
nobody adversarially examined — and it would be **right** to, which is what makes the bug silent. The
skill states the hazard by name, and `RX03` asserts it.

### Panel mode, and a constraint the old prose only implied

`/aid-deep-review` models one reviewer against one rule set. `aid-discover`'s REVIEW is a four-mandate
panel with per-mandate clean-context rules. Rather than exempt it, the skill grew a panel mode: mandates
declare their own scratch ledger, rule set, `surface` whitelist and `deny` list.

**Denial is enforced at dispatch**, because a mandate that reconstructs meaning from the KB alone is
worthless if the reviewer can read the source it is being tested against — and an agent cannot un-see a
file it was handed.

That produced a rule the old collapsed-panel prose only gestured at: **collapsing mandates into fewer
dispatches is legal only when their `surface` and `deny` sets are identical.** The prose said M3/M4
"cannot share context with the source-aware passes"; stating it as surface equality makes it checkable
rather than remembered.

### Three diagnostic errors, all mine, all caught

Worth recording because the pattern is the same each time — I measured before I understood what the
measurement counted.

1. **A shallow first pass.** I removed the two-line gate+grade pair from eight callers. That broke
   delivery-008's oracle (site count 19 → 12) *and* achieved a 3% reduction. Reverted; the oracle went
   back to 15/15 before I continued.
2. **"The C-metric counts criteria lines."** It does not. The pinned pattern matches review
   *infrastructure* tokens, and the criteria tables I relocated matched none of them. The relocation was
   right on its own merits and moved the metric by **zero**.
3. **Two measurement artifacts I initially read as extractable machinery.** 18 of `aid-discover`'s lines
   are its own oracle and probe outputs, which merely live under `review-pending/` and survive any
   extraction. 13 of `aid-execute`'s are its **Agent Selection table** — a per-task-type executor→reviewer
   mapping the caller must keep. Classifying those was what made an honest target reachable.

### What the criteria relocation actually bought

Not the metric — but two real things. `review-rubrics/kb.md` now exists, and it **gives the KB class its
first rule IDs**. It routed to a rubric whose table is `Check | Definition | Evidence anchor | Severity`:
a genuine rubric with nothing a ledger's `Rule` column could cite. That is why delivery-005 refused to
write `KB-22` into an example and logged the dependency. **`KB-NN` placeholders: 0 remain.**

The catalog's own integrity suite then caught three defects in my new rows, one of which is a schema
constraint now documented: **a rule row's cells must contain no pipe, not even an escaped one.** The
ledger can escape a pipe because `grade.sh` reads `cols[3]`/`cols[4]` before any free text; a rule row
cannot, because `Severity` is the *last* cell.

### An inherited oracle inverted, deliberately

delivery-008 asserted every `grade.sh` site mentions `check-gaps.sh` at an earlier line. After extraction
two sites — the Lite path's engine and `aid-execute`'s delivery gate — **delegate** to
`/aid-deep-review`, which gates. Requiring a direct call would force every caller to re-implement exactly
what was extracted.

So the assertion now accepts *gated directly **or** by delegation*, and `GW01`'s non-vacuity floor came
down 15 → 8 with the reason stated inline. **The invariant is unchanged** — no grade over an open gap;
what changed is who computes the grade.

### Two callers not migrated, each with a reason

An exclusion without a reason is how a criterion gets met by shrinking its own scope, so both are named
in the suite:

- **`aid-review`** — its meta-review VERIFY loop is deliberately retained. It reviews reviews.
- **`aid-describe`** — its matches are references to `aid-discover`'s brief, which it *reuses* rather than
  owns, plus a `minimum_grade` read feeding a composite `ready` predicate alongside an essence verdict.
  Neither is dispatch machinery this extraction can take.

`RX11` fails if fewer than six callers are actually checked, so the exclusion list cannot grow quietly.

### Result

- `reviewer-brief-template.md` carries the invocation manifest and the boilerplate six briefs each copied.
  A caller supplies exactly **two** sections; a third is how six copies happened.
- Six briefs 483 → 192, kept **at their paths** so an inherited oracle stays non-vacuous rather than
  satisfied. Five of six had been advertising the retired source tags.
- `reviewer-dispatch.md` 311 → 55, a rationale document. It had also still carried the
  reviewer-reconciles instruction delivery-009 retired.
- Suites: `test-review-extraction.sh` **21/21** with **4/4 negative controls caught**, including clause
  (b) firing with *"919 ≥ 876 — lines were relocated, not removed."* Plus gap-gate-wiring 15/15,
  reviewer-conformance 33/33, review-rubrics 28/28, criteria-gaps 35/35, doc-counts 31/31.

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
