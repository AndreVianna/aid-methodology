# task-064 EVIDENCE -- the site's generated skill surface regenerated

feature-006 §5, card count fixed by REQUIREMENTS FR-11 **CC-7**. Closes BLUEPRINT criterion **8**.

## 1. "The site needs no code change" is true, and is not the whole obligation

`assignGroups()` derives verb families by walking `catalog.rows` in file order, so `design` gains
cards and `brainstorm` appears as a new single-card section **with no edit to that file**. What
*does* move is the generated content the site commits. Both generators were run in the order
`site/package.json`'s `prebuild` uses:

```
$ node scripts/gen-reference.mjs      Done.
$ node scripts/gen-skills.mjs         completed (advisory extractor notes only)
```

| Surface | before | after |
|---|---|---|
| `site/src/content/docs/skills/*.md` | 76 (75 skills + index) | **112** (111 skills + index) |
| `site/src/data/skill-flows/*` | 75 | **111** |
| `site/scripts/.skills-manifest.json` | -- | regenerated |
| `site/src/content/docs/reference/skills.md` + `.reference-manifest.json` | -- | regenerated |

**220 files** changed under `site/`. The page count tracks the corrected roster of **111**, not the
DETAIL's 112 -- the `aid-graph` off-by-one task-050 established.

## 2. The card counts CC-7 fixes

Counted from the published index rather than predicted:

```
### design       cards = 22
   aid-design, -roadmap, -mvp, -backlog, -api, -ui, -theme, -cli, -data-model,
   -data-pipeline, -messaging, -integration, -job, -config, -infra, -test,
   -document, -dashboard, -architecture, -stack, -testing-strategy, -cicd
### brainstorm   cards = 1
   aid-brainstorm
```

**22 and 1**, exactly. `brainstorm` appears as its own single-card section, which is the property
feature-005 V19 asserted statically and this task confirms at run time.

**`assignGroups` threw none of its four guards** -- *duplicate assignment*, *full-path catalog
row*, *curated skill missing*, *unassignable skill* -- all four exist in the source and
`gen-skills.mjs` ran to completion.

## 3. A prediction I carried from the DETAIL, corrected by the run

task-053's evidence said relocating a `State machine:` line into a body would "newly fire R1" in
`extract-residual.mjs`, and that this is why task-064 is a descendant of every slice. **R1 did not
fire for any of the four relocated skills.** Their sidecars are built by `extract-dispatch`, which
outranks R1: each of those skills carries a `## Dispatch` table, so the residual rung is never
consulted.

| Skill | extractor | sidecar changed by this run |
|---|---|---|
| `aid-describe` | `extract-dispatch` | yes |
| `aid-housekeep` | `extract-dispatch` | yes |
| `aid-summarize` | `extract-dispatch` | no |
| `aid-update-kb` | `extract-dispatch` | no |

Across all 111 sidecars the rung distribution is `inline` 44, `extract-engine` 34,
`extract-sibling` 13, `extract-dispatch` 13, `residual` 7 -- so R1 does fire, just not for these.

The task's *placement* is still correct for the reason it was placed: every skill page embeds its
skill's full description verbatim, so the AC-12 sweep moves all of them and this task must run
after every slice. Only the mechanism named in the earlier note was wrong.

## 4. The reference page

`gen-reference.mjs` rewrote `reference/skills.md`, whose roster statement reads **"all 111
skills"** -- the corrected figure, consistent with the page count above. Its
`34 engine-driven verb-first shortcut skills` line is unchanged in substance; the emitting quantity
has not moved, which is the invariant AC-11 protects.
