# task-004: aid-update-ticket skill

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
- Author `canonical/skills/aid-update-ticket/` as a `SKILL.md` prose state machine (+ `references/state-*.md` only if warranted): states `PARSE-ARGS -> RESOLVE-CONNECTOR -> LOAD-CONTEXT -> COMPOSE -> CONFIRM (AskUserQuestion, showing the exact change) -> WRITE (host MCP)` (feature-001 §Feature Flow; AC-3).
- Grammar/parse: `<part> [<connector>:]<ticket-id> <content>`, `part in {description, comment, status}` (closed enum; reject anything else with the usage line). The first whitespace token is `part`, the second is the ref (colon-split for stem), everything after is `<content>` (free text, may contain spaces/colons, never re-parsed).
- Semantics: `description` REPLACES the field; `comment` APPENDS a comment; `status` SETS the state. LOAD-CONTEXT per part: `status` -> fetch available transitions; `description` -> fetch current value for a before/after preview; `comment` -> none.
- Status validation: validate the requested target against the tool's available transitions and, on mismatch, list the valid targets and stop; if the MCP cannot enumerate transitions, attempt and surface the tracker's own error verbatim (feature-001 §Security Specs).
- CONFIRM is an in-run `AskUserQuestion` gate before the MCP write (CHAIN, not PAUSE). MCP-failure is non-destructive (no partial write).
- Frontmatter per feature-001 §Layers (incl. `AskUserQuestion`; `argument-hint` = the update grammar line; no `Write`/`Edit`); point to the shared `ticket-resolution.md` (task-001); do not re-describe the ladder inline.
- Authored under `canonical/` only.

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-update-ticket/SKILL.md` exists with the required frontmatter (`AskUserQuestion` in `allowed-tools`; `argument-hint` = the update grammar line) and the LOAD-CONTEXT/COMPOSE/CONFIRM/WRITE states (AC-3 anatomy).
- [ ] `/aid-update-ticket {description|comment|status} [<connector>:]<ticket-id> <content>` mutates ONLY the named part after preview + confirm (`description` replaces, `comment` appends, `status` sets) (AC-3).
- [ ] A `status` target is validated against the tool's available transitions; an invalid target lists the valid options (falls back to attempt-and-surface-verbatim when transitions cannot be enumerated) (AC-3).
- [ ] `part` is a closed enum (reject anything else with the usage line); the content remainder is taken verbatim and never re-parsed (feature-001 §API Contracts).
- [ ] Points to the shared `ticket-resolution.md`; authored under `canonical/` only; parse/behavior coverage is provided by task-005; no compiled build applies. All section-6 quality gates pass.
