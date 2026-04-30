# Profile Auto-Detection Rules

Used by the PROFILE state to pick a section template based on KB content.
The skill reads each `.aid/knowledge/*.md`, applies the scoring signals
below, and picks the highest-scoring profile.

## Scoring signals

Each signal that matches contributes points to its profile. The highest score
wins.

### web-app

| Signal | Points | How to detect |
|---|---|---|
| `ui-architecture.md` exists and non-empty (>30 non-blank lines) | +3 | `wc -l` after stripping blank lines |
| `api-contracts.md` mentions REST, GraphQL, HTTP endpoints | +2 | grep `REST`, `GraphQL`, `HTTP`, `endpoint`, `route` |
| `integration-map.md` has inbound HTTP clients | +1 | grep `inbound.*HTTP` or `browser`, `client` |

### library

| Signal | Points | How to detect |
|---|---|---|
| `module-map.md` describes "exports" or "public API" | +3 | grep `Export-Package`, `exported`, `public API`, `exports` |
| No `ui-architecture.md` (or stub-only, < 30 lines) | +2 | `wc -l` |
| `api-contracts.md` describes "exported symbols", "types" | +2 | grep `exported symbols`, `type`, `interface` |
| `infrastructure.md` is sparse (no deployment manifest) | +1 | `wc -l` < 100, no Docker/K8s mentions |

### cli

| Signal | Points | How to detect |
|---|---|---|
| `infrastructure.md` mentions "command-line" or `bin/` | +3 | grep `command-line`, `\bcli\b`, `bin/`, `argparse`, `clap` |
| `api-contracts.md` describes subcommands | +3 | grep `subcommand`, `--flag`, `argv`, `parse` |
| `module-map.md` describes a single executable | +2 | one main module, no service/server mentions |

### microservices

| Signal | Points | How to detect |
|---|---|---|
| `module-map.md` lists ≥6 independently-deployed services | +4 | count headings under "Services" or "Modules" with deployable indicators |
| `integration-map.md` has inter-service contracts | +2 | grep `service-to-service`, `gRPC`, `mTLS`, `service mesh` |
| Multiple deployment manifests in `infrastructure.md` | +2 | grep `kubernetes`, `helm chart`, multiple `Dockerfile`, multiple `service.yaml` |

### data-pipeline

| Signal | Points | How to detect |
|---|---|---|
| `integration-map.md` mentions "transforms", "ETL", "streaming" | +3 | grep `ETL`, `transform`, `extract`, `streaming`, `Kafka`, `event source` |
| `data-model.md` describes pipeline stages | +2 | grep `stage`, `transform`, `lineage`, `DAG` |
| `infrastructure.md` mentions Airflow, dbt, Spark, Flink | +2 | grep `Airflow`, `dbt`, `Spark`, `Flink`, `Beam`, `Dagster` |

## Confidence levels

After computing scores:

| Confidence | Condition | Behavior |
|---|---|---|
| **high** | Top score ≥ 5 AND second-highest ≤ top/2 | Print detection, proceed silently |
| **medium** | Top score ≥ 3 AND second-highest within (top/2, top) | Print detection with a warning, proceed |
| **low** | All scores < 3, OR top within 1 of second | Use `AskUserQuestion` to ask user to choose from candidates |

## Implementation

```bash
# Pseudo-code for the agent during PROFILE state
declare -A SCORES
SCORES[web-app]=0
SCORES[library]=0
SCORES[cli]=0
SCORES[microservices]=0
SCORES[data-pipeline]=0

# Run each signal check, increment relevant SCORES key
# (See per-profile signal lists above)

# Find max
MAX_PROFILE=...
MAX_SCORE=...
SECOND_SCORE=...

# Determine confidence
if (( MAX_SCORE >= 5 && SECOND_SCORE * 2 <= MAX_SCORE )); then
    CONFIDENCE=high
elif (( MAX_SCORE >= 3 )); then
    CONFIDENCE=medium
else
    CONFIDENCE=low
fi
```

## Output to user

```
[PROFILE] Auto-detected: web-app (score 6, confidence: high)
          Signals matched:
            +3 ui-architecture.md non-empty
            +2 api-contracts.md mentions REST endpoints
            +1 integration-map.md has inbound HTTP
          Override: re-run with --profile X --reset
```

When confidence is `low`:
```
[PROFILE] Detection ambiguous (top scores: web-app=2, library=2).
          Using AskUserQuestion to resolve...
```
