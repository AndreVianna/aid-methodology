---
name: aid-init
description: >
  Initialize an AID project. Asks greenfield or brownfield, collects project metadata,
  external documentation paths, and scaffolds the .aid/ directory structure.
  Sets up {project_context_file} with placeholders. Run once at project start — before
  aid-discover (brownfield) or aid-interview (greenfield).
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
argument-hint: "[--reset] clear existing .aid/ and re-initialize"
---

# AID Project Initialization

Set up a project for the AID methodology. Collects essential metadata, scaffolds the
workspace, and determines the workflow path. Run this once before any other AID phase.

**This is a conversational skill — it asks questions and waits for answers.**

**Workspace structure:**
```
{ProjectFolder}/
  AGENTS.md
  .aid/
    knowledge/
      STATE.md
      (...16 KB docs, INDEX.md, README.md)
```

Works and features are created later by `/aid-interview`.

---

## Pre-flight Checks

> **[State: PRE-FLIGHT] — Verify mode and check for an existing workspace before collecting any input.**
>
> ```
> aid-init  ▸ you are here
>   [● PRE-FLIGHT] → [ COLLECT ] → [ SCAFFOLD ] → [ META-DOCS ] → [ SETUP ] → [ DONE ]
> ```

### Check 0: Verify Not in Plan Mode

- ✅ `Default` or `Auto-accept edits` → Proceed
- ❌ `Plan mode` → STOP. Tell user to switch. Init creates files — Plan mode will block all writes.

### Check 1: Existing Workspace

1. Check if `.aid/` already exists with content:
   - If `.aid/` exists AND contains non-empty `.md` files AND `--reset` was NOT passed:
     ```
     ⚠️ This project already has an AID workspace with content.
     Re-running init will overwrite the KB templates (but not filled content).
     
     [1] Continue — re-initialize (keeps filled documents, resets empty ones)
     [2] Cancel
     ```
     Wait for response. If [2], exit.
   - If `--reset` was passed: warn and confirm:
     ```
     ⚠️ --reset will DELETE all .aid/ contents and start fresh.
     This includes .aid/knowledge/, all tasks, and all features.
     This is irreversible. Continue? [y/N]
     ```
     If confirmed, delete `.aid/` contents.

---

## Step 1: Collect Project Metadata

> **[State: COLLECT] — Gather project metadata through a short conversational interview (6 questions).**
>
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

---

## Step 2: Scaffold Knowledge Base

> **[State: SCAFFOLD] — Create the `.aid/knowledge/` directory and all 16 KB document templates.**
>
> ```
> aid-init  ▸ you are here
>   [✓ PRE-FLIGHT] → [✓ COLLECT ] → [● SCAFFOLD ] → [ META-DOCS ] → [ SETUP ] → [ DONE ]
> ```

▶ Scaffolding Knowledge Base (~5–10 s for 16 template files)

Create `.aid/knowledge/` directory and all 16 KB document templates.

### For Brownfield Projects

Create each file with a header indicating it's pending discovery:

```markdown
# {Document Title}

> **Source:** aid-discover
> **Status:** ❌ Pending Discovery
> **Last Updated:** —

*This document will be populated by `/aid-discover`.*
```

The 16 documents:

| File | Title |
|------|-------|
| `project-structure.md` | Project Structure |
| `external-sources.md` | External Sources |
| `architecture.md` | Architecture |
| `technology-stack.md` | Technology Stack |
| `module-map.md` | Module Map |
| `coding-standards.md` | Coding Standards |
| `data-model.md` | Data Model |
| `api-contracts.md` | API Contracts |
| `integration-map.md` | Integration Map |
| `domain-glossary.md` | Domain Glossary |
| `test-landscape.md` | Test Landscape |
| `security-model.md` | Security Model |
| `tech-debt.md` | Tech Debt |
| `infrastructure.md` | Infrastructure |
| `ui-architecture.md` | UI Architecture |
| `feature-inventory.md` | Feature Inventory |

**Special case — external-sources.md:** If the user provided external paths in Q4, write
them into the file immediately:

```markdown
# External Sources

> **Source:** aid-init
> **Status:** ⚠️ Paths Registered — Pending Discovery
> **Last Updated:** {date}

## Registered Sources

| # | Path | Type | Accessible | Notes |
|---|------|------|------------|-------|
| 1 | /path/to/docs | directory | ✅ | 23 files |
| 2 | /path/to/spec.pdf | file | ✅ | |

*Content analysis will be performed by `/aid-discover` (discovery-scout).*
```

If no external paths: write the standard "no external documentation" message.

✓ Scaffolding Knowledge Base done

### For Greenfield Projects

Create each file with a header indicating it will be filled during interview/specify:

```markdown
# {Document Title}

> **Source:** aid-interview / aid-specify
> **Status:** ❌ Pending
> **Last Updated:** —

*This document will be populated as requirements are gathered and specifications are written.*
```

**Greenfield documents are the same 16 files.** Some will remain sparse (e.g., tech-debt.md
for a new project), and that's expected. The reviewer in later phases understands this.

---

## Step 3: Create Meta-Documents

> **[State: META-DOCS] — Write README.md, INDEX.md, and STATE.md to complete the knowledge workspace.**
>
> ```
> aid-init  ▸ you are here
>   [✓ PRE-FLIGHT] → [✓ COLLECT ] → [✓ SCAFFOLD ] → [● META-DOCS ] → [ SETUP ] → [ DONE ]
> ```

▶ Writing meta-documents (~5 s)

### .aid/knowledge/README.md

```markdown
# Knowledge Base — {Project Name}

> {One-line description}

## Project Info

| Property | Value |
|----------|-------|
| **Type** | {Brownfield / Greenfield} |
| **Initialized** | {date} |
| **Minimum Grade** | {grade} |
| **External Sources** | {N paths / None} |

## Completeness

| Document | Status | Source |
|----------|--------|--------|
| project-structure.md | ❌ Pending | aid-discover |
| external-sources.md | {⚠️ Paths Registered / ❌ Pending} | aid-init / aid-discover |
| architecture.md | ❌ Pending | aid-discover |
| technology-stack.md | ❌ Pending | aid-discover |
| module-map.md | ❌ Pending | aid-discover |
| coding-standards.md | ❌ Pending | aid-discover |
| data-model.md | ❌ Pending | aid-discover |
| api-contracts.md | ❌ Pending | aid-discover |
| integration-map.md | ❌ Pending | aid-discover |
| domain-glossary.md | ❌ Pending | aid-discover |
| test-landscape.md | ❌ Pending | aid-discover |
| security-model.md | ❌ Pending | aid-discover |
| tech-debt.md | ❌ Pending | aid-discover |
| infrastructure.md | ❌ Pending | aid-discover |
| ui-architecture.md | ❌ Pending | aid-discover |
| feature-inventory.md | ❌ Pending | aid-discover |

## Revision History

| Date | Phase | Description |
|------|-------|-------------|
| {date} | aid-init | Initialized ({brownfield/greenfield}) |
```

### .aid/knowledge/INDEX.md

```markdown
# Knowledge Base Index — {Project Name}

Use this index to find the right document before making assumptions.
If your task touches an area covered here, read the relevant document first.

| Document | Summary |
|----------|---------|
| project-structure.md | Pending discovery |
| external-sources.md | {Pending discovery / N external paths registered} |
| architecture.md | Pending discovery |
| technology-stack.md | Pending discovery |
| module-map.md | Pending discovery |
| coding-standards.md | Pending discovery |
| data-model.md | Pending discovery |
| api-contracts.md | Pending discovery |
| integration-map.md | Pending discovery |
| domain-glossary.md | Pending discovery |
| test-landscape.md | Pending discovery |
| security-model.md | Pending discovery |
| tech-debt.md | Pending discovery |
| infrastructure.md | Pending discovery |
| ui-architecture.md | Pending discovery |
| feature-inventory.md | Pending discovery |
```

### .aid/knowledge/STATE.md

Copy the template from `../../templates/discovery-state-template.md` to
`.aid/knowledge/STATE.md`. Fill in the placeholders:

- `{minimum}` → grade from Q5
- `{Brownfield / Greenfield}` → from Q1
- `{List of paths from init Q4, or "None provided"}` → from Q4

✓ Meta-documents written

---

## Step 4: Set Up AGENTS.md

> **[State: SETUP] — Configure `AGENTS.md`, `.gitignore`, and install skill templates.**
>
> ```
> aid-init  ▸ you are here
>   [✓ PRE-FLIGHT] → [✓ COLLECT ] → [✓ SCAFFOLD ] → [✓ META-DOCS ] → [● SETUP ] → [ DONE ]
> ```

Check if `AGENTS.md` exists in the project root.

- **If it doesn't exist:** Create it with the AID template:

```markdown
# {Project Name}

<!-- AID-DISCOVER project-description -->
{One-line description from Q3}
<!-- /AID-DISCOVER -->

## Project Overview
<!-- AID-DISCOVER project-overview -->
(pending discovery)
<!-- /AID-DISCOVER -->

## Build & Test
<!-- AID-DISCOVER build-test -->
(pending discovery)
<!-- /AID-DISCOVER -->

## Code Conventions
<!-- AID-DISCOVER code-conventions -->
(pending discovery)
<!-- /AID-DISCOVER -->

## Architecture
<!-- AID-DISCOVER architecture -->
(pending discovery)
<!-- /AID-DISCOVER -->

## AID Workspace

The `.aid/` directory contains the Knowledge Base and work artifacts.
Read `.aid/knowledge/INDEX.md` to find what you need.
```

- **If it already exists:** Do NOT overwrite. Check for `<!-- AID-DISCOVER -->` placeholders.
  If none exist, append an "AID Workspace" section at the end pointing to
  `.aid/knowledge/INDEX.md`.
  Print: `[Init] AGENTS.md exists — appended workspace reference.`

### .gitignore

What happens here depends on the user's answer to **Q6**:

- **If the user chose [1] — commit `.aid/`:** Do NOT add a `.aid/` entry.
  Leave any existing `.gitignore` untouched, and do not create one.
  Print: `[Init] .aid/ will be tracked by Git (your Q6 choice).`

- **If the user chose [2] — keep `.aid/` local:**
  - If `.gitignore` doesn't exist: create it with `.aid/` as the only entry.
  - If it already exists: check whether `.aid/` is already listed; if not,
    append `.aid/` on a new line at the end of the file.
  - Print: `[Init] .gitignore updated — added .aid/ entry (workspace stays local).`

---

## Step 4b: Install Skill Templates

Some skills need template assets installed in the project at runtime (not just
scaffolded once). Currently:

### `knowledge-summary/` for `/aid-summarize`

If the source tree exists at `../../templates/knowledge-summary/` (relative to this
skill — i.e., `.claude/templates/knowledge-summary/`), copy the entire tree into the
project at `.aid/templates/knowledge-summary/`:

```bash
SRC="$(dirname "$0")/../../templates/knowledge-summary"
DST=".aid/templates/knowledge-summary"
if [ -d "$SRC" ]; then
    mkdir -p "$DST"
    cp -R "$SRC/." "$DST/"
    chmod +x "$DST"/scripts/*.sh 2>/dev/null || true
    echo "[Init] Installed knowledge-summary templates → $DST"
else
    echo "[Init] knowledge-summary templates not found at $SRC — skipping."
    echo "       /aid-summarize will not be available until you install them."
fi
```

The `knowledge-summary/` tree contains the CSS, JS, HTML skeleton, design tokens,
mermaid examples, accessibility checklist, grading rubric, profile section
templates, and validation scripts that `/aid-summarize` uses to build the visual
HTML summary. The skill is the orchestrator; these templates are the assets.

If a project doesn't intend to use `/aid-summarize`, this step is harmless — the
templates just sit unused.

---

## Step 5: Summary and Next Steps

> **[State: DONE] — Print the initialization summary and suggest the next AID phase.**
>
> ```
> aid-init  ▸ you are here
>   [✓ PRE-FLIGHT] → [✓ COLLECT ] → [✓ SCAFFOLD ] → [✓ META-DOCS ] → [✓ SETUP ] → [● DONE ]
> ```

Print a summary of everything created:

```
✅ AID Project Initialized

  Project:     {name}
  Type:        {Brownfield / Greenfield}
  Min Grade:   {grade}
  External:    {N paths / None}

  Created:
    knowledge/    (16 KB documents + README + INDEX + STATE)
    AGENTS.md                   {created / updated / unchanged}

  AID workspace (.aid/):        {tracked by Git | local only — added to .gitignore}

  Next step:
    {Brownfield: "Run /aid-discover to analyze the codebase and populate the Knowledge Base."}
    {Greenfield: "Run /aid-interview to gather requirements and start building the specification."}
```

---

## Idempotency Rules

- **Running init twice on the same project** does not overwrite documents that have real
  content (Status ≠ "Pending"). Only resets documents still at "Pending" status.
- **AGENTS.md** is never overwritten if it exists — only appended to.
- **STATE.md** is recreated (it's metadata, not content).
- **`--reset`** is the nuclear option — deletes everything and starts fresh.

---

## Quality Checklist

- [ ] `.aid/knowledge/` created with all 16 KB templates
- [ ] README.md has correct project type, name, and completeness table
- [ ] INDEX.md has all 16 documents listed
- [ ] STATE.md (`.aid/knowledge/STATE.md`) has correct minimum grade and project type
- [ ] External paths (if any) verified accessible and recorded
- [ ] AGENTS.md has workspace reference and AID placeholders (created or appended)
- [ ] `.gitignore` matches the Q6 choice (`.aid/` entry present only if the user chose [2], local-only)
- [ ] No files outside .aid/, AGENTS.md, .gitignore were modified
