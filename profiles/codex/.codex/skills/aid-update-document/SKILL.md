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
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
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
- **Genre structures:** `.codex/aid/templates/shortcut-scaffolding/document.md`.

State machine: **INTAKE -> AUTHOR -> VERIFY (loop) -> PRESENT [human gate, diff] -> WRITE
(on approval) -> DONE**. Print the `[State: NAME] -- {purpose}` entry line on each state.

---

## State: INTAKE

1. **Require a target document + a change.** Empty argument -> ask one bootstrapping
   question ("Which document should I update, and what change?") and wait.
2. **Locate + read the existing document.** If it cannot be resolved, ask (or, if the user
   meant a new doc, suggest `/aid-create-document`).
3. **Pick the path** (fast if the document + change are clear; guided otherwise) and
   **classify complexity** -> `aid-tech-writer` model/effort (sonnet/medium default; opus/high
   for a large rewrite). Verifier tier >= producer.
4. **Consult the Work Initiation Gate, then allocate the work folder + STATE.** First run
   the gate (`.codex/aid/templates/work-initiation-gate.md`):
   `bash .codex/aid/scripts/works/enumerate-works.sh` (main tree + every git worktree).
   Empty -> allocate, no prompt. Works exist -> ask new-vs-continuation; on **continuation**
   route to the chosen work's resume door and STOP (allocate nothing); on **new work**:
   create and enter the worktree per the gate's `§ 3a` step 2
   (`worktree-lifecycle.sh create <work-id> <name>`, STOP on a non-zero exit or empty path,
   else enter the resolved path), **then** allocate (`initiator: aid-update-document`;
   `phase` not driven).
5. **Read the design seed, if present.** If `.aid/design/document.md` exists, read it as
   prior context before drafting; it is an input, never a substitute, and is not modified
   by this run.

**Advance:** AUTHOR.

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
-> loop on failure (3-cycle circuit-breaker -> IMPEDIMENT + `lifecycle: Blocked`).

**Advance:** PRESENT.

---

## State: PRESENT  (hard stop -- human final say)

Set `lifecycle: Paused-Awaiting-Input`. Present the revised document **as a diff against
the current file** + the target path. Await approval. Never writes `.aid/knowledge/`.

**Advance:** WRITE on approval; else DONE (draft kept in the work folder).

---

## State: WRITE  (only on approval)

Write the revision back to the existing document (the diff was already reviewed at PRESENT).
Then optionally print handoffs (`/aid-update-kb`, `/aid-create*`, ...).

**Advance:** DONE.

---

## State: DONE

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.

---

## Constraints

- **Resolves nothing**; edits + writes back on approval.
- **Reads the existing document first**; shows a **diff**; never silently overwrites.
- **Grounded + accurate** to KB + source; **NEVER writes `.aid/knowledge/`**.
- **Clean context**; **verification always a sub-agent dispatch** (`aid-reviewer`).
- **Tracking:** write STATE `lifecycle` at every transition.
