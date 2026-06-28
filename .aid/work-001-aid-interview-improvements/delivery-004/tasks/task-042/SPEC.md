# task-042: ADR immutability / supersession for the greenfield decisions element (web-validation G1)

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-004 (post-gate hardening; added 2026-06-28 from the web greenfield best-practice validation)

**Depends on:** task-025 (the seed-authoring state authors the 5-element model incl. the decisions element), task-031 (the conformance CL-Step 2 "Evolve the design" path)

**Scope:**
The web greenfield-validation (`features/feature-001-elicitation-research-spike/research/web-greenfield-validation.md`)
found gap **G1**: the greenfield seed's `decisions.md` element captures what/why/rejected-alternative but lacks
**ADR immutability + supersession history** (Nygard / JPH ADR convention treats this as essential) -- it is edited
in place, with no superseded-decision chain. Add the ADR-superseding discipline to the decisions element (prose;
IMPLEMENT unit-test default OVERRIDDEN -- skill prose, exercised by review):

- In `canonical/skills/aid-describe/references/state-describe-seed.md` (the decisions element / element-5 authoring
  guidance): a recorded decision is **immutable**. When a decision changes, the analyst APPENDS a NEW decision entry
  that **supersedes** the prior one (a `Status: Accepted | Superseded` field + a `Superseded-by:` / `Supersedes:`
  link), rather than editing the original in place. Keep the existing what/why/rejected-alternative content; add the
  status + supersession chain. Ground it in the Nygard ADR convention (cite the web-validation G1).
- Reconcile with the conformance lane: in `canonical/skills/aid-housekeep/references/state-kb-delta.md` CL-Step 2,
  the "[1] Evolve the design" outcome FOR A DECISION must mean **append a superseding decision entry** (preserving
  the superseded one), NOT overwrite the original -- consistent with the flag-not-overwrite invariant + ADR
  immutability. Add a one-line note so the two agree (do NOT change the human-gate flow).
- If a decisions-element template/shape is referenced (e.g. in the seed doc-set or a kb-authoring template), align it
  with the status/supersession fields. Keep it lightweight (a small schema + the rule, not a full ADR tool).

Do NOT change the other 4 seed elements, the coherence check's two layers, the freshness short-circuit, the
greenfield review gate, or any brownfield mechanism. Edit CANONICAL only (IMPLEMENT-only); the FULL generator render
to the 5 profiles + `.claude` mirror + the re-gate are done AFTER (orchestrator render + delivery-004 re-gate).
ASCII-only.

**Acceptance Criteria:**
- [ ] `state-describe-seed.md` decisions element specifies ADR **immutability + supersession** (new entry supersedes; `Status` + `Superseded-by`/`Supersedes` chain; original never edited in place), grounded in the Nygard ADR convention. *(G1)*
- [ ] `state-kb-delta.md` CL-Step 2 "[1] Evolve the design" for a DECISION = append a superseding entry (not overwrite); consistent with flag-not-overwrite. *(G1 reconciliation)*
- [ ] The existing what/why/rejected-alternative decisions content is preserved (additive, not a rewrite); the other 4 elements + coherence + freshness + review gate untouched. *(no regression)*
- [ ] ASCII-only; no brownfield mechanism touched.
- [ ] REQUIREMENTS.md s6 quality gates pass (full render + DBI + suites confirmed at the re-gate).
