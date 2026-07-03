> **Human-facing documentation.** Machine source consumed by `/generate-profile` is [`SKILL.md`](SKILL.md) in this folder.

# aid-monitor — Monitor (optional)

Observe production, classify findings, and route actions. Per-work scope. An optional, on-demand delivery skill — run post-deployment, on schedule, or on demand; not a required pipeline phase.

## What It Does

Combines telemetry interpretation with triage into a single observe → classify → act cycle:

1. **Observe** — pull data from error tracking, APM, CI/CD, support tickets
2. **Classify** — BUG (spec right, code wrong) / CR (spec needs change) / INFRASTRUCTURE / NO ACTION
3. **Analyze** — root cause analysis for bugs (trace → fault → scope → test requirements)
4. **Propose** — present findings with routing recommendations
5. **Act** — route findings to aid-describe (bugs via the lite bug-fix triage; CRs as new/changed requirements), escalate infra

## Artifacts

| Artifact | Location | Purpose |
|----------|----------|---------|
| in-memory monitor context | (run-scoped) | Observation log, finding statuses, run history |
| `MONITOR-STATE.md` _(deferred)_ | `.aid/{work}/` | Planned persistent observation log — deferred until the Monitor area matures |

## Routing

| Classification | Route | Path |
|----------------|-------|------|
| BUG | aid-describe | Short: lite bug-fix triage → task → execute |
| Change Request | aid-describe | Full cycle: new/changed requirements → specify → plan → ... |
| Infrastructure | Ops (manual) | Outside AID scope |
| No Action | Close | Document justification |
