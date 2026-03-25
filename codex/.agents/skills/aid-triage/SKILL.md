---
name: aid-triage
description: >
  Classify production findings as BUG, Change Request, Infrastructure, or No Action.
  For bugs: perform root cause analysis and map the patch. Routes bugs to aid-implement
  (short path), CRs to aid-discover (new cycle). Use when TRACK-REPORT.md has findings
  above severity thresholds.
allowed-tools: Read, Glob, Grep, Bash
context: fork
agent: orchestrator
---

# Classification, Root Cause Analysis & Routing

Classify findings, map the fix for bugs, and route everything. The classification determines the path.

## Inputs

- `TRACK-REPORT.md` — findings from production
- Feature SPECs: `aid-workspace/{work}/features/*/SPEC.md` — expected behavior
- `aid-workspace/knowledge/` — system context
- `aid-workspace/{work}/tasks/task-{id}.md` files — acceptance criteria for affected features

## Process

### 1. Read Finding
Per finding above threshold: observed symptoms, supporting evidence, impact.

### 2. Classify

```
Does code do what the feature SPEC says?
├── NO → BUG (spec right, code wrong) → root cause analysis → aid-implement
├── YES, spec doesn't cover this case →
│     Obvious fix? → BUG (spec gap) → root cause analysis → aid-implement
│     Needs requirements input? → CHANGE REQUEST → aid-discover
├── YES, spec is now wrong → CHANGE REQUEST → aid-discover
├── NOT CODE → INFRASTRUCTURE → escalate to ops
└── FALSE POSITIVE → NO ACTION → close with justification
```

### 3. Assess Severity
- **Critical:** Data loss, security breach, total outage → Immediate
- **High:** Core functionality broken → Same day
- **Medium:** Non-critical affected, workaround exists → This week
- **Low:** Minor, limited impact → Next sprint

### 4. Root Cause Analysis (BUGs only)

Before routing, perform root cause analysis using the KB:

1. **Reproduce the path.** Trace from TRIAGE evidence: endpoint → module → function.
2. **Identify the fault.** What specific code is wrong? Missing validation? Wrong assumption? Race condition?
3. **Understand why.** Spec ambiguous? Edge case missed? KB assumption wrong?
4. **Assess impact.** Broken functionality, user count. Check module consumers (`aid-workspace/knowledge/module-map.md`). Data integrity affected?
5. **Define patch scope.** Exactly which files change and why. Minimal surface area — fix the bug, don't refactor.
6. **Test requirements.** Fix verification test + regression tests + coverage gap.

Root cause = one sentence: "The `PaymentService.Process()` method doesn't validate null `currency` field, which spec says must default to USD."

If root cause analysis is complex, produce `CORRECTION.md` as the task spec for aid-implement.

### 5. Route
- **BUG → aid-implement** (short path: implement → review → test → deploy)
- **CR → aid-discover** (full cycle or targeted)
- **Infrastructure → ops** (outside AID)
- **No Action → close** (document justification)

### 6. Document
TRIAGE.md per finding: finding, classification, evidence, routing, severity. For bugs: include root cause, patch scope, and test requirements (inline or via CORRECTION.md).

## Bug vs. CR Decision

The distinction hinges on the spec:
- Bug: API returns 500 for special chars in name. Spec says return 200 for valid requests. Code is wrong.
- CR: Reports at midnight UTC. Client now needs midnight local time. Code matches spec. Spec needs change.
- Gray area: If fix is obvious and contained → bug. If needs stakeholder input → CR.

## Output

`TRIAGE.md` with: per finding — classification, evidence, routing decision, severity assessment. For bugs: root cause, patch scope, test requirements. Optional `CORRECTION.md` for complex bugs.

## Quality Checklist

- [ ] Every finding above threshold classified
- [ ] Classification references feature SPEC
- [ ] Evidence supports classification
- [ ] Bug vs CR distinction explicit and justified
- [ ] Severity with expected response time
- [ ] Routing decision clear
- [ ] For bugs: root cause identified (one sentence, specific)
- [ ] For bugs: patch scope defined (minimal — fix the bug, nothing else)
- [ ] For bugs: test requirements defined (fix verification + regression + coverage gap)
