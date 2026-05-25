# task-017: Implement lite → full path escalation (preserve captured info)

**Type:** IMPLEMENT

**Source:** feature-005-lite-path → delivery-002

**Depends on:** task-014, task-016

**Scope:**
- Detect escalation trigger: user types `/aid-interview escalate` or selects escalate option mid-sub-path.
- On escalate: change `Path` from lite to escalated in `## Triage`; preserve all captured prompts (sub-path answers, slot values) in a `## Escalation Carry` block of work-area `STATE.md`.
- Re-enter the full-path Interview flow at CONTINUE (State 3 — Q-AND-A is State 2 post-thin-router; CONTINUE is where the agent resumes incomplete REQUIREMENTS.md sections); seed first questions from the carried answers.
- Lite-path output files (work-root SPEC.md, tasks/) are converted to full-path layout (per-feature folder structure).

**Acceptance Criteria:**
- [ ] Escalation triggers cleanly from any sub-path mid-flow without crash.
- [ ] Captured information (prompts already answered) is preserved in `## Escalation Carry` block.
- [ ] Full-path Interview resumes at CONTINUE (State 3 — post-thin-router; not State 1) with carried answers visible.
- [ ] Lite-path artifacts (work-root SPEC, tasks/) are converted to full-path equivalents (feature folders, per-feature SPECs, PLAN.md placeholder); user does not lose info.
- [ ] Reverse not implemented (no full → lite escalation; per FR1 scope).
- [ ] Unit tests for the carry + reflow logic.
- [ ] All §6 quality gates pass.
