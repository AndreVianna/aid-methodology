# task-004: concern-model.md + seed reframe + expectations-as-open-questions

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-001

**Depends on:** task-001

**Scope:**
- Author `canonical/aid/templates/kb-authoring/concern-model.md`: the 10 numbered universal
  concerns (C1-C9 + C0) each with id / question / definition (what belongs, what does not) /
  default doc(s); the T2 cardinality contract (fixed concern count); the three-force boundary rule
  (coverage x fit x audience/ownership); the audience axis distinguished from `tier-model.md` (the
  three orthogonal axes); the propose->confirm split/add/conditional rules; the seed-coverage check
  mapping exactly the 15 `synth_default_seed` docs (none unmapped, none duplicated;
  `repo-presentation.md` named only as a conditional extension example, never a default).
- Register `concern-model.md` in `canonical/aid/templates/kb-authoring/README.md` (index row +
  quick-reference area as the document-derivation model) and cross-ref the boundary rule from
  `canonical/aid/templates/kb-authoring/principles.md`.
- Add the comment-only concern annotation (the concern id per entry) to `synth_default_seed`'s
  `MAP` array + the prose ownership table in
  `canonical/skills/aid-discover/references/doc-set-resolve.md` -- the emitted TSV stays
  `filename<TAB>owner<TAB>presence` BYTE-IDENTICAL (concern is NOT a 4th machine field); document
  the propose->confirm flow against the concern model.
- Rewrite EVERY `### <filename>` entry in
  `canonical/skills/aid-discover/references/document-expectations.md` (all 19 entries) to
  open-question form: lead with the open question(s), retain the slot list as an "(Investigate: ...)"
  parenthetical, keep the red-flags. Still keyed `### <filename>`; no parser change.
- Edit canonical only; re-run `run_generator.py` (resolves SPIKE-2: confirm the renderer
  auto-discovers the net-new `kb-authoring/concern-model.md`); commit regenerated `profiles/`.

**Acceptance Criteria:**
- [ ] `concern-model.md` enumerates the 10 concerns (C1-C9 + C0) with id/question/definition/default
  doc(s), states the T2 fixed-count contract, the three-force boundary rule, the audience-vs-tier
  axis distinction, and the propose->confirm split/add/conditional rules.
- [ ] The seed-coverage check maps exactly the 15 `synth_default_seed` docs with none unmapped or
  duplicated; `repo-presentation.md` appears only as a conditional-extension example, never a default.
- [ ] `concern-model.md` is registered in `kb-authoring/README.md`; the boundary rule is
  cross-referenced from `principles.md`.
- [ ] The concern annotation in `doc-set-resolve.md` is comment-only; the emitted
  `filename<TAB>owner<TAB>presence` TSV is byte-identical to before (verified) -- `resolve_doc_set`
  and the 4 accessors untouched.
- [ ] All 19 `### <filename>` entries in `document-expectations.md` lead with open question(s),
  retain the slot list as an "(Investigate: ...)" parenthetical, and keep red-flags; the file is
  still keyed `### <filename>` with no parser change.
- [ ] `run_generator.py` re-run auto-discovers and emits `concern-model.md` to all 5 trees + the
  `.claude/` working copy; regenerated `profiles/` committed (render-drift green).
- [ ] All section-6 quality gates pass.
