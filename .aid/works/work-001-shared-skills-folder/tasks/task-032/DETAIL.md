# task-032: Manual cross-tool probe of the `Bash Shell Terminal` alias list

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-20

**Depends on:** task-031

**Scope:**
- One manual check only (REQUIREMENTS.md § 9 AC-20, § 8 A-4): `allowed-tools: ... Bash Shell Terminal ...`
  is accepted by every host -- unknown names are ignored without error, and Claude Code still
  pre-approves `Bash` in default mode. No other assumption is probed: A-1 is verified, A-2 is
  verified for discovery and accepted for execution, A-3 is settled by the Claude Code
  documentation and the always-import `CLAUDE.md` design, A-5 by its adopted fallback.
- The executing agent prepares the probe kit; a human maintainer runs it, because it needs the
  host IDEs and their accounts:
  - a scratch repo installed with `aid add claude-code,codex,cursor,copilot-cli,antigravity
    --from-bundle <staging>` from `bash release.sh --stage-only --out <staging>`;
  - per host, the steps of the § 8 probe method: invoke one shell-using skill (e.g. `/aid-ask` or
    another skill whose `allowed-tools` lists `Bash Shell Terminal`), and record whether the skill
    loads without a frontmatter error, whether it runs, and, for Claude Code in default mode,
    whether its shell call is pre-approved without a permission prompt.
- Record the result as one `lifecycle_history` entry in this work's `STATE.yml` (event, date,
  pass/fail, per-host notes), written through the work-state writer the pipeline uses.
- If A-4 fails: do not mark this task Done. Raise the § 8 A-4 fallback (the SPEC revisits the alias
  list; per-tool remapping does not return) as a Q&A entry in this work's `STATE.yml` `qa:` list,
  so a follow-up task implements it with an added criterion before the work is marked Done.

**Acceptance Criteria:**
- [ ] This work's `STATE.yml` `lifecycle_history` holds one entry for the A-4 probe naming each of the five hosts with a pass or fail and the Claude Code default-mode pre-approval result.
- [ ] The probe kit (staging directory command, install command, per-host steps) is recorded in that entry's `notes` or in the hand-off, so the probe is repeatable.
- [ ] If any host fails, a `qa:` entry in `STATE.yml` names the failure and the § 8 A-4 fallback, and this task ends `Failed`, not `Done`.
- [ ] All section-6 quality gates pass.
