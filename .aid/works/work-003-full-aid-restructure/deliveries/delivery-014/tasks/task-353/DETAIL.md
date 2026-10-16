# task-353: Delivery-014 documentation search and reconciled rewrite list

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 353 --field State.

**Type:** RESEARCH

**Source:** feature-009-one-skill-per-need -> delivery-014 -> AC-24, AC-45

**Depends on:** --

**Scope:**
- Create `.aid/works/work-003-full-aid-restructure/research/delivery-014-sites.md`. Touch nothing else.
- Re-run these searches at this task's base commit, and record the base commit in the file
  (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, The final documentation pass; `##### 9. Testing`, DN-01 to DN-03). `test-doc-names.sh`
  comes with task-354, so the DN rules are run by hand, as the spec states them:
  - **D1** DN-01's rule without the release flag: over `docs/`, `site/src/content/` and `examples/`, and `README.md`,
    every mention of a retired slash name (as `/aid-<name>` or in backticks) and every old phase name (Discover,
    Describe, Define, Specify, Plan, Detail, Execute) written as a phase -- in a `->` or `→` sequence, or followed by
    "phase";
  - **D2** the retired names: every skill folder under `canonical/skills/` at the work's base
    (`git merge-base master HEAD`) that `canonical/skills/` no longer holds, and every family form the old -> new
    table of `.aid/knowledge/backlog.md` § Next Release names; the two lists compared, each difference named;
  - **D3** DN-03's rule without the flag: the identity search, `git grep -lIiE 'building software|software-development lifecycle|AI Integrated Software Development|methodology for software development|kind of digital work' -- . ':!.aid/works' ':!site/src/data' ':!.aid/knowledge/kb.html' ':!.aid/runtime' ':!tests' ':!**/tests/**' ':!**/__tests__/**'`, over `docs/` and `site/src/content/docs/`,
    and every file it finds without "software first, not software only";
  - **D4** each page under `site/src/content/docs/`, classed as generated (`gen-skills.mjs`, `gen-reference.mjs`),
    synced from `docs/` (`sync-docs.mjs`'s manifest) or hand-written;
  - **D5** the counted phrases `test-doc-counts.sh` asserts, with their files;
  - **D6** every link into a page or anchor the pass renames or removes.
- **Site fixtures (G11, extended).** Also search `site/scripts/__tests__/` and `site/src/lib/__tests__/` for every
  test that reads a real skill's or template's body as a fixture -- by path, or by name through `loadSkillRecord`,
  `buildFlowChart`, `liveChart` or the like (`git grep -nE "'aid-[a-z-]+'|canonical/(skills|aid/templates)/" --
  site/scripts/__tests__ site/src/lib/__tests__`). Each hit on a file this delivery rewrites, moves or deletes goes to
  the task that changes that file, which re-points the test in the same task.
- **KB `sources:` (G17).** The G6 and G2 searches also run over `.aid/knowledge/` (the frontmatter `sources:` lists): each
  `sources:` entry that cites a file this delivery deletes, moves or renames goes to the task that deletes, moves or
  renames it, which fixes the entry in the same task (AD14).
- **Site generator sources (G19).** The searches also run over `site/scripts/` outside `__tests__` for the name of every
  skill this delivery retires or renames; each hit goes to the task that retires or renames that skill.
- Give each hit exactly one owner:
  - a task of delivery-014 (task-354 to task-363; see the task files under
    `.aid/works/work-003-full-aid-restructure/tasks/task-NNN/DETAIL.md`, the layout delivery-008's migration leaves):
    task-356 (`docs/aid-methodology.md`), task-357 (`docs/faq.md`, `glossary.md`, `repository-structure.md`),
    task-364 (canonical text a generated page copies), task-358 (`docs/install.md` with the old -> new table, `release.md`, `chat-wake-install.md`,
    `diagram-content-reference.md`), task-359 (the hand-written site pages of the home page, `concepts/` and
    `get-started/`), task-360 (the hand-written site pages of `guides/`, `reference/` and `contact/`), task-361
    (`README.md` and `examples/`);
  - **a hit in a generated page is owned by its source**: the findings name, for each, the file the generator copies
    the text from (a `SKILL.md`, a reference, a template, `.aid/settings.yml`); its owner is task-364, which fixes it
    there and regenerates. "Generated page: regenerated" is never the owner of a DN-01 or DN-03 hit; a page synced from
    `docs/` follows its `docs/` source's task;
  - "installed copy (resync)";
  - "history, left as is";
  - "rendered after the resync (gate step)" for hits in `.aid/knowledge/kb.html`, `.aid/knowledge/INDEX.md` and the
    site pages generated from `.aid/settings.yml` (`reference/settings.md`) (G8).
- In a delta section, list each file assigned to two independent tasks, with the order to edit it.
- **The owner classes also include "baseline, re-recorded at the gate"** for hits in
  `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`. No task edits a baseline (Q134 D11).
- **Skill owner table (G2).** Build it from a full listing, `ls canonical/skills/*/SKILL.md`, not from
  text searches. It has one row per skill on disk at the base, naming the task of this delivery that owns
  that skill's edits, or "no change needed here" with the reason (for example "generated doorway: changes
  through the builder").
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-353.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-353`.
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
- [ ] Each of D1-D6 shows its exact command, and re-running it at the base named in the file reproduces its hits.
- [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0; D2's two lists agree or each difference has its owner.
- [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
- [ ] RESEARCH defaults are overridden as in task-001; the test step selects nothing (work folder only).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
