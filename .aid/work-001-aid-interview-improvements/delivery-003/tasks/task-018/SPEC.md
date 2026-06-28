# task-018: Delivery-003 verification -- brownfield tests + dogfood-transcript review

**Type:** TEST

**Source:** work-001-aid-interview-improvements -> delivery-003

**Depends on:** task-017

**Scope:**
- Verify delivery-003 against its gate criteria. Skills are prose-executed and not unit-tested by
  design, so this task combines (A) running the EXISTING brownfield canonical tests (which must still
  pass) with (B) the AID AI + human-review DoD via dogfood transcripts + the reviewer checklist. It
  authors no new skill content.
- **(A) Brownfield-intact regression (AC-10 / NFR-2):** run `tests/canonical/test-parse-recipe.sh`
  (19 units) and `tests/canonical/test-recon-classify.sh`, plus the path/walkthrough fixtures, HOME-pinned;
  all must pass. Confirm `parse-recipe.sh`, `recon-classify.sh`, the recipe set, and `aid-discover` are
  untouched (diff) and the `state-triage.md` "Unit-testable mapping rules" routing/override/recipe-offer
  tables still hold (feature-004 D3 -- the route is byte-unchanged). Run the master-only heavy gates
  locally: `tests/run-all.sh` (HOME-pinned) and the `site` Astro build.
- **(B) AC-3 no-bare-question scan:** produce / review dogfood transcripts and confirm EVERY emitted
  question turn (every line ending in `?` soliciting a user answer) carries a non-empty `Suggested:` and
  `Why:`; the fixed opener carries its example + cue. Any bare question is a FAIL.
- **(B) AC-4 calibration + advisor:** produce two transcripts on the SAME prompt -- one EXPERT persona,
  one NOVICE persona -- demonstrating (a) the explicit knowledge-level follow-up fired as an early
  follow-up (never turn 1) carrying an NFR-7 envelope, and (b) demonstrable depth divergence (expert =
  fewer why-steps / lighter confirms; novice = draws out, teaches, more example-probes) so the two read
  as different conversations. Each of the five AC-4 user moves ("I don't know", "what do you recommend?",
  "explain pros/cons", "explain like a junior", a mistaken assertion) appears at least once and shows
  the engine guiding/recommending/explaining/disagreeing WHILE deferring the final decision.
- **(B) Engine-not-form (D1/D2/NFR-4):** reviewer reads `elicitation-engine.md` to confirm exactly ONE
  fixed turn (the D1 opener), every later turn selector-driven (no hidden questionnaire), and the loop
  halting at minimal-but-sufficient (grill-me "every branch" anti-pattern absent).
- **(B) Triage (AC-7 / FR-5) + opener de-dup:** triage transcripts -- one on a full brownfield KB, one on
  a seed KB -- showing the opener fired ONCE, gap-targeted draw-out skipping what the KB answers, and a
  correct route; plus one single-slice -> lite+recipe and one sprawling-backbone -> full; plus a
  TRIAGE -> CONTINUE transcript where the D1 opener appears EXACTLY ONCE (CONTINUE enters the loop with
  the opener answer; the no-`**Opener:**` fallback emits it).
- Record results to this task's STATE.md / the delivery gate; file any [HIGH]/[CRITICAL] findings per the
  ledger schema. Out of scope: fixing content defects (loop back to the owning task 010-016).

**Acceptance Criteria:**
- [ ] `tests/canonical/test-parse-recipe.sh` (19 units) and `tests/canonical/test-recon-classify.sh` pass HOME-pinned; the path/walkthrough fixtures pass; `parse-recipe.sh` / `recon-classify.sh` / recipe set / aid-discover confirmed untouched; the `state-triage.md` routing/override/recipe-offer tables still hold. *(AC-10 / NFR-2, gate criterion 5; feature-004 D3/D4)*
- [ ] AC-3 transcript scan: zero bare questions -- every question turn carries a non-empty `Suggested:` + `Why:`, opener included. *(AC-3, gate criterion 1)*
- [ ] AC-4: the expert and novice transcripts show the early (non-turn-1) NFR-7 calibration ask AND demonstrable depth divergence; all five AC-4 user moves appear and each defers the decision to the user. *(AC-4, gate criterion 2)*
- [ ] Engine-not-form confirmed: one fixed opener, selector-driven thereafter, stops at minimal-but-sufficient (no grill-me "every branch"). *(D1/D2/NFR-4, gate criterion 3)*
- [ ] Triage verified in BOTH full-KB and seed-KB contexts with correct routes (lite+recipe and full cases), and the D1 opener appears exactly once across TRIAGE -> CONTINUE (with the fallback emitting it when `**Opener:**` is absent). *(AC-7 / FR-5, gate criterion 4)*
- [ ] Master-only heavy gates pass locally: `tests/run-all.sh` (HOME-pinned) and the `site` Astro build. *(gate criterion 6)*
- [ ] Tests are deterministic with clean setup/teardown; all delivery-003 gate criteria and the source-feature ACs (feature-002 AC-3/AC-4/engine-integrity; feature-004 AC-7/AC-10) are covered. *(TEST defaults)*
