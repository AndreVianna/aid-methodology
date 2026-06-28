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
    /aid-describe {work} to reopen the requirements interview.` and exit.
  - Otherwise, record the user's input into the relevant REQUIREMENTS.md section, update
    STATE.md `## Interview State` section statuses if needed, update affected feature SPEC.md
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

**Advance:** **HALT**. This is the terminal state. Run `/aid-define` again only to add information or re-validate.
