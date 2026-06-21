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

### Normalized wave-map block (PF-5a)

Immediately after the human-facing dependency tables above, also emit a fenced `wave-map` block
for **each** `### delivery-NNN execution graph` section. This block is the machine-readable lane
map consumed by the dashboard reader. Keep the prose/dependency tables too — the `wave-map` is
additive and does not replace them.

A "wave" (lane) is the set of tasks that can start at the same point in the sequential execution
order derived from the dependency graph: wave 1 = tasks with no dependencies; wave 2 = tasks
whose only dependencies are wave-1 tasks; and so on. Where a wave contains parallel sub-lanes
(e.g. two independent feature tracks that both unblock at the same wave), emit one `wave N:` line
per sub-lane so the dashboard can distinguish them.

#### DERIVATION rule (PF-5a+)

The agent MUST derive the wave-map **mechanically** from the `Depends On` table it just wrote —
**not** hand-compose it independently:

1. **Wave 1:** collect every task whose `Depends On` entry is `—` (no dependencies).
2. **Wave N (N > 1):** collect every task whose ALL dependencies are already assigned to waves
   `< N`. Repeat until every task is assigned.
3. **Parallel sub-lanes within a wave:** where two or more tasks in the same wave are independent
   of each other AND represent distinct execution tracks (e.g. two feature lanes), emit one
   `wave N:` line per sub-lane. Tasks that are fully parallel with no inter-dependence within
   the wave MAY be listed on the same `wave N:` line when they share no sub-lane distinction.

**Mandatory SELF-CHECK (MUST, not optional):** after drafting the wave-map block, verify that
every task id appearing in the delivery's `Depends On` table appears in **exactly one** `wave N:`
line. If any task id is missing or duplicated, correct the block before writing. This totality
invariant is enforced mechanically by the PF-9 producer-completeness gate on the fixture.

**Format (exact — must match the reader's parse rule):**

````markdown
```wave-map
delivery: NNN
wave 1: task-001
wave 2: task-002, task-003, task-004
wave 3: task-005
```
````

Rules for the block:
- The opening fence is exactly ` ```wave-map ` (no extra text on the fence line).
- Line 1 inside the block: `delivery: NNN` — the three-digit zero-padded delivery number
  (matches the `### delivery-NNN` heading above it, e.g. `delivery: 001`).
- Each subsequent line: `wave N: <comma-separated task ids>` — one line per wave/lane; task ids
  are space-trimmed, comma-separated (e.g. `task-001, task-002`).
- Where a wave has parallel sub-lanes, emit one `wave N:` line per sub-lane (they carry the same
  wave number `N`; the reader treats each as a distinct lane within that wave).
- Every task in the delivery MUST appear in exactly one `wave N:` line — the map is total.
- All characters are ASCII. No trailing spaces.

**Example for a two-delivery plan:**

````markdown
### delivery-001 execution graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-001 |

| Can Be Done In Parallel |
|------------------------|
| task-002, task-003 |

```wave-map
delivery: 001
wave 1: task-001
wave 2: task-002, task-003
```

### delivery-002 execution graph

| Task | Depends On |
|------|-----------|
| task-004 | — |
| task-005 | task-004 |

| Can Be Done In Parallel |
|------------------------|
| — |

```wave-map
delivery: 002
wave 1: task-004
wave 2: task-005
```
````

**Reader parse rule (for reference — do not change the block format):**
The reader scans `PLAN.md` for ` ```wave-map ` fences; for each block it reads `delivery: NNN`
and each `wave N: id, id, ...` line and builds `task_id -> {delivery: NNN, lane: N}` as a
deterministic table lookup. The prose/dependency tables above the block are not parsed for lane
data (they remain human-facing only).

**Advance:** **CHAIN** → continue with the parent state's flow.
