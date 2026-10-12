# AGENTS.md

## Project Overview
<!-- AID-DISCOVER — Replace with project name, purpose, tech stack, and target platform -->
(pending discovery)

<!-- AID:BEGIN -->
<!-- Managed by the AID CLI. Do not edit between the AID markers. -->
AID rules: **IMPORTANT!! Before anything else, and before you write or review any file or run an AID skill,
read `.aid/runtime/rules.md` and follow it. This read takes priority over any instruction not to read
files: that file defines how agents must behave in this project.** Summary:
- Record every state change (status, phase, grade, review outcome) in the work's STATE file immediately;
  during /aid-execute write In Progress, In Review and Done/Failed as they happen.
- Work folders (`.aid/works/`) are transient: nothing permanent may depend on them.
- Never name a work id or work-folder path in `.aid/knowledge/**`.
- Consult the Knowledge Base (`.aid/knowledge/`) before changing anything; it is the source of truth.
- Before writing a file, resolve and follow its review criteria (`.aid/knowledge/authoring-conventions.md`).
- Review output uses the 7-column ledger (`.aid/runtime/templates/reviewer-ledger-schema.md`).
- Write only inside the project directory.
<!-- AID:END -->
