# aid-ask

- **Work:** work-001-aid-ask
- **Created:** 2026-06-09
- **Source:** /aid-interview lite path — LITE-FEATURE
- **Status:** Ready

## Goal

aid-ask is an optional, on-demand, **read-only** AID skill that answers a user's
free-form question about the project. It grounds its answer in three context
sources — the Knowledge Base (`.aid/knowledge/`), the live codebase, and the
current state of in-flight AID works (`.aid/work-*/STATE.md` and their progress)
— and replies in the conversation. It is a quick "ask the project anything"
helper: no work folder, no STATE.md, no pipeline phase. Read-only is a hard rule:
the skill never creates, edits, or deletes any file.

## Context

**Scope:**

- **Canonical source:** a new `canonical/skills/aid-ask/SKILL.md` authored in the
  thin-router pattern, modeled on the optional on-demand skill `aid-housekeep`
  (no README; the generator auto-discovers skills via `iterdir()` over
  `canonical/skills/`, so creating the directory IS the registration — there is no
  per-skill profile entry to wire).
- **Read-only tool surface (config-verifiable):** aid-ask's own `allowed-tools`
  grant `Read, Glob, Grep, Agent` and **omit `Write`, `Edit`, and `Bash`**, so the
  skill itself cannot modify or shell-write any file — verifiable by inspecting the
  SKILL.md frontmatter. Any shell-level or deep investigation is delegated to the
  dispatched `aid-researcher`, whose prompt explicitly instructs it to operate
  strictly read-only (return analysis as its message; write nothing).
- **Not a numbered pipeline phase** — it is an optional, on-demand skill outside the
  Discover→Execute→Deploy flow. No work folder, no STATE.md, no artifacts written.
- **Single-shot, no state machine** — `/aid-ask <question>` reads context and replies
  in one pass. No multi-state orchestration.
- **Agent:** dispatches `aid-researcher` (the read-only analytical reader that already
  reads code/docs/KB) for broad/expensive investigation. Trivial questions may be
  answered inline (Read/Glob/Grep only).
- **Hygiene:** regenerate all install trees with the FULL generator and pass the
  render-drift + KB-hygiene CI gates after authoring.

**KB references:**

- `architecture.md` — Thin-Router SKILL.md pattern, the 6-phase skill map (aid-ask is
  outside it, like the optional Deliver skills), the canonical→5-tree render pipeline,
  and the Opus/Sonnet/Haiku agent-tier model.
- `coding-standards.md` — SKILL.md frontmatter shape and AGENT.md authoring pattern to
  follow when authoring the new skill.
- `project-structure.md` — where canonical skills live and how install trees are laid out.

## Acceptance Criteria

- [ ] Given a project with a populated KB and/or in-flight works, when the user runs `/aid-ask <question>`, then aid-ask returns an answer grounded in the KB, the codebase, and work state — with source citations (KB doc names, file paths, or `work-NNN` STATE) — and modifies no files.
- [ ] Given a question the available context cannot answer, when aid-ask responds, then it explicitly states the gap rather than fabricating an answer.
- [ ] Given the aid-ask SKILL.md, its `allowed-tools` grant `Read, Glob, Grep, Agent` and omit `Write`/`Edit`/`Bash` (config-verifiable by frontmatter inspection), the SKILL.md instructs the dispatched `aid-researcher` to operate strictly read-only, and running `/aid-ask` leaves the git working tree unchanged (no created/modified/deleted files).
- [ ] Given the skill is authored, when the FULL generator runs, then `/aid-ask` is present and byte-identical across all 5 install trees and passes the render-drift + KB-hygiene CI gates.
- [ ] Given a broad/expensive question, when aid-ask needs deep investigation, then it dispatches `aid-researcher`; trivial questions may be answered inline.
- [ ] All applicable CI gates pass: render-drift, canonical-tests, generator-selftests, and kb-hygiene (the jobs in `.github/workflows/test.yml`).

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Author aid-ask skill and render to all install trees |

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-06-09 | Initial lite-path SPEC created | /aid-interview LITE-FEATURE |
