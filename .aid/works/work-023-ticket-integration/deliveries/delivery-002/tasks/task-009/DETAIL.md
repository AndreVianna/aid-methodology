# task-009: Revise consumption-protocol.md to the single-surface model

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

**Source:** work-023-ticket-integration -> delivery-002

**Depends on:** task-008

**Scope:**
- Apply edits E1-E7 to the single file `canonical/aid/templates/connectors/consumption-protocol.md` (feature-004 §Feature Flow), `canonical/` only, so the shared reference describes the reads-delegate-to-`/aid-read-ticket` / writes-via-dedicated-skills model and drops every automated file/mirror/comment seam. This is a load-bearing prose contract (P1(d)-SIG inline contracts an agent reads to decide what a seam may do) -- authoring it IS implementing the new protocol:
  - **E1** intro blockquote: keep the "short, additive pointer" model but replace the "mirror is additive-on-top" write-implying parenthetical with the single-surface framing (a wired seam consumes a connector for reads only, delegating the read to `/aid-read-ticket`, and never files/comments/transitions; writes flow through the dedicated skills).
  - **E2** seam-recipe Step 1: "reading or filing a ticket" -> "reading a ticket".
  - **E3** seam-recipe Step 4: rename "**Act, then stop.**" -> "**Read, then stop.**"; a seam reads through the host MCP only and delegates that read to `/aid-read-ticket`; never files/comments/transitions. KEEP the trailing "Never persist anything host-MCP-specific ... cache of live tool state." sentence unchanged.
  - **E4** "## Nearest-ancestor resolution" opener: reframe to consumer-less inheritance/traceability semantics (name no caller). Everything after it (the "own ref else inherit" lead-in, the containment-chains table, the "Why feature outranks delivery" rationale, the SPEC-traced-owning-feature paragraph, the terminal silent-skip case) is UNCHANGED / byte-identical (FR-11).
  - **E5** "## Wired seams" table: DELETE the `aid-execute` Target row in full (Target ceases to be a role; only Ingest + Enrich remain). Ingest rows keep their record-`ticket_ref` role with the read verb delegated to `/aid-read-ticket` (aid-describe, aid-specify); aid-plan/aid-fix record-only rows unchanged; Enrich rows (aid-query-kb, aid-researcher, aid-developer) delegate the read to `/aid-read-ticket`.
  - **E6** "**Ingest vs. target, restated.**" -> "**Ingest vs. enrich, restated.**": drop the target/mirror concept; no seam performs an outward write.
  - **E7** "## Worked example (AC9)" -> "## Worked example (nearest-ancestor resolution)": replace the five-step `aid-execute` status-mirror walkthrough with an id-based inheritance one (task with no own ref inherits owning SPEC-traced feature `jira:PROJ-45`; live fields read via `/aid-read-ticket jira:PROJ-45`; no outward write occurs).
- Assert the three inline contracts (read-delegation; write-routing; LOCAL-LINK populated only from a user-supplied ref) per feature-004 §API Contracts. Keep the `ticket_ref` multi-level linkage + nearest-ancestor resolution; the MCP-first scope + the `api`/`ssh`/`cli`-out-of-scope header note are unchanged.
- Do NOT touch any seam file, any of the four `ticket_ref`-carrying templates (FR-11), or any KB doc.

**Acceptance Criteria:**
- [ ] No automated file/mirror/comment seam remains: `grep -i mirror consumption-protocol.md` -> 0; the `aid-execute` Target row is absent; "Read or write through the host MCP" is gone; the "## Worked example" section describes a read, not a status mirror (AC-11).
- [ ] The `ticket_ref` multi-level linkage + nearest-ancestor resolution are retained; the containment-chains table + the "Why feature outranks delivery" rationale are byte-identical apart from E4's reframed opener (AC-11).
- [ ] The doc states inline that seam reads delegate to `/aid-read-ticket` (recipe Step 4 + every ingest/enrich row + the "Ingest vs. enrich" paragraph) and all writes go via the dedicated skills (intro + Step 4 + API Contracts) (AC-11).
- [ ] `ticket_ref` is documented as populated only from a user-supplied ref (never auto-created/auto-discovered); a no-`ticket_ref`/no-connector project is a silent no-op at every seam (AC-10); the four `ticket_ref`-carrying templates are unchanged (FR-11).
- [ ] The edit is confined to `canonical/aid/templates/connectors/consumption-protocol.md`; no seam file, template, or KB doc is touched; authored in `canonical/` only. This deliverable is prose (no unit-testable code, no compiled build), so the code-specific IMPLEMENT defaults are superseded by these doc-structural criteria (feature-004 §Testing), verified in task-010.
- [ ] All section-6 quality gates pass.
