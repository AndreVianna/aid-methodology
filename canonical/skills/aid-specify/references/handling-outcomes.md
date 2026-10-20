# Handling Outcomes During Discussion

Reference material for the specify skill — how to handle exceptional situations
that arise during the propose→discuss→write→review loop.

## KB is Wrong or Incomplete

**Simple fix:** Fix the KB document directly, note it in the work's `qa` with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --category Knowledge --impact Low --context '<the fix>' --suggested '<the fix made>' --asked-by aid-specify`, then record it with `--answer --id Q<n> --state Assumed --value '<the fix made>'`.

**Needs re-discovery:** Record the question in the work's `qa` with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --category Knowledge --impact <High|Medium|Low> --context '<the gap>' --suggested '<the recommendation>' --asked-by aid-specify`, ask it through the question protocol, and record the reply with `--answer --id Q<n> --state Answered --value '<the reply>'`;
note the loopback in this feature's `features:` entry (work STATE.yml), continue with non-blocked sections.

## Requirements are Wrong or Incomplete

**Simple fix:** Fix REQUIREMENTS.md directly — both the upstream section and the feature's own §11 subsection live there.

**Needs a requirements answer:** Record the question in the work's `qa` with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --category Requirements --impact <High|Medium|Low> --context '<the gap>' --suggested '<the recommendation>' --asked-by aid-specify`, ask it through the question protocol, and record the reply with `--answer --id Q<n> --state Answered --value '<the reply>'`;
note the loopback in this feature's `features:` entry (work STATE.yml).

## Spike Needed (State 3)

1. Update STATE.yml: `state: Spike Needed` with What/Why/Scope/Blocked Sections
2. Print spike details and exit

On return: read spike results, record in the feature's `#### Technical Specification`, resume loop.

## Blocked (State 4)

Check each Pending loopback. If resolved → unblock, resume loop. If still blocked → exit.

## Feature Split

Add new `### Feature NNN` subsection(s) to §11, redistribute the content between them, continue.

## Feature Merge

Merge content into target, delete current folder, exit.
