# task-016: Source-invariant suite for neutral skills, runtime and generator output

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

**Type:** TEST

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-1, AC-4, AC-5, AC-6

**Depends on:** task-001, task-002, task-003, task-005, task-011

**Scope:**
- `tests/canonical/test-shared-layout-sources.sh` (new; follows the suite conventions S1 to S5 of
  `.aid/knowledge/test-landscape.md`, sources `tests/lib/assert.sh`, pins `HOME`, builds its own
  fixtures, never reads a work folder). One keyed assertion per clause:
  - AC-1: run `python .claude/skills/generate-profile/scripts/run_generator.py` in a throwaway
    clone (as `test-release.sh` clones), assert it prints `VERIFY (deterministic): PASS`, a stray
    file planted beforehand in the generated part of a
    `profiles/<tool>/` tree (everything except its hand-kept `README.md`) is gone and the tree holds
    only the agents and `aid-tool.conf`, no `.jsonl` manifest exists, and
    `find profiles -type d \( -name skills -o -name aid \)` is empty.
  - AC-4: the five greps of REQUIREMENTS.md § 9 AC-4, each expecting `0`.
  - AC-5: the non-comment-line check of task-002 over `canonical/aid/`, excusing only lines that a
    row of `tests/canonical/fixtures/runtime-source-path-allowlist.tsv` matches; every row has a
    non-empty `why`; no row is stale (each `pattern` matches at least one line of its `path`).
  - AC-6: no comma in any `allowed-tools` line; the count naming `Bash` equals the count containing
    `Bash Shell Terminal`; no `context:`/`agent:` key.
  - Rules source: `canonical/aid/rules.md` exists and holds no host path (`.claude/`, `.codex/`,
    `.cursor/`, `.github/aid/`), no `canonical/` token, no `^@` line and no AID marker line.
- Negative controls: for AC-4, AC-5 and AC-6, a fixture copy with one planted violation (a
  `canonical/aid/scripts/` token in a skill, an unlisted `.claude/` path in a runtime template, a
  comma-separated `allowed-tools`) makes the corresponding check fail.
- The AC-19 doc grep is NOT in this suite; task-031 owns it after the docs land.
- `tests/canonical/test-kb-scanner-scope.sh`: assert that the install-tree skip lists of
  `build-project-index.sh` and `harvest-coined-terms.sh` contain `.agents` (change made in task-002),
  keyed per script.
- Deferred review note (definition-gate ledger row 37): Add a test for the `.agents` entry in the install-tree skip lists of `build-project-index.sh` and `harvest-coined-terms.sh`, in `tests/canonical/test-kb-scanner-scope.sh`.
- Deferred review note (definition-gate ledger row 9): AC-5 test design: see the task-002 note for the same row (anchored pattern, per-file-type comment rules, sized allowlist).

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-shared-layout-sources.sh --verbose` exits `0` and prints one `PASS:` line per clause listed in Scope (AC-1, each AC-4 grep, AC-5 check, allowlist `why`, allowlist staleness, each AC-6 clause, rules source).
- [ ] `bash tests/canonical/test-kb-scanner-scope.sh` exits `0` and prints one `PASS:` line per script for the `.agents` skip-list entry; removing `.agents` from either skip list in a scratch copy makes it exit non-zero.
- [ ] Each negative control prints a `PASS:` line asserting that the planted violation was detected.
- [ ] Removing the `why` of one allowlist row in a scratch copy makes the suite exit non-zero.
- [ ] The suite contains no path under `.aid/works/` (`grep -c '\.aid/works' tests/canonical/test-shared-layout-sources.sh` prints `0`).
- [ ] All section-6 quality gates pass.
