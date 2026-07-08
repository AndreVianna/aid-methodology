# task-008: ELICIT discover state and aid-discover state-machine wiring

**Type:** IMPLEMENT

**Source:** work-002-external_sources -> delivery-001

**Depends on:** task-002, task-005, task-006, task-007

**Scope:**
- New `canonical/skills/aid-discover/references/state-elicit.md` holding the E0–E3 flow: E0 idempotent re-entry off the `## Discovery Elicitation` block; E1 external-sources branch (PAUSE-FOR-USER-DECISION; feeds STATE.md `## External Documentation`; resets `external-sources.md` to `Pending` on change); E2 tool-integrations branch (PAUSE; preset from task-007's catalog or `custom`; descriptor write with `.aid/connectors/.gitignore`-first ordering; hands the secret VALUE to task-006's `write` op; triggers task-005's INDEX builder); E3 record + CHAIN -> GENERATE.
- Wire `ELICIT` into `canonical/skills/aid-discover/SKILL.md` at all ~8 sites: the frontmatter `description` state-machine line, the state-machine banner, State Detection (new `State 0`), the Dispatch table row (inline worker -> GENERATE), the six per-state "you are here" maps, and a new `ELICIT` state-entry block.
- **Q9 skip-vs-empty marker (STATE.md Q9):** the `## Discovery Elicitation` record MUST encode an explicit tool-step marker distinguishing `SKIPPED` (the tool step was not engaged) from `DECLARED-EMPTY` (the step was engaged and zero tools were declared), so reconcile (task-018) can branch on it. Ambiguous source/tool entries become `## Q&A (Pending)` entries (Category `Source` / `Integration`), never guesses.
- The `mcp` -> host-wiring trigger is left as a delivery-002 hook (task-016); this task wires no hosts. Renders to all 5 profiles.

**Acceptance Criteria:**
- [ ] State Detection selects `ELICIT` (State 0) when `## Discovery Elicitation` is absent or `Resolved: no`, and falls through to States 1–6 once `Resolved: yes`
- [ ] E1 and E2 are genuine PAUSE-FOR-USER-DECISION gates; both branches are skippable and write no empty artifacts (no `external-sources.md` change and no `.aid/connectors/` tree when skipped)
- [ ] The `## Discovery Elicitation` record encodes the Q9 tool-step marker `SKIPPED` vs `DECLARED-EMPTY`, distinct from the `Sources` / `Tools` / `Resolved` fields
- [ ] On a confirmed tool, the descriptor is written after `.aid/connectors/.gitignore` (first action), the secret value is handed to task-006's `write` op (reference-not-value in the descriptor), and task-005's INDEX builder is triggered
- [ ] All ~8 SKILL.md sites carry the `ELICIT` prepend/entry; the change renders identically into all 5 profiles
- [ ] New/changed skill prose has no unit-testable surface; existing aid-discover suites + dogfood byte-identity checks pass; build/render passes
- [ ] All §6 quality gates pass
