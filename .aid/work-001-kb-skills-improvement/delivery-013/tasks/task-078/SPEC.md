# task-078: Author the dimension depth standard + re-point the GENERATE custom-doc prompt

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-078/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-013

**Depends on:** task-077

**Scope:**
- Realize feature-016 **Change 1 (FR-52)** per task-077's design of record. Edit **canonical**
  sources only; the full `run_generator.py` regen + `.claude` sync is the regen step (run here, with
  the doc-resolution assertion + DBI in task-079).
- **Author the per-spine-dimension depth standard** in the authority file task-077 chose
  (`canonical/skills/aid-discover/references/document-expectations.md` as a new spine-dimension-keyed
  section, **or** a new sibling `canonical/skills/aid-discover/references/spine-depth-expectations.md`)
  — the C0–C9 + D work-actionable depth standards, each keyed to its dimension, generalizing today's
  best software `### <filename>` entries.
- **Re-point the GENERATE custom-doc prompt** — `canonical/skills/aid-discover/references/state-generate.md`
  §2.6 and `canonical/skills/aid-discover/references/agent-prompts.md` § "Custom-Doc Runtime
  Extension" resolve each doc -> its **spine dimension** (via the matrix `spine-dimension` column /
  the §2.6 dimension mapping) -> the dimension's depth standard, instead of the bare
  `### <filename>` anchor. No doc is left at a dangling anchor.
- **Keep per-filename entries as optional additive refinements** — an existing `### <filename>`
  entry layers on top of its dimension standard; it never replaces it.
- **Cross-reference** the dimension depth standard from
  `canonical/aid/templates/kb-authoring/concern-model.md` and
  `canonical/aid/templates/kb-authoring/domain-doc-matrix.md` (the dimension keying substrate these
  two own).
- **Regen step:** run the full `run_generator.py` (at `.claude/skills/generate-profile/scripts/`) to
  sync canonical -> `.claude`; never edit the rendered `.claude/` copy directly.

**Acceptance Criteria:**
- [ ] The **per-spine-dimension depth standard** (C0–C9 + D) is authored in task-077's chosen
  authority file; each dimension has a non-empty work-actionable standard (C5/C3/C2/C6 explicit per
  the seed). *(FR-52)*
- [ ] `state-generate.md` §2.6 + `agent-prompts.md` are **re-pointed** to resolve doc -> spine
  dimension -> standard; **no** custom-doc prompt points at a bare `### <filename>` anchor. *(FR-52)*
- [ ] Existing per-filename `### <filename>` entries are preserved as **optional additive
  refinements** (layer on, do not regress / do not replace the dimension standard). *(FR-52)*
- [ ] `concern-model.md` + `domain-doc-matrix.md` cross-reference the dimension depth standard;
  the spine cardinality, matrix domain set, classifier, and `synth_default_seed` are **untouched**.
- [ ] Edits are in `canonical/...` only; the full `run_generator.py` regen + `.claude` sync is run
  (the `.claude/` copy is generated, never hand-edited).
- [ ] All section-6 quality gates pass.
