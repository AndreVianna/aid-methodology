---
name: aid-create-document
description: >
  Create a document NOW -- markdown/reference/how-to, an ADR, an architecture
  write-up, a runbook, a tutorial, a changelog, a mermaid diagram, a table --
  determining the format AND structure from the request, in one pass. Grounded
  in and accuracy-checked against the Knowledge Base (.aid/knowledge/) and the
  project source. It RESOLVES NOTHING: it drafts the document, you approve, then
  it is placed. Produced by the aid-tech-writer agent and verified by
  aid-reviewer. NEVER writes into .aid/knowledge/ (that is /aid-update-kb's
  territory). Allocates a work-NNN folder. /aid-add-document is its alias; the
  genre skills (/aid-document-decision, ...) and /aid-create-diagram delegate here.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "<subject> -- what to document (optionally a kind: adr, runbook, tutorial, changelog, diagram, ...)"
---

# Create Document (write it now, resolve nothing)

`/aid-create-document` writes a document **now** and places it on your approval. It
determines the **format** (markdown, mermaid diagram, HTML, a table) and the **structure**
(ADR, runbook, tutorial, changelog, general/Diataxis, ...) from the request -- deferring to
intelligence, not a per-kind skill. `/aid-add-document` is its pure alias; the genre skills
(`/aid-document-decision`, `-architecture`, `-guideline`, `-standard`, `-runbook`,
`-tutorial`, `-changelog`) and `/aid-create-diagram` are thin kind-siblings that delegate
here binding a genre/format hint.

- **Boundary vs the KB:** this **never writes `.aid/knowledge/`**. If the content belongs
  in the KB, print a handoff to `/aid-update-kb`. The KB is `aid-discover`/`aid-update-kb`
  territory (its own authoring rules + grading).
- **Boundary vs `/aid-design`:** `aid-design` *produces a design* (`aid-architect`);
  `aid-create-document` *writes documentation about* something (`aid-tech-writer`).
- **Not a numbered pipeline phase**; does not route to `/aid-execute`.
- **Behavior contract:** `.aid/work-005-lite-skills-refactor/specs/aid-document.md`.
- **Genre structures** (ADR / C4 / runbook / ...): `.codex/aid/templates/shortcut-scaffolding/document.md`.

State machine: **INTAKE -> AUTHOR -> VERIFY (loop) -> PRESENT [human gate] -> PLACE (on
approval) -> DONE**. Print the `[State: NAME] -- {purpose}` entry line on each state.

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
5. **Consult the Work Initiation Gate, then allocate the work folder + STATE.** First run
   the gate (`.codex/aid/templates/work-initiation-gate.md`):
   `bash .codex/aid/scripts/works/enumerate-works.sh` (main tree + every git worktree).
   Empty -> allocate, no prompt. Works exist -> ask new-vs-continuation; on **continuation**
   route to the chosen work's resume door and STOP (allocate nothing); on **new work**
   allocate (`pipeline.path: lite`, `initiator: aid-create-document`, `lifecycle: Running`,
   `active_skill: aid-create-document`; `phase` not driven).

**Advance:** AUTHOR.

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
3. **Grade:** `bash .codex/aid/scripts/grade.sh --explain <ledger>`. Not clean -> loop
   to AUTHOR. Circuit-breaker: 3 cycles -> IMPEDIMENT + `lifecycle: Blocked`.

**Advance:** PRESENT.

---

## State: PRESENT  (hard stop -- human final say before placing)

Set `lifecycle: Paused-Awaiting-Input`. Present the drafted document **and the proposed
target location** (KB-informed: `docs/`, an ADR dir, `CHANGELOG.md`, a runbook path, ...).
Await approval. **Never writes `.aid/knowledge/`.**

**Advance:** PLACE on approval; else DONE (draft kept in the work folder).

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

Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. Keep the
work folder (draft + verify ledger) as the audit record.

---

## Constraints

- **Resolves nothing** -- drafts + places on approval; asserts no decision.
- **Grounded + accurate** to KB + source, enforced (VERIFY step 1 + the writer brief).
- **NEVER writes `.aid/knowledge/`** -- KB updates route to `/aid-update-kb`.
- **Present before place**; extra care on overwrite / published `docs/`.
- **Clean context**; **verification always a sub-agent dispatch** (`aid-reviewer`).
- **Tracking:** write STATE `lifecycle` at every transition.
