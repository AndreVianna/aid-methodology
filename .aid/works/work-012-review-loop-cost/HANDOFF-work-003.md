# Handoff brief — resuming `work-003` (review subsystem redesign)

> Paste the section below to the agent that will resume `work-003`. It is written to be
> read cold, with no access to the conversation that produced it. Every number in it
> states the command that produced it, so the agent can re-measure rather than trust.

---

## Your task

Resume `work-003` (PR #185, branch `work-003`, "rebuild the review subsystem"). It has
been stalled for four days while master moved a long way underneath it. Before you write
any code, you must reconcile it with master — and part of that reconciliation is a design
decision, not a merge.

Read this whole brief first. Then read
`.aid/works/work-003-review-subsystem-redesign/STATE.md` on the branch, which records the
work's own decisions and the evidence behind them.

---

## 1. What happened while the branch sat still

`work-003` last moved at `f3e0593e5`. Since it diverged, **251 commits** landed on master
across seven merged pull requests:

| PR | What it landed |
|---|---|
| #188 | KB `INDEX` routing-table columns reordered; `Extension` folded into `Primary` |
| #189 | two flat-layout defects in the execute state helpers; `work-010` pruned |
| #190 | **work-004 — declared review criteria.** Read this one closely; see §3 |
| #192 | work-009 — crash-lost artifacts restored; **`STATE.md` → `STATE.yml`** |
| #193 | the `aid-graph` skill removed entirely |
| #184 | work-006 — the design-phase skill family; skills went **76 → 111** |
| #195 | the work id dropped from `knowledge/STATE.md` |
| #194 | **work-012 — review-loop cost.** The largest collision; see §2 |

Re-derive that list yourself before trusting it:

```bash
git log --oneline --merges $(git merge-base origin/master origin/work-003)..origin/master
```

---

## 2. What work-012 put on master, and why it collides with you

work-012 changed **the same review subsystem you are rebuilding**, from a different angle:
it attacked the *cost* of a review cycle, not its *correctness*. It is merged. It is not
negotiable ground you can quietly overwrite — but where it genuinely conflicts with your
design, say so and raise it, rather than deleting it silently.

### 2a. Scoped review cycles

The old rule made every cycle re-read the whole artifact. The new rule splits cycle 2+
into two sets:

- **VERIFY** — the existing ledger, checked **in full**, every cycle. Unchanged in scope.
- **HUNT** — new findings are sought **only in what the previous FIX changed**, plus
  whatever mechanically cross-references it.

Three guards keep that sound, and all three are load-bearing:

1. the hunt set is widened by **mechanical** cross-reference lookup, never by model
   judgment;
2. the cross-document contradiction pass still runs, but **once per phase** — on cycle 1
   of any review whose `ARTIFACTS` span more than one artifact — not once per cycle per
   feature;
3. the existing `Recurred` status plus **one final full pass before approval** catch what
   scoping missed.

### 2b. Criterion oracles

A `review-criteria:` entry may now carry an **optional** `oracle:` key naming an
executable check. A criterion with an oracle is re-decided by *running* it, not by
re-reading. Absence of the key is not a defect. The verdict is **per file**
(`VIOLATION` / `UNDECIDED`), so an oracle that cannot decide a file says so instead of
guessing. One oracle ships: `scripts/checks/g07-selector-partition.sh`.

### 2c. A measurement instrument you should use

`tests/review-cost-meter.sh` is on master. It has `record` and `report` subcommands and
measures the **declared read surface** — the bytes of every artifact named in a dispatch
brief. It is how work-012 proved its own premise. You will need it; see §5.

### 2d. The measured results, so you know the bar

| Claim | Figure |
|---|---|
| Read-surface reduction at cycle 2 | **61.5%** mean (control 1.000, treatment 0.385, three paired subjects) |
| Files the one oracle decides | 241 of 317 (76%); 76 undecided and reported as such |
| Hand re-derivation the oracle removes | ~186 KB per cycle, against one 151-line script |

### 2e. The exact files work-012 touched

```
.aid/knowledge/authoring-conventions.md
canonical/agents/aid-reviewer/AGENT.md
canonical/aid/templates/kb-authoring/frontmatter-schema.md
canonical/aid/templates/reviewer-dispatch.md
canonical/aid/templates/reviewer-ledger-schema.md
canonical/skills/{aid-define,aid-detail,aid-discover,aid-execute,aid-plan,aid-specify}/references/reviewer-brief.md
canonical/skills/aid-define/references/state-cross-reference.md
canonical/skills/aid-detail/references/review.md
canonical/skills/aid-plan/references/review-deliverables.md
canonical/skills/aid-specify/references/{state-initialize.md,state-review.md}
scripts/checks/g07-selector-partition.sh
tests/review-cost-meter.sh
tests/canonical/test-{criterion-oracles,review-cost-meter,scoped-review-cycles}.sh
```

Compare that list against your own branch's canonical footprint. The overlap is close to
total on the review files.

---

## 3. Six premises of `work-003` that are now false

Each was verified against the two branches. Re-verify before acting.

| # | The branch assumes | What is actually true |
|---|---|---|
| 1 | "master is an ancestor, so it merges without divergence" (stated in the PR body) | master is **251 commits ahead**; a test merge produced **196 conflicting files** |
| 2 | `work-003` owns *how a reviewer knows what to judge by* | work-004 landed the **declared `review-criteria:` cascade** — a rival mechanism for the same job. `authoring-conventions.md` went from 0 to 10 mentions of it |
| 3 | `reviewer-dispatch.md` can be gutted (45 added, 292 removed) and replaced by `reviewer-brief-template.md` | work-012 **extended** that same file (86 added, 1 removed). Deleting it drops the scoped-cycle mechanism silently |
| 4 | it may rewrite the cycle N≥2 rule in `reviewer-ledger-schema.md` | work-012 rewrote **that same rule**, for a different purpose |
| 5 | state lives in `work-state-template.md` / `delivery-state-template.md` | both renamed to `.yml` by work-009. **The files the branch edits no longer exist** |
| 6 | its skill-count guards hold | `test-skill-counts.sh` and `check-skill-counts.mjs` are **deleted on master**; skills went 76 → 111 |

Commands that produced those:

```bash
git log --oneline origin/master..origin/work-003 | wc -l   # 124
git log --oneline origin/work-003..origin/master | wc -l   # 251
git show origin/master:.aid/knowledge/authoring-conventions.md | grep -c review-criteria
git ls-tree origin/master --name-only canonical/aid/templates/ | grep -i state
git ls-tree origin/master --name-only canonical/skills/ | wc -l
```

### And one new constraint that did not exist when the branch started

**NFR-2 now counts executable surface only.** Authored instruction is free; a script is
not. `work-003` adds **seven** new scripts (`check-gaps.sh`, `gap-register.sh`,
`plan-resume.sh`, `writeback-ledger.sh`, `lint-modality.sh`, `lint-settings.sh`,
`emit-summary-findings.sh`). Each must now justify itself by
**replacing recurring human re-derivation, measured** — that is the bar work-012 set and
met, and `review-cost-meter.sh` exists to measure it with.

---

## 4. Two things you must **decide**, not merge

A three-way merge cannot resolve either of these. Bring both to the owner with a
recommendation before you write the reconciliation.

**Decision 1 — two mechanisms, one job.** work-004's declared `review-criteria:` cascade
and `work-003`'s rubric catalog (`canonical/aid/templates/review-rubrics/`, 10 files) both
answer *"what does the reviewer judge this artifact by?"* Shipping both means two rival
sources of truth. The options are roughly: fold the catalog's content into the criteria
cascade; keep the catalog and demote the cascade; or define a strict precedence between
them. This is the sharpest item in the whole reconciliation.

**Decision 2 — the dispatch protocol.** `work-003` deletes most of `reviewer-dispatch.md`
in favour of `reviewer-brief-template.md`; work-012 extended it with the VERIFY/HUNT split
and the mandate to render each brief to a file and call `record` in the same step. A
replacement template must carry both, or the deletion is a silent regression of a measured
improvement.

---

## 5. What to do, in order

1. **Merge master into the branch and resolve by category.** The conflict count was 196
   *before* work-012 merged and will be higher now — re-measure it yourself. Resolve by
   category, not file by file:
   - `profiles/`, `.claude/`, `.cursor/` (was 136 files) — **never hand-merge.** These
     are generated. Take either side and regenerate with the profile generator.
   - `.aid/works/**` — transient per-work state; keep your own branch's.
   - `canonical/` and `tests/` (was 21 files) — **this is the real work.** Every one is a
     review-subsystem file that both sides edited.
   - `site/`, `docs/` and `README.md` (was 31 files) — follow whatever the canonical
     resolution decided.

2. **Take Decisions 1 and 2 to the owner** before writing the reconciliation.

3. **Re-measure every inventory the branch records.** `delivery-028`'s BLUEPRINT counts
   ("10 canonical files, 48 `Step 2` cells, 2 test suites") were measured four days ago
   against a branch that has since moved and is about to move again. Re-run the measuring
   commands the BLUEPRINT names and update the numbers before you plan against them.

4. **Know that the headline change is still unimplemented.** The PR announces "severity
   becomes judgment", but the retired model is still shipped on the branch — all 10 rubric
   files still carry `Severity` cells, and 9 still carry the two-step lookup. Verify:
   ```bash
   grep -c Severity canonical/aid/templates/review-rubrics/*.md
   ```

5. **Re-baseline the 13 unexecuted deliveries against master.** Some of what they specify
   may now be done, obsolete, or in conflict. Report which, with evidence, rather than
   executing them as written.

6. **Take the clean-context measurement the PR admits it never took.** The PR states the
   reviewer found the previous cycle's ledger despite being passed one scratch path,
   because every cycle sits in one directory under a name differing by one digit, and that
   a reviewer holding last cycle's findings is answering a cheaper question. Clean context
   must be **structural**, not instructional. That measurement is still outstanding.

---

## 6. Constraints that bind you

- **Never hand-edit `profiles/`, `.claude/`, or `.cursor/`.** Regenerate them.
- **Tracking discipline is not optional.** Every state change — task, delivery, phase,
  grade — is written to the work's `STATE.yml` *at the moment it changes*. A task that
  sits at `Pending` through its whole execution and then jumps to `Done` is the exact
  failure this rule exists to prevent. Note the format is now `.yml`, not `.md`.
- **Never name a work inside `.aid/knowledge/`.** No `work-003`, no work-folder path, in
  prose, tables, headings or frontmatter. Cite the durable artifact instead.
- **Measure, do not assert.** Any claim that the redesign improves something needs a
  number and the command that produced it. This is now the house standard, and
  `review-cost-meter.sh` is on disk for exactly this.
- **Do not change** the grading scale, the ledger's 7-column shape, or `grade.sh`'s
  positional parse.

---

## 7. What to report back

1. The re-measured conflict count, by category.
2. Your recommendation on Decisions 1 and 2, with the trade-off for each.
3. The re-measured `delivery-028` inventory.
4. Which of the 13 unexecuted deliveries are still valid, which are obsolete, and which
   now conflict — with evidence per item.
5. A revised estimate of remaining scope, expressed as which subsystems must change and
   how invasive the edits are. Not in days.
