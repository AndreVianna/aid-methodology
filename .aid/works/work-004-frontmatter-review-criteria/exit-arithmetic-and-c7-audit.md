# Close-out: the exit arithmetic (AC-4) and the C-7 audit (AC-6)

Two independent verifications, both produced once at the end, against the repository **after** the
single render. Their verdicts are separate: one passes, one does not.

---

## AC-4 — the exit arithmetic: **DOES NOT PASS**

**AC-4 asks one question: do removed guard lines exceed added mechanism lines?** It fixes the
figure it is tested against — *"Guard-line floor: 379 (`check-skill-counts.mjs`), and that is the
figure the criterion is tested against"* — and forbids merging the deleted documentation into it.

### The removed side

| What | Lines | Note |
|---|---|---|
| `tests/canonical/check-skill-counts.mjs` | 379 | the floor AC-4 names |
| `tests/canonical/test-skill-counts.sh` | 83 | its wrapper; guard infrastructure, removed with it |
| **Removed guard lines** | **462** | measured: `git diff --numstat <merge-base>..HEAD` on both paths |
| *Removed documentation lines* | *1,802* | *the 20 READMEs — reported **separately**, never summed into the figure above. NFR-2 forbids the merge because merged, deleted prose pays for added machinery and the criterion stops measuring what it exists to measure.* |

### The added side

NFR-2 defines added mechanism as *"new scripts, checks, validators, or process rules an agent must
follow"*, and excludes one thing explicitly: *"An authored `review-criteria:` block is not
mechanism."*

**No script, check, or validator was added — C-1 held, and every gate confirmed it.** The entire
added side is the third category: process rules.

Measured on the non-rendered instruction sources (`canonical/**` plus the five hand-authored
`profiles/<tool>/{CLAUDE,AGENTS}.md`; renders, the work folder, the KB, tests and docs excluded):

| Step | Lines |
|---|---|
| Gross added | 671 |
| − authored `review-criteria:` blocks (NFR-2 excludes them) | −107 |
| − emitter payload blocks (a generated doc's own declaration, not a rule) | −45 |
| **= added mechanism, strict count** | **519** |

### The verdict: PASSES under NFR-2 as revised by the owner on 2026-08-14

**Two answers, because the criterion changed after being measured. Both are recorded, because the
first one is what forced the second.**

| Basis | Added mechanism | vs 462 removed | vs the 379 floor |
|---|---|---|---|
| **NFR-2 as revised** — executable surface only | **0** | **pass** | **pass** |
| NFR-2 as originally worded — authored instruction counted too | 519 | fail by 57 | fail by 140 |

Under the revision the added side is **zero**: no script, check, validator, gate or CI step was added
anywhere in the work, `grade.sh` is untouched, and every gate confirmed C-1 held. Against 462 guard
lines removed, or against the 379 the criterion names, AC-4 passes.

### Why the criterion was revised rather than the number massaged

The original wording ended *"or process rules an agent must follow"*, which counted every line of
instruction this work wrote. Measured that way it failed, 462 against 519 — and that failure was
reported first, before any revision was proposed, because a criterion that exists to prevent gaming
should not be quietly re-read by the party it constrains.

The owner then tested the criterion itself, on four grounds:

1. **The retired guard's defect class is the least severe in this project's own table.** A cosmetic
   count is `G-01` = MINOR — *"the reader can run `wc -l`"*. Nothing dispatches on a skill count. 379
   lines of CI automation stood against the lowest-stakes class there is.
2. **Its determinism was a function of its narrowness, not something the trade gave up.** The guard
   was deterministic *because* it checked a hardcoded claim list. Determinism is not available over
   "any claim any document makes about itself", so that axis does not exist at the new scope — and
   presenting it as a loss, which an earlier draft of this document did, was a false comparison.
3. **Per-push automation was the wrong cadence.** A count that drifts between two pushes harms nobody
   between them. "Is our prose still accurate" belongs to a review or a housekeep pass.
4. **The corpora the criteria are blind to are correctly out of scope.** The criteria govern artifacts
   an agent reads *as instructions*. A maintainer-only tool's comment and a script's prose are not
   that, and a script that genuinely depends on a count derives it rather than stating it.

**The deciding argument: the guard encouraged the defect it caught.** Its existence made stating a
drift-prone count feel safe. `G-01` says do not state it — and stream 3 duly *deleted* the counts from
`module-map.md` and `test-landscape.md` rather than guarding them. No number, nothing to drift,
nothing to guard. The guard treated the symptom; the declaration treats the cause. Counting the
guard's removal as a debt to repay penalises the correct decision twice — once for deleting it, again
for writing what made it unnecessary.

### What this document does NOT claim

That the enforcement surface shrank in total. **It did not — it moved**, and the parts of that move
that are losses are recorded here rather than buried:

- **From automatic to on-demand.** The retired guard ran in CI on every push
  (`.github/workflows/test.yml` → `tests/run-all.sh`). The declarations run when a review runs.
- **From deterministic to judgment-applied,** with measured variance: one defect class in
  delivery-002 took **three gate cycles** to close, because two sweeps missed instances a third
  found. A script does not do that.
- **Two corpora lost automatic coverage entirely** — the repo-local maintainer skills, and
  non-markdown files. Judged correctly out of scope above, but the coverage is gone, not replaced.

Against those, what the move bought is broader reach and a different class of catch. task-017 planted
the retired guard's exact defect class and the declarations caught it — plus **four more real drifts
on the same file** that the guard never covered. And the defects that actually mattered in this work
were not countable facts at all: a ledger shape that would make `grade.sh` report `A+` regardless of
findings, a criterion asserting a layout the project forbids, three divergent severity definitions,
and one criterion that was simply false on disk. No count guard could express any of them.

`test-doc-counts.sh` (109 lines) is deliberately **kept**: the public front face is where a wrong
number costs a newcomer's trust, which is worth automating. The repo-wide guard is not.

---

## AC-6 — the C-7 audit: **PASSES**

**AC-6 asks that nothing from `work-003` crossed except through the six C-7 gates, each logged.**

### Provenance: nothing crossed as code

Checked against the branch, not asserted:

| Check | Result |
|---|---|
| `origin/work-003` an ancestor of `work-004`? | **No** — never merged |
| Equivalent-patch commits (`git cherry origin/work-003 HEAD`) | **None** — nothing cherry-picked |
| `work-003`'s exclusive files present here? (`review-rubrics/` catalog, `reviewer-brief-template.md` — the two the import log names) | **Absent** — no file copied |
| Commits on this branch since the merge base | 49, all authored for this work |

The `work-003` mentions that do appear in the branch are in commit messages and requirements prose
explaining what was **not** taken — which is the log doing its job, not a leak.

### The log: three entries, six gates

`imports-from-work-003.md` holds exactly three entries, all three the same kind: measurements *of
another branch*, admitted to serve §8's own collision-surface accounting.

| Gate | Verdict |
|---|---|
| 1 — a statement crosses, never a commit, cherry-pick or file copy | **Pass** — verified above; all three are statements |
| 2 — each entry names the work-004 requirement it serves | **Pass** — all three name §8 |
| 3 — each names where it was re-derived | **Pass** — `git rev-list`/`git diff --name-status`, with the exemption §8 grants itself stated in the row: a measurement of another branch cannot be re-derived from this one |
| 4 — no mechanism crosses | **Pass** — the log says so explicitly, and the two files that would have carried one are absent |
| 5 — nothing is relied on for a design decision | **Pass** — every stream-1 target was re-derived from this branch in §4; the requirements' own change log records the correction pass that removed the artifacts existing only on `work-003` |
| 6 — every admitted fact is logged, one row | **Pass** — three rows, no fourth import anywhere |

**Verdict: AC-6 passes.** The only thing that crossed from `work-003` was knowledge of the
collision surface, logged, serving one section, relied on for nothing.
