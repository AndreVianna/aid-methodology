# Delivery SPEC -- delivery-016: Altitude Signature Exception + Dogfood + Re-inject Lost Depth

[!NOTE]
This is the DELIVERY-LEVEL SPEC.md template. It is the IMMUTABLE DEFINITION for this delivery.
Written once by aid-plan / aid-specify; not a state file. State lives in delivery-016/STATE.md.

> **Delivery:** delivery-016
> **Work:** work-001-kb-skills-improvement
> **Created:** 2026-06-25

---

## Objective

Repair the **altitude-rule signature tax** and run the **live AID dogfood regression** that closes
feature-016. This delivery realizes **Change 3 (FR-56)**: amend `principles.md`'s
altitude/summary+pointer rule (P1(d)) with a **signature exception** so load-bearing operational
contracts an agent must honor to ACT — field types, exit codes, args/modes/invariants — are stated
**INLINE or with a precise grep-recoverable anchor**, never a bare `sources:` file pointer; then run
the dual-intent self-eval on AID's own KB (software + methodology) as the live regression and
**re-inject the AID instance's altitude-rule-evicted depth** (the host-tool matrix, exit-codes) as
the **first beneficiary** of the exception.

## Scope

In scope (feature-016 Change 3, FR-56 + dogfood):

- **Altitude signature exception** — amend `principles.md` P1(d) + the altitude/summary+pointer
  rule: work-critical operational contracts (field types, exit codes, args/modes/invariants) are
  stated inline or with a precise grep-recoverable anchor, never a bare file pointer; the altitude
  rule keeps de-bloating *narrative* volatility but not *work-critical contracts*. Cross-reference
  from `concern-model.md`'s "Operational guidance is first-class structure" section.
- **AID dogfood regression** — run the delivery-015 dual-intent self-eval on AID's own KB
  (software + methodology) as the live regression; confirm both gates pass.
- **Re-inject AID's lost depth** — restore the host-tool matrix + exit-codes the over-broad
  altitude rule evicted from AID's KB docs, as the first beneficiary of the exception (the
  assertiveness gate would otherwise FAIL on the REACH for them).

**Out of scope:** the spine-keyed depth standard (Change 1 — **delivery-013**); the spine-keyed
safeguard (Change 2 — **delivery-014**); the dual-intent self-eval mechanism itself (§4 —
**delivery-015**, which this delivery dogfoods and whose assertiveness gate enforces the exception);
any change to feature-014's spine/matrix/classifier.

## Gate Criteria

- [ ] `principles.md` P1(d) + the altitude/summary+pointer rule carry the **signature exception**:
  load-bearing operational contracts (field types, exit codes, args/modes/invariants) are stated
  **inline or with a precise grep-recoverable anchor**, never a bare `sources:` file pointer; the
  rule still de-bloats narrative volatility. *(FR-56)*
- [ ] The **AID dogfood** runs the delivery-015 dual-intent eval on AID's own KB and **passes both
  gates** (assertiveness + essence) as the live regression. *(FR-56)*
- [ ] AID's previously altitude-rule-evicted depth (host-tool matrix, exit-codes) is **re-injected**
  into the relevant KB docs as the first beneficiary of the exception; the assertiveness gate no
  longer FAILs on a REACH for them. *(FR-56)*
- [ ] **Delivery grade gate = A+**.
- [ ] All section-6 quality gates pass: canonical→render parity (full `run_generator.py`), DBI
  (here both the canonical→`.claude` render-parity check **and** the **`.aid/knowledge/*`
  doc-content sync** — this is the **only** delivery in feature-016 that edits AID's own KB doc
  content, re-injecting the host-tool matrix + exit-codes the over-broad altitude rule evicted),
  ASCII-only + WinPS-5.1 lint for any changed script, KB-hygiene + INDEX-fresh CI green after the
  re-injected depth + regenerated INDEX, and the affected canonical suites re-run green.

## Tasks

> Authored by `/aid-detail`. Each task has a full SPEC + STATE at `tasks/task-NNN/`. The
> `Depends on` ordering and waves are in PLAN.md `### delivery-016 execution graph`.

| Task | Type | Title |
|------|------|-------|
| task-088 | IMPLEMENT | Altitude-rule signature exception in principles.md (+ concern-model.md cross-ref) |
| task-089 | DOCUMENT | Re-inject AID's evicted depth (host-tool matrix, exit-codes) + regen INDEX |
| task-090 | TEST | Run the dual-intent dogfood on AID's KB (both gates pass) + regen/DBI/hygiene re-checks |

## Dependencies

- **Depends on:** delivery-015 (the dual-intent self-eval gates — the assertiveness gate enforces
  the signature exception, and the dogfood runs the delivery-015 mechanism)
- **Blocks:** -- (none; closes feature-016)

## Notes

- **Self-enforcing exception:** the assertiveness limb (delivery-015) is what makes the signature
  exception bite — a contract behind a bare `sources:` pointer becomes a REACH FAIL, so the rule is
  enforced by the gate, not just stated in prose.
- **First beneficiary:** re-injecting AID's host-tool matrix + exit-codes is both the proof and the
  motivating case for the exception (these were evicted by the over-broad altitude rule, per the two
  critique rounds).
- **Design rationale** lives in feature-016 SPEC §4 and the design seed §5.3 + §7 (D-D).
- Affected files: `canonical/aid/templates/kb-authoring/principles.md`,
  `canonical/aid/templates/kb-authoring/concern-model.md`,
  `canonical/aid/templates/kb-authoring/tier-model.md` (if touched),
  AID's own `.aid/knowledge/*.md` docs (re-injected depth) + regenerated `INDEX.md`.
