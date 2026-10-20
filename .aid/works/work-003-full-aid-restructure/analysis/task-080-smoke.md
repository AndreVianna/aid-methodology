# task-080 smoke run

One run each, `python3 tests/conversation/run.py --feature 002 --sample <id> --runs 1`, in a scratch copy
made from `5f3d5e00` (`task-080: In Progress`) after the copy's own `run_generator.py`, so the agent ran on the
delivery-003 skills. All ten failed. The samples were not re-run after the fixes: the 3-of-3 runs are the gate's.

| Sample | Failed checks | Judge rows | Sample defects fixed | Product defects |
|---|---|---|---|---|
| 002-01 | -- | 2 | EO-1 read the proposal rule too strictly | No question form; record written after the reply |
| 002-02 | -- | 3 | The answer sheet held no description answer | No question form, reason or recommendation; no groups by importance; no break offered |
| 002-03 | `contains .aid/STATE.yml state: Skipped` | 3 | The skip and follow-up used questions aid-config never asks | No question form; two questions in one message |
| 002-04 | -- | 3 | `answered_by` is `--` when the session has no git name, as the protocol says | No "Why I ask" |
| 002-14 | `tool-not-called Edit`, `tool-not-called Write` | 2 | Both whole-run checks matched the writes made after the user's choice | First message held no reading or question; two questions at once |
| 002-15 | -- | 3 | The simulated user named the tracker before being asked | -- |
| 002-16 | `tool-called Skill aid-research` | 4 | The run ended at the proposal, before the skill ran | Two questions in one message, no recommendation |
| 002-17 | `tool-called Skill aid-review`, `tool-not-called Bash *pr*review*` | -- | The glob matched `project ... review-pending` | The review ran and wrote a file before the user agreed, without the skill |
| 002-18 | `tool-called Read *usage-events.csv*` | 2 | The read is made by the dispatched helper; the skill's own verify cycles were judged as resolving | -- |
| 002-19 | `tool-called Skill aid-monitor` | 2 | The run ended at the proposal; the "earlier finding" question needs a finding on record | Did not stop on the proposal; listed needs instead of one question |

The common product defect: the agent does not use the question protocol's form (the subject and importance
line, "Why I ask", "My recommendation", one question at a time). The skills carry the protocol line, but the
form is not applied. It is raised for the delivery review.

Review follow-ups: 002-16's intake exception is held to the opening question again (the fix had widened it to
scoping questions, which would hide a product defect), and 002-13 names `aid-update-kb`.
