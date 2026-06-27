# task-063: Regen profiles + .claude dogfood sync (DBI) + KB/skill doc updates

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-063/STATE.md.

**Type:** DOCUMENT

**Source:** work-001-kb-skills-improvement -> delivery-010

**Depends on:** task-062

**Scope:**
- Run the **full `run_generator.py`** to render canonical -> profiles (refresh emission
  manifests), then **sync `.claude/` from `profiles/claude-code/`** so the repo-root dogfood
  install is **byte-identical** (DBI).
- Update affected **KB/skill READMEs** and regenerate **INDEX** via the canonical
  `build-kb-index.sh`; add a **release-tracking** entry for feature-014.
- **Record** the Step 0f path-triage reconciliation outcome (task-058) and the
  Decisions-concern decision (task-056) where appropriate (feature/KB docs).

**Acceptance Criteria:**
- [ ] Profiles regenerated (emission manifests current); **`.claude/` byte-identical (DBI green)**;
  render-drift 0. *(section-6 cornerstones)*
- [ ] INDEX regenerated via the **canonical** `build-kb-index.sh`; release-tracking updated. *(FR-44)*
- [ ] Step 0f + Decisions decisions recorded.
- [ ] All section-6 quality gates pass.
