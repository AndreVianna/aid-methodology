# Delivery-003 site search and reconciled edit list

This file is the output of task-058 (RESEARCH) of delivery-003. It re-runs searches Q1 to Q9 of the task's Scope, the G11, G17 and G19 searches, and the skill owner table (G2) at the base commit, gives every hit exactly one owner, lists the suites that are assigned to more than one task, and reconciles the result with the task files task-059 to task-081. It changes no other file.

## Base commit and conventions

- **Base commit:** `7fe3aebc140e85a06056ad91f15432bba2367014` (the `task-058: In Progress` commit). The worktree was clean at the base (`git status --short` empty), so every search below, run from the worktree root with `git grep` and no tree argument, reads the base bytes.
- **Excluded from every search:** `.aid/works/` (planning text: the task files, the proposal, the PLAN and REQUIREMENTS, and this file itself). Installed copies (`.claude/`, `.agents/`, `.aid/runtime/`, `.cursor/`, `profiles/`, `.aid/.aid-manifest.json`) are excluded from the row tables and counted in the Installed copies section; they are the resync's output, not an edit list. `recovery/` and `packages/` are excluded from the row tables and listed in the Delta.
- **Owner classes.** (1) a task of delivery-003 (task-059 to task-081); (2) `installed copy (resync)`; (3) `history, left as is`, for `release-tracking.md`, `kb.html`, `coverage-accepted-removals.tsv` and `validate-diagram-content.mjs`; (4) `baseline, re-recorded at the gate`, for `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`; (5) `no change needed here (reason)`, used only for a hit in a file that no delivery-003 task names and that the spec leaves unchanged. Each class-5 file is listed in the Delta (D4) for the maintainer's ruling, because the task's owner classes do not name it. Class 5 names hits whose text needs no edit, so no task owns an edit for them.
- **Generated doorways.** A `canonical/skills/aid-*/SKILL.md` whose first heading is `# Shortcut` is a generated doorway (34 of them). Its text comes from `shortcut-engine.md` (task-062) and changes through the builder, so its owner is `no change needed here (generated doorway ...)`, not a sweep task.
- **Test step.** Every change in this task lies under `.aid/works/`. Per the work-folder-only rule, no suite runs and `select-suites.sh` is not run; no `run_generator.py` runs; there are no `.sh`, `.py` or `.mjs` changes to check. The generator and its helpers are in `.aid/works/work-003-full-aid-restructure/research/delivery-003-sites-tools/`.
- **Reproducing a section.** Each Q section gives its command, run from the repository root at the base commit. Q8 is printed by `gen.py --q8` and Q9 by `ad13run.sh`; run with no argument, `gen.py` rewrites this file. The row generator is `.aid/works/work-003-full-aid-restructure/research/delivery-003-sites-tools/gen.py` with its owner map `own.py` beside it; `ad13run.sh` there is the AD13 counter.

## Contents

- Q1 SS-01 banner forms
- Q2 interviewer sites
- Q3 question-record sites
- Q4 AskUserQuestion
- Q5 reviewer-brief files
- Q6 state-machine-chaining citations
- Q7 asking skills against the AC-28 coverage table
- Q8 Q106 suite map
- Q9 AD13 counts
- Site fixtures (G11)
- KB sources (G17)
- Site generator sources (G19)
- Baselines
- Installed copies (resync)
- Skill owner table (G2)
- Suites on two tasks and the run order
- Delta

## Q1 SS-01 banner forms

Command (scope: SS-01's, `canonical/skills/` and `canonical/aid/templates/`):

```bash
git grep -n -E -e '\[State: ' -e 'you are here' -e 'Advancing to \[State' -e '\[State [0-9]+\] Dispatching' -e '\[Resolved:' -e 'Re-run `/aid-' -- canonical/skills canonical/aid/templates
```

Hits: **481** lines in 119 files. Owners by count: task-060 86, task-061 71, task-062 3, task-063 19, task-064 33, task-065 44, task-066 32, task-067 86, task-068 45, task-069 57, task-074 5.

The `[State: X]` lines that are an `**Advance:**` target stay (F002 § 4); the grep shows every line, and the sweep tasks remove the others. Installed copies are not listed here (Installed copies section).

| # | Location | Form | Text | Owner |
|---|---|---|---|---|
| 1 | `canonical/aid/templates/shortcut-engine.md:96` | [State: X] | `Print the state-entry line on entry to each state (`[State: NAME] -- {one-line` | task-062 |
| 2 | `canonical/aid/templates/shortcut-engine.md:235` | [State: X] | ``[State: INTAKE] ERROR -- no shortcut-catalog.yml row for '{name}'. This is a build` | task-062 |
| 3 | `canonical/aid/templates/shortcut-engine.md:907` | [State: X] | `[State: APPROVAL-HALT] -- flattened work ready for approval; nothing has executed.` | task-062 |
| 4 | `canonical/aid/templates/state-machine-chaining.md:24` | [State: X] | `**Advance:** → [State: X] (continue inline).` | task-074 |
| 5 | `canonical/aid/templates/state-machine-chaining.md:41` | [State: X] | `**Advance:** Stop here. Re-run `/aid-<skill>` after {one-line condition} to continue to [State: X].` | task-074 |
| 6 | `canonical/aid/templates/state-machine-chaining.md:51` | [State: X] | `**Advance:** Stop here (contracted checkpoint per {citation}). Re-run `/aid-<skill>` to continue to [State: X].` | task-074 |
| 7 | `canonical/aid/templates/state-machine-chaining.md:70` | [State: X] | `3. If CHAIN: print a short transition line (e.g., `→ Advancing to [State: X]`), then begin executing the next state's...` | task-074 |
| 8 | `canonical/aid/templates/state-machine-chaining.md:95` | [State: X] | `❌ **Mixing CHAIN and PAUSE in the same Advance line.** Each transition is exactly one type. If a state's next-step de...` | task-074 |
| 9 | `canonical/skills/aid-brainstorm/SKILL.md:26` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 10 | `canonical/skills/aid-create-architecture/SKILL.md:34` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}` entry` | task-061 |
| 11 | `canonical/skills/aid-create-architecture/SKILL.md:68` | [State: X] | `**Advance:** CHAIN → [State: CREATE] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-061 |
| 12 | `canonical/skills/aid-create-architecture/SKILL.md:108` | [State: X] | `**Advance:** CHAIN → [State: VERIFY] when every refusal check passes; HALT when a refusal check stops the step.` | task-061 |
| 13 | `canonical/skills/aid-create-architecture/SKILL.md:117` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: CREATE] when it is not clean and fewe...` | task-061 |
| 14 | `canonical/skills/aid-create-backlog/SKILL.md:29` | [State: X] | `Print the `[State: NAME] -- {purpose}` entry line on each state.` | task-061 |
| 15 | `canonical/skills/aid-create-backlog/SKILL.md:60` | [State: X] | `**Advance:** CHAIN → [State: GUARD] once the seed question is settled; HALT when the run ends here (the user designs ...` | task-061 |
| 16 | `canonical/skills/aid-create-backlog/SKILL.md:74` | [State: X] | `**Advance:** CHAIN → [State: REALIZE] when the gate passes; HALT when the gate refuses.` | task-061 |
| 17 | `canonical/skills/aid-create-backlog/SKILL.md:182` | [State: X] | `**Advance:** CHAIN → [State: REGISTER] when the document is written; HALT when the route case applies.` | task-061 |
| 18 | `canonical/skills/aid-create-backlog/SKILL.md:201` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-061 |
| 19 | `canonical/skills/aid-create-backlog/SKILL.md:211` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: REALIZE] when it is not clean and few...` | task-061 |
| 20 | `canonical/skills/aid-create-cicd/SKILL.md:36` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}` entry` | task-061 |
| 21 | `canonical/skills/aid-create-cicd/SKILL.md:71` | [State: X] | `**Advance:** CHAIN → [State: CREATE] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-061 |
| 22 | `canonical/skills/aid-create-cicd/SKILL.md:111` | [State: X] | `**Advance:** CHAIN → [State: VERIFY] when every refusal check passes; HALT when a refusal check stops the step.` | task-061 |
| 23 | `canonical/skills/aid-create-cicd/SKILL.md:120` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: CREATE] when it is not clean and fewe...` | task-061 |
| 24 | `canonical/skills/aid-create-document/SKILL.md:37` | [State: X] | `gate] -> PLACE (on approval) -> DONE**. Print the `[State: NAME] -- {purpose}` entry line on each state.` | task-069 |
| 25 | `canonical/skills/aid-create-document/SKILL.md:66` | [State: X] | `**Advance:** CHAIN → [State: INTAKE-ASK] when a question must be put (empty argument, Guided path, works exist); CHAI...` | task-069 |
| 26 | `canonical/skills/aid-create-document/SKILL.md:81` | [State: X] | `**Advance:** CHAIN → [State: ALLOCATE] once the questions are answered; HALT when the user does not answer (nothing w...` | task-069 |
| 27 | `canonical/skills/aid-create-document/SKILL.md:110` | [State: X] | `**Advance:** CHAIN → [State: AUTHOR] on a new work; HALT when the user continues an existing work (the gate's § 3b ta...` | task-069 |
| 28 | `canonical/skills/aid-create-document/SKILL.md:123` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-069 |
| 29 | `canonical/skills/aid-create-document/SKILL.md:137` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: AUTHOR] when it is not clean and fewe...` | task-069 |
| 30 | `canonical/skills/aid-create-document/SKILL.md:149` | [State: X] | `**Advance:** ASK → [State: PLACE].` | task-069 |
| 31 | `canonical/skills/aid-create-document/SKILL.md:162` | [State: X] | `**Advance:** CHAIN → [State: DONE].` | task-069 |
| 32 | `canonical/skills/aid-create-mvp/SKILL.md:39` | [State: X] | `Print the `[State: NAME] -- {purpose}` entry line on each state.` | task-061 |
| 33 | `canonical/skills/aid-create-mvp/SKILL.md:69` | [State: X] | `**Advance:** CHAIN → [State: GUARD] once the seed question is settled; HALT when the run ends here (the user designs ...` | task-061 |
| 34 | `canonical/skills/aid-create-mvp/SKILL.md:83` | [State: X] | `**Advance:** CHAIN → [State: REALIZE] when the gate passes; HALT when the gate refuses.` | task-061 |
| 35 | `canonical/skills/aid-create-mvp/SKILL.md:129` | [State: X] | `**Advance:** CHAIN → [State: VERIFY] when the section is written; HALT when a route case applies.` | task-061 |
| 36 | `canonical/skills/aid-create-mvp/SKILL.md:139` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: REALIZE] when it is not clean and few...` | task-061 |
| 37 | `canonical/skills/aid-create-roadmap/SKILL.md:34` | [State: X] | `Print the `[State: NAME] -- {purpose}` entry line on each state.` | task-061 |
| 38 | `canonical/skills/aid-create-roadmap/SKILL.md:63` | [State: X] | `**Advance:** CHAIN → [State: GUARD] once the seed question is settled; HALT when the run ends here (the user designs ...` | task-061 |
| 39 | `canonical/skills/aid-create-roadmap/SKILL.md:77` | [State: X] | `**Advance:** CHAIN → [State: REALIZE] when the gate passes; HALT when the gate refuses.` | task-061 |
| 40 | `canonical/skills/aid-create-roadmap/SKILL.md:139` | [State: X] | `**Advance:** CHAIN → [State: REGISTER] when the document is written; HALT when the route case applies.` | task-061 |
| 41 | `canonical/skills/aid-create-roadmap/SKILL.md:158` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-061 |
| 42 | `canonical/skills/aid-create-roadmap/SKILL.md:168` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: REALIZE] when it is not clean and few...` | task-061 |
| 43 | `canonical/skills/aid-create-stack/SKILL.md:34` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}` entry` | task-061 |
| 44 | `canonical/skills/aid-create-stack/SKILL.md:67` | [State: X] | `**Advance:** CHAIN → [State: CREATE] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-061 |
| 45 | `canonical/skills/aid-create-stack/SKILL.md:107` | [State: X] | `**Advance:** CHAIN → [State: VERIFY] when every refusal check passes; HALT when a refusal check stops the step.` | task-061 |
| 46 | `canonical/skills/aid-create-stack/SKILL.md:116` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: CREATE] when it is not clean and fewe...` | task-061 |
| 47 | `canonical/skills/aid-create-testing-strategy/SKILL.md:34` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}` entry` | task-061 |
| 48 | `canonical/skills/aid-create-testing-strategy/SKILL.md:66` | [State: X] | `**Advance:** CHAIN → [State: CREATE] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-061 |
| 49 | `canonical/skills/aid-create-testing-strategy/SKILL.md:106` | [State: X] | `**Advance:** CHAIN → [State: VERIFY] when every refusal check passes; HALT when a refusal check stops the step.` | task-061 |
| 50 | `canonical/skills/aid-create-testing-strategy/SKILL.md:115` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: CREATE] when it is not clean and fewe...` | task-061 |
| 51 | `canonical/skills/aid-create-ticket/SKILL.md:102` | [State: X] | `**Advance:** **CHAIN** → [State: RESOLVE-CONNECTOR] when the arguments parse; **HALT** when the usage line was printed.` | task-068 |
| 52 | `canonical/skills/aid-create-ticket/SKILL.md:118` | [State: X] | `**Advance:** **CHAIN** → [State: COMPOSE] when the connector resolves silently; **CHAIN** → [State: PICK-CONNECTOR] w...` | task-068 |
| 53 | `canonical/skills/aid-create-ticket/SKILL.md:129` | [State: X] | `**Advance:** **CHAIN** → [State: COMPOSE] once the user has picked the connector (continue inline).` | task-068 |
| 54 | `canonical/skills/aid-create-ticket/SKILL.md:157` | [State: X] | `**Advance:** **CHAIN** → [State: LEVEL-RESOLVE] (continue inline); **HALT** on the cross-tracker stop.` | task-068 |
| 55 | `canonical/skills/aid-create-ticket/SKILL.md:183` | [State: X] | `**Advance:** **CHAIN** → [State: CONFIRM] (continue inline).` | task-068 |
| 56 | `canonical/skills/aid-create-ticket/SKILL.md:212` | [State: X] | `**Advance:** **CHAIN** → [State: FILE] once the user has chosen `[1] File it`; **CHAIN** → [State: COMPOSE] on `[2] E...` | task-068 |
| 57 | `canonical/skills/aid-create-ticket/SKILL.md:230` | [State: X] | `**Advance:** **CHAIN** → [State: RETURN-REF] (continue inline).` | task-068 |
| 58 | `canonical/skills/aid-define/SKILL.md:219` | you are here | `Print the state-entry line and "you are here" map. Examples for each state:` | task-064 |
| 59 | `canonical/skills/aid-define/SKILL.md:223` | [State: X] | `[State: FEATURE-DECOMPOSITION] — Decompose approved requirements into § 11 feature sections.` | task-064 |
| 60 | `canonical/skills/aid-define/SKILL.md:224` | you are here | `aid-define  ▸ you are here` | task-064 |
| 61 | `canonical/skills/aid-define/SKILL.md:231` | [State: X] | `[State: CROSS-REFERENCE] — Validate REQUIREMENTS.md against KB and codebase; create Q&A for gaps.` | task-064 |
| 62 | `canonical/skills/aid-define/SKILL.md:232` | you are here | `aid-define  ▸ you are here` | task-064 |
| 63 | `canonical/skills/aid-define/SKILL.md:238` | [State: X] | `[State: DONE] — Interview complete, approved, decomposed, and cross-referenced.` | task-064 |
| 64 | `canonical/skills/aid-define/SKILL.md:239` | you are here | `aid-define  ▸ you are here` | task-064 |
| 65 | `canonical/skills/aid-define/SKILL.md:253` | [State: X] | `On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.` | task-064 |
| 66 | `canonical/skills/aid-define/references/state-cross-reference.md:25` | [State N] Dispatching | `Print before dispatch: `[State 6] Dispatching aid-reviewer for Cross-Reference validation.`` | task-064 |
| 67 | `canonical/skills/aid-define/references/state-cross-reference.md:47` | [State: X] | `**Advance:** **CHAIN** → [State: DONE] once the cross-reference questions are answered and their answers applied.` | task-064 |
| 68 | `canonical/skills/aid-define/references/state-done.md:45` | [State: X] | `**Advance:** **CHAIN** → [State: CROSS-REFERENCE] when the user picks [2]; **HALT** when the user picks another option.` | task-064 |
| 69 | `canonical/skills/aid-define/references/state-feature-decomposition.md:13` | [State N] Dispatching | `**Agent:** This is design work, not interview work. Dispatch with `subagent_type: aid-architect` (overriding the defa...` | task-064 |
| 70 | `canonical/skills/aid-define/references/state-feature-decomposition.md:26` | [State: X] | `**Advance:** **CHAIN** → [State: CROSS-REFERENCE] once the feature sections are written (continue inline).` | task-064 |
| 71 | `canonical/skills/aid-deploy/SKILL.md:119` | you are here | `Print the state-entry line and "you are here" map:` | task-068 |
| 72 | `canonical/skills/aid-deploy/SKILL.md:123` | [State: X] | `[State: IDLE] — No active release; begin assessing eligible deliveries.` | task-068 |
| 73 | `canonical/skills/aid-deploy/SKILL.md:124` | you are here | `aid-deploy  ▸ you are here` | task-068 |
| 74 | `canonical/skills/aid-deploy/SKILL.md:130` | [State: X] | `[State: SELECTING] — Presenting eligible deliveries for user to include in this release.` | task-068 |
| 75 | `canonical/skills/aid-deploy/SKILL.md:131` | you are here | `aid-deploy  ▸ you are here` | task-068 |
| 76 | `canonical/skills/aid-deploy/SKILL.md:137` | [State: X] | `[State: VERIFYING] — Running full build, tests, and lint against selected deliveries.` | task-068 |
| 77 | `canonical/skills/aid-deploy/SKILL.md:138` | you are here | `aid-deploy  ▸ you are here` | task-068 |
| 78 | `canonical/skills/aid-deploy/SKILL.md:144` | [State: X] | `[State: FIX-DECISION] — Checks failed; the user decides whether to fix here or loop back to aid-execute.` | task-068 |
| 79 | `canonical/skills/aid-deploy/SKILL.md:145` | [State: X] | `[State: RE-VERIFY] — Fixing the failed checks here, then running them again.` | task-068 |
| 80 | `canonical/skills/aid-deploy/SKILL.md:146` | you are here | `aid-deploy  ▸ you are here` | task-068 |
| 81 | `canonical/skills/aid-deploy/SKILL.md:152` | [State: X] | `[State: PACKAGING] — Producing release artifacts per infrastructure.md § Deployment.` | task-068 |
| 82 | `canonical/skills/aid-deploy/SKILL.md:153` | you are here | `aid-deploy  ▸ you are here` | task-068 |
| 83 | `canonical/skills/aid-deploy/SKILL.md:159` | [State: X] | `[State: DONE] — Release complete; all deliveries and tasks marked Shipped.` | task-068 |
| 84 | `canonical/skills/aid-deploy/SKILL.md:160` | you are here | `aid-deploy  ▸ you are here` | task-068 |
| 85 | `canonical/skills/aid-deploy/SKILL.md:197` | [State: X] | `On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.` | task-068 |
| 86 | `canonical/skills/aid-deploy/references/state-fix-decision.md:19` | [State: X] | `**Advance:** **CHAIN** → [State: RE-VERIFY] when the user chooses to fix here; **HALT** when the user loops back to` | task-068 |
| 87 | `canonical/skills/aid-deploy/references/state-idle.md:33` | [State: X] | `**Advance:** **CHAIN** → [State: SELECTING] (continue inline).` | task-068 |
| 88 | `canonical/skills/aid-deploy/references/state-packaging.md:98` | [State: X] | `**Advance:** **CHAIN** → [State: DONE] (continue inline; see `references/state-done.md`).` | task-068 |
| 89 | `canonical/skills/aid-deploy/references/state-re-run.md:6` | [State: X] | `[State: RE-RUN] — Prior release found; confirming whether to start a new release or review.` | task-068 |
| 90 | `canonical/skills/aid-deploy/references/state-re-run.md:7` | you are here | `aid-deploy  ▸ you are here` | task-068 |
| 91 | `canonical/skills/aid-deploy/references/state-re-run.md:19` | [State: X] | `**Advance:** **CHAIN** → [State: IDLE] on [1] New release; **HALT** on [2] Review package-NNN.` | task-068 |
| 92 | `canonical/skills/aid-deploy/references/state-re-verify.md:16` | [State: X] | `**Advance:** **CHAIN** → [State: PACKAGING] (continue inline) when every check passes; **CHAIN** → [State: FIX-DECISI...` | task-068 |
| 93 | `canonical/skills/aid-deploy/references/state-selecting.md:49` | [State: X] | `**Advance:** **CHAIN** → [State: VERIFYING] once the user has chosen the deliveries, given the version and package na...` | task-068 |
| 94 | `canonical/skills/aid-deploy/references/state-verifying.md:46` | [State: X] | `**Advance:** **CHAIN** → [State: PACKAGING] (continue inline) when every check passes; **CHAIN** → [State: FIX-DECISI...` | task-068 |
| 95 | `canonical/skills/aid-describe/SKILL.md:197` | you are here | `Print the state-entry line and "you are here" map. Examples for each state:` | task-063 |
| 96 | `canonical/skills/aid-describe/SKILL.md:201` | [State: X] | `[State: FIRST-RUN] — Start a new interview from scratch; create STATE.md and REQUIREMENTS.md scaffold.` | task-063 |
| 97 | `canonical/skills/aid-describe/SKILL.md:202` | you are here | `aid-describe  ▸ you are here` | task-063 |
| 98 | `canonical/skills/aid-describe/SKILL.md:208` | [State: X] | `[State: Q-AND-A] — Resolve pending cross-phase questions before continuing.` | task-063 |
| 99 | `canonical/skills/aid-describe/SKILL.md:209` | you are here | `aid-describe  ▸ you are here` | task-063 |
| 100 | `canonical/skills/aid-describe/SKILL.md:215` | [State: X] | `[State: CONTINUE] — Resume the conversational interview for incomplete sections.` | task-063 |
| 101 | `canonical/skills/aid-describe/SKILL.md:216` | you are here | `aid-describe  ▸ you are here` | task-063 |
| 102 | `canonical/skills/aid-describe/SKILL.md:222` | [State: X] | `[State: COMPLETION] — All sections captured; run KB hydration and present requirements for approval.` | task-063 |
| 103 | `canonical/skills/aid-describe/SKILL.md:223` | you are here | `aid-describe  ▸ you are here` | task-063 |
| 104 | `canonical/skills/aid-describe/SKILL.md:229` | [State: X] | `[State: DESCRIBE-SEED] — Authoring forward-authored KB seed from elicited intent (greenfield mode).` | task-063 |
| 105 | `canonical/skills/aid-describe/SKILL.md:230` | you are here | `aid-describe  ▸ you are here` | task-063 |
| 106 | `canonical/skills/aid-describe/SKILL.md:247` | [State: X] | `On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.` | task-063 |
| 107 | `canonical/skills/aid-describe/references/state-completion.md:159` | [State: X] | `**Advance:** **CHAIN** → [State: CONTINUE] when the user adds a consideration; **HALT** when the user approves the re...` | task-063 |
| 108 | `canonical/skills/aid-describe/references/state-continue.md:45` | [State: X] | `**Advance:** **CHAIN** → [State: DESCRIBE-SEED] when the work is greenfield (no brownfield KB on disk) and its seed i...` | task-063 |
| 109 | `canonical/skills/aid-describe/references/state-describe-seed.md:242` | [State: X] | `[State: DESCRIBE-SEED] -- Authoring forward-authored KB seed (greenfield mode).` | task-063 |
| 110 | `canonical/skills/aid-describe/references/state-describe-seed.md:243` | you are here | `aid-describe > you are here` | task-063 |
| 111 | `canonical/skills/aid-describe/references/state-describe-seed.md:516` | [State: X] | `**Advance:** **CHAIN** → [State: COMPLETION]` | task-063 |
| 112 | `canonical/skills/aid-describe/references/state-first-run.md:79` | [State: X] | `**Advance:** **CHAIN** → [State: CONTINUE].` | task-063 |
| 113 | `canonical/skills/aid-describe/references/state-q-and-a.md:64` | [State: X] | `**Advance:** **CHAIN** → [State: CONTINUE] (continue inline).` | task-063 |
| 114 | `canonical/skills/aid-design-api/SKILL.md:31` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 115 | `canonical/skills/aid-design-api/SKILL.md:51` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 116 | `canonical/skills/aid-design-api/SKILL.md:65` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 117 | `canonical/skills/aid-design-api/SKILL.md:74` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 118 | `canonical/skills/aid-design-architecture/SKILL.md:36` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 119 | `canonical/skills/aid-design-architecture/SKILL.md:56` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 120 | `canonical/skills/aid-design-architecture/SKILL.md:84` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 121 | `canonical/skills/aid-design-architecture/SKILL.md:93` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 122 | `canonical/skills/aid-design-backlog/SKILL.md:39` | [State: X] | `the `[State: NAME] -- {purpose}` entry line on each state.` | task-060 |
| 123 | `canonical/skills/aid-design-backlog/SKILL.md:60` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 124 | `canonical/skills/aid-design-backlog/SKILL.md:79` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 125 | `canonical/skills/aid-design-backlog/SKILL.md:89` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 126 | `canonical/skills/aid-design-cicd/SKILL.md:36` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 127 | `canonical/skills/aid-design-cicd/SKILL.md:57` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 128 | `canonical/skills/aid-design-cicd/SKILL.md:83` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 129 | `canonical/skills/aid-design-cicd/SKILL.md:92` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 130 | `canonical/skills/aid-design-cli/SKILL.md:31` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 131 | `canonical/skills/aid-design-cli/SKILL.md:51` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 132 | `canonical/skills/aid-design-cli/SKILL.md:65` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 133 | `canonical/skills/aid-design-cli/SKILL.md:74` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 134 | `canonical/skills/aid-design-config/SKILL.md:35` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 135 | `canonical/skills/aid-design-config/SKILL.md:56` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 136 | `canonical/skills/aid-design-config/SKILL.md:70` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 137 | `canonical/skills/aid-design-config/SKILL.md:79` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 138 | `canonical/skills/aid-design-dashboard/SKILL.md:31` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 139 | `canonical/skills/aid-design-dashboard/SKILL.md:52` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 140 | `canonical/skills/aid-design-dashboard/SKILL.md:66` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 141 | `canonical/skills/aid-design-dashboard/SKILL.md:75` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 142 | `canonical/skills/aid-design-data-model/SKILL.md:33` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 143 | `canonical/skills/aid-design-data-model/SKILL.md:54` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 144 | `canonical/skills/aid-design-data-model/SKILL.md:68` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 145 | `canonical/skills/aid-design-data-model/SKILL.md:77` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 146 | `canonical/skills/aid-design-data-pipeline/SKILL.md:31` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 147 | `canonical/skills/aid-design-data-pipeline/SKILL.md:51` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 148 | `canonical/skills/aid-design-data-pipeline/SKILL.md:65` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 149 | `canonical/skills/aid-design-data-pipeline/SKILL.md:74` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 150 | `canonical/skills/aid-design-document/SKILL.md:35` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 151 | `canonical/skills/aid-design-document/SKILL.md:55` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 152 | `canonical/skills/aid-design-document/SKILL.md:69` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 153 | `canonical/skills/aid-design-document/SKILL.md:78` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 154 | `canonical/skills/aid-design-infra/SKILL.md:35` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 155 | `canonical/skills/aid-design-infra/SKILL.md:56` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 156 | `canonical/skills/aid-design-infra/SKILL.md:70` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 157 | `canonical/skills/aid-design-infra/SKILL.md:79` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 158 | `canonical/skills/aid-design-integration/SKILL.md:32` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 159 | `canonical/skills/aid-design-integration/SKILL.md:53` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 160 | `canonical/skills/aid-design-integration/SKILL.md:67` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 161 | `canonical/skills/aid-design-integration/SKILL.md:76` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 162 | `canonical/skills/aid-design-job/SKILL.md:31` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 163 | `canonical/skills/aid-design-job/SKILL.md:52` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 164 | `canonical/skills/aid-design-job/SKILL.md:66` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 165 | `canonical/skills/aid-design-job/SKILL.md:75` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 166 | `canonical/skills/aid-design-messaging/SKILL.md:31` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 167 | `canonical/skills/aid-design-messaging/SKILL.md:52` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 168 | `canonical/skills/aid-design-messaging/SKILL.md:66` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 169 | `canonical/skills/aid-design-messaging/SKILL.md:75` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 170 | `canonical/skills/aid-design-mvp/SKILL.md:37` | [State: X] | `the `[State: NAME] -- {purpose}` entry line on each state.` | task-060 |
| 171 | `canonical/skills/aid-design-mvp/SKILL.md:57` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 172 | `canonical/skills/aid-design-mvp/SKILL.md:73` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 173 | `canonical/skills/aid-design-mvp/SKILL.md:83` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 174 | `canonical/skills/aid-design-roadmap/SKILL.md:37` | [State: X] | `the `[State: NAME] -- {purpose}` entry line on each state.` | task-060 |
| 175 | `canonical/skills/aid-design-roadmap/SKILL.md:58` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 176 | `canonical/skills/aid-design-roadmap/SKILL.md:74` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 177 | `canonical/skills/aid-design-roadmap/SKILL.md:84` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 178 | `canonical/skills/aid-design-stack/SKILL.md:36` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 179 | `canonical/skills/aid-design-stack/SKILL.md:57` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 180 | `canonical/skills/aid-design-stack/SKILL.md:83` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 181 | `canonical/skills/aid-design-stack/SKILL.md:92` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 182 | `canonical/skills/aid-design-test/SKILL.md:35` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 183 | `canonical/skills/aid-design-test/SKILL.md:55` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 184 | `canonical/skills/aid-design-test/SKILL.md:69` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 185 | `canonical/skills/aid-design-test/SKILL.md:78` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 186 | `canonical/skills/aid-design-testing-strategy/SKILL.md:35` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 187 | `canonical/skills/aid-design-testing-strategy/SKILL.md:56` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 188 | `canonical/skills/aid-design-testing-strategy/SKILL.md:84` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 189 | `canonical/skills/aid-design-testing-strategy/SKILL.md:93` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 190 | `canonical/skills/aid-design-theme/SKILL.md:31` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 191 | `canonical/skills/aid-design-theme/SKILL.md:51` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 192 | `canonical/skills/aid-design-theme/SKILL.md:65` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 193 | `canonical/skills/aid-design-theme/SKILL.md:74` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 194 | `canonical/skills/aid-design-ui/SKILL.md:36` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}`` | task-060 |
| 195 | `canonical/skills/aid-design-ui/SKILL.md:56` | [State: X] | `**Advance:** CHAIN → [State: DESIGN] when the gate allocated a new work; HALT when the user continues an existing wor...` | task-060 |
| 196 | `canonical/skills/aid-design-ui/SKILL.md:70` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-060 |
| 197 | `canonical/skills/aid-design-ui/SKILL.md:79` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: DESIGN] when it is not clean and fewe...` | task-060 |
| 198 | `canonical/skills/aid-design/SKILL.md:31` | [State: X] | `DONE**. Print the `[State: NAME] -- {purpose}` entry line on each state.` | task-060 |
| 199 | `canonical/skills/aid-detail/SKILL.md:67` | you are here | `Print the state-entry line and "you are here" map:` | task-065 |
| 200 | `canonical/skills/aid-detail/SKILL.md:71` | [State: X] | `[State: FIRST-RUN] — No task files yet; begin proposing task breakdown per deliverable.` | task-065 |
| 201 | `canonical/skills/aid-detail/SKILL.md:72` | you are here | `aid-detail  ▸ you are here` | task-065 |
| 202 | `canonical/skills/aid-detail/SKILL.md:78` | [State: X] | `[State: REVIEW] — Existing tasks found; re-review against current PLAN.md and SPECs.` | task-065 |
| 203 | `canonical/skills/aid-detail/SKILL.md:79` | you are here | `aid-detail  ▸ you are here` | task-065 |
| 204 | `canonical/skills/aid-detail/SKILL.md:85` | [State: X] | `[State: DONE] — Task list approved and meets minimum grade.` | task-065 |
| 205 | `canonical/skills/aid-detail/SKILL.md:86` | you are here | `aid-detail  ▸ you are here` | task-065 |
| 206 | `canonical/skills/aid-detail/references/confirm.md:16` | [State: X] | `**Advance:** **CHAIN** → [State: REVIEW] when the user confirms the reopen; **CHAIN** → [State: DONE] when the user k...` | task-065 |
| 207 | `canonical/skills/aid-detail/references/first-run.md:99` | [State: X] | `> **No graded gate here.** FIRST-RUN chains into `[State: REVIEW]`` | task-065 |
| 208 | `canonical/skills/aid-detail/references/first-run.md:131` | [State: X] | `[State: FIRST-RUN] complete.` | task-065 |
| 209 | `canonical/skills/aid-detail/references/first-run.md:136` | [State: X] | `**Advance:** **CHAIN** → [State: REVIEW] once the task breakdown is approved and its files are written.` | task-065 |
| 210 | `canonical/skills/aid-detail/references/review.md:66` | [State: X] | `[State: REVIEW] complete.` | task-065 |
| 211 | `canonical/skills/aid-detail/references/review.md:74` | [State: X] | `**Advance:** **CHAIN** → [State: DONE] (continue inline).` | task-065 |
| 212 | `canonical/skills/aid-discover/SKILL.md:213` | you are here | `Print the state-entry line with description, then the "you are here" state-map. Use one of these depending on the det...` | task-066 |
| 213 | `canonical/skills/aid-discover/SKILL.md:217` | [State: X] | `[State: ELICIT] — Capture the project's external sources and tool integrations before GENERATE runs.` | task-066 |
| 214 | `canonical/skills/aid-discover/SKILL.md:218` | you are here | `aid-discover  ▸ you are here` | task-066 |
| 215 | `canonical/skills/aid-discover/SKILL.md:224` | [State: X] | `[State: GENERATE] — Populate missing KB documents by orchestrating parallel discovery sub-agents.` | task-066 |
| 216 | `canonical/skills/aid-discover/SKILL.md:225` | you are here | `aid-discover  ▸ you are here` | task-066 |
| 217 | `canonical/skills/aid-discover/SKILL.md:231` | [State: X] | `[State: REVIEW] — Grade all KB documents for accuracy, completeness, and evidence quality.` | task-066 |
| 218 | `canonical/skills/aid-discover/SKILL.md:232` | you are here | `aid-discover  ▸ you are here` | task-066 |
| 219 | `canonical/skills/aid-discover/SKILL.md:238` | [State: X] | `[State: Q-AND-A] — Resolve pending questions with the user before attempting automated fixes.` | task-066 |
| 220 | `canonical/skills/aid-discover/SKILL.md:239` | you are here | `aid-discover  ▸ you are here` | task-066 |
| 221 | `canonical/skills/aid-discover/SKILL.md:245` | [State: X] | `[State: FIX] — Apply Q&A answers and reviewer feedback to bring KB documents up to minimum grade.` | task-066 |
| 222 | `canonical/skills/aid-discover/SKILL.md:246` | you are here | `aid-discover  ▸ you are here` | task-066 |
| 223 | `canonical/skills/aid-discover/SKILL.md:252` | [State: X] | `[State: APPROVAL] — KB meets minimum grade; ask the user to confirm it is ready for Interview.` | task-066 |
| 224 | `canonical/skills/aid-discover/SKILL.md:253` | you are here | `aid-discover  ▸ you are here` | task-066 |
| 225 | `canonical/skills/aid-discover/SKILL.md:259` | [State: X] | `[State: DONE] — Discovery is complete and user-approved; KB is ready for Interview.` | task-066 |
| 226 | `canonical/skills/aid-discover/SKILL.md:260` | you are here | `aid-discover  ▸ you are here` | task-066 |
| 227 | `canonical/skills/aid-discover/SKILL.md:315` | [State: X] | `On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.` | task-066 |
| 228 | `canonical/skills/aid-discover/references/state-approval.md:36` | [State: X] | `Print: `[State: APPROVAL] complete.`` | task-066 |
| 229 | `canonical/skills/aid-discover/references/state-approval.md:40` | [State: X] | `**Advance:** **CHAIN** → [State: DONE] on approval; **HALT** on a consideration.` | task-066 |
| 230 | `canonical/skills/aid-discover/references/state-done.md:72` | [State: X] | `Print: `[State: DONE] complete.`` | task-066 |
| 231 | `canonical/skills/aid-discover/references/state-done.md:74` | [State: X] | `**Advance:** **CHAIN** → [State: REVIEW] when the user confirms the reopen; **HALT** when the user keeps the discover...` | task-066 |
| 232 | `canonical/skills/aid-discover/references/state-elicit.md:306` | [State: X] | `Print: `[State: ELICIT] complete -- sources: {Sources}; tools: {Tools} ({Tools step}).`` | task-066 |
| 233 | `canonical/skills/aid-discover/references/state-elicit.md:307` | [State: X] | `Print: `[State: ELICIT] complete.`` | task-066 |
| 234 | `canonical/skills/aid-discover/references/state-elicit.md:309` | [State: X] | `**Advance:** **CHAIN** → [State: GENERATE] (continue inline).` | task-066 |
| 235 | `canonical/skills/aid-discover/references/state-fix.md:123` | [State: X] | `Print: `[State: FIX] complete.`` | task-066 |
| 236 | `canonical/skills/aid-discover/references/state-fix.md:125` | [State: X] | `**Advance:** **CHAIN** → [State: REVIEW] if grade < minimum (rerun review); **CHAIN** → [State: APPROVAL] if grade ≥ ...` | task-066 |
| 237 | `canonical/skills/aid-discover/references/state-generate.md:1082` | [State: X] | `Print: `[State: GENERATE] complete.`` | task-066 |
| 238 | `canonical/skills/aid-discover/references/state-generate.md:1084` | [State: X] | `**Advance:** **CHAIN** → [State: REVIEW] (continue inline); **HALT** when the confirmed discovery path is greenfield ...` | task-066 |
| 239 | `canonical/skills/aid-discover/references/state-q-and-a.md:62` | [State: X] | `Print: `[State: Q-AND-A] complete.`` | task-066 |
| 240 | `canonical/skills/aid-discover/references/state-q-and-a.md:66` | [State: X] | `**Advance:** **CHAIN** → [State: FIX] when any answer implies a doc change; **CHAIN** → [State: APPROVAL] when no ans...` | task-066 |
| 241 | `canonical/skills/aid-discover/references/state-review.md:585` | [State: X] | `Print: `[State: REVIEW] complete.`` | task-066 |
| 242 | `canonical/skills/aid-discover/references/state-review.md:587` | [State: X] | `**Advance:** **CHAIN** → [State: Q-AND-A] if Pending Q&A entries with Impact: Required` | task-066 |
| 243 | `canonical/skills/aid-discover/references/state-review.md:588` | [State: X] | `exist; **CHAIN** → [State: FIX] when none exists. Both continue inline.` | task-066 |
| 244 | `canonical/skills/aid-execute/SKILL.md:123` | you are here | `Print the state-entry line and "you are here" map:` | task-065 |
| 245 | `canonical/skills/aid-execute/SKILL.md:127` | [State: X] | `[State: EXECUTE] — Running the executor agent to produce task deliverables.` | task-065 |
| 246 | `canonical/skills/aid-execute/SKILL.md:128` | you are here | `aid-execute  ▸ you are here` | task-065 |
| 247 | `canonical/skills/aid-execute/SKILL.md:134` | [State: X] | `[State: REVIEW] — Grading task output against acceptance criteria with a clean-context reviewer.` | task-065 |
| 248 | `canonical/skills/aid-execute/SKILL.md:135` | you are here | `aid-execute  ▸ you are here` | task-065 |
| 249 | `canonical/skills/aid-execute/SKILL.md:141` | [State: X] | `[State: FIX] — Resuming a task saved at FIX: applying its CODE-issue fixes, then REVIEW.` | task-065 |
| 250 | `canonical/skills/aid-execute/SKILL.md:142` | you are here | `aid-execute  ▸ you are here` | task-065 |
| 251 | `canonical/skills/aid-execute/SKILL.md:148` | [State: X] | `[State: DONE] — Grade meets minimum; task complete.` | task-065 |
| 252 | `canonical/skills/aid-execute/SKILL.md:149` | you are here | `aid-execute  ▸ you are here` | task-065 |
| 253 | `canonical/skills/aid-execute/SKILL.md:226` | [State: X] | `On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.` | task-065 |
| 254 | `canonical/skills/aid-execute/references/state-delivery-gate.md:16` | [State: X] | `[State: DELIVERY-GATE] — Per-delivery quality gate running.` | task-065 |
| 255 | `canonical/skills/aid-execute/references/state-delivery-gate.md:17` | you are here | `aid-execute  ▸ you are here` | task-065 |
| 256 | `canonical/skills/aid-execute/references/state-execute.md:782` | [State: X] | `**Advance:** **CHAIN** → [State: REVIEW] (continue inline).` | task-065 |
| 257 | `canonical/skills/aid-execute/references/state-fix.md:183` | [State: X] | `**Advance:** **CHAIN** → [State: REVIEW] (continue inline).` | task-065 |
| 258 | `canonical/skills/aid-execute/references/state-re-run.md:10` | [State: X] | `[State: RE-RUN] — Task already Done; confirming whether to reopen for review.` | task-065 |
| 259 | `canonical/skills/aid-execute/references/state-re-run.md:11` | you are here | `aid-execute  ▸ you are here` | task-065 |
| 260 | `canonical/skills/aid-execute/references/state-re-run.md:23` | [State: X] | `**Advance:** **CHAIN** → [State: REVIEW], once the user has confirmed the reopen; **HALT** when the task stays Done.` | task-065 |
| 261 | `canonical/skills/aid-execute/references/state-review.md:186` | [State: X] | `**Advance:** **CHAIN** → [State: DONE] once the triage, the findings write and the terminal State write are done; **H...` | task-065 |
| 262 | `canonical/skills/aid-housekeep/SKILL.md:196` | [State: X] | `[State: PREFLIGHT] — Verifying prerequisites: .aid/ exists, not Plan Mode, git repo present.` | task-067 |
| 263 | `canonical/skills/aid-housekeep/SKILL.md:197` | you are here | `aid-housekeep  ▸ you are here` | task-067 |
| 264 | `canonical/skills/aid-housekeep/SKILL.md:203` | [State: X] | `[State: KB-DELTA] — Detecting KB delta since last approval; dispatching targeted re-discovery.` | task-067 |
| 265 | `canonical/skills/aid-housekeep/SKILL.md:204` | you are here | `aid-housekeep  ▸ you are here` | task-067 |
| 266 | `canonical/skills/aid-housekeep/SKILL.md:210` | [State: X] | `[State: SUMMARY-DELTA] — Checking whether the visual summary needs regeneration.` | task-067 |
| 267 | `canonical/skills/aid-housekeep/SKILL.md:211` | you are here | `aid-housekeep  ▸ you are here` | task-067 |
| 268 | `canonical/skills/aid-housekeep/SKILL.md:217` | [State: X] | `[State: CLEANUP] — Sweeping stale work-area artifacts.` | task-067 |
| 269 | `canonical/skills/aid-housekeep/SKILL.md:218` | you are here | `aid-housekeep  ▸ you are here` | task-067 |
| 270 | `canonical/skills/aid-housekeep/SKILL.md:224` | [State: X] | `[State: DONE] — Housekeeping complete.` | task-067 |
| 271 | `canonical/skills/aid-housekeep/SKILL.md:225` | you are here | `aid-housekeep  ▸ you are here` | task-067 |
| 272 | `canonical/skills/aid-housekeep/SKILL.md:248` | [State: X] | `On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.` | task-067 |
| 273 | `canonical/skills/aid-housekeep/references/state-cleanup.md:34` | [State: X] | `Print the `[State: CLEANUP]` banner from `SKILL.md § State Detection`:` | task-067 |
| 274 | `canonical/skills/aid-housekeep/references/state-cleanup.md:37` | [State: X] | `[State: CLEANUP] — Sweeping stale work-area artifacts.` | task-067 |
| 275 | `canonical/skills/aid-housekeep/references/state-cleanup.md:38` | you are here | `aid-housekeep  ▸ you are here` | task-067 |
| 276 | `canonical/skills/aid-housekeep/references/state-cleanup.md:119` | [State: X] | `**No commit is made.** Advance: **CHAIN** → [State: DONE].` | task-067 |
| 277 | `canonical/skills/aid-housekeep/references/state-cleanup.md:256` | [State: X] | `Advance: **CHAIN** → [State: DONE].` | task-067 |
| 278 | `canonical/skills/aid-housekeep/references/state-cleanup.md:539` | [State: X] | `**Advance:** **CHAIN** → [State: DONE] (continue inline).` | task-067 |
| 279 | `canonical/skills/aid-housekeep/references/state-kb-delta.md:58` | [State: X] | `Print the `[State: KB-DELTA]` banner from `SKILL.md S State Detection`.` | task-067 |
| 280 | `canonical/skills/aid-housekeep/references/state-preflight.md:113` | [State: X] | `Print: `[State: PREFLIGHT] complete.`` | task-067 |
| 281 | `canonical/skills/aid-housekeep/references/state-preflight.md:115` | [State: X] | `**Advance:** **CHAIN** → [State: CLEANUP] when `--cleanup-only` was set (see `SKILL.md § Arguments`);` | task-067 |
| 282 | `canonical/skills/aid-housekeep/references/state-preflight.md:116` | [State: X] | `otherwise **CHAIN** → [State: KB-DELTA].` | task-067 |
| 283 | `canonical/skills/aid-housekeep/references/state-summary-delta.md:62` | [State: X] | `[State: SUMMARY-DELTA] — Checking whether the visual summary needs regeneration.` | task-067 |
| 284 | `canonical/skills/aid-housekeep/references/state-summary-delta.md:63` | you are here | `aid-housekeep  ▸ you are here` | task-067 |
| 285 | `canonical/skills/aid-housekeep/references/state-summary-delta.md:355` | [State: X] | `**Advance:** **CHAIN** → [State: CLEANUP] when the stage did not stall; **HALT** when it stalled.` | task-067 |
| 286 | `canonical/skills/aid-monitor/SKILL.md:104` | you are here | `Print the state-entry line and "you are here" map:` | task-068 |
| 287 | `canonical/skills/aid-monitor/SKILL.md:108` | [State: X] | `[State: OBSERVE] — Pulling telemetry signals and correlating against baselines.` | task-068 |
| 288 | `canonical/skills/aid-monitor/SKILL.md:109` | you are here | `aid-monitor  ▸ you are here` | task-068 |
| 289 | `canonical/skills/aid-monitor/SKILL.md:115` | [State: X] | `[State: CLASSIFY] — Classifying each anomaly as BUG, CHANGE REQUEST, INFRASTRUCTURE, or NO ACTION.` | task-068 |
| 290 | `canonical/skills/aid-monitor/SKILL.md:116` | you are here | `aid-monitor  ▸ you are here` | task-068 |
| 291 | `canonical/skills/aid-monitor/SKILL.md:122` | [State: X] | `[State: ROUTE] — Proposing and executing routing actions per finding classification.` | task-068 |
| 292 | `canonical/skills/aid-monitor/SKILL.md:123` | you are here | `aid-monitor  ▸ you are here` | task-068 |
| 293 | `canonical/skills/aid-monitor/SKILL.md:129` | [State: X] | `[State: DONE] — All findings routed; monitor cycle complete.` | task-068 |
| 294 | `canonical/skills/aid-monitor/SKILL.md:130` | you are here | `aid-monitor  ▸ you are here` | task-068 |
| 295 | `canonical/skills/aid-monitor/SKILL.md:225` | [State: X] | `On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.` | task-068 |
| 296 | `canonical/skills/aid-monitor/SKILL.md:233` | [State: X] | `[State: RE-RUN] — Prior findings on record; confirming whether to run fresh or review a finding.` | task-068 |
| 297 | `canonical/skills/aid-monitor/SKILL.md:234` | you are here | `aid-monitor  ▸ you are here` | task-068 |
| 298 | `canonical/skills/aid-monitor/references/state-classify.md:45` | [State: X] | `**Advance:** **CHAIN** → [State: ROUTE] (continue inline).` | task-068 |
| 299 | `canonical/skills/aid-monitor/references/state-observe.md:34` | [State: X] | `**Advance:** **CHAIN** → [State: CLASSIFY] (continue inline).` | task-068 |
| 300 | `canonical/skills/aid-plan/SKILL.md:125` | you are here | `Print the state-entry line and "you are here" map:` | task-065 |
| 301 | `canonical/skills/aid-plan/SKILL.md:129` | [State: X] | `[State: FIRST-RUN] — No PLAN.md found; begin dependency mapping and deliverable sequencing.` | task-065 |
| 302 | `canonical/skills/aid-plan/SKILL.md:130` | you are here | `aid-plan  ▸ you are here` | task-065 |
| 303 | `canonical/skills/aid-plan/SKILL.md:136` | [State: X] | `[State: REVIEW] — PLAN.md exists; re-review deliverables against current SPECs and KB.` | task-065 |
| 304 | `canonical/skills/aid-plan/SKILL.md:137` | you are here | `aid-plan  ▸ you are here` | task-065 |
| 305 | `canonical/skills/aid-plan/SKILL.md:143` | [State: X] | `[State: DONE] — Plan is complete and meets minimum grade.` | task-065 |
| 306 | `canonical/skills/aid-plan/SKILL.md:144` | you are here | `aid-plan  ▸ you are here` | task-065 |
| 307 | `canonical/skills/aid-plan/SKILL.md:169` | [State: X] | `On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.` | task-065 |
| 308 | `canonical/skills/aid-plan/SKILL.md:177` | [State: X] | `[State: DONE] — Plan is complete and meets minimum grade.` | task-065 |
| 309 | `canonical/skills/aid-plan/SKILL.md:178` | you are here | `aid-plan  ▸ you are here` | task-065 |
| 310 | `canonical/skills/aid-plan/references/confirm-reopen.md:12` | [State: X] | `**Advance:** **ASK** → [State: REVIEW].` | task-065 |
| 311 | `canonical/skills/aid-plan/references/first-run-loop.md:237` | [State: X] | `**Advance:** **CHAIN** → [State: REVIEW] when the user approves the sequence; **HALT** when the user declines the plan.` | task-065 |
| 312 | `canonical/skills/aid-plan/references/review-deliverables.md:75` | [State: X] | `**Advance:** **CHAIN** → [State: DONE] when the grade meets minimum and all delivery folders are created; **CHAIN** →...` | task-065 |
| 313 | `canonical/skills/aid-prototype/SKILL.md:20` | [State: X] | `decides] -> HANDOFF? -> DONE**. Print the `[State: NAME] -- {purpose}` entry line on each state.` | task-069 |
| 314 | `canonical/skills/aid-prototype/SKILL.md:47` | [State: X] | `**Advance:** CHAIN → [State: INTAKE-ASK] when any of these holds: the argument is empty, the path is Guided, works ex...` | task-069 |
| 315 | `canonical/skills/aid-prototype/SKILL.md:61` | [State: X] | `**Advance:** ASK → [State: ALLOCATE].` | task-069 |
| 316 | `canonical/skills/aid-prototype/SKILL.md:85` | [State: X] | `**Advance:** CHAIN → [State: BUILD].` | task-069 |
| 317 | `canonical/skills/aid-prototype/SKILL.md:98` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-069 |
| 318 | `canonical/skills/aid-prototype/SKILL.md:111` | [State: X] | `**Advance:** CHAIN → [State: BUILD] when the check fails the first time; otherwise CHAIN → [State: PRESENT].` | task-069 |
| 319 | `canonical/skills/aid-prototype/SKILL.md:121` | [State: X] | `**Advance:** ASK → [State: HANDOFF].` | task-069 |
| 320 | `canonical/skills/aid-prototype/SKILL.md:132` | [State: X] | `**Advance:** ASK → [State: DONE].` | task-069 |
| 321 | `canonical/skills/aid-report/SKILL.md:23` | [State: X] | `resolves] -> HANDOFF? -> DONE**. Print the `[State: NAME] -- {purpose}` entry line on each state.` | task-069 |
| 322 | `canonical/skills/aid-report/SKILL.md:49` | [State: X] | `**Advance:** CHAIN → [State: INTAKE-ASK] when any of these holds: the argument is empty, the path is Guided, works ex...` | task-069 |
| 323 | `canonical/skills/aid-report/SKILL.md:62` | [State: X] | `**Advance:** ASK → [State: ALLOCATE].` | task-069 |
| 324 | `canonical/skills/aid-report/SKILL.md:83` | [State: X] | `**Advance:** CHAIN → [State: ANALYZE].` | task-069 |
| 325 | `canonical/skills/aid-report/SKILL.md:102` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-069 |
| 326 | `canonical/skills/aid-report/SKILL.md:118` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the grade is clean; CHAIN → [State: ANALYZE] when it is not clean and fewe...` | task-069 |
| 327 | `canonical/skills/aid-report/SKILL.md:128` | [State: X] | `**Advance:** ASK → [State: HANDOFF].` | task-069 |
| 328 | `canonical/skills/aid-report/SKILL.md:140` | [State: X] | `**Advance:** ASK → [State: DONE].` | task-069 |
| 329 | `canonical/skills/aid-research/SKILL.md:24` | [State: X] | `(loop) -> PRESENT [human resolves] -> HANDOFF? -> DONE**. Print the `[State: NAME] -- {purpose}` entry line` | task-069 |
| 330 | `canonical/skills/aid-research/SKILL.md:54` | [State: X] | `**Advance:** CHAIN → [State: INTAKE-ASK] when any of these holds: the argument is empty, the path is Guided, works ex...` | task-069 |
| 331 | `canonical/skills/aid-research/SKILL.md:67` | [State: X] | `**Advance:** ASK → [State: ALLOCATE].` | task-069 |
| 332 | `canonical/skills/aid-research/SKILL.md:89` | [State: X] | `**Advance:** CHAIN → [State: INVESTIGATE].` | task-069 |
| 333 | `canonical/skills/aid-research/SKILL.md:109` | [State: X] | `**Advance:** CHAIN → [State: PROPOSE-SPIKE] when the researcher returned a spike proposal; otherwise CHAIN → [State: ...` | task-069 |
| 334 | `canonical/skills/aid-research/SKILL.md:124` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-069 |
| 335 | `canonical/skills/aid-research/SKILL.md:146` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the grade is clean; CHAIN → [State: INVESTIGATE] when it is not clean and ...` | task-069 |
| 336 | `canonical/skills/aid-research/SKILL.md:157` | [State: X] | `**Advance:** ASK → [State: HANDOFF].` | task-069 |
| 337 | `canonical/skills/aid-research/SKILL.md:170` | [State: X] | `**Advance:** ASK → [State: DONE].` | task-069 |
| 338 | `canonical/skills/aid-review/SKILL.md:25` | [State: X] | `(`[State: NAME] -- {one-line purpose}`), the convention every AID skill uses.` | task-069 |
| 339 | `canonical/skills/aid-review/SKILL.md:93` | [State: X] | `**Advance:** CHAIN → [State: INTAKE-ASK] when any of these holds: the argument is empty, the path is guided, works ex...` | task-069 |
| 340 | `canonical/skills/aid-review/SKILL.md:106` | [State: X] | `**Advance:** ASK → [State: ALLOCATE].` | task-069 |
| 341 | `canonical/skills/aid-review/SKILL.md:127` | [State: X] | `**Advance:** CHAIN → [State: REVIEW].` | task-069 |
| 342 | `canonical/skills/aid-review/SKILL.md:152` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-069 |
| 343 | `canonical/skills/aid-review/SKILL.md:176` | [State: X] | `**Advance:** CHAIN → [State: PRESENT-FINDINGS] when the grade is clean; CHAIN → [State: REVIEW] when it is not clean ...` | task-069 |
| 344 | `canonical/skills/aid-review/SKILL.md:193` | [State: X] | `**Advance:** ASK → [State: PUBLISH].` | task-069 |
| 345 | `canonical/skills/aid-review/SKILL.md:209` | [State: X] | `**Advance:** CHAIN → [State: DONE].` | task-069 |
| 346 | `canonical/skills/aid-specify/SKILL.md:133` | [Resolved: | `**If found:** Print: `[Resolved: REQUIREMENTS.md §11 / Feature 001 — {Title}]`` | task-064 |
| 347 | `canonical/skills/aid-specify/SKILL.md:189` | you are here | `Print the state-entry line and "you are here" map. Examples for INITIALIZE:` | task-064 |
| 348 | `canonical/skills/aid-specify/SKILL.md:192` | [State: X] | `[State: INITIALIZE] — First run for this feature; load context, determine sections, begin The Loop.` | task-064 |
| 349 | `canonical/skills/aid-specify/SKILL.md:193` | you are here | `aid-specify ({feature})  ▸ you are here` | task-064 |
| 350 | `canonical/skills/aid-specify/SKILL.md:199` | [State: X] | `[State: CONTINUE] — Resume The Loop (Propose → Discuss → Write → Review) for the next pending section.` | task-064 |
| 351 | `canonical/skills/aid-specify/SKILL.md:200` | you are here | `aid-specify ({feature})  ▸ you are here` | task-064 |
| 352 | `canonical/skills/aid-specify/SKILL.md:206` | [State: X] | `[State: REVIEW] — All sections complete; re-review entire spec against current KB and codebase.` | task-064 |
| 353 | `canonical/skills/aid-specify/SKILL.md:207` | you are here | `aid-specify ({feature})  ▸ you are here` | task-064 |
| 354 | `canonical/skills/aid-specify/SKILL.md:213` | [State: X] | `[State: DONE] — Spec is Ready and has met the minimum grade.` | task-064 |
| 355 | `canonical/skills/aid-specify/SKILL.md:214` | you are here | `aid-specify ({feature})  ▸ you are here` | task-064 |
| 356 | `canonical/skills/aid-specify/SKILL.md:220` | [State: X] | `[State: SPIKE] — Feature has unknowns requiring investigation; spike work needed.` | task-064 |
| 357 | `canonical/skills/aid-specify/SKILL.md:221` | you are here | `aid-specify ({feature})  ▸ you are here` | task-064 |
| 358 | `canonical/skills/aid-specify/SKILL.md:227` | [State: X] | `[State: BLOCKED] — Feature has a pending loopback that must be resolved before continuing.` | task-064 |
| 359 | `canonical/skills/aid-specify/SKILL.md:228` | you are here | `aid-specify ({feature})  ▸ you are here` | task-064 |
| 360 | `canonical/skills/aid-specify/SKILL.md:245` | [State: X] | `On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.` | task-064 |
| 361 | `canonical/skills/aid-specify/references/state-blocked.md:18` | [State: X] | `**Advance:** **WAIT** → [State: CONTINUE].` | task-064 |
| 362 | `canonical/skills/aid-specify/references/state-continue.md:121` | [State: X] | `**Advance:** **CHAIN** → [State: REVIEW] when all sections are Complete; **CHAIN** → [State: SPIKE] when a spike is n...` | task-064 |
| 363 | `canonical/skills/aid-specify/references/state-initialize.md:144` | [State: X] | `**Advance:** **CHAIN** → [State: CONTINUE].` | task-064 |
| 364 | `canonical/skills/aid-specify/references/state-review.md:94` | [State: X] | `**Advance:** **CHAIN** → [State: DONE] when the spec stays Ready; **CHAIN** → [State: CONTINUE] when the grade is bel...` | task-064 |
| 365 | `canonical/skills/aid-specify/references/state-spike.md:21` | [State: X] | `**Advance:** **WAIT** → [State: CONTINUE].` | task-064 |
| 366 | `canonical/skills/aid-summarize/SKILL.md:122` | you are here | `Print the state-entry line and "you are here" map at the start of each mode:` | task-067 |
| 367 | `canonical/skills/aid-summarize/SKILL.md:126` | [State: X] | `[State: PREFLIGHT] — Verifying prerequisites: KB approved, Node.js available, network reachable.` | task-067 |
| 368 | `canonical/skills/aid-summarize/SKILL.md:127` | you are here | `aid-summarize  ▸ you are here` | task-067 |
| 369 | `canonical/skills/aid-summarize/SKILL.md:133` | [State: X] | `[State: STALE-CHECK] — Comparing KB review date vs last summary date to determine if regeneration is needed.` | task-067 |
| 370 | `canonical/skills/aid-summarize/SKILL.md:134` | you are here | `aid-summarize  ▸ you are here` | task-067 |
| 371 | `canonical/skills/aid-summarize/SKILL.md:140` | [State: X] | `[State: PROFILE] — Reading doc-set from .aid/settings.yml and domain from .aid/knowledge/STATE.md to derive the secti...` | task-067 |
| 372 | `canonical/skills/aid-summarize/SKILL.md:141` | you are here | `aid-summarize  ▸ you are here` | task-067 |
| 373 | `canonical/skills/aid-summarize/SKILL.md:147` | [State: X] | `[State: GENERATE] — Building kb.html from resolved doc-set and KB frontmatter (one section per resolved doc).` | task-067 |
| 374 | `canonical/skills/aid-summarize/SKILL.md:148` | you are here | `aid-summarize  ▸ you are here` | task-067 |
| 375 | `canonical/skills/aid-summarize/SKILL.md:154` | [State: X] | `[State: VALIDATE] — Running machine-verifiable quality checks (visual fidelity, links, HTML, contrast).` | task-067 |
| 376 | `canonical/skills/aid-summarize/SKILL.md:155` | you are here | `aid-summarize  ▸ you are here` | task-067 |
| 377 | `canonical/skills/aid-summarize/SKILL.md:161` | [State: X] | `[State: APPROVAL] — Both Machine and Human grades meet minimum; awaiting user approval.` | task-067 |
| 378 | `canonical/skills/aid-summarize/SKILL.md:162` | you are here | `aid-summarize  ▸ you are here` | task-067 |
| 379 | `canonical/skills/aid-summarize/SKILL.md:168` | [State: X] | `[State: DONE] — Summary approved and Summarization History updated.` | task-067 |
| 380 | `canonical/skills/aid-summarize/SKILL.md:169` | you are here | `aid-summarize  ▸ you are here` | task-067 |
| 381 | `canonical/skills/aid-summarize/SKILL.md:190` | [State: X] | `On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.` | task-067 |
| 382 | `canonical/skills/aid-summarize/references/state-approval.md:54` | [State: X] | `Print: `[State: APPROVAL] complete.`` | task-067 |
| 383 | `canonical/skills/aid-summarize/references/state-approval.md:56` | [State: X] | `**Advance:** **CHAIN** → [State: WRITEBACK] when the user approves; **CHAIN** → [State: FIX] when changes are needed;...` | task-067 |
| 384 | `canonical/skills/aid-summarize/references/state-done.md:19` | [State: X] | `[State: DONE]` | task-067 |
| 385 | `canonical/skills/aid-summarize/references/state-done.md:37` | [State: X] | `[State: DONE]` | task-067 |
| 386 | `canonical/skills/aid-summarize/references/state-fix.md:36` | [State: X] | `Print: `[State: FIX] complete.`` | task-067 |
| 387 | `canonical/skills/aid-summarize/references/state-fix.md:38` | [State: X] | `**Advance:** **CHAIN** → [State: VALIDATE] (continue inline).` | task-067 |
| 388 | `canonical/skills/aid-summarize/references/state-generate.md:375` | [State: X] | `Print: `[State: GENERATE] complete.`` | task-067 |
| 389 | `canonical/skills/aid-summarize/references/state-generate.md:377` | [State: X] | `**Advance:** **CHAIN** → [State: VALIDATE] (continue inline).` | task-067 |
| 390 | `canonical/skills/aid-summarize/references/state-manual-checklist.md:37` | [State: X] | `Print: `[State: MANUAL-CHECKLIST] complete.`` | task-067 |
| 391 | `canonical/skills/aid-summarize/references/state-manual-checklist.md:39` | [State: X] | `**Advance:** **CHAIN** → [State: APPROVAL] when Overall Grade ≥ minimum; **CHAIN** → [State: FIX] otherwise.` | task-067 |
| 392 | `canonical/skills/aid-summarize/references/state-preflight.md:21` | [State: X] | `Print: `[State: PREFLIGHT] complete.`` | task-067 |
| 393 | `canonical/skills/aid-summarize/references/state-preflight.md:23` | [State: X] | `**Advance:** **CHAIN** → [State: STALE-CHECK] (continue inline).` | task-067 |
| 394 | `canonical/skills/aid-summarize/references/state-profile.md:136` | [State: X] | `[State: PROFILE] Doc-set/domain read complete.` | task-067 |
| 395 | `canonical/skills/aid-summarize/references/state-profile.md:144` | [State: X] | `[State: PROFILE] WARNING: discovery.doc_set not found in .aid/settings.yml.` | task-067 |
| 396 | `canonical/skills/aid-summarize/references/state-profile.md:160` | [State: X] | `Print: `[State: PROFILE] complete.`` | task-067 |
| 397 | `canonical/skills/aid-summarize/references/state-profile.md:162` | [State: X] | `**Advance:** **CHAIN** → [State: GENERATE] (continue inline).` | task-067 |
| 398 | `canonical/skills/aid-summarize/references/state-stale-check.md:30` | [State: X] | `Print: `[State: STALE-CHECK] complete.`` | task-067 |
| 399 | `canonical/skills/aid-summarize/references/state-stale-check.md:32` | [State: X] | `**Advance:** **CHAIN** → [State: PROFILE] when the result is `STALE`; **CHAIN** → [State: APPROVAL] when it is `CURRE...` | task-067 |
| 400 | `canonical/skills/aid-summarize/references/state-validate.md:60` | [State: X] | `Print: `[State: VALIDATE] complete.`` | task-067 |
| 401 | `canonical/skills/aid-summarize/references/state-validate.md:62` | [State: X] | `**Advance:** **CHAIN** → [State: MANUAL-CHECKLIST] if Machine Grade >= minimum; **CHAIN** → [State: FIX] otherwise. B...` | task-067 |
| 402 | `canonical/skills/aid-summarize/references/state-writeback.md:30` | [State: X] | `Print: `[State: WRITEBACK] complete.`` | task-067 |
| 403 | `canonical/skills/aid-summarize/references/state-writeback.md:32` | [State: X] | `**Advance:** **CHAIN** → [State: DONE] (continue inline).` | task-067 |
| 404 | `canonical/skills/aid-test/SKILL.md:24` | [State: X] | `Print the `[State: NAME] -- {purpose}` entry line on each state.` | task-069 |
| 405 | `canonical/skills/aid-test/SKILL.md:53` | [State: X] | `**Advance:** CHAIN → [State: INTAKE-ASK] when any of these holds: the argument is empty, the path is Guided, works ex...` | task-069 |
| 406 | `canonical/skills/aid-test/SKILL.md:66` | [State: X] | `**Advance:** ASK → [State: ALLOCATE].` | task-069 |
| 407 | `canonical/skills/aid-test/SKILL.md:86` | [State: X] | `**Advance:** CHAIN → [State: RUN].` | task-069 |
| 408 | `canonical/skills/aid-test/SKILL.md:102` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-069 |
| 409 | `canonical/skills/aid-test/SKILL.md:117` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the grade is clean; CHAIN → [State: RUN] when it is not clean and fewer th...` | task-069 |
| 410 | `canonical/skills/aid-test/SKILL.md:127` | [State: X] | `**Advance:** ASK → [State: HANDOFF].` | task-069 |
| 411 | `canonical/skills/aid-test/SKILL.md:137` | [State: X] | `**Advance:** ASK → [State: DONE].` | task-069 |
| 412 | `canonical/skills/aid-update-architecture/SKILL.md:33` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}` entry` | task-061 |
| 413 | `canonical/skills/aid-update-architecture/SKILL.md:80` | [State: X] | `**Advance:** CHAIN → [State: UPDATE]; HALT when the destination is absent.` | task-061 |
| 414 | `canonical/skills/aid-update-architecture/SKILL.md:99` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-061 |
| 415 | `canonical/skills/aid-update-architecture/SKILL.md:108` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: UPDATE] when it is not clean and fewe...` | task-061 |
| 416 | `canonical/skills/aid-update-architecture/SKILL.md:127` | [State: X] | `**Advance:** CHAIN → [State: DONE] when the user approves; CHAIN → [State: DONE] when the user declines (the revision...` | task-061 |
| 417 | `canonical/skills/aid-update-backlog/SKILL.md:28` | [State: X] | `Print the `[State: NAME] -- {purpose}` entry line on each state.` | task-061 |
| 418 | `canonical/skills/aid-update-backlog/SKILL.md:69` | [State: X] | `**Advance:** CHAIN → [State: GUARD]; HALT when the destination is absent.` | task-061 |
| 419 | `canonical/skills/aid-update-backlog/SKILL.md:86` | [State: X] | `**Advance:** CHAIN → [State: UPDATE] when no seed was found, it has no unresolved question, or the override is suppli...` | task-061 |
| 420 | `canonical/skills/aid-update-backlog/SKILL.md:168` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-061 |
| 421 | `canonical/skills/aid-update-backlog/SKILL.md:178` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: UPDATE] when it is not clean and fewe...` | task-061 |
| 422 | `canonical/skills/aid-update-backlog/SKILL.md:204` | [State: X] | `**Advance:** CHAIN → [State: DONE] when the user approves; CHAIN → [State: DONE] when the user declines (the revision...` | task-061 |
| 423 | `canonical/skills/aid-update-cicd/SKILL.md:36` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}` entry` | task-061 |
| 424 | `canonical/skills/aid-update-cicd/SKILL.md:84` | [State: X] | `**Advance:** CHAIN → [State: UPDATE]; HALT when the destination is absent.` | task-061 |
| 425 | `canonical/skills/aid-update-cicd/SKILL.md:103` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-061 |
| 426 | `canonical/skills/aid-update-cicd/SKILL.md:112` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: UPDATE] when it is not clean and fewe...` | task-061 |
| 427 | `canonical/skills/aid-update-cicd/SKILL.md:133` | [State: X] | `**Advance:** CHAIN → [State: DONE] when the user approves; CHAIN → [State: DONE] when the user declines (the revision...` | task-061 |
| 428 | `canonical/skills/aid-update-document/SKILL.md:28` | [State: X] | `gate, diff] -> WRITE (on approval) -> DONE**. Print the `[State: NAME] -- {purpose}` entry line on each state.` | task-069 |
| 429 | `canonical/skills/aid-update-document/SKILL.md:55` | [State: X] | `**Advance:** CHAIN → [State: INTAKE-ASK] when any of these holds: the argument is empty, the document does not resolv...` | task-069 |
| 430 | `canonical/skills/aid-update-document/SKILL.md:71` | [State: X] | `**Advance:** CHAIN → [State: ALLOCATE]; HALT when the user meant a new document (item 2).` | task-069 |
| 431 | `canonical/skills/aid-update-document/SKILL.md:93` | [State: X] | `**Advance:** CHAIN → [State: AUTHOR].` | task-069 |
| 432 | `canonical/skills/aid-update-document/SKILL.md:103` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-069 |
| 433 | `canonical/skills/aid-update-document/SKILL.md:113` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the check is clean; CHAIN → [State: AUTHOR] when it is not clean and fewer...` | task-069 |
| 434 | `canonical/skills/aid-update-document/SKILL.md:122` | [State: X] | `**Advance:** ASK → [State: WRITE].` | task-069 |
| 435 | `canonical/skills/aid-update-document/SKILL.md:132` | [State: X] | `**Advance:** CHAIN → [State: DONE].` | task-069 |
| 436 | `canonical/skills/aid-update-kb/SKILL.md:393` | [State: X] | `[State: ANALYZE] -- Building the Impact Map: how and where the instruction lands in the KB.` | task-067 |
| 437 | `canonical/skills/aid-update-kb/SKILL.md:394` | you are here | `aid-update-kb  > you are here` | task-067 |
| 438 | `canonical/skills/aid-update-kb/SKILL.md:400` | [State: X] | `[State: SCOPE] -- Turning the Impact Map into the minimal Scope Plan + Not-Changing list.` | task-067 |
| 439 | `canonical/skills/aid-update-kb/SKILL.md:401` | you are here | `aid-update-kb  > you are here` | task-067 |
| 440 | `canonical/skills/aid-update-kb/SKILL.md:407` | [State: X] | `[State: CONFIRM] -- Human gate: confirm understanding + scope before any edit.` | task-067 |
| 441 | `canonical/skills/aid-update-kb/SKILL.md:408` | you are here | `aid-update-kb  > you are here` | task-067 |
| 442 | `canonical/skills/aid-update-kb/SKILL.md:414` | [State: X] | `[State: APPLY] -- Applying only the Confirmed Scope's targeted summary+pointer edits.` | task-067 |
| 443 | `canonical/skills/aid-update-kb/SKILL.md:415` | you are here | `aid-update-kb  > you are here` | task-067 |
| 444 | `canonical/skills/aid-update-kb/SKILL.md:421` | [State: X] | `[State: REVIEW] -- Scope-diff guard, then grading the changed KB docs through f005's four-mandate panel.` | task-067 |
| 445 | `canonical/skills/aid-update-kb/SKILL.md:422` | you are here | `aid-update-kb  > you are here` | task-067 |
| 446 | `canonical/skills/aid-update-kb/SKILL.md:428` | [State: X] | `[State: APPROVAL] -- Human gate: confirm the approved changes before committing.` | task-067 |
| 447 | `canonical/skills/aid-update-kb/SKILL.md:429` | you are here | `aid-update-kb  > you are here` | task-067 |
| 448 | `canonical/skills/aid-update-kb/SKILL.md:435` | [State: X] | `[State: DONE] -- Restamp approved_at_commit:, commit, and clean run-state.` | task-067 |
| 449 | `canonical/skills/aid-update-kb/SKILL.md:436` | you are here | `aid-update-kb  > you are here` | task-067 |
| 450 | `canonical/skills/aid-update-kb/SKILL.md:507` | [State: X] | `On state entry, print `[State: NAME]` + the "you are here" banner from State` | task-067 |
| 451 | `canonical/skills/aid-update-kb/references/state-analyze.md:85` | [State: X] | `Print the `[State: ANALYZE]` banner from `SKILL.md § State Detection`.` | task-067 |
| 452 | `canonical/skills/aid-update-kb/references/state-apply.md:36` | [State: X] | `Print the `[State: APPLY]` banner from `SKILL.md § State Detection`.` | task-067 |
| 453 | `canonical/skills/aid-update-kb/references/state-approval.md:17` | [State: X] | `Print the `[State: APPROVAL]` banner from `SKILL.md § State Detection`.` | task-067 |
| 454 | `canonical/skills/aid-update-kb/references/state-confirm.md:12` | [State: X] | `Print the `[State: CONFIRM]` banner from `SKILL.md § State Detection`.` | task-067 |
| 455 | `canonical/skills/aid-update-kb/references/state-done.md:10` | [State: X] | `Print the `[State: DONE]` banner from `SKILL.md § State Detection`.` | task-067 |
| 456 | `canonical/skills/aid-update-kb/references/state-done.md:222` | [State: X] | `[State: DONE] complete.` | task-067 |
| 457 | `canonical/skills/aid-update-kb/references/state-review.md:29` | [State: X] | `Print the `[State: REVIEW]` banner from `SKILL.md § State Detection`.` | task-067 |
| 458 | `canonical/skills/aid-update-kb/references/state-review.md:329` | [State: X] | `Print: `[State: REVIEW] complete. Advancing to APPROVAL.`` | task-067 |
| 459 | `canonical/skills/aid-update-kb/references/state-review.md:358` | [State: X] | `Print: `[State: REVIEW] below gate -- entering FIX loop.`` | task-067 |
| 460 | `canonical/skills/aid-update-mvp/SKILL.md:39` | [State: X] | `Print the `[State: NAME] -- {purpose}` entry line on each state.` | task-061 |
| 461 | `canonical/skills/aid-update-mvp/SKILL.md:77` | [State: X] | `**Advance:** CHAIN → [State: GUARD]; HALT when the destination is absent.` | task-061 |
| 462 | `canonical/skills/aid-update-mvp/SKILL.md:94` | [State: X] | `**Advance:** CHAIN → [State: UPDATE] when no seed was found, it has no unresolved question, or the override is suppli...` | task-061 |
| 463 | `canonical/skills/aid-update-mvp/SKILL.md:143` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-061 |
| 464 | `canonical/skills/aid-update-mvp/SKILL.md:153` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: UPDATE] when it is not clean and fewe...` | task-061 |
| 465 | `canonical/skills/aid-update-mvp/SKILL.md:184` | [State: X] | `**Advance:** CHAIN → [State: DONE] when the user approves; CHAIN → [State: DONE] when the user declines (the revision...` | task-061 |
| 466 | `canonical/skills/aid-update-roadmap/SKILL.md:33` | [State: X] | `Print the `[State: NAME] -- {purpose}` entry line on each state.` | task-061 |
| 467 | `canonical/skills/aid-update-roadmap/SKILL.md:71` | [State: X] | `**Advance:** CHAIN → [State: GUARD]; HALT when the destination is absent.` | task-061 |
| 468 | `canonical/skills/aid-update-roadmap/SKILL.md:88` | [State: X] | `**Advance:** CHAIN → [State: UPDATE] when no seed was found, it has no unresolved question, or the override is suppli...` | task-061 |
| 469 | `canonical/skills/aid-update-roadmap/SKILL.md:133` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-061 |
| 470 | `canonical/skills/aid-update-roadmap/SKILL.md:143` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: UPDATE] when it is not clean and fewe...` | task-061 |
| 471 | `canonical/skills/aid-update-roadmap/SKILL.md:169` | [State: X] | `**Advance:** CHAIN → [State: DONE] when the user approves; CHAIN → [State: DONE] when the user declines (the revision...` | task-061 |
| 472 | `canonical/skills/aid-update-stack/SKILL.md:33` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}` entry` | task-061 |
| 473 | `canonical/skills/aid-update-stack/SKILL.md:78` | [State: X] | `**Advance:** CHAIN → [State: UPDATE]; HALT when the destination is absent.` | task-061 |
| 474 | `canonical/skills/aid-update-stack/SKILL.md:97` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-061 |
| 475 | `canonical/skills/aid-update-stack/SKILL.md:106` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: UPDATE] when it is not clean and fewe...` | task-061 |
| 476 | `canonical/skills/aid-update-stack/SKILL.md:126` | [State: X] | `**Advance:** CHAIN → [State: DONE] when the user approves; CHAIN → [State: DONE] when the user declines (the revision...` | task-061 |
| 477 | `canonical/skills/aid-update-testing-strategy/SKILL.md:33` | [State: X] | ``design-lifecycle.md § Skill shape` defines it. Print the `[State: NAME] -- {purpose}` entry` | task-061 |
| 478 | `canonical/skills/aid-update-testing-strategy/SKILL.md:80` | [State: X] | `**Advance:** CHAIN → [State: UPDATE]; HALT when neither destination exists.` | task-061 |
| 479 | `canonical/skills/aid-update-testing-strategy/SKILL.md:99` | [State: X] | `**Advance:** CHAIN → [State: VERIFY].` | task-061 |
| 480 | `canonical/skills/aid-update-testing-strategy/SKILL.md:108` | [State: X] | `**Advance:** CHAIN → [State: PRESENT] when the verify is clean; CHAIN → [State: UPDATE] when it is not clean and fewe...` | task-061 |
| 481 | `canonical/skills/aid-update-testing-strategy/SKILL.md:128` | [State: X] | `**Advance:** CHAIN → [State: DONE] when the user approves; CHAIN → [State: DONE] when the user declines (the revision...` | task-061 |

## Q2 interviewer sites

Command (scope: `canonical/agents/`, `canonical/skills/`, `canonical/aid/templates/`, `docs/`, `examples/`, `site/src/content/`, `tests/`, `.aid/knowledge/`):

```bash
git grep -n -i interviewer -- canonical/agents canonical/skills canonical/aid/templates docs examples site/src/content tests .aid/knowledge
```

Hits: **50** lines in 23 files. The superseded proposal counted 18 files (D1).

| # | Location | Text | Owner |
|---|---|---|---|
| 1 | `.aid/knowledge/architecture.md:197` | `\| Describe \| `aid-describe` \| **Definition** \| Definition, **full path only**: adaptive interview + COMPLETION + (gre...` | task-077 |
| 2 | `.aid/knowledge/architecture.md:257` | ``aid-interview` SKILL was split; the `aid-interviewer` AGENT keeps its name (only the skill` | task-077 |
| 3 | `.aid/knowledge/architecture.md:259` | ``aid-interview/`; `canonical/agents/aid-interviewer/` is unchanged.` | task-077 |
| 4 | `.aid/knowledge/architecture.md:355` | `(aid-architect, aid-clerk, aid-developer, aid-interviewer, aid-operator,` | task-077 |
| 5 | `.aid/knowledge/architecture.md:361` | `\| Medium (6) \| aid-developer, aid-operator, aid-tech-writer, aid-interviewer, aid-researcher, aid-reviewer \| Workhors...` | task-077 |
| 6 | `.aid/knowledge/architecture.md:370` | `depth does not aid retrieval). `aid-interviewer`, `aid-researcher`, and `aid-reviewer`` | task-077 |
| 7 | `.aid/knowledge/decisions.md:783` | `- **Rejected:** The chaining rule, which named the next step in prose and saved none. A separate interviewer` | task-077 |
| 8 | `.aid/knowledge/decisions.md:792` | ``canonical/agents/aid-interviewer/` agent still exists and `canonical/skills/aid-describe/SKILL.md`` | task-077 |
| 9 | `.aid/knowledge/kb.html:2140` | `<dt>When</dt><dd>After discovery (or directly for greenfield), when starting a new Work. The <code>aid-interviewer</c...` | history, left as is |
| 10 | `.aid/knowledge/module-map.md:86` | `\| `canonical/agents/*` (8) \| Toolkit \| Sub-agent role definitions (one `AGENT.md` each); dispatched by skills. \| `tem...` | task-077 |
| 11 | `.aid/knowledge/release-tracking.md:205` | `- [NEW] **`aid-describe` + `aid-define`** — **Breaking:** `aid-interview` is split into two Phase 2 skills: `aid-desc...` | history, left as is |
| 12 | `canonical/agents/aid-architect/AGENT.md:26` | `- Gather requirements from stakeholders (that's the Interviewer)` | task-072 |
| 13 | `canonical/agents/aid-interviewer/AGENT.md:2` | `name: aid-interviewer` | task-072 |
| 14 | `canonical/agents/aid-interviewer/AGENT.md:8` | `You are the Interviewer — the conversational requirements specialist in the AID pipeline.` | task-072 |
| 15 | `canonical/aid/templates/agent-dispatch-tiering.md:52` | `\| aid-interviewer \| medium \| `medium` \| large / `high` (complex requirement synthesis) \|` | task-072 |
| 16 | `canonical/skills/aid-define/references/reviewer-brief.md:115` | `Do NOT include interview transcripts, the aid-interviewer's working notes, or` | task-064 |
| 17 | `canonical/skills/aid-define/references/state-cross-reference.md:5` | `**Agent:** This is adversarial validation, not interview work. Dispatch with `subagent_type: aid-reviewer` (overridin...` | task-064 |
| 18 | `canonical/skills/aid-define/references/state-feature-decomposition.md:13` | `**Agent:** This is design work, not interview work. Dispatch with `subagent_type: aid-architect` (overriding the defa...` | task-064 |
| 19 | `canonical/skills/aid-describe/SKILL.md:25` | `\| 1–4 \| Conversational interview \| `aid-interviewer` \| Empathetic dialogue, deterministic advancing \|` | task-063 |
| 20 | `canonical/skills/aid-describe/SKILL.md:26` | `\| DESCRIBE-SEED \| Greenfield KB seed authoring (aid-describe step per D3) \| `aid-interviewer` + dispatches `aid-revie...` | task-063 |
| 21 | `canonical/skills/aid-describe/SKILL.md:28` | `The frontmatter default `agent: aid-interviewer` covers States 1–4. DESCRIBE-SEED also uses `aid-interviewer`, additi...` | task-063 |
| 22 | `canonical/skills/aid-describe/SKILL.md:241` | `\| FIRST-RUN \| `references/state-first-run.md` \| `aid-interviewer` \| CHAIN → CONTINUE \|` | task-063 |
| 23 | `canonical/skills/aid-describe/SKILL.md:242` | `\| Q-AND-A \| `references/state-q-and-a.md` \| `aid-interviewer` \| CHAIN → CONTINUE \|` | task-063 |
| 24 | `canonical/skills/aid-describe/SKILL.md:243` | `\| CONTINUE \| `references/state-continue.md` \| `aid-interviewer` \| CHAIN → DESCRIBE-SEED when the work is greenfield a...` | task-063 |
| 25 | `canonical/skills/aid-describe/SKILL.md:244` | `\| DESCRIBE-SEED \| `references/state-describe-seed.md` \| `aid-interviewer` \| CHAIN → COMPLETION \|` | task-063 |
| 26 | `canonical/skills/aid-describe/SKILL.md:245` | `\| COMPLETION \| `references/state-completion.md` \| `aid-interviewer` \| CHAIN → CONTINUE when the user adds a considera...` | task-063 |
| 27 | `canonical/skills/aid-describe/references/advisor-stance.md:163` | `the interviewer is the perceived authority). The NFR-7 envelope's explicit override` | task-063 |
| 28 | `canonical/skills/aid-specify/SKILL.md:15` | `**The agent is a tech lead, not an interviewer.** It proposes concrete solutions grounded` | task-064 |
| 29 | `docs/aid-methodology.md:808` | `ME["aid-interviewer"]:::med` | task-076 |
| 30 | `docs/aid-methodology.md:828` | `- **Medium (6 default):** `aid-developer`, `aid-operator`, `aid-tech-writer`, `aid-interviewer`, `aid-researcher`, `a...` | task-076 |
| 31 | `docs/diagram-content-reference.md:183` | `- The **`aid-interviewer`** agent (never renamed).` | task-076 |
| 32 | `examples/brownfield-lite-path/README.md:105` | `Having confirmed the lite path, `aid-describe` invokes the `interviewer` agent` | task-076 |
| 33 | `examples/brownfield-lite-path/README.md:111` | `The `interviewer` asks targeted questions:` | task-076 |
| 34 | `examples/brownfield-lite-path/README.md:132` | `CONDENSED-INTAKE ends when the `interviewer` has enough to write the spec. The` | task-076 |
| 35 | `examples/brownfield-lite-path/README.md:133` | ``interviewer` then drafts the **work-root REQUIREMENTS.md** and presents it for approval.` | task-076 |
| 36 | `examples/brownfield-lite-path/README.md:139` | `The `interviewer` produces a single `REQUIREMENTS.md` at the work root. Notice what is` | task-076 |
| 37 | `examples/brownfield-lite-path/README.md:282` | `To use it, the `interviewer` agent fills a JSON file with the slot values for` | task-076 |
| 38 | `examples/brownfield-lite-path/README.md:331` | `[CONDENSED-INTAKE]  (interviewer agent)` | task-076 |
| 39 | `examples/greenfield/README.md:108` | `The interviewer agent leads you through a conversational Q&A. For this project the` | task-076 |
| 40 | `site/src/content/docs/concepts/methodology.md:812` | `ME["aid-interviewer"]:::med` | task-076 |
| 41 | `site/src/content/docs/concepts/methodology.md:832` | `- **Medium (6 default):** `aid-developer`, `aid-operator`, `aid-tech-writer`, `aid-interviewer`, `aid-researcher`, `a...` | task-076 |
| 42 | `site/src/content/docs/reference/agents.md:35` | `### `aid-interviewer`` | task-072 |
| 43 | `site/src/content/docs/reference/agents.md:41` | `[Definition: `canonical/agents/aid-interviewer/AGENT.md`](https://github.com/AndreVianna/aid-methodology/blob/master/...` | task-072 |
| 44 | `site/src/content/docs/skills/aid-describe.md:58` | `\| FIRST-RUN \| `references/state-first-run.md` \| `aid-interviewer` \| CHAIN → CONTINUE \|` | task-063 |
| 45 | `site/src/content/docs/skills/aid-describe.md:66` | `\| Q-AND-A \| `references/state-q-and-a.md` \| `aid-interviewer` \| CHAIN → CONTINUE \|` | task-063 |
| 46 | `site/src/content/docs/skills/aid-describe.md:74` | `\| CONTINUE \| `references/state-continue.md` \| `aid-interviewer` \| CHAIN → DESCRIBE-SEED when the work is greenfield a...` | task-063 |
| 47 | `site/src/content/docs/skills/aid-describe.md:82` | `\| DESCRIBE-SEED \| `references/state-describe-seed.md` \| `aid-interviewer` \| CHAIN → COMPLETION \|` | task-063 |
| 48 | `site/src/content/docs/skills/aid-describe.md:90` | `\| COMPLETION \| `references/state-completion.md` \| `aid-interviewer` \| CHAIN → CONTINUE when the user adds a considera...` | task-063 |
| 49 | `tests/canonical/test-describe-full-only.sh:27` | `# No agent is invoked; nothing here dispatches aid-interviewer/aid-reviewer.` | task-063 |
| 50 | `tests/cost-baseline.tsv:4` | `agent	aid-interviewer/AGENT.md	2278` | baseline, re-recorded at the gate |

## Q3 question-record sites

Two searches. **3a** is `## Cross-phase Q&A` (SS-06's form). **3b** is every skill or template line that writes, or names as its target, a delivery-level `qa` (KI-003). The migration scripts, the dashboard readers and the tests that read the old shapes are not writers in SS-06's scope; they are listed with their owners in 3a.

Command 3a:

```bash
git grep -n -F 'Cross-phase Q&A' -- canonical docs examples site/src/content .aid/knowledge tests dashboard bin chat-node
```

Command 3b:

```bash
git grep -n -i -E -e 'deliver[^ ]{0,30}(STATE\.yml|`qa`|\bqa\b)' -e '\bqa\b.{0,40}deliver' -e 'delivery-scoped' -- canonical/skills canonical/aid/templates canonical/agents
```

3a: **100** lines in 40 files; the skill files are the nine of the superseded proposal (D1).

| File | Lines | Owner |
|---|---|---|
| .aid/knowledge/artifact-schemas.md | 157, 181, 727, 728 | task-077 |
| .aid/knowledge/tech-debt.md | 80 | task-077 |
| bin/aid | 3206, 3225, 3261 | no change needed here (CLI reader of the old heading; spec keeps it; see Delta) |
| bin/aid.ps1 | 4079, 4097, 4130 | no change needed here (CLI reader of the old heading; spec keeps it; see Delta) |
| canonical/aid/scripts/migrate/migrate-work-hierarchy.ps1 | 182, 210, 431, 468, 523 | no change needed here (migration script: reads the old shapes; outside SS-06, spec keeps it) |
| canonical/aid/scripts/migrate/migrate-work-hierarchy.sh | 169, 198, 417, 446, 448, 463, 495, 511 | no change needed here (migration script: reads the old shapes; outside SS-06, spec keeps it) |
| canonical/aid/templates/delivery-state-template.yml | 6, 14, 72 | no change needed here (delivery template; Feature 006 retires it, no task edits it; see Delta) |
| canonical/skills/aid-define/SKILL.md | 55 | task-064 |
| canonical/skills/aid-describe/SKILL.md | 43, 164, 178, 261, 264 | task-063 |
| canonical/skills/aid-describe/references/advisor-stance.md | 144 | task-063 |
| canonical/skills/aid-describe/references/elicitation-engine.md | 123, 220 | task-063 |
| canonical/skills/aid-describe/references/move-playbook.md | 91, 289, 300, 329 | task-063 |
| canonical/skills/aid-describe/references/state-describe-seed.md | 307 | task-063 |
| canonical/skills/aid-describe/references/state-q-and-a.md | 3, 12, 48 | task-063 |
| canonical/skills/aid-detail/references/task-decomposition.md | 222 | task-065 |
| canonical/skills/aid-specify/SKILL.md | 53 | task-064 |
| dashboard/reader/derivation.py | 769 | task-070 |
| dashboard/reader/models.py | 345 | task-070 |
| dashboard/reader/parsers.py | 1369 | task-070 |
| dashboard/reader/reader.py | 1191, 1388, 1513 | task-070 |
| dashboard/reader/tests/test_derivation.py | 101, 121, 319, 507 | task-079 |
| dashboard/reader/tests/test_fixtures.py | 140 | task-079 |
| dashboard/reader/tests/test_reader.py | 153 | task-079 |
| dashboard/reader/tests/test_task011_golden_master.py | 299, 423, 960 | task-079 |
| dashboard/reader/tests/test_task014_fixtures.py | 16, 17, 198, 637, 641 | task-079 |
| dashboard/reader/tests/test_work001_delivery_layouts.py | 123, 126, 396 | task-079 |
| dashboard/server/reader.mjs | 2699, 2869, 2959 | task-070 |
| dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-001-running-parallel/STATE.md | 36 | task-079 |
| dashboard/server/tests/fixtures/pt1-aid/.aid/works/work-002-paused/STATE.md | 19 | task-079 |
| dashboard/server/tests/fixtures/pt1h-repo-a/.aid/works/work-001-with-unicode/STATE.md | 30 | task-079 |
| dashboard/server/tests/fixtures/pt1h-repo-b/.aid/works/work-001-minimal/STATE.md | 30 | task-079 |
| tests/canonical/fixtures/migrate/fixture-source/work-999-migration-test/STATE.md | 48 | no change needed here (test fixture of the old shape, read by the migration suites) |
| tests/canonical/fixtures/migrate/fixture/work-999-migration-test/STATE.md | 53 | no change needed here (test fixture of the old shape, read by the migration suites) |
| tests/canonical/fixtures/migrate/fixture/work-999-migration-test/deliveries/delivery-001/STATE.md | 32 | no change needed here (test fixture of the old shape, read by the migration suites) |
| tests/canonical/fixtures/migrate/fixture/work-999-migration-test/deliveries/delivery-002/STATE.md | 32 | no change needed here (test fixture of the old shape, read by the migration suites) |
| tests/canonical/test-artifact-discipline.sh | 525 | task-078 |
| tests/canonical/test-disjoint-merge.sh | 26, 31, 41, 42, 289, 322, 376, 393, 423, 425, 429 | no change needed here (migration-era fixture of the delivery qa key; the edited files are not its subject) |
| tests/canonical/test-migrate-hierarchy.sh | 7, 218, 229 | no change needed here (migration script suite; the spec keeps the migration) |
| tests/canonical/test-work-state-template.sh | 41, 456, 465, 466 | no change needed here (asserts delivery-state-template.yml, which no task edits) |
| tests/cost-meter.py | 350 | no change needed here (no delivery-003 task names this file; see Delta) |

3b: the delivery-level `qa` writers and the delivery-level `qa` key mentions. The lines that name a work's `STATE.yml` `qa` (the work level, `aid-orchestrate`, `skill-steps.md`) are not writers of a delivery-level `qa` and are not rows.

| File | Line | Text | Owner |
|---|---|---|---|
| canonical/aid/templates/delivery-state-template.yml | 14 | `#     delivery_gate (Issue List), qa (delivery-scoped Cross-phase Q&A).` | no change needed here (delivery template; Feature 006 retires it; no task edits it; see Delta D4) |
| canonical/aid/templates/work-state-template.yml | 39 | `# delivery-NNN/STATE.yml (delivery lifecycle + gate + delivery-scoped Q&A +` | no change needed here (comment on the delivery layout; no task edits it; see Delta D4) |
| canonical/skills/aid-ask/SKILL.md | 177 | ``deliveries/delivery-NNN/STATE.yml` `qa` sequence instead.` | task-067 |
| canonical/skills/aid-execute/references/state-delivery-gate.md | 313 | `- **SPEC** → Append to the `qa` sequence in `deliveries/delivery-NNN/STATE.yml` (SD-5:` | task-065 |
| canonical/skills/aid-plan/SKILL.md | 189 | `- **→ Specify:** SPEC ambiguous → append to the `qa` sequence in the relevant delivery's `STATE.yml`` | task-065 |
| canonical/skills/aid-plan/SKILL.md | 190 | `- **→ Interview:** Priority unclear → append to the `qa` sequence in the relevant delivery's `STATE.yml`` | task-065 |

## Q4 AskUserQuestion

Command (every tracked file except `.aid/works/` and the installed copies):

```bash
git grep -n -F AskUserQuestion -- . ':!.aid/works' ':!.claude' ':!.agents' ':!.aid/runtime' ':!.cursor' ':!profiles' ':!recovery' ':!packages' ':!.aid/.aid-manifest.json'
```

Hits: **73** lines in 27 files; 14 of them are under `canonical/` (the superseded proposal counted 13, D1). Each `allowed-tools` line is removed (the sweep's rule (c)); each body mention is rewritten to ask in plain text through the protocol.

**Decision on `canonical/aid/scripts/connectors/write-connector.sh` (line 5).** The line is a comment that names the requirement the skills meet (`requires AskUserQuestion, SKILL.md line 12`). It is text, not a picker use: no code path in the script calls the tool. Owner task-068, which rewrites the comment with the skills' `allowed-tools`. The byte-identical copy `dashboard/scripts/write-connector.sh` is an installed copy (resync).

| File | Lines | Owner | Action |
|---|---|---|---|
| .aid/knowledge/decisions.md | 793 | task-077 | re-point the text |
| canonical/aid/scripts/connectors/write-connector.sh | 5 | task-068 | rewrite comment (no picker) |
| canonical/aid/templates/connectors/ticket-resolution.md | 46, 134, 233 | task-068 | re-point the text |
| canonical/aid/templates/state-machine-chaining.md | 29, 48, 68, 91, 93 | task-074 | re-point the text |
| canonical/skills/aid-config/SKILL.md | 9, 103, 174, 185 | task-068 | remove from allowed-tools and body; ask via protocol |
| canonical/skills/aid-create-ticket/SKILL.md | 12, 38, 111, 122, 187 | task-068 | remove from allowed-tools and body; ask via protocol |
| canonical/skills/aid-housekeep/references/state-cleanup.md | 175, 178, 203, 210, 319, 335, 339, 366 | task-067 | remove from allowed-tools and body; ask via protocol |
| canonical/skills/aid-orchestrate/SKILL.md | 5 | task-069 | remove from allowed-tools and body; ask via protocol |
| canonical/skills/aid-read-ticket/SKILL.md | 7, 23, 98, 99, 155, 165, 167, 192 | task-068 | remove from allowed-tools and body; ask via protocol |
| canonical/skills/aid-set-connector/SKILL.md | 6, 91 | task-068 | remove from allowed-tools and body; ask via protocol |
| canonical/skills/aid-set-connector/references/question-sets.md | 91, 98 | task-068 | remove from allowed-tools and body; ask via protocol |
| canonical/skills/aid-summarize/references/state-approval.md | 26 | task-067 | remove from allowed-tools and body; ask via protocol |
| canonical/skills/aid-summarize/references/state-fix.md | 30 | task-067 | remove from allowed-tools and body; ask via protocol |
| canonical/skills/aid-summarize/references/state-manual-checklist.md | 11, 13 | task-067 | remove from allowed-tools and body; ask via protocol |
| canonical/skills/aid-update-ticket/SKILL.md | 14, 106 | task-068 | remove from allowed-tools and body; ask via protocol |
| dashboard/scripts/write-connector.sh | 5 | installed copy (resync) | rewrite comment (no picker) |
| site/src/content/docs/skills/aid-config.md | 13 | task-068 | re-point the text |
| site/src/content/docs/skills/aid-create-ticket.md | 13 | task-068 | re-point the text |
| site/src/content/docs/skills/aid-orchestrate.md | 13 | task-069 | re-point the text |
| site/src/content/docs/skills/aid-read-ticket.md | 13 | task-068 | re-point the text |
| site/src/content/docs/skills/aid-set-connector.md | 13 | task-068 | re-point the text |
| site/src/content/docs/skills/aid-update-ticket.md | 13 | task-068 | re-point the text |
| site/src/data/skill-flows/aid-housekeep.flow.json | 99 | task-067 | re-point the text |
| site/src/data/skill-flows/aid-summarize.flow.json | 137, 159, 184 | task-067 | re-point the text |
| tests/canonical/test-connector-skills-structural.sh | 15, 37, 103 | task-068 | re-point the text |
| tests/canonical/test-ticket-skills-structural.sh | 18, 28, 118, 125, 132, 188, 192, 229 | task-068 | re-point the text |
| tests/coverage-baseline.tsv | 8075, 8081, 8087, 8117, 8138 | baseline, re-recorded at the gate | re-point the text |

Installed copies carry the same hits; see Installed copies.

## Q5 reviewer-brief files

Command:

```bash
git ls-files | grep -E 'reviewer-brief\.md$|reviewer-dispatch\.md$|aid-reviewer/AGENT\.md$'   # then, per file: grep -c -E '^### What to report' <file>
```

At the base, `### What to report` appears in **0** of the **8** canonical files (six `reviewer-brief.md`, `reviewer-dispatch.md` and `aid-reviewer/AGENT.md`), so every one is an edit (rule (f); AC-46).

| File | What to report headings at base | Owner |
|---|---|---|
| canonical/agents/aid-reviewer/AGENT.md | 0 | task-072 |
| canonical/aid/templates/reviewer-dispatch.md | 0 | task-072 |
| canonical/skills/aid-define/references/reviewer-brief.md | 0 | task-064 |
| canonical/skills/aid-detail/references/reviewer-brief.md | 0 | task-065 |
| canonical/skills/aid-discover/references/reviewer-brief.md | 0 | task-066 |
| canonical/skills/aid-execute/references/reviewer-brief.md | 0 | task-065 |
| canonical/skills/aid-plan/references/reviewer-brief.md | 0 | task-065 |
| canonical/skills/aid-specify/references/reviewer-brief.md | 0 | task-064 |

The installed copies of the briefs and of `reviewer-dispatch.md` (`.claude/`, `.agents/`, `.aid/runtime/`) lack the heading too (checked on three of them); they are resync. `recovery/partial/canonical/aid/templates/reviewer-dispatch.md` is a recovery snapshot, owner class 5 (Delta D4).

## Q6 state-machine-chaining citations

Command:

```bash
git grep -n -F state-machine-chaining -- . ':!.aid/works' ':!.claude' ':!.agents' ':!.aid/runtime' ':!.cursor' ':!profiles' ':!recovery' ':!packages' ':!.aid/.aid-manifest.json'
```

Hits: **14** lines in 6 files. `canonical/` cites the chaining file in **0** files other than its own (the citations were re-pointed to `skill-steps.md` before the base; the superseded proposal counted 19 at `a3b28db4`, D1). The remaining live citations are the test-pipeline suite, its skip list and the two baselines; the file itself is deleted by task-074.

| File | Lines | Owner |
|---|---|---|
| .aid/knowledge/decisions.md | 786 | task-077 |
| canonical/aid/templates/state-machine-chaining.md | 104 | task-074 |
| tests/canonical/skill-steps-exempt.tsv | 39 | task-074 |
| tests/canonical/test-pipeline-status-walkthrough.sh | 398, 406, 410, 412, 416, 421, 589 | task-074 |
| tests/cost-baseline.tsv | 643 | baseline, re-recorded at the gate |
| tests/coverage-baseline.tsv | 6683, 6704, 6716 | baseline, re-recorded at the gate |

## Q7 asking skills against the AC-28 coverage table

Command (the asking set, and the skills each sample names):

```bash
ls canonical/skills/*/SKILL.md | wc -l                                  # 112 on disk at the base
grep -l -e '^# Shortcut' canonical/skills/*/SKILL.md | wc -l            # 34 generated doorways
grep -h -m1 '^skills:' tests/conversation/samples/feature-002/*.md       # the samples' skills: rows
grep -E '^(skills|covers):' tests/conversation/samples/feature-002/002-14-*.md
```

The asking set is every skill on disk except the two that never ask (`aid-chat`, `aid-unset-connector`, the SS-04 never-asks list). Each asking skill is covered either by a sample that names it and covers AC-28, or by a `skill:` row of `tests/conversation/deferred.tsv` that task-078 adds (the row names the skill or a glob, and the feature that brings the skill's sample). The 34 generated doorways are covered by their Feature 009 rows, through the engine.

Counts: 112 skills on disk; 110 asking; 8 covered by an existing sample (all eight are Feature 002's, with AC-28); 102 need a `skill:` row from task-078; 2 never ask.

Note on sample `002-13-mid-task-kb-update-returns`: its frontmatter names `aid-kb-update`, which is not a skill folder (the skill is `aid-update-kb`). The sample is deferred and covers AC-38, not AC-28, so it does not change the table; the name is a Delta item (D8).

| Skill | Kind | AC-28 coverage (sample id, or the skill: row task-078 adds) | Owner of the skill's edits |
|---|---|---|---|
| aid-ask | hand-authored | skill:aid-ask row (task-078 adds; waits for Feature 004) | task-067 |
| aid-brainstorm | hand-authored | skill:aid-brainstorm row (task-078 adds; waits for Feature 003) | task-060 |
| aid-chat | hand-authored, never asks | never asks: SS-04 never-asks list (no protocol line) | none |
| aid-config | hand-authored | sample 002-02-settings-groups-and-breaks (AC-28) | task-068 |
| aid-create | generated doorway | skill:aid-create row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-create-api | generated doorway | skill:aid-create-api row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-create-architecture | hand-authored | skill:aid-create-architecture row (task-078 adds; waits for Feature 004) | task-061 |
| aid-create-backlog | hand-authored | skill:aid-create-backlog row (task-078 adds; waits for Feature 004) | task-061 |
| aid-create-cicd | hand-authored | skill:aid-create-cicd row (task-078 adds; waits for Feature 004) | task-061 |
| aid-create-cli | generated doorway | skill:aid-create-cli row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-create-config | generated doorway | skill:aid-create-config row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-create-dashboard | generated doorway | skill:aid-create-dashboard row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-create-data-model | generated doorway | skill:aid-create-data-model row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-create-data-pipeline | generated doorway | skill:aid-create-data-pipeline row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-create-diagram | hand-authored | skill:aid-create-diagram row (task-078 adds; waits for Feature 009) | task-069 |
| aid-create-document | hand-authored | skill:aid-create-document row (task-078 adds; waits for Feature 009) | task-069 |
| aid-create-infra | generated doorway | skill:aid-create-infra row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-create-integration | generated doorway | skill:aid-create-integration row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-create-job | generated doorway | skill:aid-create-job row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-create-messaging | generated doorway | skill:aid-create-messaging row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-create-mvp | hand-authored | skill:aid-create-mvp row (task-078 adds; waits for Feature 004) | task-061 |
| aid-create-roadmap | hand-authored | skill:aid-create-roadmap row (task-078 adds; waits for Feature 004) | task-061 |
| aid-create-stack | hand-authored | skill:aid-create-stack row (task-078 adds; waits for Feature 004) | task-061 |
| aid-create-test | generated doorway | skill:aid-create-test row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-create-testing-strategy | hand-authored | skill:aid-create-testing-strategy row (task-078 adds; waits for Feature 004) | task-061 |
| aid-create-theme | generated doorway | skill:aid-create-theme row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-create-ticket | hand-authored | skill:aid-create-ticket row (task-078 adds; waits for Feature 009) | task-068 |
| aid-create-ui | generated doorway | skill:aid-create-ui row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-define | hand-authored | skill:aid-define row (task-078 adds; waits for Feature 005) | task-064 |
| aid-deploy | hand-authored | skill:aid-deploy row (task-078 adds; waits for Feature 006) | task-068 |
| aid-deprecate | generated doorway | skill:aid-deprecate row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-describe | hand-authored | skill:aid-describe row (task-078 adds; waits for Feature 003) | task-063 |
| aid-design | hand-authored | skill:aid-design row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-api | hand-authored | skill:aid-design-api row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-architecture | hand-authored | skill:aid-design-architecture row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-backlog | hand-authored | skill:aid-design-backlog row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-cicd | hand-authored | skill:aid-design-cicd row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-cli | hand-authored | skill:aid-design-cli row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-config | hand-authored | skill:aid-design-config row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-dashboard | hand-authored | skill:aid-design-dashboard row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-data-model | hand-authored | skill:aid-design-data-model row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-data-pipeline | hand-authored | skill:aid-design-data-pipeline row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-document | hand-authored | skill:aid-design-document row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-infra | hand-authored | skill:aid-design-infra row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-integration | hand-authored | skill:aid-design-integration row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-job | hand-authored | skill:aid-design-job row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-messaging | hand-authored | skill:aid-design-messaging row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-mvp | hand-authored | skill:aid-design-mvp row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-roadmap | hand-authored | skill:aid-design-roadmap row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-stack | hand-authored | skill:aid-design-stack row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-test | hand-authored | skill:aid-design-test row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-testing-strategy | hand-authored | skill:aid-design-testing-strategy row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-theme | hand-authored | skill:aid-design-theme row (task-078 adds; waits for Feature 009) | task-060 |
| aid-design-ui | hand-authored | skill:aid-design-ui row (task-078 adds; waits for Feature 009) | task-060 |
| aid-detail | hand-authored | skill:aid-detail row (task-078 adds; waits for Feature 006) | task-065 |
| aid-discover | hand-authored | skill:aid-discover row (task-078 adds; waits for Feature 004) | task-066 |
| aid-document | hand-authored | skill:aid-document row (task-078 adds; waits for Feature 009) | task-069 |
| aid-document-architecture | hand-authored | skill:aid-document-architecture row (task-078 adds; waits for Feature 009) | task-069 |
| aid-document-changelog | hand-authored | skill:aid-document-changelog row (task-078 adds; waits for Feature 009) | task-069 |
| aid-document-decision | hand-authored | skill:aid-document-decision row (task-078 adds; waits for Feature 009) | task-069 |
| aid-document-guideline | hand-authored | skill:aid-document-guideline row (task-078 adds; waits for Feature 009) | task-069 |
| aid-document-runbook | hand-authored | skill:aid-document-runbook row (task-078 adds; waits for Feature 009) | task-069 |
| aid-document-standard | hand-authored | skill:aid-document-standard row (task-078 adds; waits for Feature 009) | task-069 |
| aid-document-tutorial | hand-authored | skill:aid-document-tutorial row (task-078 adds; waits for Feature 009) | task-069 |
| aid-execute | hand-authored | skill:aid-execute row (task-078 adds; waits for Feature 007) | task-065 |
| aid-experiment | generated doorway | skill:aid-experiment row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-fix | generated doorway | skill:aid-fix row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-housekeep | hand-authored | skill:aid-housekeep row (task-078 adds; waits for Feature 004) | task-067 |
| aid-migrate | generated doorway | skill:aid-migrate row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-monitor | hand-authored | sample 002-19-monitor-finding-question (AC-28) | task-068 |
| aid-orchestrate | hand-authored | sample 002-14-orchestrate-unsure-reading (AC-28) | task-069 |
| aid-plan | hand-authored | skill:aid-plan row (task-078 adds; waits for Feature 006) | task-065 |
| aid-prototype | hand-authored | skill:aid-prototype row (task-078 adds; waits for Feature 009) | task-069 |
| aid-prototype-ui | hand-authored | skill:aid-prototype-ui row (task-078 adds; waits for Feature 009) | task-069 |
| aid-read-ticket | hand-authored | sample 002-15-which-tracker (AC-28) | task-068 |
| aid-refactor | generated doorway | skill:aid-refactor row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-remove | generated doorway | skill:aid-remove row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-report | hand-authored | sample 002-18-report-what-to-analyze (AC-28) | task-069 |
| aid-research | hand-authored | sample 002-16-research-without-a-question (AC-28) | task-069 |
| aid-review | hand-authored | sample 002-17-review-publish-approval (AC-28) | task-069 |
| aid-set-connector | hand-authored | sample 002-01-connector-question (AC-28) | task-068 |
| aid-specify | hand-authored | skill:aid-specify row (task-078 adds; waits for Feature 005) | task-064 |
| aid-summarize | hand-authored | skill:aid-summarize row (task-078 adds; waits for Feature 004) | task-067 |
| aid-test | hand-authored | skill:aid-test row (task-078 adds; waits for Feature 009) | task-069 |
| aid-test-data-quality | hand-authored | skill:aid-test-data-quality row (task-078 adds; waits for Feature 009) | task-069 |
| aid-test-performance | hand-authored | skill:aid-test-performance row (task-078 adds; waits for Feature 009) | task-069 |
| aid-test-security | hand-authored | skill:aid-test-security row (task-078 adds; waits for Feature 009) | task-069 |
| aid-unset-connector | hand-authored, never asks | never asks: SS-04 never-asks list (no protocol line) | none |
| aid-update | generated doorway | skill:aid-update row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-update-api | generated doorway | skill:aid-update-api row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-update-architecture | hand-authored | skill:aid-update-architecture row (task-078 adds; waits for Feature 004) | task-061 |
| aid-update-backlog | hand-authored | skill:aid-update-backlog row (task-078 adds; waits for Feature 004) | task-061 |
| aid-update-cicd | hand-authored | skill:aid-update-cicd row (task-078 adds; waits for Feature 004) | task-061 |
| aid-update-cli | generated doorway | skill:aid-update-cli row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-update-config | generated doorway | skill:aid-update-config row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-update-dashboard | generated doorway | skill:aid-update-dashboard row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-update-data-model | generated doorway | skill:aid-update-data-model row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-update-data-pipeline | generated doorway | skill:aid-update-data-pipeline row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-update-document | hand-authored | skill:aid-update-document row (task-078 adds; waits for Feature 009) | task-069 |
| aid-update-infra | generated doorway | skill:aid-update-infra row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-update-integration | generated doorway | skill:aid-update-integration row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-update-job | generated doorway | skill:aid-update-job row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-update-kb | hand-authored | skill:aid-update-kb row (task-078 adds; waits for Feature 004) | task-067 |
| aid-update-messaging | generated doorway | skill:aid-update-messaging row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-update-mvp | hand-authored | skill:aid-update-mvp row (task-078 adds; waits for Feature 004) | task-061 |
| aid-update-roadmap | hand-authored | skill:aid-update-roadmap row (task-078 adds; waits for Feature 004) | task-061 |
| aid-update-stack | hand-authored | skill:aid-update-stack row (task-078 adds; waits for Feature 004) | task-061 |
| aid-update-test | generated doorway | skill:aid-update-test row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-update-testing-strategy | hand-authored | skill:aid-update-testing-strategy row (task-078 adds; waits for Feature 004) | task-061 |
| aid-update-theme | generated doorway | skill:aid-update-theme row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |
| aid-update-ticket | hand-authored | skill:aid-update-ticket row (task-078 adds; waits for Feature 009) | task-068 |
| aid-update-ui | generated doorway | skill:aid-update-ui row (task-078 adds; waits for Feature 009) | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) |

## Q8 Q106 suite map

Command for each edit-list token: the suites under `tests/` (not fixtures), `site/scripts/__tests__/`, `site/src/lib/__tests__/` and the dashboard test folders that name the file or skill as a path (`canonical/skills/<name>/`, `<name>/SKILL.md`, `<name>/references/`), or, for file tokens, the file's name. Under `site/` a quoted skill name also counts (the site tests load skills by name). Command (prints this section and writes nothing; run from the repository root at the base commit):

```bash
python3 .aid/works/work-003-full-aid-restructure/research/delivery-003-sites-tools/gen.py --q8
```

Each token is matched with these two shapes; `<file name>`, `<skill>` and `<suites>` are filled in by the tool, not typed by hand:

```bash
git grep -n -F -e '<file name>' -- tests site/scripts/__tests__ site/src/lib/__tests__ dashboard   # file tokens
git grep -n -E -e '(^|[^A-Za-z0-9_-])<skill>/(SKILL\.md|references/)' -e 'canonical/skills/<skill>([^A-Za-z0-9_-]|$)' -- <suites>   # skill tokens
```

Edit-list tokens: **69** (hand-authored skill folders with a hit, and canonical files with a hit; generated doorways are not tokens). Suites that read at least one token: **93**. The DETAIL column is the set of task files whose text names the suite's file name.

| Suite | Edit-list tokens it reads (matching lines) | Measured owner(s) | Named in DETAIL | Reconciled action |
|---|---|---|---|---|
| `dashboard/reader/tests/test_feature009.py` | `aid-detail`: 6 | task-065 | -- | ADD to task-065's Scope (same-task rule) |
| `dashboard/reader/tests/test_task023_list_management_parity.py` | `write-connector.sh`: 2 | task-068 | -- | ADD to task-068's Scope (same-task rule) |
| `dashboard/server/tests/test_task019_connector_ops.mjs` | `write-connector.sh`: 5 | task-068 | -- | ADD to task-068's Scope (same-task rule) |
| `dashboard/server/tests/test_task019_connector_ops.py` | `write-connector.sh`: 8 | task-068 | -- | ADD to task-068's Scope (same-task rule) |
| `dashboard/server/tests/test_task022_connectors_external_sources_ui.py` | `write-connector.sh`: 1 | task-068 | -- | ADD to task-068's Scope (same-task rule) |
| `dashboard/server/tests/test_task023_list_management_round_trips.py` | `write-connector.sh`: 11 | task-068 | -- | ADD to task-068's Scope (same-task rule) |
| `site/scripts/__tests__/flow-advance.test.mjs` | `aid-create-ticket`: 1, `aid-discover`: 1, `aid-plan`: 3, `aid-test`: 5, `aid-update-kb`: 1 | task-065, task-066, task-067, task-068, task-069 | -- | ADD to task-065, task-066, task-067, task-068, task-069's Scope (same-task rule) |
| `site/scripts/__tests__/flow-classify.test.mjs` | `aid-review`: 2, `aid-test`: 4, `shortcut-engine.md`: 4 | task-062, task-069 | -- | ADD to task-062, task-069's Scope (same-task rule) |
| `site/scripts/__tests__/flow-compose.test.mjs` | `aid-create-document`: 1, `aid-test`: 1, `shortcut-engine.md`: 5 | task-062, task-069 | -- | ADD to task-062, task-069's Scope (same-task rule) |
| `site/scripts/__tests__/flow-engine-core.test.mjs` | `shortcut-engine.md`: 6 | task-062 | -- | ADD to task-062's Scope (same-task rule) |
| `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | `aid-define`: 4, `aid-deploy`: 2, `aid-describe`: 12, `aid-detail`: 1, `aid-discover`: 1, `aid-execute`: 1, `aid-housekeep`: 1, `aid-monitor`: 1, `aid-plan`: 2, `aid-specify`: 1, `aid-summarize`: 1, `aid-update-kb`: 2 | task-063, task-064, task-065, task-066, task-067, task-068 | -- | ADD to task-063, task-064, task-065, task-066, task-067, task-068's Scope (same-task rule) |
| `site/scripts/__tests__/flow-extract-engine.test.mjs` | `shortcut-engine.md`: 2 | task-062 | -- | ADD to task-062's Scope (same-task rule) |
| `site/scripts/__tests__/flow-extract-inline.test.mjs` | `aid-create-document`: 1, `aid-design`: 1, `aid-prototype`: 1, `aid-report`: 1, `aid-research`: 1, `aid-review`: 2, `aid-test`: 2, `aid-update-document`: 1 | task-060, task-069 | -- | ADD to task-060, task-069's Scope (same-task rule) |
| `site/scripts/__tests__/flow-extract-residual.test.mjs` | `aid-config`: 5, `aid-create-ticket`: 3, `aid-orchestrate`: 5, `aid-read-ticket`: 2, `aid-set-connector`: 1, `aid-update-ticket`: 2 | task-068, task-069 | -- | ADD to task-068, task-069's Scope (same-task rule) |
| `site/scripts/__tests__/flow-extract-sibling.test.mjs` | `aid-create-document`: 3, `aid-test`: 20 | task-069 | -- | ADD to task-069's Scope (same-task rule) |
| `site/scripts/__tests__/flow-facade.test.mjs` | `aid-config`: 11, `aid-describe`: 6, `aid-review`: 14, `aid-summarize`: 1 | task-063, task-067, task-068, task-069 | -- | ADD to task-063, task-067, task-068, task-069's Scope (same-task rule) |
| `site/scripts/__tests__/flow-graph-doorways.test.mjs` | `aid-test`: 1, `shortcut-engine.md`: 6 | task-062, task-069 | -- | ADD to task-062, task-069's Scope (same-task rule) |
| `site/scripts/__tests__/flow-graph.test.mjs` | `aid-describe`: 1, `aid-review`: 3, `aid-test`: 67, `shortcut-engine.md`: 4 | task-062, task-063, task-069 | -- | ADD to task-062, task-063, task-069's Scope (same-task rule) |
| `site/scripts/__tests__/flow-render-mermaid.test.mjs` | `aid-test`: 1 | task-069 | -- | ADD to task-069's Scope (same-task rule) |
| `site/scripts/__tests__/flow-validate.test.mjs` | `aid-test`: 7 | task-069 | -- | ADD to task-069's Scope (same-task rule) |
| `site/scripts/__tests__/gen-reference.test.mjs` | `AGENT.md`: 1, `aid-config`: 1, `aid-create-ticket`: 1, `aid-define`: 1, `aid-deploy`: 1, `aid-describe`: 1, `aid-detail`: 1, `aid-discover`: 1, `aid-execute`: 1, `aid-housekeep`: 1, `aid-monitor`: 1, `aid-orchestrate`: 1, `aid-plan`: 1, `aid-read-ticket`: 1, `aid-set-connector`: 1, `aid-specify`: 1, `aid-summarize`: 1, `aid-update-kb`: 1, `aid-update-ticket`: 1, `shortcut-engine.md`: 1 | task-062, task-063, task-064, task-065, task-066, task-067, task-068, task-069, task-072 | -- | ADD to task-062, task-063, task-064, task-065, task-066, task-067, task-068, task-069, task-072's Scope (same-task rule) |
| `site/scripts/__tests__/gen-skills-index.test.mjs` | `aid-define`: 1, `aid-deploy`: 3, `aid-describe`: 1, `aid-detail`: 1, `aid-monitor`: 3, `aid-orchestrate`: 1, `aid-plan`: 1, `aid-specify`: 1 | task-063, task-064, task-065, task-068, task-069 | -- | ADD to task-063, task-064, task-065, task-068, task-069's Scope (same-task rule) |
| `site/scripts/__tests__/gen-skills.test.mjs` | `aid-discover`: 1, `aid-monitor`: 3, `aid-plan`: 8, `aid-read-ticket`: 2 | task-065, task-066, task-068 | -- | ADD to task-065, task-066, task-068's Scope (same-task rule) |
| `site/scripts/__tests__/provenance-appender.test.mjs` | `aid-review`: 9, `shortcut-engine.md`: 5 | task-062, task-069 | -- | ADD to task-062, task-069's Scope (same-task rule) |
| `site/scripts/__tests__/provenance-render-list.test.mjs` | `aid-test`: 7 | task-069 | -- | ADD to task-069's Scope (same-task rule) |
| `site/scripts/__tests__/provenance.test.mjs` | `aid-review`: 5, `aid-test`: 2 | task-069 | -- | ADD to task-069's Scope (same-task rule) |
| `site/scripts/__tests__/skills-body.test.mjs` | `aid-review`: 2 | task-069 | -- | ADD to task-069's Scope (same-task rule) |
| `site/scripts/__tests__/skills-catalog.test.mjs` | `aid-deploy`: 3, `aid-monitor`: 1 | task-068 | -- | ADD to task-068's Scope (same-task rule) |
| `site/scripts/__tests__/skills-discover.test.mjs` | `aid-test`: 46 | task-069 | -- | ADD to task-069's Scope (same-task rule) |
| `site/scripts/__tests__/skills-groups.test.mjs` | `aid-config`: 7, `aid-define`: 1, `aid-deploy`: 7, `aid-describe`: 2, `aid-detail`: 1, `aid-monitor`: 4, `aid-orchestrate`: 4, `aid-plan`: 11, `aid-specify`: 1 | task-063, task-064, task-065, task-068, task-069 | -- | ADD to task-063, task-064, task-065, task-068, task-069's Scope (same-task rule) |
| `site/scripts/__tests__/skills-render-index.test.mjs` | `aid-deploy`: 1, `aid-monitor`: 1, `aid-orchestrate`: 2 | task-068, task-069 | -- | ADD to task-068, task-069's Scope (same-task rule) |
| `site/scripts/__tests__/skills-render-page.test.mjs` | `aid-review`: 3 | task-069 | -- | ADD to task-069's Scope (same-task rule) |
| `site/scripts/__tests__/skills-render-value.test.mjs` | `aid-read-ticket`: 1 | task-068 | -- | ADD to task-068's Scope (same-task rule) |
| `site/scripts/__tests__/skills-summary.test.mjs` | `aid-test`: 10 | task-069 | -- | ADD to task-069's Scope (same-task rule) |
| `site/src/lib/__tests__/feature-006-head-gate.test.ts` | `AGENT.md`: 1, `shortcut-engine.md`: 1 | task-062, task-072 | -- | ADD to task-062, task-072's Scope (same-task rule) |
| `site/src/lib/__tests__/skill-node-panel.test.ts` | `AGENT.md`: 2, `aid-execute`: 1, `aid-plan`: 4 | task-065, task-072 | -- | ADD to task-065, task-072's Scope (same-task rule) |
| `tests/canonical/test-aid-cli-parity.sh` | `aid-define`: 1 | task-064 | -- | ADD to task-064's Scope (same-task rule) |
| `tests/canonical/test-aid-migrate.sh` | `aid-plan`: 2 | task-065 | -- | ADD to task-065's Scope (same-task rule) |
| `tests/canonical/test-artifact-discipline.sh` | `AGENT.md`: 1, `aid-detail`: 1, `aid-plan`: 2, `reviewer-dispatch.md`: 1, `shortcut-engine.md`: 2 | task-062, task-065, task-072 | task-072, task-074, task-078 | ADD to task-062, task-065's Scope (same-task rule); named, but no measured assertion on its file: confirm and record in task-074, task-078 |
| `tests/canonical/test-catalog-dirs-parity.sh` | `shortcut-engine.md`: 2 | task-062 | -- | ADD to task-062's Scope (same-task rule) |
| `tests/canonical/test-change-refactor-family-scaffold.sh` | `shortcut-engine.md`: 1 | task-062 | -- | ADD to task-062's Scope (same-task rule) |
| `tests/canonical/test-compute-block-radius.sh` | `aid-execute`: 1 | task-065 | -- | ADD to task-065's Scope (same-task rule) |
| `tests/canonical/test-conformance-lane-semantics.sh` | `aid-housekeep`: 1 | task-067 | -- | ADD to task-067's Scope (same-task rule) |
| `tests/canonical/test-connector-set-unset-lifecycle.sh` | `aid-set-connector`: 2 | task-068 | -- | ADD to task-068's Scope (same-task rule) |
| `tests/canonical/test-connector-skills-structural.sh` | `aid-discover`: 1, `aid-set-connector`: 5, `ticket-resolution.md`: 2, `write-connector.sh`: 4 | task-066, task-068 | -- | ADD to task-066, task-068's Scope (same-task rule) |
| `tests/canonical/test-cost-meter.sh` | `AGENT.md`: 5 | task-072 | -- | ADD to task-072's Scope (same-task rule) |
| `tests/canonical/test-create-family-scaffold.sh` | `shortcut-engine.md`: 6 | task-062 | -- | ADD to task-062's Scope (same-task rule) |
| `tests/canonical/test-criterion-oracles.sh` | `AGENT.md`: 3 | task-072 | -- | ADD to task-072's Scope (same-task rule) |
| `tests/canonical/test-cutover-no-dangling.sh` | `aid-describe`: 1, `aid-discover`: 1 | task-063, task-066 | -- | ADD to task-063, task-066's Scope (same-task rule) |
| `tests/canonical/test-delivery-gate-aggregate.sh` | `aid-execute`: 1 | task-065 | -- | ADD to task-065's Scope (same-task rule) |
| `tests/canonical/test-deploy-monitor-repurpose.sh` | `aid-deploy`: 2, `aid-monitor`: 3, `shortcut-engine.md`: 2 | task-062, task-068 | -- | ADD to task-062, task-068's Scope (same-task rule) |
| `tests/canonical/test-derive-waves.sh` | `aid-detail`: 1 | task-065 | -- | ADD to task-065's Scope (same-task rule) |
| `tests/canonical/test-describe-full-only.sh` | `aid-describe`: 4 | task-063 | task-060, task-061, task-062, task-063, task-064, task-065, task-066, task-067, task-068, task-069 | named, but no measured assertion on its file: confirm and record in task-060, task-061, task-062, task-064, task-065, task-066, task-067, task-068, task-069 |
| `tests/canonical/test-discovery-doc-ownership.sh` | `AGENT.md`: 5, `aid-discover`: 2 | task-066, task-072 | -- | ADD to task-066, task-072's Scope (same-task rule) |
| `tests/canonical/test-doc-set-mapping.sh` | `aid-discover`: 1 | task-066 | -- | ADD to task-066's Scope (same-task rule) |
| `tests/canonical/test-doc-set-propose-confirm.sh` | `aid-discover`: 1 | task-066 | -- | ADD to task-066's Scope (same-task rule) |
| `tests/canonical/test-doc-set-read.sh` | `aid-discover`: 2 | task-066 | -- | ADD to task-066's Scope (same-task rule) |
| `tests/canonical/test-document-family-scaffold.sh` | `shortcut-engine.md`: 2 | task-062 | -- | ADD to task-062's Scope (same-task rule) |
| `tests/canonical/test-domain-doc-matrix.sh` | `aid-discover`: 1 | task-066 | -- | ADD to task-066's Scope (same-task rule) |
| `tests/canonical/test-downstream-worktree-entry.sh` | `aid-define`: 2, `aid-deploy`: 2, `aid-detail`: 2, `aid-execute`: 2, `aid-plan`: 2, `aid-specify`: 2, `shortcut-engine.md`: 2 | task-062, task-064, task-065, task-068 | -- | ADD to task-062, task-064, task-065, task-068's Scope (same-task rule) |
| `tests/canonical/test-expectations-single-source.sh` | `AGENT.md`: 11, `aid-discover`: 4 | task-066, task-072 | -- | ADD to task-066, task-072's Scope (same-task rule) |
| `tests/canonical/test-f010-governance-guards.sh` | `aid-housekeep`: 2, `aid-update-kb`: 2 | task-067 | -- | ADD to task-067's Scope (same-task rule) |
| `tests/canonical/test-fix-family-scaffold.sh` | `shortcut-engine.md`: 1 | task-062 | -- | ADD to task-062's Scope (same-task rule) |
| `tests/canonical/test-grade-summary.sh` | `aid-summarize`: 3 | task-067 | -- | ADD to task-067's Scope (same-task rule) |
| `tests/canonical/test-guardrails-d012.sh` | `aid-summarize`: 2 | task-067 | -- | ADD to task-067's Scope (same-task rule) |
| `tests/canonical/test-kb-review-surface.sh` | `aid-discover`: 2 | task-066 | -- | ADD to task-066's Scope (same-task rule) |
| `tests/canonical/test-kb-template-authoring-standard.sh` | `reviewer-dispatch.md`: 1 | task-072 | -- | ADD to task-072's Scope (same-task rule) |
| `tests/canonical/test-ledger-isolation.sh` | `aid-discover`: 3, `aid-summarize`: 2, `reviewer-dispatch.md`: 2 | task-066, task-067, task-072 | -- | ADD to task-066, task-067, task-072's Scope (same-task rule) |
| `tests/canonical/test-multitool-isolation.sh` | `aid-plan`: 4 | task-065 | -- | ADD to task-065's Scope (same-task rule) |
| `tests/canonical/test-never-merges.sh` | `aid-execute`: 1, `aid-housekeep`: 2 | task-065, task-067 | -- | ADD to task-065, task-067's Scope (same-task rule) |
| `tests/canonical/test-output-root-isolation.sh` | `aid-discover`: 1, `aid-housekeep`: 1 | task-066, task-067 | -- | ADD to task-066, task-067's Scope (same-task rule) |
| `tests/canonical/test-pipeline-status-walkthrough.sh` | `aid-define`: 2, `aid-deploy`: 1, `aid-describe`: 1, `aid-detail`: 2, `aid-execute`: 4, `aid-plan`: 2, `aid-specify`: 4, `state-machine-chaining.md`: 7 | task-063, task-064, task-065, task-068, task-074 | task-074 | ADD to task-063, task-064, task-065, task-068's Scope (same-task rule) |
| `tests/canonical/test-prototype-family-scaffold.sh` | `shortcut-engine.md`: 2 | task-062 | -- | ADD to task-062's Scope (same-task rule) |
| `tests/canonical/test-reconcile-scenarios.sh` | `aid-discover`: 1 | task-066 | -- | ADD to task-066's Scope (same-task rule) |
| `tests/canonical/test-release.sh` | `aid-discover`: 4 | task-066 | -- | ADD to task-066's Scope (same-task rule) |
| `tests/canonical/test-review-path-audit.sh` | `AGENT.md`: 3, `aid-review`: 2 | task-069, task-072 | -- | ADD to task-069, task-072's Scope (same-task rule) |
| `tests/canonical/test-scoped-review-cycles.sh` | `aid-define`: 1, `aid-detail`: 1, `aid-plan`: 1, `aid-specify`: 1, `reviewer-dispatch.md`: 2 | task-064, task-065, task-072 | -- | ADD to task-064, task-065, task-072's Scope (same-task rule) |
| `tests/canonical/test-severity-why-line.sh` | `AGENT.md`: 1 | task-072 | -- | ADD to task-072's Scope (same-task rule) |
| `tests/canonical/test-shared-prune.sh` | `aid-define`: 3, `aid-summarize`: 1 | task-064, task-067 | -- | ADD to task-064, task-067's Scope (same-task rule) |
| `tests/canonical/test-shared-remove.sh` | `aid-define`: 7 | task-064 | -- | ADD to task-064's Scope (same-task rule) |
| `tests/canonical/test-shortcut-engine-contract.sh` | `shortcut-engine.md`: 8 | task-062 | task-062 | as named |
| `tests/canonical/test-skill-steps.sh` | `shortcut-engine.md`: 2 | task-062 | task-078, task-081 | ADD to task-062's Scope (same-task rule); named, but no measured assertion on its file: confirm and record in task-078, task-081 |
| `tests/canonical/test-spine-depth-coverage.sh` | `aid-discover`: 3 | task-066 | -- | ADD to task-066's Scope (same-task rule) |
| `tests/canonical/test-state-review-surface.sh` | `aid-define`: 1, `aid-detail`: 1, `aid-discover`: 1, `aid-execute`: 1, `aid-plan`: 1, `aid-specify`: 1, `reviewer-dispatch.md`: 12, `shortcut-engine.md`: 7 | task-062, task-064, task-065, task-066, task-072 | -- | ADD to task-062, task-064, task-065, task-066, task-072's Scope (same-task rule) |
| `tests/canonical/test-task-state-transitions.sh` | `aid-execute`: 1 | task-065 | -- | ADD to task-065's Scope (same-task rule) |
| `tests/canonical/test-test-experiment-family-scaffold.sh` | `shortcut-engine.md`: 2 | task-062 | -- | ADD to task-062's Scope (same-task rule) |
| `tests/canonical/test-ticket-retirement-structural.sh` | `AGENT.md`: 7, `aid-deploy`: 3, `aid-describe`: 4, `aid-detail`: 3, `aid-execute`: 5, `aid-monitor`: 3, `aid-plan`: 6, `aid-report`: 1, `aid-research`: 1, `aid-review`: 1, `aid-specify`: 1, `aid-update-ticket`: 2, `shortcut-engine.md`: 5 | task-062, task-063, task-064, task-065, task-068, task-069, task-072 | -- | ADD to task-062, task-063, task-064, task-065, task-068, task-069, task-072's Scope (same-task rule) |
| `tests/canonical/test-ticket-skills-structural.sh` | `aid-create-ticket`: 1, `aid-read-ticket`: 1, `aid-update-ticket`: 1, `ticket-resolution.md`: 10 | task-068 | -- | ADD to task-068's Scope (same-task rule) |
| `tests/canonical/test-update-kb-scope-fidelity.sh` | `aid-update-kb`: 7 | task-067 | -- | ADD to task-067's Scope (same-task rule) |
| `tests/canonical/test-work-initiation-gate.sh` | `aid-create-document`: 3, `aid-describe`: 3, `aid-design`: 3, `aid-prototype`: 4, `aid-report`: 3, `aid-research`: 4, `aid-review`: 4, `aid-test`: 3, `aid-update-document`: 3, `shortcut-engine.md`: 3 | task-060, task-062, task-063, task-069 | -- | ADD to task-060, task-062, task-063, task-069's Scope (same-task rule) |
| `tests/canonical/test-work-state-template.sh` | `aid-describe`: 1 | task-063 | -- | ADD to task-063's Scope (same-task rule) |
| `tests/canonical/test-write-connector.sh` | `write-connector.sh`: 6 | task-068 | -- | ADD to task-068's Scope (same-task rule) |
| `tests/cost-meter.py` | `AGENT.md`: 4 | task-072 | -- | ADD to task-072's Scope (same-task rule) |

The row for a suite with `ADD to` is the reconciled edit list: those suites have no assertion in the named task's Scope, so the task's Scope gains the suite (Q106), and the owner keeps the suite green. See Delta D5 and D6.

## Q9 AD13 counts

Command: the five `ad13_check` patterns of `tests/canonical/test-artifact-discipline.sh` (lines 505 to 524), each run through the suite's own counter `ad13_count_class` (extracted unchanged, run on the tracked tree):

```bash
bash .aid/works/work-003-full-aid-restructure/research/delivery-003-sites-tools/ad13run.sh "$PWD"    # prints one line per class, C1 to C5 in table order; ad13run.sh holds the suite's ad13_count_class unchanged
```

| Class | Count at base | Ceiling in the suite today | Owner of the ceiling |
|---|---|---|---|
| work STATE.md (retired; use STATE.yml) | 53 | 65 | task-078 (lowers to the post-sweep count, downward only) |
| BLUEPRINT.md (retired as an authored artifact) | 151 | 154 | task-078 (lowers to the post-sweep count, downward only) |
| bare task-NNN.md (now tasks/task-NNN/DETAIL.md) | 16 | 16 | task-078 (lowers to the post-sweep count, downward only) |
| per-feature SPEC.md (folded into REQUIREMENTS.md section 11) | 3 | 3 | task-078 (lowers to the post-sweep count, downward only) |
| retired STATE.md section headings | 209 | 235 | task-078 (lowers to the post-sweep count, downward only) |

All five counts are at or below their ceilings today, so `test-artifact-discipline.sh` passes at the base. Task-078 lowers each ceiling to the count it measures after the sweep (a rise is never allowed; the suite's own rule).

## Site fixtures (G11)

Command (every site test that reads a skill's or template's body by path or by quoted name):

```bash
git grep -n -o -I -E "'aid-[a-z0-9-]+'|canonical/skills/[^'\" \`)]+|canonical/aid/templates/[^'\" \`)]+" -- site/scripts/__tests__ site/src/lib/__tests__ | sort -u | wc -l
```

Hits: **883** (test, target) hits: one per distinct quoted skill name or skill/template path on a line of a site test, so a line naming two targets counts twice. One row below per (test, target); its Hits is its share of that count. A target that is a skill folder takes the skill's owner (the test is re-pointed in that task, G11). Rows with `no change needed here` name no delivery-003 edit target.

| Site test | Target | Owner | Hits |
|---|---|---|---|
| site/scripts/__tests__/flow-advance.test.mjs | ${dir}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-advance.test.mjs | aid-discover | task-066 | 1 |
| site/scripts/__tests__/flow-advance.test.mjs | aid-fixture/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/flow-advance.test.mjs | aid-fixture/SKILL.md:10 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-advance.test.mjs | aid-fixture/SKILL.md:42 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-advance.test.mjs | aid-kb-update (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-advance.test.mjs | aid-plan | task-065 | 3 |
| site/scripts/__tests__/flow-advance.test.mjs | aid-test | task-069 | 5 |
| site/scripts/__tests__/flow-advance.test.mjs | aid-update-kb | task-067 | 1 |
| site/scripts/__tests__/flow-classify.test.mjs | <dir>/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-classify.test.mjs | aid-create | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 1 |
| site/scripts/__tests__/flow-classify.test.mjs | aid-first/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-classify.test.mjs | aid-parent (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/flow-classify.test.mjs | aid-parent/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 5 |
| site/scripts/__tests__/flow-classify.test.mjs | aid-review | task-069 | 2 |
| site/scripts/__tests__/flow-classify.test.mjs | aid-second/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-classify.test.mjs | aid-test | task-069 | 3 |
| site/scripts/__tests__/flow-classify.test.mjs | aid-test-security | task-069 | 2 |
| site/scripts/__tests__/flow-classify.test.mjs | canonical/aid/templates/shortcut-engine.md | task-062 | 4 |
| site/scripts/__tests__/flow-compose.test.mjs | ${skill}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-compose.test.mjs | aaa-first/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-compose.test.mjs | aid-add-document/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-compose.test.mjs | aid-create-api | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 10 |
| site/scripts/__tests__/flow-compose.test.mjs | aid-create-document | task-069 | 1 |
| site/scripts/__tests__/flow-compose.test.mjs | aid-document | task-069 | 1 |
| site/scripts/__tests__/flow-compose.test.mjs | aid-fix | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 4 |
| site/scripts/__tests__/flow-compose.test.mjs | aid-test | task-069 | 1 |
| site/scripts/__tests__/flow-compose.test.mjs | aid-test-performance | task-069 | 1 |
| site/scripts/__tests__/flow-compose.test.mjs | aid-test-security | task-069 | 2 |
| site/scripts/__tests__/flow-compose.test.mjs | aid-test-skill (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/flow-compose.test.mjs | aid-unknown/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-compose.test.mjs | canonical/aid/templates/shortcut-engine.md | task-062 | 5 |
| site/scripts/__tests__/flow-compose.test.mjs | canonical/aid/templates/zzz-last.md | no change needed here (no delivery-003 task names this file; see Delta) | 2 |
| site/scripts/__tests__/flow-compose.test.mjs | door-skill/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-engine-core.test.mjs | canonical/aid/templates/shortcut-engine.md | task-062 | 2 |
| site/scripts/__tests__/flow-engine-core.test.mjs | canonical/aid/templates/work-initiation-gate.md | no change needed here (delivery-002 converted this gate; no delivery-003 task edits it) | 2 |
| site/scripts/__tests__/flow-extract-dispatch.test.mjs | ${KW_SKILL}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-dispatch.test.mjs | ${name}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/flow-extract-dispatch.test.mjs | aid-absent-state (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-dispatch.test.mjs | aid-define | task-064 | 4 |
| site/scripts/__tests__/flow-extract-dispatch.test.mjs | aid-deploy | task-068 | 2 |
| site/scripts/__tests__/flow-extract-dispatch.test.mjs | aid-describe | task-063 | 12 |
| site/scripts/__tests__/flow-extract-dispatch.test.mjs | aid-detail | task-065 | 1 |
| site/scripts/__tests__/flow-extract-dispatch.test.mjs | aid-discover | task-066 | 1 |
| site/scripts/__tests__/flow-extract-dispatch.test.mjs | aid-execute | task-065 | 1 |
| site/scripts/__tests__/flow-extract-dispatch.test.mjs | aid-housekeep | task-067 | 1 |
| site/scripts/__tests__/flow-extract-dispatch.test.mjs | aid-keyword-states (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-dispatch.test.mjs | aid-monitor | task-068 | 1 |
| site/scripts/__tests__/flow-extract-dispatch.test.mjs | aid-plan | task-065 | 2 |
| site/scripts/__tests__/flow-extract-dispatch.test.mjs | aid-specify | task-064 | 1 |
| site/scripts/__tests__/flow-extract-dispatch.test.mjs | aid-summarize | task-067 | 1 |
| site/scripts/__tests__/flow-extract-dispatch.test.mjs | aid-update-kb | task-067 | 2 |
| site/scripts/__tests__/flow-extract-engine.test.mjs | ${dirName}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-engine.test.mjs | aid-create-api | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 6 |
| site/scripts/__tests__/flow-extract-engine.test.mjs | aid-fix | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 1 |
| site/scripts/__tests__/flow-extract-engine.test.mjs | aid-synthetic-long (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-engine.test.mjs | aid-synthetic-long/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-engine.test.mjs | canonical/aid/templates/shortcut-engine.md | task-062 | 2 |
| site/scripts/__tests__/flow-extract-inline.test.mjs | ${name}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-inline.test.mjs | ${skillName}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/flow-extract-inline.test.mjs | <name>/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-inline.test.mjs | <skillName>/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-inline.test.mjs | aid-create-document | task-069 | 1 |
| site/scripts/__tests__/flow-extract-inline.test.mjs | aid-design | task-060 | 1 |
| site/scripts/__tests__/flow-extract-inline.test.mjs | aid-prototype | task-069 | 1 |
| site/scripts/__tests__/flow-extract-inline.test.mjs | aid-report | task-069 | 1 |
| site/scripts/__tests__/flow-extract-inline.test.mjs | aid-research | task-069 | 1 |
| site/scripts/__tests__/flow-extract-inline.test.mjs | aid-review | task-069 | 2 |
| site/scripts/__tests__/flow-extract-inline.test.mjs | aid-test | task-069 | 2 |
| site/scripts/__tests__/flow-extract-inline.test.mjs | aid-update-document | task-069 | 1 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | ${dir}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | ${name}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | ${skillName}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | <name>/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | aid-ask | task-067 | 2 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | aid-config | task-068 | 5 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | aid-create | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 1 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | aid-create-ticket | task-068 | 3 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | aid-deprecate | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 1 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | aid-document | task-069 | 1 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | aid-document-runbook | task-069 | 1 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | aid-fixture (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | aid-fixture/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | aid-orchestrate | task-069 | 5 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | aid-read-ticket | task-068 | 2 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | aid-set-connector | task-068 | 1 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | aid-test-security | task-069 | 1 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | aid-unset-connector | task-068 | 1 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | aid-update-api | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 1 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | aid-update-ticket | task-068 | 2 |
| site/scripts/__tests__/flow-extract-residual.test.mjs | test-fixture/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | ${dirName}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | ${name}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-alias-synth (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-approx-parent (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-approx-parent/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-cap-synth (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-create | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-create-document | task-069 | 3 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-cycle-synth (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-cycle-synth/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-document | task-069 | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-document-architecture | task-069 | 3 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-document-changelog | task-069 | 2 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-neither-synth (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-test | task-069 | 20 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-test-data-quality | task-069 | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-test-performance | task-069 | 2 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-test-security | task-069 | 6 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-w2-synth (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | aid-w4-synth (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | fake-cap-1/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | fake-cap-2/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | fake-cap-3/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | fake-cap-4/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-extract-sibling.test.mjs | fake-cap-5/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-facade.test.mjs | ${dirName}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/flow-facade.test.mjs | aid-config | task-068 | 11 |
| site/scripts/__tests__/flow-facade.test.mjs | aid-create | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 4 |
| site/scripts/__tests__/flow-facade.test.mjs | aid-describe | task-063 | 6 |
| site/scripts/__tests__/flow-facade.test.mjs | aid-document-architecture | task-069 | 2 |
| site/scripts/__tests__/flow-facade.test.mjs | aid-review | task-069 | 14 |
| site/scripts/__tests__/flow-facade.test.mjs | aid-summarize | task-067 | 1 |
| site/scripts/__tests__/flow-facade.test.mjs | aid-test-security | task-069 | 1 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs |  (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs | ${PARENT_SKILL}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs | ${dirName}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs | ${skillName}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs | aid-add/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs | aid-create | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 1 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs | aid-create-api | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 13 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs | aid-document | task-069 | 1 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs | aid-fix | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 2 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs | aid-test | task-069 | 1 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs | aid-test-quality/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs | aid-test-security | task-069 | 10 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs | aid-unknown/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs | canonical/aid/templates/shortcut-engine.md | task-062 | 3 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs | purity-doorway/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs | w1-doorway/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-graph-doorways.test.mjs | w5-doorway/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-graph.test.mjs | aid-alpha/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-graph.test.mjs | aid-base (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/flow-graph.test.mjs | aid-base/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 6 |
| site/scripts/__tests__/flow-graph.test.mjs | aid-beta/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-graph.test.mjs | aid-describe | task-063 | 1 |
| site/scripts/__tests__/flow-graph.test.mjs | aid-example (not a skill folder) | no change needed here (names no delivery-003 edit target) | 6 |
| site/scripts/__tests__/flow-graph.test.mjs | aid-example/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/flow-graph.test.mjs | aid-foo (not a skill folder) | no change needed here (names no delivery-003 edit target) | 8 |
| site/scripts/__tests__/flow-graph.test.mjs | aid-foo/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/flow-graph.test.mjs | aid-no-exit (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-graph.test.mjs | aid-review | task-069 | 3 |
| site/scripts/__tests__/flow-graph.test.mjs | aid-test | task-069 | 68 |
| site/scripts/__tests__/flow-graph.test.mjs | canonical/aid/templates/shortcut-engine.md | task-062 | 2 |
| site/scripts/__tests__/flow-graph.test.mjs | foo/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 4 |
| site/scripts/__tests__/flow-graph.test.mjs | x/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-render-mermaid.test.mjs | aid-fixture (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-render-mermaid.test.mjs | aid-fixture/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/flow-render-mermaid.test.mjs | aid-test | task-069 | 1 |
| site/scripts/__tests__/flow-validate.test.mjs | aid-test | task-069 | 7 |
| site/scripts/__tests__/flow-validate.test.mjs | aid-x (not a skill folder) | no change needed here (names no delivery-003 edit target) | 5 |
| site/scripts/__tests__/flow-validate.test.mjs | aid-x/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 5 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-ask | task-067 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-chat | task-068 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-config | task-068 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-create-ticket | task-068 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-define | task-064 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-deploy | task-068 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-describe | task-063 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-detail | task-065 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-discover | task-066 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-execute | task-065 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-housekeep | task-067 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-monitor | task-068 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-orchestrate | task-069 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-plan | task-065 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-read-ticket | task-068 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-set-connector | task-068 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-specify | task-064 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-summarize | task-067 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-unset-connector | task-068 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-update-kb | task-067 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | aid-update-ticket | task-068 | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | canonical/aid/templates/knowledge-base | no change needed here (no delivery-003 task names this file; see Delta) | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | canonical/aid/templates/shortcut-catalog.yml | no change needed here (no delivery-003 task names this file; see Delta) | 1 |
| site/scripts/__tests__/gen-reference.test.mjs | canonical/aid/templates/shortcut-engine.md | task-062 | 1 |
| site/scripts/__tests__/gen-skills-index.test.mjs |  (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/gen-skills-index.test.mjs | aid-define | task-064 | 1 |
| site/scripts/__tests__/gen-skills-index.test.mjs | aid-deploy | task-068 | 3 |
| site/scripts/__tests__/gen-skills-index.test.mjs | aid-describe | task-063 | 1 |
| site/scripts/__tests__/gen-skills-index.test.mjs | aid-detail | task-065 | 1 |
| site/scripts/__tests__/gen-skills-index.test.mjs | aid-monitor | task-068 | 3 |
| site/scripts/__tests__/gen-skills-index.test.mjs | aid-orchestrate | task-069 | 1 |
| site/scripts/__tests__/gen-skills-index.test.mjs | aid-plan | task-065 | 1 |
| site/scripts/__tests__/gen-skills-index.test.mjs | aid-specify | task-064 | 1 |
| site/scripts/__tests__/gen-skills.test.mjs |  (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/gen-skills.test.mjs | */SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 4 |
| site/scripts/__tests__/gen-skills.test.mjs | aid-deleted (not a skill folder) | no change needed here (names no delivery-003 edit target) | 4 |
| site/scripts/__tests__/gen-skills.test.mjs | aid-discover | task-066 | 1 |
| site/scripts/__tests__/gen-skills.test.mjs | aid-monitor | task-068 | 3 |
| site/scripts/__tests__/gen-skills.test.mjs | aid-plan | task-065 | 8 |
| site/scripts/__tests__/gen-skills.test.mjs | aid-read-ticket | task-068 | 2 |
| site/scripts/__tests__/gen-skills.test.mjs | canonical/aid/templates/shortcut-catalog.yml | no change needed here (no delivery-003 task names this file; see Delta) | 4 |
| site/scripts/__tests__/gen-skills.test.mjs | some-dir-name/SKILL.md:2 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/provenance-appender.test.mjs | aid-add-api (not a skill folder) | no change needed here (names no delivery-003 edit target) | 3 |
| site/scripts/__tests__/provenance-appender.test.mjs | aid-add-cli (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/provenance-appender.test.mjs | aid-ask | task-067 | 3 |
| site/scripts/__tests__/provenance-appender.test.mjs | aid-create-api | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 3 |
| site/scripts/__tests__/provenance-appender.test.mjs | aid-review | task-069 | 9 |
| site/scripts/__tests__/provenance-appender.test.mjs | canonical/aid/templates/shortcut-engine.md | task-062 | 3 |
| site/scripts/__tests__/provenance-deep-link.test.mjs | aid (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/provenance-deep-link.test.mjs | aid-bar/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/provenance-deep-link.test.mjs | aid-baz/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/provenance-deep-link.test.mjs | aid-create-api | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 1 |
| site/scripts/__tests__/provenance-deep-link.test.mjs | aid-foo/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 5 |
| site/scripts/__tests__/provenance-render-list.test.mjs | aid-fixture (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/provenance-render-list.test.mjs | aid-test | task-069 | 7 |
| site/scripts/__tests__/provenance-verify.test.mjs | nonexistent/DETAIL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/provenance-verify.test.mjs | nonexistent/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 3 |
| site/scripts/__tests__/provenance-verify.test.mjs | nonexistent/SKILL.md#L1 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/provenance-verify.test.mjs | test-skill (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/provenance-verify.test.mjs | test-skill/crlf.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 3 |
| site/scripts/__tests__/provenance-verify.test.mjs | test-skill/crlf.md#L1 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/provenance-verify.test.mjs | test-skill/good.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 15 |
| site/scripts/__tests__/provenance-verify.test.mjs | test-skill/good.md#L1 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/provenance-verify.test.mjs | test-skill/good.md#L1-L100 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/provenance-verify.test.mjs | test-skill/whitespace.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 3 |
| site/scripts/__tests__/provenance-verify.test.mjs | test-skill/whitespace.md#L2 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/provenance.test.mjs |  (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/provenance.test.mjs | ../skills/test-skill/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/provenance.test.mjs | aid-ask | task-067 | 1 |
| site/scripts/__tests__/provenance.test.mjs | aid-review | task-069 | 5 |
| site/scripts/__tests__/provenance.test.mjs | aid-test | task-069 | 2 |
| site/scripts/__tests__/provenance.test.mjs | test-skill/crlf.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/provenance.test.mjs | test-skill/good.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/provenance.test.mjs | test-skill/nonexistent.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/provenance.test.mjs | test-skill/ws.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skill-counts.test.mjs | aid-ask | task-067 | 1 |
| site/scripts/__tests__/skill-node-panel-lifecycle.test.mjs | aid-flow-data (not a skill folder) | no change needed here (names no delivery-003 edit target) | 3 |
| site/scripts/__tests__/skill-node-panel-lifecycle.test.mjs | aid-node-panel (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skill-node-panel-panel.test.mjs | a/SKILL.md#L5 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skill-node-panel-panel.test.mjs | a/SKILL.md#L9-L12 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skill-node-panel-panel.test.mjs | a/references/w.md#L1-L43 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skill-node-panel-panel.test.mjs | aid-fixture (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skill-node-panel-panel.test.mjs | aid-flow-data (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skill-node-panel-panel.test.mjs | aid-node-panel (not a skill folder) | no change needed here (names no delivery-003 edit target) | 4 |
| site/scripts/__tests__/skills-body.test.mjs | aid-create-api | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 1 |
| site/scripts/__tests__/skills-body.test.mjs | aid-fixture (not a skill folder) | no change needed here (names no delivery-003 edit target) | 3 |
| site/scripts/__tests__/skills-body.test.mjs | aid-multi (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-body.test.mjs | aid-review | task-069 | 2 |
| site/scripts/__tests__/skills-catalog.test.mjs | aid-alpha (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-catalog.test.mjs | aid-bad (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-catalog.test.mjs | aid-catalog- (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-catalog.test.mjs | aid-deploy | task-068 | 3 |
| site/scripts/__tests__/skills-catalog.test.mjs | aid-fix | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 1 |
| site/scripts/__tests__/skills-catalog.test.mjs | aid-middle (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-catalog.test.mjs | aid-monitor | task-068 | 1 |
| site/scripts/__tests__/skills-catalog.test.mjs | aid-zap (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-catalog.test.mjs | canonical/aid/templates/shortcut-catalog.yml | no change needed here (no delivery-003 task names this file; see Delta) | 1 |
| site/scripts/__tests__/skills-discover.test.mjs | <dirName>/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-discover.test.mjs | aid--double (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-discover.test.mjs | aid-a (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-discover.test.mjs | aid-a-b (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-discover.test.mjs | aid-a1 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-discover.test.mjs | aid-ab (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-discover.test.mjs | aid-alpha (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-discover.test.mjs | aid-bad (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-discover.test.mjs | aid-bad- (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-discover.test.mjs | aid-beta (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-discover.test.mjs | aid-foo-bar (not a skill folder) | no change needed here (names no delivery-003 edit target) | 6 |
| site/scripts/__tests__/skills-discover.test.mjs | aid-foo-bar/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-discover.test.mjs | aid-good (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-discover.test.mjs | aid-m (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-discover.test.mjs | aid-mismatch (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-discover.test.mjs | aid-missing (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-discover.test.mjs | aid-test | task-069 | 47 |
| site/scripts/__tests__/skills-discover.test.mjs | aid-z (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-frontmatter.test.mjs | */SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-frontmatter.test.mjs | aid-foo (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-frontmatter.test.mjs | foo/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-frontmatter.test.mjs | x/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 3 |
| site/scripts/__tests__/skills-frontmatter.test.mjs | x/SKILL.md:3 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-frontmatter.test.mjs | z/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-frontmatter.test.mjs | z/SKILL.md:2 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-groups.test.mjs | aid-config | task-068 | 4 |
| site/scripts/__tests__/skills-groups.test.mjs | aid-define | task-064 | 1 |
| site/scripts/__tests__/skills-groups.test.mjs | aid-deploy | task-068 | 7 |
| site/scripts/__tests__/skills-groups.test.mjs | aid-describe | task-063 | 2 |
| site/scripts/__tests__/skills-groups.test.mjs | aid-detail | task-065 | 1 |
| site/scripts/__tests__/skills-groups.test.mjs | aid-monitor | task-068 | 4 |
| site/scripts/__tests__/skills-groups.test.mjs | aid-mystery-skill (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-groups.test.mjs | aid-orchestrate | task-069 | 4 |
| site/scripts/__tests__/skills-groups.test.mjs | aid-plan | task-065 | 8 |
| site/scripts/__tests__/skills-groups.test.mjs | aid-specify | task-064 | 1 |
| site/scripts/__tests__/skills-groups.test.mjs | aid-totally-unknown-xyz (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-paths.test.mjs | aid-bar-baz (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-paths.test.mjs | aid-create-api | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 5 |
| site/scripts/__tests__/skills-paths.test.mjs | aid-foo (not a skill folder) | no change needed here (names no delivery-003 edit target) | 8 |
| site/scripts/__tests__/skills-render-index.test.mjs | */SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-render-index.test.mjs | aid-alpha (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-render-index.test.mjs | aid-beta (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-render-index.test.mjs | aid-deploy | task-068 | 1 |
| site/scripts/__tests__/skills-render-index.test.mjs | aid-monitor | task-068 | 1 |
| site/scripts/__tests__/skills-render-index.test.mjs | aid-orchestrate | task-069 | 2 |
| site/scripts/__tests__/skills-render-index.test.mjs | canonical/aid/templates/shortcut-catalog.yml | no change needed here (no delivery-003 task names this file; see Delta) | 2 |
| site/scripts/__tests__/skills-render-page.test.mjs | ${dirName}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-render-page.test.mjs | aid-angle-test (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-render-page.test.mjs | aid-create-api | no change needed here (generated doorway: text comes from shortcut-engine.md, task-062, and changes through the builder) | 2 |
| site/scripts/__tests__/skills-render-page.test.mjs | aid-desc-test (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-render-page.test.mjs | aid-folded-test (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-render-page.test.mjs | aid-fullfield-test (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-render-page.test.mjs | aid-list-test (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-render-page.test.mjs | aid-nodesc (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-render-page.test.mjs | aid-nosidebar-test (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-render-page.test.mjs | aid-pipe-test (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-render-page.test.mjs | aid-quote-test (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-render-page.test.mjs | aid-review | task-069 | 3 |
| site/scripts/__tests__/skills-render-page.test.mjs | aid-synthetic-test (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/scripts/__tests__/skills-render-page.test.mjs | aid-test-skill (not a skill folder) | no change needed here (names no delivery-003 edit target) | 5 |
| site/scripts/__tests__/skills-render-page.test.mjs | aid-test-skill/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 4 |
| site/scripts/__tests__/skills-render-value.test.mjs | ${dir}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-render-value.test.mjs | aid-read-ticket | task-068 | 1 |
| site/scripts/__tests__/skills-summary.test.mjs |  (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-summary.test.mjs | aid-custom-dir (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-summary.test.mjs | aid-some-skill (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/scripts/__tests__/skills-summary.test.mjs | aid-test | task-069 | 10 |
| site/scripts/__tests__/skills-summary.test.mjs | aid-x (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/src/lib/__tests__/feature-006-head-gate.test.ts | */SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/src/lib/__tests__/feature-006-head-gate.test.ts | aid-ask | task-067 | 15 |
| site/src/lib/__tests__/feature-006-head-gate.test.ts | canonical/aid/templates/knowledge-base/*.md | no change needed here (no delivery-003 task names this file; see Delta) | 1 |
| site/src/lib/__tests__/feature-006-head-gate.test.ts | canonical/aid/templates/shortcut-catalog.yml | no change needed here (no delivery-003 task names this file; see Delta) | 2 |
| site/src/lib/__tests__/feature-006-head-gate.test.ts | canonical/aid/templates/shortcut-engine.md | task-062 | 1 |
| site/src/lib/__tests__/feature-009-releases-banner.test.ts | aid-banner-dismissed (not a skill folder) | no change needed here (names no delivery-003 edit target) | 2 |
| site/src/lib/__tests__/skill-node-panel.dom.test.ts | a/SKILL.md#L5 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/src/lib/__tests__/skill-node-panel.dom.test.ts | a/SKILL.md#L9-L12 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/src/lib/__tests__/skill-node-panel.dom.test.ts | a/references/w.md#L1-L43 (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/src/lib/__tests__/skill-node-panel.dom.test.ts | aid-fixture (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/src/lib/__tests__/skill-node-panel.dom.test.ts | aid-flow-data (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/src/lib/__tests__/skill-node-panel.dom.test.ts | aid-node-panel (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/src/lib/__tests__/skill-node-panel.test.ts | ${name}/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/src/lib/__tests__/skill-node-panel.test.ts | */SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/src/lib/__tests__/skill-node-panel.test.ts | Aid-Ask/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/src/lib/__tests__/skill-node-panel.test.ts | aid-ask | task-067 | 20 |
| site/src/lib/__tests__/skill-node-panel.test.ts | aid-audit/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/src/lib/__tests__/skill-node-panel.test.ts | aid-execute | task-065 | 1 |
| site/src/lib/__tests__/skill-node-panel.test.ts | aid-not-a-real-skill/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/src/lib/__tests__/skill-node-panel.test.ts | aid-plan | task-065 | 5 |
| site/src/lib/__tests__/skill-node-panel.test.ts | aid_ask/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |
| site/src/lib/__tests__/skill-node-panel.test.ts | canonical/aid/templates/shortcut-catalog.yml | no change needed here (no delivery-003 task names this file; see Delta) | 1 |
| site/src/lib/__tests__/skill-node-panel.test.ts | …/SKILL.md (not a skill folder) | no change needed here (names no delivery-003 edit target) | 1 |

## KB sources (G17)

Command: each `.aid/knowledge/*.md` frontmatter (the lines between its first two `---`) is searched for the paths this delivery deletes or moves: `state-machine-chaining.md` and `agents/aid-interviewer`.

```bash
git grep -n -E 'state-machine-chaining|agents/aid-interviewer' -- .aid/knowledge
```

Result: **0** `sources:` entries cite a deleted or moved file (no frontmatter entry names either path). The prose hits in the KB (`architecture.md`, `decisions.md`, `kb.html`, `module-map.md`, `release-tracking.md`) are Q2 and Q6 rows, owned as there: task-077 for the four editable docs, `history, left as is` for `kb.html` and `release-tracking.md`.

## Site generator sources (G19)

Command: the site generators outside `__tests__` for the name of every skill this delivery retires or renames, and for the two deleted names:

```bash
git grep -n -i -E -e 'interviewer' -e 'state-machine-chaining' -- site/scripts ':!site/scripts/__tests__'
```

Hits: **0**. Delivery-003 retires and renames no skill (the retired items are the `aid-interviewer` agent and the chaining template), so the list of retired or renamed skill names is empty and the result is empty. The site generators name neither deleted file.

## Baselines

Command:

```bash
git grep -n -E "interviewer|state-machine-chaining|AskUserQuestion|Cross-phase|Advancing to|you are here|Re-run \`/aid-|\[State" -- tests/cost-baseline.tsv tests/coverage-baseline.tsv
```

Hits: **10** lines. Every row is owned by the gate: no task edits a baseline (Q134 D11); the gate re-records both files after the sweep.

| File | Line | Test and assertion (first two columns) | Owner |
|---|---|---|---|
| tests/cost-baseline.tsv | 4 | agent \| aid-interviewer/AGENT.md | baseline, re-recorded at the gate |
| tests/cost-baseline.tsv | 643 | template \| state-machine-chaining.md | baseline, re-recorded at the gate |
| tests/coverage-baseline.tsv | 6683 | test-pipeline-status-walkthrough.sh \| B2: state-machine-chaining.md exists | baseline, re-recorded at the gate |
| tests/coverage-baseline.tsv | 6704 | test-pipeline-status-walkthrough.sh \| B4a state-machine-chaining.md: silent-write annotation present | baseline, re-recorded at the gate |
| tests/coverage-baseline.tsv | 6716 | test-pipeline-status-walkthrough.sh \| B4b state-machine-chaining.md: no co-occurrence of --pipeline and Print: (safe) | baseline, re-recorded at the gate |
| tests/coverage-baseline.tsv | 8075 | test-ticket-skills-structural.sh \| T03 aid-read-ticket allowed-tools includes AskUserQuestion | baseline, re-recorded at the gate |
| tests/coverage-baseline.tsv | 8081 | test-ticket-skills-structural.sh \| T09 aid-create-ticket allowed-tools includes AskUserQuestion | baseline, re-recorded at the gate |
| tests/coverage-baseline.tsv | 8087 | test-ticket-skills-structural.sh \| T15 aid-update-ticket allowed-tools includes AskUserQuestion | baseline, re-recorded at the gate |
| tests/coverage-baseline.tsv | 8117 | test-ticket-skills-structural.sh \| T45 aid-create-ticket's CONFIRM state is a single in-run AskUserQuestion exchange | baseline, re-recorded at the gate |
| tests/coverage-baseline.tsv | 8138 | test-ticket-skills-structural.sh \| T66 shared ref: two-or-more catalogued matches ask via AskUserQuestion | baseline, re-recorded at the gate |

## Installed copies (resync)

Command (the same pattern as the baselines, over the installed trees):

```bash
git grep -c -E "interviewer|state-machine-chaining|AskUserQuestion|Cross-phase|Advancing to|you are here|Re-run \`/aid-|\[State" -- .claude/skills .agents/skills .aid/runtime
```

| Tree | Matching lines | Owner |
|---|---|---|
| installed .agents/skills/ | 544 | installed copy (resync) |
| installed .aid/runtime/ | 37 | installed copy (resync) |
| installed .claude/skills/ | 549 | installed copy (resync) |
| .cursor/, profiles/, .aid/.aid-manifest.json | not counted | installed copy (resync) |

Each installed line mirrors a canonical line already in the tables above, or a generated profile; the resync (after task-081 and the gate) regenerates them with the full generator, never a partial render. `dashboard/scripts/write-connector.sh` is a byte-identical copy of `canonical/aid/scripts/connectors/write-connector.sh`, so it is an installed copy too.

## Skill owner table (G2)

Built from `ls canonical/skills/*/SKILL.md`: **112** rows, one per skill on disk at the base. Column *Hits* counts the skill's lines in Q1, Q2, Q4 and Q6 (canonical only).

| Skill | Kind | Owner | Files with hits |
|---|---|---|---|
| aid-ask | hand-authored | task-067 | 0 |
| aid-brainstorm | hand-authored | task-060 | 1 |
| aid-chat | hand-authored | task-068 | 0 |
| aid-config | hand-authored | task-068 | 1 |
| aid-create | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-create-api | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-create-architecture | hand-authored | task-061 | 1 |
| aid-create-backlog | hand-authored | task-061 | 1 |
| aid-create-cicd | hand-authored | task-061 | 1 |
| aid-create-cli | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-create-config | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-create-dashboard | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-create-data-model | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-create-data-pipeline | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-create-diagram | hand-authored | task-069 | 0 |
| aid-create-document | hand-authored | task-069 | 1 |
| aid-create-infra | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-create-integration | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-create-job | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-create-messaging | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-create-mvp | hand-authored | task-061 | 1 |
| aid-create-roadmap | hand-authored | task-061 | 1 |
| aid-create-stack | hand-authored | task-061 | 1 |
| aid-create-test | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-create-testing-strategy | hand-authored | task-061 | 1 |
| aid-create-theme | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-create-ticket | hand-authored | task-068 | 2 |
| aid-create-ui | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-define | hand-authored | task-064 | 7 |
| aid-deploy | hand-authored | task-068 | 8 |
| aid-deprecate | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-describe | hand-authored | task-063 | 8 |
| aid-design | hand-authored | task-060 | 1 |
| aid-design-api | hand-authored | task-060 | 1 |
| aid-design-architecture | hand-authored | task-060 | 1 |
| aid-design-backlog | hand-authored | task-060 | 1 |
| aid-design-cicd | hand-authored | task-060 | 1 |
| aid-design-cli | hand-authored | task-060 | 1 |
| aid-design-config | hand-authored | task-060 | 1 |
| aid-design-dashboard | hand-authored | task-060 | 1 |
| aid-design-data-model | hand-authored | task-060 | 1 |
| aid-design-data-pipeline | hand-authored | task-060 | 1 |
| aid-design-document | hand-authored | task-060 | 1 |
| aid-design-infra | hand-authored | task-060 | 1 |
| aid-design-integration | hand-authored | task-060 | 1 |
| aid-design-job | hand-authored | task-060 | 1 |
| aid-design-messaging | hand-authored | task-060 | 1 |
| aid-design-mvp | hand-authored | task-060 | 1 |
| aid-design-roadmap | hand-authored | task-060 | 1 |
| aid-design-stack | hand-authored | task-060 | 1 |
| aid-design-test | hand-authored | task-060 | 1 |
| aid-design-testing-strategy | hand-authored | task-060 | 1 |
| aid-design-theme | hand-authored | task-060 | 1 |
| aid-design-ui | hand-authored | task-060 | 1 |
| aid-detail | hand-authored | task-065 | 4 |
| aid-discover | hand-authored | task-066 | 8 |
| aid-document | hand-authored | task-069 | 0 |
| aid-document-architecture | hand-authored | task-069 | 0 |
| aid-document-changelog | hand-authored | task-069 | 0 |
| aid-document-decision | hand-authored | task-069 | 0 |
| aid-document-guideline | hand-authored | task-069 | 0 |
| aid-document-runbook | hand-authored | task-069 | 0 |
| aid-document-standard | hand-authored | task-069 | 0 |
| aid-document-tutorial | hand-authored | task-069 | 0 |
| aid-execute | hand-authored | task-065 | 6 |
| aid-experiment | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-fix | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-housekeep | hand-authored | task-067 | 6 |
| aid-migrate | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-monitor | hand-authored | task-068 | 3 |
| aid-orchestrate | hand-authored | task-069 | 1 |
| aid-plan | hand-authored | task-065 | 4 |
| aid-prototype | hand-authored | task-069 | 1 |
| aid-prototype-ui | hand-authored | task-069 | 0 |
| aid-read-ticket | hand-authored | task-068 | 1 |
| aid-refactor | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-remove | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-report | hand-authored | task-069 | 1 |
| aid-research | hand-authored | task-069 | 1 |
| aid-review | hand-authored | task-069 | 1 |
| aid-set-connector | hand-authored | task-068 | 2 |
| aid-specify | hand-authored | task-064 | 7 |
| aid-summarize | hand-authored | task-067 | 14 |
| aid-test | hand-authored | task-069 | 1 |
| aid-test-data-quality | hand-authored | task-069 | 0 |
| aid-test-performance | hand-authored | task-069 | 0 |
| aid-test-security | hand-authored | task-069 | 0 |
| aid-unset-connector | hand-authored | task-068 | 0 |
| aid-update | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-update-api | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-update-architecture | hand-authored | task-061 | 1 |
| aid-update-backlog | hand-authored | task-061 | 1 |
| aid-update-cicd | hand-authored | task-061 | 1 |
| aid-update-cli | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-update-config | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-update-dashboard | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-update-data-model | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-update-data-pipeline | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-update-document | hand-authored | task-069 | 1 |
| aid-update-infra | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-update-integration | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-update-job | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-update-kb | hand-authored | task-067 | 7 |
| aid-update-messaging | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-update-mvp | hand-authored | task-061 | 1 |
| aid-update-roadmap | hand-authored | task-061 | 1 |
| aid-update-stack | hand-authored | task-061 | 1 |
| aid-update-test | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-update-testing-strategy | hand-authored | task-061 | 1 |
| aid-update-theme | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |
| aid-update-ticket | hand-authored | task-068 | 1 |
| aid-update-ui | generated doorway | no change needed here (generated doorway: changes through the builder; text from shortcut-engine.md, task-062) | 0 |

Rows with no owner: **0**. Rows: **112**. `ls canonical/skills/*/SKILL.md \| wc -l` = 112.

## Suites on two tasks and the run order

A suite is on two tasks when two or more delivery-003 tasks (other than task-058) own a part of its assertions, by the measured owners or by the DETAIL file that names it. The run order: when one task depends on the other, the dependency runs first; otherwise the tasks are independent and each runs in its own worktree, merged in task-number order (the order the wave's merge takes them).

| Suite | Tasks | Run order |
|---|---|---|
| `dashboard/server/tests/test_index_html.py` | task-073, task-079 | task-073 before task-079 (dependency) |
| `site/scripts/__tests__/flow-advance.test.mjs` | task-065, task-066, task-067, task-068, task-069 | independent: task-number order |
| `site/scripts/__tests__/flow-classify.test.mjs` | task-062, task-069 | independent: task-number order |
| `site/scripts/__tests__/flow-compose.test.mjs` | task-062, task-069 | independent: task-number order |
| `site/scripts/__tests__/flow-extract-dispatch.test.mjs` | task-063, task-064, task-065, task-066, task-067, task-068 | independent: task-number order |
| `site/scripts/__tests__/flow-extract-inline.test.mjs` | task-060, task-069 | independent: task-number order |
| `site/scripts/__tests__/flow-extract-residual.test.mjs` | task-068, task-069 | independent: task-number order |
| `site/scripts/__tests__/flow-facade.test.mjs` | task-063, task-067, task-068, task-069 | independent: task-number order |
| `site/scripts/__tests__/flow-graph-doorways.test.mjs` | task-062, task-069 | independent: task-number order |
| `site/scripts/__tests__/flow-graph.test.mjs` | task-062, task-063, task-069 | independent: task-number order |
| `site/scripts/__tests__/gen-reference.test.mjs` | task-062, task-063, task-064, task-065, task-066, task-067, task-068, task-069, task-072 | independent: task-number order |
| `site/scripts/__tests__/gen-skills-index.test.mjs` | task-063, task-064, task-065, task-068, task-069 | independent: task-number order |
| `site/scripts/__tests__/gen-skills.test.mjs` | task-065, task-066, task-068 | independent: task-number order |
| `site/scripts/__tests__/provenance-appender.test.mjs` | task-062, task-069 | independent: task-number order |
| `site/scripts/__tests__/skills-groups.test.mjs` | task-063, task-064, task-065, task-068, task-069 | independent: task-number order |
| `site/scripts/__tests__/skills-render-index.test.mjs` | task-068, task-069 | independent: task-number order |
| `site/src/lib/__tests__/feature-006-head-gate.test.ts` | task-062, task-072 | independent: task-number order |
| `site/src/lib/__tests__/skill-node-panel.test.ts` | task-065, task-072 | independent: task-number order |
| `tests/canonical/test-artifact-discipline.sh` | task-062, task-065, task-072, task-074, task-078 | task-062 before task-078 (dependency); task-065 before task-078 (dependency); task-072 before task-078 (dependency); task-074 before task-078 (dependency) |
| `tests/canonical/test-connector-skills-structural.sh` | task-066, task-068 | independent: task-number order |
| `tests/canonical/test-cutover-no-dangling.sh` | task-063, task-066 | independent: task-number order |
| `tests/canonical/test-deploy-monitor-repurpose.sh` | task-062, task-068 | independent: task-number order |
| `tests/canonical/test-describe-full-only.sh` | task-060, task-061, task-062, task-063, task-064, task-065, task-066, task-067, task-068, task-069 | independent: task-number order |
| `tests/canonical/test-discovery-doc-ownership.sh` | task-066, task-072 | independent: task-number order |
| `tests/canonical/test-doc-counts.sh` | task-072, task-076 | task-072 before task-076 (dependency) |
| `tests/canonical/test-downstream-worktree-entry.sh` | task-062, task-064, task-065, task-068 | independent: task-number order |
| `tests/canonical/test-expectations-single-source.sh` | task-066, task-072 | independent: task-number order |
| `tests/canonical/test-ledger-isolation.sh` | task-066, task-067, task-072 | independent: task-number order |
| `tests/canonical/test-never-merges.sh` | task-065, task-067 | independent: task-number order |
| `tests/canonical/test-output-root-isolation.sh` | task-066, task-067 | independent: task-number order |
| `tests/canonical/test-pipeline-status-walkthrough.sh` | task-063, task-064, task-065, task-068, task-074 | independent: task-number order |
| `tests/canonical/test-review-path-audit.sh` | task-069, task-072 | independent: task-number order |
| `tests/canonical/test-scoped-review-cycles.sh` | task-064, task-065, task-072 | independent: task-number order |
| `tests/canonical/test-shared-prune.sh` | task-064, task-067 | independent: task-number order |
| `tests/canonical/test-skill-steps.sh` | task-062, task-078, task-081 | task-062 before task-078 (dependency); task-062 before task-081 (dependency); task-078 before task-081 (dependency) |
| `tests/canonical/test-state-review-surface.sh` | task-062, task-064, task-065, task-066, task-072 | independent: task-number order |
| `tests/canonical/test-ticket-retirement-structural.sh` | task-062, task-063, task-064, task-065, task-068, task-069, task-072 | independent: task-number order |
| `tests/canonical/test-work-initiation-gate.sh` | task-060, task-062, task-063, task-069 | independent: task-number order |
| `tests/conversation/run.py` | task-071, task-080 | task-071 before task-080 (dependency) |

39 suites are on two or more tasks.

## Delta

This section is what the reconciled list changes against the superseded proposal (`analysis/detail-proposal-delivery-003.md`, measured at `a3b28db4`) and what the maintainer must rule on. Nothing here edits a task file; the Scope additions are for the maintainer to make.

**D1. Counts at the base against the superseded proposal.** Measured at `7fe3aebc`:

| Item | Superseded proposal | Base 7fe3aebc | Note |
|---|---|---|---|
| `AskUserQuestion` files under `canonical/` | 13 | 14 | all 14 have a delivery-003 owner (Q4); `canonical/aid/scripts/connectors/write-connector.sh` is a comment, D3 |
| `interviewer` files in SS-05's scope | 18 | 16 | the scope is canonical/agents, skills, templates, docs, examples and site/src/content |
| `state-machine-chaining.md` citing files under `canonical/` | 19 | 0 | delivery-002 re-pointed them; the file itself is deleted by task-074 |
| skill files with `## Cross-phase Q&A` | 9 | 9 | the same nine files |
| `reviewer-brief.md` files | 6 | 6 | all six lack `### What to report` |
| Q1 banner lines | not counted | 481 | in 119 files |

**D2. Chaining file.** No canonical file cites it any more (Q6). Its live consumers are the test-pipeline suite (7 lines), its skip list and the two baselines, and all three sit with task-074 or the gate. Task-074's DETAIL depends only on task-058, so its edits do not wait for the sweep tasks; the superseded proposal's `062-068` dependency is not in the task file.

**D3. The connector comment.** `canonical/aid/scripts/connectors/write-connector.sh` line 5 is text: decided here, owner task-068 (Q4). The proposal left the question open.

**D4. Hits in files no delivery-003 task names (owner class 5).** The maintainer rules on each file. The research default leaves each file unchanged; the reason shown is the one the owner map gives:

- `bin/aid`: no change needed here (CLI reader of the old heading; spec keeps it; see Delta)
- `bin/aid.ps1`: no change needed here (CLI reader of the old heading; spec keeps it; see Delta)
- `canonical/aid/scripts/migrate/migrate-work-hierarchy.ps1`: no change needed here (migration script: reads the old shapes; outside SS-06, spec keeps it)
- `canonical/aid/scripts/migrate/migrate-work-hierarchy.sh`: no change needed here (migration script: reads the old shapes; outside SS-06, spec keeps it)
- `canonical/aid/templates/delivery-state-template.yml`: no change needed here (delivery template; Feature 006 retires it; no task edits it; see Delta D4)
- `canonical/aid/templates/work-state-template.yml`: no change needed here (comment on the delivery layout; no task edits it; see Delta D4)
- `tests/canonical/fixtures/migrate/fixture-source/work-999-migration-test/STATE.md`: no change needed here (test fixture of the old shape, read by the migration suites)
- `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/STATE.md`: no change needed here (test fixture of the old shape, read by the migration suites)
- `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/deliveries/delivery-001/STATE.md`: no change needed here (test fixture of the old shape, read by the migration suites)
- `tests/canonical/fixtures/migrate/fixture/work-999-migration-test/deliveries/delivery-002/STATE.md`: no change needed here (test fixture of the old shape, read by the migration suites)
- `tests/canonical/test-disjoint-merge.sh`: no change needed here (migration-era fixture of the delivery qa key; the edited files are not its subject)
- `tests/canonical/test-migrate-hierarchy.sh`: no change needed here (migration script suite; the spec keeps the migration)
- `tests/canonical/test-work-state-template.sh`: no change needed here (asserts delivery-state-template.yml, which no task edits)
- `tests/cost-meter.py`: no change needed here (no delivery-003 task names this file; see Delta)

- G11 (site tests): 213 (test, target) rows across 38 site test files name no delivery-003 edit target (fixture strings, template names and paths no task changes). Each is class 5 and needs no edit; they are all listed one by one in the G11 table (Site fixtures section), with that owner.

Recovery and packaging snapshots, not live sources: `recovery/partial/...` (their files name the chaining rule, the reviewer dispatch and the Cross-phase heading) and `packages/` (a local build output, not tracked as source).

**D5. Suites that read an edit-list file but are not named by the owning task.** Proposed: the owning task's Scope names the suite, and the task updates it in the same task (Q106). The owners are the measured owners of Q8:

- `dashboard/reader/tests/test_feature009.py`: ADD to task-065's Scope (same-task rule)
- `dashboard/reader/tests/test_task023_list_management_parity.py`: ADD to task-068's Scope (same-task rule)
- `dashboard/server/tests/test_task019_connector_ops.mjs`: ADD to task-068's Scope (same-task rule)
- `dashboard/server/tests/test_task019_connector_ops.py`: ADD to task-068's Scope (same-task rule)
- `dashboard/server/tests/test_task022_connectors_external_sources_ui.py`: ADD to task-068's Scope (same-task rule)
- `dashboard/server/tests/test_task023_list_management_round_trips.py`: ADD to task-068's Scope (same-task rule)
- `site/scripts/__tests__/flow-advance.test.mjs`: ADD to task-065, task-066, task-067, task-068, task-069's Scope (same-task rule)
- `site/scripts/__tests__/flow-classify.test.mjs`: ADD to task-062, task-069's Scope (same-task rule)
- `site/scripts/__tests__/flow-compose.test.mjs`: ADD to task-062, task-069's Scope (same-task rule)
- `site/scripts/__tests__/flow-engine-core.test.mjs`: ADD to task-062's Scope (same-task rule)
- `site/scripts/__tests__/flow-extract-dispatch.test.mjs`: ADD to task-063, task-064, task-065, task-066, task-067, task-068's Scope (same-task rule)
- `site/scripts/__tests__/flow-extract-engine.test.mjs`: ADD to task-062's Scope (same-task rule)
- `site/scripts/__tests__/flow-extract-inline.test.mjs`: ADD to task-060, task-069's Scope (same-task rule)
- `site/scripts/__tests__/flow-extract-residual.test.mjs`: ADD to task-068, task-069's Scope (same-task rule)
- `site/scripts/__tests__/flow-extract-sibling.test.mjs`: ADD to task-069's Scope (same-task rule)
- `site/scripts/__tests__/flow-facade.test.mjs`: ADD to task-063, task-067, task-068, task-069's Scope (same-task rule)
- `site/scripts/__tests__/flow-graph-doorways.test.mjs`: ADD to task-062, task-069's Scope (same-task rule)
- `site/scripts/__tests__/flow-graph.test.mjs`: ADD to task-062, task-063, task-069's Scope (same-task rule)
- `site/scripts/__tests__/flow-render-mermaid.test.mjs`: ADD to task-069's Scope (same-task rule)
- `site/scripts/__tests__/flow-validate.test.mjs`: ADD to task-069's Scope (same-task rule)
- `site/scripts/__tests__/gen-reference.test.mjs`: ADD to task-062, task-063, task-064, task-065, task-066, task-067, task-068, task-069, task-072's Scope (same-task rule)
- `site/scripts/__tests__/gen-skills-index.test.mjs`: ADD to task-063, task-064, task-065, task-068, task-069's Scope (same-task rule)
- `site/scripts/__tests__/gen-skills.test.mjs`: ADD to task-065, task-066, task-068's Scope (same-task rule)
- `site/scripts/__tests__/provenance-appender.test.mjs`: ADD to task-062, task-069's Scope (same-task rule)
- `site/scripts/__tests__/provenance-render-list.test.mjs`: ADD to task-069's Scope (same-task rule)
- `site/scripts/__tests__/provenance.test.mjs`: ADD to task-069's Scope (same-task rule)
- `site/scripts/__tests__/skills-body.test.mjs`: ADD to task-069's Scope (same-task rule)
- `site/scripts/__tests__/skills-catalog.test.mjs`: ADD to task-068's Scope (same-task rule)
- `site/scripts/__tests__/skills-discover.test.mjs`: ADD to task-069's Scope (same-task rule)
- `site/scripts/__tests__/skills-groups.test.mjs`: ADD to task-063, task-064, task-065, task-068, task-069's Scope (same-task rule)
- `site/scripts/__tests__/skills-render-index.test.mjs`: ADD to task-068, task-069's Scope (same-task rule)
- `site/scripts/__tests__/skills-render-page.test.mjs`: ADD to task-069's Scope (same-task rule)
- `site/scripts/__tests__/skills-render-value.test.mjs`: ADD to task-068's Scope (same-task rule)
- `site/scripts/__tests__/skills-summary.test.mjs`: ADD to task-069's Scope (same-task rule)
- `site/src/lib/__tests__/feature-006-head-gate.test.ts`: ADD to task-062, task-072's Scope (same-task rule)
- `site/src/lib/__tests__/skill-node-panel.test.ts`: ADD to task-065, task-072's Scope (same-task rule)
- `tests/canonical/test-aid-cli-parity.sh`: ADD to task-064's Scope (same-task rule)
- `tests/canonical/test-aid-migrate.sh`: ADD to task-065's Scope (same-task rule)
- `tests/canonical/test-artifact-discipline.sh`: ADD to task-062, task-065's Scope (same-task rule); named, but no measured assertion on its file: confirm and record in task-074, task-078
- `tests/canonical/test-catalog-dirs-parity.sh`: ADD to task-062's Scope (same-task rule)
- `tests/canonical/test-change-refactor-family-scaffold.sh`: ADD to task-062's Scope (same-task rule)
- `tests/canonical/test-compute-block-radius.sh`: ADD to task-065's Scope (same-task rule)
- `tests/canonical/test-conformance-lane-semantics.sh`: ADD to task-067's Scope (same-task rule)
- `tests/canonical/test-connector-set-unset-lifecycle.sh`: ADD to task-068's Scope (same-task rule)
- `tests/canonical/test-connector-skills-structural.sh`: ADD to task-066, task-068's Scope (same-task rule)
- `tests/canonical/test-cost-meter.sh`: ADD to task-072's Scope (same-task rule)
- `tests/canonical/test-create-family-scaffold.sh`: ADD to task-062's Scope (same-task rule)
- `tests/canonical/test-criterion-oracles.sh`: ADD to task-072's Scope (same-task rule)
- `tests/canonical/test-cutover-no-dangling.sh`: ADD to task-063, task-066's Scope (same-task rule)
- `tests/canonical/test-delivery-gate-aggregate.sh`: ADD to task-065's Scope (same-task rule)
- `tests/canonical/test-deploy-monitor-repurpose.sh`: ADD to task-062, task-068's Scope (same-task rule)
- `tests/canonical/test-derive-waves.sh`: ADD to task-065's Scope (same-task rule)
- `tests/canonical/test-discovery-doc-ownership.sh`: ADD to task-066, task-072's Scope (same-task rule)
- `tests/canonical/test-doc-set-mapping.sh`: ADD to task-066's Scope (same-task rule)
- `tests/canonical/test-doc-set-propose-confirm.sh`: ADD to task-066's Scope (same-task rule)
- `tests/canonical/test-doc-set-read.sh`: ADD to task-066's Scope (same-task rule)
- `tests/canonical/test-document-family-scaffold.sh`: ADD to task-062's Scope (same-task rule)
- `tests/canonical/test-domain-doc-matrix.sh`: ADD to task-066's Scope (same-task rule)
- `tests/canonical/test-downstream-worktree-entry.sh`: ADD to task-062, task-064, task-065, task-068's Scope (same-task rule)
- `tests/canonical/test-expectations-single-source.sh`: ADD to task-066, task-072's Scope (same-task rule)
- `tests/canonical/test-f010-governance-guards.sh`: ADD to task-067's Scope (same-task rule)
- `tests/canonical/test-fix-family-scaffold.sh`: ADD to task-062's Scope (same-task rule)
- `tests/canonical/test-grade-summary.sh`: ADD to task-067's Scope (same-task rule)
- `tests/canonical/test-guardrails-d012.sh`: ADD to task-067's Scope (same-task rule)
- `tests/canonical/test-kb-review-surface.sh`: ADD to task-066's Scope (same-task rule)
- `tests/canonical/test-kb-template-authoring-standard.sh`: ADD to task-072's Scope (same-task rule)
- `tests/canonical/test-ledger-isolation.sh`: ADD to task-066, task-067, task-072's Scope (same-task rule)
- `tests/canonical/test-multitool-isolation.sh`: ADD to task-065's Scope (same-task rule)
- `tests/canonical/test-never-merges.sh`: ADD to task-065, task-067's Scope (same-task rule)
- `tests/canonical/test-output-root-isolation.sh`: ADD to task-066, task-067's Scope (same-task rule)
- `tests/canonical/test-pipeline-status-walkthrough.sh`: ADD to task-063, task-064, task-065, task-068's Scope (same-task rule)
- `tests/canonical/test-prototype-family-scaffold.sh`: ADD to task-062's Scope (same-task rule)
- `tests/canonical/test-reconcile-scenarios.sh`: ADD to task-066's Scope (same-task rule)
- `tests/canonical/test-release.sh`: ADD to task-066's Scope (same-task rule)
- `tests/canonical/test-review-path-audit.sh`: ADD to task-069, task-072's Scope (same-task rule)
- `tests/canonical/test-scoped-review-cycles.sh`: ADD to task-064, task-065, task-072's Scope (same-task rule)
- `tests/canonical/test-severity-why-line.sh`: ADD to task-072's Scope (same-task rule)
- `tests/canonical/test-shared-prune.sh`: ADD to task-064, task-067's Scope (same-task rule)
- `tests/canonical/test-shared-remove.sh`: ADD to task-064's Scope (same-task rule)
- `tests/canonical/test-skill-steps.sh`: ADD to task-062's Scope (same-task rule); named, but no measured assertion on its file: confirm and record in task-078, task-081
- `tests/canonical/test-spine-depth-coverage.sh`: ADD to task-066's Scope (same-task rule)
- `tests/canonical/test-state-review-surface.sh`: ADD to task-062, task-064, task-065, task-066, task-072's Scope (same-task rule)
- `tests/canonical/test-task-state-transitions.sh`: ADD to task-065's Scope (same-task rule)
- `tests/canonical/test-test-experiment-family-scaffold.sh`: ADD to task-062's Scope (same-task rule)
- `tests/canonical/test-ticket-retirement-structural.sh`: ADD to task-062, task-063, task-064, task-065, task-068, task-069, task-072's Scope (same-task rule)
- `tests/canonical/test-ticket-skills-structural.sh`: ADD to task-068's Scope (same-task rule)
- `tests/canonical/test-update-kb-scope-fidelity.sh`: ADD to task-067's Scope (same-task rule)
- `tests/canonical/test-work-initiation-gate.sh`: ADD to task-060, task-062, task-063, task-069's Scope (same-task rule)
- `tests/canonical/test-work-state-template.sh`: ADD to task-063's Scope (same-task rule)
- `tests/canonical/test-write-connector.sh`: ADD to task-068's Scope (same-task rule)
- `tests/cost-meter.py`: ADD to task-072's Scope (same-task rule)

**D6. Suites named by a task but with no assertion on the files that task changes.** The naming task must confirm this in its own run (the rule is the same, so the suite stays on the list, and the task records nothing new):

- `tests/canonical/test-artifact-discipline.sh`: ADD to task-062, task-065's Scope (same-task rule); named, but no measured assertion on its file: confirm and record in task-074, task-078
- `tests/canonical/test-describe-full-only.sh`: named, but no measured assertion on its file: confirm and record in task-060, task-061, task-062, task-064, task-065, task-066, task-067, task-068, task-069
- `tests/canonical/test-skill-steps.sh`: ADD to task-062's Scope (same-task rule); named, but no measured assertion on its file: confirm and record in task-078, task-081

**D7. AD13 ceilings.** Today's counts are below their ceilings (Q9), so the suite is green at the base. Task-078 lowers each ceiling to the post-sweep count, and never raises one.

**D8. Sample 002-13 names a skill that is not on disk.** Its frontmatter names `aid-kb-update`, and the skill is `aid-update-kb`. The sample is deferred (AC-38), so the name has no test effect now; the maintainer should fix it when the sample is next edited (owner: task-080, which edits the samples).

**D9. Decision-record lines.** `.aid/knowledge/decisions.md` lines 783, 786 and 792 record the superseded chaining rule and the interviewer agent. Task-077 names `decisions.md` only for D15's agent count. Default: task-077 leaves the superseded entries as they are, because a decision record keeps its history; the maintainer confirms.

**D10. Work state and project state templates.** Feature 002's Files table names `work-state-template.yml` (Edit) and `project-state-template.yml` (Create). Neither is named by a delivery-003 task, and the `qa` and phase rows of that table are delivery-002's scope (its task files name the templates). Their delivery-level comment in `work-state-template.yml` is class 5 (Q3b), not an edit for this delivery.

**D11. Installed copies.** The installed trees carry every canonical hit (Installed copies). They are regenerated by the resync after the gate, with the full generator; no partial render and no `run_generator.py` in a live tree.

**D12. Test step.** Changes lie only under `.aid/works/`; no suite runs (work-folder-only rule). The spawn-free checks have no `.sh`, `.py` or `.mjs` file to check.

**D13. Run order of `tests/canonical/test-artifact-discipline.sh`.** The suite is on five tasks (see Suites on two tasks and the run order), and its one owner in Q3 is task-078. Run order: task-062, task-065, task-072 and task-074 each run before task-078 (dependency).

