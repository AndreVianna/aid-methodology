---
name: aid-init
description: >
  Initialize an AID project. Asks greenfield or brownfield, collects project metadata,
  external documentation paths, and scaffolds the aid-workspace/knowledge/ directory with empty templates.
  Sets up AGENTS.md with placeholders. Run once at project start — before
  aid-discover (brownfield) or aid-interview (greenfield).
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
argument-hint: "[--reset] clear existing aid-workspace/knowledge/ and re-initialize"
---

# AID Project Initialization

Set up a project for the AID methodology. Collects essential metadata, scaffolds the
Knowledge Base, and determines the workflow path. Run this once before any other AID phase.

**This is a conversational skill — it asks questions and waits for answers.**

---

## Pre-flight Checks

### Check 0: Verify Not in Plan Mode

**Before starting init, verify you are NOT in Plan Mode.**

- ✅ `Default` or `Auto-accept edits` → Proceed
- ❌ `Plan mode` → STOP. Tell user to switch. Init creates files — Plan mode will block all writes.

### Check 1: Existing Knowledge Base

1. Check if `aid-workspace/knowledge/` already exists with content:
   - If `aid-workspace/knowledge/` exists AND contains non-empty `.md` files AND `--reset` was NOT passed:
     ```
     ⚠️ This project already has a Knowledge Base with content.
     Re-running init will overwrite the KB templates (but not filled content).
     
     [1] Continue — re-initialize (keeps filled documents, resets empty ones)
     [2] Cancel
     ```
     Wait for response. If [2], exit.
   - If `--reset` was passed: warn and confirm:
     ```
     ⚠️ --reset will DELETE all aid-workspace/knowledge/ contents and start fresh.
     This is irreversible. Continue? [y/N]
     ```
     If confirmed, delete `aid-workspace/knowledge/` contents.

2. Verify not in Plan Mode (same check as aid-discover):
   - ✅ `Default` or `Auto-accept edits` → Proceed
   - ❌ `Plan mode` → STOP. Tell user to switch.

---

## Step 1: Collect Project Metadata

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

```
One-line description of what this project does:
```

### Q4: External Documentation (if any)

```
Do you have documentation outside this repository that should be considered?
(architecture docs, wiki exports, design documents, Confluence pages, etc.)

Provide file or directory paths separated by commas, or press Enter to skip.
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
(A+ through F, default: A)

[Enter] for default (A)
```

Parse and validate the grade. Store it.

---

## Step 2: Scaffold Knowledge Base

Create `aid-workspace/knowledge/` directory and all 14 KB document templates.

### For Brownfield Projects

Create each file with a header indicating it's pending discovery:

```markdown
# {Document Title}

> **Source:** aid-discover
> **Status:** ❌ Pending Discovery
> **Last Updated:** —

*This document will be populated by `/aid-discover`.*
```

The 14 documents:

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

### For Greenfield Projects

Create each file with a header indicating it will be filled during interview/specify:

```markdown
# {Document Title}

> **Source:** aid-interview / aid-specify
> **Status:** ❌ Pending
> **Last Updated:** —

*This document will be populated as requirements are gathered and specifications are written.*
```

**Greenfield documents are the same 14 files.** Some will remain sparse (e.g., tech-debt.md
for a new project), and that's expected. The reviewer in later phases understands this.

---

## Step 3: Create Meta-Documents

### aid-workspace/knowledge/README.md

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

## Revision History

| Date | Phase | Description |
|------|-------|-------------|
| {date} | aid-init | Initialized ({brownfield/greenfield}) |
```

### aid-workspace/knowledge/INDEX.md

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
```

### aid-workspace/knowledge/DISCOVERY-STATE.md

```markdown
# Discovery State

**Grade:** Not Started
**Minimum Grade:** {grade from Q5}
**Project Type:** {Brownfield / Greenfield}
**User Approved:** no

## External Documentation

{List of paths from Q4, or "None provided"}

## Issues

(Populated by reviewer after discovery)

## Q&A

(Populated during discovery and review)
```

---

## Step 4: Set Up Project Config Files

### AGENTS.md

Check if `AGENTS.md` exists in the project root.

- **If it doesn't exist:** Create it with the AID template (placeholders for discovery to fill):

```markdown
# {Project Name}

## Project Overview
<!-- AID:DISCOVER project-overview -->
(pending discovery)
<!-- /AID:DISCOVER -->

## Build & Test
<!-- AID:DISCOVER build-test -->
(pending discovery)
<!-- /AID:DISCOVER -->

## Code Conventions
<!-- AID:DISCOVER code-conventions -->
(pending discovery)
<!-- /AID:DISCOVER -->

## Architecture
<!-- AID:DISCOVER architecture -->
(pending discovery)
<!-- /AID:DISCOVER -->

## Knowledge Base

The `aid-workspace/knowledge/` directory contains {14} documents covering architecture, conventions,
data models, integrations, and more. Read `aid-workspace/knowledge/INDEX.md` to find what you need.
```

- **If it already exists:** Do NOT overwrite. Check for `<!-- AID:DISCOVER -->` placeholders.
  If none exist, append a "Knowledge Base" section at the end pointing to `aid-workspace/knowledge/INDEX.md`.
  Print: `[Init] AGENTS.md exists — appended KB reference.`

**Note:** Codex uses `AGENTS.md` as its primary project context file. There is no separate `CLAUDE.md`.
The `AGENTS.md` template above already includes project overview, conventions, architecture, and KB reference — all the context Codex needs.

---

## Step 5: Summary and Next Steps

Print a summary of everything created:

```
✅ AID Project Initialized

  Project:     {name}
  Type:        {Brownfield / Greenfield}
  Min Grade:   {grade}
  External:    {N paths / None}

  Created:
    aid-workspace/knowledge/              (14 KB documents + README + INDEX + DISCOVERY-STATE)
    AGENTS.md               {created / updated / unchanged}

  Next step:
    {Brownfield: "Run /aid-discover to analyze the codebase and populate the Knowledge Base."}
    {Greenfield: "Run /aid-interview to gather requirements and start building the specification."}
```

---

## Idempotency Rules

- **Running init twice on the same project** does not overwrite documents that have real
  content (Status ≠ "Pending"). Only resets documents still at "Pending" status.
- **AGENTS.md** is never overwritten if it exists — only appended to.
- **aid-workspace/knowledge/DISCOVERY-STATE.md** is recreated (it's metadata, not content).
- **`--reset`** is the nuclear option — deletes everything and starts fresh.

---

## Quality Checklist

- [ ] All 14 KB templates created in aid-workspace/knowledge/
- [ ] README.md has correct project type, name, and completeness table
- [ ] INDEX.md has all 14 documents listed
- [ ] DISCOVERY-STATE.md has correct minimum grade and project type
- [ ] External paths (if any) verified accessible and recorded
- [ ] AGENTS.md has KB reference (created or appended)
- [ ] No files outside aid-workspace/knowledge/ and AGENTS.md were modified
