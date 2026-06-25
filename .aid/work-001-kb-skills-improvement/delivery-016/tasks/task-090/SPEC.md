# task-090: Run the dual-intent dogfood on AID's KB (both gates pass) + regen/DBI/hygiene re-checks

[!NOTE]
This is the TASK-LEVEL SPEC.md. Immutable definition. State lives in task-090/STATE.md.

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-016

**Depends on:** task-089

**Scope:**
- Run the **live AID dogfood regression** that closes feature-016 (FR-56). TEST only — no skill
  behavior changes here.
- **Dogfood the delivery-015 dual-intent self-eval on AID's own KB** (software + methodology):
  derive the probes from AID's own C9/C4/D docs + source, run the **assertiveness** limb (Blind
  Work-Simulation) and the **essence** limb (Blind Reconstruction + Source Confrontation), and
  confirm **both keystone gates PASS** (zero `[HIGH] [ACTBACK]` + STATED-coverage >= threshold + all
  quality-contracts present; zero `[HIGH] [FIDELITY]` + essence-coverage >= threshold).
- **Signature-exception regression:** confirm the assertiveness gate **no longer FAILs on a REACH**
  for the re-injected host-tool matrix + exit-codes (task-089) — i.e. those contracts now resolve
  STATED, proving the exception + re-injection landed.
- **Threshold calibration confirmation:** confirm the task-086 thresholds (>=90% STATED / essence)
  hold against the AID dogfood + the per-domain fixtures; record any calibration adjustment in
  task-090/STATE.md `## Notes` (the deferred §8 calibration resolves here).
- **Build / hygiene re-checks:** canonical -> `.claude` render-parity **and** the `.aid/knowledge/*`
  doc-content sync (this delivery edits AID's own KB docs); **KB-hygiene + INDEX-fresh** CI green
  after the regenerated INDEX; ASCII-only + WinPS-5.1 lint for any changed script; the affected
  canonical suites re-run green. HOME-pinned where any suite scans (the AID-scan HOME-pin lesson).

**Acceptance Criteria:**
- [ ] The delivery-015 dual-intent eval runs on **AID's own KB** (software + methodology) and
  **PASSes both gates** (assertiveness + essence) as the live regression. *(FR-56)*
- [ ] The assertiveness gate **no longer FAILs on a REACH** for the re-injected host-tool matrix +
  exit-codes — they resolve STATED, proving the signature exception + re-injection landed. *(FR-56)*
- [ ] The task-086 PASS **thresholds** are confirmed against the AID dogfood + fixtures; any
  calibration adjustment is recorded (the §8 deferral resolves here). *(FR-54, FR-55, §8)*
- [ ] **DBI green** (canonical -> `.claude` render-parity **and** `.aid/knowledge/*` doc-content
  sync); **KB-hygiene + INDEX-fresh** CI green; ASCII-only + WinPS-5.1 lint green; the affected
  canonical suites re-run green. *(section-6)*
- [ ] All section-6 quality gates pass.
