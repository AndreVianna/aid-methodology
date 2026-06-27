# task-067: Best-format-per-fact + completeness grading — remove the diagram-count cap (Change 3)

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-067/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-011

**Depends on:** task-064

**Scope:**
- Implement feature-015 **Change 3 (FR-47)** — replace the diagram-COUNT gate with a
  best-format-per-fact + completeness rubric. Edit **canonical** sources only (regen is task-070).
- **`templates/knowledge-summary/grading-rubric.md`** — rewrite the dimensions to reward
  **clarity, completeness (coverage of all project-relevant information / the resolved doc-set),
  and visual communication for a newcomer**, with the **format chosen per fact** (the §0 standard).
  Completeness is measured against **resolved-doc-set coverage** (every resolved doc / spine
  dimension is represented), not a fixed section list. **Drop the diagram-count dimension** (no
  floor, no ceiling). State explicitly that the **KB no-diagrams rule is NOT applied** to the
  summary grade.
- **`scripts/summarize/grade-summary.sh`** — remove the **C+/diagram-count cap** (the
  `grade-summary.sh:307` C+-unless-N-diagrams line) and implement **coverage-based completeness
  scoring** consistent with the rewritten rubric. The script stays ASCII-only and WinPS-5.1-safe
  where it is a shipped helper.
- Cross-check the rewritten rubric against the task-064 manifest's doc-set-coverage definition so
  "completeness" in the rubric and "section per resolved doc" in the manifest agree.

**Acceptance Criteria:**
- [ ] The rubric rewards **clarity + completeness (resolved-doc-set coverage) + newcomer visual
  communication**, with the format chosen per fact; **no diagram floor and no diagram ceiling**.
  *(FR-47)*
- [ ] The **C+/diagram-count cap is removed** from `grade-summary.sh` (the C+-unless-N-diagrams
  gate no longer exists); a grep for the diagram-count cap returns nothing. *(FR-47)*
- [ ] `grade-summary.sh` computes **coverage-based completeness** against the resolved doc-set
  (every resolved doc / spine dimension represented), consistent with the rewritten rubric and the
  task-064 manifest. *(FR-47)*
- [ ] The rubric states explicitly that the **KB no-diagrams rule is NOT applied** to the summary
  grade. *(FR-47, §0)*
- [ ] `grade-summary.sh` stays ASCII-only + WinPS-5.1-safe; edits are in `canonical/...` only;
  guardrails C1/C2/C3/C5/C6 are not regressed.
- [ ] All section-6 quality gates pass.
