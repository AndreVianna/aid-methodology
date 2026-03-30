---
name: aid-init
description: >
  Initialize an AID project. Asks greenfield or brownfield, collects project metadata,
  external documentation paths, and scaffolds the .aid/ directory structure.
  Sets up CLAUDE.md with placeholders. Run once at project start — before
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
  CLAUDE.md
  .aid/
    knowledge/
      DISCOVERY-STATE.md
      (...16 KB docs, INDEX.md, README.md)
```

Works and features are created later by `/aid-interview`.

---

## Pre-flight Checks

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

---

## Step 2: Scaffold Knowledge Base

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
| feature-inventory.md | Pending discovery |
```

### .aid/knowledge/DISCOVERY-STATE.md

Copy the template from `../../templates/discovery-state.md` to
`.aid/knowledge/DISCOVERY-STATE.md`. Fill in the placeholders:

- `{minimum}` → grade from Q5
- `{Brownfield / Greenfield}` → from Q1
- `{List of paths from init Q4, or "None provided"}` → from Q4

---

## Step 4: Set Up CLAUDE.md

Check if `CLAUDE.md` exists in the project root.

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
  Print: `[Init] CLAUDE.md exists — appended workspace reference.`

### .gitignore

Check if `.gitignore` exists in the project root.

- **If it doesn't exist:** Create it with `.aid/` as the only entry.
- **If it already exists:** Check if `.aid/` is already listed.
  If not, append `.aid/` on a new line at the end of the file.
  Print: `[Init] .gitignore updated — added .aid/ entry.`

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
    knowledge/    (16 KB documents + README + INDEX + DISCOVERY-STATE)
    CLAUDE.md                   {created / updated / unchanged}
    .gitignore                  {created / updated / unchanged}

  Next step:
    {Brownfield: "Run /aid-discover to analyze the codebase and populate the Knowledge Base."}
    {Greenfield: "Run /aid-interview to gather requirements and start building the specification."}
```

---

## Idempotency Rules

- **Running init twice on the same project** does not overwrite documents that have real
  content (Status ≠ "Pending"). Only resets documents still at "Pending" status.
- **CLAUDE.md** is never overwritten if it exists — only appended to.
- **DISCOVERY-STATE.md** is recreated (it's metadata, not content).
- **`--reset`** is the nuclear option — deletes everything and starts fresh.

---

## Quality Checklist

- [ ] `.aid/knowledge/` created with all 16 KB templates
- [ ] README.md has correct project type, name, and completeness table
- [ ] INDEX.md has all 16 documents listed
- [ ] DISCOVERY-STATE.md has correct minimum grade and project type
- [ ] External paths (if any) verified accessible and recorded
- [ ] CLAUDE.md has workspace reference and AID placeholders (created or appended)
- [ ] .gitignore has `.aid/` entry
- [ ] No files outside .aid/, CLAUDE.md, .gitignore were modified
