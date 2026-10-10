# task-017: Shared-install suite: byte-identical skills and runtime for every tool

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

**Type:** TEST

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-3, AC-7

**Depends on:** task-012, task-014

**Scope:**
- `tests/canonical/test-shared-install.sh` (new; S1 to S5 conventions, `HOME` pinned, fixtures
  built per run, staging via `tests/lib/bundle.sh`).
- AC-3, for each of the five tools in a fresh fixture: `aid add <tool> --from-bundle <staging>`;
  every `canonical/skills/<rel>` equals `.agents/skills/<rel>` byte-for-byte (and
  `.claude/skills/<rel>` for claude-code); the `aid-*` file count under `.agents/skills` equals
  `find canonical/skills -type f | wc -l`. Negative control: mutate one byte of one staged skill
  inside a copy of the shared payload (re-packed with the wrapper first and `SHA256SUMS` dropped),
  install it, and assert the byte comparison fails.
- AC-7, for each tool: every file in `.aid/runtime/{scripts,templates}/` equals its
  `canonical/aid/{scripts,templates}/` source; no `aid/` directory under `.claude`, `.codex`,
  `.cursor`, `.github` or `.agent`; pre-seeded `.aid/knowledge/x.md`, `.aid/works/w/STATE.yml` and
  `.aid/design/d.md` keep identical sha256 across `aid add`, `aid update` and `aid remove`; a stray
  file placed in `.aid/runtime/` is gone after the next `aid update`.

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-shared-install.sh --verbose` exits `0`, with a `PASS:` line per tool for the AC-3 byte comparison, the AC-3 file count, each AC-7 clause, and one for the negative control.
- [ ] Reverting the payload mutation guard (forcing the negative control to install unmutated bytes) in a scratch copy makes the negative-control assertion fail, proving the control is live.
- [ ] The suite reads no file under `.aid/works/` of this repository and leaves the real repo's `git status --porcelain` unchanged.
- [ ] All section-6 quality gates pass.
