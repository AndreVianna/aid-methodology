# task-066: Per-skill contracts, two glossary terms, and the two decisions this work made

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-066/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** DOCUMENT

**Source:** work-006-design-phase-skills -> delivery-003

**Depends on:** task-065

**Scope:**
- Source: `features/feature-006-integration-and-close-out/SPEC.md` §7's Knowledge Base table, rows
  `pipeline-contracts.md`, `domain-glossary.md` and `decisions.md`. It closes three more of the
  documents named in BLUEPRINT criterion **9** and carries their share of criterion **4**.
- **`pipeline-contracts.md` gains per-skill state machines for the thirty-six.** This is the document
  the closing pipeline sweep (task-073) diffs in a **scoped** way rather than with `--exit-code`,
  precisely because this task edits it on purpose: what task-073 asserts is that the numbered
  Discover / Describe / Define / Specify / Plan / Detail / Execute sequence inside it is unchanged,
  not that the file is. Read that sequence out of the file rather than retyping it -- **this file uses
  ASCII `->`** and states *"six numbered phases"*, writing the pair as `Describe/Define (Phase 2a/2b)`
  (`:450-451`), whereas `CLAUDE.md:74` and `AGENTS.md:74` use U+2192 (`→`) and name seven. The phase
  set is the same in all three; only the rendering differs, so a pattern copied from either agent-context
  file matches nothing here.
- **No new skill may declare a `phase:`, and this document is where that temptation lives.** The
  thirty-six are on-demand skills in the shape `/aid-design` and `/aid-prototype` already have
  (REQUIREMENTS **FR-3**), so their contracts are written without phase membership. C-1's closed enum
  is not extended and no contract implies it was.
- **`domain-glossary.md` gains four entries**: *seed*, *design artifact*, and the two new documents
  `roadmap.md` and `backlog.md`. §7 flags three count lines in this file -- `:481`, `:483`, `:496` --
  all **guard-blind**; `:496` (*"58-row **single-source** catalog"*) is mode **M3**, right noun with an
  intervening word defeating the adjacency the regex requires.
- **`decisions.md` gains exactly two decisions**, both of which REQUIREMENTS states the reasoning for
  and neither of which is derivable from the code: why `design`/`create`/`update` were chosen over an
  `export` or `document-` verb (REQUIREMENTS **FR-1**, **C-2**, **FR-6**), and why forward-looking
  documents were admitted to a Knowledge Base that describes what **is** (REQUIREMENTS §5.3's
  rationale paragraph -- a committed decision is a present fact; a design seed is not yet one and stays
  in `.aid/design/`).
- **`decisions.md` is conditional, and that is a fact this task must not contradict.** FR-9 cites it as
  the precedent for admitting `roadmap.md` and `backlog.md` as conditional documents, and it is
  `required` in this repository's own resolved doc-set under **CC-1**. Adding decisions to it does not
  change either property.
- **The per-quantity delta binds here as it does everywhere.** Directories 76 -> **112**; catalog rows
  and canonical names 58 -> **94**; `repurpose` rows 24 -> **60**; aliases **0**; **`shortcuts`
  (emitting) 34, unchanged**; `curatedOnly` **18**; `classicRepurposed` **3**. Each edit is made against
  the quantity the sentence names.
- **Two authoring rules bind, both already enforced.** No `work-NNN` reference and no work-folder path
  (`AS03c`), and no `## Change Log` section or `changelog:` frontmatter field (`AS03`, `AS03b`) --
  REQUIREMENTS **C-3**. And no current count inside a dated bullet or a `| N | YYYY-MM-DD |` row, which
  the guard's `HISTORY_SHAPES` rule (`check-skill-counts.mjs:216-219`) skips.
- Out of scope: the four documents task-065 owns; `test-landscape.md` and `tech-debt.md` (task-067);
  every `docs/` and `site/` surface (task-068); `check-skill-counts.mjs` and the stage-2 replay
  (task-069); `INDEX.md` (task-070) and `kb.html` (task-071). Also out of scope: extending the `phase:`
  enum or the numbered sequence in any form.

**Acceptance Criteria:**
- [ ] **BLUEPRINT criterion 9 -- all thirty-six carry a per-skill contract in `pipeline-contracts.md`.**
      For each of the thirty-six skill names, the document holds an entry naming it; the count of
      thirty-six named skills is captured to a variable and compared against the thirty-six directory
      names derived from disk, with `comm -3` over the two sorted lists **empty**
- [ ] **No contract declares or implies a phase.** `grep -c 'phase:' ` over the added region captured
      to a variable -> `0`, and the numbered sequence
      `Discover -> Describe -> Define -> Specify -> Plan -> Detail -> Execute` appears in this document
      exactly as it does in `git show HEAD:.aid/knowledge/pipeline-contracts.md` -- a scoped comparison
      of that sequence, not a whole-file diff, which this task makes unsatisfiable by design
- [ ] **`domain-glossary.md` gains all four entries**: *seed*, *design artifact*, `roadmap.md` and
      `backlog.md`, each recorded with its definition quoted. The *seed* entry states the
      `.aid/design/` lifecycle and the governing distinction -- the Knowledge Base describes what
      **is**, a seed describes what **should be**
- [ ] **`decisions.md` gains exactly two decisions, and both record reasoning rather than outcome.**
      The verb-choice decision names the rejected alternatives (`export`, `document-`) and why; the
      forward-looking-documents decision states why a committed decision is a present fact while a
      design seed is not. Recorded with both entries quoted in full
- [ ] **BLUEPRINT criterion 4's share -- every count line in these three states its own quantity's new
      value**, recorded as a triple per figure: quantity, value before, value after
- [ ] **The negative half.** In these three documents no phrasing of the **`shortcuts` (emitting)**
      quantity moved off **34**, no `curatedOnly` figure off **18**, no `classicRepurposed` figure off
      **3**, and no alias figure off **0** -- asserted by diffing the matching lines against
      `git show HEAD:` per file, with every difference explained
- [ ] **`domain-glossary.md:496`'s M3 line is fixed by re-wording the document**, not by widening a
      regex: `check-skill-counts.mjs` is **not** edited here (`git diff --exit-code -- tests/` is clean)
      and the record states the chosen phrasing
- [ ] **The guard is run over these three and its report recorded**: every line it reports is either
      fixed here or recorded with the task that owns it
- [ ] **No history apparatus and no work reference was introduced.** Per file,
      `grep -cE 'work-[0-9]{3}'` -> `0`, `grep -c '^## Change Log'` -> `0`, no `changelog:` field; and
      `AS03`, `AS03b`, `AS03c` are green
- [ ] **No current count was written into a dated bullet or dated table row** -- the guard's own count
      of `HISTORY_SHAPES`-skipped lines carrying a count is still **0**
- [ ] **Only these three documents moved.** `git diff --name-only HEAD -- .aid/knowledge/` lists exactly
      `pipeline-contracts.md`, `domain-glossary.md` and `decisions.md`
- [ ] Accuracy verified against the current codebase: every line number cited in this task's record is
      re-resolved against the file as it stands
- [ ] Nothing outside the declared writes moves:
      `git diff --exit-code -- canonical/ tests/ site/ docs/ profiles/ .claude/ .cursor/` is clean
- [ ] All section-6 quality gates pass
