# task-028: Re-key the dogfood byte-identity suite to the shared layout

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-18

**Depends on:** task-027

**Scope:**
- `tests/canonical/test-dogfood-byte-identity.sh`, re-keyed per REQUIREMENTS.md § 11 Feature 001 ›
  Test plan (AC-18 row):
  - canonical <-> installed: every `canonical/skills/<rel>` equals `.agents/skills/<rel>` and
    `.claude/skills/<rel>`; `canonical/aid/` equals `.aid/runtime/` (excluding `host.conf`);
  - agents: `.claude/agents/aid-*` and `.cursor/agents/aid-*` equal their profile emission-manifest
    rows;
  - the manifest records the shared entries (`shared.skills`, `shared.runtime`, `shared.agents_md`,
    `shared.claude_md`, the `.claude/skills` mirror);
  - root context: the repo-root `CLAUDE.md` AID region holds only `@AGENTS.md` and its
    `## Project` section is present; `AGENTS.md` has exactly one `<!-- AID:BEGIN -->` line;
  - absences: `.claude/aid/`, `.cursor/aid/`, `.cursor/skills/aid-*`;
  - survivors: `.claude/skills/generate-profile/SKILL.md`, `.claude/skills/release-aid/SKILL.md`
    (the Direction-3 allowlists keep their role for hand-authored repo-local content).
- The `.cursor/` skills/runtime tuple keys that no longer exist get rows in
  `tests/coverage-accepted-removals.tsv`.
- A negative control: on a scratch copy, one changed byte in `.agents/skills/aid-ask/SKILL.md` makes
  the canonical comparison fail.

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-dogfood-byte-identity.sh --verbose` exits `0`, with `PASS:` lines for each comparison, the manifest shared-entry check, the root-context checks, each absence and each survivor.
- [ ] The negative control prints a `PASS:` line asserting the planted byte was detected.
- [ ] The coverage-parity gate (run where `pwsh`, `node` and `python3` are on PATH) reports no un-excused removal for this suite.
- [ ] All section-6 quality gates pass.
