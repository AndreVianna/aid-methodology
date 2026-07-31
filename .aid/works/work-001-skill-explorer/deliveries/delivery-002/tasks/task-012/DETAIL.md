# task-012: `gen-skills.mjs` entrypoint: pipeline, manifest and drift guard

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-012. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-012/STATE.md.
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

**Depends on:** task-009, task-010

**Scope:**
- Create `site/scripts/gen-skills.mjs`: the `Purpose / Usage / Wired as / Exit codes` header block, the `#!/usr/bin/env node` shebang, and the `if (import.meta.url === pathToFileURL(process.argv[1]).href) main()` guard that follows `fetch-release-data.mjs` rather than `gen-reference.mjs`'s unconditional module-scope `main()` -- this is what makes the parser, the value renderer and the page renderer directly unit-testable, and therefore what makes AC-2 testable at fixture granularity.
- Implement the seven-step pass in fixed order: DISCOVER, PARSE, RECORD, RENDER, WRITE (`mkdir -p src/content/docs/skills/`, `writeFileSync` utf8 LF), MANIFEST, GUARD.
- Write `site/scripts/.skills-manifest.json` -- sibling of `.reference-manifest.json`, outside the content-collection root so `docsLoader()` never sees it -- with `generator`, `entries` ordered by `src` ascending, and `generatedPaths`. **No `generatedAt` and no wall-clock value anywhere.** Serialized `JSON.stringify(manifest, null, 2) + '\n'`, all paths POSIX strings built by concatenation.
- Implement the AC-1 drift guard **after** the write pass, so it also sees pages left over from a deleted skill: compare the sorted on-disk skill directories against the pages written and against the `*.md` now on disk (minus `index.md`, which feature-002 owns), throwing on either mismatch. Report only the two set differences under `missing pages:` and `orphan pages:` labels -- `gen-reference.mjs` dumps both full lists, which is unreadable at this corpus's scale.
- **The generator never deletes.** An orphan page is thrown on and named with the `git rm` remedy; auto-pruning would keep the build green and convert AC-1's loud coverage failure into exactly the silent rot the criterion exists to prevent.

**Acceptance Criteria:**
- [ ] AC-1: the guard throws when the written page set differs from the on-disk skill set, **and** when the on-disk page set does, reporting each delta sorted under `missing pages:` / `orphan pages:`.
- [ ] With a synthetic orphan page present, the generator throws and names that page, and **does not delete it**; the `git rm` remedy appears in the message.
- [ ] `index.md` is excluded from the on-disk comparison.
- [ ] The manifest carries `generator`, `entries` and `generatedPaths`, has **no `generatedAt`** and no other wall-clock value, is serialized with two-space JSON plus one trailing newline, and holds only POSIX paths built by concatenation -- `path.join` appears nowhere.
- [ ] `entries` is ordered by `src` ascending, matching the sorted directory scan.
- [ ] Exactly four stdout lines on a successful run -- start, `parsed N skills`, `wrote N pages -> src/content/docs/skills/`, `wrote scripts/.skills-manifest.json` -- each prefixed `[gen-skills] `, with **no per-page logging** and nothing on stderr.
- [ ] Every count in the output is computed from the live scan; no count literal appears in the module.
- [ ] Failures throw `[gen-skills] <guard>: <detail>` uncaught, using the stable guard names `skills drift`, `frontmatter parse`, `duplicate key`, `name mismatch`, `invalid slug`, `missing SKILL.md`. Exit code 0 on success, 1 on any guard failure; no exit code 2.
- [ ] AC-6: two consecutive runs produce byte-identical pages and a byte-identical manifest, verified by byte comparison and not by `git diff`.
- [ ] `site/scripts/gen-reference.mjs` is byte-unmodified and nothing is imported from it.
- [ ] Unit tests exist for every new public function; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
