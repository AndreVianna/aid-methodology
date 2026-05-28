# State: CLASSIFY

Active findings are present; classify each anomaly and perform root cause analysis for bugs.

### Step 2: Classify

For each finding above threshold:

```
Does code do what the feature SPEC says?
├── NO → BUG (spec right, code wrong)
├── YES, spec doesn't cover this case →
│     Obvious fix? → BUG (spec gap)
│     Needs requirements input? → CHANGE REQUEST
├── YES, spec is now wrong → CHANGE REQUEST
├── NOT CODE → INFRASTRUCTURE
└── FALSE POSITIVE → NO ACTION
```

Assess severity per finding:
- **Critical:** Data loss, security breach, total outage → Immediate
- **High:** Core functionality broken → Same day
- **Medium:** Non-critical affected, workaround exists → This week
- **Low:** Minor, limited impact → Next cycle

### Step 3: Analyze (BUGs only)

▶ root cause analysis starting (~2–5 min per BUG per `.agents/templates/rough-time-hints.md`)
Root cause analysis before routing:

1. **Reproduce the path.** Trace from evidence: endpoint → module → function.
2. **Identify the fault.** What specific code is wrong?
3. **Understand why.** Spec ambiguous? Edge case? KB assumption wrong?
4. **Assess blast radius.** Check module consumers via INDEX.md → module-map.
5. **Define patch scope.** Exactly which files change. Minimal surface — fix the bug, don't refactor.
6. **Test requirements.** Fix verification + regression + coverage gap.

Root cause = one sentence:
"The `PaymentService.Process()` method doesn't validate null `currency` field,
which spec says must default to USD."
✓ root cause analysis done (record actual time, root cause, patch scope) — or ✗ root cause analysis blocked: {reason — usually KB gap or unreproducible}

For threshold definitions, see `## Severity Thresholds` in SKILL.md.

**Advance:** **CHAIN** → [State: ROUTE] (continue inline).
