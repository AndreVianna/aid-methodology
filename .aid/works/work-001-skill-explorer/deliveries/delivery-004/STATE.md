---
delivery_state: Done
gate_tier: Large
gate_grade: A+
gate_timestamp: "2026-07-29T16:06:54Z"
ticket_ref: "--"
---

# Delivery State -- delivery-004

[!NOTE]
This is the DELIVERY-LEVEL STATE.md. It is divided into three zones:
  FRONTMATTER (single writer = this delivery's branch, machine-parsed scalars) --
      `delivery_state`, `gate_tier`, `gate_grade`, `gate_timestamp`, `ticket_ref`.
  AUTHORED (single writer = this delivery's branch, markdown body) --
      the narrative remainder of Delivery Lifecycle / Gate Block, Cross-phase Q&A.
  DERIVED (read-only, assembled at read time) --
      Tasks State (rollup from per-task STATE.md files in tasks/task-NNN/STATE.md).
Identifiers (`Delivery`/`Work` in the header blockquote below, `Branch`) are INFERRED from
the folder name and git worktree -- never authored in frontmatter.

<!-- DELIVERY LIFECYCLE ENUM (authored, not derived)
  aid-plan       creates this file with State = Pending-Spec
  aid-specify    advances to Specified
  aid-execute    advances Specified -> Executing -> Gated -> Done, or to Blocked
Enum members: Pending-Spec | Specified | Executing | Gated | Done | Blocked
This authored state is NOT a derivation of child task states. A delivery may be Pending-Spec
with ZERO tasks; the `_none yet_` rollup below is correct and expected for a new delivery.
-->

> **Delivery:** delivery-004
> **Work:** work-001-skill-explorer
> **Branch:** aid/work-001-delivery-004

---

## Delivery Lifecycle

<!-- AUTHORED -- single writer: this delivery's branch only. The **State** scalar lives in the
     YAML frontmatter block at the top of this file (`delivery_state`). -->

- **Updated:** 2026-07-26T15:05:55Z
- **Block Reason:** --
- **Block Artifact:** --

---

## Delivery Gate

<!-- AUTHORED -- single writer: the delivery-gate closing step of `aid-execute` on this
     delivery's branch. Reviewer Tier / Grade / Timestamp live in the YAML frontmatter block
     at the top of this file (`gate_tier`, `gate_grade`, `gate_timestamp`). -->

- **Issue List:** round 1 raised 3 (0 Critical, 0 High, 1 Medium, 2 Low), all Fixed — see below.

### Gate round 1 — C+ (below the A+ floor)

**[MEDIUM] The source-file cache was per-call, not per-run.** `verifyProvenance` created a
fresh `Map` on every invocation, which deduplicates reads within one chart but not across the
corpus — and across the corpus is the whole point. Measured before accepting the finding: 64 of
the 111 skills cite `canonical/aid/templates/shortcut-engine.md` and 64 cite
`work-initiation-gate.md`, so each was read 64 times. Corpus cost was 315 reads against 176
with one run-level cache, a 1.79x amplification — precisely the doorway case the SPEC names
when it says "once per run". The task-041 DETAIL is internally inconsistent here: its prose
says "once per run … material when a doorway corpus shares a single engine file", but its own
AC says to assert it "across a chart", which is a per-call claim. The prose and the SPEC agree
with each other, so they win. Fixed by giving the appender a run-level `_runFileCache` beside
its existing `_runMemo` and threading it into every verify call; `_cache` is promoted from a
test-only seam to a documented parameter, and `resetProvenanceMemo()` clears both. Measured
after: 176 reads, 139 avoided, both templates cached once. Pages are byte-unchanged, which
confirms this is purely a cost fix.

The old test was titled "once per run" but exercised a single call, so it could never have
caught this. Retitled to say per-call, and two tests added: one proving a shared cache
collapses three separate calls to one read, and its non-vacuity twin proving the same three
calls read three times without it. A further pair asserts the appender actually threads its
run cache through, rather than letting verify quietly make its own.

**[LOW] P2a asserted no `file#L…`.** The DETAIL requires every throw to name the skill, the
node id **and** the location; P2a checked the first two plus the guard name but omitted the
third, while its sibling P2b included it. Added.

**[LOW] `sourcePath` was destructured and never read.** The DETAIL says the appender uses two
SkillRecord fields, but `buildFlowChart` builds every path it needs from `name` and `dir`, so
`sourcePath` had no work to do; it was destructured — with a comment admitting as much — purely
to satisfy a grep-based AC. That is an AC testing a spelling rather than a behaviour. Removed,
and the test inverted to assert `sourcePath` is *not* destructured. The constraint the AC
actually protects — that `bodyStartLine` and `lineCount` are never consulted, because a node
may cite a worker file or the shared engine template rather than this skill's own `SKILL.md` —
is unaffected and still asserted.

**Delta recorded:** the appender reads exactly **one** SkillRecord field, `dirName`, not the
two the DETAIL anticipated.

After the round: 2571 tests across 41 files, build clean at 142 pages, regeneration idempotent,
and no mutation artifacts anywhere under `site/scripts/`.

### Gate round 2 — A (still below the A+ floor)

All three round-1 findings confirmed Fixed. The reviewer specifically audited the new
`vi.doMock` cache tests for vacuity and confirmed the mock genuinely intercepts, the
three-call/one-read assertion measures the cache, and the without-cache twin is a real
non-vacuity control. Asked to challenge rather than rubber-stamp the `sourcePath` removal, it
agreed: the AC over-specified a field the appender was never going to use, and the constraint
the AC protects is intact.

Two [MINOR] findings, both introduced by my own round-1 fix commit, both fixed:

1. **A duplicate `REPO_ROOT` declaration.** My commit added `import { REPO_ROOT }` to
   `provenance-appender.test.mjs`, which already declared `const REPO_ROOT` four lines below.
   Worth more than the cosmetic note it was filed as: two declarations of one binding in module
   scope is **not valid ESM**, and it only ran because Vitest's transform renames import
   bindings. The existing `const` already resolves to the repo root, so the import was deleted.
   Confirmed the file now parses outside the runner, and swept `__tests__/`, `lib/provenance/`,
   `lib/flow-graph/` and `skills/` for the same pattern — clean.
2. **A stale comment.** The AC-2 header still said the appender "uses only dirName and
   sourcePath" after `sourcePath` was removed, contradicting the test below it. Reworded, with
   the reason recorded so the next reader does not re-add the field.

### Gate round 2 — A (two MINOR findings, below A+ floor)

Gate re-ran on commit 155d8e08. All three round-1 rows are Fixed. Two new [MINOR] findings raised.

**[MINOR] Dead `REPO_ROOT` import.** Commit 155d8e08 added
`import { REPO_ROOT } from '../skills/paths.mjs'` to `provenance-appender.test.mjs` (L30) while
a `const REPO_ROOT = resolve(__dirname, '../../../')` already existed at L34. The import is
shadowed and never referenced; `REPO_ROOT` at L92 and L112 binds to the `const`. Fix: remove
the import at L30.

**[MINOR] Stale AC-2 comment.** The file-level description at L9 still says the appender "uses
only SkillRecord.dirName and sourcePath". `sourcePath` was removed by this commit; the comment
contradicts the test at L165 (`not.toMatch(/...sourcePath.../)`). Fix: update the comment to
reflect one-field access.

Checks: 2571/2571 tests pass, 142-page build clean, gen-skills idempotent on two runs, git
status clean, zero mutation artifacts.

### Gate round 3 — A+ (clears the A+ floor)

Both round-2 findings confirmed Fixed in commit 80199e1b. All five ledger rows now Fixed.
No new findings. Delivery clears the A+ floor.

Checks: 2571/2571 tests pass, 142-page build clean, gen-skills idempotent on two runs, git
status clean, zero mutation artifacts.

### AC-7 — comprehension spot-check: **PASS**, performed 2026-07-30 (late)

This delivery's BLUEPRINT made recording AC-7 a gate criterion in two places, and the gate
above closed A+ without it. Neither the criterion's checkbox nor any verdict was ever filled in;
a grep for `AC-7` across every delivery STATE.md found only unrelated hits. The work-level final
gate found that and performed the check. Recorded here, at the criterion's own delivery, rather
than only at the gate that noticed.

**AC-7 as specified** (`REQUIREMENTS.md`:383-386): *"A reader unfamiliar with a given skill can
state its step order and exit points correctly from the chart alone. **Non-blocking** — a
judgement check, not a CI gate — but recorded because it is the only criterion that tests the
stated outcome directly."*

**Method — and why it was not run by the executing agent.** "Unfamiliar" is the load-bearing
word, and by this point in the work no agent that had touched the corpus could satisfy it. The
check was given to a **clean-context reader** with the rendered `aid-review` chart pasted into
its prompt and an explicit prohibition on opening any file. It used **zero tools**, so the
answers are from the diagram alone. `aid-review` was chosen because it is the hardest inline-state
shape available: 6 nodes, a decision with two labelled branches, and dotted loop-backs.

**Result — the reader's answers against the source (`canonical/skills/aid-review/SKILL.md`):**

| Question | Reader's answer | Source | Verdict |
|---|---|---|---|
| Step order | INTAKE → REVIEW → VERIFY → PRESENT-FINDINGS → PUBLISH → DONE, noting PUBLISH is conditional | `:32` state machine + the five `**Advance:**` lines | **Correct** |
| Exit points | DONE only, reached from both branches | `:203` `## State: DONE`, the only exit | **Correct** |
| The decision | "on approval" → PUBLISH; "otherwise" → DONE | `:184` "**Advance:** PUBLISH on approval; otherwise DONE" | **Correct** |

Both criteria AC-7 actually names — **step order and exit points** — were stated correctly from
the chart alone, unprompted, by a reader that had never seen the skill. **AC-7 passes.**

**But the spot-check earned its keep by finding something no other criterion did.** Asked which
steps loop back, the reader answered **three** — REVIEW→INTAKE, VERIFY→REVIEW,
PUBLISH→PRESENT-FINDINGS — reading the chart faithfully. The source expresses **one**. The
sidecar's own provenance is the evidence:

| Edge | Source line | Real control flow? |
|---|---|---|
| `VERIFY -.-> REVIEW` | `:159` "If it is not clean, **loop back to REVIEW** so the first reviewer revises" | **Yes** |
| `REVIEW -.-> INTAKE` | `:132` "(model+effort **from INTAKE** Step 4)" | **No** — a prose parenthetical |
| `PUBLISH -.-> PRESENT-FINDINGS` | `:193` "**PRESENT-FINDINGS** is what authorizes this call" | **No** — a prose cross-reference |

Cause is `_scanBodyEdges`'s **rule 7** in `site/scripts/lib/flow-graph/extract-inline.mjs`:212,
which by documented design emits a `loop-back` edge for *any* non-heading, non-fenced line
mentioning an earlier-ordered state. It cannot distinguish "loop back to REVIEW" from "from
INTAKE Step 4". Filed as **W1-16**; it is **not** fixed here, because tightening rule 7 changes
generated output for the whole corpus and this delivery's successors assert those pages
byte-unchanged. Escalated to the owner rather than downgraded.

**Extent — stated honestly.** Verified by reading the source end to end for **one** skill. The
mechanism is general, so the class is not specific to `aid-review`. A proxy scan (loop-back edges
whose provenance line lacks loop language) flags ~30 edges across 24 distinct charts, but that proxy is
**unreliable** — several flagged rows are wrapped-line tails whose full sentence does express a
loop — so it is an unverified upper bound, not a defect count. 70 of the 100 loop-back edges in
the corpus trace to lines that do use loop language, and the large doorway majority inherits one
genuine "Loop back" line from `shortcut-engine.md`:804.

**This also answers feature-005's OQ-2** ("Who performs AC-7, and when"), open until now: a
clean-context reader agent, given only the rendered chart and barred from reading the repo, at the
delivery gate that owns the criterion. That is repeatable, which is what the deferred item
"AC-7 formalized into a repeatable review step" (PLAN.md § Deferred) asked for.

---

## Cross-phase Q&A

<!-- AUTHORED -- single writer: this delivery's branch (via the delivery-gate step of aid-execute).
     The work-level ## Cross-phase Q&A is a DERIVED union of all delivery Q&A sections plus any
     work-owner-authored work-level entries. -->

### Q1 — task-043's "exactly four lines of stdout" AC is stale

- **Category:** Requirements (AC-vs-reality conflict)
- **Impact:** Medium
- **State:** Answered
- **Context:** task-043 AC reads "stdout remains **exactly four lines** per successful run".
  That was true when feature-001 fixed the contract, but task-029 (delivery-003) added a
  run-level flow-warning summary line plus one detail line per warning. Measured now:
  `node scripts/gen-skills.mjs` emits **14** stdout lines — the 4 fixed lines, 1 summary
  line, and 9 warning detail lines — with stderr silent and exit 0. Taken literally the AC
  is unsatisfiable without deleting a feature delivery-003 shipped.
- **Answer:** Apply the precedent the owner already set for the identical conflict in
  task-030: the warning report **stays**, and the four-line clause is re-scoped to mean
  *stdout is not widened by this task* — the appender itself logs nothing, the four fixed
  lines remain exactly four, and stderr stays silent on success. This is not a new owner
  decision; it is the task-030 ruling applied to a second instance of the same conflict.
- **Applied to:** task-043 acceptance interpretation; recorded here rather than editing the
  immutable DETAIL.

---

## Task Review Findings

<!-- AUTHORED -- per-task review outcomes recorded as each task closes. -->

### task-040 — `canonical/` deep-link builder

Module is clean: `GITHUB_BLOB_BASE` imported read-only from `paths.mjs` and never
redeclared, no `encodeURI`/`encodeURIComponent`, no `path.join`, no import-time side
effect. Three test weaknesses found and fixed during review:

1. One assertion compared `blobUrl`'s output to `GITHUB_BLOB_BASE + '/' + file + lineAnchor(...)`
   — a re-computation of the implementation from the same two functions under test, so a
   consistent mutation of both would have left it green. Replaced with a literal expected
   string, which also makes it a genuine third data point rather than a restatement.
2. Two of the three guard-message assertions matched only the echoed input path
   (`/path\/with space/`, `/\.\./`). The input is echoed by **all three** messages, so
   neither assertion could tell which guard had fired. Retargeted at wording unique to each
   guard.

Mutation-proved after the fix: rewording each of the three throw messages is now killed by
its own test and no other (M6, M7, M8 — executed, all killed). The developer's own five
mutants (M1–M5, on the anchor condition, the `-L` separator and each of the three guard
predicates) were also confirmed killed.

**Outcome:** Pass.

### task-041 — Provenance verifier (P0–P6)

Module is sound. `chart.skill` was checked against `model.mjs` and is a real `FlowChart`
field, so messages name the skill rather than `undefined`. P1 correctly runs *before* P0 —
P0 must read the file, which requires it to exist — and the developer documented that
ordering rather than leaving it to be rediscovered. The separability table is genuine: each
P*n* fixture is valid for P0..P*n-1*, and P5 is proven the hard way on a file whose line 2
really is spaces, so P4 passes and only P5 fires.

One coverage gap found and closed:

1. The read-once criterion says each cited file is **read** once per run, but the test
   counted `Map.set` calls. Those are different claims — a `readCached` that called
   `readFileSync` *before* consulting the cache would still store exactly one entry while
   reading the file six times (two nodes × P0/P3/P4), leaving the counter green. Added a
   test that counts `readFileSync` itself via a `vi.doMock` passthrough on `node:fs`.

Mutation-proved by hand-applying that exact defect (reorder `readCached` so the read
precedes the cache check): the new test fails, and **the original `Map.set` counter passes**
— confirming the gap was real and is now covered. The developer's own nine mutants (P0
CRLF token, P1 canonical prefix and `..` segment, P2 lower bound, P3 comparison operator,
P4 and P5 predicate polarity, cache-hit skip, and dropping P3 from the detail path) were
reported killed.

**Outcome:** Pass, with the read-once assertion strengthened.

### task-043 — `## Source fragments` appender registration

The headline result is genuine and worth stating plainly: **`verifyProvenance` passed over the
whole corpus on its first run.** Every node of all 111 charts has an `excerpt` byte-identical
to its cited `canonical/` slice, with P0 and P5 clean. `body.mjs` changed by exactly the two
lines specified — one import, `BODY_APPENDERS = [provenanceAppender]` — and stdout stayed at
14 lines with stderr silent, so the appender widened nothing (see Q1).

Three findings, all resolved.

**F-1 (serious, process). An un-restored mutation artifact shipped into a production module.**
`index.mjs` line 107 read `memo.get("__MUTANT__")` — the developer applied its own M1
memoization mutant, observed the kill, and never restored the file. Memoization was therefore
dead: `buildFlowChart` ran on every `render()` call rather than once per directory, and the
pages were generated in that state. The failure was reported as a *passing* mutation kill,
which is why re-verification caught it and the report did not. Restored to `memo.get(dirName)`;
AC-3 now holds and the suite is green at 2531 across 40 files. Swept the whole of
`site/scripts/` for other artifacts — none.

**F-2 (quality). The duplicate-label redundancy from delivery-003 had reappeared here.**
223 of 883 lead-in lines across 98 of the 111 skills rendered as
`**3 · \`CONTINUATION\`** — CONTINUATION`, saying the same word twice — the same defect the
owner objected to as `INTAKE<br/>INTAKE` at the delivery-003 UI checkpoint. Applied the rule
already established in `render-mermaid.mjs`'s `nodeLabel`, including its case-insensitive
comparison: an exact comparison would have left `ENTRY — Entry` and `EXIT — Exit` in place,
16 of the 223. Corpus duplication now measures 0. Mutation-proved with four mutants — removing
the collapse, inverting it, weakening the comparison to case-sensitive, and weakening it to a
substring test. The case-sensitive weakening is killed by **exactly one** test, the dedicated
different-case case, so that arm is provably load-bearing; the substring weakening is killed by
the non-vacuity case that keeps a label merely *containing* the name.

**F-3 (DETAIL/SPEC factual defect, no code change). The stated rationale for `title=` does not
reproduce.** Both task-042 and task-044 assert that omitting `title=` lets Expressive Code's
frames plugin delete a heading line from "four known corpus lines". Tested by A/B build with a
detector that finds at-risk fragments *without* keying off `title=` (the first version of that
detector did key off it, and so reported a vacuous pass — noted because it is the same error
class this delivery keeps finding): 236 fragments begin with `#`, and **zero were deleted in
either build**. Cause: `getFileNameFromComment` resolves a `LanguageGroup` for the block's
language, and `plaintext` is a member of no group, so extraction bails before it can match.
The language choice alone already disarms the scan. `title=` is **kept** regardless — the SPEC
mandates it as the visible provenance caption — but its justification is now recorded as
unverified, and task-044's assertion stands on the SPEC requirement rather than on the
four-line claim.

Verified beyond the ACs: regeneration is idempotent (second run byte-identical), the real
Astro build completes at 142 pages, and all 236 at-risk heading lines survive into the built
HTML — which is the actual claim the unit-test `title=` assertion can only proxy.

**Outcome:** Pass after rework.

### task-044 — `provenance.test.mjs`, the AC-5 suite

Delivered 34 tests in six groups. Spot-checked the criteria most often satisfied only in name,
and these hold: the P4 message asserts `first-differing-line=`, every verifier throw asserts
the guard name **and** `skill=` **and** `node=` rather than a bare `.toThrow()`, the sweep
enumerates from disk with a `> 50` non-vacuity floor instead of a literal count, `detail` is
never excerpt-compared, and the no-JS group asserts `[Source: ` count as an **equality** with
`chart.nodes.length`. The sweep walked 111 directories and 912 nodes.

One AC half was missing. The determinism criterion has two: `renderFragmentList` twice on the
same chart, **and** "two `gen:skills` runs leave the fragment section byte-identical". Only the
first was covered. Added a whole-corpus test for the second that compares each page's on-disk
section against a freshly rendered one — the on-disk section *is* the previous run's output, so
any nondeterminism surfaces there. Spawning the generator inside the suite was rejected: it
would rewrite 111 tracked files as a side effect of running tests.

Mutation-proved by changing one word inside one page's section: only the new test fails, and
the page was confirmed byte-restored afterwards.

Also confirmed clean on the failure mode that bit task-043: `git status` shows only the new
test file, and `grep MUTANT` across `site/scripts/` finds nothing.

Full suite: 2567 tests across 41 files.

**Outcome:** Pass, with the second determinism half added.

### task-042 — Fragment-list renderer

Two classes of problem found, both fixed on a resumed dispatch to the same developer.

**1. The rendered format diverged from feature-005's SPEC on seven points.** The SPEC
carries a worked example under § UI Specs → "Entry anatomy" that is authoritative, and
neither the DETAIL's prose nor the first implementation was reconciled against it. The
serious one: the link line rendered as `[<file><anchor>](<url>)` with no `Source: ` prefix,
which would have made **task-044 unimplementable** — it asserts exactly one `[Source: …]`
link per entry and counts them to prove the no-JS invariant, and that count would have been
zero. The other six: the intro sentence was paraphrased rather than the SPEC's fixed wording;
the detail link sat on its own line instead of joining the source link with ` · `; both link
paths lacked their code spans; the lead-in used `**3.** \`NAME\`` instead of one bold span
`**3 · \`NAME\`**`; `kind` was not italicised; the position came from the loop index rather
than `node.order`; and the documented backtick-in-name fallback to escaped plain text was
missing entirely.

Verified after the fix by rendering the SPEC's own example node and diffing against the
SPEC's literal markdown block: **byte-identical across all seven lines.** Using the loop
index deserves the same objection as re-sorting — it is a second ordering authority that
agrees with `node.order` only because feature-003 guarantees contiguous ordering.

**2. Two reported mutation kills were coincidental.** M6 (`terminal !== null` inverted) was
reported killed by *"multi-node: ALL fences carry title="*, and M8 (`detail !== null`
inverted) by *"fragment with no tildes uses the floor of 4"*. A fence-width test is not
evidence that the `detail` condition is correct; both were collateral damage from a null
dereference, and the behaviours themselves were unproven. Both are if-and-only-ifs, so each
now has two fixtures differing *only* in the field under test. Re-ran both mutants: the
dedicated proofs are now among the killers, and the "IS present" direction fails
behaviourally rather than by crashing.

Full suite after the change: 2501 tests across 39 files, green.

**Outcome:** Pass after rework.

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     The Tasks State section below is assembled at READ TIME from per-task STATE.md files
     (tasks/task-NNN/STATE.md within this delivery folder). NEVER written directly.
     ============================================================ -->

## Tasks State

<!-- DERIVED -- read-only rollup assembled from tasks/task-NNN/STATE.md mutable cells.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |
