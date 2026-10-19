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

State machine: **INTAKE -> AUTHOR -> VERIFY (loop) -> PRESENT [human gate, diff] -> WRITE
(on approval) -> DONE**. Print the `[State: NAME] -- {purpose}` entry line on each state.
Steps, hand-offs and the work record follow [`skill-steps.md`](../../aid/templates/skill-steps.md).

---

## State Detection

**Detection shapes the entry step and validates a saved step, and never routes** (`skill-steps.md`, § State Detection). A fresh start enters INTAKE. A resume continues at the step the work record saves, which the gate's § 3b routes to; the saved step's artifact is checked against disk, and a mismatch goes to recovery, never to a silent re-route.

---

## State: INTAKE

1. **Require a target document + a change.** Empty argument -> ask one bootstrapping
   question ("Which document should I update, and what change?") and wait.
2. **Locate + read the existing document.** If it cannot be resolved, ask (or, if the user
   meant a new doc, suggest `/aid-create-document`).
3. **Pick the path** (fast if the document + change are clear; guided otherwise) and
   **classify complexity** -> `aid-tech-writer` model/effort (sonnet/medium default; opus/high
   for a large rewrite). Verifier tier >= producer.
4. **Allocate the work through the gate.** Run the Work Initiation Gate
   (`.aid/runtime/templates/work-initiation-gate.md`): `bash .aid/runtime/scripts/works/enumerate-works.sh`
   (main tree + every git worktree). Empty -> no prompt. Works exist -> ask the gate's
   new-vs-continuation question with the enumerated list.
   - **New work:** call the gate's `§ 3a` with the user's words, this skill's name
     (`aid-update-document`), its first step (`INTAKE`), and a kebab-case slug from the document.
     The gate's `§ 3a` step 2 creates and enters the worktree
     (`worktree-lifecycle.sh create <work-id> <name>`),
     **then** allocate (`.aid/works/<work-id>-<slug>/`) the work folder and write its record through
     the writer, before it hands back: "`STATE.yml` was created by the gate;
     skip any instruction to write `initiator`, `active_skill`, `lifecycle` or `phase` by hand;
     set other keys through the writer." This skill drives no `phase`.
   - **Continuation:** On continuation, follow the gate's § 3b: enter the chosen work's worktree and run the skill its record names, at its saved step.
5. **Read the design seed, if present.** If `.aid/design/document.md` exists, read it as
   prior context before drafting; it is an input, never a substitute, and is not modified
   by this run.

**Advance:** ASK -> [State: AUTHOR].

---

## State: AUTHOR

Dispatch **`aid-tech-writer`** (clean context, tiered) to produce the **revised** document
(a draft in the work folder, not yet written back), grounded in and accurate to the KB +
project source, preserving the document's existing genre structure.

**Advance:** VERIFY.

---

## State: VERIFY

Same as `/aid-create-document`: mechanical grounding check + a clean-context **`aid-reviewer`**
adversarial check (accurate, complete, no fabrication, structure preserved) -> `grade.sh`
-> loop on failure (3-cycle circuit-breaker -> IMPEDIMENT, and the lifecycle set to `Blocked` through the writer).

**Advance:** PRESENT.

---

## State: PRESENT  (hard stop -- human final say)

The hard stop follows the ASK step of `skill-steps.md`. Present the revised document **as a diff against
the current file** + the target path. Await approval. Never writes `.aid/knowledge/`.

**Advance:** ASK -> [State: WRITE] on approval; otherwise [State: DONE] (draft kept in the work folder).

---

## State: WRITE  (only on approval)

Write the revision back to the existing document (the diff was already reviewed at PRESENT).
Then optionally print handoffs (`/aid-update-kb`, `/aid-create*`, ...).

**Advance:** DONE.

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
