# Handling Outcomes During Discussion

Reference material for the specify skill — how to handle exceptional situations
that arise during the propose→discuss→write→review loop.

## KB is Wrong or Incomplete

**Simple fix:** Fix the KB document directly, note in the `qa` sequence (STATE.yml).

**Needs re-discovery:** Add Q&A entry to `.aid/knowledge/STATE.md` `## Q&A (Pending)`,
note the loopback in the Features State view (work STATE.yml), continue with non-blocked sections.

## Requirements are Wrong or Incomplete

**Simple fix:** Fix REQUIREMENTS.md directly — both the upstream section and the feature's own §11 subsection live there.

**Needs re-interview:** Add Q&A entry to the `qa` sequence (`.aid/works/{work}/STATE.yml`),
note the loopback in the Features State view (work STATE.yml).

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
