# task-023: recon-classify.sh (full ordered classifier + RM1-RM4) + the `triage:` settings block

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-004

**Depends on:** task-006 (delivery-001)

**Scope:**
- Author `canonical/aid/scripts/kb/recon-classify.sh` -- a shipped, deterministic KB script (no
  LLM, no embedding model, pure coreutils: `awk`/`grep`/`sort`/`wc` + the existing
  `read-setting.sh`). ASCII-only bash (vendors into the install bundles; PS-5.1 N/A). It reads two
  **already-generated** markdown files (no second tree scan) plus the settings:
  - **Flags** (mirror the sibling shape): `--index .aid/generated/project-index.md`,
    `--candidates .aid/generated/candidate-concepts.md`, `--settings .aid/settings.yml`,
    `--output .aid/generated/recon.md`. Reuse the sibling absolute-OUTPUT-before-cd resolution.
  - **The four metrics (RM1-RM4):** RM1 = source-file count (sum `Files` over `project-index.md`
    Language Breakdown rows whose Language is an `is_source` language); RM2 = source LOC (sum
    `Lines` over the same `is_source` rows); RM3 = directory/subsystem count (distinct top-2-level
    directory prefixes over `is_source` files in the Full File Inventory); RM4 = candidate-concept
    count (the `Cross-source (spread >= 2)` value from `candidate-concepts.md` Summary; 0 when the
    file is missing/empty).
  - **The `is_source` 23-language classifier** re-implemented inside the script, kept in **lockstep
    with `build-project-index.sh`'s `is_source`** (the same lockstep hazard f004 manages; the
    lockstep is asserted by task-024's shared fixture).
  - **The full ordered classifier (single indivisible awk rule)** against the configurable
    thresholds, in this exact order: (1) `RM1 <= greenfield_max_source_files AND RM2 <=
    greenfield_max_source_loc` -> propose **GREENFIELD**; (2) else `RM2 >= large_min_source_loc OR
    RM3 >= large_min_dirs OR RM4 >= large_min_concepts` -> propose **BROWNFIELD-LARGE** (any one
    large dimension trips); (3) else -> propose **BROWNFIELD-SMALL**. The greenfield-DETECTING first
    branch is built here as CODE (D4 scope: classifier completeness, whole/indivisible). Greenfield
    is **detect + signpost** in this work: the classifier DETECTS greenfield (kept), and on a
    greenfield verdict aid-discover signposts and halts (wired in task-025). There is **no greenfield
    generation path** -- no greenfield generation engine, no greenfield closure, no greenfield
    panel-collapse (forward-authoring a KB-seed from intent is a future interview-side work).
  - **Output:** emit `.aid/generated/recon.md` with the proposed path PLUS the four metric values
    AND which threshold(s) tripped (so the confirm gate can show the human *why*).
  - **Degrade-gracefully:** missing/empty `--candidates` => RM4=0 (never an error); missing
    `--index` => log a warning and propose `brownfield-small` (conservative default). Never error
    out -- the human-confirm gate is the safety net.
- Add a new top-level **`triage:` block** to `canonical/aid/templates/settings.yml` with the five
  threshold keys + sensible defaults + explanatory comments:
  `greenfield_max_source_files: 5`, `greenfield_max_source_loc: 500`,
  `large_min_source_loc: 20000`, `large_min_dirs: 25`, `large_min_concepts: 40`. Absent block =>
  these defaults; a project may override any single key. Reads are flat one-level dotted paths
  (`triage.greenfield_max_source_files`) via the existing `read-setting.sh` -- no `yq`, no new
  config machinery.
- Add `canonical/aid/scripts/kb/recon-classify.sh` to `tests/canonical/test-ascii-only.sh`'s
  `SHIPPED_SCRIPTS` allow-list (C2).
- Re-run `python .claude/skills/generate-profile/scripts/run_generator.py` so the new script + the
  template edit render to all 5 host trees + the repo `.claude/` working copy; commit the
  regenerated `profiles/` (render-drift-full-generator precedent). **[SPIKE-T4]** -- if an emission
  manifest pins the `scripts/kb/` list, regen, never hand-place.

**Acceptance Criteria:**
- [ ] `recon-classify.sh` parses RM1-RM4 deterministically from `project-index.md` +
  `candidate-concepts.md` only (no `find`/`wc` second tree scan).
- [ ] The ordered classifier is a single indivisible rule with the exact ordering greenfield ->
  brownfield-large (OR-on-large) -> brownfield-small; the greenfield-proposing first branch is
  present as code.
- [ ] Greenfield is gated on BOTH RM1 AND RM2 being under their thresholds (a 3-file / 50k-LOC repo
  is NOT greenfield); brownfield-large trips if ANY one of RM2/RM3/RM4 is at/over its large
  threshold (a small-LOC but concept-dense repo via RM4 still proposes large).
- [ ] `.aid/generated/recon.md` records the proposed path, the four metric values, and the tripped
  threshold(s).
- [ ] Missing/empty `--candidates` degrades RM4 to 0 (no error); missing `--index` logs a warning
  and proposes `brownfield-small`; the script never exits non-zero on these degrade cases.
- [ ] The `triage:` block exists in `canonical/aid/templates/settings.yml` with all five keys +
  defaults + comments; reads resolve via `read-setting.sh` flat one-level paths (no `yq`).
- [ ] `recon-classify.sh` is ASCII-only and added to `test-ascii-only.sh`'s `SHIPPED_SCRIPTS`.
- [ ] `run_generator.py` re-run; the script + settings template render to all 5 trees + `.claude/`;
  render-drift stays green.
- [ ] All section-6 quality gates pass.
