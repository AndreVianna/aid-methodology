---
delivery_state: Gated
gate_tier: Large
gate_grade: D+
gate_timestamp: '2026-07-30T23:34:34Z'
ticket_ref: "--"
---

# Delivery State -- delivery-015

<!-- ZONES
  FRONTMATTER (single writer = this delivery's branch): delivery_state, gate_tier,
      gate_grade, gate_timestamp, ticket_ref.
  AUTHORED (single writer = this delivery's branch): the narrative remainder of
      Delivery Lifecycle / Delivery Gate, and Cross-phase Q&A.
  DERIVED (read-only, assembled at read time): Tasks State.
  Identifiers (Delivery / Work / Branch) are INFERRED from the folder name and git
  worktree -- never authored in frontmatter.

  Lifecycle enum: Pending-Spec | Specified | Executing | Gated | Done | Blocked
  Authored independently across the pipeline, NOT derived from task rollup:
    aid-plan    creates this file at Pending-Spec
    aid-specify advances to Specified
    aid-execute advances Specified -> Executing -> Gated -> Done, or to Blocked
-->

> **Delivery:** delivery-015
> **Work:** work-003-review-subsystem-redesign
> **Branch:** aid/work-003-delivery-015

---

## Delivery Lifecycle

<!-- AUTHORED -- single writer: this delivery's branch. The State scalar lives in the
     frontmatter above (delivery_state). -->

- **Updated:** 2026-07-30T19:31:56Z
- **Block Reason:** --
- **Block Artifact:** --

---

## Delivery Gate

- **Complexity Score:** 18 (tasks=6, depth=3, risk=9, consults=0) -> Large tier
- **Cycles:** 11. Grades D- -> D -> D -> D -> D+ -> D -> D+ -> D -> D -> D -> D+; findings 13 -> 15 -> 8 -> 11 -> 6 -> 7 -> 9 -> 8 -> 8 -> 14 -> 14 (**113** total). The recorded Grade is cycle 11's, the last one actually measured. Cycles 10 and 11 found MORE than cycle 9, not fewer: the bar change did not change what a reviewer looks for, and four of those 28 findings were **guards that could not fail** -- a class no amount of prose review surfaces, and the class that had been letting the prose defects through.
- **Minimum grade:** `B-` — **changed from `A+` at cycle 10** (human decision, 2026-07-30;
  `.aid/settings.yml`). `B-` is the lowest bar whose whole band excludes `[MEDIUM]`, so the exit
  criterion is now *zero `[MEDIUM]`/`[HIGH]`/`[CRITICAL]`*, with `[LOW]`/`[MINOR]` **deferred, not
  waived** — they accumulate in the work `STATE.md § Deferred Findings` and are swept in one pass
  before the work ships. Measurement and reasoning: that section. Set globally rather than per-skill
  for the reason in work `STATE.md § Q19`.
- **Issue List:** 112 of the 113 findings across eleven cycles are FIXED and self-verified; the 113th
  is one `[LOW]` deferred under the `B-` bar (work `STATE.md § Deferred Findings`). Cycles 1-9 ran
  against the `A+` bar and never cleared it; § Cross-phase Q&A, 'Why six cycles did not reach A+'
  (written at cycle 6, and the diagnosis held through cycle 9) and § 'Method change at cycle 9'.
- **Cycle 10 (graded 2026-07-30, tree `86eb7584`):** **D** — 3 `[HIGH]` + 11 `[MEDIUM]` + 0 `[LOW]` + 0 `[MINOR]`, so **nothing defers** and all 14 must be fixed to clear `B-`. Ledger: `.aid/.temp/review-pending/execute-delivery-015-cycle10.md`. Two of the 14 are guard gaps the reviewer proved by mutation, not by reading: appending a live two-grade instruction to `aid-summarize/SKILL.md`'s body left the suite 57/57 green (row 5 — `TG01` excludes three files whole), and flipping `SEV_FOR[L1]` to `[HIGH]` plus `SUMMARY-01` to `[CRITICAL]` also left it green (row 6 — the emitter is not in `SEV01`'s feed). Row 1 is a regression cycle 9's own guard rewrite introduced: per-instance detail lines from `validate-html-output.sh` are unclaimed by any rule, so an ordinary broken anchor now exits 2 (pause) instead of 1 (gradeable).
- **Cycle 10 FIX (2026-07-30):** all 14 fixed and self-verified. The two guard gaps are closed with
  guards, not with prose: `TG01` now sweeps **per line** with a seven-entry retirement-prose allowance
  instead of excluding five files whole (plus `TG04`, which fails when an allowance stops matching, so
  the list cannot rot into a whole-file pass), and `SEV04` compares the **emitter's** twelve severity
  tokens against the catalog — the surface where the value actually reaches `grade.sh`, and the one
  `SEV01` never covered. Added `SEV05` (every catalog row's severity must sit in the band its own
  modality selects — the rule that `SUMMARY-08`'s `MUST`/`[LOW]` broke), `EM06` (a check's per-instance
  detail lines are attributed to their check), `CK05` (template and writer agree on the *form* of a
  field, not just its value set) and `CK06` (no ragged row in the Field/Value table). 58 → 64
  assertions, every new one mutation-tested: `SEV05` first failed to fail, because the rationale prose
  I wrote contained the words "Step 2" and the check accepted that as the instance-derived sentinel; it
  now reads the **leading** token only. `CK06` then produced a false positive, because awk's `\\&`
  replacement is a literal `&` that shortened the line and corrupted the second count.
- **Class sweeps done, not just the named instances:** the modality/severity conformance sweep over all
  83 catalog rows found `SUMMARY-08` and nothing else; the grade-coupling sweep found the second
  instance at `aid-discover/references/state-review.md` § *Assertiveness gate PASS conditions* that
  row 8 predicted; the stale-field sweep found the `Header` row
  of `artifact-schemas.md` describing four pre-relocation field names one line above the row the
  reviewer cited; and `TG01`'s widening surfaced a **second grade producer nobody had filed** —
  `aid-discover/SKILL.md`'s "Overall grade = weighted average where architecture, module-map and
  coding-standards count double", an averaging rule against `grade.sh`'s worst-dominates, with weights
  no artifact computed. Removed.
- **Verification:** `test-one-grading-backend.sh` 64/64; `dogfood-byte-identity` 755/755 after render +
  dogfood sync of all 8 edited files across both trees; `ascii-only`, `review-rubrics`,
  `reviewer-conformance`, `criteria-gaps`, `gap-gate-wiring`, `grade-summary`, `guardrails-d012`,
  `writeback-ledger`, `settings-frontmatter-gates` (35/35), `actback-fixtures` (20/20) all green.
- **Cycle 11 (graded 2026-07-30, tree `51d730da`):** **D+** — 1 `[HIGH]` + 12 `[MEDIUM]` + 1 `[LOW]`.
  Ledger: `.aid/.temp/review-pending/execute-delivery-015-cycle11.md`. The `[LOW]` (row 13, lowercase
  globals + a dead `missing_docs` accumulator) is the first row to be **deferred** under the `B-` bar
  rather than fixed; it is copied to work `STATE.md § Deferred Findings`.
  **Two more guards that cannot fail, and one of them is mine from cycle 10:** `SEV05` strips only
  spaces from the Modality cell, so `kb.md`'s `**SHOULD**` matches no `case` branch and the row is
  dropped silently — and `KB-26` is the *only* such row, the one this delivery re-anchored and leaned
  on across five surfaces. Setting it to `[CRITICAL]` left the suite green. `SEV01` extracts the rule
  ID with `grep -oE '[A-Z]{2,12}-[0-9]{2}' | head -1`, which on a ledger example row takes the `#`
  cell: all four `AB-00N` rows extract `AB-00`, both `TB-00N` rows extract `TB-00`, `catalog_sev`
  returns empty and the loop `continue`s — six of eleven example rows are in the feed and never
  compared. Cycle 10's comment claims it fixed exactly this vacuity by dropping the backtick
  requirement; the rows entered the feed, they were just never compared. Both non-vacuity counters
  (`SEV03`, `band_n`) count rows *seen*, not comparisons *performed*, which is why neither noticed.
- **Cycle 11 FIX (2026-07-30):** 13 of 14 fixed; row 13 (`[LOW]`) deferred to the end-of-work sweep,
  which is the first exercise of the `B-` bar's deferral path.
  **The two blind guards, and why neither non-vacuity counter caught them:** both `SEV03` and `band_n`
  counted rows *seen* entering the loop, not comparisons *performed* inside it — so a row that entered
  and was then dropped by a `continue` or an unmatched `case` was indistinguishable from a row that was
  compared. Both now count comparisons (`SEV03` reads 25, where the row-count form read 28 while six
  were being dropped). `SEV01` now takes **every** rule-shaped token on a line rather than `head -1`,
  which had been taking the `#` cell of ledger example rows, and reports a severity-bearing row that
  resolves *no* rule instead of skipping it silently. `SEV05` normalises emphasis out of the Modality
  cell and has a default branch that **fails** on a spelling it cannot read.
  **New guards:** `SEV06` (a severity stated for a lint TAG in prose must match the anchor of the rule
  that tag cites — the class `SEV01` structurally cannot see, since its feed is table rows), `MC11` (a
  **compact** single-line `--input` round-trips exactly, 4 adversarial cases), `MC12` (an unclosed
  string exits 2 and leaves the file untouched), `GR01` (the generated settings reference publishes the
  *resolved* `minimum_grade`). 64 → 68 assertions, all green.
  **`SEV06` earned itself immediately:** the row-7 fix re-anchored the lint-tag table, and `SEV06`
  found a **second** table in the same file — the CALIBRATION definitions at `:75-78` — still stating
  the retired flat `[MEDIUM]`/`[MEDIUM]`/`[HIGH]`. Fixed. That is the class-sweep the finding's Evidence
  called for, caught by a guard rather than by the next reviewer.
  **Two of my own probes were the bug, not the code:** `MC11` first failed on a value the script had
  round-tripped correctly, because python's text-mode `print` turned the note's `\n` into `\r\n` inside
  the probe — it now compares JSON-escaped ASCII forms, which cannot be re-encoded on the way to the
  comparison. And an earlier hand-built fixture used `\ ` (backslash-space), which is not a valid JSON
  escape, so the "corruption" it showed was in the input.
  **Also closed while in the same class:** the four pre-existing bare-line citations
  `kb-citation-lint.sh` reports under `aid-discover/references` — two of which had *already* drifted
  (`lookup_list` is at `:170`, not the cited `:197`). That lint defaults to `.aid/knowledge`, so nothing
  was policing them; it is now clean over that directory.
- **Cycle 12 (graded 2026-07-31, tree `51d730da`+):** **D+** — 1 `[HIGH]` + 7 `[MEDIUM]` + 1 `[LOW]`.
  Ledger: `.aid/.temp/review-pending/execute-delivery-015-cycle12.md`. Read together with the
  delivery-013 and delivery-014 gates that ran the same day, **20 of the 32 findings across the
  three were one shape**: a fact stated in two or more places with one copy updated. Each had been
  *created by the previous fix* — moving `minimum_grade` to `B-` falsified the KB's
  `quality-gates.md`; adding two skills falsified 42 count claims at once.
- **Cycle 12 FIX, part 1 (`d4af0528`, 2026-07-31):** built the generalised cure instead of closing
  the rows one at a time — `derived-values.mjs` (registry) + `check-derived-values.mjs` (engine) +
  `test-derived-values.sh` (11 assertions, 7 mutations).
- **Cycle 12 FIX, part 2 (2026-08-07):** part 1 closed **only a subset**, and the new guard reported
  `all 168 agree` over the instances that survived — three blind spots, each of exactly the shape the
  guard exists to catch:
  `agent-count` required the noun **plural**, so `module-map.md`'s contract could read "9 agent
  directories" untouched; every `minimum_grade` pattern required the word **is**, so
  `summary.minimum_grade: A+` stood CONFIRMED in two KB docs against a `settings.yml` that has never
  held a `summary:` key and *cannot* (S8/Q19); and in `check-skill-counts.mjs` a lookbehind meant to
  exclude `site/scripts/skills/* (12)` also excluded `canonical/skills/* (111)`, `(N total:` had no
  pattern at all, and the first term of every `A + B + C` decomposition fell outside the
  bare-`curated` follow set. **Both guards extended, then the class re-swept:** 7 stale sites, all
  fixed. New assertions, every one mutation-proved: `DV12`–`DV14` (11→14) and `SC02`–`SC05` (1→5,
  the skill-count suite having had **no** mutation control at all — a single green-run assertion that
  could not distinguish "every count agrees" from "no pattern matches").
  **`DV14` guards the guard:** the per-skill-pin pattern compares against the GLOBAL bar, which is
  only correct while no override exists, so `buildRegistry` now THROWS if `settings.yml` ever grows
  one rather than quietly reporting a legitimately-different override as wrong.
  **Two findings collided and had to be sequenced.** Row 7 moves `KB-02`, `NAR-08` and `EXE-09` from
  `SHOULD` to `MUST` (their cited criteria all say MUST in as many words) — which moves their
  severity anchors to `Step 2` and so *changes the correct answer for row 4*, whose fix restates
  `KB-02`'s anchor in prose. Catalog first, prose second. It also made a **third** ledger-schema
  example row non-conformant (`NAR-08`/`[LOW]`) that the reviewer had explicitly cleared; the
  17 example rows tree-wide were re-swept after the change, and now carry 0 violations.
  **Class sweeps, not the named instances:** the em-dash `Line` cell was fixed in all four rows; the
  grade-behaviour claim was re-measured against `grade.sh` (`[HIGH]`→`D+`, `[MEDIUM]`→`C+`,
  `[LOW]`→`B+`) and the repo swept for other grade assertions (no others stale); and row 9's
  exit-code-header class was swept across `scripts/{summarize,config,kb}` — `manual-checklist.sh` and
  `kb-teachback-questions.sh` fixed, **11 pre-existing scripts recorded as tech-debt `W3-1`** rather
  than folded into this gate, because none is in this delivery's change surface.
  **Not fixed, and why:** row 1's `kb.html:3408` extent ("requires A+ for all KB documents") is a
  GENERATED artifact whose content pass is delivery-016's declared scope; editing the render instead
  of regenerating it is the F2 defect. Recorded there, not silently dropped.
- **Verification:** `derived-values` 14/14 · `skill-counts` 5/5 (218 claims) · `review-rubrics` 28/28
  · `reviewer-conformance` 33/33 · `modality-gate` 23/23 · `dogfood-byte-identity` 755/755 after
  render + dogfood resync of 12 files — four of which (`lint-frontmatter.sh`, `spot-check-facts.sh`,
  `tier-model.md`, `agent-prompts.md`) `d4af0528` had edited in `canonical/` and **never rendered**,
  so the byte-identity gate would have failed in CI on that commit alone.
- **State:** cycle 12's fixes are ungraded until a fresh reviewer runs.

---

## Cross-phase Q&A

<!-- AUTHORED -- single writer: this delivery's branch (via the delivery-gate step of
     aid-execute). Written here, NOT into the shared work-level STATE.md, to preserve the
     disjoint-write property. -->

### The V1 visual gate stays agent-mediated (2026-07-30) — human decision, DECIDED

- **Category:** Design
- **Impact:** Medium
- **Status:** **Decided — do not re-ask.** Raised by cycle 10's reviewer, which deliberately filed no
  ledger row for it because the behaviour is as-declared; it asked for a human judgment instead.

**What de-scoring changed.** The retired `grade-summary.sh` read `V1_score` and forced the Human Grade
to `F` when the mandatory visual check failed — a hard, mechanical block. Nothing now reads
`V1_answer`: `state-approval.md`'s precondition is `test -f` on the checklist JSON, which passes on a
checklist recording `V1_answer: "n"`. Enforcement rests on an agent choosing to write a `SUMMARY-06`
row, after which the grade follows from that row's severity like any other finding.

**Decision: leave it agent-mediated.** It is what the rubric already declares in as many words
(`knowledge-summary/grading-rubric.md § Hard rules` #2 — "it produces a `SUMMARY-06` finding, and the
grade follows"), `review-rubrics/summary.md` marks `SUMMARY-06` **judgment / human evidence only**, and
`test-landscape.md § Coverage Assessment` exempts prompt-driven skill state machines from machine
testing by design. So no rule is broken and nothing is silently weaker than declared — this judgment
check is enforced exactly like every other judgment check in the catalog.

**What this closes.** A future cycle must not file this as a defect, and must not "fix" it by adding a
`V1_answer` read to APPROVAL: that would make one judgment check enforced differently from the rest,
which is the inconsistency this decision chooses against. Reopening it means changing how *judgment*
rules are enforced generally, not patching this one.

### Why six cycles did not reach A+ (2026-07-30) — needs a human decision

- **Category:** Process
- **Impact:** High
- **Status:** Open — gate not passed; awaiting a decision on how to close it

Six Large-tier cycles. Grades `D- → D → D → D → D+ → D`. Findings `13 → 15 → 8 → 11 → 6 → 7`. All 60
are fixed; cycle 6's seven fixes are self-verified but ungraded.

**The substance is sound, and every cycle re-confirmed it independently.** Each reviewer built its own
fixtures and *ran* the emitter and the checklist script, re-derived the coverage-parity inventory,
mutation-tested the suites' gate-criterion assertions (7–8 mutations per cycle, all caught), and
re-verified NFR-1 (`grade.sh` byte-identical to `7a9df485`), NFR-2 (render parity across all 8 trees,
byte-identity 755/755), and NFR-7 (one grade producer, repo-wide). Gate criteria 1–4, 6 and 7 hold.

**What kept the grade down was documentation coherence — and, materially, me.** Three of the findings
in cycle N+1 were *caused by* a fix in cycle N:

| Cycle | Introduced by the previous cycle's fix |
|---|---|
| 4 | `AC3e-2`'s pattern carried a literal `0x08` where `\b` was meant → the only mechanical guard for gate criterion 5 passed unconditionally |
| 5 | `SEV01`'s row *feed* still required backticked rule IDs, so the widened extraction read 0 rows in four of eight files |
| 6 | wiring `PRE-01` landed a literal `\n` instead of a line continuation → the emitter **aborted** under `set -u` and reported exit 1, the code for a *complete* run |

All three are the same root cause: **an escape written through a layer that consumed it.** Two guards
now exist for it (`CB01` control bytes, `CB03` literal `\n`), both mutation-tested. But the rate matters
more than the instances: while fixing ~10 findings a cycle I was creating roughly one, so further cycles
carry real risk of net harm rather than convergence.

**The other driver is structural.** This delivery rewrote ~20 interlocking prose surfaces that all
describe one workflow (VALIDATE → MANUAL-CHECKLIST → APPROVAL/FIX, plus the two discover gates). An A+
floor requires *zero* open findings at `[MEDIUM]` or above, and `grade.sh` is worst-severity dominated —
so one restated severity or one stale sentence anywhere in those twenty files pins the whole delivery at
`D`. Cycle 6's seven findings were: one crash (mine), one unreconcilable rule (mine, cycle 5), two
missing runbook steps, and three stale sentences. That is the shape of the residue, and it is not
converging to zero by iteration.

**Three ways to close it, for the human to pick:**

1. **Accept at the current grade, with the residue documented.** The scripts, tests and gates are
   verified; the open class is prose coherence in files that no test can bind. Records the honest grade
   rather than an engineered one.
2. **Narrow the gate's scope to what it can actually judge** — scripts, tests, rendered parity — and
   move the prose-coherence sweep to its own delivery with a lint that can enforce it (a "no severity
   restated beside a rule ID" check already exists as `SEV01`; the missing one is "no stale claim about
   what a script does", which needs a different mechanism than review).
3. **Keep cycling.** Cheapest to say, and the trajectory argues against it: six cycles, one grade step,
   and a fix-induced-defect rate near one per cycle.

**Recommendation: option 2.** It is the only one that changes the mechanism rather than the effort, and
it matches what this work has already concluded twice — that a claim about a script's behaviour needs a
lint, not a reviewer (feature-008's FR-G4, and Q16's "a gate that can never pass gets switched off").

### Resumed 2026-07-30 — what the handoff's "implementation complete" actually was

The prior session recorded task-003 as complete with 23/23 tests passing. Both halves of that were
true and neither was sufficient: the uncommitted tree held **task-003's de-score plus an incomplete
start on task-005's surface sweep**, and the test suite passed over defects it was not written to
see. Carried here so nothing is lost and nothing is claimed twice.

**Fixed under task-003 (its own scope):**

| # | Where | Defect |
|---|---|---|
| 1 | `manual-checklist.sh:224` | Interactive banner still printed `Scores K1 (10) + K2 (15) + V1 visual gate (5) = 30 pts.` — the retired model, in user-visible output, from the very script being de-scored |
| 2 | `manual-checklist.sh:252` | Prompt still read `HUMAN VISUAL GATE (mandatory, 5 pts)` |
| 3 | `manual-checklist.sh:213` | Non-interactive mode announced `scoring supplied answers` |
| 4 | `manual-checklist.sh:24` | Header still said `V1=n (0 pts)` |
| 5 | `aid-summarize/references/state-approval.md:3` | `the grade meet the minimum` — agreement error introduced by the rewrite |
| 6 | `aid-summarize/references/state-approval.md:15-17` | The three new rows broke the value-column alignment the rest of the block keeps |

**Why the test suite did not catch 1-4.** `MC01` greps for `^\s*(K1|K2|V1)_score=` and the three
`score_*()` definitions. All of those were genuinely gone, so it passed — while four score strings
survived in the same file, two of them the only thing a human running the script would actually see.
The suite's own header warns that "it is easy to write a test that passes because it looks at
nothing"; this is that, in the suite that warns about it. **task-006 must assert over the script's
output strings, not only its identifiers.**

**Open, and owned by later tasks in this delivery** (not fixed under task-003 — each is in another
task's declared scope):

| # | Where | Defect | Owner |
|---|---|---|---|
| 7 | `knowledge-summary/grading-rubric.md:70-71` | The check table still carries `**Machine total** \| **68**` and `**Human total** \| **30**` — the two-grade model's totals, live on a canonical surface. `TG01` misses them because it greps `Machine Grade`/`Human Grade`, not `Machine total` | task-005 |
| 8 | same, `:296-302` | An orphaned code block with no heading or lead-in, displaying the retired scored output (`15/15`, `5/5`, `2/2`) — left behind when the percentage-ladder section was deleted | task-005 |
| 9 | same, `:161-166`, `:213-219`, `:247-251`, `:69` | Point values surviving in the pass-criteria prose: `Full coverage (10/10)`, `Partial (5/10)`, `trivially passed (5/5)`, `Trivially passed (2/2)` | task-005 |
| 10 | same, `:212-219` | `D1`/`D2` still have live pass-criteria sections while `review-rubrics/summary.md` records them as **deleted** | task-005 |
| 11 | same, `:51`, `:160` | `K1` cites `discovery.doc_set`; `COV` at `:54` and `summary.md` cite `knowledge.doc_set`. One of the two is wrong | task-005 |
| 12 | `state-summary-delta.md:319` | Reads `diagram parse failure → auto-F on the human visual check` — a careless substitution that now asserts something false (a diagram parse failure is not the human visual check), and the line still says "Machine or Human grade" | task-005 |
| 13 | `aid-summarize/references/state-fix.md:14-15`, `:26` | Still carries `D1`/`D2` repair entries for deleted checks, and an example reading *"K1 scored partial"* | task-005 |
| 14 | `review-rubrics/summary.md` mapping table | Omits `T1`, `T2`, `T3` and `NM` while claiming "Every check it scored is accounted for here". `T1`/`T2` appear only inside the `V1` row's note; `T3` and `NM` appear nowhere. `MP02` asserts 17 checks, so it cannot see the gap | task-004 (it owns the visual-gate split) |
| 15 | `review-rubrics/summary.md` Change Log | Says "Seven content-truth rules"; the file defines **nine** (`SUMMARY-01`…`09`) | task-004 |

### Two pre-existing defects the sweep turned up — recorded, deliberately NOT fixed here

Both were found by task-005's derived sweep, both predate this delivery, and neither is in its scope
(`## Scope` names the grading backend). Recorded with the evidence and the fix so the decision to
defer is visible rather than silent.

**A. `validate-visuals.mjs` has never been invoked by anything. [HIGH]**

Six surfaces describe the §7 visual-fidelity gate (T1/T2/T3) as part of VALIDATE, and
`state-validate.md` listed it as check **1 of 3** that `emit-summary-findings.sh` "orchestrates".
Nothing invokes it:

```bash
grep -rn validate-visuals canonical/ --include=*.sh --include=*.mjs   # only its own file
```

`emit-summary-findings.sh` runs `validate-html-output.sh` and `contrast-check.mjs`, and does the
coverage and retired-runtime checks inline. **The retired `grade-summary.sh` invoked the same two**
(`git show 7a9df485:...grade-summary.sh | grep -E '\.mjs|bash '`), so this delivery neither caused it
nor reduced coverage — the delivery gate criterion *"reduces no assertion"* holds. It is the same
false-wiring class this work already found twice: feature-007's frontmatter lint, and feature-008's
`quality-gates.md` claim that the citation lint runs in CI.

It also falsifies feature-007 SPEC §1c, which says the retained script *"Keeps: ... the four
validator invocations"*. There were **two**.

*Done here:* every surface now says the validator is available but not invoked, points at the manual
invocation, and names the mandatory human visual check as the live safeguard — which is the fallback
already specified for a host without Playwright. *Not done here:* wiring it. That is a behaviour
change, needs Playwright plus a real `kb.html` to test, and belongs to whoever owns the visual gate.

**B. 11 canonical `SKILL.md` files carry a dead relative link, and it ships. [MEDIUM]**

```bash
grep -rlc '](\.\./\.\./templates/state-machine-chaining.md)' canonical/skills/   # 11 files
grep -rlc '](\.\./\.\./aid/templates/state-machine-chaining.md)' canonical/skills/ # 2 files, correct
```

From `canonical/skills/<skill>/SKILL.md`, `../../templates/` resolves to `canonical/templates/`,
which does not exist; the file is at `canonical/aid/templates/`. `aid-create-ticket` and `aid-define`
use the correct `../../aid/templates/` form. **The renderer does not rewrite it** — the dogfood
`.claude/skills/aid-summarize/SKILL.md` carries the identical broken path — so it is dead in all five
profiles and both dogfood trees, i.e. shipped to adopters.

The fix is mechanical (`../../templates/` → `../../aid/templates/` in 11 files) and the delivery
re-renders anyway. Deferred regardless: delivery-015's gate criteria are all about grading, and
touching 11 unrelated skills inside it would make the diff unreviewable against those criteria.
**Raised for a scope decision rather than assumed either way.**

### AC-2 is satisfied BY the historical rows, not despite them

`.aid/knowledge/STATE.md` still records `| Machine Grade | A+ (grade-summary AUTO_POOL 68/68) |`,
`| Human Grade | A+ ... |` and `**Overall Grade:** A+` from a past run. Those are **left exactly as
they are, on purpose** — task-005's second acceptance criterion says historical recorded values stay
as history, because re-deriving a letter for findings that were never itemised would be fabrication.
The template that governs *future* writes (`discovery-state-template.md`) now emits `Grade` +
`Checklist`. Flagged here so the delivery gate does not read a deliberately-preserved record as a
missed surface.

**NFR-2 (five profiles) is discharged once for the delivery, not per task.** Tasks 001-002 left the
render un-run: `emit-summary-findings.sh` exists only in `canonical/`, and `grade-summary.sh` is
still present in all five `profiles/` trees and both dogfood trees (`.claude/`, `.cursor/`).
Rendering per task would publish incoherent intermediate trees — task-005's surfaces currently
contradict task-003's script. The render + dogfood sync therefore runs once, after task-005, before
task-006 and the gate. Task-003's "All section-6 quality gates pass" is satisfied at that point;
recorded here rather than ticked early.

### Method change at cycle 9 (2026-07-30) — fix the class, not the instance

Cycles 1-8 fixed what the ledger named and handed the rest back to the next reviewer. The evidence
that this was the actual cause of non-convergence, not bad luck:

| Fixed at | Found again at | The class that was never swept |
|---|---|---|
| cycle 8 — severities in `kb-dual-intent-probes.sh` | cycle 9 | the identical claim in its sibling `kb-actback-task.sh`, never grepped |
| cycle 6 — "forces grade <= D" in 4 places | cycles 8 **and** 9 | 4 more instances of the same sentence |
| cycle 8 — 3 control chars in `escape_json` | cycle 9 | 29 of the 32 C0 chars were still broken |
| cycle 7 — added `MC09` to hold that class | cycle 9 | the guard could not fail: its fixture held only already-handled chars |

From cycle 9 the FIX step is three obligations, not one:

1. **Sweep the class.** A finding names a defect *kind*; its Evidence bounds the *extent*. Grep the
   whole tree for the kind before touching the named instance.
2. **Run it, then mutate it.** Exercise every exit path of what was changed, and for each new guard,
   break the thing it guards and confirm the guard fails. A guard that has never failed is unproven.
3. **Discharge the coherence obligations the fix creates.** A changed contract has readers — the
   state docs, the rubric rows, the golden fixtures, the sibling script. Enumerate and check them.

What this produced at cycle 9: 4 classes swept tree-wide, 22+ mechanical guards now holding the
classes prose review had been re-catching each cycle (`test-one-grading-backend.sh` 23 -> 58
assertions), every exit path of both scripts exercised, and the two golden fixtures the changes
touched updated and re-verified. Cost: this cycle's self-review was longer than the reviewer pass it
precedes. That is the intended trade — the reviewer is a safety net, not the mechanism.

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEW
     Assembled at READ TIME from tasks/task-NNN/STATE.md. Never written here.
     ============================================================ -->

## Tasks State

<!-- DERIVED -- read-only rollup from tasks/task-NNN/STATE.md.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |
