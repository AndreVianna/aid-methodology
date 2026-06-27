# task-083: Probe-derivation helper (work probes from C9 + essence probes from C4/D + source)

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-083/STATE.md.

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-015

**Depends on:** task-081 (the C9-derived task selector that seeds the work probes), task-078 (the
spine-keyed depth standard the derived probes target)

**Scope:**
- Realize feature-016 §4.0 probe derivation (FR-54 + FR-55 substrate). Edit **canonical** sources
  only; the full `run_generator.py` regen + `.claude` sync is the regen step.
- **The probe-derivation helper** under `canonical/aid/scripts/kb/` (extends `kb-actback-task.sh` /
  `kb-teachback-questions.sh` rather than adding parallel infra):
  - **Work probes (Intent 1):** derive K representative tasks from the **C9 capability/what-it-does
    doc** + the domain — reusing delivery-014's C9-derived selector as the deterministic seed —
    selected so the set collectively exercises the load-bearing dimensions (C5 data/contracts, C3
    conventions, C2 parts, C6 quality).
  - **Essence probes (Intent 2):** derive "what is X / how does Y work / why Z" probes over the
    project's load-bearing concepts, sampled from the **C4 vocabulary** + **C9 capabilities** + **D
    decisions** docs and from high-salience source facts.
  - **Spread + minimum-count + cache:** probes spread across spine dimensions with a minimum count;
    probes **cache across REVIEW⇄FIX cycles** (cost mitigation, §8); K scales by triage size. The
    **human confirm/extend at the gate** hook (the no-assumptions pattern) is exposed.
- The helper is **deterministic** where mechanical (same doc-set + same C9/C4/D docs -> same probe
  set), **ASCII-only + WinPS-5.1-safe**, and reuses the existing helper conventions (no new agent
  enum, no separate verdict sentinel). Run the full `run_generator.py` regen -> `.claude` sync; never
  edit the rendered `.claude/` copy.

**Acceptance Criteria:**
- [ ] A probe-derivation helper under `canonical/aid/scripts/kb/` derives **work probes** from the C9
  doc + domain (reusing delivery-014's C9-derived selector) and **essence probes** from C4 + C9 + D
  docs + high-salience source facts. *(FR-54, FR-55, §4.0)*
- [ ] Probes are **spread across spine dimensions** with a minimum count, **cache across REVIEW⇄FIX
  cycles**, scale K by triage size, and expose a **human confirm/extend** hook at the gate (the
  no-assumptions pattern). *(§4.0, §8)*
- [ ] The helper is **deterministic** (same doc-set + same C9/C4/D docs -> same probe set),
  **ASCII-only + WinPS-5.1-safe**, and adds **no new agent enum / verdict sentinel / grading infra**
  (extends `kb-actback-task.sh` / `kb-teachback-questions.sh`). *(NFR-3, scope discipline)*
- [ ] Edits are `canonical/...` only; the full `run_generator.py` regen + `.claude` sync run.
- [ ] All section-6 quality gates pass.
