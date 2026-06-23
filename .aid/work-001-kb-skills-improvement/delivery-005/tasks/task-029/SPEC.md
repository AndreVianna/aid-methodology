# task-029: Brownfield path fixtures + shipped-defaults settings.yml

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-005

**Depends on:** -- (none)

**Scope:**
- Author the hand-built, ASCII, checked-in BROWNFIELD path fixtures that the AC7 suite (task-032)
  runs over, under `tests/canonical/fixtures/kb-essence/paths/` (f012 SPEC F4) -- the `generated/`
  index+candidate tables `recon-classify.sh` reads (NOT real source trees; recon does not re-scan):
  - `brownfield-small/generated/project-index.md` + `candidate-concepts.md`: source present, every
    dimension under `large_min_*` (RM2 LOC in Language Breakdown; RM3 dir count in Full File
    Inventory `< large_min_dirs`; RM4 concepts in Summary). Must classify **brownfield-small**.
  - `brownfield-large/generated/project-index.md` + `candidate-concepts.md`: at least one large
    dimension trips, exercising each OR-branch of f006's classifier as three independent variants --
    **LOC variant** (RM2 `>= large_min_source_loc`, via Language Breakdown), **dirs variant** (RM3
    `>= large_min_dirs`, via a Full File Inventory carrying `>= large_min_dirs` distinct top-2-level
    `is_source` dir prefixes), **concepts variant** (RM4 `>= large_min_concepts`, via the candidate
    Summary `Cross-source (spread >= 2)` count). All must classify **brownfield-large**.
  - `paths/settings.yml`: a checked-in fixture carrying ONLY the `triage.*` block with the SHIPPED
    default values (byte-identical to `canonical/aid/templates/settings.yml` `triage.*`), so TEST-D
    runs fully isolated via `--settings paths/settings.yml` and never reads the live repo settings.
- Each `project-index.md` MUST populate BOTH sections recon parses (f006 SPEC L179-181): the
  `Language Breakdown` table (RM1 source-file count + RM2 source LOC over `is_source` rows) AND the
  `Full File Inventory` section (RM3 -- distinct top-2-level `is_source` dir prefixes); omitting the
  Full File Inventory would make the dirs-variant (V-D4) silently never trip `large_min_dirs`.
- Each `candidate-concepts.md` carries f004's documented schema (`## Summary` with the `Cross-source
  (spread >= 2)` count row + `## Ranked Candidates` columns, f004 SPEC L275-289) -- so RM4 reads a
  real count.

**Boundary (f012 EXERCISES, does not RE-SPEC):** this task authors ONLY fixture files. It does NOT
author or edit `recon-classify.sh` or the `triage.*` thresholds (f006, shipped by delivery-004). The
**greenfield path fixture is OUT of scope -- it is carved to delivery-009 (AC7-greenfield)**; this
task plants brownfield-small + brownfield-large only. The numeric `triage.*` floor values are not
chosen here -- they are the shipped f006 defaults that task-032 pins ([SPIKE-T1] / [SPIKE-V2]); this
task only carries them into `paths/settings.yml` and plants shapes that bin under them.

**Acceptance Criteria:**
- [ ] `tests/canonical/fixtures/kb-essence/paths/` exists containing `brownfield-small/generated/` and `brownfield-large/generated/` (with `project-index.md` + `candidate-concepts.md` each) plus `paths/settings.yml`; all ASCII, checked into git. The `greenfield/` fixture is NOT present (delivery-009).
- [ ] Each `project-index.md` carries BOTH a `Language Breakdown` table (RM1/RM2 over `is_source` rows) AND a `Full File Inventory` section (RM3 distinct top-2-level `is_source` dir prefixes), per f006 SPEC L179-181.
- [ ] `brownfield-small` is planted so every dimension (RM2 LOC, RM3 dirs, RM4 concepts) sits under the corresponding `large_min_*` shipped default; `brownfield-large` is planted in three variants, each tripping exactly one large floor (LOC, dirs, concepts) independently.
- [ ] Each `candidate-concepts.md` carries f004's documented schema with a `## Summary` `Cross-source (spread >= 2)` count consistent with the fixture's intended RM4 binning.
- [ ] `paths/settings.yml` carries a `triage.*` block whose keys/values are byte-identical to the shipped `canonical/aid/templates/settings.yml` `triage.*` block (so task-032 V-D7 can assert parity).
- [ ] No fixture file is written/mutated at run time -- the trees are static read-only inputs copied into a `mktemp -d` scratch by task-032 before any script runs.
- [ ] All section-6 quality gates pass.
