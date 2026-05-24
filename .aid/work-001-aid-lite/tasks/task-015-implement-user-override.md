# task-015: Implement user-override mechanism on triage turn

**Type:** IMPLEMENT

**Source:** feature-005-lite-path → delivery-002

**Depends on:** task-014

**Scope:**
- After triage emits its auto-selected Sub-path, present the choice to the user with options: [1] Proceed, [2] Use different sub-path (a/b/c), [3] Escalate to full.
- If overridden: record `Sub-path (auto)` (the original auto value) and set `Override: yes` in `## Triage`.
- If user selects [3] Escalate: set Path=full + **omit Sub-path field** (no n/a placeholder — matches task-014's contract: full-route Sub-path field is absent) + record escalation rationale.
- Final Sub-path field always reflects the user's chosen sub-path.

**Acceptance Criteria:**
- [ ] On-same-triage-turn UX (no separate skill re-invocation needed for override).
- [ ] Auto-selected sub-path always shown to user before sub-path-specific work begins.
- [ ] Override recorded with both auto and final values in `## Triage`.
- [ ] Escalate-to-full path sets Path=full + records rationale.
- [ ] Unit tests for each override path.
- [ ] All §6 quality gates pass.
