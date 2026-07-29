---
delivery_state: Executing
gate_tier: Small | Medium | Large
gate_grade: "{grade or Pending}"
gate_timestamp: "{YYYY-MM-DDTHH:MM:SSZ}"
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

- **Issue List:** {inline severity-tagged list, or "none" if gate passed clean}

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
