# task-043 EVIDENCE -- brownfield cicd lifecycle, and the gate policy that stays out of the C8 doc

Closes BLUEPRINT criteria 4 and 5 for the `cicd` artifact -- the fourth and last of the
brownfield lifecycle rows. Rows: feature-004 **V4** (this task's share), **V5**, **V8**, **V9**'s
`/aid-create-cicd` clause, **V11**, **V19**, **V21**, **V25**'s behavioral half, plus §4 rows 1
and 3 read from the C8 side.

## 0. Preconditions

| Fact | Value |
|---|---|
| C8 destination | `.aid/knowledge/infrastructure.md` -- **322** lines, `source: hand-authored`, resolved from `.aid/settings.yml` (`infrastructure.md\|aid-researcher-quality\|required`) |
| Skills invocable via | task-039's live throwaway render; this task rendered nothing and reverted nothing |
| Baseline | `git status --porcelain .aid/knowledge/ .aid/design/ .github/` -> empty |

Execution deviations: the three task-040 §0 states, unchanged. All four runs have their own
allocation record (§5).

## 1. Run 1 -- `/aid-design-cicd` (V4, including the `.github/` conjunct)

```
$ git status --porcelain .aid/knowledge/ .github/
                                         # (empty) -- BOTH trees
$ test -f .aid/design/cicd.md ; echo $?  # 0
$ grep -c '^## ' .aid/design/cicd.md     # 6
```

**V4 PASS.** The `.github/` half of the conjunct is the one that fails if a `cicd` *design* run
edits a workflow file; it did not. The seed's own Constraints record that no workflow file is
written, because production config is opt-in per run and was not requested.

## 2. Run 2 -- `/aid-create-cicd` (V5, V9, V11, §4 rows 1 and 3)

Realized the promotion sequence into the populated C8 doc's `## CI/CD Pipeline` section and
consumed the seed.

```
$ test ! -f .aid/design/cicd.md ; echo $?
0                                        # V5: seed consumed
$ git diff --name-only .aid/knowledge/
.aid/knowledge/infrastructure.md         # V9: the C8 doc ONLY ...
$ git diff --name-only .aid/knowledge/test-landscape.md .aid/knowledge/quality-gates.md | wc -l
0                                        # ... and NEITHER C6 doc
```

**V11 -- the row this task exists for (§4 row 4).** The C8 diff **names the stage** and **cites**
the gate document, and contains no gate policy at all:

```
$ git diff .aid/knowledge/infrastructure.md | grep '^+' | grep -ci 'stage'
2                                        # the stage is named
$ git diff .aid/knowledge/infrastructure.md | grep '^+' | grep -ci 'quality-gate document'
1                                        # the gate doc is cited
$ git diff .aid/knowledge/infrastructure.md | grep '^+' | grep -niE 'threshold|blocks the merge|waive'
                                         # (empty) -- no policy crossed the boundary
```

The written text draws the line explicitly: *"The policy those gates apply -- what each one
demands of a change, and how an exception to it is handled -- is the project's quality-gate
document's to state, and is cited here rather than repeated."* That is the C8 side of the same
boundary task-042 verified from the C6 side.

**§4 rows 1 and 3, from the C8 side:**

```
$ git diff .aid/knowledge/infrastructure.md | grep '^+' | grep -ciE 'vitest|playwright|which suites'
0                                        # row 1: no which-suites-run claim (that is C6's)
$ git diff .aid/knowledge/infrastructure.md | grep '^+' | grep -ciE '[0-9]+\.[0-9]+\.[0-9]+'
0                                        # row 3: no build-tool version (that is C0's)
```

## 3. Runs 3 and 4 -- `/aid-update-cicd` (V8a, V8b)

```
# run 3, seed ABSENT
$ test ! -f .aid/design/cicd.md ; echo $?     # 0
$ git diff --numstat .aid/knowledge/infrastructure.md
19  0                                    # V8a: completed and wrote, seedlessly

# run 4, fixture seed present (written BEFORE the run, Open questions empty)
$ test ! -f .aid/design/cicd.md ; echo $?     # 0  -- consumed
$ git diff .aid/knowledge/infrastructure.md | grep -c 'absence of a result is not a result'
1                                        # V8b: the seed's Current direction landed
$ ls .aid/design/
README.md  knowledge-graph-redesign.md   # no seed left behind
```

**V8a PASS. V8b PASS.** With task-040 through task-042, **V8 is now closed for all four
foundation artifacts** in both directions.

## 4. V19, V21, and V11 re-checked across all four runs

```
$ git diff .aid/knowledge/infrastructure.md | grep -cE '^[+-](source|approved_at_commit):'
0                                        # V19
$ git diff .aid/knowledge/infrastructure.md | grep '^+' | grep -niE 'threshold|blocks the merge|waive'
                                         # (empty) -- still no policy after runs 3 and 4
$ bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge   # green after every writing run
```

**V21 / AC-11** over `infrastructure.md`, after runs 2, 3 and 4: `body-only` empty and
`toc-only` empty. No `## ` section was added, so `## Contents` needed no change and stayed
consistent both ways.

## 5. V25's behavioral half -- allocation records, captured before teardown

| Work folder | `initiator` | `phase` |
|---|---|---|
| `work-007-design-cicd` | `aid-design-cicd` | `Describe` |
| `work-008-create-cicd` | `aid-create-cicd` | `Describe` |
| `work-009-update-cicd-noseed` | `aid-update-cicd` | `Describe` |
| `work-010-update-cicd-withseed` | `aid-update-cicd` | `Describe` |

One distinct value across the four, equal to the template's seeded default: **no run wrote
`phase`.** Fourth and final instance of the oracle-wording defect logged at task-040 -- the row's
literal `grep -c '^phase: .'` -> `0` is unsatisfiable because the new `work-state-template.yml`
seeds `phase: Describe`. The gate now has all four instances.

## 6. Nothing created, nothing registered, no workflow file emitted

```
$ git status --porcelain .aid/settings.yml .aid/knowledge/README.md .github/
                                         # (empty)
```

Production config stayed opt-in: the user asked for none in any run, so none was emitted.

## 7. Restoration

```
$ git diff --exit-code HEAD -- .aid/knowledge/infrastructure.md ; echo $?
0                                        # the C8 document back to current HEAD
$ git status --porcelain .aid/knowledge/ .aid/design/ .github/
                                         # (empty)
$ ls -d .aid/works/*/ | grep -v work-006 | wc -l
0                                        # all four allocations torn down
$ git worktree list | wc -l
1
```

`git status --porcelain profiles/ .claude/ .cursor/` is identical before and after this task --
the live throwaway render, untouched. task-048 reverts it.
