# Connector Preset Catalog

> Curated defaults for the tool-integration presets `aid-discover`'s `ELICIT` state (Step E2)
> offers when a developer declares a connectable tool. Each row pre-fills a
> `.aid/connectors/<connector>.md` descriptor — the connector-descriptor schema frozen by
> feature-001 (`name`, `connection_type`, `endpoint`, `auth_method`, `secret_reference`,
> `preset`) — and the user confirms or adjusts the pre-filled fields and supplies instance
> specifics (their own org/host/domain, the env-var name for `secret_reference`) before it is
> written. Any tool not listed here is still declared through the generic (`custom`) descriptor.
>
> This asset holds **defaults and templates only** — never a secret value and never a
> per-project instance value. `secret_reference-form` below names the reference *form*
> (`env:<VAR>` or `file:`), never a credential.
>
> This is a `canonical/` artifact: it ships and installs byte-identically into every profile's
> `.claude/aid/templates/connectors/` (or equivalent per-tool) install tree, alongside
> [`kb-authoring/domain-doc-matrix.md`](../kb-authoring/domain-doc-matrix.md), which it mirrors
> in shape — a curated, LLM-read lookup table a discovery gate consults directly from disk (no
> per-project templating at render time; the render is a plain copy).

## Columns

| Column | Meaning |
|--------|---------|
| `preset-id` | Stable id written into the descriptor's `preset` field (e.g. `github`) |
| `name` | Default human name |
| `connection_type` | Default transport — closed enum `mcp \| api \| ssh \| url \| cli` (feature-001 Data Model) |
| `endpoint-template` | Endpoint/launch-spec skeleton; instance specifics (host, org, domain) are completed at elicitation |
| `auth_method` | Default auth axis — closed enum `none \| token \| pat \| oauth \| ssh-key` (feature-001 Data Model); orthogonal to `connection_type` |
| `secret_reference-form` | Default reference FORM only — `env:<VAR>` or `file:` — never a value; `—` when `auth_method` is `none` |
| `notes` | One-line human guidance; seeds the descriptor's `objective`/`summary` |
| `tags` | Preset-declared tag override, appended to `ELICIT`'s auto-derived `[connector, <connection_type>]` default |

`audience` is not overridden by any preset row below; every row uses `ELICIT`'s auto-derived
default (`[developer, architect]`, feature-001's worked `github.md` example), so the column is
omitted here (YAGNI — an all-default column carries no information).

## Presets

| preset-id | name | connection_type | endpoint-template | auth_method | secret_reference-form | notes | tags |
|-----------|------|------------------|--------------------|-------------|------------------------|-------|------|
| `github` | GitHub | `mcp` | `docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server` | `pat` | `env:GITHUB_PERSONAL_ACCESS_TOKEN` | GitHub issues/PRs/repos via the official GitHub MCP server (Docker-hosted); scope the PAT to only the repos it needs. | `[connector, mcp, source-host]` |
| `gitlab` | GitLab | `api` | `https://{your-gitlab-host}/api/v4` | `pat` | `file:` | GitLab issues/MRs/repos via the REST API v4; replace `{your-gitlab-host}` with `gitlab.com` or your self-hosted instance. | `[connector, api, source-host]` |
| `jira` | Jira | `api` | `https://{your-domain}.atlassian.net/rest/api/3` | `token` | `file:` | Jira Cloud issues via the REST API v3; replace `{your-domain}` with your Atlassian site name. | `[connector, api, issue-tracker]` |
| `slack` | Slack | `api` | `https://slack.com/api/` | `token` | `file:` | Slack channels/messages via the Slack Web API; requires a bot token installed to the workspace with the needed scopes. | `[connector, api, chat]` |
| `confluence` | Confluence | `api` | `https://{your-domain}.atlassian.net/wiki/rest/api` | `token` | `file:` | Confluence Cloud pages/spaces via the REST API; replace `{your-domain}` with your Atlassian site name; shares Jira's Atlassian API-token auth pattern. | `[connector, api, docs]` |
| `notion` | Notion | `api` | `https://api.notion.com/v1` | `token` | `file:` | Notion pages/databases via the Notion API; requires an internal integration secret shared with the target pages/databases. | `[connector, api, docs]` |
| `jenkins` | Jenkins | `api` | `https://{your-jenkins-host}/` | `token` | `file:` | Jenkins jobs/builds via its REST API; replace `{your-jenkins-host}` with your Jenkins base URL. | `[connector, api, ci]` |
| `docker` | Docker | `cli` | `docker` | `none` | `—` | Local Docker Engine via the `docker` CLI/socket for container-runtime tasks; no auth needed against an unmodified local daemon. | `[connector, cli, container-runtime]` |
