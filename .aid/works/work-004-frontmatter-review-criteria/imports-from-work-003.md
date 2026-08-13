# Imports from work-003

Every fact drawn from `work-003` is logged here, one row, per C-7 gate 6. What crosses is a
**statement** re-authored into work-004's own tree — never a commit, cherry-pick, or file copy (gate 1).
Each row names the work-004 requirement it serves (gate 2) and where it was re-derived (gate 3).

| # | Fact imported | Serves | Re-derived from | Notes |
|---|---------------|--------|-----------------|-------|
| 1 | `work-003` sits ~131 commits ahead of `master` and is unpushed | §8 (Assumptions & Dependencies) | `git rev-list --count master..work-003` on the machine holding `work-003` | A measurement of another branch; **cannot be re-derived on this branch** (C-7 gate 3 exempts §8 itself, which exists to record the collision surface). Recorded as known collision surface, relied on for no design decision. |
| 2 | Against review-related files under `canonical/`, `work-003` **modifies 26** that also exist here | §8 (collision set) | `git diff --name-status master...work-003` | Same off-branch caveat as row 1. The 26 are the real collision set; every stream-1 target was independently re-derived from this branch in §4, not taken from here. |
| 3 | `work-003` **adds 17** review-related files that do not exist here (incl. a `review-rubrics/` catalog and `reviewer-brief-template.md`) | §8 (collision set) | `git diff --name-status master...work-003` | Same off-branch caveat. Recorded so the second-merging branch is warned of the two-catalog collision; no mechanism or file crosses (gate 4). |

**No mechanism has been imported.** Rows 1–3 are statements about a branch, admitted to serve §8's own
collision-surface accounting. If any later import is proposed, it passes all six C-7 gates or it does
not come across.
