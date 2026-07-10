# task-010: pipeline-contracts.md aid-discover state-machine row update

**Type:** DOCUMENT

**Source:** work-002-external_sources -> delivery-001

**Depends on:** task-008

**Scope:**
- Update the `aid-discover` row in `.aid/knowledge/pipeline-contracts.md` `## Per-Skill State Machines` from `GENERATE -> REVIEW -> Q-AND-A -> FIX -> APPROVAL -> DONE` to `ELICIT -> GENERATE -> REVIEW -> Q-AND-A -> FIX -> APPROVAL -> DONE`.
- KB-internal edit (within `.aid/knowledge/`, the P7-allowed write zone); no P7 exemption needed.

**Acceptance Criteria:**
- [ ] The `aid-discover` state-machine row reads `ELICIT -> GENERATE -> …`, matching the shipped `aid-discover/SKILL.md` state machine (task-008)
- [ ] Accuracy verified against the as-authored `aid-discover/SKILL.md`
- [ ] All §6 quality gates pass
