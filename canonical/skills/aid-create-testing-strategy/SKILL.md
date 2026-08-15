---
name: aid-create-testing-strategy
description: >
  Realize a ready testing-strategy seed from `.aid/design/testing-strategy.md` into the
  project's quality (C6) documents -- the test landscape (levels, coverage expectations, CI
  lane mapping, known gaps) and the gate policy (what blocks a merge, the thresholds, who
  may waive one). Use this skill when a testing-strategy seed is ready and the project has
  no record of its test lanes or merge gates yet. Creates the gate document on first use and
  registers it in `.aid/settings.yml` and `.aid/knowledge/README.md` in the same run, which
  opts that document into the Conformance Lane permanently -- a choice you are making by
  running this skill. To revise C6 content this lifecycle already committed, use
  `/aid-update-testing-strategy`; to author or revise test CODE rather than the strategy,
  use `/aid-create-test` or `/aid-update-test`. Produced by the aid-architect agent and
  independently verified by aid-reviewer (full verify). Allocates a work-NNN folder.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[<direction>] -- which parts of the testing-strategy seed to realize"
---

# Create Testing Strategy (realize a seed into the C6 documents)

Bind **VERB=`create`**, **ARTIFACT=`testing-strategy`** -- the `create` *stage* in the
contract's vocabulary -- then follow the shared contract at
`canonical/aid/templates/design-lifecycle.md`. This skill binds that contract and restates
none of its rules. It consumes the seed `/aid-design-testing-strategy` produces and touches
`.aid/design/` for no other purpose.

- **Boundary vs `/aid-update-testing-strategy`:** that skill revises C6 content this
  lifecycle already committed; this one realizes a seed.
- **Boundary vs `/aid-create-test` and `/aid-update-test`:** those author test *code*; this
  one writes the strategy and the gate policy.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> CREATE -> VERIFY -> PRESENT -> DONE**, as
`design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}` entry
line on each state.

---

## State: INTAKE

1. **Allocate** through the Work Initiation Gate exactly as the contract's Allocation rule
   requires (`canonical/skills/aid-design/SKILL.md` INTAKE step 4 is the shape), with
   `initiator: aid-create-testing-strategy`. `phase` is not driven.
2. **Read the seed** at `.aid/design/testing-strategy.md`.
3. **Resolve the destinations by concern, not filename.** This skill binds concern **C6**
   (quality & testing, `canonical/aid/templates/kb-authoring/concern-model.md`) and owns
   **two** documents. The seed's `## Destination` names both halves; where it does not,
   resolve C6 against `.aid/settings.yml` `knowledge.doc_set`, falling back to the C6 row of
   `canonical/aid/templates/kb-authoring/domain-doc-matrix.md`, and confirm with the user. An
   ambiguous realization is **asked**, never picked silently.
4. **Read both destinations** whole where they exist, and note each one's `source:` field.
5. **Classify complexity** for the `aid-architect` dispatch (verifier tier >= producer).

**Advance:** CREATE.

---

## State: CREATE

**Exactly three conditions refuse. There is no fourth.**

1. **No seed** at `.aid/design/testing-strategy.md` -> refuse, name
   `/aid-design-testing-strategy` as the skill that produces one, and write nothing.
2. **The seed's `## Open questions` still carries unresolved questions** by the detection
   rule in `design-lifecycle.md`, and no `--override-open-questions` was supplied -> refuse,
   naming each unresolved question and that override token. Leave the seed byte-identical.
3. **A destination's frontmatter says `source: generated`** -> refuse for that document: a
   registered build script owns its content, so this skill must not write it.

Otherwise it **realizes**. Whatever a destination already holds is never itself a reason to
refuse -- an as-built C6 document is the normal case this skill is for.

**The realization event.** Merge the settled seed content into the two destinations per the
content rules below, offer any additional output the user asks for, then **delete the seed**.
Situations resolve as:

- A destination absent, this skill owning the whole document -> create it, then register it
  (see *Creating the gate document* below).
- Destination present, the owned content absent -> add it. This is the dominant path.
- Destination present, carrying content **an earlier `create` for this artifact committed**
  -> that part routes to `/aid-update-testing-strategy` rather than being overwritten.
  "Committed content" means content an earlier run of this lifecycle wrote, at the
  granularity of the sections the seed's `## Destination` names -- **not** the as-built
  content `/aid-discover` wrote.

**A repeat `create` never halts with nothing done.** Every part of the seed that is new is
written; each part that would overwrite previously committed content is **named and routed**
to `/aid-update-testing-strategy`. The seed is deleted only when everything its
`## Destination` named was written; otherwise it stays in place carrying just the unrealized
parts, which `/aid-update-testing-strategy` then consumes.

**Advance:** VERIFY.

---

## State: VERIFY

**Full verify**, as `design-lifecycle.md` defines it. Not clean -> loop to CREATE; the
3-cycle circuit breaker there escalates to IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** PRESENT.

---

## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present both realized documents and assert: which
half went where; on a creation path both registration surfaces were written; and anything
routed to `/aid-update-testing-strategy` is named.

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.

---

## The two owned regions

| Destination | Owned region |
|---|---|
| the C6 **test** document (`test-landscape.md` by default) | the **whole document**, with its CI section restricted to the **test-lane mapping** -- which suites run in which lane, and nothing further about the pipeline |
| the C6 **gate** document (`quality-gates.md`, conditional) | the **whole document** |

This is a content split **under one owner**, not a contest between two skills. The split line
is the one this repository already draws in prose: the gate document is *distinct from the
automated test suites* the test document records.

## What this skill writes -- and must not

**Into the test document:** the test levels and what each is for, coverage expectations,
which suites run in which CI lane, and the known gaps.

**Into the gate document:** the **gate policy** -- what blocks a merge, the thresholds, who
may waive one and how. This skill owns that policy; a sibling that writes the delivery
pipeline writes only the *stage*, never the policy.

**Must not write:**

- **Pipeline stages, triggers, environments or promotion rules** -- concern C8. Cite the C8
  document instead; `/aid-create-cicd` owns that content.
- **A framework version, in either C6 document** -- concern C0, `/aid-create-stack`'s. A
  version recorded in a C6 doc is a duplicate that will drift.

## Creating the gate document (on demand, same run)

Where the concern's gate document is absent, this skill creates it, sets
`source: forward-authored` and `sources: []`, and registers it **in the same run** -- never
later, never by a hand edit outside the skill run, and never by another skill:

1. Append exactly one `.aid/settings.yml` `knowledge.doc_set` entry
   `quality-gates.md|aid-researcher-quality|required` -- presence `required`, owner taken
   from the document's **matrix row** slot.
2. Append one `.aid/knowledge/README.md` Completeness row and increment that file's
   `**Doc-set:** N documents` line.

Both use the R13 append-block idiom -- one entry appended, never a rewrite of the block, and
`term_exclusions` is never touched. Both must succeed in the same run; if either fails,
report and halt.

## Frontmatter invariants

- A document **this skill creates** gets `source: forward-authored` and `sources: []`.
- A document that **already existed** keeps whatever `source:` value it had, **unchanged**.
- `source: generated` **refuses** (CREATE condition 3).
- `approved_at_commit:` is **never** written and never restamped -- it is generator-written
  by `/aid-discover` and `/aid-update-kb` on approval, and this skill is neither.
- `sources:` gains only what this run actually used.

## Write discipline

Read each destination whole, edit in place, and write back with everything outside the edited
range **byte-identical**. Never regenerate and never restructure a document. Adding a `## `
section obliges updating that document's `## Contents` list in the **same** write.

## Constraints

- **`phase` is not driven** by this skill.
- **Full verify**, per `design-lifecycle.md`.
- **Seed consumed on the realizing path**, and left in place for the parts that routed.
- **Clean context**; verification always an `aid-reviewer` sub-agent dispatch.
- **Tracking:** write STATE `lifecycle` at every transition.
