---
name: aid-update-backlog
description: >
  Revise backlog.md -- re-prioritize items, add new items, and promote accepted tech-debt.md
  rows into backlog.md (deleted from tech-debt.md in the same run). Use this skill when the
  backlog already exists and items need adding, re-grouping, or retiring. Keeps ## Next
  Release in step with what is actually committed. Reads and consumes a backlog seed when
  one is present in `.aid/design/`; never requires one. Asks every run which previously
  created outputs to update alongside it -- no stored list, no tracking metadata written.
  When backlog.md is absent, routes to `/aid-create-backlog` without writing anything.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "[<change>] -- what to revise (items to add, re-prioritize, promote, or move)"
---

# Update Backlog (revise backlog.md)

`/aid-update-backlog` revises `.aid/knowledge/backlog.md`. It is an `update`-stage skill
under the shared contract in `.aid/runtime/templates/design-lifecycle.md` (class 1),
reading and consuming a seed from `.aid/design/backlog.md` when one is present, and never
requiring one.

- **Boundary vs `/aid-create-backlog`:** that skill creates `backlog.md` on first use.
  When `backlog.md` is absent this skill routes to `/aid-create-backlog`, names it
  explicitly, and writes nothing.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.

State machine: **INTAKE -> GUARD -> UPDATE -> VERIFY -> PRESENT -> DONE**.

Talking with the user: follow `.aid/runtime/templates/question-protocol.md`.

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

Every question this step asks (the opening and the derived-outputs question) is asked before the work exists, so each is recorded in a design document, as the gate's "Recording the questions asked before a work exists" says (`.aid/runtime/templates/work-initiation-gate.md`): `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --design <file> --category <category> --impact <High|Medium|Low> --context '<the question, as shown>' --suggested '<your recommendation>' --asked-by aid-update-backlog` before it is shown (it prints the question's id), then `--answer --design <file> --id <the printed id> --state Answered|Skipped|Assumed --value '<the reply>'` after the reply. `<file>` is `.aid/design/backlog.md` when that seed exists, otherwise `.aid/design/untitled-<YYYYMMDD-HHMMSS>.md`, stamped at the first question and reused for the whole run. A question recorded in the seed leaves the rest of the seed untouched.

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What would
   you like to revise in the backlog -- items to add, re-prioritize, promote from
   tech-debt.md, or move between sections?") and wait.
2. **Read the destination** at `.aid/knowledge/backlog.md`. If absent, **route**: allocate nothing and
   write nothing, name `/aid-create-backlog` explicitly in the response, and end the run.
3. **Read the seed** at `.aid/design/backlog.md` if one exists. Note its presence or
   absence; do not require it.
4. **Read `tech-debt.md`** at `.aid/knowledge/tech-debt.md` if it exists. The seed or the
   user may name candidate rows to promote; know their current state before the confirm
   gate runs.
5. **Ask the derived-outputs question** -- every run, unconditionally: "Which previously
   created outputs should be updated alongside backlog.md?" Wait for the user's answer
   before proceeding. Write no stored list and no tracking metadata anywhere.
6. **Classify complexity (model + effort)** for the `aid-architect` dispatch below;
   verifier tier >= producer tier (`agent-dispatch-tiering.md`).
7. **Allocate** once the destination is present, so a route leaves no work behind, exactly per
   `design-lifecycle.md § Skill shape -- Allocation`: the Work Initiation Gate, with
   `initiator: aid-update-backlog`, `--path lite` and the saved step `GUARD` (INTAKE runs before the
   record and saves nothing), and `--seed .aid/design/backlog.md` on the gate's `--create` when that seed exists, or `--seed` the untitled design document when INTAKE recorded its questions there instead (the gate adds it to the work's `sources:` and copies its `## Questions` into the work's record). `phase` is not driven.

Every `--step` call after the allocation passes in its `--detail` the subject, whether a seed was found, the
derived outputs the user named and the complexity tier, so a resume finds them in the record.

**Advance:** CHAIN → [State: GUARD]; HALT when the destination is absent.

---

## State: GUARD

**Readiness gate (class-1 contract, feature-002 §3b).** Only applies when a seed was
found in INTAKE.

- **Seed present, unresolved questions, no override** → refuse. Name each unresolved
  question **and** the override flag `--override-open-questions` the user must supply to bypass the gate. Write
  nothing; leave seed and destination byte-identical. Set `lifecycle` to `Paused-Awaiting-Input` through the writer.
- **No seed present** → advance (gate does not apply).
- **Seed present, no unresolved questions, or override supplied** → advance.

The run ends at a refusal, with the work paused at this step: set the lifecycle to `Paused-Awaiting-Input` and the pause reason (the refusal, in one line) through the writer (`--pipeline --field Lifecycle` and `--field "Pause Reason"`). A resume sets the lifecycle back to `Running`, runs GUARD again and re-reads the seed.

**Advance:** CHAIN → [State: UPDATE] when no seed was found, it has no unresolved question, or the override is supplied; HALT when the guard refuses.

---

## State: UPDATE

**Before the first edit,** copy every file this step will edit or delete (the destination, each output the user
named in INTAKE, a consumed seed and, for a promotion, `tech-debt.md`) into `rollback/` in the work folder, under the same
relative path, so PRESENT can restore them if the user declines. Copy only once: when UPDATE runs
again (after VERIFY or a requested change), a file already under `rollback/` is kept, so a decline restores
the original, not an earlier revision.

Dispatch **`aid-architect`** (clean context, tiered) to revise the document.

**Artifact-specific duties:**

- **Re-prioritize** existing items by moving rows between sections or changing their
  `Priority` field within a section.
- **Add a new item** -- born in the backlog, so mint an `ID` in whatever form the
  project's own `tech-debt.md` inventory already uses, taking the next unused ordinal;
  never reuse a retired id. Fill all seven columns.
- **Promote `tech-debt.md` rows** via the confirm gate below.
- **Move items** between `## Next Release` and `## Prioritized` -- moving an item into
  `## Next Release` is a commitment; moving it out un-commits it.
- **Keep `## Next Release` in step** with what is actually committed -- no item should sit
  there unless the current tag will include it.

**Promotion pass.** For each candidate row the seed proposes or the user names from
`tech-debt.md`:

1. Present a **per-item confirm gate** showing the source row and the proposed column
   mapping (see the two arms below). Always propose a `Tag` default; never write an empty
   `Tag`.
2. If the user confirms: add the fully-populated row (all seven columns) to the
   appropriate section in `backlog.md`. Delete the source row from `tech-debt.md` in the
   **same run**, keyed on the `ID` column -- a whole-row deletion, never a rewrite of any
   other row and never a change to the file's prose.
3. If the user declines: leave the row in `tech-debt.md` untouched.

**There are two and only two column-mapping arms; both are binding; neither is exempt from
any of the seven columns.**

**Arm 1 -- `tech-debt.md` promotion.** Applies when the source is an inventory row:

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

**Arm 2 -- release-note bullet.** Applies when the source is an already-built item from
`release-tracking.md`'s `## Unreleased` section:

| Source | `backlog.md` column | Rule |
|---|---|---|
| -- | `ID` | **Minted** in whatever form the project's own `tech-debt.md` inventory already uses, taking the next unused ordinal; never reuses a retired id |
| The bullet's `[NEW]` / `[CHANGE]` / `[FIX]` marker | `Tag` | Carried verbatim; the drain re-tags nothing |
| The bullet's leading feature name, or its first clause | `Title` | One noun phrase |
| The bullet's own text | `Definition & done-condition` | Done-condition read as **shipped, pending tag** |
| The durable anchor the bullet already names | `Location` | Path plus a grep-recoverable symbol or heading, **never `path:LINE`** |
| -- | `Risk if not done` | **ships untagged / absent from the next release notes** |
| -- | `Priority` | **`P1`** -- the `## Next Release` slice is the committed slice by definition |

**Item schema** -- one ID-keyed table per item section (`feature-003 §3b`):

    | ID | Tag | Title | Definition & done-condition | Location | Risk if not done | Priority |
    |----|-----|-------|----------------------------|----------|-----------------|----------|

All seven columns are required on every row, from both arms.

**Seed handling (CC-3).** If a seed was read in INTAKE: use it as input to the revision;
**delete it** after the update is written. If no seed was present: no file to delete.

**User-named outputs.** For each output the user named in INTAKE: update it alongside
`backlog.md` in this same dispatch.

**Advance:** CHAIN → [State: VERIFY].

---

## State: VERIFY

**Full verify** -- exactly as `design-lifecycle.md § Skill shape -- "Full verify"`
defines it. Not clean -> loop to UPDATE; the circuit-breaker there governs escalation
to IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: UPDATE] when it is not clean and fewer than 3 cycles have run; HALT when the circuit-breaker has blocked the work.

---

## State: PRESENT (hard stop -- the user decides)

Present the revised document clearly. Assert:

- Every promoted row was deleted from `tech-debt.md` in this run.
- No item exists in both `backlog.md` and `tech-debt.md` simultaneously.
- `## Next Release` reflects the committed slice.
- If a seed was consumed: `.aid/design/backlog.md` no longer exists.
- No tracking metadata was written to any output.
- To create a backlog for the first time, use `/aid-create-backlog`.

Then ask the approval question: keep this revision, change it, or decline it. It is an approval under
`.aid/runtime/templates/question-protocol.md`: record it with `--ask` (category `Approval`, `covers` the revision), set
`lifecycle` to `Paused-Awaiting-Input` and the pause reason through the writer, and ask. The question pauses this step
where it stands and cannot be skipped. Once it is answered, record the answer with `--answer` and set `lifecycle` back to
`Running` through the writer (`skill-steps.md` part 3). Then:

- **Approve:** the revision stays as written.
- **Change:** the changes the user asks for go into the step detail, and UPDATE applies them; the verify runs again.
- **Decline:** copy every file saved under `rollback/` back to its place (a consumed seed included), so the Knowledge
  Base is as it was before this run and nothing lands.

**Advance:** CHAIN → [State: DONE] when the user approves; CHAIN → [State: DONE] when the user declines (the revision is rolled back first); CHAIN → [State: UPDATE] when the user asks for changes.

---

## State: DONE

Set `lifecycle` to `Completed` through the writer (`--pipeline --field Lifecycle --value Completed`), which also clears the saved skill and step.

**Advance:** HALT.

---

## Constraints

- **Absent destination routes to `/aid-create-backlog`** -- names it, writes nothing
  (`feature-003 §6c`).
- **`phase` is not driven** by this skill (`design-lifecycle.md § Skill shape --
  Allocation`).
- **Full verify**, per `design-lifecycle.md`, unlike a light single-pass check.
- **Seed consumed when present, never required** (CC-3). If a seed was read: delete it
  after the update is written. If no seed: proceed without one.
- **Derived-outputs question asked every run, unconditionally** -- no stored list, no
  tracking metadata written (FR-8, feature-002 §3d).
- **C-3 compliance**: `backlog.md` carries no `## Change Log`, no `## Revision History`,
  no `changelog:` frontmatter field, no work id, and no work-folder path.
- **Move not copy**: the promoted row is deleted from `tech-debt.md` in the same run that
  adds it to `backlog.md`; an item may not exist in both documents simultaneously.
- **`Location` is always a durable anchor** -- path plus a grep-recoverable symbol or
  heading, never the bare `path:LINE` form (`kb-citation-lint.sh` exits 1 on it).
- **No empty `Tag`**: where `Type` does not determine the value, ask at the confirm gate.
- **ID is never re-minted, never reused, never renumbered** -- the id space is shared with
  `tech-debt.md` and V18's `comm` oracle depends on it.
- **Both column-mapping arms are binding** (tech-debt.md promotion and release-note
  bullet); neither is exempt from any of the seven columns.
- **Clean context**; **verification always a sub-agent dispatch** (`aid-reviewer`).
- **Tracking:** set the lifecycle through the writer (`--pipeline --field Lifecycle`) at every transition.
