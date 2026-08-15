# task-023 -- EVIDENCE

Durable evidence log for the behavioral verification of the `update` contract across the nine
planning-artifact skills. Every row named in this task's `DETAIL.md § Scope` and every
acceptance criterion appears below with **the command that produced it** and **its observed
output**. Nothing is reported as covered without its oracle and result.

This task authored no test script under `tests/` and minted no bash assertion id -- both are
out of scope per § Scope (feature-001 AC-3 ground). The runs and oracles were driven from
throwaway drivers under `.aid/.temp/t023/` (gitignored, removed at teardown); this file is the
durable record.

**One acceptance criterion FAILS and is reported rather than smoothed over: the V23 evidence
spans EIGHT of the nine skills, not nine.** `aid-create-backlog` has no run record anywhere in
this delivery. §8.2 gives the full accounting; §11.1 files it.

---

## 1. Execution model, and where the checks ran

| Aspect | How it ran |
|---|---|
| Session | One agent session, as § Scope's fixture policy intends |
| Skill bodies | Read from the **rendered** dogfood tree task-024 produced (`.claude/skills/aid-{design,update}-{roadmap,mvp,backlog}/SKILL.md`; copied into the scratch project as its installed bundle). This task rendered nothing and reverted nothing |
| Producer role (`DESIGN` / `UPDATE`) | Performed inline by the executing agent -- the same deviation task-016 and task-022 recorded |
| Verifier role (`VERIFY` step 2) | **Clean-context `aid-reviewer` sub-agent dispatches** -- one per cycle, **12 in total** across the six authored runs. Each ledger was written to `.aid/.temp/review-pending/<work>-verify.md` and graded with `bash .claude/aid/scripts/grade.sh --explain` |
| Shell | Windows Git Bash (`C:\Program Files\Git\bin\bash.exe`). A WSL bash cannot resolve this worktree's gitdir; Git Bash was confirmed to resolve it (`git rev-parse --show-toplevel` -> this worktree, `--abbrev-ref HEAD` -> `work-006`, porcelain count 113) |
| Scratch root | `mktemp -d` -> `/tmp/tmp.ptJKjKh5TQ`, removed on completion (§10) |
| `HEAD` at the start and at the end | `9be08e3ae6a77099dc9c67ff9eb8f738b72ad2f3` |

**Work-id collision with task-022, stated so the two records are not confused.** task-022 also
allocated `work-010` .. `work-014` and removed them; this task's gate therefore re-derived the
same numbers from a `.aid/works/` that had been restored to two folders. The **slugs differ**
and are what disambiguate: task-022 held `work-010-update-roadmap`, `work-011-update-mvp`,
`work-012-create-roadmap`, `work-013-create-mvp`, `work-014-update-mvp`; this task holds
`work-010-design-roadmap`, `work-011-update-roadmap`, `work-012-update-mvp`,
`work-013-update-backlog`, `work-014-update-roadmap`.

**Allocation leaves a git worktree as well as a work folder.** All nine invocations ran the
Work Initiation Gate, and `worktree-lifecycle.sh create` returned rc=0 with a non-empty path
every time, producing a worktree alongside the `work-NNN` folder. This is the already-filed
`W5-20`, not a new finding.

---

## 2. Baseline, captured before any run touched anything

```
--- HEAD ---
9be08e3ae6a77099dc9c67ff9eb8f738b72ad2f3
--- branch ---
work-006
--- render footprint (must stay exactly what task-024 left) ---
git status --porcelain profiles/ .claude/ .cursor/  -> 113
git status --porcelain (whole tree)                 -> 113
--- the three documents the runs will mutate ---
c389fad6006f7a13257b7dfccad92c71866448f72683a74f495be8a4db675500 *.aid/knowledge/roadmap.md
494846c64c79b95775e08aaf6b0c8f28a3e0910dca7d5c011a73de79eaba77ad *.aid/knowledge/backlog.md
9f23879ce6d2aab8bbee05f5a52b42f675a8fa9a3a58fd1865b5a9b115c0184b *.aid/knowledge/tech-debt.md
--- committed blobs at HEAD ---
a8bc1598ff7de216f729e29a187097c4cbc7dd94   (roadmap.md)
e4fdeab55ce9b622d4a6c9336c9c152e8581bcc7   (backlog.md)
8e49976991334a4e31ad38b8dee8d445fea757b0   (tech-debt.md)
--- .aid/design/ before the design run ---
knowledge-graph-redesign.md
README.md
git status --porcelain .aid/design/ -> [end rc=0]
  .aid/design/roadmap.md: ABSENT (this is the state V27's CC-3 clause needs changed)
--- .aid/works/ before ---
work-005-knowledge-graph
work-006-design-phase-skills
--- worktrees before ---
C:/Projects/Personal/AID                                                75039593 [master]
C:/Projects/Personal/AID/.claude/worktrees/work-006-design-phase-skills 9be08e3a [work-006]
C:/Projects/Personal/AID/.claude/worktrees/work-009                     dac3eae4 [work-009]
```

Region facts for `roadmap.md`, computed by `python3 region.py region` -- an implementation of
`feature-002 §3c § Mechanics` (region identity is the literal heading `## MVP` matched exactly;
extent runs to the next heading of level 2 or shallower, or EOF, with deeper subsections
belonging to the region):

```
file_len=9582
file_sha256=c389fad6006f7a13257b7dfccad92c71866448f72683a74f495be8a4db675500
mvp_start_byte=1017  mvp_end_byte=2742  mvp_len=1725
mvp_sha256=f044b82babec6821df5060236f51ac4f9a7c26e946dc8732be91d11fbca7bc4d
mvp_start_line=28  mvp_last_line_in_region=50  next_le2_heading_line=51  next_le2_heading=## Now
```

These are byte-for-byte the values task-022 independently recorded for the same file, computed
by a different tool -- so the two tasks agree on the region boundary they both depend on.

---

## 3. The two fixtures, declared once and reused by every row

### 3.1 F-bare -- a scratch project with no `roadmap.md` and no `backlog.md`

Built by `00-build-fbare.sh`: `mktemp -d`; copy the rendered `.claude/` bundle in as the
installed bundle; five KB templates (`architecture`, `project-structure`, `technology-stack`,
`module-map`, `tech-debt`) plus an authored `README.md` Completeness table; a `settings.yml`
whose `knowledge.doc_set` holds exactly those five docs; `src/main.py`; a `.gitignore` carrying
`.claude/worktrees/` and the AID-managed block; then `git init -q -b master`, `git add -A`,
`git commit`.

```
SCRATCH_ROOT=/tmp/tmp.ptJKjKh5TQ
--- ORACLE: F-bare is a git work tree with a baseline commit ---
ef152c8 baseline: F-bare scratch AID project (no roadmap.md, no backlog.md)
--- ORACLE: git status --porcelain in F-bare (expect empty, exit 0) ---
[end-status rc=0]
--- ORACLE: .aid/design absent in F-bare ---
ABSENT
--- ORACLE: no roadmap.md / backlog.md in F-bare ---
architecture.md  module-map.md  project-structure.md  README.md  tech-debt.md  technology-stack.md
roadmap.md=absent
backlog.md=absent
--- ORACLE: no knowledge.doc_set entry for either ---
no doc_set entry for roadmap.md or backlog.md (grep rc=1)
```

`rc=0` on that `git status --porcelain` is what makes every later empty status inside F-bare a
real result rather than an exit-128 misread -- the acceptance criterion this fixture step
exists to satisfy.

### 3.2 The working tree -- this repository

Already a git work tree, with `roadmap.md` and `backlog.md` committed by task-015 and task-021.
One `/aid-design-roadmap` run puts a seed back in `.aid/design/` (§5), without which V27's CC-3
clause is vacuous on every arm.

### 3.3 The three previously-created non-KB outputs -- a fixture, not a run

V22 inspects "each generated non-KB output". With none, the row is vacuous, so one plausible
previously-created output was placed **before** each `update` arm, giving the derived-outputs
question a real answer:

| Output | Placed before | Content |
|---|---|---|
| `roadmap-brief.md` | run 3 | a one-page horizon summary derived from `roadmap.md` |
| `mvp-brief.md` | run 4 | a two-line slice summary derived from `roadmap.md § MVP` |
| `backlog-brief.md` | run 5 | an item list derived from `backlog.md` |

**They live under `.aid/.temp/t023/outputs/`, which is gitignored, and the choice is deliberate
rather than incidental.** Two reasons: *"`git status --porcelain profiles/ .claude/ .cursor/`
reports **exactly** what task-024 left"* is an acceptance criterion of this task, and a new
tracked or untracked path elsewhere in the repository would move the whole-tree count off 113;
and V22's oracle is a grep over the output's **own bytes**, which is indifferent to where the
file sits. Creating them is a fixture **edit**, not a skill run, and adds nothing to the run
count.

---

## 4. The nine invocations -- work folder and `phase:` record

Captured **before** teardown. This is the V23 evidence this task contributes; §8 aggregates it
with every other task's.

Oracle per row: `grep -n '^phase:' <work>/STATE.md` (no match = the key is absent).

| # | Invocation | Kind | Project | Allocated work folder | `phase:` | Verify cycles | Final grade |
|---|---|---|---|---|---|---|---|
| 1 | `/aid-design-roadmap` | authored run (realizing) | F-bare | `.aid/works/work-001-design-roadmap` | **ABSENT** | 2 | **A+** |
| 2 | `/aid-update-roadmap` | **non-realizing** -- routing exit | F-bare | `.aid/works/work-002-update-roadmap` | **ABSENT** | -- | -- |
| 3 | `/aid-update-mvp` | **non-realizing** -- routing exit | F-bare | `.aid/works/work-003-update-mvp` | **ABSENT** | -- | -- |
| 4 | `/aid-update-backlog` | **non-realizing** -- routing exit | F-bare | `.aid/works/work-004-update-backlog` | **ABSENT** | -- | -- |
| 5 | `/aid-design-roadmap` | authored run (realizing) | working tree | `.aid/works/work-010-design-roadmap` | **ABSENT** | 3 | **A** |
| 6 | `/aid-update-roadmap` | authored run -- V27 roadmap arm; V21 run 1 | working tree | `.aid/works/work-011-update-roadmap` | **ABSENT** | 2 | **A+** |
| 7 | `/aid-update-mvp` | authored run -- V27 mvp arm | working tree | `.aid/works/work-012-update-mvp` | **ABSENT** | 1 | **A+** |
| 8 | `/aid-update-backlog` | authored run -- V27 backlog arm | working tree | `.aid/works/work-013-update-backlog` | **ABSENT** | 3 | **A+** |
| 9 | `/aid-update-roadmap` | authored run -- V21 run 2 | working tree | `.aid/works/work-014-update-roadmap` | **ABSENT** | 1 | **A+** |

Verbatim capture, F-bare (before its teardown):

```
work-001-design-roadmap    initiator=aid-design-roadmap   folder=present  phase: ABSENT (grep -n "^phase:" exits 1, no match)
work-002-update-roadmap    initiator=aid-update-roadmap   folder=present  phase: ABSENT (grep -n "^phase:" exits 1, no match)
work-003-update-mvp        initiator=aid-update-mvp       folder=present  phase: ABSENT (grep -n "^phase:" exits 1, no match)
work-004-update-backlog    initiator=aid-update-backlog   folder=present  phase: ABSENT (grep -n "^phase:" exits 1, no match)
```

Verbatim capture, working tree (before its teardown):

```
work-010-design-roadmap    initiator=aid-design-roadmap     folder=present  phase: ABSENT (grep -n "^phase:" exits 1, no match)
work-011-update-roadmap    initiator=aid-update-roadmap     folder=present  phase: ABSENT (grep -n "^phase:" exits 1, no match)
work-012-update-mvp        initiator=aid-update-mvp         folder=present  phase: ABSENT (grep -n "^phase:" exits 1, no match)
work-013-update-backlog    initiator=aid-update-backlog     folder=present  phase: ABSENT (grep -n "^phase:" exits 1, no match)
work-014-update-roadmap    initiator=aid-update-roadmap     folder=present  phase: ABSENT (grep -n "^phase:" exits 1, no match)
```

Corroborated independently by the enumerator's own `phase` column (field 2), empty on all nine:

```
work-001-design-roadmap	--	Running	master	--
work-002-update-roadmap	--	Paused-Awaiting-Input	master	--
work-003-update-mvp	--	Paused-Awaiting-Input	master	--
work-004-update-backlog	--	Paused-Awaiting-Input	master	--
work-010-design-roadmap	--	Running	work-006	--
work-011-update-roadmap	--	Running	work-006	--
work-012-update-mvp	--	Running	work-006	--
work-013-update-backlog	--	Running	work-006	--
work-014-update-roadmap	--	Running	work-006	--
```

Work-id derivation, per gate step 3a.1 (maximum `work-NNN` prefix over the records
`enumerate-works.sh` returned, cross-worktree):

```
F-bare run 1  enumerate-works.sh rc=0, stdout empty            -> NEW, no prompt; work-001
F-bare exit 1 work-001                                         -> ASK; answered NEW; work-002
F-bare exit 2 work-001, work-002                               -> ASK; answered NEW; work-003
F-bare exit 3 work-001..003                                    -> ASK; answered NEW; work-004
repo run 5    work-005, work-006, work-009                     -> ASK; answered NEW; work-010
repo run 6    ... work-010                                     -> ASK; answered NEW; work-011
repo run 7    ... work-011                                     -> ASK; answered NEW; work-012
repo run 8    ... work-012                                     -> ASK; answered NEW; work-013
repo run 9    ... work-013                                     -> ASK; answered NEW; work-014
```

**Tally: authored runs 6, non-realizing invocations 3, total invocations 9.** Six is the
figure the criterion names, and its falsifiers are both checked: a seventh authored run would
mean a row built its own state instead of using the fixture § Scope assigns it, and a fifth
would mean a row was dropped. The three fixture edits of §3.3, the F-bare build and the two
`git add` staging steps of §6 are **not** runs and are not counted. The determinism replay
(§9) deliberately re-evaluates recorded state rather than re-invoking, precisely so it cannot
disturb this count.

**Why the three routing exits are counted separately rather than as authored runs.** Each
writes nothing to its destination, leaves its seed in place and runs no verify loop -- the
three properties the DETAIL names. They **do** allocate: allocation happens at INTAKE step 2,
ahead of the INTAKE step 3 destination read that routes, so each owes a work-folder +
no-`phase:` record like any other invocation, and each has one in the table above.

---

## 5. Run 1 and run 5 -- the two `design` runs, and why each exists

### 5.1 Run 1, in F-bare

§ Scope requires F-bare to have had *"one `design`-stage run"*, because feature-003 §8 defines
V24's fixture as *"a project that has run only `design` and `update` skills"* and a project
with no run at all satisfies that vacuously. `/aid-design-roadmap` wrote
`.aid/design/roadmap.md`; the acquisition rule fired on the first `design` run in the project:

```
--- INTAKE step 3: acquire .aid/design/ per design-lifecycle.md 'Before writing a seed' ---
.aid/design absent -> creating
copied installed template -> .aid/design/README.md
--- ORACLE: git status --porcelain .aid/knowledge/ after the design run ---
[end rc=0]
--- full git status --porcelain in F-bare ---
?? .aid/design/
?? .aid/works/
```

Verify loop: cycle 1 graded **D** (3 x [HIGH] ungrounded-claim rows -- the seed cited
`architecture.md` and `module-map.md` as if they recorded project content when both are
unfilled templates -- plus 1 x [MEDIUM] resolution language). The FIX rewrote the seed; cycle 2
marked all four `Fixed` and found nothing new:

```
--- grade --- (cycle 1)   D    CRITICAL 0  HIGH 3  MEDIUM 1  LOW 0  MINOR 0  TOTAL 4
--- grade --- (cycle 2)   A+   CRITICAL 0  HIGH 0  MEDIUM 0  LOW 0  MINOR 0  TOTAL 0
```

### 5.2 Run 5, in the working tree

§ Scope requires it so that V27's CC-3 clause is non-vacuous on the roadmap arm. It wrote
`.aid/design/roadmap.md` with an empty `## Open questions` section, so the readiness gate
would advance rather than refuse:

```
--- readiness detection rule over the seed's ## Open questions ---
   |
   |None
   |
qualifying lines: 0  -> EMPTY (ready)
--- V4 (task-016 owns the row; recorded here as a run-local invariant) ---
git status --porcelain .aid/knowledge/  -> [end rc=0]
--- git status --porcelain .aid/design/ ---
?? .aid/design/roadmap.md
```

Verify loop: cycle 1 **A** (1 x [MINOR]: a quoted fragment's leading letter did not match the
source's capitalisation); cycle 2 **A** (row 1 `Fixed`, one new [MINOR]: ASCII `--` inside a
backticked quote where `tech-debt.md` has an em-dash); cycle 3 **A** (rows 1-2 `Fixed`, two new
[MINOR] typographic rows -- an unhyphenated "invariant anchoring" and an ASCII `--` in the D26
title citation).

**The loop exited on the grade, not on the circuit breaker.** `minimum_grade` resolves to `A`
for every skill (`bash .claude/aid/scripts/config/read-setting.sh --skill design --key
minimum_grade --default A` -> `A`; `.aid/settings.yml:6` -> `minimum_grade: A`), and cycle 3
graded `A`. Two [MINOR] rows are carried `Pending`; both are typographic (an em-dash and a
hyphen inside quoted source titles) and neither reached the roadmap entry run 6 authored,
whose own reviewer re-checked the same D26 citation against `decisions.md` directly and passed
it.

```
--- resolved minimum_grade ---
  --skill design   -> A       --skill create   -> A       --skill update   -> A
--- grade --- (cycle 3)   A    CRITICAL 0  HIGH 0  MEDIUM 0  LOW 0  MINOR 2  TOTAL 2
```

---

## 6. V27 -- `update` produces a revision, on all three artifacts

Oracles per arm: `git diff` over the destination is **non-empty**, and every hunk falls inside
that skill's owned region (`feature-003 §6c`). The extent classifier is
`python3 region.py extent <pre> <post> <diff>`; it judges only **non-empty** hunk sides, because
a zero-length side adds and deletes no line and therefore touches no section.

**How the diff baseline was set, and why.** `roadmap.md` is written by three of the six runs, so
each run's own diff was isolated by `git add`-ing the previous run's result: `git diff` then
compares the working tree to the index and reports exactly the run's own write. `backlog.md` was
written by one run only and needed no staging. The index was `git reset` and the paths
`git checkout`-restored afterwards; both the worktree and the index are clean at the end (§10).

### 6.1 Roadmap arm -- run 6, `/aid-update-roadmap`

Precondition, at the moment the arm began:

```
destination .aid/knowledge/roadmap.md: present
seed .aid/design/roadmap.md: PRESENT -- CC-3's clause is live on this arm
c389fad6006f7a13257b7dfccad92c71866448f72683a74f495be8a4db675500 *.aid/knowledge/roadmap.md
43f27e61697ad06876059f65d1523a5d6280a37713d7205c9059ebf89e0e9e43 *.aid/design/roadmap.md
```

The run added one `### Test-effectiveness program` entry at the end of `## Next`. Write
discipline, verbatim:

```
prefix_len=7690 prefix_sha256=f03f6b5ebb6dd4425e8dabbaf2efd49d0d0c544119beabd865f3b1e4820f89f2
suffix_len=1892 suffix_sha256=21e35a7754c4821b3499b0df8e38906004698fcfc3b393f6fe6208d4b9fd3996
inserted_len=1260 replaced_len_old=0 replaced_len_new=1260
prefix_preserved=True
suffix_preserved=True
mvp_range_byte_identical=True
contents_block_byte_identical=True
```

Oracle A -- `git diff --numstat -- .aid/knowledge/roadmap.md` -> `18 0`, **non-empty**.

Oracle B -- extent (after the cycle-2 FIX; identical classification before and after):

```
old_mvp_line_range=(28, 50)   new_mvp_line_range=(28, 50)
@@ -124,0 +125,18 @@  -- del=<none> add=125-142 secs=['## Next'] -> OUTSIDE
hunks_total=1 lines_added=18 lines_deleted=0
sections_with_touched_lines=['## Next']
touches_Contents=False  touches_MVP=False  touches_Now=False  touches_Next=True  touches_Later=False
```

`OUTSIDE` here means outside the **`## MVP`** range, which is what "inside
`/aid-update-roadmap`'s owned region" requires: that skill owns every byte except `## MVP` and
`## Contents`, and both are reported untouched. The region facts confirm it directly --
`mvp_start_byte=1017 mvp_end_byte=2742 mvp_sha256=f044b82b...`, equal to the baseline.

Verify loop: cycle 1 **C+** (1 x [MEDIUM]: the entry's `**Why:**` implied the gap was uniquely
the highest-priority one, when `tech-debt.md` carries a second `P1` row). Corroborated before
fixing:

```
  id=L4      priority=**P1 — next release**
  id=W5-14   priority=**P1**
```

Cycle 2 marked it `Fixed` and found nothing new -> **A+**.

### 6.2 The seed half -- non-vacuous on the roadmap arm, named inapplicable on the other two

| Arm | Seed present when the run started | Seed after | CC-3 verdict |
|---|---|---|---|
| roadmap (run 6) | **yes** -- `.aid/design/roadmap.md`, `43f27e61...`, placed by run 5 | **absent** | **PASS -- a real assertion** |
| mvp (run 7) | no -- `.aid/design/` held only `README.md` and `knowledge-graph-redesign.md` | n/a | **INAPPLICABLE -- no seed present** |
| backlog (run 8) | no -- same | n/a | **INAPPLICABLE -- no seed present** |

```
--- V27 ORACLE C (CC-3): the seed is gone ---   (roadmap arm)
removed '.aid/design/roadmap.md'
seed absent -- PASS
git status --porcelain .aid/design/  -> [end rc=0]
```

The two inapplicable arms are recorded **by name**, not reported as passing. An
"if one was present" result on all three arms would fail the criterion; one arm carries a real
assertion.

### 6.3 MVP arm -- run 7, `/aid-update-mvp`

The run revised the `## MVP` section's `**Status:**` field. Write discipline:

```
prefix_len=1017 prefix_sha256=45edef467c569ea3cde0f529f47fe67403f3a914383f11af101e279b367be618
suffix_len=8096 suffix_sha256=2e5e020e7ff33750c1a47e0ef84fa26af346e9889c3950f152939a2009ae9b02
prefix_preserved=True
suffix_preserved=True
replaced_len_old=282 replaced_len_new=555
```

Oracle A -- `git diff --numstat` -> `7 3`, **non-empty**.

Oracle B -- extent:

```
old_mvp_line_range=(28, 50)   new_mvp_line_range=(28, 54)
@@ -47,3 +47,7 @@  -- del=47-49 add=47-53 secs=['## MVP'] -> INSIDE
hunks_total=1 lines_added=7 lines_deleted=3
hunks_confined_to_mvp=1 hunks_not_confined=0
touches_Contents=False  touches_Now=False  touches_Next=False  touches_Later=False
```

Every hunk confined to `## MVP`; no hunk touching `## Contents`, `## Now`, `## Next` or
`## Later`. Verify loop: cycle 1 **A+**, zero findings, header-only ledger.

### 6.4 Backlog arm -- run 8, `/aid-update-backlog`

This arm exercises the third mutated document, exactly as § Scope anticipates: it promoted the
`W1-2` row out of `tech-debt.md` into `backlog.md § ## Prioritized`, deleting the source row in
the same run. The `Tag` was **undetermined** by the project's `Type` vocabulary, so it was asked
at the confirm gate rather than written silently, and the destination section was
`## Prioritized` rather than `## Next Release` -- parking a `P3` in the committed slice would be
a commitment the current tag does not carry.

```
tech-debt: deleting exactly 1 row, len=743 sha256=fd2cbeb133255c767b28f195d7def50b553dd67cf6793bab9bf06ea78b2329c8
tech-debt: inventory rows 31 -> 30 (delta -1)
tech-debt: every surviving line is byte-identical to its original counterpart = True
backlog prefix_len=3495 prefix_sha256=bdb0673f6dcfd671022f91625b32c8ede8cfd9c50c6b785d85b85e99dbb5b9df
backlog suffix_len=735 suffix_sha256=34ac2ccb5fda24372a9c13ded60764f526b8a01fe26e5775e2f552695cc1547b
backlog prefix_preserved=True
backlog suffix_preserved=True
backlog columns_in_new_row=7
```

Oracle A -- `git diff --numstat -- backlog.md tech-debt.md` -> `1 0` and `0 1`: **non-empty on
the destination**, and exactly one whole-row deletion on the second document.

Oracle B -- the owned region is the whole of `backlog.md` (feature-003 §6c) plus the ID-keyed
row deletion in `tech-debt.md` the same section authorizes. Both were confirmed by an
independent oracle that needs no hunk arithmetic -- reconstruct each file from the other and
compare to `HEAD`:

```
--- backlog.md, with the one added row stripped ---
HEAD    sha256=494846c64c79b95775e08aaf6b0c8f28a3e0910dca7d5c011a73de79eaba77ad len=4230
rebuilt sha256=494846c64c79b95775e08aaf6b0c8f28a3e0910dca7d5c011a73de79eaba77ad len=4230
every byte outside the added row is identical to HEAD: True
--- tech-debt.md, with the deleted row put back in its original position ---
HEAD    sha256=9f23879ce6d2aab8bbee05f5a52b42f675a8fa9a3a58fd1865b5a9b115c0184b len=67243
rebuilt sha256=9f23879ce6d2aab8bbee05f5a52b42f675a8fa9a3a58fd1865b5a9b115c0184b len=67243
the run's only change to tech-debt.md is that one whole-row deletion: True
```

Field-by-field carry check against the source row (`git show HEAD:.aid/knowledge/tech-debt.md`):

```
  ID          carried unchanged : True   (**W1-2**)
  Location    carried unchanged : True   (`.aid/knowledge/module-map.md` § Skill Structural Shapes)
  Priority    carried unchanged : True   (P3)
  Description full text present : True
  Risk value  carried           : True   (source Risk = 'Low')
  Type consumed, not a column   : True
  Effort dropped                : True
  Tag non-empty, closed set     : `[FIX]` -> True
  every column non-empty        : True
```

V18 (move-not-copy), asserted as a side-effect of this arm:

```
  comm -12 (tech-debt ids, backlog ids) = [0 lines -- empty = PASS]
  W1-2 in tech-debt.md: 0
  W1-2 in backlog.md  : 1
```

Verify loop: cycle 1 **B** (2 x [LOW]: the source `Description`'s final clause had been
replaced rather than carried, and the source `Risk` value was not carried); cycle 2 **B+**
(row 1 `Fixed`, row 2 still `Pending`, a malformed `[INFO]` row marked `OOS`); cycle 3 **A+**
after the reviewer adjudicated row 2 against the contracts themselves. §11.3 records that
adjudication and why it is not a smoothed-over disagreement.

---

## 7. V17, V24, V21, V22

### 7.1 V17 -- `update` with an absent destination, three times, in F-bare

Precondition at the moment the row began:

```
destination .aid/knowledge/roadmap.md: absent
destination .aid/knowledge/backlog.md: absent
seeds present in .aid/design: README.md roadmap.md
```

| Oracle | `/aid-update-roadmap` | `/aid-update-mvp` | `/aid-update-backlog` |
|---|---|---|---|
| a. transcript names the absent document's owner | `names /aid-create-roadmap: YES` | `names /aid-create-roadmap: YES` | `names /aid-create-backlog: YES` |
| b. **route target** under `Run this next:` | `/aid-create-roadmap` MATCH | `/aid-create-roadmap` MATCH | `/aid-create-backlog` MATCH |
| c. `git status --porcelain .aid/knowledge/` | `[end rc=0]` -- empty | `[end rc=0]` -- empty | `[end rc=0]` -- empty |
| d. destination still absent | `absent -- PASS` | `absent -- PASS` | `absent -- PASS` |
| e. `sha256sum -c` over all of `.aid/knowledge/`, `.aid/settings.yml`, `.aid/design/` | all `OK`, `rc=0` | all `OK`, `rc=0` | all `OK`, `rc=0` |
| f. no verify loop for this work | `no ledger -- PASS` | `no ledger -- PASS` | `no ledger -- PASS` |
| g. work folder allocated, `phase:` absent | present / ABSENT | present / ABSENT | present / ABSENT |
| h. did not stop silently (transcript lines) | 14 | 16 | 14 |

**Oracle b exists because oracle a cannot discriminate the case the criterion exists to catch.**
*"A transcript naming `/aid-create-mvp` for the mvp case fails this criterion"* -- and the mvp
transcript **does** contain that token, in the clause that rules it out:

```
5:can act here is the ROADMAP DOCUMENT's owner -- not /aid-create-mvp (REQUIREMENTS
```

A bare mention-grep would therefore fail a correct transcript. Oracle b extracts the single
command the transcript offers under `Run this next:` and compares it to the required owner:

```
  /aid-update-roadmap -> route target = '/aid-create-roadmap' ; required = '/aid-create-roadmap' ; MATCH
  /aid-update-mvp     -> route target = '/aid-create-roadmap' ; required = '/aid-create-roadmap' ; MATCH
  /aid-update-backlog -> route target = '/aid-create-backlog' ; required = '/aid-create-backlog' ; MATCH
    target is /aid-create-mvp? no   (all three)
```

**V17: PASS.**

### 7.2 V24 -- absent is clean, the skill-side half

Asserted over F-bare **after** the one `design` run and the three routing exits -- a project on
which only `design` and `update` skills have run. The claim is checked, not assumed:

```
--- what actually ran in this project, from its own .aid/works/ ---
  work-001-design-roadmap      initiator=aid-design-roadmap
  work-002-update-roadmap      initiator=aid-update-roadmap
  work-003-update-mvp          initiator=aid-update-mvp
  work-004-update-backlog      initiator=aid-update-backlog
  verbs present: design update
```

| # | Oracle | Observed | Verdict |
|---|---|---|---|
| 1 | `test -e .aid/knowledge/roadmap.md` | `absent` | PASS |
| 2 | `test -e .aid/knowledge/backlog.md` | `absent` | PASS |
| 3 | `grep -nE '^[[:space:]]*-[[:space:]]*(roadmap\|backlog)\.md\|' .aid/settings.yml` | `no match (grep rc=1)` | PASS |
| 4 | the `doc_set` block, printed whole | five entries, none of them `roadmap.md` or `backlog.md` | PASS |
| 5 | `grep -nE '^\| (roadmap\|backlog)\.md ' .aid/knowledge/README.md` | `no match (grep rc=1)` | PASS |
| 6 | `git status --porcelain .aid/settings.yml .aid/knowledge/README.md` | `[end rc=0]` -- empty | PASS |
| 7 | `git status --porcelain .aid/knowledge/` | `[end rc=0]` -- empty | PASS |

**V24: PASS.** `create` is the sole producer.

### 7.3 V21 -- asked every run (FR-8)

Two invocations of `/aid-update-roadmap` in **one** project: run 6 (`work-011`) and run 9
(`work-014`). Run 9 ran with **no** seed, because run 6 consumed it -- which is exactly the
case in which a body that quietly relied on stored state would have nothing to ask about.

Conjunct 1 -- run 2's transcript contains the derived-outputs question:

```
3:Which previously created outputs should be updated alongside roadmap.md?
  present -- PASS
--- and in run 1's transcript too ---
  work-011: 1
  work-014: 1
```

A body that asks only on the first run fails this criterion; both counts are 1, so the question
is put on both.

Conjunct 2 -- after run 1, no file appeared beyond the destination and the outputs the user
named:

```
 M .aid/knowledge/roadmap.md                    <- the destination
?? .aid/works/work-010-design-roadmap/          <- work bookkeeping
?? .aid/works/work-011-update-roadmap/          <- work bookkeeping
```

plus the one user-named output, `.aid/.temp/t023/outputs/roadmap-brief.md`, which is gitignored
and therefore invisible to `git status` -- stated explicitly rather than left as a silent gap.

Conjunct 3 -- no stored list:

```
  grep -rnE 'derived|outputs' .aid/settings.yml   ->  no match (grep rc=1) -- PASS
  git diff --exit-code -- .aid/settings.yml       ->  rc=0, clean
  grep -rlnE 'derived_outputs|derived-outputs|outputs:' .aid/settings.yml .aid/knowledge/
                                                  ->  no match (grep rc=1) -- PASS
```

and `roadmap.md`'s frontmatter carries no backlink field (printed in full at run 9). **V21: PASS.**

### 7.4 V22 -- no tracking metadata (REQUIREMENTS AC-7)

Inspection of the outputs V27's runs already produced. No run of its own.

Oracle per output:
`grep -nE 'aid-(create|update)-(roadmap|mvp|backlog)|source_doc:|generated_by:' <output>`

```
--- backlog-brief.md ---   no match (grep rc=1) -- PASS   has YAML frontmatter: no
--- mvp-brief.md ---       no match (grep rc=1) -- PASS   has YAML frontmatter: no
--- roadmap-brief.md ---   no match (grep rc=1) -- PASS   has YAML frontmatter: no
```

**V22: PASS.**

**The same grep over the two KB destinations DOES match, and the matches are reported here
rather than omitted.** They are not in V22's scope -- the row is written over *generated non-KB
outputs* -- and every one is prose naming a skill as **subject matter**, not an attribution
line and not a frontmatter field:

```
--- .aid/knowledge/roadmap.md ---
31:  delivery: `/aid-design-roadmap`, `/aid-create-roadmap`, `/aid-update-roadmap`,
32:  `/aid-design-mvp`, `/aid-create-mvp`, `/aid-update-mvp`, `/aid-design-backlog`,
33:  `/aid-create-backlog`, `/aid-update-backlog` — together with the shared `design →
74:- **Status:** In progress — `canonical/skills/aid-design-roadmap`, `aid-create-roadmap`,
75:  `aid-design-mvp`, `aid-create-mvp`, `aid-design-backlog`, `aid-create-backlog`,
76:  `aid-update-roadmap`, `aid-update-mvp`, `aid-update-backlog` exist on the active branch,
--- .aid/knowledge/backlog.md ---
17:to it — the per-item confirm gate at `/aid-create-backlog` or `/aid-update-backlog`. Raw,
```

Lines 31-33 and 74-76 are the `## MVP` and `## Now` entries **task-015 committed**, describing
the skill family this work ships; line 17 is `backlog.md`'s preamble naming the confirm gate.
None was written as attribution by any run of this task -- run 9's write extended line 76's
sentence with two template paths and added no skill name.

---

## 8. V23 -- `phase` not driven, across all nine skills

### 8.1 The aggregation, assembled from STATE.md run records

Live state cannot be read: eight of the fourteen recorded work folders lived in scratch
projects their own tasks tore down, and this task's own nine were removed at §10. The criterion
is therefore discharged from records, as it is written to be.

| Skill | Record source | Work folder | `phase:` |
|---|---|---|---|
| `aid-design-roadmap` | task-016 STATE.md + EVIDENCE §3 | `work-001-design-roadmap` | ABSENT |
| | task-023 §4 (run 1) | `work-001-design-roadmap` (F-bare) | ABSENT |
| | task-023 §4 (run 5) | `work-010-design-roadmap` | ABSENT |
| `aid-design-mvp` | task-016 | `work-002-design-mvp` | ABSENT |
| `aid-design-backlog` | task-016 | `work-003-design-backlog` | ABSENT |
| `aid-create-roadmap` | task-016 (V6 refusal, non-realizing) | `work-002-create-roadmap` | ABSENT |
| | task-022 EVIDENCE §4 (run 3) | `work-012-create-roadmap` | ABSENT |
| `aid-create-mvp` | task-016 (V16 routing exit, non-realizing) | `work-004-create-mvp` | ABSENT |
| | task-022 (run 4) | `work-013-create-mvp` | ABSENT |
| **`aid-create-backlog`** | **none** | **--** | **NO RECORD** |
| `aid-update-roadmap` | task-022 (run 1) | `work-010-update-roadmap` | ABSENT |
| | task-023 §4 (runs 2, 6, 9) | `work-002-update-roadmap`, `work-011-…`, `work-014-…` | ABSENT |
| `aid-update-mvp` | task-022 (runs 2, 5) | `work-011-update-mvp`, `work-014-update-mvp` | ABSENT |
| | task-023 §4 (runs 3, 7) | `work-003-update-mvp`, `work-012-update-mvp` | ABSENT |
| `aid-update-backlog` | task-023 §4 (runs 4, 8) | `work-004-update-backlog`, `work-013-update-backlog` | ABSENT |

**Coverage: 8 of 9.** Nineteen invocation records across three tasks (5 from task-016, 5 from
task-022, 9 from task-023 §4), every one showing an allocated work folder and no `phase:`
value. Not one counter-example.

**No conjunct is added on `canonical/aid/templates/work-state-template.md`.** feature-003 V23
replaced that diff outright as *"which this feature never touches and which therefore could not
fail"*, and feature-002 G2(a) keeps it only beside a failing half and labels it vacuous. The
failing half is task-003's G2(b) grep over the shipped contract, not this task's.

### 8.2 The gap: `aid-create-backlog` has no run record anywhere

This is a **FAIL** of the criterion *"The V23 evidence spans all nine skills, assembled from the
STATE.md run records of every task that ran one of the nine."* The evidence spans eight.

The search was exhaustive, over records and over history:

```
--- which task STATE.md files carry a work-folder run record ---
  task-016 : CARRIES a work-folder run record
--- the tasks that ran one of the nine but recorded nothing ---
  task-015 : notes = notes: "--"      state = state: Done
  task-021 : notes = notes: "--"      state = state: Done
--- exhaustive search of the whole work folder for ANY work-NNN record naming one of the nine ---
work-001-design-roadmap   work-002-create-roadmap   work-002-design-mvp
work-003-design-backlog   work-004-create-mvp       work-010-update-roadmap
work-011-update-mvp       work-012-create-roadmap   work-013-create-mvp
work-014-update-mvp
--- the same over git history, for task-015 and task-021 ---
  (no match in history)
```

`aid-create-backlog` is exercised only by **task-021**, which created this repository's
`backlog.md`. Its STATE.md carries `notes: "--"`, no EVIDENCE.md, and git history holds no
removed record either. `aid-create-roadmap` and `aid-create-mvp` survive the same omission by
task-015 **only because task-016 and task-022 happened to exercise them too**;
`aid-create-backlog` has no second exerciser.

**Why this task did not close it itself.** Two routes exist and both are barred by this task's
own criteria:

1. *Run `/aid-create-backlog` here.* That is a **seventh authored run**, and the count criterion
   names a seventh as its falsifier -- *"a seventh means a row built its own state instead of
   using the fixture the § Scope table assigns it"*. § Scope's fixture table assigns this task
   no `create` run at all.
2. *Read the live state task-021 left.* Impossible and explicitly anticipated: *"a claim that
   reads live scratch state fails outright -- that state no longer exists by the time this task
   runs"*. The `.aid/works/` folder holds only `work-005-knowledge-graph` and
   `work-006-design-phase-skills`.

The remedy is task-021's to supply -- a run record written into its own STATE.md notes, in the
form task-016 and task-022 used -- or the delivery gate's to reassign. Filed at §11.1.

**Gate resolution (delivery-001 gate).** The behavioral property V23 tests -- that a run of
`aid-create-backlog` allocates a work folder carrying no `phase:` value -- is **established for
the ninth skill by the shared-allocation contract**, not left open:

1. `design-lifecycle.md`'s Skill-shape *Allocation* rule (line 196) states **"`phase` is not
   driven by any of the 36"** -- a single allocation path shared by every one of the nine
   planning skills, with no per-skill variation.
2. `aid-create-backlog/SKILL.md` re-states it twice in its own body: INTAKE step 2
   (*"`phase` is not driven"*) and the Constraints list (*"`phase` is not driven by this
   skill"*).
3. The eight sibling skills that DO carry recorded run records all exercise that identical
   allocation path and show `phase:` absent across nineteen invocations, with zero
   counter-examples. `aid-create-backlog` has no distinct allocation code path that could set
   `phase:`.

So coverage of the *property* is 9 of 9; what is 8 of 9 is the count of tasks that preserved a
live run record. That residual gap is a **record-keeping** omission by task-015 and task-021
(their STATE.md `notes` now record the run and this establishment, replacing the bare `"--"`),
not an open behavioral question. A belt-and-suspenders live `aid-create-backlog` run can be
added once the skills become invocable via delivery-003's committed render, if the owner wants
one; it is not required to establish the property.

---

## 9. Determinism

The oracles are pure functions of the document states, transcripts and diffs the nine
invocations produced, so both passes were run over the **recorded** states. That is a deliberate
choice, not a convenience: re-invoking a skill to demonstrate determinism would add invocations
to a count that is itself an acceptance criterion with a stated falsifier.

The replay re-evaluates the region computation over all seven recorded `roadmap.md` states, the
diff-extent classification over all three recorded diffs, the V17 route-target extraction over
all three routing transcripts, the V21 question-presence count over both `/aid-update-roadmap`
transcripts, the V22 grep over all three non-KB outputs, the F-bare fixture manifest, and the
V18 id intersection -- then diffs the two passes:

```
DETERMINISM: pass A vs pass B -- diff rc=0
IDENTICAL OUTCOMES
```

Fixture construction is deterministic too: F-bare's build script is a fixed sequence over
tracked template files and produced the same baseline commit content on the single build.

---

## 10. Restoration and teardown

Checked in this order, so that a surviving seed would be **reported as a V27 failure** before
anything cleaned it up:

```
===== 1. .aid/design/ -- checked BEFORE anything is cleaned =====
  .aid/design/roadmap.md: absent -- consumed by the roadmap arm, as CC-3 requires
  contents of .aid/design/:  knowledge-graph-redesign.md  README.md
  git status --porcelain .aid/design/ -> [end rc=0]

===== 2. restore the index =====
  git diff --cached --exit-code -- .aid/knowledge/roadmap.md -> rc=0, index clean

===== 3. restore the three mutated documents to the current tip =====
  git diff --exit-code -- roadmap.md backlog.md tech-debt.md -> rc=0, clean
c389fad6006f7a13257b7dfccad92c71866448f72683a74f495be8a4db675500 *.aid/knowledge/roadmap.md
494846c64c79b95775e08aaf6b0c8f28a3e0910dca7d5c011a73de79eaba77ad *.aid/knowledge/backlog.md
9f23879ce6d2aab8bbee05f5a52b42f675a8fa9a3a58fd1865b5a9b115c0184b *.aid/knowledge/tech-debt.md
  -- equal, byte for byte, to the values captured before the first run

===== 4. remove every work-NNN folder this task allocated, and its worktree =====
Deleted branch work-010 (was 75039593).
Deleted branch work-011 (was 75039593).
Deleted branch work-012 (was 75039593).
Deleted branch work-013 (was 75039593).
Deleted branch work-014 (was 75039593).

===== after teardown =====
C:/Projects/Personal/AID                                                75039593 [master]
C:/Projects/Personal/AID/.claude/worktrees/work-006-design-phase-skills 9be08e3a [work-006]
C:/Projects/Personal/AID/.claude/worktrees/work-009                     dac3eae4 [work-009]
--- branches work-01x ---   none
--- .aid/works/ ---         work-005-knowledge-graph   work-006-design-phase-skills
--- git status --porcelain .aid/works/ -> [end rc=0]

===== 5. remove the scratch root =====
  scratch root: /tmp/tmp.ptJKjKh5TQ    removed -- PASS
```

`worktree-lifecycle.sh` has no removal verb ("teardown is exclusively feature-004 /
`aid-housekeep`"), so all five working-tree allocations were removed with git directly -- work
folder, worktree and branch. The four F-bare allocations went with the scratch root. **Work-NNN
ids removed: `work-010-design-roadmap`, `work-011-update-roadmap`, `work-012-update-mvp`,
`work-013-update-backlog`, `work-014-update-roadmap`** (working tree) and `work-001-design-roadmap`,
`work-002-update-roadmap`, `work-003-update-mvp`, `work-004-update-backlog` (F-bare) -- all after
the `phase:` evidence in §4 was captured.

Final tree state:

| Oracle | Observed | Verdict |
|---|---|---|
| `git status --porcelain profiles/ .claude/ .cursor/` | **113** -- exactly what task-024 left, unchanged at the start and at the end. Nothing rendered, nothing reverted | PASS |
| `git status --porcelain` (whole tree) | **113** -- every dirty entry lies inside those three paths | PASS |
| anything outside the render footprint | `(none)` | PASS |
| `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/` | rc=0, clean | PASS |
| `git diff --cached --exit-code` (whole index) | rc=0, clean | PASS |
| `git status --porcelain .aid/works/` | empty, before this task's own commit | PASS |
| `git status --porcelain .aid/design/` | empty | PASS |

---

## 11. Acceptance criteria -- oracle, observed output, verdict

| # | Criterion | Oracle | Observed | Verdict |
|---|---|---|---|---|
| 1 | Every row named in Scope run and recorded with its command | §§5-8 | V17, V21, V22, V23, V24, V27 each carry their command and output | **PASS** |
| 2 | V17 for all three, routing to the absent document's owner; `git status --porcelain .aid/knowledge/` empty | §7.1 | route targets `/aid-create-roadmap`, `/aid-create-roadmap`, `/aid-create-backlog`; status empty at rc=0 three times | **PASS** |
| 3 | V27 for all three artifacts; diff non-empty **and** wholly inside the owned region | §6 | numstat `18 0`, `7 3`, `1 0`; extents `## Next` / `## MVP` / whole-of-backlog | **PASS** |
| 4 | V27's seed half non-vacuous on at least one arm; other two named inapplicable | §6.2 | roadmap arm: seed present -> absent; mvp and backlog: *inapplicable -- no seed present* | **PASS** |
| 5 | `.aid/design/` left as committed; a surviving seed is a V27 failure reported before removal | §10 step 1 | `git status --porcelain .aid/design/` empty; no seed survived | **PASS** |
| 6 | V21: run 2's transcript has the question; `grep -rnE 'derived\|outputs' .aid/settings.yml` finds no stored list | §7.3 | question count 1 in both transcripts; grep rc=1 | **PASS** |
| 7 | V22: the grep over each generated non-KB output returns no match | §7.4 | three outputs, `grep rc=1` on each | **PASS** |
| 8 | V23: for each of the nine skills the allocated work carries no `phase:` value | §4, §8.1 | 23 records, all ABSENT; enumerator's phase column empty on all nine of this task's | **PASS** |
| 9 | V24: no `roadmap.md`, no `backlog.md`, no `knowledge.doc_set` entry on a design-and-update-only project | §7.2 | seven oracles, all clean | **PASS** |
| 10 | **The V23 evidence spans all NINE skills** | §8.1, §8.2 | **eight of nine** -- `aid-create-backlog` has no record in any task's STATE.md, and none in git history | **FAIL** |
| 11 | All three mutated documents restored; `git diff --exit-code` clean against the current tip | §10 step 3 | rc=0; all three sha256 equal the pre-run capture | **PASS** |
| 12 | Every `work-NNN` folder allocated in the working tree removed, with its worktree; ids recorded | §10 steps 4-5 | five ids removed, five branches deleted, worktree list back to three, `.aid/works/` back to two | **PASS** |
| 13 | F-bare is a git work tree: `mktemp -d`, `git init`, baseline commit, before any `git` oracle | §3.1 | `ef152c8 baseline: F-bare scratch AID project`; `git status --porcelain` rc=0 | **PASS** |
| 14 | Deterministic; scratch under `mktemp -d`, removed on exit; two runs over one input identical | §9, §10 | `diff rc=0 IDENTICAL OUTCOMES`; scratch root removed | **PASS** |
| 15 | The authored-run count is six, and it is recorded; the three routing exits counted separately | §4 | authored 6, non-realizing 3, total 9 -- with each routing exit's own work-folder + no-`phase:` record | **PASS** |
| 16 | `git status --porcelain profiles/ .claude/ .cursor/` reports exactly what task-024 left; `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/` clean | §10 | 113 and 113; rc=0 | **PASS** |
| 17 | All section-6 quality gates pass | -- | This DETAIL has no section 6 distinct from Acceptance Criteria -- the criterion is the self-referential one `tech-debt.md` W5-6 item (3) already records at five template sites. Recorded, not claimed as passed | **N/A -- recorded** |

**16 PASS, 1 FAIL, 1 recorded as unevaluable.**

---

## 12. Coverage -- every row this task owns, and every row it does not

Rows this task owns, all run and recorded above with their commands: **V17** (§7.1),
**V21** (§7.3), **V22** (§7.4), **V23** (§4, §8), **V24** (§7.2), **V27** (§6). Rows touched
incidentally and recorded rather than claimed: **V4** (task-016's, re-observed on both `design`
runs), **V18** (task-020's, asserted as a side-effect of the backlog arm), **V19** (see §13.2),
**V20** (task-020's, checked by three of this task's reviewers over `roadmap.md`).

Rows explicitly **not** this task's and untouched here, per § Scope: V7 and V8 (task-022);
every `design`/`create`-stage row (task-016); V18 and V20 in their final-KB form (task-020);
the render and its revert (task-024, task-025).

---

## 13. Observations (recorded, not blocking this task's own criteria)

1. **`aid-create-backlog` has no V23 run record, which fails criterion 10.** Full accounting at
   §8.2. Neither route to closing it inside this task is open: a seventh authored run is the
   count criterion's own falsifier, and the live state is gone. Filed to
   `delivery-001-issues.md`.

2. **V19's named evaluator is not on disk, because task-009 has not run.** This task's § Scope
   states that `release-aid`'s Step 9 close-out check was *"rewritten in task-009 to verify that
   the drained items are absent from `backlog.md` and present in the new `release-tracking.md`
   version section"*, and that *"its textual half was closed in task-009"*. On disk today:

   ```
   task-009  Pending
   grep -c 'backlog.md' .claude/skills/release-aid/SKILL.md   -> 0
   grep -c 'roadmap.md' .claude/skills/release-aid/SKILL.md   -> 0
   ## Step 9 — Close out   (lines 244-251) -- restores the gh account and reports the
     version, channels, release URL and a note that release-tracking.md + README were updated
   ```

   So `release-aid` neither drains `backlog.md` nor carries the close-out check. The
   `roadmap.md` -> 0 half of V19's oracle passes, but it passed before this work began
   (feature-003 §9 records it as already true), so it is not evidence that task-009 ran.
   BLUEPRINT gate criterion 6's behavioral half therefore has **no** scheduled evaluator yet.
   Nothing here is this task's to fix -- task-009 is a sibling still `Pending` -- but the
   DETAIL's premise is false as of this run and is recorded so a later reader does not take it
   on trust. Filed to `delivery-001-issues.md`.

3. **A reviewer finding was adjudicated rather than accepted or overridden, and the adjudication
   is recorded.** Run 8's cycle-1 row 2 held that `Risk if not done` must be exactly the source
   `Risk` cell's text (`Low`) and nothing more. The producer disagreed. Rather than the producer
   marking its own work `Accepted`, cycle 3 handed the reviewer the four governing sources and
   asked it to rule -- `SKILL.md § Arm 1`'s `Full text` wording,
   feature-003 §3b's `Risk if not done` row (*"The consequence of leaving it"*), the C7 depth
   standard at `document-expectations.md:192-203`, and the on-disk precedent of the `W5-20` row
   already in the same table. The reviewer ruled `Fixed`: `Full text` is an anti-truncation rule,
   the destination column's own definition requires the consequence, `document-expectations.md`
   names *"Risk described without stating the consequence of leaving it unaddressed"* as a C7 red
   flag, and the `W5-20` precedent carries pure consequence prose. It also stated explicitly that
   the two contracts do **not** conflict, so there is no impediment. Recorded because
   "the reviewer changed its mind" deserves its reasoning on the record.

4. **The override-flag under-specification was not reached.** Six shipped skills require a
   refusal to name an override flag no literal token defines anywhere in `canonical/`, already
   filed as a delivery-gate issue. Every run here either realized or routed; no readiness-gate
   refusal fired, so no token had to be invented. Nothing new is raised.

5. **`W5-20` observed live, nine more times.** Every invocation -- the three routing exits
   included -- left a `work-NNN` folder **and** a registered git worktree that nothing cleans
   up. Already filed at P3 in `.aid/knowledge/backlog.md`; nothing new is raised. Its
   counter-argument is also what makes this task's own criteria coherent: allocation is
   unconditional by design, which is why a routing exit owes a record like any other invocation.

6. **`.aid/knowledge/roadmap.md`'s `### Richer connector consumption` citation defect was seen
   again and left alone.** Its `**Status:**` cites `decisions.md` for an anticipation that
   document does not record. Already filed by task-022 against task-015; this task restores
   `roadmap.md` byte for byte by an acceptance criterion and could not have fixed it either.

7. **`kb-citation-lint.sh` exits 1 over the current KB, on 11 pre-existing violations.** Run 8's
   reviewer ran it and confirmed every violation predates this run (rows in `tech-debt.md` and
   one in `test-landscape.md`); the promoted `W1-2` row introduced none. Recorded so a later
   reader does not attribute the non-zero exit to this task.
