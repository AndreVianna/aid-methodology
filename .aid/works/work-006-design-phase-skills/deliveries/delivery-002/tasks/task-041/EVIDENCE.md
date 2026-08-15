# task-041 EVIDENCE -- brownfield stack lifecycle, and the version that lands in the C0 doc

Closes BLUEPRINT criteria 4 and 5 for the `stack` artifact. Rows covered: feature-004 **V4**
(this task's share), **V5**, **V8**, **V9**'s `/aid-create-stack` clause, **V10**'s positive
half, **V19**, **V21** and **V25**'s behavioral half.

## 0. Preconditions

| Fact | Value |
|---|---|
| C0 destination | `.aid/knowledge/technology-stack.md` (**262** lines, `source: hand-authored`), resolved from `.aid/settings.yml` (`technology-stack.md\|aid-researcher-architecture\|required`) |
| D destination | `.aid/knowledge/decisions.md` (**553** lines, `source: hand-authored`), resolved the same way (`decisions.md\|aid-researcher-architecture\|required`) -- already present and `required`, so nothing is created there |
| Skills invocable via | task-039's throwaway render (live; this task rendered nothing and reverted nothing) |
| Baseline | `git status --porcelain .aid/knowledge/ .aid/design/ .github/` -> empty |

**Execution deviations** are the same three task-040 §0 states, for the same reasons, and are
not repeated here: manual runs, no `aid-architect`/`aid-reviewer` dispatch per run (content
quality is asserted by no row here), and work-folder allocation without a git worktree.
Unlike task-040, **all four runs here have their own allocation record** (§6).

## 1. Run 1 -- `/aid-design-stack` (V4)

Wrote `.aid/design/stack.md` in `design-seed.md`'s shape (6 headings), `## Open questions`
holding the literal `None`, and a `## Destination` naming **two** destinations -- the C0 doc for
the chosen pin and the **D** doc for the rejected alternative. Its `## Current direction` named
a specific test framework **and** its version: **vitest 4.1.8**.

```
$ git status --porcelain .aid/knowledge/ .github/
                                          # (empty)
$ grep -c '^## ' .aid/design/stack.md
6
$ sed -n '/^## Destination/,$p' .aid/design/stack.md | grep -c technology-stack.md   # -> 2
$ sed -n '/^## Destination/,$p' .aid/design/stack.md | grep -c decisions.md          # -> 2
$ sed -n '/^## Current direction/,/^## /p' .aid/design/stack.md | grep -oE 'vitest [0-9.]+'
vitest 4.1.8
```

**V4 PASS.**

## 2. Run 2 -- `/aid-create-stack` (V5, V9, V10)

Realized into the **populated** C0 doc without refusing, wrote the rejected alternative to the
**D** doc as a new `## D27` entry, and consumed the seed.

```
$ test ! -f .aid/design/stack.md ; echo $?
0                                         # V5: seed consumed
$ git diff --name-only .aid/knowledge/
.aid/knowledge/decisions.md
.aid/knowledge/technology-stack.md        # V9: the C0 doc PLUS the D doc -- both, as required
$ git diff .aid/knowledge/technology-stack.md | grep '^+' | grep -c '4\.1\.8'
1                                         # V10 positive half: the version string landed in the C0 doc
```

**V5 PASS. V9 PASS** -- the D doc is *this artifact's own* second destination, not another
artifact's, which is the distinction the row exists to make. **V10 (positive half) PASS**; its
negative half (a version must NOT appear in a C6 doc) is task-042's.

The C0 write landed the pin inside `## Test Commands`, beside the `npm test` line it governs --
an existing section, so no `## ` section was added and `## Contents` needed no change. The D
write added `## D27` **and its matching `## Contents` entry in the same pass**, which is the
create skill's stated obligation.

## 3. Run 3 -- `/aid-update-stack`, seed **absent** (V8a)

```
$ test ! -f .aid/design/stack.md ; echo $?
0                                         # precondition: no seed
$ git diff --numstat .aid/knowledge/technology-stack.md
3   1                                     # completed and wrote, seedless
```

**V8a PASS** -- it neither refused nor named a missing seed.

## 4. Run 4 -- `/aid-update-stack`, fixture seed present (V8b)

The step-4 seed is a fixture written **before** the run began, with `## Open questions` empty
and a `## Current direction` naming a checkable outcome ("the lockfile is authoritative on
disagreement").

```
$ test ! -f .aid/design/stack.md ; echo $?
0                                         # fixture seed consumed
$ git diff .aid/knowledge/technology-stack.md | grep -c 'lockfile is authoritative'
1                                         # the seed's Current direction landed
$ ls .aid/design/
README.md  knowledge-graph-redesign.md    # no seed left behind
```

**V8b PASS.**

## 5. V19 and V21

```
$ git diff .aid/knowledge/technology-stack.md .aid/knowledge/decisions.md \
    | grep -cE '^[+-](source|approved_at_commit):'
0                                         # V19: neither line touched in either doc
$ bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge   # green after every writing run
```

**V21 / AC-11 -- `## Contents` vs body, both directions, after runs 2, 3 and 4.** Slugs compared
with `comm -3` (underscore-preserving, matching the anchor form the documents actually use):

| Document | body-only | toc-only | Verdict |
|---|---|---|---|
| `technology-stack.md` | (empty) | (empty) | **PASS** |
| `decisions.md` | `d26--no-line-coverage-metric-...` | (empty) | this run's writes are consistent; see below |

**The one `decisions.md` discrepancy is PRE-EXISTING and is not this run's.** `## D26` exists in
the body with no `## Contents` entry, and that is already true at `HEAD`:

```
$ git show HEAD:.aid/knowledge/decisions.md > /tmp/dec_head.md
$ grep -c '^## D26' /tmp/dec_head.md ; grep -c '^- \[D26' /tmp/dec_head.md
1
0                                         # gap present before this task ran
$ grep -c '^## D27' .aid/knowledge/decisions.md ; grep -c '^- \[D27' .aid/knowledge/decisions.md
1
1                                         # this run's own entry IS consistent
```

Logged to `delivery-002-issues.md` as a KB defect rather than fixed here: repairing another
document's pre-existing table of contents is outside this task's declared write set.

One methodological note: a first pass of this check reported a second `decisions.md`
discrepancy on `d13--per-repo-format_version-...`. That was a **false positive in the check**,
not a defect -- the slugifier was stripping `_`. Recorded because a reviewer re-running a
naive version of this comparison will see it too.

## 6. V25's behavioral half -- allocation records, captured before teardown

All four runs allocated through `writeback-state.sh --pipeline`; **no run wrote `phase`**:

| Work folder | `initiator` | `phase` |
|---|---|---|
| `work-007-design-stack` | `aid-design-stack` | `Describe` |
| `work-008-create-stack` | `aid-create-stack` | `Describe` |
| `work-009-update-stack-noseed` | `aid-update-stack` | `Describe` |
| `work-010-update-stack-withseed` | `aid-update-stack` | `Describe` |

```
$ for w in ...; do grep -m1 '^phase:' .aid/works/$w/STATE.yml; done | sort -u | wc -l
1                                         # one distinct value, equal to the template's own default
```

**V25's behavioral half as literally worded is UNSATISFIABLE, and this is the same
oracle-wording defect task-040 logged.** The row asks for `grep -c '^phase: .'` -> `0`, but the
new `work-state-template.yml` **seeds** a concrete `phase: Describe`, so the count is `1` for any
allocated work however correct the skill is. The property that is true, and that these four
records establish, is that **no run writes `phase`** -- all four equal the template default
byte-for-byte. Already logged for the gate under task-040; recorded here as the second
instance so the gate sees it is a class, not a one-off.

## 7. No registration moved

No document was created, so neither registration surface was written:

```
$ git status --porcelain .aid/settings.yml .aid/knowledge/README.md
                                          # (empty)
```

## 8. Restoration

```
$ git diff --exit-code HEAD -- .aid/knowledge/technology-stack.md .aid/knowledge/decisions.md ; echo $?
0                                         # both destinations back to current HEAD
$ git status --porcelain .aid/knowledge/ .aid/design/
                                          # (empty)
$ ls -d .aid/works/*/ | grep -v work-006 | wc -l
0                                         # all four allocations torn down
$ git worktree list | wc -l
1                                         # none of their worktrees registered
```

The restoration target is **current `HEAD`**, not recorded bytes. The throwaway render is left
live for the remaining consumers; task-048 reverts it.
