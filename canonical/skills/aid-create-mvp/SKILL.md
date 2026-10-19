---
name: aid-create-mvp
description: >
  Realize a ready MVP seed into roadmap.md's ## MVP section only -- the first shippable
  slice: what it includes, why the line falls there, what was cut, and its current status.
  Use this skill when an MVP seed is ready and the roadmap's MVP section has not been
  written yet. The roadmap document itself is `/aid-create-roadmap`'s to create; when
  roadmap.md is absent this skill routes to `/aid-create-roadmap` without writing anything
  and leaves the seed in place. Routes to `/aid-update-mvp` when ## MVP already carries
  committed content. Writes no document and no registration entry -- it owns a section, not
  a file.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "[<slice>] -- what to realize into the ## MVP section (fills the section from the seed)"
---

# Create MVP (realize a seed into roadmap.md's ## MVP section)

`/aid-create-mvp` realizes a ready MVP seed at `.aid/design/mvp.md` into the
`## MVP` section of `.aid/knowledge/roadmap.md`. It is a `create`-stage skill
under the shared contract in `.aid/runtime/templates/design-lifecycle.md` (class 1),
consuming the seed `/aid-design-mvp` produces and never touching `.aid/design/` for
any other purpose.

- **Boundary vs `/aid-create-roadmap`:** this skill owns the `## MVP` section only;
  the roadmap document itself — its frontmatter, preamble, `## Contents` index, and the
  three horizon sections — belongs entirely to `/aid-create-roadmap`. When `roadmap.md`
  is absent this skill routes to `/aid-create-roadmap` and creates nothing (`feature-003
  §3c`; REQUIREMENTS CC-5).
- **Boundary vs `/aid-update-mvp`:** that skill revises an existing `## MVP` section.
  When the owned region already carries committed content this skill routes to it rather
  than overwriting it.
- **No document ownership, no registration.** This skill realizes a section of an
  existing document, not a document of its own. It never writes a `.aid/settings.yml`
  `knowledge.doc_set` entry and never writes a `.aid/knowledge/README.md` Completeness
  row (REQUIREMENTS CC-5; `feature-003 §1` destinations table).
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> GUARD -> REALIZE -> VERIFY -> PRESENT -> DONE**.
Print the `[State: NAME] -- {purpose}` entry line on each state.

---

## State Detection

Steps move and record by `.aid/runtime/templates/skill-steps.md` (the step entry, the advance words and the
work record); this skill restates none of them.

**Detection shapes the entry step and validates a saved step, and never routes.** A fresh start on a work
runs INTAKE's reads to decide how far the entry step goes. On resume the saved step is checked against what
is on disk, and a mismatch goes to recovery, never to a silent re-route. Which skill and which step a work
continues at come only from its work record.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What
   belongs in the first shippable slice, and where does the line fall -- or run
   `/aid-design-mvp` first?") and wait.
2. **Allocate, exactly per `design-lifecycle.md § Skill shape -- Allocation`** -- the Work Initiation Gate, whose `--create` is given `--skill aid-create-mvp`, `--step INTAKE` and `--path lite`; the record starts `Running`. `phase` is not driven.
3. **Read the seed** at `.aid/design/mvp.md`. If no seed exists, inform the user and
   ask whether to proceed without one (slice entered interactively) or to run
   `/aid-design-mvp` first; do not proceed silently. The question blocks the work: pause INTAKE on it, with its detail saying the work is allocated and the question is open, record it with `--ask`, set the lifecycle to `Paused-Awaiting-Input`, and then ask it. Once it is answered, INTAKE continues at step 4.
4. **Read the destination** at `.aid/knowledge/roadmap.md` if it exists. Classify its
   state: absent | present-MVP-absent | present-MVP-populated.
5. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).

**Advance:** CHAIN -> [State: GUARD].

---

## State: GUARD

**Readiness gate (class-1 contract, feature-002 §3b).** Inspect the seed for a
non-empty `## Open questions` section per `design-lifecycle.md`'s detection rule.

- **Unresolved questions present, no override** → refuse. Name each unresolved
  question **and** the override flag `--override-open-questions` the user must supply to bypass the gate. Write
  nothing; leave seed and destination byte-identical. Set the lifecycle to `Paused-Awaiting-Input` through the writer, and stop: this step stays saved, and a later run inspects the seed again from the top.
- **No unresolved questions, or override supplied** → advance.

**Advance:** CHAIN -> [State: REALIZE] when no question is unresolved or the override is supplied; HALT when a question is unresolved and no override is supplied (the refusal above).

---

## State: REALIZE

Dispatch **`aid-architect`** (clean context, tiered) to realize the seed. Apply the
case determined in INTAKE:

| Destination state | Action |
|---|---|
| `roadmap.md` absent | **Route** to `/aid-create-roadmap` -- an MVP is a section of a roadmap, not a document (REQUIREMENTS CC-5; feature-002 §3c *first-write rule*). Name `/aid-create-roadmap` explicitly in the response. Write nothing. Leave `.aid/design/mvp.md` in place for that run (CC-3). Set the lifecycle to `Paused-Awaiting-Input` through the writer. Then ask the user, through the question protocol, whether to run the skill it routes to, naming it; the question is blocking and stays open, and VERIFY is not called. |
| `roadmap.md` present, `## MVP` absent | **Create** the `## MVP` section using the **byte-range write discipline** below. **Delete the seed.** |
| `roadmap.md` present, `## MVP` already carries committed content | **Route** to `/aid-update-mvp`; write nothing; leave the seed in place for that run (CC-3). Set the lifecycle to `Paused-Awaiting-Input` through the writer. Then ask the user, through the question protocol, whether to run the skill it routes to, naming it; the question is blocking and stays open, and VERIFY is not called. |

**Byte-range write discipline (binding; precondition for V7 and V8).** Read the
whole `roadmap.md` file. Identify the `## MVP` byte range: the literal heading
`## MVP`, matched exactly, through to (but not including) the next heading of level 2
or shallower, or EOF if none follows. Replace only that byte range with the new
section content. Write the file back with every byte outside that range
**byte-identical** -- no reformatting, no whitespace change, no re-ordering of any
other region.

**Never edits `## Contents`.** The `## Contents` block is outside the `## MVP` byte
range and belongs to `/aid-create-roadmap` (feature-003 AC-6a). The byte-range write
discipline makes this structurally true: the discipline reads the whole file and
replaces only the owned range, so no byte in `## Contents` is touched.

**Anchor position when creating the section.** Insert `## MVP` immediately after the
`## Contents` block and before `## Now` -- not "before the first other `##`", which
would place the section above the document index and break KB layout order (feature-003
§3c; feature-002 §3c *Position when created*).

**`## MVP` section shape** (`feature-003 §3c`):

    ## MVP

    - **What:** the first shippable slice, itemized.
    - **Why:** why the line falls there.
    - **Rejected:** what was cut from the slice, each with the reason for the cut.
    - **Status:** Not started | In progress | Shipped <version> -- with the evidence
      anchor.

**Advance:** CHAIN -> [State: VERIFY] (creation path); HALT on a route case (the question above stays open and the run ends).

---

## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to REALIZE; the circuit-breaker there governs escalation
to IMPEDIMENT, and the lifecycle is set to `Blocked` through the writer.

**Advance:** CHAIN -> [State: PRESENT].

---

## State: PRESENT (hard stop -- the user decides)

Set the lifecycle to `Paused-Awaiting-Input` through the writer. Present the realized `## MVP` section clearly.
Assert:

- `## Contents` is unchanged -- the `- [MVP](#mvp)` entry is present (written by
  `/aid-create-roadmap`) and no new entry was added.
- No `.aid/settings.yml` `knowledge.doc_set` entry was written and no
  `.aid/knowledge/README.md` Completeness row was written -- this skill creates no
  document.
- Every byte outside the `## MVP` range is identical to what it was before this run.
- To revise the MVP section later, use `/aid-update-mvp`.

**Advance:** ASK -> [State: DONE].

---

## State: DONE

Set the lifecycle to `Completed` through the writer, `updated` now, append a `## Lifecycle History` row.

---

## Constraints

- **Never creates `roadmap.md`** -- the document belongs to `/aid-create-roadmap`
  (REQUIREMENTS CC-5). When `roadmap.md` is absent, routes to `/aid-create-roadmap`,
  names it explicitly, writes nothing, and leaves `.aid/design/mvp.md` in place.
- **Never edits `## Contents`** -- that block belongs to `/aid-create-roadmap`
  (feature-003 AC-6a); the byte-range write discipline structurally prevents it.
- **No registration entry** -- this skill creates no document and therefore writes no
  `.aid/settings.yml` `knowledge.doc_set` entry and no `.aid/knowledge/README.md`
  Completeness row (REQUIREMENTS CC-5).
- **Byte-range write discipline**: read the whole file, replace only the `## MVP`
  range, write back with every other region byte-identical -- never regenerate the
  document.
- **`phase` is not driven** by this skill (`design-lifecycle.md § Skill shape --
  Allocation`).
- **Full verify**, per `design-lifecycle.md`, unlike a light single-pass check.
- **Seed consumed on the creation path** (region created); left in place on both route
  paths (CC-3).
- **C-3 compliance**: writes no `## Change Log`, no `## Revision History`, no
  `changelog:` frontmatter field, no work id, and no work-folder path into
  `roadmap.md`.
- **Clean context**; **verification always a sub-agent dispatch** (`aid-reviewer`).
- **Tracking:** write the STATE lifecycle through the writer at every transition.
