# task-015: Index generation steps and the manifest index row in `gen-skills.mjs`

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-015. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-015/STATE.md.
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

**Source:** work-001-skill-explorer -> delivery-002 (feature-002-grouped-skill-index)

**Depends on:** task-012, task-014

**Scope:**
- Edit `site/scripts/gen-skills.mjs` -- feature-001's entrypoint, edited here by sanction of its own Manifest contract ("Feature-002 adds its index page as one more `entries` row in this same manifest, produced by this same generator run") -- adding four steps and the manifest row. **Feature-001's seven steps and their relative order are untouched; this task changes the order of none of them.**
- Step **3a CATALOG**: read `canonical/aid/templates/shortcut-catalog.yml` through `catalog.mjs` (task-008), placed after RECORD only because nothing earlier needs it.
- Step **4a ASSIGN**: `assignGroups(records, catalog)` (task-011), which must follow RECORD because it needs every record's `route` and `description`, and must precede 5a.
- Step **5a INDEX**: render and write `src/content/docs/skills/index.md` through `render-index.mjs` (task-014).
- Step **7a CARDS**: the `dead card` guard -- every card target must be among the pages just written -- run inside the same guard phase as step 7, after both writes, so it also catches an index referencing a page a later step failed to produce.
- Manifest: insert the index row **into sorted position, not appended**, with `src` = `canonical/skills/*/SKILL.md, canonical/aid/templates/shortcut-catalog.yml` (byte-identical to the string `gen-reference.mjs`:447 already writes for its own two-input page, and to the index page's own `generatedFrom`), and rebuild `generatedPaths` from `entries` in the same order.
- This task **must not run concurrently with task-012**: both own `site/scripts/gen-skills.mjs`.

**Acceptance Criteria:**
- [ ] Feature-001's seven steps appear in their original relative order; steps 3a, 4a, 5a and 7a are inserted between them and reorder nothing.
- [ ] The index row's `src` string is byte-identical to `gen-reference.mjs`:447's two-source string and to the index page's own `generatedFrom` value -- one string, three places.
- [ ] `entries` remains ascending by `src` **literally** after insertion (the index row lands first among the `canonical/skills/...` rows because `*` sorts before any lowercase letter), and the ordering is a pure string comparison that holds identically on every platform.
- [ ] `generatedPaths` is rebuilt from `entries` in the same order and includes `site/src/content/docs/skills/index.md`.
- [ ] The `dead card` guard throws `[gen-skills] dead card: <detail>` when a card target is absent from the page set just written, naming the offending card.
- [ ] The manifest still has **no `generatedAt`**, no wall-clock value, and only POSIX paths built by concatenation.
- [ ] stdout is still **exactly four lines** per successful run -- this task adds none -- and stderr is still silent on success.
- [ ] Two consecutive runs leave `index.md` and the manifest byte-identical.
- [ ] Feature-001's drift guard still excludes `index.md` from its on-disk comparison, and AC-1 still throws in both directions.
- [ ] Unit tests exist for each new step and for the `dead card` guard; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
