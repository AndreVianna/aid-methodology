# State: Q-AND-A

The work's `qa` (STATE.yml) has open entries (`state: Pending` or `state: Skipped`); resolve them one at a time before continuing. A `Skipped` entry stays open and is offered again here, to the same user or to another one.

These may come from:
- Cross-reference analysis (State 6)
- Loopback from downstream phases (e.g., `/aid-specify` recorded a question with `--ask`)
- Review findings

### Step 1: Load and Filter

Read the work's `qa`. Collect all entries with `state: Pending` or `state: Skipped`.

**Before asking each question, filter:**

1. **Already answered in REQUIREMENTS.md?** → record it `Assumed`, with the section it is answered in:
   `bash .aid/runtime/scripts/execute/writeback-state.sh --answer --id Q<n> --state Assumed --value '<answer>' --applied-to '<section>'`.
   Skip to next.
2. **Answered in KB?** → record it `Assumed` the same way, citing the KB document. Skip.
3. **Inferrable from context?** → Keep it, and make sure its `suggested` answer exists.

After filtering, sort the remaining open entries by impact: **High → Medium → Low**.

If zero remain, say that every question is resolved from existing material, and stop this step.

Otherwise say how many questions need the user's input.

### Step 2: Ask One at a Time

For each open question, ask it in the question form of `.aid/runtime/templates/question-protocol.md`:
its category and importance label on the first line, the question, **Why I ask** (who injected it and
why it matters), **My recommendation** (its `suggested` answer), and the closing line that allows a
free answer, an explanation or a skip.

**Wait for the user's response before asking the next.**

### Step 3: Record

Record each outcome with `writeback-state.sh --answer` right after the user answers; the writer sets `answered_by`:

- **Skip:** `--answer --id Q<n> --state Skipped`. The question stays open and is offered again later.
- **Accept the suggestion:** `--answer --id Q<n> --state Answered --value '<suggested>'`.
- **The user's own answer:** `--answer --id Q<n> --state Answered --value '<text>'`.

**Write immediately.** Also update REQUIREMENTS.md with the answer content where relevant.

If the answer affects a feature that already exists, update that feature's `§ 11` section too
as the answer requires.

### Step 4: Continue Until Done

When all questions are addressed, say how many were answered and how many were skipped.

**Advance:** **CHAIN** → [State: CONTINUE] (continue inline).
