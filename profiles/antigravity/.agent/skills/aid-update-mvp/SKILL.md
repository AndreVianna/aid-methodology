---
name: aid-update-mvp
description: >
  Revise roadmap.md's ## MVP section only -- the first shippable slice: its contents, the
  line reasoning, what was cut, and its Status field (including the transition to Shipped
  <version>). Use this skill when the MVP section already carries committed content and its
  scope has changed. May create the ## MVP section if roadmap.md exists without one. Reads
  and consumes an MVP seed when one is present in .aid/design/; never requires one. Asks
  every run which previously created outputs to update alongside it -- no stored list, no
  tracking metadata written. Everything outside ## MVP belongs to /aid-update-roadmap. When
  roadmap.md is absent, routes to /aid-create-roadmap without writing anything.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[<slice>] -- what to revise in the MVP section (contents, line, cuts, status)"
---

# Update MVP (revise roadmap.md's ## MVP section)

`/aid-update-mvp` revises the `## MVP` section of `.aid/knowledge/roadmap.md`. It is
an `update`-stage skill under the shared contract in
`.agent/aid/templates/design-lifecycle.md` (class 1), reading and consuming a seed
from `.aid/design/mvp.md` when one is present, and never requiring one.

- **Boundary vs `/aid-update-roadmap`:** this skill owns only the `## MVP` byte range.
  Everything outside it -- the preamble, `## Contents`, `## Now`, `## Next`, `## Later` --
  belongs to `/aid-update-roadmap`. The byte-range write discipline enforces this
  structurally.
- **May create the section.** If `roadmap.md` exists but has no `## MVP` section this
  skill creates it at the anchor position -- immediately after `## Contents` and before
  `## Now` (`feature-003 §3c`).
- **Destination absent:** when `roadmap.md` does not exist this skill routes to
  `/aid-create-roadmap`, names it explicitly, and writes nothing.
- **No document ownership, no registration.** This skill writes a section of an existing
  document, not a document of its own. It never writes a `.aid/settings.yml`
  `knowledge.doc_set` entry and never writes a `.aid/knowledge/README.md` Completeness
  row (REQUIREMENTS CC-5).
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> GUARD -> UPDATE -> VERIFY -> PRESENT -> DONE**.
Print the `[State: NAME] -- {purpose}` entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What would
   you like to revise in the MVP section -- slice contents, the line reasoning, cuts, or
   status?") and wait.
2. **Allocate, exactly per `design-lifecycle.md § Skill shape -- Allocation`** -- the Work
   Initiation Gate, then `initiator: aid-update-mvp`, `active_skill: aid-update-mvp`,
   `pipeline.path: lite`, `lifecycle: Running`. `phase` is not driven.
3. **Read the destination** at `.aid/knowledge/roadmap.md`. If absent, **route** to
   `/aid-create-roadmap` -- name it explicitly in the response -- and write nothing.
   Set `lifecycle: Paused-Awaiting-Input`. Advance to DONE without proceeding further.
4. **Read the seed** at `.aid/design/mvp.md` if one exists. Note its presence or absence;
   do not require it.
5. **Ask the derived-outputs question** -- every run, unconditionally: "Which previously
   created outputs should be updated alongside the MVP section?" Wait for the user's
   answer before proceeding. Write no stored list and no tracking metadata anywhere.
6. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).

**Advance:** GUARD.

---

## State: GUARD

**Readiness gate (class-1 contract, feature-002 §3b).** Only applies when a seed was
found in INTAKE.

- **Seed present, unresolved questions, no override** → refuse. Name each unresolved
  question **and** the override flag `--override-open-questions` the user must supply to bypass the gate. Write
  nothing; leave seed and destination byte-identical. Set `lifecycle:
  Paused-Awaiting-Input`.
- **No seed present** → advance (gate does not apply).
- **Seed present, no unresolved questions, or override supplied** → advance.

**Advance:** UPDATE.

---

## State: UPDATE

Dispatch **`aid-architect`** (clean context, tiered) to revise the `## MVP` section.
Apply the **byte-range write discipline** (`feature-003 §4`, feature-002 §3c *Mechanics*):
read the whole `roadmap.md` file, identify the `## MVP` byte range (the literal heading
`## MVP`, matched exactly, through to the next heading of level 2 or shallower, or EOF),
replace only that range with the new content, and write the file back with every byte
outside that range **byte-identical** -- no reformatting, no whitespace change, no
re-ordering of any other region.

**May create the section.** If `roadmap.md` exists without a `## MVP` section: insert the
section immediately after the `## Contents` block and before `## Now` (`feature-003 §3c`,
feature-002 §3c *Position when created*). This is a pure insertion -- zero deletions in
the diff (`git diff --numstat` shows 0 deletions).

**`## MVP` section shape** (`feature-003 §3c`):

    ## MVP

    - **What:** the first shippable slice, itemized.
    - **Why:** why the line falls there.
    - **Rejected:** what was cut from the slice, each with the reason for the cut.
    - **Status:** Not started | In progress | Shipped <version> -- with the evidence
      anchor.

**Artifact-specific duties:**
- **Revise the slice** -- update `What`, `Why`, and `Rejected` fields.
- **Update `Status`** -- including the transition to `Shipped <version>` with a durable
  evidence anchor (path plus a grep-recoverable symbol or heading, never `path:LINE`).

**Never edits `## Contents`** -- that block is outside the `## MVP` byte range and
belongs to `/aid-create-roadmap`. The byte-range discipline makes this structurally true.

**Seed handling (CC-3).** If a seed was read in INTAKE: use it as input to the revision;
**delete it** after the update is written. If no seed was present: no file to delete.

**User-named outputs.** For each output the user named in INTAKE: update it alongside the
MVP section in this same dispatch.

**Advance:** VERIFY.

---

## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to UPDATE; the circuit-breaker there governs escalation
to IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** PRESENT.

---

## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the revised `## MVP` section clearly.
Assert:

- `## Contents` is unchanged -- the `- [MVP](#mvp)` entry is present and no other entry
  was added or removed.
- Every byte outside the `## MVP` range is identical to what it was before this run.
- If a section was created (it was absent before): the section now exists immediately
  after `## Contents`.
- If a seed was consumed: `.aid/design/mvp.md` no longer exists.
- No `.aid/settings.yml` `knowledge.doc_set` entry and no `.aid/knowledge/README.md`
  Completeness row was written.
- No tracking metadata was written to any output.
- To revise the direction entries outside MVP, use `/aid-update-roadmap`.

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.

---

## Constraints

- **Owns only `## MVP`** -- every byte outside that range is byte-identical after this
  run (`feature-003 §4`; REQUIREMENTS AC-6a).
- **Never edits `## Contents`** -- that block belongs to `/aid-create-roadmap`; the
  byte-range discipline structurally prevents it.
- **Absent destination routes to `/aid-create-roadmap`** -- names it, writes nothing
  (`feature-003 §6c`, §4; REQUIREMENTS CC-5).
- **Byte-range write discipline**: read the whole file, replace only the `## MVP` range,
  write back with every other region byte-identical -- never regenerate the document.
- **No registration entry** -- this skill creates no document and therefore writes no
  `.aid/settings.yml` `knowledge.doc_set` entry and no `.aid/knowledge/README.md`
  Completeness row (REQUIREMENTS CC-5).
- **`phase` is not driven** by this skill (`design-lifecycle.md § Skill shape --
  Allocation`).
- **Full verify**, per `design-lifecycle.md`, unlike a light single-pass check.
- **Seed consumed when present, never required** (CC-3). If a seed was read: delete it
  after the update is written. If no seed: proceed without one.
- **Derived-outputs question asked every run, unconditionally** -- no stored list, no
  tracking metadata written (FR-8, feature-002 §3d).
- **C-3 compliance**: writes no `## Change Log`, no `## Revision History`, no
  `changelog:` frontmatter field, no work id, and no work-folder path into `roadmap.md`.
- **Clean context**; **verification always a sub-agent dispatch** (`aid-reviewer`).
- **Tracking:** write STATE `lifecycle` at every transition.
