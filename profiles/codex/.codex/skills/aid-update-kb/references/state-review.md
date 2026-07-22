# State: REVIEW

REVIEW first runs two mechanical, `aid-update-kb`-specific checks -- a
**scope-diff guard** (disk-derived) and a **hunk-level traceability
mandate** -- and only then grades the changed KB docs through f005's
four-mandate review panel (Correctness / Anatomy-incl-altitude / Teach-back /
Act-back). It is selected when the run-state file records `**State:** REVIEW`
or `**State:** FIX`.

**Cross-delivery reuse (task-014 / f005 seam).** This state does NOT redefine
the review gate. Once the scope-diff guard (Step 0) passes, it invokes
`aid-discover`'s REVIEW state machine
(`.codex/skills/aid-discover/references/state-review.md`) with the f005
injectable parameters set to the `aid-update-kb` scope:

- `{{SCOPE}}` = `update-kb`
- `{{ARTIFACTS}}` = the **disk-derived** edited-doc set from Step 0 below --
  NEVER APPLY's self-reported `**Edited Docs:**`
- `{{CONTEXT}}` = "aid-update-kb targeted KB update review" plus the
  hunk-level traceability mandate instructions (Step 0c)

All ledger paths, mandate dispatch instructions, merge logic, grade.sh
invocation, teach-back gate derivation, act-back gate derivation, and scratch
ledger cleanup are defined in f005's `state-review.md` and followed WITHOUT
modification (AC-7 -- the f005 panel itself is unchanged). This section
supplies only the `aid-update-kb`-specific wiring, plus the two
update-kb-specific checks that gate entry into it.

Print the `[State: REVIEW]` banner from `SKILL.md § State Detection`.

---

## Step 0: Scope-diff guard (mechanical, runs FIRST, HL-7/AC-4)

**This guard is authoritative and MUST run before the f005 panel is even
dispatched.** It never trusts APPLY's self-report; it derives the actually-
edited doc set from disk.

### 0a. Derive the edited-doc set from disk

Read `**Pre-APPLY baseline:**` and `**Confirmed Scope:**` from `<STATE_FILE>`.

```bash
BASELINE=$(grep -m1 "^\*\*Pre-APPLY baseline:\*\*" "$STATE_FILE" | sed 's/^\*\*Pre-APPLY baseline:\*\* *//')
if [ -z "$BASELINE" ] || [ "$BASELINE" = "clean" ]; then
  DISK_CHANGED=$(git status --porcelain -- .aid/knowledge/ | awk '{print $2}')
else
  DISK_CHANGED=$(git diff --name-only "$BASELINE" -- .aid/knowledge/)
fi
```

`DISK_CHANGED` is ground truth -- the set of `.aid/knowledge/` paths that
actually differ on disk right now. This is compared against
`**Confirmed Scope:**` (the frozen doc list CONFIRM wrote), **never** against
APPLY's `**Edited Docs:**` self-report (that field is read only for
descriptive context in Step 0c, below -- it is not the guard's input).

### 0b. Compare against Confirmed Scope

- **A disk-changed doc NOT in Confirmed Scope** -> **HARD FAIL**,
  unconditionally (never gradable away by grade/teach-back/act-back -- this
  is a live HL-7 scope violation, not a quality defect). Whether the edit is
  an accidental slip or a genuinely-needed addition is a judgment call this
  mechanical guard cannot make on its own -- it never silently reverts and
  never silently lets it through. Print:

  ```
  [REVIEW] Scope-diff guard: HARD FAIL -- <doc> was edited but is not in
  Confirmed Scope. Escalating to the user (Step 4(b) below) -- this guard
  never decides for itself whether an out-of-scope edit is accidental or
  genuinely needed.
  ```

- **A Confirmed Scope doc NOT changed on disk** -> not an automatic hard
  fail; check that Scope Plan row's `Change-type`:
  - `No change needed` -- expected; that item PASSES.
  - Any other change-type -- the confirmed edit was never made. Flag as an
    incomplete APPLY -- unambiguous, no scope judgment needed (Step 4(a)
    below): completing an already-confirmed item stays inside scope, it is
    not an expansion.

- **Disk-changed set == Confirmed Scope** (after the `No change needed`
  carve-out above) -> scope-diff guard **PASSES**.

Print:

```
[REVIEW] Scope-diff guard: {PASS|HARD FAIL}. Disk-derived edited set:
{list}. Confirmed Scope: {list}.
```

If the guard is not a clean PASS, do **NOT** proceed to Step 0c/Step 1 this
pass -- go directly to Step 4(a) (incomplete-APPLY) or Step 4(b) (HARD FAIL)
below; the f005 panel is never dispatched over a scope-diff violation that
hasn't cleared first (there would be no ledger to fix it against either --
see Step 4(a)/4(b)).

---

## Step 0c: Traceability mandate (hunk-level, AC-4)

Beyond the file-level scope-diff guard above, every individual edit -- down
to the hunk -- must map to a specific confirmed Scope Plan item. The
file-level guard cannot see over-editing *within* an in-scope doc (e.g. a
whole new section grafted onto a doc whose only confirmed item was one small
fact correction). This is **not** a fifth f005 dispatch -- it is folded into
the `{{CONTEXT}}` handed to the existing four-mandate panel in Step 1, so the
already-dispatched reviewers check it as part of their normal pass:

```
Traceability mandate (aid-update-kb specific, in addition to your normal
mandate): for each doc in {{ARTIFACTS}}, diff it against the Pre-APPLY
baseline (`git diff <baseline> -- <doc>`) hunk by hunk. Every hunk must
correspond to exactly one Scope Plan row (matched by doc + change-type/
description -- read **Scope Plan:** from the run-state file for the row
descriptions). A hunk with no corresponding Scope Plan row is an
out-of-scope edit inside an otherwise in-scope doc. Flag it:
[TRACE-1] Untraceable hunk -- <file>:<hunk> has no corresponding Scope Plan
item (nearest item: <#>, if any)
```

`[TRACE-1]` findings are graded via the normal `grade.sh` mechanism (Step 2
below) alongside Correctness / Anatomy / Teach-back / Act-back findings --
they are not a separate pass/fail gate on their own, but they count against
the merged grade, so an over-edited hunk cannot pass review purely because
the four base mandates are individually satisfied.

---

## Step 1: Invoke f005's REVIEW with update-kb scope

Follow `.codex/skills/aid-discover/references/state-review.md` verbatim,
substituting:

```
{{SCOPE}}     = update-kb
{{ARTIFACTS}} = <DISK_CHANGED from Step 0a -- the disk-derived .aid/knowledge/<doc>.md paths>
{{CONTEXT}}   = "aid-update-kb targeted KB update: review the changed docs for
                 accuracy, anatomy/coverage (incl. altitude: hollow vs
                 transcription), teach-back, and act-back. The docs were edited
                 by aid-update-kb APPLY from this prompt: <prompt from
                 **Prompt:** in run-state>" + the Step 0c traceability
                 mandate text (verbatim)
```

The four mandate sub-agents (or 3 dispatches, per `panel:` setting) run against the
changed docs only, each writing to its own scratch ledger:

```
.aid/.temp/review-pending/update-kb-correctness.md
.aid/.temp/review-pending/update-kb-anatomy.md
.aid/.temp/review-pending/update-kb-teachback.md
.aid/.temp/review-pending/update-kb-actback.md
```

**Teach-back scope (SPIKE-1 default -- FR-34 re-verification).** The M3
teach-back dispatch uses the **full whole-KB clean-context exit** (not a scoped
teach-back limited to the changed docs). A fresh agent given ONLY the KB
explains the engine. This guarantees that the delta did not break whole-KB
concept closure (FR-34 standing invariant). The scoped optimization
(teach-back limited to changed-docs' concepts only) is f010-tunable but NOT
the default here.

---

## Step 2: Merge and grade (f005 machinery, unchanged)

Follow f005's Step 2 verbatim with `{{SCOPE}} = update-kb`:

Merge the scratch ledgers into the single canonical ledger:

```
.aid/.temp/review-pending/update-kb.md
```

Then delete the scratch ledgers per f005's Step 2e (the `rm -f` block with
`{{SCOPE}} = update-kb`).

Run the unchanged `grade.sh`:

```bash
bash .codex/aid/scripts/grade.sh --explain .aid/.temp/review-pending/update-kb.md
```

Derive `teach_back_verdict` and `act_back_verdict` per f005's Step 2c and 2d
(count open `[TEACHBACK]` and `[ACTBACK]` rows in `update-kb.md`).

---

## Step 3: Evaluate the exit rule and resolve minimum grade

Resolve the minimum grade for `aid-update-kb`:

```bash
bash .codex/aid/scripts/config/read-setting.sh \
  --skill update-kb --key minimum_grade --default A
```

Exit rule (f005's rule, plus the scope-diff verdict -- already guaranteed
PASS at this point, since Step 0 would have routed away before Step 1 if it
were not):

```
READY iff scope_diff_verdict == PASS
     AND grade(update-kb.md) >= minimum_grade
     AND teach_back_verdict == PASS
     AND act_back_verdict == PASS
```

Print:

```
Scope-diff: PASS | Grade: {grade} | Teach-back: {PASS|FAIL} | Act-back: {PASS|FAIL} -> {Ready|NOT Ready}
[Review 3/3] Grade: {grade}. Minimum: {min}.
```

---

## Step 4: Advance

Four distinct outcomes reach this step -- two are a pre-panel block straight
out of Step 0 (4a/4b, no ledger exists yet), two are the f005 panel's own
result once Step 0 has fully passed (4c/4d).

### 4(a) Incomplete APPLY (Step 0b's second bullet) -- loop back to APPLY, no escalation

Unambiguous: a doc already in `Confirmed Scope` simply has not been edited
yet (and its `Change-type` is not `No change needed`). No scope judgment is
needed -- APPLY just has to finish already-confirmed work. There is no
ledger for this (the panel never ran this pass), so this does **not** go
through `aid-discover`'s FIX-loop machinery -- it is a direct loop back to
APPLY:

Update `<STATE_FILE>`:

```
**State:** APPLY
**Scope-diff:** incomplete-APPLY -- <doc> confirmed but unedited
```

Print: `[REVIEW] Scope-diff guard: incomplete APPLY -- <doc> is confirmed but was never edited. Returning to APPLY.`

**Advance:** CHAIN -> APPLY (continue inline; `state-apply.md § Step 1` picks
the doc back up -- it is still in `Confirmed Scope`).

### 4(b) Out-of-scope edit found on disk (Step 0b's first bullet) -- user escalation, never auto-decided (HL-7)

Grade-chasing may not expand scope, and this mechanical guard cannot itself
tell an accidental edit from a genuinely-needed one -- so it never silently
reverts and never silently lets a fix loop absorb it either. Append a Q&A
entry to `.aid/knowledge/STATE.md ## Q&A (Pending)`:

```
### Q{N}
- **Category:** Update-KB / Scope Expansion Needed
- **Impact:** High
- **Status:** Pending
- **Context:** /aid-update-kb REVIEW found <doc> edited on disk but outside
  Confirmed Scope. This may be an accidental out-of-scope edit, or a
  genuinely needed addition the instruction implies but SCOPE/CONFIRM did
  not originally capture.
- **Suggested:** If <doc> should be in scope, re-run /aid-update-kb to
  re-enter CONFIRM/SCOPE with the expanded need. If it should NOT be in
  scope, simply re-run /aid-update-kb without expanding it -- the next
  APPLY pass reverts the out-of-scope edit automatically
  (`state-apply.md § Step 0`), no manual `git restore` required.
```

Update the run-state file:

```
**State:** CONFIRM
**Scope-diff:** HARD FAIL -- escalated Q{N}
```

Print:

```
[REVIEW] Scope-diff guard: HARD FAIL -- <doc> is outside Confirmed Scope.
Escalated as Q{N} in .aid/knowledge/STATE.md -- grade-chasing may not
expand scope (HL-7). Run /aid-update-kb again to resolve at CONFIRM.
```

**Advance:** PAUSE-FOR-USER-ACTION -- return to CONFIRM on the next
invocation. Either answer resolves cleanly with no extra step here: accept
the expansion and CONFIRM's next freeze simply includes `<doc>`; decline it
and `state-apply.md § Step 0`'s re-scope revert strips the edit the next
time APPLY runs.

### 4(c) READY (scope-diff PASS and grade/teach-back/act-back all clear) -> APPROVAL

Update `<STATE_FILE>`:

```
**State:** APPROVAL
**Scope-diff:** PASS
**Review Grade:** <grade>
**Review Teach-back:** PASS
**Review Act-back:** PASS
**Review Completed:** <ISO-8601 timestamp>
```

Print: `[State: REVIEW] complete. Advancing to APPROVAL.`

**Advance:** CHAIN -> APPROVAL (continue inline).

### 4(d) NOT READY (grade / teach-back / act-back / `[TRACE-1]` findings) -- ordinary FIX loop, bounded to Confirmed Scope (HL-7)

The scope-diff guard already passed to reach the panel at all -- these
findings are quality/traceability defects within already-in-scope docs, not
a scope-expansion question. The FIX loop reuses `aid-discover`'s existing
`state-fix.md` over `update-kb.md` (NO new loop is invented). Invoke
`.codex/skills/aid-discover/references/state-fix.md` with the ledger path
set to `.aid/.temp/review-pending/update-kb.md`.

**FIX-loop constraint (HL-7).** Every fix edit MUST stay within
`**Confirmed Scope:**` -- it may correct/complete an already-confirmed doc,
or trim a `[TRACE-1]`-flagged hunk back to what its Scope Plan item actually
describes. It may NEVER add a new doc, or a new hunk of substance, with no
confirmed Scope Plan item behind it -- that is scope expansion, not a fix,
and has no legitimate path through this loop (a fixer that tries it
re-triggers Step 0's scope-diff HARD FAIL on the next pass, which routes to
4(b) above, not back through FIX again).

After FIX completes its edits, return to Step 0 of this state (re-run the
scope-diff guard before re-dispatching the panel).

Update `<STATE_FILE>`:

```
**State:** FIX
**Scope-diff:** PASS
**Review Grade:** <grade>
**Review Teach-back:** <PASS|FAIL>
**Review Act-back:** <PASS|FAIL>
```

Print: `[State: REVIEW] below gate -- entering FIX loop.`

**Advance:** CHAIN -> FIX (aid-discover state-fix.md over update-kb.md), then
re-enter REVIEW (Step 0) on return.
