CONTEXT: Working directory (git worktree; stay inside it):
/tmp/claude-0/-home-user-aid-methodology/eeb5954d-f6d6-5dfd-af2e-bb9eefc66cd3/scratchpad/site-aid/project/.claude/worktrees/work-005-site-rework
`.aid/works/work-005-site-rework/REQUIREMENTS.md` section 11 holds six features; each has a `#### Technical Specification` that was just written. You review the features assigned in your prompt. This is the Specify review gate: grade each assigned Technical Specification against the requirements slice it cites (section 5 FR and section 9 AC ids), the KB and the REAL codebase.

RUBRIC: .aid/runtime/templates/grading-rubric.md. Check:
- Every path, file, function, line number, package and number it cites exists or is correct (verify read-only with Grep/Glob/Bash; do not run npm install or a build). A hallucinated artifact is HIGH.
- Concrete enough to implement without asking (exact files, signatures, data shapes, commands, expected results); vague "appropriate approach" language is MEDIUM.
- Each AC the feature owns (and each FR it implements) is actually satisfiable by the spec, with a check that can fail.
- No contradiction with the other features' specs (names of files, scripts, dependencies, ordering) or with sections 1-10; no duplicated statement of one fact.
- Consistency with KB (architecture, coding-standards, test-landscape, authoring-conventions) and repo rules in `.aid/knowledge/PROJECT.md`.
- Cycle 1 also runs the cross-document contradiction pass (Guard 2) across all six specs: `.aid/runtime/templates/reviewer-dispatch.md`, section "The cross-document contradiction pass (Guard 2)". Report contradictions between features only from your assigned side and name the other feature.
OUT OF SCOPE: KB document accuracy (log as Status: OOS rows), PLAN/task breakdown, interview process, the owner decisions listed in `.aid/works/work-005-site-rework/briefs/specify-brief.md` (do not question those decisions, only whether the spec implements them correctly).

DECLARED REVIEW CRITERIA: resolve per `.aid/runtime/templates/kb-authoring/review-rubric.md` (section "Resolving review criteria") and `.aid/knowledge/authoring-conventions.md`; a work artifact resolves to no document type (not a finding). Cite a criterion id as a prefix in the Description cell when one applies; run an `oracle:` if a criterion has one, else degrade to reading and say so.

DELIVERABLES: One ledger file per your prompt, ONE markdown table, 7 columns, no narrative, per `.aid/runtime/templates/reviewer-ledger-schema.md`; severity CRITICAL|HIGH|MEDIUM|LOW|MINOR; Status Pending (or OOS). Then run `bash .aid/runtime/scripts/grade.sh <ledger>` and return the grade, counts by severity and the one-line gist of every HIGH or CRITICAL row. Never edit REQUIREMENTS.md, specs, or STATE.yml.
