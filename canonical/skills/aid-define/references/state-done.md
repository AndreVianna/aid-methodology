# State: DONE

Interview is complete, approved, features decomposed, and cross-references validated; offer to add information, re-validate, or close.

Print:

```
Interview for {work} is complete and approved.

[1] Add more information — reopen for additional input
[2] Re-run cross-reference validation
[3] Done — nothing to add
```

- **[1] Add more information:**
  - Ask: _"What would you like to add or change?"_
  - If the user wants to change **requirements-level content** (Objective, Problem Statement,
    Functional Requirements, etc.) — print: `For requirements-level changes, run
    /aid-describe {work} to reopen the requirements interview.` then HALT.
  - Otherwise, record the user's input into the relevant REQUIREMENTS.md section, update
    `interview.sections[].state` (STATE.yml) if needed, update the affected §11 feature section
    files if the change impacts a feature, and update KB documents if the new info is KB-relevant.
  - Print: `✅ Updated. Run /aid-define {work} again to re-validate.`

- **[2] Re-run cross-reference:**
  - Proceed to State 6 (CROSS-REFERENCE) for a fresh validation pass

- **[3] Done:**
  - Delete review ledgers:
    ```bash
    rm -f .aid/.temp/review-pending/interview-{work}-cross-ref.md
    rm -f .aid/.temp/review-pending/interview-{work}-lite.md
    rmdir --ignore-fail-on-non-empty .aid/.temp/review-pending/ 2>/dev/null || true
    ```
  - Print: `✅ Interview complete. Requirements approved. Ready for /aid-specify.`

The menu is a blocking question, asked through the question protocol: this step pauses on it until the user
answers. A requirements-level change hands off to `/aid-describe` in one plain line. Run `/aid-define` again
only to add information or re-validate.

**Advance:** **CHAIN** → [State: CROSS-REFERENCE] when the user picks [2]; **HALT** when the user picks another option. This is the terminal state.
