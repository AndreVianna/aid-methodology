# State: FIX

FIX repairs what the gate found and re-enters the pipeline at the state that can regenerate the repaired thing; it is selected when VALIDATE or VISUAL-GATE finds a grade below the resolved floor.

## Both artifacts are generated, so editing one is not a repair

`relationships.md` and `graph.html` are build output. Hand-editing either is not a fix: the
next regeneration re-emits the defect, and the file itself carries an `AUTO-GENERATED`
marker naming the command that overwrites it. **The repair goes to the input.** That is why
this state does not loop straight back to VALIDATE — it re-enters the pipeline at the state
that regenerates what was repaired.

## Machine-pool rows — objective, one correct repair each

Read `.aid/.temp/review-pending/graph.md` and take every row whose Status is `Pending` or
`Recurred`. Each row's Description names the failing check and its Evidence carries the
validator's own line, which is what identifies the offending input.

**Do NOT touch the Status column.** The fixer fixes; the reviewer verifies. The next
VALIDATE re-runs the checks and moves the Status itself — a row you mark `Fixed` by hand is
a claim that has not been re-verified.

## The re-entry state is decided by where the repaired input lives

Print the re-entry state as you route, and record it in the row's `Evidence` so the decision
is observable rather than remembered:

| The repair touched | Re-enter at | Why not earlier or later |
|---|---|---|
| A view input — a view template, the palette, or the assembled page | **RENDER** | The table is unaffected. Re-running EXTRACT would re-run the bounded agent pass and legitimately churn the inferred rows for what was a styling fix |
| A table input — the relation vocabulary, the schema carrier, an enumeration or extraction script, or the coverage-notes assembler | **EXTRACT** | The row set itself changes |
| Nothing — the row was `Accepted` or `Invalid` under the ledger schema's own rules | **VALIDATE** | There is nothing to regenerate |

Where one cycle's rows span more than one class, re-enter at the **earliest** state any of
them requires: EXTRACT before RENDER, RENDER before VALIDATE. A later state cannot
regenerate what an earlier one produces.

## The human row is subjective — expose → propose → ask, never a silent guess

A `G1` fail is a judgment, and the user's judgment is the input. Never guess-fix it.

1. **Expose** — restate the legibility complaint precisely, in the user's own words, and
   name what in the view it is about.
2. **Propose** — offer **one** concrete change: a density default, a label-collision rule, a
   lens preset. Not a menu, and not a rewrite.
3. **Ask** — use `AskUserQuestion` to have the user approve the proposal, give their own
   direction, or accept the lower grade. **Wait for the answer before editing anything.**

**The one `G1` answer that is not a legibility repair** is "it did not render". Its repair is
the drawing-context prerequisite, and it is routed to the packaging owner rather than fixed
here — a density change cannot supply a missing drawing context. Say so plainly and stop; do
not iterate on a picture that was never drawn.

Print: `[State: FIX] complete.` and the re-entry state.

**Advance:** **CHAIN** → [State: RENDER], [State: EXTRACT] or [State: VALIDATE] per the table above (continue inline).
