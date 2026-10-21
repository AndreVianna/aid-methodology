# State: OBSERVE

No prior run context; pull telemetry signals and correlate against baselines.

### Step 1: Observe

Pull data from configured sources. Scope the observation window:
- **Post-deploy:** last deploy → now
- **Scheduled:** last monitor run → now
- **On-demand:** user-specified window

**No data source available.** When no configured source can be reached (none catalogued, or every pull
failed), do not list what is needed, and do not end the turn with "which would you like?" or any open
request for a pointer, a log or a finding number. The wait for the user is this one question, in the
form of `.aid/runtime/templates/question-protocol.md`, in plain text:

```text
Monitoring -- question 1 of 1 -- importance: high
Which data source should I observe: {the closest candidate found in `.aid/connectors/INDEX.md` or the host tool}, or an export you give me?
Why I ask: there is no data to observe without a source.
My recommendation: {the candidate and why, or the export if none was found}
  1. {the candidate} (recommended)
  2. An export or log you provide
Or answer in your own words, ask me to explain, or skip this question.
```

Record it (in a work; with no work open, add `--design .aid/design/untitled-<YYYYMMDD-HHMMSS>.md` to both calls, so the question and its answer land in a design document, as `question-protocol.md` § Where each record lives sets) with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --category Monitoring --impact High --context '<the question>' --suggested '<the recommendation>' --asked-by aid-monitor` before it is shown (it prints the id), and the reply with `--answer --id Q<n> --state <Answered|Skipped> --value '<the answer>' --applied-to 'data source'` right after. A skipped question ends the observation with the finding `no data source`; nothing is invented.

▶ telemetry pull starting (~30 s–2 min per source per `.aid/runtime/templates/rough-time-hints.md`)
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

**Advance:** **CHAIN** → [State: CLASSIFY] (continue inline).
