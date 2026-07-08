# task-007: Connector preset catalog canonical asset

**Type:** CONFIGURE

**Source:** work-002-external_sources -> delivery-001

**Depends on:** -- (none)

**Scope:**
- New curated asset `canonical/aid/templates/connectors/preset-catalog.md` — a markdown table with the columns from feature-002 Data Model (`preset-id`, `name`, `connection_type`, `endpoint-template`, `auth_method`, `secret_reference-form`, `notes`, optional `tags` / `audience`).
- Seed rows for the requirement-named tools (REQUIREMENTS §1): `github`, `gitlab`, `jira`, `slack`, `confluence`, `notion`, `jenkins`, `docker`; authored `endpoint-template` per row.
- Holds defaults and templates only — never a secret value and never a per-project instance value. Renders into each profile's install tree like other `canonical/aid/templates/**` assets; LLM-read at ELICIT Step E2.

**Acceptance Criteria:**
- [ ] The catalog contains the eight seed preset rows with all required columns populated
- [ ] Every `connection_type` is within feature-001's enum (`mcp | api | ssh | url | cli`) and every `auth_method` within (`none | token | pat | oauth | ssh-key`)
- [ ] The asset contains NO plaintext secret and no per-project instance value (references/templates only)
- [ ] Re-rendering the profiles from this asset is idempotent (byte-stable install-tree copies)
- [ ] `endpoint-template` values are verified accurate against current tooling (e.g. the GitHub MCP server launch spec)
- [ ] All §6 quality gates pass
