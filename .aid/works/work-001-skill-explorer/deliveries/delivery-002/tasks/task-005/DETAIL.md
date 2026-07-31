# task-005: Skills-cluster path primitives and the strict frontmatter parser

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-005. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-005/STATE.md.
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

**Depends on:** task-004

**Scope:**
- Create `site/scripts/skills/paths.mjs`: repo-root resolution, the POSIX path builders (repo-relative strings built by **concatenation, never `path.join`**, which yields backslashes on Windows and would make the manifest platform-dependent), and the `GITHUB_BLOB_BASE` constant `https://github.com/AndreVianna/aid-methodology/blob/master` -- redeclared here, never imported from `gen-reference.mjs`, which runs `main()` at module scope.
- Create `site/scripts/skills/frontmatter.mjs`: `parseSkillFrontmatter(text, sourcePath) -> Field[]` where `Field` is `{ key, kind: 'scalar'|'list', value, line }`. This is the **sole** YAML reader in the `skills/` cluster and implements every row of feature-001's parser table.
- Conventions: ESM `.mjs`, `node:`-prefixed builtins only, kebab-case filenames, **2-space indentation** to match everything already in `site/scripts/` (feature-001's recorded divergence from `coding-standards.md`'s tab rule, which was mined from `canonical/aid/scripts/summarize/`), pure exported functions with no import-time side effect, no new dependency (`yaml` is not resolvable from `site/`).

**Acceptance Criteria:**
- [ ] Every construct in feature-001's parser table round-trips: CRLF-tolerant `^---\r?\n ... \r?\n---` fence; keys containing digits, dots and uppercase; plain, single-quoted (`''` -> `'`) and double-quoted (`\"` `\\` `\n` `\t`) scalars; an empty value kept as a field with `''`; folded `>`/`>-`/`>+` and literal `|`/`|-`/`|+` blocks with chomping respected and a blank line becoming a paragraph break; block sequences and flow sequences both yielding `kind: 'list'`.
- [ ] Blank lines and `#` comments between fields are the **only** two constructs skipped; a `#` inside a scalar value is content, not a comment.
- [ ] Duplicate key, an unclassifiable line at indent 0, and a missing or unterminated fence each **throw**, and each message names the file, the 1-based line number and the offending text.
- [ ] `Field[]` is an ordered array preserving source order -- never an object -- so no downstream renderer depends on JavaScript property ordering.
- [ ] Every path helper returns a POSIX string produced by concatenation; `path.join` appears nowhere in either module, verified by grep.
- [ ] Neither module imports anything from `site/scripts/gen-reference.mjs`, verified by grep.
- [ ] Unit tests exist for every new public function; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
