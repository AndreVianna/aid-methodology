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

### The verdict

**Against the 462 lines actually removed: 519 added — a fail on the strict count.**
**Against the 379-line floor AC-4 names as "the figure the criterion is tested against": a fail
under every reading below.**

Two reclassifications are arguable. Both are shown at **gross** additions, the same basis as the
519, because mixing net and gross is how an arithmetic like this quietly misleads:

| Reading | Added mechanism | vs 462 removed | vs the 379 floor |
|---|---|---|---|
| Strict — everything above counts | 519 | **fail** by 57 | **fail** by 140 |
| − `frontmatter-schema.md`'s field definition (gross 88) | 431 | **pass** by 31 | **fail** by 52 |
| − also `aid-clerk`'s relocated Caller Contract (gross 15) | 416 | **pass** by 46 | **fail** by 37 |

The two candidates, so the owner can judge them rather than take my word:

- **`frontmatter-schema.md`'s field definition (88).** It defines a data *format*. That is not a
  script, a check, a validator, or a rule an agent must follow — and NFR-2 already excludes an
  authored `review-criteria:` block, of which this is the schema one level up. The counter-argument
  is that it does contain obligations (which keys are required), so a reader could call it a rule.
- **`aid-clerk`'s Caller Contract (15).** Relocated verbatim out of a README whose lines are already
  inside the 1,802 removed. Counting it as *added* counts one move twice.

**So the verdict turns entirely on which number AC-4 is tested against**, and AC-4 answers that
itself: *379*. On its own stated basis the criterion **fails**, by between 37 and 140 lines
depending on classification. It passes only if the comparison is re-based on the 462 actually
removed **and** the schema definition is granted as non-mechanism.

**What this means, plainly.** No script, gate, or validator was added — C-1 held, `grade.sh` is
untouched, and the reviewer independently confirmed every changed script is a modification of an
existing file. So the *machinery* did not grow. What grew is instruction: roughly the same volume of
process rules as the guard lines removed. The enforcement surface **moved** rather than shrank —
from one script checking a fixed claim list mechanically, to declarations a reviewer resolves across
four trees. task-017's proof shows those declarations catch strictly more than the guard did, so the
trade bought coverage; AC-4 measures lines, not coverage, and by its own stated basis it fails.

**This is an owner decision, not the gate's and not the executor's**: accept the criterion as failed
and record why; re-base it on the 462 actually removed; or revise NFR-2 to count mechanism as
executable surface only, which is the distinction the evidence actually supports. All three are
defensible. Picking the one that passes, without saying so, is exactly what an anti-gaming criterion
exists to prevent — which is why all three are on the table here instead of one.

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
