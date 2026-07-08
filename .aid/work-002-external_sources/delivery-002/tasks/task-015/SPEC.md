# task-015: Host-MCP-config wire/unwire twin

**Type:** IMPLEMENT

**Source:** work-002-external_sources -> delivery-002

**Depends on:** task-014, task-001

**Scope:**
- New Bash+PowerShell twin under `canonical/aid/scripts/connectors/` with symmetric `wire <stem>` and `unwire <stem>` ops that read task-014's mechanism table and perform an idempotent read-merge-write per installed host.
- `wire`: tokenize the descriptor `endpoint` into `command` + `args`, attach the secret as an `env` reference (`${VAR}` passthrough — name only, never the value), add/update only this connector's server entry; preserve all other servers (e.g. the repo's `playwright-project`).
- `unwire`: remove only this connector's server entry (`mcpServers` key / the codex `[mcp_servers.<name>]` equivalent); clean-success no-op if absent; never delete the config file.
- wire-only-installed: act only on hosts in `.aid/settings.yml tools.installed` (via `read-setting.sh --path tools.installed` — within KI-001's 2-level limit); skip uninstalled hosts cleanly (no error, no empty file). Nested JSON via Python stdlib `json` (no hard `jq`); the codex TOML write path is deferred (verify-at-implementation, KI-006).

**Acceptance Criteria:**
- [ ] `wire` merges the connector into an installed host's config keyed by the `<stem>` server name, preserving every other server + user content; re-running is idempotent (no duplication)
- [ ] Committed MCP configs carry only an `env` reference (`${VAR}`), never a secret value
- [ ] `unwire` removes only this connector's entry, is a clean no-op if already absent, and never deletes the config file
- [ ] Uninstalled hosts are skipped cleanly (no error, no empty config created); an `api | ssh | url | cli` connector triggers no host write
- [ ] Nested JSON uses Python stdlib only (no new heavy dependency — AC-8); shipped PowerShell is WinPS-5.1-compatible + ASCII-only
- [ ] Unit tests cover `wire` + `unwire` against fixture configs; all existing tests still pass; build passes
- [ ] All §6 quality gates pass
