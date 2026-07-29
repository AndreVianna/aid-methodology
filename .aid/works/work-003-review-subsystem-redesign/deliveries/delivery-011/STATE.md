---
delivery_state: Done
gate_tier: Medium
gate_grade: "A+"
gate_timestamp: "2026-07-29T16:35:00Z"
ticket_ref: "--"
---

# Delivery State -- delivery-011

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

> **Delivery:** delivery-011
> **Work:** work-003-review-subsystem-redesign
> **Branch:** aid/work-003-delivery-011

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
- **The spine's terminus.** All nine verify-do-not-redo assertions hold, so the region-ownership
  arithmetic held across seven deliveries editing one file.

### The conformance check is the work's proof, and it is proved

Seven deliveries edited `aid-reviewer/AGENT.md`, each owning declared regions. The risk the whole
sequencing exercise existed to manage was a later delivery quietly undoing an earlier one's edit.

`test-reviewer-conformance.sh` asserts the file's **end state**, and **9 of 9 negative controls are
caught** — one per upstream delivery, each reverting that delivery's edit and each firing the assertion
that *names the delivery which owns it*. So a regression is not only detected, it is attributed.

**Every assertion is a content anchor, never a line number.** Each of the seven deliveries changed the
file's length, so any line-keyed assertion would have started failing for the wrong reason somewhere
around delivery-005. That is not a stylistic preference — the specs that planned this work quoted line
numbers, and all of them drifted.

### A defect worse than the spec described

The spec called `## Tasks Status` a "write-target defect". It is worse than that: **the section does
not exist, and the section it became is read-only.**

- No state template defines `## Tasks Status`. It is the *pre-migration* name — the hierarchy migration
  scripts reference it only as the legacy heading they rename **from**.
- Its successor, `## Tasks State`, is marked **DERIVED**: *"read-only view assembled at read time from
  per-task STATE.md files. Never written directly into this file."*

So the reviewer was told, twice in its own body plus once in its README, to write test results into a
section that does not exist under that name and is forbidden to writers under its real one. Corrected
to the task's own `delivery-NNN/tasks/task-NNN/STATE.md`, which is the file the per-task writer actually
targets. `RC26` asserts the claim itself — that no template defines the old section — so the finding is
verified, not asserted.

### The tier contradiction, resolved rather than picked

Delivery-003 found `README.md` claiming **Large tier** where the frontmatter says `medium`, marked it
`OOS`, and routed it here. The obvious fix — change one to match the other — would have been wrong in
either direction.

Reading all three sources together resolves it: the **invariant is real** (reviewer tier ≥ executor
tier, stated three times in `architecture.md`), the **default is medium** (frontmatter and the tiering
table), and **Large is a per-dispatch escalation** where the executor is Large — which the dispatch
sites say explicitly (`aid-detail`'s first-run and `aid-define`'s cross-reference both dispatch **at
Large tier** and cite the invariant by name).

So the README was right about the invariant and wrong about what it implies: it stated the *escalated*
case as the *default*. Stating Large as the default would contradict the frontmatter that actually
configures the model and would over-spend on every ordinary review. Rewritten as medium-with-escalation,
and `RC28`–`RC31` pin all of it.

### Two more residuals that would have taught the wrong behaviour

- **Every worked example still spelled the durable ledger path.** Delivery-009 established that the
  reviewer is given a scratch path and is *never* told the durable one — but four `--ledger` examples
  named `.aid/.temp/review-pending/<scope>.md`. **An agent copies the example, not the paragraph three
  sections above it.** Replaced with the scratch placeholder plus one line saying where the path comes
  from, and `RC18` fails if a durable path returns.
- **The cross-reference constraint hardcoded `[CRITICAL]`** for any internal contradiction. That
  contradicts the severity scale this work spent three deliveries establishing: a contradiction confined
  to one document with a local fix is not the same as one that has escaped to consumers. Re-anchored to
  the taxonomy so its severity is looked up like everything else.

The source-authority constraint was also re-pointed at the catalog's **two authority ladders** rather
than an inline ranking, including the conflict rules — manner outranks intent on *how*, intent outranks
manner on *what*, and a conflict between ladders is escalated rather than resolved.

### The division of labour, stated where it will be read

`aid-screener` exists now, so the reviewer's body needed to say what the split means for it. The section
is deliberately explicit in both directions:

- **A screening result never substitutes for a graded pass.** A clean screen means nothing obvious was
  visible, not that the artifact is sound. Treating it as a partial pass would put an ungraded judgment
  into a graded outcome — the one thing the split exists to prevent.
- **Do not narrow the pass because a screener looked.** Its findings save rediscovery of the obvious,
  and that is the entire saving. They say nothing about the class enumeration, the authority ladders, or
  the rule-set resolution, none of which a screener does.
- **And do not do screening work at review depth** — if a defect is visible at reading speed and no
  screener ran, report it and move on.

### Result

- The residual body edits landed: opening role statement, the write-target correction, severity as a
  *lookup* rather than an assignment, the catalog-anchored authority ladders, and the depth section.
- `README.md`: tier reconciled, write target corrected.
- `test-reviewer-conformance.sh` **33/33**, with **9/9 negative controls caught** — one per upstream
  delivery, each attributing the regression correctly.
- Nothing was redone that an upstream delivery owned: this delivery verified those regions and edited
  only its own.

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
