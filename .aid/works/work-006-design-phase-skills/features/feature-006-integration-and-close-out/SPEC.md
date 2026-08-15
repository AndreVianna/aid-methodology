# Integration and Close-Out

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md NFR-1, NFR-2, NFR-3, NFR-4, C-5, §10, AC-1/AC-8/AC-9 | /aid-define |
| 2026-08-09 | Technical Specification authored against live derivations. Two corrections to the requirements half recorded in §2 and §5: the `shortcuts` count does NOT move (all 36 rows are `repurpose: true`, so it stays 34 and those phrasings must not be edited), and AC-6's site criterion cannot fail as written because the `design` verb family already exists — replaced with the four `assignGroups` guards plus exact card counts | /aid-specify |
| 2026-08-09 | Review close-out. The replacement card count was wrong (15, counting only feature-005's contribution) and is now **22** per FR-11 CC-7, with every dependent figure re-derived (§5, §10, AC-6). `DMR32`'s zero-alias literal embeds the row total and is now in §4's edit set, which grew from four sites to eight across two files. §3's "run the guard, do not hunt" procedure was unsound — a replay of the guard's own 26 `CLAIMS` regexes finds count-bearing lines it cannot see inside its own scanned trees — and is replaced by a two-stage procedure that closes the gap by extending `CLAIMS`. §6 gains the `.cursor/` resync and the freshness oracle (`render-drift`); §7 drops the `release-tracking.md` entry (FR-11 doctrine: written at tag time by `release-aid`) and records `kb.html` as unregenerable (`tech-debt.md` W1-11); §8a defers pair ownership to CC-9. Found while sweeping the same class: a **third** count-bearing file under `tests/` that no review round had named — `tests/coverage-baseline.tsv` enumerates `test-catalog-dirs-parity.sh`'s per-catalog-row keys, so it gains 144 rows, and its `coverage-parity` lane is committed-and-enforcing rather than advisory. Added as §4c, with the CI-only re-bootstrap runbook and a §10 row; its unchanged `CDP{i}e/f/g` count is now a second independent oracle for `shortcuts` = 34 | /aid-specify |
| 2026-08-09 | **Owner decision: `kb.html` IS regenerated in this work.** The premise this spec's §7 rested on — `tech-debt.md` W1-11's "cannot be regenerated — the assembler's `.aid/.temp/summarize/` input tree no longer exists" — is false and W1-11 is corrected: `/aid-summarize`'s GENERATE state reads `.aid/knowledge/*.md` directly and *writes* the `.aid/.temp/summarize/` tree itself during a run (`state-generate.md` §2/§5/§8); the path is gitignored scratch, so a fresh run recreates it. §7 now regenerates `kb.html` by re-running the skill, last of all, with two costs stated rather than discovered: the run takes ~24m (Calibration Log) and its **visual** gate is an orchestrator step because Playwright is not installed in the summarize package (Knowledge Summary Status). §10 gains a four-conjunct regeneration row plus an explicit not-asserted row for the visual gate; §3's M6 keeps its guard-blindness but loses its "left stale" consequence; §9's sizing table gains the run as a further unaccounted operand. Also corrected while verifying: §7's "Verified live … `64 verb-first`" was wrong — the file has no such string, it reads `34 verb-first shortcuts`, a figure that is **correct today and must stay 34** | owner decision / /aid-plan |

## Source

- REQUIREMENTS.md §6 NFR-1 (render parity), NFR-2 (catalog integrity), NFR-3, NFR-4, NFR-5 (grade floor)
- REQUIREMENTS.md §7 C-5 (generator discipline), C-1
- REQUIREMENTS.md §9 AC-1, AC-8, AC-9, **AC-11** (every count-bearing catalog assertion moves together — the origin of this spec's AC-4 and §4); §10 Priority
- REQUIREMENTS.md §5 Functional Requirements — §5.1 (the `tech-debt.md` → `backlog.md` →
  `release-tracking.md` item flow, which §7 depends on) and **FR-11** cross-feature contracts — **CC-7** (the `design` family has 22 rows) and **CC-9** (confusable-pair ownership; the complete set is verified only here). FR-11's rule is *refer, never restate*: this spec cites the contract and does not reproduce it.

## Description

The work every new skill shares, done **once over the finished set of thirty-six** —
plus the description of what AID now has. These are aggregates: a skill count, a row
count, a byte-identity hash, a corpus guard. Computing any of them over a partial set
produces a number that is wrong the moment the next feature lands, which is why this
feature runs last rather than being distributed.

**Roster integration.** Thirty-six catalog rows validated — `name` equals directory,
`alias_of: null`, `repurpose: true` on hand-authored rows. Then
`build-shortcut-skills.py`, then the **full** `run_generator.py` (never a partial
render), the five-profile render, the byte-identity gate green, and **both** repo-root
dogfood trees resynced — `.claude/` from `profiles/claude-code/` and `.cursor/` from
`profiles/cursor/`, because the byte-identity gate carries a tuple for each (§6).

**Count-bearing surfaces.** Each moves to **its own** new value: 112 directories, 94
catalog rows, 60 `repurpose` rows (76 / 58 / 24 today) — while `shortcuts` stays at
**34**, which is why §2 states the delta per quantity and not as one number. The site
needs no code change for the `design` family; the count guard, its `CLAIMS` phrasing
table, and both catalog suites are updated — the second of those suites needs comment
edits only, its assertions being count-agnostic by design (§4b).

**Knowledge Base and methodology refresh.** AID's own description of what it now has:
the capability inventory, architecture, module map, per-skill state machines in
pipeline-contracts, glossary entries for *seed* and *design artifact* and the two new
documents, and the decisions record capturing why `design`/`create`/`update` were chosen
and why forward-looking documents were admitted to the KB. Plus the methodology
narrative and its per-family Skill Inventory table (`docs/aid-methodology.md` and its
site mirror), whose Total moves 58 → 94. Then, **last of all**, the two generated
summaries: `INDEX.md`, and `kb.html` via a re-run of `/aid-summarize` — a ~24-minute
authored run whose *visual* gate is an orchestrator step, because Playwright is not
installed in the summarize package (§7). **No `release-tracking.md` entry** — under the
doctrine feature-001 installs, that file is purely historical and its version sections
are written at tag time by `release-aid`, not by this work (§7).

These summaries are deliberately updated last: they are final-state descriptions, and
refreshing them before the roster settles guarantees rework.

**Two closing verification sweeps.** That every confusable pair carries mutual negative
routing, and that the `phase:` enum, the work/delivery/task hierarchy, and the numbered
pipeline are provably untouched.

**Note on scope.** This is the largest feature and it mixes mechanical render work with
KB authoring. Splitting it was considered and deferred: the split point depends on how
large the render surface actually turns out to be, which is not knowable until the
roster exists. It is the first candidate to divide if `/aid-plan` finds it oversized.

## User Stories

- As an **adopter installing AID**, I want all thirty-six skills present and working in
  my host tool, so that the render pipeline delivered what the catalog promises.
- As the **maintainer**, I want every count-bearing document to state the true roster
  size, so that CI's count assertions pass and the docs do not lie.
- As a **newcomer**, I want the KB and methodology docs to describe the design family, so
  that I can discover it without reading the catalog.

## Priority

Must

## Acceptance Criteria

- [ ] Given the thirty-six new skills, when the catalog is validated, then every row's
      `name` equals its directory name, `alias_of` is `null`, and hand-authored rows
      carry `repurpose: true`.
- [ ] **(C-5)** Given a catalog edit, when the generator runs, then
      `build-shortcut-skills.py` is followed by the full `run_generator.py`, never a
      partial render — evidenced by re-running the generator and getting an empty
      `git diff -- profiles/` (§10, the `render-drift` oracle).
- [ ] Given the five profiles, when the render completes, then the byte-identity gate is
      green over **both** tuples and **both** repo-root dogfood trees match their profile
      source: `.claude/` ↔ `profiles/claude-code/` and `.cursor/` ↔ `profiles/cursor/`.
- [ ] **(REQUIREMENTS AC-11)** Given every count-bearing document and test, when this
      feature lands, then each states its own new value — 112 directories, 94 catalog
      rows, 94 canonical names, 60 `repurpose` rows, 0 aliases, `shortcuts` still 34 —
      and **every** hardcoded catalog assertion moves together, not just the headline
      two. In `tests/canonical/test-deploy-monitor-repurpose.sh` that is four assertions
      (`DMR30` `TOTAL_ROWS`, `DMR31` `CANONICAL_ROWS`, `DMR32` the zero-alias pair —
      whose expected literal embeds the row total — and `DMR33` `REPURPOSE_ROWS`, whose
      message carries the decomposition `24 + 34 = 58` → `60 + 34 = 94`) plus two
      comment blocks; in `tests/canonical/test-catalog-dirs-parity.sh` it is two comment
      blocks and no assertion, that suite being count-agnostic by design; and
      `tests/coverage-baseline.tsv` is **re-bootstrapped** in CI, gaining 144 rows and no
      new `CDP{i}e/f/g` row. §4 is the complete site list.
- [ ] Given NFR-5, when each artifact this work produces is graded, then it meets the
      configured minimum grade.
- [ ] **(replaces the original site criterion — see §5)** Given the finished corpus,
      when `assignGroups` runs, then it throws none of its four guards and the published
      index holds **22** cards in the `design` family and **1** in `brainstorm`
      (FR-11 CC-7).
- [ ] Given the KB and the methodology narrative, when refreshed, then the capability
      inventory, architecture, module map, project structure, pipeline contracts,
      glossary, test landscape, decisions record and `docs/aid-methodology.md` (with its
      site mirror) describe the new family and state the new figures (§7); `INDEX.md` is
      regenerated and, **last of all**, `kb.html` is regenerated by re-running
      `/aid-summarize` rather than hand-patched. Its **visual** gate is an orchestrator
      step, not an automated one — Playwright is not installed in the summarize package
      — so what this criterion asserts is the machine half plus a recorded V1 verdict
      (§7, §10).
- [ ] **(AC-8, FR-11 CC-9)** Given the complete confusable-pair set — verifiable only
      here, because CC-9 splits authorship across features — when the sweep runs, then
      each pair carries mutual negative routing, reported per pair and per direction.
- [ ] Given the pipeline, when the sweep runs, then the `phase:` enum, the
      work/delivery/task hierarchy, and the numbered sequence are unchanged.

---

## Technical Specification

### 1. Why this is one feature and why it runs last

Every item here is an **aggregate over the finished set of thirty-six**: a directory
count, a row count, a byte-identity hash, a corpus guard, a completeness sweep.
Computing any of them while features 001–005 are still landing produces a number that
is correct for an hour and wrong afterwards. That is the whole justification for
grouping otherwise-unrelated work — it is a sequencing constraint, not a thematic one.

Ordering within the feature is forced by data flow:

```
catalog rows validated
   ↓
build-shortcut-skills.py            (emits/refreshes generated doorways)
   ↓
run_generator.py  (FULL, never partial)
   ↓
5-profile render + emission manifests
   ↓
dogfood resync, BOTH trees      .claude/ ← profiles/claude-code/
                                .cursor/ ← profiles/cursor/
   ↓
byte-identity gate (2 tuples)       ← the render is internally CONSISTENT
   ↓
render-drift (regenerate + diff)    ← the render is FRESH; the two are different
                                      properties and neither implies the other
   ↓
count-bearing surfaces: guard run, CLAIMS extension, replay to zero,
                        hardcoded test assertions, coverage-baseline re-bootstrap
   ↓
KB + methodology refresh            ← final-state summaries, updated last
   ↓
two closing sweeps
```

The `byte-identity` → `render-drift` split is the one ordering subtlety worth reading
twice: a consistently-stale render passes the first and fails the second, so the second
is what makes "the render is provably correct" a true statement rather than an
aspiration (§6).

### 2. What the counts actually become — derived, not asserted

`site/scripts/skills/skill-counts.mjs` `deriveSkillCounts()` reads the catalog and
`canonical/skills/` from disk, so no *rendered* figure needs maintaining. Hand-written
figures are a different matter and there are many: the guard reports **175 claims
checked** across 520 files today (§3), plus the test literals in §4, plus the surfaces
§3 shows the guard cannot see. This section fixes what each quantity becomes; §3 and §4
fix where those quantities are written down. The full delta:

| Quantity | Today | After | Changed? |
|---|---:|---:|---|
| `directories` | 76 | 112 | +36 |
| `catalogRows` | 58 | 94 | +36 |
| `catalogCanonical` | 58 | 94 | +36 |
| `catalogAliases` | 0 | 0 | — |
| `repurposed` | 24 | 60 | +36 |
| **`shortcuts`** (emitting) | **34** | **34** | **no** |
| `curatedOnly` | 18 | 18 | no |
| `classicRepurposed` | 3 | 3 | no |

Today's column is not asserted — it is the live output of
`node tests/canonical/check-skill-counts.mjs --list`, which currently reports
`All 175 stated skill counts agree with the derivation`.

**The `shortcuts` row is the load-bearing one.** All thirty-six new rows are
`repurpose: true` (NFR-2), so `deriveSkillCounts` counts none of them as emitting.
Every repo statement of the form "N shortcuts", "N shortcut skills", "N doorways",
"N verb-first" therefore stays at 34 and **must not be touched**. Half the
count-bearing surfaces in this repo use that phrasing; "update every count" would
corrupt them. The guard in §3 distinguishes the quantities by phrasing, which is why
this table is stated per-quantity rather than as one number.

Arithmetic check on the repurpose decomposition: `60 + 34 = 94`. ✓

### 3. Count-bearing surfaces: the guard is necessary, and it is not sufficient

`tests/canonical/check-skill-counts.mjs` is repo-rooted and derives from
`deriveSkillCounts`, scanning `README.md`, `docs/`, `.aid/knowledge/`, `canonical/`,
the repo-local maintainer skills (`generate-profile`, `release-aid`), and
`site/src/content/docs/` (`:145-196`). Its `CLAIMS` array (`:63-118`) holds **26**
entries, each binding one phrasing to one **quantity** — 7 to `corpus total`, 6 to
`emitting shortcuts`, 4 to `catalog rows`, 3 each to `repurpose rows` and
`curated (non-catalog)`, 1 each to the remaining three.

**Running the guard is step one of two, not the whole procedure.** The guard is
phrasing-bound: a sentence stating a count in wording no `CLAIMS` regex matches is
invisible to it, and its file filter admits only `.md/.mdx/.sh/.mjs/.js/.ts/.py/.yml/
.yaml` (`:170`), so an `.html` surface is structurally unreachable. Both blind spots
are populated **today, inside the guard's own scanned trees**, so a guard-only
procedure would leave live falsehoods behind at 112/94/60.

*Stated search, so this is a measurement and not an impression.* Replay: load the
guard's own `CLAIMS` array and its own file walk; for every occurrence of `58`, `76` or
`24` (the three quantities that move) on a non-history, unmarked line, ask whether any
`CLAIMS` regex claims **that occurrence** — testing the line alone and both straddle
joins, exactly as the guard does. Result over the live corpus: **36 unclaimed
occurrences**, of which these are count-bearing about the corpus:

They fall into **five failure modes**, not fifteen one-offs — which is what makes the
stage-2 fix below a bounded set of new regexes rather than an open-ended hunt:

| # | Mode | Live example |
|---|---|---|
| M1 | **Bare table cell.** A `\| **58** \|` Total row carries no noun at all, so every noun-anchored regex misses it by construction | `docs/aid-methodology.md:149` and its mirror `:153` |
| M2 | **A noun the array does not list.** `CLAIMS` binds *skills / skill directories / skill definitions / dirs / rows-with-a-backticked-template*; a sentence saying **files**, **directories** (bare), **sidecars**, **manifest** or plain **rows** matches nothing | `install.md:411` "76 `aid-`-prefixed skill markdown **files**"; `architecture.md:432` "has 76 **directories**"; `project-structure.md:182` "58-row **manifest**"; `tech-debt.md:160` "all 76 **sidecars**"; `capability-inventory.md:159` "Every one of the 58 **rows** owns…" |
| M3 | **Right noun, broken adjacency.** The regexes require the digit next to the noun. An intervening word defeats them | `domain-glossary.md:496` "58-row **single-source** catalog" vs `(\d+)-row catalog`; `aid-methodology.md:91` and `:130` "the other 24 **rows are hand-authored** `repurpose`" vs both `the other (\d+) are \`repurpose` and `(\d+) hand-authored \`?repurpose` |
| M4 | **Decomposition tail.** The head of a sentence matches and pins one quantity; the `+ N + N` breakdown after it is never examined | `diagram-content-reference.md:24`, `:104`; `glossary.md:68`; `reference/glossary.md:72`; `index.mdx:77` |
| M5 | **Deliberately-narrowed pattern, correctly excluding a live claim.** `(?<![\w/*])\`?skills\/\`?\s*\((\d+)\)` excludes a `*` on purpose (a glob is a module count, `:84-86`), which also excludes a real one | `module-map.md:76` `` `canonical/skills/*` (76) ``; `diagram-content-reference.md:109`, `:111` |

And one mode that no regex can close:

| # | Mode | Consequence |
|---|---|---|
| M6 | **Outside the extension filter.** `.aid/knowledge/kb.html` states the corpus total in three places and no `.html` is admitted by `EXT` (`:170`) | Unreachable by any `CLAIMS` entry — that half is permanent and no regex closes it. It is not a *stale-content* problem, though: `kb.html` is **regenerated** in §7 by re-running `/aid-summarize`, which rebuilds it from the refreshed `.aid/knowledge/*.md`. So the guard never sees it and never needs to; §10 carries the regeneration's own row instead |

The affected surfaces, so the stage-2 replay has a starting inventory (it is the replay,
not this list, that is the acceptance oracle — a hand list is exactly what drifts):

| Surface | Lines | Modes |
|---|---|---|
| `docs/aid-methodology.md` — entry-point paragraph, family narrative, **and the Skill Inventory table** | `:91`, `:130`, `:149` | M3, M1 |
| `site/src/content/docs/concepts/methodology.md` — independently maintained mirror | `:95`, `:134`, `:153` | M3, M1 |
| `docs/diagram-content-reference.md` | `:24`, `:104`, `:109`, `:111` | M4, M5 |
| `docs/glossary.md` / `site/src/content/docs/reference/glossary.md` | `:68` / `:72` | M4 |
| `docs/install.md` | `:411` | M2 |
| `site/src/content/docs/index.mdx` | `:77` | M4 |
| `.aid/knowledge/architecture.md` | `:432` | M2 |
| `.aid/knowledge/capability-inventory.md` | `:154`, `:159`, `:181`, `:286` | M2, M3 |
| `.aid/knowledge/domain-glossary.md` | `:481`, `:483`, `:496` | M2, M3 |
| `.aid/knowledge/module-map.md` | `:76` | M5 |
| `.aid/knowledge/project-structure.md` | `:182` | M2 |
| `.aid/knowledge/tech-debt.md` | `:160` | M2 |
| `canonical/aid/templates/shortcut-catalog.yml` | `:108` | M3 |
| `canonical/skills/aid-triage/references/state-classify.md` | `:85` | M2 |
| `.claude/skills/generate-profile/scripts/build-shortcut-skills.py` | `:12` | M3 |
| `.aid/knowledge/kb.html` | 3 places | **M6 — not fixable by a `CLAIMS` entry; discharged by §7's `/aid-summarize` re-run** |

`README.md` — the one individually-named file in the scan — is clean: every count it
states is claimed. **All five scanned trees** appear above, so the blind spot is
distributed across the whole scope rather than concentrated in one neglected corner;
that is the reason the fix is a `CLAIMS` extension and not a sweep of one directory.

**A second reason the guard alone is insufficient, independent of phrasing.** Its
`HISTORY_SHAPES` rule (`:216-219`) skips any dated table row or dated bullet, and its own
comment says so plainly: *"the rule is evadable… A live false claim formatted as a dated
bullet is skipped"* (`:211-214`). Today 16 such lines are skipped, of which **0 carry a
count** — the run prints exactly that — so nothing is hiding there right now, and this
work must not introduce one. That is a constraint on how new figures are written, not a
search: do not state a current count inside a dated bullet or a `\| N \| YYYY-MM-DD \|`
row.

**So the procedure has two stages, and the second one is the durable half.**

1. **Run the guard and fix what it reports.** It prints every disagreeing line with
   file, line, quantity and expected value. This half is exactly as before and remains
   the mechanism that exists because hand-hunting failed repeatedly — its own header
   documents two gate cycles that missed live falsehoods.
2. **Close the blind spot by extending `CLAIMS`, not by hand-hunting once.** The guard's
   own header states the design intent — *"Adding a phrasing or a path here extends
   coverage across the whole repo at once"* (`:24-26`) — so the fix for a phrasing the
   guard cannot see is a new `CLAIMS` entry, not a one-time sweep that leaves the next
   author in the same position. Add entries covering **M2–M4** (M1 and M5 are argued
   below), re-run the replay, and require it to reach **zero** unclaimed occurrences of
   the moving quantities. Three constraints on the new regexes, all learned from entries
   already in the array: bound the noun to a named set rather than opening it to `\w+`
   (`:75-77`); keep the `repurpose` / `shortcut` negative lookarounds intact (`:87-90`)
   so a correct number is never reported as wrong; and remember that a false positive
   costs the guard the credibility its real findings depend on (`:93-95`), so a phrasing
   that cannot be bounded safely is better rewritten in the document than forced into a
   regex.

   **M1 and M5 are closed by rewriting the document, not the guard.** For M1, a bare
   `\| **58** \|` Total cell has no noun for any pattern to anchor on; give it one — the
   Skill Inventory table's Total row becomes a labelled figure the `catalog rows`
   patterns can see (§7 makes the same edit for content reasons). For M5, the `*`
   lookbehind is a deliberate, documented exclusion (`:84-86`) that prevents a module
   count being read as a skill count; widening it would re-import the false positives it
   was written to remove, so `module-map.md:76` and `diagram-content-reference.md:109`
   `:111` are re-worded to a guarded phrasing instead. Weakening a correct guard to cover
   a document is the wrong direction of fix.

   `kb.html` (M6) is covered by **neither** route — a new `CLAIMS` entry cannot reach an
   `.html` file and rewriting an assembled artifact is not a fix. It is regenerated in §7
   instead, which is a third route and the only one that applies to a generated file.

The replay in stage 2 is the **oracle** for "counts true repo-wide", alongside the guard
itself; §10 carries both rows. A guard run that exits 0 while the replay still reports
unclaimed occurrences is a passing gate over a false document, which is the exact
failure this section exists to prevent.

Three of the guard's own constants need decisions — one table and two scalars, each a
deliberate decision rather than bookkeeping:

**(a) `SUPERSEDED`** — the marker is not a blank cheque; a `count-history` line may
only claim a value the quantity *actually held*. Superseded values must be added:

```js
'corpus total': [..., 76],      // 76 joins 10,12,13,14,67,82,92,94
'catalog rows': [69, 80, 58],   // 58 joins
'catalog canonical names': [..., 58],
'repurpose rows': [2, 4, 24],   // 24 joins
```
`'emitting shortcuts'` is **not** touched — 34 is still current (§2).

> Note a collision that is safe but looks alarming: `94` is already listed under
> `corpus total` (a historical corpus size) and becomes the *current* `catalog rows`
> value. `SUPERSEDED` is keyed per-quantity, so the two never meet. Recorded here so a
> reviewer does not "fix" it.

**(b) `MARKER_CAP = 12`** (a scalar, `:319`) — a deliberate ratchet held at exactly the
number of exemptions in use, with no headroom. Verified live: the guard currently
reports **exactly 12** marker-exempted lines against a cap of 12. So adding even one
`count-history` marker trips it *by design*, and the raise belongs in the same commit
with the reason stated there. Tripping it is expected behaviour, not a malfunction —
a reviewer who reads "exceeds the cap" as a broken guard will reach for the wrong fix.
Whether this work adds a marker at all is a per-line decision made while executing (a);
the raise is conditional on that, and the condition is the point.

**(c) `CLAIM_FLOOR = 120`** (a scalar, `:374`) — a floor on claims *checked*, guarding
against a regex refactor silently neutering the scan. Its own note says to set it *near
the live figure*, because "a floor an order of magnitude below the real count cannot do
that" (`:368-373`). The current run checks **175** against a floor of 120, so growth
alone would not force a change — but §3 stage 2 deliberately widens `CLAIMS`, which
raises the checked count further, and a floor left at 120 would then be slack rather
than a ratchet. **Raise it to the post-change live figure in the same commit as the new
`CLAIMS` entries**, with the reason stated there. This is a real edit, not a
considered-and-skipped note.

The guard is **green today** (520 files scanned, 175 claims checked, 12 marker-exempted
lines — verified by running it), which matters: any failure it reports during this work
is caused by this work, with no pre-existing noise to triage out.

### 4. The catalog assertions under `tests/` — eight edit sites in two files, plus a third file that must be re-bootstrapped

`deriveSkillCounts` covers prose. `tests/` is outside the count guard's scan entirely
(`check-skill-counts.mjs:36-39` lists it under NOT YET SCANNED), so **nothing** catches a
stale integer anywhere below. Three files are affected and each in a different way:
(a) carries the assertions that go red; (b) carries only comments, its assertions being
count-agnostic by design; (c) carries neither — it is a generated inventory whose size
tracks the catalog, guarded by its own CI lane.

**(a) `tests/canonical/test-deploy-monitor-repurpose.sh` — four assertions, two comment
blocks.**

| Site | Kind | Today | After |
|---|---|---|---|
| `:319` DMR30 `TOTAL_ROWS` — expected literal **and** message | assertion | 58 | 94 |
| `:320` DMR31 `CANONICAL_ROWS` — expected literal **and** message | assertion | 58 | 94 |
| `:321-323` DMR32 zero-alias — the expected literal is the whole sentence `"0 alias of 58 rows carrying an alias_of field"`, plus `the 58 rows` in the message | assertion | `0 alias of **58** rows` | `0 alias of **94** rows` |
| `:324` DMR33 `REPURPOSE_ROWS` — expected literal, plus the decomposition in the message | assertion | 24; `24 + 34 = 58` | 60; `60 + 34 = 94` |
| `:31-34` Part 4 header comment | comment | `58` rows, `58` canonical, `0` alias, `24` repurpose, other `34`, `24 + 34 = 58` | `94` / `94` / `0` / `60` / `34` / `60 + 34 = 94` |
| `:308-318` "Catalog size, by version" comment | comment | narration ends at work-004's `94 -> 58` rows and `30 -> 24` repurpose | **append** a new sentence (`58 -> 94` rows, `24 -> 60` repurpose); do **not** rewrite the earlier narration — `:317-318` says the record is "deliberately preserved, not overwritten" and that only its last figures are asserted |

**`DMR32` is the one that would otherwise be missed, and it is the reason this section
was rewritten.** Its expected value is not `0`; it is a sentence pairing the alias count
with `ALIAS_FIELD_LINES`, the same-anchor control (`:300-304`) that stops "0 alias rows"
passing for the wrong reason. `ALIAS_FIELD_LINES` counts every row carrying an
`alias_of:` key, so at 94 rows it reads 94 and the hardcoded `58` fails the suite. The
zero itself does stay `0` — every new row carries `alias_of: null` — but the assertion
still moves, which is exactly what REQUIREMENTS AC-11 means by *moving together*.

Derived, verified as needing no edit: `DMR34` (`:326`, canonical + alias == total),
`DMR35a` (`:331`), `DMR35b` (`:340`), `DMR36` (`:367`), and the `${TOTAL_ROWS}` banner
at `:306`.

**(b) `tests/canonical/test-catalog-dirs-parity.sh` — zero assertions, two comment
blocks.** The suite is count-agnostic by design (`:21-22`: "derives its row set from the
catalog and holds NO expected total, so it passes at any row count"), and that survives
this work. Its **header** does not:

| Comment block | Figures inside it | Today → After |
|---|---|---|
| `:13-17` the `repurpose`-exemption note | `24 \`repurpose\` rows` (`:14`) | 24 → **60** |
| | `the 3 classic re-registered pipeline skills` (`:15`) | 3 → **3, unchanged** — `classicRepurposed` does not move (§2), and `:16` already tells the reader to re-derive it |
| `:21-31` the post-change-composition note | `measured 2026-07-31` (`:23`) | → the date this work re-measures |
| | `58-row catalog = 58 canonical names (\`alias_of: null\`) + 0 aliases` (`:24`) | 58 / 58 / 0 → **94 / 94 / 0** |
| | `24 \`repurpose\` rows … + 34 shortcuts — 58 - 24 = 34`, and the independent awk pass that "also reaches 34" (`:25-27`) | 24 / 34 / `58 - 24 = 34` → **60 / 34 / `94 - 60 = 34`**, awk still 34 |

Two blocks, five figures, and the count-agnostic property at `:21-22` and `:17` ("The
suite reads the flag per row, so it needs no edit when that figure moves") is what makes
these comments rather than assertions.

**Both files carry a total of eight edit sites** — four assertions and two comment blocks
in (a), two comment blocks in (b) — which corrects an earlier framing that opened "two
test files hardcode integers" and then tabled sites from one. The closing report must
state the split explicitly, rather than implying `test-catalog-dirs-parity.sh` was left
untouched *or* that an assertion in it was changed.

**(c) A third file moves, with a live gate of its own: `tests/coverage-baseline.tsv`.**
This one is not a hardcoded integer — it is an *inventory* whose row count is driven by
the catalog row count, and it is the reason "count-agnostic by design" does not mean
"unaffected".

`test-catalog-dirs-parity.sh` emits **per-catalog-row** assertion keys: `CDP{i}a`
(directory exists), `CDP{i}b` (`aid-` prefix), `CDP{i}c` (`SKILL.md` exists) and
`CDP{i}d` (frontmatter `name` == directory == row) fire for every row, while
`CDP{i}e/f/g` (the thin-doorway body assertions) fire only for **non**-`repurpose` rows —
a `repurpose: true` row logs `CDP{i}e` as an exemption and `continue`s (`:143-146`). The
committed baseline records exactly that shape today: 59 each of `a`/`b`/`c` (58 rows plus
the `CDP00*` preflight), 58 `d`, and **34** each of `e`/`f`/`g`.

| Baseline key class | Today | After | Why |
|---|---|---|---|
| `CDP{i}a`, `b`, `c` | 59 | **95** | one per row + `CDP00*` |
| `CDP{i}d` | 58 | **94** | one per row |
| `CDP{i}e`, `f`, `g` | 34 | **34** | body assertions skip `repurpose: true`, and all 36 new rows are |
| `DMR*` | 46 | **46** | fixed keys; the baseline stores the ID (`DMR30`), not the message, so §4a's message edits do not move it |

Net: **144 new baseline rows** (36 × 4), and **zero** new `e/f/g` rows. That last cell is
a second, fully independent confirmation of §2's load-bearing `shortcuts`-stays-34 claim —
arrived at from the coverage inventory rather than from `deriveSkillCounts` — and if it
moves, §2 is wrong somewhere.

**The procedure is a re-bootstrap, not an edit.** `.github/workflows/coverage-parity.yml`
fires on any `tests/**` change (`:38-48`), which §4a and §4b guarantee. Its baseline is
**committed and therefore enforcing** — the header's "advisory" language applies only
while the file is absent, and the exit-code contract is "0 clean | 1 parity violation"
with 1 surfacing as a job failure (`:19-35`). A 144-row corpus-wide delta is not an
accept-list case; the runbook at `:23-30` applies: run the lane via `workflow_dispatch`
with `bootstrap: true`, download the `coverage-baseline` artifact, and commit **both**
`tests/coverage-baseline.tsv` and `tests/coverage-baseline.meta`. Hand-editing the `.tsv`
would desynchronise it from `.meta`'s provenance record.

**It cannot be done from the authoring worktree.** `collect` re-runs the entire canonical
corpus serially and needs a runtime-complete Linux environment (`pwsh` + `node` +
`python3`); the same header records that the corpus hangs under the local Windows shell,
which is why the baseline is captured in CI rather than committed from a laptop. So this
step has a **hand-off**, not just a command, and must be scheduled rather than assumed.

### 5. The site

**Nothing to build for the `design` family.** `site/scripts/skills/groups.mjs`
`assignGroups()` derives verb families by walking `catalog.rows` in file order
(`:253`), **skipping curated names** (`:254`), and appending each newly-seen verb
(`:258-262`); it then pushes one card per surviving row into that verb's family
(`:269-271`). `design` is
*already* a family — the shipped `aid-design` row (`shortcut-catalog.yml:441-442`,
`verb: design`) is the only one today and has always produced one. The **twenty-one**
new design rows add cards to that existing section; `brainstorm` appears as a new
single-card section automatically. Neither requires a code change.

AC-6 ("the `design` verb family is recognized and grouped") is therefore **already
true before this work starts**. An acceptance criterion that cannot fail is not a
criterion, so it is replaced by one that can:

> Given the finished corpus, when `assignGroups` runs, then it throws none of its four
> guards, **and the `design` family contains exactly 22 cards while `brainstorm`
> contains exactly 1**.

**Where 22 comes from, and why the earlier figure of 15 was wrong.** The figure is
**not derived here**: FR-11 **CC-7** fixes it, and FR-11's governing rule is that a
cross-feature contract is stated once and referred to, never restated — six specs
re-deriving the same number is precisely how they drifted apart the first time. So this
spec cites CC-7 and stops at the value.

The diagnosis of the old figure is this spec's own, and worth recording so the error is
not repeated: 15 was feature-005's contribution counted in isolation — its rows plus the
shipped `aid-design` — with the design rows that features 003 and 004 contribute
silently dropped. Every one of those carries `verb: design` and none is curated, so
every one produces a card. Getting this wrong matters more than an ordinary count error,
because the number exists **only** to give the replaced criterion something that can
fail; a criterion that fails at the true value is worse than the unfailable one it
replaced.

Two conditions make 22 the card count rather than merely the row count, and both are
verified: none of the 22 is in `CURATED_GROUPS` (`groups.mjs:63-111` — the curated
roster is 7 Support + 6 KB Maintenance + 5 Definition full-path + 1 Execution, and
holds no `aid-design*` and no `aid-brainstorm` name), and `assignGroups` emits one card
per non-curated row (`:269-271`). Contrast `query`: `aid-ask` **is** a catalog row but **is** curated, so it
produces no card at all — which is why "row count" and "card count" have to be checked
against the curated roster rather than assumed equal.

**Honest reading of the four guards.** Only **`unassignable skill`** can fire from this
work: it throws for any on-disk directory that is neither curated nor catalog-backed, so
thirty-six directories with thirty-six matching rows pass, and a single directory whose
row was forgotten fails loudly. `duplicate assignment` (`:161`) and `full-path catalog
row` (`:196`) fire only on a malformed or colliding `CURATED_GROUPS`, and `curated skill
missing` (`:206`) only on a deleted curated directory — none of which this work touches
(`CURATED_GROUPS` is **not** edited; all thirty-six are catalog-backed, including
`/aid-brainstorm`). They are named in the criterion as a *no-regression* clause, not as
the teeth, and the criterion would be dishonest if it implied otherwise — that being the
same defect it was written to fix.

**The card counts are the teeth, and they cover the gap the guards leave.** The clamp
guards on-disk-without-a-row; it explicitly does **not** guard row-without-a-directory
(`:265-268`: "the clamp only guards the other direction"). A row whose directory was
never created therefore throws nothing and simply yields one card fewer — invisible to
all four guards and visible to `design == 22`.

**One taxonomy warning, because three different "families" are in play and only one of
them is 22.** The 22 is the **verb** family `assignGroups` builds for the published
index. The catalog's `group:` field is a second axis: every new design row and
`/aid-brainstorm` carries `group: G3` ("Prototype + Design"), which today holds
`aid-prototype`, `aid-prototype-ui` and `aid-design` (3 rows, verified by grouping the
live catalog), so **G3 becomes 25**. And §7's methodology Skill Inventory table is a
third, hand-curated taxonomy that mostly tracks `group` but splits G5 (update /
refactor / remove / deprecate / migrate) and G11 (report+dashboard / review / research /
query) by verb and merges G9+G10 into "deploy + monitor" — so it is neither axis
exactly, and its Prototype + Design row takes **25**, not 22.

The three reconcile, which is the check worth carrying: the site's `design` (22) +
`prototype` (2) + `brainstorm` (1) verb families are exactly G3's 25. A figure of 22 in a
`group`-shaped context, or 25 in a card-count context, is wrong in both directions.
Conflating these axes is how the 15 survived the first pass.

### 6. Render and dogfood

1. `python .claude/skills/generate-profile/scripts/build-shortcut-skills.py` — reads
   the catalog, emits/refreshes generated doorways. All 36 rows are `repurpose: true`,
   so it emits **no** new directory; it is run to prove that, and to catch a row that
   accidentally lacks `repurpose`.
2. `python .claude/skills/generate-profile/scripts/run_generator.py` — **full run**.
   A partial render is the documented failure mode: `architecture.md § Gotchas`
   (`:490-502`) says "After any `canonical/` edit, run the FULL `run_generator.py` — not
   a per-script renderer — or CI render-drift fails on stale emission manifests." The KB
   names the same oracle step 5 does, which is why that step is not an invention here.
3. Resync **both** repo-root dogfood trees, not just the obvious one:
   `.claude/` from `profiles/claude-code/` **and** `.cursor/` from `profiles/cursor/`.
   This is the step that is forgotten: the dogfood trees are reached only by `setup.sh`,
   so nothing writes them as a side effect of the render. `.cursor/` is the half that
   gets forgotten *twice* — it holds 373 tracked files (`git ls-files .cursor | wc -l`)
   against `.claude/`'s 385, and it has its own byte-identity tuple with its own key
   prefix, so omitting it fails the very gate step 4 runs.
4. `tests/canonical/test-dogfood-byte-identity.sh` — three directions per tuple, and
   **two** tuples, defined at `:5-16`: tuple 1 is
   `profiles/claude-code/emission-manifest.jsonl` / `profiles/claude-code/.claude` ↔
   repo-root `.claude` (keys `DBI00*`, `DBI01`, `DBI-FWD/REV/ORPHAN`); tuple 2 is
   `profiles/cursor/emission-manifest.jsonl` / `profiles/cursor/.cursor` ↔ repo-root
   `.cursor` (keys `DBI-CUR00*`, `DBI-CUR01`, `DBI-CUR-FWD/REV/ORPHAN`). The two key
   sets are deliberately disjoint. Direction 3 is the one that catches a stale dogfood
   file left behind by step 3 — in either tree.
5. **The freshness oracle, which is a different check and not optional.**
   Re-run `run_generator.py`, then `git diff --exit-code -- profiles/`. This is CI's
   `render-drift` job (`.github/workflows/test.yml:44-63`), and it is the only oracle
   in this feature that can fail on a **stale or partial** render.

**A caveat that must be carried into the closing report**, because the test's own header
states it (`test-dogfood-byte-identity.sh:35-58`): all three artifacts each direction
compares — manifest, profile tree, dogfood tree — are outputs of the *same* generator
run; `canonical/`, the generator's input, is not among them. So **every** direction in
**both** tuples proves mutual consistency and **no** direction proves freshness: "if all
three artifacts are consistently stale, this suite is green." The header is not
speculating — it records that this suite was green over the stale trees a previous
re-render existed to replace, both before and after, and could not have detected it
either time.

That is why step 5 exists, and the header names the same pair explicitly:

| Property | Oracle |
|---|---|
| consistency | `test-dogfood-byte-identity.sh` — manifest ↔ profile tree ↔ dogfood tree |
| **freshness** | re-run the generator, then `git diff --exit-code -- profiles/` (CI `render-drift`) |
| semantic correctness | the catalog/dirs parity suite (§4b) and the count guard (§3) |

Without step 5, §10's "Render complete" row could not fail on a stale render, and C-5
(full render, never partial) would have no oracle at all — a partial render that happens
to be self-consistent is precisely what byte-identity cannot see.

### 7. KB and methodology refresh — final-state summaries, last

Refreshed **once**, after the roster settles. Mid-work staleness is correct, not a
defect.

The table is a work list, not a filter: any document §3 stage 1 or stage 2 reports is
also in scope even if it has no row here. The rows below are the ones that need
*authoring* beyond a number change.

**Knowledge Base (`.aid/knowledge/`).**

| Document | What changes | Count lines §3 must also reach |
|---|---|---|
| `capability-inventory.md` | The design family as a capability; the three-verb lifecycle | `:154`, `:159`, `:181`, `:286` — all guard-blind |
| `architecture.md` | Prose *and* its own count table (a known drift pair — the guard catches the table, a human must catch the prose) | `:432` — guard-blind |
| `module-map.md` | New skill directories | `:76` — guard-blind |
| `project-structure.md` | The `canonical/skills/` tree line and the catalog manifest row | `:95` (guarded), `:182` "58-row manifest" — guard-blind |
| `pipeline-contracts.md` | Per-skill state machines for the thirty-six | — |
| `domain-glossary.md` | *seed*, *design artifact*, plus `roadmap.md` and `backlog.md` | `:481`, `:483`, `:496` — guard-blind |
| `decisions.md` | Two decisions: why `design`/`create`/`update` over `export`/`document-`; why forward-looking documents were admitted to the KB | — |
| `test-landscape.md` | The assertions changed in §4 — all four `DMR*` keys including `DMR32`, the two count-agnostic-by-design notes, and the `coverage-baseline.tsv` re-bootstrap with its new row shape (§4c) | — |
| `tech-debt.md` | W1-11's live figure (`today 76 skills`) and its `:160` sidecar figure; **and the closure of W1-11's `kb.html` half** once the re-run below lands (the `W1-2` prose-population half stays open) | `:160` — guard-blind |
| `INDEX.md` | **Regenerated**, last of all: `bash canonical/aid/scripts/kb/build-kb-index.sh` | — |
| `kb.html` | **Regenerated** by re-running `/aid-summarize`, after every other document in this table is final — see the sub-section below for the procedure and its caveat | 3 places — guard-blind (`.html` is outside `EXT`) |

**Methodology narrative** — named here because the Description promises it and no
earlier draft of this spec named a file:

| Document | What changes |
|---|---|
| `docs/aid-methodology.md` | §1's entry-point paragraph (`:91`), the corpus footnote (`:101`), the family narrative (`:130`), and **the Skill Inventory table** (`:132-149`). Row deltas, taken from the sibling row tables at **feature-003 §1 (Skill inventory and catalog rows)** and **feature-004 §1 (Skill inventory and catalog rows)** rather than recounted here: `create` 12 → **19** and `update` 12 → **19**; `prototype + design` 3 → **25**; the other twelve rows unchanged at 31 combined; Total **58 → 94**. Two authoring decisions this table forces, neither of them mechanical: whether `/aid-brainstorm` earns its own row (the table already splits G5 and G11 by verb, so precedent exists both ways — it is folded into `prototype + design` above), and giving the Total row a noun so the count guard can see it (§3 stage 2, mode M1) |
| `site/src/content/docs/concepts/methodology.md` | The mirror of the above at `:95`, `:105`, `:134`, and its Skill Inventory table at `:136-153` — a **separate hand-maintained file**, not a render of `docs/`, so it drifts independently and both must be edited. The four-line offset between the two files is itself evidence they are not kept in lockstep by any mechanism |
| `docs/diagram-content-reference.md` | `:24`, `:104`, `:109`, `:111` — the skill-count trigger row and the two source-of-truth figures |
| `docs/glossary.md`, `docs/install.md`, `site/src/content/docs/reference/glossary.md`, `site/src/content/docs/index.mdx` | The decomposition tails at `:68`, `:411`, `:72`, `:77` |

Arithmetic check on the Skill Inventory table: `19 + 19 + 25 = 63` for the three moving
families, plus `1+1+1+1+1+7+11+3+1+1+2+1 = 31` unchanged across the other twelve, is
`94`. ✓ Cross-checked against the roster the other way: `58 + 36 = 94`. ✓ And the moving
families absorb exactly the 36 new rows: `(19-12) + (19-12) + (25-3) = 7 + 7 + 22 = 36`. ✓

**`kb.html` IS regenerated, by re-running `/aid-summarize`.** An earlier draft of this
section stated the opposite, on a premise that does not survive reading the skill: it
quoted `tech-debt.md` W1-11's claim that the file "**cannot be regenerated** — the
assembler's `.aid/.temp/summarize/` input tree no longer exists". That premise is false,
and W1-11 has been corrected. What is true:

- **The KB is the input, not the scratch tree.** `/aid-summarize`'s GENERATE state reads
  `.aid/knowledge/{doc}.md` for every resolved doc
  (`canonical/skills/aid-summarize/references/state-generate.md` § 2) and *writes*
  `.aid/.temp/summarize/summary-src/` — skeleton, per-doc section files and
  `section-manifest.txt` — during the same run (§ 5), which `assemble.sh` then
  concatenates into `.aid/knowledge/kb.html` (§ 8).
- **Its absence is expected, not a loss.** `.aid/.temp/` is gitignored (`.gitignore`:69);
  the tree is scratch space that exists only while a run is in flight. A fresh run
  recreates it and its manifest. The generator is not broken — the file is simply stale
  because the skill has not been re-run.
- **What is stale, measured rather than recalled.** M6's "three places" are three
  occurrences of the literal `75 skills`, two of them expanded — `75 skills (17 curated +
  58 catalog skills)` and `75 skills (17 curated pipeline/on-demand/router + a 58-row
  shortcut catalog…)` — against a live corpus of 76 / 58 / 18. Already two roster
  generations stale, i.e. the staleness predates this work rather than being caused by
  it. An earlier draft of this bullet also cited a `64 verb-first` figure; **no such
  string is in the file** — it reads `34 verb-first shortcuts`, which is *correct today
  and stays correct after this work* (§2, and cross-cutting risk 3 in PLAN.md). The
  re-run must reproduce that 34, not move it.
- The re-run clears all three of M6's occurrences as a side-effect of rebuilding from
  the refreshed KB, which is why §3 needs no `.html`-reaching `CLAIMS` entry.

**Procedure.** Run `/aid-summarize` **after** every other document in the table above is
final — it reads the KB, so a run started earlier bakes in the pre-refresh figures. It is
the last step of this section and of this feature. `kb.html` is **not** hand-patched:
hand-editing an assembled artifact makes it neither current nor reproducible, and the
next assembler run silently overwrites the edit.

**Two costs, stated so neither is discovered at execution time.**

1. **It is a long run, not a command.** The last recorded full GENERATE took **24m20s**
   and produced a 178 KB / 20-section file — `.aid/knowledge/STATE.md` § Calibration Log,
   the 2026-06-25 `aid-tech-writer (summarize GENERATE)` row (*"15-30m … 24m20s …
   kb.html 178KB/20 sections"*), corroborated by the § Summarization History row for the
   same date (177,780 bytes over an 18-doc KB, which is the 18 + 2 the §10 row uses).
   Size it as its own task, not as a line inside another one.
2. **The visual gate is an orchestrator step, not an automated one.** `validate-visuals.mjs`
   is SKIPPED because Playwright is not installed in the summarize package
   (`.aid/knowledge/STATE.md` § Knowledge Summary Status, **Visual-Gate Note**: *"V1
   visual gate must be run by the orchestrator"*). So this feature must **not** promise a
   passing automated visual gate. What it asserts is the machine half — the assembled
   file exists, is self-contained, and states the new figures — plus an explicit
   orchestrator-run V1, recorded in § Summarization History like every prior run. A §10
   row that claimed an automated visual pass would be a row that cannot run.

W1-11 is edited in the same pass: its `kb.html` half closes here, and the entry stays
open on its other survivor (`W1-2`'s hand-measured per-shape populations, still prose).

**No `release-tracking.md` entry.** Under the doctrine this work installs — stated in
REQUIREMENTS **§5.1 Knowledge Base doc-set additions** ("`release-tracking.md` becomes
**purely historical**: every section is a shipped version… At tag time the release flow
drains the committed items from `backlog.md` into a new `release-tracking.md` version
section"), restated as **AC-4**, and implemented in
feature-001 §4b, which makes `release-aid` Step 3.1 the sole writer of a version section
— writing a v3.0.0 slice here would be a second writer producing a section for a release
that has not been cut. That is exactly the pattern the doctrine removes. So: this
feature writes **no** release entry; the v3.0.0 section is authored at tag time by
`release-aid`, from `backlog.md`, outside this work. (`release-tracking.md` is also one
of the count guard's two `EXCLUDE_FILES` — `check-skill-counts.mjs:155-158` — because
its figures are true statements about past releases, so §3 will not report it either.)

Two of these documents (`roadmap.md`, `backlog.md`) are *conditional* and carry no
template under `canonical/`; feature-001 owns that, and this feature must not add one —
doing so would move the seed off 14 and break the doc-set resolution.

### 8. The two closing sweeps

**(a) Mutual negative routing.** The only place the AC-8 pair set can be verified whole.
Ownership is **not** restated here — FR-11 **CC-9** settles it, and the per-pair
assignment is tabled once, in **feature-005 §6c (The AC-8 pair set)**. An earlier draft
of this section asserted its own split ("feature-005 writes one side of three
cross-feature pairs and feature-004 the other"); that contradicted the sibling's own
table, where only one of the four pairs is split across two features and the rest are
owned end-to-end by a single feature. The correction is not to restate the right split
here — a fourth copy would drift like the third — but to stop asserting it at all and
read the pair set from CC-9 and feature-005 §6c at execution time. That is the whole
reason FR-11 exists.

What **is** this feature's own is the verification, and the reason it can only happen
here: whichever feature owns a side, no pair is checkable until every side exists.
Method: for each pair in the AC-8 set, assert each skill's `description` names its
neighbour. Reported as a table of pair → both directions present, because "the sweep
passed" is not evidence. A pair whose owning feature never wrote its side fails here as
a defect, which is the point of deferring the check rather than the authorship.

**(b) Pipeline untouched.** Three properties, each with a real oracle:

| Property | Oracle |
|---|---|
| `phase:` enum unchanged (C-1) | `git diff master -- canonical/aid/templates/work-state-template.md` shows no change to the `phase:` line. C-1 names this file as the enum's definition, so it is the right target and the diff is scoped rather than repo-wide |
| work/delivery/task hierarchy unchanged (NFR-3) | `git diff master -- .aid/knowledge/artifact-schemas.md` shows no change to the hierarchy definition |
| numbered sequence unchanged (NFR-3) | `git diff master -- .aid/knowledge/pipeline-contracts.md CLAUDE.md AGENTS.md` shows Discover→…→Execute untouched, **and** no new skill declares a `phase:`: `grep -l 'phase:' canonical/skills/aid-{design,create,update}-*/SKILL.md canonical/skills/aid-brainstorm/SKILL.md` returns nothing |

Two notes, because both rows are easy to over-read.

The third row is a **scoped** diff, never `git diff --exit-code`: §7 edits
`pipeline-contracts.md` on purpose (state machines for the thirty-six), so an exit-code
oracle there would be unsatisfiable by construction. What is asserted is that the
numbered sequence within it is unchanged. The same row's `grep` is the half that matters
most: the diff proves nobody *edited* the spine, the `grep` proves nobody *joined* it —
the actual risk, and one that a diff of three unrelated files cannot see. The positive
control for the `grep` is that it returns nothing today, because no shipped shortcut
skill declares a `phase:` either.

Both `CLAUDE.md` and `AGENTS.md` are named because the numbered sequence is stated in
both agent-context files; checking one and not the other has been a live drift source.

This sweep exists because the work adds thirty-six skills to a methodology whose
seven-step spine is a closed enum. The risk it guards is a skill quietly presenting
itself as a phase.

### 9. Scope note, restated honestly

This is the largest feature and it mixes mechanical render work with KB authoring.
Splitting was considered and deferred: the split point depends on how large the render
surface turns out to be, which is not knowable until the roster exists. §2–§6 have now
sized it, and the honest sizing is **larger than an earlier draft of this section
claimed**. That draft summed "four hardcoded assertions, one guard run" and concluded the
render half was smaller than assumed at definition time; each of those operands was
wrong or incomplete:

| Operand, as first stated | Corrected |
|---|---|
| no new generated directories | holds — all 36 rows are `repurpose: true` (§2, §6 step 1) |
| no site code change | holds — `assignGroups` derives families from data (§5) |
| four hardcoded assertions | **eight sites across two files** — four assertions plus four comment blocks, `DMR32` among them (§4) |
| one guard run | **a guard run plus a `CLAIMS` extension and a replay to zero**, because the guard cannot see every count-bearing line in its own trees (§3) |
| — (unaccounted) | the `.cursor/` resync, 373 tracked files with its own byte-identity tuple (§6 step 3) |
| — (unaccounted) | the freshness oracle, `render-drift` (§6 step 5) |
| — (unaccounted) | the `coverage-baseline.tsv` **re-bootstrap** — a third file, a second CI lane, and a CI-only hand-off that cannot run from the authoring worktree (§4c) |
| — (unaccounted) | the methodology Skill Inventory table and its independently-maintained site mirror (§7) |
| — (unaccounted) | the **`/aid-summarize` re-run** that regenerates `kb.html` (§7) — a ~24-minute authored run with an orchestrator-run visual gate, not a command; it also has to be **last**, so it serializes behind everything else in §7 |

So the render half is **not** demonstrably smaller than assumed; it is comparable, and
§7 (KB and methodology authoring) is still the larger share. The split point, if
`/aid-plan` finds this oversized, is unchanged — **§7, not §6** — and the reason is
unchanged too: §3–§6 form one causal chain from catalog to green gate, while §7 consumes
its result. What changes is that a split must not be justified by "the render half turned
out small", because that premise does not hold.

### 10. Verification

Every row names an oracle that **can fail**, and each cited key asserts the property its
row claims — checked against the source, not recalled. One row is a deliberate exception
and is labelled as such: **Not asserted here: an automated visual gate**. It is negative
space rather than an oracle, and it earns a row because leaving it out is what lets a
reader assume the summarize gate covers the rendered page. It is the only such row.

| What | Oracle |
|---|---|
| Rows valid | `test-catalog-dirs-parity.sh` — assertions unedited (count-agnostic by design), header comments updated per §4b; plus `DMR30`/`DMR31`/`DMR32`/`DMR33` at their new values |
| No orphan **row** (every row has a directory) | `DMR35b` (`test-deploy-monitor-repurpose.sh:336`, `:340`) and `CDP{i}a` (`test-catalog-dirs-parity.sh:126`). **Not `DMR35a`** — `:331` asserts the awk name-extraction agrees with the grep row count, which is an extraction control, not an orphan check |
| No orphan **directory** (every generated/repurpose dir has a row) | `DMR36` (`:367`) and `CDP-ORPHAN` (`test-catalog-dirs-parity.sh:187`, `:193`) |
| Build helper agrees | `CDP-HELPER` (`:202`) — `build-shortcut-skills.py --check` reports `OK:`, an independent byte-level drift detector over §6 step 1 |
| Render **consistent** | `test-dogfood-byte-identity.sh` green: three directions × two tuples, `DBI*` **and** `DBI-CUR*` keys both reported |
| Render **fresh**, and C-5 (full render, never partial) | Re-run `run_generator.py`, then `git diff --exit-code -- profiles/` — CI's `render-drift` (`.github/workflows/test.yml:44-63`). This is the **only** row that can fail on a stale or partial render; byte-identity provably cannot (§6) |
| Dogfood trees resynced | The `-ORPHAN` direction of **both** tuples, plus `git status --porcelain .claude .cursor` clean after the resync |
| Counts true repo-wide (guarded phrasings) | `node tests/canonical/check-skill-counts.mjs` exits 0, `claims checked ≥ CLAIM_FLOOR` at its raised value (§3c) |
| Counts true repo-wide (**un**guarded phrasings) | §3 stage-2 replay reports **zero** unclaimed occurrences of `76`/`58`/`24` over the guard's own scanned trees. Without this row the previous one can pass over a false document |
| `shortcuts` untouched | The guard reports 34 for `emitting shortcuts` and flags any line changed to 70. **Independent second oracle:** the re-bootstrapped baseline still holds exactly 34 `CDP{i}e`, 34 `f` and 34 `g` rows (§4c) — derived from the coverage inventory, not from `deriveSkillCounts`, so the two cannot fail together for a shared reason. **Third witness:** the regenerated `kb.html` must still read `34 verb-first shortcuts` (the `kb.html` row's conjunct (b)) — a generated file, so it cannot be talked into agreement |
| Coverage inventory in parity | `coverage-parity` lane green: baseline re-bootstrapped per §4c's runbook, `tests/coverage-baseline.{tsv,meta}` committed together, `coverage-parity.sh` exits 0. The gate **enforces** (the baseline is committed), so this row goes red by default if the re-bootstrap is skipped |
| Site families | `assignGroups` throws none of its four guards, **and** `design` = 22 cards, `brainstorm` = 1 (FR-11 CC-7). The card counts are the load-bearing half — §5 records that three of the four guards cannot fire from this work, and that a row with no directory throws nothing and only shows up as a missing card |
| `kb.html` regenerated, not patched (§7) | Four conjuncts, because no one of them can fail alone. (a) **M6 cleared:** `grep -c '75 skills' .aid/knowledge/kb.html` → `0` (it is `3` today) and `grep -c '58-row' ` → `0` (it is `2`), with the new figures present instead. (b) **The negative half, same file:** `grep -c '34 verb-first' ` is still `≥ 1` — a regeneration that swept `shortcuts` off 34 fails here, and this is the `shortcuts`-untouched row's third witness. (c) **Produced by the assembler, not edited:** `.aid/.temp/summarize/summary-src/section-manifest.txt` exists from this run; its non-blank, non-`#` line count equals the resolved doc-set count **+ 2** (`00-at-a-glance` and the trailing KB index, neither a doc section — `state-generate.md` § 5's ordering rule), and `kb.html`'s section anchors appear in that manifest's order. The `+ 2` is not assumed: § Summarization History records 18 docs → 20 sections and 19 docs → 21 sections. (d) **The run is recorded:** a new `## Summarization History` row in `.aid/knowledge/STATE.md` carrying output size, section count and the **orchestrator-run** V1 verdict — not an automated one (§7 cost 2). (a) alone passes on a hand-patch; (c) alone passes on a run started before the KB refresh, which is why §7 fixes the ordering |
| **Not asserted here:** an automated visual gate | Deliberately absent. `validate-visuals.mjs` is SKIPPED — Playwright is not installed in the summarize package (`.aid/knowledge/STATE.md` § Knowledge Summary Status) — so V1 is an orchestrator step. Naming it as a machine oracle would be a row that cannot run; row (d) above records the human verdict instead |
| Grade floor | Each artifact graded by `canonical/aid/scripts/grade.sh` meets the configured minimum (`A`) |
| Routing sweep | §8a's method, reported as one row per pair × both directions, over the pair set read from CC-9 and feature-005 §6c |
| Pipeline untouched | §8b — three scoped diffs **and** the `phase:` grep over the thirty-six, which is the clause a diff cannot cover |

Three rows, in two groups, deserve their reason stated.

The `shortcuts`-untouched row is deliberately a **negative** oracle. Every other row here
fails when work is missing; that one fails when work is *over-applied*, which is this
feature's most likely error mode.

`kb.html` now has **two** rows where an earlier draft had none, and the pair is the point.
That draft cited `tech-debt.md` W1-11's "cannot be regenerated" clause and concluded there
was no oracle to invent; the clause was false (§7) and W1-11 has been corrected, so the
positive row exists and can fail. The second row is the honest half: the *machine* half of
the summarize gate is assertable, the *visual* half is not, because Playwright is absent
from the summarize package. Stating both is what keeps the first row from being read as a
promise of a gate that cannot run.
