# Executor brief (every task of work-005-site-rework)

Working directory (git worktree on branch `work-005`; stay inside it; never touch the main checkout):
/tmp/claude-0/-home-user-aid-methodology/eeb5954d-f6d6-5dfd-af2e-bb9eefc66cd3/scratchpad/site-aid/project/.claude/worktrees/work-005-site-rework

You execute ONE task. Your prompt names it (`delivery-NNN`, `task-NNN`).

## 1. Read
- The task: `.aid/works/work-005-site-rework/deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` (Scope and Acceptance Criteria are binding; do exactly the Scope, nothing more).
- The requirements slice: `bash .aid/runtime/scripts/execute/slice-requirements.sh .aid/works/work-005-site-rework task-NNN` (the feature's Technical Specification it builds against, plus the AC entries it cites). The spec text holds the exact files, code blocks and checks; follow it.
- `.aid/knowledge/PROJECT.md` (rules that never bend), and via `.aid/knowledge/INDEX.md` only the KB documents the task needs (coding-standards, authoring-conventions for `.md` files you write, test-landscape). Resolve a file's review criteria in `.aid/knowledge/authoring-conventions.md` before writing it.
- `.claude/skills/aid-execute/references/task-type-rules.md` for the task's type.

## 2. State writes (MANDATORY, in this order, the moment each happens)
Use these three environment variables on every call:
`AID_STATE_FILE=.aid/works/work-005-site-rework/STATE.yml AID_WORK_DIR=.aid/works/work-005-site-rework AID_DELIVERY_ISSUES_DIR=.aid/works/work-005-site-rework`
- Before any work: `bash .aid/runtime/scripts/execute/writeback-state.sh --delivery-id DDD --task-id NNN --field State --value "In Progress"` (with the env vars in front).
- When your work and your own acceptance-criteria run are done: `--field State --value "In Review"`. Then STOP and report; the orchestrator dispatches the quick-check reviewer and writes `Done`.
- On an unresolvable problem: `--field State --value "Failed"` and write `.aid/works/work-005-site-rework/IMPEDIMENT-task-NNN.md` (type, description, options, recommendation) and report.
Run each shell command plainly (one command per call, no loops/pipes around the writeback call).

## 3. Do the work
- Edit only what the Scope names. Never edit `canonical/`, never edit generated or installed trees (`profiles/`, `.agents/`, `.claude/skills/aid-*`, `.cursor/`, `.aid/runtime/`).
- Work in `site/` with Node >= 22. `npm ci` / `npm install` (network to the npm registry) is allowed ONLY where the task says so. No other network use.
- NEVER: deploy, publish, push, tag, `npm publish`, run the docs workflow, change git config. Do not touch other deliveries' files.
- Do not invent facts. Content must be true to the repository; if a statement cannot be verified, remove or soften it and record it where the task says.
- ASCII-only for shipped `.ps1`, LF-only for `.sh` (no such files expected).

## 4. Verify
Run every Acceptance Criterion command of the task yourself (from the directory the task says). Fix until they pass. Report each criterion with the actual output (short). If a criterion cannot be satisfied as written because the task text is wrong (bad command, wrong path), do not weaken it silently: fix the work if it is yours; if the criterion itself is defective, say exactly what is wrong and what you ran instead (the orchestrator decides), and still do everything else.

## 5. Commit (local only)
Stage only the files of this task (`git add <paths>`; never `git add -A`; include the task's own `STATE.yml` only through the writeback script, which is committed with your changes). Commit with:
`GIT_AUTHOR_NAME="AID work-005" GIT_AUTHOR_EMAIL="aid-work-005@localhost" GIT_COMMITTER_NAME="AID work-005" GIT_COMMITTER_EMAIL="aid-work-005@localhost" git commit -q -m "task-NNN: <title>" -m "<one line what/why>" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>" -m "Claude-Session: https://claude.ai/code/session_01Ya4i9grwKpahn9kYnxxEYa"`
Leave the tree clean (`git status --short` empty) except for files the task says stay untracked or ignored. Never push.

## 6. Report (short)
Task id, State written, files changed (paths), each criterion with its actual result, commit hash, deviations, anything the next task needs to know.
