# Requirements

- **Name:** KB Index Routing-Table Restructure
- **Description:** Reorder the generated KB index routing-table columns so the short fixed-width fields come before the two long free-text ones, and fold the Extension section's rows into Primary, changing only the index generator's rendering

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-12 | Initial capture (shortcut: aid-refactor) | /aid-refactor |
| 2026-08-12 | GATE Pass 1 FIX cycle 1 -- scoped the AC-1/AC-12 repo-wide greps to exclude `.git/` and `.aid/works/`; added the line-486 comment, the old separator string, and the BI01 line-104 assert as edit targets; corrected the test-landscape/architecture cites and four line ranges; recorded the `set -eu` deviation and the `kb.html` out-of-scope carve-out | /aid-refactor GATE |
| 2026-08-12 | GATE Pass 1 FIX cycle 2 -- extended two KB cite ranges to bullet boundaries and added the dogfood-tree cite; added `.aid/.temp/` to the AC-1/AC-12 grep exclusions; extended the BI16 edit scope to the line-467 comment | /aid-refactor GATE |

## 1. Objective

Make `.aid/knowledge/INDEX.md` scannable again. The index is AID's RAG routing
table — every agent task prompt loads it so the agent can pick which KB doc to
read. Two structural properties currently work against that job:

1. The two longest, most variable free-text columns (`Objective`, `Summary`) sit
   in the middle of the row, pushing the short fixed-width columns (`Tags`,
   `See-instead`, `Audience`) out of vertical alignment and destroying
   column-to-column scannability.
2. The table is split into three sections, one of which — `Extension -
   project-specific (outside the declared default seed)` — groups rows by
   **provenance**, which is not routing information.

The change is a pure restructure of how the index generator renders. No row is
added or dropped, no cell is recomposed, no frontmatter field changes meaning.

## 2. Problem Statement

**Column order.** The routing table is emitted today as:

```
| Document | Objective | Summary | Tags | See-instead | Audience |
```

`Objective` and `Summary` are free prose lifted from each doc's frontmatter and
routinely run to several hundred characters (see
`.aid/knowledge/INDEX.md:31-45`). Because they are columns 2 and 3, the
short, near-fixed-width columns that a reader actually scans down — `Tags`,
`See-instead`, `Audience` — start at a different horizontal offset on every
row. The reader cannot run an eye down a column; they must re-parse each row.

**False section rank.** `.aid/knowledge/INDEX.md:55` emits `## Extension -
project-specific (outside the declared default seed)`, holding `decisions.md`,
`quality-gates.md`, and `release-tracking.md` (lines 59-61). The section header
says these docs sit outside the default seed — a *provenance* fact — while the
peer section is labelled `## Primary - load-bearing knowledge`. The juxtaposition
implies these three are less load-bearing, which is false: `decisions.md` and
`quality-gates.md` are as load-bearing as any doc in Primary. Provenance is not
a routing signal, so it does not belong in a routing table — and nothing is lost
by dropping it, because provenance still lives in each doc's own
`kb-category:` frontmatter field and in the doc-set tracker at
`.aid/knowledge/README.md:38-59`.

The `## Meta - process / ledger (review-exempt)` section is a different case and
stays: review-exemption *is* a routing-relevant distinction (it tells a reader
those docs are process/ledger state, not knowledge content).

## 3. Users & Stakeholders

| Role | Description | Primary Needs |
|------|-------------|---------------|
| Agent (RAG consumer) | Every dispatched AID agent loads `.aid/knowledge/INDEX.md` in its task prompt to route to the right KB doc | A table whose short discriminating columns (`Audience`, `Tags`, `See-instead`) are readable at a glance, with no misleading section rank |
| Maintainer / human reader | Reads the index to find which doc covers a topic | Same scannability; a section split that reflects how a doc is *used*, not where it came from |
| AID repo maintainer | Owns `canonical/`, the profile renders, and CI | The change lands in canonical only, renders byte-identically to all targets, and leaves every gate green |

## 4. Scope

### In Scope

- `canonical/aid/scripts/kb/build-kb-index.sh` — the section-heading emission and
  table-header emission (lines 491-513), the per-doc cell print order
  (line 315), the two cell-order comments that document it (the awk-contract
  comment at line 97 and the row-assembly inline comment at line 486), and the
  two places the generator's own emitted prose names the column order (the
  `intent:` heredoc at lines 441-445 and the routing-table paragraph at lines
  458-460).
- The rendered twins of that script: the five profile copies under `profiles/`
  and the two repo-root dogfood copies (`.claude/` and `.cursor/`) — updated by
  running the full profile generator, never hand-edited.
- The regenerated `.aid/knowledge/INDEX.md`.
- The test oracles that pin the old column order or the Extension heading:
  `tests/canonical/test-build-kb-index.sh` (BI01 at lines 102 and 104, BI13 at lines
  371-408, BI16 at lines 468-469, and the BI13 header comment at line 18) and
  `tests/canonical/test-kb-forward-authored-marker.sh` (FI03 at line 381).

### Out of Scope

- **Retiring the `extension` value of `kb-category` project-wide.** The three
  docs keep `kb-category: extension` in their frontmatter. Only the index
  generator's *rendering* changes. The frontmatter lint, the KB review-surface
  scoping, the relationship-graph schema, the KB doc templates, and all of their
  tests continue to recognize `extension` unchanged. This is a confirmed scope
  decision and is not to be re-opened.
- Changing which columns exist, what they are named, or what data composes each
  cell. The column *set* is fixed at six; only the order changes.
- Changing the alphabetical within-section sort, the `Document` link form, the
  blank-cell rendering (`" "`), the pipe-escaping, or the intent/objective and
  intent/summary fallback chain (lines 285-312).
- **`.aid/knowledge/kb.html` — the generated visual KB summary.** It is out of
  scope because a *different* generator produces it: it is emitted by the
  `/aid-summarize` skill, not by `build-kb-index.sh`, with its own HTML markup,
  its own reduced column set
  (`<th>Document</th><th>Tags</th><th>Objective</th><th>Audience</th>` at
  `.aid/knowledge/kb.html:3577`), its own lede prose (`:3565`), and its own
  `Extension &mdash; project-specific` grouping (`:3694`) — none of which this
  work's generator emits and none of which AC-1/AC-12's grep targets match.
  Stated honestly, the residual: until `/aid-summarize`'s own grouping is
  revisited, `kb.html` still shows an Extension section, so the HTML summary and
  `INDEX.md` will disagree on grouping after this change. Absorbing `kb.html`
  into this work is explicitly refused — it belongs to a change against the
  `/aid-summarize` skill.
- Editing any KB document's body or frontmatter.
- Hand-editing `.aid/knowledge/INDEX.md` (it is generated; see
  `.aid/knowledge/architecture.md:503-505`).

## 5. Functional Requirements

**FR-1 — New column order.** The generator emits the routing-table header, in
every section it emits, as exactly:

```
| Document | Audience | Tags | See-instead | Objective | Summary |
```

**FR-2 — Matching separator row.** The separator row immediately below the
header carries the same six cells in the same new order, each keeping the dash
count it has today for that column (header length + 2):

```
|----------|----------|------|-------------|-----------|---------|
```

**FR-3 — Cell print order follows the header.** The per-doc awk pass at
`canonical/aid/scripts/kb/build-kb-index.sh:315` currently prints
`obj_cell | sum_cell | tags_cell | see_cell | aud_cell`. It must print
`aud_cell | tags_cell | see_cell | obj_cell | sum_cell`, so that the cells align
with FR-1. The caller at line 488 continues to prefix the `Document` link and
wrap with the outer pipes, unchanged.

**FR-4 — Contract comment updated.** The awk-contract comment at
`canonical/aid/scripts/kb/build-kb-index.sh:97` documents the two-line awk
output shape; its second line must be updated to the new cell order so the
comment does not go stale against line 315. The same contract is restated at the
consuming end by the row-assembly loop's inline comment at
`canonical/aid/scripts/kb/build-kb-index.sh:486`
(`# line 2: obj | sum | tags | see | aud`); it must be updated to the same new
order (`# line 2: aud | tags | see | obj | sum`) in the same change.

**FR-5 — No Extension section.** The generator no longer emits the heading
`## Extension - project-specific (outside the declared default seed)` (currently
line 499) nor a separate table for the `extension` category.

**FR-6 — Extension rows fold into Primary.** Docs whose `kb-category` is
`extension` are rendered as rows of the `## Primary - load-bearing knowledge`
table, in the same single alphabetical sort as every other Primary row. In the
AID corpus this moves `decisions.md`, `quality-gates.md`, and
`release-tracking.md` into Primary, interleaved alphabetically — not appended as
a block.

**FR-7 — Meta section unchanged.** `## Meta - process / ledger (review-exempt)`
is still emitted, still second, and still holds exactly the docs whose
`kb-category` is `meta` (`README.md`, `STATE.md`, `external-sources.md`).

**FR-8 — Section count and order.** The generator emits at most two sections, in
the order Primary then Meta. The category iteration at line 491
(`for category in primary meta extension`) collapses accordingly; a section with
no docs still emits nothing (the existing `emitted_header` guard is retained).

**FR-9 — Generator's own prose updated.** The two places where the generator
writes prose naming the column order must be corrected to the new order:

- the emitted `intent:` frontmatter block (lines 441-445), whose text reads
  "Each row carries Document, Objective, Summary, Tags, See-instead, and
  Audience columns composed from frontmatter";
- the routing-table paragraph (lines 458-460), whose first line reads
  "Routing table: each row is a KB doc with Objective, Summary, Tags,
  See-instead, and Audience columns".

**FR-10 — Canonical is the only hand-edited copy.** All edits land in
`canonical/aid/scripts/kb/build-kb-index.sh`; the seven rendered copies are
produced by running the full profile generator
(`python .claude/skills/generate-profile/scripts/run_generator.py`), never by
editing a rendered file (`.aid/knowledge/architecture.md:494-499`,
`.aid/knowledge/architecture.md:500-502`).

**FR-11 — Index regenerated.** `.aid/knowledge/INDEX.md` is regenerated with
`bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output
.aid/knowledge/INDEX.md` — invoking the canonical script, not the `.claude/`
copy (`.aid/knowledge/architecture.md:503-505`) — and the result committed.

**FR-12 — Test oracles updated in lockstep.** The assertions that pin the old
shape are updated to the new shape in the same change:

- `tests/canonical/test-build-kb-index.sh:102` (BI01, header string) and
  `tests/canonical/test-build-kb-index.sh:104` (BI01, separator string) — the
  separator assert sits immediately below the header assert and pins the old
  dash-width order, so AC-1 cannot pass unless it moves with line 102;
- `tests/canonical/test-build-kb-index.sh:403` (BI13, `## Extension` header
  present) — inverted to assert the Extension heading is **absent** and that the
  `extension`-category fixture doc's row appears under Primary; the BI13
  three-category fixture (its `ext-doc.md` block at lines 389-395) is retained
  so the fold-in is actually exercised, and the section comments at lines 18 and
  371 are reworded;
- `tests/canonical/test-build-kb-index.sh:467-469` (BI16: the line-467 comment,
  which still claims `kb13` emits one header row per each of three categories
  and is falsified by the Extension fold-in, is reworded alongside the header
  string and the expected header count, which drops from 3 to 2 for that
  fixture);
- `tests/canonical/test-kb-forward-authored-marker.sh:381` (FI03, header
  string).

## 6. Non-Functional Requirements

- **Behavior preservation (the refactor invariant).** For any KB corpus, the
  generator emits exactly the same *set* of document rows, with exactly the same
  *cell content*, composed from exactly the same frontmatter fields, read from
  exactly the same source of truth. Only column order and section grouping
  change.

  Stated honestly: the rendered **bytes** of `.aid/knowledge/INDEX.md` change by
  design — that is the point of the refactor. "Behavior preserving" here means
  *no cell value is recomputed and no row is added, dropped, or re-sourced*, not
  *the output file is unchanged*. Consequently the oracles that assert the old
  byte-level shape (FR-12) must be updated in the same change; that update is
  part of the behavior-preservation verification, not a violation of it.

  One deliberate, bounded exception to "same cell content": `INDEX.md`'s own row
  derives its `Objective` cell from the generator-emitted `intent:` block, so
  correcting that prose per FR-9 changes that one cell. Its `Summary` cell is
  the first sentence of the same block, which does not name the columns, and is
  expected to be unchanged. No other row's cells change.

- **Determinism.** The generator remains deterministic: same corpus in, same
  output out (modulo the `AUTO-GENERATED`/`Generated at:` timestamp lines, which
  CI already filters).

- **Performance.** Unchanged. The one-awk-subprocess-per-doc design (lines
  476-489) is retained as-is; this is a `restructure`, not a `performance`
  refactor, and no baseline measurement or target applies.

- **Portability.** The script keeps its existing POSIX-shell + awk constraints
  and the project's shell conventions (`.aid/knowledge/coding-standards.md`); no
  new tool dependency is introduced. Its existing `set -eu` line (line 42) is
  left exactly as found: it deviates from the documented `set -euo pipefail`
  convention, and closing that deviation here would be an unscoped behavior
  change (see SPEC.md "Documented deviation").

## 7. Constraints

- **Canonical is the single source of truth.** `canonical/` is the only
  hand-edited tree; the five `profiles/*` install trees plus the `.claude/` and
  `.cursor/` dogfood trees are renders
  (`.aid/knowledge/architecture.md:120-143`,
  `.aid/knowledge/architecture.md:495-496`). Eight copies of
  `build-kb-index.sh` exist on disk; seven are generated.
- **Full generator run, never a partial render.** After any `canonical/` edit the
  FULL `run_generator.py` must run, not a per-script render, or CI fails on stale
  emission manifests (`.aid/knowledge/architecture.md:500-502`).
- **Byte-identity gates.** CI's `render-drift` job re-runs the generator and fails
  on any uncommitted `profiles/` drift
  (`.aid/knowledge/architecture.md:137-139`,
  `.aid/knowledge/test-landscape.md:240-243`); `test-dogfood-byte-identity.sh`
  covers the dogfood direction (`.aid/knowledge/test-landscape.md:383`).
- **INDEX.md freshness gate.** CI's `kb-hygiene` job regenerates the index into a
  scratch file and diffs it against the committed one with the timestamp lines
  filtered, failing on any difference (`.github/workflows/test.yml`, step
  "INDEX.md is fresh (regenerate + diff, timestamps filtered)"). The committed
  `.aid/knowledge/INDEX.md` must therefore be regenerated in the same commit as
  the generator change.
- **`.aid/knowledge/INDEX.md` is a generated file.** It must never be hand-edited,
  and it must be regenerated with the canonical script path, because the
  regeneration command is embedded in the file's own header comment and checked.
- **Frontmatter compatibility.** `kb-category: extension` must remain a valid,
  recognized value everywhere else in the toolchain; nothing outside the index
  generator's rendering may start treating it as unknown.

## 8. Assumptions & Dependencies

- **Assumption:** the `extension` category currently contributes only the three
  AID docs listed above; no other KB doc in this repo carries it. Verified
  against `.aid/knowledge/INDEX.md:59-61`.
- **Assumption:** no consumer parses `.aid/knowledge/INDEX.md` positionally by
  column index or greps for the `## Extension` heading outside the two test files
  named in FR-12. This must be re-verified by a repo-wide grep (excluding
  `.git/`, `.aid/works/`, and `.aid/.temp/`, for the same reason as AC-1/AC-12) during
  implementation before the change is declared complete.
- **Assumption:** the reordered columns do not affect the KB relationship graph
  or the KB export, which read doc frontmatter rather than the rendered index.
- **Dependency:** `python .claude/skills/generate-profile/scripts/run_generator.py`
  must run successfully to produce the seven rendered copies.
- **Dependency:** `tests/canonical/test-build-kb-index.sh` and
  `tests/canonical/test-kb-forward-authored-marker.sh` are the primary oracles.
  Both run inside the canonical suite by virtue of `run-all.sh`'s
  `tests/canonical/test-*.sh` glob, which is the actual enrolment mechanism.
  `.aid/knowledge/test-landscape.md:135` enumerates `test-build-kb-index.sh`;
  it does not enumerate `test-kb-forward-authored-marker.sh` anywhere, so the KB
  is not evidence for that second suite's enrolment — the glob is.

## 9. Acceptance Criteria

**AC-1 (column order).** Given any KB corpus, when the generator runs, then every
table header row it emits is exactly
`| Document | Audience | Tags | See-instead | Objective | Summary |` and is
immediately followed by
`|----------|----------|------|-------------|-----------|---------|`. No
occurrence of the old header string `| Document | Objective | Summary | Tags |
See-instead | Audience |` survives anywhere in the repository — excluding
`.git/`, `.aid/works/`, and `.aid/.temp/` — (canonical, the seven renders,
`.aid/knowledge/INDEX.md`, or any test). `.aid/works/` and `.aid/.temp/` are
excluded because this work's own definition documents and its review ledgers
must quote the old strings in order to specify their removal.

**AC-2 (cells align with header).** Given a doc with all six fields populated,
when its row is emitted, then the cell in position 2 is its `audience` rendering,
position 3 its `tags` rendering, position 4 its `see_also` rendering, position 5
its objective, and position 6 its summary.

**AC-3 (no Extension heading).** Given a corpus containing at least one doc with
`kb-category: extension`, when the generator runs, then the output contains no
line beginning `## Extension`.

**AC-4 (extension rows under Primary).** Given that same corpus, when the
generator runs, then each `extension`-category doc's row appears inside the
`## Primary - load-bearing knowledge` table, in the single alphabetical sort with
the `primary` docs. Concretely for this repo: `decisions.md`, `quality-gates.md`,
and `release-tracking.md` appear in the Primary table, alphabetically interleaved
(`decisions.md` between `coding-standards.md` and `domain-glossary.md`,
`quality-gates.md` between `project-structure.md` and `relationships.md`,
`release-tracking.md` between `relationships.md` and `tech-debt.md`) — not
appended as a trailing block.

**AC-5 (Meta survives unchanged).** Given the repo corpus, when the generator
runs, then the output still contains the heading
`## Meta - process / ledger (review-exempt)`, it is the second and last section,
and its table holds exactly `README.md`, `STATE.md`, and `external-sources.md`.

**AC-6 (section count).** Given the repo corpus, when the generator runs, then
exactly two `## ` section headings and exactly two header rows are emitted.

**AC-7 (identical row set and cell content).** Given the pre-change
`.aid/knowledge/INDEX.md` and the post-change one, when each row is normalized by
sorting its six cells' contents and the two files' row multisets are compared,
then they are identical — same 22 document links, same cell values — with exactly
one documented exception: the `INDEX.md` row's own `Objective` cell, which
changes because FR-9 corrects the generator-emitted `intent:` prose that composes
it. Every other cell in every other row is byte-identical to before.

**AC-8 (frontmatter untouched).** Given the three docs `decisions.md`,
`quality-gates.md`, and `release-tracking.md`, when the change is complete, then
each still carries `kb-category: extension` in its frontmatter, and no
frontmatter field of any KB doc was modified.

**AC-9 (index regenerated and fresh).** Given the committed
`.aid/knowledge/INDEX.md`, when the canonical generator is re-run into a scratch
file and both are diffed with the `AUTO-GENERATED|Generated at:|: Generated$`
lines filtered, then the diff is empty — i.e. the `kb-hygiene` "INDEX.md is fresh"
step passes.

**AC-10 (canonical ↔ profiles ↔ dogfood byte parity).** Given the edited
canonical script, when the full `run_generator.py` runs, then all five
`profiles/*` copies and both dogfood copies (`.claude/aid/scripts/kb/`,
`.cursor/aid/scripts/kb/`) of `build-kb-index.sh` carry the change, the working
tree shows no un-committed render drift, the per-profile emission manifests are
updated, and `test-dogfood-byte-identity.sh` passes.

**AC-11 (updated oracles pass).** Given the updated test files, when
`tests/canonical/test-build-kb-index.sh` and
`tests/canonical/test-kb-forward-authored-marker.sh` run, then every assertion
passes, including: BI01 asserting the new header string and the new separator
string; BI13 asserting the
Extension heading is absent and that the `extension` fixture doc's row is in the
Primary table; BI16 asserting the new header string with an expected count of 2
for the three-category fixture; and FI03 asserting the new header string. The
full canonical suite reports no new failures relative to the pre-change baseline.

**AC-12 (no stale references).** Given a repo-wide grep — excluding `.git/`,
`.aid/works/`, and `.aid/.temp/`, because this work's own definition documents
and its review ledgers must quote the old strings in order to specify their
removal — for the old header string, for the
old separator string `|----------|-----------|---------|------|-------------|----------|`,
for `## Extension - project-specific`, and for the prose phrase "Objective,
Summary, Tags, See-instead, and Audience", when the change is complete, then
every remaining hit is either absent or has been updated to the new order —
including the generator's `intent:` heredoc, its routing-table paragraph, the
awk-contract comment at line 97, and the row-assembly cell-order comment at
line 486.

## 10. Priority

**Must.** Both changes are a single indivisible restructure of one generator's
rendering; there is no partial delivery worth shipping (a reordered table that
still carries a misleading Extension heading, or a folded table with the old
column order, leaves the index in a half-migrated state that every downstream
oracle would have to be updated for twice).
