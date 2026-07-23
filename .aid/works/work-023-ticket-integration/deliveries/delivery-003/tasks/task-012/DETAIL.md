# task-012: KB project-management guidance -- connectors + dedicated-skills model

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

**Type:** DOCUMENT

**Source:** work-023-ticket-integration -> delivery-003

**Depends on:** -- (none in-delivery; independent of task-011; runs after delivery-002 per PLAN.md ordering)

**Scope:**
- Update `.aid/knowledge/infrastructure.md` `## Project Management Tooling` (the real on-disk heading -- confirmed; the retired `infrastructure.md § Project Management` label never named a real section) to document the current model: outward tracker interaction happens through AID's connectors registry plus the three dedicated skills (`/aid-read-ticket`, `/aid-create-ticket`, `/aid-update-ticket`), never through automated ticket writes embedded in pipeline skills (feature-005 §Feature-Flow (a); AC-13).
- Keep the existing statement that AID itself uses no external tracker and tracks its own work in-repo (the added note describes how a project that DOES have a tracker now interacts with it). Add a `## Change Log` row; Change Log stays the last section.
- Citations (AC-13): cite the connector catalog by the KB->KB durable anchor `integration-map.md` `## Connectors`; cite the skills by KB->source anchors (`canonical/skills/aid-read-ticket/`, `canonical/skills/aid-create-ticket/`, `canonical/skills/aid-update-ticket/`) and the shared ladder `canonical/aid/templates/connectors/ticket-resolution.md`. NEVER cite the root context file (`CLAUDE.md` / `AGENTS.md`) -- KB cites KB->KB / KB->source only.
- This is a DIRECT dogfood-KB edit -- the KB under `.aid/knowledge/` is hand-authored working state, NOT rendered from `canonical/` and NOT part of byte-parity (feature-005 §Feature-Flow gotchas). Do NOT place it in `canonical/`; do not expect it in `profiles/`. (SPEC-mandated exception to the canonical-authoring invariant for this hand-authored KB doc.)
- `.aid/knowledge/INDEX.md` is generated -- never hand-edit; regenerate via `canonical/aid/scripts/kb/build-kb-index.sh` only if the doc summary shifted (a small addition to an existing section is not expected to).

**Acceptance Criteria:**
- [ ] `.aid/knowledge/infrastructure.md § Project Management Tooling` documents the connectors + dedicated-skills model (outward interaction via the connectors registry + the three skills; never automated ticket writes) and keeps the "AID uses no external tracker / tracks its own work in-repo" statement (AC-13).
- [ ] Citations are KB->KB (`integration-map.md` `## Connectors`) + KB->source (the three `canonical/skills/aid-*-ticket/` dirs + `ticket-resolution.md`); a grep of the edit for any `CLAUDE.md` / `AGENTS.md` citation returns zero (AC-13).
- [ ] A `## Change Log` row is added and Change Log remains the last section; `INDEX.md` is not hand-edited (regenerate via `build-kb-index.sh` only if the summary shifted).
- [ ] The edit is made in `.aid/knowledge/infrastructure.md` (dogfood KB) -- NOT in `canonical/`, NOT rendered (SPEC-mandated exception).
- [ ] Accuracy verified against the on-disk connectors model + the three skills; the citation/frontmatter lints (task-014) pass for this doc.
- [ ] All section-6 quality gates pass.
