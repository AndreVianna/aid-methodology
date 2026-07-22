# task-003: Re-emit to profiles + resync dogfood

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
> `aid-execute/references/state-execute.md § MANDATORY: State-Write Protocol`.

**Type:** CONFIGURE

**Source:** work-020-update-kb-intent-alignment -> delivery-001

**Depends on:** task-001, task-002

**Scope:**
- Run the generator (per `canonical/EMISSION-MANIFEST.md`) to re-emit the edited `canonical/skills/aid-update-kb/` (SKILL.md + all reference docs, including the two new state files) into every `profiles/<tool>/…/skills/aid-update-kb/` copy.
- Resync the dogfood `.claude/skills/aid-update-kb/` from `profiles/claude-code/` (the setup.sh install path), so the installed skill matches canonical.
- Verify propagation: each generated copy differs from `canonical/` only by the profile path-prefix rewrite (e.g. `canonical/` → `.claude/`), and the two new reference files (`state-scope.md`, `state-confirm.md`) are present in every profile.

**Acceptance Criteria:**
- [ ] All five profiles + dogfood `.claude/` contain the redesigned `aid-update-kb` (7 reference files: analyze, scope, confirm, apply, review, approval, done + SKILL.md).
- [ ] Each generated copy is path-prefix-parity clean against `canonical/` (byte-identical modulo the documented prefix rewrite) — `test-dogfood-byte-identity` stays green (AC-7).
- [ ] No generated copy was hand-edited (all changes trace to the `canonical/` source).
- [ ] All section-6 quality gates pass.
