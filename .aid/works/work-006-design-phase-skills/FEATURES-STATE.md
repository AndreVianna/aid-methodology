# Features State (preserved from STATE.md at the STATE.yml conversion)

**Why this file exists.** The state format moved from `STATE.md` to `STATE.yml`, and the
new schema has **no `features` key** -- per-feature state is a purely DERIVED view,
assembled at read time from `features/{feature}/SPEC.md`. The table below carried data that
is **not** derivable from those SPECs: the per-feature spec **grade history**, the Q&A
counts, and the review notes. The converter's DERIVED-data guard correctly refused to drop
it, so it is preserved here verbatim and the state file's section was left empty for the
generated view to fill.

Transient work-folder bookkeeping: pruned when the work ships, and no permanent artifact
depends on it.

## Per-feature spec state at the time of conversion

| # | Feature | Spec State | Spec Grade | Q&A Count | Notes |
|---|---------|------------|------------|-----------|-------|
| 1 | feature-001-kb-doc-set-restructure | Ready | E → E → E+ → r5 closed | 2 | r5: 18 Fixed, 1 Invalid (reviewer evidence refuted on disk). `release-tracking.md` registration restored; AC-9 moved to a surface adopters receive |
| 2 | feature-002-design-lifecycle-machinery | Ready | E+ → E → D → r5 closed | 0 | 17/17 Fixed. Two surviving statements of the old create-rule swept; AC-11/G3 stop denying the real build; 15 citations corrected |
| 3 | feature-003-planning-artifact-skills | Ready | r1 → r2 closed | 0 | 21/21 Fixed. ACs 5 → 12; all 40 cross-spec cites converted to section anchors; doc_set presence corrected to `required` per CC-1 |
| 4 | feature-004-foundation-artifact-skills | Ready | r1 → r2 closed | 1 | 26/26 Fixed. CC-3 propagated; fabricated feature-001 quote deleted; a 4th content collision found and assigned |
| 5 | feature-005-design-grid-and-brainstorm | Ready | r1 closed | 0 | 21/21 Fixed. Unpaired-artifact rule deleted per CC-8; derivation pinned to the pre-work catalog; 15 SKILL.md bodies now specified |
| 6 | feature-006-integration-and-close-out | Ready | r1 closed | 0 | 23/23 Fixed. Card count 15 → 22; count-guard procedure rebuilt on a 36-occurrence replay; **`coverage-baseline.tsv` +144 rows found — would have broken CI** |

## The contradiction this table recorded

The work-level template declares `## Features State` DERIVED and never written directly,
while `aid-specify`'s State Detection reads Feature State rows from that table and its
`state-initialize.md` Step 3 instructs writing them there. Skill and template disagreed.
Rows were written so feature state was tracked at all, and the contradiction was logged as
a backlog item rather than silently resolved. The conversion does not resolve it either --
it preserves the evidence and leaves the disagreement standing.
