# task-035: Conformance discoverability signpost in aid-execute delivery-gate


**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-005

**Depends on:** -- (none; edits a file no other delivery-005 task touches -- wave 1)

**Scope:**
- Add a one-line, NON-mechanistic SIGNPOST to
  `canonical/skills/aid-execute/references/state-delivery-gate.md`: when a delivery touched code
  under a forward-authored design (a `source: forward-authored` doc exists in the work's KB), the
  delivery-gate prints a pointer such as "forward-authored design present -- run `/aid-housekeep` to
  check code->design conformance." Per the feature-005 Layers table row, this is a **Secondary
  (optional) signpost only -- no mechanism here**.
- Discoverability ONLY: the actual conformance check lives in the aid-housekeep KB-DELTA conformance
  lane (delivery-005 tasks 028-031). This task adds NO gate, NO mechanism, NO blocking behavior, and
  does NOT alter the delivery-gate's existing routing or grade logic.
- Match the existing `state-delivery-gate.md` prose conventions (it already routes KB issues to
  `/aid-discover` via Q&A -- mirror that signpost style).

**Acceptance Criteria:**
- [ ] `state-delivery-gate.md` prints the conformance signpost when a `source: forward-authored` doc is present in the work's KB, and prints nothing extra otherwise (purely additive). *(feature-005 Layers "optional signpost")*
- [ ] NO mechanism / gate / blocking behavior added; the existing delivery-gate routing + grade logic is unchanged (verify via `git diff` -- only the additive signpost lines). *(scope boundary)*
- [ ] Skill-prose authoring: the IMPLEMENT unit-test default is OVERRIDDEN (the skill is prose-executed, not unit-tested; the additive signpost is exercised in the task-034 conformance-lane verification / dogfood review). *(prose-skill override, per the d004/d005 precedent)*
- [ ] ASCII-only; the canonical edit is propagated to the 5 profiles + `.claude` mirror by task-032 (render). *(render-drift / DBI)*
- [ ] All REQUIREMENTS.md §6 quality gates pass.
