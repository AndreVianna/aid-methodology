# task-001: Reorder the index columns and fold Extension into Primary in the KB index generator

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. This is the FLAT layout: there is no sibling
task-001/STATE.md -- this task's mutable cells live in the work-root STATE.md, section
`### Tasks lifecycle`.
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

**Type:** REFACTOR

**Source:** work-010-refactor -> delivery-001

**Depends on:** -- (none)

**Scope:**
- **Capture the pre-refactor baseline FIRST** (REFACTOR rule: full suite before, full suite
  after). Before touching any file, record the canonical suite's per-suite PASS/FAIL result set
  -- `bash tests/run-all.sh`, or the branch point's last green CI run if a local full run is not
  viable -- into a gitignored scratch file under `.aid/.temp/`. Read each suite's own summary
  line for counts; never grep over stdout. task-002 diffs against this file, so it must exist
  before the first edit.
- **Hand-edit exactly one file: `canonical/aid/scripts/kb/build-kb-index.sh`** (`set -eu` at
  L42; no `pipefail`). Ten edit sites, line numbers verified against the file on disk:
  1. **L97** -- the awk-contract comment inside the `# Per-doc render program` header block
     (L94-99). Reword the printed-line contract to
     `#     <kb-category>\n<aud_cell> | <tags_cell> | <see_cell> | <obj_cell> | <sum_cell>` so it
     does not go stale against edit 2.
  2. **L315** -- the awk `END` cell-print, the `print` immediately after `print cat` (L314).
     Reorder to `print aud_cell " | " tags_cell " | " see_cell " | " obj_cell " | " sum_cell`.
     **Order only:** no cell is recomputed, no blank-cell default (L308-312 -- the block runs
     `obj_cell`, `sum_cell`, `tags_cell`, `see_cell`, `aud_cell`, under the L307 comment) and no
     objective/summary coexistence fallback changes.
  3. **L486** -- the inline comment on `cells="${rendered#*$'\n'}"`. Reword to
     `# line 2: aud | tags | see | obj | sum`.
  4. **L482-489** -- the row-assembly caller loop. Insert ONE category normalization immediately
     after `cat_line="${rendered%%$'\n'*}"` (L485): when `cat_line` is `extension`, set it to
     `primary`. Write it as a full `if [[ ... ]]; then ...; fi` block, **not** as
     `[[ ... ]] && cat_line=primary` -- the script runs under `set -e`, so a trailing `&&`-list
     that evaluates false (i.e. every non-extension doc) aborts the loop. `doc_row+=` at L488 is
     unchanged: the row still gets the `Document` link prefix and the outer pipes.
  5. **L491** -- the category iteration loop becomes `for category in primary meta; do`. The
     `emitted_header` guard (L492, L495, L504, L510) is retained verbatim, so an empty category
     still emits nothing.
  6. **L496-500** -- the section-heading `case "$category"`. Delete the `extension)` arm (L499)
     only. The `primary)` (L497) and `meta)` (L498) arms, including their exact heading strings,
     are unchanged.
  7. **L502-503** -- header + separator emission. New header
     `| Document | Audience | Tags | See-instead | Objective | Summary |`, new separator
     `|----------|----------|------|-------------|-----------|---------|` -- each separator cell
     keeps the dash count that column has today.
  8. **L443-444** -- the emitted `intent:` heredoc sentence ("Each row carries Document,
     Objective, Summary, ..."). Same sentence, new column order.
  9. **L458** -- the emitted routing-table paragraph's first sentence (L458-460). Same paragraph,
     new column order; the trailing routing guidance (Objective+Tags to route, See-instead for
     negative routing, Audience to filter) is order-independent and keeps its wording.
  10. **L21-22 and L24-25** -- the script's own file-header comment block (the `# source:`
     paragraph). Both sentences go stale and must be reworded in this task. L21-22 reads
     `# source: value is a pass-through -- this generator groups docs strictly by` /
     `# kb-category (primary/meta/extension) and is source-value-agnostic.` -- false after edits
     4-6, because `extension` is no longer an emitted grouping; state that the generator groups
     by `kb-category` into the two emitted sections `primary` and `meta`, with docs declaring
     `kb-category: extension` folded into Primary. L24-25 reads `# The INDEX 6-column` /
     `# schema (Document/Objective/Summary/Tags/See-instead/Audience) is unchanged.` -- it names
     the OLD order; restate it as the 6-column schema
     `Document/Audience/Tags/See-instead/Objective/Summary` and drop the "is unchanged" claim.
     The intervening forward-authored sentence (L22-24, `A forward-authored (greenfield seed) doc
     with kb-category: primary renders in the Primary table identically to a hand-authored one.`)
     stays true and stays as-is. This is a comment-only edit: no code on these lines.
- **Edits 4 and 5 must land together.** The replay stage emits a row only when the cached
  `doc_cat[i]` equals the category being iterated, so dropping `extension` from the loop without
  the normalization silently deletes the `decisions.md`, `quality-gates.md`, and
  `release-tracking.md` rows -- a row-set change that violates the refactor invariant (AC-7).
  With the normalization in place nothing further is needed for alphabetical interleaving:
  `all_docs` is already `find | sort`-ordered and the replay preserves that order (AC-4).
- **Render the seven twins** with the FULL
  `python .claude/skills/generate-profile/scripts/run_generator.py` -- never a partial or
  per-script render, or `render-drift` fails on stale emission manifests. The twins are the five
  `profiles/*/.../aid/scripts/kb/build-kb-index.sh` and the two dogfood copies
  (`.claude/aid/scripts/kb/`, `.cursor/aid/scripts/kb/`). Hand-editing any of them is a defect.
- **Regenerate `.aid/knowledge/INDEX.md`** in the same change, via the canonical path --
  `bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md`
  -- not the `.claude/` copy: that command string is embedded in the generated file's own header
  and is checked by `kb-hygiene`.
- **Do NOT touch:** any test file (that is task-002's scope), any KB document's body or
  frontmatter, `.aid/knowledge/INDEX.md` by hand, the within-section sort, the `Document` link
  form, the blank-cell rendering, the pipe-escaping, or the one-awk-subprocess-per-doc design.
  This is a `restructure`, so no benchmark, baseline, or target applies to performance.

**Acceptance Criteria:**
- [ ] **AC-1.** A repo-wide `grep -rF` **excluding `.git/`, `.aid/works/`, and `.aid/.temp/`**
      (this work's own definition documents and its review ledger must quote the old strings in
      order to specify their removal, and a literal `grep -rF` honours no ignore rules) for
      `| Document | Objective | Summary | Tags | See-instead | Audience |` and for
      `|----------|-----------|---------|------|-------------|----------|` returns zero hits. The
      `.aid/works/` and `.aid/.temp/` exclusions are mandatory, not optional: this work's own
      REQUIREMENTS.md / SPEC.md / BLUEPRINT.md / task DETAIL.md files, and its review ledger under
      `.aid/.temp/review-pending/`, necessarily quote the old strings, so an unscoped grep can
      never come back clean. The new header string hits in
      `canonical/aid/scripts/kb/build-kb-index.sh`, all five `profiles/*` renders, both dogfood
      renders, and `.aid/knowledge/INDEX.md`, each with its new separator on the next line.
- [ ] **AC-2.** In the regenerated `.aid/knowledge/INDEX.md`, splitting a fully populated row
      (e.g. `architecture.md`) on unescaped `|` yields cell 2 = its `audience:` rendering,
      cell 3 = its backticked `tags:`, cell 4 = its `see_also:` links, cell 5 = its objective,
      cell 6 = its summary -- matching the awk `END` print order.
- [ ] **AC-3.** `grep -c '^## Extension' .aid/knowledge/INDEX.md` is 0.
- [ ] **AC-4.** In `.aid/knowledge/INDEX.md` the `decisions.md`, `quality-gates.md`, and
      `release-tracking.md` rows sit inside the `## Primary - load-bearing knowledge` table at
      their alphabetical positions -- `decisions.md` between `coding-standards.md` and
      `domain-glossary.md`, `quality-gates.md` between `project-structure.md` and
      `relationships.md`, `release-tracking.md` between `relationships.md` and `tech-debt.md` --
      not appended as a trailing block.
- [ ] **AC-5.** `## Meta - process / ledger (review-exempt)` is still emitted, is the LAST `## `
      heading in the file, and its rows are exactly `README.md`, `STATE.md`, and
      `external-sources.md`.
- [ ] **AC-6.** `grep -c '^## ' .aid/knowledge/INDEX.md` is 2, and `grep -cF` for the new header
      string on the same file is 2.
- [ ] **AC-7.** Normalizing every document row of the pre-change and post-change
      `.aid/knowledge/INDEX.md` (split on unescaped `|`, sort the six cell contents, sort the
      rows) and diffing the two multisets yields exactly one difference: the `INDEX.md` row's own
      `Objective` cell, which edit 8 changes by design. Both sides carry the same 22 document
      links; every other cell in every other row is byte-identical.
- [ ] **AC-8.** `grep -l 'kb-category: extension' .aid/knowledge/*.md` still returns exactly
      `decisions.md`, `quality-gates.md`, and `release-tracking.md`; `git diff` over
      `.aid/knowledge/` shows no added or removed frontmatter line in any KB doc and no body
      change to any KB doc other than the generated `INDEX.md`.
- [ ] **AC-9.** Re-running the canonical generator into a scratch file and diffing it against the
      committed `.aid/knowledge/INDEX.md` with the `AUTO-GENERATED|Generated at:|: Generated$`
      lines filtered produces empty output -- the `kb-hygiene` "INDEX.md is fresh" step passes.
- [ ] **AC-10.** After the full `run_generator.py`, `git status --porcelain` shows no
      un-committed drift under `profiles/`, `.claude/`, or `.cursor/`; all seven rendered
      `build-kb-index.sh` copies contain the new header string; the per-profile emission
      manifests are updated; and `bash tests/canonical/test-dogfood-byte-identity.sh` exits 0.
- [ ] **AC-12 (generator side).** The generator's `intent:` heredoc, its routing-table paragraph,
      its awk-contract comment, its row-assembly cell-order comment, and its own file-header
      `# source:` comment block (edit 10) each name the new order; no occurrence of the prose
      phrase `Objective, Summary, Tags, See-instead, and Audience` survives anywhere outside
      `.git/`, `.aid/works/`, and `.aid/.temp/` (the same three-directory exclusion set as AC-1
      above, and for the same reason). **Slash-separated forms are checked separately, because
      neither AC-1's pipe-separated header string nor the prose phrase above matches them:**
      (a) `grep -rF 'Document/Objective/Summary/Tags/See-instead/Audience'` under the same
      exclusion set returns zero hits (today it hits exactly L25 of the canonical generator and of
      its seven rendered twins, and nowhere else in the repo); and (b)
      `grep -n 'primary/meta/extension' canonical/aid/scripts/kb/build-kb-index.sh` returns zero
      hits, with the same check on all seven twins. Check (b) is deliberately scoped to that one
      file and its renders rather than repo-wide: the identical string legitimately survives in
      `aid/scripts/connectors/build-connectors-index.{sh,ps1}` and in
      `aid/templates/kb-authoring/review-rubric.md`, where it names the unchanged `kb-category:`
      frontmatter enum (AC-8 keeps that enum intact), not an emitted grouping.
- [ ] **REFACTOR invariant, and the justified test failures.** The pre-refactor baseline was
      captured before the first edit. After this task, the ONLY new failures anywhere in the
      canonical suite are these five assertions, each of which pins the pre-change *rendering*
      (implementation) rather than behavior: `test-build-kb-index.sh` BI01 header (L102), BI01
      separator (L104), BI13 `## Extension` (L403), BI16 header count (L468-469), and
      `test-kb-forward-authored-marker.sh` FI03 (L381). That list -- and the pre-refactor
      baseline file -- is recorded and handed to task-002; any sixth new failure is a defect in
      this task, not a test to update.
- [ ] All section-6 quality gates pass.
