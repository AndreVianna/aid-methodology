# State: COLLECT

Gather project metadata through a short conversational interview (6 questions).

> ```
> aid-init  ▸ you are here
>   [✓ PRE-FLIGHT] → [● COLLECT ] → [ SCAFFOLD ] → [ META-DOCS ] → [ SETUP ] → [ DONE ]
> ```

Ask these questions **one at a time**. Wait for each answer before asking the next.

### Q1: Project Type

```
Is this a greenfield (new) or brownfield (existing codebase) project?

[1] Brownfield — existing code to analyze
[2] Greenfield — starting from scratch
```

Store the answer. This determines the workflow path.

### Q2: Project Name

```
What's the project name? (used in KB headers and INDEX.md)
```

If the project has a `package.json`, `*.csproj`, `pom.xml`, `Cargo.toml`, `pyproject.toml`,
or similar manifest, suggest the name found there. The user confirms or overrides.

### Q3: Brief Description

Before asking, scan for a description in common manifest files:
- `pom.xml` → `<description>` tag
- `*.csproj` → `<Description>` tag
- `package.json` → `"description"` field
- `Cargo.toml` → `description` field under `[package]`
- `pyproject.toml` → `description` field
- `*.gradle` or `build.gradle.kts` → `description` property
- `README.md` → first non-heading paragraph (fallback)

If a description is found, suggest it:
```
One-line description of what this project does:
(suggestion: "{description found in manifest}")

[y] to accept, or type your own:
```

If nothing is found, ask plainly:
```
One-line description of what this project does:
```

### Q4: External Documentation (if any)

```
Do you have documentation outside this repository that should be considered?
(architecture docs, wiki exports, design documents, Confluence pages, etc.)

Provide file or directory paths separated by commas, or type [n] to skip.
```

If paths are provided:
- Verify each path is accessible: `test -r <path>`
- Report status for each:
  ```
  ✅ /path/to/docs — accessible (directory, 23 files)
  ❌ /path/to/wiki — not accessible
  ```
- Ask if they want to continue without inaccessible paths
- Store accessible paths

### Q5: Minimum Grade

```
What minimum quality grade should the Knowledge Base meet before proceeding?
(A+ through F)

[A] to accept the default, or type a different grade:
```

Parse and validate the grade. Store it.

### Q6: Heartbeat Interval (for long-running subagent dispatches)

```
How often should long-running subagents report progress?
(Per `canonical/templates/subagent-heartbeat-protocol.md` — applies when
a dispatched subagent's ETA exceeds 5 min)

[1] 1 minute (default — strong signal, minimal noise)
[2] 2 minutes (lighter signal)
[3] 5 minutes (very light — for noise-sensitive sessions)
[4] 0 (disable heartbeat entirely; subagents won't self-report)
```

Store the answer as a number of minutes (1, 2, 5, or 0). Written to
`STATE.md` top-of-file as `**Heartbeat Interval:** N minutes` (or `0` to
disable). Dispatchers read this value before dispatching long-running
subagents and pass `HEARTBEAT_INTERVAL=Nm` to the subagent prompt.

### Q7: Commit the AID Workspace?

The `.aid/` directory holds the Knowledge Base and all AID work artifacts. Ask
the user whether Git should track it. Phrase the question exactly like this:

```
Should the AID workspace — the `.aid/` folder, which holds the Knowledge Base
and all AID work artifacts — be committed to this project's Git repository?

[1] Yes, commit it — Git tracks `.aid/`. The Knowledge Base is versioned
    alongside the code and shared with everyone who clones the repository.
[2] No, keep it local — AID adds `.aid/` to `.gitignore`, so the workspace
    stays on your machine and is never committed or pushed.
```

Store the answer. It controls the `.gitignore` step in Step 4.

**Advance:** Next state is `SCAFFOLD` — when this state's work completes, router prints `Next: [State: SCAFFOLD] — run /aid-init again` and exits.
