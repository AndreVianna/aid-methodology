# State: CROSS-REFERENCE

Requirements are approved and features exist but cross-reference validation has not yet been completed; validate REQUIREMENTS.md against KB documents and codebase, grade findings, and record a question for each gap.

**Agent:** Adversarial validation. Dispatch with `subagent_type: aid-reviewer` **at Large tier** — the features were decomposed by the Large `aid-architect`, so reviewer tier >= executor tier (`.aid/runtime/templates/agent-dispatch-tiering.md`).

**Dispatch package:** render `references/reviewer-brief.md` with:
- `{{ARTIFACTS}}` = `.aid/works/{work}/REQUIREMENTS.md` (including `§11 Features`, one subsection per feature)
- `{{CONTEXT}}` = `REQUIREMENTS.md was just approved and N features were decomposed from §5 Functional Requirements. This is the cross-reference pass that validates requirements + feature boundaries against the KB and codebase before any feature reaches /aid-specify.`

Include in the brief file (not in the dispatch prompt — `reviewer-dispatch.md` § Dispatch by path):
- **Ledger lifecycle:** "Append new findings as rows with Status: Pending to
  `.aid/.temp/review-pending/interview-<work>-cross-ref.md`. Read the existing file
  first if it exists. Output per `.aid/runtime/templates/reviewer-ledger-schema.md` —
  ONE table, no narrative. After writing the ledger, run:
  `bash .aid/runtime/scripts/grade.sh .aid/.temp/review-pending/interview-<work>-cross-ref.md`
  and include the grade in your return message."

Then append the reviewer's share of the process body from `references/cross-reference.md`
(sections 6a to 6c: load context, cross-reference, grade) so the subagent has the per-step execution
detail. Sections 6d to 6f are the main conversation's: it presents the findings, records each question
with `writeback-state.sh --ask`, asks them through the question protocol, and wraps up. The subagent never
asks; it lists its open questions in its report.

▶ aid-reviewer starting (~1–2 min)
Wait for completion. If it fails, say why in one plain line.

After aid-reviewer returns, run grade.sh on the ledger to confirm the grade:

```bash
bash .aid/runtime/scripts/grade.sh --explain .aid/.temp/review-pending/interview-<work>-cross-ref.md
```

**Cycle 1 also runs the cross-document contradiction pass (Guard 2).** This review receives
every artifact of the phase at once, which is the only vantage point from which a
contradiction between two of them is visible. Run it on cycle 1 only -- that makes it
once per phase by construction. Definition:
`reviewer-dispatch.md` section "The cross-document contradiction pass (Guard 2)".

The cross-reference questions pause this step where it stands (a blocking question). After each answer the step
applies it (`cross-reference.md` § 6e) and, once every question is answered or skipped, records the cross-reference
(§ 6f); only then does the step end.

**Advance:** **CHAIN** → [State: DONE] once the cross-reference questions are answered and their answers applied.
