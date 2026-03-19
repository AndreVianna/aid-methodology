---
name: aid-track
description: >
  Production telemetry interpretation. Monitors production by reading error logs,
  issue trackers, metrics, CI/CD, test results, and user feedback. Produces
  TRACK-REPORT.md. Use post-deployment, on schedule, or on-demand.
allowed-tools: Read, Glob, Grep, Bash
context: fork
agent: researcher
---

# Runtime Telemetry & Observability

Monitor production. Interpret what's happening — don't just collect data.

## Core Principle

Track interprets, it doesn't just collect. "Error rate increased 340% after deploy #47, concentrated in payment module, affecting ~2,000 users, correlating with async refactor in DELIVERY-3."

## Inputs

Any combination of: error tracking (Sentry, AppInsights, CloudWatch), issue trackers, CI/CD results, APM, test trends, user feedback. Plus `knowledge/` for baseline context.

## Process

### 1. Data Collection
Pull from configured sources. Scope: post-deployment (last deploy → now), scheduled (since last run), or on-demand (user-specified window). Capture raw data, metadata (timestamps, users, endpoints), and trends vs. baseline.

### 2. Anomaly Detection
Compare to baseline: error rate changes, performance degradation, test instability, behavioral anomalies. Use KB to filter known conditions and expected variation.

### 3. Trend Analysis
Beyond point-in-time: error rate across deployments, test flakiness trending, slow performance degradation, support ticket clustering.

### 4. Correlation
Connect signals: "Error spike started 23 min after deploy #47." "Performance drop coincides with new region traffic." Correlation narrows investigation scope.

### 5. Impact Assessment
Per finding: scope (users, functionality), severity (data loss? security? revenue?), urgency (worsening? stable? self-resolving?).

### 6. Produce Report
TRACK-REPORT.md with concrete evidence per finding, correlation with changes, severity, recommendation (trigger triage or no action).

## Severity Thresholds

| Metric | Threshold | Action |
|--------|-----------|--------|
| New error type | Any | Trigger triage |
| Error rate increase | >200% baseline | Trigger triage |
| Performance degradation | >50% latency | Trigger triage |
| Test failures | Any new persistent | Trigger triage |
| Support ticket cluster | 3+ same issue | Trigger triage |
| Below threshold | — | Document, no triage |

## Output

`TRACK-REPORT.md` with findings, evidence, severity, and recommendations. Clean report if nothing found.

## Quality Checklist

- [ ] All configured sources checked
- [ ] Findings include concrete evidence
- [ ] Severity assessed per finding
- [ ] Correlations with deployments noted
- [ ] KB consulted to filter false positives
- [ ] Clean report stated if no issues
