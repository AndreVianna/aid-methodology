# Execution Graph Generation

Build the execution graph for each delivery after ALL deliverables are detailed.
Write it as a new section in PLAN.md under the corresponding delivery.

---

## Step 5: Build Execution Graph

After ALL deliverables are detailed, build the execution graph for each delivery.
Write it as a new section in PLAN.md under the corresponding delivery.

For each delivery, produce TWO tables:

```markdown
#### Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-002 |
| task-004 | task-002 |
| task-005 | task-003, task-004 |

| Can Be Done In Parallel |
|------------------------|
| task-003, task-004 |
```

**Dependency rules:**
- Every task except the first MUST have at least one dependency
- Dependencies are determined by what each task needs from previous tasks
  (output files, schema changes, service availability, etc.)
- If two tasks share the same dependencies but don't depend on each other → parallel
- The parallel table lists groups of tasks that can safely run concurrently

**This graph is what `/aid-execute` reads to determine task ordering and parallelism.**

**Advance:** **CHAIN** → continue with the parent state's flow.
