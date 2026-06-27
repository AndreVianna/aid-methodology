# task-069: Adapt canonical summarize suites + guardrail checks (C1/C2/C3/C5/C6)

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-069/STATE.md.

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-011

**Depends on:** task-065, task-066, task-067, task-068

**Scope:**
- Adapt the **canonical summarize test suites** to the redesigned correctness-core behavior
  (Changes 1-5) and assert the §5 guardrails that D-011 must not break. TEST only — no skill
  behavior is changed here (that was tasks 065-068).
- **Change-1 coverage:** a fixture KB (feature-014 doc-set + custom docs + `## Discovery Domain`)
  yields **one section per resolved doc / `kb-category`**; assert **no `repo-presentation.md`**
  reference survives; assert the `noscript` doc list is **derived** (matches the resolved doc-set,
  not a hardcoded list).
- **Change-2 coverage:** assert `domain-glossary.md` / `decisions.md` / `capability-inventory.md`
  render as **content components** (glossary/ADR/capability present in the output), not as bare
  links; assert the generic fallback covers a doc with no bespoke component.
- **Change-3 coverage:** assert `grade-summary.sh` has **no C+/diagram-count cap** and grades on
  coverage-based completeness (a complete, diagram-light summary is not capped; a diagram-rich but
  incomplete summary is not floored).
- **Change-4/5 coverage:** assert the "At a Glance" newcomer framing (no software-metric lead) and
  the **page-shell alignment** with `home.html` + CLI `index.html` (shell selectors/landmarks
  present).
- **Guardrail checks (C1/C2/C3/C5/C6):** C1 output path `<repo>/.aid/dashboard/kb.html`; C2/C3
  single self-contained file (no CDN / no split asset / no framework fetch); C5
  `## Knowledge Summary Status` -> `**User Approved:** yes (YYYY-MM-DD)` literal preserved; C6
  `README.md ## Completeness` rows + `kb_baseline:` shape preserved.
- Follow the split-big-TEST-tasks lesson: keep this delivery's test work to the summarize suites +
  guardrail checks; if any single suite balloons, split it into per-suite sub-units rather than one
  mega-run. Tests target the **canonical** suites under
  `canonical/aid/scripts/summarize/`/`tests/`; rendering/DBI is task-070.

**Acceptance Criteria:**
- [ ] A feature-014 fixture KB produces **one section per resolved doc / `kb-category`**; the suite
  asserts **no `repo-presentation.md`** and a **derived `noscript`** list. *(FR-45)*
- [ ] The suite asserts glossary / ADR / capability render as **content components** (not links)
  and the generic fallback covers a no-bespoke-component doc. *(FR-46)*
- [ ] The suite asserts **no C+/diagram-count cap** in `grade-summary.sh` and **coverage-based**
  completeness grading (complete-but-diagram-light is not capped). *(FR-47)*
- [ ] The suite asserts newcomer "At a Glance" framing (no software-metric lead) and **page-shell
  alignment** with `home.html` + CLI `index.html`. *(FR-48, FR-49, §5b)*
- [ ] The suite asserts guardrails **C1/C2/C3/C5/C6** hold (path, self-containment, approval
  signal, completeness/`kb_baseline` shapes). *(guardrails)*
- [ ] All section-6 quality gates pass.
