# State: VISUAL-GATE

VISUAL-GATE asks the one question about this artifact that no machine can answer — whether the graph is legible — and recomputes the Overall Grade from the answer; it is selected after VALIDATE meets the floor, when the view is in scope.

**N/A when `view_expected` is false.** No page was rendered, so there is nothing to judge:
the human pool is `N/A`, the Overall Grade is the Machine Grade, and VALIDATE advances
straight to DONE without entering this state at all. That is the honest form of "no human
gate on a table" — not a waived check, but a check with no subject.

## Why there is a human gate here at all, and only one check in it

Every property of the relationship table that matters is decidable: an id resolves or it
does not, a relation pair inverts or it does not, a provenance value is in the enum or it is
not. There is no judgment to elicit about it, so it carries **no** human check — a human
pool over a machine-checkable table would be ceremony that invites rubber-stamping.

Whether a live force-directed graph is *legible* is a different kind of question, and it is
not machine-decidable. The visual validator does not even collect a canvas. Two project
rules already bind this: reviewing web output requires a real browser, and source inspection
is not a valid review of a rendered page. So the view carries exactly **one** check, `G1`,
and it is mandatory.

## Ask `G1`

Surface the artifact — `.aid/knowledge/graph.html` — and ask the user to open it in a real
browser. Use `AskUserQuestion`; this is inline elicitation, not a pause. Ask one question
with all of its parts named, so a "yes" means something:

> **`G1` — is the graph legible and usable?** With the page open in a real browser: are the
> labels readable at default zoom; does each lens visibly change the view; do keyboard zoom
> and pan work; and does reduced motion yield a settled picture rather than a moving one?

**One of `G1`'s answers is "it did not render."** That is a real outcome and not a legibility
verdict: the table mounts first and unconditionally, and the canvas may report that no
drawing context is available. Record it as a `G1` **fail** whose repair is the drawing-context
prerequisite — and it is the one `G1` answer FIX routes to the packaging owner rather than to
a density or label change.

## Record the answer, then recompute

Write the answer to `.aid/.temp/graph/visual-gate.json`:

```json
{ "g1": "pass", "note": "<the user's own words, verbatim>" }
```

`"g1"` is `pass` or `fail` and nothing else. Then re-run the gate so the grades are computed
from the recorded answer by the one script that computes them:

```bash
bash canonical/aid/scripts/graph/grade-graph.sh
```

A `fail` forces the Human Grade to `F`, and the Overall Grade is the lower of the two. `G1`
never becomes a ledger row: that ledger is the machine gate, and a human verdict inside it
would be counted into the Machine Grade.

**The answer dies with the scratch, and that is correct.** `G1` is re-asked on every
regeneration, because a regenerated view is a different picture and a stored approval would
be an assertion about bytes that no longer exist. Nothing about it is persisted into
`.aid/knowledge/`.

## Route on the recomputed Overall Grade

| Condition | Do |
|---|---|
| Overall Grade ≥ the resolved floor | CHAIN to DONE |
| Overall Grade < the resolved floor | CHAIN to FIX |

Print: `[State: VISUAL-GATE] complete.`

**Advance:** **CHAIN** → [State: DONE] if the Overall Grade ≥ the floor; **CHAIN** → [State: FIX] otherwise. Both continue inline.
