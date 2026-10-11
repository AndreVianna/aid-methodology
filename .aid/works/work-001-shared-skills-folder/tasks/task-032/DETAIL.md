# task-032: Manual cross-tool probes of A-4 aliases and A-6 rules pointer

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
- Own BOTH manual probes in REQUIREMENTS.md § 9 AC-20 for each required host: A-4 alias acceptance (`allowed-tools: ... Bash Shell Terminal ...`, including Claude Code default-mode `Bash` pre-approval) and A-6 pointer loading via a unique token in `.aid/runtime/rules.md`. Record each as pass, fail or unknown; unknown is never treated as pass. No other assumption is probed: A-1 is verified, A-2 is
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
- If A-4 fails, record the § 8 alias fallback as a Q&A and require its added criterion. If A-6 fails for a host, activate the existing `rules_inline` mechanism, add a host-specific criterion, and re-run affected generation/install checks plus task-031 final regression before acceptance. Unknown or inaccessible hosts remain unknown/blocked under existing criteria; record them without inventing success.

**Acceptance Criteria:**
- [ ] This work's `STATE.yml` `lifecycle_history` holds one entry for the A-4 and A-6 probe results for each required host, each recorded as pass/fail/unknown, including Claude Code default-mode pre-approval.
- [ ] The probe kit (staging directory command, install command, per-host steps) is recorded in that entry's `notes` or in the hand-off, so the probe is repeatable.
- [ ] Confirmed A-6 failure records and activates host-specific `rules_inline`, adds the criterion, and repeats affected checks and task-031 final gates; unknown stays unknown and never silently passes.
- [ ] All section-6 quality gates pass.
