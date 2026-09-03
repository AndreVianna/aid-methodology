# task-001: Node runtime component provisioned in the `aid` payload

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

**Source:** feature-002-node-and-message-plane -> delivery-001 -> AC-9, AC-22

**Depends on:** --

**Scope:**
- A `chat-node/` runtime component at the repository root, provisioned exactly as `dashboard/` already is -- a directory of runtime files, not a separate distributable.
- Its file set listed in **every** manifest that derives a file list, so no publication channel can ship a partial node.
- No third-party dependency added to any package manifest: the node needs none, and FR-7.6 is satisfied literally rather than by a carve-out.

**Acceptance Criteria:**
- [ ] `chat-node/` exists at the repository root and appears in every manifest that names `dashboard/`; verified by grepping each manifest for both names and comparing the counts.
- [ ] `aid`'s package manifests still declare **zero** third-party dependencies after this task; verified by reading each dependency list.
- [ ] A fresh install from each channel places the node's files on disk; verified by listing the installed tree per channel.
- [ ] Re-running the provisioning step changes nothing (idempotent); verified by a second run producing no diff.
- [ ] No plaintext secrets in anything this task adds.
- [ ] All section-6 quality gates pass
