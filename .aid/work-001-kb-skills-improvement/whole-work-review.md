# Whole-Work Review — work-001-kb-skills-improvement

**Date:** 2026-06-23
**Scope:** Holistic A+ gate over the entire 12-feature spec set (beyond the per-feature gates),
on two axes the user named: **over-engineering** and **intent-correspondence**, plus
cross-feature coherence. Three adversarial reviewers (one per lens); findings deduped + synthesized.

Ledgers: `.aid/.temp/review-pending/whole-work-{overengineering,intent,coherence}.md`.

## Verdict

**Strong, disciplined design (≈A-/B+ as a whole) — not slop, not wholesale over-engineered —
but not A+ until one intent gap + localized over-build + two unowned seams are closed.**

- **Over-engineering:** proportionate CORE (f001 `sources:` / f002 INDEX / f004 harvest+closure),
  over-built PERIPHERY (validation + adaptivity scaffolding). No new runtime anywhere — bare-box
  ethos honored.
- **Intent-fidelity:** faithful on 7 of 8 threads. One real gap at the conceptual heart (below).
- **Coherence:** acyclic, buildable, single-producer primitives. Two unowned cross-feature seams.

## Disposition of findings

### FIXED in this revision pass (spec edits)

| # | Finding (lens) | Sev | Resolution | Owner |
|---|----------------|-----|------------|-------|
| 1 | **Essence delivered as LEXICAL harvest only** — a tokenless idea (the hardest 'Relative bus' case, §1.2) clears neither the phrase floor nor closure, and teach-back never asks. (intent) | HIGH | **Add a non-lexical limb** [user decision]: f004 gains a researcher/architect **conceptual-synthesis** candidate channel (concepts w/o a recurring token, evidence-anchored to source spans); f005 teach-back gains an open **engine-narration** question graded as a first-class FAIL independent of the term quiz. | f004 + f005 |
| 2 | **f004↔f006 closure-cap contradiction** — f004's "2-level `read-setting.sh` read works" claim is provably wrong; nobody owns the override arg. (coherence) | HIGH | f004 corrects the claim + **owns the cap-override runtime-arg** interface (Step-5b); f006 supplies it from path-config. | f004 |
| 3 | **f005↔f008 REVIEW parameterization unowned** — update-kb needs f005's `<scope>`/`doc_set` injectable; neither spec lists it. (coherence) | HIGH | **f005 owns** exposing ledger-scope + doc-set as injectable params as a listed deliverable. | f005 |
| 4 | **`kb-salient-coverage.sh` duplicates `closure-check.sh`** — same inputs, same term-presence scan. (over-eng) | HIGH | **Merge into one coverage oracle**: f004's `closure-check.sh` emits BOTH the ungrounded set AND the per-doc coverage list; f005 drops its script + consumes f004's. | f004 + f005 |
| 5 | **Greenfield over-built** — a Could threaded through the whole engine (matrix column, mini-panel, closure redefinition, orphaned intent-vs-as-built verifier). (over-eng + intent) | MED | **Keep but simplify** [user decision]: greenfield = elicit via existing `aid-interview`/`aid-specify` → standard engine; DROP the bespoke verifier (re-triage handles transition) + the closure redefinition (same closure, elicited not extracted). | f006 |
| 6 | **Teach-back double-encoded** — boolean sentinel AND grade-forcing rows + ~80 lines reconciling them. (over-eng) | MED | **Collapse to one mechanism**: keep `[HIGH][TEACHBACK]` rows (already force grade ≤ D via grade.sh); drop the sentinel + AND. | f005 |
| 7 | **Panel-collapse may undo f005's anti-P2 split** (SPIKE-T3 only asks). (coherence) | MED | **Adjudicated**: collapsed reviewer runs mandates as separate SEQUENTIAL passes within one agent (no blending → anti-P2 preserved), not a blended judgment. | f006 |

### CARRIED to /aid-plan (not spec defects — planning/packaging/impl decisions)

- **MERGE f008 + f009 into ONE delivery.** They can never ship independently (shared branch/PR,
  render-drift RED on f008 alone, "no release tag between them"). Plan them as a single deliverable.
  Effective decomposition = 11, not 12.
- **Shared-lib dedup (impl-time):** `is_source` (3×) and `extract_list` (f001/f002/f004/f006) are
  hand-duplicated with lockstep fixtures on a false "bash can't source functions" claim. Implementation
  should expose one sourced lib (f001-owned) the others source. LOW; deferred to keep this revision
  focused (and to avoid adding a shared-lib layer speculatively before the consumers are built).
- **Salience weighting:** the `freq*(1+2*(spread-1))` curve's hardcoded `2` is invented latitude;
  validate the ranking against f012's fixture rather than asserting the constant.
- **Skill-count drift CI guard:** 4 skill-count populations across ~24 surfaces are unguarded by CI;
  f009's count reconciliation is manual-correctness. Consider a count-consistency check.
- **f006 thresholds stay configurable** (user approved at /aid-specify); the over-eng reviewer's
  "hardcode them" suggestion is noted but NOT applied — reversing a user decision.

### ACCEPTED (in-scope by necessity / delivered-by-principle)

- **f009 has no FR of its own** — it exists for AID's ship machinery (render/manifest/count drift).
  In-scope by necessity, not intent. Acceptable.
- **Audience/mixed-audience dimension** faded from first-class to optional frontmatter + an INDEX
  filter column. Defensible: summary+pointer is the agreed resolution of the audience fork.

## User decisions recorded

1. **Essence depth → ADD a non-lexical limb** (close the conceptual-essence gap). → finding #1.
2. **Greenfield → KEEP but SIMPLIFY** (interview/specify reuse, no bespoke verifier). → finding #5.

## Re-gate result (2026-06-23)

The 7 fixed findings were applied across f004/f005/f006 + REQUIREMENTS + upper sections, then
re-gated. The conceptual limb re-gated **SOUND** (closes the tokenless-essence gap; anchoring
non-hallucinatable; teach-back single-encoding preserves AC1). The merge initially created a
`closure-check.sh` 3-output **contract mismatch** between f004 and f005 (caught at re-gate, D/D+)
— reconciled to one explicit contract (a: ungrounded set / b: `sources:`-anchored coverage,
`absent`=finding / c: transcription-ratio; URL→N/A), and f006/REQUIREMENTS stale text (matrix
cells + f004 cross-refs) cleaned. **Final: f004/f005/f006 all A+; all 12 features Ready/A+.**
