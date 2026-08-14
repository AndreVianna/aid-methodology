# AC-2 proof — the removed check's defect class

**Result: PASS.** The class `check-skill-counts.mjs` existed to catch is caught by the declaration
that replaced it, without the deleted script. A removal whose replacement cannot catch the defect
would be a regression rather than a retirement; this one is a retirement.

## Harness

`git worktree add --detach <tmp> HEAD`, plant, review, `git worktree remove --force`. Nothing
committed, the work branch's files never edited (**NFR-1**), teardown verified: the plant is absent
from the tracked tree and `git worktree list` shows only the main tree. No maintained test added.

## The plant

`.aid/knowledge/module-map.md`, line 221: **`76 skill directories` → `92 skill directories`.**

That is precisely the class the deleted guard was built for — a stale, load-bearing count written
into prose. `92` is not arbitrary: it is a real historical value of this very figure, which is what
made the class so persistent that a 379-line repo-wide guard was written to chase it.

Disk truth at plant time: `ls -d canonical/skills/*/ | wc -l` = **76**.

## The dispatch

`aid-reviewer`, pointed at the worktree, asked only to review `module-map.md` "for accuracy against
the repository it describes". **The prompt named no criterion, no criterion id, no count, and never
mentioned the retired guard.**

## Outcome — caught, via the declaration

The review returned the planted count as its **row 1, `[CRITICAL]`**, and reached it the way the
mechanism intends:

- It named **`module-map.md`'s own `F-02`** — *"The skill, agent and profile counts stated here are
  measured from `canonical/skills/`, `canonical/agents/` and `profiles/`"* — as its highest
  authority for the file, then the global criteria table as the second. That declaration was
  authored by task-011; it is the replacement the removal rests on.
- It established the real value **from disk** (`ls canonical/skills/ | wc -l = 76`), which is what
  the deleted guard did mechanically.
- It noticed the plant contradicted the decomposition in its own sentence (`18 + 34 + 24` = 76, not
  92) and the module inventory 135 lines above — reasoning across the document rather than matching
  a string.

**Nothing in the review referenced the deleted script**, because nothing could: it no longer
exists. The catch came entirely from the declared criteria.

## The stronger result: the declaration caught MORE than the guard did

The same review found **four real count drifts on the tracked tree** that the deleted guard never
covered — it guarded the skill-count triple against its own claim list, not arbitrary measured
figures:

| What | Stated | Actual |
|---|---|---|
| A third value for the skill total, in a "Measured" note | `47 of the 75` | the inventory says 76, disk says 76 |
| Exemplar `SKILL.md` line counts | `aid-research (181)`, `aid-test (131)`, `aid-prototype (129)`, `aid-design (120)` | 178, 130, 128, 119 |
| A stated size range for the same eight skills | `120--220 lines` | violated at both ends — `aid-update-document` is 105, `aid-review` is 221 |
| A runtime module's size | `~642 lines` | 657 |

All four sat under an explicit *"CONFIRMED: line counts … measured directly"* claim, which is what
made them load-bearing rather than cosmetic — and therefore `G-01` violations rather than noise.

**Fixed as a class, not as four instances** (FIX contract `F1`): every stated line count and size
range in `module-map.md` is now replaced by the shape it was standing in for, plus an instruction to
measure when you need the number. The `CONFIRMED` block now says outright that line counts are
deliberately not asserted, because every one that was had drifted by the next reading. The counts
that remain — 76 skills, 9 agents, 5 profiles — are the load-bearing ones `F-02` governs, and they
match disk.

That is the retirement's real justification. The guard checked a fixed claim list mechanically; the
declaration checks whatever the document actually asserts, which is a wider surface — at the cost of
being reviewer-applied rather than automatic. Both halves of that trade are recorded in
`removal-set.md`.
