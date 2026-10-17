# task-356: Final pass: docs/aid-methodology.md

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 356 --field State.

**Type:** DOCUMENT

**Source:** feature-009-one-skill-per-need -> delivery-014 -> AC-45

**Depends on:** task-358

**Scope:**
- `docs/aid-methodology.md`, then `(cd site && npm run sync:docs)` for its synced page `concepts/methodology.md`.
- **The final documentation pass** (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, The final documentation pass; AC-45, Q104):
  `aid-tech-writer` rewrites the files below against the finished product -- the phases (Definition,
  Specification, Planning, Building, CI), the skills as `canonical/skills/` holds them, the action skills with their
  kinds typed or said, the KB skills, `/aid-configure` -- and states the identity the same way everywhere: AID is built for software first, not software only -- its pipeline and kind catalog leave room for other areas of work, which no shipped kind covers yet.
  - A retired skill or an old phase name appears only inside the old -> new table (task-358) or as a link to it;
    an old phase name is never written as a phase (in a `->` or `→` sequence, or followed by "phase").
  - The counted phrases `test-doc-counts.sh` asserts take the derived counts.
  - A generated site page (`gen-skills.mjs`, `gen-reference.mjs`) is regenerated, never edited by hand; a page synced
    from `docs/` changes only through `(cd site && npm run sync:docs)`.
- **KB `sources:` citations (G17).** Every `.aid/knowledge/` document whose frontmatter `sources:` cites a file or
  folder this task deletes, moves or renames is fixed in this same task (`git grep -n -e '<path>' -e '<folder>/' --
  .aid/knowledge/` at this task's base): the entry follows a moved file, and goes when the file is gone. Only the
  `sources:` entries change here; the prose stays for the delivery's DOCUMENT task. So `test-artifact-discipline.sh`
  AD14 (every `sources:` citation resolves) holds at this task's end. The KB lines are committed as the delivery
  commits KB paths (through `kb-commit.sh` once it exists, as Feature 007's BUILD requires).
- **KB edits and NEXT's KB check (Feature 007 § 2, step 7; Feature 004).** This task edits no KB document. Its commits
  may touch files that KB documents cite in their `sources:`, so NEXT's KB check after it may make a `CALL` to
  `/aid-kb-update`, which edits and commits the drifted documents itself and records a `KB change` entry `Assumed`.
  This task leaves that to the call; the delivery's KB DOCUMENT task then runs on the KB the call left (its own KB
  block).
- Links into `docs/install.md` use the headings and anchors task-358 left; this task writes no anchor into that file.
- **Site regeneration (G1, G5).** When this task adds, deletes, renames or edits anything under
  `canonical/skills/`, `canonical/agents/` or `canonical/aid/templates/`, it runs
  `(cd site && npm run gen:skills && npm run gen:reference)` in this same task and commits the output:
  the skill pages, `skills/index.md`, `src/data/skill-flows/`, `reference/skills.md`,
  `reference/agents.md` and `scripts/.skills-manifest.json`.
  - It also updates any hard-coded count or name list in a site generator, for example the agent count
    in `site/scripts/gen-reference.mjs`, so the generators' drift checks pass at this task's end.
  - A generated site page is never edited by hand.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-014-sites.md` (written, reviewed and committed before
  the run starts, Q139) assigns to `task-356`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-356.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`.
     - **Work-folder-only rule.** A task whose changes all lie under `.aid/works/` runs no suite: steps 2-5
       are skipped, and the report says so. The work folder is transient pipeline state that no suite may
       depend on, and it is not resync-relevant (PLAN.md § "Testing before the resync"). `select-suites.sh`
       is not the reason and is not run for it: it selects every suite with no `# COVERS:` header, whatever
       changed.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-356`.
       That includes the copy's own `run_generator.py`, run from inside it, then the `resync` commit.
     - Delete from `"$S"/tests/canonical/` every `test-*.sh` not in `COPY`.
     - Run `(cd "$S" && HOME="$(mktemp -d)" bash tests/run-all.sh)` and record its failures.
     - Run `rm -rf "$S"` before step 4.
     - If the copy's generator fails, that failure is the result, and `COPY` is reported as not run.
  4. **Live half.**
     - When `LIVE` is every suite outside `COPY`, run `HOME="$(mktemp -d)" bash tests/run-all.sh` and
       drop the `COPY` suites' results by name.
     - Otherwise, run each `LIVE` suite with `HOME="$(mktemp -d)" bash tests/canonical/<suite>`.
  5. **Outside `run-all.sh`.**
     - Run `(cd site && npm test)` when this task changes anything under `canonical/skills/`,
       `canonical/agents/` or `canonical/aid/templates/`, or under `docs/` or `site/` (G5). Run `npm ci`
       there first if `site/node_modules` is absent.
     - Run `python3 -m pytest <file>` for each dashboard Python test file this task changes, and
       `node --test <file>` for each dashboard `.mjs` test file it changes.
  6. **Report.** For each suite, report where it ran, its result and its run count.
     - Ceiling (T5): one full run of steps 2-5 per test round. Between rounds, re-run only the failing
       group (T6).
     - The same failure after three fix rounds is a real blocker (`/aid-execute` TEST,
       `references/blocker.md`).

**Acceptance Criteria:**
- [ ] Run without the release flag, `test-doc-names.sh -v`, where the test step puts it (the scratch copy: its text matches the driver's pattern `P`), lists no DN-01 or DN-03 hit in the files this task owns; `test-doc-counts.sh` passes live, and the site `npm test` passes after `sync:docs` and regeneration.
- [ ] Each statement about a skill, a phase or a file matches `canonical/` as the work leaves it (accuracy verified against the current tree).
- [ ] Over `.aid/knowledge/`, no frontmatter `sources:` entry cites a path this task deletes, moves or renames, and `test-artifact-discipline.sh` AD14 passes where the test step puts the suite (G17).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
