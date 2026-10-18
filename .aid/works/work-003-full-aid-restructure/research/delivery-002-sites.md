# Delivery-002 site search and reconciled edit list

This file is the output of task-020 (RESEARCH) of delivery-002. It re-runs the searches of PLAN.md's delivery-002 stanza, wave 1, and of REQUIREMENTS.md § 11 Feature 002 `##### 8. Testing`, gives every hit exactly one owner, and reconciles the result with the task files task-021 to task-057. It changes no other file.

## Base commit and conventions

- **Base commit:** `06d32a1ba63e1c8810e16978165e5581034f4c87` (the `task-020: In Progress` commit on branch `work-003`, HEAD at the time of the run). `git status --short` was empty at the base, so every command below, run from the repository root, reads the same bytes as the commit.
- **Owner classes** (the four allowed by task-020): a task of delivery-002 (task-021 to task-057), `installed copy (resync)`, `history, left as is`, `baseline, re-recorded at the gate`. Where a hit lies in a file that no task edits and that the spec leaves unchanged, the owner is `history, left as is`; see the Delta, item D9.
- **Owner of a skill file** is the task whose Scope or group names that skill (the skill owner table below); a skill with no hit and no sweep convention is `no change needed here`.
- **Row counts.** P1, P2, P3, P4 and P7 print one row per hit line. P5 prints one row per file (its line numbers are listed in the row), because 406 lines would repeat the same owner. P8 prints one row per (edit-list token or skill, suite, owner), with the number of matching lines. G11 prints one row per (site test, target, owner).
- **Branch movement during the run.** Other commits landed on `work-003` while this task ran (`06d32a1b..HEAD` holds 9 commits, ending at `faaa956c`). So the searches pass the base commit as the tree argument (`git grep ... 06d32a1b -- <paths>`), not the working tree. P1 to P9 were also re-run at the base and match the working-tree output line for line. Of the tracked paths the searches cover, only `tests/canonical/test-conversation-runner.sh` and `tests/conversation/run.py` differ from the base, and no search term matches them except three token lines and nine skill-name lines in the first, which the base-tree run already reports.
- **This file's commit.** Commit `21263602` ("work-003: Q154 ...", a commit this task did not make, landed while this task was still running) already holds an earlier version of this file, and it is listed as tracked. The version in the working tree is the final one. Nothing was committed by this task.
- **Test step.** Every change in this task lies under `.aid/works/`. Per the work-folder-only rule, no suite runs for it; `select-suites.sh` is not run; no `run_generator.py` runs. Scratch files are in `/tmp/claude-0/-home-user-aid-methodology/cd2e209b-dbef-5f81-874a-fdeb1e92d87f/scratchpad/t020/`.

## Contents

- P1 SS-11 phase names
- P2 SS-14 (b) record writes
- P3 SS-14 (d) continuation lines
- P4 SS-12 hand-written finish
- P5 SS-03 advance words and PAUSE-FOR-USER
- P6 SS-02 Dispatch tables and State sections
- P7 NM-01 to NM-04
- P8 Q106 map (suites that read edit-list files)
- P9 suites that feed old names or assert phase output
- P10 writer atomicity
- Site fixtures (G11)
- KB sources (G17)
- Site generator sources (G19)
- Baselines
- Installed copies (resync)
- Skill owner table (G2)
- Suites on two tasks and the run order
- Delta

## P1 SS-11 phase names

Forms of SS-11 over its scope (tracked files under `canonical/skills/`, `canonical/aid/templates/`, `canonical/aid/scripts/` except `summarize/`, `dashboard/home.html`, `dashboard/reader/*.py`, `dashboard/server/*.mjs`, `dashboard/server/*.py`, `dashboard/scripts/writeback-state.sh`; never a `tests/` or `__tests__/` folder). Command (script `p1.sh` in the scratch folder, reproduced here):

```bash
# P1 (SS-11 forms, SS-11 scope; run from the repo root). Prints file:line:text.
OLD='(Describe|Define|Specify|Plan|Detail|Execute)'
SCOPE=(':(glob)canonical/skills/**' ':(glob)canonical/aid/templates/**' ':(glob)canonical/aid/scripts/**' ':(exclude)canonical/aid/scripts/summarize/**' 'dashboard/home.html' ':(glob)dashboard/reader/*.py' ':(glob)dashboard/server/*.mjs' ':(glob)dashboard/server/*.py' 'dashboard/scripts/writeback-state.sh')
{
git grep -n -E -e "phase: $OLD\b" -e "--field Phase --value $OLD\b" -e "['\"]$OLD['\"]" -e "$OLD \| $OLD\b" -e "Phase\.$OLD\b" -e "=== '$OLD'" -- "${SCOPE[@]}"
git grep -n -i -E -e "phase.*\`$OLD\`" -e "\`$OLD\`.*phase" -- "${SCOPE[@]}"
} | sort -t: -k1,1 -k2,2n -u
```

Hits: **55** lines (the spec states 55). The `legacy-phase-map: begin` / `end` markers do not exist yet, so no line is excluded by them. Table-header rows such as `\| State \| Detail \| Worker \| Advance \|` and prose like "Migration Plan" match a single old word and are not SS-11 forms, so they are not rows. The deploy sentence "it stays at `Execute`" (`canonical/skills/aid-deploy/references/state-idle.md:26`) is split over two lines and is not reachable by these forms; it is listed in the Delta.

| # | Location | Form | Text | Owner |
|---|---|---|---|---|
| 1 | `canonical/aid/scripts/execute/writeback-state.sh:1749` | enum list | `#   Phase:          Describe \| Define \| Specify \| Plan \| Detail \| Execute` | task-025 |
| 2 | `canonical/aid/scripts/execute/writeback-state.sh:1802` | enum list | `*) die "invalid Phase value '$FIELD_VALUE'; must be one of: Describe \| Define \| Specify \| Plan \| Detail \| Execut...` | task-025 |
| 3 | `canonical/aid/templates/shortcut-engine.md:334` | phase: <old> | `phase: Describe` | task-037 |
| 4 | `canonical/aid/templates/shortcut-engine.md:494` | --field Phase --value <old> | `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Phase --value Specify` | task-037 |
| 5 | `canonical/aid/templates/shortcut-engine.md:571` | --field Phase --value <old> | ``--field Phase --value Plan`.` | task-037 |
| 6 | `canonical/aid/templates/shortcut-engine.md:623` | --field Phase --value <old> | ``--field Phase --value Detail`.` | task-037 |
| 7 | `canonical/aid/templates/shortcut-engine.md:724` | enum list | ``writeback-state.sh`'s `Phase` enum (`Describe \| Define \| Specify \| Plan \|` | task-037 |
| 8 | `canonical/aid/templates/shortcut-engine.md:725` | enum list | `Detail \| Execute`) has no `Gate` value -- `Phase` stays `Detail`` | task-037 |
| 9 | `canonical/aid/templates/work-initiation-gate.md:138` | phase: <old> | `\| Mid-Execute or beyond (`phase: Execute`, or `delivery_state` is `Executing`/`Gated`/`Done`) \| `/aid-execute <work...` | task-030 |
| 10 | `canonical/aid/templates/work-initiation-gate.md:139` | backticked <old> on a phase line | `\| Partial full-path work still in a definition phase -- route to the skill matching `STATE.yml` `phase` \| `Describe...` | task-030 |
| 11 | `canonical/aid/templates/work-initiation-gate.md:143` | backticked <old> on a phase line | ``aid-describe`, when the chosen work's `phase` is `Describe` -- the gate hands` | task-030 |
| 12 | `canonical/aid/templates/work-state-template.yml:118` | enum list | `# [W] Describe \| Define \| Specify \| Plan \| Detail \| Execute` | task-021 |
| 13 | `canonical/aid/templates/work-state-template.yml:119` | phase: <old> | `phase: Describe` | task-021 |
| 14 | `canonical/skills/aid-define/references/state-feature-decomposition.md:8` | --field Phase --value <old> | `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Phase --value Define` | task-039 |
| 15 | `canonical/skills/aid-describe/references/state-first-run.md:38` | phase: <old> | `phase: Describe` | task-038 |
| 16 | `canonical/skills/aid-detail/references/first-run.md:16` | --field Phase --value <old> | `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Phase --value Detail` | task-040 |
| 17 | `canonical/skills/aid-execute/references/state-execute.md:734` | --field Phase --value <old> | `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Phase --value Execute` | task-040 |
| 18 | `canonical/skills/aid-orchestrate/SKILL.md:47` | backticked <old> on a phase line | `investigation, when nothing was to land), set `phase` to `Execute` and `lifecycle` to` | task-032 |
| 19 | `canonical/skills/aid-orchestrate/references/size-and-route.md:50` | --field Phase --value <old> | `AID_STATE_FILE=<work>/STATE.yml AID_WORK_DIR=<work> bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline -...` | task-032 |
| 20 | `canonical/skills/aid-plan/references/first-run-loop.md:12` | --field Phase --value <old> | `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Phase --value Plan` | task-040 |
| 21 | `canonical/skills/aid-specify/references/state-continue.md:8` | --field Phase --value <old> | `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Phase --value Specify` | task-039 |
| 22 | `canonical/skills/aid-specify/references/state-initialize.md:103` | --field Phase --value <old> | `bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Phase --value Specify` | task-039 |
| 23 | `dashboard/home.html:1131` | quoted <old> | `var PHASE_ORDER = ['Describe', 'Define', 'Specify', 'Plan', 'Detail', 'Execute'];` | task-033 |
| 24 | `dashboard/home.html:4251` | quoted <old> | `// Detail into a single "Describe" step, so the full stepper would read as` | task-033 |
| 25 | `dashboard/home.html:4316` | quoted <old> | `// APPROVAL-HALT, which halts pre-Execute) all collapse into "Describe" until` | task-033 |
| 26 | `dashboard/home.html:4320` | quoted <old> | `var LITE_STAGES = ['Describe', 'Execute', 'Done'];` | task-033 |
| 27 | `dashboard/home.html:4324` | === '<old>' | `} else if (work.phase === 'Execute') {` | task-033 |
| 28 | `dashboard/reader/models.py:44` | enum list | `Describe \| Define \| Specify \| Plan \| Detail \| Execute` | task-031 |
| 29 | `dashboard/reader/models.py:55` | quoted <old> | `Describe = "Describe"` | task-031 |
| 30 | `dashboard/reader/models.py:56` | quoted <old> | `Define = "Define"` | task-031 |
| 31 | `dashboard/reader/models.py:57` | quoted <old> | `Specify = "Specify"` | task-031 |
| 32 | `dashboard/reader/models.py:58` | quoted <old> | `Plan = "Plan"` | task-031 |
| 33 | `dashboard/reader/models.py:59` | quoted <old> | `Detail = "Detail"` | task-031 |
| 34 | `dashboard/reader/models.py:60` | quoted <old> | `Execute = "Execute"` | task-031 |
| 35 | `dashboard/reader/parsers.py:1890` | Phase.<old> | `"Describe": Phase.Describe,` | task-031 |
| 36 | `dashboard/reader/parsers.py:1891` | Phase.<old> | `"Define": Phase.Define,` | task-031 |
| 37 | `dashboard/reader/parsers.py:1892` | Phase.<old> | `"Specify": Phase.Specify,` | task-031 |
| 38 | `dashboard/reader/parsers.py:1893` | Phase.<old> | `"Plan": Phase.Plan,` | task-031 |
| 39 | `dashboard/reader/parsers.py:1894` | Phase.<old> | `"Detail": Phase.Detail,` | task-031 |
| 40 | `dashboard/reader/parsers.py:1895` | Phase.<old> | `"Execute": Phase.Execute,` | task-031 |
| 41 | `dashboard/reader/state_schema.py:122` | quoted <old> | `closed-enum field's real value is a single member ('Execute'), never a` | task-031 |
| 42 | `dashboard/scripts/writeback-state.sh:1588` | enum list | `#   Phase:          Describe \| Define \| Specify \| Plan \| Detail \| Execute \| Deploy` | task-025 |
| 43 | `dashboard/scripts/writeback-state.sh:1641` | enum list | `*) die "invalid Phase value '$FIELD_VALUE'; must be one of: Describe \| Define \| Specify \| Plan \| Detail \| Execut...` | task-025 |
| 44 | `dashboard/server/reader.mjs:80` | quoted <old> | `Describe: "Describe",` | task-031 |
| 45 | `dashboard/server/reader.mjs:81` | quoted <old> | `Define: "Define",` | task-031 |
| 46 | `dashboard/server/reader.mjs:82` | quoted <old> | `Specify: "Specify",` | task-031 |
| 47 | `dashboard/server/reader.mjs:83` | quoted <old> | `Plan: "Plan",` | task-031 |
| 48 | `dashboard/server/reader.mjs:84` | quoted <old> | `Detail: "Detail",` | task-031 |
| 49 | `dashboard/server/reader.mjs:85` | quoted <old> | `Execute: "Execute",` | task-031 |
| 50 | `dashboard/server/reader.mjs:823` | Phase.<old> | `"Describe": Phase.Describe,` | task-031 |
| 51 | `dashboard/server/reader.mjs:824` | Phase.<old> | `"Define": Phase.Define,` | task-031 |
| 52 | `dashboard/server/reader.mjs:825` | Phase.<old> | `"Specify": Phase.Specify,` | task-031 |
| 53 | `dashboard/server/reader.mjs:826` | Phase.<old> | `"Plan": Phase.Plan,` | task-031 |
| 54 | `dashboard/server/reader.mjs:827` | Phase.<old> | `"Detail": Phase.Detail,` | task-031 |
| 55 | `dashboard/server/reader.mjs:828` | Phase.<old> | `"Execute": Phase.Execute,` | task-031 |

## P2 SS-14 (b) record writes

Command (run from the repo root; the five allowed files are excluded, as SS-14 (b) says):

```bash
# P2 (SS-14 b) run from repo root; scope canonical/skills/** and canonical/aid/templates/**, minus the five allowed template/gate files
SC=(':(glob)canonical/skills/**' ':(glob)canonical/aid/templates/**')
EX=(':(exclude)canonical/aid/templates/work-state-template.yml' ':(exclude)canonical/aid/templates/project-state-template.yml' ':(exclude)canonical/aid/templates/delivery-state-template.yml' ':(exclude)canonical/aid/templates/task-state-template.yml' ':(exclude)canonical/aid/templates/work-initiation-gate.md')
git grep -n -E -e 'initiator:' -e '[Cc]opy.*work-state-template\.yml' -e 'work-state-template\.yml` to\b' -e '^(active_skill|step|step_detail|phase):' -- "${SC[@]}" "${EX[@]}"
```

Hits: **55** lines. Every hit is in a file of "Files and layout" (a converted allocation point or an exempt per-skill file): the design allocation (`design-lifecycle.md`, `shortcut-engine.md`), the seven starters, `aid-describe`'s seed, and the exempt per-skill binding lines of `aid-brainstorm`, the `aid-design-*` family and the KB `aid-create-*` / `aid-update-*` skills. Owner = the task that edits the file; for an exempt line that stays, the task named is the one that sweeps that file.

| # | Location | Text | Owner | Status of the line |
|---|---|---|---|---|
| 1 | `canonical/aid/templates/design-lifecycle.md:193` | ``pipeline.path: lite`, `initiator: aid-<verb>-<artifact>`, `lifecycle: Running`,` | task-034 | converted (allocation point / starter) |
| 2 | `canonical/aid/templates/shortcut-engine.md:307` | `Copy `.aid/runtime/templates/work-state-template.yml` to` | task-037 | converted (allocation point / starter) |
| 3 | `canonical/aid/templates/shortcut-engine.md:329` | `initiator: {name}` | task-037 | converted (allocation point / starter) |
| 4 | `canonical/aid/templates/shortcut-engine.md:334` | `phase: Describe` | task-037 | converted (allocation point / starter) |
| 5 | `canonical/aid/templates/shortcut-engine.md:335` | `active_skill: {name}` | task-037 | converted (allocation point / starter) |
| 6 | `canonical/skills/aid-brainstorm/SKILL.md:44` | ``initiator: aid-brainstorm`. `phase` is not driven. The `work-NNN` folder is where` | task-034 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 7 | `canonical/skills/aid-create-architecture/SKILL.md:43` | ``initiator: aid-create-architecture`. `phase` is not driven.` | task-036 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 8 | `canonical/skills/aid-create-backlog/SKILL.md:38` | `Initiation Gate, then `initiator: aid-create-backlog`, `active_skill:` | task-036 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 9 | `canonical/skills/aid-create-cicd/SKILL.md:45` | ``initiator: aid-create-cicd`. `phase` is not driven.` | task-036 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 10 | `canonical/skills/aid-create-document/SKILL.md:59` | `else enter the resolved path), **then** allocate (`pipeline.path: lite`, `initiator:` | task-044 | converted (allocation point / starter) |
| 11 | `canonical/skills/aid-create-mvp/SKILL.md:49` | `Work Initiation Gate, then `initiator: aid-create-mvp`, `active_skill:` | task-036 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 12 | `canonical/skills/aid-create-roadmap/SKILL.md:43` | `Initiation Gate, then `initiator: aid-create-roadmap`, `active_skill:` | task-036 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 13 | `canonical/skills/aid-create-stack/SKILL.md:43` | ``initiator: aid-create-stack`. `phase` is not driven.` | task-036 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 14 | `canonical/skills/aid-create-testing-strategy/SKILL.md:43` | ``initiator: aid-create-testing-strategy`. `phase` is not driven.` | task-036 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 15 | `canonical/skills/aid-describe/references/state-first-run.md:15` | `Copy from `../../../aid/templates/work-state-template.yml` if the file does not yet exist.` | task-038 | converted (allocation point / starter) |
| 16 | `canonical/skills/aid-describe/references/state-first-run.md:33` | `initiator: aid-describe` | task-038 | converted (allocation point / starter) |
| 17 | `canonical/skills/aid-describe/references/state-first-run.md:38` | `phase: Describe` | task-038 | converted (allocation point / starter) |
| 18 | `canonical/skills/aid-describe/references/state-first-run.md:39` | `active_skill: aid-describe` | task-038 | converted (allocation point / starter) |
| 19 | `canonical/skills/aid-design-api/SKILL.md:40` | ``initiator: aid-design-api`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 20 | `canonical/skills/aid-design-architecture/SKILL.md:45` | ``initiator: aid-design-architecture`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 21 | `canonical/skills/aid-design-backlog/SKILL.md:47` | `Initiation Gate, then `initiator: aid-design-backlog`, `active_skill:` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 22 | `canonical/skills/aid-design-cicd/SKILL.md:46` | ``initiator: aid-design-cicd`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 23 | `canonical/skills/aid-design-cli/SKILL.md:40` | ``initiator: aid-design-cli`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 24 | `canonical/skills/aid-design-config/SKILL.md:45` | ``initiator: aid-design-config`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 25 | `canonical/skills/aid-design-dashboard/SKILL.md:41` | ``initiator: aid-design-dashboard`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 26 | `canonical/skills/aid-design-data-model/SKILL.md:43` | ``initiator: aid-design-data-model`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 27 | `canonical/skills/aid-design-data-pipeline/SKILL.md:40` | ``initiator: aid-design-data-pipeline`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 28 | `canonical/skills/aid-design-document/SKILL.md:44` | ``initiator: aid-design-document`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 29 | `canonical/skills/aid-design-infra/SKILL.md:45` | ``initiator: aid-design-infra`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 30 | `canonical/skills/aid-design-integration/SKILL.md:42` | ``initiator: aid-design-integration`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 31 | `canonical/skills/aid-design-job/SKILL.md:41` | ``initiator: aid-design-job`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 32 | `canonical/skills/aid-design-messaging/SKILL.md:41` | ``initiator: aid-design-messaging`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 33 | `canonical/skills/aid-design-mvp/SKILL.md:44` | `Initiation Gate, then `initiator: aid-design-mvp`, `active_skill: aid-design-mvp`,` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 34 | `canonical/skills/aid-design-roadmap/SKILL.md:45` | `Initiation Gate, then `initiator: aid-design-roadmap`, `active_skill:` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 35 | `canonical/skills/aid-design-stack/SKILL.md:46` | ``initiator: aid-design-stack`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 36 | `canonical/skills/aid-design-test/SKILL.md:44` | ``initiator: aid-design-test`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 37 | `canonical/skills/aid-design-testing-strategy/SKILL.md:45` | ``initiator: aid-design-testing-strategy`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 38 | `canonical/skills/aid-design-theme/SKILL.md:40` | ``initiator: aid-design-theme`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 39 | `canonical/skills/aid-design-ui/SKILL.md:45` | ``initiator: aid-design-ui`. `phase` is not driven.` | task-035 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 40 | `canonical/skills/aid-design/SKILL.md:52` | `else enter the resolved path), **then** allocate (`pipeline.path: lite`, `initiator:` | task-034 | converted (allocation point / starter) |
| 41 | `canonical/skills/aid-prototype/SKILL.md:43` | `else enter the resolved path), **then** allocate (`pipeline.path: lite`, `initiator:` | task-044 | converted (allocation point / starter) |
| 42 | `canonical/skills/aid-report/SKILL.md:45` | `else enter the resolved path), **then** allocate (`pipeline.path: lite`, `initiator:` | task-044 | converted (allocation point / starter) |
| 43 | `canonical/skills/aid-research/SKILL.md:55` | ``.aid/runtime/templates/work-state-template.yml` to` | task-044 | converted (allocation point / starter) |
| 44 | `canonical/skills/aid-research/SKILL.md:57` | ``initiator: aid-research`, `lifecycle: Running`, `active_skill: aid-research`,` | task-044 | converted (allocation point / starter) |
| 45 | `canonical/skills/aid-review/SKILL.md:101` | `the `<work-id>` resolved above). Copy `.aid/runtime/templates/work-state-template.yml` to` | task-044 | converted (allocation point / starter) |
| 46 | `canonical/skills/aid-review/SKILL.md:103` | ``pipeline.path: lite`, `initiator: aid-review`, `lifecycle: Running`, `active_skill:` | task-044 | converted (allocation point / starter) |
| 47 | `canonical/skills/aid-test/SKILL.md:48` | `else enter the resolved path), **then** allocate (`pipeline.path: lite`, `initiator:` | task-044 | converted (allocation point / starter) |
| 48 | `canonical/skills/aid-update-architecture/SKILL.md:44` | ``initiator: aid-update-architecture`. `phase` is not driven.` | task-036 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 49 | `canonical/skills/aid-update-backlog/SKILL.md:38` | `Work Initiation Gate, then `initiator: aid-update-backlog`, `active_skill:` | task-036 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 50 | `canonical/skills/aid-update-cicd/SKILL.md:47` | ``initiator: aid-update-cicd`. `phase` is not driven.` | task-036 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 51 | `canonical/skills/aid-update-document/SKILL.md:48` | `else enter the resolved path), **then** allocate (`initiator: aid-update-document`;` | task-044 | converted (allocation point / starter) |
| 52 | `canonical/skills/aid-update-mvp/SKILL.md:49` | `Initiation Gate, then `initiator: aid-update-mvp`, `active_skill: aid-update-mvp`,` | task-036 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 53 | `canonical/skills/aid-update-roadmap/SKILL.md:43` | `Initiation Gate, then `initiator: aid-update-roadmap`, `active_skill:` | task-036 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 54 | `canonical/skills/aid-update-stack/SKILL.md:44` | ``initiator: aid-update-stack`. `phase` is not driven.` | task-036 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |
| 55 | `canonical/skills/aid-update-testing-strategy/SKILL.md:44` | ``initiator: aid-update-testing-strategy`. `phase` is not driven.` | task-036 | exempt (per-skill binding line, stays; SS-14 shared exempt list) |

## P3 SS-14 (d) continuation lines

Command (run from the repo root):

```bash
# P3 (SS-14 d) run from repo root; scope canonical/skills/** and canonical/aid/templates/** minus work-initiation-gate.md
SC=(':(glob)canonical/skills/**' ':(glob)canonical/aid/templates/**' ':(exclude)canonical/aid/templates/work-initiation-gate.md')
git grep -n -E -e 'resume door' -e '`?phase`?-matched' -e '[A-Z][a-z]+-phase work' -e 'route per the chosen work' -- "${SC[@]}"
```

Hits: **14** lines in 10 files. They are the continuation lines that Files and layout names: `shortcut-engine.md` § Design Notes (lines 46 and 60) and § State: INTAKE Step 3 (lines 260 and 261), `aid-review` § Step 5 (line 85), `aid-describe` § One or more works exist (lines 167 and 169), and the `aid-research`, `aid-test`, `aid-prototype`, `aid-report`, `aid-create-document`, `aid-update-document` and `aid-design` continuation lines. Nothing else matches, so the list agrees with the spec.

| # | Location | Under | Text | Owner |
|---|---|---|---|---|
| 1 | `canonical/aid/templates/shortcut-engine.md:46` | Design Notes | `"continuation" the gate routes to the chosen work's own resume door and this engine` | task-037 |
| 2 | `canonical/aid/templates/shortcut-engine.md:60` | Design Notes | `door (`/aid-execute` for a halted shortcut work; the `phase`-matched skill for a` | task-037 |
| 3 | `canonical/aid/templates/shortcut-engine.md:260` | Step 3: Consult the Work Initiation Gate, then allocate w... | `gate routes to the chosen work's own resume door (`/aid-execute <work>` for a halted` | task-037 |
| 4 | `canonical/aid/templates/shortcut-engine.md:261` | Step 3: Consult the Work Initiation Gate, then allocate w... | `shortcut work; the `phase`-matched skill for a partial full-path work) and **this engine` | task-037 |
| 5 | `canonical/skills/aid-create-document/SKILL.md:56` | State: INTAKE | `route to the chosen work's resume door and STOP (allocate nothing); on **new work**:` | task-044 |
| 6 | `canonical/skills/aid-describe/SKILL.md:167` | One or more works exist -> ASK (never auto-continue) | `- **Continuation:** route per the chosen work's `STATE.md` `phase`/`lifecycle` (gate` | task-038 |
| 7 | `canonical/skills/aid-describe/SKILL.md:169` | One or more works exist -> ASK (never auto-continue) | `Describe-phase work), **first normalize** the chosen work's id to its bare `work-NNN`` | task-038 |
| 8 | `canonical/skills/aid-design/SKILL.md:49` | State: INTAKE | `route to the chosen work's resume door and STOP (allocate nothing); on **new work**:` | task-034 |
| 9 | `canonical/skills/aid-prototype/SKILL.md:40` | State: INTAKE | `route to the chosen work's resume door and STOP (allocate nothing); on **new work**:` | task-044 |
| 10 | `canonical/skills/aid-report/SKILL.md:42` | State: INTAKE | `route to the chosen work's resume door and STOP (allocate nothing); on **new work**:` | task-044 |
| 11 | `canonical/skills/aid-research/SKILL.md:47` | State: INTAKE | `enumerated list; on **continuation** route to the chosen work's resume door and STOP` | task-044 |
| 12 | `canonical/skills/aid-review/SKILL.md:85` | Step 5 -- allocate the work folder + STATE | `the gate routes to the chosen work's resume door and this skill **STOPs (allocates` | task-044 |
| 13 | `canonical/skills/aid-test/SKILL.md:45` | State: INTAKE | `route to the chosen work's resume door and STOP (allocate nothing); on **new work**:` | task-044 |
| 14 | `canonical/skills/aid-update-document/SKILL.md:45` | State: INTAKE | `route to the chosen work's resume door and STOP (allocate nothing); on **new work**:` | task-044 |

## P4 SS-12 hand-written finish

Command (run from the repo root):

```bash
# P4 (SS-12) run from repo root
git grep -n -E -e "lifecycle: ['\"]?(Completed|Canceled)" -- ':(glob)canonical/skills/**' ':(glob)canonical/aid/templates/**'
```

Hits: **43** lines in **43** files: 42 skill files that finish by hand plus `aid-deploy/references/state-done.md` (whose prose quotes `lifecycle: Completed`; task-043 rewords it). The seven starters switch to the writer (task-044); the KB-writing `aid-create-*` / `aid-update-*` skills, `aid-design` and the `aid-design-*` family keep their lines as exempt (SS-12 exempt list).

| # | Location | Text | Owner | Status |
|---|---|---|---|---|
| 1 | `canonical/skills/aid-brainstorm/SKILL.md:87` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-034 | exempt, stays (shared exempt list, SS-12) |
| 2 | `canonical/skills/aid-create-architecture/SKILL.md:119` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.` | task-036 | exempt, stays (shared exempt list, SS-12) |
| 3 | `canonical/skills/aid-create-backlog/SKILL.md:216` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.` | task-036 | exempt, stays (shared exempt list, SS-12) |
| 4 | `canonical/skills/aid-create-cicd/SKILL.md:122` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.` | task-036 | exempt, stays (shared exempt list, SS-12) |
| 5 | `canonical/skills/aid-create-document/SKILL.md:124` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. Keep the` | task-044 | switches to the writer (task-044) |
| 6 | `canonical/skills/aid-create-mvp/SKILL.md:151` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.` | task-036 | exempt, stays (shared exempt list, SS-12) |
| 7 | `canonical/skills/aid-create-roadmap/SKILL.md:175` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.` | task-036 | exempt, stays (shared exempt list, SS-12) |
| 8 | `canonical/skills/aid-create-stack/SKILL.md:119` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.` | task-036 | exempt, stays (shared exempt list, SS-12) |
| 9 | `canonical/skills/aid-create-testing-strategy/SKILL.md:117` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.` | task-036 | exempt, stays (shared exempt list, SS-12) |
| 10 | `canonical/skills/aid-deploy/references/state-done.md:15` | `This is the **M6 normalized-Completed emit**: it writes the authoritative `lifecycle: C...` | task-043 | prose reworded (task-043) |
| 11 | `canonical/skills/aid-design-api/SKILL.md:83` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 12 | `canonical/skills/aid-design-architecture/SKILL.md:100` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 13 | `canonical/skills/aid-design-backlog/SKILL.md:102` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 14 | `canonical/skills/aid-design-cicd/SKILL.md:99` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 15 | `canonical/skills/aid-design-cli/SKILL.md:83` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 16 | `canonical/skills/aid-design-config/SKILL.md:88` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 17 | `canonical/skills/aid-design-dashboard/SKILL.md:84` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 18 | `canonical/skills/aid-design-data-model/SKILL.md:86` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 19 | `canonical/skills/aid-design-data-pipeline/SKILL.md:83` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 20 | `canonical/skills/aid-design-document/SKILL.md:87` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 21 | `canonical/skills/aid-design-infra/SKILL.md:88` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 22 | `canonical/skills/aid-design-integration/SKILL.md:85` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 23 | `canonical/skills/aid-design-job/SKILL.md:84` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 24 | `canonical/skills/aid-design-messaging/SKILL.md:84` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 25 | `canonical/skills/aid-design-mvp/SKILL.md:95` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 26 | `canonical/skills/aid-design-roadmap/SKILL.md:97` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 27 | `canonical/skills/aid-design-stack/SKILL.md:99` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 28 | `canonical/skills/aid-design-test/SKILL.md:87` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 29 | `canonical/skills/aid-design-testing-strategy/SKILL.md:101` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 30 | `canonical/skills/aid-design-theme/SKILL.md:83` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 31 | `canonical/skills/aid-design-ui/SKILL.md:88` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. The seed` | task-035 | exempt, stays (shared exempt list, SS-12) |
| 32 | `canonical/skills/aid-design/SKILL.md:105` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. Keep` | task-034 | exempt, stays (shared exempt list, SS-12) |
| 33 | `canonical/skills/aid-prototype/SKILL.md:102` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. Keep the` | task-044 | switches to the writer (task-044) |
| 34 | `canonical/skills/aid-report/SKILL.md:111` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. Keep the` | task-044 | switches to the writer (task-044) |
| 35 | `canonical/skills/aid-research/SKILL.md:136` | `Set STATE `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. Keep` | task-044 | switches to the writer (task-044) |
| 36 | `canonical/skills/aid-review/SKILL.md:196` | `Set STATE `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.` | task-044 | switches to the writer (task-044) |
| 37 | `canonical/skills/aid-test/SKILL.md:109` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row. Leave the` | task-044 | switches to the writer (task-044) |
| 38 | `canonical/skills/aid-update-architecture/SKILL.md:100` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.` | task-036 | exempt, stays (shared exempt list, SS-12) |
| 39 | `canonical/skills/aid-update-backlog/SKILL.md:178` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.` | task-036 | exempt, stays (shared exempt list, SS-12) |
| 40 | `canonical/skills/aid-update-document/SKILL.md:98` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.` | task-044 | switches to the writer (task-044) |
| 41 | `canonical/skills/aid-update-mvp/SKILL.md:157` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.` | task-036 | exempt, stays (shared exempt list, SS-12) |
| 42 | `canonical/skills/aid-update-roadmap/SKILL.md:143` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.` | task-036 | exempt, stays (shared exempt list, SS-12) |
| 43 | `canonical/skills/aid-update-stack/SKILL.md:98` | `Set `lifecycle: Completed`, `updated` now, append a `## Lifecycle History` row.` | task-036 | exempt, stays (shared exempt list, SS-12) |

## P5 SS-03 advance words and PAUSE-FOR-USER

Command (run from the repo root; the flow-graph library is included because it parses the words):

```bash
# P5 (SS-03): every PAUSE-FOR-USER line, and every **Advance:** line (its word), in canonical/ and the site flow-graph lib
git grep -n -E 'PAUSE-FOR-USER|\*\*Advance:\*\*' -- ':(glob)canonical/**' ':(glob)site/scripts/lib/flow-graph/**'
```

Hits: **406** lines in **129** files: 54 `PAUSE-FOR-USER-ACTION` and 47 `PAUSE-FOR-USER-DECISION` mentions (a mention in prose or a table cell is counted too, as SS-03 scans the whole line), and 242 `**Advance:**` lines. A plain step name after `**Advance:**` (`CHAIN` as today: `DESIGN`, `VERIFY`, `PRESENT`, `DONE`, `UPDATE`, `REVIEW` and so on) is a CHAIN and is listed for the sweep; the rule of task (b) changes only the pause words.

| # | File | Lines | PAUSE-FOR-USER-ACTION (-> WAIT) | PAUSE-FOR-USER-DECISION (-> ASK, keeps its step) | Other `**Advance:**` words | Owner |
|---|---|---|---|---|---|---|
| 1 | `canonical/aid/templates/connectors/ticket-resolution.md` | 136 | 0 | 1 | - | task-043 |
| 2 | `canonical/aid/templates/shortcut-engine.md` | 103, 371, 473, 536, 609, 706, 713, 895, 945 | 0 | 0 | CHAIN x7, HALT x1 | task-037 |
| 3 | `canonical/aid/templates/state-machine-chaining.md` | 17, 24, 32, 41, 46, 51, 61, 69, 71, 85, 93, 105 | 4 | 3 | Stop x2 | task-050 (exempt row for SS-03; the file is removed by delivery-003, see Delta D7) |
| 4 | `canonical/skills/aid-brainstorm/SKILL.md` | 48, 62, 71, 81 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-034 |
| 5 | `canonical/skills/aid-create-architecture/SKILL.md` | 56, 94, 103, 113 | 0 | 0 | CREATE x1, VERIFY x1, PRESENT x1, DONE x1 | task-036 |
| 6 | `canonical/skills/aid-create-backlog/SKILL.md` | 51, 65, 168, 187, 197, 210 | 0 | 0 | GUARD x1, REALIZE x1, REGISTER x1, VERIFY x1, PRESENT x1, DONE x1 | task-036 |
| 7 | `canonical/skills/aid-create-cicd/SKILL.md` | 59, 97, 106, 116 | 0 | 0 | CREATE x1, VERIFY x1, PRESENT x1, DONE x1 | task-036 |
| 8 | `canonical/skills/aid-create-document/SKILL.md` | 69, 82, 96, 106, 118 | 0 | 0 | AUTHOR x1, VERIFY x1, PRESENT x1, PLACE x1, DONE x1 | task-044 |
| 9 | `canonical/skills/aid-create-mvp/SKILL.md` | 60, 75, 118, 128, 145 | 0 | 0 | GUARD x1, REALIZE x1, VERIFY x1, PRESENT x1, DONE x1 | task-036 |
| 10 | `canonical/skills/aid-create-roadmap/SKILL.md` | 54, 68, 127, 146, 156, 169 | 0 | 0 | GUARD x1, REALIZE x1, REGISTER x1, VERIFY x1, PRESENT x1, DONE x1 | task-036 |
| 11 | `canonical/skills/aid-create-stack/SKILL.md` | 55, 93, 102, 113 | 0 | 0 | CREATE x1, VERIFY x1, PRESENT x1, DONE x1 | task-036 |
| 12 | `canonical/skills/aid-create-testing-strategy/SKILL.md` | 54, 92, 101, 111 | 0 | 0 | CREATE x1, VERIFY x1, PRESENT x1, DONE x1 | task-036 |
| 13 | `canonical/skills/aid-create-ticket/SKILL.md` | 39, 101, 123, 141, 167, 173, 195, 214, 222 | 0 | 2 | - | task-043 |
| 14 | `canonical/skills/aid-define/SKILL.md` | 246 | 0 | 0 | - | task-039 |
| 15 | `canonical/skills/aid-define/references/state-cross-reference.md` | 41 | 0 | 0 | - | task-039 |
| 16 | `canonical/skills/aid-define/references/state-done.md` | 37 | 0 | 0 | - | task-039 |
| 17 | `canonical/skills/aid-define/references/state-feature-decomposition.md` | 20 | 0 | 0 | - | task-039 |
| 18 | `canonical/skills/aid-deploy/SKILL.md` | 183, 185 | 1 | 1 | - | task-043 |
| 19 | `canonical/skills/aid-deploy/references/state-done.md` | 32 | 0 | 0 | - | task-043 |
| 20 | `canonical/skills/aid-deploy/references/state-idle.md` | 34 | 0 | 0 | - | task-043 |
| 21 | `canonical/skills/aid-deploy/references/state-packaging.md` | 98 | 0 | 0 | - | task-043 |
| 22 | `canonical/skills/aid-deploy/references/state-re-run.md` | 18 | 0 | 0 | - | task-043 |
| 23 | `canonical/skills/aid-deploy/references/state-selecting.md` | 38 | 0 | 0 | - | task-043 |
| 24 | `canonical/skills/aid-deploy/references/state-verifying.md` | 52 | 0 | 0 | - | task-043 |
| 25 | `canonical/skills/aid-describe/SKILL.md` | 281, 284, 286 | 1 | 2 | - | task-038 |
| 26 | `canonical/skills/aid-describe/references/state-completion.md` | 138, 145 | 0 | 2 | - | task-038 |
| 27 | `canonical/skills/aid-describe/references/state-continue.md` | 43 | 0 | 0 | - | task-038 |
| 28 | `canonical/skills/aid-describe/references/state-first-run.md` | 108 | 0 | 0 | - | task-038 |
| 29 | `canonical/skills/aid-describe/references/state-q-and-a.md` | 64 | 0 | 0 | - | task-038 |
| 30 | `canonical/skills/aid-design-api/SKILL.md` | 45, 59, 68, 77 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 31 | `canonical/skills/aid-design-architecture/SKILL.md` | 50, 76, 85, 94 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 32 | `canonical/skills/aid-design-backlog/SKILL.md` | 57, 76, 86, 96 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 33 | `canonical/skills/aid-design-cicd/SKILL.md` | 51, 75, 84, 93 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 34 | `canonical/skills/aid-design-cli/SKILL.md` | 45, 59, 68, 77 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 35 | `canonical/skills/aid-design-config/SKILL.md` | 50, 64, 73, 82 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 36 | `canonical/skills/aid-design-dashboard/SKILL.md` | 46, 60, 69, 78 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 37 | `canonical/skills/aid-design-data-model/SKILL.md` | 48, 62, 71, 80 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 38 | `canonical/skills/aid-design-data-pipeline/SKILL.md` | 45, 59, 68, 77 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 39 | `canonical/skills/aid-design-document/SKILL.md` | 49, 63, 72, 81 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 40 | `canonical/skills/aid-design-infra/SKILL.md` | 50, 64, 73, 82 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 41 | `canonical/skills/aid-design-integration/SKILL.md` | 47, 61, 70, 79 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 42 | `canonical/skills/aid-design-job/SKILL.md` | 46, 60, 69, 78 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 43 | `canonical/skills/aid-design-messaging/SKILL.md` | 46, 60, 69, 78 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 44 | `canonical/skills/aid-design-mvp/SKILL.md` | 53, 69, 79, 89 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 45 | `canonical/skills/aid-design-roadmap/SKILL.md` | 55, 71, 81, 91 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 46 | `canonical/skills/aid-design-stack/SKILL.md` | 51, 75, 84, 93 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 47 | `canonical/skills/aid-design-test/SKILL.md` | 49, 63, 72, 81 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 48 | `canonical/skills/aid-design-testing-strategy/SKILL.md` | 50, 76, 85, 95 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 49 | `canonical/skills/aid-design-theme/SKILL.md` | 45, 59, 68, 77 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 50 | `canonical/skills/aid-design-ui/SKILL.md` | 50, 64, 73, 82 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, DONE x1 | task-035 |
| 51 | `canonical/skills/aid-design/SKILL.md` | 55, 67, 81, 90, 99 | 0 | 0 | DESIGN x1, VERIFY x1, PRESENT x1, HANDOFF x1, DONE x1 | task-034 |
| 52 | `canonical/skills/aid-detail/SKILL.md` | 92, 94 | 1 | 1 | - | task-040 |
| 53 | `canonical/skills/aid-detail/references/execution-graph-generation.md` | 87 | 0 | 0 | - | task-040 |
| 54 | `canonical/skills/aid-detail/references/first-run.md` | 128 | 0 | 0 | - | task-040 |
| 55 | `canonical/skills/aid-detail/references/review.md` | 82 | 0 | 0 | - | task-040 |
| 56 | `canonical/skills/aid-detail/references/task-decomposition.md` | 232 | 0 | 0 | - | task-040 |
| 57 | `canonical/skills/aid-discover/SKILL.md` | 21, 43, 306, 308 | 2 | 3 | - | task-041 |
| 58 | `canonical/skills/aid-discover/references/state-approval.md` | 38 | 0 | 0 | - | task-041 |
| 59 | `canonical/skills/aid-discover/references/state-closure.md` | 339, 340 | 0 | 1 | the x1 | task-041 |
| 60 | `canonical/skills/aid-discover/references/state-done.md` | 72 | 0 | 0 | - | task-041 |
| 61 | `canonical/skills/aid-discover/references/state-elicit.md` | 59, 75, 79, 141, 159, 161, 311 | 0 | 4 | Stop x2 | task-041 |
| 62 | `canonical/skills/aid-discover/references/state-fix.md` | 125 | 0 | 0 | - | task-041 |
| 63 | `canonical/skills/aid-discover/references/state-generate.md` | 186, 237, 240, 289, 430, 432, 566, 586, 591, 952, 979, 1086 | 0 | 8 | Stop x3 | task-041 |
| 64 | `canonical/skills/aid-discover/references/state-q-and-a.md` | 64 | 0 | 0 | - | task-041 |
| 65 | `canonical/skills/aid-discover/references/state-review.md` | 587 | 0 | 0 | - | task-041 |
| 66 | `canonical/skills/aid-execute/SKILL.md` | 222, 224 | 1 | 1 | - | task-040 |
| 67 | `canonical/skills/aid-execute/references/state-delivery-gate.md` | 87, 149, 240, 266, 323, 372, 483 | 0 | 0 | - | task-040 |
| 68 | `canonical/skills/aid-execute/references/state-execute.md` | 782 | 0 | 0 | - | task-040 |
| 69 | `canonical/skills/aid-execute/references/state-fix.md` | 183 | 0 | 0 | - | task-040 |
| 70 | `canonical/skills/aid-execute/references/state-re-run.md` | 22 | 0 | 1 | - | task-040 |
| 71 | `canonical/skills/aid-execute/references/state-review.md` | 183 | 0 | 0 | - | task-040 |
| 72 | `canonical/skills/aid-housekeep/SKILL.md` | 35, 229, 230, 242, 244, 250 | 5 | 0 | - | task-042 |
| 73 | `canonical/skills/aid-housekeep/references/state-cleanup.md` | 534 | 0 | 0 | - | task-042 |
| 74 | `canonical/skills/aid-housekeep/references/state-done.md` | 72 | 0 | 0 | - | task-042 |
| 75 | `canonical/skills/aid-housekeep/references/state-kb-delta.md` | 478, 799, 859, 884 | 1 | 1 | CHAIN x2, PAUSE-FOR-USER-ACTION x1 | task-042 |
| 76 | `canonical/skills/aid-housekeep/references/state-preflight.md` | 115 | 0 | 0 | - | task-042 |
| 77 | `canonical/skills/aid-housekeep/references/state-summary-delta.md` | 268, 311, 355 | 1 | 0 | - | task-042 |
| 78 | `canonical/skills/aid-monitor/SKILL.md` | 222, 224 | 1 | 1 | - | task-043 |
| 79 | `canonical/skills/aid-monitor/references/state-classify.md` | 45 | 0 | 0 | - | task-043 |
| 80 | `canonical/skills/aid-monitor/references/state-observe.md` | 34 | 0 | 0 | - | task-043 |
| 81 | `canonical/skills/aid-monitor/references/state-route.md` | 60 | 0 | 0 | - | task-043 |
| 82 | `canonical/skills/aid-plan/SKILL.md` | 154, 156 | 1 | 1 | - | task-040 |
| 83 | `canonical/skills/aid-plan/references/first-run-loop.md` | 231 | 0 | 0 | - | task-040 |
| 84 | `canonical/skills/aid-plan/references/review-deliverables.md` | 79 | 0 | 0 | - | task-040 |
| 85 | `canonical/skills/aid-prototype/SKILL.md` | 50, 63, 76, 86, 96 | 0 | 0 | BUILD x1, VERIFY x1, PRESENT x1, HANDOFF x1, DONE x1 | task-044 |
| 86 | `canonical/skills/aid-read-ticket/SKILL.md` | 69, 94, 109 | 0 | 0 | CHAIN x3 | task-043 |
| 87 | `canonical/skills/aid-report/SKILL.md` | 49, 68, 84, 94, 105 | 0 | 0 | ANALYZE x1, VERIFY x1, PRESENT x1, HANDOFF x1, DONE x1 | task-044 |
| 88 | `canonical/skills/aid-research/SKILL.md` | 61, 85, 107, 118, 130 | 0 | 0 | INVESTIGATE x1, VERIFY x1, PRESENT x1, HANDOFF x1, DONE x1 | task-044 |
| 89 | `canonical/skills/aid-review/SKILL.md` | 109, 134, 158, 175, 190 | 0 | 0 | REVIEW x1, VERIFY x1, PRESENT-FINDINGS x1, PUBLISH x1, DONE x1 | task-044 |
| 90 | `canonical/skills/aid-specify/SKILL.md` | 224, 226 | 1 | 1 | - | task-039 |
| 91 | `canonical/skills/aid-specify/references/state-blocked.md` | 16 | 1 | 0 | - | task-039 |
| 92 | `canonical/skills/aid-specify/references/state-continue.md` | 114 | 0 | 0 | - | task-039 |
| 93 | `canonical/skills/aid-specify/references/state-done.md` | 19 | 0 | 0 | - | task-039 |
| 94 | `canonical/skills/aid-specify/references/state-initialize.md` | 143 | 0 | 0 | - | task-039 |
| 95 | `canonical/skills/aid-specify/references/state-review.md` | 90 | 0 | 0 | - | task-039 |
| 96 | `canonical/skills/aid-specify/references/state-spike.md` | 19 | 1 | 0 | - | task-039 |
| 97 | `canonical/skills/aid-summarize/SKILL.md` | 184, 186 | 1 | 1 | - | task-042 |
| 98 | `canonical/skills/aid-summarize/references/state-approval.md` | 53 | 0 | 0 | If x1 | task-042 |
| 99 | `canonical/skills/aid-summarize/references/state-done.md` | 44 | 0 | 0 | - | task-042 |
| 100 | `canonical/skills/aid-summarize/references/state-fix.md` | 38 | 0 | 0 | - | task-042 |
| 101 | `canonical/skills/aid-summarize/references/state-generate.md` | 377 | 0 | 0 | - | task-042 |
| 102 | `canonical/skills/aid-summarize/references/state-manual-checklist.md` | 39 | 0 | 0 | - | task-042 |
| 103 | `canonical/skills/aid-summarize/references/state-preflight.md` | 23 | 0 | 0 | - | task-042 |
| 104 | `canonical/skills/aid-summarize/references/state-profile.md` | 162 | 0 | 0 | - | task-042 |
| 105 | `canonical/skills/aid-summarize/references/state-stale-check.md` | 32 | 0 | 0 | - | task-042 |
| 106 | `canonical/skills/aid-summarize/references/state-validate.md` | 62 | 0 | 0 | - | task-042 |
| 107 | `canonical/skills/aid-summarize/references/state-writeback.md` | 32 | 0 | 0 | - | task-042 |
| 108 | `canonical/skills/aid-test/SKILL.md` | 53, 69, 84, 94, 103 | 0 | 0 | RUN x1, VERIFY x1, PRESENT x1, HANDOFF x1, DONE x1 | task-044 |
| 109 | `canonical/skills/aid-update-architecture/SKILL.md` | 60, 76, 85, 94 | 0 | 0 | UPDATE x1, VERIFY x1, PRESENT x1, DONE x1 | task-036 |
| 110 | `canonical/skills/aid-update-backlog/SKILL.md` | 55, 71, 147, 157, 172 | 0 | 0 | GUARD x1, UPDATE x1, VERIFY x1, PRESENT x1, DONE x1 | task-036 |
| 111 | `canonical/skills/aid-update-cicd/SKILL.md` | 64, 80, 89, 99 | 0 | 0 | UPDATE x1, VERIFY x1, PRESENT x1, DONE x1 | task-036 |
| 112 | `canonical/skills/aid-update-document/SKILL.md` | 54, 64, 74, 83, 92 | 0 | 0 | AUTHOR x1, VERIFY x1, PRESENT x1, WRITE x1, DONE x1 | task-044 |
| 113 | `canonical/skills/aid-update-kb/SKILL.md` | 54, 272, 446, 448, 450, 451, 461, 508, 512, 518 | 8 | 0 | CHAIN x1 | task-042 |
| 114 | `canonical/skills/aid-update-kb/references/state-analyze.md` | 238, 262 | 1 | 0 | CHAIN x1 | task-042 |
| 115 | `canonical/skills/aid-update-kb/references/state-apply.md` | 311 | 0 | 0 | CHAIN x1 | task-042 |
| 116 | `canonical/skills/aid-update-kb/references/state-approval.md` | 91, 153 | 1 | 0 | CHAIN x1, PAUSE-FOR-USER-ACTION x1 | task-042 |
| 117 | `canonical/skills/aid-update-kb/references/state-confirm.md` | 9, 96, 135, 155 | 2 | 0 | CHAIN x1, PAUSE-FOR-USER-ACTION x1, HALT x1 | task-042 |
| 118 | `canonical/skills/aid-update-kb/references/state-done.md` | 99, 238 | 1 | 0 | PAUSE-FOR-USER-ACTION x1, HALT x1 | task-042 |
| 119 | `canonical/skills/aid-update-kb/references/state-review.md` | 243, 284, 331, 360, 414 | 1 | 0 | CHAIN x4, PAUSE-FOR-USER-ACTION x1 | task-042 |
| 120 | `canonical/skills/aid-update-kb/references/state-scope.md` | 166 | 0 | 0 | CHAIN x1 | task-042 |
| 121 | `canonical/skills/aid-update-mvp/SKILL.md` | 62, 78, 121, 131, 151 | 0 | 0 | GUARD x1, UPDATE x1, VERIFY x1, PRESENT x1, DONE x1 | task-036 |
| 122 | `canonical/skills/aid-update-roadmap/SKILL.md` | 57, 73, 112, 122, 137 | 0 | 0 | GUARD x1, UPDATE x1, VERIFY x1, PRESENT x1, DONE x1 | task-036 |
| 123 | `canonical/skills/aid-update-stack/SKILL.md` | 58, 74, 83, 92 | 0 | 0 | UPDATE x1, VERIFY x1, PRESENT x1, DONE x1 | task-036 |
| 124 | `canonical/skills/aid-update-testing-strategy/SKILL.md` | 60, 76, 85, 94 | 0 | 0 | UPDATE x1, VERIFY x1, PRESENT x1, DONE x1 | task-036 |
| 125 | `site/scripts/lib/flow-graph/advance.mjs` | 4, 36, 73, 82, 104, 111, 287, 294, 295, 460, 603, 604, 799, 800, 808, 812, 813, 814, 815, 817, 825, 1028 | 11 | 7 | block x2, blocks x1 | task-024 |
| 126 | `site/scripts/lib/flow-graph/engine-core.mjs` | 174, 198 | 1 | 1 | - | task-024 |
| 127 | `site/scripts/lib/flow-graph/extract-dispatch.mjs` | 58, 141, 413, 495, 497 | 2 | 1 | marker x2, PAUSE-FOR-USER-ACTION x1 | task-024 |
| 128 | `site/scripts/lib/flow-graph/extract-inline.mjs` | 5, 25, 59, 69, 133, 160, 181 | 0 | 0 | block x2, marker x2, line x1 | task-024 |
| 129 | `site/scripts/lib/flow-graph/model.mjs` | 23, 45, 153 | 3 | 3 | - | task-024 |

## P6 SS-02 Dispatch tables and State sections

Command (run from the repo root). A `SKILL.md` is in the set when it has a `## State:` section, a `| State | ... | Advance |` table, or a `## Dispatch` heading (`## Dispatch table`, `## Dispatch`, `## Dispatch Protocol ...`) above a table row:

```bash
git grep -l -E '^## State:' -- 'canonical/skills/*/SKILL.md'
git grep -l -E '^\| *State *\|.*Advance' -- 'canonical/skills/*/SKILL.md'
git grep -n -E '^#+ *Dispatch' -- 'canonical/skills/*/SKILL.md'   # then, for each hit, check that a table row (^\|) follows under that heading
```

Result: **58** SKILL.md files (the `ls canonical/skills/*/SKILL.md` listing has 112 files). `aid-ask` and `aid-read-ticket` have a `## Dispatch table` heading with a table, so they are in the set. `aid-orchestrate` is in no set: it has no Dispatch table or State section, and task-032 cites `skill-steps.md` in it anyway (Delta D6). 34 of the 112 skill files carry the generated-doorway banner; none of them is in the set.

| # | SKILL.md | Basis | (a) citation, (b) advance words, (c) State Detection | Owner |
|---|---|---|---|---|
| 1 | `canonical/skills/aid-ask/SKILL.md` | Dispatch table | cite `skill-steps.md`; advance words; detection rule | task-042 |
| 2 | `canonical/skills/aid-brainstorm/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-034 |
| 3 | `canonical/skills/aid-create-architecture/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-036 |
| 4 | `canonical/skills/aid-create-backlog/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-036 |
| 5 | `canonical/skills/aid-create-cicd/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-036 |
| 6 | `canonical/skills/aid-create-document/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-044 |
| 7 | `canonical/skills/aid-create-mvp/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-036 |
| 8 | `canonical/skills/aid-create-roadmap/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-036 |
| 9 | `canonical/skills/aid-create-stack/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-036 |
| 10 | `canonical/skills/aid-create-testing-strategy/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-036 |
| 11 | `canonical/skills/aid-define/SKILL.md` | State/Advance table, Dispatch table | cite `skill-steps.md`; advance words; detection rule | task-039 |
| 12 | `canonical/skills/aid-deploy/SKILL.md` | State/Advance table, Dispatch table | cite `skill-steps.md`; advance words; detection rule | task-043 |
| 13 | `canonical/skills/aid-describe/SKILL.md` | State/Advance table, Dispatch table | cite `skill-steps.md`; advance words; detection rule | task-038 |
| 14 | `canonical/skills/aid-design-api/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 15 | `canonical/skills/aid-design-architecture/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 16 | `canonical/skills/aid-design-backlog/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 17 | `canonical/skills/aid-design-cicd/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 18 | `canonical/skills/aid-design-cli/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 19 | `canonical/skills/aid-design-config/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 20 | `canonical/skills/aid-design-dashboard/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 21 | `canonical/skills/aid-design-data-model/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 22 | `canonical/skills/aid-design-data-pipeline/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 23 | `canonical/skills/aid-design-document/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 24 | `canonical/skills/aid-design-infra/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 25 | `canonical/skills/aid-design-integration/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 26 | `canonical/skills/aid-design-job/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 27 | `canonical/skills/aid-design-messaging/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 28 | `canonical/skills/aid-design-mvp/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 29 | `canonical/skills/aid-design-roadmap/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 30 | `canonical/skills/aid-design-stack/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 31 | `canonical/skills/aid-design-test/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 32 | `canonical/skills/aid-design-testing-strategy/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 33 | `canonical/skills/aid-design-theme/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 34 | `canonical/skills/aid-design-ui/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-035 |
| 35 | `canonical/skills/aid-design/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-034 |
| 36 | `canonical/skills/aid-detail/SKILL.md` | State/Advance table, Dispatch table | cite `skill-steps.md`; advance words; detection rule | task-040 |
| 37 | `canonical/skills/aid-discover/SKILL.md` | State/Advance table, Dispatch table | cite `skill-steps.md`; advance words; detection rule | task-041 |
| 38 | `canonical/skills/aid-execute/SKILL.md` | State/Advance table, Dispatch table | cite `skill-steps.md`; advance words; detection rule | task-040 |
| 39 | `canonical/skills/aid-housekeep/SKILL.md` | State/Advance table, Dispatch table | cite `skill-steps.md`; advance words; detection rule | task-042 |
| 40 | `canonical/skills/aid-monitor/SKILL.md` | State/Advance table, Dispatch table | cite `skill-steps.md`; advance words; detection rule | task-043 |
| 41 | `canonical/skills/aid-plan/SKILL.md` | State/Advance table, Dispatch table | cite `skill-steps.md`; advance words; detection rule | task-040 |
| 42 | `canonical/skills/aid-prototype/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-044 |
| 43 | `canonical/skills/aid-read-ticket/SKILL.md` | Dispatch table | cite `skill-steps.md`; advance words; detection rule | task-043 |
| 44 | `canonical/skills/aid-report/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-044 |
| 45 | `canonical/skills/aid-research/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-044 |
| 46 | `canonical/skills/aid-review/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-044 |
| 47 | `canonical/skills/aid-specify/SKILL.md` | State/Advance table, Dispatch table | cite `skill-steps.md`; advance words; detection rule | task-039 |
| 48 | `canonical/skills/aid-summarize/SKILL.md` | State/Advance table, Dispatch table | cite `skill-steps.md`; advance words; detection rule | task-042 |
| 49 | `canonical/skills/aid-test/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-044 |
| 50 | `canonical/skills/aid-update-architecture/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-036 |
| 51 | `canonical/skills/aid-update-backlog/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-036 |
| 52 | `canonical/skills/aid-update-cicd/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-036 |
| 53 | `canonical/skills/aid-update-document/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-044 |
| 54 | `canonical/skills/aid-update-kb/SKILL.md` | State/Advance table, Dispatch table | cite `skill-steps.md`; advance words; detection rule | task-042 |
| 55 | `canonical/skills/aid-update-mvp/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-036 |
| 56 | `canonical/skills/aid-update-roadmap/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-036 |
| 57 | `canonical/skills/aid-update-stack/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-036 |
| 58 | `canonical/skills/aid-update-testing-strategy/SKILL.md` | `## State:` | cite `skill-steps.md`; advance words; detection rule | task-036 |

## P7 NM-01 to NM-04 (never-merges)

Command (run from the repo root; include and exclude globs as REQUIREMENTS.md § 11 Feature 002 `##### 8. Testing` gives them):

```bash
# P7 (NM-01..NM-04): tracked files (git grep) under NM include globs, minus NM exclude globs. Run from repo root.
INC=(':(glob)canonical/**' ':(glob)bin/**' ':(glob)lib/**' ':(glob)dashboard/**' ':(glob)chat-node/**' ':(glob)scripts/**' release.sh install.sh install.ps1)
EXC=(':(exclude,glob)**/tests/**' ':(exclude,glob)**/__tests__/**' ':(exclude,glob)canonical/aid/templates/knowledge-summary/**' ':(exclude,glob)canonical/aid/templates/knowledge-base/**')
echo "## NM-01 git merge / git pull without --ff-only"
git grep -n -E 'git merge|git pull' -- "${INC[@]}" "${EXC[@]}" | grep -v -E 'git merge-base|git merge-tree' | grep -v -E 'git pull.*--ff-only' 
echo "## NM-02 merge endpoints, git push to main/master"
git grep -n -E 'gh pr merge|glab mr merge|pulls/[^ ]*/merge|merge_requests/[^ ]*/merge|git push[^|;]* (main|master)\b' -- "${INC[@]}" "${EXC[@]}"
echo "## NM-03 gh pr create / glab mr create"
git grep -n -E 'gh pr create|glab mr create' -- "${INC[@]}" "${EXC[@]}"
echo "## NM-04 merge to main"
git grep -n -i -E 'merge to main' -- "${INC[@]}" "${EXC[@]}"
```

NM-01 (`git merge`, `git pull` without `--ff-only`) and NM-02 (merge endpoints, `git push` to `main`/`master`) have **no** hit today. Four hits, all exempt, so only the two exemptions fire, as the spec states.

| # | Rule | Location | Exempt entry | Owner |
|---|---|---|---|---|
| 1 | NM-03 | `canonical/skills/aid-housekeep/references/state-done.md:32` | aid-housekeep, references/state-done.md (until Feature 004) | task-042 |
| 2 | NM-04 | `canonical/skills/aid-execute/SKILL.md:318` | aid-execute: SKILL.md, references/reviewer-brief.md, references/state-delivery-gate.md (until Feature 007) | task-040 |
| 3 | NM-04 | `canonical/skills/aid-execute/references/reviewer-brief.md:121` | aid-execute: SKILL.md, references/reviewer-brief.md, references/state-delivery-gate.md (until Feature 007) | task-040 |
| 4 | NM-04 | `canonical/skills/aid-execute/references/state-delivery-gate.md:177` | aid-execute: SKILL.md, references/reviewer-brief.md, references/state-delivery-gate.md (until Feature 007) | task-040 |

## P8 Q106 map: suites that read edit-list files

Command (run from the repo root). Each token is a basename of an edit-list file of delivery-002 (the files the tasks of this delivery change, from their Scopes and the spec's Files and layout), and each skill name is an edit-list skill (every skill in the groups of the owner table, including the no-change ones). The match is a plain substring match, by basename or name, in the four suite trees, so it over-includes: `rules.md` also matches `shared-rules.md`, and `aid-create` also matches `aid-create-api`: in `site/scripts/__tests__/flow-graph-doorways.test.mjs` it matches 27 lines (row 709), of which one is the exact name `'aid-create'`, at line 354. Each row still names the owner that must re-point or update that suite. The rows for the two baseline files take `baseline, re-recorded at the gate`:

```bash
TESTDIRS="tests site/scripts/__tests__ site/src/lib/__tests__ dashboard/reader/tests dashboard/server/tests"
for tok in work-state-template.yml project-state-template.yml question-protocol.md skill-steps.md advance.mjs writeback-state.sh work-initiation-gate.md start-or-resume.md rules.md home.html models.py parsers.py state_schema.py reader.py server.py reader.mjs server.mjs design-lifecycle.md shortcut-engine.md decisions.md artifact-schemas.md domain-glossary.md backlog.md pipeline-contracts.md architecture.md test-landscape.md INDEX.md ticket-resolution.md release.yml installer-tests.yml release.sh; do git grep -n -F -e "$tok" 06d32a1ba63e1c8810e16978165e5581034f4c87 -- $TESTDIRS; done
for n in $(ls canonical/skills); do git grep -n -F -e "$n" 06d32a1ba63e1c8810e16978165e5581034f4c87 -- $TESTDIRS; done
```

Hits: 761 (suite, owner) rows covering 7050 (token or name, line) matches in 356 suite files. Re-run at the base with the command above: 7050 output lines (2118 for the token loop, 4932 for the name loop), 356 distinct files. Rows with owner `history, left as is` are references to edit-list skills that no task edits (their text stays); the rows for the two baseline files are `baseline, re-recorded at the gate`; the rest are owned by the task that changes the asserted file, or, for a suite a task names, by that task.

| # | Suite | Owner | Edit-list names it matches (matching lines) |
|---|---|---|---|
| 1 | `dashboard/reader/tests/test_integration.py` | task-025 | `work-state-template.yml` 1, `writeback-state.sh` 15, `models.py` 1, `parsers.py` 1, `reader.py` 2, `aid-deploy` 1, `aid-execute` 9, `aid-specify` 1 |
| 2 | `tests/canonical/test-connector-consumption-linkage.sh` | task-021 | `work-state-template.yml` 3 |
| 3 | `tests/canonical/test-cutover-no-dangling.sh` | task-021 | `work-state-template.yml` 6 |
| 4 | `tests/canonical/test-delivery-gate-aggregate.sh` | task-021 | `work-state-template.yml` 1 |
| 5 | `tests/canonical/test-describe-full-only.sh` | task-021 | `work-state-template.yml` 2 |
| 6 | `tests/canonical/test-kb-html-claims-check.sh` | task-021 | `work-state-template.yml` 1 |
| 7 | `tests/canonical/test-state-review-surface.sh` | task-021 | `work-state-template.yml` 3 |
| 8 | `tests/canonical/test-task-state-transitions.sh` | task-021 | `work-state-template.yml` 1 |
| 9 | `tests/canonical/test-ticket-retirement-structural.sh` | task-021 | `work-state-template.yml` 3 |
| 10 | `tests/canonical/test-work-state-template.sh` | task-021 | `work-state-template.yml` 12 |
| 11 | `tests/canonical/test-writeback-state.sh` | task-021 | `work-state-template.yml` 3 |
| 12 | `tests/coverage-accepted-removals.tsv` | task-021 | `work-state-template.yml` 1 |
| 13 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `work-state-template.yml` 1 |
| 14 | `tests/coverage-rehome-allowlist.tsv` | task-021 | `work-state-template.yml` 1 |
| 15 | `site/scripts/__tests__/flow-advance.test.mjs` | task-024 | `advance.mjs` 4 |
| 16 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-024 | `advance.mjs` 1 |
| 17 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | task-024 | `advance.mjs` 4 |
| 18 | `site/scripts/__tests__/flow-graph.test.mjs` | task-024 | `advance.mjs` 8 |
| 19 | `site/scripts/__tests__/flow-validate.test.mjs` | task-024 | `advance.mjs` 3 |
| 20 | `site/scripts/__tests__/source-encoding.test.mjs` | task-024 | `advance.mjs` 1 |
| 21 | `dashboard/reader/tests/test_declared_path_three_way_parity.py` | task-025 | `writeback-state.sh` 7 |
| 22 | `dashboard/server/tests/test_task008_display_rename.py` | task-025 | `writeback-state.sh` 5 |
| 23 | `dashboard/server/tests/test_task010_task_notes.py` | task-025 | `writeback-state.sh` 1 |
| 24 | `dashboard/server/tests/test_task010_task_notes_cross_runtime_parity.py` | task-025 | `writeback-state.sh` 4 |
| 25 | `dashboard/server/tests/test_task011_dispatch_round_trip.mjs` | task-025 | `writeback-state.sh` 4 |
| 26 | `dashboard/server/tests/test_task011_dispatch_round_trip.py` | task-025 | `writeback-state.sh` 14 |
| 27 | `dashboard/server/tests/test_task012_consuming_round_trips.py` | task-025 | `writeback-state.sh` 2 |
| 28 | `dashboard/server/tests/test_task029_task_stop_resume_ops.mjs` | task-025 | `writeback-state.sh` 2 |
| 29 | `dashboard/server/tests/test_task029_task_stop_resume_ops.py` | task-025 | `writeback-state.sh` 2 |
| 30 | `dashboard/server/tests/test_task030_finish_stop_resume_ui.py` | task-025 | `writeback-state.sh` 2 |
| 31 | `dashboard/server/tests/test_task033_execution_control_round_trips.py` | task-025 | `writeback-state.sh` 10 |
| 32 | `dashboard/server/tests/test_write_enabled_cross_runtime_parity.py` | task-025 | `writeback-state.sh` 2 |
| 33 | `tests/README.md` | task-025 | `writeback-state.sh` 1 |
| 34 | `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/deliveries/delivery-001/STATE.md` | task-025 | `writeback-state.sh` 1 |
| 35 | `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/deliveries/delivery-001/tasks/task-001/STATE.md` | task-025 | `writeback-state.sh` 2 |
| 36 | `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/deliveries/delivery-001/tasks/task-002/STATE.md` | task-025 | `writeback-state.sh` 2 |
| 37 | `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/deliveries/delivery-001/tasks/task-004/STATE.md` | task-025 | `writeback-state.sh` 2 |
| 38 | `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/deliveries/delivery-002/STATE.md` | task-025 | `writeback-state.sh` 1 |
| 39 | `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/deliveries/delivery-002/tasks/task-003/STATE.md` | task-025 | `writeback-state.sh` 2 |
| 40 | `tests/canonical/test-artifact-discipline.sh` | task-025 | `writeback-state.sh` 2 |
| 41 | `tests/canonical/test-delivery-gate-aggregate.sh` | task-025 | `writeback-state.sh` 6 |
| 42 | `tests/canonical/test-disjoint-merge.sh` | task-025 | `writeback-state.sh` 9 |
| 43 | `tests/canonical/test-lite-work-end-to-end.sh` | task-025 | `writeback-state.sh` 3 |
| 44 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-025 | `writeback-state.sh` 17 |
| 45 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-039 | `writeback-state.sh` 1, `aid-define` 6, `aid-specify` 20 |
| 46 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-040 | `aid-detail` 5, `aid-execute` 14, `aid-plan` 5 |
| 47 | `tests/canonical/test-shortcut-engine-contract.sh` | task-025 | `writeback-state.sh` 1 |
| 48 | `tests/canonical/test-state-review-surface.sh` | task-025 | `writeback-state.sh` 1 |
| 49 | `tests/canonical/test-task-state-transitions.sh` | task-025 | `writeback-state.sh` 6 |
| 50 | `tests/canonical/test-version-sync.sh` | task-025 | `writeback-state.sh` 1 |
| 51 | `tests/canonical/test-writeback-state.sh` | task-025 | `writeback-state.sh` 3 |
| 52 | `tests/conversation/samples/feature-001/001-10-release-own-work.md` | task-025 | `writeback-state.sh` 1 |
| 53 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `writeback-state.sh` 380 |
| 54 | `site/scripts/__tests__/flow-engine-core.test.mjs` | task-030 | `work-initiation-gate.md` 5 |
| 55 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-030 | `work-initiation-gate.md` 1 |
| 56 | `tests/canonical/test-work-initiation-gate.sh` | task-030 | `work-initiation-gate.md` 5 |
| 57 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `work-initiation-gate.md` 1 |
| 58 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `work-initiation-gate.md` 1 |
| 59 | `tests/canonical/test-aid-cli-parity.sh` | task-032 | `rules.md` 7 |
| 60 | `tests/canonical/test-aid-migrate.sh` | task-032 | `rules.md` 29 |
| 61 | `tests/canonical/test-aid-status-drift.sh` | task-032 | `rules.md` 1 |
| 62 | `tests/canonical/test-change-refactor-family-scaffold.sh` | task-032 | `rules.md` 1 |
| 63 | `tests/canonical/test-connector-skills-structural.sh` | task-032 | `rules.md` 9 |
| 64 | `tests/canonical/test-create-family-scaffold.sh` | task-032 | `rules.md` 1 |
| 65 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-032 | `rules.md` 1, `aid-orchestrate` 2 |
| 66 | `tests/canonical/test-document-family-scaffold.sh` | task-032 | `rules.md` 2 |
| 67 | `tests/canonical/test-dogfood-byte-identity.sh` | task-032 | `rules.md` 12 |
| 68 | `tests/canonical/test-install-core-primitives.sh` | task-032 | `rules.md` 24 |
| 69 | `tests/canonical/test-install-provisioning.sh` | task-032 | `rules.md` 2 |
| 70 | `tests/canonical/test-layout-format-guard.sh` | task-032 | `rules.md` 1 |
| 71 | `tests/canonical/test-prototype-family-scaffold.sh` | task-032 | `rules.md` 1 |
| 72 | `tests/canonical/test-release-install-e2e.sh` | task-032 | `rules.md` 5 |
| 73 | `tests/canonical/test-release.sh` | task-032 | `rules.md` 2 |
| 74 | `tests/canonical/test-shared-install.sh` | task-032 | `rules.md` 12 |
| 75 | `tests/canonical/test-shared-layout-sources.sh` | task-032 | `rules.md` 1 |
| 76 | `tests/canonical/test-shared-remove.sh` | task-032 | `rules.md` 13 |
| 77 | `tests/canonical/test-skill-guide.sh` | task-032 | `rules.md` 10 |
| 78 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `rules.md` 1 |
| 79 | `tests/coverage-rehome-allowlist.tsv` | task-032 | `rules.md` 6 |
| 80 | `tests/windows/Test-AidInstaller.ps1` | task-032 | `rules.md` 19 |
| 81 | `tests/windows/Test-InstallProvisioning.ps1` | task-032 | `rules.md` 2 |
| 82 | `dashboard/reader/tests/test_flattened_layout_parity.py` | task-033 | `home.html` 1 |
| 83 | `dashboard/reader/tests/test_work016_container_discovery.py` | task-033 | `home.html` 9 |
| 84 | `dashboard/server/tests/test_cli_home_html.py` | task-033 | `home.html` 5 |
| 85 | `dashboard/server/tests/test_home_html_project_header.py` | task-033 | `home.html` 4 |
| 86 | `dashboard/server/tests/test_index_html.py` | task-033 | `home.html` 27 |
| 87 | `dashboard/server/tests/test_server_node.mjs` | task-033 | `home.html` 19 |
| 88 | `dashboard/server/tests/test_server_py.py` | task-033 | `home.html` 8 |
| 89 | `dashboard/server/tests/test_task009_rename_ui.py` | task-033 | `home.html` 4 |
| 90 | `dashboard/server/tests/test_task010_task_notes.py` | task-033 | `home.html` 1 |
| 91 | `dashboard/server/tests/test_task010_task_notes_ui.py` | task-033 | `home.html` 4 |
| 92 | `dashboard/server/tests/test_task012_consuming_round_trips.py` | task-033 | `home.html` 1 |
| 93 | `dashboard/server/tests/test_task022_connectors_external_sources_ui.py` | task-033 | `home.html` 6 |
| 94 | `dashboard/server/tests/test_task026_delete_pipeline_ui.py` | task-033 | `home.html` 6 |
| 95 | `dashboard/server/tests/test_task030_finish_stop_resume_ui.py` | task-033 | `home.html` 4 |
| 96 | `dashboard/server/tests/test_task033_execution_control_round_trips.py` | task-033 | `home.html` 5 |
| 97 | `dashboard/server/tests/test_tools_management_ui.py` | task-033 | `home.html` 7 |
| 98 | `tests/canonical/test-aid-migrate-trigger.sh` | task-033 | `home.html` 46 |
| 99 | `tests/canonical/test-aid-migrate.sh` | task-033 | `home.html` 4 |
| 100 | `tests/canonical/test-aid-migration-stamp.sh` | task-033 | `home.html` 1 |
| 101 | `tests/canonical/test-chat-node-manifest.sh` | task-033 | `home.html` 1 |
| 102 | `tests/canonical/test-dashboard-manifest.sh` | task-033 | `home.html` 1 |
| 103 | `tests/canonical/test-dashboard-parity-h.sh` | task-033 | `home.html` 4 |
| 104 | `tests/canonical/test-grade-summary.sh` | task-033 | `home.html` 4 |
| 105 | `tests/canonical/test-guardrails-d012.sh` | task-033 | `home.html` 6 |
| 106 | `tests/canonical/test-install-parity.sh` | task-033 | `home.html` 5 |
| 107 | `tests/canonical/test-release-migrate-smoke.sh` | task-033 | `home.html` 1 |
| 108 | `tests/coverage-accepted-removals.tsv` | task-033 | `home.html` 4 |
| 109 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `home.html` 7 |
| 110 | `tests/lib/sandbox.sh` | task-033 | `home.html` 1 |
| 111 | `tests/ui/README.md` | task-033 | `home.html` 1 |
| 112 | `tests/ui/edit-surfaces.spec.mjs` | task-033 | `home.html` 1 |
| 113 | `dashboard/reader/tests/test_fixtures.py` | task-031 | `models.py` 1, `parsers.py` 3, `reader.py` 1 |
| 114 | `dashboard/reader/tests/test_reader.py` | task-031 | `models.py` 1, `parsers.py` 2, `reader.py` 6 |
| 115 | `dashboard/reader/tests/test_work016_container_discovery.py` | task-031 | `models.py` 6, `state_schema.py` 1, `reader.py` 1, `reader.mjs` 5 |
| 116 | `tests/canonical/test-aid-cli-parity.sh` | task-031 | `models.py` 3, `parsers.py` 3, `reader.py` 3, `server.py` 3, `reader.mjs` 3, `server.mjs` 3 |
| 117 | `tests/canonical/test-aid-dashboard-cli.sh` | task-031 | `models.py` 1, `parsers.py` 1, `reader.py` 1, `server.py` 7, `reader.mjs` 1, `server.mjs` 4 |
| 118 | `dashboard/reader/tests/test_derivation.py` | task-031 | `parsers.py` 1, `state_schema.py` 1, `reader.py` 2 |
| 119 | `dashboard/reader/tests/test_task014_fixtures.py` | task-031 | `parsers.py` 1, `server.py` 1, `reader.mjs` 8 |
| 120 | `dashboard/reader/tests/test_task064_kb_status.py` | task-031 | `parsers.py` 1 |
| 121 | `dashboard/reader/tests/test_task069_detail_parser.py` | task-031 | `parsers.py` 1, `reader.py` 7 |
| 122 | `dashboard/reader/tests/test_work003_state_schema.py` | task-031 | `parsers.py` 1, `state_schema.py` 5, `reader.py` 2, `server.py` 2, `reader.mjs` 7 |
| 123 | `dashboard/server/tests/test_task012_consuming_round_trips.py` | task-031 | `parsers.py` 2, `server.py` 3, `reader.mjs` 7, `server.mjs` 9 |
| 124 | `dashboard/server/tests/test_task022_connectors_external_sources_ui.py` | task-031 | `parsers.py` 1, `server.py` 1, `reader.mjs` 1 |
| 125 | `dashboard/server/tests/test_task027_pipeline_delete_round_trips.py` | task-031 | `parsers.py` 1, `server.py` 4, `server.mjs` 5 |
| 126 | `tests/canonical/test-derive-waves.sh` | task-031 | `parsers.py` 1 |
| 127 | `dashboard/reader/tests/test_shortcut_kind_map_cross_runtime_parity.py` | task-031 | `state_schema.py` 9, `reader.mjs` 13, `server.mjs` 1 |
| 128 | `dashboard/reader/tests/test_state_yaml_conformance.py` | task-031 | `state_schema.py` 1, `reader.mjs` 1 |
| 129 | `tests/canonical/test-work-state-template.sh` | task-031 | `state_schema.py` 1 |
| 130 | `dashboard/reader/tests/test_declared_path_three_way_parity.py` | task-031 | `reader.py` 3, `reader.mjs` 3 |
| 131 | `dashboard/reader/tests/test_derived_lanes_cross_runtime_parity.py` | task-031 | `reader.py` 2, `reader.mjs` 3 |
| 132 | `dashboard/reader/tests/test_feature009.py` | task-031 | `reader.py` 6, `reader.mjs` 3 |
| 133 | `dashboard/reader/tests/test_flattened_layout_parity.py` | task-031 | `reader.py` 4, `reader.mjs` 4 |
| 134 | `dashboard/reader/tests/test_plan_delivery_title_cross_runtime_parity.py` | task-031 | `reader.py` 2, `reader.mjs` 4 |
| 135 | `dashboard/reader/tests/test_task011_golden_master.py` | task-031 | `reader.py` 1, `server.py` 4, `reader.mjs` 7 |
| 136 | `dashboard/reader/tests/test_task066_kb_parity.py` | task-031 | `reader.py` 1 |
| 137 | `dashboard/reader/tests/test_work001_delivery_layouts.py` | task-031 | `reader.py` 7, `server.py` 2, `reader.mjs` 7 |
| 138 | `dashboard/server/tests/test_reader_task069.mjs` | task-031 | `reader.py` 2, `reader.mjs` 3 |
| 139 | `dashboard/server/tests/test_task033_execution_control_round_trips.py` | task-031 | `reader.py` 1, `server.py` 8, `reader.mjs` 1, `server.mjs` 6 |
| 140 | `tests/canonical/test-artifact-discipline.sh` | task-031 | `reader.py` 1, `reader.mjs` 1 |
| 141 | `tests/canonical/test-dashboard-manifest.sh` | task-031 | `reader.py` 2 |
| 142 | `tests/canonical/test-dashboard-parity-h.sh` | task-031 | `reader.py` 3, `server.py` 12, `reader.mjs` 3, `server.mjs` 10 |
| 143 | `tests/canonical/test-lite-work-end-to-end.sh` | task-031 | `reader.py` 6, `reader.mjs` 5 |
| 144 | `dashboard/reader/tests/test_task008_display_rename.py` | task-031 | `server.py` 1, `reader.mjs` 3 |
| 145 | `dashboard/reader/tests/test_task021_external_sources.py` | task-031 | `server.py` 2, `reader.mjs` 3 |
| 146 | `dashboard/reader/tests/test_task029_stop_requested.py` | task-031 | `server.py` 1, `reader.mjs` 3 |
| 147 | `dashboard/server/tests/fixtures/README.md` | task-031 | `server.py` 1 |
| 148 | `dashboard/server/tests/test_home_html_project_header.py` | task-031 | `server.py` 2, `server.mjs` 2 |
| 149 | `dashboard/server/tests/test_index_html.py` | task-031 | `server.py` 2 |
| 150 | `dashboard/server/tests/test_server_py.py` | task-031 | `server.py` 6 |
| 151 | `dashboard/server/tests/test_task011_dispatch_round_trip.py` | task-031 | `server.py` 8 |
| 152 | `dashboard/server/tests/test_task013_project_registry_ops.mjs` | task-031 | `server.py` 1, `server.mjs` 10 |
| 153 | `dashboard/server/tests/test_task017_registry_tooling_round_trips.mjs` | task-031 | `server.py` 1, `server.mjs` 5 |
| 154 | `dashboard/server/tests/test_task017_registry_tooling_round_trips.py` | task-031 | `server.py` 2, `server.mjs` 11 |
| 155 | `dashboard/server/tests/test_task023_list_management_round_trips.mjs` | task-031 | `server.py` 1, `server.mjs` 4 |
| 156 | `dashboard/server/tests/test_task023_list_management_round_trips.py` | task-031 | `server.py` 4, `reader.mjs` 2, `server.mjs` 5 |
| 157 | `dashboard/server/tests/test_task030_finish_stop_resume_ui.py` | task-031 | `server.py` 2, `server.mjs` 2 |
| 158 | `dashboard/server/tests/test_tools_management_ui.py` | task-031 | `server.py` 1, `server.mjs` 1 |
| 159 | `tests/canonical/test-aid-remote.sh` | task-031 | `server.py` 2, `reader.mjs` 1, `server.mjs` 2 |
| 160 | `tests/canonical/test-ascii-only.sh` | task-031 | `server.py` 1, `reader.mjs` 1, `server.mjs` 1 |
| 161 | `tests/canonical/test-dashboard-parity.sh` | task-031 | `server.py` 2, `server.mjs` 2 |
| 162 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `server.py` 6, `server.mjs` 4 |
| 163 | `tests/ui/README.md` | task-031 | `server.py` 1, `server.mjs` 1 |
| 164 | `tests/ui/serve.mjs` | task-031 | `server.py` 1, `server.mjs` 1 |
| 165 | `dashboard/reader/tests/test_resolve_work_dir_cross_runtime_parity.py` | task-031 | `reader.mjs` 3 |
| 166 | `dashboard/reader/tests/test_security_hardening.py` | task-031 | `reader.mjs` 4 |
| 167 | `dashboard/reader/tests/test_state_yaml_conformance_node.py` | task-031 | `reader.mjs` 6 |
| 168 | `dashboard/reader/tests/test_task019_connectors.py` | task-031 | `reader.mjs` 3 |
| 169 | `dashboard/reader/tests/test_task023_list_management_parity.py` | task-031 | `reader.mjs` 5 |
| 170 | `dashboard/reader/tests/test_task044_freshness_parity.py` | task-031 | `reader.mjs` 2 |
| 171 | `dashboard/server/tests/test_server_node.mjs` | task-031 | `reader.mjs` 12, `server.mjs` 11 |
| 172 | `dashboard/server/tests/test_task002_resolve_work_dir.mjs` | task-031 | `reader.mjs` 2 |
| 173 | `dashboard/server/tests/test_task010_task_notes_cross_runtime_parity.py` | task-031 | `reader.mjs` 2, `server.mjs` 7 |
| 174 | `dashboard/server/tests/test_task019_connector_ops.mjs` | task-031 | `reader.mjs` 3, `server.mjs` 6 |
| 175 | `dashboard/server/tests/test_task021_external_source_ops.mjs` | task-031 | `reader.mjs` 4, `server.mjs` 6 |
| 176 | `dashboard/server/tests/test_task025_pipeline_delete_ops.mjs` | task-031 | `reader.mjs` 3, `server.mjs` 6 |
| 177 | `dashboard/server/tests/test_task029_task_stop_resume_ops.mjs` | task-031 | `reader.mjs` 3, `server.mjs` 6 |
| 178 | `dashboard/server/tests/test_write_enabled_cross_runtime_parity.py` | task-031 | `reader.mjs` 5, `server.mjs` 13 |
| 179 | `tests/canonical/test-producer-completeness.sh` | task-031 | `reader.mjs` 6 |
| 180 | `tests/canonical/test-task-state-transitions.sh` | task-031 | `reader.mjs` 2 |
| 181 | `dashboard/server/tests/test_ki009_windows_dispatch.py` | task-031 | `server.mjs` 5 |
| 182 | `dashboard/server/tests/test_task010_task_notes.py` | task-031 | `server.mjs` 1 |
| 183 | `dashboard/server/tests/test_task011_dispatch_round_trip.mjs` | task-031 | `server.mjs` 13 |
| 184 | `dashboard/server/tests/test_task015_tools_update_ops.mjs` | task-031 | `server.mjs` 14 |
| 185 | `tests/canonical/test-kb-citation-lint.sh` | task-031 | `server.mjs` 3 |
| 186 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `design-lifecycle.md` 1, `aid-brainstorm` 5, `aid-design` 110 |
| 187 | `site/scripts/__tests__/flow-classify.test.mjs` | task-037 | `shortcut-engine.md` 4 |
| 188 | `site/scripts/__tests__/flow-compose.test.mjs` | task-037 | `shortcut-engine.md` 5 |
| 189 | `site/scripts/__tests__/flow-engine-core.test.mjs` | task-037 | `shortcut-engine.md` 6 |
| 190 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | task-037 | `shortcut-engine.md` 2 |
| 191 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-037 | `shortcut-engine.md` 6 |
| 192 | `site/scripts/__tests__/flow-graph.test.mjs` | task-037 | `shortcut-engine.md` 4 |
| 193 | `site/scripts/__tests__/gen-reference.test.mjs` | task-037 | `shortcut-engine.md` 1 |
| 194 | `site/scripts/__tests__/provenance-appender.test.mjs` | task-037 | `shortcut-engine.md` 5 |
| 195 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | task-037 | `shortcut-engine.md` 1 |
| 196 | `tests/canonical/test-artifact-discipline.sh` | task-037 | `shortcut-engine.md` 2 |
| 197 | `tests/canonical/test-catalog-dirs-parity.sh` | task-037 | `shortcut-engine.md` 2 |
| 198 | `tests/canonical/test-change-refactor-family-scaffold.sh` | task-037 | `shortcut-engine.md` 1 |
| 199 | `tests/canonical/test-create-family-scaffold.sh` | task-037 | `shortcut-engine.md` 6 |
| 200 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-037 | `shortcut-engine.md` 2 |
| 201 | `tests/canonical/test-document-family-scaffold.sh` | task-037 | `shortcut-engine.md` 2 |
| 202 | `tests/canonical/test-downstream-worktree-entry.sh` | task-037 | `shortcut-engine.md` 2 |
| 203 | `tests/canonical/test-fix-family-scaffold.sh` | task-037 | `shortcut-engine.md` 1 |
| 204 | `tests/canonical/test-prototype-family-scaffold.sh` | task-037 | `shortcut-engine.md` 2 |
| 205 | `tests/canonical/test-shortcut-engine-contract.sh` | task-037 | `shortcut-engine.md` 8 |
| 206 | `tests/canonical/test-state-review-surface.sh` | task-037 | `shortcut-engine.md` 7 |
| 207 | `tests/canonical/test-test-experiment-family-scaffold.sh` | task-037 | `shortcut-engine.md` 2 |
| 208 | `tests/canonical/test-ticket-retirement-structural.sh` | task-037 | `shortcut-engine.md` 5 |
| 209 | `tests/canonical/test-work-initiation-gate.sh` | task-037 | `shortcut-engine.md` 3 |
| 210 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `shortcut-engine.md` 1 |
| 211 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `shortcut-engine.md` 4 |
| 212 | `tests/canonical/fixtures/dual-intent/content/doc-set.tsv` | task-045 | `decisions.md` 1, `domain-glossary.md` 1 |
| 213 | `tests/canonical/fixtures/dual-intent/data-ml/doc-set.tsv` | task-045 | `decisions.md` 1, `domain-glossary.md` 1 |
| 214 | `tests/canonical/fixtures/dual-intent/design/doc-set.tsv` | task-045 | `decisions.md` 1, `domain-glossary.md` 1 |
| 215 | `tests/canonical/test-chat-node-wake.sh` | task-045 | `decisions.md` 1 |
| 216 | `tests/canonical/test-domain-doc-matrix.sh` | task-045 | `decisions.md` 15 |
| 217 | `tests/canonical/test-grade-summary.sh` | task-045 | `decisions.md` 6, `domain-glossary.md` 8 |
| 218 | `tests/canonical/test-kb-review-surface.sh` | task-045 | `decisions.md` 3 |
| 219 | `tests/canonical/fixtures/actback-task/docset-check.tsv` | task-045 | `domain-glossary.md` 1 |
| 220 | `tests/canonical/fixtures/actback-task/kb/domain-glossary.md` | task-045 | `domain-glossary.md` 1 |
| 221 | `tests/canonical/fixtures/kb-essence/actback/actback-fail-kb/knowledge/domain-glossary.md` | task-045 | `domain-glossary.md` 1 |
| 222 | `tests/canonical/fixtures/kb-essence/actback/representative-task-fixture/doc-set.tsv` | task-045 | `domain-glossary.md` 1 |
| 223 | `tests/canonical/fixtures/kb-essence/actback/representative-task-fixture/expected/task-spec.txt` | task-045 | `domain-glossary.md` 1 |
| 224 | `tests/canonical/fixtures/kb-essence/closed-kb/knowledge/architecture.md` | task-045 | `domain-glossary.md` 1 |
| 225 | `tests/canonical/test-actback-fixtures.sh` | task-045 | `domain-glossary.md` 14 |
| 226 | `tests/canonical/test-actback-task.sh` | task-045 | `domain-glossary.md` 15 |
| 227 | `tests/canonical/test-closure-batching.sh` | task-045 | `domain-glossary.md` 2 |
| 228 | `tests/canonical/test-closure-check.sh` | task-045 | `domain-glossary.md` 5 |
| 229 | `tests/canonical/test-doc-set-mapping.sh` | task-045 | `domain-glossary.md` 5 |
| 230 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-045 | `domain-glossary.md` 2 |
| 231 | `tests/canonical/test-essence-capture.sh` | task-045 | `domain-glossary.md` 2 |
| 232 | `tests/canonical/test-output-root-isolation.sh` | task-045 | `domain-glossary.md` 4 |
| 233 | `tests/canonical/test-teachback-fixtures.sh` | task-045 | `domain-glossary.md` 5 |
| 234 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `domain-glossary.md` 1 |
| 235 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `domain-glossary.md` 2 |
| 236 | `tests/canonical/fixtures/actback-task/docset-contract.tsv` | task-049 | `pipeline-contracts.md` 1 |
| 237 | `tests/canonical/test-actback-task.sh` | task-049 | `pipeline-contracts.md` 1, `architecture.md` 3 |
| 238 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-049 | `pipeline-contracts.md` 8 |
| 239 | `tests/canonical/test-doc-set-mapping.sh` | task-049 | `pipeline-contracts.md` 9, `architecture.md` 10 |
| 240 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-049 | `pipeline-contracts.md` 2, `architecture.md` 4 |
| 241 | `tests/canonical/test-doc-set-read.sh` | task-049 | `pipeline-contracts.md` 5, `architecture.md` 13 |
| 242 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `pipeline-contracts.md` 1, `architecture.md` 1 |
| 243 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `pipeline-contracts.md` 4, `architecture.md` 12 |
| 244 | `dashboard/reader/tests/test_reader.py` | task-049 | `architecture.md` 1 |
| 245 | `tests/canonical/fixtures/actback-task/docset-component.tsv` | task-049 | `architecture.md` 1 |
| 246 | `tests/canonical/fixtures/kb-essence/paths/brownfield-large/generated/project-index.md` | task-049 | `architecture.md` 1 |
| 247 | `tests/canonical/fixtures/kb-essence/unclosed-kb/knowledge/domain-glossary.md` | task-049 | `architecture.md` 2 |
| 248 | `tests/canonical/fixtures/teachback-questions/candidate-concepts-mixed.md` | task-049 | `architecture.md` 1 |
| 249 | `tests/canonical/test-build-kb-index.sh` | task-049 | `architecture.md` 3 |
| 250 | `tests/canonical/test-closure-check.sh` | task-049 | `architecture.md` 16 |
| 251 | `tests/canonical/test-conformance-lane-semantics.sh` | task-049 | `architecture.md` 4 |
| 252 | `tests/canonical/test-essence-capture.sh` | task-049 | `architecture.md` 1 |
| 253 | `tests/canonical/test-expectations-single-source.sh` | task-049 | `architecture.md` 9 |
| 254 | `tests/canonical/test-frontmatter-lint.sh` | task-049 | `architecture.md` 1 |
| 255 | `tests/canonical/test-grade-summary.sh` | task-049 | `architecture.md` 6 |
| 256 | `tests/canonical/test-harvest-coined-terms.sh` | task-049 | `architecture.md` 1 |
| 257 | `tests/canonical/test-housekeep-classify.sh` | task-049 | `architecture.md` 2 |
| 258 | `tests/canonical/test-kb-html-claims-check.sh` | task-049 | `architecture.md` 4 |
| 259 | `tests/canonical/test-kb-index-extract-list.sh` | task-049 | `architecture.md` 4 |
| 260 | `tests/canonical/test-kb-review-surface.sh` | task-049 | `architecture.md` 3 |
| 261 | `tests/canonical/test-spine-depth-coverage.sh` | task-049 | `architecture.md` 3 |
| 262 | `tests/canonical/test-summarize-preflight.sh` | task-049 | `architecture.md` 1 |
| 263 | `tests/canonical/test-validator-behavior.sh` | task-049 | `architecture.md` 5 |
| 264 | `tests/conversation/fixtures/default/.aid/knowledge/INDEX.md` | task-049 | `architecture.md` 1 |
| 265 | `tests/conversation/fixtures/done-work/.aid/knowledge/INDEX.md` | task-049 | `architecture.md` 1 |
| 266 | `tests/conversation/fixtures/empty-notes-file/.aid/knowledge/INDEX.md` | task-049 | `architecture.md` 1 |
| 267 | `tests/conversation/fixtures/ticket-mid-work/.aid/knowledge/INDEX.md` | task-049 | `architecture.md` 1 |
| 268 | `tests/conversation/samples/feature-001/001-05-project-question.md` | task-049 | `architecture.md` 1 |
| 269 | `tests/conversation/samples/feature-001/001-06-kb-conflict.md` | task-049 | `architecture.md` 1 |
| 270 | `tests/canonical/test-discovery-doc-ownership.sh` | task-057 | `test-landscape.md` 4 |
| 271 | `tests/canonical/test-doc-set-mapping.sh` | task-057 | `test-landscape.md` 13 |
| 272 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-057 | `test-landscape.md` 9 |
| 273 | `tests/canonical/test-validator-behavior.sh` | task-057 | `test-landscape.md` 1, `INDEX.md` 5 |
| 274 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `test-landscape.md` 1 |
| 275 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `test-landscape.md` 5, `INDEX.md` 7 |
| 276 | `dashboard/reader/tests/test_task019_connectors.py` | task-057 | `INDEX.md` 3 |
| 277 | `dashboard/server/tests/test_task019_connector_ops.mjs` | task-057 | `INDEX.md` 2 |
| 278 | `dashboard/server/tests/test_task019_connector_ops.py` | task-057 | `INDEX.md` 2 |
| 279 | `dashboard/server/tests/test_task023_list_management_round_trips.py` | task-057 | `INDEX.md` 7 |
| 280 | `tests/canonical/test-build-connectors-index.sh` | task-057 | `INDEX.md` 15 |
| 281 | `tests/canonical/test-connector-registry.sh` | task-057 | `INDEX.md` 4 |
| 282 | `tests/canonical/test-connector-set-unset-lifecycle.sh` | task-057 | `INDEX.md` 6 |
| 283 | `tests/canonical/test-connector-twins-ps1-parity.sh` | task-057 | `INDEX.md` 9 |
| 284 | `tests/canonical/test-connectors-registry-integration.sh` | task-057 | `INDEX.md` 10 |
| 285 | `tests/canonical/test-conversation-runner.sh` | task-057 | `INDEX.md` 2 |
| 286 | `tests/canonical/test-frontmatter-lint.sh` | task-057 | `INDEX.md` 1 |
| 287 | `tests/canonical/test-grade-summary.sh` | task-057 | `INDEX.md` 2 |
| 288 | `tests/canonical/test-guardrails-d012.sh` | task-057 | `INDEX.md` 1 |
| 289 | `tests/canonical/test-kb-forward-authored-marker.sh` | task-057 | `INDEX.md` 2 |
| 290 | `tests/canonical/test-kb-freshness-check.sh` | task-057 | `INDEX.md` 6 |
| 291 | `tests/canonical/test-kb-review-surface.sh` | task-057 | `INDEX.md` 5 |
| 292 | `tests/canonical/test-payload-size.sh` | task-057 | `INDEX.md` 1 |
| 293 | `tests/canonical/test-reconcile-scenarios.sh` | task-057 | `INDEX.md` 30 |
| 294 | `tests/canonical/test-write-connector.sh` | task-057 | `INDEX.md` 7 |
| 295 | `tests/cost-meter.py` | task-057 | `INDEX.md` 1 |
| 296 | `tests/canonical/test-connector-skills-structural.sh` | task-043 | `ticket-resolution.md` 2, `aid-config` 2, `aid-set-connector` 14, `aid-unset-connector` 13 |
| 297 | `tests/canonical/test-ticket-skills-structural.sh` | task-043 | `ticket-resolution.md` 10, `aid-create-ticket` 35, `aid-read-ticket` 18, `aid-update-ticket` 32 |
| 298 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `ticket-resolution.md` 1, `aid-chat` 5, `aid-config` 5, `aid-create-ticket` 5, `aid-deploy` 5, `aid-monitor` 5, `aid-read-ticket` 5, `aid-set-connector` 5, `aid-unset-connector` 5, `aid-update-ticket` 5 |
| 299 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `ticket-resolution.md` 3, `aid-create-ticket` 33, `aid-deploy` 9, `aid-monitor` 6, `aid-read-ticket` 16, `aid-update-ticket` 25 |
| 300 | `tests/canonical/test-version-sync.sh` | task-056 | `release.yml` 15 |
| 301 | `tests/canonical/test-writeback-state.sh` | task-056 | `release.yml` 1 |
| 302 | `tests/canonical/test-aid-cli-parity.sh` | task-056 | `installer-tests.yml` 1, `release.sh` 1 |
| 303 | `tests/canonical/test-ascii-only.sh` | task-056 | `installer-tests.yml` 1 |
| 304 | `tests/canonical/test-ps51-compat.sh` | task-056 | `installer-tests.yml` 1 |
| 305 | `tests/windows/Test-AidInstaller.ps1` | task-056 | `installer-tests.yml` 1, `release.sh` 3 |
| 306 | `tests/canonical/test-aid-cli-ps1.sh` | task-056 | `release.sh` 1 |
| 307 | `tests/canonical/test-aid-cli.sh` | task-056 | `release.sh` 1 |
| 308 | `tests/canonical/test-aid-migrate-trigger.sh` | task-056 | `release.sh` 7 |
| 309 | `tests/canonical/test-aid-migrate.sh` | task-056 | `release.sh` 1 |
| 310 | `tests/canonical/test-chat-node-manifest.sh` | task-056 | `release.sh` 4 |
| 311 | `tests/canonical/test-conversation-runner.sh` | task-056 | `release.sh` 1 |
| 312 | `tests/canonical/test-dashboard-manifest.sh` | task-056 | `release.sh` 2 |
| 313 | `tests/canonical/test-npm-installer.sh` | task-056 | `release.sh` 1 |
| 314 | `tests/canonical/test-pypi-installer.sh` | task-056 | `release.sh` 1 |
| 315 | `tests/canonical/test-registry.sh` | task-056 | `release.sh` 1 |
| 316 | `tests/canonical/test-release-install-e2e.sh` | task-056 | `release.sh` 20 |
| 317 | `tests/canonical/test-release-migrate-smoke.sh` | task-056 | `release.sh` 1 |
| 318 | `tests/canonical/test-release.sh` | task-056 | `release.sh` 11 |
| 319 | `tests/canonical/test-shared-install.sh` | task-056 | `release.sh` 1 |
| 320 | `tests/canonical/test-shortcut-builder-invariants.sh` | task-056 | `release.sh` 1 |
| 321 | `tests/canonical/test-shortcut-engine-contract.sh` | task-056 | `release.sh` 1 |
| 322 | `tests/coverage-accepted-removals.tsv` | task-056 | `release.sh` 2 |
| 323 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `release.sh` 17 |
| 324 | `tests/lib/bundle.sh` | task-056 | `release.sh` 2 |
| 325 | `site/scripts/__tests__/provenance.test.mjs` | task-042 | `aid-ask` 2 |
| 326 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | task-042 | `aid-ask` 15 |
| 327 | `site/src/lib/__tests__/skill-node-panel.test.ts` | task-042 | `aid-ask` 20 |
| 328 | `tests/canonical/test-aid-cli-parity.sh` | task-042 | `aid-ask` 7 |
| 329 | `tests/canonical/test-aid-migrate.sh` | task-042 | `aid-ask` 1 |
| 330 | `tests/canonical/test-dogfood-byte-identity.sh` | task-042 | `aid-ask` 2 |
| 331 | `tests/canonical/test-multitool-isolation.sh` | task-042 | `aid-ask` 4 |
| 332 | `tests/canonical/test-ticket-retirement-structural.sh` | task-042 | `aid-ask` 5 |
| 333 | `tests/windows/Test-AidInstaller.ps1` | task-042 | `aid-ask` 3 |
| 334 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | task-042 | `aid-ask` 5 |
| 335 | `site/scripts/__tests__/gen-reference.test.mjs` | task-042 | `aid-ask` 1, `aid-housekeep` 1, `aid-summarize` 1, `aid-update-kb` 1 |
| 336 | `site/scripts/__tests__/provenance-appender.test.mjs` | task-042 | `aid-ask` 3 |
| 337 | `site/scripts/__tests__/skill-counts.test.mjs` | task-042 | `aid-ask` 2 |
| 338 | `tests/canonical/fixtures/install-core-primitives/manifest-v3.golden.json` | task-042 | `aid-ask` 1 |
| 339 | `tests/canonical/fixtures/install-core-primitives/manifest-v3.model.tsv` | task-042 | `aid-ask` 1 |
| 340 | `tests/canonical/test-catalog-dirs-parity.sh` | task-042 | `aid-ask` 1 |
| 341 | `tests/canonical/test-connector-consumption-linkage.sh` | task-042 | `aid-ask` 1 |
| 342 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-042 | `aid-ask` 1 |
| 343 | `tests/canonical/test-skill-guide.sh` | task-042 | `aid-ask` 1, `aid-housekeep` 1, `aid-summarize` 1, `aid-update-kb` 1 |
| 344 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `aid-ask` 5, `aid-housekeep` 5, `aid-summarize` 5, `aid-update-kb` 5 |
| 345 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `aid-ask` 2, `aid-housekeep` 1, `aid-update-kb` 1 |
| 346 | `tests/conversation/samples/feature-001/001-07-rich-ticket.md` | task-034 | `aid-brainstorm` 1 |
| 347 | `tests/conversation/samples/feature-001/001-08-bare-idea.md` | task-034 | `aid-brainstorm` 1 |
| 348 | `tests/conversation/samples/feature-001/001-09-bug-fix-phases.md` | task-034 | `aid-brainstorm` 1 |
| 349 | `tests/conversation/samples/feature-001/001-14-refactor-is-new-capability.md` | task-034 | `aid-brainstorm` 1 |
| 350 | `tests/canonical/test-chat-node-hub.sh` | task-043 | `aid-chat` 1 |
| 351 | `tests/canonical/test-chat-node-wake.sh` | task-043 | `aid-chat` 3 |
| 352 | `site/scripts/__tests__/gen-reference.test.mjs` | task-043 | `aid-chat` 1, `aid-config` 1, `aid-create-ticket` 1, `aid-deploy` 1, `aid-monitor` 1, `aid-read-ticket` 1, `aid-set-connector` 1, `aid-unset-connector` 1, `aid-update-ticket` 1 |
| 353 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | task-043 | `aid-config` 8, `aid-create-ticket` 4, `aid-read-ticket` 2, `aid-set-connector` 2, `aid-unset-connector` 2, `aid-update-ticket` 2 |
| 354 | `dashboard/reader/tests/test_reader.py` | task-043 | `aid-config` 3 |
| 355 | `dashboard/server/tests/test_server_node.mjs` | task-043 | `aid-config` 1 |
| 356 | `dashboard/server/tests/test_task012_consuming_round_trips.py` | task-043 | `aid-config` 2 |
| 357 | `site/scripts/__tests__/flow-facade.test.mjs` | task-043 | `aid-config` 16 |
| 358 | `site/scripts/__tests__/skills-groups.test.mjs` | task-043 | `aid-config` 7, `aid-deploy` 13, `aid-monitor` 10 |
| 359 | `tests/canonical/test-aid-cli-parity.sh` | task-043 | `aid-config` 2 |
| 360 | `tests/canonical/test-skill-guide.sh` | task-043 | `aid-config` 1, `aid-create-ticket` 1, `aid-update-ticket` 1 |
| 361 | `tests/canonical/test-skill-guide.sh` | task-036 | `aid-create-architecture` 1, `aid-create-backlog` 1, `aid-create-cicd` 1, `aid-create-mvp` 1, `aid-create-roadmap` 1, `aid-create-stack` 1, `aid-create-testing-strategy` 1, `aid-update-architecture` 1, `aid-update-backlog` 1, `aid-update-cicd` 1, `aid-update-mvp` 1, `aid-update-roadmap` 1, `aid-update-stack` 1, `aid-update-testing-strategy` 1 |
| 362 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `aid-create-architecture` 5, `aid-create-backlog` 5, `aid-create-cicd` 5, `aid-create-mvp` 5, `aid-create-roadmap` 5, `aid-create-stack` 5, `aid-create-testing-strategy` 5, `aid-update-architecture` 5, `aid-update-backlog` 5, `aid-update-cicd` 5, `aid-update-mvp` 5, `aid-update-roadmap` 5, `aid-update-stack` 5, `aid-update-testing-strategy` 5 |
| 363 | `tests/canonical/test-work-initiation-gate.sh` | task-044 | `aid-create-document` 3, `aid-prototype` 9, `aid-report` 3, `aid-research` 10, `aid-review` 11, `aid-test` 3, `aid-update-document` 5 |
| 364 | `site/scripts/__tests__/flow-compose.test.mjs` | task-044 | `aid-create-document` 4, `aid-test` 8 |
| 365 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | task-044 | `aid-create-document` 2, `aid-prototype` 1, `aid-report` 2, `aid-research` 1, `aid-review` 5, `aid-test` 5, `aid-update-document` 5 |
| 366 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | task-044 | `aid-create-document` 6, `aid-test` 53 |
| 367 | `tests/canonical/test-create-family-scaffold.sh` | task-044 | `aid-create-document` 3, `aid-report` 3, `aid-review` 1, `aid-test` 3 |
| 368 | `tests/canonical/test-document-family-scaffold.sh` | task-044 | `aid-create-document` 2, `aid-report` 2, `aid-review` 1, `aid-update-document` 1 |
| 369 | `tests/canonical/test-skill-guide.sh` | task-044 | `aid-create-document` 1, `aid-prototype` 1, `aid-test` 2, `aid-update-document` 1 |
| 370 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `aid-create-document` 5, `aid-prototype` 10, `aid-report` 5, `aid-research` 6, `aid-review` 6, `aid-test` 20, `aid-update-document` 5 |
| 371 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `aid-create-document` 3, `aid-prototype` 5, `aid-report` 4, `aid-research` 24, `aid-review` 15, `aid-test` 3, `aid-update-document` 3 |
| 372 | `site/scripts/__tests__/flow-advance.test.mjs` | task-043 | `aid-create-ticket` 4, `aid-deploy` 1 |
| 373 | `tests/canonical/test-ticket-retirement-structural.sh` | task-043 | `aid-create-ticket` 9, `aid-deploy` 10, `aid-monitor` 11, `aid-read-ticket` 9, `aid-set-connector` 1, `aid-update-ticket` 14 |
| 374 | `tests/canonical/test-aid-cli-parity.sh` | task-039 | `aid-define` 1 |
| 375 | `tests/canonical/test-downstream-worktree-entry.sh` | task-039 | `aid-define` 16, `aid-specify` 12 |
| 376 | `tests/canonical/test-shared-prune.sh` | task-039 | `aid-define` 3 |
| 377 | `tests/canonical/test-shared-remove.sh` | task-039 | `aid-define` 7 |
| 378 | `tests/canonical/test-state-review-surface.sh` | task-039 | `aid-define` 1, `aid-specify` 1 |
| 379 | `dashboard/reader/tests/test_work003_state_schema.py` | task-039 | `aid-define` 1 |
| 380 | `site/scripts/__tests__/flow-advance.test.mjs` | task-039 | `aid-define` 4, `aid-specify` 4 |
| 381 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-039 | `aid-define` 8, `aid-specify` 5 |
| 382 | `site/scripts/__tests__/flow-graph.test.mjs` | task-039 | `aid-define` 5 |
| 383 | `site/scripts/__tests__/gen-reference.test.mjs` | task-039 | `aid-define` 1, `aid-specify` 1 |
| 384 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-039 | `aid-define` 1, `aid-specify` 1 |
| 385 | `site/scripts/__tests__/skills-groups.test.mjs` | task-039 | `aid-define` 1, `aid-specify` 1 |
| 386 | `tests/canonical/test-artifact-discipline.sh` | task-039 | `aid-define` 2, `aid-specify` 2 |
| 387 | `tests/canonical/test-scoped-review-cycles.sh` | task-039 | `aid-define` 1, `aid-specify` 5 |
| 388 | `tests/canonical/test-skill-guide.sh` | task-039 | `aid-define` 1 |
| 389 | `tests/canonical/test-work-state-template.sh` | task-039 | `aid-define` 2, `aid-specify` 1 |
| 390 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `aid-define` 5, `aid-specify` 5 |
| 391 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `aid-define` 14, `aid-specify` 16 |
| 392 | `tests/coverage-rehome-allowlist.tsv` | task-039 | `aid-define` 1, `aid-specify` 1 |
| 393 | `tests/canonical/test-downstream-worktree-entry.sh` | task-043 | `aid-deploy` 10 |
| 394 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-043 | `aid-deploy` 1 |
| 395 | `dashboard/server/tests/test_index_html.py` | task-043 | `aid-deploy` 1 |
| 396 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-043 | `aid-deploy` 1, `aid-monitor` 1 |
| 397 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-043 | `aid-deploy` 8, `aid-monitor` 8 |
| 398 | `site/scripts/__tests__/skills-catalog.test.mjs` | task-043 | `aid-deploy` 4, `aid-monitor` 2 |
| 399 | `site/scripts/__tests__/skills-render-index.test.mjs` | task-043 | `aid-deploy` 2, `aid-monitor` 2 |
| 400 | `tests/canonical/test-catalog-dirs-parity.sh` | task-043 | `aid-deploy` 1, `aid-monitor` 1 |
| 401 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-043 | `aid-deploy` 14, `aid-monitor` 21 |
| 402 | `tests/coverage-rehome-allowlist.tsv` | task-043 | `aid-deploy` 1, `aid-read-ticket` 1, `aid-update-ticket` 1 |
| 403 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-038 | `aid-describe` 25 |
| 404 | `tests/canonical/test-cutover-no-dangling.sh` | task-038 | `aid-describe` 3 |
| 405 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-038 | `aid-describe` 3 |
| 406 | `tests/canonical/test-ticket-retirement-structural.sh` | task-038 | `aid-describe` 16 |
| 407 | `tests/canonical/test-work-initiation-gate.sh` | task-038 | `aid-describe` 4 |
| 408 | `tests/canonical/test-work-state-template.sh` | task-038 | `aid-describe` 7 |
| 409 | `dashboard/reader/tests/test_feature009.py` | task-038 | `aid-describe` 1 |
| 410 | `dashboard/reader/tests/test_shortcut_kind_map_cross_runtime_parity.py` | task-038 | `aid-describe` 5 |
| 411 | `dashboard/reader/tests/test_work003_state_schema.py` | task-038 | `aid-describe` 6 |
| 412 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-006-lite-sample/SPEC.md` | task-038 | `aid-describe` 1 |
| 413 | `dashboard/server/tests/test_index_html.py` | task-038 | `aid-describe` 6 |
| 414 | `site/scripts/__tests__/flow-facade.test.mjs` | task-038 | `aid-describe` 8 |
| 415 | `site/scripts/__tests__/flow-graph.test.mjs` | task-038 | `aid-describe` 3 |
| 416 | `site/scripts/__tests__/gen-reference.test.mjs` | task-038 | `aid-describe` 1 |
| 417 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-038 | `aid-describe` 1 |
| 418 | `site/scripts/__tests__/skills-groups.test.mjs` | task-038 | `aid-describe` 3 |
| 419 | `tests/canonical/test-connector-consumption-linkage.sh` | task-038 | `aid-describe` 1 |
| 420 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-038 | `aid-describe` 5 |
| 421 | `tests/canonical/test-describe-full-only.sh` | task-038 | `aid-describe` 9 |
| 422 | `tests/canonical/test-path-fixtures.sh` | task-038 | `aid-describe` 1 |
| 423 | `tests/canonical/test-skill-guide.sh` | task-038 | `aid-describe` 1 |
| 424 | `tests/conversation/fixtures/done-work/.aid/works/work-001-csv-export/STATE.yml` | task-038 | `aid-describe` 1 |
| 425 | `tests/conversation/fixtures/ticket-mid-work/.aid/works/work-001-retry-policy/STATE.yml` | task-038 | `aid-describe` 1 |
| 426 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `aid-describe` 5 |
| 427 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `aid-describe` 12 |
| 428 | `tests/canonical/test-work-initiation-gate.sh` | task-034 | `aid-design` 3 |
| 429 | `site/scripts/__tests__/flow-advance.test.mjs` | task-034 | `aid-design` 1 |
| 430 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | task-034 | `aid-design` 4 |
| 431 | `tests/canonical/test-skill-guide.sh` | task-034 | `aid-design` 5 |
| 432 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `aid-design` 3 |
| 433 | `tests/canonical/test-skill-guide.sh` | task-035 | `aid-design-api` 1, `aid-design-architecture` 1, `aid-design-backlog` 1, `aid-design-cicd` 1, `aid-design-cli` 1, `aid-design-config` 1, `aid-design-dashboard` 1, `aid-design-data-model` 1, `aid-design-data-pipeline` 1, `aid-design-document` 1, `aid-design-infra` 1, `aid-design-integration` 1, `aid-design-job` 1, `aid-design-messaging` 1, `aid-design-mvp` 1, `aid-design-roadmap` 1, `aid-design-stack` 1, `aid-design-test` 1, `aid-design-testing-strategy` 1, `aid-design-theme` 1, `aid-design-ui` 1 |
| 434 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `aid-design-api` 5, `aid-design-architecture` 5, `aid-design-backlog` 5, `aid-design-cicd` 5, `aid-design-cli` 5, `aid-design-config` 5, `aid-design-dashboard` 5, `aid-design-data-model` 5, `aid-design-data-pipeline` 5, `aid-design-document` 5, `aid-design-infra` 5, `aid-design-integration` 5, `aid-design-job` 5, `aid-design-messaging` 5, `aid-design-mvp` 5, `aid-design-roadmap` 5, `aid-design-stack` 5, `aid-design-test` 10, `aid-design-testing-strategy` 5, `aid-design-theme` 5, `aid-design-ui` 5 |
| 435 | `dashboard/reader/tests/test_feature009.py` | task-040 | `aid-detail` 9, `aid-execute` 2 |
| 436 | `tests/canonical/test-artifact-discipline.sh` | task-040 | `aid-detail` 1, `aid-plan` 2 |
| 437 | `tests/canonical/test-downstream-worktree-entry.sh` | task-040 | `aid-detail` 7, `aid-execute` 10, `aid-plan` 7 |
| 438 | `tests/canonical/test-state-review-surface.sh` | task-040 | `aid-detail` 1, `aid-execute` 1, `aid-plan` 1 |
| 439 | `tests/canonical/test-ticket-retirement-structural.sh` | task-040 | `aid-detail` 11, `aid-execute` 23, `aid-plan` 22 |
| 440 | `dashboard/reader/tests/test_flattened_layout_parity.py` | task-040 | `aid-detail` 1, `aid-execute` 1, `aid-plan` 1 |
| 441 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-040 | `aid-detail` 1, `aid-execute` 5, `aid-plan` 1 |
| 442 | `site/scripts/__tests__/gen-reference.test.mjs` | task-040 | `aid-detail` 1, `aid-execute` 1, `aid-plan` 1 |
| 443 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-040 | `aid-detail` 1, `aid-plan` 1 |
| 444 | `site/scripts/__tests__/skills-groups.test.mjs` | task-040 | `aid-detail` 1, `aid-plan` 11 |
| 445 | `tests/canonical/test-derive-waves.sh` | task-040 | `aid-detail` 1 |
| 446 | `tests/canonical/test-scoped-review-cycles.sh` | task-040 | `aid-detail` 1, `aid-plan` 2 |
| 447 | `tests/canonical/test-skill-guide.sh` | task-040 | `aid-detail` 1 |
| 448 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `aid-detail` 5, `aid-execute` 5, `aid-plan` 5 |
| 449 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `aid-detail` 16, `aid-execute` 22, `aid-plan` 19 |
| 450 | `tests/coverage-rehome-allowlist.tsv` | task-040 | `aid-detail` 1, `aid-execute` 1, `aid-plan` 1 |
| 451 | `site/scripts/__tests__/flow-advance.test.mjs` | task-041 | `aid-discover` 2 |
| 452 | `tests/canonical/test-connector-skills-structural.sh` | task-041 | `aid-discover` 5 |
| 453 | `tests/canonical/test-cutover-no-dangling.sh` | task-041 | `aid-discover` 7 |
| 454 | `tests/canonical/test-discovery-doc-ownership.sh` | task-041 | `aid-discover` 2 |
| 455 | `tests/canonical/test-doc-set-mapping.sh` | task-041 | `aid-discover` 1 |
| 456 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-041 | `aid-discover` 1 |
| 457 | `tests/canonical/test-doc-set-read.sh` | task-041 | `aid-discover` 2 |
| 458 | `tests/canonical/test-domain-doc-matrix.sh` | task-041 | `aid-discover` 1 |
| 459 | `tests/canonical/test-expectations-single-source.sh` | task-041 | `aid-discover` 4 |
| 460 | `tests/canonical/test-kb-review-surface.sh` | task-041 | `aid-discover` 2 |
| 461 | `tests/canonical/test-ledger-isolation.sh` | task-041 | `aid-discover` 3 |
| 462 | `tests/canonical/test-output-root-isolation.sh` | task-041 | `aid-discover` 1 |
| 463 | `tests/canonical/test-reconcile-scenarios.sh` | task-041 | `aid-discover` 1 |
| 464 | `tests/canonical/test-release.sh` | task-041 | `aid-discover` 5 |
| 465 | `tests/canonical/test-spine-depth-coverage.sh` | task-041 | `aid-discover` 3 |
| 466 | `tests/canonical/test-state-review-surface.sh` | task-041 | `aid-discover` 1 |
| 467 | `dashboard/reader/tests/test_task066_kb_parity.py` | task-041 | `aid-discover` 2 |
| 468 | `dashboard/server/tests/fixtures/pt023-external-sources/multi-entry.md` | task-041 | `aid-discover` 1 |
| 469 | `dashboard/server/tests/fixtures/pt023-external-sources/placeholder-only.md` | task-041 | `aid-discover` 1 |
| 470 | `dashboard/server/tests/fixtures/pt023-external-sources/single-entry.md` | task-041 | `aid-discover` 1 |
| 471 | `dashboard/server/tests/test_index_html.py` | task-041 | `aid-discover` 3 |
| 472 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-041 | `aid-discover` 1 |
| 473 | `site/scripts/__tests__/gen-reference.test.mjs` | task-041 | `aid-discover` 1 |
| 474 | `site/scripts/__tests__/gen-skills.test.mjs` | task-041 | `aid-discover` 2 |
| 475 | `tests/README.md` | task-041 | `aid-discover` 1 |
| 476 | `tests/canonical/test-conformance-lane-semantics.sh` | task-041 | `aid-discover` 5 |
| 477 | `tests/canonical/test-grade-summary.sh` | task-041 | `aid-discover` 2 |
| 478 | `tests/canonical/test-harvest-batching.sh` | task-041 | `aid-discover` 1 |
| 479 | `tests/canonical/test-kb-template-authoring-standard.sh` | task-041 | `aid-discover` 1 |
| 480 | `tests/canonical/test-path-fixtures.sh` | task-041 | `aid-discover` 1 |
| 481 | `tests/canonical/test-skill-guide.sh` | task-041 | `aid-discover` 1 |
| 482 | `tests/canonical/test-summarize-preflight.sh` | task-041 | `aid-discover` 1 |
| 483 | `tests/canonical/test-ticket-retirement-structural.sh` | task-041 | `aid-discover` 1 |
| 484 | `tests/canonical/test-write-external-source.sh` | task-041 | `aid-discover` 3 |
| 485 | `tests/conversation/samples/feature-001/001-15-no-kb-offers-preparation.md` | task-041 | `aid-discover` 1 |
| 486 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `aid-discover` 5 |
| 487 | `tests/canonical/test-compute-block-radius.sh` | task-040 | `aid-execute` 1 |
| 488 | `tests/canonical/test-delivery-gate-aggregate.sh` | task-040 | `aid-execute` 4 |
| 489 | `tests/canonical/test-task-state-transitions.sh` | task-040 | `aid-execute` 5 |
| 490 | `dashboard/reader/tests/fixtures/task011_golden/flat_golden.json` | task-040 | `aid-execute` 1 |
| 491 | `dashboard/reader/tests/fixtures/task011_golden/hierarchical_golden.json` | task-040 | `aid-execute` 1 |
| 492 | `dashboard/reader/tests/test_fixtures.py` | task-040 | `aid-execute` 5 |
| 493 | `dashboard/reader/tests/test_reader.py` | task-040 | `aid-execute` 10, `aid-plan` 1 |
| 494 | `dashboard/reader/tests/test_resolve_work_dir_cross_runtime_parity.py` | task-040 | `aid-execute` 1 |
| 495 | `dashboard/reader/tests/test_security_hardening.py` | task-040 | `aid-execute` 1 |
| 496 | `dashboard/reader/tests/test_task002_resolve_work_dir.py` | task-040 | `aid-execute` 1 |
| 497 | `dashboard/reader/tests/test_task011_golden_master.py` | task-040 | `aid-execute` 2 |
| 498 | `dashboard/reader/tests/test_task011_reconcile.py` | task-040 | `aid-execute` 3 |
| 499 | `dashboard/reader/tests/test_task014_fixtures.py` | task-040 | `aid-execute` 7 |
| 500 | `dashboard/reader/tests/test_task069_detail_parser.py` | task-040 | `aid-execute` 1 |
| 501 | `dashboard/reader/tests/test_work001_delivery_layouts.py` | task-040 | `aid-execute` 1 |
| 502 | `dashboard/reader/tests/test_work003_state_schema.py` | task-040 | `aid-execute` 5 |
| 503 | `dashboard/reader/tests/test_work016_container_discovery.py` | task-040 | `aid-execute` 1 |
| 504 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-001-running-parallel/STATE.md` | task-040 | `aid-execute` 1 |
| 505 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-001-running-parallel/STATE.yml` | task-040 | `aid-execute` 1 |
| 506 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-003-blocked/STATE.md` | task-040 | `aid-execute` 1 |
| 507 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-003-blocked/STATE.yml` | task-040 | `aid-execute` 1 |
| 508 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-006-lite-sample/STATE.md` | task-040 | `aid-execute` 1 |
| 509 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-006-lite-sample/STATE.yml` | task-040 | `aid-execute` 1 |
| 510 | `dashboard/server/tests/fixtures/pt1h-detail-repo/.aid/works/work-001-detail/STATE.yml` | task-040 | `aid-execute` 1 |
| 511 | `dashboard/server/tests/fixtures/pt1h-repo-a/.aid/works/work-001-with-unicode/STATE.md` | task-040 | `aid-execute` 1 |
| 512 | `dashboard/server/tests/fixtures/pt1h-repo-b/.aid/works/work-001-minimal/STATE.md` | task-040 | `aid-execute` 1 |
| 513 | `dashboard/server/tests/test_reader_task069.mjs` | task-040 | `aid-execute` 2 |
| 514 | `dashboard/server/tests/test_task002_resolve_work_dir.mjs` | task-040 | `aid-execute` 1 |
| 515 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | task-040 | `aid-execute` 1 |
| 516 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-040 | `aid-execute` 4 |
| 517 | `site/scripts/__tests__/flow-render-mermaid.test.mjs` | task-040 | `aid-execute` 2 |
| 518 | `site/scripts/__tests__/gen-skills.test.mjs` | task-040 | `aid-execute` 1 |
| 519 | `site/src/lib/__tests__/skill-node-panel.test.ts` | task-040 | `aid-execute` 1, `aid-plan` 4 |
| 520 | `tests/README.md` | task-040 | `aid-execute` 2 |
| 521 | `tests/canonical/fixtures/migrate/fixture-source/work-999-migration-test/STATE.md` | task-040 | `aid-execute` 1 |
| 522 | `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/STATE.md` | task-040 | `aid-execute` 1 |
| 523 | `tests/canonical/test-change-refactor-family-scaffold.sh` | task-040 | `aid-execute` 2 |
| 524 | `tests/canonical/test-connector-consumption-linkage.sh` | task-040 | `aid-execute` 2, `aid-plan` 1 |
| 525 | `tests/canonical/test-conversation-runner.sh` | task-040 | `aid-execute` 4, `aid-plan` 2 |
| 526 | `tests/canonical/test-create-family-scaffold.sh` | task-040 | `aid-execute` 2 |
| 527 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-040 | `aid-execute` 1 |
| 528 | `tests/canonical/test-disjoint-merge.sh` | task-040 | `aid-execute` 3 |
| 529 | `tests/canonical/test-document-family-scaffold.sh` | task-040 | `aid-execute` 2 |
| 530 | `tests/canonical/test-fix-family-scaffold.sh` | task-040 | `aid-execute` 1 |
| 531 | `tests/canonical/test-kb-no-work-ids.sh` | task-040 | `aid-execute` 3 |
| 532 | `tests/canonical/test-producer-completeness.sh` | task-040 | `aid-execute` 1 |
| 533 | `tests/canonical/test-prototype-family-scaffold.sh` | task-040 | `aid-execute` 2 |
| 534 | `tests/canonical/test-test-experiment-family-scaffold.sh` | task-040 | `aid-execute` 3 |
| 535 | `tests/canonical/test-work-initiation-gate.sh` | task-040 | `aid-execute` 3, `aid-plan` 3 |
| 536 | `tests/canonical/test-writeback-state.sh` | task-040 | `aid-execute` 5 |
| 537 | `tests/conversation/fixtures/done-work/.aid/works/work-001-csv-export/STATE.yml` | task-040 | `aid-execute` 1 |
| 538 | `tests/cost-meter.py` | task-040 | `aid-execute` 1 |
| 539 | `tests/canonical/test-conformance-lane-semantics.sh` | task-042 | `aid-housekeep` 1 |
| 540 | `tests/canonical/test-f010-governance-guards.sh` | task-042 | `aid-housekeep` 2, `aid-update-kb` 4 |
| 541 | `tests/canonical/test-output-root-isolation.sh` | task-042 | `aid-housekeep` 1 |
| 542 | `dashboard/server/tests/test_index_html.py` | task-042 | `aid-housekeep` 7 |
| 543 | `site/scripts/__tests__/flow-advance.test.mjs` | task-042 | `aid-housekeep` 1, `aid-summarize` 1, `aid-update-kb` 2 |
| 544 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-042 | `aid-housekeep` 1, `aid-summarize` 1, `aid-update-kb` 3 |
| 545 | `site/scripts/__tests__/flow-graph.test.mjs` | task-042 | `aid-housekeep` 2, `aid-update-kb` 3 |
| 546 | `tests/canonical/test-connector-skills-structural.sh` | task-042 | `aid-housekeep` 2 |
| 547 | `tests/canonical/test-doc-counts.sh` | task-042 | `aid-housekeep` 2 |
| 548 | `tests/canonical/test-worktree-lifecycle.sh` | task-042 | `aid-housekeep` 1 |
| 549 | `tests/coverage-accepted-removals.tsv` | task-043 | `aid-monitor` 2 |
| 550 | `tests/canonical/test-document-family-scaffold.sh` | task-043 | `aid-monitor` 1 |
| 551 | `site/scripts/__tests__/gen-reference.test.mjs` | task-032 | `aid-orchestrate` 1 |
| 552 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-032 | `aid-orchestrate` 4 |
| 553 | `site/scripts/__tests__/skills-groups.test.mjs` | task-032 | `aid-orchestrate` 10 |
| 554 | `site/scripts/__tests__/skills-render-index.test.mjs` | task-032 | `aid-orchestrate` 4 |
| 555 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `aid-orchestrate` 5 |
| 556 | `tests/canonical/test-aid-migrate.sh` | task-040 | `aid-plan` 2 |
| 557 | `tests/canonical/test-multitool-isolation.sh` | task-040 | `aid-plan` 4 |
| 558 | `tests/windows/Test-AidInstaller.ps1` | task-040 | `aid-plan` 4 |
| 559 | `tests/canonical/test-review-path-audit.sh` | task-040 | `aid-plan` 2 |
| 560 | `site/scripts/__tests__/flow-advance.test.mjs` | task-044 | `aid-prototype` 1, `aid-report` 1, `aid-research` 1, `aid-test` 7 |
| 561 | `tests/canonical/test-prototype-family-scaffold.sh` | task-044 | `aid-prototype` 54, `aid-review` 1, `aid-test` 4 |
| 562 | `site/scripts/__tests__/gen-skills.test.mjs` | task-043 | `aid-read-ticket` 4 |
| 563 | `site/scripts/__tests__/skills-render-value.test.mjs` | task-043 | `aid-read-ticket` 6 |
| 564 | `site/scripts/__tests__/skills-render-page.test.mjs` | task-043 | `aid-read-ticket` 2 |
| 565 | `tests/canonical/test-connector-consumption-linkage.sh` | task-043 | `aid-read-ticket` 1 |
| 566 | `tests/canonical/test-ticket-retirement-structural.sh` | task-044 | `aid-report` 3, `aid-research` 10, `aid-review` 12 |
| 567 | `tests/canonical/fixtures/actback-task/data-ml.tsv` | task-044 | `aid-research` 4 |
| 568 | `tests/canonical/fixtures/actback-task/design.tsv` | task-044 | `aid-research` 3 |
| 569 | `tests/canonical/fixtures/actback-task/docset-check.tsv` | task-044 | `aid-research` 5 |
| 570 | `tests/canonical/fixtures/actback-task/docset-component.tsv` | task-044 | `aid-research` 2 |
| 571 | `tests/canonical/fixtures/actback-task/docset-contract.tsv` | task-044 | `aid-research` 2 |
| 572 | `tests/canonical/fixtures/actback-task/docset-endpoint.tsv` | task-044 | `aid-research` 1 |
| 573 | `tests/canonical/fixtures/actback-task/docset-feature.tsv` | task-044 | `aid-research` 1 |
| 574 | `tests/canonical/fixtures/actback-task/docset-module.tsv` | task-044 | `aid-research` 2 |
| 575 | `tests/canonical/fixtures/actback-task/docset-optin.tsv` | task-044 | `aid-research` 1 |
| 576 | `tests/canonical/fixtures/dual-intent/content/doc-set.tsv` | task-044 | `aid-research` 6 |
| 577 | `tests/canonical/fixtures/dual-intent/content/good-kb/authoring-conventions.md` | task-044 | `aid-research` 1 |
| 578 | `tests/canonical/fixtures/dual-intent/content/good-kb/content-inventory.md` | task-044 | `aid-research` 1 |
| 579 | `tests/canonical/fixtures/dual-intent/content/good-kb/content-map.md` | task-044 | `aid-research` 1 |
| 580 | `tests/canonical/fixtures/dual-intent/content/good-kb/content-model.md` | task-044 | `aid-research` 1 |
| 581 | `tests/canonical/fixtures/dual-intent/content/good-kb/decisions.md` | task-044 | `aid-research` 1 |
| 582 | `tests/canonical/fixtures/dual-intent/content/good-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 583 | `tests/canonical/fixtures/dual-intent/content/shallow-kb/authoring-conventions.md` | task-044 | `aid-research` 1 |
| 584 | `tests/canonical/fixtures/dual-intent/content/shallow-kb/content-inventory.md` | task-044 | `aid-research` 1 |
| 585 | `tests/canonical/fixtures/dual-intent/content/shallow-kb/content-map.md` | task-044 | `aid-research` 1 |
| 586 | `tests/canonical/fixtures/dual-intent/content/shallow-kb/content-model.md` | task-044 | `aid-research` 1 |
| 587 | `tests/canonical/fixtures/dual-intent/content/shallow-kb/decisions.md` | task-044 | `aid-research` 1 |
| 588 | `tests/canonical/fixtures/dual-intent/content/shallow-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 589 | `tests/canonical/fixtures/dual-intent/content/wrong-kb/authoring-conventions.md` | task-044 | `aid-research` 1 |
| 590 | `tests/canonical/fixtures/dual-intent/content/wrong-kb/content-inventory.md` | task-044 | `aid-research` 1 |
| 591 | `tests/canonical/fixtures/dual-intent/content/wrong-kb/content-map.md` | task-044 | `aid-research` 1 |
| 592 | `tests/canonical/fixtures/dual-intent/content/wrong-kb/content-model.md` | task-044 | `aid-research` 1 |
| 593 | `tests/canonical/fixtures/dual-intent/content/wrong-kb/decisions.md` | task-044 | `aid-research` 1 |
| 594 | `tests/canonical/fixtures/dual-intent/content/wrong-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 595 | `tests/canonical/fixtures/dual-intent/data-ml/doc-set.tsv` | task-044 | `aid-research` 6 |
| 596 | `tests/canonical/fixtures/dual-intent/data-ml/good-kb/coding-standards.md` | task-044 | `aid-research` 1 |
| 597 | `tests/canonical/fixtures/dual-intent/data-ml/good-kb/data-pipeline.md` | task-044 | `aid-research` 1 |
| 598 | `tests/canonical/fixtures/dual-intent/data-ml/good-kb/data-schemas.md` | task-044 | `aid-research` 1 |
| 599 | `tests/canonical/fixtures/dual-intent/data-ml/good-kb/decisions.md` | task-044 | `aid-research` 1 |
| 600 | `tests/canonical/fixtures/dual-intent/data-ml/good-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 601 | `tests/canonical/fixtures/dual-intent/data-ml/good-kb/model-cards.md` | task-044 | `aid-research` 1 |
| 602 | `tests/canonical/fixtures/dual-intent/data-ml/shallow-kb/coding-standards.md` | task-044 | `aid-research` 1 |
| 603 | `tests/canonical/fixtures/dual-intent/data-ml/shallow-kb/data-pipeline.md` | task-044 | `aid-research` 1 |
| 604 | `tests/canonical/fixtures/dual-intent/data-ml/shallow-kb/data-schemas.md` | task-044 | `aid-research` 1 |
| 605 | `tests/canonical/fixtures/dual-intent/data-ml/shallow-kb/decisions.md` | task-044 | `aid-research` 1 |
| 606 | `tests/canonical/fixtures/dual-intent/data-ml/shallow-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 607 | `tests/canonical/fixtures/dual-intent/data-ml/shallow-kb/model-cards.md` | task-044 | `aid-research` 1 |
| 608 | `tests/canonical/fixtures/dual-intent/data-ml/wrong-kb/coding-standards.md` | task-044 | `aid-research` 1 |
| 609 | `tests/canonical/fixtures/dual-intent/data-ml/wrong-kb/data-pipeline.md` | task-044 | `aid-research` 1 |
| 610 | `tests/canonical/fixtures/dual-intent/data-ml/wrong-kb/data-schemas.md` | task-044 | `aid-research` 1 |
| 611 | `tests/canonical/fixtures/dual-intent/data-ml/wrong-kb/decisions.md` | task-044 | `aid-research` 1 |
| 612 | `tests/canonical/fixtures/dual-intent/data-ml/wrong-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 613 | `tests/canonical/fixtures/dual-intent/data-ml/wrong-kb/model-cards.md` | task-044 | `aid-research` 1 |
| 614 | `tests/canonical/fixtures/dual-intent/design/doc-set.tsv` | task-044 | `aid-research` 6 |
| 615 | `tests/canonical/fixtures/dual-intent/design/good-kb/component-inventory.md` | task-044 | `aid-research` 1 |
| 616 | `tests/canonical/fixtures/dual-intent/design/good-kb/decisions.md` | task-044 | `aid-research` 1 |
| 617 | `tests/canonical/fixtures/dual-intent/design/good-kb/design-overview.md` | task-044 | `aid-research` 1 |
| 618 | `tests/canonical/fixtures/dual-intent/design/good-kb/design-principles.md` | task-044 | `aid-research` 1 |
| 619 | `tests/canonical/fixtures/dual-intent/design/good-kb/design-tokens.md` | task-044 | `aid-research` 1 |
| 620 | `tests/canonical/fixtures/dual-intent/design/good-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 621 | `tests/canonical/fixtures/dual-intent/design/shallow-kb/component-inventory.md` | task-044 | `aid-research` 1 |
| 622 | `tests/canonical/fixtures/dual-intent/design/shallow-kb/decisions.md` | task-044 | `aid-research` 1 |
| 623 | `tests/canonical/fixtures/dual-intent/design/shallow-kb/design-overview.md` | task-044 | `aid-research` 1 |
| 624 | `tests/canonical/fixtures/dual-intent/design/shallow-kb/design-principles.md` | task-044 | `aid-research` 1 |
| 625 | `tests/canonical/fixtures/dual-intent/design/shallow-kb/design-tokens.md` | task-044 | `aid-research` 1 |
| 626 | `tests/canonical/fixtures/dual-intent/design/shallow-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 627 | `tests/canonical/fixtures/dual-intent/design/wrong-kb/component-inventory.md` | task-044 | `aid-research` 1 |
| 628 | `tests/canonical/fixtures/dual-intent/design/wrong-kb/decisions.md` | task-044 | `aid-research` 1 |
| 629 | `tests/canonical/fixtures/dual-intent/design/wrong-kb/design-overview.md` | task-044 | `aid-research` 1 |
| 630 | `tests/canonical/fixtures/dual-intent/design/wrong-kb/design-principles.md` | task-044 | `aid-research` 1 |
| 631 | `tests/canonical/fixtures/dual-intent/design/wrong-kb/design-tokens.md` | task-044 | `aid-research` 1 |
| 632 | `tests/canonical/fixtures/dual-intent/design/wrong-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 633 | `tests/canonical/fixtures/kb-essence/actback/representative-task-fixture/doc-set.tsv` | task-044 | `aid-research` 4 |
| 634 | `tests/canonical/test-actback-task.sh` | task-044 | `aid-research` 3 |
| 635 | `tests/canonical/test-change-refactor-family-scaffold.sh` | task-044 | `aid-research` 2, `aid-review` 3, `aid-test` 1 |
| 636 | `tests/canonical/test-connector-consumption-linkage.sh` | task-044 | `aid-research` 1 |
| 637 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-044 | `aid-research` 3 |
| 638 | `tests/canonical/test-discovery-doc-ownership.sh` | task-044 | `aid-research` 39 |
| 639 | `tests/canonical/test-doc-set-mapping.sh` | task-044 | `aid-research` 56 |
| 640 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-044 | `aid-research` 14 |
| 641 | `tests/canonical/test-doc-set-read.sh` | task-044 | `aid-research` 44 |
| 642 | `tests/canonical/test-grade-summary.sh` | task-044 | `aid-research` 5 |
| 643 | `tests/canonical/test-update-kb-scope-fidelity.sh` | task-044 | `aid-research` 2 |
| 644 | `site/scripts/__tests__/flow-facade.test.mjs` | task-044 | `aid-review` 20, `aid-test` 1 |
| 645 | `site/scripts/__tests__/flow-graph.test.mjs` | task-044 | `aid-review` 7, `aid-test` 70 |
| 646 | `site/scripts/__tests__/provenance.test.mjs` | task-044 | `aid-review` 8, `aid-test` 2 |
| 647 | `site/scripts/__tests__/skills-render-page.test.mjs` | task-044 | `aid-review` 8, `aid-test` 10 |
| 648 | `tests/canonical/test-review-path-audit.sh` | task-044 | `aid-review` 10 |
| 649 | `dashboard/reader/tests/test_work003_state_schema.py` | task-044 | `aid-review` 1 |
| 650 | `site/scripts/__tests__/flow-classify.test.mjs` | task-044 | `aid-review` 6, `aid-test` 12 |
| 651 | `site/scripts/__tests__/provenance-appender.test.mjs` | task-044 | `aid-review` 12 |
| 652 | `site/scripts/__tests__/skills-body.test.mjs` | task-044 | `aid-review` 3 |
| 653 | `tests/README.md` | task-044 | `aid-review` 1 |
| 654 | `tests/canonical/test-aid-update-dry-run-plan.sh` | task-044 | `aid-review` 13 |
| 655 | `tests/canonical/test-artifact-discipline.sh` | task-044 | `aid-review` 1 |
| 656 | `tests/canonical/test-conversation-runner.sh` | task-044 | `aid-review` 1 |
| 657 | `tests/canonical/test-cost-meter.sh` | task-044 | `aid-review` 5 |
| 658 | `tests/canonical/test-criterion-oracles.sh` | task-044 | `aid-review` 2 |
| 659 | `tests/canonical/test-cutover-no-dangling.sh` | task-044 | `aid-review` 1 |
| 660 | `tests/canonical/test-describe-full-only.sh` | task-044 | `aid-review` 1 |
| 661 | `tests/canonical/test-expectations-single-source.sh` | task-044 | `aid-review` 11 |
| 662 | `tests/canonical/test-fix-family-scaffold.sh` | task-044 | `aid-review` 1, `aid-test` 2 |
| 663 | `tests/canonical/test-release.sh` | task-044 | `aid-review` 1 |
| 664 | `tests/canonical/test-severity-why-line.sh` | task-044 | `aid-review` 1 |
| 665 | `tests/canonical/test-test-experiment-family-scaffold.sh` | task-044 | `aid-review` 1, `aid-test` 38 |
| 666 | `tests/canonical/test-writeback-state.sh` | task-044 | `aid-review` 2 |
| 667 | `tests/conversation/run.py` | task-044 | `aid-review` 2 |
| 668 | `tests/cost-meter.py` | task-044 | `aid-review` 1 |
| 669 | `tests/canonical/test-connector-set-unset-lifecycle.sh` | task-043 | `aid-set-connector` 8, `aid-unset-connector` 5 |
| 670 | `tests/canonical/test-write-connector.sh` | task-043 | `aid-set-connector` 1, `aid-unset-connector` 1 |
| 671 | `tests/canonical/test-ticket-retirement-structural.sh` | task-039 | `aid-specify` 6 |
| 672 | `dashboard/reader/tests/test_fixtures.py` | task-039 | `aid-specify` 1 |
| 673 | `dashboard/reader/tests/test_flattened_layout_parity.py` | task-039 | `aid-specify` 1 |
| 674 | `dashboard/reader/tests/test_reader.py` | task-039 | `aid-specify` 1 |
| 675 | `dashboard/reader/tests/test_task014_fixtures.py` | task-039 | `aid-specify` 2 |
| 676 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-002-paused/STATE.md` | task-039 | `aid-specify` 1 |
| 677 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-002-paused/STATE.yml` | task-039 | `aid-specify` 1 |
| 678 | `tests/canonical/test-connector-consumption-linkage.sh` | task-039 | `aid-specify` 1 |
| 679 | `tests/canonical/test-writeback-state.sh` | task-039 | `aid-specify` 2 |
| 680 | `tests/conversation/fixtures/ticket-mid-work/.aid/works/work-001-retry-policy/STATE.yml` | task-039 | `aid-specify` 1 |
| 681 | `tests/conversation/samples/feature-001/001-15-no-kb-offers-preparation.md` | task-039 | `aid-specify` 1 |
| 682 | `tests/canonical/test-grade-summary.sh` | task-042 | `aid-summarize` 4 |
| 683 | `tests/canonical/test-guardrails-d012.sh` | task-042 | `aid-summarize` 2 |
| 684 | `tests/canonical/test-ledger-isolation.sh` | task-042 | `aid-summarize` 2 |
| 685 | `tests/canonical/test-shared-prune.sh` | task-042 | `aid-summarize` 1 |
| 686 | `site/scripts/__tests__/flow-facade.test.mjs` | task-042 | `aid-summarize` 1 |
| 687 | `site/scripts/__tests__/flow-render-mermaid.test.mjs` | task-044 | `aid-test` 1 |
| 688 | `site/scripts/__tests__/flow-validate.test.mjs` | task-044 | `aid-test` 18 |
| 689 | `site/scripts/__tests__/provenance-render-list.test.mjs` | task-044 | `aid-test` 7 |
| 690 | `site/scripts/__tests__/skills-discover.test.mjs` | task-044 | `aid-test` 55 |
| 691 | `dashboard/server/tests/test_reader_task069.mjs` | task-044 | `aid-test` 1 |
| 692 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | task-044 | `aid-test` 1, `aid-update-document` 1 |
| 693 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-044 | `aid-test` 25 |
| 694 | `site/scripts/__tests__/skills-summary.test.mjs` | task-044 | `aid-test` 10 |
| 695 | `tests/canonical/test-disjoint-merge.sh` | task-044 | `aid-test` 1 |
| 696 | `tests/canonical/test-migrate-kb-frontmatter.sh` | task-044 | `aid-test` 1 |
| 697 | `tests/canonical/test-release-install-e2e.sh` | task-044 | `aid-test` 3 |
| 698 | `tests/canonical/test-update-kb-scope-fidelity.sh` | task-042 | `aid-update-kb` 11 |
| 699 | `site/scripts/__tests__/gen-skills.test.mjs` | task-042 | `aid-update-kb` 9 |
| 700 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | history, left as is | `aid-create` 7, `aid-document` 6, `aid-document-architecture` 3, `aid-document-changelog` 2, `aid-test-data-quality` 1, `aid-test-performance` 3, `aid-test-security` 17 |
| 701 | `dashboard/reader/tests/test_work003_state_schema.py` | history, left as is | `aid-create` 4, `aid-create-api` 2, `aid-create-data-model` 1, `aid-refactor` 9 |
| 702 | `site/scripts/__tests__/flow-advance.test.mjs` | history, left as is | `aid-create` 4, `aid-fix` 4, `aid-update` 2 |
| 703 | `site/scripts/__tests__/flow-classify.test.mjs` | history, left as is | `aid-create` 3, `aid-test-security` 6 |
| 704 | `site/scripts/__tests__/flow-compose.test.mjs` | history, left as is | `aid-create` 14, `aid-create-api` 10, `aid-document` 1, `aid-fix` 4, `aid-test-performance` 1, `aid-test-security` 4 |
| 705 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | history, left as is | `aid-create` 12, `aid-create-api` 12, `aid-fix` 5 |
| 706 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | history, left as is | `aid-create` 2, `aid-update` 5 |
| 707 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | history, left as is | `aid-create` 5, `aid-deprecate` 1, `aid-document` 2, `aid-document-runbook` 1, `aid-fix` 3, `aid-test-security` 1, `aid-update` 4, `aid-update-api` 1 |
| 708 | `site/scripts/__tests__/flow-facade.test.mjs` | history, left as is | `aid-create` 8, `aid-document` 4, `aid-document-architecture` 4, `aid-test-security` 1 |
| 709 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | history, left as is | `aid-create` 27, `aid-create-api` 23, `aid-document` 1, `aid-fix` 5, `aid-test-security` 18 |
| 710 | `site/scripts/__tests__/gen-reference.test.mjs` | history, left as is | `aid-create` 1, `aid-update` 2 |
| 711 | `site/scripts/__tests__/provenance-appender.test.mjs` | history, left as is | `aid-create` 6, `aid-create-api` 6 |
| 712 | `site/scripts/__tests__/provenance-deep-link.test.mjs` | history, left as is | `aid-create` 1, `aid-create-api` 1 |
| 713 | `site/scripts/__tests__/skills-body.test.mjs` | history, left as is | `aid-create` 1, `aid-create-api` 1, `aid-fix` 3 |
| 714 | `site/scripts/__tests__/skills-paths.test.mjs` | history, left as is | `aid-create` 6, `aid-create-api` 6 |
| 715 | `site/scripts/__tests__/skills-render-page.test.mjs` | history, left as is | `aid-create` 2, `aid-create-api` 2 |
| 716 | `tests/canonical/test-change-refactor-family-scaffold.sh` | history, left as is | `aid-create` 2, `aid-deprecate` 16, `aid-document` 2, `aid-fix` 5, `aid-migrate` 18, `aid-refactor` 37, `aid-remove` 27, `aid-update` 41, `aid-update-api` 22, `aid-update-data-model` 9 |
| 717 | `tests/canonical/test-create-family-scaffold.sh` | history, left as is | `aid-create` 39, `aid-create-api` 22, `aid-create-dashboard` 3, `aid-create-data-model` 11, `aid-experiment` 2, `aid-update` 2 |
| 718 | `tests/canonical/test-document-family-scaffold.sh` | history, left as is | `aid-create` 3, `aid-create-diagram` 1, `aid-document` 57, `aid-document-architecture` 4, `aid-document-changelog` 4, `aid-document-decision` 20, `aid-document-guideline` 4, `aid-document-runbook` 16, `aid-document-standard` 4, `aid-document-tutorial` 4, `aid-refactor` 1, `aid-update` 3, `aid-update-infra` 2 |
| 719 | `tests/canonical/test-prototype-family-scaffold.sh` | history, left as is | `aid-create` 6, `aid-experiment` 4, `aid-prototype-ui` 27, `aid-update` 6 |
| 720 | `tests/canonical/test-review-path-audit.sh` | history, left as is | `aid-create` 2 |
| 721 | `tests/canonical/test-skill-guide.sh` | history, left as is | `aid-create` 6, `aid-create-api` 1, `aid-create-cli` 1, `aid-create-config` 1, `aid-create-dashboard` 1, `aid-create-data-model` 1, `aid-create-data-pipeline` 1, `aid-create-diagram` 1, `aid-create-infra` 1, `aid-create-integration` 1, `aid-create-job` 1, `aid-create-messaging` 1, `aid-create-test` 1, `aid-create-theme` 1, `aid-create-ui` 1, `aid-deprecate` 1, `aid-document` 2, `aid-document-architecture` 1, `aid-document-changelog` 1, `aid-document-decision` 1, `aid-document-guideline` 1, `aid-document-runbook` 1, `aid-document-standard` 1, `aid-document-tutorial` 1, `aid-experiment` 1, `aid-migrate` 1, `aid-prototype-ui` 1, `aid-remove` 1, `aid-test-data-quality` 1, `aid-test-performance` 1, `aid-test-security` 1, `aid-update` 5, `aid-update-api` 1, `aid-update-cli` 1, `aid-update-config` 1, `aid-update-dashboard` 1, `aid-update-data-model` 1, `aid-update-data-pipeline` 1, `aid-update-infra` 1, `aid-update-integration` 1, `aid-update-job` 1, `aid-update-messaging` 1, `aid-update-test` 1, `aid-update-theme` 1, `aid-update-ui` 1 |
| 722 | `tests/canonical/test-test-experiment-family-scaffold.sh` | history, left as is | `aid-create` 5, `aid-create-test` 1, `aid-experiment` 20, `aid-fix` 15, `aid-test-data-quality` 2, `aid-test-performance` 2, `aid-test-security` 17, `aid-update` 2, `aid-update-test` 1 |
| 723 | `tests/canonical/test-ticket-retirement-structural.sh` | history, left as is | `aid-create` 9, `aid-update` 14 |
| 724 | `tests/canonical/test-ticket-skills-structural.sh` | history, left as is | `aid-create` 35, `aid-update` 32 |
| 725 | `tests/canonical/test-work-initiation-gate.sh` | history, left as is | `aid-create` 3, `aid-update` 5 |
| 726 | `tests/cost-baseline.tsv` | baseline, re-recorded at the gate | `aid-create` 120, `aid-create-api` 5, `aid-create-cli` 5, `aid-create-config` 5, `aid-create-dashboard` 5, `aid-create-data-model` 5, `aid-create-data-pipeline` 5, `aid-create-diagram` 5, `aid-create-infra` 5, `aid-create-integration` 5, `aid-create-job` 5, `aid-create-messaging` 5, `aid-create-test` 10, `aid-create-theme` 5, `aid-create-ui` 5, `aid-deprecate` 5, `aid-document` 40, `aid-document-architecture` 5, `aid-document-changelog` 5, `aid-document-decision` 5, `aid-document-guideline` 5, `aid-document-runbook` 5, `aid-document-standard` 5, `aid-document-tutorial` 5, `aid-experiment` 5, `aid-fix` 5, `aid-migrate` 5, `aid-prototype-ui` 5, `aid-refactor` 5, `aid-remove` 5, `aid-test-data-quality` 5, `aid-test-performance` 5, `aid-test-security` 5, `aid-update` 120, `aid-update-api` 5, `aid-update-cli` 5, `aid-update-config` 5, `aid-update-dashboard` 5, `aid-update-data-model` 5, `aid-update-data-pipeline` 5, `aid-update-infra` 5, `aid-update-integration` 5, `aid-update-job` 5, `aid-update-messaging` 5, `aid-update-test` 10, `aid-update-theme` 5, `aid-update-ui` 5 |
| 727 | `tests/coverage-baseline.tsv` | baseline, re-recorded at the gate | `aid-create` 36, `aid-migrate` 273, `aid-refactor` 1, `aid-update` 29 |
| 728 | `tests/canonical/test-fix-family-scaffold.sh` | history, left as is | `aid-document` 1, `aid-document-runbook` 1, `aid-fix` 28, `aid-refactor` 1, `aid-test-security` 2, `aid-update` 4, `aid-update-infra` 3 |
| 729 | `tests/canonical/test-multitool-isolation.sh` | history, left as is | `aid-fix` 3 |
| 730 | `tests/windows/Test-AidInstaller.ps1` | history, left as is | `aid-fix` 2 |
| 731 | `dashboard/reader/tests/test_declared_path_three_way_parity.py` | history, left as is | `aid-fix` 2 |
| 732 | `dashboard/server/tests/test_server_node.mjs` | history, left as is | `aid-fix` 2 |
| 733 | `dashboard/server/tests/test_server_py.py` | history, left as is | `aid-fix` 2 |
| 734 | `site/scripts/__tests__/flow-render-mermaid.test.mjs` | history, left as is | `aid-fix` 2 |
| 735 | `site/scripts/__tests__/provenance-render-list.test.mjs` | history, left as is | `aid-fix` 1 |
| 736 | `site/scripts/__tests__/skill-node-panel-panel.test.mjs` | history, left as is | `aid-fix` 1 |
| 737 | `site/scripts/__tests__/skills-catalog.test.mjs` | history, left as is | `aid-fix` 4 |
| 738 | `site/src/lib/__tests__/skill-node-panel.dom.test.ts` | history, left as is | `aid-fix` 1 |
| 739 | `tests/canonical/test-connector-consumption-linkage.sh` | history, left as is | `aid-fix` 2 |
| 740 | `tests/conversation/samples/feature-001/001-01-one-match.md` | history, left as is | `aid-fix` 1 |
| 741 | `tests/coverage-accepted-removals.tsv` | history, left as is | `aid-fix` 1, `aid-migrate` 200 |
| 742 | `dashboard/reader/tests/test_task011_golden_master.py` | history, left as is | `aid-migrate` 2, `aid-refactor` 1 |
| 743 | `tests/canonical/test-aid-cli-parity.sh` | history, left as is | `aid-migrate` 2, `aid-update` 3 |
| 744 | `tests/canonical/test-aid-migrate-trigger.sh` | history, left as is | `aid-migrate` 2 |
| 745 | `tests/canonical/test-aid-migrate.sh` | history, left as is | `aid-migrate` 2 |
| 746 | `tests/canonical/test-release-migrate-smoke.sh` | history, left as is | `aid-migrate` 4 |
| 747 | `tests/coverage-parity.sh` | history, left as is | `aid-migrate` 3 |
| 748 | `tests/coverage-rehome-allowlist.tsv` | history, left as is | `aid-migrate` 3, `aid-update` 1 |
| 749 | `tests/run-all.sh` | history, left as is | `aid-migrate` 1 |
| 750 | `dashboard/reader/tests/test_flattened_layout_parity.py` | history, left as is | `aid-refactor` 1 |
| 751 | `tests/canonical/fixtures/state-yaml-conformance/shape-s2-mapping-of-scalars.expected.json` | history, left as is | `aid-refactor` 1 |
| 752 | `tests/canonical/fixtures/state-yaml-conformance/shape-s2-mapping-of-scalars.yml` | history, left as is | `aid-refactor` 1 |
| 753 | `tests/canonical/test-task-state-transitions.sh` | history, left as is | `aid-refactor` 1 |
| 754 | `tests/canonical/test-writeback-state.sh` | history, left as is | `aid-refactor` 4 |
| 755 | `tests/conversation/samples/feature-001/001-14-refactor-is-new-capability.md` | history, left as is | `aid-refactor` 1 |
| 756 | `dashboard/server/tests/test_task017_registry_tooling_round_trips.py` | history, left as is | `aid-update` 1 |
| 757 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | history, left as is | `aid-update` 3 |
| 758 | `site/scripts/__tests__/flow-graph.test.mjs` | history, left as is | `aid-update` 3 |
| 759 | `site/scripts/__tests__/gen-skills.test.mjs` | history, left as is | `aid-update` 9 |
| 760 | `tests/canonical/test-f010-governance-guards.sh` | history, left as is | `aid-update` 4 |
| 761 | `tests/canonical/test-update-kb-scope-fidelity.sh` | history, left as is | `aid-update` 11 |

## P9 Suites that feed old phase names to a writer, or assert reader phase output

Command (run from the repo root; the second line adds the writer-fed `_produce("Phase", ...)` calls of `test_integration.py`, which the first does not match):

```bash
# P9: old phase names fed to a writer, or asserted as reader phase output (run from the repo root)
OLD='(Describe|Define|Specify|Plan|Detail|Execute)'
git grep -n -E -e "Phase\.$OLD\b" -e "--field Phase --value" -e "--phase $OLD\b" -e "phase:? *['\"]$OLD['\"]" -e "phase *(===|==|!==|=) *['\"]$OLD['\"]" -e "phase\"?: *\"$OLD\"" -e "\"$OLD\" *(:|,)" -- tests site/scripts/__tests__ site/src/lib/__tests__ dashboard/reader/tests dashboard/server/tests
git grep -n -E -e "\"(Execute|Specify)\"" -e "'(Execute|Specify)'" -- dashboard/reader/tests/test_integration.py
```
```bash
git grep -n -E -e "\"(Execute|Specify)\"" -e "'(Execute|Specify)'" -- dashboard/reader/tests/test_integration.py
```

Hits: **48** lines (42 from the first command, 6 from the second). Rule (task-025 and the spec's Tests rule): a hand-written old name in a fixture's input stays; every reader output asserted and every value fed to a writer changes to the new name.

| # | Location | Text | Kind | Owner |
|---|---|---|---|---|
| 1 | `dashboard/reader/tests/fixtures/task011_golden/flat_golden.json:35` | `"phase": "Execute",` | golden reader output | task-031 |
| 2 | `dashboard/reader/tests/fixtures/task011_golden/hierarchical_golden.json:49` | `"phase": "Execute",` | golden reader output | task-031 |
| 3 | `dashboard/reader/tests/test_feature009.py:366` | `self.assertEqual(w.phase, Phase.Execute)` | reader output assertion | task-031 |
| 4 | `dashboard/reader/tests/test_feature009.py:412` | `self.assertEqual(w.phase, Phase.Execute)` | reader output assertion | task-031 |
| 5 | `dashboard/reader/tests/test_feature009.py:899` | `self.assertEqual(w.phase, Phase.Execute)` | reader output assertion | task-031 |
| 6 | `dashboard/reader/tests/test_fixtures.py:408` | `self.assertEqual(w.phase, Phase.Execute)` | reader output assertion | task-031 |
| 7 | `dashboard/reader/tests/test_fixtures.py:706` | `self.assertEqual(w.phase, Phase.Execute)` | reader output assertion | task-031 |
| 8 | `dashboard/reader/tests/test_integration.py:235` | `self.assertEqual(w.phase, Phase.Execute,` | reader output assertion | task-031 |
| 9 | `dashboard/reader/tests/test_integration.py:376` | `self.assertEqual(w.phase, Phase.Execute, "Step 1: phase Execute")` | reader output assertion | task-031 |
| 10 | `dashboard/reader/tests/test_reader.py:620` | `self.assertEqual(pw.phase, Phase.Execute)` | reader output assertion | task-031 |
| 11 | `dashboard/reader/tests/test_reader.py:779` | `"Describe": Phase.Describe,` | reader output assertion | task-031 |
| 12 | `dashboard/reader/tests/test_reader.py:780` | `"Define": Phase.Define,` | reader output assertion | task-031 |
| 13 | `dashboard/reader/tests/test_reader.py:781` | `"Specify": Phase.Specify,` | reader output assertion | task-031 |
| 14 | `dashboard/reader/tests/test_reader.py:782` | `"Plan": Phase.Plan,` | reader output assertion | task-031 |
| 15 | `dashboard/reader/tests/test_reader.py:783` | `"Detail": Phase.Detail,` | reader output assertion | task-031 |
| 16 | `dashboard/reader/tests/test_reader.py:784` | `"Execute": Phase.Execute,` | reader output assertion | task-031 |
| 17 | `dashboard/reader/tests/test_reader.py:989` | `self.assertEqual(w.phase, Phase.Execute)` | reader output assertion | task-031 |
| 18 | `dashboard/reader/tests/test_reader.py:1257` | `self.assertEqual(pw.phase, Phase.Execute)` | reader output assertion | task-031 |
| 19 | `dashboard/reader/tests/test_task011_golden_master.py:173` | `phase: Optional[str] = "Execute",` | fixture input or mapping | task-031 |
| 20 | `dashboard/reader/tests/test_task011_golden_master.py:357` | `work_phase: str = "Execute",` | fixture input or mapping | task-031 |
| 21 | `dashboard/reader/tests/test_work003_state_schema.py:311` | `self.assertEqual(pw.phase, Phase.Execute)` | reader output assertion | task-031 |
| 22 | `dashboard/reader/tests/test_work003_state_schema.py:353` | `self.assertEqual(pw.phase, Phase.Describe)` | reader output assertion | task-031 |
| 23 | `dashboard/reader/tests/test_work003_state_schema.py:357` | `self.assertEqual(pw.phase, Phase.Define)` | reader output assertion | task-031 |
| 24 | `dashboard/reader/tests/test_work003_state_schema.py:861` | `for phase_value in ("Describe", "Define"):` | fixture input or mapping | task-031 |
| 25 | `tests/canonical/test-diagram-content.sh:45` | `"requires": ["Discover", "Describe", "Define", "Specify", "Plan", "Detail", "Execute"],` | fixture input or mapping | history, left as is |
| 26 | `tests/canonical/test-pipeline-status-walkthrough.sh:346` | `if grep -qF "writeback-state.sh --pipeline --field Phase --value ${expected_phase}" "$sfile" 2>/d...` | writer-fed value | task-039 (B1 loop; the expected-phase rows for aid-define, aid-specify) |
| 27 | `tests/canonical/test-pipeline-status-walkthrough.sh:614` | `bash canonical/aid/scripts/execute/writeback-state.sh --pipeline --field Phase --value Specify` | writer-fed value | task-025 |
| 28 | `tests/canonical/test-writeback-state.sh:574` | `AID_STATE_FILE="$PIPE_STATE" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null ...` | writer-fed value | task-025 |
| 29 | `tests/canonical/test-writeback-state.sh:623` | `AID_STATE_FILE="$PIPE_STATE_G" bash "$SCRIPT" --pipeline --field Phase --value Plan 2>/dev/null \...` | writer-fed value | task-025 |
| 30 | `tests/canonical/test-writeback-state.sh:668` | `AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Phase --value "$ph_val" 2>/dev/n...` | writer-fed value | task-025 |
| 31 | `tests/canonical/test-writeback-state.sh:676` | `AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Phase --value "$ph_val" 2>/dev/n...` | writer-fed value | task-025 |
| 32 | `tests/canonical/test-writeback-state.sh:682` | `AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Phase --value "Build" 2>/dev/nul...` | writer-fed value (a negative case: its old-name refusal is asserted) | task-025 |
| 33 | `tests/canonical/test-writeback-state.sh:687` | `AID_STATE_FILE="$PIPE_STATE10" bash "$SCRIPT" --pipeline --field Phase --value "execute" 2>/dev/n...` | writer-fed value (a negative case: its old-name refusal is asserted) | task-025 |
| 34 | `tests/canonical/test-writeback-state.sh:1128` | `AID_STATE_FILE="$PIPE_STATE17" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null` | writer-fed value | task-025 |
| 35 | `tests/canonical/test-writeback-state.sh:1140` | `bash "$SCRIPT" --pipeline --field Phase --value Deploy &` | writer-fed value | task-025 |
| 36 | `tests/canonical/test-writeback-state.sh:1177` | `AID_STATE_FILE="$PIPE_STATE17B" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null` | writer-fed value | task-025 |
| 37 | `tests/canonical/test-writeback-state.sh:1187` | `bash "$SCRIPT" --pipeline --field Phase --value Deploy &` | writer-fed value | task-025 |
| 38 | `tests/canonical/test-writeback-state.sh:1245` | `AID_STATE_FILE="$PIPE_STATE18" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null` | writer-fed value | task-025 |
| 39 | `tests/canonical/test-writeback-state.sh:1262` | `AID_STATE_FILE="$PIPE_STATE19A" bash "$SCRIPT" --pipeline --field Phase --value Specify 2>/dev/null` | writer-fed value | task-025 |
| 40 | `tests/canonical/test-writeback-state.sh:1286` | `AID_STATE_FILE="$PIPE_STATE19C" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null` | writer-fed value | task-025 |
| 41 | `tests/canonical/test-writeback-state.sh:1764` | `AID_STATE_FILE="${BINV_WORK}/STATE.yml" bash "$SCRIPT" --pipeline --field Phase --value Execute 2...` | writer-fed value | task-025 |
| 42 | `tests/canonical/test-writeback-state.sh:1806` | `AID_STATE_FILE="$CRLF_STATE" bash "$SCRIPT" --pipeline --field Phase --value Execute 2>/dev/null ...` | writer-fed value | task-025 |
| 43 | `dashboard/reader/tests/test_integration.py:223` | `self._produce("Phase", "Execute")` | writer-fed value | task-025 |
| 44 | `dashboard/reader/tests/test_integration.py:257` | `self._produce("Phase", "Specify")` | writer-fed value | task-025 |
| 45 | `dashboard/reader/tests/test_integration.py:294` | `self._produce("Phase", "Execute")` | writer-fed value | task-025 |
| 46 | `dashboard/reader/tests/test_integration.py:368` | `self._produce("Phase", "Execute")` | writer-fed value | task-025 |
| 47 | `dashboard/reader/tests/test_integration.py:423` | `self._produce("Phase", "Execute")` | writer-fed value | task-025 |
| 48 | `dashboard/reader/tests/test_integration.py:481` | `self._produce("Phase", "Execute")` | writer-fed value | task-025 |

Notes: line 346 of `test-pipeline-status-walkthrough.sh` is one hit with one owner, task-039. The line is the shared loop body of B1 (the loop over `aid-define aid-specify aid-plan aid-detail aid-execute`) and neither task names it in its Scope; both edit the B1 expected-phase table it reads. The tie goes to the earlier task in the run order, task-039, because task-040 depends on task-039 (the two-owner suites table records that order). `test-diagram-content.sh` lists the phase names as diagram text, which the spec leaves as it is. The golden JSON fixtures are outputs and change to `Building`.

## P10 Are today's writes atomic?

Commands (run from the repo root):

```bash
git grep -n -E 'mktemp|mv "|acquire_lock|release_lock' -- canonical/aid/scripts/execute/writeback-state.sh
sed -n 1418,1431p canonical/aid/scripts/execute/writeback-state.sh
sed -n 1835,1865p canonical/aid/scripts/execute/writeback-state.sh
```

Answer: **yes, the field writes already are.** Every write in `canonical/aid/scripts/execute/writeback-state.sh` takes the sentinel lock (`acquire_lock`, released by an `EXIT` trap), writes the new bytes into a `mktemp` file with `wb_set_kv`, runs `wb_state_verify` on that temporary copy, and only then runs `mv "$tmp" "$STATE_FILE"` (the field write at lines 1835-1864, the task-field write at 1418-1430). A failed verification removes the temporary copy and leaves `$STATE_FILE` unchanged (exit 3). The `dashboard/scripts/writeback-state.sh` fork does the same at lines 1261-1337. Two limits to carry into task-025: the temporary file is created in the system temp directory, so the `mv` is a rename only when that directory is on the same filesystem as the work folder (otherwise it is a copy and not atomic); and the lock wait is the only retry. task-025 keeps the discipline for the new modes and adds the byte-for-byte case to `test-writeback-state.sh`.

## Site fixtures (G11)

Command (run from the repo root; the G11 search of task-020 Scope):

```bash
git grep -nE "'aid-[a-z-]+'|canonical/(skills|aid/templates)/" 06d32a1ba63e1c8810e16978165e5581034f4c87 -- site/scripts/__tests__ site/src/lib/__tests__
```

Hits: 835 lines in 39 site test files, grouped below per (test file, target, owner). A target is a real skill or template file, or a fixture name that names no real file (`aid-fixture`, `aid-parent`, `door-skill` and the like). Owner = the owner of the real target (the task that changes it); a target no task changes, and a fixture name, is `history, left as is` (Delta D9). `flow-advance.test.mjs` is also a task-024 file for its new words.

| # | Site test | Target | Owner | Hits |
|---|---|---|---|---|
| 1 | `site/scripts/__tests__/flow-advance.test.mjs` | `canonical/skills/aid-fixture/ (no such skill; fixture path)` | history, left as is | 4 |
| 2 | `site/scripts/__tests__/flow-advance.test.mjs` | `canonical/skills/aid-update-kb/SKILL.md` | task-042 | 1 |
| 3 | `site/scripts/__tests__/flow-advance.test.mjs` | `canonical/skills/aid-discover/references/state-q-and-a.md` | task-041 | 1 |
| 4 | `site/scripts/__tests__/flow-advance.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 4 |
| 5 | `site/scripts/__tests__/flow-advance.test.mjs` | `skill aid-test` | task-044 | 1 |
| 6 | `site/scripts/__tests__/flow-classify.test.mjs` | `skill aid-review` | task-044 | 2 |
| 7 | `site/scripts/__tests__/flow-classify.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 1 |
| 8 | `site/scripts/__tests__/flow-classify.test.mjs` | `canonical/skills/aid-parent/ (no such skill; fixture path)` | history, left as is | 5 |
| 9 | `site/scripts/__tests__/flow-classify.test.mjs` | `canonical/skills/aid-second/ (no such skill; fixture path)` | history, left as is | 1 |
| 10 | `site/scripts/__tests__/flow-classify.test.mjs` | `canonical/skills/aid-first/ (no such skill; fixture path)` | history, left as is | 1 |
| 11 | `site/scripts/__tests__/flow-classify.test.mjs` | `skill aid-test` | task-044 | 2 |
| 12 | `site/scripts/__tests__/flow-classify.test.mjs` | `name aid-parent (no such skill; fixture name)` | history, left as is | 2 |
| 13 | `site/scripts/__tests__/flow-classify.test.mjs` | `skill aid-test-security` | history, left as is | 2 |
| 14 | `site/scripts/__tests__/flow-classify.test.mjs` | `canonical/aid/templates/shortcut-engine.md` | task-037 | 2 |
| 15 | `site/scripts/__tests__/flow-classify.test.mjs` | `skill aid-create` | history, left as is | 1 |
| 16 | `site/scripts/__tests__/flow-classify.test.mjs` | `canonical/aid/templates/shortcut-engine.md.` | history, left as is | 2 |
| 17 | `site/scripts/__tests__/flow-compose.test.mjs` | `canonical/aid/templates/shortcut-engine.md` | task-037 | 5 |
| 18 | `site/scripts/__tests__/flow-compose.test.mjs` | `name aid-test-skill (no such skill; fixture name)` | history, left as is | 2 |
| 19 | `site/scripts/__tests__/flow-compose.test.mjs` | `canonical/skills/door-skill/ (no such skill; fixture path)` | history, left as is | 1 |
| 20 | `site/scripts/__tests__/flow-compose.test.mjs` | `canonical/aid/templates/zzz-last.md` | history, left as is | 2 |
| 21 | `site/scripts/__tests__/flow-compose.test.mjs` | `canonical/skills/aaa-first/ (no such skill; fixture path)` | history, left as is | 1 |
| 22 | `site/scripts/__tests__/flow-compose.test.mjs` | `canonical/skills/aid-fix/SKILL.md` | history, left as is | 2 |
| 23 | `site/scripts/__tests__/flow-compose.test.mjs` | `skill aid-fix` | history, left as is | 2 |
| 24 | `site/scripts/__tests__/flow-compose.test.mjs` | `canonical/skills/aid-create-api/SKILL.md` | history, left as is | 5 |
| 25 | `site/scripts/__tests__/flow-compose.test.mjs` | `skill aid-create-api` | history, left as is | 5 |
| 26 | `site/scripts/__tests__/flow-compose.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 1 |
| 27 | `site/scripts/__tests__/flow-compose.test.mjs` | `canonical/skills/aid-test-security/SKILL.md` | history, left as is | 2 |
| 28 | `site/scripts/__tests__/flow-compose.test.mjs` | `canonical/skills/aid-document/SKILL.md` | history, left as is | 1 |
| 29 | `site/scripts/__tests__/flow-compose.test.mjs` | `canonical/skills/aid-add-document/ (no such skill; fixture path)` | history, left as is | 1 |
| 30 | `site/scripts/__tests__/flow-compose.test.mjs` | `skill aid-create-document` | task-044 | 1 |
| 31 | `site/scripts/__tests__/flow-compose.test.mjs` | `canonical/skills/aid-test-performance/SKILL.md` | history, left as is | 1 |
| 32 | `site/scripts/__tests__/flow-compose.test.mjs` | `canonical/skills/aid-unknown/ (no such skill; fixture path)` | history, left as is | 1 |
| 33 | `site/scripts/__tests__/flow-engine-core.test.mjs` | `canonical/aid/templates/shortcut-engine.md` | task-037 | 2 |
| 34 | `site/scripts/__tests__/flow-engine-core.test.mjs` | `canonical/aid/templates/work-initiation-gate.md` | task-030 | 2 |
| 35 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-describe` | task-038 | 10 |
| 36 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-deploy` | task-043 | 1 |
| 37 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-define` | task-039 | 4 |
| 38 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-detail` | task-040 | 1 |
| 39 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-discover` | task-041 | 1 |
| 40 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-plan` | task-040 | 1 |
| 41 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-monitor` | task-043 | 1 |
| 42 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-specify` | task-039 | 2 |
| 43 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-execute` | task-040 | 3 |
| 44 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-housekeep` | task-042 | 1 |
| 45 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-summarize` | task-042 | 1 |
| 46 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-update-kb` | task-042 | 2 |
| 47 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `name aid-keyword-states (no such skill; fixture name)` | history, left as is | 1 |
| 48 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `canonical/skills/aid-describe/SKILL.md` | task-038 | 1 |
| 49 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `canonical/skills/aid-describe/references/state-completion.md` | task-038 | 1 |
| 50 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | `skill aid-create-api` | history, left as is | 3 |
| 51 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | `skill aid-fix` | history, left as is | 1 |
| 52 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | `canonical/skills/aid-create-api/SKILL.md` | history, left as is | 3 |
| 53 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | `canonical/aid/templates/shortcut-engine.md` | task-037 | 2 |
| 54 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | `name aid-synthetic-long (no such skill; fixture name)` | history, left as is | 1 |
| 55 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | `canonical/skills/aid-synthetic-long/ (no such skill; fixture path)` | history, left as is | 1 |
| 56 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `skill aid-review` | task-044 | 2 |
| 57 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `skill aid-test` | task-044 | 2 |
| 58 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `skill aid-create-document` | task-044 | 1 |
| 59 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `skill aid-design` | task-034 | 1 |
| 60 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `skill aid-prototype` | task-044 | 1 |
| 61 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `skill aid-report` | task-044 | 1 |
| 62 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `skill aid-research` | task-044 | 1 |
| 63 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `skill aid-update-document` | task-044 | 1 |
| 64 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `canonical/skills/test-fixture/ (no such skill; fixture path)` | history, left as is | 1 |
| 65 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-create-ticket` | task-043 | 3 |
| 66 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-read-ticket` | task-043 | 1 |
| 67 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-update-ticket` | task-043 | 1 |
| 68 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-config` | task-043 | 4 |
| 69 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-ask` | task-042 | 2 |
| 70 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-create` | history, left as is | 1 |
| 71 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-update-api` | history, left as is | 1 |
| 72 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-deprecate` | history, left as is | 1 |
| 73 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-document` | history, left as is | 1 |
| 74 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-document-runbook` | history, left as is | 1 |
| 75 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-test-security` | history, left as is | 1 |
| 76 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `name aid-fixture (no such skill; fixture name)` | history, left as is | 1 |
| 77 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `canonical/skills/aid-fixture/ (no such skill; fixture path)` | history, left as is | 1 |
| 78 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-set-connector` | task-043 | 1 |
| 79 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-unset-connector` | task-043 | 1 |
| 80 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `canonical/skills/aid-config/SKILL.md` | task-043 | 1 |
| 81 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/fake-cap-2/ (no such skill; fixture path)` | history, left as is | 1 |
| 82 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/fake-cap-3/ (no such skill; fixture path)` | history, left as is | 1 |
| 83 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/fake-cap-4/ (no such skill; fixture path)` | history, left as is | 1 |
| 84 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/fake-cap-5/ (no such skill; fixture path)` | history, left as is | 1 |
| 85 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `skill aid-test-security` | history, left as is | 5 |
| 86 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `skill aid-test-performance` | history, left as is | 2 |
| 87 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `skill aid-test` | task-044 | 12 |
| 88 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 8 |
| 89 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/aid-create/SKILL.md` | history, left as is | 1 |
| 90 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/aid-test-security/SKILL.md` | history, left as is | 1 |
| 91 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `skill aid-document-architecture` | history, left as is | 3 |
| 92 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `skill aid-document-changelog` | history, left as is | 2 |
| 93 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `skill aid-create-document` | task-044 | 3 |
| 94 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `name aid-alias-synth (no such skill; fixture name)` | history, left as is | 1 |
| 95 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `name aid-neither-synth (no such skill; fixture name)` | history, left as is | 1 |
| 96 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `name aid-approx-parent (no such skill; fixture name)` | history, left as is | 2 |
| 97 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/aid-approx-parent/ (no such skill; fixture path)` | history, left as is | 1 |
| 98 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `name aid-cycle-synth (no such skill; fixture name)` | history, left as is | 1 |
| 99 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/aid-cycle-synth/ (no such skill; fixture path)` | history, left as is | 1 |
| 100 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `name aid-cap-synth (no such skill; fixture name)` | history, left as is | 1 |
| 101 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/fake-cap-1/ (no such skill; fixture path)` | history, left as is | 1 |
| 102 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `skill aid-test-data-quality` | history, left as is | 1 |
| 103 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `skill aid-document` | history, left as is | 1 |
| 104 | `site/scripts/__tests__/flow-facade.test.mjs` | `canonical/skills/aid-review/SKILL.md` | task-044 | 1 |
| 105 | `site/scripts/__tests__/flow-facade.test.mjs` | `skill aid-describe` | task-038 | 6 |
| 106 | `site/scripts/__tests__/flow-facade.test.mjs` | `skill aid-review` | task-044 | 13 |
| 107 | `site/scripts/__tests__/flow-facade.test.mjs` | `skill aid-config` | task-043 | 11 |
| 108 | `site/scripts/__tests__/flow-facade.test.mjs` | `skill aid-document-architecture` | history, left as is | 2 |
| 109 | `site/scripts/__tests__/flow-facade.test.mjs` | `skill aid-create` | history, left as is | 4 |
| 110 | `site/scripts/__tests__/flow-facade.test.mjs` | `skill aid-test-security` | history, left as is | 1 |
| 111 | `site/scripts/__tests__/flow-facade.test.mjs` | `skill aid-summarize` | task-042 | 1 |
| 112 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/aid/templates/shortcut-engine.md` | task-037 | 3 |
| 113 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/aid-create-api/SKILL.md` | history, left as is | 1 |
| 114 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/aid-fix/SKILL.md` | history, left as is | 1 |
| 115 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/aid-test-quality/ (no such skill; fixture path)` | history, left as is | 1 |
| 116 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/aid-document/SKILL.md` | history, left as is | 1 |
| 117 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/aid-add/ (no such skill; fixture path)` | history, left as is | 1 |
| 118 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `skill aid-create` | history, left as is | 1 |
| 119 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/aid-unknown/ (no such skill; fixture path)` | history, left as is | 2 |
| 120 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/purity-doorway/ (no such skill; fixture path)` | history, left as is | 1 |
| 121 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/w1-doorway/ (no such skill; fixture path)` | history, left as is | 1 |
| 122 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/w5-doorway/ (no such skill; fixture path)` | history, left as is | 1 |
| 123 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `skill aid-create-api` | history, left as is | 12 |
| 124 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `skill aid-fix` | history, left as is | 1 |
| 125 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `skill aid-test-security` | history, left as is | 10 |
| 126 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `skill aid-test` | task-044 | 1 |
| 127 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 14 |
| 128 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/aid-test/references/z.md` | task-044 | 1 |
| 129 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/aid-foo/ (no such skill; fixture path)` | history, left as is | 2 |
| 130 | `site/scripts/__tests__/flow-graph.test.mjs` | `skill aid-test` | task-044 | 50 |
| 131 | `site/scripts/__tests__/flow-graph.test.mjs` | `name aid-example (no such skill; fixture name)` | history, left as is | 6 |
| 132 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/aid-example/ (no such skill; fixture path)` | history, left as is | 2 |
| 133 | `site/scripts/__tests__/flow-graph.test.mjs` | `name aid-foo (no such skill; fixture name)` | history, left as is | 8 |
| 134 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/foo/ (no such skill; fixture path)` | history, left as is | 4 |
| 135 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/x/ (no such skill; fixture path)` | history, left as is | 1 |
| 136 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/aid-review/SKILL.md` | task-044 | 2 |
| 137 | `site/scripts/__tests__/flow-graph.test.mjs` | `name aid-no-exit (no such skill; fixture name)` | history, left as is | 1 |
| 138 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/aid-base/ (no such skill; fixture path)` | history, left as is | 6 |
| 139 | `site/scripts/__tests__/flow-graph.test.mjs` | `name aid-base (no such skill; fixture name)` | history, left as is | 2 |
| 140 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/aid-beta/ (no such skill; fixture path)` | history, left as is | 1 |
| 141 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/aid-alpha/ (no such skill; fixture path)` | history, left as is | 1 |
| 142 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/aid/templates/shortcut-engine.md` | task-037 | 1 |
| 143 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/aid/templates/shortcut-engine.md.` | history, left as is | 1 |
| 144 | `site/scripts/__tests__/flow-graph.test.mjs` | `skill aid-housekeep` | task-042 | 1 |
| 145 | `site/scripts/__tests__/flow-graph.test.mjs` | `skill aid-update-kb` | task-042 | 1 |
| 146 | `site/scripts/__tests__/flow-graph.test.mjs` | `skill aid-describe` | task-038 | 1 |
| 147 | `site/scripts/__tests__/flow-graph.test.mjs` | `skill aid-review` | task-044 | 1 |
| 148 | `site/scripts/__tests__/flow-render-mermaid.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 1 |
| 149 | `site/scripts/__tests__/flow-render-mermaid.test.mjs` | `name aid-fixture (no such skill; fixture name)` | history, left as is | 1 |
| 150 | `site/scripts/__tests__/flow-render-mermaid.test.mjs` | `canonical/skills/aid-fixture/ (no such skill; fixture path)` | history, left as is | 1 |
| 151 | `site/scripts/__tests__/flow-validate.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 6 |
| 152 | `site/scripts/__tests__/flow-validate.test.mjs` | `skill aid-test` | task-044 | 1 |
| 153 | `site/scripts/__tests__/flow-validate.test.mjs` | `name aid-x (no such skill; fixture name)` | history, left as is | 5 |
| 154 | `site/scripts/__tests__/flow-validate.test.mjs` | `canonical/skills/aid-x/ (no such skill; fixture path)` | history, left as is | 5 |
| 155 | `site/scripts/__tests__/gen-reference.test.mjs` | `canonical/aid/templates/shortcut-engine.md` | task-037 | 1 |
| 156 | `site/scripts/__tests__/gen-reference.test.mjs` | `canonical/aid/templates/shortcut-catalog.yml` | history, left as is | 1 |
| 157 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-summarize` | task-042 | 1 |
| 158 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-discover` | task-041 | 1 |
| 159 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-config` | task-043 | 1 |
| 160 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-describe` | task-038 | 1 |
| 161 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-define` | task-039 | 1 |
| 162 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-specify` | task-039 | 1 |
| 163 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-plan` | task-040 | 1 |
| 164 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-detail` | task-040 | 1 |
| 165 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-execute` | task-040 | 1 |
| 166 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-deploy` | task-043 | 1 |
| 167 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-monitor` | task-043 | 1 |
| 168 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-housekeep` | task-042 | 1 |
| 169 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-ask` | task-042 | 1 |
| 170 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-update-kb` | task-042 | 1 |
| 171 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-set-connector` | task-043 | 1 |
| 172 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-unset-connector` | task-043 | 1 |
| 173 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-update-ticket` | task-043 | 1 |
| 174 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-create-ticket` | task-043 | 1 |
| 175 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-read-ticket` | task-043 | 1 |
| 176 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-orchestrate` | task-032 | 1 |
| 177 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-chat` | task-043 | 1 |
| 178 | `site/scripts/__tests__/gen-reference.test.mjs` | `canonical/aid/templates/knowledge-base/` | history, left as is | 1 |
| 179 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `skill aid-describe` | task-038 | 1 |
| 180 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `skill aid-plan` | task-040 | 1 |
| 181 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `skill aid-specify` | task-039 | 1 |
| 182 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `skill aid-define` | task-039 | 1 |
| 183 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `skill aid-detail` | task-040 | 1 |
| 184 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `skill aid-orchestrate` | task-032 | 1 |
| 185 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `skill aid-deploy` | task-043 | 3 |
| 186 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `skill aid-monitor` | task-043 | 3 |
| 187 | `site/scripts/__tests__/gen-skills.test.mjs` | `canonical/skills/some-dir-name/ (no such skill; fixture path)` | history, left as is | 1 |
| 188 | `site/scripts/__tests__/gen-skills.test.mjs` | `skill aid-read-ticket` | task-043 | 1 |
| 189 | `site/scripts/__tests__/gen-skills.test.mjs` | `canonical/skills/aid-read-ticket/SKILL.md` | task-043 | 1 |
| 190 | `site/scripts/__tests__/gen-skills.test.mjs` | `canonical/skills/*/ (no such skill; fixture path)` | history, left as is | 4 |
| 191 | `site/scripts/__tests__/gen-skills.test.mjs` | `canonical/aid/templates/shortcut-catalog.yml` | history, left as is | 4 |
| 192 | `site/scripts/__tests__/gen-skills.test.mjs` | `name aid-deleted (no such skill; fixture name)` | history, left as is | 4 |
| 193 | `site/scripts/__tests__/gen-skills.test.mjs` | `skill aid-update-kb` | task-042 | 8 |
| 194 | `site/scripts/__tests__/gen-skills.test.mjs` | `skill aid-execute` | task-040 | 1 |
| 195 | `site/scripts/__tests__/gen-skills.test.mjs` | `skill aid-discover` | task-041 | 1 |
| 196 | `site/scripts/__tests__/provenance-appender.test.mjs` | `canonical/aid/templates/shortcut-engine.md` | task-037 | 3 |
| 197 | `site/scripts/__tests__/provenance-appender.test.mjs` | `name aid-add-api (no such skill; fixture name)` | history, left as is | 3 |
| 198 | `site/scripts/__tests__/provenance-appender.test.mjs` | `name aid-add-cli (no such skill; fixture name)` | history, left as is | 1 |
| 199 | `site/scripts/__tests__/provenance-appender.test.mjs` | `skill aid-review` | task-044 | 9 |
| 200 | `site/scripts/__tests__/provenance-appender.test.mjs` | `skill aid-create-api` | history, left as is | 3 |
| 201 | `site/scripts/__tests__/provenance-appender.test.mjs` | `skill aid-ask` | task-042 | 3 |
| 202 | `site/scripts/__tests__/provenance-deep-link.test.mjs` | `canonical/skills/aid-foo/ (no such skill; fixture path)` | history, left as is | 5 |
| 203 | `site/scripts/__tests__/provenance-deep-link.test.mjs` | `canonical/skills/aid-bar/ (no such skill; fixture path)` | history, left as is | 1 |
| 204 | `site/scripts/__tests__/provenance-deep-link.test.mjs` | `canonical/skills/aid-baz/ (no such skill; fixture path)` | history, left as is | 2 |
| 205 | `site/scripts/__tests__/provenance-deep-link.test.mjs` | `canonical/skills/aid-create-api/SKILL.md` | history, left as is | 1 |
| 206 | `site/scripts/__tests__/provenance-render-list.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 7 |
| 207 | `site/scripts/__tests__/provenance-render-list.test.mjs` | `name aid-fixture (no such skill; fixture name)` | history, left as is | 1 |
| 208 | `site/scripts/__tests__/provenance-verify.test.mjs` | `canonical/skills/test-skill/ (no such skill; fixture path)` | history, left as is | 26 |
| 209 | `site/scripts/__tests__/provenance-verify.test.mjs` | `canonical/skills/nonexistent/ (no such skill; fixture path)` | history, left as is | 6 |
| 210 | `site/scripts/__tests__/provenance.test.mjs` | `skill aid-test` | task-044 | 2 |
| 211 | `site/scripts/__tests__/provenance.test.mjs` | `canonical/skills/aid-review/SKILL.md` | task-044 | 4 |
| 212 | `site/scripts/__tests__/provenance.test.mjs` | `canonical/skills/test-skill/ (no such skill; fixture path)` | history, left as is | 4 |
| 213 | `site/scripts/__tests__/provenance.test.mjs` | `canonical/skills/../ (no such skill; fixture path)` | history, left as is | 1 |
| 214 | `site/scripts/__tests__/provenance.test.mjs` | `canonical/skills/aid-ask/SKILL.md` | task-042 | 1 |
| 215 | `site/scripts/__tests__/provenance.test.mjs` | `skill aid-review` | task-044 | 1 |
| 216 | `site/scripts/__tests__/skill-counts.test.mjs` | `skill aid-ask` | task-042 | 1 |
| 217 | `site/scripts/__tests__/skill-node-panel-lifecycle.test.mjs` | `name aid-flow-data (no such skill; fixture name)` | history, left as is | 3 |
| 218 | `site/scripts/__tests__/skill-node-panel-lifecycle.test.mjs` | `name aid-node-panel (no such skill; fixture name)` | history, left as is | 1 |
| 219 | `site/scripts/__tests__/skill-node-panel-panel.test.mjs` | `name aid-fixture (no such skill; fixture name)` | history, left as is | 1 |
| 220 | `site/scripts/__tests__/skill-node-panel-panel.test.mjs` | `canonical/skills/a/ (no such skill; fixture path)` | history, left as is | 4 |
| 221 | `site/scripts/__tests__/skill-node-panel-panel.test.mjs` | `name aid-flow-data (no such skill; fixture name)` | history, left as is | 1 |
| 222 | `site/scripts/__tests__/skill-node-panel-panel.test.mjs` | `name aid-node-panel (no such skill; fixture name)` | history, left as is | 4 |
| 223 | `site/scripts/__tests__/skills-body.test.mjs` | `name aid-fixture (no such skill; fixture name)` | history, left as is | 3 |
| 224 | `site/scripts/__tests__/skills-body.test.mjs` | `skill aid-review` | task-044 | 2 |
| 225 | `site/scripts/__tests__/skills-body.test.mjs` | `name aid-multi (no such skill; fixture name)` | history, left as is | 2 |
| 226 | `site/scripts/__tests__/skills-body.test.mjs` | `skill aid-create-api` | history, left as is | 1 |
| 227 | `site/scripts/__tests__/skills-catalog.test.mjs` | `canonical/aid/templates/shortcut-catalog.yml` | history, left as is | 1 |
| 228 | `site/scripts/__tests__/skills-catalog.test.mjs` | `name aid-catalog- (no such skill; fixture name)` | history, left as is | 1 |
| 229 | `site/scripts/__tests__/skills-catalog.test.mjs` | `name aid-middle (no such skill; fixture name)` | history, left as is | 1 |
| 230 | `site/scripts/__tests__/skills-catalog.test.mjs` | `name aid-alpha (no such skill; fixture name)` | history, left as is | 1 |
| 231 | `site/scripts/__tests__/skills-catalog.test.mjs` | `name aid-zap (no such skill; fixture name)` | history, left as is | 1 |
| 232 | `site/scripts/__tests__/skills-catalog.test.mjs` | `skill aid-deploy` | task-043 | 3 |
| 233 | `site/scripts/__tests__/skills-catalog.test.mjs` | `skill aid-monitor` | task-043 | 1 |
| 234 | `site/scripts/__tests__/skills-catalog.test.mjs` | `name aid-bad (no such skill; fixture name)` | history, left as is | 1 |
| 235 | `site/scripts/__tests__/skills-catalog.test.mjs` | `skill aid-fix` | history, left as is | 1 |
| 236 | `site/scripts/__tests__/skills-discover.test.mjs` | `skill aid-test` | task-044 | 45 |
| 237 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-missing (no such skill; fixture name)` | history, left as is | 2 |
| 238 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-bad- (no such skill; fixture name)` | history, left as is | 1 |
| 239 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid--double (no such skill; fixture name)` | history, left as is | 1 |
| 240 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-mismatch (no such skill; fixture name)` | history, left as is | 2 |
| 241 | `site/scripts/__tests__/skills-discover.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 1 |
| 242 | `site/scripts/__tests__/skills-discover.test.mjs` | `canonical/skills/aid-test/references` (directory) | task-044 | 1 |
| 243 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-foo-bar (no such skill; fixture name)` | history, left as is | 6 |
| 244 | `site/scripts/__tests__/skills-discover.test.mjs` | `canonical/skills/aid-foo-bar/ (no such skill; fixture path)` | history, left as is | 1 |
| 245 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-alpha (no such skill; fixture name)` | history, left as is | 1 |
| 246 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-beta (no such skill; fixture name)` | history, left as is | 1 |
| 247 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-z (no such skill; fixture name)` | history, left as is | 2 |
| 248 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-a (no such skill; fixture name)` | history, left as is | 2 |
| 249 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-m (no such skill; fixture name)` | history, left as is | 2 |
| 250 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-a-b (no such skill; fixture name)` | history, left as is | 2 |
| 251 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-ab (no such skill; fixture name)` | history, left as is | 2 |
| 252 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-good (no such skill; fixture name)` | history, left as is | 1 |
| 253 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-bad (no such skill; fixture name)` | history, left as is | 1 |
| 254 | `site/scripts/__tests__/skills-frontmatter.test.mjs` | `canonical/skills/foo/ (no such skill; fixture path)` | history, left as is | 1 |
| 255 | `site/scripts/__tests__/skills-frontmatter.test.mjs` | `name aid-foo (no such skill; fixture name)` | history, left as is | 1 |
| 256 | `site/scripts/__tests__/skills-frontmatter.test.mjs` | `canonical/skills/x/ (no such skill; fixture path)` | history, left as is | 4 |
| 257 | `site/scripts/__tests__/skills-frontmatter.test.mjs` | `canonical/skills/z/ (no such skill; fixture path)` | history, left as is | 2 |
| 258 | `site/scripts/__tests__/skills-frontmatter.test.mjs` | `canonical/skills/*/ (no such skill; fixture path)` | history, left as is | 1 |
| 259 | `site/scripts/__tests__/skills-groups.test.mjs` | `name aid-totally-unknown-xyz (no such skill; fixture name)` | history, left as is | 1 |
| 260 | `site/scripts/__tests__/skills-groups.test.mjs` | `name aid-mystery-skill (no such skill; fixture name)` | history, left as is | 1 |
| 261 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-orchestrate` | task-032 | 4 |
| 262 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-config` | task-043 | 4 |
| 263 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-describe` | task-038 | 2 |
| 264 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-plan` | task-040 | 8 |
| 265 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-specify` | task-039 | 1 |
| 266 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-define` | task-039 | 1 |
| 267 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-detail` | task-040 | 1 |
| 268 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-deploy` | task-043 | 7 |
| 269 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-monitor` | task-043 | 4 |
| 270 | `site/scripts/__tests__/skills-paths.test.mjs` | `skill aid-create-api` | history, left as is | 3 |
| 271 | `site/scripts/__tests__/skills-paths.test.mjs` | `canonical/skills/aid-create-api/SKILL.md` | history, left as is | 2 |
| 272 | `site/scripts/__tests__/skills-paths.test.mjs` | `name aid-foo (no such skill; fixture name)` | history, left as is | 8 |
| 273 | `site/scripts/__tests__/skills-paths.test.mjs` | `name aid-bar-baz (no such skill; fixture name)` | history, left as is | 2 |
| 274 | `site/scripts/__tests__/skills-render-index.test.mjs` | `canonical/skills/*/ (no such skill; fixture path)` | history, left as is | 2 |
| 275 | `site/scripts/__tests__/skills-render-index.test.mjs` | `canonical/aid/templates/shortcut-catalog.yml` | history, left as is | 2 |
| 276 | `site/scripts/__tests__/skills-render-index.test.mjs` | `skill aid-deploy` | task-043 | 1 |
| 277 | `site/scripts/__tests__/skills-render-index.test.mjs` | `skill aid-monitor` | task-043 | 1 |
| 278 | `site/scripts/__tests__/skills-render-index.test.mjs` | `skill aid-orchestrate` | task-032 | 2 |
| 279 | `site/scripts/__tests__/skills-render-index.test.mjs` | `name aid-beta (no such skill; fixture name)` | history, left as is | 1 |
| 280 | `site/scripts/__tests__/skills-render-index.test.mjs` | `name aid-alpha (no such skill; fixture name)` | history, left as is | 1 |
| 281 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-test-skill (no such skill; fixture name)` | history, left as is | 5 |
| 282 | `site/scripts/__tests__/skills-render-page.test.mjs` | `canonical/skills/aid-review/SKILL.md` | task-044 | 1 |
| 283 | `site/scripts/__tests__/skills-render-page.test.mjs` | `skill aid-review` | task-044 | 2 |
| 284 | `site/scripts/__tests__/skills-render-page.test.mjs` | `canonical/skills/aid-test-skill/ (no such skill; fixture path)` | history, left as is | 4 |
| 285 | `site/scripts/__tests__/skills-render-page.test.mjs` | `skill aid-create-api` | history, left as is | 1 |
| 286 | `site/scripts/__tests__/skills-render-page.test.mjs` | `canonical/skills/aid-create-api/SKILL.md` | history, left as is | 1 |
| 287 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-list-test (no such skill; fixture name)` | history, left as is | 2 |
| 288 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-pipe-test (no such skill; fixture name)` | history, left as is | 2 |
| 289 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-angle-test (no such skill; fixture name)` | history, left as is | 2 |
| 290 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-synthetic-test (no such skill; fixture name)` | history, left as is | 2 |
| 291 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-folded-test (no such skill; fixture name)` | history, left as is | 2 |
| 292 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-fullfield-test (no such skill; fixture name)` | history, left as is | 2 |
| 293 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-nosidebar-test (no such skill; fixture name)` | history, left as is | 1 |
| 294 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-desc-test (no such skill; fixture name)` | history, left as is | 2 |
| 295 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-nodesc (no such skill; fixture name)` | history, left as is | 1 |
| 296 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-quote-test (no such skill; fixture name)` | history, left as is | 2 |
| 297 | `site/scripts/__tests__/skills-render-value.test.mjs` | `canonical/skills/aid-read-ticket/SKILL.md` | task-043 | 1 |
| 298 | `site/scripts/__tests__/skills-summary.test.mjs` | `skill aid-test` | task-044 | 10 |
| 299 | `site/scripts/__tests__/skills-summary.test.mjs` | `name aid-some-skill (no such skill; fixture name)` | history, left as is | 1 |
| 300 | `site/scripts/__tests__/skills-summary.test.mjs` | `name aid-custom-dir (no such skill; fixture name)` | history, left as is | 1 |
| 301 | `site/scripts/__tests__/skills-summary.test.mjs` | `name aid-x (no such skill; fixture name)` | history, left as is | 2 |
| 302 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | `canonical/aid/templates/knowledge-base/` | history, left as is | 1 |
| 303 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | `canonical/aid/templates/shortcut-engine.md` | task-037 | 1 |
| 304 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | `canonical/aid/templates/shortcut-catalog.yml` | history, left as is | 2 |
| 305 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | `canonical/skills/*/ (no such skill; fixture path)` | history, left as is | 1 |
| 306 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | `canonical/skills/aid-ask/SKILL.md` | task-042 | 6 |
| 307 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | `skill aid-ask` | task-042 | 9 |
| 308 | `site/src/lib/__tests__/feature-009-releases-banner.test.ts` | `name aid-banner-dismissed (no such skill; fixture name)` | history, left as is | 2 |
| 309 | `site/src/lib/__tests__/skill-node-panel.dom.test.ts` | `name aid-fixture (no such skill; fixture name)` | history, left as is | 1 |
| 310 | `site/src/lib/__tests__/skill-node-panel.dom.test.ts` | `canonical/skills/a/ (no such skill; fixture path)` | history, left as is | 3 |
| 311 | `site/src/lib/__tests__/skill-node-panel.dom.test.ts` | `name aid-flow-data (no such skill; fixture name)` | history, left as is | 1 |
| 312 | `site/src/lib/__tests__/skill-node-panel.dom.test.ts` | `name aid-node-panel (no such skill; fixture name)` | history, left as is | 1 |
| 313 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `canonical/skills/aid-ask/SKILL.md` | task-042 | 13 |
| 314 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `skill aid-ask` | task-042 | 7 |
| 315 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `skill aid-plan` | task-040 | 2 |
| 316 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `skill aid-execute` | task-040 | 1 |
| 317 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `canonical/skills/aid-plan/SKILL.md` | task-040 | 3 |
| 318 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `canonical/skills/Aid-Ask/ (no such skill; fixture path)` | history, left as is | 1 |
| 319 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `canonical/skills/aid_ask/ (no such skill; fixture path)` | history, left as is | 1 |
| 320 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `canonical/skills/aid-audit/ (no such skill; fixture path)` | history, left as is | 1 |
| 321 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `canonical/skills/*/ (no such skill; fixture path)` | history, left as is | 1 |
| 322 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `canonical/aid/templates/shortcut-catalog.yml` | history, left as is | 1 |
| 323 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `canonical/skills/aid-not-a-real-skill/ (no such skill; fixture path)` | history, left as is | 1 |

## KB sources (G17)

Command (run from the repo root):

```bash
git grep -n -E 'state-machine-chaining\.md|canonical/agents/aid-interviewer|canonical/aid/templates/state-machine-chaining' -- .aid/knowledge
```

Hits: 2 lines. None is a `sources:` entry that delivery-002 deletes, moves or renames: delivery-002 deletes, moves and renames no file (the chaining file is deleted by delivery-003, task-074; `aid-interviewer` by delivery-003 too). **0 rows** for the G17 rule. The KB rows that delivery-002 does own are the task-045, task-049 and task-057 documents (see the Delta).

## Site generator sources (G19)

Delivery-002 retires and renames no skill (the retirements are Features 003, 004 and 009, and `aid-interviewer` is delivery-003), so the G19 rule has **0 rows**. The flow-graph library lines that parse the advance words are in P5 (task-024).

## Baselines

Command (run from the repo root; the terms are the edit-list tokens and the suite names of P8 and P9):

```bash
for term in <the P8 tokens, the P8 suite names, design-lifecycle.md>; do git grep -n -F -e "$term" -- tests/cost-baseline.tsv tests/coverage-baseline.tsv; done
```

Hits: 6188 (term, line) matches in the two baselines, in 129 (baseline, term) rows. Owner for every row: `baseline, re-recorded at the gate` (Q134 D11; no task edits a baseline).

| # | Baseline | Matched term | Lines | Owner |
|---|---|---|---|---|
| 1 | `tests/cost-baseline.tsv` | `architecture.md` | 1 | baseline, re-recorded at the gate |
| 2 | `tests/cost-baseline.tsv` | `coding-standards.md` | 1 | baseline, re-recorded at the gate |
| 3 | `tests/cost-baseline.tsv` | `data-pipeline.md` | 1 | baseline, re-recorded at the gate |
| 4 | `tests/cost-baseline.tsv` | `design-lifecycle.md` | 1 | baseline, re-recorded at the gate |
| 5 | `tests/cost-baseline.tsv` | `design-tokens.md` | 1 | baseline, re-recorded at the gate |
| 6 | `tests/cost-baseline.tsv` | `domain-glossary.md` | 1 | baseline, re-recorded at the gate |
| 7 | `tests/cost-baseline.tsv` | `pipeline-contracts.md` | 1 | baseline, re-recorded at the gate |
| 8 | `tests/cost-baseline.tsv` | `shortcut-engine.md` | 1 | baseline, re-recorded at the gate |
| 9 | `tests/cost-baseline.tsv` | `test-landscape.md` | 1 | baseline, re-recorded at the gate |
| 10 | `tests/cost-baseline.tsv` | `ticket-resolution.md` | 1 | baseline, re-recorded at the gate |
| 11 | `tests/cost-baseline.tsv` | `work-initiation-gate.md` | 1 | baseline, re-recorded at the gate |
| 12 | `tests/coverage-baseline.tsv` | `INDEX.md` | 7 | baseline, re-recorded at the gate |
| 13 | `tests/coverage-baseline.tsv` | `SPEC.md` | 2 | baseline, re-recorded at the gate |
| 14 | `tests/coverage-baseline.tsv` | `STATE.md` | 48 | baseline, re-recorded at the gate |
| 15 | `tests/coverage-baseline.tsv` | `STATE.yml` | 69 | baseline, re-recorded at the gate |
| 16 | `tests/coverage-baseline.tsv` | `architecture.md` | 12 | baseline, re-recorded at the gate |
| 17 | `tests/coverage-baseline.tsv` | `coding-standards.md` | 2 | baseline, re-recorded at the gate |
| 18 | `tests/coverage-baseline.tsv` | `content-model.md` | 2 | baseline, re-recorded at the gate |
| 19 | `tests/coverage-baseline.tsv` | `coverage-parity.sh` | 12 | baseline, re-recorded at the gate |
| 20 | `tests/coverage-baseline.tsv` | `data-schemas.md` | 2 | baseline, re-recorded at the gate |
| 21 | `tests/coverage-baseline.tsv` | `design-tokens.md` | 2 | baseline, re-recorded at the gate |
| 22 | `tests/coverage-baseline.tsv` | `domain-glossary.md` | 2 | baseline, re-recorded at the gate |
| 23 | `tests/coverage-baseline.tsv` | `home.html` | 7 | baseline, re-recorded at the gate |
| 24 | `tests/coverage-baseline.tsv` | `pipeline-contracts.md` | 4 | baseline, re-recorded at the gate |
| 25 | `tests/coverage-baseline.tsv` | `project-index.md` | 4 | baseline, re-recorded at the gate |
| 26 | `tests/coverage-baseline.tsv` | `release.sh` | 17 | baseline, re-recorded at the gate |
| 27 | `tests/coverage-baseline.tsv` | `rules.md` | 1 | baseline, re-recorded at the gate |
| 28 | `tests/coverage-baseline.tsv` | `server.mjs` | 4 | baseline, re-recorded at the gate |
| 29 | `tests/coverage-baseline.tsv` | `server.py` | 6 | baseline, re-recorded at the gate |
| 30 | `tests/coverage-baseline.tsv` | `shortcut-engine.md` | 4 | baseline, re-recorded at the gate |
| 31 | `tests/coverage-baseline.tsv` | `test-actback-fixtures.sh` | 20 | baseline, re-recorded at the gate |
| 32 | `tests/coverage-baseline.tsv` | `test-actback-task.sh` | 29 | baseline, re-recorded at the gate |
| 33 | `tests/coverage-baseline.tsv` | `test-aid-cli-parity.sh` | 748 | baseline, re-recorded at the gate |
| 34 | `tests/coverage-baseline.tsv` | `test-aid-cli-ps1.sh` | 171 | baseline, re-recorded at the gate |
| 35 | `tests/coverage-baseline.tsv` | `test-aid-cli.sh` | 201 | baseline, re-recorded at the gate |
| 36 | `tests/coverage-baseline.tsv` | `test-aid-dashboard-cli.sh` | 142 | baseline, re-recorded at the gate |
| 37 | `tests/coverage-baseline.tsv` | `test-aid-migrate-trigger.sh` | 63 | baseline, re-recorded at the gate |
| 38 | `tests/coverage-baseline.tsv` | `test-aid-migrate.sh` | 210 | baseline, re-recorded at the gate |
| 39 | `tests/coverage-baseline.tsv` | `test-aid-remote.sh` | 48 | baseline, re-recorded at the gate |
| 40 | `tests/coverage-baseline.tsv` | `test-ascii-only.sh` | 8 | baseline, re-recorded at the gate |
| 41 | `tests/coverage-baseline.tsv` | `test-build-connectors-index.sh` | 15 | baseline, re-recorded at the gate |
| 42 | `tests/coverage-baseline.tsv` | `test-build-kb-index.sh` | 18 | baseline, re-recorded at the gate |
| 43 | `tests/coverage-baseline.tsv` | `test-catalog-dirs-parity.sh` | 485 | baseline, re-recorded at the gate |
| 44 | `tests/coverage-baseline.tsv` | `test-change-refactor-family-scaffold.sh` | 83 | baseline, re-recorded at the gate |
| 45 | `tests/coverage-baseline.tsv` | `test-closure-batching.sh` | 7 | baseline, re-recorded at the gate |
| 46 | `tests/coverage-baseline.tsv` | `test-closure-check.sh` | 13 | baseline, re-recorded at the gate |
| 47 | `tests/coverage-baseline.tsv` | `test-compute-block-radius.sh` | 28 | baseline, re-recorded at the gate |
| 48 | `tests/coverage-baseline.tsv` | `test-conformance-lane-semantics.sh` | 24 | baseline, re-recorded at the gate |
| 49 | `tests/coverage-baseline.tsv` | `test-connector-consumption-linkage.sh` | 53 | baseline, re-recorded at the gate |
| 50 | `tests/coverage-baseline.tsv` | `test-connector-registry.sh` | 14 | baseline, re-recorded at the gate |
| 51 | `tests/coverage-baseline.tsv` | `test-connector-set-unset-lifecycle.sh` | 51 | baseline, re-recorded at the gate |
| 52 | `tests/coverage-baseline.tsv` | `test-connector-skills-structural.sh` | 43 | baseline, re-recorded at the gate |
| 53 | `tests/coverage-baseline.tsv` | `test-connector-twins-ps1-parity.sh` | 23 | baseline, re-recorded at the gate |
| 54 | `tests/coverage-baseline.tsv` | `test-connectors-registry-integration.sh` | 8 | baseline, re-recorded at the gate |
| 55 | `tests/coverage-baseline.tsv` | `test-create-family-scaffold.sh` | 43 | baseline, re-recorded at the gate |
| 56 | `tests/coverage-baseline.tsv` | `test-cutover-no-dangling.sh` | 12 | baseline, re-recorded at the gate |
| 57 | `tests/coverage-baseline.tsv` | `test-dashboard-manifest.sh` | 6 | baseline, re-recorded at the gate |
| 58 | `tests/coverage-baseline.tsv` | `test-dashboard-parity-h.sh` | 114 | baseline, re-recorded at the gate |
| 59 | `tests/coverage-baseline.tsv` | `test-dashboard-parity.sh` | 15 | baseline, re-recorded at the gate |
| 60 | `tests/coverage-baseline.tsv` | `test-delivery-gate-aggregate.sh` | 24 | baseline, re-recorded at the gate |
| 61 | `tests/coverage-baseline.tsv` | `test-deploy-monitor-repurpose.sh` | 43 | baseline, re-recorded at the gate |
| 62 | `tests/coverage-baseline.tsv` | `test-describe-full-only.sh` | 28 | baseline, re-recorded at the gate |
| 63 | `tests/coverage-baseline.tsv` | `test-discovery-doc-ownership.sh` | 13 | baseline, re-recorded at the gate |
| 64 | `tests/coverage-baseline.tsv` | `test-disjoint-merge.sh` | 24 | baseline, re-recorded at the gate |
| 65 | `tests/coverage-baseline.tsv` | `test-doc-counts.sh` | 3 | baseline, re-recorded at the gate |
| 66 | `tests/coverage-baseline.tsv` | `test-doc-set-mapping.sh` | 21 | baseline, re-recorded at the gate |
| 67 | `tests/coverage-baseline.tsv` | `test-doc-set-propose-confirm.sh` | 12 | baseline, re-recorded at the gate |
| 68 | `tests/coverage-baseline.tsv` | `test-doc-set-read.sh` | 47 | baseline, re-recorded at the gate |
| 69 | `tests/coverage-baseline.tsv` | `test-document-family-scaffold.sh` | 48 | baseline, re-recorded at the gate |
| 70 | `tests/coverage-baseline.tsv` | `test-dogfood-byte-identity.sh` | 18 | baseline, re-recorded at the gate |
| 71 | `tests/coverage-baseline.tsv` | `test-domain-doc-matrix.sh` | 18 | baseline, re-recorded at the gate |
| 72 | `tests/coverage-baseline.tsv` | `test-downstream-worktree-entry.sh` | 60 | baseline, re-recorded at the gate |
| 73 | `tests/coverage-baseline.tsv` | `test-essence-capture.sh` | 8 | baseline, re-recorded at the gate |
| 74 | `tests/coverage-baseline.tsv` | `test-expectations-single-source.sh` | 9 | baseline, re-recorded at the gate |
| 75 | `tests/coverage-baseline.tsv` | `test-f010-governance-guards.sh` | 13 | baseline, re-recorded at the gate |
| 76 | `tests/coverage-baseline.tsv` | `test-fix-family-scaffold.sh` | 35 | baseline, re-recorded at the gate |
| 77 | `tests/coverage-baseline.tsv` | `test-frontmatter-lint.sh` | 21 | baseline, re-recorded at the gate |
| 78 | `tests/coverage-baseline.tsv` | `test-grade-summary.sh` | 47 | baseline, re-recorded at the gate |
| 79 | `tests/coverage-baseline.tsv` | `test-guardrails-d012.sh` | 35 | baseline, re-recorded at the gate |
| 80 | `tests/coverage-baseline.tsv` | `test-harvest-batching.sh` | 5 | baseline, re-recorded at the gate |
| 81 | `tests/coverage-baseline.tsv` | `test-harvest-coined-terms.sh` | 18 | baseline, re-recorded at the gate |
| 82 | `tests/coverage-baseline.tsv` | `test-housekeep-classify.sh` | 24 | baseline, re-recorded at the gate |
| 83 | `tests/coverage-baseline.tsv` | `test-install-parity.sh` | 3 | baseline, re-recorded at the gate |
| 84 | `tests/coverage-baseline.tsv` | `test-install-provisioning.sh` | 44 | baseline, re-recorded at the gate |
| 85 | `tests/coverage-baseline.tsv` | `test-kb-forward-authored-marker.sh` | 15 | baseline, re-recorded at the gate |
| 86 | `tests/coverage-baseline.tsv` | `test-kb-freshness-check.sh` | 21 | baseline, re-recorded at the gate |
| 87 | `tests/coverage-baseline.tsv` | `test-kb-index-extract-list.sh` | 14 | baseline, re-recorded at the gate |
| 88 | `tests/coverage-baseline.tsv` | `test-kb-review-surface.sh` | 7 | baseline, re-recorded at the gate |
| 89 | `tests/coverage-baseline.tsv` | `test-kb-template-authoring-standard.sh` | 11 | baseline, re-recorded at the gate |
| 90 | `tests/coverage-baseline.tsv` | `test-landscape.md` | 5 | baseline, re-recorded at the gate |
| 91 | `tests/coverage-baseline.tsv` | `test-migrate-kb-frontmatter.sh` | 60 | baseline, re-recorded at the gate |
| 92 | `tests/coverage-baseline.tsv` | `test-multitool-isolation.sh` | 30 | baseline, re-recorded at the gate |
| 93 | `tests/coverage-baseline.tsv` | `test-npm-installer.sh` | 37 | baseline, re-recorded at the gate |
| 94 | `tests/coverage-baseline.tsv` | `test-output-root-isolation.sh` | 24 | baseline, re-recorded at the gate |
| 95 | `tests/coverage-baseline.tsv` | `test-path-fixtures.sh` | 20 | baseline, re-recorded at the gate |
| 96 | `tests/coverage-baseline.tsv` | `test-payload-size.sh` | 10 | baseline, re-recorded at the gate |
| 97 | `tests/coverage-baseline.tsv` | `test-pipeline-status-walkthrough.sh` | 163 | baseline, re-recorded at the gate |
| 98 | `tests/coverage-baseline.tsv` | `test-producer-completeness.sh` | 9 | baseline, re-recorded at the gate |
| 99 | `tests/coverage-baseline.tsv` | `test-prototype-family-scaffold.sh` | 48 | baseline, re-recorded at the gate |
| 100 | `tests/coverage-baseline.tsv` | `test-ps51-compat.sh` | 1 | baseline, re-recorded at the gate |
| 101 | `tests/coverage-baseline.tsv` | `test-pypi-installer.sh` | 37 | baseline, re-recorded at the gate |
| 102 | `tests/coverage-baseline.tsv` | `test-reconcile-scenarios.sh` | 49 | baseline, re-recorded at the gate |
| 103 | `tests/coverage-baseline.tsv` | `test-registry.sh` | 258 | baseline, re-recorded at the gate |
| 104 | `tests/coverage-baseline.tsv` | `test-release-install-e2e.sh` | 114 | baseline, re-recorded at the gate |
| 105 | `tests/coverage-baseline.tsv` | `test-release-migrate-smoke.sh` | 10 | baseline, re-recorded at the gate |
| 106 | `tests/coverage-baseline.tsv` | `test-release.sh` | 15 | baseline, re-recorded at the gate |
| 107 | `tests/coverage-baseline.tsv` | `test-shortcut-builder-invariants.sh` | 43 | baseline, re-recorded at the gate |
| 108 | `tests/coverage-baseline.tsv` | `test-shortcut-engine-contract.sh` | 24 | baseline, re-recorded at the gate |
| 109 | `tests/coverage-baseline.tsv` | `test-spine-depth-coverage.sh` | 13 | baseline, re-recorded at the gate |
| 110 | `tests/coverage-baseline.tsv` | `test-state-review-surface.sh` | 18 | baseline, re-recorded at the gate |
| 111 | `tests/coverage-baseline.tsv` | `test-summarize-preflight.sh` | 20 | baseline, re-recorded at the gate |
| 112 | `tests/coverage-baseline.tsv` | `test-task-state-transitions.sh` | 16 | baseline, re-recorded at the gate |
| 113 | `tests/coverage-baseline.tsv` | `test-teachback-fixtures.sh` | 13 | baseline, re-recorded at the gate |
| 114 | `tests/coverage-baseline.tsv` | `test-test-experiment-family-scaffold.sh` | 46 | baseline, re-recorded at the gate |
| 115 | `tests/coverage-baseline.tsv` | `test-ticket-retirement-structural.sh` | 98 | baseline, re-recorded at the gate |
| 116 | `tests/coverage-baseline.tsv` | `test-ticket-skills-structural.sh` | 88 | baseline, re-recorded at the gate |
| 117 | `tests/coverage-baseline.tsv` | `test-update-kb-scope-fidelity.sh` | 110 | baseline, re-recorded at the gate |
| 118 | `tests/coverage-baseline.tsv` | `test-validator-behavior.sh` | 66 | baseline, re-recorded at the gate |
| 119 | `tests/coverage-baseline.tsv` | `test-version-sync.sh` | 23 | baseline, re-recorded at the gate |
| 120 | `tests/coverage-baseline.tsv` | `test-work-initiation-gate.sh` | 94 | baseline, re-recorded at the gate |
| 121 | `tests/coverage-baseline.tsv` | `test-work-state-template.sh` | 18 | baseline, re-recorded at the gate |
| 122 | `tests/coverage-baseline.tsv` | `test-worktree-lifecycle.sh` | 116 | baseline, re-recorded at the gate |
| 123 | `tests/coverage-baseline.tsv` | `test-write-connector.sh` | 75 | baseline, re-recorded at the gate |
| 124 | `tests/coverage-baseline.tsv` | `test-write-external-source.sh` | 55 | baseline, re-recorded at the gate |
| 125 | `tests/coverage-baseline.tsv` | `test-writeback-state.sh` | 375 | baseline, re-recorded at the gate |
| 126 | `tests/coverage-baseline.tsv` | `ticket-resolution.md` | 3 | baseline, re-recorded at the gate |
| 127 | `tests/coverage-baseline.tsv` | `work-initiation-gate.md` | 1 | baseline, re-recorded at the gate |
| 128 | `tests/coverage-baseline.tsv` | `work-state-template.yml` | 1 | baseline, re-recorded at the gate |
| 129 | `tests/coverage-baseline.tsv` | `writeback-state.sh` | 380 | baseline, re-recorded at the gate |

## Installed copies (resync)

`.aid/runtime/` is the installed copy of `canonical/` (the resync step refreshes it at the gate). Command (run from the repo root; the P1-P5 forms over the installed copy):

```bash
# Installed copies (.aid/runtime is the installed copy of canonical/): the P1-P5 forms, run from the repo root
OLD='(Describe|Define|Specify|Plan|Detail|Execute)'
git grep -n -E -e 'PAUSE-FOR-USER' -e '\*\*Advance:\*\*' -e 'initiator:' -e "lifecycle: ['\"]?(Completed|Canceled)" -e '--field Phase --value' -e "phase: $OLD\b" -e "Phase\.$OLD\b" -e "['\"]$OLD['\"]" -e "$OLD \| $OLD\b" -e 'work-state-template\.yml` to' -e '^(active_skill|step|step_detail|phase):' -e 'resume door' -e '`?phase`?-matched' -e '[A-Z][a-z]+-phase work' -e 'route per the chosen work' -- .aid/runtime
```

| # | Installed file | Lines | Owner |
|---|---|---|---|
| 1 | `.aid/runtime/scripts/execute/writeback-state.sh` | 2 | installed copy (resync) |
| 2 | `.aid/runtime/scripts/summarize/validate-diagram-content.mjs` | 1 | installed copy (resync) |
| 3 | `.aid/runtime/templates/connectors/ticket-resolution.md` | 1 | installed copy (resync) |
| 4 | `.aid/runtime/templates/design-lifecycle.md` | 1 | installed copy (resync) |
| 5 | `.aid/runtime/templates/shortcut-engine.md` | 22 | installed copy (resync) |
| 6 | `.aid/runtime/templates/state-machine-chaining.md` | 12 | installed copy (resync) |
| 7 | `.aid/runtime/templates/work-initiation-gate.md` | 2 | installed copy (resync) |
| 8 | `.aid/runtime/templates/work-state-template.yml` | 5 | installed copy (resync) |

## Skill owner table (G2)

Built from `ls canonical/skills/*/SKILL.md` (112 files at the base; the command is `ls canonical/skills/*/SKILL.md | wc -l`). One row per file. A skill is owned by the task whose Scope or group names it; a skill that no task edits says `no change needed here` with the reason.

```bash
ls canonical/skills/*/SKILL.md | wc -l
ls canonical/skills/*/SKILL.md
```

| # | SKILL.md | Owner | Basis |
|---|---|---|---|
| 1 | `canonical/skills/aid-ask/SKILL.md` | task-042 | Sweep (a)-(c) and the group (d) sites listed in the task file |
| 2 | `canonical/skills/aid-brainstorm/SKILL.md` | task-034 | Sweep (a)-(c) on its Dispatch / State section; binding lines stay (exempt, SS-14) |
| 3 | `canonical/skills/aid-chat/SKILL.md` | no change needed here | in the task-043 group, but no Dispatch table, State section, advance word, phase or lifecycle text: needs no change (G2 note of that task) |
| 4 | `canonical/skills/aid-config/SKILL.md` | no change needed here | in the task-043 group, but no Dispatch table, State section, advance word, phase or lifecycle text: needs no change (G2 note of that task) |
| 5 | `canonical/skills/aid-create/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 6 | `canonical/skills/aid-create-api/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 7 | `canonical/skills/aid-create-architecture/SKILL.md` | task-036 | KB-writing skill: sweep (a)-(c); its binding line and finish stay (exempt, Feature 004) |
| 8 | `canonical/skills/aid-create-backlog/SKILL.md` | task-036 | KB-writing skill: sweep (a)-(c); its binding line and finish stay (exempt, Feature 004) |
| 9 | `canonical/skills/aid-create-cicd/SKILL.md` | task-036 | KB-writing skill: sweep (a)-(c); its binding line and finish stay (exempt, Feature 004) |
| 10 | `canonical/skills/aid-create-cli/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 11 | `canonical/skills/aid-create-config/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 12 | `canonical/skills/aid-create-dashboard/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 13 | `canonical/skills/aid-create-data-model/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 14 | `canonical/skills/aid-create-data-pipeline/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 15 | `canonical/skills/aid-create-diagram/SKILL.md` | no change needed here | hand-authored kind sibling of the task-044 group: no Dispatch table, State section, advance word or chaining citation |
| 16 | `canonical/skills/aid-create-document/SKILL.md` | task-044 | Starter: allocates through the gate 3a, continuation one-liner, writer finish (converted) |
| 17 | `canonical/skills/aid-create-infra/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 18 | `canonical/skills/aid-create-integration/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 19 | `canonical/skills/aid-create-job/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 20 | `canonical/skills/aid-create-messaging/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 21 | `canonical/skills/aid-create-mvp/SKILL.md` | task-036 | KB-writing skill: sweep (a)-(c); its binding line and finish stay (exempt, Feature 004) |
| 22 | `canonical/skills/aid-create-roadmap/SKILL.md` | task-036 | KB-writing skill: sweep (a)-(c); its binding line and finish stay (exempt, Feature 004) |
| 23 | `canonical/skills/aid-create-stack/SKILL.md` | task-036 | KB-writing skill: sweep (a)-(c); its binding line and finish stay (exempt, Feature 004) |
| 24 | `canonical/skills/aid-create-test/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 25 | `canonical/skills/aid-create-testing-strategy/SKILL.md` | task-036 | KB-writing skill: sweep (a)-(c); its binding line and finish stay (exempt, Feature 004) |
| 26 | `canonical/skills/aid-create-theme/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 27 | `canonical/skills/aid-create-ticket/SKILL.md` | task-043 | KB-writing skill: sweep (a)-(c); its binding line and finish stay (exempt, Feature 004) |
| 28 | `canonical/skills/aid-create-ui/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 29 | `canonical/skills/aid-define/SKILL.md` | task-039 | Sweep (a)-(c) and the group (d) sites listed in the task file |
| 30 | `canonical/skills/aid-deploy/SKILL.md` | task-043 | Sweep (a)-(c) and the group (d) sites listed in the task file |
| 31 | `canonical/skills/aid-deprecate/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 32 | `canonical/skills/aid-describe/SKILL.md` | task-038 | Sweep (a)-(c) and the group (d) sites listed in the task file |
| 33 | `canonical/skills/aid-design/SKILL.md` | task-034 | Sweep (a)-(c); (d) per group note |
| 34 | `canonical/skills/aid-design-api/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 35 | `canonical/skills/aid-design-architecture/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 36 | `canonical/skills/aid-design-backlog/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 37 | `canonical/skills/aid-design-cicd/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 38 | `canonical/skills/aid-design-cli/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 39 | `canonical/skills/aid-design-config/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 40 | `canonical/skills/aid-design-dashboard/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 41 | `canonical/skills/aid-design-data-model/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 42 | `canonical/skills/aid-design-data-pipeline/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 43 | `canonical/skills/aid-design-document/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 44 | `canonical/skills/aid-design-infra/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 45 | `canonical/skills/aid-design-integration/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 46 | `canonical/skills/aid-design-job/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 47 | `canonical/skills/aid-design-messaging/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 48 | `canonical/skills/aid-design-mvp/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 49 | `canonical/skills/aid-design-roadmap/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 50 | `canonical/skills/aid-design-stack/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 51 | `canonical/skills/aid-design-test/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 52 | `canonical/skills/aid-design-testing-strategy/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 53 | `canonical/skills/aid-design-theme/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 54 | `canonical/skills/aid-design-ui/SKILL.md` | task-035 | Sweep (a)-(c); (d) per group note |
| 55 | `canonical/skills/aid-detail/SKILL.md` | task-040 | Sweep (a)-(c) and the group (d) sites listed in the task file |
| 56 | `canonical/skills/aid-discover/SKILL.md` | task-041 | Sweep (a)-(c) and the group (d) sites listed in the task file |
| 57 | `canonical/skills/aid-document/SKILL.md` | no change needed here | hand-authored kind sibling of the task-044 group: no Dispatch table, State section, advance word or chaining citation |
| 58 | `canonical/skills/aid-document-architecture/SKILL.md` | no change needed here | hand-authored kind sibling of the task-044 group: no Dispatch table, State section, advance word or chaining citation |
| 59 | `canonical/skills/aid-document-changelog/SKILL.md` | no change needed here | hand-authored kind sibling of the task-044 group: no Dispatch table, State section, advance word or chaining citation |
| 60 | `canonical/skills/aid-document-decision/SKILL.md` | no change needed here | hand-authored kind sibling of the task-044 group: no Dispatch table, State section, advance word or chaining citation |
| 61 | `canonical/skills/aid-document-guideline/SKILL.md` | no change needed here | hand-authored kind sibling of the task-044 group: no Dispatch table, State section, advance word or chaining citation |
| 62 | `canonical/skills/aid-document-runbook/SKILL.md` | no change needed here | hand-authored kind sibling of the task-044 group: no Dispatch table, State section, advance word or chaining citation |
| 63 | `canonical/skills/aid-document-standard/SKILL.md` | no change needed here | hand-authored kind sibling of the task-044 group: no Dispatch table, State section, advance word or chaining citation |
| 64 | `canonical/skills/aid-document-tutorial/SKILL.md` | no change needed here | hand-authored kind sibling of the task-044 group: no Dispatch table, State section, advance word or chaining citation |
| 65 | `canonical/skills/aid-execute/SKILL.md` | task-040 | Sweep (a)-(c) and the group (d) sites listed in the task file |
| 66 | `canonical/skills/aid-experiment/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 67 | `canonical/skills/aid-fix/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 68 | `canonical/skills/aid-housekeep/SKILL.md` | task-042 | Sweep (a)-(c) and the group (d) sites listed in the task file |
| 69 | `canonical/skills/aid-migrate/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 70 | `canonical/skills/aid-monitor/SKILL.md` | task-043 | Sweep (a)-(c) and the group (d) sites listed in the task file |
| 71 | `canonical/skills/aid-orchestrate/SKILL.md` | task-032 | Start, resume and cancel through the writer; cites skill-steps.md; rules.md bullet |
| 72 | `canonical/skills/aid-plan/SKILL.md` | task-040 | Sweep (a)-(c) and the group (d) sites listed in the task file |
| 73 | `canonical/skills/aid-prototype/SKILL.md` | task-044 | Starter: allocates through the gate 3a, continuation one-liner, writer finish (converted) |
| 74 | `canonical/skills/aid-prototype-ui/SKILL.md` | no change needed here | hand-authored kind sibling of the task-044 group: no Dispatch table, State section, advance word or chaining citation |
| 75 | `canonical/skills/aid-read-ticket/SKILL.md` | task-043 | Sweep (a)-(c) and the group (d) sites listed in the task file |
| 76 | `canonical/skills/aid-refactor/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 77 | `canonical/skills/aid-remove/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 78 | `canonical/skills/aid-report/SKILL.md` | task-044 | Starter: allocates through the gate 3a, continuation one-liner, writer finish (converted) |
| 79 | `canonical/skills/aid-research/SKILL.md` | task-044 | Starter: allocates through the gate 3a, continuation one-liner, writer finish (converted) |
| 80 | `canonical/skills/aid-review/SKILL.md` | task-044 | Starter: allocates through the gate 3a, continuation one-liner, writer finish (converted) |
| 81 | `canonical/skills/aid-set-connector/SKILL.md` | no change needed here | in the task-043 group, but no Dispatch table, State section, advance word, phase or lifecycle text: needs no change (G2 note of that task) |
| 82 | `canonical/skills/aid-specify/SKILL.md` | task-039 | Sweep (a)-(c) and the group (d) sites listed in the task file |
| 83 | `canonical/skills/aid-summarize/SKILL.md` | task-042 | Sweep (a)-(c) and the group (d) sites listed in the task file |
| 84 | `canonical/skills/aid-test/SKILL.md` | task-044 | Starter: allocates through the gate 3a, continuation one-liner, writer finish (converted) |
| 85 | `canonical/skills/aid-test-data-quality/SKILL.md` | no change needed here | hand-authored kind sibling of the task-044 group: no Dispatch table, State section, advance word or chaining citation |
| 86 | `canonical/skills/aid-test-performance/SKILL.md` | no change needed here | hand-authored kind sibling of the task-044 group: no Dispatch table, State section, advance word or chaining citation |
| 87 | `canonical/skills/aid-test-security/SKILL.md` | no change needed here | hand-authored kind sibling of the task-044 group: no Dispatch table, State section, advance word or chaining citation |
| 88 | `canonical/skills/aid-unset-connector/SKILL.md` | no change needed here | in the task-043 group, but no Dispatch table, State section, advance word, phase or lifecycle text: needs no change (G2 note of that task) |
| 89 | `canonical/skills/aid-update/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 90 | `canonical/skills/aid-update-api/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 91 | `canonical/skills/aid-update-architecture/SKILL.md` | task-036 | KB-writing skill: sweep (a)-(c); its binding line and finish stay (exempt, Feature 004) |
| 92 | `canonical/skills/aid-update-backlog/SKILL.md` | task-036 | KB-writing skill: sweep (a)-(c); its binding line and finish stay (exempt, Feature 004) |
| 93 | `canonical/skills/aid-update-cicd/SKILL.md` | task-036 | KB-writing skill: sweep (a)-(c); its binding line and finish stay (exempt, Feature 004) |
| 94 | `canonical/skills/aid-update-cli/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 95 | `canonical/skills/aid-update-config/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 96 | `canonical/skills/aid-update-dashboard/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 97 | `canonical/skills/aid-update-data-model/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 98 | `canonical/skills/aid-update-data-pipeline/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 99 | `canonical/skills/aid-update-document/SKILL.md` | task-044 | Starter: allocates through the gate 3a, continuation one-liner, writer finish (converted) |
| 100 | `canonical/skills/aid-update-infra/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 101 | `canonical/skills/aid-update-integration/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 102 | `canonical/skills/aid-update-job/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 103 | `canonical/skills/aid-update-kb/SKILL.md` | task-042 | KB-writing skill: sweep (a)-(c); its binding line and finish stay (exempt, Feature 004) |
| 104 | `canonical/skills/aid-update-messaging/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 105 | `canonical/skills/aid-update-mvp/SKILL.md` | task-036 | KB-writing skill: sweep (a)-(c); its binding line and finish stay (exempt, Feature 004) |
| 106 | `canonical/skills/aid-update-roadmap/SKILL.md` | task-036 | KB-writing skill: sweep (a)-(c); its binding line and finish stay (exempt, Feature 004) |
| 107 | `canonical/skills/aid-update-stack/SKILL.md` | task-036 | KB-writing skill: sweep (a)-(c); its binding line and finish stay (exempt, Feature 004) |
| 108 | `canonical/skills/aid-update-test/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 109 | `canonical/skills/aid-update-testing-strategy/SKILL.md` | task-036 | KB-writing skill: sweep (a)-(c); its binding line and finish stay (exempt, Feature 004) |
| 110 | `canonical/skills/aid-update-theme/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |
| 111 | `canonical/skills/aid-update-ticket/SKILL.md` | no change needed here | in the task-043 group, but no Dispatch table, State section, advance word, phase or lifecycle text: needs no change (G2 note of that task) |
| 112 | `canonical/skills/aid-update-ui/SKILL.md` | no change needed here | generated doorway: changes through the builder (shortcut-catalog.yml and shortcut-engine.md, task-037) |

Row count: 112 = 112 files on disk. Rows with an empty owner: 0. Rows owned by a task: 60; `no change needed here`: 52.

## Suites that two tasks share, and the run order

A suite is listed when the hits in it are owned by two or more tasks of delivery-002. "Independent" means that neither task is in the other's dependency closure in the delivery-002 Execution Graph (PLAN.md). Every listed suite runs after all its tasks are Done; the run order is a topological order of those tasks by the graph, ties broken by task number. The two-task pairs that are independent are the ones the spec asks to list with an order.

| # | Suite | Tasks | Independent pairs | Dependent pairs | Run order |
|---|---|---|---|---|---|
| 1 | `dashboard/reader/tests/fixtures/task011_golden/flat_golden.json` | task-031, task-040 | - | task-040 after task-031 | task-031 -> task-040 |
| 2 | `dashboard/reader/tests/fixtures/task011_golden/hierarchical_golden.json` | task-031, task-040 | - | task-040 after task-031 | task-031 -> task-040 |
| 3 | `dashboard/reader/tests/test_declared_path_three_way_parity.py` | task-025, task-031 | - | task-025 after task-031 | task-031 -> task-025 |
| 4 | `dashboard/reader/tests/test_feature009.py` | task-031, task-038, task-040 | task-038/task-040 | task-038 after task-031; task-040 after task-031 | task-031 -> task-038 -> task-040 |
| 5 | `dashboard/reader/tests/test_fixtures.py` | task-031, task-039, task-040 | - | task-039 after task-031; task-040 after task-031; task-040 after task-039 | task-031 -> task-039 -> task-040 |
| 6 | `dashboard/reader/tests/test_flattened_layout_parity.py` | task-031, task-033, task-039, task-040 | task-033/task-039, task-033/task-040 | task-033 after task-031; task-039 after task-031; task-040 after task-031; task-040 after task-039 | task-031 -> task-033 -> task-039 -> task-040 |
| 7 | `dashboard/reader/tests/test_integration.py` | task-025, task-031 | - | task-025 after task-031 | task-031 -> task-025 |
| 8 | `dashboard/reader/tests/test_reader.py` | task-031, task-039, task-040, task-043, task-049 | task-039/task-043, task-040/task-043 | task-039 after task-031; task-040 after task-031; task-043 after task-031; task-049 after task-031; task-040 after task-039; task-049 after task-039; task-049 after task-040; task-049 after task-043 | task-031 -> task-039 -> task-040 -> task-043 -> task-049 |
| 9 | `dashboard/reader/tests/test_resolve_work_dir_cross_runtime_parity.py` | task-031, task-040 | - | task-040 after task-031 | task-031 -> task-040 |
| 10 | `dashboard/reader/tests/test_security_hardening.py` | task-031, task-040 | - | task-040 after task-031 | task-031 -> task-040 |
| 11 | `dashboard/reader/tests/test_shortcut_kind_map_cross_runtime_parity.py` | task-031, task-038 | - | task-038 after task-031 | task-031 -> task-038 |
| 12 | `dashboard/reader/tests/test_task011_golden_master.py` | task-031, task-040 | - | task-040 after task-031 | task-031 -> task-040 |
| 13 | `dashboard/reader/tests/test_task014_fixtures.py` | task-031, task-039, task-040 | - | task-039 after task-031; task-040 after task-031; task-040 after task-039 | task-031 -> task-039 -> task-040 |
| 14 | `dashboard/reader/tests/test_task019_connectors.py` | task-031, task-057 | - | task-057 after task-031 | task-031 -> task-057 |
| 15 | `dashboard/reader/tests/test_task066_kb_parity.py` | task-031, task-041 | - | task-041 after task-031 | task-031 -> task-041 |
| 16 | `dashboard/reader/tests/test_task069_detail_parser.py` | task-031, task-040 | - | task-040 after task-031 | task-031 -> task-040 |
| 17 | `dashboard/reader/tests/test_work001_delivery_layouts.py` | task-031, task-040 | - | task-040 after task-031 | task-031 -> task-040 |
| 18 | `dashboard/reader/tests/test_work003_state_schema.py` | task-031, task-038, task-039, task-040, task-044 | task-038/task-039, task-038/task-040, task-038/task-044, task-039/task-044, task-040/task-044 | task-038 after task-031; task-039 after task-031; task-040 after task-031; task-044 after task-031; task-040 after task-039 | task-031 -> task-038 -> task-039 -> task-040 -> task-044 |
| 19 | `dashboard/reader/tests/test_work016_container_discovery.py` | task-031, task-033, task-040 | task-033/task-040 | task-033 after task-031; task-040 after task-031 | task-031 -> task-033 -> task-040 |
| 20 | `dashboard/server/tests/test_home_html_project_header.py` | task-031, task-033 | - | task-033 after task-031 | task-031 -> task-033 |
| 21 | `dashboard/server/tests/test_index_html.py` | task-031, task-033, task-038, task-041, task-042, task-043 | task-033/task-038, task-033/task-041, task-033/task-042, task-033/task-043, task-038/task-041, task-038/task-042, task-038/task-043, task-041/task-042, task-041/task-043, task-042/task-043 | task-033 after task-031; task-038 after task-031; task-041 after task-031; task-042 after task-031; task-043 after task-031 | task-031 -> task-033 -> task-038 -> task-041 -> task-042 -> task-043 |
| 22 | `dashboard/server/tests/test_reader_task069.mjs` | task-031, task-040, task-044 | task-040/task-044 | task-040 after task-031; task-044 after task-031 | task-031 -> task-040 -> task-044 |
| 23 | `dashboard/server/tests/test_server_node.mjs` | task-031, task-033, task-043 | task-033/task-043 | task-033 after task-031; task-043 after task-031 | task-031 -> task-033 -> task-043 |
| 24 | `dashboard/server/tests/test_server_py.py` | task-031, task-033 | - | task-033 after task-031 | task-031 -> task-033 |
| 25 | `dashboard/server/tests/test_task002_resolve_work_dir.mjs` | task-031, task-040 | - | task-040 after task-031 | task-031 -> task-040 |
| 26 | `dashboard/server/tests/test_task010_task_notes.py` | task-025, task-031, task-033 | task-025/task-033 | task-025 after task-031; task-033 after task-031 | task-031 -> task-025 -> task-033 |
| 27 | `dashboard/server/tests/test_task010_task_notes_cross_runtime_parity.py` | task-025, task-031 | - | task-025 after task-031 | task-031 -> task-025 |
| 28 | `dashboard/server/tests/test_task011_dispatch_round_trip.mjs` | task-025, task-031 | - | task-025 after task-031 | task-031 -> task-025 |
| 29 | `dashboard/server/tests/test_task011_dispatch_round_trip.py` | task-025, task-031 | - | task-025 after task-031 | task-031 -> task-025 |
| 30 | `dashboard/server/tests/test_task012_consuming_round_trips.py` | task-025, task-031, task-033, task-043 | task-025/task-033, task-033/task-043 | task-025 after task-031; task-043 after task-025; task-033 after task-031; task-043 after task-031 | task-031 -> task-025 -> task-033 -> task-043 |
| 31 | `dashboard/server/tests/test_task019_connector_ops.mjs` | task-031, task-057 | - | task-057 after task-031 | task-031 -> task-057 |
| 32 | `dashboard/server/tests/test_task022_connectors_external_sources_ui.py` | task-031, task-033 | - | task-033 after task-031 | task-031 -> task-033 |
| 33 | `dashboard/server/tests/test_task023_list_management_round_trips.py` | task-031, task-057 | - | task-057 after task-031 | task-031 -> task-057 |
| 34 | `dashboard/server/tests/test_task029_task_stop_resume_ops.mjs` | task-025, task-031 | - | task-025 after task-031 | task-031 -> task-025 |
| 35 | `dashboard/server/tests/test_task030_finish_stop_resume_ui.py` | task-025, task-031, task-033 | task-025/task-033 | task-025 after task-031; task-033 after task-031 | task-031 -> task-025 -> task-033 |
| 36 | `dashboard/server/tests/test_task033_execution_control_round_trips.py` | task-025, task-031, task-033 | task-025/task-033 | task-025 after task-031; task-033 after task-031 | task-031 -> task-025 -> task-033 |
| 37 | `dashboard/server/tests/test_tools_management_ui.py` | task-031, task-033 | - | task-033 after task-031 | task-031 -> task-033 |
| 38 | `dashboard/server/tests/test_write_enabled_cross_runtime_parity.py` | task-025, task-031 | - | task-025 after task-031 | task-031 -> task-025 |
| 39 | `site/scripts/__tests__/flow-advance.test.mjs` | task-024, task-034, task-039, task-041, task-042, task-043, task-044 | task-034/task-039, task-034/task-041, task-034/task-042, task-034/task-043, task-034/task-044, task-039/task-041, task-039/task-042, task-039/task-043, task-039/task-044, task-041/task-042, task-041/task-043, task-041/task-044, task-042/task-043, task-042/task-044, task-043/task-044 | task-034 after task-024; task-039 after task-024; task-041 after task-024; task-042 after task-024; task-043 after task-024; task-044 after task-024 | task-024 -> task-034 -> task-039 -> task-041 -> task-042 -> task-043 -> task-044 |
| 40 | `site/scripts/__tests__/flow-classify.test.mjs` | task-037, task-044 | task-037/task-044 | - | task-037 -> task-044 |
| 41 | `site/scripts/__tests__/flow-compose.test.mjs` | task-037, task-044 | task-037/task-044 | - | task-037 -> task-044 |
| 42 | `site/scripts/__tests__/flow-engine-core.test.mjs` | task-030, task-037 | - | task-037 after task-030 | task-030 -> task-037 |
| 43 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-024, task-038, task-039, task-040, task-041, task-042, task-043 | task-038/task-039, task-038/task-040, task-038/task-041, task-038/task-042, task-038/task-043, task-039/task-041, task-039/task-042, task-039/task-043, task-040/task-041, task-040/task-042, task-040/task-043, task-041/task-042, task-041/task-043, task-042/task-043 | task-038 after task-024; task-039 after task-024; task-040 after task-024; task-041 after task-024; task-042 after task-024; task-043 after task-024; task-040 after task-039 | task-024 -> task-038 -> task-039 -> task-040 -> task-041 -> task-042 -> task-043 |
| 44 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | task-037, task-040 | task-037/task-040 | - | task-037 -> task-040 |
| 45 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | task-024, task-034, task-044 | task-034/task-044 | task-034 after task-024; task-044 after task-024 | task-024 -> task-034 -> task-044 |
| 46 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | task-042, task-043, task-044 | task-042/task-043, task-042/task-044, task-043/task-044 | - | task-042 -> task-043 -> task-044 |
| 47 | `site/scripts/__tests__/flow-facade.test.mjs` | task-038, task-042, task-043, task-044 | task-038/task-042, task-038/task-043, task-038/task-044, task-042/task-043, task-042/task-044, task-043/task-044 | - | task-038 -> task-042 -> task-043 -> task-044 |
| 48 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-030, task-037, task-040, task-044 | task-037/task-040, task-037/task-044, task-040/task-044 | task-037 after task-030; task-040 after task-030; task-044 after task-030 | task-030 -> task-037 -> task-040 -> task-044 |
| 49 | `site/scripts/__tests__/flow-graph.test.mjs` | task-024, task-037, task-038, task-039, task-042, task-044 | task-037/task-038, task-037/task-039, task-037/task-042, task-037/task-044, task-038/task-039, task-038/task-042, task-038/task-044, task-039/task-042, task-039/task-044, task-042/task-044 | task-037 after task-024; task-038 after task-024; task-039 after task-024; task-042 after task-024; task-044 after task-024 | task-024 -> task-037 -> task-038 -> task-039 -> task-042 -> task-044 |
| 50 | `site/scripts/__tests__/flow-render-mermaid.test.mjs` | task-040, task-044 | task-040/task-044 | - | task-040 -> task-044 |
| 51 | `site/scripts/__tests__/flow-validate.test.mjs` | task-024, task-044 | - | task-044 after task-024 | task-024 -> task-044 |
| 52 | `site/scripts/__tests__/gen-reference.test.mjs` | task-032, task-037, task-038, task-039, task-040, task-041, task-042, task-043 | task-032/task-037, task-032/task-038, task-032/task-039, task-032/task-040, task-032/task-041, task-032/task-042, task-032/task-043, task-037/task-038, task-037/task-039, task-037/task-040, task-037/task-041, task-037/task-042, task-037/task-043, task-038/task-039, task-038/task-040, task-038/task-041, task-038/task-042, task-038/task-043, task-039/task-041, task-039/task-042, task-039/task-043, task-040/task-041, task-040/task-042, task-040/task-043, task-041/task-042, task-041/task-043, task-042/task-043 | task-040 after task-039 | task-032 -> task-037 -> task-038 -> task-039 -> task-040 -> task-041 -> task-042 -> task-043 |
| 53 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-032, task-038, task-039, task-040, task-043 | task-032/task-038, task-032/task-039, task-032/task-040, task-032/task-043, task-038/task-039, task-038/task-040, task-038/task-043, task-039/task-043, task-040/task-043 | task-040 after task-039 | task-032 -> task-038 -> task-039 -> task-040 -> task-043 |
| 54 | `site/scripts/__tests__/gen-skills.test.mjs` | task-040, task-041, task-042, task-043 | task-040/task-041, task-040/task-042, task-040/task-043, task-041/task-042, task-041/task-043, task-042/task-043 | - | task-040 -> task-041 -> task-042 -> task-043 |
| 55 | `site/scripts/__tests__/provenance-appender.test.mjs` | task-037, task-042, task-044 | task-037/task-042, task-037/task-044, task-042/task-044 | - | task-037 -> task-042 -> task-044 |
| 56 | `site/scripts/__tests__/provenance.test.mjs` | task-042, task-044 | task-042/task-044 | - | task-042 -> task-044 |
| 57 | `site/scripts/__tests__/skills-groups.test.mjs` | task-032, task-038, task-039, task-040, task-043 | task-032/task-038, task-032/task-039, task-032/task-040, task-032/task-043, task-038/task-039, task-038/task-040, task-038/task-043, task-039/task-043, task-040/task-043 | task-040 after task-039 | task-032 -> task-038 -> task-039 -> task-040 -> task-043 |
| 58 | `site/scripts/__tests__/skills-render-index.test.mjs` | task-032, task-043 | task-032/task-043 | - | task-032 -> task-043 |
| 59 | `site/scripts/__tests__/skills-render-page.test.mjs` | task-043, task-044 | task-043/task-044 | - | task-043 -> task-044 |
| 60 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | task-037, task-042 | task-037/task-042 | - | task-037 -> task-042 |
| 61 | `site/src/lib/__tests__/skill-node-panel.test.ts` | task-040, task-042 | task-040/task-042 | - | task-040 -> task-042 |
| 62 | `tests/README.md` | task-025, task-040, task-041, task-044 | task-040/task-041, task-040/task-044, task-041/task-044 | task-040 after task-025; task-041 after task-025; task-044 after task-025 | task-025 -> task-040 -> task-041 -> task-044 |
| 63 | `tests/canonical/fixtures/actback-task/docset-check.tsv` | task-044, task-045 | task-044/task-045 | - | task-044 -> task-045 |
| 64 | `tests/canonical/fixtures/actback-task/docset-component.tsv` | task-044, task-049 | - | task-049 after task-044 | task-044 -> task-049 |
| 65 | `tests/canonical/fixtures/actback-task/docset-contract.tsv` | task-044, task-049 | - | task-049 after task-044 | task-044 -> task-049 |
| 66 | `tests/canonical/fixtures/dual-intent/content/doc-set.tsv` | task-044, task-045 | task-044/task-045 | - | task-044 -> task-045 |
| 67 | `tests/canonical/fixtures/dual-intent/data-ml/doc-set.tsv` | task-044, task-045 | task-044/task-045 | - | task-044 -> task-045 |
| 68 | `tests/canonical/fixtures/dual-intent/design/doc-set.tsv` | task-044, task-045 | task-044/task-045 | - | task-044 -> task-045 |
| 69 | `tests/canonical/fixtures/kb-essence/actback/representative-task-fixture/doc-set.tsv` | task-044, task-045 | task-044/task-045 | - | task-044 -> task-045 |
| 70 | `tests/canonical/test-actback-task.sh` | task-044, task-045, task-049 | task-044/task-045, task-045/task-049 | task-049 after task-044 | task-044 -> task-045 -> task-049 |
| 71 | `tests/canonical/test-aid-cli-parity.sh` | task-031, task-032, task-039, task-042, task-043, task-056 | task-032/task-039, task-032/task-042, task-032/task-043, task-039/task-042, task-039/task-043, task-042/task-043 | task-032 after task-031; task-039 after task-031; task-042 after task-031; task-043 after task-031; task-056 after task-031; task-056 after task-032; task-056 after task-039; task-056 after task-042; task-056 after task-043 | task-031 -> task-032 -> task-039 -> task-042 -> task-043 -> task-056 |
| 72 | `tests/canonical/test-aid-migrate-trigger.sh` | task-033, task-056 | - | task-056 after task-033 | task-033 -> task-056 |
| 73 | `tests/canonical/test-aid-migrate.sh` | task-032, task-033, task-040, task-042, task-056 | task-032/task-033, task-032/task-040, task-032/task-042, task-033/task-040, task-033/task-042, task-040/task-042 | task-056 after task-032; task-056 after task-033; task-056 after task-040; task-056 after task-042 | task-032 -> task-033 -> task-040 -> task-042 -> task-056 |
| 74 | `tests/canonical/test-artifact-discipline.sh` | task-025, task-031, task-037, task-039, task-040, task-044 | task-037/task-039, task-037/task-040, task-037/task-044, task-039/task-044, task-040/task-044 | task-025 after task-031; task-037 after task-025; task-039 after task-025; task-040 after task-025; task-044 after task-025; task-037 after task-031; task-039 after task-031; task-040 after task-031; task-044 after task-031; task-040 after task-039 | task-031 -> task-025 -> task-037 -> task-039 -> task-040 -> task-044 |
| 75 | `tests/canonical/test-ascii-only.sh` | task-031, task-056 | - | task-056 after task-031 | task-031 -> task-056 |
| 76 | `tests/canonical/test-catalog-dirs-parity.sh` | task-037, task-042, task-043 | task-037/task-042, task-037/task-043, task-042/task-043 | - | task-037 -> task-042 -> task-043 |
| 77 | `tests/canonical/test-change-refactor-family-scaffold.sh` | task-032, task-037, task-040, task-044 | task-032/task-037, task-032/task-040, task-032/task-044, task-037/task-040, task-037/task-044, task-040/task-044 | - | task-032 -> task-037 -> task-040 -> task-044 |
| 78 | `tests/canonical/test-chat-node-manifest.sh` | task-033, task-056 | - | task-056 after task-033 | task-033 -> task-056 |
| 79 | `tests/canonical/test-chat-node-wake.sh` | task-043, task-045 | task-043/task-045 | - | task-043 -> task-045 |
| 80 | `tests/canonical/test-closure-check.sh` | task-045, task-049 | task-045/task-049 | - | task-045 -> task-049 |
| 81 | `tests/canonical/test-conformance-lane-semantics.sh` | task-041, task-042, task-049 | task-041/task-042 | task-049 after task-041; task-049 after task-042 | task-041 -> task-042 -> task-049 |
| 82 | `tests/canonical/test-connector-consumption-linkage.sh` | task-021, task-038, task-039, task-040, task-042, task-043, task-044 | task-038/task-039, task-038/task-040, task-038/task-042, task-038/task-043, task-038/task-044, task-039/task-042, task-039/task-043, task-039/task-044, task-040/task-042, task-040/task-043, task-040/task-044, task-042/task-043, task-042/task-044, task-043/task-044 | task-038 after task-021; task-039 after task-021; task-040 after task-021; task-042 after task-021; task-043 after task-021; task-044 after task-021; task-040 after task-039 | task-021 -> task-038 -> task-039 -> task-040 -> task-042 -> task-043 -> task-044 |
| 83 | `tests/canonical/test-connector-set-unset-lifecycle.sh` | task-043, task-057 | - | task-057 after task-043 | task-043 -> task-057 |
| 84 | `tests/canonical/test-connector-skills-structural.sh` | task-032, task-041, task-042, task-043 | task-032/task-041, task-032/task-042, task-032/task-043, task-041/task-042, task-041/task-043, task-042/task-043 | - | task-032 -> task-041 -> task-042 -> task-043 |
| 85 | `tests/canonical/test-conversation-runner.sh` | task-040, task-044, task-056, task-057 | task-040/task-044 | task-056 after task-040; task-057 after task-040; task-056 after task-044; task-057 after task-044; task-057 after task-056 | task-040 -> task-044 -> task-056 -> task-057 |
| 86 | `tests/canonical/test-create-family-scaffold.sh` | task-032, task-037, task-040, task-044 | task-032/task-037, task-032/task-040, task-032/task-044, task-037/task-040, task-037/task-044, task-040/task-044 | - | task-032 -> task-037 -> task-040 -> task-044 |
| 87 | `tests/canonical/test-cutover-no-dangling.sh` | task-021, task-038, task-041, task-044 | task-038/task-041, task-038/task-044, task-041/task-044 | task-038 after task-021; task-041 after task-021; task-044 after task-021 | task-021 -> task-038 -> task-041 -> task-044 |
| 88 | `tests/canonical/test-dashboard-manifest.sh` | task-031, task-033, task-056 | - | task-033 after task-031; task-056 after task-031; task-056 after task-033 | task-031 -> task-033 -> task-056 |
| 89 | `tests/canonical/test-dashboard-parity-h.sh` | task-031, task-033 | - | task-033 after task-031 | task-031 -> task-033 |
| 90 | `tests/canonical/test-delivery-gate-aggregate.sh` | task-021, task-025, task-040 | - | task-025 after task-021; task-040 after task-021; task-040 after task-025 | task-021 -> task-025 -> task-040 |
| 91 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-032, task-037, task-038, task-040, task-042, task-043, task-044, task-049 | task-032/task-037, task-032/task-038, task-032/task-040, task-032/task-042, task-032/task-043, task-032/task-044, task-037/task-038, task-037/task-040, task-037/task-042, task-037/task-043, task-037/task-044, task-038/task-040, task-038/task-042, task-038/task-043, task-038/task-044, task-040/task-042, task-040/task-043, task-040/task-044, task-042/task-043, task-042/task-044, task-043/task-044 | task-049 after task-032; task-049 after task-037; task-049 after task-038; task-049 after task-040; task-049 after task-042; task-049 after task-043; task-049 after task-044 | task-032 -> task-037 -> task-038 -> task-040 -> task-042 -> task-043 -> task-044 -> task-049 |
| 92 | `tests/canonical/test-derive-waves.sh` | task-031, task-040 | - | task-040 after task-031 | task-031 -> task-040 |
| 93 | `tests/canonical/test-describe-full-only.sh` | task-021, task-038, task-044 | task-038/task-044 | task-038 after task-021; task-044 after task-021 | task-021 -> task-038 -> task-044 |
| 94 | `tests/canonical/test-discovery-doc-ownership.sh` | task-041, task-044, task-057 | task-041/task-044 | task-057 after task-041; task-057 after task-044 | task-041 -> task-044 -> task-057 |
| 95 | `tests/canonical/test-disjoint-merge.sh` | task-025, task-040, task-044 | task-040/task-044 | task-040 after task-025; task-044 after task-025 | task-025 -> task-040 -> task-044 |
| 96 | `tests/canonical/test-doc-set-mapping.sh` | task-041, task-044, task-045, task-049, task-057 | task-041/task-044, task-041/task-045, task-044/task-045, task-045/task-049 | task-049 after task-041; task-057 after task-041; task-049 after task-044; task-057 after task-044; task-057 after task-045; task-057 after task-049 | task-041 -> task-044 -> task-045 -> task-049 -> task-057 |
| 97 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-041, task-044, task-045, task-049, task-057 | task-041/task-044, task-041/task-045, task-044/task-045, task-045/task-049 | task-049 after task-041; task-057 after task-041; task-049 after task-044; task-057 after task-044; task-057 after task-045; task-057 after task-049 | task-041 -> task-044 -> task-045 -> task-049 -> task-057 |
| 98 | `tests/canonical/test-doc-set-read.sh` | task-041, task-044, task-049 | task-041/task-044 | task-049 after task-041; task-049 after task-044 | task-041 -> task-044 -> task-049 |
| 99 | `tests/canonical/test-document-family-scaffold.sh` | task-032, task-037, task-040, task-043, task-044 | task-032/task-037, task-032/task-040, task-032/task-043, task-032/task-044, task-037/task-040, task-037/task-043, task-037/task-044, task-040/task-043, task-040/task-044, task-043/task-044 | - | task-032 -> task-037 -> task-040 -> task-043 -> task-044 |
| 100 | `tests/canonical/test-dogfood-byte-identity.sh` | task-032, task-042 | task-032/task-042 | - | task-032 -> task-042 |
| 101 | `tests/canonical/test-domain-doc-matrix.sh` | task-041, task-045 | task-041/task-045 | - | task-041 -> task-045 |
| 102 | `tests/canonical/test-downstream-worktree-entry.sh` | task-037, task-039, task-040, task-043 | task-037/task-039, task-037/task-040, task-037/task-043, task-039/task-043, task-040/task-043 | task-040 after task-039 | task-037 -> task-039 -> task-040 -> task-043 |
| 103 | `tests/canonical/test-essence-capture.sh` | task-045, task-049 | task-045/task-049 | - | task-045 -> task-049 |
| 104 | `tests/canonical/test-expectations-single-source.sh` | task-041, task-044, task-049 | task-041/task-044 | task-049 after task-041; task-049 after task-044 | task-041 -> task-044 -> task-049 |
| 105 | `tests/canonical/test-fix-family-scaffold.sh` | task-037, task-040, task-044 | task-037/task-040, task-037/task-044, task-040/task-044 | - | task-037 -> task-040 -> task-044 |
| 106 | `tests/canonical/test-frontmatter-lint.sh` | task-049, task-057 | - | task-057 after task-049 | task-049 -> task-057 |
| 107 | `tests/canonical/test-grade-summary.sh` | task-033, task-041, task-042, task-044, task-045, task-049, task-057 | task-033/task-041, task-033/task-042, task-033/task-044, task-033/task-045, task-033/task-049, task-041/task-042, task-041/task-044, task-041/task-045, task-042/task-044, task-042/task-045, task-044/task-045, task-045/task-049 | task-057 after task-033; task-049 after task-041; task-057 after task-041; task-049 after task-042; task-057 after task-042; task-049 after task-044; task-057 after task-044; task-057 after task-045; task-057 after task-049 | task-033 -> task-041 -> task-042 -> task-044 -> task-045 -> task-049 -> task-057 |
| 108 | `tests/canonical/test-guardrails-d012.sh` | task-033, task-042, task-057 | task-033/task-042 | task-057 after task-033; task-057 after task-042 | task-033 -> task-042 -> task-057 |
| 109 | `tests/canonical/test-kb-html-claims-check.sh` | task-021, task-049 | - | task-049 after task-021 | task-021 -> task-049 |
| 110 | `tests/canonical/test-kb-review-surface.sh` | task-041, task-045, task-049, task-057 | task-041/task-045, task-045/task-049 | task-049 after task-041; task-057 after task-041; task-057 after task-045; task-057 after task-049 | task-041 -> task-045 -> task-049 -> task-057 |
| 111 | `tests/canonical/test-ledger-isolation.sh` | task-041, task-042 | task-041/task-042 | - | task-041 -> task-042 |
| 112 | `tests/canonical/test-lite-work-end-to-end.sh` | task-025, task-031 | - | task-025 after task-031 | task-031 -> task-025 |
| 113 | `tests/canonical/test-multitool-isolation.sh` | task-040, task-042 | task-040/task-042 | - | task-040 -> task-042 |
| 114 | `tests/canonical/test-output-root-isolation.sh` | task-041, task-042, task-045 | task-041/task-042, task-041/task-045, task-042/task-045 | - | task-041 -> task-042 -> task-045 |
| 115 | `tests/canonical/test-path-fixtures.sh` | task-038, task-041 | task-038/task-041 | - | task-038 -> task-041 |
| 116 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-025, task-038, task-039, task-040, task-043 | task-038/task-039, task-038/task-040, task-038/task-043, task-039/task-043, task-040/task-043 | task-038 after task-025; task-039 after task-025; task-040 after task-025; task-043 after task-025; task-040 after task-039 | task-025 -> task-038 -> task-039 -> task-040 -> task-043 |
| 117 | `tests/canonical/test-producer-completeness.sh` | task-031, task-040 | - | task-040 after task-031 | task-031 -> task-040 |
| 118 | `tests/canonical/test-prototype-family-scaffold.sh` | task-032, task-037, task-040, task-044 | task-032/task-037, task-032/task-040, task-032/task-044, task-037/task-040, task-037/task-044, task-040/task-044 | - | task-032 -> task-037 -> task-040 -> task-044 |
| 119 | `tests/canonical/test-reconcile-scenarios.sh` | task-041, task-057 | - | task-057 after task-041 | task-041 -> task-057 |
| 120 | `tests/canonical/test-release-install-e2e.sh` | task-032, task-044, task-056 | task-032/task-044 | task-056 after task-032; task-056 after task-044 | task-032 -> task-044 -> task-056 |
| 121 | `tests/canonical/test-release-migrate-smoke.sh` | task-033, task-056 | - | task-056 after task-033 | task-033 -> task-056 |
| 122 | `tests/canonical/test-release.sh` | task-032, task-041, task-044, task-056 | task-032/task-041, task-032/task-044, task-041/task-044 | task-056 after task-032; task-056 after task-041; task-056 after task-044 | task-032 -> task-041 -> task-044 -> task-056 |
| 123 | `tests/canonical/test-review-path-audit.sh` | task-040, task-044 | task-040/task-044 | - | task-040 -> task-044 |
| 124 | `tests/canonical/test-scoped-review-cycles.sh` | task-039, task-040 | - | task-040 after task-039 | task-039 -> task-040 |
| 125 | `tests/canonical/test-shared-install.sh` | task-032, task-056 | - | task-056 after task-032 | task-032 -> task-056 |
| 126 | `tests/canonical/test-shared-prune.sh` | task-039, task-042 | task-039/task-042 | - | task-039 -> task-042 |
| 127 | `tests/canonical/test-shared-remove.sh` | task-032, task-039 | task-032/task-039 | - | task-032 -> task-039 |
| 128 | `tests/canonical/test-shortcut-engine-contract.sh` | task-025, task-037, task-056 | - | task-037 after task-025; task-056 after task-025; task-056 after task-037 | task-025 -> task-037 -> task-056 |
| 129 | `tests/canonical/test-skill-guide.sh` | task-032, task-034, task-035, task-036, task-038, task-039, task-040, task-041, task-042, task-043, task-044 | task-032/task-034, task-032/task-035, task-032/task-036, task-032/task-038, task-032/task-039, task-032/task-040, task-032/task-041, task-032/task-042, task-032/task-043, task-032/task-044, task-034/task-035, task-034/task-036, task-034/task-038, task-034/task-039, task-034/task-040, task-034/task-041, task-034/task-042, task-034/task-043, task-034/task-044, task-035/task-036, task-035/task-038, task-035/task-039, task-035/task-040, task-035/task-041, task-035/task-042, task-035/task-043, task-035/task-044, task-036/task-038, task-036/task-039, task-036/task-040, task-036/task-041, task-036/task-042, task-036/task-043, task-036/task-044, task-038/task-039, task-038/task-040, task-038/task-041, task-038/task-042, task-038/task-043, task-038/task-044, task-039/task-041, task-039/task-042, task-039/task-043, task-039/task-044, task-040/task-041, task-040/task-042, task-040/task-043, task-040/task-044, task-041/task-042, task-041/task-043, task-041/task-044, task-042/task-043, task-042/task-044, task-043/task-044 | task-040 after task-039 | task-032 -> task-034 -> task-035 -> task-036 -> task-038 -> task-039 -> task-040 -> task-041 -> task-042 -> task-043 -> task-044 |
| 130 | `tests/canonical/test-spine-depth-coverage.sh` | task-041, task-049 | - | task-049 after task-041 | task-041 -> task-049 |
| 131 | `tests/canonical/test-state-review-surface.sh` | task-021, task-025, task-037, task-039, task-040, task-041 | task-037/task-039, task-037/task-040, task-037/task-041, task-039/task-041, task-040/task-041 | task-025 after task-021; task-037 after task-021; task-039 after task-021; task-040 after task-021; task-041 after task-021; task-037 after task-025; task-039 after task-025; task-040 after task-025; task-041 after task-025; task-040 after task-039 | task-021 -> task-025 -> task-037 -> task-039 -> task-040 -> task-041 |
| 132 | `tests/canonical/test-summarize-preflight.sh` | task-041, task-049 | - | task-049 after task-041 | task-041 -> task-049 |
| 133 | `tests/canonical/test-task-state-transitions.sh` | task-021, task-025, task-031, task-040 | - | task-025 after task-021; task-031 after task-021; task-040 after task-021; task-025 after task-031; task-040 after task-025; task-040 after task-031 | task-021 -> task-031 -> task-025 -> task-040 |
| 134 | `tests/canonical/test-test-experiment-family-scaffold.sh` | task-037, task-040, task-044 | task-037/task-040, task-037/task-044, task-040/task-044 | - | task-037 -> task-040 -> task-044 |
| 135 | `tests/canonical/test-ticket-retirement-structural.sh` | task-021, task-037, task-038, task-039, task-040, task-041, task-042, task-043, task-044 | task-037/task-038, task-037/task-039, task-037/task-040, task-037/task-041, task-037/task-042, task-037/task-043, task-037/task-044, task-038/task-039, task-038/task-040, task-038/task-041, task-038/task-042, task-038/task-043, task-038/task-044, task-039/task-041, task-039/task-042, task-039/task-043, task-039/task-044, task-040/task-041, task-040/task-042, task-040/task-043, task-040/task-044, task-041/task-042, task-041/task-043, task-041/task-044, task-042/task-043, task-042/task-044, task-043/task-044 | task-037 after task-021; task-038 after task-021; task-039 after task-021; task-040 after task-021; task-041 after task-021; task-042 after task-021; task-043 after task-021; task-044 after task-021; task-040 after task-039 | task-021 -> task-037 -> task-038 -> task-039 -> task-040 -> task-041 -> task-042 -> task-043 -> task-044 |
| 136 | `tests/canonical/test-update-kb-scope-fidelity.sh` | task-042, task-044 | task-042/task-044 | - | task-042 -> task-044 |
| 137 | `tests/canonical/test-validator-behavior.sh` | task-049, task-057 | - | task-057 after task-049 | task-049 -> task-057 |
| 138 | `tests/canonical/test-version-sync.sh` | task-025, task-056 | - | task-056 after task-025 | task-025 -> task-056 |
| 139 | `tests/canonical/test-work-initiation-gate.sh` | task-030, task-034, task-037, task-038, task-040, task-044 | task-034/task-037, task-034/task-038, task-034/task-040, task-034/task-044, task-037/task-038, task-037/task-040, task-037/task-044, task-038/task-040, task-038/task-044, task-040/task-044 | task-034 after task-030; task-037 after task-030; task-038 after task-030; task-040 after task-030; task-044 after task-030 | task-030 -> task-034 -> task-037 -> task-038 -> task-040 -> task-044 |
| 140 | `tests/canonical/test-work-state-template.sh` | task-021, task-031, task-038, task-039 | task-038/task-039 | task-031 after task-021; task-038 after task-021; task-039 after task-021; task-038 after task-031; task-039 after task-031 | task-021 -> task-031 -> task-038 -> task-039 |
| 141 | `tests/canonical/test-write-connector.sh` | task-043, task-057 | - | task-057 after task-043 | task-043 -> task-057 |
| 142 | `tests/canonical/test-writeback-state.sh` | task-021, task-025, task-039, task-040, task-044, task-056 | task-039/task-044, task-040/task-044 | task-025 after task-021; task-039 after task-021; task-040 after task-021; task-044 after task-021; task-056 after task-021; task-039 after task-025; task-040 after task-025; task-044 after task-025; task-056 after task-025; task-040 after task-039; task-056 after task-039; task-056 after task-040; task-056 after task-044 | task-021 -> task-025 -> task-039 -> task-040 -> task-044 -> task-056 |
| 143 | `tests/conversation/fixtures/done-work/.aid/works/work-001-csv-export/STATE.yml` | task-038, task-040 | task-038/task-040 | - | task-038 -> task-040 |
| 144 | `tests/conversation/fixtures/ticket-mid-work/.aid/works/work-001-retry-policy/STATE.yml` | task-038, task-039 | task-038/task-039 | - | task-038 -> task-039 |
| 145 | `tests/conversation/samples/feature-001/001-15-no-kb-offers-preparation.md` | task-039, task-041 | task-039/task-041 | - | task-039 -> task-041 |
| 146 | `tests/cost-meter.py` | task-040, task-044, task-057 | task-040/task-044 | task-057 after task-040; task-057 after task-044 | task-040 -> task-044 -> task-057 |
| 147 | `tests/coverage-accepted-removals.tsv` | task-021, task-033, task-043, task-056 | task-033/task-043 | task-033 after task-021; task-043 after task-021; task-056 after task-021; task-056 after task-033; task-056 after task-043 | task-021 -> task-033 -> task-043 -> task-056 |
| 148 | `tests/coverage-rehome-allowlist.tsv` | task-021, task-032, task-039, task-040, task-043 | task-032/task-039, task-032/task-040, task-032/task-043, task-039/task-043, task-040/task-043 | task-032 after task-021; task-039 after task-021; task-040 after task-021; task-043 after task-021; task-040 after task-039 | task-021 -> task-032 -> task-039 -> task-040 -> task-043 |
| 149 | `tests/ui/README.md` | task-031, task-033 | - | task-033 after task-031 | task-031 -> task-033 |
| 150 | `tests/windows/Test-AidInstaller.ps1` | task-032, task-040, task-042, task-056 | task-032/task-040, task-032/task-042, task-040/task-042 | task-056 after task-032; task-056 after task-040; task-056 after task-042 | task-032 -> task-040 -> task-042 -> task-056 |

152 suites have hits owned by two or more tasks. Every one runs after all its tasks, in the order shown.

## Delta

Each item is a difference between a search result and a statement of the spec (REQUIREMENTS.md § 11 Feature 002 and PLAN.md), or between the spec and the task files, with its owner.

| # | Statement or check | Result today | Difference and owner |
|---|---|---|---|
| D1 | P1: "Run on today's tree, these forms reach 55 lines" (SS-11) | 55 lines, with the spec's forms (see the command in P1) | None. The count matches. The owners of the 55 are in the P1 table. |
| D2 | P1: the deploy sentence "it stays at `Execute`" is listed in the phase-sites table but is "listed without being reachable" | `canonical/skills/aid-deploy/references/state-idle.md:26` is split over two lines; the grep cannot reach it | Not one of the 55. Its owner is task-043 (`aid-deploy` group), which changes it to `Building`. |
| D3 | Phase sites: "the nine `--field Phase --value` writes" (Work state layout, phase-sites table) | Ten: the nine, plus `canonical/skills/aid-orchestrate/references/size-and-route.md:50` (`--field Phase --value Execute`) | The tenth is not in the spec's table. Owner: task-032 (`aid-orchestrate`). Its `canonical/skills/aid-orchestrate/SKILL.md:47` ("set `phase` to `Execute`") is also not in the table; owner task-032. |
| D4 | P2: "every file (b) matches is in Files and layout" (SS-14 (b)) | All 55 lines are in converted allocation points or exempt per-skill files | None. Exempt lines stay; the owner of each is the task that sweeps its file. |
| D5 | P3: "(d) matches exactly the continuation lines listed in Files and layout" (SS-14 (d)) | 14 lines in 10 files, one per continuation line the spec lists (`shortcut-engine.md` § Design Notes, § State: INTAKE Step 3; `aid-review` § Step 5; `aid-describe` § One or more works exist; the seven starters; `aid-design`) | None. |
| D6 | P4: "Today 42 skill files do it" (SS-12, Work state layout) | 43 lines in 43 files: the 42, plus `aid-deploy/references/state-done.md`, whose prose quotes `lifecycle: Completed` and which task-043 rewords | None once the deploy prose is counted; the spec says it is reworded for that reason. |
| D7 | P5 and SS-02: `canonical/aid/templates/state-machine-chaining.md` carries `**Advance:**` lines (12 in P5) | The file is deleted by delivery-003 (task-074), not by delivery-002 | Its hits are owned by task-050 (the exempt-list row for SS-03, per task-050's Scope). The owner classes name no delivery-003 task; the row points at task-074 for the removal. Please confirm this reading. |
| D8 | SS-02: "every `SKILL.md` with a Dispatch table or a `## State:` section" | 58 files; `aid-ask` and `aid-read-ticket` have a `## Dispatch table` heading and a table | None. Note: `aid-orchestrate` has neither, but task-032's Scope says its `SKILL.md` cites `skill-steps.md`. That is a task-level addition, not an SS-02 requirement; owner task-032. |
| D9 | Owner classes | The spec's "left as they are" items (`site/src/data/skill-flows/`, `tests/canonical/test-diagram-content.sh`, `canonical/aid/scripts/summarize/`, documentation prose in `docs/` and `site/src/content/docs/`) have no class of their own; G11 synthetic fixture names (`aid-fixture`, `aid-parent`, `door-skill`) name no real file; some tests name unchanged skills | Those items are assigned to `history, left as is` (the class for a hit that stays). The two baseline files, `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`, are not history: every hit in them is owned by `baseline, re-recorded at the gate` (Q134 D11), and no task edits them. Please confirm; the alternative is a fifth class. `site/src/data/skill-flows/` is regenerated by the G1 generator run of each task that changes a skill (task-021 first). |
| D10 | Tests rule (Feature 002 § 2): "`test-describe-full-only.sh`" is named among the suites that change | it has 12 edit-list matches (owners: task-021, task-038, task-044) | No task Scope names this suite. Its owner is the task that changes the file it reads (per P8). Please confirm that the matches are the only edit it needs. |
| D11 | P7: "Run against today's tree with these globs, only the two exemptions fire" (NM) | NM-03: 1 hit (aid-housekeep, exempt). NM-04: 3 hits (aid-execute, exempt). NM-01 and NM-02: none | None. |
| D12 | P8: suites named by a task Scope (for example `test-pipeline-status-walkthrough.sh` A1 and B1, `test-work-initiation-gate.sh`, `test-skill-guide.sh`) | The name-based match of P8 finds the files each task names, plus other suites (for example `test_reader.py`, `test-release.sh`) | Each extra suite gets the owner of the file it reads. None is left without an owner. |
| D13 | Dashboard files the spec lists for the readers (Files and layout: `reader.py`, `dashboard/server/server.py` `_ser_work`, `server.mjs`) | Not in the task-031 bullet of the phase sites, but in its "Both readers pass `intent.phases`" paragraph | Owner task-031, as that paragraph of its Scope says. No difference in owner. |
| D14 | task-025 Scope: "every write is atomic: a temporary copy is renamed into place under the lock" | Today's field writes already do this (P10); the limit is the temp directory | Owner task-025 keeps the discipline for the new modes (its Scope) and states the same-filesystem limit in its findings. No difference in owner. |

## Test step

No suite and no check was run for this task: every change lies under `.aid/works/` (the work-folder-only rule of task-020 and the test step of PLAN.md). `bash -n`, `py_compile` and `node --check` have nothing to check (no `.sh`, `.py` or `.mjs` changed). `run_generator.py` was not run; no branch, worktree or commit was made.

