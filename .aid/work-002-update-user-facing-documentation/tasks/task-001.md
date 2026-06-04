# task-001: Drift audit + information-architecture design

**Type:** RESEARCH

**Source:** work-002-update-user-facing-documentation → delivery-001

**Depends on:** — (none)

**Scope:**
- Diff every user-facing doc (`README.md`, `methodology/aid-methodology.md` + images, `docs/glossary.md`, `docs/faq.md`, `examples/**`) against the current source of truth: `.aid/knowledge/` and `.aid/knowledge/knowledge-summary.html`.
- Produce a **corrected fact-set**: an itemized list of every stale/inaccurate claim with its correction — covering the known drift (AID lite path, changed pipeline shape, re-placed skills, five profiles incl. GitHub Copilot CLI + Antigravity) **and any additional drift discovered** during the diff.
- Produce a proposed **information architecture / reading path** for the documentation (README → docs → methodology → examples), including the target structure for a possible full reorganization and the examples index. Identify which existing example directories are obsolete and slated for removal (consumed by task-002).
- Output is a planning/reference artifact (not final prose) that task-002…task-006 consume.

**Acceptance Criteria:**
- [ ] Every user-facing doc has been compared against the KB / knowledge-summary; the corrected fact-set lists each drift item with its correction and source citation.
- [ ] Drift beyond the known list is either captured in the fact-set or explicitly noted as "none found." (SPEC AC: drift audit performed.)
- [ ] A concrete information-architecture / reading-path proposal exists, covering README, docs/, methodology, and the examples index. (SPEC AC: information architecture.)
- [ ] No methodology, code, or behavior changes are proposed — documentation only. (SPEC AC: docs-only.)
- [ ] All quality gates pass (see SPEC § Quality Gates).
