# Plan -- work-021-release-aid-skill

> **Work:** work-021-release-aid-skill
> **Created:** 2026-07-22

---

## Deliverables

- **Delivery:** delivery-001 -- release-aid Maintainer Release Skill
- **What it delivers:** A repo-local, maintainer-only `/release-aid <level>` skill that executes the AID repo's own release end-to-end (RESOLVE → PRECHECK → BUMP → DOCS+NOTES → PR → DRY-RUN → TAG → VERIFY → CONFIRM), pausing only at the three irreversible human-gated points, and making the release-notes + documentation sweep a mandatory step of every release.
- **Features:** feature-001-release-aid-skill   (the single feature; no `features/` folder)
- **Depends on:** -- (none -- single delivery)
- **Priority:** Must

> **Reality note (light task breakdown).** The authoritative artifact
> (`.claude/skills/release-aid/SKILL.md`) is **already authored and settled with the
> user**; this work *formalizes* it, so task-001 (author the skill) is effectively
> complete on arrival. The remaining tasks are validation (task-002) and the one-time
> reconciliation of the pre-existing broken ledger/doc backlog this work surfaced
> (task-003 — whose disposition is open decision OD-1). Per-task `DETAIL.md` files are a
> later step (`/aid-detail`), not authored now.

---

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | task-001 |
| task-003 | task-001 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
| 2 | task-002, task-003 |
