
# Classification & Routing

When Track detects something, Triage decides what it is and where it goes. This is the routing decision that determines whether a fix takes four phases or ten.

## Core Principle

**The classification determines the path. Get it right.** A bug misclassified as a CR wastes a full development cycle on something that needed a patch. A CR misclassified as a bug produces a band-aid that breaks when requirements shift again. The distinction is precise: does the code match the spec? If no → bug. If yes, but the spec is wrong → CR.

## Inputs

- `TRACK-REPORT.md` — findings from production monitoring.
- `SPEC.md` — the specification of expected behavior.
- `aid-workspace/knowledge/` directory — system context for analysis.
- `task-{id}.md` files — acceptance criteria for relevant features.

## Process

### Step 1: Read the Finding

For each finding in the Track Report above the severity threshold:
- What was observed? (Concrete symptoms.)
- What evidence supports it? (Metrics, logs, reproduction steps.)
- What's the impact? (Users, functionality, data integrity.)

### Step 2: Classify

Apply this decision tree:

```
Does the code do what SPEC.md says it should?
├── NO → BUG
│     The spec is right. The code is wrong.
│     Route to aid-implement (short path).
│
├── YES, but the spec doesn't cover this case → BUG (spec gap)
│     The spec didn't specify edge case behavior.
│     If the correct behavior is obvious → aid-implement.
│     If the correct behavior needs requirements input → CR.
│
├── YES, and the spec is now wrong → CHANGE REQUEST
│     Business rules changed. Users need different behavior.
│     The system works as designed; the design needs to change.
│     Route to aid-discover (new cycle).
│
├── NOT A CODE ISSUE → INFRASTRUCTURE
│     Server misconfiguration, scaling limits, third-party outage.
│     Escalate to ops. Outside AID scope.
│
└── FALSE POSITIVE → NO ACTION
      Expected behavior, already resolved, below threshold.
      Close with justification.
```

### Step 3: Assess Severity

| Severity | Criteria | Expected Response Time |
|----------|----------|----------------------|
| **Critical** | Data loss, security breach, total service outage | Immediate |
| **High** | Core functionality broken for significant user segment | Same day |
| **Medium** | Non-critical functionality affected, workaround exists | This week |
| **Low** | Minor issue, limited impact, easy workaround | Next sprint |

### Step 4: Route

Based on classification:

**BUG → aid-implement (short path)**
Triage performs root cause analysis and documents it in TRIAGE.md. Then the bug routes directly to Implement → Review → Test → Deploy. Five phases total. No re-specification, no re-planning.

**Change Request → aid-discover (new cycle)**
The CR enters as a new project. If the system has an existing KB, discovery is targeted (update what changed). If it's a significant feature, it runs the full pipeline: Discover → Interview → Specify → Plan → Detail → Implement → Review → Test → Deploy.

**Infrastructure → ops escalation**
Document the finding, recommended action, and escalate. Track this outside the AID pipeline.

**No Action → close**
Document the justification for closing. Reference evidence that shows the finding is benign.

### Step 5: Root Cause Analysis (Bugs Only)

For findings classified as BUG, Triage now performs root cause analysis before handing off to Implement:

1. **Reproduce the path.** From the evidence, trace the execution path that leads to the bug. Which endpoint? Which module? Which function?
2. **Identify the fault.** What specific code is wrong? Missing validation? Wrong assumption? Off-by-one? Race condition? Use `aid-workspace/knowledge/module-map.md` and `aid-workspace/knowledge/architecture.md` to navigate.
3. **Understand why.** Why did this happen? Was the spec ambiguous? Was an edge case missed?
4. **Define patch scope.** What files need to change? Keep it minimal — fix the bug, don't refactor the neighborhood.
5. **Define test requirements.** Fix verification test (fails before, passes after), regression tests, and coverage gaps.

The root cause should be one sentence: "The `PaymentService.Process()` method doesn't validate null `currency` field, which the spec says must default to USD."

### Step 6: Document

Generate `TRIAGE.md` using the [template](../../templates/feedback-artifacts/TRIAGE.md). Every classification must include:
- The finding (what was detected).
- The classification (bug/CR/infra/no-action).
- The evidence (why this classification, not another).
- The routing decision (where it goes next).
- The severity assessment.
- **For bugs:** Root cause analysis, patch scope, and test requirements.

## The Hard Calls

### Bug vs. CR

The distinction hinges on the spec:

**Bug example:** SPEC says "API returns 200 with user data for valid requests." API returns 500 for users with special characters in their name. The spec is right; the code doesn't handle the edge case. → **BUG.**

**CR example:** SPEC says "Reports generated daily at midnight UTC." Client now operates in multiple timezones and needs reports at midnight *local time* per region. The code does exactly what the spec says. The spec needs to change. → **CR.**

**Gray area:** SPEC says "support file upload." Users try to upload 2GB files and it crashes. Did the spec implicitly assume reasonable file sizes? Is the missing size limit a spec gap (bug) or a new requirement (CR)?

Rule of thumb: if the fix is obvious and contained (add a size check, return a helpful error), treat it as a bug. If it requires stakeholder input to define the correct behavior (what's the max size? should we support chunked upload?), treat it as a CR.

### Severity Disagreement

Track may assess severity differently than Triage. Track sees metrics; Triage has spec context. Triage severity overrides Track severity, with justification documented.

## Output: TRIAGE.md

See [Triage Template](../../templates/feedback-artifacts/TRIAGE.md) for the full template.

## Triggers

### → aid-implement (Short Bug Path)
When classification is BUG, perform root cause analysis, produce TRIAGE.md (including root cause, patch scope, and test requirements), and hand off to `aid-implement` for the fix.

### → aid-discover (New Cycle)
When classification is Change Request, produce TRIAGE.md and route to `aid-discover` as a new project cycle. The CR becomes the input to discovery (or interview, for greenfield).

## Quality Checklist

- [ ] Every finding above threshold has a classification.
- [ ] Classification references SPEC.md for expected behavior.
- [ ] Evidence supports the classification (not just gut feeling).
- [ ] Bug vs. CR distinction is explicit and justified.
- [ ] Severity is assessed with expected response time.
- [ ] Routing decision is clear (next phase identified).
- [ ] TRIAGE.md produced with all required fields.

## Why This Phase Exists

Not every production finding needs the same response. A bug (spec right, code wrong) takes the short path: Triage → Implement → Review → Test → Deploy — five phases. Triage performs root cause analysis and documents it in TRIAGE.md, then routes directly to Implement. A change request (spec needs updating) takes the full cycle back through Discover. Infrastructure issues go to ops, outside AID entirely.

Triage is the classification, root cause analysis, and routing decision that prevents treating every issue the same way. Without it, teams either over-engineer bug fixes (treating them as CRs) or under-engineer change requests (treating them as quick bug fixes).

## Related Phases

- **Previous:** [Track](../aid-track/) — provides TRACK-REPORT.md with findings
- **Routes to:** [Implement](../aid-implement/) for bugs (short path), [Discover](../aid-discover/) for change requests

## See Also

- [Triage Template](../../templates/feedback-artifacts/TRIAGE.md) — Full TRIAGE.md template.
- [AID Methodology](../../methodology/aid-methodology.md) — The complete methodology.
