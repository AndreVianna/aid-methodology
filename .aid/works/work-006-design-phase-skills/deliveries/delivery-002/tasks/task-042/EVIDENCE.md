# task-042 EVIDENCE -- brownfield testing-strategy lifecycle across BOTH C6 documents

Closes BLUEPRINT criteria 4 and 5 for the `testing-strategy` artifact. Rows: feature-004 **V4**
(this task's share), **V5**, **V8**, **V9**'s `/aid-create-testing-strategy` clause, **V10**'s
**negative** half, **V19**, **V21**, **V25**'s behavioral half; §7e is the content rule and §8's
two-C6-document split the destination shape.

## 0. Preconditions

| Fact | Value |
|---|---|
| C6 test doc | `.aid/knowledge/test-landscape.md` -- **577** lines, `source: hand-authored` |
| C6 gate doc | `.aid/knowledge/quality-gates.md` -- **435** lines, `source: hand-authored` |
| `4.1.8` (the version task-041 landed in the C0 doc) | present in **neither** C6 doc at baseline -- which is the state V10's negative half must preserve |
| Skills invocable via | task-039's live throwaway render; this task rendered nothing and reverted nothing |
| Baseline | `git status --porcelain .aid/knowledge/ .aid/design/ .github/` -> empty |

Execution deviations are the three task-040 §0 states, unchanged. All four runs here have their
own allocation record (§5).

## 1. Run 1 -- `/aid-design-testing-strategy` (V4)

Seed written in `design-seed.md`'s shape (6 headings), `## Open questions` = `None`, and a
`## Destination` naming the two C6 halves **separately**: the test-landscape half (a
suite-to-lane mapping) and the gate-policy half (which lane blocks, who may waive).

```
$ git status --porcelain .aid/knowledge/ .github/          # (empty)
$ grep -c '^## ' .aid/design/testing-strategy.md            # 6
$ sed -n '/^## Destination/,$p' .aid/design/testing-strategy.md | grep -c test-landscape.md   # 1
$ sed -n '/^## Destination/,$p' .aid/design/testing-strategy.md | grep -c quality-gates.md    # 1
```

**V4 PASS.**

## 2. Run 2 -- `/aid-create-testing-strategy` (V5, V9, V10-negative, §4 row 1)

Realized into **both** populated C6 documents without refusing, each half into the document
that owns it, and consumed the seed.

```
$ test ! -f .aid/design/testing-strategy.md ; echo $?
0                                        # V5: seed consumed
$ git diff --name-only .aid/knowledge/
.aid/knowledge/quality-gates.md
.aid/knowledge/test-landscape.md         # V9: BOTH C6 docs ...
$ git diff --name-only .aid/knowledge/infrastructure.md | wc -l
0                                        # ... and NOT the C8 doc
$ git diff .aid/knowledge/test-landscape.md .aid/knowledge/quality-gates.md \
    | grep '^+' | grep -c '4\.1\.8'
0                                        # V10 NEGATIVE half: no version in either C6 doc
```

**V5 PASS. V9 PASS** -- a run naming only one of the two C6 documents would have failed.
**V10 (negative half) PASS**; the positive half was task-041's, and both halves name the same
version string, which is why the two tasks are ordered.

**§4 row 1, from the C6 side.** The test doc's CI section gained the suite-to-lane mapping and
nothing further:

```
$ git diff .aid/knowledge/test-landscape.md | grep '^+' \
    | grep -icE 'on: *(push|pull_request)|runs-on|workflow_dispatch|deploy to|promote to'
0                                        # no concrete stage/trigger/environment value added
$ git diff .aid/knowledge/test-landscape.md | grep '^+' | grep -c 'C8'
1                                        # the pipeline's own shape is CITED to the C8 doc
```

The only added line matching `stage|trigger|environment|promotion` is the disclaimer itself --
*"The pipeline's own shape -- its stages, triggers, environments and promotion between them --
is the project's **C8** document's to state, and is cited from here rather than restated."*
That is the row's requirement, not a violation of it, and it is recorded explicitly because a
naive grep reads the two identically.

The gate-policy half went to the gate document only: which lane blocks a PR, which block after
merge and on a tag, which is advisory, and who may waive.

## 3. Runs 3 and 4 -- `/aid-update-testing-strategy` (V8a, V8b)

```
# run 3, seed ABSENT
$ test ! -f .aid/design/testing-strategy.md ; echo $?      # 0
$ git diff --numstat .aid/knowledge/quality-gates.md
18  0                                    # V8a: completed and wrote, seedlessly

# run 4, fixture seed present (written BEFORE the run, Open questions empty)
$ test ! -f .aid/design/testing-strategy.md ; echo $?      # 0  -- consumed
$ git diff .aid/knowledge/quality-gates.md | grep -c 'Re-run once before considering a waiver'
1                                        # V8b: the seed's Current direction landed
$ ls .aid/design/
README.md  knowledge-graph-redesign.md   # no seed left behind
```

**V8a PASS. V8b PASS.**

## 4. V19 and V21, after all four runs

```
$ git diff .aid/knowledge/test-landscape.md .aid/knowledge/quality-gates.md \
    | grep -cE '^[+-](source|approved_at_commit):'
0                                        # V19: neither line touched in either document
$ bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge   # green after every writing run
```

**V21 / AC-11**, `comm -3` over Contents vs body (underscore-preserving slugs), after runs 2, 3
and 4:

| Document | body-only | toc-only | Verdict |
|---|---|---|---|
| `test-landscape.md` | (empty) | (empty) | **PASS** |
| `quality-gates.md` | (empty) | (empty) | **PASS** |

Neither run added a `## ` section, so neither `## Contents` needed a change -- and both stayed
consistent in both directions.

## 5. V25's behavioral half -- allocation records, captured before teardown

| Work folder | `initiator` | `phase` |
|---|---|---|
| `work-007-design-testing-strategy` | `aid-design-testing-strategy` | `Describe` |
| `work-008-create-testing-strategy` | `aid-create-testing-strategy` | `Describe` |
| `work-009-update-testing-strategy-noseed` | `aid-update-testing-strategy` | `Describe` |
| `work-010-update-testing-strategy-withseed` | `aid-update-testing-strategy` | `Describe` |

`sort -u` over the four values -> **one** distinct value, equal to the template's own seeded
default: **no run wrote `phase`.** The row's literal wording (`grep -c '^phase: .'` -> `0`)
remains unsatisfiable for the reason task-040 logged and task-041 confirmed -- the new
`work-state-template.yml` seeds a concrete `phase: Describe`. Third instance of that
oracle-wording defect; already filed for the gate.

## 6. Nothing created, nothing registered

CC-2's registration path does not fire here -- both C6 documents already existed -- and that is
checked rather than assumed:

```
$ git status --porcelain .aid/settings.yml .aid/knowledge/README.md
                                         # (empty)
```

## 7. Restoration

```
$ git diff --exit-code HEAD -- .aid/knowledge/test-landscape.md .aid/knowledge/quality-gates.md ; echo $?
0                                        # both C6 documents back to current HEAD
$ git status --porcelain .aid/knowledge/ .aid/design/
                                         # (empty)
$ ls -d .aid/works/*/ | grep -v work-006 | wc -l
0                                        # all four allocations torn down
$ git worktree list | wc -l
1
```

`git status --porcelain profiles/ .claude/ .cursor/` is identical before and after this task
(505 / 100 / 100 entries -- the live throwaway render, untouched). task-048 reverts it.
