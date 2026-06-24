# State: REVIEW

REVIEW grades the changed KB docs through f005's five-mandate review/calibration
panel. It is selected when the run-state file records `**State:** REVIEW` or
`**State:** FIX`.

**Cross-delivery reuse (task-014 / f005 seam).** This state does NOT redefine
the review gate. It invokes `aid-discover`'s REVIEW state machine
(`canonical/skills/aid-discover/references/state-review.md`) with the f005
injectable parameters set to the `aid-update-kb` scope:

- `{{SCOPE}}` = `update-kb`
- `{{ARTIFACTS}}` = the changed-doc set (read from `**Edited Docs:**` in the
  run-state file)
- `{{CONTEXT}}` = "aid-update-kb targeted KB update review"

All ledger paths, mandate dispatch instructions, merge logic, grade.sh
invocation, teach-back gate derivation, act-back gate derivation, and scratch
ledger cleanup are defined in f005's `state-review.md` and followed WITHOUT
modification. This section supplies only the `aid-update-kb`-specific wiring.

Print the `[State: REVIEW]` banner from `SKILL.md § State Detection`.

---

## Step 0: Read the changed-doc set

Read `**Edited Docs:**` from `<STATE_FILE>` to get the list of docs that APPLY
edited. This is the `{{ARTIFACTS}}` value passed to f005's panel. If
`**Edited Docs:**` is absent, read it from `**Change Plan:**` as the fallback.

---

## Step 1: Invoke f005's REVIEW with update-kb scope

Follow `canonical/skills/aid-discover/references/state-review.md` verbatim,
substituting:

```
{{SCOPE}}     = update-kb
{{ARTIFACTS}} = <list of .aid/knowledge/<doc>.md paths from the edited-doc set>
{{CONTEXT}}   = "aid-update-kb targeted KB update: review the changed docs for
                 accuracy, calibration, concept-closure, teach-back, act-back,
                 and calibration. The docs were edited by aid-update-kb APPLY
                 from this prompt: <prompt from **Prompt:** in run-state>"
```

The five (or six, per `panel:` setting) mandate sub-agents run against the
changed docs only, each writing to its own scratch ledger:

```
.aid/.temp/review-pending/update-kb-correctness.md
.aid/.temp/review-pending/update-kb-anatomy.md
.aid/.temp/review-pending/update-kb-concept-closure.md
.aid/.temp/review-pending/update-kb-teachback.md
.aid/.temp/review-pending/update-kb-calibration.md
.aid/.temp/review-pending/update-kb-actback.md
```

**Teach-back scope (SPIKE-1 default -- FR-34 re-verification).** The M4
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
bash canonical/scripts/grade.sh --explain .aid/.temp/review-pending/update-kb.md
```

Derive `teach_back_verdict` and `act_back_verdict` per f005's Step 2c and 2d
(count open `[TEACHBACK]` and `[ACTBACK]` rows in `update-kb.md`).

---

## Step 3: Evaluate the exit rule and resolve minimum grade

Resolve the minimum grade for `aid-update-kb`:

```bash
bash canonical/scripts/config/read-setting.sh \
  --skill update-kb --key minimum_grade --default A
```

Exit rule (identical to f005):

```
READY iff grade(update-kb.md) >= minimum_grade
     AND teach_back_verdict == PASS
     AND act_back_verdict == PASS
```

Print:

```
Grade: {grade} | Teach-back: {PASS|FAIL} | Act-back: {PASS|FAIL} -> {Ready|NOT Ready}
[Review 3/3] Grade: {grade}. Minimum: {min}.
```

---

## Step 4: Advance

**If READY:** Update `<STATE_FILE>`:

```
**State:** APPROVAL
**Review Grade:** <grade>
**Review Teach-back:** PASS
**Review Act-back:** PASS
**Review Completed:** <ISO-8601 timestamp>
```

Print: `[State: REVIEW] complete. Advancing to APPROVAL.`

**Advance:** CHAIN -> APPROVAL (continue inline).

---

**If NOT READY:** Route below-gate findings to the FIX loop.

The FIX loop reuses `aid-discover`'s existing `state-fix.md` over `update-kb.md`
(NO new loop is invented). Invoke
`canonical/skills/aid-discover/references/state-fix.md` with the ledger path
set to `.aid/.temp/review-pending/update-kb.md`. After FIX completes its edits
and regenerates, return to Step 1 of this state (re-dispatch the panel).
Repeat until READY.

Update `<STATE_FILE>`:

```
**State:** FIX
**Review Grade:** <grade>
**Review Teach-back:** <PASS|FAIL>
**Review Act-back:** <PASS|FAIL>
```

Print: `[State: REVIEW] below gate -- entering FIX loop.`

**Advance:** CHAIN -> FIX (aid-discover state-fix.md over update-kb.md), then
re-enter REVIEW (Step 1) on return.
