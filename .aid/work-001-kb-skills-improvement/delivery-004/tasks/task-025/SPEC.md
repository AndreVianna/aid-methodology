# task-025: path-config.md 3-path matrix + per-path f004 closure-cap runtime-arg wiring (Step 0f + Steps 2-5 + Step 5b)

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-004

**Depends on:** task-023, task-011 (delivery-001)

**Scope:**
- Author `canonical/skills/aid-discover/references/path-config.md` -- the path config matrix that
  the GENERATE / closure / review states read for the per-path knobs. One row per brownfield path
  (brownfield-small / brownfield-large) mapping each to: source-of-truth, concept acquisition, f004
  deep-dive fan-out (on/off), f004 `discovery.closure` caps (`max_rounds` / `max_clean_passes`),
  f005 `review.panel` size (`full` / `collapsed`), the 5 invariant review mandates, the exit, the
  starting KB, and cost. **Teach-back closure is noted as the invariant exit on BOTH brownfield
  rows.** A **greenfield row** is also present, but its action is **signpost + HALT** -- none of the
  generation columns (fan-out / closure / panel) apply to it.
  - **brownfield-large:** fan-out on; f004 default caps (`max_rounds: 4`, `max_clean_passes: 2`);
    `review.panel: full`.
  - **brownfield-small:** fan-out OFF (ONE understand-pass `aid-researcher` over the small source,
    not the 4-way parallel fan-out); caps `max_rounds: 1`, `max_clean_passes: 1`;
    `review.panel: collapsed`.
  - **greenfield:** action = **signpost + HALT** ("Nothing to discover yet -- run `/aid-interview`
    to define the project; the KB fills in as you build, via re-triage once code lands"). No fan-out,
    no closure caps, no `review.panel` value -- greenfield is detect+signpost, not a generation path.
    (Forward-authoring a KB-seed from intent is a future interview-side work, out of scope.)
- Amend `canonical/skills/aid-discover/references/state-generate.md`:
  - Add **Step 0f** after f004's Step 0e (harvest) and before Step 1 (pre-scan): run
    `recon-classify.sh`; print `[0f] Recon: measuring project shape...` and `[0f] Proposed path:
    <path> (source-files=N, LOC=M, dirs=D, concepts=C)`; THEN the propose->human-confirm triage
    PAUSE-FOR-USER-DECISION (mirroring Step 0d / `aid-interview`'s TRIAGE -- single confirm turn,
    [1] confirm proposed / [2] override / [3] override); idempotent re-entry = re-triage (if
    `## Discovery Triage **Path:**` already exists, re-measure and show the prior->new diff, ask to
    confirm the transition or keep). Write the confirmed path to `## Discovery Triage` in the KB
    STATE file (`.aid/knowledge/STATE.md`, per [SPIKE-T6]; the re-entry read targets the same file
    the write targets), recording `**Path:** / **Measured:** / **Proposed:** / **Decision
    rationale:** / **Re-triaged:**` and `**Override:**` when the human chose a non-proposed path.
    Then branch on the confirmed path: on **greenfield**, print the **signpost and HALT** -- "Nothing
    to discover yet -- run `/aid-interview` to define the project; the KB fills in as you build, via
    re-triage once code lands" -- do NOT chain to Step 1 (no fan-out / closure / panel runs;
    GENERATE ends). On a **brownfield** path, CHAIN -> Step 1 with the confirmed path parameterizing
    the rest of GENERATE.
  - Add the **path parameter to the Steps 2-5 deep-dive fan-out**: for brownfield-small skip the
    4-way parallel fan-out and dispatch ONE understand-pass `aid-researcher` over the small source;
    for brownfield-large run the full fan-out (path-config.md is the source of the fan-out on/off
    bit). **Greenfield never reaches the fan-out** -- it halted at the Step 0f signpost (above), so
    Steps 2-5 only ever run for the two brownfield paths.
  - Add the **per-path closure-cap runtime argument to Step 5b**: the orchestrator passes the
    path-derived caps (`--max-clean-passes` / `--max-rounds` / `--token-budget`, from
    `path-config.md`) to f004's Step 5b closure step -- the cap-override interface **specified and
    owned in f004's SPEC (Step 5b)** and wired in delivery-001 task-011. brownfield-large uses
    f004's defaults (no override needed); brownfield-small passes `--max-rounds 1`
    `--max-clean-passes 1`. NO two-level nested settings read; the override is a runtime parameter
    (C1/NFR-8 -- no `yq`). Greenfield never reaches f004's closure -- it halted at the Step 0f
    signpost, so Step 5b only runs for the two brownfield paths.
- This task CONFIGURES f004 (sets its knobs per path via the existing Step-5b interface); it does
  NOT re-spec f004's closure loop, harvest, or the cap-override interface itself.
- Re-run `python .claude/skills/generate-profile/scripts/run_generator.py`; commit regenerated
  `profiles/` so the new reference + the `state-generate.md` edit render to all 5 trees + `.claude/`
  (render-drift stays green; **[SPIKE-T4]**).

**Acceptance Criteria:**
- [ ] `path-config.md` has one row per brownfield path with all matrix dimensions filled per the
  feature-006 matrix; teach-back closure is stated as the invariant exit on both brownfield rows. A
  greenfield row is present whose action is **signpost + HALT** (no generation columns apply).
- [ ] `path-config.md` records, per brownfield path: fan-out on/off, the
  `max_rounds`/`max_clean_passes` caps, and the `review.panel` value (`full` for brownfield-large;
  `collapsed` for brownfield-small).
- [ ] `state-generate.md` Step 0f runs recon-classify, then a PAUSE-FOR-USER-DECISION confirm gate,
  with idempotent re-entry (prior `**Path:**` => re-triage diff + re-confirm) and writes
  `## Discovery Triage` to `.aid/knowledge/STATE.md` (read + write target the same file).
- [ ] On a confirmed greenfield verdict, Step 0f prints the signpost ("Nothing to discover yet --
  run `/aid-interview` ...") and HALTS -- it does NOT chain to Step 1 (no fan-out / closure / panel).
- [ ] The Steps 2-5 fan-out branches on the confirmed path (brownfield-small => one understand-pass;
  brownfield-large => full 4-way fan-out); greenfield never reaches the fan-out (it halted at Step 0f).
- [ ] Step 5b supplies the per-path closure cap via the `--max-clean-passes`/`--max-rounds`/
  `--token-budget` runtime args (f004's Step-5b interface); brownfield-large uses defaults,
  brownfield-small passes `max_rounds:1`/`max_clean_passes:1`; no nested settings read is introduced
  (greenfield never reaches f004 closure -- it halted at the signpost).
- [ ] `run_generator.py` re-run; the new reference + the edit render to all 5 trees + `.claude/`;
  render-drift stays green.
- [ ] All section-6 quality gates pass.
