# Delivery SPEC -- delivery-001: work-002-dashboard-export-buttons lite execution

> **Delivery:** delivery-001
> **Work:** work-002-dashboard-export-buttons
> **Created:** 2026-06-27

---

## Objective

Single delivery for lite-path work work-002-dashboard-export-buttons. All tasks execute on the
`aid/work-002-dashboard-export-buttons-delivery-001` branch and are gated together at
delivery-001 close.

## Scope

All tasks defined in the work-root SPEC.md `## Tasks` section.

**Out of scope:** Future deliveries (this is the sole lite-path delivery). Profile/manifest
regeneration and user-doc/release-tracking updates are intentionally excluded from this work's
task set (handled later via /aid-housekeep / /aid-deploy if needed).

## Gate Criteria

- [ ] All tasks in delivery-001 are Done or Canceled.
- [ ] Delivery grade meets or exceeds the minimum grade for this work.
- [ ] All section-6 quality gates pass.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Generation-time Markdown export payload |
| task-002 | IMPLEMENT | Client-side export chrome (buttons + Blob download + print-CSS) |
| task-003 | TEST | Export behaviors + §7 Playwright visual gate + a11y/theme |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Lite-path work: single delivery, no features/ folder, no REQUIREMENTS.md, no PLAN.md.
Source: /aid-interview lite path, sub-path LITE-FEATURE.
