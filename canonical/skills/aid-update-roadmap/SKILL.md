---
name: aid-update-roadmap
description: >
  Revise roadmap.md's direction entries outside the ## MVP section --
  add, revise or supersede direction entries, and move an entry between
  horizon sections (## Now, ## Next, ## Later). Reads and consumes a
  roadmap seed when one is present in .aid/design/; never requires one.
  Asks every run which previously created outputs to update alongside it
  -- no stored list, no tracking metadata written. The ## MVP section
  belongs entirely to /aid-update-mvp -- this skill never touches it and
  leaves the ## Contents MVP index entry in place whether or not the
  section exists. When roadmap.md is absent, routes to /aid-create-roadmap
  without writing anything.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[<direction>] -- what to revise (entries to add, update, supersede, or move)"
---

# Update Roadmap (revise direction entries outside ## MVP)

`/aid-update-roadmap` revises the direction entries of `.aid/knowledge/roadmap.md`
outside the `## MVP` section. It is an `update`-stage skill under the shared contract in
`canonical/aid/templates/design-lifecycle.md` (class 1), reading and consuming a seed
from `.aid/design/roadmap.md` when one is present, and never requiring one.

- **Boundary vs `/aid-update-mvp`:** this skill owns every byte of `roadmap.md` **except**
  the `## MVP` section. It never creates, edits, or removes `## MVP` content. The
  `- [MVP](#mvp)` index entry in `## Contents` is left in place whether or not the section
  exists -- the index is outside the `## MVP` byte range and belongs to this skill's region.
- **Destination absent:** when `roadmap.md` does not exist this skill routes to
  `/aid-create-roadmap`, names it explicitly, and writes nothing.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> GUARD -> UPDATE -> VERIFY -> PRESENT -> DONE**.
Print the `[State: NAME] -- {purpose}` entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What would
   you like to revise in the roadmap -- entries to add, update, supersede, or move between
   horizons?") and wait.
2. **Allocate, exactly per `design-lifecycle.md § Skill shape -- Allocation`** -- the Work
   Initiation Gate, then `initiator: aid-update-roadmap`, `active_skill:
   aid-update-roadmap`, `pipeline.path: lite`, `lifecycle: Running`. `phase` is not
   driven.
3. **Read the destination** at `.aid/knowledge/roadmap.md`. If absent, **route** to
   `/aid-create-roadmap` -- name it explicitly in the response -- and write nothing.
   Set `lifecycle: Paused-Awaiting-Input`. Advance to DONE without proceeding further.
4. **Read the seed** at `.aid/design/roadmap.md` if one exists. Note its presence or
   absence; do not require it.
5. **Ask the derived-outputs question** -- every run, unconditionally: "Which previously
   created outputs should be updated alongside roadmap.md?" Wait for the user's answer
   before proceeding. Write no stored list and no tracking metadata anywhere.
6. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).

**Advance:** GUARD.

---

## State: GUARD

**Readiness gate (class-1 contract, feature-002 §3b).** Only applies when a seed was
found in INTAKE.

- **Seed present, unresolved questions, no override** → refuse. Name each unresolved
  question **and** the override flag the user must supply to bypass the gate. Write
  nothing; leave seed and destination byte-identical. Set `lifecycle:
  Paused-Awaiting-Input`.
- **No seed present** → advance (gate does not apply).
- **Seed present, no unresolved questions, or override supplied** → advance.

**Advance:** UPDATE.

---

## State: UPDATE

Dispatch **`aid-architect`** (clean context, tiered) to revise the document. Apply
the **byte-range write discipline** (§4, feature-003): read the whole `roadmap.md` file,
modify only the bytes in the owned region (everything except the `## MVP` byte range and
`## Contents`), and write the file back with every byte outside the owned region
**byte-identical** -- no reformatting, no whitespace change, no re-ordering.

**Owned region** -- the horizon sections and their entries:
- `## Now` and its `### <Direction>` entries
- `## Next` and its `### <Direction>` entries
- `## Later` and its `### <Direction>` entries
- The preamble paragraph (above `## Contents`)

**Never touches:**
- `## MVP` and everything inside it -- that byte range belongs entirely to
  `/aid-update-mvp`.
- `## Contents` -- the index belongs to `/aid-create-roadmap`'s creation path; the
  `- [MVP](#mvp)` entry is left in place whether or not `## MVP` exists.

**Artifact-specific duties:**
- **Add** a new direction entry in the appropriate horizon section in `### <Direction>`
  shape (`feature-003 §3a`).
- **Revise** an existing entry's `What`, `Why`, `Rejected`, or `Status` fields in place.
- **Supersede** an entry: set its `Status` to `Superseded by <entry>` with a durable
  evidence anchor; add the superseding entry in the appropriate section.
- **Move** an entry between horizon sections by deleting it from the source section and
  inserting it in the target section -- byte-identical content, new position only.

**Seed handling (CC-3).** If a seed was read in INTAKE: use it as input to the revision;
**delete it** after the update is written. If no seed was present: no file to delete.

**User-named outputs.** For each output the user named in INTAKE: update it alongside
`roadmap.md` in this same dispatch.

**Advance:** VERIFY.

---

## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to UPDATE; the circuit-breaker there governs escalation
to IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** PRESENT.

---

## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the revised document clearly. Assert:

- `## MVP` content is byte-identical to what it was before this run (or still absent if
  it was absent).
- The `- [MVP](#mvp)` index entry in `## Contents` is present and unchanged.
- If a seed was consumed: `.aid/design/roadmap.md` no longer exists.
- No tracking metadata was written to any output.
- To revise the MVP section, use `/aid-update-mvp`.

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.

---

## Constraints

- **Never touches `## MVP`** -- that byte range belongs to `/aid-update-mvp`
  (`feature-003 §4`).
- **Leaves `## Contents` intact** -- including the `- [MVP](#mvp)` entry, present whether
  or not the section exists (`feature-003 §3c`).
- **Absent destination routes to `/aid-create-roadmap`** -- names it, writes nothing
  (`feature-003 §6c`, REQUIREMENTS CC-5).
- **Byte-range write discipline**: read the whole file, replace only the owned region,
  write back with every other region byte-identical -- never regenerate the document.
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
