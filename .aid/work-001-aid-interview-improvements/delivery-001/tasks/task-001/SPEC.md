# task-001: Classic elicitation & domain-discovery technique survey

**Type:** RESEARCH

**Source:** work-001-aid-interview-improvements -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Survey the established Requirements-Elicitation / Domain-Discovery technique families named in
  feature-001 SPEC (DDD / ubiquitous language, Event Storming, User-Story Mapping, Volere / RE
  process, Context & domain modeling, JAD-style facilitation, Five-whys / laddering) -- treat the
  list as a starting set, not a ceiling; add any genuinely load-bearing technique found.
- Score EACH family on the feature's fixed per-technique rubric: (a) what KB-seed content it
  surfaces (-> RQ-A), (b) what conversational moves it contributes (-> RQ-B), (c) fit with AID's
  one-decision-at-a-time / human-gated / propose-don't-assume process (NFR-1/NFR-7), (d) an
  adopt / adapt / avoid verdict with reason.
- Produce a standalone research note at
  `features/feature-001-elicitation-research-spike/research/technique-survey.md` (the §2 Technique
  Survey draft + the sources it cites). Write to the dual-audience authoring standard
  (`authoring-conventions.md`). This note is an INPUT consumed by task-003 (synthesis); it does NOT
  create or edit `findings.md` (task-003 assembles that, avoiding parallel-write contention with
  task-002).
- Research/recommendation only -- no production code, no KB docs, no skill/tooling edits (C-6).

**Acceptance Criteria:**
- [ ] Every surveyed family has a rubric-scored entry with an explicit adopt/adapt/avoid verdict + reason. *(DoD-1)*
- [ ] At least 2 technique alternatives are compared on the same rubric (apples-to-apples). *(RESEARCH default)*
- [ ] Every claim is sourced -- each cited technique/article carries a URL + access date (+ license where applicable). *(RESEARCH default; feeds §7)*
- [ ] The note is formed so task-003 can lift it into `findings.md` §2 and answer RQ-A1..A5 / RQ-B1..B2 from it (each entry maps its findings to the relevant RQ).
- [ ] Output is `research/technique-survey.md` only; no `findings.md`, no code, no KB-doc, no tooling change (scope boundary respected). *(C-6)*
- [ ] All REQUIREMENTS.md §6 quality gates that apply to a research artifact pass (dual-audience clarity, single-concern, evidence-grounded).
