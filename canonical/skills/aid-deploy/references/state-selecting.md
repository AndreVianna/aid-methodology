# State: SELECTING

Eligible deliveries are presented to the user for inclusion in this release; a package file is created.

**Who asks.** This step runs in the main conversation (inline), because it puts questions to the user; a worker never asks. It uses what IDLE gathered (the eligible deliveries and the knowledge-base facts).

### Step 2: Select Deliveries

Present eligible deliveries to the user:

```
Ready to ship:
  ✅ delivery-001: User Authentication (4 tasks, all A or above)
  ✅ delivery-002: API Rate Limiting (3 tasks, all A-)

Already shipped:
  📦 delivery-003: Core Models (in package-001-mvp)

Not ready:
  ⏳ delivery-004: Reporting Dashboard (2/5 tasks complete)

Which deliveries should be in this release? [all ready / select / cancel]
```

If user selects "all ready" → include all eligible.
If user selects specific ones → include only those.
If user cancels → reset work `STATE.md` `## Deploy State` to Idle. No package file is written, and the run ends (the advance line below).

Ask for:
- Version/tag name (suggest based on versioning scheme from KB)
- Package name slug (for the filename: `package-NNN-{slug}.md`)
- Only when infrastructure.md has no Deployment section or its project type is unclear: how the
  project gets packaged and deployed (build output, target, environment). Ask it through the question
  protocol (`.aid/runtime/templates/question-protocol.md`), so the answer is recorded in the work's
  `STATE.yml` `qa`. Asked in this same exchange, so the question is answered before PACKAGING needs it.

Create the package file from template (`../../../aid/templates/package.md`):
- Fill in: deliveries, deployment type/target from KB, environment from KB
- Determine package number (next sequential after existing packages)
- Save to `.aid/works/{work}/packages/package-NNN-{slug}.md`

Update work `STATE.md` `## Deploy State`: Status → Verifying, Active Package → package-NNN.

The questions above are blocking: this step pauses on them until they are answered, and then carries on
through the package file and the status update.

**Advance:** **CHAIN** → [State: VERIFYING] once the user has chosen the deliveries, given the version and package name, and answered any packaging question; **HALT** when the user cancels.
