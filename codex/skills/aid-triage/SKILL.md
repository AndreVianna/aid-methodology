---
name: aid-triage
description: >
  Classify production findings as BUG, Change Request, Infrastructure, or No Action.
  Routes bugs to aid-correct (short path), CRs to aid-discover (new cycle). Use
  when TRACK-REPORT.md has findings above severity thresholds.
metadata:
  short-description: Production finding classification and routing
---

# Classification & Routing

Classify findings and route them. The classification determines the path.

## Inputs

- `TRACK-REPORT.md` — findings from production
- `SPEC.md` — expected behavior
- `knowledge/` — system context
- `TASK-{id}.md` files — acceptance criteria for affected features

## Process

### 1. Read Finding
Per finding above threshold: observed symptoms, supporting evidence, impact.

### 2. Classify

```
Does code do what SPEC.md says?
├── NO → BUG (spec right, code wrong) → aid-correct
├── YES, spec doesn't cover this case →
│     Obvious fix? → BUG (spec gap) → aid-correct
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

### 4. Route
- **BUG → aid-correct** (short path: correct → implement → review → test → deploy)
- **CR → aid-discover** (full cycle or targeted)
- **Infrastructure → ops** (outside AID)
- **No Action → close** (document justification)

### 5. Document
TRIAGE.md per finding: finding, classification, evidence, routing, severity.

## Bug vs. CR Decision

The distinction hinges on the spec:
- Bug: API returns 500 for special chars in name. Spec says return 200 for valid requests. Code is wrong.
- CR: Reports at midnight UTC. Client now needs midnight local time. Code matches spec. Spec needs change.
- Gray area: If fix is obvious and contained → bug. If needs stakeholder input → CR.

## Output

`TRIAGE.md` with: per finding — classification, evidence, routing decision, severity assessment.

## Quality Checklist

- [ ] Every finding above threshold classified
- [ ] Classification references SPEC.md
- [ ] Evidence supports classification
- [ ] Bug vs CR distinction explicit and justified
- [ ] Severity with expected response time
- [ ] Routing decision clear
