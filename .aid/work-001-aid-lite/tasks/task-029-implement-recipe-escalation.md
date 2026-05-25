# task-029: Implement recipe → standard-lite-path escalation (preserve slot values)

**Type:** IMPLEMENT

**Source:** feature-011-recipes → delivery-004

**Depends on:** task-017, task-028

**Scope:**
- Detect escalation trigger: user types `/aid-interview escalate-from-recipe` or selects escalate during slot-fill.
- Preserve slot values supplied so far in a new `## Recipe Slots` block in work-area `STATE.md` (one bullet per filled slot: `- {slot-name}: {value}`).
- Seed the standard lite-path interview's first questions with the preserved slot values.
- Standard lite-path sub-path (per feature-005) takes over from there.
- Escalation can chain: recipe → standard-lite → full path (via FR1 escalation, task-017).

**Acceptance Criteria:**
- [ ] Escalation triggers cleanly from any point during slot-fill.
- [ ] `## Recipe Slots` block in `STATE.md` contains all slot values filled before escalation.
- [ ] Standard lite-path interview's first questions accept the preserved slot values as default answers.
- [ ] Two-step escalation (recipe → standard-lite → full) chains correctly without losing any captured info.
- [ ] Unit tests for the carry block + escalation chain.
- [ ] All §6 quality gates pass.
