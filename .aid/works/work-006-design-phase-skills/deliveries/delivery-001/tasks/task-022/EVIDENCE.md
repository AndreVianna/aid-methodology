# task-022 -- EVIDENCE

Durable evidence log for the byte-discipline verification of the `## MVP` region split. Every
acceptance criterion below appears with **the command that produced it** and **its observed
output**. Nothing is reported as covered without its oracle and result.

This task authored no test script under `tests/` and minted no bash assertion id -- both are
out of scope per § Scope (feature-001 AC-3 ground). The runs and oracles were driven from
throwaway drivers under `.aid/.temp/t022/` (gitignored, removed at teardown); this file is the
durable record.

---

## 1. Execution model, and where the checks ran

| Aspect | How it ran |
|---|---|
| Session | One agent session |
| Skill bodies | Read from the **rendered** dogfood tree task-024 produced (`.claude/skills/aid-{create,update}-{roadmap,mvp}/SKILL.md`). This task rendered nothing and reverted nothing |
| Producer role (`REALIZE` / `UPDATE`) | Performed inline by the executing agent |
| Verifier role (`VERIFY` step 2) | **Clean-context `aid-reviewer` sub-agent dispatches** -- one per authored run, five in total. Each ledger was written to `.aid/.temp/review-pending/<work>-verify.md` and graded with `bash .claude/aid/scripts/grade.sh --explain` |
| Where the checks ran | **This repository's own working tree**, on the `roadmap.md` task-015 committed, exactly as § Scope requires: V7 and V8 are `git diff`-based and their SPEC text names `.aid/knowledge/roadmap.md`, so a `mktemp -d` fixture is not a git work tree and would make `git diff -U0` meaningless. The task mutated that one file and restored it (§7) |
| Shell | Windows Git Bash (`C:\Program Files\Git\bin\bash.exe`). A WSL bash cannot resolve this worktree's gitdir and returns false git results; Git Bash was confirmed to resolve it (`git rev-parse --show-toplevel` -> this worktree, `--abbrev-ref HEAD` -> `work-006`, porcelain count 113) |

**Byte-range writes were performed as byte splices.** Each run's write reads the whole file,
replaces only the owned byte range, and writes back -- the literal discipline
`feature-002 §3c § Mechanics` states ("Read whole file -> replace only the owned byte range ->
write back with every other region byte-identical. Never regenerate"). Every splice reports
the SHA-256 of the untouched prefix and suffix and re-reads the file to confirm both survived;
those `prefix_preserved=True` / `suffix_preserved=True` lines are quoted per run below.

**What the oracles therefore do and do not discriminate.** Because the writer follows the
discipline, "bytes outside the range are unchanged" is a property the write *implements*, and
the oracle confirms it end to end. The rows' discriminating power sits in the four things a
compliant-looking implementation can still get wrong, and each was checked independently:
**which** region each verb wrote (the ownership split), **where** the region boundary falls
(the extent rule, with a control that must come out OUTSIDE), whether `## Contents` gained an
entry, and whether a run realized at all rather than exiting by routing. The
`## Contents` block's SHA-256 is `0207ecc61dcb41279919b304f23868667c7a0906d340fe1bc467ebce77ea4102`
in **all twelve** recorded document states -- fixtures, pre-run and post-run alike.

**Allocation leaves a git worktree as well as a work folder, and the worktree is branched off
`master`.** All five invocations ran the Work Initiation Gate, and
`worktree-lifecycle.sh create` produced a worktree under `.claude/worktrees/` alongside the
`work-NNN` folder; all five printed `75039593 [work-NNN]`, i.e. `master`. `master` carries **no**
`.aid/knowledge/roadmap.md` (`git cat-file -e master:.aid/knowledge/roadmap.md` -> `fatal: path
'.aid/knowledge/roadmap.md' exists on disk, but not in 'master'`, exit 128), so artifact writes
landed in the **invoking** project tree, per the precedent task-015 § Scope records ("four
`.aid/works/work-NNN-*/` folders and their worktrees appear in the working tree") and task-016
re-recorded. This is the already-filed `W5-20`, not a new finding (§8).

---

## 2. The F-full baseline, captured before any run

Oracle: `python3 region.py .aid/knowledge/roadmap.md`, which implements
`feature-002 §3c § Mechanics` -- region identity is the literal heading `## MVP` matched
exactly; region extent runs from that heading to the next heading of level 2 or shallower, or
EOF, with deeper subsections belonging to the region.

```
file=.aid/knowledge/roadmap.md
file_len=9582
file_sha256=c389fad6006f7a13257b7dfccad92c71866448f72683a74f495be8a4db675500
crlf_present=False
mvp_present=True
mvp_start_byte=1017
mvp_end_byte=2742
mvp_len=1725
mvp_sha256=f044b82babec6821df5060236f51ac4f9a7c26e946dc8732be91d11fbca7bc4d
mvp_start_line=28
mvp_last_line_in_region=50
next_le2_heading_line=51
next_le2_heading=## Now
subheadings_in_region=0
```

Committed blob: `git rev-parse HEAD:.aid/knowledge/roadmap.md` -> `a8bc1598ff7de216f729e29a187097c4cbc7dd94` at `HEAD = 61b9cb2d`.

**This is the captured `## MVP` byte range V7 and the third criterion refer to:** bytes
**[1017, 2742)**, length **1725**, SHA-256 **`f044b82babec6821df5060236f51ac4f9a7c26e946dc8732be91d11fbca7bc4d`**,
lines **28-50**, terminated by the next level-2 heading `## Now` at line 51.

---

## 3. Fixtures -- three working-tree states, none of them a run

Fixture edits are working-tree **edits**, not skill runs, so they add nothing to the run count.
Each was verified at the moment it was established.

| Fixture | Produced by | `file_sha256` | `## MVP` state |
|---|---|---|---|
| **F-full** | already on disk; no edit | `c389fad6...` (9582 B) | populated, `f044b82b...` |
| **F-horizons-empty** | hand edit: splice `[2742, 9582)` -> `## Now\n\n## Next\n\n## Later\n` | `4a54aa38...` (2768 B) | populated, **`f044b82b...` -- unchanged by the fixture edit** |
| **F-no-MVP** | hand edit: splice `[1017, 2742)` -> empty | `f0120fc8...` (7857 B) | `mvp_present=False`; `- [MVP](#mvp)` **retained** at line 23 |

F-horizons-empty, at the moment run 3 began:

```
mvp_sha256=f044b82babec6821df5060236f51ac4f9a7c26e946dc8732be91d11fbca7bc4d
--- headings + Contents entries kept ---
21:## Contents
23:- [MVP](#mvp)
24:- [Now](#now)
25:- [Next](#next)
26:- [Later](#later)
28:## MVP
51:## Now
53:## Next
55:## Later
--- horizon entry bodies gone ---
### count = 0
```

F-no-MVP, at the moment run 4 began:

```
file_len=7857
file_sha256=f0120fc87218f395de5975291dec3457b27574ba098fe9b4717051ec9dcd9a9c
mvp_present=False
--- ## Contents MVP entry RETAINED (deliberate) ---
23:- [MVP](#mvp)
--- headings ---
21:## Contents
28:## Now
70:## Next
102:## Later
```

**F-no-MVP was re-established between the two runs that use it**, because run 4 created the
region and would have left run 5 with nothing to create. The re-established state is
byte-identical to the one run 4 consumed -- which is also a determinism datum for fixture
construction:

```
--- fixture is byte-identical to the one run 4 used ---
f0120fc87218f395de5975291dec3457b27574ba098fe9b4717051ec9dcd9a9c *.aid/.temp/t022/snap/04-pre-create-mvp.md
f0120fc87218f395de5975291dec3457b27574ba098fe9b4717051ec9dcd9a9c *.aid/knowledge/roadmap.md
```

**How the diff baseline was set, and why.** V8's oracle is literally
`git diff -U0 .aid/knowledge/roadmap.md`, which compares the working tree to the **index**.
For runs 1 and 2 the fixture *is* F-full, so index == HEAD == fixture and the command ran
**unmodified**. For runs 3, 4 and 5 the fixture is a hand edit, so the fixture was
`git add`-ed before the run; the index then holds the fixture and the same command reports
**exactly the run's own write** rather than fixture-plus-run. The path was `git reset` and
`git checkout`-restored afterwards, and both the worktree and the index are clean at the end
(§7).

---

## 4. The five authored runs -- work folder and `phase:` record

Captured **before** teardown. This is the V23 evidence task-023 aggregates. The criterion
binds all five because all five realize -- each ran in the fixture § Scope assigns it precisely
so that it writes, and the non-empty-diff conjuncts in §5 and §6 are what make that checkable.
This task performed **no** non-realizing invocation: no routing exit and no refusal.

Oracle per row: `grep -n '^phase:' .aid/works/<work>/STATE.md` (no match = the key is absent).

| # | Invocation | Fixture | Allocated work folder | `phase:` | Worktree also allocated | Verify cycles | Final grade |
|---|---|---|---|---|---|---|---|
| 1 | `/aid-update-roadmap` | F-full | `.aid/works/work-010-update-roadmap` | **ABSENT** | `.claude/worktrees/work-010-update-roadmap` | 2 | **A+** |
| 2 | `/aid-update-mvp` | F-full | `.aid/works/work-011-update-mvp` | **ABSENT** | `.claude/worktrees/work-011-update-mvp` | 2 | **A+** |
| 3 | `/aid-create-roadmap` | F-horizons-empty | `.aid/works/work-012-create-roadmap` | **ABSENT** | `.claude/worktrees/work-012-create-roadmap` | 2 | **A+** |
| 4 | `/aid-create-mvp` | F-no-MVP | `.aid/works/work-013-create-mvp` | **ABSENT** | `.claude/worktrees/work-013-create-mvp` | 1 | **A+** |
| 5 | `/aid-update-mvp` | F-no-MVP (re-established) | `.aid/works/work-014-update-mvp` | **ABSENT** | `.claude/worktrees/work-014-update-mvp` | 1 | **A+** |

Verbatim capture:

```
===== V23 EVIDENCE: work folder + phase: per authored run =====
work-010-update-roadmap    folder=present  phase: ABSENT (grep -n "^phase:" exits 1, no match)
work-011-update-mvp        folder=present  phase: ABSENT (grep -n "^phase:" exits 1, no match)
work-012-create-roadmap    folder=present  phase: ABSENT (grep -n "^phase:" exits 1, no match)
work-013-create-mvp        folder=present  phase: ABSENT (grep -n "^phase:" exits 1, no match)
work-014-update-mvp        folder=present  phase: ABSENT (grep -n "^phase:" exits 1, no match)
```

Corroborated independently by the enumerator's own `phase` column, which is empty for all five:

```
work-010-update-roadmap	--	Running	work-006	--
work-011-update-mvp	--	Running	work-006	--
work-012-create-roadmap	--	Running	work-006	--
work-013-create-mvp	--	Running	work-006	--
work-014-update-mvp	--	Running	work-006	--
```

Work-id derivation, per gate step 3a.1 (maximum `work-NNN` prefix over the records
`enumerate-works.sh` returned, cross-worktree). Works already existed on the first call, so
the gate ASKED on every one of the five and the answer was NEW each time:

```
run 1  max over records = work-009 (work-005, work-006, work-009)  -> work-010
run 2  max = work-010                                              -> work-011
run 3  max = work-011                                              -> work-012
run 4  max = work-012                                              -> work-013
run 5  max = work-013                                              -> work-014
```

`worktree-lifecycle.sh create` returned rc=0 with a non-empty path on all five, so the
fail-closed create-failure guard never fired.

**Tally: authored runs 5, non-realizing invocations 0, total invocations 5.** Five is the
falsifier the criterion names: a sixth would mean a row built its own state instead of using
its assigned fixture, and a fourth would mean a row was dropped. The two fixture edits, the
one fixture re-establishment and the one control edit are **not** runs and are not counted.

---

## 5. V7 -- `## MVP` preserved by its neighbour

Two halves, each in the fixture § Scope assigns it. **Both** conjuncts are asserted for each:
the captured range is byte-identical, **and** the run shows a non-empty `git diff` outside the
range -- a run that wrote nothing would satisfy the first vacuously and fails the row.

### 5.1 `/aid-update-roadmap` in F-full (run 1)

The run moved `### Agent chat channel` from `## Next` to `## Later` (block bytes carried, not
retyped) and revised the `### v2.4.0 release` `Status` field.

Write discipline, verbatim:

```
prefix_len=5711 prefix_sha256=cc3b9a348fceb2ca729d7f4f123eec276fae9eb2e8408ad72dab0a9ed730063d
suffix_len=0 suffix_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
prefix_preserved=True
suffix_preserved=True
moved_block_len=1026 moved_block_sha256=2b8957daaef0f4d30059c1ecb9921e11d3f498c06eba49e65e41aca06bcd601e
moved_block_byte_identical=True
```

Oracle A -- `python3 region.py .aid/knowledge/roadmap.md` after the run:

```
file_len=9722
file_sha256=6f29306bcfd937bfe4a333b0e42547bae694f80bb8449c610dedaa177ae99c75
mvp_start_byte=1017
mvp_end_byte=2742
mvp_len=1725
mvp_sha256=f044b82babec6821df5060236f51ac4f9a7c26e946dc8732be91d11fbca7bc4d
```

Offset, length and SHA-256 all equal the captured baseline. **Byte-identical: PASS.**

Oracle B -- `git diff -U0 -- .aid/knowledge/roadmap.md`, non-empty and outside the range:

```
@@ -107,2 +107,5 @@  -- del=107-108 in_old_mvp=False secs=['## Next']  | add=107-111 in_new_mvp=False secs=['## Later', '## Next'] -> OUTSIDE
@@ -125,2 +127,0 @@  -- del=125-126 in_old_mvp=False secs=['## Later'] | add=<none>                                            -> OUTSIDE
hunks_total=2 lines_added=5 lines_deleted=4
hunks_confined_to_mvp=0 hunks_not_confined=2
sections_with_touched_lines=['## Later', '## Next']
touches_Contents=False
contents_block_byte_identical=True
```

Diff non-empty (2 hunks, 5 added / 4 deleted lines), every touched line outside the `## MVP`
range. **Not a routing exit. PASS.**

Heading order after the run, confirming the move landed correctly:

```
21:## Contents   28:## MVP   51:## Now   93:## Next   111:## Later   113:### Agent chat channel
```

### 5.2 `/aid-create-roadmap` in F-horizons-empty (run 3)

Destination present with horizon sections empty, so REALIZE took the **fill** row of the
skill's table ("Fill `## Now`, `## Next`, `## Later` from the seed; leave every byte outside
those sections identical, including `## MVP` if present").

Write discipline, verbatim:

```
prefix_len=2742 prefix_sha256=e3b9b6923754276cb60e5450f70c99f45e46616a62876146f405341405de26d1
suffix_len=0
prefix_preserved=True
suffix_preserved=True
replaced_len_old=26 replaced_len_new=5404
```

Oracle A -- region after the run:

```
file_len=8325
file_sha256=13a50d8447b4ca39aff32e4d8b76a1eb7528c60d9c1e003c1a5160a3454c877e
mvp_start_byte=1017
mvp_end_byte=2742
mvp_len=1725
mvp_sha256=f044b82babec6821df5060236f51ac4f9a7c26e946dc8732be91d11fbca7bc4d
```

**Byte-identical to the captured baseline: PASS.**

Oracle B -- `git diff -U0` against the staged fixture:

```
@@ -52,0 +53,36 @@  -- del=<none> | add=53-88   in_new_mvp=False secs=['## Now']   -> OUTSIDE
@@ -54,0 +91,25 @@  -- del=<none> | add=91-115  in_new_mvp=False secs=['## Next']  -> OUTSIDE
@@ -55,0 +117,27 @@ -- del=<none> | add=117-143 in_new_mvp=False secs=['## Later'] -> OUTSIDE
hunks_total=3 lines_added=88 lines_deleted=0
hunks_confined_to_mvp=0 hunks_not_confined=3
touches_Contents=False
contents_block_byte_identical=True
```

Diff non-empty (88 added lines), all of it outside the `## MVP` range. **Not a routing exit. PASS.**

REGISTER was correctly skipped -- the destination was present, not created:

```
690fe7c778b91856da30c725b93f9b67231431aca39207637714e405c90b6cd5 *.aid/settings.yml
8dfce335495a97b078b9cd44b823bee7e824838c40a25dbfba39bbc44b561030 *.aid/knowledge/README.md
```

(identical to the pre-run capture of both files).

### 5.3 V7 verdict

Both halves run, in their assigned fixtures, each with a non-empty diff outside the range and a
byte-identical `## MVP`. Replayed a second time (§9) with identical outcomes:

```
captured F-full ## MVP range sha256=f044b82babec6821df5060236f51ac4f9a7c26e946dc8732be91d11fbca7bc4d
01-post-update-roadmap: IDENTICAL
03-pre-create-roadmap:  IDENTICAL
03-post-create-roadmap: IDENTICAL
```

**V7: PASS.**

---

## 6. V8 / feature-002 E3 -- mvp writes only its section

Three runs discharge this row: the `update` half in F-full, the `create` half in F-no-MVP, and
the fifth run -- `update` creating the region -- which §6.3 covers as its own case.

### 6.1 `/aid-update-mvp` in F-full (run 2)

Write discipline, verbatim:

```
prefix_len=1017 prefix_sha256=45edef467c569ea3cde0f529f47fe67403f3a914383f11af101e279b367be618
suffix_len=6840 suffix_sha256=ff456ef787d584c865893b69398ddf5c2bd582b623e898202f5561da8554049e
prefix_preserved=True
suffix_preserved=True
```

Oracle -- `git diff -U0 -- .aid/knowledge/roadmap.md` (unmodified command; index == HEAD == F-full):

```
old_mvp_line_range=(28, 50)
new_mvp_line_range=(28, 60)
@@ -31,3 +31 @@    -- del=31-33 in_old_mvp=True secs=['## MVP'] | add=31-31 in_new_mvp=True secs=['## MVP'] -> INSIDE
@@ -47,3 +45,15 @@  -- del=47-49 in_old_mvp=True secs=['## MVP'] | add=45-59 in_new_mvp=True secs=['## MVP'] -> INSIDE
hunks_total=2 lines_added=16 lines_deleted=6
hunks_confined_to_mvp=2 hunks_not_confined=0
sections_with_touched_lines=['## MVP']
touches_Contents=False
touches_Now=False
touches_Next=False
touches_Later=False
contents_block_byte_identical=True
```

Diff non-empty inside the region (16 added / 6 deleted lines), every hunk confined to
`## MVP`, and no hunk touching `## Contents`, `## Now`, `## Next` or `## Later`.
**Not a routing exit. PASS.**

### 6.2 `/aid-create-mvp` in F-no-MVP (run 4)

Write discipline, verbatim (a pure insertion at the anchor byte 1017 -- immediately after the
`## Contents` block, before `## Now`):

```
prefix_len=1017 prefix_sha256=45edef467c569ea3cde0f529f47fe67403f3a914383f11af101e279b367be618
suffix_len=6840 suffix_sha256=ff456ef787d584c865893b69398ddf5c2bd582b623e898202f5561da8554049e
prefix_preserved=True
suffix_preserved=True
replaced_len_old=0 replaced_len_new=1499
```

Oracle -- `git diff -U0` against the staged fixture:

```
old_mvp_line_range=None
new_mvp_line_range=(28, 48)
@@ -27,0 +28,21 @@ -- del=<none> | add=28-48 in_new_mvp=True secs=['## MVP'] -> INSIDE
hunks_total=1 lines_added=21 lines_deleted=0
hunks_confined_to_mvp=1 hunks_not_confined=0
sections_with_touched_lines=['## MVP']
touches_Contents=False
touches_Now=False
touches_Next=False
touches_Later=False
contents_block_byte_identical=True
```

The added line range 28-48 is **exactly** the created region's line range 28-48.
`git diff --numstat` -> `21	0` (zero deletions, a pure insertion). Heading order:
`21:## Contents  28:## MVP  49:## Now  91:## Next  123:## Later`. **PASS.**

No registration was written -- this skill creates a section, not a document:

```
690fe7c778b91856da30c725b93f9b67231431aca39207637714e405c90b6cd5 *.aid/settings.yml
8dfce335495a97b078b9cd44b823bee7e824838c40a25dbfba39bbc44b561030 *.aid/knowledge/README.md
git status --porcelain -- .aid/settings.yml .aid/knowledge/README.md  ->  (empty)
```

### 6.3 `/aid-update-mvp` creating the region, on a freshly re-established F-no-MVP (run 5)

This is the fifth authored run and the case that had no fixture at all before -- the
`update` verb exercising the region-creation power feature-003 §4's table grants it.

Write discipline, verbatim:

```
prefix_len=1017 prefix_sha256=45edef467c569ea3cde0f529f47fe67403f3a914383f11af101e279b367be618
suffix_len=6840 suffix_sha256=ff456ef787d584c865893b69398ddf5c2bd582b623e898202f5561da8554049e
prefix_preserved=True
suffix_preserved=True
replaced_len_old=0 replaced_len_new=1592
```

Oracle -- `git diff -U0` against the staged fixture:

```
old_mvp_line_range=None
new_mvp_line_range=(28, 49)
@@ -27,0 +28,22 @@ -- del=<none> | add=28-49 in_new_mvp=True secs=['## MVP'] -> INSIDE
hunks_total=1 lines_added=22 lines_deleted=0
hunks_confined_to_mvp=1 hunks_not_confined=0
sections_with_touched_lines=['## MVP']
touches_Contents=False
touches_Now=False
touches_Next=False
touches_Later=False
contents_block_byte_identical=True
```

Added lines 28-49 are exactly the created region 28-49; `git diff --numstat` -> `22	0`
(pure insertion); heading order `21:## Contents  28:## MVP  50:## Now  92:## Next  124:## Later`;
neither registration surface written. **PASS.**

### 6.4 An oracle defect found and corrected, rather than accepted

The first-cut classifier judged a hunk side of length 0 by its **anchor position**. On run 4's
pure insertion that anchor sits at old line 27 -- the last line before `## Now` in a file with
no `## MVP` -- so the classifier reported `touches_Contents=True` and `OUTSIDE`, which read as
a V8 failure. It is not one: a zero-length side adds and deletes **no line**, so it touches no
section, and "no hunk touches `## Contents`" is a claim about lines added or deleted. The
classifier was corrected to judge only non-empty sides, and re-run over **every** saved diff
to confirm no verdict moved except the mis-read one:

| Diff | first-cut verdict | corrected verdict |
|---|---|---|
| run 1, V7-update | OUTSIDE x2 | OUTSIDE x2 (unchanged) |
| run 2, V8-update | INSIDE x2 | INSIDE x2 (unchanged) |
| run 3, V7-create | OUTSIDE x3 | OUTSIDE x3 (unchanged) |
| run 4, V8-create | **OUTSIDE, touches_Contents=True** | **INSIDE, touches_Contents=False** (corrected) |
| control | OUTSIDE | OUTSIDE (unchanged) |

The correction is not a weakening: the corrected classifier still returns OUTSIDE for the
control and for all five horizon-section hunks, and the conclusion is backed independently by
a check that needs no hunk arithmetic at all -- the `## Contents` block's SHA-256 is
`0207ecc6...` in every recorded state, pre and post, for all five runs.

### 6.5 V8 / E3 verdict

Both verbs run in their assigned fixtures, each with a non-empty diff **inside** the region and
no hunk touching `## Contents`, `## Now`, `## Next` or `## Later`. **V8 = feature-002 E3: PASS.**

---

## 7. The extent rule -- exercised, not assumed

Both halves are assertions over diffs. Neither is a skill run.

**INSIDE half** -- a `###` entry written inside the MVP falls inside the asserted range. Run 2
wrote `### Slice contents` into the region; the assertion is made on run 2's own F-full diff:

```
INSIDE half -- ### heading line inside the MVP region of 02-post: 50
mvp_start_line=28
next_le2_heading_line=61      (so the region is lines 28-60)
subheadings_in_region=1
```

Line 50 falls in 28-60, and run 2's second hunk (`add=45-59`) covers it and was classified
`in_new_mvp=True`. The region terminated at `## Now`, not at the `###` heading -- which is the
rule under test ("Deeper subsections belong to the region"). **PASS.**

**OUTSIDE half** -- a change made to `## Now` falls outside the range. A **control hand edit**
(one line in `## Now`, `Thirty-six` -> `Thirty-six (36)`), not a run:

```
@@ -55 +55 @@
-- **What:** Thirty-six new `design`/`create`/`update` skills covering nine artifact types —
+- **What:** Thirty-six (36) new `design`/`create`/`update` skills covering nine artifact types —

old_mvp_line_range=(28, 50)
new_mvp_line_range=(28, 50)
del=55-55 in_old_mvp=False secs=['## Now'] | add=55-55 in_new_mvp=False secs=['## Now'] -> OUTSIDE
hunks_confined_to_mvp=0 hunks_not_confined=1
sections_with_touched_lines=['## Now']
contents_block_byte_identical=True
```

**PASS** -- and this is what makes the INSIDE half non-vacuous: the same oracle that calls run
2's hunks INSIDE calls this one OUTSIDE, so it discriminates rather than always answering
"inside".

The control edit's post-state was reconstructed for the replay by re-applying the same edit to
a **copy** (no live file touched); its SHA-256 `438caf3435a6415a51c54a9d74838ba078792cd8bf12be3ffa74cf8bb11fcf72`
equals the live-file SHA-256 recorded when the control originally ran, so the reconstruction is
faithful.

---

## 8. Coverage -- every feature-003 §8 and feature-002 §7 row named with its owner

The three rows this task owns are run and recorded above, each with the command that produced
it: **feature-003 V7** (§5), **feature-003 V8** (§6) and **feature-002 E3** (§6, the same case
as V8). Every other row is named below with the task or delivery that owns it. None is silently
dropped; none is claimed as covered here.

**feature-003 §8 -- V1..V28**

| Row | Owner |
|---|---|
| V1, V2, V3, V25 | the skill-authoring tasks task-010..task-014 (each asserts them over the skills it authors); V2 re-asserted by task-024's render |
| V4 | task-016 (run and recorded there) |
| V5 | task-015 (roadmap) and task-021 (backlog); the `create`-stage run is task-016's |
| V6 | task-016 |
| **V7** | **task-022 -- this task (§5)** |
| **V8** | **task-022 -- this task (§6)** |
| V9 | task-015 |
| V10 | task-011 (description/catalog side), task-015 (run side) |
| V11, V12 | task-015 (roadmap) and task-021 (backlog) |
| V13, V14 | task-012, task-015, task-021 |
| V15 | task-015 (roadmap) and task-021 (backlog) |
| V16 (= feature-002 E1) | task-016 |
| V17 | task-023 |
| V18 | task-009, task-018, task-020, task-021, task-023 |
| V19 | task-009 (the `release-aid` rewire), re-checked by task-023 |
| V20 | task-020, task-021, task-023 |
| V21, V22 | task-023 |
| V23 | task-023 aggregates the nine-skill sweep; task-015 and task-021 record their own runs; **this task supplies the five records in §4** |
| V24 | task-023 |
| V26 | feature-006, delivery-003 (a hand-off, not a second execution -- so recorded by task-016) |
| V27 | task-023 |
| V28 | task-010 (catalog row author); its oracle is runnable at close-out, delivery-003 |

**feature-002 §7 -- A1..K1**

| Row | Owner |
|---|---|
| A1, A2, A3, A4, A5, A6 | task-001 (the landed `.aid/design/` folder and its README template) |
| B1 | task-003 (`design-lifecycle.md`) |
| B2 | part (a) task-003 / task-024's render; part (b) run and recorded by task-016 |
| B3 | task-016 |
| B4 | task-003, audited by task-005 |
| C1, C2 | task-004 (the rule-binding table) |
| D1, D2 | task-003 |
| D3 | task-002 (`design-seed.md`) |
| E1 | task-016 (identical to feature-003 V16) |
| E2 | feature-004, delivery-002 (the populated-destination case; `/aid-create-architecture` is not authored in this delivery) |
| **E3** | **task-022 -- this task (§6); identical to feature-003 V8** |
| F1 | task-003 |
| G1 | task-005, with the deferred behavioral half recorded by task-016 |
| G2 | task-003 (conjunct b, over this feature's own contract) and task-023 |
| G3 | task-005 (the shipped-footprint audit over the feature's commit range) |
| H1 | feature-006, delivery-003 (the count sweep) |
| I1 | feature-006, delivery-003 (render parity) |
| J1 | task-004 |
| K1 | task-001 |

---

## 9. Determinism, and teardown

**Determinism.** The oracles are pure functions of the document states the five runs produced,
so both passes were run over the recorded pre/post snapshots -- which adds no sixth run. The
replay re-evaluates the region computation over all twelve recorded states, the diff-extent
classification over all six recorded diffs, the V7 byte-identity comparison, and the extent
rule, then the two passes are diffed:

```
DETERMINISM: pass A vs pass B -- diff rc=0 IDENTICAL OUTCOMES
```

Fixture construction is deterministic too: F-no-MVP, built twice by hand, came out
byte-identical both times (`f0120fc8...`, §3).

**Teardown.** `worktree-lifecycle.sh` has no removal verb ("teardown is exclusively feature-004
/ `aid-housekeep`"), so all five allocations were removed with git directly -- work folder,
worktree and branch:

```
--- work-010-update-roadmap ---   Deleted branch work-010 (was 75039593).
--- work-011-update-mvp ---       Deleted branch work-011 (was 75039593).
--- work-012-create-roadmap ---   Deleted branch work-012 (was 75039593).
--- work-013-create-mvp ---       Deleted branch work-013 (was 75039593).
--- work-014-update-mvp ---       Deleted branch work-014 (was 75039593).

===== after teardown =====
C:/Projects/Personal/AID                                                75039593 [master]
C:/Projects/Personal/AID/.claude/worktrees/work-006-design-phase-skills 61b9cb2d [work-006]
C:/Projects/Personal/AID/.claude/worktrees/work-009                     dac3eae4 [work-009]
--- branches work-01x ---   none
--- .aid/works ---          work-005-knowledge-graph   work-006-design-phase-skills
--- worktree dirs on disk ---   work-006-design-phase-skills   work-009
```

The worktree list is back to the three that existed before this task, no `work-01*` branch
remains, and `.aid/works/` holds only the two folders that were there before.

---

## 10. Final tree state

| Oracle | Observed | Verdict |
|---|---|---|
| `git diff --exit-code -- .aid/knowledge/roadmap.md` | rc=0, clean; `sha256sum` -> `c389fad6006f7a13257b7dfccad92c71866448f72683a74f495be8a4db675500`, equal to the F-full baseline byte for byte | PASS |
| `git diff --cached --exit-code -- .aid/knowledge/roadmap.md` | rc=0 -- the index is clean too, so the staging used as a diff baseline (§3) left nothing behind | PASS |
| `git status --porcelain .aid/works/` | empty before this task's own commit -- no folder this task created remains | PASS |
| `git status --porcelain profiles/ .claude/ .cursor/` | **113** entries -- exactly what task-024 left, unchanged at the start and at the end of this task. Nothing was rendered and nothing reverted | PASS |
| `git status --porcelain` (whole tree) | **113** -- every dirty entry lies inside those three paths; nothing else moved | PASS |
| `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/` | rc=0 -- clean; no test script authored, no assertion id minted | PASS |
| `git status --porcelain -- .aid/settings.yml .aid/knowledge/README.md` | empty; both files' SHA-256 unchanged across all five runs | PASS |
| `git status --porcelain -- .aid/design/` | empty -- no seed existed for `roadmap` or `mvp`, so no seed was consumed and `.aid/design/` was never written | PASS |

---

## 11. Observations (recorded, not blocking this task's own criteria)

1. **A false evidence anchor in the COMMITTED `roadmap.md`.** Run 3's reviewer raised a
   [HIGH] against the text this task authored, and the same defect is present in the
   `roadmap.md` **task-015 committed**, at line 155:
   `- **Status:** intent — anticipated by the architecture (see \`decisions.md\`), not yet
   committed to or worked.` `decisions.md` records no such anticipation --
   `grep -niE "richer|anticipat|consumption" .aid/knowledge/decisions.md` -> **no match** --
   and its D19 (`## D19 — Connectors registry: catalog, not connection manager`) records the
   opposite: `Accepted (delivery-002 withdrawn)`. The claim is therefore unsupported by the
   document it cites, which is a feature-003 §3a durable-citation defect in a shipped
   artifact. **This task did not fix it**: `roadmap.md` is restored byte for byte by an
   acceptance criterion, and the file belongs to task-015. Raised here for the delivery gate.
   Run 3's own copy of the defect was fixed in its cycle 2 and the ledger row marked `Fixed`.
2. **`W5-20` observed live, five more times.** Every one of the five invocations left a
   `work-NNN` folder **and** a registered git worktree that nothing cleans up; and because
   `worktree-lifecycle.sh create` branches off `master`, which carries no
   `.aid/knowledge/roadmap.md`, the artifact write necessarily lands in the invoking tree
   rather than the allocated worktree. Already filed at P3 in `.aid/knowledge/backlog.md`;
   nothing new is raised.
3. **The override-flag under-specification was not reached.** Six shipped skills require a
   refusal to name an override flag no literal token defines anywhere in `canonical/`, already
   filed as a delivery-gate issue. This task performs no refusal and no routing exit -- all
   five runs realize -- so the gate never fired and no token had to be invented here.
4. **One reviewer finding was `Accepted`, with its citation.** Run 2's [LOW] said the
   `### Slice contents` subsection goes beyond the four-field `## MVP` template. It is retained
   deliberately: feature-002 §3c *Mechanics* fixes the region extent as running to the next
   heading of level 2 or shallower with "Deeper subsections belong to the region", so a `###`
   inside `## MVP` is admitted by the contract, and the four-field template states the fields
   the section must carry rather than a prohibition on deeper structure. The subsection is the
   positive half of the extent-rule criterion (§7), so removing it would fail that criterion.
   The row remains visible in the ledger as `Accepted`, not deleted.
