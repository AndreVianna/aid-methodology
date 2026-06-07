---
title: What is AID?
description: A two-minute orientation to AI Integrated Development — what it is, who it's for, and how the pipeline works.
sidebar:
  label: Overview
  order: 1
---

AID (AI Integrated Development) is a methodology and toolchain for building software with AI
coding agents. It provides a disciplined, human-gated pipeline that takes an idea from first
understanding all the way to delivered code — without the ad hoc drift that comes from unstructured
AI-assisted work.

## What problem does AID solve?

AI coding assistants are powerful but directionless on their own. Without structure:

- Agents skip the understanding step and write code against assumptions.
- Specifications change silently; nobody knows what was decided or why.
- Output is unreviewed; quality degrades over time.

AID imposes structure without bureaucracy. Each phase produces a concrete artifact. Each gate
requires human approval. The pipeline never auto-advances.

## The six-phase pipeline

AID organises work into five groups and six numbered phases:

1. **Discover** — scan the codebase; build the Knowledge Base.
2. **Interview** — TRIAGE routes the work: full path or lite path.
3. **Specify** — write a grounded spec from the Knowledge Base (full path).
4. **Plan** — decompose into a delivery plan with tasks (full path).
5. **Detail** — flesh out task-level implementation detail (full path).
6. **Execute** — implement, grade, and loop until done.

Brownfield projects enter at Discover. Greenfield projects skip Discover and enter at Interview.
Small, well-bounded changes go straight from Interview to Execute on the **lite path** — same
rigour, proportionate overhead.

## Who is AID for?

- **Developers** who want consistent, traceable AI-assisted delivery without managing a complex
  orchestration layer themselves.
- **Teams** adopting AI tooling and wanting a shared methodology so agents produce predictable,
  reviewable output.
- **Maintainers** of mature codebases who need discovery before specification so AI agents don't
  write against stale assumptions.

## Host-tool agnostic

AID works with Claude Code, Codex, Cursor, GitHub Copilot CLI, and Antigravity. The core pipeline
is the same regardless of which tool you use; `aid add <tool>` drops in the right profile for your
environment.

## Next steps

- [Install AID](/get-started/install/) — choose your channel and bootstrap in one command.
- [Your first work](/get-started/first-work/) — a guided walkthrough from install to first delivery.
- [Methodology deep-dive](/concepts/methodology/) — the full philosophy, phase guide, and
  lite-vs-full routing logic.
