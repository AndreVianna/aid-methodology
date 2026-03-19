
# Runtime Telemetry & Observability

Monitor production. Interpret what's happening — don't just collect data. Identify anomalies, trends, and correlations that need attention.

## Core Principle

**Track interprets, it doesn't just collect.** A dashboard shows you a spike. Track tells you "error rate increased 340% after deploy #47, concentrated in the payment module, affecting ~2,000 users, correlating with the async refactor in DELIVERY-3." The AI reads the data the way a senior engineer would — looking for meaning, not just numbers.

## Inputs

Any combination of:
- Error tracking systems (Sentry, Application Insights, CloudWatch, log files).
- Issue trackers (GitHub Issues, Jira, Linear).
- CI/CD pipeline results (GitHub Actions, Azure Pipelines).
- Performance monitoring (APM tools, custom metrics).
- Test results (unit, E2E, integration — especially trends).
- User feedback (support tickets, forum posts, app store reviews).
- `knowledge/` directory — to distinguish expected behavior from anomalies.

## Process

### Step 1: Data Collection

Pull from configured sources. Scope to the relevant time window:
- **Post-deployment:** Last deployment to now.
- **Scheduled:** Since last track run.
- **On-demand:** User-specified window.

For each source, capture:
- Raw data (error messages, stack traces, metric values).
- Metadata (timestamps, affected users, affected endpoints).
- Trends (comparison to baseline period).

### Step 2: Anomaly Detection

Compare current state to baseline. Flag deviations:
- **Error rate changes:** New error types, frequency spikes, pattern shifts.
- **Performance degradation:** Latency increases, throughput drops, resource exhaustion.
- **Test instability:** New flaky tests, coverage gaps in changed areas.
- **Behavioral anomalies:** Unexpected API responses, data inconsistencies.

Not everything abnormal is a problem. Use the KB (`knowledge/infrastructure.md`, `knowledge/test-landscape.md`) to filter out known conditions, planned maintenance, or expected seasonal variation.

### Step 3: Trend Analysis

Look beyond point-in-time snapshots:
- Is error rate increasing over the last N deployments?
- Is test flakiness trending up in a specific module?
- Are performance metrics slowly degrading (boiling frog)?
- Are support tickets clustering around a specific feature?

Trends that cross thresholds matter even when individual data points don't.

### Step 4: Correlation

Connect signals across sources:
- "Error spike started 23 minutes after deploy #47."
- "Performance drop coincides with traffic from new region."
- "Test failures correlate with changes in module X."
- "Support tickets about feature Y increased after DELIVERY-3."

Correlation isn't causation, but it narrows investigation scope for Triage.

### Step 5: Impact Assessment

For each finding, assess:
- **Scope:** How many users affected? Which functionality?
- **Severity:** Data loss risk? Security exposure? Revenue impact?
- **Urgency:** Is it getting worse? Stable? Self-resolving?

### Step 6: Produce Report

Generate `TRACK-REPORT.md` using the [template](references/track-report-template.md).

For each finding:
- Concrete evidence (not "something seems off" — show the numbers).
- Correlation with recent changes if applicable.
- Severity assessment.
- Recommendation: trigger triage, or no action needed.

If nothing is found — that's the expected outcome. A clean report is a good report.

## Output: TRACK-REPORT.md

See [Track Report Template](references/track-report-template.md) for the full template.

## Severity Thresholds

Not every anomaly triggers triage. Default thresholds (adjust per project):

| Metric | Threshold | Action |
|--------|-----------|--------|
| New error type | Any | Trigger triage |
| Error rate increase | >200% from baseline | Trigger triage |
| Performance degradation | >50% latency increase | Trigger triage |
| Test failures | Any new persistent failure | Trigger triage |
| Support ticket cluster | 3+ tickets on same issue | Trigger triage |
| Below threshold | — | Document in report, no triage |

## When to Run

- **Post-deployment:** After every `aid-deploy` ships. Check that what was deployed works.
- **Scheduled:** Daily or weekly depending on project activity. Catches slow-burn issues.
- **Alert-triggered:** When monitoring tools fire alerts above configured thresholds.
- **On-demand:** When a stakeholder asks "how's production doing?"

## Triggers

### → aid-triage (Loop 7)

When findings exceed severity thresholds, produce TRACK-REPORT.md and hand off to `aid-triage` for classification and routing.

## Quality Checklist

- [ ] All configured sources checked.
- [ ] Findings include concrete evidence (numbers, logs, timestamps).
- [ ] Each finding has a severity assessment.
- [ ] Correlations with recent deployments noted where applicable.
- [ ] KB consulted to filter false positives.
- [ ] Clean report stated explicitly if no issues found.
- [ ] Recommendation given for each finding (triage or no action).

## See Also

- [Track Report Template](references/track-report-template.md) — Full TRACK-REPORT.md template.
- [AID Methodology](../../business/playbook-v2/aid-methodology.md) — The complete methodology.
