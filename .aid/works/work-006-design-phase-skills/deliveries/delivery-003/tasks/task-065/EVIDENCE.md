# task-065 EVIDENCE -- four "what AID has" Knowledge Base documents describe the design family

feature-006 §7's KB table, rows `capability-inventory.md`, `architecture.md`, `module-map.md` and
`project-structure.md`. Closes the first four documents of BLUEPRINT criterion **9** and their
share of criterion **4**.

## 1. The per-quantity delta -- and two figures the DETAIL gets wrong

Every figure was derived from the catalog and the corpus at execution time, never copied:

| Quantity | Was | Now | DETAIL says |
|---|---|---|---|
| skill directories | 75 | **111** | 112 -- **wrong** |
| catalog rows | 58 | **94** | 94 |
| canonical names | 58 | **94** | 94 |
| `repurpose` rows | 24 | **60** | 60 |
| aliases | 0 | **0** | 0, unchanged |
| `shortcuts` (emitting) | 34 | **34** | 34, unchanged |
| `curatedOnly` | 17 | **17** | 18 -- **wrong** |
| `classicRepurposed` | 3 | **3** | 3, unchanged |

The two wrong figures are the `aid-graph` off-by-one task-050 established and logged against the
whole delivery. They are **independently corroborated** here: `module-map.md` and
`project-structure.md` already said **75** directories and **17 curated** before this task
touched them, because the upstream removal commit corrected them. So three sources agree on 17
and none on 18.

`111 = 94 catalog rows + 17 curated rowless` closes exactly.

## 2. Why "update every count" would have corrupted these files

Roughly half the count-bearing sentences in these documents use the `shortcuts` phrasing, and that
quantity **does not move**. Each edit was made against the quantity the sentence actually names.
The discipline shows in the final state: `34` appears throughout all four documents and was never
touched, while `58 -> 94` and `24 -> 60` moved wherever they appeared.

**18 count sites moved**, found by sweeping rather than by working from the DETAIL's line numbers
-- which had drifted:

| Document | sites moved |
|---|---|
| `capability-inventory.md` | 8 |
| `architecture.md` | 8 |
| `module-map.md` | 4 |
| `project-structure.md` | 3 |

A final regex sweep over all four for a stale `76`/`58`/`112`/`24`/`18` adjacent to a
skill/row/catalog/directory/repurpose noun returns **clean** on every document. Two matches were
correctly *not* changed: `~24 lines` in `module-map.md`'s structural table is a line count, not a
row count.

## 3. What each document gained

**`capability-inventory.md`** -- the `design` stage as a capability, with the three-verb lifecycle
stated as a table keyed on *the state the work is in*, which is what a caller chooses between:
`design` when the shape is still open, `create` when a ready seed exists and the destination does
not, `update` when the destination exists and has drifted. It records the three `create` refusals
and no fourth, that a repeat `create` routes rather than overwrites, and that `update` needs no
seed but consumes one. Its verb-family table gained the 21 new `design` rows, a `brainstorm` row,
and the seven new `create` and seven new `update` `repurpose` entries.

**`architecture.md`** -- a `Design` row in the workflow table, and prose on the shared contract:
the 22 `design` rows **bind** `design-lifecycle.md` rather than restating it, which is what keeps
36 skills consistent without 36 copies of the rules, and why adding an artifact is a catalog row
plus a thin body rather than a new state machine.

**`module-map.md`** -- two new structural shapes for the new directories: the `design` seed-writer
(binds the contract, writes only `.aid/design/<artifact>.md`) and the foundation `create`/`update`
pair (realizes a seed into a KB document, or revises one).

**`project-structure.md`** -- the `canonical/skills/` tree line and the catalog manifest row now
read 111 / 94 / 60.

## 4. One instruction that is moot, and why

The DETAIL requires `module-map.md`'s `` `canonical/skills/*` (76) `` line to be **re-worded** into
a phrasing the count guard can see, because a deliberate `*` lookbehind in
`check-skill-counts.mjs` excluded it (mode M5), and it argues -- correctly -- that weakening the
guard to accommodate a document is the wrong direction of fix.

**That guard no longer exists.** `check-skill-counts.mjs` was retired upstream; under
`RESCOPE-COUNT-GUARD.md` public-doc counts are guarded by `test-doc-counts.sh` and counts inside
`canonical/` and `.aid/knowledge/` are reviewer-governed under criterion `G-01`. There is no guard
left for the line to be made visible to, so the figure is simply corrected in place and the line
keeps its natural phrasing. Recorded rather than silently skipped.

`bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` is **green**.
