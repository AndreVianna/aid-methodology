---
delivery_state: Done
gate_tier: Medium
gate_grade: "A+"
gate_timestamp: "2026-07-29T13:20:00Z"
ticket_ref: "--"
---

# Delivery State -- delivery-009

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

> **Delivery:** delivery-009
> **Work:** work-003-review-subsystem-redesign
> **Branch:** aid/work-003-delivery-009

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

- **Issue List:** 3 findings, all `Fixed`, 0 `Pending`. Severities as found: 1 `[HIGH]`,
  1 `[MEDIUM]`, 1 `[LOW]`.
- **Result:** an interrupted review is resumable, and status reconciliation has moved off the reviewer.

### The contradiction this delivery existed to repair

Three documents disagreed, and the disagreement was not academic — **the model could not run.**

The schema and `aid-execute`'s delivery gate both told a cycle-N reviewer to read the prior ledger and
update each row's Status. `aid-discover`'s dispatch rules forbade showing a reviewer anything from a
prior cycle — *"Do NOT tell reviewers what was fixed or the previous grade"* — **twenty-two lines from
the delivery gate's own "clean context" instruction.**

Worse, in the one skill that already used scratch ledgers, the merge step deletes every scratch
unconditionally, while four mandate prompts told a cycle-2 reviewer to *"read existing
`{{SCOPE}}-<mandate>.md`, update Status for your prior rows"* — a file already deleted. And the merge
rule keyed on the **row ID**, which is only stable if the scratch that minted it still exists. So the
join key was **defined and unusable**, which is worse than undefined: it looks workable on the page.

### The resolving principle

**Independence protects judgment, not bookkeeping.** Clean context exists so cycle N's *severity* is
not anchored by cycle N−1's. Deciding that row 4 is now `Fixed` is not a judgment about the artifact at
all — it is a set difference between two finding lists. Nothing is protected by making the judge do that
arithmetic, and a great deal is lost: the judge has to be shown the prior verdict to do it.

So reconciliation moved to the orchestrator, keyed on **`(Doc, Rule)`** rather than the row ID. `Line`
is deliberately excluded — it drifts on every edit, so keying on it would report every
fixed-then-shifted finding as new. That key only became possible when `Rule` became mandatory and
single-valued two deliveries ago.

**Contamination is now structural, not instructional.** The reviewer is given a scratch path and is
never told the canonical one, so there is no rule to remember — the prior verdict is simply not
reachable. Mode selection is one `test -f`: scratch present → resume, absent → new cycle.

### The coverage guard is the load-bearing part

A reviewer used to mark a finding `Fixed` because it did not see it — **with no evidence it ever
looked.** The `U-` manifest is the first thing that makes *"I examined this and found nothing"*
distinguishable from *"I never got there"*.

So the transition table has three rows where there used to be one: a `Pending` finding absent from the
scratch becomes `Fixed` **only if** the unit covering its `Doc` is `Examined`. Otherwise it stays
`Pending`, because **absence proves nothing**. Without that guard an interrupted cycle silently clears
every finding it failed to reach.

### The partition, and why it is asserted in both directions

AC-6 says a resumed review re-examines no valid unit and skips no invalid one. Asserting only *"it
detected staleness"* passes a planner that invalidates **everything**; asserting only *"it kept
something"* passes one that invalidates **nothing**. Both are broken and both would look fine.

So the keep/invalidate sets are asserted **exhaustive and disjoint** — and two negative controls prove
it: one planner that invalidates everything and one that invalidates nothing **both** turn `RR06` red.
That is the acceptance criterion tested as a partition rather than as a count.

### AC-8's control is the one that would have been skipped

"A criterion change invalidates exactly the affected units" is easy to satisfy loosely — invalidate on
any filesystem change and every real change is caught. The negative control is what makes it mean
something: **touching a file without changing it must not invalidate**, and neither must rewriting
identical bytes. A one-byte change must. A control that keys the digest on `mtime` instead of content
turns the suite red.

The rule-set digest deliberately covers the rubric **plus every document its `Criterion` cells cite**,
because that is where criteria actually live — people edit the coding standard, not the rubric. A
control that hashes only the rubric file is caught too.

**The granularity cost, stated plainly:** invalidation is per (rule-set × artifact), so changing one
rule re-examines every unit measured against that set. Per-rule would need each unit to record which
rules actually fired — a runtime claim no static check can verify, and unfalsifiable in the direction
that matters, since a rule that finds nothing leaves no trace. Over-invalidation is bounded and cheap;
under-invalidation is a correctness bug.

### The stop signal reached most reviews for the first time

`write-control-signal.sh` was task-scoped: `--task-id` validated against `^[0-9]{1,3}$`. A review run by
`aid-discover`, `aid-specify`, `aid-plan`, `aid-detail`, or by `aid-execute`'s **own delivery gate** has
no task id, so **user-stop did not reach it at all.** The resume contract names three interruption types
including user-stop; shipping it for one of them would have been a partial obligation dressed as a
complete one.

Generalised with `--scope review --slug <ledger-scope>`, defaulting to `task` so every existing caller
is unchanged (asserted). The slug is the **one place a string reaches a filename**, so its pattern is
narrow by design — `^[a-z0-9][a-z0-9-]{0,63}$`, admitting no `.` and no `/`, which makes `../` and
absolute paths inexpressible rather than sanitised after the fact. Four traversal-shaped slugs are
refused with exit 4 and nothing is written outside `.aid/.control/`; a control that loosens the pattern
is caught.

### Result

- `plan-resume.sh` — read-only, follows the **linter** exit alphabet (0 clean / 1 stale / 2 usage)
  because it reports staleness, while the writer follows `writeback-state.sh`'s. One script cannot
  honour both, which is why the planner and the writer are separate. **The planner never writes**; the
  orchestrator applies its plan with `--set-status`, preserving the single-writer invariant.
- `--list-units` on the ledger helper, with `--remaining` as sugar for `Unexamined ∪ In Progress` — the
  "treat an interrupted unit as unexamined" rule made mechanical in the read API instead of restated in
  prose at every caller.
- The orphaned instructions are gone: `grep -rn 'If re-reviewing' canonical/` returns **0**, checked by
  content anchor rather than line number because five features edited the schema before this one.
- **Resume never moves the grade**: a full invalidate → re-open → re-examine cycle leaves the
  `--explain` breakdown byte-identical.
- Also fixed in passing: `aid-reviewer/README.md` still advertised the **retired source tags**
  (`[CODE]`, `[TASK]`, `[SPEC]`, `[KB]`, `[ARCHITECTURE]`) — a stale claim surviving delivery-004.
- Suites: `test-review-resume.sh` **34/34** with **5/5 negative controls caught** (one re-run after the
  first attempt turned out to be a broken control rather than a vacuous assertion).

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
