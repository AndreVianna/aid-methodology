---
name: aid-init
description: >
  Initialize an AID project. Asks greenfield or brownfield, collects project metadata,
  external documentation paths, and scaffolds the .aid/ directory structure.
  Sets up {project_context_file} with placeholders. Run once at project start — before
  aid-discover (brownfield) or aid-interview (greenfield).
  State machine: PRE-FLIGHT → COLLECT → SCAFFOLD → META-DOCS → SETUP → DONE.
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
  {project_context_file}
  .aid/
    knowledge/
      STATE.md
      (...16 KB docs, INDEX.md, README.md)
```

Works and features are created later by `/aid-interview`.

---

## ⚠️ Pre-flight Checks

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

## State Detection

⚠️ FILESYSTEM IS THE ONLY SOURCE OF TRUTH — determine state from disk, not from memory.

Inspect the `.aid/` directory after pre-flight:

- `.aid/` absent or empty → **COLLECT** (first run; begin metadata interview)
- `.aid/knowledge/` exists but fewer than 16 KB document templates present → **SCAFFOLD**
- All 16 KB templates exist but `README.md`, `INDEX.md`, or `STATE.md` missing from `.aid/knowledge/` → **META-DOCS**
- All meta-documents exist but `{project_context_file}` has no `<!-- AID-DISCOVER -->` placeholders and no AID Workspace section → **SETUP**
- All of the above complete but `.aid/templates/knowledge-summary/` does not exist → **SETUP** (step-4b knowledge-summary template install did not run)
- All of the above complete, including `.aid/templates/knowledge-summary/` present → **DONE**

Print the state-entry line:

```
[State: {NAME}] — {one-line description from the matching row below}
```

---

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| COLLECT | `references/step-1-collect.md` | `inline` | → SCAFFOLD |
| SCAFFOLD | `references/step-2-scaffold.md` | `inline` | → META-DOCS |
| META-DOCS | `references/step-3-meta-docs.md` | `inline` | → SETUP |
| SETUP | `references/step-4-setup.md` | `inline` | → DONE |
| DONE | `references/step-5-done.md` | `inline` | → halt |

On state entry, print `[State: NAME]` + the "you are here" map from the matching state-detail file.
When a state completes, print `Next: [State: {NEXT}] — run /aid-init again` and exit.
For the DONE state, print the summary and halt — no next-state line.

---

## Idempotency Rules

- **Running init twice on the same project** does not overwrite documents that have real
  content (Status ≠ "Pending"). Only resets documents still at "Pending" status.
- **{project_context_file}** is never overwritten if it exists — only appended to.
- **STATE.md** is recreated (it's metadata, not content).
- **`--reset`** is the nuclear option — deletes everything and starts fresh.

---

## Quality Checklist

- [ ] `.aid/knowledge/` created with all 16 KB templates
- [ ] README.md has correct project type, name, and completeness table
- [ ] INDEX.md has all 16 documents listed
- [ ] STATE.md (`.aid/knowledge/STATE.md`) has correct minimum grade and project type
- [ ] External paths (if any) verified accessible and recorded
- [ ] {project_context_file} has workspace reference and AID placeholders (created or appended)
- [ ] `.gitignore` matches the Q7 choice (`.aid/` entry present only if the user chose [2], local-only); `.aid/.heartbeat/` entry present REGARDLESS of Q7 choice
- [ ] No files outside .aid/, {project_context_file}, .gitignore were modified
