# task-004: Consumption protocol + seam wiring + multi-level ticket_ref STATE/SPEC schema

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

**Source:** work-004-connector-consumption -> delivery-001

**Depends on:** — (none)

**Scope:**
- Author `canonical/aid/templates/connectors/consumption-protocol.md` — the MCP-first "how a seam
  uses a connector" reference: at a wired seam the agent scans `INDEX.md`; for a relevant
  `connection_type: mcp` connector it uses the **host tool's MCP** (AID resolves nothing, stores no
  credential). aid-managed consumption (`api`/`ssh`/`url`/`cli`) is explicitly out of scope
  (MCP-first only — OD-Q1).
- Document the **multi-level `ticket_ref` linkage** + **nearest-ancestor resolution** contract in
  the same reference: form `<connector-stem>:<external-id>` (e.g. `jira:PROJ-123`), tying the link
  to a catalogued connector; settable at **any** level (work / feature / delivery / task).
  Resolution by AID containment (`work ⊃ delivery ⊃ task`, `work ⊃ feature`; a delivery groups ≥1
  feature): a unit uses its own `ticket_ref` if present, else inherits — `delivery → work`;
  `feature → work`; and for a **task** `task → its owning (SPEC-traced) feature → its delivery →
  work` (feature outranks delivery; a task tracing to no single feature skips the feature level).
- Add the optional `ticket_ref` scalar to the STATE/SPEC schema at every lifecycle unit that
  carries a STATE/SPEC: work STATE frontmatter, feature SPEC, delivery STATE frontmatter, and task
  STATE (plus the flattened `### Tasks lifecycle`). Readers/dashboard ignore it when absent.
  Coordinate with the in-flight `work-003-state-schema` frontmatter conventions; `ticket_ref` is a
  **lifecycle-unit** field, never a connector-descriptor field (the descriptor schema is unchanged).
- Wire the consumption seams by adding a connector-awareness step that references
  `consumption-protocol.md`: `aid-describe`/`aid-specify` (read a source ticket → record a
  `ticket_ref` at the level created), `aid-plan`/`aid-fix` (create/register a ticket → record its
  `ticket_ref`), `aid-execute` (resolve the **nearest** `ticket_ref` for the unit it acts on; mirror
  `STATE.md` task-state transitions → that ticket), `aid-query-kb` (enrich), and the
  `aid-researcher` + `aid-developer` agents.
- Markdown-only; **no new scripts** (consumption is MCP-only; AID stores no credential and resolves
  nothing for it).

**Acceptance Criteria:**
- [ ] `canonical/aid/templates/connectors/consumption-protocol.md` documents the MCP-first seam
  behavior (scan `INDEX.md` → use the host MCP for `connection_type: mcp`; AID stores no credential)
  and the multi-level `ticket_ref` linkage + nearest-ancestor resolution contract (traces to AC9).
- [ ] The optional `ticket_ref` scalar (`<connector-stem>:<external-id>`) is added to the STATE/SPEC
  schema at work, feature, delivery, and task levels; readers ignore it when absent; the connector
  descriptor schema is unchanged (traces to AC9).
- [ ] The consumption seams (`aid-describe`, `aid-specify`, `aid-plan`, `aid-fix`, `aid-execute`,
  `aid-query-kb`, `aid-researcher`, `aid-developer`) each reference `consumption-protocol.md`;
  ingest seams record a `ticket_ref` at the level they create, and `aid-execute` resolves the
  nearest ref and mirrors task-state transitions to that ticket (traces to AC9).
- [ ] A task with `ticket_ref: jira:PROJ-45` (or inheriting from feature, else delivery, else work)
  + a `jira` MCP connector: an `In Progress` transition posts to `PROJ-45` (traces to AC9).
- [ ] All section-6 quality gates pass.
