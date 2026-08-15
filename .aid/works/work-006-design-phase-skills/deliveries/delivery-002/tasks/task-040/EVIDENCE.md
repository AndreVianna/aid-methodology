# task-040 EVIDENCE -- brownfield architecture lifecycle against this repository's C1 doc

Closes BLUEPRINT criteria 4 and 5 for the `architecture` artifact. Rows covered: feature-004
**V4** (this task's share), **V5**, **V8**, **V17** (`hand-authored` half), **V19**, and
feature-002 §7 **E2**.

## 0. Preconditions and how the runs were driven

| Fact | Value |
|---|---|
| Destination | `.aid/knowledge/architecture.md`, resolved from `.aid/settings.yml` `knowledge.doc_set` (`architecture.md\|aid-researcher-architecture\|required`) -> concern **C1** |
| Destination state before run 1 | **520 lines**, `source: hand-authored` at `:3`, **no** `approved_at_commit:` line present |
| `.aid/design/` before run 1 | committed content only: `README.md`, `knowledge-graph-redesign.md` |
| Skills invocable via | the throwaway local render task-039 produced (rebuilt this session; `build-shortcut-skills.py` -> full `run_generator.py` -> additive dogfood resync) |
| Baseline | `git status --porcelain .aid/knowledge/ .aid/design/ .github/` -> empty |

**Execution deviations, stated rather than hidden.** These runs were driven as **manual runs**
(the path BLUEPRINT § Notes prescribes and feature-002 §Verification labels for E2). Three
deviations from the skills' full state machines apply, and none of them touches an oracle this
task asserts -- every criterion below is a **file-state** or **refusal/realization** property,
not a content-quality property:

1. **The `aid-architect` producing dispatch and the `aid-reviewer` full-verify dispatch were
   not made per run**; the content was authored inline by the executor. Content quality is not
   asserted by any row here. This follows the owner decision recorded at delivery-002 STATE
   Q1 (independent review batched at the delivery gate).
2. **Run 2 has no separately allocated `work-NNN` folder.** Runs 1, 3 and 4 do (below). No
   criterion here examines run 2's allocation.
3. **No git worktree was created** by the allocations. The Work Initiation Gate's worktree
   isolates a *work*; entering one would move execution out of the very repository whose
   populated C1 document is the test subject, which is what AC-3 and E2 scope these runs to.
   The `work-NNN` folder and its `STATE.yml` -- the part the `phase:` evidence reads -- were
   allocated for real.

## 1. Run 1 -- `/aid-design-architecture` (V4)

Wrote `.aid/design/architecture.md` in `design-seed.md`'s shape (6 headings), its
`## Destination` naming the C1 doc and its `## Open questions` holding the literal `None` (so
the readiness gate is not exercised here -- that is task-044's).

```
$ git status --porcelain .aid/knowledge/ .github/
                                     # (empty)
$ test -f .aid/design/architecture.md ; echo $?
0
$ grep -c '^## ' .aid/design/architecture.md
6
$ sed -n '/^## Open questions/,/^## /p' .aid/design/architecture.md | sed '1d;$d' | grep -v '^\s*$'
None
$ bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge  # -> green
```

**V4 PASS** -- the `design` stage wrote no `.aid/knowledge/` and no `.github/` path. The oracle
is scoped to those two trees and makes no claim that the seed is the only new file, because
feature-002 §2d binds every `design` skill to acquire `.aid/design/` on first use.

## 2. Run 2 -- `/aid-create-architecture` (V5 / AC-3 / feature-002 E2)

The destination was **populated (520 lines)** and the run **realized rather than refusing** --
which is the whole point of the row. Content landed inside the existing `## Invariants`
section (a new `## ` section was not needed, so `## Contents` was untouched). The seed was
deleted as the realization event.

```
$ test ! -f .aid/design/architecture.md ; echo $?
0                                        # TRUE -- seed consumed
$ git diff --stat .aid/knowledge/architecture.md
 1 file changed, 9 insertions(+)         # non-empty
$ git show HEAD:.aid/knowledge/architecture.md | wc -l
520                                      # the destination it did NOT refuse
```

**V5 / AC-3 / E2 PASS**, both halves. A `create` that refused because the destination was
populated would have failed both.

## 3. Run 3 -- `/aid-update-architecture`, seed **absent** (V8a)

```
$ test ! -f .aid/design/architecture.md ; echo $?
0                                        # precondition: no seed
$ git diff --numstat .aid/knowledge/architecture.md | cut -f1
13                                       # grew from 9 -> 13 insertions
$ test ! -f .aid/design/architecture.md ; echo $?
0                                        # the update created no seed
```

**V8a PASS** -- the run completed and wrote, without a seed and without naming a missing one.
An `update` that required a seed would fail here.

## 4. Run 4 -- `/aid-update-architecture`, seed **present** (V8b)

The step-4 seed is a **fixture built before the run began**, not a second `design` run: what
an authored `design` run happens to put in `## Current direction` is not under the executor's
control, so a precondition of "the run leaves it saying X" would be unreachable. The fixture's
`## Current direction` proposed naming **three independent enforcement points**.

```
$ test ! -f .aid/design/architecture.md ; echo $?
0                                        # TRUE -- fixture seed consumed
$ git diff .aid/knowledge/architecture.md | grep -c 'three independent enforcement'
1                                        # the seed's Current direction landed
$ git diff .aid/knowledge/architecture.md | grep '^+' \
    | grep -oE 'render-drift|VERIFY byte-compare|byte-identity suite' | sort -u
byte-identity suite
render-drift
VERIFY byte-compare                      # all three named points landed
$ git diff --stat .aid/knowledge/architecture.md
 1 file changed, 16 insertions(+)
```

**V8b PASS.** (a) alone would be satisfied by an `update` that ignores seeds and (b) alone by
one that demands them; both held.

## 5. V17 (`hand-authored` half) and V19, across runs 2 and 4

```
$ git diff .aid/knowledge/architecture.md | grep -cE '^[+-]source:'
0                                        # source: line never appears in the diff
$ sed -n '3p' .aid/knowledge/architecture.md
source: hand-authored                    # same value before and after
$ git diff .aid/knowledge/architecture.md | grep -cE '^[+-]approved_at_commit:'
0                                        # never written, never restamped
$ git diff .aid/knowledge/architecture.md | grep -c '^+## '
0                                        # no new section, so ## Contents is unchanged
$ bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge  # green after every writing run
```

**V17 (hand-authored half) PASS. V19 PASS.** The `forward-authored` half of V17 is task-045's.

Content-boundary spot check -- the run added no C0 version, no C8 pipeline stage or
environment, and no concern-D rejected alternative:

```
$ git diff .aid/knowledge/architecture.md | grep '^+' \
    | grep -inE 'v[0-9]+\.[0-9]+|version [0-9]|pipeline stage|environment|rejected'
                                         # (no output)
```

## 6. `decisions.md` -- declared as a write, asserted about only as restored

feature-004 §7b forbids `/aid-create-architecture` from writing rejected alternatives into the
C1 doc and §7d routes a choice-not-taken to the project's **D** doc, while §5's destination
table names a second destination only for `stack`. The two readings differ on whether an
architecture run *may* write `decisions.md`; Detail does not settle a spec question, so this
task declared it a write and restores it, asserting nothing either way. In this run it was in
fact untouched:

```
$ git status --porcelain .aid/knowledge/decisions.md
                                         # (empty)
```

## 7. Allocation records, captured before teardown

Three `work-NNN` folders were allocated through `writeback-state.sh`'s own `--pipeline` writes
(`Pipeline Path`, `Pipeline Initiator`, `Lifecycle`, `Active Skill`) and **`phase` was never
written by any run**:

| Work folder | `initiator` | `lifecycle` | `phase` |
|---|---|---|---|
| `work-007-design-architecture` | `aid-design-architecture` | `Running` | `Describe` |
| `work-008-update-architecture-noseed` | `aid-update-architecture` | `Running` | `Describe` |
| `work-009-update-architecture-withseed` | `aid-update-architecture` | `Running` | `Describe` |

**A finding this run surfaced, and the reason the value is not empty.** The **new**
`canonical/aid/templates/work-state-template.yml` **seeds `phase: Describe`** as a concrete
default. The previous markdown template carried an un-instantiated placeholder
(`phase: Describe | Define | ... | Execute`), which read as "no committed value". So the
oracle wording used by feature-003 V23 and its siblings -- *"`grep -n '^phase:'` -> absent or
empty"* -- is **no longer satisfiable by any allocated work**, however correct the skill is.
The property that is actually true, and that these three records establish, is that **no skill
run writes `phase`**: all three equal the template's seeded default byte-for-byte
(`sort -u` over the three values -> 1 distinct value, equal to the template's). Raised for the
delivery gate; it is an oracle-wording defect, not a skill defect, and it is the same class as
the three unsatisfiable-criterion instances this work has already recorded.

## 8. Restoration

Every document these runs touched is returned to current `HEAD`, `.aid/design/` to its
committed content, and all three allocated work folders removed **after** the records above
were captured. task-048 confirms rather than repairs. See §9 for the post-restoration
assertions.

## 9. Post-restoration assertions

```
$ git status --porcelain .aid/knowledge/
                                         # (empty)
$ git status --porcelain .aid/design/
                                         # (empty)
$ wc -l < .aid/knowledge/architecture.md
520                                      # back to its pre-run length
$ sed -n '3p' .aid/knowledge/architecture.md
source: hand-authored
$ ls .aid/design/
README.md  knowledge-graph-redesign.md   # committed content only
$ ls -d .aid/works/*/ | grep -v work-006 | wc -l
0                                        # all three allocations torn down
$ git worktree list | wc -l
1                                        # main tree only
```

The throwaway render is deliberately left live for the remaining consumers (task-041..047);
task-048 reverts it. This task rendered nothing and reverted nothing.
