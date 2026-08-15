# task-050 EVIDENCE -- the catalog validated over the finished set

Closes BLUEPRINT criterion **1**. delivery-003's entry task and a **read-only audit**: it is the
single edge by which this delivery joins the graph, so every delivery-001 and delivery-002 task is
an ancestor and the set it validates is complete. Validation before mutation is the point --
every later task here consumes the catalog, and a bad row would be propagated by the render into
five profiles and two dogfood trees before anything noticed.

Every diff row is stated against **`origin/master`**, per the standing instruction the
delivery-002 gate recorded after finding the local `master` ref 100 commits stale.

## 1. The finding that matters most for this delivery: 111 directories, not 112

The two quantities are asserted separately, because the corpus is larger than the catalog by the
curated skills that own no row:

```
$ grep -c '^  - name:' canonical/aid/templates/shortcut-catalog.yml
94                              # PASS -- exactly the BLUEPRINT's figure
$ ls -1d canonical/skills/*/ | wc -l
111                             # the BLUEPRINT says 112
```

**Cause established rather than guessed:** `aid-graph` was removed upstream (commit `b8b01b1b`
*"Completely remove aid-graph skill"*), and it was a **curated, rowless** skill --

```
$ git show b8b01b1b^:canonical/aid/templates/shortcut-catalog.yml | grep -c '^  - name: aid-graph$'
0                               # it never had a catalog row
$ git ls-tree -d --name-only b8b01b1b^ canonical/skills/ | wc -l   -> 76
$ git ls-tree -d --name-only b8b01b1b  canonical/skills/ | wc -l   -> 75
```

so its removal moved the directory count by exactly one and the row count by zero. Both of the
BLUEPRINT's derived figures are therefore off by one in the same direction, and the corrected
arithmetic closes exactly:

| Quantity | BLUEPRINT | Actual | Why |
|---|---|---|---|
| catalog rows | 94 | **94** | unchanged -- `aid-graph` had no row |
| skill directories | 112 | **111** | `aid-graph` removed upstream |
| curated skills owning no row | 18 | **17** | same removal |
| | | `111 = 94 + 17` | closes |

The 17 curated rowless skills, enumerated for the record: `aid-config`, `aid-create-ticket`,
`aid-define`, `aid-describe`, `aid-detail`, `aid-discover`, `aid-execute`, `aid-housekeep`,
`aid-plan`, `aid-read-ticket`, `aid-set-connector`, `aid-specify`, `aid-summarize`, `aid-triage`,
`aid-unset-connector`, `aid-update-kb`, `aid-update-ticket`.

**This propagates.** Every count-bearing surface in this delivery that would state `112` must
state `111`, and every one that would state `18 curated` must state `17` -- tasks 059, 062, 069
and the Knowledge Base / methodology tasks 065-068. Logged for the delivery, and this task states
it once here rather than letting each later task rediscover it.

## 2. `name` == directory == frontmatter `name:`, `aid-` prefixed, for all 94 rows

```
$ bash tests/canonical/test-catalog-dirs-parity.sh
PASS                            # CDP{i}a/b/c/d are exactly these conjuncts, one set per row
$ git diff origin/master -- tests/canonical/test-catalog-dirs-parity.sh
0 lines                         # green UNMODIFIED -- it is count-agnostic, so it extends by data
$ grep '^  - name:' "$C" | sed 's/^  - name: //' | grep -c '^aid-'
94                              # 94/94 carry the prefix
```

## 3. `alias_of: null` on every row, count-free

```
$ [ "$(grep -c '^    alias_of: null$' "$C")" = "$(grep -c '^  - name:' "$C")" ]
94 == 94   PASS
```

It fails if any row omits, misspells or aliases the field, and holds at any row count.
`test-catalog-dirs-parity.sh` is deliberately **not** the oracle here -- the catalog's own field
contract records `alias_of` as parsed-then-never-read dead input in that suite.

## 4. `repurpose: true` on every hand-authored row, asserted so the emitting count cannot move

The count-free form of *"the `shortcuts` (emitting) quantity does not move"*:

```
rows carrying NO repurpose key:   HEAD = 34,   origin/master = 34
$ comm -3 <sorted HEAD set> <sorted origin/master set>
                                 # empty -- PASS
```

All thirty-six rows this work adds are hand-authored, so a row that lost the key would appear in
that difference. No expected integer is stated here on purpose: the integers belong to task-059,
task-062 and task-069, and a figure stated in two places is how the two copies drift. It follows
arithmetically that `repurpose: true` rows = 94 - 34 = **60**, and the file agrees
(`grep -c '^    repurpose: true$'` -> 60).

## 5. `CDP-HELPER` -- the independent byte-level cross-check

```
$ python3 .claude/skills/generate-profile/scripts/build-shortcut-skills.py --check
OK: 34 doorway(s) up to date, 60 repurpose row(s) skipped, 0 orphan(s).
```

Exit 0, and the line begins `OK:`. That proves the sixty `repurpose` rows were skipped and the
thirty-four generated doorways are byte-current **before** task-060 renders them. Three of the
BLUEPRINT's four figures -- 94 rows, 60 `repurpose`, 34 emitting -- are confirmed by this single
independent instrument; the fourth (the directory count) is the one §1 corrects.

## 6. The two count-bearing instruments: deliberately not run, and why

| Instrument | State | `git diff origin/master` |
|---|---|---|
| `tests/canonical/test-deploy-monitor-repurpose.sh` | not run, not edited -- still holds the pre-work integers (`TOTAL_ROWS`/`CANONICAL_ROWS == 58`, `REPURPOSE_ROWS == 24`) that **task-062** retunes | **0 lines** |
| `tests/canonical/check-skill-counts.mjs` | **retired upstream** (deleted by work-004); superseded by `RESCOPE-COUNT-GUARD.md`, under which public-doc counts are guarded by `test-doc-counts.sh` and `canonical/` counts are reviewer-governed under `G-01` | **0 lines** |

Running either now would report a correct mid-work state as a failure.
`git diff origin/master -- tests/` over the whole tree is **0 lines**.

## 7. This task wrote nothing

```
$ git status --porcelain canonical/ tests/ site/ docs/ .aid/knowledge/ profiles/ .claude/ .cursor/
0 entries                       # identical before and after
$ git diff --cached --name-only  # (empty)
```

Every row is a `grep`, a `comm`, a scoped `git diff` or a named suite over committed content, so
two executions produce identical outcomes and there is nothing to tear down.
