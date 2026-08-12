# KB Index Routing-Table Restructure

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-12 | SPEC authored from REQUIREMENTS.md | /aid-refactor |
| 2026-08-12 | GATE Pass 1 FIX cycle 1 -- scoped AC-1/AC-12 and the verification sweep to exclude `.git/` and `.aid/works/`; replaced the unsupported test-landscape cite with the `run-all.sh` glob mechanism; recorded the `set -eu` vs `set -euo pipefail` deviation as do-not-fix; added the `.aid/knowledge/kb.html` out-of-scope carve-out with its residual | /aid-refactor GATE |
| 2026-08-12 | GATE Pass 2 FIX cycle 1 -- cross-pass correction: BI16 comments at test L21/L465 are stale too | /aid-refactor GATE |

## Source

- REQUIREMENTS.md §1 Objective, §2 Problem Statement — motivation for both structural changes
- REQUIREMENTS.md §4 Scope — the edit surface (in scope) and the confirmed `kb-category: extension` carve-out (out of scope)
- REQUIREMENTS.md §5 Functional Requirements — FR-1..FR-12, the behavioral contract
- REQUIREMENTS.md §6 Non-Functional Requirements — the behavior-preservation invariant and its one documented exception
- REQUIREMENTS.md §7 Constraints — canonical-only editing, full-generator render, byte-identity and INDEX.md-freshness gates
- REQUIREMENTS.md §8 Assumptions & Dependencies — the no-positional-consumer assumption to re-verify
- REQUIREMENTS.md §9 Acceptance Criteria — AC-1..AC-12, carried 1:1 below
- REQUIREMENTS.md §10 Priority — Must, indivisible

## Description

`.aid/knowledge/INDEX.md` is AID's RAG routing table: every dispatched agent loads it to
decide which KB doc to read. Two structural properties of the generated table work against
that job. First, the two long free-text columns (`Objective`, `Summary`) sit at positions 2
and 3, so the short, near-fixed-width columns a reader actually scans down (`Audience`,
`Tags`, `See-instead`) start at a different horizontal offset on every row. Second, the
table is split into three sections, one of which — `## Extension - project-specific
(outside the declared default seed)` — groups rows by **provenance**, which is not routing
information and which falsely implies its three docs are less load-bearing than the Primary
ones.

This change reorders the emitted columns to `Document | Audience | Tags | See-instead |
Objective | Summary` and folds `extension`-category rows into the Primary table's single
alphabetical sort, removing the Extension section entirely. The `Meta` section stays:
review-exemption *is* routing-relevant.

Only the index generator's rendering changes. No row is added or dropped, no cell is
recomposed, no frontmatter field changes meaning, and `kb-category: extension` remains a
valid, recognized value everywhere else in the toolchain.

## User Stories

- As a dispatched AID agent loading the KB index, I want the short discriminating columns
  (`Audience`, `Tags`, `See-instead`) adjacent and vertically aligned so that I can route to
  the right doc without re-parsing every row.
- As a human maintainer reading the index, I want section headings that reflect how a doc is
  *used* rather than where it came from so that I am not misled into treating
  `decisions.md` or `quality-gates.md` as second-rank.
- As the AID repo maintainer, I want the change confined to `canonical/` and rendered
  mechanically to every copy so that render-drift, byte-identity, and INDEX.md-freshness
  gates all stay green.

## Priority

**Must.** The two changes are a single indivisible restructure of one generator's rendering;
a half-migrated table (reordered but still carrying the Extension heading, or folded but with
the old column order) would force every downstream oracle to be updated twice.

## Acceptance Criteria

- [ ] **AC-1 (column order).** Given any KB corpus, when the generator runs, then every table
      header it emits is exactly `| Document | Audience | Tags | See-instead | Objective | Summary |`
      immediately followed by `|----------|----------|------|-------------|-----------|---------|`,
      and no occurrence of the old header string survives anywhere in the repository, excluding
      `.git/`, `.aid/works/`, and `.aid/.temp/` (canonical, the seven renders,
      `.aid/knowledge/INDEX.md`, or any test). `.aid/works/` and `.aid/.temp/` are excluded because
      this work's own definition documents and its review ledgers must quote the old strings in
      order to specify their removal.
- [ ] **AC-2 (cells align with header).** Given a doc with all six fields populated, when its row
      is emitted, then cell 2 is its `audience` rendering, cell 3 its `tags`, cell 4 its
      `see_also`, cell 5 its objective, and cell 6 its summary.
- [ ] **AC-3 (no Extension heading).** Given a corpus containing at least one doc with
      `kb-category: extension`, when the generator runs, then the output contains no line
      beginning `## Extension`.
- [ ] **AC-4 (extension rows under Primary).** Given that same corpus, when the generator runs,
      then each `extension`-category doc's row appears inside the `## Primary - load-bearing
      knowledge` table in the single alphabetical sort with the `primary` docs — for this repo,
      `decisions.md` between `coding-standards.md` and `domain-glossary.md`, `quality-gates.md`
      between `project-structure.md` and `relationships.md`, and `release-tracking.md` between
      `relationships.md` and `tech-debt.md` — not appended as a trailing block.
- [ ] **AC-5 (Meta survives unchanged).** Given the repo corpus, when the generator runs, then
      `## Meta - process / ledger (review-exempt)` is still emitted, is the second and last
      section, and its table holds exactly `README.md`, `STATE.md`, and `external-sources.md`.
- [ ] **AC-6 (section count).** Given the repo corpus, when the generator runs, then exactly two
      `## ` section headings and exactly two header rows are emitted.
- [ ] **AC-7 (identical row set and cell content).** Given the pre-change and post-change
      `.aid/knowledge/INDEX.md`, when each row is normalized by sorting its six cell contents and
      the two row multisets are compared, then they are identical — same 22 document links, same
      cell values — with exactly one documented exception: the `INDEX.md` row's own `Objective`
      cell, which changes because FR-9 corrects the generator-emitted `intent:` prose that
      composes it. Every other cell in every other row is byte-identical to before.
- [ ] **AC-8 (frontmatter untouched).** Given `decisions.md`, `quality-gates.md`, and
      `release-tracking.md`, when the change is complete, then each still carries
      `kb-category: extension`, and no frontmatter field of any KB doc was modified.
- [ ] **AC-9 (index regenerated and fresh).** Given the committed `.aid/knowledge/INDEX.md`, when
      the canonical generator is re-run into a scratch file and both are diffed with the
      `AUTO-GENERATED|Generated at:|: Generated$` lines filtered, then the diff is empty — i.e.
      the `kb-hygiene` "INDEX.md is fresh" step passes.
- [ ] **AC-10 (canonical / profiles / dogfood byte parity).** Given the edited canonical script,
      when the full `run_generator.py` runs, then all five `profiles/*` copies and both dogfood
      copies (`.claude/aid/scripts/kb/`, `.cursor/aid/scripts/kb/`) carry the change, the working
      tree shows no uncommitted render drift, the per-profile emission manifests are updated, and
      `test-dogfood-byte-identity.sh` passes.
- [ ] **AC-11 (updated oracles pass).** Given the updated test files, when
      `tests/canonical/test-build-kb-index.sh` and
      `tests/canonical/test-kb-forward-authored-marker.sh` run, then every assertion passes —
      including BI01 asserting the new header and separator strings, BI13 asserting the Extension
      heading is absent and the `extension` fixture doc's row is in the Primary table, BI16
      asserting the new header string with an expected count of 2, and FI03 asserting the new
      header string — and the full canonical suite reports no new failures against the pre-change
      baseline.
- [ ] **AC-12 (no stale references).** Given a repo-wide grep — excluding `.git/`,
      `.aid/works/`, and `.aid/.temp/`, because this work's own definition documents and its
      review ledgers must quote the old strings in
      order to specify their removal — for the old header string, the old
      separator string, `## Extension - project-specific`, and the prose phrase "Objective,
      Summary, Tags, See-instead, and Audience", when the change is complete, then every remaining
      hit is either absent or updated to the new order — including the generator's `intent:`
      heredoc, its routing-table paragraph, the awk-contract comment, and the row-assembly
      cell-order comment.

---

## Technical Specification

### Data Model

Unchanged — behavior-preserving refactor. No schema, no persistence, no frontmatter field is
touched; `kb-category: extension` remains a valid recognized value everywhere outside the index
generator's rendering (REQUIREMENTS.md §4 Out of Scope, AC-8).

### Feature Flow

Unchanged — behavior-preserving refactor. The pipeline
(`find` KB docs -> sort -> one `awk` subprocess per doc -> cache category + cells -> replay the
cache grouped by category -> write `$OUTPUT`) keeps its shape, its one-awk-pass-per-doc design
(lines 476-489), and its fallback chain (lines 285-312). Only what the replay stage renders
changes.

### Layers & Components

**Single hand-edited component: `canonical/aid/scripts/kb/build-kb-index.sh`** (8 copies exist
on disk; 7 are renders — see Downstream render surface). Line numbers verified against the file
on disk at authoring time.

| # | Line(s) | Block | Current behavior | Target behavior | FR |
|---|---------|-------|------------------|-----------------|----|
| 1 | 97 | awk-contract comment in the per-doc render program header | Documents awk's 2-line output as `<kb-category>\n<obj_cell> \| <sum_cell> \| <tags_cell> \| <see_cell> \| <aud_cell>` | Second line reworded to `<aud_cell> \| <tags_cell> \| <see_cell> \| <obj_cell> \| <sum_cell>` so the comment does not go stale against edit 2 | FR-4 |
| 2 | 315 | awk `END` block, cell-print statement | `print obj_cell " \| " sum_cell " \| " tags_cell " \| " see_cell " \| " aud_cell` | `print aud_cell " \| " tags_cell " \| " see_cell " \| " obj_cell " \| " sum_cell` — order only; no cell is recomputed | FR-3, AC-2 |
| 3 | 486 | row-assembly loop, inline comment on `cells=` | `# line 2: obj \| sum \| tags \| see \| aud` | `# line 2: aud \| tags \| see \| obj \| sum` | FR-4 (extension), AC-12 |
| 4 | 482-489 | row-assembly caller loop | Caches `doc_cat[i]="$cat_line"` verbatim and `doc_row[i]="\| [name](../knowledge/name) \| ${cells} \|"` | Row assembly unchanged (still prefixes the `Document` link and wraps with outer pipes). Add a single category normalization immediately after `cat_line` is extracted: when `cat_line` is `extension`, set it to `primary`. **This normalization is what makes edit 5 safe** — see Trap below | FR-3, FR-6 |
| 5 | 491 | category iteration loop | `for category in primary meta extension; do` | `for category in primary meta; do`. The `emitted_header` guard (492, 495, 504, 510) is retained verbatim, so an empty category still emits nothing | FR-5, FR-8 |
| 6 | 496-500 | section-heading `case "$category"` | Three arms: `primary)`, `meta)`, `extension)` | Drop the `extension)` arm (line 499) entirely; `primary)` and `meta)` unchanged, including their heading strings | FR-5, FR-7, AC-3, AC-5 |
| 7 | 502-503 | header + separator emission | `\| Document \| Objective \| Summary \| Tags \| See-instead \| Audience \|` / `\|----------\|-----------\|---------\|------\|-------------\|----------\|` | `\| Document \| Audience \| Tags \| See-instead \| Objective \| Summary \|` / `\|----------\|----------\|------\|-------------\|-----------\|---------\|` — each cell keeps the dash count it has today for that column | FR-1, FR-2, AC-1 |
| 8 | 441-445 | emitted `intent:` heredoc (frontmatter of the generated file) | "Each row carries Document, Objective, Summary, Tags, See-instead, and Audience columns composed from frontmatter." | Same sentence with the new column order | FR-9, AC-7, AC-12 |
| 9 | 458-460 | emitted routing-table paragraph | "Routing table: each row is a KB doc with Objective, Summary, Tags, See-instead, and Audience columns ... Use Objective+Tags to route ..." | Same paragraph with the new column order; the trailing routing guidance (Objective+Tags to route, See-instead for negative routing, Audience to filter) is order-independent and keeps its meaning | FR-9, AC-12 |

**Trap (ordering dependency between edits 4 and 5).** Edits 4 and 5 must land together. `doc_cat[i]`
holds the raw awk-emitted category, and the replay loop emits a row only when `doc_cat[i]` equals the
category being iterated. Dropping `extension` from the loop (edit 5) *without* the normalization
(edit 4) silently drops all three extension docs' rows from the output — a row-set change, which
would violate the refactor invariant (AC-7). With the normalization in place the fold-in needs
nothing else: `all_docs` is already `find | sort`-ordered and the replay preserves that order, so the
folded rows interleave alphabetically for free (AC-4) rather than appending as a block.

**Conventions to hold** (`.aid/knowledge/coding-standards.md`): `#!/usr/bin/env bash` (line 1
already complies); the frontmatter parsing stays in awk with no new `yq`/`python` dependency; no
new tool is introduced.

**Documented deviation — do NOT "fix" it.** `coding-standards.md:102` states `set -euo pipefail`,
but `canonical/aid/scripts/kb/build-kb-index.sh:42` is `set -eu` (no `pipefail`). That line stays
exactly as found. Adding `-o pipefail` during this behavior-preserving refactor is **out of scope
and an unscoped behavior change**: the script contains unguarded pipelines (e.g. line 521,
`SIZE=$(wc -c < "$OUTPUT" | tr -d ' ')`) whose failure behavior would change, and AC-7's
row-multiset check would not detect the regression. Bringing the file to the full convention is a
separate, independently-verified change. The one-awk-subprocess-per-doc design is retained as-is — this is a
`restructure`, not a `performance` refactor, so no benchmark, baseline, or target applies.

**Downstream render surface** (all machine-produced; hand-editing any of them is a defect —
`.aid/knowledge/architecture.md` "Editing a rendered/vendored copy does nothing"):

- Five profile renders: `profiles/antigravity/.agent/`, `profiles/claude-code/.claude/`,
  `profiles/codex/.codex/`, `profiles/copilot-cli/.github/`, `profiles/cursor/.cursor/` — each at
  `aid/scripts/kb/build-kb-index.sh`.
- Two dogfood renders: `.claude/aid/scripts/kb/build-kb-index.sh`,
  `.cursor/aid/scripts/kb/build-kb-index.sh`.
- Produced by the **full** `python .claude/skills/generate-profile/scripts/run_generator.py` — never
  a partial or per-script render, or CI `render-drift` fails on stale emission manifests
  (`.aid/knowledge/architecture.md` Gotchas).
- `.aid/knowledge/INDEX.md`, regenerated in the same commit with
  `bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md`
  — the canonical path, not the `.claude/` copy, because the regeneration command is embedded in the
  file's own header comment and checked by `kb-hygiene`.

**Not a render surface, and out of scope: `.aid/knowledge/kb.html`.** The generated visual KB
summary carries the same `Extension &mdash; project-specific` grouping (`:3694`) and column-order
prose (`:3565`) this work removes from `INDEX.md`, but it is produced by a *different* generator —
the `/aid-summarize` skill — with its own HTML markup and its own reduced column set
(`<th>Document</th><th>Tags</th><th>Objective</th><th>Audience</th>`, `:3577`). None of AC-1's or
AC-12's grep targets match those strings, by design. Residual, stated honestly: until
`/aid-summarize`'s own grouping is revisited, `kb.html` still shows an Extension section, so the two
views of the KB will disagree on grouping after this change. That reconciliation belongs to a change
against `/aid-summarize`, not here; `kb.html` is not to be edited by this work.

**Test oracles** (both suites run in the canonical suite by virtue of `run-all.sh`'s
`tests/canonical/test-*.sh` glob — that glob, not the KB, is the enrolment mechanism.
`.aid/knowledge/test-landscape.md:135` enumerates `test-build-kb-index.sh` but does not enumerate
`test-kb-forward-authored-marker.sh` anywhere, so the KB does not document that second suite.
`render-drift` and `test-dogfood-byte-identity.sh` cover the render direction):

| Oracle | Line(s) | Change |
|--------|---------|--------|
| `tests/canonical/test-build-kb-index.sh` BI01 | 102, 104 | Header-string assert and separator-string assert both updated to the new strings. REQUIREMENTS §5 FR-12 names only line 102; the separator assert at line 104 is required by AC-1 and must move with it |
| `tests/canonical/test-build-kb-index.sh` BI13 | 18, 371, 403, +new | Section comments at 18 and 371 reworded ("category grouping" now means primary/meta with extension folded in); line 403's `assert_file_contains "$OUT13" "## Extension"` inverted to `assert_file_not_contains` (helper exists, `tests/lib/assert.sh:77`); add an assertion that `ext-doc.md`'s row is inside the Primary table. The three-category `kb13` fixture, including the `ext-doc.md` block at 389-395, is retained so the fold-in is actually exercised. Asserts 401-402 and 406-408 unchanged |
| `tests/canonical/test-build-kb-index.sh` BI16 | 21, 465, 467-469 | `grep -c` pattern updated to the new header string; expected count drops 3 -> 2 for the `kb13` fixture. The comment at 467 (`# kb13 has all three categories; each must have exactly one header row.`) is falsified by the Extension fold-in and must be reworded with them -- `kb13` still declares three categories, but only two emit a header row. Comments at 21 and 465 carry the SAME falsified "once per category" framing (`Table header row emitted once per category (6-column header + separator).` / `... (6-column header).`) and are reworded with them to "once per *emitted* section"; the 6-column part stays true, only the order changed |
| `tests/canonical/test-kb-forward-authored-marker.sh` FI03 | 381 | `grep -qF` header string updated to the new order; the "6-column ... schema unchanged" framing stays true |

**Coverage-parity gate.** `tests/coverage-baseline.tsv` is committed and therefore enforcing. It
records per-suite assertion-ID counts — `test-build-kb-index.sh BI01 10`, `BI13 6`, `BI16 1`. The
BI13 change must keep at least 6 BI13-tagged assertions (inverting one assert preserves the count;
the new Primary-placement assert is a net add, which the gate permits). BI01 and BI16 counts are
unchanged. No accept-list row or baseline re-bootstrap should be needed.

**Verification sweep before declaring done** (REQUIREMENTS.md §8): repo-wide grep (excluding
`.git/`, `.aid/works/`, and `.aid/.temp/`, per AC-1/AC-12) confirming no
consumer parses `.aid/knowledge/INDEX.md` positionally by column index or greps for the `## Extension`
heading outside the two oracles above. Spot-checked at authoring time — the dashboard readers'
`INDEX.md` handling (`dashboard/reader/parsers.py`, `dashboard/server/reader.mjs`) refers to the
connectors index and to skip-lists by filename, not to the KB routing table's columns.
