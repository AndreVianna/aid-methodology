# Claude Code handoff — delivery-003

## Owner instruction and stop boundary

The owner stopped Codex work to conserve the weekly limit and requested: pause the
tasks, push everything, prepare this handoff, and provide a prompt for Claude Code.
This push saves unfinished work; it is not delivery approval or permission to merge.
No new tests or model requests were started after the pause instruction.

The pipeline is `Paused-Awaiting-Input`, at `aid-execute / DELIVERY-GATE`.
The tasks are already Done; delivery-003 itself remains incomplete and its grade is
Pending. The recurring `finish-delivery-003-gate` automation was deleted earlier;
all subagents are completed and the private Codex TUI was closed with exit 0.
Do not restart background work merely because this file is read.

When the owner pastes the resumption prompt, continue delivery-003 before later
deliveries or the wider process review. Use Claude's allowance for offline work.
**Codex-backed probes and the strict acceptance batch still consume the owner's
Codex limit: obtain confirmation of budget/timing before launching those calls.**
Do not silently replace the Codex acceptance host/model with Claude to avoid that
cost. The acceptance bar remains unchanged.

## Workspace and current commits

- Authoritative repository: `C:\Projects\AID`, branch `work-003`.
- Remote: `https://github.com/AndreVianna/aid-methodology.git`, branch `work-003`.
- Work: `.aid/works/work-003-full-aid-restructure/`.
- Read `.aid/runtime/rules.md`, the current `STATE.yml`, relevant KB and review
  criteria before acting. Follow the existing work; do not allocate another one.
- Original live WSL checkout: `/home/andre/projects/aid`, HEAD `86b797a1` with local
  edits. **Never reset, stash, or overwrite it to align commits.** Test checkouts
  are independent own-Git copies under its `.aid/.temp/`.

| Commit | Meaning |
|---|---|
| `e29c5211e538542392949b5f6a4f3167283acd21` | Research/question source corrections |
| `119c9d06f0b16a2b1effa7a201254bc934ed9283` | Isolated resync |
| `c1ddd874ce39882cc43482a61eb0eeec631a210d` | Connector follow-ups, LF policy and fixture corrections |
| `d6cfb5f7bf0d2abc1f8a7061fe45bfbe0a945cce` | Isolated resync; earlier formal validation identity |
| `c12a0716f343464343528c180aec794d5fd1829c` | Earlier tested generated site outputs |
| `d587ae1f85958e340856eb58691ecfc4244bd63c` | Passive raw conversation capture and coverage corrections |
| `2597aafd74d33fa3c5a03f1b2cf7e2789df7aa41` | Isolated diagnostic resync |
| `67a7882c71d4736bb4d7f270b6449175b71c824e` | Complete mkdir and question-record recipes |
| `34f54b72619cede492f96fe10dffceaf482a32b6` | **Last resync-relevant commit and current measured source identity** |
| `0af277dce6eac7bce0b9b78d722abcb9ac0f0bc4` | Current 70 tested generated outputs and work bookkeeping |
| `fcea6852e4097dd57af2e2fa9fadca6d499de144` | Executed coverage/cost baseline refresh and current report |
| `390582cbd8dc329c8c0d6af1abd5444fbda33424` | Recorded scope question before its approval |

The handoff commit contains this file and the latest paused STATE. Identify its
hash with `git log -1`; no self-referential commit hash is embedded here.

## Immediate next work: approved, but barely started

**Q190 is Answered `1`.** The owner approved
`analysis/delivery-003-codex-guard-proposal.md`, under **Proposed work**:

1. Prove exact Linux Codex 0.164 native hook loading, trust, event payloads,
   explicit denial, continuation and error behavior in a disposable project.
2. Establish which checks can actually prevent creation without the required
   folder, continuation after a failed record write, or record/display mismatch.
3. Integrate only proven checks, with namespaced runtime scripts and full
   install/update/manifest/remove support. Do not bypass trust, rewrite tool
   arguments, create missing records, repair failed writes, or retry for the model.
4. Independently review, resync, and run the unchanged strict gate. Preserve every
   original event and visible message; a later correction does not erase a failure.

Do not ask again for the scope approval. The latest pause concerns execution and
budget, not withdrawal of Q190. No product guard has been implemented.

### Exact native probe stop point

Private base:
`/home/andre/projects/aid/.aid/.temp/native-hooks-32598dd89dd64cd2959c549638a6a109`

- `repo/`: empty own-Git probe repository; not the product checkout.
- `repo/.codex/hooks.json`: four diagnostic hooks, SessionStart / PreToolUse /
  PostToolUse / Stop, all calling one private Python handler with a two-second
  timeout. Definition SHA256:
  `2738dd7b0d5ce431683358b531683741aee43c19279c6bfdd82467f1b1cb38e8`.
- Handler: `repo/.aid/runtime/scripts/hooks/aid-native-probe.py`, SHA256
  `3cbbd2c983b77c303e84295b4d87ed3266368953bcd6e3f6cad89523fed46af5`.
- `mode.txt` is `observe`; other prepared toy modes are `stop-once`,
  `malformed-pre`, and `timeout-pre`. These are diagnostic controls, not a shipped
  design or acceptance-run coaching.
- Standard CLI folder trust was approved, then the native hook review UI was
  opened. The command/source were inspected and the four exact definitions were
  trusted through that UI; it displayed Active 1 for each installed event.
  **No bypass flag, preseeded trust hash, or global user configuration was used.**
- `trust-tui.log` records the native UI. No behavioral prompt was submitted and
  no `events.jsonl` was created. **No hook execution, denial, continuation or
  fail-closed property is proved yet.** Do not promote trusted UI status to a pass.
- The TUI was closed on the owner's pause request. Its disposable copied
  `home/.codex/auth.json` was removed; original authentication is untouched.
  Restore test authentication privately only if later Codex calls are authorized;
  never print or commit its contents.
- A portable copy of the preparation helper and probe metadata is in the evidence
  packet. The helper creates a new private fixture, rather than resuming this one.

Read `delivery-003-codex-guard-integration-notes.md` in the packet. Current
`profiles/codex.toml` declares hooks false. Existing schema, renderer and both
installer twins are Claude-Stop-specific: simply flipping the capability or
copying the Claude handler is invalid. The existing checker does not prove
successful-write correlation, failed-write stop behavior or Codex record equality.
G-13 allows a namespaced handler in host settings only with manifest ownership
and removal; unrelated feature/trust keys are not automatically permitted.

Official contract: <https://learn.chatgpt.com/docs/hooks>. Stop requests
continuation, not proven withdrawal of an already visible message. Hook errors
can leave calls unblocked, some tool paths opt out, and transcript format is not
stable. The exact installed Linux CLI is 0.164.0; this proves no Windows or older
version compatibility. Do not upgrade the CLI/model silently.

## Why delivery-003 is still open

The strict full batch has **never passed**. Attempts 1–11 and focused failures
remain preserved. Strict attempt 11 stopped after 14 passes at sample014/run3
because a same-issue follow-up renamed its group. Later focused attempts exposed
scope intake before choice, wrong answer flags, missing mkdir, failed-write
retries, missing chronology and substantive record/display mismatch.

The latest default-profile focused014 batch,
`20261024T202557Z-codex-user-codex-judge-codex-147593`, reports completed/passed 3/3.
Independent actual audit **rejects acceptance**: runs1/3 omit mkdir and halt after
creation fails; run2 retries the failed write and omits a recorded confirmation
condition in its display. All loaded the complete current recipe.

A controlled same-source Astra diagnostic passed one trial, then failed scope
ordering. It did not authorize a new final profile. Default-session metadata
selects `gpt-6.1-sol` with effort null/unset; Astra also had effort null. No
low-effort cause, missing source rule, or categorical host instruction conflict
was established. Do not continue speculative wording edits for actor noncompliance.

Other limits to preserve:

- Research focused3 was judged 3/3, but manual EO4 found no explicit statement
  that the choice belongs to the user. PRESENT now requires it; fresh strict016
  actual evidence is still owed. Do not close its Pending behavioral row early.
- Historical014 routing success did not prove setup or repair: it omitted mkdir
  and truthfully halted; MEDIUM OOS and unproven executor cwd remain recorded.
- Passive raw capture preserves each successfully returned main Codex stdout
  before parsing, in `codex-raw/turn-NNN.jsonl`. It changes no prompts, normalized
  events or judgments. CLI nonzero/timeout before stdout return has no raw artifact.
  The older discarded chronology cannot be reconstructed from final diffs alone.
- Tracker MCP is a closed read-only fixture for the two-trackers main Codex agent
  only. Helpers/default fixtures remain disconnected; actual prior015 Jira calls
  and unavailable results were checked. Keep account apps/web/config isolated.

## Validated local preparation — do not repeat without a new reason

Measured source identity is `34f54b726`; later generated/bookkeeping and baseline
commits do not constitute a fresh execution at a different source identity.

| Component | Actual result |
|---|---|
| Official canonical run | 178/178, exit0, 560.20 seconds, unchanged timeouts |
| Full site, after canonical in separate clone | 50 files / 2,822 tests, exit0 |
| Scratch generator/install parity | exit0; all 3,513 tracked raw files and modes unchanged, including manifest |
| Official separate coverage collection | all178; exit0; 11,129 keys / 13,536 emissions, 178 logs |
| Real optional Playwright-absent cohort | 26/26; required runtimes retained |
| Native Windows remote cohort | 50/50, no skips; no source overlay |
| Actual rg-absent harvest cohort | 5/5; positive native-rg evidence retained |
| Audited MAX4 executed coverage | 11,135 keys / 13,542 emissions; historical diff0, 21 rehomes, zero accepted-removal use, 1,174 additions |
| Passive raw offline runner | 279/0 |

Coverage union SHA256:
`c0e3aa5eb511f9f8a5041074eb940fa170fa27eafc93517018c6c8f706f4d1ed`.
Every normalized raw log observation was independently matched to its official
inventory; MAX counts are used, never SUM or old unexecuted rows. Initial standalone
and MAX3 failures remain preserved. The skip report has four platform notices and
20 real placeholder labels; CPG08 is an executed normalizer test, not a runtime skip.

All four coverage/cost baseline TSV/meta files were guardedly re-recorded and
independently verified, with original files and historical comparisons preserved.
Cost has 645 keys; always-on falls 569 characters (54,546 → 53,977), but 81 metrics
grow. **Historical cost diff remains exit1 at zero tolerance.** No tolerance or
accepted-removal change was made; a new baseline is not a historical no-growth pass.
Cost metrics overlap and must not be summed as independent source bytes.

The complete verified project-local runtime and native Windows prerequisites
already exist. No system/home/sudo install is needed. Runtime/provenance metadata
and exact paths are in the local formal3 and complete-validation-env files.
The unchanged cost collector requires the documented relative-root API workaround:
an absolute root beneath ancestor `.aid` incorrectly omits 81 rows. Final capture
used all645; never accept the truncated564-row inventory.

## Binding remaining acceptance and closure

All ten samples require three fresh successful runs each, all roles Codex:

```bash
PATH=/home/andre/.local/bin:/usr/local/bin:/usr/bin:/bin \
PYTHONDONTWRITEBYTECODE=1 /usr/bin/python3 tests/conversation/run.py --feature 002 \
  --sample 002-01-connector-question \
  --sample 002-02-settings-groups-and-breaks \
  --sample 002-03-follow-up-and-skip-answered \
  --sample 002-04-skip-then-another-user \
  --sample 002-14-orchestrate-unsure-reading \
  --sample 002-15-which-tracker \
  --sample 002-16-research-without-a-question \
  --sample 002-17-review-publish-approval \
  --sample 002-18-report-what-to-analyze \
  --sample 002-19-monitor-finding-question \
  --hosts codex --user-host codex --judge-host codex --runs 3 --fail-fast
```

Do not run it until Codex budget/timing is confirmed. Do not substitute all22:
006–013 are deferred; 005/020/021/021b belong elsewhere. A stopped-early,
completed-false, passed-false summary is failed/incomplete, not an active job.
Inspect actual reasons, ledger, checks, ordered transcript, raw streams and diff;
empty judge ledgers alone are insufficient. No cherry-picking, assertion weakening,
hidden writes or missing-evidence acceptance. Manually audit fresh016 EO4.

After a proven source change: independent review, source commit, isolated resync,
fresh installed-instruction verification and necessary final exact-candidate
validation. Q150 permits the same-session resync/fresh-CLI exception; do not ask for
reload approval again. Q142 task floor C-, Q143 delivery verification A,
Q184 historical verify waiver and Q180/186/189 strict bar remain recorded.

The requested save push does not close the gate. Installer CI must eventually be
green on the actual final commit, including required native Windows coverage.
Do not infer that result from earlier CI or local remote tests. Never merge.

## Evidence and state operations

Tracked portable packet: `analysis/claude-code-handoff-evidence/`, indexed by
`index.json` with original paths, byte sizes and SHA256. It contains selected actual
component metadata, review ledgers, integration notes and the unfinished native
probe helper. No authentication or disposable runtime is included.

Full local raw captures/logs remain in
`C:\Projects\AID\.aid\.temp\runner-codex-checks\` and ledgers in
`.aid/.temp/review-pending/`. Key sets are `formal3-*`,
`delivery-003-recipe-focused-evidence`, `delivery-003-model-comparison-evidence`,
`delivery-003-014-group-contract.md`, and `delivery-003-research-focused-verdict.md`.
These ignored files are available on this machine, not supplied by a Git clone.
If absent elsewhere, do not pretend the summaries replace missing raw evidence.

The complete current report is `analysis/delivery-003-gate.md`; its lower historical
approval is explicitly superseded. Use the current Pending header.

In PowerShell, record the resume and subsequent transitions through the writer:

```powershell
$env:AID_STATE_FILE='.aid/works/work-003-full-aid-restructure/STATE.yml'
$env:AID_WORK_DIR='.aid/works/work-003-full-aid-restructure'
& 'C:/Program Files/Git/bin/bash.exe' canonical/aid/scripts/execute/writeback-state.sh `
  --pipeline --field Lifecycle --value Running
& 'C:/Program Files/Git/bin/bash.exe' canonical/aid/scripts/execute/writeback-state.sh `
  --step --skill aid-execute --name DELIVERY-GATE --detail 'Your exact next action'
```

Honor the pause until the receiving owner prompt authorizes resumption. Preserve
unrelated edits and do not restart automations or spend Codex allowance by default.
