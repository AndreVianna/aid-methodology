# task-003: Document scan exclusions + scan-config.yml in the CLI reference, install help, and release ledger

[!NOTE]
This is the TASK-LEVEL DETAIL.md — the IMMUTABLE DEFINITION for this task in a flattened (Lite)
work. Written once; not a state file. This flattened work has NO per-task `STATE.md`; each task's
mutable cells live in the work-root `STATE.md § ## Delivery Lifecycle → ### Tasks lifecycle`.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** DOCUMENT

**Source:** work-022-scan-exclusions -> delivery-001

**Depends on:** task-001

**Scope:**
- Update `site/src/content/docs/reference/cli.mdx` `scan` section (~:204-225): explain that
  scan prunes a built-in set of heavy/cache/build/IDE/AI-tool/OS directories by exact
  basename (case-insensitive, any depth for Tier A; `--all` root-only for the OS/system
  Tier B), that the is-project check precedes the prune (a project whose own folder is a
  pruned name is still discovered), and document the new user-level `scan-config.yml`
  (location at the CLI state home beside `registry.yml`; `prune_dirs:` block list;
  extend-only additive merge with the built-in defaults; seeded on first run; safe to edit).
  Keep the existing flag table accurate; do not misrepresent Tier B as configurable.
- Update `docs/install.md` scan help text (~:708-712) so the `aid projects [list|add|
  remove|scan]` help blurb notes the exclusion behavior + the `scan-config.yml` knob,
  consistent with the CLI reference wording.
- Add a `## Unreleased` entry to `.aid/knowledge/release-tracking.md` (currently empty at
  ~:24): a `[CHANGE]` item describing the expanded scan prune sets and the new
  user-configurable `scan-config.yml`, following the ledger's item conventions (`[CHANGE]`
  is description-only; reference work-022).
- Keep machine-parsed markdown values plain text (no glyphs). Do NOT cite CLAUDE.md /
  AGENTS.md by line. Verify the rendered docs read correctly after editing.

**Acceptance Criteria:**
- [ ] `cli.mdx` documents the built-in Tier-A/Tier-B exclusion behavior (exact-basename,
  case-insensitive, Tier-A any-depth vs Tier-B `--all` root-only), the is-project-precedes-
  prune rule, and the `scan-config.yml` config (location, `prune_dirs:` format, extend-only
  additive merge, first-run seeding). (AC-13)
- [ ] `docs/install.md` scan help notes the exclusion behavior + `scan-config.yml`,
  consistent with `cli.mdx`. (AC-13)
- [ ] `.aid/knowledge/release-tracking.md` `## Unreleased` carries a `[CHANGE]` entry for
  the expanded prune sets + `scan-config.yml`, following the ledger conventions. (AC-13)
- [ ] Machine-parsed markdown values are plain text (no glyphs); no CLAUDE.md/AGENTS.md
  line cites; rendered docs verified. (authoring conventions)
- [ ] All section-6 quality gates pass.
