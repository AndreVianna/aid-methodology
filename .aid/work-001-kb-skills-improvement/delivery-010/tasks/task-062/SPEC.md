# task-062: Tests (classifier / matrix / self-bootstrap / authoring-standard) + affected suites

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-062/STATE.md.

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-010

**Depends on:** task-059, task-060, task-061

**Scope:**
- Add/extend canonical test suites covering:
  - **Domain classifier** (decisive -> classify; uncertain -> Required Q&A; STATE record;
    idempotent re-entry).
  - **Matrix resolution** (hit returns the curated row; miss triggers research-fallback;
    hybrid composition unions over the spine; software row == 15-doc seed).
  - **Self-bootstrap STATE** (missing STATE.md -> created from template; preflight passes).
  - **Authoring-standard mechanical checks** (layout order, frontmatter fields, index present,
    change-log-last, diagram-absence).
- **Re-run + fix** affected existing suites: `test-doc-set-read.sh`, `test-actback-task.sh`,
  `test-discovery-doc-ownership.sh`. Confirm **render-drift = 0** and **DBI green**.
- Pin `HOME` for any suite that scans `HOME` (repo test-isolation rule).

**Acceptance Criteria:**
- [ ] New tests pass and cover classifier / matrix / self-bootstrap / authoring-standard. *(FR-38–FR-44)*
- [ ] Affected existing suites re-run **green**; `synth_default_seed` byte-stability confirmed.
- [ ] render-drift 0; DBI green; HOME pinned where suites scan HOME.
- [ ] All section-6 quality gates pass.
