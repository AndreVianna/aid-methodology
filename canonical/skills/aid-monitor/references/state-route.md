# State: ROUTE

All findings are classified; propose and execute routing actions per finding classification.
ROUTE runs inline in the main conversation: no sub-agent. Each bug and change request goes back as a plain request.

### Step 4: Propose Actions

Present findings to the user with proposed routing:

```
📊 Monitor Report — work-001 (since 2026-03-20)

Finding 1: [CRITICAL] [BUG] Null currency causes 500 error
  Evidence: 342 errors in 48h, payment module, started after package-002
  Root cause: PaymentService.Process() missing null validation
  Patch scope: PaymentService.cs + PaymentServiceTests.cs
  → Proposed: Fix request

Finding 2: [MEDIUM] [CHANGE REQUEST] Reports need local timezone
  Evidence: 12 support tickets requesting midnight-local instead of midnight-UTC
  → Proposed: New-work request

Finding 3: [LOW] [NO ACTION] Intermittent 504 on health endpoint
  Evidence: 3 occurrences in 7 days, all self-resolved < 30s
  → Proposed: Document, no action

[1] Approve all routes
[2] Adjust — change routing for specific findings
```

### Step 5: Act

For each approved finding:

**BUG → fix request:**
- Record the bug finding in the in-memory monitor context with: root cause, patch scope, test requirements, severity. (A persistent `MONITOR-STATE.md` is deferred until the Monitor area matures — see aid-monitor/SKILL.md.)
- Hand the diagnosis — root cause, patch scope, test requirements — back as a fix request, in plain words, through `rules.md` § Handling a request. The request starts a fix work, which implements the fix directly (→ optional `aid-deploy`). The spec is already correct; only the code is wrong, so the fix work skips Specify/Plan/Detail.

**CHANGE REQUEST → new-work request:**
- Record the change request in the in-memory monitor context (the desired new/changed behavior, with evidence).
- Hand the desired change and its evidence back as a new-work request, in plain words, through `rules.md` § Handling a request. The intake (`/aid-orchestrate`) checks the reading against the Knowledge Base and the code, sizes the work and picks its phases.

**INFRASTRUCTURE → escalate:**
- Document in the monitor run summary with recommended ops action
- Not in AID's scope — the user handles this

**NO ACTION → close:**
- Document justification in the monitor run summary → Resolved Findings list

**Update known-issues.md** if findings reveal new known issues affecting other features.

### Step 6: Update State

Print monitor run summary: date, window, finding count, routing summary.

If a catalogued `issue-tracker` connector exists in `.aid/connectors/` → print a suggestion:
consider filing a ticket for each BUG finding via `/aid-create-ticket`. Optional, user-initiated,
never auto-invoked; silent (no output) if no issue-tracker connector is catalogued.

**Advance:** **CHAIN** → [State: DONE] (continue inline).
