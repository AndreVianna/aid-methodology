# Rename aid-interview to aid-define

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-27 | Feature identified from REQUIREMENTS.md §5 FR-6, §6 NFR-6, §8 D-3, §9 AC-8, §10 P3 | /aid-interview |

## Source

- REQUIREMENTS.md §5 FR-6, §6 NFR-6, §8 D-3, §9 AC-8, §10 P3

## Description

The name aid-interview describes the method (interviewing) rather than the outcome (defining the
work). This feature renames the skill to a clearer name (current lean: /aid-define) with full
cross-tree propagation, following the same pattern work-001 used for aid-ask → aid-query-kb:
render the renamed skill to the 5 host trees, orphan-prune the old skill directory, update the
install manifests, update the skill-name reference surfaces (a rename leaves the skill count
unchanged), and update the docs site. The rename must stay byte-identical across the 5 host trees
(DBI) per the established render and propagation rules, and CI must stay green. **Sequencing:** this
feature must land AFTER the content features (002/003/004), which edit the skill directory in place —
a directory rename collides with concurrent content-edits.

## User Stories

- As an AID adopter, I want the skill named for what it produces (defining the work) so that its
  purpose is obvious from the command name.
- As an AID maintainer, I want the rename propagated byte-identically across all 5 host trees with
  the old directory orphan-pruned and manifests, skill-count surfaces, and docs site updated so
  that no channel ships a stale or broken reference.

## Priority

Should

## Acceptance Criteria

- [ ] Given the rename, when it ships, then the skill is renamed with byte-identical propagation
  across the 5 trees, the old directory is orphan-pruned, and the install manifests, skill-count
  surfaces, and docs site are updated. *(AC-8)*
- [ ] Given the renamed skill, when CI runs, then CI is green. *(AC-8, NFR-6)*

---

## Technical Specification

{Added by /aid-specify — do not fill during interview.}
