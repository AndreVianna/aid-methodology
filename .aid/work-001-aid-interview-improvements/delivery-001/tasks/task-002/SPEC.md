# task-002: grill-me question-driven elicitation comparative

**Type:** RESEARCH

**Source:** work-001-aid-interview-improvements -> delivery-001

**Depends on:** -- (none; independent of and parallel with task-001)

**Scope:**
- Research the web-trending `grill-me` question-driven elicitation approach (and similar variants)
  for GENERAL requirements gathering -- not only greenfield. Deliver: (1) what it is and how it
  works; (2) strengths + weaknesses; (3) a head-to-head comparison with AID's seasoned-analyst
  elicitation; (4) an explicit adopt-vs-avoid list (which ideas to reimplement in AID's own idiom,
  which to consciously reject).
- Respect C-6: adoption is INSPIRATION-ONLY -- no copying of grill-me prompts or code; capture the
  approach's license + source URL in the note.
- Apply the A-1 fallback: if solid public material is thin, do NOT block -- lean on the established
  RE/domain-discovery literature and treat the comparative as best-effort, but STATE EXPLICITLY in
  the note what was/wasn't found and how the fallback was applied (visible gap, not silently papered).
- Produce a standalone research note at
  `features/feature-001-elicitation-research-spike/research/grillme-comparative.md` (the §3 grill-me
  Comparative draft + its sources + the A-1 disclosure if it fired). Dual-audience authoring standard.
  This note is an INPUT consumed by task-003; it does NOT create or edit `findings.md` (task-003
  assembles that -- avoids parallel-write contention with task-001).
- Research/recommendation only -- no production code, no KB docs, no skill/tooling edits (C-6).

**Acceptance Criteria:**
- [ ] The note covers what-it-is, strengths, weaknesses, a head-to-head vs AID, and an explicit adopt-vs-avoid list. *(DoD-2; AC-1 clause 2)*
- [ ] License + source URL for grill-me captured; no prompt/code copied (inspiration-only). *(C-6)*
- [ ] If grill-me sources were thin, the A-1 fallback disclosure states explicitly what was/wasn't found and how the fallback was applied. *(A-1, DoD-2)*
- [ ] Every claim is sourced (URL + access date), feeding the consolidated §7. *(RESEARCH default)*
- [ ] Output is `research/grillme-comparative.md` only; no `findings.md`, no code, no KB-doc, no tooling change. *(C-6 scope boundary)*
- [ ] All REQUIREMENTS.md §6 quality gates that apply to a research artifact pass.
