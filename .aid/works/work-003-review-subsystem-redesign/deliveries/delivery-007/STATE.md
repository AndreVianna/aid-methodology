---
delivery_state: Done
gate_tier: Medium
gate_grade: "A+"
gate_timestamp: "2026-07-29T05:55:00Z"
ticket_ref: "--"
---

# Delivery State -- delivery-007

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

> **Delivery:** delivery-007
> **Work:** work-003-review-subsystem-redesign
> **Branch:** aid/work-003-delivery-007

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

- **Issue List:** 3 findings + 1 gap + 5 coverage rows,
  `.aid/.temp/review-pending/delivery-007.md` — all 3 findings `Fixed`, 0 `Pending`. Severities as
  found: 1 `[HIGH]`, 1 `[MEDIUM]`, 1 `[LOW]`.
- **The gap machinery was exercised on this delivery's own artifacts**, not only on fixtures: a real
  `G-` row written, the gate correctly declining to block it (it is `:NB`), and the gap promoted into
  this delivery's own register — which created the `## Criteria Gaps` section in a live `STATE.md` on
  first use.

### The bug where satisfying one criterion broke another

`--promote` reset a `Declined` gap's status back to `Pending` when the gap recurred. That looked
right: the gap came back, so it is pending again. It satisfied AC-10 — the recurrence counter
incremented and the loop was flagged.

**And it silently broke AC-5.** A key whose status is `Pending` drops out of `--resolved-keys`, so the
next batch would re-ask a question the user had already answered *no* to. The single failure the whole
register exists to prevent, introduced by making the other half work.

The smoke test caught it because step 7 printed **nothing** where it should have listed the declined
key. Not an assertion — reading the output of a hand-run and noticing a blank where a line belonged.

The rule now: **a recurrence increments the counter and the answer stands.** Only an explicit terminal
status may replace a terminal status. `CG16` and `CG18` assert it, and a negative control that
reintroduces the exact bug trips both.

That pair is worth stating plainly because it generalises: two acceptance criteria that pull against
each other need a test that holds *both* at once. Testing them separately is how this shipped in the
first place.

### Two scripts, because one exit-code alphabet cannot serve two purposes

`check-gaps.sh` is a **linter**: its exit code *is* the finding (0 clean / 1 gap), like every other
lint in the tree. `gap-register.sh` is a **state writer**, which must distinguish a bad argument from
an unreadable file from a failed write. Merging them would force one of those alphabets to lie.

The gate also cannot live inside `grade.sh` — NFR-1 forbids changing its behaviour, and
grade-inertness is the wrong tool regardless: **an inert row cannot stop a grade, only fail to affect
one.** Stopping requires a gate outside the grader.

### The discriminator had to be anchored

`[GAP:CRITERIA]` blocks; `[GAP:CRITERIA:NB]` must not. A prefix match on `[GAP:CRITERIA` would treat
them identically, and every demoted gap would block forever. The awk match is anchored to the closing
bracket, and a control that loosens it to the prefix trips `CG03` and `CG07`.

### Key hygiene is a hard rejection, not a warning

A gap key containing a row ID, date, or cycle number never dedupes — which disables **both**
never-re-asking and loop detection at once, silently, while every command still reports success. So
`--promote` rejects an uppercase key, a too-short key, a key carrying a date, and a depth above 2.
Four rejections, all controlled.

### What is deliberately not done here

`G-001` in this delivery's register: **the gate is wired at none of the 18 grade sites.** It exists
and works, but nothing calls it yet — that wiring is delivery-008's scope. Recorded as
`[GAP:CRITERIA:NB]` rather than left implicit, so the gate does not block its own delivery while the
obligation stays visible in a git-tracked file.

That is also the protocol's first genuine use: a gap raised because the work is honestly incomplete,
demoted rather than discarded, with a named resolution.

### Result

- **The register survives.** `## Criteria Gaps` added to the work, discovery and delivery templates,
  and created on first use in existing `STATE.md` files so no migration pass is needed. `CG29`
  asserts neither register file is gitignored — the ledger under `.aid/.temp/` is deleted at DONE, so
  the register is the only thing that outlives both the halt and that deletion.
- **The interim `OOS` exemption is retired.** An ungrounded finding is now unwritable at *every*
  status, asserted across all six (`WL13b`). An unmatched artifact class is a `[GAP:CRITERIA]` row,
  not a finding nobody can trace to a rule.
- **The halt is not a new mechanism.** `PAUSE-FOR-USER-ACTION`, cited rather than argued, with
  `aid-housekeep`'s existing register-write-then-route as precedent.
- **`criteria-gap-protocol.md`** documents the Type 1/2 model, the three discriminators, the ten-step
  lifecycle, routing (including why only the KB route passes its brief through the prompt — its
  worktree is cut from `master`, so a register write is invisible across that boundary), restricted
  mode, and why the depth cap is 2.
- Suites: `test-criteria-gaps.sh` **35/35** with **5/5 negative controls caught**,
  `test-writeback-ledger.sh` 44/44, `test-ledger-eighth-column.sh` 23/23,
  `test-review-rubrics.sh` 28/28, both NFR-5 fixture suites green. 170 assertions, zero failures.
- Both gap scripts render to all five profiles and are present in both dogfood installs.

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

## Criteria Gaps

<!-- AUTHORED by gap-register.sh, never by hand. Section created on first use.
     Cell contracts: aid/templates/work-state-template.md ## Criteria Gaps -->

| Gap Key | Kind | Status | Depth | Recurrences | Scope | Criterion | Resolution |
|---|---|---|---|---|---|---|---|
| review/gate-wiring-sites | criteria | Pending | 0 | 0 | canonical/aid/scripts/review/check-gaps.sh | the pre-grade gate is unwired: no grade site calls it yet | delivery-008 wires all 18 grade sites |
