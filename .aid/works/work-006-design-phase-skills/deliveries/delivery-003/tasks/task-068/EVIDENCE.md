# task-068 EVIDENCE -- the methodology narrative, its Skill Inventory Total, and the mirrors

feature-006 §7's *Methodology narrative* table and §3's surface inventory. Closes the methodology
half of BLUEPRINT criterion **9** and these files' share of criterion **4**.

## 1. A correction to §7, made against disk

§7 calls `site/src/content/docs/concepts/methodology.md` *"a **separate hand-maintained file**, not
a render of `docs/`"*, offering the four-line offset between the two as evidence. **That is false.**
`site/scripts/sync-docs.mjs`'s `MANIFEST` maps `aid-methodology.md` -> `concepts/methodology.md`
and `glossary.md` -> `reference/glossary.md` (among others). The offset is the sync transform -- it
strips the leading H1 and injects a four-line frontmatter block -- not independent maintenance.

So **two** of §7's named site edit sites are **generated**, and hand-editing either would be
overwritten by the next `prebuild`, which runs `sync:docs` before every build.
`site/src/content/docs/index.mdx` is **not** in the manifest and is genuinely hand-maintained.

The procedure followed was therefore: edit the four `docs/` sources plus `index.mdx`, then run
`node site/scripts/sync-docs.mjs` and commit the regenerated mirrors. One mechanism instead of two
hand-edits kept in lockstep by nothing -- which removes the drift §7's row was describing rather
than reproducing it.

## 2. The Skill Inventory table, with its arithmetic checked

The table's families are not the catalog's verbs -- `create-test` sits under *test + experiment*,
`create-document` under *document*, `create-dashboard` under *report + dashboard*. So the row
deltas were computed against that grouping and the result checked by summation:

| Family | was | now |
|---|---|---|
| create | 12 | **19** (+7: roadmap, backlog, mvp, architecture, stack, testing-strategy, cicd) |
| update | 12 | **19** (+7, the same artifacts) |
| prototype + design | 3 | **split** |
| -- `prototype` | -- | **2** |
| -- `design` | -- | **22** |
| -- `brainstorm` | -- | **1** |
| all others | unchanged | unchanged |
| **Total** | **58** | **94** |

Splitting *prototype + design* is what makes the numbers legible: the `design` family is now the
second largest in the catalog, and folding 22 rows into a row labelled for prototypes would have
hidden it. The summed family counts are
`19+19+1+1+1+1+1+7+2+22+1+11+3+1+1+2+1` = **94**, matching the stated Total and the catalog's own
`grep -c '^  - name:'`.

Cross-checked against the catalog by verb: `create` 23 rows minus the 4 that live in other family
rows = 19; `update` 22 minus 3 = 19; `design` 22; `brainstorm` 1; `prototype` 2.

## 3. Every surface, and the figure each one names

**19 count sites** moved across the five hand-authored sources. The `shortcuts` (emitting)
quantity **34** appears throughout and was not touched at any of them:

| Surface | sites moved |
|---|---|
| `docs/aid-methodology.md` | 6 (entry paragraph, corpus footnote, family narrative, the table, the repo tree line, `58-row` phrasings) |
| `docs/diagram-content-reference.md` | 6 |
| `docs/glossary.md` | 7 + a new **Design seed** entry defining the `design -> create -> update` lifecycle |
| `docs/install.md` | 2 |
| `site/src/content/docs/index.mdx` | 5 |

Then `sync-docs.mjs` regenerated `concepts/methodology.md` and `reference/glossary.md`, and the
mirror's Total reads **94**, matching its source by construction rather than by a second edit.

A final detector pass over all seven surfaces -- looking for `75`/`76`/`58` beside a
skill/row/catalog noun, or `24` beside `hand-authored`/`repurpose` -- returns **clean** on every
one. Getting there took four passes: the obvious sites went first, then `58-row` as a phrase, then
three variants the earlier patterns missed (`58 rows owns`, `all 58 catalog rows`,
`34 ... + 24 hand-authored`). Recorded because it is the shape of the risk criterion 4 names:
a count-bearing sentence hides in whatever phrasing the author happened to use.
