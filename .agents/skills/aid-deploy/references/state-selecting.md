# State: SELECTING

Eligible deliveries are presented to the user for inclusion in this release; a package file is created.

**Who asks.** This step runs in the main conversation (inline), because it puts questions to the user; a worker never asks. It uses what IDLE gathered (the eligible deliveries and the knowledge-base facts).

### Step 2: Select Deliveries

Show the eligible deliveries to the user as a plain summary (no question in it):

```
Ready to ship:
  ✅ delivery-001: User Authentication (4 tasks, all A or above)
  ✅ delivery-002: API Rate Limiting (3 tasks, all A-)

Already shipped:
  📦 delivery-003: Core Models (in package-001-mvp)

Not ready:
  ⏳ delivery-004: Reporting Dashboard (2/5 tasks complete)
```

Then ask the questions below one at a time, each in its own message, through the question protocol
(`.aid/runtime/templates/question-protocol.md`): one topic per message, the question form with **Why I
ask** and **My recommendation**, never the host tool's question picker. Every one of them blocks the work, so
this step pauses on each as part 3 of the step procedure says. Before showing a question, record it in the
work's `qa` with `bash .aid/runtime/scripts/execute/writeback-state.sh --ask --category Release --impact <High|Medium|Low> --context '<the question, as shown>' --suggested '<the recommendation>' --asked-by aid-deploy --step SELECTING` (it prints the question's id), bring the step detail
up to date with `--step`, and set the lifecycle to `Paused-Awaiting-Input` and the pause reason to the open
question through the writer. When the user answers, record the answer with `--answer --id <id> --state
<Answered|Skipped> --value '<the answer>' --applied-to '<what it changed>'`, set the lifecycle back to
`Running`, and ask the next question.

1. **Which deliveries go in this release** (importance: high). Recommend all the ready ones, and offer
   to pick a subset or to cancel the release.
   - "All ready" includes every eligible delivery; specific ones include only those.
   - If the user cancels: reset the work `STATE.yml` Deploy State (`deploy` key) to Idle. No package file is written. Set the lifecycle to
     `Paused-Awaiting-Input` and the pause reason to 'Release selection canceled; no package was written'
     through the writer, and the run ends (the advance line below).
2. **The version or tag name** (importance: medium). Recommend one from the versioning scheme in the KB.
3. **The package name slug** (importance: low), for the filename `package-NNN-{slug}.md`. Recommend one
   from the release's content.
4. **How the project is packaged and deployed** (importance: medium; build output, target, environment),
   asked only when infrastructure.md has no Deployment section or its project type is unclear. It is asked
   here so the answer is in hand before PACKAGING needs it.

Create the package file from template (`../../../aid/templates/package.md`) once the questions are answered:
- Fill in: deliveries, deployment type/target from KB, environment from KB
- Determine package number (next sequential after existing packages)
- Save to `.aid/works/{work}/packages/package-NNN-{slug}.md`

Update work `STATE.yml` Deploy State (`deploy` key): Status → Verifying, Active Package → package-NNN.

The questions are blocking: this step pauses on them until they are answered, and then carries on
through the package file and the status update.

**Advance:** **CHAIN** → [State: VERIFYING] once the user has chosen the deliveries, given the version and package name, and answered any packaging question; **HALT** when the user cancels.
