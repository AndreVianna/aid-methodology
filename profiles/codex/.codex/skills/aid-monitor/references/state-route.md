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
  → Proposed: Route to /aid-fix

Finding 2: [MEDIUM] [CHANGE REQUEST] Reports need local timezone
  Evidence: 12 support tickets requesting midnight-local instead of midnight-UTC
  → Proposed: Route to /aid-triage

Finding 3: [LOW] [NO ACTION] Intermittent 504 on health endpoint
  Evidence: 3 occurrences in 7 days, all self-resolved < 30s
  → Proposed: Document, no action

[1] Approve all routes
[2] Adjust — change routing for specific findings
```

### Step 5: Act

For each approved finding:

**BUG → /aid-fix:**
- Record the bug finding in the in-memory monitor context with: root cause, patch scope, test requirements, severity. (A persistent `MONITOR-STATE.md` is deferred until the Monitor area matures — see aid-monitor/SKILL.md.)
- Hand off the diagnosis — root cause, patch scope, test requirements — to `/aid-fix`, which scaffolds and implements the fix directly (→ optional `aid-deploy`). The spec is already correct; only the code is wrong, so `/aid-fix` skips Specify/Plan/Detail.

**CHANGE REQUEST → /aid-triage:**
- Record the change request in the in-memory monitor context (the desired new/changed behavior, with evidence).
- Hand off the desired change and its evidence to `/aid-triage`, which suggests the right entry — the full path via `/aid-describe` for a broad or ambiguous change (the pipeline then runs from Interview: Specify → Plan → Detail → Execute; a large-enough CR spins up a new work), or a specific direct-entry shortcut for a known single change-type.

**INFRASTRUCTURE → escalate:**
- Document in the monitor run summary with recommended ops action
- Not in AID's scope — the user handles this

**NO ACTION → close:**
- Document justification in the monitor run summary → Resolved Findings list

**Update known-issues.md** if findings reveal new known issues affecting other features.

### Step 6: Update State

Print monitor run summary: date, window, finding count, routing summary.

▶ PM tool ticket creation starting (~10–30 s per ticket per `.codex/aid/templates/rough-time-hints.md`; skip block entirely if no PM tool)
If PM tool configured (infrastructure.md § Project Management):
- Create tickets for BUG tasks
- Link to existing Sprint/Epic
✓ PM tool ticket creation done (record actual time, N tickets created) — or ✗ PM tool ticket creation failed: {reason — usually auth/network}

**Advance:** **CHAIN** → [State: DONE] (continue inline).
