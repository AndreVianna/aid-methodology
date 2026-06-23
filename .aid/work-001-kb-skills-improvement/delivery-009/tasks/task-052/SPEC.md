# task-052: Greenfield path fixture (the AC7 greenfield project shape)

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-009

**Depends on:** task-029 (delivery-005)

**Scope:**
- Author the hand-built, ASCII, checked-in **GREENFIELD path fixture** that task-029
  (delivery-005) explicitly carved out -- the slice it left as "the `greenfield/` fixture is NOT
  present (delivery-009)". It lives alongside the brownfield fixtures task-029 already planted, under
  `tests/canonical/fixtures/kb-essence/paths/greenfield/generated/` (f012 SPEC F4) -- the
  `generated/` index + candidate tables `recon-classify.sh` reads (NOT a real source tree; recon does
  not re-scan):
  - `greenfield/generated/project-index.md`: Language Breakdown sums to `<= greenfield_max_source_files`
    source files **AND** `<= greenfield_max_source_loc` LOC over `is_source` rows (so RM1 AND RM2 are
    both under the greenfield ceilings -- the greenfield discriminator is gated on BOTH); Full File
    Inventory holds only a few `is_source` dir prefixes (low RM3). Both sections MUST be present per
    f006 SPEC L179-181 (Language Breakdown for RM1/RM2 + Full File Inventory for RM3), mirroring the
    task-029 brownfield fixtures.
  - `greenfield/generated/candidate-concepts.md`: a **near-empty** candidate list (nothing to extract
    -- the greenfield signal), carrying f004's documented schema (`## Summary` with the
    `Cross-source (spread >= 2)` count row -- a near-zero count -- + the `## Ranked Candidates`
    columns `# | Term | Class | Freq | Spread | Channels | Salience | Example source`, f004 SPEC
    L275-289) so RM4 parses a real (near-zero) count and does not fall back to a parse error.
  - **Reuse the SHIPPED-defaults `paths/settings.yml` task-029 already authored** -- do NOT create a
    second settings fixture. The greenfield fixture bins under the SAME shipped `triage.*` defaults
    (`greenfield_max_source_files: 5`, `greenfield_max_source_loc: 500`) carried in that file; this
    task plants a greenfield shape that classifies greenfield under those existing values.

**Boundary (f012 EXERCISES, does not RE-SPEC):** this task authors ONLY the greenfield fixture files.
It does NOT author or edit `recon-classify.sh` or the `triage.*` thresholds (f006, shipped by
delivery-004), and it does NOT add or edit `paths/settings.yml` (task-029 owns it -- this task reuses
it). It plants the greenfield shape ONLY; the brownfield-small + brownfield-large fixtures are
task-029's (consumed as siblings). The numeric `triage.*` greenfield floors are NOT chosen here --
they are the shipped f006 defaults that task-053 pins ([SPIKE-T1] / [SPIKE-V2]); this task plants a
shape that bins greenfield under them.

**Acceptance Criteria:**
- [ ] `tests/canonical/fixtures/kb-essence/paths/greenfield/generated/` exists containing
  `project-index.md` + `candidate-concepts.md`; both ASCII, checked into git; planted alongside the
  task-029 brownfield fixtures under the same `paths/` tree.
- [ ] `greenfield/project-index.md` carries BOTH a `Language Breakdown` table (RM1 source-file count
  AND RM2 source LOC, both `<=` the shipped greenfield ceilings over `is_source` rows) AND a
  `Full File Inventory` section (RM3 -- only a few distinct top-2-level `is_source` dir prefixes), per
  f006 SPEC L179-181.
- [ ] `greenfield/candidate-concepts.md` carries f004's documented schema with a `## Summary`
  `Cross-source (spread >= 2)` count that is near-zero (the "nothing to extract" greenfield signal),
  so RM4 reads a real low count.
- [ ] The greenfield shape classifies **greenfield** under the SHIPPED `triage.*` defaults carried in
  the existing task-029 `paths/settings.yml` -- no second settings fixture is created, and
  `paths/settings.yml` is not edited.
- [ ] No fixture file is written/mutated at run time -- the tree is a static read-only input copied
  into a `mktemp -d` scratch by task-053 before any script runs.
- [ ] All AC7-greenfield fixture-shape acceptance criteria from feature-012 (F4 greenfield) are
  covered; all section-6 quality gates pass.
