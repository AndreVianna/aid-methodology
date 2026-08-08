# {Title}

## Change Log

| Date | Change | Source |
|------|--------|--------|

## Source

- REQUIREMENTS.md {section references}

## Description

{Description from stakeholder perspective — extracted and synthesized from REQUIREMENTS.md.
Write in plain language. This is what the feature does, not how.}

## User Stories

- As a {user}, I want to {action} so that {benefit}

## Priority

{Must / Should / Could}

## Acceptance Criteria

<!-- A TABLE with a Modality column, not a checklist. `lint-modality.sh` matches `| AC-N | ... |`
     rows, so a checklist is invisible to it: a SPEC written to the old shape could never produce a
     violation, and the gate that /aid-specify runs over this file certified a property it had no way
     to observe. Modality is what step 1 of the severity scale reads -- an untagged criterion makes
     every finding against it ungradeable. `/aid-define` carries each criterion's Modality across from
     REQUIREMENTS.md into this table during decomposition. -->

| ID | Modality | Criterion |
|----|----------|-----------|
| AC-1 | MUST | Given {precondition}, when {action}, then {expected result}. |

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
