# task-005: Add the ## Connectors section to all 5 profile context files (AGENTS.md byte-identity)

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

**Type:** CONFIGURE

**Source:** work-004-connector-consumption -> delivery-001

**Depends on:** — (none)

**Scope:**
- Add the `## Connectors` section to **all 5** profile context files —
  `profiles/claude-code/CLAUDE.md`, `profiles/antigravity/AGENTS.md`, `profiles/codex/AGENTS.md`,
  `profiles/copilot-cli/AGENTS.md`, `profiles/cursor/AGENTS.md` — propagating the section that
  currently exists only in the dogfood root `CLAUDE.md` (the pointer-bug fix, REQUIREMENTS §2). The
  section is the catalog-not-connection-manager protocol: scan `.aid/connectors/INDEX.md`; for an
  `mcp` connector request the connection from the host tool's own MCP/plugin; for
  `api`/`ssh`/`url`/`cli` resolve the descriptor's `secret_reference` at use-time.
- The four `AGENTS.md` (antigravity, codex, copilot-cli, cursor) MUST remain **byte-identical** to
  each other after the edit (`test-agents-md-invariant.sh`).
- These context files are **hand-maintained + installer-propagated** — they are NOT canonical
  (`canonical/`)-rendered by `/generate-profile`. The installer managed-region allowlist already
  covers the `Connectors` stem (`lib/aid-install-core.sh`, `lib/AidInstallCore.psm1`) — confirm the
  allowlist entry is present; **no installer change** is required.

**Acceptance Criteria:**
- [ ] The `## Connectors` section is present in all 5 profile context files
  (`profiles/claude-code/CLAUDE.md` + the four `AGENTS.md`) (traces to AC8).
- [ ] The four `AGENTS.md` (antigravity, codex, copilot-cli, cursor) are byte-identical to each
  other after the edit; `tests/canonical/test-agents-md-invariant.sh` passes (traces to AC8).
- [ ] The installer managed-region allowlist already covers the `Connectors` stem (verified in
  `lib/aid-install-core.sh` + `lib/AidInstallCore.psm1`); no installer change is made (traces to AC8).
- [ ] All section-6 quality gates pass.
