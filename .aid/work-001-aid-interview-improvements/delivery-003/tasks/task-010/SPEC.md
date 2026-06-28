# task-010: Advisor-stance + NFR-7 question-envelope reference doc

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-003

**Depends on:** -- (none)

**Scope:**
- Author the new single-concern reference doc `canonical/skills/aid-interview/references/advisor-stance.md`
  (additive; not a fork). It is the engine's emission envelope + expert-advisor behavior, consumed by
  the engine driver (task-013).
- **NFR-7 question-envelope contract (AC-3):** encode the fixed three-part envelope exactly as the
  feature-002 SPEC specifies -- `{1-2 sentences of context, optional [From: .aid/knowledge/<doc>.md]}`
  / `{the question}` / `Suggested: {concrete proposed answer -- never blank, never "-"}` /
  `Why: {rationale grounded in the user's prior words, the KB, or expert judgment}` / the
  `[1] Accept this` / `[2] Not applicable` / `[3] Your answer: ___` choices.
- **Two enforcement mechanisms** (prose-executed, no machine run): (1) STRUCTURAL -- the envelope is
  the ONLY emission path; `Suggested:` and `Why:` are non-optional fields, a bare/empty-field question
  is a malformed emission; (2) SELF-CHECK -- the pre-emit gate that verifies both fields are present
  and concrete, and on a genuinely-open creative question proposes a best straw-man + states the
  uncertainty in `Why:` rather than falling back to a bare question.
- **Expert-advisor stance (NFR-1 / AC-4):** the five AC-4 user-move handlers, each STILL deferring the
  final decision to the user -- "I don't know" (guide/scaffold, offer straw-man default, mark as
  assumption if accepted, never record a blank); "what do you recommend?" (recommend as a real expert
  with rationale, no non-committal punt); "explain the pros and cons" (trade-offs at calibrated depth);
  "explain it like I'm a junior" (temporary novice-depth teach, then re-offer the question); a mistaken
  assertion (cordially disagree with reasons, never yes-man, return the call to the user).
- Single-concern per file; cross-references the engine driver (`elicitation-engine.md`), the move
  playbook (straw-man-first guarantees a suggestion exists), and `calibration.md` (calibrated depth)
  by path. ASCII-only.
- **Out of scope:** the seed content model / `source:` marker (feature-003); the routing decision
  (feature-004); editing any existing spine file (task-014); running the generator (task-017).

**Acceptance Criteria:**
- [ ] `references/advisor-stance.md` exists and reproduces the three-part NFR-7 envelope verbatim, with `Suggested:` and `Why:` documented as NON-OPTIONAL (a bare or empty-field question is stated to be unconstructable). *(AC-3 / NFR-7, gate criterion 1)*
- [ ] Both enforcement mechanisms (structural envelope-only emission + the pre-emit self-check, including the straw-man fallback for genuinely-open questions) are specified. *(AC-3)*
- [ ] All five AC-4 user moves ("I don't know" / "what do you recommend?" / "explain pros and cons" / "explain like a junior" / mistaken assertion) each have a concrete handler that explicitly DEFERS the final decision to the user (no silent assumption). *(AC-4, gate criterion 2)*
- [ ] Doc is single-concern (envelope + advisor stance only), cross-references the engine/playbook/calibration docs by real path, and is ASCII-only.
- [ ] Skill is prose-executed: no unit test is added (per the feature-002 DoD); the IMPLEMENT unit-test default is explicitly overridden by the structural + self-check enforcement above. Existing canonical tests are not touched (regression verified at task-018); generator render deferred to task-017.
- [ ] All REQUIREMENTS.md §6 quality gates pass.
