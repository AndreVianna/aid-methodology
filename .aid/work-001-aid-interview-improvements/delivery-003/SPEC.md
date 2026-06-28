# Delivery SPEC -- delivery-003: Seasoned-Analyst Engine + Guided Triage

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-NNN/STATE.md.

> **Delivery:** delivery-003
> **Work:** work-001-aid-interview-improvements
> **Created:** 2026-06-27

---

## Objective

Deliver the conversational core of the work: the seasoned-analyst elicitation engine plus
analyst-driven guided triage, as an in-place extension of the `aid-interview` skill. Together they
turn the interview from a passive transcriber / rigid questionnaire into a seasoned analyst -- one
fixed "what+why" opener then adaptive, gap-driven next-move selection, with calibration, an
expert-advisor stance, and a suggested-answer-+-rationale on every question. This delivery ships
first because the engine improves the interview for EVERY user (brownfield and greenfield), and it
is the shared substrate that the greenfield seed (delivery-004) and the split (delivery-006) build on.

## Scope

- **feature-002-seasoned-analyst-engine:** the engine -- D1 fixed opener + D2 adaptive 5-step
  next-move selector, read+ask calibration, expert-advisor stance, the NFR-7 question-envelope
  contract, in-place extension of the aid-interview spine, and the 3-parameter consumption contract.
- **feature-004-guided-triage:** analyst-driven triage that consumes the engine -- draws out the
  path (full vs lite) + recipe-deciding signals, KB-context-aware (full / seed / no KB), reuses the
  existing routing rule + recipe tooling, and resolves the 002/004 opener seam (the single D1 opener
  fires once in TRIAGE, carried forward so CONTINUE does not re-ask).

**Out of scope:** the greenfield seed model / marker / gate / coherence (delivery-004, feature-003);
the conformance check (delivery-005); the aid-describe/aid-define split (delivery-006). No skill
RENAME or directory restructure here -- this is purely behavioral, in place.

## Gate Criteria

- [ ] Every question the analyst emits carries a concrete suggested answer + rationale (NFR-7 / AC-3) -- no bare questions.
- [ ] A new session asks the user's knowledge level/type and demonstrably adapts question depth/style (AC-4); the expert-advisor behaviors ("I don't know" / "what do you recommend?" / "explain like a junior" / cordial disagreement) all defer the final decision to the user.
- [ ] The engine is adaptive (one fixed opener + selector-driven), stops at minimal-but-sufficient, not a fixed questionnaire (D1/D2).
- [ ] Guided triage draws out the path + recipe signals and routes correctly in BOTH full-KB and seed-KB contexts (AC-7); the single D1 opener is not double-asked across TRIAGE -> CONTINUE.
- [ ] The existing brownfield aid-discover + standard-interview path still passes its tests (AC-10 / NFR-2): `test-parse-recipe.sh`, `test-recon-classify.sh`, path/walkthrough fixtures.
- [ ] All section-6 quality gates pass (incl. the master-only heavy gates: `tests/run-all.sh` HOME-pinned + the `site` Astro build).

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-010 | IMPLEMENT | Advisor-stance + NFR-7 question-envelope reference doc |
| task-011 | IMPLEMENT | Move-playbook reference doc (ten moves + gap-type firing table) |
| task-012 | IMPLEMENT | Calibration reference doc (read+ask, depth-shaping) |
| task-013 | IMPLEMENT | Elicitation-engine driver reference doc (opener + 5-step selector) |
| task-014 | IMPLEMENT | In-place engine wiring of the aid-interview spine |
| task-015 | IMPLEMENT | Engine-driven guided triage in state-triage.md |
| task-016 | IMPLEMENT | Opener-seam de-dup in state-continue.md |
| task-017 | CONFIGURE | Full generator render + 5-profile/.claude propagation |
| task-018 | TEST | Delivery-003 verification -- brownfield tests + dogfood-transcript review |
| task-041 | IMPLEMENT | Anti-anchoring guard + read-back + verbatim-wording hardening (web-validation) |

## Dependencies

- **Depends on:** -- (extends the current skill; builds on the executed delivery-001 findings + delivery-002 infra)
- **Blocks:** delivery-004 (the engine elicits the seed), delivery-006 (the split operates on this content)

## Notes

In-place edits to `canonical/skills/aid-interview/` (C-2 extend-don't-fork). Strictly sequential with
delivery-004 + delivery-006 (same skill dir). Per D3 the engine + triage are destined for the
`aid-describe` side of the eventual split, but THIS delivery does not split -- it lands the behavior
in the current single skill.
