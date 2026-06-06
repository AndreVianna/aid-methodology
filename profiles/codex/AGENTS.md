# AGENTS.md

## Project Overview
<!-- AID-DISCOVER — Replace with project name, purpose, tech stack, and target platform -->
(pending discovery)

## Knowledge Base

This project uses the [AID methodology](https://github.com/AndreVianna/aid-methodology).
- Read `.aid/knowledge/INDEX.md`.

## Review output format (global)

Any review output you produce — dispatched sub-agent, script validator, or
ad-hoc user-prompted — uses the schema at
`templates/reviewer-ledger-schema.md` (under this tool's install root). Write the ledger as a single
markdown table at `.aid/.temp/review-pending/<scope>.md`. Use the 7-column
shape: `# | Severity | Status | Doc | Line | Description | Evidence`.
Severity tags bracketed; Status enum: Pending/Fixed/Recurred/Accepted/OOS/Invalid.
No narrative or summary sections in the ledger.

## Permissions

- Read any file in the project
- Write only within the project directory
- Run build and test commands (Python, Bash, PowerShell)
- Do NOT modify files outside the project root
