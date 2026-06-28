# task-011: Move-playbook reference doc (ten moves + gap-type firing table)

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-003

**Depends on:** -- (none)

**Scope:**
- Author the new single-concern reference doc `canonical/skills/aid-interview/references/move-playbook.md`
  (additive). It encodes the ten elicitation moves (findings.md RQ-B1) plus the gap-type -> move firing
  rule that the engine driver (task-013) consults in selection Step 3.
- **The ten moves**, each with its family origin: term-capture + disambiguation (DDD/UL, 1);
  boundary-elicitation (Context Modeling, 2); event-first / propose-timeline-back (Event Storming, 3);
  backbone-first + walking-skeleton (User-Story Mapping, 4 -- the move feature-004 leans on);
  rationale + testability probe (Volere, 5); bounded why-probe (climb 2-3 whys, propose the inferred
  motive back, stop at the terminal value -- NEVER the rote "five whys"; Laddering, 7);
  concrete-example probe (Example Mapping, 8); capture-and-defer / red-card (record to
  `STATE.md ## Cross-phase Q&A`, move on; Example Mapping, 8); straw-man-first (JAD, 6) and
  mediate-then-defer & scribe (JAD, 6) -- the latter two are NOT standalone gap responses but the
  DELIVERY ENVELOPE every other move is emitted through.
- **The gap-type -> move firing table** exactly per the feature-002 SPEC (undefined/ambiguous term ->
  term-capture; unnamed boundary -> boundary-elicitation; unknown behavior/flow -> event-first;
  unknown scope size / recipe signal -> backbone-first + walking-skeleton; missing fit criterion ->
  rationale + testability; missing "why" -> bounded why-probe; claim with no concrete example ->
  concrete-example probe; unsettleable point -> capture-and-defer; any turn / disagreement ->
  straw-man-first + mediate-then-defer wrapping). The findings RQ-B1 SEQUENCE is a DEFAULT, not a
  script (D2 / NFR-1 latitude); the table is the firing rule.
- Single-concern per file; cross-references `elicitation-engine.md` (the consumer of the firing table)
  and `advisor-stance.md` (straw-man-first / mediate-then-defer as the envelope) by real path.
  ASCII-only.
- **Out of scope:** the selector loop itself (task-013); calibration depth-shaping (task-012); the
  envelope template (task-010); generator render (task-017).

**Acceptance Criteria:**
- [ ] `references/move-playbook.md` exists and documents all TEN moves with their family origins exactly as the feature-002 SPEC names them, including the bounded why-probe's "NEVER rote five-whys" rule and the capture-and-defer red-card sink. *(D2, feature-002 Move Selection)*
- [ ] The gap-type -> move firing table is present and matches the feature-002 SPEC row-for-row; straw-man-first + mediate-then-defer are documented as the delivery ENVELOPE (not standalone responses). *(D2)*
- [ ] The doc states the RQ-B1 sequence is a default, not a script (selector-driven, not a fixed questionnaire). *(D1/D2, gate criterion 3)*
- [ ] Doc is single-concern, cross-references the engine + advisor docs by real path, and is ASCII-only.
- [ ] Skill is prose-executed: no unit test is added (per feature-002 DoD; IMPLEMENT unit-test default overridden). Existing canonical tests untouched (verified at task-018); render deferred to task-017.
- [ ] All REQUIREMENTS.md §6 quality gates pass.
