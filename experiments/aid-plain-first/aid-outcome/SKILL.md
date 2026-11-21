---
name: aid-outcome
description: Opt-in plain-agent work with one requirements document, project knowledge and independent whole-result review.
allowed-tools: Read Glob Grep Write Edit Bash Shell Terminal Task
argument-hint: "the work to do"
hooks:
  PreToolUse:
    - matcher: "Bash|PowerShell"
      hooks:
        - type: command
          command: 'python3 "$CLAUDE_PROJECT_DIR/.aid/runtime/scripts/change/safeguard.py"'
---

# Outcome-focused work (opt-in prototype)

Use the host agent's normal execution and tools. Preserve unrelated changes, project rules and the user's approval boundaries; never push, merge or deploy without authorization. The Claude hook covers direct Git push and merge only when the host loads it. For Codex on WSL/Linux in a Git project, activate `python3 .aid/runtime/scripts/change/codex_hook_config.py install --project <git-root>` and review and trust the hook in Codex `/hooks`; if the required protection cannot be established, stop and explain. Do not overwrite existing user hook configuration. Other hosts and indirect commands are not proven protected by these declarations.

Before implementation, identify the user's goal, relevant project facts, constraints and meaningful uncertainty. Consider alternatives when a real choice exists; ask the user only when the intended result or required authorization is unclear. Read the project card and targeted KB facts if present; if the KB is absent, use existing discovery where appropriate or disclose the gap. Check current source when needed and disclose conflicts or missing knowledge. Reuse the existing KB generation and maintenance tools instead of inventing a replacement.

Keep tool output focused: locate the relevant section or command and read enough to verify it, rather than printing complete runtime scripts, unrelated KB files or broad search results. This does not replace any required session read or justify omitting needed evidence. The start-and-resume reference includes the state-writer invocation.

Maintain **one current `REQUIREMENTS.md`** for this work: goal, scope, constraints, observable outcomes, relevant facts and attributed decisions or assumptions. Scale its detail to the task. Reuse the related existing `.aid/works/<work>/REQUIREMENTS.md` and its valid active state; do not overwrite, silently adopt unrelated work or revive completed work. For a new work, follow `references/start-and-resume.md`: reuse the existing allocation gate and direct-state initializer, then create the requirements document exclusively. Before changing a requirements document, confirm it has not changed since reading; reconcile conflicts instead of overwriting them. Record user changes in the same document, preserving previous decisions. If existing sources disagree about the intended work, preserve them and ask which is authoritative.

Execute normally. Identify KB facts affected by the changes and use the existing KB maintenance process to prepare a scoped update; preserve unrelated knowledge and required user-confirmation boundaries, or disclose the unfinished update. Run appropriate checks and review your own result against the requirements and relevant project facts. Then assign a separate reviewer to inspect the actual whole result and evidence: completeness against the full agreed scope, correctness and testability, maintainability, and rendered usability where relevant. Use `references/review.md` for a compact brief and direct independent dispatch where supported. Review findings must cite evidence; use the existing reviewer ledger and `grade.sh`, without changing the existing grading scale. Address supported findings and recheck the affected evidence. Preserve and disclose unrun checks, failures and unavailable reviewers.

Trace every required outcome as verified, failed or unverified with supporting evidence and reasons. An empty ledger or a high grade is not proof that all outcomes were examined. The optional `outcome_coverage.py` check described in `references/coverage.md` validates record structure only: the reviewer must compare its outcome list with the current requirements and inspect evidence independently. If any required outcome has failed, any supported required finding remains unresolved, or required evidence or independent review is unavailable, report the result incomplete or unverified; do not claim completion. Present the result and limitations without adding an unnecessary approval pause.
