# task-068: The methodology narrative, its Skill Inventory Total, and the four synced mirrors

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-068/STATE.md.
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

**Depends on:** task-067

**Scope:**
- Source: `features/feature-006-integration-and-close-out/SPEC.md` §7's *Methodology narrative* table
  and §3's surface inventory. It closes the methodology half of BLUEPRINT criterion **9** -- *"the
  methodology Skill Inventory table and its independently hand-maintained site mirror both moved to a
  Total of 94"* -- and carries these files' share of criterion **4**.
- **The hand-authored sources, which is what this task edits.** `docs/aid-methodology.md`: §1's
  entry-point paragraph (`:91`), the corpus footnote (`:101`), the family narrative (`:130`) and **the
  Skill Inventory table** (`:132-149`). `docs/diagram-content-reference.md`: `:24`, `:104`, `:109`,
  `:111`. `docs/glossary.md`: `:68`. `docs/install.md`: `:411`. `site/src/content/docs/index.mdx`:
  `:77`.
- **A correction to §7, made against disk rather than carried forward.** §7's row for
  `site/src/content/docs/concepts/methodology.md` calls it *"a **separate hand-maintained file**, not a
  render of `docs/`"* and offers the four-line offset between the two files as evidence. That is false:
  `site/scripts/sync-docs.mjs`'s `MANIFEST` (`:30-70`) maps `aid-methodology.md` ->
  `concepts/methodology.md`, `faq.md` -> `concepts/faq.md`, `repository-structure.md` ->
  `reference/repository-structure.md` and `glossary.md` -> `reference/glossary.md`. The offset is the
  sync transform -- it strips the leading H1 and injects a four-line frontmatter block -- not
  independent maintenance. So **two** of §7's named site edit sites are generated:
  `concepts/methodology.md` and `reference/glossary.md`. Hand-editing either would be overwritten by the
  next `prebuild`, which runs `sync:docs` before every build. `site/src/content/docs/index.mdx` is
  **not** in the manifest and is genuinely hand-maintained.
- **So the procedure is: edit the four `docs/` sources plus `index.mdx`, then run
  `node site/scripts/sync-docs.mjs`** and commit the regenerated mirrors together with
  `site/scripts/.synced-manifest.json`. That is one mechanism instead of two hand-edits kept in lockstep
  by nothing, and it removes the drift §7's row was describing.
- **The Skill Inventory table's row deltas, taken from the sibling row tables rather than recounted
  here** (feature-003 §1 and feature-004 §1): `create` 12 -> **19**, `update` 12 -> **19**,
  `prototype + design` 3 -> **25**, the other twelve rows unchanged at **31** combined, Total 58 ->
  **94**. Arithmetic: `19 + 19 + 25 = 63`, plus 31, is 94; and the moving families absorb exactly the
  new rows, `(19-12) + (19-12) + (25-3) = 36`.
- **25, not 22, on the `prototype + design` row -- and the reason is a taxonomy, not a discrepancy.**
  This table is a third, hand-curated axis: it mostly tracks the catalog's `group:` field but splits G5
  and G11 by verb and merges G9+G10. Its `prototype + design` row is G3, which holds `design` 22 +
  `prototype` 2 + `brainstorm` 1 = **25**. The **22** is the site's **verb** family card count and is
  task-064's. A 22 here would be wrong.
- **Whether `/aid-brainstorm` earns its own table row is an authoring decision this table forces**, and
  the table already splits by verb elsewhere, so precedent exists both ways. §7 folds it into
  `prototype + design`; the row deltas above assume that, so a different choice changes two figures and
  must be recorded as a decision rather than made silently.
- **Give the Total row a noun (mode M1).** A bare `| **58** |` cell has nothing for any `CLAIMS`
  pattern to anchor on, which is why the guard cannot see it today. Label the figure so the
  `catalog rows` patterns can -- §3 stage 2 makes the same edit for guard reasons and §7 for content
  reasons; it is one edit.
- **The four decomposition tails (mode M4).** `docs/glossary.md:68`, `docs/install.md:411`,
  `site/src/content/docs/index.mdx:77` and `docs/diagram-content-reference.md:24`/`:104` state a total
  and then break it down; the head matches a `CLAIMS` regex and pins one quantity while the `+ N + N`
  tail is never examined. Every operand in each tail moves to its own quantity's new value, and the
  arithmetic is re-checked per sentence.
- **`docs/diagram-content-reference.md:109` and `:111` are mode M5** and are fixed **in the document**:
  the guard's `*` lookbehind (`check-skill-counts.mjs:84-86`) is a deliberate exclusion that stops a
  module count being read as a skill count, so the lines are re-worded to a guarded phrasing rather than
  the pattern widened.
- **`docs/install.md:411`'s noun is `files`** (*"76 `aid-`-prefixed skill markdown **files**"*) -- mode
  M2. The figure is the directory count, 112, and the noun stays accurate: one `SKILL.md` per directory.
- **No `release-tracking.md` entry.** Under the doctrine this work installs, that file is purely
  historical and its version sections are written at tag time by `release-aid` from `backlog.md`. It is
  also one of the guard's two `EXCLUDE_FILES` (`check-skill-counts.mjs:155-158`), so the guard will not
  report it either.
- Out of scope: every `.aid/knowledge/` document (task-065 through task-067, task-070, task-071);
  `check-skill-counts.mjs` and the stage-2 replay (task-069); the generated site skill pages, index and
  flow sidecars (task-064); and any write under `site/scripts/__tests__/`, barred by feature-001 AC-3.

**Acceptance Criteria:**
- [ ] **BLUEPRINT criterion 9's methodology half -- both Skill Inventory tables read a Total of 94.**
      In `docs/aid-methodology.md` and in the regenerated
      `site/src/content/docs/concepts/methodology.md`, the Total row reads **94**, and the `create`,
      `update` and `prototype + design` rows read **19**, **19** and **25**. Every other row is
      unchanged, and the twelve unchanged rows still sum to **31** -- captured and recorded, so a
      compensating error cannot hide
- [ ] **The mirror was regenerated, not hand-edited, and the record says which.**
      `node site/scripts/sync-docs.mjs` is run; `git diff --name-only HEAD -- site/src/content/docs/`
      lists `concepts/methodology.md`, `reference/glossary.md` and `index.mdx` (plus `concepts/faq.md`
      and `reference/repository-structure.md` if the transform touched them) together with
      `site/scripts/.synced-manifest.json`; and re-running the script produces byte-identical output
- [ ] **The §7 correction is recorded as a correction**, with `sync-docs.mjs`'s `MANIFEST` cited: the
      two site files §7 called hand-maintained are sync targets, and the four-line offset is the
      transform. A record that hand-edits them and reports success would be wrong even if the bytes
      matched, because the next `prebuild` would overwrite them
- [ ] **The `prototype + design` row is 25 and the record states why it is not 22**, naming the three
      axes -- verb family (22, task-064's), catalog `group:` G3 (25) and this hand-curated table (25)
- [ ] **The `/aid-brainstorm` row decision is recorded** as a decision, with the choice made and the
      two figures it affects named
- [ ] **The Total row now carries an explicit noun and its current value (was M1).** After the edit
      each of the two tables' Total rows names what it counts rather than standing as a bare number,
      and the recorded figure is re-derived from disk at authoring time. The old oracle -- that the
      retired guard's `--list` print a claim for the row -- is superseded
      (`../../RESCOPE-COUNT-GUARD.md`); for any surface `tests/canonical/test-doc-counts.sh` asserts,
      that guard exiting **0** is the oracle, and for the rest it is a recorded `G-01` verdict
- [ ] **Every decomposition tail's operands moved and its arithmetic re-checks.** For each of
      `docs/glossary.md:68`, `docs/install.md:411`, `site/src/content/docs/index.mdx:77` and
      `docs/diagram-content-reference.md:24` and `:104`, the sentence is quoted before and after and its
      arithmetic is shown to hold at the new values
- [ ] **`diagram-content-reference.md:109` and `:111` were re-worded, not exempted**:
      `check-skill-counts.mjs` is **not** edited by this task (`git diff --exit-code -- tests/` is
      clean), and the record states the chosen phrasing
- [ ] **BLUEPRINT criterion 4's share, and the negative half.** Every edited figure is recorded as a
      triple -- quantity, before, after -- and in these files no phrasing of the **`shortcuts`
      (emitting)** quantity moved off **34**, no `curatedOnly` figure off **18**, no
      `classicRepurposed` figure off **3**, and no alias figure off **0**. `docs/glossary.md:54`'s
      *"34 verb-first shortcut doorways + 24 `repurpose` skills"* is the sharpest case: the 34 stays and
      the 24 becomes 60
- [ ] **No `release-tracking.md` entry was written.**
      `git diff --exit-code -- .aid/knowledge/release-tracking.md` is clean
- [ ] **No history apparatus and no work reference was introduced** in any edited file:
      `grep -cE 'work-[0-9]{3}'` per file captured to a variable -> `0`, and no `## Change Log` section
      or `changelog:` field was added
- [ ] **The guard is run over these files and its report recorded**, with every reported line either
      fixed here or recorded with the task that owns it
- [ ] **The site suite is green with no edit to it.** `cd site && npm test` passes and
      `git diff --exit-code -- site/scripts/__tests__/` is clean. A red suite here is a finding to
      report, not to fix by editing the suite
- [ ] Accuracy verified against the current codebase: every line number cited in this task's record is
      re-resolved against the file as it stands rather than carried from this DETAIL or from §7
- [ ] Nothing outside the declared writes moves:
      `git diff --exit-code -- canonical/ tests/ .aid/knowledge/ profiles/ .claude/ .cursor/
      site/src/content/docs/skills/ site/src/data/skill-flows/` is clean
- [ ] All section-6 quality gates pass
