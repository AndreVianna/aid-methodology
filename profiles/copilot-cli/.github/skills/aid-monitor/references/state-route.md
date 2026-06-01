# State: ROUTE

All findings are classified; propose and execute routing actions per finding classification.

### Step 4: Propose Actions

Present findings to the user with proposed routing:

```
📊 Monitor Report — work-001 (since 2026-03-20)

Finding 1: [CRITICAL] [BUG] Null currency causes 500 error
  Evidence: 342 errors in 48h, payment module, started after package-002
  Root cause: PaymentService.Process() missing null validation
  Patch scope: PaymentService.cs + PaymentServiceTests.cs
  → Proposed: Create task in delivery-hotfix → aid-execute

Finding 2: [MEDIUM] [CHANGE REQUEST] Reports need local timezone
  Evidence: 12 support tickets requesting midnight-local instead of midnight-UTC
  → Proposed: Route to aid-discover → new work cycle

Finding 3: [LOW] [NO ACTION] Intermittent 504 on health endpoint
  Evidence: 3 occurrences in 7 days, all self-resolved < 30s
  → Proposed: Document, no action

[1] Approve all routes
[2] Adjust — change routing for specific findings
```

### Step 5: Act

For each approved finding:

**BUG → aid-execute (short path):**
- Create a new task file in `.aid/{work}/tasks/` with type IMPLEMENT
- Include: root cause, patch scope, test requirements, severity
- The task goes through the normal execute cycle (code → review → done)

**CHANGE REQUEST → aid-discover:**
- Write a Q&A entry to `.aid/knowledge/STATE.md` `## Q&A (Pending)` describing the gap
- Optionally create a new work if scope is large enough

**INFRASTRUCTURE → escalate:**
- Document in the monitor run summary with recommended ops action
- Not in AID's scope — human handles this

**NO ACTION → close:**
- Document justification in the monitor run summary → Resolved Findings list

**Update known-issues.md** if findings reveal new known issues affecting other features.

### Step 6: Update State

Print monitor run summary: date, window, finding count, routing summary.

▶ PM tool ticket creation starting (~10–30 s per ticket per `.github/templates/rough-time-hints.md`; skip block entirely if no PM tool)
If PM tool configured (infrastructure.md § Project Management):
- Create tickets for BUG tasks
- Link to existing Sprint/Epic
✓ PM tool ticket creation done (record actual time, N tickets created) — or ✗ PM tool ticket creation failed: {reason — usually auth/network}

**Advance:** **CHAIN** → [State: DONE] (continue inline).
