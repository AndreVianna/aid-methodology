# State: VALIDATE

VALIDATE runs this skill's own quality rubric over its own two artifacts and computes the Machine Grade; it is selected after RENDER, and again after every FIX.

Run:

```bash
bash .cursor/aid/scripts/graph/grade-graph.sh
```

— adding `--grade X` iff the invocation carried it.

The script invokes the reused leaf validators, writes one ledger row per failure into
`.aid/.temp/review-pending/graph.md` at the severity the rubric assigns, hands that ledger
to the project's one grading algorithm, and prints the check inventory and then the three
grades. **The rubric — every row, its severity and the reason for that severity — lives in
that script's `--help`**, which is its single home; it is not restated here, because a
second copy of a severity assignment is a second authority that can drift.

## Show the inventory, not just the grade

The inventory carries a line for **every** rubric row: `run`, `skip` or `fail`. Print it.
It is what makes "no row = no finding" safe to rely on — an absent row means a **passed**
check and never an unrun one — and it is the only thing that stops a grade from being read
as stronger evidence than it is. Every `skip` is repeated in the closing summary, and DONE
prints it again.

Two skips are expected rather than exceptional, and both are honest degradations:

- **A check whose runtime is absent** — no browser for the visual gate. It emits no row and
  does not lower the Machine Grade. The human check then carries the whole visual review,
  and reviewing a rendered page by reading its source is not a valid substitute for it.
- **A validator that could not be invoked** (exit `2`). The artifact is not what failed, so
  this is a recorded skip and never a silent pass. Report it against the validator.

## What is structurally absent from this state

No check's subject is the Knowledge Base's completeness. The Knowledge Base gap rows live
in a **different** ledger, and `grade-graph.sh` refuses that path outright — so the gap rows
are unreachable by the gate rather than merely unread. Do not pass, mention or merge that
path into any grading call.

## Route on the printed Machine Grade against the resolved floor

Both numbers are on the script's own output, and its exit code already compares them:

| Condition | Do |
|---|---|
| Machine Grade ≥ the resolved floor, and the view is in scope | CHAIN to VISUAL-GATE |
| Machine Grade ≥ the resolved floor, and the view is **not** in scope | The human pool is `N/A` and the Overall Grade is the Machine Grade: CHAIN straight to DONE |
| Machine Grade < the resolved floor | CHAIN to FIX |

The Human and Overall Grades read `pending` on this state's first pass whenever the view is
in scope, because the human check has not been asked yet. That is correct, and neither
enters the routing decision here: **this state routes on the Machine Grade alone.**

Print: `[State: VALIDATE] complete.`

**Advance:** **CHAIN** → [State: VISUAL-GATE] if the Machine Grade ≥ the floor and the view is in scope; **CHAIN** → [State: DONE] if it is ≥ the floor and the view is not in scope; **CHAIN** → [State: FIX] otherwise. All continue inline.
