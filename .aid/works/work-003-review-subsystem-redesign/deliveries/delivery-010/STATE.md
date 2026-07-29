---
delivery_state: Done
gate_tier: Medium
gate_grade: "A+"
gate_timestamp: "2026-07-29T15:05:00Z"
ticket_ref: "--"
---

# Delivery State -- delivery-010

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

> **Delivery:** delivery-010
> **Work:** work-003-review-subsystem-redesign
> **Branch:** aid/work-003-delivery-010

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

- **Issue List:** 2 findings, both `Fixed`, 0 `Pending`. Both `[LOW]`, and both against my own test
  rather than the artifact.
- **Result:** the boilerplate is split, `aid-screener` exists, and the roster is ten.

### The split's success criterion was an empty diff, and it held

Nine agents inherit this boilerplate, so a split that changed the rendered output would change nine
agent bodies at once. That is why this was its own delivery rather than bundled with anything.

**The mechanism decided the shape.** `_resolve_includes` substitutes a whole template file verbatim,
with no newline trimming, and the token sits on its own line — so the token line's newline is appended
after the content. With two tokens on two lines, the *second* line's newline is what separates the
blocks. Therefore the blank separator that lived between the two sections had to be dropped from
**both** files: keeping it would have added a stray blank line to every rendered agent.

    file A = heartbeat, no trailing blank
    file B = self-review discipline
    render = A + newline + B   ==   the original

Verified by reconstructing the original from the two halves and requiring byte equality before writing
anything, then again after rendering: **zero differences outside the two template files and the
manifests that record them, and zero changed agent bodies.** `BS07` asserts the round trip in CI, and a
control that puts the blank line back turns it red.

### The screener is defined by what it lacks

Its reason to exist is an **absence**: it does not include the discipline boilerplate, so it does not
carry *"find nothing more to find before handing off"*. If it did, it would be a slow reviewer and
would cost exactly what it exists to save.

So the body is a **counter-instruction**, not a subset of the reviewer's: stop when the obvious is
exhausted, do not enumerate the class, do not dig, and — the important one — **a clean screen is not a
pass.** A cheap pass mistaken for a thorough one is worse than no pass at all, so it must close with one
of exactly two sentences, never leaving the caller to infer which it meant.

**It has no `Bash`, and that is load-bearing three times over.** It cannot write a ledger row, so a
cheap pass can never contribute to a grade. It cannot run a build or a validator, so it cannot slowly
become a review. And its cost stays bounded by reading, which is the only reason it is worth
dispatching. The body says so explicitly, so the absence reads as a design decision rather than an
oversight someone might later "fix".

The asymmetry is asserted **in both directions and in every rendered tree**: the screener must not carry
the mandate *and* the reviewer must. Controls that give the screener the mandate, grant it `Bash`, or
take the mandate off the reviewer are all caught.

### Two findings, both against my own test

- **`BS22` conflated "grants Bash" with "mentions Bash".** The screener's body discusses `Bash` at
  length — there is a whole section called *"Why you have no Bash"* — so a whole-body grep failed on a
  correct artifact. Granting is the `tools:` frontmatter line; the assertion now reads that, and skips
  the Codex tree, which renders TOML with no `tools` field at all.
- **`BS17` matched text I had not written.** It grepped for lowercase `not exhaustive` where the body
  says `deliberately NOT exhaustive`.

Both are the same mistake in different clothes: asserting against remembered wording instead of the
artifact. Cheap to fix here, and worth noting because it is the third delivery in a row where the test
needed more correcting than the thing it tested.

### The count gate did the work for me

`test-doc-counts.sh` **derives** the agent count from the tree rather than hardcoding it, then asserts
each public surface states the current number. Adding one directory made it name all ten stale surfaces
precisely — no searching required. That is the difference between a gate that ages well and one that
becomes a chore.

Ten surfaces were gated; six more (the site content, the generator's own SKILL doc, and two live
`toHaveLength(9)` assertions) are **not** covered by that gate and had to be found by search. Worth
recording as a real gap: the gate scopes itself to public docs and deliberately skips the KB, so the
site and the build scripts rot silently.

### One thing I chose not to change

`decisions.md`'s ADR **D15 — Nine agents in three tiers** keeps its title. It records what was decided
at the time; rewriting it to say "Ten" would falsify the history the record exists to keep. An
amendment note was added instead — and the count gate already excludes changelog and history lines for
exactly this reason. The tier logic in D15 is also what *admitted* the screener: matching model cost to
task stakes is precisely the argument for a Small-tier screening pass.

### Result

- `agent-boilerplate.md` reduced to the heartbeat and stop-poll contract; `agent-discipline-boilerplate.md`
  carries the self-review discipline. Nine agents take both includes, in order.
- `aid-screener`: small tier, `Read, Glob, Grep`, no `Bash`, heartbeat but no exhaustiveness mandate.
- Roster 9 → 10 across 16 files, plus a tiering-table row whose `Escalate` cell reads **never** —
  escalating a screener turns it into the review it runs before.
- All five Codex agent TOMLs parse, including the new one, with `has heartbeat=True, has mandate=False`
  visible in the rendered body.
- Suites: `test-agent-boilerplate-split.sh` **27/27** with **4/4 negative controls caught**;
  `test-doc-counts.sh` **31/31**.

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
