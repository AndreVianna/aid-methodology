---
name: aid-update-testing-strategy
description: >
  Revise the project's quality (C6) documents -- the test landscape (levels, coverage
  expectations, CI lane mapping, known gaps) and the gate policy (what blocks a merge, the
  thresholds, who may waive one) -- plus any previously created outputs you name. Use this
  skill when the testing-strategy record already exists and a lane or a gate has changed.
  Requires no design seed: the change you state in the run is a sufficient input. Reads and
  consumes a testing-strategy seed when one is present in .aid/design/. When a C6 document
  does not yet exist, routes to /aid-create-testing-strategy. To author or revise test CODE
  rather than the strategy, use /aid-create-test or /aid-update-test. Produced by the
  aid-architect agent and independently verified by aid-reviewer (full verify). Allocates a
  work-NNN folder.
allowed-tools: Read, Glob, Grep, shell, Write, Edit, Agent
argument-hint: "<change> -- what to revise in the testing strategy or the gate policy"
---

# Update Testing Strategy (revise the C6 documents)

Bind **VERB=`update`**, **ARTIFACT=`testing-strategy`** -- the `update` *stage* in the
contract's vocabulary -- then follow the shared contract at
`.github/aid/templates/design-lifecycle.md`. This skill binds that contract and restates
none of its rules.

- **Boundary vs `/aid-create-testing-strategy`:** that skill realizes a seed and owns the
  creation path; this one is the maintenance verb. Where a destination is absent this skill
  routes there rather than standing one up itself.
- **Boundary vs `/aid-create-test` and `/aid-update-test`:** those author test *code*; this
  one revises the strategy and the gate policy.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> UPDATE -> VERIFY -> PRESENT -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}` entry
line on each state.

---

## State: INTAKE

1. **Require a stated change.** Empty argument -> ask one bootstrapping question ("What should
   change in the testing strategy or the gate policy?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.github/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-update-testing-strategy`. `phase` is not driven.
3. **No seed is required.** The change stated in this run is a sufficient input, and this
   skill completes without a seed. **Read and consume one when present** at
   `.aid/design/testing-strategy.md`, carrying its `## Current direction` into the
   destinations and deleting it once realized.
4. **Resolve the destinations by concern.** This skill binds concern **C6** (quality &
   testing) and owns **two** documents. Where a seed supplied a `## Destination`, use it;
   otherwise apply the concern rule here -- resolve C6 against `.aid/settings.yml`
   `knowledge.doc_set`, falling back to the C6 row of
   `.github/aid/templates/kb-authoring/domain-doc-matrix.md` -- and **confirm the resolution
   with the user before writing**. Never resolve silently.
5. **Read both destinations** whole, and note each one's `source:` field. An absent
   destination -> route to `/aid-create-testing-strategy` for that document and write nothing
   there.
6. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** UPDATE.

---

## State: UPDATE

1. **Apply only the change the user named in this run**, to the owned C6 content, per the
   content rules below.
2. **Ask, every run, which derived outputs to update alongside this one.** This step is
   unconditional -- it runs on every invocation, and the answer is **stored nowhere**: no
   frontmatter backlink, no manifest, no registry, and no state carried between runs. The
   question is asked afresh each time.
3. **Write no tracking metadata** into any output this run touches -- no `derived-from`, no
   `source-doc`, no `generated-by`, no `aid-tracked` field, and no skill-attribution line.
4. **`source: generated` refuses.** A registered build script owns that content.

**Advance:** VERIFY.

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to UPDATE; the
3-cycle circuit breaker there escalates to IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** PRESENT.

---

## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the revision, say which C6 half each change
went to, name every output touched, and assert that a consumed seed is gone.

**Advance:** DONE.

---

## The two owned regions

| Destination | Owned region |
|---|---|
| the C6 **test** document (`test-landscape.md` by default) | the **whole document**, with its CI section restricted to the **test-lane mapping** |
| the C6 **gate** document (`quality-gates.md`, conditional) | the **whole document** |

## What this skill writes -- and must not

**Into the test document:** the test levels and what each is for, coverage expectations, which
suites run in which CI lane, and the known gaps.

**Into the gate document:** the **gate policy** -- what blocks a merge, the thresholds, who may
waive one and how. This pair owns that policy.

**Must not write:**

- **Any pipeline stage, trigger, environment or promotion rule** -- concern C8, the cicd
  skills'. Cite the C8 document instead.
- **A framework version, in either C6 document** -- concern C0, the stack skills'. A version
  recorded in a C6 doc is a duplicate that will drift.

## Frontmatter invariants

- Each destination's `source:` is left **unchanged**, whatever it was -- neither verb rewrites
  it.
- `source: generated` **refuses**.
- `approved_at_commit:` is **never** written and never restamped -- it is generator-written by
  `/aid-discover` and `/aid-update-kb` on approval, and this skill is neither.
- `sources:` gains only what this run actually used.

## Write discipline

Read each destination whole, edit in place, and write back with everything outside the edited
range **byte-identical**. Never regenerate and never restructure a document. Adding a `## `
section obliges updating that document's `## Contents` list in the **same** write.

## Conformance Lane

This skill changes **only what the user named in that run**. It does **not** resolve a flagged
Conformance-Lane divergence on its own -- reconciliation there is human by the lane's design --
so a flag the user did not point at survives this run untouched.

## Constraints

- **`phase` is not driven** by this skill.
- **Full verify**, per `design-lifecycle.md`.
- **No seed required; a present seed is consumed.**
- **Never stands up a destination** -- that path belongs to `/aid-create-testing-strategy`.
- **Clean context**; verification always an `aid-reviewer` sub-agent dispatch.
- **Tracking:** write STATE `lifecycle` at every transition.
