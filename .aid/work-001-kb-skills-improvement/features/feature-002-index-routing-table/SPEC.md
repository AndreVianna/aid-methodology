# INDEX Routing Table

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-22 | Feature identified from REQUIREMENTS.md §5 (FR-1, FR-3) | /aid-interview |

## Source

- REQUIREMENTS.md §5.A (FR-1, FR-3)
- REQUIREMENTS.md §1.7 (INDEX routing table design; vector-router rejection), §2.6 (P6)
- Constraints C3 (canonical→render), C7 (INDEX-fresh / KB-hygiene CI)

## Description

This feature replaces today's prose-`intent:` `INDEX.md` list with a generated,
deterministic **routing table** so agents and humans find the right doc fast and
reliably. Each row carries *Document (link = path) · Objective · Summary · Tags ·
See-instead · Audience*, where Audience lets a human filter to the docs relevant
to their role and See-instead provides negative routing ("use this doc, not that
one") to avoid the siloed-logic trap.

The table is composed mechanically by `build-kb-index.sh` from the frontmatter
fields (no LLM), so it stays deterministic, git-diffable, and dependency-free —
consistent with AID's bare-box, AI-skeptic-friendly ethos. The INDEX-fresh and
KB-hygiene CI checks are updated to assert the new table format rather than the
old prose list. The explicitly rejected alternative (a vector/MCP router) is out
of scope.

## User Stories

- As an **AI agent**, I want `INDEX.md` to be a structured routing table with tags
  and see-instead pointers so that I route to the right doc in one pass without
  burning context budget or missing a conflicting rule in another doc.
- As a **non-technical PM** (or any human role), I want an Audience column so that
  I can filter the KB to the docs written at my level.
- As an **AID maintainer**, I want the table generated deterministically by
  `build-kb-index.sh` from frontmatter so that it is CI-verifiable and never
  hand-edited.

## Priority

Must

## Acceptance Criteria

- [ ] Given a KB with frontmatter, when `build-kb-index.sh` runs, then `INDEX.md`
  is the generated routing table with columns Document · Objective · Summary ·
  Tags · See-instead · Audience. *(FR-1, AC4)*
- [ ] Given the generator, when it composes the table, then it does so
  deterministically from frontmatter with no LLM, and the INDEX-fresh / KB-hygiene
  CI checks pass under the new format. *(FR-3, AC4)*
- [ ] Given two docs with a conflicting rule, when an agent consults the INDEX,
  then See-instead negative routing points it to the authoritative/related doc.
  *(FR-1, addresses P6 siloed-logic trap)*

> Cross-cutting note: builds on the frontmatter primitive (f001). Deterministic,
> dependency-free composition satisfies the FR-23 / NFR-3 determinism budget and
> NFR-8 (no new dependency).

---

## Technical Specification

> Methodology/tooling feature. This changes AID's INDEX generator
> (`canonical/aid/scripts/kb/build-kb-index.sh`) from prose-`intent:` emission to a
> per-category **routing table**, and updates the INDEX-fresh / kb-hygiene CI expectations.
> It **builds on f001** (`features/feature-001-frontmatter-and-sources-primitive/SPEC.md`),
> which owns the frontmatter field schema, the `extract_list` helper, and the soft-skip
> lint. The f001/f002 boundary is fixed (decision 3 below): **f001 owns the schema +
> `extract_list` + the lint; f002 owns this generator's table composition + the INDEX-fresh
> CI update.** Every claim is grounded against the files cited inline; genuine unknowns are
> flagged **[SPIKE]**, not guessed.

### Overview

Today `build-kb-index.sh` emits, per category, a list of `### [doc](..)` headings each
followed by the doc's multi-line `intent:` prose (current generator lines 157-193; current
output `.aid/knowledge/INDEX.md` lines 25-221). This feature replaces that **per-category
prose list** with a **per-category markdown table** whose columns are
**Document (link) · Objective · Summary · Tags · See-instead · Audience** (FR-1). The table
is composed mechanically from frontmatter — no LLM — keeping it deterministic, git-diffable,
and dependency-free (FR-3, NFR-3, NFR-8).

Three user-approved decisions this spec builds on (not re-litigated):

1. **Keep `kb-category` grouping.** The output stays `## Primary …` / `## Meta …` /
   `## Extension …` sections (the existing three category headers, current generator lines
   166-170), each now containing **one table** rather than a prose list. Category order is
   the existing `primary → meta → extension` (load-bearing primary first); see *Within-group
   sort* for intra-table ordering.
2. **Include the Audience column.** Six columns:
   **Document · Objective · Summary · Tags · See-instead · Audience**.
3. **f001/f002 boundary.** f001 ships a backward-compatible generator (parses the new
   fields, still emits the *current* prose shape with an `objective→intent` fallback — f001
   SPEC "Field Flow" step 3). **f002 (this feature) flips the emission to the table** and
   updates the CI expectation. f001 delivers `extract_list`; f002 *consumes* it. If the plan
   sequences f001+f002 as one delivery, the table lands in that delivery directly
   (**[SPIKE-1]** — confirm the f001/f002 delivery boundary with PLAN.md; mirrors f001
   SPIKE-1).

### INDEX Table Format

The generated `INDEX.md` keeps its generated-doc frontmatter and AUTO-GENERATED markers
(current generator lines 117-143) and its trailing "To regenerate" footer (lines 195-197),
**unchanged in shape** except the prose lead-in (line 138-141 "from each doc's `intent:`
field … shows the document name, its `kb-category:`, and its declared intent") is reworded
to describe the table. Each `## <Category>` section then contains exactly one table:

```markdown
## Primary — load-bearing knowledge

| Document | Objective | Summary | Tags | See-instead | Audience |
|----------|-----------|---------|------|-------------|----------|
| [architecture.md](../knowledge/architecture.md) | Architectural map of the AID repo | One-sentence scope of the doc. | `canonical-render`, `phase-gate` | [project-structure.md](../knowledge/project-structure.md) | architect, maintainer |
| [schemas.md](../knowledge/schemas.md) | The AID data-model schemas | One-sentence scope. | `settings.yml`, `frontmatter` | [module-map.md](../knowledge/module-map.md) | architect, developer |
```

**Cell → frontmatter mapping** (each cell is composed mechanically from one field of the
source doc's frontmatter; the field schema + types are owned by f001):

| Column | Source field (f001 schema) | Generator helper | Rendering rule |
|--------|----------------------------|------------------|----------------|
| **Document** | the file itself (not a frontmatter field) | `basename` (existing, line 160) | Markdown link `[<name>](../knowledge/<name>)` — identical link target to today (current line 182). |
| **Objective** | `objective:` (required, single-line scalar) | `extract_field` (existing, lines 71-85) | Verbatim trimmed scalar. **Fallback to `intent:`** when absent (see *Coexistence fallback*). Pipe-escaped. |
| **Summary** | `summary:` (required, single-line scalar) | `extract_field` | Verbatim trimmed scalar. **Fallback to `intent:` first sentence** when absent. Pipe-escaped. |
| **Tags** | `tags:` (optional, list) | `extract_list` (**f001**) | Each tag rendered inline-code, comma-joined: `` `tag1`, `tag2` ``. Empty list → blank cell. |
| **See-instead** | `see_also:` (optional, list of doc-names) | `extract_list` (**f001**) | Each entry rendered as a doc-name link `[<entry>](../knowledge/<entry>)` when it looks like a sibling doc name (matches `*.md` / a bare token); a non-doc-name prose entry is rendered verbatim (per f001 schema: "a bare prose pointer is tolerated but not linked"). Comma-joined. Empty → blank. |
| **Audience** | `audience:` (optional, list) | `extract_list` (**f001**) | Role labels comma-joined verbatim (`architect, pm`). Empty → blank. |

`owner:` is parsed by f001 but is **not** an INDEX column (it drives f007 freshness
accountability — f001 "Field Flow"); the table omits it.

**Cell-safety (pipe + newline escaping).** Every cell value is single-line by construction
(`extract_field` returns one line; `extract_list` entries are short strings with no embedded
newlines per f001 schema). The generator MUST escape any literal `|` in a cell value to `\|`
so a stray pipe in an `objective`/`summary`/tag cannot break the table. A cell that is empty
after composition renders as a single space (` `) so the markdown table stays well-formed.

**Within-group sort.** Rows within each category table are emitted in the generator's
existing deterministic order: `find … | sort` over the filenames (current line 150),
i.e. **alphabetical by document filename**. This is the load-bearing-first ordering *at the
category level* (primary group precedes meta/extension); there is **no per-row
load-bearingness rank**, because f001's schema adds no numeric `tier`/`order` field and the
INDEX must stay deterministic from frontmatter alone. *(If a future feature wants
load-bearing-first ordering **within** a table, it must first add a deterministic ordering
field to f001's schema — **[SPIKE-4]**, deferred; not in scope here. Alphabetical is the
committed v1 order.)*

**AUTO-GENERATED marker / header.** Preserved verbatim from the current generator
(lines 133-134 — the `<!-- AUTO-GENERATED $TS … -->` + `<!-- DO NOT EDIT … -->` pair, and
the `# Knowledge Base Index` H1). The "Generated at: $TS" line (line 139) and the AUTO-
GENERATED line carry the only timestamps; both are already filtered by the INDEX-fresh CI
step (see *CI*). The reworded lead-in (replacing "shows … its declared intent") carries **no
timestamp**, so it does not affect the freshness diff.

### Generator Changes

All changes are confined to `canonical/aid/scripts/kb/build-kb-index.sh` (then re-rendered to
the 5 host trees — see *CI / render-drift*). The script stays `set -eu`, ASCII-only, plain
bash + coreutils (`awk`, `grep`, `find`, `sort`, `basename`) — **no new runtime** (NFR-8/C1).

1. **Header frontmatter + lead-in (lines 117-143).** Keep the generated-doc frontmatter
   block. Update the `intent:` body and the prose lead-in to describe the *table* (the doc
   is "a routing table with Objective · Summary · Tags · See-instead · Audience columns")
   rather than "each doc's `intent:` field." The AUTO-GENERATED markers and the regen command
   are unchanged.

2. **`extract_list` helper (from f001).** f001 adds `extract_list <file> <field>` — a YAML
   inline-or-block list reader — to this same script. f002 **consumes** it for `tags`,
   `see_also`, `audience`. If the plan lands f002 before f001, f002 must include the helper;
   under the fixed boundary (decision 3) the helper is f001's. **f002 adds no new parser
   primitive** — it reuses `extract_field` (objective/summary) + `extract_list` (the lists).

3. **Per-category table emission (replaces lines 157-193).** The category loop
   (`for category in primary meta extension`) is preserved. For each category:
   - Emit the existing `## <Category> — …` header (lines 166-170), unchanged.
   - Emit the **table header + separator** row once (the 6-column header above), instead of
     setting `emitted_header` for a prose run.
   - For each doc in that category (in `sort` order), compose **one table row**:
     `objective=extract_field "$f" objective`; `summary=extract_field "$f" summary`;
     `tags=extract_list "$f" tags`; `see_also=extract_list "$f" see_also`;
     `audience=extract_list "$f" audience`; apply the *Coexistence fallback*; pipe-escape
     each; join the list cells; emit `| [name](../knowledge/name) | objective | summary | tags | see-instead | audience |`.
   - The current `source: generated` special-case (lines 183-187, which emits an italic
     "*Generated by …*" note under the heading) is **dropped from the row body** — that note
     does not fit a table cell. The generated-ness of a doc (e.g. `project-structure.md`,
     `INDEX.md`) is no longer surfaced inline; this is an intentional simplification of the
     table format. *(If surfacing it is desired, it belongs in a Tags/Audience convention,
     not a per-row prose note — out of scope, noted for the gate.)*

4. **Empty-KB and missing-category cases.** The "no KB docs found" branch (lines 152-155)
   is preserved. A category with no docs emits **neither** the header **nor** an empty table
   (same as today: `emitted_header` guard → only emit when ≥1 doc matches). The trailing
   `---` + regen footer (lines 195-197) is unchanged.

5. **Determinism.** Output is a pure function of (a) the sorted file list and (b) each file's
   frontmatter — identical inputs yield byte-identical output modulo the two timestamp lines
   (already CI-filtered). No `date`-derived content enters a cell. `extract_field` /
   `extract_list` are deterministic awk. (NFR-3 / C5.)

### Coexistence fallback (REQUIRED)

Until **f011** migrates AID's own docs (FR-30), the **0-of-15** hand-authored primary KB
docs in `.aid/knowledge/` carry `intent:` but **not** `objective:`/`summary:`/`tags:`/etc.
(confirmed: current INDEX.md is built entirely from `intent:`). The generator therefore MUST
produce a valid table during the coexistence window. The fallback rule, per column:

- **Objective cell.** If `objective:` is present (non-empty after trim) → use it. **Else
  fall back to `intent:`**: take the doc's `intent:` literal block (read with the existing
  `extract_literal`, lines 89-114), collapse it to a single line (join lines on spaces,
  squeeze whitespace), and use it as the Objective cell. This mirrors today's behavior (the
  Objective column carries the same routing prose users see now). If **both** `objective:`
  and `intent:` are absent → emit `*(no objective declared)*` (parallels the current
  `*(no intent: declared)*`, line 177).
- **Summary cell.** If `summary:` is present → use it. **Else fall back to the first
  sentence of the collapsed `intent:`**, extracted by a single bounded, fully deterministic
  rule (no LLM). Operating on the collapsed single-line `intent:` (the same join-on-spaces +
  squeeze-whitespace transform the Objective fallback uses, so no embedded newline survives):
  - **Sentence-boundary predicate.** Cut at the first sentence-ending `.`, `!`, or `?` that
    is **immediately followed by whitespace and an uppercase ASCII letter `[A-Z]`, OR by
    end-of-string**. The cut text *includes* that terminator. Formally, the boundary is the
    first match of the regex `[.!?](?=[ \t]+[A-Z]|$)` over the collapsed line. The
    `[A-Z]`-after-space guard is what makes the split robust on the real coexistence corpus:
    a `.` inside a version/decimal/abbreviation (`v1.1.0`, `1.4`, `e.g.`, `i.e.`) is **not**
    followed by space-then-uppercase, so it is **not** a boundary and the token is never
    truncated mid-string. (A `.` followed by space-then-lowercase — mid-sentence prose — is
    likewise not a boundary.)
  - **No-boundary case.** If no position matches the predicate, the whole collapsed line is
    the Summary (it is a single "sentence" with no qualifying terminator).
  - **Hard caps (both applied, in order).** (1) Cap at the **first newline** — moot after the
    collapse above, but stated so the rule is total. (2) Cap the result at a **hard maximum of
    200 characters**; if the selected sentence exceeds 200 chars, truncate to 200 and append an
    ASCII ellipsis `...` (three dots), so the cell is bounded regardless of
    input. Truncation is on character count, not token boundary — bounded length wins over
    word-preservation, by design, to keep the rule unambiguous.
  - If `intent:` is also absent → blank cell.

  This predicate is implementable as one `awk`/`grep -oP` (or POSIX `sed` two-pass) over the
  collapsed line with no lookahead into other fields; identical input yields byte-identical
  output. All literals (`.!?`, `[A-Z]`, `...`) are ASCII, so the rule preserves the C2
  ASCII-only guarantee and the NFR-3 determinism budget.
- **Tags / See-instead / Audience cells.** These have **no `intent:` analogue**; when the
  source list field is absent or empty they render **blank** (a single space). This is the
  soft, additive behavior that keeps an un-migrated doc valid — it simply has empty optional
  cells. (Mirrors f001's soft-skip lint: an un-migrated doc is tolerated, not failed.)

**Why this is safe (degrade-gracefully, NFR-7).** An un-migrated KB (every current AID doc)
renders as a table where every row has a populated Objective+Summary (from `intent:`
fallback) and blank Tags/See-instead/Audience. A migrated KB renders fully. A mixed KB
(during the f011 migration) renders each row by its own fields — **no doc breaks
mid-migration**. The fallback is the same contract f001 relies on: `intent:` stays valid
(coexistence) until f011 retires it.

**Important — keep INDEX-fresh green for AID's own KB at f002 landing.** Because f002 flips
the emission to the table, **AID's own `.aid/knowledge/INDEX.md` MUST be regenerated and
committed in the same change** (it will become the table-form INDEX built from the existing
`intent:` fallbacks). Otherwise the INDEX-fresh CI step (which regenerates and diffs) goes
red on the committed prose-form INDEX. This regenerated INDEX is itself an artifact of this
feature.

### CI

- **INDEX-fresh** (`kb-hygiene` job, `test.yml` lines 116-124). This step regenerates the
  INDEX to `/tmp/INDEX.regen.md` and diffs it against the committed `.aid/knowledge/INDEX.md`
  with the timestamp lines filtered (`filt='AUTO-GENERATED|Generated at:|: Generated$'`).
  It is **format-agnostic** — it asserts "committed == regenerated," not a specific shape —
  so it **survives the format change** *provided the committed INDEX.md is regenerated in the
  same commit* (above). **No edit to this step is required**; the f002 "CI update" is simply
  committing the regenerated table-form INDEX so the diff is clean. The new table rows carry
  no timestamp, so nothing escapes the existing filter. **The `: Generated$` false-green
  cannot occur for table rows — verified safe:** every table row ends in ` |` (the closing
  cell pipe), so the `$`-anchored `: Generated$` pattern can never match a table line; the
  only line that matches that filter is the generator's own changelog line
  (`- <date>: Generated`, `build-kb-index.sh:130` → `INDEX.md:12`), which is exactly what the
  filter is meant to drop. No further action needed. *(The canonical suite still asserts
  byte-stability across two runs, which incidentally covers this.)*
- **kb-hygiene** (same job). The CRLF and `.aid/.temp` checks are orthogonal. f001 adds the
  `lint-frontmatter.sh` step (soft-skip on un-migrated docs); f002 does **not** change the
  lint — it consumes the same fields. No kb-hygiene edit beyond the regenerated INDEX.
- **render-drift** (`render-drift` job, lines 24-42). `build-kb-index.sh` is canonical and
  is rendered to the 5 host trees (`profiles/{claude-code/.claude, codex/.codex,
  cursor/.cursor, copilot-cli/.github, antigravity/.agent}` plus the repo `.claude/` working
  copy — same fan-out f001 documents). The generator edit MUST be made in `canonical/` only,
  then `python .claude/skills/generate-profile/scripts/run_generator.py` re-run and the
  regenerated `profiles/` committed, or render-drift goes red (C3 / NFR-4;
  render-drift-full-generator precedent). **[SPIKE-3]** — verify no emission manifest pins
  the old `build-kb-index.sh` byte-shape such that regen is required (same spike as f001
  SPIKE-3); if pinned, regen the full generator, never hand-edit a rendered copy.
- **canonical suite (NEW or extended).** Add table-shape assertions for `build-kb-index.sh`
  to a canonical helper suite under `tests/canonical/` (auto-discovered by `tests/run-all.sh`
  glob, run in the `canonical-tests` job, line 80). Assert: (a) a doc with full new fields
  renders all 6 cells; (b) an un-migrated `intent:`-only doc renders Objective+Summary from
  the `intent:` fallback and blank Tags/See-instead/Audience; (c) a pipe in a field is
  escaped; (d) `see_also` doc-names render as links; (e) the output is byte-stable across two
  runs (determinism). **No existing `build-kb-index.sh` canonical suite exists** (verified:
  no `tests/canonical/*kb-index*` file), so this is a **new** suite file
  (`tests/canonical/test-build-kb-index.sh`, auto-discovered by the glob). It must pin
  `HOME`/use a throwaway fixture KB root (not `.aid/knowledge/`) so it asserts against
  controlled inputs.

### Constraints

- **C2 — ASCII-only (f002 owns the ASCIIfication; explicit deliverable).**
  `build-kb-index.sh` is a shipped KB script (vendored into the install bundles alongside the
  new `lint-frontmatter.sh`). All f002 edits MUST be ASCII (bash; PS N/A); the table glyphs
  f002 introduces (`|`, `-`, `` ` ``) are ASCII. The *existing* script, however, is **NOT
  ASCII-clean today**: 17 non-ASCII lines — em-dashes (`—`) in comments/help text (lines
  2, 17-20, 33, 45-48, 124, 134, 167-169, 186) plus a check-mark emoji in the success `echo`
  on line 203 (verified by `grep -P "[^\x00-\x7F]"`) — and it is **absent from
  `test-ascii-only.sh`'s `SHIPPED_SCRIPTS` array** (lines 24-46), so the ASCII guard does not
  cover it today.

  **f002 owns resolving this** (no longer deferred to a spike or to "whichever feature ships
  first"): because f002 edits this script, f002 — in the same change — (a) **ASCIIfies the
  whole script**, replacing every em-dash `—` with an ASCII `--` (or `-`) and the line-203
  check-mark emoji with an ASCII marker (e.g. `[OK]`/`OK:`), and (b) **adds
  `build-kb-index.sh` to the `test-ascii-only.sh` `SHIPPED_SCRIPTS` array**, so the guard
  covers it going forward. (b) is gated on (a): the allow-list addition is committed in the
  same change as the ASCIIfication, so the guard goes green immediately. This is an explicit
  f002 deliverable + acceptance criterion (see *f002 deliverables* below), not a deferred
  spike. If the plan folds f001+f002 into one delivery, the ASCIIfication still lands here, in
  the change that edits the script.
- **C3 / NFR-4 — render-drift green.** Edit canonical only; re-run `run_generator.py`; commit
  regenerated `profiles/`. Never hand-edit a rendered copy.
- **NFR-3 / C5 — determinism.** Pure-function output (sorted file list × frontmatter),
  ordering-stable (`sort`, line 150), no LLM, asserted by the canonical suite.
- **NFR-8 / C1 — no new runtime.** Plain bash + coreutils; reuses `extract_field`/
  `extract_list`; adds no dependency, binary, or interpreter-version escalation.

### f002 deliverables (acceptance criteria for the gate)

In addition to the table emission, f002's change MUST land all of:

1. **Table generator.** `build-kb-index.sh` emits the 6-column per-category routing table
   (per *Generator Changes*), with the coexistence fallbacks (Objective, and the bounded
   deterministic Summary predicate above).
2. **ASCII-clean the script.** All 17 existing non-ASCII glyphs in `build-kb-index.sh`
   (em-dashes + the line-203 check-mark emoji) are replaced with ASCII. The whole script
   passes `grep -P "[^\x00-\x7F]"` with no matches. *(Owned by f002 — see C2.)*
3. **Wire the ASCII guard.** `build-kb-index.sh` is added to `test-ascii-only.sh`'s
   `SHIPPED_SCRIPTS` array (gated on deliverable 2, in the same change), so the guard covers
   it from this change forward. *(Owned by f002 — see C2.)*
4. **Regenerated INDEX.** AID's own `.aid/knowledge/INDEX.md` is regenerated to the table form
   and committed in the same change (keeps INDEX-fresh green — see *Coexistence fallback*).
5. **Re-rendered profiles.** `run_generator.py` re-run and the regenerated `profiles/`
   committed (keeps render-drift green — see *CI / render-drift*).
6. **New canonical suite.** `tests/canonical/test-build-kb-index.sh` with assertions (a)-(e)
   (see *CI / canonical suite*).

### Spikes (genuine unknowns flagged, not guessed)

**Open (PLAN-sequencing):**

- **[SPIKE-1]** f001/f002 delivery boundary — does the table render land here or fold into
  f001's delivery? Spec assumes f002 flips the emission; f001 ships backward-compatible.
  Confirm against PLAN.md (mirrors f001 SPIKE-1). *(Sequencing only — does not change f002's
  content; the ASCIIfication + table land in whichever change edits the script.)*
- **[SPIKE-3]** render-manifest byte-pinning of `build-kb-index.sh` — verify the full
  generator must be re-run (render-drift-full-generator precedent); if pinned, regen, never
  hand-edit.

**Out of scope (deferred by decision):**

- **[SPIKE-4 — deferred]** within-table load-bearing-first ordering needs a deterministic
  rank field f001's schema does not add; v1 uses alphabetical `sort`. Out of scope here.

**Resolved (no longer open):**

- **[SPIKE-2 — verified safe]** INDEX-fresh `: Generated$` false-green cannot occur for table
  rows: every row ends in ` |`, so the `$`-anchored pattern never matches a cell (only the
  changelog line matches, as intended). Resolved in-spec — see *CI / INDEX-fresh*.
- **[SPIKE-5 — resolved]** no existing `build-kb-index.sh` canonical suite — f002 adds a new
  `tests/canonical/test-build-kb-index.sh` (see *f002 deliverables* §6).
- **[SPIKE-6 — resolved → f002 deliverable]** the existing script's 17 non-ASCII lines
  (em-dashes + line-203 check-mark emoji) and its absence from `test-ascii-only.sh` are now an
  explicit f002 deliverable (ASCIIfy + wire the guard, gated on f002's own edit). No longer a
  spike — see C2 and *f002 deliverables* §2-3.
