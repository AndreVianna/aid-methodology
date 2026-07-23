# task-003: aid-create-ticket skill (--level / --parent + LEVEL-RESOLVE)

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
- Author `canonical/skills/aid-create-ticket/` as a `SKILL.md` prose state machine (+ `references/state-*.md` only if warranted): states `PARSE-ARGS -> RESOLVE-CONNECTOR -> COMPOSE -> LEVEL-RESOLVE -> CONFIRM -> FILE (host MCP) -> RETURN-REF` (feature-001 §Feature Flow; AC-2, FR-2a, FR-2b).
- Grammar/parse: `[--connector <stem>] [--level epic|story|task] [--parent <ref>] <description>` -- flags in any order before the trailing free-text; the whole non-flag remainder is the `<description>` verbatim (never re-parsed); create has NO bare-leading-token connector heuristic. `--level` takes the closed canonical enum (case-insensitive) OR a quoted literal provider-type passthrough; a bare non-tier value is rejected with the usage line. `--level` is optional with NO default. Missing `<description>` -> usage line and exit.
- COMPOSE fixes level and parent by precedence, defaulting neither silently: level = explicit `--level` > description-inferred > unset; parent = `--parent <ref>` > description-inferred > none.
- LEVEL-RESOLVE (non-destructive host-MCP issue-type query, runs before the gate): map the canonical tier to the tracker's concrete issue-type by the ordered synonym set (first available wins); a quoted literal passthrough skips synonym-matching; graceful degradation to a plain issue + optional `type:<tier>` label when no tier matches, with the concrete resolved type (or the degradation note) shown in the preview.
- CONFIRM (single in-run `AskUserQuestion` gate, CHAIN not PAUSE): when the level is unset/uninferable its pick IS the `epic|story|task` selection folded into this gate; an inferred level is surfaced for confirmation; the preview shows the resolved issue-type (or degradation note) and any `--parent`/inferred-parent link (or a no-hierarchy note) before `[1] File it / [2] Edit / [3] Cancel`.
- FILE writes via the host MCP and sets the provider's native parent link best-effort -- only after confirm; a rejected/absent hierarchy is noted in the preview and does not fail the create.
- Frontmatter per feature-001 §Layers (incl. `AskUserQuestion`; `argument-hint` = the create grammar line; no `Write`/`Edit`); point to the shared `ticket-resolution.md` (task-001).
- The persistent per-connector `level_map` override is DEFERRED (needs a connector-descriptor field -> out of scope; no schema change) -- the runtime synonym match + literal passthrough cover the need here.
- Authored under `canonical/` only.

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-create-ticket/SKILL.md` exists with the required frontmatter (`AskUserQuestion` in `allowed-tools`; `argument-hint` = the create grammar line) and the COMPOSE/LEVEL-RESOLVE/CONFIRM/FILE/RETURN-REF states (AC-2 anatomy).
- [ ] Files a ticket ONLY after a preview of exactly what will be sent + explicit confirm, then returns the new `<connector-stem>:<external-id>` -- and only then (AC-2).
- [ ] The level is never silently defaulted: absent `--level` and uninferable -> the confirm gate requires an explicit `epic|story|task` pick; an inferred level is surfaced; the canonical tier is shown resolved to the tracker's concrete issue-type in the preview, with a graceful-degradation note when the tracker lacks that tier (AC-2, FR-2a).
- [ ] `--connector`/`--level`/`--parent` parse in any order before the description; the whole non-flag remainder is the description; no bare-leading-token connector heuristic; `--level` accepts the closed enum (case-insensitive) or a quoted literal passthrough and rejects a bare non-tier value with the usage line (feature-001 §API Contracts).
- [ ] An optional `--parent` (or inferred parent) is shown in the preview and linked via the provider's native hierarchy best-effort (noted, non-fatal, when the tracker has none) (AC-2, FR-2b).
- [ ] LEVEL-RESOLVE and the issue-type query are non-destructive reads run before the gate; nothing about level or parent reaches the tracker before confirm (feature-001 §Security Specs).
- [ ] Points to the shared `ticket-resolution.md`; authored under `canonical/` only; parse/behavior coverage is provided by task-005; no compiled build applies. All section-6 quality gates pass.
