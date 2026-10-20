# State: DONE

Interview is complete, approved, features decomposed, and cross-references validated; offer to add information, re-validate, or close.

Tell the user, in one plain line, that the interview for {work} is complete and approved. Then ask one question, in
the protocol's form. Record it first with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --category Requirements --impact Low --context '<the question, as shown>' --suggested 'Done' --asked-by aid-define --step DONE` (it prints the question's id), and record the answer with `--answer --id <id>`:

```text
Requirements -- question 1 of 1 -- importance: low
Is there anything to add or check before I close this?
Why I ask: the requirements and features are complete and cross-referenced, so nothing more runs unless you ask.
My recommendation: nothing to add -- close it, and move on to the specification.
  1. Nothing to add, close it (recommended)
  2. Run the cross-reference validation again
  3. Add more information (reopen for additional input)
Or answer in your own words, ask me to explain, or skip this question.
```

- **Add more information:**
  - Ask, as a new question in the protocol's form (recorded first with `--ask`): "What would you like to add or change?"
  - If the user wants to change **requirements-level content** (Objective, Problem Statement,
    Functional Requirements, etc.) — say in one plain line that requirements-level changes are made in `/aid-describe {work}`, which reopens the requirements interview; then HALT.
  - Otherwise, record the user's input into the relevant REQUIREMENTS.md section, update
    `interview.sections[].state` (STATE.yml) if needed, update the affected §11 feature section
    files if the change impacts a feature, and update KB documents if the new info is KB-relevant.
  - Print: `✅ Updated.` and show the menu again.

- **Run the cross-reference validation again:**
  - Go on to CROSS-REFERENCE for a fresh validation pass

- **Nothing to add:**
  - Delete review ledgers:
    ```bash
    rm -f .aid/.temp/review-pending/interview-{work}-cross-ref.md
    rm -f .aid/.temp/review-pending/interview-{work}-lite.md
    rmdir --ignore-fail-on-non-empty .aid/.temp/review-pending/ 2>/dev/null || true
    ```
  - Print: `✅ Interview complete. Requirements approved. Ready for /aid-specify.`

The menu is a blocking question, asked through the question protocol: this step pauses on it until the user
answers. A requirements-level change hands off to `/aid-describe` in one plain line.

**Before the run ends (the HALT case below), record why it stops** through the writer, so the work is never left
`Running` with nothing running: `--pipeline --field Lifecycle --value Paused-Awaiting-Input`, then
`--pipeline --field "Pause Reason" --value '<why>'`. The reason is 'Requirements change requested -- run /aid-describe {work}'
after a requirements-level change, and 'Features defined and cross-referenced -- run /aid-specify {work}' after the user closes it.

**Advance:** **CHAIN** → [State: CROSS-REFERENCE] when the user picks [2]; **HALT** when the user picks another option.
