# State: CROSS-REFERENCE

Requirements are approved and features exist but cross-reference validation has not yet been completed; validate REQUIREMENTS.md against KB documents and codebase, grade findings, and create Q&A entries for gaps.

**Agent:** This is adversarial validation, not interview work. Dispatch with `subagent_type: aid-reviewer` (overriding the default `aid-interviewer`) **at Large tier** — the features were decomposed by the Large `aid-architect`, so reviewer tier >= executor tier (`.claude/aid/templates/agent-dispatch-tiering.md`).

**Dispatch package:** render `references/reviewer-brief.md` with:
- `{{ARTIFACTS}}` = `.aid/works/{work}/REQUIREMENTS.md` + every `.aid/works/{work}/features/feature-*/SPEC.md` scaffold
- `{{CONTEXT}}` = `REQUIREMENTS.md was just approved and N features were decomposed from §5 Functional Requirements. This is the cross-reference pass that validates requirements + feature boundaries against the KB and codebase before any feature reaches /aid-specify.`

Include in the prompt:
- **Ledger lifecycle:** "Append new findings as rows with Status: Pending to
  `.aid/.temp/review-pending/interview-<work>-cross-ref.md`. Read the existing file
  first if it exists. Output per `.claude/aid/templates/reviewer-ledger-schema.md` —
  ONE table, no narrative. After writing the ledger, run:
  `bash .claude/aid/scripts/grade.sh .aid/.temp/review-pending/interview-<work>-cross-ref.md`
  and include the grade in your return message."

Then append the cross-reference process body from `references/cross-reference.md`
(load context, cross-reference, grade, present findings, create Q&A, wrap up) so
the subagent has the per-step execution detail.

Print before dispatch: `[State 6] Dispatching aid-reviewer for Cross-Reference validation.`

▶ aid-reviewer starting (~1–2 min)
Wait for completion.
✓ aid-reviewer done (record actual time) — or ✗ aid-reviewer failed: {reason}

After aid-reviewer returns, run grade.sh on the ledger to confirm the grade:

```bash
bash .claude/aid/scripts/grade.sh --explain .aid/.temp/review-pending/interview-<work>-cross-ref.md
```

**Advance:** **CHAIN** → [State: DONE] when cross-reference completes (continue inline).
