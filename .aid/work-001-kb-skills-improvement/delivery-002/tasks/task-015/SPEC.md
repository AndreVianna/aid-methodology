# task-015: INDEX routing-table emission in build-kb-index.sh + coexistence fallbacks

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-002

**Depends on:** task-002 (delivery-001)

**Scope:**
- Flip `canonical/aid/scripts/kb/build-kb-index.sh` from the current per-category prose-`intent:`
  list (current lines 157-193) to a per-category 6-column markdown routing table with header
  `| Document | Objective | Summary | Tags | See-instead | Audience |`. Preserve the `kb-category`
  grouping (`## Primary` / `## Meta` / `## Extension`, category order `primary -> meta -> extension`),
  the `find ... | sort` within-group alphabetical ordering (line 150), the AUTO-GENERATED markers +
  generated-doc frontmatter (lines 117-143), the empty-KB / missing-category guards (lines 152-155),
  and the trailing `---` + regen footer (lines 195-197). Reword the prose lead-in (lines 138-141) to
  describe the table instead of "each doc's `intent:` field" (no timestamp added).
- Compose each row mechanically from frontmatter: `objective`/`summary` via the existing
  `extract_field`; `tags`/`see_also`/`audience` via `extract_list` (consumed from f001/task-002 --
  add NO new parser primitive). Render rules per f002 SPEC "Cell -> frontmatter mapping": Document =
  `[name](../knowledge/name)` link; Tags = inline-code, comma-joined; See-instead = doc-name link for
  `*.md`/bare-token entries, verbatim for prose entries, comma-joined; Audience = role labels
  comma-joined verbatim. Omit `owner:` (not an INDEX column). Drop the `source: generated` italic
  per-row note (lines 183-187) -- does not fit a cell.
- Cell-safety: escape every literal `|` in a cell to `\|`; an empty cell renders as a single space.
- Coexistence fallbacks (REQUIRED, per f002 SPEC "Coexistence fallback"): Objective falls back to the
  collapsed single-line `intent:` (via `extract_literal`, join-on-spaces + squeeze-whitespace) when
  `objective:` is absent, else `*(no objective declared)*` when both absent. Summary falls back to the
  first sentence of the collapsed `intent:` using the bounded deterministic predicate -- first match of
  `[.!?](?=[ \t]+[A-Z]|$)` over the collapsed line (terminator included), no-boundary => whole line,
  hard caps: cut at first newline then truncate at 200 chars with ASCII `...`; blank when `intent:` also
  absent. Tags/See-instead/Audience render blank when their source list is absent/empty.
- Determinism: output is a pure function of (sorted file list x frontmatter); no `date`-derived content
  in any cell; all introduced literals ASCII.
- Regenerate AID's own `.aid/knowledge/INDEX.md` to the table form and commit it in this change (keeps
  INDEX-fresh CI green -- it will render from the existing `intent:` fallbacks).
- Re-run `python .claude/skills/generate-profile/scripts/run_generator.py` and commit the regenerated
  `profiles/` (keeps render-drift green; edit canonical only, never hand-edit a rendered copy).
- Boundary: this task OWNS the table render. It does NOT ASCII-clean the script or wire the ASCII guard
  (task-016), does NOT add the canonical test suite (task-017), does NOT touch f001's schema/parser
  (delivery-001) or f011's migration (delivery-003).

**Acceptance Criteria:**
- [ ] When `build-kb-index.sh` runs, `INDEX.md` is the generated per-category routing table with
  columns Document | Objective | Summary | Tags | See-instead | Audience. *(f002 AC4)*
- [ ] Category grouping (`primary -> meta -> extension`), within-group alphabetical `sort` order,
  AUTO-GENERATED markers, generated-doc frontmatter, empty-KB guard, and regen footer are all
  preserved.
- [ ] Each cell is composed deterministically from frontmatter via `extract_field`/`extract_list`
  (no new parser primitive; no LLM); identical inputs yield byte-identical output modulo the two
  CI-filtered timestamp lines.
- [ ] Document renders as `[name](../knowledge/name)`; Tags as comma-joined inline-code; See-instead as
  doc-name links (verbatim for prose entries); Audience comma-joined verbatim; `owner:` omitted; the
  `source: generated` per-row note is dropped.
- [ ] A literal `|` in any cell is escaped to `\|`; an empty cell renders as a single space.
- [ ] Objective falls back to the collapsed `intent:` when `objective:` absent (`*(no objective
  declared)*` when both absent); Summary falls back to the first sentence via the
  `[.!?](?=[ \t]+[A-Z]|$)` predicate (whole line when no boundary; 200-char cap with ASCII `...`),
  blank when `intent:` absent; Tags/See-instead/Audience blank when absent -- an un-migrated
  `intent:`-only KB still renders a valid table.
- [ ] AID's own `.aid/knowledge/INDEX.md` is regenerated to the table form and committed in this change
  (INDEX-fresh CI step stays green).
- [ ] `run_generator.py` re-run and regenerated `profiles/` committed; no rendered copy hand-edited
  (render-drift green).
- [ ] All section-6 quality gates pass.
