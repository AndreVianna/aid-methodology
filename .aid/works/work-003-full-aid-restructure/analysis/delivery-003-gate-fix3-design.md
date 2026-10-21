# Delivery-003 gate fix round 3: design

The third sample fix round, asked for under Q180 and Q181. Q180 makes delivery-003 move forward only when all 9 gate
samples pass 3 of 3. Q181 pulls backlog W7-14 into this round: a Claude Code question-form hook installed by the CLI,
plus four targeted fixes, smoke runs while fixing and 3 runs at the end. It answers the attempt-3 column of
`delivery-003-gate.md` § Sample results. Nothing is built until this design is approved, and nothing is planned on
the Knowledge Base conflict in Open point 1 until it is answered.

## Where attempt 3 stands

| Sample | Attempt 3 | Main failure | Answered in this round by |
|---|---|---|---|
| 002-01 connector question | 3/3 | | regression smoke only |
| 002-02 settings groups and breaks | 3/3 | | regression smoke only |
| 002-03 follow-up, skip answered | 2/3 | PC-5: `none`, `svn`, `mercurial` offered for a git project; `greenfield` for one with code | fix (a) |
| 002-04 skip, then another user | 0/3 | PC-10, PC-4, PC-11: the follow-up offer to run `/aid-set-connector` is unrecorded and outside the form; no `aid-set-connector` call | the hook; playbook row if the call is still missing |
| 002-14 orchestrate, unsure reading | 0/3 | the first clarifying question is outside the form and unrecorded; once two questions in one turn | the hook |
| 002-16 research without a question | 2/3 | PC-9: a skipped scoping question is not recorded `Assumed` | fix (d) |
| 002-17 review publish approval | 1/3 | run 1 CRITICAL: the agent offered to apply code fixes and ran `/aid-fix` and `/aid-execute`; run 3: the publish question unrecorded | fix (c); the hook |
| 002-18 report what to analyze | 1/3 | `/aid-report` starts at once and picks the only data file, so the question about what to analyze is never asked | fix (b) |
| 002-19 monitor finding question | 0/3 | the no-data question is asked by hand, before `/aid-monitor` runs, outside the form and unrecorded | the hook; playbook row for the hand-asked question |

The root cause of 002-17 run 1 is on disk. `canonical/aid/templates/reviewer-ledger-schema.md` § Ad-hoc user-prompted
reviews, step 5, tells the agent to ask "whether to apply the fixes now", and recommends applying them when a finding
is `[HIGH]` or above. `CLAUDE.md` § Review output format points every agent at that file.

## 1. The question-form hook

### The host contract

Verified against the Claude Code hooks reference, `https://code.claude.com/docs/en/hooks` (read 2026-10-21). The
repo's own Claude Code waker, `chat-node/adapters/claude-code.mjs`, already blocks with the same output shape.

| Item | What the reference says |
|---|---|
| Event | `Stop` runs when the main agent finishes responding; not on a user interrupt. A sub-agent fires `SubagentStop`, not `Stop` |
| Input (stdin JSON) | `session_id`, `transcript_path`, `cwd`, `hook_event_name`, `stop_hook_active`, `last_assistant_message` (the text of the final response) |
| `stop_hook_active` | `true` when Claude is already continuing because of a stop hook |
| Block | exit 0 with `{"decision": "block", "reason": "<text>"}`; Claude receives the reason and continues. Exit 2 with stderr routes the same way |
| Loop cap | after 8 consecutive continuations Claude Code ends the turn anyway |
| Transcript lag | the transcript file is written asynchronously and may miss the newest messages; use `last_assistant_message` for the final text |
| Location | `.claude/settings.json` is the project scope and can be committed; `.claude/settings.local.json` is per machine |
| Path | `${CLAUDE_PROJECT_DIR}` is substituted and exported; in shell form it is wrapped in double quotes |
| `-p` runs | a `-p` session treats the folder as trusted, so hooks in a committed `.claude/settings.json` run |
| Windows | shell form runs in Git Bash, or in PowerShell when Git Bash is not installed |

Assumption, not documented: the transcript is JSON lines, one entry per message, with `type`, `message.role`,
`message.content` blocks (`text`, `tool_use` with `name` and `input`, `tool_result`), and `isSidechain` / `isMeta`
flags. The parser reads it tolerantly: an entry it cannot read is skipped, never fatal.

The runner proves the hook is exercised. `tests/conversation/run.py` `build_fixture` installs each fixture with
`bin/aid add claude-code`, and `ClaudeCodeAgent.send` runs `claude -p` with `--setting-sources project`. The CLI
reference (`https://code.claude.com/docs/en/cli-reference`) lists `user`, `project` and `local` as separate sources,
so that flag loads `.claude/settings.json` and not `.claude/settings.local.json`.

### Where it lives

| File | Role |
|---|---|
| `canonical/aid/scripts/hooks/aid-question-form.sh` | Launcher. Finds `python3` (then `python` at 3.8 or later) and runs the checker. No Python, or any error: prints `{}` and exits 0 |
| `canonical/aid/scripts/hooks/aid-question-form.py` | The checker. Python standard library only, 3.8-compatible (the PyPI package's floor) |

`release.sh` `build_shared_payload` copies `canonical/aid/**` verbatim to the runtime, so both files ship to
`.aid/runtime/scripts/hooks/` with no generator change. The language follows the project's own JSON handling:
`lib/aid-install-core.sh` `_manifest_write_v3_python` and `chat-node/scripts/hook-install.py` parse JSON with
`python3`; no canonical script uses `jq`. Both files carry the Purpose / Usage / Exit codes header
(`coding-standards.md` F-03).

### What it does

1. Read stdin. `stop_hook_active` true: print `{}`, exit 0. This is the only re-entry rule, and it is enough: the hook
   blocks at most once per turn and never loops.
2. `AID_QUESTION_HOOK=off` in the environment: print `{}`, exit 0 (a kill switch for one session).
3. Take the message from `last_assistant_message`. Absent: the last assistant text in the transcript.
4. Decide whether the message waits on the user (below). It does not: print `{}`, exit 0.
5. Run the checks (below). All pass: print `{}`, exit 0.
6. Otherwise print one block object with the reason, exit 0. When `AID_QUESTION_HOOK_LOG` names a file, append one JSON
   line to it: time, `session_id`, the missing items, and the blocked message text. Only the runner sets it.

### When a message waits on the user

Fenced code blocks are removed first; a `?` inside one never counts. The message waits on the user when any of these
holds:

- a line matches the form's first line: `{subject} -- question {n} of {m} -- importance: {label}` (`--`, an en dash
  or an em dash accepted as the separator);
- its last paragraph has a sentence that ends with `?` (outside inline code and URLs);
- a line is a closing line (it holds "your own words" and "explain").

It does not wait, and the hook passes at once, when:

| Exception | How it is recognised |
|---|---|
| The break offer (question-protocol Rule 7) | the last paragraph holds `Take a break, or go on to` |
| A final report that asks nothing | none of the three signs above |

### The checks

| # | Check | Passes when |
|---|---|---|
| F1 | First line | a line matches the first-line pattern, with the label `high`, `medium` or `low` in lower case |
| F2 | Reason | a line starts with `Why I ask:` (bold or italic markers ignored) |
| F3 | Recommendation | a line starts with `My recommendation:` (the same tolerance) |
| F4 | Closing line | a line offers own words and an explanation: the question line or the approval line, by meaning, as PC-5(e) reads |
| F5 | Record | one of the three record signs below, unless the record is waived |

The hook does not judge which closing line is right (a question or an approval). That is meaning, and stays with the
judge.

Record signs (any one passes F5):

- **R1.** A Bash call in this turn whose command holds `writeback-state.sh` and `--ask`. This covers `--ask`,
  `--ask --design` and `--project --ask`. "This turn" is every main-thread entry after the last real user prompt (a
  `user` entry that is not a tool result and not `isMeta`); `isSidechain` entries are ignored.
- **R2.** An Edit or Write in this turn on `.aid/knowledge/STATE.md`: a Knowledge Base question is recorded there
  (`question-protocol.md` § Where each record lives).
- **R3.** The question re-shows an open entry: a `Pending` or `Skipped` entry in `.aid/STATE.yml`, a work
  `STATE.yml` `qa` list, or a `.aid/design/*.md` `## Questions` table whose `category` equals the first line's subject
  (the protocol's record key for the subject), or whose `context` matches the question line (normalised text: lower
  case, punctuation and extra spaces removed; one contains the other). This covers a skipped question offered again
  on its own entry, which writes no new `--ask` (002-04's fixture holds a `Skipped` `Connections` entry; the
  `aid-config` walk re-asks on the same entry), and a question a sub-agent recorded for the main conversation to ask.
  It is matched on the category as well as the text because an agent re-words a question it shows again.

The record is waived (F1 to F4 still apply) for:

| Waiver | Recognised by |
|---|---|
| The recovery confirmation (`skill-steps.md` § Recovery) | the first line's subject is `Recovery`. Not "the turn ran `--check`": every resume runs it, and a clean check is followed by recorded questions |
| The cancel confirmation (`aid-orchestrate` `references/start-or-resume.md` § 5. Cancel a named work) | the first line's subject is `Cancel work` |
| A ticket skill (no writer, `question-protocol.md` § Where each record lives) | the session's most recent Skill call is `aid-read-ticket`, `aid-create-ticket` or `aid-update-ticket` |

Fix (e) below names the two fixed subjects in the two skill files, so the hook has something stable to read.

Transcript lag: before it reads R1 or R2, the hook waits until the transcript's last assistant text equals the
message, polling every 100 ms for at most 2 s. Then it judges on what is there. The Bash calls of a turn come before
its final text, so they are normally on disk already.

### The reason it sends back

Short and plain, naming only what is missing. For example:

```text
AID question check: your message waits on the user but is missing: the record (no writeback-state.sh --ask ran
this turn); the "Why I ask:" line.
Record the question first (--ask; --ask --design before a work exists; --project --ask in setup skills), then
show it again in full, in the form of .aid/runtime/templates/question-protocol.md.
If you are offering an open question again, show it under its recorded category and do not record it twice.
If you are not waiting on the user, end the turn without a question.
```

The record lines appear only when the record is what is missing. The last line gives the agent a way out for an
incidental closer ("anything else?"); it does not push a statement into a question.

### Fail-open, and limits

- Any error (bad stdin, unreadable transcript, no Python) prints `{}` and exits 0. A broken hook must never hold a
  session. `onFailure` has no effect on `Stop`, per the reference.
- A Windows machine without Git Bash runs the shell form in PowerShell, where the launcher cannot run: the hook
  fails open there. No PowerShell twin of the hook is built now (see Not in this round). The installer twin is built
  (part 2).
- When another Stop hook has already continued the turn (for example the chat waker, if the user installed it),
  `stop_hook_active` is true and this hook passes without checking. Accepted.

## 2. Installation (W7-14)

### What `aid add claude-code` writes

One handler, in its own matcher group, in the project's `.claude/settings.json` under `hooks.Stop`:

```json
{
  "hooks": [
    {
      "type": "command",
      "command": "bash \"${CLAUDE_PROJECT_DIR}/.aid/runtime/scripts/hooks/aid-question-form.sh\"",
      "timeout": 30
    }
  ]
}
```

- **Ownership.** A handler is AID's when its `command` holds `/.aid/runtime/scripts/hooks/aid-`. That is the `aid-`
  namespace for a file that has no markers. AID never touches another handler, group or key.
- **No machine path.** The command names only `${CLAUDE_PROJECT_DIR}`, so the committed file holds nothing
  machine-specific. That is the hazard `chat-node/scripts/hook-install.py` guards against for the chat hook.
- **Merge.** Parse the file; strip every AID handler from every `Stop` group; drop a group left empty by that; append
  the AID group; write back. Other keys keep their order and values. Output: UTF-8 without BOM, LF, 2-space indent,
  `": "` after keys, the file's own final-newline state kept. A run that changes nothing writes nothing.
- **Absent file.** Created holding only the hook. The manifest records that AID created it.
- **A file AID will not edit** (not parseable, not an object, `hooks` or `hooks.Stop` of the wrong type, a non-integer
  number, two keys differing only in case): left untouched, one warning line naming the file and the fix, nothing
  recorded, and the install goes on with exit 0. Both twins refuse the same files, so their output stays byte-equal.
- **No `python3`** on the Bash side: the same warning, nothing written, exit 0.
- **Output:** one line, `Hook: aid-question-form (Stop) in .claude/settings.json`.

`aid update` runs the same ensure step, so existing installs and this repo's dogfood get the hook too. A hook the
profile no longer declares is stripped by the same step.

### Removal

`aid remove claude-code` (`_uninstall_tool_v3`) strips every AID handler from `.claude/settings.json` before it drops
the tool from the manifest, by the manifest record and by the ownership marker both, so a manifest written by an
older CLI still gets a clean removal. When AID created the file and it is now `{}`, the file is deleted. User entries
stay.

### Profile, descriptor and manifest

| Layer | Change |
|---|---|
| `profiles/claude-code.toml` | a `[hooks]` table: `settings = ".claude/settings.json"`, `stop = ["aid-question-form"]` |
| `aid-tool.conf` (rendered) | `hook_settings=.claude/settings.json` and one `hook=Stop:aid-question-form` line per hook |
| `validate_release_descriptor` | `hook_settings` must be `<root>/settings.json`; `hook` must match `Stop:aid-<name>`, may repeat, and needs `hook_settings`. An older CLI ignores both keys (the reader has no default branch) |
| Manifest | under the tool, an additive list: `"hooks": [ { "event": "Stop", "name": "aid-question-form", "settings": ".claude/settings.json", "created": true } ]`. Model line `tools.<tool>.hook` with the four fields. `format_version` stays 3 (Open point 7) |

### Files that change

| File | Change |
|---|---|
| `lib/aid-install-core.sh` | `_ensure_host_hooks` and `_remove_host_hooks` (inline `python3`, as `_manifest_write_v3_python`); called from `install_shared` next to `_ensure_claude_md_region` (finalize and update-finalize) and from `_uninstall_tool_v3`; `validate_release_descriptor` keys; `_aid_build_install_model`, both manifest writers and the readers carry `tools.<tool>.hook` |
| `lib/AidInstallCore.psm1` | the twins `Invoke-EnsureHostHooks` and `Invoke-RemoveHostHooks`, native (no Python), with a JSON writer that matches the Bash output byte for byte; called from `Install-AidShared` and `Uninstall-AidToolV3`; the descriptor check; `Build-ManifestJson`, `Write-AidManifestV3` and the readers carry the hook list. Windows PowerShell 5.1 and ASCII-only (`coding-standards.md` F-01) |
| `bin/aid`, `bin/aid.ps1` | the `add` usage line says Claude Code also gets the AID Stop hook. No other change: `add`, `update` and `remove` already go through the core |
| `.claude/skills/generate-profile/scripts/aid_profile.py` | parse `[hooks]` into a `HooksConfig`; `validate`: hooks need `capabilities.hooks = true`, a settings path under the root dir, `aid-` names, and only `claude-code` may declare them for now |
| `.claude/skills/generate-profile/scripts/render.py` | `_descriptor` emits the two keys; `_self_test` checks them |
| `profiles/claude-code.toml`, `profiles/claude-code/aid-tool.conf` | the table, and the regenerated descriptor. `release.sh` `build_tool_artifact` packs that descriptor, so it must be regenerated before any staging |
| `.claude/skills/generate-profile/scripts/run_generator.py` | none: it re-renders every profile through `render_profile` and resyncs the dogfood through `sync_dogfood.py` |
| `chat-node/scripts/hook-install.py`, `chat-node/adapters/claude-code.mjs`, `bin/aid` `_cmd_chat_hook` | comments that say the product writes no host configuration are corrected; behaviour unchanged |

### The other three hook-capable profiles

Cursor, Copilot CLI and Antigravity declare `hooks = true` and get nothing now. A new backlog row, W7-37, carries the
question-form hook for them: Cursor's `.cursor/hooks.json` `stop` (it can submit the next message), Copilot's
`.github/hooks/aid-*.json` `agentStop`, and Antigravity after its hook model is researched (`external-sources.md`
§ Host agent-tool documentation).

## 3. Four targeted fixes, plus two subject names

| Fix | Change | Where |
|---|---|---|
| (a) 002-03 | When the project settles a value, the walk asks a confirmation (Rule 5.1) with no numbered options: "I'll keep `source_control` as `git`, because this folder is a git repository -- all right?" Settled means: `source_control` is `git` when `git rev-parse --is-inside-work-tree` succeeds (`svn` or `mercurial` when `.svn` or `.hg` is present); `type` is `brownfield` when source files exist outside `.aid/`. Nothing settles `none` or `greenfield`: those keep the numbered options | `canonical/skills/aid-config/SKILL.md` Mode 1 Step 3; the Suggestions table note |
| (b) 002-18 | The Fast path needs the user's own words to name both the data and the question. Data found on disk never makes the path Fast. When no question is named, INTAKE-ASK asks one, in the form, recorded with `--ask --design`: what the report should answer, recommending a question and naming the data it would read. More than one candidate data source, and none named: that is asked first, as its own question. One candidate is named in the recommendation, not asked (Rule 5.3) | `canonical/skills/aid-report/SKILL.md` § State: INTAKE step 2, § State: INTAKE-ASK |
| (b) general | "Starting at once skips only the go-ahead. The skill's own intake questions still come, in the form and recorded." | `canonical/aid/rules.md` § Handling a request (the closed-list bullet) |
| (c) 002-17 | A review never turns into a fix. During or after a review the agent offers no fix and asks no "fix now?" question. The one line naming `/aid-fix` is a statement. A fix starts only from the user's own new request, through its own confirmation | `canonical/aid/rules.md` § Handling a request; `canonical/skills/aid-review/SKILL.md` § Constraints |
| (c) root cause | Step 5 of the ad-hoc review no longer asks whether to apply the fixes: it reports findings and grade and ends with the `/aid-fix` statement line | `canonical/aid/templates/reviewer-ledger-schema.md` § Ad-hoc user-prompted reviews |
| (c) example | The follow-up example "fix them now?" becomes "shall I go on?", so the rule text no longer models a fix offer | `canonical/aid/rules.md` § Asking the user; `canonical/aid/templates/question-protocol.md` § One question |
| (d) 002-16 | A scoping question an earlier answer settles is not asked: it is recorded `--ask --design`, then `--answer --design --state Assumed` with the reason. A scoping question the user cannot answer ("I don't know") closes `Assumed`, with the assumption the research makes and why; the report names it under its gaps | `canonical/skills/aid-research/SKILL.md` § State: INTAKE-ASK |
| (e) hook subjects | The recovery confirmation's first line uses the subject `Recovery`; the cancel confirmation's uses `Cancel work` | `canonical/aid/templates/skill-steps.md` § Recovery; `canonical/skills/aid-orchestrate/references/start-or-resume.md` § 5. Cancel a named work |

## 4. The runner and the judge

The hook does not unsay a message: the withdrawn text stays in the turn, followed by the replacement. Today
`read_stream` joins every text block of a call, so the judge would see the withdrawn question and fail PC-10 on it.

| Change | Where |
|---|---|
| The agent env gets `AID_QUESTION_HOOK_LOG=<run folder>/hook.jsonl` (outside the fixture, so `files.diff` stays clean) | `tests/conversation/run.py` `run_once` |
| After each call, a text block that matches a logged blocked message (same text after trimming) is marked withdrawn, with the missing items | `read_stream`, `ClaudeCodeAgent.send` |
| `transcript.md` shows a withdrawn block under `[Withdrawn by the question-form hook -- missing: ...]`; the simulated user sees only the replacement | `render_transcript_md`, `ask_user` |
| The judge reads withdrawn text for Must-not items (publish, push, a fix offer, invented figures) and not for PC checks or question-shape items (MN on several questions); those are judged on the replacement | `tests/conversation/protocol-checks.md`, a new section "Messages the hook withdrew" |
| `hook.jsonl` is kept in the run folder; the docstring says so | `run.py` module docstring |

Open point 3 asks the maintainer to confirm this judging rule.

## 5. Tests

| Suite | Cases |
|---|---|
| `tests/canonical/test-question-form-hook.sh` (new; `# COVERS: canonical/aid/scripts/hooks/`) | builds its own stdin and transcript fixtures. QF-01 formed and recorded: pass. QF-02 to QF-05 each of F1 to F4 missing: block naming it. QF-06 no `--ask`: block naming the record. QF-07 `--ask --design` and `--project --ask`: pass. QF-08 `--ask` only in an earlier turn: block. QF-09 a report with no question: pass. QF-10 `stop_hook_active`: pass on a bad message. QF-11 break offer: pass. QF-12 subjects `Recovery` and `Cancel work`: pass with no record; any other subject after a `--check` in the turn, with no record: block. QF-13 a re-worded re-offer whose subject is the category of a `Skipped` entry in `.aid/STATE.yml`, and one whose question line matches the entry's `context`: pass; the same message with no open entry: block, and the reason says not to record twice. QF-14 KB question with an Edit on `.aid/knowledge/STATE.md`: pass. QF-15 ticket skill most recent: pass with no record. QF-16 `?` only inside a code fence: pass. QF-17 bad stdin, missing transcript, no Python on `PATH`: `{}`, exit 0. QF-18 kill switch. QF-19 no `last_assistant_message`: the transcript fallback. QF-20 the log line is written on a block only. QF-21 the block output is one JSON object, exit 0 |
| `tests/canonical/test-host-hooks.sh` (new; `# COVERS: lib/aid-install-core.sh`, `profiles/`, `bin/aid`) | through `bin/aid add/update/remove --from-bundle` in temp targets. HH-01 fresh target: the file created with the AID group only; the manifest record with `created: true`. HH-02 a file with user keys and a user Stop hook: kept, AID group appended; a second `add` and an `update` change no byte. HH-03 an unreadable file: untouched, warning, exit 0, no record. HH-04 `remove`: AID handler gone, user hook kept; a created file left as `{}` deleted. HH-05 record missing but marker present: still stripped. HH-06 `add cursor`, `add codex`: no settings file. HH-07 `update` on an install without the hook adds it. HH-08 no `python3`: warning, exit 0. HH-09 bad `hook=` and `hook_settings=` descriptors refused |
| `tests/canonical/test-aid-cli-ps1.sh`, `test-aid-cli-parity.sh` | HH-01, HH-02, HH-04 through `bin/aid.ps1`; a parity case comparing the bytes both twins write for the same input (nesting, booleans, null, Unicode, escapes) |
| `tests/canonical/test-install-parity.sh` PAR14 | the two new twin pairs added to its list |
| `tests/canonical/test-release-staging-descriptors.sh` | a descriptor with the hook keys is accepted; malformed ones refused |
| `tests/windows/Test-AidInstaller.ps1` | Q126: `add claude-code` writes the hook; `remove` takes it out |
| `tests/canonical/test-skill-steps.sh` group S | static checks for fixes (a) to (e): the ad-hoc review offers no fix; `rules.md` carries the no-fix and the intake lines; the `aid-config` confirmation rule; the `aid-report` Fast-path condition; the `aid-research` `Assumed` lines; the two subjects |
| `.github/workflows/installer-tests.yml` `SUITES` | add `test-host-hooks`. The hook suite is not platform-sensitive; it runs in `tests/run-all.sh` with the rest |

Tests build their own fixtures; none reads a work folder.

## 6. How it runs

Five Sonnet builders in parallel, on disjoint files (Q141), in worktrees, then one more for the Knowledge Base. The
contracts they share are fixed above: the command string and marker, the descriptor keys, the manifest model line,
the JSON output rules, the two subjects and the log line.

| Builder | Files |
|---|---|
| B1 Hook | `canonical/aid/scripts/hooks/*`; `tests/canonical/test-question-form-hook.sh` |
| B2 Installer, Bash and generator | `lib/aid-install-core.sh`; `bin/aid`; `aid_profile.py`; `render.py`; `profiles/claude-code.toml` and its regenerated `aid-tool.conf`; `test-host-hooks.sh`; `test-release-staging-descriptors.sh`; `installer-tests.yml`; the `chat-node` comments |
| B3 Installer, PowerShell | `lib/AidInstallCore.psm1`; `bin/aid.ps1`; `test-aid-cli-ps1.sh`; `test-aid-cli-parity.sh`; `test-install-parity.sh`; `tests/windows/Test-AidInstaller.ps1` |
| B4 Runner and judge | `tests/conversation/run.py`; `tests/conversation/protocol-checks.md` |
| B5 Targeted fixes | `aid-config`, `aid-report`, `aid-research`, `aid-review` SKILL.md; `rules.md`; `question-protocol.md`; `reviewer-ledger-schema.md`; `skill-steps.md`; `start-or-resume.md`; `test-skill-steps.sh` |
| B6 Knowledge Base and docs (after B1 to B5) | the docs in part 7 |

Then, in order:

1. Tests: the suites that assert changed text, then `HOME="$(mktemp -d)" bash tests/run-all.sh`, then the site tests.
2. One Opus review of the round's diff, one fix round, one verify (Q166). A recurred row or a new HIGH or CRITICAL gets
   one more fix and verify; new MEDIUM and LOW rows go to the backlog as OOS.
3. Resync, committed alone: `python3 .claude/skills/generate-profile/scripts/run_generator.py`. Through
   `sync_dogfood.py` it runs `aid update` on this repo, which adds the hook to this repo's `.claude/settings.json`
   (Open point 4). Push `work-003`; installer CI must be green.
4. The maintainer runs `/reload-skills`. Hook edits are picked up by Claude Code's file watcher.
5. **Smoke runs** on the maintainer's machine: one run of each of the 9 samples, four at a time:
   `python3 tests/conversation/run.py --feature 002 --sample <id> --runs 1`. The 2 that pass today are included,
   because the hook now touches every sample.
6. Iterate only on what fails: read its ledger and `hook.jsonl`, fix, resync, re-run that sample once. After two
   iterations with no progress on the same sample, stop and ask the maintainer.
7. **Final check:** all 9 samples, 3 runs each. All 27 pass: gate report attempt 4, then close through the writer as
   in `delivery-003-gate-handoff.md` § What is left, step 4. Any failure: back to step 6.

Every step goes into `STATE.yml` history as it happens. The approval of this design is recorded as a question first.

### If a smoke run still fails

Designed now, built only if the smoke runs show the failure.

| Failure | Candidate fix |
|---|---|
| 002-19: a question asked by hand before `/aid-monitor` starts | `rules.md`: "A skill that starts at once asks its own questions inside its run; ask nothing before starting it." |
| 002-04: no `aid-set-connector` call | `rules.md`: "An open question left by an earlier run is offered by the skill that asked it (its `asked_by`)." |
| 002-14: no `aid-orchestrate` call | diagnose from the ledger; the rule already sends such a request through `/aid-orchestrate` |
| The hook blocks a message that asks nothing | tighten the detection in `aid-question-form.py`, add the case to the hook suite |

## 7. Knowledge Base impact

No work id is written in any of these.

| Doc | What becomes false or must be stated |
|---|---|
| `backlog.md` | W7-14 leaves `## Prioritized` and moves, same id, to `## Next Release` as `[NEW]`, with its done-when restated: the hook installs, is recorded in the manifest and is removed with its tool; `test-question-form-hook.sh` and `test-host-hooks.sh` pass. The backlog's own gotchas say an item is moved, never deleted, and is drained into `release-tracking.md` at the tag. New row W7-37 in `## Prioritized`: the hook for Cursor, Copilot CLI and Antigravity |
| `authoring-conventions.md` | G-13 forbids AID content at a tool root outside `agents/` or `skills/`; § Content Isolation red-flags writing outside AID markers in a host file. Both gain the one exception (Open point 1) |
| `capability-inventory.md` | "`aid chat hook --install` is the only command in the product that writes a host tool's configuration" becomes false; `aid add` and `aid update` for Claude Code write the project hook |
| `module-map.md` | the `chat-node/scripts/hook-install.py` row's "The only writer of host configuration in the product" becomes false; a row for `canonical/aid/scripts/hooks/`; the `canonical/aid/scripts/*` area list gains `hooks` |
| `architecture.md` | § Data Flow, install flow: the core also places the Claude Code project hook and records it; § Invariants: AID edits only its own handlers in a host settings file |
| `artifact-schemas.md` | the manifest shape gains `tools.<tool>.hooks`; its frontmatter criterion on the manifest shape names it |
| `external-sources.md` | a row for the Claude Code hooks reference (the contract table above, read 2026-10-21); the paragraph saying Claude Code is not catalogued and its harness claims are unsourced becomes false and is rewritten |
| `integration-map.md` | the host-tools notes: Claude Code runs the AID Stop hook from project settings, and `-p` runs trust them |
| `decisions.md` | D34: one project-scoped hook entry in Claude Code's settings. Why: the rule text alone survived two rounds; the runner loads project settings only; the command holds no machine path. Rejected: `settings.local.json` (per machine, not loaded by the samples), user scope (not per project), wording only |
| `project-structure.md` | `canonical/aid/scripts/hooks/` and `.aid/runtime/scripts/hooks/`; `.claude/settings.json` now carries the AID Stop hook |
| `test-landscape.md` | the two new suites, the `SUITES` entry, and the runner's `hook.jsonl` |
| `tech-debt.md` | the hook fails open on Windows without Git Bash |
| `INDEX.md` | regenerated with `build-kb-index.sh` if a frontmatter field changes |

Outside the Knowledge Base: `README.md` § Install and `docs/aid-methodology.md` § 10. Adoption Guide say what
`aid add claude-code` writes; the site's synced docs follow.

## Not in this round

- `aid status` does not report the hook.
- No setting in `.aid/settings.yml` to turn the hook off; the environment kill switch only (Open point 6).
- No PowerShell twin of the hook script.
- No hook for the other three profiles (W7-37).

## Open points

Each is one question for the maintainer, most important first, with my recommendation.

1. **Knowledge Base conflict.** Installing the hook makes three KB statements false. `authoring-conventions.md` G-13:
   "No AID-own content is placed at the root level of a tool directory (for example `.codex/`) outside that tool's
   `agents/` or `skills/` subtree". The § Content Isolation red flag: "writing outside the AID:BEGIN/END region in a
   host file". `capability-inventory.md`: "`aid chat hook --install` is the only command in the product that writes a
   host tool's configuration". **Recommendation:** amend them in this round. The exception: a host settings file may
   hold AID handlers that run a script under `.aid/runtime/scripts/hooks/aid-*`, recorded in the manifest and removed
   with the tool. The host reads hooks only from its settings files, and the script itself stays under the runtime
   (G-10, G-11 hold).
2. **Settings scope.** **Recommendation:** the project `.claude/settings.json`. The runner loads only project
   settings, the file travels with the repo like the `CLAUDE.md` region, and the command holds no machine path.
   `.claude/settings.local.json` is per machine and the samples would never exercise it.
3. **Judging a withdrawn message.** **Recommendation:** as part 4. The runner marks it; PC checks judge the
   replacement; Must-not items judge both; the simulated user sees the replacement only. Without this, the hook
   cannot make PC-10 pass, because the withdrawn text stays in the turn.
4. **Dogfood.** The resync adds the hook to this repo's tracked `.claude/settings.json`, so the maintainer's own
   sessions here get it. **Recommendation:** accept it; `AID_QUESTION_HOOK=off` at launch turns it off for one
   session.
5. **Block shape.** **Recommendation:** `decision: "block"`, the long-standing shape the chat waker already uses.
   `hookSpecificOutput.additionalContext` shows no "hook error" label, but it is newer; switch only if the smoke runs
   show the label confuses the flow.
6. **Opt-out.** **Recommendation:** no settings key now; the kill switch only. A backlog row if a user asks for one.
7. **Manifest format.** **Recommendation:** an additive `hooks` list under the tool, `format_version` stays 3. Older
   CLIs ignore it, and removal also sweeps by marker. A format bump would need a migration step for one optional key.
8. **Settled values in `aid-config`.** **Recommendation:** a confirmation, as Q181 says. The alternative, recording
   them `Assumed` and not asking, would change the walk's question count that 002-02 and 002-03 already pass with.
9. **Smoke scope.** **Recommendation:** smoke all 9 samples once, not only the 7 failing, because the hook changes
   every sample's flow.
