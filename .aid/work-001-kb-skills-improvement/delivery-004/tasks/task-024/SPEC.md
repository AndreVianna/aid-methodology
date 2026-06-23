# task-024: Canonical test suite for recon-classify (classification + byte-reproducibility + is_source lockstep)

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-004

**Depends on:** task-023

**Scope:**
- Author `tests/canonical/test-recon-classify.sh` plus its supporting fixtures under
  `tests/canonical/fixtures/` (minimal hand-authored `project-index.md` +
  `candidate-concepts.md` pairs, one per intended verdict). Auto-discovered by
  `tests/run-all.sh`. Mechanical assertions only (no LLM, no dispatch):
  - **greenfield:** a near-empty index (RM1 <= `greenfield_max_source_files` AND RM2 <=
    `greenfield_max_source_loc`) classifies **greenfield**.
  - **brownfield-large by LOC:** a large-LOC index (RM2 >= `large_min_source_loc`, other dimensions
    small) classifies **brownfield-large**.
  - **brownfield-large by dirs:** a high-directory index (RM3 >= `large_min_dirs`, LOC/concepts
    small) independently classifies **brownfield-large**.
  - **brownfield-large by concepts:** a concept-dense `candidate-concepts.md` (RM4 >=
    `large_min_concepts`, LOC/dirs small) independently classifies **brownfield-large** (the "small
    but conceptually dense" case).
  - **brownfield-small:** a has-source index under every large threshold classifies
    **brownfield-small**.
  - **greenfield gate is conjunctive:** a 3-source-file but 50k-LOC index does NOT classify
    greenfield (it classifies large) -- asserts RM1 AND RM2, not OR.
  - **threshold override flips the verdict:** the same fixture classified under a settings file that
    lowers/raises a `triage.*` threshold yields a different verdict -- the thresholds are
    configurable, not hard-coded.
  - **degrade-gracefully:** missing/empty `--candidates` => RM4=0 and a non-error classify; missing
    `--index` => a warning + `brownfield-small` proposal, exit 0.
  - **byte-reproducibility (NFR-3):** running recon-classify twice on the same inputs emits a
    byte-identical `recon.md` (diff is empty) -- mirrors f004's harvest NFR-3 guard.
  - **`is_source` lockstep fixture (NFR drift guard):** a shared assertion that
    `recon-classify.sh`'s source-language set is **identical** to `build-project-index.sh`'s
    `is_source` set (the re-implemented 23-language classifier cannot drift) -- mirroring f004's
    shared-fixture lockstep approach.
- Use a throwaway/pinned settings fixture for threshold reads; no dependence on the developer's real
  `.aid/`.

**Acceptance Criteria:**
- [ ] Each fixture classifies to its intended path (greenfield / brownfield-small /
  brownfield-large), including the three independent large-dimension trips (LOC / dirs / concepts).
- [ ] The conjunctive-greenfield assertion (3-file / 50k-LOC => NOT greenfield) passes.
- [ ] A `triage.*` threshold override changes the verdict on a fixed fixture.
- [ ] Both degrade-gracefully cases (no candidates => RM4=0; no index => brownfield-small + warning)
  assert a non-error exit and the expected proposal.
- [ ] The byte-reproducibility assertion confirms two runs emit an identical `recon.md`.
- [ ] The `is_source` lockstep fixture asserts the two source-language sets are byte-identical and
  FAILS if `recon-classify.sh` drifts from `build-project-index.sh`.
- [ ] Tests are deterministic, with clean setup/teardown, and are auto-discovered by
  `tests/run-all.sh`.
- [ ] All acceptance criteria from feature-006 brownfield classification (AC7) are covered by an
  assertion.
- [ ] All section-6 quality gates pass.
