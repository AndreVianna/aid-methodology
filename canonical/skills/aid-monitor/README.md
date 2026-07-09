> **Human-facing documentation.** Machine source consumed by `/generate-profile` is [`SKILL.md`](SKILL.md) in this folder.

# aid-monitor — Monitor (optional)

Observe production, classify findings, and route actions. Per-work scope. An optional, on-demand delivery skill — run post-deployment, on schedule, or on demand; not a required pipeline phase.

## What It Does

Combines telemetry interpretation with triage into a single observe → classify → act cycle:

1. **Observe** — pull data from error tracking, APM, CI/CD, support tickets
2. **Classify** — BUG (spec right, code wrong) / CR (spec needs change) / INFRASTRUCTURE / NO ACTION
3. **Analyze** — root cause analysis for bugs (trace → fault → scope → test requirements)
4. **Propose** — present findings with routing recommendations
5. **Act** — route findings to `/aid-fix` (bugs) or `/aid-triage` (CRs), escalate infra

## Artifacts

| Artifact | Location | Purpose |
|----------|----------|---------|
| in-memory monitor context | (run-scoped) | Observation log, finding statuses, run history |
| `MONITOR-STATE.md` _(deferred)_ | `.aid/{work}/` | Planned persistent observation log — deferred until the Monitor area matures |

## Routing

| Classification | Route | Path |
|----------------|-------|------|
| BUG | `/aid-fix` | Diagnosis → scaffold + implement the fix directly |
| Change Request | `/aid-triage` | Suggests the right entry: a specific shortcut, or the full path via `/aid-describe` |
| Infrastructure | Ops (manual) | Outside AID scope |
| No Action | Close | Document justification |
