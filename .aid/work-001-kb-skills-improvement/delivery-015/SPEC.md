# Delivery SPEC -- delivery-015: The Dual-Intent KB Self-Evaluation

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-015/STATE.md.

> **Delivery:** delivery-015
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-25

---

## Objective

Build the **core mechanism** of feature-016 (§4, FR-54 + FR-55): turn the two user intents into
measurable, domain-general REVIEW keystone gates with **no external test corpus**. (1) the **Blind
Work-Simulation** limb — a clean-context KB-only agent plans each derived work probe in the
project's own conventions, tagging STATED/ASSUMED/REACH (the *assertiveness* gate, Intent 1,
generalizing the M4 act-back keystone); (2) the **Blind Reconstruction + Source Confrontation**
limb — a KB-only agent reconstructs the project's essence, then a source-grounded agent confronts
it for Divergence/Omission (the *essence* gate, Intent 2, generalizing the M3 teach-back keystone);
(3) the **probe-derivation helper** (work + essence probes derived from the project's own C9/C4/D
docs + source); and (4) the **dual-intent ledger** + the **convergence thresholds**, wired into
REVIEW as two hard keystone gates. Both limbs run **on the project being discovered, using its own
source as ground truth** — so the gates fire for any domain with no anticipated per-domain content.

## Scope

In scope (feature-016 §4, FR-54 + FR-55):

- **Blind Work-Simulation (assertiveness gate, Intent 1, FR-54)** — the generalized M4 act-back:
  K derived work probes; per-step STATED/ASSUMED/REACH tagging; load-bearing ASSUMED/REACH =
  `[HIGH] [ACTBACK]`; a plan that violates the project's conventions (C3)/invariants/quality bars
  (C6) = a **quality FAIL**; PASS = complete, correct, convention-honoring, zero load-bearing
  insufficiencies. Generalizes `reviewer-prompt-actback.md`.
- **Blind Reconstruction + Source Confrontation (essence gate, Intent 2, FR-55)** — the generalized
  M3 teach-back: stage 1 KB-only reconstruction of what/why/how over essence probes; stage 2 a
  **source-grounded** agent confronts it — **Divergence** = `[HIGH] [FIDELITY]`, load-bearing
  **Omission** = `[MED] [ESSENCE-GAP]`; PASS = no divergence + essence-coverage ≥ threshold.
  Generalizes `reviewer-prompt-teachback.md` with the source-confrontation second stage.
- **Probe-derivation helper** — work probes from the C9 doc + domain (via delivery-014's C9-derived
  selector); essence probes from C4 vocabulary + C9 capabilities + D decisions + high-salience
  source facts; spread across spine dimensions + a minimum count; human confirm/extend at the gate;
  K scales by triage size; probes cache across cycles. Deterministic substrate + ASCII + WinPS-safe.
- **Dual-intent ledger + convergence gates** — the 7-column reviewer-ledger schema with
  `[ACTBACK]`/`[FIDELITY]`/`[ESSENCE-GAP]` tags; REVIEW⇄FIX loop converges until Assertiveness (zero
  `[HIGH] [ACTBACK]`, STATED-coverage ≥ threshold, all quality-contracts present) AND Essence (zero
  `[HIGH] [FIDELITY]`, essence-coverage ≥ threshold) both pass; both are **hard keystone gates** (a
  FAIL caps the grade). Wired into `state-review.md` — **including its §2c/§2d verdict-derivation
  greps**, which today match the literal `[TEACHBACK]`/`[ACTBACK]` strings; the new
  `[FIDELITY]`/`[ESSENCE-GAP]` essence tags and the assertiveness `[ACTBACK]` tag MUST be wired into
  the grade aggregation so the essence verdict no longer keys on `[TEACHBACK]` alone.
- **Per-domain fixtures** — GOOD mini-KBs (PASS both gates) + SHALLOW/WRONG mini-KBs (FAIL the right
  limb) per non-software domain, extending the in-suite `actback-task` fixture pattern, with tiny
  fixture "source" trees for the source-confrontation stage.

**Out of scope:** the spine-keyed depth standard (Change 1 — **delivery-013**) and the spine-keyed
safeguard + C9-derived selector (Change 2 — **delivery-014**), both consumed here; the altitude
signature exception + AID dogfood + depth re-injection (Change 3 — **delivery-016**); any new
grading infra, verdict sentinel, or agent enum value (reuses f005's panel + `grade.sh` + the
ledger schema).

## Gate Criteria

- [ ] The **Blind Work-Simulation** limb runs on any domain: KB-only step-by-step planning with
  STATED/ASSUMED/REACH tagging; load-bearing ASSUMED/REACH = `[HIGH] [ACTBACK]`; a
  convention/invariant/quality-bar violation = a quality FAIL; PASS = complete, correct,
  convention-honoring, zero load-bearing insufficiencies. *(FR-54)*
- [ ] The **Blind Reconstruction + Source Confrontation** limb runs on any domain: KB-only
  reconstruction + a source-grounded confrontation; **Divergence** = `[HIGH] [FIDELITY]`,
  **Omission** = `[MED] [ESSENCE-GAP]`; PASS = no divergence + essence-coverage ≥ threshold. *(FR-55)*
- [ ] Both limbs emit into a **dual-intent ledger** (7-column schema) and are wired into REVIEW as
  **two hard keystone gates** (a FAIL caps the grade), with the convergence thresholds; probes are
  **derived from the project's own C9/C4/D docs + source** (no external corpus). *(FR-54, FR-55)*
- [ ] **Fixtures prove the gates fire off-software:** per-domain GOOD KBs PASS both gates; SHALLOW
  KBs FAIL the assertiveness limb on the missing contract; WRONG KBs FAIL the essence limb on
  divergence; the probe derivation is domain-appropriate (not "add an endpoint"). *(FR-54, FR-55)*
- [ ] **No new grading infra / agent enum:** reuses f005's parallel panel + `grade.sh` + the
  7-column ledger; the only new role-shape is the source-grounded confronter. *(scope discipline)*
- [ ] **Delivery grade gate = A+**.
- [ ] All section-6 quality gates pass: canonical→render parity (full `run_generator.py`), DBI
  (here the **canonical→`.claude` render-parity** check; this delivery edits only `canonical/`
  sources + test fixtures, **not** AID's own `.aid/knowledge/*` doc content — that doc-content DBI
  sync is delivery-016's), ASCII-only + WinPS-5.1 lint for any shipped/changed script, and the new +
  affected canonical suites (the new `test-dual-intent-self-eval.sh`, actback-task, actback-fixtures)
  re-run green.

## Tasks

> Authored by `/aid-detail`. Each task has a full SPEC + STATE at `tasks/task-NNN/`. The
> `Depends on` ordering and waves are in PLAN.md `### delivery-015 execution graph`.

| Task | Type | Title |
|------|------|-------|
| task-083 | IMPLEMENT | Probe-derivation helper (work probes from C9 + essence probes from C4/D + source) |
| task-084 | IMPLEMENT | Blind Work-Simulation limb (generalize reviewer-prompt-actback.md) |
| task-085 | IMPLEMENT | Blind Reconstruction + Source-Confrontation limb (generalize reviewer-prompt-teachback.md) |
| task-086 | IMPLEMENT | Wire the dual-intent ledger + convergence keystone gates into state-review.md (incl. §2c/§2d greps) |
| task-087 | TEST | Per-domain GOOD/SHALLOW/WRONG mini-KB fixtures + test-dual-intent-self-eval.sh |

## Dependencies

- **Depends on:** delivery-013 (the spine-keyed depth standard the FIX loop drives toward),
  delivery-014 (the spine-keyed safeguard owning-table + the C9-derived task selector that seeds
  the work probes)
- **Blocks:** delivery-016 (the altitude signature exception is enforced + dogfooded by the
  assertiveness gate built here)

## Notes

- **Extend, don't re-spec:** generalizes f005's M3 + f013's M4 reviewer-prompt bodies; reuses the
  parallel-panel dispatch + `grade.sh` + the 7-column ledger verbatim; no separate verdict
  sentinel, no new agent enum value. The probe-derivation helper extends `kb-actback-task.sh` /
  `kb-teachback-questions.sh`.
- **Self-eval property:** both limbs run on the project being discovered, using its own source as
  ground truth and its own capabilities as task seeds — no external test corpus.
- **Design rationale** lives in feature-016 SPEC §3 and the design seed §4 (the full mechanism).
- Affected files: `canonical/skills/aid-discover/references/reviewer-prompt-actback.md`,
  `canonical/skills/aid-discover/references/reviewer-prompt-teachback.md`,
  `canonical/skills/aid-discover/references/state-review.md` (incl. the **§2c/§2d
  verdict-derivation greps** — re-key off the literal `[TEACHBACK]`/`[ACTBACK]` strings onto the new
  `[FIDELITY]`/`[ESSENCE-GAP]` + `[ACTBACK]` tags in the grade aggregation),
  `canonical/skills/aid-discover/references/state-generate.md`,
  a new probe-derivation helper under `canonical/aid/scripts/kb/`,
  new/extended `tests/canonical/test-dual-intent-self-eval.sh` + fixtures.
