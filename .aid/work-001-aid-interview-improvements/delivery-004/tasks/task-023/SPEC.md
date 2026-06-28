# task-023: Thread greenfield review param + reconcile state-review.md panel exclusion

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-004

**Depends on:** task-022

**Scope:**
- Wire the `greenfield: true|false` review parameter (default `false`) through the aid-discover review
  subsystem so a seed review invoked in greenfield mode reaches the FULL panel and honors task-022's
  Greenfield-mode block, while brownfield review (default false) stays byte-unchanged (NFR-2). Two files:
- **`canonical/skills/aid-discover/references/reviewer-brief.md`** -- add `greenfield: true|false`
  (default `false`) as a review parameter threaded into the rendered brief alongside the existing doc-set
  parameterization (D-5); when set, the brief instructs the reviewer to apply the
  `document-expectations.md` Greenfield-mode block (intent-evidence substituted, as-built red flags
  relaxed, dimension floors retained). Default-false rendering is unchanged.
- **`canonical/skills/aid-discover/references/state-review.md`** -- reconcile the existing
  **lines ~117-118 "Greenfield never reaches the panel"** exclusion into the REQUIRED two-case form
  (feature-003 SPEC "Panel-exclusion reconciliation"):
  - KEEP: a project *classified* greenfield in aid-discover's brownfield-discovery **triage (Step 0f)** has
    nothing extracted to deeply review, so its `panel:` branch collapses and it skips the panel -- correct
    FOR DISCOVERY, retained.
  - ADD: a **`greenfield: true` seed-review invocation** is a DISTINCT path (NOT entered via Step 0f
    triage; invoked from the `aid-describe` seed-authoring step, flow step 5) and per NFR-3 MUST traverse
    the **full** panel in greenfield mode (same dimension floors; intent-evidence substituted; as-built red
    flags relaxed).
  - The edit MUST replace the blanket "never reaches the panel" assertion with this two-case
    disambiguation; leaving it as the blanket form is a FAIL.
- ASCII-only; no script/schema change; default-false brownfield review path unaffected.
- **Out of scope:** the Greenfield-mode expectations block itself (task-022); the seed-authoring step that
  SETS `greenfield: true` (task-025); render (task-026).

**Acceptance Criteria:**
- [ ] `reviewer-brief.md` threads `greenfield: true|false` (default `false`) and, when true, instructs the reviewer to apply the `document-expectations.md` Greenfield-mode block; default-false rendering is byte-unchanged (verify via diff). *(NFR-2/NFR-3, D-5; gate criterion 1)*
- [ ] `state-review.md`'s former blanket "Greenfield never reaches the panel" (lines ~117-118) is replaced by the two-case form: discovery-triage greenfield -> collapsed/skipped panel RETAINED, AND `greenfield: true` seed-review -> FULL panel in greenfield mode ADDED. *(NFR-3 "same gate"; gate criterion 1)*
- [ ] The two greenfield contexts (discovery-skip vs seed-review-full) are unambiguously disambiguated; no blanket exclusion remains. *(panel-exclusion reconciliation; gate criterion 1)*
- [ ] Brownfield review (`greenfield: false`/absent) path is unaffected outside the additive param + the carve (verify via diff). *(NFR-2; gate criterion 2)*
- [ ] ASCII-only; skill reference is prose-executed (no unit test; IMPLEMENT unit-test default overridden -- exercised by the greenfield-gate + brownfield-intact runs at task-027). All REQUIREMENTS.md §6 quality gates pass.
