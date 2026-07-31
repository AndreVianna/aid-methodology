# task-001: Source-derived roster checks and the drift clamp in `gen-reference.test.mjs`

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-001. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-001/STATE.md.
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

**Type:** TEST

**Source:** work-001-skill-explorer -> delivery-001 (feature-001-skill-detail-pages)

**Depends on:** -- (none)

**Scope:**
- Replace all eight stale roster items at `site/scripts/__tests__/gen-reference.test.mjs`:101-141 with checks re-derived from `canonical/skills/` and `canonical/aid/templates/shortcut-catalog.yml`: the `CURATED_SKILL_NAMES` constant (18 names -> the 21 the generator curates, adding `aid-read-ticket`, `aid-create-ticket`, `aid-update-ticket`), both `it` titles (`:119`, `:135`), both comments (`:138-139` and the constant's), the three numeric assertions (`:123`, `:126`, `:132`) and the `**Total**` regex (`:140`).
- Add the local ~10-line catalog reader mirroring `gen-reference.mjs`'s row opener `/^  - name:\s*(.+)$/` (`:102`), field line `/^    ([a-zA-Z_]+):\s*(.*)$/` (`:111`) and `stripYamlScalar` (`:120-125`) -- **re-implemented, never imported**, because `gen-reference.mjs` runs `main()` at module scope and importing from it would regenerate the other generator's four pages and manifest.
- **Distinguish the replacements from the genuinely new checks -- there are four of the former and two of the latter, and conflating them produces a duplicate assertion.** Per feature-001's Part A table, three of the four numeric items are *replaced in place*, not supplemented: **`:123` becomes** `expect(catalogNames.filter((n) => !skillDirs.includes(n))).toEqual([])` (every catalog row has a directory on disk); **`:126` becomes** `expect(shortcutDirs.slice().sort()).toEqual(catalogNames.filter((n) => !CURATED_SKILL_NAMES.includes(n)).slice().sort())` (set equality in both directions, no count); **`:140`'s regex** keeps its shape with the count becoming `emittingNames.length`; and **`:132` is left unchanged**, since it becomes correct for free once the constant is corrected. Do not add a second "every catalog row has a directory" check alongside the `:123` replacement -- it *is* that replacement.
- **Then add the two genuinely new assertions**, which replace nothing: `expect(CURATED_SKILL_NAMES.filter((n) => !skillDirs.includes(n))).toEqual([])` (no curated name has lost its directory), and **the clamp**: `expect(skillDirs.filter((d) => !catalogNames.includes(d) && !CURATED_SKILL_NAMES.includes(d))).toEqual([])`.
- Tighten `:137`'s `toContain('## Direct-entry shortcuts')` to `'### Direct-entry shortcuts'`, removing a false positive one line above an assertion already being edited.
- `site/scripts/gen-reference.mjs` is byte-unmodified by this task; only the test file is touched.

**Acceptance Criteria:**
- [ ] No assertion, `it` title or comment in the roster region carries a corpus or catalog count literal; every expectation is computed from the `canonical/skills/` directory listing and `shortcut-catalog.yml` on each run.
- [ ] `CURATED_SKILL_NAMES` holds all 21 names `SKILL_GROUPS` curates, including `aid-read-ticket`, `aid-create-ticket` and `aid-update-ticket`.
- [ ] The roster region contains **exactly four** derived checks — one per row of feature-001's Part A replacement table, with no duplicate — and all four hold: every catalog row has a directory on disk; non-curated directories equal non-curated catalog names by set equality; every curated name has a directory; the `**Total**` regex interpolates `emittingNames.length`. A fifth, redundant check fails this criterion.
- [ ] **The clamp fails by name.** With an on-disk skill directory present that is neither a catalog row nor in the curated roster, the suite fails and the failure message names that directory -- demonstrated against the three ticket skills.
- [ ] `npx vitest run scripts/__tests__/gen-reference.test.mjs` exits 0, excluding only the two `git diff`-based idempotency failures delivery-001's BLUEPRINT records as environmental.
- [ ] `git diff --stat -- site/scripts/gen-reference.mjs` is empty; the four `site/src/content/docs/reference/*.md` pages and `site/scripts/.reference-manifest.json` are byte-unchanged.
- [ ] Tests are deterministic, build their own expectations from source, use clean setup/teardown, and read nothing under `.aid/works/`.
- [ ] Feature-001's build-integration criterion clause (b) is covered: the file carries no hard-coded corpus count.
- [ ] All section-6 quality gates pass
