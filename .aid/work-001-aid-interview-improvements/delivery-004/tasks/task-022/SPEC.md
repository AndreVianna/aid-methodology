# task-022: Greenfield-mode parameterization block in document-expectations.md

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-004

**Depends on:** -- (none)

**Scope:**
- Add a single **Greenfield mode** parameterization block to
  `canonical/skills/aid-discover/references/document-expectations.md` that the `aid-reviewer` sub-agent
  honors when the review parameter `greenfield: true` is set (owner decision 1). This is a flag that
  parameterizes the EXISTING expectations -- NOT a forked variant file; the default-false brownfield
  expectations stay byte-unchanged (NFR-2).
- The block specifies three things (per feature-003 SPEC "Greenfield review gate"):
  - **Evidence substitution** (when `greenfield: true`): wherever a depth standard / red flag demands
    code/config evidence, substitute INTENT-evidence (confirmed elicited statements + gathered
    REQUIREMENTS). Concretely: C3 "concrete example from this project's code or files" -> "from intended
    use"; `architecture.md` "ground every claim in a file or path" -> "ground every claim in a confirmed
    requirement or elicited statement"; C4 "where it lives in the code" -> "where it lives in the intended
    design / domain".
  - **As-built red flags RELAXED (suppressed):** C0 `technology-stack.md` "Version TBD" + "missing runnable
    build command" accepted as "latest-at-init / TBD-until-scaffolded" + build "TBD" (owner decision 2);
    C1 `architecture.md` "generic descriptions without file paths" relaxed to sketch-altitude intended
    boundaries (and `project-structure.md` excluded entirely); C3 `coding-standards.md` "convention named
    but no example from code" accepted when the doc declares "standard for `<stack>`, no project-specific
    deviations yet" (owner decision 4).
  - **Dimension floors KEPT (same bar, MUST still pass):** C4 term-boundary invariants (`## Invariants`);
    C1 architecture `## Invariants`; the operational-structure floors / owned named sections per
    `concern-model.md`; NO dimension is skipped -- only the evidence SOURCE changes and the AS-BUILT red
    flags are suppressed.
- The block must state explicitly that it is additive on top of each doc's spine-dimension floor and never
  replaces a floor. ASCII-only; targeted insert (no edits to the existing C0-C9 dimension blocks beyond
  the new greenfield carve they reference).
- **Out of scope:** threading the `greenfield:` param through `reviewer-brief.md` + the `state-review.md`
  panel-exclusion reconciliation (task-023); invoking the gate from the seed-authoring step (task-025);
  render (task-026).

**Acceptance Criteria:**
- [ ] `document-expectations.md` carries one **Greenfield mode** block (not a forked file) honored when `greenfield: true`, specifying the evidence-substitution rules for C3/architecture/C4 verbatim to the SPEC. *(NFR-3, owner decision 1; gate criterion 1)*
- [ ] The block suppresses the named as-built red flags (C0 Version-TBD + missing-build-command; C1 generic-without-paths; C3 convention-without-example) per owner decisions 2 and 4. *(NFR-3; gate criterion 4)*
- [ ] The block KEEPS the dimension floors (C4 + C1 `## Invariants`, operational-structure owned sections, no dimension skipped) and states it is additive-on-top-of-floor, never a floor replacement. *(NFR-3; gate criterion 1)*
- [ ] Default (`greenfield: false` / absent) brownfield expectations are byte-unchanged outside the additive block (verify via diff). *(NFR-2; gate criterion 2)*
- [ ] ASCII-only; skill reference is prose-executed (no unit test; IMPLEMENT unit-test default overridden -- exercised by the greenfield-gate run at task-027). All REQUIREMENTS.md §6 quality gates pass.
