# task-002: M1 — add typed `## Pipeline Status` block to work-state template + interview seed

**Type:** IMPLEMENT

**Source:** feature-001-pipeline-state-architecture → delivery-001

**Depends on:** task-001

**Scope:**
- Add the new contracted `## Pipeline Status` section to `canonical/templates/work-state-template.md` exactly as specified in feature-001 §2.2: a grep-recoverable `**Field:** value` block with the typed fields `Lifecycle`, `Phase`, `Active Skill`, `Updated`, and the conditional `Pause Reason` / `Block Reason` / `Block Artifact`.
- Declare the closed enums verbatim: `Lifecycle ∈ Running | Paused-Awaiting-Input | Blocked | Completed | Canceled`; `Phase ∈ Interview | Specify | Plan | Detail | Execute | Deploy | Monitor`; `Active Skill ∈ aid-{skill} | none`.
- Seed the block's initial values at work creation: wire `aid-interview` (`references/state-lite-done.md` / feature-decomposition) to emit the opening `Lifecycle: Running` + `Phase: Interview` + `Active Skill` + `Updated` (feature-001 §4 M1; the only producer touched in M1).
- Re-run the FULL `run_generator.py`; add a template-shape assertion that the section + enum members exist.

**Acceptance Criteria:**
- [ ] `work-state-template.md` contains the `## Pipeline Status` block with all 7 fields and the documented "written ONLY by `writeback-state.sh --pipeline`, never hand-edited, all values closed enums" header note (feature-001 §2.2).
- [ ] The three enum vocabularies are declared once in the template as the single source of truth feature-002 imports (feature-001 DD "enum drift").
- [ ] `aid-interview` work-creation seeds the block with valid opening enum values; observable interview behavior (prompts, gates, outputs) is unchanged (C4).
- [ ] A new template-shape assertion verifies the section + enum members exist; FULL generator re-run, no render-drift, all five trees byte-identical.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Unit/shape tests for the new template assertion added; existing `tests/run-all.sh` + Windows installer suite pass; FULL generator build passes.
