# task-051: summary-src sections + kb.html regen (Playwright visual gate)

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-008

**Depends on:** task-050

**Scope:**
- f009 Part 3 row 14 + Part 4 (S9/S12, AC12) -- the built KB-summary artifact and its source of
  truth. `.aid/dashboard/kb.html` is the committed built artifact (meta `generator="aid-summarize"`,
  written per `canonical/skills/aid-summarize/references/state-writeback.md:19`); its **source of
  truth is `.aid/knowledge/summary-src/sections/*.html`**. Fix the source sections FIRST, then
  re-run the `aid-summarize` render path so `kb.html` regenerates -- **never hand-edit `kb.html`**.
- **Summary HTML sections (S9 -- edit by hand):**
  - `summary-src/sections/02-the-pipeline.html` -- rename the mermaid `ASK` node id + label (l.29)
    **and its edge reference `DSC -. optional .-> ASK` (l.46)** to the new id consistently (rename
    the node id, NOT just its label, or the renamed node dangles / mermaid creates a duplicate), and
    the caption (l.49) to `aid-query-kb`; optionally add an `aid-update-kb` node. **Bump the
    "five optional skills" count -> six** (caption l.49 + the body enumeration l.8): aid-update-kb is
    a new optional skill, so the optional-skill count goes 5 -> 6 -- a count-only surface that carries
    no `aid-ask`/`12 skills` token, so it needs its own `five optional` grep.
  - `summary-src/sections/03-phases-and-skills.html` -- rename the `/aid-ask` card (l.163) to
    `/aid-query-kb`; add an `aid-update-kb` card.
  - `summary-src/sections/06-pipeline-contracts.html` -- `<h3>... (12 skills)</h3>` (l.8) ->
    `(13 skills)`; rename the `/aid-ask` contract row (l.24) to `/aid-query-kb`; add an
    `aid-update-kb` contract row.
  - `summary-src/sections/12-documentation-surface.html` -- **count-only surface with NO `aid-ask`
    token** (l.12 "Mermaid flowchart + 12 skills"): bump "12 skills" -> "13 skills". A
    `grep aid-ask` alone MISSES this section -- it needs its own `12 skills` grep.
- **Regenerate kb.html (S12 -- generated, not hand-edited):** re-run the `aid-summarize` render
  path so `.aid/dashboard/kb.html` regenerates from the edited `summary-src` with
  `aid-query-kb`/`aid-update-kb` and "13 skills", removing the stale `aid-ask` refs
  (l.792/812/984/1176) and both "12 skills" counts (l.1160/1723).
- **Playwright visual-validation gate (machine-global hard rule -- web-review gate):** the
  regenerated `kb.html` renders to a web summary page, so the review MUST load it in Playwright,
  screenshot it, and confirm the pipeline mermaid figure + skill cards + the slash-command-contract
  table render with the new skills. **Source-only inspection is an automatic FAIL.**
- **Out of scope:** KB-doc prose counts + INDEX + narrative (task-050); docs-site `gen-reference.mjs`
  + `skills.md` + dogfood (task-052).

**Acceptance Criteria:**
- [ ] `grep -rn 'aid-ask' .aid/knowledge/summary-src/sections/` is empty AND
  `grep -rn '12 skills' .aid/knowledge/summary-src/sections/` is empty (the section-12 count-only
  surface, which carries no `aid-ask` token, was caught by its own grep).
- [ ] `grep -rn 'five optional\|5 optional' .aid/knowledge/summary-src/sections/02-the-pipeline.html`
  is empty (the optional-skill count was bumped 5 -> 6 in both the caption l.49 and the body
  enumeration l.8 -- a count-only surface with no `aid-ask`/`12 skills` token).
- [ ] In `02-the-pipeline.html` the mermaid node id `ASK` is renamed consistently: `grep -n 'ASK'`
  finds no orphaned references -- the node DEF (l.29) AND the edge `DSC -. optional .-> ASK` (l.46)
  both use the new id, so the diagram is internally consistent (no dangling/duplicate node).
- [ ] The summary sections render `aid-query-kb` (mermaid node + label + caption + card + contract
  row) and add an `aid-update-kb` card + contract row; both "12 skills" counts (section 06 + section
  12) are now "13 skills".
- [ ] `.aid/dashboard/kb.html` is REGENERATED via the `aid-summarize` render path (not hand-edited);
  `grep -n "aid-ask\|12 skills" .aid/dashboard/kb.html` is empty; `aid-query-kb`/`aid-update-kb`
  and "13 skills" appear.
- [ ] **Playwright visual validation:** the regenerated `kb.html` is loaded in Playwright and
  screenshotted; the pipeline mermaid figure, skill cards, and slash-command-contract table render
  correctly with the new skill set. (Source-only review of this artifact is an automatic FAIL.)
- [ ] No KB-doc prose count / INDEX / docs-site / dogfood surface is edited in this task (those are
  task-050 / task-052).
- [ ] All section-6 quality gates pass.
