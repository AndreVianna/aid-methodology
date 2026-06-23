# task-013: Calibration rubric dimension + finding tags in review-rubric.md

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-001

**Depends on:** task-008

**Scope:**
- Add the new "Calibration (summary vs transcription)" section to
  `canonical/aid/templates/kb-authoring/review-rubric.md`, after the Full Primary rubric
  (Full-Primary-only dimension). Author the four checks: CAL-1 Transcription (too fat, anchored to
  `closure-check.sh` output (c) transcription-ratio; `[MEDIUM]` `[CAL-TRANSCRIPTION]`), CAL-2
  Hollowness (too thin, `sources:`-vs-body ratio; `[MEDIUM]` `[CAL-HOLLOW]`), CAL-3 Coverage-vs-source
  (a `sources:` fact absent from the doc, anchored to `closure-check.sh` output (b) `absent` rows;
  `[HIGH]` `[CAL-COVERAGE]`), CAL-4 Deferral-must-point (`[LOW]` `[CAL-DEFERRAL]`). Author the
  round-trip test (forward orientation / reverse coverage -> output (b) / transcription scan ->
  output (c)) as the operationalization. Note URL `sources:` -> N/A in (b)/(c).
- Add the new finding tags to the "Lint output -> severity mapping" table reusing the existing
  `[SEVERITY] [TAG] <description>` convention: `[CLOSURE-GAP]` (HIGH), `[CAL-TRANSCRIPTION]` (MEDIUM),
  `[CAL-HOLLOW]` (MEDIUM), `[CAL-COVERAGE]` (HIGH), `[CAL-DEFERRAL]` (LOW), `[TEACHBACK]` (HIGH). These
  are description-side tags; `grade.sh` still counts only the Severity column -- NO `grade.sh` change.
- The exact `[MEDIUM]`-vs-`[HIGH]` cut for transcription/hollowness is the SHAPE only; the floor is
  f012-calibrated (delivery-005) -- author the tags/checks, not the tuned threshold.
- Edit canonical only; re-run `run_generator.py`; commit regenerated `profiles/`.

**Acceptance Criteria:**
- [ ] `review-rubric.md` has a new Calibration section (CAL-1..CAL-4) after Full Primary, each check
  with its definition, evidence anchor (output (b)/(c) where applicable), and severity.
- [ ] The round-trip test (forward orientation / reverse coverage / transcription scan) is documented,
  with reverse coverage anchored to output (b) and transcription scan to output (c); URL `sources:`
  noted as N/A in both.
- [ ] The "Lint output -> severity mapping" table gains `[CLOSURE-GAP]` (HIGH), `[CAL-TRANSCRIPTION]`
  (MEDIUM), `[CAL-HOLLOW]` (MEDIUM), `[CAL-COVERAGE]` (HIGH), `[CAL-DEFERRAL]` (LOW), `[TEACHBACK]`
  (HIGH) as description-side tags.
- [ ] No `grade.sh` change; the category routing and existing rubrics are unchanged.
- [ ] `run_generator.py` re-run; regenerated `profiles/` committed (render-drift green).
- [ ] All section-6 quality gates pass.
