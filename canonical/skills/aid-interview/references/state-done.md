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
  - Record the user's input into the relevant REQUIREMENTS.md section
  - Update STATE.md `## Interview Status` section statuses if needed
  - Update affected feature SPEC.md files if the change impacts a feature
  - Update KB documents if the new info is KB-relevant
  - Print: `✅ Updated. Run /aid-interview {work} again to re-validate.`

- **[2] Re-run cross-reference:**
  - Proceed to State 6 (CROSS-REFERENCE) for a fresh validation pass

- **[3] Done:**
  - Print: `✅ Interview complete. Requirements approved. Ready for /aid-specify.`

**Advance:** → halt. This is the terminal state. Run `/aid-interview` again only to add information or re-validate.
