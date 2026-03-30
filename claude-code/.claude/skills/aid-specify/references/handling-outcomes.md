# Handling Outcomes During Discussion

Reference material for the specify skill — how to handle exceptional situations
that arise during the propose→discuss→write→review loop.

## KB is Wrong or Incomplete

**Simple fix:** Fix the KB document directly, note in STATE.md Change Log.

**Needs re-discovery:** Add Q&A entry to `.aid/knowledge/DISCOVERY-STATE.md`,
add Loopback entry to STATE.md, continue with non-blocked sections.

## Requirements are Wrong or Incomplete

**Simple fix:** Fix REQUIREMENTS.md and SPEC.md directly, add Change Log entries.

**Needs re-interview:** Add Q&A entry to `.aid/{work}/INTERVIEW-STATE.md`,
add Loopback entry to STATE.md.

## Spike Needed (State 3)

1. Update STATE.md: `**Status:** Spike Needed` with What/Why/Scope/Blocked Sections
2. Print spike details and exit

On return: read spike results, record in SPEC.md, resume loop.

## Blocked (State 4)

Check each Pending loopback. If resolved → unblock, resume loop. If still blocked → exit.

## Feature Split

Create new feature folder(s), redistribute SPEC.md content, add Change Log entries, continue.

## Feature Merge

Merge content into target, delete current folder, exit.
