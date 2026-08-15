# task-065: Four "what AID has" Knowledge Base documents describe the design family

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-065/STATE.md.
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

**Depends on:** task-064

**Scope:**
- Source: `features/feature-006-integration-and-close-out/SPEC.md` §7's Knowledge Base table, rows
  `capability-inventory.md`, `architecture.md`, `module-map.md` and `project-structure.md`. It closes
  the first four documents named in BLUEPRINT criterion **9** and carries their share of criterion
  **4**'s *"every count-bearing surface states its own new value"*.
- **The Knowledge Base is refreshed once, here, after the roster settles.** Mid-work staleness was
  correct, not a defect; refreshing before the render and the site regeneration guarantees rework.
  This is the first of four authoring slices over the documents that describe what AID **has**.
- **`capability-inventory.md`** gains the design family as a capability and the three-verb
  `design -> create -> update` lifecycle, and moves its count lines. §7 records four of them --
  `:154`, `:159`, `:181`, `:286` -- and marks all four **guard-blind**, so the count guard will not
  report them and the stage-2 replay in task-069 is the oracle. `:159` (*"Every one of the 58 rows
  owns..."*) is mode M2: a bare `rows` noun no `CLAIMS` regex matches.
- **`architecture.md`** gains prose about the design family **and** its own count table. §7 names this
  a known drift pair: the guard catches the table and a human must catch the prose. `:432` (*"has 76
  directories"*) is mode M2, a bare `directories` noun, and is guard-blind.
- **`module-map.md`** gains the new skill directories. `:76` is mode **M5** and is fixed **in this
  document, not in the guard**: `` `canonical/skills/*` (76) `` is excluded by a deliberate `*`
  lookbehind (`check-skill-counts.mjs:84-86`) that stops a module count being read as a skill count.
  Widening that pattern would re-import the false positives it was written to remove, so the line is
  re-worded to a phrasing the existing guard can see. Weakening a correct guard to accommodate a
  document is the wrong direction of fix.
- **`project-structure.md`** gains the `canonical/skills/` tree line and the catalog manifest row.
  `:95` is **guarded** -- the guard will report it -- and `:182` (*"58-row manifest"*) is mode M2 and
  guard-blind.
- **The per-quantity delta, which is why "update every count" would corrupt these files.** Directories
  76 -> **112**; catalog rows 58 -> **94**; canonical names 58 -> **94**; `repurpose` rows 24 -> **60**;
  aliases **0**, unchanged; **`shortcuts` (emitting) 34, unchanged**; `curatedOnly` **18**, unchanged;
  `classicRepurposed` **3**, unchanged. Roughly half the count-bearing sentences in the repository use
  the `shortcuts` phrasing, so each edit is made against the quantity the sentence names, never against
  a single number.
- **Two authoring rules bind these edits and both are already enforced elsewhere.** No `work-NNN`
  reference and no work-folder path may appear (`AS03c`), and no `## Change Log` section or
  `changelog:` frontmatter field may be added (`AS03`, `AS03b`) -- REQUIREMENTS **C-3** and §4's Out of
  Scope record that master resolved this upstream and that `AS03` now asserts the **absence** of the
  history apparatus.
- **Do not state a current count inside a dated bullet or a dated table row.** The guard's
  `HISTORY_SHAPES` rule (`check-skill-counts.mjs:216-219`) skips both shapes, and its own comment says
  the rule is evadable. 16 such lines are skipped today and **0** carry a count; this work must not
  introduce one.
- Out of scope: `pipeline-contracts.md`, `domain-glossary.md` and `decisions.md` (task-066);
  `test-landscape.md` and `tech-debt.md` (task-067); every `docs/` and `site/` surface (task-068);
  `check-skill-counts.mjs` itself and the stage-2 replay (task-069); `INDEX.md` (task-070) and
  `kb.html` (task-071).

**Acceptance Criteria:**
- [ ] **BLUEPRINT criterion 9, first four documents -- each describes the new family, not just its
      count.** `capability-inventory.md` names the design family as a capability and states the
      three-verb lifecycle; `architecture.md`'s prose describes it; `module-map.md` lists the new skill
      directories; `project-structure.md`'s `canonical/skills/` tree line and catalog manifest row are
      current. A reviewer read per document, recorded with the added or changed passage quoted
- [ ] **BLUEPRINT criterion 4's share -- every count line in these four states its own quantity's new
      value.** Each edited figure is recorded as a triple: the quantity it states, the value before,
      and the value after. Directories -> 112, catalog rows / canonical names -> 94, `repurpose` rows
      -> 60
- [ ] **The negative half, which is this delivery's most likely error mode.** In these four documents,
      no phrasing of the **`shortcuts` (emitting)** quantity moved off **34**, no `curatedOnly` figure
      moved off **18**, no `classicRepurposed` figure moved off **3**, and no alias figure moved off
      **0**. Asserted by diffing the set of lines matching `\b34\b`, `\b18\b`, `\b3 classic` and
      `\b0 alias` against `git show HEAD:` for each file, with every difference explained
- [ ] **`architecture.md`'s prose and its own count table agree.** Both halves are checked, and the
      record states them separately -- §7 names this a known drift pair. Under the re-scope
      (`../../RESCOPE-COUNT-GUARD.md`) **both** halves are now human-checked: these are
      `.aid/knowledge/` surfaces, which the surviving guard does not scan
- [ ] **`module-map.md:76` was re-worded, not exempted.** The line states a count that is either
      removed as cosmetic or re-measured from disk at authoring time, per criterion **`G-01`**, and
      the record states which phrasing was chosen and the command behind any figure it keeps. The
      old requirement -- that the phrasing be visible to the retired guard's `CLAIMS` pattern -- is
      superseded; no count guard is edited by this task (`git diff --exit-code -- tests/` is clean)
- [ ] **`G-01` is discharged over these four and the verdicts are recorded.** For each of the four
      files, the record states whether its count line was **removed** as cosmetic or **re-measured**
      at authoring time, with the command used for a re-measure. The retired repo-wide count guard
      is not run and not re-created; `.aid/knowledge/` and `canonical/` counts are reviewer-governed
      under `G-01` at severity `MINOR` (`../../RESCOPE-COUNT-GUARD.md`). A file reported only as
      "checked" fails this criterion
- [ ] **No history apparatus and no work reference was introduced.** For each of the four,
      `grep -cE 'work-[0-9]{3}'` captured to a variable -> `0`, `grep -c '^## Change Log'` -> `0`, and
      no `changelog:` frontmatter field exists. The named oracles `AS03`, `AS03b` and `AS03c` are green
- [ ] **No current count was written into a dated bullet or a dated table row.** The count of
      `HISTORY_SHAPES`-skipped lines carrying a count is still **0**, taken from the guard's own run
      output rather than from a hand search
- [ ] **Only these four documents moved.** `git diff --name-only HEAD -- .aid/knowledge/` lists exactly
      `capability-inventory.md`, `architecture.md`, `module-map.md` and `project-structure.md`
- [ ] Accuracy verified against the current codebase: every line number cited in this task's record is
      re-resolved against the file as it stands rather than carried from this DETAIL or from §7
- [ ] Nothing outside the declared writes moves:
      `git diff --exit-code -- canonical/ tests/ site/ docs/ profiles/ .claude/ .cursor/` is clean
- [ ] All section-6 quality gates pass
