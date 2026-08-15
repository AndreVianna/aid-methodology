---
name: aid-create-backlog
description: >
  Realize a ready backlog seed into `.aid/knowledge/backlog.md` -- frontmatter, preamble, ##
  Contents index, ## Next Release, ## Prioritized, and ## Gotchas. Use this skill when a
  backlog seed is ready and the project needs its backlog document written for the first
  time. Moves accepted tech-debt.md items into backlog.md in the same run (id unchanged; row
  deleted from tech-debt.md). Registers the document in `.aid/settings.yml` and
  `.aid/knowledge/README.md` on first creation. Routes to `/aid-update-backlog` when the
  item sections already carry committed content.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[<direction>] -- which items to accept and how to prioritize them (fills item sections from the seed)"
---

# Create Backlog (realize a seed into backlog.md)

`/aid-create-backlog` realizes a ready backlog seed at `.aid/design/backlog.md`
into the committed KB document at `.aid/knowledge/backlog.md`. It is a `create`-stage
skill under the shared contract in `canonical/aid/templates/design-lifecycle.md` (class 1),
consuming the seed `/aid-design-backlog` produces and never touching `.aid/design/` for any
other purpose.

- **Boundary vs `/aid-update-backlog`:** that skill revises existing item entries. When
  the item sections already carry committed content this skill routes to it rather than
  overwriting them.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> GUARD -> REALIZE -> REGISTER -> VERIFY -> PRESENT -> DONE**.
Print the `[State: NAME] -- {purpose}` entry line on each state.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What items do
   you want to accept into the backlog -- or run `/aid-design-backlog` first?") and wait.
2. **Allocate, exactly per `design-lifecycle.md § Skill shape -- Allocation`** -- the Work
   Initiation Gate, then `initiator: aid-create-backlog`, `active_skill:
   aid-create-backlog`, `pipeline.path: lite`, `lifecycle: Running`. `phase` is not
   driven.
3. **Read the seed** at `.aid/design/backlog.md`. If no seed exists, inform the user and
   ask whether to proceed without one (items entered interactively) or to run
   `/aid-design-backlog` first; do not proceed silently.
4. **Read the destination** at `.aid/knowledge/backlog.md` if it exists. Classify its
   state: absent | present-sections-empty | present-sections-populated.
5. **Read `tech-debt.md`** at `.aid/knowledge/tech-debt.md` if it exists. The seed may
   name candidate rows to promote; know their current state before the confirm gate runs.
6. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
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
| `backlog.md` absent | **Create** the document: write frontmatter (§3b values below, verbatim), `# Backlog` title, one-paragraph preamble (what this document holds and the promotion criterion -- an item moves here when it is **accepted into the plan**, an explicit human decision at a per-item confirm gate), `## Contents` with all three entries in heading order, then `## Next Release`, `## Prioritized`, `## Gotchas`. Then run the **promotion pass** below. **Delete the seed.** |
| Present, item sections empty or absent | Fill `## Next Release`, `## Prioritized`, `## Gotchas` from the seed; leave every byte outside those sections identical. Then run the **promotion pass**. **Delete the seed.** |
| Present, item sections already carry committed content | **Route** to `/aid-update-backlog`; write nothing; leave the seed in place for that run (CC-3). Set `lifecycle: Paused-Awaiting-Input`. Advance to DONE without calling REGISTER or VERIFY. |

**`## Contents` index** -- the fixed three-entry form (`feature-003 §3b`), always written
at creation and always left intact on the fill path:

    - [Next Release](#next-release)
    - [Prioritized](#prioritized)
    - [Gotchas](#gotchas)

**Promotion pass.** For each item the seed proposes as a candidate for promotion from
`tech-debt.md`:

1. Present a **per-item confirm gate** showing the source row and the proposed column
   mapping (see the two arms below). Always propose a `Tag` default; never write an empty
   `Tag`.
2. If the user confirms: add the fully-populated row (all seven columns) to the appropriate
   section in `backlog.md`. Delete the source row from `tech-debt.md` in the **same run**,
   keyed on the `ID` column — a whole-row deletion, never a rewrite of any other row and
   never a change to the file's prose.
3. If the user declines: leave the row in `tech-debt.md` untouched.

**There are two and only two column-mapping arms; both are binding; neither is exempt from
any of the seven columns.**

**Arm 1 — `tech-debt.md` promotion.** Applies when the source is an inventory row:

| `tech-debt.md` column | `backlog.md` column | Rule |
|---|---|---|
| `ID` | `ID` | Carried **unchanged** -- never re-minted |
| `Description` | `Definition & done-condition` | Full text |
| `Location` | `Location` | Durable anchor -- path plus a grep-recoverable symbol or heading, **never `path:LINE`** |
| `Risk` | `Risk if not done` | Full text |
| `Priority` | `Priority` | `P1` / `P2` / `P3` unchanged |
| `Type` | **consumed, not carried** | Read to seed `Tag`'s default; dropped as a column. A defect Type seeds `[FIX]`; a gap/absent-capability Type seeds `[NEW]`; an alteration Type seeds `[CHANGE]`. Where the project's `Type` vocabulary leaves the tag undetermined, **ask** at the same confirm gate |
| `Effort` | **dropped** | Scheduling estimate; does not cross |
| -- | `Tag` | Seeded from `Type` by the rule above; confirmed at the gate; **never left empty** |
| -- | `Title` | One noun phrase; the key the release drain matches on |

**Arm 2 — release-note bullet.** Applies when the source is an already-built item from
`release-tracking.md`'s `## Unreleased` section (a one-off migration of a pre-existing
`## Unreleased` section into the backlog):

| Source | `backlog.md` column | Rule |
|---|---|---|
| -- | `ID` | **Minted** in whatever form the project's own `tech-debt.md` inventory already uses, taking the next unused ordinal; never reuses a retired id |
| The bullet's `[NEW]` / `[CHANGE]` / `[FIX]` marker | `Tag` | Carried verbatim; the drain re-tags nothing |
| The bullet's leading feature name, or its first clause | `Title` | One noun phrase |
| The bullet's own text | `Definition & done-condition` | Done-condition read as **shipped, pending tag** |
| The durable anchor the bullet already names | `Location` | Path plus a grep-recoverable symbol or heading, **never `path:LINE`** |
| -- | `Risk if not done` | **ships untagged / absent from the next release notes** |
| -- | `Priority` | **`P1`** -- the `## Next Release` slice is the committed slice by definition |

**Item schema** -- one ID-keyed table per item section, modeled on `tech-debt.md`'s
inventory (`feature-003 §3b`):

    | ID | Tag | Title | Definition & done-condition | Location | Risk if not done | Priority |
    |----|-----|-------|----------------------------|----------|-----------------|----------|

All seven columns are required on every row, from both arms. A row with a blank cell in
any column is not complete and must not be written.

**`## Gotchas`** -- required by C7 ownership; real operational-guidance content:

- **ID is inherited on promotion, never re-minted.** The `comm -12` duplicate-item oracle
  (V18) keys on the id; re-minting a promoted id makes the check compare unlike things and
  breaks the move audit entirely.
- **Parking an item in `## Next Release` is a commitment.** That section is drained at
  tag time by `release-aid`; every row there becomes a tagged release-note bullet in
  `release-tracking.md` and is deleted from `backlog.md` in the same run. Do not park
  an item there unless the current tag will include it.
- **An item is moved, never copied.** The promoted row is deleted from `tech-debt.md` in
  the same run that adds it to `backlog.md`. An item present in both documents is a
  checkable defect.

**Frontmatter** (write verbatim on creation; `feature-003 §3b`):

```yaml
---
kb-category: primary
source: hand-authored
objective: Defined and prioritized work items for {project} that have not shipped — the slice committed to the next release and the prioritized remainder.
summary: Read this to see what is accepted into the plan but not yet shipped; raw unscheduled observations live in tech-debt.md and shipped work in release-tracking.md.
sources: []
tags: [C7, backlog, prioritization, items, planning]
see_also: [tech-debt.md, release-tracking.md, roadmap.md]
owner: architect
audience: [developer, architect, pm]
---
```

**Advance:** REGISTER (creation or fill path). Route path: advance to DONE directly.

---

## State: REGISTER

**On creation only** (destination was absent in INTAKE). Write two surfaces atomically
in the same run, per `feature-003 §6b` (REQUIREMENTS CC-1, CC-2):

1. **`.aid/settings.yml` `knowledge.doc_set`** -- append exactly one line:
   `    - backlog.md|skill-self|required`
   using the R13 append-block idiom (append to the existing `doc_set:` list; never rewrite
   the block; never touch `term_exclusions`).
2. **`.aid/knowledge/README.md` Completeness table** -- append exactly one row:
   `Concern` = `C7`, `Owner` = `skill-self`, `Status` = `Created (skill-self)`;
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

- On the creation path: both registration surfaces were written.
- `## Gotchas` is present and carries real content.
- Every promoted row was deleted from `tech-debt.md` in this run.
- To revise items later, use `/aid-update-backlog`.

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.

---

## Constraints

- **`phase` is not driven** by this skill (`design-lifecycle.md § Skill shape --
  Allocation`).
- **Full verify**, per `design-lifecycle.md`, unlike a light single-pass check.
- **Seed consumed on the realizing path** (creation or fill); left in place only on
  the route path (CC-3).
- **Registration is atomic with creation** -- both surfaces in the same run (CC-2);
  presence value is `required`, never `conditional` (CC-1).
- **C-3 compliance**: `backlog.md` carries no `## Change Log`, no `## Revision History`,
  no `changelog:` frontmatter field, no work id, and no work-folder path.
- **Clean context**; **verification always a sub-agent dispatch** (`aid-reviewer`).
- **Tracking:** write STATE `lifecycle` at every transition.
- **Move not copy**: the promoted row is deleted from `tech-debt.md` in the same run that
  adds it to `backlog.md`; an item may not exist in both documents simultaneously.
- **`Location` is always a durable anchor** -- path plus a grep-recoverable symbol or
  heading, never the bare `path:LINE` form (`kb-citation-lint.sh` exits 1 on it).
- **No empty `Tag`**: where `Type` does not determine the value, ask at the confirm gate.
- **ID is never re-minted, never reused, never renumbered** -- the id space is shared with
  `tech-debt.md` and V18's `comm` oracle depends on it.
- **Both column-mapping arms are binding** (tech-debt.md promotion and release-note
  bullet); neither is exempt from any of the seven columns.
