# task-003: Synthesis & Recommendations -> findings.md

**Type:** RESEARCH

**Source:** work-001-aid-interview-improvements -> delivery-001

**Depends on:** task-001, task-002

**Scope:**
- Assemble the single feature deliverable `findings.md` at
  `features/feature-001-elicitation-research-spike/findings.md` from the two research notes
  (`research/technique-survey.md` from task-001, `research/grillme-comparative.md` from task-002),
  in the feature SPEC's required 7-section structure: §1 Summary & Recommendations, §2 Technique
  Survey (lift from task-001), §3 grill-me Comparative (lift from task-002), §4 Recommendation A,
  §5 Recommendation B, §6 Open Questions / Risks, §7 Sources (consolidate both notes' citations).
- Answer ALL research questions, each with a JUSTIFIED (cites a surveyed technique/source) and
  ACTIONABLE (states a downstream-buildable recommendation) answer:
  - RQ-A1..A5 (seed-content set): validate/revise the candidate seed; map each kept element to its
    KB doc + `kb-category`; exclusions + rationale (RQ-A2); declared-vs-harvested spine guidance
    (RQ-A3); domain-adaptive shape (RQ-A4); the zero-KB-gap-loopback sufficiency bar (RQ-A5).
  - RQ-B1..B4 (analyst conversation): elicitation moves; calibration; triage elicitation; how
    NFR-7 (every question carries a suggested answer + rationale) survives/strengthens.
- Author §4 Recommendation A (seed-content set) and §5 Recommendation B (analyst conversation
  design) so features 003 + 002 can specify the seed model/engine and feature 004 the triage
  DIRECTLY from them. Note (per D-5) what aid-discover's review expectations imply for a greenfield
  doc-set so feature-003 can wire the same KB review gate.
- Flag in §6 any A-2 schema-expressibility gap (seed not expressible in the existing KB schema) and
  any unresolved question, for features 002-005 -- explicit, not implicit.
- Research/synthesis only -- no production code, no KB docs, no skill/tooling/schema edits (C-6).
  The intermediate `research/*.md` notes may remain as appendices or be folded in; `findings.md` is
  the gated deliverable.

**Acceptance Criteria:**
- [ ] `findings.md` exists at the SPEC path with all 7 required sections populated. *(DoD-1, DoD-2)*
- [ ] Every RQ-A1..A5 and RQ-B1..B4 sub-question is answered with a justified + actionable answer. *(DoD-3)*
- [ ] §4 Rec A and §5 Rec B are specific + justified and formed so features 002/003/004/005 can be specified directly from them (each recommendation names the feature(s) it grounds). *(DoD-4; AC-1 clause 3)*
- [ ] §6 surfaces any A-2 schema gap and any unresolved downstream question explicitly. *(DoD-5)*
- [ ] §7 consolidates the citations from both research notes (URL + access date; license where applicable). *(DoD-1/DoD-2 sourcing)*
- [ ] No production code, KB doc, skill, tooling, or schema change is produced (scope boundary). *(C-6)*
- [ ] `findings.md` passes the artifact review gate at the work's **configured** minimum grade -- a document review for completeness/grounding/actionability. (DoD-6 / NFR-3 specify the spec-time floor as "≥ A"; the owner has since raised the global `review.minimum_grade` to A+, so A+ is the gate that actually applies at execution.) *(DoD-6)*
