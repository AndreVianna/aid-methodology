# task-009: Skill discovery and the `SkillRecord`

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-009. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-009/STATE.md.
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

**Type:** IMPLEMENT

**Source:** work-001-skill-explorer -> delivery-002 (feature-001-skill-detail-pages)

**Depends on:** task-005

**Scope:**
- Create `site/scripts/skills/discover.mjs`: enumerate `canonical/skills/` with `readdirSync(...).sort()` (the default UTF-16 code-unit sort `gen-reference.mjs` already uses -- no `localeCompare`) and build the `SkillRecord[]` exactly as feature-001's typedef specifies: `dirName`, `sourcePath`, `route`, `destPath`, `fields`, `field(k)`, `body`, `bodyStartLine`, `lineCount`, `referencesDir`.
- Slug derivation is **identity** -- the `canonical/skills/` directory name *is* the slug. No slugification step exists, and none may be added: a lossy slugifier is how two skills silently collide onto one page.
- Per-skill guards, all throws, each naming the offending directory: missing `SKILL.md`; a directory name failing `^[a-z0-9]+(-[a-z0-9]+)*$`; frontmatter `name` not equal to the directory name.
- `bodyStartLine` and `lineCount` exist for feature-005's deep links and range verification; `referencesDir` is non-null for directories carrying a `references/` subtree and is how feature-003 reaches a fat pipeline skill's workers.
- The record carries **no `shape` field** (classification is feature-003's and must inspect the body, never the catalog's `repurpose` flag) and **no count of anything** (population sizes per shape are classifier outputs, not inputs).

**Acceptance Criteria:**
- [ ] The directory scan is `.sort()`ed with the default comparator; no `localeCompare` appears.
- [ ] Slug derivation is identity: `record.dirName`, `record.route` (`/skills/<dir>/`) and `record.destPath` are all derived from the directory name with no transformation beyond concatenation.
- [ ] A missing `SKILL.md`, a directory name failing `^[a-z0-9]+(-[a-z0-9]+)*$`, and a frontmatter `name` differing from the directory name each throw, and each message names the offending directory.
- [ ] `bodyStartLine` is the 1-based line of the first body character and `lineCount` is the total line count of `SKILL.md` -- both correct against a fixture whose frontmatter contains a multi-line folded scalar.
- [ ] `referencesDir` is non-null exactly when `canonical/skills/<dir>/references/` exists, and null otherwise.
- [ ] The emitted record has no `shape` key and no count key of any kind, verified against the typedef.
- [ ] Every path on the record is a POSIX string built by concatenation; `path.join` appears nowhere.
- [ ] Unit tests exist for every new public function and for each guard; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
