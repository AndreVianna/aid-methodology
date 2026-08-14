# Delivery Issue Log -- delivery-001

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded -- grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-014 | [HIGH] | aid-update-roadmap description names /aid-create-roadmap, a confusable neighbour SPEC 6d does not assign it (V25: no neighbour it does not) | Open |
| task-014 | [HIGH] | aid-update-mvp description names /aid-create-roadmap, a confusable neighbour SPEC 6d does not assign it (V25: no neighbour it does not) | Open |
| task-016 | [HIGH] | EVIDENCE.md 4.7 records the V6/V16 determinism replay with no command; either two further non-realizing invocations went unrecorded (breaching the all-invocations record obligation and AC-11's cap of two) or the skills were never re-run and determinism is unestablished for those rows | Open |
| task-016 | [HIGH] | Six shipped skills (aid-create/update-roadmap/mvp/backlog) order the refusal to name the override flag, but no literal token is defined in canonical/ -- the documented bypass is unreachable and each run invents its own. Not task-016's to fix; owned by the skill-authoring tasks / feature-002 contract | Open |
| task-015 | [HIGH] | .aid/knowledge/roadmap.md:155 cites decisions.md for a claim that document does not make; D19 records the opposite (Accepted, delivery-002 withdrawn). Found by task-022, confirmed by its reviewer; task-022 could not fix it because its own criteria require restoring roadmap.md unchanged | Open |
