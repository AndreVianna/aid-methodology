# Delivery-002 site search and reconciled edit list

This file is the output of task-020 (RESEARCH) of delivery-002. It re-runs the searches of PLAN.md's delivery-002 stanza, wave 1, and of REQUIREMENTS.md § 11 Feature 002 `##### 8. Testing`, gives every hit exactly one owner, and reconciles the result with the task files task-021 to task-057. It changes no other file.

## Base commit and conventions

- **Base commit:** `06d32a1ba63e1c8810e16978165e5581034f4c87` (the `task-020: In Progress` commit on branch `work-003`, HEAD at the time of the run). `git status --short` was empty at the base, so every command below, run from the repository root, reads the same bytes as the commit.
- **Owner classes** (the four allowed by task-020): a task of delivery-002 (task-021 to task-057), `installed copy (resync)`, `history, left as is`, `baseline, re-recorded at the gate`. Where a hit lies in a file that no task edits and that the spec leaves unchanged, the owner is `history, left as is`; see the Delta, item D9.
- **Owner of a skill file** is the task whose Scope or group names that skill (the skill owner table below); a skill with no hit and no sweep convention is `no change needed here`.
- **Row counts.** P1, P2, P3, P4 and P7 print one row per hit line. P5 prints one row per file (its line numbers are listed in the row), because 406 lines would repeat the same owner. P8 prints one row per (edit-list token or skill, suite, owner), with the number of matching lines. G11 prints one row per (site test, target, owner).
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
| 3 | `canonical/aid/templates/state-machine-chaining.md` | 17, 24, 32, 41, 46, 51, 61, 69, 71, 85, 93, 105 | 4 | 3 | Stop x2 | task-050 (exempt row for SS-03; the file is deleted by task-074, delivery-003; see Delta D7) |
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

Command (run from the repo root). Each token is a basename of an edit-list file of delivery-002 (the files the tasks of this delivery change, from their Scopes and the spec's Files and layout), and each skill name is an edit-list skill (every skill in the groups of the owner table, including the no-change ones). The match is by basename or name, in the four suite trees, so it over-includes (for example `rules.md` also matches `shared-rules.md`); each row still names the owner that must re-point or update that suite:

```bash
TESTDIRS="tests site/scripts/__tests__ site/src/lib/__tests__ dashboard/reader/tests dashboard/server/tests"
for tok in work-state-template.yml project-state-template.yml question-protocol.md skill-steps.md advance.mjs writeback-state.sh work-initiation-gate.md start-or-resume.md rules.md home.html models.py parsers.py state_schema.py reader.py server.py reader.mjs server.mjs design-lifecycle.md shortcut-engine.md decisions.md artifact-schemas.md domain-glossary.md backlog.md pipeline-contracts.md architecture.md test-landscape.md INDEX.md ticket-resolution.md release.yml installer-tests.yml release.sh; do git grep -n -F -e "$tok" -- $TESTDIRS; done
for n in <every skill named in the owner table>; do git grep -n -F -e "skills/$n/" -e "'$n'" -e "\"$n\"" -e "\`$n\`" -- $TESTDIRS; done
```

Hits: 708 (suite, owner) rows covering 7051 matching lines in 356 suite files. Rows with owner `history, left as is` are references to edit-list skills that no task edits (their text stays); the rest are owned by the task that changes the asserted file, or, for a suite a task names, by that task.

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
| 10 | `tests/canonical/test-work-state-template.sh` | task-021 | `work-state-template.yml` 12, `state_schema.py` 1, `aid-define` 2, `aid-describe` 7, `aid-specify` 1 |
| 11 | `tests/canonical/test-writeback-state.sh` | task-025 | `work-state-template.yml` 3, `writeback-state.sh` 3, `release.yml` 1, `aid-execute` 5, `aid-review` 2, `aid-specify` 2, `aid-refactor` 4 |
| 12 | `tests/coverage-accepted-removals.tsv` | task-021 | `work-state-template.yml` 1 |
| 13 | `tests/coverage-baseline.tsv` | task-021 | `work-state-template.yml` 1 |
| 14 | `tests/coverage-rehome-allowlist.tsv` | task-021 | `work-state-template.yml` 1 |
| 15 | `site/scripts/__tests__/flow-advance.test.mjs` | task-024 | `advance.mjs` 4, `aid-create-ticket` 4, `aid-define` 4, `aid-deploy` 1, `aid-design` 1, `aid-discover` 2, `aid-housekeep` 1, `aid-prototype` 1, `aid-report` 1, `aid-research` 1, `aid-specify` 4, `aid-summarize` 1, `aid-test` 7, `aid-update-kb` 2, `aid-create` 4, `aid-fix` 4, `aid-update` 2 |
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
| 42 | `tests/canonical/test-disjoint-merge.sh` | task-025 | `writeback-state.sh` 9, `aid-execute` 3, `aid-test` 1 |
| 43 | `tests/canonical/test-lite-work-end-to-end.sh` | task-025 | `writeback-state.sh` 3, `reader.py` 6, `reader.mjs` 5 |
| 44 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-025 | `writeback-state.sh` 17 |
| 45 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-039 | `writeback-state.sh` 1, `aid-define` 6, `aid-specify` 20 |
| 46 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-040 | `writeback-state.sh` 1, `aid-detail` 5, `aid-execute` 14, `aid-plan` 5 |
| 47 | `tests/canonical/test-shortcut-engine-contract.sh` | task-025 | `writeback-state.sh` 1 |
| 48 | `tests/canonical/test-state-review-surface.sh` | task-025 | `writeback-state.sh` 1 |
| 49 | `tests/canonical/test-task-state-transitions.sh` | task-025 | `writeback-state.sh` 6 |
| 50 | `tests/canonical/test-version-sync.sh` | task-025 | `writeback-state.sh` 1 |
| 51 | `tests/conversation/samples/feature-001/001-10-release-own-work.md` | task-025 | `writeback-state.sh` 1 |
| 52 | `tests/coverage-baseline.tsv` | task-025 | `writeback-state.sh` 380 |
| 53 | `site/scripts/__tests__/flow-engine-core.test.mjs` | task-030 | `work-initiation-gate.md` 5 |
| 54 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-030 | `work-initiation-gate.md` 1 |
| 55 | `tests/canonical/test-work-initiation-gate.sh` | task-030 | `work-initiation-gate.md` 5, `shortcut-engine.md` 3, `aid-create-document` 3, `aid-describe` 4, `aid-design` 3, `aid-execute` 3, `aid-plan` 3, `aid-prototype` 9, `aid-report` 3, `aid-research` 10, `aid-review` 11, `aid-test` 3, `aid-update-document` 5, `aid-create` 3, `aid-update` 5 |
| 56 | `tests/cost-baseline.tsv` | task-030 | `work-initiation-gate.md` 1 |
| 57 | `tests/coverage-baseline.tsv` | task-030 | `work-initiation-gate.md` 1 |
| 58 | `tests/canonical/test-aid-cli-parity.sh` | task-056 | `rules.md` 7, `models.py` 3, `parsers.py` 3, `reader.py` 3, `server.py` 3, `reader.mjs` 3, `server.mjs` 3, `installer-tests.yml` 1, `release.sh` 1, `aid-ask` 7, `aid-config` 2, `aid-define` 1, `aid-migrate` 2, `aid-update` 3 |
| 59 | `tests/canonical/test-aid-migrate.sh` | task-032 | `rules.md` 29 |
| 60 | `tests/canonical/test-aid-status-drift.sh` | task-032 | `rules.md` 1 |
| 61 | `tests/canonical/test-change-refactor-family-scaffold.sh` | task-032 | `rules.md` 1 |
| 62 | `tests/canonical/test-connector-skills-structural.sh` | task-032 | `rules.md` 9 |
| 63 | `tests/canonical/test-create-family-scaffold.sh` | task-032 | `rules.md` 1 |
| 64 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-032 | `rules.md` 1, `aid-orchestrate` 2 |
| 65 | `tests/canonical/test-document-family-scaffold.sh` | task-032 | `rules.md` 2 |
| 66 | `tests/canonical/test-dogfood-byte-identity.sh` | task-032 | `rules.md` 12 |
| 67 | `tests/canonical/test-install-core-primitives.sh` | task-032 | `rules.md` 24 |
| 68 | `tests/canonical/test-install-provisioning.sh` | task-032 | `rules.md` 2 |
| 69 | `tests/canonical/test-layout-format-guard.sh` | task-032 | `rules.md` 1 |
| 70 | `tests/canonical/test-prototype-family-scaffold.sh` | task-032 | `rules.md` 1 |
| 71 | `tests/canonical/test-release-install-e2e.sh` | task-032 | `rules.md` 5 |
| 72 | `tests/canonical/test-release.sh` | task-056 | `rules.md` 2, `release.sh` 11, `aid-discover` 5, `aid-review` 1 |
| 73 | `tests/canonical/test-shared-install.sh` | task-032 | `rules.md` 12 |
| 74 | `tests/canonical/test-shared-layout-sources.sh` | task-032 | `rules.md` 1 |
| 75 | `tests/canonical/test-shared-remove.sh` | task-052 | `rules.md` 13, `aid-define` 7 |
| 76 | `tests/canonical/test-skill-guide.sh` | task-032 | `rules.md` 10, `aid-ask` 1, `aid-config` 1, `aid-create-architecture` 1, `aid-create-backlog` 1, `aid-create-cicd` 1, `aid-create-document` 1, `aid-create-mvp` 1, `aid-create-roadmap` 1, `aid-create-stack` 1, `aid-create-testing-strategy` 1, `aid-create-ticket` 1, `aid-define` 1, `aid-describe` 1, `aid-design` 5, `aid-design-api` 1, `aid-design-architecture` 1, `aid-design-backlog` 1, `aid-design-cicd` 1, `aid-design-cli` 1, `aid-design-config` 1, `aid-design-dashboard` 1, `aid-design-data-model` 1, `aid-design-data-pipeline` 1, `aid-design-document` 1, `aid-design-infra` 1, `aid-design-integration` 1, `aid-design-job` 1, `aid-design-messaging` 1, `aid-design-mvp` 1, `aid-design-roadmap` 1, `aid-design-stack` 1, `aid-design-test` 1, `aid-design-testing-strategy` 1, `aid-design-theme` 1, `aid-design-ui` 1, `aid-detail` 1, `aid-discover` 1, `aid-housekeep` 1, `aid-prototype` 1, `aid-summarize` 1, `aid-test` 2, `aid-update-architecture` 1, `aid-update-backlog` 1, `aid-update-cicd` 1, `aid-update-document` 1, `aid-update-kb` 1, `aid-update-mvp` 1, `aid-update-roadmap` 1, `aid-update-stack` 1, `aid-update-testing-strategy` 1, `aid-update-ticket` 1, `aid-create` 6, `aid-create-api` 1, `aid-create-cli` 1, `aid-create-config` 1, `aid-create-dashboard` 1, `aid-create-data-model` 1, `aid-create-data-pipeline` 1, `aid-create-diagram` 1, `aid-create-infra` 1, `aid-create-integration` 1, `aid-create-job` 1, `aid-create-messaging` 1, `aid-create-test` 1, `aid-create-theme` 1, `aid-create-ui` 1, `aid-deprecate` 1, `aid-document` 2, `aid-document-architecture` 1, `aid-document-changelog` 1, `aid-document-decision` 1, `aid-document-guideline` 1, `aid-document-runbook` 1, `aid-document-standard` 1, `aid-document-tutorial` 1, `aid-experiment` 1, `aid-migrate` 1, `aid-prototype-ui` 1, `aid-remove` 1, `aid-test-data-quality` 1, `aid-test-performance` 1, `aid-test-security` 1, `aid-update` 5, `aid-update-api` 1, `aid-update-cli` 1, `aid-update-config` 1, `aid-update-dashboard` 1, `aid-update-data-model` 1, `aid-update-data-pipeline` 1, `aid-update-infra` 1, `aid-update-integration` 1, `aid-update-job` 1, `aid-update-messaging` 1, `aid-update-test` 1, `aid-update-theme` 1, `aid-update-ui` 1 |
| 77 | `tests/coverage-baseline.tsv` | task-032 | `rules.md` 1 |
| 78 | `tests/coverage-rehome-allowlist.tsv` | task-032 | `rules.md` 6 |
| 79 | `tests/windows/Test-AidInstaller.ps1` | task-032 | `rules.md` 19 |
| 80 | `tests/windows/Test-InstallProvisioning.ps1` | task-032 | `rules.md` 2 |
| 81 | `dashboard/reader/tests/test_flattened_layout_parity.py` | task-033 | `home.html` 1 |
| 82 | `dashboard/reader/tests/test_work016_container_discovery.py` | task-033 | `home.html` 9 |
| 83 | `dashboard/server/tests/test_cli_home_html.py` | task-033 | `home.html` 5 |
| 84 | `dashboard/server/tests/test_home_html_project_header.py` | task-033 | `home.html` 4 |
| 85 | `dashboard/server/tests/test_index_html.py` | task-033 | `home.html` 27, `server.py` 2, `aid-deploy` 1, `aid-describe` 6, `aid-discover` 3, `aid-housekeep` 7 |
| 86 | `dashboard/server/tests/test_server_node.mjs` | task-033 | `home.html` 19 |
| 87 | `dashboard/server/tests/test_server_py.py` | task-033 | `home.html` 8 |
| 88 | `dashboard/server/tests/test_task009_rename_ui.py` | task-033 | `home.html` 4 |
| 89 | `dashboard/server/tests/test_task010_task_notes.py` | task-033 | `home.html` 1 |
| 90 | `dashboard/server/tests/test_task010_task_notes_ui.py` | task-033 | `home.html` 4 |
| 91 | `dashboard/server/tests/test_task012_consuming_round_trips.py` | task-033 | `home.html` 1 |
| 92 | `dashboard/server/tests/test_task022_connectors_external_sources_ui.py` | task-033 | `home.html` 6 |
| 93 | `dashboard/server/tests/test_task026_delete_pipeline_ui.py` | task-033 | `home.html` 6 |
| 94 | `dashboard/server/tests/test_task030_finish_stop_resume_ui.py` | task-033 | `home.html` 4 |
| 95 | `dashboard/server/tests/test_task033_execution_control_round_trips.py` | task-033 | `home.html` 5 |
| 96 | `dashboard/server/tests/test_tools_management_ui.py` | task-033 | `home.html` 7 |
| 97 | `tests/canonical/test-aid-migrate-trigger.sh` | task-033 | `home.html` 46 |
| 98 | `tests/canonical/test-aid-migrate.sh` | task-033 | `home.html` 4 |
| 99 | `tests/canonical/test-aid-migration-stamp.sh` | task-033 | `home.html` 1 |
| 100 | `tests/canonical/test-chat-node-manifest.sh` | task-033 | `home.html` 1 |
| 101 | `tests/canonical/test-dashboard-manifest.sh` | task-033 | `home.html` 1 |
| 102 | `tests/canonical/test-dashboard-parity-h.sh` | task-033 | `home.html` 4 |
| 103 | `tests/canonical/test-grade-summary.sh` | task-033 | `home.html` 4 |
| 104 | `tests/canonical/test-guardrails-d012.sh` | task-033 | `home.html` 6 |
| 105 | `tests/canonical/test-install-parity.sh` | task-033 | `home.html` 5 |
| 106 | `tests/canonical/test-release-migrate-smoke.sh` | task-033 | `home.html` 1 |
| 107 | `tests/coverage-accepted-removals.tsv` | task-033 | `home.html` 4 |
| 108 | `tests/coverage-baseline.tsv` | task-033 | `home.html` 7 |
| 109 | `tests/lib/sandbox.sh` | task-033 | `home.html` 1 |
| 110 | `tests/ui/README.md` | task-033 | `home.html` 1 |
| 111 | `tests/ui/edit-surfaces.spec.mjs` | task-033 | `home.html` 1 |
| 112 | `dashboard/reader/tests/test_fixtures.py` | task-031 | `models.py` 1, `parsers.py` 3, `reader.py` 1 |
| 113 | `dashboard/reader/tests/test_reader.py` | task-031 | `models.py` 1, `parsers.py` 2, `reader.py` 6 |
| 114 | `dashboard/reader/tests/test_work016_container_discovery.py` | task-031 | `models.py` 6, `state_schema.py` 1, `reader.py` 1, `reader.mjs` 5 |
| 115 | `tests/canonical/test-aid-dashboard-cli.sh` | task-031 | `models.py` 1, `parsers.py` 1, `reader.py` 1, `server.py` 7, `reader.mjs` 1, `server.mjs` 4 |
| 116 | `dashboard/reader/tests/test_derivation.py` | task-031 | `parsers.py` 1, `state_schema.py` 1, `reader.py` 2 |
| 117 | `dashboard/reader/tests/test_task014_fixtures.py` | task-031 | `parsers.py` 1, `server.py` 1, `reader.mjs` 8 |
| 118 | `dashboard/reader/tests/test_task064_kb_status.py` | task-031 | `parsers.py` 1 |
| 119 | `dashboard/reader/tests/test_task069_detail_parser.py` | task-031 | `parsers.py` 1, `reader.py` 7 |
| 120 | `dashboard/reader/tests/test_work003_state_schema.py` | task-031 | `parsers.py` 1, `state_schema.py` 5, `reader.py` 2, `server.py` 2, `reader.mjs` 7 |
| 121 | `dashboard/server/tests/test_task012_consuming_round_trips.py` | task-031 | `parsers.py` 2, `server.py` 3, `reader.mjs` 7, `server.mjs` 9 |
| 122 | `dashboard/server/tests/test_task022_connectors_external_sources_ui.py` | task-031 | `parsers.py` 1, `server.py` 1, `reader.mjs` 1 |
| 123 | `dashboard/server/tests/test_task027_pipeline_delete_round_trips.py` | task-031 | `parsers.py` 1, `server.py` 4, `server.mjs` 5 |
| 124 | `tests/canonical/test-derive-waves.sh` | task-031 | `parsers.py` 1 |
| 125 | `dashboard/reader/tests/test_shortcut_kind_map_cross_runtime_parity.py` | task-031 | `state_schema.py` 9, `reader.mjs` 13, `server.mjs` 1 |
| 126 | `dashboard/reader/tests/test_state_yaml_conformance.py` | task-031 | `state_schema.py` 1, `reader.mjs` 1 |
| 127 | `dashboard/reader/tests/test_declared_path_three_way_parity.py` | task-031 | `reader.py` 3, `reader.mjs` 3 |
| 128 | `dashboard/reader/tests/test_derived_lanes_cross_runtime_parity.py` | task-031 | `reader.py` 2, `reader.mjs` 3 |
| 129 | `dashboard/reader/tests/test_feature009.py` | task-031 | `reader.py` 6, `reader.mjs` 3 |
| 130 | `dashboard/reader/tests/test_flattened_layout_parity.py` | task-031 | `reader.py` 4, `reader.mjs` 4 |
| 131 | `dashboard/reader/tests/test_plan_delivery_title_cross_runtime_parity.py` | task-031 | `reader.py` 2, `reader.mjs` 4 |
| 132 | `dashboard/reader/tests/test_task011_golden_master.py` | task-031 | `reader.py` 1, `server.py` 4, `reader.mjs` 7 |
| 133 | `dashboard/reader/tests/test_task066_kb_parity.py` | task-031 | `reader.py` 1 |
| 134 | `dashboard/reader/tests/test_work001_delivery_layouts.py` | task-031 | `reader.py` 7, `server.py` 2, `reader.mjs` 7 |
| 135 | `dashboard/server/tests/test_reader_task069.mjs` | task-031 | `reader.py` 2, `reader.mjs` 3 |
| 136 | `dashboard/server/tests/test_task033_execution_control_round_trips.py` | task-031 | `reader.py` 1, `server.py` 8, `reader.mjs` 1, `server.mjs` 6 |
| 137 | `tests/canonical/test-artifact-discipline.sh` | task-031 | `reader.py` 1, `reader.mjs` 1 |
| 138 | `tests/canonical/test-dashboard-manifest.sh` | task-031 | `reader.py` 2 |
| 139 | `tests/canonical/test-dashboard-parity-h.sh` | task-031 | `reader.py` 3, `server.py` 12, `reader.mjs` 3, `server.mjs` 10 |
| 140 | `dashboard/reader/tests/test_task008_display_rename.py` | task-031 | `server.py` 1, `reader.mjs` 3 |
| 141 | `dashboard/reader/tests/test_task021_external_sources.py` | task-031 | `server.py` 2, `reader.mjs` 3 |
| 142 | `dashboard/reader/tests/test_task029_stop_requested.py` | task-031 | `server.py` 1, `reader.mjs` 3 |
| 143 | `dashboard/server/tests/fixtures/README.md` | task-031 | `server.py` 1 |
| 144 | `dashboard/server/tests/test_home_html_project_header.py` | task-031 | `server.py` 2, `server.mjs` 2 |
| 145 | `dashboard/server/tests/test_server_py.py` | task-031 | `server.py` 6 |
| 146 | `dashboard/server/tests/test_task011_dispatch_round_trip.py` | task-031 | `server.py` 8 |
| 147 | `dashboard/server/tests/test_task013_project_registry_ops.mjs` | task-031 | `server.py` 1, `server.mjs` 10 |
| 148 | `dashboard/server/tests/test_task017_registry_tooling_round_trips.mjs` | task-031 | `server.py` 1, `server.mjs` 5 |
| 149 | `dashboard/server/tests/test_task017_registry_tooling_round_trips.py` | task-031 | `server.py` 2, `server.mjs` 11 |
| 150 | `dashboard/server/tests/test_task023_list_management_round_trips.mjs` | task-031 | `server.py` 1, `server.mjs` 4 |
| 151 | `dashboard/server/tests/test_task023_list_management_round_trips.py` | task-031 | `server.py` 4, `reader.mjs` 2, `server.mjs` 5 |
| 152 | `dashboard/server/tests/test_task030_finish_stop_resume_ui.py` | task-031 | `server.py` 2, `server.mjs` 2 |
| 153 | `dashboard/server/tests/test_tools_management_ui.py` | task-031 | `server.py` 1, `server.mjs` 1 |
| 154 | `tests/canonical/test-aid-remote.sh` | task-031 | `server.py` 2, `reader.mjs` 1, `server.mjs` 2 |
| 155 | `tests/canonical/test-ascii-only.sh` | task-056 | `server.py` 1, `reader.mjs` 1, `server.mjs` 1, `installer-tests.yml` 1 |
| 156 | `tests/canonical/test-dashboard-parity.sh` | task-031 | `server.py` 2, `server.mjs` 2 |
| 157 | `tests/coverage-baseline.tsv` | task-031 | `server.py` 6, `server.mjs` 4 |
| 158 | `tests/ui/README.md` | task-031 | `server.py` 1, `server.mjs` 1 |
| 159 | `tests/ui/serve.mjs` | task-031 | `server.py` 1, `server.mjs` 1 |
| 160 | `dashboard/reader/tests/test_resolve_work_dir_cross_runtime_parity.py` | task-031 | `reader.mjs` 3 |
| 161 | `dashboard/reader/tests/test_security_hardening.py` | task-031 | `reader.mjs` 4 |
| 162 | `dashboard/reader/tests/test_state_yaml_conformance_node.py` | task-031 | `reader.mjs` 6 |
| 163 | `dashboard/reader/tests/test_task019_connectors.py` | task-031 | `reader.mjs` 3 |
| 164 | `dashboard/reader/tests/test_task023_list_management_parity.py` | task-031 | `reader.mjs` 5 |
| 165 | `dashboard/reader/tests/test_task044_freshness_parity.py` | task-031 | `reader.mjs` 2 |
| 166 | `dashboard/server/tests/test_server_node.mjs` | task-031 | `reader.mjs` 12, `server.mjs` 11 |
| 167 | `dashboard/server/tests/test_task002_resolve_work_dir.mjs` | task-031 | `reader.mjs` 2 |
| 168 | `dashboard/server/tests/test_task010_task_notes_cross_runtime_parity.py` | task-031 | `reader.mjs` 2, `server.mjs` 7 |
| 169 | `dashboard/server/tests/test_task019_connector_ops.mjs` | task-031 | `reader.mjs` 3, `server.mjs` 6 |
| 170 | `dashboard/server/tests/test_task021_external_source_ops.mjs` | task-031 | `reader.mjs` 4, `server.mjs` 6 |
| 171 | `dashboard/server/tests/test_task025_pipeline_delete_ops.mjs` | task-031 | `reader.mjs` 3, `server.mjs` 6 |
| 172 | `dashboard/server/tests/test_task029_task_stop_resume_ops.mjs` | task-031 | `reader.mjs` 3, `server.mjs` 6 |
| 173 | `dashboard/server/tests/test_write_enabled_cross_runtime_parity.py` | task-031 | `reader.mjs` 5, `server.mjs` 13 |
| 174 | `tests/canonical/test-producer-completeness.sh` | task-025 | `reader.mjs` 6, `aid-execute` 1 |
| 175 | `tests/canonical/test-task-state-transitions.sh` | task-031 | `reader.mjs` 2 |
| 176 | `dashboard/server/tests/test_ki009_windows_dispatch.py` | task-031 | `server.mjs` 5 |
| 177 | `dashboard/server/tests/test_task010_task_notes.py` | task-031 | `server.mjs` 1 |
| 178 | `dashboard/server/tests/test_task011_dispatch_round_trip.mjs` | task-031 | `server.mjs` 13 |
| 179 | `dashboard/server/tests/test_task015_tools_update_ops.mjs` | task-031 | `server.mjs` 14 |
| 180 | `tests/canonical/test-kb-citation-lint.sh` | task-031 | `server.mjs` 3 |
| 181 | `tests/cost-baseline.tsv` | task-034 | `design-lifecycle.md` 1, `aid-brainstorm` 5, `aid-design` 110 |
| 182 | `site/scripts/__tests__/flow-classify.test.mjs` | task-037 | `shortcut-engine.md` 4 |
| 183 | `site/scripts/__tests__/flow-compose.test.mjs` | task-037 | `shortcut-engine.md` 5 |
| 184 | `site/scripts/__tests__/flow-engine-core.test.mjs` | task-037 | `shortcut-engine.md` 6 |
| 185 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | task-037 | `shortcut-engine.md` 2 |
| 186 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-037 | `shortcut-engine.md` 6 |
| 187 | `site/scripts/__tests__/flow-graph.test.mjs` | task-037 | `shortcut-engine.md` 4 |
| 188 | `site/scripts/__tests__/gen-reference.test.mjs` | task-037 | `shortcut-engine.md` 1 |
| 189 | `site/scripts/__tests__/provenance-appender.test.mjs` | task-037 | `shortcut-engine.md` 5 |
| 190 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | task-037 | `shortcut-engine.md` 1 |
| 191 | `tests/canonical/test-artifact-discipline.sh` | task-037 | `shortcut-engine.md` 2 |
| 192 | `tests/canonical/test-catalog-dirs-parity.sh` | task-037 | `shortcut-engine.md` 2 |
| 193 | `tests/canonical/test-change-refactor-family-scaffold.sh` | task-037 | `shortcut-engine.md` 1 |
| 194 | `tests/canonical/test-create-family-scaffold.sh` | task-037 | `shortcut-engine.md` 6 |
| 195 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-037 | `shortcut-engine.md` 2 |
| 196 | `tests/canonical/test-document-family-scaffold.sh` | task-037 | `shortcut-engine.md` 2 |
| 197 | `tests/canonical/test-downstream-worktree-entry.sh` | task-037 | `shortcut-engine.md` 2 |
| 198 | `tests/canonical/test-fix-family-scaffold.sh` | task-037 | `shortcut-engine.md` 1 |
| 199 | `tests/canonical/test-prototype-family-scaffold.sh` | task-037 | `shortcut-engine.md` 2 |
| 200 | `tests/canonical/test-shortcut-engine-contract.sh` | task-037 | `shortcut-engine.md` 8 |
| 201 | `tests/canonical/test-state-review-surface.sh` | task-037 | `shortcut-engine.md` 7 |
| 202 | `tests/canonical/test-test-experiment-family-scaffold.sh` | task-037 | `shortcut-engine.md` 2 |
| 203 | `tests/canonical/test-ticket-retirement-structural.sh` | task-037 | `shortcut-engine.md` 5 |
| 204 | `tests/cost-baseline.tsv` | task-037 | `shortcut-engine.md` 1 |
| 205 | `tests/coverage-baseline.tsv` | task-037 | `shortcut-engine.md` 4 |
| 206 | `tests/canonical/fixtures/dual-intent/content/doc-set.tsv` | task-045 | `decisions.md` 1, `domain-glossary.md` 1 |
| 207 | `tests/canonical/fixtures/dual-intent/data-ml/doc-set.tsv` | task-045 | `decisions.md` 1, `domain-glossary.md` 1 |
| 208 | `tests/canonical/fixtures/dual-intent/design/doc-set.tsv` | task-045 | `decisions.md` 1, `domain-glossary.md` 1 |
| 209 | `tests/canonical/test-chat-node-wake.sh` | task-045 | `decisions.md` 1 |
| 210 | `tests/canonical/test-domain-doc-matrix.sh` | task-045 | `decisions.md` 15 |
| 211 | `tests/canonical/test-grade-summary.sh` | task-045 | `decisions.md` 6, `domain-glossary.md` 8 |
| 212 | `tests/canonical/test-kb-review-surface.sh` | task-045 | `decisions.md` 3 |
| 213 | `tests/canonical/fixtures/actback-task/docset-check.tsv` | task-045 | `domain-glossary.md` 1 |
| 214 | `tests/canonical/fixtures/actback-task/kb/domain-glossary.md` | task-045 | `domain-glossary.md` 1 |
| 215 | `tests/canonical/fixtures/kb-essence/actback/actback-fail-kb/knowledge/domain-glossary.md` | task-045 | `domain-glossary.md` 1 |
| 216 | `tests/canonical/fixtures/kb-essence/actback/representative-task-fixture/doc-set.tsv` | task-045 | `domain-glossary.md` 1 |
| 217 | `tests/canonical/fixtures/kb-essence/actback/representative-task-fixture/expected/task-spec.txt` | task-045 | `domain-glossary.md` 1 |
| 218 | `tests/canonical/fixtures/kb-essence/closed-kb/knowledge/architecture.md` | task-045 | `domain-glossary.md` 1 |
| 219 | `tests/canonical/test-actback-fixtures.sh` | task-045 | `domain-glossary.md` 14 |
| 220 | `tests/canonical/test-actback-task.sh` | task-045 | `domain-glossary.md` 15 |
| 221 | `tests/canonical/test-closure-batching.sh` | task-045 | `domain-glossary.md` 2 |
| 222 | `tests/canonical/test-closure-check.sh` | task-045 | `domain-glossary.md` 5 |
| 223 | `tests/canonical/test-doc-set-mapping.sh` | task-045 | `domain-glossary.md` 5 |
| 224 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-045 | `domain-glossary.md` 2 |
| 225 | `tests/canonical/test-essence-capture.sh` | task-045 | `domain-glossary.md` 2 |
| 226 | `tests/canonical/test-output-root-isolation.sh` | task-045 | `domain-glossary.md` 4 |
| 227 | `tests/canonical/test-teachback-fixtures.sh` | task-045 | `domain-glossary.md` 5 |
| 228 | `tests/cost-baseline.tsv` | task-045 | `domain-glossary.md` 1 |
| 229 | `tests/coverage-baseline.tsv` | task-045 | `domain-glossary.md` 2 |
| 230 | `tests/canonical/fixtures/actback-task/docset-contract.tsv` | task-049 | `pipeline-contracts.md` 1 |
| 231 | `tests/canonical/test-actback-task.sh` | task-049 | `pipeline-contracts.md` 1, `architecture.md` 3 |
| 232 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-049 | `pipeline-contracts.md` 8 |
| 233 | `tests/canonical/test-doc-set-mapping.sh` | task-049 | `pipeline-contracts.md` 9, `architecture.md` 10 |
| 234 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-049 | `pipeline-contracts.md` 2, `architecture.md` 4 |
| 235 | `tests/canonical/test-doc-set-read.sh` | task-049 | `pipeline-contracts.md` 5, `architecture.md` 13 |
| 236 | `tests/cost-baseline.tsv` | task-049 | `pipeline-contracts.md` 1, `architecture.md` 1 |
| 237 | `tests/coverage-baseline.tsv` | task-049 | `pipeline-contracts.md` 4, `architecture.md` 12 |
| 238 | `dashboard/reader/tests/test_reader.py` | task-049 | `architecture.md` 1 |
| 239 | `tests/canonical/fixtures/actback-task/docset-component.tsv` | task-049 | `architecture.md` 1 |
| 240 | `tests/canonical/fixtures/kb-essence/paths/brownfield-large/generated/project-index.md` | task-049 | `architecture.md` 1 |
| 241 | `tests/canonical/fixtures/kb-essence/unclosed-kb/knowledge/domain-glossary.md` | task-049 | `architecture.md` 2 |
| 242 | `tests/canonical/fixtures/teachback-questions/candidate-concepts-mixed.md` | task-049 | `architecture.md` 1 |
| 243 | `tests/canonical/test-build-kb-index.sh` | task-049 | `architecture.md` 3 |
| 244 | `tests/canonical/test-closure-check.sh` | task-049 | `architecture.md` 16 |
| 245 | `tests/canonical/test-conformance-lane-semantics.sh` | task-049 | `architecture.md` 4 |
| 246 | `tests/canonical/test-essence-capture.sh` | task-049 | `architecture.md` 1 |
| 247 | `tests/canonical/test-expectations-single-source.sh` | task-049 | `architecture.md` 9 |
| 248 | `tests/canonical/test-frontmatter-lint.sh` | task-049 | `architecture.md` 1 |
| 249 | `tests/canonical/test-grade-summary.sh` | task-049 | `architecture.md` 6 |
| 250 | `tests/canonical/test-harvest-coined-terms.sh` | task-049 | `architecture.md` 1 |
| 251 | `tests/canonical/test-housekeep-classify.sh` | task-049 | `architecture.md` 2 |
| 252 | `tests/canonical/test-kb-html-claims-check.sh` | task-049 | `architecture.md` 4 |
| 253 | `tests/canonical/test-kb-index-extract-list.sh` | task-049 | `architecture.md` 4 |
| 254 | `tests/canonical/test-kb-review-surface.sh` | task-049 | `architecture.md` 3 |
| 255 | `tests/canonical/test-spine-depth-coverage.sh` | task-049 | `architecture.md` 3 |
| 256 | `tests/canonical/test-summarize-preflight.sh` | task-049 | `architecture.md` 1 |
| 257 | `tests/canonical/test-validator-behavior.sh` | task-049 | `architecture.md` 5 |
| 258 | `tests/conversation/fixtures/default/.aid/knowledge/INDEX.md` | task-049 | `architecture.md` 1 |
| 259 | `tests/conversation/fixtures/done-work/.aid/knowledge/INDEX.md` | task-049 | `architecture.md` 1 |
| 260 | `tests/conversation/fixtures/empty-notes-file/.aid/knowledge/INDEX.md` | task-049 | `architecture.md` 1 |
| 261 | `tests/conversation/fixtures/ticket-mid-work/.aid/knowledge/INDEX.md` | task-049 | `architecture.md` 1 |
| 262 | `tests/conversation/samples/feature-001/001-05-project-question.md` | task-049 | `architecture.md` 1 |
| 263 | `tests/conversation/samples/feature-001/001-06-kb-conflict.md` | task-049 | `architecture.md` 1 |
| 264 | `tests/canonical/test-discovery-doc-ownership.sh` | task-057 | `test-landscape.md` 4 |
| 265 | `tests/canonical/test-doc-set-mapping.sh` | task-057 | `test-landscape.md` 13 |
| 266 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-057 | `test-landscape.md` 9 |
| 267 | `tests/canonical/test-validator-behavior.sh` | task-057 | `test-landscape.md` 1, `INDEX.md` 5 |
| 268 | `tests/cost-baseline.tsv` | task-057 | `test-landscape.md` 1 |
| 269 | `tests/coverage-baseline.tsv` | task-057 | `test-landscape.md` 5, `INDEX.md` 7 |
| 270 | `dashboard/reader/tests/test_task019_connectors.py` | task-057 | `INDEX.md` 3 |
| 271 | `dashboard/server/tests/test_task019_connector_ops.mjs` | task-057 | `INDEX.md` 2 |
| 272 | `dashboard/server/tests/test_task019_connector_ops.py` | task-057 | `INDEX.md` 2 |
| 273 | `dashboard/server/tests/test_task023_list_management_round_trips.py` | task-057 | `INDEX.md` 7 |
| 274 | `tests/canonical/test-build-connectors-index.sh` | task-057 | `INDEX.md` 15 |
| 275 | `tests/canonical/test-connector-registry.sh` | task-057 | `INDEX.md` 4 |
| 276 | `tests/canonical/test-connector-set-unset-lifecycle.sh` | task-057 | `INDEX.md` 6 |
| 277 | `tests/canonical/test-connector-twins-ps1-parity.sh` | task-057 | `INDEX.md` 9 |
| 278 | `tests/canonical/test-connectors-registry-integration.sh` | task-057 | `INDEX.md` 10 |
| 279 | `tests/canonical/test-conversation-runner.sh` | task-057 | `INDEX.md` 2 |
| 280 | `tests/canonical/test-frontmatter-lint.sh` | task-057 | `INDEX.md` 1 |
| 281 | `tests/canonical/test-grade-summary.sh` | task-057 | `INDEX.md` 2 |
| 282 | `tests/canonical/test-guardrails-d012.sh` | task-057 | `INDEX.md` 1 |
| 283 | `tests/canonical/test-kb-forward-authored-marker.sh` | task-057 | `INDEX.md` 2 |
| 284 | `tests/canonical/test-kb-freshness-check.sh` | task-057 | `INDEX.md` 6 |
| 285 | `tests/canonical/test-kb-review-surface.sh` | task-057 | `INDEX.md` 5 |
| 286 | `tests/canonical/test-payload-size.sh` | task-057 | `INDEX.md` 1 |
| 287 | `tests/canonical/test-reconcile-scenarios.sh` | task-057 | `INDEX.md` 30 |
| 288 | `tests/canonical/test-write-connector.sh` | task-057 | `INDEX.md` 7 |
| 289 | `tests/cost-meter.py` | task-057 | `INDEX.md` 1 |
| 290 | `tests/canonical/test-connector-skills-structural.sh` | task-043 | `ticket-resolution.md` 2, `aid-config` 2, `aid-set-connector` 14, `aid-unset-connector` 13 |
| 291 | `tests/canonical/test-ticket-skills-structural.sh` | task-043 | `ticket-resolution.md` 10, `aid-create-ticket` 35, `aid-read-ticket` 18, `aid-update-ticket` 32 |
| 292 | `tests/cost-baseline.tsv` | task-043 | `ticket-resolution.md` 1, `aid-chat` 5, `aid-config` 5, `aid-create-ticket` 5, `aid-deploy` 5, `aid-monitor` 5, `aid-read-ticket` 5, `aid-set-connector` 5, `aid-unset-connector` 5, `aid-update-ticket` 5 |
| 293 | `tests/coverage-baseline.tsv` | task-043 | `ticket-resolution.md` 3, `aid-create-ticket` 33, `aid-deploy` 9, `aid-monitor` 6, `aid-read-ticket` 16, `aid-update-ticket` 25 |
| 294 | `tests/canonical/test-version-sync.sh` | task-056 | `release.yml` 15 |
| 295 | `tests/canonical/test-ps51-compat.sh` | task-056 | `installer-tests.yml` 1 |
| 296 | `tests/windows/Test-AidInstaller.ps1` | task-056 | `installer-tests.yml` 1, `release.sh` 3 |
| 297 | `tests/canonical/test-aid-cli-ps1.sh` | task-056 | `release.sh` 1 |
| 298 | `tests/canonical/test-aid-cli.sh` | task-056 | `release.sh` 1 |
| 299 | `tests/canonical/test-aid-migrate-trigger.sh` | task-056 | `release.sh` 7 |
| 300 | `tests/canonical/test-aid-migrate.sh` | task-056 | `release.sh` 1 |
| 301 | `tests/canonical/test-chat-node-manifest.sh` | task-056 | `release.sh` 4 |
| 302 | `tests/canonical/test-conversation-runner.sh` | task-056 | `release.sh` 1 |
| 303 | `tests/canonical/test-dashboard-manifest.sh` | task-056 | `release.sh` 2 |
| 304 | `tests/canonical/test-npm-installer.sh` | task-056 | `release.sh` 1 |
| 305 | `tests/canonical/test-pypi-installer.sh` | task-056 | `release.sh` 1 |
| 306 | `tests/canonical/test-registry.sh` | task-056 | `release.sh` 1 |
| 307 | `tests/canonical/test-release-install-e2e.sh` | task-056 | `release.sh` 20 |
| 308 | `tests/canonical/test-release-migrate-smoke.sh` | task-056 | `release.sh` 1 |
| 309 | `tests/canonical/test-shared-install.sh` | task-056 | `release.sh` 1 |
| 310 | `tests/canonical/test-shortcut-builder-invariants.sh` | task-056 | `release.sh` 1 |
| 311 | `tests/canonical/test-shortcut-engine-contract.sh` | task-056 | `release.sh` 1 |
| 312 | `tests/coverage-accepted-removals.tsv` | task-056 | `release.sh` 2 |
| 313 | `tests/coverage-baseline.tsv` | task-056 | `release.sh` 17 |
| 314 | `tests/lib/bundle.sh` | task-056 | `release.sh` 2 |
| 315 | `site/scripts/__tests__/provenance.test.mjs` | task-042 | `aid-ask` 2 |
| 316 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | task-042 | `aid-ask` 15 |
| 317 | `site/src/lib/__tests__/skill-node-panel.test.ts` | task-042 | `aid-ask` 20 |
| 318 | `tests/canonical/test-aid-migrate.sh` | task-042 | `aid-ask` 1 |
| 319 | `tests/canonical/test-dogfood-byte-identity.sh` | task-042 | `aid-ask` 2 |
| 320 | `tests/canonical/test-multitool-isolation.sh` | task-042 | `aid-ask` 4 |
| 321 | `tests/canonical/test-ticket-retirement-structural.sh` | task-042 | `aid-ask` 5 |
| 322 | `tests/windows/Test-AidInstaller.ps1` | task-042 | `aid-ask` 3 |
| 323 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | task-042 | `aid-ask` 5 |
| 324 | `site/scripts/__tests__/gen-reference.test.mjs` | task-042 | `aid-ask` 1, `aid-housekeep` 1, `aid-summarize` 1, `aid-update-kb` 1 |
| 325 | `site/scripts/__tests__/provenance-appender.test.mjs` | task-042 | `aid-ask` 3 |
| 326 | `site/scripts/__tests__/skill-counts.test.mjs` | task-042 | `aid-ask` 2 |
| 327 | `tests/canonical/fixtures/install-core-primitives/manifest-v3.golden.json` | task-042 | `aid-ask` 1 |
| 328 | `tests/canonical/fixtures/install-core-primitives/manifest-v3.model.tsv` | task-042 | `aid-ask` 1 |
| 329 | `tests/canonical/test-catalog-dirs-parity.sh` | task-042 | `aid-ask` 1 |
| 330 | `tests/canonical/test-connector-consumption-linkage.sh` | task-042 | `aid-ask` 1 |
| 331 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-042 | `aid-ask` 1 |
| 332 | `tests/cost-baseline.tsv` | task-042 | `aid-ask` 5, `aid-housekeep` 5, `aid-summarize` 5, `aid-update-kb` 5 |
| 333 | `tests/coverage-baseline.tsv` | task-042 | `aid-ask` 2, `aid-housekeep` 1, `aid-update-kb` 1 |
| 334 | `tests/conversation/samples/feature-001/001-07-rich-ticket.md` | task-034 | `aid-brainstorm` 1 |
| 335 | `tests/conversation/samples/feature-001/001-08-bare-idea.md` | task-034 | `aid-brainstorm` 1 |
| 336 | `tests/conversation/samples/feature-001/001-09-bug-fix-phases.md` | task-034 | `aid-brainstorm` 1 |
| 337 | `tests/conversation/samples/feature-001/001-14-refactor-is-new-capability.md` | task-034 | `aid-brainstorm` 1 |
| 338 | `tests/canonical/test-chat-node-hub.sh` | task-043 | `aid-chat` 1 |
| 339 | `tests/canonical/test-chat-node-wake.sh` | task-043 | `aid-chat` 3 |
| 340 | `site/scripts/__tests__/gen-reference.test.mjs` | task-043 | `aid-chat` 1, `aid-config` 1, `aid-create-ticket` 1, `aid-deploy` 1, `aid-monitor` 1, `aid-read-ticket` 1, `aid-set-connector` 1, `aid-unset-connector` 1, `aid-update-ticket` 1 |
| 341 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | task-043 | `aid-config` 8, `aid-create-ticket` 4, `aid-read-ticket` 2, `aid-set-connector` 2, `aid-unset-connector` 2, `aid-update-ticket` 2 |
| 342 | `dashboard/reader/tests/test_reader.py` | task-043 | `aid-config` 3 |
| 343 | `dashboard/server/tests/test_server_node.mjs` | task-043 | `aid-config` 1 |
| 344 | `dashboard/server/tests/test_task012_consuming_round_trips.py` | task-043 | `aid-config` 2 |
| 345 | `site/scripts/__tests__/flow-facade.test.mjs` | task-043 | `aid-config` 16 |
| 346 | `site/scripts/__tests__/skills-groups.test.mjs` | task-043 | `aid-config` 7, `aid-deploy` 13, `aid-monitor` 10 |
| 347 | `tests/cost-baseline.tsv` | task-036 | `aid-create-architecture` 5, `aid-create-backlog` 5, `aid-create-cicd` 5, `aid-create-mvp` 5, `aid-create-roadmap` 5, `aid-create-stack` 5, `aid-create-testing-strategy` 5, `aid-update-architecture` 5, `aid-update-backlog` 5, `aid-update-cicd` 5, `aid-update-mvp` 5, `aid-update-roadmap` 5, `aid-update-stack` 5, `aid-update-testing-strategy` 5 |
| 348 | `site/scripts/__tests__/flow-compose.test.mjs` | task-044 | `aid-create-document` 4, `aid-test` 8 |
| 349 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | task-044 | `aid-create-document` 2, `aid-prototype` 1, `aid-report` 2, `aid-research` 1, `aid-review` 5, `aid-test` 5, `aid-update-document` 5 |
| 350 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | task-044 | `aid-create-document` 6, `aid-test` 53 |
| 351 | `tests/canonical/test-create-family-scaffold.sh` | task-044 | `aid-create-document` 3, `aid-report` 3, `aid-review` 1, `aid-test` 3 |
| 352 | `tests/canonical/test-document-family-scaffold.sh` | task-044 | `aid-create-document` 2, `aid-report` 2, `aid-review` 1, `aid-update-document` 1 |
| 353 | `tests/cost-baseline.tsv` | task-044 | `aid-create-document` 5, `aid-prototype` 10, `aid-report` 5, `aid-research` 6, `aid-review` 6, `aid-test` 20, `aid-update-document` 5 |
| 354 | `tests/coverage-baseline.tsv` | task-044 | `aid-create-document` 3, `aid-prototype` 5, `aid-report` 4, `aid-research` 24, `aid-review` 15, `aid-test` 3, `aid-update-document` 3 |
| 355 | `tests/canonical/test-ticket-retirement-structural.sh` | task-043 | `aid-create-ticket` 9, `aid-deploy` 10, `aid-monitor` 11, `aid-read-ticket` 9, `aid-set-connector` 1, `aid-update-ticket` 14 |
| 356 | `tests/canonical/test-downstream-worktree-entry.sh` | task-039 | `aid-define` 16, `aid-specify` 12 |
| 357 | `tests/canonical/test-shared-prune.sh` | task-039 | `aid-define` 3 |
| 358 | `tests/canonical/test-state-review-surface.sh` | task-039 | `aid-define` 1, `aid-specify` 1 |
| 359 | `dashboard/reader/tests/test_work003_state_schema.py` | task-039 | `aid-define` 1 |
| 360 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-039 | `aid-define` 8, `aid-specify` 5 |
| 361 | `site/scripts/__tests__/flow-graph.test.mjs` | task-039 | `aid-define` 5 |
| 362 | `site/scripts/__tests__/gen-reference.test.mjs` | task-039 | `aid-define` 1, `aid-specify` 1 |
| 363 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-039 | `aid-define` 1, `aid-specify` 1 |
| 364 | `site/scripts/__tests__/skills-groups.test.mjs` | task-039 | `aid-define` 1, `aid-specify` 1 |
| 365 | `tests/canonical/test-artifact-discipline.sh` | task-039 | `aid-define` 2, `aid-specify` 2 |
| 366 | `tests/canonical/test-scoped-review-cycles.sh` | task-039 | `aid-define` 1, `aid-specify` 5 |
| 367 | `tests/cost-baseline.tsv` | task-039 | `aid-define` 5, `aid-specify` 5 |
| 368 | `tests/coverage-baseline.tsv` | task-039 | `aid-define` 14, `aid-specify` 16 |
| 369 | `tests/coverage-rehome-allowlist.tsv` | task-039 | `aid-define` 1, `aid-specify` 1 |
| 370 | `tests/canonical/test-downstream-worktree-entry.sh` | task-043 | `aid-deploy` 10 |
| 371 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-043 | `aid-deploy` 1 |
| 372 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-043 | `aid-deploy` 1, `aid-monitor` 1 |
| 373 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-043 | `aid-deploy` 8, `aid-monitor` 8 |
| 374 | `site/scripts/__tests__/skills-catalog.test.mjs` | task-043 | `aid-deploy` 4, `aid-monitor` 2 |
| 375 | `site/scripts/__tests__/skills-render-index.test.mjs` | task-043 | `aid-deploy` 2, `aid-monitor` 2 |
| 376 | `tests/canonical/test-catalog-dirs-parity.sh` | task-043 | `aid-deploy` 1, `aid-monitor` 1 |
| 377 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-043 | `aid-deploy` 14, `aid-monitor` 21 |
| 378 | `tests/coverage-rehome-allowlist.tsv` | task-043 | `aid-deploy` 1, `aid-read-ticket` 1, `aid-update-ticket` 1 |
| 379 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-038 | `aid-describe` 25 |
| 380 | `tests/canonical/test-cutover-no-dangling.sh` | task-038 | `aid-describe` 3 |
| 381 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-038 | `aid-describe` 3 |
| 382 | `tests/canonical/test-ticket-retirement-structural.sh` | task-038 | `aid-describe` 16 |
| 383 | `dashboard/reader/tests/test_feature009.py` | task-038 | `aid-describe` 1 |
| 384 | `dashboard/reader/tests/test_shortcut_kind_map_cross_runtime_parity.py` | task-038 | `aid-describe` 5 |
| 385 | `dashboard/reader/tests/test_work003_state_schema.py` | task-038 | `aid-describe` 6 |
| 386 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-006-lite-sample/SPEC.md` | task-038 | `aid-describe` 1 |
| 387 | `site/scripts/__tests__/flow-facade.test.mjs` | task-038 | `aid-describe` 8 |
| 388 | `site/scripts/__tests__/flow-graph.test.mjs` | task-038 | `aid-describe` 3 |
| 389 | `site/scripts/__tests__/gen-reference.test.mjs` | task-038 | `aid-describe` 1 |
| 390 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-038 | `aid-describe` 1 |
| 391 | `site/scripts/__tests__/skills-groups.test.mjs` | task-038 | `aid-describe` 3 |
| 392 | `tests/canonical/test-connector-consumption-linkage.sh` | task-038 | `aid-describe` 1 |
| 393 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-038 | `aid-describe` 5 |
| 394 | `tests/canonical/test-describe-full-only.sh` | task-038 | `aid-describe` 9 |
| 395 | `tests/canonical/test-path-fixtures.sh` | task-038 | `aid-describe` 1 |
| 396 | `tests/conversation/fixtures/done-work/.aid/works/work-001-csv-export/STATE.yml` | task-038 | `aid-describe` 1 |
| 397 | `tests/conversation/fixtures/ticket-mid-work/.aid/works/work-001-retry-policy/STATE.yml` | task-038 | `aid-describe` 1 |
| 398 | `tests/cost-baseline.tsv` | task-038 | `aid-describe` 5 |
| 399 | `tests/coverage-baseline.tsv` | task-038 | `aid-describe` 12 |
| 400 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | task-034 | `aid-design` 4 |
| 401 | `tests/coverage-baseline.tsv` | task-034 | `aid-design` 3 |
| 402 | `tests/cost-baseline.tsv` | task-035 | `aid-design-api` 5, `aid-design-architecture` 5, `aid-design-backlog` 5, `aid-design-cicd` 5, `aid-design-cli` 5, `aid-design-config` 5, `aid-design-dashboard` 5, `aid-design-data-model` 5, `aid-design-data-pipeline` 5, `aid-design-document` 5, `aid-design-infra` 5, `aid-design-integration` 5, `aid-design-job` 5, `aid-design-messaging` 5, `aid-design-mvp` 5, `aid-design-roadmap` 5, `aid-design-stack` 5, `aid-design-test` 10, `aid-design-testing-strategy` 5, `aid-design-theme` 5, `aid-design-ui` 5 |
| 403 | `dashboard/reader/tests/test_feature009.py` | task-040 | `aid-detail` 9, `aid-execute` 2 |
| 404 | `tests/canonical/test-artifact-discipline.sh` | task-040 | `aid-detail` 1, `aid-plan` 2 |
| 405 | `tests/canonical/test-downstream-worktree-entry.sh` | task-040 | `aid-detail` 7, `aid-execute` 10, `aid-plan` 7 |
| 406 | `tests/canonical/test-state-review-surface.sh` | task-040 | `aid-detail` 1, `aid-execute` 1, `aid-plan` 1 |
| 407 | `tests/canonical/test-ticket-retirement-structural.sh` | task-040 | `aid-detail` 11, `aid-execute` 23, `aid-plan` 22 |
| 408 | `dashboard/reader/tests/test_flattened_layout_parity.py` | task-040 | `aid-detail` 1, `aid-execute` 1, `aid-plan` 1 |
| 409 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-040 | `aid-detail` 1, `aid-execute` 5, `aid-plan` 1 |
| 410 | `site/scripts/__tests__/gen-reference.test.mjs` | task-040 | `aid-detail` 1, `aid-execute` 1, `aid-plan` 1 |
| 411 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-040 | `aid-detail` 1, `aid-plan` 1 |
| 412 | `site/scripts/__tests__/skills-groups.test.mjs` | task-040 | `aid-detail` 1, `aid-plan` 11 |
| 413 | `tests/canonical/test-derive-waves.sh` | task-040 | `aid-detail` 1 |
| 414 | `tests/canonical/test-scoped-review-cycles.sh` | task-040 | `aid-detail` 1, `aid-plan` 2 |
| 415 | `tests/cost-baseline.tsv` | task-040 | `aid-detail` 5, `aid-execute` 5, `aid-plan` 5 |
| 416 | `tests/coverage-baseline.tsv` | task-040 | `aid-detail` 16, `aid-execute` 22, `aid-plan` 19 |
| 417 | `tests/coverage-rehome-allowlist.tsv` | task-040 | `aid-detail` 1, `aid-execute` 1, `aid-plan` 1 |
| 418 | `tests/canonical/test-connector-skills-structural.sh` | task-041 | `aid-discover` 5 |
| 419 | `tests/canonical/test-cutover-no-dangling.sh` | task-041 | `aid-discover` 7 |
| 420 | `tests/canonical/test-discovery-doc-ownership.sh` | task-041 | `aid-discover` 2 |
| 421 | `tests/canonical/test-doc-set-mapping.sh` | task-041 | `aid-discover` 1 |
| 422 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-041 | `aid-discover` 1 |
| 423 | `tests/canonical/test-doc-set-read.sh` | task-041 | `aid-discover` 2 |
| 424 | `tests/canonical/test-domain-doc-matrix.sh` | task-041 | `aid-discover` 1 |
| 425 | `tests/canonical/test-expectations-single-source.sh` | task-041 | `aid-discover` 4 |
| 426 | `tests/canonical/test-kb-review-surface.sh` | task-041 | `aid-discover` 2 |
| 427 | `tests/canonical/test-ledger-isolation.sh` | task-041 | `aid-discover` 3 |
| 428 | `tests/canonical/test-output-root-isolation.sh` | task-041 | `aid-discover` 1 |
| 429 | `tests/canonical/test-reconcile-scenarios.sh` | task-041 | `aid-discover` 1 |
| 430 | `tests/canonical/test-spine-depth-coverage.sh` | task-041 | `aid-discover` 3 |
| 431 | `tests/canonical/test-state-review-surface.sh` | task-041 | `aid-discover` 1 |
| 432 | `dashboard/reader/tests/test_task066_kb_parity.py` | task-041 | `aid-discover` 2 |
| 433 | `dashboard/server/tests/fixtures/pt023-external-sources/multi-entry.md` | task-041 | `aid-discover` 1 |
| 434 | `dashboard/server/tests/fixtures/pt023-external-sources/placeholder-only.md` | task-041 | `aid-discover` 1 |
| 435 | `dashboard/server/tests/fixtures/pt023-external-sources/single-entry.md` | task-041 | `aid-discover` 1 |
| 436 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-041 | `aid-discover` 1 |
| 437 | `site/scripts/__tests__/gen-reference.test.mjs` | task-041 | `aid-discover` 1 |
| 438 | `site/scripts/__tests__/gen-skills.test.mjs` | task-041 | `aid-discover` 2 |
| 439 | `tests/README.md` | task-041 | `aid-discover` 1 |
| 440 | `tests/canonical/test-conformance-lane-semantics.sh` | task-041 | `aid-discover` 5 |
| 441 | `tests/canonical/test-grade-summary.sh` | task-041 | `aid-discover` 2 |
| 442 | `tests/canonical/test-harvest-batching.sh` | task-041 | `aid-discover` 1 |
| 443 | `tests/canonical/test-kb-template-authoring-standard.sh` | task-041 | `aid-discover` 1 |
| 444 | `tests/canonical/test-path-fixtures.sh` | task-041 | `aid-discover` 1 |
| 445 | `tests/canonical/test-summarize-preflight.sh` | task-041 | `aid-discover` 1 |
| 446 | `tests/canonical/test-ticket-retirement-structural.sh` | task-041 | `aid-discover` 1 |
| 447 | `tests/canonical/test-write-external-source.sh` | task-041 | `aid-discover` 3 |
| 448 | `tests/conversation/samples/feature-001/001-15-no-kb-offers-preparation.md` | task-041 | `aid-discover` 1 |
| 449 | `tests/cost-baseline.tsv` | task-041 | `aid-discover` 5 |
| 450 | `tests/canonical/test-compute-block-radius.sh` | task-040 | `aid-execute` 1 |
| 451 | `tests/canonical/test-delivery-gate-aggregate.sh` | task-040 | `aid-execute` 4 |
| 452 | `tests/canonical/test-task-state-transitions.sh` | task-040 | `aid-execute` 5 |
| 453 | `dashboard/reader/tests/fixtures/task011_golden/flat_golden.json` | task-040 | `aid-execute` 1 |
| 454 | `dashboard/reader/tests/fixtures/task011_golden/hierarchical_golden.json` | task-040 | `aid-execute` 1 |
| 455 | `dashboard/reader/tests/test_fixtures.py` | task-040 | `aid-execute` 5 |
| 456 | `dashboard/reader/tests/test_reader.py` | task-040 | `aid-execute` 10, `aid-plan` 1 |
| 457 | `dashboard/reader/tests/test_resolve_work_dir_cross_runtime_parity.py` | task-040 | `aid-execute` 1 |
| 458 | `dashboard/reader/tests/test_security_hardening.py` | task-040 | `aid-execute` 1 |
| 459 | `dashboard/reader/tests/test_task002_resolve_work_dir.py` | task-040 | `aid-execute` 1 |
| 460 | `dashboard/reader/tests/test_task011_golden_master.py` | task-040 | `aid-execute` 2 |
| 461 | `dashboard/reader/tests/test_task011_reconcile.py` | task-040 | `aid-execute` 3 |
| 462 | `dashboard/reader/tests/test_task014_fixtures.py` | task-040 | `aid-execute` 7 |
| 463 | `dashboard/reader/tests/test_task069_detail_parser.py` | task-040 | `aid-execute` 1 |
| 464 | `dashboard/reader/tests/test_work001_delivery_layouts.py` | task-040 | `aid-execute` 1 |
| 465 | `dashboard/reader/tests/test_work003_state_schema.py` | task-040 | `aid-execute` 5 |
| 466 | `dashboard/reader/tests/test_work016_container_discovery.py` | task-040 | `aid-execute` 1 |
| 467 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-001-running-parallel/STATE.md` | task-040 | `aid-execute` 1 |
| 468 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-001-running-parallel/STATE.yml` | task-040 | `aid-execute` 1 |
| 469 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-003-blocked/STATE.md` | task-040 | `aid-execute` 1 |
| 470 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-003-blocked/STATE.yml` | task-040 | `aid-execute` 1 |
| 471 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-006-lite-sample/STATE.md` | task-040 | `aid-execute` 1 |
| 472 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-006-lite-sample/STATE.yml` | task-040 | `aid-execute` 1 |
| 473 | `dashboard/server/tests/fixtures/pt1h-detail-repo/.aid/works/work-001-detail/STATE.yml` | task-040 | `aid-execute` 1 |
| 474 | `dashboard/server/tests/fixtures/pt1h-repo-a/.aid/works/work-001-with-unicode/STATE.md` | task-040 | `aid-execute` 1 |
| 475 | `dashboard/server/tests/fixtures/pt1h-repo-b/.aid/works/work-001-minimal/STATE.md` | task-040 | `aid-execute` 1 |
| 476 | `dashboard/server/tests/test_reader_task069.mjs` | task-040 | `aid-execute` 2 |
| 477 | `dashboard/server/tests/test_task002_resolve_work_dir.mjs` | task-040 | `aid-execute` 1 |
| 478 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | task-040 | `aid-execute` 1 |
| 479 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-040 | `aid-execute` 4 |
| 480 | `site/scripts/__tests__/flow-render-mermaid.test.mjs` | task-040 | `aid-execute` 2 |
| 481 | `site/scripts/__tests__/gen-skills.test.mjs` | task-040 | `aid-execute` 1 |
| 482 | `site/src/lib/__tests__/skill-node-panel.test.ts` | task-040 | `aid-execute` 1, `aid-plan` 4 |
| 483 | `tests/README.md` | task-040 | `aid-execute` 2 |
| 484 | `tests/canonical/fixtures/migrate/fixture-source/work-999-migration-test/STATE.md` | task-040 | `aid-execute` 1 |
| 485 | `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/STATE.md` | task-040 | `aid-execute` 1 |
| 486 | `tests/canonical/test-change-refactor-family-scaffold.sh` | task-040 | `aid-execute` 2 |
| 487 | `tests/canonical/test-connector-consumption-linkage.sh` | task-040 | `aid-execute` 2, `aid-plan` 1 |
| 488 | `tests/canonical/test-conversation-runner.sh` | task-040 | `aid-execute` 4, `aid-plan` 2 |
| 489 | `tests/canonical/test-create-family-scaffold.sh` | task-040 | `aid-execute` 2 |
| 490 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-040 | `aid-execute` 1 |
| 491 | `tests/canonical/test-document-family-scaffold.sh` | task-040 | `aid-execute` 2 |
| 492 | `tests/canonical/test-fix-family-scaffold.sh` | task-040 | `aid-execute` 1 |
| 493 | `tests/canonical/test-kb-no-work-ids.sh` | task-040 | `aid-execute` 3 |
| 494 | `tests/canonical/test-prototype-family-scaffold.sh` | task-040 | `aid-execute` 2 |
| 495 | `tests/canonical/test-test-experiment-family-scaffold.sh` | task-040 | `aid-execute` 3 |
| 496 | `tests/conversation/fixtures/done-work/.aid/works/work-001-csv-export/STATE.yml` | task-040 | `aid-execute` 1 |
| 497 | `tests/cost-meter.py` | task-040 | `aid-execute` 1 |
| 498 | `tests/canonical/test-conformance-lane-semantics.sh` | task-042 | `aid-housekeep` 1 |
| 499 | `tests/canonical/test-f010-governance-guards.sh` | task-042 | `aid-housekeep` 2, `aid-update-kb` 4 |
| 500 | `tests/canonical/test-output-root-isolation.sh` | task-042 | `aid-housekeep` 1 |
| 501 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-042 | `aid-housekeep` 1, `aid-summarize` 1, `aid-update-kb` 3 |
| 502 | `site/scripts/__tests__/flow-graph.test.mjs` | task-042 | `aid-housekeep` 2, `aid-update-kb` 3 |
| 503 | `tests/canonical/test-connector-skills-structural.sh` | task-042 | `aid-housekeep` 2 |
| 504 | `tests/canonical/test-doc-counts.sh` | task-042 | `aid-housekeep` 2 |
| 505 | `tests/canonical/test-worktree-lifecycle.sh` | task-042 | `aid-housekeep` 1 |
| 506 | `tests/coverage-accepted-removals.tsv` | task-043 | `aid-monitor` 2 |
| 507 | `tests/canonical/test-document-family-scaffold.sh` | task-043 | `aid-monitor` 1 |
| 508 | `site/scripts/__tests__/gen-reference.test.mjs` | task-032 | `aid-orchestrate` 1 |
| 509 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-032 | `aid-orchestrate` 4 |
| 510 | `site/scripts/__tests__/skills-groups.test.mjs` | task-032 | `aid-orchestrate` 10 |
| 511 | `site/scripts/__tests__/skills-render-index.test.mjs` | task-032 | `aid-orchestrate` 4 |
| 512 | `tests/cost-baseline.tsv` | task-032 | `aid-orchestrate` 5 |
| 513 | `tests/canonical/test-aid-migrate.sh` | task-040 | `aid-plan` 2 |
| 514 | `tests/canonical/test-multitool-isolation.sh` | task-040 | `aid-plan` 4 |
| 515 | `tests/windows/Test-AidInstaller.ps1` | task-040 | `aid-plan` 4 |
| 516 | `tests/canonical/test-review-path-audit.sh` | task-040 | `aid-plan` 2 |
| 517 | `tests/canonical/test-prototype-family-scaffold.sh` | task-044 | `aid-prototype` 54, `aid-review` 1, `aid-test` 4 |
| 518 | `site/scripts/__tests__/gen-skills.test.mjs` | task-043 | `aid-read-ticket` 4 |
| 519 | `site/scripts/__tests__/skills-render-value.test.mjs` | task-043 | `aid-read-ticket` 6 |
| 520 | `site/scripts/__tests__/skills-render-page.test.mjs` | task-043 | `aid-read-ticket` 2 |
| 521 | `tests/canonical/test-connector-consumption-linkage.sh` | task-043 | `aid-read-ticket` 1 |
| 522 | `tests/canonical/test-ticket-retirement-structural.sh` | task-044 | `aid-report` 3, `aid-research` 10, `aid-review` 12 |
| 523 | `tests/canonical/fixtures/actback-task/data-ml.tsv` | task-044 | `aid-research` 4 |
| 524 | `tests/canonical/fixtures/actback-task/design.tsv` | task-044 | `aid-research` 3 |
| 525 | `tests/canonical/fixtures/actback-task/docset-check.tsv` | task-044 | `aid-research` 5 |
| 526 | `tests/canonical/fixtures/actback-task/docset-component.tsv` | task-044 | `aid-research` 2 |
| 527 | `tests/canonical/fixtures/actback-task/docset-contract.tsv` | task-044 | `aid-research` 2 |
| 528 | `tests/canonical/fixtures/actback-task/docset-endpoint.tsv` | task-044 | `aid-research` 1 |
| 529 | `tests/canonical/fixtures/actback-task/docset-feature.tsv` | task-044 | `aid-research` 1 |
| 530 | `tests/canonical/fixtures/actback-task/docset-module.tsv` | task-044 | `aid-research` 2 |
| 531 | `tests/canonical/fixtures/actback-task/docset-optin.tsv` | task-044 | `aid-research` 1 |
| 532 | `tests/canonical/fixtures/dual-intent/content/doc-set.tsv` | task-044 | `aid-research` 6 |
| 533 | `tests/canonical/fixtures/dual-intent/content/good-kb/authoring-conventions.md` | task-044 | `aid-research` 1 |
| 534 | `tests/canonical/fixtures/dual-intent/content/good-kb/content-inventory.md` | task-044 | `aid-research` 1 |
| 535 | `tests/canonical/fixtures/dual-intent/content/good-kb/content-map.md` | task-044 | `aid-research` 1 |
| 536 | `tests/canonical/fixtures/dual-intent/content/good-kb/content-model.md` | task-044 | `aid-research` 1 |
| 537 | `tests/canonical/fixtures/dual-intent/content/good-kb/decisions.md` | task-044 | `aid-research` 1 |
| 538 | `tests/canonical/fixtures/dual-intent/content/good-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 539 | `tests/canonical/fixtures/dual-intent/content/shallow-kb/authoring-conventions.md` | task-044 | `aid-research` 1 |
| 540 | `tests/canonical/fixtures/dual-intent/content/shallow-kb/content-inventory.md` | task-044 | `aid-research` 1 |
| 541 | `tests/canonical/fixtures/dual-intent/content/shallow-kb/content-map.md` | task-044 | `aid-research` 1 |
| 542 | `tests/canonical/fixtures/dual-intent/content/shallow-kb/content-model.md` | task-044 | `aid-research` 1 |
| 543 | `tests/canonical/fixtures/dual-intent/content/shallow-kb/decisions.md` | task-044 | `aid-research` 1 |
| 544 | `tests/canonical/fixtures/dual-intent/content/shallow-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 545 | `tests/canonical/fixtures/dual-intent/content/wrong-kb/authoring-conventions.md` | task-044 | `aid-research` 1 |
| 546 | `tests/canonical/fixtures/dual-intent/content/wrong-kb/content-inventory.md` | task-044 | `aid-research` 1 |
| 547 | `tests/canonical/fixtures/dual-intent/content/wrong-kb/content-map.md` | task-044 | `aid-research` 1 |
| 548 | `tests/canonical/fixtures/dual-intent/content/wrong-kb/content-model.md` | task-044 | `aid-research` 1 |
| 549 | `tests/canonical/fixtures/dual-intent/content/wrong-kb/decisions.md` | task-044 | `aid-research` 1 |
| 550 | `tests/canonical/fixtures/dual-intent/content/wrong-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 551 | `tests/canonical/fixtures/dual-intent/data-ml/doc-set.tsv` | task-044 | `aid-research` 6 |
| 552 | `tests/canonical/fixtures/dual-intent/data-ml/good-kb/coding-standards.md` | task-044 | `aid-research` 1 |
| 553 | `tests/canonical/fixtures/dual-intent/data-ml/good-kb/data-pipeline.md` | task-044 | `aid-research` 1 |
| 554 | `tests/canonical/fixtures/dual-intent/data-ml/good-kb/data-schemas.md` | task-044 | `aid-research` 1 |
| 555 | `tests/canonical/fixtures/dual-intent/data-ml/good-kb/decisions.md` | task-044 | `aid-research` 1 |
| 556 | `tests/canonical/fixtures/dual-intent/data-ml/good-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 557 | `tests/canonical/fixtures/dual-intent/data-ml/good-kb/model-cards.md` | task-044 | `aid-research` 1 |
| 558 | `tests/canonical/fixtures/dual-intent/data-ml/shallow-kb/coding-standards.md` | task-044 | `aid-research` 1 |
| 559 | `tests/canonical/fixtures/dual-intent/data-ml/shallow-kb/data-pipeline.md` | task-044 | `aid-research` 1 |
| 560 | `tests/canonical/fixtures/dual-intent/data-ml/shallow-kb/data-schemas.md` | task-044 | `aid-research` 1 |
| 561 | `tests/canonical/fixtures/dual-intent/data-ml/shallow-kb/decisions.md` | task-044 | `aid-research` 1 |
| 562 | `tests/canonical/fixtures/dual-intent/data-ml/shallow-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 563 | `tests/canonical/fixtures/dual-intent/data-ml/shallow-kb/model-cards.md` | task-044 | `aid-research` 1 |
| 564 | `tests/canonical/fixtures/dual-intent/data-ml/wrong-kb/coding-standards.md` | task-044 | `aid-research` 1 |
| 565 | `tests/canonical/fixtures/dual-intent/data-ml/wrong-kb/data-pipeline.md` | task-044 | `aid-research` 1 |
| 566 | `tests/canonical/fixtures/dual-intent/data-ml/wrong-kb/data-schemas.md` | task-044 | `aid-research` 1 |
| 567 | `tests/canonical/fixtures/dual-intent/data-ml/wrong-kb/decisions.md` | task-044 | `aid-research` 1 |
| 568 | `tests/canonical/fixtures/dual-intent/data-ml/wrong-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 569 | `tests/canonical/fixtures/dual-intent/data-ml/wrong-kb/model-cards.md` | task-044 | `aid-research` 1 |
| 570 | `tests/canonical/fixtures/dual-intent/design/doc-set.tsv` | task-044 | `aid-research` 6 |
| 571 | `tests/canonical/fixtures/dual-intent/design/good-kb/component-inventory.md` | task-044 | `aid-research` 1 |
| 572 | `tests/canonical/fixtures/dual-intent/design/good-kb/decisions.md` | task-044 | `aid-research` 1 |
| 573 | `tests/canonical/fixtures/dual-intent/design/good-kb/design-overview.md` | task-044 | `aid-research` 1 |
| 574 | `tests/canonical/fixtures/dual-intent/design/good-kb/design-principles.md` | task-044 | `aid-research` 1 |
| 575 | `tests/canonical/fixtures/dual-intent/design/good-kb/design-tokens.md` | task-044 | `aid-research` 1 |
| 576 | `tests/canonical/fixtures/dual-intent/design/good-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 577 | `tests/canonical/fixtures/dual-intent/design/shallow-kb/component-inventory.md` | task-044 | `aid-research` 1 |
| 578 | `tests/canonical/fixtures/dual-intent/design/shallow-kb/decisions.md` | task-044 | `aid-research` 1 |
| 579 | `tests/canonical/fixtures/dual-intent/design/shallow-kb/design-overview.md` | task-044 | `aid-research` 1 |
| 580 | `tests/canonical/fixtures/dual-intent/design/shallow-kb/design-principles.md` | task-044 | `aid-research` 1 |
| 581 | `tests/canonical/fixtures/dual-intent/design/shallow-kb/design-tokens.md` | task-044 | `aid-research` 1 |
| 582 | `tests/canonical/fixtures/dual-intent/design/shallow-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 583 | `tests/canonical/fixtures/dual-intent/design/wrong-kb/component-inventory.md` | task-044 | `aid-research` 1 |
| 584 | `tests/canonical/fixtures/dual-intent/design/wrong-kb/decisions.md` | task-044 | `aid-research` 1 |
| 585 | `tests/canonical/fixtures/dual-intent/design/wrong-kb/design-overview.md` | task-044 | `aid-research` 1 |
| 586 | `tests/canonical/fixtures/dual-intent/design/wrong-kb/design-principles.md` | task-044 | `aid-research` 1 |
| 587 | `tests/canonical/fixtures/dual-intent/design/wrong-kb/design-tokens.md` | task-044 | `aid-research` 1 |
| 588 | `tests/canonical/fixtures/dual-intent/design/wrong-kb/domain-glossary.md` | task-044 | `aid-research` 1 |
| 589 | `tests/canonical/fixtures/kb-essence/actback/representative-task-fixture/doc-set.tsv` | task-044 | `aid-research` 4 |
| 590 | `tests/canonical/test-actback-task.sh` | task-044 | `aid-research` 3 |
| 591 | `tests/canonical/test-change-refactor-family-scaffold.sh` | task-044 | `aid-research` 2, `aid-review` 3, `aid-test` 1 |
| 592 | `tests/canonical/test-connector-consumption-linkage.sh` | task-044 | `aid-research` 1 |
| 593 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-044 | `aid-research` 3 |
| 594 | `tests/canonical/test-discovery-doc-ownership.sh` | task-044 | `aid-research` 39 |
| 595 | `tests/canonical/test-doc-set-mapping.sh` | task-044 | `aid-research` 56 |
| 596 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-044 | `aid-research` 14 |
| 597 | `tests/canonical/test-doc-set-read.sh` | task-044 | `aid-research` 44 |
| 598 | `tests/canonical/test-grade-summary.sh` | task-044 | `aid-research` 5 |
| 599 | `tests/canonical/test-update-kb-scope-fidelity.sh` | task-044 | `aid-research` 2 |
| 600 | `site/scripts/__tests__/flow-facade.test.mjs` | task-044 | `aid-review` 20, `aid-test` 1 |
| 601 | `site/scripts/__tests__/flow-graph.test.mjs` | task-044 | `aid-review` 7, `aid-test` 70 |
| 602 | `site/scripts/__tests__/provenance.test.mjs` | task-044 | `aid-review` 8, `aid-test` 2 |
| 603 | `site/scripts/__tests__/skills-render-page.test.mjs` | task-044 | `aid-review` 8, `aid-test` 10 |
| 604 | `tests/canonical/test-review-path-audit.sh` | task-044 | `aid-review` 10 |
| 605 | `dashboard/reader/tests/test_work003_state_schema.py` | task-044 | `aid-review` 1 |
| 606 | `site/scripts/__tests__/flow-classify.test.mjs` | task-044 | `aid-review` 6, `aid-test` 12 |
| 607 | `site/scripts/__tests__/provenance-appender.test.mjs` | task-044 | `aid-review` 12 |
| 608 | `site/scripts/__tests__/skills-body.test.mjs` | task-044 | `aid-review` 3 |
| 609 | `tests/README.md` | task-044 | `aid-review` 1 |
| 610 | `tests/canonical/test-aid-update-dry-run-plan.sh` | task-044 | `aid-review` 13 |
| 611 | `tests/canonical/test-artifact-discipline.sh` | task-044 | `aid-review` 1 |
| 612 | `tests/canonical/test-conversation-runner.sh` | task-044 | `aid-review` 1 |
| 613 | `tests/canonical/test-cost-meter.sh` | task-044 | `aid-review` 5 |
| 614 | `tests/canonical/test-criterion-oracles.sh` | task-044 | `aid-review` 2 |
| 615 | `tests/canonical/test-cutover-no-dangling.sh` | task-044 | `aid-review` 1 |
| 616 | `tests/canonical/test-describe-full-only.sh` | task-044 | `aid-review` 1 |
| 617 | `tests/canonical/test-expectations-single-source.sh` | task-044 | `aid-review` 11 |
| 618 | `tests/canonical/test-fix-family-scaffold.sh` | task-044 | `aid-review` 1, `aid-test` 2 |
| 619 | `tests/canonical/test-severity-why-line.sh` | task-044 | `aid-review` 1 |
| 620 | `tests/canonical/test-test-experiment-family-scaffold.sh` | task-044 | `aid-review` 1, `aid-test` 38 |
| 621 | `tests/conversation/run.py` | task-044 | `aid-review` 2 |
| 622 | `tests/cost-meter.py` | task-044 | `aid-review` 1 |
| 623 | `tests/canonical/test-connector-set-unset-lifecycle.sh` | task-043 | `aid-set-connector` 8, `aid-unset-connector` 5 |
| 624 | `tests/canonical/test-write-connector.sh` | task-043 | `aid-set-connector` 1, `aid-unset-connector` 1 |
| 625 | `tests/canonical/test-ticket-retirement-structural.sh` | task-039 | `aid-specify` 6 |
| 626 | `dashboard/reader/tests/test_fixtures.py` | task-039 | `aid-specify` 1 |
| 627 | `dashboard/reader/tests/test_flattened_layout_parity.py` | task-039 | `aid-specify` 1 |
| 628 | `dashboard/reader/tests/test_reader.py` | task-039 | `aid-specify` 1 |
| 629 | `dashboard/reader/tests/test_task014_fixtures.py` | task-039 | `aid-specify` 2 |
| 630 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-002-paused/STATE.md` | task-039 | `aid-specify` 1 |
| 631 | `dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-002-paused/STATE.yml` | task-039 | `aid-specify` 1 |
| 632 | `tests/canonical/test-connector-consumption-linkage.sh` | task-039 | `aid-specify` 1 |
| 633 | `tests/conversation/fixtures/ticket-mid-work/.aid/works/work-001-retry-policy/STATE.yml` | task-039 | `aid-specify` 1 |
| 634 | `tests/conversation/samples/feature-001/001-15-no-kb-offers-preparation.md` | task-039 | `aid-specify` 1 |
| 635 | `tests/canonical/test-grade-summary.sh` | task-042 | `aid-summarize` 4 |
| 636 | `tests/canonical/test-guardrails-d012.sh` | task-042 | `aid-summarize` 2 |
| 637 | `tests/canonical/test-ledger-isolation.sh` | task-042 | `aid-summarize` 2 |
| 638 | `tests/canonical/test-shared-prune.sh` | task-042 | `aid-summarize` 1 |
| 639 | `site/scripts/__tests__/flow-facade.test.mjs` | task-042 | `aid-summarize` 1 |
| 640 | `site/scripts/__tests__/flow-render-mermaid.test.mjs` | task-044 | `aid-test` 1 |
| 641 | `site/scripts/__tests__/flow-validate.test.mjs` | task-044 | `aid-test` 18 |
| 642 | `site/scripts/__tests__/provenance-render-list.test.mjs` | task-044 | `aid-test` 7 |
| 643 | `site/scripts/__tests__/skills-discover.test.mjs` | task-044 | `aid-test` 55 |
| 644 | `dashboard/server/tests/test_reader_task069.mjs` | task-044 | `aid-test` 1 |
| 645 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | task-044 | `aid-test` 1, `aid-update-document` 1 |
| 646 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-044 | `aid-test` 25 |
| 647 | `site/scripts/__tests__/skills-summary.test.mjs` | task-044 | `aid-test` 10 |
| 648 | `tests/canonical/test-migrate-kb-frontmatter.sh` | task-044 | `aid-test` 1 |
| 649 | `tests/canonical/test-release-install-e2e.sh` | task-044 | `aid-test` 3 |
| 650 | `tests/canonical/test-update-kb-scope-fidelity.sh` | task-042 | `aid-update-kb` 11 |
| 651 | `site/scripts/__tests__/gen-skills.test.mjs` | task-042 | `aid-update-kb` 9 |
| 652 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | history, left as is | `aid-create` 7, `aid-document` 6, `aid-document-architecture` 3, `aid-document-changelog` 2, `aid-test-data-quality` 1, `aid-test-performance` 3, `aid-test-security` 17 |
| 653 | `dashboard/reader/tests/test_work003_state_schema.py` | history, left as is | `aid-create` 4, `aid-create-api` 2, `aid-create-data-model` 1, `aid-refactor` 9 |
| 654 | `site/scripts/__tests__/flow-classify.test.mjs` | history, left as is | `aid-create` 3, `aid-test-security` 6 |
| 655 | `site/scripts/__tests__/flow-compose.test.mjs` | history, left as is | `aid-create` 14, `aid-create-api` 10, `aid-document` 1, `aid-fix` 4, `aid-test-performance` 1, `aid-test-security` 4 |
| 656 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | history, left as is | `aid-create` 12, `aid-create-api` 12, `aid-fix` 5 |
| 657 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | history, left as is | `aid-create` 2, `aid-update` 5 |
| 658 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | history, left as is | `aid-create` 5, `aid-deprecate` 1, `aid-document` 2, `aid-document-runbook` 1, `aid-fix` 3, `aid-test-security` 1, `aid-update` 4, `aid-update-api` 1 |
| 659 | `site/scripts/__tests__/flow-facade.test.mjs` | history, left as is | `aid-create` 8, `aid-document` 4, `aid-document-architecture` 4, `aid-test-security` 1 |
| 660 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | history, left as is | `aid-create` 27, `aid-create-api` 23, `aid-document` 1, `aid-fix` 5, `aid-test-security` 18 |
| 661 | `site/scripts/__tests__/gen-reference.test.mjs` | history, left as is | `aid-create` 1, `aid-update` 2 |
| 662 | `site/scripts/__tests__/provenance-appender.test.mjs` | history, left as is | `aid-create` 6, `aid-create-api` 6 |
| 663 | `site/scripts/__tests__/provenance-deep-link.test.mjs` | history, left as is | `aid-create` 1, `aid-create-api` 1 |
| 664 | `site/scripts/__tests__/skills-body.test.mjs` | history, left as is | `aid-create` 1, `aid-create-api` 1, `aid-fix` 3 |
| 665 | `site/scripts/__tests__/skills-paths.test.mjs` | history, left as is | `aid-create` 6, `aid-create-api` 6 |
| 666 | `site/scripts/__tests__/skills-render-page.test.mjs` | history, left as is | `aid-create` 2, `aid-create-api` 2 |
| 667 | `tests/canonical/test-change-refactor-family-scaffold.sh` | history, left as is | `aid-create` 2, `aid-deprecate` 16, `aid-document` 2, `aid-fix` 5, `aid-migrate` 18, `aid-refactor` 37, `aid-remove` 27, `aid-update` 41, `aid-update-api` 22, `aid-update-data-model` 9 |
| 668 | `tests/canonical/test-create-family-scaffold.sh` | history, left as is | `aid-create` 39, `aid-create-api` 22, `aid-create-dashboard` 3, `aid-create-data-model` 11, `aid-experiment` 2, `aid-update` 2 |
| 669 | `tests/canonical/test-document-family-scaffold.sh` | history, left as is | `aid-create` 3, `aid-create-diagram` 1, `aid-document` 57, `aid-document-architecture` 4, `aid-document-changelog` 4, `aid-document-decision` 20, `aid-document-guideline` 4, `aid-document-runbook` 16, `aid-document-standard` 4, `aid-document-tutorial` 4, `aid-refactor` 1, `aid-update` 3, `aid-update-infra` 2 |
| 670 | `tests/canonical/test-prototype-family-scaffold.sh` | history, left as is | `aid-create` 6, `aid-experiment` 4, `aid-prototype-ui` 27, `aid-update` 6 |
| 671 | `tests/canonical/test-review-path-audit.sh` | history, left as is | `aid-create` 2 |
| 672 | `tests/canonical/test-test-experiment-family-scaffold.sh` | history, left as is | `aid-create` 5, `aid-create-test` 1, `aid-experiment` 20, `aid-fix` 15, `aid-test-data-quality` 2, `aid-test-performance` 2, `aid-test-security` 17, `aid-update` 2, `aid-update-test` 1 |
| 673 | `tests/canonical/test-ticket-retirement-structural.sh` | history, left as is | `aid-create` 9, `aid-update` 14 |
| 674 | `tests/canonical/test-ticket-skills-structural.sh` | history, left as is | `aid-create` 35, `aid-update` 32 |
| 675 | `tests/cost-baseline.tsv` | history, left as is | `aid-create` 120, `aid-create-api` 5, `aid-create-cli` 5, `aid-create-config` 5, `aid-create-dashboard` 5, `aid-create-data-model` 5, `aid-create-data-pipeline` 5, `aid-create-diagram` 5, `aid-create-infra` 5, `aid-create-integration` 5, `aid-create-job` 5, `aid-create-messaging` 5, `aid-create-test` 10, `aid-create-theme` 5, `aid-create-ui` 5, `aid-deprecate` 5, `aid-document` 40, `aid-document-architecture` 5, `aid-document-changelog` 5, `aid-document-decision` 5, `aid-document-guideline` 5, `aid-document-runbook` 5, `aid-document-standard` 5, `aid-document-tutorial` 5, `aid-experiment` 5, `aid-fix` 5, `aid-migrate` 5, `aid-prototype-ui` 5, `aid-refactor` 5, `aid-remove` 5, `aid-test-data-quality` 5, `aid-test-performance` 5, `aid-test-security` 5, `aid-update` 120, `aid-update-api` 5, `aid-update-cli` 5, `aid-update-config` 5, `aid-update-dashboard` 5, `aid-update-data-model` 5, `aid-update-data-pipeline` 5, `aid-update-infra` 5, `aid-update-integration` 5, `aid-update-job` 5, `aid-update-messaging` 5, `aid-update-test` 10, `aid-update-theme` 5, `aid-update-ui` 5 |
| 676 | `tests/coverage-baseline.tsv` | history, left as is | `aid-create` 36, `aid-migrate` 273, `aid-refactor` 1, `aid-update` 29 |
| 677 | `tests/canonical/test-fix-family-scaffold.sh` | history, left as is | `aid-document` 1, `aid-document-runbook` 1, `aid-fix` 28, `aid-refactor` 1, `aid-test-security` 2, `aid-update` 4, `aid-update-infra` 3 |
| 678 | `tests/canonical/test-multitool-isolation.sh` | history, left as is | `aid-fix` 3 |
| 679 | `tests/windows/Test-AidInstaller.ps1` | history, left as is | `aid-fix` 2 |
| 680 | `dashboard/reader/tests/test_declared_path_three_way_parity.py` | history, left as is | `aid-fix` 2 |
| 681 | `dashboard/server/tests/test_server_node.mjs` | history, left as is | `aid-fix` 2 |
| 682 | `dashboard/server/tests/test_server_py.py` | history, left as is | `aid-fix` 2 |
| 683 | `site/scripts/__tests__/flow-render-mermaid.test.mjs` | history, left as is | `aid-fix` 2 |
| 684 | `site/scripts/__tests__/provenance-render-list.test.mjs` | history, left as is | `aid-fix` 1 |
| 685 | `site/scripts/__tests__/skill-node-panel-panel.test.mjs` | history, left as is | `aid-fix` 1 |
| 686 | `site/scripts/__tests__/skills-catalog.test.mjs` | history, left as is | `aid-fix` 4 |
| 687 | `site/src/lib/__tests__/skill-node-panel.dom.test.ts` | history, left as is | `aid-fix` 1 |
| 688 | `tests/canonical/test-connector-consumption-linkage.sh` | history, left as is | `aid-fix` 2 |
| 689 | `tests/conversation/samples/feature-001/001-01-one-match.md` | history, left as is | `aid-fix` 1 |
| 690 | `tests/coverage-accepted-removals.tsv` | history, left as is | `aid-fix` 1, `aid-migrate` 200 |
| 691 | `dashboard/reader/tests/test_task011_golden_master.py` | history, left as is | `aid-migrate` 2, `aid-refactor` 1 |
| 692 | `tests/canonical/test-aid-migrate-trigger.sh` | history, left as is | `aid-migrate` 2 |
| 693 | `tests/canonical/test-aid-migrate.sh` | history, left as is | `aid-migrate` 2 |
| 694 | `tests/canonical/test-release-migrate-smoke.sh` | history, left as is | `aid-migrate` 4 |
| 695 | `tests/coverage-parity.sh` | history, left as is | `aid-migrate` 3 |
| 696 | `tests/coverage-rehome-allowlist.tsv` | history, left as is | `aid-migrate` 3, `aid-update` 1 |
| 697 | `tests/run-all.sh` | history, left as is | `aid-migrate` 1 |
| 698 | `dashboard/reader/tests/test_flattened_layout_parity.py` | history, left as is | `aid-refactor` 1 |
| 699 | `tests/canonical/fixtures/state-yaml-conformance/shape-s2-mapping-of-scalars.expected.json` | history, left as is | `aid-refactor` 1 |
| 700 | `tests/canonical/fixtures/state-yaml-conformance/shape-s2-mapping-of-scalars.yml` | history, left as is | `aid-refactor` 1 |
| 701 | `tests/canonical/test-task-state-transitions.sh` | history, left as is | `aid-refactor` 1 |
| 702 | `tests/conversation/samples/feature-001/001-14-refactor-is-new-capability.md` | history, left as is | `aid-refactor` 1 |
| 703 | `dashboard/server/tests/test_task017_registry_tooling_round_trips.py` | history, left as is | `aid-update` 1 |
| 704 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | history, left as is | `aid-update` 3 |
| 705 | `site/scripts/__tests__/flow-graph.test.mjs` | history, left as is | `aid-update` 3 |
| 706 | `site/scripts/__tests__/gen-skills.test.mjs` | history, left as is | `aid-update` 9 |
| 707 | `tests/canonical/test-f010-governance-guards.sh` | history, left as is | `aid-update` 4 |
| 708 | `tests/canonical/test-update-kb-scope-fidelity.sh` | history, left as is | `aid-update` 11 |

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
| 26 | `tests/canonical/test-pipeline-status-walkthrough.sh:346` | `if grep -qF "writeback-state.sh --pipeline --field Phase --value ${expected_phase}" "$sfile" 2>/d...` | writer-fed value | task-039 (B1 for aid-define, aid-specify) |
| 26 | `tests/canonical/test-pipeline-status-walkthrough.sh:346` | `if grep -qF "writeback-state.sh --pipeline --field Phase --value ${expected_phase}" "$sfile" 2>/d...` | writer-fed value | task-040 (B1 for aid-plan, aid-detail, aid-execute) |
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

Notes: line 346 of `test-pipeline-status-walkthrough.sh` is one hit with two owners, one row for each B1 group (task-039, task-040), because the loop over `aid-define aid-specify aid-plan aid-detail aid-execute` checks each skill's own expected phase; task-040 depends on task-039 (the B1 table is edited by both). `test-diagram-content.sh` lists the phase names as diagram text, which the spec leaves as it is. The golden JSON fixtures are outputs and change to `Building`.

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
git grep -nE "'aid-[a-z-]+'|canonical/(skills|aid/templates)/" -- site/scripts/__tests__ site/src/lib/__tests__
```

Hits: 835 lines in 39 site test files, grouped below per (test file, target, owner). A target is a real skill or template file, or a fixture name that names no real file (`aid-fixture`, `aid-parent`, `door-skill` and the like). Owner = the owner of the real target (the task that changes it); a target no task changes, and a fixture name, is `history, left as is` (Delta D9). `flow-advance.test.mjs` is also a task-024 file for its new words.

| # | Site test | Target | Owner | Hits |
|---|---|---|---|---|
| 1 | `site/scripts/__tests__/flow-advance.test.mjs` | `canonical/skills/aid-fixture/ (no such skill; fixture path)` | history, left as is | 4 |
| 2 | `site/scripts/__tests__/flow-advance.test.mjs` | `canonical/skills/aid-update-kb/SKILL.md` | task-042 | 1 |
| 3 | `site/scripts/__tests__/flow-advance.test.mjs` | `canonical/skills/aid-discover/SKILL.md` | task-041 | 1 |
| 4 | `site/scripts/__tests__/flow-advance.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 4 |
| 5 | `site/scripts/__tests__/flow-advance.test.mjs` | `skill aid-test` | task-044 | 1 |
| 6 | `site/scripts/__tests__/flow-classify.test.mjs` | `skill aid-review` | task-044 | 2 |
| 7 | `site/scripts/__tests__/flow-classify.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 1 |
| 8 | `site/scripts/__tests__/flow-classify.test.mjs` | `canonical/skills/aid-parent/ (no such skill; fixture path)` | history, left as is | 5 |
| 9 | `site/scripts/__tests__/flow-classify.test.mjs` | `canonical/skills/aid-first/ (no such skill; fixture path)` | history, left as is | 1 |
| 10 | `site/scripts/__tests__/flow-classify.test.mjs` | `canonical/skills/aid-second/ (no such skill; fixture path)` | history, left as is | 1 |
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
| 35 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-deploy` | task-043 | 1 |
| 36 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-discover` | task-041 | 1 |
| 37 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-detail` | task-040 | 1 |
| 38 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-describe` | task-038 | 10 |
| 39 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-define` | task-039 | 4 |
| 40 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-plan` | task-040 | 1 |
| 41 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-specify` | task-039 | 2 |
| 42 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-execute` | task-040 | 3 |
| 43 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-housekeep` | task-042 | 1 |
| 44 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-monitor` | task-043 | 1 |
| 45 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-summarize` | task-042 | 1 |
| 46 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `skill aid-update-kb` | task-042 | 2 |
| 47 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `name aid-keyword-states (no such skill; fixture name)` | history, left as is | 1 |
| 48 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `canonical/skills/aid-describe/SKILL.md` | task-038 | 2 |
| 49 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | `skill aid-create-api` | history, left as is | 3 |
| 50 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | `skill aid-fix` | history, left as is | 1 |
| 51 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | `canonical/skills/aid-create-api/SKILL.md` | history, left as is | 3 |
| 52 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | `canonical/aid/templates/shortcut-engine.md` | task-037 | 2 |
| 53 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | `name aid-synthetic-long (no such skill; fixture name)` | history, left as is | 1 |
| 54 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | `canonical/skills/aid-synthetic-long/ (no such skill; fixture path)` | history, left as is | 1 |
| 55 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `skill aid-review` | task-044 | 2 |
| 56 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `skill aid-test` | task-044 | 2 |
| 57 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `skill aid-create-document` | task-044 | 1 |
| 58 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `skill aid-design` | task-034 | 1 |
| 59 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `skill aid-prototype` | task-044 | 1 |
| 60 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `skill aid-report` | task-044 | 1 |
| 61 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `skill aid-research` | task-044 | 1 |
| 62 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | `skill aid-update-document` | task-044 | 1 |
| 63 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `canonical/skills/test-fixture/ (no such skill; fixture path)` | history, left as is | 1 |
| 64 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-create-ticket` | task-043 | 3 |
| 65 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-read-ticket` | task-043 | 1 |
| 66 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-update-ticket` | task-043 | 1 |
| 67 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-config` | task-043 | 4 |
| 68 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-ask` | task-042 | 2 |
| 69 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-create` | history, left as is | 1 |
| 70 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-update-api` | history, left as is | 1 |
| 71 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-deprecate` | history, left as is | 1 |
| 72 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-document` | history, left as is | 1 |
| 73 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-document-runbook` | history, left as is | 1 |
| 74 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-test-security` | history, left as is | 1 |
| 75 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `name aid-fixture (no such skill; fixture name)` | history, left as is | 1 |
| 76 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `canonical/skills/aid-fixture/ (no such skill; fixture path)` | history, left as is | 1 |
| 77 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-set-connector` | task-043 | 1 |
| 78 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `skill aid-unset-connector` | task-043 | 1 |
| 79 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | `canonical/skills/aid-config/SKILL.md` | task-043 | 1 |
| 80 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/fake-cap-2/ (no such skill; fixture path)` | history, left as is | 1 |
| 81 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/fake-cap-3/ (no such skill; fixture path)` | history, left as is | 1 |
| 82 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/fake-cap-4/ (no such skill; fixture path)` | history, left as is | 1 |
| 83 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/fake-cap-5/ (no such skill; fixture path)` | history, left as is | 1 |
| 84 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `skill aid-test-security` | history, left as is | 5 |
| 85 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `skill aid-test-performance` | history, left as is | 2 |
| 86 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `skill aid-test` | task-044 | 12 |
| 87 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 8 |
| 88 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/aid-create/SKILL.md` | history, left as is | 1 |
| 89 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/aid-test-security/SKILL.md` | history, left as is | 1 |
| 90 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `skill aid-document-architecture` | history, left as is | 3 |
| 91 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `skill aid-document-changelog` | history, left as is | 2 |
| 92 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `skill aid-create-document` | task-044 | 3 |
| 93 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `name aid-alias-synth (no such skill; fixture name)` | history, left as is | 1 |
| 94 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `name aid-neither-synth (no such skill; fixture name)` | history, left as is | 1 |
| 95 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `name aid-approx-parent (no such skill; fixture name)` | history, left as is | 2 |
| 96 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/aid-approx-parent/ (no such skill; fixture path)` | history, left as is | 1 |
| 97 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `name aid-cycle-synth (no such skill; fixture name)` | history, left as is | 1 |
| 98 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/aid-cycle-synth/ (no such skill; fixture path)` | history, left as is | 1 |
| 99 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `name aid-cap-synth (no such skill; fixture name)` | history, left as is | 1 |
| 100 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `canonical/skills/fake-cap-1/ (no such skill; fixture path)` | history, left as is | 1 |
| 101 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `skill aid-test-data-quality` | history, left as is | 1 |
| 102 | `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `skill aid-document` | history, left as is | 1 |
| 103 | `site/scripts/__tests__/flow-facade.test.mjs` | `canonical/skills/aid-review/SKILL.md` | task-044 | 1 |
| 104 | `site/scripts/__tests__/flow-facade.test.mjs` | `skill aid-describe` | task-038 | 6 |
| 105 | `site/scripts/__tests__/flow-facade.test.mjs` | `skill aid-review` | task-044 | 13 |
| 106 | `site/scripts/__tests__/flow-facade.test.mjs` | `skill aid-config` | task-043 | 11 |
| 107 | `site/scripts/__tests__/flow-facade.test.mjs` | `skill aid-document-architecture` | history, left as is | 2 |
| 108 | `site/scripts/__tests__/flow-facade.test.mjs` | `skill aid-create` | history, left as is | 4 |
| 109 | `site/scripts/__tests__/flow-facade.test.mjs` | `skill aid-summarize` | task-042 | 1 |
| 110 | `site/scripts/__tests__/flow-facade.test.mjs` | `skill aid-test-security` | history, left as is | 1 |
| 111 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/aid/templates/shortcut-engine.md` | task-037 | 3 |
| 112 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/aid-create-api/SKILL.md` | history, left as is | 1 |
| 113 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/aid-fix/SKILL.md` | history, left as is | 1 |
| 114 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/aid-test-quality/ (no such skill; fixture path)` | history, left as is | 1 |
| 115 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/aid-document/SKILL.md` | history, left as is | 1 |
| 116 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/aid-add/ (no such skill; fixture path)` | history, left as is | 1 |
| 117 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `skill aid-create` | history, left as is | 1 |
| 118 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/aid-unknown/ (no such skill; fixture path)` | history, left as is | 2 |
| 119 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/purity-doorway/ (no such skill; fixture path)` | history, left as is | 1 |
| 120 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/w1-doorway/ (no such skill; fixture path)` | history, left as is | 1 |
| 121 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `canonical/skills/w5-doorway/ (no such skill; fixture path)` | history, left as is | 1 |
| 122 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `skill aid-create-api` | history, left as is | 12 |
| 123 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `skill aid-fix` | history, left as is | 1 |
| 124 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `skill aid-test-security` | history, left as is | 10 |
| 125 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `skill aid-test` | task-044 | 1 |
| 126 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 15 |
| 127 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/aid-foo/ (no such skill; fixture path)` | history, left as is | 2 |
| 128 | `site/scripts/__tests__/flow-graph.test.mjs` | `skill aid-test` | task-044 | 50 |
| 129 | `site/scripts/__tests__/flow-graph.test.mjs` | `name aid-example (no such skill; fixture name)` | history, left as is | 6 |
| 130 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/aid-example/ (no such skill; fixture path)` | history, left as is | 2 |
| 131 | `site/scripts/__tests__/flow-graph.test.mjs` | `name aid-foo (no such skill; fixture name)` | history, left as is | 8 |
| 132 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/foo/ (no such skill; fixture path)` | history, left as is | 4 |
| 133 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/x/ (no such skill; fixture path)` | history, left as is | 1 |
| 134 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/aid-review/SKILL.md` | task-044 | 2 |
| 135 | `site/scripts/__tests__/flow-graph.test.mjs` | `name aid-no-exit (no such skill; fixture name)` | history, left as is | 1 |
| 136 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/aid-base/ (no such skill; fixture path)` | history, left as is | 6 |
| 137 | `site/scripts/__tests__/flow-graph.test.mjs` | `name aid-base (no such skill; fixture name)` | history, left as is | 2 |
| 138 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/aid-beta/ (no such skill; fixture path)` | history, left as is | 1 |
| 139 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/skills/aid-alpha/ (no such skill; fixture path)` | history, left as is | 1 |
| 140 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/aid/templates/shortcut-engine.md` | task-037 | 1 |
| 141 | `site/scripts/__tests__/flow-graph.test.mjs` | `canonical/aid/templates/shortcut-engine.md.` | history, left as is | 1 |
| 142 | `site/scripts/__tests__/flow-graph.test.mjs` | `skill aid-housekeep` | task-042 | 1 |
| 143 | `site/scripts/__tests__/flow-graph.test.mjs` | `skill aid-update-kb` | task-042 | 1 |
| 144 | `site/scripts/__tests__/flow-graph.test.mjs` | `skill aid-describe` | task-038 | 1 |
| 145 | `site/scripts/__tests__/flow-graph.test.mjs` | `skill aid-review` | task-044 | 1 |
| 146 | `site/scripts/__tests__/flow-render-mermaid.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 1 |
| 147 | `site/scripts/__tests__/flow-render-mermaid.test.mjs` | `name aid-fixture (no such skill; fixture name)` | history, left as is | 1 |
| 148 | `site/scripts/__tests__/flow-render-mermaid.test.mjs` | `canonical/skills/aid-fixture/ (no such skill; fixture path)` | history, left as is | 1 |
| 149 | `site/scripts/__tests__/flow-validate.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 6 |
| 150 | `site/scripts/__tests__/flow-validate.test.mjs` | `skill aid-test` | task-044 | 1 |
| 151 | `site/scripts/__tests__/flow-validate.test.mjs` | `name aid-x (no such skill; fixture name)` | history, left as is | 5 |
| 152 | `site/scripts/__tests__/flow-validate.test.mjs` | `canonical/skills/aid-x/ (no such skill; fixture path)` | history, left as is | 5 |
| 153 | `site/scripts/__tests__/gen-reference.test.mjs` | `canonical/aid/templates/shortcut-engine.md` | task-037 | 1 |
| 154 | `site/scripts/__tests__/gen-reference.test.mjs` | `canonical/aid/templates/shortcut-catalog.yml` | history, left as is | 1 |
| 155 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-discover` | task-041 | 1 |
| 156 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-config` | task-043 | 1 |
| 157 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-summarize` | task-042 | 1 |
| 158 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-describe` | task-038 | 1 |
| 159 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-define` | task-039 | 1 |
| 160 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-specify` | task-039 | 1 |
| 161 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-plan` | task-040 | 1 |
| 162 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-detail` | task-040 | 1 |
| 163 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-execute` | task-040 | 1 |
| 164 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-deploy` | task-043 | 1 |
| 165 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-monitor` | task-043 | 1 |
| 166 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-housekeep` | task-042 | 1 |
| 167 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-ask` | task-042 | 1 |
| 168 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-update-kb` | task-042 | 1 |
| 169 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-set-connector` | task-043 | 1 |
| 170 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-unset-connector` | task-043 | 1 |
| 171 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-create-ticket` | task-043 | 1 |
| 172 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-read-ticket` | task-043 | 1 |
| 173 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-update-ticket` | task-043 | 1 |
| 174 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-orchestrate` | task-032 | 1 |
| 175 | `site/scripts/__tests__/gen-reference.test.mjs` | `skill aid-chat` | task-043 | 1 |
| 176 | `site/scripts/__tests__/gen-reference.test.mjs` | `canonical/aid/templates/knowledge-base/` | history, left as is | 1 |
| 177 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `skill aid-plan` | task-040 | 1 |
| 178 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `skill aid-specify` | task-039 | 1 |
| 179 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `skill aid-detail` | task-040 | 1 |
| 180 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `skill aid-describe` | task-038 | 1 |
| 181 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `skill aid-define` | task-039 | 1 |
| 182 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `skill aid-orchestrate` | task-032 | 1 |
| 183 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `skill aid-deploy` | task-043 | 3 |
| 184 | `site/scripts/__tests__/gen-skills-index.test.mjs` | `skill aid-monitor` | task-043 | 3 |
| 185 | `site/scripts/__tests__/gen-skills.test.mjs` | `canonical/skills/some-dir-name/ (no such skill; fixture path)` | history, left as is | 1 |
| 186 | `site/scripts/__tests__/gen-skills.test.mjs` | `skill aid-read-ticket` | task-043 | 1 |
| 187 | `site/scripts/__tests__/gen-skills.test.mjs` | `canonical/skills/aid-read-ticket/SKILL.md` | task-043 | 1 |
| 188 | `site/scripts/__tests__/gen-skills.test.mjs` | `canonical/skills/*/ (no such skill; fixture path)` | history, left as is | 4 |
| 189 | `site/scripts/__tests__/gen-skills.test.mjs` | `canonical/aid/templates/shortcut-catalog.yml` | history, left as is | 4 |
| 190 | `site/scripts/__tests__/gen-skills.test.mjs` | `name aid-deleted (no such skill; fixture name)` | history, left as is | 4 |
| 191 | `site/scripts/__tests__/gen-skills.test.mjs` | `skill aid-update-kb` | task-042 | 8 |
| 192 | `site/scripts/__tests__/gen-skills.test.mjs` | `skill aid-execute` | task-040 | 1 |
| 193 | `site/scripts/__tests__/gen-skills.test.mjs` | `skill aid-discover` | task-041 | 1 |
| 194 | `site/scripts/__tests__/provenance-appender.test.mjs` | `canonical/aid/templates/shortcut-engine.md` | task-037 | 3 |
| 195 | `site/scripts/__tests__/provenance-appender.test.mjs` | `name aid-add-cli (no such skill; fixture name)` | history, left as is | 1 |
| 196 | `site/scripts/__tests__/provenance-appender.test.mjs` | `name aid-add-api (no such skill; fixture name)` | history, left as is | 3 |
| 197 | `site/scripts/__tests__/provenance-appender.test.mjs` | `skill aid-review` | task-044 | 9 |
| 198 | `site/scripts/__tests__/provenance-appender.test.mjs` | `skill aid-create-api` | history, left as is | 3 |
| 199 | `site/scripts/__tests__/provenance-appender.test.mjs` | `skill aid-ask` | task-042 | 3 |
| 200 | `site/scripts/__tests__/provenance-deep-link.test.mjs` | `canonical/skills/aid-foo/ (no such skill; fixture path)` | history, left as is | 5 |
| 201 | `site/scripts/__tests__/provenance-deep-link.test.mjs` | `canonical/skills/aid-bar/ (no such skill; fixture path)` | history, left as is | 1 |
| 202 | `site/scripts/__tests__/provenance-deep-link.test.mjs` | `canonical/skills/aid-baz/ (no such skill; fixture path)` | history, left as is | 2 |
| 203 | `site/scripts/__tests__/provenance-deep-link.test.mjs` | `canonical/skills/aid-create-api/SKILL.md` | history, left as is | 1 |
| 204 | `site/scripts/__tests__/provenance-render-list.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 7 |
| 205 | `site/scripts/__tests__/provenance-render-list.test.mjs` | `name aid-fixture (no such skill; fixture name)` | history, left as is | 1 |
| 206 | `site/scripts/__tests__/provenance-verify.test.mjs` | `canonical/skills/test-skill/ (no such skill; fixture path)` | history, left as is | 26 |
| 207 | `site/scripts/__tests__/provenance-verify.test.mjs` | `canonical/skills/nonexistent/ (no such skill; fixture path)` | history, left as is | 6 |
| 208 | `site/scripts/__tests__/provenance.test.mjs` | `skill aid-test` | task-044 | 2 |
| 209 | `site/scripts/__tests__/provenance.test.mjs` | `canonical/skills/aid-review/SKILL.md` | task-044 | 4 |
| 210 | `site/scripts/__tests__/provenance.test.mjs` | `canonical/skills/test-skill/ (no such skill; fixture path)` | history, left as is | 4 |
| 211 | `site/scripts/__tests__/provenance.test.mjs` | `canonical/skills/../ (no such skill; fixture path)` | history, left as is | 1 |
| 212 | `site/scripts/__tests__/provenance.test.mjs` | `canonical/skills/aid-ask/SKILL.md` | task-042 | 1 |
| 213 | `site/scripts/__tests__/provenance.test.mjs` | `skill aid-review` | task-044 | 1 |
| 214 | `site/scripts/__tests__/skill-counts.test.mjs` | `skill aid-ask` | task-042 | 1 |
| 215 | `site/scripts/__tests__/skill-node-panel-lifecycle.test.mjs` | `name aid-flow-data (no such skill; fixture name)` | history, left as is | 3 |
| 216 | `site/scripts/__tests__/skill-node-panel-lifecycle.test.mjs` | `name aid-node-panel (no such skill; fixture name)` | history, left as is | 1 |
| 217 | `site/scripts/__tests__/skill-node-panel-panel.test.mjs` | `name aid-fixture (no such skill; fixture name)` | history, left as is | 1 |
| 218 | `site/scripts/__tests__/skill-node-panel-panel.test.mjs` | `canonical/skills/a/ (no such skill; fixture path)` | history, left as is | 4 |
| 219 | `site/scripts/__tests__/skill-node-panel-panel.test.mjs` | `name aid-flow-data (no such skill; fixture name)` | history, left as is | 1 |
| 220 | `site/scripts/__tests__/skill-node-panel-panel.test.mjs` | `name aid-node-panel (no such skill; fixture name)` | history, left as is | 4 |
| 221 | `site/scripts/__tests__/skills-body.test.mjs` | `name aid-fixture (no such skill; fixture name)` | history, left as is | 3 |
| 222 | `site/scripts/__tests__/skills-body.test.mjs` | `skill aid-review` | task-044 | 2 |
| 223 | `site/scripts/__tests__/skills-body.test.mjs` | `name aid-multi (no such skill; fixture name)` | history, left as is | 2 |
| 224 | `site/scripts/__tests__/skills-body.test.mjs` | `skill aid-create-api` | history, left as is | 1 |
| 225 | `site/scripts/__tests__/skills-catalog.test.mjs` | `canonical/aid/templates/shortcut-catalog.yml` | history, left as is | 1 |
| 226 | `site/scripts/__tests__/skills-catalog.test.mjs` | `name aid-catalog- (no such skill; fixture name)` | history, left as is | 1 |
| 227 | `site/scripts/__tests__/skills-catalog.test.mjs` | `name aid-middle (no such skill; fixture name)` | history, left as is | 1 |
| 228 | `site/scripts/__tests__/skills-catalog.test.mjs` | `name aid-zap (no such skill; fixture name)` | history, left as is | 1 |
| 229 | `site/scripts/__tests__/skills-catalog.test.mjs` | `name aid-alpha (no such skill; fixture name)` | history, left as is | 1 |
| 230 | `site/scripts/__tests__/skills-catalog.test.mjs` | `skill aid-deploy` | task-043 | 3 |
| 231 | `site/scripts/__tests__/skills-catalog.test.mjs` | `skill aid-monitor` | task-043 | 1 |
| 232 | `site/scripts/__tests__/skills-catalog.test.mjs` | `name aid-bad (no such skill; fixture name)` | history, left as is | 1 |
| 233 | `site/scripts/__tests__/skills-catalog.test.mjs` | `skill aid-fix` | history, left as is | 1 |
| 234 | `site/scripts/__tests__/skills-discover.test.mjs` | `skill aid-test` | task-044 | 45 |
| 235 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-missing (no such skill; fixture name)` | history, left as is | 2 |
| 236 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-bad- (no such skill; fixture name)` | history, left as is | 1 |
| 237 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid--double (no such skill; fixture name)` | history, left as is | 1 |
| 238 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-mismatch (no such skill; fixture name)` | history, left as is | 2 |
| 239 | `site/scripts/__tests__/skills-discover.test.mjs` | `canonical/skills/aid-test/SKILL.md` | task-044 | 2 |
| 240 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-foo-bar (no such skill; fixture name)` | history, left as is | 6 |
| 241 | `site/scripts/__tests__/skills-discover.test.mjs` | `canonical/skills/aid-foo-bar/ (no such skill; fixture path)` | history, left as is | 1 |
| 242 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-alpha (no such skill; fixture name)` | history, left as is | 1 |
| 243 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-beta (no such skill; fixture name)` | history, left as is | 1 |
| 244 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-z (no such skill; fixture name)` | history, left as is | 2 |
| 245 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-a (no such skill; fixture name)` | history, left as is | 2 |
| 246 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-m (no such skill; fixture name)` | history, left as is | 2 |
| 247 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-a-b (no such skill; fixture name)` | history, left as is | 2 |
| 248 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-ab (no such skill; fixture name)` | history, left as is | 2 |
| 249 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-good (no such skill; fixture name)` | history, left as is | 1 |
| 250 | `site/scripts/__tests__/skills-discover.test.mjs` | `name aid-bad (no such skill; fixture name)` | history, left as is | 1 |
| 251 | `site/scripts/__tests__/skills-frontmatter.test.mjs` | `canonical/skills/foo/ (no such skill; fixture path)` | history, left as is | 1 |
| 252 | `site/scripts/__tests__/skills-frontmatter.test.mjs` | `name aid-foo (no such skill; fixture name)` | history, left as is | 1 |
| 253 | `site/scripts/__tests__/skills-frontmatter.test.mjs` | `canonical/skills/x/ (no such skill; fixture path)` | history, left as is | 4 |
| 254 | `site/scripts/__tests__/skills-frontmatter.test.mjs` | `canonical/skills/z/ (no such skill; fixture path)` | history, left as is | 2 |
| 255 | `site/scripts/__tests__/skills-frontmatter.test.mjs` | `canonical/skills/*/ (no such skill; fixture path)` | history, left as is | 1 |
| 256 | `site/scripts/__tests__/skills-groups.test.mjs` | `name aid-totally-unknown-xyz (no such skill; fixture name)` | history, left as is | 1 |
| 257 | `site/scripts/__tests__/skills-groups.test.mjs` | `name aid-mystery-skill (no such skill; fixture name)` | history, left as is | 1 |
| 258 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-orchestrate` | task-032 | 4 |
| 259 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-config` | task-043 | 4 |
| 260 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-describe` | task-038 | 2 |
| 261 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-plan` | task-040 | 8 |
| 262 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-specify` | task-039 | 1 |
| 263 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-detail` | task-040 | 1 |
| 264 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-define` | task-039 | 1 |
| 265 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-deploy` | task-043 | 7 |
| 266 | `site/scripts/__tests__/skills-groups.test.mjs` | `skill aid-monitor` | task-043 | 4 |
| 267 | `site/scripts/__tests__/skills-paths.test.mjs` | `skill aid-create-api` | history, left as is | 3 |
| 268 | `site/scripts/__tests__/skills-paths.test.mjs` | `canonical/skills/aid-create-api/SKILL.md` | history, left as is | 2 |
| 269 | `site/scripts/__tests__/skills-paths.test.mjs` | `name aid-foo (no such skill; fixture name)` | history, left as is | 8 |
| 270 | `site/scripts/__tests__/skills-paths.test.mjs` | `name aid-bar-baz (no such skill; fixture name)` | history, left as is | 2 |
| 271 | `site/scripts/__tests__/skills-render-index.test.mjs` | `canonical/skills/*/ (no such skill; fixture path)` | history, left as is | 2 |
| 272 | `site/scripts/__tests__/skills-render-index.test.mjs` | `canonical/aid/templates/shortcut-catalog.yml` | history, left as is | 2 |
| 273 | `site/scripts/__tests__/skills-render-index.test.mjs` | `skill aid-deploy` | task-043 | 1 |
| 274 | `site/scripts/__tests__/skills-render-index.test.mjs` | `skill aid-monitor` | task-043 | 1 |
| 275 | `site/scripts/__tests__/skills-render-index.test.mjs` | `skill aid-orchestrate` | task-032 | 2 |
| 276 | `site/scripts/__tests__/skills-render-index.test.mjs` | `name aid-beta (no such skill; fixture name)` | history, left as is | 1 |
| 277 | `site/scripts/__tests__/skills-render-index.test.mjs` | `name aid-alpha (no such skill; fixture name)` | history, left as is | 1 |
| 278 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-test-skill (no such skill; fixture name)` | history, left as is | 5 |
| 279 | `site/scripts/__tests__/skills-render-page.test.mjs` | `canonical/skills/aid-review/SKILL.md` | task-044 | 1 |
| 280 | `site/scripts/__tests__/skills-render-page.test.mjs` | `skill aid-review` | task-044 | 2 |
| 281 | `site/scripts/__tests__/skills-render-page.test.mjs` | `canonical/skills/aid-test-skill/ (no such skill; fixture path)` | history, left as is | 4 |
| 282 | `site/scripts/__tests__/skills-render-page.test.mjs` | `skill aid-create-api` | history, left as is | 1 |
| 283 | `site/scripts/__tests__/skills-render-page.test.mjs` | `canonical/skills/aid-create-api/SKILL.md` | history, left as is | 1 |
| 284 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-list-test (no such skill; fixture name)` | history, left as is | 2 |
| 285 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-pipe-test (no such skill; fixture name)` | history, left as is | 2 |
| 286 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-angle-test (no such skill; fixture name)` | history, left as is | 2 |
| 287 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-synthetic-test (no such skill; fixture name)` | history, left as is | 2 |
| 288 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-folded-test (no such skill; fixture name)` | history, left as is | 2 |
| 289 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-fullfield-test (no such skill; fixture name)` | history, left as is | 2 |
| 290 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-nosidebar-test (no such skill; fixture name)` | history, left as is | 1 |
| 291 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-desc-test (no such skill; fixture name)` | history, left as is | 2 |
| 292 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-nodesc (no such skill; fixture name)` | history, left as is | 1 |
| 293 | `site/scripts/__tests__/skills-render-page.test.mjs` | `name aid-quote-test (no such skill; fixture name)` | history, left as is | 2 |
| 294 | `site/scripts/__tests__/skills-render-value.test.mjs` | `canonical/skills/aid-read-ticket/SKILL.md` | task-043 | 1 |
| 295 | `site/scripts/__tests__/skills-summary.test.mjs` | `skill aid-test` | task-044 | 10 |
| 296 | `site/scripts/__tests__/skills-summary.test.mjs` | `name aid-some-skill (no such skill; fixture name)` | history, left as is | 1 |
| 297 | `site/scripts/__tests__/skills-summary.test.mjs` | `name aid-custom-dir (no such skill; fixture name)` | history, left as is | 1 |
| 298 | `site/scripts/__tests__/skills-summary.test.mjs` | `name aid-x (no such skill; fixture name)` | history, left as is | 2 |
| 299 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | `canonical/aid/templates/knowledge-base/` | history, left as is | 1 |
| 300 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | `canonical/aid/templates/shortcut-engine.md` | task-037 | 1 |
| 301 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | `canonical/aid/templates/shortcut-catalog.yml` | history, left as is | 2 |
| 302 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | `canonical/skills/*/ (no such skill; fixture path)` | history, left as is | 1 |
| 303 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | `canonical/skills/aid-ask/SKILL.md` | task-042 | 6 |
| 304 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | `skill aid-ask` | task-042 | 9 |
| 305 | `site/src/lib/__tests__/feature-009-releases-banner.test.ts` | `name aid-banner-dismissed (no such skill; fixture name)` | history, left as is | 2 |
| 306 | `site/src/lib/__tests__/skill-node-panel.dom.test.ts` | `name aid-fixture (no such skill; fixture name)` | history, left as is | 1 |
| 307 | `site/src/lib/__tests__/skill-node-panel.dom.test.ts` | `canonical/skills/a/ (no such skill; fixture path)` | history, left as is | 3 |
| 308 | `site/src/lib/__tests__/skill-node-panel.dom.test.ts` | `name aid-flow-data (no such skill; fixture name)` | history, left as is | 1 |
| 309 | `site/src/lib/__tests__/skill-node-panel.dom.test.ts` | `name aid-node-panel (no such skill; fixture name)` | history, left as is | 1 |
| 310 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `canonical/skills/aid-ask/SKILL.md` | task-042 | 13 |
| 311 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `skill aid-ask` | task-042 | 7 |
| 312 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `skill aid-plan` | task-040 | 2 |
| 313 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `skill aid-execute` | task-040 | 1 |
| 314 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `canonical/skills/aid-plan/SKILL.md` | task-040 | 3 |
| 315 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `canonical/skills/Aid-Ask/ (no such skill; fixture path)` | history, left as is | 1 |
| 316 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `canonical/skills/aid_ask/ (no such skill; fixture path)` | history, left as is | 1 |
| 317 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `canonical/skills/aid-audit/ (no such skill; fixture path)` | history, left as is | 1 |
| 318 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `canonical/skills/*/ (no such skill; fixture path)` | history, left as is | 1 |
| 319 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `canonical/aid/templates/shortcut-catalog.yml` | history, left as is | 1 |
| 320 | `site/src/lib/__tests__/skill-node-panel.test.ts` | `canonical/skills/aid-not-a-real-skill/ (no such skill; fixture path)` | history, left as is | 1 |

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

Hits: 6188 lines in the two baselines, in 129 (baseline, term) rows. Owner for every row: `baseline, re-recorded at the gate` (Q134 D11; no task edits a baseline).

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

`.aid/runtime/` is the installed copy of `canonical/` (the resync step refreshes it at the gate). Command (run from the repo root; one line per pattern of P1-P5):

```bash
git grep -n -E 'PAUSE-FOR-USER|\*\*Advance:\*\*|initiator:|work-state-template\.yml` to|^(active_skill|step|step_detail|phase):|resume door|`?phase`?-matched|[A-Z][a-z]+-phase work|route per the chosen work|lifecycle: ["\x27]?(Completed|Canceled)|--field Phase --value' -- .aid/runtime
```

| # | Installed file | Lines | Owner |
|---|---|---|---|
| 1 | `.aid/runtime/templates/connectors/ticket-resolution.md` | 1 | installed copy (resync) |
| 2 | `.aid/runtime/templates/design-lifecycle.md` | 1 | installed copy (resync) |
| 3 | `.aid/runtime/templates/shortcut-engine.md` | 13 | installed copy (resync) |
| 4 | `.aid/runtime/templates/state-machine-chaining.md` | 12 | installed copy (resync) |
| 5 | `.aid/runtime/templates/work-state-template.yml` | 2 | installed copy (resync) |

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

A suite is listed when hits in it are owned by two or more tasks. For each pair of such tasks, the table says whether they depend on each other in the delivery-002 Execution Graph (PLAN.md, the table of the stanza). An independent pair is run after both tasks are done, in task-number order; a dependent pair is run after the later task, which is the one that depends on the earlier.

| # | Suite | Tasks | Relation | Run order |
|---|---|---|---|---|
| 1 | `dashboard/reader/tests/fixtures/task011_golden/flat_golden.json` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 2 | `dashboard/reader/tests/fixtures/task011_golden/hierarchical_golden.json` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 3 | `dashboard/reader/tests/test_declared_path_three_way_parity.py` | task-025, task-031 | task-025 depends on task-031 | task-031, then task-025 |
| 4 | `dashboard/reader/tests/test_feature009.py` | task-031, task-038 | task-038 depends on task-031 | task-031, then task-038 |
| 5 | `dashboard/reader/tests/test_feature009.py` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 6 | `dashboard/reader/tests/test_feature009.py` | task-038, task-040 | independent | task-038 and task-040 in either order; run after both are done, in number order (task-038 then task-040) |
| 7 | `dashboard/reader/tests/test_fixtures.py` | task-031, task-039 | task-039 depends on task-031 | task-031, then task-039 |
| 8 | `dashboard/reader/tests/test_fixtures.py` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 9 | `dashboard/reader/tests/test_fixtures.py` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 10 | `dashboard/reader/tests/test_flattened_layout_parity.py` | task-031, task-033 | task-033 depends on task-031 | task-031, then task-033 |
| 11 | `dashboard/reader/tests/test_flattened_layout_parity.py` | task-031, task-039 | task-039 depends on task-031 | task-031, then task-039 |
| 12 | `dashboard/reader/tests/test_flattened_layout_parity.py` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 13 | `dashboard/reader/tests/test_flattened_layout_parity.py` | task-033, task-039 | independent | task-033 and task-039 in either order; run after both are done, in number order (task-033 then task-039) |
| 14 | `dashboard/reader/tests/test_flattened_layout_parity.py` | task-033, task-040 | independent | task-033 and task-040 in either order; run after both are done, in number order (task-033 then task-040) |
| 15 | `dashboard/reader/tests/test_flattened_layout_parity.py` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 16 | `dashboard/reader/tests/test_integration.py` | task-025, task-031 | task-025 depends on task-031 | task-031, then task-025 |
| 17 | `dashboard/reader/tests/test_reader.py` | task-031, task-039 | task-039 depends on task-031 | task-031, then task-039 |
| 18 | `dashboard/reader/tests/test_reader.py` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 19 | `dashboard/reader/tests/test_reader.py` | task-031, task-043 | task-043 depends on task-031 | task-031, then task-043 |
| 20 | `dashboard/reader/tests/test_reader.py` | task-031, task-049 | task-049 depends on task-031 | task-031, then task-049 |
| 21 | `dashboard/reader/tests/test_reader.py` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 22 | `dashboard/reader/tests/test_reader.py` | task-039, task-043 | independent | task-039 and task-043 in either order; run after both are done, in number order (task-039 then task-043) |
| 23 | `dashboard/reader/tests/test_reader.py` | task-039, task-049 | task-049 depends on task-039 | task-039, then task-049 |
| 24 | `dashboard/reader/tests/test_reader.py` | task-040, task-043 | independent | task-040 and task-043 in either order; run after both are done, in number order (task-040 then task-043) |
| 25 | `dashboard/reader/tests/test_reader.py` | task-040, task-049 | task-049 depends on task-040 | task-040, then task-049 |
| 26 | `dashboard/reader/tests/test_reader.py` | task-043, task-049 | task-049 depends on task-043 | task-043, then task-049 |
| 27 | `dashboard/reader/tests/test_resolve_work_dir_cross_runtime_parity.py` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 28 | `dashboard/reader/tests/test_security_hardening.py` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 29 | `dashboard/reader/tests/test_shortcut_kind_map_cross_runtime_parity.py` | task-031, task-038 | task-038 depends on task-031 | task-031, then task-038 |
| 30 | `dashboard/reader/tests/test_task011_golden_master.py` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 31 | `dashboard/reader/tests/test_task014_fixtures.py` | task-031, task-039 | task-039 depends on task-031 | task-031, then task-039 |
| 32 | `dashboard/reader/tests/test_task014_fixtures.py` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 33 | `dashboard/reader/tests/test_task014_fixtures.py` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 34 | `dashboard/reader/tests/test_task019_connectors.py` | task-031, task-057 | task-057 depends on task-031 | task-031, then task-057 |
| 35 | `dashboard/reader/tests/test_task066_kb_parity.py` | task-031, task-041 | task-041 depends on task-031 | task-031, then task-041 |
| 36 | `dashboard/reader/tests/test_task069_detail_parser.py` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 37 | `dashboard/reader/tests/test_work001_delivery_layouts.py` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 38 | `dashboard/reader/tests/test_work003_state_schema.py` | task-031, task-038 | task-038 depends on task-031 | task-031, then task-038 |
| 39 | `dashboard/reader/tests/test_work003_state_schema.py` | task-031, task-039 | task-039 depends on task-031 | task-031, then task-039 |
| 40 | `dashboard/reader/tests/test_work003_state_schema.py` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 41 | `dashboard/reader/tests/test_work003_state_schema.py` | task-031, task-044 | task-044 depends on task-031 | task-031, then task-044 |
| 42 | `dashboard/reader/tests/test_work003_state_schema.py` | task-038, task-039 | independent | task-038 and task-039 in either order; run after both are done, in number order (task-038 then task-039) |
| 43 | `dashboard/reader/tests/test_work003_state_schema.py` | task-038, task-040 | independent | task-038 and task-040 in either order; run after both are done, in number order (task-038 then task-040) |
| 44 | `dashboard/reader/tests/test_work003_state_schema.py` | task-038, task-044 | independent | task-038 and task-044 in either order; run after both are done, in number order (task-038 then task-044) |
| 45 | `dashboard/reader/tests/test_work003_state_schema.py` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 46 | `dashboard/reader/tests/test_work003_state_schema.py` | task-039, task-044 | independent | task-039 and task-044 in either order; run after both are done, in number order (task-039 then task-044) |
| 47 | `dashboard/reader/tests/test_work003_state_schema.py` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 48 | `dashboard/reader/tests/test_work016_container_discovery.py` | task-031, task-033 | task-033 depends on task-031 | task-031, then task-033 |
| 49 | `dashboard/reader/tests/test_work016_container_discovery.py` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 50 | `dashboard/reader/tests/test_work016_container_discovery.py` | task-033, task-040 | independent | task-033 and task-040 in either order; run after both are done, in number order (task-033 then task-040) |
| 51 | `dashboard/server/tests/test_home_html_project_header.py` | task-031, task-033 | task-033 depends on task-031 | task-031, then task-033 |
| 52 | `dashboard/server/tests/test_reader_task069.mjs` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 53 | `dashboard/server/tests/test_reader_task069.mjs` | task-031, task-044 | task-044 depends on task-031 | task-031, then task-044 |
| 54 | `dashboard/server/tests/test_reader_task069.mjs` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 55 | `dashboard/server/tests/test_server_node.mjs` | task-031, task-033 | task-033 depends on task-031 | task-031, then task-033 |
| 56 | `dashboard/server/tests/test_server_node.mjs` | task-031, task-043 | task-043 depends on task-031 | task-031, then task-043 |
| 57 | `dashboard/server/tests/test_server_node.mjs` | task-033, task-043 | independent | task-033 and task-043 in either order; run after both are done, in number order (task-033 then task-043) |
| 58 | `dashboard/server/tests/test_server_py.py` | task-031, task-033 | task-033 depends on task-031 | task-031, then task-033 |
| 59 | `dashboard/server/tests/test_task002_resolve_work_dir.mjs` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 60 | `dashboard/server/tests/test_task010_task_notes.py` | task-025, task-031 | task-025 depends on task-031 | task-031, then task-025 |
| 61 | `dashboard/server/tests/test_task010_task_notes.py` | task-025, task-033 | independent | task-025 and task-033 in either order; run after both are done, in number order (task-025 then task-033) |
| 62 | `dashboard/server/tests/test_task010_task_notes.py` | task-031, task-033 | task-033 depends on task-031 | task-031, then task-033 |
| 63 | `dashboard/server/tests/test_task010_task_notes_cross_runtime_parity.py` | task-025, task-031 | task-025 depends on task-031 | task-031, then task-025 |
| 64 | `dashboard/server/tests/test_task011_dispatch_round_trip.mjs` | task-025, task-031 | task-025 depends on task-031 | task-031, then task-025 |
| 65 | `dashboard/server/tests/test_task011_dispatch_round_trip.py` | task-025, task-031 | task-025 depends on task-031 | task-031, then task-025 |
| 66 | `dashboard/server/tests/test_task012_consuming_round_trips.py` | task-025, task-031 | task-025 depends on task-031 | task-031, then task-025 |
| 67 | `dashboard/server/tests/test_task012_consuming_round_trips.py` | task-025, task-033 | independent | task-025 and task-033 in either order; run after both are done, in number order (task-025 then task-033) |
| 68 | `dashboard/server/tests/test_task012_consuming_round_trips.py` | task-025, task-043 | task-043 depends on task-025 | task-025, then task-043 |
| 69 | `dashboard/server/tests/test_task012_consuming_round_trips.py` | task-031, task-033 | task-033 depends on task-031 | task-031, then task-033 |
| 70 | `dashboard/server/tests/test_task012_consuming_round_trips.py` | task-031, task-043 | task-043 depends on task-031 | task-031, then task-043 |
| 71 | `dashboard/server/tests/test_task012_consuming_round_trips.py` | task-033, task-043 | independent | task-033 and task-043 in either order; run after both are done, in number order (task-033 then task-043) |
| 72 | `dashboard/server/tests/test_task019_connector_ops.mjs` | task-031, task-057 | task-057 depends on task-031 | task-031, then task-057 |
| 73 | `dashboard/server/tests/test_task022_connectors_external_sources_ui.py` | task-031, task-033 | task-033 depends on task-031 | task-031, then task-033 |
| 74 | `dashboard/server/tests/test_task023_list_management_round_trips.py` | task-031, task-057 | task-057 depends on task-031 | task-031, then task-057 |
| 75 | `dashboard/server/tests/test_task029_task_stop_resume_ops.mjs` | task-025, task-031 | task-025 depends on task-031 | task-031, then task-025 |
| 76 | `dashboard/server/tests/test_task030_finish_stop_resume_ui.py` | task-025, task-031 | task-025 depends on task-031 | task-031, then task-025 |
| 77 | `dashboard/server/tests/test_task030_finish_stop_resume_ui.py` | task-025, task-033 | independent | task-025 and task-033 in either order; run after both are done, in number order (task-025 then task-033) |
| 78 | `dashboard/server/tests/test_task030_finish_stop_resume_ui.py` | task-031, task-033 | task-033 depends on task-031 | task-031, then task-033 |
| 79 | `dashboard/server/tests/test_task033_execution_control_round_trips.py` | task-025, task-031 | task-025 depends on task-031 | task-031, then task-025 |
| 80 | `dashboard/server/tests/test_task033_execution_control_round_trips.py` | task-025, task-033 | independent | task-025 and task-033 in either order; run after both are done, in number order (task-025 then task-033) |
| 81 | `dashboard/server/tests/test_task033_execution_control_round_trips.py` | task-031, task-033 | task-033 depends on task-031 | task-031, then task-033 |
| 82 | `dashboard/server/tests/test_tools_management_ui.py` | task-031, task-033 | task-033 depends on task-031 | task-031, then task-033 |
| 83 | `dashboard/server/tests/test_write_enabled_cross_runtime_parity.py` | task-025, task-031 | task-025 depends on task-031 | task-031, then task-025 |
| 84 | `site/scripts/__tests__/flow-advance.test.mjs` | task-024, task-041 | task-041 depends on task-024 | task-024, then task-041 |
| 85 | `site/scripts/__tests__/flow-advance.test.mjs` | task-024, task-042 | task-042 depends on task-024 | task-024, then task-042 |
| 86 | `site/scripts/__tests__/flow-advance.test.mjs` | task-024, task-044 | task-044 depends on task-024 | task-024, then task-044 |
| 87 | `site/scripts/__tests__/flow-advance.test.mjs` | task-041, task-042 | independent | task-041 and task-042 in either order; run after both are done, in number order (task-041 then task-042) |
| 88 | `site/scripts/__tests__/flow-advance.test.mjs` | task-041, task-044 | independent | task-041 and task-044 in either order; run after both are done, in number order (task-041 then task-044) |
| 89 | `site/scripts/__tests__/flow-advance.test.mjs` | task-042, task-044 | independent | task-042 and task-044 in either order; run after both are done, in number order (task-042 then task-044) |
| 90 | `site/scripts/__tests__/flow-classify.test.mjs` | task-037, task-044 | independent | task-037 and task-044 in either order; run after both are done, in number order (task-037 then task-044) |
| 91 | `site/scripts/__tests__/flow-compose.test.mjs` | task-037, task-044 | independent | task-037 and task-044 in either order; run after both are done, in number order (task-037 then task-044) |
| 92 | `site/scripts/__tests__/flow-engine-core.test.mjs` | task-030, task-037 | task-037 depends on task-030 | task-030, then task-037 |
| 93 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-024, task-038 | task-038 depends on task-024 | task-024, then task-038 |
| 94 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-024, task-039 | task-039 depends on task-024 | task-024, then task-039 |
| 95 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-024, task-040 | task-040 depends on task-024 | task-024, then task-040 |
| 96 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-024, task-041 | task-041 depends on task-024 | task-024, then task-041 |
| 97 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-024, task-042 | task-042 depends on task-024 | task-024, then task-042 |
| 98 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-024, task-043 | task-043 depends on task-024 | task-024, then task-043 |
| 99 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-038, task-039 | independent | task-038 and task-039 in either order; run after both are done, in number order (task-038 then task-039) |
| 100 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-038, task-040 | independent | task-038 and task-040 in either order; run after both are done, in number order (task-038 then task-040) |
| 101 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-038, task-041 | independent | task-038 and task-041 in either order; run after both are done, in number order (task-038 then task-041) |
| 102 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-038, task-042 | independent | task-038 and task-042 in either order; run after both are done, in number order (task-038 then task-042) |
| 103 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-038, task-043 | independent | task-038 and task-043 in either order; run after both are done, in number order (task-038 then task-043) |
| 104 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 105 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-039, task-041 | independent | task-039 and task-041 in either order; run after both are done, in number order (task-039 then task-041) |
| 106 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-039, task-042 | independent | task-039 and task-042 in either order; run after both are done, in number order (task-039 then task-042) |
| 107 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-039, task-043 | independent | task-039 and task-043 in either order; run after both are done, in number order (task-039 then task-043) |
| 108 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-040, task-041 | independent | task-040 and task-041 in either order; run after both are done, in number order (task-040 then task-041) |
| 109 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-040, task-042 | independent | task-040 and task-042 in either order; run after both are done, in number order (task-040 then task-042) |
| 110 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-040, task-043 | independent | task-040 and task-043 in either order; run after both are done, in number order (task-040 then task-043) |
| 111 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-041, task-042 | independent | task-041 and task-042 in either order; run after both are done, in number order (task-041 then task-042) |
| 112 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-041, task-043 | independent | task-041 and task-043 in either order; run after both are done, in number order (task-041 then task-043) |
| 113 | `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-042, task-043 | independent | task-042 and task-043 in either order; run after both are done, in number order (task-042 then task-043) |
| 114 | `site/scripts/__tests__/flow-extract-engine.test.mjs` | task-037, task-040 | independent | task-037 and task-040 in either order; run after both are done, in number order (task-037 then task-040) |
| 115 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | task-024, task-034 | task-034 depends on task-024 | task-024, then task-034 |
| 116 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | task-024, task-044 | task-044 depends on task-024 | task-024, then task-044 |
| 117 | `site/scripts/__tests__/flow-extract-inline.test.mjs` | task-034, task-044 | independent | task-034 and task-044 in either order; run after both are done, in number order (task-034 then task-044) |
| 118 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | task-042, task-043 | independent | task-042 and task-043 in either order; run after both are done, in number order (task-042 then task-043) |
| 119 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | task-042, task-044 | independent | task-042 and task-044 in either order; run after both are done, in number order (task-042 then task-044) |
| 120 | `site/scripts/__tests__/flow-extract-residual.test.mjs` | task-043, task-044 | independent | task-043 and task-044 in either order; run after both are done, in number order (task-043 then task-044) |
| 121 | `site/scripts/__tests__/flow-facade.test.mjs` | task-038, task-042 | independent | task-038 and task-042 in either order; run after both are done, in number order (task-038 then task-042) |
| 122 | `site/scripts/__tests__/flow-facade.test.mjs` | task-038, task-043 | independent | task-038 and task-043 in either order; run after both are done, in number order (task-038 then task-043) |
| 123 | `site/scripts/__tests__/flow-facade.test.mjs` | task-038, task-044 | independent | task-038 and task-044 in either order; run after both are done, in number order (task-038 then task-044) |
| 124 | `site/scripts/__tests__/flow-facade.test.mjs` | task-042, task-043 | independent | task-042 and task-043 in either order; run after both are done, in number order (task-042 then task-043) |
| 125 | `site/scripts/__tests__/flow-facade.test.mjs` | task-042, task-044 | independent | task-042 and task-044 in either order; run after both are done, in number order (task-042 then task-044) |
| 126 | `site/scripts/__tests__/flow-facade.test.mjs` | task-043, task-044 | independent | task-043 and task-044 in either order; run after both are done, in number order (task-043 then task-044) |
| 127 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-030, task-037 | task-037 depends on task-030 | task-030, then task-037 |
| 128 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-030, task-040 | task-040 depends on task-030 | task-030, then task-040 |
| 129 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-030, task-044 | task-044 depends on task-030 | task-030, then task-044 |
| 130 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-037, task-040 | independent | task-037 and task-040 in either order; run after both are done, in number order (task-037 then task-040) |
| 131 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-037, task-044 | independent | task-037 and task-044 in either order; run after both are done, in number order (task-037 then task-044) |
| 132 | `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 133 | `site/scripts/__tests__/flow-graph.test.mjs` | task-024, task-037 | task-037 depends on task-024 | task-024, then task-037 |
| 134 | `site/scripts/__tests__/flow-graph.test.mjs` | task-024, task-038 | task-038 depends on task-024 | task-024, then task-038 |
| 135 | `site/scripts/__tests__/flow-graph.test.mjs` | task-024, task-039 | task-039 depends on task-024 | task-024, then task-039 |
| 136 | `site/scripts/__tests__/flow-graph.test.mjs` | task-024, task-042 | task-042 depends on task-024 | task-024, then task-042 |
| 137 | `site/scripts/__tests__/flow-graph.test.mjs` | task-024, task-044 | task-044 depends on task-024 | task-024, then task-044 |
| 138 | `site/scripts/__tests__/flow-graph.test.mjs` | task-037, task-038 | independent | task-037 and task-038 in either order; run after both are done, in number order (task-037 then task-038) |
| 139 | `site/scripts/__tests__/flow-graph.test.mjs` | task-037, task-039 | independent | task-037 and task-039 in either order; run after both are done, in number order (task-037 then task-039) |
| 140 | `site/scripts/__tests__/flow-graph.test.mjs` | task-037, task-042 | independent | task-037 and task-042 in either order; run after both are done, in number order (task-037 then task-042) |
| 141 | `site/scripts/__tests__/flow-graph.test.mjs` | task-037, task-044 | independent | task-037 and task-044 in either order; run after both are done, in number order (task-037 then task-044) |
| 142 | `site/scripts/__tests__/flow-graph.test.mjs` | task-038, task-039 | independent | task-038 and task-039 in either order; run after both are done, in number order (task-038 then task-039) |
| 143 | `site/scripts/__tests__/flow-graph.test.mjs` | task-038, task-042 | independent | task-038 and task-042 in either order; run after both are done, in number order (task-038 then task-042) |
| 144 | `site/scripts/__tests__/flow-graph.test.mjs` | task-038, task-044 | independent | task-038 and task-044 in either order; run after both are done, in number order (task-038 then task-044) |
| 145 | `site/scripts/__tests__/flow-graph.test.mjs` | task-039, task-042 | independent | task-039 and task-042 in either order; run after both are done, in number order (task-039 then task-042) |
| 146 | `site/scripts/__tests__/flow-graph.test.mjs` | task-039, task-044 | independent | task-039 and task-044 in either order; run after both are done, in number order (task-039 then task-044) |
| 147 | `site/scripts/__tests__/flow-graph.test.mjs` | task-042, task-044 | independent | task-042 and task-044 in either order; run after both are done, in number order (task-042 then task-044) |
| 148 | `site/scripts/__tests__/flow-render-mermaid.test.mjs` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 149 | `site/scripts/__tests__/flow-validate.test.mjs` | task-024, task-044 | task-044 depends on task-024 | task-024, then task-044 |
| 150 | `site/scripts/__tests__/gen-reference.test.mjs` | task-032, task-037 | independent | task-032 and task-037 in either order; run after both are done, in number order (task-032 then task-037) |
| 151 | `site/scripts/__tests__/gen-reference.test.mjs` | task-032, task-038 | independent | task-032 and task-038 in either order; run after both are done, in number order (task-032 then task-038) |
| 152 | `site/scripts/__tests__/gen-reference.test.mjs` | task-032, task-039 | independent | task-032 and task-039 in either order; run after both are done, in number order (task-032 then task-039) |
| 153 | `site/scripts/__tests__/gen-reference.test.mjs` | task-032, task-040 | independent | task-032 and task-040 in either order; run after both are done, in number order (task-032 then task-040) |
| 154 | `site/scripts/__tests__/gen-reference.test.mjs` | task-032, task-041 | independent | task-032 and task-041 in either order; run after both are done, in number order (task-032 then task-041) |
| 155 | `site/scripts/__tests__/gen-reference.test.mjs` | task-032, task-042 | independent | task-032 and task-042 in either order; run after both are done, in number order (task-032 then task-042) |
| 156 | `site/scripts/__tests__/gen-reference.test.mjs` | task-032, task-043 | independent | task-032 and task-043 in either order; run after both are done, in number order (task-032 then task-043) |
| 157 | `site/scripts/__tests__/gen-reference.test.mjs` | task-037, task-038 | independent | task-037 and task-038 in either order; run after both are done, in number order (task-037 then task-038) |
| 158 | `site/scripts/__tests__/gen-reference.test.mjs` | task-037, task-039 | independent | task-037 and task-039 in either order; run after both are done, in number order (task-037 then task-039) |
| 159 | `site/scripts/__tests__/gen-reference.test.mjs` | task-037, task-040 | independent | task-037 and task-040 in either order; run after both are done, in number order (task-037 then task-040) |
| 160 | `site/scripts/__tests__/gen-reference.test.mjs` | task-037, task-041 | independent | task-037 and task-041 in either order; run after both are done, in number order (task-037 then task-041) |
| 161 | `site/scripts/__tests__/gen-reference.test.mjs` | task-037, task-042 | independent | task-037 and task-042 in either order; run after both are done, in number order (task-037 then task-042) |
| 162 | `site/scripts/__tests__/gen-reference.test.mjs` | task-037, task-043 | independent | task-037 and task-043 in either order; run after both are done, in number order (task-037 then task-043) |
| 163 | `site/scripts/__tests__/gen-reference.test.mjs` | task-038, task-039 | independent | task-038 and task-039 in either order; run after both are done, in number order (task-038 then task-039) |
| 164 | `site/scripts/__tests__/gen-reference.test.mjs` | task-038, task-040 | independent | task-038 and task-040 in either order; run after both are done, in number order (task-038 then task-040) |
| 165 | `site/scripts/__tests__/gen-reference.test.mjs` | task-038, task-041 | independent | task-038 and task-041 in either order; run after both are done, in number order (task-038 then task-041) |
| 166 | `site/scripts/__tests__/gen-reference.test.mjs` | task-038, task-042 | independent | task-038 and task-042 in either order; run after both are done, in number order (task-038 then task-042) |
| 167 | `site/scripts/__tests__/gen-reference.test.mjs` | task-038, task-043 | independent | task-038 and task-043 in either order; run after both are done, in number order (task-038 then task-043) |
| 168 | `site/scripts/__tests__/gen-reference.test.mjs` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 169 | `site/scripts/__tests__/gen-reference.test.mjs` | task-039, task-041 | independent | task-039 and task-041 in either order; run after both are done, in number order (task-039 then task-041) |
| 170 | `site/scripts/__tests__/gen-reference.test.mjs` | task-039, task-042 | independent | task-039 and task-042 in either order; run after both are done, in number order (task-039 then task-042) |
| 171 | `site/scripts/__tests__/gen-reference.test.mjs` | task-039, task-043 | independent | task-039 and task-043 in either order; run after both are done, in number order (task-039 then task-043) |
| 172 | `site/scripts/__tests__/gen-reference.test.mjs` | task-040, task-041 | independent | task-040 and task-041 in either order; run after both are done, in number order (task-040 then task-041) |
| 173 | `site/scripts/__tests__/gen-reference.test.mjs` | task-040, task-042 | independent | task-040 and task-042 in either order; run after both are done, in number order (task-040 then task-042) |
| 174 | `site/scripts/__tests__/gen-reference.test.mjs` | task-040, task-043 | independent | task-040 and task-043 in either order; run after both are done, in number order (task-040 then task-043) |
| 175 | `site/scripts/__tests__/gen-reference.test.mjs` | task-041, task-042 | independent | task-041 and task-042 in either order; run after both are done, in number order (task-041 then task-042) |
| 176 | `site/scripts/__tests__/gen-reference.test.mjs` | task-041, task-043 | independent | task-041 and task-043 in either order; run after both are done, in number order (task-041 then task-043) |
| 177 | `site/scripts/__tests__/gen-reference.test.mjs` | task-042, task-043 | independent | task-042 and task-043 in either order; run after both are done, in number order (task-042 then task-043) |
| 178 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-032, task-038 | independent | task-032 and task-038 in either order; run after both are done, in number order (task-032 then task-038) |
| 179 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-032, task-039 | independent | task-032 and task-039 in either order; run after both are done, in number order (task-032 then task-039) |
| 180 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-032, task-040 | independent | task-032 and task-040 in either order; run after both are done, in number order (task-032 then task-040) |
| 181 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-032, task-043 | independent | task-032 and task-043 in either order; run after both are done, in number order (task-032 then task-043) |
| 182 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-038, task-039 | independent | task-038 and task-039 in either order; run after both are done, in number order (task-038 then task-039) |
| 183 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-038, task-040 | independent | task-038 and task-040 in either order; run after both are done, in number order (task-038 then task-040) |
| 184 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-038, task-043 | independent | task-038 and task-043 in either order; run after both are done, in number order (task-038 then task-043) |
| 185 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 186 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-039, task-043 | independent | task-039 and task-043 in either order; run after both are done, in number order (task-039 then task-043) |
| 187 | `site/scripts/__tests__/gen-skills-index.test.mjs` | task-040, task-043 | independent | task-040 and task-043 in either order; run after both are done, in number order (task-040 then task-043) |
| 188 | `site/scripts/__tests__/gen-skills.test.mjs` | task-040, task-041 | independent | task-040 and task-041 in either order; run after both are done, in number order (task-040 then task-041) |
| 189 | `site/scripts/__tests__/gen-skills.test.mjs` | task-040, task-042 | independent | task-040 and task-042 in either order; run after both are done, in number order (task-040 then task-042) |
| 190 | `site/scripts/__tests__/gen-skills.test.mjs` | task-040, task-043 | independent | task-040 and task-043 in either order; run after both are done, in number order (task-040 then task-043) |
| 191 | `site/scripts/__tests__/gen-skills.test.mjs` | task-041, task-042 | independent | task-041 and task-042 in either order; run after both are done, in number order (task-041 then task-042) |
| 192 | `site/scripts/__tests__/gen-skills.test.mjs` | task-041, task-043 | independent | task-041 and task-043 in either order; run after both are done, in number order (task-041 then task-043) |
| 193 | `site/scripts/__tests__/gen-skills.test.mjs` | task-042, task-043 | independent | task-042 and task-043 in either order; run after both are done, in number order (task-042 then task-043) |
| 194 | `site/scripts/__tests__/provenance-appender.test.mjs` | task-037, task-042 | independent | task-037 and task-042 in either order; run after both are done, in number order (task-037 then task-042) |
| 195 | `site/scripts/__tests__/provenance-appender.test.mjs` | task-037, task-044 | independent | task-037 and task-044 in either order; run after both are done, in number order (task-037 then task-044) |
| 196 | `site/scripts/__tests__/provenance-appender.test.mjs` | task-042, task-044 | independent | task-042 and task-044 in either order; run after both are done, in number order (task-042 then task-044) |
| 197 | `site/scripts/__tests__/provenance.test.mjs` | task-042, task-044 | independent | task-042 and task-044 in either order; run after both are done, in number order (task-042 then task-044) |
| 198 | `site/scripts/__tests__/skills-groups.test.mjs` | task-032, task-038 | independent | task-032 and task-038 in either order; run after both are done, in number order (task-032 then task-038) |
| 199 | `site/scripts/__tests__/skills-groups.test.mjs` | task-032, task-039 | independent | task-032 and task-039 in either order; run after both are done, in number order (task-032 then task-039) |
| 200 | `site/scripts/__tests__/skills-groups.test.mjs` | task-032, task-040 | independent | task-032 and task-040 in either order; run after both are done, in number order (task-032 then task-040) |
| 201 | `site/scripts/__tests__/skills-groups.test.mjs` | task-032, task-043 | independent | task-032 and task-043 in either order; run after both are done, in number order (task-032 then task-043) |
| 202 | `site/scripts/__tests__/skills-groups.test.mjs` | task-038, task-039 | independent | task-038 and task-039 in either order; run after both are done, in number order (task-038 then task-039) |
| 203 | `site/scripts/__tests__/skills-groups.test.mjs` | task-038, task-040 | independent | task-038 and task-040 in either order; run after both are done, in number order (task-038 then task-040) |
| 204 | `site/scripts/__tests__/skills-groups.test.mjs` | task-038, task-043 | independent | task-038 and task-043 in either order; run after both are done, in number order (task-038 then task-043) |
| 205 | `site/scripts/__tests__/skills-groups.test.mjs` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 206 | `site/scripts/__tests__/skills-groups.test.mjs` | task-039, task-043 | independent | task-039 and task-043 in either order; run after both are done, in number order (task-039 then task-043) |
| 207 | `site/scripts/__tests__/skills-groups.test.mjs` | task-040, task-043 | independent | task-040 and task-043 in either order; run after both are done, in number order (task-040 then task-043) |
| 208 | `site/scripts/__tests__/skills-render-index.test.mjs` | task-032, task-043 | independent | task-032 and task-043 in either order; run after both are done, in number order (task-032 then task-043) |
| 209 | `site/scripts/__tests__/skills-render-page.test.mjs` | task-043, task-044 | independent | task-043 and task-044 in either order; run after both are done, in number order (task-043 then task-044) |
| 210 | `site/src/lib/__tests__/feature-006-head-gate.test.ts` | task-037, task-042 | independent | task-037 and task-042 in either order; run after both are done, in number order (task-037 then task-042) |
| 211 | `site/src/lib/__tests__/skill-node-panel.test.ts` | task-040, task-042 | independent | task-040 and task-042 in either order; run after both are done, in number order (task-040 then task-042) |
| 212 | `tests/README.md` | task-025, task-040 | task-040 depends on task-025 | task-025, then task-040 |
| 213 | `tests/README.md` | task-025, task-041 | task-041 depends on task-025 | task-025, then task-041 |
| 214 | `tests/README.md` | task-025, task-044 | task-044 depends on task-025 | task-025, then task-044 |
| 215 | `tests/README.md` | task-040, task-041 | independent | task-040 and task-041 in either order; run after both are done, in number order (task-040 then task-041) |
| 216 | `tests/README.md` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 217 | `tests/README.md` | task-041, task-044 | independent | task-041 and task-044 in either order; run after both are done, in number order (task-041 then task-044) |
| 218 | `tests/canonical/fixtures/actback-task/docset-check.tsv` | task-044, task-045 | independent | task-044 and task-045 in either order; run after both are done, in number order (task-044 then task-045) |
| 219 | `tests/canonical/fixtures/actback-task/docset-component.tsv` | task-044, task-049 | task-049 depends on task-044 | task-044, then task-049 |
| 220 | `tests/canonical/fixtures/actback-task/docset-contract.tsv` | task-044, task-049 | task-049 depends on task-044 | task-044, then task-049 |
| 221 | `tests/canonical/fixtures/dual-intent/content/doc-set.tsv` | task-044, task-045 | independent | task-044 and task-045 in either order; run after both are done, in number order (task-044 then task-045) |
| 222 | `tests/canonical/fixtures/dual-intent/data-ml/doc-set.tsv` | task-044, task-045 | independent | task-044 and task-045 in either order; run after both are done, in number order (task-044 then task-045) |
| 223 | `tests/canonical/fixtures/dual-intent/design/doc-set.tsv` | task-044, task-045 | independent | task-044 and task-045 in either order; run after both are done, in number order (task-044 then task-045) |
| 224 | `tests/canonical/fixtures/kb-essence/actback/representative-task-fixture/doc-set.tsv` | task-044, task-045 | independent | task-044 and task-045 in either order; run after both are done, in number order (task-044 then task-045) |
| 225 | `tests/canonical/test-actback-task.sh` | task-044, task-045 | independent | task-044 and task-045 in either order; run after both are done, in number order (task-044 then task-045) |
| 226 | `tests/canonical/test-actback-task.sh` | task-044, task-049 | task-049 depends on task-044 | task-044, then task-049 |
| 227 | `tests/canonical/test-actback-task.sh` | task-045, task-049 | independent | task-045 and task-049 in either order; run after both are done, in number order (task-045 then task-049) |
| 228 | `tests/canonical/test-aid-migrate-trigger.sh` | task-033, task-056 | task-056 depends on task-033 | task-033, then task-056 |
| 229 | `tests/canonical/test-aid-migrate.sh` | task-032, task-033 | independent | task-032 and task-033 in either order; run after both are done, in number order (task-032 then task-033) |
| 230 | `tests/canonical/test-aid-migrate.sh` | task-032, task-040 | independent | task-032 and task-040 in either order; run after both are done, in number order (task-032 then task-040) |
| 231 | `tests/canonical/test-aid-migrate.sh` | task-032, task-042 | independent | task-032 and task-042 in either order; run after both are done, in number order (task-032 then task-042) |
| 232 | `tests/canonical/test-aid-migrate.sh` | task-032, task-056 | task-056 depends on task-032 | task-032, then task-056 |
| 233 | `tests/canonical/test-aid-migrate.sh` | task-033, task-040 | independent | task-033 and task-040 in either order; run after both are done, in number order (task-033 then task-040) |
| 234 | `tests/canonical/test-aid-migrate.sh` | task-033, task-042 | independent | task-033 and task-042 in either order; run after both are done, in number order (task-033 then task-042) |
| 235 | `tests/canonical/test-aid-migrate.sh` | task-033, task-056 | task-056 depends on task-033 | task-033, then task-056 |
| 236 | `tests/canonical/test-aid-migrate.sh` | task-040, task-042 | independent | task-040 and task-042 in either order; run after both are done, in number order (task-040 then task-042) |
| 237 | `tests/canonical/test-aid-migrate.sh` | task-040, task-056 | task-056 depends on task-040 | task-040, then task-056 |
| 238 | `tests/canonical/test-aid-migrate.sh` | task-042, task-056 | task-056 depends on task-042 | task-042, then task-056 |
| 239 | `tests/canonical/test-artifact-discipline.sh` | task-025, task-031 | task-025 depends on task-031 | task-031, then task-025 |
| 240 | `tests/canonical/test-artifact-discipline.sh` | task-025, task-037 | task-037 depends on task-025 | task-025, then task-037 |
| 241 | `tests/canonical/test-artifact-discipline.sh` | task-025, task-039 | task-039 depends on task-025 | task-025, then task-039 |
| 242 | `tests/canonical/test-artifact-discipline.sh` | task-025, task-040 | task-040 depends on task-025 | task-025, then task-040 |
| 243 | `tests/canonical/test-artifact-discipline.sh` | task-025, task-044 | task-044 depends on task-025 | task-025, then task-044 |
| 244 | `tests/canonical/test-artifact-discipline.sh` | task-031, task-037 | task-037 depends on task-031 | task-031, then task-037 |
| 245 | `tests/canonical/test-artifact-discipline.sh` | task-031, task-039 | task-039 depends on task-031 | task-031, then task-039 |
| 246 | `tests/canonical/test-artifact-discipline.sh` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 247 | `tests/canonical/test-artifact-discipline.sh` | task-031, task-044 | task-044 depends on task-031 | task-031, then task-044 |
| 248 | `tests/canonical/test-artifact-discipline.sh` | task-037, task-039 | independent | task-037 and task-039 in either order; run after both are done, in number order (task-037 then task-039) |
| 249 | `tests/canonical/test-artifact-discipline.sh` | task-037, task-040 | independent | task-037 and task-040 in either order; run after both are done, in number order (task-037 then task-040) |
| 250 | `tests/canonical/test-artifact-discipline.sh` | task-037, task-044 | independent | task-037 and task-044 in either order; run after both are done, in number order (task-037 then task-044) |
| 251 | `tests/canonical/test-artifact-discipline.sh` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 252 | `tests/canonical/test-artifact-discipline.sh` | task-039, task-044 | independent | task-039 and task-044 in either order; run after both are done, in number order (task-039 then task-044) |
| 253 | `tests/canonical/test-artifact-discipline.sh` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 254 | `tests/canonical/test-catalog-dirs-parity.sh` | task-037, task-042 | independent | task-037 and task-042 in either order; run after both are done, in number order (task-037 then task-042) |
| 255 | `tests/canonical/test-catalog-dirs-parity.sh` | task-037, task-043 | independent | task-037 and task-043 in either order; run after both are done, in number order (task-037 then task-043) |
| 256 | `tests/canonical/test-catalog-dirs-parity.sh` | task-042, task-043 | independent | task-042 and task-043 in either order; run after both are done, in number order (task-042 then task-043) |
| 257 | `tests/canonical/test-change-refactor-family-scaffold.sh` | task-032, task-037 | independent | task-032 and task-037 in either order; run after both are done, in number order (task-032 then task-037) |
| 258 | `tests/canonical/test-change-refactor-family-scaffold.sh` | task-032, task-040 | independent | task-032 and task-040 in either order; run after both are done, in number order (task-032 then task-040) |
| 259 | `tests/canonical/test-change-refactor-family-scaffold.sh` | task-032, task-044 | independent | task-032 and task-044 in either order; run after both are done, in number order (task-032 then task-044) |
| 260 | `tests/canonical/test-change-refactor-family-scaffold.sh` | task-037, task-040 | independent | task-037 and task-040 in either order; run after both are done, in number order (task-037 then task-040) |
| 261 | `tests/canonical/test-change-refactor-family-scaffold.sh` | task-037, task-044 | independent | task-037 and task-044 in either order; run after both are done, in number order (task-037 then task-044) |
| 262 | `tests/canonical/test-change-refactor-family-scaffold.sh` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 263 | `tests/canonical/test-chat-node-manifest.sh` | task-033, task-056 | task-056 depends on task-033 | task-033, then task-056 |
| 264 | `tests/canonical/test-chat-node-wake.sh` | task-043, task-045 | independent | task-043 and task-045 in either order; run after both are done, in number order (task-043 then task-045) |
| 265 | `tests/canonical/test-closure-check.sh` | task-045, task-049 | independent | task-045 and task-049 in either order; run after both are done, in number order (task-045 then task-049) |
| 266 | `tests/canonical/test-conformance-lane-semantics.sh` | task-041, task-042 | independent | task-041 and task-042 in either order; run after both are done, in number order (task-041 then task-042) |
| 267 | `tests/canonical/test-conformance-lane-semantics.sh` | task-041, task-049 | task-049 depends on task-041 | task-041, then task-049 |
| 268 | `tests/canonical/test-conformance-lane-semantics.sh` | task-042, task-049 | task-049 depends on task-042 | task-042, then task-049 |
| 269 | `tests/canonical/test-connector-consumption-linkage.sh` | task-021, task-038 | task-038 depends on task-021 | task-021, then task-038 |
| 270 | `tests/canonical/test-connector-consumption-linkage.sh` | task-021, task-039 | task-039 depends on task-021 | task-021, then task-039 |
| 271 | `tests/canonical/test-connector-consumption-linkage.sh` | task-021, task-040 | task-040 depends on task-021 | task-021, then task-040 |
| 272 | `tests/canonical/test-connector-consumption-linkage.sh` | task-021, task-042 | task-042 depends on task-021 | task-021, then task-042 |
| 273 | `tests/canonical/test-connector-consumption-linkage.sh` | task-021, task-043 | task-043 depends on task-021 | task-021, then task-043 |
| 274 | `tests/canonical/test-connector-consumption-linkage.sh` | task-021, task-044 | task-044 depends on task-021 | task-021, then task-044 |
| 275 | `tests/canonical/test-connector-consumption-linkage.sh` | task-038, task-039 | independent | task-038 and task-039 in either order; run after both are done, in number order (task-038 then task-039) |
| 276 | `tests/canonical/test-connector-consumption-linkage.sh` | task-038, task-040 | independent | task-038 and task-040 in either order; run after both are done, in number order (task-038 then task-040) |
| 277 | `tests/canonical/test-connector-consumption-linkage.sh` | task-038, task-042 | independent | task-038 and task-042 in either order; run after both are done, in number order (task-038 then task-042) |
| 278 | `tests/canonical/test-connector-consumption-linkage.sh` | task-038, task-043 | independent | task-038 and task-043 in either order; run after both are done, in number order (task-038 then task-043) |
| 279 | `tests/canonical/test-connector-consumption-linkage.sh` | task-038, task-044 | independent | task-038 and task-044 in either order; run after both are done, in number order (task-038 then task-044) |
| 280 | `tests/canonical/test-connector-consumption-linkage.sh` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 281 | `tests/canonical/test-connector-consumption-linkage.sh` | task-039, task-042 | independent | task-039 and task-042 in either order; run after both are done, in number order (task-039 then task-042) |
| 282 | `tests/canonical/test-connector-consumption-linkage.sh` | task-039, task-043 | independent | task-039 and task-043 in either order; run after both are done, in number order (task-039 then task-043) |
| 283 | `tests/canonical/test-connector-consumption-linkage.sh` | task-039, task-044 | independent | task-039 and task-044 in either order; run after both are done, in number order (task-039 then task-044) |
| 284 | `tests/canonical/test-connector-consumption-linkage.sh` | task-040, task-042 | independent | task-040 and task-042 in either order; run after both are done, in number order (task-040 then task-042) |
| 285 | `tests/canonical/test-connector-consumption-linkage.sh` | task-040, task-043 | independent | task-040 and task-043 in either order; run after both are done, in number order (task-040 then task-043) |
| 286 | `tests/canonical/test-connector-consumption-linkage.sh` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 287 | `tests/canonical/test-connector-consumption-linkage.sh` | task-042, task-043 | independent | task-042 and task-043 in either order; run after both are done, in number order (task-042 then task-043) |
| 288 | `tests/canonical/test-connector-consumption-linkage.sh` | task-042, task-044 | independent | task-042 and task-044 in either order; run after both are done, in number order (task-042 then task-044) |
| 289 | `tests/canonical/test-connector-consumption-linkage.sh` | task-043, task-044 | independent | task-043 and task-044 in either order; run after both are done, in number order (task-043 then task-044) |
| 290 | `tests/canonical/test-connector-set-unset-lifecycle.sh` | task-043, task-057 | task-057 depends on task-043 | task-043, then task-057 |
| 291 | `tests/canonical/test-connector-skills-structural.sh` | task-032, task-041 | independent | task-032 and task-041 in either order; run after both are done, in number order (task-032 then task-041) |
| 292 | `tests/canonical/test-connector-skills-structural.sh` | task-032, task-042 | independent | task-032 and task-042 in either order; run after both are done, in number order (task-032 then task-042) |
| 293 | `tests/canonical/test-connector-skills-structural.sh` | task-032, task-043 | independent | task-032 and task-043 in either order; run after both are done, in number order (task-032 then task-043) |
| 294 | `tests/canonical/test-connector-skills-structural.sh` | task-041, task-042 | independent | task-041 and task-042 in either order; run after both are done, in number order (task-041 then task-042) |
| 295 | `tests/canonical/test-connector-skills-structural.sh` | task-041, task-043 | independent | task-041 and task-043 in either order; run after both are done, in number order (task-041 then task-043) |
| 296 | `tests/canonical/test-connector-skills-structural.sh` | task-042, task-043 | independent | task-042 and task-043 in either order; run after both are done, in number order (task-042 then task-043) |
| 297 | `tests/canonical/test-conversation-runner.sh` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 298 | `tests/canonical/test-conversation-runner.sh` | task-040, task-056 | task-056 depends on task-040 | task-040, then task-056 |
| 299 | `tests/canonical/test-conversation-runner.sh` | task-040, task-057 | task-057 depends on task-040 | task-040, then task-057 |
| 300 | `tests/canonical/test-conversation-runner.sh` | task-044, task-056 | task-056 depends on task-044 | task-044, then task-056 |
| 301 | `tests/canonical/test-conversation-runner.sh` | task-044, task-057 | task-057 depends on task-044 | task-044, then task-057 |
| 302 | `tests/canonical/test-conversation-runner.sh` | task-056, task-057 | task-057 depends on task-056 | task-056, then task-057 |
| 303 | `tests/canonical/test-create-family-scaffold.sh` | task-032, task-037 | independent | task-032 and task-037 in either order; run after both are done, in number order (task-032 then task-037) |
| 304 | `tests/canonical/test-create-family-scaffold.sh` | task-032, task-040 | independent | task-032 and task-040 in either order; run after both are done, in number order (task-032 then task-040) |
| 305 | `tests/canonical/test-create-family-scaffold.sh` | task-032, task-044 | independent | task-032 and task-044 in either order; run after both are done, in number order (task-032 then task-044) |
| 306 | `tests/canonical/test-create-family-scaffold.sh` | task-037, task-040 | independent | task-037 and task-040 in either order; run after both are done, in number order (task-037 then task-040) |
| 307 | `tests/canonical/test-create-family-scaffold.sh` | task-037, task-044 | independent | task-037 and task-044 in either order; run after both are done, in number order (task-037 then task-044) |
| 308 | `tests/canonical/test-create-family-scaffold.sh` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 309 | `tests/canonical/test-cutover-no-dangling.sh` | task-021, task-038 | task-038 depends on task-021 | task-021, then task-038 |
| 310 | `tests/canonical/test-cutover-no-dangling.sh` | task-021, task-041 | task-041 depends on task-021 | task-021, then task-041 |
| 311 | `tests/canonical/test-cutover-no-dangling.sh` | task-021, task-044 | task-044 depends on task-021 | task-021, then task-044 |
| 312 | `tests/canonical/test-cutover-no-dangling.sh` | task-038, task-041 | independent | task-038 and task-041 in either order; run after both are done, in number order (task-038 then task-041) |
| 313 | `tests/canonical/test-cutover-no-dangling.sh` | task-038, task-044 | independent | task-038 and task-044 in either order; run after both are done, in number order (task-038 then task-044) |
| 314 | `tests/canonical/test-cutover-no-dangling.sh` | task-041, task-044 | independent | task-041 and task-044 in either order; run after both are done, in number order (task-041 then task-044) |
| 315 | `tests/canonical/test-dashboard-manifest.sh` | task-031, task-033 | task-033 depends on task-031 | task-031, then task-033 |
| 316 | `tests/canonical/test-dashboard-manifest.sh` | task-031, task-056 | task-056 depends on task-031 | task-031, then task-056 |
| 317 | `tests/canonical/test-dashboard-manifest.sh` | task-033, task-056 | task-056 depends on task-033 | task-033, then task-056 |
| 318 | `tests/canonical/test-dashboard-parity-h.sh` | task-031, task-033 | task-033 depends on task-031 | task-031, then task-033 |
| 319 | `tests/canonical/test-delivery-gate-aggregate.sh` | task-021, task-025 | task-025 depends on task-021 | task-021, then task-025 |
| 320 | `tests/canonical/test-delivery-gate-aggregate.sh` | task-021, task-040 | task-040 depends on task-021 | task-021, then task-040 |
| 321 | `tests/canonical/test-delivery-gate-aggregate.sh` | task-025, task-040 | task-040 depends on task-025 | task-025, then task-040 |
| 322 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-032, task-037 | independent | task-032 and task-037 in either order; run after both are done, in number order (task-032 then task-037) |
| 323 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-032, task-038 | independent | task-032 and task-038 in either order; run after both are done, in number order (task-032 then task-038) |
| 324 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-032, task-040 | independent | task-032 and task-040 in either order; run after both are done, in number order (task-032 then task-040) |
| 325 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-032, task-042 | independent | task-032 and task-042 in either order; run after both are done, in number order (task-032 then task-042) |
| 326 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-032, task-043 | independent | task-032 and task-043 in either order; run after both are done, in number order (task-032 then task-043) |
| 327 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-032, task-044 | independent | task-032 and task-044 in either order; run after both are done, in number order (task-032 then task-044) |
| 328 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-032, task-049 | task-049 depends on task-032 | task-032, then task-049 |
| 329 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-037, task-038 | independent | task-037 and task-038 in either order; run after both are done, in number order (task-037 then task-038) |
| 330 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-037, task-040 | independent | task-037 and task-040 in either order; run after both are done, in number order (task-037 then task-040) |
| 331 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-037, task-042 | independent | task-037 and task-042 in either order; run after both are done, in number order (task-037 then task-042) |
| 332 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-037, task-043 | independent | task-037 and task-043 in either order; run after both are done, in number order (task-037 then task-043) |
| 333 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-037, task-044 | independent | task-037 and task-044 in either order; run after both are done, in number order (task-037 then task-044) |
| 334 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-037, task-049 | task-049 depends on task-037 | task-037, then task-049 |
| 335 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-038, task-040 | independent | task-038 and task-040 in either order; run after both are done, in number order (task-038 then task-040) |
| 336 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-038, task-042 | independent | task-038 and task-042 in either order; run after both are done, in number order (task-038 then task-042) |
| 337 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-038, task-043 | independent | task-038 and task-043 in either order; run after both are done, in number order (task-038 then task-043) |
| 338 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-038, task-044 | independent | task-038 and task-044 in either order; run after both are done, in number order (task-038 then task-044) |
| 339 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-038, task-049 | task-049 depends on task-038 | task-038, then task-049 |
| 340 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-040, task-042 | independent | task-040 and task-042 in either order; run after both are done, in number order (task-040 then task-042) |
| 341 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-040, task-043 | independent | task-040 and task-043 in either order; run after both are done, in number order (task-040 then task-043) |
| 342 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 343 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-040, task-049 | task-049 depends on task-040 | task-040, then task-049 |
| 344 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-042, task-043 | independent | task-042 and task-043 in either order; run after both are done, in number order (task-042 then task-043) |
| 345 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-042, task-044 | independent | task-042 and task-044 in either order; run after both are done, in number order (task-042 then task-044) |
| 346 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-042, task-049 | task-049 depends on task-042 | task-042, then task-049 |
| 347 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-043, task-044 | independent | task-043 and task-044 in either order; run after both are done, in number order (task-043 then task-044) |
| 348 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-043, task-049 | task-049 depends on task-043 | task-043, then task-049 |
| 349 | `tests/canonical/test-deploy-monitor-repurpose.sh` | task-044, task-049 | task-049 depends on task-044 | task-044, then task-049 |
| 350 | `tests/canonical/test-derive-waves.sh` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 351 | `tests/canonical/test-describe-full-only.sh` | task-021, task-038 | task-038 depends on task-021 | task-021, then task-038 |
| 352 | `tests/canonical/test-describe-full-only.sh` | task-021, task-044 | task-044 depends on task-021 | task-021, then task-044 |
| 353 | `tests/canonical/test-describe-full-only.sh` | task-038, task-044 | independent | task-038 and task-044 in either order; run after both are done, in number order (task-038 then task-044) |
| 354 | `tests/canonical/test-discovery-doc-ownership.sh` | task-041, task-044 | independent | task-041 and task-044 in either order; run after both are done, in number order (task-041 then task-044) |
| 355 | `tests/canonical/test-discovery-doc-ownership.sh` | task-041, task-057 | task-057 depends on task-041 | task-041, then task-057 |
| 356 | `tests/canonical/test-discovery-doc-ownership.sh` | task-044, task-057 | task-057 depends on task-044 | task-044, then task-057 |
| 357 | `tests/canonical/test-doc-set-mapping.sh` | task-041, task-044 | independent | task-041 and task-044 in either order; run after both are done, in number order (task-041 then task-044) |
| 358 | `tests/canonical/test-doc-set-mapping.sh` | task-041, task-045 | independent | task-041 and task-045 in either order; run after both are done, in number order (task-041 then task-045) |
| 359 | `tests/canonical/test-doc-set-mapping.sh` | task-041, task-049 | task-049 depends on task-041 | task-041, then task-049 |
| 360 | `tests/canonical/test-doc-set-mapping.sh` | task-041, task-057 | task-057 depends on task-041 | task-041, then task-057 |
| 361 | `tests/canonical/test-doc-set-mapping.sh` | task-044, task-045 | independent | task-044 and task-045 in either order; run after both are done, in number order (task-044 then task-045) |
| 362 | `tests/canonical/test-doc-set-mapping.sh` | task-044, task-049 | task-049 depends on task-044 | task-044, then task-049 |
| 363 | `tests/canonical/test-doc-set-mapping.sh` | task-044, task-057 | task-057 depends on task-044 | task-044, then task-057 |
| 364 | `tests/canonical/test-doc-set-mapping.sh` | task-045, task-049 | independent | task-045 and task-049 in either order; run after both are done, in number order (task-045 then task-049) |
| 365 | `tests/canonical/test-doc-set-mapping.sh` | task-045, task-057 | task-057 depends on task-045 | task-045, then task-057 |
| 366 | `tests/canonical/test-doc-set-mapping.sh` | task-049, task-057 | task-057 depends on task-049 | task-049, then task-057 |
| 367 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-041, task-044 | independent | task-041 and task-044 in either order; run after both are done, in number order (task-041 then task-044) |
| 368 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-041, task-045 | independent | task-041 and task-045 in either order; run after both are done, in number order (task-041 then task-045) |
| 369 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-041, task-049 | task-049 depends on task-041 | task-041, then task-049 |
| 370 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-041, task-057 | task-057 depends on task-041 | task-041, then task-057 |
| 371 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-044, task-045 | independent | task-044 and task-045 in either order; run after both are done, in number order (task-044 then task-045) |
| 372 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-044, task-049 | task-049 depends on task-044 | task-044, then task-049 |
| 373 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-044, task-057 | task-057 depends on task-044 | task-044, then task-057 |
| 374 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-045, task-049 | independent | task-045 and task-049 in either order; run after both are done, in number order (task-045 then task-049) |
| 375 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-045, task-057 | task-057 depends on task-045 | task-045, then task-057 |
| 376 | `tests/canonical/test-doc-set-propose-confirm.sh` | task-049, task-057 | task-057 depends on task-049 | task-049, then task-057 |
| 377 | `tests/canonical/test-doc-set-read.sh` | task-041, task-044 | independent | task-041 and task-044 in either order; run after both are done, in number order (task-041 then task-044) |
| 378 | `tests/canonical/test-doc-set-read.sh` | task-041, task-049 | task-049 depends on task-041 | task-041, then task-049 |
| 379 | `tests/canonical/test-doc-set-read.sh` | task-044, task-049 | task-049 depends on task-044 | task-044, then task-049 |
| 380 | `tests/canonical/test-document-family-scaffold.sh` | task-032, task-037 | independent | task-032 and task-037 in either order; run after both are done, in number order (task-032 then task-037) |
| 381 | `tests/canonical/test-document-family-scaffold.sh` | task-032, task-040 | independent | task-032 and task-040 in either order; run after both are done, in number order (task-032 then task-040) |
| 382 | `tests/canonical/test-document-family-scaffold.sh` | task-032, task-043 | independent | task-032 and task-043 in either order; run after both are done, in number order (task-032 then task-043) |
| 383 | `tests/canonical/test-document-family-scaffold.sh` | task-032, task-044 | independent | task-032 and task-044 in either order; run after both are done, in number order (task-032 then task-044) |
| 384 | `tests/canonical/test-document-family-scaffold.sh` | task-037, task-040 | independent | task-037 and task-040 in either order; run after both are done, in number order (task-037 then task-040) |
| 385 | `tests/canonical/test-document-family-scaffold.sh` | task-037, task-043 | independent | task-037 and task-043 in either order; run after both are done, in number order (task-037 then task-043) |
| 386 | `tests/canonical/test-document-family-scaffold.sh` | task-037, task-044 | independent | task-037 and task-044 in either order; run after both are done, in number order (task-037 then task-044) |
| 387 | `tests/canonical/test-document-family-scaffold.sh` | task-040, task-043 | independent | task-040 and task-043 in either order; run after both are done, in number order (task-040 then task-043) |
| 388 | `tests/canonical/test-document-family-scaffold.sh` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 389 | `tests/canonical/test-document-family-scaffold.sh` | task-043, task-044 | independent | task-043 and task-044 in either order; run after both are done, in number order (task-043 then task-044) |
| 390 | `tests/canonical/test-dogfood-byte-identity.sh` | task-032, task-042 | independent | task-032 and task-042 in either order; run after both are done, in number order (task-032 then task-042) |
| 391 | `tests/canonical/test-domain-doc-matrix.sh` | task-041, task-045 | independent | task-041 and task-045 in either order; run after both are done, in number order (task-041 then task-045) |
| 392 | `tests/canonical/test-downstream-worktree-entry.sh` | task-037, task-039 | independent | task-037 and task-039 in either order; run after both are done, in number order (task-037 then task-039) |
| 393 | `tests/canonical/test-downstream-worktree-entry.sh` | task-037, task-040 | independent | task-037 and task-040 in either order; run after both are done, in number order (task-037 then task-040) |
| 394 | `tests/canonical/test-downstream-worktree-entry.sh` | task-037, task-043 | independent | task-037 and task-043 in either order; run after both are done, in number order (task-037 then task-043) |
| 395 | `tests/canonical/test-downstream-worktree-entry.sh` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 396 | `tests/canonical/test-downstream-worktree-entry.sh` | task-039, task-043 | independent | task-039 and task-043 in either order; run after both are done, in number order (task-039 then task-043) |
| 397 | `tests/canonical/test-downstream-worktree-entry.sh` | task-040, task-043 | independent | task-040 and task-043 in either order; run after both are done, in number order (task-040 then task-043) |
| 398 | `tests/canonical/test-essence-capture.sh` | task-045, task-049 | independent | task-045 and task-049 in either order; run after both are done, in number order (task-045 then task-049) |
| 399 | `tests/canonical/test-expectations-single-source.sh` | task-041, task-044 | independent | task-041 and task-044 in either order; run after both are done, in number order (task-041 then task-044) |
| 400 | `tests/canonical/test-expectations-single-source.sh` | task-041, task-049 | task-049 depends on task-041 | task-041, then task-049 |
| 401 | `tests/canonical/test-expectations-single-source.sh` | task-044, task-049 | task-049 depends on task-044 | task-044, then task-049 |
| 402 | `tests/canonical/test-fix-family-scaffold.sh` | task-037, task-040 | independent | task-037 and task-040 in either order; run after both are done, in number order (task-037 then task-040) |
| 403 | `tests/canonical/test-fix-family-scaffold.sh` | task-037, task-044 | independent | task-037 and task-044 in either order; run after both are done, in number order (task-037 then task-044) |
| 404 | `tests/canonical/test-fix-family-scaffold.sh` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 405 | `tests/canonical/test-frontmatter-lint.sh` | task-049, task-057 | task-057 depends on task-049 | task-049, then task-057 |
| 406 | `tests/canonical/test-grade-summary.sh` | task-033, task-041 | independent | task-033 and task-041 in either order; run after both are done, in number order (task-033 then task-041) |
| 407 | `tests/canonical/test-grade-summary.sh` | task-033, task-042 | independent | task-033 and task-042 in either order; run after both are done, in number order (task-033 then task-042) |
| 408 | `tests/canonical/test-grade-summary.sh` | task-033, task-044 | independent | task-033 and task-044 in either order; run after both are done, in number order (task-033 then task-044) |
| 409 | `tests/canonical/test-grade-summary.sh` | task-033, task-045 | independent | task-033 and task-045 in either order; run after both are done, in number order (task-033 then task-045) |
| 410 | `tests/canonical/test-grade-summary.sh` | task-033, task-049 | independent | task-033 and task-049 in either order; run after both are done, in number order (task-033 then task-049) |
| 411 | `tests/canonical/test-grade-summary.sh` | task-033, task-057 | task-057 depends on task-033 | task-033, then task-057 |
| 412 | `tests/canonical/test-grade-summary.sh` | task-041, task-042 | independent | task-041 and task-042 in either order; run after both are done, in number order (task-041 then task-042) |
| 413 | `tests/canonical/test-grade-summary.sh` | task-041, task-044 | independent | task-041 and task-044 in either order; run after both are done, in number order (task-041 then task-044) |
| 414 | `tests/canonical/test-grade-summary.sh` | task-041, task-045 | independent | task-041 and task-045 in either order; run after both are done, in number order (task-041 then task-045) |
| 415 | `tests/canonical/test-grade-summary.sh` | task-041, task-049 | task-049 depends on task-041 | task-041, then task-049 |
| 416 | `tests/canonical/test-grade-summary.sh` | task-041, task-057 | task-057 depends on task-041 | task-041, then task-057 |
| 417 | `tests/canonical/test-grade-summary.sh` | task-042, task-044 | independent | task-042 and task-044 in either order; run after both are done, in number order (task-042 then task-044) |
| 418 | `tests/canonical/test-grade-summary.sh` | task-042, task-045 | independent | task-042 and task-045 in either order; run after both are done, in number order (task-042 then task-045) |
| 419 | `tests/canonical/test-grade-summary.sh` | task-042, task-049 | task-049 depends on task-042 | task-042, then task-049 |
| 420 | `tests/canonical/test-grade-summary.sh` | task-042, task-057 | task-057 depends on task-042 | task-042, then task-057 |
| 421 | `tests/canonical/test-grade-summary.sh` | task-044, task-045 | independent | task-044 and task-045 in either order; run after both are done, in number order (task-044 then task-045) |
| 422 | `tests/canonical/test-grade-summary.sh` | task-044, task-049 | task-049 depends on task-044 | task-044, then task-049 |
| 423 | `tests/canonical/test-grade-summary.sh` | task-044, task-057 | task-057 depends on task-044 | task-044, then task-057 |
| 424 | `tests/canonical/test-grade-summary.sh` | task-045, task-049 | independent | task-045 and task-049 in either order; run after both are done, in number order (task-045 then task-049) |
| 425 | `tests/canonical/test-grade-summary.sh` | task-045, task-057 | task-057 depends on task-045 | task-045, then task-057 |
| 426 | `tests/canonical/test-grade-summary.sh` | task-049, task-057 | task-057 depends on task-049 | task-049, then task-057 |
| 427 | `tests/canonical/test-guardrails-d012.sh` | task-033, task-042 | independent | task-033 and task-042 in either order; run after both are done, in number order (task-033 then task-042) |
| 428 | `tests/canonical/test-guardrails-d012.sh` | task-033, task-057 | task-057 depends on task-033 | task-033, then task-057 |
| 429 | `tests/canonical/test-guardrails-d012.sh` | task-042, task-057 | task-057 depends on task-042 | task-042, then task-057 |
| 430 | `tests/canonical/test-kb-html-claims-check.sh` | task-021, task-049 | task-049 depends on task-021 | task-021, then task-049 |
| 431 | `tests/canonical/test-kb-review-surface.sh` | task-041, task-045 | independent | task-041 and task-045 in either order; run after both are done, in number order (task-041 then task-045) |
| 432 | `tests/canonical/test-kb-review-surface.sh` | task-041, task-049 | task-049 depends on task-041 | task-041, then task-049 |
| 433 | `tests/canonical/test-kb-review-surface.sh` | task-041, task-057 | task-057 depends on task-041 | task-041, then task-057 |
| 434 | `tests/canonical/test-kb-review-surface.sh` | task-045, task-049 | independent | task-045 and task-049 in either order; run after both are done, in number order (task-045 then task-049) |
| 435 | `tests/canonical/test-kb-review-surface.sh` | task-045, task-057 | task-057 depends on task-045 | task-045, then task-057 |
| 436 | `tests/canonical/test-kb-review-surface.sh` | task-049, task-057 | task-057 depends on task-049 | task-049, then task-057 |
| 437 | `tests/canonical/test-ledger-isolation.sh` | task-041, task-042 | independent | task-041 and task-042 in either order; run after both are done, in number order (task-041 then task-042) |
| 438 | `tests/canonical/test-multitool-isolation.sh` | task-040, task-042 | independent | task-040 and task-042 in either order; run after both are done, in number order (task-040 then task-042) |
| 439 | `tests/canonical/test-output-root-isolation.sh` | task-041, task-042 | independent | task-041 and task-042 in either order; run after both are done, in number order (task-041 then task-042) |
| 440 | `tests/canonical/test-output-root-isolation.sh` | task-041, task-045 | independent | task-041 and task-045 in either order; run after both are done, in number order (task-041 then task-045) |
| 441 | `tests/canonical/test-output-root-isolation.sh` | task-042, task-045 | independent | task-042 and task-045 in either order; run after both are done, in number order (task-042 then task-045) |
| 442 | `tests/canonical/test-path-fixtures.sh` | task-038, task-041 | independent | task-038 and task-041 in either order; run after both are done, in number order (task-038 then task-041) |
| 443 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-025, task-038 | task-038 depends on task-025 | task-025, then task-038 |
| 444 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-025, task-039 | task-039 depends on task-025 | task-025, then task-039 |
| 445 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-025, task-040 | task-040 depends on task-025 | task-025, then task-040 |
| 446 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-025, task-043 | task-043 depends on task-025 | task-025, then task-043 |
| 447 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-038, task-039 | independent | task-038 and task-039 in either order; run after both are done, in number order (task-038 then task-039) |
| 448 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-038, task-040 | independent | task-038 and task-040 in either order; run after both are done, in number order (task-038 then task-040) |
| 449 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-038, task-043 | independent | task-038 and task-043 in either order; run after both are done, in number order (task-038 then task-043) |
| 450 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 451 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-039, task-043 | independent | task-039 and task-043 in either order; run after both are done, in number order (task-039 then task-043) |
| 452 | `tests/canonical/test-pipeline-status-walkthrough.sh` | task-040, task-043 | independent | task-040 and task-043 in either order; run after both are done, in number order (task-040 then task-043) |
| 453 | `tests/canonical/test-prototype-family-scaffold.sh` | task-032, task-037 | independent | task-032 and task-037 in either order; run after both are done, in number order (task-032 then task-037) |
| 454 | `tests/canonical/test-prototype-family-scaffold.sh` | task-032, task-040 | independent | task-032 and task-040 in either order; run after both are done, in number order (task-032 then task-040) |
| 455 | `tests/canonical/test-prototype-family-scaffold.sh` | task-032, task-044 | independent | task-032 and task-044 in either order; run after both are done, in number order (task-032 then task-044) |
| 456 | `tests/canonical/test-prototype-family-scaffold.sh` | task-037, task-040 | independent | task-037 and task-040 in either order; run after both are done, in number order (task-037 then task-040) |
| 457 | `tests/canonical/test-prototype-family-scaffold.sh` | task-037, task-044 | independent | task-037 and task-044 in either order; run after both are done, in number order (task-037 then task-044) |
| 458 | `tests/canonical/test-prototype-family-scaffold.sh` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 459 | `tests/canonical/test-reconcile-scenarios.sh` | task-041, task-057 | task-057 depends on task-041 | task-041, then task-057 |
| 460 | `tests/canonical/test-release-install-e2e.sh` | task-032, task-044 | independent | task-032 and task-044 in either order; run after both are done, in number order (task-032 then task-044) |
| 461 | `tests/canonical/test-release-install-e2e.sh` | task-032, task-056 | task-056 depends on task-032 | task-032, then task-056 |
| 462 | `tests/canonical/test-release-install-e2e.sh` | task-044, task-056 | task-056 depends on task-044 | task-044, then task-056 |
| 463 | `tests/canonical/test-release-migrate-smoke.sh` | task-033, task-056 | task-056 depends on task-033 | task-033, then task-056 |
| 464 | `tests/canonical/test-review-path-audit.sh` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 465 | `tests/canonical/test-scoped-review-cycles.sh` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 466 | `tests/canonical/test-shared-install.sh` | task-032, task-056 | task-056 depends on task-032 | task-032, then task-056 |
| 467 | `tests/canonical/test-shared-prune.sh` | task-039, task-042 | independent | task-039 and task-042 in either order; run after both are done, in number order (task-039 then task-042) |
| 468 | `tests/canonical/test-shortcut-engine-contract.sh` | task-025, task-037 | task-037 depends on task-025 | task-025, then task-037 |
| 469 | `tests/canonical/test-shortcut-engine-contract.sh` | task-025, task-056 | task-056 depends on task-025 | task-025, then task-056 |
| 470 | `tests/canonical/test-shortcut-engine-contract.sh` | task-037, task-056 | task-056 depends on task-037 | task-037, then task-056 |
| 471 | `tests/canonical/test-spine-depth-coverage.sh` | task-041, task-049 | task-049 depends on task-041 | task-041, then task-049 |
| 472 | `tests/canonical/test-state-review-surface.sh` | task-021, task-025 | task-025 depends on task-021 | task-021, then task-025 |
| 473 | `tests/canonical/test-state-review-surface.sh` | task-021, task-037 | task-037 depends on task-021 | task-021, then task-037 |
| 474 | `tests/canonical/test-state-review-surface.sh` | task-021, task-039 | task-039 depends on task-021 | task-021, then task-039 |
| 475 | `tests/canonical/test-state-review-surface.sh` | task-021, task-040 | task-040 depends on task-021 | task-021, then task-040 |
| 476 | `tests/canonical/test-state-review-surface.sh` | task-021, task-041 | task-041 depends on task-021 | task-021, then task-041 |
| 477 | `tests/canonical/test-state-review-surface.sh` | task-025, task-037 | task-037 depends on task-025 | task-025, then task-037 |
| 478 | `tests/canonical/test-state-review-surface.sh` | task-025, task-039 | task-039 depends on task-025 | task-025, then task-039 |
| 479 | `tests/canonical/test-state-review-surface.sh` | task-025, task-040 | task-040 depends on task-025 | task-025, then task-040 |
| 480 | `tests/canonical/test-state-review-surface.sh` | task-025, task-041 | task-041 depends on task-025 | task-025, then task-041 |
| 481 | `tests/canonical/test-state-review-surface.sh` | task-037, task-039 | independent | task-037 and task-039 in either order; run after both are done, in number order (task-037 then task-039) |
| 482 | `tests/canonical/test-state-review-surface.sh` | task-037, task-040 | independent | task-037 and task-040 in either order; run after both are done, in number order (task-037 then task-040) |
| 483 | `tests/canonical/test-state-review-surface.sh` | task-037, task-041 | independent | task-037 and task-041 in either order; run after both are done, in number order (task-037 then task-041) |
| 484 | `tests/canonical/test-state-review-surface.sh` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 485 | `tests/canonical/test-state-review-surface.sh` | task-039, task-041 | independent | task-039 and task-041 in either order; run after both are done, in number order (task-039 then task-041) |
| 486 | `tests/canonical/test-state-review-surface.sh` | task-040, task-041 | independent | task-040 and task-041 in either order; run after both are done, in number order (task-040 then task-041) |
| 487 | `tests/canonical/test-summarize-preflight.sh` | task-041, task-049 | task-049 depends on task-041 | task-041, then task-049 |
| 488 | `tests/canonical/test-task-state-transitions.sh` | task-021, task-025 | task-025 depends on task-021 | task-021, then task-025 |
| 489 | `tests/canonical/test-task-state-transitions.sh` | task-021, task-031 | task-031 depends on task-021 | task-021, then task-031 |
| 490 | `tests/canonical/test-task-state-transitions.sh` | task-021, task-040 | task-040 depends on task-021 | task-021, then task-040 |
| 491 | `tests/canonical/test-task-state-transitions.sh` | task-025, task-031 | task-025 depends on task-031 | task-031, then task-025 |
| 492 | `tests/canonical/test-task-state-transitions.sh` | task-025, task-040 | task-040 depends on task-025 | task-025, then task-040 |
| 493 | `tests/canonical/test-task-state-transitions.sh` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 494 | `tests/canonical/test-test-experiment-family-scaffold.sh` | task-037, task-040 | independent | task-037 and task-040 in either order; run after both are done, in number order (task-037 then task-040) |
| 495 | `tests/canonical/test-test-experiment-family-scaffold.sh` | task-037, task-044 | independent | task-037 and task-044 in either order; run after both are done, in number order (task-037 then task-044) |
| 496 | `tests/canonical/test-test-experiment-family-scaffold.sh` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 497 | `tests/canonical/test-ticket-retirement-structural.sh` | task-021, task-037 | task-037 depends on task-021 | task-021, then task-037 |
| 498 | `tests/canonical/test-ticket-retirement-structural.sh` | task-021, task-038 | task-038 depends on task-021 | task-021, then task-038 |
| 499 | `tests/canonical/test-ticket-retirement-structural.sh` | task-021, task-039 | task-039 depends on task-021 | task-021, then task-039 |
| 500 | `tests/canonical/test-ticket-retirement-structural.sh` | task-021, task-040 | task-040 depends on task-021 | task-021, then task-040 |
| 501 | `tests/canonical/test-ticket-retirement-structural.sh` | task-021, task-041 | task-041 depends on task-021 | task-021, then task-041 |
| 502 | `tests/canonical/test-ticket-retirement-structural.sh` | task-021, task-042 | task-042 depends on task-021 | task-021, then task-042 |
| 503 | `tests/canonical/test-ticket-retirement-structural.sh` | task-021, task-043 | task-043 depends on task-021 | task-021, then task-043 |
| 504 | `tests/canonical/test-ticket-retirement-structural.sh` | task-021, task-044 | task-044 depends on task-021 | task-021, then task-044 |
| 505 | `tests/canonical/test-ticket-retirement-structural.sh` | task-037, task-038 | independent | task-037 and task-038 in either order; run after both are done, in number order (task-037 then task-038) |
| 506 | `tests/canonical/test-ticket-retirement-structural.sh` | task-037, task-039 | independent | task-037 and task-039 in either order; run after both are done, in number order (task-037 then task-039) |
| 507 | `tests/canonical/test-ticket-retirement-structural.sh` | task-037, task-040 | independent | task-037 and task-040 in either order; run after both are done, in number order (task-037 then task-040) |
| 508 | `tests/canonical/test-ticket-retirement-structural.sh` | task-037, task-041 | independent | task-037 and task-041 in either order; run after both are done, in number order (task-037 then task-041) |
| 509 | `tests/canonical/test-ticket-retirement-structural.sh` | task-037, task-042 | independent | task-037 and task-042 in either order; run after both are done, in number order (task-037 then task-042) |
| 510 | `tests/canonical/test-ticket-retirement-structural.sh` | task-037, task-043 | independent | task-037 and task-043 in either order; run after both are done, in number order (task-037 then task-043) |
| 511 | `tests/canonical/test-ticket-retirement-structural.sh` | task-037, task-044 | independent | task-037 and task-044 in either order; run after both are done, in number order (task-037 then task-044) |
| 512 | `tests/canonical/test-ticket-retirement-structural.sh` | task-038, task-039 | independent | task-038 and task-039 in either order; run after both are done, in number order (task-038 then task-039) |
| 513 | `tests/canonical/test-ticket-retirement-structural.sh` | task-038, task-040 | independent | task-038 and task-040 in either order; run after both are done, in number order (task-038 then task-040) |
| 514 | `tests/canonical/test-ticket-retirement-structural.sh` | task-038, task-041 | independent | task-038 and task-041 in either order; run after both are done, in number order (task-038 then task-041) |
| 515 | `tests/canonical/test-ticket-retirement-structural.sh` | task-038, task-042 | independent | task-038 and task-042 in either order; run after both are done, in number order (task-038 then task-042) |
| 516 | `tests/canonical/test-ticket-retirement-structural.sh` | task-038, task-043 | independent | task-038 and task-043 in either order; run after both are done, in number order (task-038 then task-043) |
| 517 | `tests/canonical/test-ticket-retirement-structural.sh` | task-038, task-044 | independent | task-038 and task-044 in either order; run after both are done, in number order (task-038 then task-044) |
| 518 | `tests/canonical/test-ticket-retirement-structural.sh` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 519 | `tests/canonical/test-ticket-retirement-structural.sh` | task-039, task-041 | independent | task-039 and task-041 in either order; run after both are done, in number order (task-039 then task-041) |
| 520 | `tests/canonical/test-ticket-retirement-structural.sh` | task-039, task-042 | independent | task-039 and task-042 in either order; run after both are done, in number order (task-039 then task-042) |
| 521 | `tests/canonical/test-ticket-retirement-structural.sh` | task-039, task-043 | independent | task-039 and task-043 in either order; run after both are done, in number order (task-039 then task-043) |
| 522 | `tests/canonical/test-ticket-retirement-structural.sh` | task-039, task-044 | independent | task-039 and task-044 in either order; run after both are done, in number order (task-039 then task-044) |
| 523 | `tests/canonical/test-ticket-retirement-structural.sh` | task-040, task-041 | independent | task-040 and task-041 in either order; run after both are done, in number order (task-040 then task-041) |
| 524 | `tests/canonical/test-ticket-retirement-structural.sh` | task-040, task-042 | independent | task-040 and task-042 in either order; run after both are done, in number order (task-040 then task-042) |
| 525 | `tests/canonical/test-ticket-retirement-structural.sh` | task-040, task-043 | independent | task-040 and task-043 in either order; run after both are done, in number order (task-040 then task-043) |
| 526 | `tests/canonical/test-ticket-retirement-structural.sh` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 527 | `tests/canonical/test-ticket-retirement-structural.sh` | task-041, task-042 | independent | task-041 and task-042 in either order; run after both are done, in number order (task-041 then task-042) |
| 528 | `tests/canonical/test-ticket-retirement-structural.sh` | task-041, task-043 | independent | task-041 and task-043 in either order; run after both are done, in number order (task-041 then task-043) |
| 529 | `tests/canonical/test-ticket-retirement-structural.sh` | task-041, task-044 | independent | task-041 and task-044 in either order; run after both are done, in number order (task-041 then task-044) |
| 530 | `tests/canonical/test-ticket-retirement-structural.sh` | task-042, task-043 | independent | task-042 and task-043 in either order; run after both are done, in number order (task-042 then task-043) |
| 531 | `tests/canonical/test-ticket-retirement-structural.sh` | task-042, task-044 | independent | task-042 and task-044 in either order; run after both are done, in number order (task-042 then task-044) |
| 532 | `tests/canonical/test-ticket-retirement-structural.sh` | task-043, task-044 | independent | task-043 and task-044 in either order; run after both are done, in number order (task-043 then task-044) |
| 533 | `tests/canonical/test-update-kb-scope-fidelity.sh` | task-042, task-044 | independent | task-042 and task-044 in either order; run after both are done, in number order (task-042 then task-044) |
| 534 | `tests/canonical/test-validator-behavior.sh` | task-049, task-057 | task-057 depends on task-049 | task-049, then task-057 |
| 535 | `tests/canonical/test-version-sync.sh` | task-025, task-056 | task-056 depends on task-025 | task-025, then task-056 |
| 536 | `tests/canonical/test-write-connector.sh` | task-043, task-057 | task-057 depends on task-043 | task-043, then task-057 |
| 537 | `tests/conversation/fixtures/done-work/.aid/works/work-001-csv-export/STATE.yml` | task-038, task-040 | independent | task-038 and task-040 in either order; run after both are done, in number order (task-038 then task-040) |
| 538 | `tests/conversation/fixtures/ticket-mid-work/.aid/works/work-001-retry-policy/STATE.yml` | task-038, task-039 | independent | task-038 and task-039 in either order; run after both are done, in number order (task-038 then task-039) |
| 539 | `tests/conversation/samples/feature-001/001-15-no-kb-offers-preparation.md` | task-039, task-041 | independent | task-039 and task-041 in either order; run after both are done, in number order (task-039 then task-041) |
| 540 | `tests/cost-baseline.tsv` | task-030, task-032 | task-032 depends on task-030 | task-030, then task-032 |
| 541 | `tests/cost-baseline.tsv` | task-030, task-034 | task-034 depends on task-030 | task-030, then task-034 |
| 542 | `tests/cost-baseline.tsv` | task-030, task-035 | task-035 depends on task-030 | task-030, then task-035 |
| 543 | `tests/cost-baseline.tsv` | task-030, task-036 | task-036 depends on task-030 | task-030, then task-036 |
| 544 | `tests/cost-baseline.tsv` | task-030, task-037 | task-037 depends on task-030 | task-030, then task-037 |
| 545 | `tests/cost-baseline.tsv` | task-030, task-038 | task-038 depends on task-030 | task-030, then task-038 |
| 546 | `tests/cost-baseline.tsv` | task-030, task-039 | task-039 depends on task-030 | task-030, then task-039 |
| 547 | `tests/cost-baseline.tsv` | task-030, task-040 | task-040 depends on task-030 | task-030, then task-040 |
| 548 | `tests/cost-baseline.tsv` | task-030, task-041 | task-041 depends on task-030 | task-030, then task-041 |
| 549 | `tests/cost-baseline.tsv` | task-030, task-042 | task-042 depends on task-030 | task-030, then task-042 |
| 550 | `tests/cost-baseline.tsv` | task-030, task-043 | task-043 depends on task-030 | task-030, then task-043 |
| 551 | `tests/cost-baseline.tsv` | task-030, task-044 | task-044 depends on task-030 | task-030, then task-044 |
| 552 | `tests/cost-baseline.tsv` | task-030, task-045 | task-045 depends on task-030 | task-030, then task-045 |
| 553 | `tests/cost-baseline.tsv` | task-030, task-049 | task-049 depends on task-030 | task-030, then task-049 |
| 554 | `tests/cost-baseline.tsv` | task-030, task-057 | task-057 depends on task-030 | task-030, then task-057 |
| 555 | `tests/cost-baseline.tsv` | task-032, task-034 | independent | task-032 and task-034 in either order; run after both are done, in number order (task-032 then task-034) |
| 556 | `tests/cost-baseline.tsv` | task-032, task-035 | independent | task-032 and task-035 in either order; run after both are done, in number order (task-032 then task-035) |
| 557 | `tests/cost-baseline.tsv` | task-032, task-036 | independent | task-032 and task-036 in either order; run after both are done, in number order (task-032 then task-036) |
| 558 | `tests/cost-baseline.tsv` | task-032, task-037 | independent | task-032 and task-037 in either order; run after both are done, in number order (task-032 then task-037) |
| 559 | `tests/cost-baseline.tsv` | task-032, task-038 | independent | task-032 and task-038 in either order; run after both are done, in number order (task-032 then task-038) |
| 560 | `tests/cost-baseline.tsv` | task-032, task-039 | independent | task-032 and task-039 in either order; run after both are done, in number order (task-032 then task-039) |
| 561 | `tests/cost-baseline.tsv` | task-032, task-040 | independent | task-032 and task-040 in either order; run after both are done, in number order (task-032 then task-040) |
| 562 | `tests/cost-baseline.tsv` | task-032, task-041 | independent | task-032 and task-041 in either order; run after both are done, in number order (task-032 then task-041) |
| 563 | `tests/cost-baseline.tsv` | task-032, task-042 | independent | task-032 and task-042 in either order; run after both are done, in number order (task-032 then task-042) |
| 564 | `tests/cost-baseline.tsv` | task-032, task-043 | independent | task-032 and task-043 in either order; run after both are done, in number order (task-032 then task-043) |
| 565 | `tests/cost-baseline.tsv` | task-032, task-044 | independent | task-032 and task-044 in either order; run after both are done, in number order (task-032 then task-044) |
| 566 | `tests/cost-baseline.tsv` | task-032, task-045 | independent | task-032 and task-045 in either order; run after both are done, in number order (task-032 then task-045) |
| 567 | `tests/cost-baseline.tsv` | task-032, task-049 | task-049 depends on task-032 | task-032, then task-049 |
| 568 | `tests/cost-baseline.tsv` | task-032, task-057 | task-057 depends on task-032 | task-032, then task-057 |
| 569 | `tests/cost-baseline.tsv` | task-034, task-035 | independent | task-034 and task-035 in either order; run after both are done, in number order (task-034 then task-035) |
| 570 | `tests/cost-baseline.tsv` | task-034, task-036 | independent | task-034 and task-036 in either order; run after both are done, in number order (task-034 then task-036) |
| 571 | `tests/cost-baseline.tsv` | task-034, task-037 | independent | task-034 and task-037 in either order; run after both are done, in number order (task-034 then task-037) |
| 572 | `tests/cost-baseline.tsv` | task-034, task-038 | independent | task-034 and task-038 in either order; run after both are done, in number order (task-034 then task-038) |
| 573 | `tests/cost-baseline.tsv` | task-034, task-039 | independent | task-034 and task-039 in either order; run after both are done, in number order (task-034 then task-039) |
| 574 | `tests/cost-baseline.tsv` | task-034, task-040 | independent | task-034 and task-040 in either order; run after both are done, in number order (task-034 then task-040) |
| 575 | `tests/cost-baseline.tsv` | task-034, task-041 | independent | task-034 and task-041 in either order; run after both are done, in number order (task-034 then task-041) |
| 576 | `tests/cost-baseline.tsv` | task-034, task-042 | independent | task-034 and task-042 in either order; run after both are done, in number order (task-034 then task-042) |
| 577 | `tests/cost-baseline.tsv` | task-034, task-043 | independent | task-034 and task-043 in either order; run after both are done, in number order (task-034 then task-043) |
| 578 | `tests/cost-baseline.tsv` | task-034, task-044 | independent | task-034 and task-044 in either order; run after both are done, in number order (task-034 then task-044) |
| 579 | `tests/cost-baseline.tsv` | task-034, task-045 | independent | task-034 and task-045 in either order; run after both are done, in number order (task-034 then task-045) |
| 580 | `tests/cost-baseline.tsv` | task-034, task-049 | task-049 depends on task-034 | task-034, then task-049 |
| 581 | `tests/cost-baseline.tsv` | task-034, task-057 | task-057 depends on task-034 | task-034, then task-057 |
| 582 | `tests/cost-baseline.tsv` | task-035, task-036 | independent | task-035 and task-036 in either order; run after both are done, in number order (task-035 then task-036) |
| 583 | `tests/cost-baseline.tsv` | task-035, task-037 | independent | task-035 and task-037 in either order; run after both are done, in number order (task-035 then task-037) |
| 584 | `tests/cost-baseline.tsv` | task-035, task-038 | independent | task-035 and task-038 in either order; run after both are done, in number order (task-035 then task-038) |
| 585 | `tests/cost-baseline.tsv` | task-035, task-039 | independent | task-035 and task-039 in either order; run after both are done, in number order (task-035 then task-039) |
| 586 | `tests/cost-baseline.tsv` | task-035, task-040 | independent | task-035 and task-040 in either order; run after both are done, in number order (task-035 then task-040) |
| 587 | `tests/cost-baseline.tsv` | task-035, task-041 | independent | task-035 and task-041 in either order; run after both are done, in number order (task-035 then task-041) |
| 588 | `tests/cost-baseline.tsv` | task-035, task-042 | independent | task-035 and task-042 in either order; run after both are done, in number order (task-035 then task-042) |
| 589 | `tests/cost-baseline.tsv` | task-035, task-043 | independent | task-035 and task-043 in either order; run after both are done, in number order (task-035 then task-043) |
| 590 | `tests/cost-baseline.tsv` | task-035, task-044 | independent | task-035 and task-044 in either order; run after both are done, in number order (task-035 then task-044) |
| 591 | `tests/cost-baseline.tsv` | task-035, task-045 | independent | task-035 and task-045 in either order; run after both are done, in number order (task-035 then task-045) |
| 592 | `tests/cost-baseline.tsv` | task-035, task-049 | task-049 depends on task-035 | task-035, then task-049 |
| 593 | `tests/cost-baseline.tsv` | task-035, task-057 | task-057 depends on task-035 | task-035, then task-057 |
| 594 | `tests/cost-baseline.tsv` | task-036, task-037 | independent | task-036 and task-037 in either order; run after both are done, in number order (task-036 then task-037) |
| 595 | `tests/cost-baseline.tsv` | task-036, task-038 | independent | task-036 and task-038 in either order; run after both are done, in number order (task-036 then task-038) |
| 596 | `tests/cost-baseline.tsv` | task-036, task-039 | independent | task-036 and task-039 in either order; run after both are done, in number order (task-036 then task-039) |
| 597 | `tests/cost-baseline.tsv` | task-036, task-040 | independent | task-036 and task-040 in either order; run after both are done, in number order (task-036 then task-040) |
| 598 | `tests/cost-baseline.tsv` | task-036, task-041 | independent | task-036 and task-041 in either order; run after both are done, in number order (task-036 then task-041) |
| 599 | `tests/cost-baseline.tsv` | task-036, task-042 | independent | task-036 and task-042 in either order; run after both are done, in number order (task-036 then task-042) |
| 600 | `tests/cost-baseline.tsv` | task-036, task-043 | independent | task-036 and task-043 in either order; run after both are done, in number order (task-036 then task-043) |
| 601 | `tests/cost-baseline.tsv` | task-036, task-044 | independent | task-036 and task-044 in either order; run after both are done, in number order (task-036 then task-044) |
| 602 | `tests/cost-baseline.tsv` | task-036, task-045 | independent | task-036 and task-045 in either order; run after both are done, in number order (task-036 then task-045) |
| 603 | `tests/cost-baseline.tsv` | task-036, task-049 | task-049 depends on task-036 | task-036, then task-049 |
| 604 | `tests/cost-baseline.tsv` | task-036, task-057 | task-057 depends on task-036 | task-036, then task-057 |
| 605 | `tests/cost-baseline.tsv` | task-037, task-038 | independent | task-037 and task-038 in either order; run after both are done, in number order (task-037 then task-038) |
| 606 | `tests/cost-baseline.tsv` | task-037, task-039 | independent | task-037 and task-039 in either order; run after both are done, in number order (task-037 then task-039) |
| 607 | `tests/cost-baseline.tsv` | task-037, task-040 | independent | task-037 and task-040 in either order; run after both are done, in number order (task-037 then task-040) |
| 608 | `tests/cost-baseline.tsv` | task-037, task-041 | independent | task-037 and task-041 in either order; run after both are done, in number order (task-037 then task-041) |
| 609 | `tests/cost-baseline.tsv` | task-037, task-042 | independent | task-037 and task-042 in either order; run after both are done, in number order (task-037 then task-042) |
| 610 | `tests/cost-baseline.tsv` | task-037, task-043 | independent | task-037 and task-043 in either order; run after both are done, in number order (task-037 then task-043) |
| 611 | `tests/cost-baseline.tsv` | task-037, task-044 | independent | task-037 and task-044 in either order; run after both are done, in number order (task-037 then task-044) |
| 612 | `tests/cost-baseline.tsv` | task-037, task-045 | independent | task-037 and task-045 in either order; run after both are done, in number order (task-037 then task-045) |
| 613 | `tests/cost-baseline.tsv` | task-037, task-049 | task-049 depends on task-037 | task-037, then task-049 |
| 614 | `tests/cost-baseline.tsv` | task-037, task-057 | task-057 depends on task-037 | task-037, then task-057 |
| 615 | `tests/cost-baseline.tsv` | task-038, task-039 | independent | task-038 and task-039 in either order; run after both are done, in number order (task-038 then task-039) |
| 616 | `tests/cost-baseline.tsv` | task-038, task-040 | independent | task-038 and task-040 in either order; run after both are done, in number order (task-038 then task-040) |
| 617 | `tests/cost-baseline.tsv` | task-038, task-041 | independent | task-038 and task-041 in either order; run after both are done, in number order (task-038 then task-041) |
| 618 | `tests/cost-baseline.tsv` | task-038, task-042 | independent | task-038 and task-042 in either order; run after both are done, in number order (task-038 then task-042) |
| 619 | `tests/cost-baseline.tsv` | task-038, task-043 | independent | task-038 and task-043 in either order; run after both are done, in number order (task-038 then task-043) |
| 620 | `tests/cost-baseline.tsv` | task-038, task-044 | independent | task-038 and task-044 in either order; run after both are done, in number order (task-038 then task-044) |
| 621 | `tests/cost-baseline.tsv` | task-038, task-045 | independent | task-038 and task-045 in either order; run after both are done, in number order (task-038 then task-045) |
| 622 | `tests/cost-baseline.tsv` | task-038, task-049 | task-049 depends on task-038 | task-038, then task-049 |
| 623 | `tests/cost-baseline.tsv` | task-038, task-057 | task-057 depends on task-038 | task-038, then task-057 |
| 624 | `tests/cost-baseline.tsv` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 625 | `tests/cost-baseline.tsv` | task-039, task-041 | independent | task-039 and task-041 in either order; run after both are done, in number order (task-039 then task-041) |
| 626 | `tests/cost-baseline.tsv` | task-039, task-042 | independent | task-039 and task-042 in either order; run after both are done, in number order (task-039 then task-042) |
| 627 | `tests/cost-baseline.tsv` | task-039, task-043 | independent | task-039 and task-043 in either order; run after both are done, in number order (task-039 then task-043) |
| 628 | `tests/cost-baseline.tsv` | task-039, task-044 | independent | task-039 and task-044 in either order; run after both are done, in number order (task-039 then task-044) |
| 629 | `tests/cost-baseline.tsv` | task-039, task-045 | independent | task-039 and task-045 in either order; run after both are done, in number order (task-039 then task-045) |
| 630 | `tests/cost-baseline.tsv` | task-039, task-049 | task-049 depends on task-039 | task-039, then task-049 |
| 631 | `tests/cost-baseline.tsv` | task-039, task-057 | task-057 depends on task-039 | task-039, then task-057 |
| 632 | `tests/cost-baseline.tsv` | task-040, task-041 | independent | task-040 and task-041 in either order; run after both are done, in number order (task-040 then task-041) |
| 633 | `tests/cost-baseline.tsv` | task-040, task-042 | independent | task-040 and task-042 in either order; run after both are done, in number order (task-040 then task-042) |
| 634 | `tests/cost-baseline.tsv` | task-040, task-043 | independent | task-040 and task-043 in either order; run after both are done, in number order (task-040 then task-043) |
| 635 | `tests/cost-baseline.tsv` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 636 | `tests/cost-baseline.tsv` | task-040, task-045 | independent | task-040 and task-045 in either order; run after both are done, in number order (task-040 then task-045) |
| 637 | `tests/cost-baseline.tsv` | task-040, task-049 | task-049 depends on task-040 | task-040, then task-049 |
| 638 | `tests/cost-baseline.tsv` | task-040, task-057 | task-057 depends on task-040 | task-040, then task-057 |
| 639 | `tests/cost-baseline.tsv` | task-041, task-042 | independent | task-041 and task-042 in either order; run after both are done, in number order (task-041 then task-042) |
| 640 | `tests/cost-baseline.tsv` | task-041, task-043 | independent | task-041 and task-043 in either order; run after both are done, in number order (task-041 then task-043) |
| 641 | `tests/cost-baseline.tsv` | task-041, task-044 | independent | task-041 and task-044 in either order; run after both are done, in number order (task-041 then task-044) |
| 642 | `tests/cost-baseline.tsv` | task-041, task-045 | independent | task-041 and task-045 in either order; run after both are done, in number order (task-041 then task-045) |
| 643 | `tests/cost-baseline.tsv` | task-041, task-049 | task-049 depends on task-041 | task-041, then task-049 |
| 644 | `tests/cost-baseline.tsv` | task-041, task-057 | task-057 depends on task-041 | task-041, then task-057 |
| 645 | `tests/cost-baseline.tsv` | task-042, task-043 | independent | task-042 and task-043 in either order; run after both are done, in number order (task-042 then task-043) |
| 646 | `tests/cost-baseline.tsv` | task-042, task-044 | independent | task-042 and task-044 in either order; run after both are done, in number order (task-042 then task-044) |
| 647 | `tests/cost-baseline.tsv` | task-042, task-045 | independent | task-042 and task-045 in either order; run after both are done, in number order (task-042 then task-045) |
| 648 | `tests/cost-baseline.tsv` | task-042, task-049 | task-049 depends on task-042 | task-042, then task-049 |
| 649 | `tests/cost-baseline.tsv` | task-042, task-057 | task-057 depends on task-042 | task-042, then task-057 |
| 650 | `tests/cost-baseline.tsv` | task-043, task-044 | independent | task-043 and task-044 in either order; run after both are done, in number order (task-043 then task-044) |
| 651 | `tests/cost-baseline.tsv` | task-043, task-045 | independent | task-043 and task-045 in either order; run after both are done, in number order (task-043 then task-045) |
| 652 | `tests/cost-baseline.tsv` | task-043, task-049 | task-049 depends on task-043 | task-043, then task-049 |
| 653 | `tests/cost-baseline.tsv` | task-043, task-057 | task-057 depends on task-043 | task-043, then task-057 |
| 654 | `tests/cost-baseline.tsv` | task-044, task-045 | independent | task-044 and task-045 in either order; run after both are done, in number order (task-044 then task-045) |
| 655 | `tests/cost-baseline.tsv` | task-044, task-049 | task-049 depends on task-044 | task-044, then task-049 |
| 656 | `tests/cost-baseline.tsv` | task-044, task-057 | task-057 depends on task-044 | task-044, then task-057 |
| 657 | `tests/cost-baseline.tsv` | task-045, task-049 | independent | task-045 and task-049 in either order; run after both are done, in number order (task-045 then task-049) |
| 658 | `tests/cost-baseline.tsv` | task-045, task-057 | task-057 depends on task-045 | task-045, then task-057 |
| 659 | `tests/cost-baseline.tsv` | task-049, task-057 | task-057 depends on task-049 | task-049, then task-057 |
| 660 | `tests/cost-meter.py` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 661 | `tests/cost-meter.py` | task-040, task-057 | task-057 depends on task-040 | task-040, then task-057 |
| 662 | `tests/cost-meter.py` | task-044, task-057 | task-057 depends on task-044 | task-044, then task-057 |
| 663 | `tests/coverage-accepted-removals.tsv` | task-021, task-033 | task-033 depends on task-021 | task-021, then task-033 |
| 664 | `tests/coverage-accepted-removals.tsv` | task-021, task-043 | task-043 depends on task-021 | task-021, then task-043 |
| 665 | `tests/coverage-accepted-removals.tsv` | task-021, task-056 | task-056 depends on task-021 | task-021, then task-056 |
| 666 | `tests/coverage-accepted-removals.tsv` | task-033, task-043 | independent | task-033 and task-043 in either order; run after both are done, in number order (task-033 then task-043) |
| 667 | `tests/coverage-accepted-removals.tsv` | task-033, task-056 | task-056 depends on task-033 | task-033, then task-056 |
| 668 | `tests/coverage-accepted-removals.tsv` | task-043, task-056 | task-056 depends on task-043 | task-043, then task-056 |
| 669 | `tests/coverage-baseline.tsv` | task-021, task-025 | task-025 depends on task-021 | task-021, then task-025 |
| 670 | `tests/coverage-baseline.tsv` | task-021, task-030 | task-030 depends on task-021 | task-021, then task-030 |
| 671 | `tests/coverage-baseline.tsv` | task-021, task-031 | task-031 depends on task-021 | task-021, then task-031 |
| 672 | `tests/coverage-baseline.tsv` | task-021, task-032 | task-032 depends on task-021 | task-021, then task-032 |
| 673 | `tests/coverage-baseline.tsv` | task-021, task-033 | task-033 depends on task-021 | task-021, then task-033 |
| 674 | `tests/coverage-baseline.tsv` | task-021, task-034 | task-034 depends on task-021 | task-021, then task-034 |
| 675 | `tests/coverage-baseline.tsv` | task-021, task-037 | task-037 depends on task-021 | task-021, then task-037 |
| 676 | `tests/coverage-baseline.tsv` | task-021, task-038 | task-038 depends on task-021 | task-021, then task-038 |
| 677 | `tests/coverage-baseline.tsv` | task-021, task-039 | task-039 depends on task-021 | task-021, then task-039 |
| 678 | `tests/coverage-baseline.tsv` | task-021, task-040 | task-040 depends on task-021 | task-021, then task-040 |
| 679 | `tests/coverage-baseline.tsv` | task-021, task-042 | task-042 depends on task-021 | task-021, then task-042 |
| 680 | `tests/coverage-baseline.tsv` | task-021, task-043 | task-043 depends on task-021 | task-021, then task-043 |
| 681 | `tests/coverage-baseline.tsv` | task-021, task-044 | task-044 depends on task-021 | task-021, then task-044 |
| 682 | `tests/coverage-baseline.tsv` | task-021, task-045 | task-045 depends on task-021 | task-021, then task-045 |
| 683 | `tests/coverage-baseline.tsv` | task-021, task-049 | task-049 depends on task-021 | task-021, then task-049 |
| 684 | `tests/coverage-baseline.tsv` | task-021, task-056 | task-056 depends on task-021 | task-021, then task-056 |
| 685 | `tests/coverage-baseline.tsv` | task-021, task-057 | task-057 depends on task-021 | task-021, then task-057 |
| 686 | `tests/coverage-baseline.tsv` | task-025, task-030 | task-030 depends on task-025 | task-025, then task-030 |
| 687 | `tests/coverage-baseline.tsv` | task-025, task-031 | task-025 depends on task-031 | task-031, then task-025 |
| 688 | `tests/coverage-baseline.tsv` | task-025, task-032 | task-032 depends on task-025 | task-025, then task-032 |
| 689 | `tests/coverage-baseline.tsv` | task-025, task-033 | independent | task-025 and task-033 in either order; run after both are done, in number order (task-025 then task-033) |
| 690 | `tests/coverage-baseline.tsv` | task-025, task-034 | task-034 depends on task-025 | task-025, then task-034 |
| 691 | `tests/coverage-baseline.tsv` | task-025, task-037 | task-037 depends on task-025 | task-025, then task-037 |
| 692 | `tests/coverage-baseline.tsv` | task-025, task-038 | task-038 depends on task-025 | task-025, then task-038 |
| 693 | `tests/coverage-baseline.tsv` | task-025, task-039 | task-039 depends on task-025 | task-025, then task-039 |
| 694 | `tests/coverage-baseline.tsv` | task-025, task-040 | task-040 depends on task-025 | task-025, then task-040 |
| 695 | `tests/coverage-baseline.tsv` | task-025, task-042 | task-042 depends on task-025 | task-025, then task-042 |
| 696 | `tests/coverage-baseline.tsv` | task-025, task-043 | task-043 depends on task-025 | task-025, then task-043 |
| 697 | `tests/coverage-baseline.tsv` | task-025, task-044 | task-044 depends on task-025 | task-025, then task-044 |
| 698 | `tests/coverage-baseline.tsv` | task-025, task-045 | task-045 depends on task-025 | task-025, then task-045 |
| 699 | `tests/coverage-baseline.tsv` | task-025, task-049 | task-049 depends on task-025 | task-025, then task-049 |
| 700 | `tests/coverage-baseline.tsv` | task-025, task-056 | task-056 depends on task-025 | task-025, then task-056 |
| 701 | `tests/coverage-baseline.tsv` | task-025, task-057 | task-057 depends on task-025 | task-025, then task-057 |
| 702 | `tests/coverage-baseline.tsv` | task-030, task-031 | task-030 depends on task-031 | task-031, then task-030 |
| 703 | `tests/coverage-baseline.tsv` | task-030, task-032 | task-032 depends on task-030 | task-030, then task-032 |
| 704 | `tests/coverage-baseline.tsv` | task-030, task-033 | independent | task-030 and task-033 in either order; run after both are done, in number order (task-030 then task-033) |
| 705 | `tests/coverage-baseline.tsv` | task-030, task-034 | task-034 depends on task-030 | task-030, then task-034 |
| 706 | `tests/coverage-baseline.tsv` | task-030, task-037 | task-037 depends on task-030 | task-030, then task-037 |
| 707 | `tests/coverage-baseline.tsv` | task-030, task-038 | task-038 depends on task-030 | task-030, then task-038 |
| 708 | `tests/coverage-baseline.tsv` | task-030, task-039 | task-039 depends on task-030 | task-030, then task-039 |
| 709 | `tests/coverage-baseline.tsv` | task-030, task-040 | task-040 depends on task-030 | task-030, then task-040 |
| 710 | `tests/coverage-baseline.tsv` | task-030, task-042 | task-042 depends on task-030 | task-030, then task-042 |
| 711 | `tests/coverage-baseline.tsv` | task-030, task-043 | task-043 depends on task-030 | task-030, then task-043 |
| 712 | `tests/coverage-baseline.tsv` | task-030, task-044 | task-044 depends on task-030 | task-030, then task-044 |
| 713 | `tests/coverage-baseline.tsv` | task-030, task-045 | task-045 depends on task-030 | task-030, then task-045 |
| 714 | `tests/coverage-baseline.tsv` | task-030, task-049 | task-049 depends on task-030 | task-030, then task-049 |
| 715 | `tests/coverage-baseline.tsv` | task-030, task-056 | task-056 depends on task-030 | task-030, then task-056 |
| 716 | `tests/coverage-baseline.tsv` | task-030, task-057 | task-057 depends on task-030 | task-030, then task-057 |
| 717 | `tests/coverage-baseline.tsv` | task-031, task-032 | task-032 depends on task-031 | task-031, then task-032 |
| 718 | `tests/coverage-baseline.tsv` | task-031, task-033 | task-033 depends on task-031 | task-031, then task-033 |
| 719 | `tests/coverage-baseline.tsv` | task-031, task-034 | task-034 depends on task-031 | task-031, then task-034 |
| 720 | `tests/coverage-baseline.tsv` | task-031, task-037 | task-037 depends on task-031 | task-031, then task-037 |
| 721 | `tests/coverage-baseline.tsv` | task-031, task-038 | task-038 depends on task-031 | task-031, then task-038 |
| 722 | `tests/coverage-baseline.tsv` | task-031, task-039 | task-039 depends on task-031 | task-031, then task-039 |
| 723 | `tests/coverage-baseline.tsv` | task-031, task-040 | task-040 depends on task-031 | task-031, then task-040 |
| 724 | `tests/coverage-baseline.tsv` | task-031, task-042 | task-042 depends on task-031 | task-031, then task-042 |
| 725 | `tests/coverage-baseline.tsv` | task-031, task-043 | task-043 depends on task-031 | task-031, then task-043 |
| 726 | `tests/coverage-baseline.tsv` | task-031, task-044 | task-044 depends on task-031 | task-031, then task-044 |
| 727 | `tests/coverage-baseline.tsv` | task-031, task-045 | task-045 depends on task-031 | task-031, then task-045 |
| 728 | `tests/coverage-baseline.tsv` | task-031, task-049 | task-049 depends on task-031 | task-031, then task-049 |
| 729 | `tests/coverage-baseline.tsv` | task-031, task-056 | task-056 depends on task-031 | task-031, then task-056 |
| 730 | `tests/coverage-baseline.tsv` | task-031, task-057 | task-057 depends on task-031 | task-031, then task-057 |
| 731 | `tests/coverage-baseline.tsv` | task-032, task-033 | independent | task-032 and task-033 in either order; run after both are done, in number order (task-032 then task-033) |
| 732 | `tests/coverage-baseline.tsv` | task-032, task-034 | independent | task-032 and task-034 in either order; run after both are done, in number order (task-032 then task-034) |
| 733 | `tests/coverage-baseline.tsv` | task-032, task-037 | independent | task-032 and task-037 in either order; run after both are done, in number order (task-032 then task-037) |
| 734 | `tests/coverage-baseline.tsv` | task-032, task-038 | independent | task-032 and task-038 in either order; run after both are done, in number order (task-032 then task-038) |
| 735 | `tests/coverage-baseline.tsv` | task-032, task-039 | independent | task-032 and task-039 in either order; run after both are done, in number order (task-032 then task-039) |
| 736 | `tests/coverage-baseline.tsv` | task-032, task-040 | independent | task-032 and task-040 in either order; run after both are done, in number order (task-032 then task-040) |
| 737 | `tests/coverage-baseline.tsv` | task-032, task-042 | independent | task-032 and task-042 in either order; run after both are done, in number order (task-032 then task-042) |
| 738 | `tests/coverage-baseline.tsv` | task-032, task-043 | independent | task-032 and task-043 in either order; run after both are done, in number order (task-032 then task-043) |
| 739 | `tests/coverage-baseline.tsv` | task-032, task-044 | independent | task-032 and task-044 in either order; run after both are done, in number order (task-032 then task-044) |
| 740 | `tests/coverage-baseline.tsv` | task-032, task-045 | independent | task-032 and task-045 in either order; run after both are done, in number order (task-032 then task-045) |
| 741 | `tests/coverage-baseline.tsv` | task-032, task-049 | task-049 depends on task-032 | task-032, then task-049 |
| 742 | `tests/coverage-baseline.tsv` | task-032, task-056 | task-056 depends on task-032 | task-032, then task-056 |
| 743 | `tests/coverage-baseline.tsv` | task-032, task-057 | task-057 depends on task-032 | task-032, then task-057 |
| 744 | `tests/coverage-baseline.tsv` | task-033, task-034 | independent | task-033 and task-034 in either order; run after both are done, in number order (task-033 then task-034) |
| 745 | `tests/coverage-baseline.tsv` | task-033, task-037 | independent | task-033 and task-037 in either order; run after both are done, in number order (task-033 then task-037) |
| 746 | `tests/coverage-baseline.tsv` | task-033, task-038 | independent | task-033 and task-038 in either order; run after both are done, in number order (task-033 then task-038) |
| 747 | `tests/coverage-baseline.tsv` | task-033, task-039 | independent | task-033 and task-039 in either order; run after both are done, in number order (task-033 then task-039) |
| 748 | `tests/coverage-baseline.tsv` | task-033, task-040 | independent | task-033 and task-040 in either order; run after both are done, in number order (task-033 then task-040) |
| 749 | `tests/coverage-baseline.tsv` | task-033, task-042 | independent | task-033 and task-042 in either order; run after both are done, in number order (task-033 then task-042) |
| 750 | `tests/coverage-baseline.tsv` | task-033, task-043 | independent | task-033 and task-043 in either order; run after both are done, in number order (task-033 then task-043) |
| 751 | `tests/coverage-baseline.tsv` | task-033, task-044 | independent | task-033 and task-044 in either order; run after both are done, in number order (task-033 then task-044) |
| 752 | `tests/coverage-baseline.tsv` | task-033, task-045 | independent | task-033 and task-045 in either order; run after both are done, in number order (task-033 then task-045) |
| 753 | `tests/coverage-baseline.tsv` | task-033, task-049 | independent | task-033 and task-049 in either order; run after both are done, in number order (task-033 then task-049) |
| 754 | `tests/coverage-baseline.tsv` | task-033, task-056 | task-056 depends on task-033 | task-033, then task-056 |
| 755 | `tests/coverage-baseline.tsv` | task-033, task-057 | task-057 depends on task-033 | task-033, then task-057 |
| 756 | `tests/coverage-baseline.tsv` | task-034, task-037 | independent | task-034 and task-037 in either order; run after both are done, in number order (task-034 then task-037) |
| 757 | `tests/coverage-baseline.tsv` | task-034, task-038 | independent | task-034 and task-038 in either order; run after both are done, in number order (task-034 then task-038) |
| 758 | `tests/coverage-baseline.tsv` | task-034, task-039 | independent | task-034 and task-039 in either order; run after both are done, in number order (task-034 then task-039) |
| 759 | `tests/coverage-baseline.tsv` | task-034, task-040 | independent | task-034 and task-040 in either order; run after both are done, in number order (task-034 then task-040) |
| 760 | `tests/coverage-baseline.tsv` | task-034, task-042 | independent | task-034 and task-042 in either order; run after both are done, in number order (task-034 then task-042) |
| 761 | `tests/coverage-baseline.tsv` | task-034, task-043 | independent | task-034 and task-043 in either order; run after both are done, in number order (task-034 then task-043) |
| 762 | `tests/coverage-baseline.tsv` | task-034, task-044 | independent | task-034 and task-044 in either order; run after both are done, in number order (task-034 then task-044) |
| 763 | `tests/coverage-baseline.tsv` | task-034, task-045 | independent | task-034 and task-045 in either order; run after both are done, in number order (task-034 then task-045) |
| 764 | `tests/coverage-baseline.tsv` | task-034, task-049 | task-049 depends on task-034 | task-034, then task-049 |
| 765 | `tests/coverage-baseline.tsv` | task-034, task-056 | task-056 depends on task-034 | task-034, then task-056 |
| 766 | `tests/coverage-baseline.tsv` | task-034, task-057 | task-057 depends on task-034 | task-034, then task-057 |
| 767 | `tests/coverage-baseline.tsv` | task-037, task-038 | independent | task-037 and task-038 in either order; run after both are done, in number order (task-037 then task-038) |
| 768 | `tests/coverage-baseline.tsv` | task-037, task-039 | independent | task-037 and task-039 in either order; run after both are done, in number order (task-037 then task-039) |
| 769 | `tests/coverage-baseline.tsv` | task-037, task-040 | independent | task-037 and task-040 in either order; run after both are done, in number order (task-037 then task-040) |
| 770 | `tests/coverage-baseline.tsv` | task-037, task-042 | independent | task-037 and task-042 in either order; run after both are done, in number order (task-037 then task-042) |
| 771 | `tests/coverage-baseline.tsv` | task-037, task-043 | independent | task-037 and task-043 in either order; run after both are done, in number order (task-037 then task-043) |
| 772 | `tests/coverage-baseline.tsv` | task-037, task-044 | independent | task-037 and task-044 in either order; run after both are done, in number order (task-037 then task-044) |
| 773 | `tests/coverage-baseline.tsv` | task-037, task-045 | independent | task-037 and task-045 in either order; run after both are done, in number order (task-037 then task-045) |
| 774 | `tests/coverage-baseline.tsv` | task-037, task-049 | task-049 depends on task-037 | task-037, then task-049 |
| 775 | `tests/coverage-baseline.tsv` | task-037, task-056 | task-056 depends on task-037 | task-037, then task-056 |
| 776 | `tests/coverage-baseline.tsv` | task-037, task-057 | task-057 depends on task-037 | task-037, then task-057 |
| 777 | `tests/coverage-baseline.tsv` | task-038, task-039 | independent | task-038 and task-039 in either order; run after both are done, in number order (task-038 then task-039) |
| 778 | `tests/coverage-baseline.tsv` | task-038, task-040 | independent | task-038 and task-040 in either order; run after both are done, in number order (task-038 then task-040) |
| 779 | `tests/coverage-baseline.tsv` | task-038, task-042 | independent | task-038 and task-042 in either order; run after both are done, in number order (task-038 then task-042) |
| 780 | `tests/coverage-baseline.tsv` | task-038, task-043 | independent | task-038 and task-043 in either order; run after both are done, in number order (task-038 then task-043) |
| 781 | `tests/coverage-baseline.tsv` | task-038, task-044 | independent | task-038 and task-044 in either order; run after both are done, in number order (task-038 then task-044) |
| 782 | `tests/coverage-baseline.tsv` | task-038, task-045 | independent | task-038 and task-045 in either order; run after both are done, in number order (task-038 then task-045) |
| 783 | `tests/coverage-baseline.tsv` | task-038, task-049 | task-049 depends on task-038 | task-038, then task-049 |
| 784 | `tests/coverage-baseline.tsv` | task-038, task-056 | task-056 depends on task-038 | task-038, then task-056 |
| 785 | `tests/coverage-baseline.tsv` | task-038, task-057 | task-057 depends on task-038 | task-038, then task-057 |
| 786 | `tests/coverage-baseline.tsv` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 787 | `tests/coverage-baseline.tsv` | task-039, task-042 | independent | task-039 and task-042 in either order; run after both are done, in number order (task-039 then task-042) |
| 788 | `tests/coverage-baseline.tsv` | task-039, task-043 | independent | task-039 and task-043 in either order; run after both are done, in number order (task-039 then task-043) |
| 789 | `tests/coverage-baseline.tsv` | task-039, task-044 | independent | task-039 and task-044 in either order; run after both are done, in number order (task-039 then task-044) |
| 790 | `tests/coverage-baseline.tsv` | task-039, task-045 | independent | task-039 and task-045 in either order; run after both are done, in number order (task-039 then task-045) |
| 791 | `tests/coverage-baseline.tsv` | task-039, task-049 | task-049 depends on task-039 | task-039, then task-049 |
| 792 | `tests/coverage-baseline.tsv` | task-039, task-056 | task-056 depends on task-039 | task-039, then task-056 |
| 793 | `tests/coverage-baseline.tsv` | task-039, task-057 | task-057 depends on task-039 | task-039, then task-057 |
| 794 | `tests/coverage-baseline.tsv` | task-040, task-042 | independent | task-040 and task-042 in either order; run after both are done, in number order (task-040 then task-042) |
| 795 | `tests/coverage-baseline.tsv` | task-040, task-043 | independent | task-040 and task-043 in either order; run after both are done, in number order (task-040 then task-043) |
| 796 | `tests/coverage-baseline.tsv` | task-040, task-044 | independent | task-040 and task-044 in either order; run after both are done, in number order (task-040 then task-044) |
| 797 | `tests/coverage-baseline.tsv` | task-040, task-045 | independent | task-040 and task-045 in either order; run after both are done, in number order (task-040 then task-045) |
| 798 | `tests/coverage-baseline.tsv` | task-040, task-049 | task-049 depends on task-040 | task-040, then task-049 |
| 799 | `tests/coverage-baseline.tsv` | task-040, task-056 | task-056 depends on task-040 | task-040, then task-056 |
| 800 | `tests/coverage-baseline.tsv` | task-040, task-057 | task-057 depends on task-040 | task-040, then task-057 |
| 801 | `tests/coverage-baseline.tsv` | task-042, task-043 | independent | task-042 and task-043 in either order; run after both are done, in number order (task-042 then task-043) |
| 802 | `tests/coverage-baseline.tsv` | task-042, task-044 | independent | task-042 and task-044 in either order; run after both are done, in number order (task-042 then task-044) |
| 803 | `tests/coverage-baseline.tsv` | task-042, task-045 | independent | task-042 and task-045 in either order; run after both are done, in number order (task-042 then task-045) |
| 804 | `tests/coverage-baseline.tsv` | task-042, task-049 | task-049 depends on task-042 | task-042, then task-049 |
| 805 | `tests/coverage-baseline.tsv` | task-042, task-056 | task-056 depends on task-042 | task-042, then task-056 |
| 806 | `tests/coverage-baseline.tsv` | task-042, task-057 | task-057 depends on task-042 | task-042, then task-057 |
| 807 | `tests/coverage-baseline.tsv` | task-043, task-044 | independent | task-043 and task-044 in either order; run after both are done, in number order (task-043 then task-044) |
| 808 | `tests/coverage-baseline.tsv` | task-043, task-045 | independent | task-043 and task-045 in either order; run after both are done, in number order (task-043 then task-045) |
| 809 | `tests/coverage-baseline.tsv` | task-043, task-049 | task-049 depends on task-043 | task-043, then task-049 |
| 810 | `tests/coverage-baseline.tsv` | task-043, task-056 | task-056 depends on task-043 | task-043, then task-056 |
| 811 | `tests/coverage-baseline.tsv` | task-043, task-057 | task-057 depends on task-043 | task-043, then task-057 |
| 812 | `tests/coverage-baseline.tsv` | task-044, task-045 | independent | task-044 and task-045 in either order; run after both are done, in number order (task-044 then task-045) |
| 813 | `tests/coverage-baseline.tsv` | task-044, task-049 | task-049 depends on task-044 | task-044, then task-049 |
| 814 | `tests/coverage-baseline.tsv` | task-044, task-056 | task-056 depends on task-044 | task-044, then task-056 |
| 815 | `tests/coverage-baseline.tsv` | task-044, task-057 | task-057 depends on task-044 | task-044, then task-057 |
| 816 | `tests/coverage-baseline.tsv` | task-045, task-049 | independent | task-045 and task-049 in either order; run after both are done, in number order (task-045 then task-049) |
| 817 | `tests/coverage-baseline.tsv` | task-045, task-056 | independent | task-045 and task-056 in either order; run after both are done, in number order (task-045 then task-056) |
| 818 | `tests/coverage-baseline.tsv` | task-045, task-057 | task-057 depends on task-045 | task-045, then task-057 |
| 819 | `tests/coverage-baseline.tsv` | task-049, task-056 | independent | task-049 and task-056 in either order; run after both are done, in number order (task-049 then task-056) |
| 820 | `tests/coverage-baseline.tsv` | task-049, task-057 | task-057 depends on task-049 | task-049, then task-057 |
| 821 | `tests/coverage-baseline.tsv` | task-056, task-057 | task-057 depends on task-056 | task-056, then task-057 |
| 822 | `tests/coverage-rehome-allowlist.tsv` | task-021, task-032 | task-032 depends on task-021 | task-021, then task-032 |
| 823 | `tests/coverage-rehome-allowlist.tsv` | task-021, task-039 | task-039 depends on task-021 | task-021, then task-039 |
| 824 | `tests/coverage-rehome-allowlist.tsv` | task-021, task-040 | task-040 depends on task-021 | task-021, then task-040 |
| 825 | `tests/coverage-rehome-allowlist.tsv` | task-021, task-043 | task-043 depends on task-021 | task-021, then task-043 |
| 826 | `tests/coverage-rehome-allowlist.tsv` | task-032, task-039 | independent | task-032 and task-039 in either order; run after both are done, in number order (task-032 then task-039) |
| 827 | `tests/coverage-rehome-allowlist.tsv` | task-032, task-040 | independent | task-032 and task-040 in either order; run after both are done, in number order (task-032 then task-040) |
| 828 | `tests/coverage-rehome-allowlist.tsv` | task-032, task-043 | independent | task-032 and task-043 in either order; run after both are done, in number order (task-032 then task-043) |
| 829 | `tests/coverage-rehome-allowlist.tsv` | task-039, task-040 | task-040 depends on task-039 | task-039, then task-040 |
| 830 | `tests/coverage-rehome-allowlist.tsv` | task-039, task-043 | independent | task-039 and task-043 in either order; run after both are done, in number order (task-039 then task-043) |
| 831 | `tests/coverage-rehome-allowlist.tsv` | task-040, task-043 | independent | task-040 and task-043 in either order; run after both are done, in number order (task-040 then task-043) |
| 832 | `tests/ui/README.md` | task-031, task-033 | task-033 depends on task-031 | task-031, then task-033 |
| 833 | `tests/windows/Test-AidInstaller.ps1` | task-032, task-040 | independent | task-032 and task-040 in either order; run after both are done, in number order (task-032 then task-040) |
| 834 | `tests/windows/Test-AidInstaller.ps1` | task-032, task-042 | independent | task-032 and task-042 in either order; run after both are done, in number order (task-032 then task-042) |
| 835 | `tests/windows/Test-AidInstaller.ps1` | task-032, task-056 | task-056 depends on task-032 | task-032, then task-056 |
| 836 | `tests/windows/Test-AidInstaller.ps1` | task-040, task-042 | independent | task-040 and task-042 in either order; run after both are done, in number order (task-040 then task-042) |
| 837 | `tests/windows/Test-AidInstaller.ps1` | task-040, task-056 | task-056 depends on task-040 | task-040, then task-056 |
| 838 | `tests/windows/Test-AidInstaller.ps1` | task-042, task-056 | task-056 depends on task-042 | task-042, then task-056 |

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
| D9 | Owner classes | The spec's "left as they are" items (`site/src/data/skill-flows/`, `tests/coverage-baseline.tsv`, `tests/canonical/test-diagram-content.sh`, `canonical/aid/scripts/summarize/`, documentation prose in `docs/` and `site/src/content/docs/`) have no class of their own; G11 synthetic fixture names (`aid-fixture`, `aid-parent`, `door-skill`) name no real file; some tests name unchanged skills | Assigned to `history, left as is` (the class for a hit that stays). Please confirm; the alternative is a fifth class. `site/src/data/skill-flows/` is regenerated by the G1 generator run of each task that changes a skill (task-021 first). |
| D10 | Tests rule (Feature 002 § 2): "`test-describe-full-only.sh`" is named among the suites that change | it has 12 edit-list matches (owners: task-021, task-038, task-044) | No task Scope names this suite. Its owner is the task that changes the file it reads (per P8). Please confirm that the matches are the only edit it needs. |
| D11 | P7: "Run against today's tree with these globs, only the two exemptions fire" (NM) | NM-03: 1 hit (aid-housekeep, exempt). NM-04: 3 hits (aid-execute, exempt). NM-01 and NM-02: none | None. |
| D12 | P8: suites named by a task Scope (for example `test-pipeline-status-walkthrough.sh` A1 and B1, `test-work-initiation-gate.sh`, `test-skill-guide.sh`) | The name-based match of P8 finds the files each task names, plus other suites (for example `test_reader.py`, `test-release.sh`) | Each extra suite gets the owner of the file it reads. None is left without an owner. |
| D13 | Task-021, task-022 and task-025 (P8 assignments) | The spec's Files and layout list `reader.py`, `server.py` (`_ser_work`) and `server.mjs` for task-031 | Owners follow task-031's Scope text ("through `reader.py`, `dashboard/server/server.py` `_ser_work` and `server.mjs`"). No difference. |
| D14 | P10: "Whether today's writes ... are already atomic" | Yes: temp copy, verify, rename under the lock (see P10) | The spec's § 2 atomic-write requirement is already met for the field writes; the new modes are task-025 and task-029 work. Limit noted in P10. |

## Test step

No suite and no check was run for this task: every change lies under `.aid/works/` (the work-folder-only rule of task-020 and the test step of PLAN.md). `bash -n`, `py_compile` and `node --check` have nothing to check (no `.sh`, `.py` or `.mjs` changed). `run_generator.py` was not run; no branch, worktree or commit was made.

