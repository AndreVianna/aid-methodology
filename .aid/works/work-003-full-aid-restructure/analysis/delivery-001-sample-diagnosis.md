# Feature 001 conversation samples: failure diagnosis

Read-only analysis. Nothing was edited, run or committed. The skill and rules text is identical in the two smoke copies and the work-003 worktree (`diff -r canonical` found no differences), so the line numbers below hold in all three. Paths are given relative to the worktree unless they are absolute.

Abbreviations: S1 = `/tmp/claude-0/-home-user-aid-methodology/cd2e209b-dbef-5f81-874a-fdeb1e92d87f/scratchpad/t016/smoke.l2FsLo`; S2 = `/tmp/t017-smoke-Bl3w4M`; runs live under `<copy>/.aid/.temp/conversation-tests/<run-id>/<sample>/run-1/`.

Confidence tags: CONFIRMED (seen directly), LIKELY (strong inference), UNCERTAIN (weak signal).

## 0. What the agent under test actually had

- **Flags** (`tests/conversation/run.py:309-318`): `claude -p --output-format stream-json --verbose --permission-mode acceptEdits --tools/--allowedTools Read,Glob,Grep,Edit,Write,Bash,Skill,Task --strict-mcp-config --setting-sources project`, plus `--resume` from turn 2 on. There is no `--model`, no `--system-prompt` and no `--append-system-prompt`. CONFIRMED.
- **Environment** (`run.py:353-357`, `base_env`): copies the whole parent `os.environ` and changes only `HOME` and `CLAUDE_CONFIG_DIR`. In this sandbox that passes on `CLAUDE_CODE_REMOTE=true`, `CLAUDE_CODE_ENTRYPOINT=remote_desktop`, `CLAUDE_CODE_SESSION_ID=<parent session>`, `CLAUDE_EFFORT=medium`, `CLAUDECODE`, `CCR_*` and others. CONFIRMED (`env`).
  - The agent under test received the parent's remote-session context. Its scratchpad path carries the parent session id: 001-02 writes its benchmark to `/tmp/claude-0/-tmp-aid-conv-run-h4bd0qzm-project/cd2e209b-.../scratchpad`, outside the fixture. Its commits use the parent's attribution and the user's email: 001-10 T3 has `Co-Authored-By: Claude Sonnet 5.5`, `Claude-Session: <parent session URL>...` and `user.email=<maintainer email>`. CONFIRMED.
  - **The model under test was Claude Sonnet 5.5** (26 `Co-Authored-By: Claude Sonnet 5.5` hits across the run folders), running at inherited `CLAUDE_EFFORT=medium`. LIKELY for effort, CONFIRMED for the model.
  - The same environment writes about 205 KB of CA material into the throwaway HOME at start-up (`home/.ccr/ca-bundle.crt` 197 KB, `.pki`, `.local/share/pki`, `.aws/config`, `.boto`). It appears in **every** `files.diff`, even for runs that changed nothing (001-04's diff is 205,635 bytes and 3,356 lines). CONFIRMED.
- **Context files installed in the fixture** (`lib/aid-install-core.sh:1114-1161`):
  - `CLAUDE.md` holds the SESSION START block, the summary bullets from `canonical/aid/rules.md:3-14` and the import line `@.aid/runtime/rules.md`. The full `rules.md`, including `## Handling a request` (lines 79-96) and `## Skill guide` (lines 98-156), is therefore in context from the first token.
  - `AGENTS.md` carries the same block without the `@` line.
  - The installed skill tree includes `.claude/skills/aid-orchestrate/` with the 5 references, plus about 150 other skills (shortcut doorways such as `aid-fix`, `aid-create-cli`, `aid-update-cli` and `aid-test-performance`).
- **What was loaded in each run** (from the tool calls in every `transcript.jsonl`):
  - `Read(.aid/runtime/rules.md)` was the **first tool call in 22 of 22 runs**.
  - `Skill(aid-orchestrate)` was called in **2 of 22 runs**: both 001-15 runs, where the user literally says "start the work". Only there were `check-intent.md`, `start-or-resume.md` and `size-and-route.md` read.
  - `external-sources.md` and `feedback-routing.md` were never read in any run.
  - Other skills called: `aid-create-cli` (001-07), `aid-brainstorm` (001-08), `aid-deploy` (001-10), `aid-update`, `aid-discover` and `aid-execute` (001-15, 001-07). CONFIRMED.

So the main finding: **rules.md was always in context; aid-orchestrate almost never was.** Whatever exists only in aid-orchestrate was unavailable in 20 of 22 runs. That covers sizing (lite/full), the `intent:` record, `sources:` entries, the Preparation offer and the CI close.

## 1. Per-sample table (latest run per sample, judged against the sample text in the copy)

| Sample | Run (copy) | Result | What the agent did | First divergence | In context at that point | Class |
|---|---|---|---|---|---|---|
| 001-01 one-match | 20261018T013643Z (S1); 012200Z same | FAIL: Edit src/* + 4 rows | Read rules, named `/aid-fix`, read code/KB with Bash, then `Edit(src/notes/store.py)` and `Edit(tests/test_store.py)` in turn 1. Reported the finished fix. | T1, first text: "This is a defect, so `/aid-fix` fits. I'll start by looking at the code." then edits. The close says "I didn't start a tracked work or write a STATE entry for this small fix. Say so if you want it recorded through `/aid-fix`." | rules.md (Read + import), including rules.md:83 "One skill fits: propose its workflow" and :96 "the user approves before building". No skill loaded. | (c) primary, (a) contributing ("propose" is undefined; nothing says "no edit before agreement, however small") |
| 001-02 several-decide | 012256Z (S1) | FAIL: 1 row (EO-1) | Read rules/KB, benchmarked `list` in the leaked scratchpad (outside the fixture) and gave a good answer. Named no workflow. | T1: went straight to "I measured this without touching any project code"; never says which workflow it chose or why. | rules.md only. The guide lists `/aid-test-<kind>` (rules.md:141) but not `aid-test-performance` by name, and that skill's description requires "a threshold or SLO". The user has none. | (a) (rules.md:83-84 does not require naming the choice; the description wording steers away) + (d) sample expectation |
| 001-03 several-ask | 012402Z (S1) | FAIL: 3 rows | T1: surveyed the project, found nothing "messy", and asked one question ("What did you mean by messy?") with 3 options and a recommendation. T2: proposed `/aid-refactor` and asked "Shall I go ahead ... If you'd rather skip any of the four steps, say which." | T1: its options are its own (code structure / notes data / something unseen), not the workflow kinds the sample lists (tidy / remove / KB re-sync). It had already ruled out the KB re-sync by checking. | rules.md only | (d) mostly (the judge counted the T2 approval plus "say which" as two questions, and the EO wants specific option kinds) + (a) mild |
| 001-06 kb-conflict | 012641Z (S1) | FAIL: 2 rows | Read `architecture.md` and saw that "the single JSON file is the state". Planned `/aid-migrate` and planned to **update** the KB. Asked only about importing old notes. | T1: "`README.md` and `.aid/knowledge/architecture.md`: both currently describe the single JSON file as the state, so I'd update them." It treated the KB statement as stale documentation, not as a conflict. | rules.md:95 "Check every decision against the Knowledge Base; raise a conflict, never settle it alone." "Conflict" is not defined. | (a) |
| 001-07 rich-ticket | 013859Z (S1); 013731Z, 012801Z | 013859 and 012801: judge input too long (5.15 MB diff). 013731: FAIL (no Skill call + 4 rows) | 013731: proposed `/aid-create-cli` and asked "Shall I proceed?" (no Skill call). 013859 and 012801: `Skill(aid-create-cli)` in T2, shortcut engine, own worktree, wrote REQUIREMENTS/tasks, reviewer agents. In 012801 the simulated user then approved `/aid-execute` and the whole build ran. | T1 in all three: says neither "no brainstorming, straight to spec/plan" nor "lite". It proposes (rules.md:83) instead of starting the skill (orchestrate SKILL.md:39 "Start the first phase skill yourself"). | rules.md; `aid-create-cli` (shortcut engine) once started. aid-orchestrate was never loaded. The engine has no `intent:`, depth wording or "lite" announcement (`shortcut-engine.md` has only `path: lite` at :325/:339). | (d) judge size + simulated user (012801 T3 "Yes, I approve running it" instead of `<<END>>`) + (a) structural (action-skill handover skips sizing) + (a) "propose" vs "start yourself" |
| 001-08 bare-idea | 013411Z (S1) | FAIL: 3 rows | T1: proposed `/aid-brainstorm` but asked "Does that route suit you, or would you rather skip straight to `/aid-describe`?" and listed 3 open topics. T2: `Skill(aid-brainstorm)` INTAKE asked "Is `note-tagging` a good name?" | T1: offered a choice of workflows and never sized the work as full. T2: the first brainstorm question is about the seed slug, not the idea. | rules.md; then aid-brainstorm SKILL.md. Sizing (`size-and-route.md` §2) was never loaded. | (b) sizing lives only in an unread reference + (a) `canonical/skills/aid-brainstorm/SKILL.md:37-39` INTAKE step 2 "confirm it with the user" makes the slug the first question |
| 001-09 bug-fix-phases | 012327Z (S2) | FAIL: 6 rows | Same pattern as 001-01: "This is a defect fix. Let me find the code..." then `Edit(src/notes/commands.py)` and `Edit(.aid/knowledge/capability-inventory.md)`, with no reproduction before the edit. "I made the fix directly without starting an AID work or STATE file, since it's a one-line defect." | T1 edit | rules.md only | (c) primary, (a) contributing; + (d) judge row 6 [MEDIUM] is not an EO/MN item (`judge.md:31-32` forbids that) |
| 001-10 release-own-work | 014349Z (S2); 012424Z | FAIL: 4 rows | T1: good reading ("this is a release, so `/aid-deploy` fits") with one question. T2: `Skill(aid-deploy)`, worktree, proposed a plan. T3: committed, fast-forwarded master, tagged, added `.gitignore` `__pycache__/`. "I didn't write the work's `STATE.yml` or `REQUIREMENTS.md`, or run the review-grading steps. I judged them disproportionate." | T2: "the full AID path would also write a requirements document and a task file ... I'd keep that to a minimal record". It decided to skip the skill's own bookkeeping. | rules.md, aid-deploy SKILL.md, shortcut-engine.md. The CI close (`size-and-route.md` §3) was not in context. | (c) primary; (b) for the close. Note: the current sample adds the check `tool-called Bash *writeback-state.sh*Lifecycle*Completed*`, which only an agent that has read `size-and-route.md` §3 would know to run. |
| 001-11 ticket-mid-work | 012605Z (S2) | FAIL: 2 checks + 3 rows | Read the ticket and STATE.yml, closed Q4/Q6 as Answered with ticket values, rewrote REQUIREMENTS.md. Added **no** `sources:` entry, although the STATE.yml it read shows `sources: []` at line 29. | T1: the `Edit(STATE.yml)` touches `qa:` only | rules.md only. The pull-in rule ("Append one `sources:` entry", `references/external-sources.md:12-19`) exists only in an orchestrate reference that was never loaded. rules.md never mentions `sources:`. | (b) |
| 001-12 write-back-limit | 014542Z (S2) | **PASS** (empty ledger). The earlier 012708Z run failed on the old sample text, where PROJ-42 was not said to be a file. | n/a | n/a | n/a | the sample fix worked |
| 001-13 project-source-unattached | 012850Z (S2) | FAIL: 1 row (MN-1) | Read PROJ-99 and `external-sources.md`, added constraints to REQUIREMENTS.md, left `sources: []`, and said so in one line. Added a `lifecycle_history` entry ("Added payments-team retry rules from PROJ-99 as constraints"). | None in substance. The judge ruled that the history entry "records it in the work's state file". | rules.md (tracking discipline, rules.md:16-29, **requires** recording the change) | (d) sample: `001-13-project-source-unattached.md:30` "or record it in the work's state file" contradicts rules.md tracking discipline |
| 001-14 refactor-is-new-capability | 013022Z (S2) | FAIL: 2 rows | T1: reclassified correctly ("this isn't a refactor ... a search is new behaviour"). Then offered "`/aid-update-cli` ... or just make the small edit directly?" and **recommended the direct edit**. T2: user agreed, edits to src, tests and KB, untracked. | T1: offers and recommends bypassing the workflow | rules.md only (:83-84 "None fits: carry on with no AID workflow" is the only bypass sentence; nothing forbids offering one when a skill fits) | (c) + (a) |
| 001-15 no-kb-offers-preparation | 014633Z (S2); 013147Z | 014633: judge input too long (5.15 MB diff). 013147: FAIL on the turn cap; the judge ledger was **empty** (it would have passed). | 013147: `Skill(aid-orchestrate)` + 3 refs, then a correct Preparation offer (it recommended skipping, but did offer). The user said "discover", `aid-discover` ran, and the simulated user kept answering ELICIT prompts to turn 12. 014633: `Skill(aid-orchestrate)` + 3 refs, then `Skill(aid-update)` at once, with no Preparation offer, the whole shortcut engine in T1, and execution in T2. | 014633 T1: the handover to `aid-update` (orchestrate step 3) comes before the Preparation offer (step 6 / `size-and-route.md` §5). | aid-orchestrate SKILL.md + check-intent + start-or-resume + size-and-route. **The instruction was in context; the skill's own step order skips it.** | 014633: (a) structural ordering. 013147: (d) simulated user did not end ("Once the assistant has started building the knowledge base ... reply with the end marker"). Both: (d) judge size. |
| 001-16 work-closes-done | 014211Z (S2) | FAIL: 1 row | Found the work and ran `writeback-state.sh` (Lifecycle Completed, Active Skill none) plus a hand-written history entry. Left `phase: Execute`. Said "The intent listed CI as the closing phase, and I didn't run it." | T1 report. It did what `size-and-route.md` §3 prescribes, but did not know that this **is** the CI close, so it reported CI as not run. | rules.md:92-93 "CI always closes the work", with no definition. The orchestrate description (SKILL.md:4) and the guide entry (rules.md:105) say "start, resume or cancel", with no "close", so "close it out" matched nothing. | (a) + (b) |
| 001-04, 001-05 | 012510Z, 012550Z (S1) | PASS | n/a | n/a | rules.md only | n/a |

## 2. Root causes, ranked by how many failing samples they explain

**RC-1. aid-orchestrate is not loaded, so everything that lives only there is invisible.** Class (b) placement. Explains 7: 001-07, 001-08, 001-09, 001-10, 001-11, 001-14, 001-16.
- The guide makes a shortcut skill the closest match for almost every concrete request: `/aid-fix` "when something is broken" (rules.md:135), `/aid-create-<kind>`, `/aid-update-<kind>`, `/aid-deploy`. The agent picks it directly. `/aid-orchestrate` (rules.md:105, SKILL.md:4) reads as "start, resume or cancel a work", which the agent takes as a lifecycle tool, not the front door for "fix this", "add that" or "close it out".
- Sizing (lite/full) and the phase list exist only in `references/size-and-route.md`. The `intent:` record is in `start-or-resume.md` §6, `sources:` and `write_backs:` in `external-sources.md`, the Preparation offer in `size-and-route.md` §5 and the CI close in `size-and-route.md` §3. The samples' expected outcomes ("sizes it lite/full and says so", "Specification -> Planning -> Building -> CI", "records a source", "closes through the closing step") need exactly that content.
- Evidence: 20 of 22 runs never called `Skill(aid-orchestrate)`. 0 runs read `external-sources.md`.

**RC-2. "Small, clear request → just do it" (the proportionality shortcut).** Class (c) model compliance, amplified by (a) wording. Explains 4 directly (001-01, 001-09, 001-14, 001-10) and shows up in 3 more as "I wrote them myself instead of dispatching an architect, because the change is small" (001-07 013859, 001-15 014633) and the untracked benchmark in 001-02.
- Quotes:
  - 001-01: "this small fix"
  - 001-09: "since it's a one-line defect"
  - 001-10: "I judged them disproportionate"
  - 001-14: "My recommendation is the direct edit. The change is small"
- In every case rules.md was in context. The agent names the right skill and then does the work by hand.
- The wording makes this easy:
  - rules.md:83 says only "propose its workflow", without "and stop" or "change nothing until the user agrees".
  - The only no-build rule sits at the end of a bullet about question style (:96 "the user approves before building and the result").
  - Nothing says size picks the **depth**, never whether the workflow runs.
  - rules.md:84 "None fits: carry on with no AID workflow" is the only explicit permission to act freely, and the model stretches it to "fits, but small".

**RC-3. Structural contradiction: action-skill handover bypasses sizing, intent and Preparation.** Class (a) wording, and it is inherited from the spec (REQUIREMENTS.md Feature 001 §2 routing rule). Explains 4: 001-07, 001-09/001-14 (no phase statement is reachable), 001-15 (014633).
- `aid-orchestrate/SKILL.md:26-28` (step 3) and `size-and-route.md:22-24` hand an action-skill reading over **before** step 6 (size and record `intent:`), step 7 (show the reading) and `size-and-route.md` §5 (Preparation). The phase table rows "Bug fix, refactor, change, new capability, document → Spec → Plan → Build → CI" are effectively dead, because every such reading matches `/aid-fix`, `/aid-create`, `/aid-update` or `/aid-refactor`.
- The shortcut engine records no `intent:`, never says lite/full and never offers Preparation (`grep` of `shortcut-engine.md`: only `path: lite`).
- 001-15 014633 is the clean proof. The agent had all three references in context and still went orchestrate → `aid-update` with no Preparation offer.
- Related: rules.md:83 "propose its workflow" vs SKILL.md:39 "Start the first phase skill yourself" vs sample 001-07 "starts the workflow itself, using the Skill tool". 001-07 013731 proposed, 013859 started, and both are defensible readings.

**RC-4. Harness defects.** Class (d). Explains 2 directly (001-07, 001-15) and inflates or distorts every judgment.
- (i) Judge input too long. A worktree created by `worktree-lifecycle.sh` under `.claude/worktrees/` is a full checkout of the fixture: about 590 files, 5.15 MB, all diffed against `/dev/null`. Every run also carries 205 KB of HOME CA noise.
- (ii) The simulated user ignores the answer sheet's END trigger:
  - 001-07 012801 T3: "Yes, I approve running it. Go ahead with `/aid-execute`."
  - 001-15 013147: kept answering `aid-discover` ELICIT to turn 12.
- (iii) Env leakage: parent remote-session context, Sonnet 5.5 at medium effort, scratchpad writes outside the fixture, the parent's email and session URL in commits. The effect on behaviour is UNCERTAIN. It is a fidelity and privacy defect regardless.
- (iv) The judge adds rows that are not EO/MN items (001-09 row 6 [MEDIUM]; 001-12 012708Z row 1 says "met in substance" yet stays Pending), against `judge.md:31-32`.

**RC-5. Undefined key terms in `## Handling a request`.** Class (a). Explains 3: 001-06 ("conflict", rules.md:95), 001-16 ("CI closes", rules.md:92-93), 001-01/001-09 ("propose", rules.md:83). 001-01/001-09 are also counted under RC-2.

**RC-6. Sample and fixture defects.** Class (d). Explains 2-3: 001-13 (Must-not line 30 contradicts tracking discipline), 001-03 (the EO names specific workflow kinds; the judge treats an approval plus "say which" as two questions), 001-02 (it expects "the performance check", but `aid-test-performance`'s description requires a threshold or SLO the user doesn't have).
- Cross-sample trap: the default fixture's `architecture.md:24` "Nothing else is persisted." makes 001-07's CSV export a KB conflict too. 013859 raised it as a question before approval. Fixing 001-06 (RC-5) will push 001-07 to ask an extra question.

Common causes you asked about:

| Hypothesis | Verdict |
|---|---|
| "Acts in the first turn before reading rules" | **Refuted.** rules.md was the first Read in 22 of 22 runs, and it is also `@`-imported. |
| "CLAUDE.md summary weaker than rules.md" | **Not a cause**, because the full rules.md is imported. The summary bullet (rules.md:4-5) mentions the skill guide but not "propose and wait"; that is harmless here. |
| "Skill guide says propose but a shortcut skill says act" | **Partly true.** The shortcut doorways themselves halt at the approval gate (`aid-fix` SKILL.md: "halts at the FR-10 approval gate. It never executes"). The real issue is that the agent never starts them and does the work by hand (RC-2). The propose-vs-start split is between rules.md:83 and orchestrate SKILL.md:39 (RC-3). |
| "`--permission-mode acceptEdits` lets it edit freely" | **An enabler, not a cause.** It removes the permission prompt that would act as a human gate in an interactive session, and the spec mandates it. |
| "`-p` one-shot pushes it to finish in one turn" | **Weak.** In 8 of the 13 failing samples the agent did stop and ask at some point (001-03, 06, 07, 08, 10, 13, 14, 15). The immediate-action failures correlate with "small clear defect" wording, not with `-p`. UNCERTAIN as a minor amplifier. |

## 3. Fixes (smallest first), with expected effect

Budget note: `## Handling a request` is rules.md:79-96, which is **18 of the 20 lines** AC-6 allows (counting rule in REQUIREMENTS.md Feature 001 §3). Any rules.md fix must reword lines, not just add them.

### Harness and samples (no product change; do first)

1. **Judge input size** (`run.py:464-491` `build_diff`, `run.py:413-420` skips, `run.py:609-619` judge prompt):
   - (a) Diff each `fixture/.claude/worktrees/<wt>/<path>` against `before["fixture/<path>"]` instead of `/dev/null`, and omit it when it is byte-identical. This still records every change the agent made (spec REQUIREMENTS.md:989-993 asks for "every change the agent makes") and drops the 5 MB copy, including the copied `.aid/runtime/`.
   - (b) In `home_skip`, also exclude the sandbox's own CA and credential set-up files: `.ccr/`, `.pki/`, `.local/share/pki/`, `.aws/`, `.boto`. They fall under the spec's "host tool's own files ... and any credential file" exclusion.
   - (c) As a backstop for the judge prompt only (keep the full `files.diff` on disk): cap each file's hunk text at, say, 300 lines and the whole diff at about 200 KB, with an explicit `[... N lines of <path> truncated ...]` marker. Say in `judge.md` that truncated content must not be assumed absent.
   - Confidence that this removes the "input too long" failures: high (90%). Do **not** simply exclude `.claude/worktrees/` or `.aid/`: that would hide real agent writes such as STATE.yml and code edits in the worktree, which the spec wants judged.
2. **Simulated user END triggers** (`tests/conversation/simulated-user.md:15`, and the prompt tail in `run.py:576-577`): add a first rule along the lines of "Before writing anything, check the answer sheet's `<<END>>` conditions; if one is met by the assistant's last message, reply `<<END>>` alone. This overrides every other rule." Repeat it in the per-turn prompt. Fixes 001-07 012801 and 001-15 013147 behaviour. Confidence high (80%).
3. **Environment isolation** (`run.py:353-357`): drop the inherited `CLAUDE_CODE_*` session and remote variables (`CLAUDE_CODE_SESSION_ID`, `CLAUDE_CODE_REMOTE*`, `CLAUDE_CODE_ENTRYPOINT`, `CLAUDECODE`, `CLAUDE_CODE_CHILD_SESSION`, `CLAUDE_EFFORT`, `CLAUDE_AFTER_LAST_COMPACT`, `CLAUDE_CODE_USER_EMAIL`, ...). Keep proxy and CA variables. Add an explicit `--model` (or an env-selectable one) and record it in the run folder.
   - Risk: in this sandbox the child may need some of those variables to authenticate. Verify on one sample. The effect on pass rate is UNCERTAIN; the effect on fidelity and privacy is certain.
4. **Judge discipline** (`judge.md:31-32`): add "Never add a row that is not an EO-n or MN-n item; an item met in substance gets no row." It removes spurious rows (001-09 row 6, 001-12's old row 1). Low impact on pass count.
5. **Sample 001-13** (`001-13-project-source-unattached.md:30`): change to "Add the payments ticket to the work's `sources:` list." The run otherwise met every item. Confidence of green: 80%.
6. **Sample/fixture interplay 001-06 / 001-07**: either word 001-07's KB-conflict expectation (a conflict question counts as part of the single pre-build approval) or narrow the default fixture's `architecture.md:24` so an export file is not a conflict. Otherwise fix 8 trades 001-06 for 001-07.
7. **Sample 001-03 and 001-02** (optional): 001-03 should accept "one question with options and a recommendation" without requiring the three named kinds. 001-02 should accept any read-only investigation workflow that is named with its reason, or the `aid-test-performance` description should drop the "against a threshold or SLO" precondition.

### Product wording and placement

8. **rules.md, `## Handling a request`** (canonical/aid/rules.md:81-96). Reword, staying at or under 20 lines:
   - :83-84 → "One skill fits: propose it in one line with your reading, then stop: change no project file until the user agrees, however small the change. Small work runs `lite`; it never runs by hand outside its workflow. None fits: carry on with no AID workflow." (RC-2, RC-5)
   - :88-89 → "Every request that changes the project, or starts, resumes, closes or cancels a work, goes through `/aid-orchestrate` first: it checks the reading, sizes it, records it and hands over." (RC-1)
   - :92-93 → "... CI always closes the work (today: `/aid-orchestrate` marks it `Completed`)." (RC-5, 001-16)
   - :95 → "A request that would make a Knowledge Base statement false (a decision or a constraint such as what is persisted) is a conflict: quote it and ask the user before planning around it." (001-06)
   - Add, if a line is free: "A ticket, file or link brought into a work is appended to its `sources:` before it is applied." (001-11)
   - Confidence:
     - 001-16 and 001-11: medium-high (65-70%).
     - 001-06: medium (60%).
     - 001-01, 001-09, 001-14: medium (40-55% per run; lower for 3 of 3 runs, see the bottom line).
9. **Skill guide entry and description**: rules.md:105 and `aid-orchestrate/SKILL.md:4` → "start, resume, close or cancel a work, and size it; when a plain request changes the project or continues, closes or cancels a work". Add a SKILL.md step "Close a work" that points to `size-and-route.md` §3 and sets `phase` too. (RC-1, 001-16)
10. **Reorder aid-orchestrate so sizing and Preparation come before the action-skill handover** (`SKILL.md:21-44`; `size-and-route.md:22-24`; `start-or-resume.md:25-27`):
    - Check the reading.
    - Offer Preparation when there is no KB.
    - Size (phases and depth).
    - Show the reading with its depth in one line.
    - Then hand over to the action skill, with `intent:` written once the skill's START has created the work (or let the shortcut engine accept and write a passed-in `intent:`).
    - This is a spec-level change: REQUIREMENTS.md Feature 001 §2 routing rule states the handover "before any work is created". **Flag it for a human decision.**
    - Fixes 001-15 (014633 ordering), and makes "lite / no brainstorm" statements reachable in 001-07, 001-09 and 001-14. Confidence medium (50-60%), and only together with fix 8's "goes through `/aid-orchestrate` first".
11. **aid-brainstorm INTAKE** (`canonical/skills/aid-brainstorm/SKILL.md:37-39`): derive the slug and state it in the same message as the first question about the idea ("I'll call the seed `note-tagging`; first question: ..."), rather than making slug confirmation its own question. Plus the orchestrate path for the "full" sizing line. Fixes 001-08 (EO-1 and EO-3). Confidence medium (50%).
12. **Within skills, the proportionality bypass** (001-10, and the "wrote it myself instead of dispatching an architect" pattern): one line in `shortcut-engine.md` and `aid-deploy` START: "Size never skips a step of this workflow: the STATE.yml, the documents and the gates run for a one-line change too." Confidence low (30%); this is the most compliance-bound failure.

### What no wording fix is likely to solve reliably

- **The RC-2 behaviour on Sonnet 5.5 at medium effort** (001-01, 001-09, 001-14, 001-10). The instruction to wait was in context and the model chose to act, rationalising size each time. Stronger wording should raise the per-run pass rate, but "3 of 3 runs must pass" per sample makes a reliable green unlikely without a mechanical guard. One option is a PreToolUse hook that blocks Edit/Write outside `.aid/` while no work has `user_approved`, which `.claude/settings.json` could carry, since `capabilities.hooks = true` for claude-code. That is a design decision.
- **Samples that depend on judge interpretation** (001-03, 001-02, partly 001-11 EO-4 "one line") will stay noisy at 3 of 3 runs whatever the product wording.

## 4. Judge input-size limit: where and what

- The prompt is built in `run.py:609-619` (`judge()`). It concatenates `transcript_md`, the **whole** `diff` in a code fence, `checks_txt`, Expected outcome and Must not, sent on stdin to `helper_call`.
- The diff comes from `build_diff(before, after)` (`run.py:464-491`) over `capture()` (`run.py:446-451`). The only exclusions are fixture `.git/` (`run.py:413-414`) and HOME `.claude/`, `.claude.json` and credential-named files (`run.py:417-420`).
- Failing runs: 001-07 013859Z (5,150,741 B), 001-07 012801Z (5,151,928 B), 001-15 014633Z (5,149,499 B). About 590 `fixture/.claude/worktrees/...` files each, mostly an untouched copy of the fixture including `.aid/runtime/`.
- Smallest safe change consistent with spec REQUIREMENTS.md:972-993 ("every change the agent makes", with git-ignored files included):
  - Diff worktree files against the main fixture's baseline file of the same relative path, and skip identical ones (fix 1a).
  - Add the sandbox CA and credential files to the HOME exclusions (fix 1b). The spec already excludes "host tool's own files ... and any credential file".
  - Apply a per-file and total cap with explicit truncation markers **only on the judge prompt** (fix 1c), and record the cap in the spec's Transcript capture bullet.
  - Excluding `.claude/worktrees/` or `.aid/runtime/` wholesale is not spec-consistent: the agent's real work (STATE.yml, src edits) lands inside the worktree, and samples judge it.

## 5. Bottom line

Mainly fixable, so option A is worth doing now. It is fixable mostly by **placement** (route plain change requests through aid-orchestrate; reorder its handover after sizing and Preparation), **definitions** in `## Handling a request` ("propose and stop", "conflict", "CI close", "sources"), and **harness and sample fixes**. The harness fixes are cheap and needed whatever is decided about the product wording.

The residual is model compliance. In 4 samples (001-01, 001-09, 001-14, 001-10) the agent had the rule in context and chose to act by hand on "small" work. Wording can raise the per-run pass rate, but probably not to 3 of 3.

Estimate for a first fix round (harness + samples + rules.md + orchestrate description/reorder + brainstorm INTAKE):
- **Single run:** about 7-9 of the 13 failing samples turn green, likely 001-13, 001-16, 001-11, 001-15, 001-06, 001-07, plus 2-3 of {001-01, 001-09, 001-14, 001-08, 001-02}.
- **The gate as specified (3 of 3 runs):** about 4-6. 001-10 and 001-03 are the least likely.

If 3 of 3 stays the gate, either accept 2 of 3 for the compliance-bound samples, or add the mechanical pre-approval guard (option B for that subset only). Also pin the model under test, because today's results are from Sonnet 5.5 at medium effort, inherited by accident from the sandbox environment.
