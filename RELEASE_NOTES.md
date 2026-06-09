# Release Notes

> Accumulates user-visible changes under `[Unreleased]`. At tag time, rename the
> section to the new version + date and start a fresh `[Unreleased]` block.

## [Unreleased]

### What's New

- **`/aid-ask` — ask the project anything (optional, read-only).** A new on-demand
  skill that answers free-form questions about the project by consulting the
  Knowledge Base, the live codebase, and in-flight AID works (`.aid/work-*/`),
  replying in the conversation with source citations (KB doc names, file paths, or
  `work-NNN` STATE). It is single-shot (no state machine), never writes any file,
  and sits outside the numbered pipeline. It dispatches `aid-researcher` for
  broad/expensive investigation and answers trivial questions inline; when the
  available context cannot answer, it states the gap instead of guessing.
  Available across all five install trees (Claude Code, Codex, Cursor, GitHub
  Copilot CLI, Antigravity).

### Technical Changes

- `aid-ask` is authored once in `canonical/skills/aid-ask/SKILL.md` and rendered
  byte-identical into all 5 install trees by the generator. Its `allowed-tools` are
  restricted to `Read, Glob, Grep, Agent` (no `Write`/`Edit`/`Bash`), giving a
  config-verifiable read-only guarantee.

### Known Issues

- The Knowledge Base's hand-written skill-count enumerations (e.g. "11 user-facing
  skills") are not yet updated for `aid-ask` (now 12). Reconcile via `/aid-housekeep`
  (KB-DELTA) before tagging — tracked as **Q30** in `.aid/knowledge/STATE.md`.
