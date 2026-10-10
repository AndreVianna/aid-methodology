# task-002: Make the canonical runtime safe to place verbatim at `.aid/runtime/`

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

**Type:** IMPLEMENT

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-5

**Depends on:** -- (none)

**Scope:**
- Apply the task-001 token mapping to `canonical/aid/**` (REQUIREMENTS.md § 11 Feature 001 ›
  Layers & Components › `canonical/aid/**`). "Comment line" for this task and for the AC-5 check
  in task-016 means: a line whose first non-blank character is `#` in a `.sh`, `.py`, `.ps1`,
  `.yml` or `.yaml` file. In every other file (markdown templates included) every line counts.
- Remove the host install-root paths (`.claude/`, `.codex/`, `.cursor/`, `.agent/`) from the
  runtime files that carry them today (find them with
  `grep -rlE '\.(claude|codex|cursor|agent)/' canonical/aid`: e.g. `templates/shortcut-catalog.yml`,
  `templates/reviewer-dispatch.md`, `templates/connectors/*.md`, `templates/rough-time-hints.md`).
  A reference that names a host tool's OWN native file (not an AID install root) is either reworded
  tool-neutrally or kept and listed in the allowlist with its reason.
- Resolve `{project_context_file}` in `canonical/aid/templates/knowledge-summary/prompt.md` to
  `AGENTS.md`, and any other filename placeholder `substitute_filenames` used to replace.
- Scripts that call a sibling runtime script must work from BOTH `canonical/aid/` (this repo, the
  test suites) and `.aid/runtime/` (an installed project): resolve siblings relative to the
  script's own directory. A line that genuinely must name a source-repo path stays as-is and is
  listed in the allowlist.
- `tests/canonical/fixtures/runtime-source-path-allowlist.tsv` (new): tab-separated columns
  `path`, `pattern`, `why`, one row per kept line, each with a non-empty `why` stating why the path
  must resolve in the AID source repo (for example the `run_generator.py` row in
  `canonical/aid/templates/rough-time-hints.md`).
- `canonical/aid/scripts/kb/build-kb-index.sh` embeds `.aid/runtime/scripts/kb/build-kb-index.sh`
  as its self-path; regenerate `.aid/knowledge/INDEX.md` with
  `bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md`
  in this same change (the CI "INDEX.md is fresh" step regenerates and diffs it).
- `canonical/aid/scripts/works/worktree-lifecycle.sh`: neutralise its comment/usage tokens, but
  leave the `_worktrees_root_from` body (its `.claude/worktrees` line) to task-011.
- The deliberate forks under `dashboard/scripts/` (e.g. `writeback-state.sh`, whose banner says
  "THIS IS A DELIBERATE FORK, NOT A RENDER") re-track any canonical line this task changes, so the
  fork-parity suites stay green.
- Update existing suites that pin old runtime strings; renamed or removed keys get rows in
  `tests/coverage-accepted-removals.tsv`.
- Out of scope: `canonical/skills/**` (task-001), `canonical/agents/**` (task-003). Do NOT run
  `run_generator.py` and do NOT commit changes under `profiles/`, `.claude/` or `.cursor/`
  (same reason as task-001).

**Acceptance Criteria:**
- [ ] `grep -rnE '(^|[^A-Za-z0-9_])canonical/(aid/)?(scripts|templates|skills|agents|recipes)/|\.(claude|codex|cursor|agent)/' canonical/aid | grep -vE '^[^:]+\.(sh|py|ps1|ya?ml):[0-9]+:[[:space:]]*#'` prints only lines matched by a row of `runtime-source-path-allowlist.tsv`, plus the single `_worktrees_root_from` line left to task-011.
- [ ] Every allowlist row has a non-empty `why`, and every row's `pattern` matches at least one line of its `path` (no stale row).
- [ ] `grep -rlE '\{(project_context_file|reviewer_output_file|open_questions_file)\}' canonical/aid | wc -l` prints `0`.
- [ ] `.aid/knowledge/INDEX.md` contains `.aid/runtime/scripts/kb/build-kb-index.sh` and no `canonical/aid/scripts/kb/build-kb-index.sh`; regenerating it to a temp file and diffing with the timestamp lines filtered (as the `.github/workflows/test.yml` step "INDEX.md is fresh" does) prints nothing.
- [ ] `bash tests/canonical/test-build-kb-index.sh`, `bash tests/canonical/test-worktree-lifecycle.sh`, `bash tests/canonical/test-writeback-state.sh` and every suite this task edited exit `0`.
- [ ] `git diff --name-only` for this task's commit lists no path under `profiles/`, `canonical/skills/`, `canonical/agents/`, `.claude/` or `.cursor/`.
- [ ] All section-6 quality gates pass.
