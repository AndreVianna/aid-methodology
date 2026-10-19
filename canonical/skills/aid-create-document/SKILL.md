---
name: aid-create-document
description: >
  Create a document in one pass, working out both its format and its structure from what you
  ask for -- a how-to, a reference page, an ADR, an architecture write-up, a runbook, a
  tutorial, a changelog, a diagram, a table. Use this skill when you need a document written
  now and do not want to decide its genre first. It is grounded in, and accuracy-checked
  against, the Knowledge Base (`.aid/knowledge/`) and the project source; aid-tech-writer
  produces it and aid-reviewer verifies it. It resolves nothing: it drafts, you approve, and
  only then is the document placed. It never writes into `.aid/knowledge/` -- that is
  `/aid-update-kb`'s territory. The genre skills such as `/aid-document-decision`, and
  `/aid-create-diagram`, all delegate here. To settle a document's direction as a reusable
  design seed first, use `/aid-design-document`.
allowed-tools: Read Glob Grep Bash Shell Terminal Write Edit Agent
argument-hint: "<subject> -- what to document (optionally a kind: adr, runbook, tutorial, changelog, diagram, ...)"
---

# Create Document (write it now, resolve nothing)

`/aid-create-document` writes a document **now** and places it on your approval. It
determines the **format** (markdown, mermaid diagram, HTML, a table) and the **structure**
(ADR, runbook, tutorial, changelog, general/Diataxis, ...) from the request -- deferring to
intelligence, not a per-kind skill. The genre skills
(`/aid-document-decision`, `-architecture`, `-guideline`, `-standard`, `-runbook`,
`-tutorial`, `-changelog`) and `/aid-create-diagram` are thin kind-siblings that delegate
here binding a genre/format hint.

- **Boundary vs the KB:** this **never writes `.aid/knowledge/`**. If the content belongs
  in the KB, print a handoff to `/aid-update-kb`. The KB is `aid-discover`/`aid-update-kb`
  territory (its own authoring rules + grading).
- **Boundary vs `/aid-design`:** `aid-design` *produces a design* (`aid-architect`);
  `aid-create-document` *writes documentation about* something (`aid-tech-writer`).
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.
- **Genre structures** (ADR / C4 / runbook / ...): `.aid/runtime/templates/shortcut-scaffolding/document.md`.

State machine: **INTAKE -> AUTHOR -> VERIFY (loop) -> PRESENT [human gate] -> PLACE (on
approval) -> DONE**. Print the `[State: NAME] -- {purpose}` entry line on each state.
Steps, hand-offs and the work record follow [`skill-steps.md`](../../aid/templates/skill-steps.md).

---

## State Detection

**Detection shapes the entry step and validates a saved step, and never routes** (`skill-steps.md`, § State Detection). A fresh start enters INTAKE. A resume continues at the step the work record saves, which the gate's § 3b routes to; the saved step's artifact is checked against disk, and a mismatch goes to recovery, never to a silent re-route.

---

## State: INTAKE

1. **Require a subject.** Empty argument -> ask one bootstrapping question ("What do you
   want documented, and for whom?") and wait.
2. **Resolve format + genre** from the request (or the hint a kind-sibling bound): e.g. "an
   ADR for X" -> markdown ADR; "a diagram of the pipeline" -> mermaid; "the release notes"
   -> changelog. Use the genre structures in `document.md`.
3. **Pick the path:** **Fast** -- a clear subject + kind -> author now. **Guided** -- vague
   -> scope subject / audience / kind first.
4. **Classify complexity (model + effort):** most docs -> `aid-tech-writer` at **sonnet /
   medium**; a heavy architecture write-up -> **opus / high**. Verifier tier >= producer.
5. **Allocate the work through the gate.** Run the Work Initiation Gate
   (`.aid/runtime/templates/work-initiation-gate.md`): `bash .aid/runtime/scripts/works/enumerate-works.sh`
   (main tree + every git worktree). Empty -> no prompt. Works exist -> ask the gate's
   new-vs-continuation question with the enumerated list.
   - **New work:** call the gate's `§ 3a` with the user's words, this skill's name
     (`aid-create-document`), its first step (`INTAKE`), `--path lite`, and a kebab-case slug from
     the subject. The gate's `§ 3a` step 2 creates and enters the worktree
     (`worktree-lifecycle.sh create <work-id> <name>`),
     **then** allocate (`.aid/works/<work-id>-<slug>/`) the work folder and write its record through
     the writer, before it hands back: "`STATE.yml` was created by the gate;
     skip any instruction to write `initiator`, `active_skill`, `lifecycle` or `phase` by hand;
     set other keys through the writer." This skill drives no `phase`. When `/aid-orchestrate`
     passed an `intent:` block, write it into that STATE.yml in block style, keys as passed,
     replacing the template's `intent:` rest value, as the engine's INTAKE Step 5 does
     (`.aid/runtime/templates/shortcut-engine.md`); a typed `/aid-create-document` (or
     `/aid-document`, which runs this skill) writes none.
   - **Continuation:** On continuation, follow the gate's § 3b: enter the chosen work's worktree and run the skill its record names, at its saved step.
6. **Read the design seed, if present.** If `.aid/design/document.md` exists, read it as
   prior context before drafting; it is an input, never a substitute, and is not modified
   by this run.

**Advance:** ASK -> [State: AUTHOR].

---

## State: AUTHOR

Dispatch **`aid-tech-writer`** (clean context, tiered) to write the document in the resolved
format + genre structure, **grounded in and accurate to** the KB + project source
(`task-type-rules.md ## DOCUMENT` -- verify accuracy against the current codebase and KB).
It drafts into the work folder (not yet placed). Text formats are produced natively
(markdown, mermaid, HTML, CSV/tables); for a format it cannot cleanly emit (native
`.pptx`/`.xlsx`), it produces the best text form and notes the conversion handoff.

**Advance:** VERIFY.

---

## State: VERIFY

1. **Mechanical grounding check** (no dispatch): claims about the project cite a KB doc or
   `file:line`; the genre's required structure is present.
2. **Adversarial verification** -- clean-context **`aid-reviewer`** checks the draft:
   accurate against KB + codebase, complete for its genre, no fabricated content. Writes a
   review-quality ledger to `.aid/.temp/review-pending/<work>-verify.md`.
3. **Grade:** `bash .aid/runtime/scripts/grade.sh --explain <ledger>`. Not clean -> loop
   to AUTHOR. Circuit-breaker: 3 cycles -> IMPEDIMENT, and the lifecycle set to `Blocked` through the writer.

**Advance:** PRESENT.

---

## State: PRESENT  (hard stop -- human final say before placing)

The hard stop follows the ASK step of `skill-steps.md`. Present the drafted document **and the proposed
target location** (KB-informed: `docs/`, an ADR dir, `CHANGELOG.md`, a runbook path, ...).
Await approval. **Never writes `.aid/knowledge/`.**

**Advance:** ASK -> [State: PLACE] on approval; otherwise [State: DONE] (draft kept in the work folder).

---

## State: PLACE  (only on approval)

Write the document to its approved target location. **Extra care on overwrite or on the
published `docs/` tree:** inspect the target first and show the diff -- never silently
overwrite an existing doc. Then optionally print handoffs the user may act on: `/aid-update-kb`
(if it belongs in the KB), `/aid-create*` (if it describes something not yet built),
`/aid-refactor` (an ADR mandating a refactor).

**Advance:** DONE.

---

## State: DONE

Finish through the writer: `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Completed`, which also clears the saved skill and step. Keep the work folder (draft + verify ledger) as the audit record.

**Advance:** HALT.

---

## Constraints

- **Resolves nothing** -- drafts + places on approval; asserts no decision.
- **Grounded + accurate** to KB + source, enforced (VERIFY step 1 + the writer brief).
- **NEVER writes `.aid/knowledge/`** -- KB updates route to `/aid-update-kb`.
- **Present before place**; extra care on overwrite / published `docs/`.
- **Clean context**; **verification always a sub-agent dispatch** (`aid-reviewer`).
- **Tracking:** every record change goes through the writer (`skill-steps.md`, § The work record).
