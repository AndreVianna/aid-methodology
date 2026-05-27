# State: OBSERVE

No prior run context; pull telemetry signals and correlate against baselines.

### Step 1: Observe

Pull data from configured sources. Scope the observation window:
- **Post-deploy:** last deploy → now
- **Scheduled:** last monitor run → now
- **On-demand:** user-specified window

▶ telemetry pull starting (~30 s–2 min per source per `.cursor/templates/rough-time-hints.md`)
For each data source, capture:
- Raw signals (errors, latency spikes, failures, ticket clusters)
- Metadata (timestamps, affected users/endpoints, frequency)
- Trends vs. baseline (is this new? worsening? stable?)
✓ telemetry pull done (record actual time, sources hit, signals collected) — or ✗ telemetry pull failed: {source, reason}

▶ anomaly detection starting (~10–30 s)
**Anomaly detection — compare to baseline:**
- Error rate changes (new error types, rate spikes)
- Performance degradation (latency, throughput)
- Test instability (new flaky tests, persistent failures)
- Behavioral anomalies (unexpected patterns in usage or data)

**Correlation — connect signals:**
- "Error spike started 23 min after deploy of package-002"
- "Performance drop coincides with new region traffic"
- Correlation narrows investigation scope — don't just list, connect.

Use KB to filter: known conditions, expected variation, already-documented issues.
✓ anomaly detection done (record actual time, N findings above threshold) — or ✗ anomaly detection failed: {reason}

**Advance:** Next state is `CLASSIFY` — when this state's work completes, router prints `Next: [State: CLASSIFY] — run /aid-monitor again` and exits.
