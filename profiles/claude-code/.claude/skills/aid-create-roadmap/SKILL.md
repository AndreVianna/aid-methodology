---
name: aid-create-roadmap
description: >
  Realize a ready roadmap seed into `.aid/knowledge/roadmap.md` -- frontmatter, preamble, ##
  Contents index (including the forward ## MVP entry), and the three horizon sections ##
  Now, ## Next, ## Later. Use this skill when a roadmap seed is ready and the project needs
  its roadmap document written for the first time. Registers the document in
  `.aid/settings.yml` and `.aid/knowledge/README.md` on first creation. Routes to
  `/aid-update-roadmap` when the horizon sections already carry committed content. The ##
  MVP section belongs entirely to `/aid-create-mvp` -- this skill writes only its ##
  Contents index entry.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[<direction>] -- what to realize (fills horizon sections from the seed)"
---

# Create Roadmap (realize a seed into roadmap.md)

`/aid-create-roadmap` realizes a ready roadmap seed at `.aid/design/roadmap.md`
into the committed KB document at `.aid/knowledge/roadmap.md`. It is a `create`-stage
skill under the shared contract in `.claude/aid/templates/design-lifecycle.md` (class 1),
consuming the seed `/aid-design-roadmap` produces and never touching `.aid/design/` for any
other purpose.

- **Boundary vs `/aid-create-mvp`:** this skill creates `roadmap.md` and owns every
  section **except** `## MVP`. It writes the `- [MVP](#mvp)` index entry in `## Contents`
  from the moment the document exists, but it never creates a `## MVP` heading -- that
  section belongs entirely to `/aid-create-mvp` (`feature-003 §3c`).
- **Boundary vs `/aid-update-roadmap`:** that skill revises existing horizon entries. When
  the owned region already carries committed content this skill routes to it rather than
  overwriting it.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> GUARD -> REALIZE -> REGISTER -> VERIFY -> PRESENT -> DONE**.
Print the `[State: NAME] -- {purpose}` entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What direction
   do you want to realize into roadmap.md -- or run `/aid-design-roadmap` first?") and wait.
2. **Allocate, exactly per `design-lifecycle.md § Skill shape -- Allocation`** -- the Work
   Initiation Gate, then `initiator: aid-create-roadmap`, `active_skill:
   aid-create-roadmap`, `pipeline.path: lite`, `lifecycle: Running`. `phase` is not
   driven.
3. **Read the seed** at `.aid/design/roadmap.md`. If no seed exists, inform the user and
   ask whether to proceed without one (direction entered interactively) or to run
   `/aid-design-roadmap` first; do not proceed silently.
4. **Read the destination** at `.aid/knowledge/roadmap.md` if it exists. Classify its state:
   absent | present-horizon-empty | present-horizon-populated.
5. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).

**Advance:** GUARD.

---

## State: GUARD

**Readiness gate (class-1 contract, feature-002 §3b).** Inspect the seed for a non-empty
`## Open questions` section per `design-lifecycle.md`'s detection rule.

- **Unresolved questions present, no override** → refuse. Name each unresolved question
  **and** the override flag `--override-open-questions` the user must supply to bypass the gate. Write nothing; leave
  seed and destination byte-identical. Set `lifecycle: Paused-Awaiting-Input`.
- **No unresolved questions, or override supplied** → advance.

**Advance:** REALIZE.

---

## State: REALIZE

Dispatch **`aid-architect`** (clean context, tiered) to realize the seed. Apply the case
determined in INTAKE:

| Destination state | Action |
|---|---|
| `roadmap.md` absent | **Create** the document: write frontmatter (§3a values below, verbatim), `# Roadmap` title, one-paragraph preamble (what this document holds and what it does not -- no items live here), `## Contents` with all four entries in heading order, then `## Now`, `## Next`, `## Later`. **Delete the seed.** |
| Present, horizon sections empty or absent | Fill `## Now`, `## Next`, `## Later` from the seed; leave every byte outside those sections identical, including `## MVP` if present. **Delete the seed.** |
| Present, horizon sections already carry committed content | **Route** to `/aid-update-roadmap`; write nothing; leave the seed in place for that run (CC-3). Set `lifecycle: Paused-Awaiting-Input`. Advance to DONE without calling REGISTER or VERIFY. |

**`## Contents` index** -- the fixed four-entry form (`feature-003 §3a`), always written
at creation and always left intact on the fill path:

    - [MVP](#mvp)
    - [Now](#now)
    - [Next](#next)
    - [Later](#later)

**Never creates `## MVP`.** The `- [MVP](#mvp)` entry is a forward reference: the dead
in-document anchor is accepted and is what makes REQUIREMENTS AC-6a literally true.

**Entry schema** for each direction in a horizon section:

    ### <Direction, as a noun phrase>

    - **What:** the direction committed to, at roadmap altitude.
    - **Why:** the constraint or trade-off that drove it.
    - **Rejected:** each alternative considered, with the reason it lost.
    - **Status:** Accepted | Superseded by <entry> -- followed by a durable evidence
      anchor (path plus a grep-recoverable heading or search string), or the literal
      `intent` when nothing has been built yet.

**No summary table. No item ids anywhere.** (`feature-003 §3a`)

**Frontmatter** (write verbatim on creation; `feature-003 §3a`):

```yaml
---
kb-category: primary
source: hand-authored
objective: Present commitment and future direction for {project} — what it has decided to do next, why, and what it deliberately did not choose.
summary: Read this to know where the project is going and what the first committed slice is; specific defined-and-prioritized items live in backlog.md and shipped work in release-tracking.md.
sources: []
tags: [D, roadmap, commitment, direction, mvp]
see_also: [backlog.md, decisions.md, release-tracking.md]
owner: architect
audience: [architect, pm, developer]
---
```

`source: hand-authored` -- no as-built counterpart exists for the Conformance Lane to
compare a direction entry against (`decisions.md` carries the same value for the same
reason; `feature-003 §3a` records the divergence from feature-004's `forward-authored`).

**Advance:** REGISTER (creation or fill path). Route path: advance to DONE directly.

---

## State: REGISTER

**On creation only** (destination was absent in INTAKE). Write two surfaces atomically
in the same run, per `feature-003 §6b` (REQUIREMENTS CC-1, CC-2):

1. **`.aid/settings.yml` `knowledge.doc_set`** -- append exactly one line:
   `    - roadmap.md|skill-self|required`
   using the R13 append-block idiom (append to the existing `doc_set:` list; never rewrite
   the block; never touch `term_exclusions`).
2. **`.aid/knowledge/README.md` Completeness table** -- append exactly one row:
   `Concern` = `D`, `Owner` = `skill-self`, `Status` = `Created (skill-self)`;
   and increment the `**Doc-set:** N documents` count line by 1.

Both writes must succeed in the same run. If either fails, report and halt.

**Advance:** VERIFY.

---

## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to REALIZE; the circuit-breaker there governs escalation
to IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** PRESENT.

---

## State: PRESENT (hard stop -- the user decides)

Set `lifecycle: Paused-Awaiting-Input`. Present the realized document clearly. Assert:

- `## MVP` heading is absent (the `- [MVP](#mvp)` index entry is present).
- On the creation path: both registration surfaces were written.
- To revise horizon entries later, use `/aid-update-roadmap`.
- To draw the MVP line, use `/aid-create-mvp`.

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.

---

## Constraints

- **Never creates `## MVP`** -- only the `## Contents` index entry (`feature-003 §3c`).
- **`phase` is not driven** by this skill (`design-lifecycle.md § Skill shape --
  Allocation`).
- **Full verify**, per `design-lifecycle.md`, unlike a light single-pass check.
- **Seed consumed on the realizing path** (creation or fill); left in place only on
  the route path (CC-3).
- **Registration is atomic with creation** -- both surfaces in the same run (CC-2);
  presence value is `required`, never `conditional` (CC-1).
- **C-3 compliance**: `roadmap.md` carries no `## Change Log`, no `## Revision History`,
  no `changelog:` frontmatter field, no work id, and no work-folder path.
- **Clean context**; **verification always a sub-agent dispatch** (`aid-reviewer`).
- **Tracking:** write STATE `lifecycle` at every transition.
