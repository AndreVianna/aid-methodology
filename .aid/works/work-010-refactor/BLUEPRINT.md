# Delivery BLUEPRINT -- delivery-001: KB Index Routing-Table Restructure

> **Delivery:** delivery-001
> **Work:** work-010-refactor
> **Created:** 2026-08-12

---

## Objective

Restore `.aid/knowledge/INDEX.md` as a scannable RAG routing table by changing one generator's
rendering in two coupled ways: emit the six columns as
`Document | Audience | Tags | See-instead | Objective | Summary`, so the short near-fixed-width
fields a reader scans down sit adjacent and aligned ahead of the two long free-text fields; and
remove the `## Extension - project-specific (outside the declared default seed)` section, folding
its rows into the single alphabetical `## Primary - load-bearing knowledge` table, because
provenance is not routing information and the section's juxtaposition with "load-bearing" falsely
ranks three load-bearing docs as second-tier. `## Meta - process / ledger (review-exempt)` stays --
review-exemption *is* routing-relevant. The two changes are one indivisible restructure: shipping
either alone leaves a half-migrated table and forces every downstream oracle to be updated twice.

## Scope

- `canonical/aid/scripts/kb/build-kb-index.sh` -- the only hand-edited copy. Nine edit points
  (SPEC.md `### Layers & Components`): the awk-contract comment, the awk `END` cell-print order, the
  row-assembly cell-order comment, the `extension` -> `primary` category normalization in the
  row-assembly loop, the category iteration list, the section-heading `case` arms, the header +
  separator emission, the emitted `intent:` heredoc, and the emitted routing-table paragraph.
- The seven rendered twins of that script -- five `profiles/*/aid/scripts/kb/build-kb-index.sh` and
  the two dogfood copies (`.claude/aid/scripts/kb/`, `.cursor/aid/scripts/kb/`) -- produced by the
  FULL `python .claude/skills/generate-profile/scripts/run_generator.py`, never hand-edited.
- The regenerated `.aid/knowledge/INDEX.md`, produced by invoking the canonical script path.
- The test oracles that pin the old shape: `tests/canonical/test-build-kb-index.sh` (BI01's header
  and separator asserts, BI13, BI16 at lines 467-469 -- including the line-467 comment
  `# kb13 has all three categories; each must have exactly one header row.`, which the Extension
  fold-in falsifies -- and the BI13 section comments) and
  `tests/canonical/test-kb-forward-authored-marker.sh` (FI03).
- The repo-wide verification sweep (excluding `.git/`, `.aid/works/`, and `.aid/.temp/`, per
  AC-1/AC-12) for stale references and for any positional consumer of the rendered index
  (REQUIREMENTS.md §8).

**Out of scope:**

- **Retiring the `extension` value of `kb-category` project-wide -- confirmed decision, not to be
  re-opened.** `decisions.md`, `quality-gates.md`, and `release-tracking.md` keep
  `kb-category: extension` in their frontmatter. Only the index generator's *rendering* changes; the
  frontmatter lint, the KB review-surface scoping, the relationship-graph schema, the KB doc
  templates, and all of their tests continue to recognize `extension` unchanged.
- Changing which columns exist, their names, or what data composes each cell (the set stays at six;
  only the order changes).
- Changing the within-section alphabetical sort, the `Document` link form, the blank-cell rendering,
  the pipe-escaping, or the objective/summary fallback chain.
- **`.aid/knowledge/kb.html` -- the generated visual KB summary.** Produced by a DIFFERENT
  generator (the `/aid-summarize` skill), not by `build-kb-index.sh`: its own HTML markup, its own
  reduced column set (`<th>Document</th><th>Tags</th><th>Objective</th><th>Audience</th>` at
  `:3577`), its own lede prose (`:3565`), and its own `Extension &mdash; project-specific` grouping
  (`:3694`) -- none of which AC-1/AC-12's grep targets match. Residual, stated honestly: until
  `/aid-summarize`'s own grouping is revisited, `kb.html` still shows an Extension section, so the
  HTML summary and `INDEX.md` will disagree on grouping after this change. Not absorbed here.
- Editing any KB document's body or frontmatter; hand-editing `.aid/knowledge/INDEX.md`.
- Any performance change: the one-awk-subprocess-per-doc design is retained as-is. This is a
  `restructure`, so no benchmark, baseline, or target applies.

## Gate Criteria

- [ ] **AC-1 -- column order, no survivors.** A repo-wide `grep -rF` (excluding `.git/`,
      `.aid/works/`, and `.aid/.temp/` -- this work's own definition documents and its review
      ledger must quote the old strings in order to specify their removal, and a literal
      `grep -rF` honours no ignore rules)
      for `| Document | Objective | Summary | Tags | See-instead | Audience |` and for
      `|----------|-----------|---------|------|-------------|----------|` returns zero hits, and
      `grep -F "| Document | Audience | Tags | See-instead | Objective | Summary |"` hits in
      `canonical/aid/scripts/kb/build-kb-index.sh`, all five `profiles/*` renders, both dogfood
      renders, and `.aid/knowledge/INDEX.md`, each with its separator
      `|----------|----------|------|-------------|-----------|---------|` on the next line.
- [ ] **AC-2 -- cells align with the header.** For a fully populated row in the regenerated
      `.aid/knowledge/INDEX.md` (e.g. `architecture.md`), splitting the row on unescaped `|` yields
      cell 2 = that doc's `audience:` rendering, cell 3 = its backticked `tags:`, cell 4 = its
      `see_also:` links, cell 5 = its objective, cell 6 = its summary -- matching the awk `END`
      print order in `build-kb-index.sh`.
- [ ] **AC-3 -- no Extension heading.** `grep -c '^## Extension' .aid/knowledge/INDEX.md` is 0, and
      BI13's inverted `assert_file_not_contains "$OUT13" "## Extension"` passes against the retained
      three-category `kb13` fixture (which still contains `ext-doc.md`).
- [ ] **AC-4 -- extension rows fold into Primary alphabetically.** In `.aid/knowledge/INDEX.md` the
      `decisions.md`, `quality-gates.md`, and `release-tracking.md` rows are inside the
      `## Primary - load-bearing knowledge` table at their alphabetical positions -- `decisions.md`
      between `coding-standards.md` and `domain-glossary.md`, `quality-gates.md` between
      `project-structure.md` and `relationships.md`, `release-tracking.md` between `relationships.md`
      and `tech-debt.md` -- not appended as a trailing block; and BI13's new assertion places
      `ext-doc.md`'s row inside the Primary table.
- [ ] **AC-5 -- Meta survives unchanged.** `.aid/knowledge/INDEX.md` still contains
      `## Meta - process / ledger (review-exempt)`, it is the LAST `## ` heading in the file, and the
      table rows following it (up to the trailing `---` + regeneration-command footer) are exactly
      `README.md`, `STATE.md`, and `external-sources.md`.
- [ ] **AC-6 -- section count.** `grep -c '^## ' .aid/knowledge/INDEX.md` is 2 and
      `grep -cF "| Document | Audience | Tags | See-instead | Objective | Summary |"` on the same
      file is 2.
- [ ] **AC-7 -- identical row multiset.** Normalizing every document row of the pre-change and
      post-change `.aid/knowledge/INDEX.md` (split on unescaped `|`, sort the six cell contents,
      sort the rows) and diffing the two multisets yields exactly one difference: the `INDEX.md`
      row's own `Objective` cell, which FR-9 changes by design. Both sides carry the same 22
      document links; every other cell in every other row is byte-identical.
- [ ] **AC-8 -- frontmatter untouched.** `grep -l 'kb-category: extension' .aid/knowledge/*.md`
      still returns exactly `decisions.md`, `quality-gates.md`, and `release-tracking.md`; and
      `git diff` over `.aid/knowledge/` shows no added or removed frontmatter line (no `+`/`-` line
      matching `^[+-](kb-category|source|generator|objective|summary|sources|tags|see_also|owner|audience|contracts|intent|approved_at_commit):`)
      in any KB doc, and no KB doc other than the generated `INDEX.md` shows a body change.
- [ ] **AC-9 -- index regenerated and fresh.** Re-running
      `bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output <scratch>` and
      diffing `<scratch>` against the committed `.aid/knowledge/INDEX.md` with the
      `AUTO-GENERATED|Generated at:|: Generated$` lines filtered produces empty output -- i.e. the
      `kb-hygiene` "INDEX.md is fresh (regenerate + diff, timestamps filtered)" step passes.
- [ ] **AC-10 -- canonical / profiles / dogfood byte parity.** After a full
      `python .claude/skills/generate-profile/scripts/run_generator.py`, `git status --porcelain`
      shows no un-committed drift under `profiles/`, `.claude/`, or `.cursor/`; all seven rendered
      `build-kb-index.sh` copies contain the new header string; the per-profile emission manifests
      are updated; and `bash tests/canonical/test-dogfood-byte-identity.sh` exits 0.
- [ ] **AC-11 -- updated oracles pass.** `bash tests/canonical/test-build-kb-index.sh` and
      `bash tests/canonical/test-kb-forward-authored-marker.sh` each report 0 failures in their own
      summary line -- including BI01's new header and separator asserts, BI13's absent-Extension and
      Primary-placement asserts, BI16's new header pattern with expected count 2 and its reworded
      line-467 comment, and FI03's new header string -- the full canonical suite shows no new failures against the pre-change
      baseline, and the coverage-parity gate stays green (BI13 keeps at least its 6 tagged
      assertions per `tests/coverage-baseline.tsv`).
- [ ] **AC-12 -- no stale references.** A repo-wide grep (excluding `.git/`, `.aid/works/`, and
      `.aid/.temp/`, for the same reason as AC-1) for
      the old header string, the old separator string, `## Extension - project-specific`, and the
      prose phrase `Objective, Summary, Tags, See-instead, and Audience` returns zero hits; and the
      generator's `intent:` heredoc, its routing-table paragraph, its awk-contract comment, and its
      row-assembly cell-order comment each name the new order. A companion grep confirms no consumer
      parses `.aid/knowledge/INDEX.md` positionally by column index or greps for the `## Extension`
      heading outside the two updated oracles.
- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Reorder the index columns and fold Extension into Primary in the KB index generator |
| task-002 | TEST | Re-point the KB-index oracles at the new table shape and verify the restructure |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Shortcut-generated flattened Lite work. Source: /aid-refactor (refactor, artifact '').

The `extension` -> `primary` category normalization in the row-assembly loop is load-bearing, not
cosmetic: the replay stage emits a row only when the cached `doc_cat[i]` equals the category being
iterated, so dropping `extension` from the category loop WITHOUT that normalization silently deletes
the `decisions.md`, `quality-gates.md`, and `release-tracking.md` rows -- a row-set change that
violates the refactor invariant (AC-7). The two edits must land together. With the normalization in
place the fold-in needs nothing further: `all_docs` is already `find | sort`-ordered and the replay
preserves that order, so the folded rows interleave alphabetically for free (AC-4).
