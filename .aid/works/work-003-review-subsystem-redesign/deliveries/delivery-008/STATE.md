---
delivery_state: Done
gate_tier: Medium
gate_grade: "A+"
gate_timestamp: "2026-07-29T06:15:00Z"
ticket_ref: "--"
---

# Delivery State -- delivery-008

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

> **Delivery:** delivery-008
> **Work:** work-003-review-subsystem-redesign
> **Branch:** aid/work-003-delivery-008

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

- **Issue List:** 2 findings, both `Fixed`, 0 `Pending`. Severities as found: 1 `[MEDIUM]`, 1 `[LOW]`.
- **Closes `G-001`** from delivery-007 — the gap that recorded "the gate exists but nothing calls it".
  Marked `Answered` in delivery-007's register with the resolution `canon -> all 19 grade sites
  gated`. **First full round trip of the gap protocol**: raised in one delivery, resolved in the next,
  and the answer is now in `--resolved-keys` so it can never be re-asked.

### The site set is derived, and that is the whole design

`19 files, 20 invocation lines` — `aid-define/references/state-cross-reference.md` carries two. Of
those 19, one (`criteria-gap-protocol.md`) already showed the gate; the other 18 were wired.

**The oracle has no exclusion list.** It derives its file set from disk — every file containing
`bash canonical/aid/scripts/grade.sh` — and requires each to mention the gate at an *earlier* line. A
grade site added next year fails the suite the day it lands, with nobody remembering to update
anything. A negative control that drops a brand-new ungated grade site into the tree turns the suite
red, which is that claim proved rather than asserted.

**The pattern needs the `bash ` prefix, and that is not cosmetic.** Matching a bare
`canonical/aid/scripts/grade.sh` also catches ten files that merely *mention* the grader — prose,
see-also lines, reviewer briefs naming it as the authority. Demanding a gate call inside a sentence
would be nonsense, so an invocation is identified by the `bash ` that makes it one. My first sweep
dropped the prefix and reported 29 files; the SPEC's 18 was right and my sweep was wrong.

### Two forms, and the bug the second one hid

Twelve sites are fenced or line-start invocations; six are inline-backticked steps inside `SKILL.md`
prose; one is a prose form. The inline rewrite reuses the grade call's own ledger path so the gate
checks the same file — and there a greedy `\S+` **swallowed the closing backtick and the full stop**,
emitting `--ledger <ledger>`.` into shipped documentation.

That would have satisfied any "does the file mention the gate?" check. It is caught now by `GW08`,
which asserts no emitted gate command carries markup in its `--ledger` argument, and by `GW09`, which
requires every gate *invocation* to actually pass `--ledger` — a bare call exits 2 (usage) and would
read as a failure rather than a clean gate.

### An NFR-1 alarm that was not one

A closing check compared `git show <ref>:grade.sh` against the working tree with `cmp` and reported
**"CHANGED -- NFR-1 violated"**. It had not changed: `git show` emits the stored blob while the
working tree carries the repo's line-ending filters, so the bytes differ where the content does not.
`git diff` — which applies those filters — reports **zero** changes.

Worth recording twice over. A false NFR-1 alarm is nearly as damaging as a missed one, and the fix was
to assert the invariant the authoritative way rather than to trust a byte comparison across a filter
boundary. `GW15` now does exactly that.

### Sites named individually, despite the sweep being total

Four are asserted by name as well, because a total sweep says *something* regressed without saying
*what*, and these four have outsized consequences:

- **the Lite path's shortcut engine** — every shortcut skill grades through it, so one omission would
  let the entire Lite path grade over an open gap
- **`aid-execute`'s DELIVERY-GATE** — where a delivery is actually accepted
- **`aid-summarize`'s VALIDATE** and **`aid-deploy`'s VERIFYING** — machine-written ledgers that
  cannot produce a gap row today. Their call is a cheap exit-0 invariant, and wiring them is
  *precisely* what makes the sweep total: a partial wiring needs an exclusion list, and exclusion
  lists rot.

### Behaviour, not just string presence

A wiring suite that never runs the thing it wires proves only that a string appears. `GW11`–`GW13`
execute the gate against three real ledgers and require it to fire on `[GAP:CRITERIA]` and **only**
on that — `[GAP:CRITERIA:NB]` and `[GAP:EVIDENCE]` must pass. A control that loosens the
discriminator match to a prefix trips `GW12`.

### Result

- 18 sites wired, 19 total gated, `grade.sh` untouched (asserted two ways).
- `test-gap-gate-wiring.sh` **15/15** with **5/5 negative controls caught**, including the new-site
  totality control.
- 184 assertions green across seven suites; both NFR-5 fixture suites unchanged.
- Render parity verified; both dogfood installs synced (18 files updated each).

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
