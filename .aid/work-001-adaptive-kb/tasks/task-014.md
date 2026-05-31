# task-014: Regenerate the repo knowledge summary

**Type:** DOCUMENT

**Source:** work-001-adaptive-kb (whole) → delivery-002

**Depends on:** task-013

**Scope:**
- Regenerate `knowledge-summary.html` from the updated KB by running `/aid-summarize` (it is idempotent and detects staleness; the KB updates in task-006 + task-013 make it stale, so it will regenerate). The summary must reflect the new declared-doc-set mechanism, the reconciled discovery-agent ownership, and H5 as resolved.
- Ensure the generated KB indexes (`INDEX.md`, `metrics.md`, `project-index.md`) are current via the generated-files refresh, so the summary is built from fresh inputs.
- This task is complete when `/aid-summarize` reaches its DONE state (both Machine and Human grades ≥ minimum).

**Acceptance Criteria:**
- [ ] `/aid-summarize` regenerates `knowledge-summary.html` from the updated KB and passes its two-grade gate (Machine + Human ≥ minimum).
- [ ] The summary contains no stale "fixed 14/16 doc-set" framing and reflects the declared-doc-set mechanism + resolved H5.
- [ ] Generated KB indexes (INDEX.md / metrics.md / project-index.md) are current.
- [ ] DOCUMENT default criterion: accuracy verified against the current codebase + KB.
