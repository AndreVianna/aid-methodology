---
name: aid-update-document
description: >
  Revise or extend a document that already exists, in one pass. Use this skill when a
  document has drifted from the code, is missing a section, or needs a correction -- and you
  want the change drafted against the current source rather than written from memory. It
  reads the existing document first, then edits it, grounded in and accuracy-checked against
  the Knowledge Base (`.aid/knowledge/`) and the project source. It resolves nothing: it
  drafts the change and shows you a diff, and only after you approve is it written back. It
  never writes into `.aid/knowledge/` -- that is `/aid-update-kb`'s territory.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<document + change> -- which existing document to update, and how"
---

# Update Document (update it now, resolve nothing)

`/aid-update-document` updates an **existing** document -- the sibling of
`/aid-create-document` for edits rather than new authoring.
Same collapse shape, same producer/verifier, same KB boundary; the difference
is it **locates and reads the existing document first**, edits it, and shows a **diff** at
the human gate (overwrite care is central).

- **Boundary vs the KB:** never writes `.aid/knowledge/`; KB edits route to `/aid-update-kb`.
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.
- **Genre structures:** `.aid/runtime/templates/shortcut-scaffolding/document.md`.

State machine: **INTAKE (-> INTAKE-ASK?) -> ALLOCATE -> AUTHOR -> VERIFY (loop) -> PRESENT [human
gate, diff] -> WRITE (on approval) -> DONE**. Print the `[State: NAME] -- {purpose}` entry line on each state.
Steps, hand-offs and the work record follow [`skill-steps.md`](../../aid/templates/skill-steps.md).

---

## State Detection

**Detection shapes the entry step and validates a saved step, and never routes** (`skill-steps.md`, § State Detection). A fresh start enters INTAKE. A resume continues at the step the work record saves, which the gate's § 3b routes to; the saved step's artifact is checked against disk, and a mismatch goes to recovery, never to a silent re-route.

---

## State: INTAKE

INTAKE and INTAKE-ASK run before the work record exists, so they save no steps (`skill-steps.md`, § Before a work exists).

1. **Check the target and the change.** Note whether the argument is empty. Do not ask here.
2. **Locate + read the existing document.** Note whether it resolves; if it does not, INTAKE-ASK
   asks which document is meant (or suggests `/aid-create-document` for a new one).
3. **Pick the path** (fast if the document + change are clear; guided otherwise) and
   **classify complexity** -> `aid-tech-writer` model/effort (sonnet/medium default; opus/high
   for a large rewrite). Verifier tier >= producer.
4. **Check for works.** Run `bash .aid/runtime/scripts/works/enumerate-works.sh`
   (main tree + every git worktree). Note whether any exist. Do not prompt here.
5. **Read the design seed, if present.** If `.aid/design/document.md` exists, read it as
   prior context before drafting; it is an input, never a substitute, and is not modified
   by this run.

**Advance:** CHAIN -> [State: INTAKE-ASK] when any of these holds: the argument is empty, the document does not resolve, the path is guided, works exist; otherwise CHAIN -> [State: ALLOCATE].

---

## State: INTAKE-ASK  (only when a question must be put)

Ask one topic at a time, through the question protocol, in this order and only for what applies:

1. **Empty argument** -> the bootstrapping question ("Which document should I update, and what
   change?"). The answer is the target and the change; the path and complexity are then set from it.
2. **Document does not resolve** -> ask which document is meant, or suggest
   `/aid-create-document` if the user meant a new one. In that case nothing is allocated, and the run
   ends there naming that skill.
3. **Guided path** -> scope the change.
4. **Works exist** -> the gate's new-vs-continuation question with the enumerated list.

**Advance:** CHAIN -> [State: ALLOCATE]; HALT when the user meant a new document (item 2).

---

## State: ALLOCATE

Allocate the work through the gate: the Work Initiation Gate
(`.aid/runtime/templates/work-initiation-gate.md`).

- **New work:** call the gate's `§ 3a` with the user's words, this skill's name
  (`aid-update-document`), its saved step (`AUTHOR`), the step the work continues at once it exists (INTAKE and INTAKE-ASK run before the record and save nothing), and a kebab-case slug from the document.
  The gate's `§ 3a` step 2 creates and enters the worktree
  (`worktree-lifecycle.sh create <work-id> <name>`),
  **then** allocate (`.aid/works/<work-id>-<slug>/`) the work folder and write its record through
  the writer, before it hands back: "`STATE.yml` was created by the gate;
  skip any instruction to write `initiator`, `active_skill`, `lifecycle` or `phase` by hand;
  set other keys through the writer." This skill drives no `phase`.
- **Continuation:** On continuation, follow the gate's § 3b: enter the chosen work's worktree and run the skill its record names, at its saved step.

Every `--step` call in this skill passes in its `--detail` the target document, the change, the path and the
complexity tier, so a resume finds them in the record.

**Advance:** CHAIN -> [State: AUTHOR].

---

## State: AUTHOR

Dispatch **`aid-tech-writer`** (clean context, tiered) to produce the **revised** document
(a draft in the work folder, not yet written back), grounded in and accurate to the KB +
project source, preserving the document's existing genre structure.

**Advance:** CHAIN -> [State: VERIFY].

---

## State: VERIFY

Same as `/aid-create-document`: mechanical grounding check + a clean-context **`aid-reviewer`**
adversarial check (accurate, complete, no fabrication, structure preserved) -> `grade.sh`
-> loop on failure (3-cycle circuit-breaker -> IMPEDIMENT, and the lifecycle set to `Blocked` through the writer).

**Advance:** CHAIN -> [State: PRESENT].

---

## State: PRESENT  (hard stop -- human final say)

The hard stop follows the ASK step of `skill-steps.md`. Present the revised document **as a diff against
the current file** + the target path. Await approval. Never writes `.aid/knowledge/`.

**Advance:** ASK -> [State: WRITE].

---

## State: WRITE  (only on approval)

If the user declined, write nothing: the draft stays in the work folder, and the step goes on to
DONE. Otherwise write the revision back to the existing document (the diff was already reviewed at
PRESENT). Then optionally print handoffs (`/aid-update-kb`, `/aid-create*`, ...).

**Advance:** CHAIN -> [State: DONE].

---

## State: DONE

Finish through the writer: `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Completed`, which also clears the saved skill and step.

**Advance:** HALT.

---

## Constraints

- **Resolves nothing**; edits + writes back on approval.
- **Reads the existing document first**; shows a **diff**; never silently overwrites.
- **Grounded + accurate** to KB + source; **NEVER writes `.aid/knowledge/`**.
- **Clean context**; **verification always a sub-agent dispatch** (`aid-reviewer`).
- **Tracking:** every record change goes through the writer (`skill-steps.md`, § The work record).
