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
> **Management mode (STATE.md Q10 — derived from `connection_type`).** A preset row whose
> `connection_type` is `mcp` is **tool-managed**: the host tool provides its own MCP server/plugin
> for the target, so `auth_method` is always `none` and `secret_reference-form` is always `—` —
> AID registers no credential for it, and `endpoint-template` is **informational only** (never a
> launch/wire command). A preset row whose `connection_type` is `api \| ssh \| url \| cli` is
> **aid-managed**: `auth_method` and `secret_reference-form` are the credential AID records
> locally, and `endpoint-template` is the concrete connect target.
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
| `endpoint-template` | Endpoint skeleton; instance specifics (host, org, domain) are completed at elicitation. For a **tool-managed** (`mcp`) preset this is **informational only** (e.g. "via the host tool's own GitHub MCP server") — never a launch/wire command (AID does not launch or wire it — Q10); for an **aid-managed** preset it is the concrete connect target |
| `auth_method` | Default auth axis — closed enum `none \| token \| pat \| oauth \| ssh-key` (feature-001 Data Model); orthogonal to `connection_type`. **Always `none` for a tool-managed (`mcp`) preset** — the host tool authenticates the target, so AID registers no credential (Q10) |
| `secret_reference-form` | Default reference FORM only — `env:<VAR>` or `file:` — never a value, for **aid-managed** presets only. **Always `—` for a tool-managed (`mcp`) preset** — AID stores no credential for it (Q10) |
| `notes` | One-line human guidance; seeds the descriptor's `objective`/`summary` |
| `tags` | Preset-declared tag override, appended to `ELICIT`'s auto-derived `[connector, <connection_type>]` default |

`audience` is not overridden by any preset row below; every row uses `ELICIT`'s auto-derived
default (`[developer, architect]`, feature-001's worked `github.md` example), so the column is
omitted here (YAGNI — an all-default column carries no information).

## Presets

| preset-id | name | connection_type | endpoint-template | auth_method | secret_reference-form | notes | tags |
|-----------|------|------------------|--------------------|-------------|------------------------|-------|------|
| `github` | GitHub | `mcp` | via the host tool's own GitHub MCP server | `none` | `—` | Tool-managed: request the connection from your host tool's GitHub MCP; the host tool handles auth (AID stores no credential). | `[connector, mcp, source-host]` |
| `gitlab` | GitLab | `api` | `https://{your-gitlab-host}/api/v4` | `pat` | `file:` | GitLab issues/MRs/repos via the REST API v4; replace `{your-gitlab-host}` with `gitlab.com` or your self-hosted instance. | `[connector, api, source-host]` |
| `jira` | Jira | `api` | `https://{your-domain}.atlassian.net/rest/api/3` | `token` | `file:` | Jira Cloud issues via the REST API v3; replace `{your-domain}` with your Atlassian site name. | `[connector, api, issue-tracker]` |
| `slack` | Slack | `api` | `https://slack.com/api/` | `token` | `file:` | Slack channels/messages via the Slack Web API; requires a bot token installed to the workspace with the needed scopes. | `[connector, api, chat]` |
| `confluence` | Confluence | `api` | `https://{your-domain}.atlassian.net/wiki/rest/api` | `token` | `file:` | Confluence Cloud pages/spaces via the REST API; replace `{your-domain}` with your Atlassian site name; shares Jira's Atlassian API-token auth pattern. | `[connector, api, docs]` |
| `notion` | Notion | `api` | `https://api.notion.com/v1` | `token` | `file:` | Notion pages/databases via the Notion API; requires an internal integration secret shared with the target pages/databases. | `[connector, api, docs]` |
| `jenkins` | Jenkins | `api` | `https://{your-jenkins-host}/` | `token` | `file:` | Jenkins jobs/builds via its REST API; replace `{your-jenkins-host}` with your Jenkins base URL. | `[connector, api, ci]` |
| `docker` | Docker | `cli` | `docker` | `none` | `—` | Local Docker Engine via the `docker` CLI/socket for container-runtime tasks; no auth needed against an unmodified local daemon. | `[connector, cli, container-runtime]` |
