# aid-detail

Break deliverables into small, sequential, testable tasks — each one a PR.
The ultimate breakdown.

## The Universal Loop

Each deliverable follows the same cycle:

```
1. PROPOSE  → agent proposes task breakdown for a deliverable
2. DISCUSS  → developer and agent refine (size, scope, sequence, criteria)
3. WRITE    → save agreed tasks to files
4. REVIEW   → grade against SPEC/PLAN — pass? next deliverable. fail? back to 1.
```

**Re-run = enter at step 4 with existing tasks.**

## Usage

```
/aid-detail work-001
/aid-detail                   # auto-selects when single work
/aid-detail work-001 --reset
```

## Workspace

```
aid-workspace/
  knowledge/                ← shared KB (read)
  work-NNN-{name}/
    PLAN.md                 ← deliverables (read — must exist)
    features/
      feature-NNN-{name}/
        SPEC.md             ← per-feature tech spec (read)
    tasks/                  ← OUTPUT
      task-001.md
      task-002.md
```

## How It Works

### First Run

1. **Propose tasks** for the first deliverable — sequential, each small enough for one agent session
2. **Discuss** — size, scope, sequence, acceptance criteria. Split, merge, reorder until right.
3. **Write and review** — save task files, verify sequence holds, scope aligned with SPECs, criteria testable. Grade A/B/C.
4. **Next deliverable** — same loop. Task numbers are global across deliverables.
5. **Summary**

### Re-run (Review)

When `tasks/` has files, re-run enters the loop at step 4:
- Checks for PLAN changes, SPEC changes, orphan tasks, missing tasks, broken sequence
- Grades A–D overall
- Re-enters the loop for affected deliverables

## The Rules

1. **Always small.** Every task fits one agent session.
2. **Sequential within a deliverable.** Each builds on the previous.
3. **Each task = one PR.** Human reviews and merges before next.
4. **No new decisions.** Everything is in PLAN + SPECs. Detail just slices.

## Task Format

```markdown
# task-{id}: {Title}

**Source:** feature-NNN-{name} → delivery-{x}

**Scope:**
- `path/to/File.java` (create)
- `path/to/OtherFile.java` (modify)

**Acceptance Criteria:**
- [ ] Criterion 1 — concrete, testable
- [ ] All existing tests still pass
```

Four sections. Nothing else.

## Feedback Loops

- **→ Plan:** Too vague to decompose → return to `/aid-plan`
- **→ Specify:** SPEC missing detail → Q&A to feature's STATE.md
- **→ Discovery:** KB gap → Q&A to DISCOVERY-STATE.md
