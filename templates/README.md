# AID Templates

Reusable document templates for every artifact produced during the AID lifecycle.

## Knowledge Base (Discovery Phase)

The Knowledge Base is AID's gravitational center — 13 documents that capture the living understanding of a project.

→ [knowledge-base/](knowledge-base/) — One template per KB document, with guidance and examples.

## Requirements (Interview Phase)

→ [requirements/requirements-template.md](requirements/requirements-template.md) — Structured requirements document produced by adaptive interview.

## Specifications (Specify Phase)

→ [specs/spec-template.md](specs/spec-template.md) — SPEC.md grounded in the Knowledge Base with traceability to requirements.

## Delivery Plans (Plan + Detail Phases)

→ [delivery-plans/delivery-template.md](delivery-plans/delivery-template.md) — High-level delivery plan (strategy)
→ [delivery-plans/detail-template.md](delivery-plans/detail-template.md) — Detailed execution plan (tactics)
→ [delivery-plans/task-template.md](delivery-plans/task-template.md) — Individual task specification

## Feedback Artifacts

These are produced when a phase discovers that upstream assumptions were wrong. They're the formal mechanism that prevents silent workarounds.

→ [feedback-artifacts/GAP.md](feedback-artifacts/GAP.md) — Knowledge Base gap discovered during any phase
→ [feedback-artifacts/IMPEDIMENT.md](feedback-artifacts/IMPEDIMENT.md) — Implementation blocker requiring plan/spec revision
→ [feedback-artifacts/TRIAGE.md](feedback-artifacts/TRIAGE.md) — Production finding classification and routing

## Reports

→ [reports/review-template.md](reports/review-template.md) — Code review report with grading
→ [reports/test-report-template.md](reports/test-report-template.md) — Staging/E2E test validation report
→ [reports/track-report-template.md](reports/track-report-template.md) — Production monitoring report
→ [reports/correction-template.md](reports/correction-template.md) — *(Deprecated)* Bug fix scope and root cause analysis — now included in TRIAGE.md

---

## How to Use

1. Copy the relevant template into your project
2. Fill in the sections — guidance comments explain what goes where
3. Remove the guidance comments when done
4. The completed artifact becomes input for the next phase

Templates are designed to be **opinionated defaults**, not rigid forms. Adapt them to your project's needs.
