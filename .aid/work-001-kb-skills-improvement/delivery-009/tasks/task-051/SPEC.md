# task-051: Greenfield path behavior -- state-generate.md elicit-via-interview/specify wiring + collapsed panel + same f004 closure

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-009

**Depends on:** task-025 (delivery-004), task-011 (delivery-001), task-014 (delivery-001)

**Scope:**
- Turn the **greenfield route-note** task-025 (delivery-004) left in
  `canonical/skills/aid-discover/references/state-generate.md` into the actual greenfield PATH
  BEHAVIOR. task-025 wired Step 0f (recon-classify + the propose->confirm triage gate, including the
  `[3] Override greenfield` confirm option and the `## Discovery Triage` write) and left greenfield
  as a **route-note only** in the Steps 2-5 fan-out ("greenfield => elicit via
  `aid-interview`/`aid-specify`; behavior is delivery-009"). This task replaces that route-note with
  the running behavior. It does **NOT** re-spec recon-classify (task-023), the triage gate / Step 0f
  (task-025), the f004 closure loop (task-011), or the f005 panel (task-014) -- it CONSUMES them.
- Amend `canonical/skills/aid-discover/references/state-generate.md` so that, when the confirmed
  `## Discovery Triage` path is **greenfield**, GENERATE:
  - **Skips the Steps 2-5 deep-dive fan-out entirely** (per f006's matrix: greenfield fan-out =
    "none -- nothing to extract"). No `aid-researcher` understand-pass is dispatched (greenfield has
    no source to extract from -- distinct from brownfield-small, which still runs ONE understand-pass).
  - **Routes spine elicitation to the EXISTING `aid-interview` / `aid-specify` skills** (f006 SPEC
    "Greenfield Path"): the concept spine is **elicited** from the project's intent
    (requirements/design artifacts + the human elicitation turns those skills already drive), NOT
    extracted from a source sweep. Author this as a **route step** that hands off to those skills and
    consumes their output as the thin intent-KB seed; build **NO bespoke greenfield generation
    engine** (boundary: interview/specify are reused as-is, NOT re-spec'd).
  - **Feeds the elicited thin intent-KB into the standard f004 spine + closure machinery unchanged**
    (the same `state-closure.md` loop task-011 authored): greenfield uses the **same closure caps as
    brownfield-small** (`max_rounds: 1`, `max_clean_passes: 1`, supplied via the Step-5b
    `--max-clean-passes`/`--max-rounds`/`--token-budget` runtime-arg interface task-025 wired and
    task-011 owns) and reaches **teach-back closure -- the invariant exit, NOT a greenfield-specific
    redefinition**. Only the closure loop's *input* differs (intent-sourced rather than
    source-extracted); the loop, caps, and exit bar are identical to brownfield-small.
  - **Drives the f005 REVIEW panel in the `collapsed` shape** -- the same `review.panel: collapsed`
    value `path-config.md` (task-025) already records for greenfield: ONE reviewer running the four
    content mandates (M1/M2/M3/M5) as separate sequential passes + ONE clean-context teach-back
    reviewer (M4). This is a CONSUMPTION of the collapsed-panel behavior already built for
    brownfield-small (task-025's path-config row + the `state-review.md` `review.panel` branch
    f005/task-014 exposed); greenfield reuses it with NO new panel logic. Confirm the greenfield path
    threads `review.panel: collapsed` into REVIEW exactly as brownfield-small does (no
    greenfield-specific panel branch).
- Add a **greenfield->brownfield transition note** to `state-generate.md` Step 0f's idempotent
  re-entry (re-triage) branch, consistent with the behavior task-025 already wired: when a prior
  greenfield run is re-triaged after code lands, the freshly-measured path re-routes to
  brownfield-small/large and the **standard brownfield engine** captures the now-extractable anatomy;
  crossing `large_min_*` triggers a brownfield-large consolidation. State explicitly that the
  transition is handled by **re-triage + the standard brownfield engine** with **NO bespoke
  intent-vs-as-built transition verifier** (none is in scope -- f006 SPEC). This is a documentation/
  wiring clarification on the existing re-triage branch, not a new mechanism.
- Edit canonical only; re-run `python .claude/skills/generate-profile/scripts/run_generator.py`;
  commit the regenerated `profiles/` so the `state-generate.md` edit renders to all 5 host trees +
  the repo `.claude/` working copy (render-drift stays green; **[SPIKE-T4]** -- regen, never
  hand-place).

**Acceptance Criteria:**
- [ ] `state-generate.md`'s greenfield branch SKIPS the Steps 2-5 fan-out entirely (no
  `aid-researcher` understand-pass) and ROUTES spine elicitation to `aid-interview`/`aid-specify`;
  the route-note task-025 left is replaced by running behavior. No bespoke greenfield generation
  engine is added; interview/specify are reused, not re-spec'd.
- [ ] The elicited thin intent-KB feeds the SAME f004 closure loop (`state-closure.md`, task-011)
  with greenfield caps `max_rounds: 1` / `max_clean_passes: 1` supplied via the Step-5b runtime-arg
  interface (task-025/task-011); the closure loop, caps, and teach-back exit are byte-for-byte the
  brownfield-small behavior -- no greenfield-specific exit or redefined closure.
- [ ] Teach-back closure is the invariant exit on the greenfield path (M4 grades whether a fresh
  reviewer can explain the system + define each concept from the thin KB -- the identical M4 bar used
  on the brownfield paths, with no greenfield carve-out).
- [ ] The greenfield path threads `review.panel: collapsed` into f005's REVIEW exactly as
  brownfield-small does (the path-config.md greenfield row + the `state-review.md` `review.panel`
  branch task-025/task-014 built); no new or greenfield-specific panel logic is introduced.
- [ ] Step 0f's re-triage (idempotent re-entry) branch documents the greenfield->brownfield
  transition as re-triage + the standard brownfield engine (re-measure -> re-route -> brownfield
  extract; crossing `large_min_*` -> brownfield-large consolidation), with NO intent-vs-as-built
  transition verifier in scope.
- [ ] No new shipped script is added (wiring/behavior only); recon-classify (task-023), Step 0f /
  triage gate (task-025), the f004 closure loop (task-011), and the f005 panel (task-014) are
  CONSUMED, not re-spec'd or edited beyond the greenfield branch in `state-generate.md`.
- [ ] `run_generator.py` re-run; the `state-generate.md` edit renders to all 5 trees + `.claude/`;
  render-drift stays green.
- [ ] All section-6 quality gates pass.
