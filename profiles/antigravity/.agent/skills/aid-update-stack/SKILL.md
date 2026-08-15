---
name: aid-update-stack
description: >
  Revise the project's technology (C0) Knowledge Base document -- languages, runtimes,
  frameworks, package managers, and build and test tooling with their versions, dependencies
  and constraints -- plus any previously created outputs you name. Use this skill when the
  technology-stack document already exists and a choice in it has changed. Requires no
  design seed: the change you state in the run is a sufficient input. Reads and consumes a
  stack seed when one is present in `.aid/design/`. When the C0 document does not yet exist,
  routes to `/aid-create-stack`. To change a configuration option within a chosen stack
  rather than the stack record, use `/aid-create-config` or `/aid-update-config`. Produced
  by the aid-architect agent and independently verified by aid-reviewer (full verify).
  Allocates a work-NNN folder.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<change> -- what to revise in the technology-stack record"
---

# Update Stack (revise the C0 document)

Bind **VERB=`update`**, **ARTIFACT=`stack`** -- the `update` *stage* in the contract's
vocabulary -- then follow the shared contract at
`.agent/aid/templates/design-lifecycle.md`. This skill binds that contract and restates
none of its rules.

- **Boundary vs `/aid-create-stack`:** that skill realizes a seed and owns the creation path;
  this one is the maintenance verb. Where the destination is absent this skill routes there
  rather than standing one up itself.
- **Boundary vs `/aid-create-config` and `/aid-update-config`:** those act on a configuration
  option *within* a chosen stack; this one revises the record of the stack choice.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> UPDATE -> VERIFY -> PRESENT -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}` entry
line on each state.

---

## State: INTAKE

1. **Require a stated change.** Empty argument -> ask one bootstrapping question ("What
   should change in the technology-stack record?") and wait.
2. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`.agent/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-update-stack`. `phase` is not driven.
3. **No seed is required.** The change stated in this run is a sufficient input, and this
   skill completes without a seed. **Read and consume one when present** at
   `.aid/design/stack.md`, carrying its `## Current direction` into the destination and
   deleting it once realized.
4. **Resolve the destination by concern.** This skill binds concern **C0** (technology). Where
   a seed supplied a `## Destination`, use it; otherwise apply the concern rule here --
   resolve C0 against `.aid/settings.yml` `knowledge.doc_set`, falling back to the C0 row of
   `.agent/aid/templates/kb-authoring/domain-doc-matrix.md` -- and **confirm the resolution
   with the user before writing**. Never resolve silently.
5. **Read the whole destination**, and note its `source:` field. Absent destination -> route
   to `/aid-create-stack` and write nothing.
6. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** UPDATE.

---

## State: UPDATE

1. **Apply only the change the user named in this run**, to the owned C0 content, per the
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

Set `lifecycle: Paused-Awaiting-Input`. Present the revision, name every output touched, state
where any rejected alternative went, and assert that a consumed seed is gone.

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.

---

## What this skill writes -- and must not

**Writes (C0):** languages, runtimes, frameworks, package managers, and build and test tooling
**each with its version**, plus version constraints and floors. Among the twelve foundation
skills, the stack pair is the **only** writer of framework and tool versions, and this skill
keeps that sole ownership.

**Must not write:**

- **Rejected alternatives into the C0 document.** That document has no section for them.
  This skill **routes** a rejected alternative to the project's D document (`decisions.md` by
  default, owner `aid-researcher-architecture`) -- it is the only one of the twelve that does.
- **Architecture structure** -- concern C1, the architecture skills'.
- **CI runner configuration** -- concern C8, the cicd skills'.

## Frontmatter invariants

- The destination's `source:` is left **unchanged**, whatever it was -- neither verb rewrites
  it.
- `source: generated` **refuses**.
- `approved_at_commit:` is **never** written and never restamped -- it is generator-written by
  `/aid-discover` and `/aid-update-kb` on approval, and this skill is neither.
- `sources:` gains only what this run actually used.

## Write discipline

Read the destination whole, edit in place, and write back with everything outside the edited
range **byte-identical**. Never regenerate and never restructure the document. Adding a
`## ` section obliges updating that document's `## Contents` list in the **same** write.

## Conformance Lane

This skill changes **only what the user named in that run**. It does **not** resolve a flagged
Conformance-Lane divergence on its own -- reconciliation there is human by the lane's design --
so a flag the user did not point at survives this run untouched.

## Constraints

- **`phase` is not driven** by this skill.
- **Full verify**, per `design-lifecycle.md`.
- **No seed required; a present seed is consumed.**
- **Never stands up its destination** -- that path belongs to `/aid-create-stack`.
- **Clean context**; verification always an `aid-reviewer` sub-agent dispatch.
- **Tracking:** write STATE `lifecycle` at every transition.
