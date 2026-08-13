# task-006: Rename code-half — emitters, twin, parser, test-suites, render.py

> **Execution protocol:** whoever executes this task writes its `State` at every
> transition (`In Progress` at start, `In Review` before the reviewer, terminal
> `Done`/`Failed` at end) in this task's `STATE.md`. Binds the main agent executing
> directly, not only a dispatched sub-agent.

**Type:** IMPLEMENT

**Source:** work-004-frontmatter-review-criteria -> delivery-001

**Depends on:** task-002

**Scope:**
- Emitters that write the field — `build-kb-index.sh`, `build-relationships.sh`, `build-metrics.sh`,
  `build-connectors-index.sh` **and its PowerShell twin `build-connectors-index.ps1`**: emit
  `review-criteria:`; keep the two connector twins byte-parallel.
- Parser — `canonical/aid/scripts/migrate/migrate-kb-frontmatter.sh` (`/^contracts:/`): accept both
  names during the coexistence window.
- The 2 script test-suites — `tests/canonical/test-build-connectors-index.sh`,
  `tests/canonical/test-migrate-kb-frontmatter.sh`: update expected strings to the new key.
- `.claude/skills/generate-profile/scripts/render.py`: carry `review-criteria:` through the agent
  frontmatter rebuild (`new_fm`), so a canonical `AGENT.md` block is not silently dropped at render.
- **No on-disk data rename of the 22/18 KB docs or the 4 fixtures** — that is delivery-002.

**Acceptance Criteria:**
- [ ] All 5 emitters (incl. the `.ps1` twin) emit `review-criteria:`; connector twins stay byte-parallel.
- [ ] The migration parser accepts both `contracts:` and `review-criteria:`.
- [ ] `test-build-connectors-index.sh` and `test-migrate-kb-frontmatter.sh` pass against the new key.
- [ ] `render.py` carries `review-criteria` into the rebuilt agent frontmatter (verified by unit or a
      dry-run of the rebuild, not by running the full render — render is delivery-003).
- [ ] No KB doc or fixture data is renamed here. All §6 quality gates pass.
