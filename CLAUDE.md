# CLAUDE.md

## Project

**AID (AI Integrated Development)** — a methodology for orchestrating AI-assisted software work as a chain of small, reviewable phases (Discover → Interview → Specify → Plan → Detail → Execute → Deploy → Monitor). This repo is both the **methodology specification** (`methodology/aid-methodology.md`, 1,071 lines) and a **multi-tool distribution** of skills/agents/templates/recipes rendered into 3 install trees (Claude Code, Codex CLI, Cursor) from a single `canonical/` source via `run_generator.py`.

## Knowledge Base

his project uses the [AID methodology](https://github.com/AndreVianna/aid-methodology).
@`.aid/knowledge/INDEX.md`.

## .aid/ committed (this repo only)

This repository deliberately commits `.aid/knowledge/` and other `.aid/` artifacts
to git, because AID is dogfooding itself — the Knowledge Base and work-artifacts
ARE part of the product here. The general guidance in README.md (gitignore `.aid/`)
applies to adopter projects, not to this repo.

## Permissions

- Read any file in the project
- Write only within the project directory
- Run build and test commands (Python, Bash, PowerShell)
- Do NOT modify files outside the project root

