# State: CROSS-REFERENCE

Requirements are approved and features exist but cross-reference validation has not yet been completed; validate REQUIREMENTS.md against KB documents and codebase, grade findings, and create Q&A entries for gaps.

**Agent:** This is adversarial validation, not interview work. Dispatch with `subagent_type: reviewer` (overriding the default `interviewer`).

**Dispatch package:** render `references/reviewer-brief.md` with:
- `{{ARTIFACTS}}` = `.aid/{work}/REQUIREMENTS.md` + every `.aid/{work}/features/feature-*/SPEC.md` scaffold
- `{{CONTEXT}}` = `REQUIREMENTS.md was just approved and N features were decomposed from §5 Functional Requirements. This is the cross-reference pass that validates requirements + feature boundaries against the KB and codebase before any feature reaches /aid-specify.`

Then append the cross-reference process body from `references/cross-reference.md`
(load context, cross-reference, grade, present findings, create Q&A, wrap up) so
the subagent has the per-step execution detail.

Print before dispatch: `[State 6] Dispatching reviewer for Cross-Reference validation.`

▶ reviewer starting (~1–2 min)
Wait for completion.
✓ reviewer done (record actual time) — or ✗ reviewer failed: {reason}

**Advance:** Next state is `DONE` — when cross-reference completes, print `Next: [State: DONE] — run /aid-interview again` and exit.
