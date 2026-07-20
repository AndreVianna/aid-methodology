# task-019: ConnectorRef reader/model + connector.set/remove ops

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** feature-007-connectors-list -> delivery-003

**Depends on:** task-018, task-004 (delivery-001)

**Scope:**
- Add a new read-model record `ConnectorRef` (`dashboard/reader/models.py`, a new dataclass beside
  `KbStateRef`), one per descriptor, read-only (never persisted), with fields in declared order:
  `stem` (filename stem == the remove key), `name`, `connection_type` (raw scalar; no enum added),
  `endpoint?`, `auth_method?`, `secret_reference?`, `summary?`.
- Add a new source-of-truth parser `parse_connectors(connectors_dir)` (Python,
  `dashboard/reader/parsers.py`) / `parseConnectors(connectorsDir)` (Node,
  `dashboard/server/reader.mjs`) as **byte-parity twins**, following the readers' established
  `parse_*` naming: enumerate `<aid_dir>/connectors/*.md` with the EXACT filter
  `connector-registry.sh list` uses (`*.md`, excluding `INDEX.md` and dotfiles, sorted by stem --
  `connector-registry.sh` lines 151-154); a missing `connectors/` dir -> empty list (non-error).
  Per descriptor extract the six frontmatter scalars using the readers' existing
  first-frontmatter-block single-line-scalar extraction (same semantics as `connector-registry.sh`
  `read_field` / `build-connectors-index.sh` `ef()`: a body-level `---` never re-enters
  frontmatter); build one `ConnectorRef` with `stem` = filename.
- Add an additive field `connectors: list[ConnectorRef]` on `RepoInfo` (`models.py` lines 220-226,
  beside `kb_state` -- connectors are a project-level `.aid/` registry), sorted by `stem`. Surface
  it ONLY in the DM-1 `RepoModel` served by `GET /r/<id>/api/model`; do NOT touch the DM-2 home
  model (`/api/home`). Wire `parse_connectors` into `read_repo` where `RepoInfo` is constructed
  (`reader.py` ~line 373/425) and the Node twin (`reader.mjs` `repoInfo`, ~line 2640):
  `RepoInfo(..., connectors=parse_connectors(...))`.
- Extend the serializer twins: add `connectors` AFTER `kb_state` in the RepoInfo dict -- `server.py`
  `_ser_repo_info` (lines 595-601) and `reader.mjs` `_buildRepoInfo` (lines 4328-4332) -- each
  `ConnectorRef` serialized in declared field order (`stem, name, connection_type, endpoint,
  auth_method, secret_reference, summary`). Do NOT bump `schema_version` (DM-1 stays 3; additive-key
  precedent). Regenerate the golden fixtures for the twin parity suites
  (`dashboard/server/tests/test_server_node.mjs`, `test_server_py.py`; `dashboard/reader/tests/`) in
  lockstep.
- Append TWO project-scoped rows to feature-001's `OP_TABLE` (both `server.py` + `server.mjs`
  byte-parity twins): `connector.set` -> `write-connector.sh set --root <repo>/.aid/connectors
  --name … --type … [--endpoint …] [--auth …] [--secret-ref …]`; `connector.remove` ->
  `write-connector.sh remove --root <repo>/.aid/connectors --stem <stem>`. Both are per-repo,
  project-scoped: the request carries `target: {}` (present-but-empty, consuming feature-002's
  `settings.set` envelope shape) and does NOT consume `target.work_id`; `<id>` alone resolves the
  repo path (verbatim from `id_map`, SEC-2) and the writer's `--root` is the server-built absolute
  `<repo>/.aid/connectors`. argv is an ARRAY (never a shell string).
- Add the conditional per-op arg-schema (validated server-side before any spawn): `connector.set` --
  `name` required (1-80 chars; reject newline/`|`/control -> 422); `type` required in
  `mcp|api|ssh|url|cli`; `endpoint` required when `type in {api,ssh,url,cli}` (<=200 chars; reject
  newline/`|`); `auth` required when `type in {api,url,cli}` (in `none|token|pat|oauth`; when present
  in `none|token|pat|oauth|ssh-key`); `secret_ref` conditionally required for a credentialed
  connector but the client MAY omit it (writer defaults) -- when supplied it must match
  `^(env:[A-Za-z_][A-Za-z0-9_]*|file:[^\n|]+|keychain:[^\n|]+)$`, <=200 chars; forbidden for
  `mcp`/`auth none`. `connector.remove` -- `stem` required matching `^[a-z0-9][a-z0-9-]*$`.
  A validation failure -> 422 before spawn.
- Rely on the writer (task-018) + feature-001's generic exit->HTTP map for dispatch; this task adds
  no per-op `status_map` override (the writer emits feature-001's literal alphabet). No new route,
  no new gate, no in-process fs write.

**Acceptance Criteria:**
- [ ] `parse_connectors` / `parseConnectors` enumerate `.aid/connectors/*.md` with the exact
  `connector-registry.sh list` filter (excluding `INDEX.md`/dotfiles, sorted by stem), return `[]`
  for a missing dir, and build one `ConnectorRef` per descriptor from the six frontmatter scalars;
  the two twins produce byte-identical output over a shared fixture set. (feature-007 AC2)
- [ ] `RepoInfo` gains a `connectors: list[ConnectorRef]` field sorted by `stem`, surfaced under
  `model.repo.connectors` in the DM-1 `/r/<id>/api/model` envelope and absent from the DM-2
  `/api/home` model; the secret VALUE and `.secrets/` contents are never read or serialized.
- [ ] Serializers emit `connectors` after `kb_state` with each `ConnectorRef` in declared field
  order; `schema_version` is NOT bumped; regenerated golden fixtures keep `test_server_py.py` /
  `test_server_node.mjs` / reader twin suites green (byte-parity).
- [ ] `OP_TABLE` (both twins) carries `connector.set` and `connector.remove` with the argv arrays
  above; both send `target: {}`, resolve `<repo>/.aid/connectors` server-side from `<id>` (never
  from the body), and never consume `work_id`.
- [ ] The per-op arg schema validates `connector.set` (`name`/`type`/conditional
  `endpoint`/`auth`/`secret_ref`) and `connector.remove` (`stem` charset) BEFORE any child spawn,
  returning 422 `invalid-value` on a violation; argv is an array. (feature-007 AC1)
- [ ] A `connector.set` / `connector.remove` op dispatched through the endpoint invokes
  `write-connector.sh` and maps its exit code to HTTP via feature-001's literal table with no per-op
  remapping (200/422/500).
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
