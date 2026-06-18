# State: PROFILE

PROFILE auto-detects the project type from KB signals to select the correct section template; it is selected when STALE-CHECK finds the KB is stale and no stored profile exists.

Decide which section template to use. Skip if `.aid/knowledge/STATE.md` `## Knowledge Summary Status` already has a
`**Profile:**` entry (preserved from previous run unless `--reset`).

If `--profile X` was passed (and X is not `auto`), use that. Otherwise auto-detect:

Read `.aid/knowledge/`:
- `architecture.md` — UI/frontend patterns documented?
- `pipeline-contracts.md` — REST/GraphQL? exported symbols? subcommands?
- `module-map.md` — count of services? single executable?
- `infrastructure.md` — CLI? deployment manifests? Airflow/dbt?
- `integration-map.md` — inbound HTTP? inter-service? ETL/transforms?

Apply the scoring rules in `.claude/aid/templates/knowledge-summary/section-templates/auto-detect.md` to pick a profile.

Output to user:
```
[PROFILE] Auto-detected: {profile} (score {N}, confidence: {high|medium|low})
          Signals: {brief list}
          Override: re-run with --profile X --reset
```

If confidence is `low` (top score within 1 of second), present the top 2 candidates
and ask the user to choose using the `AskUserQuestion` tool.

Persist:
```
**Profile:** {chosen}
**Profile Source:** auto-detected | user-specified
**Profile Confidence:** {level}
```
to `.aid/knowledge/STATE.md` `## Knowledge Summary Status`.

Print: `[State: PROFILE] complete.`

**Advance:** **CHAIN** → [State: GENERATE] (continue inline).
