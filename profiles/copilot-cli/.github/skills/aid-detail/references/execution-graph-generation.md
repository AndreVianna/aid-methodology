# Execution Graph Generation

Build the execution graph for each delivery after ALL deliverables are detailed.
Write it as a new section in PLAN.md under the corresponding delivery.

---

## Step 5: Build Execution Graph

After ALL deliverables are detailed, build the execution graph for each delivery.
Write it as a new section in PLAN.md under the corresponding delivery.

For each delivery, produce TWO tables **plus** a normalized `wave-map` block (see below):

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

### Normalized wave-map block (PF-5a) — DERIVED, never authored

The dashboard reader consumes a machine-readable `wave-map` block per delivery. **Do not write
it by hand.** A wave-map is a topological sort of the `Depends On` table you just wrote, so it
carries no information that table does not — computing it by hand spends effort on arithmetic and
can silently disagree with the table it came from.

Write the derived blocks into `PLAN.md`:

```bash
bash .github/aid/scripts/execute/derive-waves.sh <path-to-PLAN.md> --write
```

`--write` is **idempotent** and splices each block into its own delivery section:
existing blocks are replaced, not appended, so re-running after correcting a dependency table is
safe and running it twice changes nothing. On a plan that is already correct it is a byte-identical
no-op. **Never redirect the output with `>>`** — that duplicates every block.

Then confirm the file agrees with itself:

```bash
bash .github/aid/scripts/execute/derive-waves.sh <path-to-PLAN.md> --check
```

`--check` exits 0 when every block matches its table, 1 on a disagreement (printing both), and 2
on a malformed graph — a dependency cycle, or a task the table never defines. **A non-zero exit is
a defect in the dependency table, not in the script:** fix the table and re-derive.

This replaces the former hand-derivation steps and their manual totality self-check. Both are now
guaranteed by construction: `tests/canonical/test-derive-waves.sh` pins the ordering, the exact
output format, totality, cycle detection, and read-only behaviour.

The emitted format, for reference when reading a plan:

````markdown
```wave-map
delivery: 001
wave 1: task-001
wave 2: task-002, task-003
```
````

The reader builds `task_id -> {delivery: NNN, lane: N}` from `delivery:` and each `wave N:` line.
Because the lane value comes from the wave *number*, two `wave 2:` lines are indistinguishable
from one holding the same tasks — so the script emits one line per wave, and no sub-lane judgment
is required.

**Advance:** **CHAIN** → continue with the parent state's flow.
