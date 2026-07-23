# task-002: aid-read-ticket skill

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

**Source:** work-023-ticket-integration -> delivery-001

**Depends on:** task-001

**Scope:**
- Author `canonical/skills/aid-read-ticket/` as a `SKILL.md` prose state machine (+ `references/state-*.md` only if warranted): states `PARSE-ARGS -> RESOLVE-CONNECTOR -> FETCH (host MCP) -> DISPLAY` (feature-001 §Feature Flow). Non-destructive; single host-MCP fetch; no confirm.
- Frontmatter: `name`; one-pass `description` (`aid-query-kb` style); `allowed-tools: Read, Glob, Grep, AskUserQuestion`; `argument-hint: [<connector>:]<ticket-id>`. No `Write`/`Edit` (the skill persists nothing in the repo).
- Point to the shared `canonical/aid/templates/connectors/ticket-resolution.md` (task-001) for the resolution ladder + grammar-parse + confirm conventions; do NOT re-describe the ladder inline.
- Grammar/parse: `[<connector>:]<ticket-id>` -- split on the first `:` (stem selects the connector; remainder = external-id), else the whole token is the id and the connector is resolved by the ladder. Missing/empty arg -> print the `argument-hint` usage line and exit.
- MCP-failure policy: a failed / not-found / unauthorized / unavailable host-MCP call surfaces the tracker's error verbatim and exits non-destructively (feature-001 §Feature Flow MCP-call failure policy).
- Authored under `canonical/` only; render is delivery-003 (feature-005).

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-read-ticket/SKILL.md` exists with the required frontmatter (incl. `AskUserQuestion` in `allowed-tools`; `argument-hint` = the grammar line) and the Feature-Flow states (AC-1 anatomy).
- [ ] `/aid-read-ticket [<connector>:]<ticket-id>` fetches via the resolved connector's host MCP and displays the ticket's fields; performs NO external write; shows NO confirmation prompt (AC-1).
- [ ] The skill points to the shared `ticket-resolution.md` for resolution/grammar/confirm and re-implements no ladder inline (feature-001 §Layers).
- [ ] Connector resolution follows the ladder via the shared reference: explicit `<stem>:` prefix override; 0/1/2+ scan; host-MCP; the `"no issue-tracker connector found."` notify string (AC-4/AC-5/AC-6).
- [ ] A not-found/unauthorized/unavailable read is reported (tracker error verbatim) and the skill exits non-destructively.
- [ ] Authored under `canonical/` only; structural/parse coverage is provided by task-005; no compiled build applies (prose state machine). All section-6 quality gates pass.
