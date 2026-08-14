# Handling Outcomes During Discussion

Reference material for the specify skill — how to handle exceptional situations
that arise during the propose→discuss→write→review loop.

## KB is Wrong or Incomplete

**Simple fix:** Fix the KB document directly, note in the `qa` sequence (STATE.yml).

**Needs re-discovery:** Add Q&A entry to `.aid/knowledge/STATE.md` `## Q&A (Pending)`,
note the loopback in the Features State view (work STATE.yml), continue with non-blocked sections.

## Requirements are Wrong or Incomplete

**Simple fix:** Fix REQUIREMENTS.md and SPEC.md directly, add Change Log entries.

**Needs re-interview:** Add Q&A entry to the `qa` sequence (`.aid/works/{work}/STATE.yml`),
note the loopback in the Features State view (work STATE.yml).

## Spike Needed (State 3)

1. Update STATE.yml: `state: Spike Needed` with What/Why/Scope/Blocked Sections
2. Print spike details and exit

On return: read spike results, record in SPEC.md, resume loop.

## Blocked (State 4)

Check each Pending loopback. If resolved → unblock, resume loop. If still blocked → exit.

## Feature Split

Create new feature folder(s), redistribute SPEC.md content, add Change Log entries, continue.

## Feature Merge

Merge content into target, delete current folder, exit.
