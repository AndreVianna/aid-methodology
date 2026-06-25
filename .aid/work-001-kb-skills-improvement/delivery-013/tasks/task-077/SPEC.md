# task-077: Design the per-spine-dimension depth standard + pick the authority file

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-077/STATE.md.

**Type:** DESIGN

**Source:** work-001-kb-skills-improvement -> delivery-013

**Depends on:** delivery-010 (feature-014 — the spine, the matrix's per-doc `spine-dimension`
column, `document-expectations.md`, and `state-generate.md` §2.6 the custom-doc prompt this
delivery re-keys)

**Scope:**
- Produce the **design of record** for feature-016 Change 1 (FR-52) so task-078 can author it
  mechanically. DESIGN only — propose + decide; do **not** edit the skill sources (that is task-078).
- **The per-spine-dimension depth-standard contract (C0–C9 + D).** For every spine dimension,
  define the *work-actionable depth standard* a doc realizing that dimension MUST reach, generalizing
  today's best software `document-expectations.md` entries: C5 = shapes/fields/types/constraints +
  the extension procedure (how to add/change one); C3 = the project's actual rules + concrete
  examples + red-flags ("convention named but no example" = red flag); C2 = the parts, how they
  connect, how to add a part; C6 = how work is graded/validated + the bars to meet; C0 (tech + build/
  lint commands); C1 (structure + invariants); C4 (vocabulary + conceptual invariants); C7 (risk/debt
  + gotchas); C8 (ship/operate); C9 (capabilities + how-invoked); D (decisions + rationale + rejected
  alternatives). Each standard is dimension-keyed, not filename-keyed.
- **The authority-file decision (seed §8 open question).** Decide the **lower-churn form**: a new
  `### C<N> — <dimension>` spine-dimension-keyed section *within* `document-expectations.md` (one
  authority file) **vs** a sibling `spine-depth-expectations.md`. Record the decision + rationale so
  task-078 has no ambiguity.
- **The resolution contract:** specify exactly how `state-generate.md` §2.6 + `agent-prompts.md`
  resolve doc -> spine dimension (via the matrix `spine-dimension` column / the §2.6 dimension
  mapping) -> the dimension standard, and how an existing `### <filename>` entry layers on top as an
  **optional additive refinement** (never replaces the dimension standard).
- Output is a structured proposal recorded in task-077/STATE.md `## Notes` (decision + rationale +
  the dimension->standard table shape + the resolution contract) — no report file.

**Acceptance Criteria:**
- [ ] A **per-spine-dimension depth-standard contract** is specified for **every** dimension
  (C0–C9 + D), each stating the work-actionable depth a doc realizing it must reach (the C5, C3, C2,
  C6 standards are explicit per the seed; the rest are specified, not "TBD"). *(FR-52)*
- [ ] The **authority-file decision** is made and justified (extend `document-expectations.md` with a
  spine-dimension-keyed section **or** new `spine-depth-expectations.md`), picking the lower-churn
  form; task-078 inherits an unambiguous target. *(FR-52, seed §8)*
- [ ] The **doc -> dimension -> standard resolution contract** is specified for `state-generate.md`
  §2.6 + `agent-prompts.md` (no doc left at a dangling `### <filename>` anchor), and the
  per-filename-entry-as-optional-refinement rule is stated (layers on, never replaces). *(FR-52)*
- [ ] The proposal **consumes the spine, does not grow it** — no change to the 11-dimension
  cardinality, the matrix domain set, the classifier, or `synth_default_seed` is proposed.
- [ ] All section-6 quality gates pass (for a DESIGN task: the proposal is recorded in STATE; no
  canonical edits, so no regen/DBI runs here — they run in task-078/task-079).
