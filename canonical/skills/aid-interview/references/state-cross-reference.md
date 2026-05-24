# State: CROSS-REFERENCE

Requirements are approved and features exist but cross-reference validation has not yet been completed; validate REQUIREMENTS.md against KB documents and codebase, grade findings, and create Q&A entries for gaps.

**Agent:** This is adversarial validation, not interview work. Dispatch with `subagent_type: reviewer` (overriding the default `interviewer`). Print before dispatch: `[State 6] Dispatching reviewer for Cross-Reference validation.`

▶ reviewer starting (~1–2 min)
Read `references/cross-reference.md` for the full cross-reference validation process
(load context, cross-reference, grade, present findings, create Q&A, wrap up).
✓ reviewer done (record actual time) — or ✗ reviewer failed: {reason}

**Advance:** Next state is `DONE` — when cross-reference completes, print `Next: [State: DONE] — run /aid-interview again` and exit.
