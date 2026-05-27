> **Human-facing documentation.** Machine source consumed by `/aid-generate` is [`SKILL.md`](SKILL.md) in this folder.

# aid-config — Pipeline Configuration

View and update `.aid/settings.yml` — the single source of truth for AID
pipeline settings (grades, parallelism, heartbeat, project identity).

## Two modes

| Invocation | What it does |
|---|---|
| `/aid-config` | Print a table of all current settings. On first run, copy the template into place first. Suggests follow-up commands for any unset values. |
| `/aid-config <dotted.key>` | Show the current value of `<dotted.key>`; prompt for a new value (suggestions + free-form); validate; save. |

Examples:
- `/aid-config` — show everything
- `/aid-config project.name` — set the project name interactively
- `/aid-config review.minimum_grade` — change the global minimum grade
- `/aid-config discover.minimum_grade` — set a per-skill override (creates the `discover:` section if needed)

That's the whole UX. No state machine, no breadcrumb files, no multi-invocation
sequences.

## Settings schema

The canonical schema is at `canonical/templates/settings.yml`. Top-level sections:

| Section | Purpose |
|---|---|
| `project` | name, description, type (brownfield/greenfield) |
| `tools` | which AI host tools have AID installed |
| `review` | global default `minimum_grade` for every skill's REVIEW state |
| `execution` | `max_parallel_tasks` for `/aid-execute` + `/aid-deploy` |
| `traceability` | `heartbeat_interval` (minutes) for sub-agent visibility |

**Per-skill overrides** — any of 9 skill names (`discover`, `summary`,
`interview`, `specify`, `plan`, `detail`, `execute`, `deploy`, `monitor`)
may be added as a top-level key with its own `minimum_grade:` to override
the global value for that skill.

## How other skills read settings

Consumer skills resolve their settings via:

1. **Per-skill override** (e.g., `discover.minimum_grade`) — if present
2. **Global category default** (`review.minimum_grade`) — otherwise
3. **Hardcoded skill default** — only if `.aid/settings.yml` is missing entirely

The canonical resolution helper is `canonical/scripts/config/read-setting.sh`.

## Artifacts

| Artifact | Location | Purpose |
|----------|----------|---------|
| `.aid/settings.yml` | project root | The source of truth for pipeline configuration; consumed by every AID skill |

(`.aid/knowledge/` and `{project_context_file}` are scaffolded by other tools, not by `aid-config`.)

## Next Step

After setting `project.name` and `project.description`:

| Project type | Next skill |
|---|---|
| Brownfield (existing code) | `/aid-discover` — analyze the codebase and fill in the KB |
| Greenfield (new project) | `/aid-interview` — gather requirements from scratch |
