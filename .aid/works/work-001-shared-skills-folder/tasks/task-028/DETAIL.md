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
    `.claude/skills/<rel>`; `canonical/aid/` equals `.aid/runtime/` under the payload exclusions
    (dot-files, `node_modules/`, `.git/`), including `rules.md`, and `.aid/runtime/host.conf` exists
    holding exactly `worktree_root=.claude/worktrees` and is the only other file under
    `.aid/runtime/` (AC-18);
  - agents: `.claude/agents/aid-*` and `.cursor/agents/aid-*` equal the agent files of the
    regenerated `profiles/claude-code/` and `profiles/cursor/` trees;
  - the manifest records the shared entries (`shared.skills`, `shared.runtime`, `shared.agents_md`,
    `shared.claude_md`, the `.claude/skills` mirror);
  - root context: the repo-root `CLAUDE.md` AID region holds only `@AGENTS.md` and its
    `## Project` section is present; `AGENTS.md` has exactly one `<!-- AID:BEGIN -->` line;
  - absences: `.claude/aid/`, `.cursor/aid/`, `.cursor/skills/aid-*`;
  - survivors: `.claude/skills/generate-profile/SKILL.md`, `.claude/skills/release-aid/SKILL.md`
    (the Direction-3 allowlists keep their role for hand-authored repo-local content).
- `tests/canonical/test-work-state-template.sh`: WS07 (reads `.claude/aid/templates/work-state-template.yml`)
  and WS08 (reads the rendered profile copies, which no longer exist) are re-pointed to the installed
  runtime copy `.aid/runtime/templates/work-state-template.yml`.
- The `.cursor/` skills/runtime tuple keys that no longer exist get rows in
  `tests/coverage-accepted-removals.tsv`.
- Negative controls: on a scratch copy, one changed byte in `.agents/skills/aid-ask/SKILL.md`
  makes the canonical comparison fail, and deleting `.aid/runtime/host.conf` makes the runtime
  check fail.
- Deferred review note (definition-gate ledger row 22): Tree-walk equality checks against `canonical/aid/` must apply the payload exclusions (dot-files, `node_modules/`, `.git/`), since CI runs `npm ci` inside `canonical/aid/scripts/summarize/`.

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-dogfood-byte-identity.sh --verbose` exits `0`, with `PASS:` lines for each comparison, the manifest shared-entry check, the root-context checks, each absence and each survivor.
- [ ] `bash tests/canonical/test-work-state-template.sh` exits `0` with `grep -c '\.claude/aid/' tests/canonical/test-work-state-template.sh` printing `0`.
- [ ] The negative controls print `PASS:` lines asserting the planted byte and the missing `host.conf` were detected.
- [ ] The coverage-parity gate (run where `pwsh`, `node` and `python3` are on PATH) reports no un-excused removal for this suite.
- [ ] All section-6 quality gates pass.
