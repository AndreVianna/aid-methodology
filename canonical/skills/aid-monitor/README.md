> **Human-facing documentation.** Machine source consumed by `/aid-generate` is [`SKILL.md`](SKILL.md) in this folder.

# aid-monitor — Monitor (optional)

Observe production, classify findings, and route actions. Per-work scope. An optional, on-demand delivery skill — run post-deployment, on schedule, or on demand; not a required pipeline phase.

## What It Does

Combines telemetry interpretation with triage into a single observe → classify → act cycle:

1. **Observe** — pull data from error tracking, APM, CI/CD, support tickets
2. **Classify** — BUG (spec right, code wrong) / CR (spec needs change) / INFRASTRUCTURE / NO ACTION
3. **Analyze** — root cause analysis for bugs (trace → fault → scope → test requirements)
4. **Propose** — present findings with routing recommendations
5. **Act** — create tasks for bugs (→ aid-execute), Q&A entries for CRs (→ aid-discover), escalate infra

## Artifacts

| Artifact | Location | Purpose |
|----------|----------|---------|
| `MONITOR-STATE.md` | `.aid/{work}/` | Observation log, finding statuses, run history |

## Routing

| Classification | Route | Path |
|----------------|-------|------|
| BUG | aid-execute | Short: new task → execute → deploy |
| Change Request | aid-discover | Full cycle: Q&A entry → discover → interview → ... |
| Infrastructure | Ops (manual) | Outside AID scope |
| No Action | Close | Document justification |
